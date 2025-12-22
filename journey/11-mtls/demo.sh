#!/bin/bash
# =============================================================================
#  NIVEAU 2 - MISSION 3 : mTLS Authentication
#
#  Objectif : Émettre des certificats client et serveur pour mTLS.
#             Authentification mutuelle post-quantique.
#
#  Algorithme : ML-DSA-65
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source les helpers
source "$LAB_ROOT/lib/colors.sh"
source "$LAB_ROOT/lib/interactive.sh"
source "$LAB_ROOT/lib/workspace.sh"

# PKI binary
PKI_BIN="$LAB_ROOT/bin/pki"

# =============================================================================
# Vérifications
# =============================================================================

check_pki_installed() {
    if [[ ! -x "$PKI_BIN" ]]; then
        print_error "L'outil PKI n'est pas installé"
        exit 1
    fi
}

# =============================================================================
# Bannière
# =============================================================================

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🔐  NIVEAU 2 - MISSION 3                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   mTLS : Authentification mutuelle                            ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Durée estimée :${NC} 8 minutes"
    echo -e "  ${BOLD}Algorithme    :${NC} ML-DSA-65"
    echo ""
    echo "  mTLS = Mutual TLS = Le client ET le serveur prouvent leur identité"
    echo ""
    echo "    ┌──────────┐                      ┌──────────┐"
    echo "    │  CLIENT  │ ◄── certificat ───► │  SERVER  │"
    echo "    │  (Alice) │                      │  (API)   │"
    echo "    └──────────┘                      └──────────┘"
    echo ""
    echo "  Scénario : Alice et Bob ont des certificats. Mallory n'en a pas."
    echo ""
}

# =============================================================================
# Setup : Créer ou réutiliser la CA PQC
# =============================================================================

setup_ca() {
    mission_start 1 "Préparer la CA pour mTLS"

    # Utiliser la CA PQC du Niveau 1 si disponible
    local pqc_issuing="$WORKSPACE_ROOT/niveau-1/pqc-issuing-ca"

    if [[ -f "$pqc_issuing/ca.crt" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Réutilisation de ta CA PQC du Niveau 1"
        echo ""
        MTLS_CA="$pqc_issuing"
        learned "Réutiliser les CA existantes = bonne pratique"
    else
        echo "  Création d'une CA mTLS dédiée..."
        MTLS_CA="$LEVEL_WORKSPACE/mtls-ca"

        if [[ ! -f "$MTLS_CA/ca.crt" ]]; then
            teach_cmd "pki init-ca --name \"mTLS Demo CA\" --algorithm ml-dsa-65 --dir $MTLS_CA" \
                      "CA dédiée pour l'authentification mTLS"
        fi
    fi

    validate_file "$MTLS_CA/ca.crt" "CA mTLS"

    mission_complete "CA mTLS prête"
}

# =============================================================================
# Mission 2 : Émettre le certificat serveur
# =============================================================================

mission_2_server_cert() {
    mission_start 2 "Émettre le certificat serveur"

    echo "  Le serveur a besoin d'un certificat pour prouver son identité."
    echo ""
    echo -e "  ${BOLD}Profil :${NC} ml-dsa/tls-server"
    echo "    - Extended Key Usage : serverAuth"
    echo "    - DNS SANs : api.example.com"
    echo ""

    local cert_out="$LEVEL_WORKSPACE/mtls-server.crt"
    local key_out="$LEVEL_WORKSPACE/mtls-server.key"

    if [[ -f "$cert_out" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Le certificat serveur existe déjà !"
        validate_file "$cert_out" "Certificat serveur mTLS"
        return 0
    fi

    teach_cmd "pki issue --ca-dir $MTLS_CA --profile ml-dsa/tls-server --cn \"api.example.com\" --dns \"api.example.com\" --out $cert_out --key-out $key_out" \
              "Certificat TLS serveur avec ML-DSA-65"

    validate_file "$cert_out" "Certificat serveur"

    mission_complete "Certificat serveur émis"

    learned "tls-server = Extended Key Usage: serverAuth"
}

# =============================================================================
# Mission 3 : Émettre les certificats clients
# =============================================================================

mission_3_client_certs() {
    mission_start 3 "Émettre les certificats clients"

    echo "  Chaque client a besoin de son propre certificat."
    echo ""
    echo -e "  ${BOLD}Profil :${NC} ml-dsa/tls-client"
    echo "    - Extended Key Usage : clientAuth"
    echo "    - Identifie le client auprès du serveur"
    echo ""

    # Alice
    local alice_cert="$LEVEL_WORKSPACE/alice.crt"
    local alice_key="$LEVEL_WORKSPACE/alice.key"

    echo -e "  ${BOLD}Certificat pour Alice :${NC}"

    if [[ -f "$alice_cert" ]]; then
        echo -e "  ${YELLOW}[INFO]${NC} Le certificat d'Alice existe déjà !"
    else
        teach_cmd "pki issue --ca-dir $MTLS_CA --profile ml-dsa/tls-client --cn \"Alice\" --out $alice_cert --key-out $alice_key" \
                  "Certificat client pour Alice"
    fi

    validate_file "$alice_cert" "Certificat Alice"

    echo ""

    # Bob
    local bob_cert="$LEVEL_WORKSPACE/bob.crt"
    local bob_key="$LEVEL_WORKSPACE/bob.key"

    echo -e "  ${BOLD}Certificat pour Bob :${NC}"

    if [[ -f "$bob_cert" ]]; then
        echo -e "  ${YELLOW}[INFO]${NC} Le certificat de Bob existe déjà !"
    else
        teach_cmd "pki issue --ca-dir $MTLS_CA --profile ml-dsa/tls-client --cn \"Bob\" --out $bob_cert --key-out $bob_key" \
                  "Certificat client pour Bob"
    fi

    validate_file "$bob_cert" "Certificat Bob"

    mission_complete "Certificats clients émis (Alice et Bob)"

    learned "tls-client = Extended Key Usage: clientAuth"
}

# =============================================================================
# Mission 4 : Vérifier les certificats
# =============================================================================

mission_4_verify() {
    mission_start 4 "Simuler l'authentification mTLS"

    echo "  Simulons ce qui se passe lors d'une connexion mTLS :"
    echo ""

    local alice_cert="$LEVEL_WORKSPACE/alice.crt"
    local bob_cert="$LEVEL_WORKSPACE/bob.crt"
    local server_cert="$LEVEL_WORKSPACE/mtls-server.crt"

    # Vérification Alice
    echo -e "  ${BOLD}Test 1 : Alice se connecte${NC}"
    echo ""

    demo_cmd "$PKI_BIN verify --ca $MTLS_CA/ca.crt --cert $alice_cert" \
             "Vérification du certificat d'Alice..."

    if "$PKI_BIN" verify --ca "$MTLS_CA/ca.crt" --cert "$alice_cert" > /dev/null 2>&1; then
        echo ""
        echo -e "    ${GREEN}✓${NC} Alice authentifiée avec succès !"
    fi

    echo ""
    wait_enter

    # Vérification Bob
    echo -e "  ${BOLD}Test 2 : Bob se connecte${NC}"
    echo ""

    demo_cmd "$PKI_BIN verify --ca $MTLS_CA/ca.crt --cert $bob_cert" \
             "Vérification du certificat de Bob..."

    if "$PKI_BIN" verify --ca "$MTLS_CA/ca.crt" --cert "$bob_cert" > /dev/null 2>&1; then
        echo ""
        echo -e "    ${GREEN}✓${NC} Bob authentifié avec succès !"
    fi

    echo ""
    wait_enter

    # Mallory (pas de certificat)
    echo -e "  ${BOLD}Test 3 : Mallory essaie sans certificat${NC}"
    echo ""
    echo -e "    ${RED}✗${NC} Mallory est REJETÉ ! (Pas de certificat client)"
    echo -e "    ${DIM}Sans certificat signé par la CA, pas d'accès.${NC}"
    echo ""

    # Résumé
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  RÉSUMÉ AUTHENTIFICATION mTLS                                  │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo -e "  │  Alice   │ Certificat valide signé par CA     │ ${GREEN}✓ AUTORISÉ${NC}  │"
    echo -e "  │  Bob     │ Certificat valide signé par CA     │ ${GREEN}✓ AUTORISÉ${NC}  │"
    echo -e "  │  Mallory │ Pas de certificat                  │ ${RED}✗ REJETÉ${NC}    │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Authentification mTLS simulée"

    learned "mTLS = preuve cryptographique, pas de mot de passe"
}

# =============================================================================
# Récapitulatif
# =============================================================================

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 3 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Certificat serveur avec EKU serverAuth" \
        "Certificats clients avec EKU clientAuth" \
        "Simulation d'authentification mTLS" \
        "Rejet des connexions sans certificat"

    echo -e "  ${BOLD}Tes fichiers mTLS :${NC}"
    echo -e "    ${CYAN}$LEVEL_WORKSPACE/${NC}"
    echo "      mtls-server.crt/key  - Serveur"
    echo "      alice.crt/key        - Client Alice"
    echo "      bob.crt/key          - Client Bob"
    echo ""

    show_lesson "mTLS = authentification mutuelle cryptographique.
Pas de mot de passe. Juste des certificats.
Avec PQC, c'est résistant aux attaques quantiques."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} Code Signing"
    echo "  Signer du code avec ML-DSA"
    echo ""
    echo -e "    ${CYAN}./journey/03-applications/02-code-signing/demo.sh${NC}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    check_pki_installed

    # Initialiser le workspace Niveau 2
    init_workspace "niveau-2"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer la mission..."

    setup_ca
    wait_enter

    mission_2_server_cert
    wait_enter

    mission_3_client_certs
    wait_enter

    mission_4_verify

    show_recap_final
}

# Exécution
main "$@"

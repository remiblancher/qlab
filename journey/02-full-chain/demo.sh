#!/bin/bash
# =============================================================================
#  NIVEAU 1 - MISSION 1 : Full PQC Chain
#
#  Objectif : Construire une hiérarchie PKI complète en post-quantique.
#             Root CA → Issuing CA → Certificat TLS
#
#  Algorithmes : ML-DSA-87 (Root), ML-DSA-65 (Issuing), ML-DSA-65 + ML-KEM-768 (End)
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
        echo "  Exécute : ./tooling/install.sh"
        exit 1
    fi
}

# =============================================================================
# Bannière
# =============================================================================

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🔐  NIVEAU 1 - MISSION 1                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Full PQC Chain of Trust                                     ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Durée estimée :${NC} 10 minutes"
    echo -e "  ${BOLD}Algorithmes   :${NC} ML-DSA-87, ML-DSA-65, ML-KEM-768"
    echo ""
    echo "  Dans cette mission, tu vas construire une PKI complète :"
    echo ""
    echo "    1. Créer une Root CA (ML-DSA-87 - sécurité maximale)"
    echo "    2. Créer une Issuing CA subordonnée (ML-DSA-65)"
    echo "    3. Émettre un certificat TLS serveur (ML-DSA-65 + ML-KEM-768)"
    echo "    4. Examiner la chaîne de confiance"
    echo ""
    echo -e "  ${GREEN}Aucune cryptographie classique dans la chaîne.${NC}"
    echo ""
}

# =============================================================================
# Mission 1 : Créer la Root CA PQC
# =============================================================================

mission_1_root_ca() {
    mission_start 1 "Créer la Root CA Post-Quantum"

    echo "  La Root CA est le point d'ancrage de toute ta PKI."
    echo "  Elle doit être la plus sécurisée car elle a la plus longue durée de vie."
    echo ""
    echo -e "  ${BOLD}Algorithme choisi :${NC} ML-DSA-87"
    echo "    - NIST FIPS 204 standard"
    echo "    - Niveau de sécurité 5 (équivalent ~256 bits classique)"
    echo "    - Recommandé pour les CA racines longue durée"
    echo ""

    local root_ca="$LEVEL_WORKSPACE/pqc-root-ca"

    # Vérifier si déjà créé
    if [[ -f "$root_ca/ca.crt" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Ta Root CA PQC existe déjà !"
        validate_file "$root_ca/ca.crt" "Certificat Root CA"
        echo ""
        learned "Une Root CA peut durer 20-30 ans"
        return 0
    fi

    # L'utilisateur tape la commande
    teach_cmd "pki init-ca --name \"PQC Root CA\" --algorithm ml-dsa-87 --dir $root_ca" \
              "ML-DSA-87 = niveau de sécurité maximal (NIST Level 5)"

    # Validation
    validate_files "$root_ca" "ca.crt" "ca.key"

    # Afficher les infos
    echo ""
    echo -e "  ${BOLD}Détails de ta Root CA :${NC}"
    "$PKI_BIN" info "$root_ca/ca.crt" 2>/dev/null | head -12 | sed 's/^/    /'

    mission_complete "Root CA PQC créée (ML-DSA-87)"

    learned "ML-DSA-87 pour les CA racines (sécurité maximale)"
}

# =============================================================================
# Mission 2 : Créer l'Issuing CA PQC
# =============================================================================

mission_2_issuing_ca() {
    mission_start 2 "Créer l'Issuing CA subordonnée"

    echo "  L'Issuing CA émet les certificats end-entity."
    echo "  Elle est signée par la Root CA."
    echo ""
    echo -e "  ${BOLD}Algorithme choisi :${NC} ML-DSA-65"
    echo "    - Niveau de sécurité 3 (équivalent ~192 bits classique)"
    echo "    - Bon équilibre sécurité/performance"
    echo "    - Utilisé pour les CA intermédiaires"
    echo ""

    local root_ca="$LEVEL_WORKSPACE/pqc-root-ca"
    local issuing_ca="$LEVEL_WORKSPACE/pqc-issuing-ca"

    # Vérifier si déjà créé
    if [[ -f "$issuing_ca/ca.crt" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Ton Issuing CA existe déjà !"
        validate_file "$issuing_ca/ca.crt" "Certificat Issuing CA"
        echo ""
        return 0
    fi

    # L'utilisateur tape la commande
    teach_cmd "pki init-ca --name \"PQC Issuing CA\" --algorithm ml-dsa-65 --parent $root_ca --dir $issuing_ca" \
              "--parent lie cette CA à la Root CA (subordination)"

    # Validation
    validate_files "$issuing_ca" "ca.crt" "ca.key"

    # Afficher les infos
    echo ""
    echo -e "  ${BOLD}Vérification de la chaîne :${NC}"
    echo ""
    echo "    Root CA (ML-DSA-87)"
    echo "        │"
    echo "        └── signe"
    echo "              │"
    echo "              ▼"
    echo "    Issuing CA (ML-DSA-65)"
    echo ""

    mission_complete "Issuing CA créée et signée par la Root"

    learned "--parent crée une CA subordonnée"
}

# =============================================================================
# Mission 3 : Émettre un certificat TLS
# =============================================================================

mission_3_tls_cert() {
    mission_start 3 "Émettre un certificat TLS serveur"

    echo "  Le certificat TLS serveur utilise deux algorithmes PQC :"
    echo ""
    echo "    - ML-DSA-65 : pour les signatures (authentification)"
    echo "    - ML-KEM-768 : pour l'échange de clés (confidentialité TLS)"
    echo ""
    echo -e "  ${CYAN}C'est le profil 'ml-dsa-kem/tls-server'${NC}"
    echo ""

    local issuing_ca="$LEVEL_WORKSPACE/pqc-issuing-ca"
    local cert_out="$LEVEL_WORKSPACE/pqc-server.crt"
    local key_out="$LEVEL_WORKSPACE/pqc-server.key"

    # Vérifier si déjà créé
    if [[ -f "$cert_out" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Ton certificat serveur existe déjà !"
        validate_file "$cert_out" "Certificat TLS"
        echo ""
        return 0
    fi

    # L'utilisateur tape la commande
    teach_cmd "pki issue --ca-dir $issuing_ca --profile ml-dsa-kem/tls-server --cn \"pqc.example.com\" --dns \"pqc.example.com\" --out $cert_out --key-out $key_out" \
              "Le profil ml-dsa-kem inclut signature + encryption PQC"

    # Validation
    validate_file "$cert_out" "Certificat TLS PQC"
    validate_file "$key_out" "Clé privée TLS PQC"

    # Afficher les infos
    echo ""
    echo -e "  ${BOLD}Détails du certificat :${NC}"
    "$PKI_BIN" info "$cert_out" 2>/dev/null | head -15 | sed 's/^/    /'

    mission_complete "Certificat TLS PQC émis (ML-DSA-65 + ML-KEM-768)"

    learned "ml-dsa-kem = double protection (signature + encryption)"
}

# =============================================================================
# Mission 4 : Examiner la chaîne complète
# =============================================================================

mission_4_chain() {
    mission_start 4 "Examiner la chaîne de confiance"

    echo "  Visualisons ta hiérarchie PKI complète :"
    echo ""
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │           ${BOLD}PQC Root CA${NC}                   │"
    echo "  │           ML-DSA-87                     │"
    echo "  │       (NIST Level 5 - maximum)          │"
    echo "  └─────────────────┬───────────────────────┘"
    echo "                    │ signe"
    echo "                    ▼"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │         ${BOLD}PQC Issuing CA${NC}                  │"
    echo "  │           ML-DSA-65                     │"
    echo "  │          (NIST Level 3)                 │"
    echo "  └─────────────────┬───────────────────────┘"
    echo "                    │ signe"
    echo "                    ▼"
    echo "  ┌─────────────────────────────────────────┐"
    echo "  │       ${BOLD}TLS Server Certificate${NC}            │"
    echo "  │   ML-DSA-65 (sig) + ML-KEM-768 (enc)    │"
    echo "  │          (NIST Level 3)                 │"
    echo "  └─────────────────────────────────────────┘"
    echo ""

    wait_enter

    # Comparaison des tailles
    local root_ca="$LEVEL_WORKSPACE/pqc-root-ca"
    local issuing_ca="$LEVEL_WORKSPACE/pqc-issuing-ca"
    local server_cert="$LEVEL_WORKSPACE/pqc-server.crt"

    local root_size=$(wc -c < "$root_ca/ca.crt" | tr -d ' ')
    local issuing_size=$(wc -c < "$issuing_ca/ca.crt" | tr -d ' ')
    local server_size=$(wc -c < "$server_cert" | tr -d ' ')
    local chain_total=$((root_size + issuing_size + server_size))

    echo -e "  ${BOLD}Tailles des certificats :${NC}"
    echo ""
    printf "    %-25s %8s\n" "Root CA (ML-DSA-87)" "$root_size B"
    printf "    %-25s %8s\n" "Issuing CA (ML-DSA-65)" "$issuing_size B"
    printf "    %-25s %8s\n" "Serveur TLS" "$server_size B"
    echo "    ─────────────────────────────────"
    printf "    %-25s %8s\n" "CHAÎNE COMPLÈTE" "$chain_total B"
    echo ""

    # Comparer avec classique si disponible
    local classic_ca="$WORKSPACE_ROOT/quickstart/classic-ca"
    if [[ -f "$classic_ca/ca.crt" ]]; then
        local classic_size=$(wc -c < "$classic_ca/ca.crt" | tr -d ' ')
        local ratio=$(echo "scale=1; $root_size / $classic_size" | bc)
        echo -e "  ${CYAN}Comparaison :${NC}"
        echo "    CA classique (ECDSA)  : $classic_size B"
        echo "    CA PQC (ML-DSA-87)    : $root_size B"
        echo "    Ratio                 : ${ratio}x plus grand"
        echo ""
        echo -e "  ${DIM}C'est le prix à payer pour la résistance quantique.${NC}"
    fi

    mission_complete "Chaîne de confiance PQC complète examinée"

    learned "Les certificats PQC sont ~5-10x plus grands que les classiques"
}

# =============================================================================
# Récapitulatif
# =============================================================================

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 1 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Root CA avec ML-DSA-87 (sécurité maximale)" \
        "Issuing CA subordonnée avec ML-DSA-65" \
        "Certificat TLS avec ML-DSA-65 + ML-KEM-768" \
        "Chaîne complète 100% post-quantique"

    echo -e "  ${BOLD}Tes fichiers sont dans :${NC}"
    echo -e "    ${CYAN}$LEVEL_WORKSPACE/${NC}"
    echo ""

    show_lesson "Construire une PKI full PQC utilise les mêmes concepts.
Seuls les algorithmes changent. Et ils sont plus gros."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} Hybrid Catalyst"
    echo "  Découvre les certificats hybrides (classique + PQC)"
    echo ""
    echo -e "    ${CYAN}./journey/02-pqc-basics/02-hybrid/demo.sh${NC}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    check_pki_installed

    # Initialiser le workspace Niveau 1
    init_workspace "niveau-1"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer la mission..."

    mission_1_root_ca
    wait_enter

    mission_2_issuing_ca
    wait_enter

    mission_3_tls_cert
    wait_enter

    mission_4_chain

    show_recap_final
}

# Exécution
main "$@"

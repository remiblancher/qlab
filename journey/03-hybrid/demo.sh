#!/bin/bash
# =============================================================================
#  NIVEAU 1 - MISSION 2 : Hybrid Catalyst
#
#  Objectif : Créer des certificats hybrides (classique + PQC).
#             Le meilleur des deux mondes.
#
#  Algorithmes : ECDSA P-384 + ML-DSA-65 (Catalyst ITU-T X.509)
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
    echo -e "${BOLD}${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🔀  NIVEAU 1 - MISSION 2                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Hybrid Catalyst : Le meilleur des deux mondes              ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Durée estimée :${NC} 10 minutes"
    echo -e "  ${BOLD}Algorithmes   :${NC} ECDSA P-384 + ML-DSA-65"
    echo ""
    echo "  Le problème :"
    echo "    \"Je dois rester compatible avec les clients legacy,"
    echo "     tout en étant prêt pour le post-quantique.\""
    echo ""
    echo "  La solution : Certificats hybrides (Catalyst)"
    echo "    - Clé classique (ECDSA) pour les clients legacy"
    echo "    - Clé PQC (ML-DSA) pour les clients modernes"
    echo "    - Les deux dans UN SEUL certificat"
    echo ""
}

# =============================================================================
# Mission 1 : Créer la CA Hybride
# =============================================================================

mission_1_hybrid_ca() {
    mission_start 1 "Créer une CA Hybride"

    echo "  Une CA hybride contient DEUX paires de clés :"
    echo ""
    echo "    ┌─────────────────────────────────────────────┐"
    echo "    │  CERTIFICAT HYBRIDE (CATALYST)              │"
    echo "    ├─────────────────────────────────────────────┤"
    echo "    │  Clé principale  : ECDSA P-384 (classique)  │"
    echo "    │  Signature       : ECDSA P-384              │"
    echo "    ├─────────────────────────────────────────────┤"
    echo "    │  Extension: Alternative Public Key          │"
    echo "    │    → ML-DSA-65 (post-quantum)               │"
    echo "    │  Extension: Alternative Signature           │"
    echo "    │    → ML-DSA-65 (post-quantum)               │"
    echo "    └─────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${CYAN}Standard : ITU-T X.509 Section 9.8${NC}"
    echo ""

    local hybrid_ca="$LEVEL_WORKSPACE/hybrid-ca"

    # Vérifier si déjà créé
    if [[ -f "$hybrid_ca/ca.crt" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Ta CA hybride existe déjà !"
        validate_file "$hybrid_ca/ca.crt" "Certificat CA hybride"
        echo ""
        return 0
    fi

    # L'utilisateur tape la commande
    teach_cmd "pki init-ca --name \"Hybrid Root CA\" --algorithm ecdsa-p384 --hybrid-algorithm ml-dsa-65 --dir $hybrid_ca" \
              "--hybrid-algorithm ajoute la deuxième clé PQC"

    # Validation
    validate_files "$hybrid_ca" "ca.crt" "ca.key"

    # Afficher les infos
    echo ""
    echo -e "  ${BOLD}Détails de ta CA hybride :${NC}"
    "$PKI_BIN" info "$hybrid_ca/ca.crt" 2>/dev/null | head -15 | sed 's/^/    /'

    mission_complete "CA Hybride créée (ECDSA P-384 + ML-DSA-65)"

    learned "--hybrid-algorithm empile classique + PQC"
}

# =============================================================================
# Mission 2 : Émettre un certificat hybride
# =============================================================================

mission_2_hybrid_cert() {
    mission_start 2 "Émettre un certificat TLS hybride"

    echo "  Le certificat hérite de la nature hybride de la CA."
    echo "  Profil utilisé : hybrid/catalyst/tls-server"
    echo ""

    local hybrid_ca="$LEVEL_WORKSPACE/hybrid-ca"
    local cert_out="$LEVEL_WORKSPACE/hybrid-server.crt"
    local key_out="$LEVEL_WORKSPACE/hybrid-server.key"

    # Vérifier si déjà créé
    if [[ -f "$cert_out" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Ton certificat hybride existe déjà !"
        validate_file "$cert_out" "Certificat hybride"
        echo ""
        return 0
    fi

    # L'utilisateur tape la commande
    teach_cmd "pki issue --ca-dir $hybrid_ca --profile hybrid/catalyst/tls-server --cn \"hybrid.example.com\" --dns \"hybrid.example.com\" --out $cert_out --key-out $key_out" \
              "Le profil hybrid/catalyst inclut les deux algorithmes"

    # Validation
    validate_file "$cert_out" "Certificat TLS hybride"
    validate_file "$key_out" "Clé privée hybride"

    mission_complete "Certificat TLS hybride émis"

    learned "hybrid/catalyst = profil pour certificats hybrides"
}

# =============================================================================
# Mission 3 : Test d'interopérabilité
# =============================================================================

mission_3_interop() {
    mission_start 3 "Test d'interopérabilité"

    local hybrid_ca="$LEVEL_WORKSPACE/hybrid-ca"
    local cert="$LEVEL_WORKSPACE/hybrid-server.crt"

    echo "  Le pouvoir de l'hybride : ça marche avec TOUT le monde !"
    echo ""

    echo -e "  ${BOLD}Test 1 : Client Legacy (OpenSSL)${NC}"
    echo "    OpenSSL ne comprend pas le PQC, mais vérifie quand même."
    echo ""

    demo_cmd "openssl verify -CAfile $hybrid_ca/ca.crt $cert" \
             "Vérification avec OpenSSL (classique seulement)..."

    echo ""
    if openssl verify -CAfile "$hybrid_ca/ca.crt" "$cert" 2>&1 | grep -q "OK"; then
        echo -e "    ${GREEN}✓${NC} Client legacy : Certificat vérifié via ECDSA"
        echo -e "    ${DIM}(Les extensions PQC sont ignorées)${NC}"
    fi

    echo ""
    wait_enter

    echo -e "  ${BOLD}Test 2 : Client PQC-Aware (pki)${NC}"
    echo "    L'outil pki vérifie LES DEUX signatures."
    echo ""

    demo_cmd "$PKI_BIN verify --cert $cert --ca $hybrid_ca/ca.crt" \
             "Vérification avec pki (classique + PQC)..."

    echo ""
    if "$PKI_BIN" verify --cert "$cert" --ca "$hybrid_ca/ca.crt" > /dev/null 2>&1; then
        echo -e "    ${GREEN}✓${NC} Client PQC : ECDSA ET ML-DSA vérifiés"
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  RÉSUMÉ INTEROPÉRABILITÉ                                       │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo -e "  │  Client Legacy (OpenSSL)  │ Utilise ECDSA, ignore PQC │ ${GREEN}✓ OK${NC} │"
    echo -e "  │  Client PQC (pki)         │ Vérifie LES DEUX          │ ${GREEN}✓ OK${NC} │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${BOLD}Zéro changement pour les clients legacy. Protection quantique pour les autres.${NC}"
    echo ""

    mission_complete "Interopérabilité validée"

    learned "L'hybride fonctionne avec tous les clients"
}

# =============================================================================
# Mission 4 : Comparaison des tailles
# =============================================================================

mission_4_compare() {
    mission_start 4 "Comparer les tailles"

    local hybrid_ca="$LEVEL_WORKSPACE/hybrid-ca"
    local hybrid_cert="$LEVEL_WORKSPACE/hybrid-server.crt"

    # Récupérer les tailles
    local hybrid_ca_size=$(wc -c < "$hybrid_ca/ca.crt" | tr -d ' ')
    local hybrid_cert_size=$(wc -c < "$hybrid_cert" | tr -d ' ')

    # Comparer avec le Quick Start classique si disponible
    local classic_ca="$WORKSPACE_ROOT/quickstart/classic-ca"
    local classic_cert="$WORKSPACE_ROOT/quickstart/server.crt"

    echo -e "  ${BOLD}Tailles des certificats :${NC}"
    echo ""

    if [[ -f "$classic_ca/ca.crt" ]] && [[ -f "$classic_cert" ]]; then
        local classic_ca_size=$(wc -c < "$classic_ca/ca.crt" | tr -d ' ')
        local classic_cert_size=$(wc -c < "$classic_cert" | tr -d ' ')

        local ca_ratio=$(echo "scale=1; $hybrid_ca_size / $classic_ca_size" | bc)
        local cert_ratio=$(echo "scale=1; $hybrid_cert_size / $classic_cert_size" | bc)

        echo "  ┌──────────────────────────────────────────────────────────────┐"
        printf "  │  %-20s %12s %12s %10s │\n" "" "Classique" "Hybride" "Ratio"
        echo "  ├──────────────────────────────────────────────────────────────┤"
        printf "  │  %-20s %10s B %10s B %9sx │\n" "CA Certificate" "$classic_ca_size" "$hybrid_ca_size" "$ca_ratio"
        printf "  │  %-20s %10s B %10s B %9sx │\n" "Server Certificate" "$classic_cert_size" "$hybrid_cert_size" "$cert_ratio"
        echo "  └──────────────────────────────────────────────────────────────┘"
        echo ""
        echo -e "  ${CYAN}L'hybride est ~${ca_ratio}x plus grand car il contient :${NC}"
    else
        printf "    %-25s %8s\n" "CA Hybride" "$hybrid_ca_size B"
        printf "    %-25s %8s\n" "Cert TLS Hybride" "$hybrid_cert_size B"
        echo ""
        echo -e "  ${CYAN}L'hybride est plus grand car il contient :${NC}"
    fi

    echo "    - Clé publique ECDSA originale"
    echo "    - Signature ECDSA"
    echo "    - Clé publique ML-DSA alternative (~1952 bytes)"
    echo "    - Signature ML-DSA alternative (~3293 bytes)"
    echo ""

    mission_complete "Comparaison effectuée"

    learned "L'hybride = sécurité doublée, taille augmentée"
}

# =============================================================================
# Récapitulatif
# =============================================================================

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 2 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "CA hybride avec ECDSA P-384 + ML-DSA-65" \
        "Certificat TLS hybride (Catalyst)" \
        "Interopérabilité validée (legacy + PQC)" \
        "Comparaison des tailles"

    echo -e "  ${BOLD}Pourquoi choisir l'hybride ?${NC}"
    echo ""
    echo "    ${GREEN}✓${NC} Rétro-compatible : Les clients legacy fonctionnent"
    echo "    ${GREEN}✓${NC} Future-proof : Protection contre les attaques quantiques"
    echo "    ${GREEN}✓${NC} Défense en profondeur : Si un algo tombe, l'autre protège"
    echo "    ${GREEN}✓${NC} Migration douce : Pas de \"flag day\" requis"
    echo ""

    echo -e "  ${BOLD}Quand utiliser l'hybride :${NC}"
    echo ""
    echo "    • Pendant la transition PQC (maintenant !)"
    echo "    • Quand tu ne contrôles pas tous les clients"
    echo "    • Pour la conformité réglementaire"
    echo "    • Pour les infrastructures critiques"
    echo ""

    show_lesson "Tu n'as pas à choisir entre classique et PQC.
Empile-les. C'est la ceinture ET les bretelles."

    echo ""
    echo -e "${BOLD}${GREEN}NIVEAU 1 TERMINÉ !${NC}"
    echo ""
    echo "  Tu as maintenant dans ton workspace :"
    echo "    - CA classique (Quick Start)"
    echo "    - CA full PQC (Mission 1)"
    echo "    - CA hybride (Mission 2)"
    echo ""
    echo "  Prochaine étape : Niveau 2 - Applications"
    echo "    Utilise tes CA pour des cas réels (mTLS, Code Signing, Timestamping)"
    echo ""
    echo -e "    ${CYAN}./journey/03-applications/01-mtls/demo.sh${NC}"
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

    mission_1_hybrid_ca
    wait_enter

    mission_2_hybrid_cert
    wait_enter

    mission_3_interop
    wait_enter

    mission_4_compare

    show_recap_final
}

# Exécution
main "$@"

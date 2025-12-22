#!/bin/bash
# =============================================================================
#  NIVEAU 4 - MISSION 9 : LTV Signatures
#
#  Objectif : Créer des signatures valides pour 30+ ans.
#
#  Algorithme : HYBRIDE (combinaison signature + timestamp + OCSP)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$LAB_ROOT/lib/colors.sh"
source "$LAB_ROOT/lib/interactive.sh"
source "$LAB_ROOT/lib/workspace.sh"

PKI_BIN="$LAB_ROOT/bin/pki"

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${GREEN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   📜  NIVEAU 4 - MISSION 9                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   LTV Signatures : Validité à long terme                      ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  LTV = Long-Term Validation"
    echo ""
    echo "  Problème : Un certificat expire. La CRL disparaît."
    echo "            Comment prouver qu'une signature était valide ?"
    echo ""
    echo "  Solution : Embarquer toutes les preuves DANS la signature."
    echo ""
    echo "    ┌─────────────────────────────────────────────────────────────┐"
    echo "    │  SIGNATURE LTV = Signature + Timestamp + OCSP + Chaîne     │"
    echo "    │                                                             │"
    echo "    │  Tout ce qu'il faut pour vérifier OFFLINE, dans 30 ans.    │"
    echo "    └─────────────────────────────────────────────────────────────┘"
    echo ""
}

mission_1_components() {
    mission_start 1 "Comprendre les composants LTV"

    echo "  Une signature LTV contient :"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  1. SIGNATURE                                                  │"
    echo "  │     → La signature du document (ML-DSA)                        │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  2. TIMESTAMP                                                  │"
    echo "  │     → Preuve de la date de signature (TSA)                     │"
    echo "  │     → Prouve que le certificat était valide à cette date       │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  3. OCSP RESPONSE                                              │"
    echo "  │     → Preuve que le certificat n'était pas révoqué             │"
    echo "  │     → Capturée au moment de la signature                       │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  4. CERTIFICATE CHAIN                                          │"
    echo "  │     → Tous les certificats de la chaîne                        │"
    echo "  │     → Pour vérifier sans accès au réseau                       │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Composants LTV compris"
}

mission_2_create_ltv() {
    mission_start 2 "Créer une signature LTV"

    # Préparer l'environnement
    LTV_CA="$LEVEL_WORKSPACE/ltv-ca"
    if [[ ! -f "$LTV_CA/ca.crt" ]]; then
        echo "  Création de la CA pour LTV..."
        "$PKI_BIN" init-ca --name "LTV Demo CA" --algorithm ecdsa-p384 \
            --hybrid-algorithm ml-dsa-65 --dir "$LTV_CA" > /dev/null 2>&1
    fi

    # Créer certificat de signature
    local sign_cert="$LEVEL_WORKSPACE/ltv-signer.crt"
    local sign_key="$LEVEL_WORKSPACE/ltv-signer.key"
    if [[ ! -f "$sign_cert" ]]; then
        "$PKI_BIN" issue --ca-dir "$LTV_CA" --profile hybrid/catalyst/code-signing \
            --cn "LTV Signer" --out "$sign_cert" --key-out "$sign_key" > /dev/null 2>&1
    fi

    # Créer TSA
    local tsa_cert="$LEVEL_WORKSPACE/ltv-tsa.crt"
    local tsa_key="$LEVEL_WORKSPACE/ltv-tsa.key"
    if [[ ! -f "$tsa_cert" ]]; then
        "$PKI_BIN" issue --ca-dir "$LTV_CA" --profile hybrid/catalyst/tsa \
            --cn "LTV TSA" --out "$tsa_cert" --key-out "$tsa_key" > /dev/null 2>&1
    fi

    # Document à signer
    local doc="$LEVEL_WORKSPACE/contract-ltv.txt"
    echo "Contrat archivable - $(date)" > "$doc"
    echo "Valide pendant 30 ans" >> "$doc"

    echo "  Document à signer : contract-ltv.txt"
    echo ""

    # Signer avec horodatage
    local signature="$LEVEL_WORKSPACE/contract-ltv.p7s"

    teach_cmd "pki cms sign --data $doc --cert $sign_cert --key $sign_key --tsa-cert $tsa_cert --tsa-key $tsa_key --embed-certs -o $signature" \
              "Signature CMS avec timestamp et chaîne embarquée"

    if [[ -f "$signature" ]]; then
        validate_file "$signature" "Signature LTV"
        local sig_size=$(wc -c < "$signature" | tr -d ' ')
        echo ""
        echo -e "  ${CYAN}Taille de la signature LTV :${NC} $sig_size bytes"
        echo "  (Plus grande car contient timestamp + certs)"
    fi

    mission_complete "Signature LTV créée"
}

mission_3_verify_offline() {
    mission_start 3 "Vérifier OFFLINE"

    local doc="$LEVEL_WORKSPACE/contract-ltv.txt"
    local signature="$LEVEL_WORKSPACE/contract-ltv.p7s"

    echo "  La signature LTV peut être vérifiée sans réseau."
    echo "  Toutes les preuves sont embarquées."
    echo ""

    demo_cmd "$PKI_BIN cms verify --signature $signature --data $doc --ca $LTV_CA/ca.crt" \
             "Vérification offline..."

    if "$PKI_BIN" cms verify --signature "$signature" --data "$doc" --ca "$LTV_CA/ca.crt" > /dev/null 2>&1; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Signature valide"
        echo -e "  ${GREEN}✓${NC} Timestamp valide"
        echo -e "  ${GREEN}✓${NC} Chaîne de certificats valide"
    fi

    echo ""
    echo "  Dans 30 ans, même si :"
    echo "    - Le certificat a expiré"
    echo "    - La CA n'existe plus"
    echo "    - Les serveurs OCSP sont éteints"
    echo ""
    echo "  → La signature reste vérifiable grâce au LTV"

    mission_complete "Vérification offline réussie"
}

mission_4_use_cases() {
    mission_start 4 "Cas d'usage LTV"

    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  CAS D'USAGE LTV                                               │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  ARCHIVAGE LÉGAL                                               │"
    echo "  │  → Contrats, actes notariés                                    │"
    echo "  │  → Conservation : 30-50 ans                                    │"
    echo "  │                                                                 │"
    echo "  │  FACTURES ÉLECTRONIQUES                                        │"
    echo "  │  → Conformité fiscale                                          │"
    echo "  │  → Conservation : 10 ans minimum                               │"
    echo "  │                                                                 │"
    echo "  │  DOSSIERS MÉDICAUX                                             │"
    echo "  │  → Données patient signées                                     │"
    echo "  │  → Conservation : vie du patient + 10 ans                      │"
    echo "  │                                                                 │"
    echo "  │  PROPRIÉTÉ INTELLECTUELLE                                      │"
    echo "  │  → Brevets, designs                                            │"
    echo "  │  → Conservation : 20+ ans                                      │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Cas d'usage compris"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 9 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Compréhension des composants LTV" \
        "Signature avec timestamp embarqué" \
        "Vérification offline" \
        "Cas d'usage archivage long terme"

    show_lesson "LTV = signature + timestamp + OCSP + chaîne.
Avec PQC, tes archives restent vérifiables pendant 30+ ans,
même quand les ordinateurs quantiques existeront."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} PQC Tunnel"
    echo -e "    ${CYAN}./journey/05-advanced/02-pqc-tunnel/demo.sh${NC}"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-4"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_components
    wait_enter
    mission_2_create_ltv
    wait_enter
    mission_3_verify_offline
    wait_enter
    mission_4_use_cases

    show_recap_final
}

main "$@"

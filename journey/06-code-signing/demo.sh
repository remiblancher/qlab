#!/bin/bash
# =============================================================================
#  NIVEAU 2 - MISSION 4 : Code Signing PQC
#
#  Objectif : Signer du code avec ML-DSA pour une protection long terme.
#
#  Algorithme : ML-DSA-65
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$LAB_ROOT/lib/colors.sh"
source "$LAB_ROOT/lib/interactive.sh"
source "$LAB_ROOT/lib/workspace.sh"

PKI_BIN="$LAB_ROOT/bin/pki"

# =============================================================================
# Bannière
# =============================================================================

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${BLUE}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   ✍️  NIVEAU 2 - MISSION 4                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Code Signing Post-Quantum                                   ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Durée estimée :${NC} 8 minutes"
    echo -e "  ${BOLD}Algorithme    :${NC} ML-DSA-65"
    echo ""
    echo "  Le problème :"
    echo "    \"Un binaire signé en 2024 sera peut-être vérifié en 2034."
    echo "     Si les ordinateurs quantiques forgent les signatures ECDSA..."
    echo "     Des malwares pourraient paraître légitimes.\""
    echo ""
    echo "  La solution : Signer avec ML-DSA (quantum-resistant)"
    echo ""
}

# =============================================================================
# Missions
# =============================================================================

mission_1_ca() {
    mission_start 1 "Préparer la CA Code Signing"

    local pqc_ca="$WORKSPACE_ROOT/niveau-1/pqc-issuing-ca"

    if [[ -f "$pqc_ca/ca.crt" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Réutilisation de ta CA PQC du Niveau 1"
        CODE_CA="$pqc_ca"
    else
        CODE_CA="$LEVEL_WORKSPACE/code-signing-ca"
        if [[ ! -f "$CODE_CA/ca.crt" ]]; then
            teach_cmd "pki init-ca --name \"Code Signing CA\" --algorithm ml-dsa-65 --dir $CODE_CA" \
                      "CA dédiée à la signature de code"
        fi
    fi

    validate_file "$CODE_CA/ca.crt" "CA Code Signing"
    mission_complete "CA Code Signing prête"
}

mission_2_cert() {
    mission_start 2 "Émettre un certificat Code Signing"

    local cert="$LEVEL_WORKSPACE/code-signing.crt"
    local key="$LEVEL_WORKSPACE/code-signing.key"

    echo "  Profil : ml-dsa/code-signing"
    echo "    - Extended Key Usage : codeSigning"
    echo "    - Valide pour signer des binaires, scripts, firmware"
    echo ""

    if [[ -f "$cert" ]]; then
        echo -e "${YELLOW}[INFO]${NC} Le certificat existe déjà !"
    else
        teach_cmd "pki issue --ca-dir $CODE_CA --profile ml-dsa/code-signing --cn \"ACME Software\" --out $cert --key-out $key" \
                  "Certificat pour signer du code avec ML-DSA-65"
    fi

    validate_file "$cert" "Certificat Code Signing"
    mission_complete "Certificat Code Signing émis"
}

mission_3_sign() {
    mission_start 3 "Signer un binaire"

    local cert="$LEVEL_WORKSPACE/code-signing.crt"
    local key="$LEVEL_WORKSPACE/code-signing.key"
    local firmware="$LEVEL_WORKSPACE/firmware-v1.0.bin"
    local signature="$LEVEL_WORKSPACE/firmware-v1.0.p7s"

    # Créer un faux firmware
    if [[ ! -f "$firmware" ]]; then
        echo "  Création d'un firmware de test (100 KB)..."
        dd if=/dev/urandom of="$firmware" bs=1024 count=100 2>/dev/null
    fi

    echo ""
    echo "  Format de signature : CMS/PKCS#7 (standard industrie)"
    echo ""

    if [[ -f "$signature" ]]; then
        echo -e "${YELLOW}[INFO]${NC} La signature existe déjà !"
    else
        teach_cmd "pki cms sign --data $firmware --cert $cert --key $key -o $signature" \
                  "Signature CMS détachée du firmware"
    fi

    validate_file "$signature" "Signature CMS (.p7s)"

    local sig_size=$(wc -c < "$signature" | tr -d ' ')
    echo ""
    echo -e "  ${CYAN}Taille de la signature :${NC} $sig_size bytes"
    echo -e "  ${DIM}(La signature ML-DSA fait ~3300 bytes)${NC}"

    mission_complete "Firmware signé avec ML-DSA-65"
}

mission_4_verify() {
    mission_start 4 "Vérifier la signature"

    local firmware="$LEVEL_WORKSPACE/firmware-v1.0.bin"
    local signature="$LEVEL_WORKSPACE/firmware-v1.0.p7s"

    echo "  Simulation de vérification côté client..."
    echo ""

    demo_cmd "$PKI_BIN cms verify --signature $signature --data $firmware --ca $CODE_CA/ca.crt" \
             "Vérification de la signature CMS..."

    if "$PKI_BIN" cms verify --signature "$signature" --data "$firmware" --ca "$CODE_CA/ca.crt" > /dev/null 2>&1; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Signature valide !"
        echo -e "  ${GREEN}✓${NC} Le firmware n'a pas été modifié"
        echo -e "  ${GREEN}✓${NC} Signé par un certificat de confiance"
    fi

    echo ""
    echo "  Cette signature restera valide même quand les ordinateurs"
    echo "  quantiques pourront forger des signatures ECDSA."

    mission_complete "Signature vérifiée"
}

# =============================================================================
# Récapitulatif
# =============================================================================

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 4 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Certificat Code Signing avec ML-DSA-65" \
        "Signature CMS d'un firmware" \
        "Vérification de l'intégrité"

    echo -e "  ${BOLD}Durée de vie des logiciels signés :${NC}"
    echo ""
    echo "    Firmware IoT         : 10-20 ans  → ${RED}PQC maintenant${NC}"
    echo "    Systèmes industriels : 15-30 ans  → ${RED}PQC maintenant${NC}"
    echo "    Dispositifs médicaux : 10-15 ans  → ${RED}PQC maintenant${NC}"
    echo "    Logiciels desktop    : 5-10 ans   → ${YELLOW}Planifier PQC${NC}"
    echo ""

    show_lesson "Les signatures de code doivent rester valides pendant des années.
ML-DSA garantit qu'elles ne peuvent pas être forgées, même par des ordinateurs quantiques."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} Timestamping"
    echo -e "    ${CYAN}./journey/03-applications/03-timestamping/demo.sh${NC}"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-2"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_ca
    wait_enter
    mission_2_cert
    wait_enter
    mission_3_sign
    wait_enter
    mission_4_verify

    show_recap_final
}

main "$@"

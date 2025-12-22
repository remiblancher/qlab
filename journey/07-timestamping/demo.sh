#!/bin/bash
# =============================================================================
#  NIVEAU 2 - MISSION 5 : Timestamping PQC
#
#  Objectif : Horodater des documents avec ML-DSA pour preuve dans le temps.
#
#  Algorithme : ML-DSA-65 (TSA)
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
    echo -e "${BOLD}${YELLOW}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🕐  NIVEAU 2 - MISSION 5                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Timestamping Post-Quantum                                   ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Durée estimée :${NC} 8 minutes"
    echo -e "  ${BOLD}Algorithme    :${NC} ML-DSA-65"
    echo ""
    echo "  L'horodatage prouve qu'un document existait à un moment donné."
    echo ""
    echo "    ┌──────────────────────────────────────────────────────────┐"
    echo "    │  DOCUMENT  ──►  HASH  ──►  TSA  ──►  TIMESTAMP TOKEN     │"
    echo "    │                                                          │"
    echo "    │  \"Ce document existait le 2024-12-21 à 14:30:00 UTC\"    │"
    echo "    └──────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Cas d'usage : contrats, propriété intellectuelle, conformité"
    echo ""
}

# =============================================================================
# Missions
# =============================================================================

mission_1_tsa() {
    mission_start 1 "Créer une TSA (Time Stamping Authority)"

    TSA_DIR="$LEVEL_WORKSPACE/tsa"

    echo "  Une TSA est une autorité qui signe des horodatages."
    echo "  Elle a besoin d'un certificat avec EKU: timeStamping"
    echo ""

    if [[ -f "$TSA_DIR/tsa.crt" ]]; then
        echo -e "${YELLOW}[INFO]${NC} La TSA existe déjà !"
        validate_file "$TSA_DIR/tsa.crt" "Certificat TSA"
        return 0
    fi

    # Créer une CA pour la TSA si nécessaire
    local tsa_ca="$LEVEL_WORKSPACE/tsa-ca"
    if [[ ! -f "$tsa_ca/ca.crt" ]]; then
        echo "  Création de la CA pour la TSA..."
        "$PKI_BIN" init-ca --name "TSA Root CA" --algorithm ml-dsa-65 --dir "$tsa_ca" > /dev/null 2>&1
    fi

    mkdir -p "$TSA_DIR"

    teach_cmd "pki issue --ca-dir $tsa_ca --profile ml-dsa/tsa --cn \"PQC Timestamp Authority\" --out $TSA_DIR/tsa.crt --key-out $TSA_DIR/tsa.key" \
              "Profil TSA avec Extended Key Usage: timeStamping"

    validate_file "$TSA_DIR/tsa.crt" "Certificat TSA"

    # Copier la CA pour la vérification
    cp "$tsa_ca/ca.crt" "$TSA_DIR/ca.crt"

    mission_complete "TSA créée avec ML-DSA-65"
    learned "Une TSA signe des preuves d'existence dans le temps"
}

mission_2_timestamp() {
    mission_start 2 "Horodater un document"

    local doc="$LEVEL_WORKSPACE/contract.txt"
    local tsr="$LEVEL_WORKSPACE/contract.tsr"

    # Créer un document de test
    if [[ ! -f "$doc" ]]; then
        echo "Contrat de vente - Version finale" > "$doc"
        echo "Date: $(date)" >> "$doc"
        echo "Parties: Alice et Bob" >> "$doc"
        echo "Montant: 100,000 EUR" >> "$doc"
    fi

    echo "  Document à horodater : contract.txt"
    echo ""
    cat "$doc" | sed 's/^/    /'
    echo ""

    if [[ -f "$tsr" ]]; then
        echo -e "${YELLOW}[INFO]${NC} L'horodatage existe déjà !"
    else
        teach_cmd "pki tsa stamp --data $doc --cert $TSA_DIR/tsa.crt --key $TSA_DIR/tsa.key -o $tsr" \
                  "Création d'un timestamp token (TSR)"
    fi

    validate_file "$tsr" "Timestamp Response (.tsr)"

    local tsr_size=$(wc -c < "$tsr" | tr -d ' ')
    echo ""
    echo -e "  ${CYAN}Taille du token :${NC} $tsr_size bytes"

    mission_complete "Document horodaté"
    learned "Le TSR contient : hash du document + date + signature TSA"
}

mission_3_verify() {
    mission_start 3 "Vérifier l'horodatage"

    local doc="$LEVEL_WORKSPACE/contract.txt"
    local tsr="$LEVEL_WORKSPACE/contract.tsr"

    echo "  Vérification que le document n'a pas été modifié"
    echo "  et que l'horodatage est valide."
    echo ""

    demo_cmd "$PKI_BIN tsa verify --data $doc --response $tsr --ca $TSA_DIR/ca.crt" \
             "Vérification du timestamp..."

    if "$PKI_BIN" tsa verify --data "$doc" --response "$tsr" --ca "$TSA_DIR/ca.crt" > /dev/null 2>&1; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Horodatage valide"
        echo -e "  ${GREEN}✓${NC} Document non modifié depuis l'horodatage"
        echo -e "  ${GREEN}✓${NC} Signé par une TSA de confiance"
    fi

    echo ""
    wait_enter

    # Test avec document modifié
    echo -e "  ${BOLD}Test : Et si le document est modifié ?${NC}"
    echo ""

    local modified="$LEVEL_WORKSPACE/contract-modified.txt"
    cp "$doc" "$modified"
    echo "MODIFICATION FRAUDULEUSE" >> "$modified"

    echo "  Document modifié après horodatage..."
    echo ""

    if ! "$PKI_BIN" tsa verify --data "$modified" --response "$tsr" --ca "$TSA_DIR/ca.crt" > /dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} ÉCHEC de vérification !"
        echo -e "  ${RED}✗${NC} Le document a été modifié après l'horodatage"
    fi

    echo ""
    echo -e "  ${CYAN}L'horodatage protège l'intégrité ET prouve la date.${NC}"

    mission_complete "Horodatage vérifié"
}

mission_4_longevity() {
    mission_start 4 "Comprendre la valeur long terme"

    echo "  Pourquoi l'horodatage PQC est crucial :"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  AUJOURD'HUI (2024)                                            │"
    echo "  │    → Tu horodates un brevet avec ML-DSA                        │"
    echo "  │    → Preuve d'antériorité créée                                │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  DANS 20 ANS (2044)                                            │"
    echo "  │    → Litige sur la propriété intellectuelle                    │"
    echo "  │    → Les ordinateurs quantiques existent                       │"
    echo "  │    → Horodatage ECDSA = forgeable = invalide                   │"
    echo "  │    → Horodatage ML-DSA = vérifiable = preuve valide            │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    echo -e "  ${BOLD}Durée de conservation typique :${NC}"
    echo ""
    echo "    Brevets           : 20 ans   → ${RED}PQC obligatoire${NC}"
    echo "    Contrats          : 10-30 ans → ${RED}PQC obligatoire${NC}"
    echo "    Archives légales  : 30-50 ans → ${RED}PQC obligatoire${NC}"
    echo "    Logs conformité   : 7-10 ans  → ${YELLOW}PQC recommandé${NC}"
    echo ""

    mission_complete "Valeur long terme comprise"
    learned "L'horodatage PQC = preuve vérifiable dans 30+ ans"
}

# =============================================================================
# Récapitulatif
# =============================================================================

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 5 TERMINÉE ! ${NC}"
    echo ""
    echo -e "${BOLD}${GREEN} NIVEAU 2 COMPLET !${NC}"
    echo ""

    show_recap "Ce que tu as accompli dans le Niveau 2 :" \
        "mTLS : Authentification mutuelle PQC" \
        "Code Signing : Signatures de binaires ML-DSA" \
        "Timestamping : Horodatage pour preuve légale"

    show_lesson "Les applications PKI fonctionnent de la même manière avec PQC.
mTLS, Code Signing, Timestamping : mêmes workflows, algorithmes différents.
La protection long terme est maintenant garantie."

    echo ""
    echo -e "${BOLD}Prochaine étape :${NC} Niveau 3 - Ops & Lifecycle"
    echo "  Gestion du cycle de vie : révocation, OCSP, crypto-agilité"
    echo ""
    echo -e "    ${CYAN}./journey/04-ops-lifecycle/01-revocation/demo.sh${NC}"
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

    mission_1_tsa
    wait_enter
    mission_2_timestamp
    wait_enter
    mission_3_verify
    wait_enter
    mission_4_longevity

    show_recap_final
}

main "$@"

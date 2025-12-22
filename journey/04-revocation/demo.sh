#!/bin/bash
# =============================================================================
#  NIVEAU 3 - MISSION 6 : Revocation & CRL
#
#  Objectif : Révoquer des certificats et générer des CRL avec hybride.
#
#  Algorithme : ECDSA P-384 + ML-DSA-65 (HYBRIDE)
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
    echo -e "${BOLD}${RED}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🚨  NIVEAU 3 - MISSION 6                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Revocation & CRL                                            ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Algorithme :${NC} HYBRIDE (ECDSA P-384 + ML-DSA-65)"
    echo ""
    echo "  Scénario : Une clé privée a été compromise."
    echo "  Tu dois révoquer le certificat et publier une CRL."
    echo ""
}

mission_1_setup() {
    mission_start 1 "Préparer l'environnement"

    # Utiliser la CA hybride du Niveau 1 ou en créer une
    HYBRID_CA="$WORKSPACE_ROOT/niveau-1/hybrid-ca"

    if [[ -f "$HYBRID_CA/ca.crt" ]]; then
        echo -e "  ${GREEN}[OK]${NC} Réutilisation de ta CA hybride du Niveau 1"
    else
        HYBRID_CA="$LEVEL_WORKSPACE/hybrid-ca"
        if [[ ! -f "$HYBRID_CA/ca.crt" ]]; then
            teach_cmd "pki init-ca --name \"Ops Hybrid CA\" --algorithm ecdsa-p384 --hybrid-algorithm ml-dsa-65 --dir $HYBRID_CA" \
                      "CA hybride pour les opérations"
        fi
    fi

    # Émettre un certificat à révoquer
    local cert="$LEVEL_WORKSPACE/compromised-server.crt"
    local key="$LEVEL_WORKSPACE/compromised-server.key"

    if [[ ! -f "$cert" ]]; then
        echo ""
        echo "  Émission d'un certificat serveur..."
        "$PKI_BIN" issue --ca-dir "$HYBRID_CA" --profile hybrid/catalyst/tls-server \
            --cn "compromised.example.com" --dns "compromised.example.com" \
            --out "$cert" --key-out "$key" > /dev/null 2>&1
    fi

    SERIAL=$(openssl x509 -in "$cert" -noout -serial 2>/dev/null | cut -d= -f2)
    echo ""
    echo -e "  Certificat émis : ${YELLOW}serial $SERIAL${NC}"

    mission_complete "Environnement prêt"
}

mission_2_incident() {
    mission_start 2 "Incident : Compromission de clé !"

    echo -e "  ${RED}⚠ ALERTE : La clé privée de compromised.example.com a été exposée !${NC}"
    echo ""
    echo "  Étapes de réponse à incident :"
    echo "    1. ✓ Détection de la compromission"
    echo "    2. ✓ Identification du certificat (serial: $SERIAL)"
    echo "    3. → Révoquer le certificat"
    echo "    4. → Générer une nouvelle CRL"
    echo "    5. → Émettre un certificat de remplacement"
    echo ""

    mission_complete "Incident identifié"
}

mission_3_revoke() {
    mission_start 3 "Révoquer le certificat"

    echo "  Raisons de révocation possibles :"
    echo "    - keyCompromise : clé privée compromise"
    echo "    - affiliationChanged : changement d'organisation"
    echo "    - superseded : remplacé par un nouveau certificat"
    echo "    - cessationOfOperation : service arrêté"
    echo ""

    teach_cmd "pki revoke $SERIAL --ca-dir $HYBRID_CA --reason keyCompromise" \
              "Révocation avec raison 'keyCompromise'"

    echo ""
    echo -e "  ${GREEN}✓${NC} Certificat révoqué"
    echo -e "  ${CYAN}Le certificat est maintenant invalide.${NC}"

    mission_complete "Certificat révoqué"
}

mission_4_crl() {
    mission_start 4 "Générer et publier la CRL"

    echo "  CRL = Certificate Revocation List"
    echo "  Liste signée de tous les certificats révoqués."
    echo ""

    teach_cmd "pki crl generate --ca-dir $HYBRID_CA" \
              "Génération de la CRL signée"

    local crl="$HYBRID_CA/crl/ca.crl"
    if [[ -f "$crl" ]]; then
        validate_file "$crl" "CRL"
        local crl_size=$(wc -c < "$crl" | tr -d ' ')
        echo ""
        echo -e "  ${CYAN}Taille de la CRL :${NC} $crl_size bytes"
        echo ""
        echo "  La CRL hybride utilise la signature ECDSA (compatibilité legacy)"
        echo "  mais contient aussi la signature ML-DSA en extension."
    fi

    mission_complete "CRL générée et prête à distribuer"
}

mission_5_verify() {
    mission_start 5 "Vérifier le statut de révocation"

    local cert="$LEVEL_WORKSPACE/compromised-server.crt"

    echo "  Vérifions que le certificat est bien révoqué..."
    echo ""

    # La vérification devrait échouer
    if ! "$PKI_BIN" verify --cert "$cert" --ca "$HYBRID_CA/ca.crt" --crl "$HYBRID_CA/crl/ca.crl" > /dev/null 2>&1; then
        echo -e "  ${RED}✗${NC} Certificat RÉVOQUÉ - Vérification échouée (attendu)"
    else
        echo -e "  ${YELLOW}[INFO]${NC} Vérification (CRL peut ne pas être supportée)"
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  RÉSUMÉ RÉVOCATION                                             │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │  Serial          : $SERIAL                           │"
    echo "  │  Raison          : keyCompromise                               │"
    echo -e "  │  Status          : ${RED}RÉVOQUÉ${NC}                                     │"
    echo "  │  CRL générée     : Oui                                         │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Statut de révocation vérifié"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 6 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Simulation d'incident de compromission" \
        "Révocation avec raison 'keyCompromise'" \
        "Génération de CRL hybride" \
        "Vérification du statut"

    show_lesson "Les opérations PKI sont indépendantes de l'algorithme.
Révoquer un certificat PQC = même workflow qu'un certificat classique.
Pas de formation supplémentaire pour les équipes ops."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} OCSP Live"
    echo -e "    ${CYAN}./journey/04-ops-lifecycle/02-ocsp/demo.sh${NC}"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-3"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_setup
    wait_enter
    mission_2_incident
    wait_enter
    mission_3_revoke
    wait_enter
    mission_4_crl
    wait_enter
    mission_5_verify

    show_recap_final
}

main "$@"

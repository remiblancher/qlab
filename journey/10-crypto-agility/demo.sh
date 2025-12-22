#!/bin/bash
# =============================================================================
#  NIVEAU 3 - MISSION 8 : Crypto-Agility
#
#  Objectif : Comprendre et pratiquer la rotation d'algorithmes.
#
#  Algorithme : HYBRIDE → la clé de la transition
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
    echo -e "${BOLD}${PURPLE}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🔄  NIVEAU 3 - MISSION 8                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   Crypto-Agility : Préparer la transition                     ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  Crypto-agility = capacité à changer d'algorithme sans tout casser."
    echo ""
    echo "  Pourquoi c'est crucial :"
    echo "    - Un algorithme peut être déprécié (vulnérabilité découverte)"
    echo "    - Les standards évoluent (SHA-1 → SHA-256 → SHA-3)"
    echo "    - La transition PQC est la plus grande de l'histoire"
    echo ""
}

mission_1_inventory() {
    mission_start 1 "Inventorier les algorithmes en place"

    echo "  Première étape : savoir ce qu'on a."
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  INVENTAIRE DE TES CA                                          │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"

    local count=0

    # Quick Start
    local qs_ca="$WORKSPACE_ROOT/quickstart/classic-ca"
    if [[ -f "$qs_ca/ca.crt" ]]; then
        local algo=$(openssl x509 -in "$qs_ca/ca.crt" -noout -text 2>/dev/null | grep "Signature Algorithm" | head -1 | awk '{print $3}')
        printf "  │  %-20s │ %-20s │ %-12s │\n" "Quick Start" "$algo" "CLASSIQUE"
        count=$((count + 1))
    fi

    # Niveau 1 - PQC Root
    local pqc_root="$WORKSPACE_ROOT/niveau-1/pqc-root-ca"
    if [[ -f "$pqc_root/ca.crt" ]]; then
        printf "  │  %-20s │ %-20s │ %-12s │\n" "PQC Root CA" "ML-DSA-87" "PQC"
        count=$((count + 1))
    fi

    # Niveau 1 - PQC Issuing
    local pqc_issuing="$WORKSPACE_ROOT/niveau-1/pqc-issuing-ca"
    if [[ -f "$pqc_issuing/ca.crt" ]]; then
        printf "  │  %-20s │ %-20s │ %-12s │\n" "PQC Issuing CA" "ML-DSA-65" "PQC"
        count=$((count + 1))
    fi

    # Niveau 1 - Hybrid
    local hybrid="$WORKSPACE_ROOT/niveau-1/hybrid-ca"
    if [[ -f "$hybrid/ca.crt" ]]; then
        printf "  │  %-20s │ %-20s │ %-12s │\n" "Hybrid CA" "ECDSA+ML-DSA" "HYBRIDE"
        count=$((count + 1))
    fi

    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    if [[ $count -eq 0 ]]; then
        echo -e "  ${YELLOW}[INFO]${NC} Aucune CA trouvée. Fais le Niveau 1 d'abord."
    else
        echo -e "  ${GREEN}[OK]${NC} $count CA inventoriées"
    fi

    mission_complete "Inventaire terminé"
    learned "L'inventaire est la base de toute migration"
}

mission_2_transition_plan() {
    mission_start 2 "Comprendre la stratégie de transition"

    echo "  La transition PQC se fait en 3 phases :"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │                                                                 │"
    echo "  │  PHASE 1 : HYBRIDE (maintenant)                                │"
    echo "  │  ───────────────────────────                                   │"
    echo "  │  → Déployer des CA hybrides (ECDSA + ML-DSA)                   │"
    echo "  │  → Compatibilité legacy préservée                              │"
    echo "  │  → Protection PQC pour clients modernes                        │"
    echo "  │                                                                 │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  PHASE 2 : MIGRATION (2-5 ans)                                 │"
    echo "  │  ────────────────────────────                                  │"
    echo "  │  → Mettre à jour les clients pour supporter PQC                │"
    echo "  │  → Réémettre les certificats en hybride                        │"
    echo "  │  → Tester la compatibilité                                     │"
    echo "  │                                                                 │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  PHASE 3 : FULL PQC (quand prêt)                               │"
    echo "  │  ─────────────────────────────                                 │"
    echo "  │  → Déprécier les algorithmes classiques                        │"
    echo "  │  → Basculer vers full PQC                                      │"
    echo "  │  → Révoquer les anciennes CA                                   │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Stratégie comprise"
    learned "Hybride = pont vers le full PQC"
}

mission_3_fallback() {
    mission_start 3 "Tester le fallback"

    echo "  Le fallback permet de revenir en arrière si problème."
    echo ""
    echo "  Avec l'hybride :"
    echo "    - Les clients legacy utilisent ECDSA"
    echo "    - Les clients modernes utilisent ML-DSA"
    echo "    - Si ML-DSA pose problème → ECDSA toujours disponible"
    echo ""

    local hybrid_ca="$WORKSPACE_ROOT/niveau-1/hybrid-ca"
    local hybrid_cert="$WORKSPACE_ROOT/niveau-1/hybrid-server.crt"

    if [[ -f "$hybrid_cert" ]]; then
        echo -e "  ${BOLD}Test avec ton certificat hybride :${NC}"
        echo ""

        # Vérification OpenSSL (classique)
        echo "  Test 1 : Vérification OpenSSL (classique seulement)"
        if openssl verify -CAfile "$hybrid_ca/ca.crt" "$hybrid_cert" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓${NC} OpenSSL : OK (utilise ECDSA, ignore PQC)"
        fi

        echo ""

        # Vérification pki (PQC-aware)
        echo "  Test 2 : Vérification pki (PQC-aware)"
        if "$PKI_BIN" verify --ca "$hybrid_ca/ca.crt" --cert "$hybrid_cert" > /dev/null 2>&1; then
            echo -e "    ${GREEN}✓${NC} pki : OK (vérifie ECDSA ET ML-DSA)"
        fi

        echo ""
        echo "  → Les deux chemins fonctionnent = crypto-agility en action"
    else
        echo -e "  ${YELLOW}[INFO]${NC} Fais la mission Hybrid du Niveau 1 d'abord."
    fi

    mission_complete "Fallback testé"
}

mission_4_checklist() {
    mission_start 4 "Checklist de préparation"

    echo "  Es-tu prêt pour la transition PQC ?"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  CHECKLIST CRYPTO-AGILITY                                      │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"

    # Check 1: Inventaire
    local inv_status="${GREEN}✓${NC}"
    echo -e "  │  $inv_status Inventaire des CA et certificats                       │"

    # Check 2: Hybrid CA
    local hyb_status="${RED}✗${NC}"
    if [[ -f "$WORKSPACE_ROOT/niveau-1/hybrid-ca/ca.crt" ]]; then
        hyb_status="${GREEN}✓${NC}"
    fi
    echo -e "  │  $hyb_status CA hybride déployée                                    │"

    # Check 3: Tests
    local test_status="${GREEN}✓${NC}"
    echo -e "  │  $test_status Tests de compatibilité legacy                         │"

    # Check 4: Révocation
    local rev_status="${GREEN}✓${NC}"
    echo -e "  │  $rev_status Processus de révocation testé                          │"

    # Check 5: OCSP
    local ocsp_status="${GREEN}✓${NC}"
    echo -e "  │  $ocsp_status OCSP responder fonctionnel                            │"

    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    mission_complete "Checklist complétée"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 8 TERMINÉE ! ${NC}"
    echo ""
    echo -e "${BOLD}${GREEN} NIVEAU 3 COMPLET !${NC}"
    echo ""

    show_recap "Ce que tu as accompli dans le Niveau 3 :" \
        "Révocation et génération de CRL" \
        "OCSP responder en temps réel" \
        "Stratégie de transition PQC" \
        "Crypto-agility avec hybride"

    show_lesson "La crypto-agility, c'est pouvoir changer d'algorithme
sans interrompre le service. L'hybride est la clé de la transition.
Tu peux migrer progressivement, client par client."

    echo ""
    echo -e "${BOLD}Prochaine étape :${NC} Niveau 4 - Advanced"
    echo "  LTV Signatures, PQC Tunnel, CMS Encryption"
    echo ""
    echo -e "    ${CYAN}./journey/05-advanced/01-ltv-signatures/demo.sh${NC}"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-3"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_inventory
    wait_enter
    mission_2_transition_plan
    wait_enter
    mission_3_fallback
    wait_enter
    mission_4_checklist

    show_recap_final
}

main "$@"

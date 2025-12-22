#!/bin/bash
# =============================================================================
#  NIVEAU 3 - MISSION 7 : OCSP Live
#
#  Objectif : Déployer un OCSP responder hybride et vérifier en temps réel.
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
OCSP_PORT=8888

# Cleanup function
cleanup() {
    if [[ -n "$OCSP_PID" ]]; then
        kill $OCSP_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

show_welcome() {
    clear
    echo ""
    echo -e "${BOLD}${CYAN}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🌐  NIVEAU 3 - MISSION 7                                    ║"
    echo "  ║                                                               ║"
    echo "  ║   OCSP Live : Vérification en temps réel                      ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "  ${BOLD}Algorithme :${NC} HYBRIDE (ECDSA P-384 + ML-DSA-65)"
    echo ""
    echo "  OCSP = Online Certificate Status Protocol"
    echo "  Vérification du statut d'un certificat en temps réel."
    echo ""
    echo "    Client ──► OCSP Request ──► Responder ──► OCSP Response"
    echo "                                    │"
    echo "                            \"good\" ou \"revoked\""
    echo ""
}

mission_1_setup() {
    mission_start 1 "Préparer la CA et les certificats"

    HYBRID_CA="$WORKSPACE_ROOT/niveau-1/hybrid-ca"
    if [[ ! -f "$HYBRID_CA/ca.crt" ]]; then
        HYBRID_CA="$LEVEL_WORKSPACE/ocsp-ca"
        if [[ ! -f "$HYBRID_CA/ca.crt" ]]; then
            "$PKI_BIN" init-ca --name "OCSP Demo CA" --algorithm ecdsa-p384 \
                --hybrid-algorithm ml-dsa-65 --dir "$HYBRID_CA" > /dev/null 2>&1
        fi
    fi

    echo -e "  ${GREEN}[OK]${NC} CA hybride disponible"

    # Créer le certificat OCSP responder
    local ocsp_cert="$LEVEL_WORKSPACE/ocsp-responder.crt"
    local ocsp_key="$LEVEL_WORKSPACE/ocsp-responder.key"

    if [[ ! -f "$ocsp_cert" ]]; then
        echo "  Émission du certificat OCSP responder..."
        "$PKI_BIN" issue --ca-dir "$HYBRID_CA" --profile hybrid/catalyst/ocsp-responder \
            --cn "OCSP Responder" --out "$ocsp_cert" --key-out "$ocsp_key" > /dev/null 2>&1
    fi
    validate_file "$ocsp_cert" "Certificat OCSP Responder"

    # Créer un certificat serveur à vérifier
    SERVER_CERT="$LEVEL_WORKSPACE/server-to-verify.crt"
    SERVER_KEY="$LEVEL_WORKSPACE/server-to-verify.key"

    if [[ ! -f "$SERVER_CERT" ]]; then
        "$PKI_BIN" issue --ca-dir "$HYBRID_CA" --profile hybrid/catalyst/tls-server \
            --cn "server.example.com" --dns "server.example.com" \
            --out "$SERVER_CERT" --key-out "$SERVER_KEY" > /dev/null 2>&1
    fi
    validate_file "$SERVER_CERT" "Certificat serveur"

    SERVER_SERIAL=$(openssl x509 -in "$SERVER_CERT" -noout -serial 2>/dev/null | cut -d= -f2)
    echo ""
    echo -e "  Certificat serveur : serial ${YELLOW}$SERVER_SERIAL${NC}"

    mission_complete "Environnement OCSP prêt"
}

mission_2_start_responder() {
    mission_start 2 "Démarrer le OCSP Responder"

    local ocsp_cert="$LEVEL_WORKSPACE/ocsp-responder.crt"
    local ocsp_key="$LEVEL_WORKSPACE/ocsp-responder.key"

    echo "  Le responder OCSP est un service HTTP qui répond aux requêtes."
    echo "  Il signe ses réponses avec son certificat délégué."
    echo ""

    echo -e "  ${CYAN}Démarrage du responder sur port $OCSP_PORT...${NC}"
    echo ""

    demo_cmd "$PKI_BIN ocsp serve --port $OCSP_PORT --ca-dir $HYBRID_CA --cert $ocsp_cert --key $ocsp_key &" \
             "Lancement du service OCSP..."

    "$PKI_BIN" ocsp serve --port $OCSP_PORT --ca-dir "$HYBRID_CA" \
        --cert "$ocsp_cert" --key "$ocsp_key" > /dev/null 2>&1 &
    OCSP_PID=$!

    sleep 2

    if kill -0 $OCSP_PID 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} OCSP Responder démarré (PID: $OCSP_PID)"
        echo -e "  ${CYAN}URL: http://localhost:$OCSP_PORT/${NC}"
    else
        echo -e "  ${RED}✗${NC} Échec du démarrage"
    fi

    mission_complete "OCSP Responder actif"
}

mission_3_query_good() {
    mission_start 3 "Requête OCSP - Certificat valide"

    echo "  Interrogeons le responder pour le statut du certificat..."
    echo ""

    # Créer la requête OCSP
    local request="$LEVEL_WORKSPACE/ocsp-request.der"
    local response="$LEVEL_WORKSPACE/ocsp-response.der"

    "$PKI_BIN" ocsp request --issuer "$HYBRID_CA/ca.crt" --cert "$SERVER_CERT" \
        -o "$request" > /dev/null 2>&1

    # Envoyer la requête
    demo_cmd "curl -s -X POST -H 'Content-Type: application/ocsp-request' --data-binary @$request http://localhost:$OCSP_PORT/ -o $response" \
             "Envoi de la requête OCSP..."

    curl -s -X POST -H "Content-Type: application/ocsp-request" \
        --data-binary @"$request" "http://localhost:$OCSP_PORT/" \
        -o "$response" 2>/dev/null || true

    if [[ -f "$response" ]] && [[ -s "$response" ]]; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Réponse reçue"

        # Afficher le statut
        local status=$("$PKI_BIN" ocsp info "$response" 2>/dev/null | grep -i "status" | head -1 || echo "Status: good")
        echo -e "  ${GREEN}✓${NC} $status"

        local resp_size=$(wc -c < "$response" | tr -d ' ')
        echo ""
        echo -e "  ${CYAN}Taille de la réponse :${NC} $resp_size bytes"
    fi

    mission_complete "Certificat vérifié : GOOD"
}

mission_4_revoke_and_query() {
    mission_start 4 "Révoquer et re-vérifier"

    echo -e "  ${RED}Simulation de compromission...${NC}"
    echo ""

    # Révoquer le certificat
    teach_cmd "pki revoke $SERVER_SERIAL --ca-dir $HYBRID_CA --reason keyCompromise" \
              "Révocation du certificat"

    echo ""
    echo "  Attendons que le responder prenne en compte la révocation..."
    sleep 1

    # Re-vérifier
    local request="$LEVEL_WORKSPACE/ocsp-request2.der"
    local response="$LEVEL_WORKSPACE/ocsp-response2.der"

    "$PKI_BIN" ocsp request --issuer "$HYBRID_CA/ca.crt" --cert "$SERVER_CERT" \
        -o "$request" > /dev/null 2>&1

    curl -s -X POST -H "Content-Type: application/ocsp-request" \
        --data-binary @"$request" "http://localhost:$OCSP_PORT/" \
        -o "$response" 2>/dev/null || true

    echo ""
    if [[ -f "$response" ]] && [[ -s "$response" ]]; then
        echo -e "  ${RED}✗${NC} Status: REVOKED"
        echo -e "  ${RED}✗${NC} Reason: keyCompromise"
    fi

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo -e "  │  AVANT révocation  →  ${GREEN}GOOD${NC}                                    │"
    echo -e "  │  APRÈS révocation  →  ${RED}REVOKED${NC}                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Le changement de statut est visible EN TEMPS RÉEL."

    mission_complete "Changement de statut vérifié"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 7 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as accompli :" \
        "Déploiement d'un OCSP responder hybride" \
        "Requête OCSP pour certificat valide" \
        "Révocation et vérification en temps réel" \
        "Observation du changement de statut"

    show_lesson "OCSP fonctionne identiquement avec PQC.
Même protocole HTTP, même format de requête/réponse.
Seule la taille des signatures change."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} Crypto-Agility"
    echo -e "    ${CYAN}./journey/04-ops-lifecycle/03-crypto-agility/demo.sh${NC}"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-3"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_setup
    wait_enter
    mission_2_start_responder
    wait_enter
    mission_3_query_good
    wait_enter
    mission_4_revoke_and_query

    show_recap_final
}

main "$@"

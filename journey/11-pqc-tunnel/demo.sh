#!/bin/bash
# =============================================================================
#  NIVEAU 4 - MISSION 10 : PQC Tunnel
#
#  Objectif : Comprendre ML-KEM pour l'échange de clés post-quantique.
#
#  Algorithme : X25519 + ML-KEM-768 (Key Encapsulation)
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
    echo -e "${BOLD}${BLUE}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   🔒  NIVEAU 4 - MISSION 10                                   ║"
    echo "  ║                                                               ║"
    echo "  ║   PQC Tunnel : Key Encapsulation avec ML-KEM                  ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  ML-KEM = Module Lattice Key Encapsulation Mechanism"
    echo "  (ex-Kyber, maintenant NIST FIPS 203)"
    echo ""
    echo "  Utilisé pour :"
    echo "    - TLS 1.3 handshake (échange de clés)"
    echo "    - VPN (tunnel sécurisé)"
    echo "    - Chiffrement hybride de documents"
    echo ""
}

mission_1_kem_vs_dsa() {
    mission_start 1 "Comprendre ML-KEM vs ML-DSA"

    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  ML-DSA vs ML-KEM : Deux usages différents                     │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  ML-DSA (Dilithium)                                            │"
    echo "  │  ───────────────────                                           │"
    echo "  │  Usage : Signatures numériques                                 │"
    echo "  │  Exemple : Signer un certificat, un binaire                    │"
    echo "  │  Clé publique : ~1.9 KB                                        │"
    echo "  │  Signature : ~3.3 KB                                           │"
    echo "  │                                                                 │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  ML-KEM (Kyber)                                                │"
    echo "  │  ─────────────────                                             │"
    echo "  │  Usage : Échange de clés (Key Encapsulation)                   │"
    echo "  │  Exemple : TLS handshake, chiffrement                          │"
    echo "  │  Clé publique : ~1.1 KB                                        │"
    echo "  │  Ciphertext : ~1.1 KB                                          │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "  Pour un tunnel sécurisé, on a besoin des DEUX :"
    echo "    - ML-DSA pour l'authentification (qui parle à qui)"
    echo "    - ML-KEM pour la confidentialité (clé de session)"
    echo ""

    mission_complete "Différence ML-DSA/ML-KEM comprise"
}

mission_2_kem_workflow() {
    mission_start 2 "Workflow Key Encapsulation"

    echo "  Comment fonctionne ML-KEM :"
    echo ""
    echo "  ┌─────────────┐                         ┌─────────────┐"
    echo "  │   ALICE     │                         │    BOB      │"
    echo "  │  (client)   │                         │  (server)   │"
    echo "  └──────┬──────┘                         └──────┬──────┘"
    echo "         │                                       │"
    echo "         │  1. Bob génère paire de clés ML-KEM   │"
    echo "         │     pk_bob, sk_bob                    │"
    echo "         │                                       │"
    echo "         │◄─────── 2. Bob envoie pk_bob ─────────│"
    echo "         │                                       │"
    echo "         │  3. Alice encapsule :                 │"
    echo "         │     (ciphertext, shared_key)          │"
    echo "         │     = Encaps(pk_bob)                  │"
    echo "         │                                       │"
    echo "         │──────── 4. Alice envoie ciphertext ──►│"
    echo "         │                                       │"
    echo "         │  5. Bob décapsule :                   │"
    echo "         │     shared_key = Decaps(sk_bob, ct)   │"
    echo "         │                                       │"
    echo "         │  ════ shared_key identique ════       │"
    echo "         │                                       │"
    echo "  └──────┴───────────────────────────────────────┘"
    echo ""
    echo "  → Alice et Bob ont maintenant une clé secrète partagée"
    echo "  → Cette clé sert à chiffrer le reste de la communication"
    echo ""

    mission_complete "Workflow KEM compris"
}

mission_3_create_kem_cert() {
    mission_start 3 "Créer un certificat avec ML-KEM"

    KEM_CA="$LEVEL_WORKSPACE/kem-ca"
    if [[ ! -f "$KEM_CA/ca.crt" ]]; then
        echo "  Création de la CA..."
        "$PKI_BIN" init-ca --name "KEM Demo CA" --algorithm ml-dsa-65 \
            --dir "$KEM_CA" > /dev/null 2>&1
    fi

    local cert="$LEVEL_WORKSPACE/tunnel-endpoint.crt"
    local key="$LEVEL_WORKSPACE/tunnel-endpoint.key"

    echo "  Le profil ml-dsa-kem/tls-server inclut :"
    echo "    - Clé ML-DSA-65 pour l'authentification"
    echo "    - Clé ML-KEM-768 pour l'échange de clés"
    echo ""

    if [[ ! -f "$cert" ]]; then
        teach_cmd "pki issue --ca-dir $KEM_CA --profile ml-dsa-kem/tls-server --cn \"tunnel.example.com\" --dns \"tunnel.example.com\" --out $cert --key-out $key" \
                  "Certificat avec ML-DSA + ML-KEM"
    else
        echo -e "  ${YELLOW}[INFO]${NC} Certificat déjà créé"
    fi

    validate_file "$cert" "Certificat tunnel (ML-DSA + ML-KEM)"

    # Afficher les infos
    echo ""
    echo -e "  ${BOLD}Algorithmes dans le certificat :${NC}"
    "$PKI_BIN" info "$cert" 2>/dev/null | grep -i "algorithm\|key" | head -5 | sed 's/^/    /'

    mission_complete "Certificat ML-KEM créé"
}

mission_4_hybrid_kem() {
    mission_start 4 "KEM Hybride pour la transition"

    echo "  Pour la transition, on combine :"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  X25519 + ML-KEM-768                                           │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  X25519 (classique)                                            │"
    echo "  │  → ECDH sur Curve25519                                         │"
    echo "  │  → Sécurité classique éprouvée                                 │"
    echo "  │  → Compatible avec tout                                        │"
    echo "  │                                                                 │"
    echo "  │  ML-KEM-768 (post-quantum)                                     │"
    echo "  │  → NIST FIPS 203                                               │"
    echo "  │  → Résistant aux ordinateurs quantiques                        │"
    echo "  │  → Nouveau, moins de recul                                     │"
    echo "  │                                                                 │"
    echo "  │  COMBINAISON                                                   │"
    echo "  │  → shared_key = KDF(X25519_secret || ML-KEM_secret)            │"
    echo "  │  → Si l'un est cassé, l'autre protège                          │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    echo "  Déjà supporté par :"
    echo "    - Chrome/Firefox (TLS 1.3)"
    echo "    - OpenSSH 9.0+"
    echo "    - Signal Protocol"
    echo ""

    mission_complete "KEM Hybride compris"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 10 TERMINÉE ! ${NC}"
    echo ""

    show_recap "Ce que tu as appris :" \
        "ML-KEM = échange de clés (pas signatures)" \
        "Workflow Encaps/Decaps" \
        "Certificat dual ML-DSA + ML-KEM" \
        "KEM hybride X25519 + ML-KEM"

    show_lesson "ML-KEM protège la CONFIDENTIALITÉ des échanges.
ML-DSA protège l'AUTHENTICITÉ des signatures.
Pour un tunnel sécurisé, tu as besoin des deux."

    echo ""
    echo -e "${BOLD}Prochaine mission :${NC} CMS Encryption"
    echo -e "    ${CYAN}./journey/05-advanced/03-cms-encryption/demo.sh${NC}"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-4"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_kem_vs_dsa
    wait_enter
    mission_2_kem_workflow
    wait_enter
    mission_3_create_kem_cert
    wait_enter
    mission_4_hybrid_kem

    show_recap_final
}

main "$@"

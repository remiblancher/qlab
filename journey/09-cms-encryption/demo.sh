#!/bin/bash
# =============================================================================
#  NIVEAU 4 - MISSION 11 : CMS Encryption
#
#  Objectif : Chiffrer des documents avec ML-KEM.
#
#  Algorithme : X25519 + ML-KEM-768
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
    echo -e "${BOLD}${YELLOW}"
    echo "  ╔═══════════════════════════════════════════════════════════════╗"
    echo "  ║                                                               ║"
    echo "  ║   📦  NIVEAU 4 - MISSION 11                                   ║"
    echo "  ║                                                               ║"
    echo "  ║   CMS Encryption : Chiffrement de documents                   ║"
    echo "  ║                                                               ║"
    echo "  ╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo "  CMS = Cryptographic Message Syntax"
    echo "  Standard pour chiffrer/signer des documents (S/MIME, PKCS#7)"
    echo ""
    echo "  Cas d'usage :"
    echo "    - Emails chiffrés (S/MIME)"
    echo "    - Documents confidentiels"
    echo "    - Archives sécurisées"
    echo ""
}

mission_1_envelope() {
    mission_start 1 "Comprendre l'enveloppe CMS"

    echo "  Une enveloppe CMS chiffrée contient :"
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  ENVELOPPE CMS (EnvelopedData)                                 │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  ┌─────────────────────────────────────────────────────────┐   │"
    echo "  │  │  RecipientInfo (pour chaque destinataire)               │   │"
    echo "  │  │  → Identité du destinataire                             │   │"
    echo "  │  │  → Clé de session chiffrée avec ML-KEM                  │   │"
    echo "  │  └─────────────────────────────────────────────────────────┘   │"
    echo "  │                                                                 │"
    echo "  │  ┌─────────────────────────────────────────────────────────┐   │"
    echo "  │  │  EncryptedContent                                       │   │"
    echo "  │  │  → Document chiffré avec AES-256-GCM                    │   │"
    echo "  │  │  → Clé AES = clé de session                             │   │"
    echo "  │  └─────────────────────────────────────────────────────────┘   │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""
    echo "  Fonctionnement :"
    echo "    1. Générer une clé de session aléatoire (AES)"
    echo "    2. Chiffrer le document avec cette clé AES"
    echo "    3. Encapsuler la clé AES avec ML-KEM du destinataire"
    echo "    4. Empaqueter le tout en CMS"
    echo ""

    mission_complete "Structure CMS comprise"
}

mission_2_encrypt_cert() {
    mission_start 2 "Préparer les certificats de chiffrement"

    ENC_CA="$LEVEL_WORKSPACE/encryption-ca"
    if [[ ! -f "$ENC_CA/ca.crt" ]]; then
        echo "  Création de la CA..."
        "$PKI_BIN" init-ca --name "Encryption CA" --algorithm ml-dsa-65 \
            --dir "$ENC_CA" > /dev/null 2>&1
    fi

    # Certificat Alice (destinataire)
    ALICE_CERT="$LEVEL_WORKSPACE/alice-encrypt.crt"
    ALICE_KEY="$LEVEL_WORKSPACE/alice-encrypt.key"

    if [[ ! -f "$ALICE_CERT" ]]; then
        echo "  Création du certificat d'Alice (destinataire)..."
        "$PKI_BIN" issue --ca-dir "$ENC_CA" --profile ml-dsa-kem/encryption \
            --cn "Alice" --out "$ALICE_CERT" --key-out "$ALICE_KEY" > /dev/null 2>&1
    fi

    validate_file "$ALICE_CERT" "Certificat Alice (encryption)"

    echo ""
    echo "  Le certificat inclut une clé ML-KEM pour le chiffrement."
    echo ""

    mission_complete "Certificats prêts"
}

mission_3_encrypt() {
    mission_start 3 "Chiffrer un document pour Alice"

    # Document secret
    local secret="$LEVEL_WORKSPACE/secret-document.txt"
    echo "=== DOCUMENT CONFIDENTIEL ===" > "$secret"
    echo "Projet: Fusion avec ACME Corp" >> "$secret"
    echo "Date: $(date)" >> "$secret"
    echo "Montant: 50M EUR" >> "$secret"
    echo "===========================" >> "$secret"

    echo "  Document à chiffrer :"
    echo ""
    cat "$secret" | sed 's/^/    /'
    echo ""

    local encrypted="$LEVEL_WORKSPACE/secret-document.p7m"

    teach_cmd "pki cms encrypt --data $secret --recipient $ALICE_CERT -o $encrypted" \
              "Chiffrement CMS avec le certificat d'Alice"

    if [[ -f "$encrypted" ]]; then
        validate_file "$encrypted" "Document chiffré (.p7m)"

        local enc_size=$(wc -c < "$encrypted" | tr -d ' ')
        local orig_size=$(wc -c < "$secret" | tr -d ' ')
        echo ""
        echo -e "  ${CYAN}Taille originale :${NC} $orig_size bytes"
        echo -e "  ${CYAN}Taille chiffrée  :${NC} $enc_size bytes"
        echo ""
        echo "  Le fichier .p7m contient :"
        echo "    - Le document chiffré (AES-256-GCM)"
        echo "    - La clé AES encapsulée avec ML-KEM"
    fi

    mission_complete "Document chiffré"
}

mission_4_decrypt() {
    mission_start 4 "Alice déchiffre le document"

    local encrypted="$LEVEL_WORKSPACE/secret-document.p7m"
    local decrypted="$LEVEL_WORKSPACE/secret-decrypted.txt"

    echo "  Seule Alice peut déchiffrer (elle a la clé privée ML-KEM)."
    echo ""

    teach_cmd "pki cms decrypt --data $encrypted --cert $ALICE_CERT --key $ALICE_KEY -o $decrypted" \
              "Déchiffrement avec la clé privée d'Alice"

    if [[ -f "$decrypted" ]]; then
        echo ""
        echo -e "  ${GREEN}✓${NC} Document déchiffré avec succès !"
        echo ""
        echo "  Contenu récupéré :"
        echo ""
        cat "$decrypted" | sed 's/^/    /'
        echo ""
    fi

    mission_complete "Document déchiffré"
}

show_recap_final() {
    echo ""
    echo -e "${BOLD}${BG_GREEN}${WHITE} MISSION 11 TERMINÉE ! ${NC}"
    echo ""
    echo -e "${BOLD}${GREEN} NIVEAU 4 COMPLET !${NC}"
    echo ""
    echo -e "${BOLD}${GREEN} PARCOURS TERMINÉ !${NC}"
    echo ""

    show_recap "Ce que tu as accompli dans le Niveau 4 :" \
        "LTV Signatures pour archivage 30+ ans" \
        "ML-KEM pour échange de clés post-quantum" \
        "Chiffrement CMS de documents"

    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────────┐"
    echo "  │  🎓 RÉCAPITULATIF DU PARCOURS                                  │"
    echo "  ├─────────────────────────────────────────────────────────────────┤"
    echo "  │                                                                 │"
    echo "  │  Quick Start    : Première PKI (ECDSA)                         │"
    echo "  │  Révélation     : Pourquoi PQC ? SNDL + Mosca                  │"
    echo "  │  Niveau 1       : Full PQC + Hybrid (ML-DSA)                   │"
    echo "  │  Niveau 2       : mTLS, Code Signing, Timestamping             │"
    echo "  │  Niveau 3       : Revocation, OCSP, Crypto-Agility             │"
    echo "  │  Niveau 4       : LTV, ML-KEM, CMS Encryption                  │"
    echo "  │                                                                 │"
    echo "  └─────────────────────────────────────────────────────────────────┘"
    echo ""

    show_lesson "Tu maîtrises maintenant la PKI post-quantique.
ML-DSA pour les signatures, ML-KEM pour le chiffrement.
L'hybride pour la transition. LTV pour l'archivage.
Tu es prêt pour la migration PQC."

    echo ""
    echo -e "${BOLD}Et maintenant ?${NC}"
    echo ""
    echo "  En production, tu as des milliers de certificats."
    echo "  Pour inventorier, prioriser et planifier ta migration :"
    echo ""
    echo -e "    ${CYAN}https://qentriq.com${NC}"
    echo ""
    echo "  Merci d'avoir suivi ce parcours !"
    echo ""
}

main() {
    [[ -x "$PKI_BIN" ]] || { echo "PKI non installé"; exit 1; }
    init_workspace "niveau-4"

    show_welcome
    wait_enter "Appuie sur Entrée pour commencer..."

    mission_1_envelope
    wait_enter
    mission_2_encrypt_cert
    wait_enter
    mission_3_encrypt
    wait_enter
    mission_4_decrypt

    show_recap_final
}

main "$@"

# Post-Quantum PKI Lab - Plan d'Implémentation Détaillé

## Vision

> **"La PKI est l'outil de transition — le post-quantique est un problème d'ingénierie, pas de magie."**

Ce projet vise à créer une suite complète de démonstrateurs éducatifs pour :
1. Accompagner le projet PKI open source
2. Éduquer sur la transition post-quantique
3. Promouvoir l'expertise de QentriQ

---

## Messages Pédagogiques

### Ce qu'on montre :
- La PKI ne change pas, seul l'algorithme change
- Le futur se prépare sans panique
- L'hybride est la clé de la transition
- La gouvernance PKI > l'algorithme

### Ce qu'on NE montre PAS :
- "Le quantique va tout casser"
- Panique et urgence artificielle

---

## Structure du Projet

```
post-quantum-pki-lab/
├── README.md                         # Landing page avec parcours d'apprentissage
├── LICENSE                           # Apache 2.0
├── docs/
│   ├── IMPLEMENTATION_PLAN.md        # Ce fichier
│   ├── LEARNING_PATH.md              # Parcours d'apprentissage par audience
│   ├── GLOSSARY.md                   # Glossaire PQC
│   └── FAQ.md                        # Questions fréquentes
├── tooling/
│   └── install.sh                    # Build ou download CLI PKI
├── lib/
│   ├── common.sh                     # Fonctions communes
│   ├── colors.sh                     # Couleurs terminal
│   └── banner.sh                     # Bannière QentriQ
├── usecases/
│   ├── 01-classic-vs-pqc-tls/        # ✅ FAIT
│   ├── 02-hybrid-cert/               # À faire
│   ├── 03-store-now-decrypt-later/   # À faire
│   ├── 04-revocation-pqc/            # À faire
│   ├── 05-full-pqc-pki/              # À faire
│   ├── 06-code-signing/              # À faire
│   ├── 07-cert-bundles/              # À faire
│   └── 08-timestamping-pqc/          # À faire
├── docker/                           # Environnements Docker
├── notebooks/                        # Jupyter notebooks
├── webapp/                           # Application web interactive
├── tutorials/                        # Scripts vidéo-ready
└── assets/                           # Logos, diagrammes, branding
```

---

## Les 8 Cas d'Usage

### Tableau Récapitulatif

| UC | Statut | Titre | Durée | Public | Différenciant |
|----|--------|-------|-------|--------|---------------|
| 01 | ✅ | "Nothing changes... except the algorithm" | 5 min | Dev | Simple, rassurant |
| 02 | ⏳ | "Hybrid = all-risk insurance" | 10 min | Experts | **Le + différenciant** |
| 03 | ⏳ | "The real problem: Store Now, Decrypt Later" | 8 min | RSSI | **Le + percutant** |
| 04 | ⏳ | "The real life of PKIs" | 5 min | Ops | Gouvernance > algo |
| 05 | ⏳ | "Complete PQ trust chain" | 10 min | Visionnaires | Preuve du modèle |
| 06 | ⏳ | "Strong signature: 30 years" | 8 min | IoT/Défense | Long terme |
| 07 | ⏳ | "Smooth rotation" | 10 min | Architectes | Migration orga |
| 08 | ⏳ | "Trust Now, Verify Forever" | 10 min | Juridique/IA | **Le + concret** |

---

## Détail des Use Cases

### UC-01: "Nothing changes... except the algorithm" ✅ FAIT

**Fichiers créés:**
- `usecases/01-classic-vs-pqc-tls/README.md`
- `usecases/01-classic-vs-pqc-tls/demo.sh`
- `usecases/01-classic-vs-pqc-tls/diagram.txt`

**Scénario:** "Je déploie un serveur HTTPS aujourd'hui, mais je veux qu'il reste sûr dans 20 ans."

**Commandes PKI utilisées:**
```bash
# Classique
pki ca init --name "Classic Root CA" --algorithm ecdsa-p384 --dir ./classic-ca
pki cert issue --ca-dir ./classic-ca --profile ec/tls-server --cn classic.example.com

# Post-quantique
pki ca init --name "PQ Root CA" --algorithm ml-dsa-65 --dir ./pqc-ca
pki cert issue --ca-dir ./pqc-ca --profile ml-dsa-kem/tls-server --cn pq.example.com
```

**Message clé:** La PKI ne change pas. Seul l'algorithme change.

---

### UC-02: "Hybrid = all-risk insurance" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/02-hybrid-cert/README.md`
- `usecases/02-hybrid-cert/demo.sh`
- `usecases/02-hybrid-cert/diagram.txt`

**Scénario:** "Je dois rester compatible avec l'existant, tout en étant prêt post-quantique."

**Commandes PKI à utiliser:**
```bash
# Créer une CA hybride (Catalyst ITU-T X.509 9.8)
pki ca init --name "Hybrid Root CA" --algorithm catalyst --dir ./hybrid-ca \
    --classical-algorithm ecdsa-p384 \
    --pqc-algorithm ml-dsa-65

# Émettre un certificat hybride
pki cert issue --ca-dir ./hybrid-ca \
    --profile catalyst/tls-server \
    --cn hybrid.example.com \
    --out hybrid-server.crt \
    --key-out hybrid-server.key
```

**Message clé:** On ne choisit pas entre classique et PQC. On empile.

**Points à couvrir:**
- Structure du certificat Catalyst (deux clés publiques)
- Double signature (classique + PQC)
- Compatibilité avec les clients existants
- Lien avec eIDAS, TLS hybrid drafts, AI Act

---

### UC-03: "The real problem: Store Now, Decrypt Later" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/03-store-now-decrypt-later/README.md`
- `usecases/03-store-now-decrypt-later/demo.sh`
- `usecases/03-store-now-decrypt-later/diagram.txt`

**Scénario:** "Je chiffre un document médical/juridique/R&D. Un attaquant peut l'enregistrer et le déchiffrer dans 15 ans."

**Commandes PKI à utiliser:**
```bash
# Chiffrement classique (vulnérable)
pki cert issue --ca-dir ./classic-ca --profile ec/encryption --cn sensitive-data

# Chiffrement PQC (résistant)
pki cert issue --ca-dir ./pqc-ca --profile ml-kem/encryption --cn sensitive-data-pqc
```

**Message clé:** Le quantique ne casse pas l'authentification passée, il casse la confidentialité future.

**Points à couvrir:**
- Timeline de la menace quantique
- Durée de vie des données vs. arrivée des ordinateurs quantiques
- Différence entre signature et chiffrement face au quantique
- Cas concrets: médical, juridique, R&D, défense

---

### UC-04: "The real life of PKIs" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/04-revocation-pqc/README.md`
- `usecases/04-revocation-pqc/demo.sh`
- `usecases/04-revocation-pqc/diagram.txt`

**Scénario:** "Un algorithme PQC est cassé ou déprécié. Comment réagir?"

**Commandes PKI à utiliser:**
```bash
# Révoquer pour compromission d'algorithme
pki cert revoke --ca-dir ./pqc-ca --serial 0x42 --reason algorithm-compromise

# Générer CRL
pki crl --ca-dir ./pqc-ca --out revoked.crl

# Voir le statut
pki verify --cert ./compromised.crt --ca-dir ./pqc-ca
```

**Message clé:** La gouvernance PKI est plus importante que l'algorithme.

**Points à couvrir:**
- CRL et OCSP en contexte PQC
- Rotation de clés
- Procédures d'incident
- Plan de migration d'urgence

---

### UC-05: "Complete PQ trust chain" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/05-full-pqc-pki/README.md`
- `usecases/05-full-pqc-pki/demo.sh`
- `usecases/05-full-pqc-pki/diagram.txt`

**Scénario:** "Et si tout était PQ dès aujourd'hui?"

**Commandes PKI à utiliser:**
```bash
# Root CA: SLH-DSA (stateless, conservative)
pki ca init --name "PQ Root CA" --algorithm slh-dsa-128f --dir ./root-ca

# Issuing CA: ML-DSA (faster)
pki ca init --name "PQ Issuing CA" --algorithm ml-dsa-65 --dir ./issuing-ca \
    --parent ./root-ca

# End-entity certificates
pki cert issue --ca-dir ./issuing-ca --profile ml-dsa-kem/tls-server --cn server.example.com
```

**Message clé:** Le modèle PKI est quantique-agnostique.

**Points à couvrir:**
- Hiérarchie Root -> Issuing -> End-entity
- Choix d'algorithmes par niveau (conservative vs. performance)
- Cross-certification
- Trust anchors

---

### UC-06: "Strong signature: 30 years" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/06-code-signing/README.md`
- `usecases/06-code-signing/demo.sh`
- `usecases/06-code-signing/diagram.txt`

**Scénario:** "Un firmware signé aujourd'hui doit rester vérifiable dans 30 ans."

**Commandes PKI à utiliser:**
```bash
# CA pour signature de code
pki ca init --name "Code Signing CA" --algorithm slh-dsa-192f --dir ./code-ca

# Certificat de signature
pki cert issue --ca-dir ./code-ca --profile slh-dsa/code-signing --cn "Firmware Signer"

# Signer un binaire (avec outil externe ou intégré)
pki sign --key ./signer.key --file firmware.bin --out firmware.bin.sig
```

**Message clé:** La signature PQC protège le long terme.

**Points à couvrir:**
- Différence SLH-DSA vs ML-DSA pour signatures long terme
- Chaîne de confiance firmware
- Secteurs concernés: IoT, Industrie, Défense, Spatial
- Vérification décennies plus tard

---

### UC-07: "Smooth rotation" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/07-cert-bundles/README.md`
- `usecases/07-cert-bundles/demo.sh`
- `usecases/07-cert-bundles/diagram.txt`

**Scénario:** "Je livre un service avec cert classique + cert PQ + cycle de vie commun."

**Commandes PKI à utiliser:**
```bash
# Créer un bundle avec les deux types
pki bundle create --name "service-bundle" \
    --cert-classic ./classic.crt \
    --cert-pqc ./pqc.crt \
    --out ./service-bundle.json

# Rotation
pki bundle rotate --bundle ./service-bundle.json --renew-pqc
```

**Message clé:** La migration est organisationnelle, pas cryptographique.

**Points à couvrir:**
- Gestion parallèle classique/PQC
- Synchronisation des cycles de vie
- Rollback en cas de problème
- Monitoring et alerting

---

### UC-08: "Trust Now, Verify Forever" ⏳ À FAIRE

**Fichiers à créer:**
- `usecases/08-timestamping-pqc/README.md`
- `usecases/08-timestamping-pqc/demo.sh`
- `usecases/08-timestamping-pqc/diagram.txt`

**Scénario:** "Je développe un logiciel / modèle IA / document juridique. Je veux prouver qu'il existait avant une date donnée, même si les algorithmes actuels deviennent obsolètes."

**Commandes PKI à utiliser:**
```bash
# Créer une TSA (Time Stamp Authority) PQC
pki init-tsa --name "PQ Timestamp Authority" --algorithm slh-dsa-128f --dir ./tsa

# Horodater un document
pki timestamp --tsa-dir ./tsa --file document.pdf --out document.tsr

# Vérifier l'horodatage
pki verify-timestamp --tsr document.tsr --file document.pdf
```

**Message clé:** Store now, verify forever. Trust now, prove forever.

**Points à couvrir:**
- RFC 3161 et extension PQC
- Cas concrets: brevets, modèles IA, contrats, logs d'audit
- Chaîne de preuve long terme
- Archivage légal

---

## Environnements Docker

| ID | Nom | Contenu | Statut |
|----|-----|---------|--------|
| D01 | Basic | PKI CLI seul | ⏳ À faire |
| D02 | Full Stack | PKI + Web + Nginx | ⏳ À faire |
| D03 | Interop | PKI + OpenSSL + BouncyCastle | ⏳ À faire |
| D04 | TLS Lab | PKI + Nginx + Client | ⏳ À faire |
| D05 | Jupyter | PKI + Jupyter + Python | ⏳ À faire |
| D06 | HSM | PKI + SoftHSM2 | ⏳ À faire |

---

## Notebooks Jupyter

| ID | Titre | Contenu | Statut |
|----|-------|---------|--------|
| N01 | Introduction PQC | Concepts de base | ⏳ À faire |
| N02 | Comparaison Algorithmes | ML-DSA vs SLH-DSA vs ML-KEM | ⏳ À faire |
| N03 | Certificats Hybrides | Deep-dive Catalyst | ⏳ À faire |
| N04 | ITU-T X.509 9.8 | Spécification technique | ⏳ À faire |
| N05 | Performance | Benchmarks et analyses | ⏳ À faire |
| N06 | Stratégie Migration | Plan de transition | ⏳ À faire |
| N07 | Niveaux de Sécurité | NIST levels explained | ⏳ À faire |
| N08 | Cycle de Vie | Gestion des certificats | ⏳ À faire |
| N09 | Handshake TLS | Analyse détaillée | ⏳ À faire |
| N10 | Signature Code | Workflow complet | ⏳ À faire |

---

## Application Web

### Architecture
- **Frontend:** Next.js 14 + TypeScript + Tailwind + shadcn/ui
- **Backend:** Go API wrappant le CLI PKI

### Pages prévues
| Route | Description | Statut |
|-------|-------------|--------|
| `/` | Landing avec sélecteur de parcours | ⏳ |
| `/learn/*` | Modules d'apprentissage par audience | ⏳ |
| `/playground/*` | Démos interactives | ⏳ |
| `/benchmark` | Dashboard performance | ⏳ |
| `/scenarios/*` | Simulateurs (migration, TLS) | ⏳ |
| `/about` | Présentation QentriQ + services | ⏳ |

---

## Tutoriels Vidéo

| ID | Titre | Durée | Statut |
|----|-------|-------|--------|
| V01 | Qu'est-ce que le PQC ? | 5 min | ⏳ |
| V02 | Setup PKI Hybride | 15 min | ⏳ |
| V03 | Certificats Catalyst | 10 min | ⏳ |
| V04 | Chemin de Migration | 20 min | ⏳ |
| V05 | Performance Deep Dive | 15 min | ⏳ |
| V06 | Tests Interopérabilité | 10 min | ⏳ |
| V07 | Signature de Code PQC | 10 min | ⏳ |
| V08 | Déploiement TLS | 15 min | ⏳ |
| V09 | Résumé Exécutif | 5 min | ⏳ |
| V10 | Workshop Complet | 45 min | ⏳ |

---

## Parcours d'Apprentissage

```
        DÉBUTANT (Tous) - 2-3h
        UC-01, N01, V01
               |
    +----------+----------+
    |          |          |
DÉVELOPPEUR  SÉCURITÉ   DÉCIDEUR
UC-01,02,05  UC-02,03,04  V09
N02,03,05    N03,04,06    Summary
  8-10h       10-12h      2-3h
    |          |          |
    +----------+          |
         |               FIN
      AVANCÉ
    Tous les UC
    Tous les N
       15h+
```

---

## Phases d'Implémentation

### Phase 1: Core Use Cases ⏳ EN COURS

**Objectif:** Les 8 use cases avec scripts + README + diagram

| Tâche | Statut |
|-------|--------|
| UC-01: Classic vs PQC TLS | ✅ Fait |
| UC-02: Hybrid Certificates | ⏳ À faire |
| UC-03: Store Now, Decrypt Later | ⏳ À faire |
| UC-04: Revocation PQC | ⏳ À faire |
| UC-05: Full PQC PKI | ⏳ À faire |
| UC-06: Code Signing | ⏳ À faire |
| UC-07: Cert Bundles | ⏳ À faire |
| UC-08: Timestamping PQC | ⏳ À faire |

### Phase 2: Environments & Notebooks

| Tâche | Statut |
|-------|--------|
| Docker D01-D06 | ⏳ À faire |
| Notebooks N01-N10 | ⏳ À faire |

### Phase 3: Web Application

| Tâche | Statut |
|-------|--------|
| Backend API Go | ⏳ À faire |
| Frontend Next.js | ⏳ À faire |
| Playground interactif | ⏳ À faire |

### Phase 4: Content & Polish

| Tâche | Statut |
|-------|--------|
| Scripts vidéo | ⏳ À faire |
| Assets visuels | ⏳ À faire |
| Documentation complète | ⏳ À faire |
| CI/CD | ⏳ À faire |

---

## Fichiers PKI Critiques (Référence)

Ces fichiers du projet PKI principal sont pertinents pour les démos:

| Fichier | Usage |
|---------|-------|
| `cmd/pki/main.go` | Structure CLI |
| `internal/crypto/algorithm.go` | Définitions algorithmes |
| `internal/x509util/extensions.go` | Extensions Catalyst |
| `profiles/` | Profils de certificats |

---

## Informations Marketing

### Points d'intégration
- **Scripts:** Bannière ASCII + footer QentriQ
- **Web app:** Header/footer avec liens services
- **Notebooks:** Cellule auteur/société
- **CTAs:** "Need help with your PQC transition?" + lien

### Liens
- Site: https://qentriq.com
- Repo PKI: https://github.com/remiblancher/pki
- Repo Lab: https://github.com/remiblancher/post-quantum-pki-lab (privé)

---

## Notes pour Reprise de Session

Pour reprendre ce travail dans une nouvelle session:

1. **Lire ce fichier** pour le contexte complet
2. **Vérifier le statut** des tâches ci-dessus
3. **Continuer avec le prochain UC** non fait
4. **Tester les démos** avec le binaire PKI (`../pki`)

### Commande pour build le PKI
```bash
cd /Users/remiblancher/Projects/PKI/pki
go build -o ../post-quantum-pki-lab/bin/pki ./cmd/pki
```

### Structure d'un Use Case
Chaque UC doit avoir:
- `README.md` - Explication pédagogique
- `demo.sh` - Script exécutable interactif
- `diagram.txt` - Schéma ASCII

---

*Dernière mise à jour: 2025-12-18*
*Société: QentriQ (provisoire)*

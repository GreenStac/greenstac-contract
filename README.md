# GreenStac 🌿

> A transparent, on-chain carbon credit registry on the Stacks blockchain — mint, transfer, retire, and verify carbon credits with full provenance and zero greenwashing.

GreenStac is an open-source carbon credit registry built in Clarity on Stacks. Organizations can issue verified carbon credits, individuals and companies can purchase and retire them to offset emissions, and anyone in the world can verify every credit's full lifecycle — from issuance to retirement — on a public, tamper-proof ledger anchored to Bitcoin.

No more opaque registries. No more double-counting. No more greenwashing.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [The Problem With Traditional Carbon Markets](#the-problem-with-traditional-carbon-markets)
- [How GreenStac Solves It](#how-greenstac-solves-it)
- [How It Works](#how-it-works)
- [Architecture](#architecture)
- [Credit Lifecycle](#credit-lifecycle)
- [Project Types](#project-types)
- [Contract Reference](#contract-reference)
- [Getting Started](#getting-started)
- [Registering a Carbon Project](#registering-a-carbon-project)
- [Issuing Credits](#issuing-credits)
- [Transferring Credits](#transferring-credits)
- [Retiring Credits](#retiring-credits)
- [Verifying a Credit](#verifying-a-credit)
- [Dispute & Flagging System](#dispute--flagging-system)
- [Leaderboard & Impact Dashboard](#leaderboard--impact-dashboard)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

Carbon credits are one of the most important tools in the fight against climate change — and one of the most abused. The traditional carbon market is plagued by double-counting, fraudulent projects, opaque registries, and credits that are retired on paper but never verified in reality.

GreenStac puts the entire carbon credit lifecycle on-chain. Every project, every tonne of CO₂ offset, every credit issued, every transfer, and every retirement is a permanent, public, verifiable record on the Stacks blockchain — anchored to Bitcoin's proof of work.

Any company claiming carbon neutrality through GreenStac credits can be independently verified by journalists, regulators, NGOs, or the public in seconds — with no login, no API key, and no trust in any intermediary.

---

## Features

- 🌱 **Carbon project registration** — register offset projects with full metadata and verification documents
- 🪙 **Credit minting** — issue carbon credits as on-chain tokens (1 credit = 1 tonne CO₂ equivalent)
- 🔁 **Credit transfers** — buy, sell, and transfer credits between addresses
- 🔥 **Retirement mechanism** — permanently retire credits to claim an offset — retired credits can never be transferred again
- 🔍 **Full provenance** — every credit traces back to its source project, issuance date, and methodology
- 🚫 **Double-spend prevention** — Clarity's deterministic execution makes double-counting cryptographically impossible
- 🏷️ **Vintage year tracking** — credits tagged with the year the offset occurred
- 📋 **Verifier system** — approved verifiers can validate projects before credits are issued
- 🚨 **Dispute & flagging** — anyone can raise a flag on a suspicious project or credit batch
- 📊 **Impact dashboard** — track total CO₂ retired globally, by project, and by address
- 🧪 **Full Clarinet test suite**

---

## The Problem With Traditional Carbon Markets

The voluntary carbon market is worth billions — but its foundations are shaky:

**Double-counting** — the same carbon offset is sold to multiple buyers across different registries with no cross-registry reconciliation.

**Greenwashing** — companies claim carbon neutrality by purchasing low-quality credits from projects that deliver little or no real climate benefit.

**Opacity** — traditional registries like Verra and Gold Standard are private databases. The public cannot independently verify claims without paying for access.

**No real-time audit trail** — credits can be issued, transferred, and retired through manual processes with significant delays and room for error.

**Single point of failure** — a centralized registry can be hacked, corrupted, or shut down, wiping retirement records and credit histories.

---

## How GreenStac Solves It

| Problem | GreenStac Solution |
|---|---|
| Double-counting | Each credit has a unique on-chain ID; retired credits are permanently burned — impossible to reuse |
| Greenwashing | All project metadata, methodology, and verification docs are linked on-chain and publicly auditable |
| Opacity | Entire registry is public on the Stacks blockchain — no login required to verify any credit |
| No audit trail | Every issuance, transfer, and retirement is an immutable on-chain event with block height timestamp |
| Single point of failure | Anchored to Bitcoin via Stacks — no central server to hack or shut down |

---

## How It Works

```
Project Developer              GreenStac Contract              Buyer / Offsetter
       │                              │                               │
       │── register-project ─────────►│                               │
       │◄─ project-id returned ───────│                               │
       │                              │                               │
       │   [Verifier approves         │                               │
       │    the project off-chain     │                               │
       │    and calls verify-project] │                               │
       │                              │                               │
       │── issue-credits ─────────────►│                              │
       │◄─ credit batch minted ───────│                               │
       │                              │                               │
       │── transfer-credits ──────────►│◄── purchase / receive ───────│
       │                              │                               │
       │                              │◄── retire-credits ────────────│
       │                              │    (permanently burned,       │
       │                              │     retirement cert issued)   │
       │                              │                               │
       │                              │◄── verify-retirement ─────────│
       │                              │    (public, permissionless)   │
```

---

## Architecture

GreenStac is a single Clarity contract with supporting maps for projects, credit batches, individual credits, retirements, verifiers, and flags.

```
┌────────────────────────────────────────────────────────────────────┐
│                         greenstac.clar                             │
│                                                                    │
│  ┌───────────────────────┐   ┌────────────────────────────────┐   │
│  │    Project Map        │   │       Credit Batch Map         │   │
│  │  project-id → {       │   │  batch-id → {                  │   │
│  │    name,              │   │    project-id,                 │   │
│  │    developer,         │   │    credits-issued,             │   │
│  │    project-type,      │   │    credits-retired,            │   │
│  │    country,           │   │    vintage-year,               │   │
│  │    methodology,       │   │    issuance-block,             │   │
│  │    verified,          │   │    methodology,                │   │
│  │    verifier,          │   │    status                      │   │
│  │    total-issued,      │   │  }                             │   │
│  │    total-retired,     │   └────────────────────────────────┘   │
│  │    metadata-uri,      │                                        │
│  │    status             │   ┌────────────────────────────────┐   │
│  │  }                    │   │       Credit Map               │   │
│  └───────────────────────┘   │  credit-id → {                 │   │
│                              │    batch-id,                   │   │
│  ┌───────────────────────┐   │    project-id,                 │   │
│  │   Retirement Map      │   │    owner,                      │   │
│  │  retirement-id → {    │   │    vintage-year,               │   │
│  │    credit-ids[],      │   │    status (active/retired),    │   │
│  │    retiree,           │   │    issued-at                   │   │
│  │    reason,            │   │  }                             │   │
│  │    retired-at,        │   └────────────────────────────────┘   │
│  │    tonnes-offset,     │                                        │
│  │    certificate-uri    │   ┌────────────────────────────────┐   │
│  │  }                    │   │       Verifier Map             │   │
│  └───────────────────────┘   │  principal → {                 │   │
│                              │    name,                       │   │
│  ┌───────────────────────┐   │    accreditation,              │   │
│  │      Flag Map         │   │    active                      │   │
│  │  project/credit → {   │   │  }                             │   │
│  │    flagger,           │   └────────────────────────────────┘   │
│  │    reason,            │                                        │
│  │    resolved           │                                        │
│  │  }                    │                                        │
│  └───────────────────────┘                                        │
└────────────────────────────────────────────────────────────────────┘
```

---

## Credit Lifecycle

Every GreenStac credit moves through a strict, one-way lifecycle. Transitions are enforced by the contract and cannot be reversed.

```
PROJECT REGISTERED
        │
        ▼
PROJECT PENDING VERIFICATION
        │
        ▼ (verifier calls verify-project)
PROJECT VERIFIED ──────────────────────────────► PROJECT SUSPENDED
        │                                         (flagged/disputed)
        ▼
CREDITS ISSUED (batch minted, credits ACTIVE)
        │
        ├──► TRANSFERRED (owner changes, status stays ACTIVE)
        │
        ▼
CREDITS RETIRED (permanent — status RETIRED, can never be transferred)
        │
        ▼
RETIREMENT CERTIFICATE ISSUED (on-chain record, public forever)
```

A retired credit is permanently burned. It cannot be transferred, re-issued, or reused in any way. This makes double-counting cryptographically impossible.

---

## Project Types

GreenStac supports all major voluntary carbon market project categories:

| Type | Code | Description | Example |
|---|---|---|---|
| Forestry & Land Use | `REDD+` | Preventing deforestation | Amazon forest conservation |
| Renewable Energy | `RE` | Clean energy generation | Solar farm in Nigeria |
| Methane Capture | `CH4` | Capturing landfill or agricultural methane | Landfill gas capture |
| Energy Efficiency | `EE` | Reducing energy consumption | Efficient cookstoves program |
| Blue Carbon | `BC` | Ocean and coastal ecosystems | Mangrove restoration |
| Soil Carbon | `SC` | Agricultural land carbon sequestration | Regenerative farming |
| Direct Air Capture | `DAC` | Technology-based CO₂ removal | Carbon capture facility |
| Community Projects | `CP` | Social co-benefit projects | Clean water + carbon |

---

## Contract Reference

### Public Functions

#### `register-project`
Register a new carbon offset project. Returns a unique project ID.

```clarity
(define-public (register-project
  (name (string-utf8 128))
  (project-type (string-ascii 16))
  (country (string-utf8 64))
  (methodology (string-utf8 128))
  (estimated-annual-tonnes uint)
  (metadata-uri (string-utf8 256))))
```

| Parameter | Description |
|---|---|
| `name` | Project name |
| `project-type` | One of the project type codes above |
| `country` | Country where the project is located |
| `methodology` | Verification standard used (e.g. Verra VCS, Gold Standard) |
| `estimated-annual-tonnes` | Estimated annual CO₂ offset in tonnes |
| `metadata-uri` | IPFS or Arweave link to full project documentation |

---

#### `verify-project`
Approve a registered project. Only callable by approved verifiers.

```clarity
(define-public (verify-project
  (project-id uint)
  (verification-uri (string-utf8 256))))
```

---

#### `issue-credits`
Mint a batch of carbon credits for a verified project. Only the project developer can call this.

```clarity
(define-public (issue-credits
  (project-id uint)
  (amount uint)
  (vintage-year uint)
  (batch-metadata-uri (optional (string-utf8 256)))))
```

| Parameter | Description |
|---|---|
| `amount` | Number of credits to issue (1 credit = 1 tonne CO₂e) |
| `vintage-year` | The year the carbon offset actually occurred |

---

#### `transfer-credits`
Transfer one or more active credits to another address.

```clarity
(define-public (transfer-credits
  (credit-ids (list 200 uint))
  (recipient principal)
  (memo (optional (string-utf8 256)))))
```

---

#### `retire-credits`
Permanently retire credits to claim a carbon offset. Retired credits cannot be transferred.

```clarity
(define-public (retire-credits
  (credit-ids (list 200 uint))
  (reason (string-utf8 256))
  (beneficiary (optional principal))
  (certificate-uri (optional (string-utf8 256)))))
```

| Parameter | Description |
|---|---|
| `credit-ids` | List of credit IDs to retire (max 200 per tx) |
| `reason` | Reason for retirement (e.g. "2025 corporate emissions offset") |
| `beneficiary` | Optional — retire on behalf of another entity |
| `certificate-uri` | Optional IPFS link to a formal retirement certificate |

---

#### `flag-project`
Raise a public dispute flag on a project. Permissionless — anyone can flag.

```clarity
(define-public (flag-project
  (project-id uint)
  (reason (string-utf8 256))))
```

---

#### `resolve-flag`
Resolve a dispute flag. Only the contract owner or an approved verifier can resolve.

```clarity
(define-public (resolve-flag
  (project-id uint)
  (flagger principal)
  (resolution (string-utf8 256))))
```

---

#### `add-verifier`
Add a new approved verifier. Only callable by the contract owner.

```clarity
(define-public (add-verifier
  (verifier principal)
  (name (string-utf8 64))
  (accreditation (string-utf8 128))))
```

---

### Read-Only Functions

```clarity
;; Get full project details
(define-read-only (get-project (project-id uint)))

;; Get credit batch details
(define-read-only (get-batch (batch-id uint)))

;; Get individual credit details
(define-read-only (get-credit (credit-id uint)))

;; Get retirement certificate details
(define-read-only (get-retirement (retirement-id uint)))

;; Get all credits owned by an address
(define-read-only (get-credits-by-owner (owner principal)))

;; Get total credits retired by an address
(define-read-only (get-total-retired-by (address principal)))

;; Get total CO₂ offset registered globally on GreenStac
(define-read-only (get-global-retired-tonnes))

;; Get total credits issued globally
(define-read-only (get-global-issued-credits))

;; Get verifier details
(define-read-only (get-verifier (verifier principal)))

;; Check if a credit is active (not yet retired)
(define-read-only (is-credit-active (credit-id uint)))

;; Get all flags on a project
(define-read-only (get-project-flags (project-id uint)))

;; Get total number of registered projects
(define-read-only (get-project-count))
```

---

### Error Codes

| Code | Constant | Description |
|---|---|---|
| `u600` | `err-project-not-found` | Project ID does not exist |
| `u601` | `err-not-project-developer` | Caller is not the project developer |
| `u602` | `err-project-not-verified` | Cannot issue credits on unverified project |
| `u603` | `err-project-suspended` | Project is suspended due to open dispute |
| `u604` | `err-credit-not-found` | Credit ID does not exist |
| `u605` | `err-not-credit-owner` | Caller does not own this credit |
| `u606` | `err-credit-already-retired` | Credit has already been retired |
| `u607` | `err-not-verifier` | Caller is not an approved verifier |
| `u608` | `err-already-verified` | Project is already verified |
| `u609` | `err-invalid-vintage-year` | Vintage year is in the future or invalid |
| `u610` | `err-invalid-project-type` | Project type code not recognised |
| `u611` | `err-zero-amount` | Cannot issue or transfer zero credits |
| `u612` | `err-batch-too-large` | Credit list exceeds maximum of 200 per tx |
| `u613` | `err-already-flagged` | Caller already flagged this project |
| `u614` | `err-flag-not-found` | No flag found from this address |
| `u615` | `err-self-transfer` | Cannot transfer credits to yourself |
| `u616` | `err-verifier-already-exists` | Verifier is already registered |

---

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) — Clarity development toolchain
- [Hiro Wallet](https://wallet.hiro.so/) — for testnet/mainnet interactions
- Node.js v18+ — for scripts and certificate generation
- STX for gas fees

### Installation

```bash
# Clone the repository
git clone https://github.com/your-username/greenstac.git
cd greenstac

# Install dependencies
npm install

# Verify contracts compile
clarinet check

# Run the test suite
clarinet test
```

---

## Registering a Carbon Project

Any address can register a carbon project. It enters a pending state until a verifier approves it.

```clarity
(contract-call? .greenstac register-project
  u"Okomu Forest Conservation Project"
  "REDD+"
  u"Nigeria"
  u"Verra VCS VM0015"
  u50000
  u"ipfs://QmProjectDocumentationHash")
```

Returns `(ok u1)` — your project ID is `1`.

### What goes in the metadata URI

Your IPFS or Arweave document should include:
- Project design document (PDD)
- Satellite imagery proving forest coverage
- Baseline emissions methodology
- Monitoring and verification reports
- Legal land tenure documentation
- Community benefit sharing agreements

---

## Issuing Credits

Once a verifier has approved your project, you can issue credit batches:

```clarity
;; Issue 10,000 credits for the 2025 vintage
(contract-call? .greenstac issue-credits
  u1          ;; project-id
  u10000      ;; 10,000 tonnes CO₂e
  u2025       ;; vintage year
  (some u"ipfs://QmBatchVerificationReport"))
```

Each credit gets a unique on-chain ID and is assigned to the project developer as initial owner.

---

## Transferring Credits

```clarity
;; Transfer 500 credits to a corporate buyer
(contract-call? .greenstac transfer-credits
  (list u1 u2 u3 ... u500)   ;; list of credit IDs
  'SPBuyerAddress...
  (some u"Purchase order #PO-2025-0042"))
```

---

## Retiring Credits

Retirement is permanent and irreversible. Once retired, a credit is burned forever.

```clarity
;; Retire 100 credits to offset 2025 corporate emissions
(contract-call? .greenstac retire-credits
  (list u501 u502 ... u600)
  u"Acme Corp 2025 Annual Emissions Offset"
  (some 'SPAcmeCorpAddress...)
  (some u"ipfs://QmRetirementCertificateHash"))
```

The contract emits a permanent retirement record containing:
- Retiree address
- Number of tonnes offset
- Project and vintage details
- Block height and timestamp
- Beneficiary (if retiring on behalf of another entity)

---

## Verifying a Credit

Anyone can verify any credit's full history with no login required:

```bash
# CLI verification
node scripts/verify-credit.js --credit-id 42 --network mainnet
```

Output:
```
GreenStac Credit Verification
══════════════════════════════════════════════
Credit ID:        42
Status:           RETIRED ✅
Project:          Okomu Forest Conservation Project (#1)
Project Type:     REDD+ (Forestry & Land Use)
Country:          Nigeria
Vintage Year:     2025
Methodology:      Verra VCS VM0015
Verified By:      South Pole Group (SP3VER...)
Batch ID:         3
Issued At:        Block 148200 (2025-03-15)

Retirement:
  Retired By:     SP9876...AcmeCorp
  Beneficiary:    Acme Corp
  Reason:         Acme Corp 2025 Annual Emissions Offset
  Retired At:     Block 152440 (2025-11-02)
  Certificate:    ipfs://QmRetirementCertificateHash

Flags:            None ✅
```

---

## Dispute & Flagging System

GreenStac is permissionless — anyone can raise a flag on a project they believe is fraudulent or non-compliant:

```clarity
;; Anyone can flag a suspicious project
(contract-call? .greenstac flag-project
  u1
  u"Satellite imagery shows deforestation in the project boundary since 2024. Evidence at ipfs://Qm...")
```

Flagged projects are marked as SUSPENDED — no new credits can be issued until the flag is resolved by an approved verifier. Existing credits remain valid but the suspension is publicly visible.

```clarity
;; Verifier resolves the flag after investigation
(contract-call? .greenstac resolve-flag
  u1
  'SPFlaggerAddress...
  u"Investigation complete. Deforestation was outside project boundary. Satellite report at ipfs://Qm...")
```

All flags and resolutions are permanently on-chain — the full dispute history of every project is publicly auditable forever.

---

## Leaderboard & Impact Dashboard

GreenStac maintains a global on-chain impact ledger. Query it anytime:

```clarity
;; Total CO₂ offset through GreenStac globally
(contract-call? .greenstac get-global-retired-tonnes)

;; Total credits retired by a specific address
(contract-call? .greenstac get-total-retired-by 'SPAcmeCorpAddress...)

;; Full project stats
(contract-call? .greenstac get-project u1)
```

Use the included dashboard script to generate a formatted impact report:

```bash
node scripts/impact-report.js --address SPAcmeCorpAddress... --network mainnet
```

---

## Project Structure

```
greenstac/
├── contracts/
│   └── greenstac.clar                  # Main carbon registry contract
├── tests/
│   └── greenstac_test.ts               # Full Clarinet test suite
├── scripts/
│   ├── register-project.ts             # CLI: register a carbon project
│   ├── issue-credits.ts                # CLI: issue a credit batch
│   ├── transfer-credits.ts             # CLI: transfer credits
│   ├── retire-credits.ts               # CLI: retire credits
│   ├── verify-credit.ts                # CLI: verify a credit's full history
│   ├── flag-project.ts                 # CLI: flag a suspicious project
│   ├── impact-report.ts                # CLI: generate impact report
│   └── add-verifier.ts                 # CLI: register a new verifier (owner only)
├── deployments/
│   ├── devnet.yaml
│   ├── testnet.yaml
│   └── mainnet.yaml
├── settings/
│   └── Devnet.toml
├── Clarinet.toml
├── package.json
└── README.md
```

---

## Testing

```bash
# Run all tests
clarinet test

# Run with coverage report
clarinet test --coverage

# Open interactive Clarinet console
clarinet console
```

### Test coverage includes

- Project registration and ID assignment
- Project pending state before verification
- Verifier approves project — status changes to verified
- Non-verifier cannot verify a project
- Credits cannot be issued on unverified project
- Credit issuance — batch minted, correct amount
- Future vintage year rejected
- Credit transfer — new owner recorded
- Non-owner cannot transfer credits
- Self-transfer rejected
- Credit retirement — status permanently set to RETIRED
- Retired credit cannot be transferred
- Retired credit cannot be retired again
- Double-counting impossible — retired ID is burned
- Flag a project — project suspended
- No new credits on suspended project
- Verifier resolves flag — project unsuspended
- Global retired tonnes counter increments correctly
- Retirement certificate record created on-chain
- All error codes triggered and verified

---

## Roadmap

- [x] Carbon project registration with metadata
- [x] Verifier approval system
- [x] Credit issuance with vintage year tracking
- [x] Credit transfer between addresses
- [x] Permanent retirement with on-chain certificate
- [x] Dispute and flagging system
- [x] Global impact ledger
- [ ] Web UI — project browser and retirement dashboard
- [ ] Credit marketplace — list and purchase credits on-chain
- [ ] Fractionalized credits — trade partial tonnes (0.01 tonne precision)
- [ ] SIP-009 retirement NFTs — mint a collectible certificate when retiring credits
- [ ] Integration with StacksMint — issue GSTAC governance tokens to active verifiers
- [ ] Integration with QuorumStack — require multisig for large credit issuances
- [ ] Automated satellite data oracle — flag projects with detected deforestation
- [ ] Corporate ESG reporting module — auto-generate annual offset reports
- [ ] Mobile-friendly retirement certificate viewer
- [ ] DAO governance for verifier accreditation

---

## Contributing

Contributions are welcome — especially from climate scientists, carbon market experts, and GIS specialists who can help improve project methodology validation. To get started:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`clarinet test`)
5. Open a pull request with a clear description

Please read [CONTRIBUTING.md](./CONTRIBUTING.md) before submitting.

---

## License

GreenStac is open source under the [MIT License](./LICENSE).

---

Built with ❤️ on [Stacks](https://stacks.co) — Bitcoin's smart contract layer.

> Every tonne retired on GreenStac is a tonne the planet can trust.

;; GreenStac Smart Contract
;; A transparent, on-chain carbon credit registry

;; Constants and Error Codes
(define-constant contract-owner tx-sender)

(define-constant err-project-not-found (err u600))
(define-constant err-not-project-developer (err u601))
(define-constant err-project-not-verified (err u602))
(define-constant err-project-suspended (err u603))
(define-constant err-credit-not-found (err u604))
(define-constant err-not-credit-owner (err u605))
(define-constant err-credit-already-retired (err u606))
(define-constant err-not-verifier (err u607))
(define-constant err-already-verified (err u608))
(define-constant err-invalid-vintage-year (err u609))
(define-constant err-invalid-project-type (err u610))
(define-constant err-zero-amount (err u611))
(define-constant err-batch-too-large (err u612))
(define-constant err-already-flagged (err u613))
(define-constant err-flag-not-found (err u614))
(define-constant err-self-transfer (err u615))
(define-constant err-verifier-already-exists (err u616))

;; Data Vars
(define-data-var project-count uint u0)
(define-data-var batch-count uint u0)
(define-data-var retirement-count uint u0)
(define-data-var global-retired-tonnes uint u0)
(define-data-var global-issued-credits uint u0)

;; Utility Counter
(define-data-var counter int 0)

;; Data Maps
(define-map projects
    uint
    {
        name: (string-utf8 128),
        developer: principal,
        project-type: (string-ascii 16),
        country: (string-utf8 64),
        methodology: (string-utf8 128),
        estimated-annual-tonnes: uint,
        verified: bool,
        verifier: (optional principal),
        total-issued: uint,
        total-retired: uint,
        metadata-uri: (string-utf8 256),
        status: (string-ascii 16)
    }
)

(define-map batches
    uint
    {
        project-id: uint,
        credits-issued: uint,
        credits-retired: uint,
        vintage-year: uint,
        issuance-block: uint,
        metadata-uri: (optional (string-utf8 256)),
        status: (string-ascii 16)
    }
)

(define-map credits
    uint
    {
        batch-id: uint,
        project-id: uint,
        owner: principal,
        vintage-year: uint,
        status: (string-ascii 16),
        issued-at: uint
    }
)

(define-map retirements
    uint
    {
        credit-ids: (list 200 uint),
        retiree: principal,
        reason: (string-utf8 256),
        retired-at: uint,
        tonnes-offset: uint,
        beneficiary: (optional principal),
        certificate-uri: (optional (string-utf8 256))
    }
)

(define-map verifiers
    principal
    {
        name: (string-utf8 64),
        accreditation: (string-utf8 128),
        active: bool
    }
)

(define-map flags
    uint
    {
        flagger: principal,
        reason: (string-utf8 256),
        resolved: bool
    }
)

(define-map user-retired-totals principal uint)

;; Private helper to validate project type
(define-private (is-valid-project-type (pt (string-ascii 16)))
  (or
    (is-eq pt "REDD+")
    (is-eq pt "RE")
    (is-eq pt "CH4")
    (is-eq pt "EE")
    (is-eq pt "BC")
    (is-eq pt "SC")
    (is-eq pt "DAC")
    (is-eq pt "CP")
  )
)

;; Utility functions for test (counter)
(define-public (increment-counter)
  (begin
    (var-set counter (+ (var-get counter) 1))
    (ok (var-get counter))
  )
)

(define-public (decrement-counter)
  (begin
    (var-set counter (- (var-get counter) 1))
    (ok (var-get counter))
  )
)

(define-read-only (get-counter)
  (var-get counter)
)

;; Core Public Functions
(define-public (register-project
  (name (string-utf8 128))
  (project-type (string-ascii 16))
  (country (string-utf8 64))
  (methodology (string-utf8 128))
  (estimated-annual-tonnes uint)
  (metadata-uri (string-utf8 256)))
  (begin
    (asserts! (is-valid-project-type project-type) err-invalid-project-type)
    (let
      ((new-id (+ (var-get project-count) u1)))
      (map-set projects new-id {
        name: name,
        developer: tx-sender,
        project-type: project-type,
        country: country,
        methodology: methodology,
        estimated-annual-tonnes: estimated-annual-tonnes,
        verified: false,
        verifier: none,
        total-issued: u0,
        total-retired: u0,
        metadata-uri: metadata-uri,
        status: "PENDING"
      })
      (var-set project-count new-id)
      (ok new-id)
    )
  )
)

(define-public (verify-project (project-id uint) (verification-uri (string-utf8 256)))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-project-not-found))
      (verifier-info (unwrap! (map-get? verifiers tx-sender) err-not-verifier))
    )
    (asserts! (get active verifier-info) err-not-verifier)
    (asserts! (not (get verified project)) err-already-verified)
    
    (map-set projects project-id (merge project {
      verified: true,
      verifier: (some tx-sender),
      status: "VERIFIED"
    }))
    (ok true)
  )
)

(define-public (add-verifier (verifier principal) (name (string-utf8 64)) (accreditation (string-utf8 128)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-not-verifier)
    (asserts! (is-none (map-get? verifiers verifier)) err-verifier-already-exists)
    (map-set verifiers verifier {
      name: name,
      accreditation: accreditation,
      active: true
    })
    (ok true)
  )
)

(define-public (issue-credits
  (project-id uint)
  (amount uint)
  (vintage-year uint)
  (batch-metadata-uri (optional (string-utf8 256))))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-project-not-found))
    )
    (asserts! (is-eq (get developer project) tx-sender) err-not-project-developer)
    (asserts! (get verified project) err-project-not-verified)
    (asserts! (not (is-eq (get status project) "SUSPENDED")) err-project-suspended)
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (and (>= vintage-year u1990) (<= vintage-year u2100)) err-invalid-vintage-year)

    (let
      (
        (batch-id (+ (var-get batch-count) u1))
      )
      (map-set batches batch-id {
        project-id: project-id,
        credits-issued: amount,
        credits-retired: u0,
        vintage-year: vintage-year,
        issuance-block: burn-block-height,
        metadata-uri: batch-metadata-uri,
        status: "ACTIVE"
      })
      (map-set projects project-id (merge project {
        total-issued: (+ (get total-issued project) amount)
      }))
      (var-set batch-count batch-id)
      (var-set global-issued-credits (+ (var-get global-issued-credits) amount))
      (ok batch-id)
    )
  )
)

;; Transfer credits
(define-private (transfer-credit-step (credit-id uint) (context { recipient: principal, sender: principal, success: bool }))
  (let
    (
      (credit-opt (get-credit credit-id))
    )
    (match credit-opt credit
      (if (and 
            (get success context) 
            (is-eq (get owner credit) (get sender context))
            (is-eq (get status credit) "ACTIVE")
          )
        (begin
          (map-set credits credit-id (merge credit { owner: (get recipient context) }))
          { recipient: (get recipient context), sender: (get sender context), success: true }
        )
        (merge context { success: false })
      )
      (merge context { success: false })
    )
  )
)

(define-public (transfer-credits
  (credit-ids (list 200 uint))
  (recipient principal)
  (memo (optional (string-utf8 256))))
  (begin
    (asserts! (> (len credit-ids) u0) err-zero-amount)
    (asserts! (not (is-eq tx-sender recipient)) err-self-transfer)

    (let
      (
        (result (fold transfer-credit-step credit-ids { recipient: recipient, sender: tx-sender, success: true }))
      )
      (if (get success result)
        (begin
          (print memo)
          (ok true)
        )
        err-not-credit-owner
      )
    )
  )
)

;; Retire credits
(define-private (retire-credit-step (credit-id uint) (context { sender: principal, success: bool }))
  (let
    (
      (credit-opt (get-credit credit-id))
    )
    (match credit-opt credit
      (if (and 
            (get success context) 
            (is-eq (get owner credit) (get sender context))
            (is-eq (get status credit) "ACTIVE")
          )
        (begin
          (map-set credits credit-id (merge credit { status: "RETIRED" }))
          
          ;; Update project totals
          (match (map-get? projects (get project-id credit)) project
            (map-set projects (get project-id credit) (merge project { total-retired: (+ (get total-retired project) u1) }))
            false
          )
          ;; Update batch totals
          (match (map-get? batches (get batch-id credit)) batch
            (map-set batches (get batch-id credit) (merge batch { credits-retired: (+ (get credits-retired batch) u1) }))
            false
          )

          { sender: (get sender context), success: true }
        )
        (merge context { success: false })
      )
      (merge context { success: false })
    )
  )
)

(define-public (retire-credits
  (credit-ids (list 200 uint))
  (reason (string-utf8 256))
  (beneficiary (optional principal))
  (certificate-uri (optional (string-utf8 256))))
  (begin
    (asserts! (> (len credit-ids) u0) err-zero-amount)
    
    (let
      (
        (result (fold retire-credit-step credit-ids { sender: tx-sender, success: true }))
        (amount (len credit-ids))
        (retirement-id (+ (var-get retirement-count) u1))
      )
      (if (get success result)
        (begin
          (map-set retirements retirement-id {
            credit-ids: credit-ids,
            retiree: tx-sender,
            reason: reason,
            retired-at: burn-block-height,
            tonnes-offset: amount,
            beneficiary: beneficiary,
            certificate-uri: certificate-uri
          })
          
          (var-set global-retired-tonnes (+ (var-get global-retired-tonnes) amount))
          (var-set retirement-count retirement-id)
          (map-set user-retired-totals tx-sender (+ (default-to u0 (map-get? user-retired-totals tx-sender)) amount))

          (ok true)
        )
        err-credit-already-retired
      )
    )
  )
)

(define-public (flag-project (project-id uint) (reason (string-utf8 256)))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-project-not-found))
    )
    (asserts! (is-none (map-get? flags project-id)) err-already-flagged)
    
    (map-set flags project-id {
      flagger: tx-sender,
      reason: reason,
      resolved: false
    })
    
    (map-set projects project-id (merge project { status: "SUSPENDED" }))
    (ok true)
  )
)

(define-public (resolve-flag (project-id uint) (flagger principal) (resolution (string-utf8 256)))
  (let
    (
      (project (unwrap! (map-get? projects project-id) err-project-not-found))
      (flag (unwrap! (map-get? flags project-id) err-flag-not-found))
      (verifier-info (map-get? verifiers tx-sender))
    )
    (asserts! (or (is-eq tx-sender contract-owner) (is-some verifier-info)) err-not-verifier)
    (asserts! (is-eq (get flagger flag) flagger) err-flag-not-found)
    
    (map-set flags project-id (merge flag { resolved: true }))
    (map-set projects project-id (merge project { status: "VERIFIED" }))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-project (project-id uint))
  (map-get? projects project-id)
)

(define-read-only (get-batch (batch-id uint))
  (map-get? batches batch-id)
)

;; Virtual Credit Constructor
;; Each batch issues sequential IDs: (batch-id * 1,000,000,000) + offset
(define-read-only (get-credit (credit-id uint))
  (let
    (
      (batch-id (/ credit-id u1000000000))
      (offset (mod credit-id u1000000000))
      (batch-opt (map-get? batches batch-id))
      (credit-record (map-get? credits credit-id))
    )
    (match batch-opt batch
      (if (< offset (get credits-issued batch))
        (match credit-record record
          (some record)
          (match (map-get? projects (get project-id batch)) project
            (some {
              batch-id: batch-id,
              project-id: (get project-id batch),
              owner: (get developer project),
              vintage-year: (get vintage-year batch),
              status: "ACTIVE",
              issued-at: (get issuance-block batch)
            })
            none
          )
        )
        none
      )
      none
    )
  )
)

(define-read-only (get-retirement (retirement-id uint))
  (map-get? retirements retirement-id)
)

;; As Clarity does not support unbound dynamic lists, we return an empty list.
;; Off-chain indexers should be used to get all credits by an owner.
(define-read-only (get-credits-by-owner (owner principal))
  (list )
)

(define-read-only (get-total-retired-by (address principal))
  (default-to u0 (map-get? user-retired-totals address))
)

(define-read-only (get-global-retired-tonnes)
  (var-get global-retired-tonnes)
)

(define-read-only (get-global-issued-credits)
  (var-get global-issued-credits)
)

(define-read-only (get-verifier (verifier principal))
  (map-get? verifiers verifier)
)

(define-read-only (is-credit-active (credit-id uint))
  (is-eq (some "ACTIVE") (get status (get-credit credit-id)))
)

(define-read-only (get-project-flags (project-id uint))
  (map-get? flags project-id)
)

(define-read-only (get-project-count)
  (var-get project-count)
)

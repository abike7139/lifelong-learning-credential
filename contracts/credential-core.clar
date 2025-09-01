;; ===============================================
;; CREDENTIAL CORE CONTRACT
;; Handles digital credential issuance, verification, and management
;; ===============================================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u101))
(define-constant ERR-CREDENTIAL-EXPIRED (err u102))
(define-constant ERR-INVALID-ISSUER (err u103))
(define-constant ERR-CREDENTIAL-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-SKILL-LEVEL (err u105))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map credentials
  {
    credential-id: (string-ascii 64),
    holder: principal
  }
  {
    issuer: principal,
    skill-name: (string-ascii 50),
    skill-level: uint,
    issue-date: uint,
    expiry-date: uint,
    verification-status: (string-ascii 20),
    metadata: (string-ascii 200)
  }
)

(define-map authorized-issuers principal bool)

(define-map skill-registry
  (string-ascii 50)
  {
    category: (string-ascii 30),
    max-level: uint,
    verification-required: bool
  }
)

(define-map user-credentials
  principal
  {
    total-credentials: uint,
    verified-credentials: uint,
    last-update: uint
  }
)

;; Data variables
(define-data-var credential-counter uint u0)
(define-data-var total-issued-credentials uint u0)
(define-data-var total-verified-credentials uint u0)

;; Initialize contract with owner as authorized issuer
(map-set authorized-issuers CONTRACT-OWNER true)

;; =======================
;; PUBLIC FUNCTIONS
;; =======================

;; Issue a new credential
(define-public (issue-credential 
    (holder principal)
    (skill-name (string-ascii 50))
    (skill-level uint)
    (expiry-date uint)
    (metadata (string-ascii 200))
  )
  (let 
    (
      (new-id (+ (var-get credential-counter) u1))
      (credential-id (uint-to-string new-id))
      (current-block block-height)
    )
    (asserts! (is-authorized-issuer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= skill-level u1) (<= skill-level u10)) ERR-INVALID-SKILL-LEVEL)
    (asserts! (> expiry-date current-block) ERR-CREDENTIAL-EXPIRED)
    
    ;; Check if skill exists in registry, if not add with defaults
    (match (map-get? skill-registry skill-name)
      skill-info true
      (map-set skill-registry skill-name {
        category: "general",
        max-level: u10,
        verification-required: true
      })
    )
    
    ;; Store credential
    (map-set credentials
      {credential-id: credential-id, holder: holder}
      {
        issuer: tx-sender,
        skill-name: skill-name,
        skill-level: skill-level,
        issue-date: current-block,
        expiry-date: expiry-date,
        verification-status: "pending",
        metadata: metadata
      }
    )
    
    ;; Update counters
    (var-set credential-counter new-id)
    (var-set total-issued-credentials (+ (var-get total-issued-credentials) u1))
    
    ;; Update user credential count
    (update-user-credential-count holder)
    
    (ok credential-id)
  )
)

;; Verify a credential
(define-public (verify-credential 
    (credential-id (string-ascii 64))
    (holder principal)
  )
  (let 
    (
      (credential-key {credential-id: credential-id, holder: holder})
      (credential-data (unwrap! (map-get? credentials credential-key) ERR-CREDENTIAL-NOT-FOUND))
    )
    (asserts! (is-authorized-issuer tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (get expiry-date credential-data) block-height) ERR-CREDENTIAL-EXPIRED)
    
    ;; Update verification status
    (map-set credentials
      credential-key
      (merge credential-data {verification-status: "verified"})
    )
    
    ;; Update verified credential count
    (var-set total-verified-credentials (+ (var-get total-verified-credentials) u1))
    
    ;; Update user verified count
    (update-user-verified-count holder)
    
    (ok true)
  )
)

;; Add authorized issuer (only contract owner)
(define-public (add-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-issuers issuer true)
    (ok true)
  )
)

;; Remove authorized issuer (only contract owner)
(define-public (remove-authorized-issuer (issuer principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq issuer CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
    (map-delete authorized-issuers issuer)
    (ok true)
  )
)

;; Register a new skill in the registry
(define-public (register-skill 
    (skill-name (string-ascii 50))
    (category (string-ascii 30))
    (max-level uint)
    (verification-required bool)
  )
  (begin
    (asserts! (is-authorized-issuer tx-sender) ERR-NOT-AUTHORIZED)
    (map-set skill-registry skill-name {
      category: category,
      max-level: max-level,
      verification-required: verification-required
    })
    (ok true)
  )
)

;; Update credential status
(define-public (update-credential-status
    (credential-id (string-ascii 64))
    (holder principal)
    (new-status (string-ascii 20))
  )
  (let 
    (
      (credential-key {credential-id: credential-id, holder: holder})
      (credential-data (unwrap! (map-get? credentials credential-key) ERR-CREDENTIAL-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender (get issuer credential-data)) ERR-NOT-AUTHORIZED)
    
    (map-set credentials
      credential-key
      (merge credential-data {verification-status: new-status})
    )
    (ok true)
  )
)

;; =======================
;; READ-ONLY FUNCTIONS
;; =======================

;; Get credential details
(define-read-only (get-credential 
    (credential-id (string-ascii 64))
    (holder principal)
  )
  (map-get? credentials {credential-id: credential-id, holder: holder})
)

;; Check if credential is valid (not expired and verified)
(define-read-only (is-credential-valid 
    (credential-id (string-ascii 64))
    (holder principal)
  )
  (match (map-get? credentials {credential-id: credential-id, holder: holder})
    credential-data 
      (and 
        (> (get expiry-date credential-data) block-height)
        (is-eq (get verification-status credential-data) "verified")
      )
    false
  )
)

;; Get user credential summary
(define-read-only (get-user-credentials (user principal))
  (map-get? user-credentials user)
)

;; Get skill registry info
(define-read-only (get-skill-info (skill-name (string-ascii 50)))
  (map-get? skill-registry skill-name)
)

;; Check if user is authorized issuer
(define-read-only (is-authorized-issuer (issuer principal))
  (default-to false (map-get? authorized-issuers issuer))
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-issued: (var-get total-issued-credentials),
    total-verified: (var-get total-verified-credentials),
    current-block: block-height
  }
)

;; Get credential verification status
(define-read-only (get-verification-status
    (credential-id (string-ascii 64))
    (holder principal)
  )
  (match (map-get? credentials {credential-id: credential-id, holder: holder})
    credential-data (get verification-status credential-data)
    "not-found"
  )
)

;; =======================
;; PRIVATE FUNCTIONS
;; =======================

;; Update user credential count
(define-private (update-user-credential-count (user principal))
  (let 
    (
      (current-data (default-to 
        {total-credentials: u0, verified-credentials: u0, last-update: u0}
        (map-get? user-credentials user)
      ))
    )
    (map-set user-credentials user
      (merge current-data {
        total-credentials: (+ (get total-credentials current-data) u1),
        last-update: block-height
      })
    )
  )
)

;; Update user verified credential count
(define-private (update-user-verified-count (user principal))
  (let 
    (
      (current-data (default-to 
        {total-credentials: u0, verified-credentials: u0, last-update: u0}
        (map-get? user-credentials user)
      ))
    )
    (map-set user-credentials user
      (merge current-data {
        verified-credentials: (+ (get verified-credentials current-data) u1),
        last-update: block-height
      })
    )
  )
)

;; Convert integer to ASCII string (helper function)
(define-private (uint-to-string (value uint))
  (if (is-eq value u0)
    "0"
    (if (is-eq value u1) "1"
    (if (is-eq value u2) "2"
    (if (is-eq value u3) "3"
    (if (is-eq value u4) "4"
    (if (is-eq value u5) "5"
    (if (is-eq value u6) "6"
    (if (is-eq value u7) "7"
    (if (is-eq value u8) "8"
    (if (is-eq value u9) "9"
    (if (is-eq value u10) "10"
      "unknown"
    ))))))))))))

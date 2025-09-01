;; ===============================================
;; COMPETENCY TRACKER CONTRACT
;; Tracks individual competencies, professional development, and ROI
;; ===============================================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u200))
(define-constant ERR-COMPETENCY-NOT-FOUND (err u201))
(define-constant ERR-INVALID-INVESTMENT (err u202))
(define-constant ERR-INVALID-DURATION (err u203))
(define-constant ERR-DEVELOPMENT-NOT-FOUND (err u204))
(define-constant ERR-INVALID-SCORE (err u205))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-COMPETENCY-LEVEL u100)
(define-constant MIN-INVESTMENT-AMOUNT u1)

;; Data structures
(define-map user-competencies
  {
    user: principal,
    competency-id: (string-ascii 50)
  }
  {
    current-level: uint,
    target-level: uint,
    last-assessed: uint,
    assessment-score: uint,
    development-plan: (string-ascii 100),
    status: (string-ascii 20)
  }
)

(define-map professional-development
  {
    user: principal,
    activity-id: uint
  }
  {
    activity-type: (string-ascii 30),
    activity-name: (string-ascii 100),
    start-date: uint,
    end-date: uint,
    investment-amount: uint,
    completion-status: (string-ascii 20),
    competencies-gained: (list 5 (string-ascii 50)),
    roi-score: uint
  }
)

(define-map learning-investments
  principal
  {
    total-invested: uint,
    total-activities: uint,
    completed-activities: uint,
    average-roi: uint,
    last-investment: uint
  }
)

(define-map competency-definitions
  (string-ascii 50)
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    category: (string-ascii 30),
    industry-relevance: uint,
    market-demand: uint
  }
)

;; Data variables
(define-data-var activity-counter uint u0)
(define-data-var total-competencies uint u0)
(define-data-var total-investments uint u0)

;; =======================
;; PUBLIC FUNCTIONS
;; =======================

;; Add or update user competency
(define-public (set-user-competency
    (competency-id (string-ascii 50))
    (current-level uint)
    (target-level uint)
    (development-plan (string-ascii 100))
  )
  (let
    (
      (competency-key {user: tx-sender, competency-id: competency-id})
    )
    (asserts! (and (>= current-level u0) (<= current-level MAX-COMPETENCY-LEVEL)) ERR-INVALID-SCORE)
    (asserts! (and (>= target-level u0) (<= target-level MAX-COMPETENCY-LEVEL)) ERR-INVALID-SCORE)
    (asserts! (>= target-level current-level) ERR-INVALID-SCORE)
    
    ;; Store competency data
    (map-set user-competencies
      competency-key
      {
        current-level: current-level,
        target-level: target-level,
        last-assessed: block-height,
        assessment-score: current-level,
        development-plan: development-plan,
        status: "active"
      }
    )
    
    ;; Update total competencies if new
    (if (is-none (map-get? user-competencies competency-key))
      (var-set total-competencies (+ (var-get total-competencies) u1))
      true
    )
    
    (ok true)
  )
)

;; Record professional development activity
(define-public (record-development-activity
    (activity-type (string-ascii 30))
    (activity-name (string-ascii 100))
    (end-date uint)
    (investment-amount uint)
    (competencies-gained (list 5 (string-ascii 50)))
  )
  (let
    (
      (new-activity-id (+ (var-get activity-counter) u1))
      (activity-key {user: tx-sender, activity-id: new-activity-id})
      (current-block block-height)
    )
    (asserts! (>= investment-amount MIN-INVESTMENT-AMOUNT) ERR-INVALID-INVESTMENT)
    (asserts! (> end-date current-block) ERR-INVALID-DURATION)
    
    ;; Store activity
    (map-set professional-development
      activity-key
      {
        activity-type: activity-type,
        activity-name: activity-name,
        start-date: current-block,
        end-date: end-date,
        investment-amount: investment-amount,
        completion-status: "in-progress",
        competencies-gained: competencies-gained,
        roi-score: u0
      }
    )
    
    ;; Update counters
    (var-set activity-counter new-activity-id)
    (var-set total-investments (+ (var-get total-investments) investment-amount))
    
    ;; Update user investment tracking
    (update-learning-investment tx-sender investment-amount)
    
    (ok new-activity-id)
  )
)

;; Complete development activity and calculate ROI
(define-public (complete-development-activity
    (activity-id uint)
    (roi-score uint)
  )
  (let
    (
      (activity-key {user: tx-sender, activity-id: activity-id})
      (activity-data (unwrap! (map-get? professional-development activity-key) ERR-DEVELOPMENT-NOT-FOUND))
    )
    (asserts! (and (>= roi-score u0) (<= roi-score u100)) ERR-INVALID-SCORE)
    
    ;; Update activity completion
    (map-set professional-development
      activity-key
      (merge activity-data {
        completion-status: "completed",
        roi-score: roi-score
      })
    )
    
    ;; Update user investment tracking
    (update-completed-activity tx-sender roi-score)
    
    (ok true)
  )
)

;; Update competency assessment
(define-public (update-assessment
    (competency-id (string-ascii 50))
    (new-score uint)
  )
  (let
    (
      (competency-key {user: tx-sender, competency-id: competency-id})
      (competency-data (unwrap! (map-get? user-competencies competency-key) ERR-COMPETENCY-NOT-FOUND))
    )
    (asserts! (and (>= new-score u0) (<= new-score MAX-COMPETENCY-LEVEL)) ERR-INVALID-SCORE)
    
    ;; Update assessment
    (map-set user-competencies
      competency-key
      (merge competency-data {
        current-level: new-score,
        last-assessed: block-height,
        assessment-score: new-score
      })
    )
    
    (ok true)
  )
)

;; Define competency standards
(define-public (define-competency
    (competency-id (string-ascii 50))
    (name (string-ascii 50))
    (description (string-ascii 200))
    (category (string-ascii 30))
    (industry-relevance uint)
    (market-demand uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (>= industry-relevance u1) (<= industry-relevance u10)) ERR-INVALID-SCORE)
    (asserts! (and (>= market-demand u1) (<= market-demand u10)) ERR-INVALID-SCORE)
    
    (map-set competency-definitions competency-id {
      name: name,
      description: description,
      category: category,
      industry-relevance: industry-relevance,
      market-demand: market-demand
    })
    
    (ok true)
  )
)

;; =======================
;; READ-ONLY FUNCTIONS
;; =======================

;; Get user competency details
(define-read-only (get-user-competency
    (user principal)
    (competency-id (string-ascii 50))
  )
  (map-get? user-competencies {user: user, competency-id: competency-id})
)

;; Get development activity details
(define-read-only (get-development-activity
    (user principal)
    (activity-id uint)
  )
  (map-get? professional-development {user: user, activity-id: activity-id})
)

;; Get user learning investment summary
(define-read-only (get-learning-investments (user principal))
  (map-get? learning-investments user)
)

;; Get competency definition
(define-read-only (get-competency-definition (competency-id (string-ascii 50)))
  (map-get? competency-definitions competency-id)
)

;; Calculate competency progress percentage
(define-read-only (get-competency-progress
    (user principal)
    (competency-id (string-ascii 50))
  )
  (match (map-get? user-competencies {user: user, competency-id: competency-id})
    competency-data
      (let
        (
          (current (get current-level competency-data))
          (target (get target-level competency-data))
        )
        (if (is-eq target u0)
          u100
          (/ (* current u100) target)
        )
      )
    u0
  )
)

;; Get user's ROI average
(define-read-only (get-user-roi-average (user principal))
  (match (map-get? learning-investments user)
    investment-data (get average-roi investment-data)
    u0
  )
)

;; Get contract statistics
(define-read-only (get-tracker-stats)
  {
    total-competencies: (var-get total-competencies),
    total-investments: (var-get total-investments),
    activity-counter: (var-get activity-counter)
  }
)

;; =======================
;; PRIVATE FUNCTIONS
;; =======================

;; Update learning investment tracking
(define-private (update-learning-investment (user principal) (amount uint))
  (let
    (
      (current-data (default-to
        {total-invested: u0, total-activities: u0, completed-activities: u0, average-roi: u0, last-investment: u0}
        (map-get? learning-investments user)
      ))
    )
    (map-set learning-investments user
      (merge current-data {
        total-invested: (+ (get total-invested current-data) amount),
        total-activities: (+ (get total-activities current-data) u1),
        last-investment: block-height
      })
    )
  )
)

;; Update completed activity and ROI
(define-private (update-completed-activity (user principal) (roi uint))
  (let
    (
      (current-data (default-to
        {total-invested: u0, total-activities: u0, completed-activities: u0, average-roi: u0, last-investment: u0}
        (map-get? learning-investments user)
      ))
      (new-completed (+ (get completed-activities current-data) u1))
      (current-avg (get average-roi current-data))
      (new-average (/ (+ (* current-avg (get completed-activities current-data)) roi) new-completed))
    )
    (map-set learning-investments user
      (merge current-data {
        completed-activities: new-completed,
        average-roi: new-average
      })
    )
  )
)

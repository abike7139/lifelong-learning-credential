;; ===============================================
;; CAREER PATH CONTRACT
;; Manages career planning, industry alignment, and job market analysis
;; ===============================================

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-PATH-NOT-FOUND (err u301))
(define-constant ERR-INVALID-TIMELINE (err u302))
(define-constant ERR-MILESTONE-NOT-FOUND (err u303))
(define-constant ERR-INVALID-INDUSTRY (err u304))
(define-constant ERR-INVALID-PRIORITY (err u305))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-MILESTONES u20)
(define-constant MAX-PRIORITY-LEVEL u5)

;; Data structures
(define-map career-paths
  {
    user: principal,
    path-id: uint
  }
  {
    title: (string-ascii 100),
    target-role: (string-ascii 50),
    industry: (string-ascii 30),
    timeline-months: uint,
    status: (string-ascii 20),
    progress-percentage: uint,
    created-at: uint,
    updated-at: uint
  }
)

(define-map career-milestones
  {
    user: principal,
    path-id: uint,
    milestone-id: uint
  }
  {
    title: (string-ascii 100),
    description: (string-ascii 200),
    target-date: uint,
    completion-status: (string-ascii 20),
    required-skills: (list 5 (string-ascii 50)),
    priority-level: uint,
    completion-date: uint
  }
)

(define-map industry-trends
  (string-ascii 30)
  {
    growth-rate: uint,
    skill-demand: (list 10 (string-ascii 50)),
    average-salary: uint,
    job-availability: uint,
    last-updated: uint
  }
)

(define-map job-market-analysis
  {
    industry: (string-ascii 30),
    role: (string-ascii 50)
  }
  {
    demand-score: uint,
    supply-score: uint,
    growth-projection: uint,
    required-experience: uint,
    skill-gap-analysis: (list 5 (string-ascii 50)),
    market-competitiveness: uint
  }
)

(define-map user-career-profile
  principal
  {
    current-role: (string-ascii 50),
    industry: (string-ascii 30),
    experience-years: uint,
    total-paths: uint,
    active-paths: uint,
    completed-milestones: uint
  }
)

;; Data variables
(define-data-var path-counter uint u0)
(define-data-var milestone-counter uint u0)
(define-data-var total-active-paths uint u0)

;; =======================
;; PUBLIC FUNCTIONS
;; =======================

;; Create a new career path
(define-public (create-career-path
    (title (string-ascii 100))
    (target-role (string-ascii 50))
    (industry (string-ascii 30))
    (timeline-months uint)
  )
  (let
    (
      (new-path-id (+ (var-get path-counter) u1))
      (path-key {user: tx-sender, path-id: new-path-id})
    )
    (asserts! (and (>= timeline-months u1) (<= timeline-months u120)) ERR-INVALID-TIMELINE)
    
    ;; Store career path
    (map-set career-paths
      path-key
      {
        title: title,
        target-role: target-role,
        industry: industry,
        timeline-months: timeline-months,
        status: "active",
        progress-percentage: u0,
        created-at: block-height,
        updated-at: block-height
      }
    )
    
    ;; Update counters
    (var-set path-counter new-path-id)
    (var-set total-active-paths (+ (var-get total-active-paths) u1))
    
    ;; Update user profile
    (update-user-career-profile tx-sender industry)
    
    (ok new-path-id)
  )
)

;; Add milestone to career path
(define-public (add-career-milestone
    (path-id uint)
    (title (string-ascii 100))
    (description (string-ascii 200))
    (target-date uint)
    (required-skills (list 5 (string-ascii 50)))
    (priority-level uint)
  )
  (let
    (
      (new-milestone-id (+ (var-get milestone-counter) u1))
      (milestone-key {user: tx-sender, path-id: path-id, milestone-id: new-milestone-id})
      (path-key {user: tx-sender, path-id: path-id})
    )
    (asserts! (is-some (map-get? career-paths path-key)) ERR-PATH-NOT-FOUND)
    (asserts! (> target-date block-height) ERR-INVALID-TIMELINE)
    (asserts! (and (>= priority-level u1) (<= priority-level MAX-PRIORITY-LEVEL)) ERR-INVALID-PRIORITY)
    
    ;; Store milestone
    (map-set career-milestones
      milestone-key
      {
        title: title,
        description: description,
        target-date: target-date,
        completion-status: "pending",
        required-skills: required-skills,
        priority-level: priority-level,
        completion-date: u0
      }
    )
    
    (var-set milestone-counter new-milestone-id)
    (ok new-milestone-id)
  )
)

;; Complete career milestone
(define-public (complete-milestone
    (path-id uint)
    (milestone-id uint)
  )
  (let
    (
      (milestone-key {user: tx-sender, path-id: path-id, milestone-id: milestone-id})
      (milestone-data (unwrap! (map-get? career-milestones milestone-key) ERR-MILESTONE-NOT-FOUND))
      (path-key {user: tx-sender, path-id: path-id})
      (path-data (unwrap! (map-get? career-paths path-key) ERR-PATH-NOT-FOUND))
    )
    ;; Update milestone completion
    (map-set career-milestones
      milestone-key
      (merge milestone-data {
        completion-status: "completed",
        completion-date: block-height
      })
    )
    
    ;; Update career path progress
    (let
      (
        (new-progress (calculate-path-progress tx-sender path-id))
      )
      (map-set career-paths
        path-key
        (merge path-data {
          progress-percentage: new-progress,
          updated-at: block-height
        })
      )
    )
    
    ;; Update user profile
    (update-completed-milestones tx-sender)
    
    (ok true)
  )
)

;; Update industry trend data (owner only)
(define-public (update-industry-trends
    (industry (string-ascii 30))
    (growth-rate uint)
    (skill-demand (list 10 (string-ascii 50)))
    (average-salary uint)
    (job-availability uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= growth-rate u100) ERR-INVALID-INDUSTRY)
    (asserts! (<= job-availability u100) ERR-INVALID-INDUSTRY)
    
    (map-set industry-trends industry {
      growth-rate: growth-rate,
      skill-demand: skill-demand,
      average-salary: average-salary,
      job-availability: job-availability,
      last-updated: block-height
    })
    
    (ok true)
  )
)

;; Update job market analysis
(define-public (update-job-market
    (industry (string-ascii 30))
    (role (string-ascii 50))
    (demand-score uint)
    (supply-score uint)
    (growth-projection uint)
    (required-experience uint)
    (skill-gap-analysis (list 5 (string-ascii 50)))
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (and (<= demand-score u100) (<= supply-score u100)) ERR-INVALID-INDUSTRY)
    (asserts! (<= growth-projection u100) ERR-INVALID-INDUSTRY)
    
    (map-set job-market-analysis
      {industry: industry, role: role}
      {
        demand-score: demand-score,
        supply-score: supply-score,
        growth-projection: growth-projection,
        required-experience: required-experience,
        skill-gap-analysis: skill-gap-analysis,
        market-competitiveness: (calculate-market-competitiveness demand-score supply-score)
      }
    )
    
    (ok true)
  )
)

;; =======================
;; READ-ONLY FUNCTIONS
;; =======================

;; Get career path details
(define-read-only (get-career-path
    (user principal)
    (path-id uint)
  )
  (map-get? career-paths {user: user, path-id: path-id})
)

;; Get career milestone details
(define-read-only (get-career-milestone
    (user principal)
    (path-id uint)
    (milestone-id uint)
  )
  (map-get? career-milestones {user: user, path-id: path-id, milestone-id: milestone-id})
)

;; Get industry trends
(define-read-only (get-industry-trends (industry (string-ascii 30)))
  (map-get? industry-trends industry)
)

;; Get job market analysis
(define-read-only (get-job-market-data
    (industry (string-ascii 30))
    (role (string-ascii 50))
  )
  (map-get? job-market-analysis {industry: industry, role: role})
)

;; Get user career profile
(define-read-only (get-user-career-profile (user principal))
  (map-get? user-career-profile user)
)

;; Calculate career path progress
(define-read-only (calculate-path-progress
    (user principal)
    (path-id uint)
  )
  ;; Simplified calculation - in real implementation would count completed milestones
  (let
    (
      (path-data (map-get? career-paths {user: user, path-id: path-id}))
    )
    (match path-data
      path-info
        (let
          (
            (months-elapsed (- block-height (get created-at path-info)))
            (total-timeline (get timeline-months path-info))
          )
          (if (>= months-elapsed total-timeline)
            u100
            (/ (* months-elapsed u100) total-timeline)
          )
        )
      u0
    )
  )
)

;; Get career recommendations based on current skills
(define-read-only (get-career-recommendations
    (user principal)
    (current-industry (string-ascii 30))
  )
  (match (map-get? industry-trends current-industry)
    trend-data
      {
        recommended-skills: (get skill-demand trend-data),
        growth-potential: (get growth-rate trend-data),
        market-opportunity: (get job-availability trend-data)
      }
    {
      recommended-skills: (list),
      growth-potential: u0,
      market-opportunity: u0
    }
  )
)

;; Get contract statistics
(define-read-only (get-career-stats)
  {
    total-paths: (var-get path-counter),
    total-milestones: (var-get milestone-counter),
    active-paths: (var-get total-active-paths)
  }
)

;; =======================
;; PRIVATE FUNCTIONS
;; =======================

;; Update user career profile
(define-private (update-user-career-profile (user principal) (industry (string-ascii 30)))
  (let
    (
      (current-data (default-to
        {current-role: "entry-level", industry: industry, experience-years: u0, total-paths: u0, active-paths: u0, completed-milestones: u0}
        (map-get? user-career-profile user)
      ))
    )
    (map-set user-career-profile user
      (merge current-data {
        industry: industry,
        total-paths: (+ (get total-paths current-data) u1),
        active-paths: (+ (get active-paths current-data) u1)
      })
    )
  )
)

;; Update completed milestones count
(define-private (update-completed-milestones (user principal))
  (let
    (
      (current-data (default-to
        {current-role: "entry-level", industry: "general", experience-years: u0, total-paths: u0, active-paths: u0, completed-milestones: u0}
        (map-get? user-career-profile user)
      ))
    )
    (map-set user-career-profile user
      (merge current-data {
        completed-milestones: (+ (get completed-milestones current-data) u1)
      })
    )
  )
)

;; Calculate market competitiveness score
(define-private (calculate-market-competitiveness (demand uint) (supply uint))
  (if (is-eq supply u0)
    u100
    (let
      (
        (ratio (/ (* demand u100) supply))
      )
      (if (> ratio u100) u100 ratio)
    )
  )
)

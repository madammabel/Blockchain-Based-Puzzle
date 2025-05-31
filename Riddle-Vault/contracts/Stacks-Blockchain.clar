;; CryptoQuest - Decentralized Puzzle Platform
;; A comprehensive blockchain-based puzzle ecosystem where creators can publish encrypted challenges
;; and solvers compete for STX rewards through cryptographic proof-of-solution mechanisms.
;; Features include difficulty-based categorization, time-bound challenges, reputation tracking,
;; and a fair economic model with automated reward distribution.

;; Error Constants - Validation and Access Control
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-CHALLENGE-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-COMPLETED (err u102))
(define-constant ERR-INVALID-SOLUTION-PROVIDED (err u103))
(define-constant ERR-INSUFFICIENT-REWARD-AMOUNT (err u104))
(define-constant ERR-CHALLENGE-TIME-EXPIRED (err u105))
(define-constant ERR-INVALID-DIFFICULTY-LEVEL (err u106))
(define-constant ERR-CREATOR-CANNOT-SOLVE-OWN (err u107))
(define-constant ERR-INVALID-DURATION-SPECIFIED (err u108))
(define-constant ERR-NOT-EXPIRED-YET (err u109))
(define-constant ERR-EXCESSIVE-PLATFORM-FEE (err u110))
(define-constant ERR-INVALID-TITLE-LENGTH (err u111))
(define-constant ERR-INVALID-DESCRIPTION-LENGTH (err u112))
(define-constant ERR-INVALID-SOLUTION-LENGTH (err u113))
(define-constant ERR-INVALID-HASH-FORMAT (err u114))
(define-constant ERR-INVALID-AMOUNT (err u115))
(define-constant ERR-INVALID-TAG-FORMAT (err u116))

;; System Constants
(define-constant contract-administrator tx-sender)
(define-constant minimum-stx-reward u1000000) ;; 1 STX base requirement
(define-constant default-platform-commission u5) ;; 5% standard fee
(define-constant maximum-allowed-fee u20) ;; 20% cap on platform fees
(define-constant max-difficulty-rating u5) ;; Difficulty scale 1-5
(define-constant min-difficulty-rating u1)
(define-constant max-duration-blocks u1000000) ;; Maximum challenge duration
(define-constant min-duration-blocks u1) ;; Minimum challenge duration
(define-constant max-title-length u64)
(define-constant max-description-length u256)
(define-constant max-solution-length u256)
(define-constant max-bonus-amount u100000000) ;; 100 STX max bonus

;; Global State Variables
(define-data-var next-challenge-identifier uint u0)
(define-data-var minimum-reward-threshold uint minimum-stx-reward)
(define-data-var platform-commission-rate uint default-platform-commission)

;; Core Data Structures
(define-map cryptoquests 
  uint 
  {
    challenge-creator: principal,
    quest-title: (string-ascii 64),
    detailed-description: (string-ascii 256),
    encrypted-solution-hash: (buff 32),
    stx-reward-pool: uint,
    complexity-rating: uint,
    creation-block-height: uint,
    expiration-block-height: uint,
    completion-status: bool,
    successful-solver: (optional principal),
    completion-block-height: (optional uint)
  }
)

(define-map participant-analytics
  principal
  {
    total-challenges-created: uint,
    total-challenges-solved: uint,
    cumulative-rewards-earned: uint,
    cumulative-rewards-distributed: uint,
    reputation-score: uint
  }
)

(define-map solver-attempt-history
  {challenge-id: uint, participant: principal}
  {
    total-attempts-made: uint,
    most-recent-attempt-block: uint,
    first-attempt-block: uint
  }
)

(define-map challenge-metadata
  uint
  {
    category-tags: (list 5 (string-ascii 20)),
    estimated-solve-time: uint,
    hint-available: bool,
    bonus-multiplier: uint
  }
)

;; Input Validation Functions
(define-private (validate-title (title (string-ascii 64)))
  (let ((title-length (len title)))
    (and (> title-length u0) (<= title-length max-title-length))
  )
)

(define-private (validate-description (description (string-ascii 256)))
  (let ((desc-length (len description)))
    (and (> desc-length u0) (<= desc-length max-description-length))
  )
)

(define-private (validate-solution (solution (string-ascii 256)))
  (let ((solution-length (len solution)))
    (and (> solution-length u0) (<= solution-length max-solution-length))
  )
)

(define-private (validate-hash (hash (buff 32)))
  (is-eq (len hash) u32)
)

(define-private (validate-difficulty (difficulty uint))
  (and (>= difficulty min-difficulty-rating) (<= difficulty max-difficulty-rating))
)

(define-private (validate-duration (duration uint))
  (and (>= duration min-duration-blocks) (<= duration max-duration-blocks))
)

(define-private (validate-amount (amount uint))
  (and (> amount u0) (<= amount max-bonus-amount))
)

(define-private (validate-estimated-time (time uint))
  (<= time u525600) ;; Max 1 year in minutes
)

(define-private (validate-tag-list (tags (list 5 (string-ascii 20))))
  (fold validate-single-tag tags true)
)

(define-private (validate-single-tag (tag (string-ascii 20)) (acc bool))
  (let ((tag-length (len tag)))
    (and acc (> tag-length u0) (<= tag-length u20))
  )
)

;; Query Functions - Read-Only Operations
(define-read-only (get-challenge-details (challenge-identifier uint))
  (map-get? cryptoquests challenge-identifier)
)

(define-read-only (get-current-challenge-count)
  (var-get next-challenge-identifier)
)

(define-read-only (get-participant-profile (user-address principal))
  (default-to 
    {
      total-challenges-created: u0, 
      total-challenges-solved: u0, 
      cumulative-rewards-earned: u0, 
      cumulative-rewards-distributed: u0,
      reputation-score: u0
    }
    (map-get? participant-analytics user-address)
  )
)

(define-read-only (get-solver-statistics (challenge-identifier uint) (solver-address principal))
  (default-to
    {
      total-attempts-made: u0, 
      most-recent-attempt-block: u0,
      first-attempt-block: u0
    }
    (map-get? solver-attempt-history {challenge-id: challenge-identifier, participant: solver-address})
  )
)

(define-read-only (get-platform-commission-percentage)
  (var-get platform-commission-rate)
)

(define-read-only (get-minimum-reward-requirement)
  (var-get minimum-reward-threshold)
)

(define-read-only (check-if-challenge-expired (challenge-identifier uint))
  (match (map-get? cryptoquests challenge-identifier)
    challenge-data 
    (> stacks-block-height (get expiration-block-height challenge-data))
    false
  )
)

(define-read-only (calculate-platform-fee-amount (reward-total uint))
  (/ (* reward-total (var-get platform-commission-rate)) u100)
)

(define-read-only (calculate-solver-reward-amount (total-reward uint))
  (- total-reward (calculate-platform-fee-amount total-reward))
)

(define-read-only (get-challenge-metadata-info (challenge-identifier uint))
  (map-get? challenge-metadata challenge-identifier)
)

;; Internal Helper Functions
(define-private (increment-creator-statistics (creator-address principal))
  (let ((current-participant-data (get-participant-profile creator-address)))
    (map-set participant-analytics creator-address
      (merge current-participant-data 
        {
          total-challenges-created: (+ (get total-challenges-created current-participant-data) u1),
          reputation-score: (+ (get reputation-score current-participant-data) u10)
        }
      )
    )
  )
)

(define-private (increment-solver-statistics (solver-address principal) (reward-amount uint))
  (let ((current-participant-data (get-participant-profile solver-address)))
    (map-set participant-analytics solver-address
      (merge current-participant-data 
        {
          total-challenges-solved: (+ (get total-challenges-solved current-participant-data) u1),
          cumulative-rewards-earned: (+ (get cumulative-rewards-earned current-participant-data) reward-amount),
          reputation-score: (+ (get reputation-score current-participant-data) u25)
        }
      )
    )
  )
)

(define-private (update-creator-payout-statistics (creator-address principal) (payout-amount uint))
  (let ((current-participant-data (get-participant-profile creator-address)))
    (map-set participant-analytics creator-address
      (merge current-participant-data 
        {
          cumulative-rewards-distributed: (+ (get cumulative-rewards-distributed current-participant-data) payout-amount)
        }
      )
    )
  )
)

(define-private (record-solution-attempt (challenge-identifier uint) (solver-address principal))
  (let ((existing-attempt-data (get-solver-statistics challenge-identifier solver-address)))
    (map-set solver-attempt-history 
      {challenge-id: challenge-identifier, participant: solver-address}
      {
        total-attempts-made: (+ (get total-attempts-made existing-attempt-data) u1),
        most-recent-attempt-block: stacks-block-height,
        first-attempt-block: (if (is-eq (get first-attempt-block existing-attempt-data) u0) 
                               stacks-block-height 
                               (get first-attempt-block existing-attempt-data))
      }
    )
  )
)

(define-private (validate-challenge-parameters (difficulty-level uint) (duration-in-blocks uint) (reward-stx uint))
  (begin
    (asserts! (validate-difficulty difficulty-level) ERR-INVALID-DIFFICULTY-LEVEL)
    (asserts! (validate-duration duration-in-blocks) ERR-INVALID-DURATION-SPECIFIED)
    (asserts! (>= reward-stx (var-get minimum-reward-threshold)) ERR-INSUFFICIENT-REWARD-AMOUNT)
    (ok true)
  )
)

(define-private (validate-solution-attempt (challenge-identifier uint) (challenge-data {challenge-creator: principal, quest-title: (string-ascii 64), detailed-description: (string-ascii 256), encrypted-solution-hash: (buff 32), stx-reward-pool: uint, complexity-rating: uint, creation-block-height: uint, expiration-block-height: uint, completion-status: bool, successful-solver: (optional principal), completion-block-height: (optional uint)}) (provided-solution-hash (buff 32)))
  (begin
    (asserts! (not (get completion-status challenge-data)) ERR-ALREADY-COMPLETED)
    (asserts! (<= stacks-block-height (get expiration-block-height challenge-data)) ERR-CHALLENGE-TIME-EXPIRED)
    (asserts! (is-eq provided-solution-hash (get encrypted-solution-hash challenge-data)) ERR-INVALID-SOLUTION-PROVIDED)
    (asserts! (not (is-eq tx-sender (get challenge-creator challenge-data))) ERR-CREATOR-CANNOT-SOLVE-OWN)
    (ok true)
  )
)

(define-private (sanitize-and-validate-inputs 
  (title (string-ascii 64))
  (description (string-ascii 256))
  (hash (buff 32))
  (difficulty uint)
  (duration uint)
  (tags (list 5 (string-ascii 20)))
  (solve-time uint)
)
  (begin
    (asserts! (validate-title title) ERR-INVALID-TITLE-LENGTH)
    (asserts! (validate-description description) ERR-INVALID-DESCRIPTION-LENGTH)
    (asserts! (validate-hash hash) ERR-INVALID-HASH-FORMAT)
    (asserts! (validate-difficulty difficulty) ERR-INVALID-DIFFICULTY-LEVEL)
    (asserts! (validate-duration duration) ERR-INVALID-DURATION-SPECIFIED)
    (asserts! (validate-tag-list tags) ERR-INVALID-TAG-FORMAT)
    (asserts! (validate-estimated-time solve-time) ERR-INVALID-DURATION-SPECIFIED)
    (ok true)
  )
)

;; Primary Public Functions
(define-public (publish-cryptoquest 
  (quest-title (string-ascii 64))
  (detailed-description (string-ascii 256))
  (encrypted-solution-hash (buff 32))
  (complexity-rating uint)
  (duration-in-blocks uint)
  (category-tags (list 5 (string-ascii 20)))
  (estimated-solve-time uint)
)
  (let 
    (
      (new-challenge-id (+ (var-get next-challenge-identifier) u1))
      (creator-stx-balance (stx-get-balance tx-sender))
    )
    ;; Comprehensive input validation and sanitization
    (try! (sanitize-and-validate-inputs quest-title detailed-description encrypted-solution-hash complexity-rating duration-in-blocks category-tags estimated-solve-time))
    (try! (validate-challenge-parameters complexity-rating duration-in-blocks creator-stx-balance))
    
    ;; Secure STX transfer to contract for reward escrow
    (try! (stx-transfer? creator-stx-balance tx-sender (as-contract tx-sender)))
    
    ;; Create new cryptoquest entry with validated inputs
    (map-set cryptoquests new-challenge-id
      {
        challenge-creator: tx-sender,
        quest-title: quest-title,
        detailed-description: detailed-description,
        encrypted-solution-hash: encrypted-solution-hash,
        stx-reward-pool: creator-stx-balance,
        complexity-rating: complexity-rating,
        creation-block-height: stacks-block-height,
        expiration-block-height: (+ stacks-block-height duration-in-blocks),
        completion-status: false,
        successful-solver: none,
        completion-block-height: none
      }
    )
    
    ;; Store additional metadata with validated inputs
    (map-set challenge-metadata new-challenge-id
      {
        category-tags: category-tags,
        estimated-solve-time: estimated-solve-time,
        hint-available: false,
        bonus-multiplier: u100
      }
    )
    
    ;; Update global state and creator analytics
    (var-set next-challenge-identifier new-challenge-id)
    (increment-creator-statistics tx-sender)
    
    (ok new-challenge-id)
  )
)

(define-public (attempt-solution (challenge-identifier uint) (provided-solution (string-ascii 256)))
  (let 
    (
      (challenge-data (unwrap! (map-get? cryptoquests challenge-identifier) ERR-CHALLENGE-NOT-FOUND))
      (computed-solution-hash (sha256 (unwrap-panic (to-consensus-buff? provided-solution))))
    )
    ;; Validate inputs
    (asserts! (> challenge-identifier u0) ERR-CHALLENGE-NOT-FOUND)
    (asserts! (validate-solution provided-solution) ERR-INVALID-SOLUTION-LENGTH)
    
    ;; Comprehensive solution validation
    (try! (validate-solution-attempt challenge-identifier challenge-data computed-solution-hash))
    
    ;; Record this attempt for analytics
    (record-solution-attempt challenge-identifier tx-sender)
    
    ;; Process successful solution and reward distribution
    (let 
      (
        (total-reward-pool (get stx-reward-pool challenge-data))
        (platform-fee-amount (calculate-platform-fee-amount total-reward-pool))
        (solver-reward-amount (calculate-solver-reward-amount total-reward-pool))
      )
      
      ;; Execute reward transfers with validated amounts
      (try! (as-contract (stx-transfer? solver-reward-amount tx-sender tx-sender)))
      (try! (as-contract (stx-transfer? platform-fee-amount tx-sender contract-administrator)))
      
      ;; Update challenge completion status
      (map-set cryptoquests challenge-identifier
        (merge challenge-data
          {
            completion-status: true,
            successful-solver: (some tx-sender),
            completion-block-height: (some stacks-block-height)
          }
        )
      )
      
      ;; Update participant analytics
      (increment-solver-statistics tx-sender solver-reward-amount)
      (update-creator-payout-statistics (get challenge-creator challenge-data) total-reward-pool)
      
      (ok solver-reward-amount)
    )
  )
)

(define-public (reclaim-expired-cryptoquest (challenge-identifier uint))
  (let ((challenge-data (unwrap! (map-get? cryptoquests challenge-identifier) ERR-CHALLENGE-NOT-FOUND)))
    ;; Validate challenge identifier
    (asserts! (> challenge-identifier u0) ERR-CHALLENGE-NOT-FOUND)
    
    ;; Validate reclaim eligibility
    (asserts! (is-eq tx-sender (get challenge-creator challenge-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (get completion-status challenge-data)) ERR-ALREADY-COMPLETED)
    (asserts! (> stacks-block-height (get expiration-block-height challenge-data)) ERR-NOT-EXPIRED-YET)
    
    ;; Return escrowed reward to original creator
    (try! (as-contract (stx-transfer? (get stx-reward-pool challenge-data) tx-sender (get challenge-creator challenge-data))))
    
    ;; Mark challenge as reclaimed
    (map-set cryptoquests challenge-identifier
      (merge challenge-data {stx-reward-pool: u0})
    )
    
    (ok (get stx-reward-pool challenge-data))
  )
)

(define-public (provide-creator-bonus (challenge-identifier uint) (bonus-amount uint))
  (let ((challenge-data (unwrap! (map-get? cryptoquests challenge-identifier) ERR-CHALLENGE-NOT-FOUND)))
    ;; Validate inputs
    (asserts! (> challenge-identifier u0) ERR-CHALLENGE-NOT-FOUND)
    (asserts! (validate-amount bonus-amount) ERR-INVALID-AMOUNT)
    
    (try! (stx-transfer? bonus-amount tx-sender (get challenge-creator challenge-data)))
    
    ;; Update creator statistics
    (update-creator-payout-statistics (get challenge-creator challenge-data) bonus-amount)
    
    (ok true)
  )
)

;; Administrative Control Functions
(define-public (adjust-minimum-reward-threshold (new-minimum-threshold uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-amount new-minimum-threshold) ERR-INVALID-AMOUNT)
    (var-set minimum-reward-threshold new-minimum-threshold)
    (ok true)
  )
)

(define-public (modify-platform-commission-rate (new-commission-percentage uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (<= new-commission-percentage maximum-allowed-fee) ERR-EXCESSIVE-PLATFORM-FEE)
    (var-set platform-commission-rate new-commission-percentage)
    (ok true)
  )
)

(define-public (emergency-contract-withdrawal (withdrawal-amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-administrator) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (validate-amount withdrawal-amount) ERR-INVALID-AMOUNT)
    (try! (as-contract (stx-transfer? withdrawal-amount tx-sender contract-administrator)))
    (ok true)
  )
)

;; Enhanced Utility Functions
(define-public (batch-challenge-query (challenge-ids (list 10 uint)))
  (ok (map get-challenge-details challenge-ids))
)

(define-public (update-challenge-metadata 
  (challenge-identifier uint) 
  (new-tags (list 5 (string-ascii 20)))
  (hint-enabled bool)
)
  (let ((challenge-data (unwrap! (map-get? cryptoquests challenge-identifier) ERR-CHALLENGE-NOT-FOUND)))
    ;; Validate inputs
    (asserts! (> challenge-identifier u0) ERR-CHALLENGE-NOT-FOUND)
    (asserts! (validate-tag-list new-tags) ERR-INVALID-TAG-FORMAT)
    
    (asserts! (is-eq tx-sender (get challenge-creator challenge-data)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (get completion-status challenge-data)) ERR-ALREADY-COMPLETED)
    
    (map-set challenge-metadata challenge-identifier
      {
        category-tags: new-tags,
        estimated-solve-time: u0,
        hint-available: hint-enabled,
        bonus-multiplier: u100
      }
    )
    (ok true)
  )
)
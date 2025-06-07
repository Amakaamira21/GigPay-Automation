;; Freelance Work and Payment Automation Smart Contract
;; Written in Clarinet for Stacks blockchain

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_CONTRACT_NOT_FOUND (err u101))
(define-constant ERR_INVALID_STATUS (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_MILESTONE_NOT_FOUND (err u104))
(define-constant ERR_ALREADY_COMPLETED (err u105))
(define-constant ERR_NOT_CLIENT (err u106))
(define-constant ERR_NOT_FREELANCER (err u107))

;; Data structures
(define-map contracts
  { contract-id: uint }
  {
    client: principal,
    freelancer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    total-amount: uint,
    status: (string-ascii 20), ;; "active", "completed", "disputed", "cancelled"
    deadline: uint
  }
)

(define-map milestones
  { contract-id: uint, milestone-id: uint }
  {
    description: (string-ascii 200),
    amount: uint,
    status: (string-ascii 20), ;; "pending", "submitted", "approved", "paid"
    due-date: uint
  }
)

(define-map contract-funds
  { contract-id: uint }
  { escrowed-amount: uint }
)

(define-map ratings
  { contract-id: uint, rater: principal }
  {
    rating: uint, ;; 1-5 stars
    review: (string-ascii 300)
  }
)

;; Data variables
(define-data-var next-contract-id uint u1)
(define-data-var platform-fee-percentage uint u250) ;; 2.5% = 250 basis points

;; Read-only functions
(define-read-only (get-contract (contract-id uint))
  (map-get? contracts { contract-id: contract-id })
)

(define-read-only (get-milestone (contract-id uint) (milestone-id uint))
  (map-get? milestones { contract-id: contract-id, milestone-id: milestone-id })
)

(define-read-only (get-contract-funds (contract-id uint))
  (map-get? contract-funds { contract-id: contract-id })
)

(define-read-only (get-rating (contract-id uint) (rater principal))
  (map-get? ratings { contract-id: contract-id, rater: rater })
)

(define-read-only (calculate-platform-fee (amount uint))
  (/ (* amount (var-get platform-fee-percentage)) u10000)
)

;; Public functions

;; Create a new freelance contract
(define-public (create-contract 
  (freelancer principal)
  (title (string-ascii 100))
  (description (string-ascii 500))
  (total-amount uint)
  (deadline uint))
  (let
    (
      (contract-id (var-get next-contract-id))
    )
    (try! (stx-transfer? total-amount tx-sender (as-contract tx-sender)))
    (map-set contracts
      { contract-id: contract-id }
      {
        client: tx-sender,
        freelancer: freelancer,
        title: title,
        description: description,
        total-amount: total-amount,
        status: "active",
        deadline: deadline
      }
    )
    (map-set contract-funds
      { contract-id: contract-id }
      { escrowed-amount: total-amount }
    )
    (var-set next-contract-id (+ contract-id u1))
    (ok contract-id)
  )
)

;; Add milestone to contract
(define-public (add-milestone
  (contract-id uint)
  (milestone-id uint)
  (description (string-ascii 200))
  (amount uint)
  (due-date uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get client contract)) ERR_NOT_CLIENT)
    (asserts! (is-eq (get status contract) "active") ERR_INVALID_STATUS)
    (map-set milestones
      { contract-id: contract-id, milestone-id: milestone-id }
      {
        description: description,
        amount: amount,
        status: "pending",
        due-date: due-date
      }
    )
    (ok true)
  )
)

;; Submit milestone work
(define-public (submit-milestone (contract-id uint) (milestone-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
      (milestone (unwrap! (get-milestone contract-id milestone-id) ERR_MILESTONE_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get freelancer contract)) ERR_NOT_FREELANCER)
    (asserts! (is-eq (get status milestone) "pending") ERR_INVALID_STATUS)
    (map-set milestones
      { contract-id: contract-id, milestone-id: milestone-id }
      (merge milestone { status: "submitted" })
    )
    (ok true)
  )
)

;; Approve milestone and trigger payment
(define-public (approve-milestone (contract-id uint) (milestone-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
      (milestone (unwrap! (get-milestone contract-id milestone-id) ERR_MILESTONE_NOT_FOUND))
      (funds (unwrap! (get-contract-funds contract-id) ERR_CONTRACT_NOT_FOUND))
      (milestone-amount (get amount milestone))
      (platform-fee (calculate-platform-fee milestone-amount))
      (freelancer-payment (- milestone-amount platform-fee))
    )
    (asserts! (is-eq tx-sender (get client contract)) ERR_NOT_CLIENT)
    (asserts! (is-eq (get status milestone) "submitted") ERR_INVALID_STATUS)
    (asserts! (>= (get escrowed-amount funds) milestone-amount) ERR_INSUFFICIENT_FUNDS)
    
    ;; Transfer payment to freelancer
    (try! (as-contract (stx-transfer? freelancer-payment tx-sender (get freelancer contract))))
    
    ;; Transfer platform fee to contract owner
    (try! (as-contract (stx-transfer? platform-fee tx-sender CONTRACT_OWNER)))
    
    ;; Update milestone status
    (map-set milestones
      { contract-id: contract-id, milestone-id: milestone-id }
      (merge milestone { status: "paid" })
    )
    
    ;; Update escrowed funds
    (map-set contract-funds
      { contract-id: contract-id }
      { escrowed-amount: (- (get escrowed-amount funds) milestone-amount) }
    )
    
    (ok true)
  )
)

;; Complete contract
(define-public (complete-contract (contract-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
      (funds (unwrap! (get-contract-funds contract-id) ERR_CONTRACT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get client contract)) ERR_NOT_CLIENT)
    (asserts! (is-eq (get status contract) "active") ERR_INVALID_STATUS)
    
    ;; Return any remaining funds to client
    (if (> (get escrowed-amount funds) u0)
      (try! (as-contract (stx-transfer? (get escrowed-amount funds) tx-sender (get client contract))))
      true
    )
    
    ;; Update contract status
    (map-set contracts
      { contract-id: contract-id }
      (merge contract { status: "completed" })
    )
    
    ;; Clear escrowed funds
    (map-set contract-funds
      { contract-id: contract-id }
      { escrowed-amount: u0 }
    )
    
    (ok true)
  )
)

;; Cancel contract (only if no milestones are paid)
(define-public (cancel-contract (contract-id uint))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
      (funds (unwrap! (get-contract-funds contract-id) ERR_CONTRACT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender (get client contract)) ERR_NOT_CLIENT)
    (asserts! (is-eq (get status contract) "active") ERR_INVALID_STATUS)
    
    ;; Return escrowed funds to client
    (try! (as-contract (stx-transfer? (get escrowed-amount funds) tx-sender (get client contract))))
    
    ;; Update contract status
    (map-set contracts
      { contract-id: contract-id }
      (merge contract { status: "cancelled" })
    )
    
    ;; Clear escrowed funds
    (map-set contract-funds
      { contract-id: contract-id }
      { escrowed-amount: u0 }
    )
    
    (ok true)
  )
)

;; Submit rating and review
(define-public (submit-rating
  (contract-id uint)
  (rating uint)
  (review (string-ascii 300)))
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
    )
    (asserts! (is-eq (get status contract) "completed") ERR_INVALID_STATUS)
    (asserts! (and (>= rating u1) (<= rating u5)) (err u108))
    (asserts! (or (is-eq tx-sender (get client contract)) 
                  (is-eq tx-sender (get freelancer contract))) ERR_NOT_AUTHORIZED)
    
    (map-set ratings
      { contract-id: contract-id, rater: tx-sender }
      {
        rating: rating,
        review: review
      }
    )
    (ok true)
  )
)

;; Emergency functions (only contract owner)
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-fee u1000) (err u109)) ;; Max 10%
    (var-set platform-fee-percentage new-fee)
    (ok true)
  )
)

;; Dispute resolution (simplified - in practice would involve oracles)
(define-public (resolve-dispute 
  (contract-id uint) 
  (resolution (string-ascii 20))) ;; "client" or "freelancer"
  (let
    (
      (contract (unwrap! (get-contract contract-id) ERR_CONTRACT_NOT_FOUND))
      (funds (unwrap! (get-contract-funds contract-id) ERR_CONTRACT_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get status contract) "disputed") ERR_INVALID_STATUS)
    
    (if (is-eq resolution "client")
      ;; Refund to client
      (try! (as-contract (stx-transfer? (get escrowed-amount funds) tx-sender (get client contract))))
      ;; Pay freelancer
      (try! (as-contract (stx-transfer? (get escrowed-amount funds) tx-sender (get freelancer contract))))
    )
    
    ;; Update contract status
    (map-set contracts
      { contract-id: contract-id }
      (merge contract { status: "completed" })
    )
    
    ;; Clear funds
    (map-set contract-funds
      { contract-id: contract-id }
      { escrowed-amount: u0 }
    )
    
    (ok true)
  )
)
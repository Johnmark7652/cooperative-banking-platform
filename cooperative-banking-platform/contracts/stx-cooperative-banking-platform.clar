;; Cooperative Banking Platform Smart Contract
;; A decentralized banking system for cooperative financial services

;; Error codes
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-ACCOUNT-NOT-FOUND (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-LOAN-NOT-FOUND (err u104))
(define-constant ERR-LOAN-ALREADY-APPROVED (err u105))
(define-constant ERR-MINIMUM-BALANCE-REQUIRED (err u106))
(define-constant ERR-MEMBER-NOT-FOUND (err u107))
(define-constant ERR-ALREADY-MEMBER (err u108))
(define-constant ERR-INVALID-LOAN-TERM (err u109))
(define-constant ERR-LOAN-OVERDUE (err u110))

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MINIMUM-BALANCE u100000) ;; 0.1 STX minimum
(define-constant MAX-LOAN-TERM u365) ;; 365 blocks (about 1 year)
(define-constant INTEREST-RATE u5) ;; 5% annual interest
(define-constant PLATFORM-FEE-RATE u1) ;; 1% platform fee

;; Helper functions
(define-private (min (a uint) (b uint))
    (if (< a b) a b)
)

(define-private (max (a uint) (b uint))
    (if (> a b) a b)
)

;; Data structures
(define-map members 
    principal 
    {
        balance: uint,
        join-date: uint,
        total-deposits: uint,
        total-withdrawals: uint,
        credit-score: uint,
        is-active: bool
    }
)

(define-map loans
    uint
    {
        borrower: principal,
        amount: uint,
        interest-rate: uint,
        term-blocks: uint,
        start-block: uint,
        status: (string-ascii 20),
        collateral: uint,
        monthly-payment: uint
    }
)

(define-map transactions
    uint
    {
        from: principal,
        to: (optional principal),
        amount: uint,
        transaction-type: (string-ascii 20),
        timestamp: uint,
        description: (string-ascii 100)
    }
)

(define-map savings-goals
    {member: principal, goal-id: uint}
    {
        target-amount: uint,
        current-amount: uint,
        target-date: uint,
        description: (string-ascii 100),
        is-completed: bool
    }
)

;; Global variables
(define-data-var next-loan-id uint u1)
(define-data-var next-transaction-id uint u1)
(define-data-var total-deposits uint u0)
(define-data-var total-loans uint u0)
(define-data-var platform-reserves uint u0)

;; Member Management Functions

;; Join the cooperative
(define-public (join-cooperative)
    (let ((member-exists (map-get? members tx-sender)))
        (asserts! (is-none member-exists) ERR-ALREADY-MEMBER)
        (map-set members tx-sender {
            balance: u0,
            join-date: stacks-block-height,
            total-deposits: u0,
            total-withdrawals: u0,
            credit-score: u500, ;; Starting credit score
            is-active: true
        })
        (ok true)
    )
)

;; Deposit funds
(define-public (deposit (amount uint))
    (let ((member-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND)))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        
        (map-set members tx-sender {
            balance: (+ (get balance member-data) amount),
            join-date: (get join-date member-data),
            total-deposits: (+ (get total-deposits member-data) amount),
            total-withdrawals: (get total-withdrawals member-data),
            credit-score: (min u1000 (+ (get credit-score member-data) u1)),
            is-active: (get is-active member-data)
        })
        
        (var-set total-deposits (+ (var-get total-deposits) amount))
        (record-transaction tx-sender none amount "DEPOSIT" "Member deposit")
        (ok amount)
    )
)

;; Withdraw funds
(define-public (withdraw (amount uint))
    (let ((member-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND)))
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (get balance member-data) amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (>= (- (get balance member-data) amount) MINIMUM-BALANCE) ERR-MINIMUM-BALANCE-REQUIRED)
        
        (try! (as-contract (stx-transfer? amount tx-sender tx-sender)))
        
        (map-set members tx-sender {
            balance: (- (get balance member-data) amount),
            join-date: (get join-date member-data),
            total-deposits: (get total-deposits member-data),
            total-withdrawals: (+ (get total-withdrawals member-data) amount),
            credit-score: (get credit-score member-data),
            is-active: (get is-active member-data)
        })
        
        (record-transaction tx-sender none amount "WITHDRAWAL" "Member withdrawal")
        (ok amount)
    )
)

;; Transfer funds between members
(define-public (transfer (recipient principal) (amount uint))
    (let (
        (sender-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND))
        (recipient-data (unwrap! (map-get? members recipient) ERR-MEMBER-NOT-FOUND))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (get balance sender-data) amount) ERR-INSUFFICIENT-BALANCE)
        (asserts! (get is-active recipient-data) ERR-UNAUTHORIZED)
        
        ;; Update sender balance
        (map-set members tx-sender {
            balance: (- (get balance sender-data) amount),
            join-date: (get join-date sender-data),
            total-deposits: (get total-deposits sender-data),
            total-withdrawals: (get total-withdrawals sender-data),
            credit-score: (get credit-score sender-data),
            is-active: (get is-active sender-data)
        })
        
        ;; Update recipient balance
        (map-set members recipient {
            balance: (+ (get balance recipient-data) amount),
            join-date: (get join-date recipient-data),
            total-deposits: (get total-deposits recipient-data),
            total-withdrawals: (get total-withdrawals recipient-data),
            credit-score: (get credit-score recipient-data),
            is-active: (get is-active recipient-data)
        })
        
        (record-transaction tx-sender (some recipient) amount "TRANSFER" "Member to member transfer")
        (ok amount)
    )
)

;; Loan Management Functions

;; Apply for a loan
(define-public (apply-for-loan (amount uint) (term-blocks uint) (collateral uint))
    (let (
        (member-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND))
        (loan-id (var-get next-loan-id))
        (monthly-payment (calculate-monthly-payment amount term-blocks))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (<= term-blocks MAX-LOAN-TERM) ERR-INVALID-LOAN-TERM)
        (asserts! (>= (get credit-score member-data) u400) ERR-UNAUTHORIZED)
        (asserts! (>= collateral (/ (* amount u50) u100)) ERR-INSUFFICIENT-BALANCE) ;; 50% collateral required
        
        (map-set loans loan-id {
            borrower: tx-sender,
            amount: amount,
            interest-rate: INTEREST-RATE,
            term-blocks: term-blocks,
            start-block: u0,
            status: "PENDING",
            collateral: collateral,
            monthly-payment: monthly-payment
        })
        
        (var-set next-loan-id (+ loan-id u1))
        (ok loan-id)
    )
)

;; Approve loan (only contract owner can approve)
(define-public (approve-loan (loan-id uint))
    (let ((loan-data (unwrap! (map-get? loans loan-id) ERR-LOAN-NOT-FOUND)))
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status loan-data) "PENDING") ERR-LOAN-ALREADY-APPROVED)
        
        (map-set loans loan-id {
            borrower: (get borrower loan-data),
            amount: (get amount loan-data),
            interest-rate: (get interest-rate loan-data),
            term-blocks: (get term-blocks loan-data),
            start-block: stacks-block-height,
            status: "APPROVED",
            collateral: (get collateral loan-data),
            monthly-payment: (get monthly-payment loan-data)
        })
        
        ;; Transfer loan amount to borrower
        (try! (as-contract (stx-transfer? (get amount loan-data) tx-sender (get borrower loan-data))))
        (var-set total-loans (+ (var-get total-loans) (get amount loan-data)))
        
        (record-transaction (as-contract tx-sender) (some (get borrower loan-data)) (get amount loan-data) "LOAN_DISBURSEMENT" "Loan approved and disbursed")
        (ok true)
    )
)

;; Make loan payment
(define-public (make-loan-payment (loan-id uint) (payment-amount uint))
    (let ((loan-data (unwrap! (map-get? loans loan-id) ERR-LOAN-NOT-FOUND)))
        (asserts! (is-eq tx-sender (get borrower loan-data)) ERR-UNAUTHORIZED)
        (asserts! (is-eq (get status loan-data) "APPROVED") ERR-UNAUTHORIZED)
        (asserts! (> payment-amount u0) ERR-INVALID-AMOUNT)
        
        (try! (stx-transfer? payment-amount tx-sender (as-contract tx-sender)))
        
        ;; Calculate platform fee
        (let ((platform-fee (/ (* payment-amount PLATFORM-FEE-RATE) u100)))
            (var-set platform-reserves (+ (var-get platform-reserves) platform-fee))
        )
        
        (record-transaction tx-sender none payment-amount "LOAN_PAYMENT" "Loan payment made")
        (ok payment-amount)
    )
)

;; Savings Goals Functions

;; Create savings goal
(define-public (create-savings-goal (goal-id uint) (target-amount uint) (target-date uint) (description (string-ascii 100)))
    (let ((member-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND)))
        (asserts! (> target-amount u0) ERR-INVALID-AMOUNT)
        (asserts! (> target-date stacks-block-height) ERR-INVALID-AMOUNT)
        
        (map-set savings-goals {member: tx-sender, goal-id: goal-id} {
            target-amount: target-amount,
            current-amount: u0,
            target-date: target-date,
            description: description,
            is-completed: false
        })
        
        (ok goal-id)
    )
)

;; Add to savings goal
(define-public (add-to-savings-goal (goal-id uint) (amount uint))
    (let (
        (member-data (unwrap! (map-get? members tx-sender) ERR-MEMBER-NOT-FOUND))
        (goal-data (unwrap! (map-get? savings-goals {member: tx-sender, goal-id: goal-id}) ERR-ACCOUNT-NOT-FOUND))
    )
        (asserts! (> amount u0) ERR-INVALID-AMOUNT)
        (asserts! (>= (get balance member-data) amount) ERR-INSUFFICIENT-BALANCE)
        
        (let ((new-amount (+ (get current-amount goal-data) amount)))
            ;; Update member balance
            (map-set members tx-sender {
                balance: (- (get balance member-data) amount),
                join-date: (get join-date member-data),
                total-deposits: (get total-deposits member-data),
                total-withdrawals: (get total-withdrawals member-data),
                credit-score: (get credit-score member-data),
                is-active: (get is-active member-data)
            })
            
            ;; Update savings goal
            (map-set savings-goals {member: tx-sender, goal-id: goal-id} {
                target-amount: (get target-amount goal-data),
                current-amount: new-amount,
                target-date: (get target-date goal-data),
                description: (get description goal-data),
                is-completed: (>= new-amount (get target-amount goal-data))
            })
            
            (record-transaction tx-sender none amount "SAVINGS_DEPOSIT" "Added to savings goal")
            (ok new-amount)
        )
    )
)

;; Utility Functions

;; Calculate monthly payment for loan (simplified version)
(define-private (calculate-monthly-payment (principal uint) (term-blocks uint))
    (let (
        (monthly-blocks (if (> term-blocks u30) (/ term-blocks u30) u1))
        (total-interest (/ (* principal INTEREST-RATE) u100))
        (total-amount (+ principal total-interest))
    )
        (/ total-amount monthly-blocks)
    )
)

;; Record transaction
(define-private (record-transaction (from principal) (to (optional principal)) (amount uint) (tx-type (string-ascii 20)) (description (string-ascii 100)))
    (let ((tx-id (var-get next-transaction-id)))
        (map-set transactions tx-id {
            from: from,
            to: to,
            amount: amount,
            transaction-type: tx-type,
            timestamp: stacks-block-height,
            description: description
        })
        (var-set next-transaction-id (+ tx-id u1))
        tx-id
    )
)

;; Read-only functions

;; Get member information
(define-read-only (get-member-info (member principal))
    (map-get? members member)
)

;; Get loan information
(define-read-only (get-loan-info (loan-id uint))
    (map-get? loans loan-id)
)

;; Get transaction information
(define-read-only (get-transaction (tx-id uint))
    (map-get? transactions tx-id)
)

;; Get savings goal information
(define-read-only (get-savings-goal (member principal) (goal-id uint))
    (map-get? savings-goals {member: member, goal-id: goal-id})
)

;; Get platform statistics
(define-read-only (get-platform-stats)
    (ok {
        total-deposits: (var-get total-deposits),
        total-loans: (var-get total-loans),
        platform-reserves: (var-get platform-reserves),
        next-loan-id: (var-get next-loan-id),
        next-transaction-id: (var-get next-transaction-id)
    })
)

;; Calculate member credit score based on activity
(define-read-only (calculate-credit-score (member principal))
    (match (map-get? members member)
        member-data
        (let (
            (base-score u500)
            (deposit-bonus (min u200 (/ (get total-deposits member-data) u10000)))
            (activity-bonus (if (> (get total-deposits member-data) (get total-withdrawals member-data)) u50 u0))
            (time-bonus (min u100 (/ (- stacks-block-height (get join-date member-data)) u1000)))
        )
            (+ base-score deposit-bonus activity-bonus time-bonus)
        )
        u0
    )
)

;; Administrative functions (only contract owner)

;; Update platform fee rate
(define-public (update-platform-fee-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (<= new-rate u10) ERR-INVALID-AMOUNT) ;; Max 10% fee
        ;; Note: In production, you'd use a data-var for platform-fee-rate
        (ok new-rate)
    )
)

;; Withdraw platform reserves
(define-public (withdraw-platform-reserves (amount uint))
    (begin
        (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
        (asserts! (<= amount (var-get platform-reserves)) ERR-INSUFFICIENT-BALANCE)
        
        (try! (as-contract (stx-transfer? amount tx-sender CONTRACT-OWNER)))
        (var-set platform-reserves (- (var-get platform-reserves) amount))
        
        (record-transaction (as-contract tx-sender) (some CONTRACT-OWNER) amount "ADMIN_WITHDRAWAL" "Platform reserves withdrawal")
        (ok amount)
    )
)
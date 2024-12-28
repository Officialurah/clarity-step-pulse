;; Define token
(define-fungible-token step-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-registered (err u101))
(define-constant err-already-claimed-today (err u102))
(define-constant err-goal-not-met (err u103))
(define-constant tokens-per-goal u10) ;; 10 tokens per completed goal

;; Data structures
(define-map users
    principal
    {
        daily-goal: uint,
        last-claim: uint,
        total-goals-met: uint
    }
)

(define-map daily-steps
    {user: principal, day: uint}
    uint
)

;; Public functions
(define-public (register (daily-goal uint))
    (ok (map-set users tx-sender {
        daily-goal: daily-goal,
        last-claim: u0,
        total-goals-met: u0
    }))
)

(define-public (log-steps (step-count uint) (day uint))
    (begin
        (asserts! (is-some (map-get? users tx-sender)) err-not-registered)
        (ok (map-set daily-steps {user: tx-sender, day: day} step-count))
    )
)

(define-public (claim-reward (day uint))
    (let (
        (user-data (unwrap! (map-get? users tx-sender) err-not-registered))
        (steps (unwrap! (map-get? daily-steps {user: tx-sender, day: day}) err-not-registered))
    )
    (asserts! (not (is-eq (get last-claim user-data) day)) err-already-claimed-today)
    (asserts! (>= steps (get daily-goal user-data)) err-goal-not-met)
    (try! (ft-mint? step-token tokens-per-goal tx-sender))
    (map-set users tx-sender (merge user-data {
        last-claim: day,
        total-goals-met: (+ (get total-goals-met user-data) u1)
    }))
    (ok true))
)

;; Read only functions
(define-read-only (get-user-data (user principal))
    (map-get? users user)
)

(define-read-only (get-steps (user principal) (day uint))
    (map-get? daily-steps {user: user, day: day})
)

(define-read-only (get-balance (account principal))
    (ok (ft-get-balance step-token account))
)

;; Admin functions
(define-public (update-reward-rate (new-rate uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok true)
    )
)
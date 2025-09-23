;; TITLE: TrustLayer Protocol - Decentralized Trust Management System
;;
;; SUMMARY: A revolutionary Bitcoin-native smart contract protocol built on Stacks that
;; establishes a decentralized trust infrastructure for the Bitcoin economy. TrustLayer
;; enables verifiable reputation scoring, temporal decay mechanisms, and cross-platform
;; trust verification while maintaining Bitcoin's security guarantees.
;;
;; DESCRIPTION: The TrustLayer Protocol represents a paradigm shift in decentralized
;; trust management, leveraging Bitcoin's immutable security through Stacks smart contracts.
;; This protocol provides comprehensive trust infrastructure including:

;; ERROR CONSTANTS
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-PARAMETERS (err u101))
(define-constant ERR-IDENTITY-EXISTS (err u102))
(define-constant ERR-IDENTITY-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-REPUTATION (err u104))
(define-constant ERR-NOT-ADMIN (err u105))

;; SYSTEM CONSTANTS
(define-constant MAX-REPUTATION u1000)
(define-constant MIN-REPUTATION u0)
(define-constant DEFAULT-REPUTATION u50)
(define-constant DECAY-RATE u10) ;; 10% decay rate
(define-constant DECAY-PERIOD u10000) ;; blocks between decay

;; STATE VARIABLES
(define-data-var admin principal tx-sender)
(define-data-var active bool true)
(define-data-var total-users uint u0)

;; CORE DATA STRUCTURES
;; Identity registry
(define-map identities
  { owner: principal }
  {
    reputation: uint,
    created-at: uint,
    last-updated: uint,
    last-decay: uint,
    active: bool,
  }
)

;; Trust actions configuration
(define-map trust-actions
  { action: (string-ascii 50) }
  {
    points: uint,
    active: bool,
  }
)

;; ADMIN FUNCTIONS
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
    (var-set admin new-admin)
    (ok true)
  )
)

(define-public (set-active (status bool))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
    (var-set active status)
    (ok true)
  )
)

(define-public (add-trust-action
    (action (string-ascii 50))
    (points uint)
  )
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) ERR-NOT-ADMIN)
    (asserts! (<= points u100) ERR-INVALID-PARAMETERS)
    (map-set trust-actions { action: action } {
      points: points,
      active: true,
    })
    (ok true)
  )
)

;; CORE FUNCTIONS
;; Register new identity
(define-public (register-identity)
  (let ((owner tx-sender))
    (begin
      (asserts! (var-get active) ERR-UNAUTHORIZED)
      (asserts! (is-none (map-get? identities { owner: owner }))
        ERR-IDENTITY-EXISTS
      )

      (map-set identities { owner: owner } {
        reputation: DEFAULT-REPUTATION,
        created-at: stacks-block-height,
        last-updated: stacks-block-height,
        last-decay: stacks-block-height,
        active: true,
      })

      (var-set total-users (+ (var-get total-users) u1))
      (ok DEFAULT-REPUTATION)
    )
  )
)

;; Execute trust action to earn reputation
(define-public (execute-action (action (string-ascii 50)))
  (let (
      (owner tx-sender)
      (profile (unwrap! (map-get? identities { owner: owner }) ERR-IDENTITY-NOT-FOUND))
      (action-config (unwrap! (map-get? trust-actions { action: action }) ERR-INVALID-PARAMETERS))
    )
    (begin
      (asserts! (var-get active) ERR-UNAUTHORIZED)
      (asserts! (get active profile) ERR-UNAUTHORIZED)
      (asserts! (get active action-config) ERR-INVALID-PARAMETERS)

      ;; Apply decay if needed
      (if (>= (- stacks-block-height (get last-decay profile)) DECAY-PERIOD)
        (begin
          (try! (apply-decay owner))
          true
        )
        true
      )

      ;; Calculate new reputation
      (let (
          (current-profile (unwrap! (map-get? identities { owner: owner }) ERR-IDENTITY-NOT-FOUND))
          (current-rep (get reputation current-profile))
          (points (get points action-config))
          (new-rep (if (< (+ current-rep points) MAX-REPUTATION)
            (+ current-rep points)
            MAX-REPUTATION
          ))
        )
        (begin
          (map-set identities { owner: owner }
            (merge current-profile {
              reputation: new-rep,
              last-updated: stacks-block-height,
            })
          )
          (ok new-rep)
        )
      )
    )
  )
)

;; Apply reputation decay
(define-private (apply-decay (owner principal))
  (let (
      (profile (unwrap! (map-get? identities { owner: owner }) ERR-IDENTITY-NOT-FOUND))
      (current-rep (get reputation profile))
      (decay-amount (/ (* current-rep DECAY-RATE) u100))
      (new-rep (if (> current-rep decay-amount)
        (- current-rep decay-amount)
        MIN-REPUTATION
      ))
    )
    (begin
      (map-set identities { owner: owner }
        (merge profile {
          reputation: new-rep,
          last-updated: stacks-block-height,
          last-decay: stacks-block-height,
        })
      )
      (ok new-rep)
    )
  )
)

;; READ-ONLY FUNCTIONS
(define-read-only (get-reputation (owner principal))
  (match (map-get? identities { owner: owner })
    profile (some (get reputation profile))
    none
  )
)

(define-read-only (get-profile (owner principal))
  (map-get? identities { owner: owner })
)

(define-read-only (verify-threshold
    (owner principal)
    (threshold uint)
  )
  (match (map-get? identities { owner: owner })
    profile (and (get active profile) (>= (get reputation profile) threshold))
    false
  )
)

(define-read-only (get-protocol-info)
  {
    max-reputation: MAX-REPUTATION,
    default-reputation: DEFAULT-REPUTATION,
    decay-rate: DECAY-RATE,
    decay-period: DECAY-PERIOD,
    total-users: (var-get total-users),
    admin: (var-get admin),
    active: (var-get active),
  }
)

;; INITIALIZATION
;; Bootstrap essential trust actions
(map-set trust-actions { action: "lightning-channel" } {
  points: u10,
  active: true,
})
(map-set trust-actions { action: "governance-vote" } {
  points: u5,
  active: true,
})
(map-set trust-actions { action: "defi-interaction" } {
  points: u15,
  active: true,
})
(map-set trust-actions { action: "contract-deploy" } {
  points: u20,
  active: true,
})
(map-set trust-actions { action: "security-audit" } {
  points: u25,
  active: true,
})

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
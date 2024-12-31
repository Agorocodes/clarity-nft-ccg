;; Clarity Smart Contract for Clarity Decentralized Collectible Card Game (CCG)
;;
;; This contract facilitates the creation and management of collectible cards as Non-Fungible Tokens (NFTs).
;; It allows the minting, burning, transferring, and updating of card data within the game.
;; Key features:
;; - Minting of single or batch cards with unique URIs
;; - Burning cards and tracking burned status
;; - Card ownership management and transfer functionality
;; - Owner-only actions to mint or modify cards
;; - Read-only functions to fetch card metadata, owner details, and card status
;; 
;; The contract ensures that only the designated owner can mint or batch-mint cards and prevents unauthorized modifications.
;; Card data is associated with a URI, representing the card's metadata or visual content.

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-card-not-owner (err u101))
(define-constant err-card-exists (err u102))
(define-constant err-card-not-found (err u103))
(define-constant err-invalid-card-uri (err u104))
(define-constant err-already-burned (err u105))
(define-constant err-invalid-batch-size (err u106))
(define-constant max-batch-size u100)  ;; Maximum cards that can be minted in a single batch

;; Data Variables
(define-non-fungible-token card-nft uint)
(define-data-var last-card-id uint u0)

;; Maps
(define-map card-uri uint (string-ascii 256))
(define-map burned-cards uint bool)  ;; Track burned cards
(define-map batch-metadata uint (string-ascii 256))  ;; Store batch metadata

;; Private Functions
(define-private (is-card-owner (card-id uint) (sender principal))
    (is-eq sender (unwrap! (nft-get-owner? card-nft card-id) false)))

(define-private (is-valid-card-uri (uri (string-ascii 256)))
    (let ((uri-length (len uri)))
        (and (>= uri-length u1)
             (<= uri-length u256))))

(define-private (is-card-burned (card-id uint))
    (default-to false (map-get? burned-cards card-id)))

(define-private (mint-single-card (card-uri-data (string-ascii 256)))
    (let ((card-id (+ (var-get last-card-id) u1)))
        (asserts! (is-valid-card-uri card-uri-data) err-invalid-card-uri)
        (try! (nft-mint? card-nft card-id tx-sender))
        (map-set card-uri card-id card-uri-data)
        (var-set last-card-id card-id)
        (ok card-id)))

(define-private (uint-to-response (id uint))
    {
        card-id: id,
        uri: (unwrap-panic (get-card-uri id)),
        owner: (unwrap-panic (get-owner id)),
        burned: (unwrap-panic (is-burned id))
    })


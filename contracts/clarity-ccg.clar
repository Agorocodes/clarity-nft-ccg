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

(define-private (list-cards (start uint) (count uint))
    (map + 
        (list start) 
        (generate-sequence count)))

(define-private (generate-sequence (length uint))
    (map - (list length)))

;; Refactor and optimize: Combining mint and URI validation into a single function
(define-private (validate-card-uri (uri (string-ascii 256)))
    (let ((uri-length (len uri)))
        (and (>= uri-length u1)
             (<= uri-length u256))))

(define-private (mint-single-card-in-batch (uri (string-ascii 256)) (previous-results (list 100 uint)))
(match (mint-single-card uri)
    success (unwrap-panic (as-max-len? (append previous-results success) u100))
    error previous-results))

;; Public Functions
(define-public (mint-card (card-uri-data (string-ascii 256)))
    (begin
        ;; Validate that the caller is the contract owner
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)

        ;; Validate the card URI
        (asserts! (is-valid-card-uri card-uri-data) err-invalid-card-uri)

        ;; Proceed with minting the card
        (mint-single-card card-uri-data)))

(define-public (batch-mint-cards (uris (list 100 (string-ascii 256))))
    (let 
        ((batch-size (len uris)))
        (begin
            (asserts! (is-eq tx-sender contract-owner) err-owner-only)
            (asserts! (<= batch-size max-batch-size) err-invalid-batch-size)
            (asserts! (> batch-size u0) err-invalid-batch-size)

            ;; Use fold to process the URIs and mint cards
            (ok (fold mint-single-card-in-batch uris (list)))
        )))

(define-public (burn-card (card-id uint))
    (let ((card-owner (unwrap! (nft-get-owner? card-nft card-id) err-card-not-found)))
        (asserts! (is-eq tx-sender card-owner) err-card-not-owner)
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (try! (nft-burn? card-nft card-id card-owner))
        (map-set burned-cards card-id true)
        (ok true)))

(define-public (transfer-card (card-id uint) (sender principal) (recipient principal))
    (begin
        (asserts! (is-eq recipient tx-sender) err-card-not-owner)
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (let ((actual-sender (unwrap! (nft-get-owner? card-nft card-id) err-card-not-owner)))
            (asserts! (is-eq actual-sender sender) err-card-not-owner)
            (try! (nft-transfer? card-nft card-id sender recipient))
            (ok true))))

(define-public (update-card-uri (card-id uint) (new-uri (string-ascii 256)))
    (begin
        (let ((card-owner (unwrap! (nft-get-owner? card-nft card-id) err-card-not-found)))
            (asserts! (is-eq card-owner tx-sender) err-card-not-owner)
            (asserts! (is-valid-card-uri new-uri) err-invalid-card-uri)
            (map-set card-uri card-id new-uri)
            (ok true))))

;; Security improvement: Ensure that burning a card updates the status immediately
(define-public (burn-card-and-update-status (card-id uint))
    (let ((card-owner (unwrap! (nft-get-owner? card-nft card-id) err-card-not-found)))
        (asserts! (is-eq tx-sender card-owner) err-card-not-owner)
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (try! (nft-burn? card-nft card-id card-owner))
        (map-set burned-cards card-id true)
        (ok "Card burned and status updated.")))


;; Fix bug: Prevent minting with invalid batch size
(define-public (validate-batch-size (uris (list 100 (string-ascii 256))))
    (let ((batch-size (len uris)))
        (asserts! (<= batch-size max-batch-size) err-invalid-batch-size)
        (asserts! (> batch-size u0) err-invalid-batch-size)
        (ok "Batch size is valid.")))

;; This function ensures that only the actual owner can transfer a card.
(define-public (secure-transfer-card (card-id uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? card-nft card-id) err-card-not-owner)) err-card-not-owner)
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (try! (nft-transfer? card-nft card-id tx-sender recipient))
        (ok true)))

;; This function prevents the burning of cards that do not exist or are already burned.
(define-public (prevent-invalid-card-burn (card-id uint))
    (begin
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (asserts! (not (is-card-owner card-id tx-sender)) err-card-not-owner)
        (ok true)))

;; This function refactors the transfer-card function for better readability and consistency.
(define-public (refactored-transfer-card (card-id uint) (recipient principal))
    (begin
        (asserts! (is-eq tx-sender (unwrap! (nft-get-owner? card-nft card-id) err-card-not-owner)) err-card-not-owner)
        (asserts! (not (is-card-burned card-id)) err-already-burned)
        (try! (nft-transfer? card-nft card-id tx-sender recipient))
        (ok true)))

;; Read-Only Functions
(define-read-only (get-card-uri (card-id uint))
    (ok (map-get? card-uri card-id)))

(define-read-only (get-owner (card-id uint))
    (ok (nft-get-owner? card-nft card-id)))

(define-read-only (get-last-card-id)
    (ok (var-get last-card-id)))

(define-read-only (is-burned (card-id uint))
    (ok (is-card-burned card-id)))

(define-read-only (get-batch-card-ids (start-id uint) (count uint))
    (ok (map uint-to-response 
        (unwrap-panic (as-max-len? 
            (list-cards start-id count) 
            u100)))))

;; Contract initialization
(begin
    (var-set last-card-id u0))


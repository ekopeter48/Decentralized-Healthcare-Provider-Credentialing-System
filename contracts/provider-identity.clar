;; Provider Identity Contract
;; Manages practitioner profiles in a decentralized healthcare credentialing system

;; Data Maps
(define-map providers
  { provider-id: principal }
  {
    name: (string-utf8 100),
    specialty: (string-utf8 100),
    contact-info: (string-utf8 200),
    profile-hash: (buff 32),
    active: bool,
    created-at: uint,
    updated-at: uint
  }
)

;; Provider Registration
(define-public (register-provider
                (name (string-utf8 100))
                (specialty (string-utf8 100))
                (contact-info (string-utf8 200))
                (profile-hash (buff 32)))
  (let ((provider-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1)))))
    (asserts! (is-none (map-get? providers {provider-id: provider-id})) (err u1)) ;; Provider already exists
    (map-set providers
      {provider-id: provider-id}
      {
        name: name,
        specialty: specialty,
        contact-info: contact-info,
        profile-hash: profile-hash,
        active: true,
        created-at: current-time,
        updated-at: current-time
      }
    )
    (ok provider-id)
  )
)

;; Update Provider Profile
(define-public (update-provider
                (name (string-utf8 100))
                (specialty (string-utf8 100))
                (contact-info (string-utf8 200))
                (profile-hash (buff 32)))
  (let ((provider-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (existing-provider (unwrap! (map-get? providers {provider-id: provider-id}) (err u2)))) ;; Provider not found
    (map-set providers
      {provider-id: provider-id}
      {
        name: name,
        specialty: specialty,
        contact-info: contact-info,
        profile-hash: profile-hash,
        active: (get active existing-provider),
        created-at: (get created-at existing-provider),
        updated-at: current-time
      }
    )
    (ok provider-id)
  )
)

;; Deactivate Provider
(define-public (deactivate-provider)
  (let ((provider-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (existing-provider (unwrap! (map-get? providers {provider-id: provider-id}) (err u2)))) ;; Provider not found
    (map-set providers
      {provider-id: provider-id}
      {
        name: (get name existing-provider),
        specialty: (get specialty existing-provider),
        contact-info: (get contact-info existing-provider),
        profile-hash: (get profile-hash existing-provider),
        active: false,
        created-at: (get created-at existing-provider),
        updated-at: current-time
      }
    )
    (ok provider-id)
  )
)

;; Reactivate Provider
(define-public (reactivate-provider)
  (let ((provider-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (existing-provider (unwrap! (map-get? providers {provider-id: provider-id}) (err u2)))) ;; Provider not found
    (map-set providers
      {provider-id: provider-id}
      {
        name: (get name existing-provider),
        specialty: (get specialty existing-provider),
        contact-info: (get contact-info existing-provider),
        profile-hash: (get profile-hash existing-provider),
        active: true,
        created-at: (get created-at existing-provider),
        updated-at: current-time
      }
    )
    (ok provider-id)
  )
)

;; Get Provider Details
(define-read-only (get-provider (provider-id principal))
  (map-get? providers {provider-id: provider-id})
)

;; Check if Provider is Active
(define-read-only (is-provider-active (provider-id principal))
  (match (map-get? providers {provider-id: provider-id})
    provider (ok (get active provider))
    (err u2) ;; Provider not found
  )
)

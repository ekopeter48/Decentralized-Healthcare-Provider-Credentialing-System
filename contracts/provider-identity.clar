;; Education Verification Contract
;; Validates medical training credentials in a decentralized healthcare credentialing system

;; Data Maps
(define-map education-credentials
  { provider-id: principal, credential-id: uint }
  {
    institution: (string-utf8 100),
    degree: (string-utf8 100),
    field: (string-utf8 100),
    year-completed: uint,
    credential-hash: (buff 32),
    verified: bool,
    verifier: (optional principal),
    created-at: uint,
    verified-at: (optional uint)
  }
)

(define-map provider-credential-count
  { provider-id: principal }
  { count: uint }
)

;; Provider Identity Contract
(define-constant provider-identity-contract .provider-identity)

;; Add Education Credential
(define-public (add-credential
                (institution (string-utf8 100))
                (degree (string-utf8 100))
                (field (string-utf8 100))
                (year-completed uint)
                (credential-hash (buff 32)))
  (let ((provider-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (provider-active (contract-call? provider-identity-contract is-provider-active provider-id))
        (credential-count-data (default-to {count: u0} (map-get? provider-credential-count {provider-id: provider-id})))
        (credential-id (+ (get count credential-count-data) u1)))

    ;; Check if provider is active
    (asserts! (is-ok provider-active) (err u1))
    (asserts! (unwrap! provider-active (err u1)) (err u2)) ;; Provider must be active

    ;; Add credential
    (map-set education-credentials
      {provider-id: provider-id, credential-id: credential-id}
      {
        institution: institution,
        degree: degree,
        field: field,
        year-completed: year-completed,
        credential-hash: credential-hash,
        verified: false,
        verifier: none,
        created-at: current-time,
        verified-at: none
      }
    )

    ;; Update credential count
    (map-set provider-credential-count
      {provider-id: provider-id}
      {count: credential-id}
    )

    (ok credential-id)
  )
)

;; Verify Education Credential (by authorized verifier)
(define-public (verify-credential (provider-id principal) (credential-id uint))
  (let ((verifier-id tx-sender)
        (current-time (unwrap-panic (get-block-info? time (- block-height u1))))
        (credential (unwrap! (map-get? education-credentials {provider-id: provider-id, credential-id: credential-id}) (err u3)))) ;; Credential not found

    ;; In a real implementation, we would check if verifier is authorized
    ;; For simplicity, we're allowing any principal to verify

    (map-set education-credentials
      {provider-id: provider-id, credential-id: credential-id}
      {
        institution: (get institution credential),
        degree: (get degree credential),
        field: (get field credential),
        year-completed: (get year-completed credential),
        credential-hash: (get credential-hash credential),
        verified: true,
        verifier: (some verifier-id),
        created-at: (get created-at credential),
        verified-at: (some current-time)
      }
    )

    (ok true)
  )
)

;; Get Education Credential
(define-read-only (get-credential (provider-id principal) (credential-id uint))
  (map-get? education-credentials {provider-id: provider-id, credential-id: credential-id})
)

;; Get All Credentials for Provider
(define-read-only (get-credential-count (provider-id principal))
  (default-to {count: u0} (map-get? provider-credential-count {provider-id: provider-id}))
)

;; Check if Credential is Verified
(define-read-only (is-credential-verified (provider-id principal) (credential-id uint))
  (match (map-get? education-credentials {provider-id: provider-id, credential-id: credential-id})
    credential (ok (get verified credential))
    (err u3) ;; Credential not found
  )
)

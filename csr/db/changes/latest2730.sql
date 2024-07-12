-- Please update version.sql too -- this keeps clean builds in sync
define version=2730
@update_header

ALTER TABLE csr.sso_certificate_status DROP CONSTRAINT UK_SSO_CERT_STATUS;
ALTER TABLE csr.sso_certificate_status DROP COLUMN SID_ID;
ALTER TABLE csr.sso_certificate_status ADD (
	CERT_HASH	RAW(64) NULL
);
ALTER TABLE csr.sso_certificate_status ADD CONSTRAINT UK_SSO_CERT_STATUS UNIQUE (cert_hash, sso_cert_id);

@..\certificate_pkg
@..\certificate_body

@update_tail

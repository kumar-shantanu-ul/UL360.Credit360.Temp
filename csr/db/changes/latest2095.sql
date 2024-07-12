define version=2095
@update_header

ALTER TABLE csr.internal_audit ADD (
	COMPARISON_RESPONSE_ID	NUMBER(10) NULL
);

@..\audit_pkg
@..\audit_body

@update_tail
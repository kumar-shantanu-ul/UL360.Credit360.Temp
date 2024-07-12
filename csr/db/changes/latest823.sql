-- Please update version.sql too -- this keeps clean builds in sync
define version=823
@update_header

ALTER TABLE CSR.TAG ADD (
	LOOKUP_KEY			VARCHAR2(30)
);

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE MODIFY LOOKUP_KEY VARCHAR2(30);

@../audit_body

@update_tail
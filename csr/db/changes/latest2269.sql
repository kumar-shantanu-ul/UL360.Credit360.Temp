-- Please update version.sql too -- this keeps clean builds in sync
define version=2269
@update_header

ALTER TABLE CSRIMP.internal_audit_type ADD (
	VALIDITY_MONTHS           NUMBER(10)
);

@..\csrimp\imp_body

@update_tail

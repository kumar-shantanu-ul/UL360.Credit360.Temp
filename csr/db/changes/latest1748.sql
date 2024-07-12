-- Please update version.sql too -- this keeps clean builds in sync
define version=1748
@update_header

ALTER TABLE csr.internal_audit_type ADD (
	auditor_can_take_ownership NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_IAT_TAKE_OWNERSHIP_0_1 CHECK (auditor_can_take_ownership IN (0,1))
);

ALTER TABLE csrimp.internal_audit_type ADD (auditor_can_take_ownership NUMBER(1));
UPDATE csrimp.internal_audit_type SET auditor_can_take_ownership=0;
ALTER TABLE csrimp.internal_audit_type MODIFY auditor_can_take_ownership NOT NULL;
ALTER TABLE csrimp.internal_audit_type ADD CONSTRAINT CHK_IAT_TAKE_OWNERSHIP_0_1 CHECK (auditor_can_take_ownership IN (0,1));

@../audit_pkg
@../audit_body
@../schema_body
@../csrimp/imp_body

@update_tail

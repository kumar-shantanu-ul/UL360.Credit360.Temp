-- Please update version.sql too -- this keeps clean builds in sync
define version=805
@update_header

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD (
    LOOKUP_KEY                VARCHAR2(60)
);

@..\audit_pkg
@..\audit_body

@update_tail
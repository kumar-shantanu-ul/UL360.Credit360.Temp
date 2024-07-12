-- Please update version.sql too -- this keeps clean builds in sync
define version=883
@update_header

ALTER TABLE CSR.INTERNAL_AUDIT ADD (
    AUDITOR_NAME              VARCHAR2(50),
    AUDITOR_ORGANISATION      VARCHAR2(50)
);

@..\audit_pkg
@..\audit_body

@update_tail

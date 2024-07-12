-- Please update version.sql too -- this keeps clean builds in sync
define version=1483
@update_header

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE ADD(
    OVERRIDE_ISSUE_DTM        NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_IAT_OVRD_ISS_DTM_0_1 CHECK (OVERRIDE_ISSUE_DTM IN (0,1))
)
;

ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE ADD(
    OVERRIDE_ISSUE_DTM        NUMBER(1, 0),
    CONSTRAINT CHK_IAT_OVRD_ISS_DTM_0_1 CHECK (OVERRIDE_ISSUE_DTM IN (0,1))
)
;

UPDATE  CSRIMP.INTERNAL_AUDIT_TYPE SET OVERRIDE_ISSUE_DTM=0;

ALTER TABLE CSRIMP.INTERNAL_AUDIT_TYPE MODIFY OVERRIDE_ISSUE_DTM NOT NULL;

@..\audit_pkg

@..\quick_survey_body
@..\audit_body
@..\schema_body
@..\csrimp\imp_body

@update_tail

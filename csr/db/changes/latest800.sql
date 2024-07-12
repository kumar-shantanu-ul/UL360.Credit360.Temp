-- Please update version.sql too -- this keeps clean builds in sync
define version=800
@update_header


CREATE SEQUENCE CSR.INTERNAL_AUDIT_TYPE_ID_SEQ 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

@..\audit_pkg
@..\audit_body
@..\quick_survey_body

@update_tail

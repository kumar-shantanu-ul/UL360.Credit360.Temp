-- Please update version.sql too -- this keeps clean builds in sync
define version=2167
@update_header

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD DEFAULT_OVERDUE_DAYS NUMBER(10) NULL;

@update_tail
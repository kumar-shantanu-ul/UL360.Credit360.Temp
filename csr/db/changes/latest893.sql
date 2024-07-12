-- Please update version.sql too -- this keeps clean builds in sync
define version=893
@update_header

GRANT SELECT, REFERENCES ON ASPEN2.LANG TO CSR;


CREATE TABLE CSR.QUICK_SURVEY_LANG(
    APP_SID        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_SID    NUMBER(10, 0)    NOT NULL,
    LANG          VARCHAR2(10)    NOT NULL,
    CONSTRAINT PK_QS_LANG PRIMARY KEY (APP_SID, SURVEY_SID, LANG)
);

ALTER TABLE CSR.QUICK_SURVEY_LANG ADD CONSTRAINT FK_QS_LANG_QS
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES CSR.QUICK_SURVEY(APP_SID, SURVEY_SID);

   
ALTER TABLE CSR.QUICK_SURVEY_LANG ADD CONSTRAINT FK_QS_LANG_LANG
    FOREIGN KEY (LANG)
    REFERENCES ASPEN2.LANG(LANG);
	
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CSR',
		object_name     => 'QUICK_SURVEY_LANG',
		policy_name     => 'QUICK_SURVEY_LANG_POLICY',
		function_schema => 'CSR',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/						
	
@..\quick_survey_pkg
@..\quick_survey_body

@update_tail

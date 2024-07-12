-- Please update version.sql too -- this keeps clean builds in sync
define version=1950
@update_header

GRANT SELECT, REFERENCES ON CSR.FLOW TO CHAIN;

CREATE TABLE CHAIN.FLOW_QUESTIONNAIRE_TYPE(
	APP_SID            	 	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	FLOW_SID				NUMBER(10, 0)	 NOT NULL,
	QUESTIONNAIRE_TYPE_ID	NUMBER(10, 0)	 NOT NULL,
	CONSTRAINT	PK_FLOW_QNR_TYPE	PRIMARY KEY (APP_SID, FLOW_SID)			
);

ALTER TABLE CHAIN.FLOW_QUESTIONNAIRE_TYPE ADD CONSTRAINT FK_FLOW_QNR_TYPE_QNNAIRE_TYPE
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_TYPE_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_TYPE (APP_SID, QUESTIONNAIRE_TYPE_ID)
;

ALTER TABLE CHAIN.FLOW_QUESTIONNAIRE_TYPE ADD CONSTRAINT FK_FLOW_QNR_TYPE_FLOW 
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW (APP_SID, FLOW_SID)
;


/* rls policy for chain.flow_questionnaire_type */
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CHAIN',
			object_name     => 'FLOW_QUESTIONNAIRE_TYPE',
			policy_name     => 'FLOW_QUESTIONNAIRE_TYPE_POLICY',
			function_schema => 'CHAIN',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive 
		);
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			NULL;
		WHEN FEATURE_NOT_ENABLED THEN
			dbms_output.put_line('RLS policies not applied for "CHAIN.FLOW_QUESTIONNAIRE_TYPE" as feature not enabled');
	END;
END;
/
	
@../chain/flow_form_pkg
	
@../chain/flow_form_body	

@update_tail
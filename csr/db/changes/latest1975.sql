-- Please update version.sql too -- this keeps clean builds in sync
define version=1975
@update_header

CREATE TABLE CHAIN.FLOW_FILTER (
	APP_SID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	FLOW_SID              	NUMBER(10) NOT NULL,
	SAVED_FILTER_SID     	NUMBER(10) NOT NULL,
  CONSTRAINT PK_FLOW_FILTER PRIMARY KEY (APP_SID, FLOW_SID, SAVED_FILTER_SID)
);

ALTER TABLE CHAIN.FLOW_FILTER ADD CONSTRAINT FK_FLOW_FILTER_FLOW
    FOREIGN KEY (APP_SID, FLOW_SID)
    REFERENCES CSR.FLOW(APP_SID, FLOW_SID)
	ON DELETE CASCADE
;

ALTER TABLE CHAIN.FLOW_FILTER ADD CONSTRAINT FK_FLOW_FILTER_FILTER
    FOREIGN KEY (APP_SID, SAVED_FILTER_SID)
    REFERENCES CHAIN.SAVED_FILTER(APP_SID, SAVED_FILTER_SID)
	ON DELETE CASCADE
;

/* rls policy for chain.flow_filter */
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	BEGIN
		dbms_rls.add_policy(
			object_schema   => 'CHAIN',
			object_name     => 'FLOW_FILTER',
			policy_name     => 'FLOW_FILTER_POLICY',
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
			dbms_output.put_line('RLS policies not applied for "CHAIN.FLOW_FILTER" as feature not enabled');
	END;
END;
/
	
@../chain/flow_form_pkg
@../chain/flow_form_body	

@update_tail
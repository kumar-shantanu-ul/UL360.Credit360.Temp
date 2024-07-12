-- Please update version.sql too -- this keeps clean builds in sync
define version=2250
@update_header

SET SERVEROUTPUT ON;

-- RLS for new plugin table
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	POLICY_DOES_NOT_EXIST EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_DOES_NOT_EXIST, -28102);
BEGIN
	BEGIN
		DBMS_RLS.DROP_POLICY('CSRIMP', 'PLUGIN_INDICATOR', SUBSTR('PLUGIN_INDICATOR', 1, 23)||'_POLICY');
	EXCEPTION
		WHEN POLICY_DOES_NOT_EXIST THEN
			DBMS_OUTPUT.PUT_LINE('Policy function does not already exist for CSRIMP.PLUGIN_INDICATOR');
	END;

	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSRIMP',
			object_name     => 'PLUGIN_INDICATOR',
			policy_name     => SUBSTR('PLUGIN_INDICATOR', 1, 23)||'_POLICY',
			function_schema => 'CSRIMP',
			policy_function => 'sessionIdCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
			DBMS_OUTPUT.PUT_LINE('Policy added to PLUGIN_INDICATOR');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for CSRIMP.PLUGIN_INDICATOR');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for PLUGIN_INDICATOR as feature not enabled');
	END;
END;
/

GRANT SELECT,INSERT,UPDATE ON csr.PLUGIN_INDICATOR TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.plugin_indicator TO web_user;

@update_tail


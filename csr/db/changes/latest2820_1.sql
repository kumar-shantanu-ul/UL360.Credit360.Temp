-- Please update version.sql too -- this keeps clean builds in sync
define version=2820
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Data changes ***
-- RLS
DECLARE v_count NUMBER;
BEGIN	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_policies 
	 WHERE object_owner = 'CMS'
	   AND policy_name = 'DEBUG_DDL_LOG_POL'
	   AND object_name = 'DEBUG_DDL_LOG';
	   
	IF v_count > 0 THEN
		dbms_output.put_line('Dropping policy DEBUG_DDL_LOG_POL');
		dbms_rls.drop_policy(
			object_schema	=>'CMS',
			object_name  	=>'DEBUG_DDL_LOG',
			policy_name  	=>'DEBUG_DDL_LOG_POL'
		);
	END IF;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_output.put_line('Writing policy DEBUG_DDL_LOG_POL');
	dbms_rls.add_policy(
		object_schema   => 'CMS',
		object_name     => 'DEBUG_DDL_LOG',
		policy_name     => 'DEBUG_DDL_LOG_POL', 
		function_schema => 'CSRIMP',
		policy_function => 'SessionIDCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive
	);
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail

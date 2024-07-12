-- Please update version.sql too -- this keeps clean builds in sync
define version=2532
@update_header

-- SPECIAL CASE FOR APP_LOCK
-- We believe we've found a bug in 10g that's causing a problem when calling csr_data_pkg.LockApp.
-- After the update statement sets the dummy row in csr.app_lock, SQL%ROWCOUNT is sometimes zero, 
-- even though the row exists for the app sid and the context appears to be set correctly.
-- We've done extensive testing to rule out anything other then a possible bug in 10g.
-- Setting the rls policy type to 'dynamic' instead of 'context_sensitive' prevents the issue we are seeing.

BEGIN
	FOR r IN (
		SELECT object_name, policy_name 
		  FROM all_policies 
		 WHERE object_owner = 'CSR' 
		   AND object_name = 'APP_LOCK') 
	LOOP
		dbms_rls.drop_policy(
            object_schema   => 'CSR',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	dbms_rls.add_policy(
	    object_schema   => 'CSR',
	    object_name     => 'APP_LOCK',
	    policy_name     => 'APP_LOCK_POLICY',
	    function_schema => 'CSR',
	    policy_function => 'appSidCheck',
	    statement_types => 'select, insert, update, delete',
	    update_check	=> true,
	    policy_type     => dbms_rls.dynamic
	);
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policy not added as feature is disabled');
END;
/

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2456
@update_header

-- Create a new batch job type
INSERT INTO CSR.BATCH_JOB_TYPE (BATCH_JOB_TYPE_ID, DESCRIPTION, PLUGIN_NAME, ONE_AT_A_TIME)
	VALUES (14, 'Delegation completeness calculation', 'delegation-completeness', 0);
       -- 14 => JT_DELEGATION_COMP IN BATCH_JOB_PKG

CREATE TABLE CSR.BATCH_JOB_DELEGATION_COMP (
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID		NUMBER(10, 0)	NOT NULL,
	DELEGATION_SID		NUMBER(10,0)	NOT NULL,
	CONSTRAINT			PK_BATCH_JOB_DELEGATION_COMP PRIMARY KEY (APP_SID, BATCH_JOB_ID) ENABLE,
	CONSTRAINT			FK_BATCH_JOB_DELEGATION_COMP FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES			CSR.BATCH_JOB (APP_SID, BATCH_JOB_ID)
	ON DELETE CASCADE ENABLE
);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'BATCH_JOB_DELEGATION_COMP'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'appSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
END;
/

-- Update packages
@../batch_job_pkg.sql
@../batch_job_body.sql
@../delegation_pkg.sql
@../delegation_body.sql

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2304
@update_header

ALTER TABLE csr.internal_audit_file RENAME TO internal_audit_file_data;
ALTER TABLE csr.internal_audit_file_data RENAME COLUMN internal_audit_file_id to internal_audit_file_data_id;

ALTER TABLE csrimp.internal_audit_file RENAME TO internal_audit_file_data;		
ALTER TABLE csrimp.internal_audit_file_data RENAME COLUMN internal_audit_file_id to internal_audit_file_data_id;

ALTER TABLE csrimp.map_internal_audit_file RENAME TO map_internal_audit_file_data;
ALTER TABLE csrimp.map_internal_audit_file_data RENAME COLUMN OLD_INTERNAL_AUDIT_FILE_ID to OLD_INT_AUDIT_FILE_DATA_ID;
ALTER TABLE csrimp.map_internal_audit_file_data RENAME COLUMN NEW_INTERNAL_AUDIT_FILE_ID to NEW_INT_AUDIT_FILE_DATA_ID;  

ALTER TABLE csr.internal_audit_file_connection RENAME TO internal_audit_file;
ALTER TABLE csr.internal_audit_file RENAME COLUMN internal_audit_file_id to internal_audit_file_data_id;

ALTER TABLE csrimp.internal_audit_file_connection RENAME TO internal_audit_file;
ALTER TABLE csrimp.internal_audit_file RENAME COLUMN internal_audit_file_id to internal_audit_file_data_id;

-- todo INTERNAL_AUDIT_FILE as well?
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'INTERNAL_AUDIT_FILE_DATA',
		'INTERNAL_AUDIT_FILE'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema
				=> 'CSR',
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

@..\audit_pkg
@..\audit_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body
@..\csr_app_body

@update_tail

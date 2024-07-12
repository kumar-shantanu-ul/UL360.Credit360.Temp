-- Please update version.sql too -- this keeps clean builds in sync
define version=1516
@update_header


 
declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
begin   
    v_list := t_tabs(
        --'FUND',
        'METER_IND',
        'LEASE_TYPE',
        'PROPERTY_TYPE',
        'PROPERTY_TYPE_SPACE_TYPE',
        'REGION_TYPE_TAG_GROUP',
        'SPACE',
        'SPACE_TYPE',
        'SPACE_TYPE_REGION_METRIC',
        'AUDIT_NON_COMPLIANCE',
        'DELEG_META_ROLE_IND_SELECTION',
        'FLOW_ITEM_SUBSCRIPTION',
        'FLOW_STATE_LOG_FILE',
        'IND_SET',
        'IND_SET_IND',
        --'INTERNAL_AUDIT_REGION',
        'ISSUE_CUSTOM_FIELD_DATE_VAL',
        'METER_READING_DATA'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin
                    if v_i = 1 then
                        v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    else
                        v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
                    end if;
                    dbms_output.put_line('doing '||v_name);
                    dbms_rls.add_policy(
                        object_schema   => 'CSR',
                        object_name     => v_list(i),
                        policy_name     => v_name,
                        function_schema => 'CSR',
                        policy_function => 'appSidCheck',
                        statement_types => 'select, insert, update, delete',
                        update_check    => true,
                        policy_type     => dbms_rls.context_sensitive );
                    -- dbms_output.put_line('done  '||v_name);
                    exit;
                exception
                    when policy_already_exists then
                        v_i := v_i + 1;
                end;
            end loop;
        end;
    end loop;
end;
/



@..\csr_data_pkg
@..\space_pkg
@..\property_pkg
@..\flow_pkg
@..\region_metric_pkg

@..\csr_data_body
@..\space_body
@..\property_body
@..\flow_body
@..\region_metric_body

GRANT EXECUTE ON csr.region_metric_pkg TO WEB_USER;

@update_tail
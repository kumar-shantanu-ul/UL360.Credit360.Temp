-- Please update version.sql too -- this keeps clean builds in sync
define version=1541
@update_header

DROP SEQUENCE CSR.MGMT_COMPANY_ID;

CREATE SEQUENCE CSR.MGMT_COMPANY_ID_SEQ
    START WITH 1000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'MGMT_COMPANY',
        'RULESET',
        'RULESET_MEMBER',
        'RULESET_RUN',
        'RULESET_RUN_FINDING'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin               
                    v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    
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
                        NULL;
                end;
            end loop;
        end;
    end loop;
end;
/


CREATE OR REPLACE VIEW csr.v$property_meter AS
    SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
        NVL(mi.label, pi.description) group_label, mi.group_key,
        a.primary_ind_sid, pi.description primary_description, NVL(pmc.description, pm.description) primary_measure, a.primary_measure_conversion_id,
        a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,       
        ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
        ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
        ms.realtime_metering, ms.show_in_meter_list
      FROM all_meter a
        JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid            
        JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
        LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
        LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
        LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
        LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
        LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
        LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
        LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;

@..\property_pkg
@..\property_body        

@update_tail
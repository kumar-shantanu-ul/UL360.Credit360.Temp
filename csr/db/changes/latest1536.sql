-- Please update version.sql too -- this keeps clean builds in sync
define version=1536
@update_header

ALTER TABLE csr.PROPERTY_TYPE_SPACE_TYPE ADD (
    IS_HIDDEN           NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT CHK_PT_ST_HIDDEN CHECK (IS_HIDDEN IN (0,1))
);

-- added colours
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANSITION AS
    SELECT fst.app_sid, fi.flow_sid, fi.flow_item_Id, fst.flow_state_transition_id, fst.verb, 
    fs.flow_state_id from_state_id, fs.label from_state_label, fs.state_colour from_state_colour,
        tfs.flow_state_id to_state_id, tfs.label to_state_label, tfs.state_colour to_state_colour,
        fst.ask_for_comment, fst.pos transition_pos,
        fi.survey_response_id, fi.dashboard_instance_id -- UPDATE THIS WHEN WE ADD MORE COLUMNS FOR JOINS TO WORKFLOW DETAIL TABLES
      FROM flow_item fi           
        JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
        JOIN flow_state_transition fst ON fs.flow_state_id = fst.from_state_id AND fs.app_sid = fst.app_sid
        JOIN flow_state tfs ON fst.to_state_id = tfs.flow_state_id AND fst.app_sid = tfs.app_sid            
     WHERE tfs.is_deleted = 0
        ;

-- depends on v$flow_item_transition
CREATE OR REPLACE VIEW csr.V$FLOW_ITEM_TRANS_ROLE_MEMBER AS
    SELECT fit.*, r.role_sid, r.name role_name, rrm.region_sid
      FROM V$FLOW_ITEM_TRANSITION fit
        JOIN flow_state_transition_role fstr ON fit.flow_state_transition_id = fstr.flow_state_transition_id AND fit.app_sid = fstr.app_sid
        JOIN role r ON fstr.role_sid = r.role_sid AND fstr.app_sid = r.app_sid
        JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid 
     WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
    ;

-- added subtype
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;



-- missing RLS
declare
  policy_already_exists exception;
  pragma exception_init(policy_already_exists, -28101);

  type t_tabs is table of varchar2(30);
  v_list t_tabs;
  v_null_list t_tabs;
  v_found number;
begin 
  v_list := t_tabs(
    'FUND',
    'PROPERTY_SUB_TYPE'
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
                update_check  => true,
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


@..\property_pkg.sql 
@..\property_body.sql
@..\region_body.sql

@update_tail
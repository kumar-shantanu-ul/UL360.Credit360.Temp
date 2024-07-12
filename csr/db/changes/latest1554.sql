-- Please update version.sql too -- this keeps clean builds in sync
define version=1554
@update_header


ALTER TABLE CSR.RULESET_RUN_FINDING DROP PRIMARY KEY CASCADE DROP INDEX;

DELETE FROM CSR.RULESET_RUN_FINDING;

ALTER TABLE CSR.RULESET_RUN_FINDING ADD (
    START_DTM   DATE  NOT NULL,
    END_DTM     DATE  NOT NULL,
    CONSTRAINT CK_RULESET_RUN_FND_DATES CHECK (start_dtm = trunc(start_dtm, 'mon') and end_dtm = trunc(end_dtm, 'mon') and end_dtm > start_dtm)
);

ALTER TABLE CSR.RULESET_RUN_FINDING ADD (
    CONSTRAINT PK_RULESET_RUN_FINDING PRIMARY KEY (APP_SID, RULESET_SID, REGION_SID, IND_SID, FINDING_KEY, START_DTM, END_DTM)
);

/*
-- not doing this any more
ALTER TABLE CSR.TEMP_FLOW_FILTER ADD (
    HAS_TRANSITIONS         NUMBER(1) NULL
);
*/

ALTER TABLE CSR.FLOW_ITEM ADD (
    LAST_FLOW_STATE_TRANSITION_ID   NUMBER(10)  NULL,
    CONSTRAINT FK_FLOW_ITEM_FL_ST_TRANS FOREIGN KEY (APP_SID, LAST_FLOW_STATE_TRANSITION_ID)
    REFERENCES CSR.FLOW_STATE_TRANSITION(APP_SID, FLOW_STATE_TRANSITION_ID)
);

-- update as best we can
declare 
    v_cnt   number(10) := 0;
begin
    for r in (
        select x.flow_item_id, fst.flow_state_transition_id
          from (
            select flow_item_id, current_state_id to_state_id, flow_state_id from_state_Id, rn
              from (
                select fi.flow_item_id, fi.current_state_id, fsl.flow_state_id, 
                    row_number() over (partition by fsl.flow_item_id order by flow_state_log_id desc) rn
                  from csr.flow_item fi
                  join csr.flow_state_log fsl on fi.flow_item_id = fsl.flow_item_id and fi.app_sid = fsl.app_sid
             )
             where rn = 2
          )x     
          join csr.flow_state_transition fst on x.to_state_id = fst.to_state_id and x.from_state_id = fst.from_state_id 
    )
    loop
        update csr.flow_item set last_flow_state_transition_id = r.flow_state_transition_id where flow_item_id = r.flow_item_id;
        v_cnt := v_cnt + 1;
    end loop;
    dbms_output.put_line('updated '||v_cnt||' items');
end;
/


ALTER TABLE CSR.FLOW_ITEM ADD (
    LAST_FLOW_STATE_LOG_ID   NUMBER(10),
    CONSTRAINT FK_FLOW_ITEM_FL_ST_LOG FOREIGN KEY (APP_SID, LAST_FLOW_STATE_LOG_ID, FLOW_ITEM_ID)
    REFERENCES CSR.FLOW_STATE_LOG(APP_SID, FLOW_STATE_LOG_ID, FLOW_ITEM_ID) DEFERRABLE INITIALLY DEFERRED
);

declare
    v_cnt number(10) := 0;
    v_id  number(10);
begin
    for r in (
         select flow_item_id, flow_state_log_id 
           from (
             select fsl.flow_item_id, fsl.flow_state_log_id, row_number() over (partition by flow_item_id order by flow_state_log_id desc) rn
               from csr.flow_state_log fsl
          )
          where rn = 1
    )
    loop
        update csr.flow_item set last_flow_state_log_id = r.flow_state_log_id where flow_item_id = r.flow_item_id;
        v_cnt := v_cnt + 1;
    end loop;
    dbms_output.put_line(v_cnt||' last_flow_state_log_ids matched up');
    v_cnt := 0;
    for r in (
        select app_sid, flow_item_id, current_state_id
          from csr.flow_item
         where last_flow_state_log_Id is null
    )
    loop
        insert into csr.flow_state_log (app_sid, flow_state_log_id, flow_item_id, flow_state_Id, set_by_user_sid, set_dtm, comment_text)
            values (r.app_sid, csr.flow_state_log_id_seq.nextval, r.flow_item_id, r.current_state_id, security.security_pkg.SID_BUILTIN_ADMINISTRATOR, sysdate,'Automatically added')
            returning flow_state_log_id into v_id;
        update csr.flow_item
          set last_flow_state_log_id = v_id
        where flow_Item_id = r.flow_item_id;
        v_cnt := v_cnt + 1;
    end loop;
    dbms_output.put_line(v_cnt||' last_flow_state_log_ids missing but fixed');
end;
/


ALTER TABLE CSR.FLOW_ITEM MODIFY LAST_FLOW_STATE_LOG_ID NOT NULL;




create index csr.ix_all_meter_meter_ind_id on csr.all_meter (app_sid, meter_ind_id);
create index csr.ix_as2_inbound_r_original_mess on csr.as2_inbound_receipt (app_sid, original_message_id);
create index csr.ix_batch_job_as2_message_id on csr.batch_job_as2_outbound_message (app_sid, message_id);
create index csr.ix_batch_job_as2_original_mess on csr.batch_job_as2_outbound_receipt (app_sid, original_message_id);
create index csr.ix_batch_job_exc_model_instanc on csr.batch_job_excel_model (app_sid, model_instance_sid, base_model_sid);
create index csr.ix_csr_user_last_logon_ty on csr.csr_user (last_logon_type_id);
create index csr.ix_customer_property_flow on csr.customer (app_sid, property_flow_sid);
create index csr.ix_flow_item_last_flow_sta on csr.flow_item (app_sid, last_flow_state_transition_id);
create index csr.ix_flow_item_last_flow_st2 on csr.flow_item (app_sid, last_flow_state_log_id, flow_item_id);
create index csr.ix_flow_item_flow_sid on csr.flow_item (app_sid, flow_sid);
create index csr.ix_flow_item_ale_flow_transiti on csr.flow_item_alert (app_sid, flow_transition_alert_id);
create index csr.ix_flow_item_gen_to_user_sid on csr.flow_item_generated_alert (app_sid, to_user_sid);
create index csr.ix_flow_item_gen_flow_transiti on csr.flow_item_generated_alert (app_sid, flow_transition_alert_id);
create index csr.ix_flow_item_gen_from_user_sid on csr.flow_item_generated_alert (app_sid, from_user_sid);
create index csr.ix_flow_state_lo_flow_state_lo on csr.flow_state_log_file (app_sid, flow_state_log_id);
create index csr.ix_flow_state_tr_flow_sid_help on csr.flow_state_transition (app_sid, flow_sid, helper_sp);
create index csr.ix_flow_transiti_flow_state_tr on csr.flow_transition_alert (app_sid, flow_state_transition_id);
create index csr.ix_fund_company_sid on csr.fund (app_sid, company_sid);
create index csr.ix_imp_session_owner_sid on csr.imp_session (app_sid, owner_sid);
create index csr.ix_imp_val_imp_measure_i on csr.imp_val (app_sid, imp_measure_id, imp_ind_id);
create index csr.ix_imp_vocab_imp_tag_type_ on csr.imp_vocab (imp_tag_type_id);
create index csr.ix_inbound_cms_a_tab_sid on csr.inbound_cms_account (app_sid, tab_sid);
create index csr.ix_inbound_cms_a_flow_sid on csr.inbound_cms_account (app_sid, flow_sid);
create index csr.ix_inbound_cms_a_default_regio on csr.inbound_cms_account (app_sid, default_region_sid);
create index csr.ix_inbound_issue_issue_type_id on csr.inbound_issue_account (app_sid, issue_type_id);
create index csr.ix_ind_set_owner_sid on csr.ind_set (app_sid, owner_sid);
create index csr.ix_ind_set_ind_ind_sid on csr.ind_set_ind (app_sid, ind_sid);
create index csr.ix_meter_reading_meter_source_ on csr.meter_reading (app_sid, meter_source_type_id);
create index csr.ix_mgmt_company_company_sid on csr.mgmt_company (app_sid, company_sid);
create index csr.ix_property_property_type2 on csr.property (app_sid, property_type_id, property_sub_type_id);
create index csr.ix_property_fund_id on csr.property (app_sid, fund_id);
create index csr.ix_property_flow_item_id on csr.property (app_sid, flow_item_id);
create index csr.ix_property_company_sid on csr.property (app_sid, company_sid);
create index csr.ix_property_mgmt_company_ on csr.property (app_sid, mgmt_company_id);
create index csr.ix_property_property_type on csr.property (app_sid, property_type_id);
--create index csr.ix_property_divi_region_sid on csr.property_division (app_sid, region_sid);
create index csr.ix_property_type_space_type_id on csr.property_type_space_type (app_sid, space_type_id);
create index csr.ix_region_metric_ind_sid_measu on csr.region_metric_region (app_sid, ind_sid, measure_sid);
create index csr.ix_region_metric_measure_conve on csr.region_metric_region (app_sid, measure_conversion_id, measure_sid);
create index csr.ix_region_set_re_region_sid on csr.region_set_region (app_sid, region_sid);
create index csr.ix_region_type_t_tag_group_id on csr.region_type_tag_group (app_sid, tag_group_id);
create index csr.ix_region_type_t_region_type on csr.region_type_tag_group (region_type);
create index csr.ix_route_flow_sid_flow on csr.route (app_sid, flow_sid, flow_state_id);
create index csr.ix_route_section_sid on csr.route (app_sid, section_sid);
create index csr.ix_route_step_route_id on csr.route_step (app_sid, route_id);
create index csr.ix_route_step_us_csr_user_sid on csr.route_step_user (app_sid, csr_user_sid);
create index csr.ix_ruleset_reporting_per on csr.ruleset (app_sid, reporting_period_sid);
create index csr.ix_ruleset_membe_ind_sid on csr.ruleset_member (app_sid, ind_sid);
create index csr.ix_ruleset_run_region_sid on csr.ruleset_run (app_sid, region_sid);
create index csr.ix_ruleset_run_f_explained_by_ on csr.ruleset_run_finding (app_sid, explained_by_user_sid);
create index csr.ix_ruleset_run_f_ruleset_sid_i on csr.ruleset_run_finding (app_sid, ruleset_sid, ind_sid);
create index csr.ix_ruleset_run_f_approved_by_u on csr.ruleset_run_finding (app_sid, approved_by_user_sid);
create index csr.ix_section_current_route on csr.section (app_sid, current_route_step_id);
create index csr.ix_section_flow_item_id on csr.section (app_sid, flow_item_id);
create index csr.ix_section_alert_notify_user_s on csr.section_alert (app_sid, notify_user_sid);
create index csr.ix_section_alert_section_sid on csr.section_alert (app_sid, section_sid);
create index csr.ix_section_alert_from_user_sid on csr.section_alert (app_sid, from_user_sid);
create index csr.ix_section_alert_flow_state_id on csr.section_alert (app_sid, flow_state_id);
create index csr.ix_section_alert_route_step_id on csr.section_alert (app_sid, route_step_id);
create index csr.ix_section_alert_customer_aler on csr.section_alert (app_sid, customer_alert_type_id);
create index csr.ix_section_cart__section_sid on csr.section_cart_member (app_sid, section_sid);
create index csr.ix_section_modul_flow_sid on csr.section_module (app_sid, flow_sid);
create index csr.ix_section_modul_region_sid on csr.section_module (app_sid, region_sid);
create index csr.ix_section_route_flow_state_id on csr.section_routed_flow_state (app_sid, flow_state_id, flow_sid);
create index csr.ix_section_route_reject_fs_tra on csr.section_routed_flow_state (app_sid, reject_fs_transition_id);
create index csr.ix_section_tag_parent_id on csr.section_tag (app_sid, parent_id);
create index csr.ix_section_tag_m_section_sid on csr.section_tag_member (app_sid, section_sid);
create index csr.ix_section_trans_section_sid on csr.section_trans_comment (app_sid, section_sid);
create index csr.ix_section_trans_entered_by_si on csr.section_trans_comment (app_sid, entered_by_sid);
create index csr.ix_space_property_regi on csr.space (app_sid, property_region_sid, property_type_id);
create index csr.ix_space_property_type on csr.space (app_sid, property_type_id, space_type_id);
create index csr.ix_space_type_re_region_type_i on csr.space_type_region_metric (app_sid, region_type, ind_sid);
create index csr.ix_space_type_re_ind_sid on csr.space_type_region_metric (app_sid, ind_sid);


@..\flow_pkg
@..\property_pkg
@..\ruleset_pkg

@..\csr_app_body
@..\flow_body
@..\property_body
@..\ruleset_body

@update_tail
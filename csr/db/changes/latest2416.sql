-- -- Please update version.sql too -- this keeps clean builds in sync
define version=2416
@update_header

create index csr.ix_audit_type_he_plugin_id_plu on csr.audit_type_header (plugin_id, plugin_type_id);
create index csr.ix_audit_type_ta_plugin_id_plu on csr.audit_type_tab (plugin_id, plugin_type_id);
create index csr.ix_batch_job_str_company_sid on csr.batch_job_structure_import (app_sid, company_sid);
create index csr.ix_batch_job_tem_schedule_sid on csr.batch_job_templated_report (app_sid, schedule_sid);
create index csr.ix_customer_chemical_flow on csr.customer (app_sid, chemical_flow_sid);
create index csr.ix_delegation_layout_id on csr.delegation (app_sid, layout_id);

declare
	v_exists number;
begin
	select count(*)
	  into v_exists
	  from all_indexes
	 where owner='CSR' and table_name='INTERNAL_AUDIT_FILE' and index_name = 'IX_INT_AUDI_FILE_CONN_ID';
	 
	if v_exists = 1 then
		execute immediate 'DROP INDEX CSR.IX_INT_AUDI_FILE_CONN_ID';
	end if;
end;
/

-- Index existed under a different name originally.
DECLARE
	v_exists	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND table_name = 'INTERNAL_AUDIT_FILE'
	   AND index_name = 'IX_INTERNAL_AUDI_FILE_ID';
	 
	IF v_exists = 1 THEN
		EXECUTE IMMEDIATE 'DROP INDEX CSR.IX_INTERNAL_AUDI_FILE_ID';
	END IF;
END;
/

create index csr.ix_internal_audi_tab_sid on csr.internal_audit_type (app_sid, tab_sid);
create index csr.ix_module_param_module_id on csr.module_param (module_id);
create index csr.ix_plugin_tab_sid on csr.plugin (app_sid, tab_sid);
create index csr.ix_plugin_lookup_flow_sid_flow on csr.plugin_lookup_flow_state (app_sid, flow_sid, flow_state_id);
create index csr.ix_property_opti_properties_ge on csr.property_options (app_sid, properties_geo_map_sid);
create index csr.ix_tpl_report_sc_doc_folder_si on csr.tpl_report_schedule (app_sid, doc_folder_sid);
create index csr.ix_tpl_report_sc_region_select on csr.tpl_report_schedule (region_selection_type_id);
create index csr.ix_tpl_report_sc_tpl_report_si on csr.tpl_report_schedule (app_sid, tpl_report_sid);
create index csr.ix_tpl_rep_sc_reg_sel_tag on csr.tpl_report_schedule (app_sid, region_selection_tag_id);
create index csr.ix_tpl_report_sc_owner_user_si on csr.tpl_report_schedule (app_sid, owner_user_sid);
create index csr.ix_tpl_report_sc_role_sid on csr.tpl_report_schedule (app_sid, role_sid);
create index csr.ix_tpl_report_sc_region_sid on csr.tpl_report_schedule_region (app_sid, region_sid);
create index csr.ix_tpl_report_sc_schedule_sid on csr.tpl_report_schedule_region (app_sid, schedule_sid);
create index csr.ix_tpl_rep_sc_svd_doc_reg_sid on csr.tpl_report_sched_saved_doc (app_sid, region_sid);
create index csr.ix_tpl_report_sc_doc_id on csr.tpl_report_sched_saved_doc (app_sid, doc_id);
create index csr.ix_tpl_rep_sc_svd_doc_sch_sid on csr.tpl_report_sched_saved_doc (app_sid, schedule_sid);

alter table chain.component drop CONSTRAINT FK_COMPONENT_UNIT;
create index chain.ix_component_amount_unit_i on chain.component (app_sid, amount_unit_id);
ALTER TABLE CHAIN.COMPONENT ADD CONSTRAINT FK_COMPONENT_UNIT
    FOREIGN KEY (APP_SID, AMOUNT_UNIT_ID)
    REFERENCES CHAIN.AMOUNT_UNIT(APP_SID, AMOUNT_UNIT_ID)
;

create index chain.ix_component_parent_compon on chain.component (app_sid, parent_component_type_id, component_type_id);
create index chain.ix_invitation_ba_lang on chain.invitation_batch (app_sid, lang);
create index chain.ix_product_revis_revision_crea on chain.product_revision (app_sid, revision_created_by_sid);
create index chain.ix_product_revis_product_id_pr on chain.product_revision (app_sid, product_id, previous_end_dtm, previous_rev_number);
create index chain.ix_prch_cmpnt_cpmnt_comp_compt on chain.purchased_component (app_sid, component_id, company_sid, component_type_id);
create index chain.ix_purchased_com_pre_purc on chain.purchased_component (app_sid, previous_purch_component_id);

@update_tail

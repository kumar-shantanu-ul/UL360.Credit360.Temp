-- Please update version.sql too -- this keeps clean builds in sync
define version=562
@update_header

create index ix_customer_region_type_rt on customer_region_type(region_type) tablespace indx;
create index ix_ind_gas_type on ind(gas_type_id) tablespace indx;
create index ix_ind_map_to_ind on ind(app_sid, map_to_ind_sid) tablespace indx;
create index ix_ind_factor_type on ind(factor_type_id) tablespace indx;
create index ix_ind_gas_measure on ind(app_sid, gas_measure_sid) tablespace indx;
create index ix_axis_memb_related_act_tag on axis_member(app_sid, related_action_tag_id) tablespace indx;
create index ix_axis_memb_related_tag on axis_member(app_sid, related_tag_id) tablespace indx;
create index ix_axis_memb_primary_act_tag on axis_member(app_sid, primary_action_tag_id) tablespace indx;
create index ix_axis_memb_primary_tag on axis_member(app_sid, primary_tag_id) tablespace indx;
create index ix_axis_right on axis(app_sid, axis_id, right_side_axis_id) tablespace indx;
create index ix_axis_left on axis(app_sid, axis_id, left_side_axis_id) tablespace indx;
create index ix_axis_related_tag on axis_member(app_sid, related_tag_id) tablespace indx;
create index ix_axis_related_act_tag on axis_member(app_sid, related_action_tag_id) tablespace indx;
create index ix_axis_primary_tag on axis_member(app_sid, primary_tag_id) tablespace indx;
create index ix_axis_primary_act_tag on axis(app_sid, primary_action_tag_group_id) tablespace indx;
create index ix_related_axis_related on related_axis(app_sid, related_axis_id) tablespace indx;
create index ix_doc_current_pending on doc_current(app_sid, doc_id, pending_version) tablespace indx;
create index ix_std_factor_geo on std_factor(geo_country, geo_region) tablespace indx;
create index ix_std_factor_egrid on std_factor(egrid_ref) tablespace indx;
create index ix_factor_type_std_measure on factor_type(std_measure_id) tablespace indx;
create index ix_factor_type_parent on factor_type(parent_id) tablespace indx;
create index ix_postit_created_by on postit(app_sid, created_by_sid) tablespace indx;
create index ix_postit_file_postit on postit_file(app_sid, postit_id) tablespace indx;
create index ix_supplier_deleg_tpl_deleg on supplier_delegation(app_sid, tpl_delegation_sid) tablespace indx;
create index ix_supplier_deleg_deleg on supplier_delegation(app_sid, delegation_sid) tablespace indx;
create index ix_doc_folder_approver on doc_folder(app_sid, approver_sid) tablespace indx;
create index ix_doc_folder_subscrip_nfy on doc_folder_subscription(app_sid, notify_sid) tablespace indx;
create index ix_deleg_grid_ind on delegation_grid(app_sid, ind_sid) tablespace indx;
create index ix_var_expl_group on var_expl(app_sid, var_expl_group_id)tablespace indx;
create index ix_dataview_ind_norm_ind on dataview_ind_member(app_Sid, normalization_ind_sid) tablespace indx;
create index ix_rel_axis_mem_axis_mem on related_axis_member(app_sid, axis_id, axis_member_id) tablespace indx;
create index ix_rel_axis_mem_rel_axis on related_axis_member(app_sid, axis_id, related_axis_id) tablespace indx;
create index ix_rel_axis_mem_rel_axis_mem on related_axis_member(app_sid, axis_id, related_axis_member_id) tablespace indx;
create index ix_deleg_comment_deleg on delegation_comment(app_sid, delegation_sid) tablespace indx;
create index ix_axis_related_tgid on axis(app_sid, related_tag_group_id) tablespace indx;
create index ix_axis_related_act_tgid on axis(app_sid, related_action_tag_group_id) tablespace indx;
create index ix_axis_related_pri_tgid on axis(app_sid, primary_tag_group_id) tablespace indx;
create index ix_factor_org_factor on factor(app_sid, original_factor_id) tablespace indx;
create index ix_factor_egrid on factor(egrid_ref) tablespace indx;
create index ix_deleg_ind_var_expl on delegation_ind(app_sid, var_expl_group_id) tablespace indx;
create index ix_region_region_type on region(app_sid, region_type) tablespace indx;
create index ix_default_alert_tpl_frm on default_alert_template(default_alert_frame_id) tablespace indx;

@update_tail

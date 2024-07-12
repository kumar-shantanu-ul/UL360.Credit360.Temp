-- Please update version.sql too -- this keeps clean builds in sync
define version=1595
@update_header

create index actions.ix_refmeasure304 on actions.ind_template(app_sid,gas_measure_sid);
create index actions.ix_refmeasure_conversion309 on actions.task_ind_template_instance(app_sid,entry_measure_conversion_id);

create index chain.ix_busness_unit_parent on chain.business_unit(app_sid,parent_business_unit_id);
create index chain.ix_company_company_type on chain.company(app_sid,company_type_id);
create index chain.ix_ctc_ctr_relationship on chain.company_type_capability(app_sid,related_company_type_id,company_type_id);
create index chain.ix_ctc_ctr_inherited on chain.company_type_capability(app_sid,related_company_type_id,inherited_from_company_type_id);
create index chain.ix_ctr_company_type_2 on chain.company_type_relationship(app_sid,related_company_type_id);
create index chain.ix_fu_cu_last_modified_by_sid on chain.file_upload(app_sid,last_modified_by_sid);
create index chain.ix_invitation_company_obo on chain.invitation(app_sid,on_behalf_of_company_sid);
create index chain.ix_translation_set_iut on chain.invitation_user_tpl(app_sid,lang);
create index chain.ix_invite_obo_ctr_oboctcict on chain.invite_on_behalf_of(app_sid,on_behalf_of_company_type_id,can_invite_company_type_id);
create index chain.ix_ref_id_label_comp_typ on chain.reference_id_label(app_sid,company_type_id);
create index chain.ix_sector_parent_id on chain.sector(app_sid,parent_sector_id);

create index csr.ix_axis_publication_sid on csr.axis(app_sid,publication_sid);
create index csr.ix_axis_member_publication_sid on csr.axis_member(app_sid,publication_sid);
create index csr.ix_dataview_ris_ind on csr.dataview(app_sid,rank_ind_sid);
create index csr.ix_duc_delegation on csr.delegation_user_cover(app_sid,delegation_sid);
create index csr.ix_deleg_meta_role_ind_aspn2ts on csr.deleg_meta_role_ind_selection(app_sid,lang);
create index csr.ix_deleg_meta_role_ind_ind on csr.deleg_meta_role_ind_selection(app_sid,ind_sid);
create index csr.ix_dataview_dataview_exp_feed on csr.export_feed_dataview(app_sid,dataview_sid);
create index csr.ix_iss_iss_sup on csr.issue(app_sid,issue_supplier_id);
create index csr.ix_iss_sup_nc_action on csr.issue_supplier(app_sid,qs_expr_non_compl_action_id);
create index csr.ix_csru_it_default_role on csr.issue_type(app_sid,default_assign_to_role_sid);
create index csr.ix_csru_it_default_user on csr.issue_type(app_sid,default_assign_to_user_sid);
create index csr.ix_mir_mi on csr.model_instance_region(app_sid,base_model_sid,model_instance_sid);
create index csr.ix_fil_by_status_surv on csr.qs_filter_by_status(app_sid,survey_sid);
create index csr.ix_qs_fil_cond_cmp_op on csr.qs_filter_condition(app_sid,question_id,compare_to_option_id);
create index csr.ix_submsn_file_qss on csr.qs_submission_file(app_sid,survey_response_id,submission_id);
create index csr.ix_qs_q_opt_answer on csr.quick_survey_answer(app_sid,question_option_id,question_id);
create index csr.ix_expr_show_question_id on csr.quick_survey_expr_action(app_sid,show_question_id);
create index csr.ix_ind_qsst on csr.quick_survey_score_threshold(app_sid,maps_to_ind_sid);
create index csr.ix_st_qsst on csr.quick_survey_score_threshold(app_sid,score_threshold_id);
create index csr.ix_meas_conv_rlst_run_fnd on csr.ruleset_run_finding(app_sid,entry_measure_conversion_id);
create index csr.ix_sup_score_ind_sid on csr.score_threshold(app_sid,supplier_score_ind_sid);
create index csr.ix_sheetaa_sheet on csr.sheet_automatic_approval(app_sid,sheet_id);
create index csr.ix_sheetaa_user on csr.sheet_automatic_approval(app_sid,csr_user_sid);
create index csr.ix_wsvmv_wscvm on csr.worksheet_column_value_map(app_sid,value_map_id,column_type_id,value_mapper_id);

create index donations.ix_reftag_group258 on donations.customer_options(app_sid,fc_status_tag_group_sid);
create index donations.ix_refcustom_field176 on donations.customer_options(app_sid,fc_amount_field_lookup_key);
create index donations.ix_fc_paid_tag_id on donations.customer_options(app_sid,fc_paid_tag_id);
create index donations.ix_reftag241 on donations.customer_options(app_sid,fc_tag_id);
create index donations.ix_reffunding_commitment219 on donations.fc_budget(app_sid,funding_commitment_sid);
create index donations.ix_refdonation245 on donations.fc_donation(app_sid,donation_id);
create index donations.ix_reffunding_commitment239 on donations.fc_tag(app_sid,funding_commitment_sid);
create index donations.ix_reffunding_commitment223 on donations.fc_upload(app_sid,funding_commitment_sid);
create index donations.ix_refscheme225 on donations.funding_commitment(app_sid,scheme_sid);
create index donations.ix_reftag200 on donations.funding_commitment(app_sid,charity_budget_tag_id);
create index donations.ix_refregion_group227 on donations.funding_commitment(app_sid,region_group_sid);
create index donations.ix_refdonation_status221 on donations.funding_commitment(app_sid,donation_status_sid);
create index donations.ix_refrecipient199 on donations.funding_commitment(app_sid,recipient_sid);


@update_tail
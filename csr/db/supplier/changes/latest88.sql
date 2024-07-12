-- Please update version.sql too -- this keeps clean builds in sync
define version=88
@update_header

/* Core Supplier *************/
create index supplier.ix_alert_batch_app_sid on supplier.alert_batch (app_sid);
create index supplier.ix_all_company_country_code on supplier.all_company (country_code);
create index supplier.ix_all_company_app_sid on supplier.all_company (app_sid);
create index supplier.ix_product_part_product_id on supplier.product_part (product_id);
create index supplier.ix_product_part_part_type_id on supplier.product_part (part_type_id);
create index supplier.ix_product_part_parent_id on supplier.product_part (parent_id);
create index supplier.ix_product_quest_group_status_ on supplier.product_questionnaire_group (group_status_id);
create index supplier.ix_product_quest_group_id on supplier.product_questionnaire_group (group_id);
create index supplier.ix_product_revis_group_id on supplier.product_revision_tag (group_id);
create index supplier.ix_product_revis_tag_id on supplier.product_revision_tag (tag_id);
create index supplier.ix_product_sales_period_id on supplier.product_sales_volume (period_id);
create index supplier.ix_product_tag_tag_id on supplier.product_tag (tag_id);
create index supplier.ix_questionnaire_workflow_type on supplier.questionnaire_group (workflow_type_id);
create index supplier.ix_questionnaire_questionnaire on supplier.questionnaire_tag (questionnaire_id);
create index supplier.ix_tag_group_mem_tag_id on supplier.tag_group_member (tag_id);
create index supplier.ix_tag_tag_attri_tag_attribute on supplier.tag_tag_attribute (tag_attribute_id);
create index supplier.ix_unit_unit_type_id on supplier.unit (unit_type_id);
create index supplier.ix_user_report_s_tag_id on supplier.user_report_sales_types (tag_id);
create index supplier.ix_user_report_s_period_id on supplier.user_report_settings (period_id);
create index supplier.ix_customer_peri_period_id on supplier.customer_period (period_id);
create index supplier.ix_questionnaire_group_id on supplier.questionnaire_group_membership (group_id);
create index supplier.ix_questionnaire_request_statu on supplier.questionnaire_request (request_status_id);
/* ****************************/

/* OLD Chain *****************
create index supplier.ix_all_procurer__supplier_comp on supplier.all_procurer_supplier (supplier_company_sid);
create index supplier.ix_all_procurer__currency_code on supplier.all_procurer_supplier (currency_code);
create index supplier.ix_all_procurer__app_sid on supplier.all_procurer_supplier (app_sid);
create index supplier.ix_all_product_supplier_comp on supplier.all_product (supplier_company_sid);
create index supplier.ix_all_product_q_questionnaire on supplier.all_product_questionnaire (questionnaire_id);
create index supplier.ix_all_product_q_question_stat on supplier.all_product_questionnaire (questionnaire_status_id);
create index supplier.ix_cert_scheme_s_cert_scheme_i on supplier.cert_scheme_source_cat_mapping (cert_scheme_id);
create index supplier.ix_chain_questio_quick_survey_ on supplier.chain_questionnaire (app_sid, quick_survey_sid);
create index supplier.ix_chain_questio_app_sid on supplier.chain_questionnaire (app_sid);
create index supplier.ix_company_part_company_sid on supplier.company_part (company_sid);
create index supplier.ix_company_part_parent_id on supplier.company_part (parent_id);
create index supplier.ix_company_part_part_type_id on supplier.company_part (part_type_id);
create index supplier.ix_company_quest_chain_questio on supplier.company_questionnaire_response (chain_questionnaire_id);
create index supplier.ix_company_quest_app_sid on supplier.company_questionnaire_response (app_sid);
create index supplier.ix_company_quest_response_stat on supplier.company_questionnaire_response (response_status_id);
create index supplier.ix_company_tag_company_sid on supplier.company_tag (company_sid);
create index supplier.ix_company_user_csr_user_sid on supplier.company_user (app_sid, csr_user_sid);
create index supplier.ix_company_user_user_profile_ on supplier.company_user (user_profile_visibility_id);
create index supplier.ix_contact_owner_company on supplier.contact (owner_company_sid);
create index supplier.ix_contact_existing_comp on supplier.contact (existing_company_sid);
create index supplier.ix_contact_exist_comp_usr on supplier.contact (existing_company_sid, existing_user_sid, app_sid);
create index supplier.ix_contact_registered_to on supplier.contact (registered_to_company_sid, registered_as_user_sid, app_sid);
create index supplier.ix_contact_contact_state on supplier.contact (contact_state_id);
create index supplier.ix_contact_country_code on supplier.contact (country_code);
create index supplier.ix_contact_currency_code on supplier.contact (currency_code);
create index supplier.ix_contact_app_sid on supplier.contact (app_sid);

create index supplier.ix_invite_sent_by_compa on supplier.invite (sent_by_company_sid, sent_by_user_sid, app_sid);
create index supplier.ix_invite_sent_to_conta on supplier.invite (sent_to_contact_id, sent_by_company_sid, app_sid);
create index supplier.ix_invite_invite_status on supplier.invite (invite_status_id);
create index supplier.ix_invite_questi_chain_questio on supplier.invite_questionnaire (chain_questionnaire_id);
create index supplier.ix_invite_questi_last_msg_from on supplier.invite_questionnaire (last_msg_from_company_sid, last_msg_from_user_sid, app_sid);
create index supplier.ix_message_company_sid on supplier.message (company_sid);
create index supplier.ix_message_user_sid on supplier.message (app_sid, user_sid);
create index supplier.ix_message_group_sid on supplier.message (group_sid);
create index supplier.ix_message_message_templ on supplier.message (message_template_id);
create index supplier.ix_message_conta_contact_id_ow on supplier.message_contact (contact_id, owner_company_sid, app_sid);
create index supplier.ix_message_procu_procurer_comp on supplier.message_procurer_supplier (procurer_company_sid, supplier_company_sid, app_sid);
create index supplier.ix_message_quest_chain_questio on supplier.message_questionnaire (chain_questionnaire_id);
create index supplier.ix_message_templ_message_templ on supplier.message_template (message_template_format_id);
create index supplier.ix_message_user_user_sid on supplier.message_user (app_sid, user_sid);
create index supplier.ix_quest_procurer_supplier on supplier.questionnaire_request (procurer_company_sid, supplier_company_sid, app_sid);
create index supplier.ix_quest_supplier_chain_q on supplier.questionnaire_request (supplier_company_sid, chain_questionnaire_id);
create index supplier.ix_quest_supplier_user on supplier.questionnaire_request (supplier_company_sid, supplier_user_sid, app_sid);
create index supplier.ix_quest_procurer_user on supplier.questionnaire_request (procurer_company_sid, procurer_user_sid, app_sid);
create index supplier.ix_quest_supplier_rel_by on supplier.questionnaire_request (supplier_company_sid, released_by_user_sid, app_sid);
*****************************/


/* Wood *****************
create index supplier.ix_wood_part_des_post_cert_sch on supplier.wood_part_description (post_cert_scheme_id);
create index supplier.ix_wood_part_des_pre_cert_sche on supplier.wood_part_description (pre_cert_scheme_id);
create index supplier.ix_wood_part_des_pre_recycled_ on supplier.wood_part_description (pre_recycled_country_code);
create index supplier.ix_wood_part_des_post_recycled on supplier.wood_part_description (post_recycled_country_code);
create index supplier.ix_wood_part_des_pre_recyc_dgi on supplier.wood_part_description (pre_recycled_doc_group_id);
create index supplier.ix_wood_part_des_post_recy_dgi on supplier.wood_part_description (post_recycled_doc_group_id);
create index supplier.ix_wood_part_des_weight_unit_i on supplier.wood_part_description (weight_unit_id);
create index supplier.ix_wood_part_woo_bleaching_pro on supplier.wood_part_wood (bleaching_process_id);
create index supplier.ix_wood_part_woo_cert_scheme_i on supplier.wood_part_wood (cert_scheme_id);
create index supplier.ix_wood_part_woo_country_code on supplier.wood_part_wood (country_code);
create index supplier.ix_wood_part_woo_cert_doc_grou on supplier.wood_part_wood (cert_doc_group_id);
create index supplier.ix_wood_part_woo_forest_source on supplier.wood_part_wood (forest_source_cat_code);
create index supplier.ix_wood_part_woo_species_code on supplier.wood_part_wood (species_code);
create index supplier.ix_wood_part_woo_wrme_wood_typ on supplier.wood_part_wood (wrme_wood_type_id);
*****************************/


/* Natural products *****************
create index supplier.ix_np_component__country_of_or on supplier.np_component_description (country_of_origin);
create index supplier.ix_np_component__np_kingdom_id on supplier.np_component_description (np_kingdom_id);
create index supplier.ix_np_component__np_production on supplier.np_component_description (np_production_process_group_id);
create index supplier.ix_np_part_evide_document_grou on supplier.np_part_evidence (document_group_id);
create index supplier.ix_np_part_evide_np_evidence_c on supplier.np_part_evidence (np_evidence_class_id);
create index supplier.ix_np_part_evide_np_evidence_t on supplier.np_part_evidence (np_evidence_type_id);
create index supplier.ix_np_pp_group_m_np_production on supplier.np_pp_group_member (np_production_process_id);

*****************************/

/* Green tick *****************
create index supplier.ix_gt_access_pac_gt_access_vis on supplier.gt_access_pack_mapping (gt_access_visc_type_id);
create index supplier.ix_gt_battery_gt_battery_ch on supplier.gt_battery (gt_battery_chem_id);
create index supplier.ix_gt_battery_ba_gt_battery_ty on supplier.gt_battery_battery_type (gt_battery_type_id);
create index supplier.ix_gt_country_ma_country_code on supplier.gt_country_made_in (country_code);
create index supplier.ix_gt_country_ma_product_id_re on supplier.gt_country_made_in (product_id, revision_id);
create index supplier.ix_gt_country_ma_gt_transport_ on supplier.gt_country_made_in (gt_transport_type_id);
create index supplier.ix_gt_country_re_gt_region_id on supplier.gt_country_region (gt_region_id);
create index supplier.ix_gt_country_so_country_code on supplier.gt_country_sold_in (country_code);
create index supplier.ix_gt_country_so_product_id_re on supplier.gt_country_sold_in (product_id, revision_id);
create index supplier.ix_gt_endangered_gt_endangered on supplier.gt_endangered_prod_class_map (gt_endangered_species_id);
create index supplier.ix_gt_fa_anc_mat_product_id_re on supplier.gt_fa_anc_mat (product_id, revision_id);
create index supplier.ix_gt_fa_endange_gt_endangered on supplier.gt_fa_endangered_sp (gt_endangered_species_id);
create index supplier.ix_gt_fa_haz_che_product_id_re on supplier.gt_fa_haz_chem (product_id, revision_id);
create index supplier.ix_gt_fa_palm_in_product_id_re on supplier.gt_fa_palm_ind (product_id, revision_id);
create index supplier.ix_gt_fa_wsr_gt_water_stre on supplier.gt_fa_wsr (gt_water_stress_region_id);
create index supplier.ix_gt_fd_answer__gt_fd_scheme_ on supplier.gt_fd_answer_scheme (gt_fd_scheme_id);
create index supplier.ix_gt_fd_answer__product_id_re on supplier.gt_fd_answer_scheme (product_id, revision_id);
create index supplier.ix_gt_fd_endange_gt_endangered on supplier.gt_fd_endangered_sp (gt_endangered_species_id);
create index supplier.ix_gt_fd_ingredi_gt_fd_ingred_ on supplier.gt_fd_ingredient (gt_fd_ingred_prov_type_id);
create index supplier.ix_gt_fd_ingredi_gt_fd_in_type on supplier.gt_fd_ingredient (gt_fd_ingred_type_id);
create index supplier.ix_gt_fd_ingredi_gt_water_stre on supplier.gt_fd_ingredient (gt_water_stress_region_id);
create index supplier.ix_gt_fd_ingred__gt_fd_ingred_ on supplier.gt_fd_ingred_type (gt_fd_ingred_group_id);
create index supplier.ix_gt_fd_palm_in_gt_palm_ingre on supplier.gt_fd_palm_ind (gt_palm_ingred_id);
create index supplier.ix_gt_food_anc_m_product_id_re on supplier.gt_food_anc_mat (product_id, revision_id);
create index supplier.ix_gt_food_answe_data_quality_ on supplier.gt_food_answers (data_quality_type_id);
create index supplier.ix_gt_food_answe_gt_fd_portion on supplier.gt_food_answers (gt_fd_portion_type_id);
create index supplier.ix_gt_food_answe_gt_water_stre on supplier.gt_food_answers (gt_water_stress_region_id);
create index supplier.ix_gt_food_sa_q_gt_sa_questio on supplier.gt_food_sa_q (gt_sa_question_id);
create index supplier.ix_gt_formulatio_data_quality_ on supplier.gt_formulation_answers (data_quality_type_id);
create index supplier.ix_gt_formulatio_bs_document_g on supplier.gt_formulation_answers (bs_document_group);
create index supplier.ix_gt_link_produ_link_product_ on supplier.gt_link_product (link_product_id);
create index supplier.ix_gt_link_produ_product_id_re on supplier.gt_link_product (product_id, revision_id);
create index supplier.ix_gt_material_gt_material_g on supplier.gt_material (gt_material_group_id);
create index supplier.ix_gt_mat_man_ma_gt_manufac_ty on supplier.gt_mat_man_mappiing (gt_manufac_type_id);
create index supplier.ix_gt_packaging__data_quality_ on supplier.gt_packaging_answers (data_quality_type_id);
create index supplier.ix_gt_packaging__pack_style_ty on supplier.gt_packaging_answers (pack_style_type);
create index supplier.ix_gt_packaging__gt_access_pac on supplier.gt_packaging_answers (gt_access_pack_type_id);
create index supplier.ix_gt_packaging__gt_gift_cont_ on supplier.gt_packaging_answers (gt_gift_cont_type_id);
create index supplier.ix_gt_packaging__gt_pack_layer on supplier.gt_packaging_answers (gt_pack_layers_type_id);
create index supplier.ix_gt_packaging__gt_trans_pack on supplier.gt_packaging_answers (gt_trans_pack_type_id);
create index supplier.ix_gt_pack_item_product_id_re on supplier.gt_pack_item (product_id, revision_id);
create index supplier.ix_gt_pack_item_gt_pack_mater on supplier.gt_pack_item (gt_pack_material_type_id);
create index supplier.ix_gt_pack_item_gt_pack_shape on supplier.gt_pack_item (gt_pack_shape_type_id);
create index supplier.ix_gt_pda_anc_ma_product_id_re on supplier.gt_pda_anc_mat (product_id, revision_id);
create index supplier.ix_gt_pda_batter_gt_battery_co on supplier.gt_pda_battery (gt_battery_code_id);
create index supplier.ix_gt_pda_batter_gt_battery_us on supplier.gt_pda_battery (gt_battery_use_id);
create index supplier.ix_gt_pda_batter_product_id_re on supplier.gt_pda_battery (product_id, revision_id);
create index supplier.ix_gt_pda_endang_gt_endangered on supplier.gt_pda_endangered_sp (gt_endangered_species_id);
create index supplier.ix_gt_pda_hc_ite_gt_pda_haz_ch on supplier.gt_pda_hc_item (gt_pda_haz_chem_id);
create index supplier.ix_gt_pda_hc_ite_gt_pda_materi on supplier.gt_pda_hc_item (gt_pda_material_item_id, product_id, revision_id);
create index supplier.ix_gt_pda_hc_mat_gt_pda_haz_ch on supplier.gt_pda_hc_mat_map (gt_pda_haz_chem_id);
create index supplier.ix_gt_pda_main_p_product_id_re on supplier.gt_pda_main_power (product_id, revision_id);
create index supplier.ix_gt_pda_materi_gt_manufac_ty on supplier.gt_pda_material_item (gt_manufac_type_id);
create index supplier.ix_gt_pda_materi_gt_material_i on supplier.gt_pda_material_item (gt_material_id);
create index supplier.ix_gt_pda_materi_gt_pda_accred on supplier.gt_pda_material_item (gt_pda_accred_type_id);
create index supplier.ix_gt_pda_materi_gt_pda_proven on supplier.gt_pda_material_item (gt_pda_provenance_type_id);
create index supplier.ix_gt_pda_materi_product_id_re on supplier.gt_pda_material_item (product_id, revision_id);
create index supplier.ix_gt_pda_materi_gt_water_stre on supplier.gt_pda_material_item (gt_water_stress_region_id);
create index supplier.ix_gt_pda_mat_pr_gt_pda_proven on supplier.gt_pda_mat_prov_mapping (gt_pda_provenance_type_id);
create index supplier.ix_gt_pda_palm_i_gt_palm_ingre on supplier.gt_pda_palm_ind (gt_palm_ingred_id);
create index supplier.ix_gt_pda_prov_a_gt_pda_accred on supplier.gt_pda_prov_acc_mapping (gt_pda_accred_type_id);
create index supplier.ix_gt_pdesign_an_data_quality_ on supplier.gt_pdesign_answers (data_quality_type_id);
create index supplier.ix_gt_pdesign_an_gt_pda_durabi on supplier.gt_pdesign_answers (gt_pda_durability_type_id);
create index supplier.ix_gt_product_an_data_quality_ on supplier.gt_product_answers (data_quality_type_id);
create index supplier.ix_gt_product_an_ct_doc_group_ on supplier.gt_product_answers (ct_doc_group_id);
create index supplier.ix_gt_product_an_consumer_advi on supplier.gt_product_answers (consumer_advice_3_dg);
create index supplier.ix_gt_product_an_consumer_adv4 on supplier.gt_product_answers (consumer_advice_4_dg);
create index supplier.ix_gt_product_an_sustain_asse1 on supplier.gt_product_answers (sustain_assess_1_dg);
create index supplier.ix_gt_product_an_sustain_asse2 on supplier.gt_product_answers (sustain_assess_2_dg);
create index supplier.ix_gt_product_an_sustain_asse3 on supplier.gt_product_answers (sustain_assess_3_dg);
create index supplier.ix_gt_product_an_sustain_asse4 on supplier.gt_product_answers (sustain_assess_4_dg);
create index supplier.ix_gt_product_an_gt_product_ra on supplier.gt_product_answers (gt_product_range_id);
create index supplier.ix_gt_product_ty_gt_access_vis on supplier.gt_product_type (gt_access_visc_type_id);
create index supplier.ix_gt_product_ty_gt_product_cl on supplier.gt_product_type (gt_product_class_id);
create index supplier.ix_gt_product_ty_gt_product_ty on supplier.gt_product_type (gt_product_type_group_id);
create index supplier.ix_gt_product_ty_gt_water_use_ on supplier.gt_product_type (gt_water_use_type_id);
create index supplier.ix_gt_sa_ingred__gt_fd_ingred_ on supplier.gt_sa_ingred_prod_type (gt_fd_ingred_type_id);
create index supplier.ix_gt_sa_questio_gt_sa_issue_i on supplier.gt_sa_question (gt_sa_issue_id);
create index supplier.ix_gt_sa_q_prod__gt_product_ty on supplier.gt_sa_q_prod_type (gt_product_type_id);
create index supplier.ix_gt_score_log_product_id on supplier.gt_score_log (product_id);
create index supplier.ix_gt_score_log_gt_score_type on supplier.gt_score_log (gt_score_type_id);
create index supplier.ix_gt_shape_mate_gt_pack_mater on supplier.gt_shape_material_mapping (gt_pack_material_type_id);
create index supplier.ix_gt_supplier_a_data_quality_ on supplier.gt_supplier_answers (data_quality_type_id);
create index supplier.ix_gt_supplier_a_sust_doc_grou on supplier.gt_supplier_answers (sust_doc_group_id);
create index supplier.ix_gt_supplier_a_gt_sus_relati on supplier.gt_supplier_answers (gt_sus_relation_type_id);
create index supplier.ix_gt_tag_produc_tag_id on supplier.gt_tag_product_type (tag_id);
create index supplier.ix_gt_target_sco_gt_product_ra on supplier.gt_target_scores (gt_product_range_id);
create index supplier.ix_gt_target_sco_gt_product_ty on supplier.gt_target_scores (gt_product_type_id);
create index supplier.ix_gt_target_sco_app_sid on supplier.gt_target_scores_log (app_sid);
create index supplier.ix_gt_target_scl_gt_product_ra on supplier.gt_target_scores_log (gt_product_range_id);
create index supplier.ix_gt_target_scl_gt_product_ty on supplier.gt_target_scores_log (gt_product_type_id);
create index supplier.ix_gt_transport__data_quality_ on supplier.gt_transport_answers (data_quality_type_id);
create index supplier.ix_gt_trans_item_gt_trans_mate on supplier.gt_trans_item (gt_trans_material_type_id);
create index supplier.ix_gt_trans_item_product_id_re on supplier.gt_trans_item (product_id, revision_id);
create index supplier.ix_gt_trans_regi_gt_transport_ on supplier.gt_trans_region_scoring (gt_transport_type_id);
create index supplier.ix_gt_user_repor_csr_user_sid on supplier.gt_user_report_product_ranges (csr_user_sid);
create index supplier.ix_gt_user_repty_csr_user_sid on supplier.gt_user_report_product_types (csr_user_sid);
create index supplier.ix_tag_group_fil_gt_product_gr on supplier.tag_group_filter (gt_product_group_id);
*****************************/















@update_tail

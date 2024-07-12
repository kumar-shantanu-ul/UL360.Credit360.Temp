create index donations.ix_budget_currency_code on donations.budget (currency_code);
create index donations.ix_budget_region_group_ on donations.budget (app_sid, region_group_sid);
create index donations.ix_budget_scheme_sid on donations.budget (app_sid, scheme_sid);
create index donations.ix_budget_consta_constant_id on donations.budget_constant (app_sid, constant_id);
create index donations.ix_customer_defa_currency_code on donations.customer_default_exrate (currency_code);
create index donations.ix_customer_opti_default_count on donations.customer_options (default_country);
create index donations.ix_customer_opti_default_curre on donations.customer_options (default_currency);
create index donations.ix_customer_opti_default_field on donations.customer_options (app_sid, default_field);
create index donations.ix_custom_field__dependent_fie on donations.custom_field_dependency (app_sid, dependent_field_num);
create index donations.ix_donation_budget_id on donations.donation (app_sid, budget_id);
create index donations.ix_donation_last_status_c on donations.donation (app_sid, last_status_changed_by);
create index donations.ix_donation_entered_by_si on donations.donation (app_sid, entered_by_sid);
create index donations.ix_donation_allocated_fro on donations.donation (app_sid, allocated_from_donation_id);
create index donations.ix_donation_donation_stat on donations.donation (app_sid, donation_status_sid);
create index donations.ix_donation_recipient_sid on donations.donation (app_sid, recipient_sid);
create index donations.ix_donation_scheme_sid on donations.donation (app_sid, scheme_sid);
create index donations.ix_donation_doc_document_sid on donations.donation_doc (app_sid, document_sid);
create index donations.ix_donation_tag_tag_id on donations.donation_tag (app_sid, tag_id);
create index donations.ix_exclude_tag_scheme_sid on donations.exclude_tag (app_sid, scheme_sid);
create index donations.ix_exclude_tag_tag_id on donations.exclude_tag (app_sid, tag_id);
create index donations.ix_filter_csr_user_sid on donations.filter (app_sid, csr_user_sid);
create index donations.ix_letter_body_r_letter_body_t on donations.letter_body_region_group (app_sid, letter_body_text_id, donation_status_sid);
create index donations.ix_letter_body_t_donation_stat on donations.letter_body_text (app_sid, donation_status_sid);
create index donations.ix_recipient_country_code on donations.recipient (country_code);
create index donations.ix_recipient_parent_sid on donations.recipient (app_sid, parent_sid);
create index donations.ix_recipient_tag_tag_id on donations.recipient_tag (app_sid, tag_id);
create index donations.ix_region_group_letter_templa on donations.region_group (app_sid, letter_template_id);
create index donations.ix_region_group__region_group_ on donations.region_group_member (app_sid, region_group_sid);
create index donations.ix_region_group__recipient_sid on donations.region_group_recipient (app_sid, recipient_sid);
create index donations.ix_scheme_donati_donation_stat on donations.scheme_donation_status (app_sid, donation_status_sid);
create index donations.ix_scheme_field_scheme_sid on donations.scheme_field (app_sid, scheme_sid);
create index donations.ix_scheme_tag_gr_tag_group_sid on donations.scheme_tag_group (app_sid, tag_group_sid);
create index donations.ix_tag_group_mem_tag_id on donations.tag_group_member (app_sid, tag_id);
create index donations.ix_transition_from_donation on donations.transition (app_sid, from_donation_status_sid);
create index donations.ix_transition_to_donation_s on donations.transition (app_sid, to_donation_status_sid);
create index donations.ix_user_fieldset_csr_user_sid on donations.user_fieldset (app_sid, csr_user_sid);
create index donations.ix_user_fieldset_user_fieldset on donations.user_fieldset_field (app_sid, user_fieldset_id);
create index donations.ix_recipient_pos_postit_id on donations.recipient_postit (app_sid, postit_id);

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

create index donations.ix_customer_opti_fc_being_proc on donations.customer_options (app_sid, fc_being_processed_tag_id);
create index donations.ix_customer_opti_fc_reconciled on donations.customer_options (app_sid, fc_reconciled_tag_id);
create index donations.ix_fc_tag_tag_id on donations.fc_tag (app_sid, tag_id);

create index donations.ix_scheme_donati_scheme_sid on donations.scheme_donation_status (app_sid, scheme_sid);
create index donations.ix_fc_default_ta_tag_id on donations.fc_default_tag (app_sid, tag_id);
create index donations.ix_region_filter_region_tag_gr on donations.region_filter_tag_group (app_sid, region_tag_group_id);

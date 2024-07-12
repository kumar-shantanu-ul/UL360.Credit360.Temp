grant select, references on csr.csr_user to ct;
grant select, references on csr.customer to ct;
grant select on csr.portlet to ct;
grant all on csr.tab_portlet to ct;
grant all on csr.tab_group to ct;
grant all on csr.tab to ct;
grant all on csr.tab_user to ct;
grant select on csr.tab_id_seq to ct;
grant select on csr.customer_portlet to ct;
grant select, references on csr.worksheet to ct;
grant select on csr.worksheet_column_type to ct;
grant select, references on csr.worksheet_row to ct;
grant select, references on csr.worksheet_value_map to ct;
grant select on csr.worksheet_value_map_value to ct;
grant select, references, insert on csr.alert_frame to ct;
grant select, references, insert on csr.customer_alert_type to ct;
grant select on csr.default_alert_frame to ct;
grant select on csr.alert_frame_id_seq to ct;
grant select on csr.std_alert_type to ct;
grant select on csr.customer_alert_type_id_seq to ct;

grant select, references on chain.company to ct;
grant all on chain.customer_options to ct;
grant select, references on chain.file_upload to ct;
grant select, references on chain.worksheet_file_upload to ct;
grant select, references on chain.chain_user to ct;
grant select, references on chain.invitation to ct;
grant select, references on chain.questionnaire to ct;
grant select, references on chain.questionnaire_type to ct;
grant select, references on chain.supplier_relationship to ct;
grant select, references on chain.company_type to ct;
grant execute on chain.T_STRING_LIST to ct;
grant execute on chain.T_CARD_ACTION_LIST to ct;
grant execute on chain.T_CARD_ACTION_ROW to ct;


grant select, references on postcode.country to ct;

grant select, references on aspen2.filecache to ct;

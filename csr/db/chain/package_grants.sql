grant execute on chain.chain_pkg to ct;
grant execute on chain.capability_pkg to ct;
grant execute on chain.company_pkg to ct;
grant execute on chain.company_user_pkg to ct;
grant execute on chain.helper_pkg to ct;
grant execute on chain.upload_pkg to ct;
grant execute on chain.excel_pkg to ct;
grant execute on chain.setup_pkg to ct;
grant execute on chain.card_pkg to ct;
grant execute on chain.questionnaire_pkg to ct;
grant execute on chain.type_capability_pkg to ct;

grant select on chain.v$chain_host to csr;
grant select on chain.v$company_user to csr;
grant select on chain.v$company to csr;
grant select on chain.v$questionnaire_share to csr;
grant select on chain.v$chain_user to csr;
grant select on chain.v$company_member to csr;
grant select on chain.v$questionnaire_share to csr;
grant select on chain.v$questionnaire_type_status to csr;
grant select on chain.v$filter_value to csr;
grant select on chain.v$filter_field to csr;
grant select on chain.v$purchaser_involvement to csr;
grant select on chain.v$company_admin to csr;
grant select on chain.v$company_reference to CSR;
grant select on chain.v$current_sup_rel_score to csr;


GRANT EXECUTE ON chain.company_filter_pkg TO csr;
grant execute on chain.company_pkg to security, csr;
grant execute on chain.chain_pkg to csr;
grant execute on chain.chain_pkg to web_user;
grant execute on chain.chain_link_pkg to csr;
grant execute on chain.card_pkg to csr;
grant execute on chain.capability_pkg to csr;
grant execute on chain.type_capability_pkg to csr;
grant execute on chain.newsflash_pkg to csr;
grant execute on chain.company_pkg to csr;
grant execute on chain.helper_pkg to csr;
grant execute on chain.company_user_pkg to csr;
grant execute on chain.message_pkg to csr;
grant execute on chain.filter_pkg to security;
grant execute on chain.filter_pkg to csr;
grant execute on chain.filter_pkg to cms;
grant execute on chain.questionnaire_pkg to csr;
grant execute on chain.questionnaire_security_pkg to csr;
grant execute on chain.uninvited_pkg to security;
grant execute on chain.upload_pkg to security;
grant execute on chain.setup_pkg to csr;
grant execute on chain.company_type_pkg to csr;
grant execute on chain.plugin_pkg to csr;
GRANT EXECUTE ON chain.company_tag_pkg to csr;
GRANT EXECUTE ON chain.higg_pkg TO csr;
GRANT EXECUTE on chain.higg_setup_pkg TO csr;
GRANT execute ON chain.company_score_pkg TO csr;
GRANT execute ON chain.company_score_pkg TO web_user;
GRANT execute on chain.product_type_pkg to csr;
GRANT execute ON chain.product_report_pkg TO csr;
GRANT EXECUTE ON chain.product_metric_report_pkg TO cms;
GRANT EXECUTE ON chain.product_metric_pkg TO csr;
GRANT EXECUTE ON chain.business_relationship_pkg TO csr;
GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;

GRANT EXECUTE ON chain.integration_pkg TO csr;
GRANT EXECUTE ON chain.integration_pkg TO web_user;


grant execute on chain.chain_pkg to campaigns;

GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_TABLE TO CSR;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_ROW TO CSR;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_TABLE TO CMS;
GRANT EXECUTE ON CHAIN.T_FILTERED_OBJECT_ROW TO CMS;
grant select on CHAIN.filter_value_id_seq to CSR;
GRANT EXECUTE ON chain.T_NUMERIC_TABLE TO csr;
GRANT EXECUTE ON chain.supplier_flow_pkg TO CSR;
grant execute on chain.t_filter_agg_type_table TO csr;
grant execute on chain.t_filter_agg_type_row TO csr;
grant execute on chain.t_filter_agg_type_thres_table TO csr;
grant execute on chain.t_filter_agg_type_thres_row TO csr;
grant execute on chain.t_filter_agg_type_table TO cms;
grant execute on chain.t_filter_agg_type_row TO cms;
grant execute on chain.t_filter_agg_type_thres_table TO cms;
grant execute on chain.t_filter_agg_type_thres_row TO cms;
@@web_grants

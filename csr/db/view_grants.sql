grant select on csr.v$current_user_cover to cms;
grant select on csr.v$flow_item to cms with grant option;
grant select on csr.v$ind to cms;
grant select on csr.v$region to cms;
grant select on csr.v$user_flow_item to cms with grant option;

grant select on csr.v$ind to actions;
grant select on csr.v$region to actions;

grant select on csr.v$postit to donations;
grant select on csr.v$region to donations;
GRANT SELECT, REFERENCES ON csr.v$tag_group TO donations;
GRANT SELECT, REFERENCES ON csr.v$tag TO donations;

grant select on csr.v$audit to chain;
grant select on csr.v$autocreate_user to chain;
grant select on csr.v$csr_user TO CHAIN;
grant select on csr.v$customer_lang TO chain;
grant select on csr.v$flow_capability to chain;
grant select on csr.v$flow_item to chain;
grant select on csr.v$flow_item_role_member to chain;
grant select on csr.v$flow_item_transition to chain;
grant select on csr.v$flow_item_trans_role_member to chain;
grant select on csr.v$ind to chain;
grant select on csr.v$open_flow_item_gen_alert to chain;
grant select on csr.v$quick_survey_response to chain;
grant select on csr.v$region to chain with grant option;
grant select on csr.v$supplier_score to chain;
grant select on csr.v$tag to chain;
grant select on csr.v$tag_group to chain;

grant select on csr.sheet_with_last_action to chem;
grant select on csr.v$ind to chem;
grant select on csr.v$open_flow_item_gen_alert to chem;
grant select on csr.v$region to chem;

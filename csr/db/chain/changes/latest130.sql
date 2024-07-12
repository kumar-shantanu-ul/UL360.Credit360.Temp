define version=130
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select on csr.superadmin to chain;
grant select, delete on csr.tab_portlet to chain;
grant select, delete on csr.tab_user to chain;
grant select, delete on csr.tab_group to chain;
grant select, delete on csr.tab to chain;
grant select on csr.portlet to chain;
grant select, delete, insert on csr.customer_portlet to chain;
grant execute on csr.portlet_pkg to chain;
grant execute on csr.alert_pkg to chain;
grant select on csr.alert_frame to chain;
grant select, insert, delete on csr.alert_template to chain;
grant select, insert, delete on csr.alert_template_body to chain;
grant select, insert, delete on csr.customer_alert_type to chain;
grant select, insert on csr.customer_region_type to chain;
grant select on csr.region_tree to chain;
grant select, insert on csr.csr_user to chain;
grant update on csr.customer to chain;
connect aspen2/aspen2@&_CONNECT_IDENTIFIER
grant select on aspen2.translation_set to chain;
connect chain/chain@&_CONNECT_IDENTIFIER

@update_tail

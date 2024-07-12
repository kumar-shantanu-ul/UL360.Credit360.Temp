-- Please update version.sql too -- this keeps clean builds in sync
define version=2225
@update_header

grant select on csr.default_alert_template_body to chain;
grant execute on csr.plugin_pkg to chain;
grant execute on csr.calendar_pkg to chain;

@..\chain\setup_pkg
@..\chain\setup_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1942
@update_header

grant execute on csr.flow_pkg to chain;

grant select on csr.flow_item to chain;
grant select on csr.flow_state to chain;
grant select on csr.flow_state_log to chain;

grant select on cms.tab to chain;

@../chain/flow_form_pkg
@../chain/flow_form_body

@../flow_pkg
@../flow_body

grant execute on chain.flow_form_pkg to web_user;

@update_tail

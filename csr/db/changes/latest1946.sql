-- Please update version.sql too -- this keeps clean builds in sync
define version=1946
@update_header

grant select on csr.flow_item to chain;
grant select on csr.flow_state to chain;
grant select on csr.flow_state_log to chain;
grant select on csr.flow to chain;
grant select on csr.flow_state_role to chain;

@update_tail

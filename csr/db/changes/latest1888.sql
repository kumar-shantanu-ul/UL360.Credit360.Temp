-- Please update version.sql too -- this keeps clean builds in sync
define version=1888
@update_header

GRANT EXECUTE ON csr.scenario_run_pkg TO web_user;

@../scenario_run_pkg
@../scenario_run_body
@../csr_data_pkg
@../csr_data_body

@update_tail


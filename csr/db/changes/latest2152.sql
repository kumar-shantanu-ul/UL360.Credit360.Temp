-- Please update version.sql too -- this keeps clean builds in sync
define version=2152
@update_header

CREATE TABLE CSR.scenario_like_for_like_rule (
	app_sid number(10) 				default sys_context('security', 'app') not null,
	scenario_sid					number(10) not null,
	rule_id							number(10) not null,
	applies_to_region_type			number(10) not null,
	contiguous_data_check_type		number(10) not null,
	CONSTRAINT pk_scn_like_for_like_rule PRIMARY KEY (app_sid, scenario_sid, rule_id),
	CONSTRAINT fk_scn_lfl_rule_scn_rule FOREIGN KEY (app_sid, scenario_sid, rule_id)
	REFERENCES csr.scenario_rule (app_sid, scenario_sid, rule_id)
);

@../scenario_pkg
@../scenario_body
@../csr_data_body

@update_tail

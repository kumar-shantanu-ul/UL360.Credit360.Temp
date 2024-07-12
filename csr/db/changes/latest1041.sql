-- Please update version.sql too -- this keeps clean builds in sync
define version=1041
@update_header

CREATE TABLE CSR.SCENARIO_RULE_LIKE_CONTIG_IND (
	APP_SID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SCENARIO_SID	NUMBER(10) NOT NULL,
	RULE_ID			NUMBER(10) NOT NULL,
	IND_SID			NUMBER(10) NOT NULL
);
ALTER TABLE CSR.SCENARIO_RULE_LIKE_CONTIG_IND ADD CONSTRAINT PK_SCENARIO_RULE_LIKE_CTG_IND
PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID, IND_SID);
ALTER TABLE CSR.SCENARIO_RULE_LIKE_CONTIG_IND ADD CONSTRAINT FK_SCN_RL_LIKE_CTG_IND_SCN_RL
FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID) REFERENCES CSR.SCENARIO_RULE (APP_SID, SCENARIO_SID, RULE_ID);

alter table csr.customer add scenarios_enabled number(1) default 0 not null;
alter table csr.customer add constraint ck_customer_scenarios_enabled check (scenarios_enabled in (0,1));
update csr.customer set scenarios_enabled=1 where unmerged_scenario_run_sid is not null;

alter table csr.excel_export_options add scenario_pos varchar2(10) default 'Column' not null;
alter table csr.excel_export_options add constraint ck_excel_export_opts_scn_pos check (scenario_pos in ('Column','Sheet'));

@../csr_app_body
@../scenario_pkg
@../scenario_body
@../excel_export_body
@../excel_export_pkg

@update_tail

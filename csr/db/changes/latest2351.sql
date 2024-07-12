-- Please update version.sql too -- this keeps clean builds in sync
define version=2351
@update_header

alter table csr.scenario add data_source_sp varchar2(100);
update csr.scenario set data_source_sp = 'csr.stored_calc_datasource_pkg.GetUnmergedLPNormalValues' where data_source=2;
alter table csr.scenario drop constraint ck_scenario_data_source;
alter table csr.scenario add constraint ck_scenario_data_source check (
	(data_source in (0, 1) and data_source_sp is null) or 
	(data_source = 2 and data_source_sp is not null)
);

@../stored_calc_datasource_pkg
@../scenario_body

@update_tail

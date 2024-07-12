-- Please update version.sql too -- this keeps clean builds in sync
define version=916
@update_header

alter table csr.dataview_scenario_run add constraint fk_dataview_scn_run_dataview
foreign key (app_sid, dataview_sid) references csr.dataview(app_sid, dataview_sid);

@update_tail

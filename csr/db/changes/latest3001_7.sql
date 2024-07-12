-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


alter table csr.forecasting_email_sub rename constraint PK_FRCSTNG_EMAIL to pk_scenario_email_sub;
alter table csr.forecasting_email_sub rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_email_sub rename to scenario_email_sub;
alter table csr.scenario_email_sub drop constraint FK_FRCSTNG_EMAIL_FRCSTNG_SID;
alter table csr.scenario_email_sub rename constraint fk_frcstng_user_sid to fk_scenario_email_sub_user;
alter table csr.scenario_email_sub add constraint fk_scenario_email_sub_scenario
foreign key (app_sid, scenario_sid) references csr.scenario (app_sid, scenario_sid);

alter table csr.forecasting_scenario_alert rename constraint PK_FRCAST_SCEN_ALERT TO PK_SCENARIO_ALERT;
alter table csr.forecasting_scenario_alert rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_scenario_alert rename to scenario_alert;

ALTER TABLE CSR.SCENARIO_ALERT ADD CONSTRAINT FK_SCENARIO_ALERT_SCENARIO
FOREIGN KEY (APP_SID, SCENARIO_SID) REFERENCES CSR.SCENARIO (APP_SID, SCENARIO_SID);
ALTER TABLE CSR.SCENARIO_ALERT ADD CONSTRAINT FK_SCENARIO_ALERT_USER
FOREIGN KEY (APP_SID, CSR_USER_SID) REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);


alter table csr.forecasting_rule drop constraint fk_forecast_rule_slot_sid;
alter table csr.forecasting_rule add rule_id number(10) not null;
alter table csr.forecasting_rule drop constraint pk_forecast_rule drop index;
alter table csr.forecasting_rule rename column forecasting_sid to scenario_sid;
alter table csr.forecasting_rule add constraint pk_forecasting_rule primary key 
(app_sid, scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm);
alter table csr.forecasting_rule add constraint fk_forecast_rule_scenario
foreign key (app_sid, scenario_sid) references csr.scenario (app_sid, scenario_sid);

drop table csr.forecasting_indicator;
drop table csr.forecasting_region;
drop table csr.forecasting_val;
drop table csr.forecasting_slot ;

alter table csr.scenario drop column scrag_test_scenario;
alter table csrimp.scenario drop column scrag_test_scenario;

alter table csrimp.scenario add (
	DATA_SOURCE_RUN_SID				NUMBER(10),
	CREATED_BY_USER_SID				NUMBER(10) NOT NULL,
	CREATED_DTM						DATE NOT NULL,
	INCLUDE_ALL_INDS				NUMBER(1) NOT NULL
);

drop table csrimp.forecasting_val;
drop table csrimp.forecasting_indicator;
drop table csrimp.forecasting_region;

alter table csrimp.forecasting_rule add rule_id number(10) not null;
alter table csrimp.forecasting_rule drop constraint pk_forecast_rule drop index;
alter table csrimp.forecasting_rule rename column forecasting_sid to scenario_sid;
alter table csrimp.forecasting_rule add constraint pk_forecasting_rule primary key 
(csrimp_session_id, scenario_sid, rule_id, ind_sid, region_sid, start_dtm, end_dtm);

drop table csrimp.forecasting_email_sub;
CREATE TABLE CSRIMP.SCENARIO_EMAIL_SUB (
	CSRIMP_SESSION_ID			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SCENARIO_SID				NUMBER(10, 0) NOT NULL,
	CSR_USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCENARIO_EMAIL_SUB			PRIMARY KEY (CSRIMP_SESSION_ID, SCENARIO_SID, CSR_USER_SID),
	CONSTRAINT FK_SCENARIO_EMAIL_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
grant select,insert,update,delete on csrimp.scenario_email_sub to tool_user;
grant select,insert,update,delete on csrimp.forecasting_rule to tool_user;
grant select, insert, update on csr.scenario_email_sub TO csrimp;

alter table csr.scenario_run add last_run_by_user_sid number(10) default 3 not null;
alter table csr.scenario_run add constraint fk_Scenario_run_last_run_user foreign key (app_sid, last_run_by_user_sid)
references csr.csr_user (app_sid, csr_user_sid);

alter table csrimp.scenario_run add last_run_by_user_sid number(10) not null;

alter table csr.calc_job add run_by_user_sid number(10) default nvl(sys_context('SECURITY','SID'),3) not null;
alter table csr.calc_job add constraint fk_calc_job_last_run_user foreign key (app_sid, run_by_user_sid)
references csr.csr_user (app_sid, csr_user_sid);

create index csr.ix_calc_job_run_by_user_s on csr.calc_job (app_sid, run_by_user_sid);
create index csr.ix_scenario_aler_csr_user_sid on csr.scenario_alert (app_sid, csr_user_sid);
create index csr.ix_scenario_run_last_run_by_u on csr.scenario_run (app_sid, last_run_by_user_sid);

alter table csr.scenario add data_source_run_sid number(10); 
alter table csr.scenario add created_by_user_sid number(10); 
update csr.scenario set created_by_user_sid  = 3;
alter table csr.scenario modify created_by_user_sid not null;
alter table csr.scenario modify created_by_user_sid default sys_context('security', 'sid') ;
alter table csr.scenario add created_dtm date default sysdate not null;
alter table csr.scenario add include_all_inds number(1) ;
update csr.scenario set include_all_inds = 0;
alter table csr.scenario modify include_all_inds not null;
alter table csr.scenario add constraint ck_scenario_include_all_inds check (include_all_inds in (0,1));
alter table csr.scenario drop constraint ck_scenario_recalc_trig_type;
alter table csr.scenario add CONSTRAINT CK_SCENARIO_RECALC_TRIG_TYPE CHECK (RECALC_TRIGGER_TYPE IN (0, 1, 2));

alter table csr.scenario drop constraint CK_SCENARIO_DATA_SOURCE ;
alter table csr.scenario add
    CONSTRAINT CK_SCENARIO_DATA_SOURCE CHECK(
        (DATA_SOURCE IN (0, 1) AND DATA_SOURCE_SP IS NULL AND DATA_SOURCE_SP_ARGS IS NULL AND DATA_SOURCE_RUN_SID IS NULL) OR
        (DATA_SOURCE = 2 AND DATA_SOURCE_SP IS NOT NULL AND DATA_SOURCE_SP_ARGS IS NOT NULL AND DATA_SOURCE_RUN_SID IS NULL) OR
		(DATA_SOURCE = 3 AND DATA_SOURCE_SP IS NULL AND DATA_SOURCE_SP_ARGS IS NULL AND DATA_SOURCE_RUN_SID IS NOT NULL)
    );

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

insert into csr.app_lock (app_sid, lock_type) select app_sid, 4 from csr.customer;
commit;

begin
update csr.batched_import_type set assembly='Credit360.ExportImport.Import.Batched.Importers.ForecastingScenarioImporter' 
where batch_import_type_id=4;
update csr.batched_export_type set assembly='Credit360.ExportImport.Export.Batched.Exporters.ForecastingScenarioExporter'
where batch_export_type_id=15;
end;
/

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../forecasting_pkg
@../scenario_pkg
@../schema_pkg
@../csr_data_body
@../csr_app_body
@../scenario_body
@../forecasting_body
@../indicator_body
@../region_body
@../csr_user_body
@../schema_body
@../actions/scenario_body
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../enable_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail

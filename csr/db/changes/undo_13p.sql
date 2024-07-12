whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

drop table csr.period_set cascade constraint;
drop table csr.period cascade constraint;
drop table csr.period_dates cascade constraint;
drop table csr.period_interval cascade constraint;
drop table csr.period_interval_member cascade constraint;

alter table csr.ind add default_interval varchar2(1);
update csr.ind set default_interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.ind modify default_interval not null;
alter table csr.ind modify default_interval default 'y';
alter table csr.ind add constraint ck_ind_default_interval check (default_interval in ('y','h','q','m'));
alter table csr.ind drop column period_set_id;
alter table csr.ind drop column period_interval_id;

create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.default_interval, 
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

alter table csr.dataview add interval varchar2(1);
update csr.dataview set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.dataview modify interval not null;
alter table csr.dataview add constraint ck_dataview_interval check (interval in ('y','h','q','m'));
alter table csr.dataview drop column period_set_id;
alter table csr.dataview drop column period_interval_id;


alter table csr.delegation add interval varchar2(1);
update csr.delegation set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.delegation modify interval not null;
alter table csr.delegation add constraint ck_delegation_interval check (interval in ('y','h','q','m'));
alter table csr.delegation drop column period_set_id;
alter table csr.delegation drop column period_interval_id;

alter table csr.temp_delegation_detail drop column period_set_id;
alter table csr.temp_delegation_detail drop column period_interval_id;
alter table csr.temp_delegation_detail add interval varchar2(1);

alter table csr.temp_delegation_for_region drop column period_set_id;
alter table csr.temp_delegation_for_region drop column period_interval_id;
alter table csr.temp_delegation_for_region add interval varchar2(1);

alter table csr.tmp_deleg_search drop column period_set_id;
alter table csr.tmp_deleg_search drop column period_interval_id;
alter table csr.tmp_deleg_search add interval varchar2(1);

alter table csr.pending_period drop constraint ck_pending_period_dates ;

alter table csr.tpl_report add interval varchar2(1);
update csr.tpl_report set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report modify interval not null;
alter table csr.tpl_report add constraint ck_tpl_report_interval check (interval in ('y','h','q','m'));
alter table csr.tpl_report drop column period_set_id;
alter table csr.tpl_report drop column period_interval_id;

alter table csr.metric_dashboard add interval varchar2(1);
update csr.metric_dashboard set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.metric_dashboard modify interval not null;
alter table csr.metric_dashboard add constraint ck_metric_dashboard_interval check (interval in ('y','h','q','m'));
alter table csr.metric_dashboard drop column period_set_id;
alter table csr.metric_dashboard drop column period_interval_id;

drop package csr.period_pkg;

begin
	for r in (select 1 from all_constraints where owner='CSR' and table_name='VAL' and constraint_name='CK_VAL_DATES') loop
		execute immediate 'alter table csr.val drop CONSTRAINT CK_VAL_DATES';
	end loop;
end;
/

alter table csr.val add CONSTRAINT CK_VAL_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);

alter table csr.target_dashboard add interval varchar2(1);
update csr.target_dashboard set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.target_dashboard modify interval not null;
alter table csr.target_dashboard add constraint ck_target_dashboard_interval check (interval in ('y','h','q','m'));
alter table csr.target_dashboard drop column period_set_id;
alter table csr.target_dashboard drop column period_interval_id;

alter table csr.scenario add interval varchar2(1);
update csr.scenario set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.scenario modify interval not null;
alter table csr.scenario add constraint ck_scenario_interval check (interval in ('y','h','q','m'));
alter table csr.scenario drop column period_set_id;
alter table csr.scenario drop column period_interval_id;

--set serveroutput on
begin
	for r in (select type_name from all_types where owner='CSR' and type_name in (
				'T_SHEET_INFO')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE CSR.'||r.type_name;
	end loop;
end;
/

CREATE OR REPLACE TYPE CSR.T_SHEET_INFO AS 
  OBJECT ( 
	SHEET_ID		NUMBER(10,0),
	DELEGATION_SID		NUMBER(10,0),
	PARENT_DELEGATION_SID	NUMBER(10,0),
	NAME			VARCHAR2(255),
	CAN_SAVE		NUMBER(10,0),
	CAN_SUBMIT		NUMBER(10,0),
	CAN_ACCEPT		NUMBER(10,0),
	CAN_RETURN		NUMBER(10,0),
	CAN_DELEGATE		NUMBER(10,0),
	CAN_VIEW		NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR		NUMBER(10,0),
	CAN_COPY_FORWARD	NUMBER(10,0),
	LAST_ACTION_ID		NUMBER(10,0),
	START_DTM		DATE,
	END_DTM			DATE,
	INTERVAL		VARCHAR2(1),
	GROUP_BY		VARCHAR2(128),
	PERIOD_FMT		VARCHAR2(255),	
	NOTE			CLOB,
	USER_LEVEL		NUMBER(10,0),
	IS_TOP_LEVEL		NUMBER(10,0),
	IS_READ_ONLY	NUMBER(1),
	CAN_EXPLAIN		NUMBER(1)
  );
/

alter table csr.temp_alert_batch_details drop column period_set_id;
alter table csr.temp_alert_batch_details drop column period_interval_id;
alter table csr.temp_alert_batch_details add delegation_interval varchar2(1);

alter table csr.deleg_plan add interval varchar2(1);
update csr.deleg_plan set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.deleg_plan modify interval not null;
alter table csr.deleg_plan add constraint ck_deleg_plan_interval check (interval in ('y','h','q','m'));
alter table csr.deleg_plan drop column period_set_id;
alter table csr.deleg_plan drop column period_interval_id;

alter table csr.form add interval varchar2(1);
update csr.form set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.form modify interval not null;
alter table csr.form add constraint ck_form_interval check (interval in ('y','h','q','m'));
alter table csr.form drop column period_set_id;
alter table csr.form drop column period_interval_id;

alter table csr.benchmark_dashboard add interval varchar2(1);
update csr.benchmark_dashboard set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.benchmark_dashboard modify interval not null;
alter table csr.benchmark_dashboard add constraint ck_benchmark_dash_interval check (interval in ('y','h','q','m'));
alter table csr.benchmark_dashboard drop column period_set_id;
alter table csr.benchmark_dashboard drop column period_interval_id;

begin 
	for r in (select 1
				from all_constraints 
			   where constraint_name = 'FK_QS_FILTER_COND_GEN_SURVEY' 
				 and table_name = 'QS_FILTER_CONDITION_GENERAL'
				 and owner = 'CSRIMP') loop
		execute immediate 'alter table CSRIMP.QS_FILTER_CONDITION_GENERAL drop	CONSTRAINT FK_QS_FILTER_COND_GEN_SURVEY';
	end loop;
end;
/

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		dbms_output.put_line( 'truncate table csrimp.'||r.table_name );
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.ind drop column period_set_id;
alter table csrimp.ind drop column period_interval_id;

alter table csrimp.delegation drop column period_set_id;
alter table csrimp.delegation drop column period_interval_id;

alter table csrimp.form drop column period_set_id;
alter table csrimp.form drop column period_interval_id;

alter table csrimp.dataview drop column period_set_id;
alter table csrimp.dataview drop column period_interval_id;

alter table csrimp.deleg_plan drop column period_set_id;
alter table csrimp.deleg_plan drop column period_interval_id;

alter table csrimp.tpl_report drop column period_set_id;
alter table csrimp.tpl_report drop column period_interval_id;

alter table csrimp.scenario drop column period_set_id;
alter table csrimp.scenario drop column period_interval_id;

alter table csrimp.target_dashboard drop column period_set_id;
alter table csrimp.target_dashboard drop column period_interval_id;

alter table csr.delegation drop column submission_offset ;
alter table csr.delegation modify schedule_xml not null;

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.SUBMIT_CONFIRMATION_TEXT as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;

alter table csr.delegation drop constraint CK_DELEGATION_DATES ;
alter table csr.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csr.sheet drop constraint CK_SHEET_DATES;
alter table csr.sheet add CONSTRAINT CK_SHEET_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csr.tpl_report_tag_ind add interval varchar2(1);
update csr.tpl_report_tag_ind set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report_tag_ind add constraint ck_tpl_rep_tag_ind_interval check (interval in ('y','h','q','m'));
alter table csr.tpl_report_tag_ind drop column period_set_id;
alter table csr.tpl_report_tag_ind drop column period_interval_id;

alter table csr.tpl_report_tag_eval add interval varchar2(1);
update csr.tpl_report_tag_eval set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report_tag_eval add constraint ck_tpl_report_tag_eval_int check (interval in ('y','h','q','m'));
alter table csr.tpl_report_tag_eval drop column period_set_id;
alter table csr.tpl_report_tag_eval drop column period_interval_id;

alter table csr.tpl_report_tag_logging_form add interval varchar2(1);
update csr.tpl_report_tag_logging_form set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report_tag_logging_form add constraint ck_tpl_rep_tag_log_form_int check (interval in ('y','h','q','m'));
alter table csr.tpl_report_tag_logging_form drop column period_set_id;
alter table csr.tpl_report_tag_logging_form drop column period_interval_id;

alter table csr.tpl_report_tag_dataview add interval varchar2(1);
update csr.tpl_report_tag_dataview set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report_tag_dataview add constraint ck_tpl_report_tag_datavw_int check (interval in ('y','h','q','m'));
alter table csr.tpl_report_tag_dataview drop column period_set_id;
alter table csr.tpl_report_tag_dataview drop column period_interval_id;

alter table csr.tpl_report_non_compl add interval varchar2(1);
update csr.tpl_report_non_compl set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.tpl_report_non_compl add constraint ck_tpl_report_non_compl_int check (interval in ('y','h','q','m'));
alter table csr.tpl_report_non_compl drop column period_set_id;
alter table csr.tpl_report_non_compl drop column period_interval_id;

alter table csr.imp_val drop constraint CK_IMP_VAL_DATES;
alter table csr.imp_val add CONSTRAINT CK_IMP_VAL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);


alter table csrimp.tpl_report_tag_ind drop column period_set_id;
alter table csrimp.tpl_report_tag_ind drop column period_interval_id;

alter table csrimp.tpl_report_tag_eval drop column period_set_id;
alter table csrimp.tpl_report_tag_eval drop column period_interval_id;

alter table csrimp.tpl_report_tag_logging_form drop column period_set_id;
alter table csrimp.tpl_report_tag_logging_form drop column period_interval_id;

alter table csrimp.tpl_report_tag_dataview drop column period_set_id;
alter table csrimp.tpl_report_tag_dataview drop column period_interval_id;

alter table csrimp.tpl_report_non_compl drop column period_set_id;
alter table csrimp.tpl_report_non_compl drop column period_interval_id;

drop TABLE CSRIMP.PERIOD_SET;
drop TABLE CSRIMP.PERIOD;
drop TABLE CSRIMP.PERIOD_DATES;
drop TABLE CSRIMP.PERIOD_INTERVAL;
drop TABLE CSRIMP.PERIOD_INTERVAL_MEMBER;


alter table csrimp.imp_val drop constraint CK_IMP_VAL_DATES;
alter table csrimp.imp_val add CONSTRAINT CK_IMP_VAL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csrimp.val drop CONSTRAINT CK_VAL_DATES;
alter table csrimp.val add CONSTRAINT CK_VAL_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);

alter table csr.delegation drop constraint CK_DELEGATION_DATES ;
alter table csr.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csrimp.delegation drop constraint CK_DELEGATION_DATES ;
alter table csrimp.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csr.sheet drop constraint CK_SHEET_DATES;
alter table csr.sheet add constraint CK_SHEET_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csrimp.sheet drop constraint CK_SHEET_DATES;
alter table csrimp.sheet add constraint CK_SHEET_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csr.val_change drop CONSTRAINT CK_VAL_CHANGE_DATES ;
alter table csr.val_change add CONSTRAINT CK_VAL_CHANGE_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);

alter table csrimp.val_change drop CONSTRAINT CK_VAL_CHANGE_DATES ;
alter table csrimp.val_change add CONSTRAINT CK_VAL_CHANGE_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'MON') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'MON') AND PERIOD_END_DTM > PERIOD_START_DTM);

alter table csr.val_change_log drop CONSTRAINT CK_VAL_CHANGE_LOG_DATES ;
alter table csr.val_change_log add CONSTRAINT CK_VAL_CHANGE_LOG_DATES CHECK (START_DTM = TRUNC(START_DTM, 'MON') AND END_DTM = TRUNC(END_DTM, 'MON') AND END_DTM > START_DTM);

alter table csrimp.ACC_POLICY_PWD_REGEXP drop constraint PK_ACC_POLICY_PWD_REGEXP drop index;
alter table csrimp.ACC_POLICY_PWD_REGEXP add CONSTRAINT PK_ACC_POLICY_PWD_REGEXP PRIMARY KEY (CSRIMP_SESSION_ID, ACCOUNT_POLICY_SID, PASSWORD_REGEXP_ID);

alter table csrimp.delegation drop column submission_offset;

alter table csr.aggregate_ind_calc_job drop constraint CK_AGG_CALC_JOB_DATES;
alter table csr.aggregate_ind_calc_job add constraint CK_AGG_CALC_JOB_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'MON')=END_DTM AND TRUNC(START_DTM,'MON')=START_DTM);

alter table csr.calc_job drop constraint CK_CALC_JOB_DATES;
alter table csr.calc_job add constraint CK_CALC_JOB_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'MON')=END_DTM AND TRUNC(START_DTM,'MON')=START_DTM);

alter table csr.METER_SOURCE_TYPE drop column period_set_id;
alter table csr.METER_SOURCE_TYPE drop column period_interval_id;


begin
	for r in (
		select 1 from all_objects where owner='CSR' and object_name='FB8111_LOG' and object_type='PROCEDURE'
	) loop
		execute immediate 'drop procedure CSR.FB8111_LOG';
	end loop;
end;
/

alter table csr.batch_job_meter_extract add interval varchar2(1);
update csr.batch_job_meter_extract set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.batch_job_meter_extract modify interval not null;
alter table csr.batch_job_meter_extract add constraint ck_batch_job_meter_extract check (interval in ('y','h','q','m'));
alter table csr.batch_job_meter_extract drop column period_set_id;
alter table csr.batch_job_meter_extract drop column period_interval_id;

alter table csr.snapshot add interval varchar2(1);
update csr.snapshot set interval = decode(period_interval_id,4,'y',3,'h',2,'q',1,'m',null);
alter table csr.snapshot modify interval not null;
alter table csr.snapshot add constraint ck_snapshot check (interval in ('y','h','q','m'));
alter table csr.snapshot drop column period_set_id;
alter table csr.snapshot drop column period_interval_id;


CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;


update csr.version set db_version=2587 where db_version=2588;

@../actions/ind_template_body
@../actions/scenario_body
@../actions/task_body
@../audit_body
@../benchmarking_dashboard_body
@../benchmarking_dashboard_pkg
@../calc_body
@../calc_pkg
@../chem/substance_body
@../csr_app_body
@../csr_data_body
@../csr_user_body
@../csrimp/imp_body
@../dashboard_body
@../dataset_legacy_body
@../datasource_body
@../dataview_body
@../dataview_pkg
@../deleg_plan_body
@../deleg_plan_pkg
@../delegation_body
@../delegation_pkg
@../enable_body
@../energy_star_body
@../export_feed_body
@../export_feed_pkg
@../flow_body
@../form_body
@../form_pkg
@../imp_body
@../indicator_body
@../indicator_pkg
@../issue_body
@../issue_pkg
@../meter_body
@../metric_dashboard_body
@../metric_dashboard_pkg
@../model_body
@../model_pkg
@../pending_body
@../pending_datasource_body
@../portlet_body
@../quick_survey_body
@../region_body
@../role_body
@../role_pkg
@../ruleset_body
@../scenario_body
@../scenario_pkg
@../schema_body
@../schema_pkg
@../sheet_body
@../sheet_pkg
@../snapshot_body
@../snapshot_pkg
@../stored_calc_datasource_body
@../strategy_body
@../tag_body
@../tag_pkg
@../target_dashboard_body
@../target_dashboard_pkg
@../templated_report_body
@../templated_report_pkg
@../templated_report_schedule_body
@../unit_test_body
@../utility_report_body
@../utility_report_pkg
@../val_body
@../val_datasource_body
@../val_pkg
@../vb_legacy_body
@../../../aspen2/tools/recompile_packages

--Please update version.sql too -- this keeps clean builds in sync
define version=2637
@update_header

create table csr.period_set
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	period_set_id					number(10) not null,
	annual_periods					number(1) not null,
	label							varchar2(200) not null,
	constraint fk_period_set_customer foreign key (app_sid)
	references csr.customer (app_sid),
	constraint pk_period_set primary key (app_sid, period_set_id),
	constraint ck_period_set_annual_periods check (annual_periods in (0, 1))
);

create table csr.period
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	period_set_id					number(10) not null,
	period_id						number(10) not null,
	label							varchar2(200) not null,
	start_dtm						date,
	end_dtm							date,
	constraint pk_period primary key (app_sid, period_set_id, period_id),
	constraint fk_period_period_set foreign key (app_sid, period_set_id)
	references csr.period_set (app_sid, period_set_id)
);

create table csr.period_dates
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	period_set_id					number(10) not null,
	period_id						number(10) not null,
	year							number(10) not null,
	start_dtm						date not null,
	end_dtm							date not null,
	constraint pk_period_dates primary key (app_sid, period_set_id, period_id, year), -- argh
	constraint fk_period_dates_period foreign key (app_sid, period_set_id, period_id)
	references csr.period (app_sid, period_set_id, period_id)
);

create table csr.period_interval
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	period_set_id					number(10) not null,
	period_interval_id				number(10) not null,
	single_interval_label			varchar2(200) not null,
	multiple_interval_label			varchar2(200) not null,
	constraint pk_period_interval primary key (app_sid, period_set_id, period_interval_id),
	constraint fk_period_interval_period_set foreign key (app_sid, period_set_id)
	references csr.period_set (app_sid, period_set_id)
);

create table csr.period_interval_member
(
	app_sid							number(10) default sys_context('security', 'app') not null,
	period_set_id					number(10) not null,
	period_interval_id				number(10) not null,
	start_period_id					number(10) not null,
	end_period_id					number(10) not null,
	constraint pk_period_interval_member primary key (app_sid, period_set_id, period_interval_id, start_period_id), -- hmm
	constraint fk_period_int_mem_period_int foreign key (app_sid, period_set_id, period_interval_id)
	references csr.period_interval (app_sid, period_set_id, period_interval_id),
	constraint fk_period_intrvl_st_period foreign key (app_sid, period_set_id, start_period_id)
	references csr.period (app_sid, period_set_id, period_id),
	constraint fk_period_intrvl_end_period foreign key (app_sid, period_set_id, end_period_id)
	references csr.period (app_sid, period_set_id, period_id)
);

insert into csr.period_set (app_sid, period_set_id, annual_periods, label)
	select app_sid, 1, 1, 'Calendar months'
	  from csr.customer;

insert into csr.period (app_sid, period_set_id, period_id, label, start_dtm, end_dtm)
	select c.app_sid, 1, x.period_id, x.label, x.start_dtm, x.end_dtm
	  from csr.customer c, (
	  		select 1 period_id, 'Jan' label, date '1900-01-01' start_dtm, date '1900-02-01' end_dtm
	  		  from dual
	  		 union all
	  		select 2 period_id, 'Feb' label, date '1900-02-01', date '1900-03-01'
	  		  from dual
	  		 union all
	  		select 3 period_id, 'Mar' label, date '1900-03-01', date '1900-04-01'
	  		  from dual
	  		 union all
	  		select 4 period_id, 'Apr' label, date '1900-04-01', date '1900-05-01'
	  		  from dual
	  		 union all
	  		select 5 period_id, 'May' label, date '1900-05-01', date '1900-06-01'
	  		  from dual
	  		 union all
	  		select 6 period_id, 'Jun' label, date '1900-06-01', date '1900-07-01'
	  		  from dual
	  		 union all
	  		select 7 period_id, 'Jul' label, date '1900-07-01', date '1900-08-01'
	  		  from dual
	  		 union all
	  		select 8 period_id, 'Aug' label, date '1900-08-01', date '1900-09-01'
	  		  from dual
	  		 union all
	  		select 9 period_id, 'Sep' label, date '1900-09-01', date '1900-10-01'
	  		  from dual
	  		 union all
	  		select 10 period_id, 'Oct' label, date '1900-10-01', date '1900-11-01'
	  		  from dual
	  		 union all
	  		select 11 period_id, 'Nov' label, date '1900-11-01', date '1900-12-01'
	  		  from dual
	  		 union all
	  		select 12 period_id, 'Dec' label, date '1900-12-01', date '1901-01-01'
	  		  from dual
	) x;

insert into csr.period_interval (app_sid, period_set_id, period_interval_id, single_interval_label, multiple_interval_label)
	select app_sid, 1, 1, '{0:PL} {0:YYYY}', '{0:PL} {0:YYYY} - {1:PL} {1:YYYY}'
	  from csr.customer;

insert into csr.period_interval (app_sid, period_set_id, period_interval_id, 
	single_interval_label, multiple_interval_label)
	select app_sid, 1, 2, 'Q{0:I} {0:YYYY}', 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}'
	  from csr.customer;

insert into csr.period_interval (app_sid, period_set_id, period_interval_id, 
	single_interval_label, multiple_interval_label)
	select app_sid, 1, 3, 'H{0:I} {0:YYYY}', 'H{0:I} {0:YYYY} - H{1:I} {1:YYYY}'
	  from csr.customer;
	  	  
insert into csr.period_interval (app_sid, period_set_id, period_interval_id, 
	single_interval_label, multiple_interval_label)
	select app_sid, 1, 4, '{0:YYYY}', '{0:YYYY} - {1:YYYY}'
	  from csr.customer;
	  
insert into csr.period_interval_member (app_sid, period_set_id, period_interval_id, start_period_id, end_period_id)
	select c.app_sid, 1, x.period_interval_id, x.start_period_id, x.end_period_id
	  from csr.customer c, (
	  		-- m
	  		select 1 period_interval_id, 1 start_period_id, 1 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 2 start_period_id, 2 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 3 start_period_id, 3 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 4 start_period_id, 4 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 5 start_period_id, 5 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 6 start_period_id, 6 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 7 start_period_id, 7 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 8 start_period_id, 8 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 9 start_period_id, 9 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 10 start_period_id, 10 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 11 start_period_id, 11 end_period_id
	  		  from dual
	  		 union all
	  		select 1 period_interval_id, 12 start_period_id, 12 end_period_id
	  		  from dual
	  		 union all
	  		-- q
	  		select 2 period_interval_id, 1 start_period_id, 3 end_period_id
	  		  from dual
	  		 union all
	  		select 2 period_interval_id, 4 start_period_id, 6 end_period_id
	  		  from dual
	  		 union all
	  		select 2 period_interval_id, 7 start_period_id, 9 end_period_id
	  		  from dual
	  		 union all
	  		select 2 period_interval_id, 9 start_period_id, 12 end_period_id
	  		  from dual
	  		 union all
	  		-- h
	  		select 3 period_interval_id, 1 start_period_id, 6 end_period_id
	  		  from dual
	  		 union all
	  		select 3 period_interval_id, 7 start_period_id, 12 end_period_id
	  		  from dual
	  		 union all
	  		-- y
	  		select 4 period_interval_id, 1 start_period_id, 12 end_period_id
	  		  from dual	  		
			) x;

alter table csr.ind add 
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);


update csr.ind set period_set_id = 1, period_interval_id = decode(default_interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.ind modify period_set_id not null;
alter table csr.ind modify period_interval_id not null;
alter table csr.ind add constraint fk_ind_period_interval foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.ind drop column default_interval;

create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type, 
		   i.pct_upper_tolerance, i.pct_lower_tolerance, i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm, 
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid, 
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid, 
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize, 
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid 
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

alter table csr.dataview add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.dataview set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,'3',4,-1);
alter table csr.dataview modify period_set_id not null;
alter table csr.dataview modify period_interval_id not null;
alter table csr.dataview add constraint fk_dataview_period_interval foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.dataview drop column interval;

alter table csr.delegation add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.delegation set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.delegation modify period_set_id not null;
alter table csr.delegation modify period_interval_id not null;
alter table csr.delegation add constraint fk_delegation_period_interval foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.delegation drop column interval;

DROP TABLE CSR.temp_delegation_detail;
DROP TABLE CSR.temp_delegation_for_region;
DROP TABLE csr.tmp_deleg_search;

CREATE GLOBAL TEMPORARY TABLE CSR.temp_delegation_detail
(
	sheet_id						number(10),
	parent_sheet_id					number(10),
	delegation_sid					number(10),
	parent_delegation_sid			number(10),
	is_visible						number(1),
	name							varchar2(255),
	start_dtm						date,
	end_dtm							date,
	period_set_id					number(10),
	period_interval_id				number(10),
	submission_dtm					date,
	status							number(10),
	sheet_action_description		varchar2(255),
	sheet_action_downstream			varchar2(255),
	fully_delegated					number(1),
	editing_url						varchar2(255),
	last_action_id					number(10),
	is_top_level					number(1),
	approve_dtm						date,
	delegated_by_user				number(1),
	percent_complete				number(10,0)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.temp_delegation_for_region
(
	sheet_id						number(10),
	delegation_sid					number(10),
	parent_sid						number(10),
	name							varchar2(255),
	start_dtm						date,
	end_dtm							date,
	period_set_id					number(10),
	period_interval_id				number(10),
	last_action_id					number(10),
	submission_dtm					date,
	status							number(10),
	sheet_action_description		varchar2(255),
	editing_url						varchar2(255),
	root_delegation_sid				number(10),
	last_action_colour				char(1)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE csr.tmp_deleg_search (
	app_sid             			NUMBER(10) NOT NULL,
	delegation_sid      			NUMBER(10) NOT NULL,
	name                			VARCHAR2(1023) NOT NULL,
	start_dtm           			DATE NOT NULL,
	end_dtm             			DATE NOT NULL,
	period_set_id					NUMBER(10),
	period_interval_id				NUMBER(10),
	editing_url         			VARCHAR2(255) NOT NULL,
	root_delegation_sid 			NUMBER(10) NOT NULL,
	lvl                 			NUMBER(10) NOT NULL,
	max_lvl             			NUMBER(10) NOT NULL
) ON COMMIT DELETE ROWS;			

alter table csr.pending_period add constraint ck_pending_period_dates 
check (trunc(start_dtm, 'MON') = start_dtm and trunc(end_dtm, 'MON') = end_dtm and end_dtm > start_dtm);

alter table csr.tpl_report add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report modify period_set_id not null;
alter table csr.tpl_report modify period_interval_id not null;
alter table csr.tpl_report add constraint fk_tpl_report_period_interval foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report drop column interval;

alter table csr.metric_dashboard add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.metric_dashboard set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.metric_dashboard modify period_set_id not null;
alter table csr.metric_dashboard modify period_interval_id not null;
alter table csr.metric_dashboard add constraint fk_metric_dash_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.metric_dashboard drop column interval;

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'PERIOD',
		'PERIOD_DATES',
		'PERIOD_INTERVAL',
		'PERIOD_INTERVAL_MEMBER',
		'PERIOD_SET'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin					
					-- verify that the table has an app_sid column (dev helper)
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';
					
					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

create or replace package csr.period_pkg as
end;
/

grant execute on csr.period_pkg to web_user;

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_VAL_DATES' and table_name='VAL') loop
		execute immediate 'alter table csr.val drop CONSTRAINT CK_VAL_DATES';
	end loop;
end;
/
alter table csr.val add CONSTRAINT CK_VAL_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'DD') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'DD') AND PERIOD_END_DTM > PERIOD_START_DTM);

alter table csr.target_dashboard add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.target_dashboard set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.target_dashboard modify period_set_id not null;
alter table csr.target_dashboard modify period_interval_id not null;
alter table csr.target_dashboard add constraint fk_target_dash_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.target_dashboard drop column interval;

alter table csr.scenario add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.scenario set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.scenario modify period_set_id not null;
alter table csr.scenario modify period_interval_id not null;
alter table csr.scenario add constraint fk_scenario_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.scenario drop column interval;

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
	SHEET_ID						NUMBER(10,0),
	DELEGATION_SID					NUMBER(10,0),
	PARENT_DELEGATION_SID			NUMBER(10,0),
	NAME							VARCHAR2(255),
	CAN_SAVE						NUMBER(10,0),
	CAN_SUBMIT						NUMBER(10,0),
	CAN_ACCEPT						NUMBER(10,0),
	CAN_RETURN						NUMBER(10,0),
	CAN_DELEGATE					NUMBER(10,0),
	CAN_VIEW						NUMBER(10,0),
	CAN_OVERRIDE_DELEGATOR			NUMBER(10,0),
	CAN_COPY_FORWARD				NUMBER(10,0),
	LAST_ACTION_ID					NUMBER(10,0),
	START_DTM						DATE,
	END_DTM							DATE,
	PERIOD_SET_ID					NUMBER(10),
	PERIOD_INTERVAL_ID				NUMBER(10),
	GROUP_BY						VARCHAR2(128),
	NOTE							CLOB,
	USER_LEVEL						NUMBER(10,0),
	IS_TOP_LEVEL					NUMBER(10,0),
	IS_READ_ONLY					NUMBER(1),
	CAN_EXPLAIN						NUMBER(1)
  );
/

DROP TABLE CSR.temp_alert_batch_details;

CREATE GLOBAL TEMPORARY TABLE CSR.temp_alert_batch_details
(
	app_sid							NUMBER(10) NOT NULL,
	csr_user_sid					NUMBER(10) NOT NULL,
	full_name						VARCHAR2(256), 
	friendly_name					VARCHAR2(256) NOT NULL, 
	email							VARCHAR2(256),         	
	user_name						VARCHAR2(256) NOT NULL,
	sheet_id						NUMBER(10) NOT NULL,
	sheet_url						VARCHAR2(400) NOT NULL,
	delegation_name					VARCHAR2(1023),
	period_set_id					NUMBER(10) NOT NULL,
	period_interval_id				NUMBER(10) NOT NULL,
	delegation_sid					NUMBER(10) NOT NULL,
	submission_dtm					DATE NOT NULL,
	reminder_dtm					DATE NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE NOT NULL
) ON COMMIT DELETE ROWS;

alter table csr.deleg_plan add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.deleg_plan set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.deleg_plan modify period_set_id not null;
alter table csr.deleg_plan modify period_interval_id not null;
alter table csr.deleg_plan add constraint fk_deleg_plan_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.deleg_plan drop column interval;

alter table csr.form add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.form set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.form modify period_set_id not null;
alter table csr.form modify period_interval_id not null;
alter table csr.form add constraint fk_form_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.form drop column interval;

alter table csr.benchmark_dashboard add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.benchmark_dashboard set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.benchmark_dashboard modify period_set_id not null;
alter table csr.benchmark_dashboard modify period_interval_id not null;
alter table csr.benchmark_dashboard add constraint fk_bench_dashboard_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.benchmark_dashboard drop column interval;

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

alter table csrimp.ind add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.ind drop column default_interval;

alter table csrimp.delegation add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.delegation drop column interval;

alter table csrimp.form add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.form drop column interval;

alter table csrimp.dataview add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.dataview drop column interval;

alter table csrimp.deleg_plan add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.deleg_plan drop column interval;

alter table csrimp.tpl_report add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.tpl_report drop column interval;

alter table csrimp.scenario add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.scenario drop column interval;

alter table csrimp.target_dashboard add (
    PERIOD_SET_ID				  NUMBER(10)		NOT NULL,
    PERIOD_INTERVAL_ID			  NUMBER(10)		NOT NULL
);
alter table csrimp.target_dashboard drop column interval;

alter table csr.delegation add submission_offset number(10);
begin
	for r in (select * from all_Tab_columns where owner='CSR' and table_name='DELEGATION' and column_name='SCHEDULE_XML' and nullable!='Y') loop
		execute immediate 'alter table csr.delegation modify schedule_xml null';
	end loop;
end;
/

begin
	for r in (select * from all_Tab_columns where owner='CSRIMP' and table_name='DELEGATION' and column_name='SCHEDULE_XML' and nullable!='Y') loop
		execute immediate 'alter table csrimp.delegation modify schedule_xml null';
	end loop;
end;
/

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.SUBMIT_CONFIRMATION_TEXT as delegation_policy
	  FROM csr.delegation d
    LEFT JOIN csr.delegation_description dd ON dd.app_sid = d.app_sid 
     AND dd.delegation_sid = d.delegation_sid  
	 AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
    LEFT JOIN CSR.DELEGATION_POLICY dp ON dp.app_sid = d.app_sid 
     AND dp.delegation_sid = d.delegation_sid;

BEGIN
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_DELEGATION_DATES' and table_name='DELEGATION') loop
		execute immediate 'alter table csr.delegation drop constraint CK_DELEGATION_DATES';
	end loop;
end;
/
alter table csr.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_SHEET_DATES' and table_name='SHEET') loop
		execute immediate 'alter table csr.sheet drop constraint CK_SHEET_DATES';
	end loop;
end;
/
alter table csr.sheet add constraint CK_SHEET_DATES CHECK (END_DTM > START_DTM);

alter table csr.period_interval add label varchar2(200);
update csr.period_interval set label='Annually' where period_interval_id=1;
update csr.period_interval set label='Half-yearly' where period_interval_id=2;
update csr.period_interval set label='Quarterly' where period_interval_id=3;
update csr.period_interval set label='Monthly' where period_interval_id=4;
alter table csr.period_interval modify label not null;

alter table csr.tpl_report_tag_ind add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report_tag_ind set period_set_id = decode(interval,null,null,1), period_interval_id = decode(interval,null,null,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report_tag_ind add constraint fk_tpl_rep_tag_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report_tag_ind drop column interval;

alter table csr.tpl_report_tag_eval add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report_tag_eval set period_set_id = decode(interval,null,null,1), period_interval_id = decode(interval,null,null,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report_tag_eval add constraint fk_tpl_rp_tg_eval_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report_tag_eval drop column interval;

alter table csr.tpl_report_tag_logging_form add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report_tag_logging_form set period_set_id = decode(interval,null,null,1), period_interval_id = decode(interval,null,null,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report_tag_logging_form add constraint fk_tpl_rp_tg_lgfrm_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report_tag_logging_form drop column interval;

alter table csr.tpl_report_tag_dataview add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report_tag_dataview set period_set_id = decode(interval,null,null,1), period_interval_id = decode(interval,null,null,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report_tag_dataview add constraint fk_tpl_rp_tg_dv_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report_tag_dataview drop column interval;

alter table csr.tpl_report_non_compl add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);
update csr.tpl_report_non_compl set period_set_id = decode(interval,null,null,1), period_interval_id = decode(interval,null,null,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.tpl_report_non_compl add constraint fk_tpl_rp_nc_period_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.tpl_report_non_compl drop column interval;

BEGIN
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_IMP_VAL_DATES' and table_name='IMP_VAL') loop
		execute immediate 'alter table csr.imp_val drop constraint CK_IMP_VAL_DATES';
	end loop;
end;
/
alter table csr.imp_val add CONSTRAINT CK_IMP_VAL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

alter table csr.period_interval add single_interval_no_year_label varchar2(200);
begin
	update csr.period_interval set single_interval_no_year_label = 'I{0:I}' where period_set_id<>1;
	update csr.period_interval set single_interval_no_year_label='Year' where period_set_id=1 and period_interval_id=1;
	update csr.period_interval set single_interval_no_year_label='H{0:I}' where period_set_id=1 and period_interval_id=2;
	update csr.period_interval set single_interval_no_year_label='Q{0:I}' where period_set_id=1 and period_interval_id=3;
	update csr.period_interval set single_interval_no_year_label='{0:PL}' where period_set_id=1 and period_interval_id=4;
	commit;
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

DECLARE
	type t_tabs is table of varchar2(30);
	v_null_list t_tabs;
	v_nullable	varchar2(1);
begin	
	v_null_list := t_tabs(
		'IND',
		'DELEGATION',
		'FORM',
		'DATAVIEW',
		'DELEG_PLAN',
		'TPL_REPORT',
		'TARGET_DASHBOARD',
		'SCENARIO'
	);
	for i in 1 .. v_null_list.count loop
		dbms_output.put_line('processing '||v_null_list(i));
		select nullable
		  into v_nullable
		  from all_tab_columns 
		 where owner = 'CSRIMP' 
		   and table_name = UPPER(v_null_list(i))
		   and column_name = 'PERIOD_SET_ID';
		if v_nullable = 'N' then
			execute immediate 'alter table csrimp.'||v_null_list(i)||' modify period_set_id null';
		end if;
		select nullable
		  into v_nullable
		  from all_tab_columns 
		 where owner = 'CSRIMP' 
		   and table_name = UPPER(v_null_list(i))
		   and column_name = 'PERIOD_INTERVAL_ID';
		if v_nullable = 'N' then
			execute immediate 'alter table csrimp.'||v_null_list(i)||' modify period_interval_id null';
		end if;
		execute immediate 'alter table csrimp.'||v_null_list(i)||' modify period_set_id default 1';
		execute immediate 'alter table csrimp.'||v_null_list(i)||' modify period_interval_id default 1';
	end loop;
end;
/


DECLARE
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_exists number;
begin	
	v_list := t_tabs(
		'TPL_REPORT_TAG_IND',
		'TPL_REPORT_TAG_EVAL',
		'TPL_REPORT_TAG_LOGGING_FORM',
		'TPL_REPORT_TAG_DATAVIEW',
		'TPL_REPORT_NON_COMPL',
		'DELEGATION',
		'FORM',
		'DATAVIEW',
		'DELEG_PLAN',
		'TPL_REPORT',
		'SCENARIO',
		'TARGET_DASHBOARD'
	);
	for i in 1 .. v_list.count loop
		select count(*) into v_exists from all_Tab_columns where owner='CSRIMP' and table_name=UPPER(v_list(i)) and column_name='INTERVAL';
		if v_exists = 0 then
			execute immediate 'alter table csrimp.'||v_list(i)||' add interval	varchar(1)';
		end if;
	end loop;
end;
/

declare
	v_exists number;
begin
	select count(*) into v_exists from all_Tab_columns where owner='CSRIMP' and table_name='IND' and column_name='DEFAULT_INTERVAL';
	if v_exists = 0 then
		execute immediate '
alter table csrimp.ind add (
	default_interval	varchar(1)
)';
	end if;
end;
/

alter table csrimp.tpl_report_tag_ind add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

alter table csrimp.tpl_report_tag_eval add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

alter table csrimp.tpl_report_tag_logging_form add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

alter table csrimp.tpl_report_tag_dataview add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

alter table csrimp.tpl_report_non_compl add
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);


GRANT INSERT ON csr.period TO csrimp;
GRANT INSERT ON csr.period_set TO csrimp;
GRANT INSERT ON csr.period_interval TO csrimp;
GRANT INSERT ON csr.period_interval_member TO csrimp;
GRANT INSERT ON csr.period_dates TO csrimp;

update csr.delegation set submission_offset = 0 where submission_offset is null;
alter table csr.delegation modify submission_offset default 0 not null;

CREATE TABLE CSRIMP.PERIOD_SET
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERIOD_SET_ID					NUMBER(10) NOT NULL,
	ANNUAL_PERIODS					NUMBER(1) NOT NULL,
	LABEL							VARCHAR2(200) NOT NULL,
	CONSTRAINT PK_PERIOD_SET PRIMARY KEY (CSRIMP_SESSION_ID, PERIOD_SET_ID),
	CONSTRAINT FK_PERIOD_SET_IS FOREIGN KEY (CSRIMP_SESSION_ID) 
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.PERIOD
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERIOD_SET_ID					NUMBER(10) NOT NULL,
	PERIOD_ID						NUMBER(10) NOT NULL,
	LABEL							VARCHAR2(200) NOT NULL,
	START_DTM						DATE,
	END_DTM							DATE,
	CONSTRAINT PK_PERIOD PRIMARY KEY (CSRIMP_SESSION_ID, PERIOD_SET_ID, PERIOD_ID),
	CONSTRAINT FK_PERIOD_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.PERIOD_DATES
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERIOD_SET_ID					NUMBER(10) NOT NULL,
	PERIOD_ID						NUMBER(10) NOT NULL,
	YEAR							NUMBER(10) NOT NULL,
	START_DTM						DATE NOT NULL,
	END_DTM							DATE NOT NULL,
	CONSTRAINT PK_PERIOD_DATES PRIMARY KEY (CSRIMP_SESSION_ID, PERIOD_SET_ID, PERIOD_ID, YEAR),
	CONSTRAINT FK_PERIOD_DATES_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.PERIOD_INTERVAL
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERIOD_SET_ID					NUMBER(10) NOT NULL,
	PERIOD_INTERVAL_ID				NUMBER(10) NOT NULL,
	SINGLE_INTERVAL_LABEL			VARCHAR2(200) NOT NULL,
	MULTIPLE_INTERVAL_LABEL			VARCHAR2(200) NOT NULL,
	LABEL                         	VARCHAR2(200) NOT NULL, 
	SINGLE_INTERVAL_NO_YEAR_LABEL   VARCHAR2(200) NOT NULL,
	CONSTRAINT PK_PERIOD_INTERVAL PRIMARY KEY (CSRIMP_SESSION_ID, PERIOD_SET_ID, PERIOD_INTERVAL_ID),
	CONSTRAINT FK_PERIOD_INTERVAL_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.PERIOD_INTERVAL_MEMBER
(
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERIOD_SET_ID					NUMBER(10) NOT NULL,
	PERIOD_INTERVAL_ID				NUMBER(10) NOT NULL,
	START_PERIOD_ID					NUMBER(10) NOT NULL,
	END_PERIOD_ID					NUMBER(10) NOT NULL,
	CONSTRAINT PK_PERIOD_INTERVAL_MEMBER PRIMARY KEY (CSRIMP_SESSION_ID, PERIOD_SET_ID, PERIOD_INTERVAL_ID, START_PERIOD_ID),
	CONSTRAINT FK_PERIOD_INTERVAL_MEMBER_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and constraint_name='CK_IMP_VAL_DATES' and table_name='IMP_VAL') loop
		execute immediate 'alter table csrimp.imp_val drop CONSTRAINT CK_IMP_VAL_DATES';
	end loop;
end;
/
alter table csrimp.imp_val add CONSTRAINT CK_IMP_VAL_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and constraint_name='CK_VAL_DATES' and table_name='VAL') loop
		execute immediate 'alter table csrimp.val drop CONSTRAINT CK_VAL_DATES';
	end loop;
end;
/
alter table csrimp.val add CONSTRAINT CK_VAL_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'DD') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'DD') AND PERIOD_END_DTM > PERIOD_START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_DELEGATION_DATES' and table_name='DELEGATION') loop
		execute immediate 'alter table csr.delegation drop CONSTRAINT CK_DELEGATION_DATES';
	end loop;
end;
/
alter table csr.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and constraint_name='CK_DELEGATION_DATES' and table_name='DELEGATION') loop
		execute immediate 'alter table csrimp.delegation drop CONSTRAINT CK_DELEGATION_DATES';
	end loop;
end;
/
alter table csrimp.delegation add CONSTRAINT CK_DELEGATION_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_SHEET_DATES' and table_name='SHEET') loop
		execute immediate 'alter table csr.sheet drop CONSTRAINT CK_SHEET_DATES';
	end loop;
end;
/
alter table csr.sheet add constraint CK_SHEET_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and constraint_name='CK_SHEET_DATES' and table_name='SHEET') loop
		execute immediate 'alter table csrimp.sheet drop CONSTRAINT CK_SHEET_DATES';
	end loop;
end;
/
alter table csrimp.sheet add constraint CK_SHEET_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_VAL_CHANGE_DATES' and table_name='VAL_CHANGE') loop
		execute immediate 'alter table csr.val_change drop CONSTRAINT CK_VAL_CHANGE_DATES';
	end loop;
end;
/
alter table csr.val_change add CONSTRAINT CK_VAL_CHANGE_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'DD') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'DD') AND PERIOD_END_DTM > PERIOD_START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and constraint_name='CK_VAL_CHANGE_DATES' and table_name='VAL_CHANGE') loop
		execute immediate 'alter table csrimp.val_change drop CONSTRAINT CK_VAL_CHANGE_DATES';
	end loop;
end;
/
alter table csrimp.val_change add CONSTRAINT CK_VAL_CHANGE_DATES CHECK (PERIOD_START_DTM = TRUNC(PERIOD_START_DTM, 'DD') AND PERIOD_END_DTM = TRUNC(PERIOD_END_DTM, 'DD') AND PERIOD_END_DTM > PERIOD_START_DTM);

begin
	for r in (select 1 from all_constraints where owner='CSR' and constraint_name='CK_VAL_CHANGE_LOG_DATES' and table_name='VAL_CHANGE_LOG') loop
		execute immediate 'alter table csr.VAL_CHANGE_LOG drop CONSTRAINT CK_VAL_CHANGE_LOG_DATES';
	end loop;
end;
/
alter table csr.val_change_log add CONSTRAINT CK_VAL_CHANGE_LOG_DATES CHECK (START_DTM = TRUNC(START_DTM, 'DD') AND END_DTM = TRUNC(END_DTM, 'DD') AND END_DTM > START_DTM);

alter table csrimp.ACC_POLICY_PWD_REGEXP drop constraint PK_ACC_POLICY_PWD_REGEXP drop index;
alter table csrimp.ACC_POLICY_PWD_REGEXP add CONSTRAINT PK_ACC_POLICY_PWD_REGEXP PRIMARY KEY (CSRIMP_SESSION_ID, ACCOUNT_POLICY_SID, PASSWORD_REGEXP_ID);

grant insert,select,update,delete on csrimp.period to web_user;
grant insert,select,update,delete on csrimp.period_set to web_user;
grant insert,select,update,delete on csrimp.period_interval to web_user;
grant insert,select,update,delete on csrimp.period_interval_member to web_user;
grant insert,select,update,delete on csrimp.period_dates to web_user;

alter table csrimp.map_sid drop constraint pk_map_sid drop index;
alter table csrimp.map_sid drop constraint uk_map_sid drop index;
alter table csrimp.map_acl drop constraint pk_map_acl drop index;
alter table csrimp.map_acl drop constraint uk_map_acl drop index;
alter table csrimp.map_ip_rule drop constraint pk_map_ip_rule drop index;
alter table csrimp.map_ip_rule drop constraint uk_map_ip_rule drop index;
alter table csrimp.map_form_allocation drop constraint pk_map_form_allocation drop index;
alter table csrimp.map_form_allocation drop constraint uk_map_form_allocation drop index;
alter table csrimp.map_measure_conversion drop constraint pk_map_measure_conversion drop index;
alter table csrimp.map_measure_conversion drop constraint uk_map_measure_conversion drop index;
alter table csrimp.map_accuracy_type drop constraint pk_map_accuracy_type drop index;
alter table csrimp.map_accuracy_type drop constraint uk_map_accuracy_type drop index;
alter table csrimp.map_accuracy_type_option drop constraint pk_map_accuracy_type_option drop index;
alter table csrimp.map_accuracy_type_option drop constraint uk_map_accuracy_type_option drop index;
alter table csrimp.map_tag_group drop constraint pk_map_tag_group drop index;
alter table csrimp.map_tag_group drop constraint uk_map_tag_group drop index;
alter table csrimp.map_tag drop constraint pk_map_tag drop index;
alter table csrimp.map_tag drop constraint uk_map_tag drop index;
alter table csrimp.map_alert_frame drop constraint pk_map_alert_frame drop index;
alter table csrimp.map_alert_frame drop constraint uk_map_alert_frame drop index;
alter table csrimp.map_customer_alert_type drop constraint pk_map_customer_alert_type drop index;
alter table csrimp.map_customer_alert_type drop constraint uk_map_customer_alert_type drop index;
alter table csrimp.map_pending_ind drop constraint pk_map_pending_ind drop index;
alter table csrimp.map_pending_ind drop constraint uk_map_pending_ind drop index;
alter table csrimp.map_pending_region drop constraint pk_map_pending_region drop index;
alter table csrimp.map_pending_region drop constraint uk_map_pending_region drop index;
alter table csrimp.map_pending_period drop constraint pk_map_pending_period drop index;
alter table csrimp.map_pending_period drop constraint uk_map_pending_period drop index;
alter table csrimp.map_pending_val drop constraint pk_map_pending_val drop index;
alter table csrimp.map_pending_val drop constraint uk_map_pending_val drop index;
alter table csrimp.map_approval_step_sheet drop constraint pk_map_approval_step_sheet drop index;
alter table csrimp.map_approval_step_sheet drop constraint uk_map_approval_step_sheet drop index;
alter table csrimp.map_attachment drop constraint pk_map_attachment drop index;
alter table csrimp.map_attachment drop constraint uk_map_attachment drop index;
alter table csrimp.map_section_alert drop constraint pk_map_section_alert drop index;
alter table csrimp.map_section_alert drop constraint uk_map_section_alert drop index;
alter table csrimp.map_section_comment drop constraint pk_map_section_comment drop index;
alter table csrimp.map_section_comment drop constraint uk_map_section_comment drop index;
alter table csrimp.map_section_trans_comment drop constraint pk_map_section_t_comment drop index;
alter table csrimp.map_section_trans_comment drop constraint uk_map_section_t_comment drop index;
alter table csrimp.map_section_cart drop constraint pk_map_section_cart drop index;
alter table csrimp.map_section_cart drop constraint uk_map_section_cart drop index;
alter table csrimp.map_section_tag drop constraint pk_map_section_tag drop index;
alter table csrimp.map_section_tag drop constraint uk_map_section_tag drop index;
alter table csrimp.map_route drop constraint pk_map_route drop index;
alter table csrimp.map_route drop constraint uk_map_route drop index;
alter table csrimp.map_route_step drop constraint pk_map_route_step drop index;
alter table csrimp.map_route_step drop constraint uk_map_route_step drop index;
alter table csrimp.map_sheet drop constraint pk_map_sheet drop index;
alter table csrimp.map_sheet drop constraint uk_map_sheet drop index;
alter table csrimp.map_sheet_value drop constraint pk_map_sheet_value drop index;
alter table csrimp.map_sheet_value drop constraint uk_map_sheet_value drop index;
alter table csrimp.map_sheet_history drop constraint pk_map_sheet_history drop index;
alter table csrimp.map_sheet_history drop constraint uk_map_sheet_history drop index;
alter table csrimp.map_sheet_value_change drop constraint pk_map_sheet_value_change drop index;
alter table csrimp.map_sheet_value_change drop constraint uk_map_sheet_value_change drop index;
alter table csrimp.map_imp_conflict drop constraint pk_map_imp_conflict drop index;
alter table csrimp.map_imp_conflict drop constraint uk_map_imp_conflict drop index;
alter table csrimp.map_imp_ind drop constraint pk_map_imp_ind drop index;
alter table csrimp.map_imp_ind drop constraint uk_map_imp_ind drop index;
alter table csrimp.map_imp_region drop constraint pk_map_imp_region drop index;
alter table csrimp.map_imp_region drop constraint uk_map_imp_region drop index;
alter table csrimp.map_imp_measure drop constraint pk_map_imp_measure drop index;
alter table csrimp.map_imp_measure drop constraint uk_map_imp_measure drop index;
alter table csrimp.map_imp_val drop constraint pk_map_imp_val drop index;
alter table csrimp.map_imp_val drop constraint uk_map_imp_val drop index;
alter table csrimp.map_val drop constraint pk_map_val drop index;
alter table csrimp.map_val drop constraint uk_map_val drop index;
alter table csrimp.map_ind_validation_rule drop constraint pk_map_ind_validation_rule drop index;
alter table csrimp.map_ind_validation_rule drop constraint uk_map_ind_validation_rule drop index;
alter table csrimp.map_delegation_ind_cond drop constraint pk_map_delegation_ind_cond drop index;
alter table csrimp.map_delegation_ind_cond drop constraint uk_map_delegation_ind_cond drop index;
alter table csrimp.map_deleg_plan_col drop constraint pk_map_deleg_plan_col drop index;
alter table csrimp.map_deleg_plan_col drop constraint uk_map_deleg_plan_col drop index;
alter table csrimp.map_deleg_plan_col_deleg drop constraint pk_map_dlg_plan_col_dlg drop index;
alter table csrimp.map_deleg_plan_col_deleg drop constraint uk_map_dlg_plan_col_dlg drop index;
alter table csrimp.map_form_expr drop constraint pk_map_form_expr drop index;
alter table csrimp.map_form_expr drop constraint uk_map_form_expr drop index;
alter table csrimp.map_factor drop constraint pk_map_factor drop index;
alter table csrimp.map_factor drop constraint uk_map_factor drop index;
alter table csrimp.map_deleg_ind_group drop constraint pk_map_deleg_ind_group drop index;
alter table csrimp.map_deleg_ind_group drop constraint uk_map_deleg_ind_group drop index;
alter table csrimp.map_var_expl_group drop constraint pk_map_var_expl_group drop index;
alter table csrimp.map_var_expl_group drop constraint uk_map_var_expl_group drop index;
alter table csrimp.map_var_expl drop constraint pk_map_var_expl drop index;
alter table csrimp.map_var_expl drop constraint uk_map_var_expl drop index;
alter table csrimp.map_cms_schema drop constraint pk_map_cms_schema drop index;
alter table csrimp.map_cms_schema drop constraint uk_map_cms_schema drop index;
alter table csrimp.map_cms_uk_cons drop constraint pk_map_cms_uk_cons drop index;
alter table csrimp.map_cms_uk_cons drop constraint uk_map_cms_uk_cons drop index;
alter table csrimp.map_cms_ck_cons drop constraint pk_map_cms_ck_cons drop index;
alter table csrimp.map_cms_ck_cons drop constraint uk_map_cms_ck_cons drop index;
alter table csrimp.map_cms_display_template drop constraint pk_map_cms_display_template drop index;
alter table csrimp.map_cms_display_template drop constraint uk_map_cms_display_template drop index;
alter table csrimp.map_cms_image drop constraint pk_map_cms_image drop index;
alter table csrimp.map_cms_image drop constraint uk_map_cms_image drop index;
alter table csrimp.map_cms_tag drop constraint pk_map_cms_tag drop index;
alter table csrimp.map_cms_tag drop constraint uk_map_cms_tag drop index;
alter table csrimp.map_flow_state drop constraint pk_map_flow_state drop index;
alter table csrimp.map_flow_state drop constraint uk_map_flow_state drop index;
alter table csrimp.map_flow_item drop constraint pk_map_flow_item drop index;
alter table csrimp.map_flow_item drop constraint uk_map_flow_item drop index;
alter table csrimp.map_flow_state_log drop constraint pk_map_flow_state_log drop index;
alter table csrimp.map_flow_state_log drop constraint uk_map_flow_state_log drop index;
alter table csrimp.map_flow_state_transition drop constraint pk_map_flow_state_transition drop index;
alter table csrimp.map_flow_state_transition drop constraint uk_map_flow_state_transition drop index;
alter table csrimp.map_flow_transition_alert drop constraint pk_map_flow_transition_alert drop index;
alter table csrimp.map_flow_transition_alert drop constraint uk_map_flow_transition_alert drop index;
alter table csrimp.map_flow_state_rl_cap drop constraint pk_map_flow_state_rl_cap drop index;
alter table csrimp.map_flow_state_rl_cap drop constraint uk_map_flow_state_rl_cap drop index;
alter table csrimp.map_meter_raw_data_source drop constraint pk_map_meter_raw_data_source drop index;
alter table csrimp.map_meter_raw_data_source drop constraint uk_map_meter_raw_data_source drop index;
alter table csrimp.map_live_data_duration drop constraint pk_map_live_data_duration drop index;
alter table csrimp.map_live_data_duration drop constraint uk_map_live_data_duration drop index;
alter table csrimp.map_utility_supplier drop constraint pk_map_utility_supplier drop index;
alter table csrimp.map_utility_supplier drop constraint uk_map_utility_supplier drop index;
alter table csrimp.map_utility_contract drop constraint pk_map_utility_contract drop index;
alter table csrimp.map_utility_contract drop constraint uk_map_utility_contract drop index;
alter table csrimp.map_utility_invoice drop constraint pk_map_utility_invoice drop index;
alter table csrimp.map_utility_invoice drop constraint uk_map_utility_invoice drop index;
alter table csrimp.map_meter_alarm drop constraint pk_map_meter_alarm drop index;
alter table csrimp.map_meter_alarm drop constraint uk_map_meter_alarm drop index;
alter table csrimp.map_meter_alarm_statistic drop constraint pk_map_meter_alarm_statistic drop index;
alter table csrimp.map_meter_alarm_statistic drop constraint uk_map_meter_alarm_statistic drop index;
alter table csrimp.map_meter_alarm_comparison drop constraint pk_map_meter_alarm_comparison drop index;
alter table csrimp.map_meter_alarm_comparison drop constraint uk_map_meter_alarm_comparison drop index;
alter table csrimp.map_meter_alarm_issue_period drop constraint pk_map_meter_alrm_iss_period drop index;
alter table csrimp.map_meter_alarm_issue_period drop constraint uk_map_meter_alrm_iss_period drop index;

alter table csrimp.map_event drop constraint pk_map_event drop index;
alter table csrimp.map_event drop constraint uk_map_event drop index;
alter table csrimp.map_meter_document drop constraint pk_map_meter_document drop index;
alter table csrimp.map_meter_document drop constraint uk_map_meter_document drop index;
alter table csrimp.map_issue_pending_val drop constraint pk_map_issue_pending_val drop index;
alter table csrimp.map_issue_pending_val drop constraint uk_map_issue_pending_val drop index;
alter table csrimp.map_issue_sheet_value drop constraint pk_map_issue_sheet_value drop index;
alter table csrimp.map_issue_sheet_value drop constraint uk_map_issue_sheet_value drop index;
alter table csrimp.map_issue_meter drop constraint pk_map_issue_meter drop index;
alter table csrimp.map_issue_meter drop constraint uk_map_issue_meter drop index;
alter table csrimp.map_issue_meter_alarm drop constraint pk_map_issue_meter_alarm drop index;
alter table csrimp.map_issue_meter_alarm drop constraint uk_map_issue_meter_alarm drop index;
alter table csrimp.map_issue_meter_data_source drop constraint pk_map_issue_meter_data_source drop index;
alter table csrimp.map_issue_meter_data_source drop constraint uk_map_issue_meter_data_source drop index;
alter table csrimp.map_issue_meter_raw_data drop constraint pk_map_issue_meter_raw_data drop index;
alter table csrimp.map_issue_meter_raw_data drop constraint uk_map_issue_meter_raw_data drop index;
alter table csrimp.map_issue_priority drop constraint pk_map_issue_priority drop index;
alter table csrimp.map_issue_priority drop constraint uk_map_issue_priority drop index;
alter table csrimp.map_rag_status drop constraint pk_map_rag_status drop index;
alter table csrimp.map_rag_status drop constraint uk_map_rag_status drop index;
alter table csrimp.map_issue drop constraint pk_map_issue drop index;
alter table csrimp.map_issue drop constraint uk_map_issue drop index;
alter table csrimp.map_issue_log drop constraint pk_map_issue_log drop index;
alter table csrimp.map_issue_log drop constraint uk_map_issue_log drop index;
alter table csrimp.map_issue_custom_field drop constraint pk_map_issue_custom_field drop index;
alter table csrimp.map_issue_custom_field drop constraint uk_map_issue_custom_field drop index;
alter table csrimp.map_correspondent drop constraint pk_map_correspondent drop index;
alter table csrimp.map_correspondent drop constraint uk_map_correspondent drop index;
alter table csrimp.map_deleg_plan_col_survey drop constraint pk_map_deleg_plan_col_survey drop index;
alter table csrimp.map_deleg_plan_col_survey drop constraint uk_map_deleg_plan_col_survey drop index;
alter table csrimp.map_tab drop constraint pk_map_tab drop index;
alter table csrimp.map_tab drop constraint uk_map_tab drop index;
alter table csrimp.map_tab_portlet drop constraint pk_map_tab_portlet drop index;
alter table csrimp.map_tab_portlet drop constraint uk_map_tab_portlet drop index;
alter table csrimp.map_dashboard_instance drop constraint pk_map_dashboard_instance drop index;
alter table csrimp.map_dashboard_instance drop constraint uk_map_dashboard_instance drop index;
alter table csrimp.map_tpl_report_non_compl drop constraint pk_map_tpl_report_non_compl drop index;
alter table csrimp.map_tpl_report_non_compl drop constraint uk_map_tpl_report_non_compl drop index;
alter table csrimp.map_tpl_report_tag_ind drop constraint pk_map_tpl_report_tag_ind drop index;
alter table csrimp.map_tpl_report_tag_ind drop constraint uk_map_tpl_report_tag_ind drop index;
alter table csrimp.map_tpl_report_tag_eval drop constraint pk_map_tpl_report_tag_eval drop index;
alter table csrimp.map_tpl_report_tag_eval drop constraint uk_map_tpl_report_tag_eval drop index;
alter table csrimp.map_tpl_report_tag_dv drop constraint pk_map_tpl_report_tag_dv drop index;
alter table csrimp.map_tpl_report_tag_dv drop constraint uk_map_tpl_report_tag_dv drop index;
alter table csrimp.map_tpl_report_tag_log_frm drop constraint pk_map_tpl_report_tag_log_frm drop index;
alter table csrimp.map_tpl_report_tag_log_frm drop constraint uk_map_tpl_report_tag_log_frm drop index;
alter table csrimp.map_tpl_report_tag_text drop constraint pk_map_tpl_report_tag_text drop index;
alter table csrimp.map_tpl_report_tag_text drop constraint uk_map_tpl_report_tag_text drop index;
alter table csrimp.map_aggregate_ind_group drop constraint pk_map_aggregate_ind_group drop index;
alter table csrimp.map_aggregate_ind_group drop constraint uk_map_aggregate_ind_group drop index;
alter table csrimp.map_dashboard_item drop constraint pk_map_dashboard_item drop index;
alter table csrimp.map_dashboard_item drop constraint uk_map_dashboard_item drop index;
alter table csrimp.map_dataview_zone drop constraint pk_map_dataview_zone drop index;
alter table csrimp.map_dataview_zone drop constraint uk_map_dataview_zone drop index;
alter table csrimp.map_user_cover drop constraint pk_map_user_cover drop index;
alter table csrimp.map_user_cover drop constraint uk_map_user_cover drop index;
alter table csrimp.map_doc drop constraint pk_map_doc drop index;
alter table csrimp.map_doc drop constraint uk_map_doc drop index;
alter table csrimp.map_doc_data drop constraint pk_map_doc_data drop index;
alter table csrimp.map_doc_data drop constraint uk_map_doc_data drop index;
alter table csrimp.map_internal_audit_type drop constraint pk_map_internal_audit_type drop index;
alter table csrimp.map_internal_audit_type drop constraint uk_map_internal_audit_type drop index;
alter table csrimp.map_audit_closure_type drop constraint pk_map_audit_closure_type drop index;
alter table csrimp.map_audit_closure_type drop constraint uk_map_audit_closure_type drop index;
alter table csrimp.map_model_range drop constraint pk_map_model_range drop index;
alter table csrimp.map_model_range drop constraint uk_map_model_range drop index;
alter table csrimp.map_model_sheet drop constraint pk_map_model_sheet drop index;
alter table csrimp.map_model_sheet drop constraint uk_map_model_sheet drop index;
alter table csrimp.map_non_compliance drop constraint pk_map_non_compliance drop index;
alter table csrimp.map_non_compliance drop constraint uk_map_non_compliance drop index;
alter table csrimp.map_qs_type drop constraint pk_map_qs_type drop index;
alter table csrimp.map_qs_type drop constraint uk_map_qs_type drop index;
alter table csrimp.map_qs_question drop constraint pk_map_qs_question drop index;
alter table csrimp.map_qs_question drop constraint uk_map_qs_question drop index;
alter table csrimp.map_qs_custom_question_type drop constraint pk_map_qs_cust_quest_type drop index;
alter table csrimp.map_qs_custom_question_type drop constraint uk_map_qs_cust_quest_type drop index;
alter table csrimp.map_qs_submission drop constraint pk_map_qs_submission drop index;
alter table csrimp.map_qs_submission drop constraint uk_map_qs_submission drop index;
alter table csrimp.map_score_threshold drop constraint pk_map_score_threshold drop index;
alter table csrimp.map_score_threshold drop constraint uk_map_score_threshold drop index;
alter table csrimp.map_qs_question_option drop constraint pk_map_qs_question_option drop index;
alter table csrimp.map_qs_question_option drop constraint uk_map_qs_question_option drop index;
alter table csrimp.map_qs_answer_file drop constraint pk_map_qs_answer_file drop index;
alter table csrimp.map_qs_answer_file drop constraint uk_map_qs_answer_file drop index;
alter table csrimp.map_qs_expr_msg_action drop constraint pk_map_qs_expr_msg_action drop index;
alter table csrimp.map_qs_expr_msg_action drop constraint uk_map_qs_expr_msg_action drop index;
alter table csrimp.map_qs_expr_nc_action drop constraint pk_map_qs_expr_nc_action drop index;
alter table csrimp.map_qs_expr_nc_action drop constraint uk_map_qs_expr_nc_action drop index;
alter table csrimp.map_region_set drop constraint pk_map_region_set drop index;
alter table csrimp.map_region_set drop constraint uk_map_region_set drop index;
alter table csrimp.map_postit drop constraint pk_map_postit drop index;
alter table csrimp.map_postit drop constraint uk_map_postit drop index;
alter table csrimp.map_issue_survey_answer drop constraint pk_map_issue_survey_answer drop index;
alter table csrimp.map_issue_survey_answer drop constraint uk_map_issue_survey_answer drop index;
alter table csrimp.map_issue_non_compliance drop constraint pk_map_issue_non_compliance drop index;
alter table csrimp.map_issue_non_compliance drop constraint uk_map_issue_non_compliance drop index;
alter table csrimp.map_alert drop constraint pk_map_alert drop index;
alter table csrimp.map_alert drop constraint uk_map_alert drop index;
alter table csrimp.map_non_comp_default drop constraint pk_map_non_comp_default drop index;
alter table csrimp.map_non_comp_default drop constraint uk_map_non_comp_default drop index;
alter table csrimp.map_non_comp_default_issue drop constraint pk_map_non_comp_default_issue drop index;
alter table csrimp.map_non_comp_default_issue drop constraint uk_map_non_comp_default_issue drop index;
alter table csrimp.map_deleg_date_schedule drop constraint pk_map_deleg_date_schedule drop index;
alter table csrimp.map_deleg_date_schedule drop constraint uk_map_deleg_date_schedule drop index;
alter table csrimp.MAP_SUPPLIER_SCORE drop constraint pk_MAP_SUPPLIER_SCORE drop index;
alter table csrimp.MAP_SUPPLIER_SCORE drop constraint uk_MAP_SUPPLIER_SCORE drop index;
alter table csrimp.MAP_CHAIN_GROUP_CAPABILI drop constraint pk_MAP_CHAIN_GROUP_CAPABILI drop index;
alter table csrimp.MAP_CHAIN_GROUP_CAPABILI drop constraint uk_MAP_CHAIN_GROUP_CAPABILI drop index;
alter table csrimp.MAP_CHAIN_COMPANY_TYPE drop constraint pk_MAP_CHAIN_COMPANY_TYPE drop index;
alter table csrimp.MAP_CHAIN_COMPANY_TYPE drop constraint uk_MAP_CHAIN_COMPANY_TYPE drop index;
alter table csrimp.MAP_CHAIN_CAPABILITY drop constraint pk_MAP_CHAIN_CAPABILITY drop index;
alter table csrimp.MAP_CHAIN_CAPABILITY drop constraint uk_MAP_CHAIN_CAPABILITY drop index;

declare
	type t_tabs is table of varchar2(30);
	v_tab_list t_tabs;
begin	
	v_tab_list := t_tabs(
		'MAP_CMS_TAB_COLUMN',
		'MAP_CMS_TAB_COLUMN_LINK',
		'MAP_CMS_FK_CONS',
		'MAP_METER_ALARM_TEST_TIME',
		'MAP_METER_RAW_DATA',
		'MAP_METER_READING',
		'MAP_QS_SURVEY_RESPONSE',
		'MAP_QS_EXPR',
		'MAP_NON_COMPLIANCE_FILE',
		'MAP_TENANT',
		'MAP_SPACE_TYPE',
		'MAP_PROPERTY_TYPE',
		'MAP_SUB_PROPERTY_TYPE',
		'MAP_PROPERTY_PHOTO',
		'MAP_LEASE',
		'MAP_MGMT_COMPANY',
		'MAP_FUND',
		'MAP_MGMT_COMPANY_CONTACT',
		'MAP_METER_IND',
		'MAP_LEASE_TYPE',
		'MAP_FUND_TYPE',
		'MAP_REGION_METRIC_VAL',
		'MAP_PLUGIN'
	);
	for i in 1 .. v_tab_list.count loop
		dbms_output.put_line('processing '||v_tab_list(i));
		for r in (select constraint_name from all_constraints where owner='CSRIMP' and table_name = v_tab_list(i) and constraint_type in ('U', 'P')) loop
			dbms_output.put_line('running alter table csrimp.'||v_tab_list(i)||' drop constraint '||r.constraint_name||' drop index');
			execute immediate 'alter table csrimp.'||v_tab_list(i)||' drop constraint '||r.constraint_name||' drop index';
		end loop;
	end loop;
end;
/


alter table csrimp.map_sid add constraint pk_map_sid primary key (csrimp_session_id, old_sid) USING INDEX;
alter table csrimp.map_sid add constraint uk_map_sid unique (csrimp_session_id, new_sid) USING INDEX;
alter table csrimp.map_acl add constraint pk_map_acl primary key (csrimp_session_id, old_acl_id) USING INDEX;
alter table csrimp.map_acl add constraint uk_map_acl unique (csrimp_session_id, new_acl_id) USING INDEX;
alter table csrimp.map_ip_rule add constraint pk_map_ip_rule primary key (csrimp_session_id, old_ip_rule_id) USING INDEX;
alter table csrimp.map_ip_rule add constraint uk_map_ip_rule unique (csrimp_session_id, new_ip_rule_id) USING INDEX;
alter table csrimp.map_form_allocation add constraint pk_map_form_allocation primary key (csrimp_session_id, old_form_allocation_id) USING INDEX;
alter table csrimp.map_form_allocation add constraint uk_map_form_allocation unique (csrimp_session_id, new_form_allocation_id) USING INDEX;
alter table csrimp.map_measure_conversion add constraint pk_map_measure_conversion primary key (csrimp_session_id, old_measure_conversion_id) USING INDEX;
alter table csrimp.map_measure_conversion add constraint uk_map_measure_conversion unique (csrimp_session_id, new_measure_conversion_id) USING INDEX;
alter table csrimp.map_accuracy_type add constraint pk_map_accuracy_type primary key (csrimp_session_id, old_accuracy_type_id) USING INDEX;
alter table csrimp.map_accuracy_type add constraint uk_map_accuracy_type unique (csrimp_session_id, new_accuracy_type_id) USING INDEX;
alter table csrimp.map_accuracy_type_option add constraint pk_map_accuracy_type_option primary key (csrimp_session_id, old_accuracy_type_option_id) USING INDEX;
alter table csrimp.map_accuracy_type_option add constraint uk_map_accuracy_type_option unique (csrimp_session_id, new_accuracy_type_option_id) USING INDEX;
alter table csrimp.map_tag_group add constraint pk_map_tag_group primary key (csrimp_session_id, old_tag_group_id) USING INDEX;
alter table csrimp.map_tag_group add constraint uk_map_tag_group unique (csrimp_session_id, new_tag_group_id) USING INDEX;
alter table csrimp.map_tag add constraint pk_map_tag primary key (csrimp_session_id, old_tag_id) USING INDEX;
alter table csrimp.map_tag add constraint uk_map_tag unique (csrimp_session_id, new_tag_id) USING INDEX;
alter table csrimp.map_alert_frame add constraint pk_map_alert_frame primary key (csrimp_session_id, old_alert_frame_id) USING INDEX;
alter table csrimp.map_alert_frame add constraint uk_map_alert_frame unique (csrimp_session_id, new_alert_frame_id) USING INDEX;
alter table csrimp.map_customer_alert_type add constraint pk_map_customer_alert_type primary key (csrimp_session_id, old_customer_alert_type_id) USING INDEX;
alter table csrimp.map_customer_alert_type add constraint uk_map_customer_alert_type unique (csrimp_session_id, new_customer_alert_type_id) USING INDEX;
alter table csrimp.map_pending_ind add constraint pk_map_pending_ind primary key (csrimp_session_id, old_pending_ind_id) USING INDEX;
alter table csrimp.map_pending_ind add constraint uk_map_pending_ind unique (csrimp_session_id, new_pending_ind_id) USING INDEX;
alter table csrimp.map_pending_region add constraint pk_map_pending_region primary key (csrimp_session_id, old_pending_region_id) USING INDEX;
alter table csrimp.map_pending_region add constraint uk_map_pending_region unique (csrimp_session_id, new_pending_region_id) USING INDEX;
alter table csrimp.map_pending_period add constraint pk_map_pending_period primary key (csrimp_session_id, old_pending_period_id) USING INDEX;
alter table csrimp.map_pending_period add constraint uk_map_pending_period unique (csrimp_session_id, new_pending_period_id) USING INDEX;
alter table csrimp.map_pending_val add constraint pk_map_pending_val primary key (csrimp_session_id, old_pending_val_id) USING INDEX;
alter table csrimp.map_pending_val add constraint uk_map_pending_val unique (csrimp_session_id, new_pending_val_id) USING INDEX;
alter table csrimp.map_approval_step_sheet add constraint pk_map_approval_step_sheet primary key (csrimp_session_id, old_approval_step_id, old_sheet_key) USING INDEX;
alter table csrimp.map_approval_step_sheet add constraint uk_map_approval_step_sheet unique (csrimp_session_id, new_approval_step_id, new_sheet_key) USING INDEX;
alter table csrimp.map_attachment add constraint pk_map_attachment primary key (csrimp_session_id, old_attachment_id) USING INDEX;
alter table csrimp.map_attachment add constraint uk_map_attachment unique (csrimp_session_id, new_attachment_id) USING INDEX;
alter table csrimp.map_section_alert add constraint pk_map_section_alert primary key (csrimp_session_id, old_section_alert_id) USING INDEX;
alter table csrimp.map_section_alert add constraint uk_map_section_alert unique (csrimp_session_id, new_section_alert_id) USING INDEX;
alter table csrimp.map_section_comment add constraint pk_map_section_comment primary key (csrimp_session_id, old_section_comment_id) USING INDEX;
alter table csrimp.map_section_comment add constraint uk_map_section_comment unique (csrimp_session_id, new_section_comment_id) USING INDEX;
alter table csrimp.map_section_trans_comment add constraint pk_map_section_t_comment primary key (csrimp_session_id, old_section_t_comment_id) USING INDEX;
alter table csrimp.map_section_trans_comment add constraint uk_map_section_t_comment unique (csrimp_session_id, new_section_t_comment_id) USING INDEX;
alter table csrimp.map_section_cart add constraint pk_map_section_cart primary key (csrimp_session_id, old_section_cart_id) USING INDEX;
alter table csrimp.map_section_cart add constraint uk_map_section_cart unique (csrimp_session_id, new_section_cart_id) USING INDEX;
alter table csrimp.map_section_tag add constraint pk_map_section_tag primary key (csrimp_session_id, old_section_tag_id) USING INDEX;
alter table csrimp.map_section_tag add constraint uk_map_section_tag unique (csrimp_session_id, new_section_tag_id) USING INDEX;
alter table csrimp.map_route add constraint pk_map_route primary key (csrimp_session_id, old_route_id) USING INDEX;
alter table csrimp.map_route add constraint uk_map_route unique (csrimp_session_id, new_route_id) USING INDEX;
alter table csrimp.map_route_step add constraint pk_map_route_step primary key (csrimp_session_id, old_route_step_id) USING INDEX;
alter table csrimp.map_route_step add constraint uk_map_route_step unique (csrimp_session_id, new_route_step_id) USING INDEX;
alter table csrimp.map_sheet add constraint pk_map_sheet primary key (csrimp_session_id, old_sheet_id) USING INDEX;
alter table csrimp.map_sheet add constraint uk_map_sheet unique (csrimp_session_id, new_sheet_id) USING INDEX;
alter table csrimp.map_sheet_value add constraint pk_map_sheet_value primary key (csrimp_session_id, old_sheet_value_id) USING INDEX;
alter table csrimp.map_sheet_value add constraint uk_map_sheet_value unique (csrimp_session_id, new_sheet_value_id) USING INDEX;
alter table csrimp.map_sheet_history add constraint pk_map_sheet_history primary key (csrimp_session_id, old_sheet_history_id) USING INDEX;
alter table csrimp.map_sheet_history add constraint uk_map_sheet_history unique (csrimp_session_id, new_sheet_history_id) USING INDEX;
alter table csrimp.map_sheet_value_change add constraint pk_map_sheet_value_change primary key (csrimp_session_id, old_sheet_value_change_id) USING INDEX;
alter table csrimp.map_sheet_value_change add constraint uk_map_sheet_value_change unique (csrimp_session_id, new_sheet_value_change_id) USING INDEX;
alter table csrimp.map_imp_conflict add constraint pk_map_imp_conflict primary key (csrimp_session_id, old_imp_conflict_id) USING INDEX;
alter table csrimp.map_imp_conflict add constraint uk_map_imp_conflict unique (csrimp_session_id, new_imp_conflict_id) USING INDEX;
alter table csrimp.map_imp_ind add constraint pk_map_imp_ind primary key (csrimp_session_id, old_imp_ind_id) USING INDEX;
alter table csrimp.map_imp_ind add constraint uk_map_imp_ind unique (csrimp_session_id, new_imp_ind_id) USING INDEX;
alter table csrimp.map_imp_region add constraint pk_map_imp_region primary key (csrimp_session_id, old_imp_region_id) USING INDEX;
alter table csrimp.map_imp_region add constraint uk_map_imp_region unique (csrimp_session_id, new_imp_region_id) USING INDEX;
alter table csrimp.map_imp_measure add constraint pk_map_imp_measure primary key (csrimp_session_id, old_imp_measure_id) USING INDEX;
alter table csrimp.map_imp_measure add constraint uk_map_imp_measure unique (csrimp_session_id, new_imp_measure_id) USING INDEX;
alter table csrimp.map_imp_val add constraint pk_map_imp_val primary key (csrimp_session_id, old_imp_val_id) USING INDEX;
alter table csrimp.map_imp_val add constraint uk_map_imp_val unique (csrimp_session_id, new_imp_val_id) USING INDEX;
alter table csrimp.map_val add constraint pk_map_val primary key (csrimp_session_id, old_val_id) USING INDEX;
alter table csrimp.map_val add constraint uk_map_val unique (csrimp_session_id, new_val_id) USING INDEX;
alter table csrimp.map_ind_validation_rule add constraint pk_map_ind_validation_rule primary key (csrimp_session_id, old_ind_validation_rule_id) USING INDEX;
alter table csrimp.map_ind_validation_rule add constraint uk_map_ind_validation_rule unique (csrimp_session_id, new_ind_validation_rule_id) USING INDEX;
alter table csrimp.map_delegation_ind_cond add constraint pk_map_delegation_ind_cond primary key (csrimp_session_id, old_delegation_ind_cond_id) USING INDEX;
alter table csrimp.map_delegation_ind_cond add constraint uk_map_delegation_ind_cond unique (csrimp_session_id, new_delegation_ind_cond_id) USING INDEX;
alter table csrimp.map_deleg_plan_col add constraint pk_map_deleg_plan_col primary key (csrimp_session_id, old_deleg_plan_col_id) USING INDEX;
alter table csrimp.map_deleg_plan_col add constraint uk_map_deleg_plan_col unique (csrimp_session_id, new_deleg_plan_col_id) USING INDEX;
alter table csrimp.map_deleg_plan_col_deleg add constraint pk_map_dlg_plan_col_dlg primary key (csrimp_session_id, old_deleg_plan_col_deleg_id) USING INDEX;
alter table csrimp.map_deleg_plan_col_deleg add constraint uk_map_dlg_plan_col_dlg unique (csrimp_session_id, new_deleg_plan_col_deleg_id) USING INDEX;
alter table csrimp.map_form_expr add constraint pk_map_form_expr primary key (csrimp_session_id, old_form_expr_id) USING INDEX;
alter table csrimp.map_form_expr add constraint uk_map_form_expr unique (csrimp_session_id, new_form_expr_id) USING INDEX;
alter table csrimp.map_factor add constraint pk_map_factor primary key (csrimp_session_id, old_factor_id) USING INDEX;
alter table csrimp.map_factor add constraint uk_map_factor unique (csrimp_session_id, new_factor_id) USING INDEX;
alter table csrimp.map_deleg_ind_group add constraint pk_map_deleg_ind_group primary key (csrimp_session_id, old_deleg_ind_group_id) USING INDEX;
alter table csrimp.map_deleg_ind_group add constraint uk_map_deleg_ind_group unique (csrimp_session_id, new_deleg_ind_group_id) USING INDEX;
alter table csrimp.map_var_expl_group add constraint pk_map_var_expl_group primary key (csrimp_session_id, old_var_expl_group_id) USING INDEX;
alter table csrimp.map_var_expl_group add constraint uk_map_var_expl_group unique (csrimp_session_id, new_var_expl_group_id) USING INDEX;
alter table csrimp.map_var_expl add constraint pk_map_var_expl primary key (csrimp_session_id, old_var_expl_id) USING INDEX;
alter table csrimp.map_var_expl add constraint uk_map_var_expl unique (csrimp_session_id, new_var_expl_id) USING INDEX;
alter table csrimp.map_cms_schema add constraint pk_map_cms_schema primary key (csrimp_session_id,old_oracle_schema) USING INDEX;
alter table csrimp.map_cms_schema add constraint uk_map_cms_schema unique (csrimp_session_id, new_oracle_schema) USING INDEX;
alter table csrimp.map_cms_tab_column add constraint pk_map_cms_tab_column primary key (csrimp_session_id, old_column_id) USING INDEX;
alter table csrimp.map_cms_tab_column add constraint uk_map_cms_tab_column unique (csrimp_session_id, new_column_id) USING INDEX;
alter table csrimp.map_cms_tab_column_link add constraint pk_map_cms_tab_column_link primary key (csrimp_session_id, old_column_link_id) USING INDEX;
alter table csrimp.map_cms_tab_column_link add constraint uk_map_cms_tab_column_link unique (csrimp_session_id, new_column_link_id) USING INDEX;
alter table csrimp.map_cms_uk_cons add constraint pk_map_cms_uk_cons primary key (csrimp_session_id, old_uk_cons_id) USING INDEX;
alter table csrimp.map_cms_uk_cons add constraint uk_map_cms_uk_cons unique (csrimp_session_id, new_uk_cons_id) USING INDEX;
alter table csrimp.map_cms_fk_cons add constraint pk_map_cms_fk_cons primary key (csrimp_session_id, old_fk_cons_id) USING INDEX;
alter table csrimp.map_cms_fk_cons add constraint uk_map_cms_fk_cons unique (csrimp_session_id, new_fk_cons_id) USING INDEX;
alter table csrimp.map_cms_ck_cons add constraint pk_map_cms_ck_cons primary key (csrimp_session_id, old_ck_cons_id) USING INDEX;
alter table csrimp.map_cms_ck_cons add constraint uk_map_cms_ck_cons unique (csrimp_session_id, new_ck_cons_id) USING INDEX;
alter table csrimp.map_cms_display_template add constraint pk_map_cms_display_template primary key (csrimp_session_id, old_display_template_id) USING INDEX;
alter table csrimp.map_cms_display_template add constraint uk_map_cms_display_template unique (csrimp_session_id, new_display_template_id) USING INDEX;
alter table csrimp.map_cms_image add constraint pk_map_cms_image primary key (csrimp_session_id, old_image_id) USING INDEX;
alter table csrimp.map_cms_image add constraint uk_map_cms_image unique (csrimp_session_id, new_image_id) USING INDEX;
alter table csrimp.map_cms_tag add constraint pk_map_cms_tag primary key (csrimp_session_id, old_tag_id) USING INDEX;
alter table csrimp.map_cms_tag add constraint uk_map_cms_tag unique (csrimp_session_id, new_tag_id) USING INDEX;
alter table csrimp.map_flow_state add constraint pk_map_flow_state primary key (csrimp_session_id, old_flow_state_id) USING INDEX;
alter table csrimp.map_flow_state add constraint uk_map_flow_state unique (csrimp_session_id, new_flow_state_id) USING INDEX;
alter table csrimp.map_flow_item add constraint pk_map_flow_item primary key (csrimp_session_id, old_flow_item_id) USING INDEX;
alter table csrimp.map_flow_item add constraint uk_map_flow_item unique (csrimp_session_id, new_flow_item_id) USING INDEX;
alter table csrimp.map_flow_state_log add constraint pk_map_flow_state_log primary key (csrimp_session_id, old_flow_state_log_id) USING INDEX;
alter table csrimp.map_flow_state_log add constraint uk_map_flow_state_log unique (csrimp_session_id, new_flow_state_log_id) USING INDEX;
alter table csrimp.map_flow_state_transition add constraint pk_map_flow_state_transition primary key (csrimp_session_id, old_flow_state_transition_id) USING INDEX;
alter table csrimp.map_flow_state_transition add constraint uk_map_flow_state_transition unique (csrimp_session_id, new_flow_state_transition_id) USING INDEX;
alter table csrimp.map_flow_transition_alert add constraint pk_map_flow_transition_alert primary key (csrimp_session_id, old_flow_transition_alert_id) USING INDEX;
alter table csrimp.map_flow_transition_alert add constraint uk_map_flow_transition_alert unique (csrimp_session_id, new_flow_transition_alert_id) USING INDEX;
alter table csrimp.map_flow_state_rl_cap add constraint pk_map_flow_state_rl_cap primary key (csrimp_session_id, old_flow_state_rl_cap_id) USING INDEX;
alter table csrimp.map_flow_state_rl_cap add constraint uk_map_flow_state_rl_cap unique (csrimp_session_id, new_flow_state_rl_cap_id) USING INDEX;
alter table csrimp.map_meter_raw_data_source add constraint pk_map_meter_raw_data_source primary key (csrimp_session_id, old_raw_data_source_id) USING INDEX;
alter table csrimp.map_meter_raw_data_source add constraint uk_map_meter_raw_data_source unique (csrimp_session_id, new_raw_data_source_id) USING INDEX;
alter table csrimp.map_live_data_duration add constraint pk_map_live_data_duration primary key (csrimp_session_id, old_live_data_duration_id) USING INDEX;
alter table csrimp.map_live_data_duration add constraint uk_map_live_data_duration unique (csrimp_session_id, new_live_data_duration_id) USING INDEX;
alter table csrimp.map_utility_supplier add constraint pk_map_utility_supplier primary key (csrimp_session_id, old_utility_supplier_id) USING INDEX;
alter table csrimp.map_utility_supplier add constraint uk_map_utility_supplier unique (csrimp_session_id, new_utility_supplier_id) USING INDEX;
alter table csrimp.map_utility_contract add constraint pk_map_utility_contract primary key (csrimp_session_id, old_utility_contract_id) USING INDEX;
alter table csrimp.map_utility_contract add constraint uk_map_utility_contract unique (csrimp_session_id, new_utility_contract_id) USING INDEX;
alter table csrimp.map_utility_invoice add constraint pk_map_utility_invoice primary key (csrimp_session_id, old_utility_invoice_id) USING INDEX;
alter table csrimp.map_utility_invoice add constraint uk_map_utility_invoice unique (csrimp_session_id, new_utility_invoice_id) USING INDEX;
alter table csrimp.map_meter_alarm add constraint pk_map_meter_alarm primary key (csrimp_session_id, old_meter_alarm_id) USING INDEX;
alter table csrimp.map_meter_alarm add constraint uk_map_meter_alarm unique (csrimp_session_id, new_meter_alarm_id) USING INDEX;
alter table csrimp.map_meter_alarm_statistic add constraint pk_map_meter_alarm_statistic primary key (csrimp_session_id, old_statistic_id) USING INDEX;
alter table csrimp.map_meter_alarm_statistic add constraint uk_map_meter_alarm_statistic unique (csrimp_session_id, new_statistic_id) USING INDEX;
alter table csrimp.map_meter_alarm_comparison add constraint pk_map_meter_alarm_comparison primary key (csrimp_session_id, old_comparison_id) USING INDEX;
alter table csrimp.map_meter_alarm_comparison add constraint uk_map_meter_alarm_comparison unique (csrimp_session_id, new_comparison_id) USING INDEX;
alter table csrimp.map_meter_alarm_test_time add constraint pk_map_meter_alarm_test_time primary key (csrimp_session_id, old_test_time_id) USING INDEX;
alter table csrimp.map_meter_alarm_test_time add constraint uk_map_meter_alarm_test_time unique (csrimp_session_id, new_test_time_id) USING INDEX;
alter table csrimp.map_meter_alarm_issue_period add constraint pk_map_meter_alrm_iss_period primary key (csrimp_session_id, old_issue_period_id) USING INDEX;
alter table csrimp.map_meter_alarm_issue_period add constraint uk_map_meter_alrm_iss_period unique (csrimp_session_id, new_issue_period_id) USING INDEX;
alter table csrimp.map_meter_raw_data add constraint pk_map_meter_raw_data primary key (csrimp_session_id, old_meter_raw_data_id) USING INDEX;
alter table csrimp.map_meter_raw_data add constraint uk_map_meter_raw_data unique (csrimp_session_id, new_meter_raw_data_id) USING INDEX;
alter table csrimp.map_meter_reading add constraint pk_map_meter_reading primary key (csrimp_session_id, old_meter_reading_id) USING INDEX;
alter table csrimp.map_meter_reading add constraint uk_map_meter_reading unique (csrimp_session_id, new_meter_reading_id) USING INDEX;
alter table csrimp.map_event add constraint pk_map_event primary key (csrimp_session_id, old_event_id) USING INDEX;
alter table csrimp.map_event add constraint uk_map_event unique (csrimp_session_id, new_event_id) USING INDEX;
alter table csrimp.map_meter_document add constraint pk_map_meter_document primary key (csrimp_session_id, old_meter_document_id) USING INDEX;
alter table csrimp.map_meter_document add constraint uk_map_meter_document unique (csrimp_session_id, new_meter_document_id) USING INDEX;
alter table csrimp.map_issue_pending_val add constraint pk_map_issue_pending_val primary key (csrimp_session_id, old_issue_pending_val_id) USING INDEX;
alter table csrimp.map_issue_pending_val add constraint uk_map_issue_pending_val unique (csrimp_session_id, new_issue_pending_val_id) USING INDEX;
alter table csrimp.map_issue_sheet_value add constraint pk_map_issue_sheet_value primary key (csrimp_session_id, old_issue_sheet_value_id) USING INDEX;
alter table csrimp.map_issue_sheet_value add constraint uk_map_issue_sheet_value unique (csrimp_session_id, new_issue_sheet_value_id) USING INDEX;
alter table csrimp.map_issue_meter add constraint pk_map_issue_meter primary key (csrimp_session_id, old_issue_meter_id) USING INDEX;
alter table csrimp.map_issue_meter add constraint uk_map_issue_meter unique (csrimp_session_id, new_issue_meter_id) USING INDEX;
alter table csrimp.map_issue_meter_alarm add constraint pk_map_issue_meter_alarm primary key (csrimp_session_id, old_issue_meter_alarm_id) USING INDEX;
alter table csrimp.map_issue_meter_alarm add constraint uk_map_issue_meter_alarm unique (csrimp_session_id, new_issue_meter_alarm_id) USING INDEX;
alter table csrimp.map_issue_meter_data_source add constraint pk_map_issue_meter_data_source primary key (csrimp_session_id, old_issue_meter_data_source_id) USING INDEX;
alter table csrimp.map_issue_meter_data_source add constraint uk_map_issue_meter_data_source unique (csrimp_session_id, new_issue_meter_data_source_id) USING INDEX;
alter table csrimp.map_issue_meter_raw_data add constraint pk_map_issue_meter_raw_data primary key (csrimp_session_id, old_issue_meter_raw_data_id) USING INDEX;
alter table csrimp.map_issue_meter_raw_data add constraint uk_map_issue_meter_raw_data unique (csrimp_session_id, new_issue_meter_raw_data_id) USING INDEX;
alter table csrimp.map_issue_priority add constraint pk_map_issue_priority primary key (csrimp_session_id, old_issue_priority_id) USING INDEX;
alter table csrimp.map_issue_priority add constraint uk_map_issue_priority unique (csrimp_session_id, new_issue_priority_id) USING INDEX;
alter table csrimp.map_rag_status add constraint pk_map_rag_status primary key (csrimp_session_id, old_rag_status_id) USING INDEX;
alter table csrimp.map_rag_status add constraint uk_map_rag_status unique (csrimp_session_id, new_rag_status_id) USING INDEX;
alter table csrimp.map_issue add constraint pk_map_issue primary key (csrimp_session_id, old_issue_id) USING INDEX;
alter table csrimp.map_issue add constraint uk_map_issue unique (csrimp_session_id, new_issue_id) USING INDEX;
alter table csrimp.map_issue_log add constraint pk_map_issue_log primary key (csrimp_session_id, old_issue_log_id) USING INDEX;
alter table csrimp.map_issue_log add constraint uk_map_issue_log unique (csrimp_session_id, new_issue_log_id) USING INDEX;
alter table csrimp.map_issue_custom_field add constraint pk_map_issue_custom_field primary key (csrimp_session_id, old_issue_custom_field_id) USING INDEX;
alter table csrimp.map_issue_custom_field add constraint uk_map_issue_custom_field unique (csrimp_session_id, new_issue_custom_field_id) USING INDEX;
alter table csrimp.map_correspondent add constraint pk_map_correspondent primary key (csrimp_session_id, old_correspondent_id) USING INDEX;
alter table csrimp.map_correspondent add constraint uk_map_correspondent unique (csrimp_session_id, new_correspondent_id) USING INDEX;
alter table csrimp.map_deleg_plan_col_survey add constraint pk_map_deleg_plan_col_survey primary key (csrimp_session_id, old_deleg_plan_col_survey_id) USING INDEX;
alter table csrimp.map_deleg_plan_col_survey add constraint uk_map_deleg_plan_col_survey unique (csrimp_session_id, new_deleg_plan_col_survey_id) USING INDEX;
alter table csrimp.map_tab add constraint pk_map_tab primary key (csrimp_session_id, old_tab_id) USING INDEX;
alter table csrimp.map_tab add constraint uk_map_tab unique (csrimp_session_id, new_tab_id) USING INDEX;
alter table csrimp.map_tab_portlet add constraint pk_map_tab_portlet primary key (csrimp_session_id, old_tab_portlet_id) USING INDEX;
alter table csrimp.map_tab_portlet add constraint uk_map_tab_portlet unique (csrimp_session_id, new_tab_portlet_id) USING INDEX;
alter table csrimp.map_dashboard_instance add constraint pk_map_dashboard_instance primary key (csrimp_session_id, old_dashboard_instance_id) USING INDEX;
alter table csrimp.map_dashboard_instance add constraint uk_map_dashboard_instance unique (csrimp_session_id, new_dashboard_instance_id) USING INDEX;
alter table csrimp.map_tpl_report_non_compl add constraint pk_map_tpl_report_non_compl primary key (csrimp_session_id, old_tpl_report_non_compl_id) USING INDEX;
alter table csrimp.map_tpl_report_non_compl add constraint uk_map_tpl_report_non_compl unique (csrimp_session_id, new_tpl_report_non_compl_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_ind add constraint pk_map_tpl_report_tag_ind primary key (csrimp_session_id, old_tpl_report_tag_ind_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_ind add constraint uk_map_tpl_report_tag_ind unique (csrimp_session_id, new_tpl_report_tag_ind_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_eval add constraint pk_map_tpl_report_tag_eval primary key (csrimp_session_id, old_tpl_report_tag_eval_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_eval add constraint uk_map_tpl_report_tag_eval unique (csrimp_session_id, new_tpl_report_tag_eval_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_dv add constraint pk_map_tpl_report_tag_dv primary key (csrimp_session_id, old_tpl_report_tag_dv_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_dv add constraint uk_map_tpl_report_tag_dv unique (csrimp_session_id, new_tpl_report_tag_dv_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_log_frm add constraint pk_map_tpl_report_tag_log_frm primary key (csrimp_session_id, old_tpl_report_tag_log_frm_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_log_frm add constraint uk_map_tpl_report_tag_log_frm unique (csrimp_session_id, new_tpl_report_tag_log_frm_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_text add constraint pk_map_tpl_report_tag_text primary key (csrimp_session_id, old_tpl_report_tag_text_id) USING INDEX;
alter table csrimp.map_tpl_report_tag_text add constraint uk_map_tpl_report_tag_text unique (csrimp_session_id, new_tpl_report_tag_text_id) USING INDEX;
alter table csrimp.map_aggregate_ind_group add constraint pk_map_aggregate_ind_group primary key (csrimp_session_id, old_aggregate_ind_group_id) USING INDEX;
alter table csrimp.map_aggregate_ind_group add constraint uk_map_aggregate_ind_group unique (csrimp_session_id, new_aggregate_ind_group_id) USING INDEX;
alter table csrimp.map_dashboard_item add constraint pk_map_dashboard_item primary key (csrimp_session_id, old_dashboard_item_id) USING INDEX;
alter table csrimp.map_dashboard_item add constraint uk_map_dashboard_item unique (csrimp_session_id, new_dashboard_item_id) USING INDEX;
alter table csrimp.map_dataview_zone add constraint pk_map_dataview_zone primary key (csrimp_session_id, old_dataview_zone_id) USING INDEX;
alter table csrimp.map_dataview_zone add constraint uk_map_dataview_zone unique (csrimp_session_id, new_dataview_zone_id) USING INDEX;
alter table csrimp.map_user_cover add constraint pk_map_user_cover primary key (csrimp_session_id, old_user_cover_id) USING INDEX;
alter table csrimp.map_user_cover add constraint uk_map_user_cover unique (csrimp_session_id, new_user_cover_id) USING INDEX;
alter table csrimp.map_doc add constraint pk_map_doc primary key (csrimp_session_id, old_doc_id) USING INDEX;
alter table csrimp.map_doc add constraint uk_map_doc unique (csrimp_session_id, new_doc_id) USING INDEX;
alter table csrimp.map_doc_data add constraint pk_map_doc_data primary key (csrimp_session_id, old_doc_data_id) USING INDEX;
alter table csrimp.map_doc_data add constraint uk_map_doc_data unique (csrimp_session_id, new_doc_data_id) USING INDEX;
alter table csrimp.map_internal_audit_type add constraint pk_map_internal_audit_type primary key (csrimp_session_id, old_internal_audit_type_id) USING INDEX;
alter table csrimp.map_internal_audit_type add constraint uk_map_internal_audit_type unique (csrimp_session_id, new_internal_audit_type_id) USING INDEX;
alter table csrimp.map_audit_closure_type add constraint pk_map_audit_closure_type primary key (csrimp_session_id, old_audit_closure_type_id) USING INDEX;
alter table csrimp.map_audit_closure_type add constraint uk_map_audit_closure_type unique (csrimp_session_id, new_audit_closure_type_id) USING INDEX;
alter table csrimp.map_model_range add constraint pk_map_model_range primary key (csrimp_session_id, old_range_id) USING INDEX;
alter table csrimp.map_model_range add constraint uk_map_model_range unique (csrimp_session_id, new_range_id) USING INDEX;
alter table csrimp.map_model_sheet add constraint pk_map_model_sheet primary key (csrimp_session_id, old_sheet_id) USING INDEX;
alter table csrimp.map_model_sheet add constraint uk_map_model_sheet unique (csrimp_session_id, new_sheet_id) USING INDEX;
alter table csrimp.map_non_compliance add constraint pk_map_non_compliance primary key (csrimp_session_id, old_non_compliance_id) USING INDEX;
alter table csrimp.map_non_compliance add constraint uk_map_non_compliance unique (csrimp_session_id, new_non_compliance_id) USING INDEX;
alter table csrimp.map_qs_type add constraint pk_map_qs_type primary key (csrimp_session_id, old_quick_survey_type_id) USING INDEX;
alter table csrimp.map_qs_type add constraint uk_map_qs_type unique (csrimp_session_id, new_quick_survey_type_id) USING INDEX;
alter table csrimp.map_qs_survey_response add constraint pk_map_qs_survey_response primary key (csrimp_session_id, old_survey_response_id) USING INDEX;
alter table csrimp.map_qs_survey_response add constraint uk_map_qs_survey_response unique (csrimp_session_id, new_survey_response_id) USING INDEX;
alter table csrimp.map_qs_question add constraint pk_map_qs_question primary key (csrimp_session_id, old_question_id) USING INDEX;
alter table csrimp.map_qs_question add constraint uk_map_qs_question unique (csrimp_session_id, new_question_id) USING INDEX;
alter table csrimp.map_qs_custom_question_type add constraint pk_map_qs_cust_quest_type primary key (csrimp_session_id, old_custom_question_type_id) USING INDEX;
alter table csrimp.map_qs_custom_question_type add constraint uk_map_qs_cust_quest_type unique (csrimp_session_id, new_custom_question_type_id) USING INDEX;
alter table csrimp.map_qs_submission add constraint pk_map_qs_submission primary key (csrimp_session_id, old_submission_id) USING INDEX;
alter table csrimp.map_qs_submission add constraint uk_map_qs_submission unique (csrimp_session_id, new_submission_id) USING INDEX;
alter table csrimp.map_score_threshold add constraint pk_map_score_threshold primary key (csrimp_session_id, old_score_threshold_id) USING INDEX;
alter table csrimp.map_score_threshold add constraint uk_map_score_threshold unique (csrimp_session_id, new_score_threshold_id) USING INDEX;
alter table csrimp.map_qs_question_option add constraint pk_map_qs_question_option primary key (csrimp_session_id, old_question_option_id) USING INDEX;
alter table csrimp.map_qs_question_option add constraint uk_map_qs_question_option unique (csrimp_session_id, new_question_option_id) USING INDEX;
alter table csrimp.map_qs_answer_file add constraint pk_map_qs_answer_file primary key (csrimp_session_id, old_qs_answer_file_id) USING INDEX;
alter table csrimp.map_qs_answer_file add constraint uk_map_qs_answer_file unique (csrimp_session_id, new_qs_answer_file_id) USING INDEX;
alter table csrimp.map_qs_expr add constraint pk_map_qs_expr primary key (csrimp_session_id, old_expr_id) USING INDEX;
alter table csrimp.map_qs_expr add constraint uk_map_qs_expr unique (csrimp_session_id, new_expr_id) USING INDEX;
alter table csrimp.map_qs_expr_msg_action add constraint pk_map_qs_expr_msg_action primary key (csrimp_session_id, old_qs_expr_msg_action_id) USING INDEX;
alter table csrimp.map_qs_expr_msg_action add constraint uk_map_qs_expr_msg_action unique (csrimp_session_id, new_qs_expr_msg_action_id) USING INDEX;
alter table csrimp.map_qs_expr_nc_action add constraint pk_map_qs_expr_nc_action primary key (csrimp_session_id, old_qs_expr_nc_action_id) USING INDEX;
alter table csrimp.map_qs_expr_nc_action add constraint uk_map_qs_expr_nc_action unique (csrimp_session_id, new_qs_expr_nc_action_id) USING INDEX;
alter table csrimp.map_region_set add constraint pk_map_region_set primary key (csrimp_session_id, old_region_set_id) USING INDEX;
alter table csrimp.map_region_set add constraint uk_map_region_set unique (csrimp_session_id, new_region_set_id) USING INDEX;
alter table csrimp.map_postit add constraint pk_map_postit primary key (csrimp_session_id, old_postit_id) USING INDEX;
alter table csrimp.map_postit add constraint uk_map_postit unique (csrimp_session_id, new_postit_id) USING INDEX;
alter table csrimp.map_issue_survey_answer add constraint pk_map_issue_survey_answer primary key (csrimp_session_id, old_issue_survey_answer_id) USING INDEX;
alter table csrimp.map_issue_survey_answer add constraint uk_map_issue_survey_answer unique (csrimp_session_id, new_issue_survey_answer_id) USING INDEX;
alter table csrimp.map_issue_non_compliance add constraint pk_map_issue_non_compliance primary key (csrimp_session_id, old_issue_non_compliance_id) USING INDEX;
alter table csrimp.map_issue_non_compliance add constraint uk_map_issue_non_compliance unique (csrimp_session_id, new_issue_non_compliance_id) USING INDEX;
alter table csrimp.map_alert add constraint pk_map_alert primary key (csrimp_session_id, old_alert_id) USING INDEX;
alter table csrimp.map_alert add constraint uk_map_alert unique (csrimp_session_id, new_alert_id) USING INDEX;
alter table csrimp.map_non_comp_default add constraint pk_map_non_comp_default primary key (csrimp_session_id, old_non_comp_default_id) USING INDEX;
alter table csrimp.map_non_comp_default add constraint uk_map_non_comp_default unique (csrimp_session_id, new_non_comp_default_id) USING INDEX;
alter table csrimp.map_non_comp_default_issue add constraint pk_map_non_comp_default_issue primary key (csrimp_session_id, old_non_comp_default_issue_id) USING INDEX;
alter table csrimp.map_non_comp_default_issue add constraint uk_map_non_comp_default_issue unique (csrimp_session_id, new_non_comp_default_issue_id) USING INDEX;
alter table csrimp.map_non_compliance_file add constraint pk_map_non_compliance_file primary key (csrimp_session_id, old_non_compliance_file_id) USING INDEX;
alter table csrimp.map_non_compliance_file add constraint uk_map_non_compliance_file unique (csrimp_session_id, new_non_compliance_file_id) USING INDEX;
alter table csrimp.map_deleg_date_schedule add constraint pk_map_deleg_date_schedule primary key (csrimp_session_id, old_deleg_date_schedule_id) USING INDEX;
alter table csrimp.map_deleg_date_schedule add constraint uk_map_deleg_date_schedule unique (csrimp_session_id, new_deleg_date_schedule_id) USING INDEX;
alter table csrimp.map_tenant add constraint pk_map_tenant primary key (csrimp_session_id, old_tenant_id) USING INDEX;
alter table csrimp.map_tenant add constraint uk_map_tenant unique (csrimp_session_id, new_tenant_id) USING INDEX;
alter table csrimp.map_space_type add constraint pk_map_space_type primary key (csrimp_session_id, old_space_type_id) USING INDEX;
alter table csrimp.map_space_type add constraint uk_map_space_type unique (csrimp_session_id, new_space_type_id) USING INDEX;
alter table csrimp.map_property_type add constraint pk_map_property_type primary key (csrimp_session_id, old_property_type_id) USING INDEX;
alter table csrimp.map_property_type add constraint uk_map_property_type unique (csrimp_session_id, new_property_type_id) USING INDEX;
alter table csrimp.map_sub_property_type add constraint pk_map_sub_property_type primary key (csrimp_session_id, old_sub_property_type_id) USING INDEX;
alter table csrimp.map_sub_property_type add constraint uk_map_sub_property_type unique (csrimp_session_id, new_sub_property_type_id) USING INDEX;
alter table csrimp.map_property_photo add constraint pk_map_property_photo primary key (csrimp_session_id, old_property_photo_id) USING INDEX;
alter table csrimp.map_property_photo add constraint uk_map_property_photo unique (csrimp_session_id, new_property_photo_id) USING INDEX;
alter table csrimp.map_lease add constraint pk_map_lease primary key (csrimp_session_id, old_lease_id) USING INDEX;
alter table csrimp.map_lease add constraint uk_map_lease unique (csrimp_session_id, new_lease_id) USING INDEX;
alter table csrimp.map_mgmt_company add constraint pk_map_mgmt_company primary key (csrimp_session_id, old_mgmt_company_id) USING INDEX;
alter table csrimp.map_mgmt_company add constraint uk_map_mgmt_company unique (csrimp_session_id, new_mgmt_company_id) USING INDEX;
alter table csrimp.map_fund add constraint pk_map_fund primary key (csrimp_session_id, old_fund_id) USING INDEX;
alter table csrimp.map_fund add constraint uk_map_fund unique (csrimp_session_id, new_fund_id) USING INDEX;
alter table csrimp.map_mgmt_company_contact add constraint pk_map_mgmt_company_contact primary key (csrimp_session_id, old_mgmt_company_contact_id) USING INDEX;
alter table csrimp.map_mgmt_company_contact add constraint uk_map_mgmt_company_contact unique (csrimp_session_id, new_mgmt_company_contact_id) USING INDEX;
alter table csrimp.map_meter_ind add constraint pk_map_meter_ind primary key (csrimp_session_id, old_meter_ind_id) USING INDEX;
alter table csrimp.map_meter_ind add constraint uk_map_meter_ind unique (csrimp_session_id, new_meter_ind_id) USING INDEX;
alter table csrimp.map_lease_type add constraint pk_map_lease_type primary key (csrimp_session_id, old_lease_type_id) USING INDEX;
alter table csrimp.map_lease_type add constraint uk_map_lease_type unique (csrimp_session_id, new_lease_type_id) USING INDEX;
alter table csrimp.map_fund_type add constraint pk_map_fund_type primary key (csrimp_session_id, old_fund_type_id) USING INDEX;
alter table csrimp.map_fund_type add constraint uk_map_fund_type unique (csrimp_session_id, new_fund_type_id) USING INDEX;
alter table csrimp.map_region_metric_val add constraint pk_map_region_metric_val primary key (csrimp_session_id, old_region_metric_val_id) USING INDEX;
alter table csrimp.map_region_metric_val add constraint uk_map_region_metric_val unique (csrimp_session_id, new_region_metric_val_id) USING INDEX;
alter table csrimp.map_plugin add constraint pk_map_plugin primary key (csrimp_session_id, old_plugin_id) USING INDEX;
alter table csrimp.map_plugin add constraint uk_map_plugin unique (csrimp_session_id, new_plugin_id) USING INDEX;
alter table csrimp.MAP_SUPPLIER_SCORE add constraint PK_MAP_SUPPLIER_SCORE primary key (csrimp_session_id, OLD_SUPPLIER_SCORE_ID) USING INDEX;
alter table csrimp.MAP_SUPPLIER_SCORE add constraint UK_MAP_SUPPLIER_SCORE unique (csrimp_session_id, new_SUPPLIER_SCORE_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_GROUP_CAPABILI add constraint PK_MAP_CHAIN_GROUP_CAPABILI primary key (csrimp_session_id, OLD_GROUP_CAPABILITY_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_GROUP_CAPABILI add constraint UK_MAP_CHAIN_GROUP_CAPABILI unique (csrimp_session_id, new_GROUP_CAPABILITY_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_COMPANY_TYPE add constraint PK_MAP_CHAIN_COMPANY_TYPE primary key (csrimp_session_id, OLD_COMPANY_TYPE_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_COMPANY_TYPE add constraint UK_MAP_CHAIN_COMPANY_TYPE unique (csrimp_session_id, new_COMPANY_TYPE_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_CAPABILITY add constraint PK_MAP_CHAIN_CAPABILITY primary key (csrimp_session_id, OLD_CAPABILITY_ID) USING INDEX;
alter table csrimp.MAP_CHAIN_CAPABILITY add constraint UK_MAP_CHAIN_CAPABILITY unique (csrimp_session_id, new_CAPABILITY_ID) USING INDEX;

declare
	type t_tabs is table of varchar2(30);
	v_tab_list t_tabs;
begin	
	v_tab_list := t_tabs(
		'DELEG_PLAN_APPLIED',
		'DELEG_PLAN',
		'DELEGATION_IND_TAG',
		'DELEGATION_IND_COND',
		'SECTION_STATUS',
		'DATAVIEW_REGION_MEMBER',
		'DELEGATION_USER',
		'DELEGATION_REGION',
		'DELEGATION_IND',
		'PCT_OWNERSHIP',
		'REGION_TAG',
		'IND_ACCURACY_TYPE',
		'IND_TAG',
		'IND_FLAG',
		'CUSTOMER_ALERT_TYPE',
		'INTERNAL_AUDIT',
		'EXCEL_EXPORT_OPTIONS',
		'METER_READING_PERIOD',
		'METER_READING',
		'METER_RAW_DATA_STATUS',
		'METER_RAW_DATA_SOURCE',
		'METER_RAW_DATA_ERROR',
		'METER_RAW_DATA',
		'METER_METER_ALARM_STATISTIC',
		'METER_LIVE_DATA',
		'METER_LIST_CACHE',
		'METER_EXCEL_OPTION',
		'METER_EXCEL_MAPPING',
		'METER_DOCUMENT',
		'METER_ALARM_TEST_TIME',
		'METER_ALARM_STATISTIC_PERIOD',
		'METER_ALARM_STATISTIC_JOB',
		'METER_ALARM_STATISTIC',
		'METER_ALARM_STAT_RUN',
		'METER_ALARM_ISSUE_PERIOD',
		'METER_ALARM_EVENT',
		'METER_ALARM_COMPARISON',
		'METER_ALARM',
		'ISSUE_TYPE',
		'ISSUE_SURVEY_ANSWER',
		'NON_COMPLIANCE_FILE_UPLOAD',
		'NON_COMPLIANCE',
		'MODEL_VALIDATION',
		'REGION_EVENT',
		'REGION_PROC_FILE',
		'REGION_PROC_DOC',
		'REGION_METER_ALARM',
		'METER_XML_OPTION',
		'UTILITY_SUPPLIER',
		'UTILITY_INVOICE',
		'UTILITY_CONTRACT',
		'METER_UTILITY_CONTRACT',
		'METER_SOURCE_TYPE',
		'REGION_OWNER',
		'QUICK_SURVEY_QUESTION',
		'DELEG_PLAN_ROLE',
		'DELEG_PLAN_REGION',
		'ISSUE_NON_COMPLIANCE',
		'ISSUE_METER_RAW_DATA',
		'ISSUE_METER_DATA_SOURCE',
		'ISSUE_METER_ALARM',
		'ISSUE_METER',
		'ISSUE_ACTION',
		'LIVE_DATA_DURATION',
		'EVENT',
		'ALL_METER',
		'DELEGATION_USER_COVER',
		'DELEGATION_TAG',
		'USER_COVER',
		'EXPORT_FEED',
		'EXPORT_FEED_CMS_FORM',
		'EXPORT_FEED_DATAVIEW',
		'DELEGATION_DATE_SCHEDULE',
		'SHEET_DATE_SCHEDULE'
	);
	for i in 1 .. v_tab_list.count loop
		dbms_output.put_line('processing '||v_tab_list(i));
		for r in (select constraint_name from all_constraints where owner='CSRIMP' and table_name = v_tab_list(i) and constraint_type in ('P')) loop
			dbms_output.put_line('running alter table csrimp.'||v_tab_list(i)||' drop constraint '||r.constraint_name||' drop index');
			execute immediate 'alter table csrimp.'||v_tab_list(i)||' drop constraint '||r.constraint_name||' drop index';
		end loop;
	end loop;
end;
/


alter table csrimp.DELEG_PLAN_APPLIED add constraint PK_DELEG_PLAN_APPLIED primary key (csrimp_session_id, DELEG_PLAN_APPLIED_ID);
alter table csrimp.DELEG_PLAN add constraint PK_DELEG_PLAN primary key (csrimp_session_id, DELEG_PLAN_SID);
alter table csrimp.DELEGATION_IND_TAG add constraint PK_DELEGATION_IND_TAG primary key (csrimp_session_id, DELEGATION_SID, IND_SID, TAG);
alter table csrimp.DELEGATION_IND_COND add constraint PK_DELEGATION_IND_COND primary key (csrimp_session_id, DELEGATION_SID, IND_SID, DELEGATION_IND_COND_ID);
alter table csrimp.SECTION_STATUS add constraint PK_SECTION_STATUS primary key (csrimp_session_id, SECTION_STATUS_SID);
alter table csrimp.DATAVIEW_REGION_MEMBER add constraint PK_DATAVIEW_REGION_MEMBER primary key (csrimp_session_id, DATAVIEW_SID, REGION_SID);
alter table csrimp.DELEGATION_USER add constraint PK_DELEGATION_USER primary key (csrimp_session_id, DELEGATION_SID, USER_SID);
alter table csrimp.DELEGATION_REGION add constraint PK_DELEGATION_REGION primary key (csrimp_session_id, DELEGATION_SID, REGION_SID);
alter table csrimp.DELEGATION_IND add constraint PK_DELEGATION_IND primary key (csrimp_session_id, DELEGATION_SID, IND_SID);
alter table csrimp.PCT_OWNERSHIP add constraint PK_PCT_OWNERSHIP primary key (csrimp_session_id, REGION_SID, START_DTM);
alter table csrimp.REGION_TAG add constraint PK_REGION_TAG primary key (csrimp_session_id, TAG_ID, REGION_SID);
alter table csrimp.IND_ACCURACY_TYPE add constraint PK_IND_ACCURACY_TYPE primary key (csrimp_session_id, IND_SID, ACCURACY_TYPE_ID);
alter table csrimp.IND_TAG add constraint PK_IND_TAG primary key (csrimp_session_id, TAG_ID, IND_SID);
alter table csrimp.IND_FLAG add constraint PK_IND_FLAG primary key (csrimp_session_id, IND_SID, FLAG);
alter table csrimp.CUSTOMER_ALERT_TYPE add constraint PK_CUSTOMER_ALERT_TYPE primary key (csrimp_session_id, CUSTOMER_ALERT_TYPE_ID);
alter table csrimp.INTERNAL_AUDIT add constraint PK_INTERNAL_AUDIT primary key (csrimp_session_id, INTERNAL_AUDIT_SID);
alter table csrimp.EXCEL_EXPORT_OPTIONS add constraint PK_EXCEL_EXPORT_OPTIONS primary key (csrimp_session_id, DATAVIEW_SID);
alter table csrimp.METER_READING add constraint PK_METER_READING primary key (csrimp_session_id, METER_READING_ID);
alter table csrimp.METER_RAW_DATA_STATUS add constraint PK_METER_RAW_DATA_STATUS primary key (csrimp_session_id, STATUS_ID);
alter table csrimp.METER_RAW_DATA_SOURCE add constraint PK_METER_RAW_DATA_SOURCE primary key (csrimp_session_id, RAW_DATA_SOURCE_ID);
alter table csrimp.METER_RAW_DATA_ERROR add constraint PK_METER_RAW_DATA_ERROR primary key (csrimp_session_id, METER_RAW_DATA_ID, ERROR_ID);
alter table csrimp.METER_RAW_DATA add constraint PK_METER_RAW_DATA primary key (csrimp_session_id, METER_RAW_DATA_ID);
alter table csrimp.METER_METER_ALARM_STATISTIC add constraint PK_METER_METER_ALARM_STAT primary key (csrimp_session_id, REGION_SID, STATISTIC_ID);
alter table csrimp.METER_LIVE_DATA add constraint PK_METER_LIVE_DATA primary key (csrimp_session_id, REGION_SID, LIVE_DATA_DURATION_ID, START_DTM);
alter table csrimp.METER_LIST_CACHE add constraint PK_METER_LIST_CACHE primary key (csrimp_session_id, REGION_SID);
alter table csrimp.METER_EXCEL_OPTION add constraint PK_METER_EXCEL_OPTION primary key (csrimp_session_id, RAW_DATA_SOURCE_ID);
alter table csrimp.METER_EXCEL_MAPPING add constraint PK_METER_EXCEL_MAPPING primary key (csrimp_session_id, RAW_DATA_SOURCE_ID, FIELD_NAME);
alter table csrimp.METER_DOCUMENT add constraint PK_METER_DOCUMENT primary key (csrimp_session_id, METER_DOCUMENT_ID);
alter table csrimp.METER_ALARM_TEST_TIME add constraint PK_METER_ALARM_TEST_TIME primary key (csrimp_session_id, TEST_TIME_ID);
alter table csrimp.METER_ALARM_STATISTIC_PERIOD add constraint PK_METER_ALARM_STAT_PERIOD primary key (csrimp_session_id, REGION_SID, STATISTIC_ID, STATISTIC_DTM);
alter table csrimp.METER_ALARM_STATISTIC_JOB add constraint PK_METER_ALARM_STATISTIC_JOB primary key (csrimp_session_id, REGION_SID, STATISTIC_ID);
alter table csrimp.METER_ALARM_STATISTIC add constraint PK_METER_ALARM_STATISTIC primary key (csrimp_session_id, STATISTIC_ID);
alter table csrimp.METER_ALARM_STAT_RUN add constraint PK_METER_ALARM_STAT_RUN primary key (csrimp_session_id, METER_ALARM_ID, REGION_SID, STATISTIC_ID);
alter table csrimp.METER_ALARM_ISSUE_PERIOD add constraint PK_METER_ALARM_ISSUE_PERIOD primary key (csrimp_session_id, ISSUE_PERIOD_ID);
alter table csrimp.METER_ALARM_EVENT add constraint PK_METER_ALARM_EVENT primary key (csrimp_session_id, REGION_SID, METER_ALARM_ID, METER_ALARM_EVENT_ID);
alter table csrimp.METER_ALARM_COMPARISON add constraint PK_METER_ALARM_COMPARISON primary key (csrimp_session_id, COMPARISON_ID);
alter table csrimp.METER_ALARM add constraint PK_METER_ALARM primary key (csrimp_session_id, METER_ALARM_ID);
alter table csrimp.ISSUE_TYPE add constraint PK_ISSUE_TYPE primary key (csrimp_session_id, ISSUE_TYPE_ID);
alter table csrimp.ISSUE_SURVEY_ANSWER add constraint PK_ISSUE_SURVEY_ANSER primary key (csrimp_session_id, ISSUE_SURVEY_ANSWER_ID);
alter table csrimp.NON_COMPLIANCE_FILE_UPLOAD add constraint PK_NON_COMPLIANCE_FILE_UPLOAD primary key (csrimp_session_id, NON_COMPLIANCE_ID, FILE_UPLOAD_SID);
alter table csrimp.NON_COMPLIANCE add constraint PK_NON_COMPLIANCE primary key (csrimp_session_id, NON_COMPLIANCE_ID);
alter table csrimp.MODEL_VALIDATION add constraint PK_MODEL_VALIDATION primary key (csrimp_session_id, MODEL_SID, CELL_NAME, DISPLAY_SEQ, SHEET_ID);
alter table csrimp.REGION_EVENT add constraint PK_REGION_EVENT primary key (csrimp_session_id, REGION_SID, EVENT_ID);
alter table csrimp.REGION_PROC_FILE add constraint PK_REGION_PROC_FILE primary key (csrimp_session_id, REGION_SID, METER_DOCUMENT_ID);
alter table csrimp.REGION_PROC_DOC add constraint PK_REGION_PROC_DOC primary key (csrimp_session_id, REGION_SID, DOC_ID);
alter table csrimp.REGION_METER_ALARM add constraint PK_REGION_METER_ALARM primary key (csrimp_session_id, REGION_SID, METER_ALARM_ID);
alter table csrimp.METER_XML_OPTION add constraint PK_METER_XML_OPTION primary key (csrimp_session_id, RAW_DATA_SOURCE_ID);
alter table csrimp.UTILITY_SUPPLIER add constraint PK_UTILITY_SUPPLIER primary key (csrimp_session_id, UTILITY_SUPPLIER_ID);
alter table csrimp.UTILITY_INVOICE add constraint PK_UTILITY_INVOICE primary key (csrimp_session_id, UTILITY_INVOICE_ID);
alter table csrimp.UTILITY_CONTRACT add constraint PK_UTILITY_CONTRACT primary key (csrimp_session_id, UTILITY_CONTRACT_ID);
alter table csrimp.METER_UTILITY_CONTRACT add constraint PK_METER_UTILITY_CONTRACT primary key (csrimp_session_id, REGION_SID, UTILITY_CONTRACT_ID);
alter table csrimp.METER_SOURCE_TYPE add constraint PK_METER_SOURCE_TYPE primary key (csrimp_session_id, METER_SOURCE_TYPE_ID);
alter table csrimp.REGION_OWNER add constraint PK_REGION_OWNER primary key (csrimp_session_id, REGION_SID, USER_SID);
alter table csrimp.QUICK_SURVEY_QUESTION add constraint PK_QUICK_SURVEY_QUESTION primary key (csrimp_session_id, QUESTION_ID);
alter table csrimp.DELEG_PLAN_ROLE add constraint PK_DELEG_PLAN_ROLE primary key (csrimp_session_id, DELEG_PLAN_SID, ROLE_SID);
alter table csrimp.DELEG_PLAN_REGION add constraint PK_DELEG_PLAN_REGION primary key (csrimp_session_id, DELEG_PLAN_SID, REGION_SID);
alter table csrimp.ISSUE_NON_COMPLIANCE add constraint PK_ISSUE_NON_COMPLIANCE primary key (csrimp_session_id, ISSUE_NON_COMPLIANCE_ID);
alter table csrimp.ISSUE_METER_RAW_DATA add constraint PK_ISSUE_METER_RAW_DATA primary key (csrimp_session_id, ISSUE_METER_RAW_DATA_ID);
alter table csrimp.ISSUE_METER_DATA_SOURCE add constraint PK_ISSUE_METER_DATA_SOURCE primary key (csrimp_session_id, ISSUE_METER_DATA_SOURCE_ID);
alter table csrimp.ISSUE_METER_ALARM add constraint PK_ISSUE_METER_ALARM primary key (csrimp_session_id, ISSUE_METER_ALARM_ID);
alter table csrimp.ISSUE_METER add constraint PK_ISSUE_METER primary key (csrimp_session_id, ISSUE_METER_ID);
alter table csrimp.ISSUE_ACTION add constraint PK_ISSUE_ACTION primary key (csrimp_session_id, ISSUE_ACTION_ID);
alter table csrimp.LIVE_DATA_DURATION add constraint PK_LIVE_DATA_DURATION primary key (csrimp_session_id, LIVE_DATA_DURATION_ID);
alter table csrimp.EVENT add constraint PK_EVENT primary key (csrimp_session_id, EVENT_ID);
alter table csrimp.ALL_METER add constraint PK_ALL_METER primary key (csrimp_session_id, REGION_SID);
alter table csrimp.DELEGATION_USER_COVER add constraint PK_DELEGATION_USER_COVER primary key (csrimp_session_id, USER_COVER_ID, USER_GIVING_COVER_SID, USER_BEING_COVERED_SID, DELEGATION_SID);
alter table csrimp.DELEGATION_TAG add constraint PK_DELEGATION_TAG primary key (csrimp_session_id, DELEGATION_SID, TAG_ID);
alter table csrimp.USER_COVER add constraint PK_USER_COVER primary key (csrimp_session_id, USER_COVER_ID, USER_GIVING_COVER_SID, USER_BEING_COVERED_SID);
alter table csrimp.export_feed add CONSTRAINT PK_EXPORT_FEED PRIMARY KEY (CSRIMP_SESSION_ID, EXPORT_FEED_SID);
alter table csrimp.EXPORT_FEED_CMS_FORM add	CONSTRAINT PK_EXPORT_FEED_CMS_FORM PRIMARY KEY (CSRIMP_SESSION_ID, EXPORT_FEED_SID, FORM_SID);
alter table csrimp.EXPORT_FEED_DATAVIEW add CONSTRAINT PK_EXPORT_FEED_DATAVIEW PRIMARY KEY (CSRIMP_SESSION_ID, EXPORT_FEED_SID, DATAVIEW_SID);
alter table csrimp.DELEGATION_DATE_SCHEDULE add CONSTRAINT PK_DELEGATION_DATE_SCHEDULE PRIMARY KEY (CSRIMP_SESSION_ID, DELEGATION_DATE_SCHEDULE_ID);
alter table csrimp.SHEET_DATE_SCHEDULE add CONSTRAINT PK_SHEET_DATE_SCHEDULE PRIMARY KEY (CSRIMP_SESSION_ID, DELEGATION_DATE_SCHEDULE_ID, START_DTM);

-- although not normally a good plan this only affects csrimp, not the website
BEGIN
	FOR r IN (
		SELECT object_owner, object_name, policy_name 
		  FROM all_policies 
		 WHERE pf_owner = 'CSRIMP' AND function IN ('SESSIONIDCHECK')
		   AND object_owner IN ('CSRIMP', 'CMS')
	) LOOP
		dbms_rls.drop_policy(
            object_schema   => r.object_owner,
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/
alter table csrimp.delegation add submission_offset number(10) not null;
alter table csr.period_interval modify single_interval_no_year_label not null;

alter table csr.aggregate_ind_calc_job drop constraint CK_AGG_CALC_JOB_DATES;
alter table csr.aggregate_ind_calc_job add constraint CK_AGG_CALC_JOB_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'DD')=END_DTM AND TRUNC(START_DTM,'DD')=START_DTM);

alter table csr.calc_job drop constraint CK_CALC_JOB_DATES;
alter table csr.calc_job add constraint CK_CALC_JOB_DATES CHECK(END_DTM > START_DTM AND TRUNC(END_DTM,'DD')=END_DTM AND TRUNC(START_DTM,'DD')=START_DTM);

update csr.period_interval set label='Monthly' where period_interval_id=1 and period_set_id=1;
update csr.period_interval set label='Quarterly' where period_interval_id=2 and period_set_id=1;
update csr.period_interval set label='Half-yearly' where period_interval_id=3 and period_set_id=1;
update csr.period_interval set label='Annually' where period_interval_id=4 and period_set_id=1;
update csr.period_interval_member set start_period_id = 10 where period_set_id=1 and period_interval_id=2 and start_period_id=9;


declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='TEMP_PERIOD_DTMS';
	if v_exists = 0 then
		execute immediate '
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_PERIOD_DTMS
(
	PERIOD_ID						NUMBER(10)	NOT NULL,
	YEAR							NUMBER(10)	NOT NULL,
	START_DTM						DATE		NOT NULL,
	END_DTM							DATE		NOT NULL
) ON COMMIT DELETE ROWS
';
	end if;
end;
/

ALTER TABLE CSR.METER_SOURCE_TYPE ADD (
	PERIOD_SET_ID			NUMBER(10),
	PERIOD_INTERVAL_ID		NUMBER(10)
);

BEGIN
	UPDATE csr.meter_source_type
	   SET period_set_id = 1,
	       period_interval_id = 1
	;
END;
/

ALTER TABLE CSR.METER_SOURCE_TYPE MODIFY (
	PERIOD_SET_ID			NUMBER(10)	NOT NULL,
	PERIOD_INTERVAL_ID		NUMBER(10)	NOT NULL
);

ALTER TABLE CSR.METER_SOURCE_TYPE ADD CONSTRAINT FK_PERIOD_SET_MTR_SRC_TYPE
	FOREIGN KEY	(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID)
	REFERENCES CSR.PERIOD_INTERVAL(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);
	
CREATE INDEX CSR.IX_PERIOD_SET_MTR_SRC_TYPE ON CSR.METER_SOURCE_TYPE (APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID);

begin
	for r in (
		select 1 from all_objects where owner='CSR' and object_name='FB8111_LOG' and object_type='PROCEDURE'
	) loop
		execute immediate 'drop procedure CSR.FB8111_LOG';
	end loop;
end;
/

alter table csr.batch_job_meter_extract add 
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

update csr.batch_job_meter_extract set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.batch_job_meter_extract modify period_set_id not null;
alter table csr.batch_job_meter_extract modify period_interval_id not null;
alter table csr.batch_job_meter_extract add constraint fk_bat_job_metr_xtrct_prd_int foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.batch_job_meter_extract drop column interval;

alter table csr.snapshot add 
(
	period_set_id 			number(10),
	period_interval_id		number(10)
);

update csr.snapshot set period_set_id = 1, period_interval_id = decode(interval,'y',4,'h',3,'q',2,'m',1,-1);
alter table csr.snapshot modify period_set_id not null;
alter table csr.snapshot modify period_interval_id not null;
alter table csr.snapshot add constraint fk_snapshot_period_interval foreign key (app_sid, period_set_id, period_interval_id)
references csr.period_interval (app_sid, period_set_id, period_interval_id);
alter table csr.snapshot drop column interval;

-- Previously known as v$delegation, refactored to avoid inappropriate use.
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
@../period_pkg
@../period_body
	
@update_tail

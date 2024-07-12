define version=3013
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE csr.meter_import_revert_batch_job(
	app_sid         	NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	batch_job_id    	NUMBER(10, 0)    NOT NULL,
	meter_raw_data_id   NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_IMPORT_REVERT_BATCH_JOB PRIMARY KEY (app_sid, batch_job_id, meter_raw_data_id)
);
CREATE TABLE csr.prop_type_prop_tab (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	property_type_id	NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	CONSTRAINT PK_PROP_TYPE_PROP_TAB PRIMARY KEY (app_sid, property_Type_id, plugin_id),
	CONSTRAINT FK_PROP_TYPE_PROP_TAB FOREIGN KEY (app_sid, property_type_id) REFERENCES csr.property_type(app_sid, property_type_id),
	CONSTRAINT FK_PLUGIN_PROP_TAB FOREIGN KEY (plugin_id) REFERENCES csr.plugin(plugin_id)
);
CREATE TABLE csrimp.prop_type_prop_tab (
	csrimp_session_id	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	property_type_id	NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	CONSTRAINT PK_PROP_TYPE_PROP_TAB PRIMARY KEY (csrimp_session_id, property_Type_id, plugin_id),
	CONSTRAINT FK_PROP_TYPE_PROP_TAB_IS FOREIGN KEY (csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id) ON DELETE CASCADE
);


ALTER TABLE CHAIN.HIGG_QUESTION_OPT_CONVERSION
MODIFY MEASURE_CONVERSION_ID NULL;
ALTER TABLE csr.meter_import_revert_batch_job ADD CONSTRAINT FK_BJ_MIRBJ
	FOREIGN KEY (app_sid, batch_job_id)
	REFERENCES csr.batch_job(app_sid, batch_job_id)
;
ALTER TABLE csr.meter_import_revert_batch_job ADD CONSTRAINT FK_MRD_MIRBJ
	FOREIGN KEY (app_sid, meter_raw_data_id)
	REFERENCES csr.meter_raw_data(app_sid, meter_raw_data_id)
;
CREATE INDEX csr.IX_BJ_MIRBJ ON csr.meter_import_revert_batch_job (app_sid, batch_job_id);
CREATE INDEX csr.IX_MRD_MIRBJ ON csr.meter_import_revert_batch_job (app_sid, meter_raw_data_id);
ALTER TABLE CSR.TEMPOR_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSR.QUICK_SURVEY_TYPE ADD (
	OTHER_TEXT_REQ_FOR_SCORE NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_QST_OTH_TXT_REQ_FOR_SCORE CHECK (OTHER_TEXT_REQ_FOR_SCORE IN (0,1))
);
CREATE INDEX CSR.IX_QS_QUESTION_ACTION ON CSR.QUICK_SURVEY_QUESTION (APP_SID, ACTION);
CREATE INDEX CSR.IX_QS_Q_OPT_ACTION ON CSR.QS_QUESTION_OPTION (APP_SID, OPTION_ACTION);
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD ACTION VARCHAR2(50);
ALTER TABLE CSRIMP.QUICK_SURVEY_TYPE ADD OTHER_TEXT_REQ_FOR_SCORE NUMBER(1);
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_log MODIFY message NULL';
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
ALTER TABLE csrimp.issue_log MODIFY message NULL;
create index csr.ix_prop_type_pro_plugin_id on csr.prop_type_prop_tab (plugin_id);
ALTER TABLE CSR.METER_LIVE_DATA ADD (
	METER_DATA_ID		NUMBER(10)
);
CREATE UNIQUE INDEX CSR.IX_METER_LIVE_DATA_ID ON CSR.METER_LIVE_DATA(DECODE(METER_DATA_ID, NULL, NULL, APP_SID), METER_DATA_ID);
ALTER TABLE CSRIMP.METER_LIVE_DATA ADD (
	METER_DATA_ID		NUMBER(10)
);
declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB' and column_name='FAILED';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batch_job ADD failed NUMBER(1) DEFAULT 0 NOT NULL';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCH_JOB' and constraint_name='CK_BATCH_JOB_FAILED';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batch_job ADD CONSTRAINT ck_batch_job_failed CHECK (failed IN (0, 1))';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type ADD batch_job_type_id NUMBER(10)';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type ADD batch_job_type_id NUMBER(10)';
	end if;
end;
/
alter table csr.issue_scheduled_task add raised_by_user_sid number(10);
update csr.issue_scheduled_task set raised_by_user_sid = 3;
alter table csr.issue_scheduled_task modify raised_by_user_sid not null;
create index csr.ix_iss_sched_task_raised_user on csr.issue_scheduled_task (app_sid, raised_by_user_sid);
alter table csr.issue_scheduled_task add constraint fk_iss_sched_task_raised_user
foreign key (app_sid, raised_by_user_sid) references csr.csr_user (app_sid, csr_user_sid);
alter table csrimp.issue_scheduled_task add raised_by_user_sid number(10);
update csrimp.issue_scheduled_task set raised_by_user_sid = 3;
alter table csrimp.issue_scheduled_task modify raised_by_user_sid not null;
create table csr.issue_raise_alert (
	app_sid							number(10) default sys_context('SECURITY', 'APP') not null,
	issue_id						number(10) not null,
	raised_by_user_sid				number(10) not null,
	issue_comment					varchar2(4000),
	constraint pk_issue_raise_alert primary key (app_sid, issue_id)
);
alter table csr.issue_raise_alert add constraint fk_issue_raise_alert_issue
foreign key (app_sid, issue_id) references csr.issue (app_sid, issue_id);
alter table csr.issue_raise_alert add constraint fk_issue_raise_alert_raise_by
foreign key (app_sid, raised_by_user_sid) references csr.csr_user (app_sid, csr_user_sid);
create index csr.issue_raise_alert_raised_by on csr.issue_raise_alert (app_sid, raised_by_user_sid);
alter table csr.dataview_zone rename column dataview_zone_id to pos;
alter table csr.dataview_zone drop primary key drop index;
alter table csr.dataview_zone add constraint pk_dataview_zone primary key (app_sid, dataview_sid, pos);
drop sequence csr.dataview_zone_id_seq;
alter table csrimp.dataview_zone rename column dataview_zone_id to pos;
alter table csrimp.dataview_zone drop primary key drop index;
alter table csrimp.dataview_zone add constraint pk_dataview_zone primary key (csrimp_session_id, dataview_sid, pos);
drop table csrimp.map_dataview_zone;
alter table csr.dataview_trend rename column dataview_trend_id to pos;
alter table csr.dataview_trend drop primary key drop index;
alter table csr.dataview_trend add constraint pk_dataview_trend primary key (app_sid, dataview_sid, pos);
drop sequence csr.dataview_trend_id_seq;
alter table csrimp.dataview_trend rename column dataview_trend_id to pos;
alter table csrimp.dataview_trend drop primary key drop index;
alter table csrimp.dataview_trend add constraint pk_dataview_trend primary key (csrimp_session_id, dataview_sid, pos);
alter table csr.dataview drop column use_pending;
alter table csrimp.dataview drop column use_pending;
alter table csr.dataview_history drop column use_pending;
alter table csrimp.dataview_history drop column use_pending;


GRANT SELECT, INSERT, UPDATE ON csr.prop_type_prop_tab to CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.PROP_TYPE_PROP_TAB TO TOOL_USER;




insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
values (csr.plugin_id_seq.nextval, 13, 'Actions', '/csr/site/audit/controls/ActionsTab.js', 'Audit.Controls.ActionsTab', 'Credit360.Audit.Plugins.ActionsTab', 'This tab shows a list of actions from findings against an audit', '', '');
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
			fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
			fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
			COALESCE(
				fv.description,
				CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' END,
				r.description,
				cu.full_name,
				cr.name,
				fv.str_value
			) description,
			ff.group_by_index,
			f.compound_filter_id, ff.show_all, ff.period_set_id, ff.period_interval_id, fv.start_period_id, 
			fv.filter_type, fv.null_filter, fv.colour, ff.comparator
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;
CREATE OR REPLACE VIEW CHAIN.v$filter_field AS
	SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, ff.show_all, ff.group_by_index,
		   f.compound_filter_id, ff.top_n, ff.bottom_n, ff.column_sid, ff.period_set_id,
		   ff.period_interval_id, ff.show_other, ff.comparator
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id;
CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm, bj.failed
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;
CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,                  -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title, csru.user_ref,  -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,	cu.default_company_sid, 	              -- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected
	   AND cu.registration_status_id <> 3 -- not merged
	   AND cu.deleted = 0;
CREATE OR REPLACE VIEW chain.v$company_user AS
	SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name,
		   vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,
		   vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		   vcu.account_enabled, vcu.user_ref, vcu.default_company_sid
	  FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
	 WHERE cug.app_sid = vcu.app_sid
	   AND cug.user_group_sid = gm.group_sid_id
	   AND vcu.user_sid = gm.member_sid_id;
create or replace view csr.v$scrag_usage as
select c.app_sid, c.host, case when msr.scenario_run_sid is null then 'val' when ms.file_based = 1 then 'scrag++' else 'scenario_run_val' end merged,
	   case when usr.scenario_run_sid is null then 'on the fly' when us.file_based = 1 then 'scrag++' else 'scenario_run_val' end unmerged,
	   nvl(spp_scenarios, 0) other_spp_scenarios, nvl(scenarios, 0) - nvl(spp_scenarios, 0) other_old_scenarios
  from csr.customer c
  left join csr.scenario_run msr on c.app_sid = msr.app_sid and c.merged_scenario_run_sid = msr.scenario_run_sid
  left join csr.scenario ms on ms.app_sid = msr.app_sid and ms.scenario_sid = msr.scenario_sid
  left join csr.scenario_run usr on c.app_sid = usr.app_sid and c.unmerged_scenario_run_sid = usr.scenario_run_sid
  left join csr.scenario us on us.app_sid = usr.app_sid and us.scenario_sid = usr.scenario_sid
  left join (select s.app_sid, sum(s.file_based) spp_scenarios, count(*) scenarios
			   from csr.scenario s
			  where (s.app_sid, s.scenario_sid) not in (
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.merged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid
					 union all
					select s.app_sid, s.scenario_sid
					  from csr.customer c
					  join csr.scenario_run sr on c.app_sid = sr.app_sid and c.unmerged_scenario_run_sid = sr.scenario_run_sid
					  join csr.scenario s on sr.app_sid = s.app_sid and sr.scenario_sid = s.scenario_sid)
			  group by s.app_sid) o on c.app_sid = o.app_sid;




INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28220, 3, 'yards', 0.9144, 1, 0, 1);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8313,1137,6,'yards',5);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8314,1137,6,'metres',6);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8315,1139,6,'yards',5);
INSERT INTO CHAIN.HIGG_QUESTION_OPTION ( HIGG_QUESTION_option_id,HIGG_QUESTION_id,higg_module_id,option_value,display_order) VALUES ( 8316,1139,6,'metres',6);
BEGIN
	UPDATE chain.higg_question
	   SET indicator_name = NULL,
		   indicator_lookup = NULL,
		   measure_name = NULL,
		   measure_lookup = NULL,
		   measure_divisibility = NULL,
		   std_measure_conversion_id = NULL
	 WHERE higg_question_id IN (1136, 1138);
	UPDATE chain.higg_question
	   SET units_question_id = 1137
	 WHERE higg_question_id = 1136;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = NULL,
		   std_measure_conversion_id = NULL
	 WHERE higg_question_id IN (1137,1139);
	DELETE
	  FROM chain.higg_question_survey
	 WHERE higg_question_id IN (1136, 1138);
END;
/
BEGIN
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing)
		 VALUES (8, 'Reverting', 0);
	INSERT INTO csr.meter_raw_data_status (status_id, description, needs_processing)
		 VALUES (9, 'Reverted', 0);
END;
/
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, one_at_a_time)
		 VALUES (53, 'Raw meter data import revert', 'csr.meter_monitor_pkg.ProcessRawDataImportRevert', 0);
END;
/
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_app_sid			security.security_pkg.T_SID_ID;
	v_setup_menu_sid	security.security_pkg.T_SID_ID;
	v_init_admin		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin(NULL);
	
	FOR r IN (
		SELECT c.app_sid, c.host, so.sid_id
		  FROM security.menu m 
		  JOIN security.securable_object so ON m.sid_id = so.sid_id 
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE LOWER(m.action) = '/csr/site/initiatives/admin/menu.acds'
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		v_app_sid := security.security_pkg.GetApp;
		
		v_setup_menu_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu/setup');
		
		UPDATE security.securable_object
		   SET parent_sid_id = v_setup_menu_sid
		 WHERE sid_id = r.sid_id;
	END LOOP;
	
	security.user_pkg.LogonAdmin(NULL);
END;
/
DECLARE
	v_count			number(10);
	
BEGIN
	SELECT count(*) 
	  INTO v_count
	  FROM all_tables 
	 WHERE owner = 'CSR'
	   AND table_name = 'TT_QS_CHECKBOX_ACTION';
	
	IF v_count = 0 THEN
		-- Ideally this would be a temporary table, but because of some long running queries we want
		-- to insert the bulk of the data into it before the release. Will need a separate story
		-- to get rid of this once the data has been verified.
		EXECUTE IMMEDIATE '
			CREATE TABLE csr.tt_qs_checkbox_action (
				APP_SID							NUMBER(10) NOT NULL,
				SURVEY_SID						NUMBER(10) NOT NULL,
				SURVEY_VERSION					NUMBER(10) NOT NULL,
				QUESTION_ID						NUMBER(10) NOT NULL,
				ACTION							VARCHAR2(255) NULL,
				CONSTRAINT PK_TT_QS_CHKBOX_ACTION PRIMARY KEY (APP_SID, SURVEY_SID, SURVEY_VERSION, QUESTION_ID)
			)';
	END IF;
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	DELETE
	  FROM csr.tt_qs_checkbox_action
	 WHERE survey_version = 0;
	
	-- On Wembley this took about 4 minutes but only updates drafts. We will need to update
	-- old versions in a separate script (these cannot be edited so won't change between that
	-- script and the release) and then update any versions created between this script and
	-- the release.
	INSERT INTO csr.tt_qs_checkbox_action (app_sid, survey_sid, survey_version, question_id, action)
	SELECT qsv.app_sid, qsv.survey_sid, qsv.survey_version, t.question_id, t.action
	  FROM csr.quick_survey_version qsv, 
		XMLTABLE('//checkbox[@action]' PASSING XMLTYPE(qsv.question_xml) 
			COLUMNS question_id number(10) path '@id', 
					action varchar2(255) path '@action'
		) t
	 WHERE qsv.survey_version = 0
	   AND qsv.survey_sid NOT IN (SELECT trash_sid FROM csr.trash)
	   AND t.question_id IS NOT NULL;
	
	UPDATE csr.quick_survey_question qsq
	   SET qsq.action = (
			SELECT action
			  FROM csr.tt_qs_checkbox_action t
			 WHERE t.question_id = qsq.question_id 
			   AND t.app_sid = qsq.app_sid
			   AND t.survey_version = qsq.survey_version
			   AND t.survey_sid = qsq.survey_sid
		)
	  WHERE EXISTS (
		SELECT 1
		  FROM csr.tt_qs_checkbox_action t
		 WHERE t.question_id = qsq.question_id 
		   AND t.app_sid = qsq.app_sid
		   AND t.survey_version = qsq.survey_version
		   AND t.survey_sid = qsq.survey_sid
	  );
	
	-- There's no constraint requiring all checkboxes to have a value for 'action'
	-- and the code should handle action being null, but if you create a survey in the
	-- system it will always pass something for action for checkboxes, so might as
	-- well start with consistent data.
	UPDATE csr.quick_survey_question
	   SET action = 'none'
	 WHERE action IS NULL AND question_type = 'checkbox';
	
	
	UPDATE csr.quick_survey_type
	   SET other_text_req_for_score = 1
	 WHERE quick_survey_type_id IN (
		SELECT qs.quick_survey_type_id
		  FROM chain.higg_config hc
		  JOIN csr.quick_survey qs ON qs.survey_sid = hc.survey_sid
	 );
END;
/
UPDATE csr.module
   SET warning_msg = 'This enables parts of the supply chain system and cannot be undone.<br/><br/><span style="font-weight:bold">DANGER!</span><br/>Re-running this script will reinstate default property permissions and menus.<br/>It may remove some non-standard property menus.'
 WHERE Enable_Sp = 'EnableProperties';
BEGIN
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (30, 'Full user export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (31, 'Filtered user export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (32, 'Region list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (33, 'Indicator list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (34, 'Data export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (35, 'Region role membership export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (36, 'Region and meter export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (37, 'Measure list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (38, 'Emission profile export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (39, 'Factor set export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (40, 'Indicator translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (41, 'Region translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (42, 'CMS quick chart exporter', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (43, 'CMS exporter', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (44, 'Forecasting Slot export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (45, 'Delegation translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (46, 'Filter list export', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/
declare
	v_exists number;
begin	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name='BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'begin
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 30
	 WHERE batch_export_type_id = 0;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 31
	 WHERE batch_export_type_id = 1;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 32
	 WHERE batch_export_type_id = 2;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 33
	 WHERE batch_export_type_id = 3;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 34
	 WHERE batch_export_type_id = 4;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 35
	 WHERE batch_export_type_id = 5;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 36
	 WHERE batch_export_type_id = 6;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 37
	 WHERE batch_export_type_id = 7;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 38
	 WHERE batch_export_type_id = 8;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 39
	 WHERE batch_export_type_id = 9;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 40
	 WHERE batch_export_type_id = 11;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 41
	 WHERE batch_export_type_id = 12;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 42
	 WHERE batch_export_type_id = 13;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 43
	 WHERE batch_export_type_id = 14;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 44
	 WHERE batch_export_type_id = 15;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 45
	 WHERE batch_export_type_id = 16;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 46
	 WHERE batch_export_type_id = 10;
	 
	UPDATE csr.batch_job bj
	   SET bj.batch_job_type_id = ( 
			SELECT bet.batch_job_type_id 
			  FROM csr.batched_export_type bet
			 WHERE LOWER(bj.description) = LOWER(bet.label)
		  )
	 WHERE batch_job_type_id = 27;
	 end;';
	end if;
	DELETE FROM csr.batch_job_type WHERE batch_job_type_id = 27;
END;
/
declare
	v_exists	number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB_BATCHED_EXPORT' and column_name = 'BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batch_job_batched_export DROP COLUMN batch_export_type_id';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name = 'BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_export_type DROP COLUMN batch_export_type_id';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and constraint_name = 'FK_BTCH_EXP_TYP_BTCH_JB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type ADD CONSTRAINT fk_btch_exp_typ_btch_jb_type 
			FOREIGN KEY (batch_job_type_id) 
			REFERENCES csr.batch_job_type(batch_job_type_id)';
	end if;
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name = 'BATCHED_EXPORT_TYPE' and constraint_name = 'PK_BATCHED_EXP_TYPE_JOB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type	ADD CONSTRAINT pk_batched_exp_type_job_type PRIMARY KEY (batch_job_type_id)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name = 'BATCHED_EXPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID' and nullable = 'Y';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_export_type MODIFY batch_job_type_id NOT NULL';
	end if;
end;
/
BEGIN
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (47, 'Indicator translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (48, 'Region translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (49, 'Delegation translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (50, 'Meter readings import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (51, 'Forecasting Slot import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (52, 'Factor set import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/
declare
	v_exists number;
begin	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name='BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'begin	
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 47
	 WHERE batch_import_type_id = 0;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 48
	 WHERE batch_import_type_id = 1;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 49
	 WHERE batch_import_type_id = 2;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 50
	 WHERE batch_import_type_id = 3;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 51
	 WHERE batch_import_type_id = 4;
	 UPDATE csr.batched_import_type
	   SET batch_job_type_id = 52
	 WHERE batch_import_type_id = 5;
	
	 
	UPDATE csr.batch_job bj
	   SET bj.batch_job_type_id = ( 
			SELECT bet.batch_job_type_id 
			  FROM csr.batched_import_type bet
			 WHERE LOWER(bj.description) = LOWER(bet.label)
		  )
	 WHERE batch_job_type_id = 29;
	end;';
	end if;
	
	DELETE FROM csr.batch_job_type WHERE batch_job_type_id = 29;
END;
/
	
declare
	v_exists	number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB_BATCHED_IMPORT' and column_name = 'BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batch_job_batched_import DROP COLUMN batch_import_type_id';
	end if;
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name = 'BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_import_type DROP COLUMN batch_import_type_id';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and constraint_name = 'FK_BTCH_IMP_TYP_BTCH_JB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type ADD CONSTRAINT fk_btch_imp_typ_btch_jb_type 
			FOREIGN KEY (batch_job_type_id) 
			REFERENCES csr.batch_job_type(batch_job_type_id)';
	end if;
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name = 'BATCHED_IMPORT_TYPE' and constraint_name = 'PK_BATCHED_IMP_TYPE_JOB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type	ADD CONSTRAINT pk_batched_imp_type_job_type PRIMARY KEY (batch_job_type_id)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name = 'BATCHED_IMPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID' and nullable = 'Y';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_import_type MODIFY batch_job_type_id NOT NULL';
	end if;
end;
/
BEGIN
	security.user_pkg.logonadmin();
	
	UPDATE chain.default_message_param 
	   SET href = '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}' 
	 WHERE href = '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}';
	 
	UPDATE chain.default_message_param 
	   SET href = '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}' 
	 WHERE href = '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}';
END;
/
DECLARE 
	-- Clean up dodgy meter data caused by batch servers using BST
	PROCEDURE FixMeterDates(site IN VARCHAR2)
	AS
		issue_meter_raw_data		CONSTANT NUMBER(10) := 8;
	BEGIN
		security.user_pkg.LogonAdmin(site);
		-- Reinterpret as UTC+00
		UPDATE csr.meter_source_data SET 
			start_dtm = CAST(start_dtm AS TIMESTAMP),
			end_dtm = CAST(end_dtm AS TIMESTAMP);
		UPDATE csr.meter_orphan_data SET 
			start_dtm = CAST(start_dtm AS TIMESTAMP),
			end_dtm = CAST(end_dtm AS TIMESTAMP);
		-- Raw meter issues that refer to UTC+01 timestamps are probably bogus overlaps
		UPDATE csr.issue 
		   SET deleted = 1 
		 WHERE issue_id IN (
			SELECT issue_id 
			  FROM csr.v$issue 
		     WHERE source_label = 'Meter raw data'
			   AND issue_type_id = issue_meter_raw_data
			   AND is_resolved = 0 
			   AND is_closed = 0
			   AND is_rejected = 0
			   AND REGEXP_LIKE(label, '^RAW DATA PROCESSOR: Incoming source period overlaps.*\+01:00')
		);
	EXCEPTION 
		WHEN OTHERS THEN NULL;
	END;
BEGIN
	FixMeterDates('adobe.credit360.com');
	FixMeterDates('jmfamily.credit360.com');
	FixMeterDates('yum.credit360.com'); 
	security.user_pkg.LogonAdmin(NULL);
END;
/
BEGIN
	UPDATE security.menu
	   SET action = '/csr/site/users/list/list.acds'
	 WHERE LOWER(action) = '/csr/site/users/userlist.acds';
	
	UPDATE security.securable_object so
	   SET name = 'csr_users_list'
	 WHERE LOWER(name) = 'csr_users'
	   AND EXISTS (
			SELECT NULL
			  FROM security.menu
			 WHERE sid_id = so.sid_id
			   AND LOWER(action) = '/csr/site/users/list/list.acds'
	   );  
END;
/
begin
	-- missing from some sites
	INSERT INTO csr.issue_type (app_sid, issue_type_id, label)
		SELECT app_sid, 20 /*csr_data_pkg.ISSUE_METER*/, 'Meter'
		  FROM (SELECT app_sid
				  FROM csr.customer_region_type
				 WHERE region_type = 1
				 MINUS
				SELECT app_sid
				  FROM csr.issue_type
				 WHERE issue_type_id = 20);
	-- fix up plugins
	update csr.plugin set cs_class='Credit360.Chain.Plugins.IssuesPanel' where js_class='Chain.ManageCompany.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Metering.Plugins.IssuesTab' where js_class='Credit360.Metering.IssuesTab';
	update csr.plugin set cs_class='Credit360.Teamroom.IssuesPanel' where js_class='Teamroom.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Initiatives.IssuesPanel' where js_class='Credit360.Initiatives.IssuesPanel';
	update csr.plugin set cs_class='Credit360.Property.Plugins.IssuesPanel' where js_class='Controls.IssuesPanel';
	commit;
end;
/
UPDATE csr.batch_job_type
   SET one_at_a_time = 1
 WHERE batch_job_type_id = 27;






@..\chain\higg_setup_pkg
@..\chain\higg_pkg
@..\audit_report_pkg
@..\chain\activity_report_pkg
@..\chain\company_filter_pkg
@..\chain\filter_pkg
@..\comp_regulation_report_pkg
@..\comp_requirement_report_pkg
@..\initiative_report_pkg
@..\issue_report_pkg
@..\meter_list_pkg
@..\meter_report_pkg
@..\non_compliance_report_pkg
@..\property_pkg
@..\property_report_pkg
@..\region_report_pkg
@..\supplier_pkg
@..\user_report_pkg
@..\chain\company_pkg
@..\batch_job_pkg
@..\meter_patch_pkg
@..\meter_monitor_pkg
@..\quick_survey_pkg
@@..\property_pkg
@@..\schema_pkg
@..\chain\filter_pkg.sql
@..\batch_exporter_pkg
@..\batch_importer_pkg
@..\chain\company_user_pkg
@..\audit_pkg
@..\teamroom_pkg
@..\issue_pkg
@..\initiative_pkg
@..\meter_pkg
@..\dataview_pkg


@..\chain\higg_setup_body
@..\chain\higg_body
@..\audit_report_body
@..\chain\activity_report_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\comp_regulation_report_body
@..\comp_requirement_report_body
@..\initiative_report_body
@..\issue_report_body
@..\meter_list_body
@..\meter_report_body
@..\non_compliance_report_body
@..\property_body
@..\property_report_body
@..\region_report_body
@..\supplier_body
@..\user_report_body
@..\chain\company_body
@..\meter_monitor_body
@..\initiative_body
@@..\enable_body
@..\meter_body
@..\quick_survey_body
@..\schema_body
@..\testdata_body
@..\csrimp\imp_body
@@..\property_body
@@..\schema_body
@@..\csrimp\imp_body
@..\chain\filter_body.sql
@..\..\..\aspen2\cms\db\filter_body.sql
@..\audit_report_body.sql
@..\chain\activity_report_body.sql
@..\chain\company_filter_body.sql
@..\comp_regulation_report_body.sql
@..\comp_requirement_report_body.sql
@..\initiative_report_body.sql
@..\issue_report_body.sql
@..\meter_list_body.sql
@..\meter_report_body.sql
@..\non_compliance_report_body.sql
@..\property_report_body.sql
@..\region_report_body.sql
@..\user_report_body.sql
@..\delegation_body
@..\batch_job_body
@..\batch_exporter_body
@..\batch_importer_body
@..\issue_body
@..\chain\company_user_body
@..\factor_body
@..\factor_set_group_body
@..\csr_user_body
@..\audit_body
@..\teamroom_body
@..\enhesa_body
@..\tag_body
@..\calc_body
@..\dataview_body
@..\snapshot_body



@update_tail

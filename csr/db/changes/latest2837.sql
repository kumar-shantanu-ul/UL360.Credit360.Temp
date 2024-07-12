define version=2837
define minor_version=0
define is_combined=1
@update_header

alter table csr.scenario add data_source_sp_args varchar2(4000);
update csr.scenario set data_source_sp_args = 'vals,notes,files' where data_source=2;
alter table csr.scenario drop constraint ck_scenario_data_source;
alter table csr.scenario add constraint ck_scenario_data_source check (
	(data_source in (0, 1) and data_source_sp is null and data_source_sp_args is null) or 
	(data_source = 2 and data_source_sp is not null and data_source_sp_args is not null)
);

alter table csr.aggregate_ind_group add helper_proc_args varchar2(4000) default 'vals' not null;

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION' and temporary='N') loop
		dbms_output.put_line('tab '||r.table_name);
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

alter table csrimp.scenario add data_source_sp_args varchar2(4000);
alter table csrimp.aggregate_ind_group add helper_proc_args varchar2(4000) not null;

CREATE SEQUENCE CHAIN.FILTER_PAGE_CMS_TABLE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE chain.filter_page_cms_table (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	filter_page_cms_table_id		NUMBER(10) NOT NULL,
	card_group_id					NUMBER(10) NOT NULL,
	column_sid						NUMBER(10) NOT NULL,
	CONSTRAINT pk_filter_page_cms_table PRIMARY KEY (app_sid, filter_page_cms_table_id),
	CONSTRAINT fk_filter_page_cms_table_col FOREIGN KEY (app_sid, column_sid) REFERENCES cms.tab_column (app_sid, column_sid)
);
CREATE INDEX chain.ix_filter_page_cms_table_col ON chain.filter_page_cms_table(app_sid, column_sid);
create table cms.oracle_tab
(
	oracle_schema	varchar2(30) not null,
	oracle_table	varchar2(30) not null,
	constraint pk_oracle_tab primary key (oracle_schema, oracle_table)
);
insert into cms.oracle_tab (oracle_schema, oracle_table)
	select distinct oracle_schema, oracle_table
	  from cms.tab;
alter table cms.tab add constraint fk_tab_oracle_tab foreign key 
(oracle_schema, oracle_table) references cms.oracle_tab (oracle_schema, oracle_table);

ALTER TABLE CSR.PLUGIN ADD (
	USE_REPORTING_PERIOD    	NUMBER(10) DEFAULT 0
);
	
ALTER TABLE CSRIMP.PLUGIN ADD (	
	USE_REPORTING_PERIOD    	NUMBER(10) DEFAULT 0
);
CREATE INDEX chain.ix_cap_flow_cap_capability ON chain.capability_flow_capability (capability_id);
CREATE INDEX chain.ix_cap_flow_cap_flow_cap ON chain.capability_flow_capability (app_sid, flow_capability_id);
DECLARE
	v_wrong_default		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_wrong_default
	  FROM all_tab_columns 
	 WHERE owner = 'CMS' 
	   AND table_name = 'TAB_COLUMN' 
	   AND column_name = 'SHOW_IN_BREAKDOWN' 
	   AND data_default IS NULL;
	   
	IF v_wrong_default = 1 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE cms.tab_column MODIFY show_in_breakdown DEFAULT 1';
	END IF;
END;
/

GRANT SELECT, DELETE ON chain.filter_page_cms_table TO cms;
grant select, insert on cms.oracle_tab to csrimp;


CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id
	  LEFT JOIN csr.quick_survey_type qst on qst.quick_survey_type_id = qs.quick_survey_type_id
	 WHERE d.survey_version = 0;
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset, 
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id, 
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, NVL(dd.description, d.name) as description, dp.submit_confirmation_text,
		   d.lvl
	  FROM (
		SELECT app_sid, delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml, note, group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset, 
			   is_note_mandatory, section_xml, editing_url, fully_delegated, grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period, delegation_date_schedule_id, layout_id, 
			   tag_visibility_matrix_group_id, period_set_id, period_interval_id, submission_offset, allow_multi_period, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid, LEVEL lvl
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;
CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version
	  FROM quick_survey_response qsr 
	  JOIN quick_survey_submission qss ON qsr.app_sid = qss.app_sid
	   AND qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;

ALTER TABLE csr.customer ADD data_explorer_period_extension NUMBER(2) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.customer ADD data_explorer_period_extension NUMBER(2) NOT NULL;

UPDATE csr.plugin
   SET use_reporting_period = 1
 WHERE js_class = 'Controls.CmsTab';
DECLARE
	v_company_capability_id		NUMBER(10, 0);
	v_suppliers_capability_id	NUMBER(10, 0);
BEGIN
	SELECT capability_id
	  INTO v_company_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	 
	SELECT capability_id
	  INTO v_suppliers_capability_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';
	FOR r IN (
		SELECT c.app_sid, c.host, fc.*
		  FROM csr.customer c
		  JOIN csr.flow_capability fc ON fc.flow_capability_id = 1001
		 WHERE EXISTS (
			SELECT *
			  FROM chain.implementation
			 WHERE app_sid = c.app_sid
		 )
	) LOOP
		security.user_pkg.logonadmin(r.host);
		
		DECLARE
			v_flow_capability_id	NUMBER(10, 0) := csr.customer_flow_cap_id_seq.NEXTVAL;
		BEGIN
			INSERT INTO csr.customer_flow_capability (app_sid, flow_capability_id, flow_alert_class, description, perm_type, default_permission_set, lookup_key)
			VALUES (r.app_sid, v_flow_capability_id, r.flow_alert_class, 'Chain: Company / Supplier', r.perm_type, r.default_permission_set, NULL);
			BEGIN
				INSERT INTO chain.capability_flow_capability (app_sid, flow_capability_id, capability_id)
				VALUES (r.app_sid, v_flow_capability_id, v_company_capability_id);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
		
			BEGIN
				INSERT INTO chain.capability_flow_capability (app_sid, flow_capability_id, capability_id)
				VALUES (r.app_sid, v_flow_capability_id, v_suppliers_capability_id);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
			FOR rr IN (
				SELECT *
				  FROM csr.flow_state_role_capability
				 WHERE app_sid = r.app_sid
				   AND flow_capability_id = r.flow_capability_id
			) LOOP
				INSERT INTO csr.flow_state_role_capability (app_sid, flow_state_rl_cap_id, flow_state_id, flow_capability_id, role_sid, flow_involvement_type_id, permission_set, group_sid)
				VALUES (rr.app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, rr.flow_state_id, v_flow_capability_id, rr.role_sid, rr.flow_involvement_type_id, rr.permission_set, rr.group_sid);
			END LOOP;
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
		
		DELETE FROM csr.flow_state_role_capability WHERE app_sid = r.app_sid AND flow_capability_id = r.flow_capability_id;
	END LOOP;
	
	security.user_pkg.logonadmin();
	DELETE FROM csr.flow_capability WHERE flow_capability_id = 1001;
	COMMIT;
END;
/
INSERT INTO CSR.MODULE(module_id, module_name, enable_sp, description, license_warning)
VALUES (56, 'Company Self Registration', 'EnableCompanySelfReg', 'Enables chain company self registration. Chain must already be enabled.', 0);
update csr.customer 
   set legacy_period_formatting = 0 
 where app_sid = 29144945;
update csr.period 
   set start_dtm = add_months(start_dtm, 12), 
	   end_dtm = add_months(end_dtm, 12)
 where period_set_id = 1 
   and period_id < 7
   and app_sid = 29144945;


@..\plugin_pkg
@..\chain\filter_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\csr_data_pkg
@..\chain\setup_pkg
@..\enable_pkg
@..\aggregate_ind_pkg
@..\approval_dashboard_pkg
@..\deleg_plan_pkg
@..\schema_pkg
@..\stored_calc_datasource_pkg

@..\schema_body
@..\csrimp\imp_body
@..\plugin_body
@..\property_body
@..\customer_body
@..\chain\filter_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body
@..\audit_body
@..\audit_report_body
@..\quick_survey_body
@..\sheet_body
@..\chain\company_filter_body
@..\issue_report_body
@..\chain\company_body
@..\chain\type_capability_body
@..\flow_body
@..\campaign_body
@..\chain\setup_body
@..\enable_body
@..\aggregate_ind_body
@..\approval_dashboard_body
@..\csr_app_body
@..\scenario_body
@..\stored_calc_datasource_body
@..\section_root_body
@..\meter_body
@..\meter_monitor_body
@..\meter_patch_body
@..\period_body
@..\deleg_plan_body
@..\delegation_body


@update_tail

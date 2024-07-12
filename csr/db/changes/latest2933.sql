define version=2933
define minor_version=0
define is_combined=1
@update_header

@latestUS3366_packages

-- clean out junk in csrimp
begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
	commit;
end;
/

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_DATA_ID_REGION (
	METER_DATA_ID					NUMBER(10)		NOT NULL,
	REGION_SID						NUMBER(10)		NOT NULL
) ON COMMIT DELETE ROWS;
CREATE TABLE csr.mgt_company_tree_sync_job (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	tree_root_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_mgt_company_tree_sync_job PRIMARY KEY (app_sid, tree_root_sid),
	CONSTRAINT fk_mctsj_region FOREIGN KEY (app_sid, tree_root_sid) REFERENCES csr.region (app_sid, region_sid)
);
CREATE TABLE csrimp.mgt_company_tree_sync_job (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tree_root_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_mgt_company_tree_sync_job PRIMARY KEY (csrimp_session_id, tree_root_sid),
	CONSTRAINT fk_mctsj_session FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
DROP TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE;
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_ROW AS 
	 OBJECT ( 
		CARD_GROUP_ID				NUMBER(10),
		AGGREGATE_TYPE_ID			NUMBER(10),	
		DESCRIPTION 				VARCHAR2(1023),
		FORMAT_MASK					VARCHAR2(255),
		FILTER_PAGE_IND_INTERVAL_ID	NUMBER(10),
		ACCUMULATIVE				NUMBER(1),
		AGGREGATE_GROUP				VARCHAR2(255),
		UNIT_OF_MEASURE				VARCHAR2(255)
	 ); 
/
CREATE OR REPLACE TYPE CHAIN.T_FILTER_AGG_TYPE_TABLE AS 
	TABLE OF CHAIN.T_FILTER_AGG_TYPE_ROW;
/
CREATE TABLE csr.dataview_arbitrary_period (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_AP	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);
CREATE TABLE csr.dataview_arbitrary_period_hist (
	APP_SID				NUMBER(10)			DEFAULT sys_context('security','app') NOT NULL,
	DATAVIEW_SID		NUMBER(10)			NOT NULL,
	VERSION_NUM         NUMBER(10)			NOT NULL,
	START_DTM			DATE				NOT NULL,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_HIST_ARB_PERIOD PRIMARY KEY (APP_SID, DATAVIEW_SID, VERSION_NUM, START_DTM),
	CONSTRAINT FK_DATAVIEW_FROM_DATAVIEW_APH	FOREIGN KEY (APP_SID, DATAVIEW_SID) REFERENCES csr.dataview (APP_SID, DATAVIEW_SID)
);
CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.DATAVIEW_ARBITRARY_PERIOD_HIST (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DATAVIEW_SID		NUMBER(10),
	VERSION_NUM         NUMBER(10),
	START_DTM			DATE,
	END_DTM				DATE,
	CONSTRAINT PK_DATAVIEW_ARB_PERIOD_HIST PRIMARY KEY (CSRIMP_SESSION_ID, DATAVIEW_SID, VERSION_NUM, START_DTM),
    CONSTRAINT FK_DATAVIEW_ARB_PERIOD_HIST_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
--Failed to locate all sections of latest2920_8.sql
CREATE TABLE csr.meter_tab (
	app_sid			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	plugin_id		NUMBER(10, 0) NOT NULL,
	plugin_type_id	NUMBER(10, 0) NOT NULL,
	pos				NUMBER(10, 0) NOT NULL,
	tab_label		VARCHAR2(50),
	CONSTRAINT pk_meter_tab PRIMARY KEY (app_sid, plugin_id),
	CONSTRAINT chk_meter_tab_plugin_type CHECK (plugin_type_id = 16),
	CONSTRAINT fk_meter_tab_plugin FOREIGN KEY (plugin_id, plugin_type_id) 
		REFERENCES csr.plugin(plugin_id, plugin_type_id),
	CONSTRAINT fk_meter_tab_customer FOREIGN KEY (app_sid) 
		REFERENCES csr.customer (app_sid)
);
CREATE TABLE csr.meter_tab_group (
	app_sid						NUMBER (10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	plugin_id					NUMBER (10) NOT NULL,
	group_sid					NUMBER (10),
	role_sid					NUMBER (10),
	CONSTRAINT pk_meter_tab_group PRIMARY KEY (app_sid, plugin_id, group_sid),
	CONSTRAINT chk_meter_tab_group_grp_role CHECK ((group_sid IS NULL AND role_sid IS NOT NULL) OR (group_sid IS NOT NULL AND role_sid IS NULL)),
	CONSTRAINT fk_meter_tab_group_meter_tab FOREIGN KEY (app_sid, plugin_id) 
		REFERENCES csr.meter_tab (app_sid, plugin_id),
	CONSTRAINT fk_meter_tab_group_role FOREIGN KEY (app_sid, role_sid) 
		REFERENCES csr.role (app_sid, role_sid)
);
CREATE TABLE csrimp.meter_tab (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	plugin_id						NUMBER(10) NOT NULL,
	plugin_type_id					NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	tab_label						VARCHAR2(50),
	CONSTRAINT pk_meter_tab PRIMARY KEY (csrimp_session_id, plugin_id),
	CONSTRAINT chk_meter_tab_plugin_type CHECK (plugin_type_id = 16),
    CONSTRAINT fk_meter_tab_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.meter_tab_group (	
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	plugin_id						NUMBER (10) NOT NULL,
	group_sid						NUMBER (10),
	role_sid						NUMBER (10),
	CONSTRAINT pk_meter_tab_group PRIMARY KEY (csrimp_session_id, plugin_id, group_sid),
	CONSTRAINT chk_meter_tab_group_grp_role CHECK ((group_sid IS NULL AND role_sid IS NOT NULL) OR (group_sid IS NOT NULL AND role_sid IS NULL)),
    CONSTRAINT fk_meter_tab_group_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE SEQUENCE csr.meter_header_element_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;
CREATE TABLE csr.meter_header_element (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	meter_header_element_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	meter_header_core_element_id	NUMBER(10),
	CONSTRAINT pk_meter_header_element PRIMARY KEY (app_sid, meter_header_element_id),
	CONSTRAINT fk_meter_header_el_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_meter_header_el_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT chk_meter_header_element
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NULL) OR 
				(ind_sid IS NULL AND tag_group_id IS NOT NULL AND meter_header_core_element_id IS NULL) OR
				(ind_sid IS NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NOT NULL))
);
CREATE TABLE csrimp.meter_header_element (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	meter_header_element_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	meter_header_core_element_id	NUMBER(10),
	CONSTRAINT pk_meter_header_element PRIMARY KEY (csrimp_session_id, meter_header_element_id),
	CONSTRAINT chk_meter_header_element
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NULL) OR 
				(ind_sid IS NULL AND tag_group_id IS NOT NULL AND meter_header_core_element_id IS NULL) OR
				(ind_sid IS NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NOT NULL)),
	CONSTRAINT fk_meter_header_element_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_meter_header_element (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_header_element_id		NUMBER(10)	NOT NULL,
	new_meter_header_element_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_meter_header_element primary key (csrimp_session_id, old_meter_header_element_id) USING INDEX,
	CONSTRAINT uk_map_meter_header_element unique (csrimp_session_id, new_meter_header_element_id) USING INDEX,
    CONSTRAINT fk_map_meter_header_element_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE SEQUENCE csr.meter_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;
CREATE TABLE csr.meter_photo (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	meter_photo_id					NUMBER(10, 0) NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	filename						VARCHAR2(256) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	CONSTRAINT pk_meter_photo PRIMARY KEY (app_sid, meter_photo_id),
	CONSTRAINT fk_meter_photo_meter FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.all_meter (app_sid, region_sid)
);
CREATE TABLE csrimp.meter_photo (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	meter_photo_id					NUMBER(10, 0) NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	filename						VARCHAR2(256) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	CONSTRAINT pk_meter_photo PRIMARY KEY (csrimp_session_id, meter_photo_id),
	CONSTRAINT fk_meter_photo_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_meter_photo (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_photo_id		NUMBER(10)	NOT NULL,
	new_meter_photo_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_meter_photo primary key (csrimp_session_id, old_meter_photo_id) USING INDEX,
	CONSTRAINT uk_map_meter_photo unique (csrimp_session_id, new_meter_photo_id) USING INDEX,
    CONSTRAINT fk_map_meter_photo_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
create index csr.ix_meter_tab_plugin_id_plu on csr.meter_tab (plugin_id, plugin_type_id);
create index csr.ix_meter_tab_gro_role_sid on csr.meter_tab_group (app_sid, role_sid);
create index csr.ix_meter_header_ind_sid on csr.meter_header_element (app_sid, ind_sid);
create index csr.ix_meter_header_tag_group_id on csr.meter_header_element (app_sid, tag_group_id); 
create index csr.ix_meter_photo_meter_region on csr.meter_photo (app_sid, region_sid);  
CREATE UNIQUE INDEX csr.uk_meter_header_element ON csr.meter_header_element(app_sid, ind_sid, tag_group_id, meter_header_core_element_id);
  
DECLARE
	PROCEDURE makeNull(in_col IN VARCHAR2)
	AS
	BEGIN
		FOR r IN (SELECT 1 FROM all_tab_columns WHERE owner = 'CSRIMP' AND table_name = 'METRIC_DASHBOARD_IND' AND column_name = in_col AND nullable = 'N') LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE csrimp.metric_dashboard_ind MODIFY '||in_col||' NULL';
		END LOOP;
	END;
	PROCEDURE makeNotNull(in_col IN VARCHAR2)
	AS
	BEGIN
		FOR r IN (SELECT 1 FROM all_tab_columns WHERE owner = 'CSRIMP' AND table_name = 'METRIC_DASHBOARD_IND' AND column_name = in_col AND nullable = 'Y') LOOP
			EXECUTE IMMEDIATE 'ALTER TABLE csrimp.metric_dashboard_ind MODIFY '||in_col||' NOT NULL';
		END LOOP;
	END;
BEGIN
	makeNull('INTEN_VIEW_SCENARIO_RUN_SID');
	makeNotNull('INTEN_VIEW_FLOOR_AREA_IND_SID');
	makeNull('ABSOL_VIEW_SCENARIO_RUN_SID');
END;
/
ALTER TABLE csr.qs_expr_non_compl_action MODIFY assign_to_role_sid NULL;
ALTER TABLE chain.saved_filter ADD (
	dual_axis NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_dual_axis CHECK (dual_axis IN (0, 1))
);
ALTER TABLE csrimp.chain_saved_filter ADD (
	dual_axis NUMBER(1) NULL
);
UPDATE csrimp.chain_saved_filter SET dual_axis = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY(dual_axis NUMBER(1) NOT NULL);
ALTER TABLE CHAIN.FILTER_VALUE DROP CONSTRAINT FK_FLT_VAL_FLD;
ALTER TABLE CHAIN.FILTER_VALUE ADD CONSTRAINT FK_FLT_VAL_FLD 
	FOREIGN KEY (APP_SID, FILTER_FIELD_ID)
	REFERENCES CHAIN.FILTER_FIELD(APP_SID, FILTER_FIELD_ID)
	ON DELETE CASCADE
;
  
ALTER TABLE CSR.ISSUE ADD (
	LAST_REGION_SID		NUMBER(10, 0),
	CONSTRAINT FK_ISSUE_TYPE_LAST_REGION FOREIGN KEY(APP_SID, LAST_REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID)
);
ALTER TABLE CSR.ISSUE_ACTION_LOG ADD (
	OLD_REGION_SID	NUMBER(10, 0),
	NEW_REGION_SID	NUMBER(10, 0)
);
ALTER TABLE CSRIMP.ISSUE_TYPE ADD (
	IS_REGION_EDITABLE	NUMBER(1, 0) NULL,
	CONSTRAINT CHK_REGION_EDITABLE CHECK(IS_REGION_EDITABLE IN (0,1))
);
UPDATE CSRIMP.ISSUE_TYPE SET IS_REGION_EDITABLE = 0 WHERE IS_REGION_EDITABLE IS NULL;
ALTER TABLE CSRIMP.ISSUE_TYPE MODIFY IS_REGION_EDITABLE NOT NULL;
ALTER TABLE CSRIMP.ISSUE ADD (
	LAST_REGION_SID		NUMBER(10, 0)
);
ALTER TABLE CSRIMP.ISSUE_ACTION_LOG ADD (
	OLD_REGION_SID	NUMBER(10, 0),
	NEW_REGION_SID	NUMBER(10, 0)
);
ALTER TABLE CSR.TEMP_METER_PATCH_IMPORT_ROWS
  ADD note VARCHAR2(800);
ALTER TABLE csr.delegation_layout ADD (VALID NUMBER(1) DEFAULT 1 NOT NULL);
ALTER TABLE csrimp.delegation_layout ADD (VALID NUMBER(1) DEFAULT 1 NOT NULL);
ALTER TABLE csr.metering_options ADD (
	meter_page_url					VARCHAR2(255) DEFAULT '/csr/site/meter/meter.acds' NOT NULL
);
ALTER TABLE csrimp.metering_options ADD (
	meter_page_url					VARCHAR2(255)
);
UPDATE csrimp.metering_options SET meter_page_url = '/csr/site/meter/meter.acds';
ALTER TABLE csrimp.metering_options MODIFY meter_page_url NOT NULL;


GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.mgt_company_tree_sync_job TO web_user;
GRANT SELECT, INSERT, UPDATE ON csr.mgt_company_tree_sync_job TO csrimp;
GRANT EXECUTE ON chain.t_filter_agg_type_table TO csr;
GRANT EXECUTE ON chain.t_filter_agg_type_row TO csr;
GRANT EXECUTE ON chain.t_filter_agg_type_table TO cms;
GRANT EXECUTE ON chain.t_filter_agg_type_row TO cms;
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT INSERT,SELECT,UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.dataview_arbitrary_period_hist TO csrimp;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period to web_user;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.dataview_arbitrary_period_hist to web_user;
grant select,insert,update,delete on csrimp.meter_tab to web_user;
grant select,insert,update,delete on csrimp.meter_tab_group to web_user;
grant insert on csr.meter_tab to csrimp;
grant insert on csr.meter_tab_group to csrimp;
grant select,insert,update,delete on csrimp.meter_header_element to web_user;
grant insert on csr.meter_header_element to csrimp;
grant select on csr.meter_header_element_id_seq to csrimp;
grant select,insert,update,delete on csrimp.meter_photo to web_user;
grant insert on csr.meter_photo to csrimp;
grant select on csr.meter_photo_id_seq to csrimp;

CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment,
	   ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = r2.app_sid(+) AND i.owner_role_sid = r2.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

update chain.filter_value dest
   set (num_value, str_value, filter_type) = (
	  select regexp_substr(str_value, '^([0-9]+)_', 1, 1, null, 1), null, 1
		from chain.v$filter_value src
	   where dest.app_sid = src.app_sid
		 and dest.filter_value_id = src.filter_value_id) 
 where regexp_like(str_value, '^([0-9]+)_')
   and exists(
	  select * 
		from chain.filter_field ff
	   where ff.name = 'MeterType'
		 and ff.app_sid = dest.app_sid
		 and ff.filter_field_id = dest.filter_field_id);
update chain.filter_value dest
   set (num_value, str_value, filter_type) = (
	  select str_value, null, 1
		from chain.v$filter_value src
	   where dest.app_sid = src.app_sid
		 and dest.filter_value_id = src.filter_value_id) 
 where regexp_like(str_value, '^([0-9]+)$')
   and exists(
	  select * 
		from chain.filter_field ff
	   where ff.name = 'MeterType'
		 and ff.app_sid = dest.app_sid
		 and ff.filter_field_id = dest.filter_field_id);

BEGIN	
	INSERT INTO csr.plugin_type (plugin_type_id, description) 
		 VALUES (16, 'Meter tab');
END;
/

DELETE FROM csr.branding_availability
 WHERE LOWER(client_folder_name) = 'betfair';
DELETE FROM csr.branding
 WHERE LOWER(client_folder_name) = 'betfair';
DECLARE
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		SELECT plugin_id
		  INTO v_plugin_id
		  FROM csr.plugin
		 WHERE plugin_type_id = 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/
		   AND js_class = 'Credit360.Metering.MeterRawDataTab';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
			VALUES (csr.plugin_id_seq.NEXTVAL, 16 /*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 
				'Raw meter data', '/csr/site/meter/controls/meterRawDataTab.js', 
				'Credit360.Metering.MeterRawDataTab', 'Credit360.Metering.Plugins.MeterRawData', 'Display, filter, search, and export raw readings for the meter.')
			RETURNING plugin_id INTO v_plugin_id;
	END;
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_source_type s
		  JOIN csr.customer c ON c.app_sid = s.app_sid
	) LOOP
		security.user_pkg.logonadmin(a.host);
		BEGIN
			INSERT INTO csr.meter_tab(plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, 16/*csr.csr_data_pkg.PLUGIN_TYPE_METER_TAB*/, 2, 'Raw meter data');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter administrator'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter reader'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
BEGIN
	FOR r IN (SELECT *
			    FROM dba_scheduler_jobs 
			   WHERE owner = 'CSR' 
				 AND job_name = 'TRIGGERREGIONTREESYNCJOBS')
	LOOP
		DBMS_SCHEDULER.DROP_JOB(
			job_name             => 'csr.TriggerRegionTreeSyncJobs'
		);
	END LOOP;
    DBMS_SCHEDULER.CREATE_JOB(
       job_name             => 'csr.TriggerRegionTreeSyncJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'region_tree_pkg.TriggerRegionTreeSyncJobs;',
       job_class            => 'low_priority_job',
       start_date           => TO_DATE('2016-05-24 02:00:00','yyyy-mm-dd hh24:mi:ss'),
       repeat_interval      => 'FREQ=DAILY;BYHOUR=2',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise secondary trees'
    );
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (72, 'Management company secondary tree', 'EnableManagementCompanyTree', 'Enables the management company secondary tree.');
BEGIN
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.all_meter m
		  JOIN csr.customer c ON c.app_sid = m.app_sid
		 WHERE m.urjanet_meter_id IS NOT NULL
	) LOOP
		security.user_pkg.logonadmin(a.host);
		-- Usually much quicker to recompute them all in one go
		csr.temp_meter_pkg.UpdateMeterListCache(null);
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterQuickChartTab', 'Credit360.Metering.Plugins.MeterQuickChartTab', 'Display data for the meter in a calendar view, chart, list, or pivot table.', '/csr/shared/plugins/screenshots/property_tab_meter_list.png');
INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Meter audit log', '/csr/site/meter/controls/AuditLogTab.js', 'Credit360.Metering.AuditLogTab', 'Credit360.Metering.Plugins.AuditLogTab', 'Log changes to the meter region and any patches made to the meter data.', '/csr/shared/plugins/screenshots/meter_audit_log_tab.png');
INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES (NULL, csr.plugin_id_seq.nextval, 16, 'Actions tab', '/csr/site/meter/controls/IssuesTab.js', 'Credit360.Metering.IssuesTab', 'Credit360.Plugins.PluginDto', 'Show all actions associated with the meter, and raise new actions.', '/csr/shared/plugins/screenshots/meter_issue_list_tab.png');
UPDATE csr.plugin
   SET description = 'Meter data quick chart'
 WHERE js_class = 'Credit360.Metering.MeterListTab'
   AND app_sid IS NULL
   AND js_include = '/csr/site/meter/controls/meterListTab.js'
   AND description = 'Meter data list';
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) 
VALUES (1, 25, 'Portlet');
INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) 
VALUES (1, 26, 'Dashboard');
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (71, 'Audit log reports: Dashboards', 'EnableDashboardAuditLogReports', 'Enables the audit log reports page in the admin menu and adds dashboard report. NOTE - not related to the audits module. This is audit LOGS', 0);
DECLARE
	v_portlet_id			NUMBER := 2; -- Table Portlet
BEGIN
	UPDATE csr.portlet
	   SET default_state = TO_CLOB('{"includeExcelValueLinks":true}')
	 WHERE portlet_id = v_portlet_id;
	security.user_pkg.LogOnAdmin();
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
			  JOIN csr.tab_portlet tp on c.app_sid = tp.app_sid
			  JOIN csr.customer_portlet cp on tp.customer_portlet_sid = cp.customer_portlet_sid
			  JOIN csr.portlet p on cp.portlet_id = p.portlet_id
			 WHERE p.portlet_id = v_portlet_id
			   AND NVL(INSTR(tp.state, 'includeExcelValueLinks'), 0) = 0
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);
		UPDATE csr.tab_portlet
		   SET state = CASE WHEN NVL(LENGTH(state), 0) = 0 THEN TO_CLOB('{"includeExcelValueLinks":true}') ELSE SUBSTR(state, 0, LENGTH(state) - 1) || ',"includeExcelValueLinks":true}' END
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tab_portlet_id IN (
			SELECT tp.tab_portlet_id
			  FROM csr.tab_portlet tp
			  JOIN csr.customer_portlet cp on tp.customer_portlet_sid = cp.customer_portlet_sid
			  JOIN csr.portlet p on cp.portlet_id = p.portlet_id
			 WHERE tp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND p.portlet_id = v_portlet_id
			   AND NVL(INSTR(tp.state, 'includeExcelValueLinks'), 0) = 0
		);
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
DECLARE
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE plugin_type_id = 16
	   AND js_class = 'Credit360.Metering.MeterHiResChartTab';
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
		VALUES (csr.plugin_id_seq.NEXTVAL, 16, 'Hi-res chart', '/csr/site/meter/controls/meterHiResChartTab.js', 
			'Credit360.Metering.MeterHiResChartTab', 'Credit360.Metering.Plugins.MeterHiResChart')
		RETURNING plugin_id INTO v_plugin_id;
	FOR a IN (
		SELECT DISTINCT c.app_sid, c.host
		  FROM csr.meter_source_type s
		  JOIN csr.customer c ON c.app_sid = s.app_sid
	) LOOP
		security.user_pkg.logonadmin(a.host);
		BEGIN
			INSERT INTO csr.meter_tab(plugin_id, plugin_type_id, pos, tab_label)
			VALUES (v_plugin_id, 16, 1, 'Hi-res chart');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Administrators'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter administrator'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		BEGIN
			INSERT INTO csr.meter_tab_group(plugin_id, group_sid)
			VALUES (v_plugin_id, security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getACT, security.security_pkg.getAPP, 'Groups/Meter reader'));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL; -- Ignore if the grop/rolw is not present
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- ignore dupes
		END;
		security.user_pkg.logonadmin;
	END LOOP;
END;
/
BEGIN
	INSERT INTO CSR.ISSUE_ACTION_TYPE(ISSUE_ACTION_TYPE_ID, DESCRIPTION)
	VALUES(22/*CSR.CSR_DATA_PKG.IAT_REGION_CHANGED*/, 'Region changed');
END;
/
UPDATE chain.aggregate_type
   SET description = 'Total'
 WHERE card_group_id = 46 
   AND description = 'Total consumption';
INSERT INTO csr.audit_type(audit_type_id, label, audit_type_group_id)
VALUES(24, 'Meter patch updated', 1);
UPDATE CSR.UTIL_SCRIPT 
   SET UTIL_SCRIPT_SP = 'SetAutoPCSheetStatusFlag'
 WHERE UTIL_SCRIPT_ID = 9;
DELETE FROM CSR.UTIL_SCRIPT_PARAM
 WHERE UTIL_SCRIPT_ID=9;
 
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE,PARAM_HIDDEN) 
VALUES (9,'Setting value (0 off, 1 on)','The setting to use.',0,null,0);
DECLARE
	v_menu_scenario				VARCHAR(255) := '/csr/site/scenario/scenarioList.acds';
	v_web_resource				VARCHAR(255) := '/csr/site/scenario';
BEGIN
	security.user_pkg.LogOnAdmin();
	FOR s IN (
		SELECT host, app_sid
		  FROM (
			SELECT DISTINCT w.website_name host, c.app_sid,
				   ROW_NUMBER() OVER (PARTITION BY c.app_sid ORDER BY c.app_sid) rn
			  FROM csr.customer c
			  JOIN security.website w ON c.app_sid = w.application_sid_id
		)
		 WHERE rn = 1
	)
	LOOP
		security.user_pkg.LogOnAdmin(s.host);
		FOR s IN (
			SELECT m.sid_id AS menu_sid
			  FROM security.menu m
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			   AND m.action = v_menu_scenario
		)
		LOOP
			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), s.menu_sid);
		END LOOP;
		
		FOR t IN (
			SELECT wr.sid_id AS web_resource_sid
			  FROM security.web_resource wr
			  JOIN security.securable_object so ON wr.sid_id = so.sid_id
			 WHERE so.application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
			   AND (wr.path = v_web_resource)
		)
		LOOP
			security.securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), t.web_resource_sid);
		END LOOP;
		
		security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
BEGIN
	INSERT INTO csr.sheet_action (sheet_action_id, description, colour, downstream_description) VALUES (13, 'Data being entered', 'R', 'Data being entered');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 1, 0, 0, 0, 0, 0, 1);
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 2, 1, 1, 0, 0, 1, 1);
	INSERT INTO csr.sheet_action_permission (sheet_action_id, user_level, can_save, can_submit, can_accept, can_return, can_delegate, can_view) VALUES (13, 3, 0, 0, 0, 0, 0, 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (13, 'Enable configurable meter page', 'Enables the meter "washing machine" page, a configurable page that replaces the existing meter page.', 'EnableMeterWashingMachine', NULL);
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.host
		  FROM csr.customer c
		  JOIN csr.customer_region_type crt ON c.app_sid = crt.app_sid
		 WHERE crt.region_type = 1
		 GROUP BY c.host
	) LOOP		
		security.user_pkg.LogonAdmin(r.host);
		
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 1, 1, 1); -- serial number
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 1, 2, 3); -- meter source
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 2, 1, 4); -- space
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 2, 2, 2); -- meter type
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/


DROP PACKAGE csr.temp_meter_pkg;




@..\role_pkg
@..\csr_user_pkg
@..\structure_import_pkg
@..\..\..\security\db\oracle\user_pkg
@..\..\..\security\db\oracle\accountpolicy_pkg
@..\meter_pkg
@..\region_tree_pkg
@..\enable_pkg
@..\schema_pkg
@..\chain\filter_pkg
@..\csr_data_pkg
@..\portlet_pkg
@..\dataview_pkg
@..\issue_pkg
@..\csrimp\imp_pkg
@..\meter_report_pkg
@..\meter_patch_pkg
@..\util_script_pkg
@..\delegation_pkg
@..\issue_report_pkg


@..\role_body
@..\csr_user_body
@..\structure_import_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\..\..\security\db\oracle\user_body
@..\..\..\security\db\oracle\accountpolicy_body
@..\csr_app_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\setup_body
@..\chain\supplier_audit_body
@..\meter_report_body
@..\meter_body
@..\region_tree_body
@..\enable_body
@..\quick_survey_body
@..\chain\filter_body
@..\initiative_report_body
@..\property_report_body
@..\user_report_body
@..\..\..\aspen2\cms\db\filter_body
@..\issue_body
@..\util_script_body
@..\supplier_body
@..\deleg_plan_body
@..\automated_export_body
@..\csr_data_body
@..\portlet_body
@..\dataview_body
@..\chain\company_body
@..\non_compliance_report_body
@..\tag_body
@..\region_body
@..\meter_patch_body
@..\delegation_body
@..\sheet_body
@..\issue_report_body
@..\plugin_body
@..\indicator_body
@..\region_metric_body
@..\property_body
@..\meter_alarm_body
@..\audit_body



@update_tail

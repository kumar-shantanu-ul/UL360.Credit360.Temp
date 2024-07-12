-- Please update version.sql too -- this keeps clean builds in sync
define version=1992
@update_header

ALTER TABLE CSR.TEAMROOM_TYPE_TAB DROP CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE;
ALTER TABLE CSR.TEAMROOM_TYPE_TAB ADD CONSTRAINT CHK_TEAMROOM_TAB_PLUGIN_TYPE CHECK (PLUGIN_TYPE_ID=5 OR PLUGIN_TYPE_ID=6 OR PLUGIN_TYPE_ID=7 OR PLUGIN_TYPE_ID=8 OR PLUGIN_TYPE_ID=9);

ALTER TABLE csr.calendar ADD APPLIES_TO_INITIATIVES NUMBER(1, 0) DEFAULT 0 NOT NULL;

ALTER TABLE csr.issue ADD FORECAST_DTM DATE;
ALTER TABLE csr.issue ADD LAST_FORECAST_DTM DATE;
ALTER TABLE csr.issue_action_log ADD OLD_FORECAST_DTM DATE;
ALTER TABLE csr.issue_action_log ADD NEW_FORECAST_DTM DATE;
ALTER TABLE csr.issue_type ADD SHOW_FORECAST_DTM NUMBER(1,0) DEFAULT 0 NOT NULL;

INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (18, 'Forecast date changed');

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	       i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
		   i.is_public, i.is_pending_assignment, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
		   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
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
		   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
	   AND i.deleted = 0
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
	   ));
/
	   
CREATE OR REPLACE PACKAGE CSR.teamroom_initiative_pkg
AS
END;
/

GRANT EXECUTE ON csr.teamroom_initiative_pkg TO WEB_USER;
GRANT EXECUTE ON csr.teamroom_initiative_pkg TO SECURITY;

@..\csr_data_pkg

@..\teamroom_pkg
@..\teamroom_body

@..\initiative_pkg
@..\initiative_body

@..\teamroom_initiative_pkg
@..\teamroom_initiative_body

@..\calendar_pkg
@..\calendar_body

@..\issue_pkg
@..\issue_body

DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
	v_act			security.security_pkg.T_ACT_ID;
BEGIN
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (8, 'Teamroom initiative tab');
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (9, 'Teamroom initiative main tab');
 
    -- now added specific plugins
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Teamroom.Initiatives.SummaryPanel',
        in_description      => 'Summary',
        in_js_include       => '/csr/site/teamroomInitiatives/controls/SummaryPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Teamroom.Initiatives.DocumentsPanel',
        in_description      => 'Documents',
        in_js_include       => '/csr/site/teamroomInitiatives/controls/DocumentsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Teamroom.Initiatives.CalendarPanel',
        in_description      => 'Calendar',
        in_js_include       => '/csr/site/teamroomInitiatives/controls/CalendarPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.plugin_pkg.SetPlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Teamroom.Initiatives.IssuesPanel',
        in_description      => 'Actions',
        in_js_include       => '/csr/site/teamroomInitiatives/controls/IssuesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
	
	security.user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	FOR app IN (SELECT DISTINCT host FROM csr.customer c JOIN csr.teamroom t ON c.app_sid = t.app_sid JOIN security.website w ON LOWER(w.website_name) = LOWER(c.host))
	LOOP
		security.user_pkg.LogonAdmin(app.host);
		
		FOR tt IN (SELECT DISTINCT teamroom_type_id FROM csr.teamroom_type)
		LOOP		
			csr.teamroom_pkg.InsertTab(tt.teamroom_type_id, 'Teamroom.Initiatives.SummaryPanel', 'Summary', 1);
			csr.teamroom_pkg.InsertTab(tt.teamroom_type_id, 'Teamroom.Initiatives.DocumentsPanel', 'Documents', 2);
			csr.teamroom_pkg.InsertTab(tt.teamroom_type_id, 'Teamroom.Initiatives.CalendarPanel', 'Calendar', 3);
			csr.teamroom_pkg.InsertTab(tt.teamroom_type_id, 'Teamroom.Initiatives.IssuesPanel', 'Milestones', 4);
		END LOOP;
	END LOOP;
END;
/

@update_tail
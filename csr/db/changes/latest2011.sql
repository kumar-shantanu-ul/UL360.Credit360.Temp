-- Please update version.sql too -- this keeps clean builds in sync
define version=2011
@update_header

ALTER TABLE CSR.SNAPSHOT ADD (
		IS_PROPERTY			       NUMBER(1, 0)      DEFAULT 0 NOT NULL,
		CONSTRAINT CHK_SNPSHT_IS_PROP_0_OR_1 CHECK (IS_PROPERTY IN (0,1))
);


ALTER TABLE CSR.ISSUE_SUPPLIER RENAME COLUMN SUPPLIER_SID TO COMPANY_SID;
ALTER TABLE CSR.SUPPLIER RENAME COLUMN SUPPLIER_SID TO COMPANY_SID;


CREATE TABLE CSR.TEAMROOM_COMPANY(
		APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
		TEAMROOM_SID    NUMBER(10, 0)    NOT NULL,
		COMPANY_SID     NUMBER(10, 0)    NOT NULL,
		ADDED_BY_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
		ADDED_DTM       DATE             DEFAULT SYSDATE NOT NULL,
		CONSTRAINT PK_TEAMROOM_COMPANY PRIMARY KEY (APP_SID, TEAMROOM_SID, COMPANY_SID)
);


ALTER TABLE CSR.TEAMROOM_COMPANY ADD CONSTRAINT FK_SUPPLIER_TMROOM_CPY 
		FOREIGN KEY (APP_SID, COMPANY_SID)
		REFERENCES CSR.SUPPLIER(APP_SID, COMPANY_SID) ON DELETE CASCADE;

ALTER TABLE CSR.TEAMROOM_COMPANY ADD CONSTRAINT FK_TMROOM_TMROOM_CPY 
		FOREIGN KEY (APP_SID, TEAMROOM_SID)
		REFERENCES CSR.TEAMROOM(APP_SID, TEAMROOM_SID) ON DELETE CASCADE;


CREATE OR REPLACE VIEW csr.v$supplier AS
		SELECT s.app_sid, s.company_sid, s.region_sid, s.logo_file_sid, s.recipient_sid, s.last_supplier_score_id,
					 sc.score, sc.set_dtm score_last_changed, sc.score_threshold_id
			FROM supplier s
			LEFT JOIN supplier_score sc ON s.company_sid = sc.supplier_sid AND s.last_supplier_score_id = sc.supplier_score_id;
		

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
			 i.issue_escalated, i.owner_role_sid, i.owner_user_sid, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
			 i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
			 resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
			 closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
			 rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
			 assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
			 assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
			 sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
			 i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
			 CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
			 issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_supplier_id,
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
			 ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner
		FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
				 (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs
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
		 AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
		 AND i.deleted = 0
		 AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
			FROM issue_non_compliance inc
			JOIN audit_non_compliance anc ON inc.non_compliance_id = anc.non_compliance_id AND inc.app_sid = anc.app_sid
		 WHERE NOT EXISTS (SELECT NULL FROM trash t WHERE t.trash_sid = anc.internal_audit_sid)
		 ));




CREATE TABLE CSR.INITIATIVE_GROUP_FLOW_STATE(
		APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
		INITIATIVE_USER_GROUP_ID    NUMBER(10, 0)    NOT NULL,
		FLOW_STATE_ID               NUMBER(10, 0)    NOT NULL,
		IS_EDITABLE                 NUMBER(1, 0)     DEFAULT 0 NOT NULL,
		FLOW_SID                    NUMBER(10, 0)    NOT NULL,
		PROJECT_SID                 NUMBER(10, 0)    NOT NULL,
		CHECK (IS_EDITABLE IN (0,1)),
		CONSTRAINT PK_INITIATIVE_GROUP_FLOW_STATE PRIMARY KEY (APP_SID, INITIATIVE_USER_GROUP_ID, FLOW_STATE_ID, PROJECT_SID)
);

ALTER TABLE CSR.INITIATIVE_GROUP_FLOW_STATE ADD CONSTRAINT FK_FL_ST_INIT_GRP_FL_ST
		FOREIGN KEY (APP_SID, FLOW_STATE_ID, FLOW_SID)
		REFERENCES CSR.FLOW_STATE(APP_SID, FLOW_STATE_ID, FLOW_SID) ON DELETE CASCADE;

ALTER TABLE CSR.INITIATIVE_GROUP_FLOW_STATE ADD CONSTRAINT FK_INT_PR_UGRP_INT_GRP_FL_ST
		FOREIGN KEY (APP_SID, INITIATIVE_USER_GROUP_ID, PROJECT_SID)
		REFERENCES CSR.INITIATIVE_PROJECT_USER_GROUP(APP_SID, INITIATIVE_USER_GROUP_ID, PROJECT_SID) ON DELETE CASCADE;

INSERT INTO CSR.INITIATIVE_GROUP_FLOW_STATE
	 (APP_SID, INITIATIVE_USER_GROUP_ID, FLOW_STATE_ID, IS_EDITABLE, FLOW_SID, PROJECT_SID)
		SELECT DISTINCT iufs.app_sid, iufs.INITIATIVE_USER_GROUP_ID, iufs.FLOW_STATE_ID, iufs.IS_EDITABLE, iufs.FLOW_SID, iu.PROJECT_SID
			FROM CSR.INITIATIVE_USER_FLOW_STATE iufs
			JOIN CSR.INITIATIVE_USER iu ON iufs.initiative_sid = iu.initiative_sid AND iufs.initiative_user_group_id = iu.initiative_user_group_id AND iufs.user_sid = iu.user_sid;

--DROP TABLE CSR.INITIATIVE_USER_FLOW_STATE;

ALTER TABLE CSR.RULESET ADD (
    ENABLED                 NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_RULESET_ENABLED CHECK (ENABLED IN (0,1))
);
		

ALTER TABLE CSR.INITIATIVE_METRIC_INST RENAME TO INITIATIVE_METRIC_VAL;

CREATE OR REPLACE VIEW csr.v$my_initiatives AS
	SELECT  i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
		r.role_sid, r.name role_name,
		MAX(fsr.is_editable) is_editable,
		rg.active,
		null owner_sid
		FROM  region_role_member rrm
		JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
		JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
		JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
		JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
		JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
	 WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid,
		ir.region_sid,
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
		r.role_sid, r.name,
		rg.active
	 UNION ALL
	SELECT  i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour,
		null role_sid,  null role_name,
		MAX(igfs.is_editable) is_editable,
		rg.active,
		iu.user_sid owner_sid
		FROM initiative_user iu
		JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
		JOIN initiative_project_user_group ipug 
		ON iu.initiative_user_group_id = ipug.initiative_user_group_id
		 AND iu.project_sid = ipug.project_sid
		JOIN initiative_group_flow_state igfs
		ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
		 AND ipug.project_sid = igfs.project_sid
		 AND ipug.app_sid = igfs.app_sid
		 AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
		JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
		LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
	 WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
	 GROUP BY i.app_sid, i.initiative_sid, ir.region_sid, 
		fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour,
		rg.active, iu.user_sid;

@..\teamroom_pkg
@..\supplier_pkg
@..\snapshot_pkg
@..\initiative_aggr_pkg
@..\initiative_metric_pkg
@..\initiative_grid_pkg
@..\property_pkg

@..\initiative_body
@..\initiative_aggr_body
@..\initiative_metric_body
@..\initiative_grid_body
@..\initiative_project_body
@..\initiative_import_body
@..\teamroom_body
@..\supplier_body
@..\snapshot_body
@..\region_body
@..\quick_survey_body
@..\issue_body
@..\property_body
@..\chain\company_body
@..\chain\dashboard_body
@..\chain\report_body
@..\chain\flow_form_body

@update_tail
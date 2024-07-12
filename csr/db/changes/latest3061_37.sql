-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.issue_due_source (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	issue_due_source_id				NUMBER(10,0) NOT NULL,
	issue_type_id					NUMBER(10,0) NOT NULL,
	source_description				VARCHAR2(1024) NOT NULL,
	fetch_proc						VARCHAR2(256) NOT NULL,
    CONSTRAINT pk_issue_due_source	PRIMARY KEY (app_sid, issue_due_source_id)
);

ALTER TABLE csr.issue_due_source ADD CONSTRAINT fk_issue_due_source_issue_type
	FOREIGN KEY (app_sid, issue_type_id) 
	REFERENCES csr.issue_type (app_sid, issue_type_id);

CREATE INDEX csr.issue_due_source_issue_type ON csr.issue_due_source(app_sid, issue_type_id);

CREATE TABLE csrimp.issue_due_source (
	csrimp_session_id				NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	issue_due_source_id				NUMBER(10,0) NOT NULL,
	issue_type_id					NUMBER(10,0) NOT NULL,
	source_description				VARCHAR2(1024) NOT NULL,
	fetch_proc						VARCHAR2(256) NOT NULL,
    CONSTRAINT pk_issue_due_source	PRIMARY KEY (csrimp_session_id, issue_due_source_id),
    CONSTRAINT fk_issue_due_source_is 
		FOREIGN KEY (CSRIMP_SESSION_ID) 
		REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) 
		ON DELETE CASCADE
);

-- Alter tables
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.issue DROP CONSTRAINT CHK_ISSUE_FKS';
EXCEPTION 
	WHEN OTHERS THEN NULL;
END;
/

ALTER TABLE csr.issue ADD (
	issue_due_source_id				NUMBER(10,0) NULL,
	issue_due_offset_days			NUMBER(10,0) NULL,
	issue_due_offset_months			NUMBER(10,0) NULL,
	issue_due_offset_years			NUMBER(10,0) NULL,
	permit_id						NUMBER(10,0) NULL,
	CONSTRAINT CHK_ISSUE_FKS CHECK (
		CASE WHEN ISSUE_PENDING_VAL_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SHEET_VALUE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SURVEY_ANSWER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_NON_COMPLIANCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_ACTION_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_ALARM_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_RAW_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_DATA_SOURCE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_METER_MISSING_DATA_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_SUPPLIER_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_INITIATIVE_ID IS NOT NULL THEN 1 ELSE 0 END +
		CASE WHEN ISSUE_COMPLIANCE_REGION_ID IS NOT NULL OR PERMIT_ID IS NOT NULL THEN 1 ELSE 0 END
		IN (0, 1)
	)
);

ALTER TABLE csr.issue ADD CONSTRAINT fk_issue_issue_due_source 
	FOREIGN KEY (app_sid, issue_due_source_id) 
	REFERENCES csr.issue_due_source (app_sid, issue_due_source_id);

ALTER TABLE csr.issue ADD CONSTRAINT fk_issue_permit
	FOREIGN KEY (app_sid, permit_id) 
	REFERENCES csr.compliance_permit (app_sid, compliance_permit_id);

CREATE INDEX csr.issue_issue_due_source ON csr.issue(app_sid, issue_due_source_id);
CREATE INDEX csr.issue_permit ON csr.issue(app_sid, permit_id);

ALTER TABLE csrimp.issue ADD (
	issue_due_source_id				NUMBER(10,0) NULL,
	issue_due_offset_days			NUMBER(10,0) NULL,
	issue_due_offset_months			NUMBER(10,0) NULL,
	issue_due_offset_years			NUMBER(10,0) NULL,
	permit_id						NUMBER(10,0) NULL 
);

-- *** Grants ***
grant select,insert,update,delete on csrimp.issue_due_source to tool_user;
grant insert on csr.issue_due_source to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- @../create_views.sql
CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email,
	   r2.name owner_role_name, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, i.manual_completion_dtm, manual_comp_dtm_set_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour,
	   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, 
	   c.more_info_1 correspondent_more_info_1, sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, 
	   ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment, 
	   ist.enable_manual_comp_date, ist.comment_is_optional, ist.due_date_is_mandatory, ist.is_region_editable is_issue_type_region_editable, i.issue_priority_id, 
	   ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, 
	   i.first_priority_set_dtm, issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id,
	   issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id, issue_compliance_region_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL AND i.manual_completion_dtm IS NULL THEN 0 ELSE 1
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
	   END status,
	   CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close, ist.auto_close_after_resolve_days,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden, ist.create_raw,
	   i.permit_id, i.issue_due_source_id, i.issue_due_offset_days, i.issue_due_offset_months, i.issue_due_offset_years, ids.source_description due_dtm_source_description,
	   CASE WHEN EXISTS(SELECT * 
						  FROM issue_due_source ids
						 WHERE ids.app_sid = i.app_sid 
						   AND ids.issue_type_id = i.issue_type_id)
			THEN 1 ELSE 0
	   END relative_due_dtm_enabled,
	   i.is_critical, ist.allow_critical
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, role r2, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv, issue_due_source ids
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
   AND i.app_sid = ids.app_sid(+) AND i.issue_due_source_id = ids.issue_due_source_id(+)
   AND i.deleted = 0;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../compliance_pkg
@../csr_data_pkg
@../flow_pkg
@../issue_pkg
@../permit_pkg
@../schema_pkg

@../csrimp/imp_body
@../compliance_body
@../csr_app_body
@../flow_body
@../enable_body
@../issue_body
@../issue_report_body
@../permit_body
@../schema_body

@update_tail

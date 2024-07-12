-- Please update version.sql too -- this keeps clean builds in sync
define version=2723
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.issue_type
ADD lookup_key VARCHAR2(255);

ALTER TABLE csrimp.issue_type
ADD lookup_key VARCHAR2(255);

ALTER TABLE chain.saved_filter ADD (
	exclude_from_reports		NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_svd_filr_exl_frm_reports CHECK (exclude_from_reports IN (0,1))
);

ALTER TABLE cms.tab_column ADD (
	show_in_breakdown				NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT chk_show_in_breakdown_1_0 CHECK (show_in_breakdown IN (1, 0))
);

ALTER TABLE csrimp.cms_tab_column ADD (
	show_in_breakdown				NUMBER(1),
	CONSTRAINT chk_show_in_breakdown_1_0 CHECK (show_in_breakdown IN (1, 0))
);

UPDATE csrimp.cms_tab_column SET show_in_breakdown = 1;
ALTER TABLE csrimp.cms_tab_column MODIFY show_in_breakdown NOT NULL;

ALTER TABLE csr.initiatives_options
  ADD (METRICS_START_YEAR NUMBER(10, 0) DEFAULT 2012 NOT NULL);

ALTER TABLE csr.initiatives_options
  ADD (METRICS_END_YEAR NUMBER(10, 0) DEFAULT 2020 NOT NULL);

ALTER TABLE cms.tab ADD (helper_pkg VARCHAR2(255) NULL);

ALTER TABLE csrimp.cms_tab ADD (helper_pkg VARCHAR2(255) NULL);

-- limits set somewhat arbitrarily
ALTER TABLE CSR.INITIATIVES_OPTIONS
ADD CONSTRAINT CK_INIT_OPTIONS_METRICYEAR CHECK (METRICS_START_YEAR>=2000 AND METRICS_START_YEAR<=METRICS_END_YEAR AND METRICS_END_YEAR<=2200);

-- *** Grants ***

-- ** Cross schema constraints ***
CREATE UNIQUE INDEX CSR.UK_ISSUE_TYPE_LOOKUP ON CSR.ISSUE_TYPE(APP_SID, NVL(UPPER(LOOKUP_KEY), ISSUE_TYPE_ID));

-- *** Views ***
CREATE OR REPLACE FORCE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
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
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.lookup_key
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
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
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;


-- *** Data changes ***
-- RLS

-- Data
UPDATE chain.saved_filter sf
   SET exclude_from_reports = 1
 WHERE NOT EXISTS (
	SELECT *
	  FROM chain.saved_filter_aggregation_type sfat
	 WHERE sfat.saved_filter_sid = sf.saved_filter_sid
 );

UPDATE csr.delegation
   SET editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
 WHERE editing_url IN (
	'/csr/site/delegation/sheet.acds?popup=0&',
	'/csr/site/sheet/sheetPage3.acds?popup=0&',
	'/csr/site/sheet/sheetPage3.acds?popup=1&',
	'/csr/site/delegation/sheet.acds?',
	'/csr/site/sheet/sheetpage3.acds?popup=0&',
	'/csr/site/ems/ems.acds?',
	'/csr/site/sheet/sheetpage3.acds?'
);

UPDATE csr.customer
   SET editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
 WHERE editing_url IN (
'/csr/site/delegation/sheet.acds?popup=0&',
'/csr/site/sheet/sheetPage3.acds?popup=0&',
'/csr/site/delegation/sheet.acds?',
'/csr/site/sheet/sheetPage3.acds?popup=1&',
'/csr/site/sheet/sheetpage3.acds?popup=0&'
);

update csr.std_factor set value = 0.037 where std_factor_id = 184333639;
update csr.std_factor set value = 0.037 where std_factor_id = 184333789;
update csr.std_factor set value = 0.005 where std_factor_id = 184333939;
update csr.std_factor set value = 0.001 where std_factor_id = 184334089;
update csr.std_factor set value = 0.029 where std_factor_id = 184334239;
update csr.std_factor set value = 0.095 where std_factor_id = 184334389;
update csr.std_factor set value = 0.098 where std_factor_id = 184334539;
update csr.std_factor set value = 0.148 where std_factor_id = 184334689;
update csr.std_factor set value = 0.071 where std_factor_id = 184334839;
update csr.std_factor set value = 0.059 where std_factor_id = 184334989;
update csr.std_factor set value = 0.024 where std_factor_id = 184335139;
 
update csr.factor set value = 0.037 where std_factor_id = 184333639;
update csr.factor set value = 0.037 where std_factor_id = 184333789;
update csr.factor set value = 0.005 where std_factor_id = 184333939;
update csr.factor set value = 0.001 where std_factor_id = 184334089;
update csr.factor set value = 0.029 where std_factor_id = 184334239;
update csr.factor set value = 0.095 where std_factor_id = 184334389;
update csr.factor set value = 0.098 where std_factor_id = 184334539;
update csr.factor set value = 0.148 where std_factor_id = 184334689;
update csr.factor set value = 0.071 where std_factor_id = 184334839;
update csr.factor set value = 0.059 where std_factor_id = 184334989;
update csr.factor set value = 0.024 where std_factor_id = 184335139;

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can export delegation summary', 0);

-- *** Packages ***
@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\issue_pkg
@..\enable_pkg
@..\audit_report_pkg
@..\issue_report_pkg
@..\non_compliance_report_pkg
@..\chain\filter_pkg
@..\chain\setup_pkg

@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\filter_body
@..\issue_body
@..\enable_body
@..\schema_body
@..\audit_report_body
@..\issue_report_body
@..\non_compliance_report_body
@..\region_body
@..\flow_body
@..\sheet_body
@..\logistics_body
@..\csrimp\imp_body
@..\chain\company_filter_body
@..\chain\filter_body
@..\chain\invitation_body
@..\chain\setup_body

@update_tail

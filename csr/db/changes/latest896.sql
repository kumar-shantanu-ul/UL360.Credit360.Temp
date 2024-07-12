-- Please update version.sql too -- this keeps clean builds in sync
define version=896
@update_header

grant create table to csr;

/* ISSUE LOG TEXT INDEX */
create index csr.ix_issue_log_search on csr.issue_log(message) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

/* ISSUE LABEL TEXT INDEX */
create index csr.ix_issue_search on csr.issue(label) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

revoke create table from csr;



DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every minute afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.issue_log_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_issue_log_search'');ctx_ddl.sync_index(''ix_issue_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise issue text indexes');
       COMMIT;
END;
/

CREATE OR REPLACE VIEW csr.v$issue AS
	SELECT i.app_sid, i.issue_id, i.label, i.source_label, i.is_visible, i.source_url,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
		   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
		   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
		   sysdate now_dtm, due_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, i.issue_priority_id, ip.due_date_offset, CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
		   issue_pending_val_id, issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id,
		   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND SYSDATE > due_dtm THEN 1 ELSE 0 
		   END is_overdue,
		   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 
		   END is_owner,
		   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
		   END is_resolved,
		   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
		   END is_closed,
		   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
		   END is_rejected,
		   CASE  
			WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
			WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
			ELSE 'Ongoing'
		   END status
	  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, role r, correspondent c, issue_priority ip,
	       (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
	   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
	   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
	   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
	   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
	   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
	   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
	   AND (i.issue_non_compliance_id IS NULL OR i.issue_non_compliance_id NOT IN (
		-- filter out issues from deleted audits
		SELECT inc.issue_non_compliance_id
		  FROM issue_non_compliance inc
		  JOIN non_compliance nc ON inc.non_compliance_id = nc.non_compliance_id AND inc.app_sid = nc.app_sid
		  JOIN customer c ON inc.app_sid = c.app_sid
		  JOIN security.securable_object so ON nc.internal_audit_sid = so.sid_id
		 WHERE so.parent_sid_id = c.trash_sid
	   ));

	
DECLARE
v_card_id         chain.card.card_id%TYPE;
v_desc            chain.card.description%TYPE;
v_class           chain.card.class_type%TYPE;
v_js_path         chain.card.js_include%TYPE;
v_js_class        chain.card.js_class_type%TYPE;
v_css_path        chain.card.css_include%TYPE;
v_actions         chain.T_STRING_LIST;
BEGIN
-- Credit360.Issues.Filters.StandardIssuesFilter
v_desc := 'Issues Filter';
v_class := 'Credit360.Issues.Cards.StandardIssuesFilter';
v_js_path := '/csr/site/issues/standardIssuesFilter.js';
v_js_class := 'Credit360.Issues.Filters.StandardIssuesFilter';
v_css_path := '';
BEGIN
INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
RETURNING card_id INTO v_card_id;
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
UPDATE chain.card
SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
WHERE js_class_type = v_js_class
RETURNING card_id INTO v_card_id;
END;
DELETE FROM chain.card_progression_action
WHERE card_id = v_card_id
AND action NOT IN ('default');
v_actions := chain.T_STRING_LIST('default');
FOR i IN v_actions.FIRST .. v_actions.LAST
LOOP
BEGIN
INSERT INTO chain.card_progression_action (card_id, action)
VALUES (v_card_id, v_actions(i));
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN
NULL;
END;
END LOOP;
END;
/

BEGIN
	INSERT INTO chain.card_group
	(card_group_id, name, description)
	VALUES
	(25, 'Issues Filter', 'Allows filtering of issues');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE chain.card_group
		   SET name = 'Issues Filter', 
			   description = 'Allows filtering of issues'
		 WHERE card_group_id = 25;
END;
/

grant select on chain.v$filter_value to csr;
grant select on chain.v$filter_field to csr;



@..\issue_pkg
@..\issue_body
@..\chain\filter_body

@update_tail

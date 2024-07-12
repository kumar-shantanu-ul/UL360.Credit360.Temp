-- Please update version.sql too -- this keeps clean builds in sync
define version=298
@update_header

CREATE OR REPLACE VIEW v$issue_pending AS
	SELECT i.app_sid, mi.milestone_sid, v.pending_region_id, v.pending_ind_id, mi.deliverable_sid, 
		   p.approval_step_id, i.issue_id, i.resolved_dtm 
	  FROM issue_pending_val v, 
			(SELECT aps.app_sid, aps.approval_step_id, p.pending_period_id
			   FROM approval_step aps, pending_period p
			  WHERE aps.app_sid = p.app_sid AND aps.pending_dataset_id = p.pending_dataset_id) p,
			milestone_issue mi, issue i
	 WHERE p.app_sid = v.app_sid AND p.pending_period_id = v.pending_period_id AND 
		   mi.app_sid = v.app_sid AND mi.issue_id = v.issue_id AND
		   mi.app_sid = i.app_sid AND mi.issue_id = i.issue_id;

CREATE OR REPLACE VIEW v$issue_log_alert_batch AS
	SELECT ilab.app_sid, ilab.run_at, ilabr.last_ran_at
      FROM issue_log_alert_batch ilab, issue_log_alert_batch_run ilabr
	 WHERE ilab.app_sid = ilabr.app_sid;

CREATE OR REPLACE VIEW v$issue_user AS
	SELECT iu.app_sid, iu.issue_id, iu.is_an_owner, iu.user_sid, cu.user_name, cu.full_name, cu.email
	  FROM issue_user iu, csr_user cu
	 WHERE iu.app_sid = cu.app_sid  AND iu.user_sid = cu.csr_user_sid;
	 
CREATE OR REPLACE VIEW v$issue AS
	SELECT i.app_sid, i.issue_id, label, i.deliverable_sid, mi.milestone_sid, note, i.source_label,
		   raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		   sysdate now_dtm
	  FROM issue i, csr_user curai, csr_user cures, csr_user cuclo, milestone_issue mi
	 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
	   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+) 
	   AND i.app_sid = mi.app_sid AND i.issue_id = mi.issue_id
	   AND i.app_sid = mi.app_sid AND i.deliverable_sid = mi.deliverable_sid;
	   
CREATE OR REPLACE VIEW v$issue_log AS
	SELECT il.app_sid, il.issue_log_id, il.issue_Id, il.message, il.logged_by_user_sid, 
		   cu.user_name logged_by_user_name, cu.full_name logged_by_full_name,
		   cu.email logged_by_email, il.logged_dtm, il.is_system_generated,
		   param_1, param_2, param_3, sysdate now_dtm
	  FROM issue_log il, csr_user cu
	 WHERE il.app_sid = cu.app_sid AND il.logged_by_user_sid = cu.csr_user_sid;

@update_tail

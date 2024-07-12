-- Please update version.sql too -- this keeps clean builds in sync
define version=293
@update_header

ALTER TABLE CUSTOMER ADD (
	APPROVAL_STEP_SHEET_URL		VARCHAR2(255) DEFAULT '/csr/site/pending/FormPage.acds?' NOT NULL 
);

ALTER TABLE ISSUE ADD (
	SOURCE_LABEL		VARCHAR2(2000),
    CLOSED_BY_USER_SID    NUMBER(10, 0),
    CLOSED_DTM            DATE
);

ALTER TABLE ISSUE ADD CONSTRAINT RefCSR_USER1103 
    FOREIGN KEY (APP_SID, CLOSED_BY_USER_SID)
    REFERENCES CSR_USER(APP_SID, CSR_USER_SID)
;

UPDATE ISSUE
   SET source_label = (
		SELECT TruncateString(pi.description, 600) ||' / '|| TruncateString(pr.description, 300)||' / '||pp.label
		  FROM pending_ind pi, pending_region pr, pending_period pp, issue_pending_val ipv
		 WHERE pi.pending_ind_id = ipv.pending_ind_Id 
		   AND pr.pending_region_id = ipv.pending_region_Id
		   AND pp.pending_period_Id = ipv.pending_period_id
		   AND ipv.issue_Id = issue.issue_id
);



-- backfill messages to log -- we used to get these via a UNION in INTERNAL_GetIssueLogEntries
INSERT INTO ISSUE_LOG 
	(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated,
	param_1, param_2, param_3, app_Sid)
	SELECT issue_log_id_seq.nextval, i.issue_id, pvl.description, pvl.set_by_user_sid, pvl.set_dtm, 1, 
		pvl.param_1, pvl.param_2, pvl.param_3, pvl.app_sid
	  FROM pending_val_log pvl, pending_val pv, issue_pending_val ipv, issue i
	 WHERE pvl.pending_val_id = pv.pending_val_id
	   AND pv.pending_ind_id = ipv.pending_ind_id
	   AND pv.pending_region_id = ipv.pending_region_id
	   AND pv.pending_period_id = ipv.pending_period_Id
	   AND ipv.issue_id = i.issue_id
	   AND pvl.set_dtm > i.raised_dtm;


CREATE OR REPLACE VIEW v$issue AS
	SELECT i.issue_id, label, i.deliverable_sid, mi.milestone_sid, note, i.app_sid, i.source_label,
		raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
		resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
		closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
		sysdate now_dtm
	  FROM issue i, csr_user curai, csr_user cures, csr_user cuclo, milestone_issue mi
	 WHERE i.raised_by_user_sid = curai.csr_user_sid
	   AND i.resolved_by_user_sid = cures.csr_user_sid(+) 
	   AND i.closed_by_user_sid = cuclo.csr_user_sid(+) 
	   AND i.issue_id = mi.issue_id
	   AND i.deliverable_sid = mi.deliverable_sid;
	   
BEGIN
	UPDATE CUSTOMER SET APPROVAL_STEP_SHEET_URL = '/ing/site/pending/FormPage.acds?' WHERE host='ing.credit360.com';
	UPDATE CUSTOMER SET APPROVAL_STEP_SHEET_URL = '/bat/site/pending/FormPage.acds?' WHERE host='bat.credit360.com';
END;
/

INSERT INTO PORTLET (
	PORTLET_ID, NAME, TYPE, SCRIPT_PATH
) values (
	portlet_id_seq.nextval, 'My questionnaires', 'Credit360.Portlets.MyApprovalSteps', '/csr/site/portal/Credit360.Portlets.MyApprovalSteps.js'
);


INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (
	18, 'Mail sent containing issue summaries', NULL, 
	'<params>'||
		'<param name="FROM_NAME"/>'||
		'<param name="FROM_EMAIL"/>'||
		'<param name="SUMMARY"/>'||
	'</params>'
); 

SET DEFINE OFF 

@..\pending_pkg
@..\pending_body

@..\issue_pkg
@..\issue_body

@..\approval_step_range_pkg
@..\approval_step_range_body

@..\val_datasource_pkg
@..\val_datasource_body


SET DEFINE ON

@update_tail

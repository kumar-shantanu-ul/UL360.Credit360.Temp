CREATE OR REPLACE PACKAGE BODY CSR.auto_approve_pkg AS

PROCEDURE PostSubmit(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	UPDATE sheet s
	   SET automatic_approval_status = 'P', 
		   automatic_approval_dtm = (SELECT DECODE(due_date_offset, null, SYSDATE, s.submission_dtm + due_date_offset) 
									   FROM delegation_automatic_approval 
									  WHERE app_sid = SYS_CONTEXT('SECURITY','APP'))
	 WHERE sheet_id = in_sheet_id
	 AND EXISTS (SELECT 1
				   FROM delegation_automatic_approval 
				  WHERE app_sid = SYS_CONTEXT('SECURITY','APP'));
END;

PROCEDURE PreMerge(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	NULL;
END;

PROCEDURE PostReject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_name				IN	delegation.name%TYPE,
	in_sheet_Id			IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	NULL;
END;

PROCEDURE GetDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_id, csr_user_sid 
		  FROM sheet_automatic_approval
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE AutoApprove(
	in_sheet_id		IN 		NUMBER,
	in_user_sid		IN		security_pkg.T_SID_ID,
	in_is_valid		IN		NUMBER
)
AS
	v_app			security_pkg.T_SID_ID;
	v_deleg			security_pkg.T_SID_ID;
	v_act			security_pkg.T_ACT_ID;
	v_guid			RAW(16);
	v_sheet			T_SHEET_INFO;
BEGIN
	SELECT app_sid, delegation_sid
	  INTO v_app, v_deleg
	  FROM sheet
	 WHERE sheet_id = in_sheet_id; 
	
	IF in_is_valid = 1 THEN
		user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 3600, v_app, v_act);
		v_sheet := sheet_pkg.GetSheetInfo(v_act, in_sheet_id);
		IF v_sheet.last_action_id = 1 OR v_sheet.last_action_id = 11 THEN 
			v_guid := SYS_GUID();
			sheet_pkg.Accept(v_act, in_sheet_id, to_clob(v_guid), 1);
			
			DELETE FROM sheet_history
				  WHERE sheet_id = in_sheet_id
					AND dbms_lob.compare(note, to_clob(v_guid)) = 0;
			
			sheet_pkg.CreateHistory(in_sheet_id, csr_data_pkg.ACTION_ACCEPTED, in_user_sid, v_deleg, 'Automatically approved', 1);
		END IF;
		
		UPDATE sheet 
		   SET automatic_approval_status = 'A'
		 WHERE sheet_id = in_sheet_id;
		 
		user_pkg.Logoff(v_act);
	ELSE
		sheet_pkg.CreateHistory(in_sheet_id, csr_data_pkg.ACTION_SUBMITTED, in_user_sid, v_deleg, 'Automatic approval failed: intolerances found', 1);
		
		UPDATE sheet 
		   SET automatic_approval_status = 'R'
		 WHERE sheet_id = in_sheet_id;
	END IF;
END;

PROCEDURE EnqueueAutoApproveSheets
AS
	v_batch_job_id	batch_job.batch_job_id%TYPE;
	v_act_id		security_pkg.T_ACT_ID;
BEGIN
	FOR r IN (SELECT s.app_sid, s.sheet_id, du.user_sid 
				FROM sheet_with_last_action s
				JOIN delegation d ON s.delegation_sid = d.delegation_sid
				JOIN delegation_user du ON d.parent_sid = du.delegation_sid AND du.inherited_from_sid = d.parent_sid
				JOIN security.user_table u ON u.sid_id = du.user_sid
			   WHERE s.automatic_approval_dtm <= sysdate
			     AND s.automatic_approval_status = 'P'
			     AND u.account_enabled = 1
				 AND s.last_action_id in (csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, csr_data_pkg.ACTION_ACCEPTED_WITH_MOD))
	LOOP
		v_act_id := security.user_pkg.GenerateACT();
		security.Security_pkg.SetACTAndSID(v_act_id, r.user_sid);
		security.Security_pkg.SetApp(r.app_sid);
		security.Act_Pkg.Issue(r.user_sid, v_act_id, 20, r.app_sid); --Don't want to be logged on as admin, but need sys_context
		
		IF csr_data_pkg.CheckCapabilityOfUser(r.user_sid, 'Auto Approve Valid Delegation') THEN
			batch_job_pkg.Enqueue(
				in_batch_job_type_id => batch_job_pkg.JT_AUTO_APPROVE,
				in_description => 'Auto Approve SheetID:' || r.sheet_id || ' due to UserSID:' || r.user_sid,
				out_batch_job_id => v_batch_job_id
			);
			
			INSERT INTO sheet_automatic_approval (app_sid, batch_job_id, sheet_id, csr_user_sid)
				 VALUES (r.app_sid, v_batch_job_id, r.sheet_id, r.user_sid);
			
			UPDATE sheet 
			   SET automatic_approval_status = 'Q'
			 WHERE sheet_id = r.sheet_id;
		END IF;
		
		user_pkg.Logoff(v_act_id);
	END LOOP;
END;


END auto_approve_pkg;
/

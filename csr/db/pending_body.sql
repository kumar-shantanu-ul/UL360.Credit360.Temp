CREATE OR REPLACE PACKAGE BODY CSR.pending_pkg AS

-- BROADER THINGS TO CONSIDER:
-- what if we delete indicators/regions/users in main structure (IND + REGION tables)?

FUNCTION CreateApprovalStepSID(
	in_parent_sid security_pkg.T_SID_ID
)
RETURN security_pkg.T_SID_ID AS
	v_approval_step_sid security_pkg.T_SID_ID;
BEGIN
	securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, class_pkg.GetClassId('CSRApprovalStep'), NULL, v_approval_step_sid);
	RETURN v_approval_step_sid;
END;

PROCEDURE CreateDataset(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_reporting_period_sid		IN	security_pkg.T_SID_ID,
	in_label					IN	pending_dataset.label%TYPE,
	out_pending_dataset_id		OUT	pending_dataset.pending_dataset_id%TYPE
)
AS
	v_datasets_sid security_pkg.T_SID_ID;
BEGIN
	v_datasets_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Pending/Datasets');
	
	securableobject_pkg.CreateSO(in_act_id, v_datasets_sid, class_pkg.GetClassId('CSRDataset'), NULL, out_pending_dataset_id);
	
	-- The securable object sequence is way ahead of the pending dataset sequence, so we can switch to using SIDs for IDs without the risk of hitting a duplicate.
	
	INSERT INTO pending_dataset
		(pending_dataset_id, reporting_period_sid, label, app_sid)
	VALUES
		(out_pending_dataset_id, in_reporting_period_sid, in_label, in_app_sid);
END;

PROCEDURE GetDataset(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pending_Dataset_id, reporting_period_sid, label
		  FROM pending_dataset
		 WHERE pending_Dataset_id = in_pending_dataset_id;
END;

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_OVERDUE_PENDING);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email,
			   cu.user_name,
			   c.approval_step_sheet_url||'apsId='||aps.approval_step_id||CHR(38)||'sheetKey='||apsh.sheet_key sheet_url,
			   apsh.label delegation_name, apsh.due_dtm submission_dtm, TO_CHAR(apsh.due_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt,
			   apsh.approval_step_id, apsh.sheet_key
		  FROM approval_step_sheet apsh
		  JOIN approval_step aps ON apsh.app_sid = aps.app_sid AND apsh.approval_step_id = aps.approval_step_id
		  JOIN approval_step_user apsu ON aps.app_sid = apsu.app_sid AND aps.approval_step_Id = apsu.approval_step_id
		   AND apsu.is_lurker = 0
		   AND apsu.read_only = 0
		   AND aps.parent_step_id IS NOT NULL -- don't do reminders at top level for now
			  JOIN csr_user cu ON apsu.app_sid = cu.app_sid AND apsu.user_sid = cu.csr_user_sid
			  JOIN customer c ON c.app_sid = aps.app_sid AND c.raise_reminders = 1
			  JOIN pending_dataset pds ON pds.app_sid = aps.app_sid AND pds.pending_dataset_id = aps.pending_dataset_id
			  JOIN reporting_period rp 
				ON rp.app_sid = pds.app_sid AND rp.reporting_period_sid = pds.reporting_period_sid
				AND c.current_reporting_period_sid = rp.reporting_period_sid -- just do this reporting period
			  JOIN temp_alert_batch_run tabr 
				ON apsh.due_dtm <= tabr.this_fire_time -- the sheet is overdue (in the user's local time zone)
				AND cu.app_sid = tabr.app_sid 
				AND cu.csr_user_sid = tabr.csr_user_sid
				AND tabr.std_alert_type_id = csr_data_pkg.ALERT_OVERDUE_PENDING
		  LEFT JOIN approval_step_sheet_alert apsha ON apsh.app_sid = apsha.app_sid AND apsh.approval_step_id = apsha.approval_step_id 
		   AND apsh.sheet_key = apsha.sheet_key AND apsu.app_sid = apsha.app_sid AND apsu.user_sid = apsha.user_sid
 		 WHERE apsha.overdue_sent_dtm IS NULL
		   AND apsh.submitted_value_count = 0
	     ORDER BY app_sid, csr_user_sid;	  
END;

PROCEDURE RecordOverdueSent(
	in_approval_step_id				IN 	approval_step_sheet_alert.approval_step_id%TYPE,
	in_sheet_key					IN	approval_step_sheet_alert.sheet_key%TYPE,
	in_user_sid						IN	approval_step_sheet_alert.user_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO approval_step_sheet_alert (approval_step_id, sheet_key, user_sid, overdue_sent_dtm)
		VALUES (in_approval_step_id, in_sheet_key, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE approval_step_sheet_alert
			   SET overdue_sent_dtm = SYSDATE
			 WHERE approval_step_id = in_approval_step_id
			   AND sheet_key = in_sheet_key
			   AND user_sid = in_user_sid;
	END;
END;

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_REMINDER_PENDING);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email,
			   cu.user_name, 
			   c.approval_step_sheet_url||'apsId='||aps.approval_step_id||CHR(38)||'sheetKey='||apsh.sheet_key sheet_url,
			   apsh.label delegation_name, apsh.due_dtm submission_dtm, TO_CHAR(apsh.due_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt,
			   apsh.approval_step_id, apsh.sheet_key
		  FROM approval_step_sheet apsh
			  JOIN approval_step aps ON apsh.app_sid = aps.app_sid AND apsh.approval_step_id = aps.approval_step_id
			  JOIN approval_step_user apsu ON aps.app_sid = apsu.app_sid AND aps.approval_step_Id = apsu.approval_step_id
				AND apsu.is_lurker = 0
				AND apsu.read_only = 0
				AND aps.parent_step_id IS NOT NULL -- don't do reminders at top level for now
			  JOIN csr_user cu ON apsu.app_sid = cu.app_sid AND apsu.user_sid = cu.csr_user_sid
			  JOIN customer c ON c.app_sid = aps.app_sid AND c.raise_reminders = 1
			  JOIN pending_dataset pds ON pds.app_sid = aps.app_sid AND pds.pending_dataset_id = aps.pending_dataset_id
			  JOIN reporting_period rp ON rp.app_sid = pds.app_sid AND rp.reporting_period_sid = pds.reporting_period_sid
				AND c.current_reporting_period_sid = rp.reporting_period_sid -- just do this reporting period
			  JOIN temp_alert_batch_run tabr
				ON apsh.reminder_dtm <= tabr.this_fire_time -- sheets that need a reminder
				AND apsh.due_dtm > tabr.this_fire_time -- but are not overdue (in the user's local time zone)
				AND cu.app_sid = tabr.app_sid 
				AND cu.csr_user_sid = tabr.csr_user_sid				
				AND tabr.std_alert_type_id = csr_data_pkg.ALERT_REMINDER_PENDING
			  LEFT JOIN approval_step_sheet_alert apsha ON apsh.app_sid = apsha.app_sid AND apsh.approval_step_id = apsha.approval_step_id 
				AND apsh.sheet_key = apsha.sheet_key AND apsu.app_sid = apsha.app_sid AND apsu.user_sid = apsha.user_sid
 		 WHERE apsha.reminder_sent_dtm IS NULL
		   AND apsh.submitted_value_count = 0
	  	 ORDER BY app_sid, csr_user_sid;
END;

PROCEDURE RecordReminderSent(
	in_approval_step_id				IN 	approval_step_sheet_alert.approval_step_id%TYPE,
	in_sheet_key					IN	approval_step_sheet_alert.sheet_key%TYPE,
	in_user_sid						IN	approval_step_sheet_alert.user_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO approval_step_sheet_alert (approval_step_id, sheet_key, user_sid, reminder_sent_dtm)
		VALUES (in_approval_step_id, in_sheet_key, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE approval_step_sheet_alert
			   SET reminder_sent_dtm = SYSDATE
			 WHERE approval_step_id = in_approval_step_id
			   AND sheet_key = in_sheet_key
			   AND user_sid = in_user_sid;
	END;
END;

PROCEDURE GetAllDatasetsInReportPeriod(
	in_act_id				 IN	security_pkg.T_ACT_ID,	
	in_reporting_period_sid	 IN security_pkg.T_SID_ID,
	out_cur					 OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pending_Dataset_id, reporting_period_sid, label
		  FROM pending_dataset
		 WHERE reporting_period_sid = in_reporting_period_sid;
END;

PROCEDURE AmendDataset(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN 	pending_dataset.pending_dataset_Id%TYPE,
	in_label					IN	pending_dataset.label%TYPE
)
AS
BEGIN
	UPDATE pending_Dataset
	   SET label = in_label
	 WHERE pending_dataset_id = in_pending_dataset_id;
END;


PROCEDURE DeleteDataset(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_ignore_warnings			IN	NUMBER
)
AS
BEGIN
    -- job tables
    DELETE FROM pvc_region_recalc_job
     WHERE pending_dataset_Id = in_pending_dataset_Id;
     
    DELETE FROM pvc_stored_calc_job
     WHERE pending_dataset_Id = in_pending_dataset_Id;
    
    -- pending val stuff
    DELETE FROM pending_val_variance
     WHERE pending_val_id IN (
        SELECT pending_val_id
          FROM pending_val pv, pending_ind pi
         WHERE pv.pending_ind_id = pi.pending_ind_id
           AND pi.pending_dataset_Id = in_pending_dataset_id
    );
    
    DELETE FROM pending_val_file_upload
     WHERE pending_val_id IN (
        SELECT pending_val_id
          FROM pending_val pv, pending_ind pi
         WHERE pv.pending_ind_id = pi.pending_ind_id
           AND pi.pending_dataset_Id = in_pending_dataset_id
    );
    
    DELETE FROM pending_val_log
     WHERE pending_val_id IN (
        SELECT pending_val_id
          FROM pending_val pv, pending_ind pi
         WHERE pv.pending_ind_id = pi.pending_ind_id
           AND pi.pending_dataset_Id = in_pending_dataset_id
    );

	UPDATE issue 
	   SET issue_pending_val_id = null
	 WHERE issue_pending_val_id IN (
		SELECT issue_pending_val_Id 
		   FROM issue_pending_val ipv 
			JOIN pending_ind pi ON ipv.pending_ind_id = pi.pending_ind_id
		  WHERE pending_dataset_Id = in_pending_dataset_id
     );
    DELETE FROM issue_pending_Val 
	 WHERE pending_ind_id IN (
        SELECT pending_ind_id
          FROM pending_ind 
         WHERE pending_dataset_Id = in_pending_dataset_id
    );
    
    DELETE FROM pending_val
     WHERE pending_ind_id IN (
        SELECT pending_ind_id
          FROM pending_ind 
         WHERE pending_dataset_Id = in_pending_dataset_id
    );
    
    
    -- approval steps
    DELETE FROM approval_step_region 
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step_ind 
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step_user
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step_role
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step_sheet_log
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step_sheet_alert
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );

    DELETE FROM approval_step_sheet
     WHERE approval_step_id IN (
        SELECT approval_step_id FROM approval_step WHERE pending_dataset_id = in_pending_dataset_id
     );
     
    DELETE FROM approval_step 
     WHERE pending_dataset_id = in_pending_dataset_id;
     
    DELETE FROM pending_period
     WHERE pending_dataset_id = in_pending_dataset_id;
     
    DELETE FROM pending_region
     WHERE pending_dataset_id = in_pending_dataset_id;
     
    DELETE FROM pending_ind
     WHERE pending_dataset_id = in_pending_dataset_id;
    
	DELETE FROM pending_dataset
	 WHERE pending_dataset_id = in_pending_dataset_id;
END;

PROCEDURE GetMySimilarSheets(
	in_act_Id		    IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN  approval_step.approval_step_Id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
    OPEN out_cur FOR
        SELECT aps.label, apsh.approval_step_id, apsh.sheet_key, apsh.label sheet_label, apsh.submitted_value_count, aps.max_sheet_value_count, due_dtm
    --      case when apsh.submitted_value_count >= max_sheet_value_count then 1 else 0 end fully_submitted
          FROM approval_step aps, approval_step_sheet apsh, approval_step_user apsu, (
            SELECT approval_step_id, sheet_key 
              FROM approval_step_sheet apss
             WHERE approval_step_id = in_approval_step_id
            ) this
         WHERE apsh.sheet_key = this.sheet_key -- same sheet key, different approval_steps
           AND apsh.approval_step_id = apsu.approval_step_id
           AND apsu.user_sid = v_user_sid -- same user
           AND apsh.approval_step_id = aps.approval_step_id;
END;


-- TODO: rename to getmyapprovalstepSHEETS?
PROCEDURE GetMyApprovalSteps(
	in_act_Id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	OPEN out_cur FOR
		SELECT ap.label label_1, apss.label label_2, due_dtm, submitted_value_count, visible, max_sheet_value_count, 
			apss.approval_step_id, sheet_key, pending_ind_id, pending_region_id, pending_period_id, working_day_offset_from_due,
			reminder_dtm, due_dtm, 
			c.approval_step_sheet_url||'apsId='||apss.approval_step_id||CHR(38)||'sheetKey='||apss.sheet_key sheet_url
		  FROM approval_step ap, pending_dataset pd, approval_step_sheet apss, csr_user cu, approval_step_user apsu, customer c
		 WHERE ap.approval_step_id = apsu.approval_step_id
		   AND ap.approval_step_id = apss.approval_step_id
		   AND apsu.user_sid = cu.csr_user_sid
		   AND cu.csr_user_sid = v_user_sid
           AND ap.pending_dataset_id = pd.pending_dataset_id
           AND c.app_sid = in_app_sid
           AND apss.visible = 1
           AND c.current_reporting_period_sid = pd.reporting_period_sid
		 ORDER BY label_1, label_2, apss.approval_step_id;
END;

PROCEDURE GetMyApprovalStepSheets(
	in_act_Id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	OPEN out_cur FOR
        SELECT aps.approval_step_id, aps_rownum, aps.lvl, aps.label approval_step_label, aps.max_sheet_value_count,
               apsup.user_sid submitting_to_sid, cup.full_name submitting_to_full_name, cup.email submitting_to_email,
               apsu.user_sid, cu.full_name, cu.email, apss.pending_period_id, apss.pending_ind_id, apss.pending_region_id,
               apss.label sheet_label, apss.sheet_key, apss.submitted_value_count, apss.submit_blocked, apss.due_dtm, apss.approver_response_due_dtm,
               SUM(CASE WHEN up_or_down = 1 THEN 1 ELSE 0 END) times_submitted
          FROM approval_step_sheet apss, approval_step_sheet_log apssl, approval_step apsp, approval_step_user apsup, csr_user cup,
               approval_step_user apsu, csr_user cu, (
            SELECT approval_step_id, label, level lvl, max_sheet_value_count, rownum aps_rownum,
                   CASE WHEN level = 1 THEN parent_step_id ELSE null END parent_step_id -- only get submitting to info for top level
              FROM approval_step
             START WITH approval_step_id IN ( 
                   SELECT ap.approval_step_id 
                     FROM approval_step_user apsu, approval_step ap, pending_dataset pds, customer c
                    WHERE apsu.approval_step_id = ap.approval_step_id 
                      AND ap.pending_dataset_Id = pds.pending_dataset_Id 
                      AND user_sid = v_user_sid --128916 -- v_user_sid    128916 (all), 128910 (Elaine)
                      AND c.app_sid = in_app_sid
                      AND c.current_reporting_period_sid = pds.reporting_period_sid
            )
           CONNECT BY PRIOR approval_step_id = parent_step_id
             ORDER SIBLINGS BY label
         )aps
         WHERE aps.approval_step_id = apss.approval_step_id
           AND aps.approval_step_id = apsu.approval_step_id
           AND apsu.user_sid = cu.csr_user_sid
           AND aps.parent_step_id = apsp.approval_step_id(+)
           AND apsp.approval_step_id = apsup.approval_step_id(+)
           AND apsup.user_sid = cup.csr_user_sid(+)
           AND apss.visible = 1
           AND apss.approval_step_id = apssl.approval_step_id(+)
           AND apss.sheet_Key = apssl.sheet_key(+)
         GROUP BY aps.approval_step_id, aps_rownum, aps.lvl, aps.label, aps.max_sheet_value_count,
           apsup.user_sid, cup.full_name, cup.email,
           apsu.user_sid, cu.full_name, cu.email,
           apss.label, apss.sheet_key, apss.submitted_value_count, apss.submit_blocked, apss.due_dtm, apss.approver_response_due_dtm,
           apss.pending_period_id, apss.pending_ind_id, apss.pending_region_id
         ORDER BY aps_rownum, submitting_to_sid, user_sid, sheet_key;
END;

PROCEDURE GetMyStepSheetSummary(
	out_cur_summary	OUT	SYS_REFCURSOR,
	out_cur_users	OUT	SYS_REFCURSOR
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_pending_dataset_id		pending_dataset.pending_dataset_id%TYPE;
BEGIN
	user_pkg.GetSid(SYS_CONTEXT('SECURITY', 'ACT'), v_user_sid);

	BEGIN
		SELECT
			pending_dataset_id INTO v_pending_dataset_id
		FROM
			customer
		JOIN
			pending_dataset
		ON
			pending_dataset.reporting_period_sid = customer.current_reporting_period_sid
		AND	pending_dataset.app_sid = customer.app_sid
		WHERE
			customer.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		AND	rownum = 1 -- This SQL only currently supports a single pending dataset ID. I need to revisit this.
		;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_pending_dataset_id := null;
	END;
	
	INSERT INTO
		pending_entry_ind -- All indicators in the dataset that the user can fill in.
	(
		pending_ind_id
	)
	SELECT DISTINCT
		pending_ind_id
	FROM
		pending_ind
	JOIN -- Warning: Don't turn this into a semi-join in the connect-by; Oracle gets it wrong.
		pending_element_type
	ON
		pending_ind.element_type = pending_element_type.element_type
	LEFT JOIN
		ind
	ON
		ind.ind_sid = pending_ind.maps_to_ind_sid
	AND	ind.app_sid = pending_ind.app_sid
	WHERE
		(
			-- Indicator accepts input.
			pending_element_type.is_string = 1
		OR	pending_element_type.is_number = 1
		)
		-- Exclude hidden elements. (The user can't see them to fill them in.)
	AND	pending_element_type.element_type <> 9
		-- Exclude form elements. (Data isn't merged into val, and so it can't be counted as submitted.)
	AND	pending_element_type.element_type <> 13
		-- If the pending indicator is related to a real indicator, exclude calculations. (The user can see them, but doesn't get to fill them in.)
	AND	NVL(ind.ind_type, 0) = 0
	START WITH
		-- All root indicators for this dataset.
		pending_ind.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND	pending_ind.pending_dataset_id = v_pending_dataset_id
	AND	pending_ind.parent_ind_id IS NULL
	CONNECT BY
		-- Include child indicators.
		pending_ind.app_sid = PRIOR pending_ind.app_sid
	AND	pending_ind.parent_ind_id = PRIOR pending_ind.pending_ind_id
		-- Exclude indicators where the parent indicator is editable. (Pending forms don't currently work well with such indicator trees.) TODO Is this still the case?
	AND	PRIOR pending_element_type.is_string = 0
	AND	PRIOR pending_element_type.is_number = 0
	;
		
	INSERT INTO
		approval_step_stats -- Stats for all approval steps in the dataset assigned to the current user.
	(
		approval_step_id
	,	ind_count
	,	region_count
	,	period_count
	)
	SELECT
		approval_step.approval_step_id
		-- The number of indicators in this approval step that accept input.
	,	(
			SELECT
				COUNT(*)
			FROM
				approval_step_ind
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	approval_step_id = approval_step.approval_step_id
			AND	pending_ind_id IN
				(
					SELECT
						pending_ind_id
					FROM
						pending_entry_ind
				)
		) ind_count
		-- The number of regions associated with this approval step.
	,	(
			SELECT
				COUNT(*)
			FROM
				approval_step_region
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	approval_step_id = approval_step.approval_step_id
		) region_count
		-- The number of periods associated with this approval step. (i.e. All of them.)
	,	(
			SELECT
				COUNT(*)
			FROM
				pending_period
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_dataset_id = v_pending_dataset_id
		) period_count
	FROM
		approval_step
	WHERE
		app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND	pending_dataset_id = v_pending_dataset_id
	AND	approval_step.approval_step_id IN
		(
			SELECT
				approval_step_id
			FROM
				approval_step_user
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	user_sid = v_user_sid
		)
	;

	INSERT INTO
		approval_step_summary -- All of the sheets from all of the approval steps assigned to this user for the current dataset.
	(
		approval_step_id
	,	parent_step_id
	,	sheet_key
	,	sheet_label
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	,	due_dtm
	,	approver_response_due_dtm
	,	max_ind_count
	,	max_region_count
	,	max_period_count
	,	delegated_val_count
	,	submitted_val_count
	)
	SELECT -- The zeros are calculated later.
		approval_step_id
	,	0
	,	sheet_key
	,	label
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	,	due_dtm
	,	approver_response_due_dtm
	,	0
	,	0
	,	0
	,	0
	,	0
	FROM
		approval_step_sheet
	WHERE
		app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND	approval_step_sheet.approval_step_id IN
		(
			SELECT
				approval_step_id
			FROM
				approval_step_stats
		)
	;
	
	INSERT INTO
		approval_step_hierarchy -- All the child steps of each approval step we're gathering stats for.
	(
		ancestor_step_id
	,	approval_step_id
	)
	SELECT 
		CONNECT_BY_ROOT approval_step_id
	,	approval_step_id
	FROM
		approval_step
	WHERE
		app_sid = SYS_CONTEXT('SECURITY', 'APP')
		-- Child step.
	AND	LEVEL > 1
		-- Approval steps assigned to the current user.
	START WITH
		approval_step_id
	IN
		(
			SELECT
				approval_step_id
			FROM
				approval_step_stats
		)
	CONNECT BY
		parent_step_id = PRIOR approval_step_id
	AND	app_sid = PRIOR app_sid
	;
		
	INSERT INTO
		pending_region_descendants -- For each ancestor_region_id, list all the descendant (or self) pending_region_ids.
	(
		ancestor_region_id
	,	pending_region_id
	)
	SELECT
		CONNECT_BY_ROOT pending_region_id
	,	pending_region_id
	FROM
		pending_region
	START WITH
		-- Pending regions assigned to the approval steps that are assigned to the current user.
		pending_region_id IN
		(
			SELECT DISTINCT
				pending_region_id
			FROM
				approval_step_region
			WHERE
				approval_step_id IN
				(
					SELECT
						approval_step_id
					FROM
						approval_step_stats
				)
			AND	app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
	CONNECT BY
		-- Child regions.
		PRIOR pending_region_id = parent_region_id
	AND	PRIOR app_sid = app_sid
	;

	UPDATE
		approval_step_summary
	SET
		parent_step_id =
		(
			SELECT
				parent_step_id
			FROM
				approval_step
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	approval_step_id = approval_step_summary.approval_step_id
		)
		-- The number of indicators (that accept input) that this sheet is collecting values for.
	,	max_ind_count =
		(
			CASE
				WHEN approval_step_summary.pending_ind_id IS NULL THEN
				(
					SELECT
						ind_count
					FROM
						approval_step_stats
					WHERE
						approval_step_id = approval_step_summary.approval_step_id
				)
				ELSE 1
				END
		)
		-- The number of regions that this sheet is collecting values for.
	,	max_region_count =
		(
			CASE
				WHEN approval_step_summary.pending_region_id IS NULL THEN
				(
					SELECT
						region_count
					FROM
						approval_step_stats
					WHERE
						approval_step_id = approval_step_summary.approval_step_id
				)
				ELSE 1
				END
		) 
		-- The number of periods that this sheet is collecting values for.
	,	max_period_count =
		(
			CASE
				WHEN approval_step_summary.pending_period_id IS NULL THEN
				(
					SELECT
						period_count
					FROM
						approval_step_stats
					WHERE
						approval_step_id = approval_step_summary.approval_step_id
				)
				ELSE 1
				END
		)
	;
	
	INSERT INTO
		approval_step_val
	(
		approval_step_id
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	)
	SELECT
		approval_step_id
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	FROM
		pending_val
	WHERE
		pending_val.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		-- The value is for a descendant approval step.
	AND	EXISTS
		(
			SELECT
				*
			FROM
				approval_step_hierarchy
			WHERE
				approval_step_id = pending_val.approval_step_id
		)
		-- The value is 
	AND	pending_val.pending_period_id IN
		(
			SELECT
				pending_period_id
			FROM
				approval_step_summary -- All of the sheets from all of the approval steps assigned to this user for the current dataset.
			UNION SELECT
				pending_period_id
			FROM
				pending_period
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_dataset_id = (select pending_dataset_id from pending_dataset where reporting_period_sid = (select current_reporting_period_sid from customer))
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_summary
					WHERE
						pending_period_id IS NULL
				)
		)
	AND	EXISTS
		(
			SELECT
				pending_region_id
			FROM
				pending_region_descendants
			WHERE
				pending_region_id = pending_val.pending_region_id
		)
	AND	EXISTS
		(
			SELECT
				*
			FROM
				approval_step_ind
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_ind_id = pending_val.pending_ind_id
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_stats -- An indicator can't appear halfway down the approval step hierarchy: if it's in any approval step, it'll be in the root approval steps.
					WHERE
						approval_step_id = approval_step_ind.approval_step_id
				)
			AND	EXISTS
				(
					SELECT
						*
					FROM
						pending_entry_ind
					WHERE
						pending_ind_id = pending_val.pending_ind_id
				)
		)
	;

	UPDATE
		approval_step_summary
	SET
		delegated_val_count = 
		(
			SELECT
				COUNT(DISTINCT pending_ind_id)
			FROM
				approval_step_val
			WHERE
				EXISTS
				(
					SELECT
						*
					FROM
						approval_step_hierarchy
					WHERE
						ancestor_step_id = approval_step_summary.approval_step_id
					AND	approval_step_id = approval_step_val.approval_step_id
				)
			AND	EXISTS
				(
					SELECT
						*
					FROM
						pending_region_descendants
					WHERE
						ancestor_region_id = approval_step_summary.pending_region_id
					AND	pending_region_id = approval_step_val.pending_region_id
				)
			AND	pending_period_id = approval_step_summary.pending_period_id
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_ind
					WHERE
						app_sid = SYS_CONTEXT('SECURITY', 'APP')
					AND	approval_step_id = approval_step_summary.approval_step_id
					AND	pending_ind_id = approval_step_val.pending_ind_id
				)
		)
	;

	DELETE FROM
		approval_step_hierarchy
	;
	
	DELETE FROM
		approval_step_val
	;

	INSERT INTO
		approval_step_hierarchy -- All the ancestor steps of each approval step we're gathering stats for.
	(
		ancestor_step_id
	,	approval_step_id
	)
	SELECT 
		CONNECT_BY_ROOT approval_step_id
	,	approval_step_id
	FROM
		approval_step
	WHERE
		app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND	LEVEL > 1
	START WITH
		approval_step_id
	IN
		(
			SELECT
				approval_step_id
			FROM
				approval_step_stats
		)
	CONNECT BY
		approval_step_id = PRIOR parent_step_id
	AND	app_sid = PRIOR app_sid
	;
	
	INSERT INTO
		approval_step_val
	(
		approval_step_id
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	)
	SELECT
		approval_step_id
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	FROM
		pending_val
	WHERE
		pending_val.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	AND	(
			-- The value is assigned to an ancestor approval step.
			EXISTS
			(
				SELECT
					*
				FROM
					approval_step_hierarchy
				WHERE
					approval_step_id = pending_val.approval_step_id
			)
			-- The value is assigned to a root approval step and has been merged with the main database.
		OR	EXISTS
			(
				SELECT
					*
				FROM
					approval_step_summary
				WHERE
					approval_step_id = pending_val.approval_step_id
				AND	parent_step_id IS NULL
				AND	pending_val.merged_state = 'S'
			)
		)
	AND	pending_val.pending_period_id IN
		(
			SELECT
				pending_period_id
			FROM
				approval_step_summary
			UNION SELECT
				pending_period_id
			FROM
				pending_period
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_dataset_id = v_pending_dataset_id
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_summary
					WHERE
						pending_period_id IS NULL
				)
		)
	AND	EXISTS
		(
			SELECT
				*
			FROM
				pending_region_descendants
			WHERE
				pending_region_id = pending_val.pending_region_id
		)
	AND	EXISTS
		(
			SELECT
				*
			FROM
				approval_step_ind
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_ind_id = pending_val.pending_ind_id
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_stats -- An indicator can't appear halfway down the approval step hierarchy: if it's in any approval step, it'll be in the root approval steps.
					WHERE
						approval_step_id = approval_step_ind.approval_step_id
				)
			AND	EXISTS
				(
					SELECT
						*
					FROM
						pending_entry_ind
					WHERE
						pending_ind_id = pending_val.pending_ind_id
				)
		)
	;
	
	INSERT INTO
		approval_step_hierarchy -- Add the current approval_steps to the ancestor steps of each approval step we're gathering stats for so that we can count merged-with-main values.
	(
		ancestor_step_id
	,	approval_step_id
	)
	SELECT
		approval_step_id
	,	approval_step_id
	FROM
		approval_step_stats
	;
	
	UPDATE
		approval_step_summary
	SET
		submitted_val_count = 
		(
			-- Note: If regions are split, you might get a step that has, say, 2 indicators assigned to it in total but where 2 values are submitted and 2 values are delegated.
			-- ((2 + 2 = 4) > 2). This is okay: it means that only some of the split regions have been submitted to you and that you have submitted these on yourself. (So you've
			-- submitted 2 indicators - but only for some of the split regions - and you're still waiting on the same 2 indicators from the rest of the split regions.)
			SELECT
				COUNT(DISTINCT pending_ind_id)
			FROM
				approval_step_val
			WHERE
				EXISTS
				(
					SELECT
						*
					FROM
						approval_step_hierarchy
					WHERE
						ancestor_step_id = approval_step_summary.approval_step_id
					AND	approval_step_id = approval_step_val.approval_step_id
				)
			AND	EXISTS
				(
					SELECT
						*
					FROM
						pending_region_descendants
					WHERE
						ancestor_region_id = approval_step_summary.pending_region_id
					AND	pending_region_id = approval_step_val.pending_region_id
				)
			AND	pending_period_id = approval_step_summary.pending_period_id
			AND	EXISTS
				(
					SELECT
						*
					FROM
						approval_step_ind
					WHERE
						app_sid = SYS_CONTEXT('SECURITY', 'APP')
					AND	approval_step_id = approval_step_summary.approval_step_id
					AND	pending_ind_id = approval_step_val.pending_ind_id
				)
		)
	;
	
	OPEN
		out_cur_summary
	FOR	SELECT
		approval_step_id
	,	parent_step_id
	,	sheet_key
	,	pending_period_id
	,	pending_region_id
	,	pending_ind_id
	,	sheet_label
	,	(
			SELECT
				label
			FROM
				approval_step
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	approval_step_id = approval_step_summary.approval_step_id
		) step_label
	,	(
			SELECT
				description
			FROM
				pending_region
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_region_id = approval_step_summary.pending_region_id
		) region_label
	,	(
			SELECT
				label
			FROM
				pending_period
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_period_id = approval_step_summary.pending_period_id
		) period_label
	,	(
			SELECT
				start_dtm
			FROM
				pending_period
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			AND	pending_period_id = approval_step_summary.pending_period_id
		) period_start_dtm
	,	due_dtm
	,	approver_response_due_dtm
	,	max_ind_count * max_region_count * max_period_count max_val_count
	,	delegated_val_count
	,	submitted_val_count
	FROM
		approval_step_summary
	;
	
	OPEN
		out_cur_users
	FOR	SELECT
		step.approval_step_id
	,	step.parent_step_id
	,	csr_user.csr_user_sid
	,	CASE csr_user.csr_user_sid WHEN v_user_sid THEN 1 ELSE 0 END is_current_user
	,	csr_user.full_name
	FROM
		(
			SELECT DISTINCT
				app_sid
			,	approval_step_id
			,	parent_step_id
			FROM
				approval_step
			WHERE
				app_sid = SYS_CONTEXT('SECURITY', 'APP')
			START WITH
				approval_step_id IN
				(
					SELECT
						approval_step_id
					FROM
						approval_step_user
					WHERE
						user_sid = v_user_sid
				)
			AND	pending_dataset_id = v_pending_dataset_id
			CONNECT BY
				level = 2
			AND	(
					PRIOR parent_step_id = approval_step_id
				OR	parent_step_id = PRIOR approval_step_id
				)
		) step
	JOIN
		approval_step_user
	ON
		approval_step_user.approval_step_id = step.approval_step_id
	AND	approval_step_user.app_sid = step.app_sid
	JOIN
		csr_user
	ON
		csr_user.csr_user_sid = approval_step_user.user_sid
	AND	csr_user.app_sid = approval_step_user.app_sid
	;
END;

-- hardwired for specific layout (i.e. single region, single period)
-- Consider switching to something based on the sheet_key? like:
/*
SELECT apss_ch.*
  FROM approval_step_sheet apss, approval_step aps, approval_step aps_ch, approval_step_sheet apss_ch
 WHERE apss.approval_step_id = 2500
   AND apss.sheet_key = '9621_186'
   AND apss.approval_step_id = aps.approval_step_id
   AND aps.approval_step_id = aps_ch.parent_step_id 
   AND aps_ch.approval_step_Id = apss_ch.approval_step_id
   */
PROCEDURE GetRejectableApprovalSheets(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_parent_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_region_Id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_Id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: how do we check that we can actually reject these, i.e.
	-- there must also be values for the values in this step at our level
	OPEN out_cur FOR
		SELECT apss.approval_step_id, sheet_key, apss.label, apss.pending_ind_id, apss.pending_region_id, apss.pending_period_id,
            apss.submitted_value_count, apss.submit_blocked, max_sheet_value_count, due_dtm, NVL(pr.maps_to_region_sid, 0) maps_to_region_sid
--            case when apss.submitted_value_count >= max_sheet_value_count then 1 else 0 end fully_submitted
		  FROM approval_step_sheet apss
		  JOIN approval_step aps ON aps.approval_step_id = apss.approval_step_id AND aps.app_sid = apss.app_sid
		  LEFT JOIN pending_region pr ON pr.pending_region_id = apss.pending_region_id AND pr.app_sid = apss.app_sid
		 WHERE aps.parent_step_id = in_parent_Step_Id
		   AND apss.pending_period_id = in_pending_period_id
--		   AND apss.submitted_value_count > 0
		   AND apss.pending_region_id IN (
				SELECT pending_region_id
			      FROM pending_region
			     START WITH pending_region_id = in_pending_region_id
			   CONNECT BY PRIOR pending_region_id = parent_region_id
			)		 
		ORDER BY label;
END;

PROCEDURE GetSheet(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    	IN	approval_step_sheet.sheet_key%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT apss.approval_step_id, sheet_key, apss.label, apss.pending_ind_id, apss.pending_region_id, apss.pending_period_id,
            apss.submitted_value_count, apss.submit_blocked, max_sheet_value_count, NVL(pr.maps_to_region_sid, 0) maps_to_region_sid
--            case when apss.submitted_value_count >= max_sheet_value_count then 1 else 0 end fully_submitted
		  FROM approval_step_sheet apss
		  JOIN approval_step aps ON aps.approval_step_id = apss.approval_step_id AND aps.app_sid = apss.app_sid
		  LEFT JOIN pending_region pr ON pr.pending_region_id = apss.pending_region_id AND pr.app_sid = apss.app_sid
		 WHERE apss.approval_step_id = in_approval_step_id 
		   AND apss.sheet_key = NVL(in_sheet_key, apss.sheet_key);
END;

PROCEDURE GetSheetLog(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    	IN	approval_step_sheet.sheet_key%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR        
        SELECT approval_step_id, sheet_key, dtm, by_user_sid, cu.full_name, cu.email, up_or_down, note
          FROM approval_step_sheet_log apssl, csr_user cu
         WHERE apssl.by_user_sid = cu.csr_user_sid
           AND approval_step_id = in_approval_step_id
           AND sheet_key = in_sheet_key
         ORDER BY dtm DESC;
END;


PROCEDURE GetSheetLogInclChildren(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id 	IN	approval_step.approval_step_id%TYPE,
	in_sheet_key    		IN	approval_step_sheet.sheet_key%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT apssl.approval_step_id, apssl.sheet_key, apss.label, apssl.dtm, apssl.by_user_sid, cu.full_name, cu.email, apssl.up_or_down, apssl.note
		  FROM approval_step_sheet apss, approval_step_sheet_log apssl, csr_user cu
		 WHERE apss.approval_step_id = in_approval_step_id
		   AND apss.sheet_key = in_sheet_key
		AND apss.approval_step_id = apssl.approval_step_id
		   AND apss.sheet_key = apssl.sheet_key
		   AND apssl.by_user_sid = cu.csr_user_sid
		 UNION ALL
		SELECT apssl.approval_step_id, apssl.sheet_key, apss_ch.label, apssl.dtm, apssl.by_user_sid, cu.full_name, cu.email, apssl.up_or_down, apssl.note
		  FROM approval_step_sheet apss, approval_step aps, approval_step aps_ch, approval_step_sheet apss_ch,
			approval_step_sheet_log apssl, csr_user cu
		 WHERE apss.approval_step_id = in_approval_step_id
		   AND apss.sheet_key = in_sheet_key
		   AND apss.approval_step_id = aps.approval_step_id
		   AND aps.approval_step_id = aps_ch.parent_step_id 
		   AND aps_ch.approval_step_Id = apss_ch.approval_step_id
		   AND apss_ch.pending_region_id  = in_pending_region_id
		   -- I think it makes sense NOT to show all child regions on child forms as it's confusing
		   /*IN (
				SELECT pending_region_id
				  FROM pending_region
				 START WITH pending_region_id = in_pending_region_id
			   CONNECT BY PRIOR pending_region_id = parent_region_id
			)*/		 
		   AND apss_ch.pending_period_id = in_pending_period_id
		   AND apss_ch.approval_step_id = apssl.approval_step_Id
		   AND apss_ch.sheet_key = apssl.sheet_key
		   AND apssl.by_user_sid = cu.csr_user_sid
		 ORDER BY label, dtm DESC;
END;

-- deprecated, use aspen2.utils_pkg instead
FUNCTION SubtractWorkingDays(
	in_date		IN	DATE,
	in_days		IN	NUMBER
) RETURN DATE
AS
	v_result	DATE;
BEGIN
	IF in_days < 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Days must be greater than or equal to zero');
	ELSIF in_days = 0 THEN
		RETURN in_date;
	END IF;
	SELECT in_date-MAX(i) INTO v_result
	  FROM (
		SELECT i, ROWNUM rn
		  FROM (SELECT LEVEL i FROM dual CONNECT BY LEVEL BETWEEN 1 AND (in_days+1)*2) -- multply by two to guarantee some leeway
		 WHERE TO_CHAR(in_date-i,'Dy') NOT IN ('Sat', 'Sun')
	     )
	 WHERE rn = in_days;
	RETURN v_result;
END;

-- deprecated, use aspen2.utils_pkg instead
FUNCTION AddWorkingDays(
	in_date		IN	DATE,
	in_days		IN	NUMBER
) RETURN DATE
AS
	v_result	DATE;
BEGIN
	IF in_days < 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Days must be greater than or equal to zero');
	ELSIF in_days = 0 THEN
		RETURN in_date;
	END IF;
	SELECT in_date+MAX(i) INTO v_result
	  FROM (
		SELECT i, ROWNUM rn
		  FROM (SELECT LEVEL i FROM dual CONNECT BY LEVEL BETWEEN 1 AND (in_days+1)*2) -- multply by two to guarantee some leeway
		 WHERE TO_CHAR(in_date+i,'Dy') NOT IN ('Sat', 'Sun')
	     )
	 WHERE rn = in_days;
	RETURN v_result;
END;

PROCEDURE GetApprovalStepPeriods(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	SELECT pending_dataset_Id
	  INTO v_pending_dataset_id
	  FROM approval_step 
	 WHERE approval_step_id = in_approval_step_id;
	GetPeriods(in_act_id, v_pending_dataset_id, out_cur);
END;

PROCEDURE GetApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT apsu.approval_step_id, apsu.read_only,
			   cu.csr_user_sid, cu.full_name, cu.email, cu.friendly_name, cu.user_name, ut.account_enabled active,
			   cuf.csr_user_sid fallback_user_sid, cuf.full_name fallback_full_name, cuf.email fallback_email, cu.enable_aria
		  FROM approval_step_user apsu, csr_user cu, csr_user cuf, security.user_table ut
		 WHERE apsu.approval_step_id = in_approval_step_id
		   AND apsu.user_sid = cu.csr_user_sid
		   AND ut.sid_id = cu.csr_user_sid
		   AND is_lurker = 0
		   AND apsu.fallback_user_sid = cuf.csr_user_sid(+);
END;

PROCEDURE GetApprovalStepRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pr.pending_region_id, maps_to_region_sid, description, parent_region_id, pos
		  FROM approval_step_region apsr, pending_region pr
		 WHERE apsr.pending_region_id = pr.pending_region_id
		   AND apsr.approval_step_id = in_approval_step_id;
END;


PROCEDURE GetRootApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	IN	pending_dataset.pending_Dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
/*
    OPEN out_cur FOR
        SELECT approval_step.*,  pending_ind.PENDING_IND_ID as TOP_LEVEL_PENDING_IND
          FROM approval_step, approval_step_ind, pending_ind
         WHERE approval_step.parent_step_id is null and approval_step.pending_dataset_id = in_pending_dataset_id and
               approval_step_ind.approval_step_id = approval_step.APPROVAL_STEP_ID and
               pending_ind.PENDING_IND_ID = approval_step_ind.PENDING_IND_ID and
               pending_ind.PARENT_IND_ID is null;
               */
               
    OPEN out_cur FOR
		SELECT approval_step_id, parent_step_id, pending_dataset_id, based_on_step_id, label, layout_type, max_sheet_value_count,
		       working_day_offset_from_due, app_sid
		  FROM approval_step
		 WHERE parent_step_id IS NULL
		   AND pending_dataset_id = in_pending_dataset_id;
END;


PROCEDURE INTERNAL_DeleteAppStepSheet(
	in_approval_step_id	IN	approval_step_sheet.approval_step_id%TYPE,
	in_sheet_key		IN	approval_step_sheet.sheet_key%TYPE
)
AS
BEGIN
	DELETE FROM approval_step_sheet_log
	 WHERE approval_step_Id = in_approval_step_id
	   AND sheet_key = in_sheet_key;
	DELETE FROM approval_step_sheet_alert
	 WHERE approval_step_Id = in_approval_step_id
	   AND sheet_key = in_sheet_key;	   
	DELETE FROM approval_step_sheet
	 WHERE approval_step_Id = in_approval_step_id
	   AND sheet_key = in_sheet_key;
END;

--TODO: must update submitted...
PROCEDURE TakeControlOfValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_ids		IN	T_PENDING_IND_IDS,
	in_region_id			IN	pending_val.pending_region_id%TYPE,
	in_period_id			IN	pending_val.pending_period_id%TYPE
)
AS
	v_count	NUMBER(10);
	v_pending_val_id	pending_val.pending_val_id%TYPE;
	v_approval_step_id	pending_val.approval_step_id%TYPE;
BEGIN
	-- crap hack for ODP.NET
    IF in_pending_ind_ids IS NULL OR (in_pending_ind_ids.COUNT = 1 AND in_pending_ind_ids(1) IS NULL) THEN
        RETURN;
    END IF;	 
    
    FOR i IN in_pending_ind_ids.FIRST..in_pending_ind_ids.LAST
	LOOP 
		-- TODO: what if this doesn't exist?
		-- TBH, there's no point taking control if it doesn't exist?
		BEGIN
			SELECT pending_val_id, approval_step_id 
			  INTO v_pending_val_id, v_approval_step_id
			  FROM pending_val 
			 WHERE pending_ind_id = in_pending_ind_ids(i) 
			   AND pending_region_id = in_region_id
			   AND pending_period_id = in_period_id
			   FOR UPDATE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_pending_val_id := null;
				v_approval_step_id := null;
				null; -- this is probably because they've taken control of a value that's used in a calculation, so it's trying to take control of the calculation too, and there's no value
		END;

		IF v_pending_val_id IS NOT NULL THEN
			-- check that our approval_step_id is above the one in the db
			SELECT COUNT(*)  
			  INTO v_count
			  FROM (
				SELECT approval_step_Id
				  FROM approval_step
				 START WITH approval_step_id = v_approval_step_Id
				CONNECT BY PRIOR parent_step_Id = approval_step_id
			 )
			WHERE approval_step_id = in_approval_step_id;
			
			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(-20001, 'Approval step '+in_approval_step_id+' is not a parent approval step');
			END IF; 
			
			
			AddToPendingValLog(in_act_id, v_pending_val_id, 'Took control of value');
			
			UPDATE pending_val 
			   SET approval_step_id = in_approval_Step_id
			 WHERE pending_val_id = v_pending_val_id;
		END IF;
	END LOOP;
END;

PROCEDURE GetApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	
	OPEN out_cur FOR
		SELECT approval_step_id, label, based_on_step_id, pending_dataset_id, parent_step_id, layout_type, working_day_offset_from_due
		  FROM approval_step
		 WHERE approval_step_id = in_approval_step_id;
END;

PROCEDURE GetApprovalStepMaintenanceData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT approval_step_id, (SELECT COUNT(*) FROM pending_val WHERE approval_step_id = approval_step.approval_step_id AND (val_number IS NOT NULL OR val_string IS NOT NULL)) pending_val_count,
			   (SELECT COUNT(*) FROM approval_step_sheet_log WHERE approval_step_id = approval_step.approval_step_id) sheet_log_count
		  FROM approval_step
		 WHERE approval_step.approval_step_id = in_approval_step_id;
END;

PROCEDURE GetAncestorApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		 SELECT approval_step_id, LABEL, based_on_step_id, pending_dataset_id, parent_step_id, layout_type, working_day_offset_from_due
		   FROM approval_step
		  WHERE level > 1
		  START WITH approval_step_id = in_approval_step_id
		CONNECT BY PRIOR parent_step_id = approval_step_id;
END;

PROCEDURE GetChildApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_aps					OUT	SYS_REFCURSOR,
	out_regions				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_aps FOR
		 SELECT approval_step_id, LABEL, based_on_step_id, pending_dataset_id, parent_step_id, layout_type, working_day_offset_from_due
		   FROM approval_step
		  WHERE parent_step_id = in_approval_step_id
		  ORDER BY label;
	OPEN out_regions FOR
		 SELECT apsr.approval_step_id, pending_region_id
		   FROM approval_step_region apsr, approval_step aps
		  WHERE apsr.approval_step_id = aps.approval_step_id
		    AND aps.parent_step_id = in_approval_step_id
		  ORDER BY apsr.approval_Step_id;
END;

PROCEDURE GetDescendantApprovalSteps(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_Step_id 	IN	security_pkg.T_SID_ID,
	out_aps					OUT	SYS_REFCURSOR,
	out_regions				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_aps FOR
		 SELECT approval_step_id, LABEL, based_on_step_id, pending_dataset_id, parent_step_id, layout_type, working_day_offset_from_due, level lvl
		   FROM approval_step
		   START WITH  parent_step_id = in_approval_step_id
		 CONNECT BY PRIOR approval_step_id = parent_step_id;
		 
	OPEN out_regions FOR
		 SELECT approval_step_id, pending_region_id
		   FROM approval_step_region 
		  WHERE approval_step_id IN (
		  	 SELECT approval_step_id
			   FROM approval_step
			  START WITH parent_step_id = in_approval_step_id
			CONNECT BY PRIOR approval_step_id = parent_step_id
		  )
		 ORDER BY approval_Step_id;
END;

PROCEDURE INTERNAL_DeleteVal(
	in_pending_val_id		IN	pending_val.pending_Val_id%TYPE
) 
AS
	v_region_Id	pending_val.pending_region_Id%TYPE;
	v_ind_Id	pending_val.pending_ind_Id%TYPE;
	v_period_Id	pending_val.pending_period_Id%TYPE;
BEGIN
	SELECT pending_ind_id, pending_region_id, pending_period_Id
	  INTO v_ind_id, v_region_id, v_period_Id
	  FROM pending_val
	 WHERE pending_val_id = in_pending_val_id;
	 
	-- clean out issue (leaves actual issue data)
	DELETE FROM issue_pending_Val 
	 WHERE pending_ind_id = v_ind_id
	   AND pending_region_id = v_region_id
	   AND pending_period_id = v_period_id;

	DELETE FROM pending_val_variance WHERE pending_val_id = in_pending_val_id;
	DELETE FROM pending_val_file_upload WHERE pending_val_id = in_pending_val_id;
	DELETE FROM pending_val_log WHERE pending_val_id = in_pending_val_id;
	DELETE FROM pending_val_accuracy_type_opt WHERE pending_val_id = in_pending_val_id;
	DELETE FROM pending_val WHERE pending_val_id = in_pending_val_id;
END;


-- TODO: this ought to check to see if the approval_step references pending_regions / inds
-- that aren't used elsewhere. If so, then it ought to delete the values or auto-aggregate
-- them or something.
PROCEDURE INTERNAL_DeleteApprovalStep(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
)
AS
	v_val_count	NUMBER(10);
BEGIN
	-- is this approval step being used by a pending value?
	SELECT COUNT(*) 
	  INTO v_val_count
	  FROM pending_val
	 WHERE (val_string IS NOT NULL OR val_number IS NOT NULL)
		   AND approval_step_id IN (
		 SELECT approval_step_id 
		  FROM approval_step
		 START WITH approval_step_id = in_approval_step_id
		CONNECT BY PRIOR approval_step_id = parent_step_id
	  	);
	 
	 IF v_val_count > 0 THEN
	 	RAISE_APPLICATION_ERROR(-20001, 'Cannot delete approval step as it (or a child step) is in use by '||v_val_count||' values');
	 END IF;
		
	-- loop through child steps (from bottom up)
	FOR r IN (
		 SELECT approval_step_id 
		  FROM APPROVAL_STEP
		 START WITH approval_step_id = in_approval_step_id
		CONNECT BY PRIOR approval_step_id = parent_step_id
		  ORDER BY LEVEL DESC
		)
	LOOP
		DELETE FROM pending_val_log
	 	 WHERE pending_val_id IN (SELECT pending_val_id FROM pending_val WHERE approval_step_id = r.approval_step_id AND val_number IS NULL and val_string IS NULL);
		DELETE FROM pending_val
	 	 WHERE approval_step_id = r.approval_step_id AND val_number IS NULL and val_string IS NULL;
		DELETE FROM approval_step_ind
	 	 WHERE approval_step_id = r.approval_step_id;
		DELETE FROM approval_step_region
	 	 WHERE approval_step_id = r.approval_step_id;
		DELETE FROM approval_step_user
 	 	 WHERE approval_step_id = r.approval_step_id;
		DELETE FROM approval_step_sheet_log
 	 	 WHERE approval_step_id = r.approval_step_id;
 	 	DELETE FROM approval_step_model
 	 	 WHERE approval_step_id = r.approval_step_id;
 	 	FOR rs IN (
 	 		SELECT approval_step_id, sheet_key 
 	 		  FROM approval_step_sheet
 	 		 WHERE approval_step_id = r.approval_step_id
 		)
 		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
 	 	END LOOP;
		DELETE FROM approval_step
 	 	 WHERE approval_step_id = r.approval_step_id;
 	END LOOP;
END;


-- PRIVATE function
PROCEDURE RemoveEmptyApprovalSteps(
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE
)
AS
BEGIN
	-- first of all check regions
	FOR r IN (
		SELECT approval_step_id 
		  FROM APPROVAL_STEP
		 WHERE pending_dataset_id = in_pending_dataset_id
		 MINUS
		SELECT DISTINCT aps.approval_step_id
		  FROM APPROVAL_STEP_REGION apsr, APPROVAL_STEP aps
		 WHERE apsr.approval_step_id = aps.approval_step_id
		   AND pending_dataset_id = in_pending_dataset_id
	)
	LOOP
		INTERNAL_DeleteApprovalStep(r.approval_step_id);
	END LOOP;
	
	-- now check indicators
	FOR r IN (
		SELECT approval_step_id 
		  FROM APPROVAL_STEP
		 WHERE pending_dataset_id = in_pending_dataset_id
		 MINUS
		SELECT DISTINCT aps.approval_step_id
		  FROM APPROVAL_STEP_IND apsi, APPROVAL_STEP aps
		 WHERE apsi.approval_step_id = aps.approval_step_id
		   AND pending_dataset_id = in_pending_dataset_id
	)
	LOOP
		INTERNAL_DeleteApprovalStep(r.approval_step_id);
	END LOOP;
END;

PROCEDURE DeleteApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
)
AS
	v_description approval_step.label%TYPE;
BEGIN
	SELECT label INTO v_description FROM approval_step WHERE approval_step_id = in_approval_step_id;
	
	INTERNAL_DeleteApprovalStep(in_approval_step_id);
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_approval_step_id, 'Deleted approval step "{0}"', v_description);
END;

PROCEDURE DeleteAllApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
)
AS
BEGIN
	DELETE FROM approval_step_sheet_alert
	 WHERE approval_step_id = in_approval_step_id;

	DELETE FROM approval_step_user
 	 WHERE approval_step_id = in_approval_step_id;
END;

PROCEDURE DeleteApprovalStepUser(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_user_sid             IN  approval_step_user.user_sid%TYPE
)
AS
	v_user csr_user.full_name%TYPE;
	v_step approval_step.label%TYPE;
BEGIN
	SELECT full_name INTO v_user FROM csr_user WHERE csr_user_sid = in_user_sid;
	SELECT label INTO v_step FROM approval_step WHERE approval_step_id = in_approval_step_id;
	
	DELETE FROM approval_step_user
	 WHERE approval_step_id = in_approval_step_id
	   AND user_sid = in_user_sid;

	DELETE FROM approval_step_sheet_alert
	 WHERE approval_step_id = in_approval_step_id
	   AND user_sid = in_user_sid;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_approval_step_id, 'Removed {0} from approval step "{1}"', v_user, v_step, NULL, in_user_sid);
END;

PROCEDURE AddApprovalStepUsers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_user_sids            IN  security_pkg.T_SID_IDS
)
AS
	v_user 				csr_user.full_name%TYPE;
	v_step 				approval_step.label%TYPE;
BEGIN
	FORALL i IN in_user_sids.FIRST..in_user_sids.LAST
		INSERT INTO approval_step_user
		(
			approval_step_id,
			user_sid,
			read_only
		)
		VALUES
		(
			in_approval_step_id,
			in_user_sids(i),
			0
		);
			   	
	FORALL i IN in_user_sids.FIRST..in_user_sids.LAST
		INSERT INTO approval_step_sheet_alert (approval_step_id, sheet_key, user_sid, reminder_sent_dtm, overdue_sent_dtm)
			SELECT approval_step_id, sheet_key, in_user_sids(i), 
				   CASE WHEN reminder_dtm <= SYSDATE THEN NULL ELSE reminder_dtm END,
				   CASE WHEN due_dtm <= SYSDATE THEN NULL ELSE due_dtm END
			  FROM approval_step_sheet
			 WHERE approval_step_id = in_approval_step_id;

	FOR i IN in_user_sids.FIRST..in_user_sids.LAST LOOP
		SELECT full_name 
		  INTO v_user 
		  FROM csr_user 
		 WHERE csr_user_sid = in_user_sids(i);
		
		SELECT label 
		  INTO v_step 
		  FROM approval_step 
		 WHERE approval_step_id = in_approval_step_id;
		
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_approval_step_id, 'Added {0} to approval step "{1}"', v_user, v_step, NULL, in_user_sids(i));
	END LOOP;		
EXCEPTION
	WHEN dup_val_on_index THEN
		RAISE_APPLICATION_ERROR(ERR_DUPLICATE_STEP_USER, 'approval_step_id = ' || in_approval_step_id || ', user_sid = ' ||in_user_sids(SQL%BULK_EXCEPTIONS(1).ERROR_INDEX));
END;

-- internal
PROCEDURE CreateApprovalStepSheet(
	in_approval_step_id			IN	approval_step_sheet.approval_step_id%TYPE,
	in_sheet_key				IN	approval_step_sheet.sheet_key%TYPE,
	in_label					IN	approval_step_sheet.label%TYPE,
	in_pending_ind_id			IN	approval_step_sheet.pending_ind_id%TYPE,
	in_pending_region_id		IN	approval_step_sheet.pending_region_id%TYPE,
	in_pending_period_id		IN	approval_step_sheet.pending_period_id%TYPE,
	in_due_dtm					IN	approval_step_sheet.due_dtm%TYPE
)
AS
	v_working_day_offset_from_due	approval_step.WORKING_DAY_OFFSET_FROM_DUE%TYPE;
BEGIN			
	SELECT working_day_offset_from_due	
	  INTO v_working_day_offset_from_due	
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;
	 
    INSERT INTO approval_step_sheet
        (approval_step_id, sheet_key, label, pending_ind_id, 
         pending_region_id, pending_period_id, due_dtm, reminder_dtm)
	VALUES
		(in_approval_step_id, in_sheet_key, in_label, in_pending_ind_id,
		 in_pending_region_id, in_pending_period_id, in_due_dtm, pending_pkg.SubtractWorkingDays(in_DUE_DTM, v_working_day_offset_from_Due));

	-- Fill the sheet out with either empty values, or values stolen from the parent approval step
	-- This makes it obvious when you are filling out a sheet at the mid level that the data
	-- should actually be entered at a lower level (i.e. you have to explicitly take control of
	-- values rather than being allowed to fill them out at any higher level if nothing has 
	-- actually been entered at the lower level yet).
	approval_step_range_pkg.InitWithKey(SYS_CONTEXT('SECURITY', 'ACT'), in_approval_step_id,
		in_sheet_key);
	approval_step_range_pkg.FillSheetFromParent;
END;

PROCEDURE INTERNAL_AddApprovalStep(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	    IN	approval_step.approval_step_id%TYPE,
	in_pending_dataset_id		    IN  pending_dataset.pending_Dataset_id%TYPE, -- nullable (get from parent approval step)
    in_new_label				    IN	approval_step.label%TYPE,
    in_working_day_Offset_from_due  IN	approval_step.working_day_Offset_from_due%TYPE,
    in_ind_ids		    	        IN	security_pkg.T_SID_IDS, -- nullable all inds of parent
    in_region_ids   	    	    IN	T_PENDING_REGION_IDS, -- nullable all regions
    in_user_sids                    IN  security_pkg.T_SID_IDS,
    in_layout_type				    IN	approval_step.layout_type%TYPE,
	out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
)
AS
    v_cnt						NUMBER(10);
    v_due_dtm					DATE;
    t_ind_sids 					security.T_SID_TABLE;
    v_pending_dataset_id		pending_dataset.pending_dataset_id%TYPE;
BEGIN
    v_pending_dataset_id := in_pending_dataset_id;
    IF v_pending_dataset_id IS NULL THEN
	   	SELECT pending_dataset_id
	   	  INTO v_pending_dataset_id
	   	  FROM approval_step
	   	 WHERE approval_step_id = in_parent_approval_step_id;
	END IF;

	out_new_approval_step_id := CreateApprovalStepSID(NVL(in_parent_approval_step_id, v_pending_dataset_id));
    
    -- insert child approval step
	INSERT INTO APPROVAL_STEP 
		(APPROVAL_STEP_ID, PARENT_STEP_ID, LABEL, BASED_ON_STEP_ID, 
         PENDING_DATASET_ID, LAYOUT_TYPE, MAX_SHEET_VALUE_COUNT, working_day_Offset_from_due)
	VALUES
		(out_new_approval_step_id, in_parent_approval_step_id, in_new_label, NULL,
		 v_pending_dataset_id, in_layout_type, 0, in_working_day_Offset_from_due);

		 		 
	-- insert users
    FORALL i IN in_user_sids.FIRST..in_user_sids.LAST
        INSERT INTO APPROVAL_STEP_USER
            (APPROVAL_STEP_ID, USER_SID, READ_ONLY)
        VALUES
            (out_new_approval_step_id, in_user_sids(i), 0);	 		 

    -- copy inds (optionally do just one and children)
    -- we MUST do this before regions, because regions does some checking
    -- that involves our indicators being inserted
    IF in_ind_ids IS NULL THEN
        -- if no ind ids passed in then...
    	IF in_parent_approval_step_id IS NOT NULL THEN
            -- do all indicators in parent step
		    INSERT INTO APPROVAL_STEP_IND
		    	(APPROVAL_STEP_ID, PENDING_IND_ID)
		    	SELECT out_new_approval_step_id, pending_ind_id
		          FROM APPROVAL_STEP_IND
		         WHERE approval_step_id = in_parent_approval_step_id;
		ELSE
			-- or all indicators in dataset
			-- umm - not for now - this is really irritating when adding new approval root steps
		    /*INSERT INTO APPROVAL_STEP_IND
		    	(APPROVAL_STEP_ID, PENDING_IND_ID)
		    	SELECT out_new_approval_step_id, pending_ind_id
		          FROM PENDING_IND
		         WHERE pending_Dataset_Id = v_pending_dataset_id;*/
		    null;
		END IF;
	ELSE
	    IF in_parent_approval_step_id IS NOT NULL THEN
            -- TODO: check specified indicators appear in parent?
            NULL;
        END IF;
        
        t_ind_sids := security_pkg.SidArrayToTable(in_ind_ids);        
		INSERT INTO APPROVAL_STEP_IND
			(APPROVAL_STEP_ID, PENDING_IND_ID)
			SELECT DISTINCT out_new_approval_step_id, pending_ind_id
			  FROM pending_ind 
			 START WITH pending_ind_id IN (
				SELECT column_value FROM TABLE(t_ind_sids)
			)
			CONNECT BY prior parent_ind_id = pending_ind_Id;

	END IF;

		 		 
    -- copy regions
    IF in_region_ids IS NULL THEN
        -- if no region ids passed
       	IF in_parent_approval_step_id IS NOT NULL THEN
       		-- those from parent
		    INSERT INTO APPROVAL_STEP_REGION
		    	(APPROVAL_STEP_ID, PENDING_REGION_ID, ROLLS_UP_TO_REGION_ID)
		    	SELECT out_new_approval_step_id, pending_region_id, pending_region_id
		          FROM APPROVAL_STEP_REGION
		         WHERE approval_step_id = in_parent_approval_step_id;
		ELSE
            -- all regions in pending_Dataset 
			INSERT INTO APPROVAL_STEP_REGION
		    	(APPROVAL_STEP_ID, PENDING_REGION_ID, ROLLS_UP_TO_REGION_ID)
		    	SELECT out_new_approval_step_id, pending_region_id, pending_region_id
		    	  FROM pending_region
		    	 WHERE pending_dataset_id = v_pending_dataset_id;
		END IF;
	ELSE
        FORALL i IN in_region_ids.FIRST..in_region_ids.LAST
            INSERT INTO APPROVAL_STEP_REGION 
                (APPROVAL_STEP_ID, PENDING_REGION_ID, ROLLS_UP_TO_REGION_ID)
            VALUES
                (out_new_approval_step_id, in_region_ids(i), in_region_ids(i));
                
	    IF in_parent_approval_step_id IS NOT NULL THEN
            -- do we need to subdivide?  
            -- * check inserted regions actually belong to regions in parent_step
            -- * check there are no values for the regions in the parent_step
            -- * update the rolls_up_to_region_id
            FOR r IN (
                 SELECT apsr.pending_region_Id, p.root_pending_region_Id, count(pv.pending_val_Id) val_count
                   FROM approval_step_region apsr, (
                       -- all regions that are the same, or below the regions of our parent approval_step 
                       SELECT pending_region_Id, connect_by_root pending_region_id root_pending_region_id
                         FROM pending_region
                        START WITH pending_region_id IN ( 
                           SELECT pending_region_id
                             FROM approval_step_region
                            WHERE approval_step_id = in_parent_approval_step_id
                       )
                      CONNECT BY PRIOR pending_region_id = parent_region_id
                  )p, approval_step_ind apsi, (
                    -- all values for indicators in our approval step
                    SELECT pending_val_id, pending_region_id
                      FROM pending_val, approval_step_ind apsi
                     WHERE pending_val.pending_ind_Id = apsi.pending_ind_id
                       AND apsi.approval_step_Id = out_new_approval_step_id
                      /* AND val_number IS NOT NULL
                       AND val_string IS NOT NULL -- XXX: what about files? should we clean up these values?*/
                  )pv
                 WHERE apsr.approval_Step_Id = out_new_approval_step_id
                   AND p.root_pending_region_Id = pv.pending_region_Id(+)
                   AND apsr.pending_region_id = p.pending_region_id(+)
                 GROUP BY apsr.pending_region_id, p.root_pending_region_Id
            )
            LOOP
                IF r.root_pending_region_id IS NULL THEN
                    -- boom! pending_region_id is not in the parent step
                    RAISE_APPLICATION_ERROR(-20001, 'Region '||r.pending_region_id||' is not a child of any region in approval step '||in_parent_approval_step_id);                
                ELSIF r.pending_region_Id != r.root_pending_region_id THEN
                    -- regions differ - check for values
                    IF r.val_count > 0 THEN
						-- boom! values exist so we cannot subdivide
						RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CANNOT_SUBDIVIDE_REGION, 'Cannot subdivide region id '||r.root_pending_region_id||' in approval step ('||in_parent_approval_step_id||') because values already exist for indicators present at this step');
					END IF;
                    -- set rollup correctly
                    UPDATE APPROVAL_STEP_REGION
                       SET rolls_up_to_region_id = r.root_pending_region_id
                     WHERE approval_Step_Id = out_new_approval_Step_id
                       AND pending_region_id = r.pending_region_id;
                    -- XXX -- we need values here - update region_sid? delete/reinsert?
                END IF;
                
            END LOOP;
        END IF;

        
	END IF;
         

	-- figure out max values
	SetSheetMaxValueCount(out_new_approval_step_id);
	
	-- create approval_step_sheets
	
/*	
    v_due_Dtm := in_due_dtm;
    IF v_pending_Dataset_id IS NULL THEN
	   	SELECT pending_dataset_id, due_dtm
	   	  INTO v_pending_dataset_Id, v_due_dtm
	   	  FROM approval_step
	   	 WHERE approval_step_id = in_parent_approval_step_id;
	ELSIF v_due_dtm IS NULL THEN
		-- look it up for us
	   	SELECT due_dtm
	   	  INTO v_due_dtm
	   	  FROM approval_step
	   	 WHERE approval_step_id = in_parent_approval_step_id;
	END IF;
	pending_pkg.SubtractWorkingDays(pp.default_due_dtm, in_deadline_offset)
*/  
	
	CASE in_layout_type
		WHEN LAYOUT_IND THEN
			FOR r IN (
				SELECT ap.approval_step_id, pr.pending_region_id||'_'||pp.pending_period_id sheet_key,
					   pr.description||' - '||pp.label label, pr.pending_region_id, pp.pending_period_id, 
	                   pending_pkg.SubtractWorkingDays(pp.default_due_dtm, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_region apsr, pending_region pr, pending_period pp
				 WHERE ap.approval_step_id = out_new_approval_step_id
				   AND ap.approval_step_id = apsr.approval_step_id
				   AND apsr.pending_region_id = pr.pending_region_id
				   AND ap.pending_dataset_id = pp.pending_dataset_id) LOOP

				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label, 
					NULL, r.pending_region_id, r.pending_period_id, r.due_dtm);
					
			END LOOP;
				
		WHEN LAYOUT_REGION THEN		
			FOR r IN (
				SELECT ap.approval_step_id, pi.pending_ind_id||'_'||pp.pending_period_id sheet_key,
					   pi.description||' - '||pp.label label, pi.pending_ind_id, pp.pending_period_id, 
	                   pending_pkg.SubtractWorkingDays(pp.default_due_dtm, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_ind apsi, pending_ind pi, pending_period pp
				 WHERE ap.approval_step_id = out_new_approval_step_id
				   AND ap.approval_step_id = apsi.approval_step_id
				   AND apsi.pending_ind_id = pi.pending_ind_id
				   AND ap.pending_dataset_id = pp.pending_dataset_id) LOOP
				   	
				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					r.pending_ind_id, NULL, r.pending_period_id, r.due_dtm);

			END LOOP;				   	
		
		WHEN LAYOUT_PERIOD THEN
            RAISE_APPLICATION_ERROR(-20001, 'LAYOUT_PERIOD not yet supported');
		
		WHEN LAYOUT_IND_X_REGION THEN 
            RAISE_APPLICATION_ERROR(-20001, 'LAYOUT_IND_X_REGION not yet supported');

		WHEN LAYOUT_IND_X_PERIOD THEN
            RAISE_APPLICATION_ERROR(-20001, 'LAYOUT_IND_X_PERIOD not yet supported');
		
		WHEN LAYOUT_REGION_X_PERIOD THEN 
            RAISE_APPLICATION_ERROR(-20001, 'LAYOUT_REGION_X_REGION not yet supported');
		
	END CASE;	 
	
	--TODO: fix up APPROVAL_STEP_SHEET.SUBMITTED_VALUE_COUNT?
	
END;

PROCEDURE CopyApprovalStepChangeRegions(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_copy_approval_step_id	    IN  approval_step.approval_step_id%TYPE, 
    in_region_ids   		    	IN	T_PENDING_REGION_IDS,
    in_user_sids                    IN  security_pkg.T_SID_IDS,
    out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
)
AS
    v_region_ids    		T_PENDING_REGION_IDS;
    v_user_sids     		security_pkg.T_SID_IDS;
    v_label					approval_step.label%TYPE;
    v_layout_type			approval_step.label%TYPE;
    v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
    v_dataset				pending_dataset.label%TYPE;
    v_ind_ids       		security_pkg.T_SID_IDS;
BEGIN
	SELECT pending_dataset_id, label, layout_type
		INTO v_pending_dataset_Id, v_label, v_layout_type
	  FROM approval_step
	 WHERE approval_step_Id = in_copy_approval_step_Id;

    -- crap hack for ODP.NET
    IF in_region_ids.COUNT = 1 AND in_region_ids(1) IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'You must provide one or more regions');
    END IF;	 
    

	SELECT pending_ind_id
	  BULK COLLECT INTO v_ind_ids
	  FROM APPROVAL_STEP_IND
	 WHERE approval_step_id = in_copy_approval_step_id;
    
    -- crap hack for ODP.NET
    IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
        SELECT user_sid
		  BULK COLLECT INTO v_user_sids
		  FROM APPROVAL_STEP_USER
		 WHERE approval_step_id = in_copy_approval_step_id;
    ELSE
        v_user_sids := in_user_sids;
    END IF;
    
    -- TODO: we need to validate if this is ok, i.e. no conflicts with other root approval steps
	INTERNAL_AddApprovalStep(
		in_act_id,
		null,
		v_pending_dataset_id,
	    v_label,
	    0,
	    v_ind_ids,
	    in_region_ids,
	    v_user_sids,
		v_layout_type,
		out_new_approval_step_id
	);
	
	-- TODO: copy indicators over?
	
	SELECT label INTO v_dataset FROM pending_dataset 
	 WHERE pending_dataset_id = v_pending_dataset_id;
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), out_new_approval_step_id, 'Copied approval step "{0}" under "{1}"', v_label, v_dataset, NULL, v_pending_dataset_id);
END;


PROCEDURE AddRootApprovalStep(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	    	IN  pending_dataset.pending_Dataset_id%TYPE, -- nullable (get from parent approval step)
    in_new_label			    	IN	approval_step.label%TYPE,
    in_ind_ids			            IN	security_pkg.T_SID_IDS,
    in_region_ids   		    	IN	T_PENDING_REGION_IDS, -- nullable (all regions)
    in_user_sids                    IN  security_pkg.T_SID_IDS,
    in_layout_type			    	IN	approval_step.layout_type%TYPE,
	out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
)
AS
    v_ind_ids       security_pkg.T_SID_IDS;
    v_region_ids    T_PENDING_REGION_IDS;
    v_user_sids     security_pkg.T_SID_IDS;
    v_dataset		pending_dataset.label%TYPE;
BEGIN

    -- crap hack for ODP.NET
    IF in_ind_ids.COUNT = 1 AND in_ind_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        v_ind_ids := in_ind_ids;
    END IF;	 

    -- crap hack for ODP.NET
    IF in_region_ids.COUNT = 1 AND in_region_ids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        v_region_ids := in_region_ids;
    END IF;	 
    
    
    -- crap hack for ODP.NET
    IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        v_user_sids := in_user_sids;
    END IF;
    
    -- TODO: we need to validate if this is ok, i.e. no conflicts with other root approval steps
	INTERNAL_AddApprovalStep(
		in_act_id,
		null,
		in_pending_dataset_id,
	    in_new_label,
	    0,
	    v_ind_ids,
	    v_region_ids,
	    v_user_sids,
		in_layout_type,
		out_new_approval_step_id
	);
	
	SELECT label INTO v_dataset FROM pending_dataset WHERE pending_dataset_id = in_pending_dataset_id;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), out_new_approval_step_id, 'Created approval step "{0}" under "{1}"', in_new_label, v_dataset, NULL, in_pending_dataset_id);
END;

PROCEDURE AddApprovalStep(
	in_act_id					    IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	    IN	approval_step.approval_step_id%TYPE,
	in_new_label				    IN	approval_step.label%TYPE,
    in_working_day_Offset_from_due  IN  approval_step.working_day_Offset_from_due%TYPE,
    in_ind_ids			            IN	security_pkg.T_SID_IDS, -- nullable (all inds of parent)
    in_region_ids			        IN	T_PENDING_REGION_IDS,  -- nullable (all regions of parent)
    in_user_sids                    IN  security_pkg.T_SID_IDS,
	out_new_approval_step_id	    OUT	approval_step.approval_step_id%TYPE
)
AS
	v_layout_type	approval_Step.layout_type%TYPE;
    v_ind_ids       security_pkg.T_SID_IDS;
    v_region_ids    T_PENDING_REGION_IDS;
    v_user_sids     security_pkg.T_SID_IDS;
BEGIN
	SELECT layout_type 
	  INTO v_layout_type
	  FROM approval_Step
	 WHERE approval_step_id = in_parent_approval_step_id;

    -- crap hack for ODP.NET
    IF in_ind_ids IS NULL OR (in_ind_ids.COUNT = 1 AND in_ind_ids(1) IS NULL) THEN
        -- all inds of the parent step
        SELECT pending_ind_id
          BULK COLLECT INTO v_ind_ids
          FROM APPROVAL_STEP_IND
         WHERE approval_step_id = in_parent_approval_step_id;
    ELSE
        v_ind_ids := in_ind_ids;
    END IF;	 

    -- crap hack for ODP.NET
    IF in_region_ids IS NULL OR (in_region_ids.COUNT = 1 AND in_region_ids(1) IS NULL) THEN
        -- all inds of the parent step
        SELECT pending_region_id
          BULK COLLECT INTO v_region_ids
          FROM APPROVAL_STEP_REGION
         WHERE approval_step_id = in_parent_approval_step_id;
    ELSE
        v_region_ids := in_region_ids;
    END IF;	 
    
    
    -- crap hack for ODP.NET
    IF in_user_sids.COUNT = 1 AND in_user_sids(1) IS NULL THEN
        NULL; -- collection is null by default
    ELSE
        v_user_sids := in_user_sids;
    END IF;
    
	INTERNAL_AddApprovalStep(
		in_act_id,
		in_parent_approval_step_id,
		null,
	    in_new_label,	
	    in_working_day_Offset_from_due,
	    v_ind_ids,		
	    v_region_ids,
	    v_user_sids, 
	    v_layout_type,
		out_new_approval_step_id	
	);
END;


PROCEDURE AddApprovalStep(
	in_act_id					        IN	security_pkg.T_ACT_ID,
	in_parent_approval_step_id	        IN	approval_step.approval_step_id%TYPE,
	in_new_label				        IN	approval_step.label%TYPE,
    in_working_day_Offset_from_due	    IN	approval_step.working_day_Offset_from_due%TYPE,
    in_ind_ids			                IN	security_pkg.T_SID_IDS, -- nullable (all inds of parent)
    in_region_ids   			        IN	T_PENDING_REGION_IDS, -- nullable (all regions of parent)
    in_user_sids                        IN  security_pkg.T_SID_IDS,
	out_cur						        OUT	SYS_REFCURSOR
)
AS
	v_id	approval_step.approval_step_id%TYPE;
BEGIN
	AddApprovalStep(in_act_id, in_parent_approval_step_id, in_new_label, in_working_day_Offset_from_due,
		in_ind_ids, in_region_ids, in_user_sids, v_id);
	GetApprovalStep(in_act_id, v_id, out_cur);
END;

-- TODO: handle change to layout_type
PROCEDURE AmendApprovalStep(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_label					IN	approval_step.label%TYPE
)
AS
/*
	v_parent_due_dtm	approval_step.due_dtm%TYPE;
	v_max_child_due_dtm	approval_step.due_dtm%TYPE;
BEGIN
	-- check date makes sense
	BEGIN
		SELECT due_dtm
		  INTO v_parent_due_dtm
		  FROM approval_step
		 WHERE approval_step_id = (
		 	SELECT parent_step_id 
		 	  FROM approval_step
		 	 WHERE approval_step_id = in_approval_step_id
		);
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			v_parent_due_dtm := null;
	END;

	 SELECT MAX(due_dtm)
	   INTO v_max_child_due_dtm
	   FROM approval_step
	  START WITH approval_step_id = in_approval_step_id
	CONNECT BY PRIOR approval_step_id = parent_step_id;
	
	IF v_parent_due_dtm IS NOT NULL AND in_due_dtm > v_parent_due_dtm THEN
		RAISE_APPLICATION_ERROR(-20001, 'Due date is after parent due date');
	ELSIF v_max_child_due_dtm IS NOT NULL AND in_due_dtm < v_max_child_due_dtm THEN
		RAISE_APPLICATION_ERROR(-20001, 'Due date is before child due dates');
	END IF;
	*/
BEGIN	
	UPDATE approval_step
	   SET label = in_label
	 WHERE approval_step_id = in_approval_step_id;
END;



PROCEDURE CreatePeriod(
	in_act_Id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_Id	IN	pending_dataset.pending_dataset_id%TYPE,
	in_start_dtm			IN	pending_period.start_Dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_default_due_dtm		IN	pending_period.default_due_dtm%TYPE,
	in_label				IN	pending_period.label%TYPE,
	out_pending_period_id	OUT	pending_period.pending_period_id%TYPE
)
AS
BEGIN
	INSERT INTO pending_period
		(pending_period_id, pending_Dataset_id, start_dtm, end_dtm, default_due_dtm, LABEL)
	VALUES
		(pending_period_id_seq.NEXTVAL, in_pending_dataset_Id, in_start_dtm, in_end_dtm, in_default_due_dtm, in_label)
	RETURNING pending_period_Id INTO out_pending_period_id;

    -- update all max values for layouts that include more than 1 period
    FOR r IN (
        SELECT approval_step_id
          FROM approval_step
         WHERE pending_dataset_id = in_pending_dataset_id
           AND layout_type IN (pending_pkg.LAYOUT_PERIOD, pending_pkg.LAYOUT_IND_X_PERIOD, pending_pkg.LAYOUT_REGION_X_PERIOD)
    )
    LOOP
        SetSheetMaxValueCount(r.approval_step_id);
    END LOOP;

	-- if layout type has the period "in the dropdown" then add an approval_step_sheet
	-- first of all for layout_ind
	FOR r IN (
		SELECT ap.approval_step_id, apsr.pending_region_id||'_'||out_pending_period_id sheet_key, 
		 	   pr.description||' - '||in_label label, apsr.pending_region_id, out_pending_period_id pending_period_id, 
               pending_pkg.SubtractWorkingDays(in_default_due_dtm, ap.working_day_offset_from_due) due_dtm
		  FROM approval_step ap, approval_step_region apsr, pending_region pr
         WHERE ap.pending_dataset_id = in_pending_dataset_id
           AND ap.layout_type IN (pending_pkg.LAYOUT_IND) 
		   AND ap.approval_step_id = apsr.approval_step_id
		   AND pr.pending_region_id = apsr.pending_region_id) LOOP
		
		CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
			NULL, r.pending_region_id, r.pending_period_id, r.due_dtm);

	END LOOP;
	
	-- now for layout_region
	FOR r IN (
		SELECT ap.approval_step_id, apsi.pending_ind_id||'_'||out_pending_period_id sheet_key,
               pi.description||' - '||in_label label, apsi.pending_ind_id, out_pending_period_id pending_period_id, 
               pending_pkg.SubtractWorkingDays(in_default_due_dtm, ap.working_day_offset_from_due) due_dtm
		  FROM approval_step ap, approval_step_ind apsi, pending_ind pi
         WHERE ap.pending_dataset_id = in_pending_dataset_id
           AND ap.layout_type IN (pending_pkg.LAYOUT_REGION)
		   AND ap.approval_step_id = apsi.approval_step_id
		   AND pi.pending_ind_id = apsi.pending_ind_id) LOOP

		CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
			r.pending_ind_id, NULL, r.pending_period_id, r.due_dtm);

	END LOOP;
	
	-- now for layout_ind_x_region
	FOR r IN (
		SELECT ap.approval_step_id, out_pending_period_id sheet_key, in_label label, 
			   out_pending_period_id pending_period_id, 
               pending_pkg.SubtractWorkingDays(in_default_due_dtm, ap.working_day_offset_from_due) due_dtm
		  FROM approval_step ap
         WHERE ap.pending_dataset_id = in_pending_dataset_id
           AND ap.layout_type IN (pending_pkg.LAYOUT_IND_X_REGION)) LOOP

		CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
			NULL, NULL, r.pending_period_id, r.due_dtm);

	END LOOP;
END;

PROCEDURE DeletePeriod(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	in_ignore_warnings		IN	NUMBER
)
AS
	v_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	-- TODO: what about if the values we're about to delete are associated
	-- with VAL source types?

	-- delete cached values
	DELETE FROM pending_val_cache WHERE pending_period_id = in_pending_period_id;
	DELETE FROM PVC_STORED_CALC_JOB WHERE pending_period_id = in_pending_period_id;

	
	-- delete all values 
	FOR r IN (
		SELECT pending_val_Id FROM pending_val WHERE pending_period_Id = in_pending_period_id
    )
    LOOP
		-- if we're in here at all, then there are values present,
		-- so barf (unless we're ignoring warnings)
		IF in_ignore_warnings = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Values are present for this period ('||in_pending_period_id||')');		
		END IF;
		INTERNAL_DeleteVal(r.pending_val_id);
    END LOOP;
    

	-- delete this period from approval steps
	FOR r IN (
		SELECT aps.approval_step_id
		  FROM approval_step aps -- TODO!!! This needs to filter more sensibly
		 WHERE layout_type IN (pending_pkg.LAYOUT_IND, pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION)
	)
	LOOP
		FOR rs IN (
			SELECT approval_step_id, sheet_key
			  FROM approval_step_sheet
			 WHERE pending_period_id = in_pending_period_id
			   AND approval_step_id = r.approval_step_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;		
		--SetSheetMaxValueCount(r.approval_step_id); -- TODO!! this is being run all the time and killing the database!!!
	END LOOP;
    /* Deleting approval step stops the dataset create/edit page form working, as it is normal for a 
       user to have approval steps before they have set up all the other items in the dataset.  
       Also it is somewhat unexpected behavior for the user to have their approval step vanish 
       when they do a unrelated task in the UI.
    -- check (and remove) any now empty approval steps
    SELECT pending_dataset_id
      INTO v_dataset_id
      FROM pending_period
     WHERE pending_period_id = in_pending_period_id;
    RemoveEmptyApprovalSteps(v_dataset_id);
    */
	
	DELETE FROM PENDING_PERIOD 
	 WHERE pending_period_id = in_pending_period_id;
END;
	
PROCEDURE DeleteAllPeriods(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_ignore_warnings			IN	NUMBER
)
AS
BEGIN		
	-- delete all periods
	FOR r IN (
		SELECT pending_period_Id
		  FROM pending_period
		 WHERE pending_dataset_id = in_pending_dataset_id
	)
	LOOP
		pending_pkg.DeletePeriod(in_act_id, r.pending_period_id, in_ignore_warnings);
	END LOOP;	
END;


PROCEDURE GetPeriodRange(
	in_act_id				  IN  security_pkg.T_ACT_ID,
	in_pending_dataset_id 	  IN  pending_dataset.pending_dataset_id%TYPE,
    out_start_dtm             OUT DATE,
    out_end_dtm               OUT DATE,
    out_interval_in_months    OUT NUMBER
)
AS
BEGIN
   FOR r IN (SELECT start_dtm, end_dtm FROM pending_period WHERE pending_dataset_id = in_pending_dataset_id)
   LOOP
        IF out_start_dtm IS NULL OR out_start_dtm > r.start_dtm THEN
            out_start_dtm := r.start_dtm;
        END IF;
        
        IF out_end_dtm IS NULL OR out_end_dtm < r.end_dtm THEN
            out_end_dtm := r.end_dtm;
        END IF;
        
        IF out_interval_in_months IS NULL THEN
            out_interval_in_months := months_between(r.end_dtm, r.start_dtm);
        ELSE
            IF out_interval_in_months != months_between(r.end_dtm, r.start_dtm) THEN
			    RAISE_APPLICATION_ERROR(-20001, 'Not all periods in the dataset have the same length');
            END IF;
        END IF;
   END LOOP;
END;

-- Create periods between the two dates without regards for any
-- pariods that are allready there
PROCEDURE INTERNAL_CreatePeriods(
	in_act_Id				 IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	 IN  pending_dataset.pending_dataset_id%TYPE,
    in_start_dtm             IN DATE,
    in_end_dtm               IN DATE,
    in_interval_in_months    IN NUMBER 
)
AS
    v_period_start_dtm DATE;
    v_period_end_dtm   DATE;
    v_pending_period_id	pending_period.pending_period_id%TYPE;
BEGIN
    v_period_start_dtm := in_start_dtm;
    
    WHILE v_period_start_dtm < in_end_dtm 
    LOOP
        v_period_end_dtm := ADD_MONTHS(v_period_start_dtm, in_interval_in_months);
        
        pending_pkg.CreatePeriod(in_act_Id, in_pending_dataset_id, 
            v_period_start_dtm, v_period_end_dtm, v_period_end_dtm + 1, NULL, v_pending_period_id);
            
        v_period_start_dtm := v_period_end_dtm;
    END LOOP;
END;

-- called by triggers on CMS tables (e.g. for 2012)
PROCEDURE SetRelatedPendingVal(
	in_pending_val_id           pending_val.pending_val_id%TYPE,
	in_related_ind_lookup_key	pending_ind.lookup_key%TYPE,
	in_new_val_number           pending_val.val_number%TYPE
)
AS
    v_pending_ind_id            pending_val.pending_ind_id%TYPE;
	v_pending_region_Id	        pending_val.pending_region_id%TYPE;
	v_pending_period_Id	        pending_val.pending_period_id%TYPE;
	v_approval_step_Id		    pending_val.approval_step_id%TYPE;
	v_pending_dataset_Id	    pending_ind.pending_dataset_id%TYPE;
	v_related_pending_ind_id	pending_ind.pending_ind_id%TYPE;

BEGIN
	SELECT pending_dataset_id, pv.pending_ind_id, pv.pending_region_id, pv.pending_period_Id, pv.approval_step_id
	  INTO v_pending_dataset_Id, v_pending_ind_id, v_pending_region_id, v_pending_period_id, v_approval_step_id
	  FROM pending_val pv, pending_ind pi
	 WHERE pv.pending_val_Id = in_pending_val_id
	   AND pv.pending_ind_Id = pi.pending_ind_id;

    BEGIN
        SELECT pending_ind_id 
          INTO v_related_pending_ind_id
          FROM pending_ind
         WHERE lookup_key = in_related_ind_lookup_key
           AND pending_dataset_id = v_pending_dataset_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Lookup key '||in_related_ind_lookup_key||' not found inserting pending_val_id '||in_pending_Val_Id);
    END;
	   
	BEGIN
		INSERT INTO PENDING_VAL (
			pending_val_Id, pending_ind_id, pending_region_id, pending_period_id, 
			approval_step_id, val_number
		) VALUES (
			pending_val_id_seq.nextval, v_related_pending_ind_id, v_pending_region_id, v_pending_period_id, 
			v_approval_step_id, in_new_val_number
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE pending_val
			   SET val_number = in_new_val_number,
				   approval_step_id = v_approval_step_id,
				   merged_state = CASE merged_state WHEN 'S' THEN 'U' ELSE merged_state END
			 WHERE pending_ind_id = v_related_pending_ind_id
			   AND pending_region_id = v_pending_region_id
			   AND pending_period_id = v_pending_period_id;
	END;
END;


PROCEDURE SetPeriodRange(
	in_act_Id				 IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	 IN  pending_dataset.pending_dataset_id%TYPE,
    in_start_dtm             IN DATE,
    in_end_dtm               IN DATE,
    in_interval_in_months    IN NUMBER 
)
AS
    v_current_start_dtm             DATE;
    v_current_end_dtm               DATE;
    v_current_interval_in_months    NUMBER;
BEGIN
    pending_pkg.GetPeriodRange(in_act_Id, in_pending_dataset_id, v_current_start_dtm, v_current_end_dtm, v_current_interval_in_months);
    
    IF v_current_start_dtm IS NULL THEN
        -- no periods set up
        pending_pkg.INTERNAL_CreatePeriods(in_act_Id, in_pending_dataset_id, in_start_dtm, in_end_dtm, in_interval_in_months);
        RETURN;
    END IF;
    
    IF in_start_dtm > v_current_start_dtm OR
       in_interval_in_months != v_current_interval_in_months OR
       in_end_dtm < v_current_end_dtm THEN
            -- Need to start again to cope with the change, this WILL fail if 
            -- the dataset contains any data.
            pending_pkg.DeleteAllPeriods(in_act_Id, in_pending_dataset_id, 0);
            pending_pkg.INTERNAL_CreatePeriods(in_act_Id, in_pending_dataset_id, in_start_dtm, in_end_dtm, in_interval_in_months);
    ELSE
        pending_pkg.INTERNAL_CreatePeriods(in_act_Id, in_pending_dataset_id, in_start_dtm, v_current_start_dtm, in_interval_in_months);
        pending_pkg.INTERNAL_CreatePeriods(in_act_Id, in_pending_dataset_id, v_current_end_dtm, in_end_dtm, in_interval_in_months);
    END IF;
    
END;

PROCEDURE GetPeriods(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id 	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pp.pending_period_id period_id, pp.start_dtm, pp.end_dtm, pp.LABEL
		  FROM pending_period pp
		 WHERE pp.pending_dataset_id = in_pending_dataset_id
		 ORDER BY start_dtm;
END;

-- just in case we screw them up!!
PROCEDURE RekeyApprovalStepSheet(
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT apss.ROWID rid, 
		   replace(regexp_replace(pi.description||' - '||pr.description||' - '||pp.label, '^( - )|( - )$', ''),' -  - ', ' - ') label,
		   replace(regexp_replace(pi.pending_ind_id||'_'||pr.pending_region_id||'_'||pp.pending_period_id, '^_|_$', ''),'__', '_') sheet_key
		  FROM approval_step_sheet apss, pending_period pp, pending_ind pi, pending_region pr
		 WHERE apss.approval_step_id = in_approval_step_id
		   AND apss.pending_period_id = pp.pending_period_id(+)
		   AND apss.pending_ind_id = pi.pending_ind_id(+)
		   AND apss.pending_region_id = pr.pending_region_id(+)
	)
	LOOP
		UPDATE approval_step_Sheet
		   SET sheet_key = r.sheet_key, label = r.label
		 WHERE ROWID = r.rid;
	END LOOP;
END;

-- layout_period would consist of all periods on one form, so there's
-- no really senseible due date, other than basing it on the last period
-- on the form. Hence this function!
FUNCTION MaxDueDtmForLayoutPeriod(
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE
) RETURN DATE
AS
    v_due_dtm   DATE;
BEGIN
    -- figure out due_dtm
    SELECT MAX(default_due_dtm)  
      INTO v_due_dtm
      FROM pending_period pp, pending_dataset pds, approval_step ap
     WHERE ap.pending_dataset_id = pds.pending_dataset_id
       AND pds.pending_Dataset_id = pp.pending_dataset_id
       AND ap.approval_step_id = in_approval_step_id;
    RETURN v_due_dtm;
END;

PROCEDURE CreateApprovalStepSheetsForInd(
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_layout_type			IN	approval_step.layout_type%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE
)
AS
    v_max_due_dtm_layout_period  DATE;
BEGIN
	CASE in_layout_type
		-- first of all for layout_region
		WHEN LAYOUT_REGION THEN
			FOR r IN (
	            SELECT ap.approval_step_id, 
	            	   apsi.pending_ind_id||'_'||pp.pending_period_id sheet_key, 
	            	   pi.description||' - '||pp.label label,
	                   apsi.pending_ind_id, pp.pending_period_id, 
	                   pending_pkg.SubtractWorkingDays(pp.default_due_dtm, ap.working_day_offset_from_due) due_dtm
	              FROM approval_step ap, approval_step_ind apsi, pending_ind pi, pending_period pp
	             WHERE ap.approval_step_id = in_approval_step_id
	               AND ap.approval_step_Id = apsi.approval_step_id
	               AND apsi.pending_ind_id = pi.pending_ind_Id
	               AND ap.pending_Dataset_id = pp.pending_dataset_id
	               AND apsi.pending_ind_id = in_pending_ind_id) LOOP
	               	
				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					r.pending_ind_id, NULL, r.pending_period_id, r.due_dtm);

			END LOOP;
	
		-- then for layout_period
		WHEN LAYOUT_PERIOD THEN
            v_max_due_dtm_layout_period := MaxDueDtmForLayoutPeriod(in_approval_step_id);
            FOR r IN (
				SELECT ap.approval_step_id, 
					   apsi.pending_ind_id||'_'||apsr.pending_region_id sheet_key, 
					   pi.description||' - '||pr.description label,
					   apsi.pending_ind_id, apsr.pending_region_id, 
                       pending_pkg.SubtractWorkingDays(v_max_due_dtm_layout_period, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_ind apsi, pending_ind pi, 
					   approval_step_region apsr, pending_region pr
				 WHERE ap.approval_step_id = in_approval_step_id
				   AND ap.approval_step_id = apsi.approval_step_id
				   AND ap.approval_step_id = apsr.approval_step_id
				   AND apsi.pending_ind_id = pi.pending_ind_id
				   AND apsr.pending_region_id = pr.pending_region_id
				   AND apsi.pending_ind_id = in_pending_ind_id) LOOP

				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					r.pending_ind_id, r.pending_region_id, NULL, r.due_dtm);

			END LOOP;

		-- then for layout_region_x_period
		WHEN LAYOUT_REGION_X_PERIOD THEN
            v_max_due_dtm_layout_period := MaxDueDtmForLayoutPeriod(in_approval_step_id);
			FOR r IN (
				SELECT apsi.approval_step_id, apsi.pending_ind_id sheet_key, 
					   pi.description label, apsi.pending_ind_id,
					   pending_pkg.SubtractWorkingDays(v_max_due_dtm_layout_period, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_ind apsi, pending_ind pi
				 WHERE ap.approval_step_id = in_approval_step_id
				   AND apsi.approval_step_id = in_approval_step_id
				   AND ap.approval_step_id = apsi.approval_step_id
				   AND apsi.pending_ind_id = pi.pending_ind_id
				   AND apsi.pending_ind_id = in_pending_ind_id) LOOP
				   	
				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					r.pending_ind_id, NULL, NULL, r.due_dtm);

			END LOOP;
					
		ELSE
			NULL; -- ignore
	END CASE;	
END;

PROCEDURE AddIndToApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_propagate_down		IN  NUMBER
)
AS
	v_parent_step_id	approval_step.approval_step_id%TYPE;
	v_layout_type		approval_step.layout_type%TYPE;
	v_cnt				NUMBER(10);
BEGIN
	-- you have to add an indicator at the top?
	SELECT parent_step_id, layout_type
	  INTO v_parent_step_id, v_layout_type
	  FROM APPROVAL_STEP
	 WHERE approval_step_id = in_approval_step_id;
		 
	IF v_parent_step_id IS NOT NULL THEN
		-- check it's part of the parent and NOT part of this one (should return just 1 row)
		SELECT COUNT(*) 
		  INTO v_cnt
	      FROM approval_step_ind 
	     WHERE pending_ind_id = in_pending_ind_id
	       AND approval_step_id IN (in_approval_step_id, v_parent_step_Id);
	       
		IF v_cnt = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'You must add indicators to a parent approval step first');
		ELSIF v_cnt > 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'This indicator exists at this approval step already');
		END IF;
	ELSE
		SELECT COUNT(*) 
		  INTO v_cnt
	      FROM approval_step_ind 
	     WHERE pending_ind_id = in_pending_ind_id
	       AND approval_step_id = in_approval_step_id;
		IF v_cnt > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'This indicator exists at this approval step already');
		END IF;
	END IF;
	
	-- check indicator is part of the same pending dataset
	SELECT COUNT(*)  
	  INTO v_cnt
	  FROM (
		SELECT pending_dataset_id  
		  FROM PENDING_IND 
		 WHERE pending_ind_id = in_pending_ind_id
	 INTERSECT
		SELECT pending_dataset_id
		  FROM APPROVAL_STEP
		 WHERE approval_step_id = in_approval_step_id
	   );
	 IF v_cnt != 1 THEN
	 	RAISE_APPLICATION_ERROR(-20001, 'Indicator and approval step are from different pending datasets');
	 END IF;
	
	
	-- either insert for every approval step downwards, or just this one
	IF in_propagate_down = 1 THEN
		FOR r IN (
			SELECT approval_step_id, layout_type
			  FROM approval_step
			 START WITH approval_step_id = in_approval_step_id
		   CONNECT BY PRIOR approval_step_id = parent_step_id
		)
		LOOP
			INSERT INTO APPROVAL_STEP_IND 
				(approval_step_id, pending_ind_id)			
			VALUES
				(r.approval_step_id, in_pending_ind_id);
			IF r.layout_type in (pending_pkg.LAYOUT_IND, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_IND_X_PERIOD) THEN
				SetSheetMaxValueCount(r.approval_step_id);
			END IF;
			CreateApprovalStepSheetsForInd(r.approval_step_id, r.layout_type, in_pending_ind_id);
		END LOOP;
	ELSE
		INSERT INTO APPROVAL_STEP_IND 
			(approval_step_id, pending_ind_id)			
		VALUES
			(in_approval_step_id, in_pending_ind_id);
		IF v_layout_type in (pending_pkg.LAYOUT_IND, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_IND_X_PERIOD) THEN
			SetSheetMaxValueCount(in_approval_step_id);
		END IF;
		CreateApprovalStepSheetsForInd(in_approval_step_id, v_layout_type, in_pending_ind_id);
	END IF;
END;


PROCEDURE RemoveIndFromApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_ignore_warnings		IN	NUMBER
)
AS
	v_cnt		NUMBER(10);
BEGIN
	-- TODO: DO WE NEED A SELECT FOR UPDATE???
	
	-- delete the indicator from this and all child approval steps
	FOR r IN (
		SELECT approval_step_id, layout_type
		  FROM approval_step
		 START WITH approval_step_id = in_approval_step_id
	   CONNECT BY PRIOR approval_step_id = parent_step_id
	     ORDER BY LEVEL DESC -- do from bottom up since we might delete approval steps
	)
	LOOP	
		-- check if this indicator / approval step is in use in the value table	
		UPDATE pending_val
		   SET approval_step_id = null -- set to unapproved
		 WHERE pending_ind_id = in_pending_ind_id
		   AND approval_step_id = r.approval_step_id;
		-- MUST come straight after UPDATE statement
		IF in_ignore_warnings = 0 AND SQL%ROWCOUNT > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Values are present for this indicator at approval step id '||r.approval_step_id);
		END IF;
		
		FOR rs IN (
			SELECT approval_step_Id, sheet_key 
			  FROM APPROVAL_STEP_SHEET
			 WHERE approval_step_id = r.approval_step_id
			   AND pending_ind_id = in_pending_ind_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
		   
		DELETE FROM APPROVAL_STEP_IND
		 WHERE approval_step_id = r.approval_step_id
		   AND pending_ind_id = in_pending_ind_id;
		   
		IF r.layout_type in (pending_pkg.LAYOUT_IND, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_IND_X_PERIOD) THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
		
		-- if this is the only indicator in the approval step then we're going to 
		-- want to delete the approval step
		SELECT COUNT(*) 
		  INTO v_cnt
		  FROM approval_step_ind
		 WHERE approval_step_id = r.approval_step_id;
		
		IF v_cnt = 0 THEN
			INTERNAL_DeleteApprovalStep(r.approval_step_id);
		END IF;
	END LOOP;
	
	
	-- if there is no longer in any approval step using the ind then delete from pending_val
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM approval_step_ind
	 WHERE pending_ind_id = in_pending_ind_id;
	 
	IF v_cnt = 0 THEN
		FOR r IN (
			SELECT pending_val_id 
			  FROM pending_val
		 	 WHERE pending_ind_id = in_pending_ind_id
		)
		LOOP
			INTERNAL_DeleteVal(r.pending_val_id);
		END LOOP;
	END IF;
END;

PROCEDURE CreateApprovalStepSheetsForReg(
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_layout_type				IN	approval_step.layout_type%TYPE,
	in_pending_region_id		IN	pending_region.pending_region_id%TYPE
)
AS
    v_max_due_dtm_layout_period 	DATE;
BEGIN	 
	CASE in_layout_type
		-- first of all for layout_ind
		WHEN LAYOUT_IND THEN
			FOR r IN (
				SELECT ap.approval_step_id, 
					   apsr.pending_region_id||'_'||pp.pending_period_id sheet_key, 
					   pr.description||' - '||pp.label label,
					   apsr.pending_region_id, pp.pending_period_id,
                       pending_pkg.SubtractWorkingDays(pp.default_due_dtm, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_region apsr, pending_region pr, pending_period pp
				 WHERE ap.approval_step_id = in_approval_step_id
				   AND ap.approval_step_id = apsr.approval_step_id
				   AND apsr.pending_region_id = pr.pending_region_id
				   AND ap.pending_dataset_id = pp.pending_dataset_id
				   AND apsr.pending_region_id = in_pending_region_id) LOOP

				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					NULL, r.pending_region_id, r.pending_period_id, r.due_dtm);

			END LOOP;

		-- then for layout_period
		WHEN LAYOUT_PERIOD THEN
            v_max_due_dtm_layout_period := MaxDueDtmForLayoutPeriod(in_approval_step_id);

			FOR r IN (			
                SELECT ap.approval_step_id, 
                	   apsr.pending_region_id||'_'||apsi.pending_ind_id sheet_key, 
                	   pr.description||' - '||pi.description label,
                       apsr.pending_region_id, apsi.pending_ind_id, 
                       pending_pkg.SubtractWorkingDays(v_max_due_dtm_layout_period, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_region apsr, pending_region pr, 
					   approval_step_ind apsi, pending_ind pi
				 WHERE ap.approval_step_id = in_approval_step_id
				   AND ap.approval_step_Id = apsr.approval_step_id
				   AND ap.approval_step_id = apsi.approval_step_id
				   AND apsr.pending_region_id = pr.pending_region_id
				   AND apsi.pending_ind_id = pi.pending_ind_id
				   AND apsr.pending_region_id = in_pending_region_id) LOOP
				   	   	
				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					r.pending_ind_id, r.pending_region_id, NULL, r.due_dtm);

			END LOOP;

		-- then for layout_ind_x_period
		WHEN LAYOUT_IND_X_PERIOD THEN
            v_max_due_dtm_layout_period := MaxDueDtmForLayoutPeriod(in_approval_step_id);

			FOR r IN (
                SELECT apsr.approval_step_id, apsr.pending_region_id sheet_key, pr.description label,
                       apsr.pending_region_id, 
                       pending_pkg.SubtractWorkingDays(v_max_due_dtm_layout_period, ap.working_day_offset_from_due) due_dtm
				  FROM approval_step ap, approval_step_region apsr, pending_region pr
				 WHERE ap.approval_step_id = in_approval_step_id
				   AND apsr.approval_step_id = in_approval_step_id
				   AND apsr.pending_region_id = pr.pending_region_id
				   AND apsr.pending_region_id = in_pending_region_id) LOOP

				CreateApprovalStepSheet(r.approval_step_id, r.sheet_key, r.label,
					NULL, r.pending_region_id, NULL, r.due_dtm);

			END LOOP;

		ELSE
			NULL; -- ignore
	END CASE;
END;


-- adds a region to an approval step, and inserts up the tree
-- right to the top or until we find a parent region in a higher
-- approval step
PROCEDURE AddRegionToApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_Step_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE
)
AS
	v_cnt				NUMBER(10);
	v_parent_region_id	pending_region.pending_region_id%TYPE;
	CURSOR c_matching_parent_ids(v_parent_step_id approval_step.approval_step_id%TYPE) IS
		SELECT pending_region_id
		  FROM APPROVAL_STEP_REGION
		 WHERE approval_step_id = v_parent_step_id
	 INTERSECT
		SELECT pending_region_id 
		  FROM PENDING_REGION 
		 START WITH pending_region_id = in_pending_region_id
	   CONNECT BY PRIOR parent_region_id = pending_region_id;
	v_region			pending_region.description%TYPE;
	v_step				approval_step.label%TYPE;
BEGIN		
	-- check region is part of the same pending dataset
	SELECT COUNT(*)  
	  INTO v_cnt
	  FROM (
		SELECT pending_dataset_id  
		  FROM PENDING_REGION 
		 WHERE pending_region_id = in_pending_region_id
	 INTERSECT
		SELECT pending_dataset_id
		  FROM APPROVAL_STEP
		 WHERE approval_step_id = in_approval_step_id
	   );
	 IF v_cnt != 1 THEN
	 	RAISE_APPLICATION_ERROR(-20001, 'Region and approval step are from different pending datasets');
	 END IF;
	

	-- the child nodes of the region being added, cannot exist at this level 
	-- or higher up the tree.
	-- e.g. France cannot exist higher up, if we're adding Europe
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (
	     -- get the child nodes of the region being added 
		 SELECT pending_region_id 
		   FROM PENDING_REGION
		  START WITH parent_region_id = in_pending_region_id
		CONNECT BY PRIOR pending_region_id = parent_region_id
	  INTERSECT
		 -- get regions at this level or higher up the tree
		 SELECT DISTINCT apsr.pending_region_id
		   FROM APPROVAL_STEP aps, APPROVAL_STEP_REGION apsr
		  WHERE aps.approval_step_id = apsr.approval_step_id 
		  START WITH aps.approval_step_id = in_approval_step_id
		CONNECT BY PRIOR aps.parent_step_id = aps.approval_step_id
		    AND PRIOR apsr.rolls_up_to_region_id = apsr.pending_region_id
	   );
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The region being added ('||in_pending_region_id
			||'), or one of its child nodes exists at this approval level ('||in_approval_step_id
			||') or higher up the tree');
	END IF;

	
    -- the region being added, nor its parent nodes can exist at this level 
    -- or lower down the tree.
    -- e.g. Europe cannot exist lower down if we're adding Germany
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM (
	     -- get the region being added and its parent nodes
		 SELECT pending_region_id 
		   FROM PENDING_REGION
		  START WITH pending_region_id = in_pending_region_id
		CONNECT BY PRIOR parent_region_id = pending_region_id
	  INTERSECT
		 -- get regions at this level or lower down the tree
		 SELECT DISTINCT apsr.pending_region_id
		   FROM APPROVAL_STEP aps, APPROVAL_STEP_REGION apsr
		  WHERE aps.approval_step_id = apsr.approval_step_id 
		  START WITH aps.approval_step_id = in_approval_step_id
		CONNECT BY PRIOR aps.approval_step_id = aps.parent_step_id
		    AND PRIOR apsr.pending_region_id = apsr.rolls_up_to_region_id
	  );
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The region being added ('||in_pending_region_id
			||'), or one of its parent nodes exists at this approval level ('||in_approval_step_id
			||') or lower down the tree');
	END IF;

	
	-- keep adding this region up the tree until we reach the top, 
	-- OR our node, or one of our parent nodes exists in the regions at the parent level
	<<each_parent_step>>
	FOR r IN (
		SELECT approval_step_id, parent_step_id, layout_type
		  FROM approval_step
		 START WITH approval_step_id = in_approval_step_id
	   CONNECT BY PRIOR parent_step_id = approval_step_id
	)
	LOOP
	
		OPEN c_matching_parent_ids(r.parent_step_id);
		FETCH c_matching_parent_ids INTO v_parent_region_id;
		IF c_matching_parent_ids%FOUND THEN
			-- insert, with map to parent
			INSERT INTO APPROVAL_STEP_REGION 
				(approval_step_id, pending_region_id, rolls_up_to_region_id)			
			VALUES
				(r.approval_step_id, in_pending_region_id, v_parent_region_id);			
	
			CreateApprovalStepSheetsForReg(r.approval_step_id, r.layout_type, in_pending_region_id);
			IF r.layout_type in (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) THEN
				SetSheetMaxValueCount(r.approval_step_id);
			END IF;
			-- all done
			EXIT each_parent_step;
		END IF;
		CLOSE c_matching_parent_ids;
	
		-- insert
		INSERT INTO APPROVAL_STEP_REGION 
			(approval_step_id, pending_region_id, rolls_up_to_region_id)			
		VALUES
			(r.approval_step_id, in_pending_region_id, in_pending_region_id);
		
		CreateApprovalStepSheetsForReg(r.approval_step_id, r.layout_type, in_pending_region_id);
		IF r.layout_type in (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
	END LOOP;
	
	SELECT description INTO v_region FROM pending_region WHERE pending_region_id = in_pending_region_id;
	SELECT label INTO v_step FROM approval_step WHERE approval_step_id = in_approval_step_id;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_approval_step_id, 'Added region "{0}" to approval step "{1}"', v_region, v_step);
END;


PROCEDURE RemoveRegionFromApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_ignore_warnings		IN	NUMBER
)
AS
	v_cnt		NUMBER(10);
	v_region	pending_region.description%TYPE;
	v_step		approval_step.label%TYPE;
BEGIN
	-- TODO: DO WE NEED A SELECT FOR UPDATE???
	
	-- delete the region from this and all child approval steps
	FOR r IN (
		SELECT approval_step_id, layout_type
		  FROM approval_step
		 START WITH approval_step_id = in_approval_step_id
	   CONNECT BY PRIOR approval_step_id = parent_step_id
	     ORDER BY LEVEL DESC -- do from bottom up since we might delete approval steps
	)
	LOOP	
		-- check if this region / approval step is in use in the value table	
		UPDATE pending_val
		   SET approval_step_id = null -- set to unapproved
		 WHERE pending_region_id = in_pending_region_id
		   AND approval_step_id = r.approval_step_id
		   AND (val_number IS NOT NULL OR val_string IS NOT NULL);		   
		-- MUST come straight after UPDATE statement
		IF in_ignore_warnings = 0 AND SQL%ROWCOUNT > 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Values are present for this region at approval step id '||r.approval_step_id);
		END IF;
		
		UPDATE pending_val
		   SET approval_step_id = null -- set to unapproved
		 WHERE pending_region_id = in_pending_region_id
		   AND approval_step_id = r.approval_step_id
		   AND (val_number IS NULL AND val_string IS NULL);
		   
		FOR rs IN (
			SELECT approval_step_Id, sheet_key 
			  FROM APPROVAL_STEP_SHEET
			 WHERE approval_step_id = r.approval_step_id
			   AND pending_region_id = in_pending_region_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
		
		DELETE FROM APPROVAL_STEP_REGION
		 WHERE approval_step_id = r.approval_step_id
		   AND pending_region_id = in_pending_region_id;
		
		IF r.layout_type in (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;

		
		-- if this is the only region in the approval step then we're going to 
		-- want to delete the approval step
		SELECT COUNT(*) 
		  INTO v_cnt
		  FROM approval_step_region
		 WHERE approval_step_id = r.approval_step_id;
		
		IF v_cnt = 0 THEN
			INTERNAL_DeleteApprovalStep(r.approval_step_id);
		END IF;
	END LOOP;
	
	
	-- if there is no longer in any approval step using the region then delete from pending_val
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM approval_step_region
	 WHERE pending_region_id = in_pending_region_id;
	 
	IF v_cnt = 0 THEN
		DELETE FROM pending_val 
		 WHERE pending_region_id = in_pending_region_id;
	END IF;
	
	SELECT description INTO v_region FROM pending_region WHERE pending_region_id = in_pending_region_id;
	SELECT label INTO v_step FROM approval_step WHERE approval_step_id = in_approval_step_id;
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), in_approval_step_id, 'Removed region "{0}" from approval step "{1}"', v_region, v_step, in_ignore_warnings);
END;


PROCEDURE MergeApprovalRegions(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
    in_merge_to_region_id		IN	pending_region.pending_region_id%TYPE
)
AS
	v_cnt			NUMBER(10);
	v_is_straight	NUMBER(10);
BEGIN
	-- check it's a straight chain (number of items == max depth)
	SELECT CASE WHEN MAX(LEVEL) = COUNT(*) THEN 1 ELSE 0 END 
	  INTO v_is_straight
	  FROM approval_step
	 START WITH approval_step_id = in_approval_step_id
	CONNECT BY PRIOR approval_step_id = parent_step_id;

	IF v_is_straight = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'You can only merge approval regions if the chain descends without splitting');
	END IF;
	
	
	-- check that the regions actually rollup to the region id we're being asked to merge to all the way down the chain
	-- e.g. EU => DE,FR => East Germany, West Germany should fail trying to merge DE + FR into Europe
	 SELECT COUNT(*) 
	   INTO v_cnt
	   FROM (
		SELECT parent_region_id -- we use parent_region_id, NOT rolls_up_to_region_id because for 1:EU => 2:FR(1),3:DE(1) => 2:FR(2),3:DE(3) [region_id:region(rolls_up_to_region_id)]
		  FROM approval_step aps, approval_step_region apsr, pending_region pr
		 WHERE aps.approval_step_id = apsr.approval_step_id
		   AND apsr.pending_region_id = pr.pending_region_id
		 START WITH aps.approval_step_id = in_approval_step_id
		   AND apsr.rolls_up_to_region_id = in_merge_to_region_id
	   CONNECT BY PRIOR aps.approval_step_id = aps.parent_step_id
		   AND PRIOR apsr.pending_region_id = apsr.rolls_up_to_region_id
		 GROUP BY parent_region_id
	 );
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Approval step '||in_approval_step_id||' does not contain regions which roll up to region id '||in_merge_to_region_id);
	ELSIF v_cnt > 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Approval step '||in_approval_step_id||' or descendants split into child regions: try merging lower down the chain');
	END IF;
	
	-- Check to see if there are values for this or child regions.
	-- We just need to check the top step since we know that the chain 
	-- is straight and the regions are the same all the way down.
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM approval_step_region apsr, pending_val pv
	 WHERE apsr.approval_step_id = in_approval_Step_id 
	   AND pv.pending_region_id = apsr.pending_region_id;
	
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot merge regions as values exist');
		-- TODO: at some point, offer the facility to auto aggregate the values?
		-- would need to be careful since not everything aggregates via SUM, e.g.
		-- 'Do you have a policy on X' would fail.
	END IF;
		
	-- ok, actually doing this is pretty easy!! (now we've checked it's possible)
	FOR r IN (
		SELECT approval_step_id, layout_type
		  FROM approval_step
		 START WITH approval_step_id = in_approval_step_id
		CONNECT BY PRIOR approval_step_id = parent_step_id
	)
	LOOP
		-- fix up approval_step_sheets
		FOR rs IN (
			SELECT approval_step_id, sheet_key
			  FROM approval_step_sheet
			 WHERE approval_step_id = r.approval_step_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
		
		DELETE FROM approval_step_region 
	     WHERE approval_step_id = r.approval_step_id;
	     
	    INSERT INTO approval_step_region
	    	(approval_step_id, pending_region_id, rolls_up_to_region_id) 
	    VALUES 
	    	(r.approval_step_id, in_merge_to_region_id, in_merge_to_region_id);
	    	
	    CreateApprovalStepSheetsForReg(r.approval_step_id, r.layout_type, in_merge_to_region_id);

	    IF r.layout_type in (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
	END LOOP;
END;

PROCEDURE GetWhatCannotBeSubdelegated(
    in_approval_step_Id     IN  approval_step.approval_step_id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
)
AS
    v_pending_dataset_Id    pending_dataset.pending_dataset_id%TYPE;
BEGIN
    SELECT pending_dataset_id
      INTO v_pending_dataset_id
      FROM approval_step
     WHERE approval_step_Id = in_approval_step_Id;
     
    OPEN out_cur FOR
      /*  -- everything that I MIGHT be able to subdelegate
        SELECT apsi.pending_ind_id, apschr.pending_region_id
          FROM approval_step_ind apsi, (
              SELECT pending_region_Id
                FROM pending_region pr 
               START WITH pending_region_id IN (
                   SELECT pending_region_id  
                     FROM approval_step_region 
                    WHERE approval_step_id = in_approval_step_id
              )
              CONNECT BY PRIOR pending_region_id = parent_region_id
          )apschr
         WHERE apsi.approval_step_Id = in_approval_step_id
         MINUS */
        -- everything that I CAN'T subdelegate
        -- WHERE I am IN a route up a tree, get the whole path
         SELECT lr.pending_ind_id, fr.pending_region_id
           FROM (
                SELECT apsi.pending_ind_id, rr.leaf_region_id
                  FROM approval_step aps, approval_step_region apsr, approval_step_ind apsi, (			
                    -- gets the route up the region tree fOR every leaf node
                    SELECT pr.pending_region_id, connect_by_root pending_region_id leaf_region_id
                      FROM pending_region  pr
                     START WITH pending_region_id IN (
                           -- get all leaf nodes
                           SELECT pending_region_id  
                             FROM pending_region
                            WHERE pending_dataset_Id = v_pending_dataset_id
                              AND connect_by_isleaf = 1
                              AND app_sid = SYS_CONTEXT('SECURITY','APP')
                            START WITH parent_region_id IS NULL
                          CONNECT BY PRIOR pending_region_id = parent_region_id
                        )
                    CONNECT BY PRIOR parent_region_id = pending_region_id
                  ) rr
                 WHERE aps.parent_step_id = in_approval_step_id
                   AND aps.approval_step_id = apsi.approval_step_id
                   AND aps.approval_step_id = apsr.approval_step_id
                   AND apsr.pending_region_id = rr.pending_region_id -- WHERE our region is IN a route up the tree
          )lr, (			
                -- gets the route up the region tree fOR every leaf node
                SELECT pr.pending_region_id, connect_by_root pending_region_id leaf_region_id
                  FROM pending_region  pr
                 START WITH pending_region_id IN (
                       -- get all leaf nodes
                       SELECT pending_region_id  
                         FROM pending_region
                        WHERE pending_dataset_Id = v_pending_dataset_id
                          AND connect_by_isleaf = 1
                          AND app_sid = SYS_CONTEXT('SECURITY','APP')
                        START WITH parent_region_id IS NULL
                      CONNECT BY PRIOR pending_region_id = parent_region_id
                 )
                CONNECT BY PRIOR parent_region_id = pending_region_id
         ) fr
         WHERE lr.leaf_region_id = fr.leaf_region_id;
END;

PROCEDURE SubdivideApprovalRegion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_child_region_id		IN	pending_region.pending_region_id%TYPE
)
AS
	v_parent_approval_step_id	approval_step.approval_step_id%TYPE;
	v_current_parent_id			NUMBER(10);
	v_parent_dataset_id			NUMBER(10);
    v_existing_value_cnt		NUMBER(10);
    v_cnt						NUMBER(10);
	v_parent_region_id	        pending_region.pending_region_id%TYPE;
BEGIN

	---------------------------------------------
	-- NOW SORT OUT THIS PARTICULAR APPROVAL STEP
	-- AND FIGURE OUT PARENT_REGION_ID
	---------------------------------------------
	 SELECT parent_step_id 
	   INTO v_parent_approval_step_id
	   FROM approval_step
	  WHERE approval_step_id = in_approval_step_id;
	
	-- check parent region is in parent approval step
	-- (if null, then at top of tree so we don't care)
	IF v_parent_approval_step_id IS NOT NULL THEN
        -- this will always return one or zero rows, because 
        -- you can't have two regions from parent/child pending_regions
        -- assigned to the same approval_step
        BEGIN
            SELECT pending_region_Id 
              INTO v_parent_region_id
              FROM (
                SELECT pending_region_Id 
                  FROM pending_region 
                 START WITH pending_region_id = in_child_region_id
               CONNECT BY PRIOR parent_region_id = pending_region_id
             INTERSECT
                SELECT pending_region_id
                  FROM approval_step_region
                 WHERE approval_step_id = v_parent_approval_step_id
               );
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- no intersection, therefore not in parent approval step
                RAISE_APPLICATION_ERROR(-20001, 'Region '||in_child_region_id||' is not a child of any region in parent approval step '||v_parent_approval_step_id);
        END;
	END IF;

    -- do we need to do anything?
    IF v_parent_region_id = in_child_region_id THEN
        RETURN; -- same!
    END IF;
    
    -- does the child_region_id already exist at this step?	
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM approval_step_region
	 WHERE approval_step_id = in_approval_step_id
	   AND pending_region_id = in_child_region_id;
	   
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Child region '||in_child_region_id||' already exists at approval step '||in_approval_step_id);
	END IF;
	
	---------------------------------------
	-- THEN DEAL WITH PENDING_REGION TABLE
	---------------------------------------
	-- There might be nothing to do here if it's already been subdelegated etc
	-- but we must check anyway
	
	-- has this already been sub divided?
    BEGIN 
        SELECT parent_region_id, pending_dataset_id
          INTO v_current_parent_id, v_parent_dataset_id
          FROM PENDING_REGION pr, APPROVAL_STEP_REGION apsr
         WHERE pr.pending_region_id = in_child_region_id
           AND pr.pending_region_id = apsr.pending_region_id
           AND apsr.approval_step_Id = in_approval_step_Id;
           
        -- this node has a parent and it's different to the one we're trying to assign!
        -- already subdelegated
        RAISE_APPLICATION_ERROR(-20001, 'Region '||in_child_region_id||' has already been subdelegated underneath pending region id '||v_current_parent_id||' so cannot be placed under '||v_parent_region_id);

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- all ok
            NULL;
    END;
	
	-- delete any values with no information attached to them prior to checking to 
	-- see if values are getting in the way that might block this.
	-- We ignore comments and variances since the user can't delete these to rectify
	-- the problem. Probably we shouldn't delete comments...
	FOR r IN (
		SELECT pv.pending_val_id
	      FROM PENDING_VAL pv, APPROVAL_STEP_IND apsi, PENDING_VAL_FILE_UPLOAD pvfu
	     WHERE pending_region_id = v_parent_region_id
	       AND pv.pending_ind_id = apsi.pending_ind_id
	       AND apsi.approval_step_id = in_approval_step_id
	       AND pv.pending_val_id = pvfu.pending_val_id(+) -- check file uploads
	       AND pv.val_number IS NULL -- null numeric value
	       AND pv.val_string IS NULL -- null string value
	       AND pvfu.pending_val_id IS NULL -- no file uploads
	)
	LOOP
		INTERNAL_DeleteVal(r.pending_val_id);
	END LOOP;
	
	-- do values already exist for this region and for indicators present at this approval_step?
	SELECT COUNT(*)
      INTO v_existing_value_cnt
      FROM pending_val pv, approval_step_ind apsi
     WHERE pending_region_id = v_parent_region_id
       AND pv.pending_ind_id = apsi.pending_ind_id
       AND apsi.approval_step_id = in_approval_step_id;
	IF v_existing_value_cnt > 0 THEN
    	RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CANNOT_SUBDIVIDE_REGION, 'Cannot subdivide region id '||v_parent_region_id||' for approval step ('||in_approval_step_id||') because values already exist for indicators present at this step');
    END IF;

	-- go through this (and all child approval steps) rearranging things
	FOR r in (
		SELECT approval_step_id, layout_type
		  FROM approval_step
		  START WITH approval_step_id = in_approval_Step_id
		CONNECT BY PRIOR approval_step_id = parent_step_id
		)
	LOOP
		-- fix up approval_step_sheets
		FOR rs IN (
			SELECT approval_step_id, sheet_key
			  FROM approval_Step_Sheet
			 WHERE approval_Step_id = r.approval_step_Id
			   AND pending_region_id = v_parent_region_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
	
		DELETE FROM approval_step_region 
		 WHERE approval_step_id = r.approval_step_id
		   AND pending_region_id = v_parent_region_id;
		   
		INSERT INTO approval_step_region 
			(approval_Step_id, pending_region_id, rolls_up_to_region_id)
		VALUES 
			(r.approval_step_id, in_child_region_id, v_parent_region_id);
			
		CreateApprovalStepSheetsForReg(r.approval_step_id, r.layout_type, in_child_region_id);

		-- update max values
		IF r.layout_type in (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
	END LOOP;
END;

PROCEDURE GetOrSetPendingValId(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_pending_val_id		OUT	pending_val.pending_val_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	-- BE VERY CAREFUL ABOUT OUR LOCKING - UPSERT APPROACH SHOULD BE OK??
	
	-- check ind, region, period are all in the same dataset for this 
	SELECT COUNT(*)  
	  INTO v_cnt
	  FROM (
		SELECT pending_dataset_id  
		  FROM PENDING_IND 
		 WHERE pending_ind_id = in_pending_ind_id
	 INTERSECT
		SELECT pending_dataset_id
		  FROM PENDING_REGION
		 WHERE pending_region_id = in_pending_region_id
	 INTERSECT 
	    SELECT pending_dataset_id
		  FROM PENDING_PERIOD 
		 WHERE pending_period_id = in_pending_period_id
	   );
	 IF v_cnt != 1 THEN
	 	RAISE_APPLICATION_ERROR(-20001, 'Indicator '||in_pending_ind_id||', region '||in_pending_region_id||
	 		' and period '||in_pending_period_id||' are from different pending datasets');
	 END IF;
	 
	 
	BEGIN
		INSERT INTO PENDING_VAL 
			(pending_val_Id, pending_ind_id, pending_region_id, pending_period_id, approval_step_id)
		VALUES
			(pending_val_id_seq.nextval, in_pending_ind_id, in_pending_region_id, in_pending_period_id, in_approval_step_id)
		RETURNING pending_val_id INTO out_pending_val_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT pending_val_id
			  INTO out_pending_val_id
			  FROM pending_val
			 WHERE pending_ind_id = in_pending_ind_id
			   AND pending_region_id = in_pending_region_id
			   AND pending_period_id = in_pending_period_id;
	END;
END;


PROCEDURE GetOrSetPendingVal(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(in_act_id, in_approval_step_id, in_pending_ind_id,
		in_pending_region_id, in_pending_period_id, v_id);
	OPEN out_cur FOR
		SELECT pv.pending_val_Id, pv.pending_ind_id, pv.pending_region_id, pp.pending_period_id, 
			   pp.start_dtm, pp.end_dtm, pv.val_number, pv.val_string, pv.approval_step_id,
			   pv.from_val_number, pv.from_measure_conversion_id, pi.maps_to_ind_sid, pv.note,
			   pvv.explanation variance_explanation, pv.action,
			   (SELECT COUNT(*) FROM pending_val_file_upload pvfu WHERE pvfu.pending_val_id = pv.pending_val_id) file_upload_count
		  FROM pending_val pv, pending_period pp, pending_ind pi, pending_val_variance pvv
		 WHERE pv.pending_ind_id = pi.pending_ind_id
		   AND pv.pending_period_id = pp.pending_period_id
		   AND pv.pending_val_id = v_id
		   AND pv.pending_val_Id = pvv.pending_val_id(+);		  
END;


PROCEDURE SetValueNote(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_note							IN	pending_val.note%TYPE
)
AS	
	v_pending_val_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	UPDATE pending_val 
	   SET note = in_note
	 WHERE pending_val_id = v_pending_val_id;
END;


PROCEDURE SetStringValue(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_val_string					IN	pending_val.val_string%TYPE
)
AS
	v_pending_val_id	pending_val.pending_val_id%TYPE;
	v_old_val_string	pending_val.val_string%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	SELECT val_string
	  INTO v_old_val_string
	  FROM pending_val
	 WHERE pending_val_id = v_pending_val_id;

    IF null_pkg.ne(v_old_val_string, in_val_string) THEN
        IF in_val_string IS NULL THEN
            pending_pkg.AddToPendingValLog(in_act_id, v_pending_val_id, 'Value set to blank');
        ELSE
            pending_pkg.AddToPendingValLog(in_act_id, v_pending_val_id, 'Value set to ''{0}''', in_val_string);
        END IF;
	END IF;
		
	UPDATE pending_val 
	   SET val_string = in_val_string,
		   merged_state = CASE merged_state WHEN 'S' THEN 'U' ELSE merged_state END
	 WHERE pending_val_id = v_pending_val_id;
END;

PROCEDURE SetVarianceExplanation(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_note							IN	pending_val.note%TYPE
)
AS
BEGIN
	NULL;
END;

PROCEDURE AddToPendingValLog(
	in_act_id		    IN	security_pkg.T_ACT_ID,
    in_pending_val_id   IN  pending_val.pending_val_Id%TYPE,
    in_description      IN  pending_val_Log.DESCRIPTION%TYPE,
    in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL
)
AS
    v_user_sid          security_pkg.T_SID_ID;
    v_issue_id          issue.issue_id%TYPE;
	v_issue_log_id      issue_log.issue_log_id%TYPE;
	v_issue_log_count	NUMBER;
    CURSOR c IS
		SELECT i.issue_id 
	      FROM issue i, issue_pending_val ipv, pending_val pv
	     WHERE pv.pending_val_id = in_pending_val_Id
	       AND pv.pending_ind_Id = ipv.pending_ind_Id
	       AND pv.pending_region_id = ipv.pending_region_id
	       AND pv.pending_period_Id = ipv.pending_period_Id
	       AND ipv.issue_pending_val_id = i.issue_pending_val_id;
BEGIN
	-- get the user sid for any log writing
	user_pkg.GetSid(in_act_id, v_user_sid);

    INSERT INTO pending_val_log
        (pending_val_log_id, pending_val_Id, set_dtm, set_by_user_sid, description, param_1, param_2, param_3)
    VALUES
        (pending_val_log_id_seq.nextval, in_pending_val_id, SYSDATE,  v_user_sid, in_description, in_param_1, in_param_2, in_param_3);
    
	-- if there has been, or is an issue open then log this info against the issue too.
	-- We used to do this with a UNION in issue_pkg.INTERNAL_GetIssueLogEntries but too many
	-- things needed to check for things in here that it made more sense to write it straight 
    OPEN c;
    FETCH c INTO v_issue_Id;
    IF c%FOUND THEN
		-- TODO: consider calling AddLogEntry, calling this would potentially reopen issues, which doesn't happen here
		INSERT INTO ISSUE_LOG 
			(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated,
			param_1, param_2, param_3)
		VALUES
			(issue_log_id_seq.nextval, v_issue_id, in_description, v_user_sid, SYSDATE, 1,
			in_param_1, in_param_2, in_param_3)
			RETURNING issue_log_id INTO v_issue_log_id;
			
		SELECT COUNT(*)
		  INTO v_issue_log_count
		  FROM issue_log
		 WHERE issue_id = v_issue_id;
			 
		UPDATE issue
		   SET first_issue_log_id = CASE WHEN v_issue_log_count = 1 THEN v_issue_log_id ELSE first_issue_log_id END,
			   last_issue_log_id = v_issue_log_id
		 WHERE issue_id = v_issue_id
		   AND app_sid = security_pkg.GetApp;
	END IF;
	CLOSE c;
	    
END;


PROCEDURE GetPendingValLog(
	in_act_id		        IN	security_pkg.T_ACT_ID,
    in_pending_ind_id       IN  pending_val.pending_ind_Id%TYPE,
    in_pending_region_id    IN  pending_val.pending_region_Id%TYPE,
    in_pending_period_id    IN  pending_val.pending_period_Id%TYPE,
    out_cur                 OUT SYS_REFCURSOR
)
AS
    v_now DATE := SYSDATE;
BEGIN
    OPEN out_cur FOR
        SELECT set_dtm, pvl.set_by_user_sid, cu.full_name, cu.user_name, cu.email, pvl.description, param_1, param_2, param_3, v_now now_dtm
          FROM pending_val_log pvl, pending_val pv, csr_user cu
         WHERE pvl.pending_val_id = pv.pending_val_id
           AND pvl.set_by_user_sid = cu.csr_user_sid
           AND pv.pending_ind_id = in_pending_ind_id
           AND pv.pending_region_id = in_pending_region_id
           AND pv.pending_period_id = in_pending_period_id
         ORDER BY pending_val_log_Id DESC;
END;

-- TODO: explanation of changes
PROCEDURE SetValue(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_from_val_number				IN	pending_val.from_val_number%TYPE,
	in_from_measure_conversion_id	IN	pending_val.from_measure_conversion_id%TYPE,
	in_write_sc_jobs				IN	NUMBER, -- write stored calc recalc jobs? 1 = true, 0 = false
	out_pending_val_Id				OUT	pending_val.pending_val_id%TYPE
)
AS
	ex_val_number					pending_val.val_number%TYPE;
	ex_from_val_number			    pending_val.from_val_number%TYPE;
	ex_from_measure_conversion_id   pending_val.from_measure_conversion_id%TYPE;
    ex_rid                          ROWID;
	v_cnt	            			NUMBER(10);
	v_element_type					pending_ind.element_type%TYPE;
	v_custom_field          		MEASURE.CUSTOM_FIELD%TYPE;
	v_enum_string_value     		VARCHAR2(1024);
	v_factor_a                		measure_conversion.a%type;
	v_factor_b                		measure_conversion.b%type;
	v_factor_c                		measure_conversion.c%type;
	v_factor_description    		measure_conversion.description%type;
	v_ind_sid						security_pkg.T_SID_ID;
	v_pending_dataset_Id			pending_dataset.pending_dataset_id%TYPE;
BEGIN
	-- BE VERY CAREFUL ABOUT OUR LOCKING - UPSERT APPROACH SHOULD BE OK??

	-- check ind, region, period are all in the same dataset for this 
	SELECT COUNT(*)  
	  INTO v_cnt
	  FROM (
		SELECT pending_dataset_id  
		  FROM PENDING_IND 
		 WHERE pending_ind_id = in_pending_ind_id
	 INTERSECT
		SELECT pending_dataset_id
		  FROM PENDING_REGION
		 WHERE pending_region_id = in_pending_region_id
	 INTERSECT 
	    SELECT pending_dataset_id
		  FROM PENDING_PERIOD 
		 WHERE pending_period_id = in_pending_period_id
	   );
	 IF v_cnt != 1 THEN
	 	RAISE_APPLICATION_ERROR(-20001, 'Indicator, region and period are from different pending datasets');
	 END IF;
	 
	-- get conversion factors
	SELECT NVL(NVL(mc.a, mcp.a), 1) factor_a, NVL(NVL(mc.b, mcp.b), 1) factor_b, NVL(NVL(mc.c, mcp.c), 0) factor_c, 
           NVL(mc.description, m.description) description, m.custom_field, pi.element_type
      INTO v_factor_a, v_factor_b, v_factor_c, v_factor_description, v_custom_field, v_element_type
      FROM pending_ind pi, pending_period pp, 
           measure m, measure_conversion mc, measure_conversion_period mcp
     WHERE pi.measure_sid = m.measure_sid
       AND m.measure_sid = mc.measure_sid(+)
       AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
       AND (pp.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
       AND (pp.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
       AND pi.pending_ind_id = in_pending_ind_id
       AND pp.pending_period_id = in_pending_period_id
       AND NVL(mc.measure_conversion_id(+), -1) = NVL(in_from_measure_conversion_id,-1);

	IF v_element_type = csr_data_pkg.ELEMENT_TYPE_DATE THEN
		-- not an enum but...
		-- also not very well interationalised but...
		v_enum_string_value := TO_CHAR(DATE '1899-12-30' + in_from_val_number, 'yyyy-mm-dd');
	ELSIF v_custom_field = 'x' THEN
        SELECT DECODE(in_from_val_number, 1, 'Yes', 0, 'No', 'Unknown') 
          INTO v_enum_string_value 
          FROM DUAL;
    ELSIF v_custom_field IS NOT NULL THEN
        BEGIN
            SELECT item
              INTO v_enum_string_value
              FROM TABLE(utils_pkg.SplitString( REPLACE(v_custom_field, CHR(13), ''), CHR(10))) 
             WHERE pos = in_from_val_number;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_enum_string_value := 'Unknown';
        END;
    END IF;
		
	-- upsert...
	BEGIN
		INSERT INTO PENDING_VAL 
			(pending_val_id, pending_ind_id, pending_region_id, pending_period_id, 
			 approval_step_id, val_number, val_string, from_val_number, from_measure_conversion_id, action)
		VALUES 
			(pending_val_id_seq.NEXTVAL, in_pending_ind_id, in_pending_region_id, in_pending_period_id, 
			 in_approval_step_id, v_factor_a * POWER(in_from_val_number, v_factor_b) + v_factor_c,
			 null, in_from_val_number, in_from_measure_conversion_id, 'S')
		RETURNING pending_val_id, val_number, from_val_number, from_measure_conversion_id
	         INTO out_pending_val_Id, ex_val_number, ex_from_val_number, ex_from_measure_conversion_id;
	         
        -- log the change into the history table
        IF in_from_val_number IS NULL THEN
            pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to blank');
        ELSIF v_enum_string_value IS NOT NULL THEN
            pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to ''{0}''', v_enum_string_value );
        ELSE
            pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to {0:N} {1}', in_from_val_number, v_factor_description);
        END IF;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
             SELECT pending_val_id, val_number, from_val_number, from_measure_conversion_id, rowid
               INTO out_pending_val_Id, ex_val_number, ex_from_val_number, ex_from_measure_conversion_id, ex_rid
               FROM pending_val
              WHERE pending_ind_id = in_pending_ind_id  
			    AND pending_region_id = in_pending_region_id  
			    AND pending_period_id = in_pending_period_id
			    FOR UPDATE;
             
 			UPDATE pending_val
  			   SET approval_step_id = in_approval_step_id,
 			   	   val_number = v_factor_a * POWER(in_from_val_number, v_factor_b) + v_factor_c,
 			   	   from_val_number = in_from_val_number,
 			   	   from_measure_conversion_id = in_from_measure_conversion_id,
			       merged_state = CASE merged_state WHEN 'S' THEN 'U' ELSE merged_state END
			 WHERE ROWID = ex_rid;

            IF null_pkg.ne(ex_from_val_number, in_from_val_number) OR 
               null_pkg.ne(ex_from_measure_conversion_id, in_from_measure_conversion_id) THEN
               	
                -- log the change into the history table
                IF in_from_val_number IS NULL THEN
                    pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to blank');
                ELSIF v_enum_string_value IS NOT NULL THEN
                    pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to ''{0}''', v_enum_string_value );
                ELSE
                    pending_pkg.AddToPendingValLog(in_act_id, out_pending_val_id, 'Value set to {0:N} {1}', in_from_val_number, v_factor_description);
                END IF;
           END IF;
	END;

	-- write stored calc jobs (recalc jobs get done via a trigger - PendingVal_WritePVCJob)
	IF in_write_sc_jobs = 1 THEN
		SELECT maps_to_ind_sid, pending_dataset_id
		  INTO v_ind_sid, v_pending_Dataset_id
		  FROM pending_ind
		 WHERE pending_ind_id = in_pending_ind_id;	   
		 
		IF v_ind_sid IS NOT NULL THEN 
			INSERT INTO pvc_stored_calc_job
				(pending_Dataset_id, calc_pending_ind_id, pending_region_id, pending_period_id, processing)
				SELECT pi.pending_dataset_id, cpi.pending_ind_id, pv.pending_region_id, pv.pending_period_id, 0
				  FROM TABLE(calc_pkg.GetAllCalcsUsingIndAsTable(v_ind_sid))i, pending_ind cpi, pending_ind pi, pending_val pv
				 WHERE i.dep_ind_sid = cpi.maps_to_ind_sid 
				   AND v_ind_sid = pi.maps_to_ind_sid 
				   AND pi.pending_ind_id = pv.pending_ind_id 
				   AND pv.pending_region_id = in_pending_region_id
				   AND pv.pending_period_id = in_pending_period_Id 
			 MINUS
			SELECT pending_dataset_Id, calc_pending_ind_id, pending_region_id, pending_period_id, processing
		      FROM pvc_stored_calc_job
	 		 WHERE processing = 0
			   AND pending_dataset_id = v_pending_dataset_id;
		END IF;
	END IF;
END;

PROCEDURE GetStoredCalcJobs(
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	UPDATE pvc_stored_calc_job
	   SET processing = 1
	 WHERE pending_dataset_id IN (
	 	SELECT pending_dataset_Id
	 	  FROM pending_dataset
	 	 WHERE app_sid = in_app_sid
	);
	
	OPEN out_cur FOR
		SELECT cirj.pending_dataset_id, calc_pending_ind_id, ci.calc_start_dtm_adjustment,pending_region_id, pp.pending_period_id, start_dtm, end_dtm,
			MIN(start_dtm) OVER (PARTITION BY cirj.pending_dataset_id, calc_pending_ind_id) min_start_dtm_for_all_regions,
			MAX(end_dtm) OVER (PARTITION BY cirj.pending_dataset_id, calc_pending_ind_id) max_end_dtm_for_all_regions
		  FROM pvc_stored_calc_job cirj, pending_period pp, pending_ind pi, ind ci
		 WHERE cirj.pending_period_id = pp.pending_period_id
		   AND ci.ind_sid = pi.maps_to_ind_sid
		   AND pi.pending_ind_id = calc_pending_ind_id
		   AND ci.app_sid = in_app_sid
		   AND processing = 1
		 GROUP BY cirj.pending_dataset_id, calc_pending_ind_id, pending_region_id, ci.calc_start_dtm_adjustment, pp.pending_period_id, start_dtm, end_dtm
		 ORDER BY cirj.pending_dataset_id, calc_pending_ind_id, pending_region_id, start_dtm, end_dtm;
END;

PROCEDURE GetStoredCalcJobsForPD(
	in_pending_dataset_id	IN	pending_dataset.pending_dataset_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	UPDATE pvc_stored_calc_job
	   SET processing = 1
	 WHERE pending_Dataset_id = in_pending_dataset_Id;

	OPEN out_cur FOR
		SELECT cirj.pending_dataset_id, calc_pending_ind_id, ci.calc_start_dtm_adjustment,pending_region_id, pp.pending_period_id, start_dtm, end_dtm,
			MIN(start_dtm) OVER (PARTITION BY cirj.pending_dataset_id, calc_pending_ind_id) min_start_dtm_for_all_regions,
			MAX(end_dtm) OVER (PARTITION BY cirj.pending_dataset_id, calc_pending_ind_id) max_end_dtm_for_all_regions
		  FROM pvc_stored_calc_job cirj, pending_period pp, pending_ind pi, ind ci
		 WHERE cirj.pending_period_id = pp.pending_period_id
		   AND ci.ind_sid = pi.maps_to_ind_sid
		   AND pi.pending_ind_id = calc_pending_ind_id
		   AND processing = 1
		   AND cirj.pending_dataset_Id = in_pending_dataset_id
		 GROUP BY cirj.pending_dataset_id, calc_pending_ind_id, pending_region_id, ci.calc_start_dtm_adjustment, pp.pending_period_id, start_dtm, end_dtm
		 ORDER BY cirj.pending_dataset_id, calc_pending_ind_id, pending_region_id, start_dtm, end_dtm;
END;

PROCEDURE DeleteProcessedCalcIndJobs(
	in_calc_pending_ind_id		IN	pending_ind.pending_ind_id%TYPE
)
AS
BEGIN		
	-- we only delete jobs that we've been processing 
	-- (new jobs might have been added whilst we were doing our sums)
	DELETE FROM PVC_stored_calc_job 
	 WHERE calc_pending_ind_id = in_calc_pending_ind_id AND PROCESSING = 1;
END;



PROCEDURE GetValue(
	in_act_Id			IN	security_pkg.T_ACT_ID,
	in_pending_val_Id	IN	pending_val.pending_val_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR		
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT pv.pending_val_Id, pv.pending_ind_id, pv.pending_region_id, pp.pending_period_id, 
			pp.start_dtm, pp.end_dtm, pv.val_number, pv.val_string, pv.approval_step_id,
			pv.from_val_number, pv.from_measure_conversion_id, pi.maps_to_ind_sid 
		  FROM pending_val pv, pending_period pp, pending_ind pi
		 WHERE pending_val_id = in_pending_val_id
		   AND pv.pending_period_id = pp.pending_period_id
		   AND pv.pending_ind_id = pi.pending_ind_id;
END;


PROCEDURE AddFileFromCache(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_cache_key		IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_reporting_period_sid	security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT reporting_period_sid
	  INTO v_reporting_period_sid
	  FROM pending_val pv, pending_ind pi, pending_dataset pd
	 WHERE pv.pending_val_id = in_pending_val_id
	   AND pv.pending_ind_id = pi.pending_ind_id
	   AND pi.pending_dataset_id = pd.pending_dataset_id;
    
    fileupload_pkg.CreateFileUploadFromCache(in_act_id, v_reporting_period_sid, in_cache_key, out_file_upload_sid);
    	
	--user_pkg.GetSid(in_act_id, v_user_sid);
	INSERT INTO pending_val_file_upload
		(pending_val_id, file_upload_sid)
	VALUES 
		(in_pending_val_id, out_file_upload_sid);
		
END;


PROCEDURE AddFileFromCache(		  
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%type,
	out_file_upload_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_pending_val_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	AddFileFromCache(in_act_id, v_pending_val_id, in_cache_key, out_file_upload_sid);
END;	

PROCEDURE AddExistingFile(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_file_upload_sid	IN	security_pkg.T_SID_ID
)
AS
	v_reporting_period_sid		security_pkg.T_SID_ID;
	v_file_upload_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- check that the file's parentIsd matches the reporting_period_sid of the value
	SELECT reporting_period_sid
	  INTO v_reporting_period_sid
	  FROM pending_val pv, pending_ind pi, pending_dataset pd
	 WHERE pv.pending_val_id = in_pending_val_id
	   AND pv.pending_ind_id = pi.pending_ind_id
	   AND pi.pending_dataset_id = pd.pending_dataset_id;
	   
	SELECT parent_sid   
	  INTO v_file_upload_parent_sid
	  FROM file_upload
	 WHERE file_upload_sid = in_file_upload_sid;
	 
	IF v_reporting_period_sid != v_file_upload_parent_sid THEN
	  	RAISE_APPLICATION_ERROR(-20001, 'Mismatched file parent sid and reporting period sid');
	END IF;
	
	INSERT INTO pending_val_file_upload
		(pending_val_id, file_upload_sid)
	VALUES 
		(in_pending_val_id, in_file_upload_sid);	
END;


PROCEDURE AddExistingFile(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
)
AS
	v_pending_val_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	AddExistingFile(in_act_id, v_pending_val_id, in_file_upload_sid);
END;

PROCEDURE RemoveFile(		  
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_file_upload_sid	IN	security_pkg.T_SID_ID
)
AS
	v_reporting_period_sid		security_pkg.T_SID_ID;
	v_file_upload_parent_sid	security_pkg.T_SID_ID;
BEGIN
	DELETE FROM pending_val_file_upload
	 WHERE pending_val_id = in_pending_val_id
	   AND file_upload_sid = in_file_upload_sid;
END;

PROCEDURE RemoveFile(		  
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_val.pending_period_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
)
AS
	v_pending_val_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	RemoveFile(in_act_id, v_pending_val_id, in_file_upload_sid);
END;

PROCEDURE CreateInd(
	in_act_id					IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_pending_dataset_id		IN	pending_ind.pending_dataset_id%TYPE,
	in_description				IN	pending_ind.description%TYPE,
	in_val_mandatory			IN	pending_ind.val_mandatory%TYPE			DEFAULT 0,
	in_note_mandatory			IN	pending_ind.note_mandatory%TYPE			DEFAULT 0 ,
	in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE	DEFAULT 0,
	in_measure_sid				IN	security_pkg.T_SID_ID					DEFAULT null,
	in_parent_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_element_type				IN	pending_ind.element_type%TYPE,
	in_maps_to_ind_sid			IN	security_pkg.T_SID_ID					DEFAULT null,
	in_tolerance_type			IN  pending_ind.tolerance_type%type			DEFAULT 0,
    in_pct_upper_tolerance		IN  pending_ind.pct_upper_tolerance%type	DEFAULT 1,
    in_pct_lower_tolerance		IN  pending_ind.pct_lower_tolerance%type	DEFAULT 1,
    in_format_xml				IN  pending_ind.format_xml%type				DEFAULT null,
    in_link_to_ind_id			IN  pending_ind.link_to_ind_id%type			DEFAULT null, -- ?? what does this do?
    in_read_only				IN  pending_ind.read_only%type				DEFAULT 0,
    in_info_xml					IN  pending_ind.info_xml%type				DEFAULT null,
    in_dp						IN  pending_ind.dp%type						DEFAULT 2,
    in_default_val_number		IN  pending_ind.default_val_number%type		DEFAULT null,
    in_default_val_string		IN  pending_ind.default_val_string%type		DEFAULT null,
    in_lookup_key				IN  pending_ind.lookup_key%type				DEFAULT null,
	out_pending_ind_id			OUT	pending_ind.pending_ind_id%TYPE
)
AS
	v_pos	NUMBER(10);
	v_measure_sid   security_pkg.T_SID_ID;
	v_dp	pending_ind.dp%TYPE;
BEGIN
    -- Make the new pending indicator be the last child of it's parent
	SELECT NVL(MAX(pos),0)+1
	  INTO v_pos
	  FROM pending_ind
	 WHERE pending_dataset_id = in_pending_dataset_id AND
	       parent_ind_id = in_parent_ind_id;
	 
	v_measure_sid := in_measure_sid;
	IF in_maps_to_ind_sid IS NOT NULL AND in_measure_sid IS NULL THEN
        -- default measure
        SELECT measure_sid
          INTO v_measure_sid
          FROM IND
         wHERE IND_SID = in_maps_to_ind_sid;
	END IF;

	v_dp := in_dp;
	IF v_measure_sid IS NOT NULL THEN
		SELECT scale
		  INTO v_dp
		  FROM measure
		 WHERE measure_sid = v_measure_sid;
	END IF;
	
	INSERT INTO pending_ind (
		pending_ind_id, pending_dataset_id, description, 
		val_mandatory, note_mandatory, file_upload_mandatory, measure_sid, parent_ind_id, 
		pos, element_type, tolerance_type, pct_upper_tolerance, 
		pct_lower_tolerance, format_xml, maps_to_ind_sid,
		link_to_ind_id, read_only, info_xml, dp, 
		default_val_number, default_val_string, lookup_key
	) VALUES (
		pending_ind_id_seq.nextval, in_pending_dataset_id, in_description,
		in_val_mandatory, in_note_mandatory, in_file_upload_mandatory, v_measure_sid, in_parent_ind_id,
		v_pos, in_element_type, in_tolerance_type, in_pct_upper_tolerance,
		in_pct_lower_tolerance, in_format_xml, in_maps_to_ind_sid,
		in_link_to_ind_id, in_read_only, in_info_xml, v_dp, 
		in_default_val_number, in_default_val_string, UPPER(in_lookup_key)
	) RETURNING pending_ind_id INTO out_pending_ind_id;
END;

PROCEDURE CreateInd(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_ind.pending_dataset_id%TYPE,
	in_description				IN	pending_ind.description%TYPE,
	in_val_mandatory			IN	pending_ind.val_mandatory%TYPE,
	in_note_mandatory			IN	pending_ind.note_mandatory%TYPE,
	in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE,
	in_measure_sid				IN	security_pkg.T_SID_ID,
	in_parent_ind_id			IN	pending_ind.pending_ind_id%TYPE,
	in_element_type				IN	pending_ind.element_type%TYPE,
	in_maps_to_ind_sid			IN	security_pkg.T_SID_ID,
	in_tolerance_type			IN  pending_ind.tolerance_type%type,
    in_pct_upper_tolerance		IN  pending_ind.pct_upper_tolerance%type,
    in_pct_lower_tolerance		IN  pending_ind.pct_lower_tolerance%type,
    in_format_xml				IN  pending_ind.format_xml%type,
    in_link_to_ind_id			IN  pending_ind.link_to_ind_id%type,
    in_read_only				IN  pending_ind.read_only%type,
    in_info_xml					IN  pending_ind.info_xml%type,
    in_dp						IN  pending_ind.dp%type,
    in_default_val_number		IN  pending_ind.default_val_number%type,
    in_default_val_string		IN  pending_ind.default_val_string%type,
    in_lookup_key				IN  pending_ind.lookup_key%type,
	out_cur						OUT	SYS_REFCURSOR
)
AS
    v_pending_ind_id  pending_ind.pending_ind_id%TYPE;
BEGIN
    CreateInd(in_act_id, in_pending_dataset_id, in_description, 
        in_val_mandatory, in_note_mandatory, in_file_upload_mandatory, in_measure_sid, 
        in_parent_ind_id, in_element_type, in_maps_to_ind_sid,
        in_tolerance_type, in_pct_upper_tolerance, in_pct_lower_tolerance,
        in_format_xml, in_link_to_ind_id, in_read_only, in_info_xml, 
        in_dp, in_default_val_number, in_default_val_string, in_lookup_key, 
        v_pending_ind_id);
	GetInd(in_act_id, v_pending_ind_id, out_cur);
END;

PROCEDURE DeleteInd(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_ind_id				IN	pending_ind.pending_ind_id%TYPE,
	in_ignore_warnings				IN	NUMBER DEFAULT 0, 
	in_set_sheet_max_value_count	IN	NUMBER DEFAULT 1 -- faster if you set this to 0
)
AS
	v_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	-- TODO: what about if the values we're about to delete are associated
	-- with VAL source types?


	-- iterate through all children
	FOR r IN (
		SELECT pending_ind_id
		  FROM pending_ind
		 WHERE parent_ind_id = in_pending_ind_id
	)
	LOOP
		DeleteInd(in_act_id, r.pending_ind_id, in_ignore_warnings);
	END LOOP;
		 
	-- delete cached values
	DELETE FROM pending_val_cache WHERE pending_ind_id = in_pending_ind_id;
	DELETE FROM PVC_STORED_CALC_JOB WHERE calc_pending_ind_id = in_pending_ind_id;
	DELETE FROM PVC_REGION_RECALC_JOB WHERE pending_ind_id = in_pending_ind_id;

	-- delete all values 
	FOR r IN (
		SELECT pending_val_Id FROM pending_val WHERE pending_ind_Id = in_pending_ind_id
    )
    LOOP
		-- if we're in here at all, then there are values present,
		-- so barf (unless we're ignoring warnings)
		IF in_ignore_warnings = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Values are present for this indicator ('||in_pending_ind_id||')');		
		END IF;
		INTERNAL_DeleteVal(r.pending_val_id);
    END LOOP;
    

	-- delete this ind from approval steps
	FOR r IN (
		SELECT aps.approval_step_id, layout_type
		  FROM approval_step aps, approval_step_ind apsi
		 WHERE aps.approval_step_id = apsi.approval_step_id
		   AND apsi.pending_ind_id = in_pending_ind_id	
	)
	LOOP
		FOR rs IN (
			SELECT approval_step_id, sheet_key
			  FROM approval_step_sheet
			 WHERE pending_ind_id = in_pending_ind_id
			   AND approval_step_id = r.approval_step_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
		
		DELETE FROM approval_step_ind
	     WHERE pending_ind_id = in_pending_ind_id
	       AND approval_step_id = r.approval_step_id;
		
		IF r.layout_type IN (pending_pkg.LAYOUT_IND, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_IND_X_PERIOD) AND in_set_sheet_max_value_count = 1 THEN
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
	END LOOP;

   DELETE FROM PENDING_IND_ACCURACY_TYPE 
    WHERE pending_ind_id = in_pending_ind_id;
   
    /* Deleting approval step stops the dataset create/edit page form working, as it is normal for a 
       user to have approval steps before they have set up all the other items in the dataset.  
       Also it is somewhat unexpected behavior for the user to have their approval step vanish 
       when they do a unrelated task in the UI.   
    -- check (and remove) any now empty approval steps
    SELECT pending_dataset_id
      INTO v_dataset_id
      FROM pending_ind
     WHERE pending_ind_id = in_pending_ind_id;
    RemoveEmptyApprovalSteps(v_dataset_id);
    */
	DELETE FROM pvc_region_recalc_job
	 WHERE pending_ind_id = in_pending_ind_id;
	 
	DELETE FROM pending_ind 
	 WHERE pending_ind_id = in_pending_ind_id;
END;

PROCEDURE UNSEC_AddRegionToPending(
	in_region_sid	IN	security_pkg.T_SID_ID
)
AS
	v_region_root_sid	security_pkg.T_SID_ID;
BEGIN
	-- pull this out -- i.e. if this is the most common point in the structure
	-- then we're in trouble as it'll go round recloning the whole tree (i.e
	-- because there is no common point). In this situation we want to do nothing
	-- rather than inserting 20m rows like we had happen!!
	SELECT region_tree_root_sid 
	  INTO v_region_root_sid
	  FROM region_tree
	 WHERE app_sid = security_pkg.getApp
	   AND is_primary = 1;
	 
	-- the problem here is that this region's parent might not be in the pending_dataset, nor its parent etc.
	-- so, for all relevant pending_datasets (i.e. those valid for the current reporting period), we need to 
	-- see which ancestor of this region is in the pending_dataset, and then add the missing bits of hierarchy
	-- to the pending_region table.
	FOR r IN (
	    SELECT /*+ALL_ROWS*/ *
		  FROM (
			-- filter to just show the most relevant parent node
			SELECT x.*, ROW_NUMBER() OVER (PARTITION BY pending_dataset_id ORDER BY lvl DESC) rnx
			  FROM (          
				-- get the path up the region tree, finding mappings to _all_ pending datasets (hence cross join)
				SELECT r.*, pr.maps_to_region_sid, pds.pending_dataset_id, 
					LAG(maps_to_region_sid) OVER (PARTITION BY pds.pending_dataset_id ORDER BY r.rn) PRIOR_ROW_MAPS_TO_REGION_SID
				  FROM (
						-- get the path up the region tree
						SELECT region_sid, LEVEL lvl, PRIOR region_sid prior_region_sid,
							   r.description, r.parent_sid, rownum rn
						  FROM v$region r
						 START WITH region_sid = in_region_sid
					   CONNECT BY PRIOR parent_sid = region_sid AND region_sid != v_region_root_sid -- if this happens we're in trouble! (i.e. region_sid == v_region_root_sid)
					)r 
					CROSS JOIN customer c 
					JOIN pending_dataset pds 
						ON c.app_sid = pds.app_sid AND pds.reporting_period_sid = c.current_reporting_period_sid -- for current reporting period only
					LEFT JOIN pending_region pr 
						ON r.region_sid = pr.maps_to_region_sid  AND pds.pending_dataset_id = pr.pending_dataset_id
			  )x
			WHERE prior_row_maps_to_region_sid IS NULL -- means it exists already in the pending_Region table for this pending_dataset
		  )
		  WHERE rnx = 1
		    AND region_sid != in_region_sid
	)
	LOOP
		--security_pkg.debugmsg('have got '||r.region_sid||'='||r.description);
		-- copy this chunk
		FOR rr IN (
			-- go up to the point we just identified
			SELECT /*+ALL_ROWS*/ region_sid, parent_sid, description, -level rn
			  FROM v$region
			  	   START WITH region_sid =  in_region_sid
				   CONNECT BY PRIOR parent_sid = region_sid AND region_sid != r.region_sid
			 UNION ALL
			 -- go down from this region
			 SELECT region_sid, parent_sid, description, rn 
			   FROM (
				 SELECT /*+ALL_ROWS*/ region_sid, parent_sid, description, rownum rn
				   FROM v$region
				   		START WITH parent_sid =  in_region_sid
				 	    CONNECT BY PRIOR region_sid = parent_sid 
				   		ORDER SIBLINGS BY description
			 )
			 ORDER BY rn
		)
		LOOP
			--security_pkg.debugmsg('inserting ' ||rr.description||' root is ' ||v_region_root_sid||' sid is '||rr.region_sid);
			INSERT INTO pending_region (pending_region_id, parent_region_id, pending_dataset_id, maps_to_region_sid, description)
				SELECT /*+ALL_ROWS*/ pending_region_id_seq.nextval, pending_region_id, pending_dataset_id, rr.region_sid, rr.description
				  FROM pending_region
				 WHERE pending_dataset_id = r.pending_dataset_id
				   AND maps_to_region_sid = rr.parent_sid;
			--DBMS_OUTPUT.PUT_LINE(rr.description || ' inserted into pending_dataset '||r.pending_dataset_id);
		END LOOP;
	END LOOP;
END;



PROCEDURE CreateRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_parent_region_Id			IN	pending_region.pending_region_id%TYPE,
	in_description				IN	pending_region.description%TYPE,
	in_maps_to_region_sid		IN	security_pkg.T_SID_ID,
	out_pending_region_Id		OUT	pending_region.pending_region_id%TYPE
)
AS
    v_pos NUMBER;
BEGIN
    -- Make the new pending region be the last child of it's parent
	SELECT NVL(MAX(pos),0)+1
	  INTO v_pos
	  FROM pending_region
	 WHERE pending_dataset_id = in_pending_dataset_id AND
	       parent_region_id = in_parent_region_id;
	       
	INSERT INTO pending_region
		(pending_region_id, pending_dataset_id, parent_region_id, description, maps_to_region_sid, pos)
	VALUES
		(pending_region_id_seq.nextval, in_pending_dataset_id, in_parent_region_id, in_description, in_maps_to_region_sid, v_pos)
	RETURNING pending_region_id INTO out_pending_region_id;		
END;

PROCEDURE CreateRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id		IN	pending_dataset.pending_dataset_Id%TYPE,
	in_parent_region_Id			IN	pending_region.pending_region_id%TYPE,
	in_description				IN	pending_region.description%TYPE,
	in_maps_to_region_sid		IN	security_pkg.T_SID_ID,
	out_cur             		OUT	SYS_REFCURSOR
)
AS
    v_pending_region_Id     pending_region.pending_region_id%TYPE;
BEGIN
    CreateRegion(in_act_id, in_pending_dataset_id, in_parent_region_id, in_description, in_maps_to_region_sid, v_pending_region_id);
    OPEN out_cur FOR
		SELECT pending_region_id, pending_dataset_id, parent_region_id, description, maps_to_region_sid
		  FROM pending_region
		 WHERE pending_region_id = v_pending_region_id;        
END;


PROCEDURE CreateRegionTree(
    in_act_id			        IN  security_pkg.T_ACT_ID,
	in_app_sid			    	IN  security_pkg.T_SID_ID,
	in_region_tree_root_sid		IN  security_pkg.T_SID_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
)
AS
	v_parent_region_id		pending_region.pending_region_id%TYPE;
BEGIN
	-- build new tree
	FOR r IN (
		 SELECT region_pkg.ParseLink(region_sid) region_sid, parent_sid, description, level lvl
		   FROM v$region
		  WHERE active = 1
		  START WITH parent_sid = in_region_tree_root_sid
		CONNECT BY PRIOR region_sid = parent_sid
		  ORDER SIBLINGS BY description
	)
	LOOP
		BEGIN
			SELECT pending_region_id
			  INTO v_parent_region_id
	 		  FROM pending_region
			 WHERE maps_to_region_sid = r.parent_sid
	  		   AND pending_dataset_id = in_pending_dataset_id;
		EXCEPTION 
		    WHEN NO_DATA_FOUND THEN
				v_parent_region_id := NULL;
		END;
		INSERT INTO pending_region
		    (pending_region_id, pending_dataset_id, maps_to_region_sid, description, parent_region_id)
	    VALUES
		    (pending_region_id_seq.nextval, in_pending_dataset_id, r.region_sid, r.description, v_parent_region_id);
	END LOOP;
END;

PROCEDURE GetAps(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_reg_sid						IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_deleg_cur					OUT	SYS_REFCURSOR,
	out_sheet_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN 
	DELETE FROM temp_delegation_sid;
	INSERT INTO temp_delegation_sid (delegation_sid)
		SELECT aps.approval_step_id
      	  FROM approval_step aps, pending_dataset pds, pending_period pp
		 WHERE pds.pending_dataset_id = pp.pending_dataset_id
		   AND pp.start_dtm < NVL(in_end_dtm, SYSDATE)
		   AND pp.end_dtm >  in_start_dtm
		   AND pds.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND aps.app_sid = pds.app_sid
		   AND aps.pending_dataset_id = pds.pending_dataset_id
	 INTERSECT
        SELECT approval_step_id 
          FROM approval_step_ind
         WHERE (in_ind_sid IS NULL OR pending_ind_id IN ( 
					SELECT pending_ind_id 
					  FROM pending_ind 
					 WHERE maps_to_ind_sid = in_ind_sid))
	 INTERSECT
        SELECT DISTINCT approval_step_id 
          FROM approval_step_region
         WHERE (in_reg_sid IS NULL OR pending_region_id IN ( 
					SELECT pending_region_id 
					  FROM pending_region 
					 WHERE maps_to_region_sid = in_reg_sid))
	 INTERSECT
        SELECT DISTINCT approval_step_id 
          FROM approval_step_user
         WHERE (in_user_sid IS NULL OR user_sid = in_user_sid);
         	
	OPEN out_deleg_cur FOR
		SELECT aps.approval_step_id delegation_sid, aps.parent_step_id parent_sid,
		  	   aps.label name, aps.label description, '/csr/site/pending/form.acds' editing_url,
		  	   aps.root_approval_step_id root_delegation_sid
		  FROM (SELECT approval_step_id, parent_step_id, label,
		  			   connect_by_root approval_step_id root_approval_step_id
		  		  FROM approval_step
		  		  	   START WITH parent_step_id IS NULL
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR approval_step_id = parent_step_id) aps,
			   temp_delegation_sid tds
	     WHERE tds.delegation_sid = aps.approval_step_id
	     ORDER BY aps.parent_step_id;

	OPEN out_sheet_cur FOR
		SELECT apsh.approval_step_id delegation_sid, apsh.sheet_key sheet_id,
			   pp.start_dtm, pp.end_dtm, apsh.due_dtm submission_dtm,
			   pp.label period_fmt
		  FROM approval_step_sheet apsh, temp_delegation_sid tds, pending_period pp
		 WHERE tds.delegation_sid = apsh.approval_step_id
		   AND apsh.pending_period_id = pp.pending_period_id;

	OPEN out_users_cur FOR
		SELECT apsu.approval_step_id delegation_sid,
			   cu.csr_user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM approval_step_user apsu, csr_user cu, temp_delegation_sid tds, security.user_table ut 
		 WHERE tds.delegation_sid = apsu.approval_step_id
		   AND apsu.user_sid = cu.csr_user_sid
		   AND cu.csr_user_sid = ut.sid_id;
END;

PROCEDURE CreateRegionTree(
    in_act_id			        IN  security_pkg.T_ACT_ID,
	in_app_sid			    IN  security_pkg.T_SID_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
)
AS
	v_region_tree_root_sid	security_pkg.T_SID_ID;
BEGIN
 	-- get primary region tree root sid
    SELECT region_tree_root_sid 
      INTO v_region_tree_root_sid
      FROM region_tree
     WHERE app_sid = in_app_sid
       AND is_primary = 1;
	CreateRegionTree(in_act_id, in_app_sid, v_region_tree_root_sid, in_pending_dataset_id);
END;

PROCEDURE PruneRegionTree(
    in_act_id                   IN  security_pkg.T_ACT_ID,
	in_pending_dataset_id	    IN  pending_dataset.pending_dataset_Id%TYPE
)
AS
    v_cnt   NUMBER(10);
BEGIN
    FOR r IN (       
        -- all regions
        SELECT pending_region_id, description
          FROM pending_region
         WHERE pending_dataset_id = in_pending_dataset_id
         MINUS
        -- all regions (and their parents) that are involved in approval steps
        SELECT DISTINCT pending_region_id, description
          FROM pending_region
         START WITH pending_region_id in ( -- start with every region in every approval step
            SELECT apsr.pending_region_id
              FROM approval_step_region apsr, approval_step aps
             WHERE apsr.approval_step_id = aps.approval_step_id
               AND aps.pending_dataset_id = in_pending_dataset_id
          )
        CONNECT BY PRIOR parent_region_id = pending_region_id -- go UP the tree
    )
    LOOP 
        -- check that the region still exists (the order we delete stuff isn't specified,
        -- so we might delete a region, thus deleting children, which we no longer need to 
        -- delete here)
        SELECT COUNT(*)
          INTO v_cnt
          FROM pending_region 
         WHERE pending_region_id = r.pending_region_id;
        IF v_cnt > 0 THEN
            -- delete region checking for values (there shouldn't be any) 
            deleteRegion(in_act_id, r.pending_region_id, 0);
        END IF;
    END LOOP;
END;

PROCEDURE GetRegion(
	in_act_Id					IN	security_pkg.T_ACT_ID,
	in_pending_region_Id		IN	pending_region.pending_region_id%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pending_region_id, pending_dataset_id, parent_region_id, description, maps_to_region_sid, pos
		  FROM pending_region
		 WHERE pending_region_id = in_pending_region_id;
END;

PROCEDURE GetInd(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_ind_Id		IN	pending_ind.pending_ind_id%TYPE,
	out_cur	                OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
		SELECT pi.pending_ind_id, pi.description, pi.val_mandatory, pi.note_mandatory, pi.file_upload_mandatory, pi.lookup_key,
			   pi.tolerance_type, pi.pct_upper_tolerance, pi.pct_lower_tolerance, pi.pending_dataset_id,
			   pi.parent_ind_id, pi.measure_sid, pi.maps_to_ind_sid,
   			   NVL(i.divisibility, NVL(mi.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
			   pi.pos, pi.allow_file_upload, pi.aggregate, i.calc_xml, pi.element_type, NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) ind_type,
			   pi.format_xml, pi.read_only, pi.link_to_ind_id, pi.info_xml, NVL(pi.dp, m.scale) dp, pi.default_val_number, pi.default_val_string,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp
          FROM pending_ind pi, ind i, measure m, measure mi
	     WHERE pi.app_sid = i.app_sid(+) AND pi.maps_to_ind_sid = i.ind_sid(+)
	       AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
	       AND pi.app_sid = m.app_sid(+) AND pi.measure_sid = m.measure_sid(+)
           AND pi.pending_ind_id = in_pending_ind_id;
END;

PROCEDURE GetRootRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		  SELECT pending_region_id, description, parent_region_Id, maps_to_region_sid, pos, pending_dataset_id		  		
		    FROM PENDING_REGION
		    WHERE pending_dataset_id = in_pending_dataset_id AND parent_region_id is NULL
		    ORDER BY POS;
END;	

PROCEDURE GetRegionTrees(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		  SELECT pending_region_id, description, parent_region_Id, maps_to_region_sid, pos, pending_dataset_id, LEVEL lvl		  		
		    FROM PENDING_REGION
		    START WITH pending_dataset_id = in_pending_dataset_id AND parent_region_id is NULL
		    CONNECT BY PRIOR pending_region_id = parent_region_Id
		    ORDER SIBLINGS BY POS;
END;	

PROCEDURE DeleteRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_pending_region_id			IN	pending_region.pending_region_id%TYPE,
	in_ignore_warnings				IN	NUMBER DEFAULT 0,
	in_set_sheet_max_value_count	IN	NUMBER DEFAULT 1 -- faster if you set this to 0
)
AS
	v_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	-- TODO: what about if the values we're about to delete are associated
	-- with VAL source types?


	-- iterate through all children
	FOR r IN (
		SELECT pending_region_id
		  FROM pending_region
		 WHERE parent_region_id = in_pending_region_id
	)
	LOOP
		DeleteRegion(in_act_id, r.pending_region_id, in_ignore_warnings);
	END LOOP;
		 
	-- delete cached values
	DELETE FROM pending_val_cache WHERE pending_region_id = in_pending_region_id;
	DELETE FROM PVC_STORED_CALC_JOB WHERE pending_region_id = in_pending_region_id;

	-- delete all values 
	FOR r IN (
		SELECT pending_val_Id FROM pending_val WHERE pending_region_Id = in_pending_region_id
    )
    LOOP
		-- if we're in here at all, then there are values present,
		-- so barf (unless we're ignoring warnings)
		IF in_ignore_warnings = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Values are present for this indicator ('||in_pending_region_id||')');		
		END IF;
		INTERNAL_DeleteVal(r.pending_val_id);
    END LOOP;
    
	-- delete this region from approval steps
	FOR r IN (
		SELECT aps.approval_step_id, layout_type
		  FROM approval_step aps, approval_step_region apsr
		 WHERE aps.approval_step_id = apsr.approval_step_id
		   AND apsr.pending_region_id = in_pending_region_id	
	)
	LOOP
		FOR rs IN (
			SELECT approval_step_id, sheet_key
			  FROM approval_step_sheet
			 WHERE pending_region_id = in_pending_region_id
			   AND approval_step_id = r.approval_step_id
		)
		LOOP
			INTERNAL_DeleteAppStepSheet(rs.approval_step_id, rs.sheet_key);
		END LOOP;
				
		DELETE FROM approval_step_region
	     WHERE pending_region_id = in_pending_region_id
	       AND approval_step_id = r.approval_step_id;
		
		IF r.layout_type IN (pending_pkg.LAYOUT_REGION, pending_pkg.LAYOUT_IND_X_REGION, pending_pkg.LAYOUT_REGION_X_PERIOD) AND in_set_sheet_max_value_count = 1 THEN		
			SetSheetMaxValueCount(r.approval_step_id);
		END IF;
		
	END LOOP;

    /* Deleting approval step stops the dataset create/edit page form working, as it is normal for a 
       user to have approval steps before they have set up all the other items in the dataset.  
       Also it is somewhat unexpected behavior for the user to have their approval step vanish 
       when they do a unrelated task in the UI.
    -- check (and remove) any now empty approval steps
    SELECT pending_dataset_id
      INTO v_dataset_id
      FROM pending_region
     WHERE pending_region_id = in_pending_region_id;
    RemoveEmptyApprovalSteps(v_dataset_id);
*/    

	DELETE FROM pending_region 
	 WHERE pending_region_id = in_pending_region_id;
END;
	
PROCEDURE MovePendingRegion(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_region_id           IN  PENDING_REGION.PENDING_REGION_ID%TYPE,
    in_parent_region_id            IN  PENDING_REGION.PARENT_REGION_ID%TYPE)
AS
BEGIN
    /* TODO give error if there are values etc!!*/

    UPDATE pending_region
       SET parent_region_id = in_parent_region_id
     WHERE pending_region_id = in_pending_region_id;
END;


PROCEDURE AmendPendingRegion(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_region_id        IN  PENDING_REGION.PENDING_REGION_ID%TYPE,
    in_description              IN  PENDING_REGION.DESCRIPTION%TYPE,
	in_pos						IN	PENDING_REGION.POS%TYPE
)
AS
BEGIN

    UPDATE pending_region
       SET description = in_description,
			pos = in_pos
     WHERE pending_region_id = in_pending_region_id;
END;

PROCEDURE BindAccuracyToInd(	
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
)
AS
	v_cnt	NUMBER(10);
BEGIN
	-- check accuracy type is for same app_sid as pending_ind
	SELECT COUNT(*) 
	  INTO v_cnt
	  FROM pending_ind pi, pending_dataset pd, accuracy_type a
	 WHERE pi.pending_dataset_id = pd.pending_dataset_id
	   AND pd.app_sid = a.app_sid
	   AND a.accuracy_type_id = in_accuracy_type_id
	   AND pi.pending_ind_id = in_pending_ind_id;
	
	IF v_cnt = 0 THEN	
		RAISE_APPLICATION_ERROR(-20001, 'app_sid mismatch for pending_ind_id and accuracy_type_id');
	END IF;
	
	INSERT INTO pending_ind_accuracy_type
		(pending_ind_id, accuracy_type_id)
	VALUES
		(in_pending_ind_id, in_accuracy_type_id);
END;

PROCEDURE UnbindAccuracyFromInd(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
)
AS
BEGIN
	DELETE FROM pending_ind_accuracy_type
	 WHERE pending_ind_id = in_pending_ind_id
	   AND accuracy_type_Id = in_accuracy_type_id;
	 
END;


PROCEDURE GetAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT a.accuracy_type_Id, a.LABEL, a.q_or_c, a.max_score 
		  FROM pending_ind_accuracy_type piat, pending_ind pi, approval_step_ind apsi, accuracy_type a 
		 WHERE apsi.pending_ind_id = pi.pending_ind_id
		   AND pi.pending_ind_id = piat.pending_ind_id
		   AND piat.accuracy_type_id = a.accuracy_type_id
		   AND apsi.approval_step_id = in_approval_step_id;
END;


PROCEDURE GetAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT ato.accuracy_type_id, ato.accuracy_type_option_id, ato.LABEL, ato.accuracy_weighting
		  FROM pending_ind_accuracy_type piat, pending_ind pi, approval_step_ind apsi, accuracy_type a, accuracy_type_option ato 
		 WHERE apsi.pending_ind_id = pi.pending_ind_id
		   AND pi.pending_ind_id = piat.pending_ind_id
		   AND piat.accuracy_type_id = a.accuracy_type_id
		   AND a.accuracy_type_id = ato.accuracy_type_id
		   AND apsi.approval_step_id = in_approval_step_id
		 ORDER BY ato.accuracy_type_id, accuracy_weighting DESC;
END;


PROCEDURE GetIndAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_approval_step_id	IN	approval_Step.approval_step_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT piat.pending_ind_id, piat.accuracy_type_id
		  FROM pending_ind_accuracy_type piat, pending_ind pi, approval_step_ind apsi 
		 WHERE apsi.pending_ind_id = pi.pending_ind_id
		   AND pi.pending_ind_id = piat.pending_ind_id
		   AND apsi.approval_step_id = in_approval_step_id;		
END;




-- distinct list of all files in the approval step (for doing a "use this already uploaded file" type picker)
PROCEDURE GetFilesForApprovalStep(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT fu.file_upload_sid, filename, mime_type
		  FROM approval_step aps, approval_step_ind apsi, pending_val pv, pending_val_file_upload pvfu, file_upload fu
		 WHERE aps.approval_step_id = apsi.approval_step_id
	 	   AND apsi.pending_ind_id = pv.pending_ind_id
	 	   AND pv.pending_val_id = pvfu.pending_val_id
	 	   AND pvfu.file_upload_sid = fu.file_upload_sid
	 	 ORDER BY filename;	 	   
END;



PROCEDURE ClearAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_pending_val_id	IN	pending_val.pending_val_id%TYPE,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE
)
AS
BEGIN
	DELETE FROM pending_val_accuracy_type_opt
	 WHERE pending_val_id = in_pending_val_id
	   AND accuracy_type_option_id IN (
		SELECT accuracy_type_option_id 
		  FROM accuracy_type_option
		 WHERE accuracy_type_id = in_accuracy_type_id
	 ); 
END;

PROCEDURE SetAccuracyTypeOption(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_pending_val_id			IN	pending_val.pending_val_id%TYPE,
	in_accuracy_type_option_id	IN	accuracy_type_option.accuracy_type_option_id%TYPE,
	in_pct						IN	pending_val_accuracy_type_opt.pct%TYPE
)
AS
BEGIN
	INSERT INTO PENDING_VAL_ACCURACY_TYPE_OPT
		(pending_val_id, accuracy_type_option_id, pct)
	VALUES
		(in_pending_val_id, in_accuracy_type_option_id, in_pct);
END;


PROCEDURE MapInd(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_ind_id	IN	pending_ind.pending_ind_id%TYPE,
	in_ind_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- are we mapping or unmapping?
	IF in_ind_sid IS NULL THEN
		-- unmapping
		NULL;
	ELSE
		-- mapping
		NULL;
	END IF;


	-- make the mapping (or unmapping)
	UPDATE pending_ind
	   SET maps_to_ind_sid = in_ind_sid
	 WHERE pending_ind_id = in_pending_ind_id;

	-- what about values we've already set (same issue as with imports)
	
	-- speedwise, best to validate at merge point?
END;


PROCEDURE MovePendingInd(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
    in_pending_ind_id           IN  PENDING_IND.PENDING_IND_ID%TYPE,
    in_parent_ind_id            IN  PENDING_IND.PARENT_IND_ID%TYPE)
AS
BEGIN
    /* TODO give error if there are values etc!!*/

    UPDATE pending_ind
       SET parent_ind_id = in_parent_ind_id
     WHERE pending_ind_id = in_pending_ind_id;
END;


PROCEDURE AmendPendingInd(
    in_act_Id                   IN  security_pkg.t_act_id,
    in_pending_ind_id           IN  pending_ind.pending_ind_id%TYPE,     
    in_description              IN  pending_ind.description%TYPE,        
    in_val_mandatory            IN  pending_ind.val_mandatory%TYPE,      
    in_note_mandatory           IN  pending_ind.note_mandatory%TYPE,
    in_file_upload_mandatory	IN	pending_ind.file_upload_mandatory%TYPE,
    in_measure_sid              IN  pending_ind.measure_sid%TYPE,        
    in_element_type             IN  pending_ind.element_type%TYPE,       
    in_tolerance_type           IN  pending_ind.tolerance_type%TYPE,     
    in_pct_upper_tolerance      IN  pending_ind.pct_upper_tolerance%TYPE,
    in_pct_lower_tolerance      IN  pending_ind.pct_lower_tolerance%TYPE,
    in_format_xml               IN  pending_ind.format_xml%TYPE,         
    in_link_to_ind_id           IN  pending_ind.link_to_ind_id%TYPE,     
    in_read_only                IN  pending_ind.read_only%TYPE,          
    in_info_xml                 IN  pending_ind.info_xml%TYPE,           
    in_dp                       IN  pending_ind.dp%TYPE,                 
    in_default_val_number       IN  pending_ind.default_val_number%TYPE, 
    in_default_val_string       IN  pending_ind.default_val_string%TYPE, 
    in_lookup_key               IN  pending_ind.lookup_key%TYPE,
    in_pos						IN	pending_ind.pos%TYPE,
    in_allow_file_upload		IN	pending_ind.allow_file_upload%TYPE
)
AS
BEGIN
    UPDATE pending_ind
       SET description = in_description,
		   val_mandatory = in_val_mandatory,
		   note_mandatory = in_note_mandatory,
		   file_upload_mandatory = in_file_upload_mandatory,
		   measure_sid = in_measure_sid,
		   element_type = in_element_type,
		   tolerance_type = in_tolerance_type,
		   pct_upper_tolerance = in_pct_upper_tolerance,
		   pct_lower_tolerance = in_pct_lower_tolerance,
		   format_xml = in_format_xml,
		   link_to_ind_id = in_link_to_ind_id,
		   read_only = in_read_only,
		   info_xml = in_info_xml,
		   dp = in_dp,
		   default_val_number = in_default_val_number,
		   default_val_string = in_default_val_string,
		   lookup_key = UPPER(in_lookup_key),
		   pos = in_pos,
		   allow_file_upload = in_allow_file_upload
     WHERE pending_ind_id = in_pending_ind_id;
END;


PROCEDURE MapRegion(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- are we mapping or unmapping?
	IF in_region_sid IS NULL THEN
		-- unmapping
		NULL;
	ELSE
		-- mapping
		-- with mappings be super careful about path conflicts on regions
		NULL;		
	END IF;


	-- make the mapping (or unmapping)
	UPDATE pending_region
	   SET maps_to_region_sid = in_region_sid
	 WHERE pending_region_id = in_pending_region_id;

	-- what about values we've already set (same issue as with imports)
	
	-- speedwise, best to validate at merge point?
END;


FUNCTION GetPostMergeAggrBlockers(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_pending_dataset_id	IN pending_dataset.pending_dataset_id%TYPE
) RETURN T_PENDING_MERGE_BLOCKER_TABLE
AS	
	-- basic info
	v_region_root_sid			security_pkg.T_SID_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_root_approval_step_id		approval_step.approval_step_id%TYPE;

	-- stuff for building up the error table
	v_table						T_PENDING_MERGE_BLOCKER_TABLE := T_PENDING_MERGE_BLOCKER_TABLE();
	v_err_region_path			VARCHAR2(2000);
	v_err_region_sid			security_pkg.T_SID_ID;
	v_err_pending_region_id		PENDING_REGION.pending_region_id%TYPE;
	v_err_pending_region_path	VARCHAR2(2000);
BEGIN
	-- find out some basic info based on the dataset
	SELECT app_sid
	  INTO v_app_sid
	  FROM pending_dataset
	 WHERE pending_dataset_id = in_pending_dataset_id;
	   
	SELECT region_tree_root_sid
	  INTO v_region_root_sid
	  FROM region_tree 
	 WHERE app_sid = v_app_sid 
	   AND IS_PRIMARY = 1; -- just for primary atm - is this good enough?
	   
	SELECT approval_step_id
	  INTO v_root_approval_step_id
	  FROM approval_step
	 WHERE pending_dataset_id = in_pending_dataset_id
	   AND parent_step_id IS NULL;

	-- this basically finds region/ind combinations where the mapped-to region enounters another mapped-to region further
	-- up the tree, which would cause an aggregation problem when merged
	FOR each_error IN (
		SELECT * 
		  FROM (
			WITH lp AS (  
				SELECT pending_ind_id, pending_region_id, maps_to_region_sid, region_description, ind_description 
				  FROM TABLE(pending_pkg.GetLeafPointsAsTable(v_root_approval_step_id))
			)
			SELECT region_sid, parent_sid, lp.pending_ind_id, lp.pending_region_id, 
				   lp.region_description pending_region_description, lp.ind_description pending_ind_description,
				   -- LPAD('--> ',(LEVEL-1)*4)||r.description description,  -- quite useful for debugging 
				   LTRIM(SYS_CONNECT_BY_PATH(r.description,' > '),' > ') region_path,  
			 	   CASE WHEN lp.region_description != REPLACE(SYS_CONNECT_BY_PATH(lp.region_description,'|?'),'|?','') THEN 1 ELSE 0 END ERR  -- pretty unique separator
			  FROM v$region r, lp
			 WHERE r.app_sid = v_app_sid -- belt and braces!
			   AND r.region_sid = lp.maps_to_region_sid(+)
			 START WITH region_sid = v_region_root_sid
		   CONNECT BY PRIOR r.region_sid = r.parent_sid
			   AND (PRIOR pending_ind_id = pending_ind_id OR PRIOR pending_ind_id IS NULL) -- if parent region has no mappings, we need to check for NULL
		 )
		 WHERE err = 1
	)
	LOOP
		-- reset our variables for each iteration
		v_err_region_path := '';
		v_err_region_sid := NULL;
		v_err_pending_region_path := '';
		v_err_pending_region_id := NULL;	   
		-- build a path string for the object that's actually blocking our route to the top of the region tree
		FOR r IN (
			 SELECT region_sid, r.description, pr.pending_region_id, SYS_CONNECT_BY_PATH(r.description,'|')
			   FROM v$region r, pending_region pr
			  WHERE r.app_sid = v_app_sid -- belt and braces!
				AND r.region_sid = pr.maps_to_region_sid(+)
				AND NVL(pr.pending_dataset_id, in_pending_dataset_id) = in_pending_dataset_id
			  START WITH region_sid = each_error.parent_sid -- start at parent since we'll have a pending region (the thing that is objecting) at region_sid level
			CONNECT BY PRIOR parent_sid = region_sid
	 	)
		LOOP
			IF r.pending_region_id IS NOT NULL AND v_err_region_sid IS NULL THEN
				v_err_region_sid := r.region_sid;
				v_err_pending_region_id := r.pending_region_id;
			END IF;
			IF v_err_region_sid IS NOT NULL THEN
				v_err_region_path := r.description || ' > ' || v_err_region_path;
			END IF;
		END LOOP;
		v_err_region_path := RTRIM(v_err_region_path,' > '); -- trim off crap
	   	-- now get hold of the pending region path
		WITH DATA AS (
			 SELECT description, LEVEL rn, CONNECT_BY_ISLEAF is_leaf 
			   FROM PENDING_REGION
			  START WITH pending_region_id = v_err_pending_region_id
			CONNECT BY PRIOR parent_region_id = pending_region_id		
		  )
		 SELECT LTRIM(SYS_CONNECT_BY_PATH(description, ' > '),' > ') LIST
		   INTO v_err_pending_region_path
		   FROM DATA
		  WHERE rn = 1
		  START WITH is_leaf = 1
		CONNECT BY PRIOR rn = rn + 1;
		
		-- write all the details of the problem to the table
		v_table.extend;
		v_table ( v_table.COUNT ) := T_PENDING_MERGE_BLOCKER_ROW(
			each_error.pending_region_id,
			each_error.pending_region_description,
			each_error.pending_ind_id,
			each_error.pending_ind_description,
			each_error.region_sid,
			each_error.region_path, 
			v_err_pending_region_id,
			v_err_pending_region_path,
			v_err_region_sid,
			v_err_region_path
		);				
		-- on to the next error
	END LOOP; 
	RETURN v_table;
END;


PROCEDURE GetLeafPoints(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
) AS 
BEGIN	
	OPEN out_cur FOR
		SELECT pending_ind_id, ind_description, pending_region_id, region_Description,
			root_region_id, root_Region_description, approval_step_id, maps_to_ind_sid,
			maps_to_region_sid
		  FROM TABLE(GetLeafPointsAsTable(in_approval_step_id))
		 ORDER BY pending_ind_id, root_region_id;
END;

-- THIS IS SLOW!! NEED TO LOOK AT WAYS TO MINIMISE ITS USE / KEEP THE DATA DIRECTLY UP TO DATE IN A TABLE / SPEED IT UP
FUNCTION GetLeafPointsAsTable(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE
) RETURN T_PENDING_LEAF_TABLE
AS
	v_table					T_PENDING_LEAF_TABLE;
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	SELECT pending_dataset_id
	  INTO v_pending_dataset_id
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;

	SELECT /*+ALL_ROWS*/ T_PENDING_LEAF_ROW(
    	x.pending_ind_id, 
    	x.ind_description,
    	x.pending_region_id,  
    	x.region_description, 
    	x.root_region_id, 
    	rpr.description, --root_region_description,
    	x.approval_step_id,
    	x.maps_to_ind_sid,
    	x.maps_to_region_sid
    	)
   	  BULK COLLECT INTO v_table
	  FROM ( 
		 SELECT CONNECT_BY_ROOT pending_region_id root_region_id, approval_Step_id, parent_step_id, pending_ind_id, pending_region_id, 
	     		LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, ind_description, region_description, maps_to_region_sid, maps_to_ind_sid
		   FROM ( 
		    SELECT aps.app_sid, apsi.approval_Step_id, aps.parent_step_id, apsi.pending_ind_id, apsr.pending_region_id, apsr.rolls_up_to_region_id, 
		       	   pr.description region_description, pi.description ind_description, pr.maps_to_region_sid, pi.maps_to_ind_sid
		      FROM (
                SELECT app_sid, approval_step_id, parent_step_id 
                  FROM approval_step 
                 START WITH approval_step_id = in_approval_step_id 
               CONNECT BY PRIOR app_sid = app_sid AND PRIOR approval_step_id = parent_step_id
              )aps, approval_step_region apsr, approval_step_ind apsi, pending_region pr, pending_ind pi
		     WHERE aps.app_sid = apsr.app_sid AND aps.approval_step_id = apsr.approval_step_id
		       AND aps.app_sid = apsi.app_sid AND aps.approval_step_id = apsi.approval_step_id
		       AND apsi.app_sid = apsr.app_sid AND apsi.approval_step_id = apsr.approval_step_id -- oracle likes this
		       AND apsr.app_sid = pr.app_sid AND apsr.pending_region_id = pr.pending_region_id
		       AND apsi.app_sid = pi.app_sid AND apsi.pending_ind_id = pi.pending_ind_id
	           --AND aps.pending_dataset_id = v_pending_dataset_id
		   )
		   START WITH approval_step_id = in_approval_step_id
		 CONNECT BY PRIOR app_sid = app_sid 
		 	 AND PRIOR approval_step_id = parent_step_id
		     AND PRIOR pending_region_id = rolls_up_to_region_id  
		     AND PRIOR pending_ind_id = pending_ind_id(+) -- indicators might not exist at all levels         
		 )x, pending_region rpr -- root_pending_region
	WHERE is_leaf = 1 -- just pull out the leaf values
	  AND rpr.pending_region_id = root_region_id
	ORDER BY x.pending_ind_id, x.root_region_id, x.lvl DESC, x.pending_region_id, x.approval_step_id;
	
	RETURN v_table;
END;

PROCEDURE GetApprovalStepRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pending_region_id
		FROM approval_step_region
		WHERE approval_step_id = in_approval_step_id;
END;

PROCEDURE GetApprovalStepFullRegions(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		 SELECT pending_region_id, parent_region_Id, description, maps_to_region_sid, pending_dataset_id, pos, LEVEL lvl, ROWNUM rn
		   FROM PENDING_REGION
		  START WITH pending_region_id IN 
			(SELECT pending_region_id FROM APPROVAL_STEP_REGION WHERE approval_step_id = in_approval_step_id)
		CONNECT BY PRIOR pending_region_id =parent_region_id
		  ORDER SIBLINGS BY POS;
END;

PROCEDURE GetApprovalStepRegionTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
-- gets a bunch of regions and all their children (as a single tree)
		  -- merging any common parts of the tree
		  SELECT x.pending_region_id, description, parent_region_Id, maps_to_region_sid, pending_dataset_id, pos, lvl, 
		  		 CASE WHEN y.pending_region_id IS NOT NULL THEN 1 ELSE 0 END has_approval_step
		    FROM (
		     SELECT pending_region_id, parent_region_Id, description, maps_to_region_sid, pending_dataset_id, pos, MAX(lvl) lvl, MAX(rn) maxRn
		       FROM (     
		         SELECT pending_region_id, parent_region_Id, description, maps_to_region_sid, pending_dataset_id, pos, LEVEL lvl, ROWNUM rn
				   FROM PENDING_REGION
				  START WITH pending_region_id IN 
				  	(SELECT pending_region_id FROM APPROVAL_STEP_REGION WHERE approval_step_id = in_approval_step_id)
				CONNECT BY PRIOR pending_region_id = parent_region_id 
				 ORDER SIBLINGS BY POS       
		        )
		       GROUP BY pending_region_id, parent_region_Id, pos, maps_to_region_sid, description, pending_dataset_id
		   	)x, ( 
			SELECT DISTINCT pending_region_id  -- we join to this to filter our regions that are never used
			  FROM approval_step_region
			 WHERE approval_step_id IN (
				 SELECT approval_step_id
				   FROM approval_step
				  START WITH approval_step_id = in_approval_step_id
				CONNECT BY PRIOR approval_step_id = parent_step_id
			  ) 
			)y
			WHERE x.pending_region_id = y.pending_region_id(+)
          ORDER BY maxrn;
END;	

PROCEDURE GetApprovalStepIndTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
BEGIN
	SELECT pending_dataset_id
	  INTO v_pending_dataset_id
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;
	 
	OPEN out_cur FOR
		SELECT x.pending_ind_id, x.description, x.val_mandatory, x.file_upload_mandatory, x.note_mandatory, x.lookup_key,
			   x.tolerance_type, x.pct_upper_tolerance, x.pct_lower_tolerance, x.pending_dataset_id,
			   x.parent_ind_id, x.measure_sid, x.lvl, x.maps_to_ind_sid, x.pos, x.allow_file_upload,
			   NVL(i.divisibility, NVL(mi.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility, 
			   x.aggregate, i.calc_xml, x.element_type, NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) ind_type,
			   x.format_xml, x.read_only, x.link_to_ind_id, x.info_xml, NVL(x.dp, m.scale) dp, x.default_val_number, x.default_val_string,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp
		  FROM (SELECT app_sid, pending_ind_id, maps_to_ind_sid, description, pct_upper_tolerance, pct_lower_tolerance, val_mandatory, note_mandatory, file_upload_mandatory,
					   lookup_key,tolerance_type, element_type, format_xml, read_only, link_to_ind_id, info_xml, dp, default_val_number, default_val_string,
					   aggregate, pending_dataset_id, parent_ind_id, measure_sid, pos, allow_file_upload, LEVEL lvl, ROWNUM rn
				  FROM pending_ind
				 WHERE pending_dataset_id = v_pending_dataset_id
					   START WITH parent_ind_id IS NULL
					   CONNECT BY PRIOR pending_ind_id = parent_ind_id
			     ORDER SIBLINGS BY pos) x, 
			   approval_step_ind apsi, ind i, measure m, measure mi
		 WHERE apsi.app_sid = x.app_sid AND apsi.pending_ind_id = x.pending_ind_id -- apsi.pending_ind_id(+) = x.pending_ind_id
	       AND apsi.approval_step_id = in_approval_step_id -- apsi.approval_step_id(+) = in_approval_step_id
		   /*
		   AND (apsi.pending_ind_id IS NOT NULL OR x.measure_sid IS NULL) -- this retains the structure so that we always have a full tree,other wise it
																			-- breaks if we have subdelegated the bottom 2 nodes, but we try to build a tree
																			-- since LEVEL will start at (say) 3, not 1
																			*/
	       AND x.maps_to_ind_sid = i.ind_sid(+)
	       AND x.measure_sid = m.measure_sid(+)
	       AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
	     ORDER BY rn;
END;

PROCEDURE GetPendingIndTree(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_top_PendingInd_id    IN	PENDING_IND.pending_ind_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN	 
	OPEN out_cur FOR
		SELECT x.pending_ind_id, x.description, x.val_mandatory, x.note_mandatory, x.file_upload_mandatory, x.lookup_key,
			   x.tolerance_type, x.pct_upper_tolerance, x.pct_lower_tolerance, x.pending_dataset_Id, x.pos,
			   x.parent_ind_Id, x.measure_sid, x.lvl, x.maps_to_ind_sid, x.allow_file_upload,
			   NVL(i.divisibility, NVL(mi.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
			   x.aggregate, i.calc_xml, x.element_type, NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) ind_type,
			   x.format_xml, x.read_only, x.link_to_ind_id, x.info_xml, NVL(x.dp, m.scale) dp, x.default_val_number, x.default_val_string,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp
		  FROM (SELECT pending_ind_id, maps_to_ind_sid, description, pct_upper_tolerance, pct_lower_tolerance, val_mandatory, note_mandatory, file_upload_mandatory,
			 		   lookup_key, tolerance_type, element_type, format_xml, read_only, link_to_ind_id, info_xml, dp, default_val_number, default_val_string,
					   aggregate, pending_dataset_id, parent_ind_id, measure_sid, allow_file_upload, LEVEL lvl, pos, ROWNUM rn
				  FROM pending_ind
					   START WITH pending_ind_id = in_top_PendingInd_id
					   CONNECT BY PRIOR pending_ind_id = parent_ind_id
				 ORDER SIBLINGS BY pos
		  )x, ind i, measure m, measure mi
		 WHERE x.maps_to_ind_sid = i.ind_sid(+)
	       AND x.measure_sid = m.measure_sid(+)
	       AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
	     ORDER BY rn;
END;

PROCEDURE GetChildPendingInds(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id   IN	PENDING_IND.pending_dataset_id%TYPE,
    in_parent_ind_id    	IN	PENDING_IND.pending_ind_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN	 
	OPEN out_cur FOR
		SELECT pi.pending_ind_id, pi.description, pi.val_mandatory, pi.note_mandatory, pi.file_upload_mandatory, pi.lookup_key,
			   pi.tolerance_type, pi.pct_upper_tolerance, pi.pct_lower_tolerance, pi.pending_dataset_Id, pi.pos, pi.allow_file_upload,
			   pi.parent_ind_Id, pi.measure_sid, pi.maps_to_ind_sid,
			   NVL(i.divisibility, NVL(mi.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
			   pi.aggregate, i.calc_xml, pi.element_type, NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) ind_type,
			   pi.format_xml, pi.read_only, pi.link_to_ind_id, pi.info_xml, NVL(pi.dp, m.scale) dp, pi.default_val_number, pi.default_val_string,
			   i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
			   i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.calc_output_round_dp
		  FROM pending_ind pi, ind i, measure m, measure mi
		 WHERE pi.app_sid = i.app_sid(+) AND pi.maps_to_ind_sid = i.ind_sid(+)
	       AND pi.app_sid = m.measure_sid(+) AND pi.measure_sid = m.measure_sid(+)
	       AND i.app_sid = mi.app_sid(+) AND i.measure_sid = mi.measure_sid(+)
	       AND (pi.parent_ind_id = in_parent_ind_id OR (in_parent_ind_id IS NULL AND pi.parent_ind_id IS NULL))
	       AND pi.pending_dataset_id = in_pending_dataset_Id
	     ORDER BY pi.pos;
END;


PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_include_stored_calcs	IN	NUMBER
)
AS
	v_ind_list	T_SID_AND_DESCRIPTION_TABLE;
BEGIN	
	-- select all indicators where they map to an indicator (if they don't
	-- map to an indicator then they can't be being used in a calculation)
	SELECT T_SID_AND_DESCRIPTION_ROW(0, maps_to_ind_sid, pi.description)
	  BULK COLLECT INTO v_ind_list
	  FROM approval_step_ind apsi, pending_ind pi
	 WHERE approval_step_id = in_approval_Step_id
	   AND apsi.pending_ind_id = pi.pending_ind_id
	   AND maps_to_ind_sid IS NOT NULL;
	
	datasource_pkg.Init(v_ind_list, in_include_stored_calcs);
END;


-- specific version which pulls certain stuff (e.g. tolerances) from pending_ind
PROCEDURE GetAllIndDetails(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT i.ind_sid, NVL(pi.description, i.description) description,	 
   			   NVL(NVL(i.scale, m.scale),0) scale,
   			   NVL(NVL(i.format_mask, m.format_mask),'#,##0') format_mask, 
   			   NVL(i.divisibility, NVL(m.divisibility, csr_data_pkg.DIVISIBILITY_DIVISIBLE)) divisibility,
   			   NVL(pi.aggregate, i.aggregate) aggregate, i.period_set_id, i.period_interval_id, 
   			   i.do_temporal_aggregation, i.calc_description, i.calc_xml, i.ind_type,
   			   i.calc_start_dtm_adjustment,
   			   NVL(m.description,'none') measure_description, i.measure_sid, NVL(pi.info_xml, i.info_xml) info_xml, i.start_month, i.gri, 
			   i.parent_sid, NVL(pi.pos, i.pos) pos, i.target_direction, i.active,
               CASE WHEN pi.tolerance_type IS NULL THEN i.pct_lower_tolerance ELSE pi.pct_lower_tolerance END pct_lower_tolerance,
               CASE WHEN pi.tolerance_type IS NULL THEN i.pct_upper_tolerance ELSE pi.pct_upper_tolerance END pct_upper_tolerance,
               NVL(pi.tolerance_type, i.tolerance_type) tolerance_type,
               i.factor_type_id, i.gas_measure_sid, i.gas_type_id, i.map_to_ind_sid,
               i.ind_activity_type_id, i.core, i.roll_forward, i.normalize, i.prop_down_region_tree_sid, i.is_system_managed,
               i.calc_fixed_start_dtm, i.calc_fixed_end_dtm, i.lookup_key, i.calc_output_round_dp,
			   CASE WHEN rm.ind_sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
		 FROM (
		 	SELECT dep_ind_sid
		 	  FROM TABLE(datasource_pkg.DependenciesTable)
		 	 UNION -- union eliminates any duplicates for us
		 	SELECT sid_id  
		 	  FROM TABLE(datasource_pkg.GetInds)
		     )x, v$ind i, measure m, pending_ind pi, approval_step aps, region_metric rm
	      WHERE i.ind_sid = x.dep_ind_sid 
	        AND i.measure_sid = m.measure_sid(+) -- we pull indicators even if they have no measure - sometimes they have null values in pending_val because there are notes etc	        
            AND pi.maps_to_ind_sid(+) = i.ind_sid            
            AND i.ind_sid = rm.ind_sid(+)
            AND pi.pending_dataset_id= aps.pending_dataset_id(+)
            AND aps.approval_step_id(+) = in_approval_step_id;
END;

PROCEDURE GetDataSourceValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	DELETE FROM temp_ind;
	INSERT INTO temp_ind (app_sid, ind_sid)
		SELECT /*+ALL_ROWS*/ DISTINCT SYS_CONTEXT('SECURITY','APP'), column_value
		  FROM TABLE(datasource_pkg.GetValueInds);
		  
	DELETE FROM temp_pending_region;
	INSERT INTO temp_pending_region (app_sid, pending_region_id, maps_to_region_sid)
		SELECT app_sid, pending_region_id, maps_to_region_sid
		  FROM pending_region
	  	  	   START WITH pending_region_id IN (SELECT pending_region_id 
	  	  	   									  FROM approval_step_region 
	  	  	   									 WHERE approval_step_id = in_approval_step_id)
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR pending_region_id = parent_region_id;
			   
	OPEN out_cur FOR
		-- stuff from pending_val we need (might not be in our approval step, but might be needed for calculations)
		SELECT /*+ALL_ROWS*/ pp.start_dtm, pp.end_dtm, pv.pending_region_id, pi.pending_ind_id, ti.ind_sid maps_to_ind_sid, pv.val_number,
			   pv.from_val_number, pv.from_measure_conversion_id,
			   1 priority
		  FROM pending_val pv
		  JOIN pending_ind pi ON pi.pending_ind_id = pv.pending_ind_id AND pi.app_sid = pv.app_sid
		  JOIN temp_ind ti ON ti.ind_sid = pi.maps_to_ind_sid AND ti.app_sid = pi.app_sid
		  JOIN pending_period pp ON pp.pending_period_id = pv.pending_period_id AND pp.app_sid = pv.app_sid
		  JOIN temp_pending_region tpr ON tpr.pending_region_id = pv.pending_region_id AND tpr.app_sid = pv.app_sid
		 WHERE pp.end_dtm > in_start_dtm
		   AND pp.start_dtm < in_end_dtm
		UNION ALL
		-- stuff from val we need (might not be in our approval step, but might be needed for calculations)
		SELECT /*+ALL_ROWS*/ v.period_start_dtm start_dtm, v.period_end_dtm end_dtm, pr.pending_region_id, null pending_ind_Id, ti.ind_sid maps_to_ind_sid, v.val_number,
			   v.entry_val_number from_val_number, v.entry_measure_conversion_id from_measure_conversion_id,
			   2 priority
		  FROM val v
		  JOIN temp_ind ti ON ti.ind_sid = v.ind_sid AND ti.app_sid = v.app_sid
		  JOIN temp_pending_region tpr ON tpr.maps_to_region_sid = v.region_sid AND tpr.app_sid = v.app_sid
		  JOIN pending_region pr ON pr.maps_to_region_sid = v.region_sid AND pr.app_sid = v.app_sid
		 WHERE v.period_end_dtm > in_start_dtm
		   AND v.period_start_dtm < in_end_dtm
         -- sorted for running through the value normaliser
         ORDER BY maps_to_ind_sid, pending_region_id, start_dtm, priority, end_dtm DESC;
END;


-- C# component relies upon sort order (pending_val_id)
PROCEDURE GetApprovalStepValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR	
		WITH apsr AS (
		    SELECT /*+ALL_ROWS*/ DISTINCT app_sid, pending_region_id
			   		  FROM pending_region
			  			   START WITH (app_sid, pending_region_id) IN (
			  			   		SELECT app_sid, pending_region_id 
			  			   		  FROM approval_step_region 
			  			   		 WHERE approval_step_id = in_approval_step_id)
						   CONNECT BY PRIOR app_sid = app_sid AND PRIOR pending_region_id = parent_region_id)
		SELECT pv.pending_val_Id, pv.pending_ind_id, pv.pending_region_id, pp.pending_period_id, 
			   pp.start_dtm, pp.end_dtm, pv.val_number, pv.val_string, pv.approval_step_id,
			   pv.from_val_number, pv.from_measure_conversion_id, pi.maps_to_ind_sid, pv.note,
			   pvv.explanation variance_explanation, pv.action,
			   (SELECT COUNT(*) FROM pending_val_file_upload pvfu WHERE pvfu.pending_val_id = pv.pending_val_id AND pvfu.app_sid = pv.app_sid) file_upload_count
		  FROM pending_val pv
		  JOIN pending_period pp ON pp.pending_period_id = pv.pending_period_id AND pp.app_sid = pv.app_sid
		  JOIN approval_step_ind apsi ON apsi.pending_ind_id = pv.pending_ind_id AND apsi.app_sid = pv.app_sid
		  JOIN pending_ind pi ON pi.pending_ind_id = apsi.pending_ind_id AND pi.app_sid = apsi.app_sid
		  JOIN apsr ON apsr.pending_region_id = pv.pending_region_id AND apsr.app_sid = pv.app_sid
		  LEFT JOIN pending_val_variance pvv ON pvv.pending_val_id = pv.pending_val_id AND pvv.app_sid = pv.app_sid
		 WHERE apsi.approval_step_id = in_approval_step_id
         --  AND pi.maps_to_ind_sid IS NULL -- exclude mapped inds (we've got mapped inds already) 
         -- ignore the above - we now pull all values that have been entered so we have measure conversion ids etc
         ORDER BY pending_val_id;
END;

PROCEDURE GetApprovalStepModels(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT apsm.model_sid, apsm.link_description, apsm.icon_cls
		  FROM approval_step aps
		  LEFT JOIN approval_step_model apsm ON aps.approval_step_id = apsm.approval_step_id AND aps.app_sid = apsm.app_sid
		 WHERE apsm.model_sid IS NOT NULL AND (level = 1 OR apsm.subdelegations = 'Y')
		 START WITH	aps.approval_step_id = in_approval_step_id
	   CONNECT BY aps.approval_step_id = PRIOR aps.parent_step_id AND aps.app_sid = PRIOR aps.app_sid
		 ORDER BY apsm.model_sid; -- Just so that the order is fixed. Could add a pos column if it becomes necessary.
END;

PROCEDURE ClearApprovalStepModels(
	in_approval_step_sid	IN	approval_step_model.approval_step_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_approval_step_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the approval step with sid ' || in_approval_step_sid);
	END IF;
	
	DELETE FROM approval_step_model
	 WHERE approval_step_id = in_approval_step_sid;
END;

PROCEDURE AddApprovalStepModel(
	in_approval_step_sid	IN	approval_step_model.approval_step_id%TYPE,
	in_model_sid			IN	approval_step_model.model_sid%TYPE,
	in_link_description		IN	approval_step_model.link_description%TYPE,
	in_icon_cls				IN	approval_step_model.icon_cls%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_approval_step_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the approval step with sid ' || in_approval_step_sid);
	END IF;
	
	INSERT INTO approval_step_model (approval_step_id, model_sid, link_description, icon_cls)
	VALUES (in_approval_step_sid, in_model_sid, in_link_description, in_icon_cls);
END;

-- C# component relies upon sort order (pending_val_id)
PROCEDURE GetApprovalStepVariances(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR	
		WITH apsr AS (
		    SELECT DISTINCT pending_region_id
		      FROM (
		        SELECT pending_region_id, parent_region_Id
			      FROM PENDING_REGION
			     START WITH pending_region_id IN (
			     	SELECT pending_region_id FROM APPROVAL_STEP_REGION WHERE approval_step_id = in_approval_step_id
			     )
			CONNECT BY PRIOR pending_region_id = parent_region_id                
		     )
		)
		SELECT pv.pending_ind_id, pv.pending_region_id, pv.pending_period_id, pv.pending_val_id, 
			variance, compared_with_start_dtm, compared_with_end_dtm, explanation
		  FROM APPROVAL_STEP_IND apsi, apsr, PENDING_VAL pv, PENDING_VAL_VARIANCE pvv, pending_ind pi
		 WHERE apsi.approval_step_id = in_approval_step_id
           AND apsi.pending_ind_id = pi.pending_ind_id
		   AND apsi.pending_ind_id = pv.pending_ind_Id
		   AND apsr.pending_region_id = pv.pending_region_id
		   AND pv.pending_val_id = pvv.pending_val_id
         ORDER BY pv.pending_val_id;
         --  AND pi.maps_to_ind_sid IS NULL -- exclude mapped inds (we've got mapped inds already) 
         -- ignore the above - we now pull all values that have been entered so we have measure conversion ids etc
         --ORDER BY pending_ind_id, pending_region_id, start_dtm, end_dtm DESC;
END;


PROCEDURE SetVarianceExplanation(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,	
	in_explanation					IN	pending_val_variance.explanation%TYPE
)
AS	
	v_pending_val_id	pending_val.pending_val_id%TYPE;
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	BEGIN
		INSERT INTO pending_val_variance
			(pending_val_id, compared_with_start_dtm, compared_with_end_dtm, variance, explanation)
		VALUES
			(v_pending_val_id, sysdate, sysdate, 0, in_explanation); -- TODO: pass in real dates + variance
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE pending_val_variance 
			   SET explanation = in_explanation
			 WHERE pending_val_id = v_pending_val_id;
	END;	
END;

-- this is cack - temporary measure - we either need to shove this stuff into the RawValueNormaliser
-- OR have this checked etc
PROCEDURE SetDefaultValue(
    in_pending_dataset_id   IN  pending_Dataset.pending_dataset_id%TYPE,
    in_ind_sid              IN  security_pkg.T_SID_ID,
    in_default_value        IN  pending_val.val_number%TYPE
)
AS
BEGIN
    -- store in pending_ind
    UPDATE pending_ind 
       SET default_val_string = in_default_value 
     WHERE maps_to_ind_sid = in_ind_sid
       AND pending_dataset_id = in_pending_dataset_id;
    -- update
    FOR r IN (
        SELECT DISTINCT pending_region_id, pending_period_id
          FROM approval_step_region apsr, pending_period pp, approval_step aps
         WHERE aps.approval_step_id = apsr.approval_step_id
           AND aps.pending_dataset_id = in_pending_dataset_id
           AND pp.pending_dataset_id = in_pending_dataset_id
    )
    LOOP
        INSERT INTO pending_val (pending_val_id, pending_ind_id, pending_region_id, pending_period_id, val_number)
			SELECT pending_val_id_seq.nextval, pending_ind_id, r.pending_region_id, r.pending_period_id, default_val_string
			  FROM pending_ind 
			 WHERE maps_to_ind_sid = in_ind_sid
			   AND pending_Dataset_id = in_pending_dataset_id;
    END LOOP;
END;


PROCEDURE SetSheetMaxValueCount(
	in_approval_Step_id		IN	approval_step.approval_step_id%TYPE
)
AS
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
	v_distinct_ind		NUMBER(10);
	v_distinct_region	NUMBER(10);
	v_period_count		NUMBER(10);
	v_layout_type		approval_Step.layout_type%TYPE;
	v_cnt				NUMBER(10);
BEGIN
	SELECT layout_type, pending_dataset_id 
	  INTO v_layout_type, v_pending_dataset_id
	  FROM approval_step
	 WHERE approval_step_id = in_approval_Step_id;
	 
	SELECT COUNT(pending_period_id)
	  INTO v_period_count
	  FROM pending_period
	 WHERE pending_dataset_id = v_pending_dataset_id;
	 
	SELECT COUNT(DISTINCT t.pending_ind_id), COUNT(DISTINCT t.pending_region_id)
	  INTO v_distinct_ind, v_distinct_region 
	  FROM TABLE(pending_pkg.GetLeafPointsAsTable(in_approval_step_Id))t,
	  	PENDING_IND pi, PENDING_ELEMENT_TYPE pet, IND i
	 WHERE t.pending_ind_id = pi.pending_ind_id
	   AND pi.element_type = pet.element_type
	   AND pi.maps_to_ind_sid = i.ind_sid(+)
	   AND NVL(i.ind_type, csr_data_pkg.IND_TYPE_NORMAL) IN (csr_data_pkg.IND_TYPE_NORMAL)
	   AND (pet.is_number = 1 OR pet.is_string = 1);
	
	CASE v_layout_type
		WHEN LAYOUT_IND THEN
			v_cnt := v_distinct_ind;
		WHEN LAYOUT_REGION THEN
			v_cnt := v_distinct_region;
		WHEN LAYOUT_PERIOD THEN
			v_cnt := v_period_count;
		WHEN LAYOUT_IND_X_REGION THEN
			v_cnt := v_distinct_ind * v_distinct_region;
		WHEN LAYOUT_IND_X_PERIOD THEN
			v_cnt := v_distinct_ind * v_period_count;
		WHEN LAYOUT_REGION_X_PERIOD THEN
			v_cnt := v_distinct_region * v_period_count;
		ELSE 
			RAISE_APPLICATION_ERROR(-20001, 'Unknown layout type');
	END CASE;
	
	UPDATE approval_step
	   SET max_sheet_value_count = v_cnt
	 WHERE approval_step_id = in_approval_step_Id;
END;


PROCEDURE SetValueAction(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_ids				IN	T_PENDING_IND_IDS,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,	
	in_action   					IN	pending_val.action%TYPE
)
AS	
	v_allow_partial_submit			customer.allow_partial_submit%TYPE;
BEGIN
    -- crap hack for ODP.NET
    IF in_pending_ind_ids IS NULL OR (in_pending_ind_ids.COUNT = 1 AND in_pending_ind_ids(1) IS NULL) THEN
        RETURN;
    END IF;	 
    
    -- make sure we aren't setting X or R if allow_partial_submit is false
    -- this seems to be happening sometimes, which is a bug, but hasn't been reproduced yet,
    -- so the assertion should help
	GetAllowPartialSubmit(v_allow_partial_submit);
	IF v_allow_partial_submit = 0 AND in_action != 'S' THEN
		RAISE_APPLICATION_ERROR(-20001, 'Assertion failure: trying to set the action of a pending_val to something other S when allow partial submit is disabled');
	END IF;

    FORALL i IN in_pending_ind_ids.FIRST..in_pending_ind_ids.LAST
        UPDATE pending_val
           SET action = in_action
         WHERE pending_ind_id = in_pending_ind_ids(i)
           AND pending_region_id = in_pending_region_Id
           AND pending_period_id = in_pending_period_Id;
END;


PROCEDURE AddComment(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_approval_step_id				IN	pending_val.approval_step_id%TYPE,
	in_pending_ind_id				IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id			IN	pending_val.pending_region_id%TYPE,
	in_pending_period_id			IN	pending_val.pending_period_id%TYPE,	
	in_comment_text					IN	issue_Log.message%TYPE,
	out_issue_id					OUT	issue.issue_id%TYPE
)
AS	
	v_pending_val_id	        pending_val.pending_val_id%TYPE;	
BEGIN
	GetOrSetPendingValId(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, v_pending_val_id
	);
	
	-- new issues code
	issue_pkg.LogIssuePV(
		in_act_id, in_approval_step_id, in_pending_ind_id, 
		in_pending_region_id, in_pending_period_id, in_comment_text, out_issue_id
	);
	
END;

PROCEDURE MarkCommentAsRead(
    in_act_id       IN  security_pkg.T_ACT_ID,
    in_issue_log_id	IN	issue_log.issue_log_id%TYPE
)
AS
BEGIN
	-- new issues code
    issue_pkg.MarkLogEntryAsRead(in_act_id, in_issue_log_id);
END;

PROCEDURE DeleteComment(
    in_act_id        IN  security_pkg.T_ACT_ID,
    in_issue_log_id  IN  issue_log.issue_log_id%TYPE
)
AS
BEGIN
	-- new issues code
	issue_pkg.DeleteLogEntry(in_act_id, in_issue_log_id);
END;

FUNCTION ConcatApsRegions(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_regions			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT r.description
		  FROM approval_step_region dr, pending_REGION r 
		 WHERE approval_step_id = in_approval_step_id
		   AND dr.pending_region_id = r.pending_region_id
		 ORDER BY r.description
	)
	LOOP
		-- if we've shown enough already but we're still in the loop then
		-- there's more to come, so shove on some dots and bail out.
		-- Do the same if we're about to run out of string buffer
		IF LENGTH(v_item || v_sep || r.description)<1020 AND v_cnt <= in_max_regions THEN
			v_item := v_item || v_sep || r.description;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;




FUNCTION ConcatApsUsers(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN

	FOR r IN (	
		SELECT full_name 
		  FROM CSR_USER, APPROVAL_STEP_USER du
		 WHERE csr_user_sid = du.user_sid
		   AND approval_step_id = in_approval_step_id
	)
	LOOP
		IF LENGTH(v_item || v_sep || r.full_name)<1020 AND v_cnt < in_max_users THEN
			v_item := v_item || v_sep || r.full_name;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;



FUNCTION ConcatApsUserEmails(
	in_approval_step_id		IN	approval_step.approval_step_id%TYPE,
	in_max_users			IN  NUMBER DEFAULT 100
) RETURN VARCHAR2
IS
	v_item		VARCHAR2(1024) := '';
	v_sep		VARCHAR2(2) := '';
	v_cnt		NUMBER(10) := 0;
BEGIN

	FOR r IN (	
		SELECT email
		  FROM CSR_USER, APPROVAL_STEP_USER du
		 WHERE csr_user_sid = du.user_sid
		   AND approval_step_id = in_approval_step_id
		   AND csr_user.app_sid = du.app_sid
	)
	LOOP
		IF LENGTH(v_item || v_sep || r.email)<1020 AND v_cnt < in_max_users THEN
			v_item := v_item || v_sep || r.email;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		v_sep := ', ';
		v_cnt := v_cnt + 1;
	END LOOP;
	RETURN v_item;
END;

-- this variant takes user_sid and pending_dataset_Id
PROCEDURE GetNewRootApprovalStepInfo(
    in_user_sid				IN  security_pkg.T_SID_ID,
    in_pending_dataset_Id	IN	security_pkg.T_SID_ID,
    out_cur					OUT SYS_REFCURSOR
)
AS	
BEGIN     
    OPEN out_cur FOR
		SELECT DISTINCT aps.label || ' (' ||pr.description ||')' label,
           	   pending_pkg.ConcatApsUsers(aps.parent_step_id) delegator_full_name,
           	   c.approval_step_sheet_url||'apsId='||ass.approval_step_id||CHR(38)||'sheetKey='||ass.sheet_key sheet_url
          FROM approval_step aps
            JOIN approval_step_region apsr ON aps.approval_step_id = apsr.approval_step_Id AND aps.app_sid = apsr.app_sid
            JOIN approval_step_user apsu ON aps.approval_step_id = apsu.approval_step_id AND aps.app_sid = apsu.app_sid
            JOIN pending_region pr ON apsr.pending_region_id = pr.pending_region_id AND apsr.app_sid = pr.app_sid
            JOIN approval_step_sheet ass ON aps.approval_step_id = ass.approval_step_id AND ass.app_sid = aps.app_sid
            JOIN csr_user cu ON apsu.user_sid = cu.csr_user_sid AND cu.app_sid = apsu.app_sid
            JOIN customer c ON aps.app_sid = c.app_sid
         WHERE apsu.user_sid = in_user_sid
           AND pr.pending_dataset_id = in_pending_dataset_id;
END;


PROCEDURE GetSubdelegationAlertInfo(
    in_approval_step_ids			IN  security_pkg.T_SID_IDS,
    out_cur							OUT SYS_REFCURSOR
)
AS
	t_aps_ids	security.T_SID_TABLE;
BEGIN
	t_aps_ids := security_pkg.SidArrayToTable(in_approval_step_ids);        
    OPEN out_cur FOR
		SELECT DISTINCT aps.label || ' (' ||pr.description ||')' label,
           	   pending_pkg.ConcatApsUsers(aps.parent_step_id) delegator_full_name,
           	   c.approval_step_sheet_url||'apsId='||ass.approval_step_id||CHR(38)||'sheetKey='||ass.sheet_key sheet_url
          FROM csr_user cu, approval_step aps, approval_step_region apsr, approval_step_region apspr,
          	   pending_region pr, customer c, TABLE(t_aps_ids) apsids, approval_step_sheet ass
         WHERE apsr.approval_step_id = aps.approval_step_id AND apsr.app_sid = aps.app_sid 
           AND apspr.pending_region_id = apsr.rolls_up_to_region_id AND apspr.app_sid = apsr.app_sid 
           AND apspr.approval_step_id = aps.parent_step_id AND apspr.app_sid = aps.app_sid 
           AND pr.pending_region_id = apsr.pending_region_id AND pr.app_sid = apsr.app_sid
           AND c.app_sid = aps.app_sid
           AND ass.app_sid = aps.app_sid AND ass.approval_step_id = aps.approval_step_id
           AND ass.approval_step_id = apsids.column_value;
END;

PROCEDURE GetSubmitAlertInfo(
    in_approval_step_id    			IN  approval_step.approval_step_id%TYPE,
    in_sheet_key					IN  approval_step_sheet.sheet_key%TYPE,
    out_cur                			OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ap.label, apsu.user_sid, aps.label sheet_label,
			   c.approval_step_sheet_url||'apsId='||ap.approval_step_id||CHR(38)||'sheetKey='||aps.sheet_key sheet_url
          FROM approval_step ap, approval_step_sheet aps, approval_step_user apsu, customer c
		 WHERE ap.parent_step_id = apsu.approval_step_id AND ap.app_sid = apsu.app_sid
		   AND ap.approval_step_id = aps.approval_step_id AND ap.app_sid = aps.app_sid
           AND ap.app_sid = c.app_sid AND ap.app_sid = c.app_sid
           AND apsu.is_lurker = 0 -- don't email lurkers
           AND ap.approval_step_id = in_approval_step_id
           AND aps.sheet_key = in_sheet_key;
END;

PROCEDURE GetSubmitThankYouAlertInfo(
    in_approval_step_id				IN  approval_step.approval_step_id%TYPE,
    out_cur                			OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ap.label, pending_pkg.ConcatApsUsers(ap.parent_step_id) to_names, c.approval_step_sheet_url
          FROM customer c, approval_step ap
         WHERE c.app_sid = ap.app_sid AND ap.approval_step_id = in_approval_step_id;
END;

PROCEDURE GetApprovalThankYouAlertInfo(
    in_approval_step_id    IN  approval_step.approval_step_id%TYPE,
    out_cur                OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
        SELECT ap.label, cu.csr_user_sid to_user_sid, c.approval_step_sheet_url
          FROM approval_step ap, approval_step_user apsu, csr_user cu, customer c
         WHERE ap.approval_step_Id = in_approval_step_id
           AND ap.app_sid = apsu.app_sid AND ap.approval_step_Id = apsu.approval_step_id  
           AND cu.app_sid = apsu.app_sid AND cu.csr_user_sid = apsu.user_sid
           AND ap.app_sid = c.app_sid
		   AND apsu.is_lurker = 0; -- don't email lurkers
END;

PROCEDURE GetIndicatorsThatHaveValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
    SELECT pending_ind.pending_ind_id FROM pending_ind WHERE
          pending_dataset_id = in_pending_dataset_id AND
          EXISTS (SELECT pending_val.pending_ind_id FROM pending_val WHERE pending_val.pending_ind_id = pending_ind.pending_ind_id);
END;

PROCEDURE GetRegionsThatHaveValues(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
    SELECT pending_region.pending_region_id FROM pending_region WHERE
          pending_dataset_id = in_pending_dataset_id AND
          EXISTS (SELECT pending_val.pending_region_id FROM pending_val WHERE pending_val.pending_region_id = pending_region.pending_region_id);
END;

PROCEDURE GetPathsForAllRegionsMappedTo(
	in_act_id				IN	security_pkg.T_ACT_ID,
    in_app_sid         IN  security.securable_object.sid_id%TYPE,
    in_pending_dataset_id	IN	pending_region.pending_dataset_id%TYPE,
    out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
    OPEN out_cur FOR
    SELECT region_id, path FROM 
    (
       SELECT sid_id, parent_sid_id, LEVEL, SYS_CONNECT_BY_PATH(sid_id, '/') PATH, CONNECT_BY_ROOT(sid_id) region_id FROM security.securable_object
       START WITH sid_id IN (SELECT maps_to_region_sid FROM pending_region WHERE pending_dataset_id = in_pending_dataset_id)
       CONNECT BY PRIOR parent_sid_id = sid_id
    ) WHERE parent_sid_id = in_app_sid;
END;

-- delete pending_ind / pending_region: what happens?

-- alter approval template (ripple effect, possible conflicts?)

-- 

-- XXX: ported from web code, no security
PROCEDURE GetValueFromIRP_INSECURE(
	in_pending_ind_id		IN	pending_val.pending_ind_id%TYPE,
	in_pending_region_id	IN	pending_region.pending_region_id%TYPE,
	in_pending_period_id	IN	pending_period.pending_period_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT val_number, val_string, from_val_number, from_measure_conversion_id 
  		  FROM pending_val
  		 WHERE pending_ind_id = in_pending_ind_id AND pending_region_id = in_pending_region_id AND
   			   pending_period_id = in_pending_period_id;
END;

PROCEDURE GetAllowPartialSubmit(
	out_allow_partial_submit	OUT	customer.allow_partial_submit%TYPE
)
AS
BEGIN
	-- This is ok as it's public information
	SELECT allow_partial_submit
	  INTO out_allow_partial_submit
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCascadeReject(
	out_cascade_reject			OUT	customer.cascade_reject%TYPE
)
AS
BEGIN
	-- This is ok as public information
	SELECT cascade_reject
	  INTO out_cascade_reject
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION GetSheetQueryString(
    in_pending_ind_id       IN	pending_val.pending_ind_id%TYPE,
    in_pending_region_id    IN	pending_val.pending_region_id%TYPE,
    in_pending_period_id    IN	pending_val.pending_period_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
	RETURN GetSheetQueryString(SYS_CONTEXT('SECURITY', 'APP'), in_pending_ind_id, in_pending_region_id, in_pending_period_id, in_user_sid);
END;

-- the sheet and sheet key to access a specific sheet for a specific value will depend
-- on the user. This gets the URL. It's layout specific but hasn't been adapted for
-- multiple layouts yet.
FUNCTION GetSheetQueryString(
	in_app_sid				IN	customer.app_sid%TYPE,
    in_pending_ind_id       IN	pending_val.pending_ind_id%TYPE,
    in_pending_region_id    IN	pending_val.pending_region_id%TYPE,
    in_pending_period_id    IN	pending_val.pending_period_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
    v_url   VARCHAR2(255);
BEGIN
    BEGIN
        SELECT /*+ALL_ROWS*/ url
          INTO v_url
          FROM (SELECT 'apsId='||aps.approval_step_Id||CHR(38)||'sheetKey='||apsh.sheet_key url
		          FROM approval_step aps, approval_step_sheet apsh, 
		               approval_step_ind apsi, approval_step_region apsr, 
		               approval_step_user apsu, (
		                -- where the approval_step is for the region for which this value is set, 
		                -- or for a region than encompasses it (i.e higher up the tree)
		                SELECT app_sid, pending_region_id, level lvl 
		                  FROM pending_region
		                 START WITH pending_region_id = in_pending_region_id
		               CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_region_id = pending_region_id
		             ) apsr_tree
		         WHERE apsi.app_sid = in_app_sid -- this is called without being logged on (by the issues alert batch)
		           and apsi.pending_ind_id = in_pending_ind_id
		           AND apsr.app_sid = apsr_tree.app_sid AND apsr.pending_region_id = apsr_tree.pending_region_id 
		           AND apsh.pending_period_id = in_pending_period_id -- TODO: layout specific
		           AND aps.app_sid = apsh.app_sid AND aps.approval_Step_id = apsh.approval_step_id
		           AND aps.app_sid = apsi.app_sid AND aps.approval_Step_id = apsi.approval_step_id
		           AND aps.app_sid = apsr.app_sid AND aps.approval_Step_id = apsr.approval_step_id
		           AND aps.app_sid = apsu.app_sid AND aps.approval_Step_id = apsu.approval_step_id
		           AND apsu.user_sid = in_user_sid
		        ORDER BY apsr_tree.lvl DESC)
		 WHERE ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
    
    RETURN v_url;
END;

FUNCTION GetSheetQueryString(
	in_pending_val_Id		IN	pending_val.pending_val_id%TYPE,
    in_user_sid             IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
    v_pending_ind_id       pending_val.pending_ind_id%TYPE;
    v_pending_region_id    pending_val.pending_region_id%TYPE;
    v_pending_period_id    pending_val.pending_period_id%TYPE;
BEGIN
	SELECT pending_ind_id, pending_region_id, pending_period_Id
	  INTO v_pending_ind_id, v_pending_region_id, v_pending_period_Id
	  FROM pending_Val
	 WHERE pending_val_id = in_pending_val_Id;
	 
	RETURN GetSheetQueryString(v_pending_ind_id, v_pending_region_id, v_pending_period_id, in_user_sid);
END;

PROCEDURE InsertParentApprovalStep(
	in_approval_step_id			IN	approval_step.approval_step_id%TYPE,
	in_template_step_id			IN	approval_step.approval_step_id%TYPE,
	in_copy_users				IN	NUMBER,
	out_new_approval_step_id	OUT	approval_step.approval_step_id%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_pending_dataset_id	pending_dataset.pending_dataset_id%TYPE;
	v_parent_step_id		approval_step.parent_step_id%TYPE;
	v_act					security_pkg.T_ACT_ID;
	v_approval_step_sid		security_pkg.T_SID_ID;
	v_step					approval_step.label%TYPE;
BEGIN
	v_act := security_pkg.GetACT();
	  
	SELECT pending_dataset_id INTO v_pending_dataset_id
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;
	 
	SELECT parent_step_id INTO v_parent_step_id
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;
	
	out_new_approval_step_id := CreateApprovalStepSID(NVL(v_parent_step_id, v_pending_dataset_id));
	  
	INSERT INTO approval_step
		   (approval_step_id, parent_step_id, label, based_on_step_id, pending_dataset_id, layout_type, max_sheet_value_count, working_day_offset_from_due)
	SELECT out_new_approval_step_id, parent_step_id, label, NULL, pending_dataset_id, layout_type, max_sheet_value_count, working_day_offset_from_due
	  FROM approval_step
	 WHERE approval_step_id = in_approval_step_id;
	 
	UPDATE approval_step
	   SET parent_step_id = out_new_approval_step_id
	 WHERE approval_step_id = in_approval_step_id;
	 
	securableobject_pkg.MoveSO(v_act, in_approval_step_id, out_new_approval_step_id);
	 
	UPDATE approval_step
	   SET (label, layout_type, max_sheet_value_count, working_day_offset_from_due) =
		   (SELECT label, layout_type, max_sheet_value_count, working_day_offset_from_due
			  FROM approval_step
			 WHERE approval_step_id = in_template_step_id)
	 WHERE approval_step_id = out_new_approval_step_id;
	 	 
	INSERT INTO approval_step_ind
		   (approval_step_id, pending_ind_id)
	SELECT out_new_approval_step_id, pending_ind_id
	  FROM approval_step_ind
	 WHERE approval_step_id = in_template_step_id;
	
	INSERT INTO approval_step_region
		   (approval_step_id, pending_region_id, rolls_up_to_region_id)
	SELECT out_new_approval_step_id, pending_region_id, rolls_up_to_region_id
	  FROM approval_step_region
	 WHERE approval_step_id = in_template_step_id;
	 
	INSERT INTO approval_step_sheet
		   (approval_step_id, sheet_key, label, pending_period_id, pending_ind_id, pending_region_id, submitted_value_count, submit_blocked, visible, due_dtm,
		   approver_response_due_dtm, reminder_dtm)
	SELECT out_new_approval_step_id, sheet_key, label, pending_period_id, pending_ind_id, pending_region_id, submitted_value_count, submit_blocked, visible, due_dtm,
		   approver_response_due_dtm, reminder_dtm
	  FROM approval_step_sheet
	 WHERE approval_step_id = in_template_step_id;
	 
	IF in_copy_users = 1 THEN
		INSERT INTO approval_step_user (approval_step_id, user_sid, fallback_user_sid, read_only, is_lurker)
			SELECT out_new_approval_step_id, user_sid, fallback_user_sid, read_only, is_lurker
			  FROM approval_step_user
			 WHERE approval_step_id = in_template_step_id;

		INSERT INTO approval_step_sheet_alert (approval_step_id, sheet_key, user_sid, reminder_sent_dtm, overdue_sent_dtm)
			SELECT out_new_approval_step_id, sheet_key, user_sid, reminder_sent_dtm, overdue_sent_dtm
			  FROM approval_step_sheet_alert
			 WHERE approval_step_id = in_template_step_id;
	ELSE
		user_pkg.GetSid(v_act, v_user_sid);
		
		INSERT INTO approval_step_user
			   (approval_step_id, user_sid, fallback_user_sid, read_only, is_lurker)
		VALUES
			   (out_new_approval_step_id, v_user_sid, NULL, 0, 0);

		INSERT INTO approval_step_sheet_alert (approval_step_id, sheet_key, user_sid, reminder_sent_dtm, overdue_sent_dtm)
			SELECT apsh.approval_step_id, apsh.sheet_key, apsu.user_sid, 
				   CASE WHEN apsh.reminder_dtm <= SYSDATE THEN NULL ELSE apsh.reminder_dtm END,
				   CASE WHEN apsh.due_dtm <= SYSDATE THEN NULL ELSE apsh.due_dtm END
			  FROM approval_step_sheet apsh, approval_step_user apsu
			 WHERE apsh.app_sid = apsu.app_sid AND apsh.approval_step_id = apsu.approval_step_id
			   AND apsu.approval_step_id = out_new_approval_step_id;		
	END IF;
	
	SELECT label INTO v_step FROM approval_step WHERE approval_step_id = out_new_approval_step_id;
	
	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetApp(), out_new_approval_step_id, 'Inserted approval step "{0}"', v_step, in_approval_step_id, in_template_step_id);
END;

PROCEDURE SetApprovalStepSheetsVisible(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_approval_step_id		IN	pending_val.approval_step_id%TYPE,
	in_visible				IN	NUMBER
)
AS
BEGIN
	UPDATE approval_step_sheet
	   SET visible = in_visible
	 WHERE approval_step_id = in_approval_step_id;
END;

PROCEDURE FilterUsers(
	in_filter			IN	VARCHAR2,
	in_approval_step_id	IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR,
	out_total_num_users	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_total_num_users FOR
		SELECT COUNT(*) total_num_users, csr_user_pkg.MAX_USERS max_size
		  FROM csr_user cu
		  JOIN security.user_table ON security.user_table.sid_id = cu.csr_user_sid
		 WHERE (LOWER(TRIM(full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(full_name)) LIKE '% ' || LOWER(in_filter) || '%') 
		   AND security.user_table.account_enabled = 1
		   AND cu.app_sid = security_pkg.GetApp()
		   AND cu.hidden = 0 -- Only show active users.
		   AND cu.csr_user_sid NOT IN (SELECT user_sid FROM approval_step_user WHERE approval_step_id = in_approval_step_id AND app_sid = security_pkg.GetApp())
		   AND cu.csr_user_sid NOT IN (
				SELECT user_sid
				  FROM approval_step_user
				 WHERE approval_step_id = in_approval_step_id
				   AND app_sid = security_pkg.GetApp()
			);
	
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT x.*, rownum rn
			  FROM (
					SELECT cu.csr_user_sid user_sid, cu.full_name
					  FROM csr_user cu
					  JOIN security.user_table ON security.user_table.sid_id = cu.csr_user_sid
					 WHERE (LOWER(TRIM(full_name)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(full_name)) LIKE '% ' || LOWER(in_filter) || '%') 
					   AND security.user_table.account_enabled = 1
					   AND cu.app_sid = security_pkg.GetApp()
					   AND cu.hidden = 0 -- Only show active users.
					   AND cu.csr_user_sid NOT IN (SELECT user_sid FROM approval_step_user WHERE approval_step_id = in_approval_step_id AND app_sid = security_pkg.GetApp())
				  ORDER BY CASE WHEN in_filter IS NULL OR LOWER(TRIM(full_name)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
						   CASE WHEN in_filter IS NULL OR LOWER(TRIM(full_name)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
						   LOWER(TRIM(full_name))
				) x
			)
		 WHERE rn <= csr_user_pkg.MAX_USERS
		 ORDER BY rn;
END;

PROCEDURE FilterRegions(  
	in_filter			IN	VARCHAR2,
	in_approval_step_id	IN	NUMBER,
	in_addingOrRemoving	IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR
)      
AS
BEGIN
	OPEN out_cur FOR
		SELECT pending_region_id, description
		  FROM pending_region
		 WHERE (LOWER(TRIM(description)) LIKE LOWER(in_filter) || '%' OR LOWER(TRIM(description)) LIKE '% ' || LOWER(in_filter) || '%')
		   AND app_sid = security_pkg.GetApp()
		   AND pending_dataset_id = (SELECT pending_dataset_id FROM approval_step WHERE approval_step_id = in_approval_step_id)
		   AND (in_addingOrRemoving = 0 -- Adding
				AND pending_region_id NOT IN
				(SELECT pending_region_id
			     FROM pending_region
			     START WITH pending_region_id IN (SELECT pending_region_id FROM approval_step_region WHERE approval_step_id = in_approval_step_id)
			     CONNECT BY pending_region.pending_region_id = PRIOR parent_region_id) -- You can't add a parent region to an approval step if a child region has already been added.
			   )
			OR (in_addingOrRemoving = 1 -- Removing
			    AND pending_region_id IN
			    (SELECT pending_region_id
			     FROM approval_step_region
			     WHERE approval_step_id = in_approval_step_id)
			   )
	  ORDER BY CASE WHEN in_filter IS NULL OR LOWER(TRIM(description)) LIKE LOWER(in_filter) || '%' THEN 0 ELSE 1 END, -- Favour names that start with the provided filter.
			   CASE WHEN in_filter IS NULL OR LOWER(TRIM(description)) || ' ' LIKE '% ' || LOWER(in_filter) || ' %' THEN 0 ELSE 1 END, -- Favour whole words over prefixes.
			   LOWER(TRIM(description));
END;

END pending_pkg;
/

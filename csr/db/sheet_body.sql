CREATE OR REPLACE PACKAGE BODY CSR.Sheet_Pkg AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

/*
	-> when we fetch the delegation regions to show the user, we need to filter on role
	   \_ we need to think about the fact that we might be higher up the deleg tree, i.e.

		   "Data provider"
			 |_ A
			   |_ B

			If I view B's sheet then I need to just show regions that match my role higher up

	-> when you move someone into a role that's linked to delegations, then you should tell them what data they're expected to provide

	-> is_read_only support

	might need to change delegation_pkg.getregions (i.e. on subdeleg page it will list all regions incl those where you're not in the role)
*/

/**
 * Check whether currently logged in user has permissions to access the specified
 * sheet id.
 *
 * @param 		The sheet id
 * @param   	The permission set to check (defaults to READ)
 */
PROCEDURE CheckSheetAccessAllowed(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_permission_set	IN	NUMBER DEFAULT delegation_pkg.DELEG_PERMISSION_READ
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	-- check for read permissions on the delegation
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(security_pkg.getACT, v_delegation_sid, in_permission_set) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to sheet id '||in_sheet_id);
	END IF;
END;

PROCEDURE RaiseSheetCreatedAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SHEET_CREATED) THEN
		RETURN;
	END IF;
	
	INSERT INTO sheet_created_alert (sheet_created_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
	SELECT sheet_created_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), in_sheet_id
	  FROM sheet s
	  JOIN v$delegation_user du ON s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
	  JOIN customer_alert_type cat ON cat.app_sid = s.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CREATED
	  JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
	 WHERE s.sheet_id = in_sheet_id;
END;

-- ============================
-- Create or alter sheets
-- ============================
PROCEDURE CreateSheet(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	DELEGATION.START_DTM%TYPE,
	in_submission_dtm		IN	SHEET.SUBMISSION_DTM%TYPE,
	out_sheet_id			OUT SHEET.SHEET_ID%TYPE,
	out_end_dtm				OUT	SHEET.END_DTM%TYPE
)
AS
	v_require_active_regions	NUMBER := 1;
BEGIN
	CreateSheet(in_act_id, in_delegation_sid, in_start_dtm, in_submission_dtm, v_require_active_regions, out_sheet_id, out_end_dtm);
END;

PROCEDURE CreateSheet(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	DELEGATION.START_DTM%TYPE,
	in_submission_dtm			IN	SHEET.SUBMISSION_DTM%TYPE,
	in_require_active_regions	IN	NUMBER,
	out_sheet_id				OUT SHEET.SHEET_ID%TYPE,
	out_end_dtm					OUT	SHEET.END_DTM%TYPE
)
AS
	CURSOR c_del IS
		SELECT period_set_id, period_interval_id, reminder_offset, end_dtm, created_by_sid, delegation_date_schedule_id
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
	r_del	c_del%ROWTYPE;
	CURSOR c_sheet(v_start_dtm DATE, v_end_dtm DATE) IS
		SELECT sheet_id, start_dtm, end_dtm
		  FROM sheet
		 WHERE start_dtm < v_end_dtm AND end_dtm > v_start_dtm
		   AND delegation_sid = in_delegation_sid;
	r_sheet							c_sheet%ROWTYPE;
	v_end_dtm						DATE;
	v_user_sid						security_pkg.T_SID_ID;
	v_sheet_history_id				SHEET_HISTORY.sheet_history_id%TYPE;
	v_submission_dtm				sheet.submission_dtm%TYPE;
	v_reminder_dtm					sheet.reminder_dtm%TYPE;
	v_propagate_down				customer.propagate_deleg_values_down%TYPE;
	v_status_according_parent		customer.status_from_parent_on_subdeleg%TYPE;
	v_parent_sheet_id				csr_data_pkg.T_SHEET_ID;
	v_parent_delegation_sid			security_pkg.T_SID_ID;
	v_active_region_count			NUMBER;
	v_regions_active 				NUMBER;
	v_disposal_dtm					region.disposal_dtm%TYPE;
	v_found							BOOLEAN;
BEGIN
	-- TODO: check security
	OPEN c_del;
	FETCH c_del INTO r_del;
	CLOSE c_del;

	-- figure out the end date based on the interval
	v_end_dtm := period_pkg.AddIntervals(r_del.period_set_id, r_del.period_interval_id, in_start_dtm, 1);

	IF in_require_active_regions = 1 THEN
		-- Check that we have got at least one active region for sheet period
		SELECT COUNT(*)
		  INTO v_active_region_count
		  FROM csr.delegation_region dr
		 WHERE (dr.hide_after_dtm IS NULL OR (dr.hide_inclusive = 1 AND v_end_dtm < dr.hide_after_dtm) OR (dr.hide_inclusive = 0 AND dr.hide_after_dtm > in_start_dtm))
		   AND dr.delegation_sid = in_delegation_sid;
		
		IF v_active_region_count = 0 THEN
			out_sheet_id := NULL;
			out_end_dtm := NULL;
			RETURN;		
		END IF;

		-- If all the regions are inactive before the sheet starts, no need to create a new sheet at all.
		SELECT count(active) INTO v_regions_active
		  FROM region
		 WHERE region_sid IN (SELECT region_sid FROM delegation_region WHERE delegation_sid = in_delegation_sid)
		  AND active=1;
		
		-- If there's a mix of dates and nulls, the max actual date is selected. If all null, null is selected
		SELECT MAX(disposal_dtm) INTO v_disposal_dtm
		  FROM region
		 WHERE region_sid IN (SELECT region_sid FROM delegation_region WHERE delegation_sid = in_delegation_sid)
		  AND active=0;
		
		IF v_regions_active = 0 AND (v_disposal_dtm IS NULL OR v_disposal_dtm <= in_start_dtm) THEN
			out_sheet_id := NULL;
			out_end_dtm := NULL;
			RETURN;
		END IF;
	END IF;

	-- Check that this doesn't conflict with another sheet on the system
	OPEN c_sheet(in_start_dtm, v_end_dtm);
	FETCH c_sheet INTO r_sheet;
	v_found := c_sheet%FOUND;
	CLOSE c_sheet;
	IF v_found THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SHEET_OVERLAPS, 'Sheet from '||in_start_dtm||' to '||v_end_dtm||' overlaps with an existing sheet (id '||r_sheet.sheet_id||', start='||r_sheet.start_dtm||', end='||r_sheet.end_dtm||')');
	END IF;

	user_pkg.getsid(in_act_id, v_user_sid);

	-- Calculate submission date using the following rules (see FB24343). Note that in_submission_dtm has been calculated from
	-- schedule_xml.
	--
	-- * If this is a top-level delegation, use in_submission_dtm and calculate reminder_dtm
	--
	-- * If this is a sub-delegation with schedule_xml different to its parent, use the earlier of in_submission_dtm or
	--   submission_dtm from the parent sheet and calculate reminder_dtm
	--
	-- * If this is a sub-delegation with schedule_xml the same as its parent, use the submission_dtm and reminder_dtm from
	--   the parent sheet.
	--
	-- To test schedule_xml columns for equality, we need to treat for example
	-- <recurrences><monthly every-n="1"><day number="1"></day></monthly></recurrences> and
	-- <recurrences><monthly every-n="1"><day number="1"/></monthly></recurrences> as equivalent. The extract() method creates
	-- a new DOM, which in this case will be equal and produce equal string values.
	--
	-- In theory this test could still fail, for instance if sibling nodes are ordered differently in the two XML documents. So
	-- <recurrences><monthly every-n="1"><day-varying type="first" day="monday"></day-varying></monthly></recurrences> and
	-- <recurrences><monthly every-n="1"><day-varying day="monday" type="first"></day-varying></monthly></recurrences>
	-- would be treated as different, although I haven't seen this actually happen.

	SELECT CASE WHEN parent_sid = app_sid THEN NULL ELSE parent_sid END
	  INTO v_parent_delegation_sid
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	IF v_parent_delegation_sid IS NOT NULL THEN
		BEGIN
			v_parent_sheet_id := GetSheetId(v_parent_delegation_sid, in_start_dtm, v_end_dtm);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_parent_sheet_id := -1;
		END;
	END IF;

	IF v_parent_delegation_sid IS NULL OR v_parent_sheet_id != -1 THEN
		IF r_del.delegation_date_schedule_id IS NULL THEN	-- delegation chain uses a recurring date schedule (based on schedule_xml)
			SELECT
				CASE
					WHEN dp.schedule_xml IS NOT NULL AND XMLTYPE(dp.schedule_xml).extract('/').getStringVal() = XMLTYPE(d.schedule_xml).extract('/').getStringVal() THEN sp.submission_dtm
					ELSE LEAST(in_submission_dtm, NVL(sp.submission_dtm, in_submission_dtm))
				END,
				CASE
					WHEN dp.schedule_xml IS NOT NULL AND XMLTYPE(dp.schedule_xml).extract('/').getStringVal() = XMLTYPE(d.schedule_xml).extract('/').getStringVal() THEN sp.reminder_dtm
					ELSE LEAST(in_submission_dtm, NVL(sp.submission_dtm, in_submission_dtm)) - r_del.reminder_offset
				END
			  INTO v_submission_dtm, v_reminder_dtm
			  FROM delegation d
			  LEFT JOIN delegation dp ON dp.delegation_sid = d.parent_sid
			  LEFT JOIN sheet sp ON dp.delegation_sid = sp.delegation_sid AND sp.start_dtm = in_start_dtm AND sp.end_dtm = v_end_dtm
			 WHERE d.delegation_sid = in_delegation_sid;
		ELSE												-- delegation chain uses a fixed date schedule
			BEGIN
				SELECT reminder_dtm
				  INTO v_reminder_dtm
				  FROM sheet_date_schedule
				 WHERE delegation_date_schedule_id = r_del.delegation_date_schedule_id
				   AND start_dtm = in_start_dtm;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- this may happen if delegation was extended
					v_reminder_dtm := in_submission_dtm - r_del.reminder_offset;
			END;

			SELECT
				CASE
					WHEN in_submission_dtm > NVL(sp.submission_dtm, in_submission_dtm) THEN sp.submission_dtm
					ELSE in_submission_dtm
				END,
				CASE
					WHEN in_submission_dtm > NVL(sp.submission_dtm, in_submission_dtm) THEN sp.submission_dtm + (v_reminder_dtm - in_submission_dtm)
					ELSE v_reminder_dtm
				END
			  INTO v_submission_dtm, v_reminder_dtm
			  FROM delegation d
			  LEFT JOIN delegation dp ON dp.delegation_sid = d.parent_sid
			  LEFT JOIN sheet sp ON dp.delegation_sid = sp.delegation_sid AND sp.start_dtm = in_start_dtm AND sp.end_dtm = v_end_dtm
			 WHERE d.delegation_sid = in_delegation_sid;
		END IF;

		-- TODO: alter reminder_dtm to take into account working days??
		INSERT INTO sheet
			(sheet_id, delegation_sid, start_dtm, end_dtm, submission_dtm, reminder_dtm)
		VALUES
			(sheet_id_seq.NEXTVAL, in_delegation_sid, in_start_dtm, v_end_dtm, v_submission_dtm, v_reminder_dtm)
		RETURNING sheet_id INTO out_sheet_id;

		-- place the message against coming from the creator of the delegation
		CreateHistory(out_sheet_id, csr_data_pkg.ACTION_WAITING, r_del.created_by_sid, in_delegation_sid, 'Created', 1);

		SELECT propagate_deleg_values_down, status_from_parent_on_subdeleg
		  INTO v_propagate_down, v_status_according_parent
		  FROM customer;

		IF (v_parent_delegation_sid IS NOT NULL AND v_parent_sheet_id != -1)
		AND (v_propagate_down = 1 OR v_status_according_parent = 1) THEN
			sheet_pkg.CopyValuesFromParentSheet(in_act_id, out_sheet_id);
			IF v_status_according_parent = 1 THEN
				sheet_pkg.SetSheetStatusAccordingParent(out_sheet_id, r_del.created_by_sid, in_delegation_sid, v_parent_sheet_id);
			END IF;
		END IF;
	END IF;

    -- add calc jobs for the new sheets
	IF csr_data_pkg.HasUnmergedScenario THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_SHEET_CALC);

		MERGE /*+ALL_ROWS*/ INTO sheet_val_change_log svcl
		USING (SELECT di.ind_sid
		  		 FROM delegation_ind di
		  		WHERE di.delegation_sid = in_delegation_sid) d
		   ON (svcl.ind_sid = d.ind_sid)
		 WHEN MATCHED THEN
			UPDATE
			   SET svcl.start_dtm = LEAST(svcl.start_dtm, in_start_dtm),
				   svcl.end_dtm = GREATEST(svcl.end_dtm, v_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (svcl.ind_sid, svcl.start_dtm, svcl.end_dtm)
			VALUES (d.ind_sid, in_start_dtm, v_end_dtm);
	END IF;

	out_end_dtm := v_end_dtm;
END;

FUNCTION IsSplitDelegation(
	in_sheet_id				IN	sheet.sheet_id%TYPE
) RETURN NUMBER
AS
	v_parent_sheet_id		sheet.sheet_id%TYPE;
	v_non_common_reg_count	NUMBER;
	v_parent_deleg_sid		delegation.delegation_sid%TYPE;
	v_child_deleg_sid		delegation.delegation_sid%TYPE;
BEGIN
	BEGIN
		v_parent_sheet_id := GetParentSheetIdSameDate(in_sheet_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 1;
	END;

	SELECT delegation_sid
	  INTO v_parent_deleg_sid
	  FROM sheet
	 WHERE sheet_id = v_parent_sheet_id;

	SELECT delegation_sid
	  INTO v_child_deleg_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- look for different regions between parent and child
	SELECT COUNT(*)
	  INTO v_non_common_reg_count
	  FROM
		(SELECT region_sid
		   FROM csr.delegation_region 
		  WHERE delegation_sid = v_parent_deleg_sid) reg_parent
	  FULL JOIN 
		(SELECT region_sid
		   FROM csr.delegation_region 
		  WHERE delegation_sid = v_child_deleg_sid) reg_child
	   ON reg_parent.region_sid = reg_child.region_sid
	WHERE reg_parent.region_sid IS NULL 
	   OR reg_child.region_sid IS NULL;

	IF v_non_common_reg_count > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE SetSheetStatusAccordingParent(
	in_sheet_id					IN	sheet_value.sheet_value_id%TYPE,
	in_created_by_sid			IN	security_pkg.T_SID_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	in_parent_sheet_id			IN	security_pkg.T_SID_ID
) AS
	v_parent_status				NUMBER(10);
	v_child_status				NUMBER(10);
BEGIN

	IF IsSplitDelegation(in_sheet_id) > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Split delegations are not compatible with status_from_parent_on_subdeleg.');
	END IF;

	SELECT last_action_id
	  INTO v_parent_status
	  FROM csr.sheet_with_last_action
	 WHERE sheet_id = in_parent_sheet_id;

	/*
	Sheet statuses according csr_data_pkg, also present in table csr.sheet_action

			PARENT					CHILD
			--------------------------------
			WAITING					WAITING
			WAITING_WITH_MOD		WAITING_WITH_MOD
			SUBMITTED				ACCEPTED
			SUBMITTED_WITH_MOD		ACCEPTED
			ACCEPTED				ACCEPTED
			ACCEPTED_WITH_MOD		ACCEPTED_WITH_MOD
			MERGED					ACCEPTED
			MERGED_WITH_MOD			ACCEPTED
			RETURNED				RETURNED
	*/
	CASE v_parent_status
		WHEN csr_data_pkg.ACTION_MERGED THEN v_child_status := csr_data_pkg.ACTION_ACCEPTED;
		WHEN csr_data_pkg.ACTION_MERGED_WITH_MOD THEN v_child_status := csr_data_pkg.ACTION_ACCEPTED;
		WHEN csr_data_pkg.ACTION_SUBMITTED THEN v_child_status := csr_data_pkg.ACTION_ACCEPTED;
		WHEN csr_data_pkg.ACTION_SUBMITTED_WITH_MOD THEN v_child_status := csr_data_pkg.ACTION_ACCEPTED;
		ELSE v_child_status := v_parent_status;
	END CASE;

	CreateHistory(in_sheet_id, v_child_status, in_created_by_sid, in_delegation_sid, 'Set status according to parent sheet.', 1);
END;

-- return summary info about sheets that exist for a delegation
PROCEDURE AmendDates(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	csr_data_pkg.T_SHEET_ID,
	in_submission_dtm		IN	sheet.submission_dtm%TYPE,
	in_reminder_dtm			IN	sheet.reminder_dtm%TYPE,
	in_propagate_down		IN	NUMBER	DEFAULT 1
)
AS
	v_sheet		            T_SHEET_INFO;
	v_sheet_submission_dtm	DATE;
	v_sheet_reminder_dtm	DATE;
	v_new_submission_dtm	DATE;
	v_new_reminder_dtm		DATE;
	v_old_submission_dtm	DATE;
	v_old_reminder_dtm		DATE;
	v_delegation_sid 		security_pkg.T_ACT_ID;
	v_app_sid 			    security_pkg.T_ACT_ID;
BEGIN
	-- you can only change this stuff if you are the delegator
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);

	SELECT submission_dtm
	  INTO v_sheet_submission_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	SELECT reminder_dtm 
	  INTO v_sheet_reminder_dtm
	  FROM sheet 
	 WHERE sheet_id = in_sheet_id;
	 
	 --If the dates haven't changed, don't bother altering it.
	IF v_sheet_submission_dtm = in_submission_dtm AND v_sheet_reminder_dtm = in_reminder_dtm THEN
		RETURN;
	END IF;
	 
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_sheet.delegation_sid, delegation_pkg.DELEG_PERMISSION_ALTER) THEN
	--IF v_sheet.user_level != csr_data_pkg.USER_LEVEL_DELEGATOR THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering sheet');
	END IF;

	IF v_sheet.is_read_only = 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || in_sheet_id || ' is read only');
	END IF;

	IF in_propagate_down = 1 THEN
		-- sheets from child delegations which end at the same point
		-- (i.e. would last month of any monthlies if we're quarterly, or any matching quarters)
		FOR r_s IN (
			SELECT sheet_id, submission_dtm, reminder_dtm, last_action_id
			  FROM sheet_with_last_action s
			 WHERE s.end_dtm = v_sheet.end_dtm
			   AND s.delegation_sid IN (
				 SELECT delegation_sid
				   FROM delegation
				 CONNECT BY PRIOR delegation_sid = parent_sid
				   START WITH parent_sid = v_sheet.delegation_sid
			)
		)
		LOOP
			-- <audit> 
			-- get the delegation for this child sheet and record change against it.
			SELECT d.delegation_sid, d.app_sid 
			  INTO v_delegation_sid, v_app_sid
			  FROM sheet s, delegation d 
			 WHERE s.delegation_sid = d.delegation_sid 
			   AND d.app_sid = s.app_sid
			   AND sheet_id = r_s.sheet_id;
			
			-- new child submission = new submission - gap between parent submission adn child submission dtm)
			v_new_submission_dtm := in_submission_dtm - (v_sheet_submission_dtm - r_s.submission_dtm);
			-- new child reminder - keep same gap as previously
			v_new_reminder_dtm := v_new_submission_dtm - (r_s.submission_dtm - r_s.reminder_dtm);

			/* Removing this code. We don't care if the date is in the past.
			IF v_new_submission_dtm < SYSDATE AND r_s.last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED) THEN
				v_new_submission_dtm := TRUNC(SYSDATE);
			END IF;
			IF v_new_reminder_dtm < SYSDATE AND r_s.last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED) THEN
				v_new_reminder_dtm := TRUNC(SYSDATE);
			END IF;
			*/
			
			-- <audit> 
			-- record change for child sheet
			IF v_delegation_sid != v_sheet.delegation_sid THEN
				csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
					v_delegation_sid, 'Reminder date for child sheet "' || r_s.sheet_id || '"', TRUNC(r_s.reminder_dtm, 'dd'), TRUNC(v_new_reminder_dtm, 'dd'));
				csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid, 
					v_delegation_sid, 'Submission date for child sheet "' || r_s.sheet_id || '"', TRUNC(r_s.submission_dtm, 'dd'), TRUNC(v_new_submission_dtm, 'dd'));
			END IF;				
			
			-- adjust dates
			UPDATE sheet
			   SET reminder_dtm = v_new_reminder_dtm,
					submission_dtm = v_new_submission_dtm
			 WHERE sheet_id = r_s.sheet_id;
			-- TODO: log a message to warn users!
		END LOOP;
	END IF;

	-- <audit>
	-- get the delegation for this sheet and record change against it.
	SELECT d.delegation_sid, d.app_sid, s.submission_dtm, s.reminder_dtm
	  INTO v_delegation_sid, v_app_sid, v_old_submission_dtm, v_old_reminder_dtm
	  FROM sheet s, delegation d
	 WHERE s.delegation_sid = d.delegation_sid
	   AND s.app_sid = d.app_sid
	   AND s.sheet_id = in_sheet_id;

	-- <audit>
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid,
		v_delegation_sid, 'Reminder date for sheet "' || in_sheet_id || '"', TRUNC(v_old_reminder_dtm, 'dd'), TRUNC(in_reminder_dtm, 'dd'));
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, v_app_sid,
		v_delegation_sid, 'Submission date for sheet "' || in_sheet_id || '"', TRUNC(v_old_submission_dtm, 'dd'), TRUNC(in_submission_dtm, 'dd'));

	UPDATE sheet
	   SET submission_dtm = in_submission_dtm, reminder_dtm = in_reminder_dtm
	 WHERE sheet_id = in_sheet_id;

	-- TODO: warn users one level down that dates have changed for them
END;

PROCEDURE INTERNAL_DeleteSheetValue(
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE
) AS
	v_sheet_id				security_pkg.T_SID_ID;
BEGIN
	v_sheet_id := GetSheetIdForSheetValueId(in_sheet_value_id);
	--I was going to place this in DeleteSheet but other packages call this directly
	IF SheetIsReadOnly(v_sheet_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || v_sheet_id || 'is read only');
	END IF;
	
	DELETE FROM sheet_value_file_hidden_cache
	 WHERE sheet_value_id = in_sheet_value_id;
	
	DELETE FROM sheet_value_hidden_cache
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_value_accuracy
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_inherited_value
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_inherited_value
	 WHERE inherited_value_id = in_sheet_value_id;

	UPDATE sheet_value
	   SET last_sheet_value_change_id = NULL
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_value_change_file
	 WHERE sheet_value_change_id IN (
		SELECT sheet_value_change_id
		  FROM sheet_value_change
		 WHERE sheet_value_id = in_sheet_value_id
	);

	DELETE FROM sheet_value_change
	 WHERE sheet_value_id = in_sheet_value_id;

	-- must be done after cleaning up sheet_value_change
	DELETE FROM sheet_value_file
	 WHERE sheet_value_id = in_sheet_value_id; -- when we delete the delegation SO then the file object will get cleaned up

	DELETE FROM sheet_value_var_expl
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_value
	 WHERE sheet_value_id = in_sheet_value_id;
END;

-- only to be used internally - doesn't take an access token
PROCEDURE DeleteSheet(
	in_sheet_id		IN	csr_data_pkg.T_SHEET_ID
) AS
BEGIN
	FOR r_sv IN (
		SELECT SHEET_VALUE_ID FROM SHEET_VALUE WHERE SHEET_ID = in_sheet_id
	)
	LOOP
		INTERNAL_DeleteSheetValue(r_sv.sheet_value_id);
	END LOOP;
	
	FOR grid IN (
		SELECT DISTINCT dg.helper_pkg, d.delegation_sid, s.start_dtm, s.end_dtm, dg.name
		  FROM sheet s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		 WHERE s.sheet_id = in_sheet_id
		   AND dg.helper_pkg IS NOT NULL
	)
	LOOP
		DECLARE
			not_declared EXCEPTION;
			PRAGMA EXCEPTION_INIT(not_declared, -6550);
		BEGIN
			EXECUTE IMMEDIATE 'begin '||grid.helper_pkg||'.OnDelete(:1,:2,:3,:4,:5);end;' 
			  USING SYS_CONTEXT('SECURITY', 'ACT'), grid.delegation_sid, grid.start_dtm, grid.end_dtm, grid.name;
		EXCEPTION
			-- Defining this procedure is optional 
			WHEN not_declared THEN NULL;
		END;
	END LOOP;

	UPDATE sheet
	   SET last_sheet_history_id = null
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM sheet_history
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM sheet_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM new_delegation_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM new_planned_deleg_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM sheet_created_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM delegation_change_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM delegation_edited_alert
	 WHERE sheet_id = in_sheet_id;

	FOR r IN (
		SELECT sheet_change_req_id
		  FROM sheet_change_req
	     WHERE active_sheet_id = in_sheet_id
			OR req_to_change_sheet_id = in_sheet_id
	)
	LOOP
		DELETE FROM sheet_change_req_alert
		 WHERE sheet_change_req_id = r.sheet_change_req_id;

		DELETE FROM sheet_change_req
		 WHERE sheet_change_req_id = r.sheet_change_req_id;
	END LOOP;

	DELETE FROM deleg_data_change_alert
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM sheet_automatic_approval
	 WHERE sheet_id = in_sheet_id;

	DELETE FROM sheet_completeness_sheet
	 WHERE sheet_id = in_sheet_id;

 	DELETE FROM sheet_change_log
	 WHERE sheet_id = in_sheet_id;
	 
	DELETE FROM sheet
	 WHERE sheet_id = in_sheet_id;
END;

-- ========================================
-- Get sheet and other information about it
-- ========================================
PROCEDURE GetSheet(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	csr_data_pkg.T_SHEET_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	si						T_SHEET_INFO;
BEGIN
	si := GetSheetInfo(in_act_id, in_sheet_id);

	-- we have to specify column names since these are effectively variables
	OPEN out_cur FOR
		SELECT si.sheet_id sheet_id, si.delegation_sid delegation_sid, si.parent_delegation_sid parent_delegation_sid,
			   si.can_save can_save, si.can_submit can_submit, si.can_accept can_accept, si.can_return can_return,
			   si.can_delegate can_delegate, si.can_view can_view, si.can_override_delegator can_override_delegator,
			   si.can_copy_forward can_copy_forward, si.last_action_id last_action_id, si.name name,
			   si.start_dtm start_dtm, si.end_dtm end_dtm, si.period_set_id, si.period_interval_id,
			   si.note note, si.is_top_level is_top_level, si.group_by group_by, si.is_read_only is_read_only, si.can_explain can_explain,
			   DECODE(si.user_Level, csr_data_pkg.USER_LEVEL_DELEGATOR, 'delegator', csr_data_pkg.USER_LEVEL_DELEGEE, 'delegee', csr_data_pkg.USER_LEVEL_OTHER, 'other') user_level,
			   delegation_pkg.ConcatDelegationUsers(d.delegation_sid) users,
			   delegation_pkg.ConcatDelegationDelegators(d.delegation_sid) delegators,
			   delegation_pkg.getRootDelegationSid(d.delegation_sid) root_delegation_sid,
			   s.reminder_dtm,
			   s.last_action_dtm, TO_CHAR(s.last_action_dtm, 'Dy, dd Mon yyyy') last_action_dtm_fmt, -- deprecated -- format in the C# for i18n
			   s.submission_dtm, TO_CHAR(s.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt,-- deprecated -- format in the C# for i18n
			   d.section_xml,
			   csr_data_pkg.SQL_CheckCapability(in_act_id, 'Allow approvers to edit submitted sheets') can_make_editable,
			   csr_data_pkg.SQL_CheckCapability(in_act_id, 'Allow users to raise data change requests') can_raise_scr,
			   d.submit_confirmation_text delegation_policy,
			   d.lvl
		  FROM sheet_with_last_action s
		  JOIN v$delegation_hierarchical d ON s.delegation_sid = d.delegation_sid
		 WHERE s.sheet_id = in_sheet_id;
END;

-- returns extended info about a sheet
FUNCTION GetSheetInfo(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.T_SID_ID
) RETURN T_SHEET_INFO
AS
	v_user_sid			security_pkg.T_SID_ID;
	v_delegation_sid	security_pkg.T_SID_ID;
	CURSOR c(v_user_level sheet_action_permission.user_level%TYPE)	IS
		SELECT sap.can_save, sap.can_submit, sap.can_accept, sap.can_return, sap.can_delegate, sap.can_view,
			   swla.start_dtm, swla.end_dtm, swla.last_action_id, s.is_read_only, s.is_copied_forward
		  FROM sheet_with_last_action swla
		  JOIN sheet_action_permission sap ON swla.last_action_id = sap.sheet_action_id
		  JOIN sheet s ON s.sheet_id = swla.sheet_id
		 WHERE user_level = v_user_level
		   AND swla.sheet_id = in_sheet_id;
	r	c%ROWTYPE;
	CURSOR cD IS
		SELECT
			CASE
				WHEN dup.user_sid IS NOT NULL AND du.user_sid IS NOT NULL THEN csr_data_pkg.USER_LEVEL_BOTH
				WHEN dup.user_sid IS NOT NULL THEN csr_data_pkg.USER_LEVEL_DELEGATOR
				WHEN du.user_sid IS NOT NULL THEN csr_data_pkg.USER_LEVEL_DELEGEE
				ELSE csr_data_pkg.USER_LEVEL_OTHER
			END user_level,
			CASE
				WHEN d.parent_sid = d.app_sid THEN 1
				ELSE 0
			END is_top_level,
			   d.period_set_id, d.period_interval_id, d.parent_sid, d.delegation_sid, 
			   d.note, d.group_by, d.name, d.app_sid, cd.delegation_sid child_delegation_sid
		  FROM delegation d
		  LEFT JOIN v$delegation_user du ON d.delegation_sid = du.delegation_sid AND du.user_sid = v_user_sid
		  LEFT JOIN v$delegation_user dup ON d.parent_sid = dup.delegation_sid AND dup.user_sid = v_user_sid
		  LEFT JOIN delegation cd ON cd.parent_sid = d.delegation_sid
		 WHERE d.delegation_sid = v_delegation_sid;
	rD	cD%rowtype;
	v_user_level 					NUMBER(10);
	v_last_action_id 				NUMBER(10);
	v_can_save 						NUMBER(10);
	v_can_submit 					NUMBER(10);
	v_can_accept 					NUMBER(10);
	v_can_return 					NUMBER(10);
	v_can_delegate 					NUMBER(10);
	v_can_view						NUMBER(10);
	v_can_copy_forward				NUMBER(10);
	v_can_override_delegator		NUMBER(10);
	v_is_read_only					NUMBER(1);
	v_CAN_EXPLAIN					NUMBER(1);
	v_child_deleg_region_split		NUMBER(10);
	v_not_found						BOOLEAN;
BEGIN
	BEGIN
		-- figure out the delegation_sid for this sheet
		SELECT delegation_sid, last_action_id
		  INTO v_delegation_sid, v_last_action_id
		  FROM sheet_with_last_action
		 WHERE sheet_id = in_sheet_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The sheet with id '||in_sheet_id||' does not exist');
	END;

	-- check permissions on this delegation sid
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the sheet with id '||in_sheet_id);
	END IF;

	-- figure out who this user is
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- get some info about the delegation (user level and interval)
	OPEN cD;
	FETCH cD INTO rD;
	v_not_found := cD%NOTFOUND;
	CLOSE cD;
	IF v_not_found THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The sheet with id '||in_sheet_id||' does not exist');
	END IF;

	v_can_override_delegator := 0; -- by default nobody can do this

	v_user_level := rD.user_level;

	IF v_user_level = csr_data_pkg.USER_LEVEL_BOTH THEN
		-- if green, then delegee, otherwise delegator
		SELECT
			CASE
				WHEN LAST_ACTION_COLOUR = 'R' THEN csr_data_pkg.USER_LEVEL_DELEGEE
				ELSE csr_data_pkg.USER_LEVEL_DELEGATOR
			END
		  INTO v_user_level
		  FROM sheet_with_last_action
		 WHERE sheet_id = in_sheet_id;
	END IF;

	IF delegation_pkg.CheckDelegationPermission(in_act_id, rD.delegation_sid, delegation_pkg.DELEG_PERMISSION_OVERRIDE) THEN
		v_can_override_delegator := 1; -- override delegator users can provisional merge
		-- is it best to be delegator or delegee atm?
		IF rD.is_top_level =1 OR v_last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD) THEN
			v_user_level := csr_data_pkg.USER_LEVEL_DELEGEE;
		ELSE
	 		v_user_level := csr_data_pkg.USER_LEVEL_DELEGATOR;
		END IF;
	END IF;

	OPEN c(v_user_level);
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN NULL;
	END IF;

	v_can_save := r.can_save;
	v_can_submit := r.can_submit;
	v_can_accept := r.can_accept;
	v_can_return := r.can_return;
	v_can_explain := r.can_save;

	-- override CAN_DELEGATE if user have no such capability
	IF csr_data_pkg.CheckCapability(in_act_id, 'Subdelegation') THEN
		v_CAN_DELEGATE := r.CAN_DELEGATE;
	ELSE
		v_CAN_DELEGATE := 0;
	END IF;

	v_CAN_VIEW := r.CAN_VIEW;

	-- if other, then check on a per delegation basis for read permission
	IF v_user_level = csr_data_pkg.USER_LEVEL_OTHER THEN
		IF delegation_pkg.CheckDelegationPermission(in_act_id, rD.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
			v_CAN_VIEW := 1;
		END IF;
	END IF;

	--if the child delegation has split regions allow the delegator to explain variances in case previous period was not split
	IF v_CAN_EXPLAIN = 0
	AND v_last_action_id IN(csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD)
	AND rD.child_delegation_sid IS NOT NULL THEN
		delegation_pkg.GetRegionalSubdelegState(rD.child_delegation_sid, v_child_deleg_region_split);
		IF v_child_deleg_region_split = 2 THEN
			v_CAN_EXPLAIN := 1;
		END IF;
	END IF;

	v_is_read_only := r.is_read_only;

	IF v_is_read_only = 1 THEN
		v_CAN_SAVE := 0;
		v_CAN_SUBMIT := 0;
		v_CAN_ACCEPT := 0;
		v_CAN_RETURN := 0;
		v_CAN_EXPLAIN := 0;
	END IF;

	-- Hack for batch jobs: let builtin/administrator change sheet values for any sheet
	IF security_pkg.GetSID = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		v_CAN_SAVE := 1;
	END IF;

	IF csr_data_pkg.CheckCapability(in_act_id, 'Copy forward delegation') AND 
	   v_CAN_SAVE = 1 AND r.is_copied_forward = 0
	THEN
		V_CAN_COPY_FORWARD := 1;
	ELSE
		V_CAN_COPY_FORWARD := 0;
	END IF;

	RETURN T_SHEET_INFO(
		in_sheet_id, rD.delegation_sid, rD.parent_sid, rD.name, v_can_save, v_can_submit, 
		v_can_accept, v_can_return, v_can_delegate, v_can_view, v_can_override_delegator, 
		v_can_copy_forward, r.last_action_id, r.start_dtm, r.end_dtm, rD.period_set_id,
		rD.period_interval_id, rD.group_by, rD.note, v_user_level, rD.is_top_level,
		v_is_read_only, v_can_explain);
END;

PROCEDURE GetMessages(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sheet_history_id, sa.sheet_action_id, sa.description action_description,
			action_dtm, REPLACE(TO_CHAR(action_dtm,'yyyy-mm-dd hh24:mi:ss'),' ','T') action_dtm_fmt,
			NOTE, S.LAST_SHEET_HISTORY_ID, sh.is_system_note,
			full_name from_user_name,
			email from_user_email
		  FROM SHEET_HISTORY SH, SHEET S, CSR_USER CU, SHEET_ACTION SA
		 WHERE SH.sheet_id = in_sheet_id
		   AND S.sheet_id = in_sheet_id
		   AND CU.csr_user_sid = from_user_sid
		   AND SH.SHEET_ACTION_ID = SA.SHEET_ACTION_ID
		 ORDER BY action_dtm DESC;
END;

PROCEDURE GetSheetFileUploads(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sv.sheet_id, sv.sheet_value_id,
			fu.file_upload_sid, fu.filename, fu.mime_type, fu.parent_sid
		  FROM sheet_value sv, sheet_value_file svf, file_upload fu
		 WHERE sv.sheet_id = in_sheet_id
		   AND svf.sheet_value_id = sv.sheet_value_id
		   AND fu.file_upload_sid = svf.file_upload_sid;
END;

-- this is called by /delegation/sheet2/sheet.aspx
PROCEDURE GetValuesAndFilesAndIssues(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur_vals			OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR,
	out_cur_issues			OUT SYS_REFCURSOR,
	out_cur_var_expls		OUT SYS_REFCURSOR,
	out_cur_prev_values		OUT SYS_REFCURSOR
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_delegation_sid				security_pkg.T_SID_ID;
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
	v_sheet_start_dtm				sheet.start_dtm%TYPE;
	v_sheet_end_dtm					sheet.end_dtm%TYPE;
	v_sheet_prev_year_start_dtm		sheet.start_dtm%TYPE;
	v_sheet_prev_year_end_dtm		sheet.end_dtm%TYPE;
	v_prev_sheet_start_dtm			sheet.start_dtm%TYPE;
	v_prev_sheet_end_dtm			sheet.end_dtm%TYPE;
BEGIN
	-- check permission on delegation
	SELECT d.delegation_sid, s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
	  INTO v_delegation_sid, v_sheet_start_dtm, v_sheet_end_dtm, v_period_set_id, v_period_interval_id
	  FROM sheet s, delegation d
	 WHERE s.sheet_id = in_sheet_id AND s.delegation_sid = d.delegation_sid;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading sheet');
	END IF;

	v_sheet_prev_year_start_dtm := period_pkg.GetPeriodPreviousYear(v_period_set_id, v_sheet_start_dtm);
	v_sheet_prev_year_end_dtm := period_pkg.GetPeriodPreviousYear(v_period_set_id, v_sheet_end_dtm);
	v_prev_sheet_start_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_sheet_start_dtm, -1);
	v_prev_sheet_end_dtm := v_sheet_start_dtm;

	OPEN out_cur_vals FOR
		SELECT svc.sheet_value_id, svc.ind_sid, svc.region_sid, svc.status, svc.alert, svc.val_number,
			   svc.entry_measure_conversion_id, svc.entry_val_number, svc.flag, svc.note, svc.var_expl_note, NVL(i.format_mask, m.format_mask) format_mask,
			   svc.is_na, svc.last_sheet_value_change_id
		  FROM sheet_value_converted svc
		  JOIN ind i ON svc.ind_sid = i.ind_sid AND svc.app_sid = i.app_sid
		  LEFT JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
		 WHERE sheet_id = in_sheet_id;

	GetSheetFileUploads(in_act_id, in_sheet_id, out_cur_files);

	user_pkg.getSID(in_act_id, v_user_sid);

	OPEN out_cur_issues FOR
		SELECT ind_sid, region_sid, issue_id, is_resolved, is_closed, is_rejected, COUNT(is_read) entries, SUM(is_read) entries_read
		  FROM (
			SELECT isv.ind_sid, isv.region_sid, i.issue_id, il.issue_log_id,
				CASE WHEN resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
				CASE WHEN closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
				CASE WHEN rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected,
				CASE WHEN il.logged_by_user_sid = v_user_sid OR ilr.read_dtm IS NOT NULL THEN 1 ELSE 0 END is_read
			  FROM sheet s
			  JOIN delegation d ON s.delegation_sid = d.delegation_sid
			  JOIN delegation_ind di ON d.delegation_sid = di.delegation_sid
			  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
			  JOIN issue_sheet_value isv
			    ON di.ind_sid = isv.ind_sid
			   AND dr.region_sid = isv.region_sid
			   AND isv.start_dtm < s.end_dtm -- any issues within the period of the sheet
			   AND isv.end_dtm > s.start_dtm
			  JOIN issue i ON isv.issue_sheet_value_id = i.issue_sheet_value_id
			  JOIN issue_log il ON i.issue_id = il.issue_id
			  LEFT JOIN csr_user cu ON il.logged_by_user_sid = cu.csr_user_sid
			  LEFT JOIN issue_log_read ilr
			    ON il.issue_log_Id = ilr.issue_log_id
			   AND ilr.csr_user_sid = v_user_sid
			 WHERE s.sheet_id = in_sheet_id
			   AND i.deleted = 0 -- should this query join to v$issue instead?
		  )
		 GROUP BY ind_sid, region_sid, issue_id, is_resolved, is_closed, is_rejected;

	OPEN out_cur_var_expls FOR
		SELECT sv.sheet_value_id, var_expl_id
		  FROM sheet s
		  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
		  JOIN sheet_value_var_expl svve ON sv.sheet_value_id = svve.sheet_value_id
		 WHERE s.sheet_id = in_sheet_id;

	OPEN out_cur_prev_values FOR
		SELECT /*+ALL_ROWS*/ v.ind_sid, v.region_sid, v.val_number, v.period_start_dtm, v.period_end_dtm,
				v.entry_val_number, i.measure_sid, m.description measure_desc,
				v.entry_measure_conversion_id, mc.description entry_measure_conversion_desc, st.description source_type,
				v.note, i.tolerance_type/*
				CASE
					WHEN m.custom_field LIKE '|%' THEN v.note
					ELSE NULL
				END AS val_text*/
		  FROM sheet s, delegation_region dr, delegation_ind di, val_converted v,
			   measure_conversion mc, ind i, measure m, source_type st
		 WHERE di.app_sid = s.app_sid AND di.delegation_sid = s.delegation_sid
		   AND i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
		   AND dr.app_sid = s.app_sid AND dr.delegation_sid = s.delegation_sid
		   AND v.app_sid = di.app_sid AND v.ind_sid = di.ind_sid
		   AND v.app_sid = dr.app_sid AND v.region_sid = dr.region_sid
		   AND v.source_type_id = st.source_type_id
		   AND s.sheet_id = in_sheet_id
		   AND v.app_sid = mc.app_sid(+) AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		   AND v.period_end_dtm =
				CASE tolerance_type
					WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR THEN v_sheet_prev_year_end_dtm
					ELSE v_prev_sheet_end_dtm
				END
		   AND v.period_start_dtm =
				CASE tolerance_type
					WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR THEN v_sheet_prev_year_start_dtm
					ELSE v_prev_sheet_start_dtm
				END;
END;

PROCEDURE GetValues(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid	 		security_pkg.T_SID_ID;
	v_start_dtm			sheet.start_dtm%TYPE;
	v_end_dtm			sheet.end_dtm%TYPE;
	v_months			NUMBER;
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN

	SELECT start_dtm, end_dtm, delegation_sid
		INTO v_start_dtm, v_end_dtm, v_delegation_sid
		FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- now fiddle with start_dtm and end_dtm
	-- currently just does previous note
	v_months := MONTHS_BETWEEN(v_start_dtm, v_end_dtm);
	v_end_dtm := v_start_dtm;
	v_start_dtm := ADD_MONTHS(v_end_dtm, v_months);

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT sheet_value_id, sv.sheet_id, dd.ind_sid, dd.region_sid, sv.status,
			 sv.alert,
			 sv.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
			 sv.entry_measure_conversion_id, sv.entry_val_number, sv.flag,
			 sv.note, v.note previous_note,	 sheet_value_id source_id, var_expl_note, sv.is_na
		  FROM sheet_value_converted sv, val v,
			 (SELECT ind_sid, region_sid
			    FROM delegation_ind di, delegation_region dr
			   WHERE di.delegation_sid = v_delegation_sid
			     AND dr.delegation_sid = v_delegation_sid)dd
		 WHERE sv.sheet_id(+) = in_sheet_id
		   AND dd.ind_sid = sv.ind_sid(+)
		   AND dd.region_sid = sv.region_sid(+)
		   AND dd.ind_sid = v.ind_sid(+)
		   AND dd.region_sid = v.region_sid(+)
		   AND v.period_start_dtm(+) = v_start_dtm
		   AND v.period_end_dtm(+) = v_end_dtm
		 ORDER BY dd.ind_sid, dd.region_sid;
END;

PROCEDURE GetVarExpl(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT sv.sheet_value_id, ve.var_expl_id, ve.label
		  FROM sheet_value sv
		  JOIN sheet_value_var_expl svve ON sv.sheet_value_id = svve.sheet_value_id
		  JOIN var_expl ve ON svve.var_expl_id = ve.var_expl_id
		 WHERE sv.sheet_id = in_sheet_id AND NVL(ve.hidden, 0) = 0
		 ORDER BY sheet_value_id, pos;
END;

PROCEDURE GetValuesSingleFile(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_user_sid	 		security_pkg.T_SID_ID;
	v_start_dtm			sheet.start_dtm%TYPE;
	v_end_dtm			sheet.end_dtm%TYPE;
	v_months			NUMBER;
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT start_dtm, end_dtm, delegation_sid
	  INTO v_start_dtm, v_end_dtm, v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	 -- now fiddle with start_dtm and end_dtm
	 -- currently just does previous note
	v_months := MONTHS_BETWEEN(v_start_dtm, v_end_dtm);
	v_end_dtm := v_start_dtm;
	v_start_dtm := ADD_MONTHS(v_end_dtm, v_months);

	User_pkg.getSid(in_act_id, v_user_sid);

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ v.*,
			   fu.file_upload_sid, fu.filename file_upload_name, fu.mime_type file_upload_mime_type,
			   fuv.file_upload_sid previous_file_upload_sid, fuv.filename previous_file_upload_name, fuv.mime_type previous_file_upload_mime_type
		  FROM (SELECT dd.app_sid, sheet_value_id, sv.sheet_id, dd.ind_sid, dd.region_sid, sv.status, sv.alert,
				       sv.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
					   sv.entry_measure_conversion_id, sv.entry_val_number, sv.flag, sv.note,
					   v.note previous_note, sheet_value_id source_id, v.val_id
				  FROM sheet_value_converted sv,
					  (SELECT di.app_sid, di.ind_sid, dr.region_sid
						 FROM delegation_ind di, delegation_region dr
					    WHERE di.app_sid = dr.app_sid
					      AND di.delegation_sid = v_delegation_sid
						  AND dr.delegation_sid = v_delegation_sid) dd,
					   val v
				 WHERE sv.sheet_id(+) = in_sheet_id
				   AND dd.app_sid = sv.app_sid(+)
				   AND dd.ind_sid = sv.ind_sid(+)
				   AND dd.app_sid = sv.app_sid(+)
				   AND dd.region_sid = sv.region_sid(+)
				   AND dd.app_sid = v.app_sid(+)
				   AND dd.ind_sid = v.ind_sid(+)
				   AND dd.region_sid = v.region_sid(+)
				   AND v.period_start_dtm(+) = v_start_dtm
				   AND v.period_end_dtm(+) = v_end_dtm) v,
			   (SELECT r.app_sid, r.sheet_value_id, r.file_upload_sid, fu.filename, fu.mime_type
			      FROM file_upload fu, (
			  			SELECT svf.app_sid, svf.sheet_value_id, MAX(fu.file_upload_sid) file_upload_sid
						  FROM sheet_value_file svf, file_upload fu
						 WHERE svf.app_sid = fu.app_sid AND fu.file_upload_sid = svf.file_upload_sid
					  GROUP BY svf.app_sid, svf.sheet_value_id) r
				WHERE fu.app_sid = r.app_sid AND fu.file_upload_sid = r.file_upload_sid) fu,
			    (SELECT r.app_sid, r.val_id, r.file_upload_sid, fu.filename, fu.mime_type
				   FROM file_upload fu, (
			  			SELECT vf.app_sid, vf.val_id, MAX(fu.file_upload_sid) file_upload_sid
						  FROM val_file vf, file_upload fu
						 WHERE vf.app_sid = fu.app_sid AND fu.file_upload_sid = vf.file_upload_sid
					  GROUP BY vf.app_sid, vf.val_id) r
				  WHERE fu.app_sid = r.app_sid AND fu.file_upload_sid = r.file_upload_sid) fuv
		WHERE fu.app_sid(+) = v.app_sid
		  AND fu.sheet_value_id(+) = v.sheet_value_id
		  AND fuv.val_id(+) = v.val_id
	 ORDER BY v.ind_sid, v.region_sid;
END;

PROCEDURE GetValueNoteAndFiles(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_val				OUT SYS_REFCURSOR,
	out_cur_files			OUT SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	GetValueNote(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, out_cur_val);
	GetValueFileUploads(in_act_id, in_sheet_id, in_ind_sid, in_region_sid, out_cur_files);
END;

PROCEDURE GetValueNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_val				OUT SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur_val FOR
		SELECT sv.sheet_value_id, sv.note, sv.sheet_id, sv.ind_sid, sv.region_sid
			--,fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM sheet_value sv
		  	--, file_upload fu
		 WHERE sheet_id = in_sheet_id
		   AND ind_sid = in_ind_sid
		   AND region_sid = in_region_sid;
		   --AND fu.file_upload_sid(+) = sv.file_upload_sid;
END;

PROCEDURE SetVisibility(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	in_is_visible			IN	sheet.is_visible%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE sheet SET is_visible = in_is_visible WHERE sheet_id = in_sheet_id;
	
	IF in_is_visible = 1 THEN
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION,
			SYS_CONTEXT('SECURITY','APP'), v_delegation_sid, 'Set sheet '||in_sheet_id||' to visible');
	ELSE
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION,
			SYS_CONTEXT('SECURITY','APP'), v_delegation_sid, 'Set sheet '||in_sheet_id||' to hidden');
	END IF;
END;

PROCEDURE SetReadOnly(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	in_is_read_only			IN	sheet.is_read_only%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE sheet SET is_read_only = in_is_read_only WHERE sheet_id = in_sheet_id;

	IF in_is_read_only = 1 THEN
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION,
			SYS_CONTEXT('SECURITY','APP'), v_delegation_sid, 'Set sheet '||in_sheet_id||' to readonly');
	ELSE
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY','ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION,
			SYS_CONTEXT('SECURITY','APP'), v_delegation_sid, 'Set sheet '||in_sheet_id||' to editable');
	END IF;
END;

PROCEDURE GetValueFileUploads(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	sheet_value.sheet_id%TYPE,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur_files			OUT SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur_files FOR
		SELECT svf.sheet_value_id, svf.sheet_value_id source_id, -- Source id for compatability with value readers
			fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM sheet_value sv, sheet_value_file svf, file_upload fu
		 WHERE sv.sheet_id = in_sheet_id
		   AND sv.ind_sid = in_ind_sid
		   AND sv.region_sid = in_region_sid
		   AND svf.sheet_value_id = sv.sheet_value_id
		   AND fu.file_upload_sid = svf.file_upload_sid;
END;

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_file_upload_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_file_upload_sid 	OUT security_pkg.T_SID_ID
)
AS
BEGIN
	AddFileUpload(
		in_act_id,
		GetOrSetSheetValueId(in_sheet_id, in_ind_sid, in_region_sid),
		in_file_upload_sid,
		in_cache_key,
		out_file_upload_sid
	);
END;

-- private
PROCEDURE GetDelegationAndSheetForWrite(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id				IN	sheet_value.sheet_value_id%TYPE,
	out_delegation_sid				OUT	security_pkg.T_SID_ID,
	out_sheet_id					OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT s.delegation_sid, sv.sheet_id
	  INTO out_delegation_sid, out_sheet_id
	  FROM sheet s, sheet_value sv
	 WHERE sv.sheet_value_id = in_sheet_value_id
	   AND s.sheet_id = sv.sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, out_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF SheetIsReadOnly(out_sheet_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || out_sheet_id || ' is read only');
	END IF;
END;

-- private
PROCEDURE GetIndAndRegionSids(
	in_sheet_value_id				IN	security_pkg.T_SID_ID,
	out_ind_sid						OUT	security_pkg.T_SID_ID,
	out_region_sid					OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT ind_sid, region_sid
	  INTO out_ind_sid, out_region_sid
	  FROM sheet_value
	 WHERE sheet_value_id = in_sheet_value_id;
END;

-- private
FUNCTION GetFileName(
	in_file_upload_sid				IN	security_pkg.T_SID_ID
) RETURN file_upload.filename%TYPE
AS
	v_file_name				file_upload.filename%TYPE;
BEGIN
	SELECT filename
	  INTO v_file_name
	  FROM file_upload
	 WHERE file_upload_sid = in_file_upload_sid;

	RETURN v_file_name;
END;

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
)
AS
	v_delegation_sid		security_pkg.T_SID_ID;
	v_sheet_id				security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_file_name				file_upload.filename%TYPE;
BEGIN
	GetDelegationAndSheetForWrite(in_act_id, in_sheet_value_id, v_delegation_sid, v_sheet_id);

	INSERT INTO sheet_value_file (sheet_value_id, file_upload_sid)
	VALUES (in_sheet_value_id, in_file_upload_sid);

	user_pkg.GetSid(in_act_id, v_user_sid);

	GetIndAndRegionSids(in_sheet_value_id, v_ind_sid, v_region_sid);

	v_file_name := GetFileName(in_file_upload_sid);

	-- insert some file uplaod history
	INSERT INTO sheet_value_change (
		sheet_value_change_id, sheet_value_id, ind_sid,
		region_sid, reason,changed_by_sid, changed_dtm
		)
	 VALUES (
		sheet_value_change_id_seq.NEXTVAL, in_sheet_value_id, v_ind_sid,
		v_region_sid, 'File "' || v_file_name || '"added.', v_user_sid, SYSDATE
	);
END;

PROCEDURE AddFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_file_upload_sid 	OUT security_pkg.T_SID_ID
)
AS
	v_delegation_sid		security_pkg.T_SID_ID;
	v_sheet_id				security_pkg.T_SID_ID;
BEGIN
	GetDelegationAndSheetForWrite(in_act_id, in_sheet_value_id, v_delegation_sid, v_sheet_id);

	-- Replace case (will also create later)
	IF in_file_upload_sid > 0 AND in_cache_key IS NOT NULL THEN
		RemoveFileUpload(in_act_id, in_sheet_value_id, in_file_upload_sid);
	END IF;

	-- Default value for upload sid (-1) indicates nothing was added
	out_file_upload_sid := -1;

	-- Create case
	IF in_cache_key IS NOT NULL THEN
		-- Add the file upload
		CreateFileUploadFromCache(in_act_id, v_sheet_id, in_cache_key, out_file_upload_sid);

		-- Add ACE for parent object as these don't propagate down by default
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_file_upload_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
            security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_delegation_sid, security_pkg.PERMISSION_STANDARD_ALL);
		
		AddFileUpload(in_act_id, in_sheet_value_id, out_file_upload_sid);
	END IF;
END;

PROCEDURE RemoveFileUpload(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	RemoveFileUpload(
		in_act_id,
		GetOrSetSheetValueId(in_sheet_id, in_ind_sid, in_region_sid),
		in_file_upload_sid
	);
END;

PROCEDURE RemoveFileUpload (
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE,
	in_file_upload_sid		IN	security_pkg.T_SID_ID
)
AS
	v_delegation_sid		security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_file_name				file_upload.filename%TYPE;
	v_sheet_id				security_pkg.T_SID_ID;
BEGIN
	GetDelegationAndSheetForWrite(in_act_id, in_sheet_value_id, v_delegation_sid, v_sheet_id);

	DELETE FROM sheet_value_file
	 WHERE sheet_value_id = in_sheet_value_id
	   AND file_upload_sid = in_file_upload_sid;

	user_pkg.GetSid(in_act_id, v_user_sid);

	GetIndAndRegionSids(in_sheet_value_id, v_ind_sid, v_region_sid);

	v_file_name := GetFileName(in_file_upload_sid);

	-- insert some file uplaod history
	INSERT INTO sheet_value_change (
		sheet_value_change_id, sheet_value_id, ind_sid,
		region_sid, reason,changed_by_sid, changed_dtm
		)
	 VALUES (
	 	sheet_value_change_id_seq.NEXTVAL, in_sheet_value_id, v_ind_sid,
	 	v_region_sid, 'File "' || v_file_name || '"removed.', v_user_sid, SYSDATE
	);
END;

PROCEDURE RemoveAllFileUploads (
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_value_id		IN	sheet_value.sheet_value_id%TYPE
)
AS
	v_delegation_sid		security_pkg.T_SID_ID;
	v_ind_sid				security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_sheet_id				security_pkg.T_SID_ID;
BEGIN
	GetDelegationAndSheetForWrite(in_act_id, in_sheet_value_id, v_delegation_sid, v_sheet_id);

	-- Disabled for now as part of UD-329
	-- DELETE FROM sheet_value_file
	 -- WHERE sheet_value_id = in_sheet_value_id;
	FOR f IN (SELECT app_sid, sheet_value_id, file_upload_sid FROM sheet_value_file WHERE sheet_value_id = in_sheet_value_id)
	LOOP
		INSERT INTO csr.sheet_potential_orphan_files (app_sid, sheet_value_id, file_upload_sid, submission_dtm)
		VALUES (f.app_sid, f.sheet_value_id, f.file_upload_sid, SYSDATE);
	END LOOP;
	
	DELETE FROM sheet_value_file_hidden_cache
	 WHERE sheet_value_id = in_sheet_value_id;

	-- Disabled for now as part of UD-329
	-- user_pkg.GetSid(in_act_id, v_user_sid);

	-- GetIndAndRegionSids(in_sheet_value_id, v_ind_sid, v_region_sid);

	-- insert some file upload history
	-- INSERT INTO sheet_value_change (
		-- sheet_value_change_id, sheet_value_id, ind_sid,
		-- region_sid, reason,changed_by_sid, changed_dtm
		-- )
	 -- VALUES (
	 	-- sheet_value_change_id_seq.NEXTVAL, in_sheet_value_id, v_ind_sid,
	 	-- v_region_sid, 'Uploaded file(s) removed.', v_user_sid, SYSDATE
	-- );
END;

PROCEDURE GetPreviousValues(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_sheet_id						IN	SHEET.sheet_id%TYPE,
	out_cur							OUT SYS_REFCURSOR
)                           		
AS                          		
	v_delegation_sid	 			security_pkg.T_SID_ID;
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
	v_sheet_start_dtm				sheet.start_dtm%TYPE;
	v_sheet_end_dtm					sheet.end_dtm%TYPE;
	v_sheet_prev_year_start_dtm		sheet.start_dtm%TYPE;
	v_sheet_prev_year_end_dtm		sheet.end_dtm%TYPE;
	v_prev_sheet_start_dtm			sheet.start_dtm%TYPE;
	v_prev_sheet_end_dtm			sheet.end_dtm%TYPE;
BEGIN
	-- check permission on delegation
	SELECT d.delegation_sid, s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
	  INTO v_delegation_sid, v_sheet_start_dtm, v_sheet_end_dtm, v_period_set_id, v_period_interval_id
	  FROM sheet s, delegation d
	 WHERE s.sheet_id = in_sheet_id AND s.delegation_sid = d.delegation_sid;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading sheet');
	END IF;

	v_sheet_prev_year_start_dtm := period_pkg.GetPeriodPreviousYear(v_period_set_id, v_sheet_start_dtm);
	v_sheet_prev_year_end_dtm := period_pkg.GetPeriodPreviousYear(v_period_set_id, v_sheet_end_dtm);
	v_prev_sheet_start_dtm := period_pkg.AddIntervals(v_period_set_id, v_period_interval_id, v_sheet_start_dtm, -1);
	v_prev_sheet_end_dtm := v_sheet_start_dtm;

	OPEN out_cur FOR
		SELECT /*+all_rows*/ v.ind_sid, v.region_sid, v.val_number, v.period_start_dtm, v.period_end_dtm,
			   v.entry_val_number, i.measure_sid, m.description measure_desc,
			   v.entry_measure_conversion_id, mc.description entry_measure_conversion_desc, st.description source_type
		  FROM sheet s, delegation_region dr, delegation_ind di, val_converted v,
		  	   measure_conversion mc, ind i, measure m, source_type st
		 WHERE di.app_sid = s.app_sid AND di.delegation_sid = s.delegation_sid
		   AND i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid
		   AND dr.app_sid = s.app_sid AND dr.delegation_sid = s.delegation_sid
		   AND v.app_sid = di.app_sid AND v.ind_sid = di.ind_sid
		   AND v.app_sid = dr.app_sid AND v.region_sid = dr.region_sid
		   AND v.source_type_id = st.source_type_id
		   AND s.sheet_id = in_sheet_id
		   AND v.app_sid = mc.app_sid(+) AND v.entry_measure_conversion_id = mc.measure_conversion_id(+)
		   AND i.app_sid = m.app_sid(+) AND i.measure_sid = m.measure_sid(+)
		   AND v.period_end_dtm = 
				CASE tolerance_type
                	WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR THEN v_sheet_prev_year_end_dtm
                    ELSE v_prev_sheet_end_dtm
				END
		   AND v.period_start_dtm =
				CASE tolerance_type
					WHEN csr_data_pkg.TOLERANCE_TYPE_PREVIOUS_YEAR THEN v_sheet_prev_year_start_dtm
					ELSE v_prev_sheet_start_dtm
				END;
END;

-- things that will block submissions
PROCEDURE GetBlockers(
	in_sheet_id						IN 	sheet.sheet_id%TYPE,
    out_cur							OUT	SYS_REFCURSOR
)                       			
AS                      			
	v_delegation_sid				security_pkg.T_SID_ID;
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- This needs to be fetched instead of getting it via connect_by_root because
	-- otherwise you get a lovely ORA-00600
	-- I think that's fixed in 10.0.2.0.5 since it works on live, but people
	-- probably want to run it locally...
	SELECT period_set_id, period_interval_id
	  INTO v_period_set_id, v_period_interval_id
	  FROM delegation
	 WHERE delegation_sid = v_delegation_sid;

	OPEN out_cur FOR
	    -- missing mandatory values: all mandatory indicators minus those that have been completed
		SELECT ir.ind_sid, ir.region_sid, section_key, csr_data_pkg.SHT_BLOCKED_MISSING_VALUE reason
		  FROM (SELECT di.app_sid, di.ind_sid, region_sid
		          FROM delegation_ind di,
		               delegation_region dr,
		               delegation d,
		               ind
		         WHERE di.app_sid = dr.app_sid
		           AND di.app_sid = d.app_sid
		           AND di.app_sid = ind.app_sid
		           AND dr.app_sid = d.app_sid
		           AND dr.app_sid = ind.app_sid
		           AND d.app_sid = ind.app_sid
		           AND di.delegation_sid = v_delegation_sid
		           AND dr.delegation_sid = v_delegation_sid
		           AND d.delegation_sid = v_delegation_sid
		           AND (   (    di.mandatory = 1
		                    AND d.allocate_users_to = 'region')
		                OR (    dr.mandatory = 1
		                    AND d.allocate_users_to = 'indicator')
		               )
		           AND di.ind_sid = ind.ind_sid
		           AND ind.ind_type IN (csr_data_pkg.IND_TYPE_NORMAL)
                   AND ind.measure_sid IS NOT NULL
		        MINUS
	        	SELECT DISTINCT sv.app_sid, sv.ind_sid, sv.region_sid
             	  FROM sheet_value sv, ind i, measure m
                 WHERE sv.app_sid = i.app_sid
                   AND sv.app_sid = m.app_sid
                   AND i.app_sid = m.app_sid
                   AND sv.sheet_id = in_sheet_id
                   AND sv.ind_sid = i.ind_sid
                   AND i.measure_sid = m.measure_sid
                   AND (
                    (trim(m.custom_field) = '|' and sv.note is not null)
                    OR (m.custom_field is null AND val_number is not null)
                    OR (length(m.custom_field) > 1 AND val_number > 0) -- radio buttons get set to 0 which means 'nothing selected'
                  )
          ) ir,	delegation_ind di
		 WHERE ir.app_sid = di.app_sid
		   AND ir.ind_sid = di.ind_sid
		   AND di.delegation_sid = v_delegation_sid
		 UNION
		-- if a number has been filled in, then it must have a note
		SELECT sv.ind_sid, sv.region_sid, di.section_key, csr_data_pkg.SHT_BLOCKED_MISSING_NOTE reason
		  FROM sheet_value sv,
		       delegation_ind di,
		       delegation_region dr,
		       delegation d,
		       ind,
		       (SELECT di.app_sid, di.ind_sid, MAX(cd.is_granularity_different) is_granularity_different
				  FROM delegation_ind di,
				  		(SELECT delegation_sid, 
				  			    CASE WHEN period_set_id = v_period_set_id AND period_interval_id = v_period_interval_id THEN 1 ELSE 0 END is_granularity_different
				  		   FROM delegation
	   							START WITH parent_sid = v_delegation_sid
	   							CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) cd
				 WHERE cd.delegation_sid = di.delegation_sid
			     GROUP BY app_sid, ind_sid) cdi,
			   (SELECT app_sid, region_sid, MAX(cd.is_granularity_different) is_granularity_different
  				  FROM delegation_region dr,
  				  		(SELECT delegation_sid,
  				  			    CASE WHEN period_set_id = v_period_set_id AND period_interval_id = v_period_interval_id THEN 1 ELSE 0 END is_granularity_different
  				  		   FROM delegation
	   							START WITH parent_sid = v_delegation_sid
	   							CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) cd
				 WHERE cd.delegation_sid = dr.delegation_sid
				 GROUP BY app_sid, region_sid) cdr
		 WHERE sv.app_sid = di.app_sid
		   AND sv.app_sid = dr.app_sid
		   AND sv.app_sid = d.app_sid
		   AND sv.app_sid = ind.app_Sid
		   AND di.app_sid = dr.app_sid
		   AND di.app_sid = d.app_sid
		   AND di.app_sid = ind.app_sid
		   AND dr.app_sid = d.app_sid
		   AND dr.app_sid = ind.app_sid
		   AND d.app_sid = ind.app_sid
		   AND sv.sheet_id = in_sheet_id
		   AND sv.val_number IS NOT NULL
		   AND sv.note IS NULL
		   --AND sv.file_upload_sid IS NULL
		   AND d.delegation_sid = v_delegation_sid
		   AND d.is_note_mandatory = 1
		   AND di.ind_sid = sv.ind_sid -- tie back to ind + region in case of stray values (e.g regional subdeleg / removed region or something)
		   AND di.ind_sid = ind.ind_sid
		   AND sv.ind_sid = ind.ind_sid
		   AND ind.ind_type NOT IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_AGGREGATE)
           AND di.delegation_sid = v_delegation_sid
		   AND dr.region_sid = sv.region_sid
           AND dr.delegation_sid = v_delegation_sid
		   AND di.app_sid = cdi.app_sid(+) AND di.ind_sid = cdi.ind_sid(+)
		   AND dr.app_sid = cdr.app_sid(+) AND dr.region_sid = cdr.region_sid(+)
           AND NOT (NVL(cdi.is_granularity_different, 0) = 1 AND NVL(cdr.is_granularity_different, 0) = 1)
		 UNION
		  -- alerts where there is no quality status flag selected
		  -- distinct to flatten out join to ind_flag
		 SELECT DISTINCT sv.ind_sid, sv.region_sid, di.section_key, csr_data_pkg.SHT_BLOCKED_MISSING_QUAL reason
		  FROM sheet_value sv,
		       delegation_ind di,
		       delegation_region dr,
		       delegation d,
		       ind,
               ind_flag inf,
		       (SELECT di.app_sid, di.ind_sid, MAX(cd.is_granularity_different) is_granularity_different
				  FROM delegation_ind di,
				  		(SELECT delegation_sid,
				  				CASE WHEN period_set_id = v_period_set_id AND period_interval_id = v_period_interval_id THEN 1 ELSE 0 END is_granularity_different
				  		   FROM delegation
	   							START WITH parent_sid = v_delegation_sid
	   							CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) cd
				 WHERE cd.delegation_sid = di.delegation_sid
			     GROUP BY app_sid, ind_sid) cdi,
			   (SELECT app_sid, region_sid, MAX(cd.is_granularity_different) is_granularity_different
  				  FROM delegation_region dr,
  				  		(SELECT delegation_sid,
  				  				CASE WHEN period_set_id = v_period_set_id AND period_interval_id = v_period_interval_id THEN 1 ELSE 0 END is_granularity_different
  				  		   FROM delegation
	   							START WITH parent_sid = v_delegation_sid
	   							CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) cd
				 WHERE cd.delegation_sid = dr.delegation_sid
				 GROUP BY app_sid, region_sid) cdr
		 WHERE sv.app_sid = di.app_sid
		   AND sv.app_sid = dr.app_sid
		   AND sv.app_sid = d.app_sid
		   AND sv.app_sid = ind.app_Sid
		   AND di.app_sid = dr.app_sid
		   AND di.app_sid = d.app_sid
		   AND di.app_sid = ind.app_sid
		   AND ind.app_sid = inf.app_sid
		   AND dr.app_sid = d.app_sid
		   AND dr.app_sid = ind.app_sid
		   AND d.app_sid = ind.app_sid
		   AND sv.sheet_id = in_Sheet_id
		   AND sv.val_number IS NOT NULL
		   AND sv.flag IS NULL
		   --AND sv.file_upload_sid IS NULL
		   AND d.delegation_sid = v_delegation_sid
		   AND d.is_flag_mandatory = 1
		   AND di.ind_sid = sv.ind_sid -- tie back to ind + region in case of stray values (e.g regional subdeleg / removed region or something)
		   AND di.ind_sid = ind.ind_sid
           AND ind.ind_sid = inf.ind_sid
           AND sv.ind_sid = ind.ind_sid
           AND ind.ind_type NOT IN (csr_data_pkg.IND_TYPE_CALC, csr_data_pkg.IND_TYPE_STORED_CALC, csr_data_pkg.IND_TYPE_AGGREGATE)
           AND di.delegation_sid = v_delegation_sid
		   AND dr.region_sid = sv.region_sid
           AND dr.delegation_sid = v_delegation_sid
		   AND di.app_sid = cdi.app_sid(+) AND di.ind_sid = cdi.ind_sid(+)
		   AND dr.app_sid = cdr.app_sid(+) AND dr.region_sid = cdr.region_sid(+)
           AND NOT (NVL(cdi.is_granularity_different, 0) = 1 AND NVL(cdr.is_granularity_different, 0) = 1)
		UNION
		  -- alerts where there is a quality status flag selected but a note is needed
		 SELECT sv.ind_sid, sv.region_sid, di.section_key, csr_data_pkg.SHT_BLOCKED_MISS_QUAL_NOTE reason
		  FROM sheet_value sv,
		       delegation_ind di,
		       delegation_region dr,
		       delegation d,
		       ind,
               ind_flag inf
		 WHERE sv.app_sid = di.app_sid
		   AND sv.app_sid = dr.app_sid
		   AND sv.app_sid = d.app_sid
		   AND sv.app_sid = ind.app_Sid
		   AND di.app_sid = dr.app_sid
		   AND di.app_sid = d.app_sid
		   AND di.app_sid = ind.app_sid
		   AND ind.app_sid = inf.app_sid
		   AND dr.app_sid = d.app_sid
		   AND dr.app_sid = ind.app_sid
		   AND d.app_sid = ind.app_sid
		   AND sv.sheet_id = in_Sheet_id
		   AND sv.flag = inf.flag
		   AND sv.note IS NULL
		   AND inf.requires_note = 1
		   --AND sv.file_upload_sid IS NULL
		   AND d.delegation_sid = v_delegation_sid
		   AND di.ind_sid = sv.ind_sid -- tie back to ind + region in case of stray values (e.g regional subdeleg / removed region or something)
		   AND di.ind_sid = ind.ind_sid
           AND ind.ind_sid = inf.ind_sid
           AND sv.ind_sid = ind.ind_sid
           AND di.delegation_sid = v_delegation_sid
		   AND dr.region_sid = sv.region_sid
           AND dr.delegation_sid = v_delegation_sid
		UNION
		-- alerts where there is no explanatory note
		-- TODO: this should also check the val table - or probably we'll can it and do it in the C# stuff
		-- and compare properly.
		SELECT sv.ind_sid, sv.region_sid, di.section_key, csr_data_pkg.SHT_BLOCKED_TOLERANCE reason
		  FROM sheet_value sv,
		       delegation_ind di, delegation_region dr, ind i
		 WHERE sv.app_sid = di.app_sid
		   AND sv.app_sid = dr.app_sid
		   AND sv.app_sid = i.app_sid
		   AND di.app_sid = dr.app_sid
		   AND di.app_sid = i.app_sid
		   AND dr.app_sid = i.app_sid
		   AND sv.alert IS NOT NULL
		   AND sv.note IS NULL
		   AND sv.sheet_id = in_sheet_id
		   AND di.ind_sid = sv.ind_sid
		   AND dr.delegation_sid = v_delegation_sid
		   and sv.region_sid = dr.region_sid
		   AND di.delegation_sid = v_delegation_sid
		   AND di.ind_sid = i.ind_sid
		   AND i.ind_type in (csr_data_pkg.IND_TYPE_NORMAL) --, csr_data_pkg.IND_TYPE_STORED_CALC
         ORDER BY section_key;
END;

PROCEDURE GetDelegationFromSheetId(
	in_sheet_id		IN  sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security check since this gives less information than provided
	OPEN out_cur FOR
		SELECT s.delegation_sid, d.editing_url -- RK: added editing_url for topDeleg.xml
		  FROM sheet s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		 WHERE sheet_id = in_sheet_id;
END;

FUNCTION GetParentSheetId(
	in_sheet_id		csr_data_pkg.T_SHEET_ID
) RETURN csr_data_pkg.T_SHEET_ID
AS
	v_parent_sheet_id	csr_data_pkg.T_SHEET_ID;
BEGIN
	SELECT sp.sheet_id
	  INTO v_parent_sheet_id
	  FROM sheet s, delegation d, sheet sp
	 WHERE s.sheet_id = in_sheet_id
	   AND s.delegation_sid = d.delegation_sid
	   AND sp.delegation_sid = d.parent_sid
	   AND sp.start_dtm <= s.start_dtm
	   AND sp.end_dtm >= s.end_dtm;
	RETURN v_parent_sheet_id;
END;

FUNCTION GetSheetId(
	in_delegation_sid	security_pkg.T_SID_ID,
	in_start_dtm		sheet.start_dtm%TYPE,
	in_end_dtm			sheet.end_dtm%TYPE
) RETURN csr_data_pkg.T_SHEET_ID
AS
	v_parent_sheet_id	csr_data_pkg.T_SHEET_ID;
BEGIN
	SELECT sheet_id
	  INTO v_parent_sheet_id
	  FROM sheet
	 WHERE delegation_sid = in_delegation_sid
	   AND start_dtm <= in_start_dtm
	   AND end_dtm >= in_end_dtm;
	RETURN v_parent_sheet_id;
END;

FUNCTION GetParentSheetIdSameDate(
	in_sheet_id		csr_data_pkg.T_SHEET_ID
) RETURN csr_data_pkg.T_SHEET_ID
AS
	v_parent_sheet_id			csr_data_pkg.T_SHEET_ID;
	v_sub_del_id				csr_data_pkg.T_SHEET_ID;
	v_parent_del_interval_id	delegation.period_interval_id%TYPE;
	v_sub_del_interval_id		delegation.period_interval_id%TYPE;
	v_sheet_count				NUMBER(5);
	v_status_count				NUMBER(5);
	v_parent_startdate			DATE;
	v_parent_enddate			DATE;
BEGIN
	SELECT d.delegation_sid,d.period_interval_id, dp.period_interval_id,sp.start_dtm,sp.end_dtm ,sp.sheet_id
	  INTO v_sub_del_id,v_sub_del_interval_id,v_parent_del_interval_id,v_parent_startdate,v_parent_enddate,v_parent_sheet_id
	  FROM delegation d
	  JOIN sheet s ON d.delegation_sid = s.delegation_sid
	  JOIN delegation dp ON dp.delegation_sid = d.parent_sid
	  JOIN sheet sp ON sp.DELEGATION_SID = d.PARENT_SID
	 WHERE s.sheet_id= in_sheet_id
	   AND sp.start_dtm <= s.start_dtm
	   AND sp.end_dtm >= s.end_dtm;

	IF v_sub_del_interval_id <> v_parent_del_interval_id THEN
		SELECT COUNT(*)
		  INTO v_sheet_count
		  FROM sheet
		 WHERE delegation_sid = v_sub_del_id
		   AND start_dtm >= v_parent_startdate
		   AND end_dtm <= v_parent_enddate;

		SELECT COUNT(*)
		  INTO v_status_count
		  FROM sheet_with_last_action sa
		  JOIN sheet s ON sa.sheet_id = s.sheet_id
		 WHERE s.delegation_sid = v_sub_del_id
		   AND s.start_dtm >= v_parent_startdate
		   AND s.end_dtm <= v_parent_enddate
		   AND sa.status = csr_data_pkg.SHEET_VALUE_MERGED
		   AND sa.last_action_id = csr_data_pkg.ACTION_ACCEPTED;

		IF(v_status_count <> v_sheet_count)THEN
			v_parent_sheet_id := null;
		END IF;
	ELSE
		SELECT sp.sheet_id
		  INTO v_parent_sheet_id
		  FROM sheet s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		  JOIN sheet sp ON d.parent_sid = sp.delegation_sid
		 WHERE s.sheet_id = in_sheet_id
		   AND sp.start_dtm = s.start_dtm
		   AND sp.end_dtm = s.end_dtm;
	END IF;
	RETURN v_parent_sheet_id;
END;

-- ===================
-- Change sheet status
-- ===================
/*
3 - accept data				Authorise
9 - approve and merge 		Merge
4 - request amend			Request Amend
2 - return to delegees		Return To Delegees
1 - submit					Submitted
 - CAN_ACCEPT
*/
-- a delegee has entered some data which we are going to accept
PROCEDURE Accept(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_skip_check			IN	NUMBER DEFAULT 0 -- new 'sheet2' delegations do checks themselves because of conditionals...
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_sheet							T_SHEET_INFO;
	v_user_sid						security_pkg.T_SID_ID;
	v_fully_delegated				delegation.fully_delegated%TYPE;
	v_is_top_level					NUMBER(10);
	v_parent_sheet_id				sheet.sheet_id%TYPE;
	v_split_left					NUMBER(10);
	v_delegation_sid				security_pkg.T_SID_ID;
	v_raise_split_deleg_alerts		customer.raise_split_deleg_alerts%TYPE;
	v_is_data_locked				BOOLEAN;
	v_can_edit_whilst_data_locked	BOOLEAN;
	v_sheet_ids						security_pkg.T_SID_IDS;
BEGIN
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	v_is_data_locked := csr_data_pkg.IsPeriodLocked(v_app_sid, v_sheet.start_dtm, v_sheet.start_dtm) = 1;
	v_can_edit_whilst_data_locked := csr_data_pkg.CheckCapability(in_act_id, 'Can edit forms before system lock date');
	
	-- can the user really do this? (could be read only)
	IF v_sheet.CAN_ACCEPT=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot accept sheet '||in_sheet_id);
	END IF;

	-- reject any DCRs
	UPDATE sheet_change_req
	   SET processed_note = 'Rejected because data accepted', -- i18n grr
		   processed_by_sid = v_user_sid,
		   processed_dtm = SYSDATE,
		   is_approved = 0
	 WHERE processed_dtm IS NULL
	   AND active_sheet_id = in_sheet_id;

	-- mark values as accepted
	UPDATE sheet_value
	   SET status = csr_data_pkg.SHEET_VALUE_ACCEPTED
	 WHERE sheet_id = in_sheet_id;

	-- inherit values up
	PropagateValuesToParentSheet(in_act_id, in_sheet_id);

	-- write a row to the history table for this change - note goes from this user to delegees
	CreateHistory(in_sheet_id, csr_data_pkg.ACTION_ACCEPTED, v_user_sid, v_sheet.delegation_sid, in_note);
	IF v_is_data_locked AND NOT v_can_edit_whilst_data_locked THEN 
		CreateHistory(in_sheet_id, csr_data_pkg.ACTION_ACCEPTED, v_user_sid, v_sheet.delegation_sid, 'Automatic merge of this sheet was blocked because period is locked.', 1);
	END IF;

	-- if parent is fully delegated, or this is the
	-- then merge or submit the parent sheet
	BEGIN
		v_parent_sheet_id := GetParentSheetIdSameDate(in_sheet_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- give up - this shouldn't really happen
			v_parent_sheet_id := -1;
	END;

	IF v_parent_sheet_id != -1 THEN -- TODO: and fully_delegated TO A SINGLE SUB DELEGATION! (or the other bits are already approved)
		SELECT s.delegation_sid, fully_delegated,
			   CASE WHEN d.app_sid = parent_sid THEN 1 ELSE 0 END is_top_level
		  INTO v_delegation_sid, v_fully_delegated, v_is_top_level
		  FROM delegation d, sheet s
		 WHERE s.delegation_sid = d.delegation_sid
		   AND s.app_sid = d.app_sid
		   AND s.sheet_id = v_parent_sheet_id;

		IF v_fully_delegated = csr_data_pkg.FULLY_DELEGATED_TO_ONE THEN
			IF v_is_top_level = 1 THEN
				IF NOT v_is_data_locked OR v_can_edit_whilst_data_locked THEN
					-- merge it
					MergeLowest(in_act_id, v_parent_sheet_id, in_note, 0, in_skip_check);
				ELSE
					CreateHistory(v_parent_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_delegation_sid, in_note);
					CreateHistory(v_parent_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_delegation_sid,
						'Automatic merge of this sheet was blocked because period is locked.', 1);
				END IF;
			ELSE
				-- submit it
				Submit(in_act_id, v_parent_sheet_id, in_note, in_skip_check);
				-- raise an alert
				RaiseSheetChangeAlert(v_parent_sheet_id, csr_data_pkg.ALERT_TO_DELEGATOR);
			END IF;
		ELSIF v_fully_delegated = csr_data_pkg.FULLY_DELEGATED_TO_MANY THEN
			-- See if this is the last sheet that has been accepted
			SELECT count(*)
			   INTO v_split_left
			   FROM sheet sp, sheet_with_last_action s, delegation d, delegation dp
			  WHERE sp.sheet_id = in_sheet_id
			  	AND sp.delegation_sid = dp.delegation_sid
				AND dp.parent_sid = d.parent_sid
  				AND s.delegation_sid = d.delegation_sid
				AND s.start_dtm >= sp.start_dtm
				AND s.end_dtm <= sp.end_dtm
				AND s.last_action_id NOT IN (csr_data_pkg.ACTION_ACCEPTED, csr_data_pkg.ACTION_ACCEPTED_WITH_MOD)
				AND s.is_visible = 1;

			IF v_split_left = 0 THEN
				BEGIN
					IF v_is_top_level = 1 THEN						
						IF NOT v_is_data_locked OR v_can_edit_whilst_data_locked THEN
							-- merge it
							MergeLowest(in_act_id, v_parent_sheet_id, in_note, 0, in_skip_check);
						ELSE
							CreateHistory(v_parent_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_delegation_sid, in_note);
							CreateHistory(v_parent_sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, v_delegation_sid,
								'Automatic merge of this sheet was blocked because period is locked.', 1);
						END IF;
					ELSE
						-- submit it
						Submit(in_act_id, v_parent_sheet_id, in_note, in_skip_check);
						-- raise an alert if configured
						SELECT raise_split_deleg_alerts
						  INTO v_raise_split_deleg_alerts
						  FROM customer;
						  
						IF v_raise_split_deleg_alerts = 1 THEN
							RaiseSheetChangeAlert(v_parent_sheet_id, csr_data_pkg.ALERT_TO_DELEGATOR);
						END IF;
					END IF;
				EXCEPTION
					WHEN csr_data_pkg.VALUES_NOT_COMPLETED THEN
						SELECT delegation_sid
						  INTO v_delegation_sid
						  FROM sheet
						 WHERE sheet_id = v_parent_sheet_id;

						-- Mark the sheet as PARTIALLY SUBMITTED which is a status
						-- just used for this purpose.  The note should be translated really,
						-- but oh well, i'm sick of looking at this.
						CreateHistory(v_parent_sheet_id, csr_data_pkg.ACTION_PARTIALLY_SUBMITTED, v_user_sid, v_delegation_sid,
							'Automatic submission of this sheet was blocked because there are errors');

						-- Raise an alert for the sheet so that they know about it
						RaiseSheetChangeAlert(v_parent_sheet_id, csr_data_pkg.ALERT_TO_DELEGATOR);
				END;
			END IF;
		END IF;
		
		--Schedule calculation parent completeness
		v_sheet_ids(v_sheet_ids.COUNT) := v_parent_sheet_id;
		AddCompletenessJobs(v_sheet_ids);
		
		--Delete all alerts telling Approvers that sheets have been submitted 
		DELETE FROM delegation_change_alert
		 WHERE sheet_id IN (SELECT s2.sheet_id 
							  FROM delegation d 
							  JOIN sheet s ON d.delegation_sid = s.delegation_sid 
							  JOIN delegation d2 ON d2.parent_sid = d.delegation_sid 
							  JOIN sheet s2 ON d2.delegation_sid = s2.delegation_sid
							 WHERE s.sheet_id = in_sheet_id) 
		   AND notify_user_sid IN (SELECT user_sid 
									 FROM sheet s 
									 JOIN v$delegation_user du ON s.delegation_sid = du.delegation_sid
									WHERE s.sheet_id = in_sheet_id); 
	END IF;
END;

/**
 * Based on the sheet id passed to this procedure, it will work its way up the delegation
 * tree in order to locate the most 'active' sheet higher up the tree. 'Active' means
 * that something can be, or is about to be done to it, i.e. it's been submitted pending approval,
 * it's been returned and is editable, it's been accepted and the parent is editable,
 * or it's been merged.
 *
 * The algorithm used is based on the status of the sheet as follows
 *
 * 	            user:   parent      |  owner       |  owner       |  owner
 *	                    owner       |              |              |
 *	                    ------------+--------------+--------------+------------
 *	                                |              |              |
 *	              o                 |              |  waiting     |  merged
 *	              |                 |              |              |
 *	              o     submitted   |  returned    |  (accepted)  |  (accepted)
 *	              |                 |              |              |
 *	              o     (accepted)  |  returned    |  (accepted)  |  (accepted)
 *	              |                 |              |              |
 * start deleg => o     (accepted)  |  (accepted)  |  (accepted)  |  (accepted)
 *	              |
 *	              o
 *
 * @param in_sheet_id   The start sheet_id
 * @param out_cur		Rowset containing information about the sheet and users
 */
FUNCTION UNSEC_GetActiveSheetId(
	in_sheet_id		IN	sheet.sheet_id%TYPE
) RETURN sheet.sheet_id%TYPE
AS
	v_sheet_id	sheet.sheet_id%TYPE;
	v_start_delegation_sid	security_pkg.T_SID_ID;
	v_start_dtm				sheet.start_dtm%TYPE;
	v_end_dtm				sheet.end_dtm%TYPE;
BEGIN
	SELECT delegation_sid, start_dtm, end_dtm
	  INTO v_start_delegation_sid, v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	SELECT sheet_id --, parent_delegation_sid, delegation_sid, last_action_id
	  INTO v_sheet_id
	  FROM (
		-- find sheets we're interested in and rank them according to distance from
		-- us up the delegation structure
		SELECT delegation_sid, app_sid, parent_delegation_sid, last_action_id, sheet_id,
			ROW_NUMBER() OVER (ORDER BY lvl) rn
		  FROM (
			-- find delegation sheets
			SELECT d.delegation_sid, d.app_sid, d.lvl, last_action_id, sheet_id,
				d.parent_sid parent_delegation_sid,
				CASE WHEN last_action_id IN (
					-- 0,1,9,2,10,11,12,13
					csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD,
					csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD,
					csr_data_pkg.ACTION_MERGED, csr_data_pkg.ACTION_MERGED_WITH_MOD,
					csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD
				) THEN 1 ELSE 0 END incl
			  FROM sheet_with_last_action sla
				JOIN (
					-- get delegations up tree
					SELECT app_sid, delegation_sid, parent_sid, level lvl
					  FROM delegation
					 START WITH delegation_sid = v_start_delegation_sid
				   CONNECT BY PRIOR parent_sid = delegation_sid
				)d ON sla.delegation_sid = d.delegation_sid
				  AND sla.app_sid = d.app_sid
				  AND sla.end_dtm > v_start_dtm AND sla.start_dtm < v_end_dtm
		 )
		 WHERE incl = 1
	 )x
	 WHERE rn = 1;

	RETURN v_sheet_id;
END;

PROCEDURE INTERNAL_RejectSheet(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_note							IN	sheet_history.note%TYPE,
	in_is_system_note				IN	sheet_history.is_system_note%TYPE DEFAULT 0
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
	v_helper_pkg 		customer.helper_pkg%TYPE;
	v_start_dtm			sheet.start_dtm%TYPE;
	v_end_dtm			sheet.end_dtm%TYPE;
	v_name				delegation.name%TYPE;
BEGIN
	IF SheetIsReadOnly(in_sheet_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || in_sheet_id || ' is read only');
	END IF;

	UPDATE sheet_value
	   SET status = csr_data_pkg.SHEET_VALUE_ENTERED
	 WHERE sheet_id = in_sheet_id;

	SELECT s.delegation_sid, s.start_dtm, s.end_dtm, d.name
	  INTO v_delegation_sid, v_start_dtm, v_end_dtm, v_name
	  FROM sheet s
	  JOIN delegation d ON s.delegation_sid = d.delegation_sid
	 WHERE s.sheet_id = in_sheet_id;

	CreateHistory(in_sheet_id, csr_data_pkg.ACTION_RETURNED, SYS_CONTEXT('SECURITY', 'SID'), v_delegation_sid, in_note, in_is_system_note);
	-- raise an alert
	INSERT INTO delegation_change_alert (delegation_change_alert_id, raised_by_user_sid, notify_user_sid, sheet_id)
		SELECT deleg_change_alert_id_seq.nextval, SYS_CONTEXT('SECURITY', 'SID'), du.user_sid, in_sheet_id
		  FROM sheet s
		  JOIN v$delegation_user du ON s.delegation_sid = du.delegation_sid AND s.app_sid = du.app_sid
		  JOIN customer_alert_type cat ON s.app_sid = cat.app_sid AND cat.std_alert_type_id IN (csr_data_pkg.ALERT_SHEET_CHANGED, csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED)
		  JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		 WHERE s.sheet_id = in_sheet_id;

	-- call any grid post reject handlers for this grid
	FOR r IN (
		SELECT DISTINCT dg.helper_pkg, dg.name, s.delegation_sid, s.start_dtm, s.end_dtm
		  FROM sheet s
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		 WHERE s.sheet_id = in_sheet_id
		   AND dg.helper_pkg IS NOT NULL
	)
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.PostReject(:1,:2,:3,:4,:5);end;'
				USING in_act_id, r.delegation_sid, r.start_dtm, r.end_dtm, r.name;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END LOOP;

	-- call any postreject handlers....
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM customer
	 WHERE app_sid = security_pkg.getApp;

	IF v_helper_pkg IS NOT NULL THEN
	    BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.PostReject(:1,:2,:3,:4,:5,:6);end;'
				USING in_act_id, v_delegation_sid, v_start_dtm, v_end_dtm, v_name, in_sheet_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE ActionChangeRequest(
	in_sheet_change_req_id  IN	sheet_change_req.sheet_change_req_id%TYPE,
	in_is_approved			IN	sheet_change_req.is_approved%TYPE,
	in_note					IN	sheet_change_req.processed_note%TYPE,
	in_is_system_note		IN	sheet_history.is_system_note%TYPE DEFAULT 0
)
AS
	v_to_deleg_sid		security_pkg.T_SID_ID;
	v_from_deleg_sid	security_pkg.T_SID_ID;
	v_deleg_sid			security_pkg.T_SID_ID;
	v_sheet_start_dtm	sheet.start_dtm%TYPE;
	v_sheet_end_dtm		sheet.end_dtm%TYPE;
BEGIN
	-- TODO: is this user allowed to action a change request?
	-- i.e. what permissions does the user have on the active_sheet_id

	-- TODO: elsewhere --> if you submit or reject sheets that are in the active_sheet_id
	-- column (where is_approved is null), then maybe we should delete the change requests since they'll no longer
	-- be valid?

	-- can the user really do this?
	/*
	IF v_sheet.CAN_RETURN=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot return sheet '||in_sheet_id);
	END IF;
	*/

	IF in_is_approved NOT IN (0,1) THEN
		-- the constraint checks this too, but we don't want them passing NULL in
		-- I guess the constraint could check this too... oh well.
		RAISE_APPLICATION_ERROR(-20001, 'is_approved must be 0 or 1');
	END IF;

	UPDATE sheet_change_req
	   SET processed_dtm = SYSDATE,
		processed_by_sid = security_pkg.getsid,
		processed_note = in_note,
		is_approved = in_is_approved
	 WHERE sheet_change_req_id = in_sheet_change_req_id
	   AND is_approved is null;

	IF SQL%ROWCOUNT = 0 THEN
		-- nothing doing
		RETURN;
	END IF;

	IF in_is_approved = 1 THEN
		SELECT scr.req_to_change_sheet_Id
		  INTO v_from_deleg_sid
		  FROM sheet_change_req scr
		 WHERE scr.sheet_change_req_id = in_sheet_change_req_id;
		 
		ReturnToDelegees(
			in_act_id 		=> security.security_pkg.GetAct,
			in_sheet_id 	=> v_from_deleg_sid,
			in_note 		=> in_note,
			in_is_system 	=> 1
		);
	END IF;

	-- send a state changed alert or something to let the user know what's happened
	-- N.B. Fetching the delegation sid is done as a separate query to avoid a bad query plan with
	-- WHERE delegation_sid = ( subquery )
	SELECT delegation_sid 
	  INTO v_deleg_sid
	  FROM sheet s
	  JOIN sheet_change_req scr ON s.sheet_id = scr.req_to_change_sheet_id AND s.app_sid = scr.app_sid
	 WHERE scr.sheet_change_req_id = in_sheet_change_req_id;
	 	
	INSERT INTO sheet_change_req_alert (sheet_change_req_alert_id, notify_user_sid, raised_by_user_sid, sheet_change_req_id, action_type)
		SELECT sheet_change_req_alert_id_seq.nextval, user_sid, security_pkg.getSid, in_sheet_change_req_id, 
			   CASE WHEN in_is_approved = 1 THEN 'A' ELSE 'R' END
		  FROM v$delegation_user
		 WHERE delegation_sid = v_deleg_sid;
END;

PROCEDURE ChangeRequest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.T_SID_ID,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE
)
AS
	v_sheet					T_SHEET_INFO;
	v_user_sid				security_pkg.T_SID_ID;
	v_active_sheet_id		sheet.sheet_id%TYPE;
	v_sheet_change_req_id	sheet_change_req.sheet_change_req_id%TYPE := null;
	v_last_action_id		sheet_history.sheet_action_id%TYPE;
BEGIN
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- (could be read only)
	IF v_sheet.CAN_SUBMIT=1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot raise change request on sheet '||in_sheet_id);
	END IF;

	BEGIN
		v_active_sheet_id := UNSEC_GetActiveSheetId(in_sheet_id);
		INSERT INTO sheet_change_req (sheet_change_req_id, req_to_change_sheet_id, active_sheet_id,
			raised_dtm, raised_by_sid, raised_note, is_approved)
		VALUES (sheet_change_req_id_seq.nextval, in_sheet_id, v_active_sheet_id,
			SYSDATE, v_user_sid, in_note, null)
		RETURNING sheet_change_req_id INTO v_sheet_change_req_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- one already in there
			SELECT sheet_change_req_id, active_sheet_id
			  INTO v_sheet_change_req_id, v_active_sheet_id
			  FROM sheet_change_req
			 WHERE req_to_change_sheet_id = in_sheet_id
			   AND is_approved IS NULL;
	END;

	-- ONLY auto approve though if it's not yet been approved
	SELECT last_action_id
	  INTO v_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_Id = in_sheet_id;
	IF v_last_action_id = csr_data_pkg.ACTION_SUBMITTED OR csr_data_pkg.CheckCapability(in_act_id, 'Automatically approve Data Change Requests') THEN
		ActionChangeRequest(v_sheet_change_req_id, 1, 'Data Change Request automatically approved and form returned to user for editing', 1);
	ELSE
		INSERT INTO sheet_change_req_alert (sheet_change_req_alert_id, notify_user_sid, raised_by_user_sid, sheet_change_req_id, action_type)
			SELECT sheet_change_req_alert_id_seq.nextval, user_sid, v_user_sid, v_sheet_change_req_id, 'S'
			  FROM v$delegation_user
			 WHERE delegation_sid = (
			 	SELECT delegation_sid FROM sheet WHERE sheet_id = v_active_sheet_id);
	END IF;
END;

-- a delegee wants to submit data
PROCEDURE Submit(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_skip_check			IN	NUMBER DEFAULT 0 -- new 'sheet2' delegations do checks themselves because of conditionals...
)
AS
	v_sheet				T_SHEET_INFO;
	v_user_sid			security_pkg.T_SID_ID;
	cur_blockers		SYS_REFCURSOR;
	v_ind_sid			security_pkg.T_SID_ID;
	v_region_sid		security_pkg.T_SID_ID;
	v_section_key		delegation_ind.section_key%TYPE;
	v_reason			VARCHAR2(1024);
	v_helper_pkg		VARCHAR2(1024);
	v_found				BOOLEAN;
BEGIN
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);

	-- can the user really do this? (could be read only)
	IF v_sheet.CAN_SUBMIT=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot submit sheet '||in_sheet_id);
	END IF;

	-- check mandatory completed
	IF in_skip_check = 0 THEN
		GetBlockers(in_sheet_id, cur_blockers);
		FETCH cur_blockers INTO v_ind_sid, v_region_sid, v_section_key, v_reason;
		v_found := cur_blockers%FOUND;
		CLOSE cur_blockers;
		IF v_found THEN
			RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_VALUES_NOT_COMPLETED, 'All mandatory fields must be completed '||v_ind_sid||','||v_region_sid||','||v_section_key||','||v_reason);
		END IF;
	END IF;

	-- call any grid post submit handlers for this grid
	FOR r IN (
		SELECT DISTINCT dg.helper_pkg, dg.name, s.delegation_sid, s.start_dtm, s.end_dtm
		  FROM sheet s
			JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
			JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
			JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		WHERE s.sheet_id = in_sheet_id
		  AND dg.helper_pkg IS NOT NULL
	)
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.PostSubmit(:1,:2,:3,:4,:5);end;'
				USING in_act_id, r.delegation_sid, r.start_dtm, r.end_dtm, r.name;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END LOOP;

	-- call any postsubmit handlers that are configured for the customer as a whole....
	-- actually do it before we submit because this often writes data back to the sheet
	-- and we get a permission error if we do it afterwards!
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM customer
	 WHERE app_sid = security_pkg.getApp;

	IF v_helper_pkg IS NOT NULL THEN
	    BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.PostSubmit(:1,:2,:3,:4,:5,:6);end;'
				USING in_act_id, v_sheet.delegation_sid, v_sheet.start_dtm, v_sheet.end_dtm, v_sheet.name, in_sheet_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	-- mark values as submitted
	UPDATE sheet_value
	   SET status = csr_data_pkg.SHEET_VALUE_SUBMITTED
	 WHERE sheet_id = in_sheet_id;

	-- remove any files for cached values
	FOR r in (
		SELECT DISTINCT svhc.sheet_value_id
		  FROM sheet_value_hidden_cache svhc
		  JOIN sheet_value_file svf on svhc.sheet_value_id = svf.sheet_value_id
		 WHERE svhc.sheet_value_id in (
			SELECT sheet_value_id
			  FROM sheet_value
			 WHERE sheet_id = in_sheet_id
		 )
	) LOOP
		RemoveAllFileUploads(in_act_id, r.sheet_value_id);
	END LOOP;

	-- clear out any cached values
	DELETE FROM sheet_value_hidden_cache
	 WHERE sheet_value_id in (
		SELECT sheet_value_id
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
	 );
	
	-- write a row to the history table for this change - note goes from this user to delegators
	user_pkg.GetSid(in_act_id, v_user_sid);
	CreateHistory(in_sheet_id, csr_data_pkg.ACTION_SUBMITTED, v_user_sid, v_sheet.parent_delegation_sid, in_note);
END;

-- delegator is sending data back for more tweaks
PROCEDURE ReturnToDelegees(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_is_system			IN	NUMBER DEFAULT 0
)
AS
	v_sheet						T_SHEET_INFO;
	v_user_sid					security_pkg.T_SID_ID;
	v_parent_sheet_id			csr_data_pkg.T_SHEET_ID;
	v_parent_delegation_sid		security_pkg.T_SID_ID;
	v_parent_last_action_id		security_pkg.T_SID_ID;
	v_fully_delegated 			NUMBER(10);
	v_cascade_reject			customer.cascade_reject%TYPE;
	v_parent_del_interval_id	delegation.period_interval_id%TYPE;
	v_sub_del_interval_id		delegation.period_interval_id%TYPE;
	v_parent_startdate			DATE;
	v_parent_enddate			DATE;
BEGIN
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);

	SELECT cascade_reject
	  INTO v_cascade_reject
	  FROM customer c, delegation d, sheet s
	 WHERE c.app_sid = d.app_sid
	   and d.delegation_sid = s.delegation_sid
	   and s.sheet_id = in_sheet_id;

	-- can the user really do this? (could be read only)
	IF in_is_system = 0 AND v_sheet.CAN_RETURN = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot return sheet '||in_sheet_id);
	END IF;

	-- mark values as entered (not submitted any more since we're sending back)
	UPDATE sheet_value
	   SET status = csr_data_pkg.SHEET_VALUE_ENTERED
	 WHERE sheet_id = in_sheet_id;

	-- write a row to the history table for this change - note goes from this user to delegees
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- get parent sheet
	v_parent_sheet_id := GetParentSheetId(in_sheet_id);
	SELECT delegation_sid, last_action_id
	  INTO v_parent_delegation_sid, v_parent_last_action_id
	  FROM sheet_with_last_action
	 WHERE sheet_id = v_parent_sheet_id;

	-- reject any DCRs
	UPDATE sheet_change_req
	   SET processed_note = 'Rejected because data returned outside of request', -- i18n grr
		processed_by_sid = v_user_sid,
		processed_dtm = SYSDATE,
		is_approved = 0
	 WHERE processed_dtm IS NULL
	   AND active_sheet_id = in_sheet_id;

	SELECT d.period_interval_id, dp.period_interval_id, sp.start_dtm, sp.end_dtm
	  INTO v_sub_del_interval_id, v_parent_del_interval_id, v_parent_startdate, v_parent_enddate
	  FROM delegation d
	  JOIN sheet s ON d.delegation_sid = s.delegation_sid
	  JOIN delegation dp ON d.parent_sid = dp.delegation_sid
	  JOIN sheet sp ON sp.delegation_sid = d.parent_sid
	 WHERE s.sheet_id= in_sheet_id
	   AND sp.start_dtm <= s.start_dtm
	   AND sp.end_dtm >= s.end_dtm;

	IF v_sub_del_interval_id <> v_parent_del_interval_id THEN
		v_sheet.start_dtm := v_parent_startdate;
		v_sheet.end_dtm := v_parent_enddate;
	END IF;

	-- set parent delegation to action_waiting if necessary (it might be accepted or something but we've just
	-- fiddled with stuff so we ought to make clear that there's more stuff going on with this delegation)
	IF v_parent_last_action_id != csr_data_pkg.ACTION_WAITING THEN
		FOR r IN (
			SELECT s.sheet_id, d.delegation_sid
			  FROM (
					SELECT delegation_sid
					  FROM delegation
					  START WITH delegation_sid = v_parent_delegation_sid
					CONNECT BY PRIOR parent_sid = delegation_sid
				)d
			  JOIN sheet s ON d.delegation_Sid = s.delegation_sid
			 WHERE s.start_dtm >= v_sheet.start_dtm
			   AND s.end_dtm <= v_sheet.end_dtm
	 	)
	 	LOOP
			CreateHistory(r.sheet_id, csr_data_pkg.ACTION_WAITING, v_user_sid, r.delegation_sid, in_note);
		END LOOP;
	END IF;

	-- do we need to bump back child delegation?
	-- if we've been fully delgeated then reject the child sheet
	SELECT fully_delegated
	  INTO v_fully_delegated
	  FROM delegation
	 WHERE delegation_sid = v_sheet.delegation_sid;

	 IF v_fully_delegated != csr_data_pkg.NOT_FULLY_DELEGATED AND v_cascade_reject = 1 THEN
	 	-- reject child sheets
	 	FOR r IN (
			SELECT s.sheet_id, d.delegation_sid
			  FROM (
					 SELECT delegation_sid
					   FROM delegation
					  START WITH parent_sid = v_sheet.delegation_sid
					CONNECT BY PRIOR delegation_sid = parent_sid
				)d
			  JOIN sheet s ON d.delegation_Sid = s.delegation_sid
			 WHERE s.start_dtm >= v_sheet.start_dtm
			   AND s.end_dtm <= v_sheet.end_dtm
	 	)
	 	LOOP
			-- reject any DCRs
			UPDATE sheet_change_req
			   SET processed_note = 'Rejected because data returned outside of request', -- i18n grr
				processed_by_sid = v_user_sid,
				processed_dtm = SYSDATE,
				is_approved = 0
			 WHERE processed_dtm IS NULL
			   AND active_sheet_id = r.sheet_id;

			-- mark values as entered (not submitted any more since we're sending back)
			INTERNAL_RejectSheet(in_act_id, r.sheet_id, in_note);
	 	END LOOP;
    END IF;

	CreateHistory(in_sheet_id, csr_data_pkg.ACTION_RETURNED, v_user_sid, v_sheet.delegation_sid, in_note);
END;

-- Checks whether data on the given sheet has been submitted on-time for a region.
-- Timeliness metric.
PROCEDURE CheckOnTime(
	in_act_id           IN security_pkg.T_ACT_ID,
	in_sheet_id         IN security_pkg.T_SID_ID,
	in_region_sid       IN security_pkg.T_SID_ID
)
AS
	v_already_checked   NUMBER(1);				-- Have we checked this data before?
	v_deadline_dtm      DATE;					-- Data submission deadline date
	v_merged_dtm        DATE;         			-- Date data is being merged (today)

	v_dummy_sid         security_pkg.T_SID_ID;	-- Don't need the SID of the val
BEGIN
	-- Get deadline date of sheet
	SELECT submission_dtm+1
	  INTO v_deadline_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- Update each MERGED_ON_TIME ind for the region
	FOR r IN (
		SELECT ind_sid
		  FROM delegation_ind
		 WHERE meta_role = 'MERGED_ON_TIME'
		   AND delegation_sid IN (
				SELECT delegation_sid
				  FROM sheet
				 WHERE sheet_id = in_sheet_id
			)
	)
	LOOP
		-- Determine if we've already checked this data
		SELECT COUNT(sheet_id)
		  INTO v_already_checked
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
		   AND region_sid = in_region_sid
		   AND ind_sid = r.ind_sid
		   AND val_number IS NOT NULL;

		-- Check if we have checked this data was on-time before. If so, don't update otherwise
		-- we might mark data that was originally submitted on-time as late.
		-- There should only ever be 1 row in the DB for this particular region, sheet + ind if
		-- we have checked it before.
		IF v_already_checked = 0 THEN
			-- Check if submitted on-time or not
			IF SYSDATE <= v_deadline_dtm THEN
				-- It's been merged on-time
				delegation_pkg.SaveValue (
					in_act_id => in_act_id,
					in_sheet_id => in_sheet_id,
					in_ind_sid => r.ind_sid,
					in_region_sid => in_region_sid,
					in_val_number => 1,
					in_entry_conversion_id => NULL,
					in_entry_val_number => 1,
					in_note => NULL,
					in_reason => NULL,
					in_file_count => 0,
					in_flag => NULL,
					in_write_history => 1,
					out_val_id => v_dummy_sid
				);
			ELSE
				-- The data is late - past the deadline date
				delegation_pkg.SaveValue (
					in_act_id => in_act_id,
					in_sheet_id => in_sheet_id,
					in_ind_sid => r.ind_sid,
					in_region_sid => in_region_sid,
					in_val_number => 0,
					in_entry_conversion_id => NULL,
					in_entry_val_number => 0,
					in_note => NULL,
					in_reason => NULL,
					in_file_count => 0,
					in_flag => NULL,
					in_write_history => 1,
					out_val_id => v_dummy_sid
				);
			END IF;
		END IF;
	END LOOP;

	-- Mark the region as merged for all 'MERGED' indicators
	FOR r IN (
	SELECT ind_sid
	  FROM delegation_ind
	 WHERE meta_role = 'MERGED'
	   AND delegation_sid IN (
			SELECT delegation_sid
			  FROM sheet
			 WHERE sheet_id = in_sheet_id
		)
	)
	LOOP
		-- Mark this region as merged
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => 1,
			in_entry_conversion_id => NULL,
			in_entry_val_number => 0,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;
END;

-- Counts how many sheet fields have been filled in on a particular sheet for a region.
-- Completeness metric.
PROCEDURE CheckDataPoints(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sheet_id			IN security_pkg.T_SID_ID,
	in_region_sid		IN security_pkg.T_SID_ID
)
AS
	v_region_complete_dp		NUMBER(24); -- Stores total number of DPs that have data.
	v_region_total_dp			NUMBER(24);	-- Stores total number of DPs for region.
	v_deleg_sid					NUMBER(10); -- Stores the delegation sid of the sheet.

	v_val_is_text				NUMBER(1);	-- Stores whether a sheet val uses a text measure.

	v_dummy_sid		security_pkg.T_SID_ID;	-- Don't need the SID of the val
BEGIN
	v_region_complete_dp := 0;

	-- Get the delegation sid for the sheet
	SELECT delegation_sid
	  INTO v_deleg_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- We need to check each value is greater than 0 and not empty/null
	FOR r IN (
		-- Get inds that don't have a meta_role (this excludes our user perf inds)
		SELECT ind_sid, val_number, note
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
		   AND region_sid = in_region_sid
		   AND ind_sid NOT IN (
				SELECT ind_sid
				  FROM delegation_ind
				 WHERE meta_role IS NOT NULL
				   AND delegation_sid = v_deleg_sid
			)
		   AND ind_sid IN (	-- Ignore everything except normal inds
				SELECT dind.ind_sid
				  FROM delegation_ind dind
				  JOIN ind ind
					ON dind.ind_sid = ind.ind_sid
				 WHERE ind.ind_type = csr_data_pkg.IND_TYPE_NORMAL
				   AND dind.delegation_sid = v_deleg_sid
			)
	)
	LOOP
		-- Check for valid values.
		IF NVL(r.val_number, 0) > 0 THEN
			-- Update, this DP has numeric data
			v_region_complete_dp := v_region_complete_dp + 1;
		ELSIF r.note IS NOT NULL THEN
			-- Make sure the note actually has data (might not be NULL).
			IF LENGTH(r.note) > 0 THEN
				-- Work out if the current sheet val uses a text measure
				-- Should only return 1 result as we're only looking for 1 ind.
				SELECT COUNT(ind_sid)
				  INTO v_val_is_text
				  FROM ind
				 WHERE ind_sid = r.ind_sid
				   AND measure_sid IN (
						SELECT measure_sid
						  FROM measure
						 WHERE (std_measure_conversion_id IS NULL OR custom_field = '|')
					);

				-- Make sure the measure is text (data point could be a number with
				-- no value but with a note).
				IF v_val_is_text = 1 THEN
					-- Sheet value is text!
					-- Update, this DP has data
					-- We're currently counting text version of zero as data
					v_region_complete_dp := v_region_complete_dp + 1;
				END IF;
			END IF;
		END IF;
	END LOOP;

	FOR r IN (
		SELECT ind_sid
		  FROM delegation_ind
		 WHERE meta_role = 'DP_COMPLETE'
		   AND delegation_sid = v_deleg_sid
	)
	LOOP
		-- Update sheet vals for the data point indicators
		-- Set this region's DP complete value
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => v_region_complete_dp,
			in_entry_conversion_id => NULL,
			in_entry_val_number => v_region_complete_dp,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;

	-- Just count the indicators that are associated with the delegation.
	-- We want to ignore any meta_role (User Perf), hidden indicators,
	-- indicators that don't have measure IDs and calc indicators.
	SELECT COUNT(dind.ind_sid)
	  INTO v_region_total_dp
	  FROM csr.delegation_ind dind
	  JOIN csr.ind ind
		ON ind.ind_sid = dind.ind_sid
	  LEFT JOIN csr.ind_selection_group isg
		ON ind.ind_sid = isg.master_ind_sid
	 WHERE dind.delegation_sid = v_deleg_sid
	   AND dind.visibility <> 'HIDE'
	   AND dind.meta_role IS NULL
	   AND ind.measure_sid IS NOT NULL
	   AND (ind.ind_type = csr_data_pkg.IND_TYPE_NORMAL OR
			isg.master_ind_sid IS NOT NULL);

	FOR r IN (
		SELECT ind_sid
		  FROM delegation_ind
		 WHERE meta_role = 'COMP_TOTAL_DP'
		   AND delegation_sid = v_deleg_sid
	)
	LOOP
		-- Set this region's total DP value
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => v_region_total_dp,
			in_entry_conversion_id => NULL,
			in_entry_val_number => v_region_total_dp,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;
END;

-- Counts how many sheet fields have been filled in on a particular sheet for a region with the Ind selection flags in deleg_meta_role_ind_selection.
-- Accuracy metric 1.
PROCEDURE CheckIndSelectionDP(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sheet_id			IN security_pkg.T_SID_ID,
	in_region_sid		IN security_pkg.T_SID_ID
)
AS
	v_region_count_dp		NUMBER(24); -- Stores total number of DPs have the ind selection flag we want to count.
	v_region_total_dp		NUMBER(24);	-- Stores total number of DPs that use ind selection flags.
	v_deleg_sid				NUMBER(10); -- SID of delegation the sheet is associated with.

	v_val_is_text			NUMBER(1);	-- Stores whether a sheet val uses a text measure.

	v_dummy_sid		security_pkg.T_SID_ID;	-- Don't need the SID of the val
BEGIN
	-- Get, and store, the delegation SID
	SELECT delegation_sid
	  INTO v_deleg_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- We need to check each value is greater than 0 and not empty/null
	FOR r IN (
		-- Get the ind sids of the indicators that are going to store total number of each ind sel flag.
		SELECT dmris.lang, dmris.description, dind.ind_sid
		  FROM delegation_ind dind
		  LEFT JOIN deleg_meta_role_ind_selection dmris
		    ON dind.delegation_sid = dmris.delegation_sid
		   AND dind.ind_sid = dmris.ind_sid
		 WHERE dind.meta_role = 'IND_SEL_COUNT'
		   AND dind.delegation_sid = v_deleg_sid
	)
	LOOP
		v_region_count_dp := 0;		-- Set to 0 here so we don't keep counting!

		FOR s IN (
			-- Get the ind sids of the indicators that use ind selection flags and check the values aren't zero or 'n/a'.
			SELECT ind_sid, region_sid, val_number, note
			  FROM sheet_value
			 WHERE sheet_id = in_sheet_id
			   AND region_sid = in_region_sid
			   AND ind_sid NOT IN (
					SELECT ind_sid
					  FROM delegation_ind
					 WHERE meta_role IS NOT NULL
				)
			   AND ind_sid IN (
					SELECT ind_sid
					  FROM ind_sel_group_member_desc
					 WHERE lang = r.lang
					   AND LOWER(description) = LOWER(r.description)
				)
			   AND (val_number IS NOT NULL OR LENGTH(note) > 0) -- some notes may not be NULL, but are empty.
		)
		LOOP
			-- Check for valid values.
			IF NVL(s.val_number, 0) > 0 THEN
				-- Sheet value is a number!
				-- Must ignore zeros (regard them as 'data not entered').
				v_region_count_dp := v_region_count_dp + 1;
			ELSIF s.note IS NOT NULL THEN
				-- Work out if the current sheet val uses a text measure
				-- Should only return 1 result as we're only looking for 1 ind.
				SELECT COUNT(ind_sid)
				  INTO v_val_is_text
				  FROM ind
				 WHERE ind_sid = r.ind_sid
				   AND measure_sid IN (
						SELECT measure_sid
						  FROM measure
						 WHERE (std_measure_conversion_id IS NULL OR custom_field = '|')
					);

				-- Make sure the measure is text (data point could be a number with
				-- no value but with a note).
				IF v_val_is_text = 1 THEN
					-- Sheet value is text!
					-- Is it likely they'll enter a '0' in a text field??
					IF LOWER(TO_CHAR(s.note)) <> 'n/a' THEN
						-- Update, this DP has data that isn't 'n/a'
						-- We're currently counting text version of zero as data
						v_region_count_dp := v_region_count_dp + 1;
					END IF;
				END IF;
			END IF;
		END LOOP;

		-- Write count of ind selection flag to the relevant indicator.
		-- We'll write the total after we've gone through them all.
		-- Update sheet vals for the ind that keeping count of the flag.
		-- Set this region's flag count.
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => v_region_count_dp,
			in_entry_conversion_id => NULL,
			in_entry_val_number => v_region_count_dp,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;

	-- Count all indicators for this region that use ind quality flags
	-- and have valid data.
	SELECT COUNT(ind_sid)
	  INTO v_region_total_dp
	  FROM sheet_value
	 WHERE sheet_id = in_sheet_id
	   AND region_sid = in_region_sid
	   AND ind_sid NOT IN (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role IS NOT NULL
			   AND delegation_sid = v_deleg_sid
		)
	   AND ind_sid IN (
			SELECT DISTINCT(ind_sid)
			  FROM ind_selection_group_member
		)
	   AND (val_number IS NOT NULL OR LENGTH(note) > 0); -- some notes may not be NULL, but are empty.

	-- Update all of our TOTAL_IND_SEL inds. These store the total number
	-- of indicators that use ind Flags for this region.
	FOR r IN (
		SELECT ind_sid
		  FROM delegation_ind
		 WHERE meta_role = 'IND_SEL_TOTAL'
		   AND delegation_sid IN (
				SELECT delegation_sid
				  FROM sheet
				 WHERE sheet_id = in_sheet_id
			)
	)
	LOOP
		-- Set this region's total DP value
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => v_region_total_dp,
			in_entry_conversion_id => NULL,
			in_entry_val_number => v_region_total_dp,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;
END;

-- Counts how many sheet data points have been changed since data was merged with DB.
-- Accuracy metric 2.
PROCEDURE CheckDPsChangedAfterMerge(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sheet_id			IN security_pkg.T_SID_ID,
	in_region_sid		IN security_pkg.T_SID_ID
)
AS
	v_merged_before				NUMBER(1);	-- Stores whether this sheet has been merged before.
	v_region_total_dp			NUMBER(24);	-- Stores total number of DPs for region.
	v_deleg_sid					NUMBER(10); -- Stores the delegation sid of the sheet.
	v_merged_dtm				DATE;		-- Stores the date the delegation was merged.

	v_val_is_text			NUMBER(1);	-- Stores whether a sheet val uses a text measure.

	v_dummy_sid		security_pkg.T_SID_ID;	-- Don't need the SID of the val
BEGIN
	v_region_total_dp := 0;

	-- Get the delegation sid for the sheet
	SELECT delegation_sid
	  INTO v_deleg_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- Check if this sheet has ever been merged (action id: 9).
	SELECT COUNT(sheet_id)
	  INTO v_merged_before
	  FROM csr.sheet_history
	 WHERE sheet_id = in_sheet_id
	   AND sheet_action_id = 9
	   AND rownum = 1;

	-- Count the number of data points that have valid data (we want to exclude '0' and 'N/A').
	-- Count the total like this so we ignore any vals that are (or may have been changed to) '0' or 'N/A'.
	FOR r IN (
		-- Get inds that don't have a meta_role (this excludes our user perf inds)
		SELECT ind_sid, val_number, note
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
		   AND region_sid = in_region_sid
		   AND ind_sid NOT IN (
				SELECT ind_sid
				  FROM delegation_ind
				 WHERE meta_role IS NOT NULL
				   AND delegation_sid = v_deleg_sid
			)
		   AND ind_sid IN (	-- Ignore everything except normal inds
				SELECT dind.ind_sid
				  FROM delegation_ind dind
				  JOIN ind ind
					ON dind.ind_sid = ind.ind_sid
				 WHERE ind.ind_type = csr_data_pkg.IND_TYPE_NORMAL
				   AND dind.delegation_sid = v_deleg_sid
			)
	)
	LOOP
		-- Check for valid data.
		IF NVL(r.val_number, 0) > 0 THEN
			-- Update, this DP has valid numeric data
			v_region_total_dp := v_region_total_dp + 1;
		ELSIF r.note IS NOT NULL THEN
			-- Work out if the current sheet val uses a text measure
			-- Should only return 1 result as we're only looking for 1 ind.
			SELECT COUNT(ind_sid)
			  INTO v_val_is_text
			  FROM ind
			 WHERE ind_sid = r.ind_sid
			   AND measure_sid IN (
					SELECT measure_sid
					  FROM measure
					 WHERE (std_measure_conversion_id IS NULL OR custom_field = '|')
				);

			-- Make sure the measure is text (data point could be a number with
			-- no value but with a note).
			IF v_val_is_text = 1 THEN
				-- Sheet value is text!
				-- Is it likely anyone will enter a '0' in a text field??
				IF LOWER(TO_CHAR(r.note)) <> 'n/a' THEN
					-- Update, this DP has data that isn't 'n/a'
					-- We're currently counting text version of zero as data
					v_region_total_dp := v_region_total_dp + 1;
				END IF;
			END IF;
		END IF;
	END LOOP;

	-- Don't bother checking each sheet value if this is the first time
	-- the sheet has been merged. If that's the case, just use the total no. of valid data points.
	IF v_merged_before = 1 THEN
		-- Get the last date this sheet was merged (the new merged date isn't written until
		-- all of the user performance updates are complete - later on in the MergeLowest SP).
		SELECT action_dtm
		  INTO v_merged_dtm
		  FROM (
			SELECT action_dtm
			  FROM sheet_history
			 WHERE sheet_action_id = 9
			   AND sheet_id = in_sheet_id
			 ORDER BY action_dtm DESC
		 )
		 WHERE rownum = 1;

		-- Count the data points that haven't changed since the sheet was last merged.
		DECLARE
			v_not_changed_count		NUMBER(10);		-- Total no. of DPs not changed.
		BEGIN
			v_not_changed_count := 0;

			FOR r IN (
				-- Get inds that don't have a meta_role (this excludes our user perf inds)
				SELECT ind_sid, set_dtm, val_number, note
				  FROM sheet_value
				 WHERE sheet_id = in_sheet_id
				   AND region_sid = in_region_sid
				   AND ind_sid NOT IN (
						SELECT ind_sid
						  FROM delegation_ind
						 WHERE meta_role IS NOT NULL
						   AND delegation_sid = v_deleg_sid
					)
				   AND ind_sid IN (	-- Ignore everything except normal inds
						SELECT dind.ind_sid
						  FROM delegation_ind dind
						  JOIN ind ind
							ON dind.ind_sid = ind.ind_sid
						 WHERE ind.ind_type = csr_data_pkg.IND_TYPE_NORMAL
						   AND dind.delegation_sid = v_deleg_sid
					)
			)
			LOOP
				-- Check for valid values.
				IF NVL(r.val_number, 0) > 0 THEN
					-- Check if data's changed since last merge.
					IF r.set_dtm < v_merged_dtm THEN
						-- Update, this DP has data that hasn't changed.
						v_not_changed_count := v_not_changed_count + 1;
					END IF;
				ELSIF r.note IS NOT NULL THEN

					-- Work out if the current sheet val uses a text measure
					-- Should only return 1 result as we're only looking for 1 ind.
					SELECT COUNT(ind_sid)
					  INTO v_val_is_text
					  FROM ind
					 WHERE ind_sid = r.ind_sid
					   AND measure_sid IN (
							SELECT measure_sid
							  FROM measure
							 WHERE (std_measure_conversion_id IS NULL OR custom_field = '|')
						);

					-- Make sure the measure is text (data point could be a number with
					-- no value but with a note).
					IF v_val_is_text = 1 THEN
						-- Check if data's changed since last merge.
						IF r.set_dtm < v_merged_dtm THEN
							-- Sheet value is text!
							-- Is it likely they'll enter a '0' in a text field??
							IF LOWER(TO_CHAR(r.note)) <> 'n/a' THEN
								-- Update, this DP has data that isn't 'n/a'
								-- We're currently counting text version of zero as data
								v_not_changed_count := v_not_changed_count + 1;
							END IF;
						END IF;
					END IF;
				END IF;
			END LOOP;

			-- Update sheet val for the data point not changed metric indicators
			FOR r IN (
				SELECT ind_sid
				  FROM delegation_ind
				 WHERE meta_role = 'DP_NOT_CHANGED_COUNT'
				   AND delegation_sid = v_deleg_sid
			)
			LOOP
				-- Set this region's DP complete value
				delegation_pkg.SaveValue (
					in_act_id => in_act_id,
					in_sheet_id => in_sheet_id,
					in_ind_sid => r.ind_sid,
					in_region_sid => in_region_sid,
					in_val_number => v_not_changed_count,
					in_entry_conversion_id => NULL,
					in_entry_val_number => v_not_changed_count,
					in_note => NULL,
					in_reason => NULL,
					in_file_count => 0,
					in_flag => NULL,
					in_write_history => 1,
					out_val_id => v_dummy_sid
				);
			END LOOP;
		END;
	ELSE
		-- No data points have been changed as this is the first time
		-- the sheet has been merged.
		FOR r IN (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role = 'DP_NOT_CHANGED_COUNT'
			   AND delegation_sid = v_deleg_sid
		)
		LOOP
			-- Set this region's total DP not changed metric value
			-- using the total no. valid data points.
			delegation_pkg.SaveValue (
				in_act_id => in_act_id,
				in_sheet_id => in_sheet_id,
				in_ind_sid => r.ind_sid,
				in_region_sid => in_region_sid,
				in_val_number => v_region_total_dp,
				in_entry_conversion_id => NULL,
				in_entry_val_number => v_region_total_dp,
				in_note => NULL,
				in_reason => NULL,
				in_file_count => 0,
				in_flag => NULL,
				in_write_history => 1,
				out_val_id => v_dummy_sid
			);
		END LOOP;
	END IF;

	-- Save the total number of valid data points to the total user perf indicator.
	FOR r IN (
		SELECT ind_sid
		  FROM delegation_ind
		 WHERE meta_role = 'ACC_TOTAL_DP'
		   AND delegation_sid = v_deleg_sid
	)
	LOOP
		-- Set this region's total DP value
		delegation_pkg.SaveValue (
			in_act_id => in_act_id,
			in_sheet_id => in_sheet_id,
			in_ind_sid => r.ind_sid,
			in_region_sid => in_region_sid,
			in_val_number => v_region_total_dp,
			in_entry_conversion_id => NULL,
			in_entry_val_number => v_region_total_dp,
			in_note => NULL,
			in_reason => NULL,
			in_file_count => 0,
			in_flag => NULL,
			in_write_history => 1,
			out_val_id => v_dummy_sid
		);
	END LOOP;
END;

PROCEDURE UNSEC_MergeLowest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE
)
AS
	v_user_sid		security_pkg.T_SID_ID;
	v_val_id		val.val_id%TYPE;
	v_file_uploads	security_pkg.T_SID_IDS;
	v_empty_uploads security_pkg.T_SID_IDS;
	v_helper_pkg 	customer.helper_pkg%TYPE;

	v_sheet_delegation_sid		security_pkg.T_SID_ID;
	v_sheet_start_dtm			sheet.start_dtm%TYPE;
	v_sheet_end_dtm				sheet.end_dtm%TYPE;
	v_sheet_name				delegation.name%TYPE;
	-- Used to determine which User Performance score metrics
	-- to calculate.
	v_do_merged_ontime			NUMBER(1);	-- Timeliness metric.
	v_do_count_complete_dp		NUMBER(1);	-- Completeness metric.
	v_do_acc_ind_sel_count		NUMBER(1);	-- Accuracy metric 1.
	v_do_acc_dp_changed			NUMBER(1);	-- Accuracy metric 2.
BEGIN
	SELECT s.delegation_sid, s.start_dtm, s.end_dtm, d.name
	  INTO v_sheet_delegation_sid, v_sheet_start_dtm, v_sheet_end_dtm, v_sheet_name
	  FROM sheet s
	  JOIN delegation d ON s.delegation_Sid = d.delegation_sid AND s.app_Sid = d.app_Sid
	 WHERE s.sheet_id = in_sheet_id;
	  
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- reject any DCRs
	FOR r IN (
		SELECT sheet_change_req_id
		  FROM sheet_change_req
		 WHERE processed_dtm IS NULL
	       AND active_sheet_id = in_sheet_id
	)
	LOOP
		ActionChangeRequest(r.sheet_change_req_id, 0, 'Rejected because data merged', 1);
	END LOOP;

	-- call any grid pre merge handlers for this grid
	-- we do this prior to actually merging because we might write data back
	FOR r IN (
		SELECT DISTINCT dg.helper_pkg, dg.name, s.delegation_sid, s.start_dtm, s.end_dtm
		  FROM sheet s
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		 WHERE s.sheet_id = in_sheet_id
		   AND dg.helper_pkg IS NOT NULL
	)
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'begin '||r.helper_pkg||'.PreMerge(:1,:2,:3,:4,:5);end;'
				USING in_act_id, r.delegation_sid, r.start_dtm, r.end_dtm, r.name;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END LOOP;

	-- call any premerge handlers....
	SELECT helper_pkg
	  INTO v_helper_pkg
	  FROM customer
	 WHERE app_sid = security_pkg.getApp;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.PreMerge(:1,:2,:3,:4,:5,:6);end;'
				USING in_act_id, v_sheet_delegation_sid, v_sheet_start_dtm, v_sheet_end_dtm, v_sheet_name, in_sheet_id;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;

	-- Find out what User Performance score inds are used by the sheet.
	-- Timeliness (if MERGED is used, so should MERGED_ON_TIME)
	SELECT COUNT(*)
	  INTO v_do_merged_ontime
	  FROM dual
	 WHERE EXISTS (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role = 'MERGED'
			   AND delegation_sid IN (
					SELECT delegation_sid
					  FROM sheet
					 WHERE sheet_id = in_sheet_id
				)
		);

	-- Completeness (if COMP_TOTAL_DP is used, so should DP_COMPLETE)
	SELECT COUNT(*)
	  INTO v_do_count_complete_dp
	  FROM dual
	 WHERE EXISTS (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role = 'COMP_TOTAL_DP'
			   AND delegation_sid IN (
					SELECT delegation_sid
					  FROM sheet
					 WHERE sheet_id = in_sheet_id
				)
		);

	-- Accuracy (if IND_SELECTION is used, so should TOTAL_IND_SEL_DP)
	SELECT COUNT(*)
	  INTO v_do_acc_ind_sel_count
	  FROM dual
	 WHERE EXISTS (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role = 'IND_SEL_COUNT'
			   AND delegation_sid IN (
					SELECT delegation_sid
					  FROM sheet
					 WHERE sheet_id = in_sheet_id
				)
		);

	-- Accuracy (if ACC_TOTAL_DP is used, so should DP_NOT_CHANGED_COUNT)
	SELECT COUNT(*)
	  INTO v_do_acc_dp_changed
	  FROM dual
	 WHERE EXISTS (
			SELECT ind_sid
			  FROM delegation_ind
			 WHERE meta_role = 'ACC_TOTAL_DP'
			   AND delegation_sid IN (
					SELECT delegation_sid
					  FROM sheet
					 WHERE sheet_id = in_sheet_id
				)
		);

	-- XXX: THIS LOOKS HORRIBLY SLOW AND INEFFICIENT???
	-- Loop through all regions on sheet and update User Performance score.
	-- (Timeliness, Completeness, Accuracy of data)
	FOR r IN (
	  SELECT deleg.region_sid
	    FROM sheet, delegation_region deleg
	   WHERE sheet.sheet_id = in_sheet_id
	     AND deleg.delegation_sid = sheet.delegation_sid
	)
	LOOP
		-- Timeliness metric
		IF v_do_merged_ontime = 1 THEN
			-- Update whether this region was merged on-time.
			CheckOnTime(in_act_id, in_sheet_id, r.region_sid);
		END IF;

		-- GUI will limit user to just 1, but SQL is capable of using multiple.
		-- Completeness metric
		IF v_do_count_complete_dp = 1 THEN
			-- Update the number of data points completed.
			CheckDataPoints(in_act_id, in_sheet_id, r.region_sid);
		END IF;

		-- Accuracy metric 1
		IF v_do_acc_ind_sel_count = 1 THEN
			-- Update number of data points completed with 'Actual' Q Flag/Ind Selection
			CheckIndSelectionDP(in_act_id, in_sheet_id, r.region_sid);
		END IF;

		-- Accuracy metric 2
		IF v_do_acc_dp_changed = 1 THEN
			-- Update whether this form has been re-merged.
			CheckDPsChangedAfterMerge(in_act_id, in_sheet_id, r.region_sid);
		END IF;
	END LOOP;

    -- merge numbers into db - we call directly with the SID not the access token since we've done all the access checks already.
	FOR r IN (
		SELECT sv.sheet_value_id, sv.ind_sid, sv.region_sid, s.start_dtm, s.end_dtm,
			   sv.val_number, -- val_converted derives val_number from entry_val_number in case of pct_ownership
			   sv.entry_measure_conversion_id,
			   sv.entry_val_number, sv.note, NVL(sv.flag,0) flag, NVL(reason,'New value') reason
		  FROM sheet s, sheet_value_converted sv, sheet_value_change svc
		 WHERE sv.sheet_id = s.sheet_id
		   AND sv.last_sheet_value_change_id = svc.sheet_value_change_id(+) -- not guaranteed to find a row in sheet_value_change
		   AND sv.sheet_value_id IN (
				-- merge with the top-most values (in case these weren't inherited from anything)
				SELECT NVL(siv.inherited_value_id, sv.sheet_value_id) sheet_value_id
				  FROM (
						-- get the lowest level set of values
						 SELECT sheet_value_id, inherited_value_id, CONNECT_BY_ROOT sheet_value_id root_value_id
						   FROM sheet_inherited_value
						  WHERE CONNECT_BY_ISLEAF = 1
						  START WITH sheet_value_id IN (
								SELECT sheet_value_id
								  FROM sheet_value
								 WHERE sheet_id = in_sheet_id)
						CONNECT BY PRIOR inherited_value_id = sheet_value_id) siv,
						sheet_value sv, sheet s,
						-- we include delegation_region + ind because sheet_value can include extraneous values if
						-- regions and inds got deleted (we keep the values in case the user re-adds them)
						delegation d, delegation_region dr, delegation_ind di, ind i
				 WHERE sv.sheet_id = in_sheet_id
				   AND sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
				   AND s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
				   AND d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
				   AND d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
				   AND sv.app_sid = dr.app_sid AND sv.region_sid = dr.region_sid
				   AND sv.app_sid = di.app_sid AND sv.ind_sid = di.ind_sid
				   AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
				   AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
				   AND i.measure_sid IS NOT NULL -- just in case they entered data, then converted to a folder
				   AND sv.sheet_value_id = siv.root_value_id(+)
				   AND delegation_pkg.IsCellVisibleInTagMatrix(sv.sheet_id, sv.region_sid, sv.ind_sid) = 1
		   ) -- not all values will be inherited
	)
	LOOP
		SELECT file_upload_sid
		  BULK COLLECT INTO v_file_uploads
		  FROM sheet_value_file
		 WHERE sheet_value_id = r.sheet_value_id;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid => v_user_sid,
			in_ind_sid => r.ind_sid,
			in_region_sid => r.region_sid,
			in_period_start => r.start_dtm,
			in_period_end => r.end_dtm,
			in_val_number => r.val_number,
			in_flags => r.flag,
			in_source_type_id => csr_Data_pkg.SOURCE_TYPE_DELEGATION,
			in_source_id => r.sheet_value_id,
			in_entry_conversion_id => r.entry_measure_conversion_id,
			in_entry_val_number => r.entry_val_number,
			in_update_flags => 0,
			in_reason => r.reason,
			in_note => r.note,
			in_have_file_uploads => 1,
			in_file_uploads => v_file_uploads,
			out_val_id => v_val_id);
	END LOOP;

	-- We now need to clear all the values that we don't need any more because they
	-- were previously merged at a different level.
	--
	-- There are two cases that this can occur in:
	-- a) A split sheet has a value X that is an aggregate of P, Q, R.  The sheet is merged.
	-- due to merging at the lowest level, we wrote P, Q, R into the val table.  The value X
	-- is then overriden, and the sheet remerged.  In this case we need to get rid of P, Q, R.
	-- b) In the same sheet, the value P is altered and the sheet accepted.  Now X = P+Q+R once
	-- more, and when the sheet is merged we need to remove the previously merged X and replace
	-- it with P, Q and R.
	--
	-- The method of finding these values is quite brutal: find all inds/regions/periods in
	-- the sheet and all children, and check this against the val table.  Then deduct all
	-- values we just merged, and clear the rest (by setting to NULL).
	-- The only exception case is that you can put folders/calcs/stored calcs on delegation forms
	-- so we skip any calculated indicators and indicators without measures.
	FOR r IN (
 		SELECT /*+ALL_ROWS*/ v.ind_sid, v.region_sid, v.start_dtm, v.end_dtm
 		  FROM (-- all the values on all the sheet, and all child sheets of the one we are merging
				-- that currently exist.  However skip those that are calculations, and those that are
				-- aggregates -- stored calculations or aggregates will be sorted out by the
				-- stored calc/aggregate engines
 		  		SELECT /*+ INDEX(V IDX_VAL_REGION_SID)*/ di.ind_sid, dr.region_sid, MIN(s.start_dtm) start_dtm, MAX(s.end_dtm) end_dtm
		          FROM delegation_region dr, delegation_ind di, sheet s, val v, ind i, (
						SELECT app_sid, delegation_sid
						  FROM delegation
							   START WITH delegation_sid = v_sheet_delegation_sid
							   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid) d
				 WHERE d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid AND
					   d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid AND
					   s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid AND
					   s.start_dtm >= v_sheet_start_dtm AND s.end_dtm <= v_sheet_end_dtm AND
					   i.app_sid = di.app_sid AND i.ind_sid = di.ind_sid AND
					   i.ind_type = csr_data_pkg.IND_TYPE_NORMAL AND i.measure_sid IS NOT NULL AND
					   v.app_sid = dr.app_sid AND v.region_sid = dr.region_sid AND
					   v.app_sid = s.app_sid AND v.period_start_dtm = s.start_dtm AND v.period_end_dtm = s.end_dtm AND
					   v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
				 GROUP BY di.ind_sid, dr.region_sid) v,
			  (-- all the values we are going to merge
				SELECT sv.ind_sid, sv.region_sid, s.start_dtm, s.end_dtm
				  FROM sheet s, sheet_value_converted sv, sheet_value_change svc
				 WHERE sv.sheet_id = s.sheet_id
				   AND sv.last_sheet_value_change_id = svc.sheet_value_change_id(+) -- not guaranteed to find this
				   AND sv.sheet_value_id IN (
						-- merge with the top-most values (in case these weren't inherited from anything)
						SELECT NVL(siv.inherited_value_id, sv.sheet_value_id) sheet_value_id
						  FROM (-- get the lowest level set of values
								 SELECT sheet_value_id, inherited_value_id, CONNECT_BY_ROOT sheet_value_id root_value_id
								   FROM sheet_inherited_value
								  WHERE CONNECT_BY_ISLEAF = 1
								  START WITH sheet_value_id IN (
										SELECT sheet_value_id
										  FROM sheet_value
										 WHERE sheet_id = in_sheet_id)
								CONNECT BY PRIOR inherited_value_id = sheet_value_id) siv,
							   sheet_value sv, sheet s,
					   		   -- we include delegation_region + ind because sheet_value can include extraneous values if
					   		   -- regions and inds got deleted (we keep the values in case the user re-adds them)
					   		   delegation d, delegation_region dr, delegation_ind di, ind i
				 		 WHERE sv.sheet_id = in_sheet_id
				   		   AND sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
				   		   AND s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
				   		   AND d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
				   		   AND d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
				   	       AND sv.app_sid = dr.app_sid AND sv.region_sid = dr.region_sid
				   		   AND sv.app_sid = di.app_sid AND sv.ind_sid = di.ind_sid
				   		   AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
				   		   AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
				   		   AND sv.sheet_value_id = siv.root_value_id(+))) sv -- not all values will be inherited
		 WHERE v.ind_sid = sv.ind_sid(+)
		   AND v.region_sid = sv.region_sid(+)
		   AND v.start_dtm < sv.end_dtm(+)
		   AND v.end_dtm > sv.start_dtm(+)
 		   AND sv.ind_sid IS NULL
	) LOOP
		--dbms_output.put_line('clearing ind = '||r.ind_sid||', region = '||r.region_sid||', start_dtm = '||r.start_dtm||', end_dtm = '||r.end_dtm);
		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid => v_user_sid,
			in_ind_sid => r.ind_sid,
			in_region_sid => r.region_sid,
			in_period_start => r.start_dtm,
			in_period_end => r.end_dtm,
			in_val_number => NULL,
			in_flags => 0,
			in_source_type_id => csr_Data_pkg.SOURCE_TYPE_DELEGATION,
			in_source_id => NULL,
			in_entry_conversion_id => NULL,
			in_entry_val_number => NULL,
			in_update_flags => 0,
			in_reason => 'Clearing blocking value during merge',
			in_note => NULL,
			in_have_file_uploads => 0,
			in_file_uploads => v_empty_uploads,
			out_val_id => v_val_id);
	END LOOP;

	-- remove any files for cached values
	FOR r in (
		SELECT DISTINCT svhc.sheet_value_id
		  FROM sheet_value_hidden_cache svhc
		  JOIN sheet_value_file svf on svhc.sheet_value_id = svf.sheet_value_id
		 WHERE svhc.sheet_value_id in (
			SELECT sheet_value_id
			  FROM sheet_value
			 WHERE sheet_id = in_sheet_id
		 )
	) LOOP
		RemoveAllFileUploads(in_act_id, r.sheet_value_id);
	END LOOP;

	-- clear out any cached values
	DELETE FROM sheet_value_hidden_cache
	 WHERE sheet_value_id in (
		SELECT sheet_value_id
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
	 );

	--Delete all alerts telling Approvers that sheets have been submitted 
	DELETE FROM delegation_change_alert
	 WHERE sheet_id IN (SELECT s2.sheet_id 
						  FROM delegation d 
						  JOIN sheet s ON d.delegation_sid = s.delegation_sid 
						  JOIN delegation d2 ON d2.parent_sid = d.delegation_sid 
						  JOIN sheet s2 ON d2.delegation_sid = s2.delegation_sid
						 WHERE s.sheet_id = in_sheet_id) 
	   AND notify_user_sid IN (SELECT user_sid 
								 FROM sheet s 
								 JOIN v$delegation_user du ON s.delegation_sid = du.delegation_sid
								WHERE s.sheet_id = in_sheet_id); 
END;

PROCEDURE MergeLowest(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_id				IN	security_pkg.t_sid_id,
	in_note					IN	SHEET_HISTORY.NOTE%TYPE,
	in_provisional_data		IN	NUMBER DEFAULT 0,
	in_skip_check			IN	NUMBER DEFAULT 0
)
AS
	v_sheet			T_SHEET_INFO;
	cur_blockers	SYS_REFCURSOR;
	v_ind_sid		security_pkg.T_SID_ID;
	v_region_sid	security_pkg.T_SID_ID;
	v_section_key	delegation_ind.section_key%TYPE;
	v_reason		VARCHAR2(1024);
	v_user_sid		security_pkg.T_SID_ID;
	v_found			BOOLEAN;
BEGIN
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);

	user_pkg.GetSid(in_act_id, v_user_sid);
	-- can the user really do this? Submitting a top level sheet is equiv to merging
	IF NOT (v_sheet.IS_TOP_LEVEL = 1 AND v_sheet.CAN_SUBMIT = 1) THEN
		-- override delegator can do this any time
		IF NOT (delegation_pkg.CheckDelegationPermission(in_act_id, v_sheet.delegation_sid, delegation_pkg.DELEG_PERMISSION_OVERRIDE)
		   AND in_provisional_data = 1) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot merge sheet '||in_sheet_id);
		END IF;
	END IF;

	-- check mandatory completed
	IF in_provisional_data = 0 THEN
		IF in_skip_check = 0 THEN
			GetBlockers(in_sheet_id, cur_blockers);
			FETCH cur_blockers INTO v_ind_sid, v_region_sid, v_section_key, v_reason;
			v_found := cur_blockers%FOUND;
			CLOSE cur_blockers;
			IF v_found THEN
				RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_VALUES_NOT_COMPLETED, 'All mandatory fields must be completed '||v_ind_sid||','||v_region_sid||','||v_section_key||','||v_reason);
			END IF;
		END IF;
		-- mark values as merged (not submitted any more since we're sending back)
		UPDATE sheet_value
		   SET status = csr_data_pkg.SHEET_VALUE_MERGED
		 WHERE sheet_id = in_sheet_id;
	END IF;

	UNSEC_MergeLowest(in_act_id, in_sheet_id, in_note);

	 -- write a row to the history table for this change - note goes from this user to delegees
	IF in_provisional_data = 0 THEN
		CreateHistory(in_sheet_id, csr_data_pkg.ACTION_MERGED, v_user_sid, v_sheet.delegation_sid, in_note);
	ELSE
		-- keep state the same but log message
		CreateHistory(in_sheet_id, v_sheet.last_action_id, v_user_sid, v_sheet.delegation_sid, in_note);
	END IF;
END;

PROCEDURE WriteCursorToSheet(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	delegation.start_dtm%TYPE,
	in_end_dtm			IN	delegation.end_dtm%TYPE,
	in_cur				IN	SYS_REFCURSOR
)
AS
	v_sheet_id					sheet.sheet_id%TYPE;
	v_ind_sid					security_pkg.T_SID_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_start_dtm					val.period_start_dtm%TYPE;
	v_end_dtm					val.period_end_dtm%TYPE;
	v_val						val.val_number%TYPE;
	v_val_id					NUMBER(10);
BEGIN
	-- assume the inds are on this sheet already...
	SELECT sheet_id
	  INTO v_sheet_id
	  FROM sheet
	 WHERE delegation_sid = in_delegation_sid
	   AND start_dtm = in_start_dtm
	   AND end_dtm = in_end_dtm;

	WHILE TRUE
	LOOP
		FETCH in_cur INTO v_ind_sid, v_region_sid, v_start_dtm, v_end_dtm, v_val;
		EXIT WHEN in_cur%NOTFOUND;

		delegation_pkg.SaveValue(
			in_act_id				=> in_act_id,
			in_sheet_id				=> v_sheet_id,
			in_ind_sid				=> v_ind_sid,
			in_region_sid			=> v_region_sid,
			in_val_number			=> v_val,
			in_entry_conversion_id	=> null,
			in_entry_val_number		=> null,
			in_note					=> null,
			in_reason				=> null,
			in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
			in_file_count			=> 0,
			in_flag					=> null,
			in_write_history		=> 1,
			out_val_id				=> v_val_id
		);
	END LOOP;
END;

PROCEDURE WriteCursorToVal(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_cur				IN	SYS_REFCURSOR
)
AS
	v_user_sid			security_pkg.T_SID_ID;
	v_ind_sid			security_pkg.T_SID_ID;
	v_region_sid		security_pkg.T_SID_ID;
	v_start_dtm			val.period_start_dtm%TYPE;
	v_end_dtm			val.period_end_dtm%TYPE;
	v_val				val.val_number%TYPE;
	v_val_id			val.val_id%TYPE;
BEGIN
	user_pkg.getsid(in_act_id, v_user_sid);

	WHILE TRUE
	LOOP
		FETCH in_cur INTO v_ind_sid, v_region_sid, v_start_dtm, v_end_dtm, v_val;
		EXIT WHEN in_cur%NOTFOUND;

		indicator_pkg.SetValueWithReasonWithSid(
			in_user_sid 	=> v_user_sid,
			in_ind_sid 		=> v_ind_sid,
			in_region_sid 	=> v_region_sid,
			in_period_start => v_start_dtm,
			in_period_end 	=> v_end_dtm,
			in_val_number	=> v_val,
			in_reason		=> 'Merged from delegation grid',
			out_val_id		=> v_val_id
		);
	END LOOP;
END;

PROCEDURE MakeEditable(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	in_message		IN	sheet_history.note%TYPE
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_to_delegation_sid		security_pkg.T_SID_ID;
	v_sheet		T_SHEET_INFO;
	v_new_status		NUMBER(10);
	v_parent_colour		VARCHAR2(1);
BEGIN
	SELECT delegation_sid
	  INTO v_to_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;
/*
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_to_delegation_sid, csr_data_pkg.PERMISSION_OVERRIDE_DELEGATOR) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	*/
	v_sheet := GetSheetInfo(in_act_id, in_sheet_id);

	SELECT last_action_colour
	  INTO v_parent_colour
	  FROM sheet_with_last_action
	 WHERE delegation_sid = v_sheet.parent_delegation_sid
	   AND start_dtm = v_sheet.start_dtm
	   AND end_dtm = v_sheet.end_dtm;

	-- can the user really do this?
	IF v_sheet.CAN_ACCEPT=0 AND v_sheet.CAN_OVERRIDE_DELEGATOR = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied: user cannot make sheet '||in_sheet_id||' editable');
	END IF;

	IF v_sheet.is_read_only = 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || in_sheet_id || ' is read only');
	END IF;

	IF v_parent_colour != 'R' THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, parent sheet in incorrect state');
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);

	SELECT CASE last_action_colour
		WHEN 'R' THEN csr_data_Pkg.ACTION_WAITING_WITH_MOD
		WHEN 'O' THEN csr_data_Pkg.ACTION_SUBMITTED_WITH_MOD
		WHEN 'G' THEN csr_data_Pkg.ACTION_ACCEPTED_WITH_MOD
		END INTO v_new_status
	  FROM sheet_with_last_action
	 WHERE sheet_id = in_sheet_id;

	sheet_pkg.CreateHistory(in_sheet_id, v_new_status,
		v_user_sid, v_to_delegation_sid, in_message, 1);
END;

PROCEDURE CreateHistory(
	in_sheet_id				IN	sheet.SHEET_ID%TYPE,
	in_operation_id			IN	SHEET_HISTORY.SHEET_ACTION_ID%TYPE,
	in_user_from			IN	security_pkg.T_SID_ID,
	in_to_delegation_sid	IN	security_pkg.T_SID_ID, -- null means read from sheet
	in_note					IN	sheet_history.NOTE%TYPE,
	in_is_system_note		IN	sheet_history.IS_SYSTEM_NOTE%TYPE DEFAULT 0
)
AS
	v_sheet_history_id		sheet_history.SHEET_HISTORY_ID%TYPE;
BEGIN
	SELECT sheet_history_id_seq.NEXTVAL
	  INTO v_sheet_history_id
	  FROM DUAL;

	INSERT INTO SHEET_HISTORY
		(SHEET_HISTORY_ID, SHEET_ID, SHEET_ACTION_ID, FROM_USER_SID, TO_DELEGATION_SID, ACTION_DTM, NOTE, IS_SYSTEM_NOTE)
	VALUES
		(v_sheet_history_id, in_sheet_id, in_operation_id, in_user_from, in_to_delegation_sid, SYSDATE, in_note, in_is_system_note);

	UPDATE SHEET SET LAST_SHEET_HISTORY_ID = v_sheet_history_id WHERE sheet_id = in_sheet_id;
END;

PROCEDURE RollbackHistory(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sheet_id				IN	SHEET.sheet_id%TYPE,
	in_sheet_action_id		IN	SHEET_ACTION.sheet_action_id%TYPE
)
AS
	v_delegation_sid	 		security_pkg.T_SID_ID;
	v_user_sid	 		security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	user_pkg.GetSid(in_act_id, v_user_sid);

	CreateHistory(in_sheet_id, in_sheet_action_id, v_user_sid, v_delegation_sid, 'Rollback requested', 1);
END;

PROCEDURE GetReminderAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_alert_batch_details_table		T_ALERT_BATCH_DETAILS_TABLE;
	
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_REMINDER_SHEET);
	-- FB9874 - Looks like Oracle caches an execution plan when temp_alert_batch_run is empty
	--          that takes forever for the query to run when it has data. So do the joins on
	--          the other tables first and then join to temp_alert_batch_run
	SELECT T_ALERT_BATCH_DETAILS_ROW(cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email,
		   cu.user_name, sla.sheet_id, d.editing_url||'sheetid='||sla.sheet_id, NVL(dd.description, d.name),
		    d.period_set_id, d.period_interval_id, d.delegation_sid,
			sla.submission_dtm, sla.reminder_dtm, sla.start_dtm, sla.end_dtm)
	BULK COLLECT INTO v_alert_batch_details_table
	  FROM sheet_with_last_action sla
	  JOIN v$delegation_user du ON sla.app_sid = du.app_sid AND sla.delegation_sid = du.delegation_sid
	  JOIN delegation d ON sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
	  JOIN csr_user cu ON du.app_sid = cu.app_sid AND du.user_sid = cu.csr_user_sid
	  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	  JOIN customer c ON c.app_sid = sla.app_sid AND c.raise_reminders = 1 AND scheduled_tasks_disabled = 0
	  LEFT JOIN sheet_alert sa ON du.app_sid = sa.app_sid AND sla.sheet_id = sa.sheet_id AND du.user_sid = sa.user_sid
	  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
	  LEFT JOIN delegation_description dd ON d.app_sid = dd.app_sid AND d.delegation_sid = dd.delegation_sid AND NVL(ut.language, 'en') = dd.lang
	 WHERE sla.last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD)
	   AND sa.reminder_sent_dtm IS NULL -- not reminded yet
	   AND sla.is_visible = 1 -- must be visible otherwise it's unfair to hassle the user
	   AND t.trash_sid IS NULL -- and user is not deleted
	   AND ut.account_enabled = 1 -- FB35676 user should also be active
	   AND sla.reminder_dtm > SYSDATE - Delegation_pkg.DELEG_ALERT_IGNORE_SHEETS_OLDER_THAN;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/t.app_sid, t.csr_user_sid, t.full_name, t.friendly_name, t.email,
			   t.user_name, t.sheet_id, t.sheet_url, delegation_pkg.ConcatDelegationUsers(t.delegation_Sid, 10) deleg_assigned_to,
			   t.delegation_name, t.submission_dtm, TO_CHAR(t.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt,
			   t.start_dtm sheet_start_dtm, t.end_dtm sheet_end_dtm, t.period_set_id, t.period_interval_id,
			   delegation_pkg.ConcatDelegRegionsByUserLang(t.delegation_sid, t.csr_user_sid) for_regions_description,
               (SELECT COUNT(*) FROM csr.delegation_region WHERE delegation_sid = t.delegation_sid) region_count, 
               delegation_pkg.FormatRegionNames(t.delegation_sid) region_names
		  FROM TABLE(v_alert_batch_details_table) t
		  JOIN temp_alert_batch_run tabr
			ON t.app_sid = tabr.app_sid
		   AND t.csr_user_sid = tabr.csr_user_sid
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_REMINDER_SHEET
		 WHERE t.reminder_dtm <= tabr.this_fire_time -- if the sheet needs a reminder
		   AND t.submission_dtm > tabr.this_fire_time -- but isn't overdue (in the user's local time zone)
	     ORDER BY t.app_sid, t.csr_user_sid, LOWER(t.delegation_name), t.delegation_sid, t.start_dtm;
END;

PROCEDURE RecordReminderSent(
	in_sheet_id						IN	sheet_alert.sheet_id%TYPE,
	in_user_sid						IN	sheet_alert.user_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO sheet_alert (sheet_id, user_sid, reminder_sent_dtm)
		VALUES (in_sheet_id, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE sheet_alert
			   SET reminder_sent_dtm = SYSDATE
			 WHERE sheet_id = in_sheet_id AND user_sid = in_user_sid;
	END;
END;

PROCEDURE GetOverdueAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_alert_batch_details_table		T_ALERT_BATCH_DETAILS_TABLE;
	
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_OVERDUE_SHEET);
	
	-- FB9874 - Looks like Oracle caches an execution plan when temp_alert_batch_run is empty
	--          that takes forever for the query to run when it has data. So do the joins on
	--          the other tables first and then join to temp_alert_batch_run
	SELECT T_ALERT_BATCH_DETAILS_ROW( cu.app_sid, cu.csr_user_sid, cu.full_name, cu.friendly_name, cu.email,
		   cu.user_name, sla.sheet_id, d.editing_url||'sheetid='||sla.sheet_id, NVL(dd.description, d.name),
		   d.period_set_id, d.period_interval_id, d.delegation_sid,
		   sla.submission_dtm, sla.reminder_dtm, sla.start_dtm, sla.end_dtm)
	BULK COLLECT INTO v_alert_batch_details_table
	  FROM sheet_with_last_action sla
	  JOIN v$delegation_user du ON sla.app_sid = du.app_sid AND sla.delegation_sid = du.delegation_sid
	  JOIN delegation d ON sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
	  JOIN csr_user cu ON du.app_sid = cu.app_sid AND du.user_sid = cu.csr_user_sid
	  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
	  JOIN customer c ON c.app_sid = sla.app_sid AND c.raise_reminders = 1 AND c.scheduled_tasks_disabled = 0
	  LEFT JOIN sheet_alert sa ON du.app_sid = sa.app_sid AND sla.sheet_id = sa.sheet_id AND du.user_sid = sa.user_sid
	  LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
	  LEFT JOIN delegation_description dd ON d.app_sid = dd.app_sid AND d.delegation_sid = dd.delegation_sid AND NVL(ut.language, 'en') = dd.lang	  
	 WHERE sla.last_action_id IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_RETURNED, csr_data_pkg.ACTION_RETURNED_WITH_MOD)
	   AND sa.overdue_sent_dtm IS NULL  -- make sure we've not spammed them already
	   AND sla.is_visible = 1 -- must be visible otherwise it's unfair to hassle the user
	   AND t.trash_sid IS NULL -- and user is not deleted
	   AND ut.account_enabled = 1 -- FB35676 user should also be active
	   AND sla.submission_dtm > SYSDATE - Delegation_pkg.DELEG_ALERT_IGNORE_SHEETS_OLDER_THAN;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ t.app_sid, t.csr_user_sid, t.full_name, t.friendly_name, t.email,
			   t.user_name, t.sheet_id, t.sheet_url, delegation_pkg.ConcatDelegationUsers(t.delegation_sid, 10) deleg_assigned_to,
			   t.delegation_name, t.submission_dtm, TO_CHAR(t.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt,
			   t.start_dtm sheet_start_dtm, t.end_dtm sheet_end_dtm, t.period_set_id, t.period_interval_id,
			   delegation_pkg.ConcatDelegRegionsByUserLang(t.delegation_sid, t.csr_user_sid) for_regions_description,
               (SELECT COUNT(*) FROM csr.delegation_region WHERE delegation_sid = t.delegation_sid) region_count, 
               delegation_pkg.FormatRegionNames(t.delegation_sid) region_names
		  FROM TABLE(v_alert_batch_details_table) t
		  JOIN temp_alert_batch_run tabr
			ON t.app_sid = tabr.app_sid
		   AND t.csr_user_sid = tabr.csr_user_sid
		   AND tabr.std_alert_type_id = csr_data_pkg.ALERT_OVERDUE_SHEET
		 WHERE t.submission_dtm <= tabr.this_fire_time -- the sheet is overdue (in the user's local time zone)
	     ORDER BY app_sid, csr_user_sid, LOWER(delegation_name), delegation_sid, start_dtm;
END;

PROCEDURE RecordOverdueSent(
	in_sheet_id						IN	sheet_alert.sheet_id%TYPE,
	in_user_sid						IN	sheet_alert.user_sid%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO sheet_alert (sheet_id, user_sid, overdue_sent_dtm)
		VALUES (in_sheet_id, in_user_sid, SYSDATE);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE sheet_alert
			   SET overdue_sent_dtm = SYSDATE
			 WHERE sheet_id = in_sheet_id AND user_sid = in_user_sid;
	END;
END;

PROCEDURE GetSheetEditedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT /*+ALL_ROWS*/ dea.DELEGATION_EDIT_ALERT_ID, dea.notify_user_sid, cu.email, cuf.full_name from_name, 
			   cu.full_name full_name, cu.friendly_name, 
        	   cu.full_name to_name, cu.email to_email, sa.description, cu.user_name, cu.csr_user_sid, dea.app_sid,
        	   d.name delegation_name, dd.description delegation_description,
			   s.submission_dtm, TO_CHAR(s.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, cuf.email from_email, 
               s.last_action_note note, d.name, s.sheet_id, 
               'https://'||c.host||d.editing_url||'sheetid='||s.sheet_id sheet_url,
               s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
               dea.raised_by_user_sid,
               (SELECT COUNT(*) FROM csr.delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               delegation_pkg.FormatRegionNames(d.delegation_sid) region_names
		  FROM delegation_edited_alert dea
		  JOIN csr_user cu ON dea.app_sid = cu.app_sid AND dea.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet_with_last_action s ON dea.app_sid = s.app_sid AND dea.sheet_id = s.sheet_id
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  JOIN csr_user cuf ON dea.app_sid = cuf.app_sid AND dea.raised_by_user_sid = cuf.csr_user_sid
		  JOIN sheet_action sa ON sa.sheet_action_id = s.last_action_id
		  JOIN customer c ON dea.app_sid = c.app_sid
		  JOIN customer_alert_type cat ON c.app_sid = cat.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_SHEET_EDITED
		  LEFT JOIN delegation_description dd ON dd.app_Sid = d.app_sid AND dd.delegation_sid = d.delegation_sid AND dd.lang = NVL(ut.language, 'en')
         WHERE c.scheduled_tasks_disabled = 0
		 ORDER BY cu.app_sid, cu.csr_user_sid;
END;

PROCEDURE RecordSheetEditedAlertSent(
	in_alert_id						IN	delegation_edited_alert.delegation_edit_alert_id%TYPE,
	in_user_sid						IN	delegation_edited_alert.notify_user_sid%TYPE
)
AS
BEGIN
	DELETE FROM delegation_edited_alert
	 WHERE delegation_edit_alert_id = in_alert_id
	   AND notify_user_sid = in_user_sid;
END;

PROCEDURE GetSheetCreatedAlerts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	alert_pkg.BeginStdAlertBatchRun(csr_data_pkg.ALERT_SHEET_CREATED);
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ sca.sheet_created_alert_id, sca.notify_user_sid, cuf.full_name delegator_full_name, cu.full_name, 
			   cu.friendly_name, cu.email, cu.user_name, cu.csr_user_sid, sca.app_sid,
        	   d.name delegation_name, 
			   dd.description delegation_description, 
			   s.submission_dtm, TO_CHAR(s.submission_dtm, 'Dy, dd Mon yyyy') submission_dtm_fmt, cuf.email delegator_email, 
        	   d.delegation_sid, s.sheet_id, 
        	   d.editing_url||'sheetid='||s.sheet_id sheet_url,
        	   delegation_pkg.ConcatDelegationUsers(d.delegation_sid, 10) deleg_assigned_to,
        	   s.start_dtm sheet_start_dtm, s.end_dtm sheet_end_dtm, d.period_set_id, d.period_interval_id,
        	   sca.raised_by_user_sid,
               (SELECT COUNT(*) FROM delegation_region WHERE delegation_sid = d.delegation_sid) region_count, 
               delegation_pkg.FormatRegionNames(d.delegation_sid) region_names
		  FROM sheet_created_alert sca
		  JOIN csr_user cu ON sca.app_sid = cu.app_sid AND sca.notify_user_sid = cu.csr_user_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		  JOIN sheet s ON sca.app_sid = s.app_sid AND s.sheet_id = sca.sheet_id
		  JOIN csr_user cuf ON sca.app_sid = cuf.app_sid AND sca.raised_by_user_sid = cuf.csr_user_sid
		  JOIN temp_alert_batch_run tabr ON sca.app_sid = tabr.app_sid AND sca.notify_user_sid = tabr.csr_user_sid
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation_description dd ON
			   dd.app_sid = d.app_sid AND 
			   dd.delegation_sid = d.delegation_sid AND 
			   dd.lang = NVL(ut.language, 'en')
		  JOIN customer c ON sca.app_sid = c.app_sid
		 WHERE tabr.std_alert_type_id = csr_data_pkg.ALERT_SHEET_CREATED
		   AND c.scheduled_tasks_disabled = 0
         ORDER BY cu.app_sid, cu.csr_user_sid; 
END;

PROCEDURE RecordSheetCreatedAlertSent(
	in_alert_id						IN	delegation_edited_alert.delegation_edit_alert_id%TYPE,
	in_user_sid						IN	delegation_edited_alert.notify_user_sid%TYPE
)
AS
BEGIN
	DELETE FROM sheet_created_alert
	 WHERE sheet_created_alert_id = in_alert_id
	   AND notify_user_sid = in_user_sid;
END;
-- ===========
-- DataSources
-- ===========
PROCEDURE ClearDataSources(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_value_id	IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
)
AS
BEGIN
	-- TODO: permission check?
	DELETE FROM sheet_value_accuracy
	 WHERE sheet_value_id = in_sheet_value_id;
END;

PROCEDURE AddDataSource(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_value_id	IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE,
	in_accuracy_type_option_id	IN	accuracy_type_option.accuracy_type_option_id%TYPE,
	in_pct				IN	sheet_value_accuracy.pct%TYPE
)
AS
BEGIN
	-- TODO: permission check?
	/* this is crap but I don't have time to dig and at the moment it causes:
		>From DBHelper.RunSP: From DBHelper.RunSPCustomRS: From DBHelper.SafeCmdExecute: ORA-01400: cannot insert NULL into ("CSR"."SHEET_VALUE_ACCURACY"."PCT")
		ORA-06512: at "CSR.SHEET_PKG", line 1164
		ORA-06512: at line 1 (0xC0040578)
		Category: DBHelper.RunSP
		Location: Line 553 Column -1
		*/
	IF in_pct IS NOT NULL THEN
		BEGIN
			INSERT INTO sheet_value_accuracy (sheet_value_id, accuracy_type_option_id, pct)
				VALUES (in_sheet_value_id, in_accuracy_type_option_id, in_pct);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;
END;

PROCEDURE GetDataSources(
	in_act_id		IN  security_pkg.T_ACT_ID,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE,
    out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: permission check?
	OPEN out_cur FOR
		SELECT sv.sheet_value_id, svds.accuracy_type_option_id, svds.pct, dst.q_or_c
		  FROM sheet_value sv, sheet_value_accuracy svds, accuracy_type_option ds, accuracy_type dst
		 WHERE sv.sheet_value_id = svds.sheet_value_id
           AND svds.accuracy_type_option_id = ds.accuracy_type_option_id
           AND ds.accuracy_type_id = dst.accuracy_type_id
		   AND sv.sheet_id = in_sheet_id;
END;

PROCEDURE GetDataSources(
	in_act_id		IN  security_pkg.T_ACT_ID,
	in_sheet_id		IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
    out_cur_q		OUT	SYS_REFCURSOR,
    out_cur_c		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO: permission check?
	OPEN out_cur_q FOR
		SELECT sv.sheet_value_id, svds.accuracy_type_option_id, svds.pct, dst.q_or_c
		  FROM sheet_value sv, sheet_value_accuracy svds, accuracy_type_option ds, accuracy_type dst
		 WHERE sv.sheet_value_id = svds.sheet_value_id
           AND svds.accuracy_type_option_id = ds.accuracy_type_option_id
           AND ds.accuracy_type_id = dst.accuracy_type_id
		   AND sv.sheet_id = in_sheet_id
		   AND sv.ind_sid = in_ind_sid
		   AND sv.region_sid = in_region_sid
		   AND UPPER(dst.q_or_c) = 'Q';

	OPEN out_cur_c FOR
		SELECT sv.sheet_value_id, svds.accuracy_type_option_id, svds.pct, dst.q_or_c
		  FROM sheet_value sv, sheet_value_accuracy svds, accuracy_type_option ds, accuracy_type dst
		 WHERE sv.sheet_value_id = svds.sheet_value_id
           AND svds.accuracy_type_option_id = ds.accuracy_type_option_id
           AND ds.accuracy_type_id = dst.accuracy_type_id
		   AND sv.sheet_id = in_sheet_id
		   AND sv.ind_sid = in_ind_sid
		   AND sv.region_sid = in_region_sid
		   AND UPPER(dst.q_or_c) = 'C';
END;

PROCEDURE GetIndicatorAccuracyTypes(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_cur_q		OUT	SYS_REFCURSOR,
    out_cur_c		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- removed permission check because it needs to be done on the sheet NOT
	-- on the sheet indicator members. Also this should probably be passed a
	-- delegation or sheet id so that it can do this for ALL Indicators with one
	-- DB call - this looks like it'll be very inefficient for a large form.

	--IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading indicator '||in_ind_sid);
	--END IF;

	OPEN out_cur_q FOR
		SELECT ty.accuracy_type_id, ty.label type_label, q_or_c, max_score,
			op.accuracy_type_option_id, op.label opt_label, accuracy_weighting
		  FROM ind_accuracy_type ia, accuracy_type ty, accuracy_type_option op
		 WHERE ia.ind_sid = in_ind_sid
		   AND ty.accuracy_type_id = ia.accuracy_type_id
		   AND op.accuracy_type_id = ty.accuracy_type_id
		   AND UPPER(ty.q_or_c) = 'Q'
		 ORDER BY ty.accuracy_type_id ASC, op.accuracy_weighting DESC;

	OPEN out_cur_c FOR
		SELECT ty.accuracy_type_id, ty.label type_label, q_or_c, max_score,
			op.accuracy_type_option_id, op.label opt_label, accuracy_weighting
		  FROM ind_accuracy_type ia, accuracy_type ty, accuracy_type_option op
		 WHERE ia.ind_sid = in_ind_sid
		   AND ty.accuracy_type_id = ia.accuracy_type_id
		   AND op.accuracy_type_id = ty.accuracy_type_id
		   AND UPPER(ty.q_or_c) = 'C'
		 ORDER BY ty.accuracy_type_id ASC, op.accuracy_weighting DESC;
END;

FUNCTION GetOrSetSheetValueId(
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN 	security_pkg.T_SID_ID,
	in_region_sid			IN 	security_pkg.T_SID_ID
) RETURN sheet_value.sheet_value_Id%TYPE
AS
	v_sheet_value_id	sheet_value.sheet_value_id%TYPE;
BEGIN
	BEGIN
	     INSERT INTO sheet_value (sheet_value_id, sheet_id, ind_sid, region_sid,
            val_number, flag, set_by_user_sid, set_dtm,
            note, entry_measure_conversion_id, entry_val_number, is_inherited, status
         ) VALUES (
         	sheet_value_id_seq.nextval,
         	in_sheet_id, in_ind_sid, in_region_sid,
            null,  -- val_number
            null, -- flag
            security_pkg.GetSID, SYSDATE,
            null, -- note
            null, -- entry_measure_conversion_id
            null, -- entry_val_number
            0, -- is_inherited
            0 -- status
         )
         RETURNING sheet_value_id
         INTO v_sheet_value_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT sheet_value_id
			  INTO v_sheet_value_id
			  FROM sheet_value
			 WHERE sheet_id = in_sheet_id
			   AND ind_sid = in_ind_sid
			   AND region_sid = in_region_sid;
	END;
	RETURN v_sheet_value_Id;
END;

PROCEDURE CopySheetValueExtraInfo(
	in_sheet_value_id				IN	sheet_value.sheet_value_id%TYPE,
	in_null_written					IN	BOOLEAN,
	in_from_sheet_value_ids			IN	VARCHAR2,
	in_set_sheet_iv_from_child		IN	BOOLEAN DEFAULT TRUE
)
AS
BEGIN
	IF in_sheet_value_id IS NULL THEN
		RETURN;
	END IF;

	FOR sv IN (
		SELECT in_sheet_value_id sheet_value_id, item inherited_value_id
		  FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,','))
	)
	LOOP
		BEGIN
			IF in_set_sheet_iv_from_child THEN
				-- Normal aggregation up we mark that parent value inherits from child
				INSERT INTO sheet_inherited_value (sheet_value_Id, inherited_value_Id)
				VALUES (sv.sheet_value_id, sv.inherited_value_id);
			ELSE
				-- When copying values from parent to child, we set the value for parent as inherited from child.
				INSERT INTO sheet_inherited_value (sheet_value_Id, inherited_value_Id)
				VALUES (sv.inherited_value_id, sv.sheet_value_id);
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; --ignore constraint violation - just means that we updated the value and it hadn't changed so this didn't get deleted
		END;
	END LOOP;

	IF in_set_sheet_iv_from_child THEN
		UPDATE sheet_value
		   SET is_inherited = 1
		 WHERE sheet_value_id = in_sheet_value_id;
	ELSE
		UPDATE sheet_value
		   SET is_inherited = 1
		 WHERE sheet_value_id IN (SELECT ITEM FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,',')));
	END IF;

	DELETE FROM sheet_value_accuracy
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_value_file
	 WHERE sheet_value_id = in_sheet_value_id;

	DELETE FROM sheet_value_var_expl
	 WHERE sheet_value_id = in_sheet_value_id;

	-- copy accuracy info up
	IF NOT in_null_written THEN
		INSERT INTO sheet_value_accuracy
			(sheet_value_id, accuracy_type_option_id, pct)
		SELECT in_sheet_value_id, accuracy_type_option_id, AVG(pct) pct
		  FROM sheet_value_accuracy
		 WHERE sheet_value_id IN (
			SELECT item
			  FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,','))
			)
		 GROUP BY accuracy_type_option_id;

		-- copy file upload info up
		INSERT INTO sheet_value_file
			(sheet_value_id, file_upload_sid)
		SELECT in_sheet_value_id, file_upload_sid
		  FROM sheet_value_file
		 WHERE sheet_value_id IN (
			SELECT item
			  FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,','))
			);

		-- copy var_expl info up
		INSERT INTO sheet_value_var_expl
			(sheet_value_id, var_expl_id)
		SELECT DISTINCT in_sheet_value_id, var_expl_id
		  FROM sheet_value_var_expl
		 WHERE sheet_value_id IN (
			SELECT item 
			  FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,','))
			);

		-- copy var_expl_notes up
		UPDATE sheet_value
		   SET var_expl_note = (
			SELECT csr.TruncateString(DBMS_LOB.SUBSTR(STRAGG2(var_expl_note),4000),2000)
			  FROM sheet_value
			 WHERE sheet_value_id IN (
				SELECT item
				  FROM TABLE(utils_pkg.SplitString(in_from_sheet_value_ids,','))
				)
		   )
		 WHERE sheet_value_id = in_sheet_value_id;
	END IF;
END;

PROCEDURE PropagateValuesToParentSheet(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sheet_id						IN	sheet_value.sheet_value_id%TYPE
)
AS
	 v_parent_sheet_id				csr_data_pkg.T_SHEET_ID;
	 v_sheet_value_id				sheet_value.sheet_value_id%TYPE;
	 v_file_count					NUMBER(10);
	 v_null_written					BOOLEAN;
BEGIN
	-- get the parent delegation sheet into which we fit
	BEGIN
		v_parent_sheet_id := GetParentSheetId(in_sheet_id);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- bail out if no parent sheet found
	END;

	-- this will aggregate values that haven't yet been submitted - not sure that this is a problem?
	FOR r IN (
		SELECT /*+ALL_ROWS*/ sheet_id, ind_sid, aggregate_to_region_sid, STRAGG2(note) note, aggregate, is_regional_aggregation,
			CASE
				WHEN MIN(entry_measure_conversion_id) = -1 THEN NULL -- see below - we swap NULL -> -1 for aggregations
				WHEN MAX(distinct_emc_id) = 1 AND COUNT(DISTINCT entry_measure_conversion_id) = 1 THEN MIN(entry_measure_conversion_id)
				ELSE NULL
			END entry_measure_conversion_id,
			CASE divisibility
				WHEN csr_data_pkg.DIVISIBILITY_AVERAGE THEN AVG(sum_val_number)
				WHEN csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN SUM(sum_val_number)
				-- we use MIN since we already figured out the last period in the inner query
				WHEN csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN MIN(sum_last_val_number)
			END val_number,
			CASE divisibility
				WHEN csr_data_pkg.DIVISIBILITY_AVERAGE THEN avg(sum_entry_val_number)
				WHEN csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN SUM(sum_entry_val_number)
				-- we use MIN since we already figured out the last period in the inner query
				WHEN csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN MIN(sum_last_entry_val_number)
			END entry_val_number,
			STRAGG(sheet_value_ids) sheet_value_ids,
			MIN(flag) flag,
			MIN(is_na) is_na
  	      FROM (
			  SELECT sheet_id, ind_sid, divisibility, aggregate, is_regional_aggregation, aggregate_to_region_sid, start_dtm, end_dtm, STRAGG2(note) note,
					 MIN(entry_measure_conversion_Id) entry_measure_conversion_id,
					 COUNT(DISTINCT entry_measure_conversion_id) distinct_emc_id,
					 SUM(val_number) sum_val_number, SUM(entry_val_number) sum_entry_val_number, -- sum regions as we aggregate
					 SUM(last_val_number) sum_last_val_number, SUM(last_entry_val_number) sum_last_entry_val_number,
					 STRAGG(sheet_value_id) sheet_value_ids, -- for accuracy copying
					 MIN(flag) flag,
					 MIN(is_na) is_na
			    FROM (
				  SELECT sp.sheet_id, sdi.ind_sid, NVL(i.divisibility, m.divisibility) divisibility,
				  		 i.aggregate, sdr.aggregate_to_region_sid, s.start_dtm, s.end_dtm,
						 CASE WHEN sdr.region_sid != sdr.aggregate_to_region_sid THEN 1 ELSE 0 END is_regional_aggregation,
						 -- if we're aggregating regions, then tag on the source of any notes
						 CASE WHEN sv.note IS NULL THEN NULL WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN sv.note ELSE sv.note||' ('||sdr.description||')' END note,
						 -- if we're not aggregating then use the value WITHOUT taking pct_ownership into account since this will get reapplied WHEN we store it
						 CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN val_number ELSE actual_val_number END val_number,
						 CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN entry_val_number ELSE entry_val_number * region_pkg.GetPctOwnership(sdi.ind_sid, sdr.region_sid, s.start_dtm)  END entry_val_number,
						 NVL(entry_measure_conversion_id,-1) entry_measure_conversion_id, -- NVL because NULL gets discarded by aggregate
						 -- figure out the "last_val_number" stuff here in case that's how we're aggregating
						 FIRST_VALUE(CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN val_number ELSE actual_val_number END)
							OVER (PARTITION BY sp.sheet_id, sdi.ind_sid, NVL(i.divisibility, m.divisibility),
											   sdr.aggregate_to_region_sid, sdr.region_sid
									  ORDER BY s.start_dtm DESC) last_val_number,
						 FIRST_VALUE(CASE WHEN sdr.region_sid = sdr.aggregate_to_region_sid THEN entry_val_number ELSE entry_val_number * region_pkg.GetPctOwnership(sdi.ind_sid, sdr.region_sid, s.start_dtm) END)
							OVER (PARTITION BY sp.sheet_id, sdi.ind_sid, NVL(i.divisibility, m.divisibility),
											   sdr.aggregate_to_region_sid, sdr.region_sid
									  ORDER BY s.start_dtm DESC) last_entry_val_number,
						 sheet_value_id, -- for accuracy copying
						 sv.flag, NVL(sv.is_na, 0) is_na
					-- Parent sheet (merging to)
		 			FROM sheet sp

					-- Inds on the parent sheet
					JOIN delegation_ind pdi
					  ON sp.app_sid = pdi.app_sid AND sp.delegation_sid = pdi.delegation_sid

					-- Child sheet (merging from)
		 			JOIN sheet sc
		 			  ON sc.sheet_id = in_sheet_id

		 			-- Inds on the child sheet
 				 	JOIN delegation_ind cdi
 				 	  ON cdi.app_sid = sc.app_sid AND cdi.delegation_sid = sc.delegation_sid
					 AND cdi.app_sid = pdi.app_sid AND cdi.ind_sid = pdi.ind_sid

                    -- Sibling sheet delegation
					JOIN delegation sd
					  ON sd.app_sid = sp.app_sid AND sd.parent_sid = sp.delegation_sid

		 			-- Sheets on sibling delegations (child sheets of the parent delegation)
		 			JOIN sheet s
		 			  ON sd.app_sid = s.app_sid AND sd.delegation_sid = s.delegation_sid
					 AND s.start_dtm >= sp.start_dtm
					 AND s.end_dtm <= sp.end_dtm

					-- Inds on the sibling sheet
					JOIN delegation_ind sdi
					  ON sdi.app_sid = s.app_sid AND sdi.delegation_sid = s.delegation_sid
					 AND sdi.app_sid = pdi.app_sid AND sdi.ind_sid = pdi.ind_sid

					-- Regions on the sibling sheet
					JOIN v$delegation_region sdr
					  ON sdr.app_sid = s.app_sid AND sdr.delegation_sid = s.delegation_sid

					-- All regions on the child sheet that are aggregated to
					-- This is used to pick up sibling sheets that aggregate to the same region
					JOIN (SELECT DISTINCT dr.app_sid, dr.aggregate_to_region_sid
							FROM delegation_region dr, sheet s
						   WHERE s.app_sid = dr.app_sid
							 AND s.delegation_sid = dr.delegation_sid
							 AND s.sheet_id = in_sheet_id) cdr
					  ON cdr.app_sid = sdr.app_sid AND cdr.aggregate_to_region_sid = sdr.aggregate_to_region_sid

					-- Region info
					JOIN region r
					  ON r.app_sid = sdr.app_sid AND r.region_sid = sdr.region_sid

					-- Ind info
					JOIN ind i
					  ON i.app_sid = cdi.app_sid AND i.ind_sid = cdi.ind_sid

					-- Measure info (for divisibility)
					LEFT JOIN measure m
					  ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid

					-- Values on those sheets, constraints to inds/regions that actually exist in the
					-- parent/sibling sheets (they may not, we keep data for inds/regions that have been
					-- removed from a delegation and we don't want to aggregate it).
					-- Apparently this is to stop people moaning that they lost their data when removing
					-- and re-adding an ind/region, but I think it's actually just to make my life difficult.
		 	   LEFT JOIN sheet_value_converted sv
		 			  ON s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
                     AND sv.app_sid = sdi.app_sid AND sv.ind_sid = sdi.ind_sid
					 AND sv.app_sid = sdr.app_sid AND sv.region_sid = sdr.region_sid
				   WHERE sp.sheet_id = v_parent_sheet_id
					)
				   GROUP BY sheet_id, ind_sid, divisibility, aggregate, is_regional_aggregation, aggregate_to_region_sid, start_dtm, end_dtm
			)
		 --WHERE (is_regional_aggregation = 0 OR (is_regional_aggregation = 1 AND aggregate IN ('SUM','FORCE SUM')))
		 GROUP BY sheet_id, ind_sid, divisibility, aggregate, is_regional_aggregation, aggregate_to_region_sid
	)
	LOOP
		-- We need the file upload count for all contributing sheet values
		SELECT COUNT(*)
		  INTO v_file_count
		  FROM sheet_value_file
		 WHERE sheet_value_id IN (
			SELECT item
			  FROM TABLE(utils_pkg.SplitString(r.sheet_value_ids,','))
			);

		-- writeback value including note, file, flag (we can do this since a single value)
		IF r.is_regional_aggregation = 1 AND r.aggregate NOT IN ('SUM','FORCE SUM') THEN
			-- writeback value including note, file, flag (we can do this since a single value)
			delegation_pkg.SaveValue(
				in_act_id				=> in_act_id,
				in_sheet_id				=> r.sheet_id,
				in_ind_sid				=> r.ind_sid,
				in_region_sid			=> r.aggregate_to_region_sid,
				in_val_number			=> null,
				in_entry_conversion_id	=> null,
				in_entry_val_number		=> null,
				in_note					=> 'Values at lower level',
				in_reason				=> 'Accepted from delegation',
				in_status				=> csr_data_pkg.SHEET_VALUE_PROPAGATED,
				in_file_count			=> null, -- Procedure now takes the file count so the value is created if the note was null but there are uploads
				in_flag					=> null,
				in_write_history		=> 1,
				out_val_id				=> v_sheet_value_id);
			v_null_written := true;
		ELSE
			-- writeback value including note, file, flag (we can do this since a single value)
			delegation_pkg.SaveValue(
				in_act_id				=> in_act_id,
				in_sheet_id				=> r.sheet_id,
				in_ind_sid				=> r.ind_sid,
				in_region_sid			=> r.aggregate_to_region_sid,
				in_val_number			=> r.val_number,
				in_entry_conversion_id	=> r.entry_measure_conversion_id,
				in_entry_val_number		=> CASE WHEN r.entry_measure_conversion_id IS NULL THEN NULL ELSE r.entry_val_number END,
				in_note					=> r.note,
				in_reason				=> 'Accepted from delegation',
				in_status				=> csr_data_pkg.SHEET_VALUE_PROPAGATED,
				in_file_count			=> v_file_count, -- Procedure now takes the file count so the value is created if the note was null buit there are uploads
				in_flag					=> r.flag,
				in_write_history		=> 1,
				in_is_na				=> r.is_na,
				out_val_id				=> v_sheet_value_id);
			v_null_written := false;
		END IF;

		-- sheet value id will NOT be null if the value for the sheet
		-- 	* exists already
		--  * the value OR note OR there are file uploads. If they are all null there's nothing to done in delegation_pkg.SaveValue and v_sheet_value_id will be NULL (not point carrying on)
		IF v_sheet_value_id IS NOT NULL THEN
			CopySheetValueExtraInfo(v_sheet_value_id, v_null_written, r.sheet_value_ids, true);
		END IF;
	END LOOP;
END;

PROCEDURE CopyValuesFromParentSheet(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sheet_id						IN	sheet_value.sheet_value_id%TYPE
)
AS
	v_sheet_value_id				sheet_value.sheet_value_id%TYPE;
	v_file_count					NUMBER(10);
	v_region_sid					security_pkg.T_ACT_ID;
	v_cur							SYS_REFCURSOR;
BEGIN

	FOR r IN (
		SELECT dr.region_sid, di.ind_sid, i.aggregate, NVL(i.divisibility, m.divisibility) divisibility,
			   dp.delegation_sid parent_deleg_sid, sc.start_dtm, sc.end_dtm
		  FROM delegation dp
		  JOIN delegation dc ON dp.delegation_sid = dc.parent_sid AND dp.app_sid = dc.app_sid
		  JOIN sheet sc ON dc.delegation_sid = sc.delegation_sid AND dc.app_sid = sc.app_sid
		  JOIN delegation_region dr ON dc.delegation_sid = dr.delegation_sid AND dc.app_sid = dr.app_sid
		  JOIN delegation_ind di ON dc.delegation_sid = di.delegation_sid AND dc.app_sid = di.app_sid
		  JOIN ind i ON di.ind_sid = i.ind_sid AND di.app_sid = i.app_sid
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		 WHERE sc.sheet_id = in_sheet_id
	)
	LOOP
		SELECT COUNT(*)
		  INTO v_file_count
		  FROM sheet_value_file
		 WHERE sheet_value_id = in_sheet_id;

		v_region_sid := r.region_sid;
		IF r.aggregate = 'DOWN' OR r.aggregate = 'FORCE DOWN' THEN
			BEGIN
				SELECT region_sid
				  INTO v_region_sid
				  FROM (
						SELECT region_sid, ROW_NUMBER() OVER (ORDER BY lvl) rn
						  FROM (
								SELECT region_sid, level lvl
								  FROM region
								 START WITH region_sid = r.region_sid
								CONNECT BY PRIOR parent_sid = region_sid
						)
						 WHERE region_sid IN (
								SELECT region_sid
								  FROM delegation_region
								 WHERE delegation_sid = r.parent_deleg_sid
						)
				)
				 WHERE rn = 1;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					NULL;
			END;
		END IF;

		FOR sv IN (
			SELECT sv.sheet_value_id, sv.region_sid, sv.ind_sid, sv.val_number, sv.entry_measure_conversion_id, sv.entry_val_number, sv.note, sv.flag, sv.is_na
			  FROM sheet_value sv
			  JOIN sheet s ON sv.sheet_id = s.sheet_id AND sv.app_sid = s.app_sid
			 WHERE sv.ind_sid = r.ind_sid
			   AND sv.region_sid = v_region_sid
			   AND s.delegation_sid = r.parent_deleg_sid
			   AND (
					(s.start_dtm = r.start_dtm AND s.end_dtm = r.end_dtm)
					OR
					(s.start_dtm <= r.start_dtm AND r.end_dtm <= s.end_dtm AND r.divisibility != csr_data_pkg.DIVISIBILITY_DIVISIBLE)
			)
		)
		LOOP
			delegation_pkg.SaveValue(
				in_act_id => in_act_id,
				in_sheet_id => in_sheet_id,
				in_ind_sid => sv.ind_sid,
				in_region_sid => r.region_sid,
				in_val_number => sv.val_number,
				in_entry_conversion_id => sv.entry_measure_conversion_id,
				in_entry_val_number => sv.entry_val_number,
				in_note => sv.note,
				in_reason => 'Propagated down from parent delegation',
				in_status => csr_data_pkg.SHEET_VALUE_PROPAGATED,
				in_file_count => v_file_count,
				in_flag => sv.flag,
				in_write_history => 1,
				in_force_change_reason => 0,
				in_no_check_permission => 1,
				in_is_na => sv.is_na,
				in_apply_percent_ownership => 0,
				out_cur => v_cur,
				out_val_id => v_sheet_value_id
				);

			FOR r IN (
				SELECT file_upload_sid
				  FROM sheet_value_file
				 WHERE sheet_value_id = sv.sheet_value_id
			)
			LOOP
				BEGIN
					INSERT INTO sheet_value_file (sheet_value_id, file_upload_sid)
						VALUES (v_sheet_value_id, r.file_upload_sid);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END LOOP;

			CopySheetValueExtraInfo(v_sheet_value_id, false, CAST (sv.sheet_value_id AS VARCHAR2), false);

		END LOOP;
	END LOOP;
END;

PROCEDURE CreateFileUploadFromCache(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_sheet_id			IN  security_pkg.T_SID_ID,
	in_cache_key		IN  VARCHAR2,
	out_file_upload_sid OUT security_pkg.T_SID_ID
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF NOT Security_Pkg.IsAccessAllowedSID(in_act_id, v_delegation_sid, Security_Pkg.PERMISSION_ADD_CONTENTS) THEN
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_delegation_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, SYS_CONTEXT('SECURITY','SID'), security_pkg.PERMISSION_LIST_CONTENTS+security_pkg.PERMISSION_ADD_CONTENTS);
	END IF; 
	 
	fileupload_pkg.CreateFileUploadFromCache(in_act_id, v_delegation_sid, in_cache_key, out_file_upload_sid);
END;

PROCEDURE UNSEC_SetVarExpl(
	in_sheet_value_id		IN	SHEET_VALUE.sheet_value_id%TYPE,
	in_var_expl_ids			IN	security_pkg.T_SID_IDS,
	in_var_expl_note		IN	sheet_value.var_expl_note%TYPE
)
AS
BEGIN
	DELETE FROM sheet_value_var_expl
	 WHERE sheet_value_id = in_sheet_value_id;

	-- hack for ODP.NET array passing...
    IF in_var_expl_ids IS NULL OR (in_var_expl_ids.COUNT = 1 AND in_var_expl_ids(1) IS NULL) THEN
		-- ignore
		null;
	ELSE
		FORALL i IN in_var_expl_ids.FIRST..in_var_expl_ids.LAST
			INSERT INTO sheet_value_var_expl
				(sheet_value_id, var_expl_id)
			VALUES
				(in_sheet_value_id, in_var_expl_ids(i));
	END IF;

    UPDATE sheet_value
	   SET var_expl_note = in_var_expl_note
	 WHERE sheet_value_id = in_sheet_value_id;
END;

-- when we save back, we need to see if we need to
-- recalculate anything - tells you which indicators
-- to recalculate
PROCEDURE GetCalculationsToRecalculate(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
		INTO v_delegation_sid
		FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- can user write to delegation?
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		 SELECT di.ind_sid, s.start_dtm, s.end_dtm, d.period_set_id, d.period_interval_id
		   FROM delegation_ind di, TABLE(calc_pkg.GetAllCalcsUsingIndAsTable(in_ind_sid))t,
			 	sheet s, delegation d
		  WHERE di.delegation_sid = s.delegation_sid
			AND di.ind_sid = t.dep_ind_sid
			AND s.sheet_id = in_sheet_id
			AND d.delegation_sid = s.delegation_sid;
END;

FUNCTION GetSheetIdForSheetValueId(
	in_sheet_value_id				IN	SHEET_VALUE.SHEET_VALUE_ID%TYPE
) RETURN sheet.sheet_id%TYPE
AS
	CURSOR c IS
		SELECT sheet_id
		  FROM sheet_value
		 WHERE sheet_value_id = in_sheet_value_id;
	r c%ROWTYPE;
	v_not_found BOOLEAN;
BEGIN
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN -1; -- NULL breaks DBHelper
	ELSE
		RETURN r.sheet_id;
	END IF;
END;

FUNCTION GetSheetValueId(
	in_sheet_id				IN	SHEET.SHEET_ID%TYPE,
	in_ind_sid				IN	security_pkg.t_sid_id,
	in_region_sid			IN	security_pkg.t_sid_id
) RETURN sheet_value.sheet_value_id%TYPE
AS
	CURSOR c IS
		SELECT sheet_value_id
		  FROM sheet_value
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid
		   AND sheet_id = in_sheet_id;
	r c%ROWTYPE;
	v_not_found BOOLEAN;
BEGIN
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN NULL;
	ELSE
		RETURN r.sheet_value_id;
	END IF;
END;

-- we have to decide whether to use a value submitted to us, or a value in one of our sheets
-- we work this out by assigning (0 if sub deleg, 1 if my deleg) * 4 + state (1,2,3 for red,orange,green)
PROCEDURE GetValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_region_list		IN	VARCHAR2,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_user_Sid		security_pkg.T_SID_ID;
	v_table			T_SPLIT_TABLE;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	v_table := Utils_Pkg.SplitString(in_region_list,',');
	OPEN out_cur FOR
		SELECT sheet_id, sheet_value_id, start_dtm period_start_dtm, end_dtm period_end_dtm, ind_sid, region_sid,
			   val_number, set_dtm changed_dtm, note, sheet_value_id source_id
		  FROM (
			SELECT sla.sheet_id, sv.sheet_value_id, sla.start_dtm, sla.end_dtm, di.ind_sid, dr.region_sid, sv.val_number, sv.set_dtm, sv.note,
			       ROW_NUMBER() OVER (PARTITION BY di.ind_sid,dr.region_sid,sla.start_dtm,sla.end_dtm ORDER BY dl.is_mine * 4 + DECODE(sla.last_action_colour,'G',3,'O',2,'R',1) DESC) SEQ
			  FROM DELEGATION_IND di, DELEGATION_REGION dr, DELEGATION d, SHEET_WITH_LAST_ACTION sla, SHEET_VALUE sv,
					(SELECT delegation_sid, 1 is_mine
					   FROM DELEGATION_USER DU
					  WHERE user_sid = v_user_Sid
					    AND du.inherited_from_sid = du.delegation_sid
					  UNION
					 SELECT delegation_sid, 0 is_mine
					   FROM DELEGATION_DELEGATOR DD
					  WHERE delegator_sid = v_user_sid)dl
			 WHERE di.ind_sid = in_ind_sid
			   AND dr.region_sid IN (SELECT item FROM TABLE(CAST(v_table AS T_SPLIT_TABLE)))
			   AND di.delegation_sid = d.delegation_sid
			   AND dr.delegation_sid = d.delegation_sid
			   AND d.delegation_sid = dl.delegation_sid
			   AND sla.delegation_sid = d.delegation_sid
			   AND sv.sheet_id = sla.sheet_id
			   AND sv.ind_sid = di.ind_sid
			   AND sv.region_sid = dr.region_sid
			   AND sla.end_dtm > in_start_dtm
			   AND sla.start_dtm < in_end_dtm
			)
		 WHERE SEQ = 1
		 ORDER BY region_sid, period_start_dtm, period_end_Dtm desc;
END;

-- we have to decide whether to use a value submitted to us, or a value in one of our sheets
-- we work this out by assigning (0 if sub deleg, 1 if my deleg) * 4 + state (1,2,3 for red,orange,green)
PROCEDURE internal_GetRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE
)
AS
	v_user_Sid		security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	DELETE FROM get_value_result;
	-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
	-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're
	-- processing a lot of data, and don't care too much about note fidelity.
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, ind_sid, region_sid, val_number, changed_dtm, note, flags, is_leaf, is_merged, path)
		SELECT x.period_start_dtm, x.period_end_dtm, 0 source, x.source_id, x.ind_sid, x.region_sid,
			   x.val_number, x.changed_dtm, x.note, NULL, y.is_leaf, x.is_merged, NULL -- this null is for the unused path column (it's used elsewhere)
		  FROM (
			SELECT start_dtm period_start_dtm, end_dtm period_end_dtm, ind_sid, region_sid,
				   val_number, set_dtm changed_dtm, dbms_lob.substr(note, 2000, 1) note, sheet_value_id source_id,
				   0 is_merged
			  FROM (
			   SELECT sla.sheet_id, sv.sheet_value_id, sla.start_dtm, sla.end_dtm, di.ind_sid, dr.region_sid, sv.val_number, sv.set_dtm, sv.note, sla.last_action_colour,
					  ROW_NUMBER() OVER (PARTITION BY di.ind_sid,dr.region_sid,sla.start_dtm,sla.end_dtm ORDER BY dl.is_mine * 4 + DECODE(sla.last_action_colour,'G',3,'O',2,'R',1) DESC) SEQ
				 FROM delegation_ind di, delegation_region dr, delegation d,
				  	  sheet_with_last_action sla, sheet_value sv,
				  	  (SELECT delegation_sid, 1 is_mine
						 FROM delegation_user du
						WHERE user_sid = v_user_Sid
						  AND du.inherited_from_sid = du.delegation_sid
						UNION
					   SELECT delegation_sid, 0 is_mine
						 FROM delegation_delegator dd
						WHERE delegator_sid = v_user_sid) dl
				 WHERE di.ind_sid = in_ind_sid
				   AND dr.region_sid IN (
					     SELECT region_sid
			           	   FROM region
			 			  START WITH region_sid IN (SELECT region_sid FROM region_list)
						CONNECT BY PRIOR region_sid = parent_sid)
				   AND di.delegation_sid = d.delegation_sid
				   AND dr.delegation_sid = d.delegation_sid
				   AND d.delegation_sid = dl.delegation_sid
				   AND sla.delegation_sid = d.delegation_sid
				   AND sv.sheet_id = sla.sheet_id
				   AND sv.ind_sid = di.ind_sid
				   AND sv.region_sid = dr.region_sid
				   AND sla.end_dtm > in_start_dtm
				   AND sla.start_dtm < in_end_dtm
				   AND sla.is_visible = 1
				   -- removed at Tuli's request 28/2
			  	   --AND (last_action_colour !='R' OR dl.is_mine = 1) -- red is ok, so long as it's mine
				)
			 WHERE SEQ = 1
		UNION
			SELECT v.period_start_dtm, v.period_end_dtm, v.ind_sid, v.region_sid,
				   v.val_number, v.changed_dtm, to_char(v.note) note, v.source_id, 1 is_merged
			  FROM val v
	     	 WHERE v.ind_sid = in_ind_sid
               AND v.app_sid = SYS_CONTEXT('SECURITY','APP')
	       	   AND v.period_end_dtm > in_start_dtm
	       	   AND v.period_start_dtm < in_end_dtm
	       	   AND v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
	       	   AND v.region_sid IN (
			  		 SELECT region_sid
					   FROM region
					  START WITH region_sid IN (SELECT region_sid FROM region_list)
					CONNECT BY PRIOR region_sid = parent_sid)
		) x, (
			 SELECT region_sid, CONNECT_BY_ISLEAF is_leaf
		       FROM region
			  START WITH region_sid IN (SELECT region_sid FROM region_list)
			CONNECT BY PRIOR region_sid = parent_sid
		) y
		WHERE x.region_sid = y.region_sid
        ORDER BY x.region_sid, x.period_start_dtm, x.period_end_dtm desc;
END;

PROCEDURE GetRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Populate temp table
	internal_GetRawBaseValues(in_act_id, in_ind_sid, in_start_dtm, in_end_dtm);

	-- Fetch data into output cursor
	OPEN out_cur FOR
		SELECT period_start_dtm, period_end_dtm, ind_sid, region_sid,
			val_number, changed_dtm, note, source_id, is_leaf
		  FROM get_value_result
	  ORDER BY region_sid, period_start_dtm, period_end_dtm DESC;
END;

-- this gets values regardless of whether or not you
-- can see the delegations involved
PROCEDURE internal_GetAnyRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE
)
AS
	v_user_Sid		security_pkg.T_SID_ID;
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	SELECT app_sid
	  INTO v_app_sid
	  FROM IND
	 WHERE ind_sid = in_ind_sid;

	DELETE FROM get_value_result;
	-- we use dbms_lob.substr(note, 2000, 1) to convert to varchar2. We use UTF8 in the database, so if we used 4000, then 4000 characters can easily
	-- exceed the 4096 _byte_ limit of varchar2. We could use something like the csr.TruncateString function to do this accurately but it's slow and we're
	-- processing a lot of data, and don't care too much about note fidelity.
	INSERT INTO get_value_result (period_start_dtm, period_end_dtm, source, source_id, ind_sid, region_sid, val_number, changed_dtm, note, flags, is_leaf, is_merged, path)
		SELECT start_dtm period_start_dtm, end_dtm period_end_dtm, 1 source, sheet_value_id, ind_sid, region_sid,
			val_number, set_dtm changed_dtm, dbms_lob.substr(note, 2000, 1) note, NULL, is_leaf, 0 is_merged, path
		  FROM (
		   SELECT sla.sheet_id, sv.sheet_value_id, sla.start_dtm, sla.end_dtm, di.ind_sid, dr.region_sid, sv.val_number, sv.set_dtm, sv.note, sla.last_action_colour, is_leaf,
		    ROW_NUMBER() OVER (PARTITION BY di.ind_sid,dr.region_sid,sla.start_dtm,sla.end_dtm ORDER BY dl.lvl *  DECODE(sla.last_action_colour,'G',1,'O',100,'R',200) ASC) SEQ,
		    path
			  FROM DELEGATION_IND di, DELEGATION_REGION dr, DELEGATION d,
			  	SHEET_WITH_LAST_ACTION sla, SHEET_VALUE sv,
			  	(
					SELECT delegation_sid, level lvl
			    	  FROM delegation
					 START WITH parent_sid = v_app_sid
				   CONNECT BY PRIOR delegation_sid = parent_sid
				)dl, (
          -- get rid of dupes where region_list contains A,B and C, where B and C are children of A
            SELECT region_sid, path, row_number() over (partition by region_sid order by lvl desc) rn, is_leaf
              FROM (
                SELECT region_sid, sys_connect_by_path(region_sid, '/') path, level lvl, CONNECT_BY_ISLEAF is_leaf
                  FROM region
                START WITH region_sid IN (
                    SELECT region_sid FROM region_list
                  )
              CONNECT BY PRIOR region_sid = parent_sid
            )
			   )rp
			 WHERE di.ind_sid = in_ind_sid
			   AND dr.region_sid = rp.region_sid
         	   AND rp.rn = 1 -- part of getting rid of dupes where region_list contains A,B and C, where B and C are children of A
			   AND di.delegation_sid = d.delegation_sid
			   AND dr.delegation_sid = d.delegation_sid
			   AND d.delegation_sid = dl.delegation_sid
			   AND sla.delegation_sid = d.delegation_sid
			   AND sv.sheet_id = sla.sheet_id
			   AND sv.ind_sid = di.ind_sid
			   AND sv.region_sid = dr.region_sid
			   AND sla.end_dtm > in_start_dtm
			   AND sla.start_dtm < in_end_dtm
			   AND sla.is_visible = 1
			   -- removed at Tuli's request 28/2
		  	   --AND (last_action_colour !='R' OR dl.is_mine = 1) -- red is ok, so long as it's mine
			)
		 WHERE SEQ = 1
		UNION
		SELECT v.period_start_dtm, v.period_end_dtm, 0 source, v.val_id source_id, v.ind_sid, v.region_sid,
          		v.val_number, v.changed_dtm, to_char(v.note) note, NULL, is_leaf, 1 is_merged, path
		  FROM VAL v, (
		  		-- get rid of dupes where region_list contains A,B and C, where B and C are children of A
            SELECT region_sid, path, row_number() over (partition by region_sid order by lvl desc) rn, is_leaf
              FROM (
                SELECT region_sid, sys_connect_by_path(region_sid, '/') path, level lvl, CONNECT_BY_ISLEAF is_leaf
                  FROM region
					   START WITH region_sid IN (SELECT region_sid FROM region_list)
					   CONNECT BY PRIOR region_sid = parent_sid
              )
        )r
     WHERE v.ind_sid = in_ind_sid
       AND v.period_end_dtm > in_start_dtm
       AND v.period_start_dtm < in_end_dtm
       AND v.source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
       AND v.region_sid = r.region_sid
       AND r.rn = 1 -- part of getting rid of dupes where region_list contains A,B and C, where B and C are children of A
	 ORDER BY period_start_dtm, period_end_Dtm desc, path, region_sid;
END;

PROCEDURE GetAnyRawBaseValues(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	-- Populate temp table
	internal_GetAnyRawBaseValues(in_act_id, in_ind_sid, in_start_dtm, in_end_dtm);

	-- Fetch value data into output cursor
	OPEN out_cur FOR
		SELECT period_start_dtm, period_end_dtm, ind_sid, region_sid,
			val_number, changed_dtm, note, source_id, is_leaf
		  FROM get_value_result
		 ORDER BY period_start_dtm, period_end_Dtm DESC, path, region_sid;
END;

-- hack function called from c:\cvs\csr\web\site\sheet\sheetAction.aspx.cs
PROCEDURE UNSECURED_SetAlert(
    in_alert            IN  sheet_value.alert%TYPE,
    in_sheet_value_id   IN  sheet_value.sheet_value_id%TYPE
)
AS
BEGIN
    UPDATE sheet_value SET alert = in_alert WHERE sheet_value_id = in_sheet_value_Id and alert is null;
END;

PROCEDURE GetNoteForSheetValue(
    in_sheet_value_id    IN    sheet_value.sheet_value_Id%TYPE,
    out_cur              OUT   SYS_REFCURSOR
)
AS
    v_delegation_sid    security_pkg.T_SID_ID;
BEGIN
	SELECT d.delegation_Sid
	  INTO v_delegation_sid
	  FROM delegation d, sheet s, sheet_value sv
	 WHERE d.delegation_sid = s.delegation_sid
	   AND s.sheet_id = sv.sheet_Id
	   AND sheet_value_id = in_sheet_value_id;

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT note
		  FROM sheet_value
		 WHERE sheet_value_id = in_sheet_value_id;
END;

-- once we've got the new page in place it might be worth trying to tidy this stuff up.
-- i.e. ideally this ought to be returned when you call setValue? It's not doing a security
-- check ATM because it could get called repeatedly and in the C# it's only called after
-- setting a value, although there's obviously a risk that someone reads this, and decides
-- to reuse the SP in an insecure way! (hence UNSEC prefix, i.e. this is unsecured)
PROCEDURE UNSEC_GetIndsToRecalculate(
	in_delegation_sid				IN		sheet.delegation_sid%TYPE,
	in_ind_sids						IN		security_pkg.T_SID_IDS,
	out_cur							OUT		SYS_REFCURSOR
)
AS
	v_ind_sids						security.T_SID_TABLE;
BEGIN
	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);

	-- an INTERSECT might be quicker?
	OPEN out_cur FOR
        SELECT di.ind_sid
          FROM delegation_ind di, (
				SELECT DISTINCT calc_ind_sid dep_ind_sid
				  FROM v$calc_dependency
					   START WITH ind_sid IN (SELECT column_value FROM TABLE(v_ind_sids))
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR calc_ind_sid = ind_sid) dep
         WHERE di.delegation_sid = in_delegation_Sid
           AND di.ind_sid = dep.dep_ind_sid;
END;

FUNCTION GetSheetQueryString(
    in_ind_sid						IN	security_pkg.T_SID_ID,
    in_region_sid					IN	security_pkg.T_SID_ID,
    in_start_dtm					IN	sheet.start_dtm%TYPE,
    in_end_dtm						IN	sheet.end_dtm%TYPE,
    in_user_sid 					IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
	RETURN GetSheetQueryString(SYS_CONTEXT('SECURITY', 'APP'), in_ind_sid, in_region_sid, in_start_dtm, in_end_dtm, in_user_sid);
END;

-- This mirrors a similar function in pending_pkg
FUNCTION GetSheetQueryString(
	in_app_sid						IN	customer.app_sid%TYPE,
    in_ind_sid						IN	security_pkg.T_SID_ID,
    in_region_sid					IN	security_pkg.T_SID_ID,
    in_start_dtm					IN	sheet.start_dtm%TYPE,
    in_end_dtm						IN	sheet.end_dtm%TYPE,
    in_user_sid 					IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
    v_url   VARCHAR2(255);
BEGIN
    BEGIN
	  SELECT 'sheetId='||sheet_id url
		INTO v_url
		  FROM (
			SELECT s.sheet_id, row_number() OVER (ORDER BY user_sid, sheet_id) rn -- prioritise where there's a matched user, after that pick arbitrarily if > 1 match
			  FROM delegation d, delegation_ind di, delegation_region dr,
				   sheet s, v$delegation_user du
			 WHERE di.app_sid = in_app_sid AND di.ind_sid = in_ind_sid -- this is called without being logged on (by the issues alert batch)
			   AND dr.app_sid = in_app_sid AND dr.region_sid = in_region_sid
			   AND di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
			   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.delegation_sid
			   AND d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
			   AND in_start_dtm < s.end_dtm -- within the period of the sheet
			   AND in_end_dtm > s.start_dtm
			   AND d.app_sid = du.app_sid(+) AND d.delegation_sid = du.delegation_sid(+)
			   AND du.user_sid(+) = in_user_sid
		 ) WHERE rn = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    RETURN v_url;
END;

-- internal, copies a range of values from the main system to the given sheet between the given dates
-- used by CopyForward and CopyCurrent
PROCEDURE CopyValues(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE,
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cnt							OUT	NUMBER
)
AS
	v_sheet_value_id				sheet_value.sheet_value_id%TYPE;
	v_file_count					NUMBER;
BEGIN
	out_cnt := 0;

	-- NB -- uses val_converted and sheet_value_converted in case the customer is using
	-- percentage ownership
	FOR r IN (SELECT v.val_id, v.ind_sid, v.region_sid, v.val_number, v.entry_val_number,
					 v.entry_measure_conversion_id, v.note, DECODE(v.flags, 0, NULL, v.flags) flag
				FROM val_converted v, delegation_ind di, delegation_region dr, sheet_value_converted sv, ind i
			   WHERE di.delegation_sid = in_delegation_sid
			     AND dr.delegation_sid = in_delegation_sid
			     AND di.app_sid = v.app_sid AND di.ind_sid = v.ind_sid
			     AND dr.app_sid = v.app_sid AND dr.region_sid = v.region_sid
			     AND di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid
			     AND v.period_start_dtm = in_start_dtm
			     AND v.period_end_dtm = in_end_dtm
			     AND in_sheet_id = sv.sheet_id(+)
			     AND v.app_sid = sv.app_sid(+)
			     AND v.ind_sid = sv.ind_sid(+)
			     AND v.region_sid = sv.region_sid(+)
				 -- don't copy read-only (Requested by Ali - seems sane)
			     AND di.visibility != 'READONLY'
				 -- copy values or just notes (ie. when value not set but note exists)
				 AND (v.val_number IS NOT NULL OR (v.val_number IS NULL AND v.note IS NOT NULL))
				 -- don't copy forward inactive region values
				 AND (dr.hide_after_dtm IS NULL OR (dr.hide_inclusive = 1 AND sv.end_dtm < dr.hide_after_dtm) OR (dr.hide_inclusive = 0 AND dr.hide_after_dtm > sv.start_dtm))
			     -- only fill in missing sheet values (ie. don't set value if there is note already in the sheet)
				 AND (sv.val_number IS NULL AND sv.note IS NULL)
				 -- only fill in missing sheet values (checking if any of the selection group inds have value set)
				 AND (v.ind_sid, v.region_sid) NOT IN (
					  SELECT isgm.ind_sid, f.region_sid
						FROM ind_selection_group_member isgm, (
							SELECT isgm.master_ind_sid, sv.region_sid
							  FROM sheet_value sv, ind_selection_group_member isgm, delegation_ind di, delegation_region dr
							 WHERE isgm.ind_sid = di.ind_sid
							   AND (sv.val_number IS NOT NULL OR (sv.val_number IS NULL AND sv.note IS NOT NULL))
							   AND sv.ind_sid = di.ind_sid
							   AND sv.region_sid = dr.region_sid
							   AND sv.sheet_id = in_sheet_id
							   AND di.delegation_sid = in_delegation_sid
							   AND dr.delegation_sid = in_delegation_sid
							 GROUP BY isgm.master_ind_sid, sv.region_sid) f
					   WHERE isgm.master_ind_sid = f.master_ind_sid
				  )) LOOP

		SELECT COUNT(*)
		  INTO v_file_count
		  FROM val_file
		 WHERE val_id = r.val_id;

		delegation_pkg.SaveValue(
			in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
			in_sheet_id				=> in_sheet_id,
			in_ind_sid				=> r.ind_sid,
			in_region_sid			=> r.region_sid,
			in_val_number			=> r.val_number,
			in_entry_conversion_id	=> r.entry_measure_conversion_id,
			in_entry_val_number		=> r.entry_val_number,
			in_note					=> r.note,
			in_reason				=> 'Copied forward',
			in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
			in_file_count			=> v_file_count,
			in_flag					=> r.flag,
			in_write_history		=> 1,
			out_val_id				=> v_sheet_value_id);

		INSERT INTO sheet_value_file (sheet_value_id, file_upload_sid)
			SELECT v_sheet_value_id, file_upload_sid
			  FROM val_file
		 	 WHERE val_id = r.val_id;

		out_cnt := out_cnt + 1;
	END LOOP;
END;

PROCEDURE CopyForward(
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	out_cnt							OUT	NUMBER
)                       			
AS                      			
	v_sheet							T_SHEET_INFO;
	v_prev_start_dtm				DATE;
	v_prev_end_dtm					DATE;
	v_copy_na						NUMBER;
	v_chem_cnt						NUMBER;
	v_sheet_value_id				NUMBER;
BEGIN
	-- must be able to write to the sheet
	v_sheet := GetSheetInfo(SYS_CONTEXT('SECURITY', 'ACT'), in_sheet_id);
	IF v_sheet.can_save = 0 THEN
		-- this person can't write to the sheet in this state
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_ALLOWED_WRITE, 'You are not allowed to write to sheet ' || in_sheet_id);
	END IF;

	-- Prevent copying forward multiple times
	IF v_sheet.can_copy_forward = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot copy forward sheet ' || in_sheet_id);
	END IF;

	-- figure out the end date based on the interval
	v_prev_start_dtm := period_pkg.AddIntervals(v_sheet.period_set_id, v_sheet.period_interval_id, v_sheet.start_dtm, -1);
	v_prev_end_dtm := period_pkg.AddIntervals(v_sheet.period_set_id, v_sheet.period_interval_id, v_sheet.end_dtm, -1);

	CopyValues(v_sheet.delegation_sid, in_sheet_id, v_prev_start_dtm, v_prev_end_dtm, out_cnt);

	/* Horrible hack for ABI, see case FB82440. They want to copy the "allow n/a" setting. Copy forward actually uses
	   merged, eg val, not sheet_value, and allow_na only exists in sheets. So, we need to try and find a previous
	   sheet for the period and copy the setting from there. Makes no real sense; it's not copying the values from
	   there, just this setting, but... Read the case if you care!
	*/
	SELECT copy_forward_allow_na
	  INTO v_copy_na
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	IF v_copy_na > 0 THEN
		FOR r IN (
			SELECT v.ind_sid, v.region_sid, sv.is_na, sv.note
			  FROM (
					SELECT MAX(sv.sheet_id) sheet_id, sv.ind_sid, sv.region_sid
					  FROM sheet_value sv
					  JOIN sheet s ON s.sheet_id = sv.sheet_id
					 WHERE ind_sid IN (
						SELECT ind_sid 
						  FROM delegation_ind di
						  JOIN sheet s ON di.delegation_sid = s.delegation_sid
						 WHERE s.sheet_id = in_sheet_id
						   AND di.allowed_na = 1
						)
					   AND region_sid IN (
						SELECT region_sid
						  FROM delegation_region dr
						  JOIN sheet s ON dr.delegation_sid = s.delegation_sid
						 WHERE s.sheet_id = in_sheet_id
						)
					   AND start_dtm = v_prev_start_dtm
					   AND end_dtm = v_prev_end_dtm
					 GROUP BY sv.region_sid, sv.ind_sid
				) v
			  JOIN sheet_value sv 	ON sv.ind_sid = v.ind_sid 
									AND sv.region_sid = v.region_sid 
									AND sv.sheet_id = v.sheet_id
			 WHERE sv.is_na = 1
		)
		LOOP
			delegation_pkg.SaveValue(
				in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_sheet_id				=> in_sheet_id,
				in_ind_sid				=> r.ind_sid,
				in_region_sid			=> r.region_sid,
				in_val_number			=> null,
				in_entry_conversion_id	=> null,
				in_entry_val_number		=> null,
				in_note					=> r.note,
				in_reason				=> 'Copied forward',
				in_status				=> csr_data_pkg.SHEET_VALUE_ENTERED,
				in_file_count			=> 0,
				in_flag					=> NULL,
				in_write_history		=> 1,
				in_is_na 				=> 1,
				out_val_id				=> v_sheet_value_id);
		END LOOP;
	
	END IF;
	  
	-- prod chem (in separate package to reduce dependencies and stop RK screwing up live)
	chem.substance_helper_pkg.UNSEC_CopyForward(in_sheet_id, v_chem_cnt);
	out_cnt := out_cnt + v_chem_cnt;
END;

/**
 * Mark a sheet as "copied forward". This will prevent future attempts 
 * to copy forward.
 *
 * @param in_sheet_id		The sheet to mark 
 */
PROCEDURE MarkAsCopiedForward(
	in_sheet_id				IN	sheet.sheet_id%TYPE
)
AS
BEGIN
    CheckSheetAccessAllowed(in_sheet_id, delegation_pkg.DELEG_PERMISSION_WRITE); 

	UPDATE csr.sheet
	   SET is_copied_forward = 1
	 WHERE sheet_id = in_sheet_id;
END;

PROCEDURE CopyCurrent(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_cnt					OUT	NUMBER
)
AS
	v_sheet				T_SHEET_INFO;
BEGIN
	-- must be able to write to the sheet
	v_sheet := GetSheetInfo(SYS_CONTEXT('SECURITY', 'ACT'), in_sheet_id);
	IF v_sheet.can_save = 0 THEN
		-- this person can't write to the sheet in this state
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_ALLOWED_WRITE, 'You are not allowed to write to sheet ' || in_sheet_id);
	END IF;

	CopyValues(v_sheet.delegation_sid, in_sheet_id, v_sheet.start_dtm, v_sheet.end_dtm, out_cnt);
END;

PROCEDURE GetGridsToClone(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_Sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

	OPEN out_cur FOR
		SELECT dg.path, dg.form_sid, delegation_pkg.getRootDelegationSid(s.delegation_sid) root_delegation_sid,
			   dg.ind_sid, s.start_dtm, s.end_dtm, dr.region_sid, d.period_set_id, d.period_interval_id
		  FROM sheet s
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  JOIN delegation_region dr ON d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
		  JOIN delegation_ind di ON d.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
		  JOIN delegation_grid dg ON di.app_sid = dg.app_sid AND di.ind_sid = dg.ind_sid
		 WHERE s.sheet_id = in_sheet_id;
END;

PROCEDURE SetPostIt(
	in_sheet_Id		IN	sheet.sheet_id%TYPE,
	in_postit_id	IN	postit.postit_id%TYPE,
	out_postit_id	OUT postit.postit_id%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;
	
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;
	
	postit_pkg.UNSEC_Save(in_postit_id, null, 'message', v_delegation_sid, out_postit_id);

	BEGIN
		INSERT INTO delegation_comment (delegation_sid, start_dtm, end_dtm, postit_id)
			SELECT delegation_sid, start_dtm, end_dtm, out_postit_id
			  FROM sheet
			 WHERE sheet_Id = in_sheet_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;

PROCEDURE GetPostIts(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR,
	out_cur_files	OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
	v_start_dtm			sheet.start_dtm%TYPE;
	v_end_dtm			sheet.end_dtm%TYPE;
BEGIN
	SELECT start_dtm, end_dtm, delegation_sid
	  INTO v_start_dtm, v_end_dtm, v_delegation_sid
	  FROM sheet
	 WHERE sheet_id = in_sheet_Id;

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
    END IF;

    OPEN out_cur FOR
		SELECT dc.delegation_sid, dc.start_dtm, dc.end_dtm, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid,
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM delegation_comment dc
		  JOIN v$postit p ON dc.postit_id = p.postit_id AND dc.app_sid = p.app_sid
		 WHERE delegation_sid IN (
			  SELECT delegation_Sid
			    FROM delegation
			   START WITH delegation_sid = v_delegation_Sid
			 CONNECT BY PRIOR delegation_sid = parent_sid
		   )
		   AND dc.start_dtm >=v_start_dtm
		   AND dc.end_dtm <= v_end_dtm
		 ORDER BY created_dtm;

	OPEN out_cur_files FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM delegation_comment dc
		  JOIN postit p ON dc.postit_id = p.postit_id AND dc.app_sid = p.app_sid
		  JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE delegation_sid IN (
			 SELECT delegation_Sid
			   FROM delegation
			  START WITH delegation_sid = v_delegation_Sid
			CONNECT BY PRIOR delegation_sid = parent_sid
		   )
		   AND dc.start_dtm >= v_start_dtm
		   AND dc.end_dtm <= v_end_dtm;
END;

PROCEDURE RaiseNewSheetAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	-- You manually sub-delegate a form and choose to notify users by clicking 'Yes - send e-mails'
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_DELEGATION) THEN
		RETURN;
	END IF;
	
	INSERT INTO new_delegation_alert (new_delegation_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
		 SELECT new_delegation_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), in_sheet_id
		   FROM sheet s
		   JOIN v$delegation_user du ON s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
		   JOIN customer_alert_type cat ON cat.app_sid = s.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_NEW_DELEGATION
		   JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		  WHERE s.sheet_id = in_sheet_id;
END;

PROCEDURE RaiseSheetChangeAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE,
	in_alert_to						IN	NUMBER
)
AS
BEGIN
	IF (in_alert_to = csr_data_pkg.ALERT_TO_NONE
		OR (NOT (alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SHEET_CHANGED)
			OR alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED)
			OR alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SHEET_RETURNED))
		)
	) THEN
		RETURN;
	END IF;
		-- Remove the old alerts for the sheet
	DELETE FROM delegation_change_alert
	 WHERE sheet_id = in_sheet_id;
	
	DELETE FROM new_delegation_alert
	 WHERE sheet_id = in_sheet_id
	   AND notify_user_sid = SYS_CONTEXT('SECURITY', 'SID');
	
	-- Add the new alerts
	INSERT INTO delegation_change_alert (delegation_change_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
		 SELECT deleg_change_alert_id_seq.nextval, u.user_sid, SYS_CONTEXT('SECURITY', 'SID'), in_sheet_id
		   FROM (
				SELECT du.user_sid, du.app_sid
				  FROM sheet s, v$delegation_user du
				 WHERE sheet_id = in_sheet_id
				   AND s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
				   AND in_alert_to = csr_data_pkg.ALERT_TO_DELEGEE
				 UNION
				SELECT dd.delegator_sid, dd.app_sid
				  FROM sheet s, delegation_delegator dd
				 WHERE sheet_id = in_sheet_id
				   AND s.app_sid = dd.app_sid AND s.delegation_sid = dd.delegation_sid
				   AND in_alert_to = csr_data_pkg.ALERT_TO_DELEGATOR
			)u
				JOIN customer_alert_type cat ON u.app_sid = cat.app_sid AND cat.std_alert_type_id IN (csr_data_pkg.ALERT_SHEET_CHANGED, csr_data_pkg.ALERT_SHEET_CHANGE_BATCHED)
				JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		  WHERE u.user_sid != SYS_CONTEXT('SECURITY', 'SID');
END;

PROCEDURE RaiseSheetEditedAlert(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_user_sid 		IN	security_pkg.T_SID_ID
)
AS
	v_sheet_action_id		sheet_history.sheet_action_id%TYPE;
	v_delegation_sid		sheet.delegation_sid%TYPE;
	v_action_dtm			DATE;
	v_edited_value_count	NUMBER(10);
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SHEET_EDITED) THEN
		RETURN;
	END IF;
	
	--Double check the status
	SELECT sheet_action_id, action_dtm
	  INTO v_sheet_action_id, v_action_dtm
	  FROM sheet_history 
	 WHERE sheet_history_id = 
		(SELECT last_sheet_history_id 
		   FROM sheet 
		  WHERE sheet_id = in_sheet_id
		);   
	
	IF v_sheet_action_id = csr_data_pkg.ACTION_SUBMITTED_WITH_MOD THEN
		SELECT COUNT(sheet_value_id)
		  INTO v_edited_value_count
		  FROM sheet_value
		 WHERE sheet_id = in_sheet_id
		   AND set_dtm >= v_action_dtm;
		
		IF v_edited_value_count > 0 THEN
			--Get the delegation sid
			SELECT delegation_sid
			  INTO v_delegation_sid
			  FROM sheet
			 WHERE sheet_id = in_sheet_id;
			
			--We have some edited values, so let's loop over the involved users and add an entry for them
			FOR r IN (SELECT d.DELEGATION_SID, du.USER_SID, cu.FULL_NAME
						FROM delegation_user du
						JOIN delegation d ON d.DELEGATION_SID = du.DELEGATION_SID 
										  OR d.PARENT_SID = du.DELEGATION_SID
						JOIN csr_user cu  ON du.USER_SID = cu.CSR_USER_SID
					   WHERE d.DELEGATION_SID = v_delegation_sid
					     AND du.inherited_from_sid = du.delegation_sid)	LOOP
			
				INSERT INTO delegation_edited_alert 
					(delegation_edit_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
				VALUES 
					(deleg_edit_alert_id_seq.nextval, r.user_sid, in_user_sid, in_sheet_id);
			END LOOP;
		END IF;
	END IF;
END;

PROCEDURE RaiseSheetDataChangeAlert(
	in_sheet_id			IN	sheet.sheet_id%TYPE
)
AS
	v_user_in_deleg		NUMBER(10);
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_SUBMITTED_VAL_CHANGED) THEN
		RETURN;
	END IF;

	-- CHECK USER NOT IN DELEGATION
	SELECT COUNT(du.user_sid) INTO v_user_in_deleg
	  FROM delegation_user du
	  JOIN sheet s ON du.delegation_sid = s.delegation_sid AND du.inherited_from_sid = du.delegation_sid
	 WHERE sheet_id = in_sheet_id
	   AND du.user_sid = SYS_CONTEXT('SECURITY', 'SID');

	IF v_user_in_deleg = 0 THEN
		-- Only raise one alert per person per sheet
		INSERT INTO deleg_data_change_alert (deleg_data_change_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
			 SELECT deleg_data_change_alert_id_seq.NEXTVAL, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), s.sheet_id
			   FROM delegation_user du
			   JOIN sheet s ON du.delegation_sid = s.delegation_sid AND s.sheet_id = in_sheet_id
			   LEFT JOIN deleg_data_change_alert ddc
				 ON s.sheet_id = ddc.sheet_id
				AND du.user_sid = ddc.notify_user_sid
				AND ddc.raised_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
			  WHERE ddc.sheet_id IS NULL
			    AND ddc.notify_user_sid IS NULL
			    AND ddc.raised_by_user_sid IS NULL
				AND du.inherited_from_sid = du.delegation_sid;
	END IF;
END;

PROCEDURE RaiseSheetDataChangeAlerts(
	in_sheet_ids					IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	FOR i IN in_sheet_ids.FIRST .. in_sheet_ids.LAST LOOP
		RaiseSheetDataChangeAlert(in_sheet_ids(i));
	END LOOP;
END;

PROCEDURE RaisePlanSheetUpdatedAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG) THEN
		RETURN;
	END IF;
	
	INSERT INTO updated_planned_deleg_alert (updated_planned_deleg_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
		 SELECT updated_plandeleg_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), in_sheet_id
		   FROM sheet s
		   JOIN v$delegation_user du ON s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
		   JOIN customer_alert_type cat ON cat.app_sid = s.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_UPDATED_PLANNED_DELEG
		   JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		  WHERE s.sheet_id = in_sheet_id;
END;

PROCEDURE RaisePlanSheetNewAlert(
	in_sheet_id						IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	IF NOT alert_pkg.IsAlertEnabled(csr_data_pkg.ALERT_NEW_PLANNED_DELEG) THEN
		RETURN;
	END IF;

	INSERT INTO new_planned_deleg_alert (new_planned_deleg_alert_id, notify_user_sid, raised_by_user_sid, sheet_id)
		 SELECT new_plandeleg_alert_id_seq.nextval, du.user_sid, SYS_CONTEXT('SECURITY', 'SID'), in_sheet_id
		   FROM sheet s
		   JOIN v$delegation_user du ON s.app_sid = du.app_sid AND s.delegation_sid = du.delegation_sid
		   JOIN customer_alert_type cat ON cat.app_sid = s.app_sid AND cat.std_alert_type_id = csr_data_pkg.ALERT_NEW_PLANNED_DELEG
		   JOIN alert_template at ON cat.app_sid = at.app_sid AND cat.customer_alert_type_id = at.customer_alert_type_id
		  WHERE s.sheet_id = in_sheet_id;
END;

PROCEDURE GetChangeRequests(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckSheetAccessAllowed(in_sheet_id);

	OPEN out_cur FOR
		SELECT sheet_change_req_id, req_to_change_sheet_id, raised_dtm, 
			delegation_pkg.SQL_CheckDelegationPermission(security.security_pkg.getACT, s.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) is_active_sheet_user,
			cu.full_name, cu.user_name, cu.csr_user_sid user_sid, cu.csr_user_sid, cu.email, raised_note  
		  FROM sheet_change_req scr
		  JOIN csr_user cu ON scr.raised_by_sid = cu.csr_user_sid
		  JOIN sheet s ON scr.active_sheet_id = s.sheet_id
		 WHERE (active_sheet_id = in_sheet_id OR req_to_change_sheet_id = in_sheet_id)
		   AND processed_dtm IS null;
END;

PROCEDURE GetChangedValuesSinceReSub(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_last_return	DATE;
	v_last_resub	DATE;
BEGIN
	-- We're looking to build a window of values to highlight. This is any values which have changed since the sheet
	-- was returned, but before the most recent submit with mode.
	BEGIN
		SELECT MAX(action_dtm) 
		  INTO v_last_return
		  FROM sheet_history 
		 WHERE sheet_id = in_sheet_id
		   AND sheet_action_id = csr_data_pkg.ACTION_RETURNED;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
			v_last_return := SYSDATE + 1;
	END;
	
	BEGIN
		SELECT MAX(action_dtm)
		  INTO v_last_resub
		  FROM sheet_history 
		 WHERE sheet_id = in_sheet_id
		   AND sheet_action_id = csr_data_pkg.ACTION_SUBMITTED_WITH_MOD;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
			v_last_resub := SYSDATE + 1;
	END;
	
	-- If the sheet has never been returned, there's nothing to find. We set the times to the future so that the query still
	-- runs - it just won't find anything.
	IF v_last_return IS NULL THEN
		v_last_return := SYSDATE + 1;
		v_last_resub := SYSDATE + 1;
	END IF;
	
	-- If the last resub was before the last return, we want to pick up all values since the return. So, we set it to the
	-- future. Same if the sheet has never been resubbed.
	IF v_last_resub IS NULL OR v_last_resub < v_last_return THEN
		v_last_resub := SYSDATE + 1;
	END IF;
	
	-- Do the select; so we're looking for values which have occured between the return and the resub.
	OPEN out_cur FOR
		SELECT DISTINCT sv.ind_sid, sv.region_sid
		  FROM sheet_value sv
		  JOIN sheet_value_change svc on sv.sheet_value_id = svc.sheet_value_id and sv.app_sid = svc.app_sid
		 WHERE sheet_id = in_sheet_id
		   AND changed_dtm >= v_last_return
		   AND changed_dtm < v_last_resub
		   AND sv.is_inherited = 0; -- We want to exclude from the list values propagated from child sheets.
END;

PROCEDURE GetEditedValuesSinceSub(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_last_sub		DATE;
	v_last_return	DATE;
BEGIN
	-- We're looking to build a window of values to highlight. This is any values which have changed after a submission. ie, where
	-- an approver has used "make editable" and then edited the values. This expires if we hit a return, as it means the approver has 
	-- returned the form to the submitter, and thus further edits are by the submitter.

	-- Get the last submit
	BEGIN
		SELECT MAX(action_dtm)
		  INTO v_last_sub
		  FROM sheet_history 
		 WHERE SHEET_ID = in_sheet_id
		   AND sheet_action_id IN (csr_data_pkg.ACTION_SUBMITTED, csr_data_pkg.ACTION_SUBMITTED_WITH_MOD);
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
			v_last_sub := SYSDATE + 1;
	END;
	
	BEGIN
		SELECT MAX(action_dtm) 
		  INTO v_last_return
		  FROM sheet_history 
		 WHERE SHEET_ID = in_sheet_id
		   AND sheet_action_id = csr_data_pkg.ACTION_RETURNED;
	EXCEPTION
		 WHEN NO_DATA_FOUND THEN
			v_last_return := SYSDATE + 1;
	END;
	
	-- If the sheet has never been submitted, there's nothing to find. We set the times to the future so that the query still
	-- runs - it just won't find anything.
	IF v_last_sub IS NULL THEN
		v_last_sub 		:= SYSDATE + 1;
		v_last_return 	:= SYSDATE + 1;
	END IF;
	
	-- If the last return was before the last submission, we want to pick up all values since that submission. As such, we set the return time
	-- to the future. Same as if it has never been returned.
	IF v_last_return IS NULL OR v_last_return < v_last_sub THEN
		v_last_return 	:= SYSDATE + 1;
	END IF;
	
	-- Do the select; so we're looking for values which have occured between the submission and the return
	OPEN out_cur FOR
		SELECT DISTINCT sv.ind_sid, sv.region_sid 
		  FROM sheet_value sv
		  JOIN sheet_value_change svc on sv.sheet_value_id = svc.sheet_value_id and sv.app_sid = svc.app_sid
		 WHERE sheet_id = in_sheet_id
		   AND changed_dtm > v_last_sub
		   AND changed_dtm < v_last_return;
END;

PROCEDURE GetValueChanges(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_order_dir	IN	NUMBER,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	CheckSheetAccessAllowed(in_sheet_id);

	OPEN out_cur FOR
		SELECT sheet_value_change_id, cu.csr_user_sid, cu.full_name, cu.email, cu.user_name,
			   svc.changed_dtm,
			   svc.entry_val_number, svc.entry_measure_conversion_id,
			   NVL(mc.description, m.description) measure,
			   svc.note, svc.flag, svc.reason, i.ind_sid
		  FROM sheet_value_change svc
		  JOIN sheet_value sv on svc.sheet_value_id = sv.sheet_value_id and svc.app_sid = sv.app_sid
		  JOIN csr_user cu on svc.changed_by_sid = cu.csr_user_sid and svc.app_sid = cu.app_sid
		  JOIN ind i on sv.ind_sid = i.ind_sid and sv.app_sid = i.app_sid
		  JOIN measure m on i.measure_sid = m.measure_sid and i.app_sid = m.app_sid
		  LEFT JOIN measure_conversion mc on svc.entry_measure_conversion_id = mc.measure_conversion_id and sv.app_sid = mc.app_sid
		 WHERE sv.sheet_id = in_sheet_id
		   AND sv.region_sid = in_region_sid
		   AND (sv.ind_sid = in_ind_sid OR sv.ind_sid IN (
			SELECT ind_sid
			  FROM ind_selection_group_member
			 WHERE master_ind_sid = in_ind_sid
		   ))
		 ORDER BY CASE WHEN in_order_dir = -1 THEN svc.changed_dtm END DESC,
				  CASE WHEN in_order_dir = 1 THEN svc.changed_dtm END ASC;
END;

/**
* Return if an indicator is used in a Sheet Value
* Used in indicator_pkg.IsIndicatorUsed
*/
FUNCTION IsIndicatorUsed(
	in_ind_sid	IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
BEGIN
	 FOR x IN (SELECT COUNT(*) found
	             FROM dual
				WHERE EXISTS(SELECT 1
				               FROM sheet_value
							  WHERE ind_sid = in_ind_sid)
				)
	LOOP
		 RETURN x.found = 1;
	 END LOOP;
END;

PROCEDURE GetSheetExportValues(
	in_start_dtm					IN	sheet.start_dtm%TYPE,
	in_end_dtm						IN	sheet.end_dtm%TYPE,
	in_all_values					IN	NUMBER,
	in_values_with_notes			IN	NUMBER,
	in_values_with_files			IN	NUMBER,
	in_values_with_var_expl			IN	NUMBER,
	out_val_cur						OUT	SYS_REFCURSOR,
	out_file_cur					OUT	SYS_REFCURSOR,
	out_var_expl_cur				OUT	SYS_REFCURSOR
)
AS
	v_sql							VARCHAR2(4000);
	v_use_regions					NUMBER;
	v_use_inds						NUMBER;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Run sheet export report') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Run sheet export report" capability');
	END IF;

	-- zero rows in temp ind/region tables means use all inds/regions
	SELECT COUNT(*)
	  INTO v_use_regions
	  FROM dual
	 WHERE EXISTS (SELECT 1
	 				 FROM region_list);

	SELECT COUNT(*)
	  INTO v_use_inds
	  FROM dual
	 WHERE EXISTS (SELECT 1
	 				 FROM ind_list);

	-- figure out a set of sheets to use by applying the arcane sheet selection criteria logic
	DELETE FROM temp_sheets_to_use;
	INSERT INTO temp_sheets_to_use (app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour)
		SELECT app_sid, delegation_sid, lvl, sheet_id, start_dtm, end_dtm, last_action_colour
		  FROM (SELECT d.app_sid, d.delegation_sid, d.lvl, sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.last_action_colour,
					    ROW_NUMBER() OVER (PARTITION BY d.root_delegation_sid, sla.start_dtm, sla.end_dtm ORDER BY d.lvl * DECODE(sla.last_action_colour,'G',1,'O',100,'R',200) ASC) SEQ
				  FROM (SELECT app_sid, delegation_sid, connect_by_root delegation_sid root_delegation_sid, level lvl
						  FROM delegation
							   START WITH app_sid = SYS_CONTEXT('SECURITY','APP') AND parent_sid = SYS_CONTEXT('SECURITY','APP')
							   	 	  AND (v_use_regions = 0 OR delegation_sid IN (SELECT dr.delegation_sid FROM delegation_region dr WHERE dr.region_sid IN (SELECT region_sid FROM region_list)))
							   	 	  AND (v_use_inds = 0 OR delegation_sid IN (SELECT dr.delegation_sid FROM delegation_ind dr WHERE dr.ind_sid IN (SELECT ind_sid FROM ind_list)))
							   CONNECT BY app_sid = SYS_CONTEXT('SECURITY','APP') AND PRIOR delegation_sid = parent_sid) d,
					   sheet_with_last_action sla
				 WHERE sla.app_sid = d.app_sid AND sla.delegation_sid = d.delegation_sid
				   AND sla.is_visible = 1
				   AND (in_start_dtm IS NULL OR sla.end_dtm > in_start_dtm)
				   AND (in_end_dtm IS NULL OR sla.start_dtm < in_end_dtm))
		  WHERE seq = 1;

	-- return any sheet values from selected sheets matching the given criteria
	v_sql := 'INSERT INTO temp_val_id (app_sid, val_id) '||
				 'SELECT sv.app_sid, sv.sheet_value_id '||
				   'FROM temp_sheets_to_use ts '||
				   'JOIN sheet_value sv ON ts.sheet_id = sv.sheet_id '||
		 		  'WHERE (:1 = 0 OR sv.region_sid IN (SELECT region_sid FROM region_list)) '||
		   			'AND (:2 = 0 OR sv.ind_sid IN (SELECT ind_sid FROM ind_list))';

	IF in_all_values = 0 THEN
		v_sql := v_sql || ' AND (1 = 0';

		IF in_values_with_notes = 1 THEN
			v_sql := v_sql || ' OR LENGTH(sv.note) > 0';
		END IF;

		IF in_values_with_files = 1 THEN
			v_sql := v_sql || ' OR EXISTS (SELECT 1 FROM sheet_value_file svf WHERE sv.app_sid = svf.app_sid AND sv.sheet_value_id = svf.sheet_value_id)';
		END IF;

		IF in_values_with_var_expl = 1 THEN
			v_sql := v_sql || ' OR LENGTH(sv.var_expl_note) > 0 ' ||
				'OR EXISTS (SELECT 1 FROM sheet_value_var_expl svve WHERE sv.app_sid = svve.app_sid AND sv.sheet_value_id = svve.sheet_value_id)';
		END IF;

		v_sql := v_sql || ')';
	END IF;

	BEGIN
		EXECUTE IMMEDIATE v_sql
		USING v_use_regions, v_use_inds;
	EXCEPTION
		WHEN OTHERS THEN
			RAISE_APPLICATION_ERROR(-20001, SQLERRM||' executing '||v_sql);
	END;

	OPEN out_val_cur FOR
		SELECT sv.sheet_value_id, d.editing_url||'sheetvalueid='||sv.sheet_value_id value_link, s.start_dtm, s.end_dtm,
			   sv.sheet_id, d.editing_url||'sheetid='||sv.sheet_id sheet_link, d.delegation_sid, d.name delegation_name,
			   d.start_dtm delegation_start_dtm, d.end_dtm delegation_end_dtm, d.period_set_id, d.period_interval_id,
			   sv.set_by_user_sid, cu.email set_by_email, cu.full_name set_by_full_name, sv.set_dtm,
			   sv.ind_sid, i.description ind_description, i.ind_type, sv.region_sid, r.description region_description, r.region_ref region_ref,
		 	   sv.val_number, sv.entry_val_number, sv.entry_measure_conversion_id, NVL(mc.description, m.description) entry_measure_desc,
		 	   sv.note, sv.var_expl_note,
			   CASE WHEN i.tolerance_type != 0 AND (sv.val_number > x.val_number * i.PCT_UPPER_TOLERANCE OR sv.val_number < x.val_number * i.PCT_LOWER_TOLERANCE) THEN 1 ELSE 0 END var_expl,
			   CASE WHEN i.tolerance_type != 0 AND x.val_number != 0 THEN round((sv.val_number * 10000 / x.val_number) - 10000) / 10000 ELSE NULL END var_expl_val			   
		  FROM temp_val_id tv
		  JOIN sheet_value sv ON tv.app_sid = sv.app_sid AND tv.val_id = sv.sheet_value_id
		  JOIN sheet s ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id
		  JOIN delegation d ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  JOIN v$ind i ON sv.app_sid = i.app_sid AND sv.ind_sid = i.ind_sid
		  JOIN v$region r ON sv.app_sid = r.app_sid AND sv.region_sid = r.region_sid
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND i.measure_sid = m.measure_sid
		  LEFT JOIN csr_user cu ON sv.app_sid = cu.app_sid AND sv.set_by_user_sid = cu.csr_user_sid
		  LEFT JOIN measure_conversion mc ON sv.app_sid = mc.app_sid AND sv.entry_measure_conversion_id = mc.measure_conversion_id
		  LEFT JOIN (SELECT distinct val_number, start_dtm,
						end_dtm, ind_sid, region_sid FROM sheet ns JOIN sheet_value nsv ON ns.sheet_id = nsv.sheet_id) x
				 ON x.region_sid = sv.region_sid
				AND x.ind_sid = sv.ind_sid
				AND x.start_dtm = ADD_MONTHS(s.start_dtm,
					CASE tolerance_type
					  WHEN 2 THEN -12
					ELSE -DECODE(d.period_interval_id, 4, 12, 3, 6, 2, 3, 1, 1)
					END)
				AND x.end_dtm = ADD_MONTHS(s.end_dtm,
					CASE tolerance_type
					  WHEN 2 THEN -12
					ELSE -DECODE(d.period_interval_id, 4, 12, 3, 6, 2, 3, 1, 1)
					END)
		 ORDER BY sv.sheet_value_id;

	OPEN out_file_cur FOR
		SELECT svf.sheet_value_id, fu.file_upload_sid, fu.filename, fu.mime_type
		  FROM temp_val_id tv
		  JOIN sheet_value_file svf ON tv.app_sid = svf.app_sid AND tv.val_id = svf.sheet_value_id
		  JOIN file_upload fu ON svf.app_sid = fu.app_sid AND svf.file_upload_sid = fu.file_upload_sid
		 ORDER BY svf.sheet_value_id, LOWER(fu.filename);

	OPEN out_var_expl_cur FOR
		SELECT svve.sheet_value_id, ve.label
		  FROM temp_val_id tv
		  JOIN sheet_value_var_expl svve ON tv.app_sid = svve.app_sid AND tv.val_id = svve.sheet_value_id
		  JOIN var_expl ve ON svve.app_sid = ve.app_sid AND svve.var_expl_id = ve.var_expl_id
		 ORDER BY svve.sheet_value_id, ve.pos;
END;

FUNCTION SheetIsReadOnly(
	in_sheet_id			IN	sheet.sheet_id%TYPE
) RETURN BOOLEAN
AS
    v_is_read_only		NUMBER;
BEGIN
	SELECT is_read_only
	  INTO v_is_read_only
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	RETURN NVL(v_is_read_only > 0, FALSE);
END;

PROCEDURE SetCompleteness(
	in_sheet_id			IN	sheet.sheet_id%TYPE,
	in_percent_complete	IN	sheet.percent_complete%TYPE
)
AS
BEGIN
	UPDATE sheet
	   SET percent_complete = in_percent_complete
	 WHERE sheet_id = in_sheet_id;
END;

PROCEDURE GetAnnualSummarySheets(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_sheet_id			IN	csr_data_pkg.T_SHEET_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_year				INTEGER;
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT EXTRACT(year FROM start_dtm), delegation_sid
	  INTO v_year, v_delegation_sid
	  FROM csr.sheet
	 WHERE sheet_id = in_sheet_id;

	OPEN out_cur FOR
		SELECT sheet_id
		  FROM csr.sheet
		 WHERE delegation_sid = v_delegation_sid;
END;

FUNCTION GetLastParentSheetAction (
	in_sheet_id IN VARCHAR2
) RETURN NUMBER
AS
	v_sheet_action_id NUMBER(10);
BEGIN
	BEGIN
		SELECT sh.sheet_action_id 
		  INTO v_sheet_action_id
		  FROM csr.sheet_history sh WHERE sh.sheet_history_id = (
				SELECT s2.last_sheet_history_id
				  FROM csr.sheet s
				  JOIN csr.sheet s2 ON s.sheet_id = (SELECT s.sheet_id FROM csr.delegation d WHERE d.delegation_sid = s.delegation_sid AND s2.delegation_sid = d.parent_sid)
				 WHERE s.sheet_id = in_sheet_id
				   AND s.start_dtm = s2.start_dtm);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_sheet_action_id := -1;
	END;
	
	RETURN v_sheet_action_id;
END;

PROCEDURE GetActiveSheetAndLevel(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_sheet_id			OUT sheet.sheet_id%TYPE,
	out_action_id			OUT sheet_action.sheet_action_id%TYPE,
	out_level				OUT	NUMBER
)
AS 
	v_sheet_delegation_sid	security_pkg.T_SID_ID;
	v_start_dtm				sheet.start_dtm%TYPE;
	v_end_dtm				sheet.end_dtm%TYPE;
BEGIN
	SELECT delegation_sid, start_dtm, end_dtm
	  INTO v_sheet_delegation_sid, v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id;

	-- Heavily based on the function UNSEC_GetActiveSheetId
	SELECT sheet_id, last_action_id, lvl
	  INTO out_sheet_id, out_action_id, out_level
	  FROM (
		-- find sheets we're interested in and rank them according to distance from
		-- us up the delegation structure
		SELECT delegation_sid, app_sid, parent_delegation_sid, last_action_id, sheet_id,
			ROW_NUMBER() OVER (ORDER BY lvl) rn, abs(lvl-1-GetMaxDelegationLevel(v_sheet_delegation_sid)) lvl
		  FROM (
			-- find delegation sheets
			SELECT d.delegation_sid, d.app_sid, d.lvl, last_action_id, sheet_id,
				d.parent_sid parent_delegation_sid,
				CASE WHEN last_action_id IN (
					-- 0,1,2,9,10,11,12,13
					csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_RETURNED,
					csr_data_pkg.ACTION_WAITING_WITH_MOD, csr_data_pkg.ACTION_SUBMITTED,
					csr_data_pkg.ACTION_SUBMITTED_WITH_MOD, csr_data_pkg.ACTION_MERGED,
					csr_data_pkg.ACTION_MERGED_WITH_MOD,
					csr_data_pkg.ACTION_RETURNED_WITH_MOD
				) THEN 1 ELSE 0 END incl
			  FROM sheet_with_last_action sla
				JOIN (
					-- get delegations up tree
					SELECT app_sid, delegation_sid, parent_sid, level lvl
					  FROM delegation
					 START WITH delegation_sid = GetBottomDelegationId(v_sheet_delegation_sid)
				   CONNECT BY PRIOR parent_sid = delegation_sid
				)d ON sla.delegation_sid = d.delegation_sid
				  AND sla.app_sid = d.app_sid
				  AND sla.end_dtm >= v_end_dtm AND sla.start_dtm <= v_start_dtm
		 )
		 WHERE incl = 1
	 )x
	 WHERE rn = 1;
END;

-- gets the maximum delegation level in a given delegation tree
FUNCTION GetMaxDelegationLevel(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
) RETURN NUMBER
AS
	v_level					NUMBER;
BEGIN
	SELECT MAX(lvl)
		INTO v_level
	  FROM (
		SELECT delegation_sid, level lvl
		  FROM csr.delegation 
		 START WITH delegation_sid = GetBottomDelegationId(in_delegation_sid)
	   CONNECT BY delegation_sid = PRIOR parent_sid
	  );
	  
	RETURN v_level;
END;

-- gets the delegation id of the bottom level in a delegation tree
FUNCTION GetBottomDelegationId(
	in_delegation_sid		IN	delegation.delegation_sid%TYPE
) RETURN NUMBER
AS
	v_bottom_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
		INTO v_bottom_delegation_sid
	  FROM (
		SELECT delegation_sid
		  FROM csr.delegation 
		 START WITH delegation_sid = in_delegation_sid
	   CONNECT BY PRIOR delegation_sid = parent_sid
		 ORDER BY LEVEL DESC  
	  )
	  WHERE ROWNUM = 1;
	  
	RETURN v_bottom_delegation_sid;
END;

FUNCTION GetBottomSheetQueryString(
    in_ind_sid						IN	security_pkg.T_SID_ID,
    in_region_sid					IN	security_pkg.T_SID_ID,
    in_start_dtm					IN	sheet.start_dtm%TYPE,
    in_end_dtm						IN	sheet.end_dtm%TYPE,
    in_user_sid 					IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
    v_url   VARCHAR2(255);
BEGIN
    BEGIN
	  SELECT 'sheetId='||sheet_id url
		INTO v_url
		  FROM (
			SELECT s.sheet_id, row_number() OVER (ORDER BY user_sid, sheet_id) rn -- prioritise where there's a matched user, after that pick arbitrarily if > 1 match
			  FROM delegation d, delegation_ind di, delegation_region dr,
				   sheet s, v$delegation_user du
			 WHERE di.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND di.ind_sid = in_ind_sid
			   AND dr.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND dr.region_sid = in_region_sid
			   AND di.app_sid = d.app_sid AND di.delegation_sid = d.delegation_sid
			   AND dr.app_sid = d.app_sid AND dr.delegation_sid = d.delegation_sid
			   AND d.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
			   AND in_start_dtm < s.end_dtm -- within the period of the sheet
			   AND in_end_dtm > s.start_dtm
			   AND d.app_sid = du.app_sid(+) AND d.delegation_sid = du.delegation_sid(+)
			   AND du.user_sid(+) = in_user_sid
			   AND d.delegation_sid = GetBottomDelegationId(d.delegation_sid)
		 ) WHERE rn = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
    
    RETURN v_url;
END;

PROCEDURE GetFilesForSheets(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sheet_ids			IN	security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR,
	out_cur_postit			OUT SYS_REFCURSOR
) AS
	v_sid_table			security.T_SID_TABLE;
	v_deleg_sid			security_pkg.T_SID_ID;
BEGIN
	v_sid_table := security_pkg.SidArrayToTable(in_sheet_ids);
		
	FOR r IN (SELECT column_value sheet_id FROM TABLE(v_sid_table) WHERE ROWNUM=1)
	LOOP
		SELECT delegation_sid
		  INTO v_deleg_sid
		  FROM csr.sheet
		 WHERE sheet_id = r.sheet_id;
		 
		IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, v_deleg_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
	END LOOP;

	OPEN out_cur FOR
		SELECT r.description region_description, i.description ind_description, --val_pkg.FormatPeriod(s.start_dtm, s.end_dtm, d.interval) period,
		       fu.file_upload_sid, fu.filename, fu.mime_type, fu.data
		  FROM sheet_value sv
		  JOIN sheet_value_file svf ON svf.app_sid = sv.app_sid AND svf.sheet_value_id = sv.sheet_value_id
		  JOIN file_upload fu ON fu.app_sid = svf.app_sid AND fu.file_upload_sid = svf.file_upload_sid
		  JOIN v$region r ON r.app_sid = sv.app_sid AND r.region_sid = sv.region_sid
		  JOIN v$ind i ON i.app_sid = sv.app_sid AND i.ind_sid = sv.ind_sid
		 WHERE sv.sheet_id IN (SELECT column_value FROM TABLE(v_sid_table));
		
	OPEN out_cur_postit FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, pf.data
		  FROM delegation_comment dc
		  JOIN postit p ON dc.postit_id = p.postit_id AND dc.app_sid = p.app_sid
		  JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE dc.postit_id IN (
			  SELECT dc.postit_id
			    FROM sheet s
			    JOIN delegation_comment dc ON s.start_dtm = dc.start_dtm AND S.END_DTM = DC.END_DTM
			   WHERE s.sheet_id IN (SELECT column_value sheet_id FROM TABLE(v_sid_table))
			     AND dc.delegation_sid IN (
					  SELECT delegation_sid
					    FROM delegation
					   START WITH delegation_sid IN (SELECT delegation_sid FROM sheet WHERE sheet_id IN (SELECT column_value sheet_id FROM TABLE(v_sid_table)))
					 CONNECT BY PRIOR delegation_sid = parent_sid
				));
END;

PROCEDURE CountSheetsForIndRegPer(
	in_ind_sid				IN	delegation_ind.ind_sid%TYPE,
	in_region_sid			IN	delegation_region.region_sid%TYPE,
	in_start_dtm			IN	sheet.start_dtm%TYPE,
	in_end_dtm				IN	sheet.end_dtm%TYPE,
	out_sheet_count			OUT	NUMBER
)
AS
BEGIN
	SELECT COUNT(s.sheet_id)
	  INTO out_sheet_count
	  FROM sheet s
	  JOIN delegation_ind di 	ON s.delegation_sid = di.delegation_sid
	  JOIN delegation_region dr	ON s.delegation_sid = dr.delegation_sid
	 WHERE di.ind_sid = in_ind_sid
	   AND dr.region_sid = in_region_sid
	   AND s.start_dtm	>= in_start_dtm
	   AND s.end_dtm 	<= in_end_dtm
	   AND s.app_sid	 = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddCompletenessJobs(
	in_sheet_ids					IN	security_pkg.T_SID_IDS
)
AS
	v_sheet_ids						security.T_SID_TABLE;
BEGIN
	v_sheet_ids := security_pkg.SidArrayToTable(in_sheet_ids);

	MERGE /*+ALL_ROWS*/ INTO sheet_change_log scl
	USING (SELECT column_value FROM TABLE(v_sheet_ids)) s
	   ON (scl.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND scl.sheet_id = s.column_value)
	 WHEN NOT MATCHED THEN
		INSERT (scl.sheet_id)
		VALUES (s.column_value);
END;

PROCEDURE QueueCompletenessJobs(
	in_app_sid						IN	customer.app_sid%TYPE
)
AS
	v_sheet_ids						security.T_SID_TABLE;
BEGIN
	SELECT sheet_id
	  BULK COLLECT INTO v_sheet_ids
	  FROM sheet_change_log
	 WHERE app_sid = in_app_sid
	   FOR UPDATE;

	MERGE INTO sheet_completeness_sheet scl
	USING (SELECT column_value FROM TABLE(v_sheet_ids)) s
	   ON (scl.app_sid = in_app_sid AND scl.sheet_id = s.column_value)
	 WHEN NOT MATCHED THEN
		INSERT (scl.app_sid, scl.sheet_id)
		VALUES (in_app_sid, s.column_value);

	DELETE FROM sheet_change_log
	 WHERE (app_sid, sheet_id) IN (SELECT in_app_sid, column_value FROM TABLE(v_sheet_ids));

	-- these jobs are now consistent so commit to release locks
	COMMIT;
END;

PROCEDURE QueueCompletenessJobs
AS
BEGIN
	security.user_pkg.LogonAdmin(timeout => 86400);

	FOR r IN (SELECT DISTINCT app_sid app_sid
				FROM sheet_change_log) LOOP		
		security_pkg.setApp(r.app_sid);
		QueueCompletenessJobs(r.app_sid);
	END LOOP;

	user_pkg.LogOff(security_pkg.GetAct);
END;

PROCEDURE GetCompletenessSheets(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN

	-- Note; We could make this return the top n rows if we think it's starting to take longer than the duration of the scheduled task
	-- (currently 15m) but we'll see how we go for now. 
	OPEN out_cur FOR
		SELECT scs.app_sid, sheet_id
		  FROM sheet_completeness_sheet scs
		  JOIN customer c ON scs.app_sid = c.app_sid
		 WHERE scheduled_tasks_disabled = 0
		 ORDER BY scs.app_sid ASC, sheet_id DESC;
	
END;

PROCEDURE RemoveSheetCompletenessJob(
	in_sheet_id				IN	sheet.sheet_id%TYPE
)
AS
BEGIN
	
	DELETE FROM sheet_completeness_sheet
	 WHERE sheet_id = in_sheet_id;
	
	COMMIT;
	
END;

PROCEDURE GetOverdueSheetInfo(
	in_sheet_id				IN	sheet.sheet_id%TYPE,
	out_sheet_cur			OUT	SYS_REFCURSOR,
	out_child_sheet_cur		OUT	SYS_REFCURSOR
)
AS
	v_delegation_sid		sheet.delegation_sid%TYPE;
	v_start_dtm				sheet.start_dtm%TYPE;
	v_end_dtm				sheet.end_dtm%TYPE;
BEGIN

	SELECT delegation_sid, start_dtm, end_dtm
	  INTO v_delegation_sid, v_start_dtm, v_end_dtm
	  FROM sheet
	 WHERE sheet_id = in_sheet_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_sheet_cur FOR
		SELECT s.sheet_id, d.editing_url, s.last_action_id
		  FROM sheet_with_last_action s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		 WHERE sheet_id = in_sheet_id
		   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	-- Get the child sheets. basically any sheet on a delegation who's parent is the delegation for this sheet, 
	-- and is the same period.
	OPEN out_child_sheet_cur FOR
		SELECT s.sheet_id, d.editing_url, s.last_action_id
		  FROM sheet_with_last_action s
		  JOIN delegation d ON s.delegation_sid = d.delegation_sid
		 WHERE s.delegation_sid IN (
		  SELECT delegation_sid
			FROM delegation
		   WHERE parent_sid = v_delegation_sid
		)
		   AND s.start_dtm = v_start_dtm
		   AND s.end_dtm = v_end_dtm;

END;

END Sheet_Pkg;
/

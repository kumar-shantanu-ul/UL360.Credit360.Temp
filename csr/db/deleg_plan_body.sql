CREATE OR REPLACE PACKAGE BODY CSR.Deleg_Plan_Pkg AS

PROCEDURE SetPeriod(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_day_of_period 				IN	NUMBER,
	in_force						IN	NUMBER DEFAULT 0
);

PROCEDURE UpdateDateSchedule(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN  delegation.delegation_sid%TYPE,
	in_schedule_xml			IN  delegation.schedule_xml%TYPE,
	in_reminder_offset		IN	delegation.reminder_offset%TYPE,
	in_date_schedule_id		IN	deleg_plan_date_schedule.delegation_date_schedule_id%TYPE
);

PROCEDURE UpdateSheetDates(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	delegation.delegation_sid%TYPE
);

-- delete everything in the tree where we have no user entered data
FUNCTION SafeDeleteDelegation(
	in_delegation_sid		IN	security_pkg.T_SID_ID
)
RETURN BOOLEAN
AS
	v_deleted	BOOLEAN := FALSE;
BEGIN
	DELETE FROM temp_delegation_tree;
	INSERT INTO temp_delegation_tree (delegation_sid, parent_sid, lvl)
		SELECT delegation_sid, parent_sid, level lvl
		  FROM delegation
			   START WITH delegation_sid = in_delegation_sid
			   CONNECT BY PRIOR delegation_sid = parent_sid;

	FOR r IN (
		-- figure out which delegations have NO sheet_values so can be safely
		-- deleted. Bit convoluted.
		SELECT x.delegation_sid, acd.lvl
		  FROM (
				-- get all nodes
				SELECT delegation_sid
				  FROM temp_delegation_tree
				 MINUS
				-- get all the nodes including and upwards from delegations that have sheets with data
				SELECT delegation_sid
				  FROM delegation
				 START WITH delegation_sid IN (
					-- delegations and whether or not they have sheets with data
					SELECT d.delegation_sid
					  FROM temp_delegation_tree d
					  -- constrain to regions/inds actually part of the delegation
					  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
					  JOIN delegation_ind di ON dr.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
					  -- ignore data for calculated inds
					  JOIN ind i ON di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
					  JOIN sheet s ON di.app_sid = s.app_sid AND d.delegation_sid = s.delegation_sid
					  LEFT JOIN sheet_value sv ON s.app_sid = sv.app_sid AND s.sheet_id = sv.sheet_id
					   AND sv.region_sid = dr.region_sid AND sv.ind_sid = di.ind_sid
					  LEFT JOIN sheet_value_file svf ON s.app_sid = sv.app_sid AND sv.sheet_value_id = svf.sheet_value_id
					  LEFT JOIN sheet_with_last_action sla ON s.app_sid = sla.app_sid AND s.sheet_id = sla.sheet_id
					 GROUP BY d.delegation_sid, d.parent_sid
					HAVING SUM(
							CASE WHEN sv.val_number IS NOT NULL
								   OR NVL(LENGTH(sv.note),0) != 0
								   OR svf.sheet_value_id IS NOT NULL
								   OR sv.status != csr_data_pkg.SHEET_VALUE_ENTERED -- don't delete if value including NULL has been submitted/approved/merged/modified/propagated
								   OR sla.last_action_id NOT IN (csr_data_pkg.ACTION_WAITING, csr_data_pkg.ACTION_WAITING_WITH_MOD) -- don't delete if sheet has been submitted/approved/merged
								 THEN 1 ELSE 0
							END
						   ) > 0
				)
				CONNECT BY PRIOR parent_sid = delegation_sid) x
			-- join back to the full tree and sort depth descending (i.e. so we can
			-- delete from the bottom up)
		  JOIN temp_delegation_tree acd ON x.delegation_sid = acd.delegation_sid
		 ORDER BY acd.lvl DESC
	)
	LOOP
		-- this can be safely deleted

		-- mark all sheets as read/write to work around the check in the deletion code
		-- XXX: should the deletion code actually bother checking?
		UPDATE sheet
		   SET is_read_only = 0
		 WHERE delegation_sid = r.delegation_sid;

		securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), r.delegation_sid);
		IF r.delegation_sid = in_delegation_sid THEN
			v_deleted := TRUE;
		END IF;
	END LOOP;
	RETURN v_deleted;
END;

PROCEDURE IsDelegationPartOfPlan(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT dp.deleg_plan_sid, dp.name, dp.last_applied_dtm
		  FROM deleg_plan dp
		  JOIN deleg_plan_col dpc ON dp.deleg_plan_sid = dpc.deleg_plan_sid AND dp.app_sid = dpc.app_sid
		  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id AND dpc.app_sid = dpcd.app_sid
		  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpcd.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpcd.app_sid = dpdrd.app_sid
		  JOIN (
			SELECT delegation_sid
			  FROM delegation
			 START WITH delegation_sid = in_delegation_sid
			CONNECT BY PRIOR parent_sid = delegation_sid AND PRIOR app_sid = app_sid
		  ) d ON d.delegation_sid = dpdrd.maps_to_root_deleg_sid;
END;

FUNCTION IsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count		NUMBER;
BEGIN
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM master_deleg
	 WHERE delegation_sid = in_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	RETURN v_count;
END;

-- Check whether given delegation has any children that are templates
FUNCTION HasChildTemplates(
	in_delegation_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS 
	v_sub_tpl_cnt	NUMBER;
BEGIN
	-- if any of child delegs is a template then raise error
	SELECT count(*) INTO v_sub_tpl_cnt
	  FROM delegation d
	 WHERE EXISTS (SELECT delegation_sid
					 FROM master_deleg
					WHERE delegation_sid = d.delegation_sid)
	   AND d.delegation_sid != in_delegation_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 START WITH delegation_sid = in_delegation_sid
   CONNECT BY PRIOR app_sid = app_sid AND PRIOR delegation_sid = parent_sid;
	
	IF v_sub_tpl_cnt > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE SetAsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_is_template		IN	NUMBER
)
AS
	v_sid					security_pkg.T_SID_ID;
	v_current_is_template	NUMBER;
	v_root_deleg_sids		NUMBER;
	v_sheet_values_on_deleg	NUMBER;
	v_visible_templates 	NUMBER;
BEGIN
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT COUNT(*)
	  INTO v_current_is_template
	  FROM master_deleg
	 WHERE delegation_sid = in_delegation_Sid;

	IF in_is_template = v_current_is_template THEN
		-- abort - no change. This is neater than having permission issues accessing DelegPlansRegion
		-- Also means we don't write dupe audit log entries
		RETURN;
	END IF;

	v_sid := securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '/DelegationPlans/DelegPlansRegion');

	IF in_is_template = 0 THEN
		SELECT COUNT(*)
		  INTO v_visible_templates
		  FROM deleg_plan_col dpc
		  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		 WHERE dpcd.delegation_sid = in_delegation_sid
		   AND dpc.is_hidden = 0
		   AND dpc.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
		IF v_visible_templates > 0 THEN   
			RAISE csr_data_pkg.DELEGATION_USED_AS_TPL;
		ELSE 
			FOR R IN (
				SELECT dpc.deleg_plan_col_id, dpc.deleg_plan_sid, d.description, dp.name
				  FROM deleg_plan_col dpc
				  JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
				  JOIN deleg_plan dp ON dpc.deleg_plan_sid = dp.deleg_plan_sid
				  JOIN v$delegation d ON dpcd.delegation_sid = d.delegation_sid
				 WHERE dpcd.delegation_sid = in_delegation_sid
				   AND dpc.is_hidden = 1				   
				   AND dpc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) LOOP
				UPDATE delegation
				   SET master_delegation_sid = NULL
				 WHERE master_delegation_sid = in_delegation_sid;

				DELETE FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id IN (
					SELECT deleg_plan_col_deleg_id
					  FROM deleg_plan_col
					 WHERE deleg_plan_col_id = R.deleg_plan_col_id
				 );
				DELETE FROM deleg_plan_deleg_region
				 WHERE deleg_plan_col_deleg_id IN (
					SELECT deleg_plan_col_deleg_id
					  FROM deleg_plan_col
					 WHERE deleg_plan_col_id = R.deleg_plan_col_id
				 );

				-- Remove date schedule from plan but keep date_schedule and sheet_schedules for rolled out delegs
				DELETE FROM deleg_plan_date_schedule
				 WHERE deleg_plan_col_id = R.deleg_plan_col_id;

				-- this cascade deletes deleg_plan_col
				DELETE FROM deleg_plan_col_deleg
				 WHERE deleg_plan_col_deleg_id IN (
					SELECT deleg_plan_col_deleg_id
					  FROM deleg_plan_col
					 WHERE deleg_plan_col_id = R.deleg_plan_col_id
				 );
				 
				csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
					SYS_CONTEXT('SECURITY', 'APP'), R.deleg_plan_sid, 'Deleting column "{0}" from plan "{1}", template removed.',
					R.description, R.name);
			END LOOP;
			
			DELETE FROM master_deleg
			 WHERE delegation_sid = in_delegation_sid;
		END IF;

		DELETE FROM delegation_region
		 WHERE delegation_sid = in_delegation_sid
		   AND region_sid = v_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'),
			in_delegation_sid, 'Removed as template');
	ELSE
		BEGIN

			-- delegations created by delegation plans can't be marked as a template
			SELECT COUNT(*)
			INTO v_root_deleg_sids
			  FROM csr.deleg_plan_deleg_region_deleg
			 WHERE maps_to_root_deleg_sid IN (in_delegation_sid);

			IF v_root_deleg_sids > 0 THEN
				RAISE csr_data_pkg.DELEG_FROM_DELEG_PLAN;
			END IF;

			-- delegations that already have data cannot be marked as a template
			SELECT COUNT(*)
			INTO v_sheet_values_on_deleg
			  FROM sheet s
			  JOIN sheet_value sv ON sv.sheet_id = s.sheet_id
			 WHERE s.delegation_sid = in_delegation_sid;

			IF v_sheet_values_on_deleg > 0 THEN
				RAISE csr_data_pkg.DELEG_HAS_VALUES;
			END IF;

			INSERT INTO master_deleg (delegation_sid)
				VALUES (in_delegation_sid);

			FOR r IN (
				SELECT delegation_sid
				  FROM delegation
				 START WITH delegation_sid = in_delegation_sid
				CONNECT BY PRIOR delegation_sid = parent_sid
			)
			LOOP
				DELETE FROM delegation_region_description
				 WHERE delegation_sid = r.delegation_sid
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
				DELETE FROM delegation_region
				 WHERE delegation_sid = r.delegation_sid
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

				INSERT INTO delegation_region (delegation_sid, region_sid, aggregate_to_region_sid)
				VALUES (r.delegation_sid, v_sid, v_sid);
			END LOOP;

			csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'),
				in_delegation_sid, 'Set as template');

			-- we clear this down because we want anything copied from this delegation to link back to the template correctly.
			UPDATE delegation
			   SET master_delegation_sid = NULL
			 WHERE delegation_sid = in_delegation_sid;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END IF;
END;

PROCEDURE GetMasterDelegations(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.delegation_sid sid, d.name, d.description, d.start_dtm, d.end_dtm
		  FROM master_deleg md
		  JOIN v$delegation d ON md.app_sid = d.app_sid AND md.delegation_sid = d.delegation_sid
		 WHERE delegation_pkg.SQL_CheckDelegationPermission(SYS_CONTEXT('SECURITY', 'ACT'), md.delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) = 1;
END;

PROCEDURE UNSEC_INT_DeleteDelegPlanDateSchedules(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID
)
AS
	v_schedule_ids		security.T_SID_TABLE;
BEGIN
	SELECT delegation_date_schedule_id
	  BULK COLLECT INTO v_schedule_ids
	  FROM deleg_plan_date_schedule
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	DELETE FROM deleg_plan_date_schedule
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	DELETE FROM sheet_date_schedule
	 WHERE delegation_date_schedule_id IN (
		SELECT t.column_value
		  FROM TABLE(v_schedule_ids) t
	);

	DELETE FROM delegation_date_schedule
	 WHERE delegation_date_schedule_id IN (
		SELECT t.column_value
		  FROM TABLE(v_schedule_ids) t
	);
END;

-- Securable object callbacks

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	IF in_new_name IS NOT NULL THEN
		UPDATE deleg_plan
		   SET name = in_new_name
		 WHERE deleg_plan_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_name	deleg_plan.name%TYPE;
BEGIN
	SELECT name
	  INTO v_name
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_sid_Id;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), in_sid_Id, 'Deleted delegation plan "{0}" (id {1})',
		v_name, in_sid_id);

	-- we need to set our audit log object_sid to null due to FK constraint
	UPDATE audit_log SET object_sid = null WHERE object_sid = in_sid_id;

	-- delete date schedules
	UNSEC_INT_DeleteDelegPlanDateSchedules(in_sid_id);

	DELETE FROM deleg_plan_role
	 WHERE deleg_plan_sid = in_sid_id;

	DELETE FROM deleg_plan_region
	 WHERE deleg_plan_sid = in_sid_id;

	-- delegations
	DELETE FROM deleg_plan_deleg_region_deleg
	 WHERE deleg_plan_col_deleg_id IN (
		SELECT deleg_plan_col_deleg_id
		  FROM deleg_plan_col
		 WHERE deleg_plan_sid = in_sid_id
	);

	DELETE FROM deleg_plan_deleg_region
	 WHERE deleg_plan_col_deleg_id IN (
		SELECT deleg_plan_col_deleg_id
		  FROM deleg_plan_col
		 WHERE deleg_plan_sid = in_sid_id
	);

	-- this cascade deletes from deleg_plan_col
	DELETE FROM deleg_plan_col_deleg
	 WHERE deleg_plan_col_deleg_id IN (
		SELECT deleg_plan_col_deleg_id
		  FROM deleg_plan_col
		 WHERE deleg_plan_sid = in_sid_id
	);

	-- this cascade deletes from deleg_plan_col
	DELETE FROM deleg_plan_col_survey
	 WHERE deleg_plan_col_survey_id IN (
		SELECT deleg_plan_col_deleg_id
		  FROM deleg_plan_col
		 WHERE deleg_plan_sid = in_sid_id
	 );

	-- delete jobs associated with the plan
	UPDATE batch_job
	   SET completed_dtm = SYSDATE,
		   result = 'Delegation plan deleted',
		   processing = 0,
		   running_on = NULL
	 WHERE batch_job_id IN (
			SELECT batch_job_id
			  FROM deleg_plan_job
			 WHERE deleg_plan_sid = in_sid_id)
	   AND completed_dtm IS NULL;

	DELETE FROM deleg_plan_job
	 WHERE deleg_plan_sid = in_sid_id;

	-- and finally the plan itself
	DELETE FROM deleg_plan
	 WHERE deleg_plan_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

-- delegation plan

FUNCTION GetDelegPlanRoot RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), '/DelegationPlans');
END;

-- used by statusreport amongst others
PROCEDURE GetDelegPlanGroups(
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- XXX: should really use securableobject_pkg.GetChildrenWithPermAsTable as it's much more efficient
	-- if there's loads of data
	OPEN out_cur FOR
		SELECT start_dtm, end_dtm, deleg_plan_sid, name,
			ROW_NUMBER() OVER (PARTITION BY start_dtm, end_dtm ORDER BY name) rid
		  FROM deleg_plan
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), deleg_plan_sid, security_pkg.PERMISSION_READ) = 1
		 ORDER BY start_dtm DESC;
END;


PROCEDURE CopyDelegPlanSchedule(
	in_deleg_plan_sid			IN	deleg_plan.deleg_plan_sid%TYPE,
	in_new_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE
)
AS
	v_old_start_dtm					deleg_plan.start_dtm%TYPE;
	v_start_dtm						deleg_plan.start_dtm%TYPE;
	v_old_end_dtm					deleg_plan.end_dtm%TYPE;
	v_end_dtm						deleg_plan.end_dtm%TYPE;
	v_old_schedule_xml				deleg_plan.schedule_xml%TYPE;
	v_old_reminder_offset			deleg_plan.reminder_offset%TYPE;
	v_start_months_difference		NUMBER;
	v_end_months_difference			NUMBER;
BEGIN
	SELECT start_dtm, end_dtm, schedule_xml, reminder_offset
	  INTO v_old_start_dtm, v_old_end_dtm, v_old_schedule_xml, v_old_reminder_offset
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	SELECT start_dtm, end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_new_plan_sid;

	v_start_months_difference := MONTHS_BETWEEN(v_start_dtm, v_old_start_dtm);
	v_end_months_difference := MONTHS_BETWEEN(v_end_dtm, v_old_end_dtm);
	
	-- for every date schedule of the old delegation plan
	FOR r IN (
		SELECT dpds.app_sid, dpds.deleg_plan_sid, dpds.role_sid, dpds.deleg_plan_col_id, dpds.schedule_xml,
			   dpds.reminder_offset, dpds.delegation_date_schedule_id
		  FROM deleg_plan_date_schedule dpds
		  JOIN delegation_date_schedule dds on (dds.delegation_date_schedule_id = dpds.delegation_date_schedule_id)
		 WHERE dpds.deleg_plan_sid = in_deleg_plan_sid --old planner's sid
	)
	LOOP
		-- copy the deleg_plan_date_schedule and delegation_date_schedule values
		IF v_start_months_difference != v_end_months_difference THEN
			-- new plan is for shorter/longer period, do not copy fixed date schedule
			AddDelegPlanDateSchedule(in_new_plan_sid, r.role_sid, r.deleg_plan_col_id, NVL(r.schedule_xml, v_old_schedule_xml), NVL(r.reminder_offset, v_old_reminder_offset));
		ELSE
			AddDelegPlanDateSchedule(in_new_plan_sid, r.role_sid, r.deleg_plan_col_id, r.schedule_xml, r.reminder_offset);
			
			FOR rr IN (--for every sheet date schedule of the old delegation plan
				SELECT sds.start_dtm, sds.creation_dtm, sds.submission_dtm, sds.reminder_dtm
				  FROM sheet_date_schedule sds
				 WHERE sds.delegation_date_schedule_id = r.delegation_date_schedule_id
			)
			LOOP
				-- copy the sheet_date_schedule values
				AddDelegPlanDateScheduleEntry(in_new_plan_sid, r.role_sid, r.deleg_plan_col_id,
					ADD_MONTHS(rr.start_dtm, v_start_months_difference),
					ADD_MONTHS(rr.creation_dtm, v_start_months_difference),
					ADD_MONTHS(rr.submission_dtm, v_start_months_difference),
					ADD_MONTHS(rr.reminder_dtm,v_start_months_difference));

			END LOOP;
		END IF;
	END LOOP;
END;

FUNCTION GetPlanColsDelegSids(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE
) RETURN security.security_pkg.T_SID_IDS
AS
	v_deleg_plan_col_deleg_sids			security.security_pkg.T_SID_IDS;
BEGIN
	FOR r IN (
		SELECT DISTINCT dpcd.delegation_sid
		  FROM deleg_plan_col_deleg dpcd
		  JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND dpc.is_hidden = 0
	)
	LOOP
		v_deleg_plan_col_deleg_sids(r.delegation_sid) := r.delegation_sid;
	END LOOP;
	RETURN v_deleg_plan_col_deleg_sids;
END;

FUNCTION CopyPlanColsDelegSids(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_deleg_plan_col_deleg_sids	IN	security.security_pkg.T_SID_IDS,
	in_deleg_plan_col_deleg_lbls	IN	security.security_pkg.T_VARCHAR2_ARRAY
) RETURN security.security_pkg.T_SID_IDS
AS
	v_deleg_plan_col_deleg_sids			security.security_pkg.T_SID_IDS;
	v_deleg_plan_col_deleg_lbls			security.security_pkg.T_VARCHAR2_ARRAY;
	v_start_dtm							delegation.start_dtm%TYPE;
	v_end_dtm							delegation.end_dtm%TYPE;
	v_period_set_id						delegation.period_set_id%TYPE;
	v_period_interval_id				delegation.period_interval_id%TYPE;
	v_new_delegation_sid				security.security_pkg.T_SID_ID;
	v_new_delegation_sids_cur			SYS_REFCURSOR;
	v_from_sid 							security.security_pkg.T_SID_ID;
	v_to_sid 							security.security_pkg.T_SID_ID;
	v_idx								PLS_INTEGER;
BEGIN
	SELECT start_dtm, end_dtm, period_set_id, period_interval_id
	  INTO v_start_dtm, v_end_dtm, v_period_set_id, v_period_interval_id
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	--  get template delegation sid and label, if same template has been added more than once to plan use last label
	FOR i IN 1..in_deleg_plan_col_deleg_sids.COUNT
	LOOP
		v_deleg_plan_col_deleg_lbls(in_deleg_plan_col_deleg_sids(i)) := in_deleg_plan_col_deleg_lbls(i);
	END LOOP;

	v_idx := v_deleg_plan_col_deleg_lbls.FIRST;
	WHILE v_idx IS NOT NULL
	LOOP
		delegation_pkg.CopyDelegationChangePeriod(
			SYS_CONTEXT('SECURITY', 'ACT'), v_idx, v_deleg_plan_col_deleg_lbls(v_idx),
			v_start_dtm, v_end_dtm, v_period_set_id, v_period_interval_id, v_new_delegation_sids_cur
		);

		--Fetch v_new_delegation_sid from ref_cursor v_new_delegation_sids_cur
		FETCH v_new_delegation_sids_cur INTO v_from_sid, v_to_sid;
		v_new_delegation_sid := v_to_sid;

		--Add delegation to master_deleg table
		SetAsTemplate(v_new_delegation_sid, 1);

		v_deleg_plan_col_deleg_sids(v_idx) := v_new_delegation_sid;
		v_idx := v_deleg_plan_col_deleg_lbls.NEXT(v_idx);
	END LOOP;
	RETURN v_deleg_plan_col_deleg_sids;
END;

PROCEDURE CopyDelegPlanCols(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_new_plan_sid					IN	deleg_plan.deleg_plan_sid%TYPE,
	in_copy_template				IN	NUMBER,
	in_deleg_plan_col_deleg_sids	IN	security.security_pkg.T_SID_IDS,
	in_deleg_plan_col_deleg_lbls	IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_deleg_plan_col_id 				deleg_plan_col.deleg_plan_col_id%TYPE;
	v_deleg_plan_col_deleg_sids			security.security_pkg.T_SID_IDS;
BEGIN
	IF in_copy_template = csr_data_pkg.PLAN_TEMPLATE_EXISTING THEN
		v_deleg_plan_col_deleg_sids := GetPlanColsDelegSids(in_deleg_plan_sid);
	END IF;

	IF in_copy_template = csr_data_pkg.PLAN_TEMPLATE_COPY THEN
		v_deleg_plan_col_deleg_sids := CopyPlanColsDelegSids(in_deleg_plan_sid, in_deleg_plan_col_deleg_sids, in_deleg_plan_col_deleg_lbls);
	END IF;

	IF in_copy_template = csr_data_pkg.PLAN_TEMPLATE_NO OR v_deleg_plan_col_deleg_sids.COUNT = 0 THEN
		RETURN;
	END IF;

	-- pre-map
	INSERT INTO map_id (old_id, new_id)
		SELECT dpcd.deleg_plan_col_deleg_id, deleg_plan_col_deleg_id_seq.NEXTVAL
		  FROM deleg_plan_col_deleg dpcd
		  JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid;

	-- now insert all the mappings
	FOR r IN (
		SELECT ms.new_id, dpcd.delegation_sid
		  FROM deleg_plan_col_deleg dpcd
		  JOIN map_id ms ON dpcd.deleg_plan_col_deleg_id = ms.old_id
		  JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND dpc.is_hidden = 0
	)
	LOOP
		INSERT INTO deleg_plan_col_deleg (deleg_plan_col_deleg_id, delegation_sid)
			VALUES (r.new_id, v_deleg_plan_col_deleg_sids(r.delegation_sid));
	END LOOP;

	INSERT INTO deleg_plan_col (deleg_plan_sid, deleg_plan_col_id, is_hidden, deleg_plan_col_deleg_id)
	SELECT in_new_plan_sid, deleg_plan_col_id_seq.nextval, dpc.is_hidden, ms.new_id
	  FROM deleg_plan_col dpc
	  JOIN map_id ms ON dpc.deleg_plan_col_deleg_id = ms.old_id
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND dpc.is_hidden = 0;

	-- Copy old planner's region selection to new one
	FOR r IN (--for every selected region of the old delegation planner
		SELECT dpc.deleg_plan_col_deleg_id, dpdr.region_sid, dpdr.region_selection, dpdr.tag_id, dpdr.region_type
		  FROM deleg_plan_deleg_region dpdr
		  JOIN deleg_plan_col dpc ON dpdr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		  JOIN region r ON dpdr.region_sid = r.region_sid
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid --old planner's sid
		   AND dpc.is_hidden = 0
		   AND dpdr.pending_deletion = 0
		   AND r.active = 1
	)
	LOOP
		-- find new deleg_plan_col_id (delegation planner's column) using map_id table
		SELECT dpc.deleg_plan_col_id
		  INTO v_deleg_plan_col_id
		  FROM deleg_plan_col dpc
		 WHERE dpc.deleg_plan_col_deleg_id =(
			SELECT ms.new_id -- this is the new deleg_plan_col_deleg_id
			  FROM map_id ms
			 WHERE ms.old_id = r.deleg_plan_col_deleg_id
		 )
		 AND dpc.deleg_plan_sid = in_new_plan_sid;

		UpdateDelegPlanColRegion(v_deleg_plan_col_id, r.region_sid, r.region_selection, r.tag_id, r.region_type);

	END LOOP;
END;

FUNCTION CopyDelegPlan(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_name							IN	deleg_plan.name%TYPE,
	in_start_dtm					IN	deleg_plan.start_dtm%TYPE,
	in_end_dtm						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_template_delegation_sids			security.security_pkg.T_SID_IDS;
	v_template_labels					security.security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	RETURN CopyDelegPlan(in_deleg_plan_sid, in_name, in_start_dtm, in_end_dtm,
		in_reminder_offset, in_period_set_id, in_period_interval_id, in_schedule_xml,
		csr_data_pkg.PLAN_TEMPLATE_EXISTING, v_template_delegation_sids, v_template_labels,
		in_parent_sid
	);
END;

PROCEDURE GetFolderPlans(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_app_sid			security.security_pkg.T_SID_ID := security.security_pkg.GetApp;			
BEGIN
	OPEN out_cur FOR
		SELECT dp.deleg_plan_sid, so.parent_sid_id AS parent_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.reminder_offset,
			   dp.period_set_id, dp.period_interval_id, pi.label period_interval_label,
			   dp.schedule_xml, dp.dynamic,
			   CASE WHEN dpds.dscount = 1 THEN 1 ELSE 0 END custom_date_schedule,
			   CASE WHEN dpds.dscount > 1 THEN 1 ELSE 0 END multiple_date_schedule,
			   CASE WHEN dp_w.sid_id IS NULL THEN 0 ELSE 1 END can_write,
			   CASE WHEN dp_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM deleg_plan dp
		  JOIN period_interval pi ON dp.period_interval_id = pi.period_interval_id AND dp.period_set_id = pi.period_set_id
		  LEFT JOIN (SELECT deleg_plan_sid, COUNT(*) AS dscount FROM deleg_plan_date_schedule GROUP BY deleg_plan_sid) dpds ON  dpds.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN security.securable_object so ON dp.deleg_plan_sid = so.sid_id
		  JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, in_parent_sid, security.security_pkg.PERMISSION_READ)) dp_r
			ON dp.deleg_plan_sid = dp_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, in_parent_sid, security.security_pkg.PERMISSION_WRITE)) dp_w
			ON dp.deleg_plan_sid = dp_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, in_parent_sid, security.security_pkg.PERMISSION_DELETE)) dp_d
			ON dp.deleg_plan_sid = dp_d.sid_id
		 WHERE dp.app_sid = v_app_sid
		   AND active = 1
		 ORDER BY name;
END;

PROCEDURE GetActiveDelegPlans(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_root_sid						security_pkg.T_SID_ID;
BEGIN
	v_root_sid := GetDelegPlanRoot();
	
	OPEN out_cur FOR
		SELECT dp.deleg_plan_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.reminder_offset,
			   dp.period_set_id, dp.period_interval_id, pi.label period_interval_label,
			   dp.schedule_xml, dp.dynamic, so.parent_sid_id parent_sid,
			   CASE WHEN dpds.dscount = 1 THEN 1 ELSE 0 END custom_date_schedule,
			   CASE WHEN dpds.dscount > 1 THEN 1 ELSE 0 END multiple_date_schedule,
			   CASE WHEN dp_w.sid_id IS NULL THEN 0 ELSE 1 END can_write,
			   CASE WHEN dp_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM deleg_plan dp
		  JOIN period_interval pi ON dp.period_interval_id = pi.period_interval_id AND dp.period_set_id = pi.period_set_id
		  LEFT JOIN (SELECT deleg_plan_sid, COUNT(*) AS dscount FROM deleg_plan_date_schedule GROUP BY deleg_plan_sid) dpds ON  dpds.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN security.securable_object so ON dp.deleg_plan_sid = so.sid_id
		  JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_READ)) dp_r
			ON dp.deleg_plan_sid = dp_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_WRITE)) dp_w
			ON dp.deleg_plan_sid = dp_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_DELETE)) dp_d
			ON dp.deleg_plan_sid = dp_d.sid_id
		 WHERE dp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = 1
		 ORDER BY name;
END;

PROCEDURE GetHiddenDelegPlans(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_root_sid						security_pkg.T_SID_ID;
BEGIN

	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security_pkg.IsAdmin(security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	v_root_sid := GetDelegPlanRoot();
	
	OPEN out_cur FOR
		SELECT dp.deleg_plan_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.reminder_offset,
			   dp.period_set_id, dp.period_interval_id, pi.label period_interval_label,
			   dp.schedule_xml, dp.dynamic, so.parent_sid_id parent_sid,
			   CASE WHEN dpds.dscount = 1 THEN 1 ELSE 0 END custom_date_schedule,
			   CASE WHEN dpds.dscount > 1 THEN 1 ELSE 0 END multiple_date_schedule,
			   CASE WHEN dp_w.sid_id IS NULL THEN 0 ELSE 1 END can_write,
			   CASE WHEN dp_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM deleg_plan dp
		  JOIN period_interval pi ON dp.period_interval_id = pi.period_interval_id AND dp.period_set_id = pi.period_set_id
		  LEFT JOIN (SELECT deleg_plan_sid, COUNT(*) AS dscount FROM deleg_plan_date_schedule GROUP BY deleg_plan_sid) dpds ON  dpds.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN security.securable_object so ON dp.deleg_plan_sid = so.sid_id
		  JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_READ)) dp_r
			ON dp.deleg_plan_sid = dp_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_WRITE)) dp_w
			ON dp.deleg_plan_sid = dp_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetDescendantsWithPermAsTable(v_act_id, v_root_sid, security.security_pkg.PERMISSION_DELETE)) dp_d
			ON dp.deleg_plan_sid = dp_d.sid_id
		 WHERE dp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = 0
		 ORDER BY name;
END;

FUNCTION NewDelegPlan(
	in_name							IN	deleg_plan.name%TYPE,
	in_start_date					IN	deleg_plan.start_dtm%TYPE,
	in_end_date						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_dynamic						IN	deleg_plan.dynamic%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_root_sid						security_pkg.T_SID_ID;
	v_sid							security_pkg.T_SID_ID;
BEGIN
	v_root_sid := GetDelegPlanRoot();

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), NVL(in_parent_sid, v_root_sid), security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating new delegation plan');
	END IF;

	SecurableObject_pkg.CreateSO(
		SYS_CONTEXT('SECURITY','ACT'),
		NVL(in_parent_sid, v_root_sid),
		class_pkg.GetClassID('CSRDelegationPlan'), REPLACE(in_name, '/', '\'), v_sid); --'


	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), v_sid, 'Created delegation plan "{0}" (id {1})',
		in_name, v_sid);

	INSERT INTO deleg_plan (deleg_plan_sid, name, start_dtm, end_dtm, reminder_offset,
		period_set_id, period_interval_id, schedule_xml, dynamic)
	VALUES (v_sid, in_name, in_start_date, in_end_date, in_reminder_offset, in_period_set_id,
		in_period_interval_id, in_schedule_xml, in_dynamic);
	
	IF in_period_set_id != 1 THEN 
		
		AddDelegPlanDateSchedule(v_sid, null, null, null, null); 
		
		FOR r IN (
			SELECT pstrt.start_dtm, pstrt.start_dtm creation_dtm, pend.end_dtm submission_dtm, pend.end_dtm - in_reminder_offset reminder_dtm
			  FROM period_set ps
			  JOIN period_interval_member pim ON ps.period_set_id = pim.period_set_id
			  JOIN period_dates pstrt ON pim.start_period_id = pstrt.period_id AND pim.period_set_id = pstrt.period_set_id AND pstrt.start_dtm >= in_start_date AND pstrt.start_dtm < in_end_date
			  JOIN period_dates pend ON pim.end_period_id = pend.period_id AND pim.period_set_id = pend.period_set_id AND pend.end_dtm > in_start_date AND pend.end_dtm <= in_end_date
			 WHERE ps.period_set_id = in_period_set_id
			   AND pim.period_interval_id = in_period_interval_id
			   AND pstrt.year = pend.year
		) LOOP		
			AddDelegPlanDateScheduleEntry(v_sid, null, null, r.start_dtm, r.creation_dtm, r.submission_dtm, r.reminder_dtm);
		END LOOP;
		   
	END IF;
	
	RETURN v_sid;
END;

PROCEDURE NewDelegPlanReturnDto(
	in_name							IN	deleg_plan.name%TYPE,
	in_start_date					IN	deleg_plan.start_dtm%TYPE,
	in_end_date						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_dynamic						IN	deleg_plan.dynamic%TYPE,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_root_sid						security_pkg.T_SID_ID;
	v_sid							security_pkg.T_SID_ID;
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	v_root_sid := GetDelegPlanRoot();
	v_sid := NewDelegPlan(in_name, in_start_date, in_end_date, in_reminder_offset, in_period_set_id, in_period_interval_id, in_schedule_xml, in_dynamic, in_parent_sid);

	OPEN out_cur FOR
		SELECT dp.deleg_plan_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.reminder_offset,
			   dp.period_set_id, dp.period_interval_id, pi.label period_interval_label,
			   dp.schedule_xml, dp.dynamic, so.parent_sid_id parent_sid,
			   CASE WHEN dpds.dscount = 1 THEN 1 ELSE 0 END custom_date_schedule,
			   CASE WHEN dpds.dscount > 1 THEN 1 ELSE 0 END multiple_date_schedule,
			   CASE WHEN dp_w.sid_id IS NULL THEN 0 ELSE 1 END can_write,
			   CASE WHEN dp_d.sid_id IS NULL THEN 0 ELSE 1 END can_delete
		  FROM deleg_plan dp
		  JOIN period_interval pi ON dp.period_interval_id = pi.period_interval_id AND dp.period_set_id = pi.period_set_id
		  LEFT JOIN (SELECT deleg_plan_sid, COUNT(*) AS dscount FROM deleg_plan_date_schedule GROUP BY deleg_plan_sid) dpds ON  dpds.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN security.securable_object so ON dp.deleg_plan_sid = so.sid_id
		  JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, NVL(in_parent_sid, v_root_sid), security.security_pkg.PERMISSION_READ)) dp_r
			ON dp.deleg_plan_sid = dp_r.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, NVL(in_parent_sid, v_root_sid), security.security_pkg.PERMISSION_WRITE)) dp_w
			ON dp.deleg_plan_sid = dp_w.sid_id
		  LEFT JOIN TABLE(security.securableobject_pkg.GetChildrenWithPermAsTable(v_act_id, NVL(in_parent_sid, v_root_sid), security.security_pkg.PERMISSION_DELETE)) dp_d
			ON dp.deleg_plan_sid = dp_d.sid_id
		 WHERE dp.deleg_plan_sid = v_sid;
END;

FUNCTION CopyDelegPlan(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_name							IN	deleg_plan.name%TYPE,
	in_start_dtm					IN	deleg_plan.start_dtm%TYPE,
	in_end_dtm						IN	deleg_plan.end_dtm%TYPE,
	in_reminder_offset				IN	deleg_plan.reminder_offset%TYPE,
	in_period_set_id				IN	deleg_plan.period_set_id%TYPE,
	in_period_interval_id			IN	deleg_plan.period_interval_id%TYPE,
	in_schedule_xml					IN	deleg_plan.schedule_xml%TYPE,
	in_copy_template				IN	NUMBER,
	in_template_delegation_sids		IN	security.security_pkg.T_SID_IDS,
	in_template_labels				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_parent_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL
) RETURN NUMBER
AS
	v_new_plan_sid 					deleg_plan.deleg_plan_sid%TYPE;
	v_name_template 				deleg_plan.name_template%TYPE;
	v_active 						deleg_plan.active%TYPE;
	v_notes 						deleg_plan.notes%TYPE;
	v_dynamic 						deleg_plan.dynamic%TYPE;
	v_old_period_set_id				deleg_plan.period_set_id%TYPE;
	v_old_period_interval_id		deleg_plan.period_interval_id%TYPE;
	v_new_cap_sid					NUMBER(10);
	v_copy_dacl_id					NUMBER(10);
	v_new_dacl_id					NUMBER(10);
	v_parent_sid					NUMBER(10);
	v_act_id						security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
BEGIN
	-- check read permissions
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan');
	END IF;

	SELECT name_template, active, notes, dynamic, period_set_id,
		   period_interval_id, parent_sid_id
	  INTO v_name_template, v_active, v_notes, v_dynamic,
		   v_old_period_set_id, v_old_period_interval_id, v_parent_sid
	  FROM deleg_plan dp
	  JOIN security.securable_object so ON dp.deleg_plan_sid = so.sid_id
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	-- create a new plan -- does security checks + audit
	v_new_plan_sid := NewDelegPlan(in_name, in_start_dtm, in_end_dtm,
		in_reminder_offset, in_period_set_id, in_period_interval_id, in_schedule_xml, v_dynamic, in_parent_sid);

	-- the bits newdelegplan doesn't do
	UPDATE deleg_plan
	   SET name_template = v_name_template,
		   notes = v_notes
	 WHERE deleg_plan_sid = v_new_plan_sid;

	INSERT INTO deleg_plan_role (deleg_plan_sid, role_sid, pos)
		SELECT v_new_plan_sid, role_sid, pos
		  FROM deleg_plan_role
		 WHERE deleg_plan_sid = in_deleg_plan_sid;

	INSERT INTO deleg_plan_region (deleg_plan_sid, region_sid)
		SELECT v_new_plan_sid, region_sid
		  FROM deleg_plan_region
		 WHERE deleg_plan_sid = in_deleg_plan_sid;

	IF NOT in_copy_template = csr_data_pkg.PLAN_TEMPLATE_NO THEN
		CopyDelegPlanCols(in_deleg_plan_sid, v_new_plan_sid, in_copy_template, in_template_delegation_sids, in_template_labels);
	END IF;

	-- Copy deleg_plan_date_schedule, if new delegation has the same interval
	-- Note: CopyDelegPlanSchedule currently cannot handle custom intervals
	IF v_old_period_set_id = in_period_set_id AND
	   v_old_period_interval_id = in_period_interval_id AND
	   v_old_period_set_id = 1 THEN
		
		-- Remove the default schedule for custom periods
		UNSEC_INT_DeleteDelegPlanDateSchedules(v_new_plan_sid);
		
		CopyDelegPlanSchedule(in_deleg_plan_sid, v_new_plan_sid);
	END IF;
	
	-- Copy permissions
	v_copy_dacl_id := security.acl_pkg.GetDACLIDForSID(in_deleg_plan_sid);
	v_new_dacl_id := security.acl_pkg.GetDACLIDForSID(v_new_plan_sid);
	security.acl_pkg.DeleteAllACEs(v_act_id, v_new_dacl_id);
	FOR s IN (
		SELECT acl_index, ace_type, ace_flags, sid_id, permission_set
		  FROM security.acl
		 WHERE acl_id = v_copy_dacl_id
	)
	LOOP
		security.acl_pkg.AddACE(v_act_id, v_new_dacl_id, s.acl_index, s.ace_type, s.ace_flags, s.sid_id, s.permission_set);
	END LOOP;
	
	-- Reset inherited permissions if parent is different from copied.
	IF NVL(in_parent_sid, GetDelegPlanRoot()) != v_parent_sid THEN
		security.securableobject_pkg.MoveSO(v_act_id, v_new_plan_sid, in_parent_sid, 0);
	END IF;
	
	RETURN v_new_plan_sid;
END;

PROCEDURE AmendDelegPlan(
	in_deleg_plan_sid               IN  deleg_plan.deleg_plan_sid%TYPE,
	in_dynamic                      IN  deleg_plan.dynamic%TYPE,
	in_last_applied_dynamic         IN  deleg_plan.last_applied_dynamic%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating a delegation plan');
	END IF;

	IF in_last_applied_dynamic IS NULL THEN
		UPDATE deleg_plan
		   SET dynamic = in_dynamic
		 WHERE deleg_plan_sid = in_deleg_plan_sid;
	ELSE
		UPDATE deleg_plan
			SET dynamic = in_dynamic, last_applied_dynamic = in_last_applied_dynamic
		 WHERE deleg_plan_sid = in_deleg_plan_sid;
	END IF;
END;

PROCEDURE DeleteDelegPlan(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_all				NUMBER
)
AS
	v_deleted						BOOLEAN;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting delegation plan:' || in_deleg_plan_sid);
	END IF;

	-- TODO: warn user that this will disconnect everything
	-- definitely don't do what it did before which was to delete everything
	/*
	FOR r IN (
		SELECT maps_to_root_deleg_sid
		  FROM deleg_plan_deleg_region
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), r.maps_to_root_deleg_sid);
	END LOOP;
	*/

	IF in_all = 1 THEN
		FOR r IN (
			SELECT DISTINCT dpdrd.maps_to_root_deleg_sid delegation_sid
			  FROM v$deleg_plan_deleg_region dpdr, deleg_plan_deleg_region_deleg dpdrd
			 WHERE dpdr.deleg_plan_sid = in_deleg_plan_sid
			   AND dpdr.app_sid = dpdrd.app_sid
			   AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
		)
		LOOP
			v_deleted := SafeDeleteDelegation(r.delegation_sid);
		END LOOP;
	END IF;

	-- sec obj helper code writes to audit log
	securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid);
END;


-- TODO: previous behaviour was to 'unhide' if already existed? Maybe make this a UI check/feature
-- "Do you want to add back what you had before, or create a new one"?
PROCEDURE AddDelegToPlan(
	in_deleg_plan_sid			IN	security_pkg.T_SID_ID,
	in_delegation_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_deleg_plan_col_deleg_id	deleg_plan_col_deleg.deleg_plan_col_deleg_id%TYPE;
	v_deleg_plan_col_id			deleg_plan_col.deleg_plan_col_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	INSERT INTO deleg_plan_col_deleg (deleg_plan_col_deleg_id, delegation_sid)
		VALUES (deleg_plan_col_deleg_id_seq.nextval, in_delegation_sid)
		RETURNING deleg_plan_col_deleg_id INTO v_deleg_plan_col_deleg_id;

	INSERT INTO deleg_plan_col (deleg_plan_col_Id, deleg_plan_sid, deleg_plan_col_deleg_id)
		VALUES (deleg_plan_col_id_seq.nextval, in_deleg_plan_sid, v_deleg_plan_col_deleg_id)
		RETURNING deleg_plan_col_id INTO v_deleg_plan_col_id;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Added delegation template with sid {0}',
		in_delegation_sid);

	OPEN out_cur FOR
		SELECT deleg_plan_col_id, label, type, object_sid
		  FROM v$deleg_plan_col
		 WHERE deleg_plan_col_id = v_deleg_plan_col_Id;
END;



PROCEDURE DeleteDelegPlanCol(
	in_deleg_plan_col_Id	IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	in_all					IN	NUMBER
)
AS
	v_deleg_plan_sid				security_pkg.T_SID_ID;
	v_deleg_sid						security_pkg.T_SID_ID;
	v_name							deleg_plan.name%TYPE;
	v_col_name						delegation.name%TYPE;
BEGIN
	SELECT deleg_plan_sid
	  INTO v_deleg_plan_sid
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || v_deleg_plan_sid);
	END IF;

	SELECT name
	  INTO v_name
	  FROM deleg_plan
	 WHERE deleg_plan_sid = v_deleg_plan_sid;

	SELECT label
	  INTO v_col_name
	  FROM v$deleg_plan_col
	 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

	IF in_all = 1 THEN
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), v_deleg_plan_sid, 'Deleting column "{0}" from plan "{1}"',
			v_col_name, v_name);

		FOR r IN (
		WITH roots AS (
			SELECT DISTINCT dpdrd.maps_to_root_deleg_sid maps_to_root_deleg_sid
			  FROM v$deleg_plan_deleg_region dpdr, deleg_plan_deleg_region_deleg dpdrd
			 WHERE dpdr.deleg_plan_col_id = in_deleg_plan_col_id
			   AND dpdr.app_sid = dpdrd.app_sid
			   AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
		), all_child_delegs AS (
			-- all delegations
				SELECT /*+MATERIALIZE*/ delegation_sid, parent_sid, level lvl
				  FROM delegation
				 START WITH delegation_sid IN (SELECT maps_to_root_deleg_sid FROM roots)
			   CONNECT BY PRIOR delegation_sid = parent_sid
		)
		SELECT x.delegation_sid, acd.lvl
		  FROM (
			-- get all nodes
			SELECT delegation_sid
			  FROM all_child_delegs
			 MINUS
			-- get all the nodes including and upwards from delegations that have sheets with data
			SELECT delegation_sid
			  FROM (
					-- delegations and whether or not they have sheets with data
					SELECT d.delegation_sid, d.parent_sid,
						   SUM(CASE WHEN sv.val_number IS NOT NULL OR NVL(LENGTH(sv.note),0)!=0 OR svf.sheet_value_id IS NOT NULL THEN 1 ELSE 0 END) sheet_value_cnt
					  FROM all_child_delegs d
					  -- constrain to regions/inds actually part of the delegation
					  LEFT JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
					  LEFT JOIN delegation_ind di ON dr.app_sid = di.app_sid AND d.delegation_sid = di.delegation_sid
					  -- ignore data for calculated inds
					  LEFT JOIN ind i ON di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
					  LEFT JOIN sheet s ON d.delegation_sid = s.delegation_sid
					  LEFT JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
					   AND sv.ind_sid = di.ind_sid AND sv.region_sid = dr.region_sid
					  LEFT JOIN sheet_value_file svf ON sv.sheet_value_id = svf.sheet_value_id
					 GROUP BY d.delegation_sid, d.parent_sid
			   )
			 START WITH delegation_sid IN (
				SELECT delegation_sid
				  FROM all_child_delegs
				 WHERE sheet_value_cnt > 0
			  )
			CONNECT BY PRIOR parent_sid = delegation_sid
		 )x
			-- join back to the full tree and sort depth descending (i.e. so we can
			-- delete from the bottom up)
			JOIN (
				-- for some reason level doesn't work if this block is swapped
				-- out for JOIN all_child_delegs acd -- i.e. level always returns
				-- 0 which breaks stuff, hence copying the select back in here
					SELECT delegation_sid, parent_sid, level lvl
					  FROM delegation
					 START WITH delegation_sid IN (SELECT maps_to_root_deleg_sid FROM roots)
				   CONNECT BY PRIOR delegation_sid = parent_sid
			) acd ON x.delegation_sid = acd.delegation_sid
		 ORDER BY acd.lvl DESC
		)
		LOOP
			securableobject_pkg.deleteso(SYS_CONTEXT('SECURITY','ACT'), r.delegation_sid);
		END LOOP;

		-- delegations
		DELETE FROM deleg_plan_deleg_region_deleg
		 WHERE deleg_plan_col_deleg_id IN (
			SELECT deleg_plan_col_deleg_id
			  FROM deleg_plan_col
			 WHERE deleg_plan_col_id = in_deleg_plan_col_id
		 );
		DELETE FROM deleg_plan_deleg_region
		 WHERE deleg_plan_col_deleg_id IN (
			SELECT deleg_plan_col_deleg_id
			  FROM deleg_plan_col
			 WHERE deleg_plan_col_id = in_deleg_plan_col_id
		 );

		-- date schedules
		DELETE FROM deleg_plan_date_schedule
		 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

		DELETE FROM sheet_date_schedule
		 WHERE delegation_date_schedule_id IN (
			SELECT delegation_date_schedule_id
			  FROM deleg_plan_date_schedule
			 WHERE deleg_plan_col_id = in_deleg_plan_col_id
		 );
			 
		DELETE FROM delegation_date_schedule
		 WHERE delegation_date_schedule_id IN (
			SELECT delegation_date_schedule_id
			  FROM deleg_plan_date_schedule
			 WHERE deleg_plan_col_id = in_deleg_plan_col_id
		 );

		-- this cascade deletes from deleg_plan_col
		DELETE FROM deleg_plan_col_deleg
		 WHERE deleg_plan_col_deleg_id IN (
			SELECT deleg_plan_col_deleg_id
			  FROM deleg_plan_col
			 WHERE deleg_plan_col_id = in_deleg_plan_col_id
		 );
	ELSE
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), v_deleg_plan_sid, 'Hiding column "{0}" on plan "{1}"',
			v_col_name, v_name);

		UPDATE deleg_plan_col
		   SET is_hidden = 1
		 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

	END IF;
END;

PROCEDURE MarkDeleteDelegPlanColRegion(
	in_deleg_plan_col_id		IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID
)
AS
	v_deleg_plan_col_deleg_id	deleg_plan_col_deleg.deleg_plan_col_deleg_id%TYPE;
	v_deleg_plan_col_deleg_name	delegation.name%TYPE;
	v_deleg_plan_sid			security_pkg.T_SID_ID;
BEGIN
	-- delete only if not created yet. If created then hide, i.e.
	-- we want to retain the link to any created delegations so we
	-- can clean them up when we "apply the plan" later
	
	SELECT d1.deleg_plan_sid, d1.deleg_plan_col_deleg_id, d3.description
	  INTO v_deleg_plan_sid, v_deleg_plan_col_deleg_id, v_deleg_plan_col_deleg_name
	  FROM deleg_plan_col d1
	  JOIN deleg_plan_col_deleg d2 ON d1.deleg_plan_col_deleg_id = d2.deleg_plan_col_deleg_id
	  JOIN v$delegation d3 ON d2.delegation_sid = d3.delegation_sid
	 WHERE deleg_plan_col_id = in_deleg_plan_col_id;
	
	-- clean up where not created.
	DELETE FROM deleg_plan_deleg_region dpdr
	 WHERE dpdr.deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
	   AND dpdr.region_sid = in_region_sid
	   AND NOT EXISTS (SELECT 1
						 FROM deleg_plan_deleg_region_deleg dpdrd
						WHERE dpdr.app_sid = dpdrd.app_sid
						  AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
						  AND dpdr.region_sid = dpdrd.region_sid);

	IF SQL%ROWCOUNT > 0 THEN
		-- It's never been created so just specify that it's been unmarked for creation
		-- (possibly not worth auditing this?)
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), v_deleg_plan_sid, 'Unmarked for creation - delegation template: {0} ({1}) and region ({2})',
			v_deleg_plan_col_deleg_name, v_deleg_plan_col_deleg_id, in_region_sid);
	END IF;

	-- flag for deletion where it has been created.
	UPDATE deleg_plan_deleg_region dpdr
	   SET dpdr.pending_deletion = csr_data_pkg.DELEG_PLAN_DELETE_ALL
	 WHERE dpdr.deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
	   AND dpdr.region_sid = in_region_sid
	   AND EXISTS (SELECT 1
					 FROM deleg_plan_deleg_region_deleg dpdrd
					WHERE dpdr.app_sid = dpdrd.app_sid
					  AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
					  AND dpdr.region_sid = dpdrd.region_sid);

	IF SQL%ROWCOUNT > 0 THEN
		-- It's been created so state that we're marking it for deletion.
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), v_deleg_plan_sid, 'Marked for deletion - delegation template: {0} ({1}) and region ({2})',
			v_deleg_plan_col_deleg_name, v_deleg_plan_col_deleg_id, in_region_sid);
	END IF;	
END;

-- only operates on delegations (not quick survey) ATM
PROCEDURE UpdateDelegPlanColRegion(
	in_deleg_plan_col_id		IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_region_selection			IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_tag_id					IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_region_type				IN	region.region_type%TYPE
)
AS
	v_deleg_plan_sid			security_pkg.T_SID_ID;
	v_deleg_plan_col_deleg_id	deleg_plan_col_deleg.deleg_plan_col_deleg_id%TYPE;
	v_old_region_selection		deleg_plan_deleg_region.region_selection%TYPE;
	v_old_tag_id				deleg_plan_deleg_region.tag_id%TYPE;
	v_old_region_type			region.region_type%TYPE;
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	IF in_region_type IS NOT NULL AND in_region_type < 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_REGION_TYPE, 'Region type cannot be negative');
	END IF;
	
	SELECT deleg_plan_sid
	  INTO v_deleg_plan_sid
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || v_deleg_plan_sid);
	END IF;

	SELECT deleg_plan_col_deleg_id
	  INTO v_deleg_plan_col_deleg_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_id = in_deleg_plan_col_id;

	IF in_region_selection IS NOT NULL THEN
		WITH r AS (
			SELECT region_sid, parent_sid
			  FROM region
			 START WITH region_sid IN (SELECT region_sid FROM deleg_plan_region WHERE deleg_plan_sid = v_deleg_plan_sid)
			CONNECT BY PRIOR region_sid = parent_sid
		)
		SELECT MIN(region_sid)
		  INTO v_region_sid
		  FROM deleg_plan_deleg_region dpdr
		 WHERE deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
		   AND pending_deletion = csr_data_pkg.DELEG_PLAN_NO_DELETE
		   AND EXISTS (
			SELECT NULL
			  FROM r
			 WHERE region_sid = dpdr.region_sid
			   AND region_sid != in_region_sid
			 START WITH region_sid = in_region_sid
		   CONNECT BY PRIOR parent_sid = region_sid
		 );
	 
		IF v_region_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_UNEXPECTED, 'Parent region selected cannot select child region.');
		END IF;
	
		BEGIN
			INSERT INTO deleg_plan_deleg_region (deleg_plan_col_deleg_id, region_sid, region_selection, tag_id, region_type)
			VALUES (v_deleg_plan_col_deleg_id, in_region_sid, in_region_selection, in_tag_id, in_region_type);
			
			csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
				SYS_CONTEXT('SECURITY', 'APP'), v_deleg_plan_sid, 'Marked for creation - delegation template ({0}) and region ({1})',
				v_deleg_plan_col_deleg_id, in_region_sid);
			
			-- Remove any selected child regions
			FOR r IN (
				SELECT region_sid
				 FROM deleg_plan_deleg_region dpdr
				WHERE deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
				  AND EXISTS (
					SELECT NULL
					  FROM region
					 WHERE region_sid = dpdr.region_sid
					 START WITH parent_sid = in_region_sid
				   CONNECT BY PRIOR region_sid = parent_sid
				 )
			) LOOP
				MarkDeleteDelegPlanColRegion(in_deleg_plan_col_id, r.region_sid);
			END LOOP;
			
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- have they changed the region selection? i.e. do we need to delete existing stuff?
				SELECT region_selection, tag_id, region_type
				  INTO v_old_region_selection, v_old_tag_id, v_old_region_type
				  FROM deleg_plan_deleg_region
				 WHERE deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
				   AND region_sid = in_region_sid
				   FOR UPDATE; -- lock it just in case

				IF null_pkg.ne(v_old_region_selection, in_region_selection) 
				OR null_pkg.ne(v_old_tag_id, in_tag_id)  
				OR null_pkg.ne(v_old_region_type, in_region_type)
				THEN
					-- tell it to delete what's there and then recreate
					-- also store the region selection
					UPDATE deleg_plan_deleg_region
					   SET pending_deletion = csr_data_pkg.DELEG_PLAN_DELETE_CREATE,
						   region_selection = in_region_selection,
						   tag_id = in_tag_id,
						   region_type = in_region_type
					 WHERE deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
					   AND region_sid = in_region_sid;
				ELSE
					-- store the region selection
					UPDATE deleg_plan_deleg_region
					   SET region_selection = in_region_selection,
						   tag_id = in_tag_id,
						   region_type = in_region_type,
						   pending_deletion = csr_data_pkg.DELEG_PLAN_NO_DELETE
					 WHERE deleg_plan_col_deleg_id = v_deleg_plan_col_deleg_id
					   AND region_sid = in_region_sid
					   AND pending_deletion NOT IN (csr_data_pkg.DELEG_PLAN_NO_DELETE, csr_data_pkg.DELEG_PLAN_DELETE_CREATE);
				END IF;
		END;
	ELSE
		MarkDeleteDelegPlanColRegion(in_deleg_plan_col_id, in_region_sid);
	END IF;
END;


PROCEDURE SetPlanRoles(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_role_sids		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Roles updated');

	DELETE FROM deleg_plan_role
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	FOR i IN in_role_sids.first .. in_role_sids.last LOOP
		INSERT INTO deleg_plan_role (deleg_plan_sid, role_sid, pos)
			VALUES (in_deleg_plan_sid, in_role_sids(i), i);

		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Roles added: {0}', in_role_sids(i));
	END LOOP;

END;


PROCEDURE SetPlanRegions(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS
)
AS
	v_name				deleg_plan.name%TYPE;
	t					security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_region_sids);

	SELECT name
	  INTO v_name
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	-- delete old stuff
	FOR r IN (
		SELECT r.region_sid, r.description
		  FROM v$region r
		 WHERE region_sid IN (
			SELECT region_sid
			  FROM deleg_plan_region
			 WHERE deleg_plan_sid = in_deleg_plan_sid
			  MINUS
			 SELECT column_value FROM TABLE(t)
		 )
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Removing region "{0}" from plan "{1}"',
			r.description, v_name);

		DELETE FROM deleg_plan_region
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND region_sid = r.region_sid;
	END LOOP;

	-- insert new stuff
	FOR r IN (
		SELECT region_sid, description
		  FROM v$region
		 WHERE region_sid IN (
			SELECT column_value
			  FROM TABLE(t)
			 MINUS
			SELECT region_sid
			  FROM deleg_plan_region
			 WHERE deleg_plan_sid = in_deleg_plan_sid
		)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Adding region "{0}" to plan "{1}"',
			r.description, v_name);

		INSERT INTO deleg_plan_region (deleg_plan_sid, region_sid)
		VALUES (in_deleg_plan_sid, r.region_sid);
	END LOOP;
END;


PROCEDURE GetPlanUsers(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN out_cur FOR
		-- includes inactive regions
		SELECT rrm.region_sid, dpr.pos, rrm.user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM deleg_plan_role dpr
		  JOIN region_role_member rrm ON dpr.role_sid = rrm.role_sid AND dpr.app_sid = rrm.app_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		   AND dpr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.region_sid IN (
				SELECT region_sid FROM region START WITH region_sid = in_region_sid CONNECT BY PRIOR region_sid = parent_sid
		   )
		   --fix to stop inheritance from trashed objects, fix to remove entries from region_role_member may be better.
		  AND rrm.inherited_from_sid NOT IN (
			SELECT region_sid
			  FROM region
			 START WITH parent_sid = (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   CONNECT BY PRIOR region_sid = parent_sid AND PRIOR app_sid = app_sid
		  )
		 ORDER BY region_sid, dpr.pos, cu.full_name; -- order matters!
END;

-- XXX: doesn't support secondary region trees
PROCEDURE GetChildRegions(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN out_cur FOR
		SELECT sid, description, is_leaf, class_name, deleg_plan_col_id, NVL(has_manual_amends,0) has_manual_amends, region_selection, tag_id, region_type
		  FROM (
				SELECT r.region_sid sid, r.description, rt.class_name, dpdr.deleg_plan_col_id,
					   (SELECT MAX(has_manual_amends)
						  FROM deleg_plan_deleg_region_deleg dpdrd
						 WHERE dpdr.app_sid = dpdrd.app_sid
						   AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
						   AND dpdr.region_sid = dpdrd.region_sid) has_manual_amends,
						dpdr.region_selection, dpdr.tag_id, dpdr.region_type,
						CASE
							WHEN EXISTS (SELECT null FROM region child WHERE child.parent_sid = r.region_sid)
							THEN 0 ELSE 1
						END is_leaf
				  FROM v$region r
				  JOIN region_type rt ON r.region_type = rt.region_type
				  LEFT JOIN v$deleg_plan_deleg_region dpdr ON r.region_sid = dpdr.region_sid
				   AND dpdr.deleg_plan_sid = in_deleg_plan_sid
				   -- we want stuff that's not being deleted. delete/create is ok as it'll still exist
				   AND pending_deletion IN (csr_data_pkg.DELEG_PLAN_NO_DELETE, csr_data_pkg.DELEG_PLAN_DELETE_CREATE)
				 WHERE r.parent_sid = in_parent_sid
				   AND r.active = 1
				   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		)
		 ORDER BY description, sid; -- ordering by sid is critical (description first as looks nicer)
END;

PROCEDURE GetPlanCols(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	out_col_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN out_col_cur FOR
		SELECT deleg_plan_col_id, label, type, object_sid
		  FROM v$deleg_plan_col
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND is_hidden = 0;
END;

PROCEDURE GetPlanColsDelegs(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	out_col_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN out_col_cur FOR
		SELECT DISTINCT object_sid, label
		  FROM v$deleg_plan_col
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND is_hidden = 0;
END;

PROCEDURE GetPlanDetails(
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	out_plan_cur					OUT	SYS_REFCURSOR,
	out_col_cur						OUT	SYS_REFCURSOR,
	out_root_regions_cur 			OUT	SYS_REFCURSOR,
	out_roles_cur					OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR,
	out_users_cur					OUT	SYS_REFCURSOR,
	out_dates_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN out_plan_cur FOR
		SELECT dp.deleg_plan_sid, dp.name, dp.start_dtm, dp.end_dtm, dp.reminder_offset,
			   dp.period_set_id, dp.period_interval_id,
			   dp.schedule_xml,
			   dp.dynamic, dp.last_applied_dtm,
			   dp.last_applied_dynamic
		  FROM deleg_plan dp
		 WHERE dp.deleg_plan_sid = in_deleg_plan_sid;

	GetPlanCols(in_deleg_plan_sid, out_col_cur);

	OPEN out_root_regions_cur FOR
		SELECT r.region_sid sid, r.description
		  FROM deleg_plan_region dpr
		  JOIN v$region r ON dpr.region_sid = r.region_sid AND dpr.app_sid = r.app_sid
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid;

	OPEN out_roles_cur FOR
		SELECT dpr.role_sid, r.name, dpr.pos
		  FROM deleg_plan_role dpr
		  JOIN role r ON dpr.role_sid = r.role_sid AND dpr.app_sid = r.app_sid
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		 ORDER BY dpr.pos;

	INSERT INTO region_list (region_sid)
		-- all regions in plan with ancestor in plan
		SELECT r.region_sid
		  FROM (
				-- all regions in plan with ancestor
				SELECT parent_sid ancestor_sid, CONNECT_BY_ROOT region_sid region_sid, app_sid
				  FROM region
				 START WITH region_sid IN (
						SELECT region_sid
						  FROM deleg_plan_region
						 WHERE deleg_plan_sid = in_deleg_plan_sid
						   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
				CONNECT BY PRIOR parent_sid = region_sid
		  ) r
		  JOIN deleg_plan_region dpr ON r.ancestor_sid = dpr.region_sid AND r.app_sid = dpr.app_sid
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		   AND dpr.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_regions_cur FOR
		-- rather convoluted but if you have region tree A->B->C, and you include A and C then it only shows you A
		SELECT sid, description, class_name, is_leaf, deleg_plan_col_id, NVL(has_manual_amends,0) has_manual_amends, region_selection, tag_id, region_type
		  FROM (
				-- get all root regions
				SELECT r.region_sid sid, r.description, rt.class_name, dpdr.deleg_plan_col_id,
					   (SELECT MAX(has_manual_amends)
						  FROM deleg_plan_deleg_region_deleg dpdrd
						 WHERE dpdr.app_sid = dpdrd.app_sid
						   AND dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
						   AND dpdr.region_sid = dpdrd.region_sid) has_manual_amends,
						dpdr.region_selection, dpdr.tag_id, dpdr.region_type,
						CASE
							WHEN EXISTS (SELECT null FROM region child WHERE child.parent_sid = r.region_sid)
							THEN 0 ELSE 1
						END is_leaf
				  FROM v$region r
				  JOIN region_type rt ON r.region_type = rt.region_type
				  JOIN deleg_plan_region dpr ON r.region_sid = dpr.region_sid AND r.app_sid = dpr.app_sid
				  LEFT JOIN v$deleg_plan_deleg_region dpdr
				   ON r.region_sid = dpdr.region_sid
				   AND dpdr.deleg_plan_sid = in_deleg_plan_sid
				   AND pending_deletion IN (csr_data_pkg.DELEG_PLAN_NO_DELETE, csr_data_pkg.DELEG_PLAN_DELETE_CREATE)
				 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
				   AND dpr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND dpr.region_sid NOT IN (
						SELECT region_sid
						  FROM region_list)
			  )
		 ORDER BY description, sid; -- ordering by sid is critical (description first as looks nicer)

	OPEN out_users_cur FOR
		-- includes inactive regions
		SELECT rrm.region_sid, dpr.pos, rrm.user_sid, cu.full_name, cu.email, ut.account_enabled active
		  FROM deleg_plan_role dpr
		  JOIN region_role_member rrm ON dpr.role_sid = rrm.role_sid AND dpr.app_sid = rrm.app_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		   AND dpr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.region_sid IN (
				SELECT dpr.region_sid
				  FROM deleg_plan_region dpr
				 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		   )
		   -- fix to stop inheritance from trashed objects, fix to remove entries from region_role_member may be better.
		   AND rrm.inherited_from_sid NOT IN (
				SELECT region_sid
				  FROM region
					   START WITH parent_sid = (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
					   CONNECT BY PRIOR region_sid = parent_sid AND PRIOR app_sid = app_sid
		   )
		 ORDER BY region_sid, dpr.pos, cu.full_name; -- order matters!

	OPEN out_dates_cur FOR
		SELECT dpds.role_sid, dpds.deleg_plan_col_id, dpds.schedule_xml, dpds.reminder_offset, 
			   dpds.delegation_date_schedule_id, sds.start_dtm, sds.creation_dtm, sds.submission_dtm, sds.reminder_dtm
		  FROM deleg_plan_date_schedule dpds
		  LEFT JOIN sheet_date_schedule sds ON sds.app_sid = dpds.app_sid AND sds.delegation_date_schedule_id = dpds.delegation_date_schedule_id
		 WHERE dpds.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND dpds.deleg_plan_sid = in_deleg_plan_sid
		 ORDER BY dpds.role_sid, dpds.deleg_plan_col_id, sds.start_dtm;
END;

FUNCTION CopyDelegation(
	in_deleg_plan_sid		IN	security_pkg.T_SID_ID,
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_selection		IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_tag_id				IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_region_type			IN	region.region_type%TYPE,
	out_overlapping_sid		OUT	security_pkg.T_SID_ID,
	out_overlap_reg_cur 	OUT	delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR
) RETURN security_pkg.T_SID_ID
AS
	v_deleg_sid						security_pkg.T_SID_ID;
	v_start_dtm						deleg_plan.start_dtm%TYPE;
	v_end_dtm						deleg_plan.end_dtm%TYPE;
	v_period_set_id					deleg_plan.period_set_id%TYPE;
	v_period_interval_id			deleg_plan.period_interval_id%TYPE;
	v_reminder_offset				deleg_plan.reminder_offset%TYPE;
	v_schedule_xml					deleg_plan.schedule_xml%TYPE;
	v_inds							security_pkg.T_SID_IDS;
	v_regions						security_pkg.T_SID_IDS;
	v_regions_table					security.T_SID_TABLE;
	v_overlaps						delegation_pkg.T_OVERLAP_DELEG_CUR;
	v_overlap_inds					delegation_pkg.T_OVERLAP_DELEG_INDS_CUR;
	v_overlap_regions				delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
	v_overlap_rec					delegation_pkg.T_OVERLAP_DELEG_REC;
BEGIN
	out_overlapping_sid := null;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	-- decide which regions to add in
	-- add in the region(s)
	CASE
		WHEN in_region_selection = csr_data_pkg.DELEG_PLAN_SEL_S_REGION THEN
			SELECT r.region_sid
			  BULK COLLECT INTO v_regions
			  FROM region r
			 WHERE r.active = 1
			   AND r.region_sid = in_region_sid;

		WHEN in_region_selection = csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT THEN
			SELECT r.region_sid
			  BULK COLLECT INTO v_regions
			  FROM region r
			 WHERE connect_by_isleaf = 1
			   AND (in_region_type IS NULL OR r.region_type = in_region_type)
			   AND (in_tag_id IS NULL OR EXISTS (
						SELECT NULL
						  FROM region_tag rt
						 WHERE rt.region_sid = r.region_sid
						   AND rt.tag_id = in_tag_id))
			 START WITH r.active = 1 AND r.parent_sid = in_region_sid
		   CONNECT BY r.active = 1 AND PRIOR r.app_sid = r.app_sid AND PRIOR r.region_sid = r.parent_sid;

		WHEN in_region_selection = csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT THEN
			WITH region_tree AS (
					SELECT r.region_sid, sys_connect_by_path(region_sid, '/') path, connect_by_isleaf is_leaf 
					  FROM region r
					 WHERE (in_region_type IS NULL OR r.region_type = in_region_type)
					   AND (in_tag_id IS NULL OR EXISTS (
							SELECT 1
							  FROM region_tag rt
							 WHERE rt.region_sid = r.region_sid
							   AND rt.tag_id = in_tag_id
						))
					 START WITH r.active = 1 AND r.region_sid = in_region_sid
				   CONNECT BY r.active = 1 AND PRIOR r.app_sid = r.app_sid AND PRIOR r.region_sid = r.parent_sid
				 )
				 SELECT region_sid
				   BULK COLLECT INTO v_regions
				   FROM region_tree rt 
				  WHERE NOT EXISTS (
							SELECT NULL
							  FROM region_tree
							 WHERE path like rt.path||'/%');
		WHEN in_region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_M_REGION, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT) THEN
			v_regions(1) := in_region_sid; -- we've already decided to apply, so just use the passed in region
	END CASE;
	
	IF v_regions.COUNT = 0 THEN 
		RETURN NULL;
	END IF;
	
	SELECT start_dtm, end_dtm, reminder_offset, period_set_id, period_interval_id,
		   REPLACE(schedule_xml, 'recurrence', 'recurrences')
	  INTO v_start_dtm, v_end_dtm, v_reminder_offset, v_period_set_id, v_period_interval_id,
		   v_schedule_xml
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT ind_sid
	  BULK COLLECT INTO v_inds
	  FROM delegation_ind
	 WHERE delegation_sid = in_delegation_sid;
	
	delegation_pkg.ExFindOverlaps(
		in_act_id		 				=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_delegation_sid				=> NULL,
		in_ignore_self					=> 1,
		in_parent_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_start_dtm					=> v_start_dtm,
		in_end_dtm						=> v_end_dtm,
		in_indicators_list				=> v_inds,
		in_regions_list					=> v_regions,
		out_deleg_cur					=> v_overlaps,
		out_deleg_inds_cur				=> v_overlap_inds,
		out_deleg_regions_cur			=> out_overlap_reg_cur
	);
	
	FETCH v_overlaps INTO v_overlap_rec;
	
	IF v_overlaps%FOUND THEN
		out_overlapping_sid := v_overlap_rec.delegation_sid;
		--security_pkg.debugmsg('delegation would overlap with '||v_overlap_rec.name||','||v_overlap_rec.delegation_sid||' - skipping');
		RETURN NULL;
	END IF;
	-- copy delegation without regions
	delegation_pkg.CopyDelegation(SYS_CONTEXT('SECURITY', 'ACT'), in_delegation_sid, NULL, v_deleg_sid);
	-- insert regions
	v_regions_table := security_pkg.SidArrayToTable(v_regions);
	INSERT INTO delegation_region
		(delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility)
		SELECT v_deleg_sid, r.region_sid, 0, rownum, r.region_sid, 'SHOW'
		  FROM (SELECT r.region_sid
				  FROM v$region r, TABLE(v_regions_table)
				 WHERE r.region_sid = column_value
				 ORDER BY description) r;

	delegation_pkg.UpdateDates(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_sid, v_start_dtm, v_end_dtm);
	SetPeriod(v_deleg_sid, v_period_set_id, v_period_interval_id, 1, 0);
	
	UPDATE delegation
	   SET reminder_offset = v_reminder_offset, schedule_xml = v_schedule_xml
	 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation
			 START WITH delegation_sid = v_deleg_sid
			CONNECT BY PRIOR delegation_sid = parent_sid
	);
	
	FOR r IN (
		SELECT sheet_id
		  FROM sheet
		 WHERE delegation_sid = v_deleg_sid
	)
	LOOP
		sheet_pkg.deleteSheet(r.sheet_id);
	END LOOP;

	RETURN v_deleg_sid;
END;


PROCEDURE RaiseUpdateSheetAlertForDeleg(
	in_delegation_sid				IN	delegation.delegation_sid%TYPE
)
AS
	TYPE t_sheets_table				IS TABLE OF sheet.sheet_id%TYPE;
	v_all_updated_sheets			t_sheets_table := t_sheets_table();
	v_sheets						SYS_REFCURSOR;
	v_sheet_id						sheet.sheet_id%TYPE;
BEGIN
	delegation_pkg.GetSheetIds(in_delegation_sid, v_sheets);

	IF v_sheets%ISOPEN THEN
		LOOP
			FETCH v_sheets INTO v_sheet_id;
			EXIT WHEN v_sheets%NOTFOUND;
			v_all_updated_sheets.extend(1);
			v_all_updated_sheets(v_all_updated_sheets.LAST) := v_sheet_id;
		END LOOP;
	END IF;

	--security_pkg.debugmsg('v_all_updated_sheets = '||v_all_updated_sheets.COUNT);
	IF v_all_updated_sheets.COUNT > 0 THEN
		FOR i IN v_all_updated_sheets.FIRST..v_all_updated_sheets.LAST LOOP
			sheet_pkg.RaisePlanSheetUpdatedAlert(v_all_updated_sheets(i));
		END LOOP;
	END IF;
END;

PROCEDURE ProcessSyncDelegWithMasterJob(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE,
	out_result						OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE
)
AS
	v_total_delegations				NUMBER;
	v_done							NUMBER := 0;
	v_deleg_changed					NUMBER := 0;
	v_overlaps						NUMBER := 0;
	v_updated_sheets				SYS_REFCURSOR;
	TYPE t_sheets_table				IS TABLE OF sheet.sheet_id%TYPE;
	v_all_updated_sheets			t_sheets_table := t_sheets_table();

	v_deleg_plan_sid				deleg_plan.deleg_plan_sid%TYPE;
	v_sheet_id						sheet.sheet_id%TYPE;
	v_start_dtm						sheet.start_dtm%TYPE;
	v_end_dtm						sheet.end_dtm%TYPE;
	v_submission_dtm				sheet.submission_dtm%TYPE;
	v_reminder_dtm					sheet.reminder_dtm%TYPE;
	v_editing_url					delegation.editing_url%TYPE;
	v_overlap_reg_cur 				delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
	v_overlap_reg_rec				delegation_pkg.T_OVERLAP_DELEG_REGIONS_REC;

BEGIN
	-- count how much work we're going to do for the job progress monitor
	SELECT COUNT(*)
	  INTO v_total_delegations
	  FROM delegation
		   START WITH delegation_sid IN (
				SELECT dpdrd.maps_to_root_deleg_sid
				  FROM deleg_plan_col_deleg dpcd
				  JOIN deleg_plan_deleg_region dpdr ON dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpdr.region_sid = dpdrd.region_sid
				 WHERE dpcd.delegation_sid = in_delegation_sid)
		   CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid;

	-- no security check, because they are done in delegation_pkg.SynchChildWithParent
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 START WITH delegation_sid IN (
				SELECT dpdrd.maps_to_root_deleg_sid
				  FROM deleg_plan_col_deleg dpcd
				  JOIN deleg_plan_deleg_region dpdr ON dpcd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
				  JOIN deleg_plan_deleg_region_deleg dpdrd ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id AND dpdr.region_sid = dpdrd.region_sid
				 WHERE dpcd.delegation_sid = in_delegation_sid
				   --AND dpdrd.has_manual_amends = 0
		)
		CONNECT BY PRIOR delegation_sid = parent_sid AND PRIOR app_sid = app_sid
	)
	LOOP
		--security_pkg.debugmsg('applying plan to '||r.delegation_sid);
		-- TODO: does this fix up conditions? i.e. 'synchwithparent' if it really was just the parent
		-- wouldn't need to worry about this since conditions are stored at the delegation root. In our
		-- case though we're synching with a delegation that isn't above this delegation in the hierarchy.
		delegation_pkg.SynchChildWithParent(SYS_CONTEXT('SECURITY', 'ACT'),
			delegation_pkg.GetRootDelegationSid(in_delegation_sid), r.delegation_sid,
			v_deleg_changed, v_overlaps, v_overlap_reg_cur);
			
		IF v_overlaps > 0 THEN
			out_result := 'Completed with errors, overlaps found.';
		END IF;
		
		WHILE TRUE
			LOOP
				FETCH v_overlap_reg_cur INTO v_overlap_reg_rec;
				EXIT WHEN v_overlap_reg_cur%NOTFOUND;

				IF v_overlap_reg_cur%FOUND THEN
					INSERT INTO temp_deleg_plan_overlap
							(overlapping_deleg_sid, overlapping_region_sid, tpl_deleg_sid, is_sync_deleg)
					VALUES
							(v_overlap_reg_rec.delegation_sid, v_overlap_reg_rec.region_sid, in_delegation_sid, 1);
				END IF;
		END LOOP;


		v_done := v_done + 1;
		batch_job_pkg.SetProgress(in_batch_job_id, v_done, v_total_delegations);

		IF v_deleg_changed = 1 THEN
			RaiseUpdateSheetAlertForDeleg(r.delegation_sid);
		END IF;

		-- commit to reduce locking -- this may take a long time
		COMMIT;
	END LOOP;
END;

PROCEDURE INTERNAL_GetDateSchedule(
	in_deleg_plan_sid			IN	deleg_plan.deleg_plan_sid%TYPE,
	in_role_sid					IN	role.role_sid%TYPE,
	in_deleg_plan_col_id		IN	deleg_plan_col.deleg_plan_col_id%TYPE,
	out_schedule_xml			OUT delegation.schedule_xml%TYPE,
	out_reminder_offset			OUT	delegation.reminder_offset%TYPE,
	out_date_schedule_id		OUT	deleg_plan_date_schedule.delegation_date_schedule_id%TYPE
)
AS
	CURSOR c(v_role_sid role.role_sid%TYPE, v_deleg_plan_col_id deleg_plan_col.deleg_plan_col_id%TYPE) IS
		SELECT schedule_xml, reminder_offset, delegation_date_schedule_id
		  FROM deleg_plan_date_schedule
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND deleg_plan_sid = in_deleg_plan_sid
		   AND ((v_role_sid IS NULL AND role_sid IS NULL) OR role_sid = v_role_sid)
		   AND ((v_deleg_plan_col_id IS NULL AND deleg_plan_col_id IS NULL) OR deleg_plan_col_id = v_deleg_plan_col_id);
	r	c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	OPEN c(in_role_sid, in_deleg_plan_col_id);
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		CLOSE c;
		OPEN c(in_role_sid, NULL);
		FETCH c INTO r;
		IF c%NOTFOUND THEN
			CLOSE c;
			OPEN c(NULL, in_deleg_plan_col_id);
			FETCH c INTO r;
			IF c%NOTFOUND THEN
				CLOSE c;
				OPEN c(NULL, NULL);
				FETCH c INTO r;
			END IF;
		END IF;
	END IF;
	CLOSE c;

	out_schedule_xml := r.schedule_xml;
	out_reminder_offset := r.reminder_offset;
	out_date_schedule_id := r.delegation_date_schedule_id;

	IF out_schedule_xml IS NULL AND out_reminder_offset IS NULL THEN
		-- use master schedule XML
		SELECT schedule_xml, reminder_offset
		  INTO out_schedule_xml, out_reminder_offset
		  FROM deleg_plan
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND deleg_plan_sid = in_deleg_plan_sid;
	END IF;

	out_schedule_xml := REPLACE(out_schedule_xml, 'recurrence', 'recurrences');
END;

PROCEDURE ApplyPlanToRegion(
	in_deleg_plan_sid				IN	deleg_plan.deleg_plan_sid%TYPE,
	in_is_dynamic_plan				IN	NUMBER,
	in_name_template				IN	deleg_plan.name_template%TYPE,
	in_deleg_plan_col_deleg_id		IN	deleg_plan_col_deleg.deleg_plan_col_deleg_id%TYPE,
	in_master_delegation_name		IN	delegation.name%TYPE,
	in_maps_to_root_deleg_sid		IN	deleg_plan_deleg_region_deleg.maps_to_root_deleg_sid%TYPE,
	in_apply_to_region_sid			IN	deleg_plan_deleg_region_deleg.applied_to_region_sid%TYPE,
	in_apply_to_region_lookup_key	IN	region.lookup_key%TYPE,
	in_apply_to_region_desc			IN	region_description.description%TYPE,
	in_plan_region_sid				IN	deleg_plan_deleg_region.region_sid%TYPE,
	in_tpl_delegation_sid			IN	deleg_plan_col_deleg.delegation_sid%TYPE,
	in_region_selection				IN	deleg_plan_deleg_region.region_selection%TYPE,
	in_region_type					IN	region.region_type%TYPE,
	in_tag_id						IN	deleg_plan_deleg_region.tag_id%TYPE,
	in_overwrite_dates				IN	NUMBER DEFAULT 0,
	out_created						IN OUT NUMBER
)
AS
	v_root_deleg_sid        		security_pkg.T_SID_ID;
	v_deleg_sid						security_pkg.T_SID_ID;
	v_parent_deleg_sid				security_pkg.T_SID_ID;
	v_xcheck_region_cnt				NUMBER(10);
	v_xcheck_region_sid				security_pkg.T_SID_ID;
	v_cnt							NUMBER(10);
	v_is_fully_delegated			NUMBER;
	CURSOR cd(in_delegation_sid	security_pkg.T_SID_ID) IS
		SELECT app_sid, name, period_set_id, period_interval_id, schedule_xml, note,
			   master_delegation_sid, grid_xml, editing_url, section_xml, show_aggregate
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
	rd								cd%ROWTYPE;
	v_user_list             		VARCHAR2(2000);
	v_name							delegation.name%TYPE;
	v_overlapping_sid				security_pkg.T_SID_ID;
	v_role_sid						role.role_sid%TYPE;
	v_deleg_plan_col_id				deleg_plan_col.deleg_plan_col_id%TYPE;
	v_schedule_xml					delegation.schedule_xml%TYPE;
	v_reminder_offset				delegation.reminder_offset%TYPE;
	v_date_schedule_id				deleg_plan_date_schedule.delegation_date_schedule_id%TYPE;
	v_region_on_deleg				NUMBER;
	v_non_top_deleg_sid				delegation.delegation_sid%TYPE;
	v_current_parent_deleg_sid		region.region_sid%TYPE;
	v_deleted						BOOLEAN;

	v_sheet_id						sheet.sheet_id%TYPE;
	v_start_dtm						sheet.start_dtm%TYPE;
	v_end_dtm						sheet.end_dtm%TYPE;
	v_submission_dtm				sheet.submission_dtm%TYPE;
	v_reminder_dtm					sheet.reminder_dtm%TYPE;
	v_editing_url					delegation.editing_url%TYPE;

	v_updated_deleg_ids				security.T_SID_TABLE := security.T_SID_TABLE();

	TYPE t_new_sheets_table			IS TABLE OF sheet.sheet_id%TYPE;
	v_all_new_sheets		 			t_new_sheets_table := t_new_sheets_table();
	v_all_updated_sheets		 		t_new_sheets_table := t_new_sheets_table();

	v_new_sheets					SYS_REFCURSOR;
	v_updated_sheets				SYS_REFCURSOR;
	v_overlap_reg_cur 				delegation_pkg.T_OVERLAP_DELEG_REGIONS_CUR;
	v_dele_reg_rec					delegation_pkg.T_OVERLAP_DELEG_REGIONS_REC;
	v_inds							security_pkg.T_SID_IDS;
	v_regions						security_pkg.T_SID_IDS;
	v_overlaps						delegation_pkg.T_OVERLAP_DELEG_CUR;
	v_overlap_inds					delegation_pkg.T_OVERLAP_DELEG_INDS_CUR;
	v_overlap_rec					delegation_pkg.T_OVERLAP_DELEG_REC;
BEGIN
	--security_pkg.debugmsg('applying plan with sid '||in_deleg_plan_sid||
	--	' to deleg sid '||in_maps_to_root_deleg_sid||', region sid '||in_apply_to_region_sid||
	--	', plan region sid '||in_plan_region_sid||', region selection '||in_region_selection);

	SELECT deleg_plan_col_id
	  INTO v_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_col_deleg_id = in_deleg_plan_col_deleg_id;

	-- get top level role
	BEGIN
		SELECT MIN(role_sid)
		  INTO v_role_sid
		  FROM deleg_plan_role
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND pos = 1;
	EXCEPTION
	  WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(-20001, 'No roles for plan '||in_deleg_plan_sid);
	END;

	 -- create root delegation if needed
	IF in_maps_to_root_deleg_sid IS NULL THEN
		--security_pkg.debugmsg('copy deleg for plan '||in_deleg_plan_sid||' tpl '||in_tpl_delegation_sid||' apply to '||in_apply_to_region_sid||' sel '||in_region_selection||' tag '||in_tag_id);
		out_created := 1;

		v_root_deleg_sid := CopyDelegation(in_deleg_plan_sid, in_tpl_delegation_sid, in_apply_to_region_sid, in_region_selection, 
										   in_tag_id, in_region_type, v_overlapping_sid,v_overlap_reg_cur);
		
		IF v_root_deleg_sid IS NULL THEN
			-- Nothing to create
			out_created := 0;
			IF v_overlapping_sid IS NOT NULL THEN
				-- Take note if due to overlap
				WHILE TRUE
					LOOP
						FETCH v_overlap_reg_cur INTO v_dele_reg_rec;
						 EXIT WHEN v_overlap_reg_cur%NOTFOUND;

						IF v_overlap_reg_cur%FOUND THEN
							INSERT INTO temp_deleg_plan_overlap
									(overlapping_deleg_sid, overlapping_region_sid, applied_to_region_sid, tpl_deleg_sid, is_sync_deleg, deleg_plan_sid, deleg_plan_col_deleg_id, region_sid)
							VALUES
									(v_dele_reg_rec.delegation_sid, v_dele_reg_rec.region_sid, in_apply_to_region_sid, in_tpl_delegation_sid, 0, in_deleg_plan_sid, in_deleg_plan_col_deleg_id,in_plan_region_sid);
						END IF;
					END LOOP;
			END IF;
			RETURN;
		END IF;

		INTERNAL_GetDateSchedule(in_deleg_plan_sid, v_role_sid, v_deleg_plan_col_id, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
		UpdateDateSchedule(SYS_CONTEXT('SECURITY', 'ACT'), v_root_deleg_sid, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
		
		delegation_pkg.CreateSheetsForDelegation(v_root_deleg_sid, 0, v_new_sheets);

		INSERT INTO deleg_plan_deleg_region_deleg
			(deleg_plan_col_deleg_id, region_sid, applied_to_region_sid, maps_to_root_deleg_sid)
		VALUES
			(in_deleg_plan_col_deleg_id, in_plan_region_sid, in_apply_to_region_sid, v_root_deleg_sid);
	ELSE
		v_root_deleg_sid := in_maps_to_root_deleg_sid;
		   
		IF in_region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT) THEN
			
			SELECT ind_sid
			  BULK COLLECT INTO v_inds
			  FROM delegation_ind
			 WHERE delegation_sid = v_root_deleg_sid;
			 
			SELECT region_sid
			  BULK COLLECT INTO v_regions
			  FROM delegation_region
			 WHERE delegation_sid = v_root_deleg_sid;
			
			SELECT start_dtm, end_dtm
			  INTO v_start_dtm, v_end_dtm
			  FROM deleg_plan
			 WHERE deleg_plan_sid = in_deleg_plan_sid
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			
			delegation_pkg.ExFindOverlaps(
				in_act_id		 				=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_delegation_sid				=> NULL,
				in_ignore_self					=> 1,
				in_parent_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
				in_start_dtm					=> v_start_dtm,
				in_end_dtm						=> v_end_dtm,
				in_indicators_list				=> v_inds,
				in_regions_list					=> v_regions,
				out_deleg_cur					=> v_overlaps,
				out_deleg_inds_cur				=> v_overlap_inds,
				out_deleg_regions_cur			=> v_overlap_reg_cur
			);

			FETCH v_overlaps INTO v_overlap_rec;

			IF v_overlaps%FOUND THEN
				WHILE TRUE
				LOOP
					FETCH v_overlap_reg_cur INTO v_dele_reg_rec;
					 EXIT WHEN v_overlap_reg_cur%NOTFOUND;

					IF v_overlap_reg_cur%FOUND THEN
						INSERT INTO temp_deleg_plan_overlap
							(overlapping_deleg_sid, overlapping_region_sid, applied_to_region_sid, tpl_deleg_sid, is_sync_deleg, deleg_plan_sid, deleg_plan_col_deleg_id, region_sid)
						VALUES
							(v_dele_reg_rec.delegation_sid, v_dele_reg_rec.region_sid, in_apply_to_region_sid, in_tpl_delegation_sid, 0, in_deleg_plan_sid, in_deleg_plan_col_deleg_id,in_plan_region_sid);
					END IF;
				END LOOP;
				
				RETURN;
			END IF;
			
			DELETE FROM delegation_region dr
			 WHERE EXISTS (
				SELECT NULL
				  FROM delegation
				 WHERE delegation_sid = dr.delegation_sid
				 START WITH delegation_sid = v_root_deleg_sid
			   CONNECT BY PRIOR delegation_sid = parent_sid			
			);
			
			FOR s IN (
				WITH region_tree AS (
					SELECT r.region_sid, sys_connect_by_path(region_sid, '/') path, connect_by_isleaf is_leaf 
					  FROM region r
					 WHERE (in_region_type IS NULL OR r.region_type = in_region_type)
					   AND (in_tag_id IS NULL OR EXISTS (
							SELECT 1
							  FROM region_tag rt
							 WHERE rt.region_sid = r.region_sid
							   AND rt.tag_id = in_tag_id
						))
					 START WITH r.active = 1 AND r.region_sid = in_plan_region_sid
				   CONNECT BY r.active = 1 AND PRIOR r.app_sid = r.app_sid AND PRIOR r.region_sid = r.parent_sid
				 )
				 SELECT region_sid
				   FROM region_tree rt 
				  WHERE (in_region_selection = csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT AND is_leaf = 1)
					 OR (in_region_selection = csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT AND NOT EXISTS (
							SELECT NULL
							  FROM region_tree
							 WHERE path like rt.path||'/%')
						)					
			) LOOP
				v_current_parent_deleg_sid := in_maps_to_root_deleg_sid;

				SELECT COUNT(*)
				  INTO v_region_on_deleg
				  FROM delegation_region
				 WHERE delegation_sid = v_root_deleg_sid
				   AND region_sid = s.region_sid;


				IF v_region_on_deleg = 0 THEN
					WHILE TRUE LOOP
						-- Add region to current delegation
						INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility)
						SELECT v_current_parent_deleg_sid, s.region_sid, 0,
							   (SELECT NVL(MAX(Pos), 0) + 1 FROM delegation_region WHERE delegation_sid = v_current_parent_deleg_sid),
							   s.region_sid, 'SHOW'
						 FROM DUAL
						 WHERE NOT EXISTS (
							SELECT 1
							  FROM delegation_region
							 WHERE delegation_sid = v_current_parent_deleg_sid
							   AND region_sid = s.region_sid);
							   
						v_updated_deleg_ids.extend(1);
						v_updated_deleg_ids(v_updated_deleg_ids.count) := v_current_parent_deleg_sid;
						-- Find next subdelegation or stop
						BEGIN
							SELECT delegation_sid
							  INTO v_non_top_deleg_sid
							  FROM delegation
							 WHERE parent_sid = v_current_parent_deleg_sid;
							EXCEPTION
								WHEN NO_DATA_FOUND THEN -- no more child delegations, time to break the loop
									EXIT;
						END;

						v_current_parent_deleg_sid := v_non_top_deleg_sid;
					END LOOP;
				END IF;
			END LOOP;
		END IF;

		IF in_region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_M_REGION, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT) THEN
			INSERT INTO delegation_region
			(delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid, visibility)
			SELECT v_root_deleg_sid, in_apply_to_region_sid, 0, rownum, in_apply_to_region_sid, 'SHOW'
			  FROM DUAL
			 WHERE NOT EXISTS (
				SELECT 1
				  FROM delegation_region
				 WHERE delegation_sid = v_root_deleg_sid
				   AND region_sid = in_apply_to_region_sid
			 );
		END IF;

		IF in_overwrite_dates = 1 THEN
			INTERNAL_GetDateSchedule(in_deleg_plan_sid, v_role_sid, v_deleg_plan_col_id, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
			UpdateDateSchedule(SYS_CONTEXT('SECURITY', 'ACT'), v_root_deleg_sid, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
			UpdateSheetDates(SYS_CONTEXT('SECURITY', 'ACT'), v_root_deleg_sid);
			delegation_pkg.CreateSheetsForDelegation(v_root_deleg_sid, 0, v_new_sheets);
		END IF;
	END IF;

	IF v_new_sheets%ISOPEN THEN
		LOOP
			FETCH v_new_sheets INTO v_sheet_id, v_start_dtm, v_end_dtm, v_submission_dtm, v_reminder_dtm, v_editing_url;
			EXIT WHEN v_new_sheets%NOTFOUND;
			v_all_new_sheets.extend(1);
			v_all_new_sheets(v_all_new_sheets.LAST) := v_sheet_id;
		END LOOP;
	END IF;

	IF v_updated_sheets%ISOPEN THEN
		LOOP
			FETCH v_updated_sheets INTO v_sheet_id, v_start_dtm, v_end_dtm, v_submission_dtm, v_reminder_dtm, v_editing_url;
			EXIT WHEN v_updated_sheets%NOTFOUND;
			v_all_updated_sheets.extend(1);
			v_all_updated_sheets(v_all_updated_sheets.LAST) := v_sheet_id;
		END LOOP;
	END IF;


	-- try to apply chain
	v_parent_deleg_sid := null; -- unknown on first pass
	v_deleg_sid := v_root_deleg_sid; -- we know this though!
	FOR c IN (
		SELECT rl.role_sid, rl.name
		  FROM deleg_plan_role dpr
		  JOIN role rl ON dpr.role_sid = rl.role_sid
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		 ORDER BY dpr.pos
	)
	LOOP
		IF v_parent_deleg_sid IS NOT NULL THEN
			-- must be second (or later) pass
			SELECT MIN(d.delegation_sid), COUNT(DISTINCT dr.region_sid), MIN(dr.region_sid)
			  INTO v_deleg_sid, v_xcheck_region_cnt, v_xcheck_region_sid
			  FROM delegation d
			  LEFT JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid
			   AND dr.region_sid = in_apply_to_region_sid
			 WHERE parent_sid = v_parent_deleg_sid;
			-- if there's a region present that isn't ours then
			-- we're in trouble...
			IF v_deleg_sid IS NOT NULL AND (v_xcheck_region_sid != in_apply_to_region_sid) THEN -- v_xcheck_region_cnt !=1 OR
				-- just barf for now -- ideally this delegation chain will have been marked as manually amended
				-- so this ought never happen (on new chains)
				RAISE_APPLICATION_ERROR(-20001, 'Applying chain for region '||in_apply_to_region_sid||' aborted - the regions have been changed on a child delegation of delegation '||v_parent_deleg_sid);
			END IF;

			IF v_deleg_sid IS NOT NULL AND in_overwrite_dates = 1 THEN
				INTERNAL_GetDateSchedule(in_deleg_plan_sid, c.role_sid, v_deleg_plan_col_id, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
				UpdateDateSchedule(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_sid, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
				UpdateSheetDates(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_sid);
				delegation_pkg.CreateSheetsForDelegation(v_deleg_sid, 0, v_new_sheets);
			END IF;
		END IF;

		IF in_is_dynamic_plan = 0 THEN
			-- check to see if there are actually any users in this role.
			-- On static plans, if there are no users then we just skip the step.
			SELECT COUNT(user_sid)
			  INTO v_cnt
			  FROM region_role_member
			 WHERE region_sid = in_apply_to_region_sid
			   AND role_sid = c.role_sid;
			IF v_cnt = 0 THEN
				GOTO continue_role_loop;
			END IF;
		END IF;

		IF v_deleg_sid IS NULL THEN
			-- we need to subdelegate so get delegation details about parent
			OPEN cd(v_parent_deleg_sid);
			FETCH cd INTO rd;
			CLOSE cd;

			delegation_pkg.CreateNonTopLevelDelegation(
				in_parent_sid			=> v_parent_deleg_sid,
				in_name					=> rd.name,
				in_period_set_id		=> rd.period_set_id,
				in_period_interval_id	=> rd.period_interval_id,
				in_schedule_xml			=> rd.schedule_xml,
				in_note					=> rd.note,
				in_part_of_deleg_plan	=> 1,
				in_show_aggregate		=> rd.show_aggregate,
				out_delegation_sid		=> v_deleg_sid
			);
			out_created := 1;

			-- copy indicators from the parent
			INSERT INTO delegation_ind (delegation_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na)
				SELECT v_deleg_sid, ind_sid, mandatory, pos, section_key, visibility, css_class, var_expl_group_id, meta_role, allowed_na
				  FROM delegation_ind
				 WHERE delegation_sid = v_parent_deleg_sid;

			-- Copy over User Perf Accuracy metric info
			INSERT INTO deleg_meta_role_ind_selection(delegation_sid, ind_sid, lang, description)
				SELECT v_deleg_sid, ind_sid, lang, description
				  FROM deleg_meta_role_ind_selection
				 WHERE delegation_sid = v_parent_deleg_sid;

			INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
				SELECT v_deleg_sid, ind_sid, lang, description
				  FROM delegation_ind_description
				 WHERE delegation_sid = v_parent_deleg_sid;

			-- copy over regions from parent
			INSERT INTO delegation_region (delegation_sid, region_sid, pos, aggregate_to_region_sid, visibility, allowed_na)
				SELECT v_deleg_sid, region_sid, pos, aggregate_to_region_sid, visibility, allowed_na
				  FROM delegation_region
				 WHERE delegation_sid = v_parent_deleg_sid;

			INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
				SELECT v_deleg_sid, region_sid, lang, description
				  FROM delegation_region_description
				 WHERE delegation_sid = v_parent_deleg_sid;

			v_is_fully_delegated := delegation_pkg.isFullyDelegated(v_parent_deleg_sid);

			UPDATE delegation
			   SET fully_delegated = v_is_fully_delegated -- 1?
			 WHERE delegation_sid = v_parent_deleg_sid;

			INTERNAL_GetDateSchedule(in_deleg_plan_sid, c.role_sid, v_deleg_plan_col_id, v_schedule_xml, v_reminder_offset, v_date_schedule_id);
			UpdateDateSchedule(SYS_CONTEXT('SECURITY', 'ACT'), v_deleg_sid, v_schedule_xml, v_reminder_offset, v_date_schedule_id);

			delegation_pkg.CreateSheetsForDelegation(v_deleg_sid, 0, v_new_sheets);
		END IF;

		-- now we need to either set users or roles
		IF in_is_dynamic_plan = 1 THEN
			-- clear users and set role
			delegation_pkg.SetUsers(SYS_CONTEXT('SECURITY','ACT'), v_deleg_sid, null);
			delegation_pkg.SetRoles(SYS_CONTEXT('SECURITY','ACT'), v_deleg_sid, c.role_sid);
		ELSE
			-- clear role and set users
			-- XXX: ought to be changed to some kind of array collection rather than a string
			SELECT STRAGG(user_sid)
			  INTO v_user_list
			  FROM region_role_member
			 WHERE region_sid = in_apply_to_region_sid
			   AND role_sid = c.role_sid;
			delegation_pkg.SetUsers(SYS_CONTEXT('SECURITY','ACT'), v_deleg_sid, v_user_list);
			delegation_pkg.SetRoles(SYS_CONTEXT('SECURITY','ACT'), v_deleg_sid, null);
		END IF;

		-- fix up name
		IF in_name_template IS NOT NULL THEN
			v_name := in_name_template;
			v_name := REPLACE(v_name, '{NAME}', in_master_delegation_name);
			v_name := REPLACE(v_name, '{LOOKUP_KEY}', in_apply_to_region_lookup_key);
			v_name := REPLACE(v_name, '{REGION}', in_apply_to_region_desc);
			UPDATE delegation
			   SET name = v_name
			 WHERE delegation_sid = v_deleg_sid;
		END IF;

		-- Update the array of sheets for this iteration
		IF v_new_sheets%ISOPEN THEN
			LOOP
				FETCH v_new_sheets INTO v_sheet_id, v_start_dtm, v_end_dtm, v_submission_dtm, v_reminder_dtm, v_editing_url;
				EXIT WHEN v_new_sheets%NOTFOUND;
				v_all_new_sheets.extend(1);
				v_all_new_sheets(v_all_new_sheets.LAST) := v_sheet_id;
			END LOOP;
		END IF;

		IF v_updated_sheets%ISOPEN THEN
			LOOP
				FETCH v_updated_sheets INTO v_sheet_id, v_start_dtm, v_end_dtm, v_submission_dtm, v_reminder_dtm, v_editing_url;
				EXIT WHEN v_updated_sheets%NOTFOUND;
				v_all_updated_sheets.extend(1);
				v_all_updated_sheets(v_all_updated_sheets.LAST) := v_sheet_id;
			END LOOP;
		END IF;

		v_parent_deleg_sid := v_deleg_sid;
		v_deleg_sid := null;

		-- rather bizarre, but PL/SQL won't branch to a label that precedes an END block statement, so
		-- the workaround suggested by Oracle is to shove in a NULL;. Whatever....
		<<continue_role_loop>>
		NULL;
	END LOOP;

	-- Now the users have been set, raise alerts for each sheet.
	IF v_all_new_sheets.COUNT > 0 THEN
		FOR i IN v_all_new_sheets.FIRST..v_all_new_sheets.LAST LOOP
			sheet_pkg.RaisePlanSheetNewAlert(v_all_new_sheets(i));
			sheet_pkg.RaiseSheetCreatedAlert(v_all_new_sheets(i));
		END LOOP;
	END IF;

	IF v_all_updated_sheets.COUNT > 0 THEN
		FOR i IN v_all_updated_sheets.FIRST..v_all_updated_sheets.LAST LOOP
			sheet_pkg.RaisePlanSheetUpdatedAlert(v_all_updated_sheets(i));
		END LOOP;
	END IF;


	-- now check to see if there are any children that need tidying up. If stuff has been manually sub-delegated
	-- then in theory HAS_MANUAL_AMENDS will have been set so we won't mess anything thing up that has been done
	-- deliberately, but this will clean up stuff where the roles have changed or roles have been removed and
	-- we want to clean up (but not where users have entered data).
	FOR c IN (
		SELECT delegation_sid
		  FROM delegation
		 WHERE parent_sid = v_parent_deleg_sid
	)
	LOOP
		v_deleted := SafeDeleteDelegation(c.delegation_sid);
	END LOOP;

	-- commit for each region to minimise blocking
	COMMIT;
END;

PROCEDURE ProcessApplyPlanJob(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_deleg_plan_sid   	    	IN	security_pkg.T_SID_ID,
	in_is_dynamic_plan      		IN	NUMBER DEFAULT 1,
	in_overwrite_dates				IN	NUMBER DEFAULT 0,
	out_created						OUT	NUMBER
)
AS
	v_maps_to_root_deleg_sid		deleg_plan_deleg_region_deleg.maps_to_root_deleg_sid%TYPE;
	v_text							VARCHAR2(100);
	v_name_template					deleg_plan.name_template%TYPE;
	v_tag_matches					NUMBER(10);
	v_cnt							NUMBER(10);
	v_active						NUMBER(1);
	v_steps							NUMBER;
	v_step							NUMBER;
	v_deleted						BOOLEAN;
BEGIN
	out_created := 0;

	IF in_is_dynamic_plan = 1 THEN
		v_text := 'Dynamic plan applied';
	ELSE
		v_text := 'Static plan applied';
	END IF;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, v_text);

	SELECT name_template, active
	  INTO v_name_template, v_active
	  FROM deleg_plan
	 WHERE deleg_plan_sid = in_deleg_plan_sid;

	-- if the plan isn't active then don't do anything
	IF v_active = 0 THEN
		RETURN;
	END IF;

	IF in_batch_job_id IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_steps
		  FROM deleg_plan_deleg_region_deleg dpdrd
		  JOIN deleg_plan_deleg_region dpdr ON dpdrd.app_sid = dpdr.app_sid AND dpdrd.region_sid = dpdr.region_sid AND dpdrd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
		  JOIN deleg_plan_col dpc ON dpc.app_sid = dpdr.app_sid AND dpc.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
		 WHERE dpdrd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_M_REGION, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT)
		   AND dpdr.tag_id IS NOT NULL
		   AND dpdr.tag_id NOT IN (
				SELECT rt.tag_id
				  FROM region_tag rt
				 WHERE rt.app_sid = dpc.app_sid AND rt.region_sid = dpdrd.applied_to_region_sid
		   );

		SELECT v_steps + COUNT(*)
		  INTO v_steps
		  FROM v$deleg_plan_deleg_region dpdr
		 WHERE dpdr.deleg_plan_sid = in_deleg_plan_sid
		   AND (dpdr.is_hidden = 1 OR dpdr.pending_deletion IN (csr_data_pkg.DELEG_PLAN_DELETE_ALL, csr_data_pkg.DELEG_PLAN_DELETE_CREATE));

		SELECT v_steps + COUNT(*)
		  INTO v_steps
		  FROM deleg_plan_deleg_region_deleg dpdrd,
			   deleg_plan_col dpc,
			   deleg_plan_deleg_region dpdr,
			   region r
		 WHERE dpdrd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND dpdrd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		   AND dpdr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		   AND dpdrd.region_sid = dpdr.region_sid
		   AND r.region_sid = dpdrd.applied_to_region_sid
		   AND dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND ((dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_REGION, csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT) AND dpdr.tag_id IS NOT NULL) OR r.active = 0);

		SELECT v_steps + COUNT(*)
		  INTO v_steps
		  FROM v$deleg_plan_deleg_region dpdr
		  JOIN v$region r ON dpdr.region_sid = r.region_sid
		  JOIN delegation md ON dpdr.delegation_sid = md.delegation_sid
		 WHERE dpdr.deleg_plan_sid = in_deleg_plan_sid
		   AND dpdr.is_hidden = 0;
		
		
		SELECT v_steps + COUNT(*)
		  INTO v_steps
		  FROM deleg_plan_deleg_region_deleg dpdrd
		  JOIN deleg_plan_col dpc ON dpdrd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		  JOIN deleg_plan_deleg_region dpdr ON dpdr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id AND dpdrd.region_sid = dpdr.region_sid
		  JOIN region r ON r.region_sid = dpdrd.applied_to_region_sid
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND (
			r.active = 0
			OR
			(dpdr.region_type IS NOT NULL AND r.region_type != dpdr.region_type)
			OR
			(dpdr.tag_id IS NOT NULL AND NOT EXISTS (
				SELECT NULL
				  FROM region_tag
				 WHERE region_sid = r.region_sid
				   AND tag_id = dpdr.tag_id
			))
			OR
			(dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT) AND EXISTS (
				SELECT NULL
				  FROM region
				 WHERE parent_sid = r.region_sid
				   AND active = 1
			))
			OR
			(dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT) AND EXISTS (
				SELECT NULL
				  FROM region reg
				 WHERE active = 1
				   AND (dpdr.region_type IS NULL OR region_type = dpdr.region_type)
				   AND (dpdr.tag_id IS NULL OR EXISTS (
						SELECT NULL
						  FROM region_tag
						 WHERE region_sid = reg.region_sid
						   AND tag_id = dpdr.tag_id
					))
				 START WITH parent_sid = r.region_sid
			CONNECT BY PRIOR region_sid = parent_sid			
			))
		);
		
		batch_job_pkg.SetProgress(in_batch_job_id, 0, v_steps);
		v_step := 0;
	END IF;

	-- stop new calc jobs for the duration of the application of this plan
	stored_calc_datasource_pkg.DisableJobCreation;

	-- check if any of the region tags has changed since the plan was last applied
	-- and if yes, tell it to delete what's there and then recreate
	FOR r IN (
		SELECT dpdrd.region_sid, dpc.deleg_plan_col_deleg_id
		  FROM deleg_plan_deleg_region_deleg dpdrd
		  JOIN deleg_plan_deleg_region dpdr ON dpdrd.app_sid = dpdr.app_sid AND dpdrd.region_sid = dpdr.region_sid AND dpdrd.deleg_plan_col_deleg_id = dpdr.deleg_plan_col_deleg_id
		  JOIN deleg_plan_col dpc ON dpc.app_sid = dpdr.app_sid AND dpc.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
		 WHERE dpdrd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_M_REGION, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT)
		   AND dpdr.tag_id IS NOT NULL
		   AND dpdr.tag_id NOT IN (
				SELECT rt.tag_id
				  FROM region_tag rt
				 WHERE rt.app_sid = dpc.app_sid AND rt.region_sid = dpdrd.applied_to_region_sid
		   )
	) LOOP
		UPDATE deleg_plan_deleg_region
		   SET pending_deletion = csr_data_pkg.DELEG_PLAN_DELETE_CREATE
		 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
		   AND region_sid = r.region_sid;

		IF in_batch_job_id IS NOT NULL THEN
			v_step := v_step + 1;
			batch_job_pkg.SetProgress(in_batch_job_id, v_step, v_steps);
		END IF;
	END LOOP;

	-- clean up stuff that needs deleting.
	FOR r IN (
		SELECT dpdr.deleg_plan_col_deleg_id, dpdr.region_sid, dpdr.pending_deletion
		  FROM v$deleg_plan_deleg_region dpdr
		 WHERE dpdr.deleg_plan_sid = in_deleg_plan_sid
		   AND (dpdr.is_hidden = 1 OR dpdr.pending_deletion IN (csr_data_pkg.DELEG_PLAN_DELETE_ALL, csr_data_pkg.DELEG_PLAN_DELETE_CREATE))
	)
	LOOP
		FOR s IN (
			SELECT dpdrd.maps_to_root_deleg_sid, dpdrd.applied_to_region_sid
			  FROM deleg_plan_deleg_region_deleg dpdrd
			 WHERE dpdrd.deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
			   AND dpdrd.region_sid = r.region_sid
		 --    AND has_manual_amends = 0
		-- delete delegation
		) LOOP
			--security_pkg.debugmsg('cleaning up '||s.maps_to_root_deleg_sid);
			v_deleted := SafeDeleteDelegation(s.maps_to_root_deleg_sid);

			csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
				SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Delegation safely deleted for deselected region: {0}, for template delegation {1}',
				s.applied_to_region_sid, r.deleg_plan_col_deleg_id);

			-- if we deleted the delegation, then forget we created it, otherwise mark it
			-- up as having manual amends
			-- XXX: this seemed sensible, although we appear to be ignoring has_manual_amends
			-- above.  Need to figure out why that is next.

			-- Commented bits out as temporary fix for behaviour seen in FB41727
			-- IF v_deleted THEN
				DELETE FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
				   AND region_sid = r.region_sid
				   AND applied_to_region_sid = s.applied_to_region_sid;
			-- ELSE
			-- 	UPDATE deleg_plan_deleg_region_deleg
			-- 	   SET has_manual_amends = 1
			-- 	 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
			-- 	   AND region_sid = r.region_sid
			-- 	   AND applied_to_region_sid = s.applied_to_region_sid;
			-- END IF;
		END LOOP;

		IF r.pending_deletion = csr_data_pkg.DELEG_PLAN_DELETE_CREATE THEN
			-- no further deletion required -- we'll recreate this in a minute
			UPDATE deleg_plan_deleg_region
			   SET pending_deletion = csr_data_pkg.DELEG_PLAN_NO_DELETE
			 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
			   AND region_sid = r.region_sid;
		ELSE
			-- clean up
			DELETE FROM deleg_plan_deleg_region
			 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
			   AND region_sid = r.region_sid;
		END IF;

		IF in_batch_job_id IS NOT NULL THEN
			v_step := v_step + 1;
			batch_job_pkg.SetProgress(in_batch_job_id, v_step, v_steps);
		END IF;
	END LOOP;

	FOR r IN (
		SELECT dpdrd.region_sid, dpc.deleg_plan_col_deleg_id, dpdrd.applied_to_region_sid, dpdrd.maps_to_root_deleg_sid, dpdr.region_selection, dpdr.tag_id
		  FROM deleg_plan_deleg_region_deleg dpdrd
		  JOIN deleg_plan_col dpc ON dpdrd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		  JOIN deleg_plan_deleg_region dpdr ON dpdr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id AND dpdrd.region_sid = dpdr.region_sid
		  JOIN region r ON r.region_sid = dpdrd.applied_to_region_sid
		 WHERE dpc.deleg_plan_sid = in_deleg_plan_sid
		   AND (
			r.active = 0
			OR
			(dpdr.region_type IS NOT NULL AND r.region_type != dpdr.region_type)
			OR
			(dpdr.tag_id IS NOT NULL AND NOT EXISTS (
				SELECT NULL
				  FROM region_tag
				 WHERE region_sid = r.region_sid
				   AND tag_id = dpdr.tag_id
			))
			OR
			(dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT) AND EXISTS (
				SELECT NULL
				  FROM region
				 WHERE parent_sid = r.region_sid
				   AND active = 1
			))
			OR
			(dpdr.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT) AND EXISTS (
				SELECT NULL
				  FROM region reg
				 WHERE active = 1
				   AND (dpdr.region_type IS NULL OR region_type = dpdr.region_type)
				   AND (dpdr.tag_id IS NULL OR EXISTS (
						SELECT NULL
						  FROM region_tag
						 WHERE region_sid = reg.region_sid
						   AND tag_id = dpdr.tag_id
					))
				 START WITH parent_sid = r.region_sid
			CONNECT BY PRIOR region_sid = parent_sid			
			))
		)
	) LOOP
		-- Region no longer at relevent level, so remove from delegation (if there are no sheet values)
		FOR s IN (
			WITH tree AS (
				SELECT delegation_sid
				  FROM delegation
				 START WITH delegation_sid = r.maps_to_root_deleg_sid
			   CONNECT BY PRIOR delegation_sid = parent_sid
			)
			SELECT dr.delegation_sid, dr.region_sid
			  FROM tree d
			  JOIN delegation_region dr ON d.delegation_sid = dr.delegation_sid 
			  WHERE NOT EXISTS (
				SELECT NULL
				  FROM tree nd
				  JOIN delegation_region ndr ON nd.delegation_sid = ndr.delegation_sid
				  -- constrain to inds actually part of the delegation
				  LEFT JOIN delegation_ind di ON ndr.app_sid = di.app_sid AND ndr.delegation_sid = di.delegation_sid
				  -- ignore data for calculated inds
				  LEFT JOIN ind i ON di.app_sid = i.app_sid AND di.ind_sid = i.ind_sid AND i.ind_type = csr_data_pkg.IND_TYPE_NORMAL
				  LEFT JOIN sheet s ON s.app_sid = ndr.app_sid AND s.delegation_sid = ndr.delegation_sid
				  LEFT JOIN sheet_value sv ON sv.app_sid = s.app_sid AND sv.sheet_id = s.sheet_id AND sv.region_sid = ndr.region_sid AND sv.ind_sid = di.ind_sid
				  LEFT JOIN sheet_value_file svf ON svf.app_sid = sv.app_sid AND svf.sheet_value_id = sv.sheet_value_id
				 WHERE ndr.region_sid = dr.region_sid
				 GROUP BY ndr.delegation_sid, ndr.region_sid
				HAVING SUM(CASE WHEN sv.val_number IS NOT NULL OR NVL(LENGTH(sv.note),0)!=0 OR svf.sheet_value_id IS NOT NULL THEN 1 ELSE 0 END) = 1
			)
		) LOOP
			IF r.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT) THEN
				DELETE FROM delegation_region_description
				 WHERE delegation_sid = s.delegation_sid
				   AND region_sid = s.region_sid;

				DELETE FROM delegation_region
				 WHERE delegation_sid = s.delegation_sid
				   AND region_sid = s.region_sid;
			ELSIF r.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT) THEN
				v_deleted := SafeDeleteDelegation(s.delegation_sid);

				csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
				SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Delegation safely deleted - template delegation {0} and region {1}',
					r.deleg_plan_col_deleg_id, r.applied_to_region_sid);

				DELETE FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
				   AND region_sid = r.region_sid
				   AND applied_to_region_sid = r.applied_to_region_sid;
			END IF;
		END LOOP;

		IF in_batch_job_id IS NOT NULL THEN
			v_step := v_step + 1;
			batch_job_pkg.SetProgress(in_batch_job_id, v_step, v_steps);
		END IF;
	END LOOP;

	-- now apply delegations
	FOR r IN (
		SELECT dpdr.deleg_plan_col_deleg_id, dpdr.delegation_sid, dpdr.region_sid, r.description region_description,
			   r.lookup_key region_lookup_key, md.name master_delegation_name, dpdr.region_selection, dpdr.tag_id, dpdr.region_type
		  FROM v$deleg_plan_deleg_region dpdr
		  JOIN v$region r ON dpdr.region_sid = r.region_sid
		  JOIN delegation md ON dpdr.delegation_sid = md.delegation_sid
		 WHERE dpdr.deleg_plan_sid = in_deleg_plan_sid
		   AND dpdr.is_hidden = 0
	 --    AND dpdr.has_manual_amends = 0
	)
	LOOP
		IF r.region_selection IN (csr_data_pkg.DELEG_PLAN_SEL_S_REGION, csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT) THEN
			SELECT MIN(maps_to_root_deleg_sid)
			  INTO v_maps_to_root_deleg_sid
			  FROM deleg_plan_deleg_region_deleg
			 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
			   AND region_sid = r.region_sid;

			-- ApplyPlanToRegion handles region selection to include child regions.
			ApplyPlanToRegion(
					in_deleg_plan_sid				=> in_deleg_plan_sid,
					in_is_dynamic_plan				=> in_is_dynamic_plan,
					in_name_template				=> v_name_template,
					in_deleg_plan_col_deleg_id		=> r.deleg_plan_col_deleg_id,
					in_master_delegation_name		=> r.master_delegation_name,
					in_maps_to_root_deleg_sid		=> v_maps_to_root_deleg_sid,
					in_apply_to_region_sid			=> r.region_sid,
					in_apply_to_region_lookup_key	=> r.region_lookup_key,
					in_apply_to_region_desc			=> r.region_description,
					in_plan_region_sid				=> r.region_sid,
					in_tpl_delegation_sid			=> r.delegation_sid,
					in_region_selection				=> r.region_selection,
					in_tag_id						=> r.tag_id,
					in_region_type					=> r.region_type,
					in_overwrite_dates				=> in_overwrite_dates,
					out_created						=> out_created
			);
		ELSIF r.region_selection = csr_data_pkg.DELEG_PLAN_SEL_M_REGION THEN
			IF r.tag_id IS NULL THEN
				v_tag_matches := 1;
			ELSE
				SELECT COUNT(*)
				  INTO v_tag_matches
				  FROM region_tag
				 WHERE region_sid = r.region_sid AND tag_id = r.tag_id;
			END IF;
			IF v_tag_matches > 0 THEN
				SELECT MIN(maps_to_root_deleg_sid)
				  INTO v_maps_to_root_deleg_sid
				  FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
				   AND region_sid = r.region_sid
				   AND applied_to_region_sid = r.region_sid;

				ApplyPlanToRegion(
					in_deleg_plan_sid				=> in_deleg_plan_sid,
					in_is_dynamic_plan				=> in_is_dynamic_plan,
					in_name_template				=> v_name_template,
					in_deleg_plan_col_deleg_id		=> r.deleg_plan_col_deleg_id,
					in_master_delegation_name		=> r.master_delegation_name,
					in_maps_to_root_deleg_sid		=> v_maps_to_root_deleg_sid,
					in_apply_to_region_sid			=> r.region_sid,
					in_apply_to_region_lookup_key	=> r.region_lookup_key,
					in_apply_to_region_desc			=> r.region_description,
					in_plan_region_sid				=> r.region_sid,
					in_tpl_delegation_sid			=> r.delegation_sid,
					in_region_selection				=> r.region_selection,
					in_tag_id						=> r.tag_id,
					in_region_type					=> r.region_type,
					in_overwrite_dates				=> in_overwrite_dates,
					out_created						=> out_created);
			END IF;
		ELSIF r.region_selection = csr_data_pkg.DELEG_PLAN_SEL_M_LOWEST_RT THEN
			FOR s IN (
				SELECT rx.app_sid, rx.region_sid, rx.lookup_key, rx.description
				  FROM v$region rx
				 WHERE connect_by_isleaf = 1
				   AND (r.region_type IS NULL OR rx.region_type = r.region_type)
				   AND (r.tag_id IS NULL
					OR EXISTS (
						SELECT 1
						  FROM region_tag rt
						 WHERE rt.app_sid = rx.app_sid AND rt.region_sid = rx.region_sid
						   AND rt.tag_id = r.tag_id))
				 START WITH rx.active = 1 AND rx.region_sid = r.region_sid
			   CONNECT BY rx.active = 1 AND PRIOR rx.app_sid = rx.app_sid AND PRIOR rx.region_sid = rx.parent_sid
			) LOOP
				SELECT MIN(maps_to_root_deleg_sid)
				  INTO v_maps_to_root_deleg_sid
				  FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
				   AND region_sid = r.region_sid
				   AND applied_to_region_sid = s.region_sid;

				ApplyPlanToRegion(
					in_deleg_plan_sid				=> in_deleg_plan_sid,
					in_is_dynamic_plan				=> in_is_dynamic_plan,
					in_name_template				=> v_name_template,
					in_deleg_plan_col_deleg_id		=> r.deleg_plan_col_deleg_id,
					in_master_delegation_name		=> r.master_delegation_name,
					in_maps_to_root_deleg_sid		=> v_maps_to_root_deleg_sid,
					in_apply_to_region_sid			=> s.region_sid,
					in_apply_to_region_lookup_key	=> s.lookup_key,
					in_apply_to_region_desc			=> s.description,
					in_plan_region_sid				=> r.region_sid,
					in_tpl_delegation_sid			=> r.delegation_sid,
					in_region_selection				=> r.region_selection,
					in_tag_id						=> r.tag_id,
					in_region_type					=> r.region_type,
					in_overwrite_dates				=> in_overwrite_dates,
					out_created						=> out_created);
			END LOOP;
		ELSIF r.region_selection = csr_data_pkg.DELEG_PLAN_SEL_M_LOWER_RT THEN
			FOR s IN (
				WITH region_tree AS (
					SELECT rx.region_sid, rx.lookup_key, rx.description, sys_connect_by_path(region_sid, '/') path 
					  FROM v$region rx
					 WHERE (r.region_type IS NULL OR rx.region_type = r.region_type)
					   AND (r.tag_id IS NULL OR EXISTS (
							SELECT 1
							  FROM region_tag rt
							 WHERE rt.region_sid = rx.region_sid
							   AND rt.tag_id = r.tag_id
						))
					 START WITH rx.active = 1 AND rx.region_sid = r.region_sid
				   CONNECT BY rx.active = 1 AND PRIOR rx.app_sid = rx.app_sid AND PRIOR rx.region_sid = rx.parent_sid
				 )
				 SELECT region_sid, lookup_key, description
				   FROM region_tree rt 
				  WHERE NOT EXISTS (
							SELECT NULL
							  FROM region_tree
							 WHERE path like rt.path||'/%'
						)	
			) LOOP
				SELECT MIN(maps_to_root_deleg_sid)
				  INTO v_maps_to_root_deleg_sid
				  FROM deleg_plan_deleg_region_deleg
				 WHERE deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id
				   AND region_sid = r.region_sid
				   AND applied_to_region_sid = s.region_sid;
				   
				ApplyPlanToRegion(
					in_deleg_plan_sid				=> in_deleg_plan_sid,
					in_is_dynamic_plan				=> in_is_dynamic_plan,
					in_name_template				=> v_name_template,
					in_deleg_plan_col_deleg_id		=> r.deleg_plan_col_deleg_id,
					in_master_delegation_name		=> r.master_delegation_name,
					in_maps_to_root_deleg_sid		=> v_maps_to_root_deleg_sid,
					in_apply_to_region_sid			=> s.region_sid,
					in_apply_to_region_lookup_key	=> s.lookup_key,
					in_apply_to_region_desc			=> s.description,
					in_plan_region_sid				=> r.region_sid,
					in_tpl_delegation_sid			=> r.delegation_sid,
					in_region_selection				=> r.region_selection,
					in_tag_id						=> r.tag_id,
					in_region_type					=> r.region_type,
					in_overwrite_dates				=> in_overwrite_dates,
					out_created						=> out_created);
			END LOOP;
		END IF;

		IF in_batch_job_id IS NOT NULL THEN
			v_step := v_step + 1;
			batch_job_pkg.SetProgress(in_batch_job_id, v_step, v_steps);
		END IF;
	END LOOP;

	/*
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM temp_deleg_plan_overlap;

	RAISE_APPLICATION_ERROR(-20001, v_cnt||' overlaps');
	*/

	-- temp_deleg_plan_overlap contains details of delegations that couldn't be created because of overlaps, either
	-- because the original delegation had data so couldn't be deleted, or a delegation existed that was not part of
	-- this delegation plan. The following statement attempts to re-link the first group of delegations with the delegation
	-- plan.
	--
	-- We need to be careful that if we run applyplan twice in the same transaction we don't end up with multiple sets
	-- of rows (regionManager.aspx does this when creating a region [which triggers applyplan] and then sets regiontags
	-- [which also triggers applyplan]). Also only relink where the dates and region are the same and the delegation's
	-- master_delegation_sid links back to the template delegation.
	INSERT INTO deleg_plan_deleg_region_deleg
		(deleg_plan_col_deleg_id, region_sid, applied_to_region_sid, maps_to_root_deleg_sid)
		SELECT tdpo.deleg_plan_col_deleg_id, tdpo.region_sid, tdpo.applied_to_region_sid, MIN(tdpo.overlapping_deleg_sid)
		  FROM temp_deleg_plan_overlap tdpo
		  JOIN deleg_plan_col_deleg dpcd ON tdpo.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		  JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		  JOIN deleg_plan dp ON dpc.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN delegation d ON tdpo.overlapping_deleg_sid = d.delegation_sid AND dpcd.delegation_sid = d.master_delegation_sid AND dp.start_dtm = d.start_dtm AND dp.end_dtm = d.end_dtm
		  JOIN delegation_region dr ON dr.delegation_sid = d.delegation_sid AND dr.region_sid = tdpo.applied_to_region_sid
		  JOIN deleg_plan_deleg_region dpcr ON dpcr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id AND dpcr.region_sid = tdpo.region_sid
		 WHERE dpcr.region_selection NOT IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT)
		   AND (tdpo.deleg_plan_col_deleg_id, tdpo.region_sid, tdpo.applied_to_region_sid) NOT IN (
				SELECT deleg_plan_col_deleg_id, region_sid, applied_to_region_sid
				  FROM deleg_plan_deleg_region_deleg
				)
		 GROUP BY tdpo.deleg_plan_col_deleg_id, tdpo.region_sid, tdpo.applied_to_region_sid;
	
	DELETE FROM temp_deleg_plan_overlap tdpo
	WHERE (tdpo.deleg_plan_col_deleg_id, tdpo.region_sid, tdpo.applied_to_region_sid, tdpo.overlapping_deleg_sid) IN (
		SELECT DISTINCT tdpo.deleg_plan_col_deleg_id, tdpo.region_sid, tdpo.applied_to_region_sid, tdpo.overlapping_deleg_sid
		  FROM temp_deleg_plan_overlap tdpo
		  JOIN deleg_plan_col_deleg dpcd ON tdpo.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		  JOIN deleg_plan_col dpc ON dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
		  JOIN deleg_plan dp ON dpc.deleg_plan_sid = dp.deleg_plan_sid
		  JOIN delegation d ON tdpo.overlapping_deleg_sid = d.delegation_sid AND dpcd.delegation_sid = d.master_delegation_sid AND dp.start_dtm = d.start_dtm AND dp.end_dtm = d.end_dtm
		  JOIN delegation_region dr ON dr.delegation_sid = d.delegation_sid AND dr.region_sid = tdpo.applied_to_region_sid
		  JOIN deleg_plan_deleg_region dpcr ON dpcr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id AND dpcr.region_sid = tdpo.region_sid
		 WHERE dpcr.region_selection NOT IN (csr_data_pkg.DELEG_PLAN_SEL_S_LOWEST_RT, csr_data_pkg.DELEG_PLAN_SEL_S_LOWER_RT)
	);

	UPDATE deleg_plan
	   SET last_applied_dtm = SYSDATE
	 WHERE deleg_plan_sid = in_deleg_plan_sid;
	-- Make sure these changes to deleg_plan_deleg_region_deleg are saved even if the web
	-- connection has timed out (we've already committed the creation of the delegations, so
	-- we want to link them up in the plan too)
	COMMIT;

	stored_calc_datasource_pkg.EnableJobCreation;
END;

PROCEDURE ProcessJob(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_result						OUT	batch_job.result%TYPE,
	out_result_url					OUT	batch_job.result_url%TYPE,
	out_cur							OUT	SYS_REFCURSOR	
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_delegation_sid				deleg_plan_job.delegation_sid%TYPE;
	v_deleg_plan_sid				deleg_plan_job.deleg_plan_sid%TYPE;
	v_is_dynamic_plan				deleg_plan_job.is_dynamic_plan%TYPE;
	v_overwrite_dates				deleg_plan_job.overwrite_dates%TYPE;
	v_requesting_user_sid			batch_job.requested_by_user_sid%TYPE;
	v_created						NUMBER;
	v_act							security.security_pkg.T_ACT_ID;
	v_count							NUMBER;
BEGIN
	DELETE FROM csr.temp_deleg_plan_overlap; --Clearing the overlap table

	SELECT delegation_sid, deleg_plan_sid, is_dynamic_plan, overwrite_dates, requested_by_user_sid
	  INTO v_delegation_sid, v_deleg_plan_sid, v_is_dynamic_plan, v_overwrite_dates, v_requesting_user_sid
	  FROM deleg_plan_job dpj
	  JOIN batch_job bj ON bj.batch_job_id = dpj.batch_job_id
	 WHERE bj.batch_job_id = in_batch_job_id;

	 -- log in as the requesting user. (for audit logging, etc.)
	 security.user_pkg.LogonAuthenticated(v_requesting_user_sid,86400,security.security_pkg.GetApp, v_act);

	-- stop new calc jobs for the duration of the application of this plan
	stored_calc_datasource_pkg.DisableJobCreation;

	BEGIN
		IF v_delegation_sid IS NOT NULL THEN
			ProcessSyncDelegWithMasterJob(in_batch_job_id, v_delegation_sid, out_result, out_result_url);
		ELSE
			ProcessApplyPlanJob(
				in_deleg_plan_sid		=> v_deleg_plan_sid,
				in_is_dynamic_plan		=> v_is_dynamic_plan,
				in_overwrite_dates		=> v_overwrite_dates,
				out_created				=> v_created,
				in_batch_job_id			=> in_batch_job_id);
		END IF;
		stored_calc_datasource_pkg.EnableJobCreation;

		OPEN out_cur FOR
			SELECT DISTINCT ol.overlapping_deleg_sid, deleg.description delegation_name, ol.overlapping_region_sid, 
							oreg.description overlap_region_name, ol.tpl_deleg_sid, dt.description template_name, ol.is_sync_deleg,ol.deleg_plan_sid, 
							dp.name delegation_plan, ol.applied_to_region_sid, reg.description applied_region_name
			  FROM csr.temp_deleg_plan_overlap ol
			  JOIN csr.delegation_description deleg ON ol.overlapping_deleg_sid = deleg.delegation_sid
			  JOIN csr.delegation_description dt ON ol.tpl_deleg_sid = dt.delegation_sid
			  JOIN csr.region_description oreg ON ol.overlapping_region_sid = oreg.region_sid
		 LEFT JOIN csr.region_description reg ON ol.applied_to_region_sid = reg.region_sid
		 LEFT JOIN csr.deleg_plan dp ON ol.deleg_plan_sid = dp.deleg_plan_sid
			 WHERE ol.app_sid = security_pkg.getApp
		  ORDER BY reg.description;

		SELECT COUNT(*) INTO v_count from csr.temp_deleg_plan_overlap;
		
		IF v_count > 0  THEN
			out_result := 'Overlap is found';
			ROLLBACK;
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			-- try not to leave anything locked even on failure
			stored_calc_datasource_pkg.EnableJobCreation;

			-- log the original source of the error
			ROLLBACK;
			ASPEN2.error_pkg.LogError('ProcessJob caught exception ' || SQLERRM || Chr(10) || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
			COMMIT;

			RAISE;
	END;

	-- (the SPs above ought to have committed, but just in case)
	COMMIT;
END;

PROCEDURE ApplyDynamicPlans(
	in_region_sid					IN	region.region_sid%TYPE,
	in_source_msg					IN	VARCHAR2
)
AS
	v_region_sid					region.region_sid%TYPE;
	v_batch_job_id					batch_job.batch_job_id%TYPE;
BEGIN
	v_region_sid := in_region_sid;
	IF v_region_sid IS NULL THEN
		SELECT region_root_sid
		  INTO v_region_sid
		  FROM customer
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;

	-- security is handled by ApplyPlan
	FOR r IN (SELECT DISTINCT dp.deleg_plan_sid
				FROM v$deleg_plan_deleg_region dpdr, deleg_plan dp,
					 (SELECT app_sid, region_sid
						FROM region
							 START WITH region_sid = v_region_sid
							 CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
					   UNION ALL
					  SELECT app_sid, region_sid
						FROM region
							 START WITH region_sid = v_region_sid
							 CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid) r
			   WHERE dpdr.app_sid = dp.app_sid
				 AND dpdr.deleg_plan_sid = dp.deleg_plan_sid
				 AND dpdr.app_sid = r.app_sid AND dpdr.region_sid = r.region_sid
				 AND dp.dynamic = 1
				 AND dp.last_applied_dtm IS NOT NULL
	) LOOP

		--security_pkg.debugmsg('applying plan '||r.deleg_plan_sid);

		AddJob(
			in_deleg_plan_sid	=> r.deleg_plan_sid,
			in_dynamic_change	=> TRUE,
			out_batch_job_id	=> v_batch_job_id
		);
		
		csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'), r.deleg_plan_sid, 'Dynamic plan scheduled due to: {0}', in_source_msg);
	END LOOP;
END;

PROCEDURE GetPlanStatus(
	in_deleg_plan_sid				IN	security_pkg.T_SID_ID,
	in_root_region_sid				IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_exclude_not_due				IN	NUMBER DEFAULT 0,
	in_exclude_after				IN	DATE DEFAULT SYSDATE,
	in_active_regions_only			IN	NUMBER DEFAULT 0,
	out_deleg_plan_cur				OUT	SYS_REFCURSOR,
	out_region_role_members_cur		OUT	SYS_REFCURSOR,
	out_roles_cur					OUT	SYS_REFCURSOR,
	out_deleg_plan_col_cur 			OUT	SYS_REFCURSOR,
	out_regions_cur					OUT	SYS_REFCURSOR,
	out_sheets_cur 					OUT	SYS_REFCURSOR,
	out_deleg_user_cur				OUT	SYS_REFCURSOR
)
AS
	v_exclude_after					DATE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading delegation plan:' || in_deleg_plan_sid);
	END IF;

	v_exclude_after := in_exclude_after;
	IF v_exclude_after IS NULL THEN
		v_exclude_after := SYSDATE;
	END IF;

	-- XXX: check whether user has permissions on regions in plan?
	OPEN out_deleg_plan_cur FOR
		SELECT deleg_plan_sid, name, start_dtm, end_dtm, period_set_id, period_interval_id, nvl(last_applied_dynamic, 0) last_applied_dynamic
		  FROM deleg_plan
		 WHERE deleg_plan_sid = in_deleg_plan_sid;

	-- who is in each role for each region?
	OPEN out_region_role_members_cur FOR
		SELECT r.role_sid, rrm.region_sid, rrm.user_sid, cu.email, cu.full_name
		  FROM deleg_plan_role dpr
		  JOIN role r ON dpr.role_sid = r.role_sid AND dpr.app_sid = r.app_sid AND dpr.deleg_plan_sid = in_deleg_plan_sid
		  JOIN region_role_member rrm ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
		  JOIN region rg ON rrm.region_sid = NVL(rg.link_to_region_sid, rg.region_sid) AND rrm.app_sid = rg.app_sid
		  JOIN csr_user cu ON rrm.user_sid = cu.csr_user_sid AND rrm.app_sid = cu.app_sid
		  WHERE rg.region_sid IN (
			SELECT region_sid
			  FROM region
				START WITH (
					(in_root_region_sid IS NOT NULL AND region_sid = in_root_region_sid)
					OR
					(in_root_region_sid IS NULL AND region_sid IN (SELECT region_sid FROM deleg_plan_region WHERE deleg_plan_sid = in_deleg_plan_sid))
				)
				CONNECT BY PRIOR region_sid = parent_sid
		  )
		   AND (rg.active = 1 OR in_active_regions_only = 0);

	-- the roles in the plan (i.e the levels of the delegation structure)
	OPEN out_roles_cur FOR
		SELECT dpr.role_sid, r.name, dpr.pos
		  FROM deleg_plan_role dpr
		  JOIN role r ON dpr.role_sid = r.role_sid AND dpr.app_sid = r.app_sid
		 WHERE dpr.deleg_plan_sid = in_deleg_plan_sid
		 ORDER BY dpr.pos;

	-- the delegation templates along the top
	OPEN out_deleg_plan_col_cur FOR
		SELECT deleg_plan_col_id, label, type, object_sid, deleg_plan_sid
		  FROM v$deleg_plan_col
		 WHERE deleg_plan_sid = in_deleg_plan_sid
		   AND is_hidden = 0;

	-- the regions for the left-hand side
	-- use actual hierarchy for traversing the tree, but return link_to_region_sid instead of region_sid if there is one
	-- note that this returns the whole hierarchy below in_root_region_sid; those that are in scope for this delegation plan have is_in_scope = 1
	OPEN out_regions_cur FOR
		SELECT level lvl, rt.region_type, rt.label, rt.class_name,
			NVL(r.link_to_region_sid, r.region_sid) region_sid, r.name, r.description, r.parent_sid, r.pos, extract(r.info_xml,'/').getClobVal() info_xml,
			r.active, r.link_to_region_sid, r.geo_latitude, r.geo_longitude, r.geo_country, r.geo_region,
			r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref, ROWNUM rn
			FROM v$resolved_region_description r
			JOIN region_type rt ON r.region_type = rt.region_type
			WHERE (r.active = 1 OR in_active_regions_only = 0)
			START WITH (
				(in_root_region_sid IS NOT NULL AND r.region_sid = in_root_region_sid)
				OR
				(in_root_region_sid IS NULL AND r.region_sid IN (SELECT region_sid FROM deleg_plan_region WHERE deleg_plan_sid = in_deleg_plan_sid))
			)
			CONNECT BY PRIOR r.region_sid = r.parent_sid AND PRIOR active = 1
			ORDER SIBLINGS BY r.description;

	OPEN out_sheets_cur FOR
		WITH rt AS (
			SELECT r.region_sid, dpc.deleg_plan_col_id, dpdrd.maps_to_root_deleg_sid
			FROM csr.deleg_plan_deleg_region_deleg dpdrd
            JOIN csr.delegation_region r on r.delegation_sid = dpdrd.maps_to_root_deleg_sid
            JOIN csr.deleg_plan_col dpc on dpc.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
			WHERE dpc.deleg_plan_sid = in_deleg_plan_sid
			  AND dpc.is_hidden = 0
		)
		SELECT rt.deleg_plan_col_id,
			   rt.region_sid,
			   x.delegation_sid, x.lvl,
			   sla.sheet_id, sla.start_dtm, sla.end_dtm, sla.reminder_dtm, sla.submission_dtm, sla.last_action_id,
			   sla.last_action_dtm, sla.last_action_from_user_sid, sla.last_action_note, sla.status, sla.last_action_desc,
			   sla.percent_complete
		  FROM (
			SELECT app_sid, delegation_sid, level lvl, connect_by_root delegation_sid root_delegation_sid, rownum rn
			  FROM csr.delegation
				   START WITH delegation_sid in (
					SELECT maps_to_root_deleg_sid
					  FROM rt)
				   CONNECT BY PRIOR delegation_sid = parent_sid
		) x
		  JOIN rt ON rt.maps_to_root_deleg_sid = x.root_delegation_sid
		  JOIN sheet_with_last_action sla ON x.delegation_sid = sla.delegation_sid AND x.app_sid = sla.app_sid
		 WHERE sla.is_visible = 1 AND (sla.submission_dtm <= TRUNC(v_exclude_after) or in_exclude_not_due = 0)
		 ORDER BY x.rn, sla.start_dtm;
		 
	OPEN out_deleg_user_cur FOR
		WITH rt AS (
			SELECT maps_to_root_deleg_sid, dpdr.deleg_plan_col_id, dpdr.is_hidden, dpdrd.applied_to_region_sid region_sid
			  FROM v$deleg_plan_deleg_region dpdr
			  JOIN deleg_plan_deleg_region_deleg dpdrd
				ON dpdr.deleg_plan_col_deleg_id = dpdrd.deleg_plan_col_deleg_id
			   AND dpdr.region_sid = dpdrd.region_sid
			   AND dpdr.app_sid = dpdrd.app_sid
			 WHERE deleg_plan_sid = in_deleg_plan_sid
		)
		SELECT rt.deleg_plan_col_id,
			   rt.region_sid,
			   x.delegation_sid, x.lvl,
			   du.user_sid, cu.full_name, cu.email
		  FROM (
			SELECT app_sid, delegation_sid, level lvl, connect_by_root delegation_sid root_delegation_sid, rownum rn
			  FROM delegation
				   START WITH delegation_sid in (
					SELECT maps_to_root_deleg_sid
					  FROM rt)
				   CONNECT BY PRIOR delegation_sid = parent_sid
			) x
		  JOIN v$delegation_region dr ON x.delegation_sid = dr.delegation_sid 
		  JOIN rt ON rt.maps_to_root_deleg_sid = x.root_delegation_sid
		  JOIN delegation_user du ON x.delegation_sid = du.delegation_sid AND x.app_sid = du.app_sid AND du.inherited_from_sid = du.delegation_sid
		  JOIN csr_user cu ON du.user_sid = cu.csr_user_sid AND du.app_sid = cu.app_sid; 
		  
END;

PROCEDURE CopyPlanRoles(
	in_old_deleg_plan_sid	IN	deleg_plan.deleg_plan_sid%TYPE,
	in_new_deleg_plan_sid	IN	deleg_plan.deleg_plan_sid%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_old_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_new_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INSERT INTO deleg_plan_role (deleg_plan_sid, role_sid, pos)
		SELECT in_new_deleg_plan_sid, role_sid, pos
		  FROM deleg_plan_role
		 WHERE deleg_plan_sid = in_old_deleg_plan_sid;
END;

PROCEDURE DeleteDelegPlanDateSchedules(
	in_deleg_plan_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	UNSEC_INT_DeleteDelegPlanDateSchedules(in_deleg_plan_sid);
END;

PROCEDURE AddDelegPlanDateSchedule(
	in_deleg_plan_sid		IN security_pkg.T_SID_ID,
	in_role_sid				IN deleg_plan_date_schedule.role_sid%type,
	in_deleg_plan_col_id   	IN deleg_plan_date_schedule.deleg_plan_col_id%type,
	in_schedule_xml			IN deleg_plan_date_schedule.schedule_xml%type,
	in_reminder_offset		IN deleg_plan_date_schedule.reminder_offset%type
)
AS
	v_start_dtm							DATE;
	v_end_dtm							DATE;
	v_delegation_date_schedule_id 		deleg_plan_date_schedule.delegation_date_schedule_id%type;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	IF in_reminder_offset IS NOT NULL THEN
		UPDATE deleg_plan
		   SET reminder_offset = in_reminder_offset
		 WHERE app_sid = security.security_pkg.GetApp AND deleg_plan_sid = in_deleg_plan_sid;
	END IF;
	
	IF in_schedule_xml IS NULL THEN		-- fixed date schedule has been set up
		SELECT start_dtm, end_dtm
		  INTO v_start_dtm, v_end_dtm
		  FROM deleg_plan
		 WHERE deleg_plan_sid = in_deleg_plan_sid;

		INSERT INTO delegation_date_schedule (delegation_date_schedule_id, start_dtm, end_dtm)
		VALUES (delegation_date_schedule_seq.nextval, v_start_dtm, v_end_dtm)
		RETURNING delegation_date_schedule_id INTO v_delegation_date_schedule_id;
	ELSE
		UPDATE deleg_plan
		   SET schedule_xml = in_schedule_xml
		 WHERE app_sid = security.security_pkg.GetApp AND deleg_plan_sid = in_deleg_plan_sid;
	END IF;

	INSERT INTO deleg_plan_date_schedule (deleg_plan_sid, role_sid, deleg_plan_col_id, schedule_xml, reminder_offset, delegation_date_schedule_id)
	VALUES (in_deleg_plan_sid, in_role_sid, in_deleg_plan_col_id, in_schedule_xml, in_reminder_offset, v_delegation_date_schedule_id);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
		SYS_CONTEXT('SECURITY', 'APP'), in_deleg_plan_sid, 'Date schedule updated for role: {0} and deleg plan col: {1}', in_role_sid, in_deleg_plan_col_id);
END;

PROCEDURE AddDelegPlanDateScheduleEntry(
	in_deleg_plan_sid		IN security_pkg.T_SID_ID,
	in_role_sid				IN deleg_plan_date_schedule.role_sid%type,
	in_deleg_plan_col_id   	IN deleg_plan_date_schedule.deleg_plan_col_id%type,
	in_start_dtm 			IN DATE,
	in_creation_dtm			IN DATE,
	in_submission_dtm		IN DATE,
	in_reminder_dtm			IN DATE
)
AS
	v_delegation_date_schedule_id 		deleg_plan_date_schedule.delegation_date_schedule_id%type;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing delegation plan:' || in_deleg_plan_sid);
	END IF;

	SELECT delegation_date_schedule_id
	  INTO v_delegation_date_schedule_id
	  FROM deleg_plan_date_schedule
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND ((in_role_sid IS NULL AND role_sid IS NULL) OR role_sid = in_role_sid)
	   AND ((in_deleg_plan_col_id IS NULL AND deleg_plan_col_id IS NULL) OR deleg_plan_col_id = in_deleg_plan_col_id);

	INSERT INTO sheet_date_schedule (delegation_date_schedule_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
	VALUES (v_delegation_date_schedule_id, in_start_dtm, in_creation_dtm, in_submission_dtm, in_reminder_dtm);
END;

PROCEDURE AddSyncDelegWithMasterJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	AddJob(
		in_delegation_sid	=> in_delegation_sid,
		out_batch_job_id	=> out_batch_job_id
	);
END;

PROCEDURE AddApplyPlanJob(
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
BEGIN
	AddJob(
		in_deleg_plan_sid	=> in_deleg_plan_sid,
		in_is_dynamic_plan	=> in_is_dynamic_plan,
		in_overwrite_dates	=> in_overwrite_dates,
		out_batch_job_id	=> out_batch_job_id
	);
END;

PROCEDURE AddJob(
	in_delegation_sid				IN	deleg_plan_job.delegation_sid%TYPE DEFAULT NULL,
	in_deleg_plan_sid				IN	deleg_plan_job.deleg_plan_sid%TYPE DEFAULT NULL,
	in_is_dynamic_plan				IN	deleg_plan_job.is_dynamic_plan%TYPE DEFAULT 1,
	in_overwrite_dates				IN	deleg_plan_job.overwrite_dates%TYPE DEFAULT 0,
	in_dynamic_change				IN  BOOLEAN DEFAULT FALSE,
	out_batch_job_id				OUT	batch_job.batch_job_id%TYPE
)
AS
	v_batch_job_id					batch_job.batch_job_id%TYPE;
	v_description					VARCHAR2(4000);
	v_request_as_user_sid			security_pkg.T_SID_ID;
BEGIN
	-- I don't think this needs an 'at all costs prevent duplicates' actually
	-- csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_DELEG_PLAN);
	
	IF in_dynamic_change THEN
		v_request_as_user_sid := security_pkg.SID_BUILTIN_ADMINISTRATOR;
	ELSE
		v_request_as_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	END IF;

	FOR r IN (SELECT batch_job_id
				FROM batch_job
			   WHERE batch_job_type_id = batch_job_pkg.JT_DELEGATION_SYNC
				 AND completed_dtm IS NULL
				 AND processing = 0
				 AND requested_by_user_sid = v_request_as_user_sid
				 AND batch_job_id IN (
						SELECT batch_job_id
						  FROM deleg_plan_job
						 WHERE (in_delegation_sid IS NOT NULL AND delegation_sid = in_delegation_sid)
							OR (in_deleg_plan_sid IS NOT NULL AND deleg_plan_sid = in_deleg_plan_sid AND
								in_is_dynamic_plan = is_dynamic_plan))
				 FOR UPDATE) LOOP

		UPDATE deleg_plan_job
		   SET overwrite_dates = GREATEST(overwrite_dates, in_overwrite_dates)
		 WHERE batch_job_id = r.batch_job_id;

		out_batch_job_id := r.batch_job_id;
		RETURN;
	END LOOP;

	IF in_delegation_sid IS NOT NULL THEN
		SELECT name
		  INTO v_description
		  FROM delegation
		 WHERE delegation_sid = in_delegation_sid;
	ELSE
		SELECT name
		  INTO v_description
		  FROM deleg_plan
		 WHERE deleg_plan_sid = in_deleg_plan_sid;
	END IF;

	batch_job_pkg.Enqueue(
		in_batch_job_type_id		=> batch_job_pkg.JT_DELEGATION_SYNC,
		in_description				=> v_description,
		in_requesting_user			=> v_request_as_user_sid,
		out_batch_job_id			=> v_batch_job_id
	);

	INSERT INTO deleg_plan_job
		(batch_job_id, delegation_sid, deleg_plan_sid, is_dynamic_plan, overwrite_dates)
	VALUES
		(v_batch_job_id, in_delegation_sid, in_deleg_plan_sid, in_is_dynamic_plan, in_overwrite_dates);

	INSERT INTO delegation_batch_job_export
		(batch_job_id)
	VALUES
		(v_batch_job_id);

	out_batch_job_id := v_batch_job_id;
END;

PROCEDURE SetFile (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	in_blob							IN 	BLOB,
	in_file_name					IN	batch_job_batched_export.file_name%TYPE)
AS
BEGIN
	UPDATE delegation_batch_job_export
	   SET file_blob = in_blob,
		   file_name = in_file_name
	 WHERE batch_job_id = in_batch_job_id;
END;

FUNCTION SecCheckFile(
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE
) RETURN NUMBER
AS
	v_requested_by			batch_job.requested_by_user_sid%TYPE;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 1 THEN
		RETURN 1;
	END IF;
	
	SELECT requested_by_user_sid
	  INTO v_requested_by
	  FROM batch_job
	 WHERE batch_job_id = in_batch_job_id;
	
	IF v_requested_by = SYS_CONTEXT('SECURITY', 'SID') THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE GetFile (
	in_batch_job_id					IN	batch_job.batch_job_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF SecCheckFile(in_batch_job_id) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing file');
	END IF;

	OPEN out_cur FOR
		SELECT file_blob, file_name
		  FROM delegation_batch_job_export
		 WHERE batch_job_id = in_batch_job_id;
END;

PROCEDURE SetPeriod(
	in_delegation_sid				IN	security_pkg.T_SID_ID,
	in_period_set_id				IN	delegation.period_set_id%TYPE,
	in_period_interval_id			IN	delegation.period_interval_id%TYPE,
	in_day_of_period 				IN	NUMBER,
	in_force						IN	NUMBER DEFAULT 0
)
AS
	v_period_set_id					delegation.period_set_id%TYPE;
	v_period_interval_id			delegation.period_interval_id%TYPE;
	v_delegation_sid				security_pkg.T_SID_ID;
	v_cnt							NUMBER(10);
	v_end_month						VARCHAR2(255);
	v_from_interval_n				NUMBER(10);
	v_to_interval_n					NUMBER(10);
	v_start_dtm						DATE;
	v_end_dtm						DATE;
	v_delegation_date_schedule_id 	deleg_plan_date_schedule.delegation_date_schedule_id%type;
	v_reminder						NUMBER(10);
	v_year							NUMBER(10);
BEGIN
	-- check if there's a higher delegation, this part seems pointless how could a parent have a different period set or interval?
	BEGIN
		SELECT dp.period_set_id, dp.period_interval_id, dp.delegation_sid
		  INTO v_period_set_id, v_period_interval_id, v_delegation_sid
		  FROM delegation d
		  JOIN delegation dp ON d.parent_sid = dp.delegation_sid
		 WHERE d.delegation_sid = in_delegation_sid;
		
		SELECT COUNT(period_interval_id)
		  INTO v_to_interval_n
		  FROM period_interval_member
		 WHERE period_interval_id = in_period_interval_id;
		
		SELECT COUNT(period_interval_id)
		  INTO v_from_interval_n
		  FROM period_interval_member
		 WHERE period_interval_id = v_period_interval_id;

		IF in_period_set_id != v_period_set_id THEN
			RAISE_APPLICATION_ERROR(-20001, 'Parent delegation has different period set ('||v_period_set_id||') than requested ('||in_period_set_id||')');
		END IF;
		
		IF v_to_interval_n > v_from_interval_n THEN
			RAISE_APPLICATION_ERROR(-20001, 'Parent delegation has shorter period interval ('||v_period_interval_id||') than requested ('||in_period_interval_id||')');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- ignore -- we're at the top of the tree
			NULL;
	END;

	FOR drow IN (
		-- get delegations down the tree
		SELECT delegation_sid, period_interval_id
		  FROM delegation
		 WHERE period_interval_id != in_period_interval_id OR period_set_id != in_period_set_id
		 START WITH delegation_sid = in_delegation_sid
	   CONNECT BY PRIOR delegation_sid = parent_sid
	)
	LOOP
		IF in_force = 0 THEN
			-- check whether there's data
			SELECT COUNT(*)
			  INTO v_cnt
			  FROM sheet s
			  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
			 WHERE s.delegation_sid = drow.delegation_sid
			   AND (val_number IS NOT NULL OR note IS NOT NULL);

			IF v_cnt > 0 THEN
				RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SHEETS_EXIST, 'Sheets for delegation '||drow.delegation_sid||' have values');
			END IF;
		END IF;

		-- delete existing sheets
		FOR sr IN (
			SELECT sheet_id
			  FROM sheet
			 WHERE delegation_sid = drow.delegation_sid
		)
		LOOP
			sheet_pkg.DeleteSheet(sr.sheet_id);
		END LOOP;
		
		-- month for annual delegations
		SELECT TO_CHAR(end_dtm, 'mon'), delegation_date_schedule_id
		  INTO v_end_month, v_delegation_date_schedule_id
		  FROM delegation d
		 WHERE d.delegation_sid = drow.delegation_sid;
 
		UPDATE delegation
		   SET period_set_id = in_period_set_id,
			   period_interval_id = in_period_interval_id,
			   delegation_date_schedule_id = null,
			   schedule_xml =
				CASE
					WHEN in_period_set_id != 1 THEN NULL
					WHEN in_period_interval_id = 4 THEN '<recurrences><yearly><day number="'||in_day_of_period||'" month="'||v_end_month||'"/></yearly></recurrences>'
					WHEN in_period_interval_id = 3 THEN '<recurrences><monthly every-n="6"><day number="'||in_day_of_period||'"/></monthly></recurrences>'
					WHEN in_period_interval_id = 2 THEN '<recurrences><monthly every-n="3"><day number="'||in_day_of_period||'"/></monthly></recurrences>'
					WHEN in_period_interval_id = 1 THEN '<recurrences><monthly every-n="1"><day number="'||in_day_of_period||'"/></monthly></recurrences>'
				END
		 WHERE delegation_sid = drow.delegation_sid;
		

		DELETE FROM sheet_date_schedule WHERE delegation_date_schedule_id = v_delegation_date_schedule_id;
		DELETE FROM delegation_date_schedule WHERE delegation_date_schedule_id = v_delegation_date_schedule_id;
		
		-- <audit>
		csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_DELEGATION, security_pkg.getApp, drow.delegation_sid,
			'Period', drow.period_interval_id, in_period_interval_id);
	END LOOP;
END;

PROCEDURE UpdateDateSchedule(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_delegation_sid		IN  delegation.delegation_sid%TYPE,
	in_schedule_xml			IN  delegation.schedule_xml%TYPE,
	in_reminder_offset		IN	delegation.reminder_offset%TYPE,
	in_date_schedule_id		IN	deleg_plan_date_schedule.delegation_date_schedule_id%TYPE
)
AS
	v_start_dtm							DATE;
	v_end_dtm							DATE;
	v_delegation_date_schedule_id 		deleg_plan_date_schedule.delegation_date_schedule_id%type;
BEGIN
	-- check permissions
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	SELECT delegation_date_schedule_id
	  INTO v_delegation_date_schedule_id
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	IF v_delegation_date_schedule_id IS NOT NULL THEN
		-- delete old fixed schedule
		DELETE FROM sheet_date_schedule
		 WHERE delegation_date_schedule_id = v_delegation_date_schedule_id;

		UPDATE delegation
		   SET delegation_date_schedule_id = NULL
		 WHERE delegation_sid = in_delegation_sid;

		DELETE FROM delegation_date_schedule
		 WHERE delegation_date_schedule_id = v_delegation_date_schedule_id;
	END IF;

	IF in_date_schedule_id IS NOT NULL THEN
		-- copy fixed date schedule
		SELECT start_dtm, end_dtm
		  INTO v_start_dtm, v_end_dtm
		  FROM delegation_date_schedule
		 WHERE delegation_date_schedule_id = in_date_schedule_id;

		INSERT INTO delegation_date_schedule (delegation_date_schedule_id, start_dtm, end_dtm)
		VALUES (delegation_date_schedule_seq.nextval, v_start_dtm, v_end_dtm)
		RETURNING delegation_date_schedule_id INTO v_delegation_date_schedule_id;

		INSERT INTO sheet_date_schedule (delegation_date_schedule_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm)
		SELECT v_delegation_date_schedule_id, start_dtm, creation_dtm, submission_dtm, reminder_dtm
		  FROM sheet_date_schedule
		 WHERE delegation_date_schedule_id = in_date_schedule_id;

		UPDATE delegation
		   SET delegation_date_schedule_id = v_delegation_date_schedule_id
		 WHERE delegation_sid = in_delegation_sid;
	END IF;

	UPDATE delegation
	   SET schedule_xml = in_schedule_xml,
		   reminder_offset = in_reminder_offset
	 WHERE delegation_sid = in_delegation_sid;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'), in_delegation_sid,
		'Updated date schedule');
END;

PROCEDURE UpdateSheetDates(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_delegation_sid				IN	delegation.delegation_sid%TYPE
)
AS
	v_recurrence					RECURRENCE_PATTERN;
	v_submission_dtm				DATE;
	v_reminder_dtm					DATE;
	v_submission_dates				T_RECURRENCE_DATES;
BEGIN
	-- check permissions
	IF NOT delegation_pkg.CheckDelegationPermission(in_act_id, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_ALTER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the delegation with sid '||in_delegation_sid);
	END IF;

	FOR r IN (
		SELECT d.schedule_xml, d.reminder_offset, DECODE(d.period_interval_id, 4, 12, 3, 6, 2, 3, 1, 1) interval_in_months,
			   d.delegation_date_schedule_id, d.end_dtm delegation_end_dtm, d.period_set_id,
			   s.sheet_id, s.start_dtm, s.end_dtm, s.submission_dtm, s.reminder_dtm,
			   dp.delegation_sid parent_delegation_sid, dp.schedule_xml parent_schedule_xml,
			   sp.sheet_id parent_sheet_id, sp.submission_dtm parent_submission_dtm, sp.reminder_dtm parent_reminder_dtm
		  FROM delegation d
		  JOIN sheet s ON s.app_sid = d.app_sid AND s.delegation_sid = d.delegation_sid
		  LEFT JOIN delegation dp ON dp.app_sid = d.app_sid AND dp.delegation_sid = d.parent_sid
		  LEFT JOIN sheet sp ON sp.app_sid = dp.app_sid AND sp.delegation_sid = dp.delegation_sid AND sp.start_dtm = s.start_dtm
		 WHERE d.delegation_sid = in_delegation_sid
	) LOOP
		IF r.period_set_id = 1 THEN
			v_recurrence := RECURRENCE_PATTERN(XMLType(r.schedule_xml));
			v_recurrence.MakeOccurrences(r.end_dtm, ADD_MONTHS(r.delegation_end_dtm, r.interval_in_months));

			v_submission_dates := v_recurrence.GetOccurrencesOnOrAfter(r.end_dtm);
			IF v_submission_dates.COUNT = 0 THEN
				-- eek! haven't found anything...
				RAISE_APPLICATION_ERROR(-20001, 'No submission date found for period when creating sheet for delegation '||in_delegation_sid);
			END IF;
			
			v_submission_dtm := v_submission_dates(v_submission_dates.FIRST);
			v_reminder_dtm := v_submission_dates(v_submission_dates.FIRST) - r.reminder_offset;
		END IF;
		
		IF r.parent_delegation_sid IS NULL OR r.parent_sheet_id IS NOT NULL THEN

			IF r.delegation_date_schedule_id IS NULL THEN	-- delegation chain uses a recurring date schedule (based on schedule_xml)

				IF r.parent_schedule_xml IS NOT NULL AND XMLTYPE(r.parent_schedule_xml).extract('/').getStringVal() = XMLTYPE(r.schedule_xml).extract('/').getStringVal() THEN
					v_reminder_dtm := r.parent_reminder_dtm;
					v_submission_dtm := r.parent_submission_dtm;
				ELSE
					v_reminder_dtm := LEAST(v_submission_dtm, NVL(r.parent_submission_dtm, v_submission_dtm)) - r.reminder_offset;
					v_submission_dtm := LEAST(v_submission_dtm, NVL(r.parent_submission_dtm, v_submission_dtm));
				END IF;
			ELSE										-- delegation chain uses a fixed date schedule
				-- if present use fixed due and reminder dtm, otherwise use sensible dates
				SELECT NVL(sds.submission_dtm, d.end_dtm), NVL(sds.reminder_dtm, d.end_dtm)
				  INTO v_submission_dtm, v_reminder_dtm
				  FROM delegation d
				  LEFT JOIN sheet_date_schedule sds ON sds.app_sid = d.app_sid AND sds.delegation_date_schedule_id = d.delegation_date_schedule_id AND sds.start_dtm = r.start_dtm
				 WHERE d.delegation_sid = in_delegation_sid;
				 
				IF v_submission_dtm > NVL(r.parent_submission_dtm, v_submission_dtm) THEN
					v_reminder_dtm := r.parent_submission_dtm + (v_reminder_dtm - v_submission_dtm);
					v_submission_dtm := r.parent_submission_dtm;
				END IF;
			END IF;

			UPDATE sheet
			   SET submission_dtm = v_submission_dtm,
				   reminder_dtm = v_reminder_dtm
			 WHERE delegation_sid = in_delegation_sid
			   AND start_dtm = r.start_dtm;

			-- <audit>
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'),
				in_delegation_sid, 'Reminder date for sheet "' || r.sheet_id || '"', TRUNC(r.reminder_dtm, 'dd'), TRUNC(v_reminder_dtm, 'dd'));
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, SYS_CONTEXT('SECURITY', 'APP'),
				in_delegation_sid, 'Submission date for sheet "' || r.sheet_id || '"', TRUNC(r.submission_dtm, 'dd'), TRUNC(v_submission_dtm, 'dd'));
		END IF;
	END LOOP;
END;

PROCEDURE GetChangesSinceLastApplied(
	in_deleg_plan_sid     IN  deleg_plan.deleg_plan_sid%TYPE,
	in_limit_count        IN  NUMBER,
	out_cur               OUT SYS_REFCURSOR,
	out_count             OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_deleg_plan_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT change_date, full_name
		  FROM (
			SELECT TRUNC(al.audit_date) change_date, cu.full_name
			  FROM csr.audit_log al
			  JOIN csr.csr_user cu
				   ON al.user_sid = cu.csr_user_sid
				  AND al.app_sid = cu.app_sid
			  JOIN csr.deleg_plan dp
				   ON dp.deleg_plan_sid = al.object_sid
				  AND dp.app_sid = al.app_sid
			 WHERE al.object_sid = in_deleg_plan_sid
			   AND dp.last_applied_dtm < audit_date
			 GROUP BY TRUNC(al.audit_date), full_name
			 ORDER BY TRUNC(al.audit_date) DESC
			)
		WHERE rownum <= in_limit_count;

	OPEN out_count FOR
		SELECT count(*) total_count
		  FROM (
			SELECT count(full_name) 
			  FROM csr.audit_log al
			  JOIN csr.csr_user cu
			       ON al.user_sid = cu.csr_user_sid
			      AND al.app_sid = cu.app_sid
			  JOIN csr.deleg_plan dp
			       ON dp.deleg_plan_sid = al.object_sid
			      AND dp.app_sid = al.app_sid
			 WHERE al.object_sid = in_deleg_plan_sid
			   AND dp.last_applied_dtm < audit_date
			 GROUP BY TRUNC(al.audit_date), full_name
		);
END;

/*
  TestOnly_ProcessApplyPlanJob is only used for testing
*/
PROCEDURE TestOnly_ProcessApplyPlanJob(	
	in_deleg_plan_sid   	    	IN	security_pkg.T_SID_ID,
	in_is_dynamic_plan      		IN	NUMBER DEFAULT 1,
	in_overwrite_dates				IN	NUMBER DEFAULT 0,
	out_created						OUT	NUMBER
)
AS
BEGIN
	ProcessApplyPlanJob(
		in_batch_job_id		=> NULL,
		in_deleg_plan_sid   => in_deleg_plan_sid,
		in_is_dynamic_plan  => in_is_dynamic_plan,
		in_overwrite_dates	=> in_overwrite_dates,
		out_created			=> out_created
	);
END;

PROCEDURE Internal_AssertPlanAndDelegSid(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID
)
AS
	v_sid					NUMBER;
BEGIN

	BEGIN
		SELECT deleg_plan_sid
		  INTO v_sid
		  FROM deleg_plan
		 WHERE deleg_plan_sid = in_deleg_plan_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The specified delegation plan sid could not be found.');
	END;

	BEGIN
		SELECT delegation_sid
		  INTO v_sid
		  FROM delegation
		 WHERE delegation_sid = in_deleg_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The specified delegation sid could not be found.');
	END;
END;

/*
	Internal only. Called by TickDelegPlanRegions_Append and TickDelegPlanRegions_NonAppend, above.
*/


PROCEDURE Internal_TickDelegPlanRegions(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID,
	in_region_sids			IN	security.security_pkg.T_SID_IDS,
	out_regions_t			OUT	security.T_SID_TABLE,
	out_deleg_plan_col_id	OUT	deleg_plan_col.deleg_plan_col_id%TYPE
)
AS
	v_region_cnt			NUMBER;
BEGIN
	Internal_AssertPlanAndDelegSid(in_deleg_plan_sid => in_deleg_plan_sid, in_deleg_sid => in_deleg_sid);
	
	SELECT deleg_plan_col_id
	  INTO out_deleg_plan_col_id
	  FROM deleg_plan_col
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND deleg_plan_col_deleg_id IN (
			SELECT deleg_plan_col_deleg_id
			FROM deleg_plan_col_deleg
			WHERE delegation_sid = in_deleg_sid
	   )
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	out_regions_t := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (
		SELECT column_value region_sid
		  FROM TABLE(out_regions_t)
	)
	LOOP
		SELECT COUNT(*)
		  INTO v_region_cnt
		  FROM deleg_plan_deleg_region
		 WHERE region_sid = r.region_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		IF v_region_cnt = 0 THEN
			BEGIN
				UpdateDelegPlanColRegion(
					in_deleg_plan_col_id		=> out_deleg_plan_col_id,
					in_region_sid				=> r.region_sid,
					in_region_selection			=> csr_data_pkg.DELEG_PLAN_SEL_S_REGION,
					in_tag_id					=> NULL,
					in_region_type				=> NULL
				);
			EXCEPTION
			WHEN OTHERS THEN
				IF SQLCODE = -2291 THEN	-- Parent key not found
					RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'Region sid '||r.region_sid||' could not be found.');
				ELSE
					RAISE;
				END IF;
		END;
		END IF;
		
	END LOOP;
END;

/*
	Used by the delegation planner bulk tick page. Replaces the ticker script on Hathor.
	This "Append" version only adds regions to the selected delegation plan/delegation, and does not look 
	at any regions which are not supplied, they will be left unchanged.
	For the regions which are supplied, if an entry already exists then we ignore it. We do this because we want the 
	row to remain unchanged - eg the region selection and tag id - but we don't accept those values as inputs. So we ignore 
	the rows so they are unchanged. Regions which do not will call the SP and are always set as "This region only" (R).
*/
PROCEDURE TickDelegPlanRegions_Append(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID,
	in_region_sids			IN	security.security_pkg.T_SID_IDS
)
AS
	t						security.T_SID_TABLE;
	v_region_cnt			NUMBER;
	v_deleg_plan_col_id		deleg_plan_col.deleg_plan_col_id%TYPE;
BEGIN

	Internal_TickDelegPlanRegions(
		in_deleg_plan_sid		=> in_deleg_plan_sid,
		in_deleg_sid			=> in_deleg_sid,
		in_region_sids			=> in_region_sids,
		out_regions_t			=> t,
		out_deleg_plan_col_id	=> v_deleg_plan_col_id
	);

END;

/*
	Used by the delegation planner bulk tick page. Replaces the ticker script on Hathor.
	This "Non-Append" version sets the state for all the supplied regions AND those already on the delegation plan; Eg any 
	currently on the plan that are not supplied will be removed/unticked. 
	For the regions which are supplied, if an entry already exists then we ignore it. We do this because we want the 
	row to remain unchanged - eg the region selection and tag id - but we don't accept those values as inputs. So we ignore 
	the rows so they are unchanged. Regions which do not will call the SP and are always set as "This region only" (R).
*/
PROCEDURE TickDelegPlanRegions_NonAppend(
	in_deleg_plan_sid		IN	security.security_pkg.T_SID_ID,
	in_deleg_sid			IN	security.security_pkg.T_SID_ID,
	in_region_sids			IN	security.security_pkg.T_SID_IDS
)
AS
	t						security.T_SID_TABLE;
	v_region_cnt			NUMBER;
	v_deleg_plan_col_id		deleg_plan_col.deleg_plan_col_id%TYPE;
BEGIN

	Internal_TickDelegPlanRegions(
		in_deleg_plan_sid		=> in_deleg_plan_sid,
		in_deleg_sid			=> in_deleg_sid,
		in_region_sids			=> in_region_sids,
		out_regions_t			=> t,
		out_deleg_plan_col_id	=> v_deleg_plan_col_id
	);
	
	/* 
	Now handle deletions. Anything on the list of regions which isn't in the supplied 
	list of regions should be removed. We call the same SP but with no region selection
	and the SP treats that as a removal.
	*/
	FOR r IN (
		SELECT region_sid 
		  FROM deleg_plan_deleg_region
		 WHERE region_sid NOT IN (
			SELECT column_value region_sid
			  FROM TABLE(t)
		 )
	)
	LOOP
		BEGIN
			UpdateDelegPlanColRegion(
				in_deleg_plan_col_id		=> v_deleg_plan_col_id,
				in_region_sid				=> r.region_sid,
				in_region_selection			=> '',
				in_tag_id					=> NULL,
				in_region_type				=> NULL
			);
		EXCEPTION
			WHEN OTHERS THEN
				IF SQLCODE = 2291 THEN	-- Parent key not found
					RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'Region sid '||r.region_sid||' could not be found.');
				ELSE
					RAISE;
				END IF;
		END;
	END LOOP;

END;

PROCEDURE UNSEC_GetAllDelegPlanForExport(
	out_plan_cur				OUT	SYS_REFCURSOR,
	out_col_cur					OUT	SYS_REFCURSOR,
	out_template_cur			OUT	SYS_REFCURSOR,
	out_template_desc_cur		OUT	SYS_REFCURSOR,
	out_template_ind_cur		OUT	SYS_REFCURSOR,
	out_template_ind_desc_cur	OUT	SYS_REFCURSOR,
	out_form_expr_cur			OUT	SYS_REFCURSOR,
	out_form_expr_map_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_plan_cur FOR
		SELECT deleg_plan_sid, dp.name, start_dtm, end_dtm, reminder_offset,
			   period_set_id, period_interval_id, schedule_xml, dynamic, 
			   name_template, notes, active, so.parent_sid_id parent_sid
		  FROM deleg_plan dp
		  JOIN security.securable_object so ON so.sid_id = deleg_plan_sid
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY name;
	
	OPEN out_col_cur FOR
		SELECT col.deleg_plan_sid, col.deleg_plan_col_id, d.deleg_plan_col_deleg_id, 
			   is_hidden, delegation_sid
		  FROM deleg_plan_col col
		  JOIN deleg_plan_col_deleg d ON col.deleg_plan_col_deleg_id = d.deleg_plan_col_deleg_id
		 WHERE col.deleg_plan_col_deleg_id IS NOT NULL
		   AND col.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_template_cur FOR
		SELECT delegation_sid, name, schedule_xml, note, period_set_id, 
			   period_interval_id, group_by, allocate_users_to, start_dtm, 
			   end_dtm, reminder_offset, is_note_mandatory, editing_url, 
			   show_aggregate, hide_sheet_period, tag_visibility_matrix_group_id, 
			   allow_multi_period, is_flag_mandatory, submission_offset
		  FROM delegation
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_template_desc_cur FOR
		SELECT delegation_sid, lang, description
		  FROM delegation_description
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_template_ind_cur FOR
		SELECT delegation_sid, ind_sid, mandatory, pos, visibility, 
			   css_class, allowed_na
		  FROM delegation_ind
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_template_ind_desc_cur FOR
		SELECT delegation_sid, ind_sid, lang, description
		  FROM delegation_ind_description
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		   
	OPEN out_form_expr_cur FOR 
		SELECT form_expr_id, delegation_sid, description, expr
		  FROM form_expr
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY delegation_sid;

	
	OPEN out_form_expr_map_cur FOR
		SELECT delegation_sid, ind_sid, form_expr_id
		  FROM deleg_ind_form_expr
		 WHERE delegation_sid IN (
			SELECT DISTINCT delegation_sid
			  FROM deleg_plan_col_deleg
			 )
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY delegation_sid;
END;

PROCEDURE OnRegionMove(
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_old_parent_sid 	IN 	security.security_pkg.T_SID_ID
)
AS
BEGIN
	-- Remove region or mark as delete next apply plan if moved out.
	FOR r IN (
		SELECT deleg_plan_col_id
		  FROM v$deleg_plan_deleg_region d
		 WHERE region_sid = in_region_sid
		   AND (
				NOT EXISTS(
					SELECT NULL
					  FROM region
					 WHERE region_sid = in_region_sid
					 START WITH region_sid IN (SELECT region_sid FROM csr.deleg_plan_region WHERE deleg_plan_sid = d.deleg_plan_sid)
				   CONNECT BY PRIOR region_sid = parent_sid
				)
				 OR EXISTS(
					SELECT NULL
					  FROM region r
					  JOIN v$deleg_plan_deleg_region d2 ON r.region_sid = d2.region_sid
					 WHERE r.region_sid != in_region_sid
					 START WITH r.region_sid = in_region_sid
				   CONNECT BY PRIOR r.parent_sid = r.region_sid
			   )
			)
	)
	LOOP
		UpdateDelegPlanColRegion(
			in_deleg_plan_col_id 	=> r.deleg_plan_col_id,
			in_region_sid 			=> in_region_sid,
			in_region_selection 	=> NULL,
			in_tag_id 				=> NULL,
			in_region_type 			=> NULL
		);
	END LOOP;
	
	-- Remove mark for deletion if moved back in. (Not much we can do for unapplied plans where the row is deleted.)
	-- (for dynamic plans this will be a short window as a reapply is scheduled on move)
	FOR r IN (
		SELECT deleg_plan_sid, deleg_plan_col_deleg_id
		  FROM v$deleg_plan_deleg_region d
		 WHERE region_sid = in_region_sid
		   AND pending_deletion = 1
		   AND EXISTS( -- Region is in deleg plan region tree
				SELECT NULL
				  FROM region
				 WHERE region_sid = in_region_sid
				 START WITH region_sid IN (SELECT region_sid FROM deleg_plan_region WHERE deleg_plan_sid = d.deleg_plan_sid)
			   CONNECT BY PRIOR region_sid = parent_sid
			)
		   AND NOT EXISTS( -- Old parent is not in deleg plan region tree
				SELECT NULL
				  FROM region
				 WHERE region_sid = in_old_parent_sid
				 START WITH region_sid IN (SELECT region_sid FROM deleg_plan_region WHERE deleg_plan_sid = d.deleg_plan_sid)
			   CONNECT BY PRIOR region_sid = parent_sid
			)
	)
	LOOP
		UPDATE deleg_plan_deleg_region
		   SET pending_deletion = 0
		 WHERE region_sid = in_region_sid
		   AND deleg_plan_col_deleg_id = r.deleg_plan_col_deleg_id;
		   
		csr_data_pkg.WriteAuditLogEntry(
			SYS_CONTEXT('SECURITY', 'ACT'),
			csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA,
			SYS_CONTEXT('SECURITY', 'APP'),
			r.deleg_plan_sid,
			'Un-marked for deletion - delegation template ({0}) and region ({1})',
			r.deleg_plan_col_deleg_id,
			in_region_sid);
	END LOOP;
END;

FUNCTION HasSelectedChildren(
	in_deleg_plan_sid			IN	security_pkg.T_SID_ID,
	in_deleg_plan_col_id		IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID
)
RETURN NUMBER
AS
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col dpc ON dpdr.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id
	 WHERE deleg_plan_sid = in_deleg_plan_sid
	   AND deleg_plan_col_id = in_deleg_plan_col_id
	   AND EXISTS (
			SELECT NULL
			  FROM region
			 WHERE region_sid = dpdr.region_sid
			 START WITH parent_sid = in_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		);
		
	RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END; 
END;

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.Templated_Report_Schedule_Pkg AS

-- Securable object callbacks.
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
) AS
BEGIN	
	IF in_new_name IS NOT NULL THEN
		UPDATE TPL_REPORT_SCHEDULE 
		   SET name = in_new_name 
		 WHERE schedule_sid = in_sid_id;
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS
BEGIN
	--region entries
	DELETE FROM TPL_REPORT_SCHEDULE_REGION
	 WHERE schedule_sid = in_sid_id;
	 
	--Batch entries
	DELETE FROM TPL_REPORT_SCHED_BATCH_RUN
	 WHERE schedule_sid = in_sid_id;
	
	--Existing batch jobs
	UPDATE BATCH_JOB_TEMPLATED_REPORT
	   SET schedule_sid = null
	 WHERE schedule_sid = in_sid_id;
	
	--Saved doc references
	DELETE FROM TPL_REPORT_SCHED_SAVED_DOC
	 WHERE schedule_sid = in_sid_id;
	
	--Main entry
	DELETE FROM TPL_REPORT_SCHEDULE
	 WHERE schedule_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	NULL;
END;

PROCEDURE CreateSchedule(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tpl_report_sid			IN	TPL_REPORT_SCHEDULE.TPL_REPORT_SID%TYPE,
	in_owner_user_sid			IN	TPL_REPORT_SCHEDULE.OWNER_USER_SID%TYPE,
	in_name						IN	TPL_REPORT_SCHEDULE.NAME%TYPE,
	in_region_selection_type_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN	TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN	TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN	TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN	TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN	TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN	TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN	TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN	TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN	TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN	TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_scenario_run_sid			IN	TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	out_schedule_sid			OUT security_pkg.T_SID_ID
)
AS
	v_can_manage_all		NUMBER(1);
	v_current_owner			TPL_REPORT_SCHEDULE.OWNER_USER_SID%TYPE;
BEGIN
	IF security_pkg.sql_IsAccessAllowedSID(in_act_id, in_tpl_report_sid, security_pkg.PERMISSION_WRITE)=0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to save settings for this report.');
	END IF;

	IF csr_data_pkg.CheckCapability('Manage all templated report settings') OR csr_user_pkg.IsSuperAdmin = 1 THEN
		v_can_manage_all := 1;
	ELSE
		v_can_manage_all := 0;
	END IF;

	--Create the new SO
	BEGIN
		group_pkg.CreateGroupWithClass(in_act_id, in_tpl_report_sid, security_pkg.GROUP_TYPE_SECURITY,
			in_name, class_pkg.getClassID('CSRTemplatedReportsSchedule'), out_schedule_sid);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			--Alrready exists. If they can overwrite it, throw already exists. If not, throw permission denied.
			SELECT owner_user_sid
			  INTO v_current_owner
			  FROM TPL_REPORT_SCHEDULE
			 WHERE SCHEDULE_SID = (
					SELECT sid_id
					  FROM SECURITY.SECURABLE_OBJECT 
					 WHERE parent_sid_id = in_tpl_report_sid
					   AND name = in_name); 
			
			IF(v_can_manage_all = 1 OR v_current_owner = SYS_CONTEXT('SECURITY', 'SID')) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Schedule already exists with name '||in_name);
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Permission denied saving schedule with name '||in_name);
			END IF;
	END;

	--Insert into the table.
	INSERT INTO TPL_REPORT_SCHEDULE
		(schedule_sid, tpl_report_sid, owner_user_sid, name, region_selection_type_id, region_selection_tag_id,
		 include_inactive_regions, one_report_per_region, schedule_xml, offset, use_unmerged, output_as_pdf, 
		 role_sid, email_owner_on_complete, doc_folder_sid, overwrite_existing, scenario_run_sid, 
		 publish_to_prop_doc_lib)
	VALUES
		(out_schedule_sid, in_tpl_report_sid, in_owner_user_sid, in_name, in_region_selection_type_id, 
		 in_region_selection_tag_id, in_include_inactive_regions, in_one_report_per_region, in_schedule_xml,
		 in_offset, in_use_unmerged, in_output_as_pdf, in_role_sid, in_email_owner_on_complete, in_doc_folder,
		 in_overwrite_existing, in_scenario_run_sid, in_publish_to_prop_doc_lib);

	-- <audit> 
	--csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_DELEGATION, in_app_sid, out_delegation_sid, 'Created');
END;

PROCEDURE UpdateSchedule(
	in_schedule_sid				IN	TPL_REPORT_SCHEDULE.SCHEDULE_SID%TYPE,
	in_region_selection_type_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN	TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN	TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN	TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN	TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN	TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN	TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN	TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN	TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN	TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN	TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN	TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	in_scenario_run_sid			IN	TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE
)
AS
	v_can_manage_all		NUMBER(1);
	v_current_owner			TPL_REPORT_SCHEDULE.OWNER_USER_SID%TYPE;
BEGIN
	IF csr_data_pkg.CheckCapability('Manage all templated report settings') OR csr_user_pkg.IsSuperAdmin = 1 THEN
		v_can_manage_all := 1;
	ELSE
		v_can_manage_all := 0;
	END IF;
	
	SELECT owner_user_sid
	  INTO v_current_owner
	  FROM tpl_report_schedule
	 WHERE schedule_sid = in_schedule_sid;
	
	IF (v_can_manage_all = 0 AND v_current_owner != SYS_CONTEXT('SECURITY', 'SID')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied overwriting schedule '||in_schedule_sid);
	END IF;

	--Update the schedule.
	UPDATE TPL_REPORT_SCHEDULE
	   SET region_selection_type_id = in_region_selection_type_id, 
	       include_inactive_regions = in_include_inactive_regions,
		   one_report_per_region 	= in_one_report_per_region,
		   schedule_xml 			= in_schedule_xml,
		   offset 					= in_offset,
		   use_unmerged				= in_use_unmerged,
		   output_as_pdf 			= in_output_as_pdf,
		   role_sid 				= in_role_sid,
		   email_owner_on_complete 	= in_email_owner_on_complete,
		   doc_folder_sid 			= in_doc_folder,
		   overwrite_existing 		= in_overwrite_existing,
		   region_selection_tag_id  = in_region_selection_tag_id,
		   scenario_run_sid			= in_scenario_run_sid,
		   publish_to_prop_doc_lib	= in_publish_to_prop_doc_lib
	 WHERE schedule_sid = in_schedule_sid;
END;

PROCEDURE UpdateScheduleByName(
	in_existing_name			IN TPL_REPORT_SCHEDULE.NAME%TYPE,
	in_existing_tpl_report_sid  IN TPL_REPORT_SCHEDULE.TPL_REPORT_SID%TYPE,
	in_region_selection_type_id	IN TPL_REPORT_SCHEDULE.REGION_SELECTION_TYPE_ID%TYPE,
	in_region_selection_tag_id	IN TPL_REPORT_SCHEDULE.REGION_SELECTION_TAG_ID%TYPE,
	in_include_inactive_regions	IN TPL_REPORT_SCHEDULE.INCLUDE_INACTIVE_REGIONS%TYPE,
	in_one_report_per_region	IN TPL_REPORT_SCHEDULE.ONE_REPORT_PER_REGION%TYPE,
	in_schedule_xml				IN TPL_REPORT_SCHEDULE.SCHEDULE_XML%TYPE,
	in_offset					IN TPL_REPORT_SCHEDULE.OFFSET%TYPE,
	in_use_unmerged				IN TPL_REPORT_SCHEDULE.USE_UNMERGED%TYPE,
	in_output_as_pdf			IN TPL_REPORT_SCHEDULE.OUTPUT_AS_PDF%TYPE,
	in_role_sid					IN TPL_REPORT_SCHEDULE.ROLE_SID%TYPE,
	in_email_owner_on_complete	IN TPL_REPORT_SCHEDULE.EMAIL_OWNER_ON_COMPLETE%TYPE,
	in_doc_folder				IN TPL_REPORT_SCHEDULE.DOC_FOLDER_SID%TYPE,
	in_overwrite_existing		IN TPL_REPORT_SCHEDULE.OVERWRITE_EXISTING%TYPE,
	in_scenario_run_sid			IN TPL_REPORT_SCHEDULE.SCENARIO_RUN_SID%TYPE,
	in_publish_to_prop_doc_lib	IN	TPL_REPORT_SCHEDULE.PUBLISH_TO_PROP_DOC_LIB%TYPE,
	out_schedule_sid			OUT security_pkg.T_SID_ID
)
AS
	v_schedule_sid				TPL_REPORT_SCHEDULE.schedule_sid%TYPE;
	v_can_manage_all			NUMBER(1);
	v_current_owner				TPL_REPORT_SCHEDULE.owner_user_sid%TYPE;
BEGIN
	SELECT schedule_sid
	  INTO v_schedule_sid
	  FROM TPL_REPORT_SCHEDULE
	 WHERE name = in_existing_name
	   AND tpl_report_sid = in_existing_tpl_report_sid;

	IF csr_data_pkg.CheckCapability('Manage all templated report settings') OR csr_user_pkg.IsSuperAdmin = 1 THEN
		v_can_manage_all := 1;
	ELSE
		v_can_manage_all := 0;
	END IF;
	
	SELECT owner_user_sid
	  INTO v_current_owner
	  FROM tpl_report_schedule
	 WHERE schedule_sid = v_schedule_sid;
	
	IF (v_can_manage_all = 0 AND v_current_owner != SYS_CONTEXT('SECURITY', 'SID')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied overwriting schedule '||v_schedule_sid);
	END IF;

	--Update the schedule.
	UPDATE TPL_REPORT_SCHEDULE
	   SET region_selection_type_id = in_region_selection_type_id, 
	       include_inactive_regions = in_include_inactive_regions,
		   one_report_per_region 	= in_one_report_per_region,
		   schedule_xml 			= in_schedule_xml,
		   offset 					= in_offset,
		   use_unmerged				= in_use_unmerged,
		   output_as_pdf 			= in_output_as_pdf,
		   role_sid 				= in_role_sid,
		   email_owner_on_complete 	= in_email_owner_on_complete,
		   doc_folder_sid 			= in_doc_folder,
		   overwrite_existing 		= in_overwrite_existing,
		   region_selection_tag_id  = in_region_selection_tag_id,
		   scenario_run_sid 		= in_scenario_run_sid,
		   publish_to_prop_doc_lib	= in_publish_to_prop_doc_lib
	 WHERE name = in_existing_name
	   AND tpl_report_sid = in_existing_tpl_report_sid;
	
	out_schedule_sid := v_schedule_sid;
END;

PROCEDURE SetScheduleRegions(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_regions				IN	security_pkg.T_SID_IDS
)
AS
	v_regions				security.T_SID_TABLE;
	v_pos					NUMBER(10);
BEGIN
	v_pos := 0;
	
	--Delete existing regions
	DELETE FROM TPL_REPORT_SCHEDULE_REGION
	 WHERE in_schedule_sid = schedule_sid;
	
	v_regions := security_pkg.SidArrayToTable(in_regions);
	
	FOR r IN (
		SELECT column_value FROM TABLE(v_regions)
	)
	LOOP
		INSERT INTO TPL_REPORT_SCHEDULE_REGION (
			schedule_sid, region_sid, pos
		) VALUES (
			in_schedule_sid, r.column_value, v_pos
		);
		
		v_pos := v_pos + 1;
	END LOOP;
END;

PROCEDURE GetSchedule(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_doc_folder_sid		TPL_REPORT_SCHEDULE.doc_folder_sid%TYPE;
	v_doc_folder_name		SECURITY.SECURABLE_OBJECT.name%TYPE;
BEGIN
	--[[ PERM; Check read permission on the schedule sid ]]--
	
	BEGIN
		SELECT doc_folder_sid
		  INTO v_doc_folder_sid
		  FROM TPL_REPORT_SCHEDULE
		 WHERE schedule_sid = in_schedule_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Schedule not found with sid ' || in_schedule_sid);
	END;
	 
	IF v_doc_folder_sid IS NOT NULL THEN
		SELECT name
		  INTO v_doc_folder_name
		  FROM SECURITY.SECURABLE_OBJECT
		 WHERE sid_id = v_doc_folder_sid;
	ELSE
		v_doc_folder_name := '';
	END IF;

	OPEN out_cur FOR
		SELECT trs.tpl_report_sid, trs.owner_user_sid, cu.full_name owner_name, trs.name, trs.region_selection_type_id, trs.region_selection_tag_id, trs.include_inactive_regions, trs.one_report_per_region, 
			   trs.schedule_xml, trs.offset, trs.use_unmerged, trs.output_as_pdf, trs.role_sid, trs.email_owner_on_complete, trs.doc_folder_sid, trs.overwrite_existing, v_doc_folder_name doc_folder_name, 
			   trs.scenario_run_sid, run.description scenario_run_description, trs.publish_to_prop_doc_lib
		  FROM tpl_report_schedule trs
		  LEFT JOIN csr_user cu 		ON cu.csr_user_sid = trs.owner_user_sid
		  LEFT JOIN scenario_run run	ON run.scenario_run_sid = trs.scenario_run_sid 
		 WHERE schedule_sid = in_schedule_sid;
END;

PROCEDURE GetScheduleByName(
	in_schedule_name		IN	tpl_report_schedule.name%TYPE,
	in_tpl_report_sid		IN	tpl_report_schedule.tpl_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_schedule_sid		tpl_report_schedule.schedule_sid%TYPE;
BEGIN
	--Get the sid
	SELECT schedule_sid
	  INTO v_schedule_sid
	  FROM tpl_report_schedule
	 WHERE name = in_schedule_name
	   AND tpl_report_sid = in_tpl_report_sid;
	
	GetSchedule(v_schedule_sid, out_cur);
END;

PROCEDURE UpdateScheduleName(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_new_name				IN	TPL_REPORT_SCHEDULE.name%TYPE
)
AS
	v_tpl_report_sid		TPL_REPORT_SCHEDULE.tpl_report_sid%TYPE;
	v_name_exists			NUMBER(10);
BEGIN
	--[[ PERM; Check write permission on the schedule sid ]]--

	--Make sure name doesn't already exist
	SELECT tpl_report_sid
	  INTO v_tpl_report_sid
	  FROM TPL_REPORT_SCHEDULE
	 WHERE schedule_sid = in_schedule_sid;

	SELECT MAX(sid_id)
	  INTO v_name_exists
	  FROM SECURITY.SECURABLE_OBJECT
	 WHERE parent_sid_id = v_tpl_report_sid
	   AND name = in_new_name;

	IF v_name_exists IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Schedule already exists with name '||in_new_name);
	END IF;
	   
	securableobject_pkg.RenameSO(in_act_id, in_schedule_sid, REPLACE(in_new_name,'/','\')); --'

	--The renameSO will update the table entry for us
	/*UPDATE TPL_REPORT_SCHEDULE
	   SET name = in_new_name
	 WHERE schedule_sid = in_schedule_sid;*/
END;

PROCEDURE GetScheduleEntries(
	in_tpl_report_sid		IN	TPL_REPORT_SCHEDULE.tpl_report_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	--[[ PERM; Check read permission on the template ]]--

	OPEN out_cur FOR
		SELECT trs.schedule_sid, trs.name, (SELECT next_fire_time FROM TPL_REPORT_SCHED_BATCH_RUN WHERE schedule_sid = trs.schedule_sid) next_fire_time, cu.full_name owner_name,
		       CASE WHEN (owner_user_sid = SYS_CONTEXT('SECURITY', 'SID')) THEN 1 ELSE 0 END user_is_owner, trs.owner_user_sid
		  FROM TPL_REPORT_SCHEDULE trs
		  LEFT JOIN CSR_USER cu ON cu.csr_user_sid = trs.owner_user_sid
		 WHERE tpl_report_sid = in_tpl_report_sid
		 ORDER BY name ASC;
END;

PROCEDURE GetReportsToRun(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT trs.app_sid, trs.owner_user_sid, trsbr.schedule_sid, trs.tpl_report_sid,
			   trs.schedule_xml, trs.offset, trs.region_selection_type_id,
			   trs.region_selection_tag_id, trs.include_inactive_regions,
			   trs.one_report_per_region, trs.use_unmerged, trs.output_as_pdf, trs.role_sid, 
			   trs.doc_folder_sid, trs.overwrite_existing, tr.period_set_id, tr.period_interval_id,
			   trs.publish_to_prop_doc_lib
		  FROM tpl_report_sched_batch_run trsbr
		  JOIN tpl_report_schedule trs ON trs.schedule_sid = trsbr.schedule_sid
		  JOIN tpl_report tr ON tr.tpl_report_sid = trs.tpl_report_sid
		  JOIN v$csr_user cu ON trs.owner_user_sid = cu.csr_user_sid AND trs.app_sid = cu.app_sid
		  JOIN customer c ON c.app_sid = trsbr.app_sid
		 WHERE next_fire_time < SYSDATE
		   AND trs.owner_user_sid IS NOT NULL
		   AND cu.active = 1 -- Ignore schedules for deactivated users
		   AND c.scheduled_tasks_disabled = 0; -- Ignore schedules for deactivated sites
END;

PROCEDURE GetRegions(
	in_schedule_sid			IN	TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	CURSOR check_perm_cur IS
        SELECT region_sid
          FROM tpl_report_schedule_region
         WHERE schedule_sid = in_schedule_sid
           AND security_pkg.sql_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), region_sid, security_pkg.PERMISSION_READ)=0;
    check_perm number(10);
BEGIN
	-- Check the permissions on all the regions in this range. We want to throw an exception rather 
    -- than return missing regions which would only confuse the users. (Taken from Dataview_pkg.GetRegions)
    OPEN check_perm_cur;
    FETCH check_perm_cur INTO check_perm;
    IF check_perm_cur%FOUND THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the schedule with sid '||in_schedule_sid);
    END IF;

	OPEN out_cur FOR
		SELECT region_sid
		  FROM TPL_REPORT_SCHEDULE_REGION
		 WHERE schedule_sid = in_schedule_sid
	     ORDER BY pos ASC;
END;

PROCEDURE UpdateScheduleFireTime(
	in_schedule_sid			IN	TPL_REPORT_SCHED_BATCH_RUN.schedule_sid%TYPE,
	in_new_fire_date		IN	TPL_REPORT_SCHED_BATCH_RUN.next_fire_time%TYPE
)
AS
	v_owner_user	TPL_REPORT_SCHEDULE.owner_user_sid%TYPE;
	v_batch_offset	CUSTOMER.alert_batch_run_time%TYPE;
	v_new_run_date	TPL_REPORT_SCHED_BATCH_RUN.next_fire_time%TYPE;
BEGIN
	SELECT trs.owner_user_sid, cu.alert_batch_run_time
	  INTO v_owner_user, v_batch_offset
	  FROM TPL_REPORT_SCHEDULE trs
	  JOIN customer cu ON cu.app_sid = trs.APP_SID
	 WHERE schedule_sid = in_schedule_sid;

	BEGIN
		INSERT INTO TPL_REPORT_SCHED_BATCH_RUN
			(schedule_sid, next_fire_time)
		VALUES
			(in_schedule_sid, in_new_fire_date);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE TPL_REPORT_SCHED_BATCH_RUN
			   SET next_fire_time = in_new_fire_date
			 WHERE in_schedule_sid = schedule_sid;
	END;
END;

PROCEDURE ClearScheduleFireTime(
	in_schedule_sid			IN	TPL_REPORT_SCHED_BATCH_RUN.schedule_sid%TYPE
)
AS
BEGIN
	UPDATE TPL_REPORT_SCHED_BATCH_RUN
	   SET next_fire_time = null
	 WHERE in_schedule_sid = schedule_sid;
END;

PROCEDURE UpdateSavedDocId(
	in_schedule_sid			IN TPL_REPORT_SCHED_SAVED_DOC.schedule_sid%TYPE,
	in_doc_id				IN TPL_REPORT_SCHED_SAVED_DOC.doc_id%TYPE,
	in_region_sid			IN TPL_REPORT_SCHED_SAVED_DOC.region_sid%TYPE
)
AS
BEGIN
	IF in_region_sid IS NULL THEN
		DELETE FROM TPL_REPORT_SCHED_SAVED_DOC
		 WHERE schedule_sid = in_schedule_sid
		   AND region_sid IS NULL;
	ELSE
		DELETE FROM TPL_REPORT_SCHED_SAVED_DOC
		 WHERE schedule_sid = in_schedule_sid
		   AND region_sid = in_region_sid;
	END IF;
	
	INSERT INTO TPL_REPORT_SCHED_SAVED_DOC
		(schedule_sid, doc_id, region_sid)
	VALUES
		(in_schedule_sid, in_doc_id, in_region_sid);
END;

PROCEDURE GetSavedDocId(
	in_schedule_sid			IN TPL_REPORT_SCHED_SAVED_DOC.schedule_sid%TYPE,
	in_region_sid			IN TPL_REPORT_SCHED_SAVED_DOC.region_sid%TYPE,
	out_doc_id				OUT TPL_REPORT_SCHED_SAVED_DOC.doc_id%TYPE
)
AS
BEGIN
	BEGIN
		IF in_region_sid IS NULL THEN
			SELECT trssd.doc_id
			  INTO out_doc_id
			  FROM TPL_REPORT_SCHED_SAVED_DOC trssd
			  JOIN DOC_CURRENT dc 			ON trssd.doc_id = dc.doc_id
			  JOIN TPL_REPORT_SCHEDULE trs 	ON trssd.schedule_sid = trs.schedule_sid
			 WHERE trssd.schedule_sid = in_schedule_sid
			   AND region_sid IS NULL;
		ELSE
			SELECT trssd.doc_id
			  INTO out_doc_id
			  FROM TPL_REPORT_SCHED_SAVED_DOC trssd
			  JOIN DOC_CURRENT dc 			ON trssd.doc_id = dc.doc_id
			  JOIN TPL_REPORT_SCHEDULE trs 	ON trssd.schedule_sid = trs.schedule_sid
			 WHERE trssd.schedule_sid = in_schedule_sid
			   AND region_sid = in_region_sid;
		END IF;
		  
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- doesn't exist which is ok
			RETURN;
	END;
END;

PROCEDURE GetScheduleAndTemplateName(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT trs.schedule_sid, trs.name schedule_name, tr.name template_name
		  FROM tpl_report_schedule trs
		  JOIN TPL_REPORT tr ON trs.TPL_REPORT_SID = tr.TPL_REPORT_SID
		 WHERE trs.schedule_sid = in_schedule_sid;
END;

PROCEDURE GetSchedulesByRole(
	in_role_sid				IN TPL_REPORT_SCHEDULE.role_sid%TYPE,
	out_report_cur			OUT SYS_REFCURSOR,
	out_region_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_report_cur FOR
		SELECT trs.schedule_sid, trs.name schedule_name, trs.region_selection_type_id, trs.region_selection_tag_id, trs.include_inactive_regions, trs.one_report_per_region, rst.label selection_type_label, 
		t.tag selection_type_tag_name, tr.name template_name, trs.output_as_pdf, trs.tpl_report_sid, trs.use_unmerged, tr.period_set_id, tr.period_interval_id, trs.offset, trsbr.next_fire_time, trs.schedule_xml, 
		CASE WHEN (owner_user_sid = SYS_CONTEXT('SECURITY', 'SID')) THEN 1 ELSE 0 END user_is_owner, cu.full_name owner_name, cu.email owner_email, trs.role_sid, r.name role_name, 
			(SELECT MAX(completed_dtm)
               FROM batch_job_templated_report bjtr
               JOIN batch_job bj ON bjtr.batch_job_id = bj.batch_job_id
              WHERE schedule_sid = trs.schedule_sid
			) last_fire_time
		  FROM tpl_report_schedule trs
		  JOIN tpl_report tr 				    		ON trs.tpl_report_sid 			= tr.tpl_report_sid
		  LEFT JOIN tpl_report_sched_batch_run trsbr 	ON trs.schedule_sid   			= trsbr.schedule_sid
		  JOIN csr_user	cu								ON cu.csr_user_sid 	  			= trs.owner_user_sid
		  LEFT JOIN role r								ON trs.role_sid					= r.role_sid
		  LEFT JOIN v$tag t								ON t.tag_id						= trs.region_selection_tag_id
		  JOIN region_selection_type rst				ON trs.region_selection_type_id = rst.region_selection_type_id
		 WHERE trs.role_sid = in_role_sid
		   AND TO_CHAR(trs.schedule_xml) != 'never'
		   AND trs.app_sid = SYS_CONTEXT('SECURITY','APP');

	OPEN out_region_cur FOR
		SELECT trs.schedule_sid, trsr.REGION_SID, r.DESCRIPTION
		  FROM TPL_REPORT_SCHEDULE trs
		  JOIN TPL_REPORT_SCHEDULE_REGION trsr 	ON trsr.SCHEDULE_SID = trs.SCHEDULE_SID
		  JOIN v$REGION r 						ON trsr.REGION_SID = r.REGION_SID
		 WHERE trs.role_sid = in_role_sid
		   AND trs.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetSchedulesByOwner(
	in_owner_sid			IN TPL_REPORT_SCHEDULE.owner_user_sid%TYPE,
	out_report_cur			OUT SYS_REFCURSOR,
	out_region_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_report_cur FOR
		SELECT trs.schedule_sid, trs.name schedule_name, trs.region_selection_type_id, trs.region_selection_tag_id, trs.include_inactive_regions, trs.one_report_per_region, rst.label selection_type_label,
		t.tag selection_type_tag_name, tr.name template_name, trs.output_as_pdf, trs.tpl_report_sid, trs.use_unmerged, tr.period_set_id, tr.period_interval_id, trs.offset, trsbr.next_fire_time, trs.schedule_xml, 
		cu.full_name owner_name, cu.email owner_email, 1 user_is_owner, trs.role_sid, r.name role_name, 
			(SELECT MAX(completed_dtm)
               FROM batch_job_templated_report bjtr
               JOIN batch_job bj ON bjtr.batch_job_id = bj.batch_job_id
              WHERE schedule_sid = trs.schedule_sid
			) last_fire_time
		  FROM tpl_report_schedule trs
		  JOIN tpl_report tr 				    		ON trs.tpl_report_sid 			= tr.tpl_report_sid
		  LEFT JOIN tpl_report_sched_batch_run trsbr 	ON trs.schedule_sid   			= trsbr.schedule_sid
		  JOIN csr_user	cu								ON cu.csr_user_sid 	  			= trs.owner_user_sid
		  LEFT JOIN role r								ON trs.role_sid					= r.role_sid
		  LEFT JOIN v$tag t								ON t.tag_id						= trs.region_selection_tag_id
		  JOIN region_selection_type rst				ON trs.region_selection_type_id = rst.region_selection_type_id
		 WHERE trs.owner_user_sid = in_owner_sid
		   AND TO_CHAR(trs.schedule_xml) != 'never'
		   AND trs.app_sid = SYS_CONTEXT('SECURITY','APP');
	
	OPEN out_region_cur FOR
		SELECT trs.schedule_sid, trsr.REGION_SID, r.DESCRIPTION
		  FROM TPL_REPORT_SCHEDULE trs
		  JOIN TPL_REPORT_SCHEDULE_REGION trsr 	ON trsr.SCHEDULE_SID = trs.SCHEDULE_SID
		  JOIN v$REGION r 						ON trsr.REGION_SID = r.REGION_SID
		 WHERE trs.owner_user_sid = SYS_CONTEXT('SECURITY','SID')
		   AND trs.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetRegionNames(
	in_regions				IN	security_pkg.T_SID_IDS,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_regions				security.T_SID_TABLE;
	v_pos					NUMBER(10);
BEGIN
	v_regions := security_pkg.SidArrayToTable(in_regions);
	
	OPEN out_cur FOR
		SELECT r.region_sid, r.description, r.active
		  FROM v$region r
		 WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_regions))
		   AND r.region_sid NOT IN ( -- filter out deleted regions
                SELECT region_sid
                  FROM region
                  START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY','APP'))
                CONNECT BY PRIOR region_sid = parent_sid
               )
		   AND r.app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetUserScheduleHistory(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bj.batch_job_id, bj.completed_dtm run_time, bj.result, bj.result_url,
			   bjtr.templated_report_request_xml request_data, cu.full_name run_by,
			   tr.period_set_id, tr.period_interval_id
		  FROM batch_job bj
		  JOIN batch_job_templated_report bjtr  ON bj.batch_job_id = bjtr.batch_job_id
		  JOIN csr_user cu						ON cu.csr_user_sid = bj.requested_by_user_sid
		  JOIN tpl_report_schedule	trs			ON trs.schedule_sid = in_schedule_sid
		  JOIN tpl_report tr					ON tr.tpl_report_sid = trs.tpl_report_sid
		 WHERE bjtr.schedule_sid = in_schedule_sid
		   AND bj.requested_by_user_sid = SYS_CONTEXT('SECURITY','SID')
		   AND bj.completed_dtm IS NOT NULL;
END;

PROCEDURE GetOwnerScheduleHistory(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT bj.batch_job_id, bj.completed_dtm run_time, bj.result, bj.result_url,
			   bjtr.templated_report_request_xml request_data, cu.full_name run_by,
			   tr.period_set_id, tr.period_interval_id
		  FROM batch_job bj
		  JOIN batch_job_templated_report bjtr 	ON bj.batch_job_id = bjtr.batch_job_id
		  JOIN csr_user cu						ON cu.csr_user_sid = bj.requested_by_user_sid
		  JOIN tpl_report_schedule	trs			ON trs.schedule_sid = in_schedule_sid
		  JOIN tpl_report tr					ON tr.tpl_report_sid = trs.tpl_report_sid
		 WHERE bjtr.schedule_sid = in_schedule_sid
		   AND bj.completed_dtm IS NOT NULL;
END;

PROCEDURE ChangeScheduleOwner(
	in_schedule_sid			IN TPL_REPORT_SCHEDULE.schedule_sid%TYPE,
	in_new_owner_sid		IN TPL_REPORT_SCHEDULE.owner_user_sid%TYPE
)
AS
BEGIN
	IF csr_data_pkg.CheckCapability('Manage all templated report settings') OR csr_user_pkg.IsSuperAdmin = 1 THEN
		UPDATE tpl_report_schedule
		   SET owner_user_sid = in_new_owner_sid
		 WHERE schedule_sid = in_schedule_sid;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to change the owner on these settings.');
	END IF;
END;

PROCEDURE GetRoleMemberships(
	in_user_sid				IN	NUMBER,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||in_user_sid);
	END IF;
 
 	-- The region_role_member table should never contain references to regions  
 	-- that are links, they should have been resolved before going into the table.
 
 	OPEN out_cur FOR
		SELECT r.role_sid, r.name role_name, r.lookup_key, reg.region_sid, reg.description region_description
		  FROM role r, region_role_member rrm, v$region reg
		 WHERE r.role_sid = rrm.role_sid
		   --AND r.is_hidden = 0 --should this get the hidden roles too ? 
		   AND rrm.user_Sid = in_user_sid
		   AND rrm.region_sid = reg.region_sid
		   AND r.role_sid IN (
				SELECT role_sid 
				  FROM CSR.TPL_REPORT_SCHEDULE 
				 WHERE role_sid IS NOT NULL)
		 ORDER BY role_name,region_description;
END;

END;
/

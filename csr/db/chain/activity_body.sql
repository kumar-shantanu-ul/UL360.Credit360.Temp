CREATE OR REPLACE PACKAGE BODY chain.activity_pkg
IS

PROC_NOT_FOUND						EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name				IN	VARCHAR2,
	in_activity_id					IN	activity.activity_id%TYPE
)
AS
	v_helper_pkg					activity_type.helper_pkg%TYPE;
	v_activity_type_lookup			activity_type.lookup_key%TYPE;
BEGIN
	-- call helper proc if there is one, to setup custom forms
	BEGIN
		SELECT at.helper_pkg, at.lookup_key
		  INTO v_helper_pkg, v_activity_type_lookup
		  FROM activity_type at
		  JOIN activity a ON at.activity_type_id = a.activity_type_id
		 WHERE at.app_sid = security_pkg.GetApp
		   AND a.activity_id = in_activity_id;
	EXCEPTION
		WHEN no_data_found THEN
			null;
	END;
	
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.'||in_procedure_name||'(:1, :2);end;'
				USING in_activity_id, v_activity_type_lookup;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

FUNCTION SQL_CanManageActivities (
	in_target_company_sid			IN  activity.target_company_sid%TYPE
) RETURN NUMBER
AS
	v_company_sid					activity.target_company_sid%TYPE;
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN 1;
	END IF;
	
	-- This now gets used when activities are loaded into the calendar. Since the calendar
	-- has nothing explicitly to do with chain, it's possibly to reach this point without
	-- the session company having been set - in this case, try to set it to the user's default.
	BEGIN
		v_company_sid := company_pkg.GetCompany;
	EXCEPTION	
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_company_sid := company_pkg.TrySetCompany(v_company_sid);
	END;
	
	IF v_company_sid = in_target_company_sid OR in_target_company_sid IS NULL THEN
		RETURN 0;
	END IF;
	IF type_capability_pkg.CheckCapability(company_pkg.GetCompany, in_target_company_sid, chain_pkg.MANAGE_ACTIVITIES) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION INTERNAL_CanManageActivity(
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN BOOLEAN
AS
	v_company_sid					activity.target_company_sid%TYPE;
	v_target_company_sid			activity.target_company_sid%TYPE;
BEGIN
	-- Allow batch jobs access to all activities
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;
	
	v_company_sid := company_pkg.GetCompany;
	
	SELECT target_company_sid
	  INTO v_target_company_sid
	  FROM activity
	 WHERE activity_id = in_activity_id;

	IF v_company_sid = v_target_company_sid THEN
		RETURN FALSE;
	END IF;
	 
	RETURN type_capability_pkg.CheckCapability(v_company_sid, v_target_company_sid, chain_pkg.MANAGE_ACTIVITIES);
END;

FUNCTION INTERNAL_IsActivityUser(
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM activity_involvement
			 WHERE activity_id = in_activity_id
			   AND user_sid = security_pkg.GetSid
		)
	) LOOP
		RETURN TRUE;
	END LOOP;

	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM activity a
			  JOIN activity_involvement ai ON ai.activity_id = a.activity_id
			  JOIN csr.supplier s ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
			  JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
											 AND ai.role_sid = rrm.role_sid
			 WHERE a.activity_id = in_activity_id
			   AND rrm.user_sid = security_pkg.GetSid
		)
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	RETURN FALSE;
END;

FUNCTION INTERNAL_IsAssignedToUser(
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM activity
			 WHERE activity_id = in_activity_id
			   AND assigned_to_user_sid = security_pkg.GetSid
		)
	) LOOP
		RETURN TRUE;
	END LOOP;

	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM activity a
			  JOIN csr.supplier s ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
			  JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
											 AND a.assigned_to_role_sid = rrm.role_sid
			 WHERE a.activity_id = in_activity_id
			   AND rrm.user_sid = security_pkg.GetSid
		)
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	RETURN FALSE;
END;

FUNCTION SQL_IsAssignedToUser (
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN NUMBER
AS
BEGIN
	IF INTERNAL_IsAssignedToUser(in_activity_id) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION INTERNAL_IsTargetUser(
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM v$activity
			 WHERE activity_id = in_activity_id
			   AND target_user_sid = security_pkg.GetSid
			   AND share_with_target = 1
		)
	) LOOP
		RETURN TRUE;
	END LOOP;

	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT *
			  FROM v$activity a
			  JOIN csr.supplier s  ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
			  JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
											 AND a.target_role_sid = rrm.role_sid
			 WHERE a.activity_id = in_activity_id
			   AND rrm.user_sid = security_pkg.GetSid
			   AND share_with_target = 1
		)
	) LOOP
		RETURN TRUE;
	END LOOP;
	
	RETURN FALSE;
END;

FUNCTION SQL_IsTargetUser (
	in_activity_id					IN  activity.activity_id%TYPE
) RETURN NUMBER
AS
BEGIN
	IF INTERNAL_IsTargetUser(in_activity_id) THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;

/*********************************************************************************/
/**********************   ACTIVITY   *********************************************/
/*********************************************************************************/
PROCEDURE UNSEC_AddActivityUser(
	in_activity_id					IN  activity_involvement.activity_id%TYPE,
	in_user_sid						IN  activity_involvement.user_sid%TYPE
)
AS
BEGIN
	IF in_user_sid IS NOT NULL THEN
		BEGIN
			INSERT INTO activity_involvement (activity_id, user_sid, role_sid, added_by_sid)
				 VALUES (in_activity_id, in_user_sid, NULL, security_pkg.GetSid);  
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL; -- user already added
		END;
	END IF;
END;

PROCEDURE UNSEC_AddActivityRole(
	in_activity_id					IN  activity_involvement.activity_id%TYPE,
	in_role_sid						IN  activity_involvement.role_sid%TYPE
)
AS
BEGIN
	IF in_role_sid IS NOT NULL THEN
		BEGIN
			INSERT INTO activity_involvement (activity_id, user_sid, role_sid, added_by_sid)
				 VALUES (in_activity_id, NULL, in_role_sid, security_pkg.GetSid);  
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL; -- user already added
		END;
	END IF;
END;

PROCEDURE UNSEC_CreateActivity(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_activity_type_id				IN  activity.activity_type_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE DEFAULT NULL,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_created_by_activity_id		IN  activity.created_by_activity_id%TYPE DEFAULT NULL,
	in_defer_activity_created_call	IN  NUMBER DEFAULT 0,
	out_activity_id					OUT activity.activity_id%TYPE
)
AS
	v_activity_id					activity.activity_id%TYPE;
BEGIN
	INSERT INTO activity (activity_id, description, 
				target_company_sid, project_id, activity_type_id, 
				assigned_to_user_sid, assigned_to_role_sid, target_user_sid, target_role_sid,
	            activity_dtm, original_activity_dtm, location, location_type, share_with_target,
				created_by_activity_id)
		 VALUES (activity_id_seq.NEXTVAL, in_description,
				in_target_company_sid, in_project_id, in_activity_type_id, 
				in_assigned_to_user_sid, in_assigned_to_role_sid, in_target_user_sid, in_target_role_sid,
				in_activity_dtm, in_activity_dtm, in_location, in_location_type, in_share_with_target,
				in_created_by_activity_id)
	  RETURNING activity_id INTO out_activity_id;
	  
	UNSEC_AddActivityRole(out_activity_id, in_assigned_to_role_sid);
	UNSEC_AddActivityUser(out_activity_id, in_assigned_to_user_sid);		 
	UNSEC_AddActivityUser(out_activity_id, security_pkg.GetSid);
	
	IF in_defer_activity_created_call = 0 THEN
		INTERNAL_CallHelperPkg('ActivityCreated', out_activity_id);
	END IF;
	  
	-- create any automatic activities 
	FOR r IN (
			SELECT generate_activity_type_id,			
				   default_description, default_assigned_to_role_sid, 
				   default_target_role_sid,
				   CASE (default_act_date_relative_unit) 
					 WHEN 'd' THEN SYSDATE + default_act_date_relative
					 WHEN 'm' THEN ADD_MONTHS(SYSDATE, default_act_date_relative)
					 ELSE in_activity_dtm
				   END activity_dtm, default_share_with_target,
				   default_location, default_location_type,
				   NVL2(default_assigned_to_role_sid, NULL, in_assigned_to_user_sid) assigned_to_user_sid,
				   NVL2(default_target_role_sid, NULL, in_target_user_sid) target_user_sid
			  FROM (
				SELECT generate_activity_type_id, default_description, 
				       default_assigned_to_role_sid, default_target_role_sid,
				       default_act_date_relative_unit, default_act_date_relative, 
				       default_share_with_target, default_location, default_location_type,
					   ROW_NUMBER() OVER (
				           PARTITION BY generate_activity_type_id, 
						   default_assigned_to_role_sid, default_target_role_sid,
						   default_act_date_relative_unit, default_act_date_relative, 
						   default_share_with_target, default_location, default_location_type
						   ORDER BY generate_activity_type_id
					   ) rn						   
				  FROM activity_type_action
					START WITH activity_type_id = in_activity_type_id AND (in_created_by_activity_id IS NOT NULL OR allow_user_interaction = 0)
					CONNECT BY NOCYCLE PRIOR generate_activity_type_id = activity_type_id
			  )
			 WHERE rn = 1
	) LOOP
		BEGIN
			INSERT INTO activity (activity_id, description, target_company_sid, activity_type_id,
						assigned_to_user_sid, assigned_to_role_sid, target_user_sid, target_role_sid,
						activity_dtm, original_activity_dtm, created_by_activity_id, 
						location, location_type, share_with_target)
				 VALUES (activity_id_seq.NEXTVAL, NVL(r.default_description, in_description), 
				        in_target_company_sid, r.generate_activity_type_id, r.assigned_to_user_sid, 
						NVL(r.default_assigned_to_role_sid, in_assigned_to_role_sid), r.target_user_sid, 
						NVL(r.default_target_role_sid, in_target_role_sid), NVL(r.activity_dtm, in_activity_dtm), 
						NVL(r.activity_dtm, in_activity_dtm), NVL(in_created_by_activity_id, out_activity_id), 
						NVL(r.default_location, in_location), NVL(r.default_location_type, in_location_type), r.default_share_with_target)
			  RETURNING activity_id INTO v_activity_id;
			  
			UNSEC_AddActivityRole(v_activity_id, in_assigned_to_role_sid);
			UNSEC_AddActivityUser(v_activity_id, in_assigned_to_user_sid);  
			UNSEC_AddActivityUser(v_activity_id, security_pkg.GetSid);
			
			INTERNAL_CallHelperPkg('ActivityCreated', v_activity_id);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL; 
		END;
	END LOOP;
END;

PROCEDURE INTERNAL_LogUpdates(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0
)
AS
	v_log_id						activity_log.activity_log_id%TYPE;
	CURSOR c IS
		SELECT a.assigned_to_user_sid, a.assigned_to_role_sid, a.target_user_sid, 
		       a.target_role_sid, a.activity_dtm, a.location, a.location_type,
			   a.share_with_target, au.full_name assigned_to_user_name,
			   tu.full_name target_user_name, ar.name assigned_to_role_name,
			   tr.name target_role_name
		  FROM activity a
	 LEFT JOIN csr.csr_user au ON a.assigned_to_user_sid = au.csr_user_sid
	 LEFT JOIN csr.csr_user tu ON a.target_user_sid = tu.csr_user_sid
	 LEFT JOIN csr.role ar ON a.assigned_to_role_sid = ar.role_sid
	 LEFT JOIN csr.role tr ON a.target_role_sid = tr.role_sid
		 WHERE activity_id = in_activity_id;
    r								c%ROWTYPE;
	v_assigned_to_user_name			csr.csr_user.full_name%TYPE;
	v_assigned_to_role_name			csr.role.name%TYPE;
	v_target_user_name				csr.csr_user.full_name%TYPE;
	v_target_role_name				csr.role.name%TYPE;
BEGIN
	OPEN c;
    FETCH c INTO r;
	
	-- log any changes
	IF csr.null_pkg.ne(r.assigned_to_user_sid, in_assigned_to_user_sid) OR
	   csr.null_pkg.ne(r.assigned_to_role_sid, in_assigned_to_role_sid) THEN
	
		SELECT MIN(full_name)
		  INTO v_assigned_to_user_name
		  FROM csr.csr_user
		 WHERE csr_user_sid = in_assigned_to_user_sid;
		 
		SELECT MIN(name)
		  INTO v_assigned_to_role_name
		  FROM csr.role
		 WHERE role_sid = in_assigned_to_role_sid;
		
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Assignment changed from {0} to {1}',
			in_param_1					=> NVL(r.assigned_to_user_name, r.assigned_to_role_name),
			in_param_2					=> NVL(v_assigned_to_user_name, v_assigned_to_role_name),
			out_activity_log_id			=> v_log_id
		);
	END IF;

	IF csr.null_pkg.ne(r.target_user_sid, in_target_user_sid) OR
	   csr.null_pkg.ne(r.target_role_sid, in_target_role_sid) THEN
	
		SELECT MIN(full_name)
		  INTO v_target_user_name
		  FROM csr.csr_user
		 WHERE csr_user_sid = in_target_user_sid;
		 
		SELECT MIN(name)
		  INTO v_target_role_name
		  FROM csr.role
		 WHERE role_sid = in_target_role_sid;
		
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Contact changed from {0} to {1}',
			in_param_1					=> NVL(r.target_user_name, r.target_role_name),
			in_param_2					=> NVL(v_target_user_name, v_target_role_name),
			out_activity_log_id			=> v_log_id
		);
	END IF;
	
	IF r.activity_dtm != in_activity_dtm THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity rescheduled from {0} to {1}',
			in_param_1					=> TO_CHAR(r.activity_dtm, 'DD-MM-YYYY'), -- gets reformatted before displaying to user
			in_param_2					=> TO_CHAR(in_activity_dtm, 'DD-MM-YYYY'),
			out_activity_log_id			=> v_log_id
		);
	END IF;
	
	IF csr.null_pkg.ne(r.location, in_location) THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Location changed to "{0}"',
			in_param_1					=> in_location,
			out_activity_log_id			=> v_log_id
		);
	END IF;
	
	IF r.share_with_target = 1 AND in_share_with_target = 0 THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity share status changed to not shared',
			out_activity_log_id			=> v_log_id
		);
	ELSIF r.share_with_target = 0 AND in_share_with_target = 1 THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity share status changed to shared',
			out_activity_log_id			=> v_log_id
		);
	END IF;
END;

PROCEDURE UNSEC_UpdateActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_defer_activity_updated_call	IN  NUMBER DEFAULT 0,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_cur						security_pkg.T_OUTPUT_CUR;
BEGIN
	INTERNAL_LogUpdates(
		in_activity_id					=> in_activity_id,
		in_assigned_to_user_sid			=> in_assigned_to_user_sid,
		in_assigned_to_role_sid			=> in_assigned_to_role_sid,
		in_target_user_sid				=> in_target_user_sid,
		in_target_role_sid				=> in_target_role_sid,
		in_activity_dtm					=> in_activity_dtm,
		in_location						=> in_location,
		in_share_with_target			=> in_share_with_target
	);

	UPDATE chain.activity
	   SET description = in_description,
		   target_company_sid = in_target_company_sid,
		   assigned_to_user_sid = in_assigned_to_user_sid,
		   assigned_to_role_sid = in_assigned_to_role_sid,
		   target_user_sid = in_target_user_sid,
		   target_role_sid = in_target_role_sid,
		   activity_dtm = in_activity_dtm,
		   location = in_location,
		   location_type = in_location_type,
		   share_with_target = in_share_with_target
	 WHERE activity_id = in_activity_id;

	IF in_defer_activity_updated_call = 0 THEN
		INTERNAL_CallHelperPkg('ActivityUpdated', in_activity_id);
	END IF;

	GetActivity(in_activity_id, out_activity_cur, v_dummy_cur, v_dummy_cur, v_dummy_cur);
END;

PROCEDURE INTERNAL_GetMyActivities(
	in_project_id					IN	activity.project_id%TYPE  DEFAULT NULL,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_activity_type_id				IN  activity.activity_type_id%TYPE,
	in_status						IN  VARCHAR2,
	out_activity_ids				OUT	security.T_ORDERED_SID_TABLE
)
AS
	v_base_activity_ids				security.T_ORDERED_SID_TABLE;	
	v_comps_can_manage				security.T_SID_TABLE;
	idx								PLS_INTEGER := 1;
BEGIN
	SELECT security.T_ORDERED_SID_ROW(a.activity_id, NULL)
	  BULK COLLECT INTO v_base_activity_ids
	  FROM v$activity a
	 WHERE ((in_project_id IS NULL) OR (a.project_id = in_project_id))
	   AND a.target_company_sid = NVL(in_target_company_sid, a.target_company_sid)
	   AND a.activity_type_id = NVL(in_activity_type_id, a.activity_type_id)
	   AND LOWER(a.status) = NVL(in_status, LOWER(a.status));
	   
	BEGIN
		v_comps_can_manage := security.T_SID_TABLE();
		FOR activity_rec IN (
			SELECT DISTINCT a.target_company_sid
			  FROM v$activity a
			  JOIN TABLE(v_base_activity_ids) ba ON ba.sid_id = a.activity_id)
		LOOP
			-- Loop rather than query because of ORA-14551
			IF SQL_CanManageActivities(activity_rec.target_company_sid) = 1 THEN
				v_comps_can_manage.extend(1);
				v_comps_can_manage(idx) := activity_rec.target_company_sid;
				idx := idx + 1;
			END IF;
		END LOOP;
	END;
	  
	SELECT security.T_ORDERED_SID_ROW(a.activity_id, NULL)
	  BULK COLLECT INTO out_activity_ids
	  FROM v$activity a
	  JOIN TABLE(v_base_activity_ids) ba ON ba.sid_id = a.activity_id
	  LEFT JOIN TABLE(v_comps_can_manage) c ON c.column_value = a.target_company_sid
	 WHERE c.column_value IS NOT NULL
		OR a.activity_id IN (
			SELECT a.activity_id
			  FROM activity a
			  JOIN activity_involvement ai ON a.activity_id = ai.activity_id
		 LEFT JOIN csr.supplier s ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
		 LEFT JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
			   AND rrm.role_sid = ai.role_sid
			 WHERE ai.user_sid = security_pkg.GetSid
				OR rrm.user_sid = security_pkg.GetSid
		);	
END;

PROCEDURE GetMyActivitiesFromList(
	in_activity_id_list				IN	security.T_ORDERED_SID_TABLE,
	in_page							IN	NUMBER := NULL,
	in_page_size					IN	NUMBER := NULL,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id_list				security.T_ORDERED_SID_TABLE := in_activity_id_list;
BEGIN
	
	IF in_page IS NOT NULL AND in_page_size IS NOT NULL THEN
		SELECT security.T_ORDERED_SID_ROW(sid_id, pos)
		  BULK COLLECT INTO v_activity_id_list
		  FROM TABLE(in_activity_id_list)
		 WHERE pos BETWEEN ((in_page - 1) * in_page_size) + 1 AND  (in_page * in_page_size);
	END IF;
	
	OPEN out_activity_cur FOR
		SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
				a.activity_type_id, a.activity_type_label, a.status,
				a.assigned_to_user_sid, a.assigned_to_user_name, 
				a.assigned_to_role_sid, a.assigned_to_role_name, 
				a.target_user_sid, a.target_user_name,
				a.target_role_sid, a.target_role_name,
				a.assigned_to_name, a.target_name,
				a.activity_dtm, a.original_activity_dtm, 
				a.created_dtm, a.created_by_activity_id, a.created_by_sid, a.created_by_user_name,
				a.outcome_type_id, a.outcome_type_label, a.is_success, a.is_failure,
				a.outcome_reason, a.location, a.location_type, a.share_with_target,
				SQL_IsAssignedToUser(a.activity_id) is_assigned,
				SQL_IsTargetUser(a.activity_id) is_target,
				a.target_company_name
		  FROM v$activity a
		  JOIN TABLE(v_activity_id_list) fil_list ON fil_list.sid_id = a.activity_id
		 ORDER BY fil_list.pos;
		
	OPEN out_tag_cur FOR
		SELECT at.activity_id, at.tag_id, at.tag_group_id, t.tag, t.explanation, t.lookup_key
		  FROM activity a
		  JOIN activity_tag at ON a.activity_id = at.activity_id
		  JOIN csr.v$tag t ON at.tag_id = t.tag_id
		  JOIN TABLE(v_activity_id_list) fil_list ON fil_list.sid_id = a.activity_id
		 ORDER BY fil_list.pos;
END;

PROCEDURE GetMyOverdueActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_page_number					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_activity_types				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN 	security_pkg.T_SID_IDS,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id_list				security.T_ORDERED_SID_TABLE;
	v_activity_type_tab				security.T_SID_TABLE;
	v_region_sid_table				security.T_SID_TABLE;
	v_region_cnt					NUMBER;
	v_activity_type_cnt				NUMBER;
	pos								PLS_INTEGER := 1;
BEGIN
	v_activity_type_tab := security_pkg.SidArrayToTable(in_activity_types);
	v_region_sid_table := security_pkg.SidArrayToTable(in_region_sids);
	
	SELECT COUNT(*)
	  INTO v_activity_type_cnt
	  FROM TABLE(v_activity_type_tab);
	  
	SELECT COUNT(*)
	  INTO v_region_cnt
	  FROM TABLE(v_region_sid_table);
		
	v_activity_id_list := security.T_ORDERED_SID_TABLE();	
	
	FOR activity_rec IN (
		SELECT *
		  FROM v$activity a
		  JOIN csr.supplier sup ON sup.company_sid = a.target_company_sid
		  LEFT JOIN TABLE(v_region_sid_table) r ON r.column_value = sup.region_sid
		  LEFT JOIN TABLE(v_activity_type_tab) act ON act.column_value = a.activity_type_id
		 WHERE (in_project_id IS NULL OR a.project_id = in_project_id)
		   AND a.target_company_sid = NVL(in_target_company_sid, a.target_company_sid)
		   AND (a.assigned_to_user_sid = security_pkg.GetSid OR EXISTS (
				SELECT * FROM csr.supplier s
						 JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
						WHERE (s.company_sid = a.target_company_sid OR s.company_sid = a.created_by_company_sid)
						  AND rrm.role_sid = a.assigned_to_role_sid
						  AND rrm.user_sid = security_pkg.GetSid
		   ))
		   AND a.activity_dtm <= SYSDATE
		   AND (v_activity_type_cnt = 0 OR act.column_value IS NOT NULL)
		   AND (v_region_cnt = 0 OR r.column_value IS NOT NULL)
		   AND (a.outcome_type_id IS NULL OR a.is_deferred = 1)
		 ORDER BY a.activity_dtm, a.activity_id
	) LOOP
		v_activity_id_list.extend();
		v_activity_id_list(pos) := security.T_ORDERED_SID_ROW(activity_rec.activity_id, pos);
		pos := pos + 1;	
	END LOOP;
	
	GetMyActivitiesFromList(v_activity_id_list, in_page_number, in_page_size, out_activity_cur, out_tag_cur);
END;

PROCEDURE GetMyUpcomingActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_page_number					IN	NUMBER,
	in_page_size					IN	NUMBER,
	in_activity_types				IN	security_pkg.T_SID_IDS,
	in_region_sids					IN 	security_pkg.T_SID_IDS,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id_list				security.T_ORDERED_SID_TABLE;
	v_activity_type_tab				security.T_SID_TABLE;
	v_region_sid_table				security.T_SID_TABLE;
	v_region_cnt					NUMBER;
	v_activity_type_cnt				NUMBER;
	pos								PLS_INTEGER := 1;
BEGIN
	v_activity_type_tab := security_pkg.SidArrayToTable(in_activity_types);
	v_region_sid_table := security_pkg.SidArrayToTable(in_region_sids);
	
	SELECT COUNT(*)
	  INTO v_activity_type_cnt
	  FROM TABLE(v_activity_type_tab);
	  
	SELECT COUNT(*)
	  INTO v_region_cnt
	  FROM TABLE(v_region_sid_table);
		
	v_activity_id_list := security.T_ORDERED_SID_TABLE();	
	
	FOR activity_rec IN (
		SELECT *
		  FROM v$activity a
		  JOIN csr.supplier sup ON sup.company_sid = a.target_company_sid
		  LEFT JOIN TABLE(v_region_sid_table) r ON r.column_value = sup.region_sid
		  LEFT JOIN TABLE(v_activity_type_tab) act ON act.column_value = a.activity_type_id
		 WHERE (in_project_id IS NULL OR a.project_id = in_project_id)
		   AND a.target_company_sid = NVL(in_target_company_sid, a.target_company_sid)
		   AND (a.assigned_to_user_sid = security_pkg.GetSid OR EXISTS (
				SELECT * FROM csr.supplier s
						 JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
						WHERE (s.company_sid = a.target_company_sid OR s.company_sid = a.created_by_company_sid)
						  AND rrm.role_sid = a.assigned_to_role_sid
						  AND rrm.user_sid = security_pkg.GetSid
		   ))
		   AND a.activity_dtm > SYSDATE
		   AND (v_activity_type_cnt = 0 OR act.column_value IS NOT NULL)
		   AND (v_region_cnt = 0 OR r.column_value IS NOT NULL)
		   AND (a.outcome_type_id IS NULL OR a.is_deferred = 1)
		 ORDER BY a.activity_dtm, a.activity_id
	) LOOP
		v_activity_id_list.extend();
		v_activity_id_list(pos) := security.T_ORDERED_SID_ROW(activity_rec.activity_id, pos);
		pos := pos + 1;	
	END LOOP;

	GetMyActivitiesFromList(v_activity_id_list, in_page_number, in_page_size, out_activity_cur, out_tag_cur);
END;

PROCEDURE GetTargetActivities(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_activity_cur FOR
		SELECT a.activity_id, a.target_company_sid, a.created_by_company_sid, 
			   a.activity_type_id, a.activity_type_label,
			   a.assigned_to_user_sid, a.assigned_to_user_name, 
			   a.assigned_to_role_sid, a.assigned_to_role_name, 
			   a.target_user_sid, a.target_user_name,
			   a.target_role_sid, a.target_role_name,
			   a.assigned_to_name, a.target_name,
			   a.activity_dtm, a.original_activity_dtm, 
			   a.created_dtm, a.created_by_activity_id, a.created_by_sid, a.created_by_user_name,
			   a.location, a.location_type, a.share_with_target,
			   SQL_IsAssignedToUser(a.activity_id) is_assigned,
			   SQL_IsTargetUser(a.activity_id) is_target
		  FROM v$activity a
		 WHERE ((in_project_id IS NULL) OR (a.project_id = in_project_id))
		   AND (a.target_user_sid = security_pkg.GetSid OR EXISTS (
				SELECT * FROM csr.supplier s
						 JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
						WHERE (s.company_sid = a.target_company_sid OR s.company_sid = a.created_by_company_sid)
						  AND rrm.role_sid = a.target_role_sid
						  AND rrm.user_sid = security_pkg.GetSid
		   ))
		   AND a.share_with_target = 1
		   AND (a.outcome_type_id IS NULL OR a.is_deferred = 1)
		   AND a.target_company_sid = company_pkg.GetCompany
		 ORDER BY a.activity_dtm;
END;

PROCEDURE GetActivitiesByDueDate(
	in_start_dtm					IN	activity.activity_dtm%TYPE,
	in_end_dtm						IN	activity.activity_dtm%TYPE,
	in_activity_type_id				IN	activity.activity_type_id%TYPE DEFAULT NULL,
	in_my_activities				IN	NUMBER,
	in_company_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS	
	v_activity_id_list				security.T_ORDERED_SID_TABLE;
	v_my_activity_ids				security.T_ORDERED_SID_TABLE;
BEGIN
	INTERNAL_GetMyActivities(null, null, null, null, v_my_activity_ids);
	
	SELECT security.T_ORDERED_SID_ROW(activity_id, ROWNUM)
	  BULK COLLECT INTO v_activity_id_list
	  FROM (
		SELECT a.activity_id
		  FROM v$activity a
		  JOIN TABLE(v_my_activity_ids) ma ON ma.sid_id = a.activity_id
		 WHERE activity_dtm <= in_end_dtm
		   AND activity_dtm >= in_start_dtm
		   AND (in_activity_type_id IS NULL OR in_activity_type_id = a.activity_type_id)
		   AND (in_my_activities = 0 OR a.assigned_to_user_sid = security_pkg.GetSid) 
		   AND (in_company_sid IS NULL OR a.target_company_sid = in_company_sid)
		 ORDER BY a.activity_dtm
	);
	
	GetMyActivitiesFromList(
		in_activity_id_list => v_activity_id_list,
		out_activity_cur => out_activity_cur,
		out_tag_cur => out_tag_cur);
END;

PROCEDURE INTERNAL_PageActivityIds (
	in_activity_id_list			IN	security.T_ORDERED_SID_TABLE,
	in_start_row				IN	NUMBER,
	in_end_row					IN	NUMBER,
	in_order_by 				IN	VARCHAR2,
	in_order_dir				IN	VARCHAR2,
	out_activity_id_list		OUT	security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	SELECT security.T_ORDERED_SID_ROW(activity_id, rn)
	  BULK COLLECT INTO out_activity_id_list
		  FROM (
			SELECT x.activity_id, ROWNUM rn
			  FROM (
				SELECT a.activity_id
				  FROM v$activity a
				  JOIN (SELECT DISTINCT sid_id FROM TABLE(in_activity_id_list)) fil_list ON fil_list.sid_id = a.activity_id
				 ORDER BY
						-- To avoid dyanmic SQL, do many case statements
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN
							CASE (in_order_by)
								WHEN 'activityId' THEN TO_CHAR(activity_id, '0000000000')
								WHEN 'activityDtm' THEN TO_CHAR(activity_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'activityTypeLabel' THEN activity_type_label
								WHEN 'assignedToName' THEN assigned_to_name
								WHEN 'targetName' THEN target_name
								WHEN 'location' THEN location
								WHEN 'createdDtmFormatted' THEN TO_CHAR(created_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'createdByUserName' THEN created_by_user_name
								WHEN 'status' THEN status
							END
						END ASC,
						CASE WHEN in_order_dir='DESC' THEN
							CASE (in_order_by)
								WHEN 'activityId' THEN TO_CHAR(activity_id, '0000000000')
								WHEN 'activityDtm' THEN TO_CHAR(activity_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'activityTypeLabel' THEN activity_type_label
								WHEN 'assignedToName' THEN assigned_to_name
								WHEN 'targetName' THEN target_name
								WHEN 'location' THEN location
								WHEN 'createdDtmFormatted' THEN TO_CHAR(created_dtm, 'YYYY-MM-DD HH24:MI:SS')
								WHEN 'createdByUserName' THEN created_by_user_name
								WHEN 'status' THEN status
							END
						END DESC,
						CASE WHEN in_order_dir='ASC' OR in_order_dir IS NULL THEN a.activity_id END DESC,
						CASE WHEN in_order_dir='DESC' THEN a.activity_id END ASC
				) x
			)
		  WHERE rn > in_start_row
		   AND rn <= in_end_row;
END;

PROCEDURE GetActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF INTERNAL_IsActivityUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id) THEN
		OPEN out_activity_cur FOR
			SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
				   a.activity_type_id, a.activity_type_label, a.status,
				   a.assigned_to_user_sid, a.assigned_to_user_name, 
				   a.assigned_to_role_sid, a.assigned_to_role_name, 
				   a.target_user_sid, a.target_user_name,
				   a.target_role_sid, a.target_role_name,
				   a.assigned_to_name, a.target_name,
				   a.activity_dtm, a.original_activity_dtm, 
				   a.created_dtm, a.created_by_activity_id, a.created_by_sid, a.created_by_user_name,
				   a.outcome_type_id, a.outcome_type_label, a.is_success, a.is_failure,
				   a.outcome_reason, a.location, a.location_type, a.share_with_target,
				   SQL_IsAssignedToUser(a.activity_id) is_assigned,
				   SQL_IsTargetUser(a.activity_id) is_target,
				   a.target_company_name
			  FROM v$activity a
			 WHERE a.activity_id = in_activity_id
			 ORDER BY a.activity_dtm;

		OPEN out_tag_cur FOR
			SELECT at.activity_id, at.tag_id, at.tag_group_id, t.tag, t.explanation, t.lookup_key
			  FROM activity a
			  JOIN activity_tag at ON a.activity_id = at.activity_id
			  JOIN csr.v$tag t ON at.tag_id = t.tag_id
			 WHERE a.activity_id = in_activity_id;
	ELSIF INTERNAL_IsTargetUser(in_activity_id) THEN
		OPEN out_activity_cur FOR
				SELECT a.activity_id, a.target_company_sid, a.created_by_company_sid, 
					   a.activity_type_id, a.activity_type_label, a.status,
					   a.assigned_to_user_sid, a.assigned_to_user_name, 
					   a.assigned_to_role_sid, a.assigned_to_role_name, 
					   a.target_user_sid, a.target_user_name,
					   a.target_role_sid, a.target_role_name,
					   a.assigned_to_name, a.target_name,
					   a.activity_dtm, a.original_activity_dtm, 
					   a.created_dtm, a.created_by_activity_id, a.created_by_sid, a.created_by_user_name,
					   a.location, a.location_type, a.share_with_target,
					   SQL_IsAssignedToUser(a.activity_id) is_assigned,
					   SQL_IsTargetUser(a.activity_id) is_target,
					   a.target_company_name
				  FROM v$activity a
				 WHERE a.activity_id = in_activity_id
				 ORDER BY a.activity_dtm;

			OPEN out_tag_cur FOR
				SELECT NULL activity_id, NULL tag_id, NULL tag_group_id, NULL tag, NULL explanation, NULL lookup_key
				  FROM dual
				 WHERE 1 = 2;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read activity ' || in_activity_id);
	END	IF;
		
	GetActivityLogEntries(in_activity_id, out_log_cur, out_log_file_cur);
END;

PROCEDURE GetInvolvedUsers (
	in_activity_id					IN  activity.activity_id%TYPE,
	out_inv_user_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF INTERNAL_IsActivityUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id) THEN
		OPEN out_inv_user_cur FOR
			SELECT user_sid
			  FROM activity_involvement
			 WHERE activity_id = in_activity_id
			   AND user_sid IS NOT NULL
			 UNION
			SELECT rrm.user_sid
			  FROM activity a
			  JOIN activity_involvement ai ON ai.activity_id = a.activity_id
			  JOIN csr.supplier s  ON (a.target_company_sid = s.company_sid OR a.created_by_company_sid = s.company_sid)
			  JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
											 AND ai.role_sid = rrm.role_sid
			 WHERE a.activity_id = in_activity_id;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read activity ' || in_activity_id);
	END IF;
END;

PROCEDURE CreateActivity(
	in_project_id					IN	activity.project_id%TYPE DEFAULT NULL,
	in_activity_type_id				IN  activity.activity_type_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_created_by_activity_id		IN  activity.created_by_activity_id%TYPE DEFAULT NULL,
	in_defer_activity_created_call	IN  NUMBER DEFAULT 0,
	out_activity_id					OUT activity.activity_id%TYPE
)
AS
	v_active						company.active%TYPE;
BEGIN
	IF NOT type_capability_pkg.CheckCapability(company_pkg.GetCompany, in_target_company_sid, chain_pkg.MANAGE_ACTIVITIES) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only users with the manage activity capability can create activities.');
	END IF;

	SELECT active
	  INTO v_active
	  FROM v$company
	 WHERE company_sid = in_target_company_sid;

	IF v_active != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot create activity with inactive target company ' || in_target_company_sid);
	END IF;
	
	UNSEC_CreateActivity(
		in_project_id					=> in_project_id,
		in_activity_type_id				=> in_activity_type_id,
		in_description					=> in_description,
		in_target_company_sid			=> in_target_company_sid,
		in_assigned_to_user_sid			=> in_assigned_to_user_sid,
		in_assigned_to_role_sid			=> in_assigned_to_role_sid,
		in_target_user_sid				=> in_target_user_sid,
		in_target_role_sid				=> in_target_role_sid,
		in_activity_dtm					=> in_activity_dtm,
		in_location						=> in_location,
		in_location_type				=> in_location_type,
		in_share_with_target			=> in_share_with_target,
		in_created_by_activity_id		=> in_created_by_activity_id,
		in_defer_activity_created_call	=> in_defer_activity_created_call,
		out_activity_id					=> out_activity_id
	);
END;

-- Fires the activity created helper call. This is to let C# defer the call
-- until after it has finished adding tags.
PROCEDURE ActivityCreated(
	in_activity_id					IN  activity_tag.activity_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_CanManageActivity(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only users with the manage activity capability can create activities.');
	END IF;

	INTERNAL_CallHelperPkg('ActivityCreated', in_activity_id);
END;

PROCEDURE UpdateActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_description					IN  activity.description%TYPE,
	in_target_company_sid			IN  activity.target_company_sid%TYPE,
	in_assigned_to_user_sid			IN  activity.assigned_to_user_sid%TYPE DEFAULT NULL,
	in_assigned_to_role_sid			IN  activity.assigned_to_role_sid%TYPE DEFAULT NULL,
	in_target_user_sid				IN  activity.target_user_sid%TYPE DEFAULT NULL,
	in_target_role_sid				IN  activity.target_role_sid%TYPE DEFAULT NULL,
	in_activity_dtm					IN  activity.activity_dtm%TYPE,
	in_location						IN  activity.location%TYPE DEFAULT NULL,
	in_location_type				IN  activity.location_type%TYPE DEFAULT NULL,
	in_share_with_target			IN	activity.share_with_target%TYPE DEFAULT 0,
	in_defer_activity_updated_call	IN  NUMBER DEFAULT 0,
	out_activity_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_roles_cnt							NUMBER;
BEGIN
	-- need manage permissions on current and new versions of the values that provide the permission
	SELECT count(*) INTO v_roles_cnt
					FROM csr.supplier s
					JOIN csr.region_role_member rrm ON s.region_sid = rrm.region_sid
				   WHERE s.company_sid = in_target_company_sid
					 AND rrm.role_sid = in_assigned_to_role_sid
					 AND rrm.user_sid = security_pkg.GetSid;

	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) AND ((in_assigned_to_user_sid = security_pkg.GetSid) OR (v_roles_cnt > 0))) AND
	   NOT (INTERNAL_CanManageActivity(in_activity_id) AND type_capability_pkg.CheckCapability(company_pkg.GetCompany, in_target_company_sid, chain_pkg.MANAGE_ACTIVITIES)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assignee and users with the manage activity capability can update activities.');
	END IF;
	
	UNSEC_UpdateActivity(
		in_activity_id					=> in_activity_id,
		in_description					=> in_description,
		in_target_company_sid			=> in_target_company_sid,
		in_assigned_to_user_sid			=> in_assigned_to_user_sid,
		in_assigned_to_role_sid			=> in_assigned_to_role_sid,
		in_target_user_sid				=> in_target_user_sid,
		in_target_role_sid				=> in_target_role_sid,
		in_activity_dtm					=> in_activity_dtm,
		in_location						=> in_location,
		in_location_type				=> in_location_type,
		in_share_with_target			=> in_share_with_target,
		in_defer_activity_updated_call	=> in_defer_activity_updated_call,
		out_activity_cur				=> out_activity_cur
	);
END;

-- Fires the activity updated helper call. This is to let C# defer the call
-- until after it has finished amending tags.
PROCEDURE ActivityUpdated(
	in_activity_id					IN  activity_tag.activity_id%TYPE
)
AS
BEGIN
	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assignee and users with the manage activity capability can update activities.');
	END IF;

	INTERNAL_CallHelperPkg('ActivityUpdated', in_activity_id);
END;

PROCEDURE SetActivityOutcome(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_outcome_type_id				IN  activity.outcome_type_id%TYPE,
	in_outcome_reason				IN  activity.outcome_reason%TYPE DEFAULT NULL,
	in_deferred_date				IN  activity.activity_dtm%TYPE DEFAULT NULL
)
AS
	CURSOR c IS
		SELECT description, project_id, activity_type_id, target_company_sid, 
			   assigned_to_user_sid, assigned_to_role_sid, target_user_sid, target_role_sid,
			   activity_dtm, location, location_type, share_with_target, outcome_type_id
		  FROM activity
		 WHERE activity_id = in_activity_id;
    r								c%ROWTYPE;
	v_activity_id					activity.activity_id%TYPE;
	v_require_reason				outcome_type.require_reason%TYPE;
	v_is_deferred					outcome_type.is_deferred%TYPE;
	v_outcome_label					outcome_type.label%TYPE;
	v_log_id						activity_log.activity_log_id%TYPE;
BEGIN
	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assinged to user or users with the manage activity capability can set an activity outcome.');
	END IF;
	
	SELECT require_reason, is_deferred, label
	  INTO v_require_reason, v_is_deferred, v_outcome_label
	  FROM outcome_type
	 WHERE outcome_type_id = in_outcome_type_id;
	 
	IF v_require_reason = 1 AND in_outcome_reason IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set the outcome type to '||in_outcome_type_id||' without a reason as reason is mandatory');
	END IF;
	
	IF v_is_deferred = 1 AND in_deferred_date IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot set the outcome type to '||in_outcome_type_id||' without a deferred date');
	END IF;
	
	OPEN c;
    FETCH c INTO r;
	
	UPDATE activity
	   SET outcome_type_id = in_outcome_type_id,
	       outcome_reason = in_outcome_reason,
		   activity_dtm = NVL(in_deferred_date, activity_dtm)
	 WHERE activity_id = in_activity_id;
	
	IF v_is_deferred = 1 THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity deferred until {0}',
			in_param_1					=> TO_CHAR(in_deferred_date, 'DD-MM-YYYY'),
			out_activity_log_id			=> v_log_id
		);
	END IF;
	 
	IF in_outcome_reason IS NULL THEN
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity outcome set to "{0}"',
			in_param_1					=> v_outcome_label,
			out_activity_log_id			=> v_log_id
		);
	ELSE
		AddSystemLogEntry(
			in_activity_id				=> in_activity_id,
			in_message					=> 'Activity outcome set to "{0}" with the reason "{1}"',
			in_param_1					=> v_outcome_label,
			in_param_2					=> in_outcome_reason,
			out_activity_log_id			=> v_log_id
		);
	END IF;
	 
	INTERNAL_CallHelperPkg('ActivityOutcomeSet', in_activity_id);	 
	
	IF r.outcome_type_id IS NULL OR r.outcome_type_id != in_outcome_type_id THEN
		-- create any automatic activities 
		FOR t IN (
			SELECT aota.generate_activity_type_id,
				   CASE (aota.default_act_date_relative_unit) 
					 WHEN 'd' THEN SYSDATE + aota.default_act_date_relative
					 WHEN 'm' THEN ADD_MONTHS(SYSDATE, aota.default_act_date_relative)
					 ELSE SYSDATE
				   END activity_dtm, aota.default_share_with_target,
				   aota.default_description,
				   aota.default_assigned_to_role_sid, aota.default_target_role_sid,
				   aota.default_location, aota.default_location_type,
				   NVL2(aota.default_assigned_to_role_sid, NULL, r.assigned_to_user_sid) assigned_to_user_sid,
				   NVL2(aota.default_target_role_sid, NULL, r.target_user_sid) target_user_sid
			  FROM activity_type at
			  JOIN activity_outcome_type_action aota ON at.activity_type_id = aota.activity_type_id
			 WHERE at.activity_type_id = r.activity_type_id
			   AND aota.outcome_type_id = in_outcome_type_id
			   AND aota.allow_user_interaction = 0
		) LOOP
			BEGIN
				UNSEC_CreateActivity(
					in_project_id					=> r.project_id,
					in_activity_type_id				=> t.generate_activity_type_id,
					in_description					=> NVL(t.default_description, r.description),
					in_target_company_sid			=> r.target_company_sid,
					in_assigned_to_user_sid			=> t.assigned_to_user_sid,
					in_assigned_to_role_sid			=> NVL(t.default_assigned_to_role_sid, r.assigned_to_role_sid),
					in_target_user_sid				=> t.target_user_sid,
					in_target_role_sid				=> NVL(t.default_target_role_sid, r.target_role_sid),
					in_activity_dtm					=> NVL(t.activity_dtm, SYSDATE),
					in_location						=> NVL(t.default_location, r.location),
					in_location_type				=> NVL(t.default_location_type, r.location_type),
					in_share_with_target			=> t.default_share_with_target,
					in_created_by_activity_id		=> in_activity_id,
					out_activity_id					=> v_activity_id
				);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL; 
			END;
		END LOOP;
	END IF;
END;

PROCEDURE RescheduleActivity(
	in_activity_id					IN  activity.activity_id%TYPE,
	in_new_activity_dtm				IN  activity.activity_dtm%TYPE
)
AS
	v_log_id						activity_log.activity_log_id%TYPE;
	v_old_activity_dtm				activity.activity_dtm%TYPE;
BEGIN
	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assinged to user or users with the manage activity capability can reschedule activities.');
	END IF;
	
	SELECT activity_dtm
	  INTO v_old_activity_dtm
	  FROM activity
	 WHERE activity_id = in_activity_id;
	
	UPDATE activity
	   SET activity_dtm = in_new_activity_dtm
	 WHERE activity_id = in_activity_id;
	 
	AddSystemLogEntry(
		in_activity_id				=> in_activity_id,
		in_message					=> 'Activity rescheduled from {0} to {1}',
		in_param_1					=> TO_CHAR(v_old_activity_dtm, 'DD-MM-YYYY'), -- gets reformatted before displaying to user
		in_param_2					=> TO_CHAR(in_new_activity_dtm, 'DD-MM-YYYY'),
		out_activity_log_id			=> v_log_id
	);
	 
	INTERNAL_CallHelperPkg('ActivityRescheduled', in_activity_id);
END;

PROCEDURE DeleteActivity(
	in_activity_id					IN  activity.activity_id%TYPE
)
AS
BEGIN
	IF NOT INTERNAL_CanManageActivity(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only users with the manage activity capability can delete activities.');
	END IF;
	
	FOR r IN (
		SELECT activity_log_id
		  FROM activity_log
		 WHERE activity_id = in_activity_id
	) LOOP
		DeleteLogEntry(r.activity_log_id);
	END LOOP;
	
	DELETE FROM activity_involvement
	      WHERE activity_id = in_activity_id;
		  
	DELETE FROM activity_tag
	      WHERE activity_id = in_activity_id;
		  
	UPDATE activity
	   SET created_by_activity_id = NULL
	 WHERE created_by_activity_id = in_activity_id;
	
	DELETE FROM activity
	      WHERE activity_id = in_activity_id;
		  
	INTERNAL_CallHelperPkg('ActivityDeleted', in_activity_id);
END;

/*********************************************************************************/
/**********************   ACTIVITY LOGS ******************************************/
/*********************************************************************************/
PROCEDURE GetActivityLogEntries(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT (INTERNAL_IsActivityUser(in_activity_id) OR INTERNAL_IsTargetUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read log entries for activity ' || in_activity_id);
	END IF;
	
	OPEN out_log_cur FOR
		SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
		       al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
			   al.logged_by_full_name, al.logged_by_email, al.reply_to_activity_log_id, al.is_from_email
		  FROM v$activity_log al
		 WHERE al.activity_id = in_activity_id
		 ORDER BY al.logged_dtm DESC;
		  
	OPEN out_log_file_cur FOR
		SELECT alf.activity_log_file_id, alf.activity_log_id, alf.filename, alf.mime_type,
		       alf.sha1, alf.uploaded_dtm
		  FROM activity_log_file alf
		  JOIN v$activity_log al ON al.activity_log_id = alf.activity_log_id
		 WHERE al.activity_id = in_activity_id
		 ORDER BY alf.activity_log_file_id;
END;

PROCEDURE GetActivityLogEntry(
	in_activity_log_id				IN activity_log.activity_log_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id					activity_log.activity_id%TYPE;
BEGIN
	SELECT activity_id INTO v_activity_id
	  FROM  v$activity_log al
	 WHERE al.activity_log_id = in_activity_log_id;

	IF INTERNAL_IsActivityUser(v_activity_id) OR INTERNAL_CanManageActivity(v_activity_id) THEN
		OPEN out_log_cur FOR
			SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
				   al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
				   al.logged_by_full_name, al.logged_by_email, al.reply_to_activity_log_id, al.is_from_email
			  FROM v$activity_log al
			 WHERE al.activity_id = v_activity_id
			   AND al.activity_log_id = in_activity_log_id;
	ELSIF INTERNAL_IsTargetUser(v_activity_id) THEN
		OPEN out_log_cur FOR
			SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
				   al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
				   al.logged_by_full_name, al.logged_by_email, al.reply_to_activity_log_id, al.is_from_email
			  FROM v$activity_log al
			 WHERE al.activity_id = v_activity_id
			   AND al.activity_log_id = in_activity_log_id
			   AND al.is_visible_to_supplier = 1;
	ELSE
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read the log entry with id ' || in_activity_log_id);
	END IF;
	
	OPEN out_log_file_cur FOR
		SELECT alf.activity_log_file_id, alf.activity_log_id, alf.filename, alf.mime_type,
				alf.sha1, alf.uploaded_dtm
			FROM activity_log_file alf
			JOIN v$activity_log al ON al.activity_log_id = alf.activity_log_id
			WHERE al.activity_id = v_activity_id
			AND al.activity_log_id = in_activity_log_id;
END;

PROCEDURE GetActivityLogReplies(
	in_activity_log_id				IN  activity_log.activity_log_id%TYPE,
	out_log_cur						OUT security_pkg.T_OUTPUT_CUR,
	out_log_file_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id					activity_log.activity_id%TYPE;
BEGIN
	SELECT activity_id
	  INTO v_activity_id
	  FROM activity_log
	 WHERE activity_log_id = in_activity_log_id;

	IF NOT (INTERNAL_IsActivityUser(v_activity_id) OR INTERNAL_CanManageActivity(v_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read log entry replies to ' || in_activity_log_id);
	END IF;
	
	OPEN out_log_cur FOR
		SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
		       al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
			   al.logged_by_full_name, al.logged_by_email, al.reply_to_activity_log_id
		  FROM v$activity_log al
		 WHERE al.reply_to_activity_log_id = in_activity_log_id;
		  
	OPEN out_log_file_cur FOR
		SELECT alf.activity_log_file_id, alf.activity_log_id, alf.filename, alf.mime_type,
		       alf.sha1, alf.uploaded_dtm
		  FROM activity_log_file alf
		  JOIN v$activity_log al ON al.activity_log_id = alf.activity_log_id
		 WHERE al.reply_to_activity_log_id = in_activity_log_id;
END;

PROCEDURE AddUserLogEntry(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_message						IN  activity_log.message%TYPE,
	in_reply_to_activity_log_id		IN  activity_log.reply_to_activity_log_id%TYPE DEFAULT NULL,
	in_is_visible_to_supplier		IN  activity_log.is_visible_to_supplier%TYPE DEFAULT 0,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE DEFAULT NULL,
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
)
AS
BEGIN
	IF NOT (INTERNAL_IsActivityUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id) OR INTERNAL_IsTargetUser(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to add a log entry to activity '||in_activity_id);
	END IF;
	
	INSERT INTO activity_log (activity_log_id, activity_id, message, reply_to_activity_log_id, 
	                          is_system_generated, logged_by_user_sid, is_visible_to_supplier)
	     VALUES (activity_log_id_seq.NEXTVAL, in_activity_id, in_message, in_reply_to_activity_log_id, 
		         0, security_pkg.GetSid, in_is_visible_to_supplier)
	  RETURNING activity_log_id INTO out_activity_log_id;
	  
	IF in_cache_key IS NOT NULL THEN
		INSERT INTO activity_log_file (activity_log_file_id, activity_log_id, filename, mime_type, data, sha1) 
			SELECT activity_log_file_id_seq.NEXTVAL, out_activity_log_id, filename, mime_type, object, 
				   CAST(dbms_crypto.hash(object, dbms_crypto.hash_sh1) AS VARCHAR2(40))
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
		END IF; 
	END IF;
	
	INTERNAL_CallHelperPkg('ActivityLogEntryAdded', in_activity_id);
END;

PROCEDURE GetActivityLogFile(
	in_activity_log_file_id			IN  activity_log_file.activity_log_file_id%TYPE,
	in_sha1							IN  VARCHAR2,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_activity_id					activity_log.activity_id%TYPE;
	v_share_with_target				activity.share_with_target%TYPE;
	v_is_visible_to_supplier		activity_log.is_visible_to_supplier%TYPE;
BEGIN
	SELECT al.activity_id, a.share_with_target, al.is_visible_to_supplier
	  INTO v_activity_id, v_share_with_target, v_is_visible_to_supplier
	  FROM activity_log_file alf
	  JOIN activity_log al ON alf.activity_log_id = al.activity_log_id
	  JOIN activity a ON al.activity_id = a.activity_id
	 WHERE alf.activity_log_file_id = in_activity_log_file_id;

	IF NOT (INTERNAL_IsActivityUser(v_activity_id) OR INTERNAL_CanManageActivity(v_activity_id))
	   AND NOT (INTERNAL_IsTargetUser(v_activity_id) AND v_share_with_target=1 AND v_is_visible_to_supplier=1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to read this file.');
	END IF;
	
	OPEN out_cur FOR
		SELECT filename, mime_type, data, sha1, uploaded_dtm
		  FROM activity_log_file
		 WHERE activity_log_file_id = in_activity_log_file_id
		   AND sha1 = in_sha1;
END;

PROCEDURE AddSystemLogEntry(
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_message						IN  activity_log.message%TYPE,
	in_param_1						IN  activity_log.param_1%TYPE DEFAULT NULL,
	in_param_2						IN  activity_log.param_2%TYPE DEFAULT NULL,
	in_param_3						IN  activity_log.param_3%TYPE DEFAULT NULL,
	in_is_visible_to_supplier		IN  activity_log.is_visible_to_supplier%TYPE DEFAULT 0,	
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
)
AS
BEGIN
	IF NOT (INTERNAL_IsActivityUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permission to add a log entry to activity '||in_activity_id);
	END IF;
	
	INSERT INTO activity_log (activity_log_id, activity_id, message, is_system_generated, param_1, 
	                          param_2, param_3, logged_by_user_sid, is_visible_to_supplier)
	     VALUES (activity_log_id_seq.NEXTVAL, in_activity_id, in_message, 1, in_param_1, in_param_2, 
	             in_param_3, security_pkg.GetSid, in_is_visible_to_supplier)
	  RETURNING activity_log_id INTO out_activity_log_id;
	  
	INTERNAL_CallHelperPkg('ActivityLogEntryAdded', in_activity_id);
END;

PROCEDURE DeleteLogEntry(
	in_activity_log_id				IN  activity_log.activity_log_id%TYPE
)
AS
	v_activity_id					activity_log.activity_id%TYPE;
BEGIN
	SELECT activity_id
	  INTO v_activity_id
	  FROM activity_log
	 WHERE activity_log_id = in_activity_log_id;
	 
	IF NOT INTERNAL_CanManageActivity(v_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only users with the manage activity capability can delete log entries.');
	END IF;
	
	FOR r IN (
		SELECT activity_log_id
		  FROM activity_log
		 WHERE reply_to_activity_log_id = in_activity_log_id
	) LOOP
		DeleteLogEntry(r.activity_log_id);
	END LOOP;
		
	DELETE FROM activity_log_file
	      WHERE activity_log_id = in_activity_log_id;
	
	DELETE FROM activity_log
	      WHERE activity_log_id = in_activity_log_id;
END;

PROCEDURE AddLogEntryFileFromCache (
	in_activity_log_id				IN  activity_log.activity_log_id%TYPE,
	in_cache_key					IN  aspen2.filecache.cache_key%TYPE
)
AS
BEGIN
	-- our security check here will be to ensure that this is coming from the BuiltIn Administrator
	-- as this is being called by the inbound mail processor
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddLogEntryFileFromCache can only be run as BuiltIn/Administrator');
	END IF;
	
	INSERT INTO activity_log_file (activity_log_file_id, activity_log_id, filename, mime_type, data, sha1) 
	SELECT activity_log_file_id_seq.NEXTVAL, in_activity_log_id, filename, mime_type, object, 
		   CAST(dbms_crypto.hash(object, dbms_crypto.hash_sh1) AS VARCHAR2(40))
	  FROM aspen2.filecache 
	 WHERE cache_key = in_cache_key;
END;

PROCEDURE EmailReceived (
	in_activity_id					IN  activity_log.activity_id%TYPE,
	in_mail_address					IN  VARCHAR2,
	in_mail_name					IN  VARCHAR2,
	in_message						IN  activity_log.message%TYPE,
	out_activity_log_id				OUT activity_log.activity_log_id%TYPE
)
AS
	v_user_sid					security_pkg.T_SID_ID;
BEGIN
	-- our security check here will be to ensure that this is coming from the BuiltIn Administrator
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'EmailReceived can only be run as BuiltIn/Administrator');
	END IF;
	
	v_user_sid := csr.csr_user_pkg.GetUserSidFromEmail(in_mail_address);
	
	-- make sure logged_by_user_sid is in the chain_user table for RI
	helper_pkg.AddUserToChain(NVL(v_user_sid, security_pkg.GetSid));
	
	INSERT INTO activity_log (activity_log_id, activity_id, message, logged_by_user_sid,
	                          correspondent_name, is_from_email)
	     VALUES (activity_log_id_seq.NEXTVAL, in_activity_id, in_message, 
	             NVL(v_user_sid, security_pkg.GetSid),
	             CASE WHEN v_user_sid IS NULL THEN in_mail_name ELSE NULL END, 1)
	  RETURNING activity_log_id INTO out_activity_log_id;
	  
	INTERNAL_CallHelperPkg('ActivityLogEntryAdded', in_activity_id);
END;

/*********************************************************************************/
/**********************   ACTIVITY TAGS  *****************************************/
/*********************************************************************************/
PROCEDURE AddActivityTag(
	in_activity_id					IN  activity_tag.activity_id%TYPE,
	in_tag_id						IN  activity_tag.tag_id%TYPE,
	in_tag_group_id					IN  activity_tag.tag_group_id%TYPE
)
AS
	v_activity_type_id				activity.activity_type_id%TYPE;
BEGIN
	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assignee and users with the manage activity capability can edit activity tags.');
	END IF;
	
	SELECT activity_type_id
	  INTO v_activity_type_id
	  FROM activity
	 WHERE activity_id = in_activity_id;
	 
	BEGIN
		INSERT INTO activity_tag (activity_id, tag_id, activity_type_id, tag_group_id)
		     VALUES (in_activity_id, in_tag_id, v_activity_type_id, in_tag_group_id);
			 
		INTERNAL_CallHelperPkg('ActivityTagAdded', in_activity_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL; --already added
	END;
END;

PROCEDURE RemoveActivityTag(
	in_activity_id					IN  activity_tag.activity_id%TYPE,
	in_tag_id						IN  activity_tag.tag_id%TYPE,
	in_tag_group_id					IN  activity_tag.tag_group_id%TYPE
)
AS
BEGIN	
	IF NOT (INTERNAL_IsAssignedToUser(in_activity_id) OR INTERNAL_CanManageActivity(in_activity_id)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the assignee and users with the manage activity capability can edit activity tags.');
	END IF;
	 
	DELETE FROM activity_tag
	      WHERE activity_id = in_activity_id
		    AND tag_id = in_tag_id
			AND tag_group_id = in_tag_group_id;
			
	INTERNAL_CallHelperPkg('ActivityTagRemoved', in_activity_id);
END;

/*********************************************************************************/
/**********************   ACTIVITY TYPE   ****************************************/
/*********************************************************************************/
FUNCTION GetActivityTypeId (
	in_activity_type_lookup_key		IN  activity_type.lookup_key%TYPE
) RETURN NUMBER
AS
	v_activity_type_id				activity_type.activity_type_id%TYPE;					
BEGIN
	SELECT activity_type_id
	  INTO v_activity_type_id
	  FROM activity_type
	 WHERE lookup_key = in_activity_type_lookup_key;
	 
	RETURN v_activity_type_id;
END;

PROCEDURE GetActivityTypes(
	out_activity_types_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_group_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_activity_type_action_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_alert_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_alert_roles_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_outcome_cur					OUT security_pkg.T_OUTPUT_CUR,
	out_outcome_action_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	--no permissions, any user may need to read
	OPEN out_activity_types_cur FOR
		SELECT activity_type_id, label, css_class, due_dtm_relative, due_dtm_relative_unit,
	           has_target_user, has_location, user_can_create, lookup_key, title_template, can_share
		  FROM activity_type
		 ORDER BY label;
		  
	OPEN out_tag_group_cur FOR
		SELECT attg.activity_type_id, attg.tag_group_id, tg.name
		  FROM activity_type_tag_group attg
		  JOIN csr.v$tag_group tg ON attg.tag_group_id = tg.tag_group_id
		 ORDER BY tg.name;
		  
	OPEN out_activity_type_action_cur FOR
		SELECT ata.activity_type_action_id, ata.activity_type_id, ata.generate_activity_type_id, 
		       ata.allow_user_interaction, gat.label, ata.default_description,
		       ata.default_assigned_to_role_sid, ata.default_target_role_sid,
			   ar.name default_assigned_to_role_name, tr.name default_target_role_name, 
		       ata.default_act_date_relative, ata.default_act_date_relative_unit, 
			   ata.default_share_with_target, ata.default_location, ata.default_location_type,
			   ata.copy_tags, ata.copy_assigned_to, ata.copy_target
		  FROM activity_type_action ata
	 LEFT JOIN activity_type gat ON gat.activity_type_id = ata.generate_activity_type_id
	 LEFT JOIN csr.role ar ON ata.default_assigned_to_role_sid = ar.role_sid
	 LEFT JOIN csr.role tr ON ata.default_target_role_sid = tr.role_sid			
		 ORDER BY gat.label;

	OPEN out_alert_cur FOR
		SELECT ata.customer_alert_type_id, ata.activity_type_id, ata.label,
			   ata.use_supplier_company, ata.allow_manual_editing,
			   ata.send_to_target, ata.send_to_assignee,
			   atb.subject, atb.body_html
		  FROM activity_type_alert ata
	 LEFT JOIN csr.alert_template_body atb ON atb.customer_alert_type_id = ata.customer_alert_type_id;

	OPEN out_alert_roles_cur FOR
		SELECT atar.customer_alert_type_id, atar.activity_type_id, atar.role_sid, r.name
		  FROM activity_type_alert_role atar
	 LEFT JOIN csr.role r ON r.role_sid = atar.role_sid AND r.app_sid = atar.app_sid;
			
	OPEN out_outcome_cur FOR
		SELECT atot.activity_type_id, atot.outcome_type_id, ot.label
		  FROM activity_outcome_type atot
		  JOIN outcome_type ot ON atot.outcome_type_id = ot.outcome_type_id
		 ORDER BY ot.label;

	OPEN out_outcome_action_cur FOR
		SELECT aota.activity_outcome_typ_action_id, aota.activity_type_id, aota.generate_activity_type_id, 
		       aota.allow_user_interaction, gat.label, aota.outcome_type_id, aota.default_description,
		       aota.default_assigned_to_role_sid, aota.default_target_role_sid,
			   ar.name default_assigned_to_role_name, tr.name default_target_role_name, 
		       aota.default_act_date_relative, aota.default_act_date_relative_unit, 
			   aota.default_share_with_target, aota.default_location, aota.default_location_type,
			   aota.copy_tags, aota.copy_assigned_to, aota.copy_target
		  FROM activity_outcome_type_action aota
	 LEFT JOIN activity_type gat ON gat.activity_type_id = aota.generate_activity_type_id
	 LEFT JOIN csr.role ar ON aota.default_assigned_to_role_sid = ar.role_sid
	 LEFT JOIN csr.role tr ON aota.default_target_role_sid = tr.role_sid	
		 ORDER BY gat.label;
END;

PROCEDURE SetActivityType(
	in_activity_type_id				IN  activity_type.activity_type_id%TYPE,
	in_label						IN  activity_type.label%TYPE,
	in_css_class					IN  activity_type.css_class%TYPE,
	in_due_dtm_relative				IN  activity_type.due_dtm_relative%TYPE DEFAULT NULL,
	in_due_dtm_relative_unit		IN  activity_type.due_dtm_relative_unit%TYPE DEFAULT NULL,
	in_has_target_user				IN  activity_type.has_target_user%TYPE,
	in_has_location					IN  activity_type.has_location%TYPE,
	in_user_can_create				IN  activity_type.user_can_create%TYPE,	
	in_lookup_key					IN  activity_type.lookup_key%TYPE DEFAULT NULL,
	in_title_template				IN  activity_type.title_template%TYPE DEFAULT NULL,
	in_can_share					IN  activity_type.can_share%TYPE DEFAULT 0,
	in_tag_group_ids				IN  helper_pkg.T_NUMBER_ARRAY,
	out_activity_type_id			OUT activity_type.activity_type_id%TYPE
)
AS
	v_tag_group_ids					T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_tag_group_ids);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;
	
	IF in_activity_type_id IS NULL THEN
		INSERT INTO activity_type (activity_type_id, label, css_class, due_dtm_relative, 
		                           due_dtm_relative_unit, has_target_user, has_location, 
		                           user_can_create, lookup_key, title_template, can_share)
		     VALUES (activity_type_id_seq.NEXTVAL, in_label, in_css_class, in_due_dtm_relative, 
		             in_due_dtm_relative_unit, in_has_target_user, in_has_location, 
		             in_user_can_create, in_lookup_key, in_title_template, in_can_share)
		  RETURNING activity_type_id INTO out_activity_type_id;
	ELSE
		UPDATE activity_type
		   SET label = in_label,
		       css_class = in_css_class,
		       due_dtm_relative = in_due_dtm_relative,
		       due_dtm_relative_unit = in_due_dtm_relative_unit,
		       has_target_user = in_has_target_user,
		       has_location = in_has_location,
		       user_can_create = in_user_can_create,
			   lookup_key = in_lookup_key,
			   title_template = in_title_template,
			   can_share = in_can_share
		 WHERE activity_type_id = in_activity_type_id;
		 
		out_activity_type_id := in_activity_type_id;
	END IF;
	
	-- resync tag groups, not dropping existing ones
	DELETE FROM activity_type_tag_group
	      WHERE activity_type_id = out_activity_type_id
		    AND tag_group_id NOT IN (
			SELECT item
			  FROM TABLE(v_tag_group_ids)
			);
			
	INSERT INTO activity_type_tag_group (activity_type_id, tag_group_id)
		 SELECT out_activity_type_id, item
		   FROM TABLE(v_tag_group_ids)
		  WHERE item NOT IN (
			SELECT tag_group_id
			  FROM activity_type_tag_group
			 WHERE activity_type_id = out_activity_type_id
		  );
END;

PROCEDURE SetActivityTypeAction(
	in_activity_type_action_id		IN  activity_type_action.activity_type_action_id%TYPE,
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_generate_activity_type_id	IN  activity_type_action.generate_activity_type_id%TYPE,
	in_allow_user_interaction		IN  activity_type_action.allow_user_interaction%TYPE,
	in_default_description			IN  activity_type_action.default_description%TYPE DEFAULT NULL,
	in_def_assigned_to_role_sid		IN  activity_type_action.default_assigned_to_role_sid%TYPE DEFAULT NULL,
	in_default_target_role_sid		IN  activity_type_action.default_target_role_sid%TYPE DEFAULT NULL,
	in_default_act_date_relative	IN  activity_type_action.default_act_date_relative%TYPE DEFAULT NULL,
    in_default_act_date_rel_unit	IN  activity_type_action.default_act_date_relative_unit%TYPE DEFAULT 'd',
	in_default_share_with_target	IN  activity_type_action.default_share_with_target%TYPE DEFAULT 0,
	in_default_location				IN  activity_type_action.default_location%TYPE DEFAULT NULL,
	in_default_location_type		IN  activity_type_action.default_location_type%TYPE DEFAULT NULL,
	in_copy_tags					IN  activity_type_action.copy_tags%TYPE DEFAULT 0,
	in_copy_assigned_to				IN  activity_type_action.copy_assigned_to%TYPE DEFAULT 0,
	in_copy_target					IN  activity_type_action.copy_target%TYPE DEFAULT 0,
	out_activity_type_action_id		OUT activity_type_action.activity_type_action_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;
	
	IF in_activity_type_action_id IS NULL THEN
		INSERT INTO activity_type_action (activity_type_action_id, activity_type_id, 
		            generate_activity_type_id, allow_user_interaction, default_description, 
					default_assigned_to_role_sid, default_target_role_sid,
					default_act_date_relative, default_act_date_relative_unit, 
					default_share_with_target, default_location, default_location_type,
					copy_tags, copy_assigned_to, copy_target)
		     VALUES (activity_type_action_id_seq.NEXTVAL, in_activity_type_id, 
			         in_generate_activity_type_id, in_allow_user_interaction, in_default_description, 
					 in_def_assigned_to_role_sid, in_default_target_role_sid, in_default_act_date_relative, 
					 NVL(in_default_act_date_rel_unit, 'd'), in_default_share_with_target,
					 in_default_location, in_default_location_type,
					 in_copy_tags, in_copy_assigned_to, in_copy_target)
		  RETURNING activity_type_action_id INTO out_activity_type_action_id;
	ELSE
		UPDATE activity_type_action
		   SET activity_type_id = in_activity_type_id,
		       generate_activity_type_id = in_generate_activity_type_id,
		       allow_user_interaction = in_allow_user_interaction,
		       default_description = in_default_description,
		       default_assigned_to_role_sid = in_def_assigned_to_role_sid,
		       default_target_role_sid = in_default_target_role_sid,
		       default_act_date_relative = in_default_act_date_relative,
		       default_act_date_relative_unit = NVL(in_default_act_date_rel_unit, 'd'),
		       default_share_with_target = in_default_share_with_target,
		       default_location = in_default_location,
		       default_location_type = in_default_location_type,
			   copy_tags = in_copy_tags,
			   copy_assigned_to = in_copy_assigned_to,
			   copy_target = in_copy_target
		 WHERE activity_type_action_id = in_activity_type_action_id;
		 
		out_activity_type_action_id := in_activity_type_action_id;
	END IF;
END;

PROCEDURE DeleteOldActivityTypeActions(
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_act_type_action_ids_to_keep	IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_act_type_action_ids_to_keep	T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_act_type_action_ids_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	DELETE FROM activity_type_action
	      WHERE activity_type_id = in_activity_type_id
		    AND activity_type_action_id NOT IN (
			SELECT item
			  FROM TABLE(v_act_type_action_ids_to_keep)
			);
END;

PROCEDURE SetActivityTypeAlert(
	in_customer_alert_type_id		IN  activity_type_alert.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert.activity_type_id%TYPE,
	in_label						IN  activity_type_alert.label%TYPE,
	in_use_supplier_company			IN  activity_type_alert.use_supplier_company%TYPE,
	in_allow_manual_editing			IN  activity_type_alert.allow_manual_editing%TYPE,
	in_send_to_target				IN  activity_type_alert.send_to_target%TYPE,
	in_send_to_assignee				IN  activity_type_alert.send_to_assignee%TYPE,
	in_subject						IN	csr.alert_template_body.subject%TYPE,
	in_body_html					IN	csr.alert_template_body.body_html%TYPE,
	out_customer_alert_type_id		OUT  activity_type_alert.customer_alert_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	IF in_customer_alert_type_id IS NULL THEN
		INSERT INTO csr.customer_alert_type (customer_alert_type_id)
			VALUES (csr.customer_alert_type_Id_seq.nextval)
			RETURNING customer_alert_type_id INTO out_customer_alert_type_id;

		INSERT INTO activity_type_alert (customer_alert_type_id, activity_type_id, label,
										 use_supplier_company, allow_manual_editing,
										 send_to_target, send_to_assignee)
								 VALUES (out_customer_alert_type_id, in_activity_type_id, in_label,
										 in_use_supplier_company, in_allow_manual_editing,
										 in_send_to_target, in_send_to_assignee);

		INSERT INTO csr.alert_template (customer_alert_type_id, alert_frame_id, send_type, reply_to_name, reply_to_email)
				SELECT out_customer_alert_type_id, MIN(alert_frame_id), 'manual', null, null
				  FROM csr.alert_frame;

		INSERT INTO csr.alert_template_body (lang, subject, body_html, item_html, customer_alert_type_id)
			VALUES (
				'en',
				in_subject,
				in_body_html,
				'<template></template>',
				out_customer_alert_type_id
			);
	ELSE
		UPDATE activity_type_alert
		   SET label = in_label,
			   use_supplier_company = in_use_supplier_company,
			   allow_manual_editing = in_allow_manual_editing,
			   send_to_target = in_send_to_target,
			   send_to_assignee = in_send_to_assignee
		 WHERE customer_alert_type_id = in_customer_alert_type_id
		   AND activity_type_id = in_activity_type_id;

		UPDATE csr.alert_template_body
		   SET subject = in_subject,
			   body_html = in_body_html
		 WHERE customer_alert_type_id = in_customer_alert_type_id;

		out_customer_alert_type_id := in_customer_alert_type_id;
	END IF;

	BEGIN
		-- add the parameters
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 5);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 6);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'ACTIVITY_DATE_SHORT', 'Activity date (short format)', 'The date of the activity in a short format', 7);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'ACTIVITY_DATE_LONG', 'Activity date (long format)', 'The date of the activity in a long format', 8);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'ACTIVITY_TYPE', 'Activity type', 'The type of the activity', 9);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'ASSIGNED_TO_NAME', 'Assigned to name', 'The user / role name the activity is assigned to', 10);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'CREATED_BY_NAME', 'Created by name', 'The name of the user who created the activity', 11);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'DESCRIPTION', 'Description', 'The description of the activity', 12);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'LOCATION', 'Location', 'The Location of the activity', 13);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'STATUS', 'Status', 'The status of the activity', 14);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TAGS', 'Tags', 'The tags of the activity', 15);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TARGET_NAME', 'Target name', 'The user / role name of the target of the activity', 16);
		INSERT INTO CSR.customer_alert_type_param (customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
			 VALUES (out_customer_alert_type_id, 0, 'TARGET_COMPANY', 'Target company', 'The company name of the target of the activity', 17);
	EXCEPTION
		WHEN dup_val_on_index THEN NULL;
	END;
END;

PROCEDURE DeleteOldActivityTypeAlerts(
	in_activity_type_id				IN  activity_type_action.activity_type_id%TYPE,
	in_alert_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_alert_type_ids_to_keep	T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_alert_type_ids_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	DELETE FROM activity_type_alert_role
	      WHERE activity_type_id = in_activity_type_id
		    AND customer_alert_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_alert_type_ids_to_keep)
			);

	DELETE FROM activity_type_alert
	      WHERE activity_type_id = in_activity_type_id
		    AND customer_alert_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_alert_type_ids_to_keep)
			);
END;

PROCEDURE SetActivityTypeAlertRole(
	in_customer_alert_type_id		IN  activity_type_alert_role.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert_role.activity_type_id%TYPE,
	in_role_sid						IN  activity_type_alert_role.role_sid%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	BEGIN
		INSERT INTO activity_type_alert_role (customer_alert_type_id, activity_type_id, role_sid)
									  VALUES (in_customer_alert_type_id, in_activity_type_id, in_role_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;

PROCEDURE DeleteOldActTypeAlertRoles(
	in_customer_alert_type_id		IN  activity_type_alert_role.customer_alert_type_id%TYPE,
	in_activity_type_id				IN  activity_type_alert_role.activity_type_id%TYPE,
	in_role_sids_to_keep			IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_role_sids_to_keep	T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_role_sids_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	DELETE FROM activity_type_alert_role
	      WHERE activity_type_id = in_activity_type_id
		    AND customer_alert_type_id = in_customer_alert_type_id
			AND role_sid NOT IN (
			SELECT item
			  FROM TABLE(v_role_sids_to_keep)
			);
END;

PROCEDURE DeleteActivityType(
	in_activity_type_id				IN  activity_type.activity_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;
	
	FOR r IN (
		SELECT activity_id
		  FROM activity
		 WHERE activity_type_id = in_activity_type_id
	) LOOP
		DeleteActivity(r.activity_id);
	END LOOP;
	
	DELETE FROM activity_type_alert_role
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_type_alert
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_type_default_user
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_type_action
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_outcome_type_action
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_type_tag_group
	      WHERE activity_type_id = in_activity_type_id;
		  
	DELETE FROM activity_outcome_type
	      WHERE activity_type_id = in_activity_type_id;
	
	DELETE FROM activity_type
	      WHERE activity_type_id = in_activity_type_id;
END;

/*********************************************************************************/
/*********************  ACTIVITY OUTCOMES  ***************************************/
/*********************************************************************************/
PROCEDURE SetActivityOutcomeType(
	in_activity_type_id				IN  activity_outcome_type.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type.outcome_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;
	
	BEGIN
		INSERT INTO activity_outcome_type (activity_type_id, outcome_type_id)
		     VALUES (in_activity_type_id, in_outcome_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE DeleteOldActivityOutcomeTypes(
	in_activity_type_id				IN  activity_outcome_type.activity_type_id%TYPE,
	in_outcome_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_outcome_type_ids_to_keep	T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_outcome_type_ids_to_keep);
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	DELETE FROM activity_outcome_type_action
	      WHERE activity_type_id = in_activity_type_id
		    AND outcome_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_outcome_type_ids_to_keep)
			);

	DELETE FROM activity_outcome_type
	      WHERE activity_type_id = in_activity_type_id
		    AND outcome_type_id NOT IN (
			SELECT item
			  FROM TABLE(v_outcome_type_ids_to_keep)
			);
END;

PROCEDURE SetActivityOutcomeTypeAction(
	in_activity_oc_typ_action_id	IN  activity_outcome_type_action.activity_outcome_typ_action_id%TYPE DEFAULT NULL,
	in_activity_type_id				IN  activity_outcome_type_action.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type_action.outcome_type_id%TYPE,
	in_generate_activity_type_id	IN  activity_outcome_type_action.generate_activity_type_id%TYPE,
	in_allow_user_interaction		IN  activity_outcome_type_action.allow_user_interaction%TYPE,
	in_default_description			IN  activity_outcome_type_action.default_description%TYPE DEFAULT NULL,
	in_def_assigned_to_role_sid		IN  activity_outcome_type_action.default_assigned_to_role_sid%TYPE DEFAULT NULL,
	in_default_target_role_sid		IN  activity_outcome_type_action.default_target_role_sid%TYPE DEFAULT NULL,
	in_default_act_date_relative	IN  activity_outcome_type_action.default_act_date_relative%TYPE DEFAULT NULL,
    in_default_act_date_rel_unit	IN  activity_outcome_type_action.default_act_date_relative_unit%TYPE DEFAULT 'd',
	in_default_share_with_target	IN  activity_outcome_type_action.default_share_with_target%TYPE DEFAULT 0,
	in_default_location				IN  activity_outcome_type_action.default_location%TYPE DEFAULT NULL,
	in_default_location_type		IN  activity_outcome_type_action.default_location_type%TYPE DEFAULT NULL,
	in_copy_tags					IN  activity_outcome_type_action.copy_tags%TYPE DEFAULT 0,
	in_copy_assigned_to				IN  activity_outcome_type_action.copy_assigned_to%TYPE DEFAULT 0,
	in_copy_target					IN  activity_outcome_type_action.copy_target%TYPE DEFAULT 0,
	out_activity_oc_typ_action_id	OUT activity_outcome_type_action.activity_outcome_typ_action_id%TYPE
)
AS
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;

	IF in_activity_oc_typ_action_id IS NULL THEN
		BEGIN
			INSERT INTO activity_outcome_type_action (activity_outcome_typ_action_id,
						  activity_type_id, outcome_type_id, generate_activity_type_id, 
						  allow_user_interaction, default_description, 
						  default_assigned_to_role_sid, default_target_role_sid,
						  default_act_date_relative, default_act_date_relative_unit, 
						  default_share_with_target, default_location, default_location_type,
						  copy_tags, copy_assigned_to, copy_target)
				 VALUES (activity_type_action_id_seq.NEXTVAL,
						 in_activity_type_id, in_outcome_type_id,
						 in_generate_activity_type_id, in_allow_user_interaction, in_default_description, 
						 in_def_assigned_to_role_sid, in_default_target_role_sid, in_default_act_date_relative,
						 NVL(in_default_act_date_rel_unit, 'd'), in_default_share_with_target,
						 in_default_location, in_default_location_type,
						 in_copy_tags, in_copy_assigned_to, in_copy_target)
			  RETURNING activity_outcome_typ_action_id INTO out_activity_oc_typ_action_id;
		EXCEPTION
			WHEN dup_val_on_index THEN
				SELECT activity_outcome_typ_action_id
				  INTO out_activity_oc_typ_action_id
				  FROM activity_outcome_type_action
				 WHERE activity_type_id = in_activity_type_id
				   AND outcome_type_id = in_outcome_type_id
				   AND generate_activity_type_id = in_generate_activity_type_id;
				
				UPDATE activity_outcome_type_action
				   SET allow_user_interaction = in_allow_user_interaction,
				       default_description = in_default_description,
				       default_assigned_to_role_sid = in_def_assigned_to_role_sid,
				       default_target_role_sid = in_default_target_role_sid,
				       default_act_date_relative = in_default_act_date_relative,
				       default_act_date_relative_unit = NVL(in_default_act_date_rel_unit, 'd'),
				       default_share_with_target = in_default_share_with_target,
				       default_location = in_default_location,
				       default_location_type = in_default_location_type,
					   copy_tags = in_copy_tags,
					   copy_assigned_to = in_copy_assigned_to,
					   copy_target = in_copy_target
				 WHERE activity_outcome_typ_action_id = out_activity_oc_typ_action_id;
		END;
	ELSE
		UPDATE activity_outcome_type_action
		   SET generate_activity_type_id = in_generate_activity_type_id,
		       allow_user_interaction = in_allow_user_interaction,
		       default_description = in_default_description,
		       default_assigned_to_role_sid = in_def_assigned_to_role_sid,
		       default_target_role_sid = in_default_target_role_sid,
		       default_act_date_relative = in_default_act_date_relative,
		       default_act_date_relative_unit = NVL(in_default_act_date_rel_unit, 'd'),
		       default_share_with_target = in_default_share_with_target,
		       default_location = in_default_location,
		       default_location_type = in_default_location_type,
		       copy_tags = in_copy_tags,
		       copy_assigned_to = in_copy_assigned_to,
		       copy_target = in_copy_target
		 WHERE activity_outcome_typ_action_id = in_activity_oc_typ_action_id;
		 
		 out_activity_oc_typ_action_id := in_activity_oc_typ_action_id;
	END IF;
END;

PROCEDURE DeleteOldActOCTypeActions(
	in_activity_type_id				IN  activity_outcome_type_action.activity_type_id%TYPE,
	in_outcome_type_id				IN  activity_outcome_type_action.outcome_type_id%TYPE,
	in_act_oc_type_ids_to_keep		IN  helper_pkg.T_NUMBER_ARRAY
)
AS
	v_act_oc_type_ids_to_keep	T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_act_oc_type_ids_to_keep);
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify activity types.');
	END IF;
	
	DELETE FROM activity_outcome_type_action
	      WHERE activity_type_id = in_activity_type_id
		    AND outcome_type_id = in_outcome_type_id
		    AND activity_outcome_typ_action_id NOT IN (
			SELECT item
			  FROM TABLE(v_act_oc_type_ids_to_keep)
			);
END;

/*********************************************************************************/
/**********************    OUTCOME TYPE     **************************************/
/*********************************************************************************/
PROCEDURE GetOutcomeTypes(
	out_outcome_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no permissions, any user may need to read
	OPEN out_outcome_cur FOR
		SELECT outcome_type_id, label, is_success, is_failure, is_deferred, 
		       require_reason, lookup_key
		  FROM outcome_type
		 ORDER BY label;
END;                                      

PROCEDURE SetOutcomeType(
	in_outcome_type_id				IN  outcome_type.outcome_type_id%TYPE,
	in_label						IN  outcome_type.label%TYPE,
	in_is_success					IN  outcome_type.is_success%TYPE,
	in_is_failure					IN  outcome_type.is_failure%TYPE,
	in_is_deferred					IN  outcome_type.is_deferred%TYPE,
	in_require_reason				IN  outcome_type.require_reason%TYPE,
	in_lookup_key					IN  outcome_type.lookup_key%TYPE,
	out_outcome_type_id				OUT outcome_type.outcome_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify outcome types.');
	END IF;
	
	IF in_outcome_type_id IS NULL THEN
		INSERT INTO outcome_type (outcome_type_id, label, is_success, is_failure, 
		                          is_deferred, require_reason, lookup_key)
		     VALUES (outcome_type_id_seq.NEXTVAL, in_label, in_is_success, in_is_failure, 
		             in_is_deferred, in_require_reason, in_lookup_key)
		  RETURNING outcome_type_id INTO out_outcome_type_id;
	ELSE
		UPDATE outcome_type
		   SET label = in_label,
		       is_success = in_is_success,
		       is_failure = in_is_failure,
		       is_deferred = in_is_deferred,
		       require_reason = in_require_reason,
		       lookup_key = in_lookup_key
		 WHERE outcome_type_id = in_outcome_type_id;
		 
		out_outcome_type_id := in_outcome_type_id;
	END IF;
END;

PROCEDURE DeleteOutcomeType(
	in_outcome_type_id				IN  outcome_type.outcome_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr.csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can modify outcome types.');
	END IF;
	
	UPDATE activity
	   SET outcome_type_id = null
	 WHERE outcome_type_id = in_outcome_type_id;
	
	DELETE FROM activity_outcome_type_action
	      WHERE outcome_type_id = in_outcome_type_id;
		  
	DELETE FROM activity_outcome_type
	      WHERE outcome_type_id = in_outcome_type_id;	  
		  
	DELETE FROM outcome_type
	      WHERE outcome_type_id = in_outcome_type_id;
END;

PROCEDURE GetInboundActivityAccounts(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as this is run from a batch job
	OPEN out_cur FOR
		SELECT c.host, a.inbox_sid, a.email_address
		  FROM customer_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		  JOIN mail.account a ON co.activity_mail_account_sid = a.account_sid;
END;

PROCEDURE GetInboundEmailAddress (
	out_email						OUT	mail.account.email_address%TYPE
)
AS
BEGIN
	SELECT MIN(a.email_address)
	  INTO out_email
	  FROM customer_options co
	  JOIN mail.account a ON co.activity_mail_account_sid = a.account_sid
	 WHERE co.app_sid = security_pkg.GetApp;
END;

END activity_pkg;
/

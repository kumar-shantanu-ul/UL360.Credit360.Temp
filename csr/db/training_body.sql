CREATE OR REPLACE PACKAGE BODY CSR.Training_Pkg
IS
-- Temporary helper to push booking state to COMPLETE if no pass/fail is set on the course
-- Logic needs improving to avoid using this.
PROCEDURE CheckAutoComplete(
	in_flow_item_id			IN flow_item.flow_item_id%TYPE
)
AS
	v_auto_complete			NUMBER(1);
	v_course_schedule_id	course_schedule.course_schedule_id%TYPE;
	v_user_sid				user_training.user_sid%TYPE;
BEGIN
	SELECT CASE
				WHEN fi.current_state_lookup_key = 'POST_ATTENDED' AND c.pass_fail = 0 AND fi.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_POST_ATTENDED 
				THEN 1
				ELSE 0
		   END auto_complete,
		   course_schedule_id,
		   user_sid
	  INTO v_auto_complete, v_course_schedule_id, v_user_sid
	  FROM csr.v$training_flow_item fi
	  JOIN course c ON fi.course_id = c.course_id
	 WHERE fi.flow_item_id = in_flow_item_id;
	
	IF v_auto_complete = 1 THEN
		SetPassed(
			in_course_schedule_id	=> v_course_schedule_id,
			in_user_sid				=> v_user_sid,
			in_passed				=> 1,
			in_score				=> null
		);
	END IF;
END;

-- Handle lots of random 0s and -1s passed in to mean NULL
FUNCTION DecodeNull(
	in_val	IN NUMBER
)
RETURN NUMBER
AS
BEGIN
	IF in_val IN (0, -1) THEN
		RETURN NULL;
	ELSE
		RETURN in_val;
	END IF;
END;

FUNCTION GetFlowSid
RETURN NUMBER
AS
	v_flow_sid NUMBER(10);
BEGIN
	SELECT flow_sid
	  INTO v_flow_sid
	  FROM training_options
	 WHERE app_sid = security.security_pkg.getApp;
	
	IF v_flow_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Training workflow not configured for this customer');
	END IF;
	
	RETURN v_flow_sid;
END;

FUNCTION GetManager(
	in_user_sid				IN	NUMBER,
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE
)
RETURN NUMBER
AS
	v_manager_sid			NUMBER(10);
BEGIN
	BEGIN
		SELECT ur.PARENT_USER_SID
		  INTO v_manager_sid
		  FROM course_schedule cs
		  JOIN course c ON c.course_id = cs.course_id
		  JOIN course_type ct ON ct.course_type_id = c.course_type_id
		  JOIN user_relationship ur ON ur.user_relationship_type_id = ct.user_relationship_type_id
		 WHERE course_schedule_id = in_course_schedule_id
		   AND ur.CHILD_USER_SID = in_user_sid
		   AND cs.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_manager_sid := NULL;			
	END;

	RETURN v_manager_sid;
END;

FUNCTION GetUserCourseFunctions(
	in_user_sid		IN	user_course.user_sid%TYPE,
	in_course_id	IN	course.course_id%TYPE
)
RETURN VARCHAR2
AS
	v_job_functions		VARCHAR2(1000);
BEGIN
	SELECT STRAGG2(f.label)
	  INTO v_job_functions
	  FROM course c
	  JOIN function_course fc ON fc.course_id = c.course_id
	  JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
	  JOIN function f ON fc.function_id = f.function_id
	  JOIN user_function uf 
			 ON uf.function_id = fc.function_id 
			AND csr_user_sid = in_user_sid
	 WHERE c.course_id = in_course_id
  ORDER BY tp.pos;

	RETURN v_job_functions;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;

END;

FUNCTION IsBookingOpen(
	in_start_dtm		IN DATE,
	in_end_dtm			IN DATE,
	in_delivery_method	IN delivery_method.delivery_method_id%TYPE
)
RETURN NUMBER
AS
BEGIN
	CASE
		WHEN (in_delivery_method = DELIVERY_ON_LOCATION AND in_start_dtm >= SYSDATE) THEN
			RETURN 1;
		WHEN (in_delivery_method = DELIVERY_ONLINE AND in_end_dtm IS NOT NULL AND in_end_dtm > SYSDATE) THEN
			RETURN 1;
		ELSE
			RETURN 0;
	END CASE;
END;

FUNCTION CoursesNotAvailableAsTable(
	in_user_sid		IN user_training.user_sid%TYPE
)
RETURN T_TRAINING_USER_COURSE_TABLE
AS
	v_table	T_TRAINING_USER_COURSE_TABLE := T_TRAINING_USER_COURSE_TABLE();
BEGIN
	/*
	Logic for course NOT available to any given trainee is:
	1) The have completed/passed the course and it is not up for renewal
	2) They have ongoing "unapproved" or "approved" bookings
	*/
	
	SELECT T_TRAINING_USER_COURSE_ROW (tf.app_sid, tf.user_sid, tf.course_id)
	  BULK COLLECT INTO v_table
	  FROM v$training_flow_item tf
 LEFT JOIN user_course uc
			 ON tf.course_id = uc.course_id
			AND tf.user_sid = uc.user_sid
	 WHERE tf.app_sid = SYS_CONTEXT('security', 'app')
	   AND (in_user_sid IS NULL OR tf.user_sid = in_user_sid)
	   AND (
			tf.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_UNAPPROVED, csr_data_pkg.NATURE_TRAINING_APPROVED) -- Currently being booked
			OR	(	-- Completed but not due for renewal
				tf.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_POST_ATTENDED
				-- AND uc.valid = 1
				AND uc.reschedule_due = 0
				)
			)
	GROUP BY tf.app_sid, tf.user_sid, tf.course_id;

	RETURN v_table;
END;

FUNCTION HasTransitionInvolvement(
	in_flow_state_transition_id IN flow_state_transition.flow_state_transition_id%TYPE,
	in_flow_involvement_type_id	IN flow_involvement_type.flow_involvement_type_id%TYPE
)
RETURN BOOLEAN
AS
	v_check	NUMBER(10);
BEGIN
	SELECT COUNT(flow_state_transition_id)
	  INTO v_check
	  FROM flow_state_transition_inv
	 WHERE flow_state_transition_id = in_flow_state_transition_id
	   AND flow_involvement_type_id = in_flow_involvement_type_id;

	RETURN v_check != 0;
END;

FUNCTION HasTransitionRolePerm(
	in_flow_state_transition_id IN flow_state_transition.flow_state_transition_id%TYPE,
	in_user_sid					IN user_training.user_sid%TYPE	
)
RETURN BOOLEAN
AS
	v_check		NUMBER(10);
BEGIN
	/* TODO: find answer to this:
	Do we link to user start point as well? If the region start point is not set it defaults to "Regions" 
	and role membership cannot be attributed to "Regions" so it won't work. 
	Every training employee would have to have a region start point set
	*/
	-- Check user has membership on a role involved with transition state.
	SELECT COUNT(rrm.user_sid)
	  INTO v_check
	  FROM flow_state_transition t
	  JOIN flow_state_transition_role tr ON t.flow_state_transition_id = tr.flow_state_transition_id
 LEFT JOIN region_role_member rrm
			 ON tr.role_sid = rrm.role_sid
			AND user_sid = SYS_CONTEXT('SECURITY', 'SID') -- CURRENT USER
 LEFT JOIN region_start_point rsp  -- Use region start point for trainee??? (SEE ABOVE)
			 ON rsp.user_sid = in_user_sid
			AND rrm.region_sid = rsp.region_sid
	 WHERE t.flow_state_transition_id = in_flow_state_transition_id;
  
	RETURN v_check != 0;
END;

FUNCTION HasTransitionPermission(
	in_trainee_sid				IN user_training.user_sid%TYPE,
	in_course_schedule_id		IN course_schedule.course_schedule_id%TYPE,
	in_flow_state_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE,
	in_to_state_id				IN flow_state.flow_state_id%TYPE
)
RETURN BOOLEAN
AS
	v_user_sid		user_training.user_sid%TYPE := SYS_CONTEXT('SECURITY', 'SID');
	v_is_manager	NUMBER(10);
BEGIN
	IF v_user_sid = in_trainee_sid THEN
		RETURN HasTransitionInvolvement(in_flow_state_transition_id, csr_data_pkg.FLOW_INV_TYPE_TRAINEE);
	END IF;
	
	BEGIN
		SELECT DECODE(COUNT(ur.parent_user_sid), 0, 0, 1)
		  INTO v_is_manager
		  FROM course_schedule cs
		  JOIN course c ON c.course_id = cs.course_id
		  JOIN course_type ct ON ct.course_type_id = c.course_type_id
		  JOIN user_relationship ur
				 ON ur.user_relationship_type_id = ct.user_relationship_type_id
				AND ur.parent_user_sid = v_user_sid
		 WHERE course_schedule_id = in_course_schedule_id
		   AND ur.child_user_sid = in_trainee_sid
		   AND cs.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_is_manager := 0;			
	END;
	
	IF v_is_manager = 1 THEN
		RETURN HasTransitionInvolvement(in_flow_state_transition_id, csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER);	
	END IF;
	
	RETURN HasTransitionRolePerm(in_flow_state_transition_id, in_trainee_sid);
END;

FUNCTION UserCourseRegionExists(
	in_course_region_sid	IN course.region_sid%TYPE,
	in_trainee_sid			IN user_training.user_sid%TYPE
)
RETURN NUMBER
AS
	v_course_region_sid	course.region_sid%TYPE;
	v_region_sids		security.T_SID_TABLE;
	v_exists			NUMBER(1);
BEGIN
	-- Cater for lagacy use of magic numbers
	IF in_course_region_sid IN (0, -1) THEN
		v_course_region_sid := null;
	ELSE
		v_course_region_sid := in_course_region_sid;
	END IF;

	-- Collect user mount points
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM region_start_point
	 WHERE user_sid = in_trainee_sid;

	-- Find if the regions associated with this course match any regions associated with this user.
	-- It's not a straight match, one of the user's regions must fall within the course region sid (or child there of), or vice verse!
	SELECT DECODE(COUNT(region_sid), 0, 0, 1) INTO v_exists
	  FROM
			(
				SELECT cr.region_sid
				  FROM ( -- Regions associated with this course
						SELECT r1.region_sid, r1.app_sid, r1.description
						  FROM v$region r1
					START WITH r1.app_sid = SECURITY.SECURITY_PKG.GETAPP 
						   AND r1.region_sid = v_course_region_sid
					   CONNECT BY PRIOR app_sid = app_sid
						   AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
						) cr
				  JOIN ( -- Regions for this user by start point
						SELECT region_sid, app_sid, description
						  FROM v$region
					START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP 
						   AND region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
					   CONNECT BY PRIOR app_sid = app_sid
						   AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
						) ur ON ur.region_sid = cr.region_sid
				
			);

	RETURN v_exists;
END;

FUNCTION GetFlowStatesAsTable(
	in_involvement_type_id	IN flow_involvement_type.flow_involvement_type_ID%TYPE,
	in_by_role_user_sid		IN csr_user.csr_user_sid%TYPE
)
RETURN T_TRAINING_FLOW_STATE_TABLE
AS
	v_table	T_TRAINING_FLOW_STATE_TABLE := T_TRAINING_FLOW_STATE_TABLE();
BEGIN
		SELECT T_TRAINING_FLOW_STATE_ROW (fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.flow_state_nature_id, fs.pos)
		  BULK COLLECT INTO v_table
		  FROM flow_state fs
	 LEFT JOIN flow_state_involvement fsi ON fs.flow_state_id = fsi.flow_state_id
	 LEFT JOIN flow_state_role fsr ON fs.flow_state_id = fsr.flow_state_id
	 LEFT JOIN region_role_member rrm ON fsr.role_sid = rrm.role_sid
		 WHERE fs.app_sid = SYS_CONTEXT('security', 'app')
		   AND fs.flow_sid = GetFlowSid
		   AND fs.is_deleted = 0
		   AND	(
				fsi.flow_involvement_type_id = in_involvement_type_id
				OR
				rrm.user_sid = in_by_role_user_sid 
				)
	  GROUP BY fs.flow_state_id, fs.flow_sid, fs.label, fs.lookup_key, fs.flow_state_nature_id, fs.pos;
	
	RETURN v_table;
END;

PROCEDURE GetFlowStates(
	in_involvement_type_id	IN flow_involvement_type.flow_involvement_type_ID%TYPE,
	in_by_role_user_sid		IN csr_user.csr_user_sid%TYPE,
	out_curr				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_curr FOR
		SELECT flow_state_id,
			   flow_sid,
			   pos
		  FROM TABLE (GetFlowStatesAsTable(in_involvement_type_id, in_by_role_user_sid))
		 ORDER BY pos;
END;

PROCEDURE DeleteBooking(
	in_user_sid				IN user_training.user_sid%TYPE,
	in_course_id			IN user_training.course_id%TYPE,
	in_course_schedule_id	IN user_training.course_schedule_id%TYPE,
	in_flow_item_id			IN user_training.flow_item_id%TYPE
)
AS
BEGIN
	DELETE FROM flow_item_generated_alert
	 WHERE flow_item_id = in_flow_item_id;

	DELETE FROM flow_state_log WHERE flow_item_id = in_flow_item_id;
	 
	DELETE FROM user_training
	 WHERE user_sid = in_user_sid
	   AND course_id = in_course_id
	   AND course_schedule_id = in_course_schedule_id
	   AND flow_item_id = in_flow_item_id;
	
	IF in_flow_item_id IS NOT NULL THEN
		DELETE FROM flow_item WHERE flow_item_id = in_flow_item_id;
	END IF;
END;

/* START: Scheduled job procedures */
PROCEDURE DeleteOldUnapprovedBookings
AS
BEGIN
	FOR r IN (
		SELECT ut.user_sid, ut.course_id, ut.course_schedule_id, ut.flow_item_id
				-- ce.start_dtm, ce.end_dtm, f.current_state_label, f.flow_state_nature_id, f.flow_state_nature, c.delivery_method_id
		  FROM user_training ut
		  JOIN course c ON ut.course_id = c.course_id
		  JOIN course_schedule cs ON ut.course_schedule_id = cs.course_schedule_id
		  JOIN calendar_event ce ON cs.calendar_event_id = ce.calendar_event_id
		  JOIN v$training_flow_item f ON ut.flow_item_id = f.flow_item_id
		 WHERE (
				f.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_UNAPPROVED
				OR
				f.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
				)
		   AND	(	-- "On location" are expired if the start date is passed, Online courses are expired if the end date is passed
					(start_dtm < SYSDATE AND c.delivery_method_id = DELIVERY_ON_LOCATION)
					OR
					(end_dtm IS NOT NULL AND end_dtm < SYSDATE AND c.delivery_method_id = DELIVERY_ONLINE)
				)
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('DeleteBooking: '||TO_CHAR(r.course_schedule_id));
		DeleteBooking(
			in_user_sid				=> r.user_sid,
			in_course_id			=> r.course_id,
			in_course_schedule_id	=> r.course_schedule_id,
			in_flow_item_id			=> r.flow_item_id
			);
	END LOOP;
END;

/* END: Scheduled job procedures */

PROCEDURE GetTraineeFlowTransitions(
	out_transitions_cur		OUT SYS_REFCURSOR
)
AS
	v_flow_sid	flow.flow_sid%TYPE;
BEGIN
	v_flow_sid := GetFlowSid();
	
	IF NOT security_pkg.IsAccessAllowedSID(security.security_pkg.getACT, v_flow_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	OPEN out_transitions_cur FOR
		 SELECT fst.flow_state_transition_id,
				fst.owner_can_set,
				fst.from_state_id,
				fst.to_state_id,
				fst.verb,
				fst.lookup_key,
				fst.ask_for_comment, 
				fst.mandatory_fields_message,
				fst.hours_before_auto_tran,
				fst.button_icon_path,
				fst.pos
		   FROM flow_state_transition fst
		   JOIN flow_state_transition_inv fsi
					 ON fst.flow_state_transition_id = fsi.flow_state_transition_id
					AND fsi.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE
		  WHERE fst.flow_sid = v_flow_sid
	   ORDER BY fst.from_state_id, fst.pos;
END;

PROCEDURE FilterAvailableCourses(
	in_trainee_sid				IN csr_user.csr_user_sid%TYPE,
	in_open_courses_only		IN NUMBER,
	in_user_level				IN NUMBER,
	in_training_priority_id		IN function_course.training_priority_id%TYPE,
	in_course_type_id			IN course.course_type_id%TYPE,
	in_function_id				IN function_course.function_id%TYPE,
	in_status_id				IN course.status_id%TYPE,
	in_provision_id				IN course.provision_id%TYPE,
	in_region_sid				IN course.region_sid%TYPE
)
AS
	v_user_sid				NUMBER(10);
	v_app_sid				NUMBER(10);
	v_default_state_id		flow.default_state_id%TYPE;
	v_involvement_type_id	flow_involvement_type.flow_involvement_type_id%TYPE;
BEGIN
/* COMING SOON: Multiple course regions US3189 */	
	v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = GetFlowSid;
	
	CASE in_user_level
		WHEN USER_LEVEL_TRAINEE THEN
			v_involvement_type_id := csr_data_pkg.FLOW_INV_TYPE_TRAINEE;
		WHEN USER_LEVEL_MANAGER THEN
			v_involvement_type_id := csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER;
		ELSE
			v_involvement_type_id := NULL;
	END CASE;
	
	INSERT INTO temp_user_course_filter
			(
			trainee_sid,
			course_id,
			title,
			training_priority_id,
			training_priority_pos
			)
	 SELECT x.csr_user_sid,
			x.course_id,
			x.title,
			ttp.training_priority_id,
			x.training_priority_pos
	   FROM (
				 SELECT uf.csr_user_sid,
						c.course_id,
						c.title,
						c.region_sid,
						MIN(tp.pos) training_priority_pos
				   FROM user_function uf
				   JOIN function f ON f.function_id = uf.function_id
				   JOIN function_course fc ON f.function_id = fc.function_id
				   JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
				   JOIN course c ON fc.course_id = c.course_id
			  LEFT JOIN course_schedule cs ON c.course_id = cs.course_id
			  LEFT JOIN calendar_event ce ON cs.calendar_event_id = ce.calendar_event_id
				   JOIN course_type ct
						 ON ct.app_sid = c.app_sid
						AND ct.course_type_id = c.course_type_id
				   JOIN user_relationship_type urt ON urt.app_sid = ct.app_sid AND urt.user_relationship_type_id = ct.user_relationship_type_id
				   JOIN user_relationship ur -- Link to line manager
						 ON ur.app_sid = urt.app_sid
						AND ur.user_relationship_type_id = urt.user_relationship_type_id
						AND ur.child_user_sid = uf.csr_user_sid
			  LEFT JOIN region_role_member rrm -- Link to training admin role
						 ON rrm.role_sid = role_pkg.GetRoleIdByKey('TRAINING_ADMIN')
						AND rrm.region_sid = c.region_sid
						AND rrm.user_sid = v_user_sid
			  LEFT JOIN TABLE(training_pkg.CoursesNotAvailableAsTable(uf.csr_user_sid)) na -- Not available courses
						 ON uf.csr_user_sid = na.user_sid
						AND c.course_id = na.course_id
				  WHERE c.app_sid = v_app_sid
					AND na.course_id IS NULL -- EXCLUDE: 'NOT AVAILABLE' COURSE
					-- FILTERS
					AND (in_trainee_sid IS NULL OR uf.csr_user_sid = in_trainee_sid)
					AND (in_open_courses_only = 0 OR training_pkg.IsBookingOpen(ce.start_dtm, ce.end_dtm, c.delivery_method_id) = 1)
					AND (in_course_type_id IS NULL OR c.course_type_id = in_course_type_id)
					AND (in_function_id IS NULL OR fc.function_id = in_function_id)
					AND (in_status_id IS NULL OR c.status_id = in_status_id)
					AND (in_provision_id IS NULL OR c.provision_id = in_provision_id)
					AND (in_region_sid IS NULL OR c.region_sid IN (
																	SELECT region_sid
																	  FROM region
																START WITH app_sid = v_app_sid
																	   AND region_sid = in_region_sid
														  CONNECT BY PRIOR app_sid = app_sid
															AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
																)
						)
					-- PERMISSIONS
					AND (
							(in_user_level = USER_LEVEL_TRAINEE AND uf.csr_user_sid = v_user_sid)
							OR (in_user_level = USER_LEVEL_MANAGER AND ur.parent_user_sid = v_user_sid)
							OR (in_user_level = USER_LEVEL_ADMIN AND rrm.user_sid = v_user_sid)
						)
			   GROUP BY uf.csr_user_sid, c.course_id, c.title, c.region_sid
				) x, training_priority ttp
		 WHERE training_pkg.UserCourseRegionExists(region_sid, csr_user_sid) = 1 -- Trainee-course-region match
		   AND x.training_priority_pos = ttp.pos
		   AND (in_training_priority_id IS NULL OR ttp.training_priority_id = in_training_priority_id);
END;

PROCEDURE FilterAvailableCourses(
	in_trainee_sid				IN csr_user.csr_user_sid%TYPE,
	in_open_courses_only		IN NUMBER,
	in_user_level				IN NUMBER,
	in_training_priority_id		IN training_priority.training_priority_id%TYPE	
)
AS
BEGIN
	FilterAvailableCourses(
		in_trainee_sid			=> in_trainee_sid,
		in_open_courses_only	=> in_open_courses_only,
		in_user_level			=> in_user_level,
		in_training_priority_id	=> in_training_priority_id,
		in_course_type_id		=> null,
		in_function_id			=> null,
		in_status_id			=> null,
		in_provision_id			=> null,
		in_region_sid			=> null);		
END;

PROCEDURE FilterUserBookings(
	in_trainee_sid			IN user_training.user_sid%TYPE,
	in_user_level			IN NUMBER,
	in_flow_state_id		IN flow_state.flow_state_id%TYPE,
	in_flow_state_nature_id	IN flow_state.flow_state_nature_id%TYPE,
	in_course_type_id		IN course.course_type_id%TYPE,
	in_function_id			IN function_course.function_id%TYPE,
	in_provision_id			IN course.provision_id%TYPE,
	in_status_id			IN course.status_id%TYPE,
	in_region_sid			IN course.region_sid%TYPE
)
AS
	v_user_sid	NUMBER(10);
	v_involvement_type_id	flow_involvement_type.flow_involvement_type_id%TYPE;
BEGIN
	v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	
	CASE in_user_level
		WHEN USER_LEVEL_TRAINEE THEN
			v_involvement_type_id := csr_data_pkg.FLOW_INV_TYPE_TRAINEE;
		WHEN USER_LEVEL_MANAGER THEN
			v_involvement_type_id := csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER;
		ELSE
			v_involvement_type_id := NULL;
	END CASE;
	
 INSERT INTO temp_user_course_filter
			(
			trainee_sid,
			course_id,
			title,
			flow_item_id,
			flow_state_id,
			training_priority_id,
			training_priority_pos
			)
	 SELECT x.user_sid,
			x.course_id,
			x.title, 
			x.flow_item_id,
			x.current_state_id,
			ttp.training_priority_id,
			x.training_priority_pos
      FROM (
			 SELECT ut.user_sid,
					c.course_id,
					c.title,
					c.region_sid,
					ut.flow_item_id,
					f.current_state_id,
					MIN(tp.pos) training_priority_pos
			   FROM user_training ut
			   JOIN course c ON c.course_id = ut.course_id
			   JOIN v$training_flow_item f
						 ON ut.flow_item_id = f.flow_item_id
						AND f.flow_state_is_deleted = 0
			   JOIN course_schedule cs ON ut.course_schedule_id = cs.course_schedule_id
			   JOIN course_type ct
						 ON ct.app_sid = c.app_sid
						AND ct.course_type_id = c.course_type_id
			   JOIN TABLE(training_pkg.GetFlowStatesAsTable(v_involvement_type_id, v_user_sid)) fst ON fst.flow_state_id = f.current_state_id-- flow states with view permission
			   JOIN user_relationship_type urt
						 ON urt.app_sid = ct.app_sid
						AND urt.user_relationship_type_id = ct.user_relationship_type_id
		  LEFT JOIN user_relationship ur -- Link to line manager
						 ON ur.app_sid = urt.app_sid
						AND ur.user_relationship_type_id = urt.user_relationship_type_id
						AND ur.child_user_sid = ut.user_sid
						AND ur.parent_user_sid = v_user_sid
		  LEFT JOIN region_role_member rrm
						 ON rrm.role_sid = role_pkg.GetRoleIdByKey('TRAINING_ADMIN')
						AND rrm.region_sid = c.region_sid
						AND rrm.user_sid = v_user_sid
		  LEFT JOIN function_course fc ON fc.course_id = c.course_id
		  LEFT JOIN user_function uf 
					  ON ut.user_sid = uf.csr_user_sid
					  AND fc.function_id = uf.function_id
		  LEFT JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
			  WHERE c.app_sid = SYS_CONTEXT('security', 'app')
				-- FILTERS
				AND (in_trainee_sid IS NULL OR ut.user_sid = in_trainee_sid)
				AND (in_flow_state_id IS NULL OR f.current_state_id = in_flow_state_id)
				AND (in_flow_state_nature_id IS NULL OR f.flow_state_nature_id = in_flow_state_nature_id)
				AND (in_course_type_id IS NULL OR c.course_type_id = in_course_type_id)
				AND (in_function_id IS NULL OR fc.function_id = in_function_id)
				AND (in_status_id IS NULL OR c.status_id = in_status_id)
				AND (in_provision_id IS NULL OR c.provision_id = in_provision_id)
				AND (in_region_sid IS NULL OR c.region_sid IN (
																	SELECT region_sid
																	  FROM region
																START WITH app_sid = SYS_CONTEXT('security', 'app') 
																	   AND region_sid = in_region_sid
														  CONNECT BY PRIOR app_sid = app_sid
															AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
																)
					)
				-- PERMISSIONS
				AND (
						(in_user_level = USER_LEVEL_TRAINEE AND ut.user_sid = v_user_sid)
						OR (in_user_level = USER_LEVEL_MANAGER AND ur.parent_user_sid = v_user_sid)
						OR (in_user_level = USER_LEVEL_ADMIN AND rrm.user_sid = v_user_sid)
					)
		   GROUP BY ut.user_sid,
					c.course_id,
					c.title,
					c.region_sid,
					ut.flow_item_id,
					f.current_state_id
			   ) x
	 LEFT JOIN training_priority ttp ON x.training_priority_pos = ttp.pos;

END;

PROCEDURE FilterUserBookings(
	in_trainee_sid			IN user_training.user_sid%TYPE,
	in_user_level			IN NUMBER,
	in_flow_state_id		IN flow_state.flow_state_id%TYPE
)
AS
BEGIN
	FilterUserBookings(
		in_trainee_sid			=> in_trainee_sid,
		in_user_level			=> in_user_level,
		in_flow_state_id		=> in_flow_state_id,
		in_flow_state_nature_id	=> null,
		in_course_type_id		=> null,
		in_function_id			=> null,
		in_provision_id			=> null,
		in_status_id			=> null,
		in_region_sid			=> null
	);
END;

PROCEDURE FilterAllSchedules(
	in_user_level				IN NUMBER,
	in_course_type_id			IN course.course_type_id%TYPE,
	in_function_id				IN function_course.function_id%TYPE,
	in_status_id				IN course.status_id%TYPE,
	in_provision_id				IN course.provision_id%TYPE,
	in_region_sid				IN course.region_sid%TYPE
)
AS
	v_user_sid	NUMBER(10);
	v_app_sid	NUMBER(10);	
BEGIN
	v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	INSERT INTO temp_user_course_filter
			(
			trainee_sid,
			course_id,
			title
			)
	 SELECT DISTINCT 
			CASE
				WHEN in_user_level = USER_LEVEL_ADMIN THEN v_user_sid -- Hack copied from old code. Pass through a user SID which is not used simply to avoid other code from breaking
				ELSE  ur.child_user_sid
			END,
			c.course_id,
			c.title
	   FROM course c
	   JOIN function_course fc ON fc.course_id = c.course_id
	   JOIN user_function uf ON fc.function_id = uf.function_id
	   JOIN course_schedule cs ON c.course_id = cs.course_id
	   JOIN calendar_event ce ON cs.calendar_event_id = ce.calendar_event_id
	   JOIN course_type ct	ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
	   JOIN user_relationship_type urt ON urt.app_sid = ct.app_sid AND urt.user_relationship_type_id = ct.user_relationship_type_id
	   JOIN user_relationship ur -- Link to line manager
				 ON ur.app_sid = urt.app_sid
				AND ur.user_relationship_type_id = urt.user_relationship_type_id
				AND ur.child_user_sid = uf.csr_user_sid
  LEFT JOIN region_role_member rrm -- Link to training admin role
				 ON rrm.role_sid = role_pkg.GetRoleIdByKey('TRAINING_ADMIN')
				AND rrm.region_sid = c.region_sid
				AND rrm.user_sid = v_user_sid
	  WHERE c.app_sid = v_app_sid
		-- FILTERS
		AND (in_course_type_id IS NULL OR c.course_type_id = in_course_type_id)
		AND (in_function_id IS NULL OR fc.function_id = in_function_id)
		AND (in_status_id IS NULL OR c.status_id = in_status_id)
		AND (in_provision_id IS NULL OR c.provision_id = in_provision_id)
		AND (in_region_sid IS NULL OR c.region_sid IN (
														SELECT region_sid
														  FROM region
													START WITH app_sid = v_app_sid
														   AND region_sid = in_region_sid
											  CONNECT BY PRIOR app_sid = app_sid
												AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
													)
			)
		-- PERMISSIONS
		AND (
				(in_user_level = USER_LEVEL_ADMIN AND rrm.user_sid = v_user_sid)
             OR (in_user_level = USER_LEVEL_MANAGER AND ur.parent_user_sid = v_user_sid)
			 OR (	
					in_user_level = USER_LEVEL_TRAINEE
					AND uf.csr_user_sid = v_user_sid 
					AND training_pkg.UserCourseRegionExists(c.region_sid, uf.csr_user_sid) = 1
                )
			);
END;

PROCEDURE GetUserBookingSummary(
	in_user_sid	IN user_training.user_sid%TYPE,
	out_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		 SELECT fs.flow_state_id,
				fs.label,
				fs.state_colour,
				fs.lookup_key,
				fs.pos,
				COUNT(vf.flow_item_id) Items
		   FROM flow_state fs
		   JOIN flow_state_involvement fsi
					 ON fs.flow_state_id = fsi.flow_state_id
					AND fsi.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE
      LEFT JOIN v$training_flow_item vf
            ON fs.flow_state_id = vf.current_state_id
            AND vf.user_sid = in_user_sid
		  WHERE fs.flow_sid = GetFlowSid
		    AND fs.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED -- Booking can get returned to the initial state but don't include these
			AND fs.is_deleted = 0
	   GROUP BY fs.flow_state_id,
				fs.label,
				fs.state_colour,
				fs.lookup_key,
				fs.pos
	   ORDER BY pos;
END;

PROCEDURE GetAvailableCoursesSummary(
	in_csr_user_sid	IN csr_user.csr_user_sid%TYPE,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	FilterAvailableCourses(
		in_trainee_sid			=> in_csr_user_sid,
		in_open_courses_only	=> 1,
		in_user_level			=> USER_LEVEL_TRAINEE,
		in_training_priority_id	=> null
	);
	
	OPEN out_cur FOR
		 SELECT t.training_priority_id,
				t.label,
				t.pos training_priority_pos,
				COUNT(DISTINCT f.course_id) available_courses
		   FROM training_priority t
	  LEFT JOIN temp_user_course_filter f ON t.training_priority_id = f.training_priority_id
		  WHERE f.flow_item_id IS NULL
	   GROUP BY t.training_priority_id,
				t.label,
				t.pos
	   ORDER BY t.pos;
END;

PROCEDURE GetUserCourses(
	in_csr_user_sid				IN csr_user.csr_user_sid%TYPE,
	in_training_priority_id		IN training_priority.training_priority_id%TYPE,
	in_current_state_id			IN flow_item.current_state_id%TYPE,
	in_course_query				IN NUMBER,
	out_total					OUT SYS_REFCURSOR,
	out_courses_cur				OUT SYS_REFCURSOR,
	out_course_job_function_cur OUT SYS_REFCURSOR,
	out_schedules_cur			OUT SYS_REFCURSOR,
	out_transitions_cur			OUT SYS_REFCURSOR
)
AS
	v_default_state_id flow.default_state_id%TYPE;
BEGIN
	-- Find default state because this represents new available courses
	SELECT default_state_id
	  INTO v_default_state_id
	  FROM flow
	 WHERE flow_sid = GetFlowSid;

	-- If the current state is an initial/available course state then include all available courses
	 
	CASE in_course_query
	   WHEN QUERY_TYPE_BOOKINGS THEN 
			FilterUserBookings(
				in_trainee_sid			=> in_csr_user_sid,
				in_user_level			=> USER_LEVEL_TRAINEE,
				in_flow_state_id		=> in_current_state_id
			);

	   WHEN QUERY_TYPE_AVAILABLE THEN 
			FilterAvailableCourses(
				in_trainee_sid			=> in_csr_user_sid,
				in_open_courses_only	=> 1,
				in_user_level			=> USER_LEVEL_TRAINEE,
				in_training_priority_id	=> in_training_priority_id
			);
	END CASE;

	OPEN out_total FOR
		SELECT COUNT(*) total_results
		  FROM temp_user_course_filter;
	
	-- Courses 
	OPEN out_courses_cur FOR
		 SELECT f.trainee_sid user_sid,
				c.course_id,
				c.title,
				c.description,
				c.course_type_id,
				c.delivery_method_id,
				c.duration,
				c.escalation_notice_period,
				c.expiry_notice_period,
				c.expiry_period,
				c.pass_fail,
				c.provision_id,
				c.reference,
				c.region_sid,
				c.reminder_notice_period,
				c.status_id,
				f.training_priority_id
		   FROM temp_user_course_filter f
		   JOIN course c ON f.course_id = c.course_id
		  WHERE (f.training_priority_id = in_training_priority_id OR in_training_priority_id IS NULL)
	   ORDER BY f.training_priority_pos;
	
	-- Course job functions
	OPEN out_course_job_function_cur FOR
		 SELECT f.course_id,
				fc.training_priority_id,
				tp.pos,
				fc.function_id,
				f.trainee_sid user_sid,
				f.training_priority_pos
		   FROM temp_user_course_filter f
		   JOIN function_course fc ON f.course_id = fc.course_id
		   JOIN user_function u
					 ON fc.function_id = u.function_id
					AND u.csr_user_sid = f.trainee_sid
		   JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
		  WHERE f.training_priority_id = tp.training_priority_id -- If we have filtered on a specific training priority, only return relevant user job functions
	   ORDER BY f.course_id, tp.pos;
	
	-- Schedules
	OPEN out_schedules_cur FOR
		SELECT  f.trainee_sid user_sid,
				c.course_id,
				cs.course_schedule_id,
				cs.max_capacity,
				cs.trainer_id,
				cs.place_id,
				cs.booked,
				cs.available,
				cs.canceled cancelled,
				cs.calendar_event_id,
				ce.start_dtm,
				ce.end_dtm,
				CASE WHEN ce.start_dtm < SYSDATE THEN 1
				ELSE 0
				END date_passed,
				fi.flow_item_id,  -- Or use ut.flow_item_id to control acceptible re-requests?
				NVL(fi.current_state_id, v_default_state_id) current_state_id, -- Return the default state so we can hook in the appropriate transitions
				fi.current_state_label,
				UserCourseRegionExists(f.trainee_sid, c.region_sid) user_course_region_exists -- If course.region_sid or trainee region mount point has changed this may no longer be applicable
		   FROM temp_user_course_filter f
		   JOIN course c ON f.course_id = c.course_id
		   JOIN course_schedule cs ON f.course_id = cs.course_id
		   JOIN calendar_event ce ON cs.calendar_event_id = ce.calendar_event_id
	  LEFT JOIN user_training ut 
					 ON cs.course_schedule_id = ut.course_schedule_id
					AND ut.user_sid = in_csr_user_sid
	  LEFT JOIN v$training_flow_item fi
					 ON ut.flow_item_id = fi.flow_item_id
					AND fi.current_state_id IN ( -- Only show states Trainees can see
												SELECT flow_state_id 
												  FROM flow_state_involvement
												 WHERE flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE
												   AND app_sid = SYS_CONTEXT('security', 'app')
												)
		 WHERE cs.canceled = 0
		   AND (f.training_priority_id = in_training_priority_id OR in_training_priority_id IS NULL)
		   AND (fi.current_state_id = in_current_state_id OR in_current_state_id IS NULL)
		   AND (ut.flow_item_id IS NOT NULL OR in_course_query = QUERY_TYPE_AVAILABLE)			-- Only return booked dates for user bookings, don't return alternative dates
		   AND (in_course_query = QUERY_TYPE_BOOKINGS OR training_pkg.IsBookingOpen(ce.start_dtm, ce.end_dtm, c.delivery_method_id) = 1)					-- Only return future courses for Available Courses query
		 ORDER BY f.course_id, ce.start_dtm;

	GetTraineeFlowTransitions(out_transitions_cur);
END;

PROCEDURE GetUserAvailableCourses(
	in_csr_user_sid				IN csr_user.csr_user_sid%TYPE,
	in_training_priority_id		IN training_priority.training_priority_id%TYPE,
	out_total					OUT SYS_REFCURSOR,
	out_courses_cur				OUT SYS_REFCURSOR,
	out_course_job_function_cur OUT SYS_REFCURSOR,
	out_schedules_cur			OUT SYS_REFCURSOR,
	out_transitions_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	GetUserCourses(in_csr_user_sid, in_training_priority_id, null, QUERY_TYPE_AVAILABLE, out_total, out_courses_cur, out_course_job_function_cur, out_schedules_cur, out_transitions_cur);
END;

PROCEDURE GetUserBookings(
	in_csr_user_sid				IN csr_user.csr_user_sid%TYPE,
	in_current_state_id			IN flow_item.current_state_id%TYPE,
	out_total					OUT SYS_REFCURSOR,
	out_courses_cur				OUT SYS_REFCURSOR,
	out_course_job_function_cur OUT SYS_REFCURSOR,
	out_schedules_cur			OUT SYS_REFCURSOR,
	out_transitions_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	GetUserCourses(in_csr_user_sid, null, in_current_state_id, QUERY_TYPE_BOOKINGS, out_total, out_courses_cur, out_course_job_function_cur, out_schedules_cur, out_transitions_cur);
END;

PROCEDURE GetTraineeFlowStates(
	out_default_state_id	OUT NUMBER,
	out_states_cur 			OUT SYS_REFCURSOR,
	out_transitions_cur		OUT SYS_REFCURSOR
)
AS
	v_flow_sid	flow.flow_sid%TYPE;
BEGIN
	v_flow_sid := GetFlowSid();
	
	IF NOT security_pkg.IsAccessAllowedSID(security.security_pkg.getACT, v_flow_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;	

	SELECT default_state_id
	  INTO out_default_state_id
	  FROM flow
	 WHERE flow_sid = v_flow_sid;
	
	OPEN out_states_cur FOR
		 SELECT fs.flow_state_id,
				fs.label,
				fs.state_colour,
				fs.lookup_key,
				pos, 
				COUNT(fi.flow_item_id) items_in_state
	       FROM flow_state fs
		   JOIN flow_state_involvement fsi
					 ON fs.flow_state_id = fsi.flow_state_id
					AND fsi.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE
	  LEFT JOIN flow_item fi ON current_state_id = fs.flow_state_id
	      WHERE fs.flow_sid = v_flow_sid
		    AND fs.is_deleted = 0
       GROUP BY fs.flow_state_id,
				fs.label,
				fs.state_colour,
				fs.lookup_key,
				pos
	   ORDER BY fs.pos;

	OPEN out_transitions_cur FOR
	 SELECT t.flow_state_transition_id,
			t.owner_can_set,
			t.from_state_id,
			t.to_state_id,
			t.verb,
			t.lookup_key,
			t.ask_for_comment, 
			t.mandatory_fields_message,
			t.hours_before_auto_tran,
			t.button_icon_path,
			t.pos
	   FROM flow_state_transition t
	   JOIN flow_state_transition_inv i 
				 ON i.flow_state_transition_id = t.flow_state_transition_id
				AND i.flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE
	   JOIN flow_state fs
				 ON fs.flow_state_id = t.from_state_id
				AND fs.is_deleted = 0
	  WHERE t.flow_sid = v_flow_sid
   ORDER BY t.from_state_id, t.pos;
END;

/* START: Procs to process course bookings */
PROCEDURE SetUserTrainingState(
	in_user_sid					IN user_training.user_sid%TYPE,
	in_course_schedule_id		IN course_schedule.course_schedule_id%TYPE,
	in_to_state_id				IN flow_state.flow_state_id%TYPE,
	in_reason					IN flow_state_log.comment_text%TYPE
)
AS
	v_flow_item_id				user_training.flow_item_id%TYPE;
	v_current_state_id			flow_state.flow_state_id%TYPE;
	v_flow_state_transition_id	flow_state_transition.flow_state_transition_id%TYPE;
BEGIN
	SELECT v.flow_item_id, DECODE(v.current_state_id, NULL, f.default_state_id, v.current_state_id)
	  INTO v_flow_item_id, v_current_state_id
	  FROM flow f
 LEFT JOIN v$training_flow_item v
			 ON v.flow_sid = f.flow_sid
			AND v.user_sid = in_user_sid
			AND v.course_schedule_id = in_course_schedule_id
	 WHERE f.flow_sid = GetFlowSid;

	SELECT flow_state_transition_id
	  INTO v_flow_state_transition_id
	  FROM flow_state_transition
	 WHERE from_state_id = v_current_state_id
	   AND to_state_id = in_to_state_id;

	SetUserTrainingState(
		in_flow_item_id				=> v_flow_item_id,
		in_user_sid					=> in_user_sid,
		in_course_schedule_id		=> in_course_schedule_id,
		in_flow_state_transition_id	=> v_flow_state_transition_id,
		in_to_state_id				=> in_to_state_id,
		in_reason					=> in_reason
	);
	
END;

PROCEDURE SetUserTrainingState(
	in_flow_item_id				IN user_training.flow_item_id%TYPE,
	in_user_sid					IN user_training.user_sid%TYPE,
	in_course_schedule_id		IN course_schedule.course_schedule_id%TYPE,
	in_flow_state_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE,
	in_to_state_id				IN flow_state.flow_state_id%TYPE,
	in_reason					IN flow_state_log.comment_text%TYPE
)
AS
	v_flow_sid				flow.flow_sid%TYPE := GetFlowSid();
	v_course_id				course.course_id%TYPE;
	v_flow_item_id			user_training.flow_item_id%TYPE;
	v_flow_state_nature_id	flow_state.flow_state_nature_id%TYPE;
BEGIN
	IF NOT HasTransitionPermission(in_user_sid, in_course_schedule_id, in_flow_state_transition_id, in_to_state_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing booking. (item: '||in_flow_item_id || ', to state: ' || in_to_state_id);
	END IF;

	SELECT flow_state_nature_id INTO v_flow_state_nature_id
	  FROM flow_state
	 WHERE flow_state_id = in_to_state_id;
	 
	SELECT course_id
	  INTO v_course_id
	  FROM course_schedule
	 WHERE course_schedule_id = in_course_schedule_id;

	-- If booking is being deleted, shortcut process and remove the booking altogether.
	-- We can only have one user per course schedule.
	IF v_flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_DELETED AND in_flow_item_id IS NOT NULL THEN
		DeleteBooking(
			in_user_sid				=> in_user_sid,
			in_course_id			=> v_course_id,
			in_course_schedule_id	=> in_course_schedule_id,
			in_flow_item_id			=> in_flow_item_id
			);
	ELSE
		BEGIN
			IF in_flow_item_id IS NULL THEN
				flow_pkg.AddFlowItem(v_flow_sid, v_flow_item_id);
				
				INSERT INTO user_training (app_sid, user_sid, course_schedule_id, course_id, flow_item_id)
					 VALUES (SYS_CONTEXT('security', 'app'), in_user_sid, in_course_schedule_id, v_course_id, v_flow_item_id);
			ELSE
				v_flow_item_id := in_flow_item_id;
			END IF;
		
			csr.flow_pkg.SetItemState(
				in_flow_item_id		=> v_flow_item_id,
				in_to_state_id		=> in_to_state_id,
				in_comment_text		=> in_reason,
				in_user_sid			=> SYS_CONTEXT('security', 'sid')
			);
		END;
		
		IF v_flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_POST_ATTENDED THEN
			CheckAutoComplete(v_flow_item_id);
		END IF;
		
	END IF;
END;

/* LEGACY: OLD BOOKING CALLS, CALL SetUserTrainingState DURING CODE MIGRATION */
PROCEDURE AcceptUserTraining(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE
)
AS
	v_current_user_sid		NUMBER(10) := SYS_CONTEXT('security', 'sid');
BEGIN
	SetUserTrainingState(
		in_user_sid				=> in_user_sid,
		in_course_schedule_id	=> in_course_schedule_id,
		in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'CONFIRMED'),
		in_reason				=> NULL
	);
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

PROCEDURE ClearCourseTypeRegions(
	in_course_type_id	IN course_type_region.course_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	DELETE FROM course_type_region
	 WHERE app_sid = security_pkg.GetApp
	   AND course_type_id = in_course_type_id;
END;

PROCEDURE ClearJobFunctionsForCourse(
	in_course_id	IN function_course.course_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	DELETE FROM function_course 
	 WHERE app_sid = security_pkg.GetApp
	   AND course_id = in_course_id;
END;

PROCEDURE CreateUserTraining(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_is_invite			IN 	NUMBER,
	in_comment_text			IN	flow_state_log.comment_text%TYPE
)
AS
	v_to_state_id					flow_state.flow_state_id%TYPE;
	v_current_user_sid				NUMBER(10);
	v_available						NUMBER(5);
BEGIN
	v_current_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	
	-- check if there available spaces
	SELECT available 
	  INTO v_available
	  FROM course_schedule
	 WHERE app_sid = security.security_pkg.GetApp
	   AND course_schedule_id = in_course_schedule_id;
	   
	IF v_available > 0 THEN
		BEGIN
			IF in_is_invite = 1 AND in_user_sid = v_current_user_sid THEN
				v_to_state_id := flow_pkg.GetStateId(GetFlowSid(), 'CONFIRMED');	
			ELSIF in_is_invite = 1 AND in_user_sid <> v_current_user_sid THEN
				v_to_state_id := flow_pkg.GetStateId(GetFlowSid(), 'PRE_INVITED');
			ELSE
				v_to_state_id := flow_pkg.GetStateId(GetFlowSid(), 'PRE_REQUESTED');
			END IF;
			
			SetUserTrainingState(
				in_user_sid				=> in_user_sid,
				in_course_schedule_id	=> in_course_schedule_id,
				in_to_state_id			=> v_to_state_id,
				in_reason				=> null
			);
		END;
	ELSE
		RAISE_APPLICATION_ERROR(ERR_COURSE_FULL, 'There are no more places on this course.');
	END IF;

END;

PROCEDURE DeclineUserTraining(
	in_course_schedule_id		IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid					IN	user_training.user_sid%TYPE,
	in_reason					IN	VARCHAR2
)
AS
	v_current_user_sid			NUMBER(10) := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	SetUserTrainingState(
		in_user_sid				=> in_user_sid,
		in_course_schedule_id	=> in_course_schedule_id,
		in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'PRE_DECLINED'),
		in_reason				=> in_reason
	);
	
--EXCEPTION
--	WHEN NO_DATA_FOUND THEN
--		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

/* END: Procs to process course bookings */

PROCEDURE DeleteCourse(
	in_course_id				IN course.course_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	-- clear associations with job functions first
	DELETE FROM function_course
	 WHERE course_id = in_course_id
	   AND app_sid = security_pkg.GetApp;
	
	-- remove main course record
	DELETE FROM course
	 WHERE course_id = in_course_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteCourseType(
	in_course_type_id	IN course_type.course_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	ClearCourseTypeRegions(in_course_type_id);
	
	DELETE FROM course_type
	 WHERE course_type_id = in_course_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteFunctionCourse(
	in_function_id				IN function_course.function_id%TYPE,
	in_course_id				IN function_course.course_id%TYPE,
	out_alert_details			OUT SYS_REFCURSOR
)
AS
	v_old_training_priority_id	NUMBER(1);
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;

	-- this will send alerts if necessary
	SaveFunctionCourse(in_function_id, in_course_id, null, out_alert_details);

	-- then delete it
	DELETE FROM function_course 
	 WHERE app_sid = security_pkg.GetApp
	   AND course_id = in_course_id
	   AND function_id = in_function_id;
END;

PROCEDURE DeleteSchedule(
	in_course_schedule_id	IN course_schedule.course_schedule_id%TYPE,
	out_alert_details		OUT SYS_REFCURSOR
)
AS
	v_empty_array			security_pkg.T_VARCHAR2_ARRAY;
	v_calendar_event_id		NUMBER(10);
BEGIN
	-- check if user got rights to make the changes
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course schedule') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course schedule" capability');
	END IF;

	-- these users need to be alerted that their course has been cancelled
	OPEN out_alert_details FOR
		SELECT cu1.friendly_name user_friendly_name, cu1.email user_email,
		   cu2.friendly_name manager_friendly_name, cu2.email manager_email,
		   c.title, c.description, c.reference,
		   ce.location, ce.start_dtm, ce.end_dtm
		  FROM course c,
			   csr_user cu1,
			   csr_user cu2,
			   user_relationship ur,
			   course_type ct,
			   course_schedule cs,
			   calendar_event ce
		 WHERE cu1.csr_user_sid IN (
			SELECT ut.user_sid
			  FROM user_training ut
			 WHERE ut.app_sid = security_pkg.GetApp
			   AND ut.course_schedule_id = in_course_schedule_id
			)
		   AND cu1.csr_user_sid = ur.child_user_sid
		   AND cu2.csr_user_sid = ur.parent_user_sid
		   AND ur.user_relationship_type_id = ct.user_relationship_type_id
		   AND ct.course_type_id = c.course_type_id
		   AND c.course_id = cs.course_id
		   AND cs.app_sid = security_pkg.GetApp
		   AND cs.course_schedule_id = in_course_schedule_id
		   AND ce.calendar_event_id = cs.calendar_event_id;

	-- set flow_state to DELETED for all user training
	FOR r IN (
		SELECT flow_item_id
		  FROM user_training
		 WHERE course_schedule_id = in_course_schedule_id
	)
	LOOP
		flow_pkg.SetItemState(
			in_flow_item_id => r.flow_item_id,
			in_to_state_id => flow_pkg.GetStateId(GetFlowSid(), 'DELETED'),
			in_comment_text => '',
			in_cache_keys => v_empty_array,
			in_force => 0
		);
	END LOOP;

	-- remember calendar event id
	SELECT calendar_event_id
	  INTO v_calendar_event_id
	  FROM course_schedule
	 WHERE app_sid = security_pkg.GetApp
	   AND course_schedule_id = in_course_schedule_id;
	
	-- delete schedule
	UPDATE course_schedule
	   SET canceled = 1, available = 0
	 WHERE app_sid = security_pkg.GetApp
	   AND course_schedule_id = in_course_schedule_id;
	   
	-- delete calendar event
	DELETE FROM calendar_event
	 WHERE app_sid = security_pkg.GetApp
	   AND calendar_event_id = v_calendar_event_id;
END;
	
PROCEDURE DeleteTrainer(
	in_trainer_id	IN trainer.trainer_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	-- Todo: Shouldn't be able to delete trainer if they are assigned to a course or schedule
	DELETE FROM trainer
	 WHERE trainer_id = in_trainer_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteUserTraining(
	in_course_schedule_id		IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid					IN	user_training.user_sid%TYPE
)
AS
	v_current_user_sid			NUMBER(10) := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	SetUserTrainingState(
		in_user_sid				=> in_user_sid,
		in_course_schedule_id	=> in_course_schedule_id,
		in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'PRE_DECLINED'),
		in_reason				=> NULL
	);
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

PROCEDURE CancelUserTraining(
	in_course_schedule_id		IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid					IN	user_training.user_sid%TYPE
)
AS
	v_current_user_sid			NUMBER(10) := SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	SetUserTrainingState(
		in_user_sid				=> in_user_sid,
		in_course_schedule_id	=> in_course_schedule_id,
		in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'AVAILABLE'),
		in_reason				=> NULL
	);
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

PROCEDURE GetActiveCourses(
	out_cur OUT SYS_REFCURSOR
)
AS
	v_user_sid NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	
	OPEN out_cur FOR
		SELECT c.course_id, c.title, c.reference, c.description, c.version, c.course_type_id, c.region_sid,
			   c.delivery_method_id, c.provision_id, c.status_id, c.default_trainer_id, c.default_place_id, 
			   c.duration, c.expiry_period, c.expiry_notice_period, c.escalation_notice_period, c.reminder_notice_period,
			   c.pass_score, c.survey_sid, c.quiz_sid, c.pass_fail, c.absolute_deadline,
			   CASE
				  WHEN rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL THEN 1
				  ELSE 0
			   END can_edit
		  FROM course c
		  LEFT JOIN region_role_member rrm
		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE c.app_sid = security_pkg.GetApp
		   AND status_id = 1; --active
END;

-- Only used internally
PROCEDURE GetAlertDetails(
	in_user_sid				IN  NUMBER,
	in_manager_sid			IN  NUMBER,
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	out_alert_details		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_alert_details FOR
		SELECT ut.user_sid, ut.course_schedule_id, ut.flow_item_id,
		       fs.label, fs.lookup_key,
			   cu1.friendly_name user_friendly_name, cu1.email user_email,
			   cu2.friendly_name manager_friendly_name, cu2.email manager_email,
			   c.title, c.description, c.reference,
			   ce.start_dtm, ce.end_dtm, ce.location,
			   p.street_addr1, p.street_addr2, p.town, p.state, p.postcode, p.country_code,
			   (
				-- http://oracle-base.com/articles/misc/string-aggregation-techniques.php
				SELECT LTRIM(MAX(SYS_CONNECT_BY_PATH(label,', '))
					   KEEP (DENSE_RANK LAST ORDER BY curr),', ')
				FROM (
					SELECT csr_user_sid,
						   label,
						   ROW_NUMBER() OVER (PARTITION BY csr_user_sid ORDER BY label) AS curr,
						   ROW_NUMBER() OVER (PARTITION BY csr_user_sid ORDER BY label) -1 AS prev
					FROM (
						SELECT uf.csr_user_sid, uf.function_id, f.label
						FROM user_function uf
						JOIN function f ON f.function_id = uf.function_id 
					)
				)
				GROUP BY csr_user_sid
				CONNECT BY prev = PRIOR curr AND csr_user_sid = PRIOR csr_user_sid
				START WITH curr = 1
				HAVING csr_user_sid = in_user_sid
			   ) AS job_functions
		  FROM user_training ut
		  JOIN csr_user cu1 ON cu1.csr_user_sid = in_user_sid
		  JOIN csr_user cu2 ON cu2.csr_user_sid = in_manager_sid
		  JOIN course_schedule cs ON cs.course_schedule_id = in_course_schedule_id
		  JOIN flow_item fi ON fi.flow_item_id = ut.flow_item_id
		  JOIN flow_state fs ON fs.flow_state_id = fi.current_state_id
		  JOIN course c ON c.course_id = cs.course_id
		  JOIN calendar_event ce ON ce.calendar_event_id = cs.calendar_event_id
          LEFT JOIN place p ON p.place_id = cs.place_id
		  WHERE ut.app_sid = security.security_pkg.GetApp
			AND ut.user_sid = in_user_sid
			AND ut.course_schedule_id = in_course_schedule_id;
END;

PROCEDURE GetAllCourses(
	out_cur OUT SYS_REFCURSOR
)
AS
	v_user_sid NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	
	OPEN out_cur FOR
		SELECT c.course_id, c.title, c.reference, c.description, c.version, c.course_type_id, c.region_sid,
			   c.delivery_method_id, c.provision_id, c.status_id, c.default_trainer_id, c.default_place_id, 
			   c.duration, c.expiry_period, c.expiry_notice_period, c.escalation_notice_period, c.reminder_notice_period,
			   c.pass_score, c.survey_sid, c.quiz_sid, c.pass_fail, c.absolute_deadline,
			   CASE
				   WHEN rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL THEN 1
				   ELSE 0
			   END can_edit
		  FROM course c
		  LEFT JOIN region_role_member rrm
		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE c.app_sid = security_pkg.GetApp;
END;

-- Not currently used
PROCEDURE GetAllItemsWithTransitionsMap(
	in_region_sid			IN	course.region_sid%TYPE,
	out_user_trainings		OUT SYS_REFCURSOR,
	out_states				OUT SYS_REFCURSOR,
	out_transitions 		OUT	SYS_REFCURSOR
)
AS
	v_user_sid	NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, GetFlowSid(), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||GetFlowSid());
	END IF;
	
	OPEN out_user_trainings FOR
		SELECT ut.user_sid, ut.course_schedule_id, ut.flow_item_id, ut.score, u.full_name, 
			fi.current_state_id, cs.course_id, cs.max_capacity, cs.booked, cs.available, ce.start_dtm,
			ce.end_dtm,	c.pass_score, c.title,
			CASE
				WHEN (rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL) OR ur.parent_user_sid IS NOT NULL THEN 1
				ELSE 0
			END can_edit
		  FROM user_training ut
		  JOIN csr_user u ON u.app_sid = ut.app_sid AND u.csr_user_sid = ut.user_sid
		  JOIN flow_item fi ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
		  JOIN flow_state fs ON fs.app_sid = fi.app_sid AND fs.flow_sid = fi.flow_sid AND fs.flow_state_id = fi.current_state_id AND is_deleted = 0
		  JOIN course_schedule cs ON cs.app_sid = ut.app_sid AND cs.course_schedule_id = ut.course_schedule_id AND cs.canceled = 0
		  JOIN calendar_event ce ON cs.app_sid = ce.app_sid AND cs.calendar_event_id = ce.calendar_event_id
		  JOIN course c ON c.app_sid = cs.app_sid AND c.course_id = cs.course_id AND status_id = 1
		  JOIN course_type ct ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
		  LEFT JOIN user_relationship ur ON ur.app_sid = ut.app_sid AND ur.child_user_sid = ut.user_sid AND ur.user_relationship_type_id = ct.user_relationship_type_id AND ur.parent_user_sid =  v_user_sid
		  LEFT JOIN (
			SELECT region_sid, app_sid
			  FROM region
			 START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP 
			   AND region_sid = in_region_sid
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		  ) g ON g.region_sid = c.region_sid
		  LEFT JOIN region_role_member rrm
			JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = g.app_sid AND g.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE ut.app_sid = security_pkg.getApp
		   AND ((rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL)
				OR ur.parent_user_sid IS NOT NULL
				OR ut.user_sid = v_user_sid)
		 ORDER BY ce.start_dtm, c.title, cs.course_schedule_id;
	
	OPEN out_states FOR
		SELECT flow_state_id, label, lookup_key, pos, state_colour, (SELECT COUNT(*)
																	   FROM flow_item
																	  WHERE app_sid = fs.app_sid
																		AND current_state_id = fs.flow_state_id
																		AND flow_sid = fs.flow_sid) items_in_state 
		  FROM flow_state fs
		 WHERE fs.app_sid = security.security_pkg.GetApp
		   AND fs.flow_sid = GetFlowSid()
		   AND fs.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
		 ORDER BY fs.pos, fs.flow_state_id;

	OPEN out_transitions FOR
		SELECT fst.flow_state_transition_id, fst.verb, fst.from_state_id, fst.to_state_id, 
			fst.pos transition_pos, fs_to.label to_state_label, fst.ask_for_comment, fst.button_icon_path,
			fs_to.state_colour to_state_colour,
			CASE
				WHEN fst.lookup_key LIKE 'USER_%' THEN 1
				ELSE 0
			END is_user_transition
		  FROM flow_state_transition fst
		  JOIN flow_state fs_from ON fs_from.app_sid = fst.app_sid AND fs_from.flow_sid = fst.flow_sid AND fs_from.flow_state_id = fst.from_state_id
		  JOIN flow_state fs_to ON fs_to.app_sid = fst.app_sid AND fs_to.flow_sid = fst.flow_sid AND fs_to.flow_state_id = fst.to_state_id
		 WHERE fst.app_sid = security.security_pkg.GetApp
		   AND fst.flow_sid = GetFlowSid()
		   AND fs_from.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
		 ORDER BY fst.pos, fst.flow_state_transition_id;
END;

PROCEDURE GetCalendars(
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT cal.calendar_sid, p.description, p.js_include, p.js_class, /* TEMP: backwards compatibility */p.js_class js_class_type, p.cs_class, cal.applies_to_teamrooms, cal.applies_to_initiatives
		  FROM plugin p
		  JOIN calendar cal ON cal.app_sid = security_pkg.GetApp AND p.plugin_id = cal.plugin_id AND p.plugin_type_id = 12
		  JOIN training_options top ON top.app_sid = cal.app_sid AND top.calendar_sid = cal.calendar_sid
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Calendars'), security_pkg.PERMISSION_READ)) so ON cal.calendar_sid = so.sid_id;
END;

PROCEDURE GetCourse(
	in_course_id	IN course.course_id%TYPE,
	out_cur 		OUT SYS_REFCURSOR
)
AS
	v_user_sid NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	
	OPEN out_cur FOR
		SELECT c.course_id, c.title, c.reference, c.description, c.version, c.course_type_id, c.region_sid,
			   c.delivery_method_id, c.provision_id, c.status_id, c.default_trainer_id, c.default_place_id, 
			   c.duration, c.expiry_period, c.expiry_notice_period, c.escalation_notice_period, c.reminder_notice_period,
			   c.pass_score, c.survey_sid, c.quiz_sid, c.pass_fail, c.absolute_deadline,
			   CASE
				   WHEN rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL THEN 1
				   ELSE 0
			   END can_edit
		  FROM course c
		  LEFT JOIN region_role_member rrm
		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE course_id = in_course_id
		   AND c.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCourseFunctionOptions(
	out_cur_functions 		OUT SYS_REFCURSOR,
	out_cur_courses 		OUT SYS_REFCURSOR,
	out_cur_priorities		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_courses FOR
		SELECT course_id, title, reference, description, version, course_type_id, region_sid,
			delivery_method_id, provision_id, status_id, default_trainer_id, default_place_id,
			duration, expiry_period, expiry_notice_period, escalation_notice_period, reminder_notice_period,
			pass_score, survey_sid, quiz_sid, pass_fail, absolute_deadline
		  FROM course
		 WHERE app_sid = security_pkg.GetApp
		   AND status_id = 1; --active
	
	OPEN out_cur_functions FOR
		SELECT function_id, label
		  FROM function
		 WHERE app_sid = security_pkg.GetApp;
	
	OPEN out_cur_priorities FOR
		SELECT training_priority_id, label
		  FROM training_priority;
END;

PROCEDURE GetCourseOptions(
	out_cur_course_types 		OUT SYS_REFCURSOR,
	out_cur_trainers 			OUT SYS_REFCURSOR,
	out_cur_places 				OUT SYS_REFCURSOR,
	out_cur_jobfunctions 		OUT SYS_REFCURSOR,
	out_cur_provisions 			OUT SYS_REFCURSOR,
	out_cur_statuses 			OUT SYS_REFCURSOR,
	out_cur_delivery_methods 	OUT SYS_REFCURSOR,
	out_cur_priorities			OUT SYS_REFCURSOR
)
AS
	v_user_sid NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
		   
	OPEN out_cur_course_types FOR
		SELECT ct.course_type_id, ct.label,
			  CASE
				WHEN r.course_type_id IS NOT NULL THEN 1
				ELSE 0
			  END can_edit
		  FROM course_type ct
		  LEFT JOIN (
			SELECT DISTINCT app_sid, course_type_id
			  FROM course_type_region ctr
			 WHERE EXISTS(
				SELECT *
				  FROM (
					SELECT r.region_sid, r.app_sid, connect_by_root region_sid root_region_sid
					  FROM region r
					 START WITH r.app_sid = SECURITY.SECURITY_PKG.GETAPP 
					   AND r.region_sid IN (SELECT region_sid 
											  FROM course_type_region)
				   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				) sids
				  JOIN region_role_member rrm ON rrm.app_sid = sids.app_sid AND sids.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
				  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			     WHERE sids.root_region_sid = ctr.region_sid
			)
		  ) r ON r.app_sid = ct.app_sid AND r.course_type_id = ct.course_type_id
		 WHERE ct.app_sid = security_pkg.GetApp;
			
	OPEN out_cur_trainers FOR
		SELECT t.trainer_id,
				CASE
					WHEN name IS NULL AND t.user_sid IS NOT NULL THEN u.full_name
					ELSE t.name
				END	name
		  FROM trainer t
		  LEFT JOIN csr_user u ON u.app_sid = t.app_sid AND u.csr_user_sid = t.user_sid
		 WHERE t.app_sid = security_pkg.GetApp;
			 			
	OPEN out_cur_places FOR
		SELECT p.place_id, p.street_addr1, p.street_addr2, p.town, p.state, p.postcode, p.country_code, p.lat, p.lng, c.name country_name
		  FROM place p
	 LEFT JOIN postcode.country c ON p.country_code = c.country
		 WHERE app_sid = security_pkg.GetApp;
						
	OPEN out_cur_jobfunctions FOR
		SELECT function_id, label
		  FROM function
		 WHERE app_sid = security_pkg.GetApp;
					
	OPEN out_cur_provisions FOR
		SELECT provision_id, label
		  FROM provision;
						
	OPEN out_cur_statuses FOR
		SELECT status_id, label
		  FROM status;
						
	OPEN out_cur_delivery_methods FOR
		SELECT delivery_method_id, label
		  FROM delivery_method;
	
	OPEN out_cur_priorities FOR
		SELECT training_priority_id, label
		  FROM training_priority;
END;

PROCEDURE GetCoursesForDataExport(
	out_curses 			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_curses FOR
		SELECT c.course_id, c.title, c.reference, c.description, c.version, ct.label AS course_type,
				c.region_sid, r.path AS region_description,
				dm.label AS delivery_method, p.label AS provision, s.label AS status,
				c.duration, c.expiry_period, c.expiry_notice_period, c.escalation_notice_period,
				c.reminder_notice_period, c.absolute_deadline,
				CASE
					WHEN c.default_trainer_id IS NOT NULL THEN
						CASE
							WHEN t.name IS NULL AND t.user_sid IS NOT NULL THEN	u.full_name
							WHEN t.name IS NOT NULL AND t.user_sid IS NULL THEN	t.name
							ELSE 'n/a'
						END
					ELSE 'n/a'
				END AS default_trainer,
				CASE
					WHEN c.default_place_id IS NOT NULL THEN
						pl.street_addr1 || 
						CASE 
							WHEN pl.street_addr2 IS NOT NULL THEN ', ' || pl.street_addr2
							ELSE ''
						END ||
						', ' || pl.town ||
						CASE 
							WHEN pl.state IS NOT NULL THEN ', ' || pl.state
							ELSE ''
						END ||
						CASE 
							WHEN pl.postcode IS NOT NULL THEN ', ' || pl.postcode
							ELSE ''
						END ||
						', ' || UPPER(pl.country_code)
					ELSE 'n/a'
				END AS default_place,
				CASE
					WHEN c.pass_fail = 1 THEN 'true'
					ELSE 'false'
				END AS pass_fail
		  FROM course c
		  JOIN course_type ct ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
		  JOIN delivery_method dm ON dm.delivery_method_id = c.delivery_method_id
		  JOIN provision p ON p.provision_id = c.provision_id
		  JOIN status s ON s.status_id = c.status_id
		  JOIN (
			SELECT region_sid, REPLACE(LTRIM(sys_connect_by_path(description, ''),''),'',' > ') path
			  FROM v$region 
			 START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP AND region_sid = (SELECT region_tree_root_sid
																				   FROM region_tree
																				  WHERE IS_PRIMARY = 1)
		   CONNECT BY PRIOR region_sid = parent_sid
		) r ON r.region_sid = c.region_sid
		  LEFT JOIN trainer t ON t.app_sid = c.app_sid AND t.trainer_id = c.default_trainer_id
		  LEFT JOIN csr_user u ON t.app_sid = u.app_sid AND t.user_sid = u.csr_user_sid
		  LEFT JOIN place pl ON pl.app_sid = c.app_sid AND pl.place_id = c.default_place_id
		 WHERE c.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCoursesForGrid(
	in_start_row		IN 	NUMBER,
	in_row_limit		IN 	NUMBER,
	in_sort_by			IN	VARCHAR2,
	in_sort_dir		    IN	VARCHAR2,
	in_search			IN	VARCHAR2,
	in_employee_sid		IN  NUMBER,
	in_course_type_id	IN	course.course_type_id%TYPE,
	in_function_id		IN	function_course.function_id%TYPE,
	in_provision_id		IN	course.provision_id%TYPE,
	in_status_id		IN	course.status_id%TYPE,
	in_region_sid		IN	course.region_sid%TYPE,
	in_user_level		IN	NUMBER,
	in_priority_id		IN	NUMBER,
	out_curses 			OUT SYS_REFCURSOR,
	out_jobFunctions 	OUT SYS_REFCURSOR,
	out_total			OUT SYS_REFCURSOR
)
AS
	v_order_by		VARCHAR2(4000);
	v_user_sid		NUMBER(10);
	v_app_sid		NUMBER(10);
BEGIN
	v_user_sid := SYS_CONTEXT('security', 'sid');
	v_app_sid := SYS_CONTEXT('security', 'app');
		
	v_order_by := 'course_id';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		
		utils_pkg.ValidateOrderBy(v_order_by,  'course_id,title,reference,description,course_type_id,' ||
												'region_sid,delivery_method_id,provision_id,status_id,' ||
												'default_trainer_id,default_place_id,duration,' ||
												'expiry_period,expiry_notice_period,escalation_notice_period,' ||
												'reminder_notice_period,pass_score,survey_sid,quiz_sid,' ||
												'pass_fail,absolute_deadline,region_description,' ||
												'default_trainer_label,default_place_label,course_type_label,' ||
												'delivery_method_label,provision_label,status_label,version');
	END IF;
	
	-- The column names are for convenience only, Oracle processes them in the order they are defined in the table, not by name 
	INSERT INTO temp_course
		SELECT DISTINCT c.app_sid, c.course_id, c.title,
			c.reference, c.description, c.version,
			c.course_type_id, c.region_sid, c.delivery_method_id, c.provision_id,
			c.status_id, c.default_trainer_id, c.default_place_id, c.duration,
			c.expiry_period, c.expiry_notice_period, c.escalation_notice_period,
			c.reminder_notice_period, c.pass_score, c.survey_sid, c.quiz_sid,
			c.pass_fail, c.absolute_deadline, r.path region_description,
			ct.label course_type_label, dm.label delivery_method_label,
			p.label provision_label, s.label status_label,
			CASE
				WHEN c.default_trainer_id IS NOT NULL THEN
					CASE
						WHEN t.name IS NULL AND t.user_sid IS NOT NULL THEN u.full_name
						WHEN t.name IS NOT NULL AND t.user_sid IS NULL THEN t.name
						ELSE 'n/a'
					END
				ELSE 'n/a'
			END default_trainer_label,
			CASE
				WHEN c.default_place_id IS NOT NULL THEN
					pl.street_addr1 ||
					CASE
						WHEN pl.street_addr2 IS NOT NULL THEN ', ' || pl.street_addr2
						ELSE ''
					END || 
					', ' || pl.town || 
					CASE 
						WHEN pl.state IS NOT NULL THEN ', ' || pl.state
						ELSE ''
					END ||
					CASE
						WHEN pl.postcode IS NOT NULL THEN ', ' || pl.postcode
						ELSE ''
					END ||
					', ' || UPPER(pl.country_code)
				ELSE 'n/a'
			END default_place_label,
			CASE
				WHEN rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL THEN 1
				ELSE 0
			END can_edit,
			CASE -- Code Marcin
				WHEN in_user_level = USER_LEVEL_MANAGER THEN ur.child_user_sid
				ELSE v_user_sid
			END user_sid,
			(SELECT u2.full_name
			   FROM csr_user u2
			  WHERE u2.csr_user_sid = (
				CASE
				WHEN in_user_level = USER_LEVEL_MANAGER THEN ur.child_user_sid
				ELSE v_user_sid
				END
			  )
			) user_name,
			(
				SELECT label
				   FROM flow_state fs1
				  WHERE fs1.FLOW_STATE_ID = (
					SELECT fi1.current_state_id
					  FROM flow_item fi1
					 WHERE fi1.flow_item_id = (
						SELECT flow_item_id
						  FROM user_training ut1
						 WHERE ut1.user_sid = uf.csr_user_sid
						   AND ut1.course_schedule_id = (
							SELECT cs1.course_schedule_id
							  FROM course_schedule cs1
							 WHERE cs1.COURSE_ID = c.course_id
							   AND cs1.calendar_event_id = GetLatestCalendarEvent(c.course_id, uf.csr_user_sid)
						)
					)
				)
			) flow_state,
			(
				SELECT cs1.course_schedule_id
				  FROM course_schedule cs1
				 WHERE cs1.COURSE_ID = c.course_id
				   AND cs1.calendar_event_id = GetLatestCalendarEvent(c.course_id, uf.csr_user_sid)
			) schedule_id_for_flow_state

		  FROM course c
		  JOIN course_type ct ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
		  JOIN user_relationship_type urt ON urt.app_sid = ct.app_sid AND urt.user_relationship_type_id = ct.user_relationship_type_id
		  LEFT JOIN user_relationship ur ON ur.app_sid = urt.app_sid AND ur.user_relationship_type_id = urt.user_relationship_type_id AND ur.parent_user_sid = v_user_sid
		  JOIN delivery_method dm ON dm.delivery_method_id = c.delivery_method_id
		  JOIN provision p ON p.provision_id = c.provision_id
		  JOIN status s ON s.status_id = c.status_id
		  LEFT JOIN function_course fc ON fc.app_sid = c.app_sid AND fc.course_id = c.course_id
		  LEFT JOIN user_function uf ON uf.app_sid = fc.app_sid AND uf.function_id = fc.function_id
		  LEFT JOIN trainer t ON t.app_sid = c.app_sid AND t.trainer_id = c.default_trainer_id
		  LEFT JOIN csr_user u ON t.app_sid = u.app_sid AND t.user_sid = u.csr_user_sid
		  LEFT JOIN place pl ON pl.app_sid = c.app_sid AND pl.place_id = c.default_place_id
		  
		  -- create a path for the course group e.g. 'Main > Global > Africa > Kenya'
		  JOIN (
			SELECT region_sid, REPLACE(LTRIM(sys_connect_by_path(description, ''),''),'',' > ') path
			  FROM v$region
			 START WITH app_sid = v_app_sid AND region_sid = (SELECT region_tree_root_sid
																				   FROM region_tree
																				  WHERE app_sid = v_app_sid
																				    AND IS_PRIMARY = 1)
		   CONNECT BY PRIOR region_sid = parent_sid
		  ) r ON r.region_sid = c.region_sid
		  
		 -- check if the user has the training admin role for the region
		 LEFT JOIN region_role_member rrm
			JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
			
		 WHERE c.app_sid = v_app_sid
		   AND (
				in_user_level = USER_LEVEL_ADMIN 
				OR (in_user_level = USER_LEVEL_MANAGER AND UserCourseRegionExists(c.region_sid, ur.child_user_sid) = 1)
				OR (in_user_level = USER_LEVEL_TRAINEE AND UserCourseRegionExists(c.region_sid, uf.csr_user_sid) = 1)
				)
		 -- FILTERS
		   AND (in_search IS NULL
				OR in_search = '' 
				OR UPPER(c.title) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(c.description) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(c.reference) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(TO_CHAR(c.course_id)) = UPPER(in_search)
				OR UPPER(c.version) LIKE '%'||UPPER(in_search)||'%')
		   AND (in_course_type_id IN (-1, 0) OR in_course_type_id = c.course_type_id)
		   AND (in_function_id IN (-1, 0) OR in_function_id = fc.function_id)
		   AND (in_provision_id IN (-1, 0) OR in_provision_id = c.provision_id)
		   AND (in_status_id IN (-1, 0) OR in_status_id = c.status_id)
		   AND (in_region_sid IN (-1, 0, null) OR c.region_sid IN (
																SELECT region_sid
																  FROM region
															START WITH app_sid = SYS_CONTEXT('security', 'app') 
																   AND region_sid = in_region_sid
													  CONNECT BY PRIOR app_sid = app_sid
														AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
															)
				)
		   AND (in_priority_id IN (-1, 0) OR fc.training_priority_id = in_priority_id)
		   -- PERMISSIONS
		   -- Code Marcin
		   -- "My training" page should only show courses for them as a user (in_user_level = 0)
		   -- "Manage schedules" page should only show courses for them as a manager (in_user_level = 1)
		   -- "Manage courses" page should show all courses if they are an admin (in_user_level = 2)
		   AND (
				   (in_user_level = USER_LEVEL_TRAINEE AND uf.csr_user_sid = v_user_sid)
				OR (in_user_level = USER_LEVEL_MANAGER
						AND ur.child_user_sid IS NOT NULL
						AND uf.csr_user_sid = ur.child_user_sid
						AND (in_employee_sid IN (-1,0) OR in_employee_sid = ur.child_user_sid)
				   )
				OR (in_user_level = USER_LEVEL_ADMIN AND rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL)
		   );
			
	OPEN out_total FOR
		SELECT COUNT(*) total_results
		  FROM temp_course;
	
	OPEN out_curses FOR
		' SELECT * ' ||
		  ' FROM ( ' ||
			' SELECT c.*, ' ||
			  ' row_number() over (order by '||v_order_by||', course_id) rn ' ||
			  ' FROM temp_course c ' ||
		  ' ) ' ||
		'  WHERE rn BETWEEN (:1 + 1) AND (:2 + :3) ' ||
		 ' ORDER BY rn'
		USING 	in_start_row, in_start_row, in_row_limit;
			
	OPEN out_jobFunctions FOR
		 SELECT DISTINCT
				fc.course_id,
				fc.function_id,
				fc.training_priority_id,
				CASE -- Code Marcin
					WHEN in_user_level = USER_LEVEL_ADMIN THEN -1 -- Code Marcin: Manage courses screen calls "remove duplicates" which changes all user_sids to -1.
					ELSE uf.csr_user_sid
				END user_sid
		   FROM function_course fc
		   JOIN temp_course tc ON fc.course_id = tc.course_id -- Only bother getting courses in above select
	  LEFT JOIN user_function uf ON uf.function_id = fc.function_id
		  WHERE fc.app_sid = v_app_sid
		    AND (in_user_level > USER_LEVEL_TRAINEE OR uf.csr_user_sid = v_user_sid)
	   ORDER BY course_id, function_id;
END;

PROCEDURE GetCoursesForJobFunction(
	in_function_id	IN function_course.function_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	OPEN out_cur FOR
		SELECT fc.function_id, fc.course_id, fc.training_priority_id
		  FROM function_course fc
		  JOIN course c ON c.app_sid = security_pkg.GetApp AND c.course_id = fc.course_id AND c.status_id = 1 --active
		 WHERE function_id = in_function_id
		   AND fc.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCourseTypeOptions(
	out_cur_relationships 		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_relationships FOR
		SELECT user_relationship_type_id, label
		  FROM user_relationship_type
		 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCourseTypes(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT course_type_id, label, user_relationship_type_id
		  FROM course_type
		 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE GetCourseTypesWithRegions(
	out_course_types 			OUT SYS_REFCURSOR,
	out_course_type_regions 	OUT SYS_REFCURSOR
)
AS
BEGIN
	GetCourseTypes(out_course_types);
	
	OPEN out_course_type_regions FOR
		SELECT ctr.course_type_id, r.region_sid, r.description
		  FROM course_type_region ctr
		  JOIN v$region r ON r.app_sid = ctr.app_sid AND r.region_sid = ctr.region_sid
		 WHERE ctr.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetExpiryReminders(
    out_cur    OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT employee, manager, course_id, expiry_period
		  FROM (
			SELECT ut.user_sid employee, 'manager_sid' manager, c.course_id,
				   ce.END_DTM, c.EXPIRY_PERIOD, c.EXPIRY_NOTICE_PERIOD
			  FROM user_training ut
			  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
			  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
			  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
			  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
			  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
			 WHERE fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
			   AND ut.app_sid = security.security_pkg.GetApp
			   AND c.EXPIRY_PERIOD > 0
		  ) r
		WHERE r.END_DTM = (
			-- only use the most recent time they attended this course
			SELECT MAX(end_dtm)
			  FROM (
				SELECT ut.user_sid employee, c.course_id, ce.END_DTM
				  FROM user_training ut
				  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
				  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
				  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
				  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
				  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
				 WHERE fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
				   AND ut.app_sid = security.security_pkg.GetApp
				   AND c.EXPIRY_PERIOD > 0
			  ) r2
			WHERE r2.employee = r.employee
			AND r2.course_id = r.course_id
		)
		AND ADD_MONTHS(TRUNC(r.END_DTM), r.EXPIRY_PERIOD) - r.EXPIRY_NOTICE_PERIOD = TRUNC(SYSDATE);
END;

PROCEDURE GetFlowItemsForSchedule(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	out_user_trainings		OUT	SYS_REFCURSOR,
	out_states 				OUT	SYS_REFCURSOR,
	out_transitions			OUT	SYS_REFCURSOR,
	out_users				OUT SYS_REFCURSOR
)
AS
	v_now		DATE;
	v_user_sid	NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	v_now := SYSDATE;
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, GetFlowSid(), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||GetFlowSid());
	END IF;

	OPEN out_user_trainings FOR
		SELECT ut.user_sid, ut.course_schedule_id, ut.flow_item_id, ut.score, u.full_name, 
			fi.current_state_id, cs.course_id, cs.max_capacity, cs.booked, cs.available, ce.start_dtm,
			ce.end_dtm,	c.pass_score, c.title,
			CASE
				WHEN (rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL) OR ur.parent_user_sid IS NOT NULL THEN 1
				ELSE 0
			END can_edit
		  FROM user_training ut
		  JOIN csr_user u ON u.app_sid = ut.app_sid AND u.csr_user_sid = ut.user_sid
		  JOIN flow_item fi ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
		  JOIN flow_state fs ON fs.app_sid = fi.app_sid AND fs.flow_sid = fi.flow_sid AND fs.flow_state_id = fi.current_state_id AND is_deleted = 0
		  JOIN course_schedule cs ON cs.app_sid = ut.app_sid AND cs.course_schedule_id = ut.course_schedule_id AND cs.canceled = 0
		  JOIN calendar_event ce ON cs.app_sid = ce.app_sid AND cs.calendar_event_id = ce.calendar_event_id
		  JOIN course c ON c.app_sid = cs.app_sid AND c.course_id = cs.course_id AND status_id = 1
		  JOIN course_type ct ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
		  LEFT JOIN user_relationship ur ON ur.app_sid = ut.app_sid AND ur.child_user_sid = ut.user_sid AND ur.user_relationship_type_id = ct.user_relationship_type_id AND ur.parent_user_sid =  v_user_sid
		  LEFT JOIN region_role_member rrm
			JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE ut.app_sid = security_pkg.getApp
		   AND ut.course_schedule_id = in_course_schedule_id
		   AND ((rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL)
				OR ur.parent_user_sid IS NOT NULL
				OR ut.user_sid = v_user_sid)
		 ORDER BY u.full_name;
	
	-- get all states that apply to course schedule
	-- only show UNAPPROVED and CONFIRMED states when the course schedule hasn't yet started
	-- and POST_ATTENDED and CONFIRMED when the course already started
	OPEN out_states FOR
		SELECT fs.flow_state_id, fs.label, fs.lookup_key, fs.pos, fs.state_colour, 
			(SELECT COUNT(*)
			   FROM flow_item
			  WHERE app_sid = fs.app_sid
				AND current_state_id = fs.flow_state_id
				AND flow_sid = fs.flow_sid) items_in_state
		  FROM flow_state fs
		  JOIN flow_item fi ON fi.app_sid = fs.app_sid AND fi.flow_sid = fs.flow_sid
		  JOIN user_training ut ON ut.app_sid = fi.app_sid AND ut.flow_item_id = fi.flow_item_id
		  JOIN course_schedule cs ON cs.app_sid = ut.app_sid AND cs.course_schedule_id = ut.course_schedule_id AND cs.course_schedule_id = in_course_schedule_id
		  JOIN calendar_event ce ON cs.app_sid = ce.app_sid AND cs.calendar_event_id = ce.calendar_event_id
		 WHERE fs.app_sid = security.security_pkg.GetApp
		   AND fs.flow_sid = GetFlowSid()
		   AND fs.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
		   AND (ce.start_dtm > v_now AND fs.flow_state_nature_id NOT IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
				OR ce.start_dtm <= v_now AND fs.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNAPPROVED)
		 ORDER BY fs.pos, fs.flow_state_id;
	
	-- get all transitions for the flow
	-- we can filter them in UI by mapping to the current state of each flow item
	OPEN out_transitions FOR
		SELECT fst.flow_state_transition_id, fst.verb, fst.from_state_id, fst.to_state_id, 
			fst.pos transition_pos, fs_to.label to_state_label, fst.ask_for_comment, fst.button_icon_path,
			fs_to.state_colour to_state_colour,
			CASE
				WHEN fst.lookup_key LIKE 'USER_%' THEN 1
				ELSE 0
			END is_user_transition
		  FROM flow_state_transition fst
		  JOIN flow_state fs_from ON fs_from.app_sid = fst.app_sid AND fs_from.flow_sid = fst.flow_sid AND fs_from.flow_state_id = fst.from_state_id
		  JOIN flow_state fs_to ON fs_to.app_sid = fst.app_sid AND fs_to.flow_sid = fst.flow_sid AND fs_to.flow_state_id = fst.to_state_id
		 WHERE fst.app_sid = security.security_pkg.GetApp
		   AND fst.flow_sid = GetFlowSid()
		   AND fs_from.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
		 ORDER BY fst.pos, fst.flow_state_transition_id;
	
	OPEN out_users FOR
		SELECT DISTINCT u.csr_user_sid, u.full_name 
		  FROM csr_user u
		  JOIN user_function uf ON uf.app_sid = u.app_sid AND uf.csr_user_sid = u.csr_user_sid
		  JOIN function_course fc ON fc.app_sid = uf.app_sid AND fc.function_id = uf.function_id
		  JOIN course c ON c.app_sid = fc.app_sid AND c.course_id = fc.course_id
		  JOIN course_type ct ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id      
		  JOIN course_schedule cs ON cs.app_sid = c.app_sid AND cs.course_id = c.course_id AND cs.course_schedule_id = in_course_schedule_id
		  LEFT JOIN user_relationship ur ON ur.app_sid = u.app_sid AND ur.user_relationship_type_id = ct.user_relationship_type_id AND ur.child_user_sid = u.csr_user_sid  AND ur.parent_user_sid = v_user_sid
		  LEFT JOIN region_role_member rrm
		  JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
		    ON rrm.app_sid = c.app_sid AND c.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid
		 WHERE u.app_sid = security.security_pkg.GetApp
		   AND EXISTS (
			  SELECT region_sid
				FROM region
			   WHERE region_sid = c.region_sid
			   START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = u.csr_user_sid)
			 CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		   )
		   AND ((rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL)
				OR ur.parent_user_sid IS NOT NULL
				OR u.csr_user_sid = v_user_sid);
END;

PROCEDURE GetJobFunctionsForCourse(
	in_course_id	IN course.course_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT fc.function_id, fc.training_priority_id, f.label AS function_label, tp.label AS priority_label
		  FROM function_course fc
		  JOIN function f ON f.app_sid = security_pkg.GetApp AND f.function_id = fc.function_id
		  JOIN training_priority tp ON tp.training_priority_id = fc.training_priority_id
		 WHERE course_id = in_course_id
		   AND fc.app_sid = security_pkg.GetApp;
END;

FUNCTION GetLatestCalendarEvent(
	in_course_id	NUMBER,
	in_user_id		NUMBER
) RETURN NUMBER
AS
	v_calendar_event_id NUMBER(10);
BEGIN
	SELECT MAX(CALENDAR_EVENT_ID)
	  INTO v_calendar_event_id
	  FROM (
		SELECT ce.CALENDAR_EVENT_ID, ce.start_dtm, max(ce.start_dtm) over (partition by cs.course_id) latest_date
		  FROM course_schedule cs
		  JOIN calendar_event ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
		  JOIN user_training ut ON ut.COURSE_SCHEDULE_ID = cs.COURSE_SCHEDULE_ID
		 WHERE cs.COURSE_ID = in_course_id
		   AND ut.USER_SID = in_user_id
	)
	 WHERE start_dtm = latest_date;
	 
	 RETURN v_calendar_event_id;
END;

FUNCTION GetLatestCompleteCalendarEvent(
	in_course_id	NUMBER,
	in_user_id		NUMBER
) RETURN NUMBER
AS
	v_calendar_event_id NUMBER(10);
BEGIN
	SELECT calendar_event_id 
	  INTO v_calendar_event_id
	  FROM (
		SELECT ce.start_dtm, ce.CALENDAR_EVENT_ID
		  FROM USER_TRAINING ut
		  JOIN FLOW_ITEM fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID 
		  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
		  JOIN COURSE_SCHEDULE cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
		  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
		 WHERE ut.USER_SID = in_user_id AND cs.course_id = in_course_id
		   AND fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
		)
	 WHERE start_dtm = (
		SELECT MAX(start_dtm)
		  FROM (
			SELECT ce.start_dtm, ce.CALENDAR_EVENT_ID
			  FROM CSR.USER_TRAINING ut
			  JOIN FLOW_ITEM fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID 
			  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
			  JOIN COURSE_SCHEDULE cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
			  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
			 WHERE ut.USER_SID = in_user_id AND cs.course_id = in_course_id
			   AND fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
			)
		);

	RETURN v_calendar_event_id;
END;

/* TODO: FIND OUT IF THIS IS ACTUALLY USED? Called from courseRequests.ashx GetManagedUsersForSchedule but doesn't seem to be used in the page */
PROCEDURE GetManagedUsersForSchedule(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	out_managed_users		OUT SYS_REFCURSOR
)
AS
	v_user_sid			NUMBER(10);
	v_app_sid			NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	v_app_sid := SECURITY.SECURITY_PKG.GetAPP;

	OPEN out_managed_users FOR
		SELECT DISTINCT u.csr_user_sid, u.full_name
		  FROM csr_user u
		  JOIN user_function uf		ON uf.app_sid = v_app_sid AND uf.csr_user_sid = u.csr_user_sid
		  JOIN function_course fc	ON fc.app_sid = v_app_sid AND fc.function_id = uf.function_id
		  JOIN course c				ON c.app_sid = v_app_sid  AND c.course_id = fc.course_id
		  JOIN course_type ct 		ON ct.app_sid = v_app_sid AND ct.course_type_id = c.course_type_id
		  JOIN user_relationship ur
					 ON ur.app_sid = v_app_sid
					AND ur.user_relationship_type_id = ct.user_relationship_type_id
					AND ur.child_user_sid = u.csr_user_sid
					AND ur.parent_user_sid = SYS_CONTEXT('SECURITY', 'SID') -- CURRENT LOGGED IN USER
		  JOIN course_schedule cs	ON cs.app_sid = v_app_sid AND cs.course_id = c.course_id
         WHERE u.app_sid = v_app_sid
           AND c.region_sid IN (
			SELECT region_sid
			  FROM region
			 START WITH app_sid = v_app_sid
			   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = u.csr_user_sid)
			 CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		   );
END;

PROCEDURE GetManagerEscalationReminders(
    out_cur    OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, employee, manager, course_id, expiry_period FROM
		(
			SELECT ut.app_sid, ut.user_sid employee, 'manager_sid' manager, c.course_id,
				   ce.END_DTM, c.EXPIRY_PERIOD, c.EXPIRY_NOTICE_PERIOD, c.ESCALATION_NOTICE_PERIOD
			  FROM user_training ut
			  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
			  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
			  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
			  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
			  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
			 WHERE fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
			   AND c.EXPIRY_PERIOD > 0
		) r
		WHERE r.END_DTM = (
			-- only use the most recent time they attended this course
			SELECT MAX(end_dtm)
			FROM (
			SELECT ut.user_sid employee, c.course_id, ce.END_DTM, ut.app_sid
			  FROM user_training ut
			  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
			  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
			  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
			  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
			  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
			 WHERE fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
			   AND c.EXPIRY_PERIOD > 0
			) r2
			WHERE r2.employee = r.employee
			AND r2.course_id = r.course_id
			AND r2.app_sid = r.app_sid
		)
		AND ADD_MONTHS(TRUNC(r.END_DTM), r.EXPIRY_PERIOD) - r.ESCALATION_NOTICE_PERIOD = TRUNC(SYSDATE);
END;

PROCEDURE GetRegionsForCourseType(
	in_course_type_id	IN	course_type.course_type_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_user_sid		NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	
	OPEN out_cur FOR
		SELECT descriptions.region_sid, descriptions.path description,
			CASE
				WHEN rrm.user_sid IS NOT NULL AND r.role_sid IS NOT NULL THEN 1
				ELSE 0
			END can_edit
		  FROM (
			SELECT app_sid, region_sid, REPLACE(LTRIM(sys_connect_by_path(description, ''),''),'',' > ') path
			  FROM v$region 
			 START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP AND region_sid = (SELECT region_tree_root_sid
																				   FROM region_tree
																				  WHERE IS_PRIMARY = 1)
			 CONNECT BY PRIOR region_sid = parent_sid
		  ) descriptions
		  JOIN (
			SELECT region_sid
			  FROM region
			 START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP 
			   AND region_sid IN (SELECT region_sid
									FROM COURSE_TYPE_REGION
								   WHERE APP_SID = SECURITY.SECURITY_PKG.GETAPP
									 AND COURSE_TYPE_ID = in_course_type_id)
		   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		  ) sids ON sids.region_sid = descriptions.region_sid
		  LEFT JOIN region_role_member rrm
			JOIN role r ON r.app_sid = rrm.app_sid AND r.role_sid = rrm.role_sid AND r.lookup_key = 'TRAINING_ADMIN'
			ON rrm.app_sid = descriptions.app_sid AND descriptions.region_sid = rrm.region_sid AND rrm.user_sid = v_user_sid; 
END;

PROCEDURE GetSchedulesForDataExport(
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_search				IN	VARCHAR2,
	in_employee_sid			IN  NUMBER,
	in_course_type_id		IN	course.course_type_id%TYPE,
	in_function_id			IN	function_course.function_id%TYPE,
	in_provision_id			IN	course.provision_id%TYPE,
	in_status_id			IN	course.status_id%TYPE,
	in_region_sid			IN	course.region_sid%TYPE,
	in_from_dtm				IN	calendar_event.start_dtm%TYPE,
	in_to_dtm				IN	calendar_event.end_dtm%TYPE,
	in_show_full			IN	NUMBER,
	in_show_available		IN	NUMBER,
	in_course_id			IN  VARCHAR2,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_user_level			IN	NUMBER, -- 0 = user, 1 = manager, 2 = admin
	out_course_schedules	OUT SYS_REFCURSOR
)
AS
	v_out_total				SYS_REFCURSOR;
	v_out_courses 			SYS_REFCURSOR;
	v_out_job_functions		SYS_REFCURSOR;
BEGIN
	GetSchedulesForGrid(
		in_start_row,
		in_row_limit,
		in_sort_by,
		in_sort_dir,
		in_search,
		in_employee_sid,
		in_course_type_id,
		in_function_id,
		in_provision_id,
		in_status_id,
		in_region_sid,
		in_from_dtm,
		in_to_dtm,
		in_show_full,
		in_show_available,
		in_course_id,
		in_flow_state_nature_id,
		in_user_level,
		v_out_total,
		out_course_schedules,
		v_out_courses,
		v_out_job_functions);
END;

-- Only used internally
PROCEDURE GetTraineeSchedules(
	in_trainee_sid			IN  NUMBER,
	in_course_schedule_id	IN	NUMBER,
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_search				IN	VARCHAR2,
	in_course_type_id		IN	course.course_type_id%TYPE,
	in_function_id			IN	function_course.function_id%TYPE,
	in_provision_id			IN	course.provision_id%TYPE,
	in_status_id			IN	course.status_id%TYPE,
	in_region_sid			IN	course.region_sid%TYPE,
	in_from_dtm				IN	calendar_event.start_dtm%TYPE,
	in_to_dtm				IN	calendar_event.end_dtm%TYPE,
	in_show_full			IN	NUMBER,
	in_query_type			IN	NUMBER,
	in_course_id			IN	VARCHAR2,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_user_level			IN	NUMBER,
	in_admin				IN	NUMBER,
	v_out_schedules			OUT	SYS_REFCURSOR
)
AS
	v_region_sids			security.T_SID_TABLE;
	v_user_sid				NUMBER(10);
	v_involvement_type_id	NUMBER(10);
BEGIN
	v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	
	-- Trainees cannot search for other trainee course bookings
	IF in_user_level = USER_LEVEL_TRAINEE AND in_trainee_sid IS NOT NULL AND in_trainee_sid <> v_user_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Trainees cannot search for other trainee course bookings (Logged in: ' || TO_CHAR(v_user_sid) || ', in_trainee_sid: ' || TO_CHAR(in_trainee_sid));
	END IF;

	CASE in_query_type
		WHEN QUERY_TYPE_AVAILABLE THEN
			FilterAvailableCourses(
				in_trainee_sid				=> DecodeNull(in_trainee_sid),
				in_open_courses_only		=> 0, -- We'll do our own filtering
				in_user_level				=> in_user_level,
				in_training_priority_id		=> null,
				in_course_type_id			=> DecodeNull(in_course_type_id),
				in_function_id				=> DecodeNull(in_function_id),
				in_status_id				=> DecodeNull(in_status_id),
				in_provision_id				=> DecodeNull(in_provision_id),
				in_region_sid				=> DecodeNull(in_region_sid)
			);			
		WHEN QUERY_TYPE_BOOKINGS THEN
			FilterUserBookings(
				in_trainee_sid			=> DecodeNull(in_trainee_sid),
				in_user_level			=> in_user_level,
				in_flow_state_id		=> null,
				in_flow_state_nature_id	=> DecodeNull(in_flow_state_nature_id),
				in_course_type_id		=> DecodeNull(in_course_type_id),
				in_function_id			=> DecodeNull(in_function_id),
				in_provision_id			=> DecodeNull(in_provision_id),
				in_status_id			=> DecodeNull(in_status_id),
				in_region_sid			=> DecodeNull(in_region_sid)
			);
		WHEN QUERY_TYPE_ALL_SCHEDULES THEN
			/*
				This is only here because the of a fudge to use this proc on "Course Schedules" Admin screen which has nothing to do with bookings or availability
				It's really doing a completely different query so it shouldn't share this functionality. Leave it here until we ditch the old screens
			*/
			FilterAllSchedules(
				in_user_level			=> in_user_level,
				in_course_type_id		=> DecodeNull(in_course_type_id),
				in_function_id			=> DecodeNull(in_function_id),
				in_status_id			=> DecodeNull(in_status_id),
				in_provision_id			=> DecodeNull(in_provision_id),
				in_region_sid			=> DecodeNull(in_region_sid)
			);
	END CASE;

	-- The columns must be in the same order they are defined in temp_course_schedule (see GetSchedulesForGrid)
	-- Column names are for convenience only, Oracle ignores them
	OPEN v_out_schedules FOR
		SELECT DISTINCT cs.app_sid, cs.course_schedule_id, cs.course_id, cs.max_capacity, cs.booked, cs.available,
			cs.canceled, cs.trainer_id, cs.place_id, ce.calendar_event_id, ce.start_dtm, ce.end_dtm,
			ce.created_by_sid, ce.created_dtm, ce.location, c.title, c.reference, c.description,
			c.version, c.course_type_id, c.region_sid, c.delivery_method_id, c.provision_id, c.status_id, c.default_trainer_id,
			c.default_place_id, c.duration, c.expiry_period, c.expiry_notice_period,
			c.escalation_notice_period, c.reminder_notice_period, c.pass_score, c.survey_sid,
			c.quiz_sid, c.pass_fail,
			c.absolute_deadline,
			r.path region_description,
			ct.label course_type_label,
			dm.label delivery_method_label,
			p.label provision_label,
			s.label status_label,
			CASE
				WHEN c.default_trainer_id IS NULL THEN 'n/a'
				WHEN t.name IS NULL AND t.user_sid IS NOT NULL THEN u.full_name
				WHEN t.name IS NOT NULL AND t.user_sid IS NULL THEN t.name
				ELSE 'n/a'
			END default_trainer_label,
			CASE
				WHEN c.default_place_id IS NOT NULL THEN
					pl.street_addr1 ||
					CASE
						WHEN pl.street_addr2 IS NOT NULL THEN ', ' || pl.street_addr2
						ELSE ''
					END || 
					', ' || pl.town || 
					CASE 
						WHEN pl.state IS NOT NULL THEN ', ' || pl.state
						ELSE ''
					END ||
					CASE
						WHEN pl.postcode IS NOT NULL THEN ', ' || pl.postcode
						ELSE ''
					END ||
					', ' || UPPER(pl.country_code)
				ELSE 'n/a'
			END default_place_label,
			CASE
				WHEN rrm.user_sid IS NOT NULL
				 AND ce.start_dtm > SYSDATE
				THEN 1
				ELSE 0
			END can_edit,
			CASE  -- Legacy code that should be changed.
				WHEN (fs.lookup_key IS NULL OR fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_UNSCHEDULED, csr_data_pkg.NATURE_TRAINING_DELETED)) AND ce.start_dtm > SYSDATE THEN 
						'Available'
                WHEN (fs.lookup_key IS NULL
					OR (fs.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_POST_ATTENDED AND fs.lookup_key != 'PRE_DECLINED'))
					AND ce.start_dtm < SYSDATE THEN 
						'Date passed'
				ELSE fs.label
			END user_current_state,
			ucf.trainee_sid user_sid,
			(SELECT u2.full_name
			   FROM csr_user u2
			  WHERE u2.csr_user_sid = ucf.trainee_sid
			) user_name,
			CASE
				WHEN in_admin = 1 THEN cs.attendance_password
				ELSE ''
			END attendance_password -- don't return password unless admin

		  FROM temp_user_course_filter ucf
		  JOIN course c 					ON ucf.course_id = c.course_id
		  JOIN course_schedule cs			ON c.course_id = cs.course_id AND c.app_sid = cs.app_sid
		  JOIN calendar_event ce 			ON cs.app_sid = ce.app_sid AND cs.calendar_event_id = ce.calendar_event_id
		  JOIN course_type ct				ON ct.app_sid = c.app_sid AND ct.course_type_id = c.course_type_id
		  JOIN delivery_method dm 			ON dm.delivery_method_id = c.delivery_method_id
		  JOIN provision p 					ON p.provision_id = c.provision_id
		  JOIN status s 					ON s.status_id = c.status_id
		  LEFT JOIN function_course fc 		ON fc.app_sid = c.app_sid AND fc.course_id = c.course_id
		  LEFT JOIN user_function uf 		ON uf.app_sid = fc.app_sid AND uf.function_id = fc.function_id AND uf.csr_user_sid = ucf.trainee_sid
		  LEFT JOIN trainer t 				ON t.app_sid = cs.app_sid AND t.trainer_id = cs.trainer_id
		  LEFT JOIN csr_user u 				ON t.app_sid = u.app_sid AND t.user_sid = u.csr_user_sid
		  LEFT JOIN place pl 				ON pl.app_sid = cs.app_sid AND pl.place_id = cs.place_id
		  LEFT JOIN user_training ut 		ON ut.app_sid = cs.app_sid AND ut.user_sid = ucf.trainee_sid AND ut.course_schedule_id = cs.course_schedule_id
		  LEFT JOIN flow_item fi 			ON fi.flow_item_id = ut.flow_item_id
		  LEFT JOIN flow_state fs 			ON fs.flow_state_id = fi.current_state_id

		  JOIN ( -- This is purely to get the region path. TODO: move to function
			SELECT region_sid, REPLACE(LTRIM(sys_connect_by_path(description, ''),''),'',' > ') path
			  FROM v$region
			 START WITH app_sid = SECURITY.SECURITY_PKG.GETAPP AND region_sid = (SELECT region_tree_root_sid
																				   FROM region_tree
																				  WHERE app_sid = SECURITY.SECURITY_PKG.GETAPP
																				    AND IS_PRIMARY = 1)
		   CONNECT BY PRIOR region_sid = parent_sid
		  ) r ON r.region_sid = c.region_sid
		  
		  
		  LEFT JOIN region_role_member rrm 			-- RRM. DOES THIS USER HAVE "TRAINING ADMIN" ROLE MEMBERSHIP FOR THIS REGION
					ON rrm.app_sid = c.app_sid 
					AND rrm.role_sid = role_pkg.GetRoleIdByKey('TRAINING_ADMIN')
					AND rrm.region_sid = c.region_sid
					AND rrm.user_sid = v_user_sid

		  LEFT JOIN user_relationship ur			-- UR. LINK TO LINE MANAGER
					ON ct.user_relationship_type_id = ur.user_relationship_type_id
					AND ur.child_user_sid = ucf.trainee_sid
					AND ur.parent_user_sid = v_user_sid
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cs.canceled = 0
		 
		 -- PERMISSIONS - CHRIS - I think this is covered by the filtering above. Once screens all work, try removing AND () below.
		   AND (
				-- the user is an admin and we want all schedules (i.e. the "manage schedules" page)
				(in_admin = 1 AND rrm.user_sid IS NOT NULL)
				-- or the user has a job function associated with that course
				OR (
						(in_user_level = USER_LEVEL_TRAINEE AND ucf.trainee_sid = v_user_sid) -- User = trainee
						OR
						(in_user_level = USER_LEVEL_MANAGER AND ur.parent_user_sid = v_user_sid) -- User = line manager (uf.csr_user_sid IS NOT NULL ??)
					)
				)
		 -- FILTERS - These are already take care of in temp_user_course_filter: in_flow_state_nature_id, in_course_type_id, in_function_id, in_provision_id, in_status_id, in_region_sid		 
		   AND (in_course_schedule_id IN (NULL, 0, -1) OR cs.course_schedule_id = in_course_schedule_id)
		   AND (in_from_dtm IS NULL OR ce.start_dtm >= in_from_dtm)
		   AND (in_to_dtm IS NULL OR ce.start_dtm <= in_to_dtm)
		   AND (in_show_full = 1 OR cs.available > 0)
		   AND (in_search IS NULL
				OR in_search = '' 
				OR UPPER(c.title) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(c.description) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(c.reference) LIKE '%'||UPPER(in_search)||'%'
				OR UPPER(TO_CHAR(c.course_id)) = UPPER(in_search)
				OR UPPER(c.version) LIKE '%'||UPPER(in_search)||'%')
		   AND (in_function_id IN (-1, 0) OR in_function_id = fc.function_id)
		   AND (in_course_id IS NULL OR c.course_id = in_course_id)
		   AND (in_flow_state_nature_id IS NULL OR fs.flow_state_nature_id = in_flow_state_nature_id);
		   
END;

PROCEDURE GetSchedulesForGrid(
	in_start_row			IN 	NUMBER,
	in_row_limit			IN 	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir		    	IN	VARCHAR2,
	in_search				IN	VARCHAR2,
	in_employee_sid			IN  NUMBER,
	in_course_type_id		IN	course.course_type_id%TYPE,
	in_function_id			IN	function_course.function_id%TYPE,
	in_provision_id			IN	course.provision_id%TYPE,
	in_status_id			IN	course.status_id%TYPE,
	in_region_sid			IN	course.region_sid%TYPE,
	in_from_dtm				IN	calendar_event.start_dtm%TYPE,
	in_to_dtm				IN	calendar_event.end_dtm%TYPE,
	in_show_full			IN	NUMBER,
	in_query_type			IN	NUMBER,
	in_course_id			IN	VARCHAR2,
	in_flow_state_nature_id	IN	flow_state.flow_state_nature_id%TYPE,
	in_user_level			IN	NUMBER, -- 0 = user, 1 = manager, 2 = admin
	out_total				OUT SYS_REFCURSOR,
	out_course_schedules	OUT SYS_REFCURSOR,
	out_courses 			OUT SYS_REFCURSOR,
	out_job_functions 		OUT SYS_REFCURSOR
)
AS
	v_order_by				VARCHAR2(4000);
	v_temp_course_schedule	SYS_REFCURSOR;
	v_record				temp_course_schedule%ROWTYPE;
	v_admin					NUMBER(1);
	v_user_sid				NUMBER(10);
BEGIN
	v_user_sid := SYS_CONTEXT('SECURITY', 'SID');
	
	-- make sure search period is set
	IF in_from_dtm IS NULL OR in_to_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_PERIOD_UNRECOGNISED, 'From and To dates need to be specified');
	END IF;
	
	-- check if valid order by column
	v_order_by := 'course_id';
	IF in_sort_by IS NOT NULL THEN 
		v_order_by := in_sort_by;
		
		IF in_sort_dir IS NOT NULL THEN
			v_order_by := v_order_by || ' '	|| in_sort_dir;
		END IF;
		
		utils_pkg.ValidateOrderBy(v_order_by,  'course_schedule_id,calendar_event_id,max_capacity,booked,' ||
												'available,canceled,course_id,title,reference,description,' ||
												'expiry_period,expiry_notice_period,escalation_notice_period,' ||
												'reminder_notice_period,pass_score,survey_sid,quiz_sid,' ||
												'duration,pass_fail,absolute_deadline,region_description,' ||
												'trainer_label,place_label,course_type_label,start_dtm,end_dtm,' ||
												'delivery_method_label,provision_label,status_label,version,' ||
												'region_sid');
	END IF;
	
	/*
		There are three scenarios:
		1) Line manager looking for all their trainees
		2) Trainee looking for their own courses
		3) Admin looking across all users courses
		
		Does this still matter?? Does in_user_level = USER_LEVEL_ADMIN negate this or at least push the logic into GetTraineeSchedules - CHRIS
	*/
	IF in_user_level = USER_LEVEL_ADMIN THEN
		v_admin := 1;
	ELSE
		v_admin := 0;
	END IF;
		
	GetTraineeSchedules(				
		in_trainee_sid			=> in_employee_sid, 
		in_course_schedule_id	=> 0,
		in_start_row			=> in_start_row,
		in_row_limit			=> in_row_limit,
		in_sort_by				=> in_sort_by,
		in_sort_dir				=> in_sort_dir,
		in_search				=> in_search,
		in_course_type_id		=> in_course_type_id,
		in_function_id			=> in_function_id,
		in_provision_id			=> in_provision_id,
		in_status_id			=> in_status_id,
		in_region_sid			=> in_region_sid,
		in_from_dtm				=> in_from_dtm,
		in_to_dtm				=> in_to_dtm,
		in_show_full			=> in_show_full,
		in_query_type			=> in_query_type,
		in_course_id			=> in_course_id,
		in_flow_state_nature_id	=> in_flow_state_nature_id,
		in_user_level			=> in_user_level,
		in_admin				=> v_admin,
		v_out_schedules			=> v_temp_course_schedule
	);
	
	LOOP
		FETCH v_temp_course_schedule INTO v_record;
		EXIT WHEN v_temp_course_schedule%NOTFOUND;

		INSERT INTO temp_course_schedule
		VALUES v_record;
	END LOOP;

	-- get total rows count - grids need this for paging
	OPEN out_total FOR
		SELECT COUNT(*) total_results
		  FROM temp_course_schedule;
	
	-- get courses details to use for schedules population
	OPEN out_courses FOR
		 SELECT c.course_id, c.title, c.reference, c.description, c.version, c.course_type_id,
				c.region_sid, c.delivery_method_id, c.provision_id, c.status_id, c.default_trainer_id,
				c.default_place_id, c.duration, c.expiry_period, c.expiry_notice_period, c.escalation_notice_period,
				c.reminder_notice_period, c.pass_score, c.survey_sid, c.quiz_sid, c.pass_fail, c.absolute_deadline,
				r.description region_description
		   FROM (SELECT DISTINCT course_id FROM temp_course_schedule) tc
		   JOIN course c ON tc.course_id = c.course_id
		   JOIN v$region r ON c.region_sid = r.region_sid;
	
	-- get job functions associated with courses: 
	OPEN out_job_functions FOR
		 SELECT DISTINCT
				fc.course_id,
				fc.function_id,
				fc.training_priority_id,
				CASE -- Code Marcin
					WHEN in_user_level = USER_LEVEL_ADMIN THEN v_user_sid -- Admins want to see all job functions. The above cursor puts the admin SID in the results
					ELSE uf.csr_user_sid
				END user_sid
		   FROM function_course fc
	  LEFT JOIN user_function uf ON uf.function_id = fc.function_id
		  WHERE fc.app_sid = security_pkg.GetApp
		    AND fc.course_id IN (SELECT DISTINCT course_id FROM temp_course_schedule)
		    AND (in_user_level > USER_LEVEL_TRAINEE OR uf.csr_user_sid = v_user_sid)
	   ORDER BY course_id, function_id;
	
	-- get filtered schedule records
	OPEN out_course_schedules FOR
		' SELECT * ' ||
		  ' FROM ( ' ||
			' SELECT cs.*, ' ||
			  ' row_number() over (order by '||v_order_by||', course_schedule_id) rn ' ||
			  ' FROM temp_course_schedule cs ' ||
		  ' ) ' ||
		'  WHERE rn BETWEEN (:1 + 1) AND (:2 + :3) ' ||
		 ' ORDER BY rn'
		USING 	in_start_row, in_start_row, in_row_limit;
END;

PROCEDURE GetScheduleOptions(
	out_cur_course_types 		OUT SYS_REFCURSOR,
	out_cur_trainers 			OUT SYS_REFCURSOR,
	out_cur_places 				OUT SYS_REFCURSOR,
	out_cur_jobfunctions 		OUT SYS_REFCURSOR,
	out_cur_provisions 			OUT SYS_REFCURSOR,
	out_cur_statuses 			OUT SYS_REFCURSOR,
	out_cur_delivery_methods 	OUT SYS_REFCURSOR,
	out_cur_priorities			OUT SYS_REFCURSOR,
	out_cur_courses				OUT SYS_REFCURSOR
)
AS
BEGIN	
	GetCourseOptions(out_cur_course_types, out_cur_trainers, out_cur_places, out_cur_jobfunctions,
					out_cur_provisions, out_cur_statuses, out_cur_delivery_methods,	out_cur_priorities);

	GetActiveCourses(out_cur_courses);	
END;

PROCEDURE GetSingleScheduleForGrid(
	in_user_sid				IN NUMBER,
	in_course_schedule_id	IN NUMBER,
	in_user_level			IN NUMBER,
	out_schedules			OUT	SYS_REFCURSOR,
	out_courses				OUT	SYS_REFCURSOR
)
AS
	v_temp_course_schedule	SYS_REFCURSOR;
	v_record				temp_course_schedule%ROWTYPE;
BEGIN
	GetTraineeSchedules(
		in_trainee_sid			=> in_user_sid, 
		in_course_schedule_id	=> 0,
		in_start_row			=> NULL,
		in_row_limit			=> NULL,
		in_sort_by				=> NULL,
		in_sort_dir				=> NULL,
		in_search				=> NULL,
		in_course_type_id		=> NULL,
		in_function_id			=> NULL,
		in_provision_id			=> NULL,
		in_status_id			=> NULL,
		in_region_sid			=> NULL,
		in_from_dtm				=> NULL,
		in_to_dtm				=> NULL,
		in_show_full			=> NULL,
		in_query_type			=> NULL,
		in_course_id			=> NULL,
		in_flow_state_nature_id	=> NULL,
		in_user_level			=> in_user_level,
		in_admin				=> 0,
		v_out_schedules			=> v_temp_course_schedule
	);

	LOOP
		FETCH v_temp_course_schedule INTO v_record;
		EXIT WHEN v_temp_course_schedule%NOTFOUND;

		INSERT INTO temp_course_schedule
		VALUES v_record;
	END LOOP;
	
	-- get filtered schedule records
	OPEN out_schedules FOR
		SELECT * 
		  FROM ( 
			SELECT cs.*, row_number() over (order by course_schedule_id, course_schedule_id) rn 
			  FROM temp_course_schedule cs
		);
		
	-- get courses details to use for schedules population
	OPEN out_courses FOR
		SELECT course_id, title, reference, description, version, course_type_id,
			region_sid, delivery_method_id, provision_id, status_id, default_trainer_id,
			default_place_id, duration, expiry_period, expiry_notice_period, escalation_notice_period,
			reminder_notice_period, pass_score, survey_sid, quiz_sid, pass_fail, absolute_deadline,
			region_description
		  FROM temp_course_schedule c;

END;

PROCEDURE GetTrainers(
	out_cur OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT t.trainer_id,
			CASE
				WHEN t.user_sid IS NOT NULL THEN u.full_name
				ELSE t.name
			END name,
			t.user_sid,
			t.company,
			t.address,
			t.contact_details,
			t.notes
		  FROM trainer t
		  LEFT JOIN csr_user u ON u.app_sid = t.app_sid AND u.csr_user_sid = t.user_sid
		 WHERE t.app_sid = security_pkg.GetApp;
END;

PROCEDURE GetTrainingMapSid(
	out_map_sid			OUT security_pkg.T_SID_ID
)
AS
	v_map_sid			security_pkg.T_SID_ID;
BEGIN	
	BEGIN
		SELECT geo_map_sid 
		  INTO v_map_sid 
		  FROM training_options 
		 WHERE app_sid = security_pkg.GetAPP;

		IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_map_sid, security_pkg.PERMISSION_READ) THEN
			out_map_sid := v_map_sid;
		ELSE
			out_map_sid := NULL;
		END IF;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			out_map_sid := NULL;			
	END;
END;

PROCEDURE GetTrainingReminders(
    out_cur    OUT  SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ut.app_sid, ut.user_sid, ut.course_schedule_id, ut.flow_item_id,
			   fs.label, fs.lookup_key,
			   cu1.friendly_name user_friendly_name, cu1.email user_email,
			   cu2.friendly_name manager_friendly_name, cu2.email manager_email,
			   c.title, c.description, c.reference,
			   ce.start_dtm, ce.end_dtm, ce.location,
			   (
				-- http://oracle-base.com/articles/misc/string-aggregation-techniques.php
				SELECT LTRIM(MAX(SYS_CONNECT_BY_PATH(label,', '))
					   KEEP (DENSE_RANK LAST ORDER BY curr),', ')
				FROM (
					SELECT csr_user_sid,
						   label,
						   ROW_NUMBER() OVER (PARTITION BY csr_user_sid ORDER BY label) AS curr,
						   ROW_NUMBER() OVER (PARTITION BY csr_user_sid ORDER BY label) -1 AS prev
					FROM (
						SELECT uf.csr_user_sid, uf.function_id, f.label
						FROM user_function uf
						JOIN function f ON f.function_id = uf.function_id 
					)
				)
				GROUP BY csr_user_sid
				CONNECT BY prev = PRIOR curr AND csr_user_sid = PRIOR csr_user_sid
				START WITH curr = 1
				HAVING csr_user_sid = ut.user_sid
			   ) AS job_functions
		  FROM user_training ut
		  JOIN csr_user cu1 ON cu1.csr_user_sid = ut.user_sid
		  JOIN csr_user cu2 ON cu2.csr_user_sid = GetManager(ut.user_sid, ut.course_schedule_id)
		  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
		  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
		  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
		  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
		  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
		 WHERE lookup_key = 'CONFIRMED'
		   AND TRUNC(ce.start_dtm) = TRUNC(SYSDATE + c.REMINDER_NOTICE_PERIOD);
   
END;

-- Not currently used
PROCEDURE GetUserTrainingStatus(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	out_item_state 			OUT	SYS_REFCURSOR,
	out_transitions			OUT	SYS_REFCURSOR
)
AS
	v_user_sid	NUMBER(10);
BEGIN
	SECURITY.USER_PKG.GETSID(SECURITY.SECURITY_PKG.GETACT, v_user_sid);
	 
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, GetFlowSid(), security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||GetFlowSid());
	END IF;
	
	OPEN out_item_state FOR
		SELECT * 
		  FROM (
			SELECT ut.user_sid, ut.course_schedule_id, ut.flow_item_id, fs.label, fsl.comment_text
			  FROM user_training ut
			  JOIN flow_item fi ON fi.app_sid = ut.app_sid AND fi.flow_item_id = ut.flow_item_id
			  JOIN flow_state fs ON fs.app_sid = ut.app_sid AND fs.flow_state_id = fi.current_state_id
			  JOIN flow_state_log fsl ON fsl.app_sid = fi.app_sid AND fsl.flow_item_id = fi.flow_item_id 
				AND fsl.flow_state_id = fi.current_state_id
			 WHERE ut.app_sid = security.security_pkg.GetApp
			   AND ut.course_schedule_id = in_course_schedule_id
			   AND ut.user_sid = v_user_sid
			 ORDER BY fsl.set_dtm, fsl.flow_state_log_id
		)
		 WHERE ROWNUM = 1;
		
	OPEN out_transitions FOR
		SELECT fst.flow_state_transition_id, fst.verb, fst.from_state_id, fst.to_state_id, 
			fst.pos transition_pos, fs_to.label to_state_label, fst.ask_for_comment, fst.button_icon_path,
			fs_to.state_colour to_state_colour,
			CASE
				WHEN fst.lookup_key LIKE 'USER_%' THEN 1
				ELSE 0
			END is_user_transition
		  FROM flow_state_transition fst
		  JOIN flow_state fs_from ON fs_from.app_sid = fst.app_sid AND fs_from.flow_sid = fst.flow_sid AND fs_from.flow_state_id = fst.from_state_id
		  JOIN flow_state fs_to ON fs_to.app_sid = fst.app_sid AND fs_to.flow_sid = fst.flow_sid AND fs_to.flow_state_id = fst.to_state_id
		 WHERE fst.app_sid = security.security_pkg.GetApp
		   AND fst.flow_sid = GetFlowSid()
		   AND fs_from.flow_state_nature_id <> csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
		 ORDER BY fst.pos, fst.flow_state_transition_id;	
END;

PROCEDURE SaveCourse(
	in_course_id				IN course.course_id%TYPE,
	in_title					IN course.title%TYPE,
	in_reference				IN course.reference%TYPE,
	in_description				IN course.description%TYPE,
	in_version					IN course.version%TYPE,
	in_course_type_id			IN course.course_type_id%TYPE,
	in_region_sid				IN course.region_sid%TYPE,
	in_delivery_method_id		IN course.delivery_method_id%TYPE,
	in_provision_id				IN course.provision_id%TYPE,
	in_status_id				IN course.status_id%TYPE,
	in_default_trainer_id		IN course.default_trainer_id%TYPE,
	in_default_place_id			IN course.default_place_id%TYPE,
	in_duration					IN course.duration%TYPE,
	in_expiry_period			IN course.expiry_period%TYPE,
	in_expiry_notice_period		IN course.expiry_notice_period%TYPE,
	in_escalation_notice_period	IN course.escalation_notice_period%TYPE,
	in_reminder_notice_period	IN course.reminder_notice_period%TYPE,
	in_pass_score				IN course.pass_score%TYPE,
	in_survey_sid				IN course.survey_sid%TYPE,
	in_quiz_sid					IN course.quiz_sid%TYPE,
	in_pass_fail				IN course.pass_fail%TYPE,
	in_absolute_deadline		IN course.absolute_deadline%TYPE,
	out_course_id				OUT course.course_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	IF in_course_id > 0 THEN
		BEGIN
			UPDATE course 
			   SET course_id = in_course_id, title = in_title, reference = in_reference,
				description = in_description, version = in_version, course_type_id = in_course_type_id,
				region_sid = in_region_sid, delivery_method_id = in_delivery_method_id,
				provision_id = in_provision_id, status_id = in_status_id,
				default_trainer_id = in_default_trainer_id, default_place_id = in_default_place_id,
				duration = in_duration, expiry_period = in_expiry_period, 
				expiry_notice_period = in_expiry_notice_period, escalation_notice_period = in_escalation_notice_period,
				reminder_notice_period = in_reminder_notice_period, pass_score = in_pass_score,
				survey_sid = in_survey_sid, quiz_sid = in_quiz_sid, pass_fail = in_pass_fail,
				absolute_deadline = in_absolute_deadline
			 WHERE course_id = in_course_id
			   AND app_sid = security_pkg.GETAPP;
				
			out_course_id := in_course_id;
		END;
	ELSE
		BEGIN
			INSERT INTO course (app_sid, course_id, title, reference, description, version, course_type_id,
								region_sid, delivery_method_id, provision_id, status_id, default_trainer_id,
								default_place_id, duration, expiry_period, expiry_notice_period, 
								escalation_notice_period, reminder_notice_period, pass_score, survey_sid,
								quiz_sid, pass_fail, absolute_deadline)
			VALUES (security_pkg.GETAPP, COURSE_ID_SEQ.NEXTVAL, in_title, in_reference, in_description,
					in_version, in_course_type_id, in_region_sid, in_delivery_method_id, in_provision_id,
					in_status_id, in_default_trainer_id, in_default_place_id, in_duration, in_expiry_period,
					in_expiry_notice_period, in_escalation_notice_period, in_reminder_notice_period,
					in_pass_score, in_survey_sid, in_quiz_sid, in_pass_fail, in_absolute_deadline)
		 RETURNING course_id INTO out_course_id;
		END;
	END IF;
END;

PROCEDURE SaveCourseType(
	in_course_type_id				IN course_type.course_type_id%TYPE,
	in_label						IN course_type.label%TYPE,
	in_user_relationship_type_id	IN course_type.user_relationship_type_id%TYPE,
	out_course_type_id				OUT course_type.course_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	IF in_course_type_id > 0 THEN
		BEGIN
			UPDATE course_type
			   SET	label = in_label, user_relationship_type_id = in_user_relationship_type_id
			 WHERE course_type_id = in_course_type_id AND app_sid = security_pkg.GETAPP;
				
			out_course_type_id := in_course_type_id;
		END;
	ELSE
		BEGIN
			INSERT INTO course_type (app_sid, course_type_id, label, user_relationship_type_id)
			VALUES (security_pkg.GETAPP, COURSE_TYPE_ID_SEQ.NEXTVAL, in_label, in_user_relationship_type_id)
		 RETURNING course_type_id INTO out_course_type_id;
		END;
	END IF;
END;

PROCEDURE SaveCourseTypeRegion(
	in_course_type_id	IN course_type_region.course_type_id%TYPE,
	in_region_sid		IN course_type_region.region_sid%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	INSERT INTO course_type_region (app_sid, course_type_id, region_sid)
	VALUES (security_pkg.GetApp, in_course_type_id, in_region_sid);
END;

PROCEDURE SaveFunctionCourse(
	in_function_id				IN function_course.function_id%TYPE,
	in_course_id				IN function_course.course_id%TYPE,
	in_training_priority_id		IN function_course.training_priority_id%TYPE,
	out_alert_details			OUT SYS_REFCURSOR
)
AS
	v_old_training_priority_id	NUMBER(1);
	v_exists					NUMBER(1);
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	SELECT count(*)
	  INTO v_exists
	  FROM function_course
	 WHERE function_id = in_function_id
	   AND course_id = in_course_id
	   AND app_sid = security_pkg.GetApp;
	
	IF v_exists > 0 THEN
		BEGIN
			SELECT training_priority_id
			  INTO v_old_training_priority_id
			  FROM function_course
			 WHERE app_sid = security_pkg.GetApp
			   AND function_id = in_function_id
			   AND course_id = in_course_id;

			-- if NULL then this is a delete
			IF in_training_priority_id IS NOT NULL THEN
				UPDATE function_course
				   SET training_priority_id = in_training_priority_id
				 WHERE app_sid = security_pkg.GetApp
				   AND function_id = in_function_id
				   AND course_id = in_course_id;
			END IF;
		END;
	ELSE
		BEGIN
			INSERT INTO function_course (app_sid, function_id, course_id, training_priority_id)
			VALUES (security_pkg.GetApp, in_function_id, in_course_id, in_training_priority_id);
		END;
	END IF;
	
	IF (v_old_training_priority_id IS NULL) OR (v_old_training_priority_id != in_training_priority_id AND (v_old_training_priority_id = 2 OR in_training_priority_id = 2)) THEN
		-- we probably need to alert the users about this change

		-- done and expired
		-- done and due to expire soon
		-- confirmed
		-- requested
		-- requested
		-- nothing
		OPEN out_alert_details FOR
			SELECT cu1.csr_user_sid, cu1.friendly_name user_friendly_name, cu1.email user_email,
			   cu2.friendly_name manager_friendly_name, cu2.email manager_email,
			   c.title, c.description, c.reference,
			   (SELECT label FROM training_priority WHERE training_priority_id = in_training_priority_id) new_priority,
			   (SELECT label FROM training_priority WHERE training_priority_id = v_old_training_priority_id) old_priority,
			   (SELECT label FROM function WHERE function_id = in_function_id) job_function
			  FROM course c,
				   csr_user cu1,
				   csr_user cu2,
				   user_relationship ur,
				   course_type ct
			 WHERE cu1.csr_user_sid IN (
			
				-- find users that have the modified job function
				SELECT csr_user_sid
				  FROM user_function
				 WHERE function_id = in_function_id
				   AND csr_user_sid NOT IN (
					-- and do not have another job function
					SELECT csr_user_sid
					  FROM user_function
					 WHERE function_id != in_function_id
					   AND function_id IN (
						-- that is also associated with this course and mandatory
						SELECT function_id
						  FROM function_course
						 WHERE course_id = in_course_id
						   AND training_priority_id != 2 -- not mandatory
						)
					)
				   AND csr_user_sid NOT IN (
					-- and have not already completed the course already
					SELECT ut.user_sid
					  FROM user_training ut
					  JOIN flow_item fi ON fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
					  JOIN FLOW_STATE fs ON fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
					  JOIN course_schedule cs ON cs.COURSE_SCHEDULE_ID = ut.COURSE_SCHEDULE_ID
					  JOIN course c ON c.COURSE_ID = cs.COURSE_ID
					  JOIN CALENDAR_EVENT ce ON ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
					 WHERE fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
					   AND ut.app_sid = security.security_pkg.GetApp
					   AND (
							-- and completed course not expired, or due to expire soon
							c.EXPIRY_PERIOD IS NULL
						 OR c.EXPIRY_PERIOD = 0
						 OR (ADD_MONTHS(ce.END_DTM, c.EXPIRY_PERIOD) - c.EXPIRY_NOTICE_PERIOD < SYSDATE) 
						   )
					)
				)
			   AND cu1.csr_user_sid = ur.child_user_sid
			   AND cu2.csr_user_sid = ur.parent_user_sid
			   AND ur.user_relationship_type_id = ct.user_relationship_type_id
			   AND ct.course_type_id = c.course_type_id;
	ELSE
		-- Return empty cursor
		OPEN out_alert_details FOR
		SELECT NULL FROM DUAL WHERE 1=0;
	END IF;
END;

PROCEDURE SaveSchedule(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_course_id			IN	course_schedule.course_id%TYPE,
	in_max_capacity			IN	course_schedule.max_capacity%TYPE,
	in_trainer_id			IN	course_schedule.trainer_id%TYPE,
	in_place_id				IN	course_schedule.place_id%TYPE,
	in_start_dtm			IN	calendar_event.start_dtm%TYPE,
	in_end_dtm				IN	calendar_event.end_dtm%TYPE,
	in_attendance_password	IN	course_schedule.attendance_password%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_calendar_event_id 	calendar_event.calendar_event_id%TYPE;
	v_course_schedule_id	course_schedule.course_schedule_id%TYPE;
	v_max_capacity			course_schedule.max_capacity%TYPE;
	v_booked				course_schedule.booked%TYPE;
	v_capacity_dif			NUMBER;
BEGIN
	-- check if user got rights to make the changes
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course schedule') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course schedule" capability');
	END IF;
	
	IF in_course_schedule_id IS NULL OR in_course_schedule_id < 1 THEN
		-- create calendar event first
		INSERT INTO calendar_event (calendar_event_id, start_dtm, end_dtm, created_by_sid, created_dtm)
		VALUES (calendar_event_id_seq.nextval, in_start_dtm, in_end_dtm, SYS_CONTEXT('SECURITY','SID'), SYSDATE)
		RETURNING calendar_event_id INTO v_calendar_event_id;
		
		-- create course schedule
		INSERT INTO course_schedule (course_schedule_id, course_id, calendar_event_id, max_capacity, trainer_id, place_id, booked, available, canceled, attendance_password)
		VALUES (course_schedule_id_seq.nextval, in_course_id, v_calendar_event_id, in_max_capacity, in_trainer_id, in_place_id, 0, in_max_capacity, 0, in_attendance_password)
		RETURNING course_schedule_id INTO v_course_schedule_id;
	ELSE
		v_course_schedule_id := in_course_schedule_id;
		
		SELECT max_capacity, booked, calendar_event_id
		  INTO v_max_capacity, v_booked, v_calendar_event_id
		  FROM course_schedule
		 WHERE app_sid = security_pkg.GetApp
		   AND course_schedule_id = v_course_schedule_id;
		
		-- check new max capacity is not lower than booked places
		IF in_max_capacity < v_booked THEN
			RAISE_APPLICATION_ERROR(-20001, 'cannot decrease capacity below booked places level');
		END IF;
		
		v_capacity_dif := in_max_capacity - v_max_capacity;
		
		UPDATE course_schedule
		   SET max_capacity = in_max_capacity, trainer_id = in_trainer_id, place_id = in_place_id,
			   available = available + v_capacity_dif, attendance_password = in_attendance_password
		 WHERE app_sid = security_pkg.GetApp
		   AND course_schedule_id = v_course_schedule_id;
		 
		UPDATE calendar_event
		   SET start_dtm = in_start_dtm, end_dtm = in_end_dtm
		 WHERE app_sid = security_pkg.GetApp
		   AND calendar_event_id = v_calendar_event_id;
	END IF;
	
	OPEN out_cur FOR
		SELECT cs.course_schedule_id, cs.course_id, ce.calendar_event_id, cs.max_capacity, cs.trainer_id,
			cs.place_id, cs.booked, cs.available, cs.canceled, ce.description, ce.start_dtm, ce.end_dtm,
			ce.created_by_sid, ce.created_dtm, ce.location, ce.region_sid, cs.attendance_password
		  FROM course_schedule cs
		  JOIN calendar_event ce ON ce.app_sid = cs.app_sid AND ce.calendar_event_id = cs.calendar_event_id
		 WHERE cs.app_sid = security_pkg.GetApp
		   AND cs.course_schedule_id = v_course_schedule_id;	
END;

PROCEDURE SaveTrainer(
	in_trainer_id		IN trainer.trainer_id%TYPE,
	in_name				IN trainer.name%TYPE,
	in_user_sid			IN trainer.user_sid%TYPE,
	in_company			IN trainer.company%TYPE,
	in_address			IN trainer.address%TYPE,
	in_contact_details	IN trainer.contact_details%TYPE,
	in_notes			IN trainer.notes%TYPE,
	out_cur 			OUT SYS_REFCURSOR
)
AS
	v_trainer_id trainer.trainer_id%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability(security_pkg.GetAct, 'Can edit course details') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on the "Can edit course details" capability');
	END IF;
	
	IF in_trainer_id > 0 THEN
		BEGIN
			UPDATE trainer
			   SET name = in_name,
			       user_sid = in_user_sid,
				   company = in_company,
				   address = in_address,
				   contact_details = in_contact_details,
				   notes = in_notes
			 WHERE trainer_id = in_trainer_id AND app_sid = security_pkg.GETAPP;
				
			v_trainer_id := in_trainer_id;
		END;
	ELSE
		BEGIN
			INSERT INTO trainer (app_sid, trainer_id, name, user_sid, company, address, contact_details, notes)
			VALUES (security_pkg.GETAPP, TRAINER_ID_SEQ.NEXTVAL, in_name, in_user_sid, in_company, in_address, in_contact_details, in_notes)
		 RETURNING trainer_id INTO v_trainer_id;
		END;
	END IF;
	
	OPEN out_cur FOR
		SELECT t.trainer_id,
			CASE
				WHEN t.user_sid IS NOT NULL THEN u.full_name
				ELSE t.name
			END name,
			t.user_sid,
			t.company,
			t.address,
			t.contact_details,
			t.notes
		  FROM trainer t
		  LEFT JOIN csr_user u ON u.app_sid = t.app_sid AND u.csr_user_sid = t.user_sid
		 WHERE t.app_sid = security_pkg.GetApp
		   AND t.trainer_id = v_trainer_id;
END;

PROCEDURE SetAttendance(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_attended				IN  NUMBER,
	in_reason				IN	VARCHAR2,
	in_manager				IN	NUMBER
)
AS
	v_password_match		NUMBER(1);
BEGIN
	IF in_attended = 1 AND in_manager = 0 THEN
		SELECT COUNT(*)
		  INTO v_password_match
		  FROM course_schedule cs
		 WHERE app_sid = security_pkg.getApp
		   AND course_schedule_id = in_course_schedule_id
		   AND attendance_password = in_reason;
		
		IF v_password_match = 0 THEN
			RAISE_APPLICATION_ERROR(ERR_WRONG_PASSWORD, 'Wrong password');
		END IF;
	END IF;
		   
	IF in_attended = 1 THEN
		SetUserTrainingState(
			in_user_sid				=> in_user_sid,
			in_course_schedule_id	=> in_course_schedule_id,
			in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'POST_ATTENDED'),
			in_reason				=> NULL
		);
	ELSE
		SetUserTrainingState(
			in_user_sid				=> in_user_sid,
			in_course_schedule_id	=> in_course_schedule_id,
			in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'POST_MISSED'),
			in_reason				=> NULL
		);
	END IF;
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

PROCEDURE SetPassed(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_passed				IN  NUMBER,
	in_score				IN  user_training.score%TYPE
)
AS
BEGIN
	IF in_passed = 1 THEN
		SetUserTrainingState(
			in_user_sid				=> in_user_sid,
			in_course_schedule_id	=> in_course_schedule_id,
			in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'POST_PASSED'),
			in_reason				=> NULL
		);
	ELSE
		SetUserTrainingState(
			in_user_sid				=> in_user_sid,
			in_course_schedule_id	=> in_course_schedule_id,
			in_to_state_id			=> flow_pkg.GetStateId(GetFlowSid(), 'POST_FAILED'),
			in_reason				=> NULL
		);   
	END IF;
	   
	UPDATE user_training
	   SET score = in_score
	 WHERE app_sid = security_pkg.getApp
	   AND user_sid = in_user_sid
	   AND course_schedule_id = in_course_schedule_id;
	
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RAISE_APPLICATION_ERROR(ERR_USER_TRAINING_DOESNT_EXIST, 'User training does not exist');
END;

PROCEDURE GetTrainingMatrixData(
	in_course_id		IN	NUMBER,
	in_function_id		IN	NUMBER,
	in_course_type_id	IN	NUMBER,
	in_priority_id		IN	NUMBER,
	out_xaxis			OUT SYS_REFCURSOR,
	out_yaxis			OUT SYS_REFCURSOR,
	out_data			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF security.user_pkg.IsUserInGroup(sys_context('SECURITY', 'ACT'),
		security.securableobject_pkg.GetSidFromPath(sys_context('SECURITY', 'ACT'), sys_context('SECURITY', 'APP'), 'Groups/Training Administrator')) = 0 AND
	   SECURITY.user_pkg.IsUserInGroup(sys_context('SECURITY', 'ACT'),
		security.securableobject_pkg.GetSidFromPath(sys_context('SECURITY', 'ACT'), sys_context('SECURITY', 'APP'), 'Groups/Administrators')) = 0 THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_yaxis FOR
		SELECT course_id id, title label FROM course
		 WHERE course_id = NVL(in_course_id, course_id)
		   AND course_type_id = NVL(in_course_type_id, course_type_id);
	
	OPEN out_xaxis FOR
		SELECT function_id id, label FROM function 
		 WHERE function_id = NVL(in_function_id, function_id);
	
	OPEN out_data FOR
		SELECT 
			   c.title, 
			   c.course_id, 
			   f.label, 
			   f.function_id, 
			   count(fs.flow_state_id) training_attended, 
			   count(fs2.flow_state_id) training_missed, 
			   count(fs3.flow_state_id) training_confirmed
		  FROM course c
		  JOIN function_course fc ON c.course_id = fc.course_id
		  JOIN function f ON fc.function_id = f.function_id
		  JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
		  LEFT JOIN course_schedule cs ON c.course_id = cs.course_id
		  JOIN course_type ct ON c.course_type_id = ct.course_type_id
		  LEFT JOIN user_training ut ON cs.course_schedule_id = ut.course_schedule_id
		  LEFT JOIN flow_item fi ON ut.flow_item_id = fi.flow_item_id
		  LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fs.lookup_key = 'POST_ATTENDED'
		  LEFT JOIN flow_state fs2 ON fi.current_state_id = fs2.flow_state_id AND fs2.lookup_key = 'POST_MISSED'
		  LEFT JOIN flow_state fs3 ON fi.current_state_id = fs3.flow_state_id AND fs3.lookup_key != 'PRE_DECLINED' -- user training in any flow state
		 WHERE c.course_id = NVL(in_course_id,c.course_id) -- filter by course
		   AND f.function_id = NVL(in_function_id, f.function_id) -- filter by job function
		   AND ct.course_type_id = NVL(in_course_type_id, ct.course_type_id) -- filter by course type
		   AND tp.training_priority_id = NVL(in_priority_id, tp.training_priority_id) -- filter by priority
		 GROUP BY f.function_id, f.label, c.course_id, c.title
		UNION
		SELECT 
			   'All courses' title, 
			   CAST(0 AS NUMBER(10)) course_id, 
			   f.label, 
			   f.function_id, 
			   count(fs.flow_state_id) training_attended, 
			   count(fs2.flow_state_id) training_missed, 
			   count(fs3.flow_state_id) training_confirmed
		  FROM course c
		  JOIN function_course fc ON c.course_id = fc.course_id
		  JOIN function f ON fc.function_id = f.function_id
		  JOIN training_priority tp ON fc.training_priority_id = tp.training_priority_id
		  LEFT JOIN course_schedule cs ON c.course_id = cs.course_id
		  JOIN course_type ct ON c.course_type_id = ct.course_type_id
		  LEFT JOIN user_training ut ON cs.course_schedule_id = ut.course_schedule_id
		  LEFT JOIN flow_item fi ON ut.flow_item_id = fi.flow_item_id
		  LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fs.lookup_key = 'POST_ATTENDED'
		  LEFT JOIN flow_state fs2 ON fi.current_state_id = fs2.flow_state_id AND fs2.lookup_key = 'POST_MISSED'
		  LEFT JOIN flow_state fs3 ON fi.current_state_id = fs3.flow_state_id AND fs3.lookup_key != 'PRE_DECLINED' -- user training in any flow state
		 WHERE c.course_id = NVL(in_course_id,c.course_id) -- filter by course
		   AND f.function_id = NVL(in_function_id, f.function_id) -- filter by job function
		   AND ct.course_type_id = NVL(in_course_type_id, ct.course_type_id) -- filter by course type
		   AND tp.training_priority_id = NVL(in_priority_id, tp.training_priority_id) -- filter by priority
		 GROUP BY f.function_id, f.label;
END;

PROCEDURE GetReport_Attendence(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		select f.LABEL "Job function",
			   c.TITLE "Course title", c.REFERENCE "Course reference",-- c.EXPIRY_PERIOD "Expiry (months)", c.STATUS_ID, c.COURSE_ID, 
			   ce.START_DTM "Course date",
			   CASE WHEN NVL(c.EXPIRY_PERIOD,0) = 0 THEN 'N/A' ELSE TO_CHAR(ADD_MONTHS(TRUNC(ce.END_DTM), c.EXPIRY_PERIOD)) END "Expiry date",
			   -- ut.FLOW_ITEM_ID,
			   cu.FRIENDLY_NAME "Name",-- cu.CSR_USER_SID, 
			   fs.LABEL "Attendance"--, fs.LOOKUP_KEY
		from   user_function uf
		join   function f         on f.APP_SID = security_pkg.GETAPP  and f.FUNCTION_ID = uf.FUNCTION_ID
		join   FUNCTION_COURSE fc on fc.APP_SID = security_pkg.GETAPP and fc.FUNCTION_ID = f.FUNCTION_ID 
		join   COURSE c           on c.APP_SID = security_pkg.GETAPP  and c.COURSE_ID = fc.COURSE_ID
		join   COURSE_SCHEDULE cs on cs.APP_SID = security_pkg.GETAPP and cs.COURSE_ID = c.COURSE_ID
		join   CALENDAR_EVENT ce  on ce.APP_SID = security_pkg.GETAPP and ce.CALENDAR_EVENT_ID = cs.CALENDAR_EVENT_ID
		join   USER_TRAINING ut   on ut.APP_SID = security_pkg.GETAPP and ut.COURSE_SCHEDULE_ID = cs.COURSE_SCHEDULE_ID
		join   CSR_USER cu        on cu.APP_SID = security_pkg.GETAPP and cu.CSR_USER_SID = ut.USER_SID
		join   FLOW_ITEM fi       on fi.APP_SID = security_pkg.GETAPP and fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
		join   FLOW_STATE fs      on fs.APP_SID = security_pkg.GETAPP and fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID
		where  fc.TRAINING_PRIORITY_ID = 2 -- mandatory
		and    c.STATUS_ID = 1 -- active
		and    fs.flow_state_nature_id IN (csr_data_pkg.NATURE_TRAINING_POST_ATTENDED)
		order by fs.lookup_key;	
END;

PROCEDURE GetReport_Deficiency(
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		select f.LABEL "Job function",
			   cids.TITLE "Course title", cids.REFERENCE "Course reference",
			   NVL(TO_CHAR(ce.START_DTM), 'N/A') "Course date",
			   CASE WHEN ce.END_DTM IS NULL THEN 'N/A' WHEN NVL(cids.EXPIRY_PERIOD,0) = 0 THEN 'N/A' ELSE TO_CHAR(ADD_MONTHS(TRUNC(ce.END_DTM), cids.EXPIRY_PERIOD)) END "Expiry date",
			   cu.FRIENDLY_NAME "Name",
			   CASE WHEN fs.label IS NOT NULL AND ADD_MONTHS(TRUNC(ce.END_DTM), cids.EXPIRY_PERIOD) > SYSDATE THEN fs.label WHEN fs.label IS NOT NULL THEN fs.label ELSE 'Not attended' END "Attendance",
			   cids.ce_id, fs.label, ce.end_dtm, cids.expiry_period

		  from (
			select c.TITLE, c.REFERENCE, c.EXPIRY_PERIOD,
				   uf.CSR_USER_SID user_sid,
				   GetLatestCompleteCalendarEvent(fc.COURSE_ID, uf.CSR_USER_SID) ce_id,
				   fc.FUNCTION_ID
			  from FUNCTION_COURSE fc
			  join user_function uf ON uf.APP_SID = security_pkg.GETAPP and uf.FUNCTION_ID = fc.FUNCTION_ID
			  join COURSE c ON c.COURSE_ID = fc.COURSE_ID
			 where fc.TRAINING_PRIORITY_ID = 2 -- mandatory
			   and c.STATUS_ID = 1 -- active
			) cids
		  join function f              ON f.APP_SID = security_pkg.GETAPP  and f.FUNCTION_ID = cids.FUNCTION_ID
		  join csr_user cu             ON cu.APP_SID = security_pkg.GETAPP and cu.csr_user_sid = cids.user_sid
		  left join calendar_event ce  ON ce.APP_SID = security_pkg.GETAPP and ce.CALENDAR_EVENT_ID = cids.ce_id
		  left join COURSE_SCHEDULE cs on cs.APP_SID = security_pkg.GETAPP and cs.CALENDAR_EVENT_ID = cids.ce_id
		  left join USER_TRAINING ut   on ut.APP_SID = security_pkg.GETAPP and ut.COURSE_SCHEDULE_ID = cs.COURSE_SCHEDULE_ID and ut.USER_SID = cids.user_sid
		  left join FLOW_ITEM fi       on fi.APP_SID = security_pkg.GETAPP and fi.FLOW_ITEM_ID = ut.FLOW_ITEM_ID
		  left join FLOW_STATE fs      on fs.APP_SID = security_pkg.GETAPP and fs.FLOW_STATE_ID = fi.CURRENT_STATE_ID;

END;

/*
*	Training Course File Procedures
*	Audit Logging procedure calls have been left in but commented out in case we want to audit log course changes in the future.
*/
PROCEDURE DeleteTrainingCourseFiles(
	in_course_id				IN	course.course_id%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,  -- list of files which needs to stay untouched (will keep exist and attached to the audit)
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_keeper_id_tbl				security.T_SID_TABLE;		-- this is equal to in_current_file_uploads but in table format
	v_delete_id_tbl				security.T_SID_TABLE;       -- files to delete from audit
BEGIN
	-- crap hack for ODP.NET
	IF in_current_file_uploads IS NULL OR (in_current_file_uploads.COUNT = 1 AND in_current_file_uploads(1) IS NULL) THEN
	
		-- remove all files of audit (a file itself will be deleted only if it is not being used by another audit)
		DELETE FROM course_file_data
		 WHERE course_file_data_id IN (
		SELECT course_file_data_id
		  FROM course_file
		 WHERE course_id = in_course_id
		     )
	       AND course_file_data_id NOT IN (    -- delete an internal file only if it is not being used by another audit
	   	SELECT course_file_data_id
		  FROM course_file
		 WHERE course_id != course_id
		    );
		
		-- left in place in case we want to add audit log to courses
		-- FOR r IN (
			-- SELECT cf.filename
			  -- FROM course_file cf
			  -- JOIN course_file_data cfd
			    -- ON cdf.course_file_data_id = cfd.course_file_data_id
			 -- WHERE cf.course_id = in_course_id
			 -- ) LOOP
			 
				-- csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_course_id,
					-- 'Removed document {0}', r.filename);				 
			 
			-- END LOOP;
		
		DELETE FROM course_file
		 WHERE course_id = in_course_id;
	ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_current_file_uploads);
		
		-- Get files into v_delete_id_tbl which need to be deleted from course_file and possibly from course_file_data as well
		SELECT course_file_data_id
		  BULK COLLECT INTO v_delete_id_tbl
		  FROM course_file
		 WHERE course_id = in_course_id
		   AND course_file_data_id NOT IN (
			SELECT column_value FROM TABLE(v_keeper_id_tbl));

		-- left in place in case we want to add audit log to courses
		-- FOR r IN (
			-- SELECT cfd.filename
			  -- FROM course_file cf
			  -- JOIN course_file_data cfd
			    -- ON cf.course_file_data_id = cfd.course_file_data_id
			 -- WHERE cf.course_id = in_course_id
			   -- AND cf.course_file_data_id NOT IN (
					-- SELECT column_value FROM TABLE(v_keeper_id_tbl))
			 -- ) LOOP
			 
				-- csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_course_id,
					-- 'Removed document {0}', r.filename);				 
			 
			-- END LOOP;			
		
		-- delete documents from the connection table
		DELETE FROM course_file
		 WHERE course_id = in_course_id 
		   AND course_file_data_id IN (
			SELECT column_value FROM TABLE(v_delete_id_tbl));
		
		-- delete documents from course_file_data which are not in course_file any more. (no other audit uses them)
		FOR r IN (
				SELECT column_value 
				  FROM TABLE(v_delete_id_tbl)
				 WHERE column_value NOT IN(				
					SELECT course_file_data_id
					  FROM course_file
					 )
			) 
		LOOP
			DELETE FROM course_file_data
		     WHERE course_file_data_id = r.column_value;	 
			 
		END LOOP;
	END IF;
	
	-- return a nice clean list
	OPEN out_cur FOR
		SELECT cfd.course_file_data_id, cf.course_id, cfd.filename, cfd.mime_type, cast(cfd.sha1 as varchar2(40)) sha1, cfd.uploaded_dtm
		  FROM course_file_data cfd
		  JOIN course_file cf
		    ON cf.course_file_data_id = cfd.course_file_data_id
		 WHERE cf.course_id = in_course_id;
END;

FUNCTION INTERNAL_CacheKeysArrayToTable(
	in_strings			IN	T_CACHE_KEYS
) RETURN security.T_VARCHAR2_TABLE
AS
	v_table security.T_VARCHAR2_TABLE := security.T_VARCHAR2_TABLE();
BEGIN
	IF in_strings.COUNT = 0 OR (in_strings.COUNT = 1 AND in_strings(in_strings.FIRST) IS NULL) THEN
	-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
	END IF;

	FOR i IN in_strings.FIRST .. in_strings.LAST
	LOOP
		v_table.extend;
		v_table(v_table.COUNT) := security.T_VARCHAR2_ROW(i, in_strings(i));
	END LOOP;

	RETURN v_table;
END;

PROCEDURE InsertTrainingCourseFiles(
	in_course_id				IN	course.course_id%TYPE,
	in_new_file_uploads			IN	T_CACHE_KEYS,			 -- new files to put into course_file_data and attach to the audit (course_file)
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_cache_key_tbl				security.T_VARCHAR2_TABLE;
BEGIN
	v_cache_key_tbl := INTERNAL_CacheKeysArrayToTable(in_new_file_uploads);

	-- insert into two table (do it in a loop because of course_file_id_seq.nextval)
	FOR r IN (
			SELECT course_file_id_seq.nextval nextvalue, filename, mime_type, object obj, dbms_crypto.hash(object, dbms_crypto.hash_sh1) hash
			  FROM aspen2.filecache
	         WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)
			)
		) 
	LOOP
		INSERT INTO course_file_data
			(course_file_data_id, filename, mime_type, data, sha1)
			VALUES (r.nextvalue, r.filename, r.mime_type, r.obj, r.hash);
			
		INSERT INTO course_file (app_sid, course_id, course_file_data_id)
			VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_course_id, r.nextvalue);

		-- left in place in case we want to add audit log to courses
		-- csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_DOCUMENTS, SYS_CONTEXT('SECURITY', 'APP'), in_course_id,
			-- 'Added document {0}', r.filename);
			
	END LOOP;

	-- return a nice clean list
	OPEN out_cur FOR
		SELECT cfd.course_file_data_id, cf.course_id, cfd.filename, cfd.mime_type, cast(cfd.sha1 as varchar2(40)) sha1, cfd.uploaded_dtm
		  FROM course_file_data cfd
		  JOIN course_file cf
		    ON cf.course_file_data_id = cfd.course_file_data_id
		 WHERE cf.course_id = in_course_id;
END;

PROCEDURE GetTrainingCourseFile(
	in_course_file_data_id		IN	course_file_data.course_file_data_id%TYPE,
	in_sha1						IN  course_file_data.sha1%TYPE,
	out_cur						OUT	SYS_REFCURSOR
)
AS
	v_table						security.T_SID_TABLE;
BEGIN
	OPEN out_cur FOR
		SELECT cfd.course_file_data_id, cfd.filename, cfd.mime_type,
		       cast(cfd.sha1 as varchar2(40)) sha1, cfd.uploaded_dtm, cfd.data
		  FROM course_file_data cfd
		 WHERE cfd.course_file_data_id = in_course_file_data_id
		   AND cfd.sha1 = in_sha1;
END;

PROCEDURE GetTrainingCourseFiles(
	in_course_id		IN	course.course_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_table						security.T_SID_TABLE;
BEGIN
	OPEN out_cur FOR
		SELECT cf.course_id, cfd.course_file_data_id, cfd.filename, cfd.mime_type,
		       cast(cfd.sha1 as varchar2(40)) sha1, cfd.uploaded_dtm, cfd.data
		  FROM course_file cf
		  JOIN course_file_data cfd on cf.course_file_data_id = cfd.course_file_data_id
		 WHERE cf.course_id = in_course_id;
END;

END Training_Pkg;
/

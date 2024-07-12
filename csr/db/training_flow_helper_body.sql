CREATE OR REPLACE PACKAGE BODY CSR.training_flow_helper_pkg
IS

/* STANDARD FLOW TRANSITION HELPERS */
PROCEDURE TransitionApproveBooking(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_user_sid				user_course.user_sid%TYPE;
	v_course_id				user_course.course_id%TYPE;
	v_course_schedule_id	user_course.course_schedule_id%TYPE;
	v_available				NUMBER(10);
BEGIN
	-- Get user_sid, course_id and course_schedule_id
	SELECT user_sid, course_id, course_schedule_id
	  INTO v_user_sid, v_course_id, v_course_schedule_id
	  FROM csr.user_training
	 WHERE flow_item_id = in_flow_item_id;

	SELECT available 
	  INTO v_available
	  FROM course_schedule
	 WHERE course_schedule_id = v_course_schedule_id;
	
	IF v_available = 0 THEN
		RAISE_APPLICATION_ERROR(training_pkg.ERR_COURSE_FULL, 'There are no more places on this course.');
	END IF;
	 
	-- One booking confirmed. Don't let the user book this course again.
	BEGIN
		INSERT INTO user_course 
					(app_sid, user_sid, course_id, course_schedule_id, schedule_course) 
			 VALUES (SYS_CONTEXT('security', 'app'), v_user_sid, v_course_id, v_course_schedule_id, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_course
			   SET schedule_course = 0,
				   course_schedule_id = v_course_schedule_id
			 WHERE user_sid = v_user_sid
			   AND course_id = v_course_id;
	END;
	
	-- Change "available spaces" count
	UPDATE course_schedule
	   SET available = available - 1
	 WHERE course_schedule_id = v_course_schedule_id;
	
	-- Remove all other unapproved bookings for this course/user
	FOR r IN (
		SELECT ut.course_schedule_id, f.flow_item_id
		  FROM v$training_flow_item f
		  JOIN user_training ut ON f.flow_item_id = ut.flow_item_id
		 WHERE ut.user_sid = v_user_sid
		   AND ut.course_id = v_course_id
		   AND	(
				f.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_UNSCHEDULED
				OR
				f.flow_state_nature_id = csr_data_pkg.NATURE_TRAINING_UNAPPROVED
				)
		   AND f.course_schedule_id <> v_course_schedule_id -- This should have been moved already?
	)
	LOOP
		-- It's cleaner to delete old unapproved. Alternative would be to move it to the deleted state
		training_pkg.DeleteBooking(
			in_user_sid				=> v_user_sid,
			in_course_id			=> v_course_id,
			in_course_schedule_id	=> r.course_schedule_id,
			in_flow_item_id			=> r.flow_item_id
			);
	END LOOP;
END;

PROCEDURE TransitionUnApproveBooking(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_user_sid				user_course.user_sid%TYPE;
	v_course_id				user_course.course_id%TYPE;
	v_course_schedule_id	user_course.course_schedule_id%TYPE;
BEGIN
	SELECT user_sid, course_id, course_schedule_id
	  INTO v_user_sid, v_course_id, v_course_schedule_id
	  FROM csr.user_training
	 WHERE flow_item_id = in_flow_item_id;

	-- TODO: IF there is a completed entry for this course, should we set the user_course.course_schedule_id to this value?
	UPDATE user_course
	   SET schedule_course = 1
	 WHERE user_sid = v_user_sid
	   AND course_id = v_course_id;
	   
	-- Change "available spaces" count
	UPDATE course_schedule
	   SET available = available + 1
	 WHERE course_schedule_id = v_course_schedule_id;

END;

PROCEDURE TransitionCourseValid(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_user_sid				user_course.user_sid%TYPE;
	v_course_id				user_course.course_id%TYPE;
	v_course_schedule_id	user_course.course_schedule_id%TYPE;
BEGIN
	-- Get user_sid, course_id and course_schedule_id
	SELECT user_sid, course_id, course_schedule_id
	  INTO v_user_sid, v_course_id, v_course_schedule_id
	  FROM csr.user_training
	 WHERE flow_item_id = in_flow_item_id;	
	
	BEGIN
		INSERT INTO user_course 
					(
					app_sid,
					user_sid, 
					course_id,
					course_schedule_id,
					valid,
					completed_dtm,
					schedule_course
					)
			 VALUES (
					SYS_CONTEXT('security', 'app'),
					v_user_sid,
					v_course_id,
					v_course_schedule_id,
					1,
					SYSDATE,
					0
					);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_course
			   SET course_schedule_id = v_course_schedule_id,
				   valid = 1,
				   completed_dtm = SYSDATE,
				   schedule_course = 0
			 WHERE user_sid = v_user_sid
			   AND course_id = v_course_id;
	END;
	
	-- TODO: PUT THE FOLLOWING DATE LOGIC INTO A SEPARATE PROC SO IT CAN BE CALLED FOR USER_COURSE TABLE INSERTS/UPDATES
	-- Set expiry and notice dates
	 UPDATE user_course uc
	    SET (
			expiry_dtm,
			expiry_notice_dtm,
			expiry_notice_sent,
			escalation_notice_dtm,
			escalation_notice_sent,
			reschedule_dtm
			) = ( 
			 SELECT	CASE 
						WHEN c.expiry_period <> 0 THEN ADD_MONTHS(sysdate, c.expiry_period)
						ELSE NULL
					END expiry_dtm,
					CASE 
						WHEN c.expiry_period <> 0 AND c.expiry_notice_period IS NOT NULL THEN ADD_MONTHS(sysdate, c.expiry_period) - c.expiry_notice_period
						ELSE NULL
					END expiry_notice_dtm,
					0, -- expiry_notice_sent
					CASE 
						WHEN c.expiry_period <> 0 AND escalation_notice_period IS NOT NULL THEN ADD_MONTHS(sysdate, c.expiry_period) - c.escalation_notice_period
						ELSE NULL
					END escalation_notice_dtm,
					0, -- escalation_notice_sent
					CASE 
						WHEN c.expiry_period <> 0 AND expiry_notice_period IS NOT NULL THEN ADD_MONTHS(sysdate, c.expiry_period) - c.expiry_notice_period
						ELSE NULL
					END reschedule_dtm
			   FROM course c
			  WHERE c.course_id = uc.course_id
			)
	  WHERE uc.course_id = v_course_id
	    AND uc.user_sid = v_user_sid;
	
END;

PROCEDURE TransitionCourseExpired(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_user_sid				user_course.user_sid%TYPE;
	v_course_id				user_course.course_id%TYPE;
BEGIN
	SELECT user_sid, course_id
	  INTO v_user_sid, v_course_id
	  FROM csr.user_training
	 WHERE flow_item_id = in_flow_item_id;	
	 
	UPDATE user_course
	   SET valid = 0, schedule_course = 1
	 WHERE user_sid = v_user_sid
	   AND course_id = v_course_id;
END;

PROCEDURE TransitionReschedule(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
)
AS
	v_user_sid				user_course.user_sid%TYPE;
	v_course_id				user_course.course_id%TYPE;
BEGIN
	SELECT user_sid, course_id
	  INTO v_user_sid, v_course_id
	  FROM csr.user_training
	 WHERE flow_item_id = in_flow_item_id;	
	 
	UPDATE user_course
	   SET schedule_course = 1
	 WHERE user_sid = v_user_sid
	   AND course_id = v_course_id;
END;

/*
	START: Standard procedure calls for flow_alert_class.helper_pkg (USED BY FLOW_PKG)
*/
FUNCTION GetFlowRegionSids(
	in_flow_item_id	IN csr.flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE
AS
	v_region_sids_t		security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT rsp.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM user_training ut
	  JOIN region_start_point rsp ON rsp.user_sid = ut.user_sid
	 WHERE ut.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ut.flow_item_id = in_flow_item_id;

	RETURN v_region_sids_t;
END;

/*
	Generate Alert entries based on Alert involvement type i.e. Course Trainee or Training Line manager
	Called from flow_pkg.GenerateAlertEntries
*/
PROCEDURE GenerateInvolmTypeAlertEntries(
	in_flow_item_id 				IN flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN security_pkg.T_SID_ID,
	in_flow_transition_alert_id  	IN flow_transition_alert.flow_transition_alert_id%TYPE,
	in_flow_involvement_type_id  	IN flow_involvement_type.flow_involvement_type_id%TYPE,
	in_flow_state_log_id 			IN flow_state_log.flow_state_log_id%TYPE,
	in_subject_override				IN flow_item_generated_alert.subject_override%TYPE DEFAULT NULL,
	in_body_override				IN flow_item_generated_alert.body_override%TYPE DEFAULT NULL
)
AS
	v_app_sid	NUMBER(10) := SYS_CONTEXT('security', 'app');
BEGIN
--	security.security_pkg.DebugMsg('Training: in_flow_item_id = ' || TO_CHAR(in_flow_item_id) 
--		|| ' in_flow_transition_alert_id = ' || TO_CHAR(in_flow_transition_alert_id)
--		|| ' in_flow_involvement_type_id = ' || TO_CHAR(in_flow_involvement_type_id)
--		|| ' in_flow_state_log_id = ' || TO_CHAR(in_flow_state_log_id));

	-- Handle separately as there may is only one trainee but there can be more than one line manager
	CASE
		WHEN in_flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_TRAINEE THEN

			--security.security_pkg.DebugMsg('Training csr_data_pkg.FLOW_INV_TYPE_TRAINEE');
	
			INSERT INTO flow_item_generated_alert 
					(
					app_sid,
					flow_item_generated_alert_id,
					flow_transition_alert_id,
					from_user_sid,
					to_user_sid,
					to_column_sid,
					flow_item_id,
					flow_state_log_id
					)
			 SELECT ut.app_sid,
					flow_item_gen_alert_id_seq.nextval,
					in_flow_transition_alert_id,
					in_set_by_user_sid,
					ut.user_sid,
					NULL,
					in_flow_item_id,
					in_flow_state_log_id
			   FROM user_training ut
			   WHERE ut.app_sid = v_app_sid
				 AND ut.flow_item_id = in_flow_item_id
				 AND NOT EXISTS( -- hasn't already been generated
						SELECT 1
						  FROM flow_item_generated_alert figa
						 WHERE figa.app_sid = ut.app_sid
						   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
						   AND figa.flow_state_log_id = in_flow_state_log_id
						   AND figa.to_user_sid = ut.user_sid
					  );

		WHEN in_flow_involvement_type_id = csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER THEN

			--security.security_pkg.DebugMsg('Training csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER');

			INSERT INTO flow_item_generated_alert 
					(
					app_sid,
					flow_item_generated_alert_id,
					flow_transition_alert_id,
					from_user_sid,
					to_user_sid,
					to_column_sid,
					flow_item_id,
					flow_state_log_id
					)
			 SELECT lm.app_sid,
					flow_item_gen_alert_id_seq.nextval,
					in_flow_transition_alert_id,
					in_set_by_user_sid,
					lm.line_manager_sid,
					NULL,
					in_flow_item_id,
					in_flow_state_log_id
			   FROM user_training ut
			   JOIN v$training_line_manager lm
						 ON lm.app_sid = ut.app_sid
						AND lm.course_id = ut.course_id
						AND lm.trainee_sid = ut.user_sid
			   WHERE ut.app_sid = v_app_sid
				 AND ut.flow_item_id = in_flow_item_id
				 AND NOT EXISTS( -- hasn't already been generated
						SELECT 1
						  FROM flow_item_generated_alert figa
						 WHERE figa.app_sid = lm.app_sid
						   AND figa.flow_transition_alert_id = in_flow_transition_alert_id
						   AND figa.flow_state_log_id = in_flow_state_log_id
						   AND figa.to_user_sid = lm.line_manager_sid
					  );
	END CASE;
END;

/*
	END: Standard procedure calls for flow_alert_class.helper_pkg (USED BY FLOW_PKG)
*/

/*
	TODO: Handle the case where the alert cannot be sent:
	
	1) Booking has been deleted
	2) Course schedule has been deleted
	3) Course has been deleted
	
	The query below will only return complete sets of data so maybe we just create a package to
	"cleanup generated alerts that 
*/

PROCEDURE GetFlowAlerts(
	out_cur	OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		 SELECT figa.app_sid,
				figa.flow_item_id,
				figa.flow_item_generated_alert_id,
				figa.customer_alert_type_id,
				figa.flow_transition_alert_id,
				figa.from_state_label,
				figa.to_state_label,
				t.last_flow_state_transition_id,
				figa.set_by_user_sid,
				figa.set_by_full_name,
				figa.set_by_email,
				figa.set_by_user_name,
				figa.to_user_sid,
				figa.to_user_name,
				figa.to_friendly_name, 
				figa.to_full_name, 
				figa.to_email,
				figa.comment_text,
				figa.to_initiator,
				figa.flow_alert_helper,
				t.user_sid trainee_user_sid,
				u.friendly_name trainee_friendly_name,
				u.full_name trainee_full_name,
				u.email trainee_email,
				ut.course_schedule_id,
				c.title course_title,
				c.reference,
				c.description course_description,
				training_pkg.GetUserCourseFunctions(t.user_sid, c.course_id) job_functions,
				e.start_dtm,
				e.end_dtm,
				cs.place_id
		   FROM v$open_flow_item_gen_alert figa
		   JOIN v$training_flow_item t
					 ON figa.flow_item_id = t.flow_item_id 
					AND t.app_sid = figa.app_sid
		   JOIN csr_user u
					ON u.csr_user_sid = t.user_sid
				   AND u.app_sid = t.app_sid
		   JOIN user_training ut ON ut.flow_item_id = t.flow_item_id
		   JOIN course c ON ut.course_id = c.course_id
		   JOIN course_schedule cs ON ut.course_schedule_id = cs.course_schedule_id
		   JOIN calendar_event e ON cs.calendar_event_id = e.calendar_event_id
	   ORDER BY figa.app_sid, figa.customer_alert_type_id, figa.to_user_sid, figa.flow_item_id;
END;

/* START: Flow Alert Helpers */
PROCEDURE IsCourseScheduleValid(
	in_flow_item_gen_alert_id	IN flow_item_generated_alert.flow_item_generated_alert_id%TYPE,
	in_flow_item_id				IN flow_state_log.flow_item_id%TYPE,
	in_set_by_user_sid			IN flow_state_log.set_by_user_sid%TYPE,
	in_user_sid					IN user_training.user_sid%TYPE,
	in_to_initiator				IN NUMBER,
	out_is_valid				OUT NUMBER
)
AS
BEGIN
	-- TODO: Check course is still valid, and schedule hasn't been deleted
	out_is_valid := 1;
END;

/* END: Flow Alert Helpers */

/* Other helpful procedures */
PROCEDURE SetupTransitionHelpers(
	in_flow_sid		IN 	security.security_pkg.T_SID_ID
)
AS
BEGIN
	-- Set up all the standard transition helpers.
	-- These are all absolutely required for a valid training workflow although customer specific versions may override them
	
	csr.flow_pkg.SetStateTransHelper(	
			in_flow_sid		=> in_flow_sid,
			in_helper_sp	=> 'csr.training_flow_helper_pkg.TransitionApproveBooking',
			in_label		=> 'Approve Booking'
		);

	csr.flow_pkg.SetStateTransHelper(	
			in_flow_sid		=> in_flow_sid,
			in_helper_sp	=> 'csr.training_flow_helper_pkg.TransitionUnApproveBooking',
			in_label		=> 'Unapprove Booking'
		);

	csr.flow_pkg.SetStateTransHelper(	
			in_flow_sid		=> in_flow_sid,
			in_helper_sp	=> 'csr.training_flow_helper_pkg.TransitionCourseValid',
			in_label		=> 'Course Valid'
		);

	csr.flow_pkg.SetStateTransHelper(	
			in_flow_sid		=> in_flow_sid,
			in_helper_sp	=> 'csr.training_flow_helper_pkg.TransitionReschedule',
			in_label		=> 'Reschedule course'
		);
		
	BEGIN
		INSERT INTO flow_alert_helper (app_sid, flow_alert_helper, label)
		VALUES (SYS_CONTEXT('SECURITY', 'APP'), 'csr.training_flow_helper_pkg.IsCourseScheduleValid', 'Is course schedule valid?');
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
		
END;

PROCEDURE SetupFlowInvolvementTypes
AS
	v_app_sid security.security_pkg.T_SID_ID;
BEGIN
	v_app_sid := sys_context('security','app');
	
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (app_sid, flow_alert_class)
		VALUES (v_app_sid, 'training');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	
	BEGIN
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_TRAINEE, 'training', 'Trainee', 'CSRUser');
		INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_TRAINEE, 'training');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	BEGIN
		INSERT INTO csr.flow_involvement_type (app_sid, flow_involvement_type_id, product_area, label, css_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER, 'training', 'Training line manager', 'CSRUser');
		INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
			VALUES (v_app_sid, csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER, 'training');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;

PROCEDURE SetupTrainingWorkflow(
	out_training_flow_sid	OUT flow.flow_sid%TYPE
)
AS
	v_workflow_sid			security.security_pkg.T_SID_ID;
	v_wf_ct_sid				security.security_pkg.T_SID_ID;
	v_cms_tab_sid			security.security_pkg.T_SID_ID;
	v_flow_type				VARCHAR2(256);
	v_s1					security.security_pkg.T_SID_ID;
	v_s2					security.security_pkg.T_SID_ID;
	v_s3					security.security_pkg.T_SID_ID;
	v_s4					security.security_pkg.T_SID_ID;
	v_s5					security.security_pkg.T_SID_ID;
	v_s6					security.security_pkg.T_SID_ID;
	v_s7					security.security_pkg.T_SID_ID;
	v_s8					security.security_pkg.T_SID_ID;
	v_s9					security.security_pkg.T_SID_ID;
	v_s10					security.security_pkg.T_SID_ID;
	v_r1					security.security_pkg.T_SID_ID;
	v_st1					security.security_pkg.T_SID_ID;
	v_st2					security.security_pkg.T_SID_ID;
	v_st3					security.security_pkg.T_SID_ID;
	v_st4					security.security_pkg.T_SID_ID;
	v_st5					security.security_pkg.T_SID_ID;
	v_st6					security.security_pkg.T_SID_ID;
	v_st7					security.security_pkg.T_SID_ID;
	v_st8					security.security_pkg.T_SID_ID;
	v_st9					security.security_pkg.T_SID_ID;
	v_st10					security.security_pkg.T_SID_ID;
	v_st11					security.security_pkg.T_SID_ID;
	v_st12					security.security_pkg.T_SID_ID;
	v_st13					security.security_pkg.T_SID_ID;
	v_st14					security.security_pkg.T_SID_ID;
	v_st15					security.security_pkg.T_SID_ID;
	v_cat1					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_frame0				csr.alert_frame.alert_frame_id%TYPE;
	v_cat2					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat3					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat4					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat5					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat6					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat7					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_cat8					csr.customer_alert_type.customer_alert_type_id%TYPE;
	v_i1					csr.flow_involvement_type.flow_involvement_type_id%TYPE;
	v_i2					csr.flow_involvement_type.flow_involvement_type_id%TYPE;

BEGIN
	BEGIN
		v_workflow_sid := security.securableobject_pkg.getsidfrompath(security.security_pkg.getact, security.security_pkg.getapp, 'Workflows/Training workflow');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			BEGIN
				v_wf_ct_sid:= security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Workflows');	
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please run csr\db\utils\enableworkflow.sql first');
			END;

			BEGIN
				SELECT cfac.flow_alert_class 
				  INTO v_flow_type
				  FROM csr.customer_flow_alert_class cfac
				  JOIN csr.flow_alert_class fac
				    ON cfac.flow_alert_class = fac.flow_alert_class
				 WHERE cfac.app_sid = security.security_pkg.GetApp
				   AND cfac.flow_alert_class = 'training';
			EXCEPTION 
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'Please enable the training module first');
			END; 
			
			-- create our workflow
			csr.flow_pkg.CreateFlow(
				in_label			=> 'Training workflow', 
				in_parent_sid		=> v_wf_ct_sid, 
				in_flow_alert_class	=> 'training',
				out_flow_sid		=> v_workflow_sid
			);
	END;
	

	
	-- Helpers
	SetupTransitionHelpers(v_workflow_sid);

	-- Get CMS Tab Sids.


	-- Initiate variables and populate temp tables
	v_s1 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'AVAILABLE'), csr.flow_pkg.GetNextStateID);
	v_s2 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_INVITED'), csr.flow_pkg.GetNextStateID);
	v_s3 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_REQUESTED'), csr.flow_pkg.GetNextStateID);
	v_s4 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'PRE_DECLINED'), csr.flow_pkg.GetNextStateID);
	v_s5 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'CONFIRMED'), csr.flow_pkg.GetNextStateID);
	v_s6 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_ATTENDED'), csr.flow_pkg.GetNextStateID);
	v_s7 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_MISSED'), csr.flow_pkg.GetNextStateID);
	v_s8 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'REQUEST_DELETED'), csr.flow_pkg.GetNextStateID);
	v_s9 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_PASSED'), csr.flow_pkg.GetNextStateID);
	v_s10 := NVL(csr.flow_pkg.GetStateId(v_workflow_sid, 'POST_FAILED'), csr.flow_pkg.GetNextStateID);

	csr.role_pkg.SetRole('Training Admin', v_r1);

	csr.alert_pkg.GetOrCreateFrame(UNISTR('Default'), v_frame0);
	csr.alert_pkg.SaveFrameBody(v_frame0, 'en', UNISTR('<template><table width="700"><tr><td><div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #C4D9E9;margin-bottom:20px;padding-bottom:10px;">CRedit360 Sustainability data management application</div><table border="0"><tr><td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;"><mergefield name="BODY" /></td></tr></table><div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #C4D9E9;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email <a href="mailto:support@credit360.com" style="color:#C4D9E9;text-decoration:none;">our support team</a></div></td></tr></table></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training invite (alert user)'), 'TRAINING_INVITE_ALERT_USER', v_frame0, 'manual', '', '',  0, v_cat1);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat1, 'en', UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has invited you to a training course
</template>'), UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has invited you to a training course.
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
</div>
<div><mergefield name="MY_BOOKING_URL" /><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training requested - Alert manager'), 'TRAINING_REQUESTED_ALERT_MANAGER', v_frame0, 'manual', '', '',  0, v_cat2);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat2, 'en', UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has requested a training course
</template>'), UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has requested a training course.
<div><br /></div>
<div><strong>Job functions</strong> : <mergefield name="JOB_FUNCTIONS" /></div>
<div><br /></div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_LINK" /> or copy and paste the link below into your browser for more information:</div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_URL" /><br /></div>
<div><br /></div>
<div><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training cancelled by trainee - Alert manager'), 'TRAINING_CANCELLED_ALERT_MANAGER', v_frame0, 'manual', '', '',  0, v_cat3);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat3, 'en', UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has cancelled a request
</template>'), UNISTR('<template>
<div><mergefield name="TRAINEE_FRIENDLY_NAME" /> has cancelled a request</div>
<div><br /></div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:<br /></div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_URL" /><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training declined - Alert user'), 'TRAINING_DECLINED_ALERT_USER', v_frame0, 'manual', '', '',  0, v_cat4);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat4, 'en', UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has declined your request for a training course
</template>'), UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has declined your request for a training course
<div><br />
<strong>Reason for decline</strong> : <mergefield name="COMMENT_TEXT" />
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_URL" /><br /></div>
<div><br /></div>
</div>
</div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training approved - Alert user'), 'training_approved_alert_user', v_frame0, 'manual', '', '',  0, v_cat5);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat5, 'en', UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has approved your request for a training course
</template>'), UNISTR('<template>
<div><mergefield name="FROM_FRIENDLY_NAME" /> has approved your request for a training course<br /></div>
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
</div>
<div><mergefield name="MY_BOOKING_URL" /><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training declined - Alert manager'), 'TRAINING_DECLINED_ALERT_MANAGER', v_frame0, 'manual', '', '',  0, v_cat6);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat6, 'en', UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has declined a training course
</template>'), UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has declined a training course
<div><br /></div>
<div><strong>Reason</strong> : <mergefield name="COMMENT_TEXT" /></div>
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
</div>
<div><mergefield name="EDIT_BOOKING_URL" /><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Training accepted - Alert manager'), 'TRAINING_ACCEPTED_ALERT_MANAGER', v_frame0, 'manual', '', '',  0, v_cat7);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat7, 'en', UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has accepted a training course
</template>'), UNISTR('<template>
<mergefield name="TRAINEE_FRIENDLY_NAME" /> has accepted a training course.
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /><br /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><br /></div>
<div><mergefield name="EDIT_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
</div>
<div><mergefield name="EDIT_BOOKING_URL" /><br /></div>
<div><br /></div>
</template>'), UNISTR('<template></template>'));
	csr.flow_pkg.SaveFlowAlertTemplate(v_workflow_sid, null, UNISTR('Confirmed training cancelled - Alert user'), 'CONFIRMED_CANCELLED_ALERT_USER', v_frame0, 'manual', '', '',  0, v_cat8);

	csr.flow_pkg.SaveFlowAlertTemplateBody(v_cat8, 'en', UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has cancelled your training course
</template>'), UNISTR('<template>
<mergefield name="FROM_FRIENDLY_NAME" /> has cancelled your training course.
<div><br /></div>
<div><strong>Reason for cancellation</strong> : <mergefield name="COMMENT_TEXT" /></div>
<div><br /></div>
<div>
<div><strong>Title</strong> : <mergefield name="COURSE_TITLE" /></div>
<div><strong>Reference</strong> : <mergefield name="COURSE_REF" /></div>
<div><strong>Description</strong> : <mergefield name="COURSE_DESCRIPTION" /></div>
<div><br /></div>
<div><strong>Start</strong> : <mergefield name="START_DTM" /></div>
<div><strong>End</strong> : <mergefield name="END_DTM" /></div>
<div><strong>Location</strong> : <mergefield name="LOCATION_DESC" /></div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_LINK" /> or copy and paste the link below into a browser for more information:</div>
<div><br /></div>
<div><mergefield name="MY_BOOKING_URL" /><br /></div>
</div>
</template>'), UNISTR('<template></template>'));

	v_i1 := csr_data_pkg.FLOW_INV_TYPE_TRAINEE;
	v_i2 := csr_data_pkg.FLOW_INV_TYPE_LINE_MANAGER;
	
	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_id => v_s1,
		in_label => 'Unscheduled',
		in_lookup_key => 'AVAILABLE',
		in_is_final => 0,
		in_state_colour => '16770048',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="176.2" y="899" />',
		in_flow_state_nature_id => 0);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Invite',
		in_lookup_key => 'INVITE',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st1);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st1,
		in_customer_alert_type_id => v_cat1,
		in_description => 'Training invite (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s1,
		in_to_state_id => v_s3,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_execute.png',
		in_verb => 'Request',
		in_lookup_key => 'USER_REQUEST',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => v_i1,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st2);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st2,
		in_customer_alert_type_id => v_cat2,
		in_description => 'Training requested (alert manager)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i2);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 1,
		in_flow_state_id => v_s3,
		in_label => 'Requested',
		in_lookup_key => 'PRE_REQUESTED',
		in_is_final => 0,
		in_state_colour => '16737792',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="309.2" y="1067" />',
		in_flow_state_nature_id => 1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s1,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Cancel',
		in_lookup_key => 'PRE_USER_CANCEL',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i1,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st3);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st3,
		in_customer_alert_type_id => v_cat3,
		in_description => 'Training cancelled (alert manager)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i2);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'required',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Decline',
		in_lookup_key => 'PRE_DECLINE_REQUEST',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st4);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st4,
		in_customer_alert_type_id => v_cat4,
		in_description => 'Training declined (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => 'csr.training_flow_helper_pkg.IsCourseScheduleValid',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s3,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Approve',
		in_lookup_key => 'APPROVE_REQUEST',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionApproveBooking',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st5);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st5,
		in_customer_alert_type_id => v_cat5,
		in_description => 'Training approved (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => 'csr.training_flow_helper_pkg.IsCourseScheduleValid',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 2,
		in_flow_state_id => v_s2,
		in_label => 'Invited',
		in_lookup_key => 'PRE_INVITED',
		in_is_final => 0,
		in_state_colour => '16737792',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="276.2" y="756" />',
		in_flow_state_nature_id => 1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'required',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Decline',
		in_lookup_key => 'USER_DECLINE',
		in_helper_sp => '',
		in_role_sids => null,
		in_column_sids => null,
		in_involved_type_ids => v_i1,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st6);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st6,
		in_customer_alert_type_id => v_cat6,
		in_description => 'Training declined (alert manager)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => 'csr.training_flow_helper_pkg.IsCourseScheduleValid',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i2);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s2,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Accept',
		in_lookup_key => 'USER_CONFIRM_INVITE',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionApproveBooking',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i1,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st7);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st7,
		in_customer_alert_type_id => v_cat7,
		in_description => 'Training accepted (alert manager)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i2);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 3,
		in_flow_state_id => v_s5,
		in_label => 'Confirmed',
		in_lookup_key => 'CONFIRMED',
		in_is_final => 0,
		in_state_colour => '6140965',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="697.2" y="756" />',
		in_flow_state_nature_id => 2);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 7,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s6,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Confirm attendance',
		in_lookup_key => 'CONFIRM_ATTENDANCE',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st8);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 8,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s7,
		in_ask_for_comment => 'required',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Confirm missed',
		in_lookup_key => 'CONFIRM_MISSED',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionReschedule',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st9);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 9,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s5,
		in_to_state_id => v_s4,
		in_ask_for_comment => 'required',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Cancel',
		in_lookup_key => 'CANCEL',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionUnApproveBooking',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st10);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st10,
		in_customer_alert_type_id => v_cat8,
		in_description => 'Confirmed training cancelled (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => 'csr.training_flow_helper_pkg.IsCourseScheduleValid',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 4,
		in_flow_state_id => v_s4,
		in_label => 'Declined',
		in_lookup_key => 'PRE_DECLINED',
		in_is_final => 0,
		in_state_colour => '16712965',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="538.2" y="1065" />',
		in_flow_state_nature_id => 1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 0,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s8,
		in_ask_for_comment => 'none',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '',
		in_verb => 'Delete',
		in_lookup_key => '',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st11);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 10,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s5,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Approve',
		in_lookup_key => 'APPROVE_DECLINED',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionApproveBooking',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st12);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st12,
		in_customer_alert_type_id => v_cat5,
		in_description => 'Declined training approved (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 11,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s4,
		in_to_state_id => v_s2,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_redo.png',
		in_verb => 'Resend',
		in_lookup_key => 'RESEND_INVITATION',
		in_helper_sp => '',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st13);

	csr.flow_pkg.SetTempFlowTransAlert(
		in_flow_sid => v_workflow_sid,
		in_flow_transition_alert_id => null,
		in_flow_state_transition_id => v_st13,
		in_customer_alert_type_id => v_cat1,
		in_description => 'Training invite resent (alert user)',
		in_to_initiator => 0,
		in_can_edit_before_send => 0,
		in_helper_sp  => '',
		in_flow_cms_cols => null,
		in_user_sids => null,
		in_role_sids => null,
		in_group_sids => null,
		in_alert_manager_flags => '',
		in_involved_type_ids => v_i1);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 5,
		in_flow_state_id => v_s6,
		in_label => 'Attended',
		in_lookup_key => 'POST_ATTENDED',
		in_is_final => 0,
		in_state_colour => '1921478',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1036.2" y="760" />',
		in_flow_state_nature_id => 3);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 12,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s9,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_tick.gif',
		in_verb => 'Confirm pass',
		in_lookup_key => 'CONFIRM_PASSED',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionCourseValid',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st14);

	csr.flow_pkg.SetTempFlowStateTrans(
		in_flow_sid => v_workflow_sid,
		in_pos => 13,
		in_flow_state_transition_id => null,
		in_from_state_id => v_s6,
		in_to_state_id => v_s10,
		in_ask_for_comment => 'optional',
		in_mandatory_fields_message => '',
		in_hours_before_auto_tran => null,
		in_button_icon_path => '/fp/shared/images/ic_cross.gif',
		in_verb => 'Confirm fail',
		in_lookup_key => 'CONFIRM_FAIL',
		in_helper_sp => 'csr.training_flow_helper_pkg.TransitionReschedule',
		in_role_sids => v_r1,
		in_column_sids => null,
		in_involved_type_ids => v_i2,
		in_group_sids => null,
		in_attributes_xml => null,
		out_flow_state_transition_id => v_st15);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 6,
		in_flow_state_id => v_s7,
		in_label => 'Missed',
		in_lookup_key => 'POST_MISSED',
		in_is_final => 1,
		in_state_colour => '16737792',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1048.2" y="1014" />',
		in_flow_state_nature_id => 3);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 7,
		in_flow_state_id => v_s9,
		in_label => 'Completed',
		in_lookup_key => 'POST_PASSED',
		in_is_final => 1,
		in_state_colour => '6140965',
		in_editable_role_sids => v_r1,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i1||','||v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1300.2" y="760" />',
		in_flow_state_nature_id => 3);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 8,
		in_flow_state_id => v_s10,
		in_label => 'Failed',
		in_lookup_key => 'POST_FAILED',
		in_is_final => 1,
		in_state_colour => '',
		in_editable_role_sids => null,
		in_non_editable_role_sids => v_r1,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => v_i2,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="1307.2" y="1014" />',
		in_flow_state_nature_id => 3);

	csr.flow_pkg.SetTempFlowState(
		in_flow_sid => v_workflow_sid,
		in_pos => 9,
		in_flow_state_id => v_s8,
		in_label => 'Request Deleted',
		in_lookup_key => 'REQUEST_DELETED',
		in_is_final => 0,
		in_state_colour => '16712965',
		in_editable_role_sids => null,
		in_non_editable_role_sids => null,
		in_editable_col_sids => null,
		in_non_editable_col_sids => null,
		in_involved_type_ids => null,
		in_editable_group_sids => null,
		in_non_editable_group_sids => null,
		in_attributes_xml => '<?xml version="1.0"?><attributes xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" x="538" y="1203" />',
		in_flow_state_nature_id => 4);
		
	csr.flow_pkg.SetFlowFromTempTables(
		in_flow_sid => v_workflow_sid,
		in_flow_label => 'Training workflow',
		in_flow_alert_class => 'training',
		in_cms_tab_sid => v_cms_tab_sid,
		in_default_state_id => v_s1);
	
	out_training_flow_sid := v_workflow_sid;
END;

END training_flow_helper_pkg;
/

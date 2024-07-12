CREATE OR REPLACE PACKAGE CSR.Training_Pkg
IS

QUERY_TYPE_AVAILABLE		CONSTANT NUMBER(10) := 0;
QUERY_TYPE_BOOKINGS			CONSTANT NUMBER(10) := 1;
QUERY_TYPE_ALL_SCHEDULES	CONSTANT NUMBER(10) := 2;

DELIVERY_ONLINE			CONSTANT NUMBER(1) := 1;
DELIVERY_ON_LOCATION	CONSTANT NUMBER(1) := 2;

ERR_TRAINING_FLOW_NOT_CONFIG	CONSTANT NUMBER := -20001;
ERR_USER_TRAINING_EXISTS		CONSTANT NUMBER := -20002;
ERR_USER_TRAINING_DOESNT_EXIST	CONSTANT NUMBER := -20003;
ERR_MANAGER_NOT_FOUND			CONSTANT NUMBER := -20004;
ERR_WRONG_PASSWORD				CONSTANT NUMBER := -20005;
ERR_COURSE_FULL					CONSTANT NUMBER := -20006;

-- Legacy Constants
USER_LEVEL_TRAINEE	CONSTANT NUMBER := 0;
USER_LEVEL_MANAGER	CONSTANT NUMBER := 1;
USER_LEVEL_ADMIN	CONSTANT NUMBER := 2;


TYPE T_CACHE_KEYS IS TABLE OF aspen2.filecache.cache_key%TYPE INDEX BY PLS_INTEGER;

/* *
 * Temporary helper: Check if the course has been attended and if no pass/fail is required, push to completed state
 * This is only required because the logic is currently missing. This should become redundant once the logic is fixed.
 */
PROCEDURE CheckAutoComplete(
	in_flow_item_id			IN flow_item.flow_item_id%TYPE
);

/* *
 * Get training workflow sid for this customer app
 */
FUNCTION GetFlowSid RETURN NUMBER;

/* *
 * GetManager:
 * 
 * Get a users' line manager (user SID) according to the course type using the course schedule ID
 */
FUNCTION GetManager(
	in_user_sid				IN	NUMBER,
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE
)
RETURN NUMBER;

/* *
 * Get the job function descriptions for a given course and user (concatenated, comma separated varchar2)
 * 
 * Ordered by course function priority. Returns NULL if there are no relevent job function combinations
 */
FUNCTION GetUserCourseFunctions(
	in_user_sid		IN	user_course.user_sid%TYPE,
	in_course_id	IN	course.course_id%TYPE
)
RETURN VARCHAR2;

/* *
 * Is a course schedule open for booking:
 * 
 * Centralised logic for quickly determining if a course can be booked based on 
 * delivery method and date i.e. 
 *   - Coursese at location: Today must be between start and end dates
 *   - Online courses: Today must be before end date.
 */
FUNCTION IsBookingOpen(
	in_start_dtm		IN DATE,
	in_end_dtm			IN DATE,
	in_delivery_method	IN delivery_method.delivery_method_id%TYPE
)
RETURN NUMBER;

/* *
 * Does the course region match the user's region mount points? ***THIS LOGIC WILL BE EXPANDED WHEN THERE ARE MULTIPLE REGIONS ADDED PER COURSE ***
 *
 * RETURN 1 = Yes, 0 = No
 * 
 * Find if the regions associated with this course match any regions associated with this user.
 * It's not a straight match, one of the user's regions may fall within the course region sid (or child there of), or vice verse!
 * The function matches up both region trees to see if there are any matching regions.
 * 
 * @param in_course_region_sid		region sid for the course
 * @param in_trainee_sid			User SID for the trainee
* 
 */
FUNCTION UserCourseRegionExists(
	in_course_region_sid	IN course.region_sid%TYPE,
	in_trainee_sid			IN user_training.user_sid%TYPE
)
RETURN NUMBER;

/* *
 * Get table of courses that are NOT available for booking.(app_sid, user_sid, course_sid)
 * 
 * Centralised logic for determining which courses are NOT available for booking so they can be used in multiple queries.
 * Not available if:
 *
 * User already has a bookings for this course
 * OR User has completed this course and it is not yet due for renewal
 */
FUNCTION CoursesNotAvailableAsTable(
	in_user_sid		IN user_training.user_sid%TYPE
)
RETURN T_TRAINING_USER_COURSE_TABLE;

/* *
 * Get Flow States which are visible a given involvement type OR role membership (using the provided user_sid)
 * 
 * @param in_involvement_type_id	Filter by Involvement type 
 * @param in_by_role_user_sid		For a given user, check against roles memberships
 */
FUNCTION GetFlowStatesAsTable(
	in_involvement_type_id	IN flow_involvement_type.flow_involvement_type_ID%TYPE,
	in_by_role_user_sid		IN csr_user.csr_user_sid%TYPE
)
RETURN T_TRAINING_FLOW_STATE_TABLE;

/* *
 * Get Flow States which are visible a given involvement type OR role membership (using the provided user_sid)
 * Uses the above function
 * 
 * @param in_involvement_type_id	Filter by Involvement type 
 * @param in_by_role_user_sid		For a given user, check against roles memberships
 */
PROCEDURE GetFlowStates(
	in_involvement_type_id	IN flow_involvement_type.flow_involvement_type_ID%TYPE,
	in_by_role_user_sid		IN csr_user.csr_user_sid%TYPE,
	out_curr				OUT SYS_REFCURSOR
);

/* *
 * Cleanly delete a user's course booking
 * 
 * @param in_user_sid				User SID
 * @param in_course_id				Course ID
 * @param in_course_schedule_id		Course schedule ID
 * @param in_flow_item_id			Flow item ID 
 */
PROCEDURE DeleteBooking(
	in_user_sid				IN user_training.user_sid%TYPE,
	in_course_id			IN user_training.course_id%TYPE,
	in_course_schedule_id	IN user_training.course_schedule_id%TYPE,
	in_flow_item_id			IN user_training.flow_item_id%TYPE
);

/* START: PROCEDURES FOR SCHEDULED TASKS ***/

/* *
 * Delete unapproved bookings that have expired i.e. the course dates have passed
 */
PROCEDURE DeleteOldUnapprovedBookings;

--PROCEDURE ExpireCompletedCourses;

/* END: PROCEDURES FOR SCHEDULED TASKS */

/* *
 * Get Flow State transitions available to training users
 * 
 * @param out_transitions_cur			Course details
 */
PROCEDURE GetTraineeFlowTransitions(
	out_transitions_cur		OUT SYS_REFCURSOR
);

/* *
 * Get list of Course Booking States (Flow states) and the count of bookings (flow state items) in each state
 * 
 * @param in_csr_user_sid		
 */
PROCEDURE GetUserBookingSummary(
	in_user_sid	IN user_training.user_sid%TYPE,
	out_cur		OUT SYS_REFCURSOR
);

/* *
 * For a given user, get summary of available courses by priority
 * Includes: Scheduled courses with dates available in the future (1 count per course, not course + date)
 * Excludes: Any course they are in the process of booking or have completed.
 *
 * @param in_csr_user_sid		
 */
PROCEDURE GetAvailableCoursesSummary(
	in_csr_user_sid	IN csr_user.csr_user_sid%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

/* *
 * Collect Available Course (IDs) into temp_user_course_filter table
 * This can then be used to get lists of courses or summary counts
 * 
 * @param in_trainee_sid			Filter by trainee
 * @param in_open_courses_only		Filter out courses with no schedules or schedule in the past
 * @param in_user_level				Used for permissions over records returned
 * @param in_training_priority_id	Filter by training_priority 
 */
PROCEDURE FilterAvailableCourses(
	in_trainee_sid				IN csr_user.csr_user_sid%TYPE,
	in_open_courses_only		IN NUMBER,
	in_user_level				IN NUMBER,
	in_training_priority_id		IN training_priority.training_priority_id%TYPE
);

/* *
 * Collect Bookings (Courses) into temp_user_course_filter table for a given user
 * This can then be used to get lists of courses or summary counts
 * 
 * @param in_trainee_sid			Filter by trainee
 * @param in_user_level				Used for permissions over records returned
 * @param in_flow_state_id			Filter by flow_state_id
 */
PROCEDURE FilterUserBookings(
	in_trainee_sid			IN user_training.user_sid%TYPE,
	in_user_level			IN NUMBER,
	in_flow_state_id		IN flow_state.flow_state_id%TYPE
);

/* *
 * Collect All course schedules into temp_user_course_filter table for a given user (level)
 * 
 * @param in_user_level			Used for permissions over records returned
 * @param in_course_type_id		Filter by Course Type
 * @param in_function_id		Filter by Function
 * @param in_status_id			Filter by Status
 * @param in_provision_id		Filter by Provision
 * @param in_region_sid			Filter by Region
 */
PROCEDURE FilterAllSchedules(
	in_user_level				IN NUMBER,
	in_course_type_id			IN course.course_type_id%TYPE,
	in_function_id				IN function_course.function_id%TYPE,
	in_status_id				IN course.status_id%TYPE,
	in_provision_id				IN course.provision_id%TYPE,
	in_region_sid				IN course.region_sid%TYPE
);

/* *
 * Get Courses for user 
 * 
 * @param in_csr_user_sid
 * @param in_training_priority_id		Optionally filter on a in_training_priority_id 
 * @param in_current_state_id			Optionally filter on a flow_state_id 
 * @param in_course_query				Type of query for user: 0 = Available Courses, 1 = User bookings
 * @param out_total						Total number of results returned by query
 * @param out_courses_cur				Course details
 * @param out_course_job_function_cur	Job functions for this user and courses
 * @param out_schedules_cur				Course schedules (dates)
 * @param out_transitions_cur			Transitions available for each state
 */
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
);

/* *
 * Get Available Courses for user (Exclude all courses in bookings)
 * 
 * @param in_csr_user_sid
 * @param in_training_priority_id		Optionally filter on a in_training_priority_id 
 * @param out_total						Total number of results returned by query
 * @param out_courses_cur				Course details
 * @param out_course_job_function_cur	Job functions for this user and courses
 * @param out_schedules_cur				Course schedules (dates)
 
 */
PROCEDURE GetUserAvailableCourses(
	in_csr_user_sid				IN csr_user.csr_user_sid%TYPE,
	in_training_priority_id		IN training_priority.training_priority_id%TYPE,
	out_total					OUT SYS_REFCURSOR,
	out_courses_cur				OUT SYS_REFCURSOR,
	out_course_job_function_cur OUT SYS_REFCURSOR,
	out_schedules_cur			OUT SYS_REFCURSOR,
	out_transitions_cur			OUT SYS_REFCURSOR
);

/* *
 * Get all user bookings
 * 
 * @param in_csr_user_sid
 * @param in_current_state_id			Optionally filter on a flow_state_id 
 * @param out_total						Total number of results returned by query
 * @param out_courses_cur				Course details
 * @param out_course_job_function_cur	Job functions for this user and courses
 * @param out_schedules_cur				Course schedules (dates)
 */
PROCEDURE GetUserBookings(
	in_csr_user_sid				IN csr_user.csr_user_sid%TYPE,
	in_current_state_id			IN flow_item.current_state_id%TYPE,
	out_total					OUT SYS_REFCURSOR,
	out_courses_cur				OUT SYS_REFCURSOR,
	out_course_job_function_cur OUT SYS_REFCURSOR,
	out_schedules_cur			OUT SYS_REFCURSOR,
	out_transitions_cur			OUT SYS_REFCURSOR
);

/* *
 * Get states and transitions available to trainee user
 * 
 * @param out_states_cur				Total number of results returned by query
 * @param out_transitions_cur			Course details
 */
PROCEDURE GetTraineeFlowStates(
	out_default_state_id	OUT NUMBER,
	out_states_cur 			OUT SYS_REFCURSOR,
	out_transitions_cur		OUT SYS_REFCURSOR
);

/* *
 * Set user training (a course booking) to a new flow state (Overload)
 * 
 * @param in_user_sid					user SID
 * @param in_course_schedule_id			Course schedule ID
 * @param in_to_state_id				Flow state to transition to
 */
PROCEDURE SetUserTrainingState(
	in_user_sid					IN user_training.user_sid%TYPE,
	in_course_schedule_id		IN course_schedule.course_schedule_id%TYPE,
	in_to_state_id				IN flow_state.flow_state_id%TYPE,
	in_reason					IN flow_state_log.comment_text%TYPE
);

/* *
 * Set user training (a course booking) to a new flow state
 * 
 * @param in_flow_item_id				user_training.flow_item_id, can be null if it represents the initial starting state
 * @param in_user_sid					user SID
 * @param in_course_schedule_id			Course schedule ID
 * @param in_to_state_id				Flow state to move to
 * @param in_flow_state_transition_id	Flow state transition to move via
 */
PROCEDURE SetUserTrainingState(
	in_flow_item_id				IN user_training.flow_item_id%TYPE,
	in_user_sid					IN user_training.user_sid%TYPE,
	in_course_schedule_id		IN course_schedule.course_schedule_id%TYPE,
	in_flow_state_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE,
	in_to_state_id				IN flow_state.flow_state_id%TYPE,
	in_reason					IN flow_state_log.comment_text%TYPE
);

/* FOR REFERENCE: OLD CODE STARTS HERE */

PROCEDURE AcceptUserTraining(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE
);

PROCEDURE ClearCourseTypeRegions(
	in_course_type_id			IN course_type_region.course_type_id%TYPE
);

PROCEDURE ClearJobFunctionsForCourse(
	in_course_id	IN function_course.course_id%TYPE
);

PROCEDURE CreateUserTraining(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_is_invite			IN 	NUMBER,
	in_comment_text			IN	flow_state_log.comment_text%TYPE
);

PROCEDURE DeclineUserTraining(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_reason				IN	VARCHAR2
);

PROCEDURE DeleteCourse(
	in_course_id				IN course.course_id%TYPE
);

PROCEDURE DeleteCourseType(
	in_course_type_id	IN course_type.course_type_id%TYPE
);

PROCEDURE DeleteFunctionCourse(
	in_function_id				IN function_course.function_id%TYPE,
	in_course_id				IN function_course.course_id%TYPE,
	out_alert_details			OUT SYS_REFCURSOR	
);

PROCEDURE DeleteSchedule(
	in_course_schedule_id	IN course_schedule.course_schedule_id%TYPE,
	out_alert_details		OUT SYS_REFCURSOR
);
	
PROCEDURE DeleteTrainer(
	in_trainer_id	IN trainer.trainer_id%TYPE
);

PROCEDURE DeleteUserTraining(
	in_course_schedule_id		IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid					IN	user_training.user_sid%TYPE
);

PROCEDURE CancelUserTraining(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE
);

PROCEDURE GetActiveCourses(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetAlertDetails(
	in_user_sid				IN  NUMBER,
	in_manager_sid			IN  NUMBER,
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	out_alert_details		OUT	SYS_REFCURSOR
);

PROCEDURE GetAllCourses(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetAllItemsWithTransitionsMap(
	in_region_sid			IN	course.region_sid%TYPE,
	out_user_trainings		OUT SYS_REFCURSOR,
	out_states				OUT SYS_REFCURSOR,
	out_transitions 		OUT	SYS_REFCURSOR
);

PROCEDURE GetCalendars(
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetCourse(
	in_course_id	IN course.course_id%TYPE,
	out_cur 		OUT SYS_REFCURSOR
);

PROCEDURE GetCourseFunctionOptions(
	out_cur_functions 		OUT SYS_REFCURSOR,
	out_cur_courses 		OUT SYS_REFCURSOR,
	out_cur_priorities		OUT SYS_REFCURSOR
);

PROCEDURE GetCourseOptions(
	out_cur_course_types 		OUT SYS_REFCURSOR,
	out_cur_trainers 			OUT SYS_REFCURSOR,
	out_cur_places 				OUT SYS_REFCURSOR,
	out_cur_jobfunctions 		OUT SYS_REFCURSOR,
	out_cur_provisions 			OUT SYS_REFCURSOR,
	out_cur_statuses 			OUT SYS_REFCURSOR,
	out_cur_delivery_methods 	OUT SYS_REFCURSOR,
	out_cur_priorities			OUT SYS_REFCURSOR
);

PROCEDURE GetCoursesForDataExport(
	out_curses 			OUT SYS_REFCURSOR
);

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
);

PROCEDURE GetCoursesForJobFunction(
	in_function_id	IN function_course.function_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetCourseTypeOptions(
	out_cur_relationships 		OUT SYS_REFCURSOR
);

PROCEDURE GetCourseTypes(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetCourseTypesWithRegions(
	out_course_types 			OUT SYS_REFCURSOR,
	out_course_type_regions 	OUT SYS_REFCURSOR
);

PROCEDURE GetExpiryReminders(
    out_cur    OUT  SYS_REFCURSOR
);

PROCEDURE GetFlowItemsForSchedule(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	out_user_trainings		OUT	SYS_REFCURSOR,
	out_states 				OUT	SYS_REFCURSOR,
	out_transitions			OUT	SYS_REFCURSOR,
	out_users				OUT SYS_REFCURSOR
);

PROCEDURE GetJobFunctionsForCourse(
	in_course_id	IN course.course_id%TYPE,
	out_cur			OUT SYS_REFCURSOR
);

FUNCTION GetLatestCalendarEvent(
	in_course_id	NUMBER,
	in_user_id		NUMBER
) RETURN NUMBER;

PROCEDURE GetManagedUsersForSchedule(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	out_managed_users		OUT SYS_REFCURSOR
);

PROCEDURE GetManagerEscalationReminders(
    out_cur    OUT  SYS_REFCURSOR
);

PROCEDURE GetRegionsForCourseType(
	in_course_type_id	IN	course_type.course_type_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetReport_Attendence(
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetReport_Deficiency(
	out_cur				OUT SYS_REFCURSOR
);

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
	in_user_level			IN	NUMBER,
	out_course_schedules	OUT SYS_REFCURSOR
);

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
	in_user_level			IN	NUMBER,
	out_total				OUT SYS_REFCURSOR,
	out_course_schedules	OUT SYS_REFCURSOR,
	out_courses 			OUT SYS_REFCURSOR,
	out_job_functions 		OUT SYS_REFCURSOR
);

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
);

PROCEDURE GetSingleScheduleForGrid(
	in_user_sid				IN NUMBER,
	in_course_schedule_id	IN NUMBER,
	in_user_level			IN NUMBER,
	out_schedules			OUT	SYS_REFCURSOR,
	out_courses				OUT	SYS_REFCURSOR
);

PROCEDURE GetTrainers(
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetTrainingMapSid(
	out_map_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE GetTrainingReminders(
    out_cur    OUT  SYS_REFCURSOR
);

PROCEDURE GetUserTrainingStatus(
	in_course_schedule_id	IN  course_schedule.course_schedule_id%TYPE,
	out_item_state 			OUT	SYS_REFCURSOR,
	out_transitions			OUT	SYS_REFCURSOR
);

FUNCTION GetLatestCompleteCalendarEvent(
	in_course_id	NUMBER,
	in_user_id		NUMBER
) RETURN NUMBER;

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
);

PROCEDURE SaveCourseType(
	in_course_type_id				IN course_type.course_type_id%TYPE,
	in_label						IN course_type.label%TYPE,
	in_user_relationship_type_id	IN course_type.user_relationship_type_id%TYPE,
	out_course_type_id				OUT course_type.course_type_id%TYPE
);

PROCEDURE SaveCourseTypeRegion(
	in_course_type_id			IN course_type_region.course_type_id%TYPE,
	in_region_sid				IN course_type_region.region_sid%TYPE
);

PROCEDURE SaveFunctionCourse(
	in_function_id				IN function_course.function_id%TYPE,
	in_course_id				IN function_course.course_id%TYPE,
	in_training_priority_id		IN function_course.training_priority_id%TYPE,
	out_alert_details			OUT SYS_REFCURSOR	
);

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
);

PROCEDURE SaveTrainer(
	in_trainer_id		IN trainer.trainer_id%TYPE,
	in_name				IN trainer.name%TYPE,
	in_user_sid			IN trainer.user_sid%TYPE,
	in_company			IN trainer.company%TYPE,
	in_address			IN trainer.address%TYPE,
	in_contact_details	IN trainer.contact_details%TYPE,
	in_notes			IN trainer.notes%TYPE,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE SetAttendance(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_attended				IN  NUMBER,
	in_reason				IN	VARCHAR2,
	in_manager				IN	NUMBER
);

PROCEDURE SetPassed(
	in_course_schedule_id	IN	course_schedule.course_schedule_id%TYPE,
	in_user_sid				IN	user_training.user_sid%TYPE,
	in_passed				IN  NUMBER,
	in_score				IN  user_training.score%TYPE
);

PROCEDURE GetTrainingMatrixData(
	in_course_id		IN	NUMBER,
	in_function_id		IN	NUMBER,
	in_course_type_id	IN	NUMBER,
	in_priority_id		IN	NUMBER,
	out_xaxis			OUT SYS_REFCURSOR,
	out_yaxis			OUT SYS_REFCURSOR,
	out_data			OUT SYS_REFCURSOR
);

PROCEDURE DeleteTrainingCourseFiles(
	in_course_id				IN	course.course_id%TYPE,
	in_current_file_uploads		IN	security_pkg.T_SID_IDS,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE InsertTrainingCourseFiles(
	in_course_id				IN	course.course_id%TYPE,
	in_new_file_uploads			IN	T_CACHE_KEYS,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTrainingCourseFile(
	in_course_file_data_id		IN	course_file_data.course_file_data_id%TYPE,
	in_sha1						IN  course_file_data.sha1%TYPE,
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetTrainingCourseFiles(
	in_course_id		IN	course.course_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

END Training_Pkg;
/

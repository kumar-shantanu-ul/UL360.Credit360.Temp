CREATE OR REPLACE PACKAGE CSR.training_flow_helper_pkg
IS

ERR_TRAINING_FLOW_NOT_CONFIG	CONSTANT NUMBER := -20001;
ERR_USER_TRAINING_EXISTS		CONSTANT NUMBER := -20002;
ERR_USER_TRAINING_DOESNT_EXIST	CONSTANT NUMBER := -20003;
ERR_MANAGER_NOT_FOUND			CONSTANT NUMBER := -20004;
ERR_WRONG_PASSWORD				CONSTANT NUMBER := -20005;
ERR_COURSE_FULL					CONSTANT NUMBER := -20006;

/* STANDARD FLOW TRANSITION HELPERS */
/* *
 * Workflow helper for approving bookings
 * 
 * @param in_flow_sid				Flow SID
 * @param in_flow_item_id			Flow item ID
 * @param in_flow_state_id			Flow state ID
 */
PROCEDURE TransitionApproveBooking(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE TransitionUnApproveBooking(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE TransitionCourseValid(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE TransitionCourseExpired(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

PROCEDURE TransitionReschedule(
	in_flow_sid                 IN  security.security_pkg.T_SID_ID,
	in_flow_item_id             IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id            IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id              IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key    IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text             IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid                 IN  security.security_pkg.T_SID_ID
);

/*
	START: STANDARD PROCEDURE CALLS FOR flow_alert_class.helper_pkg (USED BY FLOW_PKG)
*/
FUNCTION GetFlowRegionSids(
	in_flow_item_id	IN csr.flow_item.flow_item_id%TYPE
)
RETURN security.T_SID_TABLE;

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
);

/*
	END: Standard procedure calls for flow_alert_class.helper_pkg (USED BY FLOW_PKG)
*/

/*
 *	Get the flow alert details for the training module 
 * */
PROCEDURE GetFlowAlerts(
	out_cur	OUT	security.security_pkg.T_OUTPUT_CUR
);

/* START: Flow Alert Helpers */
PROCEDURE IsCourseScheduleValid(
	in_flow_item_gen_alert_id	IN flow_item_generated_alert.flow_item_generated_alert_id%TYPE,
	in_flow_item_id				IN flow_state_log.flow_item_id%TYPE,
	in_set_by_user_sid			IN flow_state_log.set_by_user_sid%TYPE,
	in_user_sid					IN user_training.user_sid%TYPE,
	in_to_initiator				IN NUMBER,
	out_is_valid				OUT NUMBER
);

/* END: Flow Alert Helpers */

PROCEDURE SetupFlowInvolvementTypes;

PROCEDURE SetupTransitionHelpers(
	in_flow_sid		IN 	security.security_pkg.T_SID_ID
);

/* *
 * Set up the standard training workflow. Called from the enable package.
 * 
 * @param out_training_flow_sid		Flow SID of training workflow once created.
 */
PROCEDURE SetupTrainingWorkflow(
	out_training_flow_sid	OUT flow.flow_sid%TYPE
);

END training_flow_helper_pkg;
/
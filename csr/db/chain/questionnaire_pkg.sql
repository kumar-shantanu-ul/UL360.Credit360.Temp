CREATE OR REPLACE PACKAGE CHAIN.questionnaire_pkg
IS

--(made public for bettercoal.link_pkg)
FUNCTION QnrTypeRequiresReview (
	in_questionnaire_type_id	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER;

PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireTypeFromName (
	in_name						IN  questionnaire_type.name%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

FUNCTION GetQuestionnaireTypeIdFromName (
	in_name					IN  questionnaire_type.name%TYPE
) RETURN NUMBER;

PROCEDURE GetQuestionnaireByQnrId (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	out_cur						OUT security.security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetQuestionnaires (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	out_questionnaires_cur		OUT security_pkg.T_OUTPUT_CUR,	
	out_invitations_cur			OUT security_pkg.T_OUTPUT_CUR	
);

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE	
) RETURN NUMBER;

PROCEDURE SendQuestionnaire (
	in_questionnaire_type_class		IN	questionnaire_type.class%TYPE,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_requested_due_dtm			IN	questionnaire_share.due_by_dtm%TYPE
);

PROCEDURE SendQuestionnaire (
	in_questionnaire_type_class		IN	questionnaire_type.class%TYPE,
	in_to_company_sid				IN	security_pkg.T_SID_ID,
	in_from_company_sid				IN	security_pkg.T_SID_ID,
	in_requested_due_dtm			IN	questionnaire_share.due_by_dtm%TYPE,
	in_component_id					IN component.component_id%TYPE
);

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
);

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN;

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
);

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE,
	out_exists					OUT NUMBER
);

FUNCTION QuestionnaireTypeIsActive (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN;

FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN NUMBER;

FUNCTION GetQuestionnaireTypeClass(
	in_survey_sid					IN  security_pkg.T_SID_ID
) RETURN questionnaire_type.class%TYPE;

PROCEDURE GetQuestionnaireShareWith (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_component_id			IN	 component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE	
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS;

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE	
) RETURN chain_pkg.T_SHARE_STATUS;

FUNCTION UNSEC_GetQnnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_SHARE_STATUS;

PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);

PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id			IN	 component.component_id%TYPE
);

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE	
);

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id			IN	 component.component_id%TYPE	
);

-- Internal/helper proc use - skips check on state change access if owner / purchaser
-- BUT will still check that user is a owner / purchaser and that the new state is valid
PROCEDURE UNSEC_SetQnrShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);

PROCEDURE UNSEC_SetQnrShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE,
	in_component_id			IN	 component.component_id%TYPE
);

PROCEDURE UNSEC_ReactivateQuestionnaire (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN component.component_id%TYPE
);

PROCEDURE GetQManagementData (
	in_company_sids		security_pkg.T_SID_IDS,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductManagementData (
	in_company_sids		security_pkg.T_SID_IDS,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyQuestionnaires (
	in_status			IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_view_url					IN	questionnaire_type.view_url%TYPE,
	in_edit_url					IN	questionnaire_type.edit_url%TYPE,
	in_owner_can_review			IN	questionnaire_type.owner_can_review%TYPE,
	in_name						IN	questionnaire_type.name%TYPE,
	in_class					IN	questionnaire_type.CLASS%TYPE,
	in_db_class					IN	questionnaire_type.db_class%TYPE,
	in_group_name				IN	questionnaire_type.group_name%TYPE,
	in_position					IN	questionnaire_type.position%TYPE,
	in_requires_review			In	questionnaire_type.requires_review%TYPE DEFAULT 1
);

PROCEDURE HideQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
);

PROCEDURE RenameQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_name						IN	questionnaire_type.name%TYPE	
);

FUNCTION IsQuestionnaireTypeVisible (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER;

PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
);

PROCEDURE RetractQuestionnaire (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE RetractQuestionnaire (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_component_id			IN	 component.component_id%TYPE	
);

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_component_id			IN	 component.component_id%TYPE,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckForOverdueQuestionnaires;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
);

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,	
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
);

PROCEDURE GetShareStatusLogEntries(
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	 component.component_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID
);

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	 component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
);

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
);

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);

PROCEDURE ReSendQuestionnaire (
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_due_by_dtm				IN	questionnaire_share.due_by_dtm%TYPE
);

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	,
	in_component_id				IN  component.component_id%TYPE,
	in_transition_comments		IN  qnr_status_log_entry.user_notes%TYPE DEFAULT NULL
);

PROCEDURE GetQnnaireEnabledAlertsAppSids(
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRemindersOfQnnaireShares(
	in_app_sid	IN  security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE RecordReminderSent(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_std_alert_type_id		IN  qnnaire_share_alert_log.std_alert_type_id%TYPE
);

PROCEDURE GetOverduesOfQnnaireShares(
	in_app_sid	IN  security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
);

PROCEDURE RecordOverdueSent(
	in_app_sid					IN  security_pkg.T_SID_ID,
	in_questionnaire_share_id	IN	questionnaire_share.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_std_alert_type_id		IN  qnnaire_share_alert_log.std_alert_type_id%TYPE
);

PROCEDURE GetQSQuestionnaireSubmissions(
	in_survey_sid				IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_component_id				IN 	NUMBER,	
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION IsProductQuestionnaireType(
	in_questionnaire_type_id	IN questionnaire_type.questionnaire_type_id%TYPE
)RETURN NUMBER;

-- Triggered by dbms_scheduler
PROCEDURE ExpireQuestionnaires;

-- Called by scheduled task
PROCEDURE GetExpiryAlerts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

-- Called by scheduled task
PROCEDURE MarkExpiryAlertSent (
	in_questionnaire_share_id	IN	questionnaire_expiry_alert.questionnaire_share_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID
);

FUNCTION IsTransitionAlertsEnabled(
	in_questionnaire_type_id	IN questionnaire_type.questionnaire_type_id%TYPE
)RETURN NUMBER;

PROCEDURE GetReturnedQnrRecipients(
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_component_id				IN	component.component_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

END questionnaire_pkg;
/

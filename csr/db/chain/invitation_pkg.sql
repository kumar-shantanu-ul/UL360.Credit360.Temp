CREATE OR REPLACE PACKAGE  CHAIN.invitation_pkg
IS

PROCEDURE AnnounceSids;

PROCEDURE UpdateExpirations(
	in_invitation_id			IN invitation.invitation_id%TYPE DEFAULT NULL
);

FUNCTION HasFullInviteListAccess
RETURN NUMBER;

FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE;

/*******************************
CreateInvitation
******************************/

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'),
	in_from_user_sid			IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_on_behalf_of_company_sid	IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE DEFAULT NULL,
	in_expiration_life_days		IN  NUMBER DEFAULT 0,
	in_qnr_types				IN  security_pkg.T_SID_IDS DEFAULT chain_pkg.NullSidArray,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS DEFAULT chain_pkg.NullStringArray,
	in_component_id				IN 	chain.component.component_id%TYPE DEFAULT NULL,
	in_lang						IN	VARCHAR2 DEFAULT NULL,
	in_batch_job_id				IN	invitation.batch_job_id%TYPE DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE BulkCreateInvitations (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_batch_job_id				IN	invitation.batch_job_id%TYPE,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	in_to_company_sids			IN  security_pkg.T_SID_IDS,
	in_to_user_sids				IN  security_pkg.T_SID_IDS,
	in_obo_company_sids			IN  security_pkg.T_SID_IDS
);

PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
	in_language					IN	security.user_table.language%TYPE DEFAULT NULL,
	in_culture					IN	security.user_table.culture%TYPE DEFAULT NULL,
	in_timezone					IN	security.user_table.timezone%TYPE DEFAULT NULL,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE,
	in_password					IN  Security_Pkg.T_USER_PASSWORD, 
	in_language					IN	security.user_table.language%TYPE DEFAULT NULL,
	in_culture					IN	security.user_table.culture%TYPE DEFAULT NULL,
	in_timezone					IN	security.user_table.timezone%TYPE DEFAULT NULL
);

/* It's preferable creating a new function for questionnaire request invitation type */
PROCEDURE AcceptReqQnnaireInvitation(
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
);

/* This will check for any active invites for the given user and attempt to accept each one.*/
FUNCTION AcceptAnyActiveInvites(
	in_for_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
);

PROCEDURE RejectReqQnnaireInvitation(
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION CanAcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_guid_error_val			IN  NUMBER
) RETURN NUMBER;


/*** not to be called unless external validity checks have been done ***/
FUNCTION CanAcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetInvitationId (
	in_guid						IN  invitation.guid%TYPE
) RETURN invitation.invitation_id%TYPE;

PROCEDURE GetSupplierInvitationSummary (
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_invite_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_questionnaire_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetToCompanySidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

-- Security checks - you can't do this unless you can read the suppliers
PROCEDURE GetInviteDataFromId (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetToUserSidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_user_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
);

PROCEDURE SearchInvitations (
	in_search					IN	VARCHAR2,
	in_invitation_status_id		IN	invitation.invitation_status_id%TYPE,
	in_from_user_sid			IN	security_pkg.T_SID_ID,
	in_to_user_sid				IN	security_pkg.T_SID_ID, -- Used to pull out invites to a single user
	in_sent_dtm_from			IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to				IN	invitation.sent_dtm%TYPE,
	in_invitation_type_ids		IN	security_pkg.T_SID_IDS,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadInvitations (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CancelInvitation (
  in_invitation_id				IN	invitation.invitation_id%TYPE
);

PROCEDURE CancelInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	in_suppress_cancel_err	IN	NUMBER							-- we cancel the previous invitation when resending to a new user and thi
);

PROCEDURE ReSendInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CheckQnrTypeExists (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN	invitation_qnr_type.questionnaire_type_id%TYPE
) RETURN BOOLEAN;

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION GetActiveOrAcceptedCount_UNSEC (
	in_to_company_sid				IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetQnrInvitableCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCmpnyInvitableCompanyTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInviteOnBehalfOfs (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION IsLatestInvitationRejected (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_invitation_type_id	    IN invitation.invitation_type_id%TYPE	
) RETURN NUMBER;

PROCEDURE GetAllowedInvitationTypes (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvitationLanguage (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_lang					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvitationLanguage (
	in_guid						IN	invitation.guid%TYPE,
	out_lang					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvitationsSentToCompany (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_invitation_status_id		IN	invitation.invitation_status_id%TYPE, --optional, only get invitations in a specific status
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartBatch (
	in_personal_msg				IN	invitation_batch.personal_msg%TYPE,
	in_cc_from_user				IN	invitation_batch.cc_from_user%TYPE,
	in_cc_others				IN	invitation_batch.cc_others%TYPE,
	in_std_alert_type_id		IN	invitation_batch.std_alert_type_id%TYPE,
	in_lang						IN  invitation_batch.lang%TYPE DEFAULT NULL,
	out_batch_job_id			OUT	invitation_batch.batch_job_id%TYPE
);

PROCEDURE GetBatchJob (
	in_batch_job_id				IN	invitation_batch.batch_job_id%TYPE,
	out_batch_job_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qnr_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MarkInvitationSent (
	in_invitation_id			IN	invitation.invitation_id%TYPE
);

FUNCTION TryGetComponentId(
	in_invitation_id	IN	invitation.invitation_id%TYPE,
	out_component_id	OUT	component.component_id%TYPE
)RETURN NUMBER;

-- Called by scheduled task
PROCEDURE GetExpiryAlerts (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

-- Called by scheduled task
PROCEDURE MarkExpiryAlertSent (
	in_invitation_id	IN	invitation.invitation_id%TYPE
);

END invitation_pkg;
/

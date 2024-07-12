CREATE OR REPLACE PACKAGE CHAIN.questionnaire_security_pkg
IS

PROCEDURE SetActionSecurityMask (
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_company_function			IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION,
	in_action_security_type		IN  chain_pkg.T_ACTION_SECURITY_TYPE
);

PROCEDURE SetQuestionnaireUsers (
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_user_sids				IN  security.security_pkg.T_SID_IDS,
	out_newly_added_users_cur	OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetUserPermissions (
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_permitted_actions		IN  security_pkg.T_SID_IDS
);

PROCEDURE GetSecurityMasks (
	in_company_function			IN  chain_pkg.T_COMPANY_FUNCTION,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPermissionMatrix (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_entry_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_entry_permission_cur	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DivineSecureSearchParameters (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_current_user_view		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_for_company_function		IN  chain_pkg.T_COMPANY_FUNCTION,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION CanGrantPermissions(
	in_questionnaire_id		IN questionnaire.questionnaire_id%TYPE,
	in_company_sid			IN security.security_pkg.T_SID_ID
)RETURN NUMBER;

FUNCTION CheckPermissionSQL (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION
) RETURN NUMBER;

FUNCTION CheckPermission (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION,
	in_user_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_company_sid				IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
) RETURN BOOLEAN;

PROCEDURE OnQnnairePermissionsChange(
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE
);

END questionnaire_security_pkg;
/

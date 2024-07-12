CREATE OR REPLACE PACKAGE CHAIN.action_pkg
IS

-- action reason types
-- TO DO change this to be case consistent with events
AC_RA_FIRST_REGISTRATION	 		CONSTANT VARCHAR2(50) := 'FIRST_REGISTRATION';
AC_RA_USER_REGISTRATION	 			CONSTANT VARCHAR2(50) := 'USER_REGISTRATION';
AC_RA_COMPANY_DETAILS_CHANGED 		CONSTANT VARCHAR2(50) := 'COMPANY_DETAILS_CHANGED';
AC_RA_QUESTIONNAIRE_ASSIGNED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_ASSIGNED';
AC_RA_QUESTIONNAIRE_SUBMITTED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_SUBMITTED';
AC_RA_QUESTIONNAIRE_APPROVED	 	CONSTANT VARCHAR2(50) := 'QUESTIONNAIRE_APPROVED';
AC_RA_DEPENDENT_DATA_UPDATED	 	CONSTANT VARCHAR2(50) := 'DEPENDENT_DATA_UPDATED';
-- TO DO switch these for ID's

-- Product actions
AC_RA_PRD_PURCHASER_MAP_NEEDED	 	CONSTANT VARCHAR2(50) := 'PURCHASER_MAP_NEEDED';
AC_RA_PRD_SUPPLIER_MAP_NEEDED	 	CONSTANT VARCHAR2(50) := 'SUPPLIER_MAP_NEEDED';

AC_REP_ALLOW_MULTIPLE				CONSTANT NUMBER (10) := 1;
AC_REP_NO_MULTIPLE_UPDATE_DTM		CONSTANT NUMBER (10) := 2;
AC_REP_NO_MULTIPLE_LEAVE_DTM		CONSTANT NUMBER (10) := 3;
AC_REP_REOPEN						CONSTANT NUMBER (10) := 4;

PROCEDURE AddAction (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
);

PROCEDURE GetActions (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActions (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetReasonForActionId (
	in_reason_class		reason_for_action.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE AddCompanyDoActions (
	in_new_company_sid			security_pkg.T_SID_ID
);

PROCEDURE AddUserDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
);

PROCEDURE ConfirmCompanyDetailsDoActions (
	in_company_sid				security_pkg.T_SID_ID
);

PROCEDURE ConfirmUserDetailsDoActions (
	in_user_sid					security_pkg.T_SID_ID
);

PROCEDURE InviteQuestionnaireDoActions (
	in_to_company_sid			security_pkg.T_SID_ID,
	in_questionnaire_id			questionnaire.questionnaire_id%TYPE,
	in_from_company_sid			security_pkg.T_SID_ID,
	out_action_id				OUT action.action_id%TYPE
);

PROCEDURE ShareQuestionnaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);


PROCEDURE AcceptQuestionaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);
	

PROCEDURE ViewQResultsDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);

PROCEDURE StartActionPlanDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
);

PROCEDURE CompanyDetailsUpdatedDoActions (
	in_company_sid				security_pkg.T_SID_ID
);

PROCEDURE GenerateAlertEntries (
	in_as_of_dtm		IN TIMESTAMP
);

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_for_company_url				IN	action_type.for_company_url%TYPE,
	in_related_questionnaire_url	IN	action_type.related_questionnaire_url%TYPE,
	in_related_company_url			IN	action_type.related_company_url%TYPE,
	in_for_user_url					IN	action_type.for_user_url%TYPE,
	in_other_url_1					IN	action_type.other_url_1%TYPE DEFAULT NULL,
	in_other_url_2					IN	action_type.other_url_2%TYPE DEFAULT NULL,
	in_other_url_3					IN	action_type.other_url_3%TYPE DEFAULT NULL
);

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_clear_urls					IN  BOOLEAN
);

PROCEDURE ClearActionTypeUrls (
	in_action_type_id				IN	action_type.action_type_id%TYPE
);

PROCEDURE SetActionTypeUrl (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
);

PROCEDURE CreateReasonForAction (
	in_reason_for_action_id			IN	reason_for_action.reason_for_action_id%TYPE,
	in_action_type_id				IN	reason_for_action.action_type_id%TYPE,
	in_class						IN	reason_for_action.CLASS%TYPE,
	in_reason_name					IN	reason_for_action.reason_name%TYPE,
	in_reason_desc					IN	reason_for_action.reason_description%TYPE,
	in_action_repeat_type_id		IN	reason_for_action.action_repeat_type_id%TYPE
);



END action_pkg;
/

CREATE OR REPLACE PACKAGE  capability_pkg
IS

/************************************************************************ 
			README
*************************************************************************
- Capabilities are described by types (COMMON, COMPANY, SUPPLIER).

- There are two virtual types as well (ROOT, COMPANIES)

- ROOT is (currently) effectively the same as COMMON, and can be used interchangably.

- COMPANIES is currently only used during capability registration, and effectively
	just splits the call into two calls, one for COMPANY and one for SUPPLIER, making
	it convenient for setting up the same capability under both containers.

- Grant, Hide, Override and SetPermission all have multiple declarations that
	allow you to either pass in the TYPE, or not - these are commented 
	as "auto type" or "type specified" in this header file.

- "auto type" means that the system will try to determine the type you're referring 
	to - for COMMON types, it's simple - for COMPANY or SUPPLIER types, the method
	will be run for BOTH, which may or may not be the intention.

- "type specified" allows you to be explict and control exactly which capability / type
	combination you want to
*/

/************************************************************** 
			SEMI-PRIVATE (PROTECTED) METHODS 
**************************************************************/
-- this method is public so that it can be accessed by card_pkg
PROCEDURE CheckPermType (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

-- this method is public so that it can be accessed by card_pkg
FUNCTION GetCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN capability.capability_id%TYPE;

FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- It is preferred that one of the standard check capability methods be used (i.e. by name)
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;


/************************************************************** 
		SETUP AND INITIALIZATION METHODS 
**************************************************************/
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

/******************************************
	GrantCapability
******************************************/
-- boolean, auto type
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

/******************************************
	HideCapability
******************************************/
-- auto type
PROCEDURE HideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE HideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

/******************************************
	OverrideCapability
******************************************/
-- boolean, auto type
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- boolean, type specified
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- specific, auto type
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

/******************************************
	SetCapabilityPermission
******************************************/
-- boolean, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- specific, auto type
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
);

-- specific, type specified
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
);



PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
);

/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
-- boolean
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- boolean
PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

-- specific
PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
);

/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/

-- boolean
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- boolean
FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;


/*************
For those of you who are master capability checkers, you may want to specify the type of 
capability that you're checking in your code. The advantage of this method of calling is
that you can check a users's permission on their company's supplier node without needing
to provide a supplier company sid (which must be a sid of an ACTIVE supplier)
*************
-- boolean
FUNCTION CheckCapabilityByType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN;

-- specific
FUNCTION CheckCapabilityByType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN;
*/

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

END capability_pkg;
/


CREATE OR REPLACE PACKAGE  card_pkg
IS

FUNCTION GetCardGroupId (
	in_group_name			IN  card_group.name%TYPE
) RETURN card_group.card_group_id%TYPE;

PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card.description%TYPE
);

-- this is called DESTROY instead of DELETE to highlight the fact that it potentially
-- removes data across applications - BEWARE!
PROCEDURE DestroyCard (
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE AddProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_action	IN  card_progression_action.action%TYPE
);

PROCEDURE AddProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
);

PROCEDURE RenameProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_from_action 			IN  card_progression_action.action%TYPE,
	in_to_action 			IN  card_progression_action.action%TYPE
);

FUNCTION GetProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN T_STRING_LIST;

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
);

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_to_js_class			IN  card.js_class_type%TYPE
);

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_action_list			IN  T_CARD_ACTION_LIST
);

PROCEDURE MarkTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE ClearTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
);

-- boolean
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
);

-- specific
PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
);

PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
);

END card_pkg;
/


CREATE OR REPLACE PACKAGE  chain.chain_link_pkg
IS

PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE AddCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
);

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProduct (
	in_product_id			IN  product.product_id%TYPE
);

PROCEDURE KillProduct (
	in_product_id			IN  product.product_id%TYPE
);

END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE  chain_pkg
IS

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;

-- a general use code
UNDEFINED							CONSTANT NUMBER := 0;

SUBTYPE T_ACTIVE					IS NUMBER;
ACTIVE 								CONSTANT T_ACTIVE := 1;
INACTIVE 							CONSTANT T_ACTIVE := 0;

SUBTYPE T_GROUP						IS VARCHAR2(100);
ADMIN_GROUP							CONSTANT T_GROUP := 'Administrators';
USER_GROUP							CONSTANT T_GROUP := 'Users';
PENDING_GROUP						CONSTANT T_GROUP := 'Pending Users';
CHAIN_ADMIN_GROUP					CONSTANT T_GROUP := 'Chain '||ADMIN_GROUP;
CHAIN_USER_GROUP					CONSTANT T_GROUP := 'Chain '||USER_GROUP;

COMPANY_UPLOADS						CONSTANT security.securable_object.name%TYPE := 'Uploads';

SUBTYPE T_CAPABILITY_PERM_TYPE		IS NUMBER(10);
SPECIFIC_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 0;
BOOLEAN_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 1;

SUBTYPE T_CAPABILITY_TYPE			IS NUMBER(10);
CT_ROOT								CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMMON							CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMPANY							CONSTANT T_CAPABILITY_TYPE := 1; 
CT_SUPPLIERS						CONSTANT T_CAPABILITY_TYPE := 2; 
CT_COMPANIES						CONSTANT T_CAPABILITY_TYPE := 3; -- both the CT_COMPANY and CT_SUPPLIERS nodes

/****************************************************************************************************/
SUBTYPE T_CAPABILITY				IS VARCHAR2(100);

-- treated as a either a COMPANY or SUPPLIER capability check depending on sid 
-- that is passed in with it compared with the company sid set in session
COMPANYorSUPPLIER					CONSTANT T_CAPABILITY := 'VIRTUAL.COMPANYorSUPPLIER';

/**** Root capabilities ****/
CAPABILITIES						CONSTANT T_CAPABILITY := 'Capabilities';
COMPANY								CONSTANT T_CAPABILITY := 'Company';
SUPPLIERS							CONSTANT T_CAPABILITY := 'Suppliers';

/**** Company/Suppliers nodes capabilities ****/
SPECIFY_USER_NAME					CONSTANT T_CAPABILITY := 'Specify user name';
QUESTIONNAIRE						CONSTANT T_CAPABILITY := 'Questionnaire';
SUBMIT_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Submit questionnaire';
SETUP_STUB_REGISTRATION				CONSTANT T_CAPABILITY := 'Setup stub registration';
RESET_PASSWORD						CONSTANT T_CAPABILITY := 'Reset password';
CREATE_USER							CONSTANT T_CAPABILITY := 'Create user';
EVENTS								CONSTANT T_CAPABILITY := 'Events';
ACTIONS								CONSTANT T_CAPABILITY := 'Actions';
TASKS								CONSTANT T_CAPABILITY := 'Tasks';
METRICS								CONSTANT T_CAPABILITY := 'Metrics';
PRODUCTS							CONSTANT T_CAPABILITY := 'Products';
COMPONENTS							CONSTANT T_CAPABILITY := 'Components';
PROMOTE_USER						CONSTANT T_CAPABILITY := 'Promote user';
PRODUCT_CODE_TYPES					CONSTANT T_CAPABILITY := 'Product code types';

/**** Common capabilities ****/
IS_TOP_COMPANY						CONSTANT T_CAPABILITY := 'Is top company';
SEND_QUESTIONNAIRE_INVITE			CONSTANT T_CAPABILITY := 'Send questionnaire invitation';
SEND_NEWSFLASH						CONSTANT T_CAPABILITY := 'Send newsflash';
RECEIVE_USER_TARGETED_NEWS			CONSTANT T_CAPABILITY := 'Receive user-targeted newsflash';
APPROVE_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Approve questionnaire';

/****************************************************************************************************/

SUBTYPE T_VISIBILITY				IS NUMBER;
HIDDEN 								CONSTANT T_VISIBILITY := 0;
JOBTITLE 							CONSTANT T_VISIBILITY := 1;
NAMEJOBTITLE						CONSTANT T_VISIBILITY := 2;
FULL 								CONSTANT T_VISIBILITY := 3;

SUBTYPE T_REGISTRATION_STATUS		IS NUMBER;
PENDING								CONSTANT T_REGISTRATION_STATUS := 0;
REGISTERED 							CONSTANT T_REGISTRATION_STATUS := 1;
REJECTED							CONSTANT T_REGISTRATION_STATUS := 2;
MERGED								CONSTANT T_REGISTRATION_STATUS := 3;

SUBTYPE T_INVITATION_TYPE			IS NUMBER;
QUESTIONNAIRE_INVITATION			CONSTANT T_INVITATION_TYPE := 1;
STUB_INVITATION						CONSTANT T_INVITATION_TYPE := 2;

SUBTYPE T_INVITATION_STATUS			IS NUMBER;
-- ACTIVE = 1 (defined above)
EXPIRED								CONSTANT T_INVITATION_STATUS := 2;
CANCELLED							CONSTANT T_INVITATION_STATUS := 3;
PROVISIONALLY_ACCEPTED				CONSTANT T_INVITATION_STATUS := 4;
ACCEPTED							CONSTANT T_INVITATION_STATUS := 5;
REJECTED_NOT_EMPLOYEE				CONSTANT T_INVITATION_STATUS := 6;
REJECTED_NOT_SUPPLIER				CONSTANT T_INVITATION_STATUS := 7;

SUBTYPE T_GUID_STATE				IS NUMBER;
GUID_OK 							CONSTANT T_GUID_STATE := 0;
--GUID_INVALID						CONSTANT T_GUID_STATE := 1; -- probably only used in cs class
GUID_NOTFOUND						CONSTANT T_GUID_STATE := 2;
GUID_EXPIRED						CONSTANT T_GUID_STATE := 3;
GUID_ALREADY_USED					CONSTANT T_GUID_STATE := 4;

SUBTYPE T_ALERT_ENTRY_TYPE			IS NUMBER;
EVENT_ALERT							CONSTANT T_ALERT_ENTRY_TYPE := 1;
ACTION_ALERT						CONSTANT T_ALERT_ENTRY_TYPE := 2;

SUBTYPE T_ALERT_ENTRY_PARAM_TYPE	IS NUMBER;
ORDERED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 1;
NAMED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 2;

/****************************************************************************************************/

SUBTYPE T_SHARE_STATUS				IS NUMBER;
NOT_SHARED 							CONSTANT T_SHARE_STATUS := 11;
SHARING_DATA 						CONSTANT T_SHARE_STATUS := 12;
SHARED_DATA_RETURNED 				CONSTANT T_SHARE_STATUS := 13;
SHARED_DATA_ACCEPTED 				CONSTANT T_SHARE_STATUS := 14;
SHARED_DATA_REJECTED 				CONSTANT T_SHARE_STATUS := 15;

SUBTYPE T_QUESTIONNAIRE_STATUS		IS NUMBER;
ENTERING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 1;
REVIEWING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 2;
READY_TO_SHARE 						CONSTANT T_QUESTIONNAIRE_STATUS := 3;




ERR_QNR_NOT_FOUND	CONSTANT NUMBER := -20500;
QNR_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_FOUND, -20500);

ERR_QNR_ALREADY_EXISTS	CONSTANT NUMBER := -20501;
QNR_ALREADY_EXISTS EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_EXISTS, -20501);

ERR_QNR_NOT_SHARED CONSTANT NUMBER := -20502;
QNR_NOT_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_SHARED, -20502);

ERR_QNR_ALREADY_SHARED CONSTANT NUMBER := -20503;
QNR_ALREADY_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_SHARED, -20503);



PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
);

PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE;


PROCEDURE IsChainAdmin(
	out_result				OUT  NUMBER
);

FUNCTION IsChainAdmin
RETURN BOOLEAN;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

FUNCTION IsElevatedAccount
RETURN BOOLEAN;

FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

END chain_pkg;
/


CREATE OR REPLACE PACKAGE cmpnt_cmpnt_relationship_pkg
IS

PROCEDURE AttachComponent (
	in_parent_component_id IN component.component_id%TYPE,
	in_component_id		   IN component.component_id%TYPE	
);

PROCEDURE DetachComponent (
	in_component_id		   IN component.component_id%TYPE	
);

PROCEDURE DetachChildComponents (
	in_component_id		   IN component.component_id%TYPE	
);

PROCEDURE DetachComponent (
	in_parent_component_id IN component.component_id%TYPE,
	in_component_id		   IN component.component_id%TYPE	
);

END cmpnt_cmpnt_relationship_pkg;
/

CREATE OR REPLACE PACKAGE cmpnt_prod_relationship_pkg
IS

	/* Note: we always link a "component" (even if this represents the whole product) to a product
	 * purchaser buys a component
	 * Supplier sells a product */

	-- Add purchaser Component -> Supplier Product to be linked
	
PROCEDURE SupplierSetCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_product_id			product.product_id%TYPE
);

PROCEDURE SupplierSetCmpntProdPendingRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
);

PROCEDURE SupplierRejectCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
);

/*
PROCEDURE SupplierClearCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
);
*/

PROCEDURE SupplierSetMappingAction (
	in_purchaser_company_sid	security_pkg.T_SID_ID,
	in_supplier_company_sid		security_pkg.T_SID_ID
);
	
PROCEDURE SetCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_product_id			product.product_id%TYPE
);

PROCEDURE SetCmpntProdPendingRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
);

PROCEDURE GetCompProdPairs (
	in_search					VARCHAR2,
	in_purchaser_company_sid	security_pkg.T_SID_ID,
	in_supplier_company_sid		security_pkg.T_SID_ID,
	in_show_need_attention		NUMBER,
	in_start					NUMBER,
	in_page_size				NUMBER,
	in_sort_by					VARCHAR2,
	in_sort_dir					VARCHAR2,
	in_exporting				IN NUMBER,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSuppliers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchasers (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

END cmpnt_prod_relationship_pkg;
/

CREATE OR REPLACE PACKAGE  company_pkg
IS


/************************************************************
	SYS_CONTEXT handlers
************************************************************/

FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;


/************************************************************
	Securable object handlers
************************************************************/
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
);

/************************************************************
	Company Management Handlers
************************************************************/
-- this can be used to trigger a verification of each company's so structure during updates
PROCEDURE VerifySOStructure;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
);

-- uses security_pkg.getACT
PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_name					IN  company.name%TYPE,
	in_address_1			IN  company.address_1%TYPE,
	in_address_2			IN  company.address_2%TYPE,
	in_address_3			IN  company.address_3%TYPE,
	in_address_4			IN  company.address_4%TYPE,
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_phone				IN  company.phone%TYPE,
	in_fax					IN  company.fax%TYPE,
	in_website				IN  company.website%TYPE
);

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION GetCompanyName (
	in_company_sid IN security_pkg.t_sid_id
) RETURN company.name%TYPE;

PROCEDURE SearchCompanies ( 
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchMyCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE StartRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
);

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE DeactivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);


FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
);

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsSupplier (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsPurchaser (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER;


PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
);

PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
);

/*
PROCEDURE ForceSetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);
*/

END company_pkg;
/


CREATE OR REPLACE PACKAGE  company_user_pkg
IS

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
);

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS
);

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_search_term  		IN  VARCHAR2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE ApproveUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE MakeAdmin (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION RemoveAdmin (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
);

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
);

PROCEDURE BeginUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
);

PROCEDURE EndUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS;

PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
);

PROCEDURE CheckEmailAvailability (
	in_email					IN  security_pkg.T_SO_NAME
);

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

END company_user_pkg;
/

CREATE OR REPLACE PACKAGE component_pkg
IS

-- COMPONENT types
-- any copies default for containment purposes
CMPNT_TYPE_ANY 					CONSTANT NUMBER := 1;
CMPNT_TYPE_DEFAULT 				CONSTANT NUMBER := 1;
CMPNT_TYPE_LOGICAL 				CONSTANT NUMBER := 2;
CMPNT_TYPE_PURCHASED			CONSTANT NUMBER := 3;
CMPNT_TYPE_NOTSURE				CONSTANT NUMBER := 4;

-- RA SPECIFC COMPONENT TYPES -- should these go here. They are client specific - but putting theme here gives greater visibility ? TO DO
CMPNT_TYPE_PROD_RA_ROOT 		CONSTANT NUMBER := 48;
CMPNT_TYPE_WOOD_RA_ROOT 		CONSTANT NUMBER := 49;
CMPNT_TYPE_WOOD_RA 				CONSTANT NUMBER := 50;

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE CreateComponentType (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_handler_class		IN  component_type.handler_class%TYPE,
	in_handler_pkg			IN  component_type.handler_pkg%TYPE,
	in_node_js_path			IN  component_type.node_js_path%TYPE,
	in_description			IN  component_type.description%TYPE
);

PROCEDURE CreateComponentType (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_handler_class		IN  component_type.handler_class%TYPE,
	in_handler_pkg			IN  component_type.handler_pkg%TYPE,
	in_node_js_path			IN  component_type.node_js_path%TYPE,
	in_description			IN  component_type.description%TYPE,
	in_editor_card_group_id	IN  component_type.editor_card_group_id%TYPE
);


PROCEDURE ClearComponentSources;

PROCEDURE AddComponentSource (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
);

PROCEDURE AddComponentSource (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
);

PROCEDURE GetComponentSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearComponentTypeContainment;

PROCEDURE SetComponentTypeContainment (
	in_container_component_type_id		IN component_type.component_type_id%TYPE,
	in_child_component_type_id			IN component_type.component_type_id%TYPE
);

PROCEDURE GetComponentTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsComponentType (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE
) RETURN BOOLEAN;

FUNCTION GetComponentCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN company.company_sid%TYPE;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetComponentTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponentType (
	in_component_type_id	IN  component_type.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE;

PROCEDURE DeleteComponent (
	in_component_id		   IN component.component_id%TYPE
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_product_id			IN  product.product_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_of_type				IN  component_type.component_type_id%TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/

PROCEDURE ChangeNotSureComponentType (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END component_pkg;
/

CREATE OR REPLACE PACKAGE  dashboard_pkg
IS

PROCEDURE GetSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

END dashboard_pkg;
/


CREATE OR REPLACE PACKAGE  dev_pkg
IS

PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE
);

PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
);


PROCEDURE GetOpenInvitations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOpenActiveActivations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanies (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
);


END dev_pkg;
/


CREATE OR REPLACE PACKAGE  event_pkg
IS
	
-- event type classes

-- invitations
EV_INVITATION_SENT		 			CONSTANT VARCHAR2(50) := 'InvitationSent';
EV_INVITATION_ACCEPTED		 		CONSTANT VARCHAR2(50) := 'InvitationAccepted';
EV_INVITATION_REJECTED		 		CONSTANT VARCHAR2(50) := 'InvitationRejected';
EV_INVITATION_EXPIRED		 		CONSTANT VARCHAR2(50) := 'InvitationExpired';

-- questionnaire
EV_QUESTIONNAIRE_SUBMITTED		 	CONSTANT VARCHAR2(50) := 'QuestionnaireSubmitted';
EV_QUESTIONNAIRE_APPROVED		 	CONSTANT VARCHAR2(50) := 'QuestionnaireApproved';
EV_QUESTIONNAIRE_OVERDUE			CONSTANT VARCHAR2(50) := 'QuestionniareOverdue';

-- messages for supplier
EV_QUESTIONNAIRE_SUBMITTED_SUP		CONSTANT VARCHAR2(50) := 'QuestionnaireSubmittedSup';
EV_QUESTIONNAIRE_APPROVED_SUP	  	CONSTANT VARCHAR2(50) := 'QuestionnaireApprovedSup';
EV_QUESTIONNAIRE_OVERDUE_SUP		CONSTANT VARCHAR2(50) := 'QuestionniareOverdueSup';

--EV_QUESTIONNAIRE_RETURNED		 	CONSTANT VARCHAR2(50) := 'QuestionnaireReturned';

-- action plans
EV_ACTION_PLAN_STARTED				CONSTANT VARCHAR2(50) := 'ActionPlanStarted';
EV_COMPANY_DETAILS_UPDATED			CONSTANT VARCHAR2(50) := 'CompanyDetailsUpdated';

EV_TEST		 						CONSTANT VARCHAR2(50) := 'Test';

PROCEDURE AddEvent (
	in_for_company_sid					IN event.for_company_sid%TYPE,
	in_for_user_sid						IN event.for_user_sid%TYPE,
	in_related_company_sid				IN event.related_company_sid%TYPE,
	in_related_user_sid					IN event.related_user_sid%TYPE,
	in_related_questionnaire_id			IN event.related_questionnaire_id%TYPE,
	in_related_action_id				IN event.related_action_id%TYPE,
	in_event_type_id					IN event.event_type_id%TYPE,
	out_event_id						OUT event.event_id%TYPE
);

PROCEDURE GetEvents (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvents (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvents (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvents (
	in_company_sid		NUMBER,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetEventTypeId (
	in_event_class		event_type.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE GenerateAlertEntries (
	in_as_of_dtm		IN TIMESTAMP
);

PROCEDURE AddSimpleEventType (
	in_event_type_id			IN	event_type.event_type_id%TYPE,
	in_message_template			IN	event_type.message_template%TYPE,
	in_priority					IN	event_type.priority%TYPE,
	in_class					IN	event_type.CLASS%TYPE,
	in_related_comp_url			IN	event_type.related_company_url%TYPE,
	in_related_user_url			IN	event_type.related_user_url%TYPE,
	in_related_quest_url		IN	event_type.related_questionnaire_url%TYPE
);

PROCEDURE CreateEventType (
	in_event_type_id				IN	event_type.event_type_id%TYPE,
	in_message_template				IN	event_type.message_template%TYPE,
	in_priority						IN	event_type.priority%TYPE,
	in_class						IN	event_type.class%TYPE,
	in_clear_urls					IN  BOOLEAN
);

PROCEDURE ClearEventTypeUrls (
	in_event_type_id				IN	event_type.event_type_id%TYPE
);

PROCEDURE SetEventTypeUrl (
	in_event_type_id				IN	event_type.event_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
);


END event_pkg;
/


CREATE OR REPLACE PACKAGE  invitation_pkg
IS

PROCEDURE UpdateExpirations;

FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE;


PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS
) RETURN invitation.invitation_id%TYPE;


PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
);


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
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

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
);

END invitation_pkg;
/


CREATE OR REPLACE PACKAGE logical_component_pkg
IS
/*
PROCEDURE AddComponent ( 
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE UpdateComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);


PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);
*/
END logical_component_pkg;
/

CREATE OR REPLACE PACKAGE  metric_pkg
IS

PROCEDURE GetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION SetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	in_value				IN company_metric.metric_value%TYPE
) RETURN company_metric.normalised_value%TYPE;

PROCEDURE DeleteCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE
);


END metric_pkg;
/


CREATE OR REPLACE PACKAGE newsflash_pkg
IS

TYPE T_NEWSFLASH_ROW IS RECORD
(
	newsflash_id newsflash.newsflash_id%TYPE,
	released_dtm newsflash.released_dtm%TYPE,
	content newsflash.content%TYPE,
	for_users NUMBER(1),
	for_suppliers NUMBER(1)
);

TYPE T_NEWSFLASH_TABLE IS TABLE OF T_NEWSFLASH_ROW;

FUNCTION ChainNewsSummary RETURN T_NEWSFLASH_TABLE PIPELINED;

PROCEDURE GetNewsflashSummarySP
(
	out_sp OUT customer_options.newsflash_summary_sp%TYPE
);

PROCEDURE AddNewsflash
(
	in_content newsflash.content%TYPE,
	out_newsflash_id OUT newsflash.newsflash_id%TYPE
);

PROCEDURE RestrictNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_for_suppliers NUMBER DEFAULT 0,
	in_for_users NUMBER DEFAULT 0
);

PROCEDURE ExpireNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_expiry_dtm DATE DEFAULT SYSDATE
);

PROCEDURE ReleaseNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_release_dtm DATE DEFAULT SYSDATE
);

PROCEDURE GetNewsSummary
(
	out_news_summary_cur OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE HideNewsflashFromUser
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_user_sid newsflash_user_settings.user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'SID')
);

END newsflash_pkg;
/

CREATE OR REPLACE PACKAGE product_pkg
IS

PROCEDURE AddProduct (
    in_description         	IN  product.description%TYPE,
    in_code1              	IN  product.code1%TYPE,
    in_code2              	IN  product.code2%TYPE,
    in_code3              	IN  product.code3%TYPE, 
    in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_product_id		   	OUT product.product_id%TYPE
);

FUNCTION UpdateProduct (
	in_product_id		   IN product.product_id%TYPE,
    in_description         IN product.description%TYPE,
    in_code1               IN product.code1%TYPE,
    in_code2               IN product.code2%TYPE,
    in_code3               IN product.code3%TYPE
) RETURN NUMBER;

/*PROCEDURE CheckProductUniqueness (
    in_description         IN product.description%TYPE,
    in_code1              IN product.code1%TYPE,
    in_code2              IN product.code2%TYPE,
    in_code3              IN product.code3%TYPE, 
	out_cur				   OUT	security_pkg.T_OUTPUT_CUR
);*/

PROCEDURE SetProductActivation (
	in_product_id		   IN product.product_id%TYPE,
    in_active         	   IN product.active%TYPE
);

PROCEDURE SetProductReview (
	in_product_id		   IN product.product_id%TYPE,
    in_need_review    	   IN product.active%TYPE
);

PROCEDURE GetProduct (
	in_product_id	IN  product.product_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE GetProductsForCompany (
	in_company_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE SearchProducts (
	in_search					VARCHAR2,
	in_purchaser_company_sid	security_pkg.T_SID_ID,
	in_supplier_company_sid		security_pkg.T_SID_ID,
	in_show_just_need_attention	NUMBER,
	in_show_deleted				NUMBER,
	in_start					NUMBER,
	in_page_size				NUMBER,
	in_sort_by					VARCHAR2,
	in_sort_dir					VARCHAR2,
	in_exporting				IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetProductCompanySid (
	in_product_id		   IN product.product_id%TYPE
) RETURN company.company_sid%TYPE;

PROCEDURE GetRecentProducts (
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCodeLabelsForCompany (
	in_company_sid	IN  company.company_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCodeLabelsForCompany (
    in_company_sid      security_pkg.T_SID_ID,
	in_code_label1		chain.product_code_type.code_label1%TYPE,
	in_code_label2		chain.product_code_type.code_label2%TYPE,
	in_code_label3		chain.product_code_type.code_label3%TYPE,
	in_code2_mandatory	chain.product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory	chain.product_code_type.code3_mandatory%TYPE
);

PROCEDURE GetProductCodeOptions (
	in_company_sid	IN  company.company_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateProductCodeOptions (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	company.mapping_approval_required%TYPE
);

PROCEDURE TurnOnProductsForCompany (
	in_company_sid	IN  company.company_sid%TYPE
);

/*
FUNCTION GetProductCompany (
	in_product_id		   IN product.product_id%TYPE
) RETURN company.company_sid%TYPE;
*/

FUNCTION GetProductRootComponent (
	in_product_id		   IN product.product_id%TYPE
) RETURN component.component_id%TYPE;

FUNCTION GetProductComponentIds (
	in_product_id		   IN product.product_id%TYPE
) RETURN T_NUMERIC_TABLE;

PROCEDURE GetProductComponentIdTree (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductBuilderComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.product_builder_component_id%TYPE
);

END product_pkg;
/

CREATE OR REPLACE PACKAGE purchased_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_product_id			IN  product.product_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END purchased_component_pkg;
/

CREATE OR REPLACE PACKAGE CHAIN.questionnaire_pkg
IS

-- keep
PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

-- keep
PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

-- keep
PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

-- keep
PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

-- keep
FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);


FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
);

-- keep
FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
);

-- keep
FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

-- keep
FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS;

-- keep
PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);


PROCEDURE GetQManagementData (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQManagementData (
	in_company_sid		security_pkg.T_SID_ID,
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
	in_position					IN	questionnaire_type.position%TYPE
);

PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
);

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckForOverdueQuestionnaires;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
);

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);



END questionnaire_pkg;
/

CREATE OR REPLACE PACKAGE  scheduled_alert_pkg
IS
	
/*******************************************************************
	To be called by scheduler
*******************************************************************/

PROCEDURE GenerateAlertEntries;

PROCEDURE GetOutstandingAlertRecipients (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateUserDistributionTimes;

PROCEDURE SendingScheduledAlertTo (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,	
	out_entries_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_params_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertSchedules (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAppAlertSettings (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAlertEntryTemplates (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/*******************************************************************
	To be called by scheduled alerts implementations
*******************************************************************/
PROCEDURE SetAlertEntry (
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id		IN  NUMBER,
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_occurred_dtm			IN  alert_entry.occurred_dtm%TYPE,
	in_template_name		IN  alert_entry.template_name%TYPE,
	in_text					IN  alert_entry.text%TYPE,
	in_param_type_id		IN  chain_pkg.T_ALERT_ENTRY_PARAM_TYPE
);

PROCEDURE UpdateTemplateName (
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id		IN  NUMBER,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_template_name		IN  alert_entry.template_name%TYPE
);



END scheduled_alert_pkg;
/


CREATE OR REPLACE PACKAGE CHAIN.task_pkg
IS

TASK_ACTION_REMOVE 		CONSTANT NUMBER := 1;
TASK_ACTION_ADD			CONSTANT NUMBER := 2;


TASK_STATUS_REQ_INIT_APPROVAL			CONSTANT NUMBER:=1;
TASK_STATUS_SUB_INIT_APPROVAL			CONSTANT NUMBER:=2;
TASK_STATUS_OPEN						CONSTANT NUMBER:=3;
TASK_STATUS_SUB_APPROVAL				CONSTANT NUMBER:=4;
TASK_STATUS_APPROVED					CONSTANT NUMBER:=5;
TASK_STATUS_CLOSED						CONSTANT NUMBER:=6;
TASK_STATUS_PENDING						CONSTANT NUMBER:=7;
TASK_STATUS_REMOVED						CONSTANT NUMBER:=8;
TASK_STATUS_NA							CONSTANT NUMBER:=9;

PROCEDURE CreateTaskNode (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_parent_task_node			IN task_node.task_node_id%TYPE,
	in_heading					IN task_node.heading%TYPE,
	in_description				IN task_node.description%TYPE,
	in_task_node_type_id		IN task_node.task_node_type_id%TYPE,
	out_task_node_id			OUT task_node.task_node_id%TYPE
);


PROCEDURE ProcessTasks (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
);

PROCEDURE ProcessTaskNode (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_node_id				IN	task.task_node_id%TYPE
);

PROCEDURE ChangeTaskStatus (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

PROCEDURE GetTaskStatus (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	out_status_id				OUT	task.task_status_id%TYPE
);

PROCEDURE GetTaskDueDays (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_type_id				IN	task.task_type_id%TYPE,
	out_due_in_days				OUT	NUMBER
);

PROCEDURE SetTaskDueDate (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
);

PROCEDURE AddSimpleTask (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_node_type_id		IN	task_node.task_node_type_id%TYPE,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_edit_due_date			IN	task.due_date_editable%TYPE,
	in_is_mandatory				IN	task.mandatory%TYPE,
	in_heading					IN	task.heading%TYPE,
	in_description				IN	task.description%TYPE,
	out_task_id					OUT	task.task_id%TYPE
);

-- get all tasks under a specific node_id (using hierarchy)
PROCEDURE GetFlattenedTasks (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_node_id				IN	task.task_node_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetTopLevelTaskNodes (
	in_company_sid				IN security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateTask (
	in_company_sid				IN 	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date			IN	date,
	in_due_date					IN	date
);

/*
PROCEDURE GetTasksWithHeirachy (
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTask (
	in_task_id				IN	task.task_id%TYPE,
	in_task_node_id			IN	task.task_node_id%TYPE,
	in_task_status_id		IN	task.task_status_id%TYPE,
	in_description			IN	task.description%TYPE,
	in_due_date				IN	task.due_date%TYPE,
	in_review_every_n_days	IN	task.review_every_n_days%TYPE,
	in_next_review_date		IN	task.next_review_date%TYPE,
	in_mandatory			IN	task.mandatory%TYPE,
	in_company_sid			IN	task.company_sid%TYPE,
	in_task_type_id			IN	task.task_type_id%TYPE
);
*/

END task_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.action_pkg
IS

PROCEDURE AddActionINTERNAL (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
)
AS
	v_action_id							action.action_id%TYPE;
	v_action_repeat_type_id				reason_for_action.action_repeat_type_id%TYPE;
	v_just_add_new_action				NUMBER(1) := 0;
BEGIN
	
	-- some action types are actions that should only appear once
	-- if they happen again (and aren't complete and therefore hidden) reset the timestamp, duedtm, reason data

	-- get the action repeat type
	SELECT action_repeat_type_id
	  INTO v_action_repeat_type_id
	  FROM reason_for_action ra
	 WHERE ra.app_sid = security_pkg.GetApp
	   AND ra.reason_for_action_id = in_reason_for_action_id;


	IF v_action_repeat_type_id = action_pkg.AC_REP_ALLOW_MULTIPLE THEN
		-- this is the usual case - insert and brand new action
		v_just_add_new_action := 1;
	ELSE

		-- find any incomplete action with the same
		-- for company, for user, related company, related user, related questionnaire and reason for action id

		-- TO DO - might want to match the above without looking at from users and update who the action has come from
		-- as a new action_repeat_type - but we don't have any action like this atm

		-- in these cases should only be one action but get latest (and MAX id if identical dtm) action id rather than
		-- assume only one in case action repeat type has changed for this action reason type

		BEGIN
			SELECT MAX(action_id)
			  INTO v_action_id
			  FROM action A
			 WHERE app_sid = security_pkg.GetApp
			   AND for_company_sid 						= in_for_company_sid   -- non null
			   AND NVL(for_user_sid, -1) 				= NVL(in_for_user_sid, -1)
			   AND NVL(related_company_sid, -1) 		= NVL(in_related_company_sid, -1)
			   AND NVL(related_user_sid, -1) 			= NVL(in_related_user_sid, -1)
			   AND NVL(related_questionnaire_id, -1) 	= NVL(in_related_questionnaire_id, -1)
			   AND NVL(reason_for_action_id, -1) 		= NVL(in_reason_for_action_id, -1)
			   AND is_complete = 0
			   AND SYSDATE =   (SELECT MAX(SYSDATE)
								  FROM action A
								 WHERE app_sid = security_pkg.GetApp
								   AND for_company_sid 						= in_for_company_sid   -- non null
								   AND NVL(for_user_sid, -1) 				= NVL(in_for_user_sid, -1)
								   AND NVL(related_company_sid, -1) 		= NVL(in_related_company_sid, -1)
								   AND NVL(related_user_sid, -1) 			= NVL(in_related_user_sid, -1)
								   AND NVL(related_questionnaire_id, -1) 	= NVL(in_related_questionnaire_id, -1)
								   AND NVL(reason_for_action_id, -1) 		= NVL(in_reason_for_action_id, -1)
								   AND is_complete = 0
				)
				GROUP BY action_id;

			-- if we are here we have an existing action
			out_action_id := v_action_id;

			CASE v_action_repeat_type_id
				WHEN action_pkg.AC_REP_NO_MULTIPLE_UPDATE_DTM THEN

					-- update the action
					UPDATE action
					   SET
							due_date = in_due_date,
							reason_data = in_reason_data,
							created_dtm = SYSDATE
					 WHERE action_id = v_action_id
					   AND app_sid = security_pkg.GetApp;
				WHEN action_pkg.AC_REP_NO_MULTIPLE_LEAVE_DTM THEN
					-- do nothing - leave well alone
					NULL;
				WHEN action_pkg.AC_REP_REOPEN THEN
					-- update the action
					UPDATE action
					   SET
							due_date = in_due_date,
							reason_data = in_reason_data,
							created_dtm = SYSDATE,
							is_complete = 0
					 WHERE action_id = v_action_id
					   AND app_sid = security_pkg.GetApp;
			END CASE;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- no matches
				v_just_add_new_action := 1;
		END;

	END IF;

	-- we are actually OK to just add the new action
	IF v_just_add_new_action = 1 THEN
		INSERT INTO action (
			app_sid,
			action_id,
			for_company_sid,
			for_user_sid,
			related_company_sid,
			related_user_sid,
			related_questionnaire_id,
			created_dtm,
			due_date,
			reason_for_action_id,
			reason_data
		) VALUES (
			security_pkg.GetApp,
			action_id_seq.NEXTVAL,
			in_for_company_sid,
			in_for_user_sid,
			in_related_company_sid,
			in_related_user_sid,
			in_related_questionnaire_id,
			SYSDATE,
			in_due_date,
			in_reason_for_action_id,
			in_reason_data
		) RETURNING action_id INTO v_action_id;
	END IF;


	out_action_id := v_action_id;

END;

PROCEDURE AddAction (
	in_for_company_sid					IN security_pkg.T_SID_ID,
	in_for_user_sid						IN security_pkg.T_SID_ID,
	in_related_company_sid				IN security_pkg.T_SID_ID,
	in_related_user_sid					IN security_pkg.T_SID_ID,
	in_related_questionnaire_id			IN action.related_questionnaire_id%TYPE,
	in_due_date							IN action.due_date%TYPE,
	in_reason_for_action_id				IN action.reason_for_action_id%TYPE,
	in_reason_data						IN action.reason_data%TYPE,
	out_action_id						OUT action.action_id%TYPE
)
AS
BEGIN

	-- we have to do this as we may be setting removing actions for a company yet to confirm 
	company_pkg.ActivateVirtualRelationship(in_for_company_sid);
	
	IF NOT capability_pkg.CheckCapability(in_for_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_for_company_sid);
	END IF;
	
	
	
	AddActionINTERNAL (
		in_for_company_sid,
		in_for_user_sid,
		in_related_company_sid,
		in_related_user_sid,
		in_related_questionnaire_id,
		in_due_date,
		in_reason_for_action_id,
		in_reason_data,
		out_action_id
	);
	
	company_pkg.DeactivateVirtualRelationship(in_for_company_sid);

END;


PROCEDURE GetActions (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetActions(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_start, in_page_size, out_cur);
END;

PROCEDURE GetActions (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to actions for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT * FROM
		(
			SELECT ROWNUM rn, A.* FROM
			(
				SELECT for_company_sid, for_company_name, for_company_url, for_user_sid, for_user_full_name, for_user_friendly_name,
						for_user_url, related_company_sid, related_company_name, related_company_url, related_user_sid, related_user_full_name,
						related_user_friendly_name, related_user_url, related_questionnaire_id, related_questionnaire_name, related_questionnaire_url,
						action_id, created_dtm, due_date, is_complete, completion_dtm, other_url_1, other_url_2, other_url_3, reason_for_action_id,
						reason_for_action_name, reason_for_action_description, action_type_id, message_template, priority, for_whom, is_for_user
				  FROM v$action
				 WHERE app_sid = security_pkg.GetApp
				   AND for_company_sid = in_company_sid
				   AND (for_user_sid IS NULL OR (for_user_sid = NVL(v_user_sid, -1)))
				   AND is_complete = 0
				ORDER BY priority, created_dtm DESC, NVL(for_user_sid, -1), NVL2(for_user_sid, 1, 0) DESC
			) A
			WHERE ((in_page_size IS NULL) OR (ROWNUM <= in_start+in_page_size))
			ORDER BY priority, created_dtm DESC, is_for_user DESC
		)
		WHERE rn > in_start
		ORDER BY priority, created_dtm DESC, is_for_user DESC;

END;

FUNCTION GetReasonForActionId (
	in_reason_class		reason_for_action.CLASS%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	BEGIN
        SELECT reason_for_action_id
          INTO v_ret
          FROM reason_for_action
         WHERE CLASS = in_reason_class
           AND app_sid = security_pkg.GetApp;
	EXCEPTION
		WHEN no_data_found THEN
			raise_application_error (-20100,'Cannot find reason class ' || in_reason_class || ' for app_sid=' || security_pkg.GetApp);
	END;
	RETURN v_ret;
END;

-- Helper functions - certain repetitive things need to do actions for

-- Creating a company
PROCEDURE AddCompanyDoActions (
	in_new_company_sid			security_pkg.T_SID_ID
)
AS
	v_action_id					action.action_id%TYPE;
BEGIN
	-- ensure that we can write suppliers - that's good enough for now as the company isn't a supplier when it's created
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to suppliers for company with sid '||company_pkg.GetCompany||' for user with sid '||security_pkg.GetSid);
	END IF;

	AddActionINTERNAL(in_new_company_sid, NULL, NULL, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_FIRST_REGISTRATION), NULL, v_action_id);
END;


-- Adding / registering a user
PROCEDURE AddUserDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
)
AS
	v_action_id					action.action_id%TYPE;
	v_dc						chain_user.details_confirmed%TYPE;
BEGIN
	SELECT details_confirmed
	  INTO v_dc
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURItY', 'APP')
	   AND user_sid = in_user_sid;

	IF v_dc = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;

	AddActionINTERNAL(in_company_sid, in_user_sid, NULL, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_USER_REGISTRATION), NULL, v_action_id);
END;


PROCEDURE ConfirmCompanyDetailsDoActions (
	in_company_sid			security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RETURN;
	END IF;
	
	-- actually we are just clearing actions here
	-- close the actions relating to this questionnaire type, for this company, being assigned
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_company_sid = in_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND 	(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_FIRST_REGISTRATION)) OR
			(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_COMPANY_DETAILS_CHANGED));

	UPDATE company
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;

END;


PROCEDURE ConfirmUserDetailsDoActions (
	in_user_sid				security_pkg.T_SID_ID
)
AS
BEGIN
	-- actually we are just clearing actions here
	-- close the actions relating to this questionnaire type, for this user, being assigned
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_user_sid = in_user_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_USER_REGISTRATION);

	UPDATE chain_user
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

END;

PROCEDURE InviteQuestionnaireDoActions (
	in_to_company_sid			security_pkg.T_SID_ID,
	in_questionnaire_id			questionnaire.questionnaire_id%TYPE,
	in_from_company_sid			security_pkg.T_SID_ID,
	out_action_id				OUT action.action_id%TYPE
)
AS
	v_due_dtm					questionnaire_share.due_by_dtm%TYPE;
	v_action_id					action.action_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_to_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_to_company_sid);
	END IF;

	SELECT due_by_dtm 
	  INTO v_due_dtm 
	  FROM questionnaire_share 
	 WHERE app_sid = security_pkg.GetApp 
	   AND questionnaire_id = in_questionnaire_id
	   AND qnr_owner_company_sid = in_to_company_sid
	   AND share_with_company_sid = in_from_company_sid;
	
	AddActionINTERNAL(in_to_company_sid, NULL, in_from_company_sid, NULL, in_questionnaire_id, v_due_dtm, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_ASSIGNED), NULL, v_action_id);

	out_action_id := v_action_id;
END;

PROCEDURE ShareQuestionnaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT questionnaire_pkg.GetQuestionnaireId (in_qnr_owner_company_sid, in_questionnaire_class);
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_qnr_owner_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_qnr_owner_company_sid);
	END IF;
	
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE related_questionnaire_id = v_questionnaire_id
	   AND for_company_sid = in_qnr_owner_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_ASSIGNED);
	
	AddActionINTERNAL(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, NULL, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_SUBMITTED), NULL, v_action_id);
	-- message to the company that asked for the questionnaire
	event_pkg.AddEvent(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_SUBMITTED), v_event_id);
	-- message to company who submitted the quesionnaire
	event_pkg.AddEvent(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, NULL, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_SUBMITTED_SUP), v_event_id);
END;


-- approving questionnaire
PROCEDURE AcceptQuestionaireDoActions (
	in_qnr_owner_company_sid	security_pkg.T_SID_ID,
	in_share_with_company_sid	security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE DEFAULT  questionnaire_pkg.GetQuestionnaireId(in_qnr_owner_company_sid, in_questionnaire_class);
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_qnr_owner_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_qnr_owner_company_sid);
	END IF;

	-- close the actions relating to this questionnaire type, for this company, being assigned
	-- TODO: I think that this actions all questionnaires instead of just the one we're looking at
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE related_company_sid = in_qnr_owner_company_sid
	   AND for_company_sid = in_share_with_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND 	((reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_SUBMITTED)) OR 
			(reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_DEPENDENT_DATA_UPDATED)));
	
	-- message to company who approved the quesionnaire
	event_pkg.AddEvent(in_share_with_company_sid, NULL, in_qnr_owner_company_sid, NULL, v_questionnaire_id, NULL, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_APPROVED), v_event_id);

	-- add an action for the company that did the questionnaire telling them they can review their score
	AddActionINTERNAL(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, NULL, GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_APPROVED), NULL, v_action_id);
	
	-- message to company who did the quesionnaire as well
	event_pkg.AddEvent(in_qnr_owner_company_sid, NULL, in_share_with_company_sid, NULL, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_APPROVED_SUP), v_event_id);
END;

--- this is called the first time a user from a company views the
PROCEDURE ViewQResultsDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_questionnaire_id	questionnaire.questionnaire_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	v_questionnaire_id := questionnaire_pkg.GetQuestionnaireId (in_company_sid, in_questionnaire_class);

	-- close the actions relating to this questionnaire type, for this company, being approved
	UPDATE action
	   SET is_complete = 1,
		   completion_dtm = SYSDATE
	 WHERE for_company_sid = in_company_sid
	   AND is_complete = 0
	   AND app_sid = security_pkg.GetApp
	   AND related_questionnaire_id = v_questionnaire_id
	   AND (reason_for_action_id = GetReasonForActionId(action_pkg.AC_RA_QUESTIONNAIRE_APPROVED));
END;

PROCEDURE StartActionPlanDoActions (
	in_company_sid				security_pkg.T_SID_ID,
	in_questionnaire_class		questionnaire_type.CLASS%TYPE
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_event_id					event.event_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	event_pkg.AddEvent(v_company_sid, NULL, in_company_sid, NULL, NULL, NULL, event_pkg.GetEventTypeId(event_pkg.EV_ACTION_PLAN_STARTED), v_event_id);
END;

PROCEDURE CompanyDetailsUpdatedDoActions (
	in_company_sid				security_pkg.T_SID_ID
)
AS
	v_company_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
	v_risk_found				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to actions for company with sid '||in_company_sid);
	END IF;

	SELECT COUNT(*) INTO v_risk_found
	  FROM company_metric cm, company_metric_type cmt -- From metric_pkg.GetCompanyMetric
	 WHERE cm.app_sid = cmt.app_sid
	   AND cm.company_metric_type_id = cmt.company_metric_type_id
	   AND cm.app_sid = security_pkg.GetApp
	   AND cm.company_sid = in_company_sid
	   AND cmt.CLASS = 'CALCULATED_RISK';

	IF v_risk_found > 0 THEN
		AddActionINTERNAL(v_company_sid, NULL, in_company_sid, NULL, NULL, NULL, GetReasonForActionId(action_pkg.AC_RA_DEPENDENT_DATA_UPDATED), NULL, v_action_id);
	END IF;

	event_pkg.AddEvent(v_company_sid, NULL, in_company_sid, NULL, NULL, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_COMPANY_DETAILS_UPDATED), v_event_id);
END;


PROCEDURE CollectActionParams (
	in_action_ids			IN security.T_SID_TABLE
)
AS
BEGIN
	DELETE FROM tt_named_param;

	-- This is a bit dodgy. Actions and events have this concept of string replacement, but the parameters they're replacing can either contain HTML (in which case they shouldn't
	-- be escaped) or not (in which case they should be escaped). We seem to be relying on the fact that developers know which is which and whether the escaping has been done or
	-- not everywhere they're used.

	INSERT INTO tt_named_param
	(ID, name, VALUE)
	(
		SELECT action_id, 'FOR_COMPANY_SID' name, TO_CHAR(FOR_COMPANY_SID) VALUE FROM v$action WHERE FOR_COMPANY_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_COMPANY_NAME)) VALUE FROM v$action WHERE FOR_COMPANY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_COMPANY_URL' name, TO_CHAR(FOR_COMPANY_URL) VALUE FROM v$action WHERE FOR_COMPANY_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_SID' name, TO_CHAR(FOR_USER_SID) VALUE FROM v$action WHERE FOR_USER_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FULL_NAME)) VALUE FROM v$action WHERE FOR_USER_FULL_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FRIENDLY_NAME)) VALUE FROM v$action WHERE FOR_USER_FRIENDLY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'FOR_USER_URL' name, TO_CHAR(FOR_USER_URL) VALUE FROM v$action WHERE FOR_USER_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_SID' name, TO_CHAR(RELATED_COMPANY_SID) VALUE FROM v$action WHERE RELATED_COMPANY_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_COMPANY_NAME)) VALUE FROM v$action WHERE RELATED_COMPANY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_COMPANY_URL' name, TO_CHAR(RELATED_COMPANY_URL) VALUE FROM v$action WHERE RELATED_COMPANY_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_SID' name, TO_CHAR(RELATED_USER_SID) VALUE FROM v$action WHERE RELATED_USER_SID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FULL_NAME)) VALUE FROM v$action WHERE RELATED_USER_FULL_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FRIENDLY_NAME)) VALUE FROM v$action WHERE RELATED_USER_FRIENDLY_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_USER_URL' name, TO_CHAR(RELATED_USER_URL) VALUE FROM v$action WHERE RELATED_USER_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_ID' name, TO_CHAR(RELATED_QUESTIONNAIRE_ID) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_ID IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_QUESTIONNAIRE_NAME)) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_NAME IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'RELATED_QUESTIONNAIRE_URL' name, TO_CHAR(RELATED_QUESTIONNAIRE_URL) VALUE FROM v$action WHERE RELATED_QUESTIONNAIRE_URL IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_1' name, TO_CHAR(OTHER_URL_1) VALUE FROM v$action WHERE OTHER_URL_1 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_2' name, TO_CHAR(OTHER_URL_2) VALUE FROM v$action WHERE OTHER_URL_2 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
		 UNION
		SELECT action_id, 'OTHER_URL_3' name, TO_CHAR(OTHER_URL_3) VALUE FROM v$action WHERE OTHER_URL_3 IS NOT NULL AND action_id IN (SELECT COLUMN_VALUE FROM TABLE(in_action_ids))
	);
END;


PROCEDURE GenerateAlertEntries (
	in_as_of_dtm		IN TIMESTAMP
)
AS
	v_action_ids				security.T_SID_TABLE;
BEGIN
	-- NOTE: When this method is called via the scheduler, the logged on user is
	-- the builtin administrator, therefore, the user / company sids are not set
	-- in the sesstion
	NULL;

	SELECT action_id
	  BULK COLLECT INTO v_action_ids
	  FROM (
		-- get all events that have been created
		SELECT action_id
		  FROM v$action
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (created_dtm >= in_as_of_dtm OR completion_dtm >= in_as_of_dtm)
			);

	-- collect all of the params required for the events being submitted
	CollectActionParams(v_action_ids);

	-- submit our actions to the scheduler
	FOR r IN (
		SELECT A.*, cu.company_sid, cu.user_sid
		  FROM v$action A, v$company_user cu
		 WHERE A.app_sid = cu.app_sid
		   AND A.action_id IN (SELECT * FROM TABLE(v_action_ids))
		   AND A.for_company_sid = cu.company_sid
		   AND (A.for_user_sid IS NULL OR A.for_user_sid = cu.user_sid)
	) LOOP
		scheduled_alert_pkg.SetAlertEntry(
			chain_pkg.ACTION_ALERT,
			r.action_id,
			r.company_sid,
			r.user_sid,
			r.created_dtm,
			CASE WHEN r.completion_dtm IS NULL THEN 'DEFAULT' ELSE 'COMPLETED' END,
			r.message_template,
			chain_pkg.NAMED_PARAMS
		);
	END LOOP;
END;

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_for_company_url				IN	action_type.for_company_url%TYPE,
	in_related_questionnaire_url	IN	action_type.related_questionnaire_url%TYPE,
	in_related_company_url			IN	action_type.related_company_url%TYPE,
	in_for_user_url					IN	action_type.for_user_url%TYPE,
	in_other_url_1					IN	action_type.other_url_1%TYPE DEFAULT NULL,
	in_other_url_2					IN	action_type.other_url_2%TYPE DEFAULT NULL,
	in_other_url_3					IN	action_type.other_url_3%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateActionType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
        INSERT INTO action_type ( 
            app_sid,
            action_type_id, 
            message_template, 
            priority, 
            for_company_url,
            related_questionnaire_url,
            related_company_url,
            for_user_url,
			other_url_1,
			other_url_2,
			other_url_3
        ) VALUES (
            security_pkg.getApp,
            in_action_type_id,
            in_message_template,
            in_priority,
            in_for_company_url,
            in_related_questionnaire_url,
            in_related_company_url,
            in_for_user_url,
			in_other_url_1,
			in_other_url_2,
			in_other_url_3
        );
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE action_type
			   SET	message_template=in_message_template,
					priority=in_priority,
					for_company_url=in_for_company_url,
        			related_questionnaire_url=in_related_questionnaire_url,
        			related_company_url=in_related_company_url,
					for_user_url=in_for_user_url,
					other_url_1 = in_other_url_1,
					other_url_2 = in_other_url_2,
					other_url_3 = in_other_url_3
			 WHERE app_sid=security_pkg.getApp
			   AND action_type_id=in_action_type_id;
	END;
END;

PROCEDURE CreateActionType (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_message_template				IN	action_type.message_template%TYPE,
	in_priority						IN	action_type.priority%TYPE,
	in_clear_urls					IN  BOOLEAN
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateActionType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO action_type 
		(app_sid, action_type_id, message_template, priority)
		VALUES
        (security_pkg.getApp, in_action_type_id, in_message_template, in_priority);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE action_type
		   SET message_template = in_message_template,
			   priority = in_priority
		 WHERE app_sid = security_pkg.getApp
		   AND action_type_id = in_action_type_id;

		IF in_clear_urls THEN
			ClearActionTypeUrls(in_action_type_id);
        END IF;
	END;
END;

PROCEDURE ClearActionTypeUrls (
	in_action_type_id				IN	action_type.action_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearActionTypeUrls can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE action_type
	   SET 	FOR_COMPANY_URL = NULL,
			FOR_USER_URL = NULL,
			RELATED_COMPANY_URL = NULL,
			RELATED_USER_URL = NULL,
			RELATED_QUESTIONNAIRE_URL = NULL,
			OTHER_URL_1 = NULL,
			OTHER_URL_2 = NULL,
			OTHER_URL_3 = NULL
	 WHERE app_sid = security_pkg.getApp
	   AND action_type_id = in_action_type_id;
END;


PROCEDURE SetActionTypeUrl (
	in_action_type_id				IN	action_type.action_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
)
AS
	v_column_name					user_tab_columns.COLUMN_NAME%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetActionTypeUrl can only be run as BuiltIn/Administrator');
	END IF;

	-- basic stuff to prevent obvious errors, but as we need to run this as builtin admin, I don't see this getting called maliciously.
	BEGIN
		SELECT column_name
		  INTO v_column_name
		  FROM user_tab_columns
		 WHERE table_name = 'ACTION_TYPE'
		   AND column_name = UPPER(in_column_name)
		   AND (column_name LIKE '%_URL' OR column_name LIKE 'OTHER_URL_%');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, '"'||in_column_name||'" does not appear to be a url column');
	END;
	
	EXECUTE IMMEDIATE 'UPDATE action_type SET '||v_column_name||' = :url WHERE app_sid = security_pkg.GetApp AND action_type_id = :action_type_id'
	USING in_url, in_action_type_id;
END;




PROCEDURE CreateReasonForAction (
	in_reason_for_action_id		IN	reason_for_action.reason_for_action_id%TYPE,
	in_action_type_id			IN	reason_for_action.action_type_id%TYPE,
	in_class					IN	reason_for_action.CLASS%TYPE,
	in_reason_name				IN	reason_for_action.reason_name%TYPE,
	in_reason_desc				IN	reason_for_action.reason_description%TYPE,
	in_action_repeat_type_id	IN	reason_for_action.action_repeat_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateReasonForAction can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO reason_for_action (
			app_sid,
			reason_for_action_id, 
			action_type_id, 
			CLASS, 
			reason_name, 
			reason_description,
			action_repeat_type_id	
		) VALUES ( 
			security_pkg.getApp,
			in_reason_for_action_id,
			in_action_type_id,
			in_class,
			in_reason_name,
			in_reason_desc,
			NVL(in_action_repeat_type_id, action_pkg.AC_REP_ALLOW_MULTIPLE)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE reason_for_action 
					SET action_type_id=in_action_type_id,
					CLASS=in_class,
              		reason_name=in_reason_name,
              		reason_description=in_reason_desc,
					action_repeat_type_id=NVL(in_action_repeat_type_id, action_pkg.AC_REP_ALLOW_MULTIPLE)
			 WHERE app_sid=security_pkg.getApp
			   AND reason_for_action_id=in_reason_for_action_id;
	END;
END;



END action_pkg;
/

CREATE OR REPLACE PACKAGE BODY capability_pkg
IS

BOOLEAN_PERM_SET				CONSTANT security_Pkg.T_PERMISSION := security_pkg.PERMISSION_WRITE;

/************************************************************** 
			PRIVATE UTILITY METHODS 
**************************************************************/
PROCEDURE CheckPermType (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
BEGIN
	CheckPermType(GetCapabilityId(in_capability_type, in_capability), in_expected_pt); 
END;

PROCEDURE GetGroupCapabilityId (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_group				IN  chain_pkg.T_GROUP,
	out_gc_id				OUT group_capability.group_capability_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO group_capability
		(group_capability_id, company_group_name, capability_id)
		VALUES
		(group_capability_id_seq.NEXTVAL, in_group, in_capability_id)
		RETURNING group_capability_id INTO out_gc_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT group_capability_id
			  INTO out_gc_id
			  FROM group_capability
			 WHERE company_group_name = in_group
			   AND capability_id = in_capability_id;
	END;
END;

PROCEDURE GetGroupCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	out_gc_id				OUT group_capability.group_capability_id%TYPE
)
AS
BEGIN
	GetGroupCapabilityId(GetCapabilityId(in_capability_type, in_capability), in_group, out_gc_id);
END;

-- Returns a theoretical path for a capability (i.e. - no input validatation)
FUNCTION GetCapabilityPath (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN VARCHAR2
AS
	v_path				capability_type.container%TYPE;
BEGIN	
	SELECT CASE WHEN container IS NULL THEN NULL ELSE container || '/' END CASE
	  INTO v_path
	  FROM capability_type
	 WHERE capability_type_id = in_capability_type;
	
	RETURN chain_pkg.CAPABILITIES||'/'||v_path||in_capability;
END;

FUNCTION GetCapabilityPath (
	in_capability_id			IN  capability.capability_id%TYPE
) RETURN VARCHAR2
AS
	v_capability_type		chain_pkg.T_CAPABILITY_TYPE;
	v_capability			chain_pkg.T_CAPABILITY;
BEGIN	
	SELECT capability_type_id, capability_name
	  INTO v_capability_type, v_capability
	  FROM v$capability
	 WHERE capability_id = in_capability_id;
	
	RETURN GetCapabilityPath(v_capability_type, v_capability);
END;

/************************************************************** 
			PRIVATE WORKER METHODS 
**************************************************************/
FUNCTION CheckCapabilityById (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_capability_sid		security_pkg.T_SID_ID;
BEGIN
	
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;

	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session');	
	END IF;

	-- check that we're checking the correct permission type for the capability
	CheckPermType(in_capability_id, in_expected_pt);
	
	BEGIN
		v_capability_sid := securableobject_pkg.GetSidFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), GetCapabilityPath(in_capability_id));
	EXCEPTION 
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;
	
	RETURN security_pkg.IsAccessAllowedSID(v_act_id, v_capability_sid, in_permission_set);
END;

FUNCTION CheckCapabilityByName (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_capability			chain_pkg.T_CAPABILITY DEFAULT in_capability;
	v_capability_id			capability.capability_id%TYPE;
	v_capability_type_id	capability_type.capability_type_id%TYPE;
BEGIN
	IF chain_pkg.IsElevatedAccount THEN
		RETURN TRUE;
	END IF;
	
	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NULL THEN
		-- i don't think you should be able to do this, but if I've missed something, feel free to pass it on to me! (casey)
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check capabilities when the company sid is not set in session - '||security_pkg.GetSid);	
	END IF;
	
	IF in_capability = chain_pkg.COMPANYorSUPPLIER THEN
		IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
			v_capability := chain_pkg.COMPANY;
		ELSE 
			v_capability := chain_pkg.SUPPLIERS;
		END IF;
	END IF;
	
	SELECT c.capability_id, c.capability_type_id
	  INTO v_capability_id, v_capability_type_id
	  FROM v$capability c, capability_type ct
	 WHERE c.capability_type_id = ct.capability_type_id
	   AND c.capability_name = v_capability
	   AND ((
				-- the capability is a company based one, and we're looking at our own company
				c.capability_type_id = chain_pkg.CT_COMPANY AND v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			) OR (
				-- the capability is a company based one, and we're looking at a supplier
				c.capability_type_id = chain_pkg.CT_SUPPLIERS AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			) OR (
				c.capability_type_id = chain_pkg.CT_COMMON
		   ));

	-- blow up if we're trying to check common capabilities of another company
	  IF v_capability_type_id = chain_pkg.CT_COMMON 
	 AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	 AND v_capability <> chain_pkg.COMPANY
	 AND v_capability <> chain_pkg.SUPPLIERS
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot check common capabilities of a company that is not the company set in session');
	END IF;
	
	-- if we're checking a supplier company, ensure that they're actually a supplier
	  IF (v_capability_type_id = chain_pkg.CT_SUPPLIERS OR v_capability = chain_pkg.SUPPLIERS) 
	 AND v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	 AND NOT company_pkg.IsSupplier(v_company_sid) 
	THEN
		RETURN FALSE;
	END IF;
	
	RETURN CheckCapabilityById(in_company_sid, v_capability_id, in_permission_set, in_expected_pt);
END;

PROCEDURE SetCapabilityPermission_ (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_id		IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_gc_id					group_capability.group_capability_id%TYPE;
	v_capability_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, GetCapabilityPath(in_capability_id));
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, in_group);
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, security_pkg.GetApp, 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
BEGIN

	CheckPermType(in_capability_id, in_expected_pt);
	
	-- add the requested permission
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(v_capability_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0, 
		v_group_sid, 
		in_permission_set
	);
	
	-- we want chain admins to mirror all other permissions so that they get a complete view of the system configuration, 
	-- but not one that is beyond the scope of the intended configuration
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(v_capability_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0, 
		v_chain_admins_sid, 
		in_permission_set
	);
	
	
	GetGroupCapabilityId(in_capability_id, in_group, v_gc_id);
	
	BEGIN
		INSERT INTO APPLIED_COMPANY_CAPABILITY
		(company_sid, group_capability_id, permission_set)
		VALUES
		(in_company_sid, v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
END;

PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GrantCapability can only be run as BuiltIn/Administrator');
	END IF;

	CheckPermType(in_capability_type, in_capability, in_expected_pt);
	
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
		INSERT INTO group_capability_perm
		(group_capability_id, permission_set)
		VALUES
		(v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_perm
			   SET permission_set = in_permission_set
			 WHERE group_capability_id = v_gc_id;
	END;
END;

PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION	
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	CheckPermType(in_capability_type, in_capability, in_expected_pt);

	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, permission_set_override)
        VALUES
        (v_gc_id, in_permission_set);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_override
			   SET	permission_set_override = in_permission_set
			 WHERE group_capability_id = v_gc_id;
	END;
END;

/************************************************************** 
			SEMI-PRIVATE (PROTECTED) METHODS 
**************************************************************/
-- this method is public so that it can be accessed by card_pkg
PROCEDURE CheckPermType (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_perm_type				chain_pkg.T_CAPABILITY_PERM_TYPE;
	v_capability_name		chain_pkg.T_CAPABILITY;
BEGIN
	BEGIN
		SELECT perm_type, capability_name
		  INTO v_perm_type, v_capability_name
		  FROM v$capability
		 WHERE capability_id = in_capability_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||') not found');
	END;

	IF v_perm_type <> in_expected_pt THEN
		CASE 
			WHEN in_expected_pt = chain_pkg.BOOLEAN_PERMISSION THEN
				RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||' - '||v_capability_name||') permission is not BOOLEAN type');
			WHEN in_expected_pt = chain_pkg.SPECIFIC_PERMISSION THEN
				RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability_id||' - '||v_capability_name||') permission is not SPECIFIC type');
		END CASE;
	END IF;
END;

-- this method is public so that it can be accessed by card_pkg
FUNCTION GetCapabilityId (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN capability.capability_id%TYPE
AS
	v_cap_id				capability.capability_id%TYPE;
BEGIN
	BEGIN
		SELECT capability_id
		  INTO v_cap_id
		  FROM v$capability
		 WHERE capability_type_id = in_capability_type
		   AND capability_name = in_capability;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Capability ('||in_capability||') with type '''||in_capability_type||'''not found');
	END;
	
	RETURN v_cap_id;		
END;

-- this method is public so that it can be accessed by card_pkg
FUNCTION IsCommonCapability (
	in_capability				IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
	v_capability_type			chain_pkg.T_CAPABILITY_TYPE;
BEGIN
	SELECT MAX(capability_type_id) 
	  INTO v_capability_type
	  FROM v$capability
	 WHERE capability_name = in_capability;
	
	RETURN v_capability_type = chain_pkg.CT_COMMON;
END;

-- It is preferred that one of the standard check capability methods be used (i.e. not by name)
-- this is in place for conditional card checks in card_pkg
FUNCTION CheckCapabilityById (
	in_capability_id		IN  capability.capability_id%TYPE,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	-- we've got this funny check in place to help card_pkg check it's required capabilities
	IF in_permission_set IS NULL THEN
		RETURN CheckCapabilityById(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability_id, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	ELSE
		RETURN CheckCapabilityById(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability_id, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	END IF;
END;


/***********************************************************************************************************************
************************************************************************************************************************
************************************************************************************************************************
		PUBLIC
************************************************************************************************************************
************************************************************************************************************************
***********************************************************************************************************************/

/************************************************************** 
		SETUP AND INITIALIZATION METHODS 
**************************************************************/
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
)
AS
	v_count						NUMBER(10);
	v_ct						chain_pkg.T_CAPABILITY_TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		RegisterCapability(chain_pkg.CT_COMPANY, in_capability, in_perm_type);
		RegisterCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_perm_type);
		RETURN;	
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$capability
	 WHERE capability_name = in_capability
	   AND (
	   			(capability_type_id = chain_pkg.CT_COMMON AND (in_capability_type = chain_pkg.CT_COMPANY OR in_capability_type = chain_pkg.CT_SUPPLIERS))
	   		 OR (in_capability_type = chain_pkg.CT_COMMON AND (capability_type_id = chain_pkg.CT_COMPANY OR capability_type_id = chain_pkg.CT_SUPPLIERS))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type) 
	VALUES 
	(capability_id_seq.nextval, in_capability, in_capability_type, in_perm_type);

END;

/******************************************
	GrantCapability
******************************************/
-- boolean
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS	
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN	
	IF IsCommonCapability(in_capability) THEN
		GrantCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	ELSE
		GrantCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
		GrantCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	END IF;
END;

-- boolean
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS	
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN	
	GrantCapability(in_capability_type, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF IsCommonCapability(in_capability) THEN
		GrantCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	ELSE
		GrantCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
		GrantCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	END IF;
END;

-- specific	
PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	GrantCapability(in_capability_type, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
END;

/******************************************
	HideCapability
******************************************/
PROCEDURE HideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		HideCapability(chain_pkg.CT_COMMON, in_capability, in_group);
	ELSE
		HideCapability(chain_pkg.CT_COMPANY, in_capability, in_group);
		HideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group);
	END IF;
END;

PROCEDURE HideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, hide_group_capability)
        VALUES
        (v_gc_id, chain_pkg.ACTIVE);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE group_capability_override
			   SET	hide_group_capability=chain_pkg.ACTIVE
			 WHERE group_capability_id=v_gc_id;
	END;
END;

/******************************************
	OverrideCapability
******************************************/
-- boolean
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		OverrideCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	ELSE
		OverrideCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
		OverrideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
	END IF;
END;

-- boolean
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	OverrideCapability(in_capability_type, in_capability, in_group, chain_pkg.BOOLEAN_PERMISSION, BOOLEAN_PERM_SET);
END;

--specific
PROCEDURE OverrideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		OverrideCapability(chain_pkg.CT_COMMON, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	ELSE
		OverrideCapability(chain_pkg.CT_COMPANY, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
		OverrideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
	END IF;
END;

--specific
PROCEDURE OverrideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	OverrideCapability(in_capability_type, in_capability, in_group, chain_pkg.SPECIFIC_PERMISSION, in_permission_set);
END;

/******************************************
	SetCapabilityPermission
******************************************/
-- boolean
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMMON, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	ELSE
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMPANY, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_SUPPLIERS, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
	END IF;
END;

-- boolean
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(in_capability_type, in_capability), BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

--specific
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMMON, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	ELSE
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_COMPANY, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
		SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(chain_pkg.CT_SUPPLIERS, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
	END IF;
END;

--specific
PROCEDURE SetCapabilityPermission (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group				IN  chain_pkg.T_GROUP,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
BEGIN
	SetCapabilityPermission_(in_company_sid, in_group, GetCapabilityId(in_capability_type, in_capability), in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;




/******************************************
	RefreshCompanyCapabilities
******************************************/
PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS	
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_capability_sid		security_pkg.T_SID_ID;
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, security_pkg.GetApp, 'Groups/Everyone');
BEGIN
	
	-- ensure that all capabilities have been created
	FOR r IN (
		SELECT *
		  FROM v$capability
		 ORDER BY capability_id
	) LOOP		
		BEGIN
			securableobject_pkg.CreateSO(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, GetCapabilityPath(r.capability_type_id, NULL)), security_pkg.SO_CONTAINER, r.capability_name, v_capability_sid);
			
			-- don't inherit dacls
			securableobject_pkg.SetFlags(v_act_id, v_capability_sid, 0);
			-- clean existing ACE's
			acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capability_sid));
			
			acl_pkg.AddACE(v_act_id, Acl_pkg.GetDACLIDForSID(v_capability_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				0, v_everyone_sid, security_pkg.PERMISSION_ADD_CONTENTS);	
		EXCEPTION 
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;	
	END LOOP;

	-- Apply any capability permissions that have not already been applied to the this company
	FOR r IN (
		SELECT gcp.*, c.perm_type, c.capability_type_id, c.capability_name
		  FROM v$group_capability_permission gcp, v$capability c
		 WHERE gcp.capability_id = c.capability_id
		   AND gcp.group_capability_id NOT IN (
				SELECT group_capability_id
				  FROM applied_company_capability
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND company_sid = in_company_sid
			)
	) LOOP		
		SetCapabilityPermission_(in_company_sid, r.company_group_name, r.capability_id, r.permission_set, r.perm_type);
	END LOOP;


END;


/************************************************************** 
		CHECKS AS C# COMPATIBLE METHODS 
**************************************************************/
PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByName(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set, out_result) THEN
		out_result := 1;
	END IF;
END;

PROCEDURE CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_pkg.T_PERMISSION,
	out_result				OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION) THEN
		out_result := 1;
	END IF;
END;



/************************************************************** 
		CHECKS AS PLSQL COMPATIBLE METHODS 
**************************************************************/
FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(in_company_sid, in_capability, BOOLEAN_PERM_SET, chain_pkg.BOOLEAN_PERMISSION);
END;

FUNCTION CheckCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_capability, in_permission_set);
END;

FUNCTION CheckCapability (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
) RETURN BOOLEAN
AS
BEGIN
	RETURN CheckCapabilityByName(in_company_sid, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION);
END;

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DeleteCapability can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_capability_type = chain_pkg.CT_COMPANIES THEN
		DeleteCapability(chain_pkg.CT_COMPANY, in_capability);
		DeleteCapability(chain_pkg.CT_SUPPLIERS, in_capability);
		RETURN;
	END IF;
	
	FOR com IN (
		SELECT company_sid
		  FROM company
	) LOOP
		FOR cap IN (
			SELECT capability_type_id, capability_name
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type
		) LOOP
			BEGIN
				securableobject_pkg.DeleteSO(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, com.company_sid, GetCapabilityPath(cap.capability_type_id, cap.capability_name)));
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL;
			END;
		END LOOP;
	END LOOP;
	
	DELETE FROM applied_company_capability
	 WHERE group_capability_id IN (
		SELECT group_capability_id
		  FROM group_capability
		 WHERE capability_id IN (
			SELECT capability_id
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type));
			   
	DELETE FROM group_capability_override
	 WHERE group_capability_id IN (
		SELECT group_capability_id
		  FROM group_capability
		 WHERE capability_id IN (
			SELECT capability_id
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type));
			   
	DELETE FROM group_capability_perm
	 WHERE group_capability_id IN (
		SELECT group_capability_id
		  FROM group_capability
		 WHERE capability_id IN (
			SELECT capability_id
			  FROM capability
			 WHERE capability_name LIKE in_capability
			   AND capability_type_id = in_capability_type));
		   
	DELETE FROM group_capability
	 WHERE capability_id IN (
		SELECT capability_id
		  FROM capability
		 WHERE capability_name LIKE in_capability
		   AND capability_type_id = in_capability_type);
		   
	UPDATE card_group_card
	   SET required_capability_id = NULL
	 WHERE required_capability_id IN (
		SELECT capability_id
		  FROM capability
		 WHERE capability_name LIKE in_capability
		   AND capability_type_id = in_capability_type);
		   
	DELETE FROM capability
	 WHERE capability_name LIKE in_capability
	   AND capability_type_id = in_capability_type;
END;

END capability_pkg;
/

CREATE OR REPLACE PACKAGE BODY card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';

/*******************************************************************
	Private
*******************************************************************/
FUNCTION GetCardId (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN card.card_id%TYPE
AS
	v_card_id				card.card_id%TYPE;
	e_too_many_rows			EXCEPTION;
	PRAGMA EXCEPTION_INIT (e_too_many_rows, -01422);	
BEGIN
	BEGIN
		SELECT card_id
		  INTO v_card_id
		  FROM card
		 WHERE LOWER(js_class_type) = LOWER(in_js_class);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card with js class type = '''||in_js_class||'''');
		WHEN e_too_many_rows THEN
			RAISE_APPLICATION_ERROR(-20001, 'More than one card with js class type = '''||in_js_class||'''');
	END;
    
    RETURN v_card_id;
END;

-- in reality we can only determine if the inferred type is COMMON or not, 
-- but this gives us a central point to handle the error
FUNCTION GetInferredCapabilityType (
	in_capability			IN  chain_pkg.T_CAPABILITY
) RETURN chain_pkg.T_CAPABILITY_TYPE
AS
BEGIN
	IF capability_pkg.IsCommonCapability(in_capability) THEN
		RETURN chain_pkg.CT_COMMON;
	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'Cannot infer the capability type from capability '''||in_capability||'''');
	END IF;
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_expected_pt			IN  chain_pkg.T_CAPABILITY_PERM_TYPE,
	in_invert_check			IN  BOOLEAN
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_capability_id			capability.capability_id%TYPE DEFAULT capability_pkg.GetCapabilityId(in_capability_type, in_capability);
	v_icc_val				card_group_card.invert_capability_check%TYPE DEFAULT chain_pkg.INACTIVE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'MakeCardConditional can only be run as BuiltIn/Administrator');
	END IF;
	
	capability_pkg.CheckPermType(v_capability_id, in_expected_pt);
	
	IF in_invert_check THEN 
		v_icc_val := chain_pkg.ACTIVE;
	END IF;
	
	UPDATE card_group_card
	   SET required_capability_id = v_capability_id,
	       required_permission_set = in_permission_set,
	       invert_capability_check = v_icc_val
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
END;

FUNCTION HasProgressionSteps (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE
) RETURN BOOLEAN
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_from_card_id			card.card_id%TYPE DEFAULT GetCardId(in_from_js_class);
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM card_group_progression
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND from_card_id = v_from_card_id;
	 
	RETURN v_count > 0;
END;

FUNCTION IsTerminatingCard (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
) RETURN BOOLEAN
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_force_terminate		card_group_card.force_terminate%TYPE;
BEGIN
	SELECT force_terminate
	  INTO v_force_terminate
	  FROM card_group_card
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
	
	RETURN v_force_terminate = chain_pkg.ACTIVE;
END;


/*******************************************************************
	Public
*******************************************************************/
FUNCTION GetCardGroupId (
	in_group_name			IN  card_group.name%TYPE
) RETURN card_group.card_group_id%TYPE
AS
	v_group_id				card_group.card_group_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetCardGroupId can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = '''||in_group_name||'''');
	END;
	
	RETURN v_group_id;
END;

PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card.description%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCardGroup can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO card_group
		(card_group_id, name, description)
		VALUES
		(in_id, in_name, in_description);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card_group
			   SET name = in_name, 
				   description = in_description
			 WHERE card_group_id = in_id;
	END;	
			
END;

PROCEDURE DestroyCard (
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DestroyCard can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE 
	  FROM card_group_progression
	 WHERE from_card_id = v_card_id
	    OR to_card_id = v_card_id;
	
	DELETE
	  FROM card_progression_action
	 WHERE card_id = v_card_id;

	DELETE 
	  FROM card_group_card
	 WHERE card_id = v_card_id;
	
	DELETE 
	  FROM card
	 WHERE card_id = v_card_id;	
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, null, null);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, null, in_progression_actions);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE
)
AS
BEGIN
	RegisterCard (in_desc, in_class, in_js_path, in_js_class, in_css_path, null);
END;

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_css_path				IN  card.css_include%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
	v_card_id				card.card_id%TYPE;
	v_found					BOOLEAN;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterCard can only be run as BuiltIn/Administrator');
	END IF;
		
	BEGIN
		INSERT INTO card
		(card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES
		(card_id_seq.NEXTVAL, in_desc, in_class, in_js_path, in_js_class, in_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE card 
			   SET description = in_desc,
					class_type = in_class,
					js_include = in_js_path,
					css_include = in_css_path
		     WHERE js_class_type = in_js_class
		 RETURNING card_id INTO v_card_id;
	END;
	
	AddProgressionAction(in_js_class, DEFAULT_ACTION);
	
	-- empty array check
	IF in_progression_actions IS NULL OR in_progression_actions.COUNT = 0 THEN
		DELETE FROM card_group_progression
		 WHERE from_card_id = v_card_id
		   AND from_card_action <> DEFAULT_ACTION;
		  
		DELETE FROM card_progression_action
		 WHERE card_id = v_card_id
		   AND action <> DEFAULT_ACTION;
	ELSE
		-- urg - allow non-destructive re-registrations
		-- Note: we're not worried that this isn't a very efficient way of looking at this
		-- as it only happens during card registration
		
		-- loop through existing actions for this card
		FOR r IN (
			SELECT action
			  FROM card_progression_action
			 WHERE card_id = v_card_id
			   AND action <> DEFAULT_ACTION
		) LOOP
			v_found := FALSE;
			
			-- see if we're re-registering the action
			FOR i IN in_progression_actions.FIRST .. in_progression_actions.LAST 
			LOOP
				IF LOWER(TRIM(in_progression_actions(i))) = r.action THEN
					v_found := TRUE;
				END IF;
			END LOOP;
			
			-- if we're not re-registering the action, clean it up
			IF NOT v_found THEN
				DELETE FROM card_group_progression
				 WHERE from_card_id = v_card_id
				   AND from_card_action = r.action;
			
				DELETE FROM card_progression_action
				 WHERE card_id = v_card_id
				   AND action = r.action;
			END IF;		
		END LOOP;
	
		AddProgressionActions(in_js_class, in_progression_actions);
	END IF;	
END;

PROCEDURE AddProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_action	IN  card_progression_action.action%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
BEGIN	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddProgressionAction can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO card_progression_action
		(card_id, action)
		VALUES
		(v_card_id, LOWER(TRIM(in_progression_action)));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE,
	in_progression_actions	IN  T_STRING_LIST
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddProgressionActions can only be run as BuiltIn/Administrator');
	END IF;
	
	FOR i IN in_progression_actions.FIRST .. in_progression_actions.LAST 
	LOOP
		AddProgressionAction(in_js_class, in_progression_actions(i));	
	END LOOP;
END;

PROCEDURE RenameProgressionAction (
	in_js_class				IN  card.js_class_type%TYPE,
	in_from_action 			IN  card_progression_action.action%TYPE,
	in_to_action 			IN  card_progression_action.action%TYPE
)
AS
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);
	v_count					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RenameProgressionAction can only be run as BuiltIn/Administrator');
	END IF;
	
	-- check that the from_action exists
	SELECT COUNT(*)
	  INTO v_card_id
	  FROM card_progression_action
	 WHERE card_id = v_card_id
	   AND action = LOWER(TRIM(in_from_action));
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'A progression action named '''||in_from_action||''' is not registered for card '''||in_js_class||'''');
	END IF;
	
	-- check that the to_action does not exist
	SELECT COUNT(*)
	  INTO v_card_id
	  FROM card_progression_action
	 WHERE card_id = v_card_id
	   AND action = LOWER(TRIM(in_to_action));

	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'A progression action named '''||in_to_action||''' is already registered for card '''||in_js_class||'''');
	END IF;
	
	AddProgressionAction(in_js_class, in_to_action);
	
	UPDATE card_group_progression
	   SET from_card_action = LOWER(TRIM(in_to_action))
	 WHERE from_card_id = v_card_id
	   AND from_card_action = LOWER(TRIM(in_from_action));

	-- if we're currently logged into an application, this may fail because rls prevents us from updating all rows
	-- it's possible that it will succeed if we're logged in, but the progression is not registered in other applications
	DELETE FROM card_progression_action
	  WHERE card_id = v_card_id
	    AND action = LOWER(TRIM(in_from_action));	
END;

FUNCTION GetProgressionActions (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN T_STRING_LIST
AS
	v_list 					T_STRING_LIST;
	v_card_id				card.card_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'GetProgressionActions can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		v_card_id := GetCardId(in_js_class);
	EXCEPTION
		-- card not found
		WHEN OTHERS THEN
			RETURN NULL;
	END;
	
	SELECT action
	  BULK COLLECT INTO v_list
	  FROM card_progression_action
	 WHERE card_id = v_card_id;
	
	RETURN v_list;
END;

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE;
	v_pos					NUMBER(10) DEFAULT 0;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetGroupCards can only be run as BuiltIn/Administrator');
	END IF;
		
	DELETE FROM card_group_progression
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id;
	
	DELETE FROM card_group_card
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id;
	
	-- empty array check
	IF in_card_js_types IS NULL OR in_card_js_types.COUNT = 0 THEN
		RETURN;
	END IF;
	
	FOR i IN in_card_js_types.FIRST .. in_card_js_types.LAST 
	LOOP
	
		v_card_id := GetCardId(in_card_js_types(i));

		INSERT INTO card_group_card
		(card_group_id, card_id, position)
		VALUES
		(v_group_id, v_card_id, v_pos);
		
		v_pos := v_pos + 1;
	
	END LOOP;
	
END;

PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_to_js_class			IN  card.js_class_type%TYPE
)
AS
BEGIN
	RegisterProgression(in_group_name, in_from_js_class, T_CARD_ACTION_LIST(
		T_CARD_ACTION_ROW(DEFAULT_ACTION, in_to_js_class)
	));	
END;


PROCEDURE RegisterProgression (
	in_group_name			IN  card_group.name%TYPE,
	in_from_js_class		IN  card.js_class_type%TYPE,
	in_action_list			IN  T_CARD_ACTION_LIST
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_from_card_id			card.card_id%TYPE DEFAULT GetCardId(in_from_js_class);
	v_to_card_id			card.card_id%TYPE;
	v_action				T_CARD_ACTION_ROW;
	v_count					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterProgression can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM card_group_progression
	 WHERE app_sid = security_pkg.GetApp
	   AND card_group_id = v_group_id
	   AND from_card_id = v_from_card_id;
	
	IF in_action_list IS NULL OR in_action_list.COUNT = 0 THEN
		RETURN;
	END IF;
	
	IF IsTerminatingCard(in_group_name, in_from_js_class) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot add progression steps to terminating card ('||in_from_js_class||') in card group "'||in_group_name||'"');
	END IF;
	
	FOR i IN in_action_list.FIRST .. in_action_list.LAST 
	LOOP
		v_action := in_action_list(i);
		v_to_card_id := GetCardId(v_action.go_to_js_class);
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_progression_action
		 WHERE card_id = v_from_card_id
		   AND action = v_action.on_action;
		
		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Progression action "'||v_action.on_action||'" not found for card "'||in_from_js_class||'"');
		END IF;
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_group_card
		 WHERE card_group_id = v_group_id
		   AND card_id = v_from_card_id;
		
		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'From card "'||in_from_js_class||'" not found in card group "'||in_group_name||'"');
		END IF;
		
		-- let's give a nicer message than "integrity constraint violated..."
		SELECT COUNT(*)
		  INTO v_count
		  FROM card_group_card
		 WHERE card_group_id = v_group_id
		   AND card_id = v_to_card_id;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'To card "'||v_action.go_to_js_class||'" not found in card group "'||in_group_name||'"');
		END IF;
		
		INSERT INTO card_group_progression
		(card_group_id, from_card_id, from_card_action, to_card_id)
		VALUES
		(v_group_id, v_from_card_id, v_action.on_action, v_to_card_id);
	END LOOP;
END;

PROCEDURE MarkTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);	
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'MarkTerminate can only be run as BuiltIn/Administrator');
	END IF;
	
	IF HasProgressionSteps(in_group_name, in_js_class) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot mark a card as terminating when it already has progression steps - ('||in_js_class||') in card group '||in_group_name);
	END IF;
	
	UPDATE card_group_card
	   SET force_terminate = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
	
END;

PROCEDURE ClearTerminate (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
)
AS
	v_group_id				card_group.card_group_id%TYPE DEFAULT GetCardGroupId(in_group_name);
	v_card_id				card.card_id%TYPE DEFAULT GetCardId(in_js_class);	
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTerminate can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE card_group_card
	   SET force_terminate = chain_pkg.INACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND card_group_id = v_group_id
	   AND card_id = v_card_id;
END;


PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, NULL, chain_pkg.BOOLEAN_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, FALSE);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, GetInferredCapabilityType(in_capability), in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, in_invert_check);
END;

PROCEDURE MakeCardConditional (
	in_group_name			IN  card_group.name%TYPE,
	in_js_class				IN  card.js_class_type%TYPE,
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_permission_set		IN  security_Pkg.T_PERMISSION,
	in_invert_check			IN  BOOLEAN
)
AS
BEGIN
	MakeCardConditional(in_group_name, in_js_class, in_capability_type, in_capability, in_permission_set, chain_pkg.SPECIFIC_PERMISSION, in_invert_check);
END;


PROCEDURE GetManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cards_to_use			security.T_SID_TABLE := security.T_SID_TABLE(); -- we'll use a sid table to collect card ids
	v_use_card				BOOLEAN;
BEGIN
	-- no sec checks - cards should provide their own sec checks where required
	-- (we need this to work for EVERYONE)
	
	-- we're going to build up a list of cards to include in the manager based on required capability (if set)
	FOR r IN (
		SELECT *
		  FROM card_group_card
		 WHERE app_sid = security_pkg.GetApp
		   AND card_group_id = in_card_group_id
	) LOOP
		-- if there's no required capability, include it
		IF r.required_capability_id IS NULL THEN
			v_use_card := TRUE;
		ELSE
		-- include the card if the capability passes
			v_use_card := capability_pkg.CheckCapabilityById(r.required_capability_id, r.required_permission_set);
		END IF;
		
		IF r.invert_capability_check = chain_pkg.ACTIVE THEN
			v_use_card := NOT v_use_card;
		END IF;
		
		-- if we're including the card, add it to tmp table
		IF v_use_card THEN
			v_cards_to_use.EXTEND;
			v_cards_to_use(v_cards_to_use.COUNT) := r.card_id;
		END IF;
	END LOOP;
	
	-- get the manager data
	OPEN out_manager_cur FOR
		SELECT * 
		  FROM card_group
		 WHERE card_group_id = in_card_group_id;
	
	-- get the card data
	OPEN out_card_cur FOR
		SELECT c.*, cg.force_terminate 
		  FROM card c, card_group_card cg
		 WHERE cg.app_sid = security_pkg.GetApp
		   AND cg.card_group_id = in_card_group_id
		   AND cg.card_id = c.card_id
		   AND cg.card_id IN (SELECT COLUMN_VALUE FROM TABLE(v_cards_to_use))
		 ORDER BY position;

	-- get the progression data
	OPEN out_progression_cur FOR
		SELECT fc.js_class_type from_js_class_type, cgp.from_card_action, tc.js_class_type to_js_class_type
		  FROM card_group_progression cgp, card fc, card tc
		 WHERE cgp.app_sid = security_pkg.GetApp
		   AND cgp.card_group_id = in_card_group_id
		   AND cgp.from_card_id IN (SELECT COLUMN_VALUE FROM TABLE(v_cards_to_use))
		   AND cgp.to_card_id IN (SELECT COLUMN_VALUE FROM TABLE(v_cards_to_use))
		   AND cgp.from_card_id = fc.card_id
		   AND cgp.to_card_id = tc.card_id
		 ORDER BY fc.card_id;
END;


END card_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain_pkg
IS

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO chain_user
		(user_sid, registration_status_id)
		VALUES
		(in_user_sid, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
)
AS
BEGIN
	-- NO SEC CHECKS - you can only set default settings for the user that you're logged in as in the current application
	
	BEGIN
		INSERT INTO user_setting
		(name, number_value, string_value)
		VALUES
		(LOWER(TRIM(in_name)), in_number_value, in_string_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting
			   SET number_value = in_number_value,
			   	   string_value = in_string_value
			 WHERE name = LOWER(TRIM(in_name))
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END;

END;

-- we need to pass in dummy because for some very very strange reason, we get an exception if we pass in a string array as the first param 
PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_t_names				security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_names);
BEGIN
	-- NO SEC CHECKS - you can only get default settings for the user that you're logged in as in the current application
	OPEN out_cur FOR
		SELECT name, number_value, string_value
		  FROM user_setting
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND name IN (SELECT LOWER(TRIM(value)) FROM TABLE(v_t_names));
END;


PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	INVITATION_EXPIRATION_DAYS,
				SITE_NAME,
				ADMIN_HAS_DEV_ACCESS,
				SUPPORT_EMAIL,
				NEWSFLASH_SUMMARY_SP,
				QUESTIONNAIRE_FILTER_CLASS,
				LAST_GENERATE_ALERT_DTM,
				SCHEDULED_ALERT_INTVL_MINUTES,
				CHAIN_IMPLEMENTATION,
				COMPANY_HELPER_SP,
				DEFAULT_RECEIVE_SCHED_ALERTS,
				OVERRIDE_SEND_QI_PATH,
				LOGIN_PAGE_MESSAGE,
				INVITE_FROM_NAME_ADDENDUM,
				SCHED_ALERTS_ENABLED,
				LINK_HOST,
				NVL(TOP_COMPANY_SID, 0) TOP_COMPANY_SID
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 				security_pkg.T_SID_ID;
BEGIN
	v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');
	RETURN v_sid_id;
END;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM v$country
		 ORDER BY LOWER(name);
END;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE
AS
BEGIN
	RETURN TO_DATE(in_str_val, 'DD/MM/YY HH24:MI:SS');
END;

PROCEDURE IsChainAdmin  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainAdmin THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainAdmin 
RETURN BOOLEAN
AS
BEGIN
	RETURN IsChainAdmin(security_pkg.GetSid);
END;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, in_user_sid)) T
		 WHERE T.sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;			 
	END IF;	
	
	RETURN FALSE;
END;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN in_sid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Chain/BuiltIn/Invitation Respondent');
END;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsInvitationRespondant(in_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

FUNCTION IsElevatedAccount
RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;
	
	IF IsInvitationRespondant(security_pkg.GetSid) THEN
		RETURN TRUE;
	END IF;
	
	IF security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon') THEN
		RETURN TRUE;
	END IF;
	
	RETURN FALSE;
END;

-- use with care!
-- just issues the ACT, i.e. doesn't stick it into SYS_CONTEXT
FUNCTION LogonBuiltinAdmin
RETURN security_pkg.T_ACT_ID
AS
	v_act		security_pkg.T_ACT_ID;
BEGIN
	-- we don't want to set the security context
	v_act := user_pkg.GenerateACT(); 
	Act_Pkg.Issue(security_pkg.SID_BUILTIN_ADMINISTRATOR, v_act, 3600, SYS_CONTEXT('SECURITY','APP'));
	RETURN v_act;
END;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN

	SELECT top_company_sid
	  INTO v_company_sid
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Top company sid is not set');
	END IF;

	RETURN v_company_sid;
END;


END chain_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.chain_link_pkg
IS

PROCEDURE CallLinkProc (
	in_proc_call				IN  VARCHAR2,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE DEFAULT NULL
)
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE := NULL;
	PROC_NOT_FOUND				EXCEPTION;
	PRAGMA EXCEPTION_INIT (PROC_NOT_FOUND, -06550);
BEGIN
	IF in_questionnaire_id IS NOT NULL THEN
		-- use the helper for the questionnaire_type if possible
		SELECT db_class
		  INTO v_helper_pkg
		  FROM questionnaire q
			JOIN questionnaire_type qt ON q.questionnaire_type_id = qt.questionnaire_type_id
		 WHERE questionnaire_id = in_questionnaire_id;
	END IF;
	
	IF v_helper_pkg IS NULL THEN 
		-- default to company
		SELECT company_helper_sp
		  INTO v_helper_pkg 
		  FROM customer_options co
	     WHERE app_sid = security_pkg.getApp;
	END IF;
	   	 
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || v_helper_pkg || '.' || in_proc_call || ';END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;


PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('AddCompanyUser(' || in_user_sid || ', ' || 
									in_company_sid || ')');
END;

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('AddCompany(' || in_company_sid || ')');
END;

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('DeleteCompany(' || in_company_sid || ')');
END;

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN  security_pkg.T_SID_ID,
	in_from_user_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('InviteCreated(' || in_invitation_id || ', ' ||
									in_from_company_sid || ', ' ||
									in_from_user_sid || ', ' ||
									in_to_user_sid || ')');
END;

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	CallLinkProc('QuestionnaireAdded(' || in_from_company_sid || ', ' ||
											in_to_company_sid || ', ' ||
											in_to_user_sid || ', ' ||
											in_questionnaire_id || ')', in_questionnaire_id);
END;

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateCompany(' || in_company_sid || ')');
END;


PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateUser(' || in_user_sid || ')');
END;


PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ApproveUser(' || in_company_sid || ', ' ||
									in_user_sid || ')');
END;

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	CallLinkProc('ActivateRelationship(' || in_purchaser_company_sid || ', ' ||
											in_supplier_company_sid || ')');
END;

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_comp_helper				customer_options.company_helper_sp%TYPE;
	/*
		For some reason, if you pass out_titles in to the execute immediate statement
		it barfs on linux with an invalid cursor exception when returning the cursor
		to the webserver, although it works fine on Win7 x64.
		The solution appears to be declaring another cursor locally, assigning it to
		that and then passing it back out
	*/
	c_titles					security_pkg.T_OUTPUT_CUR;
	e_proc_not_found			EXCEPTION;
	PRAGMA EXCEPTION_INIT (e_proc_not_found, -06550);
BEGIN
	SELECT COMPANY_HELPER_SP INTO v_comp_helper 
							 FROM customer_options
							WHERE app_sid=security_pkg.getApp;
	IF v_comp_helper IS NOT NULL THEN
		BEGIN
            execute immediate (
				'BEGIN ' || v_comp_helper || '.GetWizardTitles(:card_group,:out_titles);END;'
			) USING in_card_group_id, c_titles;
			out_titles := c_titles;
			RETURN;
		EXCEPTION
			WHEN e_proc_not_found THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	OPEN out_titles FOR 
		SELECT NULL AS WIZARD_TITLE, NULL AS WIZARD_SUB_TITLE FROM dual;
END;

PROCEDURE AddProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	CallLinkProc('AddProduct(' || in_product_id || ')');
END;

PROCEDURE KillProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	CallLinkProc('KillProduct(' || in_product_id || ')');
END;

END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE BODY cmpnt_cmpnt_relationship_pkg
IS

PROCEDURE AttachComponent (
	in_parent_component_id IN component.component_id%TYPE,
	in_component_id		   IN component.component_id%TYPE	
)
AS
	v_position				cmpnt_cmpnt_relationship.position%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_parent_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on components for company with sid ' || component_pkg.GetComponentCompanySid(in_parent_component_id));
	END IF;
	
	IF component_pkg.GetComponentCompanySid(in_parent_component_id) <> component_pkg.GetComponentCompanySid(in_component_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannont attach components which are owned by different companies');
	END IF;

	
	SELECT NVL(MAX(position), 0) + 1
	  INTO v_position
	  FROM cmpnt_cmpnt_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_parent_component_id;
	
	BEGIN 
		INSERT INTO cmpnt_cmpnt_relationship
		(parent_component_id, component_id, position)
		VALUES
		(in_parent_component_id, in_component_id, v_position);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;


PROCEDURE DetachComponent (
	in_component_id 		IN component.component_id%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on components for company with sid ' || component_pkg.GetComponentCompanySid(in_component_id));
	END IF;
	
	-- fully delete component relationship, no matter whether this component is the parent or the child
	DELETE FROM cmpnt_cmpnt_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (component_id = in_component_id OR parent_component_id = in_component_id);
END;

PROCEDURE DetachChildComponents (
	in_component_id		   IN component.component_id%TYPE	
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on components for company with sid ' || component_pkg.GetComponentCompanySid(in_component_id));
	END IF;

	-- fully delete all child attachments
	DELETE FROM cmpnt_cmpnt_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_component_id;
END;

PROCEDURE DetachComponent (
	in_parent_component_id IN component.component_id%TYPE,
	in_component_id		   IN component.component_id%TYPE	
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_parent_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on components for company with sid ' || component_pkg.GetComponentCompanySid(in_parent_component_id));
	END IF;

	-- delete component relationship
	DELETE FROM cmpnt_cmpnt_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_component_id = in_parent_component_id
	   AND component_id = in_component_id;

END;

END cmpnt_cmpnt_relationship_pkg;
/

CREATE OR REPLACE PACKAGE BODY cmpnt_prod_relationship_pkg
IS

	/* Note: we always link a "component" (even if this represents the whole product) to a product
	 * purchaser buys a component
	 * Supplier sells a product */

	-- Add purchaser Component -> Supplier Product to be linked
	
PROCEDURE SupplierSetCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_product_id			product.product_id%TYPE
)
AS 
BEGIN
	SetCmpntProdRel(in_purchaser_component_id, in_supplier_product_id);
	
	-- clear action / event for the supplier to map products in nothing left to do
	SupplierSetMappingAction(component_pkg.GetComponentCompanySid(in_purchaser_component_id), product_pkg.GetProductCompanySid(in_supplier_product_id));
END;

PROCEDURE SupplierSetCmpntProdPendingRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
)
AS
BEGIN
	SetCmpntProdPendingRel(in_purchaser_component_id, in_supplier_company_sid);
	
	-- add action / event for the supplier to map products
	SupplierSetMappingAction(component_pkg.GetComponentCompanySid(in_purchaser_component_id), in_supplier_company_sid);
	
END;

PROCEDURE SupplierRejectCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
)
AS
	v_purchaser_company_sid			security_pkg.T_SID_ID := component_pkg.GetComponentCompanySid(in_purchaser_component_id);
BEGIN
	SetCmpntProdPendingRel(in_purchaser_component_id, in_supplier_company_sid);
	
	UPDATE cmpnt_prod_rel_pending
	   SET    
		   rejected  			  = 1		   
	 WHERE purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid  = v_purchaser_company_sid
	   AND app_sid                = SYS_CONTEXT('SECURITY', 'APP');	
	
	-- clear action / event for the supplier to map products if nothing left to do
	SupplierSetMappingAction(v_purchaser_company_sid, in_supplier_company_sid);
END;

/*
PROCEDURE SupplierClearCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
)
AS
	v_purchaser_company_sid			security_pkg.T_SID_ID := component_pkg.GetComponentCompanySid(in_purchaser_component_id);
BEGIN

	
	DELETE FROM cmpnt_prod_rel_pending		   
	 WHERE purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid  = v_purchaser_company_sid
	   AND supplier_company_sid   = in_supplier_company_sid
	   AND app_sid                = SYS_CONTEXT('SECURITY', 'APP');	
	   
	DELETE FROM cmpnt_prod_relationship		   
	 WHERE purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid  = v_purchaser_company_sid
	   AND supplier_company_sid   = in_supplier_company_sid
	   AND app_sid                = SYS_CONTEXT('SECURITY', 'APP');
	
	-- clear action / event for the supplier to map products if nothing left to do
	SupplierSetMappingAction(v_purchaser_company_sid, in_supplier_company_sid);
END;
*/

PROCEDURE SupplierSetMappingAction (
	in_purchaser_company_sid	security_pkg.T_SID_ID,
	in_supplier_company_sid		security_pkg.T_SID_ID
)
AS
	v_count	NUMBER;
	v_action_id		action.action_id%TYPE;
BEGIN

	-- If there are no (unrejected) products left needing mapping by the supplier then clear the "mapping needed" action 
	SELECT COUNT(*) INTO v_count
	  FROM cmpnt_prod_rel_pending
	 WHERE purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND rejected = 0;
	  
	IF v_count = 0 THEN
		UPDATE action
		   SET is_complete = 1
		 WHERE related_company_sid = in_purchaser_company_sid
		   AND for_company_sid = in_supplier_company_sid 
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND reason_for_action_id = action_pkg.GetReasonForActionId(action_pkg.AC_RA_PRD_PURCHASER_MAP_NEEDED);
	ELSE 
		-- this action won't add twice
		action_pkg.AddAction(
			in_supplier_company_sid, 
			null, 
			in_purchaser_company_sid, 
			null,
			null, 
			null, 
			action_pkg.GetReasonForActionId(action_pkg.AC_RA_PRD_PURCHASER_MAP_NEEDED), 
			null, 
			v_action_id);		
	END IF;
END;
	
PROCEDURE SetCmpntProdRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_product_id			product.product_id%TYPE
)
AS 
	v_purchaser_company_sid			security_pkg.T_SID_ID := component_pkg.GetComponentCompanySid(in_purchaser_component_id);
	v_supplier_company_sid			security_pkg.T_SID_ID := product_pkg.GetProductCompanySid(in_supplier_product_id);
	v_count							NUMBER;
BEGIN

	-- need to have write permission on the component or product to link them
	IF NOT 
		((capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_purchaser_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)) OR
		(capability_pkg.CheckCapability(product_pkg.GetProductCompanySid(in_supplier_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)))
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting up relationship between component with id ' || in_purchaser_component_id || ' and pproduct with id ' || in_supplier_product_id);
	END IF;

	-- Need to check one side of the relationship and see if 
	-- this component has already been linked to any product for this supplier
	SELECT COUNT(*) INTO v_count 
	  FROM cmpnt_prod_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid = v_purchaser_company_sid
	   AND supplier_company_sid = v_supplier_company_sid;

	IF v_count > 0 THEN -- exists
		UPDATE cmpnt_prod_relationship
		   SET    
			   supplier_product_id    = in_supplier_product_id
		 WHERE purchaser_component_id = in_purchaser_component_id
		   AND purchaser_company_sid  = v_purchaser_company_sid
		   AND supplier_company_sid   = v_supplier_company_sid
		   AND app_sid                = SYS_CONTEXT('SECURITY', 'APP');	
	ELSE
		INSERT INTO cmpnt_prod_relationship 
		(
			app_sid,
			purchaser_component_id,
			purchaser_company_sid,		
			supplier_product_id, 
			supplier_company_sid
		) VALUES (
			SYS_CONTEXT('SECURITY', 'APP'), 
			in_purchaser_component_id,
			v_purchaser_company_sid,
			in_supplier_product_id,
			v_supplier_company_sid
		);	
	END IF;
	
	-- now clear any pending relationships 
	DELETE FROM cmpnt_prod_rel_pending
	 WHERE purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid  = v_purchaser_company_sid
	   AND supplier_company_sid   = v_supplier_company_sid;
	
	
END;

PROCEDURE SetCmpntProdPendingRel (
	in_purchaser_component_id		component.component_id%TYPE, 
	in_supplier_company_sid			security_pkg.T_SID_ID
)
AS 
	v_purchaser_company_sid			security_pkg.T_SID_ID := component_pkg.GetComponentCompanySid(in_purchaser_component_id);
	v_count							NUMBER;
BEGIN		
	-- need to have write permission on the component or supplier product to set this pending link
	IF NOT 
		((capability_pkg.CheckCapability(v_purchaser_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)) OR
		(capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)))
	THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting up pending relationship on component with  id ' || in_purchaser_component_id);
	END IF;
	
	-- now lets see if there;s a pending relationship already 
	SELECT COUNT(*) INTO v_count 
	  FROM cmpnt_prod_rel_pending 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid = v_purchaser_company_sid;
	   
	-- update there's a pending relationship already or add new one if not
	IF v_count > 0 THEN -- exists
		UPDATE cmpnt_prod_rel_pending
		   SET    
			   supplier_company_sid   = in_supplier_company_sid,	
			   rejected				  = 0	
		 WHERE purchaser_component_id = in_purchaser_component_id
		   AND purchaser_company_sid  = v_purchaser_company_sid
		   AND app_sid                = SYS_CONTEXT('SECURITY', 'APP');	
	ELSE
		INSERT INTO cmpnt_prod_rel_pending 
		(
			app_sid,
			purchaser_component_id,
			purchaser_company_sid,		
			supplier_company_sid
		) VALUES (
			SYS_CONTEXT('SECURITY', 'APP'), 
			in_purchaser_component_id,
			v_purchaser_company_sid,
			in_supplier_company_sid
		);	
	END IF;
	
	-- now clear any confirmed relationships 
	DELETE FROM cmpnt_prod_relationship
	 WHERE purchaser_component_id = in_purchaser_component_id
	   AND purchaser_company_sid  = v_purchaser_company_sid
	   AND supplier_company_sid   = in_supplier_company_sid;

	
END;

PROCEDURE GetCompProdPairs (
	in_search					VARCHAR2,
	in_purchaser_company_sid	security_pkg.T_SID_ID,
	in_supplier_company_sid		security_pkg.T_SID_ID,
	in_show_need_attention		NUMBER,
	in_start					NUMBER,
	in_page_size				NUMBER,
	in_sort_by					VARCHAR2,
	in_sort_dir					VARCHAR2,
	in_exporting				IN NUMBER,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_sort						VARCHAR2(100) DEFAULT in_sort_by||' '||in_sort_dir;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_supplier_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading products for company with sid '||in_supplier_company_sid);
	END IF;	

	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('component_description', 'product_description', 'mapped') THEN -- add support as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;
	
	-- clear the temporary table
	DELETE FROM tt_product_mapping_search;
	
	-- insert ALL of our search results into the temporary table
	INSERT INTO tt_product_mapping_search
	(	component_id, component_description, product_id, product_description, 
		mapped, rejected, code_label1, code1, code_label2, code2, code_label3, code3
	) 
	SELECT pc.component_id, pc.description component_description, NVL(sp.product_id, -1), sp.description product_description, 
			rel.mapped, rel.rejected, sp.code_label1, sp.code1, sp.code_label2, sp.code2, sp.code_label3, sp.code3
	  FROM v$product sp, -- supplier product
		   v$component pc, -- purchaser component
			(
				-- get all potential matches for purchaser component -> supplier product
				SELECT app_sid, purchaser_company_sid, purchaser_component_id, supplier_company_sid, supplier_product_id, 1 mapped, 0 rejected 
				  FROM cmpnt_prod_relationship 
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND purchaser_company_sid = in_purchaser_company_sid 
				   AND supplier_company_sid = in_supplier_company_sid
				 UNION ALL
				SELECT app_sid, purchaser_company_sid, purchaser_component_id, supplier_company_sid, supplier_product_id, 0 mapped, rejected  
				  FROM cmpnt_prod_rel_pending 
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND purchaser_company_sid = in_purchaser_company_sid 
				   AND supplier_company_sid = in_supplier_company_sid
			) rel
	 WHERE rel.app_sid = pc.app_sid
	   AND rel.app_sid = sp.app_sid(+)
	   AND rel.purchaser_component_id = pc.component_id
	   AND rel.supplier_product_id = sp.product_id(+)
	   AND (	LOWER(pc.description) LIKE v_search
			 OR LOWER(sp.description) LIKE v_search
			 OR LOWER(sp.code1)       LIKE v_search
			)
	   AND (in_show_need_attention = 0 OR rel.mapped = 0);

	-- now we'll run the sort on the data, setting a position value for each row
	EXECUTE IMMEDIATE
		'UPDATE tt_product_mapping_search o '||
		'   SET o.position = ( '||
		'		SELECT rn '||
		'		  FROM ( '||
		'				SELECT component_id, row_number() OVER (ORDER BY '||v_sort||') rn  '||
		'				  FROM tt_product_mapping_search'||
		'			   ) i  '||
		'		 WHERE o.component_id = i.component_id  '||
		'	  )';
		
	OPEN out_count_cur FOR 
		SELECT COUNT(*) total_rows
		  FROM tt_product_mapping_search;

	IF in_exporting = 1 THEN
		-- we've not implemented paging for exports as it's kinda unlikely we'll ever use it
		OPEN out_results_cur FOR
			SELECT  DECODE(mapped, 1, 'Yes', 'No') mapped, 
					DECODE(rejected, 1, 'Yes', 'No') rejected, 
					NVL2(code_label1, code_label1 || ': ' || code1, NULL) code1,
					NVL2(code_label2, code_label2 || ': ' || code2, NULL) code2,
					NVL2(code_label3, code_label3 || ': ' || code3, NULL) code3, 
					NVL(component_id, DECODE(rejected, 1, 0, -1)) component_id, 
					NVL(component_description, 'Not assigned') component_description,
					product_id, 
					NVL(product_description, 'Not assigned') product_description
			  FROM tt_product_mapping_search
			 ORDER BY position;

	ELSE
		OPEN out_results_cur FOR
			SELECT 	NVL(component_id, DECODE(rejected, 1, 0, -1)) component_id, 
					NVL(component_description, 'Not assigned') component_description, 
					NVL(product_id, DECODE(rejected, 1, 0, -1)) product_id, 
					NVL(product_description, 'Not assigned') product_description, 
					mapped, rejected, 
					code_label1, code1, 
					code_label2, code2, 
					code_label3, code3
			  FROM (
				SELECT r.*, rownum rn 
				  FROM tt_product_mapping_search r
				 WHERE (rownum <= NVL(in_start+in_page_size, rownum))
				 ORDER BY position
				   ) r
			 WHERE rn > NVL(in_start, 0);
	END IF;
	
	/*	
	IF in_exporting = 1 THEN 
		-- format nicely for export
		v_select_sql :=  '	SELECT component_id, component_description, DECODE(mapped, 1, ''Yes'', ''No'') mapped, DECODE(rejected, 1, ''Yes'', ''No'') rejected, product_id_raw product_id, product_description, '; 
		v_select_sql := v_select_sql || ' NVL2(code_label1, code_label1 || '': '' || code1, NULL) code2, NVL2(code_label2, code_label2 || '': '' || code2, NULL) code2, NVL2(code_label3, code_label3 || '': '' || code3, NULL) code3 FROM ';
	ELSE
		-- pull it all back
		v_select_sql :=  '	SELECT * FROM ';	
	END IF;
	
	
	v_select_sql := v_select_sql || 		'	( ';
	v_select_sql := v_select_sql||		'		SELECT rownum rn, p.* FROM ';
	v_select_sql := v_select_sql ||		'		( ';
	v_select_sql := v_select_sql ||		'			SELECT p.*, COUNT(*) OVER () AS total_rows FROM ( ';
	v_inner_sql := v_inner_sql || 		'				SELECT NVL(c.component_id, DECODE(rejected, 1, 0, -1)) component_id, NVL(c.description, ''Not assigned'') component_description, product_id product_id_raw, NVL(p.product_id, DECODE(rejected, 1, 0, -1)) product_id, NVL(p.description, ''Not assigned'') product_description, mapped, rejected, ';  
	v_inner_sql := v_inner_sql || 		'				  		p.code_label1, p.code1, p.code_label2, p.code2, p.code_label3, p.code3 ';
	v_inner_sql := v_inner_sql || 		'				  FROM (SELECT c.* FROM v$component c, v$product p WHERE p.root_component_id = c.component_id) c, v$product p, '; -- component joined to v$product ensures deleted prods not shown
	v_inner_sql := v_inner_sql || 		'					(SELECT purchaser_company_sid, purchaser_component_id, supplier_company_sid, supplier_product_id, 1 mapped, 0 rejected ';
	v_inner_sql := v_inner_sql || 		'					  FROM cmpnt_prod_relationship ';
	v_inner_sql := v_inner_sql || 		'					 WHERE purchaser_company_sid = :in_purchaser_company_sid AND supplier_company_sid = :in_supplier_company_sid ';
	v_inner_sql := v_inner_sql || 		'					UNION ';
	v_inner_sql := v_inner_sql || 		'					SELECT purchaser_company_sid, purchaser_component_id, supplier_company_sid, supplier_product_id, 0 mapped, rejected  ';
	v_inner_sql := v_inner_sql || 		'					  FROM cmpnt_prod_rel_pending ';
	v_inner_sql := v_inner_sql || 		'					 WHERE purchaser_company_sid = :in_purchaser_company_sid AND supplier_company_sid = :in_supplier_company_sid ) rel ';
	v_inner_sql := v_inner_sql || 		'				 WHERE rel.purchaser_component_id = c.component_id ';
	v_inner_sql := v_inner_sql || 		'				   AND rel.supplier_product_id = p.product_id (+) ';
	v_inner_sql := v_inner_sql || 		'				   AND (((:in_search IS NULL) OR (LOWER(c.description) LIKE :v_search)) OR ';
	v_inner_sql := v_inner_sql || 		'				   	   ((:in_search IS NULL) OR (LOWER(p.description) LIKE :v_search)) OR  ';
	v_inner_sql := v_inner_sql || 		'				   	   ((:in_search IS NULL) OR (LOWER(p.code1) LIKE :v_search))) ';
	v_inner_sql := v_inner_sql || 		'				   AND ((:in_show_need_attention = 0) OR (mapped = 0)) ';
	v_select_sql := v_select_sql ||		'			) p ';
    v_select_sql := v_select_sql || 		'   		ORDER BY ' || in_sort_by || ' ' || in_sort_dir;	
	v_select_sql := v_select_sql ||		'		) p ';
	v_paging_sql := v_paging_sql ||		'		WHERE (rownum <= NVL(:page_end, rownum)) '; -- null page_end returns all from page_start
    v_paging_sql := v_paging_sql || 		'   	ORDER BY ' || in_sort_by || ' ' || in_sort_dir;
	v_paging_sql := v_paging_sql ||		'	) p ';
	v_paging_sql := v_paging_sql ||		'	WHERE rn > NVL(:page_start, 0) ';-- null page_start returns from row 0
    v_paging_sql := v_paging_sql || 		'   ORDER BY  ' || in_sort_by || ' ' || in_sort_dir;
    */
	
END;
		

PROCEDURE GetSuppliers (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: This method already exists in company_pkg as SearchSuppliers (you can search with text = '' and page_size 0 for all results)
	OPEN out_cur FOR
	  	SELECT DISTINCT c.company_sid id, c.name description
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.supplier_company_sid 
		 ORDER BY lower(name) ASC;
	
END;

PROCEDURE GetPurchasers (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: this method should be moved to company_pkg	 
	OPEN out_cur FOR
	  	SELECT DISTINCT c.company_sid id, c.name description
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.purchaser_company_sid 
		 ORDER BY lower(name) ASC;
	
END;



END cmpnt_prod_relationship_pkg;
/

CREATE OR REPLACE PACKAGE BODY company_pkg
IS

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')) || ' (' || v_cc || ')', '/', '\');
END;

FUNCTION TrySplitSOName (
	in_name					IN  security_pkg.T_SO_NAME,
	out_company_name		OUT company.name%TYPE,
	out_country_code		OUT company.country_code%TYPE
) RETURN BOOLEAN
AS
	v_idx	NUMBER;
BEGIN
	v_idx := LENGTH(in_name);

	
	IF SUBSTR(in_name, v_idx, 1) <> ')' THEN
		RETURN FALSE;
	END IF;
	
	WHILE v_idx > 1 LOOP
		v_idx := v_idx - 1;

		IF SUBSTR(in_name, v_idx, 1) = '(' THEN
			out_company_name := SUBSTR(in_name, 1, v_idx - 2);
			out_country_code := SUBSTR(in_name, v_idx + 1, LENGTH(in_name) - v_idx - 1);
	
			RETURN GenerateSOName(out_company_name, out_country_code) = in_name;
		END IF;
	END LOOP;

	RETURN FALSE;
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_sid				IN  security_pkg.T_SID_ID,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(in_on_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0,  
		in_to_sid, 
		in_permission_set
	);
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_path				IN  varchar2,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	AddPermission(
		in_on_sid, 
		securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, in_to_path), 
		in_permission_set
	);	
END;


/**
 *	The purpose of the procedure is to be a single point of company based securable object setup. 
 *  Any changes to this procedure should be flexible enough to deal with situations where the
 *  object may or may not already exists, already have permissions etc. so that it can
 *  be called during any update scripts.
 */
PROCEDURE CreateSOStructure (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_is_new_company		IN  BOOLEAN
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_ucd_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_ADMIN_GROUP);
	v_chain_users_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_USER_GROUP);
	v_capabilities_sid		security_pkg.T_SID_ID;
	v_capability_sid		security_pkg.T_SID_ID;
	v_admins_sid			security_pkg.T_SID_ID;
	v_users_sid				security_pkg.T_SID_ID;
	v_pending_sid			security_pkg.T_SID_ID;
	v_uploads_sid			security_pkg.T_SID_ID;
BEGIN
		
	/********************************************
		CREATE OBJECTS AND ADD PERMISSIONS
	********************************************/
	
	-- ADMIN GROUP
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.ADMIN_GROUP, v_admins_sid);
	END;
	
	-- USER GROUP
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.USER_GROUP, v_users_sid);
	END;
	
	-- PENDING USER GROUP 
	BEGIN
		v_pending_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.PENDING_GROUP, v_pending_sid);
	END;
	
	-- UPLOADS CONTAINER
	BEGIN
		v_uploads_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_UPLOADS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_UPLOADS, v_uploads_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uploads_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- SETUP CAPABILITIES
	BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.CAPABILITIES);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.CAPABILITIES, v_capabilities_sid);
		
			-- don't inherit dacls
			securableobject_pkg.SetFlags(v_act_id, v_capabilities_sid, 0);
			-- clean existing ACE's
			acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capabilities_sid));
			
			AddPermission(v_capabilities_sid, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
	END;
	
	capability_pkg.RefreshCompanyCapabilities(in_company_sid);	

	/********************************************
		ADD OBJECTS TO GROUPS
	********************************************/
	-- add the users group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_users_sid, v_chain_users_sid);
	
	-- add the administrators group to the users group
	-- our group, so we're hacking this in
	--group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	BEGIN
		INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (v_admins_sid, v_users_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;

END;


FUNCTION GetGroupMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_name			IN  chain_pkg.T_GROUP
)
RETURN security.T_SO_TABLE
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN	
	RETURN group_pkg.GetDirectMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, in_group_name));
END;

-- collects a paged cursor of companies based on sids passed in as a T_ORDERED_SID_TABLE
PROCEDURE CollectSearchResults (
	in_all_results			IN  security.T_ORDERED_SID_TABLE,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_all_results);
	
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
		 	SELECT *
		 	  FROM v$company c, TABLE(in_all_results) T
		 	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND c.company_sid = T.SID_ID
		 	 ORDER BY LOWER(c.name);
	
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*, NVL(sr.active, chain_pkg.inactive) active_supplier
						  FROM v$company c, (SELECT * FROM v$supplier_relationship WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) sr, TABLE(in_all_results) T
		 	 			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	 			   AND c.app_sid = sr.app_sid(+)
		 	 			   AND c.company_sid = sr.supplier_company_sid(+)
		 	 			   AND c.company_sid = T.SID_ID
		 	 			 ORDER BY LOWER(c.name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

FUNCTION VerifyMembership (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_type			IN  chain_pkg.T_GROUP,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_g_sid					security_pkg.T_SID_ID;
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	BEGIN
		-- leave this in here so things don't blow up when we clean
		v_g_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, in_group_type);
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetMembersAsTable(v_act_id, v_g_sid))
		 WHERE sid_id = in_user_sid;
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN FALSE;
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;
	
	IF v_count > 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	END IF;
	
	RETURN v_count > 0;
END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/

/************************************************************
	SYS_CONTEXT handlers
************************************************************/
FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT in_company_sid;
BEGIN
	
	-- if v_company_sid is 0, try to get the existing company sid out of the context
	IF NVL(v_company_sid, 0) = 0 THEN
		v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;

	IF chain_pkg.IsElevatedAccount THEN
		SetCompany(v_company_sid);
		RETURN v_company_sid;
	END IF;
	
	-- first, verify that this user exists as a chain_user (ensures that views work at bare minimum)
	chain_pkg.AddUserToChain(SYS_CONTEXT('SECURITY', 'SID'));
		
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE
		   AND company_sid = v_company_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;

	-- if we've got a company sid, verify that the user is a member
	IF v_company_sid IS NOT NULL THEN
		-- is this user a group member?
		IF NOT chain_pkg.IsChainAdmin AND
		   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
		   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
			v_company_sid := NULL;
		END IF;
	END IF;
	
	-- if we don't have a company yet, check to see if a default company sid is set
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT cu.default_company_sid
			  INTO v_company_sid
			  FROM chain_user cu, v$company c
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cu.app_sid = c.app_sid
			   AND cu.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND cu.default_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, check to see if there is a top company set in customer options
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT co.top_company_sid
			  INTO v_company_sid
			  FROM customer_options co, company c
			 WHERE co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND co.app_sid = c.app_sid
			   AND co.top_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, grab the first company we're a member of alphabetically
	IF v_company_sid IS NULL THEN
		-- ok, no valid default set - might as well just sort them alphabetically by company name and 
		-- 		pick the first, at least it's predictable		
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c, (
					SELECT DISTINCT so.parent_sid_id company_sid
					  FROM security.securable_object so, TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, security_pkg.GetSid)) ug -- user group sids
					 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
					   AND so.sid_id = ug.sid_id
					   ) uc -- user companies
				 WHERE c.company_sid = uc.company_sid
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	-- if there's still no company set and we're a chain admin, pick the first company alphabetically.
	IF v_company_sid IS NULL AND chain_pkg.IsChainAdmin THEN
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;	
	END IF;

	-- set the company sid in the context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
	-- return the company sid (or 0 if it's been cleared)
	RETURN NVL(v_company_sid, 0);
	
END;

PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, 0);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	IF v_company_sid = 0 THEN
		v_company_sid := NULL;
	END IF;
	
	IF v_company_sid IS NOT NULL THEN
		IF chain_pkg.IsElevatedAccount THEN
			-- just make sure that the company exists
			SELECT COUNT(*)
			  INTO v_count
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = v_company_sid;
			
			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		ELSE
			-- is this user a group member?
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
					security_pkg.SetContext('CHAIN_COMPANY', NULL);
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		END IF;
	END IF;
		
	-- set the value in sys context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
END;

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;
	RETURN v_company_sid;
END;

/************************************************************
	Securable object handlers
************************************************************/

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
	v_chain_admins 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators');
	v_chain_users 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');
BEGIN
	
	IF in_parent_sid_id <> chain_pkg.GetCompaniesContainer THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain companies MUST be created under the application Chain/Companies container');
	END IF;
	
	IF NOT TrySplitSOName(in_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, '"'||in_name||'", "'||v_company_name||'", "'||v_country_code||'"Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
	
	-- Getting the securable object handler to create the company is a really bad idea. There are restrictions on the the characters that an SO name can comprise (and they need to
	-- be unique) - restrictions that are not applicable to company names.
	
    INSERT INTO company
    (company_sid, name, country_code)
    VALUES 
    (in_sid_id, v_company_name, TRIM(v_country_code));
    
	-- causes the groups and containers to get created
	CreateSOStructure(in_sid_id, TRUE);
	
	AddPermission(in_sid_id, security_pkg.SID_BUILTIN_ADMINISTRATOR, security_pkg.PERMISSION_STANDARD_ALL);
	AddPermission(in_sid_id, v_chain_admins, security_pkg.PERMISSION_WRITE);
	AddPermission(in_sid_id, v_chain_users, security_pkg.PERMISSION_WRITE);
	
	-- if we are creating a company add a company wide "check my details" action
	action_pkg.AddCompanyDoActions(in_sid_id);

	-- callout to customised systems
	chain_link_pkg.AddCompany(in_sid_id);
	
	-- add defaults for product codes for the new company
	product_pkg.TurnOnProductsForCompany(in_sid_id);
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
BEGIN
	IF (in_new_name IS NULL) THEN -- this is actually a virtual deletion - lets leave the name as is, but set the deleted flag
		UPDATE company
		   SET deleted = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id;
		
		RETURN;
	END IF;
		
	IF NOT TrySplitSOName(in_new_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
		
	UPDATE company
	   SET name = v_company_name,
	       country_code = TRIM(v_country_code)
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_helper_pkg	VARCHAR2(50); 
BEGIN

	--clean up all questionnaires
	FOR r IN (
		SELECT DISTINCT qt.db_class pkg
		  FROM questionnaire q, questionnaire_type qt 
		 WHERE q.questionnaire_type_id = qt.questionnaire_type_id 
		   AND q.app_sid = qt.app_sid
		   AND q.company_sid = in_sid_id
		   AND q.app_sid = security_pkg.GetApp
	)
	LOOP
		-- clear questionnaire types for this company
		IF r.pkg IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||r.pkg||'.DeleteQuestionnaires(:1);end;'
				USING in_sid_id; -- company sid
		END IF;	   
	
	END LOOP;
	
	-- now clean up all things linked to company
	
	DELETE FROM applied_company_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;


	DELETE FROM event_user_status 
	 WHERE event_id IN
	(
		SELECT event_id
		  FROM event 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM event
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- clean up actions
	DELETE FROM action_user_status 
	 WHERE action_id IN
	(
		SELECT action_id
		  FROM action 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action 
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;

	   
	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN
	(
		SELECT questionnaire_share_id
		  FROM questionnaire_share 
		 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM questionnaire_share 
	 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;
	   
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	
	DELETE FROM questionnaire
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	   
	
	DELETE FROM company_cc_email
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM company_metric
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	   
	-- clear invitations and reminders
	DELETE FROM invitation_reminder 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_company_sid = in_sid_id) 
			OR (to_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM invitation_qnr_type 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_company_sid = in_sid_id) 
			OR (to_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM invitation
	 WHERE ((from_company_sid = in_sid_id) 
		OR (to_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;


	DELETE FROM supplier_relationship
	 WHERE ((supplier_company_sid = in_sid_id) 
		OR (purchaser_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	   
	   
	-- are we OK blanking this? I think so as this is reset sensibly when ever a chain page is loaded
	UPDATE chain_user 
	   SET default_company_sid = NULL
	 WHERE default_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM newsflash_company WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	/* PRODUCT RELATED ITEMS TO CLEAR */
	-- clear the default product codes
	DELETE FROM product_code_type WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	-- clear all products and components and any links between them
	DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));	
	DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	-- clear tasks
	FOR tn IN (
		SELECT task_node_id
		  FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id 
		 ORDER BY parent_task_node_id DESC
	)
	LOOP
		FOR T IN (
			SELECT task_id
			  FROM task
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = in_sid_id 
			   AND task_node_id = tn.task_node_id
		)
		LOOP
			DELETE FROM task_doc
			 WHERE app_sid = security_pkg.GetApp
			   AND task_entry_id IN 
				(
					SELECT task_entry_id
					  FROM task_entry
					 WHERE app_sid = security_pkg.GetApp
					   AND task_id = T.task_id
				);
		
			 DELETE FROM task_entry
			  WHERE app_sid = security_pkg.GetApp
				AND task_id = T.task_id;

			
			 DELETE FROM task
			  WHERE app_sid = security_pkg.GetApp
			    AND task_id = T.task_id;
			  
		END LOOP;	
		
		DELETE FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND task_node_id = tn.task_node_id;
	END LOOP;
	
	chain_link_pkg.DeleteCompany(in_sid_id);
	
	DELETE FROM company
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

/************************************************************
	Company Management Handlers
************************************************************/

PROCEDURE VerifySOStructure
AS
BEGIN
	FOR r IN (
		SELECT company_sid
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		CreateSOStructure(r.company_sid, FALSE);
	END LOOP;
END;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	-- createSO does the sec check
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Company'), GenerateSOName(in_name, in_country_code), out_company_sid);
	
	UPDATE company
	   SET name = in_name
	 WHERE company_sid = out_company_sid;
END;

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	BEGIN
		SELECT company_sid INTO out_company_sid FROM company WHERE name=in_name AND country_code=in_country_code;
	EXCEPTION
		WHEN no_data_found THEN
			CreateCompany(in_name, in_country_code, out_company_sid);
			RETURN;
	END;		
	RAISE dup_val_on_index;
END;

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	-- user groups undder the company
	v_admin_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_pending_grp_sid		security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_users_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_other_company_grp_cnt	NUMBER;

BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	-- Now we need to delete all users from this company
	-- We cannot do this in DeleteSO for company as
	--		the users are NOT under the company in the tree - they are just members of groups under the company
	-- 		All the info we need to indentify which users to delete (group structure under company) is cleared by the security DeleteSO before the DeleteSO call is made above
	FOR r IN (
		SELECT DISTINCT user_sid 
		  FROM v$company_member 
		 WHERE company_sid = in_company_sid 
		   AND app_sid = security_pkg.GetApp
	)
	LOOP

		-- TO DO - this is not a full implementation but is to get round a current issue and will work currently
		-- we may need to implement a chain user SO type to do properly
		-- but - to prevent non chain users getting trashed this relies on 
		-- 		only chain users will be direct members unless we add people for no good reason via secmgr
		-- 		only users who have logged on to chain should be in chain user table  - though this could incluse superusers
	
		-- is this user in the groups of any other company
		SELECT COUNT(*) 
		INTO v_other_company_grp_cnt
		FROM 
		(
			-- this should just return chain company groups
			SELECT sid_id 
			  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(security_pkg.GetAct, r.user_sid))
			 WHERE sid_id NOT IN (v_admin_grp_sid, v_pending_grp_sid, v_users_grp_sid)
			 AND parent_sid_id IN (SELECT company_sid FROM company WHERE app_sid = security_pkg.GetApp)
		);
			
		IF v_other_company_grp_cnt = 0 THEN			
			-- this user is not a member of any other companies/groups so delete them
			chain.company_user_pkg.DeleteObject(security_pkg.GetAct, r.user_sid);
		END IF;
		
	END LOOP;
	
	-- finally delete the company
	securableobject_pkg.DeleteSO(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteCompany(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	securableobject_pkg.RenameSO(in_act_id, in_company_sid, NULL);
END;


PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_name					company.name%TYPE;
	v_cc					company.country_code%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Undelete access denied to company with sid '||in_company_sid);
	END IF;
	
	UPDATE company
	   SET deleted = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	RETURNING name, country_code
	  INTO v_name, v_cc;
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(v_name, v_cc));	
END;


PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_name					IN  company.name%TYPE,
	in_address_1			IN  company.address_1%TYPE,
	in_address_2			IN  company.address_2%TYPE,
	in_address_3			IN  company.address_3%TYPE,
	in_address_4			IN  company.address_4%TYPE,
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_phone				IN  company.phone%TYPE,
	in_fax					IN  company.fax%TYPE,
	in_website				IN  company.website%TYPE
)
AS
	v_cur_details			company%ROWTYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_cur_details.name <> in_name OR v_cur_details.country_code <> in_country_code THEN
		securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(in_name, in_country_code));
	END IF;
	
	UPDATE company
	   SET address_1 = in_address_1, 
		   address_2 = in_address_2, 
		   address_3 = in_address_3, 
		   address_4 = in_address_4, 
		   town = in_town, 
		   state = in_state, 
		   postcode = in_postcode, 
		   phone = in_phone, 
		   fax = in_fax, 
	 	   website = in_website
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, chain_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
END;

PROCEDURE GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_company_sid := GetCompanySid(in_company_name, in_country_code); 
END;

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	GetCompany(GetCompany(), out_cur);
END;

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF IsPurchaser(in_company_sid) THEN 
		-- default allow this to happen as this only implies read,and we
		-- don't really need a purchasers capability for anything other than this
		NULL;
	ELSE
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
		END IF;
	END IF;

	OPEN out_cur FOR
		SELECT c.*, code_label1, code_label2, code2_mandatory, code_label3, code3_mandatory	
		  FROM v$company c, product_code_type pct
		 WHERE c.company_sid = pct.company_sid(+) 
		   AND c.app_sid = pct.app_sid(+)
		   AND c.company_sid = in_company_sid
		   AND c.app_sid = security_pkg.GetApp;
END;

FUNCTION GetCompanyName (
	in_company_sid IN security_pkg.t_sid_id
) RETURN company.name%TYPE
as
	v_n	varchar2(1000);
begin
	select name
	into v_n
	from company
	where company_sid = in_company_sid
	 AND app_sid = security_pkg.GetApp;

	 return v_n;
end;

	 
PROCEDURE SearchCompanies ( 
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanies(0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, v$company_relationship cr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = cr.app_sid
		   AND c.company_sid = cr.company_sid 
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF (NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ)) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;
		
		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;
		
		RETURN;
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND ((in_only_active = chain_pkg.active AND sr.active = chain_pkg.active) OR (in_only_active = chain_pkg.inactive))
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchMyCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF chain_pkg.IsChainAdmin(SYS_CONTEXT('SECURITY', 'SID')) THEN
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
				SELECT company_sid
				  FROM v$company
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND active = chain_pkg.ACTIVE
				   AND LOWER(name) LIKE v_search
				);
	ELSE
		-- bulk collect company sid's that match our search result
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT c.company_sid
			  FROM v$company_member cm, v$company c
			 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cm.app_sid = c.app_sid
			   AND cm.company_sid = c.company_sid
			   AND cm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND LOWER(c.name) LIKE v_search
		  );
	END IF;
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE StartRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	StartRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	BEGIN
		INSERT INTO supplier_relationship
		(purchaser_company_sid, supplier_company_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
	
	UPDATE supplier_relationship
	   SET active = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	chain_link_pkg.ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
)
AS
	v_force						NUMBER(1) DEFAULT 0;
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	IF in_force THEN
		v_force := 1;
	END IF;
	
	DELETE 
	  FROM supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (   active = chain_pkg.PENDING
	   		OR v_force = 1);
END;

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = sysdate + interval '1' minute
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_company_sid;
END;

PROCEDURE DeactivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND supplier_company_sid = in_supplier_company_sid;
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	IF NOT chain_pkg.IsChainAdmin AND
	   NOT VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
	   NOT VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
)
AS
BEGIN
	IF IsMember(in_company_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;


PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;	
	IF IsSupplier(in_supplier_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	RETURN v_count > 0;
END;

-- TO DO - if this gets used a lot we might need a new COMPANYorSUPPLIERorPURCHASER type capability
-- but this is only intended to be used for a specific "GetPurchaserCompany" which is a read only "get me the company details of someone I sell to"
PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsPurchaser(in_purchaser_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsPurchaser(in_purchaser_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(in_purchaser_company_sid, in_supplier_company_sid);
END;

FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_status					supplier_relationship.active%TYPE;
BEGIN

	BEGIN
		SELECT active
		  INTO v_status
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_status := -1;
	END;
	
	RETURN v_status;
END;

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;
	
	SELECT active
	  INTO v_active
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_active = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;
	
	UPDATE company
	   SET active = chain_pkg.ACTIVE,
	       activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	chain_link_pkg.ActivateCompany(in_company_sid);
END;

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
		
	OPEN out_cur FOR
		SELECT email
		  FROM company_cc_email
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	DELETE FROM company_cc_email
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF in_emails IS NULL OR in_emails.COUNT = 0 OR in_emails(1) IS NULL THEN
		RETURN;
	END IF;

	FOR i IN in_emails.FIRST .. in_emails.LAST 
	LOOP
		BEGIN
			INSERT INTO company_cc_email
			(company_sid, lower_email, email)
			VALUES
			(in_company_sid, LOWER(TRIM(in_emails(i))), TRIM(in_emails(i)));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
END;

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- this cursor should provide two colomns, one row - columns named: email_from_name, email_from_address
	-- TODO: Actually look this up (only return a valid cursor IF the email_from_address is set)
	OPEN out_cur FOR
		SELECT support_email email_from_name, support_email email_from_address FROM customer_options WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF chain_pkg.IsChainAdmin(in_user_sid) THEN
		OPEN out_count_cur FOR
			SELECT COUNT(*) companies_count
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
		
		OPEN out_companies_cur FOR
			SELECT company_sid, name
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
	
		RETURN;
	END IF;
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) companies_count
		  FROM v$company_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	
	OPEN out_companies_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company_member cm, v$company c
		 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.app_sid = c.app_sid
		   AND cm.company_sid = c.company_sid
		   AND cm.user_sid = in_user_sid;
END;

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing stub registration data');
	END IF;
	
	UPDATE company
	   SET allow_stub_registration = in_active,
	       approve_stub_registration = in_approve
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	DELETE FROM email_stub
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF in_stubs IS NULL OR in_stubs.COUNT = 0 OR in_stubs(1) IS NULL THEN
		RETURN;
	END IF;

	
	FOR i IN in_stubs.FIRST .. in_stubs.LAST 
		LOOP
			BEGIN
				INSERT INTO email_stub
				(company_sid, lower_stub, stub)
				VALUES
				(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), LOWER(TRIM(in_stubs(i))), TRIM(in_stubs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
	END LOOP;
	
END;


PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data required for stub registration');
	END IF;
	
	UPDATE company
	   SET stub_registration_guid = user_pkg.GenerateAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND stub_registration_guid IS NULL;
	
	OPEN out_options_cur FOR
		SELECT stub_registration_guid, allow_stub_registration, approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	OPEN out_stubs_cur FOR
		SELECT stub 
		  FROM email_stub 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY lower_stub;

END;

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- no sec checks (public page)
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE -- company is active
		   AND allow_stub_registration = chain_pkg.ACTIVE -- allow stub registration
		   AND LOWER(stub_registration_guid) = LOWER(in_guid) -- match guid
		   			-- email stubs are set
		   AND company_sid IN (SELECT company_sid FROM email_stub WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));
		
		OPEN out_state_cur FOR
			SELECT chain_pkg.GUID_OK guid_state FROM DUAL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			
			RETURN;
	END;
	
	OPEN out_company_cur FOR
		SELECT company_sid, name, country_name
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid;
	
	OPEN out_stubs_cur FOR
		SELECT stub, lower_stub
		  FROM email_stub
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid
		 ORDER BY lower_stub;
END;

END company_pkg;
/

CREATE OR REPLACE PACKAGE BODY company_user_pkg
IS

/****************************************************************************************
****************************************************************************************
	SECURITY OVERRIDE FUNCTIONS
****************************************************************************************
****************************************************************************************/

PROCEDURE AddGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END; 

PROCEDURE DeleteGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 	
	DELETE
      FROM security.group_members 
     WHERE member_sid_id = in_member_sid and group_sid_id = in_group_sid;
END;

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


/* INTERNAL ONLY */
PROCEDURE UpdatePasswordResetExpirations 
AS
BEGIN
	-- don't worry about sec checks - this needs to be done anyways
	
	-- get rid of anything that's expired
	DELETE
	  FROM reset_password
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (expiration_dtm < SYSDATE OR
		   (	expiration_dtm < SYSDATE + (1/(24*12)) -- 5 minutes
			AND expiration_grace = chain_pkg.ACTIVE
		   ));
END;

FUNCTION GetPasswordResetDetails (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_user_sid 			OUT security_pkg.T_SID_ID,
	out_invitation_id 		OUT reset_password.accept_invitation_on_reset%TYPE,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_user_name				security_pkg.T_SO_NAME;
BEGIN
	UpdatePasswordResetExpirations;
	
	BEGIN	
		SELECT rp.user_sid, rp.accept_invitation_on_reset, csru.user_name
		  INTO out_user_sid, out_invitation_id, v_user_name
		  FROM reset_password rp, csr.csr_user csru
		 WHERE rp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND LOWER(rp.guid) = LOWER(in_guid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			OPEN out_state_cur FOR 
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;
	
	
	OPEN out_state_cur FOR 
		SELECT chain_pkg.GUID_OK guid_state, out_user_sid user_sid, v_user_name user_name, out_invitation_id invitation_id FROM DUAL;
		
	RETURN TRUE;
END;


-- collects a paged cursor of users based on sids passed in as a T_ORDERED_SID_TABLE
PROCEDURE CollectSearchResults (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_all_results			IN  security.T_ORDERED_SID_TABLE,
	in_show_admins			IN  BOOLEAN,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_show_admins			NUMBER(1) DEFAULT 0;
BEGIN
	IF in_show_admins THEN
		v_show_admins := 1;
	END IF;
	
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_all_results);
	
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT * FROM (
				SELECT ccu.*, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin
				  FROM v$chain_company_user ccu, TABLE(in_all_results) T, v$company_admin ca
				 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND ccu.app_sid = ca.app_sid(+)
				   AND ccu.company_sid = in_company_sid
				   AND ccu.company_sid = ca.company_sid(+)
				   AND ccu.user_sid = T.SID_ID
				   AND ccu.user_sid = ca.user_sid(+)
			 	)
		 	 ORDER BY is_admin DESC, LOWER(full_name);
	
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT * FROM (
							SELECT ccu.*, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin
							  FROM v$chain_company_user ccu, TABLE(in_all_results) T, v$company_admin ca
							 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND ccu.app_sid = ca.app_sid(+)
							   AND ccu.company_sid = in_company_sid
							   AND ccu.company_sid = ca.company_sid(+)
				   			   AND ccu.user_sid = T.SID_ID
				   			   AND ccu.user_sid = ca.user_sid(+)
							)
						 ORDER BY is_admin DESC, LOWER(full_name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

PROCEDURE InternalUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
)
AS
	v_cur_details			csr.csr_user%ROWTYPE;
BEGIN
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	
	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> security_pkg.GetAct,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_cur_details.user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> in_friendly_name,
		in_email					=> v_cur_details.email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_region_mount_point_sid	=> v_cur_details.region_mount_point_sid,
		in_active					=> NULL,
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> v_cur_details.send_alerts
	);
	
	UPDATE chain_user
	   SET visibility_id = in_visibility_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid
	   AND in_visibility_id <> -1;
END;

FUNCTION CreateUserINTERNAL (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_skip_capability_check IN  BOOLEAN
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_rsa					customer_options.default_receive_sched_alerts%TYPE;
BEGIN
	
	IF NOT in_skip_capability_check AND NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.CREATE_USER)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating users in the company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		csr.csr_user_pkg.createUser(
			in_act						=> security_pkg.GetAct, 
			in_app_sid					=> security_pkg.GetApp, 
			in_user_name				=> TRIM(in_user_name),
			in_password					=> TRIM(in_password),
			in_full_name				=> TRIM(in_full_name),
			in_friendly_name			=> TRIM(in_friendly_name),
			in_email					=> TRIM(in_email),
			in_job_title				=> null,
			in_phone_number				=> null,
			in_region_mount_point_sid	=> null,
			in_info_xml					=> null,
			in_send_alerts				=> 1,
			out_user_sid				=> v_user_sid
		);		

		csr.csr_user_pkg.DeactivateUser(security_pkg.GetAct, v_user_sid);

		-- see what the app default for receiving schedualed alerts is
		SELECT default_receive_sched_alerts
		  INTO v_rsa
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id, default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
		VALUES
		(v_user_sid, chain_pkg.NAMEJOBTITLE, chain_pkg.PENDING, in_company_sid, chain_pkg.ACTIVE, v_rsa);
		
		action_pkg.AddUserDoActions(in_company_sid, v_user_sid);
		
		-- callout to customised systems
		chain_link_pkg.AddCompanyUser (in_company_sid, v_user_sid); 
	EXCEPTION
		-- if we've got a dup object name, check to see if they're pending
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			GetUserSid(in_user_name, v_user_sid);
			-- verify that they're pending, otherwise it's a problem
			BEGIN
				SELECT user_sid
				  INTO v_user_sid
				  FROM chain_user
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND registration_status_id = chain_pkg.PENDING
				   AND user_sid = v_user_sid;
			EXCEPTION
				-- if they're not pending, rethrow the error
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'User '||in_user_name||' already exists and is not PENDING');
			END;	
	END;
	
	RETURN v_user_sid;
END;



/************************************************************
	Securable object handlers
************************************************************/


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN

	DELETE FROM event_user_status 
	 WHERE event_id IN
	(
		SELECT event_id
		  FROM event 
		 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM event_user_status 
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM event
	 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- clean up actions
	DELETE FROM action_user_status 
	 WHERE action_id IN
	(
		SELECT action_id
		  FROM action 
		 WHERE ((for_user_sid = in_sid_id) 
			OR (related_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action_user_status 	
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action 
	 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	

	-- clear invitations and reminders
	DELETE FROM invitation_reminder 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_user_sid = in_sid_id) 
			OR (to_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM invitation_qnr_type 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_user_sid = in_sid_id) 
			OR (to_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	

    DELETE FROM chain.alert_entry_named_param WHERE alert_entry_id IN (
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id 
    );
    DELETE FROM chain.alert_entry_ordered_param WHERE alert_entry_id IN (
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );
    DELETE FROM chain.alert_entry_action WHERE user_sid=in_sid_id;
    DELETE FROM chain.alert_entry_action WHERE action_id IN (
        SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
            UNION
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );
    DELETE FROM chain.alert_entry_event WHERE user_sid=in_sid_id;
    DELETE FROM chain.alert_entry_event WHERE event_id IN (
        SELECT event_id FROM chain.event WHERE for_user_sid=in_sid_id
            UNION
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );

	   
	DELETE FROM invitation
	 WHERE ((from_user_sid = in_sid_id) 
		OR (to_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_sid_id;
	  
   
	csr.csr_user_pkg.DeleteUser(security_pkg.GetAct, in_sid_id);

END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/



FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN CreateUserINTERNAL(in_company_sid, in_email, in_full_name, NULL, in_friendly_name, in_email, TRUE);
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_user_name, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(v_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(v_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	-- normal chain behaviour - email is username
	RETURN CreateUser(in_company_sid, in_email, in_full_name, in_password, in_friendly_name, in_email);
END;
	
FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN	
	RETURN CreateUserINTERNAL(in_company_sid, in_user_name, in_full_name, in_password, in_friendly_name, in_email, FALSE);
END;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec checks handled by delete user

	IF in_user_sid = in_merged_to_user_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging a user with themselves');
	ELSE
		
		IF GetRegistrationStatus(in_merged_to_user_sid) != chain_pkg.REGISTERED THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging to the user with sid '||in_merged_to_user_sid||' - they are not a registered user');
		END IF;
		
		IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging the user with sid '||in_user_sid||' - they are not pending registration');
		END IF;
	END IF;
	
	UPDATE chain_user
	   SET registration_status_id = chain_pkg.MERGED,
		   merged_to_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	DeleteUser(in_user_sid);
END;

PROCEDURE DeleteUser (
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec check handled in csr_user_pkg.DeleteUser 
	
	UPDATE chain_user
	   SET deleted = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	csr.csr_user_pkg.DeleteUser(in_act, in_user_sid);
END;

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteUser(security_pkg.GetAct, in_user_sid);
END;

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS
)
AS
	v_cur_status	chain_pkg.T_REGISTRATION_STATUS;
	v_admin_act		security_pkg.T_ACT_ID;
BEGIN
	
	IF in_status = chain_pkg.MERGED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged status must be set using SetMergedStatus');
	END IF;
	
	-- get the current status
	SELECT registration_status_id
	  INTO v_cur_status
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- if the status isn't changing, get out
	IF in_status = v_cur_status THEN
		RETURN;
	END IF;
	
	IF in_status = chain_pkg.PENDING THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot revert a user status to pending');
	END IF;
	
	IF in_status = chain_pkg.REJECTED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to rejected when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
		
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_DELETE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting the user with sid '||in_user_sid);
		END IF;

		-- login as admin user (ICK)
		v_admin_act := chain_pkg.LogonBuiltinAdmin;
		DeleteUser(v_admin_act, in_user_sid);
	END IF;
	
	IF in_status = chain_pkg.REGISTERED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to registered when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
	END IF;
	
	
	-- finally, set the new status
	UPDATE chain_user
	   SET registration_status_id = in_status
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

END;

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	AddGroupMember(in_user_sid, v_pending_sid);
	
	-- URG!!!! we'll make them full users straight away for now...
	ApproveUser(in_company_sid, in_user_sid);
	
	-- if we don't have an admin user, this user will go straight to the top
	IF v_count = 0 THEN
		MakeAdmin(in_company_sid, in_user_sid);
	END IF;
END;

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the user with sid '||in_user_sid);
	END IF;
	
	BEGIN
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id)
		VALUES
		(in_user_sid, in_visibility, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain_user
			   SET visibility_id = in_visibility
			 WHERE app_sid =  security_pkg.GetApp
			   AND user_sid = in_user_sid;
	END;		
END;

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_user_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/'||in_user_name);
	-- we're probably getting the sid to do something with them - make sure they're in chain
	chain_pkg.AddUserToChain(out_user_sid);
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanyUsers(in_company_sid, 0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_show_admins			BOOLEAN;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
			
	-- bulk collect user sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(user_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT user_sid
		  FROM v$chain_company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   	   AND company_sid = in_company_sid
	   	   AND (LOWER(full_name) LIKE v_search OR
	   	   		LOWER(job_title) LIKE v_search)
	  );
	
	v_show_admins := (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) 
				  OR (capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE));
	  
	CollectSearchResults(in_company_sid, v_results, v_show_admins, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE ApproveUser (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	v_user_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;	
	
	DeleteGroupMember(in_user_sid, v_pending_sid); 
	AddGroupMember(in_user_sid, v_user_sid); 
	chain_link_pkg.ApproveUser(in_company_sid, in_user_sid);
END;

PROCEDURE MakeAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;
	
	ApproveUser(in_company_sid, in_user_sid);
	AddGroupMember(in_user_sid, v_admin_sid); 
END;

FUNCTION RemoveAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	-- if the admin group only has one member, and we're trying to remove that member, block it - every company needs to have an admin
	IF v_count = 1 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_admin
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;
		   
		IF v_count = 1 THEN
			RETURN 0;
		END IF;
	END IF;
	
	DeleteGroupMember(in_user_sid, v_admin_sid); 
	
	RETURN 1;
END;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
)
AS
BEGIN
	security.AccountPolicyHelper_Pkg.CheckComplexity(in_email, in_password);
END;

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_cur_details			csr.csr_user%ROWTYPE;
	v_cur_rs			    chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	-- changes to email address are not permitted during registratino completion
	
	-- major sec checks handled by csr_user_pkg
	
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing the registration for the user with sid '||in_user_sid||' - they are not pending registration');
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;

	
	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> v_act_id,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_cur_details.user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> v_cur_details.friendly_name,
		in_email					=> v_cur_details.email,
		in_job_title				=> v_cur_details.job_title,
		in_phone_number				=> v_cur_details.phone_number,
		in_region_mount_point_sid	=> v_cur_details.region_mount_point_sid,
		in_active					=> 1, -- set them to active
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> v_cur_details.send_alerts
	);
	
	-- set the password
	user_pkg.ChangePasswordBySID(v_act_id, in_password, in_user_sid);
	
	-- register our user
	SetRegistrationStatus(in_user_sid, chain_pkg.REGISTERED);
END;

PROCEDURE BeginUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
)
AS
	v_visibility_id			 chain_user.visibility_id%TYPE;
	v_count					NUMBER(10);
	v_cur_details			csr.csr_user%ROWTYPE;
BEGIN
	-- meh - just clear it out to prevent dup checks
	DELETE FROM tt_user_details;
	
	-- we can update our own stuff
	IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
		
		RETURN;
	END IF;
	
	SELECT visibility_id
	  INTO v_visibility_id
	  FROM v$chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- is the user a member of our company
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND user_sid = in_user_sid;

	IF v_count > 0 THEN
		-- can we write to our own company?
		IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
		END IF;
		
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id);

		RETURN;
	END IF;
	
	IF v_visibility_id = chain_pkg.HIDDEN THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- ok, so they must be a supplier user...
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member cm, v$supplier_relationship sr
	 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sr.app_sid = cm.app_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.supplier_company_sid = cm.company_sid
	   AND cm.user_sid = in_user_sid;

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- now let's confirm that we can write to suppliers...
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- they ARE a supplier user - let's see what we can actually updated...
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	
	CASE 
	WHEN v_visibility_id = chain_pkg.JOBTITLE THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, v_cur_details.full_name, v_cur_details.friendly_name, v_cur_details.phone_number, in_job_title, v_visibility_id);
	
	WHEN v_visibility_id = chain_pkg.NAMEJOBTITLE THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name,v_cur_details.phone_number, in_job_title, v_visibility_id);
	
	WHEN v_visibility_id = chain_pkg.FULL THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id);
	
	END CASE;	
END;

PROCEDURE EndUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_details				tt_user_details%ROWTYPE;
BEGIN
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.REGISTERED THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||' - they are not registered');
	END IF;

	SELECT *
	  INTO v_details
	  FROM tt_user_details
	 WHERE user_sid = in_user_sid;
	
	InternalUpdateUser(in_user_sid, v_details.full_name, v_details.friendly_name, v_details.phone_number, v_details.job_title, v_details.visibility_id);
END;


FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS
AS
	v_rs			    	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the user with sid '||in_user_sid);
	END IF;	 
	
	BEGIN
		SELECT registration_status_id
		  INTO v_rs
		  FROM chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			chain_pkg.AddUserToChain(in_user_sid);
			
			-- try again
			SELECT registration_status_id
			  INTO v_rs
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = in_user_sid;
	END;
	   
	RETURN v_rs;
END;		
	
	
PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetUser(SYS_CONTEXT('SECURITY', 'SID'), out_cur);
END;

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM v$chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
END;
	
PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	t_users					security.T_SO_TABLE DEFAULT securableobject_pkg.GetChildrenAsTable(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users'));
	v_sid					security_pkg.T_SID_ID;
	v_guid					security_pkg.T_ACT_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	
	BEGIN
		SELECT csr_user_sid
		  INTO v_sid
		  FROM TABLE(t_users) so, csr.csr_user csru
		 WHERE csru.app_sid = v_app_sid
		   AND so.sid_id = csru.csr_user_sid
		   AND LOWER(TRIM(csru.user_name)) = LOWER(TRIM(in_param));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_sid IS NULL THEN
		-- email addresses aren't necessarily unique, so I guess we should only reset the password when they are
		BEGIN
			SELECT csr_user_sid
			  INTO v_sid
			  FROM TABLE(t_users) so, csr.csr_user csru
			 WHERE csru.app_sid = v_app_sid
			   AND so.sid_id = csru.csr_user_sid
			   AND LOWER(TRIM(csru.email)) = LOWER(TRIM(in_param));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN TOO_MANY_ROWS THEN
				NULL;
		END;	
	END IF;
	   
	IF v_sid IS NULL THEN
		RETURN;
	END IF;	
	
	-- do not send if the account is inactive
	IF user_pkg.GetAccountEnabled(v_act_id, v_sid) = 0 THEN
		RETURN;
	END IF;
	
	INSERT INTO reset_password
	(guid, user_sid, accept_invitation_on_reset)
	VALUES
	(user_pkg.GenerateACT, v_sid, invitation_pkg.GetInvitationId(in_accept_guid))
	RETURN guid INTO v_guid;
	
	-- TODO: Notify user that a password reset was requested
	-- this is a bit tricky because events are company specific, not user specific (doh!)
	
	OPEN out_cur FOR
		SELECT csru.friendly_name, csru.full_name, csru.email, rp.guid, rp.expiration_dtm, rp.user_sid
		  FROM csr.csr_user csru, reset_password rp
		 WHERE rp.app_sid = v_app_sid
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND rp.guid = v_guid;
		   
END;

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
	v_result				BOOLEAN;
BEGIN
	UPDATE reset_password
	   SET expiration_grace = 1
	 WHERE app_sid = SYS_CONTEXT('SECURTY', 'APP')
	   AND LOWER(guid) = LOWER(in_guid)
	   AND expiration_dtm > SYSDATE;
	
	-- who cares about result...
	v_result := GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_cur);
END;

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_Pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	IF (GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_state_cur)) THEN
		user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, v_user_sid);	
	END IF;
	
	-- remove all outstanding resets for this user
	DELETE FROM reset_password
	 WHERE user_sid = v_user_sid; 
END;

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
)
AS
	v_count					NUMBER(10);
BEGIN
	-- only check this if we're trying to set the password of a different user
	IF in_user_sid <> security_pkg.GetSid THEN
		
		-- capability checks should have already take place as this may be called by the UCD
		-- we'll just verify that the user is actually a company user
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'The user with sid '||in_user_sid||' is not a user of the company with sid '||in_company_sid);
		END IF;
	END IF;
	
	user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, in_user_sid);	
	
END;

PROCEDURE CheckEmailAvailability (
	in_email					IN  security_pkg.T_SO_NAME
) 
AS
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_csr_users					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users');
	v_count						NUMBER(10);
BEGIN
	-- see if there's a duplicate name, that is not the user that the invitation is originally addressed to
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain_user cu, TABLE(securableobject_pkg.GetChildrenAsTable(v_act_id, v_csr_users)) T
	 WHERE cu.app_sid = v_app_sid
	   AND cu.user_sid = T.sid_id
	   AND cu.registration_status_id <> chain_pkg.PENDING
	   AND LOWER(TRIM(T.name)) = LOWER(TRIM(in_email));
	
	-- if we've got a duplicate, let's blow up!
	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate user name found');
	END IF;

END;

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	csr.csr_user_pkg.ActivateUser(security_pkg.GetAct, in_user_sid);
	chain_link_pkg.ActivateUser(in_user_sid);
END;

END company_user_pkg;
/

CREATE OR REPLACE PACKAGE BODY component_pkg
IS

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE CreateComponentType (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_handler_class		IN  component_type.handler_class%TYPE,
	in_handler_pkg			IN  component_type.handler_pkg%TYPE,
	in_node_js_path			IN  component_type.node_js_path%TYPE,
	in_description			IN  component_type.description%TYPE
)
AS
BEGIN
	CreateComponentType(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, NULL); 
END;

PROCEDURE CreateComponentType (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_handler_class		IN  component_type.handler_class%TYPE,
	in_handler_pkg			IN  component_type.handler_pkg%TYPE,
	in_node_js_path			IN  component_type.node_js_path%TYPE,
	in_description			IN  component_type.description%TYPE,
	in_editor_card_group_id	IN  component_type.editor_card_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateComponentType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type
		(component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id)
		VALUES
		(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, in_editor_card_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE component_type
			   SET handler_class = in_handler_class,
			   	   handler_pkg = in_handler_pkg,
			   	   node_js_path = in_node_js_path,
			   	   description = in_description,
			   	   editor_card_group_id = in_editor_card_group_id
			 WHERE app_sid = security_pkg.GetApp
			   AND component_type_id = in_type_id;
	END;
		
END;

PROCEDURE ClearComponentSources
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearComponentSources can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddComponentSource (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
)
AS
BEGIN
	AddComponentSource(in_type_id, in_action, in_text, in_description, null);
END;


PROCEDURE AddComponentSource (
	in_type_id				IN  component_type.component_type_id%TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
)
AS
	v_max_pos				component_source.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddComponentSource can only be run as BuiltIn/Administrator');
	END IF;

	
	IF in_action <> LOWER(TRIM(in_action)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Actions must be formatted as trimmed and lower case');
	END IF;
	
	SELECT MAX(position)
	  INTO v_max_pos
	  FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO component_source
	(component_type_id, card_text, progression_action, description_xml, card_group_id, position)
	VALUES
	(in_type_id, in_text, in_action, in_description, in_card_group_id, NVL(v_max_pos, 0) + 1);
	
	-- I don't think there's anything wrong with adding the actions to both cards, but feel free to correct this...
	card_pkg.AddProgressionAction('Chain.Cards.ComponentSource', in_action);
	card_pkg.AddProgressionAction('Chain.Cards.ComponentBuilder.ComponentSource', in_action);
END;

PROCEDURE GetComponentSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, progression_action, card_text, description_xml
		  FROM component_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NVL(card_group_id, in_card_group_id) = in_card_group_id
		 ORDER BY position;
END;

PROCEDURE ClearComponentTypeContainment
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearComponentTypeContainment can only be run as BuiltIn/Administrator');
	END IF;

	DELETE 
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE SetComponentTypeContainment (
	in_container_component_type_id		IN component_type.component_type_id%TYPE,
	in_child_component_type_id			IN component_type.component_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetComponentTypeContainment can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type_containment
		(container_component_type_id, child_component_type_id)
		VALUES
		(in_container_component_type_id, in_child_component_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

END;

PROCEDURE GetComponentTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT UNIQUE container_component_type_id, child_component_type_id
		  FROM (
			SELECT container_component_type_id, child_component_type_id
			  FROM component_type_containment
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND child_component_type_id <> component_pkg.CMPNT_TYPE_ANY
			 UNION ALL
			SELECT ctc.container_component_type_id, ct.component_type_id child_component_type_id
			  FROM component_type_containment ctc, component_type ct
			 WHERE ctc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND ctc.app_sid = ct.app_sid
			   AND ctc.child_component_type_id = component_pkg.CMPNT_TYPE_ANY
			   AND ct.component_type_id <> component_pkg.CMPNT_TYPE_ANY
			   AND ct.component_type_id <> component_pkg.CMPNT_TYPE_NOTSURE -- don't add NOT SURE by default
			)
		ORDER BY container_component_type_id, child_component_type_id;
	
END;

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsComponentType (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE
) RETURN BOOLEAN
AS
	v_component_type_id		component.component_type_id%TYPE;
BEGIN
	BEGIN
		SELECT component_type_id
		  INTO v_component_type_id
		  FROM component
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	IF v_component_type_id = in_component_type_id THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;

FUNCTION GetComponentCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN company.company_sid%TYPE
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN
	SELECT company_sid 
	  INTO v_company_sid 
	  FROM component 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id;
		
	RETURN v_company_sid;
	
END;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetComponentTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM component_type
		 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE GetComponentType (
	in_component_type_id	IN  component_type.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM component_type
		 WHERE app_sid = security_pkg.GetApp
		   AND component_type_id = in_component_type_id;
END;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE
AS
	v_component_id			component.component_id%TYPE;
	v_company_sid 			component.company_sid%TYPE := component_pkg.GetComponentCompanySid(in_component_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||v_company_sid);
	END IF;
	
	IF NVL(in_component_id, 0) < 1 THEN

		INSERT INTO component 
		(component_id, component_type_id, description, component_code)
		VALUES 
		(component_id_seq.nextval, in_component_type_id, in_description, in_component_code) 
		RETURNING component_id INTO v_component_id;

	ELSE

		IF NOT IsComponentType(in_component_id, in_component_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot save component with id '||in_component_id||' because it is not of type '||in_component_type_id);
		END IF;
		
		v_component_id := in_component_id;
		
		UPDATE component
		   SET description = in_description, 
			   component_code = in_component_code
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	END IF;
	
	RETURN v_component_id;
END;


-- This deliberately raises an exception if the component is still linked to products
PROCEDURE DeleteComponent (
	in_component_id		   	IN component.component_id%TYPE
)
AS
	v_count					NUMBER;
	v_company_sid 			component.company_sid%TYPE := component_pkg.GetComponentCompanySid(in_component_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied on component ' || in_component_id);
	END IF;
	
	SELECT COUNT(component_id) INTO v_count 
	  FROM cmpnt_cmpnt_relationship 
	 WHERE ((component_id = in_component_id) OR (parent_component_id = in_component_id)) 
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot delete component with id ('||in_component_id||') as it is still linked to one or more products.');
	END IF;
	
	UPDATE component SET deleted = 1 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND component_id = in_component_id; 
	
	-- Clear any pending or confirmed mappings
	DELETE FROM cmpnt_prod_relationship WHERE purchaser_component_id = in_component_id AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM cmpnt_prod_rel_pending WHERE purchaser_component_id = in_component_id AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- clean up the mapping actions
	FOR r IN (
		SELECT supplier_company_sid FROM supplier_relationship WHERE purchaser_company_sid = v_company_sid AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		cmpnt_prod_relationship_pkg.SupplierSetMappingAction(v_company_sid, r.supplier_company_sid);
	END LOOP;
	
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied reading components for company with sid '||component_pkg.GetComponentCompanySid(in_component_id));
	END IF;

	OPEN out_cur FOR
		SELECT component_id, component_type_id, company_sid, created_by_sid, created_dtm, description, component_code
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
END;

PROCEDURE GetComponents (
	in_product_id			IN  product.product_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE;
BEGIN
	v_component_ids := product_pkg.GetProductComponentIds(in_product_id);
	
	OPEN out_cur FOR
		SELECT c.*
		  FROM component c, TABLE(v_component_ids) i
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = i.item
		   AND c.component_type_id = in_component_type_id
		 ORDER BY i.pos;
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	SearchComponents(in_page, in_page_size, in_search_term, NULL, out_count_cur, out_result_cur);
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_of_type				IN  component_type.component_type_id%TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- bulk collect component id's that match our search result
	SELECT security.T_ORDERED_SID_ROW(component_id, null)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT component_id
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND component_type_id = NVL(in_of_type, component_type_id)
		   AND (   LOWER(description) LIKE v_search
				OR LOWER(component_code) LIKE v_search)
	  );
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) total_count,
		   CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
		  FROM TABLE(v_results);
			
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT *
			  FROM component c, TABLE(v_results) T
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.component_id = T.SID_ID
			 ORDER BY LOWER(c.description);

	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*
						  FROM component c, TABLE(v_results) T
						 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND c.component_id = T.SID_ID
						 ORDER BY LOWER(c.description)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;





/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/


PROCEDURE ChangeNotSureComponentType (
	in_component_id			IN  component.component_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	IF NOT capability_pkg.CheckCapability(GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||GetComponentCompanySid(in_component_id));
	END IF;
	
	IF NOT IsComponentType(in_component_id, CMPNT_TYPE_NOTSURE) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot change component type of component with id '||in_component_id||' because it is not a NOT SURE component');
	END IF;
	
	UPDATE v$component
	   SET component_type_id = in_component_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	GetComponentType(in_component_type_id, out_cur); 
END;

END component_pkg;
/


CREATE OR REPLACE PACKAGE BODY dashboard_pkg
IS

PROCEDURE GetSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_total_registered_suppliers NUMBER;	
	v_suppliers_user_registered  NUMBER;
	v_outstanding_invites		 NUMBER;
	v_outstanding_questionnaires NUMBER;
	v_overdue_questionnaires	 NUMBER;
BEGIN

	-- total of YOUR suppliers 
	SELECT COUNT(*) 
	  INTO v_total_registered_suppliers
	  FROM v$supplier_relationship sr, v$company c
	 WHERE sr.app_sid = security_pkg.GetApp
	   AND sr.app_sid = c.app_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.supplier_company_sid = c.company_sid;

	-- accepted invites to distinct companies this user sent 
	-- this is not perfect as multiple people could invite the same company - and not looking at which invite they accepted - but this is probably sensible enough for summary
	SELECT COUNT(DISTINCT(i.to_company_sid)) 
	  INTO v_suppliers_user_registered
	  FROM invitation i, v$company c
	 WHERE i.app_sid = security_pkg.GetApp
	   AND i.app_sid = c.app_sid
	   AND i.invitation_status_id = chain_pkg.ACCEPTED
	   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND i.from_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND i.to_company_sid = c.company_sid;

	-- all outstanding invitations 
	SELECT COUNT(DISTINCT(i.to_company_sid)) 
	  INTO v_outstanding_invites
	  FROM invitation i, v$company c 
	 WHERE i.app_sid = security_pkg.GetApp
	   AND i.app_sid = c.app_sid
	   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND i.invitation_status_id = chain_pkg.ACTIVE
	   AND i.to_company_sid = c.company_sid;

	-- questionnaire submissions outstanding but not late 
	SELECT COUNT(*) 
	  INTO v_outstanding_questionnaires
	  FROM v$questionnaire_share
	 WHERE app_sid = security_pkg.GetApp 
	   AND share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED)
	   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND NVL(due_by_dtm, SYSDATE - 1) >= SYSDATE;

	-- questionnaire submissions outstanding AND late
	SELECT COUNT(*) 
	  INTO v_overdue_questionnaires
	  FROM v$questionnaire_share
  	 WHERE app_sid = security_pkg.GetApp 
  	   AND share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED)
  	   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND due_by_dtm < SYSDATE;

	OPEN out_cur FOR
		SELECT 
			v_total_registered_suppliers total_registered_suppliers, 
			v_suppliers_user_registered suppliers_user_registered, 
			v_outstanding_invites outstanding_invites, 
			v_outstanding_questionnaires outstanding_questionnaires, 
			v_overdue_questionnaires overdue_questionnaires
		FROM dual;

END;

END dashboard_pkg;
/

CREATE OR REPLACE PACKAGE BODY dev_pkg
IS

PROCEDURE ValidateAccess
AS
	v_sug_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.SID_ROOT, '//csr/SuperAdmins');
	v_var					NUMBER(10);
	v_deny					BOOLEAN DEFAULT NOT security_pkg.IsAdmin(security_pkg.GetAct);
BEGIN
	-- check to see if we're a super user
	IF v_deny THEN	
		SELECT COUNT(*)
		  INTO v_var
		  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetAct, v_sug_sid))
		 WHERE sid_id = security_pkg.GetSid;
		 
		v_deny := v_var = 0; 
	END IF;
	
	-- see if the application allows administators to use access development pages
	IF v_deny THEN	
		SELECT admin_has_dev_access
		  INTO v_var
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetApp;
		
		IF v_var = chain_pkg.ACTIVE AND chain_pkg.IsChainAdmin THEN
			v_deny := FALSE;
		END IF;
	END IF;
	
	-- if not, blow up!
	IF v_deny THEN
		RAISE_APPLICATION_ERROR(-20001, 'You do not have permission to call this procedure.');
	END IF;
END;

FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	WHILE LENGTH(v_cc) < 3
	LOOP
		v_cc := ' '||v_cc;
	END LOOP;
	
	
	RETURN in_company_name || ' ('||v_cc||')';
END;


-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------


PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE
)
AS
	v_cc					company.country_code%TYPE;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	SELECT MIN(country_code) -- first alphabetically
	  INTO v_cc
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(name) = LOWER(in_company_name);
	
	SetCompany(in_company_name, v_cc);
END;


PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
		
	BEGIN
		v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, chain_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			security_pkg.SetContext('CHAIN_COMPANY', NULL);
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'A company named '''||in_company_name||''' could not be found.');
	END;
	
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
END;


PROCEDURE GetOpenInvitations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR		
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	OPEN out_cur FOR
		SELECT fc.name from_company_name, fcu.full_name from_full_name, fcu.email from_email,
		  	   tc.name to_company_name, tcu.full_name to_full_name, tcu.email to_email,
		  	   i.*
		  FROM v$company fc, v$company tc, v$chain_user fcu, v$chain_user tcu, invitation i
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid
		   AND i.app_sid = tc.app_sid
		   AND i.app_sid = fcu.app_sid
		   AND i.app_sid = tcu.app_sid
		   AND i.from_company_sid = fc.company_sid
		   AND i.to_company_sid = tc.company_sid
		   AND i.from_user_sid = fcu.user_sid
		   AND i.to_user_sid = tcu.user_sid
		   AND i.invitation_status_id = chain_pkg.ACTIVE
		 ORDER BY LOWER(tc.name), LOWER(tcu.full_name);
END;

PROCEDURE GetOpenActiveActivations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;

	OPEN out_cur FOR
		SELECT cu.*, au.requested_dtm, au.guid
		  FROM csr.v$autocreate_user au, v$chain_user cu
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.app_sid = au.app_sid
		   AND cu.user_sid = au.created_user_sid
		   AND au.activated_dtm IS NULL;
END;


PROCEDURE GetCompanies (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	OPEN out_cur FOR
		SELECT c.*, NVL(ca.count, 0) ca_count, NVL(cu.count, 0) cu_count, NVL(cpu.count, 0) cpu_count
		  FROM company c, (
		  			SELECT company_sid, COUNT(*) count
		  			  FROM v$company_admin
		  			 GROUP BY company_sid
		  		) ca, (
		  			SELECT company_sid, COUNT(*) count
		  			  FROM v$company_user
		  			 GROUP BY company_sid
		  		) cu, (
		  			SELECT company_sid, COUNT(*) count
					  FROM v$company_pending_user
		  			 GROUP BY company_sid
		  		) cpu
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.deleted = 0
		   AND c.company_sid = ca.company_sid(+)
		   AND c.company_sid = cu.company_sid(+)
		   AND c.company_sid = cpu.company_sid(+)
		 ORDER BY c.name;

END;


PROCEDURE DeleteCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- check that we get dev level access
	ValidateAccess;
	
	-- ensure it's a chain company
	SELECT company_sid
	  INTO v_company_sid
	  FROM company
	 WHERE company_sid = in_company_sid;
	  
	-- trash any orphaned users	
	FOR r IN (
		-- grab all of our company users
		SELECT cm.user_sid
		  FROM v$company_member cm, chain_user cu
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.company_sid = in_company_sid
		   AND cm.user_sid = cu.user_sid
		   AND cu.tmp_is_chain_user = chain_pkg.ACTIVE
		 MINUS
		-- minus all other users
		SELECT user_sid
		  FROM v$company_member
		 WHERE company_sid <> in_company_sid	
	)
	LOOP
		company_user_pkg.DeleteUser(r.user_sid);
	END LOOP;


	company_pkg.DeleteCompany(v_company_sid);
END;

END dev_pkg;
/

CREATE OR REPLACE PACKAGE BODY event_pkg
IS

PROCEDURE AddEvent (
	in_for_company_sid					IN event.for_company_sid%TYPE,
	in_for_user_sid						IN event.for_user_sid%TYPE,
	in_related_company_sid				IN event.related_company_sid%TYPE,
	in_related_user_sid					IN event.related_user_sid%TYPE,
	in_related_questionnaire_id			IN event.related_questionnaire_id%TYPE,
	in_related_action_id				IN event.related_action_id%TYPE,
	in_event_type_id					IN event.event_type_id%TYPE,
	out_event_id						OUT event.event_id%TYPE
)
AS
	v_event_id							event.event_id%TYPE;
BEGIN

	-- this was commented out, but then again it was a write check on the company
	-- this fails because it means that a supplier can't write events to a purchaser company (doh!)
	/*
	IF NOT capability_pkg.CheckCapability(in_for_company_sid, chain_pkg.EVENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to events for company with sid '||in_for_company_sid||' as user with sid '||security_pkg.GetSid);
	END IF;
	*/
	
	INSERT INTO event (
		app_sid, 
		event_id, 
		for_company_sid, 
		for_user_sid,  
		related_company_sid, 
		related_user_sid, 
		related_questionnaire_id, 
		related_action_id, 
		created_dtm,
		event_type_id) 
	VALUES 
		(security_pkg.GetApp, 
		event_id_seq.NEXTVAL, 
		in_for_company_sid,					
		in_for_user_sid,						
		in_related_company_sid,
		in_related_user_sid,						
		in_related_questionnaire_id,	
		in_related_action_id,
		SYSDATE,														
		in_event_type_id)
	RETURNING event_id INTO v_event_id;
	
	out_event_id := v_event_id;

END;

PROCEDURE GetEvents (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetEvents(0, -1, out_cur);
END;

PROCEDURE GetEvents (
	in_start			NUMBER,
	in_page_size		NUMBER,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_company_sid		company.company_sid%TYPE := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_user_sid			chain_user.user_sid%TYPE := SYS_CONTEXT('SECURITY', 'SID');
BEGIN

	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.EVENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to events for company with sid '||v_company_sid);
	END IF;

	OPEN out_cur FOR 
		SELECT * FROM 
		(
			SELECT ROWNUM rn, E.* FROM 
			(
				SELECT 
					-- for company
					for_company_sid, for_company_name, for_company_url,
					-- for user
					for_user_sid, for_user_full_name, for_user_friendly_name, for_user_url,
					-- related company
					related_company_sid, related_company_name, related_company_url,
					-- related user
					related_user_sid, related_user_full_name, related_user_friendly_name, related_user_url,
					-- related questionnaire
					related_questionnaire_id, related_questionnaire_name, related_questionnaire_url,
					-- other data
					event_id, created_dtm, 
					other_url_1, other_url_2, other_url_3, 
					-- event type
					event_type_id, message_template, priority,
					-- who is the event for
					for_whom, is_for_user
				FROM 
					v$event E
				WHERE E.app_sid = security_pkg.GetApp
				  AND E.for_company_sid = v_company_sid
				  AND ((E.for_user_sid IS NULL) OR (E.for_user_sid = NVL(v_user_sid, -1)))
				ORDER BY E.created_dtm DESC, NVL(for_user_sid, -1), NVL2(for_user_sid, 1, 0) DESC
			) E
			WHERE ((in_page_size IS NULL) OR (ROWNUM <= in_start+in_page_size))
			ORDER BY created_dtm DESC, is_for_user DESC
		)
		WHERE rn > in_start
		ORDER BY created_dtm DESC, priority, is_for_user DESC;
		
END;

PROCEDURE GetEvents (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
BEGIN
	GetEvents(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_start, in_page_size, in_sort_by, in_sort_dir, out_cur);
END;

PROCEDURE GetEvents (
	in_company_sid		NUMBER,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS 
	v_user_sid			chain_user.user_sid%TYPE := SYS_CONTEXT('SECURITY', 'SID');
	v_SQL				VARCHAR2(2048);
BEGIN

	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction.');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('created_dtm') THEN -- add support as needed 
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction.');
	END IF;

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.EVENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to events for company with sid '||in_company_sid);
	END IF;

	v_SQL := v_SQL || 		'	SELECT * FROM ';
	v_SQL := v_SQL || 		'	( ';
	v_SQL := v_SQL ||		'		SELECT rownum rn, e.* FROM ';
	v_SQL := v_SQL ||		'		( ';
	v_SQL := v_SQL ||		'			SELECT ';
	v_SQL := v_SQL ||		'				e.*, COUNT(*) OVER () AS total_rows';
	v_SQL := v_SQL ||		'			FROM  ';
	v_SQL := v_SQL ||		'				v$event e ';
	v_SQL := v_SQL ||		'			WHERE e.app_sid = :app_sid ';
	v_SQL := v_SQL ||		'			  AND e.for_company_sid = :company_sid ';
	v_SQL := v_SQL ||		'			  AND ((e.for_user_sid IS NULL) OR (e.for_user_sid = NVL(:user_sid, -1))) ';
    v_SQL := v_SQL || 		'       	  ORDER BY ' || in_sort_by || ' ' || in_sort_dir;
	v_SQL := v_SQL ||		'		) e ';
	v_SQL := v_SQL ||		'		WHERE (rownum <= :page_end) ';
    v_SQL := v_SQL || 		'   	ORDER BY ' || in_sort_by || ' ' || in_sort_dir;
	v_SQL := v_SQL ||		'	) e ';
	v_SQL := v_SQL ||		'	WHERE rn > :page_start ';
    v_SQL := v_SQL || 		'   ORDER BY  ' || in_sort_by || ' ' || in_sort_dir;

   OPEN out_cur FOR v_SQL
		USING security_pkg.GetApp, in_company_sid, v_user_sid, in_start+in_page_size, in_start;
	
END;

FUNCTION GetEventTypeId (
	in_event_class		event_type.CLASS%TYPE
) RETURN NUMBER
AS 
	v_ret			NUMBER;
BEGIN
	SELECT event_type_id 
	  INTO v_ret
	  FROM event_type
	 WHERE CLASS = in_event_class
	   AND app_sid = security_pkg.GetApp;
	   
	RETURN v_ret;
END;

PROCEDURE CollectEventParams (
	in_event_ids			IN security.T_SID_TABLE
)
AS
BEGIN
	DELETE FROM tt_named_param;
	
	-- This is a bit dodgy. Actions and events have this concept of string replacement, but the parameters they're replacing can either contain HTML (in which case they shouldn't
	-- be escaped) or not (in which case they should be escaped). We seem to be relying on the fact that developers know which is which and whether the escaping has been done or
	-- not everywhere they're used.
	
	INSERT INTO tt_named_param
	(ID, name, VALUE)
	(	
		SELECT event_id, 'FOR_COMPANY_SID' name, TO_CHAR(FOR_COMPANY_SID) VALUE FROM v$event WHERE FOR_COMPANY_SID IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_COMPANY_NAME)) VALUE FROM v$event WHERE FOR_COMPANY_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_COMPANY_URL' name, TO_CHAR(FOR_COMPANY_URL) VALUE FROM v$event WHERE FOR_COMPANY_URL IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_USER_SID' name, TO_CHAR(FOR_USER_SID) VALUE FROM v$event WHERE FOR_USER_SID IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FULL_NAME)) VALUE FROM v$event WHERE FOR_USER_FULL_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(FOR_USER_FRIENDLY_NAME)) VALUE FROM v$event WHERE FOR_USER_FRIENDLY_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'FOR_USER_URL' name, TO_CHAR(FOR_USER_URL) VALUE FROM v$event WHERE FOR_USER_URL IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_COMPANY_SID' name, TO_CHAR(RELATED_COMPANY_SID) VALUE FROM v$event WHERE RELATED_COMPANY_SID IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_COMPANY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_COMPANY_NAME)) VALUE FROM v$event WHERE RELATED_COMPANY_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_COMPANY_URL' name, TO_CHAR(RELATED_COMPANY_URL) VALUE FROM v$event WHERE RELATED_COMPANY_URL IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_USER_SID' name, TO_CHAR(RELATED_USER_SID) VALUE FROM v$event WHERE RELATED_USER_SID IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_USER_FULL_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FULL_NAME)) VALUE FROM v$event WHERE RELATED_USER_FULL_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_USER_FRIENDLY_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_USER_FRIENDLY_NAME)) VALUE FROM v$event WHERE RELATED_USER_FRIENDLY_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_USER_URL' name, TO_CHAR(RELATED_USER_URL) VALUE FROM v$event WHERE RELATED_USER_URL IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_QUESTIONNAIRE_ID' name, TO_CHAR(RELATED_QUESTIONNAIRE_ID) VALUE FROM v$event WHERE RELATED_QUESTIONNAIRE_ID IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_QUESTIONNAIRE_NAME' name, dbms_xmlgen.convert(TO_CHAR(RELATED_QUESTIONNAIRE_NAME)) VALUE FROM v$event WHERE RELATED_QUESTIONNAIRE_NAME IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'RELATED_QUESTIONNAIRE_URL' name, TO_CHAR(RELATED_QUESTIONNAIRE_URL) VALUE FROM v$event WHERE RELATED_QUESTIONNAIRE_URL IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'OTHER_URL_1' name, TO_CHAR(OTHER_URL_1) VALUE FROM v$event WHERE OTHER_URL_1 IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'OTHER_URL_2' name, TO_CHAR(OTHER_URL_2) VALUE FROM v$event WHERE OTHER_URL_2 IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
		 UNION
		SELECT event_id, 'OTHER_URL_3' name, TO_CHAR(OTHER_URL_3) VALUE FROM v$event WHERE OTHER_URL_3 IS NOT NULL AND event_id IN (SELECT COLUMN_VALUE FROM TABLE(in_event_ids))
	);
END;

PROCEDURE GenerateAlertEntries (
	in_as_of_dtm			IN TIMESTAMP
)
AS
	v_event_ids				security.T_SID_TABLE;
BEGIN
	-- NOTE: When this method is called via the scheduler, the logged on user is
	-- the builtin administrator, therefore, the user / company sids are not set
	-- in the session
	
	SELECT event_id
	  BULK COLLECT INTO v_event_ids
	  FROM (
		-- get all events that have been created
		SELECT event_id
		  FROM v$event 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND created_dtm >= in_as_of_dtm
  			);
	
	-- collect all of the params required for the events being submitted
	CollectEventParams(v_event_ids);
	
	-- submit our events to the scheduler
	FOR r IN (
		SELECT E.*, cu.company_sid, cu.user_sid
		  FROM v$event E, v$company_user cu
		 WHERE E.app_sid = cu.app_sid
		   AND E.event_id IN (SELECT * FROM TABLE(v_event_ids))
		   AND E.for_company_sid = cu.company_sid
		   AND (E.for_user_sid IS NULL OR E.for_user_sid = cu.user_sid)
	) LOOP
		scheduled_alert_pkg.SetAlertEntry(
			chain_pkg.EVENT_ALERT,
			r.event_id,
			r.company_sid,
			r.user_sid,
			r.created_dtm,
			'DEFAULT',
			r.message_template,
			chain_pkg.NAMED_PARAMS
		);
	END LOOP;
END;

PROCEDURE AddSimpleEventType (
	in_event_type_id			IN	event_type.event_type_id%TYPE,
	in_message_template			IN	event_type.message_template%TYPE,
	in_priority					IN	event_type.priority%TYPE,
	in_class					IN	event_type.CLASS%TYPE,
	in_related_comp_url			IN	event_type.related_company_url%TYPE,
	in_related_user_url			IN	event_type.related_user_url%TYPE,
	in_related_quest_url		IN	event_type.related_questionnaire_url%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddSimpleEventType can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO event_type (
			app_sid, event_type_id, message_template,
			priority, CLASS,
			related_company_url, related_user_url, related_questionnaire_url
		) VALUES (
			security_pkg.getApp, in_event_type_id, in_message_template,
			in_priority, in_class,
			in_related_comp_url, in_related_user_url, in_related_quest_url
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE event_type 
               SET	message_template=in_message_template,
                    priority= in_priority,
                    CLASS=in_class,
                    related_company_url= in_related_comp_url,
                    related_user_url=in_related_user_url,
                    related_questionnaire_url=in_related_quest_url
             WHERE app_sid=security_pkg.getApp
               AND event_type_id=in_event_type_id;
	END;
END;

PROCEDURE CreateEventType (
	in_event_type_id				IN	event_type.event_type_id%TYPE,
	in_message_template				IN	event_type.message_template%TYPE,
	in_priority						IN	event_type.priority%TYPE,
	in_class						IN	event_type.class%TYPE,
	in_clear_urls					IN  BOOLEAN
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateEventType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO event_type 
		(app_sid, event_type_id, message_template, priority, class)
		VALUES
        (security_pkg.getApp, in_event_type_id, in_message_template, in_priority, in_class);
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE event_type
		   SET message_template = in_message_template,
			   priority = in_priority
		 WHERE app_sid = security_pkg.getApp
		   AND event_type_id = in_event_type_id;

		IF in_clear_urls THEN
			ClearEventTypeUrls(in_event_type_id);
        END IF;
	END;
END;

PROCEDURE ClearEventTypeUrls (
	in_event_type_id				IN	event_type.event_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearEventTypeUrls can only be run as BuiltIn/Administrator');
	END IF;
	
	UPDATE event_type
	   SET 	FOR_COMPANY_URL = NULL,
			FOR_USER_URL = NULL,
			RELATED_COMPANY_URL = NULL,
			RELATED_USER_URL = NULL,
			RELATED_QUESTIONNAIRE_URL = NULL,
			OTHER_URL_1 = NULL,
			OTHER_URL_2 = NULL,
			OTHER_URL_3 = NULL
	 WHERE app_sid = security_pkg.getApp
	   AND event_type_id = in_event_type_id;
END;


PROCEDURE SetEventTypeUrl (
	in_event_type_id				IN	event_type.event_type_id%TYPE,
	in_column_name					IN  user_tab_columns.COLUMN_NAME%TYPE,
	in_url							IN  VARCHAR2
)
AS
	v_column_name					user_tab_columns.COLUMN_NAME%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetEventTypeUrl can only be run as BuiltIn/Administrator');
	END IF;

	-- basic stuff to prevent obvious errors, but as we need to run this as builtin admin, I don't see this getting called maliciously.
	BEGIN
		SELECT column_name
		  INTO v_column_name
		  FROM user_tab_columns
		 WHERE table_name = 'EVENT_TYPE'
		   AND column_name = UPPER(in_column_name)
		   AND (column_name LIKE '%_URL' OR column_name LIKE 'OTHER_URL_%');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, '"'||in_column_name||'" does not appear to be a url column');
	END;
	
	EXECUTE IMMEDIATE 'UPDATE event_type SET '||v_column_name||' = :url WHERE app_sid = security_pkg.GetApp AND event_type_id = :event_type_id'
	USING in_url, in_event_type_id;
END;

END event_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.invitation_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_to_user_sid				OUT security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
BEGIN
	-- make sure that the expiration status' have been updated
	UpdateExpirations;

	BEGIN
		SELECT i.invitation_id, i.invitation_status_id, i.to_user_sid
		  INTO out_invitation_id, v_invitation_status_id, out_to_user_sid
		  FROM invitation i, v$company fc, v$company tc
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = tc.app_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.to_company_sid = tc.company_sid
		   AND LOWER(i.guid) = LOWER(in_guid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;

	IF v_invitation_status_id <> chain_pkg.ACTIVE THEN
		OPEN out_state_cur FOR
			SELECT CASE
				WHEN v_invitation_status_id = chain_pkg.EXPIRED THEN chain_pkg.GUID_EXPIRED
				ELSE chain_pkg.GUID_ALREADY_USED
				END guid_state FROM DUAL;
		RETURN FALSE;
	END IF;

	-- only include the to_user_sid if the guid is ok
	OPEN out_state_cur FOR
		SELECT chain_pkg.GUID_OK guid_state, out_to_user_sid to_user_sid FROM DUAL;

	RETURN TRUE;
END;

FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	RETURN GetInvitationStateByGuid(in_guid, out_invitation_id, v_to_user_sid, out_state_cur);
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE
AS
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
BEGIN
	BEGIN
		SELECT invitation_type_id
		  INTO v_invitation_type_id
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_invitation_type_id := chain_pkg.UNDEFINED;
	END;

	RETURN v_invitation_type_id;
END;

PROCEDURE UpdateExpirations
AS
	v_event_id		event.event_id%TYPE;
BEGIN
	-- don't worry about sec checks - this needs to be done anyways

	-- There's a very small possibility that an invitation will expire during the time from
	-- when a user first accesses the landing page, and when they actually submit the registration (or login).
	-- Instead of confusing them, let's only count it as expired if it expired more than an hour ago.
	-- We'll track this by checking if the expriation_grace flag is set.

	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_status_id = chain_pkg.ACTIVE
	       AND ((
	       		    expiration_dtm < SYSDATE
	            AND expiration_grace = chain_pkg.INACTIVE
	           ) OR (
	       	        expiration_dtm < SYSDATE - (1/24) -- one hour grace period
	       	   	AND expiration_grace = chain_pkg.ACTIVE
	       	   ))
	) LOOP
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.EXPIRED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;

		-- TODO: notify from_user_sid that the invite expired without response
		event_pkg.AddEvent(r.from_company_sid, NULL, r.to_company_sid, r.to_user_sid, NULL, NULL, event_pkg.GetEventTypeId(event_pkg.EV_INVITATION_EXPIRED), v_event_id);
		
		-- TODO: cleanup the dead objects that were associated with the invitation
	END LOOP;
END;

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_sids				security_pkg.T_SID_IDS;
	v_dummy_strings				chain_pkg.T_STRINGS;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	v_invitation_id := CreateInvitation(in_invitation_type_id, NULL, NULL, in_to_company_sid, in_to_user_sid, in_expiration_life_days, v_dummy_sids, v_dummy_strings);

	OPEN out_cur FOR
		SELECT *
		  FROM invitation
		 WHERE invitation_id = v_invitation_id;
END;

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN

	v_invitation_id := CreateInvitation(in_invitation_type_id, NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_to_company_sid), SYS_CONTEXT('SECURITY', 'SID'), in_to_company_sid, in_to_user_sid, in_expiration_life_days, in_qnr_types, in_due_dtm_strs);

	OPEN out_cur FOR
		SELECT *
		  FROM invitation
		 WHERE invitation_id = v_invitation_id;
END;


FUNCTION CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS
) RETURN invitation.invitation_id%TYPE
AS
	v_invitation_id				invitation.invitation_id%TYPE DEFAULT 0;
	v_created_invite			BOOLEAN DEFAULT FALSE;
	v_event_id					event.event_id%TYPE;
	v_expiration_life_days		NUMBER;
BEGIN
	IF in_expiration_life_days = 0 THEN
		SELECT invitation_expiration_days INTO v_expiration_life_days
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE
		v_expiration_life_days := in_expiration_life_days;
	END IF;
	
	UpdateExpirations;

	BEGIN
		SELECT invitation_id
		  INTO v_invitation_id
		  FROM v$active_invite
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_type_id = in_invitation_type_id
		   AND from_company_sid = in_from_company_sid
		   AND to_company_sid = in_to_company_sid
		   AND to_user_sid = in_to_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- if the invitation doesn't exist, create a new one
	IF v_invitation_id = 0 THEN
		INSERT INTO invitation
		(	invitation_id, invitation_type_id, guid,
			from_company_sid, from_user_sid,
			to_company_sid, to_user_sid,
			expiration_dtm
		)
		VALUES
		(
			invitation_id_seq.NEXTVAL, in_invitation_type_id, user_pkg.GenerateACT,
			in_from_company_sid, in_from_user_sid,
			in_to_company_sid, in_to_user_sid,
			SYSDATE + v_expiration_life_days
		)
		RETURNING invitation_id INTO v_invitation_id;

		v_created_invite := TRUE;
	ELSE
		-- if it does exist, reset the expiration dtm
		UPDATE invitation
		   SET expiration_dtm = GREATEST(expiration_dtm, SYSDATE + v_expiration_life_days)
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = v_invitation_id;
	END IF;


	IF in_qnr_types.COUNT <> 0 AND NOT (in_qnr_types.COUNT = 1 AND in_qnr_types(in_qnr_types.FIRST) IS NULL) THEN

		IF NOT capability_pkg.CheckCapability(in_from_company_sid, chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitations');
		END IF;



		IF in_qnr_types.COUNT <> in_due_dtm_strs.COUNT THEN
			RAISE_APPLICATION_ERROR(-20001, 'Questionnaire Type Id array has a different number of elements than the Due Date Array');
		END IF;

		FOR i IN in_qnr_types.FIRST .. in_qnr_types.LAST
		LOOP
			BEGIN
				INSERT INTO invitation_qnr_type
				(invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
				VALUES
				(v_invitation_id, in_qnr_types(i), in_from_user_sid, chain_pkg.StringToDate(in_due_dtm_strs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- TODO: Notify in_from_user_sid that added_by_user_sid had
					-- already sent the invite, otherwise, just ignore it
					-- (in normal circumstances we should be checking if this exists already,
					-- so let's just assume that it's been a race overlap)
					NULL;
			END;
		END LOOP;
	END IF;

	IF v_created_invite THEN
		CASE
			WHEN in_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
				-- start the company relationship (it will be inactive if not already present, but in there)
				company_pkg.StartRelationship(in_from_company_sid, in_to_company_sid);

				-- Notify in_from_user_sid that the invite has been created
				-- at this point add an action to the company as a whole
				event_pkg.AddEvent(in_from_company_sid, NULL, in_to_company_sid, in_to_user_sid, NULL, NULL, event_pkg.GetEventTypeId(event_pkg.EV_INVITATION_SENT), v_event_id);
				-- hook to customised system	
				chain_link_pkg.InviteCreated(v_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid);
			WHEN in_invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- TODO: Do we need to let anyone know that anything has happened?
				NULL;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||in_invitation_type_id||') event notification not handled');
		END CASE;
	END IF;

	RETURN v_invitation_id;
END;


PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	-- no sec checks - if they know the guid, they've got permission

	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, out_state_cur) THEN
		RETURN;
	END IF;

	-- set the grace period allowance
	UPDATE invitation
	   SET expiration_grace = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = v_invitation_id;

	OPEN out_invitation_cur FOR
		SELECT opt.site_name, tc.company_sid to_company_sid, tc.name to_company_name, tu.full_name to_user_name, fc.name from_company_name, fu.full_name from_user_name,
				tu.registration_status_id, i.guid, tu.email to_user_email
		  FROM invitation i, company tc, v$chain_user tu, company fc, v$chain_user fu, customer_options opt
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = tc.app_sid
		   AND i.app_sid = tu.app_sid
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = fu.app_sid(+)
		   AND i.app_sid = opt.app_sid
		   AND i.to_company_sid = tc.company_sid
		   AND i.to_user_sid = tu.user_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.from_user_sid = fu.user_sid(+)
		   AND i.invitation_id = v_invitation_id;

	OPEN out_invitation_qt_cur FOR
		SELECT qt.name
		  FROM invitation_qnr_type iqt, questionnaire_type qt
		 WHERE iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND iqt.app_sid = qt.app_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id
		   AND iqt.invitation_id = v_invitation_id;
END;

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- this is just a dummy check - it will get properly filled in later
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;

	AcceptInvitation(v_invitation_id, in_as_user_sid);
END;


PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- no sec checks - if they know the guid, they've got permission
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;

	AcceptInvitation(v_invitation_id, v_to_user_sid);
END;

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_to_company_sid			security_pkg.T_SID_ID;
	v_from_company_sid			security_pkg.T_SID_ID;
	v_is_pending_company_user	NUMBER(1);
	v_is_company_user			NUMBER(1);
	v_is_company_admin			NUMBER(1);
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
	v_approve_stub_registration	company.approve_stub_registration%TYPE;
	v_allow_stub_registration 	company.allow_stub_registration%TYPE;
	v_share_started				BOOLEAN;
BEGIN

	-- get the details
	SELECT invitation_status_id, to_user_sid, to_company_sid, from_company_sid, invitation_type_id
	  INTO v_invitation_status_id, v_to_user_sid, v_to_company_sid, v_from_company_sid, v_invitation_type_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;

	IF v_invitation_type_id = chain_pkg.STUB_INVITATION THEN
		SELECT allow_stub_registration, approve_stub_registration
		  INTO v_allow_stub_registration, v_approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_to_company_sid;

		IF v_allow_stub_registration = chain_pkg.INACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing stub registration for invitation id '||in_invitation_id);
		END IF;
	END IF;


	IF in_as_user_sid != v_to_user_sid THEN
		company_user_pkg.SetMergedStatus(v_to_user_sid, in_as_user_sid);
	END IF;

	-- activate the company
	company_pkg.ActivateCompany(v_to_company_sid);
	-- add the user to the company
	company_user_pkg.AddUserToCompany(v_to_company_sid, in_as_user_sid);

	IF v_invitation_type_id = chain_pkg.STUB_INVITATION AND v_approve_stub_registration = chain_pkg.INACTIVE THEN
		company_user_pkg.ApproveUser(v_to_company_sid, in_as_user_sid);
	END IF;

	-- see if the accepting user is an admin user
	SELECT COUNT(*)
	  INTO v_is_company_admin
	  FROM TABLE(group_pkg.GetMembersAsTable(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_to_company_sid, chain_pkg.ADMIN_GROUP)))
	 WHERE sid_id = in_as_user_sid;

	IF v_invitation_status_id <> chain_pkg.ACTIVE AND v_invitation_status_id <> chain_pkg.PROVISIONALLY_ACCEPTED THEN
		-- TODO: decide if we want an exception here or not...
		RETURN;
	END IF;

	-- may end up doing a double update on the status, but that's by design
	IF v_invitation_status_id = chain_pkg.ACTIVE THEN

		UPDATE invitation
		   SET invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   	   AND invitation_id = in_invitation_id;

		IF v_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
			-- we can activate the relationship now
			company_pkg.ActivateRelationship(v_from_company_sid, v_to_company_sid);
		END IF;
		
		/*
		-- loop round all questionnaire types for this invite and add them to this company
		-- where an open questionnaire of this type doesn't exist already
		FOR i IN (
			SELECT i.to_company_sid, i.to_user_sid, iqt.questionnaire_type_id, iqt.requested_due_dtm, i.from_company_sid
			  FROM invitation i, invitation_qnr_type iqt
			 WHERE i.invitation_id = iqt.invitation_id
			   AND i.app_sid = iqt.app_sid
			   AND i.invitation_id = in_invitation_id
			   AND questionnaire_type_id NOT IN (
					SELECT questionnaire_type_id 
					  FROM questionnaire
					 WHERE company_sid = v_to_company_sid 
					   AND app_sid = security_pkg.GetApp
					   AND questionnaire_status_id IN (questionnaire_pkg.Q_STATUS_ASSIGNED, questionnaire_pkg.Q_STATUS_PENDING)
			   )
		)
		LOOP
			INSERT INTO questionnaire (app_sid, questionnaire_id, company_sid, questionnaire_type_id, created_dtm, due_by_dtm, questionnaire_status_id, status_update_dtm)
				VALUES (security_pkg.GetApp, questionnaire_id_seq.NEXTVAL, v_to_company_sid, i.questionnaire_type_id, SYSDATE, i.requested_due_dtm, questionnaire_pkg.Q_STATUS_ASSIGNED, SYSDATE)
				RETURNING questionnaire_id INTO v_questionnaire_id;
			
			-- at this point add an action to the company as a whole
			action_pkg.InviteQuestionnaireDoActions(i.to_company_sid, v_questionnaire_id, v_action_id);

			event_pkg.AddEvent(i.from_company_sid, NULL, i.to_company_sid, i.to_user_sid, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_INVITATION_ACCEPTED), v_event_id);

			-- fire external event
			chain_link_pkg.QuestionnaireAdded(i.from_company_sid, i.to_company_sid, i.to_user_sid, v_questionnaire_id);
		END LOOP;
		*/
		
		-- loop round all questionnaire types for this invite 
		FOR i IN (
			SELECT i.to_company_sid, i.to_user_sid, iqt.questionnaire_type_id, iqt.requested_due_dtm, i.from_company_sid, qt.class questionnaire_type_class
			  FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND i.app_sid = iqt.app_sid
			   AND i.app_sid = qt.app_sid
			   AND i.invitation_id = in_invitation_id
			   AND i.invitation_id = iqt.invitation_id
			   AND iqt.questionnaire_type_id = qt.questionnaire_type_id
			   
		) LOOP
			BEGIN
				v_questionnaire_id := questionnaire_pkg.InitializeQuestionnaire(i.to_company_sid, i.questionnaire_type_class);
			EXCEPTION
				WHEN chain_pkg.QNR_ALREADY_EXISTS THEN
					v_questionnaire_id := questionnaire_pkg.GetQuestionnaireId(i.to_company_sid, i.questionnaire_type_class);
			END;
			
			BEGIN
				questionnaire_pkg.StartShareQuestionnaire(i.to_company_sid, v_questionnaire_id, i.from_company_sid, i.requested_due_dtm);	
				v_share_started := TRUE;
			EXCEPTION
				WHEN chain_pkg.QNR_ALREADY_SHARED THEN
					v_share_started := FALSE;
			END;

			IF v_share_started THEN
				action_pkg.InviteQuestionnaireDoActions(i.to_company_sid, v_questionnaire_id, i.from_company_sid, v_action_id);
				event_pkg.AddEvent(i.from_company_sid, NULL, i.to_company_sid, i.to_user_sid, v_questionnaire_id, v_action_id, event_pkg.GetEventTypeId(event_pkg.EV_INVITATION_ACCEPTED), v_event_id);					
				chain_link_pkg.QuestionnaireAdded(i.from_company_sid, i.to_company_sid, i.to_user_sid, v_questionnaire_id);
			END IF;	
		END LOOP;
		

		-- if the accepting user is not an admin, we'll need to set an admin message that the invite requires admin approval
		IF v_is_company_admin = 0 THEN
			-- TODO: Set the message (as commented above)
			NULL;
		END IF;
	END IF;

	-- TODO: Re-instate this if check!!!!!!!!!!!!!!
	--IF v_is_company_admin = 1 THEN
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.ACCEPTED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   	   AND invitation_id = in_invitation_id;

		-- TODO: Send a message to the supplier company that the invitation was accepted
		-- TODO: Send a message to the purchaser company that the invitation was accepted
	--END IF;


END;


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
)
AS
	v_sid						security_pkg.T_SID_ID;
	v_event_id					event.event_id%TYPE;
	v_admin_act					security_pkg.T_ACT_ID;
BEGIN


	IF in_reason <> chain_pkg.REJECTED_NOT_EMPLOYEE AND in_reason <> chain_pkg.REJECTED_NOT_SUPPLIER THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid invitation rejection reason - '||in_reason);
	END IF;

	-- there's only gonna be one, but this is faster than storing the row and
	-- doing no_data_found checking (and we don't care if nothing's found)
	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)
	) LOOP

		-- terminate the relationship if it is still PENDING
		company_pkg.TerminateRelationship(r.from_company_sid, r.to_company_sid, FALSE);

		-- delete the company if it's inactive
		BEGIN
			SELECT company_sid
			  INTO v_sid
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = r.to_company_sid
			   AND active = chain_pkg.INACTIVE;
			-- login as admin user (ICK)
			v_admin_act := chain_pkg.LogonBuiltinAdmin;
			company_pkg.DeleteCompany(v_admin_act, v_sid);
			

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- who cares
				NULL;
		END;

		-- delete the user if they've not registered
		BEGIN
			SELECT user_sid
			  INTO v_sid
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = r.to_user_sid
			   AND registration_status_id = chain_pkg.PENDING;

			company_user_pkg.SetRegistrationStatus(v_sid, chain_pkg.REJECTED);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- who cares
				NULL;
		END;

		UPDATE invitation
		   SET invitation_status_id = in_reason
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;


		CASE
			WHEN r.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
				-- add an event for the inviting company
				event_pkg.AddEvent(r.from_company_sid, NULL, r.to_company_sid, r.to_user_sid, NULL, NULL, event_pkg.GetEventTypeId(event_pkg.EV_INVITATION_REJECTED), v_event_id);

			WHEN r.invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- do nothing I guess....
				NULL;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||r.invitation_type_id||') event notification not handled');
		END CASE;

	END LOOP;
END;

FUNCTION CanAcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	-- hmmm - this is a bit strange, but we may want to allow this to succeed if there's a problem with the guid
	-- so that we can handle the errors appropriately
	in_guid_error_val			IN  NUMBER
) RETURN NUMBER
AS
	v_dummy						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_as_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_dummy) THEN
		RETURN in_guid_error_val;
	END IF;

	RETURN CanAcceptInvitation(v_invitation_id, in_as_user_sid);
END;

/*** not to be called unless external validity checks have been done ***/
FUNCTION CanAcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT to_user_sid
	  INTO v_to_user_sid
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;


	IF v_to_user_sid = in_as_user_sid OR company_user_pkg.GetRegistrationStatus(v_to_user_sid) = chain_pkg.PENDING THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;


FUNCTION GetInvitationId (
	in_guid						IN  invitation.guid%TYPE
) RETURN invitation.invitation_id%TYPE
AS
	v_cur						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_cur) THEN
		RETURN v_invitation_id;
	END IF;

	RETURN NULL;
END;

PROCEDURE GetSupplierInvitationSummary (
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_invite_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_questionnaire_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading suppliers');
	END IF;
	
	UpdateExpirations;
	
	OPEN out_invite_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, c.*
		  FROM invitation i, csr.csr_user csru, company c
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = c.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.to_company_sid = c.company_sid
		   AND i.to_user_sid = csru.csr_user_sid;
	
	OPEN out_questionnaire_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, iqt.*, qt.*
		  FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt, csr.csr_user csru
	     WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = iqt.app_sid
		   AND i.app_sid = qt.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.invitation_id = iqt.invitation_id
		   AND iqt.added_by_user_sid = csru.csr_user_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id;
END;

PROCEDURE GetToCompanySidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT to_company_sid
	  INTO out_company_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = GetInvitationId(in_guid);	  
END;

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
)
AS
BEGIN
	-- Temporary SP for Maersk to extend their own invitations because I'm fed up with having to do it for them.

	-- Security is enforced on the /maersk/site/temp/extendinvitations.acds URL via secmgr3.

	UPDATE chain.invitation SET invitation_status_id = 1, expiration_dtm = in_expiration_dtm
         WHERE invitation_status_id = 2 AND expiration_dtm < sysdate AND app_sid = security_pkg.GetApp;
END;

END invitation_pkg;
/

CREATE OR REPLACE PACKAGE BODY logical_component_pkg
IS
/*
PROCEDURE AddComponent ( 
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	component_pkg.AddComponent(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_description, in_component_code, component_pkg.CMPNT_TYPE_LOGICAL, v_component_id);	

	GetComponent(v_component_id, out_cur);
END;

PROCEDURE UpdateComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||component_pkg.GetComponentCompanySid(in_component_id));
	END IF;

	component_pkg.UpdateComponent(in_component_id, in_description, in_component_code);
	GetComponent(in_component_id, out_cur);

END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||component_pkg.GetComponentCompanySid(in_component_id));
	END IF;

	OPEN out_cur FOR
		SELECT component_id, company_sid, created_by_sid, created_dtm, description, component_type_id, component_code
		  FROM component
		 WHERE component_id = in_component_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;
*/
END logical_component_pkg;
/

CREATE OR REPLACE PACKAGE BODY metric_pkg
IS

PROCEDURE GetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to metrics for company with sid '||in_company_sid);
	END IF;

	
	OPEN out_cur FOR
		SELECT metric_value, max_value, normalised_value
		  FROM company_metric cm, company_metric_type cmt
		 WHERE cm.app_sid = cmt.app_sid
		   AND cm.company_metric_type_id = cmt.company_metric_type_id
		   AND cm.app_sid = security_pkg.GetApp
		   AND cm.company_sid = in_company_sid
		   AND cmt.class = in_class;
	
END;


FUNCTION SetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	in_value				IN company_metric.metric_value%TYPE
) RETURN company_metric.normalised_value%TYPE
AS
	v_normalised_value 		   company_metric.normalised_value%TYPE;
	v_company_metric_type_id   company_metric.company_metric_type_id%TYPE;
	v_max_value				   company_metric_type.max_value%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to metrics for company with sid '||in_company_sid);
	END IF;
	
	SELECT company_metric_type_id, max_value 
	  INTO v_company_metric_type_id, v_max_value
	  FROM company_metric_type
	 WHERE app_sid = security_pkg.GetApp
	   AND class = in_class;
	
	BEGIN
	   INSERT INTO company_metric (app_sid, company_metric_type_id, company_sid, metric_value, normalised_value) 
			VALUES (security_pkg.GetApp, v_company_metric_type_id, in_company_sid, in_value, 100*(in_value/v_max_value)); -- normalize to 100
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
	  
	  UPDATE company_metric 
	     SET metric_value = in_value, 
		     normalised_value = 100*(in_value/v_max_value) -- normalize to 100
	   WHERE app_sid = security_pkg.GetApp
	     AND company_metric_type_id = v_company_metric_type_id
		 AND company_sid = in_company_sid;
		 
	END;
	
	RETURN 100*(in_value/v_max_value);
	
END;

PROCEDURE DeleteCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE
) 
AS
	v_company_metric_type_id   company_metric.company_metric_type_id%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to metrics for company with sid '||in_company_sid);
	END IF;
	
	SELECT company_metric_type_id 
	  INTO v_company_metric_type_id
	  FROM company_metric_type
	 WHERE app_sid = security_pkg.GetApp
	   AND class = in_class;
	
	DELETE FROM company_metric 
     WHERE app_sid = security_pkg.GetApp
       AND company_metric_type_id = v_company_metric_type_id
       AND company_sid = in_company_sid;
END;

END metric_pkg;
/

CREATE OR REPLACE PACKAGE BODY newsflash_pkg
IS

FUNCTION HasCapability
(
	in_capability chain_pkg.T_CAPABILITY
)
RETURN BOOLEAN AS
BEGIN
	RETURN capability_pkg.CheckCapability(company_pkg.GetCompany, in_capability);
END;

PROCEDURE EnsureCapability
(
	in_capability chain_pkg.T_CAPABILITY
)
AS
BEGIN
	IF NOT HasCapability(in_capability) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Capability ''' || in_capability || ''' has not been granted to user ' || security_pkg.GetSID());
	END IF;
END;

PROCEDURE GetNewsflashSummarySP
(
	out_sp OUT customer_options.newsflash_summary_sp%TYPE
)
AS
BEGIN
	SELECT newsflash_summary_sp INTO out_sp
	  FROM customer_options
	 WHERE app_sid = security_pkg.GetApp();
	 
	 IF out_sp IS NULL THEN
		out_sp := 'chain.newsflash_pkg.GetNewsSummary';
	 END IF;
END;

PROCEDURE AddNewsflash
(
	in_content newsflash.content%TYPE,
	out_newsflash_id OUT newsflash.newsflash_id%TYPE
)
AS
BEGIN
	EnsureCapability(chain_pkg.SEND_NEWSFLASH);

	-- Not released automatically. Use RestrictNewsflash(), ExpireNewsflash() and then ReleaseNewsflash().

	INSERT INTO newsflash (content, released_dtm) VALUES (in_content, NULL) RETURNING newsflash_id INTO out_newsflash_id;
END;

PROCEDURE RestrictNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_for_suppliers NUMBER DEFAULT 0, -- For companies that are a (direct) supplier of the company that sent the message.
	in_for_users NUMBER DEFAULT 0 -- For users that have the chain_pkg.RECEIVE_USER_TARGETED_NEWS capability.
)
AS
BEGIN
	INSERT INTO newsflash_company (newsflash_id, for_suppliers, for_users) VALUES (in_newsflash_id, in_for_suppliers, in_for_users);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE newsflash_company SET for_suppliers = in_for_suppliers, for_users = in_for_users
		 WHERE newsflash_id = in_newsflash_id;
END;

PROCEDURE ExpireNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_expiry_dtm DATE DEFAULT SYSDATE
)
AS
BEGIN
	UPDATE newsflash SET expired_dtm = in_expiry_dtm WHERE newsflash_id = in_newsflash_id;
END;

PROCEDURE ReleaseNewsflash
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_release_dtm DATE DEFAULT SYSDATE
)
AS
BEGIN
	UPDATE newsflash SET released_dtm = CASE WHEN in_release_dtm < created_dtm THEN created_dtm ELSE in_release_dtm END WHERE newsflash_id = in_newsflash_id;
	-- If the newsflash is re-released, then ensure it is shown even if the old version has been hidden from specific users.
	UPDATE newsflash_user_settings SET hidden = 0 WHERE newsflash_id = in_newsflash_id;
END;

FUNCTION ChainNewsSummary RETURN T_NEWSFLASH_TABLE PIPELINED
AS
	v_cur SYS_REFCURSOR;
	v_record T_NEWSFLASH_ROW;
BEGIN
	GetNewsSummary(v_cur);
	
	LOOP
		FETCH v_cur INTO v_record;
		EXIT WHEN v_cur%NOTFOUND;
		PIPE ROW(v_record);
	END LOOP;
	CLOSE v_cur;
END;

PROCEDURE GetNewsSummary
(
	out_news_summary_cur OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_newsflash NUMBER;
BEGIN
	IF HasCapability(chain_pkg.RECEIVE_USER_TARGETED_NEWS) THEN
		v_user_newsflash := 1;
	ELSE
		v_user_newsflash := 0;
	END IF;
	
	OPEN out_news_summary_cur FOR
		SELECT n.newsflash_id, n.released_dtm, n.content, nc.for_users, nc.for_suppliers
		  FROM newsflash n
		  LEFT OUTER JOIN newsflash_company nc ON nc.app_sid = n.app_sid AND nc.newsflash_id = n.newsflash_id
		  LEFT OUTER JOIN newsflash_user_settings nus ON nus.app_sid = n.app_sid AND nus.newsflash_id = n.newsflash_id AND nus.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		 WHERE n.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND n.content IS NOT NULL
		   AND NVL(nus.hidden, 0) = 0
		   AND n.released_dtm <= SYSDATE
		   AND NVL(n.expired_dtm, SYSDATE + 1) > SYSDATE
		   AND (nc.newsflash_id IS NULL -- Messages for all companies.
				OR ( -- For this company.
					nc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				AND nc.for_users = 1
				AND v_user_newsflash = 1
				)
			    OR ( -- For companies that are a supplier of the company that sent the message.
					nc.for_suppliers = 1
				AND EXISTS (SELECT * FROM v$supplier_relationship WHERE purchaser_company_sid = nc.company_sid AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
				)
			   )
		 ORDER BY n.released_dtm DESC;
END;

PROCEDURE HideNewsflashFromUser
(
	in_newsflash_id newsflash.newsflash_id%TYPE,
	in_user_sid newsflash_user_settings.user_sid%TYPE DEFAULT SYS_CONTEXT('SECURITY', 'SID')
)
AS
BEGIN
	INSERT INTO newsflash_user_settings (newsflash_id, user_sid, hidden) VALUES (in_newsflash_id, in_user_sid, 1);
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE newsflash_user_settings SET hidden = 1
		 WHERE newsflash_id = in_newsflash_id
		   AND user_sid = in_user_sid;
END;

END newsflash_pkg;
/

CREATE OR REPLACE PACKAGE BODY product_pkg
IS

-- add product for logged on user company
PROCEDURE AddProduct (
    in_description         	IN  product.description%TYPE,
    in_code1              	IN  product.code1%TYPE,
    in_code2              	IN  product.code2%TYPE,
    in_code3              	IN  product.code3%TYPE, 
    in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_product_id		   	OUT product.product_id%TYPE
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(company_pkg.GetCompany, chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||company_pkg.GetCompany);
	END IF;
	
	-- ALWAYS create default component 
	v_component_id := component_pkg.SaveComponent(
		NULL,
		component_pkg.CMPNT_TYPE_DEFAULT,
		in_description,
		in_code1
	);
	
	BEGIN
	
		INSERT INTO product(
			product_id,
			company_sid,
			created_by_sid,
			created_dtm,
			description,
			code1,
			code2,
			code3, 
			root_component_id,
			product_builder_component_id
		)
		VALUES(
			product_id_seq.NEXTVAL,
			company_pkg.GetCompany,
			SYS_CONTEXT('SECURITY', 'SID'),
			SYSDATE,
			in_description,
			in_code1,
			in_code2,
			in_code3, 
			v_component_id,
			v_component_id
		)
		RETURNING product_id INTO out_product_id;
	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			IF (INSTR(UPPER(SQLERRM), '(CHAIN.PROD_CODE1_UNIQUE_IDX)')) > 0 THEN -- don't like this!
				 out_product_id := -1;
			ELSE
				RAISE; -- reraise the current error
			END IF;
	END;
	
	IF in_supplier_sid > 0 THEN
		cmpnt_prod_relationship_pkg.SupplierSetCmpntProdPendingRel(v_component_id, in_supplier_sid);
	END IF;
	
	-- link pkg call 
	chain_link_pkg.AddProduct(out_product_id);
	
END;

FUNCTION UpdateProduct (
	in_product_id		   IN product.product_id%TYPE,
    in_description         IN product.description%TYPE,
    in_code1               IN product.code1%TYPE,
    in_code2               IN product.code2%TYPE,
    in_code3               IN product.code3%TYPE
) RETURN NUMBER
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(product_pkg.GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on product ' || in_product_id);
	END IF;

	BEGIN
	
		UPDATE product SET
			description = in_description,
			code1 = in_code1,
			code2 = in_code2,
			code3 = in_code3
		 WHERE product_id = in_product_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			IF (INSTR(UPPER(SQLERRM), '(CHAIN.PROD_CODE1_UNIQUE_IDX)')) > 0 THEN -- don't like this!
				 RETURN -1;
			ELSE
				RAISE; -- reraise the current error
			END IF;
	END;

	UPDATE component SET
		description = in_description
	 WHERE component_id = GetProductRootComponent(in_product_id)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	RETURN 1;
	   
END;


PROCEDURE SetProductActivation (
	in_product_id		   IN product.product_id%TYPE,
    in_active         	   IN product.active%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on product ' || in_product_id);
	END IF;

    UPDATE product SET
		active = in_active
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
END;

PROCEDURE SetProductReview (
	in_product_id		   IN product.product_id%TYPE,
    in_need_review    	   IN product.active%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on product ' || in_product_id);
	END IF;

    UPDATE product SET
		need_review = in_need_review
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
END;

PROCEDURE GetProduct (
	in_product_id	IN  product.product_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product with id '||in_product_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT 
			product_id,	company_sid, company_name, created_by_sid, created_by, created_dtm,	description,	
			active, code_label1, code1,	code_label2, code2, code_label3, code3,	need_review, 
			root_component_id, product_builder_component_id
		 FROM v$company_product 
	    WHERE product_id = in_product_id
	      AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
END;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
	v_product_root_component	component.component_id%TYPE;
BEGIN

	v_product_root_component := GetProductRootComponent(in_product_id);

	IF NOT capability_pkg.CheckCapability(GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on product ' || in_product_id);
	END IF;

    UPDATE product SET
		deleted = 1
	 WHERE product_id = in_product_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	   
	-- when we delete a product we may need to:
	
	-- Add back in a pending mapping where there was relationship and we have deleted the supplier product
	FOR r IN (
		SELECT purchaser_component_id, supplier_company_sid FROM cmpnt_prod_relationship WHERE supplier_product_id = in_product_id AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		cmpnt_prod_relationship_pkg.SupplierSetCmpntProdPendingRel(r.purchaser_component_id, r.supplier_company_sid);
	END LOOP;
	
	-- unlink all components 
	cmpnt_cmpnt_relationship_pkg.DetachComponent(v_product_root_component);
	
	-- now delete the root component
	component_pkg.DeleteComponent(v_product_root_component);
	
END;

/*
PROCEDURE KillProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
	v_product_root_component	component.component_id%TYPE;
	v_company_sid 				component.component_id%TYPE := ;
BEGIN

	v_product_root_component := GetProductRootComponent(in_product_id);

	IF NOT capability_pkg.CheckCapability(GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_DELETE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied on product ' || in_product_id);
	END IF;
	
	-- TO DO NOT FINISHED

	-- link pkg call first - clear any client specific stuff (e.g. questionnaire answers)
	chain_link_pkg.KillProduct(in_product_id);
	
	-- unlink all components - don't delete as may be used in other products or needed later (search)
	cmpnt_cmpnt_relationship_pkg.DetachComponent(v_product_root_component);
	
	-- now delete the root component - as this just belongs to this product we are nuking
	component_pkg.DeleteComponent(v_product_root_component);
	
END;
*/

PROCEDURE GetProductsForCompany (
	in_company_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT p.product_id, p.description product_description, p.description || ' : ' || code1 description, code_label1, code1, code_label2, code2, code_label3, code3
		  FROM v$product p
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = in_company_sid
		 ORDER BY LOWER(p.description || ' : ' || code1) ASC;
   
END;

PROCEDURE SearchProducts (
	in_search					IN VARCHAR2,
	in_purchaser_company_sid	IN security_pkg.T_SID_ID,
	in_supplier_company_sid		IN security_pkg.T_SID_ID,
	in_show_just_need_attention	IN NUMBER,
	in_show_deleted				IN NUMBER,
	in_start					IN NUMBER,
	in_page_size				IN NUMBER,
	in_sort_by					IN VARCHAR2,
	in_sort_dir					IN VARCHAR2,
	in_exporting				IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_SQL						VARCHAR2(4000);
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
BEGIN

	-- TO DO - need a security check 

	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'code1', 'code2', 'code3', 'customer', 'status', 'source') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	IF in_exporting = 1 THEN 
		-- format nicely for export
		v_SQL :=  '	SELECT product_id, company_name, created_by, created_dtm, description, DECODE(active, 1, ''Yes'', 0, ''No'') active_product, '; 
		v_SQL := v_SQL || ' code_label1 || '': '' || code1 code1, NVL2(code_label2, code_label2 || '': '' || code2, NULL) code2, NVL2(code_label3, code_label3 || '': '' || code3, NULL) code3, ';
		v_SQL := v_SQL || ' status, source, customers FROM ';
	ELSE
		-- pull it all back
		v_SQL :=  '	SELECT * FROM ';	
	END IF;
	

	v_SQL := v_SQL || 		'	( ';
	v_SQL := v_SQL ||		'		SELECT rownum rn, p.* FROM ';
	v_SQL := v_SQL ||		'		( ';
	v_SQL := v_SQL || 		'			SELECT p.*, COUNT(*) OVER () AS total_rows FROM ';
	v_SQL := v_SQL || 		'			(';
											-- this defines the data needed 
	v_SQL := v_SQL || 		'				SELECT 	product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, ';
	v_SQL := v_SQL || 		'						code_label1, code1, code_label2, code2, code_label3, code3, need_review, deleted, ';
	v_SQL := v_SQL || 		'						 supplier_count, NVL(supplier_company_sid, -1) supplier_company_sid, supplier_company_name, ';
	v_SQL := v_SQL || 		'						 purchaser_count, NVL(purchaser_company_sid, -1) purchaser_company_sid, purchaser_company_name, ''Pending'' status, ';
	v_SQL := v_SQL || 		'						 DECODE(supplier_count, 0, ''-'', 1, supplier_company_name, supplier_count)  source, ';
	v_SQL := v_SQL || 		'						 DECODE(purchaser_count, 0, ''None'', 1, purchaser_company_name, ''Multiple'')  customers ';
	v_SQL := v_SQL || 		'				FROM v$company_product_extended ';
	v_SQL := v_SQL || 		'			   WHERE app_sid = SYS_CONTEXT(''security'', ''app'') ';
	v_SQL := v_SQL || 		'			) p,  ';
	v_SQL := v_SQL || 		'			( ';
											-- this controls the search   
	v_SQL := v_SQL || 		'				SELECT DISTINCT product_id FROM';
	v_SQL := v_SQL || 		'				( ';
	v_SQL := v_SQL || 		'					SELECT product_id, company_sid, deleted, need_review, description, code1, code2, code3, MAX(p_company_sid) p_company_sid, MAX(s_company_sid) s_company_sid FROM ';
	v_SQL := v_SQL || 		'					( ';
	v_SQL := v_SQL || 		'					    SELECT p.product_id, p.company_sid, p.company_name, p.description, p.code1, p.code2, p.code3, p.deleted, pur.p_company_sid, sup.s_company_sid, need_review ';
	v_SQL := v_SQL || 		'					      FROM v$company_product p, v$product_relationship pur, v$product_relationship sup ';
	v_SQL := v_SQL || 		'					     WHERE p.app_sid = SYS_CONTEXT(''security'', ''app'') ';
	v_SQL := v_SQL || 		'					       AND p.product_id = pur.s_product_id(+) '; -- up the tree 
	v_SQL := v_SQL || 		'					       AND p.root_component_id = sup.p_component_id(+)   '; -- down the tree - artificial atm as assumes one component per prod
	v_SQL := v_SQL || 		'					    UNION  ';
	v_SQL := v_SQL || 		'					    SELECT p.product_id, p.company_sid, p.company_name, p.description, p.code1, p.code2, p.code3, p.deleted, pur.p_company_sid, sup.s_company_sid, need_review  ';
	v_SQL := v_SQL || 		'					      FROM v$company_product p, v$product_rel_pending pur, v$product_rel_pending sup ';
	v_SQL := v_SQL || 		'					     WHERE p.app_sid = SYS_CONTEXT(''security'', ''app'') ';
	v_SQL := v_SQL || 		'					       AND p.product_id = pur.s_product_id(+) '; -- up the tree 
	v_SQL := v_SQL || 		'					       AND p.root_component_id = sup.p_component_id(+)  '; -- down the tree - artificial atm as assumes one component per prod
	v_SQL := v_SQL || 		'					)    ';
	v_SQL := v_SQL || 		'				 WHERE ((:in_purchaser_company_sid IS NULL) OR (p_company_sid = :in_purchaser_company_sid)) ';    
	v_SQL := v_SQL || 		'				  AND ((:in_supplier_company_sid IS NULL) OR (s_company_sid = :in_supplier_company_sid)) ';
											-- show deleted flag 
	v_SQL := v_SQL || 		'			  	  AND deleted IN (0, :in_show_deleted) ';
	v_SQL := v_SQL || 		'				  AND company_sid = :logged_on_company_sid ';
											-- just show work to do  
	v_SQL := v_SQL || 		'				  AND (need_review IN (1, :in_show_just_need_attention) OR ';
	v_SQL := v_SQL || 		'					  ((:in_show_just_need_attention = 0) OR (s_company_sid IS NOT NULL)) OR ';
	v_SQL := v_SQL || 		'					  ((:in_show_just_need_attention = 0) OR (p_company_sid IS NOT NULL)))  '; -- is it mapped 
											-- search on all below 
	v_SQL := v_SQL || 		'	   			  AND ((:in_search IS NULL) OR ( ';
	--v_SQL := v_SQL || 		'					  (LOWER(company_name) LIKE :v_search) OR ';
	v_SQL := v_SQL || 		'					  (LOWER(description) LIKE :v_search) OR ';
	v_SQL := v_SQL || 		'					  (LOWER(code1) LIKE :v_search) OR ';
	v_SQL := v_SQL || 		'					  (LOWER(code2) LIKE :v_search) OR ';
	v_SQL := v_SQL || 		'					  (LOWER(code3) LIKE :v_search))) ';
	v_SQL := v_SQL || 		'					  GROUP BY product_id, company_sid, description, code1, code2, code3, need_review, deleted ';
	v_SQL := v_SQL || 		'				)  ';
	v_SQL := v_SQL || 		'			) srch ';
	v_SQL := v_SQL || 		'			WHERE p.product_id = srch.product_id ';
    v_SQL := v_SQL || 		'   		ORDER BY ' || in_sort_by || ' ' || in_sort_dir;	
	v_SQL := v_SQL ||		'		) p ';
	v_SQL := v_SQL ||		'		WHERE (rownum <= NVL(:page_end, rownum)) '; -- null page_end returns all from page_start
    v_SQL := v_SQL || 		'   	ORDER BY ' || in_sort_by || ' ' || in_sort_dir;
	v_SQL := v_SQL ||		'	) p ';
	v_SQL := v_SQL ||		'	WHERE rn > NVL(:page_start, 0) ';  -- null page_start returns from row 0
    v_SQL := v_SQL || 		'   ORDER BY  ' || in_sort_by || ' ' || in_sort_dir;


   OPEN out_cur FOR v_SQL
		USING 	
			in_purchaser_company_sid, 
			in_purchaser_company_sid, 
			in_supplier_company_sid, 
			in_supplier_company_sid,
			in_show_deleted, 
			SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), 
			in_show_just_need_attention, 
			in_show_just_need_attention, 
			in_show_just_need_attention,
			in_search, 
			--v_search, 
			v_search, 
			v_search, 
			v_search, 
			v_search,
			in_start+in_page_size, 
			in_start;

END;

FUNCTION GetProductCompanySid (
	in_product_id		   IN product.product_id%TYPE
) RETURN company.company_sid%TYPE
AS
	v_company_sid			company.company_sid%TYPE;
BEGIN

	SELECT company_sid INTO v_company_sid FROM product WHERE product_id =  in_product_id;
	
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on product ' || in_product_id);
	END IF;
	
	RETURN v_company_sid;
	
END;

PROCEDURE GetRecentProducts (
	out_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- TO DO - need a security check 
	
	-- return the last 3 products added by this user in the last 12hrs
	OPEN out_cur FOR
		SELECT * 
		  FROM
		(
			SELECT p.product_id, p.description, code_label1, code1, code_label2, code2, code_label3, code3
			  FROM v$product p
			 WHERE p.created_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND p.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND p.created_dtm > SYSDATE - 0.5
			   AND p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 ORDER BY p.created_dtm DESC
		)
		WHERE rownum <= 3 ;
   
END;

PROCEDURE GetCodeLabelsForCompany (
	in_company_sid	IN  company.company_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
) 
AS 
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT code_label1, code_label2, code_label3, code2_mandatory, code3_mandatory
		  FROM product_code_type
		 WHERE company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE SaveCodeLabelsForCompany (
    in_company_sid      IN	security_pkg.T_SID_ID,
	in_code_label1		IN	chain.product_code_type.code_label1%TYPE,
	in_code_label2		IN	chain.product_code_type.code_label2%TYPE,
	in_code_label3		IN	chain.product_code_type.code_label3%TYPE,
	in_code2_mandatory	IN	chain.product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory	IN	chain.product_code_type.code3_mandatory%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE product_code_type
	   SET code_label1 = TRIM(in_code_label1),
	       code_label2 = TRIM(in_code_label2),
	       code_label3 = TRIM(in_code_label3),
	       code2_mandatory = in_code2_mandatory,
	       code3_mandatory = in_code3_mandatory
	 WHERE company_sid = in_company_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetProductCodeOptions (
	in_company_sid	IN  company.company_sid%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT mapping_approval_required
		  FROM company
		 WHERE company_sid = in_company_sid;
END;

PROCEDURE UpdateProductCodeOptions (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	company.mapping_approval_required%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE company
	   SET mapping_approval_required = in_mapping_approval_required
	 WHERE company_sid = in_company_sid;

END;

PROCEDURE TurnOnProductsForCompany (
	in_company_sid	IN  company.company_sid%TYPE
)
AS 
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	-- add defaults for product codes for the new company
	INSERT INTO product_code_type (app_sid, company_sid) VALUES (SYS_CONTEXT('SECURITY', 'APP'), in_company_sid);

END;

/*
FUNCTION GetProductCompany (
	in_product_id		   IN product.product_id%TYPE
) RETURN company.company_sid%TYPE
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(product_pkg.GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on product ' || in_product_id);
	END IF;

	SELECT company_sid INTO v_company_sid FROM product WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND product_id = in_product_id;
	RETURN v_company_sid;
END;
*/

FUNCTION GetProductRootComponent (
	in_product_id		   IN product.product_id%TYPE
) RETURN component.component_id%TYPE
AS
	v_component_id 		   component.component_id%TYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(product_pkg.GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on product ' || in_product_id);
	END IF;

	SELECT root_component_id INTO v_component_id FROM product WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND product_id = in_product_id;
	RETURN v_component_id;
END;


FUNCTION GetProductComponentIds (
	in_product_id		   IN product.product_id%TYPE
) RETURN T_NUMERIC_TABLE
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
	v_root_component_id		component.component_id%TYPE DEFAULT GetProductRootComponent(in_product_id);	
BEGIN
	SELECT T_NUMERIC_ROW(component_id, rn)
	  BULK COLLECT INTO v_component_ids
	  FROM (
	  		SELECT component_id, rownum rn 
	  		  FROM (
				SELECT v_root_component_id component_id FROM DUAL
				 UNION ALL
				SELECT component_id
				  FROM (
					SELECT component_id
					  FROM cmpnt_cmpnt_relationship
					 WHERE app_sid = security_pkg.GetApp
					 START WITH parent_component_id = v_root_component_id
				   CONNECT BY NOCYCLE PRIOR component_id = parent_component_id
					 ORDER SIBLINGS BY position
					   )
			   )
		   );
	
	RETURN v_component_ids;
END;

PROCEDURE GetProductComponentIdTree (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_root_component_id		component.component_id%TYPE DEFAULT GetProductRootComponent(in_product_id);	
BEGIN
	OPEN out_cur FOR
		SELECT v_root_component_id component_id, NULL parent_component_id FROM DUAL
		 UNION ALL
		SELECT component_id, parent_component_id
		  FROM (
			SELECT component_id, parent_component_id
			  FROM cmpnt_cmpnt_relationship
			 WHERE app_sid = security_pkg.GetApp
			 START WITH parent_component_id = v_root_component_id
		   CONNECT BY NOCYCLE PRIOR component_id = parent_component_id
			 ORDER SIBLINGS BY position
			);
END;

PROCEDURE SetProductBuilderComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.product_builder_component_id%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(product_pkg.GetProductCompanySid(in_product_id), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||chain.product_pkg.GetProductCompanySid(in_product_id));
	END IF;
	
	-- TODO: this should check that the component is actually a child...
	
	UPDATE product
	   SET product_builder_component_id = in_component_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;

END product_pkg;
/

CREATE OR REPLACE PACKAGE BODY purchased_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
	v_current_supplier_company_sid security_pkg.T_SID_ID;
BEGIN
	v_component_id := component_pkg.SaveComponent(in_component_id, component_pkg.CMPNT_TYPE_PURCHASED, in_description, in_component_code);
	
	-- find the supplier - in the pending or mapped relationship table
	-- we could stick this in a separate table but don't see the point
	BEGIN
		SELECT DISTINCT supplier_company_sid -- should NEVER be mapping this component to multiple companies
		  INTO v_current_supplier_company_sid
		  FROM 
			(
				SELECT supplier_company_sid 
				  FROM cmpnt_prod_rel_pending
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND purchaser_component_id = v_component_id
				UNION
				SELECT supplier_company_sid 
				  FROM cmpnt_prod_relationship
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND purchaser_component_id = v_component_id	
			)
		 WHERE supplier_company_sid IS NOT NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_current_supplier_company_sid := 0;
	END;			
	
	-- if the supplier has changed and the sid is set then set the new pending relationship
	-- this clears / overwrites existing pending or confirmed relationships
	IF in_supplier_sid <> v_current_supplier_company_sid AND NVL(in_supplier_sid, 0) > 0 THEN
		cmpnt_prod_relationship_pkg.SupplierSetCmpntProdPendingRel(v_component_id, in_supplier_sid);
	END IF;
	
	GetComponent(v_component_id, out_cur);

END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_supplier_company_sid	company.company_sid%TYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(component_pkg.GetComponentCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||component_pkg.GetComponentCompanySid(in_component_id));
	END IF;

	-- find the supplier - in the pending or mapped relationship table
	-- we could stick this in a separate table but don't see the point
	SELECT DISTINCT supplier_company_sid -- should NEVER be mapping this component to multiple companies
	  INTO v_supplier_company_sid
	  FROM 
		(
			SELECT supplier_company_sid 
			  FROM cmpnt_prod_rel_pending
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND purchaser_component_id = in_component_id
			 UNION
			SELECT supplier_company_sid 
			  FROM cmpnt_prod_relationship
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND purchaser_component_id = in_component_id	
		)
	 WHERE supplier_company_sid IS NOT NULL;

	-- TO DO sec check
	OPEN out_cur FOR
		SELECT component_id, c.company_sid, sc.company_sid supplier_company_sid, sc.name supplier_company, created_by_sid, created_dtm, description, component_type_id, component_code
		  FROM component c, (SELECT app_sid, company_sid, name FROM company WHERE company_sid = v_supplier_company_sid AND app_sid = SYS_CONTEXT('SECURITY', 'APP')) sc -- this is a bit of a shortcut as we'll only ever have a single component row
		 WHERE c.app_sid = sc.app_sid
		   AND c.component_id = in_component_id
		   AND c.app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetComponents (
	in_product_id			IN  product.product_id%TYPE,
	in_component_type_id	IN  component.component_type_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE;
BEGIN
	v_component_ids := product_pkg.GetProductComponentIds(in_product_id);
	
	OPEN out_cur FOR
		SELECT c.*, supplier_company_sid, supplier_company
		  FROM component c, TABLE(v_component_ids) i, 
		  	(
				SELECT DISTINCT purchaser_component_id component_id, supplier_company_sid, c.name supplier_company 
				  FROM 
				(
					 SELECT app_sid, purchaser_component_id, supplier_company_sid 
					  FROM cmpnt_prod_rel_pending
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					UNION
					SELECT app_sid, purchaser_component_id, supplier_company_sid 
					  FROM cmpnt_prod_relationship
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 ) cmpnt, company c
				 WHERE cmpnt.app_sid = c.app_sid
				   AND cmpnt.supplier_company_sid = c.company_sid
			) s
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = i.item
		   AND c.component_type_id = in_component_type_id
		   AND c.component_id = s.component_id
		 ORDER BY i.pos;
END;

END purchased_component_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.questionnaire_pkg
IS

/***************************************************************************************
	PRIVATE
***************************************************************************************/
PROCEDURE AddStatusLogEntry (
	in_questionnaire_id				questionnaire.questionnaire_id%TYPE,
	in_status						chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes					qnr_status_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
BEGIN
	SELECT NVL(MAX(status_log_entry_index), 0) + 1
	  INTO v_index
	  FROM qnr_status_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = questionnaire_id;		

	INSERT INTO qnr_status_log_entry
	(questionnaire_id, status_log_entry_index, questionnaire_status_id, user_notes)
	VALUES
	(in_questionnaire_id, v_index, in_status, in_user_notes);
END;

PROCEDURE AddShareLogEntry (
	in_qnr_share_id					questionnaire_share.questionnaire_share_id%TYPE,
	in_status						chain_pkg.T_SHARE_STATUS,
	in_user_notes					qnr_share_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
BEGIN
	SELECT NVL(MAX(share_log_entry_index), 0) + 1
	  INTO v_index
	  FROM qnr_share_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_share_id = in_qnr_share_id;		
	
	INSERT INTO qnr_share_log_entry
	(questionnaire_share_id, share_log_entry_index, share_status_id, user_notes)
	VALUES
	(in_qnr_share_id, v_index, in_status, in_user_notes);
END;

/***************************************************************************************
	PUBLIC
***************************************************************************************/

-- ok
PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT questionnaire_filter_class
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetApp;
END;

-- ok
PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_group
		 WHERE app_sid = security_pkg.GetApp;
END;

-- ok
PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		 ORDER BY position;
END;

-- ok
PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND LOWER(class) = LOWER(TRIM(in_qt_class));
END;

-- ok
FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	SELECT questionnaire_type_id
	  INTO v_ret
	  FROM questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(CLASS) = LOWER(in_qt_class);

	RETURN v_ret;
END;

-- ok
FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		SELECT questionnaire_id
		  INTO v_q_id
		  FROM questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class)
		   AND company_sid = in_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_NOT_FOUND, 'No questionnaire of type '||in_qt_class||' is setup for company with sid '||in_company_sid);
	END;
	
	RETURN v_q_id;
END;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM v$questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);
END;

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	IF QuestionnaireExists(in_company_sid, in_qt_class) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_EXISTS, 'A questionnaire of class '||in_qt_class||' already exists for company with sid '||in_company_sid);
	END IF;
	
	INSERT INTO questionnaire
	(questionnaire_id, company_sid, questionnaire_type_id, created_dtm)
	VALUES
	(questionnaire_id_seq.nextval, in_company_sid, GetQuestionnaireTypeId(in_qt_class), SYSDATE)
	RETURNING questionnaire_id INTO v_q_id;
	
	AddStatusLogEntry(v_q_id, chain_pkg.ENTERING_DATA, NULL);
	
	RETURN v_q_id;	
END;

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
)
AS
	v_qnr_share_id				questionnaire_share.questionnaire_share_id%TYPE;
	v_count						NUMBER(10);
BEGIN
	
	IF NOT company_pkg.IsSupplier(in_share_with_company_sid, in_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' is not a supplier to company with sid '||in_share_with_company_sid);
	END IF;	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id
	   AND company_sid = in_company_sid;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' does not own the questionnaire with id '||in_questionnaire_id);
	END IF;	
	
	BEGIN
		INSERT INTO questionnaire_share
		(questionnaire_share_id, questionnaire_id, qnr_owner_company_sid, share_with_company_sid, due_by_dtm)
		VALUES
		(questionnaire_share_id_seq.nextval, in_questionnaire_id, in_company_sid, in_share_with_company_sid, in_due_by_dtm)
		RETURNING questionnaire_share_id INTO v_qnr_share_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_SHARED, 'The questionnaire with id '||in_questionnaire_id||' is already shared from company with sid '||in_company_sid||' to company with sid '||in_share_with_company_sid);
	END;
	
	AddShareLogEntry(v_qnr_share_id, chain_pkg.NOT_SHARED, NULL);
END;


FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
BEGIN
	BEGIN
		v_questionnaire_id := GetQuestionnaireId(in_company_sid, in_qt_class);
	EXCEPTION
		WHEN chain_pkg.QNR_NOT_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
)
AS
BEGIN
	out_exists := 0;
	
	IF QuestionnaireExists(in_company_sid, in_qt_class) THEN
		out_exists := 1;
	END IF;
END;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS
AS
	v_q_status_id				chain_pkg.T_QUESTIONNAIRE_STATUS;
BEGIN
	-- perm check done in GetQuestionnaireId
	SELECT questionnaire_status_id
	  INTO v_q_status_id
	  FROM v$questionnaire
	 WHERE app_sid = security_pkg.GetApp
	   AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);

	RETURN v_q_status_id;
END;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- perm check done in GetQuestionnaireId
	OPEN out_cur FOR
		SELECT share_with_company_sid, share_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
	       AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);
END;

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS
AS
	v_s_status_id			chain_pkg.T_SHARE_STATUS;
BEGIN
	-- perm check done in GetQuestionnaireId
	BEGIN
		SELECT share_status_id
		  INTO v_s_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class)
		   AND share_with_company_sid = in_share_with_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a questionanire share status between OWNER: '||in_qnr_owner_company_sid||' SHARE WITH:'||in_share_with_company_sid||' of CLASS:"'||in_qt_class||'"');
	END;
	
	RETURN v_s_status_id;
END;


PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
	v_current_status			chain_pkg.T_QUESTIONNAIRE_STATUS DEFAULT GetQuestionnaireStatus(in_company_sid, in_qt_class);
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
BEGIN
	-- validate the incoming state
	IF in_q_status_id NOT IN (
		chain_pkg.ENTERING_DATA, 
		chain_pkg.REVIEWING_DATA, 
		chain_pkg.READY_TO_SHARE
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire state "'||in_q_status_id||'"');
	END IF;
	
	-- we're not changing status - get out
	IF v_current_status = in_q_status_id THEN
		RETURN;
	END IF;
	
	CASE
	WHEN v_current_status = chain_pkg.ENTERING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.REVIEWING_DATA THEN
			-- I suppose anyone can make this status change
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			-- force the call to reviewing data for logging purposes
			SetQuestionnaireStatus(in_company_sid, in_qt_class, chain_pkg.REVIEWING_DATA, 'Automatic progression');
			v_current_status := chain_pkg.REVIEWING_DATA;
		END CASE;
	
	WHEN v_current_status = chain_pkg.REVIEWING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.ENTERING_DATA THEN
			-- it's going back down, that's fine
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for company with sid '||in_company_sid);
			END IF;
		END CASE;
	
	WHEN v_current_status = chain_pkg.READY_TO_SHARE THEN
		SELECT owner_can_review
		  INTO v_owner_can_review
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
		
		-- we're trying to downgrade the status, so let's see if the owner can review
		IF v_owner_can_review = chain_pkg.INACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied re-editting questionnaire for company with sid '||in_company_sid);
		END IF;
	END CASE;
	
	AddStatusLogEntry(GetQuestionnaireId(in_company_sid, in_qt_class), in_q_status_id, in_user_notes);
END;

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
	v_qnr_share_id 				questionnaire_share.questionnaire_share_id%TYPE;
	v_isowner					BOOLEAN DEFAULT in_qnr_owner_company_sid = company_pkg.GetCompany;
	v_isPurchaser				BOOLEAN DEFAULT company_pkg.IsPurchaser(company_pkg.GetCompany, in_qnr_owner_company_sid);
	v_count						NUMBER(10);
	v_current_status			chain_pkg.T_SHARE_STATUS DEFAULT GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class);
BEGIN
	IF NOT v_isowner AND NOT v_isPurchaser THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a questionnaire where you are neither the owner or a Purchaser');
	END IF;
	
	-- validate the incoming state
	IF in_q_share_id NOT IN (
		chain_pkg.NOT_SHARED, 
		chain_pkg.SHARING_DATA, 
		chain_pkg.SHARED_DATA_RETURNED,
		chain_pkg.SHARED_DATA_ACCEPTED,
		chain_pkg.SHARED_DATA_REJECTED
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire share state "'||in_q_share_id||'"');
	END IF;

	-- nothing's changed - get out
	IF v_current_status = in_q_share_id THEN
		RETURN;
	END IF;
	
	-- we can only set certain states depending on who we are
	-- if we are the owner, we can only modify the questionnaire share from a not shared or sharing data retured state
	IF v_isowner AND v_current_status NOT IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of your questionnaire when it is not in the NOT SHARED or SHARED DATA RETURNED states');
	-- if we are the Purchaser, we can only modify from the other states.
	ELSIF v_isPurchaser AND v_current_status NOT IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a supplier''s questionnaire when it is not in the SHARING DATA or ACCEPTED or REJECTED states');
	END IF;	
		
	CASE 
	
	-- if the current status is not shared or shared data retured, we can only go to a sharing data state
	WHEN v_current_status IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED) THEN
		CASE
		WHEN in_q_share_id = chain_pkg.SHARING_DATA THEN
			IF NOT capability_pkg.CheckCapability(chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for your company ('||in_qnr_owner_company_sid||')');
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denided progressing questionnaires from NOT SHARED or SHARED DATA RETURNED to any state other than SHARING DATA');
		END CASE;
	-- if the current status is in any other sharing state, we can move to returned, accepted or rejected states
	WHEN v_current_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN
		CASE
		WHEN in_q_share_id IN (
			chain_pkg.SHARING_DATA, 
			chain_pkg.SHARED_DATA_RETURNED, 
			chain_pkg.SHARED_DATA_ACCEPTED, 
			chain_pkg.SHARED_DATA_REJECTED
		) THEN
			IF NOT capability_pkg.CheckCapability(chain_pkg.APPROVE_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied approving questionnaires for your suppliers');
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denided progressing questionnaires from SHARING_DATA, SHARED_DATA_ACCEPTED or SHARED_DATA_REJECTED to states other than SHARING_DATA, SHARED_DATA_RETURNED, SHARED_DATA_ACCEPTED or SHARED_DATA_REJECTED');
		END CASE;
		
	END CASE;

	-- if we get here, we're good to go!
	SELECT questionnaire_share_id
	  INTO v_qnr_share_id
	  FROM questionnaire_share
	 WHERE app_sid = security_pkg.GetApp
	   AND qnr_owner_company_sid = in_qnr_owner_company_sid
	   AND share_with_company_sid = in_share_with_company_sid
	   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class);
	
	AddShareLogEntry(v_qnr_share_id, in_q_share_id, in_user_notes);

END;

PROCEDURE GetQManagementData (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetQManagementData(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_start, in_page_size, in_sort_by, in_sort_dir, out_cur);
END;


PROCEDURE GetQManagementData (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_sort				VARCHAR2(100) DEFAULT in_sort_by||' '||in_sort_dir;
BEGIN

	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN (
		-- add support as needed
		'name', 
		'questionnaire_status_name', 
		'status_update_dtm'
	) THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by "'||in_sort_by||'".');
	END IF;

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	DELETE FROM tt_questionnaire_organizer;
	
	-- if it's our company, pull the ids from the questionnaire table
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm)
		SELECT questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
		   
		-- now we'll fudge any data that is sitting in a mixed shared state
		UPDATE tt_questionnaire_organizer
		   SET questionnaire_status_id = 1000, -- pseudo id
		       questionnaire_status_name = 'Mixed shared states', 
		       status_update_dtm = NULL
		 WHERE questionnaire_id IN (
		 			SELECT questionnaire_id 
		 			  FROM (SELECT questionnaire_id, COUNT(share_status_id) unique_status_count 
		 			  		  FROM (SELECT DISTINCT questionnaire_id, share_status_id FROM v$questionnaire_share) 
		 			  		 GROUP BY questionnaire_id
					) WHERE unique_status_count > 1
		       );
		
		-- now lets fix up statuses that are in unique and valid shared state
		UPDATE tt_questionnaire_organizer qo
		   SET (questionnaire_status_id, questionnaire_status_name, status_update_dtm) = (
				SELECT share_status_id, share_status_name, MAX(entry_dtm)
				  FROM v$questionnaire_share qs
				 WHERE qs.questionnaire_id = qo.questionnaire_id
				   AND qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE
				 GROUP BY share_status_id, share_status_name
				)
		 WHERE qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE;
		
		-- now fix up the due by dtms
		-- TODO: this probably isn't quite right - it should pick the next due dependant on share status (i.e. whether we've submitted it or not)
		UPDATE tt_questionnaire_organizer qo
		   SET due_by_dtm = (
		   		SELECT MAX(due_by_dtm)
		   		  FROM v$questionnaire_share qs
		   		 WHERE qs.questionnaire_id = qo.questionnaire_id
		   		   AND qo.questionnaire_status_id = qs.share_status_id
		   		   AND qo.questionnaire_status_id <> 1000 -- pseudo id
		   		)
		 WHERE qo.questionnaire_status_id <> 1000;	   		   
		 
	-- if it's NOT our company, pull the ids from the questionnaire share view
	ELSE
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, due_by_dtm)
		SELECT questionnaire_id, share_status_id, share_status_name, entry_dtm, due_by_dtm
		  FROM v$questionnaire_share
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qnr_owner_company_sid = in_company_sid
		   AND share_status_id IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED);
	END IF;
	
	
	-- now we'll run the sort on the data, setting a position value for each questionnaire_id
	EXECUTE IMMEDIATE
		'UPDATE tt_questionnaire_organizer qo '||
		'   SET qo.position = ( '||
		'		SELECT rn '||
		'		  FROM ( '||
		'				SELECT questionnaire_id, row_number() OVER (ORDER BY '||v_sort||') rn  '||
		'				  FROM v$questionnaire '||
		'			   ) q  '||
		'		 WHERE q.questionnaire_id = qo.questionnaire_id  '||
		'	  )';

	-- we can now open a clean cursor and use the position column to order and control paging
	OPEN out_cur FOR 
		SELECT r.*, CASE WHEN 
				r.questionnaire_status_id IN (chain_pkg.ENTERING_DATA, chain_pkg.REVIEWING_DATA) 
				THEN edit_url ELSE view_url END url
		  FROM (
				SELECT q.company_sid, q.name, q.edit_url, q.view_url, qo.due_by_dtm,
						qo.questionnaire_status_id, qo.questionnaire_status_name, qo.status_update_dtm, qo.position page_position, 
						COUNT(*) OVER () AS total_rows
				  FROM v$questionnaire q, tt_questionnaire_organizer qo
				 WHERE q.questionnaire_id = qo.questionnaire_id
				 ORDER BY qo.position
			   ) r
		 WHERE page_position > in_start
		   AND page_position <= (in_start + in_page_size);
END;

PROCEDURE GetMyQuestionnaires (
	in_status			IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	OPEN out_cur FOR
		SELECT questionnaire_id, company_sid, questionnaire_type_id, created_dtm, view_url, edit_url, owner_can_review, 
				class, name, db_class, group_name, position, status_log_entry_index, questionnaire_status_id, status_update_dtm
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND questionnaire_status_id = NVL(in_status, questionnaire_status_id)
		 ORDER BY LOWER(name);
END;


PROCEDURE CreateQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_view_url					IN	questionnaire_type.view_url%TYPE,
	in_edit_url					IN	questionnaire_type.edit_url%TYPE,
	in_owner_can_review			IN	questionnaire_type.owner_can_review%TYPE,
	in_name						IN	questionnaire_type.name%TYPE,
	in_class					IN	questionnaire_type.CLASS%TYPE,
	in_db_class					IN	questionnaire_type.db_class%TYPE,
	in_group_name				IN	questionnaire_type.group_name%TYPE,
	in_position					IN	questionnaire_type.position%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
        INSERT INTO questionnaire_type (
			questionnaire_type_id, 
			view_url, 
			edit_url, 
			owner_can_review, 
			name, 
			CLASS, 
			db_class,
			group_name,
			position
		) VALUES ( 
            in_questionnaire_type_id,
            in_view_url,
            in_edit_url,
            in_owner_can_review,
            in_name,
            in_class,
			in_db_class,	
            in_group_name,
            in_position
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE questionnaire_type
               SET	view_url=in_view_url,
                    edit_url= in_edit_url,
                    owner_can_review= in_owner_can_review,
                    name=in_name,
                    CLASS=in_class,
                    db_class=in_db_class,
                    group_name=in_group_name,
                    position=in_position
			WHERE app_sid=security_pkg.getApp
			  AND questionnaire_type_id=in_questionnaire_type_id;
	END;
END;



PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator');
	END IF;

	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN (
		SELECT questionnaire_share_id
		  FROM questionnaire_share qs	
			JOIN questionnaire q ON qs.questionnaire_id = q.questionnaire_id
		 WHERE q.questionnaire_type_id = in_questionnaire_type_id
		   AND q.app_sid = security_pkg.GetApp
	);
	
	DELETE FROM questionnaire_share 
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	 
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	DELETE FROM event
	 WHERE related_action_id IN (
		SELECT action_id
		  FROM action a 
			JOIN questionnaire q ON a.related_questionnaire_id = q.questionnaire_id
		  WHERE q.questionnaire_type_id = in_questionnaire_type_id
		    AND q.app_sid = security_pkg.getApp
	 );
	
	DELETE FROM action
     WHERE related_questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
     );
	
	DELETE FROM invitation_qnr_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM questionnaire
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM questionnaire_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;

END;


PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_is_owner					NUMBER(1) DEFAULT CASE WHEN in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN 1 ELSE 0 END;
	v_can_write					NUMBER(1) DEFAULT CASE WHEN capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_WRITE) THEN 1 ELSE 0 END;
	v_can_submit				NUMBER(1) DEFAULT CASE WHEN capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUBMIT_QUESTIONNAIRE) THEN 1 ELSE 0 END;
	v_ready_to_share			NUMBER(1);
	v_is_shared					NUMBER(1) DEFAULT 0;
	v_status					chain_pkg.T_QUESTIONNAIRE_STATUS;
	v_share_status				chain_pkg.T_SHARE_STATUS;
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
BEGIN
	-- security checks done in sub procedures
	
	IF NOT QuestionnaireExists(in_company_sid, in_qt_class) THEN
		OPEN out_cur FOR
			SELECT 
				0 questionnaire_exists, 
				0 is_ready_to_share,
				0 is_shared, 
				0 can_share, 
				0 is_read_only, 
				0 can_make_editable, 
				0 is_owner, 
				0 is_approved 
			  FROM DUAL;
		
		RETURN;
	END IF;
	
	v_status := GetQuestionnaireStatus(in_company_sid, in_qt_class);
	v_ready_to_share := CASE WHEN v_status = chain_pkg.READY_TO_SHARE THEN 1 ELSE 0 END; 
	
	IF v_is_owner = 0 THEN
		v_share_status := GetQuestionnaireShareStatus(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_qt_class);
		v_is_shared := CASE WHEN v_share_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN 1 ELSE 0 END;
	ELSE
		SELECT owner_can_review
		  INTO v_owner_can_review
		  FROM questionnaire_type
		 WHERE questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
	END IF;
		
	OPEN out_cur FOR
		SELECT
			1 questionnaire_exists,
			v_ready_to_share is_ready_to_share,
			v_is_shared is_shared,
			v_can_submit can_share,
			v_is_owner is_owner,
			CASE 
				WHEN v_can_write = 0 THEN 1
				WHEN v_is_owner = 1 
				 AND v_ready_to_share = 0 THEN 0
				ELSE 1 
			END is_read_only,
			CASE 
				WHEN v_is_owner = 1 AND v_owner_can_review = 1 THEN 1
				WHEN v_is_owner = 0 AND v_can_write = 1 AND v_share_status = chain_pkg.SHARING_DATA THEN 1
				ELSE 0
			END can_make_editable,
			CASE 
				WHEN v_share_status = chain_pkg.SHARED_DATA_ACCEPTED THEN 1 
				ELSE 0 
			END is_approved
		  FROM DUAL;	  
END;

PROCEDURE CheckForOverdueQuestionnaires
AS
	v_event_id			event.event_id%TYPE;
BEGIN
	
	FOR r IN (
		SELECT *
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND due_by_dtm < SYSDATE
		   AND overdue_events_sent = 0
		   AND share_status_id = chain_pkg.NOT_SHARED
	) LOOP
		-- send the message to the Purchaser
		event_pkg.AddEvent(
			r.share_with_company_sid,
			null,
			r.qnr_owner_company_sid,
			null,
			r.questionnaire_id,
			null,
			event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_OVERDUE),
			v_event_id
		);
		
		-- send the message to the supplier
		event_pkg.AddEvent(
			r.qnr_owner_company_sid,
			null,
			r.share_with_company_sid,
			null,
			r.questionnaire_id,
			null,
			event_pkg.GetEventTypeId(event_pkg.EV_QUESTIONNAIRE_OVERDUE_SUP),
			v_event_id
		);
		
		UPDATE questionnaire_share
		   SET overdue_events_sent = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_share_id = r.questionnaire_share_id;
	END LOOP;
END;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,	
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.READY_TO_SHARE, null);
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class, chain_pkg.SHARING_DATA, null);
	action_pkg.ShareQuestionnaireDoActions(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class); 
END;

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_ACCEPTED, null);
	action_pkg.AcceptQuestionaireDoActions(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class);				
END;


END questionnaire_pkg;
/

CREATE OR REPLACE PACKAGE BODY scheduled_alert_pkg
IS
/************************************************************************
	Private
************************************************************************/
FUNCTION GetAlertEntryId (
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id		IN  NUMBER,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN alert_entry.alert_entry_id%TYPE
AS
	v_alert_entry_id		alert_entry.alert_entry_id%TYPE;
BEGIN
	CASE 	
	WHEN in_alert_entry_type = chain_pkg.EVENT_ALERT THEN
		BEGIN
			SELECT alert_entry_id
			  INTO v_alert_entry_id
			  FROM alert_entry_event
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND event_id = in_corresponding_id
			   AND user_sid = in_user_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_alert_entry_id := NULL;
		END;
	
	WHEN in_alert_entry_type = chain_pkg.ACTION_ALERT THEN
		BEGIN
			SELECT alert_entry_id
			  INTO v_alert_entry_id
			  FROM alert_entry_action
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND action_id = in_corresponding_id
			   AND user_sid = in_user_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_alert_entry_id := NULL;
		END;

	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'No case defined for Alert Entry Type '||in_alert_entry_type||'.');
	END CASE;
	
	RETURN v_alert_entry_id;
END;

PROCEDURE SetAlertEntryId (
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id		IN  NUMBER,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_alert_entry_id		IN  alert_entry.alert_entry_id%TYPE
)
AS
BEGIN
	CASE 	
	WHEN in_alert_entry_type = chain_pkg.EVENT_ALERT THEN
		BEGIN
			INSERT INTO alert_entry_event
			(event_id, user_sid, alert_entry_id)
			VALUES
			(in_corresponding_id, in_user_sid, in_alert_entry_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	
	WHEN in_alert_entry_type = chain_pkg.ACTION_ALERT THEN
		BEGIN
			INSERT INTO alert_entry_action
			(action_id, user_sid, alert_entry_id)
			VALUES
			(in_corresponding_id, in_user_sid, in_alert_entry_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;

	ELSE
		RAISE_APPLICATION_ERROR(-20001, 'No case defined for Alert Entry Type '||in_alert_entry_type||'.');
	END CASE;

END;


/************************************************************************
	Public
************************************************************************/

PROCEDURE GetAppAlertSettings (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT site_name, support_email alert_from_email, link_host
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAlertEntryTemplates (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
) 
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM alert_entry_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GenerateAlertEntries 
AS
	v_last_request_time				customer_options.LAST_GENERATE_ALERT_DTM%TYPE;
	v_sched_alerts_enabled			customer_options.SCHED_ALERTS_ENABLED%TYPE;
BEGIN
	-- TODO: Move these out (they're here for a quick fix for the moment)
	invitation_pkg.UpdateExpirations;
	questionnaire_pkg.CheckForOverdueQuestionnaires;
	
	SELECT last_generate_alert_dtm, sched_alerts_enabled
	  INTO v_last_request_time, v_sched_alerts_enabled
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	IF v_sched_alerts_enabled = chain_pkg.INACTIVE THEN
		RETURN;
	END IF;
	
	UPDATE customer_options
	   SET last_generate_alert_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	FOR r IN (
		SELECT generator_pkg
		  FROM alert_entry_type
		 WHERE app_sid IS NULL
		    OR app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		DELETE FROM TT_NAMED_PARAM;
		
		EXECUTE IMMEDIATE 'begin '||r.generator_pkg||'.GenerateAlertEntries(:1); end;'
		  USING v_last_request_time;
	END LOOP;
END;

PROCEDURE GetAlertSchedules (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid, scheduled_alert_intvl_minutes
		  FROM customer_options;
END;

-- pass in a message
PROCEDURE SetAlertEntry(
	in_alert_entry_type		IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id		IN  NUMBER,
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_occurred_dtm			IN  alert_entry.occurred_dtm%TYPE,
	in_template_name		IN  alert_entry.template_name%TYPE,
	in_text					IN  alert_entry.text%TYPE,
	in_param_type_id		IN  chain_pkg.T_ALERT_ENTRY_PARAM_TYPE
)
AS
	v_alert_entry_id		alert_entry.alert_entry_id%TYPE;
BEGIN
	v_alert_entry_id := GetAlertEntryId(in_alert_entry_type, in_corresponding_id, in_user_sid);
	
	IF v_alert_entry_id IS NULL THEN
		INSERT INTO alert_entry
		(alert_entry_id, alert_entry_param_type_id, alert_entry_type_id, company_sid, user_sid, occurred_dtm, template_name, text)
		VALUES
		(alert_entry_id_seq.nextval, in_param_type_id, in_alert_entry_type, in_company_sid, in_user_sid, in_occurred_dtm, in_template_name, in_text)
		RETURNING alert_entry_id INTO v_alert_entry_id;	
		
		SetAlertEntryId(in_alert_entry_type, in_corresponding_id, in_user_sid, v_alert_entry_id);
	ELSE	
		UPDATE alert_entry
		   SET occurred_dtm = in_occurred_dtm,
			   template_name = in_template_name,
			   text = in_text
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_entry_id = v_alert_entry_id;


		DELETE FROM alert_entry_ordered_param
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_entry_id = v_alert_entry_id;
		
		DELETE FROM alert_entry_named_param
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_entry_id = v_alert_entry_id;
	END IF;
	
	CASE 
	WHEN in_param_type_id = chain_pkg.NAMED_PARAMS THEN
		
		INSERT INTO alert_entry_named_param
		(alert_entry_id, name, value)
		SELECT v_alert_entry_id, name, value
		  FROM TT_NAMED_PARAM
		 WHERE id = in_corresponding_id;
	
	WHEN in_param_type_id = chain_pkg.ORDERED_PARAMS THEN
		
		INSERT INTO alert_entry_ordered_param
		(alert_entry_id, position, value)
		SELECT v_alert_entry_id, position, value
		  FROM TT_ORDERED_PARAM
		 WHERE id = in_corresponding_id;
		
	ELSE --> required
		NULL;
		
	END CASE;
END;

PROCEDURE UpdateTemplateName (
	in_alert_entry_type			IN  chain_pkg.T_ALERT_ENTRY_TYPE,
	in_corresponding_id			IN  NUMBER,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_template_name			IN  alert_entry.template_name%TYPE
)
AS
	v_alert_entry_id		alert_entry.alert_entry_id%TYPE;
BEGIN
	v_alert_entry_id := GetAlertEntryId(in_alert_entry_type, in_corresponding_id, in_user_sid);
	
	IF v_alert_entry_id IS NULL THEN
		RETURN;
	END IF;
	
	UPDATE alert_entry
	   SET template_name = in_template_name
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND alert_entry_id = v_alert_entry_id
	   AND owner_scheduled_alert_id IS NULL; -- ignore this - its already been sent out
END;	


PROCEDURE GetOutstandingAlertRecipients (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.company_sid, c.name company_name, cu.user_sid, cu.friendly_name, cu.email
		  FROM v$company c, v$chain_user cu, (
				SELECT UNIQUE app_sid, company_sid, user_sid
				  FROM alert_entry
				 WHERE owner_scheduled_alert_id IS NULL
			   ) r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.app_sid = c.app_sid
		   AND r.app_sid = cu.app_sid
		   AND r.company_sid = c.company_sid
		   AND r.user_sid = cu.user_sid
		   AND cu.receive_scheduled_alerts = chain_pkg.ACTIVE
		   AND cu.next_scheduled_alert_dtm < SYSDATE;
END;

PROCEDURE UpdateUserDistributionTimes
AS
BEGIN
	UPDATE chain_user
	   SET next_scheduled_alert_dtm = TO_DATE(TO_CHAR(SYSDATE+1, 'yyyy/mm/dd')||' '||TO_CHAR(scheduled_alert_time, 'HH24:MI'), 'yyyy/mm/dd HH24:MI')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND next_scheduled_alert_dtm < SYSDATE;
END;

PROCEDURE SendingScheduledAlertTo (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,	
	out_entries_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_params_cur			OUT security_pkg.T_OUTPUT_CUR
) 
AS
	v_sa_id					scheduled_alert.scheduled_alert_id%TYPE;
BEGIN

	INSERT INTO scheduled_alert
	(company_sid, user_sid, scheduled_alert_id)
	VALUES
	(in_company_sid, in_user_sid, scheduled_alert_id_seq.nextval)
	RETURNING scheduled_alert_id INTO v_sa_id;

	UPDATE alert_entry
	   SET owner_scheduled_alert_id = v_sa_id
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid
	   AND owner_scheduled_alert_id IS NULL;

	OPEN out_entries_cur FOR
		SELECT *
		  FROM alert_entry
		 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
		   AND owner_scheduled_alert_id = v_sa_id
		 ORDER BY occurred_dtm DESC;	

	OPEN out_params_cur FOR
		SELECT * 
		  FROM (
			SELECT app_sid, alert_entry_id, name, null position, value
			  FROM alert_entry_named_param
			 WHERE (app_sid, alert_entry_id, chain_pkg.NAMED_PARAMS) IN
				   (
					SELECT app_sid, alert_entry_id, alert_entry_param_type_id
					  FROM alert_entry
					 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
					   AND owner_scheduled_alert_id = v_sa_id
				   )
			 UNION
			SELECT app_sid, alert_entry_id, null name, position, value
			  FROM alert_entry_ordered_param
			 WHERE (app_sid, alert_entry_id, chain_pkg.ORDERED_PARAMS) IN
				   (
					SELECT app_sid, alert_entry_id, alert_entry_param_type_id
					  FROM alert_entry
					 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
					   AND owner_scheduled_alert_id = v_sa_id
				   )
			)
		ORDER BY position;
END;

END scheduled_alert_pkg;
/


CREATE OR REPLACE PACKAGE BODY CHAIN.task_pkg
IS

ArgumentNotSupported EXCEPTION;
PRAGMA EXCEPTION_INIT(ArgumentNotSupported, -06550);

PROCEDURE CreateTaskNode (
	in_company_sid				IN security_pkg.T_SID_ID,
	in_parent_task_node			IN task_node.task_node_id%TYPE,
	in_heading					IN task_node.heading%TYPE,
	in_description				IN task_node.description%TYPE,
	in_task_node_type_id		IN task_node.task_node_type_id%TYPE,
	out_task_node_id			OUT task_node.task_node_id%TYPE
)
AS
	in_task_node_class		task_node_type.db_class%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;

	INSERT INTO task_node (
		task_node_id, app_sid, parent_task_node_id,
		heading, description, company_sid, task_node_type_id
	) VALUES (
		task_node_id_seq.NEXTVAL, SYS_CONTEXT('SECURITY', 'APP'), in_parent_task_node,
		in_heading, in_description, in_company_sid, in_task_node_type_id
	) RETURNING task_node_id INTO out_task_node_id;
END;

PROCEDURE AddSimpleTask (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_node_type_id		IN	task_node.task_node_type_id%TYPE,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_edit_due_date			IN	task.due_date_editable%TYPE,
	in_is_mandatory				IN	task.mandatory%TYPE,
	in_heading					IN	task.heading%TYPE,
	in_description				IN	task.description%TYPE,
	out_task_id					OUT	task.task_id%TYPE
)
AS
	v_node_id					task.task_node_id%TYPE;
	CURSOR						c_find_node IS
										SELECT task_node_id FROM task_node
										 WHERE app_sid=SYS_CONTEXT('SECURITY', 'APP')
										   AND task_node_type_id=in_task_node_type_id
										   AND company_sid=in_company_sid;
	v_heading					task.heading%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;
	
	OPEN c_find_node;
	FETCH c_find_node INTO v_node_id;
	IF c_find_node%NOTFOUND THEN
		task_pkg.createTaskNode(in_company_sid, NULL, NULL, NULL, in_task_node_type_id, v_node_id);
	END IF;
	CLOSE c_find_node;
	v_heading := in_heading;
	IF v_heading IS NULL THEN -- pull default heading
		SELECT description INTO v_heading FROM task_type WHERE task_type_id=in_task_type_id AND app_sid=SYS_CONTEXT('SECURITY', 'APP');
	END IF;
	INSERT INTO TASK (
		TASK_ID, APP_SID, TASK_NODE_ID, TASK_STATUS_ID,
		HEADING, DESCRIPTION, DUE_DATE, DUE_DATE_EDITABLE,
		MANDATORY, CREATED_DTM, CREATED_BY_SID,
		COMPANY_SID, TASK_TYPE_ID
	) VALUES (
		task_id_seq.NEXTVAL, SYS_CONTEXT('SECURITY', 'APP'), v_node_id, in_task_status,
		v_heading, in_description, in_due_date, in_edit_due_date,
		in_is_mandatory, SYSDATE, security_pkg.GetSID(),
		in_company_sid, in_task_type_id
	);
END;

PROCEDURE ProcessTasks (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
)
AS
	v_class		QUESTIONNAIRE_TYPE.DB_CLASS%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;

	BEGIN
		SELECT db_class INTO v_class FROM QUESTIONNAIRE_TYPE WHERE CLASS=in_questionnaire_class;
	EXCEPTION WHEN NO_DATA_FOUND THEN
		RETURN;
	END;

	BEGIN
		execute immediate 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_company_sid;
	EXCEPTION WHEN ArgumentNotSupported THEN
    	raise_application_error (-20001, 'Questionnaire class ' || v_class || ' does not support UpdateTasksForCompany');
	END;
END;

PROCEDURE ProcessTaskNode (
	in_company_sid					IN	security_pkg.T_SID_ID,
	in_task_node_id					IN	task.task_node_id%TYPE
)
AS
	v_class		QUESTIONNAIRE_TYPE.DB_CLASS%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;

	BEGIN
		SELECT db_class INTO v_class 
						FROM TASK_NODE_TYPE 
					   WHERE task_node_type_id= (
							 SELECT task_node_type_id FROM TASK_NODE
													 WHERE task_node_id=in_task_node_id
													   AND company_sid=in_company_sid
													   AND APP_SID=SYS_CONTEXT('SECURITY', 'APP')
							 ) 
						 AND APP_SID=SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION WHEN NO_DATA_FOUND THEN
		RETURN;
	END;

	IF v_class IS NULL THEN
		RETURN;
	END IF;

	BEGIN
		execute immediate 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_company_sid;
	EXCEPTION WHEN ArgumentNotSupported THEN
    	raise_application_error (-20001, 'Package ' || v_class || ' does not support UpdateTasksForCompany');
	END;
END;

PROCEDURE ChangeTaskStatus (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;
	
	UPDATE task SET task_status_id=in_status_id
			  WHERE task_id=in_task_id
				AND company_sid=in_company_sid
				AND app_sid=SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetTaskStatus (
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	out_status_id				OUT	task.task_status_id%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||in_company_sid);
	END IF;

	SELECT task_status_id INTO out_status_id
						  FROM task
						 WHERE task_id=in_task_id
						   AND company_sid=in_company_sid
						   AND app_sid=SYS_CONTEXT('SECURITY','APP');
EXCEPTION
	WHEN no_data_found THEN
		RETURN;
END;

PROCEDURE GetTaskDueDays (
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_task_type_id			IN	task.task_type_id%TYPE,
	out_due_in_days			OUT	number
)
AS
	v_task_type_id			task.task_type_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||in_company_sid);
	END IF;

	v_task_type_id := in_task_type_id;
	/*IF v_task_type_id IS NULL THEN
		BEGIN
      SELECT task_type_id INTO v_task_type_id
               FROM task
              WHERE task_id=in_task_id
                AND company_sid=in_company_sid
                AND app_sid=SYS_CONTEXT('SECURITY','APP');
		EXCEPTION
			WHEN no_data_found THEN
				raise_application_error (-20100, 'GetTaskDueDays cannot find task ' || in_task_id || ' for company ' || in_company_sid);
		END;
	END IF;*/

	BEGIN
    SELECT due_in_days
      INTO out_due_in_days
      FROM task_type
     WHERE task_type_id=in_task_type_id
       AND app_sid=SYS_CONTEXT('SECURITY','APP');
	EXCEPTION
		WHEN no_data_found THEN
			raise_application_error(-20100, 'GetTaskDueDays cannot find task type ' || in_task_type_id || ' for company ' || in_company_sid);
	END;
END;

PROCEDURE SetTaskDueDate (
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	number
)
AS
	v_due_date					date;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;
	
	BEGIN
    SELECT due_date	INTO v_due_date 
                    FROM task
                   WHERE task_id=in_task_id
                     AND company_sid=in_company_sid
                     AND app_sid=SYS_CONTEXT('SECURITY','APP');
	EXCEPTION
		WHEN no_data_found THEN
			raise_application_error(-20100, 'SetTaskDueDate cannot find task ' || in_task_id || ' for company ' || in_company_sid);
	END;
	IF (v_due_date IS NOT NULL AND NVL(in_overwrite,0) <> 0) OR
		 v_due_date IS NULL THEN
		UPDATE task SET due_date = in_due_date
              WHERE task_id=in_task_id
                AND company_sid=in_company_sid
                AND app_sid=SYS_CONTEXT('SECURITY','APP');
	END IF; 
END;

PROCEDURE GetTopLevelTaskNodes (
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||in_company_sid);
	END IF;


	OPEN out_cur FOR
		SELECT
			task_node_id, task_node_id root_task_node_id, parent_task_node_id,
			heading, description,
			1 LEVEL, company_sid
		 FROM task_node
		WHERE app_sid = security_pkg.GetApp
		  AND company_sid = in_company_sid
		  AND parent_task_node_id IS NULL;

END;

PROCEDURE GetFlattenedTasks (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_task_node_id				IN	task.task_node_id%TYPE,
	out_cur								OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||in_company_sid);
	END IF;

	IF in_task_node_id IS NULL THEN
    OPEN out_cur FOR
      SELECT * FROM task
              WHERE company_sid=in_company_sid
           ORDER BY task_type_id ASC; -- this is horrible - we should join on task type and have a display order!
  ELSE
    OPEN out_cur FOR
      SELECT * FROM task
              WHERE company_sid=in_company_sid
                AND task_node_id IN (
                    SELECT task_node_id FROM task_node
                            CONNECT BY PRIOR parent_task_node_id = task_node_id
                                  START WITH task_node_id=in_task_node_id
                )
           ORDER BY task_type_id ASC; -- this is horrible - we should join on task type and have a display order!
  END IF;
END;


PROCEDURE UpdateTask (
	in_company_sid			IN 	security_pkg.T_SID_ID,
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date	IN	date,
	in_due_date					IN	date
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||in_company_sid);
	END IF;
	
	UPDATE task 
	   SET	task_status_id = in_status_id,
			next_review_date = in_next_review_date,
			due_date = in_due_date
	 WHERE	task_id=in_task_id
	   AND	company_sid=in_company_sid;	
END;

/*
PROCEDURE GetTasksWithHeirachy (
	in_company_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	CheckCompanyPermission(in_company_sid, security_pkg.PERMISSION_READ);

	OPEN out_cur FOR
		SELECT
			root_task_node_id, lvl, n.task_node_id, parent_task_node_id,
			heading, description, show_heading,
			show_description, n.company_sid,
			-------
			task_id, task_status_id, task_status, task_description, due_date,
			review_every_n_days, next_review_date, mandatory,
			created_dtm, task_type_id, task_type, db_package,
			questionnaire_id, action_id
		FROM (
			SELECT
				task_node_id, app_sid, parent_task_node_id,
				heading, description, show_heading,
				show_description, company_sid, level lvl, CONNECT_BY_ROOT task_node_id root_task_node_id
			FROM task_node
			START WITH task_node_id IN (
				SELECT
					task_node_id
				 FROM task_node
				WHERE app_sid = security_pkg.GetApp
				  AND company_sid = in_company_sid
				  AND parent_task_node_id IS NULL
			)
			CONNECT BY PRIOR task_node_id = parent_task_node_id
		) n, (
			SELECT
				task_node_id, app_sid, task_id, ts.task_status_id, ts.description task_status, t.description task_description, due_date,
				review_every_n_days, next_review_date, mandatory,
				created_dtm, company_sid, tt.task_type_id, tt.description task_type, tt.db_package,
				questionnaire_id, action_id
			FROM task t, task_status ts, task_type tt
		   WHERE t.task_status_id = ts.task_status_id
		     AND t.task_type_id = tt.task_type_id
		     AND app_sid = security_pkg.GetApp
			 AND company_sid = in_company_sid
		) t
		WHERE n.app_sid = t.app_sid(+)
		  AND n.task_node_id = t.task_node_id(+)
		ORDER BY root_task_node_id, lvl, task_node_id, task_id;


END;

PROCEDURE SaveTask (
	in_task_id				IN	task.task_id%TYPE,
	in_task_node_id			IN	task.task_node_id%TYPE,
	in_task_status_id		IN	task.task_status_id%TYPE,
	in_description			IN	task.description%TYPE,
	in_due_date				IN	task.due_date%TYPE,
	in_review_every_n_days	IN	task.review_every_n_days%TYPE,
	in_next_review_date		IN	task.next_review_date%TYPE,
	in_mandatory			IN	task.mandatory%TYPE,
	in_company_sid			IN	task.company_sid%TYPE,
	in_task_type_id			IN	task.task_type_id%TYPE
)
AS
BEGIN
	CheckCompanyPermission(in_company_sid, security_pkg.PERMISSION_READ);

	IF in_task_id < 0 THEN
		NULL; -- we don't support adding tasks yet
	ELSE
		UPDATE task
			SET
				   task_node_id        = in_task_node_id,
				   task_status_id      = in_task_status_id,
				   description         = in_description,
				   due_date            = in_due_date,
				   review_every_n_days = in_review_every_n_days,
				   next_review_date    = in_next_review_date,
				   mandatory           = in_mandatory,
				   company_sid         = in_company_sid,
				   task_type_id        = in_task_type_id
		WHERE task_id = in_task_id
		  AND company_sid = in_company_sid
		  AND app_sid = security_pkg.GetApp;
	END IF;

END;
*/

END task_pkg;
/

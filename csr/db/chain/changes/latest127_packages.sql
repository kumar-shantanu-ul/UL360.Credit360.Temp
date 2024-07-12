CREATE OR REPLACE PACKAGE chain.alert_helper_pkg
IS

HEADER_TEMPLATE						CONSTANT NUMBER := 1;
FOOTER_TEMPLATE						CONSTANT NUMBER := 2;


PROCEDURE GetPartialTemplates (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	out_partial_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
);

PROCEDURE SavePartialTemplate (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	in_partial_template_type_id			IN	alert_partial_template.partial_template_type_id%TYPE,
	in_partial_html					IN	alert_partial_template.partial_html%TYPE,
	in_params						IN	T_STRING_LIST
);

END alert_helper_pkg;
/
CREATE OR REPLACE PACKAGE chain.capability_pkg
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

-- auto type
PROCEDURE UnhideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
);

-- type specified
PROCEDURE UnhideCapability (
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


CREATE OR REPLACE PACKAGE chain.card_pkg
IS

PROCEDURE DumpCard (
	in_js_class				IN  card.js_class_type%TYPE
);

PROCEDURE DumpCards (
	in_js_classes			IN  T_STRING_LIST
);

PROCEDURE DumpGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
);

FUNCTION GetCardId (
	in_js_class				IN  card.js_class_type%TYPE
) RETURN card.card_id%TYPE;

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

-- generally, should not be called directly
PROCEDURE CollectManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_cards_to_use			IN  security.T_SID_TABLE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
);


END card_pkg;
/


CREATE OR REPLACE PACKAGE chain.chain_link_pkg
IS

PROCEDURE AddCompanyUser (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUpload (
	in_upload_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
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
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	out_titles					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProduct (
	in_product_id				IN  product.product_id%TYPE
);

PROCEDURE KillProduct (
	in_product_id				IN  product.product_id%TYPE
);

-- subscribers of this method are expected to modify data in the tt_component_type_containment table
PROCEDURE FilterComponentTypeContainment;

FUNCTION FindMessageRecipient (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
) RETURN recipient.recipient_id%TYPE;

PROCEDURE MessageRefreshed (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE MessageCreated (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE MessageCompleted (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE InvitationAccepted (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE InvitationRejected (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
);

PROCEDURE InvitationExpired (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
);

FUNCTION GetTaskSchemeId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN task_scheme.task_scheme_id%TYPE;

PROCEDURE TaskStatusChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN  chain_pkg.T_TASK_STATUS
);

PROCEDURE TaskEntryChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
);

END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE chain.chain_pkg
IS

/**********************************************************************
	ANY UNUSED CONSTANTS SHOULD BE MOVED TO THE "DEPRICATED"
	SECTION BELOW SO THAT OLD UPDATE SCRIPTS STILL RUN
**********************************************************************/

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;
TYPE   T_NUMBERS                	IS TABLE OF NUMBER(10) INDEX BY PLS_INTEGER;



-- a general use code
UNDEFINED							CONSTANT NUMBER := 0;
HIDE_HELP_TEXT						CONSTANT VARCHAR2(1) := NULL;

SUBTYPE T_ACTIVE					IS NUMBER;
ACTIVE 								CONSTANT T_ACTIVE := 1;
INACTIVE 							CONSTANT T_ACTIVE := 0;

SUBTYPE T_DELETED					IS NUMBER;
DELETED 							CONSTANT T_DELETED := 1;
NOT_DELETED 						CONSTANT T_DELETED := 0;

INVERTED_CHECK						CONSTANT BOOLEAN := TRUE;
NORMAL_CHECK						CONSTANT BOOLEAN := FALSE;

SUBTYPE T_GROUP						IS VARCHAR2(100);
ADMIN_GROUP							CONSTANT T_GROUP := 'Administrators';
USER_GROUP							CONSTANT T_GROUP := 'Users';
PENDING_GROUP						CONSTANT T_GROUP := 'Pending Users';
CHAIN_ADMIN_GROUP					CONSTANT T_GROUP := 'Chain '||ADMIN_GROUP;
CHAIN_USER_GROUP					CONSTANT T_GROUP := 'Chain '||USER_GROUP;

COMPANY_UPLOADS						CONSTANT security.securable_object.name%TYPE := 'Uploads';
COMPANY_FILTERS						CONSTANT security.securable_object.name%TYPE := 'Filters';
UNINVITED_SUPPLIERS					CONSTANT security.securable_object.name%TYPE := 'Uninvited Suppliers';

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
CREATE_QUESTIONNAIRE_TYPE			CONSTANT T_CAPABILITY := 'Create questionnaire type';
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
UPLOADED_FILE						CONSTANT T_CAPABILITY := 'Uploaded file';

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
SELF_REG_Q_INVITATION				CONSTANT T_INVITATION_TYPE := 3;

SUBTYPE T_INVITATION_STATUS			IS NUMBER;
-- ACTIVE = 1 (defined above)
EXPIRED								CONSTANT T_INVITATION_STATUS := 2;
CANCELLED							CONSTANT T_INVITATION_STATUS := 3;
PROVISIONALLY_ACCEPTED				CONSTANT T_INVITATION_STATUS := 4;
ACCEPTED							CONSTANT T_INVITATION_STATUS := 5;
REJECTED_NOT_EMPLOYEE				CONSTANT T_INVITATION_STATUS := 6;
REJECTED_NOT_SUPPLIER				CONSTANT T_INVITATION_STATUS := 7;
ANOTHER_USER_REGISTERED				CONSTANT T_INVITATION_STATUS := 8;-- only one user allowed to self-register per company 

SUBTYPE T_GUID_STATE				IS NUMBER;
GUID_OK 							CONSTANT T_GUID_STATE := 0;
--GUID_INVALID						CONSTANT T_GUID_STATE := 1; -- probably only used in cs class
GUID_NOTFOUND						CONSTANT T_GUID_STATE := 2;
GUID_EXPIRED						CONSTANT T_GUID_STATE := 3;
GUID_ALREADY_USED					CONSTANT T_GUID_STATE := 4;
GUID_CANCELLED						CONSTANT T_GUID_STATE := 5;
GUID_ANOTHER_USER_REGISTERED		CONSTANT T_GUID_STATE := 6;

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

/****************************************************************************************************/
SUBTYPE T_FLAG						IS BINARY_INTEGER;

ALLOW_NONE							CONSTANT T_FLAG := 0;
ALLOW_ADD_EXISTING					CONSTANT T_FLAG := 1;
ALLOW_ADD_NEW						CONSTANT T_FLAG := 2;
--ALLOW_EDIT							CONSTANT T_FLAG := 4;
ALLOW_ALL							CONSTANT T_FLAG := 3;

/****************************************************************************************************/
SUBTYPE T_ACCEPTANCE_STATUS			IS NUMBER;

ACCEPT_PENDING						CONSTANT T_ACCEPTANCE_STATUS := 1;
ACCEPT_ACCEPTED						CONSTANT T_ACCEPTANCE_STATUS := 2;
ACCEPT_REJECTED						CONSTANT T_ACCEPTANCE_STATUS := 3;

/****************************************************************************************************/
SUBTYPE T_SUPPLIER_TYPE				IS NUMBER;

SUPPLIER_NOT_SET					CONSTANT T_SUPPLIER_TYPE := 0;
EXISTING_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 1;
EXISTING_PURCHASER					CONSTANT T_SUPPLIER_TYPE := 2;
UNINVITED_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 3;

/****************************************************************************************************/
SUBTYPE T_REPEAT_TYPE				IS NUMBER;
NEVER_REPEAT						CONSTANT T_REPEAT_TYPE := 0;
REPEAT_IF_CLOSED					CONSTANT T_REPEAT_TYPE := 1;
REFRESH_OR_REPEAT					CONSTANT T_REPEAT_TYPE := 2;
ALWAYS_REPEAT						CONSTANT T_REPEAT_TYPE := 3;

SUBTYPE T_ADDRESS_TYPE				IS NUMBER;
USER_ADDRESS						CONSTANT T_ADDRESS_TYPE := 0;
COMPANY_USER_ADDRESS				CONSTANT T_ADDRESS_TYPE := 1;
COMPANY_ADDRESS						CONSTANT T_ADDRESS_TYPE := 2;

SUBTYPE T_ADDRESSING_PSEUDO_USER	IS security_pkg.T_SID_ID;
FOLLOWERS							CONSTANT T_ADDRESSING_PSEUDO_USER := -1;

SUBTYPE T_PRIORITY_TYPE				IS NUMBER;
--HIDDEN (defined above)			CONSTANT T_PRIORITY_TYPE := 0;
NEUTRAL								CONSTANT T_PRIORITY_TYPE := 1;
SHOW_STOPPER						CONSTANT T_PRIORITY_TYPE := 2;

SUBTYPE T_COMPLETION_TYPE			IS NUMBER;
NO_COMPLETION						CONSTANT T_COMPLETION_TYPE := 0;
ACKNOWLEDGE							CONSTANT T_COMPLETION_TYPE := 1;
CODE_ACTION							CONSTANT T_COMPLETION_TYPE := 2;

/****************************************************************************************************/
SUBTYPE T_MESSAGE_DEFINITION_LOOKUP	IS NUMBER;
-- Secondary directional stuff --
NONE_IMPLIED						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 0;
PURCHASER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
SUPPLIER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Administrative messaging --
CONFIRM_COMPANY_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
CONFIRM_YOUR_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 101;
COMPANY_DELETED						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 102;

-- Invitation messaging --
INVITATION_SENT						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
INVITATION_ACCEPTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 201;
INVITATION_REJECTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 202;
INVITATION_EXPIRED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 203;

-- Questionnaire messaging --
COMPLETE_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 300;
QUESTIONNAIRE_SUBMITTED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 301;
QUESTIONNAIRE_APPROVED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 302;
QUESTIONNAIRE_OVERDUE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 303;
QUESTIONNAIRE_REJECTED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 304;
QUESTIONNAIRE_RETURNED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 305;

-- Component messaging --
PRODUCT_MAPPING_REQUIRED			CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 400;
UNINVITED_SUPPLIERS_TO_INVITE		CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 401;
MAPPED_PRODUCTS_TO_PUBLISH			CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 402;

-- MAERSK --
CHANGED_SUPPLIER_REG_DETAILS		CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 10000;
ACTION_PLAN_STARTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 10001;

/****************************************************************************************************/
SUBTYPE T_COMPONENT_CODE			IS component.component_code%TYPE;

SUBTYPE T_COMPONENT_TYPE			IS NUMBER;

-- COMPONENT types
PRODUCT_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 1;
LOGICAL_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 2;
PURCHASED_COMPONENT					CONSTANT T_COMPONENT_TYPE := 3;
NOTSURE_COMPONENT					CONSTANT T_COMPONENT_TYPE := 4;

-- CLIENT SPECIFC COMPONENT TYPES 
RA_WOOD_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 50;
RA_NOT_WOOD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 52;

/****************************************************************************************************/
SUBTYPE T_TASK_STATUS				IS NUMBER;

TASK_DEFAULT_STATUS					CONSTANT T_TASK_STATUS := -2;
TASK_LAST_STATUS					CONSTANT T_TASK_STATUS := -1;
TASK_HIDDEN							CONSTANT T_TASK_STATUS := 0;
TASK_OPEN							CONSTANT T_TASK_STATUS := 3;
TASK_CLOSED							CONSTANT T_TASK_STATUS := 6;
TASK_PENDING						CONSTANT T_TASK_STATUS := 7;
TASK_REMOVED						CONSTANT T_TASK_STATUS := 8;
TASK_NA								CONSTANT T_TASK_STATUS := 9;
TASK_REVIEW							CONSTANT T_TASK_STATUS := 10;

/* removed as they're not currently used
TASK_REQ_INIT_APPROVAL				CONSTANT T_TASK_STATUS := 1;
TASK_SUB_INIT_APPROVAL				CONSTANT T_TASK_STATUS := 2;
TASK_SUB_APPROVAL					CONSTANT T_TASK_STATUS := 4;
TASK_APPROVED						CONSTANT T_TASK_STATUS := 5;
*/

SUBTYPE T_TASK_ACTION				IS NUMBER;
REVERT_TASK_OFFSET					CONSTANT NUMBER := 10;

OPEN_TASK							CONSTANT T_TASK_ACTION := 1;
CLOSE_TASK							CONSTANT T_TASK_ACTION := 2;
REMOVE_TASK							CONSTANT T_TASK_ACTION := 3;
NA_TASK								CONSTANT T_TASK_ACTION := 4;
START_REVIEW_TASK					CONSTANT T_TASK_ACTION := 5;
REVERT_OPEN_TASK					CONSTANT T_TASK_ACTION := REVERT_TASK_OFFSET + OPEN_TASK;
REVERT_CLOSE_TASK					CONSTANT T_TASK_ACTION := REVERT_TASK_OFFSET + CLOSE_TASK;
REVERT_REMOVE_TASK					CONSTANT T_TASK_ACTION := REVERT_TASK_OFFSET + REMOVE_TASK;
REVERT_NA_TASK						CONSTANT T_TASK_ACTION := REVERT_TASK_OFFSET + NA_TASK;
REVERT_START_REVIEW_TASK			CONSTANT T_TASK_ACTION := REVERT_TASK_OFFSET + START_REVIEW_TASK;

-- aliases for task setup clarity
ON_OPEN_TASK						CONSTANT T_TASK_ACTION := OPEN_TASK;
ON_CLOSE_TASK						CONSTANT T_TASK_ACTION := CLOSE_TASK;
ON_REMOVE_TASK						CONSTANT T_TASK_ACTION := REMOVE_TASK;
ON_NA_TASK							CONSTANT T_TASK_ACTION := NA_TASK;
ON_START_REVIEW_TASK				CONSTANT T_TASK_ACTION := START_REVIEW_TASK;
ON_REVERT_OPEN_TASK					CONSTANT T_TASK_ACTION := REVERT_OPEN_TASK;
ON_REVERT_CLOSE_TASK				CONSTANT T_TASK_ACTION := REVERT_CLOSE_TASK;
ON_REVERT_REMOVE_TASK				CONSTANT T_TASK_ACTION := REVERT_REMOVE_TASK;
ON_REVERT_NA_TASK					CONSTANT T_TASK_ACTION := REVERT_NA_TASK;
ON_REVERT_START_REVIEW_TASK			CONSTANT T_TASK_ACTION := REVERT_START_REVIEW_TASK;

SUBTYPE T_TASK_ENTRY_TYPE			IS NUMBER;

TASK_DATE							CONSTANT T_TASK_ENTRY_TYPE := 1;
TASK_NOTE							CONSTANT T_TASK_ENTRY_TYPE := 2;
TASK_FILE							CONSTANT T_TASK_ENTRY_TYPE := 3;

/****************************************************************************************************/

SUBTYPE T_DOWNLOAD_PERMISSION		IS NUMBER;

DOWNLOAD_PERM_STANDARD				CONSTANT T_DOWNLOAD_PERMISSION := 0;
DOWNLOAD_PERM_EVERYONE				CONSTANT T_DOWNLOAD_PERMISSION := 1;
DOWNLOAD_PERM_SUPPLIERS				CONSTANT T_DOWNLOAD_PERMISSION := 2;

-- the intention here is that different grouping models can be put in
-- e.g. - the lauguage group selects the best file for the user's language settings
-- another example might be zip group - downloading mulitple files as a single zip file, etc.
SUBTYPE T_FILE_GROUP_MODEL			IS NUMBER;

LANGUAGE_GROUP						CONSTANT T_FILE_GROUP_MODEL := 0;


/****************************************************************************************************/

SUBTYPE T_FILTER_COMPARATOR			IS VARCHAR2(64);
FILTER_COMPARATOR_CONTAINS			CONSTANT T_FILTER_COMPARATOR := 'contains';
FILTER_COMPARATOR_EQUALS			CONSTANT T_FILTER_COMPARATOR := 'equals';

/****************************************************************************************************/

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

ERR_COMPANY_IS_DELETED CONSTANT NUMBER := -20510;
COMPANY_IS_DELETED EXCEPTION;
PRAGMA EXCEPTION_INIT(COMPANY_IS_DELETED, -20510);

/*******************************************************************/
/*******************************************************************/
--		DEPRICATED
/*******************************************************************/
/*******************************************************************/
RA_ROOT_PROD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 48;
RA_ROOT_WOOD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 49;
RA_WOOD_ESTIMATE_COMPONENT			CONSTANT T_COMPONENT_TYPE := 51;

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END chain_pkg;
/


CREATE OR REPLACE PACKAGE chain.company_filter_pkg
IS

/* filter helper_pkg procs */
PROCEDURE FilterSids (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_sids				IN  security.T_ORDERED_SID_TABLE,
	out_sids			OUT security.T_ORDERED_SID_TABLE
);

END company_filter_pkg;
/
CREATE OR REPLACE PACKAGE chain.company_pkg
IS


/************************************************************
	SYS_CONTEXT handlers
************************************************************/

FUNCTION TrySetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE SetCompany(
	in_name						IN  security_pkg.T_SO_NAME
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;


/************************************************************
	Securable object handlers
************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
);

/************************************************************
	Company Management Handlers
************************************************************/
-- this can be used to trigger a verification of each company's so structure during updates
PROCEDURE VerifySOStructure;

PROCEDURE CreateCompany(	
	in_name						IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueCompany(
	in_name						IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	in_sector_id				IN  company.sector_id%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

/* returns sid if present and -1 in not */
FUNCTION CheckCompanyUnique(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE
) RETURN NUMBER;

PROCEDURE DeleteCompanyFully(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (	
	in_company_sid				IN  security_pkg.T_SID_ID, 
	in_name						IN  company.name%TYPE,
	in_address_1				IN  company.address_1%TYPE,
	in_address_2				IN  company.address_2%TYPE,
	in_address_3				IN  company.address_3%TYPE,
	in_address_4				IN  company.address_4%TYPE,
	in_town						IN  company.town%TYPE,
	in_state					IN  company.state%TYPE,
	in_postcode					IN  company.postcode%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	in_phone					IN  company.phone%TYPE,
	in_fax						IN  company.fax%TYPE,
	in_website					IN  company.website%TYPE,
	in_sector_id				IN  company.sector_id%TYPE
);
	
FUNCTION GetCompanySid (	
	in_company_name				IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetCompanySid (	
	in_company_name				IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION GetCompanyName (
	in_company_sid 				IN security_pkg.T_SID_ID
) RETURN company.name%TYPE;

PROCEDURE SearchCompanies ( 
	in_search_term  			IN  varchar2,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE FilterCompanies (
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSuppliers ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	in_only_active				IN  number,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSupplierNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchaserNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchMyCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
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
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE DeactivateVirtualRelationship (
	in_key						IN  supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
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
	in_user_sid					IN  security_pkg.T_SID_ID,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStubSetupDetails (
	in_active					IN  company.allow_stub_registration%TYPE,
	in_approve					IN  company.approve_stub_registration%TYPE,
	in_stubs					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetStubSetupDetails (
	out_options_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyFromStubGuid (
	in_guid						IN  company.stub_registration_guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ConfirmCompanyDetails (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetCompaniesRegisteredByUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_company_sids			OUT security.T_ORDERED_SID_TABLE
);

PROCEDURE GetCompaniesAndUsers (
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END company_pkg;
/


CREATE OR REPLACE PACKAGE chain.company_user_pkg
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

PROCEDURE GetAllCompanyUsers (
	in_company_sid_array	IN  security_pkg.T_SID_IDS,
	in_dummy				IN  NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
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
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS;

FUNCTION GetRegistrationStatusNoCheck (
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

PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetRegUsersForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

END company_user_pkg;
/

CREATE OR REPLACE PACKAGE chain.component_pkg
IS

/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 *
 * NOTE: Component types registered using this method cannot be editted in the UI. See next overload for more info.
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
);

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 * @param in_editor_card_group_id	The card group that handles editting of this type
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
);


/**********************************************************************************
	APP MANAGEMENT
**********************************************************************************/
/**
 * Activates this type for the session application
 *
 * @param in_type_id			The type of component to activate
 */
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
);

/**********************************************************************************/
/* Component sources are application level UI configurations that allow us to set */
/* specific text and help data in a ComponentSource card. 						  */
/*                                                       . 						  */

/**
 * Clears component source data
 */
PROCEDURE ClearSources;

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 *
 * NOTE: Component source data added using this method will be used for all card groups.
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
);

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 * @param in_card_group_id		The card group to include this source data for
 *
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
);

/**
 * Gets component sources for a specific card manager
 *
 * @param in_card_group_id			The id of the card group to collect that sources for
 * @returns							The source data cursor
 */
PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************/
/* Component type containment acts as both a UI helper and database ri for which  */
/* types of components can house other types.									  */
/* This is set at application level.				 . 						      */
/*                                                       . 						  */

/**
 * Clears component type containment for this application
 */
PROCEDURE ClearTypeContainment;

/**
 * Sets component type containment with UI helper flags for a single container/child pair
 *
 * @param in_container_type_id		The container component type
 * @param in_child_type_id			The child component type
 * @param in_allow_flags			See chain_pkg for valid allow flags
 *
 * NOTE: This method will ensure that ActivateType is called for both 
 *		 the container and child types.
 */
PROCEDURE SetTypeContainment (
	in_container_type_id	IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id		IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags			IN chain_pkg.T_FLAG
);

/**
 * Gets type containment data for output to the ui
 *
 * @returns							The containment data cursor
 */
PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateComponentAmountUnit (
	in_amount_unit_id		IN amount_unit.amount_unit_id%TYPE,
	in_description			IN amount_unit.description%TYPE
);

/**********************************************************************************
	UTILITY
**********************************************************************************/
/**
 * Checks if a component is of a specific type
 *
 * @param in_component_id			The id of the component to check
 * @param in_type_id				The presumed type
 * @returns							TRUE if the type matches, FALSE if not
 */
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN;

/**
 * Gets the owner company sid for given component id
 *
 * @param in_component_id			The id of the component
 * @returns							The company sid that owns the component
 */
FUNCTION GetCompanySid (
	in_component_id			IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Checks to see if a component is deleted
 *
 * @param in_component_id			The id of the component to check
 */
FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN;

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_id		The top id of the component in the tree
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
);

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_ids		The top ids of the components in the trees
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
);

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
/**
 * Gets the components types that are active in this application
 *
 * @returns							A cursor of (as above)
 */
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets the specific component type requested
 *
 * @param in_type_id				The specific component type to get
 * @returns							A cursor of (as above)
 */
PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
/**
 * Saves a component. If in_component_id <= 0, a new component is created.
 * If in_component_id > 0, the component is updated, provided that the type
 * passed in matches the expected type.
 *
 * @param in_component_id			The id (actual for existing, < 0 for new)
 * @param in_type_id				The type 
 * @param in_description			The description
 * @param in_component_code			The component code
 * @returns							The actual id of the component
 */
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE;

/**
 * Saves a component. If in_component_id <= 0, a new component is created.
 * If in_component_id > 0, the component is updated, provided that the type
 * passed in matches the expected type.
 *
 * @param in_component_id			The id (actual for existing, < 0 for new)
 * @param in_type_id				The type 
 * @param in_description			The description
 * @param in_component_code			The component code
 * @param in_component_notes		A field with notes about the component
 * @returns							The actual id of the component
 */
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE
) RETURN component.component_id%TYPE;

/**
 * Saves an amount and unit againt a component child / containser relationship. 
 *
 * @param in_parent_component_id		The id of the parent component
 * @param in_component_id				The id of the component
 * @param in_amount_child_per_parent	How much of the child is there in the parent (mass, %, etc...) 
 * @param in_amount_unit_id				The unit describing the amount
 */
PROCEDURE StoreComponentAmount (
	in_parent_component_id		IN component.component_id%TYPE,
	in_component_id		   		IN component.component_id%TYPE,
	in_amount_child_per_parent	IN component_relationship.amount_child_per_parent%TYPE,
	in_amount_unit_id			IN component_relationship.amount_unit_id%TYPE
);

/**
 * Marks a component as deleted
 *
 * @param in_component_id			The id of the component to delete
 */
PROCEDURE DeleteComponent (
	in_component_id			IN component.component_id%TYPE
);

/**
 * Gets basic component data by component id
 *
 * @param in_component_id			The id of the component to get
 * @returns							A cursor containing the basic component data
 */
PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Gets child component data of a specific type for a top_component
 *
 * @param in_top_component_id		The top component of the tree to get
 * @param in_type_id				The type of component that we're looking for
 * @returns							A cursor containing the component data
 *
 * NOTE: The type is passed in because we allow a single method to collect data
 * for more than one type of component. You must ensure that you only return
 * components of the requested type, as this method may be called again
 * using an alternate type
 */
PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets default (min at the moment) component amount unit for an app
 *
 * @param in_type_id				(not used atm) The type of component 
 * @returns							A cursor containing the component data
 */
PROCEDURE GetDefaultAmountUnit (
	out_amount_unit_id	OUT amount_unit.amount_unit_id%TYPE,
	out_amount_unit		OUT amount_unit.description%TYPE
);

/**
 * Searchs all components that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Searchs all components of a specific type that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @param in_of_type				The specific type to search for
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadComponentsPurchased (
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

/**
 * Attaches one component to another component
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Fully detaches a component from all container and child components
 *
 * @param in_component_id		The component id to detach
 */
PROCEDURE DetachComponent (
	in_component_id				IN component.component_id%TYPE	
);

/**
 * Detaches all child components from this component
 *
 * @param in_container_id			The component id to detach children from
 */
PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
);

/**
 * Detaches a specific container / child component pair
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Gets a table of all component ids that are children of the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE;

/**
 * Gets a table of all component ids that are children of the top component ids
 *
 * @param in_top_component_ids		An array of all top component ids to include
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE;


/**
 * Gets a heirarchy cursor of all parent id / component id relationships 
 * starting with the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns out_cur					The cursor (as above)
 */
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);
/**********************************************************************************
	GENERIC COMPONENT DOCUMENT UPLOAD SUPPORT
**********************************************************************************/

PROCEDURE GetComponentUploads(
	in_component_id					IN  chain.v$component.component_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AttachFileToComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID,
	in_key							IN 	component_document.key%TYPE
);

PROCEDURE DettachFileFromComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE DoUploaderComponentFiles (
	in_component_id					IN	component_document.component_id%TYPE,
	in_added_cache_keys				IN  chain_pkg.T_STRINGS,
	in_deleted_file_sids			IN  chain_pkg.T_NUMBERS,
	in_key							IN  chain.component_document.key%TYPE 
);

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/

/**
 * Changes a not sure component type into another component type
 *
 * @param in_component_id			The id of the not sure component to change
 * @param in_to_type_id				The type to change the component to
 * @returns out_cur					A cursor the basic component data
 */
PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END component_pkg;
/

CREATE OR REPLACE PACKAGE chain.dashboard_pkg
IS

PROCEDURE GetInvitationSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

END dashboard_pkg;
/


CREATE OR REPLACE PACKAGE chain.dev_pkg
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


CREATE OR REPLACE PACKAGE chain.filter_pkg
IS

-- SO PROCS
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
);

-- Registering Filters
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
);

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE;

-- Starting a filter session
PROCEDURE CreateCompoundFilter (
	out_compound_filter_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE SaveCompoundFilter (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_name						IN	compound_filter.name%TYPE
);

-- Filter item management
FUNCTION GetNextFilterId (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER;

PROCEDURE DeleteFilter (
	in_filter_id			IN	filter.filter_id%TYPE
);

PROCEDURE AddCardFilter (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
);

-- Filter field + value management. NB this is a generic version for use in helper_pkgs, but helper_pkgs can choose to store this information how they want
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
);

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
);

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetFieldValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

-- Running filters
PROCEDURE GetCompanySids (
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_results				OUT security.T_ORDERED_SID_TABLE
);

END filter_pkg;
/
CREATE OR REPLACE PACKAGE chain.helper_pkg
IS

TYPE T_NUMBER_ARRAY IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;

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

FUNCTION NumericArrayEmpty(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN NUMBER;

FUNCTION NumericArrayToTable(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN T_NUMERIC_TABLE;

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

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE RevertLogonUCD;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

FUNCTION Flag (
	in_flags				IN  chain_pkg.T_FLAG,
	in_flag					IN  chain_pkg.T_FLAG
) RETURN chain_pkg.T_FLAG;

FUNCTION GenerateSOName (
	in_company_name			IN  uninvited_supplier.name%TYPE,
	in_country_code			IN  uninvited_supplier.country_code%TYPE
) RETURN security_pkg.T_SO_NAME;


PROCEDURE UpdateSector (
	in_sector_id			IN	sector.sector_id%TYPE,
	in_description			IN	sector.description%TYPE
);

PROCEDURE DeleteSector (
	in_sector_id			IN	sector.sector_id%TYPE
);

PROCEDURE GetSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END helper_pkg;
/


CREATE OR REPLACE PACKAGE chain.invitation_pkg
IS

PROCEDURE AnnounceSids;

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

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
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
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD
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
	in_sent_dtm_from			IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to				IN	invitation.sent_dtm%TYPE,
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

PROCEDURE ReSendInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END invitation_pkg;
/


CREATE OR REPLACE PACKAGE chain.message_pkg
IS

/**********************************************************************************
	INTERNAL FUNCTIONS
	
	These methods should not be widely used and are provided publicly for setup convenience
**********************************************************************************/

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;


/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Creates or updates a message
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	The template text to use
 * @param in_repeat_type		Defines how create the message in the event that it already exists
 * @param in_priority			The priority of the message
 * @param in_addressing_type	Defines who the message should be delivered to
 * @param in_completion_type	Defines the method that will be used to complete this message
 * @param in_completed_template	Additional information to display once the message is marked as completed
 * @param in_helper_pkg			The pkg that will be called when this message is opened or completed
 * @param in_css_class			The css class that wraps the message
 */
PROCEDURE DefineMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE,
	in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
	in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
	in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
);

/**
 * Creates or updates a message parameter
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			The css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				The href for a link. Links are not used if this is null
 * @param in_value				The innerHTML of the link (if href is not null) or span
 *
 * NOTES:
 * 	1. top level template parameters are essentially xtemplate formatted as:
 *
 *		{paramName}->{paramName:OPEN}{paramName:VALUE}{paramName:CLOSE}
 *
 *		{paramName:OPEN} -> <span class="{cssClass}">
 *								<tpl if="href">
 *									<a href="{href}">
 *								</tpl>
 *						
 *		{paramName:VALUE} ->	{value}
 *
 *		{paramName:CLOSE} -> 	<tpl if="href">
 *									</a>
 *								</tpl>
 *							</span>
 *
 * 	2. subsequent level parameters are formatted using:
 *		
 *		{paramName} -> {value}
 *
 * This allows us to keep translations in-line in the template, but still use single parameter definitions as needed.
 */
PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL	
);


/**********************************************************************************
	APPLICATION MANAGEMENT
	
	These methods act on data at an application level
**********************************************************************************/

/**
 * Creates or updates an application level message override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	Overrides the template text to use
 * @param in_priority			Overrides the priority of the message
 * @param in_addressing_type	Overrides who the message should be delivered to
 * @param in_completed_template	Overrides additional information to display once the message is marked as completed
 * @param in_helper_pkg			Overrides the pkg that will be called when this message is opened or completed
 * @param in_css_class			Overrides the css class that wraps the message
 */
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
);

/**
 * Creates or updates an application level message parameter override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			Overrides the css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				Overrides the href for a link. Links are not used if this is null
 * @param in_value				Overrides the innerHTML of the link (if href is not null) or span
 *
 * NOTE: See above for notes on how parameters are applied
 */
PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
);

/**********************************************************************************
	COMMON METHODS
	
	These are the core methods for sending a message
**********************************************************************************/

/**
 * Creates a recipient box for the company_sid, user_sid combination
 *
 * @param in_company_sid		The company_sid to create the box for
 * @param in_user_sid			The user_sid to create the box for
 * @return recipient_id			The new recipient id
 */
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE;

/**
 * Triggers a message (triggering is determined by the message definition repeate type)
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 * @param in_due_dtm			A timestamp that will be used in the notes of the message.
 *
 *	NOTE: the in_due_dtm is only used as a visual aid for the user, and DOES NOT
 *		automatically trigger additional notifications if passed without completion.
 */
PROCEDURE TriggerMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_due_dtm					IN  message.due_dtm%TYPE						DEFAULT NULL
);

/**
 * Completes a message if it is completable and is not already completed. Raises an error if it is not found
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
PROCEDURE CompleteMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
);

/**
 * Completes a message if it is completable and is not already completed but will not raise an error if it is not found
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
PROCEDURE CompleteMessageIfExists (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
);

/**
 * Completes a message if it is completable and is not already completed
 *
 * @param in_message_id			The id of the message to complete
 */
PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
);

/**
 * Finds the most recent message which matches the parameters provided. 
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
FUNCTION FindMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE;

/**
 * Gets all messages for the current user, current company
 *
 * @param in_to_company_sid				The company to get the messages for
 * @param in_to_user_sid				The user to get the messages for
 * @param in_filter_for_priority		Set to non-zero to get remove messages that are needing completion, grouped by the highest priority
 * @param in_filter_for_pure_messages	Set to non-zero to get remove messages that are not needing completion
 * @param in_page_size					The page size - 0 to get all
 * @param in_page						The page number (ignored if page_size is 0)
 * @param out_stats_cur					The stats used for paging
 * @param out_message_cur				The message details
 * @param out_message_param_cur			The message definition parameters
 * @param out_company_cur				Companies that are involved in these messages
 * @param out_user_cur					Users that are involved in these messages
 * @param out_questionnaire_type_cur	Questionnaire types that are involved in these messages
 * @param out_component_cur				Components that are involved in these messages
 */
PROCEDURE GetMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_filter_for_priority		IN  NUMBER,
	in_filter_for_pure_messages	IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_page						IN  NUMBER,	
	out_stats_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets a message by id
 *
 * @param in_message_id			The id of the message to retrieve
 */
FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE;


END message_pkg;
/


CREATE OR REPLACE PACKAGE chain.metric_pkg
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


CREATE OR REPLACE PACKAGE chain.newsflash_pkg
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

CREATE OR REPLACE PACKAGE chain.product_pkg
IS

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE,
    in_notes				IN  product.notes%TYPE
) RETURN NUMBER;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE PublishProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE EditProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_only_show_unpublished	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_code_label1					IN  product_code_type.code_label1%TYPE,
	in_code_label2					IN  product_code_type.code_label2%TYPE,
	in_code_label3					IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory				IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory				IN 	product_code_type.code3_mandatory%TYPE,
	out_products_with_empty_codes	OUT NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetNonEmptyProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
);

PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
);

PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
);

PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
);

FUNCTION HasMappedUnpublishedProducts (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

END product_pkg;
/

CREATE OR REPLACE PACKAGE chain.product_report_pkg AS

PROCEDURE SupplySummary (
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

END product_report_pkg;
/

CREATE OR REPLACE PACKAGE chain.purchased_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
);

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE GetPurchaseChannels (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_product_id			purchase.product_id%TYPE,
	in_start_date			purchase.start_date%TYPE,
	in_end_date				purchase.end_date%TYPE,
	in_invoice_number		purchase.invoice_number%TYPE,
	in_purchase_order		purchase.purchase_order%TYPE,
	in_note					purchase.note%TYPE,
	in_amount				purchase.amount%TYPE,
	in_amount_unit_id		purchase.amount_unit_id%TYPE,
	in_purchase_channel_id	purchase.purchase_channel_id%TYPE
);

PROCEDURE SearchPurchases (
	in_product_id		IN	purchase.product_id%TYPE,
	in_start			IN	NUMBER,
	in_count			IN	NUMBER,
	out_total			OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadPurchases (
	in_product_id		IN	purchase.product_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeletePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_product_id			purchase.product_id%TYPE
);

END purchased_component_pkg;
/

CREATE OR REPLACE PACKAGE chain.questionnaire_pkg
IS

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

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
);

FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

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

PROCEDURE HideQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
);

FUNCTION IsQuestionnaireTypeVisible (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER;

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

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);

END questionnaire_pkg;
/

CREATE OR REPLACE PACKAGE chain.report_pkg
IS

PROCEDURE FilterExport(
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
);

END report_pkg;
/


CREATE OR REPLACE PACKAGE chain.scheduled_alert_pkg
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


CREATE OR REPLACE PACKAGE chain.task_pkg
IS

TASK_ACTION_REMOVE 		CONSTANT NUMBER := 1;
TASK_ACTION_ADD			CONSTANT NUMBER := 2;

PROCEDURE RegisterScheme (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,	
	in_description				IN  task_scheme.description%TYPE,
	in_db_class					IN  task_scheme.db_class%TYPE
);

PROCEDURE RegisterTaskType (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_name						IN  task_type.name%TYPE,
	in_parent_name				IN  task_type.name%TYPE DEFAULT NULL,
	in_description				IN  task_type.description%TYPE,
	in_default_status			IN  chain_pkg.T_TASK_STATUS DEFAULT chain_pkg.TASK_HIDDEN,
	in_db_class					IN  task_type.db_class%TYPE DEFAULT NULL,
	in_due_in_days				IN  task_type.due_in_days%TYPE DEFAULT NULL,
	in_mandatory				IN  task_type.mandatory%TYPE DEFAULT chain_pkg.INACTIVE,
	in_due_date_editable		IN  task_type.due_date_editable%TYPE DEFAULT chain_pkg.ACTIVE,
	in_review_every_n_days		IN  task_type.review_every_n_days%TYPE DEFAULT NULL,
	in_card_id					IN  task_type.card_id%TYPE DEFAULT NULL,
	in_invert_actions			IN  BOOLEAN DEFAULT TRUE,
	in_on_action				IN  T_TASK_ACTION_LIST DEFAULT NULL
);

PROCEDURE SetChildTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_parent_name				IN  task_type.name%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
);

PROCEDURE CopyTaskTypeBranch (
	in_from_scheme_id			IN  task_type.task_scheme_id%TYPE,	
	in_to_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_from_name				IN  task_type.name%TYPE
);

FUNCTION GetTaskTypeId (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task_type.task_type_id%TYPE;

FUNCTION GetParentTaskTypeId (
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_type_id%TYPE;

FUNCTION GetParentTaskId (
	in_task_id					IN  task.task_id%TYPE
) RETURN task.task_type_id%TYPE;

FUNCTION GetTaskId (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE	
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE	
) RETURN task.task_id%TYPE;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task.task_id%TYPE;

FUNCTION GetTaskName (
	in_task_id					IN  task.task_id%TYPE
) RETURN task_type.name%TYPE;

FUNCTION GetTaskEntryName (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task_type.name%TYPE;

FUNCTION AddSimpleTask (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE
) RETURN task.task_id%TYPE;


PROCEDURE ProcessTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
);

PROCEDURE ProcessTaskScheme (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE
);

PROCEDURE StartScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_name			IN  task_type.name%TYPE DEFAULT NULL
);

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ChangeTaskStatus (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

/*** THIS PROCEDURE SHOULD ONLY BE USED WHEN YOU CAN AND WILL MANUALLY MANAGE THE CASCADE CHANGES MANUALL ***/
PROCEDURE ChangeTaskStatusNoCascade (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
);

FUNCTION GetTaskStatus (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE
) RETURN task.task_status_id%TYPE;

FUNCTION GetTaskStatus (
	in_task_id					IN	task.task_id%TYPE
) RETURN task.task_status_id%TYPE;

PROCEDURE SetTaskDueDate (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
);

PROCEDURE SetTaskDueDate (
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
);

PROCEDURE GetFlattenedTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateTask (
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date			IN	date,
	in_due_date					IN	date
);

PROCEDURE GetTaskSummary (
	in_task_scheme_id	IN	task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyActiveCompaniesByTaskType (
	in_task_type_id				IN task_type.task_type_id%TYPE,
	in_days_from				IN NUMBER,
	in_days_to					IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetActiveTasksForUser (
	in_user_sid					IN 	security_pkg.T_SID_ID,
	in_task_scheme_ids			IN	helper_pkg.T_NUMBER_ARRAY,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_count					OUT	NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE
);

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE
);

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteTaskFile (
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION HasEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name				IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE,
	in_entry_name_three			IN  task_entry.name%TYPE
) RETURN BOOLEAN;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_names				IN  T_STRING_LIST
) RETURN BOOLEAN;

PROCEDURE GetTaskCardManagerData (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_manager_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_type_card_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE MapTaskInvitationQnrType (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_include_children			IN  NUMBER
);

PROCEDURE GetInvitationTaskCardData (
	in_task_id				IN  task.task_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateTasksForReview;


END task_pkg;
/

CREATE OR REPLACE PACKAGE chain.uninvited_pkg
IS
-- Securable object callbacks
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
-- END Securable object callbacks

FUNCTION IsUninvitedSupplier (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsUninvitedSupplier (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION SupplierExists (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN NUMBER;


PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE CreateUninvited (
	in_name						IN	uninvited_supplier.name%TYPE,
	in_country_code				IN	uninvited_supplier.country_code%TYPE,
	out_uninvited_supplier_sid	OUT security_pkg.T_SID_ID
);

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION HasUninvitedSupsWithComponents (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


END uninvited_pkg;
/
CREATE OR REPLACE PACKAGE chain.upload_pkg
IS

PROCEDURE CreateObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_class_id					IN  security_pkg.T_CLASS_ID,
	in_name						IN  security_pkg.T_SO_NAME,
	in_parent_sid_id			IN  security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_name					IN  security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID
); 

PROCEDURE MoveObject(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_sid_id					IN  security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN  security_pkg.T_SID_ID
); 

PROCEDURE CreateFileUploadFromCache(		  
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_file_sid				OUT	security_pkg.T_SID_ID
);

FUNCTION IsChainUpload(
	in_file_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


PROCEDURE GetFile(
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE;

PROCEDURE GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteFile (
	in_file_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE RegisterGroup (
	in_guid						IN  file_group.guid%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_title					IN  file_group.title%TYPE,
	in_description				IN  file_group.description%TYPE,
	in_group_model				IN  chain_pkg.T_FILE_GROUP_MODEL,
	in_download_permission 		IN  chain_pkg.T_DOWNLOAD_PERMISSION
);
	
PROCEDURE SecureGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetDefaultGroupFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE SetGroupPermission (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
);

PROCEDURE SetFilePermission (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
);

PROCEDURE SetFileLang (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_lang						IN  file_upload.lang%TYPE
);

PROCEDURE GetGroups (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGroupsForLang (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetGroupId (
	in_guid						IN  file_group.guid%TYPE
) RETURN file_group.file_group_id%TYPE;

PROCEDURE SetGroupDefaultFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
);


--TODO: Add a proc for getting a file given a cache key that will take from cache if it hasn't
--      been saved yet or from upload table - this can then be shared between sourcing and wood
--      Will need to add a cache_key column to file_upload
-- edit (casey): you could use Chain.panel.UploadedFiles instead - it does everything that you need to

END upload_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.alert_helper_pkg
IS


PROCEDURE GetPartialTemplates (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	out_partial_cur					OUT	SYS_REFCURSOR,
	out_params_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing partial templates');
    END IF;
	
	OPEN out_partial_cur FOR
		SELECT *
		  FROM alert_partial_template
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_type_id = in_alert_type_id
		   AND lang = in_lang;
	
	OPEN out_params_cur FOR
		SELECT *
		  FROM alert_partial_template_param
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND alert_type_id = in_alert_type_id;
END;

PROCEDURE SavePartialTemplate (
	in_alert_type_id				IN	alert_partial_template.alert_type_id%TYPE,
	in_lang							IN	alert_partial_template.lang%TYPE,
	in_partial_template_type_id		IN	alert_partial_template.partial_template_type_id%TYPE,
	in_partial_html					IN	alert_partial_template.partial_html%TYPE,
	in_params						IN	T_STRING_LIST
)
AS
BEGIN

	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SavePartialTemplate can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO alert_partial_template
			(alert_type_id, lang, partial_template_type_id, partial_html)
		VALUES
			(in_alert_type_id, in_lang, in_partial_template_type_id, in_partial_html);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE alert_partial_template
			   SET partial_html=in_partial_html
			 WHERE app_sid=SYS_CONTEXT('SECURITY', 'APP')
			   AND alert_type_id=in_alert_type_id
			   AND lang=in_lang
			   AND partial_template_type_id=in_partial_template_type_id;
	END;
	
	
	-- Remove all and add again - safe to do at the moment as nothing references the params table
	-- Also runs for each language which isn't v efficient or clever but is simpler and I think
	-- it's justified when we only have one client that will be using this and we'll need to run
	-- a script to change their default partial templates
	DELETE FROM alert_partial_template_param
	 WHERE app_sid=SYS_CONTEXT('SECURITY', 'APP')
	   AND alert_type_id=in_alert_type_id
	   AND partial_template_type_id=in_partial_template_type_id;
	
	FOR i IN in_params.FIRST .. in_params.LAST
	LOOP
		INSERT INTO alert_partial_template_param (alert_type_id, partial_template_type_id, field_name)
		VALUES (in_alert_type_id, in_partial_template_type_id, in_params(i));
	END LOOP;
	
END;

END alert_helper_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.capability_pkg
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
	IF helper_pkg.IsElevatedAccount THEN
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

PROCEDURE SetCapabilityHidden (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_hide					IN  BOOLEAN
)
AS
	v_gc_id					group_capability.group_capability_id%TYPE;
	v_state					group_capability_override.hide_group_capability%TYPE;
	v_perm_set_override		group_capability_override.permission_set_override%TYPE;
BEGIN
	GetGroupCapabilityId(in_capability_type, in_capability, in_group, v_gc_id);
	
	BEGIN
		SELECT permission_set_override
		  INTO v_perm_set_override
		  FROM group_capability_override
		 WHERE group_capability_id = v_gc_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_perm_set_override := NULL;
	END;
	
	IF NOT in_hide AND v_perm_set_override IS NULL THEN
		-- just delete the entry
		DELETE FROM group_capability_override
		 WHERE group_capability_id = v_gc_id;
		
		RETURN;
	END IF;
	
	IF in_hide THEN
		v_state := chain_pkg.ACTIVE;
	ELSE
		v_state := chain_pkg.INACTIVE;
	END IF;
	
	BEGIN
        INSERT INTO group_capability_override
        (group_capability_id, hide_group_capability)
        VALUES
        (v_gc_id, v_state);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE group_capability_override
			   SET hide_group_capability = v_state
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
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type);

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
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideCapability can only be run as BuiltIn/Administrator');
	END IF;	
	
	SetCapabilityHidden(in_capability_type, in_capability, in_group, TRUE);
END;

PROCEDURE UnhideCapability (
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF IsCommonCapability(in_capability) THEN
		UnhideCapability(chain_pkg.CT_COMMON, in_capability, in_group);
	ELSE
		UnhideCapability(chain_pkg.CT_COMPANY, in_capability, in_group);
		UnhideCapability(chain_pkg.CT_SUPPLIERS, in_capability, in_group);
	END IF;
END;

PROCEDURE UnhideCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'UnhideCapability can only be run as BuiltIn/Administrator');
	END IF;	

	SetCapabilityHidden(in_capability_type, in_capability, in_group, FALSE);
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

CREATE OR REPLACE PACKAGE BODY chain.card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';

PROCEDURE DumpCard (
	in_js_class				IN  card.js_class_type%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpCard can only be run as BuiltIn/Administrator');
	END IF;

	DumpCards(T_STRING_LIST(in_js_class));
END;

PROCEDURE DumpCards (
	in_js_classes			IN  T_STRING_LIST
)
AS
	v_actions				VARCHAR2(4000);
	v_sep					VARCHAR2(2);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpCards can only be run as BuiltIn/Administrator');
	END IF;
	
	dbms_output.put_line('DECLARE');
	dbms_output.put_line('    v_card_id         card.card_id%TYPE;');
	dbms_output.put_line('    v_desc            card.description%TYPE;');
	dbms_output.put_line('    v_class           card.class_type%TYPE;');
	dbms_output.put_line('    v_js_path         card.js_include%TYPE;');
	dbms_output.put_line('    v_js_class        card.js_class_type%TYPE;');
	dbms_output.put_line('    v_css_path        card.css_include%TYPE;');
	dbms_output.put_line('    v_actions         T_STRING_LIST;');
	dbms_output.put_line('BEGIN');

	
	FOR i IN in_js_classes.FIRST .. in_js_classes.LAST
	LOOP
		FOR c IN (
			SELECT *
			  FROM card
			 WHERE js_class_type = in_js_classes(i)
		) LOOP
			v_actions := '';
			v_sep := '';

			FOR a IN (
				SELECT * 
				  FROM card_progression_action
				 WHERE card_id = c.card_id
			) LOOP
					v_actions := v_actions || v_sep || '''' || a.ACTION || '''';
					v_sep := ',';
			END LOOP;
			
			dbms_output.put_line('    -- '||c.js_class_type);
			dbms_output.put_line('    v_desc := '''||c.description||''';');
			dbms_output.put_line('    v_class := '''||c.class_type||''';');
			dbms_output.put_line('    v_js_path := '''||c.js_include||''';');
			dbms_output.put_line('    v_js_class := '''||c.js_class_type||''';');
			dbms_output.put_line('    v_css_path := '''||c.css_include||''';');
			dbms_output.put_line('    ');
			dbms_output.put_line('    BEGIN');
			dbms_output.put_line('        INSERT INTO card (card_id, description, class_type, js_include, js_class_type, css_include)');
			dbms_output.put_line('        VALUES (card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)');
			dbms_output.put_line('        RETURNING card_id INTO v_card_id;');
			dbms_output.put_line('    EXCEPTION ');
			dbms_output.put_line('        WHEN DUP_VAL_ON_INDEX THEN');
			dbms_output.put_line('            UPDATE card ');
			dbms_output.put_line('               SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path');
			dbms_output.put_line('             WHERE js_class_type = v_js_class');
			dbms_output.put_line('         RETURNING card_id INTO v_card_id;');
			dbms_output.put_line('    END;');
			dbms_output.put_line('    ');
			dbms_output.put_line('    DELETE FROM card_progression_action ');
			dbms_output.put_line('     WHERE card_id = v_card_id ');
			dbms_output.put_line('       AND action NOT IN ('||v_actions||');');
			dbms_output.put_line('    ');
			dbms_output.put_line('    v_actions := T_STRING_LIST('||v_actions||');');			
			dbms_output.put_line('    ');
			dbms_output.put_line('    FOR i IN v_actions.FIRST .. v_actions.LAST');
			dbms_output.put_line('    LOOP');
			dbms_output.put_line('        BEGIN');
			dbms_output.put_line('            INSERT INTO card_progression_action (card_id, action)');
			dbms_output.put_line('            VALUES (v_card_id, v_actions(i));');
			dbms_output.put_line('        EXCEPTION ');
			dbms_output.put_line('            WHEN DUP_VAL_ON_INDEX THEN');
			dbms_output.put_line('                NULL;');
			dbms_output.put_line('        END;');
			dbms_output.put_line('    END LOOP;');
			dbms_output.put_line('    ');
		END LOOP;
	END LOOP;
	
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
END;

PROCEDURE DumpGroup (
	in_group_name			IN  card_group.name%TYPE,
	in_host					IN  v$chain_host.host%TYPE
)
AS
	v_card_group_id			card_group.card_group_id%TYPE;
	v_card_group_name		card_group.name%TYPE;
	v_card_group_desc		card_group.description%TYPE;
	v_app_sid				security_pkg.T_SID_ID;
	v_chain_implementation  v$chain_host.chain_implementation%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DumpGroup can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		SELECT card_group_id, name, description
		  INTO v_card_group_id, v_card_group_name, v_card_group_desc
		  FROM card_group
		 WHERE LOWER(name) = LOWER(in_group_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = '''||in_group_name||'''');
	END;
	
	SELECT app_sid, chain_implementation
	  INTO v_app_sid, v_chain_implementation
	  FROM v$chain_host
	 WHERE LOWER(host) = LOWER(in_host);
	
	dbms_output.put_line('-- '||in_group_name||' (copied from '||in_host||')');
	dbms_output.put_line('BEGIN');
	dbms_output.put_line('    INSERT INTO card_group(card_group_id, name, description)');
	dbms_output.put_line('    VALUES('||v_card_group_id||', '''||v_card_group_name||''', '''||replace(v_card_group_desc, '''', '''''')||''');');
	dbms_output.put_line('EXCEPTION');
	dbms_output.put_line('    WHEN DUP_VAL_ON_INDEX THEN');
	dbms_output.put_line('        UPDATE card_group');
	dbms_output.put_line('           SET description='''||replace(v_card_group_desc, '''', '''''')||'''');
	dbms_output.put_line('         WHERE card_group_id='||v_card_group_id||';');
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
	dbms_output.put_line('');
	dbms_output.put_line('DECLARE');
	dbms_output.put_line('    v_card_group_id			card_group.card_group_id%TYPE DEFAULT '||v_card_group_id||';');
	dbms_output.put_line('    v_position				NUMBER(10) DEFAULT 1;');
	dbms_output.put_line('BEGIN');
	dbms_output.put_line('    ');
	dbms_output.put_line('    -- clear the app_sid');
	dbms_output.put_line('    user_pkg.logonadmin;');
	dbms_output.put_line('    ');
	dbms_output.put_line('    FOR r IN (');
	dbms_output.put_line('        SELECT host FROM v$chain_host WHERE chain_implementation = '''||v_chain_implementation||'''');
	dbms_output.put_line('    ) LOOP');
	dbms_output.put_line('        ');
	dbms_output.put_line('        user_pkg.logonadmin(r.host);');
	dbms_output.put_line('        ');
	dbms_output.put_line('        DELETE FROM card_group_progression');
	dbms_output.put_line('         WHERE app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')');
	dbms_output.put_line('           AND card_group_id = v_card_group_id;');
	dbms_output.put_line('        ');
	dbms_output.put_line('        DELETE FROM card_group_card');
	dbms_output.put_line('         WHERE app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')');
	dbms_output.put_line('           AND card_group_id = v_card_group_id;');
	dbms_output.put_line('        ');
	FOR r IN (
		SELECT c.js_class_type, cgc.position, c.card_id, cgc.required_permission_set, cgc.invert_capability_check, cgc.force_terminate,
				cap.capability_name, cap.capability_type_id
		  FROM card_group_card cgc
		  JOIN card c ON cgc.card_id = c.card_id
		  LEFT JOIN capability cap ON cgc.required_capability_id=cap.capability_id
		 WHERE cgc.app_sid = v_app_sid
		   AND cgc.card_group_id = v_card_group_id
		 ORDER BY cgc.position
	) LOOP
		dbms_output.put_line('        INSERT INTO card_group_card (card_group_id, card_id, position, required_permission_set,');
		dbms_output.put_line('               invert_capability_check, force_terminate, required_capability_id)');
		IF r.capability_name IS NULL THEN
			dbms_output.put_line('            SELECT v_card_group_id, card_id, v_position, '||NVL(CAST(r.required_permission_set as nvarchar2),'NULL')||', '||
								r.invert_capability_check||', '||r.force_terminate||', NULL');
			dbms_output.put_line('              FROM card');
			dbms_output.put_line('             WHERE js_class_type = '''||r.js_class_type||''';');
		ELSE
			dbms_output.put_line('            SELECT v_card_group_id, card_id, v_position, '||NVL(CAST(r.required_permission_set as nvarchar2),'NULL')||', '||
								r.invert_capability_check||', '||r.force_terminate||', capability_id');
			dbms_output.put_line('              FROM card, capability');
			dbms_output.put_line('             WHERE js_class_type = '''||r.js_class_type||'''');
			dbms_output.put_line('               AND capability_name = '''||r.capability_name||'''');
			dbms_output.put_line('               AND capability_type_id = '||r.capability_type_id||';');
		END IF;
		dbms_output.put_line('        ');
		dbms_output.put_line('        v_position := v_position + 1;');
		dbms_output.put_line('        ');
	END LOOP;
	
	FOR pa IN (
		SELECT f.js_class_type from_js_class_type, t.js_class_type to_js_class_type, p.from_card_action
		  FROM card_group_progression p
		  JOIN card f ON p.from_card_id = f.card_id
		  JOIN card t ON p.to_card_id = t.card_id
		 WHERE p.card_group_id = v_card_group_id
		   AND p.app_sid = v_app_sid
	) LOOP
		dbms_output.put_line('        INSERT INTO card_group_progression');
		dbms_output.put_line('        (card_group_id, from_card_id, from_card_action, to_card_id)');
		dbms_output.put_line('        SELECT v_card_group_id, f.card_id, '''||pa.from_card_action||''', t.card_id');
		dbms_output.put_line('          FROM card f, card t');
		dbms_output.put_line('         WHERE f.js_class_type = '''||pa.from_js_class_type||'''');
		dbms_output.put_line('           AND t.js_class_type = '''||pa.to_js_class_type||''';');
		dbms_output.put_line('        ');
	END LOOP;

	
	dbms_output.put_line('    END LOOP;');
	dbms_output.put_line('    ');
	dbms_output.put_line('    -- clear the app_sid');
	dbms_output.put_line('    user_pkg.logonadmin;');
	dbms_output.put_line('    ');
	dbms_output.put_line('END;');
	dbms_output.put_line('/');
END;

/*******************************************************************
	Private
*******************************************************************/
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
	
	CollectManagerData(in_card_group_id, v_cards_to_use, out_manager_cur, out_card_cur, out_progression_cur);
END;

PROCEDURE CollectManagerData (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	in_cards_to_use			IN  security.T_SID_TABLE,
	out_manager_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
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
		   AND cg.card_id IN (SELECT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		 ORDER BY position;

	-- get the progression data
	OPEN out_progression_cur FOR
		SELECT fc.js_class_type from_js_class_type, cgp.from_card_action, tc.js_class_type to_js_class_type
		  FROM card_group_progression cgp, card fc, card tc
		 WHERE cgp.app_sid = security_pkg.GetApp
		   AND cgp.card_group_id = in_card_group_id
		   AND cgp.from_card_id IN (SELECT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		   AND cgp.to_card_id IN (SELECT COLUMN_VALUE FROM TABLE(in_cards_to_use))
		   AND cgp.from_card_id = fc.card_id
		   AND cgp.to_card_id = tc.card_id
		 ORDER BY fc.card_id;
END;


END card_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.chain_pkg
IS
/********************************************************

	DO NOT ADD METHODS HERE - THIS PKG BODY SHOULD 
	BE KEPT EMPTY TO HELP PREVENT BREAKS IN UPDATE
	SCRIPTS. THE PKG HEADER SHOULD ONLY CONTAIN
	CHAIN CONSTANTS, AND NOT REFERENCE TABLES OR
	OTHER SCHEMAS (except security).

********************************************************/
-- TEMP: back in until scheduler gets fixed up
PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

END chain_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.chain_link_pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

/******************************************************************
	PRIVATE WORKER METHODS
******************************************************************/
FUNCTION GetGlobalLinkPkg
RETURN customer_options.company_helper_sp%TYPE
AS
	v_helper_pkg		customer_options.company_helper_sp%TYPE;
BEGIN
	BEGIN
		SELECT company_helper_sp
		  INTO v_helper_pkg 
		  FROM customer_options co
		 WHERE app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_helper_pkg;
END;

FUNCTION GetQuestionnaireLinkPkg (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE
)
RETURN customer_options.company_helper_sp%TYPE
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE;
BEGIN
	BEGIN
		SELECT db_class
		  INTO v_helper_pkg
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND questionnaire_id = in_questionnaire_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_helper_pkg;
END;


PROCEDURE ExecuteProcedure (
	in_helper_pkg				IN  customer_options.company_helper_sp%TYPE,
	in_proc_call				IN  VARCHAR2
)
AS
BEGIN
	IF in_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || in_helper_pkg || '.' || in_proc_call || ';END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE ExecuteProcedure (
	in_proc_call				IN  VARCHAR2
)
AS
BEGIN
	ExecuteProcedure(GetGlobalLinkPkg, in_proc_call);
END;


FUNCTION ExecuteFuncReturnNumber (
	in_helper_pkg				IN  customer_options.company_helper_sp%TYPE,
	in_func_call				IN  VARCHAR2
) RETURN NUMBER
AS
	v_result					NUMBER(10);
BEGIN
	IF in_helper_pkg IS NOT NULL THEN
		BEGIN
			EXECUTE IMMEDIATE
				'BEGIN :result := ' || in_helper_pkg || '.' || in_func_call || ';END;'
			USING OUT v_result;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	RETURN v_result;
END;

FUNCTION ExecuteFuncReturnNumber (
	in_func_call				IN  VARCHAR2
) RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFuncReturnNumber(GetGlobalLinkPkg, in_func_call);
END;

PROCEDURE ExecuteMessageProcedure (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_proc						IN  VARCHAR2,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteProcedure(in_helper_pkg, in_proc||'('||in_to_company_sid||','||in_message_id||')');
END;


/******************************************************************
	PUBLIC IMPLEMENTATION CALLS
******************************************************************/
PROCEDURE AddCompanyUser (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('AddCompanyUser(' || in_company_sid || ', ' || 
									in_user_sid || ')');
END;

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('AddCompany(' || in_company_sid || ')');
END;

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('DeleteCompany(' || in_company_sid || ')');
END;

PROCEDURE UpdateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('UpdateCompany(' || in_company_sid || ')');
END;

PROCEDURE DeleteUpload (
	in_upload_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('DeleteUpload(' || in_upload_sid || ')');
END;

PROCEDURE InviteCreated (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('InviteCreated(' || in_invitation_id || ', ' ||
									in_from_company_sid || ', ' ||
									in_to_company_sid || ', ' ||
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
	ExecuteProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id), 
		'QuestionnaireAdded(' || in_from_company_sid || ', ' ||
								 in_to_company_sid || ', ' ||
								 in_to_user_sid || ', ' ||
								 in_questionnaire_id || ')');
END;

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateCompany(' || in_company_sid || ')');
END;


PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateUser(' || in_user_sid || ')');
END;


PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ApproveUser(' || in_company_sid || ', ' ||
									in_user_sid || ')');
END;

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateRelationship(' || in_purchaser_company_sid || ', ' ||
												in_supplier_company_sid || ')');
END;

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE;
	/*
		For some reason, if you pass out_titles in to the execute immediate statement
		it barfs on linux with an invalid cursor exception when returning the cursor
		to the webserver, although it works fine on Win7 x64.
		The solution appears to be declaring another cursor locally, assigning it to
		that and then passing it back out
	*/
	c_titles					security_pkg.T_OUTPUT_CUR;
BEGIN
	v_helper_pkg := GetGlobalLinkPkg;
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
				'BEGIN ' || v_helper_pkg || '.GetWizardTitles(:card_group,:out_titles);END;'
			) USING in_card_group_id, c_titles;
			
			out_titles := c_titles;
			
			RETURN;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
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
	ExecuteProcedure('AddProduct(' || in_product_id || ')');
END;

PROCEDURE KillProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	ExecuteProcedure('KillProduct(' || in_product_id || ')');
END;

PROCEDURE FilterComponentTypeContainment
AS
BEGIN
	ExecuteProcedure('FilterComponentTypeContainment()');
END;

FUNCTION FindMessageRecipient (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
) RETURN recipient.recipient_id%TYPE
AS
BEGIN
	RETURN ExecuteFuncReturnNumber('FindMessageRecipient('||
					in_message_id 	|| ', ' ||
					in_company_sid 	|| ', ' ||
					in_user_sid 	|| ') ');
END;

PROCEDURE MessageRefreshed (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageRefreshed', in_to_company_sid, in_message_id);
END;

PROCEDURE MessageCreated (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageCreated', in_to_company_sid, in_message_id);
END;


PROCEDURE MessageCompleted (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageCompleted', in_to_company_sid, in_message_id);
END;

PROCEDURE InvitationAccepted (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('InvitationAccepted('|| 
						in_invitation_id || ', ' ||
						in_from_company_sid || ', ' ||
						in_to_company_sid ||
					')');	
END;

PROCEDURE InvitationRejected (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
)
AS
BEGIN
	ExecuteProcedure('InvitationRejected('|| 
						in_invitation_id || ', ' ||
						in_from_company_sid || ', ' ||
						in_to_company_sid || ', ' ||
						in_reason || 
					')');	
END;

PROCEDURE InvitationExpired (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('InvitationExpired('|| 
						in_invitation_id || ', ' ||
						in_from_company_sid || ', ' ||
						in_to_company_sid ||
					')');	
END;

FUNCTION GetTaskSchemeId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN task_scheme.task_scheme_id%TYPE
AS
BEGIN
	RETURN ExecuteFuncReturnNumber('GetTaskSchemeId('||in_owner_company_sid||', '||in_supplier_company_sid||')');
END;

PROCEDURE TaskStatusChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN  chain_pkg.T_TASK_STATUS
)
AS
	v_db_class					task_type.db_class%TYPE;
BEGIN
	SELECT tt.db_class
	  INTO v_db_class
	  FROM task_type tt, task t
	 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tt.app_sid = t.app_sid
	   AND tt.task_type_id = t.task_type_id
	   AND t.task_id = in_task_id;
	
	IF v_db_class IS NOT NULL THEN
		ExecuteProcedure(v_db_class, 'TaskStatusChanged('||in_task_change_id||', '||in_task_id||', '||in_status_id||')');
	END IF;
END;

PROCEDURE TaskEntryChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
)
AS
	v_db_class					task_type.db_class%TYPE;
BEGIN
	SELECT tt.db_class
	  INTO v_db_class
	  FROM task_type tt, task t, task_entry te
	 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND tt.app_sid = t.app_sid
	   AND tt.app_sid = te.app_sid
	   AND tt.task_type_id = t.task_type_id
	   AND t.task_id = te.task_id
	   AND te.task_entry_id = in_task_entry_id;
	
	IF v_db_class IS NOT NULL THEN
		ExecuteProcedure(v_db_class, 'TaskEntryChanged('||in_task_change_id||', '||in_task_entry_id||')');
	END IF;
END;

END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.company_pkg
IS

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/

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
	
			RETURN helper_pkg.GenerateSOName(out_company_name, out_country_code) = in_name;
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
	v_filters_sid			security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
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
	
	-- FILTERS CONTAINER
	BEGIN
		v_filters_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_FILTERS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_FILTERS, v_filters_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_filters_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- UNINVITED SUPPLIERS CONTAINER
	BEGIN
		v_uninvited_sups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.UNINVITED_SUPPLIERS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
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
		 	 			 ORDER BY LOWER(c.name), c.company_sid
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

	IF helper_pkg.IsElevatedAccount THEN
		SetCompany(v_company_sid);
		RETURN v_company_sid;
	END IF;
	
	-- first, verify that this user exists as a chain_user (ensures that views work at bare minimum)
	helper_pkg.AddUserToChain(SYS_CONTEXT('SECURITY', 'SID'));
		
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
		IF NOT helper_pkg.IsChainAdmin AND
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
			IF NOT helper_pkg.IsChainAdmin AND
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
			IF NOT helper_pkg.IsChainAdmin AND
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
	IF v_company_sid IS NULL AND helper_pkg.IsChainAdmin THEN
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
		IF helper_pkg.IsElevatedAccount THEN
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
			IF NOT helper_pkg.IsChainAdmin AND
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

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM v$company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(name) = LOWER(in_name);
	
	SetCompany(v_company_sid);
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
	
	IF in_parent_sid_id <> helper_pkg.GetCompaniesContainer THEN
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
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => in_sid_id
	);

	-- add product codes defaults for the new company
	product_pkg.SetProductCodeDefaults(in_sid_id);
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
		   SET deleted = chain_pkg.DELETED
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id;
		
		RETURN;
	END IF;
		
	IF NOT TrySplitSOName(in_new_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
		
	UPDATE company
	   SET name = v_company_name,
	       country_code = TRIM(v_country_code),
	       deleted = chain_pkg.NOT_DELETED
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
  
	UPDATE invitation 
	   SET reinvitation_of_invitation_id = NULL
	 WHERE app_sid = security_pkg.GetApp
	   AND reinvitation_of_invitation_id IN (
			  SELECT invitation_id 
				FROM invitation 
			   WHERE app_sid = security_pkg.GetApp
			     AND (from_company_sid = in_sid_id OR to_company_sid = in_sid_id)	
	  );
	   
	DELETE FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND (from_company_sid = in_sid_id OR to_company_sid = in_sid_id);

	-- TODO: clear tasks
	/*DELETE FROM task_file
	 WHERE app_sid = security_pkg.GetApp
	   AND task_id IN (
	   		SELECT task_id
	   		  FROM task
	   		 WHERE app_sid = security_pkg.GetApp
	   		   AND (supplier_company_sid = in_sid_id OR owner_company_sid = in_sid_id)
	   	);
	*/
	DELETE FROM task
	 WHERE app_sid = security_pkg.GetApp
	   AND (supplier_company_sid = in_sid_id OR owner_company_sid = in_sid_id);
	
	DELETE FROM purchase
	 WHERE purchaser_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM purchase_channel
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	
	chain_link_pkg.DeleteCompany(in_sid_id);	
	
	UPDATE purchased_component
	   SET component_supplier_type_id = 0, supplier_company_sid = NULL
	 WHERE supplier_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM purchased_component
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM purchaser_follower 
	 WHERE ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id))
	   AND app_sid = security_pkg.GetApp;	 
	   
	DELETE FROM supplier_follower 
	 WHERE ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id))
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
	-- TODO: we'll need to fix this up...
	--DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));	
	--DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	--DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	--DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	
	DELETE FROM message_recipient 
	 WHERE recipient_id IN
	(
		SELECT recipient_id FROM recipient
		 WHERE app_sid = security_pkg.GetApp
		   AND to_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM recipient 
	 WHERE app_sid = security_pkg.GetApp
	   AND to_company_sid = in_sid_id;
	
	DELETE FROM message_recipient 
	 WHERE message_id IN
	(
		SELECT message_id FROM message 
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message_refresh_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message 
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM user_message_log
	 WHERE message_id IN
	(
		SELECT message_id FROM message 
		 WHERE app_sid = security_pkg.GetApp
		   AND re_company_sid = in_sid_id
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message 
	 WHERE app_sid = security_pkg.GetApp
	   AND re_company_sid = in_sid_id;
	
	DELETE FROM file_upload 
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;
	
	DELETE FROM component_relationship
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	UPDATE purchased_component
	   SET supplier_product_id = NULL
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_product_id IN (SELECT product_id FROM product WHERE app_sid = security_pkg.GetApp AND company_sid = in_sid_id);
	
	DELETE FROM product
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM component_bind
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM uninvited_supplier
	 WHERE created_as_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
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
	in_sector_id			IN  company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT helper_pkg.GetCompaniesContainer;
BEGIN	
	-- createSO does the sec check
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Company'), helper_pkg.GenerateSOName(in_name, in_country_code), out_company_sid);
	
	UPDATE company
	   SET name = in_name,
	       sector_id = in_sector_id
	 WHERE company_sid = out_company_sid;
	
	-- callout to customised systems
	chain_link_pkg.AddCompany(out_company_sid);
END;

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	in_sector_id			IN  company.sector_id%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN	
	IF (CheckCompanyUnique(in_name, in_country_code) < 0) THEN
		CreateCompany(in_name, in_country_code, in_sector_id, out_company_sid);
		RETURN;	
	END IF;		
	RAISE dup_val_on_index;
END;

/* returns sid if present and -1 in not */
FUNCTION CheckCompanyUnique(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE
) RETURN NUMBER
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT company_sid INTO v_company_sid FROM company WHERE lower(name)=lower(in_name) AND country_code=in_country_code;
	EXCEPTION
		WHEN no_data_found THEN
			RETURN -1;
	END;
	RETURN v_company_sid;
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
	
	-- This gets ran twice, but ought to reduce the number of integrity constraint errors caused by deleting users that have components etc
	chain_link_pkg.DeleteCompany(in_company_sid);
	
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
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, NULL);
	
	-- Send deleted message to all purchasers
	-- TODO: Do we just want to send a message for companies that have an active relationship? This assumes not to pick up rejected invitations
	FOR p IN (
		SELECT *
		  FROM supplier_relationship
		 WHERE app_sid = security_pkg.GetApp
		   AND supplier_company_sid = in_company_sid
	) LOOP
		message_pkg.TriggerMessage (
			in_primary_lookup			=> chain_pkg.COMPANY_DELETED,
			in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
			in_to_company_sid			=> p.PURCHASER_COMPANY_SID,
			in_to_user_sid				=> chain_pkg.FOLLOWERS,
			in_re_company_sid			=> in_company_sid
		);
	END LOOP;
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
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, helper_pkg.GenerateSOName(v_name, v_cc));	
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
	in_website				IN  company.website%TYPE,
	in_sector_id				IN  company.sector_id%TYPE
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
		securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, helper_pkg.GenerateSOName(in_name, in_country_code));
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
	 	   website = in_website,
	 	   sector_id = in_sector_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	chain_link_pkg.UpdateCompany(in_company_sid);
END;

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, helper_pkg.GetCompaniesContainer, helper_pkg.GenerateSOName(in_company_name, in_country_code));
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
	v_count					INTEGER;
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
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid
	   AND deleted=1;
	
	IF (v_count=1) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_COMPANY_IS_DELETED, 'Company with company_sid: '||in_company_sid||' has been deleted.');
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
	in_company_sid 			IN security_pkg.T_SID_ID
) RETURN company.name%TYPE
AS
	v_n			company.name%TYPE;
BEGIN
	
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		SELECT name
		  INTO v_n
		  FROM v$company
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid;
	ELSE	
		BEGIN
			SELECT c.name
			  INTO v_n
			  FROM v$company c, v$company_relationship cr
			 WHERE c.app_sid = security_pkg.GetApp
			   AND c.app_sid = cr.app_sid
			   AND c.company_sid = in_company_sid
			   AND c.company_sid = cr.company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_n := ' ';
		END;
	END IF;

	RETURN v_n;
END;

	 
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

PROCEDURE FilterCompanies (
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	filter_pkg.GetCompanySids(in_compound_filter_sid, v_results);
	
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

PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: This method already exists in company_pkg as SearchSuppliers (you can search with text = '' and page_size 0 for all results)
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
END;

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: this method should be moved to company_pkg	 
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.purchaser_company_sid 
		   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
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
	
	IF helper_pkg.IsChainAdmin(SYS_CONTEXT('SECURITY', 'SID')) THEN
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
			UPDATE supplier_relationship
			   SET deleted = chain_pkg.NOT_DELETED, active = chain_pkg.PENDING
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = chain_pkg.DELETED
			   AND purchaser_company_sid = in_purchaser_company_sid
			   AND supplier_company_sid = in_supplier_company_sid;
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
	
	purchased_component_pkg.RelationshipActivated(in_purchaser_company_sid, in_supplier_company_sid);
	
	chain_link_pkg.ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
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
	
	UPDATE supplier_relationship
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (   active = chain_pkg.PENDING
	   		OR v_force = 1);
END;

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	ActivateVirtualRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, out_key);
END;

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid			IN  security_pkg.T_SID_ID,
	out_key							OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied activating virtual relationships where you are niether the purchaser or supplier');
	END IF;
	
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = sysdate + interval '1' minute, virtually_active_key = virtually_active_key_seq.NEXTVAL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (virtually_active_key IS NULL
	    OR sysdate > virtually_active_until_dtm)
 RETURNING virtually_active_key INTO out_key;
END;

PROCEDURE DeactivateVirtualRelationship (
	in_key							IN  supplier_relationship.virtually_active_key%TYPE
)
AS
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	-- get company_sid's for security check
	BEGIN
		SELECT purchaser_company_sid, supplier_company_sid
		  INTO v_purchaser_company_sid, v_supplier_company_sid
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND virtually_active_key = in_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN;
	END;
	
	IF v_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND v_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deactivating virtual relationships where you are niether the purchaser or supplier');
	END IF;

	-- Only deactivate if in_key was the key that set up the relationship
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = NULL, virtually_active_key = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND virtually_active_key = in_key;
END;

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsMember(in_supplier_company_sid, in_user_sid) THEN		
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a purchaser follower (pc='||in_purchaser_company_sid||') user who is not a member of the supplier company (sc='||in_supplier_company_sid||', su='||in_user_sid||')');
	END IF;
	
	BEGIN
		INSERT INTO purchaser_follower
		(purchaser_company_sid, supplier_company_sid, user_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsMember(in_purchaser_company_sid, in_user_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a supplier follower (sc='||in_supplier_company_sid||') user who is not a member of the purchaser company (pc='||in_purchaser_company_sid||', pu='||in_user_sid||')');
	END IF;
	
	BEGIN
		INSERT INTO supplier_follower
		(purchaser_company_sid, supplier_company_sid, user_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading purchaser follower details where you are niether the purchaser or supplier');
	END IF;
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM purchaser_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading supplier follower details where you are niether the purchaser or supplier');
	END IF;
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM supplier_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;


FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsMember(in_company_sid, security_pkg.GetSid);
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	IF NOT helper_pkg.IsChainAdmin(in_user_sid) AND
	   NOT VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, in_user_sid) AND 
	   NOT VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, in_user_sid) THEN
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
	IF IsMember(in_company_sid, security_pkg.GetSid) THEN
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
	IF helper_pkg.IsChainAdmin(in_user_sid) THEN
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

PROCEDURE ConfirmCompanyDetails (
	in_company_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RETURN;
	END IF;
	
	UPDATE company
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;
	
	message_pkg.CompleteMessageIfExists (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => in_company_sid
	);
END;

PROCEDURE GetCompaniesRegisteredByUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_company_sids			OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	SELECT security.T_ORDERED_SID_ROW(f.supplier_company_sid, null)
	  BULK COLLECT INTO out_company_sids
	  FROM supplier_follower f
	  JOIN v$company c ON c.company_sid = f.supplier_company_sid AND c.app_sid = f.app_sid
	 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND f.purchaser_company_sid = in_purchaser_company_sid
	   AND f.user_sid = in_user_sid;
END;

PROCEDURE GetCompaniesAndUsers (
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	filter_pkg.GetCompanySids(in_compound_filter_sid, v_results);
	
	OPEN out_result_cur FOR
		SELECT c.*, u.*
		  FROM v$company c
		  JOIN v$company_user u on c.company_sid = u.company_sid AND c.app_sid = u.app_sid
		  JOIN TABLE(v_results) f ON f.sid_id = c.company_sid;
END;

END company_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.company_filter_pkg
IS

/* private */
PROCEDURE FilterCountry (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  filter_field.filter_field_id%TYPE,
	in_sids				IN  security.T_ORDERED_SID_TABLE,
	out_sids			OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	out_sids := security.T_ORDERED_SID_TABLE();
	
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT company_sid
		  FROM v$company c
		  JOIN TABLE(in_sids) t ON c.company_sid = t.sid_id
		  JOIN v$filter_value ff ON c.country_code = ff.str_value
		 WHERE ff.filter_id = in_filter_id 
		   AND ff.filter_field_id = in_filter_field_id
	);
END;

PROCEDURE FilterSector (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  filter_field.filter_field_id%TYPE,
	in_sids				IN  security.T_ORDERED_SID_TABLE,
	out_sids			OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	out_sids := security.T_ORDERED_SID_TABLE();
	
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT company_sid
		  FROM v$company c
		  JOIN TABLE(in_sids) t ON c.company_sid = t.sid_id
		  JOIN v$filter_value ff ON c.sector_id = ff.num_value
		 WHERE ff.filter_id = in_filter_id 
		   AND ff.filter_field_id = in_filter_field_id
	);
END;

PROCEDURE FilterName (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_filter_field_id	IN  filter_field.filter_field_id%TYPE,
	in_sids				IN  security.T_ORDERED_SID_TABLE,
	out_sids			OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	out_sids := security.T_ORDERED_SID_TABLE();
	
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT company_sid
		  FROM v$company c
		  JOIN TABLE(in_sids) t ON c.company_sid = t.sid_id
		  JOIN v$filter_value ff ON lower(c.name) like '%'||lower(ff.str_value)||'%' 
		 WHERE ff.filter_id = in_filter_id 
		   AND ff.filter_field_id = in_filter_field_id
	);
END;


PROCEDURE FilterSids (
	in_filter_id		IN  filter.filter_id%TYPE,
	in_sids				IN  security.T_ORDERED_SID_TABLE,
	out_sids			OUT security.T_ORDERED_SID_TABLE
)
AS
BEGIN
	
	out_sids := in_sids;
	
	FOR r IN (
		SELECT name, filter_field_id
		  FROM v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
	) LOOP
		
		IF r.name = 'CountryCode' THEN
			FilterCountry(in_filter_id, r.filter_field_id, out_sids, out_sids);
		ELSIF r.name = 'Name' THEN
			FilterName(in_filter_id, r.filter_field_id, out_sids, out_sids);
		ELSIF r.name = 'Sector' THEN
			FilterSector(in_filter_id, r.filter_field_id, out_sids, out_sids);
		END IF;
		
	END LOOP;
END;


END company_filter_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.company_user_pkg
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
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
			in_to_user_sid              => v_user_sid
		);

		
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

   UPDATE invitation 
      SET reinvitation_of_invitation_id = NULL
    WHERE reinvitation_of_invitation_id IN (
      SELECT invitation_id 
	    FROM invitation 
	   WHERE ((from_user_sid = in_sid_id) 
          OR (to_user_sid = in_sid_id))
         AND app_sid = security_pkg.GetApp);
	
	DELETE FROM invitation
	 WHERE ((from_user_sid = in_sid_id) 
		OR (to_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;
	
   UPDATE invitation 
      SET cancelled_by_user_sid = NULL
    WHERE cancelled_by_user_sid = in_sid_id 
	  AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message_recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND recipient_id IN (SELECT recipient_id FROM recipient WHERE to_user_sid = in_sid_id AND app_sid = security_pkg.GetApp);
	
	DELETE FROM recipient
	 WHERE to_user_sid = in_sid_id 
	  AND app_sid = security_pkg.GetApp;
	
	DELETE FROM purchaser_follower
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM supplier_follower
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	
	DELETE FROM message_recipient
	 WHERE app_sid = security_pkg.GetApp
	   AND message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp);
	
	DELETE FROM message_refresh_log
	 WHERE app_sid = security_pkg.GetApp
	   AND (refresh_user_sid = in_sid_id 
	    OR message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp));
	
	DELETE FROM user_message_log
	 WHERE app_sid = security_pkg.GetApp
	   AND (user_sid = in_sid_id
	    OR message_id IN (SELECT message_id FROM message WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id) AND app_sid = security_pkg.GetApp));
	
	-- A bit harsh? Fine for clearing out test users, we have soft delete for real users
	DELETE FROM message
	 WHERE (re_user_sid = in_sid_id OR completed_by_user_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;
	
	-- Again way harsh how much we need to delete from components in order to delete the user cleanly.
	UPDATE purchased_component
	   SET supplier_product_id = NULL
	 WHERE app_sid = security_pkg.GetApp
	   AND supplier_product_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM purchased_component
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	FOR td	IN (SELECT product_id FROM product
			     WHERE app_sid = security_pkg.GetApp
			       AND product_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id))
		LOOP
			chain_link_pkg.KillProduct(td.product_id);
		END LOOP;
	
	DELETE FROM product
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM component_relationship
	 WHERE app_sid = security_pkg.GetApp
	   AND (child_component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id)
	    OR container_component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id));
	
	DELETE FROM component_bind
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM purchased_component
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM component_document
	 WHERE app_sid = security_pkg.GetApp
	   AND component_id IN (SELECT component_id FROM component WHERE app_sid = security_pkg.GetApp AND created_by_sid = in_sid_id);
	
	DELETE FROM component
	 WHERE app_sid = security_pkg.GetApp
	   AND created_by_sid = in_sid_id;
	
	DELETE FROM qnr_share_log_entry
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_sid_id;
	
	DELETE FROM qnr_status_log_entry
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_sid_id;
	
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
	
	UPDATE supplier_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	UPDATE purchaser_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	UPDATE message
	   SET re_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND re_user_sid = in_user_sid;
	
	-- TOOD: merge message recipients?
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

		DeleteUser(in_user_sid);
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
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
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
	helper_pkg.AddUserToChain(out_user_sid);
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
				LOWER(email) LIKE v_search OR
	   	   		LOWER(job_title) LIKE v_search)
	  );
	
	v_show_admins := (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) 
				  OR (capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE));
	  
	CollectSearchResults(in_company_sid, v_results, v_show_admins, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE GetAllCompanyUsers (
	in_company_sid_array	IN  security_pkg.T_SID_IDS,
	in_dummy				IN  NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
	v_company_sid_table		security.T_ORDERED_SID_TABLE DEFAULT security_pkg.SidArrayToOrderedTable(in_company_sid_array);
BEGIN
	FOR i IN 1..in_company_sid_array.last LOOP
		v_company_sid := in_company_sid_array(i);
		IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||v_company_sid);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT *
		  FROM v$chain_company_user ccu
		  JOIN TABLE(v_company_sid_table) c ON ccu.company_sid = c.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
END;

PROCEDURE ApproveUser (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_user_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
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
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
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
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied demoting users on company sid '||in_company_sid);
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
	
	RETURN GetRegistrationStatusNoCheck(in_user_sid);
END;

FUNCTION GetRegistrationStatusNoCheck (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS
AS
	v_rs			    	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	BEGIN
		SELECT registration_status_id
		  INTO v_rs
		  FROM chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			helper_pkg.AddUserToChain(in_user_sid);
			
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

PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE chain_user
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

	message_pkg.CompleteMessageIfExists (
		in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
		in_to_user_sid          	=> in_user_sid
	);
END;

PROCEDURE GetRegUsersForCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_cur FOR
		-- admins
		SELECT 	chu.app_sid, chu.user_sid, chu.email, chu.user_name,   
				chu.full_name, chu.friendly_name, chu.phone_number, chu.job_title,  
				chu.visibility_id, chu.registration_status_id,								
				chu.next_scheduled_alert_dtm, chu.receive_scheduled_alerts, chu.details_confirmed, 1 is_admin
		  FROM v$chain_user chu, v$company_admin ca
		 WHERE chu.app_sid = ca.app_sid
		   AND chu.user_sid = ca.user_sid
		   AND ca.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ca.company_sid = in_company_sid
		UNION
		-- all non admins
		SELECT 	chu.app_sid, chu.user_sid, chu.email, chu.user_name,   
				chu.full_name, chu.friendly_name, chu.phone_number, chu.job_title,  
				chu.visibility_id, chu.registration_status_id,								
				chu.next_scheduled_alert_dtm, chu.receive_scheduled_alerts, chu.details_confirmed, 0 is_admin
		  FROM v$chain_user chu, v$company_user cu
		 WHERE chu.app_sid = cu.app_sid
		   AND chu.user_sid = cu.user_sid
		   AND cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cu.company_sid = in_company_sid
		   AND cu.user_sid NOT IN (
			SELECT user_sid FROM v$company_admin WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') AND company_sid = in_company_sid
		   );
END;

END company_user_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
PROCEDURE FillTypeContainment
AS
BEGIN
	DELETE FROM tt_component_type_containment;
	
	INSERT INTO tt_component_type_containment
	(container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	chain_link_pkg.FilterComponentTypeContainment;
END;

FUNCTION CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_component_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to components for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to components for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

FUNCTION GetTypeId (
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_COMPONENT_TYPE
AS
	v_type_id 				chain_pkg.T_COMPONENT_TYPE;
BEGIN
	SELECT component_type_id
	  INTO v_type_id
	  FROM component_bind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	RETURN v_type_id;
END;

FUNCTION GetHandlerPkg (
	in_type_id				chain_pkg.T_COMPONENT_TYPE
) RETURN all_component_type.handler_pkg%TYPE
AS
	v_hp					all_component_type.handler_pkg%TYPE;
BEGIN
	SELECT handler_pkg
	  INTO v_hp
	  FROM v$component_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_type_id = in_type_id;
	
	RETURN v_hp;
END;

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ActivateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type
		(component_type_id)
		VALUES
		(in_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
)
AS
BEGIN
	CreateType(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, NULL); 
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO all_component_type
		(component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id)
		VALUES
		(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, in_editor_card_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_component_type
			   SET handler_class = in_handler_class,
			   	   handler_pkg = in_handler_pkg,
			   	   node_js_path = in_node_js_path,
			   	   description = in_description,
			   	   editor_card_group_id = in_editor_card_group_id
			 WHERE component_type_id = in_type_id;
	END;
END;

PROCEDURE ClearSources
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearSources can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
)
AS
BEGIN
	AddSource(in_type_id, in_action, in_text, in_description, null);
END;


PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
)
AS
	v_max_pos				component_source.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddSource can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_action <> LOWER(TRIM(in_action)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Actions must be formatted as trimmed and lower case');
	END IF;
	
	ActivateType(in_type_id);
	
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

PROCEDURE GetSources (
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

PROCEDURE ClearTypeContainment
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTypeContainment can only be run as BuiltIn/Administrator');
	END IF;

	DELETE 
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE SetTypeContainment (
	in_container_type_id				IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id					IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags						IN chain_pkg.T_FLAG
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTypeContainment can only be run as BuiltIn/Administrator');
	END IF;
	
	ActivateType(in_container_type_id);
	ActivateType(in_child_type_id);
	
	BEGIN
		INSERT INTO component_type_containment
		(container_component_type_id, child_component_type_id)
		VALUES
		(in_container_type_id, in_child_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
		
	UPDATE component_type_containment
	   SET allow_add_existing = helper_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_EXISTING),
	       allow_add_new = helper_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_NEW)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_type_id = in_container_type_id
	   AND child_component_type_id = in_child_type_id;

END;

PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	FillTypeContainment;
	
	OPEN out_cur FOR
		SELECT * FROM tt_component_type_containment;
END;

PROCEDURE CreateComponentAmountUnit (
	in_amount_unit_id		IN amount_unit.amount_unit_id%TYPE,
	in_description			IN amount_unit.description%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateComponentAmountUnit can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO amount_unit
		(amount_unit_id, description)
		VALUES
		(in_amount_unit_id, in_description);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE amount_unit
			   SET description = in_description
			 WHERE amount_unit_id = in_amount_unit_id;
	END;
END;

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN
AS
	v_type_id		chain_pkg.T_COMPONENT_TYPE;
BEGIN
	BEGIN
		SELECT component_type_id
		  INTO v_type_id
		  FROM component_bind
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	IF v_type_id = in_type_id THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;

FUNCTION GetCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN
	BEGIN
		SELECT company_sid 
		  INTO v_company_sid 
		  FROM component_bind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
		
	RETURN v_company_sid;
	
END;

FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_deleted				component.deleted%TYPE;
BEGIN
	-- don't worry about sec as there's not much we can do with a bool flag...

	SELECT deleted
	  INTO v_deleted
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id;
	
	RETURN v_deleted = chain_pkg.DELETED;
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
)
AS
	v_top_component_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TT_COMPONENT_TREE
	 WHERE top_component_id = in_top_component_id;
	
	-- if we've already got entries, get out
	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	SELECT T_NUMERIC_ROW(in_top_component_id, NULL)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;
	
	RecordTreeSnapshot(v_top_component_ids);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
)
AS
	v_unrecorded_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT T_NUMERIC_ROW(item, NULL)
	  BULK COLLECT INTO v_unrecorded_ids
	  FROM TABLE(in_top_component_ids)
	 WHERE item NOT IN (SELECT top_component_id FROM TT_COMPONENT_TREE);
	 
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_unrecorded_ids);
	
	-- if there's nothing here, then they've all been collected
	IF v_count = 0 THEN
		RETURN;
	END IF;
	
	-- insert the top components
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT item, null, item, 0
	  FROM TABLE(v_unrecorded_ids);
	
	-- insert the tree
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, amount_child_per_parent, amount_unit_id, position)
	SELECT top_component_id, container_component_id, child_component_id, amount_child_per_parent, amount_unit_id, rownum
	  FROM (
			SELECT CONNECT_BY_ROOT container_component_id top_component_id, container_component_id, child_component_id, amount_child_per_parent, amount_unit_id, position
			  FROM component_relationship
			 START WITH container_component_id IN (SELECT item FROM TABLE(v_unrecorded_ids))
			CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
			 ORDER SIBLINGS BY position
		);
END;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetType(NULL, out_cur);	
END;

PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id		
		  FROM v$component_type
		 WHERE app_sid = security_pkg.GetApp
		   AND component_type_id = NVL(in_type_id, component_type_id);
END;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE
AS
BEGIN
	RETURN SaveComponent(in_component_id, in_type_id, in_description, in_component_code, NULL);
END;

FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE
) RETURN component.component_id%TYPE
AS
	v_component_id			component.component_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF v_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		v_user_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/UserCreatorDaemon');
	END IF;
	
	IF NVL(in_component_id, 0) < 1 THEN

		INSERT INTO component 
		(component_id,  description, component_code, component_notes, created_by_sid)
		VALUES 
		(component_id_seq.nextval, in_description, in_component_code, in_component_notes, v_user_sid) 
		RETURNING component_id INTO v_component_id;
		
		INSERT INTO component_bind
		(component_id, component_type_id)
		VALUES
		(v_component_id, in_type_id);

	ELSE

		IF NOT IsType(in_component_id, in_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot save component with id '||in_component_id||' because it is not of type '||in_type_id);
		END IF;
		
		v_component_id := in_component_id;
		
		UPDATE component
		   SET description = in_description, 
			   component_code = in_component_code,
			   component_notes = in_component_notes
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	END IF;
	
	RETURN v_component_id;
END;


PROCEDURE StoreComponentAmount (
	in_parent_component_id		IN component.component_id%TYPE,
	in_component_id		   		IN component.component_id%TYPE,
	in_amount_child_per_parent	IN component_relationship.amount_child_per_parent%TYPE,
	in_amount_unit_id			IN component_relationship.amount_unit_id%TYPE
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);

	UPDATE component_relationship
	   SET 	amount_child_per_parent = in_amount_child_per_parent,
			amount_unit_id = in_amount_unit_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND child_component_id = in_component_id
	   AND container_component_id = in_parent_component_id; 
END;

PROCEDURE DeleteComponent (
	in_component_id		   	IN component.component_id%TYPE
)
AS
BEGIN
	IF IsDeleted(in_component_id) THEN
	   	RETURN;
    END IF;
	
	-- TODO: shouldn't DeleteComponent be checking the delete permission?
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE component 
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id; 

	-- call the handler
	EXECUTE IMMEDIATE 'begin '||GetHandlerPkg(GetTypeId(in_component_id))||'.DeleteComponent('||in_component_id||'); end;';
	
	-- detach the component from everything
	DetachComponent(in_component_id);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT component_id, component_type_id, company_sid, created_by_sid, created_dtm, description, component_code, component_notes
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id
		   AND deleted = chain_pkg.NOT_DELETED;
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT c.component_id, c.component_type_id, c.description, c.component_code, c.component_notes, c.deleted, c.company_sid, 
			   c.created_by_sid, c.created_dtm, ct.amount_child_per_parent, ct.amount_unit_id
		  FROM v$component c, TT_COMPONENT_TREE ct
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND c.component_type_id = in_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE GetDefaultAmountUnit (
	out_amount_unit_id	OUT amount_unit.amount_unit_id%TYPE,
	out_amount_unit		OUT amount_unit.description%TYPE
)
AS
	-- tried using cursor here but got funny results
	v_amount_unit_id	amount_unit.amount_unit_id%TYPE;
	v_amount_unit		amount_unit.description%TYPE;
BEGIN
	-- Default is just min for now
	SELECT amount_unit_id, description 
	  INTO v_amount_unit_id, v_amount_unit
		 FROM (
		SELECT amount_unit_id, MIN(amount_unit_id) OVER (PARTITION BY app_sid) min_amount_unit_id, description
		  FROM amount_unit
		 WHERE app_sid = security_pkg.GetApp
	) 
	WHERE amount_unit_id = min_amount_unit_id;
	
	out_amount_unit_id := v_amount_unit_id;
	out_amount_unit := v_amount_unit;
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	SearchComponents(in_page, in_page_size, in_container_type_id, in_search_term, NULL, out_count_cur, out_result_cur);
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
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
	
	FillTypeContainment;
	
	-- bulk collect component id's that match our search result
	SELECT security.T_ORDERED_SID_ROW(component_id, null)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT c.component_id
		  FROM v$component c, tt_component_type_containment ctc
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND c.component_type_id = NVL(in_of_type, component_type_id)
		   AND c.component_type_id = ctc.child_component_type_id
		   AND ctc.container_component_type_id = in_container_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
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
			  FROM v$component c, TABLE(v_results) T
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.component_id = T.SID_ID
			   AND c.deleted = chain_pkg.NOT_DELETED
			 ORDER BY LOWER(c.description), LOWER(c.component_code);

	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*
						  FROM v$component c, TABLE(v_results) T
						 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND c.component_id = T.SID_ID
						   AND c.deleted = chain_pkg.NOT_DELETED
						 ORDER BY LOWER(c.description), LOWER(c.component_code)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

-- Note: These are actually components belonging to the company but conceptually they are "stuff they buy"
PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200);
	v_sort_sql					VARCHAR2(4000);
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'componentcode', 'suppliername') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	v_order_by := in_sort_by;
	-- remap a couple of order by columns
	IF LOWER(v_order_by) = 'componentcode' THEN v_order_by := 'component_code'; END IF;
	IF LOWER(v_order_by) = 'suppliername' THEN v_order_by := 'supplier_name'; END IF;
	
	v_order_by := 'LOWER(pc.'||v_order_by||') '||in_sort_dir;
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(pc.description) '||in_sort_dir;
	END IF;
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id)
	SELECT component_id
	  FROM v$purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND ((in_supplier_company_sid IS NULL) OR (supplier_company_sid = in_supplier_company_sid) OR (uninvited_supplier_sid = in_supplier_company_sid))
	   AND ((LOWER(description) LIKE v_search) OR (LOWER(component_code) LIKE v_search))
	   AND deleted=chain_pkg.NOT_DELETED;
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	
	-- if the sort by is a column in the v$product view...
	v_sort_sql := ''||
		'	SELECT pc.component_id '||
		'	  FROM v$purchased_component pc, TT_ID t '||
		'	 WHERE pc.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
		'	   AND pc.component_id = t.id '||
		'	 ORDER BY '||v_order_by;
	
	EXECUTE IMMEDIATE ''||
		'UPDATE TT_ID i '||
		'   SET position = ( '||
		'		SELECT r.rn '||
		'		  FROM ('||
		'			SELECT component_id, rownum rn '||
		'			  FROM ('||v_sort_sql||') '||
		'			) r '||
		'		 WHERE i.id = r.component_id '||
		'   )';
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL(in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_component_ids
	  FROM TT_ID;
	
	OPEN out_component_cur FOR
		SELECT component_id, description, 
			   component_code, component_notes, deleted, company_sid, 
			   created_by_sid, created_dtm, component_supplier_type_id, 
			   acceptance_status_id, supplier_company_sid, supplier_name, supplier_country_code, supplier_country_name, 
			   purchaser_company_sid, purchaser_name, uninvited_supplier_sid, 
			   uninvited_name, supplier_product_id
		  FROM v$purchased_component cp, TABLE(v_component_ids) i
		 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cp.component_id = i.item
		 ORDER BY i.pos;
	
END;

-- Made this separate for control over columns - but shouldn't these both be in purchased_component_pkg?
PROCEDURE DownloadComponentsPurchased (
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_component_cur FOR
		SELECT component_id as product_id, description, 
			   component_code as product_code, component_notes as notes,
			   created_dtm as created_date, NVL(supplier_company_sid, uninvited_supplier_sid) as supplier_id,
			   NVL(supplier_name, uninvited_name) as supplier_name, supplier_country_code, supplier_country_name
		  FROM v$purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND deleted=chain_pkg.NOT_DELETED
		 ORDER BY LOWER(description);
END;


/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
	v_position				component_relationship.position%TYPE;
	v_container_type_id		chain_pkg.T_COMPONENT_TYPE;
	v_child_type_id			chain_pkg.T_COMPONENT_TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	v_company_sid := component_pkg.GetCompanySid(in_container_id);
	
	IF v_company_sid <> component_pkg.GetCompanySid(in_child_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot attach components which are owned by different companies');
	END IF;
	
	SELECT NVL(MAX(position), 0) + 1
	  INTO v_position
	  FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
	
	SELECT component_type_id
	  INTO v_container_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_container_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	SELECT component_type_id
	  INTO v_child_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	BEGIN 
		INSERT INTO component_relationship
		(container_component_id, container_component_type_id, child_component_id, child_component_type_id, company_sid, position)
		VALUES
		(in_container_id, v_container_type_id, in_child_id, v_child_type_id, v_company_sid, v_position);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;


PROCEDURE DetachComponent (
	in_component_id			IN component.component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	-- fully delete component relationship, no matter whether this component is the parent or the child
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (child_component_id = in_component_id OR container_component_id = in_component_id);
END;

PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	-- fully delete all child attachments
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
END;

PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE) ;

	-- delete component relationship
	DELETE FROM component_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id
	   AND child_component_id = in_child_id;

END;

/*
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE
AS
	v_top_component_ids		T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	SELECT T_NUMERIC_ROW(in_top_component_id, 0)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;	
	
	RETURN GetComponentTreeIds(v_top_component_ids);
END;

FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	-- this intentionally barfs if we get more than one company_sid
	SELECT cb.company_sid
	  INTO v_company_sid
	  FROM component_bind cb, TABLE(in_top_component_ids) c
	 WHERE cb.component_id = c.item
	 GROUP BY cb.company_sid;
	
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(child_component_id, rn)
	  BULK COLLECT INTO v_component_ids
	  FROM (
	  		-- add the rownum
	  		SELECT child_component_id, rownum rn 
	  		  FROM (
				-- get unique ids
				SELECT UNIQUE child_component_id
				  FROM (
				  	-- include all of the top_component_ids that we've passed in
					SELECT item child_component_id FROM TABLE(in_top_component_ids)
					 UNION ALL
					-- wrap it to accomodate the order by / union
					SELECT child_component_id
					  FROM (
					    -- walk the tree
						SELECT child_component_id
						  FROM component_relationship
						 WHERE app_sid = security_pkg.GetApp
						 START WITH container_component_id IN (SELECT item FROM TABLE(in_top_component_ids))
					   CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
						 ORDER SIBLINGS BY position
						   )
				   )
			   )
		   );
	
	RETURN v_component_ids;
END;
*/
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT child_component_id, container_component_id
		  FROM TT_COMPONENT_TREE
		 WHERE top_component_id = in_top_component_id
		 ORDER BY position;
END;

/**********************************************************************************
	GENERIC COMPONENT DOCUMENT UPLOAD SUPPORT
**********************************************************************************/

PROCEDURE GetComponentUploads(
	in_component_id					IN  chain.v$component.component_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	OPEN out_cur FOR
		SELECT key, cd.file_upload_sid, filename, mime_type, last_modified_dtm, NULL description, lang, download_permission_id,
			   NULL charset, last_modified_dtm creation_dtm, last_modified_dtm last_accessed_dtm, length(data) bytes
		  FROM chain.file_upload fu, chain.component_document cd
		 WHERE fu.app_sid = cd.app_sid
		   AND fu.file_upload_sid = cd.file_upload_sid
		   AND cd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cd.component_id = in_component_id;
END;

PROCEDURE AttachFileToComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID,
	in_key							IN 	component_document.key%TYPE
)
AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	INSERT INTO component_document (component_id, file_upload_sid, key)
		VALUES (in_component_id, in_file_upload_sid, in_key);
END;

PROCEDURE DettachFileFromComponent(
	in_component_id					IN	component_document.component_id%TYPE,
	in_file_upload_sid				IN	security_pkg.T_SID_ID
)
AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;

	DELETE FROM component_document 
	 WHERE component_id = in_component_id
	   AND file_upload_sid = in_file_upload_sid;

END;

PROCEDURE DoUploaderComponentFiles (
	in_component_id					IN	component_document.component_id%TYPE,
	in_added_cache_keys				IN  chain_pkg.T_STRINGS,
	in_deleted_file_sids			IN  chain_pkg.T_NUMBERS,
	in_key							IN  chain.component_document.key%TYPE 
)
AS
	v_file_sid security_pkg.T_SID_ID;
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid ' || GetCompanySid(in_component_id));
	END IF;	

	-- add files
	IF NOT (in_added_cache_keys IS NULL) THEN
		IF NOT (in_added_cache_keys(1) IS NULL) THEN
			FOR i IN in_added_cache_keys.FIRST .. in_added_cache_keys.LAST
			LOOP
				v_file_sid := upload_pkg.SecureFile(in_added_cache_keys(i));
				AttachFileToComponent(in_component_id, v_file_sid, in_key);		
			END LOOP;
		END IF;
	END IF;
	
	-- delete documents not used anymore
	IF NOT (in_deleted_file_sids IS NULL) THEN
		IF NOT (in_deleted_file_sids(1) IS NULL) THEN
			FOR i IN in_deleted_file_sids.FIRST .. in_deleted_file_sids.LAST
			LOOP
				component_pkg.DettachFileFromComponent(in_component_id, in_deleted_file_sids(i));	   
				upload_pkg.DeleteFile(in_deleted_file_sids(i));
			END LOOP;
		END IF;
	END IF;
END;

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/


PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF NOT IsType(in_component_id, chain_pkg.NOTSURE_COMPONENT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot change component type to '||in_to_type_id||'of component with id '||in_component_id||' because it is not a NOT SURE component');
	END IF;
	
	-- THIS MAY BARF - I've set the constraint to deferrable initially deferred, so I _think_ it should be ok...
	
	UPDATE component_bind
	   SET component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	UPDATE component_relationship
	   SET child_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND child_component_id = in_component_id;
	
	UPDATE component_relationship
	   SET container_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_component_id;
	
	GetType(in_to_type_id, out_cur); 
END;

END component_pkg;
/


CREATE OR REPLACE PACKAGE BODY chain.dashboard_pkg
IS

PROCEDURE GetInvitationSummary (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies			security.T_ORDERED_SID_TABLE;
	v_available_companies	security.T_ORDERED_SID_TABLE;
BEGIN
	
	company_pkg.GetCompaniesRegisteredByUser(v_user_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_my_companies);
	
	SELECT security.T_ORDERED_SID_ROW(supplier_company_sid, null)
	   BULK COLLECT INTO v_available_companies
	  FROM v$supplier_relationship
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	OPEN out_cur FOR
		SELECT 'REGISTERED' as Total_Type,
			    'Registered' as Total_Description,
			    COUNT(*) "All",
			    COUNT(CASE WHEN T1.sid_id IS NOT NULL THEN 1 ELSE NULL END) My
		  FROM v$company c
		  JOIN TABLE(v_available_companies) sr ON c.company_sid = sr.sid_id
		  LEFT JOIN TABLE(v_my_companies) T1 ON c.company_sid = T1.sid_id
		 WHERE c.active=1
		
		UNION ALL
		
		SELECT DECODE(s.invitation_status_id, chain_pkg.ACTIVE, 'CURRENT_INVITATIONS', chain_pkg.EXPIRED, 'OVERDUE_INVITATIONS'),
			    DECODE(s.invitation_status_id, chain_pkg.ACTIVE, 'Current Invitations', chain_pkg.EXPIRED, 'Overdue Invitations'),
			    COUNT(i.to_company_sid) "All",
			    COUNT(T1.sid_id) My
		  FROM invitation_status s
		  LEFT JOIN (invitation i 
					JOIN v$company c ON i.to_company_sid = c.company_sid AND i.app_sid = c.app_sid AND c.active = chain_pkg.INACTIVE
					JOIN csr.csr_user u ON i.from_user_sid = u.csr_user_sid AND i.app_sid = u.app_sid AND u.email NOT LIKE '%@credit360.com'
				) ON s.invitation_status_id = i.invitation_status_id
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN TABLE(v_my_companies) T1 ON i.to_company_sid = T1.sid_id
		 WHERE s.invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
		 GROUP BY s.invitation_status_id
		
		UNION ALL
		
		SELECT 'OVERDUE_REGISTRATIONS', 'Overdue Registrations',
			    COUNT(DISTINCT sr.sid_id) "All",
			    COUNT(DISTINCT T1.sid_id) My
		  FROM v$questionnaire_share q
		  LEFT JOIN v$company c ON q.qnr_owner_company_sid = c.company_sid AND q.app_sid = c.app_sid
		  LEFT JOIN TABLE(v_available_companies) sr ON c.company_sid = sr.sid_id
		  LEFT JOIN TABLE(v_my_companies) T1 ON sr.sid_id = T1.sid_id
		 WHERE share_status_id IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED)
		   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND due_by_dtm < SYSDATE;

END;

END dashboard_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.dev_pkg
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
		
		IF v_var = chain_pkg.ACTIVE AND helper_pkg.IsChainAdmin THEN
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
	WHILE LENGTH(v_cc) < 2
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
		v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, helper_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
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

CREATE OR REPLACE PACKAGE BODY chain.filter_pkg
IS

/*********************************************************************************/
/**********************   SO PROCS   *********************************************/
/*********************************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Only require ACLs to lock down this method, or do we?
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
BEGIN
	IF in_new_name IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting a name');
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
BEGIN
	-- TODO: Can we rely on ACLs here?
	
	-- TODO: Should we add a call to the helper_pkg for deletes?
	-- This will trigger cascade deletes where necessary
	DELETE FROM filter
	 WHERE compound_filter_sid = in_sid_id;
	
	DELETE FROM compound_filter
	 WHERE compound_filter_sid = in_sid_id;
	
END;


PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	-- don't allow move
	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied moving object');
END;

/**********************************************************************************/
/********************** Configuration *********************************************/
/**********************************************************************************/

-- Register a filter type in the system
PROCEDURE CreateFilterType (
	in_description			filter_type.description%TYPE,
	in_helper_pkg			filter_type.helper_pkg%TYPE,
	in_js_class_type		card.js_class_type%TYPE
)
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
	v_card_id				card.card_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateFilterType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			filter_type_id_seq.NEXTVAL,
			in_description,
			in_helper_pkg,
			card_pkg.GetCardId(in_js_class_type)
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE filter_type
			   SET description = in_description,
			       helper_pkg = in_helper_pkg
			 WHERE card_id = card_pkg.GetCardId(in_js_class_type);
	END;
END;

FUNCTION GetFilterTypeId (
	in_js_class_type		card.js_class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id = card_pkg.GetCardId(in_js_class_type);
	
	RETURN v_filter_type_id;
END;

FUNCTION GetFilterTypeId (
	in_card_group_id	card_group.card_group_id%TYPE,
	in_class_type		card.class_type%TYPE
) RETURN filter_type.filter_type_id%TYPE
AS
	v_filter_type_id		filter_type.filter_type_id%TYPE;
BEGIN
	-- TODO: What if there is more than one? i.e. 2 JS class types sharing 1 C# class type for one card group
	--       This would break, but there's no other way of distinguising filter_type_id from C#
	SELECT filter_type_id
	  INTO v_filter_type_id
	  FROM filter_type
	 WHERE card_id IN (
		SELECT c.card_id
		  FROM card_group_card cgc
		  JOIN card c ON cgc.card_id = c.card_id
		 WHERE cgc.app_sid = security_pkg.GetApp
		   AND cgc.card_group_id = in_card_group_id
		   AND c.class_type = in_class_type);
	
	RETURN v_filter_type_id;
END;

/**********************************************************************************/
/********************** Building up a Filter **************************************/
/**********************************************************************************/

PROCEDURE CreateCompoundFilter (
	out_compound_filter_sid		OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	SecurableObject_pkg.CreateSO(
		security_pkg.GetAct, 
		securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.GetCompany, chain_pkg.COMPANY_FILTERS), 
		class_pkg.GetClassID('ChainCompoundFilter'), NULL, out_compound_filter_sid);
	
	INSERT INTO compound_filter (compound_filter_sid)
	VALUES (out_compound_filter_sid);
END;

PROCEDURE SaveCompoundFilter (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_name						IN	compound_filter.name%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_compound_filter_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||in_compound_filter_sid);
	END IF;
	
	UPDATE compound_filter
	   SET name = in_name
	 WHERE compound_filter_sid = in_compound_filter_sid
	   AND app_sid = security_pkg.GetApp;
END;

FUNCTION GetNextFilterId (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_filter_type_id			IN	filter_type.filter_type_id%TYPE
) RETURN NUMBER
AS
	v_filter_id					filter.filter_id%TYPE;
BEGIN
	SELECT filter_id_seq.NEXTVAL
	  INTO v_filter_id
	  FROM dual;
	
	INSERT INTO filter (filter_id, filter_type_id, compound_filter_sid)
	VALUES (v_filter_id, in_filter_type_id, in_compound_filter_sid);
	
	RETURN v_filter_id;
END;

FUNCTION GetCompoundSidFromfilterId (
	in_filter_id			IN	filter.filter_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_compound_filter_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT compound_filter_sid
	  INTO v_compound_filter_sid
	  FROM filter
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
	
	RETURN v_compound_filter_sid;
END;

FUNCTION GetCompoundSidFromFieldId (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_filter_id				filter.filter_id%TYPE;
BEGIN
	SELECT filter_id
	  INTO v_filter_id
	  FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id = in_filter_field_id;
	
	RETURN GetCompoundSidFromfilterId(v_filter_id);
END;

PROCEDURE DeleteFilter (
	in_filter_id				IN	filter.filter_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromfilterId(in_filter_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromfilterId(in_filter_id));
	END IF;
	
	-- Currently have cascading deletes on this table, but maybe this should be handled by the helper_pkg?
	DELETE FROM filter
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;
END;

PROCEDURE AddCardFilter (
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	in_class_type				IN	card.class_type%TYPE,
	in_card_group_id			IN	card_group.card_group_id%TYPE,
	out_filter_id				OUT	filter.filter_id%TYPE
)
AS
BEGIN
	out_filter_id := GetNextFilterId(in_compound_filter_sid, GetFilterTypeId(in_card_group_id, in_class_type));
END;


/**********************************************************************************/
/**********************   Filter Field/Value management   *************************/
/**********************************************************************************/
PROCEDURE AddFilterField (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_name					IN	filter_field.name%TYPE,
	in_comparator			IN	filter_field.comparator%TYPE,
	out_filter_field_id		OUT	filter_field.filter_field_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromfilterId(in_filter_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromfilterId(in_filter_id));
	END IF;
	
	INSERT INTO filter_field (filter_field_id, filter_id, name, comparator)
	VALUES (filter_field_id_seq.NEXTVAL, in_filter_id, in_name, in_comparator)
	RETURNING filter_field_id INTO out_filter_field_id;
END;

PROCEDURE DeleteRemainingFields (
	in_filter_id			IN	filter.filter_id%TYPE,
	in_fields_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_fields_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_fields_to_keep);
	v_count					NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromfilterId(in_filter_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromfilterId(in_filter_id));
	END IF;
	
	DELETE FROM filter_field
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id
	   AND filter_field_id NOT IN (
		SELECT item FROM TABLE(v_fields_to_keep));
END;

PROCEDURE AddNumberValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.num_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromFieldId(in_filter_field_id));
	END IF;
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, num_value)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_value)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE AddStringValue (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_value				IN	filter_value.str_value%TYPE,
	out_filter_value_id		OUT	filter_value.filter_value_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromFieldId(in_filter_field_id));
	END IF;
	
	INSERT INTO filter_value (filter_value_id, filter_field_id, str_value)
	VALUES (filter_value_id_seq.NEXTVAL, in_filter_field_id, in_value)
	RETURNING filter_value_id INTO out_filter_value_id;
	
END;

PROCEDURE DeleteRemainingFieldValues (
	in_filter_field_id		IN	filter_field.filter_field_id%TYPE,
	in_values_to_keep		IN	helper_pkg.T_NUMBER_ARRAY
)
AS
	v_values_to_keep		T_NUMERIC_TABLE DEFAULT helper_pkg.NumericArrayToTable(in_values_to_keep);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, GetCompoundSidFromFieldId(in_filter_field_id), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on filter with sid: '||GetCompoundSidFromFieldId(in_filter_field_id));
	END IF;
	
	DELETE FROM filter_value
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_field_id = in_filter_field_id
	   AND filter_value_id NOT IN (
		SELECT item FROM TABLE(v_values_to_keep));
END;


PROCEDURE GetFieldValues (
	in_filter_id			IN	filter.filter_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM v$filter_value
		 WHERE filter_id = in_filter_id;
END;

/**********************************************************************************/
/**********************   Filtering   *********************************************/
/**********************************************************************************/

PROCEDURE GetCompanySids (
	in_compound_filter_sid	IN  security_pkg.T_SID_ID,
	out_results				OUT security.T_ORDERED_SID_TABLE
)
AS
	v_list				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_compound_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on filter with sid: '||in_compound_filter_sid);
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- Get initial list of companies
	-- These are active companies with a relationship to the current logged in company
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_list
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, v$company_relationship cr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = cr.app_sid
		   AND c.company_sid = cr.company_sid 
	  );
	
	FOR r IN (
		SELECT f.filter_id, ft.helper_pkg
		  FROM filter f
		  JOIN v$filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.compound_filter_sid = in_compound_filter_sid
	) LOOP
		EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterSids(:filter_id, :input, :output);END;') USING r.filter_id, v_list, OUT v_list;
	END LOOP;
	
	out_results := v_list;
	
END;

END filter_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.helper_pkg
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
		SELECT 	invitation_expiration_days,
				site_name,
				admin_has_dev_access,
				support_email,
				newsflash_summary_sp,
				questionnaire_filter_class,
				last_generate_alert_dtm,
				scheduled_alert_intvl_minutes,
				chain_implementation,
				company_helper_sp,
				default_receive_sched_alerts,
				override_send_qi_path,
				login_page_message,
				invite_from_name_addendum,
				sched_alerts_enabled,
				link_host,
				NVL(top_company_sid, 0) top_company_sid,
				product_url,
				NVL(default_url, '/') default_url,
				allow_new_user_request,
				allow_company_self_reg
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

FUNCTION NumericArrayEmpty(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN NUMBER
AS
BEGIN
	RETURN CASE WHEN in_numbers.count = 1 AND in_numbers(1) IS NULL THEN 1 ELSE 0 END;
END;

FUNCTION NumericArrayToTable(
	in_numbers				IN T_NUMBER_ARRAY
) RETURN T_NUMERIC_TABLE
AS 
	v_table 	T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF in_numbers.COUNT = 0 OR (in_numbers.COUNT = 1 AND in_numbers(in_numbers.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN v_table;
    END IF;
	
	FOR i IN in_numbers.FIRST .. in_numbers.LAST
	LOOP
		BEGIN
			v_table.extend;
			v_table(v_table.COUNT) := T_NUMERIC_ROW( in_numbers(i), v_table.COUNT );
		END;
	END LOOP;
	RETURN v_table;
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
	
	IF security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon') THEN
		RETURN TRUE;
	END IF;
	
	RETURN FALSE;
END;

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_prev_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT');
	v_prev_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_prev_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	
	user_pkg.LogonAuthenticatedPath(v_app_sid, 'users/UserCreatorDaemon', 300, v_app_sid, v_act_id);
	
	IF in_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(in_company_sid);
	END IF;
	
	INSERT INTO ucd_logon
	(app_sid, ucd_act_id, previous_act_id, previous_user_sid, previous_company_sid)
	VALUES
	(v_app_sid, v_act_id, v_prev_act_id, v_prev_user_sid, v_prev_company_sid);
END;

PROCEDURE RevertLogonUCD
AS
	v_row					ucd_logon%ROWTYPE;
BEGIN
	-- let this blow up if nothing's found
	SELECT *
	  INTO v_row
	  FROM ucd_logon
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ucd_act_id = SYS_CONTEXT('SECURITY', 'ACT');
	
	user_pkg.Logoff(v_row.ucd_act_id);
	
	Security_pkg.SetACTAndSID(v_row.previous_act_id, v_row.previous_user_sid);
	Security_pkg.SetApp(v_row.app_sid);
	
	IF v_row.previous_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(v_row.previous_company_sid);
	END IF;
	
	DELETE FROM ucd_logon
	 WHERE ucd_act_id = v_row.ucd_act_id;
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

FUNCTION Flag (
	in_flags				IN  chain_pkg.T_FLAG,
	in_flag					IN  chain_pkg.T_FLAG
) RETURN chain_pkg.T_FLAG
AS
BEGIN
	IF security.bitwise_pkg.bitand(in_flags, in_flag) = 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;

FUNCTION GenerateSOName (
	in_company_name			IN  uninvited_supplier.name%TYPE,
	in_country_code			IN  uninvited_supplier.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')) || ' (' || v_cc || ')', '/', '\');
	--'--
END;

PROCEDURE UpdateSector (
	in_sector_id			IN	sector.sector_id%TYPE,
	in_description			IN	sector.description%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO sector (sector_id, description)
		VALUES (in_sector_id, in_description);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE sector
			   SET description = in_description
			 WHERE sector_id = in_sector_id
			   AND app_sid = security_pkg.GetApp;
	END;
END;

PROCEDURE DeleteSector (
	in_sector_id			IN	sector.sector_id%TYPE
)
AS
BEGIN
	UPDATE sector
	   SET active = chain_pkg.INACTIVE
	 WHERE app_sid = security_pkg.GetApp
	   AND sector_id = in_sector_id;
END;

PROCEDURE GetSectors (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT sector_id, description
		  FROM sector
		 WHERE app_sid = security_pkg.GetApp
		   AND active = chain_pkg.ACTIVE;
END;


END helper_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.invitation_pkg
IS

PROCEDURE AnnounceSids
AS
	v_user_name			varchar2(100);
	v_company_name		varchar2(100);
BEGIN
	SELECT so.name
	  INTO v_user_name
	  FROM security.securable_object so
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID');
	  /*
	  , v_company_name
	  FROM security.securable_object so, chain.company c
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID')
	   AND c.company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), SYS_CONTEXT('SECURITY', 'SID'));
	*/
	RAISE_APPLICATION_ERROR(-20001, '"'||v_user_name||'" of "'||v_company_name||'"');
END;

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
	v_to_company_active			company.active%TYPE;
BEGIN
	-- make sure that the expiration status' have been updated
	UpdateExpirations;
	
	-- if the invite type is SELF_REG_Q_INVITATION and the company is ACTIVE then cancel it
	-- as only the first user for any company is allowed to self register
	IF GetInvitationTypeByGuid(in_guid) = chain_pkg.SELF_REG_Q_INVITATION THEN 
		SELECT DECODE(c.deleted, 1, 0, c.active) active -- treat deleted companies as inactive 
		  INTO v_to_company_active 
		  FROM invitation i, company c
		 WHERE i.to_company_sid = c.company_sid
		   AND i.app_sid = c.app_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND LOWER(guid) = LOWER(in_guid);
		
		IF v_to_company_active = chain_pkg.ACTIVE THEN
			-- reject the invite as the company is active - therefore someone else has registered
			RejectInvitation(in_guid, chain_pkg.ANOTHER_USER_REGISTERED);
		END IF;
	END IF;

	BEGIN
		SELECT i.invitation_id, i.invitation_status_id, i.to_user_sid
		  INTO out_invitation_id, v_invitation_status_id, out_to_user_sid
		  FROM invitation i, v$company fc, v$company tc
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = tc.app_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.to_company_sid = tc.company_sid
		   AND LOWER(i.guid) = LOWER(in_guid)
       AND i.reinvitation_of_invitation_id IS NULL;
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
				WHEN v_invitation_status_id = chain_pkg.ANOTHER_USER_REGISTERED THEN chain_pkg.GUID_ANOTHER_USER_REGISTERED
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
		   AND LOWER(guid) = LOWER(in_guid)
       AND reinvitation_of_invitation_id IS NULL;
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

	-- You can only trigger the messsage if you are logged in as either the from or to company for the 
	-- expired invitation. This won't often be the case in RA (but is always the case in Maersk) so I have
	-- limited the search to invitations from or to the logged in company. This isn't foolproof but
	-- will ensure that you are not accepting an expired invitation (although the UI won't know it's expired).
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
		   AND (
				to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				OR from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
				)
	) LOOP
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.EXPIRED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;

		
		IF ((r.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION) OR (r.invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION)) THEN
			message_pkg.TriggerMessage (
				in_primary_lookup           => chain_pkg.INVITATION_EXPIRED,
				in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
				in_to_company_sid           => r.from_company_sid,
				in_to_user_sid              => chain_pkg.FOLLOWERS,
				in_re_company_sid           => r.to_company_sid,
				in_re_user_sid              => r.to_user_sid
			);
		END IF;
		
		chain_link_pkg.InvitationExpired(r.invitation_id, r.from_company_sid, r.to_company_sid);
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

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
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

	v_invitation_id := CreateInvitation(in_invitation_type_id, in_from_company_sid, in_from_user_sid, in_to_company_sid, in_to_user_sid, in_expiration_life_days, in_qnr_types, in_due_dtm_strs);

	OPEN out_cur FOR
		SELECT 	invitation_id, from_company_sid, from_user_sid, to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace, 
				expiration_dtm, invitation_status_id, invitation_type_id, cancelled_by_user_sid, cancelled_dtm, reinvitation_of_invitation_id
		  FROM invitation
		 WHERE invitation_id = v_invitation_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
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
				(v_invitation_id, in_qnr_types(i), in_from_user_sid, helper_pkg.StringToDate(in_due_dtm_strs(i)));
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
				company_pkg.AddSupplierFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);

				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	  	 	=> in_from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	  	 	=> in_to_company_sid,
					in_re_user_sid		  		=> in_to_user_sid
				);
				
				-- hook to customised system	
				chain_link_pkg.InviteCreated(v_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid);
			WHEN in_invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- TODO: Do we need to let anyone know that anything has happened?
				NULL;
			WHEN in_invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION THEN
				-- start the company relationship (it will be inactive if not already present, but in there)
				company_pkg.StartRelationship(in_from_company_sid, in_to_company_sid);
				--company_pkg.AddSupplierFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);
				--company_pkg.AddPurchaserFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);
				
				-- // TO DO - ignore invitation messaging atm				
				
				-- hook to customised system	
				chain_link_pkg.InviteCreated(v_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid);
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||in_invitation_type_id||') event notification not handled');
		END CASE;
		
		-- Migrate any uninvited companies of the same name and country
		FOR uninv IN (
			SELECT u.uninvited_supplier_sid
			  FROM uninvited_supplier u
			  JOIN v$company c ON u.app_sid = c.app_sid AND helper_pkg.GenerateSOName(u.name, u.country_code) = helper_pkg.GenerateSOName(c.name, c.country_code)
			 WHERE u.app_sid = security_pkg.GetApp
			   AND u.created_as_company_sid IS NULL
			   AND u.company_sid = in_from_company_sid
			   AND u.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND c.company_sid = in_to_company_sid
		) LOOP
			uninvited_pkg.MigrateUninvitedToCompany(uninv.uninvited_supplier_sid, in_to_company_sid);
		END LOOP;
	
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
	in_as_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_state_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	AcceptInvitation(in_guid, in_as_user_sid, v_state_cur);
END;

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_act_id						security_pkg.t_act_id;
BEGIN
	-- this is just a dummy check - it will get properly filled in later
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;

	AcceptInvitation(v_invitation_id, in_as_user_sid, NULL, NULL);
END;


PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
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
	
	AcceptInvitation(v_invitation_id, v_to_user_sid, in_full_name, in_password);
END;

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD
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

	helper_pkg.LogonUCD(v_to_company_sid);

	IF in_as_user_sid != v_to_user_sid THEN
		company_user_pkg.SetMergedStatus(v_to_user_sid, in_as_user_sid);
	END IF;
	-- set this to null so that i stop trying to use it!
	v_to_user_sid := NULL;
	
	-- activate the company
	company_pkg.ActivateCompany(v_to_company_sid);
	-- add the user to the company
	company_user_pkg.AddUserToCompany(v_to_company_sid, in_as_user_sid);
	company_pkg.AddPurchaserFollower(v_from_company_sid, v_to_company_sid, in_as_user_sid);
	
	IF v_invitation_type_id = chain_pkg.STUB_INVITATION AND v_approve_stub_registration = chain_pkg.INACTIVE THEN
		company_user_pkg.ApproveUser(v_to_company_sid, in_as_user_sid);
	END IF;

	-- see if the accepting user is an admin user
	SELECT COUNT(*)
	  INTO v_is_company_admin
	  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(v_act_id, v_to_company_sid, chain_pkg.ADMIN_GROUP)))
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

		IF ((v_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION) OR (v_invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION)) THEN
			-- we can activate the relationship now
			company_pkg.ActivateRelationship(v_from_company_sid, v_to_company_sid);
		END IF;
		
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
				
				message_pkg.TriggerMessage (
					in_primary_lookup           => chain_pkg.COMPLETE_QUESTIONNAIRE,
					in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
					in_to_company_sid           => i.to_company_sid,
					in_to_user_sid              => chain_pkg.FOLLOWERS,
					in_re_company_sid           => i.from_company_sid,
					in_re_questionnaire_type_id => i.questionnaire_type_id,
					in_due_dtm					=> i.requested_due_dtm
				);
								
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_ACCEPTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> i.from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> i.to_company_sid,
					in_re_user_sid		  		=> in_as_user_sid,
					in_re_questionnaire_type_id => i.questionnaire_type_id,
					in_due_dtm					=> i.requested_due_dtm
				);
				
				chain_link_pkg.InvitationAccepted(in_invitation_id, i.from_company_sid, i.to_company_sid);
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

	IF in_password IS NOT NULL THEN
		company_user_pkg.CompleteRegistration(in_as_user_sid, in_full_name, in_password);
	END IF;
	
	helper_pkg.RevertLogonUCD;
END;


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
)
AS
	v_company_sid				security_pkg.T_SID_ID;
	v_user_sid					security_pkg.T_SID_ID;
	v_event_id					event.event_id%TYPE;
BEGIN

	IF in_reason <> chain_pkg.REJECTED_NOT_EMPLOYEE AND in_reason <> chain_pkg.REJECTED_NOT_SUPPLIER AND in_reason <> chain_pkg.ANOTHER_USER_REGISTERED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid invitation rejection reason - '||in_reason);
	END IF;
	
	helper_pkg.LogonUCD;
	
	-- there's only gonna be one, but this is faster than storing the row and
	-- doing no_data_found checking (and we don't care if nothing's found)
	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)
		   AND REINVITATION_OF_INVITATION_ID IS NULL
	) LOOP

		-- delete the company if it's inactive and there are no other invitations
		-- TODO: Do we want to include expired invitations to prevent deletion?
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = r.to_company_sid
			   AND active = chain_pkg.INACTIVE
			   AND company_sid NOT IN (
					SELECT to_company_sid
					  FROM invitation
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND to_company_sid = r.to_company_sid
					   AND invitation_id <> r.invitation_id
					   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
					   AND reinvitation_of_invitation_id IS NULL);
			
			-- terminate the relationship if it is still PENDING
			company_pkg.TerminateRelationship(r.from_company_sid, r.to_company_sid, FALSE);
			
			company_pkg.DeleteCompany(v_company_sid);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- nothing to do
				NULL;
		END;

		-- delete the user if they've not registered and don't have another active/expired invitation
		BEGIN
			SELECT user_sid
			  INTO v_user_sid
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = r.to_user_sid
			   AND registration_status_id = chain_pkg.PENDING
			   AND user_sid NOT IN (
					SELECT to_user_sid
					  FROM invitation
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND to_user_sid = r.to_user_sid
					   AND invitation_id <> r.invitation_id
					   AND invitation_status_id IN (chain_pkg.ACTIVE, chain_pkg.EXPIRED)
					   AND reinvitation_of_invitation_id IS NULL);
			
			company_user_pkg.SetRegistrationStatus(v_user_sid, chain_pkg.REJECTED);
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
				-- add message for the purchaser company
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> r.from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> r.to_company_sid,
					in_re_user_sid		  		=> r.to_user_sid
				);
				
				chain_link_pkg.InvitationRejected(r.invitation_id, r.from_company_sid, r.to_company_sid, in_reason);

			WHEN r.invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- do nothing I guess....
				NULL;
			WHEN r.invitation_type_id = chain_pkg.SELF_REG_Q_INVITATION THEN
				-- // TO DO consider messaging later - not sure needed
				
				chain_link_pkg.InvitationRejected(r.invitation_id, r.from_company_sid, r.to_company_sid, in_reason);
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||r.invitation_type_id||') event notification not handled');
		END CASE;

	END LOOP;
	
	helper_pkg.RevertLogonUCD;
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
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN
	SELECT invitation_id
	  INTO v_invitation_id
	  FROM invitation
	 WHERE LOWER(guid) = LOWER(in_guid)
	   AND reinvitation_of_invitation_id IS NULL
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT to_company_sid
	  INTO out_company_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = v_invitation_id;	  
END;

PROCEDURE GetToUserSidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_user_sid				OUT security_pkg.T_SID_ID
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN
	SELECT invitation_id INTO v_invitation_id FROM invitation WHERE LOWER(guid) = LOWER(in_guid) AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT to_user_sid
	  INTO out_user_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = v_invitation_id;	  
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

PROCEDURE SearchInvitations (
	in_search				IN	VARCHAR2,
	in_invitation_status_id	IN	invitation.invitation_status_id%TYPE,
	in_from_user_sid		IN	security_pkg.T_SID_ID, -- TODO: Currently this is NULL for anyone or NOT NULL for [Me]
	in_sent_dtm_from		IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to			IN	invitation.sent_dtm%TYPE,
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_row_count			OUT	INTEGER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	-- Find all IDs that match the search criteria
	SELECT T_NUMERIC_ROW(invitation_id, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT i.invitation_id
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid -- Not using views as filters out rejected invitations as their details become deleted
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION
		   AND (LOWER(fcu.full_name) LIKE v_search
				OR LOWER(tcsru.full_name) LIKE v_search
				OR LOWER(tc.name) LIKE v_search 
				OR LOWER(tcsru.email) LIKE v_search)
		   AND (in_from_user_sid IS NULL OR from_user_sid = SYS_CONTEXT('SECURITY', 'SID') )
		   AND (in_invitation_status_id IS NULL
					OR in_invitation_status_id = i.invitation_status_id
					OR (in_invitation_status_id = chain_pkg.ACCEPTED AND i.invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED)
					OR (in_invitation_status_id = chain_pkg.REJECTED_NOT_EMPLOYEE AND i.invitation_status_id = chain_pkg.REJECTED_NOT_SUPPLIER))
		   AND (in_sent_dtm_from IS NULL OR in_sent_dtm_from <= i.sent_dtm)
		   AND (in_sent_dtm_to IS NULL OR in_sent_dtm_to+1 >= i.sent_dtm)
		   AND reinvitation_of_invitation_id IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page in the order specified
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT i.*, istat.description invitation_status, fc.name from_company_name, fcu.full_name from_full_name,
				   fcu.email from_email, tc.name to_company_name, tcsru.full_name to_full_name, tcsru.email to_email, tc.deleted company_deleted,
				   row_number() OVER (ORDER BY 
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'DESC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'DESC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'DESC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'DESC' THEN to_char(i.invitation_status_id)
						END DESC,
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'ASC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'ASC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'ASC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'ASC' THEN to_char(i.invitation_status_id)
						END ASC 
				   ) rn
			  FROM invitation i --TODO - should this be in a view
			  JOIN TABLE(v_results) r ON i.invitation_id = r.item
			  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
			  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
			  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
			  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
			  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
			  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY rn
		) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1;
END;

PROCEDURE DownloadInvitations (
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;

	OPEN out_cur FOR
		SELECT tcsru.full_name recipient_name, tcsru.email recipient_email, tc.name company, fcu.full_name invited_by,
			   i.sent_dtm invite_sent_date, istat.description status
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION    
	  ORDER BY sent_dtm DESC;
END;

PROCEDURE CancelInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE
)
AS
	v_row_count INTEGER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_row_count
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE);

	IF v_row_count<>1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot cancel an invitation that is not in an active state');
	END IF;

	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED, cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
		   cancelled_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE);
END;

PROCEDURE ReSendInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
	v_expiration_life_days	NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	SELECT invitation_id_seq.NEXTVAL
	  INTO v_invitation_id
	  FROM dual;

	-- Set status of origainl invitation to cancelled if it is active
	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED,
	       cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
	       cancelled_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	   AND invitation_status_id = chain_pkg.ACTIVE
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT invitation_expiration_days 
	  INTO v_expiration_life_days
	  FROM customer_options;

	-- copy original invitation into a new invitation
	INSERT INTO invitation (app_sid, invitation_id, from_company_sid, from_user_sid,
		to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace, expiration_dtm,
		invitation_status_id, invitation_type_id)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id,
		   from_company_sid, -- should we use SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') or original here?
		   SYS_CONTEXT('SECURITY', 'SID'), to_company_sid, to_user_sid, SYSDATE, guid, expiration_grace,
		   SYSDATE + v_expiration_life_days, chain_pkg.ACTIVE, invitation_type_id
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE invitation
	   SET reinvitation_of_invitation_id = v_invitation_id
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO invitation_qnr_type (app_sid, invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id, questionnaire_type_id, SYS_CONTEXT('SECURITY', 'SID'),
		   SYSDATE + v_expiration_life_days
	  FROM invitation_qnr_type
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur FOR
		SELECT * 
		  FROM invitation
		 WHERE invitation_id = v_invitation_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qt.*
		  FROM questionnaire_type qt
		  JOIN invitation_qnr_type iqt ON iqt.questionnaire_type_id = qt.questionnaire_type_id 
		  							  AND iqt.app_sid = qt.app_sid
		 WHERE iqt.invitation_id = in_invitation_id
		   AND iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT invitation_status_id id,
			   CASE WHEN in_for_filter = 1 THEN filter_description ELSE description END description
		  FROM invitation_status
		 WHERE in_for_filter <> 1
			OR in_for_filter=1
		   AND filter_description IS NOT NULL;
END;


END invitation_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.message_pkg
IS

DIRECT_TO_USER				CONSTANT NUMBER := 0;
TO_ENTIRE_COMPANY			CONSTANT NUMBER := 1;
TO_OTHER_COMPANY_USER		CONSTANT NUMBER := 2;

/**********************************************************************************
	PRIVATE FUNCTIONS
**********************************************************************************/
FUNCTION GetDefinition (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
) RETURN v$message_definition%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE;
BEGIN
	-- Grab the definition data
	SELECT *
	  INTO v_dfn
	  FROM v$message_definition
	 WHERE message_definition_id = in_message_definition_id;

	RETURN v_dfn;
END;

PROCEDURE CreateDefaultMessageParam (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_param_name				IN  message_param.param_name%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO default_message_param
		(message_definition_id, param_name, lower_param_name)
		VALUES
		(in_message_definition_id, in_param_name, LOWER(in_param_name));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
END;

PROCEDURE CreateDefinitionOverride (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO message_definition
		(message_definition_id)
		VALUES
		(in_message_definition_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION GetRecipientId (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	-- try to get the recipient id
	BEGIN	
		SELECT recipient_id
		  INTO v_r_id
		  FROM recipient
		 WHERE NVL(to_company_sid, 0) = NVL(in_company_sid, 0)
		   AND NVL(to_user_sid, 0) = NVL(in_user_sid, 0);
	EXCEPTION
		-- if we don't have an id for this combination, create one
		WHEN NO_DATA_FOUND THEN
			v_r_id := CreateRecipient(in_company_sid, in_user_sid);
		-- if we find more than one match, then send it off to the link_pkg
		WHEN TOO_MANY_ROWS THEN
			v_r_id := chain_link_pkg.FindMessageRecipient(in_message_id, in_company_sid, in_user_sid);
			
			IF v_r_id IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Could not resolve to a single recipient id using company_sid='||in_company_sid||' and user_sid='||in_user_sid);
			END IF;
	END;

	RETURN v_r_id;
END;

FUNCTION FindMessage_ (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(in_message_definition_id);
	v_msg						message%ROWTYPE;
	v_message_id				message.message_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	IF in_to_user_sid <> chain_pkg.FOLLOWERS THEN
		v_to_user_sid := in_to_user_sid;
	END IF;
	
	IF v_to_user_sid IS NULL AND in_to_company_sid IS NULL THEN
		RETURN v_msg;
	END IF;	
	
	SELECT MAX(message_id)
	  INTO v_message_id
	  FROM (
			SELECT message_id
			  FROM v$message_recipient
			 WHERE message_definition_id = in_message_definition_id
			   AND (v_to_user_sid IS NULL OR to_user_sid = v_to_user_sid)
			   AND NVL(to_company_sid, 0) 			= NVL(in_to_company_sid, 0)
			   AND NVL(re_company_sid, 0) 			= NVL(in_re_company_sid, 0)
			   AND NVL(re_user_sid, 0) 				= NVL(in_re_user_sid, 0)
			   AND NVL(re_questionnaire_type_id, 0) = NVL(in_re_questionnaire_type_id, 0)
			   AND NVL(re_component_id, 0) 			= NVL(in_re_component_id, 0)
			 ORDER BY last_refreshed_dtm DESC
		   )
	 WHERE rownum = 1;
		
	RETURN GetMessage(v_message_id);
END;

FUNCTION GetUserRecipientIds (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
) RETURN T_NUMERIC_TABLE
AS
	v_vals 						T_NUMERIC_TABLE;
BEGIN
	SELECT T_NUMERIC_ROW(recipient_id, addressed_to)
	  BULK COLLECT INTO v_vals
	  FROM (
	  		SELECT recipient_id, DIRECT_TO_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid = in_user_sid
			   AND (to_company_sid IS NULL OR to_company_sid = in_company_sid)
			 UNION ALL
			SELECT recipient_id, TO_ENTIRE_COMPANY addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid IS NULL
			   AND to_company_sid = in_company_sid
			 UNION ALL
			SELECT recipient_id, TO_OTHER_COMPANY_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid <> in_user_sid
			   AND to_company_sid = in_company_sid
	  );

	RETURN v_vals;
END;



/**********************************************************************************
	INTERNAL FUNCTIONS
**********************************************************************************/
FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
BEGIN
	RETURN Lookup(in_primary_lookup, chain_pkg.NONE_IMPLIED);
END;

FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	SELECT message_definition_id
	  INTO v_dfn_id
	  FROM message_definition_lookup
	 WHERE primary_lookup_id = in_primary_lookup
	   AND secondary_lookup_id = in_secondary_lookup;
	
	RETURN v_dfn_id;
END;


/**********************************************************************************
	GLOBAL MANAGEMENT
**********************************************************************************/
PROCEDURE DefineMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE,
	in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
	in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
	in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessage can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO message_definition_lookup
		(message_definition_id, primary_lookup_id, secondary_lookup_id)
		VALUES
		(message_definition_id_seq.nextval, in_primary_lookup, in_secondary_lookup)
		RETURNING message_definition_id INTO v_dfn_id;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			v_dfn_id := Lookup(in_primary_lookup, in_secondary_lookup);
	END;
	
	BEGIN
		INSERT INTO default_message_definition
		(message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES
		(v_dfn_id, in_message_template, in_priority, in_repeat_type, in_addressing_type, in_completion_type, in_completed_template, in_helper_pkg, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE default_message_definition
			   SET message_template = in_message_template, 
			       message_priority_id = in_priority, 
			       repeat_type_id = in_repeat_type, 
			       addressing_type_id = in_addressing_type, 
			       completion_type_id = in_completion_type, 
			       completed_template = in_completed_template, 
			       helper_pkg = in_helper_pkg,
			       css_class = in_css_class
			 WHERE message_definition_id = v_dfn_id;
	END;
END;

PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE DEFAULT NULL,
	in_href						IN  message_param.href%TYPE DEFAULT NULL,
	in_value					IN  message_param.value%TYPE DEFAULT NULL	
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessageParam can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	
	UPDATE default_message_param
	   SET value = in_value, 
	       href = in_href, 
	       css_class = in_css_class
	 WHERE message_definition_id = v_dfn_id
	   AND param_name = in_param_name;
END;

/**********************************************************************************
	APPLICATION MANAGEMENT
**********************************************************************************/
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefinitionOverride(v_dfn_id);
	
	UPDATE message_definition
	   SET message_template = in_message_template, 
	       message_priority_id = in_priority, 
	       completed_template = in_completed_template, 
	       helper_pkg = in_helper_pkg, 
	       css_class = in_css_class
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_definition_id = v_dfn_id;
	
	-- Reset any parameters previously set up to defaults as there's no other way to do this other than manually
	-- But it means if you want to change the text you'll need to redefine the parameters
	DELETE FROM message_param
	 WHERE app_sid =  SYS_CONTEXT('SECURITY', 'APP')
	   AND message_definition_id = v_dfn_id;
	
END;

PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	CreateDefinitionOverride(v_dfn_id);
	
	BEGIN
		INSERT INTO message_param
		(message_definition_id, param_name, value, href, css_class)
		VALUES
		(v_dfn_id, in_param_name, in_value, in_href, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE message_param
			   SET value = in_value, 
			       href = in_href, 
			       css_class = in_css_class
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND message_definition_id = v_dfn_id
			   AND param_name = in_param_name;    
	END;
END;

/**********************************************************************************
	PUBLIC METHODS
**********************************************************************************/
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	INSERT INTO recipient
	(recipient_id, to_company_sid, to_user_sid)
	VALUES
	(recipient_id_seq.NEXTVAL, in_company_sid, in_user_sid)
	RETURNING recipient_id INTO v_r_id;
	
	RETURN v_r_id;
END;

PROCEDURE TriggerMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_due_dtm					IN  message.due_dtm%TYPE						DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(v_dfn_id);
	v_msg						message%ROWTYPE;
	v_msg_id					message.message_id%TYPE;
	v_r_id						recipient.recipient_id%TYPE;
	v_find_by_user_sid			security_pkg.T_SID_ID;	
	v_to_users					T_NUMBER_LIST;
	v_cnt						NUMBER;
BEGIN
	
	---------------------------------------------------------------------------------------------------
	-- validate message addressing

	IF v_dfn.addressing_type_id = chain_pkg.USER_ADDRESS THEN
		IF in_to_company_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid cannot be set for USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for USER_ADDRESS messages');
		END IF;
	ELSIF v_dfn.addressing_type_id = chain_pkg.COMPANY_ADDRESS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_ADDRESS messages');
		ELSIF in_to_user_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid cannot be set for COMPANY_ADDRESS messages');
		END IF;
	ELSE
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for COMPANY_USER_ADDRESS messages');
		END IF;
	END IF;	
	
	---------------------------------------------------------------------------------------------------
	-- manage pseudo user codes
	IF in_to_user_sid = chain_pkg.FOLLOWERS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for FOLLOWERS psuedo addressed messages');
		ELSIF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Re company sid must be set for FOLLOWERS psuedo addressed messages');
		END IF;
	
		IF in_secondary_lookup = chain_pkg.SUPPLIER_MSG THEN
			v_to_users := company_pkg.GetPurchaserFollowers(in_re_company_sid, in_to_company_sid);
		ELSIF in_secondary_lookup = chain_pkg.PURCHASER_MSG THEN
			v_to_users := company_pkg.GetSupplierFollowers(in_to_company_sid, in_re_company_sid);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Secondary lookup must be specified as SUPPLIER_MSG or PURCHASER_MSG for FOLLOWERS psuedo addressed messages');
		END IF;
		
		IF v_to_users IS NULL OR v_to_users.COUNT = 0 THEN
			--RAISE_APPLICATION_ERROR(-20001, 'TODO: figure out how we deal with messages addressed followers when no followers exist: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id);
			-- lets' try to use the UCD as default
			helper_pkg.LogonUCD;
			v_to_users.extend(1);
			v_to_users(v_to_users.COUNT) := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon');
			helper_pkg.RevertLogonUCD;
		END IF;
				
	ELSIF in_to_user_sid IS NOT NULL THEN
		
		v_to_users := T_NUMBER_LIST(in_to_user_sid);
		v_find_by_user_sid := in_to_user_sid;
		
	ELSE
		
		v_to_users := T_NUMBER_LIST(NULL);
		
	END IF;
	
	---------------------------------------------------------------------------------------------------
	-- get the message if it exists already 
	v_msg := FindMessage_(
		v_dfn_id, 
		in_to_company_sid, 
		v_find_by_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
		
	---------------------------------------------------------------------------------------------------
	-- apply repeatability
	IF v_msg.message_id IS NOT NULL THEN
		IF v_dfn.repeat_type_id = chain_pkg.NEVER_REPEAT THEN	

			IF v_msg.message_id IS NOT NULL THEN 
				RETURN;
			END IF;
		
		ELSIF v_dfn.repeat_type_id = chain_pkg.REPEAT_IF_CLOSED THEN

			IF v_msg.completed_dtm IS NULL THEN
				RETURN;
			END IF;

		ELSIF v_dfn.repeat_type_id = chain_pkg.REFRESH_OR_REPEAT THEN

			IF v_msg.completed_dtm IS NULL THEN
				
				INSERT INTO message_refresh_log
				(message_id, refresh_index)
				SELECT message_id, MAX(refresh_index) + 1
				  FROM message_refresh_log
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND message_id = v_msg.message_id
				 GROUP BY message_id;
				
				DELETE FROM user_message_log
				 WHERE message_id = v_msg.message_id;
			
				chain_link_pkg.MessageRefreshed(v_dfn.helper_pkg, in_to_company_sid, v_msg.message_id);
				
				RETURN;

			END IF;
		
		END IF;
	END IF;

	---------------------------------------------------------------------------------------------------
	-- create the message entry 
	

	
	INSERT INTO message
	(message_id, message_definition_id, re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, due_dtm)
	VALUES
	(message_id_seq.NEXTVAL, v_dfn_id, in_re_company_sid, in_re_user_sid, in_re_questionnaire_type_id, in_re_component_id, in_due_dtm)
	RETURNING message_id INTO v_msg_id;

	SELECT COUNT(*) INTO v_cnt FROM chain_user WHERE user_sid = SYS_CONTEXT('SECURITY','SID');
	
	-- you can't do this during setup - e.g. creating the first company as no user is logged on that is in chain_user - throws ref integrity error
	IF v_cnt > 0 THEN	
		INSERT INTO message_refresh_log
		(message_id, refresh_index)
		VALUES
		(v_msg_id, 0);
	END IF;
	
	FOR i IN v_to_users.FIRST .. v_to_users.LAST
	LOOP
		v_r_id := GetRecipientId(v_msg_id, in_to_company_sid, v_to_users(i));

		INSERT INTO message_recipient
		(message_id, recipient_id)
		VALUES
		(v_msg_id, v_r_id);
		
	END LOOP;
	
	chain_link_pkg.MessageCreated(v_dfn.helper_pkg, in_to_company_sid, v_msg_id);
END;

PROCEDURE CompleteMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msg						message%ROWTYPE;
BEGIN
	v_msg := FindMessage_(
		v_dfn_id, 
		in_to_company_sid, 
		in_to_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
	
	IF v_msg.message_id IS NULL THEN
		-- crazy long message because if it blows up, it will be tough to figure out why - this may help...
		RAISE_APPLICATION_ERROR(-20001, 'Message could not be completed because it was not found: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id);
	END IF;
	
	CompleteMessageById(v_msg.message_id);
	
END;

PROCEDURE CompleteMessageIfExists (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msg						message%ROWTYPE;
	v_completed_dtm				message.completed_dtm%TYPE;
BEGIN
	v_msg := FindMessage_(
		v_dfn_id, 
		in_to_company_sid, 
		in_to_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
	
	IF v_msg.message_id IS NOT NULL THEN
		
		SELECT completed_dtm
		  INTO v_completed_dtm
		  FROM message
		 WHERE app_sid = security_pkg.GetApp
		   AND message_id = v_msg.message_id;
		
		IF v_completed_dtm IS NULL THEN
			CompleteMessageById(v_msg.message_id);
		END IF;
		
	END IF;
	
END;

PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
)
AS
	v_helper_pkg				message_definition.helper_pkg%TYPE;
	v_to_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	UPDATE message
	   SET completed_dtm = SYSDATE,
	       completed_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_id = in_message_id
	   AND message_definition_id IN (
	   		SELECT message_definition_id
	   		  FROM v$message_definition
	   		 WHERE completion_type_id <> chain_pkg.NO_COMPLETION
	   		);	

	IF SQL%ROWCOUNT > 0 THEN
		SELECT md.helper_pkg
		  INTO v_helper_pkg
		  FROM message m, v$message_definition md
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND m.message_id = in_message_id;
		
		SELECT MAX(r.to_company_sid) -- there may be 0 or more entries, but all have the same company sid
		  INTO v_to_company_sid
		  FROM recipient r, message_recipient mr
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.app_sid = r.app_sid
		   AND mr.recipient_id = r.recipient_id
		   AND mr.message_id = in_message_id;		   
		
		chain_link_pkg.MessageCompleted(v_helper_pkg, v_to_company_sid, in_message_id);
	END IF;
END;

FUNCTION FindMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE
AS
BEGIN
	RETURN FindMessage_(
		Lookup(in_primary_lookup, in_secondary_lookup), 
		in_to_company_sid, 
		in_to_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
END;

PROCEDURE GetMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_filter_for_priority		IN  NUMBER,
	in_filter_for_pure_messages	IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_page						IN  NUMBER,
	out_stats_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_recipient_ids				T_NUMERIC_TABLE DEFAULT GetUserRecipientIds(in_to_company_sid, in_to_user_sid);
	v_user_level_messaging		company.user_level_messaging%TYPE;
	v_has_show_stoppers			NUMBER(10);
	v_page						NUMBER(10) DEFAULT in_page;
	v_count						NUMBER(10);
BEGIN
	
	-- TODO: turn this and the following query back into a single query
	INSERT INTO tt_message_search
	(	message_id, message_definition_id, to_company_sid, to_user_sid, 
		re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
		completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
	)
	SELECT m.message_id, m.message_definition_id, in_to_company_sid, 
			CASE WHEN md.addressing_type_id = chain_pkg.USER_ADDRESS THEN m.to_user_sid ELSE NULL END, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			m.completed_by_user_sid, m.last_refreshed_by_user_sid, 
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
	  FROM v$message_recipient m, v$message_definition md, TABLE(v_recipient_ids) r
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.recipient_id = r.item
	   AND m.message_definition_id = md.message_definition_id
	   AND md.message_priority_id <> chain_pkg.HIDDEN
	   AND (
			   -- the message is privately addressed to the user
			   (md.addressing_type_id = chain_pkg.USER_ADDRESS 			AND r.pos = DIRECT_TO_USER)
			   -- the message is addressed to the entire company
			OR (md.addressing_type_id = chain_pkg.COMPANY_ADDRESS 		AND r.pos = TO_ENTIRE_COMPANY)
				-- the message is address to the comapny and user 
			OR (md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	AND r.pos = DIRECT_TO_USER)
				-- we're not using user level addressing, and the messsage is addressed to the company, but another user within the company
	   	   );
	
	-- remove any messages that:
	-- 		1. involve deleted companies 
	--		2. require completion 
	-- 		3. have not been completed
	--		4. are not invitation rejection messages
	DELETE FROM tt_message_search
	 WHERE message_id IN (
	 	SELECT m.message_id
	 	  FROM message m, v$message_definition md, company c, message_definition_lookup mdl
	 	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND m.message_definition_id = md.message_definition_id
	 	   AND m.message_definition_id = mdl.message_definition_id
	 	   AND m.re_company_sid = c.company_sid
	 	   AND c.deleted = chain_pkg.DELETED
	 	   AND md.completion_type_id IN (chain_pkg.ACKNOWLEDGE, chain_pkg.CODE_ACTION)
	 	   AND m.completed_dtm IS NULL
	 	   AND mdl.primary_lookup_id <> chain_pkg.INVITATION_REJECTED
	 );
	
	SELECT NVL(MIN(user_level_messaging), chain_pkg.INACTIVE)
	  INTO v_user_level_messaging
	  FROM v$company
	 WHERE company_sid = in_to_company_sid;
	 
	IF v_user_level_messaging = chain_pkg.INACTIVE THEN
		-- TODO: turn this and the previous query back into a single query
		INSERT INTO tt_message_search
		(	message_id, message_definition_id, to_company_sid, to_user_sid, 
			re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
			completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
		)
		SELECT m.message_id, m.message_definition_id, in_to_company_sid, NULL, 
				m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
				m.completed_by_user_sid, m.last_refreshed_by_user_sid, 
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
		  FROM v$message m, v$message_definition md
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND md.message_priority_id <> chain_pkg.HIDDEN
		   AND md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	
		   AND m.message_id NOT IN (SELECT message_id FROM tt_message_search)
		   AND m.message_id IN (
				SELECT mr.message_id
				  FROM message_recipient mr, TABLE(v_recipient_ids) r
				 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND mr.recipient_id = r.item
				   AND r.pos = TO_OTHER_COMPANY_USER
			); 
	END IF;
	
	IF in_filter_for_priority <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NOT NULL;
		
		DELETE FROM tt_message_search
		 WHERE message_definition_id IN (
		 	SELECT message_definition_id
		 	  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		 );
		
		SELECT COUNT(*)
		  INTO v_has_show_stoppers
		  FROM tt_message_search ms, v$message_definition md
		 WHERE ms.message_definition_id = md.message_definition_id 
		   AND md.message_priority_id = chain_pkg.SHOW_STOPPER;
		
		IF v_has_show_stoppers > 0 THEN
			DELETE FROM tt_message_search
			 WHERE message_definition_id NOT IN (
				SELECT message_definition_id
				  FROM v$message_definition
				 WHERE message_priority_id = chain_pkg.SHOW_STOPPER
		 		);		
		END IF;
	END IF;

	IF in_filter_for_pure_messages <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NULL
		   AND message_definition_id NOT IN (
		   	SELECT message_definition_id
			  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		   );
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM tt_message_search;
	
	OPEN out_stats_cur FOR
		SELECT v_count total_rows FROM DUAL;

	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_message_search
		 WHERE message_id NOT IN (
			SELECT message_id
			  FROM (
				SELECT message_id, rownum rn
				  FROM (
					SELECT message_id
					  FROM tt_message_search
					 ORDER BY order_by_dtm DESC
					)
			  )
			 WHERE rn > in_page_size * (v_page - 1)
			   AND rn <= in_page_size * v_page
		 );		 
	END IF;


	UPDATE tt_message_search o
	   SET viewed_dtm = (
	   		SELECT viewed_dtm
	   		  FROM user_message_log i
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND i.message_id = o.message_id
  		);
	
	INSERT INTO user_message_log
	(message_id, user_sid, viewed_dtm)
	SELECT message_id, SYS_CONTEXT('SECURITY', 'SID'), SYSDATE
	  FROM tt_message_search
	 WHERE message_id NOT IN (
	 	SELECT message_id
	 	  FROM user_message_log
	 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 );	 

	OPEN out_message_cur FOR
		SELECT m.message_id, m.message_definition_id, md.message_template, md.completion_type_id, m.completed_by_user_sid, 
			   md.completed_template, md.css_class, ms.to_company_sid, ms.to_user_sid, 
			   m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			   m.completed_dtm, m.created_dtm, m.last_refreshed_dtm, m.last_refreshed_by_user_sid, m.due_dtm, SYSDATE now_dtm,
			   CASE WHEN in_to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
			   		 AND m.completed_dtm IS NULL 
			   		 AND md.completion_type_id = chain_pkg.ACKNOWLEDGE 
			   		THEN 1 
			   		ELSE 0 
			   		 END requires_acknowledge
		  FROM v$message m, v$message_definition md, tt_message_search ms
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND m.message_id = ms.message_id
		 ORDER BY ms.order_by_dtm DESC;
		   
	OPEN out_message_param_cur FOR
		SELECT message_definition_id, param_name, value, href, css_class
		  FROM v$message_param 
		 WHERE message_definition_id IN (
		 		SELECT message_definition_id FROM tt_message_search
		 	   );
		 
	OPEN out_company_cur FOR
		SELECT company_sid, name 
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid IN (
		   		SELECT to_company_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT re_company_sid FROM tt_message_search
		   	   );

	OPEN out_user_cur FOR
		SELECT csr_user_sid user_sid, full_name
		  FROM csr.csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid  IN (
		   		SELECT to_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT re_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT completed_by_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT last_refreshed_by_user_sid FROM tt_message_search
		   	   );
		
	OPEN out_questionnaire_type_cur FOR
		SELECT questionnaire_type_id, name, edit_url, view_url
		  FROM questionnaire_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id IN (
		 		SELECT re_questionnaire_type_id FROM tt_message_search
		 	   );

	OPEN out_component_cur FOR
		SELECT component_id, description
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id IN (
		 		SELECT re_component_id FROM tt_message_search
		 	   );
END;

FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE
AS
	v_msg						message%ROWTYPE;
BEGIN
	BEGIN
		SELECT *
		  INTO v_msg
		  FROM message
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND message_id = in_message_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_msg;
END;



END message_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.metric_pkg
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

CREATE OR REPLACE PACKAGE BODY chain.newsflash_pkg
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

CREATE OR REPLACE PACKAGE BODY chain.product_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_product_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to products for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to products for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

PROCEDURE CollectToCursor (
	in_product_ids			IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.pseudo_root_component_id, p.active, p.code1, p.code2, p.code3, p.notes,
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				CASE WHEN published=1 THEN 'Closed' ELSE 'Open' END status,
				p.published, p.last_published_dtm, p.last_published_by_user_sid
		  FROM v$product p, TABLE(in_product_ids) i
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = i.item
		 ORDER BY i.pos;
END;

/**********************************************************************************
	PRODUCT CALLS
**********************************************************************************/

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE,
    in_notes				IN  product.notes%TYPE
) RETURN NUMBER
AS
	v_product_id			product.product_id%TYPE;
	v_pct					product_code_type%ROWTYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	-- this will do in the place of a NOT NULL on the column (not all components require a code)
	IF in_code1 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL component_code (code1)');
	END IF;
	
	v_product_id := component_pkg.SaveComponent(in_product_id, chain_pkg.PRODUCT_COMPONENT, in_description, in_code1);
	
	BEGIN
		-- we select this into a variable to be sure that the entry exists, an insert based on select would fail silently
		SELECT *
		  INTO v_pct
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
		-- Do these on save only, rather than forcing a table constraint, so that the mandatoryness can be changed by the user without constraint errors
		IF v_pct.code2_mandatory=1 AND in_code2 IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL code2 when product_code_type has code2_mandatory set');
		END IF;
		IF v_pct.code3_mandatory=1 AND in_code3 IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL code3 when product_code_type has code2_mandatory set');
		END IF;
		
		INSERT INTO product
		(product_id, pseudo_root_component_id, code2, code3, notes)
		VALUES
		(v_product_id, v_product_id, in_code2, in_code3, in_notes);
		
		chain_link_pkg.AddProduct(v_product_id);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE product
			   SET code2 = in_code2,
			       code3 = in_code3,
			       notes = in_notes
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   		   AND product_id = v_product_id;
	END;

	
	RETURN v_product_id;
END;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
    component_pkg.DeleteComponent(in_product_id);    
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
	v_count_mapped			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count_mapped
	  FROM v$purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND deleted=chain_pkg.NOT_DELETED
	   AND supplier_product_id = in_component_id
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF v_count_mapped>0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not delete component with id: '||in_component_id||'. Component is mapped to purchased components of another company');
	END IF;
END;

PROCEDURE PublishProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product
	   SET published = 1,
	       last_published_by_user_sid = security_pkg.GetSid,
	       last_published_dtm = SYSDATE
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id;
	
	IF NOT HasMappedUnpublishedProducts(component_pkg.GetCompanySid(in_product_id)) THEN
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> component_pkg.GetCompanySid(in_product_id)
		);
	END IF;
END;

PROCEDURE EditProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product
	   SET published = 0
	 WHERE app_sid = security_pkg.GetApp
	   AND product_id = in_product_id;
	
	IF HasMappedUnpublishedProducts(component_pkg.GetCompanySid(in_product_id)) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> component_pkg.GetCompanySid(in_product_id)
		);
	END IF;
END;


PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_READ);

	SELECT T_NUMERIC_ROW(product_id, null)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||in_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT product_id
		  FROM v$product
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND deleted = chain_pkg.NOT_DELETED
		 ORDER BY LOWER(description), LOWER(code1)
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

-- this is required for component implementation
PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetProduct(in_component_id, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT p.product_id
		  FROM v$product p, TT_COMPONENT_TREE ct
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PRODUCT_COMPONENT
		   AND p.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Allow search with old parameters as app_code release will occur on servers separately.
	-- Once released, it will be safe to remove this proc
	SearchProductsSold(in_search, in_purchaser_company_sid, in_supplier_company_sid,
						in_only_show_need_review, in_only_show_empty_codes, 0,
						in_show_deleted, in_start, in_page_size, in_sort_by, in_sort_dir,
						out_count_cur, out_product_cur, out_purchaser_cur, out_supplier_cur);
END;

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_only_show_empty_codes	IN  NUMBER,
	in_only_show_unpublished	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_top_component_ids			T_NUMERIC_TABLE;
	v_product_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200) DEFAULT 'LOWER(p.'||in_sort_by||') '||in_sort_dir;
	v_sort_sql					VARCHAR2(4000);
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
	v_pct						product_code_type%ROWTYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'code1', 'code2', 'code3', 'status') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	IF LOWER(in_sort_by) = 'status' THEN
		-- clear the order by as the only status that we have right now is 'Open'
		v_order_by := '';
	ELSIF LOWER(in_sort_by) = 'customer' THEN
		-- remap the order by
		v_order_by := 'LOWER(t.value) '||in_sort_dir;
	END IF;
	
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(p.description) '||in_sort_dir;
	END IF;
	
	-- Get the product code types ready for filtering on empty codes
	SELECT *
	  INTO v_pct
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id)
	SELECT product_id
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   -- don't show deleted unless it's been asked for
	   AND (deleted = chain_pkg.NOT_DELETED OR in_show_deleted = 1)
	   -- show all products unless we want to only show needs review ones
	   AND ((need_review = chain_pkg.ACTIVE AND in_only_show_need_review = 1) OR in_only_show_need_review = 0)
	   AND ((published = 0 AND in_only_show_unpublished = 1) OR in_only_show_unpublished = 0)
	   AND (((code2 IS NULL AND v_pct.code_label2 IS NOT NULL) OR (code3 IS NULL AND v_pct.code_label3 IS NOT NULL)) OR in_only_show_empty_codes = 0)
	   AND (   LOWER(description) LIKE v_search
			OR LOWER(code1) LIKE v_search
			OR LOWER(code2) LIKE v_search
			OR LOWER(code3) LIKE v_search
		   );

	-- if we're looking at a specific purchaser company, remove any products that we don't supply to them
	IF in_purchaser_company_sid IS NOT NULL THEN
		
		DELETE 
		  FROM TT_ID 
		 WHERE id NOT IN (
		 	SELECT supplier_product_id
		 	  FROM v$purchased_component
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND company_sid = in_purchaser_company_sid
		 	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 );
		 
	END IF;
	
	-- if we're looking at a specific supplier company, then we need to drill down the component tree and find all of our purchased components
	IF in_supplier_company_sid IS NOT NULL THEN
		
		SELECT T_NUMERIC_ROW(id, rownum)
	  	  BULK COLLECT INTO v_top_component_ids
	  	  FROM TT_ID;
		
		component_pkg.RecordTreeSnapshot(v_top_component_ids);
		v_record_called := TRUE;
		
		DELETE 
		  FROM TT_ID
		 WHERE id NOT IN (
		 	SELECT ct.top_component_id
		 	  FROM TT_COMPONENT_TREE ct, TT_ID i, v$purchased_component pc
		 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND pc.component_id = ct.child_component_id
		 	   AND (pc.supplier_company_sid = in_supplier_company_sid)
		 	   AND ct.top_component_id = i.id
		 	   AND pc.deleted = chain_pkg.NOT_DELETED
		 );
		 
	END IF;
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	
	-- if the sort by is a column in the v$product view...
	IF LOWER(in_sort_by) IN ('description', 'code1', 'code2', 'code3', 'status') THEN
	
		v_sort_sql := ''||
			'	SELECT p.product_id '||
			'	  FROM v$product p, TT_ID t '||
			'	 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
			'	   AND p.product_id = t.id '||
			'	 ORDER BY '||v_order_by;
	
	/* -- the page doesn't let you do this!
	ELSIF LOWER(in_sort_by) = 'customer' THEN
	
		v_sort_sql := ''||
			'	SELECT id product_id, min(rn) '||
			'	  FROM ( '||
			'		SELECT i.id, rownum rn '||
			'		  FROM ( '||
			'		  	SELECT id  '||
			'		  	  FROM TT_ORDERED_PARAM  '||
			'			 ORDER BY '||v_order_by||
			'		  	 ) i '||
			'		 ) '||
			'	GROUP BY id';
	*/			
	END IF;
	
	EXECUTE IMMEDIATE ''||
		'UPDATE TT_ID i '||
		'   SET position = ( '||
		'		SELECT r.rn '||
		'		  FROM ('||
		'			SELECT product_id, rownum rn '||
		'			  FROM ('||v_sort_sql||') '||
		'			) r '||
		'		 WHERE i.id = r.product_id '||
		'   )';
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL(in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_purchaser_cur FOR
		SELECT DISTINCT pc.supplier_product_id product_id, c.company_sid, c.name
		  FROM v$purchased_component pc, v$company c, TT_ID i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = i.id
		   AND pc.deleted = chain_pkg.NOT_DELETED
	 	 ORDER BY LOWER(c.name);
	
	
	IF NOT v_record_called THEN
		SELECT T_NUMERIC_ROW(id, rownum)
		  BULK COLLECT INTO v_top_component_ids
		  FROM TT_ID;

		component_pkg.RecordTreeSnapshot(v_top_component_ids);
	END IF;
	
	OPEN out_supplier_cur FOR
		SELECT *
		  FROM (
			SELECT i.id product_id, c.company_sid, c.name
			  FROM TT_COMPONENT_TREE ct
			  JOIN TT_ID i ON ct.top_component_id = i.id
			  JOIN v$purchased_component pc ON pc.component_id = ct.child_component_id
			  JOIN v$company c ON pc.app_sid = c.app_sid AND pc.supplier_company_sid = c.company_sid
			 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND pc.deleted = chain_pkg.NOT_DELETED
			UNION
			SELECT i.id product_id, us.uninvited_supplier_sid, us.name
			  FROM TT_COMPONENT_TREE ct
			  JOIN TT_ID i ON ct.top_component_id = i.id
			  JOIN v$purchased_component pc ON pc.component_id = ct.child_component_id
			  JOIN uninvited_supplier us ON pc.app_sid = us.app_sid AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
			 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND pc.deleted = chain_pkg.NOT_DELETED
			)
	 	 ORDER BY LOWER(name);
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_product_ids
	  FROM TT_ID;
	
	CollectToCursor(v_product_ids, out_product_cur);
END;

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
			SELECT product_id
			  FROM v$product
			 WHERE created_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND created_dtm > SYSDATE - 7 -- let's give them a week as the row limit will take care of too many
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = 0
			 ORDER BY created_dtm DESC
			)
	 WHERE rownum <= 3;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product code types for company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT code_label1, code_label2, code_label3, code2_mandatory, code3_mandatory
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_code_label1					IN  product_code_type.code_label1%TYPE,
	in_code_label2					IN  product_code_type.code_label2%TYPE,
	in_code_label3					IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory				IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory				IN 	product_code_type.code3_mandatory%TYPE,
	out_products_with_empty_codes	OUT NUMBER,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_pct					product_code_type%ROWTYPE;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;
	
	SELECT *
	  INTO v_pct
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	-- If a field has been made mandatory, count the number of products that will be affected
	IF (v_pct.code2_mandatory=0 AND in_code2_mandatory=1) OR (v_pct.code3_mandatory=0 AND in_code3_mandatory=1) THEN
		SELECT COUNT(*)
		  INTO out_products_with_empty_codes
		  FROM product p
		  JOIN product_code_type pct ON p.app_sid = pct.app_sid AND p.company_sid = pct.company_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid =in_company_sid
		   AND ((pct.code2_mandatory=0 AND in_code2_mandatory=1 AND p.code2 IS NULL)
			OR ( pct.code3_mandatory=0 AND in_code3_mandatory=1 AND p.code3 IS NULL));
	ELSE
		out_products_with_empty_codes := 0;
	END IF;
	
	-- If a code label has been removed, remove the value of that code for all products in that company
	IF v_pct.code_label2 IS NOT NULL AND in_code_label2 IS NULL THEN
		UPDATE product
		   SET code2 = NULL
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND code2 IS NOT NULL;
	END IF;
	IF v_pct.code_label3 IS NOT NULL AND in_code_label3 IS NULL THEN
		UPDATE product
		   SET code3 = NULL
		  WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND code3 IS NOT NULL;
	END IF;
	
	UPDATE product_code_type
	   SET code_label1 = TRIM(in_code_label1),
		   code_label2 = TRIM(in_code_label2),
		   code_label3 = TRIM(in_code_label3),
		   code2_mandatory = CASE WHEN in_code_label2 IS NULL THEN 0 ELSE in_code2_mandatory END,
		   code3_mandatory = CASE WHEN in_code_label3 IS NULL THEN 0 ELSE in_code3_mandatory END
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	GetNonEmptyProductCodes(in_company_sid, out_cur);
END;

PROCEDURE GetNonEmptyProductCodes (
	in_company_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT COUNT(CASE WHEN (code2 IS NOT NULL AND pct.code_label2 IS NOT NULL) THEN p.product_id ELSE NULL END) code2_count,
				COUNT(CASE WHEN (code3 IS NOT NULL AND pct.code_label3 IS NOT NULL) THEN p.product_id ELSE NULL END) code3_count
		  FROM product p
		  JOIN product_code_type pct ON p.app_sid = pct.app_sid AND p.company_sid = pct.company_sid
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = in_company_sid
		   AND (code2 IS NOT NULL OR code3 IS NOT NULL)
		   AND (pct.code_label2 IS NOT NULL OR pct.code_label2 IS NOT NULL);
END;

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
)
AS 
BEGIN
	-- we'll let this blow up if it already exists because I'm not sure what the correct response is if this is called twice
	INSERT INTO product_code_type 
	(company_sid) 
	VALUES (in_company_sid);
END;


PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product codes for company with sid '||in_company_sid);
	END IF;

	SELECT mapping_approval_required
	  INTO out_mapping_approval_required
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE product_code_type
	   SET mapping_approval_required = in_mapping_approval_required
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);

	UPDATE product 
	   SET active = in_active
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product 
	   SET need_review = in_need_review
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE product 
	   SET pseudo_root_component_id = in_component_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;

FUNCTION HasMappedUnpublishedProducts (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM V$product p
	  JOIN v$purchased_component pc ON p.product_id = pc.supplier_product_id AND p.app_sid = pc.app_sid
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.company_sid = in_company_sid
	   AND p.published = 0
	   AND p.deleted = 0
	   AND pc.deleted = 0;
	
	RETURN v_count > 0;
END;


END product_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.product_report_pkg AS

PROCEDURE SupplySummary (
	out_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_customers			NUMBER;
	v_suppliers 		NUMBER;
	v_products_bought	NUMBER;
	v_products_sold		NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.COMPANY, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid ' || SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	SELECT COUNT(*) INTO v_suppliers
	  FROM v$supplier_relationship sr, chain.company c
	 WHERE sr.app_sid = c.app_sid
	   AND sr.supplier_company_sid = c.company_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.deleted = 0
	   AND c.deleted = 0;
 
	SELECT COUNT(*) INTO v_customers 
	  FROM v$supplier_relationship sr, chain.company c
	 WHERE sr.app_sid = c.app_sid
	   AND sr.purchaser_company_sid = c.company_sid
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.deleted = 0
	   AND c.deleted = 0;
 
	SELECT COUNT(*) INTO v_products_sold 
	  FROM v$product
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND deleted = 0;

	SELECT COUNT(*) INTO v_products_bought 
	  FROM v$purchased_component
	 WHERE company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND deleted = 0;
	
	OPEN out_cur FOR
		SELECT 
			v_suppliers supplier_count, 
			v_customers customer_count,
			v_products_sold products_sold,
			v_products_bought products_bought
		FROM dual;
	
END;
	
END product_report_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.purchased_component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/

PROCEDURE RefeshSupplierActions (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
	v_action_id				action.action_id%TYPE;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component pc, v$supplier_relationship sr
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = sr.app_sid
	   AND pc.company_sid = in_company_sid
	   AND pc.company_sid = sr.purchaser_company_sid
	   AND pc.supplier_company_sid = in_supplier_company_sid
	   AND pc.supplier_company_sid = sr.supplier_company_sid
	   AND pc.acceptance_status_id = chain_pkg.ACCEPT_PENDING;

	IF v_count = 0 THEN
		
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_re_company_sid	  	 	=> in_company_sid
		);
			
	ELSE
	
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
			in_re_company_sid	  	 	=> in_company_sid
		);
		
	END IF;
	
	IF product_pkg.HasMappedUnpublishedProducts(in_supplier_company_sid) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> in_supplier_company_sid
		);
	ELSE
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
			in_to_company_sid	  	 	=> in_supplier_company_sid
		);
	END IF;
END;

PROCEDURE RefeshCompanyActions (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
	v_action_id				action.action_id%TYPE;
BEGIN
	
	IF uninvited_pkg.HasUninvitedSupsWithComponents(in_company_sid) THEN
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE,
			in_to_company_sid	  	 	=> in_company_sid
		);
	ELSE
		message_pkg.CompleteMessageIfExists (
			in_primary_lookup 			=> chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE,
			in_to_company_sid	  	 	=> in_company_sid
		);
	END IF;
	
END;

PROCEDURE CollectToCursor (
	in_component_ids		IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_amount_unit_id	amount_unit.amount_unit_id%TYPE;
	v_amount_unit		amount_unit.description%TYPE;
BEGIN

	component_pkg.GetDefaultAmountUnit(v_amount_unit_id, v_amount_unit);

	OPEN out_cur FOR
		SELECT pc.component_id, pc.description, pc.component_code, pc.component_notes, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				-- supplier data
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, pc.uninvited_name, pcs.supplier_country_code, pcs.supplier_country_name, 
				v_amount_unit_id amount_unit_id, v_amount_unit amount_unit
		  FROM v$purchased_component pc, v$purchased_component_supplier pcs, TABLE(in_component_ids) i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = pcs.app_sid
		   AND pc.component_id = i.item
		   AND pc.component_id = pcs.component_id
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY i.pos;
END;

-- note that this procedure could be called by either the supplier or purchaser 
-- (if the purcher component is being deleted)
-- i.e. - be careful about getting the company sid from sys context
PROCEDURE SetSupplier (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID
)
AS
	v_cur_data				purchased_component%ROWTYPE;
	v_supplier_type_id		component_supplier_type.component_supplier_type_id%TYPE;
	v_current_supplier_sid	security_pkg.T_SID_ID;
	v_company_sid 			security_pkg.T_SID_ID;
	v_accpetance_status_id	chain_pkg.T_ACCEPTANCE_STATUS;
	v_key					supplier_relationship.virtually_active_key%TYPE;
BEGIN
	
	
	-- figure out which type of supplier we're attaching to...
	IF NVL(in_supplier_sid, 0) > 0 THEN
		
		v_company_sid := component_pkg.GetCompanySid(in_component_id);
		
		-- activate the virtual relationship so that we can attach to companies with pending relationships as well
		company_pkg.ActivateVirtualRelationship(v_company_sid, in_supplier_sid, v_key);
		
		IF uninvited_pkg.IsUninvitedSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.UNINVITED_SUPPLIER;
		ELSIF company_pkg.IsSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.EXISTING_SUPPLIER;
		ELSIF company_pkg.IsPurchaser(v_company_sid, in_supplier_sid) THEN 
			v_supplier_type_id := chain_pkg.EXISTING_PURCHASER;
		END IF;
		
		company_pkg.DeactivateVirtualRelationship(v_key);
		
		IF v_supplier_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied attaching to company with sid ('||in_supplier_sid||') - they are not a current purchaser or supplier of company with sid ('||v_company_sid||')');
		END IF;
	ELSE
		v_supplier_type_id := chain_pkg.SUPPLIER_NOT_SET;
	END IF;
	
	BEGIN
		-- try to setup minimum data in case it doesn't exist already
		INSERT INTO purchased_component
		(component_id, component_supplier_type_id)
		VALUES
		(in_component_id, chain_pkg.SUPPLIER_NOT_SET);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- get the current data
	SELECT *
	  INTO v_cur_data
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	-- this is a bit of a strange way, but I think we're best to have an update statement per 
	-- supplier_type entry as the data that we need is highly dependant on this state
	
	IF v_supplier_type_id = chain_pkg.SUPPLIER_NOT_SET THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	
	ELSIF v_supplier_type_id = chain_pkg.UNINVITED_SUPPLIER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = in_supplier_sid,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_PURCHASER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = in_supplier_sid,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_SUPPLIER THEN
	  
	  	IF v_cur_data.component_supplier_type_id <> chain_pkg.EXISTING_SUPPLIER OR v_cur_data.supplier_company_sid <> in_supplier_sid THEN
	  		v_accpetance_status_id := chain_pkg.ACCEPT_PENDING;
	  	ELSE
	  		v_accpetance_status_id := NVL(v_cur_data.acceptance_status_id, chain_pkg.ACCEPT_PENDING);
	  	END IF;
	  	
	  	UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = v_accpetance_status_id,
			   supplier_company_sid = in_supplier_sid,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL	   
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
	  	
	  	RefeshSupplierActions(v_cur_data.company_sid, in_supplier_sid);
	END IF;
	
	RefeshCompanyActions(v_cur_data.company_sid);
END;

/**********************************************************************************
	PUBLIC -- ICOMPONENT HANDLER PROCEDURES
**********************************************************************************/

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	v_component_id := component_pkg.SaveComponent(in_component_id, chain_pkg.PURCHASED_COMPONENT, in_description, in_component_code, in_component_notes);
	
	SetSupplier(v_component_id, in_supplier_sid);
	
	GetComponent(v_component_id, out_cur);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;

	SELECT T_NUMERIC_ROW(in_component_id, null)
	  BULK COLLECT INTO v_component_ids
	  FROM v$purchased_component 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	-- Additional check here. Generally customers should have read permission on products (should they?? I think so) - but we specifically don't want 
	-- customers seeing purchased components of their suppliers as the names of their sub-supplers are present
	IF component_pkg.GetCompanySid(in_top_component_id) <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		-- error if company logged on is not component company
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on purchased component for company with sid '||component_pkg.GetCompanySid(in_top_component_id));
	END IF;	
		
	-- Don't use collect to cursor as we need more info than that provides and info about the relationship with parent component
	OPEN out_cur FOR
		SELECT  pc.component_id, pc.description, pc.component_code, pc.component_notes, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, pc.uninvited_name, pcs.supplier_country_code, pcs.supplier_country_name,
				NVL(ct.amount_child_per_parent,0) amount_child_per_parent, 
				NVL(ct.amount_unit_id,1) amount_unit_id, 
				au.description amount_unit
		  FROM v$purchased_component pc, v$purchased_component_supplier pcs, TT_COMPONENT_TREE ct, chain.amount_unit au
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND pc.app_sid = pcs.app_sid
		   AND pc.component_id = pcs.component_id
		   AND NVL(ct.amount_unit_id,1) = au.amount_unit_id(+)
		   AND au.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND in_type_id = chain_pkg.PURCHASED_COMPONENT
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	SetSupplier(in_component_id, NULL);	
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
) 
AS
	v_count						NUMBER(10);
BEGIN
	-- make sure that the company clearing the supplier is either the supplier company, or the component owner company
	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND component_id = in_component_id
	   AND (	company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   		 OR supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   );

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied clearing the supplier for purchased component with id '||in_component_id||' where you are niether the owner or supplier company');
	END IF;
	
	SetSupplier(in_component_id, NULL);	
END;

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_purchaser_company_sid
		   AND (
		   			supplier_company_sid = in_supplier_company_sid
		   		 OR purchaser_company_sid = in_supplier_company_sid
		   	   )
	) LOOP
		SetSupplier(r.component_id, in_supplier_company_sid);	
	END LOOP;
END;

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_product_ids				T_NUMERIC_TABLE;
	v_total_count				NUMBER(10);
BEGIN

	/*
	IF NOT capability_pkg.CheckCapability(in_purchaser_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||in_purchaser_company_sid);
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	
	-- collect all of the PURCHASERS products
	SELECT T_NUMERIC_ROW(product_id, NULL)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = NVL(in_purchaser_company_sid, company_sid)
	   AND deleted = chain_pkg.NOT_DELETED;
	
	-- take a snap shot of these trees
	component_pkg.RecordTreeSnapshot(v_product_ids);
	
	-- fill the id table with all valid purchased components, owned by the purchaser company, and supplied by our company
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id, position)
	SELECT component_id, rownum
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc, (
		  		SELECT app_sid, product_id, description, code1, code2, code3
		  		  FROM v$product 
		  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  		   AND deleted = chain_pkg.NOT_DELETED
		  	   ) p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.app_sid = c.app_sid
		   --AND pc.component_id = ct.child_component_id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = p.product_id(+)
		   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (in_purchaser_company_sid IS NULL OR pc.company_sid = in_purchaser_company_sid)
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.acceptance_status_id = NVL(in_accept_status, pc.acceptance_status_id)
		   AND (
					LOWER(pc.description) LIKE v_search
		   		 OR LOWER(pc.component_code) LIKE v_search
		   		 OR LOWER(p.description) LIKE v_search
		   		 OR LOWER(p.code1) LIKE v_search
		   		 OR LOWER(p.code2) LIKE v_search
		   		 OR LOWER(p.code3) LIKE v_search
		       )
		 ORDER BY LOWER(c.name), LOWER(pc.description)
		);

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
		OR position > NVL(in_start + in_page_size, v_total_count);
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_results_cur FOR
		SELECT c.name purchaser_company_name, pc.component_id, pc.description component_description, pc.component_code, pc.component_notes, pc.acceptance_status_id, 
				p.product_id, p.description product_description, p.code1, p.code2, p.code3
		  FROM v$purchased_component pc, TT_ID i, v$product p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.component_id = i.id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_company_sid = p.company_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		 ORDER BY i.position;
END;

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	       acceptance_status_id = chain_pkg.ACCEPT_PENDING
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;

	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	   	   acceptance_status_id = chain_pkg.ACCEPT_REJECTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
END;

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = in_product_id,
		   acceptance_status_id = chain_pkg.ACCEPT_ACCEPTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
	
	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND uninvited_supplier_sid = in_uninvited_supplier_sid
	) LOOP
		SetSupplier(r.component_id, in_created_as_company_sid);	
	END LOOP;
END;

PROCEDURE GetPurchaseChannels (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied accessing purchase channels. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	OPEN out_cur FOR
		SELECT NULL id, 'General' description
		  FROM dual
		UNION ALL
		SELECT purchase_channel_id id, description
		  FROM purchase_channel
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		 ORDER BY id;
END;

PROCEDURE SavePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_product_id			purchase.product_id%TYPE,
	in_start_date			purchase.start_date%TYPE,
	in_end_date				purchase.end_date%TYPE,
	in_invoice_number		purchase.invoice_number%TYPE,
	in_purchase_order		purchase.purchase_order%TYPE,
	in_note					purchase.note%TYPE,
	in_amount				purchase.amount%TYPE,
	in_amount_unit_id		purchase.amount_unit_id%TYPE,
	in_purchase_channel_id	purchase.purchase_channel_id%TYPE
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied saving purchase for product '||in_product_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_product_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on purchases for product'||in_product_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_product_id));
	END IF;
	
	IF NVL(in_purchase_id, 0) < 1 THEN
		INSERT INTO purchase	(purchase_id, product_id, start_date, end_date, invoice_number,
								purchase_order, note, amount, amount_unit_id, purchase_channel_id)
		VALUES					(purchase_id_seq.NEXTVAL, in_product_id, in_start_date, in_end_date, in_invoice_number,
								in_purchase_order, in_note, in_amount, in_amount_unit_id, in_purchase_channel_id);
	ELSE
		UPDATE purchase
		   SET start_date = in_start_date,
		       end_date = in_end_date,
		       invoice_number = in_invoice_number,
		       purchase_order = in_purchase_order,
		       note = in_note,
		       amount = in_amount,
		       amount_unit_id = in_amount_unit_id,
		       purchase_channel_id = in_purchase_channel_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND purchase_id = in_purchase_id
		   AND product_id = in_product_id;
	END IF;
END;

PROCEDURE DeletePurchase (
	in_purchase_id			purchase.purchase_id%TYPE,
	in_product_id			purchase.product_id%TYPE
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting purchase for product '||in_product_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_product_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied on purchases for product'||in_product_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_product_id));
	END IF;
	
	DELETE FROM purchase
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
	   AND purchase_id = in_purchase_id
	   AND product_id = in_product_id;
END;

PROCEDURE SearchPurchases (
	in_product_id		IN	purchase.product_id%TYPE,
	in_start				IN	NUMBER,
	in_count			IN	NUMBER,
	out_total			OUT	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
    IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for purchases for product '||in_product_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
    END IF;
    
    IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_product_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on purchases for product'||in_product_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_product_id));
    END IF;
	
	SELECT COUNT(*)
	  INTO out_total
	  FROM purchase pur
	 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
	   AND pur.product_id = in_product_id;
	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT inner1.*, rownum rn FROM (
				SELECT pur.purchase_id, pur.product_id, pur.start_date, pur.end_date, NVL(ch.description, 'General') as channel_description,
				        ch.purchase_channel_id, pur.invoice_number, pur.purchase_order, pur.note, pur.amount,
				        pur.amount_unit_id, u.description as amount_unit_description
				  FROM purchase pur
				  JOIN amount_unit u ON pur.amount_unit_id = u.amount_unit_id
				  LEFT JOIN purchase_channel ch ON pur.purchase_channel_id = ch.purchase_channel_id AND pur.purchaser_company_sid = ch.company_sid AND pur.app_sid = ch.app_sid
				 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
				   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
				   AND pur.product_id = in_product_id
				 ORDER BY pur.start_date DESC
				) inner1
			 WHERE rownum-1 < in_start + in_count
			)
		 WHERE rn-1 >= in_start;
END;

PROCEDURE DownloadPurchases (
	in_product_id		IN	purchase.product_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.IS_TOP_COMPANY) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied searching for purchases for product '||in_product_id||'. Current company ('||SYS_CONTEXT('SECURITY','CHAIN_COMPANY')||') is not a top company');
	END IF;
	
	IF NOT capability_pkg.CheckCapability(chain.component_pkg.GetCompanySid(in_product_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on purchases for product'||in_product_id||' belonging to company with sid '||chain.component_pkg.GetCompanySid(in_product_id));
	END IF;
	
	
	OPEN out_cur FOR
		SELECT com.description as product_name, com.component_code as code, pur.start_date, pur.end_date, pur.amount, u.description as unit,
				NVL(ch.description, 'General') as channel, pur.invoice_number, pur.purchase_order, pur.note
		  FROM purchase pur
		  JOIN amount_unit u ON pur.amount_unit_id = u.amount_unit_id
		  LEFT JOIN chain.v$purchased_component com ON pur.product_id = com.component_id AND pur.app_sid = com.app_sid
		  LEFT JOIN purchase_channel ch ON pur.purchase_channel_id = ch.purchase_channel_id AND pur.purchaser_company_sid = ch.company_sid AND pur.app_sid = ch.app_sid
		 WHERE pur.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND pur.purchaser_company_sid = SYS_CONTEXT('SECURITY','CHAIN_COMPANY')
		   AND pur.product_id = in_product_id
		 ORDER BY pur.start_date DESC;
END;



END purchased_component_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.questionnaire_pkg
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
	INSERT INTO qnr_share_log_entry
	(questionnaire_share_id, share_log_entry_index, share_status_id, user_notes)
	SELECT in_qnr_share_id, NVL(MAX(share_log_entry_index), 0) + 1, in_status, in_user_notes
	  FROM qnr_share_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_share_id = in_qnr_share_id;	
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
		   AND active = chain_pkg.ACTIVE
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
	v_count						NUMBER(10);
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
		
		-- we're trying to downgrade the status, so let's see if the questionnaire has been returned or if the owner can review
		
		SELECT count(*)
		  INTO v_count
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND qnr_owner_company_sid = in_company_sid
		   AND share_status_id = chain_pkg.SHARED_DATA_RETURNED;
		
		IF v_count = 0 THEN
			SELECT owner_can_review
			  INTO v_owner_can_review
			  FROM questionnaire_type
			 WHERE app_sid = security_pkg.GetApp
			   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
			
			IF v_owner_can_review = chain_pkg.INACTIVE THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied re-editting questionnaire for company with sid '||in_company_sid);
			END IF;
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
				SELECT q.company_sid, q.name, q.edit_url, q.view_url, qo.due_by_dtm, q.questionnaire_type_id,
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
	-- TODO: This is going to be too restrictive for Survey Manager
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator or with capability CREATE_QUESTIONNAIRE_TYPE');
		END IF;
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
                    position=in_position,
                    active=chain_pkg.ACTIVE
			WHERE app_sid=security_pkg.getApp
			  AND questionnaire_type_id=in_questionnaire_type_id;
	END;
END;

PROCEDURE HideQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
)
AS
BEGIN
	-- TODO: This is going to be too restrictive for Survey Manager
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		IF NOT capability_pkg.CheckCapability(chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'HideQuestionnaireType can only be run as BuiltIn/Administrator or with capability CREATE_QUESTIONNAIRE_TYPE');
		END IF;
	END IF;
	
	UPDATE questionnaire_type
	   SET active=chain_pkg.HIDDEN
	 WHERE app_sid=security_pkg.getApp
	   AND questionnaire_type_id=in_questionnaire_type_id;
END;


/* Returns 1 if Visible, 0 if Hidden, NULL if doesn't exist */
FUNCTION IsQuestionnaireTypeVisible (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
) RETURN NUMBER
AS
	v_active				questionnaire_type.active%TYPE;
BEGIN
	BEGIN
		SELECT active
		  INTO v_active
		  FROM questionnaire_type
		 WHERE app_sid=security_pkg.getApp
		   AND questionnaire_type_id=in_questionnaire_type_id;
	EXCEPTION
		WHEN no_data_found THEN
			v_active := NULL;
	END;
	
	RETURN v_active;
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
				0 is_approved,
				0 is_rejected
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
			END is_approved,
			CASE
				WHEN v_share_status = chain_pkg.SHARED_DATA_REJECTED THEN 1
				ELSE 0
			END is_rejected
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
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_OVERDUE,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.share_with_company_sid,
			in_to_user_sid		        => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.qnr_owner_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id
		);

		-- send the message to the supplier
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_OVERDUE,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => r.qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.share_with_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id
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
	-- TODO: remove this loop - stuck in quickly for rfa
	FOR r IN (
		SELECT share_with_company_sid 
		  FROM questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND qnr_owner_company_sid = in_qnr_owner_company_sid
		   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class)
	) LOOP
		SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.READY_TO_SHARE, null);
		SetQuestionnaireShareStatus(in_qnr_owner_company_sid, r.share_with_company_sid, in_qt_class, chain_pkg.SHARING_DATA, null);
		
		message_pkg.CompleteMessageIfExists(
			in_primary_lookup			=> chain_pkg.COMPLETE_QUESTIONNAIRE,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_qnr_owner_company_sid,
			in_re_company_sid			=> r.share_with_company_sid,
			in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);	
		
		message_pkg.CompleteMessageIfExists(
			in_primary_lookup			=> chain_pkg.QUESTIONNAIRE_RETURNED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_qnr_owner_company_sid,
			in_re_company_sid			=> r.share_with_company_sid,
			in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);	
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => in_qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.share_with_company_sid,
			in_re_user_sid           	=> SYS_CONTEXT('SECURITY', 'SID'),
			in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.share_with_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => in_qnr_owner_company_sid,
			in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);


	END LOOP;
END;

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_ACCEPTED, null);
	
	message_pkg.CompleteMessage(
		in_primary_lookup			=> chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);	
	
	-- trigger questionnaire approved message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);

	-- trigger questionnaire approved message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);
	
	-- trigger action plan started message to the purchaser (hidden by default)
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.ACTION_PLAN_STARTED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid
	);
END;

PROCEDURE RejectQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_REJECTED, null);
	
	message_pkg.CompleteMessage(
		in_primary_lookup			=> chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);	
	
	-- trigger questionnaire approved message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);

	-- trigger questionnaire approved message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_user_sid              => security_pkg.GetSid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);
	
END;

PROCEDURE ReturnQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_RETURNED, null);
	SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.ENTERING_DATA, null);
	
	message_pkg.CompleteMessage(
		in_primary_lookup			=> chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_to_company_sid			=> company_pkg.GetCompany,
		in_re_company_sid			=> in_qnr_owner_company_sid,
		in_re_questionnaire_type_id	=> questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);	
	
	-- trigger questionnaire approved message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);

	-- trigger questionnaire approved message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_user_sid              => security_pkg.GetSid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);
	
END;

END questionnaire_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.report_pkg
IS

PROCEDURE FilterExport(
	in_compound_filter_sid		IN	security_pkg.T_SID_ID,
	out_cur 					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_filtered_sids				security.T_ORDERED_SID_TABLE;
	v_first_invitation_ids		chain.T_NUMERIC_TABLE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_compound_filter_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on filter with sid: '||in_compound_filter_sid);
	END IF;
	
	filter_pkg.GetCompanySids(in_compound_filter_sid, v_filtered_sids);
	
	-- Get the IDs of the first invitation sent to that company
	SELECT chain.T_NUMERIC_ROW(invitation_id, null)
	  BULK COLLECT INTO v_first_invitation_ids
	  FROM
	  (
		SELECT invitation_id, ROW_NUMBER() OVER (PARTITION BY to_company_sid ORDER BY DECODE(invitation_status_id, chain_pkg.ACCEPTED, 1, 2), sent_dtm) rn
		  FROM chain.invitation
	  )
	 WHERE rn=1;
	
	OPEN out_cur FOR
		SELECT c.company_sid "ID",
		        c.name "Company_Name", 
		        c.sector_description "Sector",
		        c.activated_dtm "Activated_Date",
		        tu.full_name || DECODE(tcu.deleted, 1, ' (deleted)') "Primary_Contact_Name",
		        tu.email "Primary_Contact_Email",
		        tu.phone_number "Primary_Contact_Phone_Number",
		        fu.full_name || DECODE(fcu.deleted, 1, ' (deleted)') "Invitation_Sent_From",
		        i.sent_dtm "Invitation_Sent_Date",
		        c.address_1,
		        c.address_2,
		        c.address_3,
		        c.address_4,
		        c.postcode,
		        c.country_name "Country",
		        c.phone "Phone_Number",
		        c.fax "Fax_Number",
		        c.website
		  FROM v$company c
		  JOIN TABLE(v_filtered_sids) f ON c.company_sid = f.sid_id
		  LEFT JOIN invitation i ON i.to_company_sid = c.company_sid AND c.app_sid = i.app_sid AND invitation_id IN (SELECT item FROM TABLE(v_first_invitation_ids))
		  LEFT JOIN csr.csr_user tu ON tu.csr_user_sid = i.to_user_sid AND tu.app_sid = i.app_sid
		  LEFT JOIN chain_user tcu ON tu.csr_user_sid = tcu.user_sid AND tu.app_sid = tcu.app_sid
		  LEFT JOIN csr.csr_user fu ON fu.csr_user_sid = i.from_user_sid AND fu.app_sid = i.app_sid
		  LEFT JOIN chain_user fcu ON fu.csr_user_sid = fcu.user_sid AND fu.app_sid = fcu.app_sid
		 WHERE c.app_sid = security_pkg.GetApp
		 ORDER BY lower(c.name);
		 
		 
		/* TODO - could add current tasks, e.g. taken from Maersk:
		
		UPDATE export_supplier es
	   SET ("Follow-up Type", "Follow-up Due Date", "Action", "Action Due Date") =
	   (
		SELECT parent_description, parent_due_date, description, due_date
		  FROM
		  (
			SELECT t.supplier_company_sid, ptt.description parent_description, pt.due_date parent_due_date, tt.description, t.due_date,
					ROW_NUMBER() OVER (PARTITION BY t.supplier_company_sid ORDER BY t.due_date, t.task_type_id) rn
			  FROM chain.task t
			  JOIN chain.task_type tt on t.task_type_id = tt.task_type_id AND t.app_sid = tt.app_sid
			  JOIN chain.task_type ptt on tt.parent_task_type_id = ptt.task_type_id AND tt.app_sid = ptt.app_sid
			  JOIN chain.task pt ON t.supplier_company_sid = pt.supplier_company_sid AND ptt.task_type_id = pt.task_type_id AND t.app_sid = pt.app_sid
			 
		  )
		 WHERE es.ID = supplier_company_sid AND rn=1
	   ); */ 
		 

END;

END report_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.scheduled_alert_pkg
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
	/*************************/
	-- TODO: Move these out (they're here for a quick fix for the moment)
	helper_pkg.LogonUCD;
	
	invitation_pkg.UpdateExpirations;
	questionnaire_pkg.CheckForOverdueQuestionnaires;
	task_pkg.UpdateTasksForReview;
	
	helper_pkg.RevertLogonUCD;
	/*************************/
	
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
		 WHERE (app_sid IS NULL OR app_sid = SYS_CONTEXT('SECURITY', 'APP'))
		   AND disabled = 0
		    
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


CREATE OR REPLACE PACKAGE BODY chain.task_pkg
IS

PROCEDURE ExecuteTaskActions (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_from_status_id			IN  chain_pkg.T_TASK_STATUS,
	in_to_status_id				IN  chain_pkg.T_TASK_STATUS
);

PROCEDURE ChangeTaskStatus_ (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_no_cascade				IN  BOOLEAN DEFAULT FALSE
);


/**********************************************************
		PRIVATE
**********************************************************/
FUNCTION GetTaskOwner (
	in_task_id					IN  task.task_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_oc_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(owner_company_sid)
	  INTO v_oc_sid
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id = in_task_id;

	RETURN v_oc_sid;
END;

PROCEDURE AddTaskActions (
	in_task_type_id				IN  task_type.task_type_id%TYPE,
	in_action_list				IN  T_TASK_ACTION_LIST,
	in_invert_actions			IN  BOOLEAN
)
AS
	v_action					T_TASK_ACTION_ROW;
	v_pos						NUMBER(10);
BEGIN
	IF in_action_list IS NULL OR in_action_list.COUNT = 0 THEN
		RETURN;
	END IF;
	
	SELECT NVL(MAX(position), 0) 
	  INTO v_pos
	  FROM task_action_trigger
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	FOR i IN in_action_list.FIRST .. in_action_list.LAST 
	LOOP
		v_action := in_action_list(i);
		
		INSERT INTO task_action_trigger
		(task_type_id, on_task_action_id, trigger_task_action_id, trigger_task_name, position)
		VALUES
		(in_task_type_id, v_action.ON_TASK_ACTION, v_action.TRIGGER_TASK_ACTION, LOWER(v_action.TRIGGER_TASK_NAME), v_pos);
		
		v_pos := v_pos + 1;
		
		-- auto revert all actions where possible - if this breaks, it will only be on setup, and we can deal with it then
		IF in_invert_actions AND v_action.ON_TASK_ACTION < chain_pkg.REVERT_TASK_OFFSET AND v_action.TRIGGER_TASK_ACTION < chain_pkg.REVERT_TASK_OFFSET THEN
			INSERT INTO task_action_trigger
			(task_type_id, on_task_action_id, trigger_task_action_id, trigger_task_name, position)
			VALUES
			(in_task_type_id, v_action.ON_TASK_ACTION + chain_pkg.REVERT_TASK_OFFSET, v_action.TRIGGER_TASK_ACTION + chain_pkg.REVERT_TASK_OFFSET, LOWER(v_action.TRIGGER_TASK_NAME), v_pos);

			v_pos := v_pos + 1;
		END IF;

	END LOOP;
END;

FUNCTION GenerateChangeGroupId
RETURN task.change_group_id%TYPE
AS
	v_change_group_id			task.change_group_id%TYPE;
BEGIN
	SELECT task_change_group_id_seq.nextval
	  INTO v_change_group_id
	  FROM dual;
	
	RETURN v_change_group_id;
END;

PROCEDURE ExecuteTaskActions (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_from_status_id			IN  chain_pkg.T_TASK_STATUS,
	in_to_status_id				IN  chain_pkg.T_TASK_STATUS
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_task_type_id				task_type.task_type_id%TYPE;
	v_scheme_id			task_type.task_scheme_id%TYPE;
BEGIN
	SELECT t.owner_company_sid, t.supplier_company_sid, tt.task_type_id, tt.task_scheme_id
	  INTO v_owner_company_sid, v_supplier_company_sid, v_task_type_id, v_scheme_id
	  FROM task t, task_type tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.app_sid = tt.app_sid
	   AND t.task_type_id = tt.task_type_id
	   AND t.task_id = in_task_id;
	
	--RAISE_APPLICATION_ERROR(-20001, in_from_status_id||', '||in_to_status_id||', '||v_owner_company_sid||', '||v_supplier_company_sid||', '|| v_task_type_id||', '||v_scheme_id);
	FOR r IN (
		SELECT t.task_id, tatt.to_task_status_id
		  FROM task_action_trigger tat, task_action_lookup tal, task_action_trigger_transition tatt, task_type tt, task t
		 WHERE tat.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tat.app_sid = tt.app_sid
		   AND tat.app_sid = t.app_sid
		   AND t.owner_company_sid = v_owner_company_sid
		   AND t.supplier_company_sid = v_supplier_company_sid
		   AND tt.task_type_id = t.task_type_id
		   AND t.task_status_id = tatt.from_task_status_id
		   AND tt.task_scheme_id = v_scheme_id
		   AND tt.name = tat.trigger_task_name
		   AND tat.task_type_id = v_task_type_id
		   AND tat.on_task_action_id = tal.task_action_id
		   AND tal.from_task_status_id = in_from_status_id
		   AND tal.to_task_status_id = in_to_status_id
		   AND tat.trigger_task_action_id = tatt.task_action_id
		 ORDER BY tat.position
	) LOOP
		ChangeTaskStatus_(in_change_group_id, r.task_id, r.to_task_status_id);
	END LOOP;
END;

PROCEDURE ChangeTaskStatus_ (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_no_cascade				IN  BOOLEAN DEFAULT FALSE
)
AS
	v_default_status			task.task_status_id%TYPE;
	v_due_date_offset			task_type.due_in_days%TYPE;
	v_set_due_date				task.due_date%TYPE;
	v_new_status				task.task_status_id%TYPE DEFAULT in_status_id;
	v_new_last_status			task.task_status_id%TYPE;
	v_cur_status				task.task_status_id%TYPE;
	v_cur_last_status			task.task_status_id%TYPE;
	v_task_type_id				task.task_type_id%TYPE;
BEGIN
	BEGIN
		SELECT task_status_id, last_task_status_id, task_type_id
		  INTO v_cur_status, v_cur_last_status, v_task_type_id
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND task_id = in_task_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Task ID: '||in_task_id);
	END;
	
	-- no status change
	IF v_cur_status = v_new_status THEN
		RETURN;
	END IF;
	
	SELECT default_task_status_id, due_in_days
	  INTO v_default_status, v_due_date_offset
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_type_id = v_task_type_id;
	
	-- figure out if we're rolling back the status
	IF v_new_status = chain_pkg.TASK_LAST_STATUS THEN
		IF v_cur_last_status IS NULL THEN
			-- i don't think we should get this, not sure how to deal with it if we do (it would mean that there was a double rollback)
			RAISE_APPLICATION_ERROR(-20001, 'Cannot rollback status when last status is null');
		ELSE
			v_new_status := v_cur_last_status;
			v_new_last_status := NULL; -- don't really need this, but reminds me that this is what we want
		END IF;
	ELSIF v_new_status = chain_pkg.TASK_DEFAULT_STATUS THEN
		v_new_status := v_default_status;
		v_new_last_status := v_cur_status;
	ELSE
		v_new_last_status := v_cur_status;
	END IF;
	
	IF v_new_status = chain_pkg.TASK_OPEN AND v_new_last_status IN (v_default_status, chain_pkg.TASK_REVIEW) THEN
		v_set_due_date := SYSDATE + v_due_date_offset;
	END IF;
	
	-- update the data
	UPDATE task 
	   SET task_status_id = v_new_status,
	   	   last_task_status_id = v_new_last_status,
	   	   last_updated_dtm = SYSDATE,
	   	   last_updated_by_sid = SYS_CONTEXT('SECURITY','SID'),
	   	   due_date = NVL(v_set_due_date, due_date),
	   	   change_group_id = in_change_group_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id;
	
	IF in_no_cascade <> TRUE THEN
		chain_link_pkg.TaskStatusChanged(in_change_group_id, in_task_id, v_new_status);

		-- TODO: I'm not sure why I have this, but seems a bit wrong as I think it prevents REVERT_REMOVE from running properly
		IF v_new_last_status IS NOT NULL THEN
			ExecuteTaskActions(in_change_group_id, in_task_id, v_new_last_status, v_new_status);
		END IF;
	END IF;
END;

FUNCTION SetTaskEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_task_entry_type_id		IN  chain_pkg.T_TASK_ENTRY_TYPE,
	in_name						IN  task_entry.name%TYPE
) RETURN task_entry.task_entry_id%TYPE
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(GetTaskOwner(in_task_id), chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||GetTaskOwner(in_task_id));
	END IF;
	
	BEGIN
		INSERT INTO task_entry
		(task_entry_id, task_id, task_entry_type_id, name)
		VALUES
		(task_entry_id_seq.NEXTVAL, in_task_id, in_task_entry_type_id, LOWER(in_name))
		RETURNING task_entry_id INTO v_task_entry_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry
			   SET last_modified_dtm = SYSDATE,
			       last_modified_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_type_id = in_task_entry_type_id
			   AND task_id = in_task_id
			   AND (name = LOWER(in_name) OR (name IS NULL AND in_name IS NULL))
			RETURNING task_entry_id INTO v_task_entry_id;
	END;
	
	RETURN v_task_entry_id;
END;


PROCEDURE CollectTasks (
	in_task_ids					IN	security.T_SID_TABLE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_ids			security.T_SID_TABLE;
BEGIN
	OPEN out_task_cur FOR
		SELECT t.task_id, t.task_status_id, t.due_date, t.next_review_date, t.last_updated_dtm, t.last_updated_by_sid, 
				t.supplier_company_sid, t.task_type_id, t.owner_company_sid, t.last_task_status_id, tt.description, SYSDATE dtm_now, CASE WHEN t.task_status_id = chain_pkg.TASK_OPEN AND t.due_date < SYSDATE THEN 1 ELSE 0 END overdue,
				tt.due_date_editable, tt.review_every_n_days, t.next_review_date, tt.mandatory, tt.name task_type_name, tt.parent_task_type_id, tt.task_scheme_id
		  FROM task t, task_type tt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = tt.app_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids))
		   AND t.task_type_id = tt.task_type_id
		 ORDER BY tt.position;
		
	SELECT task_entry_id
	  BULK COLLECT INTO v_task_entry_ids
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids));
	
	IF v_task_entry_ids.COUNT = 0 THEN
		OPEN out_task_entry_cur FOR
			SELECT null task_entry_id FROM DUAL WHERE 1 = 0;
	ELSE	
		-- TODO: for performance, it's probably better to move this data to a temporary table otherwise we're forced to join on all data
		-- because we apparently can't use the TABLE(v_task_entry_ids) on the inner select
		OPEN out_task_entry_cur FOR
			SELECT te.task_entry_id, te.task_id, te.task_entry_type_id, te.name, 
					te.last_modified_dtm, te.last_modified_by_sid, tei.dtm, tei.text, 
					tei.file_upload_sid, tei.filename, tei.mime_type, tei.bytes
			  FROM task_entry te, (
						SELECT app_sid, task_entry_id, dtm, null text, null file_upload_sid, null filename, null mime_type, null bytes, null uploaded_dtm
						  FROM task_entry_date
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 UNION ALL
						SELECT app_sid, task_entry_id, null dtm, text, null file_upload_sid, null filename, null mime_type, null bytes, null uploaded_dtm
						  FROM task_entry_note
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						 UNION ALL
						SELECT tef.app_sid, tef.task_entry_id, null dtm, null text, tef.file_upload_sid, fu.filename, fu.mime_type, LENGTH(fu.data) bytes, fu.last_modified_dtm uploaded_dtm
						  FROM task_entry_file tef, file_upload fu
						 WHERE tef.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND tef.app_sid = fu.app_sid
						   AND tef.file_upload_sid = fu.file_upload_sid
						 
					) tei
			 WHERE te.app_sid = tei.app_sid
			   AND te.task_entry_id = tei.task_entry_id
			   AND te.task_entry_id IN (SELECT COLUMN_VALUE FROM TABLE(v_task_entry_ids))
			 ORDER BY te.last_modified_dtm, tei.uploaded_dtm;
	END IF;
	
	OPEN out_task_param_cur FOR
		SELECT t.task_type_id, 'reCompanyName' param_value_name, c.name param_value, 'reCompanySid' param_key_name, c.company_sid param_key
		  FROM task t, company c
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = c.app_sid
		   AND t.supplier_company_sid = c.company_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids))
		 UNION ALL
		SELECT t.task_type_id, 'byUserFullName' param_value_name, csru.full_name param_value, 'byUserSid' param_key_name, csru.csr_user_sid param_key
		  FROM task t, csr.csr_user csru
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = csru.app_sid
		   AND t.last_updated_by_sid = csru.csr_user_sid
		   AND t.task_id IN (SELECT COLUMN_VALUE FROM TABLE(in_task_ids));
END;

PROCEDURE CollectTasks (
	in_change_group_id			IN  task.change_group_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_ids					security.T_SID_TABLE;
BEGIN
	SELECT task_id
	  BULK COLLECT INTO v_task_ids
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND change_group_id = in_change_group_id;
	
	CollectTasks(v_task_ids, out_task_cur, out_task_entry_cur, out_task_param_cur);
END;

PROCEDURE OnTaskEntryChanged (
	in_task_id					IN  task.task_id%TYPE,
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR,
	in_force_collect_task		BOOLEAN
)
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN

	IF in_force_collect_task THEN
		-- ensures that we collect this task even if it's status doesn't change
		UPDATE task
		   SET change_group_id = v_change_group_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_id = in_task_id;
	END IF;

	chain_link_pkg.TaskEntryChanged(v_change_group_id, in_task_entry_id);
	CollectTasks(v_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);	
	
END;

/**********************************************************
		PUBLIC SETUP
**********************************************************/

PROCEDURE RegisterScheme (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,	
	in_description				IN  task_scheme.description%TYPE,
	in_db_class					IN  task_scheme.db_class%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterScheme can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO task_scheme
		(task_scheme_id, description, db_class)
		VALUES
		(in_scheme_id, in_description, in_db_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_scheme
			   SET description = in_description,
			   	   db_class = in_db_class
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_scheme_id = in_scheme_id;
	END;
END;

PROCEDURE RegisterTaskType (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_name						IN  task_type.name%TYPE,
	in_parent_name				IN  task_type.name%TYPE DEFAULT NULL,
	in_description				IN  task_type.description%TYPE,
	in_default_status			IN  chain_pkg.T_TASK_STATUS DEFAULT chain_pkg.TASK_HIDDEN,
	in_db_class					IN  task_type.db_class%TYPE DEFAULT NULL,
	in_due_in_days				IN  task_type.due_in_days%TYPE DEFAULT NULL,
	in_mandatory				IN  task_type.mandatory%TYPE DEFAULT chain_pkg.INACTIVE,
	in_due_date_editable		IN  task_type.due_date_editable%TYPE DEFAULT chain_pkg.ACTIVE,
	in_review_every_n_days		IN  task_type.review_every_n_days%TYPE DEFAULT NULL,
	in_card_id					IN  task_type.card_id%TYPE DEFAULT NULL,
	in_invert_actions			IN  BOOLEAN DEFAULT TRUE,
	in_on_action				IN  T_TASK_ACTION_LIST DEFAULT NULL
)
AS
	v_task_type_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_name);
	v_parent_tt_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_parent_name);
	v_max_pos					task_type.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterTaskType can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_task_type_id IS NULL THEN
		SELECT NVL(MAX(position), 0)
		  INTO v_max_pos
		  FROM task_type
		 WHERE NVL(parent_task_type_id, -1) = NVL(v_parent_tt_id, -1);
		
		INSERT INTO task_type
		(task_type_id, task_scheme_id, name, parent_task_type_id, description, default_task_status_id, db_class, 
		due_in_days, mandatory, due_date_editable, review_every_n_days, card_id, position)
		VALUES
		(task_type_id_seq.NEXTVAL, in_scheme_id, LOWER(in_name), v_parent_tt_id, in_description, in_default_status, in_db_class,
		in_due_in_days, in_mandatory, in_due_date_editable, in_review_every_n_days, in_card_id, v_max_pos + 1)
		RETURNING task_type_id INTO v_task_type_id;
	ELSE
		UPDATE task_type
		   SET parent_task_type_id = v_parent_tt_id,
			   description = in_description,
			   default_task_status_id = in_default_status,
			   db_class = in_db_class,
			   due_in_days = in_due_in_days,
			   mandatory = in_mandatory,
			   due_date_editable = in_due_date_editable,
			   review_every_n_days = in_review_every_n_days,
			   card_id = in_card_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = v_task_type_id;
	END IF;
	
	DELETE FROM task_action_trigger
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = v_task_type_id;
	
	AddTaskActions(v_task_type_id, in_on_action, in_invert_actions);

END;

PROCEDURE SetChildTaskTypeOrder (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_parent_name				IN  task_type.name%TYPE,
	in_names_by_order			IN  T_STRING_LIST	
)
AS
	v_parent_tt_id				task_type.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_parent_name);
	v_task_type_id				task_type.task_type_id%TYPE;
	v_position					NUMBER(10) DEFAULT 1;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetChildTaskTypeOrder can only be run as BuiltIn/Administrator');
	END IF;
	
	IF v_parent_tt_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not find a task type named '||in_parent_name||' in the scheme with id '||in_scheme_id);
	END IF;
	
	-- invert them so that we know if any have been missed
	UPDATE task_type
	   SET position = (-1 * position)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND parent_task_type_id = v_parent_tt_id;
	
	FOR i IN in_names_by_order.FIRST .. in_names_by_order.LAST
	LOOP
		v_task_type_id := GetTaskTypeId(in_scheme_id, in_names_by_order(i));
		
		IF v_task_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a task type named '||in_names_by_order(i)||' and parent named '||in_parent_name||' in the scheme with id '||in_scheme_id);
		END IF;
		
		UPDATE task_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_task_type_id = v_parent_tt_id
		   AND task_type_id = v_task_type_id;
		
		IF SQL%ROWCOUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Task type named '||in_names_by_order(i)||' is not a child of parent named '||in_parent_name||' in the scheme with id '||in_scheme_id);
		END IF;
	   
		v_position := v_position + 1;
	END LOOP;
	
	FOR r IN (
		SELECT task_type_id
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND parent_task_type_id = v_parent_tt_id
		   AND position < 1
		 ORDER BY position DESC
	) LOOP
		UPDATE task_type
		   SET position = v_position
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = r.task_type_id;

		v_position := v_position + 1;
	END LOOP;
END;

PROCEDURE CopyTaskTypeBranch (
	in_from_scheme_id			IN  task_type.task_scheme_id%TYPE,	
	in_to_scheme_id				IN  task_type.task_scheme_id%TYPE,	
	in_from_name				IN  task_type.name%TYPE
)
AS
	v_actions					T_TASK_ACTION_LIST;
	v_actioned					BOOLEAN DEFAULT FALSE;
	v_task_type_id				task_type.task_type_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CopyTaskTypeBranch can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_from_scheme_id IS NULL OR in_to_scheme_id IS NULL OR in_from_name IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Null parameter: in_from_scheme_id='||NVL(TO_CHAR(in_from_scheme_id), 'NULL')||' in_to_scheme_id='||NVL(TO_CHAR(in_to_scheme_id), 'NULL')||' in_from_name='||NVL(TO_CHAR(in_from_name), 'NULL'));
	ELSIF in_from_scheme_id = in_to_scheme_id THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot branch from/to the same scheme id');
	END IF;
	
	FOR r IN (
		SELECT tt.*, ptt.name parent_name, level
		  FROM task_type tt, task_type ptt
		 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND tt.app_sid = ptt.app_sid(+)
		   AND tt.task_scheme_id = in_from_scheme_id
		   AND tt.parent_task_type_id = ptt.task_type_id(+)
		 START WITH tt.name = LOWER(in_from_name)
	   CONNECT BY PRIOR tt.task_type_id = tt.parent_task_type_id
	     ORDER SIBLINGS BY tt.position
	) LOOP
		
		v_actioned := TRUE;
		
		SELECT T_TASK_ACTION_ROW(on_task_action_id, trigger_task_action_id, trigger_task_name)
		  BULK COLLECT INTO v_actions
		  FROM task_action_trigger
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_type_id = r.task_type_id;
	
		RegisterTaskType(
			in_scheme_id			=> in_to_scheme_id,
			in_name					=> r.name,
			in_parent_name			=> r.parent_name,
			in_description			=> r.description,
			in_default_status		=> r.default_task_status_id,
			in_db_class				=> r.db_class,
			in_due_in_days			=> r.due_in_days,
			in_mandatory			=> r.mandatory,
			in_due_date_editable	=> r.due_date_editable,
			in_review_every_n_days	=> r.review_every_n_days,
			in_card_id				=> r.card_id,
			in_invert_actions		=> FALSE,
			in_on_action			=> v_actions
		);
		
		-- copy the positions as well if we're not dealing with the root task type
		IF r.level > 1 THEN
			v_task_type_id := GetTaskTypeId(in_to_scheme_id, r.name);
			
			UPDATE task_type
			   SET position = r.position
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_type_id = v_task_type_id;
		END IF;
		
	END LOOP;
	
	IF NOT v_actioned THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not find task with name '||in_from_name||' in task scheme with id of '||in_from_scheme_id);
	END IF;
END;


/**********************************************************
		PUBLIC UTILITY
**********************************************************/

FUNCTION GetTaskTypeId (
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task_type.task_type_id%TYPE
AS
	v_task_type_id				task_type.task_type_id%TYPE;
BEGIN
	SELECT MIN(task_type_id)
	  INTO v_task_type_id
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND name = LOWER(in_name)
	   AND task_scheme_id = in_scheme_id;
	
	RETURN v_task_type_id;
END;

FUNCTION GetParentTaskTypeId (
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_type_id%TYPE
AS
	v_ptt_id					task.task_type_id%TYPE;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	SELECT MIN(parent_task_type_id)
	  INTO v_ptt_id
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	RETURN v_ptt_id;
END;

FUNCTION GetParentTaskId (
	in_task_id					IN  task.task_id%TYPE
) RETURN task.task_type_id%TYPE
AS
	v_task_type_id				task.task_type_id%TYPE;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	BEGIN
		SELECT task_type_id, supplier_company_sid
		  INTO v_task_type_id, v_supplier_company_sid
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_id = in_task_id
		   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
	
	RETURN GetTaskId(v_supplier_company_sid, GetParentTaskTypeId(v_task_type_id));
END;

FUNCTION GetTaskId (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id						task.task_id%TYPE;
BEGIN
	SELECT MIN(task_id)
	  INTO v_task_id
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = in_task_entry_id;
	
	RETURN v_task_id;
END;

FUNCTION GetTaskId (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_id%TYPE
AS
BEGIN
	RETURN GetTaskId(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, in_task_type_id);
END;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_id				IN  task.task_type_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id					task.task_id%TYPE;
BEGIN
	-- no sec as it's just a task id and there's not much you can do with it
	SELECT MIN(task_id)
	  INTO v_task_id
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id
	   AND owner_company_sid = in_owner_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	RETURN v_task_id;
END;

FUNCTION GetTaskId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_name						IN  task_type.name%TYPE
) RETURN task.task_id%TYPE
AS
BEGIN
	RETURN GetTaskId(in_owner_company_sid, in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_name));
END;

FUNCTION GetTaskName (
	in_task_id					IN  task.task_id%TYPE
) RETURN task_type.name%TYPE
AS
	v_name						task_type.name%TYPE;
BEGIN
	SELECT MIN(tt.name)
	  INTO v_name
	  FROM task t, task_type tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.app_sid = tt.app_sid
	   AND t.task_id = in_task_id
	   AND t.task_type_id = tt.task_type_id;
	
	RETURN v_name;
END;

FUNCTION GetTaskEntryName (
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
) RETURN task_type.name%TYPE
AS
	v_name						task_type.name%TYPE;
BEGIN
	SELECT MIN(name)
	  INTO v_name
	  FROM task_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = in_task_entry_id;
	
	RETURN v_name;
END;

/**********************************************************
		PUBLIC OLD TASK METHODS
**********************************************************/

FUNCTION AddSimpleTask (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_task_type_id				IN	task.task_type_id%TYPE,
	in_task_status				IN	task.task_status_id%TYPE
) RETURN task.task_id%TYPE
AS
	v_task_id					task.task_id%TYPE;
	v_due_date					task.due_date%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	SELECT CASE WHEN due_in_days IS NULL THEN NULL ELSE SYSDATE + due_in_days END
	  INTO v_due_date
 	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_type_id = in_task_type_id;
	
	INSERT INTO task
	(task_id, task_type_id, owner_company_sid, supplier_company_sid, task_status_id, due_date)
	VALUES
	(task_id_seq.NEXTVAL, in_task_type_id, company_pkg.GetCompany, in_supplier_company_sid, in_task_status, v_due_date)
	RETURNING task_id INTO v_task_id;
	
	RETURN v_task_id;	   
END;


PROCEDURE ProcessTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_questionnaire_class		IN	questionnaire_type.CLASS%TYPE
)
AS
	v_class						questionnaire_type.db_class%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	SELECT MIN(db_class)
	  INTO v_class 
	  FROM questionnaire_type 
	 WHERE class = in_questionnaire_class;
	
	IF v_class IS NOT NULL THEN
		-- it is intentional that this will fail if the method doesn't exit
		EXECUTE IMMEDIATE 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_supplier_company_sid;
	END IF;
END;

PROCEDURE ProcessTaskScheme (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id			IN	task_type.task_scheme_id%TYPE
)
AS
	v_class		QUESTIONNAIRE_TYPE.DB_CLASS%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	SELECT MIN(db_class)
	  INTO v_class 
	  FROM task_scheme 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_scheme_id = in_scheme_id;

	IF v_class IS NOT NULL THEN
		-- it is intentional that this will fail if the method doesn't exit
		EXECUTE IMMEDIATE 'BEGIN ' || v_class || '.UpdateTasksForCompany(:companySid);' || ' END;' USING in_supplier_company_sid;
	END IF;
END;

PROCEDURE UpdateTask (
	in_task_id					IN	task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	in_next_review_date			IN	date,
	in_due_date					IN	date
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	UPDATE task 
	   SET 	task_status_id = in_status_id, 
	   		next_review_date = in_next_review_date,
			due_date = in_due_date
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_id = in_task_id
	   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
END;

PROCEDURE GetFlattenedTasks (
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	OPEN out_cur FOR
		SELECT t.task_id, t.task_status_id, t.due_date, t.next_review_date, 
				t.last_updated_dtm, t.last_updated_by_sid, t.supplier_company_sid, t.task_type_id, t.owner_company_sid, 
				tt.task_scheme_id, tt.description, tt.due_in_days, tt.mandatory, tt.due_date_editable, tt.review_every_n_days
		  FROM task t, task_type tt
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.app_sid = tt.app_sid
		   AND t.task_type_id = tt.task_type_id
		   AND tt.task_scheme_id = NVL(in_scheme_id, tt.task_scheme_id)
		   AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND t.supplier_company_sid = in_supplier_company_sid
		   AND tt.parent_task_type_id IS NULL
		 ORDER BY tt.position ASC;
END;

/**********************************************************
		PUBLIC TASK METHODS
**********************************************************/

PROCEDURE StartScheme (
	in_scheme_id				IN	task_type.task_scheme_id%TYPE,
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_task_type_name			IN  task_type.name%TYPE DEFAULT NULL
)
AS
	v_tt_name					task_type.name%TYPE DEFAULT LOWER(in_task_type_name);
	v_open_task_id				task.task_id%TYPE;
BEGIN
	-- no sec check here as we're just creating the basic task structure
	
	FOR r IN (
		SELECT *
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_scheme_id = in_scheme_id
	) LOOP
		BEGIN
			INSERT INTO task
			(task_id, task_type_id, owner_company_sid, supplier_company_sid, task_status_id)
			VALUES
			(task_id_seq.NEXTVAL, r.task_type_id, in_owner_company_sid, in_supplier_company_sid, r.default_task_status_id);
			
			IF r.name = v_tt_name THEN
				SELECT task_id_seq.CURRVAL INTO v_open_task_id FROM DUAL;
			END IF;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	IF v_open_task_id IS NOT NULL THEN
		ChangeTaskStatus(v_open_task_id, chain_pkg.TASK_OPEN);
	END IF;
END;

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN	
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	
	ChangeTaskStatus_(GenerateChangeGroupId, in_task_id, in_status_id);
END;

PROCEDURE ChangeTaskStatus (
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN
	ChangeTaskStatus(v_change_group_id, in_task_id, in_status_id);
	CollectTasks(v_change_group_id, out_task_cur, out_task_entry_cur, out_task_param_cur);
END;

PROCEDURE ChangeTaskStatus (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	
	ChangeTaskStatus_(in_change_group_id, in_task_id, in_status_id);
END;

PROCEDURE ChangeTaskStatusNoCascade (
	in_change_group_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN	task.task_status_id%TYPE
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID DEFAULT GetTaskOwner(in_task_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
		
	ChangeTaskStatus_(in_change_group_id, in_task_id, in_status_id, TRUE);
END;


FUNCTION GetTaskStatus (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE
) RETURN task.task_status_id%TYPE
AS
BEGIN
	RETURN GetTaskStatus(GetTaskId(in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_task_type_name)));
END;

FUNCTION GetTaskStatus (
	in_task_id					IN	task.task_id%TYPE
) RETURN task.task_status_id%TYPE
AS
	v_status_id					task.task_status_id%TYPE;
	v_owner_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT owner_company_sid, task_status_id
	  INTO v_owner_company_sid, v_status_id
	  FROM task
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id;
	
	IF NOT capability_pkg.CheckCapability(v_owner_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_owner_company_sid);
	END IF;
	   
	RETURN v_status_id;
END;


PROCEDURE SetTaskDueDate (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_scheme_id				IN  task_type.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
) 
AS
BEGIN
	SetTaskDueDate(GetTaskId(in_supplier_company_sid, GetTaskTypeId(in_scheme_id, in_task_type_name)), in_due_date, in_overwrite);
END;

PROCEDURE SetTaskDueDate (
	in_task_id					IN	task.task_id%TYPE,
	in_due_date					IN	task.due_date%TYPE,
	in_overwrite				IN	NUMBER
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;
	
	UPDATE task 
	   SET due_date = in_due_date
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND task_id = in_task_id
	   AND (NVL(in_overwrite, 0) <> 0 OR due_date IS NULL)
	   AND owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE GetTaskSummary (
	in_task_scheme_id			IN	task_scheme.task_scheme_id%TYPE DEFAULT NULL,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies		security.T_ORDERED_SID_TABLE;
BEGIN
	
	
	company_pkg.GetCompaniesRegisteredByUser(v_user_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_my_companies);
	
	OPEN out_cur FOR
		SELECT sub.*,
			    c1.name due_now_company_name,
			    c2.name over_due_company_name,
			    c3.name really_over_due_company_name,
			    c4.name due_soon_company_name,
			    c5.name due_later_company_name
		  FROM (
			SELECT MIN(Task_Name) Task_Name, Task_Type_Id, MIN(position) position,
				    COUNT(DISTINCT Due_Now) Due_Now, COUNT(DISTINCT Over_Due) Over_Due,
				    COUNT(DISTINCT Really_Over_Due) Really_Over_Due, COUNT(DISTINCT Due_Soon) Due_Soon,
				    COUNT(DISTINCT Due_Later) Due_Later,
				    MIN(Due_Now) due_now_company_sid, MIN(Over_Due) over_due_company_sid,
				    MIN(Really_Over_Due) really_over_due_company_sid, MIN(Due_Soon) due_soon_company_sid,
				    MIN(Due_Later) due_later_company_sid
			  FROM 
			  (
				SELECT tt.description Task_Name, tt.Task_Type_Id, t.supplier_company_sid company_sid, tt.position,
					   CASE WHEN t.task_status_id IN (chain_pkg.TASK_OPEN) AND t.due_date between sysdate-7 AND sysdate		THEN my.sid_id ELSE NULL END Due_Now,
					   CASE WHEN t.task_status_id IN (chain_pkg.TASK_OPEN) AND t.due_date between sysdate-14 AND sysdate-7	THEN my.sid_id ELSE NULL END Over_Due,
					   CASE WHEN t.task_status_id IN (chain_pkg.TASK_OPEN) AND t.due_date < sysdate-14						THEN my.sid_id ELSE NULL END Really_Over_Due,
					   CASE WHEN t.task_status_id IN (chain_pkg.TASK_OPEN) AND t.due_date between sysdate AND sysdate+7		THEN my.sid_id ELSE NULL END Due_Soon,
					   CASE WHEN t.task_status_id IN (chain_pkg.TASK_OPEN) AND t.due_date > sysdate+7							THEN my.sid_id ELSE NULL END Due_Later
				  FROM task_type tt
				  LEFT JOIN task_type ctt ON tt.app_sid = ctt.app_sid AND tt.task_type_id = ctt.parent_task_type_id
				  JOIN task t ON (t.task_type_id = tt.task_type_id OR t.task_type_id = ctt.task_type_id) AND t.app_sid = tt.app_sid
				  LEFT JOIN TABLE(v_my_companies) my ON t.supplier_company_sid=my.sid_id
				 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND tt.parent_task_type_id IS NULL
				   AND (in_task_scheme_id IS NULL OR tt.task_scheme_id = in_task_scheme_id)
			  ) sub2
			 GROUP BY task_type_id 
		  ) sub
		  LEFT JOIN company c1 ON sub.due_now=1 AND sub.due_now_company_sid = c1.company_sid AND c1.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c2 ON sub.over_due=1 AND sub.over_due_company_sid = c2.company_sid AND c2.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c3 ON sub.really_over_due=1 AND sub.really_over_due_company_sid = c3.company_sid AND c3.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c4 ON sub.due_soon=1 AND sub.due_soon_company_sid = c4.company_sid AND c4.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN company c5 ON sub.due_later=1 AND sub.due_later_company_sid = c5.company_sid AND c5.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY position;
	
END;

PROCEDURE GetMyActiveCompaniesByTaskType (
	in_task_type_id				IN task_type.task_type_id%TYPE,
	in_days_from				IN NUMBER,
	in_days_to					IN NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_my_companies		security.T_ORDERED_SID_TABLE;
	v_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_company_sid);
	END IF;
	
	company_pkg.GetCompaniesRegisteredByUser(v_user_sid, v_company_sid, v_my_companies);
	
	OPEN out_cur FOR
		SELECT DISTINCT c.company_sid, c.name
		  FROM task t
		  JOIN task_type tt ON t.app_sid = tt.app_sid AND t.task_type_id = tt.task_type_id
		  JOIN v$company c ON t.app_sid = c.app_sid AND t.supplier_company_sid = c.company_sid
		  JOIN TABLE(v_my_companies) my ON c.company_sid = my.sid_id
		 WHERE in_task_type_id in (t.task_type_id, tt.parent_task_type_id)
		   AND t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND t.due_date BETWEEN SYSDATE+in_days_from AND SYSDATE+in_days_to
		   AND t.task_status_id IN (chain_pkg.TASK_OPEN)
		 ORDER BY c.name;
END;

PROCEDURE GetActiveTasksForUser (
	in_user_sid					IN 	security_pkg.T_SID_ID,
	in_task_scheme_ids			IN	helper_pkg.T_NUMBER_ARRAY,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_count					OUT	NUMBER,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_my_companies		security.T_ORDERED_SID_TABLE;
	v_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	v_all_task_schemes	INTEGER DEFAULT 0;
	v_task_scheme_ids	T_NUMERIC_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||v_company_sid);
	END IF;
	
	company_pkg.GetCompaniesRegisteredByUser(in_user_sid, v_company_sid, v_my_companies);
	
	v_all_task_schemes := helper_pkg.NumericArrayEmpty(in_task_scheme_ids);
	IF v_all_task_schemes = 1 THEN
		v_task_scheme_ids := T_NUMERIC_TABLE(T_NUMERIC_ROW(-1,1));
	ELSE
		v_task_scheme_ids := helper_pkg.NumericArrayToTable(in_task_scheme_ids);
	END IF;
	
	SELECT COUNT(*)
	  INTO out_count
	  FROM task t
	  JOIN task_type tt ON t.app_sid = tt.app_sid AND t.task_type_id = tt.task_type_id
	  JOIN TABLE(v_my_companies) my ON t.supplier_company_sid = my.sid_id
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.task_status_id IN (chain_pkg.TASK_OPEN)
	   AND tt.parent_task_type_id IS NOT NULL
	   AND (v_all_task_schemes=1 OR tt.task_scheme_id IN (SELECT item FROM TABLE(v_task_scheme_ids)));
	
	INSERT INTO tt_user_tasks (supplier_name, supplier_sid, task_type_description, parent_task_type_description, due_date, rn)
		SELECT * FROM (
				SELECT inr1.*, ROWNUM rn FROM (
					SELECT c.name supplier_name, c.company_sid supplier_sid, tt.description task_type_description,
							ptt.description parent_task_type_description, due_date
					  FROM task t
					  JOIN task_type tt ON t.task_type_id = tt.task_type_id AND t.app_sid = tt.app_sid
					  JOIN task_type ptt ON tt.parent_task_type_id = ptt.task_type_id AND tt.app_sid = ptt.app_sid
					  JOIN v$company c ON t.supplier_company_sid = c.company_sid AND t.app_sid = c.app_sid
					  JOIN TABLE(v_my_companies) my ON c.company_sid = my.sid_id
					 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND t.task_status_id IN (chain_pkg.TASK_OPEN)
					   AND (v_all_task_schemes=1 OR tt.task_scheme_id IN (SELECT item FROM TABLE(v_task_scheme_ids)))
					 ORDER BY due_date
							, ptt.position, tt.position
					) inr1
				 WHERE ROWNUM <=in_start+in_page_size
				) inr2
			 WHERE rn > in_start;
	
	UPDATE tt_user_tasks paged
	   SET (re_questionnaire, re_user, message_definition_id) = 
	   (
		SELECT qt.name re_questionnaire, u.full_name re_user, msg.message_definition_id
		  FROM (
			SELECT m.re_company_sid, re_questionnaire_type_id, re_user_sid, re_component_id, message_definition_id,
					ROW_NUMBER() OVER (PARTITION BY m.re_company_sid ORDER BY last_refreshed_dtm DESC) mrn
			  FROM v$message_recipient m
			 WHERE m.re_company_sid IS NOT NULL
			   AND m.message_definition_id in (select message_definition_id from v$message_definition where completion_type_id=0)
			   AND (m.to_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
		  ) msg
		  LEFT JOIN questionnaire_type qt ON qt.questionnaire_type_id = msg.re_questionnaire_type_id AND qt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  LEFT JOIN csr.csr_user u ON msg.re_user_sid = u.csr_user_sid
		 WHERE mrn=1
		   AND msg.re_company_sid = paged.supplier_sid
	   );
	
	OPEN out_cur FOR
		SELECT t.supplier_name,
				t.supplier_sid,
				t.task_type_description,
				t.parent_task_type_description,
				t.due_date,
				t.re_questionnaire,
				t.re_user,
				df.message_template
		  FROM tt_user_tasks t
		  JOIN v$message_definition df ON t.message_definition_id = df.message_definition_id;
END;


/**********************************************************
		PUBLIC TASK ENTRY METHODS
**********************************************************/

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskDate(in_task_id, in_name, in_date, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskDate (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_date						IN  task_entry_date.dtm%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_DATE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_date
		(task_entry_id, dtm)
		VALUES
		(v_task_entry_id, in_date);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry_date
			   SET dtm = in_date
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
	END;
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, FALSE);
END;

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskNote(in_task_id, in_name, in_note, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskNote (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_note						IN  task_entry_note.text%TYPE,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_NOTE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_note
		(task_entry_id, text)
		VALUES
		(v_task_entry_id, in_note);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE task_entry_note
			   SET text = in_note
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
	END;
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, FALSE);
END;

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID
)
AS
	v_task_cur					security_pkg.T_OUTPUT_CUR;
	v_task_entry_cur			security_pkg.T_OUTPUT_CUR;
	v_task_param_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	SaveTaskFile(in_task_id, in_name, in_file_sid, v_task_cur, v_task_entry_cur, v_task_param_cur);
END;

PROCEDURE SaveTaskFile (
	in_task_id					IN  task.task_id%TYPE,
	in_name						IN  task_entry.name%TYPE,
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE DEFAULT SetTaskEntry(in_task_id, chain_pkg.TASK_FILE, in_name);
BEGIN
	BEGIN
		INSERT INTO task_entry_file
		(task_entry_id, file_upload_sid)
		VALUES
		(v_task_entry_id, in_file_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
	
	OnTaskEntryChanged(in_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, TRUE);
END;

PROCEDURE DeleteTaskFile (
	in_file_sid					IN  security_pkg.T_SID_ID,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_task_id					task.task_id%TYPE;
	v_task_entry_id				task_entry.task_entry_id%TYPE;
	v_name						task_entry.name%TYPE;
BEGIN
	SELECT te.task_id, te.name
	  INTO v_task_id, v_name
	  FROM task_entry_file tef, task_entry te
	 WHERE te.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND te.app_sid = tef.app_sid
	   AND te.task_entry_id = tef.task_entry_id
	   AND tef.file_upload_sid = in_file_sid;
	
	v_task_entry_id := SetTaskEntry(v_task_id, chain_pkg.TASK_FILE, v_name);

	DELETE 
	  FROM task_entry_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_entry_id = v_task_entry_id
	   AND file_upload_sid = in_file_sid;
	
	upload_pkg.DeleteFile(in_file_sid);
	
	OnTaskEntryChanged(v_task_id, v_task_entry_id, out_task_cur, out_task_entry_cur, out_task_param_cur, TRUE);	
END;

FUNCTION HasEntry (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name				IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name_one, in_entry_name_two));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_name_one			IN  task_entry.name%TYPE,
	in_entry_name_two			IN  task_entry.name%TYPE,
	in_entry_name_three			IN  task_entry.name%TYPE
) RETURN BOOLEAN
AS
BEGIN
	RETURN HasEntries(in_task_id, T_STRING_LIST(in_entry_name_one, in_entry_name_two, in_entry_name_three));
END;

FUNCTION HasEntries (
	in_task_id					IN  task.task_id%TYPE,
	in_entry_names				IN  T_STRING_LIST
) RETURN BOOLEAN
AS
	v_task_entry_id				task_entry.task_entry_id%TYPE;
	v_task_entry_type_id		task_entry.task_entry_type_id%TYPE;
	v_count						NUMBER(10);
BEGIN
	FOR i IN in_entry_names.FIRST .. in_entry_names.LAST
	LOOP
		BEGIN
			SELECT task_entry_id, task_entry_type_id
			  INTO v_task_entry_id, v_task_entry_type_id
			  FROM task_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_id = in_task_id
			   AND name = LOWER(in_entry_names(i));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN FALSE;
		END;
		
		IF v_task_entry_type_id = chain_pkg.TASK_DATE THEN

			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_date
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id
			   AND dtm IS NOT NULL;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSIF v_task_entry_type_id = chain_pkg.TASK_NOTE THEN
		
			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_note
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id
			   AND text IS NOT NULL;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSIF v_task_entry_type_id = chain_pkg.TASK_FILE THEN
		
			SELECT COUNT(*)
			  INTO v_count
			  FROM task_entry_file
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_entry_id = v_task_entry_id;
			
			IF v_count = 0 THEN
				RETURN FALSE;
			END IF;			

		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown task_entry_type '||v_task_entry_type_id);
		END IF;
		
	END LOOP;
	
	RETURN TRUE;
END;

PROCEDURE GetTaskCardManagerData (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_manager_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_card_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_progression_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_type_card_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_task_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_task_entry_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_task_param_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_card_ids				security.T_SID_TABLE;
	v_task_ids				security.T_SID_TABLE;
	v_scheme_id				task_scheme.task_scheme_id%TYPE;
	v_avr_key				supplier_relationship.virtually_active_key%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	company_pkg.ActivateVirtualRelationship(company_pkg.GetCompany, in_supplier_company_sid, v_avr_key);

	v_scheme_id := chain_link_pkg.GetTaskSchemeId(company_pkg.GetCompany, in_supplier_company_sid);
	
	IF v_scheme_id IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not get a scheme id');
	END IF;
	
	SELECT card_id
	  BULK COLLECT INTO v_card_ids
	  FROM task_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND task_scheme_id = v_scheme_id
	   AND card_id IS NOT NULL
	 ORDER BY position;
	
	SELECT t.task_id
	  BULK COLLECT INTO v_task_ids
	  FROM task t, (
		SELECT task_type_id
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND task_scheme_id = v_scheme_id
		 START WITH card_id IS NOT NULL
	   CONNECT BY PRIOR task_type_id = parent_task_type_id
	   ) tt
	 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND t.task_type_id = tt.task_type_id
	   AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND t.supplier_company_sid = in_supplier_company_sid;	

	card_pkg.CollectManagerData(in_card_group_id, v_card_ids, out_manager_cur, out_card_cur, out_progression_cur);

	CollectTasks(v_task_ids, out_task_cur, out_task_entry_cur, out_task_param_cur);
	
	OPEN out_task_type_card_cur FOR
		SELECT tt.task_type_id, c.class_type
		  FROM task_type tt, card c
		 WHERE tt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND tt.card_id = c.card_id
	       AND tt.card_id IN (SELECT COLUMN_VALUE FROM TABLE(v_card_ids))
	       AND tt.task_scheme_id = v_scheme_id;
	
	company_pkg.DeactivateVirtualRelationship(v_avr_key);
END;

PROCEDURE MapTaskInvitationQnrType (
	in_scheme_id				IN  task_scheme.task_scheme_id%TYPE,
	in_task_type_name			IN  task_type.name%TYPE,
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_include_children			IN  NUMBER
)
AS
	v_owner_company_sid			security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_task_type_id				task.task_type_id%TYPE DEFAULT GetTaskTypeId(in_scheme_id, in_task_type_name);
	v_task_type_ids				security.T_SID_TABLE;
BEGIN
	SELECT i.from_company_sid, i.to_company_sid
	  INTO v_owner_company_sid, v_supplier_company_sid
	  FROM invitation i, invitation_qnr_type iqt
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.app_sid = iqt.app_sid
	   AND i.invitation_id = in_invitation_id
	   AND i.invitation_id = iqt.invitation_id
	   AND iqt.questionnaire_type_id = in_questionnaire_type_id;
	   
	IF in_include_children <> chain_pkg.INACTIVE THEN
		SELECT task_type_id
		  BULK COLLECT INTO v_task_type_ids
		  FROM task_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 START WITH task_type_id = v_task_type_id
	   CONNECT BY PRIOR task_type_id = parent_task_type_id;
	ELSE
		v_task_type_ids(0) := v_task_type_id;
	END IF;

	
	FOR r IN (
		SELECT task_id
		  FROM task
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND owner_company_sid = v_owner_company_sid
		   AND supplier_company_sid = v_supplier_company_sid
		   AND task_type_id IN (SELECT COLUMN_VALUE FROM TABLE(v_task_type_ids))
	) LOOP
		BEGIN
			INSERT INTO task_invitation_qnr_type
			(task_id, invitation_id, questionnaire_type_id)
			VALUES
			(r.task_id, in_invitation_id, in_questionnaire_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE task_invitation_qnr_type
				   SET invitation_id = in_invitation_id,
					   questionnaire_type_id = in_questionnaire_type_id
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND task_id = r.task_id;
		END;
	
	END LOOP;
END;

PROCEDURE GetInvitationTaskCardData (
	in_task_id				IN  task.task_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.TASKS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to tasks for company with sid '||company_pkg.GetCompany);
	END IF;

	OPEN out_cur FOR
		SELECT qt.name questionnaire_type_name,
			   qt.view_url questionnaire_type_view_url,
		        fc.company_sid from_company_sid, fc.name from_company_name, 
				tc.company_sid to_company_sid, tc.name to_company_name, 
				fu.csr_user_sid from_user_sid, fu.full_name from_user_full_name,
				tu.csr_user_sid to_user_sid, tu.full_name to_user_full_name
		   FROM task_invitation_qnr_type tiqt, task t, invitation i, questionnaire_type qt, company fc, company tc, csr.csr_user fu, csr.csr_user tu
		  WHERE tiqt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		    AND tiqt.app_sid = t.app_sid
			AND tiqt.app_sid = i.app_sid
			AND tiqt.app_sid = qt.app_sid
			AND tiqt.app_sid = fc.app_sid
			AND tiqt.app_sid = tc.app_sid
			AND tiqt.app_sid = fu.app_sid
			AND tiqt.app_sid = tu.app_sid
			AND tiqt.task_id = t.task_id
			AND t.task_id = in_task_id
			AND t.owner_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND tiqt.invitation_id = i.invitation_id
			AND tiqt.questionnaire_type_id = qt.questionnaire_type_id
			AND i.from_company_sid = fc.company_sid
			AND i.from_user_sid = fu.csr_user_sid
			AND i.to_company_sid = tc.company_sid
			AND i.to_user_sid = tu.csr_user_sid;
		  
END;

PROCEDURE UpdateTasksForReview
AS
	v_change_group_id			task.change_group_id%TYPE DEFAULT GenerateChangeGroupId;
BEGIN

	helper_pkg.LogonUCD;
	
	FOR r IN (	
		SELECT task_id
		  FROM (
			-- get the qualifying tasks (that are in TASK_REVIEW status, and have valid offset dates)
			SELECT t.task_id, t.last_updated_dtm, tt.review_every_n_days
			  FROM task t, task_type tt
			 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND t.app_sid = tt.app_sid
			   AND t.task_type_id = tt.task_type_id  
			   AND t.task_status_id = chain_pkg.TASK_REVIEW
			   AND tt.review_every_n_days IS NOT NULL
			)	
		 WHERE last_updated_dtm + review_every_n_days < SYSDATE
	) LOOP
		-- don't update tasks that have changed in this change group (not sure why, just think it might go sideways)
		FOR t IN (
			SELECT task_id
			  FROM task
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND task_id = r.task_id
			   AND (change_group_id IS NULL OR change_group_id <> v_change_group_id)
		) LOOP
			-- set them to open if they're ready for review
			ChangeTaskStatus_(v_change_group_id, t.task_id, chain_pkg.TASK_OPEN);
		END LOOP;		
	END LOOP;
	
	helper_pkg.RevertLogonUCD;
END;

END task_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.uninvited_pkg
IS

/***********************************************************
		PRIVATE CollectSearchResults
***********************************************************/
PROCEDURE CollectSearchResults (
	in_existing_results		IN  security.T_ORDERED_SID_TABLE,
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
			   CASE WHEN in_page_size = 0 THEN 0 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_existing_results);
	
	OPEN out_result_cur FOR 
		select sub.* from (
			SELECT sub_union.*, row_number() OVER (ORDER BY LOWER(sub_union.name)) rn, ctry.name as country_name
			  FROM (
				SELECT c.company_sid, c.name, c.country_code
				  FROM v$company c
				  JOIN TABLE(in_existing_results) T
					ON c.company_sid = T.SID_ID
				 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 UNION
				SELECT u.uninvited_supplier_sid, u.name, u.country_code
				  FROM uninvited_supplier u
				  JOIN TABLE(in_existing_results) r 
					ON u.uninvited_supplier_sid = r.SID_ID
			  ) sub_union
			  JOIN postcode.country ctry on ctry.country = sub_union.country_code
		  ORDER BY rn
		  ) sub
		 WHERE rn-1 BETWEEN ((in_page-1) * in_page_size) AND (in_page * in_page_size) - 1;

	
END;

/***********************************************************
		CreateObject
***********************************************************/
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- CASEY: You need to validate the new name, and set it in your table
	NULL;
END;

/***********************************************************
		RenameObject
***********************************************************/
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
) AS
BEGIN
	-- CASEY: You need to validate the new name, and set it in your table
	NULL;
END;

/***********************************************************
		DeleteObject
***********************************************************/
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS	
BEGIN
	-- Remove links in purchased component
	UPDATE purchased_component
	   SET component_supplier_type_id = 0, uninvited_supplier_sid = NULL
	 WHERE uninvited_supplier_sid = in_sid_Id
	   AND app_sid = security_pkg.GetApp;
	DELETE FROM uninvited_supplier
	 WHERE uninvited_supplier_sid = in_sid_Id
	   AND app_sid = security_pkg.GetApp;
END;

/***********************************************************
		MoveObject
***********************************************************/
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
) AS   
BEGIN		 
	NULL;
END;

/***********************************************************
		IsUninvitedSupplier
***********************************************************/


FUNCTION IsUninvitedSupplier (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	
	--TODO: what if the supplier has been invited (i.e. created_as_company_sid is not null)?
	--      ideally we should return the created_as sid for code using this to carry on
	--      this would currently only happen if someone were to set up the supplier between the user
	--      searching for a supplier and saving the component in the wizard.
	SELECT COUNT(*)
	  INTO v_count
	  FROM uninvited_supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	   AND uninvited_supplier_sid = in_uninvited_supplier_sid
	   AND created_as_company_sid IS NULL;
	
	RETURN v_count > 0;
END;

FUNCTION IsUninvitedSupplier (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsUninvitedSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_uninvited_supplier_sid);
END;


FUNCTION SupplierExists (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN NUMBER
AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT NULL;
	v_uninvited_supplier_sid	security_pkg.T_SID_ID DEFAULT NULL;
BEGIN
	-- Check if company of same SO name exists
	BEGIN
		v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, helper_pkg.GetCompaniesContainer, helper_pkg.GenerateSOName(in_company_name, in_country_code));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	-- Only check companies that supply the current company
	BEGIN
		SELECT supplier_company_sid
		  INTO v_company_sid
		  FROM v$supplier_relationship
		 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND supplier_company_sid = v_company_sid
		   AND deleted=0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;
	
	-- Check if uninvited SO name exists already
	BEGIN
		v_uninvited_supplier_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.UNINVITED_SUPPLIERS||'/'||helper_pkg.GenerateSOName(in_company_name, in_country_code));
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;
	
	RETURN CASE WHEN v_company_sid IS NOT NULL OR v_uninvited_supplier_sid IS NOT NULL THEN 1 ELSE 0 END;
END;


/***********************************************************
		SearchUninvited
***********************************************************/
PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN

	-- Removed security check as people can see their own uninvited suppliers
	
	-- Find all IDs that match the search criteria
	SELECT security.T_ORDERED_SID_ROW(uninvited_supplier_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
		SELECT ui.uninvited_supplier_sid
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (LOWER(ui.name) LIKE v_search)
		   AND ui.created_as_company_sid IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page ordered by name
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT ui.uninvited_supplier_sid as company_sid, ui.app_sid, ctry.name as country_name, ui.name,
			       csr.stragg(pc.description) as purchased_components,
			       ui.country_code, row_number() OVER (ORDER BY LOWER(ui.name)) rn
			  FROM uninvited_supplier ui
			  JOIN TABLE(v_results) r ON ui.uninvited_supplier_sid = r.sid_id
			  JOIN postcode.country ctry on ctry.country = ui.country_code
			  LEFT JOIN v$purchased_component pc ON ui.uninvited_supplier_sid = pc.uninvited_supplier_sid AND pc.deleted=0
			 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY ui.uninvited_supplier_sid, ui.app_sid, ctry.name, ui.name, ui.country_code
		  ) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1
		 ORDER BY rn;

END;

/***********************************************************
		MigrateUninvitedToCompany
***********************************************************/
PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
)
AS
	v_key						supplier_relationship.virtually_active_key%TYPE;
	v_company_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied applying company_sid to uninvited supplier');
	END IF;
	
	UPDATE uninvited_supplier
	   SET created_as_company_sid = in_created_as_company_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = v_company_sid
	   AND uninvited_supplier_sid = in_uninvited_supplier_sid;
	
	company_pkg.ActivateVirtualRelationship(v_company_sid, in_created_as_company_sid, v_key);
	
	--TODO: Should we do some error checking here before attempting to migrate?
	
	purchased_component_pkg.MigrateUninvitedComponents(in_uninvited_supplier_sid, in_created_as_company_sid);
	
	--TODO: Actual migration of tasks
	
	company_pkg.DeactivateVirtualRelationship(v_key);
	
END;

/***********************************************************
		CreateUninvited
***********************************************************/
PROCEDURE CreateUninvited (
	in_name						IN	uninvited_supplier.name%TYPE,
	in_country_code				IN	uninvited_supplier.country_code%TYPE,
	out_uninvited_supplier_sid	OUT security_pkg.T_SID_ID
)
AS
	v_container_sid					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.UNINVITED_SUPPLIERS);
BEGIN
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Uninvited Supplier'), helper_pkg.GenerateSOName(in_name, in_country_code), out_uninvited_supplier_sid);
	
	-- TODO: would this be better moved to the CreateObject method as per chain company?
	-- CASEY: YES - you need to do that as this type of object is now creatable through SecMgr
	-- (even tho it's rather unlikely that people will add uninvited suppliers this way, it's still go practice to ensure that it works)
	INSERT INTO uninvited_supplier(uninvited_supplier_sid, company_sid, name, country_code)
	VALUES (out_uninvited_supplier_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_name, in_country_code);
END;


/***********************************************************
		SearchSuppliers
***********************************************************/
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
	v_supplier_results		security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	-- CASEY: I think that you should alter the existing SearchSuppliers in company_pkg to include a flag
	-- of in_include_uninvited_suppliers rather than duplicating the code here
	IF (NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ)) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;
		
		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;
		
		RETURN;
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_supplier_results
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
		 UNION
		SELECT ui.uninvited_supplier_sid
		  FROM uninvited_supplier ui
		 WHERE ui.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ui.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND LOWER(ui.name) LIKE v_search
		   AND ui.created_as_company_sid IS NULL
		   AND in_only_active = chain_pkg.inactive
	  );
	
	CollectSearchResults(v_supplier_results,  in_page, in_page_size, out_count_cur, out_result_cur);
END;

FUNCTION HasUninvitedSupsWithComponents (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM uninvited_supplier us
	  JOIN v$purchased_component c ON us.app_sid = c.app_sid AND us.uninvited_supplier_sid = c.uninvited_supplier_sid
	 WHERE us.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND us.company_sid = in_company_sid
	   AND us.created_as_company_sid IS NULL
	   AND c.deleted = 0;
	
	RETURN v_count > 0;
END;


END uninvited_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.upload_pkg
IS

PROCEDURE GetFiles (
	in_file_sids				IN	security.T_SID_TABLE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT file_upload_sid, filename, mime_type, last_modified_dtm, NULL description, lang, download_permission_id,
			   NULL charset, last_modified_dtm creation_dtm, last_modified_dtm last_accessed_dtm, length(data) bytes
		  FROM chain.file_upload
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND file_upload_sid IN (SELECT column_value FROM TABLE(in_file_sids));
END;

-- Private (for now)
FUNCTION GetCompanySid(
	in_file_sid					IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(company_sid)
	  INTO v_company_sid
	  FROM file_upload
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;

	RETURN v_company_sid;
END;

FUNCTION GetGroupCompanySid(
	in_file_group_id			IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(company_sid)
	  INTO v_company_sid
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_file_group_id;

	RETURN v_company_sid;
END;


PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	-- Only require ACLs to lock down this method we don't have a row in file_upload
	-- Capability checks must be performed before any insert to file_upload (or call to createSO)
	NULL;
END;


PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS	
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_sid_id);
BEGIN
	IF in_new_name IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting a name');
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS 
BEGIN
	IF NOT capability_pkg.CheckCapability(GetCompanySid(in_sid_id), chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to (deleting) upload files for company with sid '||GetCompanySid(in_sid_id));
	END IF;
	
	DELETE 
	  FROM component_document  
	 WHERE file_upload_sid = in_sid_id;
	
	DELETE 
	  FROM file_group_file
	 WHERE file_upload_sid = in_sid_id;
	
	-- Allow clients to delete references to this object
	chain_link_pkg.DeleteUpload(in_sid_id);
	
	DELETE 
	  FROM file_upload 
	 WHERE file_upload_sid = in_sid_id;
END;


PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
) AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_sid_id);
BEGIN
	-- don't allow move
	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied moving object');
END;


PROCEDURE CreateFileUploadFromCache(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_parent_sid				IN	security_pkg.T_SID_ID,
	in_cache_key				IN	aspen2.filecache.cache_key%type,
	out_file_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to uploaded files');
	END IF;

	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid, class_pkg.GetClassID('ChainFileUpload'), NULL, out_file_sid);

	INSERT INTO file_upload
	(file_upload_sid, filename, mime_type, data, sha1) 
	SELECT out_file_sid, filename, mime_type, object, 
		   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
	  FROM aspen2.filecache 
	 WHERE cache_key = in_cache_key;

	IF SQL%ROWCOUNT = 0 THEN
		-- pah! not found
		RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
	END IF; 
END;

FUNCTION IsChainUpload(
	in_file_sid			IN security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_exists	number(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM file_upload
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
	
	RETURN v_exists = 1;
END;


PROCEDURE DownloadFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_permision					chain_pkg.T_DOWNLOAD_PERMISSION;
	v_company_sid				security_pkg.T_SID_ID;
	v_allow_access				BOOLEAN DEFAULT FALSE;
	v_key						supplier_relationship.virtually_active_key%TYPE;
BEGIN
	
	BEGIN
		SELECT download_permission_id, company_sid
		  INTO v_permision, v_company_sid
		  FROM file_upload
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND file_upload_sid = in_file_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT 404 not_found FROM DUAL WHERE 1 = 0;
			
			RETURN;	
	END;
	
	CASE
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_STANDARD THEN
			v_allow_access := capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ);		
			
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_EVERYONE THEN		
			v_allow_access := TRUE;		
			
		WHEN v_permision = chain_pkg.DOWNLOAD_PERM_SUPPLIERS THEN			

			IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') IS NOT NULL THEN			
				IF v_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
					v_allow_access := TRUE;
				ELSE
					company_pkg.ActivateVirtualRelationship(v_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), v_key);					
					v_allow_access := company_pkg.IsSupplier(v_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));					
					company_pkg.DeactivateVirtualRelationship(v_key);
				END IF;			
			END IF;	
			
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown permission type '''||v_permision||'''');
	
	END CASE;
	
	IF NOT v_allow_access THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied downloading files from company with sid '||v_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT mime_type, filename, last_modified_dtm, data
		  FROM file_upload
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND file_upload_sid = in_file_sid;
END;

FUNCTION GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE
)
RETURN aspen2.lang.lang%TYPE
AS
	v_parent_lang			aspen2.lang.lang%TYPE;
BEGIN
	BEGIN
		SELECT parent.lang
		  INTO v_parent_lang
		  FROM aspen2.lang l
		  JOIN aspen2.lang parent ON l.parent_lang_id = parent.lang_id
		 WHERE l.lang = in_lang;
	EXCEPTION
		WHEN no_data_found THEN v_parent_lang := NULL;
	END;
	
	RETURN v_parent_lang;
END;

PROCEDURE GetParentLang(
	in_lang						IN	aspen2.lang.lang%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT lang_id, lang, description
		  FROM aspen2.lang
		 WHERE lang = GetParentLang(in_lang);
END;

-- Private
PROCEDURE GetFileGroupFileIDsForLang (
	in_group_id					IN	file_group.file_group_id%TYPE,
	out_file_group_file_ids		OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT NVL(ful_file_group_file_id, NVL(fupl_file_group_file_id, fud_file_group_file_id))
	  BULK COLLECT INTO out_file_group_file_ids
	  FROM (
		SELECT fg.file_group_id,
			   MAX(CASE WHEN ful.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) ful_file_group_file_id,
			   MAX(CASE WHEN fupl.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) fupl_file_group_file_id,
			   MAX(CASE WHEN fud.file_upload_sid IS NOT NULL THEN fgf.file_group_file_id ELSE NULL END) fud_file_group_file_id
		  FROM file_group fg
		  JOIN file_group_file fgf ON fg.app_sid = fgf.app_sid AND fg.file_group_id = fgf.file_group_id
		  LEFT JOIN file_upload ful ON fgf.app_sid = ful.app_sid AND fgf.file_upload_sid = ful.file_upload_sid AND ful.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
		  LEFT JOIN file_upload fupl ON fgf.app_sid = fupl.app_sid AND fgf.file_upload_sid = fupl.file_upload_sid AND fupl.lang = upload_pkg.GetParentLang(SYS_CONTEXT('SECURITY', 'LANGUAGE'))
		  LEFT JOIN file_upload fud ON fgf.app_sid = fud.app_sid AND fgf.file_upload_sid = fud.file_upload_sid AND fg.default_file_group_file_id = fgf.file_group_file_id
		 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND (in_group_id IS NULL OR fg.file_group_id = in_group_id)
		 GROUP BY fg.file_group_id
	  );
END;

PROCEDURE DownloadGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) 
AS
	v_file_sid					security_pkg.T_SID_ID;
	v_file_group_file_ids		security.T_SID_TABLE;
	v_model_id					file_group.file_group_model_id%TYPE;
BEGIN
	-- TODO: this is a basic implementation - if the exact file that they need isn't found, they don't get anything
	-- it would be worthwhile to set a default group file or something like that.	
	
	SELECT file_group_model_id
	  INTO v_model_id
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;
	
	CASE
		WHEN v_model_id = chain_pkg.LANGUAGE_GROUP THEN
			-- try to get the file with the language that they want
			BEGIN
				GetFileGroupFileIDsForLang(in_group_id, v_file_group_file_ids);
				
				SELECT file_upload_sid
				  INTO v_file_sid
				  FROM file_group_file
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND file_group_file_id = v_file_group_file_ids(1);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(-20001, 'File not found for group='||in_group_id||' and lang='||NVL(GetParentLang(SYS_CONTEXT('SECURITY', 'LANGUAGE')), 'LANG NOT SET'));
				WHEN TOO_MANY_ROWS THEN
					RAISE_APPLICATION_ERROR(-20001, 'Too many matches found for group='||in_group_id||' and lang='||NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'LANG NOT SET'));
			END;
		
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unhandled file group model type with id '||v_model_id);
	END CASE;
	
	DownloadFile(v_file_sid, out_cur);
END;

PROCEDURE GetFile (
	in_file_sid					IN	security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
	v_file_sids					security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	-- If we didn't find the file, we don't want an access denied, let it go through and return nothing
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading file uploads for company with sid '||v_company_sid);
	END IF;

	v_file_sids.extend(1);
	v_file_sids(1) := in_file_sid;

	GetFiles(v_file_sids, out_cur);
END;

PROCEDURE SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sid					security_pkg.T_SID_ID DEFAULT SecureFile(in_cache_key);
BEGIN
	GetFile(v_file_sid, out_cur);
END;

FUNCTION SecureFile (
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_file_sid					security_pkg.T_SID_ID;
BEGIN
	CreateFileUploadFromCache(security_pkg.GetAct, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, company_pkg.GetCompany, chain_pkg.COMPANY_UPLOADS), in_cache_key, v_file_sid);
	
	aspen2.filecache_pkg.DeleteEntry(in_cache_key);
	
	RETURN v_file_sid;
END;


PROCEDURE DeleteFile (
	in_file_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteObject(security_pkg.GetAct, in_file_sid);
END;

PROCEDURE RegisterGroup (
	in_guid						IN  file_group.guid%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_title					IN  file_group.title%TYPE,
	in_description				IN  file_group.description%TYPE,
	in_group_model				IN  chain_pkg.T_FILE_GROUP_MODEL,
	in_download_permission 		IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'RegisterGroup can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO file_group
		(file_group_id, company_sid, title, description, file_group_model_id, download_permission_id, guid)
		VALUES
		(file_group_id_seq.NEXTVAL, in_company_sid, in_title, in_description, in_group_model, in_download_permission, LOWER(in_guid));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			
			UPDATE file_group
			   SET company_sid = in_company_sid,
			       title = in_title,
			       description = in_description,
			       file_group_model_id = in_group_model,
			       download_permission_id = in_download_permission
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND guid = LOWER(in_guid);
	END;
END;

PROCEDURE SecureGroupFile (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_cache_key				IN	aspen2.filecache.cache_key%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sid					security_pkg.T_SID_ID DEFAULT SecureFile(in_cache_key);
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetGroupCompanySid(in_group_id);
	v_perm						chain_pkg.T_DOWNLOAD_PERMISSION;
BEGIN
	IF v_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Group company mismatch ('||v_company_sid||')');
	END IF;
	
	INSERT INTO file_group_file
	(file_group_id, file_upload_sid, file_group_file_id)
	SELECT in_group_id, v_file_sid, file_group_file_id_seq.NEXTVAL
	  FROM dual;
	
	SELECT download_permission_id
	  INTO v_perm
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;
	
	UPDATE file_upload
	   SET download_permission_id = v_perm
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = v_file_sid;
	
	GetFile(v_file_sid, out_cur);
END;

PROCEDURE SetDefaultGroupFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
)
AS
	v_file_group_file_id		file_group_file.file_group_file_id%TYPE;
BEGIN
	SELECT file_group_file_id
	  INTO v_file_group_file_id
	  FROM file_group_file
	 WHERE app_sid = security_pkg.GetApp
	   AND file_group_id = in_group_id
	   AND file_upload_sid = in_file_upload_sid;
	
	UPDATE file_group
	   SET default_file_group_file_id = v_file_group_file_id
	 WHERE app_sid = security_pkg.GetApp
	   AND file_group_id = in_group_id;
END;

PROCEDURE SetGroupPermission (
	in_group_id					IN  file_group.file_group_id%TYPE,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetGroupCompanySid(in_group_id);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;

	UPDATE file_group
	   SET download_permission_id = in_permission
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_group_id = in_group_id;

	UPDATE file_upload
	   SET download_permission_id = in_permission
	 WHERE (app_sid, file_upload_sid) IN (
	 			SELECT app_sid, file_upload_sid 
	 			  FROM file_group_file 
	 			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	 			   AND file_group_id = in_group_id
	 		);
END;

PROCEDURE SetFilePermission (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_permission				IN  chain_pkg.T_DOWNLOAD_PERMISSION
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
	v_is_group_file				NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_is_group_file
	  FROM file_group_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
	
	IF v_is_group_file > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannot change the invidual permissions of group files');
	END IF;
	
	UPDATE file_upload
	   SET download_permission_id = in_permission
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
END;

PROCEDURE SetFileLang (
	in_file_sid					IN  security_pkg.T_SID_ID,
	in_lang						IN  file_upload.lang%TYPE
)
AS
	v_company_sid 				security_pkg.T_SID_ID DEFAULT GetCompanySid(in_file_sid);
BEGIN
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||v_company_sid);
	END IF;
	
	UPDATE file_upload
	   SET lang = in_lang
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND file_upload_sid = in_file_sid;
END;

PROCEDURE GetGroups (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sids					security.T_SID_TABLE;
BEGIN
	--if they want to read groups, they need to be able to write
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_groups_cur FOR
		SELECT file_group_id, title, description, download_permission_id, guid, default_file_group_file_id
		  FROM file_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY LOWER(title);

	OPEN out_group_files_cur FOR
		SELECT fgf.file_group_id, fgf.file_upload_sid, fgf.file_group_file_id
		  FROM file_group_file fgf, file_group fg
		 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fg.app_sid = fgf.app_sid
		   AND fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND fg.file_group_id = fgf.file_group_id;

	SELECT fgf.file_upload_sid
	  BULK COLLECT INTO v_file_sids
	  FROM file_group_file fgf, file_group fg
	 WHERE fg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND fg.app_sid = fgf.app_sid
	   AND fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fg.file_group_id = fgf.file_group_id;
	
	GetFiles(v_file_sids, out_files_cur);
END;

PROCEDURE GetGroupsForLang (
	out_groups_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_group_files_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_files_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_file_sids					security.T_SID_TABLE;
	v_file_group_file_ids		security.T_SID_TABLE;
BEGIN
	--if they want to read groups, they need to be able to write
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_groups_cur FOR
		SELECT file_group_id, title, description, download_permission_id, guid, default_file_group_file_id
		  FROM file_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY LOWER(title);

	GetFileGroupFileIDsForLang(NULL, v_file_group_file_ids);
	
	OPEN out_group_files_cur FOR
		SELECT fgf.file_group_id, fgf.file_upload_sid, fgf.file_group_file_id
		  FROM file_group_file fgf
		  JOIN TABLE(v_file_group_file_ids) f ON fgf.file_group_file_id = f.column_value
		 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT fgf.file_upload_sid
	  BULK COLLECT INTO v_file_sids
	  FROM file_group_file fgf
	  JOIN TABLE(v_file_group_file_ids) f ON fgf.file_group_file_id = f.column_value
	 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	GetFiles(v_file_sids, out_files_cur);
END;

FUNCTION GetGroupId (
	in_guid						IN  file_group.guid%TYPE
) RETURN file_group.file_group_id%TYPE
AS
	v_group_id					file_group.file_group_id%TYPE;
BEGIN
	SELECT file_group_id
	  INTO v_group_id
	  FROM file_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND guid = LOWER(in_guid);
	
	RETURN v_group_id;
END;

PROCEDURE SetGroupDefaultFile (
	in_group_id					IN	file_group.file_group_id%TYPE,
	in_file_upload_sid			IN	security_pkg.T_SID_ID
)
AS
	v_file_group_file_id		file_group_file.file_group_file_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to file uploads for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	IF in_file_upload_sid IS NULL THEN
		UPDATE file_group
		   SET default_file_group_file_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND file_group_id = in_group_id;
	ELSE
		SELECT fgf.file_group_file_id
		  INTO v_file_group_file_id
		  FROM file_group_file fgf
		  JOIN file_group fg ON fgf.app_sid = fg.app_sid AND fgf.file_group_id = fg.file_group_id
		 WHERE fgf.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fg.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND fg.file_group_id = in_group_id
		   AND fgf.file_upload_sid = in_file_upload_sid;
		
		UPDATE file_group
		   SET default_file_group_file_id = v_file_group_file_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND file_group_id = in_group_id;
	END IF;
END;


END upload_pkg;
/


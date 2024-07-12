CREATE OR REPLACE PACKAGE  CHAIN.chain_pkg
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

CT_HOTSPOTTER						CONSTANT T_CAPABILITY := 'CT Hotspotter';

/**** Common capabilities ****/
IS_TOP_COMPANY						CONSTANT T_CAPABILITY := 'Is top company';
SEND_QUESTIONNAIRE_INVITE			CONSTANT T_CAPABILITY := 'Send questionnaire invitation';
SEND_NEWSFLASH						CONSTANT T_CAPABILITY := 'Send newsflash';
RECEIVE_USER_TARGETED_NEWS			CONSTANT T_CAPABILITY := 'Receive user-targeted newsflash';
APPROVE_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Approve questionnaire';
CHANGE_SUPPLIER_FOLLOWER			CONSTANT T_CAPABILITY := 'Change supplier follower';

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
CANNOT_ACCEPT_TERMS					CONSTANT T_INVITATION_STATUS := 9;-- only one user allowed to self-register per company 
NOT_INVITED							CONSTANT T_INVITATION_STATUS := 10; -- pseudo status

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
NOT_SHARED_PENDING	 				CONSTANT T_SHARE_STATUS := 16; -- Pseudo status - a catch-all of not shared / rejected / returned
NOT_SHARED_OVERDUE	 				CONSTANT T_SHARE_STATUS := 17; -- Pseudo status - pending and due date expired
NOT_SENT			 				CONSTANT T_SHARE_STATUS := 18; -- Pseudo status - supplier not sent questionnaire

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
TO_DO_LIST							CONSTANT T_PRIORITY_TYPE := 3;

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
QNR_SUBMITTED_NO_REVIEW				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 306;

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

DOWNLOAD_PERM_STANDARD					CONSTANT T_DOWNLOAD_PERMISSION := 0;
DOWNLOAD_PERM_EVERYONE					CONSTANT T_DOWNLOAD_PERMISSION := 1;
DOWNLOAD_PERM_SUPPLIERS					CONSTANT T_DOWNLOAD_PERMISSION := 2;
DOWNLOAD_PERM_STND_TRANS				CONSTANT T_DOWNLOAD_PERMISSION := 3; -- Standard transparancy
DOWNLOAD_PERM_PRTCTD_TRANS				CONSTANT T_DOWNLOAD_PERMISSION := 4; -- Protected transparancy

-- the intention here is that different grouping models can be put in
-- e.g. - the lauguage group selects the best file for the user's language settings
-- another example might be zip group - downloading mulitple files as a single zip file, etc.
SUBTYPE T_FILE_GROUP_MODEL			IS NUMBER;

LANGUAGE_GROUP						CONSTANT T_FILE_GROUP_MODEL := 0;


-- CSR style capability - check to see if the user can edit file upload groups that are not "global" - e.g not linked to a specific company
EDIT_GLOBAL_FILE_GROUPS				CONSTANT csr.capability.name%TYPE := 'Chain edit site global file groups';

/****************************************************************************************************/

SUBTYPE T_AMOUNT_UNIT_TYPE			IS VARCHAR2(32);

AUT_FRACTION						CONSTANT T_AMOUNT_UNIT_TYPE := 'fraction';
AUT_MASS							CONSTANT T_AMOUNT_UNIT_TYPE := 'mass';
AUT_UNIT							CONSTANT T_AMOUNT_UNIT_TYPE := 'unit';
AUT_VOLUME							CONSTANT T_AMOUNT_UNIT_TYPE := 'volume';

SUBTYPE T_AMOUNT_UNIT				IS NUMBER(10);

AU_PERCENTAGE						CONSTANT T_AMOUNT_UNIT := 1;

	
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

-- literally deletes everything (called primary by csr_data_pkg)
PROCEDURE DeleteChainData(
	in_app_sid			IN	security_pkg.T_SID_ID
);

END chain_pkg;
/




CREATE OR REPLACE PACKAGE  CHAIN.temp_capability_pkg
IS

FUNCTION GetCapabilityPath (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY
)RETURN VARCHAR2;

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
);

END temp_capability_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.temp_capability_pkg
IS

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

PROCEDURE DeleteCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY
)
AS
	v_act_id				security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'DeleteCapability can only be run as BuiltIn/Administrator');
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
				security.securableobject_pkg.DeleteSO(v_act_id, security.securableobject_pkg.GetSIDFromPath(v_act_id, com.company_sid, GetCapabilityPath(cap.capability_type_id, cap.capability_name)));
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
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

END temp_capability_pkg;
/
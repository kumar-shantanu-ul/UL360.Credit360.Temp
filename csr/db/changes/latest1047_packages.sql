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
CT_EMPLOYEE_COMMUTE					CONSTANT T_CAPABILITY := 'CT Employee Commute';

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
PROCEDURE RegisterCapability (
	in_capability_type			IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability				IN  chain_pkg.T_CAPABILITY,
	in_perm_type				IN  chain_pkg.T_CAPABILITY_PERM_TYPE
);

PROCEDURE GrantCapability (
	in_capability_type		IN  chain_pkg.T_CAPABILITY_TYPE,
	in_capability			IN  chain_pkg.T_CAPABILITY,
	in_group				IN  chain_pkg.T_GROUP,
	in_permission_set		IN  security_Pkg.T_PERMISSION
);

PROCEDURE RefreshCompanyCapabilities (
	in_company_sid			IN  security_pkg.T_SID_ID
);

END temp_capability_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.temp_capability_pkg
IS
-- CAPABILITY PKG
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

	-- This is a set permission operation, not an add, so remove any existing ACEs for the group in question
	acl_pkg.RemoveACEsForSid(
		v_act_id,
		Acl_pkg.GetDACLIDForSID(v_capability_sid),
		v_group_sid
	);

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
	-- TODO: This ought to clean up after itself when called multiple times, remove the old ACE and combine with the new ACE
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

END temp_capability_pkg;
/


-- Card
CREATE OR REPLACE PACKAGE  CHAIN.temp_card_pkg
IS
PROCEDURE RegisterCardGroup (
	in_id					IN  card_group.card_group_id%TYPE,
	in_name					IN  card_group.name%TYPE,
	in_description			IN  card.description%TYPE
);

PROCEDURE SetGroupCards (
	in_group_name			IN  card_group.name%TYPE,
	in_card_js_types		IN  T_STRING_LIST
);

PROCEDURE RegisterCard (
	in_desc					IN  card.description%TYPE,
	in_class				IN  card.class_type%TYPE,
	in_js_path				IN  card.js_include%TYPE,
	in_js_class				IN  card.js_class_type%TYPE
);

END temp_card_pkg;
/

CREATE OR REPLACE PACKAGE BODY CHAIN.temp_card_pkg
IS

DEFAULT_ACTION 				CONSTANT VARCHAR2(10) := 'default';

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

END temp_card_pkg;
/
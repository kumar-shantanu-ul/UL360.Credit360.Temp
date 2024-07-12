define version=72
@update_header

DECLARE
	v_class_id				security_pkg.T_CLASS_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_chain_users_sid		security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
	
	user_pkg.logonadmin;
	
	-- it needs to be applied to all companies in the application - as a rule of thumb, anything SO related is "global"
	FOR c IN (
		SELECT app_sid, company_sid, rownum as rn
		  FROM chain.company 
		 ORDER BY app_sid
		
		
	) LOOP

		-- if the app_sid is changing or if first row just to be sure...
		IF c.app_sid <> NVL(SYS_CONTEXT('SECURITY', 'APP'), 0) OR c.rn=1 THEN
			-- log us on (here's yet another method to log someone on - have a look at cvs\security\db\oracle\user_pkg.sql for even more!)
			user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 86400, c.app_sid, v_act_id);
			
			BEGIN
				v_class_id := class_pkg.GetClassID('Chain Uninvited Supplier');
			EXCEPTION 
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					class_pkg.CreateClass(security_pkg.getACT, null, 'Chain Uninvited Supplier', 'chain.uninvited_pkg', null, v_class_id);
			END;	
			
			v_chain_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, c.app_sid, 'Groups/'||chain.chain_pkg.CHAIN_USER_GROUP);
		END IF;
		
		BEGIN
			securableobject_pkg.CreateSO(v_act_id, c.company_sid, security_pkg.SO_CONTAINER, chain.chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
							
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
		EXCEPTION 
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;	
		
	END LOOP;
	
	user_pkg.logoff(security_pkg.GetAct);
END;
/

BEGIN
	FOR r IN (
		SELECT host 
		  FROM v$chain_host 
	) LOOP
		user_pkg.LogonAdmin(r.host);
		
		DECLARE
			v_class_id		security_pkg.T_CLASS_ID;
		BEGIN
			class_pkg.CreateClass(security_pkg.getACT, null, 'ChainFileUpload', 'chain.upload_pkg', null, v_class_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
		
		user_pkg.Logoff(security_pkg.getact);
	END LOOP;
END;
/

CREATE OR REPLACE PACKAGE  chain_pkg
IS

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;

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
SUBTYPE T_MESSAGE_TYPE				IS NUMBER;
EVENT								CONSTANT T_MESSAGE_TYPE := 1;
ACTION								CONSTANT T_MESSAGE_TYPE := 2;

SUBTYPE T_REPEAT_TYPE				IS NUMBER;
NEVER_REPEAT						CONSTANT T_REPEAT_TYPE := 0;
REPEAT_IF_CLOSED					CONSTANT T_REPEAT_TYPE := 1;
REFRESH_IF_OPEN						CONSTANT T_REPEAT_TYPE := 2;
ALWAYS_REPEAT						CONSTANT T_REPEAT_TYPE := 3;

SUBTYPE T_ADDRESS_TYPE				IS NUMBER;
PRIVATE_ADDRESS						CONSTANT T_ADDRESS_TYPE := 1;
USER_ADDRESS						CONSTANT T_ADDRESS_TYPE := 2;
COMPANY_ADDRESS						CONSTANT T_ADDRESS_TYPE := 3;

SUBTYPE T_PRIORITY_TYPE				IS NUMBER;
--HIDDEN (defined above)			CONSTANT T_PRIORITY_TYPE := 0;
NEUTRAL								CONSTANT T_PRIORITY_TYPE := 1;
HIGHLIGHTED							CONSTANT T_PRIORITY_TYPE := 2;
XEXCLUSIVE							CONSTANT T_PRIORITY_TYPE := 3;

/****************************************************************************************************/
SUBTYPE T_MESSAGE_DEFINITION_LOOKUP	IS NUMBER;
-- Secondary directional stuff --
NONE_IMPLIED						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 0;
PURCHASER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
SUPPLIER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Administrative messaging --
CONFIRM_COMPANY_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
CONFIRM_YOUR_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Invitation messaging --
INVITATION_SENT						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
INVITATION_ACCEPTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
INVITATION_REJECTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;

-- Questionnaire messaging --
COMPLETE_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
QUESTIONNAIRE_SUBMITTED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
REVIEW_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 201;
QUESTIONNAIRE_APPROVED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 202;

-- Component messaging --
PRODUCT_MAPPING_REQUIRED			CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 300;

-- MAERSK --
SUPPLIER_REG_DETAILS_CHANGED		CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1000;
ACTION_PLAN_STARTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1000;

/****************************************************************************************************/
SUBTYPE T_COMPONENT_CODE			IS component.component_code%TYPE;

SUBTYPE T_COMPONENT_TYPE			IS NUMBER;

-- COMPONENT types
PRODUCT_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 1;
LOGICAL_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 2;
PURCHASED_COMPONENT					CONSTANT T_COMPONENT_TYPE := 3;
NOTSURE_COMPONENT					CONSTANT T_COMPONENT_TYPE := 4;

-- CLIENT SPECIFC COMPONENT TYPES 
RA_ROOT_PROD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 48;
RA_ROOT_WOOD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 49;
RA_WOOD_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 50;
RA_WOOD_ESTIMATE_COMPONENT			CONSTANT T_COMPONENT_TYPE := 51;

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

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG;

END chain_pkg;
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
				NVL(default_url, '/') default_url
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

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG
AS
BEGIN
	IF security.bitwise_pkg.bitand(in_flags, in_flag) = 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;


END chain_pkg;
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

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
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
	in_company_sid 			IN security_pkg.T_SID_ID
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

PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
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
   WHERE reinvitation_of_invitation_id IN (
      SELECT invitation_id 
	    FROM invitation 
	   WHERE ((from_company_sid = in_sid_id) 
          OR (to_company_sid = in_sid_id))	
         AND app_sid = security_pkg.GetApp);
	   
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
	-- TODO: we'll need to fix this up...
	--DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));	
	--DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	--DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	--DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

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
	
	DELETE 
	  FROM supplier_relationship
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

BEGIN
	user_pkg.logonadmin;
	
	FOR r IN (
		SELECT * FROM v$chain_host
	) LOOP
		user_pkg.logonadmin(r.host);
		
		FOR c IN (
			SELECT * FROM company WHERE app_sid = security_pkg.GetApp
		) LOOP
			capability_pkg.RefreshCompanyCapabilities(c.company_sid);
		END LOOP;
		
	END LOOP;
	
	user_pkg.logoff(security_pkg.getact);
	
END;
/

@update_tail

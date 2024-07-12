-- Please update version.sql too -- this keeps clean builds in sync
define version=1038
@update_header

CREATE TABLE CT.TEMPLATE_KEY (
    LOOKUP_KEY VARCHAR2(255) NOT NULL,
    DESCRIPTION VARCHAR2(255) NOT NULL,
    POSITION NUMBER(10) NOT NULL,
    CONSTRAINT PK_TEMPLATE_KEY PRIMARY KEY (LOOKUP_KEY),
    CONSTRAINT TCC_TEMPLATE_KEY_1 CHECK (LOOKUP_KEY = LOWER(TRIM(LOOKUP_KEY)))
);

SET DEFINE #;
BEGIN
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_primary', 'Hotspot Report - Primary', 1);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_business_sector', 'Hotspot Report - Business Sector Section', 2);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_geographic_region', 'Hotspot Report - Geographic Region Section', 3);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_scope12', 'Hotspot Report - Scope 1 & 2 Section', 4);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_combined', 'Hotspot Report - Analysis - Both Sections Combined', 5);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_business_sector', 'Hotspot Report - Analysis - Business Sector Section', 6);
	INSERT INTO CT.template_key (lookup_key, description, position) VALUES ('hotspot_report_analysis_geographic_region', 'Hotspot Report - Analysis - Geographic Region Section', 7);
	
	UPDATE CT.report_template SET lookup_key = 'hotspot_report_analysis_combined' WHERE lookup_key = 'hotspot_report_analysis';
	UPDATE CT.report_template SET lookup_key = 'hotspot_report_geographic_region' WHERE lookup_key = 'hotspot_report_geographic_sector';
END;
/
SET DEFINE &;

ALTER TABLE CT.REPORT_TEMPLATE ADD CONSTRAINT TEMPLATE_KEY_REPORT_TPL 
    FOREIGN KEY (LOOKUP_KEY) REFERENCES CT.TEMPLATE_KEY (LOOKUP_KEY);

-- CSR_DATA_PKG required.
	
CREATE OR REPLACE PACKAGE CSR.Csr_Data_Pkg AS
-- standard constraint violated exception
CHILD_RECORD_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(CHILD_RECORD_FOUND, -02292);
-- errors
ERR_PERIOD_UNRECOGNISED				CONSTANT NUMBER := -20310; 
PERIOD_UNRECOGNISED EXCEPTION;
PRAGMA EXCEPTION_INIT(PERIOD_UNRECOGNISED, -20310);
ERR_OBJECT_IS_MOUNT_POINT			CONSTANT NUMBER := -20311; 
OBJECT_IS_MOUNT_POINT EXCEPTION;
PRAGMA EXCEPTION_INIT(OBJECT_IS_MOUNT_POINT, -20311);
ERR_OBJECT_IN_USE					CONSTANT NUMBER := -20312; 
OBJECT_IN_USE EXCEPTION;
PRAGMA EXCEPTION_INIT(OBJECT_IN_USE, -20312);
ERR_OBJECT_ALREADY_ALLOCATED		CONSTANT NUMBER := -20313;
OBJECT_ALREADY_ALLOCATED EXCEPTION;
PRAGMA EXCEPTION_INIT(OBJECT_ALREADY_ALLOCATED, -20313);
ERR_CIRCULAR_REFERENCE				CONSTANT NUMBER := -20314;
CIRCULAR_REFERENCE EXCEPTION;
PRAGMA EXCEPTION_INIT(CIRCULAR_REFERENCE, -20314);
ERR_JOB_NOT_FOUND					CONSTANT NUMBER := -20315;
JOB_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(JOB_NOT_FOUND, -20315);
ERR_JOB_ALREADY_RUNNING				CONSTANT NUMBER := -20316;
JOB_ALREADY_RUNNING EXCEPTION;
PRAGMA EXCEPTION_INIT(JOB_ALREADY_RUNNING, -20316);
ERR_WRONG_IND_TYPE_FOR_CALC 		CONSTANT NUMBER := -20317;
WRONG_IND_TYPE_FOR_CALC EXCEPTION;
PRAGMA EXCEPTION_INIT(WRONG_IND_TYPE_FOR_CALC, -20317);
ERR_NOT_ALLOWED_WRITE				CONSTANT NUMBER := -20317;
NOT_ALLOWED_WRITE EXCEPTION;
PRAGMA EXCEPTION_INIT(NOT_ALLOWED_WRITE, -20317);
ERR_VALUES_NOT_COMPLETED			CONSTANT NUMBER := -20318;
VALUES_NOT_COMPLETED EXCEPTION;
PRAGMA EXCEPTION_INIT(VALUES_NOT_COMPLETED, -20318);
ERR_ALREADY_SUBMITTED				CONSTANT NUMBER := -20319;
ALREADY_SUBMITTED EXCEPTION;
PRAGMA EXCEPTION_INIT(ALREADY_SUBMITTED, -20319);
ERR_NOTES_NOT_COMPLETED				CONSTANT NUMBER := -20320;
NOTES_NOT_COMPLETED EXCEPTION;
PRAGMA EXCEPTION_INIT(NOTES_NOT_COMPLETED, -20320);
ERR_PREVIOUS_PARENT_TRASHED			CONSTANT NUMBER := -20321;
PREVIOUS_PARENT_TRASHED EXCEPTION;
PRAGMA EXCEPTION_INIT(PREVIOUS_PARENT_TRASHED, -20321);
ERR_ALERT_ALREADY_RAISED			CONSTANT NUMBER := -20322;
ALERT_ALREADY_RAISED EXCEPTION;
PRAGMA EXCEPTION_INIT(ALERT_ALREADY_RAISED, -20322);
ERR_ALERT_TEMPLATE_NOT_FOUND		CONSTANT NUMBER := -20323;
ALERT_TEMPLATE_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(ALERT_TEMPLATE_NOT_FOUND, -20323);
ERR_SHEET_OVERLAPS					CONSTANT NUMBER := -20324;
SHEET_OVERLAPS EXCEPTION;
PRAGMA EXCEPTION_INIT(SHEET_OVERLAPS, -20324);
ERR_SUBMISSION_BLOCKED				CONSTANT NUMBER := -20325;
SUBMISSION_BLOCKED EXCEPTION;
PRAGMA EXCEPTION_INIT(SUBMISSION_BLOCKED, -20325);
ERR_CANNOT_SUBDIVIDE_REGION				CONSTANT NUMBER := -20326;
CANNOT_SUBDIVIDE_REGION EXCEPTION;
PRAGMA EXCEPTION_INIT(CANNOT_SUBDIVIDE_REGION, -20326);
ERR_INVALID_PROGRESSION_ID				CONSTANT NUMBER := -20327;
BAD_INVALID_PROGRESSION_ID EXCEPTION;
PRAGMA EXCEPTION_INIT(BAD_INVALID_PROGRESSION_ID, -20327);
ERR_INVALID_ISSUE_ID				CONSTANT NUMBER := -20328;
INVALID_ISSUE_ID EXCEPTION;
PRAGMA EXCEPTION_INIT(INVALID_ISSUE_ID, -20328);
ERR_ARRAY_SIZE_MISMATCH				CONSTANT NUMBER := -20329;
ARRAY_SIZE_MISMATCH EXCEPTION;
PRAGMA EXCEPTION_INIT(ARRAY_SIZE_MISMATCH, -20329);
ERR_PARENT_IN_PRIMARY_TREE				CONSTANT NUMBER := -20330;
PARENT_IN_PRIMARY_TREE EXCEPTION;
PRAGMA EXCEPTION_INIT(PARENT_IN_PRIMARY_TREE, -20330);
ERR_SHEETS_EXIST				CONSTANT NUMBER := -20331;
SHEETS_EXIST EXCEPTION;
PRAGMA EXCEPTION_INIT(SHEETS_EXIST, -20331);
ERR_METER_READING_TOO_LOW				CONSTANT NUMBER := -20332;
METER_READING_TOO_LOW EXCEPTION;
PRAGMA EXCEPTION_INIT(METER_READING_TOO_LOW, -20332);
ERR_METER_READING_TOO_HIGH				CONSTANT NUMBER := -20333;
METER_READING_TOO_HIGH EXCEPTION;
PRAGMA EXCEPTION_INIT(METER_READING_TOO_HIGH, -20333);
ERR_METER_PERIOD_OVERLAP				CONSTANT NUMBER := -20334;
METER_METER_PERIOD_OVERLAP EXCEPTION;
PRAGMA EXCEPTION_INIT(METER_READING_TOO_HIGH, -20334);
ERR_CANT_MOVE_REGION_GEO				CONSTANT NUMBER := -20335;
REGION_CANT_MOVE_REGION_GEO EXCEPTION;
PRAGMA EXCEPTION_INIT(REGION_CANT_MOVE_REGION_GEO, -20335);
ERR_VALUES_EXIST						CONSTANT NUMBER := -20336;
VALUES_EXIST EXCEPTION;
PRAGMA EXCEPTION_INIT(VALUES_EXIST, -20336);
ERR_NOT_UNDER_REGION_TREE				CONSTANT NUMBER := -20337;
NOT_UNDER_REGION_TREE EXCEPTION;
PRAGMA EXCEPTION_INIT(NOT_UNDER_REGION_TREE, -20337);
ERR_PARENT_MUST_BE_METER				CONSTANT NUMBER := -20338;
PARENT_MUST_BE_METER EXCEPTION;
PRAGMA EXCEPTION_INIT(NOT_UNDER_REGION_TREE, -20338);
ERR_DELEGATION_USED_AS_TPL				CONSTANT NUMBER := -20339;
DELEGATION_USED_AS_TPL EXCEPTION;
PRAGMA EXCEPTION_INIT(DELEGATION_USED_AS_TPL, -20339);
ERR_CANT_MODIFY_SYSTEM_IND				CONSTANT NUMBER := -20340;
CANT_MODIFY_SYSTEM_IND EXCEPTION;
PRAGMA EXCEPTION_INIT(CANT_MODIFY_SYSTEM_IND, -20340);
ERR_LOGISTICS_COUNTRY_INVALID			CONSTANT NUMBER := -20341;
LOGISTICS_COUNTRY_INVALID EXCEPTION;
PRAGMA EXCEPTION_INIT(LOGISTICS_COUNTRY_INVALID, -20341);
ERR_FLOW_HAS_NO_DEFAULT_STATE					CONSTANT NUMBER := -20342;
FLOW_HAS_NO_DEFAULT_STATE EXCEPTION;
PRAGMA EXCEPTION_INIT(FLOW_HAS_NO_DEFAULT_STATE, -20342);
ERR_STD_MEASURE_CONV_CHANGE				CONSTANT NUMBER := -20343;
STD_MEASURE_CONV_CHANGE EXCEPTION;
PRAGMA EXCEPTION_INIT(STD_MEASURE_CONV_CHANGE, -20343);
ERR_FLOW_STATE_CHANGE_FAILED			CONSTANT NUMBER := -20344;
FLOW_STATE_CHANGE_FAILED EXCEPTION;
PRAGMA EXCEPTION_INIT(FLOW_STATE_CHANGE_FAILED, -20344);
ERR_OBJECT_ALREADY_EXISTS				CONSTANT NUMBER := -20345;
OBJECT_ALREADY_EXISTS EXCEPTION;
PRAGMA EXCEPTION_INIT(OBJECT_ALREADY_EXISTS, -20345);

TYPE   T_VARCHAR_ARRAY  IS TABLE OF VARCHAR2(1024) INDEX BY PLS_INTEGER;
TYPE   T_NUMBER_ARRAY  IS TABLE OF NUMBER(10) INDEX BY PLS_INTEGER;

SUBTYPE T_VAL_NUMBER					IS VAL.VAL_NUMBER%TYPE;
SUBTYPE T_SHEET_ID						IS SHEET.SHEET_ID%TYPE;
SUBTYPE T_FLOW_STATE_ID					IS FLOW_STATE.FLOW_STATE_ID%TYPE;
SUBTYPE T_FLOW_STATE_TRANSITION_ID		IS FLOW_STATE_TRANSITION.FLOW_STATE_TRANSITION_ID%TYPE;
SUBTYPE T_FLOW_ITEM_ID					IS FLOW_ITEM.FLOW_ITEM_ID%TYPE;
SUBTYPE T_FLOW_COMMENT_TEXT				IS FLOW_STATE_LOG.COMMENT_TEXT%TYPE;
SUBTYPE T_LOOKUP_KEY					IS VARCHAR2(255);
SUBTYPE T_DOTNET_NUMBER					IS NUMBER(24,10);

-- indicator permission
PERMISSION_SET_TARGET			CONSTANT NUMBER(10) := 65536;
PERMISSION_SET_STATUS			CONSTANT NUMBER(10) := 131072;
PERMISSION_ALTER_SCHEMA			CONSTANT NUMBER(10) := 262144;
PERMISSION_OVERRIDE_DELEGATOR	CONSTANT NUMBER(10) := 524288;
-- csr user and csr group permissions
PERMISSION_LOGON_AS_USER		CONSTANT security_pkg.T_PERMISSION := 65536;
-- trash can permissions
PERMISSION_RESTORE_FROM_TRASH	CONSTANT security_pkg.T_PERMISSION := 65536;
-- quick survey permissions
PERMISSION_VIEW_ALL_RESULTS		CONSTANT security_pkg.T_PERMISSION := 65536;
-- delegation permissions
/*
security_pkg.PERMISSION_READ
security_pkg.PERMISSION_WRITE
security_pkg.PERMISSION_READ_PERMISSIONS
security_pkg.PERMISSION_LIST_CONTENTS
security_pkg.PERMISSION_READ_ATTRIBUTES
security_pkg.PERMISSION_WRITE_ATTRIBUTES
security_pkg.PERMISSION_ADD_CONTENTS
*/
PERMISSION_STANDARD_DELEGEE		CONSTANT security_pkg.T_PERMISSION := 995; -- 
PERMISSION_STANDARD_DELEGATOR	CONSTANT security_pkg.T_PERMISSION := 263139; -- change to use 263143? includes PERMISSION_ALTER_SCHEMA -- HMM -- change so that users can delete?
DIVISIBILITY_AVERAGE 		CONSTANT NUMBER(1) := 0;
DIVISIBILITY_DIVISIBLE 		CONSTANT NUMBER(1) := 1;
DIVISIBILITY_LAST_PERIOD 	CONSTANT NUMBER(1) := 2;
IND_TYPE_NORMAL			CONSTANT NUMBER(1) := 0;
IND_TYPE_CALC			CONSTANT NUMBER(1) := 1;
IND_TYPE_STORED_CALC	CONSTANT NUMBER(1) := 2;
IND_TYPE_AGGREGATE		CONSTANT NUMBER(1) := 3;

DEP_ON_INDICATOR	CONSTANT NUMBER(10) := 1;
DEP_ON_CHILDREN		CONSTANT NUMBER(10) := 2;
DEP_ON_MODEL		CONSTANT NUMBER(10) := 3;
RANGE_FLAG_SHOW_TOTALS	CONSTANT NUMBER(10) := 1;
ACTION_WAITING					CONSTANT NUMBER(10) := 0;
ACTION_WAITING_WITH_MOD			CONSTANT NUMBER(10) := 10;
ACTION_SUBMITTED				CONSTANT NUMBER(10) := 1;
ACTION_SUBMITTED_WITH_MOD		CONSTANT NUMBER(10) := 11;
ACTION_ACCEPTED					CONSTANT NUMBER(10) := 3;
ACTION_ACCEPTED_WITH_MOD		CONSTANT NUMBER(10) := 6; 
ACTION_MERGED					CONSTANT NUMBER(10) := 9;
ACTION_MERGED_WITH_MOD			CONSTANT NUMBER(10) := 12;
ACTION_RETURNED					CONSTANT NUMBER(10) := 2;
/* duff codes */
ACTION_AMENDED					CONSTANT NUMBER(10) := 4; -- unused
ACTION_REJECTED					CONSTANT NUMBER(10) := 5; -- unused
ACTION_PARTIALLY_SUBMITTED		CONSTANT NUMBER(10) := 7; -- unused
ACTION_PARTIALLY_AUTHORISED		CONSTANT NUMBER(10) := 8; -- unused
SOURCE_TYPE_DIRECT			CONSTANT NUMBER(10) := 0;
SOURCE_TYPE_DELEGATION		CONSTANT NUMBER(10) := 1;
SOURCE_TYPE_IMPORT			CONSTANT NUMBER(10) := 2;
SOURCE_TYPE_LOGGING			CONSTANT NUMBER(10) := 3;
SOURCE_TYPE_ESTIMATOR		CONSTANT NUMBER(10) := 4;
SOURCE_TYPE_AGGREGATOR		CONSTANT NUMBER(10) := 5;
SOURCE_TYPE_STORED_CALC		CONSTANT NUMBER(10) := 6;
SOURCE_TYPE_PENDING		    CONSTANT NUMBER(10) := 7;
SOURCE_TYPE_METER		    CONSTANT NUMBER(10) := 8;
SOURCE_TYPE_ROLLED_FORWARD	CONSTANT NUMBER(10) := 9;
SOURCE_TYPE_REALTIME_METER	CONSTANT NUMBER(10) := 10;
SOURCE_TYPE_QUICK_SURVEY	CONSTANT NUMBER(10) := 11;
SOURCE_TYPE_AGGREGATE_GRP	CONSTANT NUMBER(10) := 12;
SOURCE_TYPE_ENERGY_STAR		CONSTANT NUMBER(10) := 13;

AGGREGATOR_ERROR_BLOCKER	CONSTANT NUMBER(10) := 0;
AGGREGATOR_ERROR_FAILED		CONSTANT NUMBER(10) := 1;
USER_LEVEL_DELEGATOR		CONSTANT NUMBER(10) := 1;
USER_LEVEL_DELEGEE			CONSTANT NUMBER(10) := 2;
USER_LEVEL_OTHER			CONSTANT NUMBER(10) := 3;
USER_LEVEL_BOTH			CONSTANT NUMBER(10) := 4;
SHEET_VALUE_ENTERED			CONSTANT NUMBER(10) := 0;
SHEET_VALUE_SUBMITTED		CONSTANT NUMBER(10) := 1;
SHEET_VALUE_ACCEPTED		CONSTANT NUMBER(10) := 2;
SHEET_VALUE_MERGED			CONSTANT NUMBER(10) := 3;
SHEET_VALUE_MODIFIED		CONSTANT NUMBER(10) := 4;
SHEET_VALUE_PROPAGATED		CONSTANT NUMBER(10) := 5;
CHANGE_TYPE_VALUE			CONSTANT	NUMBER(10) := 1;
CHANGE_TYPE_FLAG			CONSTANT	NUMBER(10) := 2;
CHANGE_TYPE_FILE			CONSTANT	NUMBER(10) := 3;
CHANGE_TYPE_NOTE			CONSTANT	NUMBER(10) := 4;
CHANGE_TYPE_ENTERED_VALUE	CONSTANT	NUMBER(10) := 5;
-- don't forget to add these values to Credit360.Issues.IssueType as well
ISSUE_DATA_ENTRY			CONSTANT	NUMBER(10) := 1;
ISSUE_QUESTIONNAIRE			CONSTANT	NUMBER(10) := 2;
ISSUE_CORRECTIVE_ACTION		CONSTANT	NUMBER(10) := 3;
ISSUE_SCHEDULED_TASK		CONSTANT	NUMBER(10) := 4;
ISSUE_CMS					CONSTANT	NUMBER(10) := 5;
ISSUE_METER_MONITOR			CONSTANT	NUMBER(10) := 6;
ISSUE_METER_ALARM			CONSTANT	NUMBER(10) := 7;
ISSUE_METER_RAW_DATA		CONSTANT	NUMBER(10) := 8;
ISSUE_ENQUIRY				CONSTANT	NUMBER(10) := 9;
ISSUE_BASIC					CONSTANT	NUMBER(10) := 10;
ISSUE_NON_COMPLIANCE		CONSTANT	NUMBER(10) := 11;
ISSUE_METER_DATA_SOURCE		CONSTANT	NUMBER(10) := 12;
IAT_OPENED						CONSTANT	NUMBER(10) := 0;
IAT_ASSIGNED					CONSTANT	NUMBER(10) := 1;
IAT_EMAILED_CORRESPONDENT		CONSTANT	NUMBER(10) := 2;
IAT_RESOLVED					CONSTANT	NUMBER(10) := 3;
IAT_CLOSED						CONSTANT	NUMBER(10) := 4;
IAT_REOPENED					CONSTANT	NUMBER(10) := 5;
IAT_DUE_DATE_CHANGED			CONSTANT	NUMBER(10) := 6;
IAT_EMAILED_USER				CONSTANT	NUMBER(10) := 7;
IAT_PRIORITY_CHANGED			CONSTANT	NUMBER(10) := 8;
IAT_REJECTED					CONSTANT	NUMBER(10) := 9;
IAT_LABEL_CHANGED				CONSTANT	NUMBER(10) := 10;
IAT_EMAILED_ROLE				CONSTANT	NUMBER(10) := 11;
IAT_EMAIL_RECEIVED				CONSTANT	NUMBER(10) := 12;

ALERT_NEW_USER					CONSTANT	NUMBER(10) := 1;
ALERT_NEW_DELEGATION			CONSTANT	NUMBER(10) := 2;
ALERT_OVERDUE_SHEET				CONSTANT	NUMBER(10) := 3; 
ALERT_SHEET_CHANGED				CONSTANT	NUMBER(10) := 4; 
ALERT_REMINDER_SHEET			CONSTANT	NUMBER(10) := 5; 
ALERT_DELEG_TERMINATED			CONSTANT	NUMBER(10) := 7; 
ALERT_NEW_ROOT_APS				CONSTANT	NUMBER(10) := 9;
ALERT_SUBMIT					CONSTANT	NUMBER(10) := 10;
ALERT_REJECT					CONSTANT	NUMBER(10) := 11;
ALERT_SUB_DELEGATION			CONSTANT	NUMBER(10) := 12;
ALERT_SUBMIT_TO_ROOT			CONSTANT	NUMBER(10) := 13;
ALERT_REJECT_FROM_ROOT			CONSTANT	NUMBER(10) := 14;
ALERT_NEW_SUBMISSION			CONSTANT	NUMBER(10) := 15;
ALERT_FINAL_APPROVAL			CONSTANT	NUMBER(10) := 16;
ALERT_ISSUE_COMMENT				CONSTANT	NUMBER(10) := 17;
ALERT_ISSUE_SUMMARY				CONSTANT	NUMBER(10) := 18;
ALERT_DOCLIB_CHANGE				CONSTANT	NUMBER(10) := 19;
ALERT_GENERIC_MAILOUT			CONSTANT	NUMBER(10) := 20;
ALERT_SELFREG_VALIDATE			CONSTANT	NUMBER(10) := 21;
ALERT_SELFREG_NOTIFY			CONSTANT	NUMBER(10) := 22;
ALERT_SELFREG_APPROVAL			CONSTANT	NUMBER(10) := 23;
ALERT_SELFREG_REJECT			CONSTANT	NUMBER(10) := 24;
ALERT_PASSWORD_RESET			CONSTANT	NUMBER(10) := 25;
ALERT_ACCOUNT_DISABLED			CONSTANT	NUMBER(10) := 26;           
ALERT_REMINDER_PENDING			CONSTANT	NUMBER(10) := 27;
ALERT_OVERDUE_PENDING			CONSTANT	NUMBER(10) := 28;
ALERT_SHEET_CHANGE_REQ			CONSTANT	NUMBER(10) := 29;
ALERT_SHEET_CHANGE_BATCHED		CONSTANT	NUMBER(10) := 30;
ALERT_SURVEY					CONSTANT	NUMBER(10) := 31;
ALERT_ISSUE_SUB_CONFIRM			CONSTANT	NUMBER(10) := 32;
ALERT_ISSUE_RESOLVED			CONSTANT	NUMBER(10) := 33;
ALERT_ISSUE_MESSAGE				CONSTANT	NUMBER(10) := 34;
ALERT_ISSUE_REJECT				CONSTANT	NUMBER(10) := 35;
ALERT_ISSUE_PRIORITY_SET		CONSTANT	NUMBER(10) := 36;
ALERT_DELEG_GENERIC_MAILOUT		CONSTANT	NUMBER(10) := 37;
ALERT_USER_COVER_STARTED		CONSTANT	NUMBER(10) := 38; 
ALERT_SUBMITTED_VAL_CHANGED		CONSTANT	NUMBER(10) := 39;
     
ALERT_TO_DELEGEE 		CONSTANT	NUMBER(10) := 1;
ALERT_TO_DELEGATOR 		CONSTANT	NUMBER(10) := 2;
ALERT_TO_ALL 			CONSTANT	NUMBER(10) := 3;
NOT_FULLY_DELEGATED		CONSTANT	NUMBER(10) := 0;
FULLY_DELEGATED_TO_ONE	CONSTANT	NUMBER(10) := 1;
FULLY_DELEGATED_TO_MANY	CONSTANT	NUMBER(10) := 2;
REGION_TYPE_NORMAL			CONSTANT NUMBER(2) := 0;
REGION_TYPE_METER			CONSTANT NUMBER(2) := 1;
REGION_TYPE_ROOT			CONSTANT NUMBER(2) := 2;
REGION_TYPE_PROPERTY		CONSTANT NUMBER(2) := 3;
REGION_TYPE_TENANT			CONSTANT NUMBER(2) := 4;
REGION_TYPE_RATE			CONSTANT NUMBER(2) := 5;
REGION_TYPE_AGENT			CONSTANT NUMBER(2) := 6;
REGION_TYPE_SUPPLIER		CONSTANT NUMBER(2) := 7;
REGION_TYPE_REALTIME_METER	CONSTANT NUMBER(2) := 8;
AUDIT_TYPE_LOGON			CONSTANT	NUMBER(10) := 1;
AUDIT_TYPE_LOGOFF			CONSTANT	NUMBER(10) := 2;
AUDIT_TYPE_LOGON_SU			CONSTANT	NUMBER(10) := 3;
AUDIT_TYPE_CHANGE_SCHEMA	CONSTANT	NUMBER(10) := 4; -- add to MEASURE, ALERT
AUDIT_TYPE_USER_ACCOUNT		CONSTANT	NUMBER(10) := 5; 
AUDIT_TYPE_CHANGE_VALUE		CONSTANT	NUMBER(10) := 6;
AUDIT_TYPE_LOGON_FAILED		CONSTANT	NUMBER(10) := 7;
AUDIT_TYPE_IMPORT 			CONSTANT	NUMBER(10) := 8; -- upload, merge
AUDIT_TYPE_DOWNLOAD			CONSTANT	NUMBER(10) := 9; -- download data
AUDIT_TYPE_DELEGATION		CONSTANT	NUMBER(10) := 10; 
AUDIT_TYPE_TASK             CONSTANT    NUMBER(10) := 11;
AUDIT_TYPE_TASK_PERIOD      CONSTANT    NUMBER(10) := 12;
AUDIT_TYPE_ISSUES		    CONSTANT	NUMBER(10) := 13;
AUDIT_TYPE_TASK_STATUS		CONSTANT	NUMBER(10) := 14;
AUDIT_TYPE_METER_READING    CONSTANT    NUMBER(10) := 15;
AUDIT_TYPE_CLIENT_SPECIFIC  CONSTANT    NUMBER(10) := 16;
AUDIT_TYPE_SUSPICIOUS  		CONSTANT    NUMBER(10) := 17; -- large data downloads/trying to download docs where no permissions etc
-- start > SUPPLIER specific but doesn't make sense to split constant declaration
AUDIT_TYPE_PROD_CREATED						CONSTANT	NUMBER(10) := 50;
AUDIT_TYPE_PROD_UPDATED						CONSTANT	NUMBER(10) := 51;
AUDIT_TYPE_PROD_SUPP_CHANGED			CONSTANT	NUMBER(10) := 52;
AUDIT_TYPE_PROD_DA_CHANGED				CONSTANT	NUMBER(10) := 53;
AUDIT_TYPE_PROD_DP_CHANGED				CONSTANT	NUMBER(10) := 54;
AUDIT_TYPE_PROD_DP_DELETED				CONSTANT	NUMBER(10) := 55;
AUDIT_TYPE_PROD_TAG_CHANGED				CONSTANT	NUMBER(10) := 56;
AUDIT_TYPE_PROD_VOL_CHANGED				CONSTANT	NUMBER(10) := 57;
AUDIT_TYPE_SUPP_CREATED					CONSTANT	NUMBER(10) := 60;
AUDIT_TYPE_SUPP_UPDATED					CONSTANT	NUMBER(10) := 61;
AUDIT_TYPE_SUPP_USER_ASS				CONSTANT	NUMBER(10) := 62;
AUDIT_TYPE_SUPP_USER_UNASS				CONSTANT	NUMBER(10) := 63;
AUDIT_TYPE_SUPP_DELETED					CONSTANT	NUMBER(10) := 64;
AUDIT_TYPE_SUPP_TAG_CHANGED				CONSTANT	NUMBER(10) := 65;
AUDIT_TYPE_PROD_STATE_CHANGED			CONSTANT	NUMBER(10) := 70;
AUDIT_TYPE_QUEST_SAVED					CONSTANT	NUMBER(10) := 71;
AUDIT_TYPE_QUEST_STATE_CHANGED			CONSTANT	NUMBER(10) := 72;
AUDIT_TYPE_PROD_QUEST_LINKED			CONSTANT	NUMBER(10) := 73;
AUDIT_TYPE_PROD_QUEST_UNLINKED			CONSTANT	NUMBER(10) := 74;
-- end > SUPPLIER specific but doesn't make sense to split constant declaration
-- start > DONATIONS specific
AUDIT_TYPE_DONATIONS_DONATION       CONSTANT    NUMBER(10) := 80;
AUDIT_TYPE_DONATIONS_BUDGET       	CONSTANT    NUMBER(10) := 81;
AUDIT_TYPE_DONATIONS_SCHEME       	CONSTANT    NUMBER(10) := 82;
AUDIT_TYPE_DONATIONS_STATUS       	CONSTANT    NUMBER(10) := 83;
AUDIT_TYPE_DONATIONS_CATEGORY       CONSTANT    NUMBER(10) := 84;
AUDIT_TYPE_DONATIONS_RECIPIENT      CONSTANT    NUMBER(10) := 85;
-- end > DONATIONS specific
-- start > Internal Audit specific
AUDIT_TYPE_INTERNAL_AUDIT			CONSTANT	NUMBER(10) := 90;
AUDIT_TYPE_NON_COMPLIANCE			CONSTANT	NUMBER(10) := 91;
-- end > Internal Audit specific
-- start > Region role specific
AUDIT_TYPE_REGION_ROLE_CHANGED			CONSTANT	NUMBER(10) := 100;
-- end > Region role specific
-- start > Tags/categories
AUDIT_TYPE_REGION_TAG_CHANGED			CONSTANT	NUMBER(10) := 110;
AUDIT_TYPE_IND_TAG_CHANGED			CONSTANT	NUMBER(10) := 111;
-- end > Tags/categories
TEMPLATE_TYPE_DEFAULT_CHART		CONSTANT	NUMBER(10) := 1;
TEMPLATE_TYPE_DEFAULT_EXCEL		CONSTANT	NUMBER(10) := 2;
TEMPLATE_TYPE_DEFAULT_WORD		CONSTANT	NUMBER(10) := 3;
TEMPLATE_TYPE_DEFAULT_EXPLORER	CONSTANT	NUMBER(10) := 4;
TEMPLATE_TYPE_DEFAULT_APPROVAL	CONSTANT	NUMBER(10) := 5;
TOLERANCE_TYPE_NONE 						CONSTANT	NUMBER(10) := 0;
TOLERANCE_TYPE_PREVIOUS_PERIOD 				CONSTANT	NUMBER(10) := 1;
TOLERANCE_TYPE_PREVIOUS_YEAR 				CONSTANT	NUMBER(10) := 2;
-- pending form elements
ELEMENT_TYPE_TEXT_ENTRY 	CONSTANT 	NUMBER(10) := 1;
ELEMENT_TYPE_TEXT_BLOCK 	CONSTANT 	NUMBER(10) := 2;
ELEMENT_TYPE_SECTION 		CONSTANT 	NUMBER(10) := 3;
ELEMENT_TYPE_NUMERIC 		CONSTANT 	NUMBER(10) := 4;
ELEMENT_TYPE_TABLE 			CONSTANT 	NUMBER(10) := 5;
ELEMENT_TYPE_CHECKBOX 		CONSTANT 	NUMBER(10) := 6;
ELEMENT_TYPE_RADIO 			CONSTANT 	NUMBER(10) := 7;
ELEMENT_TYPE_DROPDOWN 		CONSTANT 	NUMBER(10) := 8;
ELEMENT_TYPE_HIDDEN 		CONSTANT 	NUMBER(10) := 9;
ELEMENT_TYPE_GRID 			CONSTANT 	NUMBER(10) := 11;
ELEMENT_TYPE_DATE 			CONSTANT 	NUMBER(10) := 12;
ELEMENT_TYPE_FORM 			CONSTANT 	NUMBER(10) := 13;
ELEMENT_TYPE_FILE_UPLOAD 	CONSTANT 	NUMBER(10) := 14;
-- audit type group 
ATG_SECURABLE_OBJECT 		CONSTANT NUMBER(10) := 1;
ATG_SUPPLIER_PRODUCT 		CONSTANT NUMBER(10) := 2;
ATG_SUPPLIER_QUESTIONNAIRE	CONSTANT NUMBER(10) := 3;	
-- document status
DOCLIB_IN_DATE				CONSTANT NUMBER(10) := 0;
DOCLIB_NEARLY_EXPIRED 		CONSTANT NUMBER(10) := 1;	
DOCLIB_EXPIRED				CONSTANT NUMBER(10) := 2;
-- location_type
LOC_TYPE_AIRPORT			CONSTANT NUMBER(10) := 1;
LOC_TYPE_COUNTRY			CONSTANT NUMBER(10) := 2;
LOC_TYPE_PORT				CONSTANT NUMBER(10) := 3;
LOC_TYPE_ROAD				CONSTANT NUMBER(10) := 4;
LOC_TYPE_BARGE_PORT			CONSTANT NUMBER(10) := 5;
LOC_TYPE_RAIL_STATION		CONSTANT NUMBER(10) := 6;
-- logistics_mode (defaults)
TRANSPORT_MODE_AIR			CONSTANT NUMBER(10) := 1;
TRANSPORT_MODE_SEA			CONSTANT NUMBER(10) := 2;
TRANSPORT_MODE_ROAD			CONSTANT NUMBER(10) := 3;
TRANSPORT_MODE_BARGE		CONSTANT NUMBER(10) := 4;
TRANSPORT_MODE_RAIL			CONSTANT NUMBER(10) := 5;

/*
AUDIT_TYPE_IMPORT			CONSTANT	NUMBER(10) := 6;
AUDIT_TYPE_CHANGE_VALUE		CONSTANT	NUMBER(10) := 6;
AUDIT_TYPE_CHANGE_VALUE		CONSTANT	NUMBER(10) := 6;
AUDIT_TYPE_CHANGE_VALUE		CONSTANT	NUMBER(10) := 6;
*/
-- include stuff like imports, merge data etc
SHT_BLOCKED_MISSING_VALUE	CONSTANT NUMBER(10) := 1; -- 'This value must be entered before you can submit' 
SHT_BLOCKED_MISSING_NOTE	CONSTANT NUMBER(10) := 2; -- 'An explanatory note must be provided for this value'
SHT_BLOCKED_MISSING_QUAL	CONSTANT NUMBER(10) := 3; -- 'A quality status must be selected for this value'
SHT_BLOCKED_MISS_QUAL_NOTE	CONSTANT NUMBER(10) := 4; -- 'A note must be entered for the selected quality status'
SHT_BLOCKED_TOLERANCE 		CONSTANT NUMBER(10) := 5; -- 'An explanatory note must be provided because the number differs significantly from a previous figure'
-- lock types
LOCK_TYPE_CALC				CONSTANT NUMBER(10) := 1;
LOCK_TYPE_SHEET_CALC		CONSTANT NUMBER(10) := 2;

-- deleg_plan pending_deletion status
DELEG_PLAN_NO_DELETE		CONSTANT NUMBER(10) := 0;  -- don't delete
DELEG_PLAN_DELETE_ALL		CONSTANT NUMBER(10) := 1;  -- delete delegations and also from DELEG_PLAN_DELEG_REGION 
DELEG_PLAN_DELETE_CREATE	CONSTANT NUMBER(10) := 2;  -- delete delegations but keep in DELEG_PLAN_DELEG_REGION and re-create

DELEG_PLAN_SEL_REGION			CONSTANT VARCHAR2(2) := 'R';    -- select the specified region
DELEG_PLAN_SEL_LEAF				CONSTANT VARCHAR2(2) := 'L';    -- select leaf nodes
DELEG_PLAN_SEL_PROPERTIES		CONSTANT VARCHAR2(2) := 'P';    -- select property nodes
DELEG_PLAN_SEL_REGION_TAG		CONSTANT VARCHAR2(2) := 'RT';   -- select the specified region
DELEG_PLAN_SEL_LEAF_TAG			CONSTANT VARCHAR2(2) := 'LT';   -- select leaf nodes
DELEG_PLAN_SEL_PROPERTIES_TAG	CONSTANT VARCHAR2(2) := 'PT';   -- select property nodes

-- class extension methods 
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/** * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);
/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE CreateCSRObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_start_month			IN	NUMBER,
	out_csr_sid				OUT	security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE LockPeriod(
	in_act_id			security_pkg.T_ACT_ID,
	in_app_sid		security_pkg.T_SID_ID,
	in_start_dtm		customer.lock_start_dtm%TYPE,
	in_end_dtm			customer.lock_end_dtm%TYPE
);

PROCEDURE RemovePeriodLock(
	in_act_id			security_pkg.T_ACT_ID,
	in_app_sid		security_pkg.T_SID_ID
);

FUNCTION IsPeriodLocked(
	in_app_sid		security_pkg.T_SID_ID,
	in_start_dtm		customer.lock_start_dtm%TYPE,
	in_end_dtm			customer.lock_end_dtm%TYPE
) RETURN NUMBER;

/**
 * AddToAuditDescription
 * 
 * @param in_field_name		.
 * @param in_old_value		.
 * @param in_new_value		.
 * @return 					.
 */
FUNCTION AddToAuditDescription(
	in_field_name	IN	VARCHAR2,
	in_old_value	IN	VARCHAR2,
	in_new_value	IN	VARCHAR2
) RETURN VARCHAR2;

PROCEDURE WriteAppAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		    IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntry_AT(
	in_act_id			IN	security_pkg.T_ACT_ID	DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntryAndSubObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN  audit_log.sub_object_id%TYPE DEFAULT NULL,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL
);

PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id			IN	security_pkg.T_SID_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditClobChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	CLOB,
	in_new_value		IN	CLOB,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditValueChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditValueDescChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_old_desc			IN	VARCHAR2,
	in_new_desc			IN	VARCHAR2,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE AuditInfoXmlChanges(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_info_xml_fields	IN	XMLType,
	in_old_info_xml		IN	XMLType,
	in_new_info_xml		IN	XMLType,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
);

PROCEDURE GetAuditLogForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForObjectType(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_audit_type_id    IN  audit_log.audit_type_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForObjectType(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE,
	in_audit_type_id    IN  audit_log.audit_type_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAuditLogForObjectTypeClass(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_object_sid				IN	security_pkg.T_SID_ID,
	in_sub_object_id			IN	audit_log.sub_object_id%TYPE,
	in_audit_type_group_id   	IN  audit_type.audit_type_group_id%TYPE,
	in_order_by					IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConfiguration(
	out_cur						OUT	SYS_REFCURSOR
);

PROCEDURE SetConfiguration(
	in_alert_mail_address			IN	customer.alert_mail_address%TYPE,
	in_alert_mail_name				IN	customer.alert_mail_name%TYPE,
	in_alert_batch_run_time			IN	customer.alert_batch_run_time%TYPE,
	in_raise_reminders				IN	customer.raise_reminders%TYPE,
	in_raise_split_deleg_alerts		IN	customer.raise_split_deleg_alerts%TYPE,
	in_cascade_reject       		IN	customer.cascade_reject%TYPE,
	in_approver_response_window		IN	customer.approver_response_Window%TYPE,
	in_self_reg_group_sid			IN	customer.self_reg_group_sid%TYPE,
	in_self_reg_needs_approval		IN	customer.self_reg_needs_approval%TYPE,
	in_self_reg_approver_sid		IN	customer.self_reg_approver_sid%TYPE,
    in_lock_end_dtm             	IN  customer.lock_end_dtm%TYPE,
    in_allow_partial_submit			IN	customer.allow_partial_submit%TYPE,
    in_create_sheets_period_end		IN	customer.create_sheets_at_period_end%TYPE
);

/**
 * Checks the capability is valid and creates a secobj of the right class in the right place.
 * 
 * @param in_capability					The name of capability to create
 * @param in_swallow_dup_exception		Optionally swallows the security_pkg.DUPLICATE_OBJECT_NAME exception
 */
PROCEDURE EnableCapability(
	in_capability  				IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    IN  NUMBER DEFAULT 0
);

/**
 * Check if app have Capabilities specified, and if user has certain capability.
 * 
 * @param in_capability		The name of capability to check against.
 */
FUNCTION CheckCapability(
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(CheckCapability, WNDS, WNPS);

FUNCTION SQL_CheckCapability(
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER;
PRAGMA RESTRICT_REFERENCES(SQL_CheckCapability, WNDS, WNPS);

FUNCTION SQL_CheckCapability(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER;
PRAGMA RESTRICT_REFERENCES(SQL_CheckCapability, WNDS, WNPS);

/**
 * Check if app have Capabilities specified, and if user has certain capability
 * 
 * @param in_act_id				The access token.
 * @param in_capability		The name of capability to check against.
 */
FUNCTION CheckCapability(
	in_act_id      				IN 	security_pkg.T_ACT_ID,
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(CheckCapability, WNDS, WNPS);

/**
 * Return all user groups for the current application
 *
 * @param out_cur				Output rowset of the form sid_id, name
 */
PROCEDURE GetAppGroups(
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Return all user groups for the current application, including those backing roles
 *
 * @param out_cur				Output rowset of the form sid_id, name
 */
PROCEDURE GetAppGroupsAndRoles(
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Add a translation for the given application
 *
 * @param in_application_sid	The application to add the translation for
 * @param in_lang_id			The lang id of the language to add a translation for
 */
PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
);

/**
 * Get a per application lock
 *
 * @param in_lock_type			The type of lock to take
 */
PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE
);

/**
 * Check if the current application has an unmerged scenario enabled
 */
FUNCTION HasUnmergedScenario
RETURN BOOLEAN;
PRAGMA RESTRICT_REFERENCES(HasUnmergedScenario, WNDS, WNPS);

END Csr_Data_Pkg;
/
CREATE OR REPLACE PACKAGE BODY CSR.Csr_Data_Pkg AS
-- errors
-- indicator permission
-- csr user and csr group permissions
-- trash can permissions
-- delegation permissions
-- class extension methods 

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
) AS
BEGIN
	-- call CreateCSRObject instead
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

/*
Generates delete statements -- circular RI still needs to be handled manually

select 'DELETE'||chr(10)||
       '  FROM '||lower(decode(x.child_owner, 'CSR', '', x.child_owner||'.')||x.child_table_name)||chr(10)||
       ' WHERE app_sid = in_app_sid;'
  from (
    select min(level) lvl, child_owner, child_table_name
      from (select p.owner parent_owner, p.table_name parent_table_name, c.owner child_owner, c.table_name child_table_name
              from all_constraints p, all_constraints c
             where c.constraint_type = 'R' and p.constraint_type in ('U', 'P') and 
                   p.owner = c.r_owner and p.constraint_name = c.r_constraint_name) pc
            start with pc.parent_owner = 'CSR' and pc.parent_table_name = 'CUSTOMER'
            connect by nocycle prior pc.child_owner = pc.parent_owner and prior pc.child_table_name = pc.parent_table_name
    group by child_owner, child_table_name) x, all_tab_columns atc
 where atc.owner = x.child_owner and atc.table_name = x.child_table_name and atc.column_name = 'APP_SID'
order by x.lvl desc, x.child_owner, x.child_table_name;
*/
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_system_mail_address	VARCHAR2(1000);
	v_tracker_mail_address	VARCHAR2(1000);	
BEGIN
	v_app_sid := securableobject_pkg.GetParent(in_act_id, in_sid_id);
	If v_app_sid <> SYS_CONTEXT('SECURITY', 'APP') THEN
		RAISE_APPLICATION_ERROR(-20001, 'The current application in SYS_CONTEXT is not set to the application being deleted');
	END IF;

	-- clean up mail accounts associated with the site
	SELECT system_mail_address, tracker_mail_address
	  INTO v_system_mail_address, v_tracker_mail_address
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	mail.mail_pkg.deleteAccount(v_system_mail_address);
	mail.mail_pkg.deleteAccount(v_tracker_mail_address);
	
	-- general clean up of irritating constraints	 
	UPDATE csr_user 
	   SET region_mount_point_sid = null
	 WHERE app_sid = v_app_sid;
	
	UPDATE region 
	   SET link_to_region_sid = null
	 WHERE app_sid = v_app_sid;

	UPDATE customer
	   SET region_root_sid = null, ind_root_sid = null
	 WHERE app_sid = v_app_sid;


	DELETE FROM model_instance_chart
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model_instance_map
	 WHERE app_sid = v_app_sid;

	DELETE FROM model_instance_region
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model_instance_sheet
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model_instance
	 WHERE app_sid = v_app_sid;

	DELETE FROM model_validation
	 WHERE app_sid = v_app_sid;

	DELETE FROM model_map
	 WHERE app_sid = v_app_sid;

	DELETE FROM model_range_cell
	 WHERE app_sid = v_app_sid;

	DELETE FROM model_region_range
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model_range
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model_sheet
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM model
	 WHERE app_sid = v_app_sid;

	DELETE FROM tpl_report_tag_ind
	 WHERE app_sid = v_app_sid;

	DELETE FROM tpl_report_tag_dv_region	
	 WHERE app_sid = v_app_sid;

	DELETE FROM tpl_report_tag_dataview
	 WHERE app_sid = v_app_sid;	
	
	DELETE FROM tpl_report_tag
	 WHERE app_sid = v_app_sid;

	DELETE FROM actions.task_period_override
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.budget_constant
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.aggr_task_period_override
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.aggr_task_task_dependency
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.initiative_extra_info
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.initiative_project_team
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_role_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_role_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_budget_history
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_budget_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_comment
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_instance
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_recalc_job
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM actions.task_task_dependency
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM map_shpfile
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM customer_map 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM job
	 WHERE app_sid = v_app_sid;

	DELETE FROM attachment_history
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_download
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_notification
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_subscription
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM factor_history
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM form_allocation_item
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM form_allocation_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM imp_conflict_val
	 WHERE app_sid = v_app_sid;

	DELETE FROM postit
	 WHERE app_sid = v_app_sid;
	 
    DELETE
      FROM issue_scheduled_task
     WHERE app_sid = v_app_sid;

	UPDATE issue
	   SET issue_pending_val_id = null,
	   	   issue_sheet_value_id = null,
		   issue_survey_answer_id = null,
		   issue_non_compliance_id = null
     WHERE app_sid = v_app_sid;

	DELETE FROM issue_pending_val
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue_non_compliance
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM issue_survey_answer
	 WHERE app_sid = v_app_sid;

	DELETE FROM issue_sheet_value
	 WHERE app_sid = v_app_sid;

	DELETE FROM issue_action_log
	 WHERE app_sid = v_app_sid;

	DELETE FROM measure_conversion_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM utility_invoice
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM meter_utility_contract
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM utility_contract
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM utility_supplier
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM meter_reading
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM all_meter
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM meter_source_type
	 WHERE app_sid = v_app_sid;

	DELETE FROM qs_answer_file
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM qs_answer_log
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM quick_survey_answer
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM quick_survey_response
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM quick_survey_question
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM quick_survey
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM root_section_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM section_approvers
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM section_comment
	 WHERE app_sid = v_app_sid;
	
	UPDATE section
	   SET visible_version_number = NULL, checked_out_version_number = null
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM section_version
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM sheet_inherited_value
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM sheet_value_accuracy
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM survey_allocation
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tab_portlet_rss_feed
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM val_accuracy
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM scenario_options
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.custom_field
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.budget
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.letter_body_region_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.region_group_recipient
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.aggr_task_ind_dependency
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.aggr_task_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_status_role
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM actions.allow_transition
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_status_transition
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.root_ind_template_instance
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_ind_template_instance
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_ind_template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_ind_template_instance
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.ind_template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.ind_template_group 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_role
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_tag_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.tag_group_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.project_task_period_status
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_period_status
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_file_upload
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_indicator
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_ind_dependency
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_period_file_upload
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_status_history
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.periodic_report_template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM selected_axis_task
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM related_axis_member 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM axis_member
	 WHERE app_sid = v_app_sid;

	UPDATE axis 
	   SET left_side_axis_id = null,
			right_side_axis_id = null
	WHERE app_sid = v_app_sid;
	   
	DELETE FROM related_axis
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM axis
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task
	 WHERE app_sid = v_app_sid;

	DELETE FROM alert_template_body
	 WHERE app_sid = v_app_sid;
	 	 
	DELETE FROM alert_template
	 WHERE app_sid = v_app_sid;

	DELETE FROM alert_frame_body
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM alert_frame
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM all_meter
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM attachment
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM calc_dependency
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM dashboard_item
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM img_chart_ind
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM img_chart
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM dataview_zone
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM delegation_ind_cond_action 
	 WHERE app_sid = v_app_sid;

	DELETE FROM delegation_ind_cond 
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM delegation_ind_tag 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_ind_tag_list 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_ind
	 WHERE app_sid = v_app_sid;

	DELETE FROM delegation_grid_aggregate_ind 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_grid
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM diary_event_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_current
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_version
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM factor
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM feed_request
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM form_comment
	 WHERE app_sid = v_app_sid;

	DELETE FROM form_allocation
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM imp_conflict
	 WHERE app_sid = v_app_sid;

	DELETE FROM imp_val
	 WHERE app_sid = v_app_sid;
				
	DELETE FROM imp_measure
	 WHERE app_sid = v_app_sid;

	DELETE FROM imp_ind
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM imp_region
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM ind_accuracy_type
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM ind_start_point
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM ind_tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM ind_window
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM instance_dataview
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM objective_status
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pct_ownership
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pvc_stored_calc_job
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pvc_region_recalc_job
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_val_file_upload
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM pending_ind_accuracy_type
	 WHERE app_sid = v_app_sid;

	DELETE FROM pending_val_accuracy_type_opt
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_val_log
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_val_variance
	 WHERE app_sid = v_app_sid;	
	
	DELETE FROM pending_val
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_val_cache
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM approval_step_ind
	 WHERE app_sid = v_app_sid;

	DELETE FROM pending_ind
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_ind_rule
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step_sheet_log
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step_sheet_alert
	 WHERE app_sid = v_app_sid;

	DELETE FROM approval_step_sheet
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_region
	 WHERE app_sid = v_app_sid;

	DELETE FROM approval_step_role
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM approval_step_template
	 WHERE app_sid = v_app_sid;	
	
	DELETE FROM approval_step_user_template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step_role
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM approval_step
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM dataview_ind_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM dataview_region_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM range_ind_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM range_region_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM region_owner
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM region_role_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM region_tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM rss_feed_item
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM section
	 WHERE app_sid = v_app_sid;
	
	UPDATE sheet_value
	   SET last_sheet_value_change_Id = null
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM sheet_value_change_file
	 WHERE app_sid = v_app_sid;

	DELETE FROM sheet_value_change
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM sheet_value_file
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM sheet_value
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM sheet_alert
	 WHERE app_sid = v_app_sid;
	 
	UPDATE sheet
	   SET LAST_SHEET_HISTORY_ID = null
	 WHERE app_sid = v_app_sid;  	
	
	DELETE FROM sheet_history
	 WHERE app_sid = v_app_sid;

	DELETE FROM sheet
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM deleg_plan_role
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM deleg_plan_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM deleg_plan_deleg_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM deleg_plan_col_deleg
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM deleg_plan_survey_region
	 WHERE app_sid = v_app_sid;

	DELETE FROM deleg_plan_col_survey
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM deleg_plan
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM master_deleg
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM deleted_delegation
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM snapshot_ind
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM app_lock
	 WHERE app_sid = v_app_sid;

	DELETE FROM stored_calc_job
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM survey_response
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tab_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tab_portlet
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tab_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tag_group_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM target_dashboard_ind_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM target_dashboard_value
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM unapproved_val
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM val_file
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM val_note
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM val
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM val_change
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM measure_conversion
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM donations.donation
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.donation_doc
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.donation_tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.letter_body_text
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.recipient_tag
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM donations.region_group_member
	 WHERE app_sid = v_app_sid;

	DELETE FROM donations.region_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.scheme_tag_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.tag_group_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.transition
	 WHERE app_sid = v_app_sid;
/*
	DELETE FROM supplier.all_product
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM supplier.contact_shortlist
	 WHERE app_sid = v_app_sid;
	
*/
	DELETE FROM actions.customer_options
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.file_upload
	 WHERE app_sid = v_app_sid;

	DELETE FROM actions.project_task_status
	 WHERE app_sid = v_app_sid;	
	
	DELETE FROM actions.project
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.role
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.script
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.tag_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM actions.task_status
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM delegation_terminated_alert
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM new_delegation_alert
	 WHERE app_sid = v_app_sid;

	DELETE FROM delegation_change_alert	
	 WHERE app_sid = v_app_sid;

	DELETE FROM user_message_alert
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM autocreate_user
	 WHERE app_sid = v_app_sid;

	DELETE FROM alert_batch_run
	 WHERE app_sid = v_app_sid;
	 	
	DELETE FROM cms_tab_alert_type
	 WHERE app_sid = v_app_sid;

	DELETE FROM flow_alert_type
	 WHERE app_sid = v_app_sid;
 	
	DELETE FROM customer_alert_type_param
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM customer_alert_type
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM customer_help_lang
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM customer_portlet
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM dashboard
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM excel_export_options
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM dataview
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM default_rss_feed
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM diary_event
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_data
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM doc_library
	 WHERE app_sid = v_app_sid;
	
/*
TODO: 

ORA-02292: integrity constraint (CSR.FK_DOC_FOLD_DOC_FOLD_SUB) violated - child record found
ORA-06512: at "CSR.CSR_DATA_PKG", line 752
ORA-06512: at line 1
ORA-06512: at "SECURITY.SECURABLEOBJECT_PKG", line 202
ORA-06512: at line 26
*/
	DELETE FROM doc_folder
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM feed
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM file_upload
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM form
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM imp_session
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM ind_flag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM scenario_ind
	 WHERE app_sid = v_app_sid;
	 	
	DELETE FROM ind
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue_log_read
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue_log
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue_user
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM issue_type
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM measure
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM objective
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM option_item
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pct_ownership_change
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM pending_dataset
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM scenario_region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM supplier
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM region
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM customer_region_type
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM region_tree
	 WHERE app_sid = v_app_sid;
	
	UPDATE customer
	   SET current_reporting_period_sid = NULL
	 WHERE app_sid = v_app_sid;

	DELETE FROM reporting_period
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM role
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM rss_feed
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM section_module
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM section_transition
	 WHERE app_sid = v_app_sid;

	DELETE FROM section_status
	 WHERE app_sid = v_app_sid;
		
	DELETE FROM session_extra
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM snapshot
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM survey
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tab
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tag_group
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM target_dashboard
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM tpl_report
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM trash
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM validation_rule
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.customer_filter_flag
	 WHERE app_sid = v_app_sid;

	DELETE FROM donations.scheme_donation_status
	 WHERE app_sid = v_app_sid;

	DELETE FROM donations.donation_status
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.filter
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.letter_template
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.tag
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM donations.tag_group
	 WHERE app_sid = v_app_sid;
/*	
	DELETE FROM supplier.alert_batch
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM supplier.all_company
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM supplier.customer_period
	 WHERE app_sid = v_app_sid;
*/
	DELETE FROM audit_log
	 WHERE app_sid = v_app_sid;

	chain.chain_pkg.DeleteChainData(v_app_sid);
	 
	DELETE FROM csr_user
	 WHERE app_sid = v_app_sid;

/*
	
	DELETE FROM cms.app_schema
	 WHERE app_sid = v_app_sid;

	DELETE FROM cms.app_schema_table
	 WHERE app_sid = v_app_sid;
*/

	DELETE FROM csr.accuracy_type_option
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM csr.accuracy_type
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM logistics_error_log
	 WHERE app_sid = v_app_sid;

	DELETE FROM logistics_tab_mode
	 WHERE app_sid = v_app_sid;

	DELETE FROM custom_location
	 WHERE app_sid = v_app_sid;

	DELETE FROM custom_distance
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM logistics_default
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM cms.image 
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM scrag_progress
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM aggregate_ind_calc_job
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM aggregate_ind_group_member
	 WHERE app_sid = v_app_sid;
	
	DELETE FROM aggregate_ind_group
	 WHERE app_sid = v_app_sid;
	 
	DELETE FROM customer
	 WHERE app_sid = v_app_sid;

	-- Now we've killed all the data, make all the CSR objects simple containers
	-- This a) speeds up deletion by not having to invoke loads of PL/SQL code
	-- and  b) stops the PL/SQL code from breaking when it finds the child rows are missing
	UPDATE security.securable_object
	   SET class_id = security_pkg.SO_CONTAINER
	 WHERE sid_id IN (SELECT sid_id
	 					FROM security.securable_object
	 					 	 START WITH sid_id = v_app_sid
	 					 	 CONNECT BY PRIOR sid_id = parent_sid_id);
END;

PROCEDURE AddStandardFramesAndTemplates
AS
BEGIN
	-- get languages that are configured for the site		  
	INSERT INTO temp_lang (lang)
		SELECT lang
		  FROM aspen2.translation_set
		 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND hidden = 0;

	-- add in the default frames
	INSERT INTO temp_alert_frame (default_alert_frame_id, alert_frame_id)
		SELECT daf.default_alert_frame_id, alert_frame_id_seq.NEXTVAL
		  FROM default_alert_frame daf, (
		  		SELECT DISTINCT default_alert_frame_id
		  		  FROM default_alert_frame_body
		  		 WHERE lang IN (SELECT lang FROM temp_lang)) dafb
		 WHERE daf.default_alert_frame_id = dafb.default_alert_frame_id;

	INSERT INTO alert_frame (alert_frame_id, name)
		SELECT taf.alert_frame_id, daf.name
		  FROM default_alert_frame daf, temp_alert_frame taf
		 WHERE daf.default_alert_frame_id = taf.default_alert_frame_id;

	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT taf.alert_frame_id, dafb.lang, dafb.html
		  FROM default_alert_frame_body dafb, temp_alert_frame taf
		 WHERE dafb.default_alert_frame_id = taf.default_alert_frame_id 
		   AND dafb.lang IN (SELECT lang FROM temp_lang);

	-- and the default templates
	INSERT INTO alert_template (customer_alert_type_id, alert_frame_id, send_type)
		SELECT cat.customer_alert_type_id, taf.alert_frame_id, 'manual' send_type
		  FROM default_alert_template dat, customer_alert_type cat, temp_alert_frame taf
		 WHERE cat.std_alert_type_id = dat.std_alert_type_id AND dat.default_alert_frame_id = taf.default_alert_frame_id;

	INSERT INTO alert_template_body (customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb, customer_alert_type cat
		 WHERE cat.std_alert_type_id = datb.std_alert_type_id 
		   AND datb.lang IN (SELECT lang FROM temp_lang);
END;

PROCEDURE CreateCSRObject(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_parent_sid_id		IN	security_pkg.T_SID_ID,
	in_start_month			IN	NUMBER,
	out_csr_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_host						VARCHAR2(255);
	-- sids we create
	v_region_root_sid_id		security_pkg.T_SID_ID;
	v_ind_root_sid_id			security_pkg.T_SID_ID;
	v_new_sid_id				security_pkg.T_SID_ID;
	v_pending_sid_id			security_pkg.T_SID_ID;
	v_trash_sid_id				security_pkg.T_SID_ID;
	v_policy_sid				security_pkg.T_SID_ID;
	-- groups
	v_admins					security_pkg.T_SID_ID;
	v_reg_users					security_pkg.T_SID_ID;
	v_super_admins				security_pkg.T_SID_ID;
	v_groups					security_pkg.T_SID_ID;
	v_auditors					security_pkg.T_SID_ID;
	v_data_providers			security_pkg.T_SID_ID;
	v_data_approvers			security_pkg.T_SID_ID;
	v_reporters					security_pkg.T_SID_ID;
	-- mail
	v_email						customer.system_mail_address%TYPE;
	v_tracker_email				customer.tracker_mail_address%TYPE;
	v_root_mailbox_sid			security_pkg.T_SID_ID;
	v_account_sid				security_pkg.T_SID_ID;
	v_outbox_mailbox_sid		security_pkg.T_SID_ID;
	v_sent_mailbox_sid			security_pkg.T_SID_ID;
	v_users_mailbox_sid			security_pkg.T_SID_ID;
	v_user_mailbox_sid			security_pkg.T_SID_ID;
	v_tracker_root_mailbox_sid	security_pkg.T_SID_ID;
	v_tracker_account_sid		security_pkg.T_SID_ID;
	-- reporting periods
	v_period_start_dtm			DATE;
	v_period_sid				security_pkg.T_SID_ID;
	-- user creator
	v_user_creator_daemon_sid   security_pkg.T_SID_ID;
	-- section stuff
	v_status_sid                security_pkg.T_SID_ID;
    v_text_sid                  security_pkg.T_SID_ID;
    v_text_statuses_sid         security_pkg.T_SID_ID;
    v_text_transitions_sid      security_pkg.T_SID_ID;
    v_deleg_plans_sid			security_pkg.T_SID_ID;
	-- en
 	v_lang_id					aspen2.lang.lang_id%TYPE;
 	-- misc
 	v_sid						security_pkg.T_SID_ID;					
BEGIN
	-- get our host name (the name of the app)
	v_host := securableobject_pkg.getName(in_act_id, in_parent_sid_id);

	/*** GROUPS ***/
	v_groups := securableobject_pkg.GetSIDFromPath(in_act_id, in_parent_sid_id, 'Groups');
	v_admins := securableobject_pkg.GetSIDFromPath(in_act_id, v_groups, 'Administrators');
	v_reg_users := securableobject_pkg.GetSIDFromPath(in_act_id, v_groups, 'RegisteredUsers');
	
	-- make superadmins members of both RegisteredUsers and Administrators
	v_super_admins := securableobject_pkg.GetSIDFromPath(in_act_id, 0, 'csr/SuperAdmins');
	group_pkg.AddMember(in_act_id, v_super_admins, v_admins);
	group_pkg.AddMember(in_act_id, v_super_admins, v_reg_users);
	-- give superadmins logon as any user on RegisteredUsers
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_reg_users), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_super_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_LOGON_AS_USER);
	
	-- create a data providers group
	group_pkg.CreateGroupWithClass(
		in_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Data Providers', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_data_providers
	);
	
	-- create a data approvers group
	group_pkg.CreateGroupWithClass(
		in_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Data Approvers', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_data_approvers
	);
	
	-- create auditors group
	group_pkg.CreateGroupWithClass(
		in_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Auditors', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_auditors
	);
	
	-- create reporters group
	group_pkg.CreateGroupWithClass(
		in_act_id, 
		v_groups, 
		security_pkg.GROUP_TYPE_SECURITY, 
		'Reporters', 
		class_pkg.getclassid('CSRUserGroup'), 
		v_reporters
	);
	
	/*** CSR ***/
	-- create root node
	securableObject_pkg.CreateSO(in_act_Id, in_parent_sid_id, class_pkg.GetClassId('CSRData'), 'CSR', out_csr_sid);	
	-- allow registered users read on the CSR node
	securableObject_pkg.ClearFlag(in_act_id, out_csr_sid, security_pkg.SOFLAG_INHERIT_DACL); 
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_csr_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);
	-- grant admins ALL permissions on the CSR node
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_csr_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	-- grant admins ALL permissions on the app 
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(in_parent_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	-- grant admins 'alter schema' on CSR node (not inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_csr_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL+csr_data_pkg.PERMISSION_ALTER_SCHEMA);
	
	/*** INDICATORS ***/	
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(in_act_id, in_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY, 'Indicators',
		security_pkg.SO_CONTAINER, v_ind_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_ind_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_ind_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** REGIONS ***/
	-- create as a group so we can add members (for permissions)
	group_pkg.CreateGroupWithClass(in_act_id, in_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY, 'Regions',
		security_pkg.SO_CONTAINER, v_region_root_sid_id);
	-- add object to the DACL (the container is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_region_root_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_region_root_sid_id, security_pkg.PERMISSION_STANDARD_READ);
	
	/*** MEASURES ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Measures', v_new_sid_id);
	-- grant registered users READ on measures (inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
				
	/*** DATAVIEWS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Dataviews', v_new_sid_id);
	-- grant RegisteredUsers READ on Dataviews
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** DASHBOARDS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Dashboards', v_new_sid_id);
	-- grant RegisteredUsers READ on Dashboards
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	/*** IMPORTS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Imports', v_new_sid_id);
	-- grant Auditors READ on Imports (inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	-- grant Auditors READ / WRITE on Imports (inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_providers, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** FORMS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	-- grant Auditors + Data Providers READ on Forms (inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_providers, security_pkg.PERMISSION_STANDARD_READ);
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_data_approvers, security_pkg.PERMISSION_STANDARD_READ);
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
		
	/*** DELEGATIONS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Delegations', v_new_sid_id);
	-- grant auditors
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_auditors, security_pkg.PERMISSION_STANDARD_READ);
	
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'DelegationPlans', v_deleg_plans_sid);
	
	
	/*** PENDING FORMS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Pending', v_pending_sid_id);
	SecurableObject_pkg.CreateSO(in_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Forms', v_new_sid_id);
	SecurableObject_pkg.CreateSO(in_act_id, v_pending_sid_id, security_pkg.SO_CONTAINER, 'Datasets', v_new_sid_id);
	
	/*** TRASH ***/
	-- create trash 
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, class_pkg.GetClassId('TrashCan'), 'Trash', v_trash_sid_id);
	-- grant admins RESTORE FROM TRASH permissions
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_trash_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL + csr_data_pkg.PERMISSION_RESTORE_FROM_TRASH);
		
	/*** ACCOUNT POLICY ***/
	-- create an account policy with no options set
	-- give admins write access on it
	security.accountPolicy_pkg.CreatePolicy(in_act_id, in_parent_sid_id, 'AccountPolicy', null, null, null, null, null, 1, v_policy_sid);
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_policy_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_INHERIT_INHERITABLE, v_admins, security_pkg.PERMISSION_STANDARD_ALL);

	/*** MAIL ***/
	-- create system mail account and add an Outbox (foo.credit360.com -> foo@credit360.com)
	-- .credit360.com = 14 chars
	IF LOWER(SUBSTR(v_host, LENGTH(v_host)-13,14)) = '.credit360.com' THEN
		-- a standard foo.credit360.com
		v_email := SUBSTR(v_host, 1, LENGTH(v_host)-14)||'@credit360.com';
		v_tracker_email := SUBSTR(v_host, 1, LENGTH(v_host)-14)||'_tracker@credit360.com';
	ELSE
		-- not a standard foo.credit360.com, so... www.foo.com@credit360.com
		v_email := v_host||'@credit360.com';
		v_tracker_email := v_host||'_tracker@credit360.com';
	END IF;

	-- If you get an error here, it's probably because you dropped/recreated the site
	-- You will have to clean up the mailbox manually
	-- This is DELIBERATELY not re-using the mailbox to avoid cross-site mail leaks
	mail.mail_pkg.createAccount(v_email, NULL, 'System mail account for '||v_host, v_account_sid, v_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);

	-- create sent/outbox and grant registered users add contents permission so they can be sent alerts
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Sent', v_sent_mailbox_sid);
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_sent_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Outbox', v_outbox_mailbox_sid);	
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_outbox_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
	
	-- create a container for per user mailboxes
	mail.mail_pkg.createMailbox(v_root_mailbox_sid, 'Users', v_users_mailbox_sid);

	-- create the tracker account
	mail.mail_pkg.createAccount(v_tracker_email, NULL, 'Tracker mail account for '||v_host, v_tracker_account_sid, v_tracker_root_mailbox_sid);
	-- let admins poke the mailboxes
	acl_pkg.AddACE(SYS_CONTEXT('SECURITY', 'ACT'), acl_pkg.GetDACLIDForSID(v_tracker_root_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
		
	/*** REPORTING PERIODS ***/
	SecurableObject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'ReportingPeriods', v_new_sid_id);
	-- grant registered users READ on reporting periods (inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);

	-- set the start-month attribute
	securableobject_pkg.SetNamedNumberAttribute(in_act_id, out_csr_sid, 'start-month', in_start_month);

	/*** GENERAL CUSTOMER ATTRIBUTES ***/
	-- insert into customer
	INSERT INTO customer (
		app_sid, name, host, system_mail_address, tracker_mail_address, alert_mail_address, alert_mail_name,
		editing_url, account_policy_sid, current_reporting_period_sid, 
		ind_info_xml_fields, 
		ind_root_sid, region_root_sid, trash_sid
	) VALUES (
		in_parent_sid_id, v_host, v_host, v_email, v_tracker_email, 'support@credit360.com', 'Credit360 support team',
		'/csr/site/delegation/sheet.acds?', v_policy_sid, null,
		XMLType('<ind-metadata><field name="definition" label="Detailed info"/></ind-metadata>'),
		null, null, v_trash_sid_id
	);
	
	-- locks
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(in_parent_sid_id, csr_data_pkg.LOCK_TYPE_CALC);
	INSERT INTO app_lock
		(app_sid, lock_type)
	VALUES
		(in_parent_sid_id, csr_data_pkg.LOCK_TYPE_SHEET_CALC);

	-- scrag progress
	INSERT INTO scrag_progress
		(app_sid)
	VALUES
		(in_parent_sid_id);

	-- clone all superadmins for the new app
	INSERT INTO csr_user (app_sid, csr_user_sid, user_name, full_name, email, friendly_name, guid)
		SELECT in_parent_sid_id, s.csr_user_sid, s.user_name, s.full_name, s.email, s.friendly_name, s.guid
          FROM superadmin s
         INNER JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- sometimes we record audit log entries against builtin/administrator and guest
	-- we hard-coded the GUIDs so csrexp will move them nicely
	INSERT INTO CSR_USER 
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(in_parent_sid_id, security_pkg.SID_BUILTIN_ADMINISTRATOR, 'builtinadministrator', 'Builtin Administrator', 
		 'Builtin Administrator', 'support@credit360.com', 'A3B4FB4B-BC13-53A3-8714-95640E79CA8A', 1);
	INSERT INTO CSR_USER 
		(app_sid, csr_user_sid, user_name, full_name, friendly_name, email, guid, hidden)
	VALUES 
		(in_parent_sid_id, security_pkg.SID_BUILTIN_GUEST, 'guest', 'Guest', 
		 'Guest', 'support@credit360.com', '77646D7A-A70E-E923-2FF6-2FD960873984', 1); 

	-- create a default reporting period
	v_period_start_dtm := TO_DATE('1/'||in_start_month||'/'||EXTRACT(Year FROM SYSDATE),'DD/MM/yyyy');
	reporting_period_pkg.CreateReportingPeriod(in_act_id, in_parent_sid_id, EXTRACT(Year FROM SYSDATE), v_period_start_dtm, ADD_MONTHS(v_period_start_dtm, 12), 0, v_period_sid); 	
	UPDATE customer
 	   SET current_reporting_period_sid = v_period_sid
 	 WHERE app_sid = in_parent_sid_id;

	/*** BOOTSTRAP INDICATORS AND REGIONS ***/
	-- we have to do this once we've put data into the customer table due to FK constraints on APP_SID
	-- Add standard region types to the customer_region_type table for this app
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (in_parent_sid_id, csr_data_pkg.REGION_TYPE_NORMAL);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (in_parent_sid_id, csr_data_pkg.REGION_TYPE_ROOT);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (in_parent_sid_id, csr_data_pkg.REGION_TYPE_PROPERTY);
	INSERT INTO customer_region_type (app_sid, region_type) VALUES (in_parent_sid_id, csr_data_pkg.REGION_TYPE_TENANT);
	-- add region root
	INSERT INTO REGION_TREE (
		REGION_TREE_ROOT_SID, app_sid, LAST_RECALC_DTM, IS_PRIMARY
	) VALUES (
		v_region_root_sid_id, in_parent_sid_id, NULL, 1
	);		
	-- insert regions sid (for user start points)
	INSERT INTO REGION (
		region_sid, parent_sid, app_sid, name, description, active, pos, info_xml, link_to_region_sid, region_type
	) VALUES (
		v_region_root_sid_id, in_parent_sid_id, in_parent_sid_id, 'regions', 'Regions', 1, 1, null, null, csr_data_pkg.REGION_TYPE_ROOT
	);
	INSERT INTO IND (
		ind_sid, parent_sid, name, description, app_sid
	) VALUES (
		v_ind_root_sid_id, in_parent_sid_id, 'indicators', 'Indicators', in_parent_sid_id
	);
	-- make Indicators and Regions members of themselves 
	group_pkg.AddMember(in_act_id, v_ind_root_sid_id, v_ind_root_sid_id);
	group_pkg.AddMember(in_act_id, v_region_root_sid_id, v_region_root_sid_id);
	
	UPDATE customer
	   SET ind_root_sid = v_ind_root_sid_id, 
	   	   region_root_sid = v_region_root_sid_id
	 WHERE app_sid = in_parent_sid_id;

    -- fiddle with UserCreatorDaemon    
    v_user_creator_daemon_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_parent_sid_id, 'Users/UserCreatorDaemon');
    
    INSERT INTO csr_user
        (csr_user_sid, email, guid, region_mount_point_sid, app_sid,
        full_name, user_name, friendly_name, info_xml, send_alerts, show_portal_help)
        SELECT v_user_creator_daemon_sid , 'support@credit360.com',  user_pkg.GenerateACT, c.region_root_sid,  
            c.app_sid, 'Automatic User Creator', 'UserCreatorDaemon', 'Automatic User Creator', null, 0, 0
          FROM customer c
         WHERE c.app_sid = in_parent_sid_id;

	-- Grant UserCreatorDaemon add contents permission on the users mailbox folder (non-inheritable)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_users_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		0, v_user_creator_daemon_sid, security_pkg.PERMISSION_ADD_CONTENTS);

	-- Make them a member of registered users
	security.group_pkg.AddMember(SYS_CONTEXT('SECURITY', 'ACT'), v_user_creator_daemon_sid, v_reg_users);

    -- add start point for superadmins
    INSERT INTO ind_start_point (ind_sid, user_sid)
        SELECT v_ind_root_sid_id, s.csr_user_sid
          FROM superadmin s
         INNER JOIN security.securable_object so ON s.csr_user_sid = so.sid_id;

	-- add a mailbox for each user, granting them full control over it
	-- and giving other registered users add contents permission
	FOR r IN (SELECT csr_user_sid
				FROM csr_user) LOOP
		mail.mail_pkg.createMailbox(v_users_mailbox_sid, r.csr_user_sid, v_user_mailbox_sid);
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_ADD_CONTENTS);
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_user_mailbox_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, r.csr_user_sid, security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;

	/*** SECTIONS ***/
	securableobject_pkg.CreateSO(in_act_id, in_parent_sid_id, security_pkg.SO_CONTAINER, 'Text', v_text_sid);
    securableobject_pkg.CreateSO(in_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Statuses', v_text_statuses_sid);
    securableobject_pkg.CreateSO(in_act_id, v_text_sid, security_pkg.SO_CONTAINER, 'Transitions', v_text_transitions_sid);
    -- make default status (red)
    section_status_pkg.CreateSectionStatus('Editing', 15728640, 0, v_status_sid);

	-- section root relies on a row in the customer table so we create it down here
	securableobject_pkg.CreateSO(in_act_id, in_parent_sid_id, class_pkg.GetClassID('CSRSectionRoot'), 'Sections', v_new_sid_id);
	-- Give the administrators group ALL and CHANGE_TITLE permimssions on it (inheritable)
	-- (We have to do this as the change title permission is unique to a CSRSectionRoot or CSRSection object and so is 
	-- not inherited from the parent)
	acl_pkg.RemoveACEsForSid(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), v_admins);
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_new_sid_id), 
		security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, 
		v_admins, security_pkg.PERMISSION_STANDARD_ALL + section_pkg.PERMISSION_CHANGE_TITLE);
	
	-- add Subdelegation capability and other common bits
	csr_data_pkg.enablecapability('Subdelegation');
	csr_data_pkg.enablecapability('System management');
	csr_data_pkg.enablecapability('Issue management');
	csr_data_pkg.enablecapability('Report publication');
	csr_data_pkg.enablecapability('Manage any portal');
	csr_data_pkg.enablecapability('Create users for approval');
	
	/*** HELP **/
	-- insert the first help_lang_id for this customer
	INSERT INTO customer_help_lang (app_sid, help_lang_id, is_default)
		SELECT in_parent_sid_id, MIN(help_lang_id), 1 
		  FROM help_lang;
	
	
	csr.region_pkg.createregion(
		in_parent_sid => v_deleg_plans_sid,
		in_name => 'DelegPlansRegion',
		in_description => 'DelegPlansRegion',
		in_geo_type => region_pkg.REGION_GEO_TYPE_OTHER,
		out_region_sid => v_new_sid_id
	);	  
	
	/*** ISSUE BITS ***/
	INSERT INTO ISSUE_TYPE (app_sid, issue_type_Id, label)
		VALUES (in_parent_sid_id, 1, 'Data entry form');
	INSERT INTO ISSUE_TYPE (app_sid, issue_type_Id, label)
		VALUES (in_parent_sid_id, 2, 'Questionnaire');
	INSERT INTO ISSUE_TYPE (app_sid, issue_type_Id, label)
		VALUES (in_parent_sid_id, 3, 'Corrective action');

	
	/*** ALERTS AND ALERT TEMPLATES ***/	
	/*** default to English **/
	SELECT lang_id
	  INTO v_lang_id
	  FROM aspen2.lang
	 WHERE lang = 'en';
	
	-- use english as the base for the site (rather than en-gb)
	aspen2.tr_pkg.SetBaseLang(SYS_CONTEXT('SECURITY', 'APP'), 'en');
	aspen2.tr_pkg.AddApplicationTranslation(SYS_CONTEXT('SECURITY', 'APP'), v_lang_id);

	-- now add in standard alerts for all csr customers (1 -> 5) + bulk mailout (20) + password reminder etc (21 -> 26)
	INSERT INTO customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
		SELECT in_parent_sid_id, customer_alert_type_id_seq.nextval, std_alert_type_id
		  FROM std_alert_type 
		 WHERE std_alert_type_id IN (
				ALERT_NEW_USER, 
				ALERT_NEW_DELEGATION,
				ALERT_OVERDUE_SHEET,
				ALERT_SHEET_CHANGED,
				ALERT_REMINDER_SHEET,
				ALERT_DELEG_TERMINATED,
				ALERT_GENERIC_MAILOUT,
				ALERT_SELFREG_VALIDATE,
				ALERT_SELFREG_NOTIFY,
				ALERT_SELFREG_APPROVAL,
				ALERT_SELFREG_REJECT,
				ALERT_PASSWORD_RESET,
				ALERT_ACCOUNT_DISABLED, 
				ALERT_USER_COVER_STARTED);
		 
	AddStandardFramesAndTemplates;
	
	
	-- some basic units
	measure_pkg.createMeasure(
		in_name 					=> 'fileupload',
		in_description 				=> 'File upload',
		in_custom_field 			=> CHR(38),
		in_pct_ownership_applies	=> 0,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'text',
		in_description 				=> 'Text',
		in_custom_field 			=> '|',
		in_pct_ownership_applies	=> 0,
		out_measure_sid				=> v_sid
	);
	measure_pkg.createMeasure(
		in_name 					=> 'date',
		in_description 				=> 'Date',
		in_custom_field 			=> '$',
		in_pct_ownership_applies	=> 0,
		out_measure_sid				=> v_sid
	);

		 
	-- delegation submission report
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportSubmissionPromptness');
	sqlreport_pkg.EnableReport('csr.delegation_pkg.GetReportDelegationBlockers');
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


PROCEDURE LockPeriod(
	in_act_id			security_pkg.T_ACT_ID,
	in_app_sid		security_pkg.T_SID_ID,
	in_start_dtm		customer.lock_start_dtm%TYPE,
	in_end_dtm			customer.lock_end_dtm%TYPE
)
AS
BEGIN
	-- permissions
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'csr'),  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	UPDATE customer 
	   SET lock_start_dtm = in_start_dtm,
		lock_end_dtm = in_end_dtm
     WHERE app_sid = in_app_sid;
END;


PROCEDURE RemovePeriodLock(
	in_act_id			security_pkg.T_ACT_ID,
	in_app_sid		security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE customer
	   SET lock_start_dtm = '1 jan 1980', lock_end_dtm = '1 jan 1980' 
	 WHERE app_sid = in_app_sid;
END;


FUNCTION IsPeriodLocked(
	in_app_sid		security_pkg.T_SID_ID,
	in_start_dtm		customer.lock_start_dtm%TYPE,
	in_end_dtm			customer.lock_end_dtm%TYPE
) RETURN NUMBER
AS
	CURSOR c IS
		SELECT lock_start_dtm, lock_end_dtm 
		  FROM customer
		 WHERE app_sid = in_app_sid
		   AND lock_start_dtm < in_end_dtm
		   AND lock_end_dtm > in_start_dtm;
	r	c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN
		RETURN 0;
	ELSE
		RETURN 1;
	END IF;
END;

FUNCTION AddToAuditDescription(
	in_field_name	IN	VARCHAR2,
	in_old_value	IN	VARCHAR2,
	in_new_value	IN	VARCHAR2
) RETURN VARCHAR2
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		IF LENGTH(in_new_value)>40 THEN
			RETURN in_field_name||' changed to '''||SUBSTR(in_new_value,1,40)||'...''; ';
		ELSE
			RETURN in_field_name||' changed to '''||NVL(in_new_value,'null')||'''; ';
		END IF;
	ELSE
		RETURN '';
	END IF;
END;

PROCEDURE AuditClobChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	CLOB,
	in_new_value		IN	CLOB,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_from	CLOB;
	v_to	CLOB;
BEGIN
	IF DBMS_LOB.COMPARE(in_old_value, in_new_value) != 0 OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		
		IF in_old_value IS NULL THEN
			v_from := 'Empty';
		ELSE
			-- hmm, that's chars not number of bytes, but the audit log code truncates properly anyway. Main thing is to avoid passing a 60k clob
			-- note that the param order on DBMS_LOB.SUBSTR is different to normal SUBSTR
			v_from := DBMS_LOB.SUBSTR(in_old_value, LEAST(LENGTH(in_old_value), 2048), 1);
		END IF;
		IF in_new_value IS NULL THEN
			v_to := 'Empty';
		ELSE
			-- hmm, that's chars not number of bytes, but the audit log code truncates properly anyway. Main thing is to avoid passing a 60k clob
			-- note that the param order on DBMS_LOB.SUBSTR is different to normal SUBSTR
			v_to := DBMS_LOB.SUBSTR(in_new_value, LEAST(LENGTH(in_new_value), 2048), 1);
		END IF;
		
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, v_from, v_to);
	END IF;
END;

PROCEDURE AuditValueChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, NVL(in_old_value,'Empty'), NVL(in_new_value,'Empty'));
	END IF;
END;

PROCEDURE AuditValueDescChange(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_field_name		IN	VARCHAR2,
	in_old_value		IN	VARCHAR2,
	in_new_value		IN	VARCHAR2,
	in_old_desc			IN	VARCHAR2,
	in_new_desc			IN	VARCHAR2,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	IF in_old_value!=in_new_value OR
		(in_old_value IS NULL AND in_new_value IS NOT NULL) OR
		(in_new_value IS NULL AND in_old_value IS NOT NULL) THEN
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 '{0} changed from "{1}" to "{2}"', in_field_name, NVL(in_old_desc,'Empty'), NVL(in_new_desc,'Empty'));
	END IF;
END;

PROCEDURE AuditInfoXmlChanges(
	in_act				IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_info_xml_fields	IN	XMLType,
	in_old_info_xml		IN	XMLType,
	in_new_info_xml		IN	XMLType,
	in_sub_object_id    IN  audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	
	-- there is slightly customized version of this procedure in donations/donation_body.sql
	FOR rx IN (
		 SELECT 
		    CASE 
		      WHEN n.node_key IS NULL THEN '{0} deleted'
		      WHEN o.node_key IS NULL THEN '{0} set to "{2}"'
		      ELSE '{0} changed from "{1}" to "{2}"'
		    END action, NVL(f.node_label, NVL(o.node_key, n.node_key)) node_label, 
		    REGEXP_REPLACE(NVL(o.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') old_node_value, 
		    REGEXP_REPLACE(NVL(n.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') new_node_value
		  FROM (
		      SELECT 
		        EXTRACT(VALUE(x), 'field/@name').getStringVal() node_key,
		        EXTRACT(VALUE(x), 'field/@label').getStringVal() node_label
		      FROM TABLE(XMLSEQUENCE(EXTRACT(in_info_xml_fields, '*/field' )))x
		   )f, (
		    SELECT 
		      EXTRACT(VALUE(x), 'field/@name').getStringVal() node_key, 
		      EXTRACT(VALUE(x), 'field/text()').getStringVal() node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_old_info_xml, '/fields/field'))
		      )x
		  )o FULL OUTER JOIN (
		     SELECT 
		      EXTRACT(VALUE(x), 'field/@name').getStringVal() node_key, 
		      EXTRACT(VALUE(x), 'field/text()').getStringVal() node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_new_info_xml, '/fields/field'))
		      )x
		  )n ON o.node_key = n.node_key
		  WHERE f.node_key = NVL(o.node_key, n.node_key)
		    AND (n.node_key IS NULL
				OR o.node_key IS NULL
				OR NVL(o.node_value, '-') != NVL(n.node_value, '-')
			)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntryAndSubObject(in_act, in_audit_type_id, in_app_sid, in_object_sid, in_sub_object_id,
			 rx.action, rx.node_label, rx.old_node_value, rx.new_node_value);
	END LOOP;
END;

-- takes appsid (useful for actions + donations)
PROCEDURE WriteAppAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
    WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);
END;

PROCEDURE WriteAuditLogEntry_AT(
	in_act_id			IN	security_pkg.T_ACT_ID	DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	PRAGMA AUTONOMOUS_TRANSACTION; 
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
    WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);
    COMMIT;
END;


PROCEDURE WriteAuditLogEntry(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	
	WriteAuditLogEntryForSid(v_user_sid, in_audit_type_id, in_app_sid, in_object_sid, in_description, in_param_1, in_param_2, in_param_3, in_sub_object_id);	
END;

PROCEDURE WriteAuditLogEntryAndSubObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN  audit_log.sub_object_id%TYPE DEFAULT NULL,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL
)
AS
	v_user_sid	security_pkg.T_SID_ID;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, SUB_OBJECT_ID, PARAM_1, PARAM_2, PARAM_3)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, v_user_sid, TruncateString(in_description,1023), in_sub_object_id, TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048) );
END;


-- doesn't seem to like overloading when we chagne the first param - maybe due to the defaults? dunno
PROCEDURE WriteAuditLogEntryForSid(
	in_sid_id			IN	security_pkg.T_SID_ID,
	in_audit_type_id	IN	audit_log.audit_type_id%TYPE,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_description		IN	audit_log.description%TYPE,
	in_param_1          IN  audit_log.param_1%TYPE DEFAULT NULL,
	in_param_2          IN  audit_log.param_2%TYPE DEFAULT NULL,
	in_param_3          IN  audit_log.param_3%TYPE DEFAULT NULL,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE DEFAULT NULL
)
AS
BEGIN
	INSERT INTO audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3, SUB_OBJECT_ID)
	VALUES
		(SYSDATE, in_audit_type_id, in_app_sid, in_object_sid, in_sid_id, TruncateString(in_description,1023), TruncateString(in_param_1,2048), TruncateString(in_param_2,2048), TruncateString(in_param_3,2048), in_sub_object_id);
END;


PROCEDURE GetAuditLogForX(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_row_count		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	-- Not really since STANDARD_READ includes it
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT * 
		  FROM (
			SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, cu.user_name, cu.csr_user_sid, 
				   description, so.NAME, param_1, param_2, param_3, al.remote_addr,
				   rownum rn, count(*) over () total_rows -- for the ext table
			  FROM audit_log al, audit_type aut, csr_user cu, security.securable_object so
			 WHERE so.sid_id = al.object_sid
			   AND cu.csr_user_sid = al.user_sid
			   AND al.audit_type_id = aut.audit_type_Id
			   AND al.app_sid = in_app_sid
			   AND object_sid = in_object_sid
			ORDER BY audit_date DESC
		 )
		 WHERE rn > in_start_row 
		   AND rn < in_start_row + in_row_count;
END;


PROCEDURE GetAuditLogForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- check permission.... insist on WRITE - slightly mroe hard-core than READ
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ al.audit_date, al.audit_type_id, aut.label, al.object_sid, cu.full_name, cu.user_name, al.csr_user_sid, 
			   al.description, al.name, al.param_1, al.param_2, al.param_3, al.remote_addr
		  FROM csr_user cu, audit_type aut, (
			/* get what ind/region cahnged to what number */
			SELECT vc.changed_dtm audit_date, csr_data_pkg.AUDIT_TYPE_CHANGE_VALUE audit_type_id,
				   vc.ind_sid object_sid, vc.changed_by_sid csr_user_sid, 
				   'Set "{0}" ("{1}") to {2}: '||vc.reason description, 
				   i.description name, -- unused?
				   i.description param_1, r.description param_2, to_char(val_number) param_3,
				   null remote_addr
			  FROM ( /* basic idea: don't get much out of val_change because it's huge. don't join it until we need to. 
			    	    there is an index on changed_by_sid, changed_dtm desc, val_changed_id to make this
			    	    fast enough
			    	  */
			  		SELECT *
			  		  FROM (
						SELECT val_change_id
						  FROM val_change
						 WHERE changed_by_sid = in_user_sid
					  ORDER BY changed_dtm desc)
					 WHERE rownum <= 100
				   ) x, val_change vc, region r, ind i
			 WHERE x.val_change_id = vc.val_change_id AND vc.region_sid = r.region_sid AND 
			 	   vc.ind_sid = i.ind_sid
			/* no dupes as val changes are recorded separately.  note if audit_log gets big too we will
			   have to do a similar inner restriction to above. */
			UNION ALL
			SELECT * -- this is what this user has done
			  FROM (SELECT al.audit_date, al.audit_type_id, al.object_sid, al.user_sid csr_user_sid, 
			  			   al.description, so.name, param_1, param_2, param_3, al.remote_addr
				  	  FROM audit_log al, SECURITY.securable_object so
				 	 WHERE user_sid = in_user_sid AND so.sid_id = al.object_sid AND
				   		   al.app_sid = in_app_sid
				  ORDER BY audit_date DESC)
			 WHERE rownum <= 100
			UNION 
			SELECT * -- this is what has been done to this user
			  FROM (SELECT al.audit_date, al.audit_type_id, al.object_sid, al.user_sid csr_user_sid, 
			  			   al.description, so.name, param_1, param_2, param_3, al.remote_addr
				  	  FROM audit_log al, SECURITY.securable_object so
				 	 WHERE object_sid = in_user_sid AND so.sid_id = al.object_sid AND
				   		   al.app_sid = in_app_sid
				  ORDER BY audit_date DESC)
			 WHERE rownum <= 100
        ) al
		WHERE aut.audit_type_id = al.audit_type_id and cu.csr_user_sid = al.csr_user_sid
	 ORDER BY audit_date DESC;	 
END;

PROCEDURE GetAuditLogForObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetAuditLogForObject(in_act_id, in_app_sid, in_object_sid, NULL, in_order_by, out_cur);
END;

PROCEDURE GetAuditLogForObject(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, LABEL, 
			object_sid, full_name, user_name, csr_user_sid, description, NAME, param_1, param_2, param_3, audit_date order_seq
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, cu.user_name, 
					   cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3, al.remote_addr
			      FROM audit_log al, audit_type aut, SECURITY.securable_object so, csr_user cu
				 WHERE so.sid_id = al.object_sid
			       AND cu.csr_user_sid = al.user_sid
			       AND al.audit_type_id = aut.audit_type_Id
			       AND al.app_sid = in_app_sid
	               AND object_sid = in_object_sid
                   AND (sub_object_id is NULL OR sub_object_id = in_sub_object_id)
			 	ORDER BY audit_date DESC
			  )x
		    )
		 ORDER BY order_seq DESC;
END;


PROCEDURE GetAuditLogForObjectType(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_audit_type_id    IN  audit_log.audit_type_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetAuditLogForObjectType(in_act_id, in_app_sid, in_object_sid, NULL, in_audit_type_id, in_order_by, out_cur);
END;


PROCEDURE GetAuditLogForObjectType(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_sub_object_id	IN	audit_log.sub_object_id%TYPE,
	in_audit_type_id    IN  audit_log.audit_type_id%TYPE,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, LABEL, object_sid, 
			NVL(full_name,'unknown') full_name, -- UserCreatorDaemon isn't in csr_user
			NVL(user_name,'unknown') user_name, -- UserCreatorDaemon isn't in csr_user
			user_sid csr_user_sid, -- UserCreatorDaemon isn't in csr_user
			description, NAME, param_1, param_2, param_3, audit_date order_seq
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.user_sid, al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, 
					   cu.user_name, cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3,
					   al.remote_addr
			      FROM audit_log al, audit_type aut, SECURITY.securable_object so, csr_user cu
				 WHERE so.sid_id = al.object_sid
			       AND cu.csr_user_sid(+) = al.user_sid
			       AND al.audit_type_id = aut.audit_type_Id
			       AND al.app_sid = in_app_sid
	               AND object_sid = in_object_sid
	           	   AND ((sub_object_id IS NULL AND in_sub_object_id IS NULL) OR sub_object_id = NVL(in_sub_object_id, sub_object_id))
                   AND al.audit_type_id = in_audit_type_id
			 	ORDER BY audit_date
			  )x
		    )
		 ORDER BY order_seq DESC;
END;

PROCEDURE GetAuditLogForObjectTypeClass(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_object_sid					IN	security_pkg.T_SID_ID,
	in_sub_object_id				IN	audit_log.sub_object_id%TYPE,
	in_audit_type_group_id  	 IN  audit_type.audit_type_group_id%TYPE,
	in_order_by						IN	VARCHAR2, -- redundant but needed for quick list output
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
    -- check permission.... insist on PERMISSION_LIST_CONTENTS - slightly more hard-core than just READ?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_object_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- TODO: check privs for doing this
	OPEN out_cur FOR
		SELECT audit_date, audit_type_id, label, object_sid, full_name, user_name, csr_user_sid, description, 
			   name, param_1, param_2, param_3, audit_date order_seq, remote_addr
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT al.audit_date, aut.audit_type_id, aut.LABEL, al.object_sid, cu.full_name, cu.user_name, 
					   cu.csr_user_sid, description, so.NAME, param_1, param_2, param_3, al.remote_addr
			      FROM audit_log al, audit_type aut, SECURITY.securable_object so, csr_user cu
				 WHERE so.sid_id = al.object_sid
			       AND cu.csr_user_sid = al.user_sid
			       AND al.audit_type_id = aut.audit_type_Id
			       AND al.app_sid = in_app_sid
	               AND object_sid = in_object_sid
	           	   AND sub_object_id = NVL(in_sub_object_id, sub_object_id)
                   AND al.audit_type_id IN (SELECT audit_type_id FROM audit_type WHERE audit_type_group_id = in_audit_type_group_id)
			 	ORDER BY audit_date
			  )x
		    )
		 ORDER BY order_seq DESC;
END;

PROCEDURE GetConfiguration(
	out_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- Reading the configuration requires write access on the application
	-- Could just be read -- but everybody has that!
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), security_pkg.GetApp(), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied reading configuration for the CSR application with sid '||security_pkg.GetApp());
	END IF;

	OPEN out_cur FOR
		SELECT c.name, c.host, c.system_mail_address, c.aggregation_engine_version, c.contact_email, c.editing_url,
			   c.message, c.raise_reminders, c.account_policy_sid, c.app_sid, c.status, c.raise_split_deleg_alerts,
			   c.ind_info_xml_fields, c.region_info_xml_fields, c.user_info_xml_fields, c.current_reporting_period_sid,
			   c.lock_start_dtm, c.lock_end_dtm, c.region_root_sid, c.ind_root_sid, c.cascade_reject, c.approver_response_window,
			   c.self_reg_group_sid, c.self_reg_needs_approval, c.self_reg_approver_sid, cu.full_name self_reg_approver_full_name, 
			   c.allow_partial_submit, c.helper_assembly, c.tracker_mail_address, c.alert_mail_address, c.approval_step_sheet_url, 
			   c.use_tracker, c.audit_calc_changes, c.fully_hide_sheets, c.use_user_sheets, c.allow_val_edit, c.calc_sum_zero_fill,
			   c.create_sheets_at_period_end, c.alert_mail_name, c.alert_batch_run_time
		  FROM customer c, csr_user cu
		 WHERE c.app_sid = security_pkg.GetApp()
		   AND c.app_sid = cu.app_sid(+) and c.self_reg_approver_sid = cu.csr_user_sid(+);
END;

PROCEDURE SetConfiguration(
	in_alert_mail_address			IN	customer.alert_mail_address%TYPE,
	in_alert_mail_name				IN	customer.alert_mail_name%TYPE,
	in_alert_batch_run_time			IN	customer.alert_batch_run_time%TYPE,
	in_raise_reminders				IN	customer.raise_reminders%TYPE,
	in_raise_split_deleg_alerts		IN	customer.raise_split_deleg_alerts%TYPE,
	in_cascade_reject       		IN	customer.cascade_reject%TYPE,
	in_approver_response_window		IN	customer.approver_response_Window%TYPE,
	in_self_reg_group_sid			IN	customer.self_reg_group_sid%TYPE,
	in_self_reg_needs_approval		IN	customer.self_reg_needs_approval%TYPE,
	in_self_reg_approver_sid		IN	customer.self_reg_approver_sid%TYPE,
    in_lock_end_dtm             	IN  customer.lock_end_dtm%TYPE,
    in_allow_partial_submit			IN	customer.allow_partial_submit%TYPE,
    in_create_sheets_period_end		IN	customer.create_sheets_at_period_end%TYPE
)
AS
	v_old_alert_batch_run_time		customer.alert_batch_run_time%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), security_pkg.GetApp(), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied writing configuration for the CSR application with sid '||security_pkg.GetApp());
	END IF;
	
	SELECT alert_batch_run_time
	  INTO v_old_alert_batch_run_time
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	UPDATE customer
	   SET alert_mail_address = in_alert_mail_address,
	   	   alert_mail_name = in_alert_mail_name,
	   	   alert_batch_run_time = in_alert_batch_run_time,
	   	   raise_reminders = in_raise_reminders,
	       raise_split_deleg_alerts = in_raise_split_deleg_alerts,
	       cascade_reject = in_cascade_reject,
           approver_response_window = in_approver_response_window,
           self_reg_group_sid = DECODE(in_self_reg_group_sid, -1, NULL, in_self_reg_group_sid),
           self_reg_needs_approval = in_self_reg_needs_approval,
           self_reg_approver_sid = in_self_reg_approver_sid,
           lock_end_dtm = in_lock_end_dtm,
           allow_partial_submit = in_allow_partial_submit,
           create_sheets_at_period_end = in_create_sheets_period_end
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	-- fix up batch run times if the batch time has changed
	IF v_old_alert_batch_run_time != in_alert_batch_run_time THEN
		UPDATE alert_batch_run abr
		   SET next_fire_time = (SELECT next_fire_time_gmt
		   						   FROM v$alert_batch_run_time abrt
		   						  WHERE abr.app_sid = abrt.app_sid
		   						    AND abr.csr_user_sid = abrt.csr_user_sid)
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END IF;
END;

PROCEDURE EnableCapability(
	in_capability  				IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    IN  NUMBER DEFAULT 0
)
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;

    -- just create a sec obj of the right type in the right place
    BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				SYS_CONTEXT('SECURITY','APP'), 
				security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;
	
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
			v_capabilities_sid, 
			class_pkg.GetClassId('CSRCapability'),
			in_capability,
			v_capability_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			IF in_swallow_dup_exception = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
			END IF;
	END;
END;

-- ACTless version (i.e. pulls from context)
FUNCTION CheckCapability(
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
BEGIN
    RETURN CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability);
END;

FUNCTION SQL_CheckCapability(
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(SYS_CONTEXT('SECURITY','ACT'), in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION SQL_CheckCapability(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER
AS
BEGIN
	IF CheckCapability(in_act_id, in_capability) THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

-- version with ACT since this is sometimes called by older SPs that are passed ACTs, so it 
-- is more consistent to also call this with the same ACT (just in case they were different
-- for some reason).
FUNCTION CheckCapability(
    in_act_Id                   IN  security_pkg.T_ACT_ID,
	in_capability  				IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid        security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;
	
	BEGIN
		-- get sid of capability to check permission
		v_capability_sid := securableobject_pkg.GetSIDFromPath(in_act_id, SYS_CONTEXT('SECURITY','APP'), '/Capabilities/' || in_capability);
		-- check permissions....
		RETURN Security_Pkg.IsAccessAllowedSID(in_act_id, v_capability_sid, security_pkg.PERMISSION_WRITE);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
            IF v_allow_by_default = 1 THEN
                RETURN TRUE; -- let them do it if it's not configured
            ELSE
                RETURN FALSE;
            END IF;
	END;
END; 

PROCEDURE GetAppGroups(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_cur FOR	
		SELECT sid_id, name 
		  FROM TABLE(securableobject_pkg.GetDescendantsAsTable(v_act_id, 
		  			 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups')))
		 WHERE class_id in (security_pkg.SO_GROUP, class_pkg.GetClassId('CSRUserGroup'));
END;


PROCEDURE GetAppGroupsAndRoles(
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id		security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	OPEN out_cur FOR	
		SELECT sid_id, name 
		  FROM TABLE(securableobject_pkg.GetDescendantsAsTable(v_act_id, 
		  			 	securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups')))
		 WHERE class_id in (
		 	security_pkg.SO_GROUP, class_pkg.GetClassId('CSRUserGroup'),
		 	security_pkg.SO_GROUP, class_pkg.GetClassId('CSRRole')
		 );
END;


PROCEDURE AddApplicationTranslation(
	in_application_sid		IN	customer.app_sid%TYPE,
	in_lang_id				IN	aspen2.lang.lang_id%TYPE
)
AS
	v_lang						aspen2.lang.lang%TYPE;
	v_alert_frame_id			alert_frame.alert_frame_id%TYPE;
	v_default_alert_frame_id	default_alert_frame.default_alert_frame_id%TYPE;
BEGIN
	aspen2.tr_pkg.AddApplicationTranslation(in_application_sid, in_lang_id);

	SELECT lang
	  INTO v_lang
	  FROM aspen2.lang
	 WHERE lang_id = in_lang_id;

	-- try and find a frame to add translations for.  if we've got no frames (weird user but possible), just add all defaults.
	BEGIN
		SELECT alert_frame_id
		  INTO v_alert_frame_id
		  FROM (SELECT alert_frame_id, rownum rn
		  		  FROM (SELECT alert_frame_id
		  				  FROM alert_frame
		 				 WHERE app_sid = in_application_sid
		 				 ORDER BY DECODE(name, 'Default', 0, 1)))
		 WHERE rn = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no frames, or templates, so just add the lot
			AddStandardFramesAndTemplates;
			RETURN;
	END;
		
	BEGIN
		-- try and find a default frame to copy translations from
		SELECT MIN(default_alert_frame_id)
		  INTO v_default_alert_frame_id
		  FROM default_alert_frame;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- There are no default frames, so quit
			RETURN;
	END;

	-- got a frame, add in missing translations for it
	INSERT INTO alert_frame_body (alert_frame_id, lang, html)
		SELECT v_alert_frame_id, lang, html
		  FROM default_alert_frame_body
		 WHERE default_alert_frame_id = v_default_alert_frame_id
		   AND lang = v_lang
		   AND lang NOT IN (SELECT lang
		   				 	  FROM alert_frame_body
		   				 	 WHERE alert_frame_id = v_alert_frame_id AND lang = v_lang);

	-- next add any missing templates that we have default config for in the given language
	INSERT INTO alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
		SELECT in_application_sid, cat.customer_alert_type_id, v_alert_frame_id, 'manual' -- always make new alerts manual send
		  FROM default_alert_template dat
			JOIN customer_alert_type cat ON dat.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE dat.default_alert_frame_id = v_default_alert_frame_id
		   AND customer_alert_type_id NOT IN (SELECT customer_alert_type_id 
											     FROM alert_template 
												WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
										     FROM customer_alert_type
										    WHERE app_sid = in_application_sid);
		   							  
	-- and finally any missing bodies
	INSERT INTO alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
		SELECT in_application_sid, cat.customer_alert_type_id, datb.lang, datb.subject, datb.body_html, datb.item_html
		  FROM default_alert_template_body datb
			JOIN customer_alert_type cat ON datb.std_alert_type_id = cat.std_alert_type_id AND cat.app_sid = in_application_sid
		 WHERE datb.std_alert_type_id IN (SELECT std_alert_type_id
		 								     FROM default_alert_template
		 							        WHERE default_alert_frame_id = v_default_alert_frame_id)
		   AND (customer_alert_type_id, lang) NOT IN (SELECT customer_alert_type_id, lang
		   									              FROM alert_template_body
		   									             WHERE app_sid = in_application_sid)
		   AND customer_alert_type_id IN (SELECT customer_alert_type_id
								             FROM customer_alert_type
								            WHERE app_sid = in_application_sid)
		   AND lang = v_lang;
END;

PROCEDURE LockApp(
	in_lock_type					IN	app_lock.lock_type%TYPE
)
AS
BEGIN
	UPDATE csr.app_lock
	   SET dummy = 1
	 WHERE lock_type = in_lock_type
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	 
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown lock type: '||in_lock_type);
	END IF;
END;

FUNCTION HasUnmergedScenario 
RETURN BOOLEAN
AS
	v_unmerged_scenario_run_sid		customer.unmerged_scenario_run_sid%TYPE;
BEGIN
	SELECT unmerged_scenario_run_sid
	  INTO v_unmerged_scenario_run_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	RETURN v_unmerged_scenario_run_sid IS NOT NULL;
END;

END;
/

	
	
DECLARE
	v_sa_sid					security.security_pkg.T_SID_ID;
	v_manage_templates			security.security_pkg.T_SID_ID;
BEGIN
	INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Manage CT Templates', 0);
	
	security.user_pkg.LogonAdmin;
	v_sa_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	
	FOR r IN (
		SELECT c.host FROM ct.customer_options co, csr.customer c WHERE co.app_sid = c.app_sid
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		csr.csr_data_pkg.EnableCapability('Manage CT Templates', 1);
		
		v_manage_templates := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Capabilities/Manage CT Templates');
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(security.security_pkg.GetAct, v_manage_templates, 0);
		-- clean existing ACE's
		security.acl_pkg.DeleteAllACEs(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_manage_templates));
				
		security.acl_pkg.AddACE(security.security_pkg.GetAct, security.Acl_pkg.GetDACLIDForSID(v_manage_templates), 
			security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/

@..\ct\admin_pkg
@..\ct\util_pkg

@..\ct\admin_body
@..\ct\util_body
@..\ct\company_body


@update_tail

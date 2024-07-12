CREATE OR REPLACE PACKAGE DONATIONS.SCHEME_Pkg
IS

-- permission constants
PERMISSION_VIEW_MINE			CONSTANT NUMBER(10) := 65536;
PERMISSION_VIEW_ALL				CONSTANT NUMBER(10) := 131072;
PERMISSION_UPDATE_MINE			CONSTANT NUMBER(10) := 262144;
PERMISSION_UPDATE_ALL 			CONSTANT NUMBER(10) := 524288;
PERMISSION_ADD_NEW				CONSTANT NUMBER(10) := 1048576;
PERMISSION_TRANSITION_ALLOWED	CONSTANT NUMBER(10) := 2097152;
PERMISSION_VIEW_REGION			CONSTANT NUMBER(10) := 4194304;
PERMISSION_UPDATE_REGION		CONSTANT NUMBER(10) := 8388608;
PERMISSION_UPDATE_TAGS			CONSTANT NUMBER(10) := 16777216;

-- errors
ERR_PERIOD_OVERLAPS			CONSTANT NUMBER := -20501;
PERIOD_OVERLAPS EXCEPTION;
PRAGMA EXCEPTION_INIT(PERIOD_OVERLAPS, -20501);

ERR_TAG_IN_USE			CONSTANT NUMBER := -20502;
TAG_IN_USE EXCEPTION;
PRAGMA EXCEPTION_INIT(TAG_IN_USE, -20502);

ERR_PAID_DTM_MISSING		CONSTANT NUMBER := -20503;
PAID_DTM_MISSING EXCEPTION;
PRAGMA EXCEPTION_INIT(PAID_DTM_MISSING, -20503);

ERR_DONATED_DTM_MISSING			CONSTANT NUMBER := -20504;
DONATED_DTM_MISSING EXCEPTION;
PRAGMA EXCEPTION_INIT(DONATED_DTM_MISSING, -20504);

ERR_MAX_FIELDS_NUMBER_OCCURED			CONSTANT NUMBER := -20505;
MAX_FIELDS_NUMBER_OCCURED EXCEPTION;
PRAGMA EXCEPTION_INIT(MAX_FIELDS_NUMBER_OCCURED, -20505);

ERR_DONATIONS_FOUND			CONSTANT NUMBER := -20506;
DONATIONS_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(DONATIONS_FOUND, -20506);

ERR_TRANSITION_INVALID			CONSTANT NUMBER := -20507;
TRANSITION_INVALID EXCEPTION;
PRAGMA EXCEPTION_INIT(TRANSITION_INVALID, -20507);

ERR_DUPLICATE_NAMES			CONSTANT NUMBER := -20508;
DUPLICATE_NAMES EXCEPTION;
PRAGMA EXCEPTION_INIT(DUPLICATE_NAMES, -20508);

ERR_HELPER_PKG				CONSTANT NUMBER := -20509;
HELPER_PKG EXCEPTION;
PRAGMA EXCEPTION_INIT(HELPER_PKG, -20509);

ERR_DELETE_FC_DONATION		CONSTANT NUMBER := -20510;
DELETE_FC_DONATION EXCEPTION;
PRAGMA EXCEPTION_INIT(DELETE_FC_DONATION, -20510);

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
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

--
-- PROCEDURE: CreateSCHEME
--
PROCEDURE CreateScheme (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_PKG.T_SID_ID,
	in_name					IN	SCHEME.name%TYPE,
	in_description	IN	SCHEME.description%TYPE,
	in_active			 	IN	SCHEME.active%TYPE,
	in_extra_fields_xml		IN	SCHEME.extra_fields_xml%TYPE,
	out_scheme_sid		 	OUT security_pkg.T_SID_ID
);

--
-- PROCEDURE: AmendSCHEME
--
PROCEDURE AmendScheme (
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_name				IN	SCHEME.name%TYPE,
	in_description	IN	SCHEME.description%TYPE,
	in_active		 	IN	SCHEME.active%TYPE,
	in_extra_fields_xml	IN	SCHEME.extra_fields_xml%TYPE
);

PROCEDURE GetScheme(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);



PROCEDURE GetSchemeFromBudgetId(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_budget_id	IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSchemes(
	in_act_id	IN	security_pkg.T_ACT_ID,
    in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomFields(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSchemeStatusMatrix(
	out_cur_schemes					OUT security_pkg.T_OUTPUT_CUR,
  out_cur_statuses				OUT security_pkg.T_OUTPUT_CUR,
  out_cur_matrix					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetSchemeStatuses(
    in_scheme_sid							IN	security_pkg.T_SID_ID,
    in_donation_status_sids		IN	security_pkg.T_SID_IDS
);

FUNCTION GetSchemeSidByName(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_name				IN	scheme.name%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE ExportSchemeDataToCSR(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE ExportSchemeDataWithTagIdToCSR (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE ExportSchemeDataWithTagIdToCSR (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE ExportAllSchemeDataToCSRExcept(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE AllSchemeDataWithTagIdToCSREx(
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE ExportSchemeDataToCSRNoDate(
	in_scheme_sid		IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_custom_values	IN  donation_pkg.T_CUSTOM_VALUES,
	in_reason			IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);

PROCEDURE ExportDataWithTagToCSRNoDate (
	in_scheme_sid			IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_custom_field_name	IN	VARCHAR2,
	in_tag_id				IN	tag.tag_id%TYPE,
	in_reason				IN	csr.val_change.reason%TYPE DEFAULT 'Data input directly into Community Involvement module'
);
END SCHEME_Pkg;
/
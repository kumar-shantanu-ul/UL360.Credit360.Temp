CREATE OR REPLACE PACKAGE chain.higg_pkg AS

HIGG_REFERENCE_FIELD CONSTANT 	VARCHAR2(255) := 'HIGGID';
HIGG_PROD_UNIT_OPT_ID 			NUMBER(10) := 2486;
HIGG_PROD_OZ_OPT_ID 			NUMBER(10) := 2487;
HIGG_PROD_LBS_OPT_ID 			NUMBER(10) := 2488;
HIGG_PROD_TONS_OPT_ID 			NUMBER(10) := 2489;
HIGG_PROD_TONNES_OPT_ID 		NUMBER(10) := 2490;
HIGG_PROD_YARDS_OPT_ID 			NUMBER(10) := 8313;
HIGG_PROD_METRES_OPT_ID 		NUMBER(10) := 8314;
HIGG_WEIGHT_UNITS_OPT_ID 		NUMBER(10) := 2491;
HIGG_WEIGHT_OZ_OPT_ID 			NUMBER(10) := 2492;
HIGG_WEIGHT_LBS_OPT_ID 			NUMBER(10) := 2493;
HIGG_WEIGHT_TONS_OPT_ID 		NUMBER(10) := 2494;
HIGG_WEIGHT_TONNES_OPT_ID 		NUMBER(10) := 2495;
HIGG_WEIGHT_YARDS_OPT_ID 		NUMBER(10) := 8315;
HIGG_WEIGHT_METRES_OPT_ID 		NUMBER(10) := 8316;

HIGG_RESPONSE_YR_LOOKUP_KEY		CONSTANT VARCHAR2(255)	:= 'HIGG_RESPONSE_YEAR';

PROCEDURE GetUnprocessedHiggProfiles (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateAuditDtm(
	in_audit_sid 					IN	csr.internal_audit.internal_audit_sid%TYPE,
	in_audit_dtm 					IN	csr.internal_audit.audit_dtm%TYPE
);

PROCEDURE SaveHiggAnswers (
	in_survey_response_id			IN	csr.quick_survey_response.survey_response_id%TYPE,
	in_higg_profile_id				IN	higg_profile.higg_profile_id%TYPE,
	in_response_year				IN  higg_response.response_year%TYPE,
	in_higg_config_id				IN	higg_config.higg_config_id%TYPE
);

PROCEDURE GetHiggIndicatorVals (
	in_aggregate_ind_group_id		IN	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE OnSurveySubmitted (
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_response_id					IN	security.security_pkg.T_SID_ID,
	in_submission_id				IN	security.security_pkg.T_SID_ID
);

PROCEDURE GetHiggResponseYrTag(
	in_higg_config_id 				IN	higg_config.higg_config_id%TYPE,
	in_response_year 				IN	higg_response.response_year%TYPE,
	out_resp_year_tag_id			OUT	csr.tag.tag_id%TYPE
);

PROCEDURE SetHiggAuditScore(
	in_internal_audit_sid 		csr.internal_audit.internal_audit_sid%TYPE
);

END higg_pkg;
/

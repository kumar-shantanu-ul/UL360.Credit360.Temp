CREATE OR REPLACE PACKAGE chain.higg_setup_pkg AS

ENERGY_LOOKUP	CONSTANT VARCHAR2(255)  := 'HIGG_KWH';
WEIGHT_LOOKUP	CONSTANT VARCHAR2(255)  := 'HIGG_KG';
VOLUME_LOOKUP	CONSTANT VARCHAR2(255)  := 'HIGG_M3';
UNIT_LOOKUP		CONSTANT VARCHAR2(255)  := 'HIGG_UNIT';
SOCIAL_MODULE 	CONSTANT NUMBER(10)		:= 5;
ENV_MODULE		CONSTANT NUMBER(10)		:= 6;

-- Indicators
HIGG_IND_ELEC_LOOKUP 			CONSTANT VARCHAR2(255) := 'ANNUAL_ELECTRICITY';
HIGG_IND_WATER_LOOKUP 			CONSTANT VARCHAR2(255) := 'ANNUAL_WATER';
HIGG_IND_WASTE_WATER_LOOKUP 	CONSTANT VARCHAR2(255) := 'DAILY_WASTEWATER';
HIGG_IND_WASTE_SOLID_LOOKUP		CONSTANT VARCHAR2(255) := 'ANNUAL_SOLID_WASTE';
HIGG_IND_WASTE_HAZ_LOOKUP		CONSTANT VARCHAR2(255) := 'ANNUAL_HAZARDOUS_WASTE';
HIGG_IND_WASTE_REC_LOOKUP		CONSTANT VARCHAR2(255) := 'ANNUAL_RECYCLED_WASTE';
HIGG_IND_PROD_ITEMS_LOOKUP		CONSTANT VARCHAR2(255) := 'ANNUAL_PROD_UNIT';
HIGG_IND_PROD_WEIGHT_LOOKUP		CONSTANT VARCHAR2(255) := 'ANNUAL_WEIGHT_WEIGHT';


TYPE T_NUM_ARRAY IS TABLE OF NUMBER(10) INDEX BY PLS_INTEGER;

PROCEDURE GetHiggModules (
	out_higg_modules				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAvailableSurveys (
	out_surveys_cur					OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHiggConfigurations (
	out_higg_config_cur				OUT	security.security_pkg.T_OUTPUT_CUR,
	out_higg_config_modules			OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetupModules (
	in_higg_config_id 				IN  higg_config.higg_config_id%TYPE,
	in_audit_type_id				IN	csr.internal_audit_type.internal_audit_type_id%TYPE,
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_modules						IN	security.security_pkg.T_SID_IDS,
	in_company_type_id				IN	company_type.company_type_id%TYPE,
	in_closure_type_id				IN	csr.audit_closure_type.audit_closure_type_id%TYPE,
	in_auditor_username				IN	VARCHAR2,
	in_copy_score_on_survey_submit	IN	NUMBER,
	out_higg_config_id				OUT	higg_config.higg_config_id%TYPE
);

FUNCTION IsHiggEnabled
RETURN NUMBER;

PROCEDURE SyncHiggSurvey (
	in_higg_config_id				IN higg_config.higg_config_id%TYPE
);

END;
/

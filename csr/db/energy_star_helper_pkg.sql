CREATE OR REPLACE PACKAGE CSR.energy_star_helper_pkg IS

FUNCTION UNSEC_ValFromCustom (
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_custom_value				IN	measure.custom_field%TYPE
) RETURN val.val_number%TYPE;

FUNCTION UNSEC_CustomFromVal (
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_num						IN	val.val_number%TYPE
) RETURN measure.custom_field%TYPE;

PROCEDURE HelperRefrigCases(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
);

PROCEDURE HelperYesNoSpaceAttr(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
);

PROCEDURE HelperCustomSpaceAttr(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
);

PROCEDURE HelperDistributionCenter(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
);

PROCEDURE HelperOfficeCooledHeated(
	in_est_account_sid			IN	security_pkg.T_SID_ID,
	in_mapping_name				IN	est_other_mapping.mapping_name%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid					IN	security_pkg.T_SID_ID,
	in_measure_conversion_id	IN	est_other_mapping.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	in_val						IN	NUMBER,
	in_str						IN	VARCHAR2
);

END;
/

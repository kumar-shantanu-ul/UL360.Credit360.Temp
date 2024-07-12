CREATE OR REPLACE PACKAGE DONATIONS.export_settings_pkg
IS

PROCEDURE SaveExportSettings(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_name				IN	user_fieldset.name%TYPE,
	in_fields			IN	VARCHAR,
	out_fieldset_id		OUT	user_fieldset.user_fieldset_id%TYPE
);

PROCEDURE GetExportFieldsById(
	in_act				IN	security_pkg.T_ACT_ID,
	in_fieldset_id		IN	user_fieldset.user_fieldset_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetExportFieldsByName(
	in_act				IN	security_pkg.T_ACT_ID,
	in_name				IN	user_fieldset.name%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFieldsetIds(
	in_act				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END export_settings_pkg;
/

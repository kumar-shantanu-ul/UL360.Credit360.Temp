CREATE OR REPLACE PACKAGE CSR.accuracy_Pkg AS

PROCEDURE GetAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END accuracy_Pkg;
/

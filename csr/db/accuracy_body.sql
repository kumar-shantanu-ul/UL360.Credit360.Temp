CREATE OR REPLACE PACKAGE BODY CSR.accuracy_Pkg AS

PROCEDURE GetAccuracyTypes(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT accuracy_type_id, LABEL, q_or_c, max_score 
		  FROM accuracy_type
		 WHERE app_sid = in_app_sid;
END;

PROCEDURE GetAccuracyTypeOptions(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_accuracy_type_id	IN	accuracy_type.accuracy_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT app_sid 
	  INTO v_app_sid	
	  FROM accuracy_type
	 WHERE accuracy_type_id = in_accuracy_type_id;

	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT accuracy_type_option_id, LABEL, accuracy_weighting
		  FROM accuracy_type_option
		 WHERE accuracy_type_id = in_accuracy_type_id;
END;

END accuracy_Pkg;
/

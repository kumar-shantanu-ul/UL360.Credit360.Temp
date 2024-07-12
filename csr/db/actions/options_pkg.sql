CREATE OR REPLACE PACKAGE  ACTIONS.options_pkg
IS

PROCEDURE GetOptions(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetScript(
	in_script_id	IN	script.script_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END options_pkg;
/


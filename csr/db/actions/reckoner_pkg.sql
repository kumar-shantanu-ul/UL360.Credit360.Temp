CREATE OR REPLACE PACKAGE  ACTIONS.reckoner_pkg
IS

PROCEDURE GetReckonerIdsForScope(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetReckoner (
	in_reckoner_id			IN	reckoner.reckoner_id%TYPE,
	out_reckoner			OUT	security_pkg.T_OUTPUT_CUR,
	out_inputs				OUT	security_pkg.T_OUTPUT_CUR,
	out_consts				OUT	security_pkg.T_OUTPUT_CUR,
	out_outputs				OUT	security_pkg.T_OUTPUT_CUR
);

END reckoner_pkg;
/


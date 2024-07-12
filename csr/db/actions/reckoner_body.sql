CREATE OR REPLACE PACKAGE BODY ACTIONS.reckoner_pkg
IS

PROCEDURE GetReckonerIdsForScope(
	in_project_sid			IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN	tag_group.tag_group_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_project_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read project with sid ' || in_project_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT tag_id, reckoner_id
		  FROM reckoner_tag
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND project_sid = in_project_sid
		   AND tag_group_id = in_tag_group_id;
END;

PROCEDURE GetReckoner(
	in_reckoner_id			IN	reckoner.reckoner_id%TYPE,
	out_reckoner			OUT	security_pkg.T_OUTPUT_CUR,
	out_inputs				OUT	security_pkg.T_OUTPUT_CUR,
	out_consts				OUT	security_pkg.T_OUTPUT_CUR,
	out_outputs				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_reckoner FOR
		SELECT reckoner_id, label, description, script
		  FROM reckoner
		 WHERE reckoner_id = in_reckoner_id;
		 
	OPEN out_inputs FOR
		SELECT reckoner_id, reckoner_input_id, name, label, pos
		  FROM reckoner_input
		 WHERE reckoner_id = in_reckoner_id;

	OPEN out_consts FOR
		SELECT d.reckoner_id, c.reckoner_const_id, c.name, c.label, c.val
		  FROM reckoner_const c, reckoner_const_dep d
		 WHERE d.reckoner_id = in_reckoner_id
		   AND c.reckoner_const_id = d.reckoner_const_id;
	
	OPEN out_outputs FOR
		SELECT reckoner_id, reckoner_output_id, name, label, map_to
		  FROM reckoner_output
		 WHERE reckoner_id = in_reckoner_id;
		
END;

END reckoner_pkg;
/

CREATE OR REPLACE PACKAGE BODY CSR.teamroom_initiative_pkg IS

PROCEDURE GetTeamroom(
	in_initiative_sid 	IN 	 security_pkg.T_SID_ID,
	out_cur				OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	-- XXX: check teamroom permissions?
	OPEN out_cur FOR
		SELECT t.teamroom_sid, t.name
		  FROM teamroom t
		  JOIN teamroom_initiative ti ON t.teamroom_sid = ti.teamroom_sid AND t.app_sid = ti.app_sid
		 WHERE ti.initiative_sid = in_initiative_sid;
END;

END;
/
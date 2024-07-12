CREATE OR REPLACE PACKAGE CSR.teamroom_initiative_pkg IS

PROCEDURE GetTeamroom(
	in_initiative_sid 	IN 	 security_pkg.T_SID_ID,
	out_cur				OUT  SYS_REFCURSOR
);

END;
/
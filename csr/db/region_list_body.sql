CREATE OR REPLACE PACKAGE BODY CSR.region_list_pkg IS

PROCEDURE GetOwnedRegions(
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetSID, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||security_pkg.GetSID);
	END IF;	  
	
	OPEN out_cur FOR 
		SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid, r.description 
		  FROM v$region r, region_owner ro
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_type = NVL(in_region_type, r.region_type)
		   AND r.region_sid = ro.region_sid
		   AND ro.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ro.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND r.active = 1
		 ORDER BY r.description;
END;

PROCEDURE GetRoleRegions(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetSID, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||security_pkg.GetSID);
	END IF;
 
 	OPEN out_cur FOR
		SELECT r.role_sid, reg.region_sid, reg.description
		  FROM role r, region_role_member rrm, v$region reg
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.role_sid = in_role_sid
		   AND r.role_sid = rrm.role_sid
		   AND rrm.region_sid = reg.region_sid
		   AND rrm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND reg.region_type = NVL(in_region_type, reg.region_type)
		   AND reg.active = 1
	 	 ORDER BY reg.description;
END;

END;
/

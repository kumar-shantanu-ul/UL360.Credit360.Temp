CREATE OR REPLACE PACKAGE CSR.region_list_pkg IS

PROCEDURE GetOwnedRegions(
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetRoleRegions(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

END;
/
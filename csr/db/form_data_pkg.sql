CREATE OR REPLACE PACKAGE csr.form_data_pkg
IS

PROCEDURE UNFINISHED_GetFormData (
	in_region_sids					IN  security_pkg.T_SID_IDS,
	in_indicator_sids				IN  security_pkg.T_SID_IDS,
	in_user_sids					IN  security_pkg.T_SID_IDS,
	in_role_sids					IN  security_pkg.T_SID_IDS,
	in_audit_sids					IN  security_pkg.T_SID_IDS,
	in_product_ids					IN  security_pkg.T_SID_IDS,
	in_company_sids					IN  security_pkg.T_SID_IDS,
	in_substance_ids				IN  security_pkg.T_SID_IDS,
	out_region_cur					OUT SYS_REFCURSOR,
	out_indicator_cur				OUT SYS_REFCURSOR,
	out_user_cur					OUT SYS_REFCURSOR,
	out_role_cur					OUT SYS_REFCURSOR,
	out_audit_cur					OUT SYS_REFCURSOR,
	out_product_cur					OUT SYS_REFCURSOR,
	out_company_cur					OUT SYS_REFCURSOR,
	out_substance_cur				OUT SYS_REFCURSOR
);

END;
/

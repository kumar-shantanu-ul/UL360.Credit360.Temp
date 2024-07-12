CREATE OR REPLACE PACKAGE BODY csr.form_data_pkg
IS

-- JB: This is from the proof of concept CMS/Mongo stuff.
-- The idea is that mongo doesn't know where to get the additional user display info for core objects, so they
-- are pulled out in one go here. This should be split up into separate microservices or something...
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
)
AS
	v_region_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_indicator_sids				security.T_SID_TABLE := security_pkg.SidArrayToTable(in_indicator_sids);
	v_user_sids						security.T_SID_TABLE := security_pkg.SidArrayToTable(in_user_sids);
	v_role_sids						security.T_SID_TABLE := security_pkg.SidArrayToTable(in_role_sids);
	v_audit_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_audit_sids);
	v_product_ids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_product_ids);
	v_company_sids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_company_sids);
	v_substance_ids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_substance_ids);
BEGIN
	-- DELETE FROM cms.temp_region_path;
	-- INSERT INTO cms.temp_region_path (region_sid, description, path, geo_country)
	-- 	SELECT region_sid, description, SYS_CONNECT_BY_PATH(REPLACE(description,chr(1),'_'),'') path, geo_country
	-- 	  FROM v$region
	-- 		START WITH parent_sid = app_sid
	-- 		CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid;

	OPEN out_region_cur FOR
		SELECT 0 region_sid, null path, null description, null geo_country
		  FROM dual
		 WHERE 1 = 0;
		-- SELECT region_sid, path, description, geo_country
		--   FROM cms.temp_region_path trp
		--   JOIN TABLE(v_region_sids) r ON trp.region_sid = r.column_value;
		  
	-- DELETE FROM cms.temp_ind_path;
	-- INSERT INTO cms.temp_ind_path (ind_sid, description, path)
	-- 	SELECT ind_sid, description, SYS_CONNECT_BY_PATH(REPLACE(description,chr(1),'_'),'') path
	-- 	  FROM v$ind
	-- 		START WITH parent_sid = app_sid
	-- 		CONNECT BY PRIOR app_sid = app_sid AND PRIOR ind_sid = parent_sid;

	OPEN out_indicator_cur FOR
		SELECT 0 ind_sid, null path, null description
		  FROM dual
		 WHERE 1 = 0;
		-- SELECT ind_sid, path, description
		--   FROM cms.temp_ind_path tip
		--   JOIN TABLE(v_indicator_sids) i ON tip.ind_sid = i.column_value;
	
	OPEN out_user_cur FOR
		SELECT cu.csr_user_sid, cu.full_name, cu.email
		  FROM csr_user cu
		  JOIN TABLE(v_user_sids) u ON cu.csr_user_sid = u.column_value;
	
	OPEN out_role_cur FOR
		SELECT r.role_sid, r.name, r.lookup_key
		  FROM role r
		  JOIN TABLE(v_role_sids) rs ON r.role_sid = rs.column_value;
	
	OPEN out_audit_cur FOR
		SELECT ia.internal_audit_sid, ia.label
		  FROM internal_audit ia
		  JOIN TABLE(v_audit_sids) a ON ia.internal_audit_sid = a.column_value;
	
	OPEN out_product_cur FOR
		SELECT 0 product_id, null product_name
		  FROM dual
		 WHERE 1 = 0;
		-- SELECT cp.product_id, cp.product_name
		--   FROM chain.v$company_product cp
		--   JOIN TABLE(v_product_ids) p ON cp.product_id = p.column_value;
	
	OPEN out_company_cur FOR
		SELECT cc.company_sid, cc.name, cc.country_code
		  FROM chain.v$company cc
		  JOIN TABLE(v_company_sids) c ON cc.company_sid = c.column_value;
	
	OPEN out_substance_cur FOR
		SELECT cs.substance_id, cs.description, cs.ref
		  FROM chem.substance cs
		  JOIN TABLE(v_substance_ids) s ON cs.substance_id = s.column_value;
END;

END;
/

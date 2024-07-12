CREATE OR REPLACE PACKAGE BODY CSR.region_api_pkg AS

FUNCTION GetNumberOfTrees(
	in_app_sid				IN	security_pkg.T_SID_ID
)
RETURN NUMBER
AS
	v_number_of_trees 		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_number_of_trees
	  FROM region_tree
	 WHERE app_sid = in_app_sid;

	RETURN v_number_of_trees;
END;

PROCEDURE GetRegionTags(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_tag_ids_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||in_region_sid);
	END IF;	

	OPEN out_tag_ids_cur FOR
		SELECT tgir.tag_id
		  FROM tag_group_ir_member tgir
		 WHERE tgir.region_sid = in_region_sid
		 ORDER BY tgir.tag_group_id, tgir.tag_id;
END;

PROCEDURE GetRegionCountry(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_country_code_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||in_region_sid);
	END IF;	

	OPEN out_country_code_cur FOR
		SELECT geo_country
		  FROM region
		 WHERE region_sid = in_region_sid;
END;

FUNCTION GetTrashedRegionSids
RETURN security.T_SID_TABLE
AS
	v_trashed_region_sids		security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_trashed_region_sids
	  FROM (
		SELECT region_sid
		  FROM region
			START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
			CONNECT BY PRIOR region_sid = parent_sid
		);
	RETURN v_trashed_region_sids;
END;

PROCEDURE FindRegionsByPath(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_path					IN	VARCHAR2,
	in_separator			IN	VARCHAR2 DEFAULT '/',
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_row_count			OUT SYS_REFCURSOR,
	out_cur					OUT SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 			T_PATH;
	v_parents				security.T_SID_TABLE;
	v_new_parents			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	SELECT LOWER(TRIM(item))
		BULK COLLECT INTO v_path_parts
		FROM table(utils_pkg.SplitString(in_path, in_separator));

	v_trashed_region_sids := GetTrashedRegionSids();

	IF GetNumberOfTrees(in_app_sid) > 1 THEN
	-- populate possible parents with the first part of the path
		BEGIN
			SELECT r.region_sid
			  BULK COLLECT INTO v_parents
			  FROM v$region r
			 WHERE LOWER(r.description) = v_path_parts(1)
			   AND r.app_sid = in_app_sid
			   AND r.active = 1
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = in_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				OPEN out_cur FOR
					SELECT region_sid
					  FROM v$region
					 WHERE 1 = 0;
				RETURN;
		END;
	ELSE --only one tree...
		BEGIN
			SELECT region_sid
			  BULK COLLECT INTO v_parents
			  FROM v$region
			 WHERE LOWER(description) = v_path_parts(1)
			   AND app_sid = in_app_sid
			   AND active = 1
			   AND region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND region_sid IN (
					SELECT region_sid
					  FROM region
					 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
				   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
				);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				OPEN out_cur FOR
					SELECT region_sid
					  FROM v$region
					 WHERE 1 = 0;
				RETURN;
		END;
	END IF;
	-- now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- select everything that matches into a set of possible parents
		SELECT region_sid
		BULK COLLECT INTO v_new_parents
		FROM v$region
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (
			SELECT COLUMN_VALUE
 			  FROM TABLE(v_parents)
		);
		v_parents := v_new_parents; -- we have to select into a different collection, so copy back on top
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;
	-- check permissions and return the stuff we've found
	OPEN out_cur FOR
		SELECT region_sid
		FROM(
			SELECT region_sid, rownum rn
			  FROM v$region
			 WHERE region_sid IN (SELECT column_value FROM TABLE(v_parents))
			   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.getAct, region_sid, security_pkg.PERMISSION_READ) = 1
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;
		  
	OPEN out_row_count FOR
		SELECT COUNT(*) AS total_rows
		  FROM TABLE(v_parents);
END;

PROCEDURE GetRegionsBySids(
	in_region_sids				IN	security.T_SID_TABLE,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, parent_sid AS parent_id, r.lookup_key, r.region_ref, link_to_region_sid AS link_to_region_id,
			   r.region_type, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type, r.active
		  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(in_region_sids))
		ORDER BY r.region_sid;

	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(in_region_sids))
		ORDER BY r.region_sid;
END;

PROCEDURE GetRegionsBySids(
	in_region_sids				IN	security_pkg.T_SID_IDS,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR
)
AS
	v_region_sids				security.T_SID_TABLE;
	v_app_sid					security_pkg.T_SID_ID;
	v_act_id					security_pkg.T_ACT_ID;
	v_allowed_region_sids		security.T_SO_TABLE;
BEGIN
	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);

	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, rt.class_name
		  FROM v$region r
		  JOIN region_type rt ON r.region_type = rt.region_type
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
		 ORDER BY r.region_sid;

	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM v$region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(v_region_sids))
		 ORDER BY r.region_sid;
END;

PROCEDURE GetRegions(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_parent_sid				IN	region.parent_sid%TYPE,
	in_search_all_trees			IN	NUMBER DEFAULT 0,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security_pkg.T_SID_ID;
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_region_sids				security.T_SID_TABLE;
	v_trashed_region_sids		security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_lookup_keys := in_lookup_keys;
	v_trashed_region_sids := GetTrashedRegionSids();
	
	IF in_search_all_trees = 0 AND GetNumberOfTrees(v_app_sid) > 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
					SELECT r.region_sid
					  FROM region r
					 WHERE r.app_sid = v_app_sid
					   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
					   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
					   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
					 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
				   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
					ORDER BY r.region_sid
					)
				)
			WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(r.region_sid) total_rows
			  FROM region r
			 WHERE r.app_sid = v_app_sid
			   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	ELSE -- Search all relevant IDs.
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
					SELECT r.region_sid
					  FROM region r
					 WHERE r.app_sid = v_app_sid
					   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
					   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
					   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
					 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
				   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
					ORDER BY r.region_sid
					)
				)
			WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(r.region_sid) total_rows
			  FROM region r
			 WHERE r.app_sid = v_app_sid
			   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	END IF;
	
	GetRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE GetRegions(
	in_parent_sid				IN	region.parent_sid%TYPE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetRegions(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 1,
		in_include_null_lookup_keys	=> 0,
		in_lookup_keys				=> security.T_VARCHAR2_TABLE(),
		in_parent_sid				=> in_parent_sid,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_region_cur				=> out_region_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetRegionsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_search_all_trees		IN	NUMBER DEFAULT 0,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_lookup_keys_count			NUMBER;
	v_lookup_contains_null		NUMBER(1) := 0;
BEGIN
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);

	IF in_lookup_keys.COUNT = 1 AND v_lookup_keys_count = 0 THEN
		-- Single null key in the params doesn't turn into a single null table entry for some reason.
		v_lookup_contains_null := 1;
	END IF;

	FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
	LOOP
		IF r.value IS NULL OR LENGTH(r.value) = 0 THEN
			v_lookup_contains_null := 1;
			EXIT;
		END IF;
	END LOOP;

	GetRegions(
		in_act_id					=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_include_all				=> 0,
		in_include_null_lookup_keys	=> v_lookup_contains_null,
		in_lookup_keys				=> v_lookup_keys,
		in_parent_sid				=> in_parent_sid,
		in_search_all_trees			=> in_search_all_trees,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_region_cur				=> out_region_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetRegionsByDescription(
	in_description			IN	region_description.description%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_region_sids := GetTrashedRegionSids();

	IF GetNumberOfTrees(v_app_sid) > 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
				SELECT DISTINCT r.region_sid
				  FROM region r
				  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
				 WHERE r.app_sid = v_app_sid
				   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
				   AND LOWER(d.description) = LOWER(in_description)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
			   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
				ORDER BY r.region_sid
					)
				)
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(DISTINCT(r.region_sid)) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND LOWER(d.description) = LOWER(in_description)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	ELSE --only one tree so no need for hierarchical query, just use ALL relevant ids
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
				SELECT DISTINCT r.region_sid
				  FROM region r
				  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
				 WHERE r.app_sid = v_app_sid
				   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
				   AND LOWER(d.description) = LOWER(in_description)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				ORDER BY r.region_sid
					)
				)
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(DISTINCT(r.region_sid)) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND LOWER(d.description) = LOWER(in_description)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1;
	END IF;

	GetRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;


PROCEDURE GetRegionsByGeoCountry(
	in_geo_country			IN	region.geo_country%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_region_sids := GetTrashedRegionSids();
	
	IF GetNumberOfTrees(v_app_sid) > 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT DISTINCT region_sid, rownum rn
			  FROM (
					SELECT r.region_sid
					  FROM region r
					 WHERE r.app_sid = v_app_sid
					   AND LOWER(r.geo_country) = LOWER(in_geo_country)
					   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
					   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
					 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
				   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
					ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

			  OPEN out_total_rows_cur FOR
				SELECT COUNT(DISTINCT(r.region_sid)) total_rows
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND LOWER(r.geo_country) = LOWER(in_geo_country)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
			   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	ELSE --only one tree so no need for hierarchical query, just use ALL relevant ids
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT DISTINCT region_sid, rownum rn
			  FROM (
					SELECT r.region_sid
					  FROM region r
					 WHERE r.app_sid = v_app_sid
					   AND LOWER(r.geo_country) = LOWER(in_geo_country)
					   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
					   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
					ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

			  OPEN out_total_rows_cur FOR
				SELECT COUNT(DISTINCT(r.region_sid)) total_rows
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND LOWER(r.geo_country) = LOWER(in_geo_country)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1;
	END IF;
	
	GetRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE GetRegionsByGeoRegion(
	in_geo_region			IN	region.geo_region%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_region_sids := GetTrashedRegionSids();
	
	IF GetNumberOfTrees(v_app_sid) > 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT DISTINCT region_sid, rownum rn
			  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND LOWER(r.geo_region) = LOWER(in_geo_region)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
			   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
				ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(DISTINCT(r.region_sid)) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND LOWER(r.geo_region) = LOWER(in_geo_region)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	ELSE
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT DISTINCT region_sid, rownum rn
			  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND LOWER(r.geo_region) = LOWER(in_geo_region)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(DISTINCT(r.region_sid)) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND LOWER(r.geo_region) = LOWER(in_geo_region)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1;
	END IF;

	GetRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE GetRegionsByGeoCity(
	in_geo_city_id			IN	region.geo_city_id%TYPE,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	v_trashed_region_sids := GetTrashedRegionSids();

	IF GetNumberOfTrees(v_app_sid) > 1 THEN
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND r.geo_city_id = in_geo_city_id
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
			   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
				ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(r.region_sid) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND r.geo_city_id = in_geo_city_id
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
			 START WITH parent_sid = NVL(in_parent_sid,(SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1 AND app_sid = v_app_sid))
		   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid;
	ELSE
		SELECT region_sid
		  BULK COLLECT INTO v_region_sids
		  FROM (
			SELECT region_sid, rownum rn
			  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = v_app_sid
				   AND r.geo_city_id = in_geo_city_id
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1
				ORDER BY r.region_sid
					)
			  )
			 WHERE rn > in_skip
			  AND rn < in_skip + in_take + 1;

		OPEN out_total_rows_cur FOR
			SELECT COUNT(r.region_sid) total_rows
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = v_app_sid
			   AND r.geo_city_id = in_geo_city_id
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			   AND security_pkg.SQL_IsAccessAllowedSID(v_act_id, r.region_sid, security_Pkg.PERMISSION_READ) = 1;
	END IF;
			   

	GetRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE Unsec_GetRegionBySid(
	in_sid					IN	NUMBER,
	in_include_tags			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_trashed_region_sids	security.T_SID_TABLE;
	v_is_in_trash			NUMBER;
BEGIN
	v_app_sid := security_pkg.GetApp;

	v_trashed_region_sids := GetTrashedRegionSids();

	SELECT COUNT(*)
	  INTO v_is_in_trash
	  FROM region r
	  JOIN TABLE(v_trashed_region_sids) t ON t.column_value = r.region_sid
	 WHERE r.region_sid = in_sid
	   AND r.app_sid = v_app_sid;

	IF v_is_in_trash > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_TRASH, 'The requested object is in the trash sid ' || in_sid);
	END IF;

	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, parent_sid AS parent_id, r.lookup_key, r.region_ref, link_to_region_sid AS link_to_region_id,
			   r.region_type, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type, r.active
		  FROM region r
		 WHERE r.app_sid = v_app_sid
		   AND r.region_sid = in_sid;

	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = v_app_sid
		   AND r.region_sid = in_sid;

	OPEN out_tags_cur FOR
		SELECT tgir.tag_id
		  FROM tag_group_ir_member tgir
		 WHERE tgir.region_sid = in_sid
		   AND in_include_tags = 1
		 ORDER BY tgir.tag_group_id, tgir.tag_id;
END;

PROCEDURE GetRegionBySid(
	in_sid					IN	NUMBER,
	in_include_tags			IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetAct, in_sid, security_pkg.PERMISSION_READ) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on region '||in_sid);
	END IF;

	Unsec_GetRegionBySid(
		in_sid				=> in_sid,
		in_include_tags		=> in_include_tags,
		out_region_cur		=> out_region_cur,
		out_description_cur	=> out_description_cur,
		out_tags_cur		=> out_tags_cur
	);
END;

PROCEDURE GetRegionsByPath(
	in_path					IN	VARCHAR2,
	in_parent_sid			IN	region.parent_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	path_cur				SYS_REFCURSOR;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;
	
	FindRegionsByPath(
		in_act_id			=> v_act_id,
		in_app_sid			=> v_app_sid,
		in_path				=> LOWER(in_path),
		in_separator		=> '/',
		in_parent_sid		=> in_parent_sid,
		in_skip				=> in_skip,
		in_take				=> in_take,
		out_row_count		=> out_total_rows_cur,
		out_cur				=> path_cur
	);
	
	IF path_cur%ISOPEN
	THEN
		FETCH path_cur BULK COLLECT INTO v_region_sids;
		CLOSE path_cur;
	END IF;

	GetRegionsBySids(
		in_region_sids		=>	v_region_sids,
		out_region_cur		=>	out_region_cur,
		out_description_cur	=>	out_description_cur
	);
END;

PROCEDURE GetRegionsBySid(
	in_region_sids			IN	security_pkg.T_SID_IDS,
	in_raise_count_errors	IN	NUMBER DEFAULT 1,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	v_region_sids			security.T_SID_TABLE;
	v_region_sids_t			security.T_SID_TABLE;
	v_allowed_region_sids	security.T_SO_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
	v_requested_count		NUMBER;
	v_allowed_count			NUMBER;
	v_trashed_count			NUMBER;
BEGIN
	v_app_sid := security_pkg.GetApp;
	v_act_id := security_pkg.GetAct;

	v_trashed_region_sids := GetTrashedRegionSids();
	v_region_sids_t := security_pkg.SidArrayToTable(in_region_sids);
	v_allowed_region_sids := securableObject_pkg.GetSIDsWithPermAsTable(v_act_id, v_region_sids_t, security_pkg.PERMISSION_READ);

	IF in_raise_count_errors = 1 THEN
		SELECT COUNT(*)
		  INTO v_requested_count
		  FROM TABLE(v_region_sids_t);

		SELECT COUNT(*)
		  INTO v_allowed_count
		  FROM region r
		  JOIN TABLE(v_allowed_region_sids) ar ON ar.sid_id = r.region_sid
		 WHERE r.app_sid = v_app_sid;

		IF v_requested_count != v_allowed_count THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on one or more requested region');
		END IF;

		SELECT COUNT(*)
		  INTO v_trashed_count
		  FROM region r
		  JOIN TABLE(v_region_sids_t) rs ON rs.column_value = r.region_sid
		 WHERE r.region_sid IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
		   AND r.app_sid = v_app_sid;

		IF v_trashed_count > 0 THEN
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_OBJECT_IN_TRASH, 'One or more of the requested regions have been deleted');
		END IF;
	END IF;

	SELECT rs.column_value region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM TABLE(v_region_sids_t) rs
	  JOIN TABLE(v_allowed_region_sids) ars ON rs.column_value = ars.sid_id
	 WHERE rs.column_value NOT IN (SELECT trs.column_value FROM TABLE(v_trashed_region_sids) trs)
	 ORDER BY region_sid;

	GetRegionsBySids(
		in_region_sids		=> v_region_sids,
		out_region_cur		=> out_region_cur,
		out_description_cur	=> out_description_cur
	);
END;

PROCEDURE GetRegionTrees(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_tree_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_tree_sids		security.T_SID_TABLE;
BEGIN

	SELECT region_tree_root_sid
	  BULK COLLECT INTO v_region_tree_sids
	  FROM (
		SELECT region_tree_root_sid, rownum rn
		  FROM (
				SELECT region_tree_root_sid
				  FROM region_tree
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take +1;

	OPEN out_total_rows_cur FOR
		SELECT COUNT(region_tree_root_sid) total_rows
		  FROM region_tree
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		  
	OPEN out_region_tree_cur FOR
		SELECT region_tree_root_sid AS region_tree_root_id, last_recalc_dtm, is_primary AS is_primary_tree, is_divisions, is_fund
		  FROM region_tree
		 WHERE region_tree_root_sid IN (SELECT column_value FROM TABLE(v_region_tree_sids));
END;

END;
/

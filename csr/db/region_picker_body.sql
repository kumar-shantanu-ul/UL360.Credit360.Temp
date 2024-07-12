CREATE OR REPLACE PACKAGE BODY CSR.Region_Picker_Pkg AS

PROCEDURE CheckSecurity(
	in_parent_sids		IN	security.T_SID_TABLE
)
AS
	v_act_id			security_pkg.T_ACT_ID;
BEGIN
	v_act_id := sys_context('security','act');
	FOR r IN (SELECT COLUMN_VALUE FROM TABLE(in_parent_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, r.column_value, security_pkg.PERMISSION_LIST_CONTENTS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
	END LOOP;
END;

PROCEDURE GetRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_region_type		IN	region.region_type%TYPE DEFAULT NULL,
	in_geo_type			IN	region.geo_type%TYPE DEFAULT NULL,
	in_is_leaf			IN	NUMBER DEFAULT NULL,
	in_level			IN	NUMBER DEFAULT NULL,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_parent_sids 		security.T_SID_TABLE;
BEGIN
	t_parent_sids := security_pkg.SidArrayToTable(in_parent_sids);

	CheckSecurity(t_parent_sids);
	
	OPEN out_cur FOR
		SELECT DISTINCT r.region_sid, r.description
		  FROM v$region r
		  JOIN (
				SELECT NVL(sub.link_to_region_sid, sub.region_sid) region_sid, CONNECT_BY_ISLEAF is_leaf, LEVEL lvl
				  FROM region sub
				 START WITH sub.region_sid in (SELECT COLUMN_VALUE FROM TABLE(t_parent_sids))
			   CONNECT BY PRIOR NVL(sub.link_to_region_sid, sub.region_sid) = parent_sid
				) rt on rt.region_sid = r.region_sid
		 WHERE (in_show_inactive = 1 OR r.active = 1)
		   AND (in_region_type IS NULL OR r.region_type = in_region_type)
		   AND (in_geo_type IS NULL OR r.geo_type = in_geo_type)
		   AND (in_is_leaf IS NULL OR rt.is_leaf = in_is_leaf)
		   AND (in_level IS NULL OR rt.lvl = in_level)
		 ORDER BY REGEXP_SUBSTR(LOWER(r.description), '^\D*'),
			   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(r.description), '[0-9]+', 1, 2))) NULLS FIRST,
			   LOWER(r.description);
END;

PROCEDURE GetRegionsByType(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_region_type		IN	region.region_type%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRegions(
		in_parent_sids		=> in_parent_sids,
		in_show_inactive	=> in_show_inactive,
		in_region_type		=> in_region_type,
		out_cur				=> out_cur);
END;

PROCEDURE GetLeafRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRegions(
		in_parent_sids		=> in_parent_sids,
		in_show_inactive	=> in_show_inactive,
		in_is_leaf			=> 1,
		out_cur				=> out_cur);
END;


PROCEDURE GetCountryRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRegions(
		in_parent_sids		=> in_parent_sids,
		in_show_inactive	=> in_show_inactive,
		in_geo_type			=> region_pkg.REGION_GEO_TYPE_COUNTRY,
		out_cur				=> out_cur);
END;

PROCEDURE GetRegionsForTags(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	in_tag_ids			IN	security_pkg.T_SID_IDS,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_parent_sids 		security.T_SID_TABLE;
	t_tag_ids			security.T_SID_TABLE;
BEGIN
	t_parent_sids := security_pkg.SidArrayToTable(in_parent_sids);
	t_tag_ids := security_pkg.SidArrayToTable(in_tag_ids);
	
	CheckSecurity(t_parent_sids);
	
	OPEN out_cur FOR
		SELECT DISTINCT r.region_sid, r.description
		  FROM v$region r
		  JOIN (
				SELECT NVL(sub.link_to_region_sid, sub.region_sid) region_sid
				  FROM region sub
				 START WITH sub.region_sid in (SELECT COLUMN_VALUE FROM TABLE(t_parent_sids))
			   CONNECT BY PRIOR NVL(sub.link_to_region_sid, sub.region_sid) = parent_sid
				) rt on rt.region_sid = r.region_sid
		 WHERE (in_show_inactive = 1 OR r.active = 1)
		   AND r.region_sid IN (SELECT region_sid FROM region_tag WHERE tag_id IN (SELECT COLUMN_VALUE FROM TABLE(t_tag_ids)))
		 ORDER BY REGEXP_SUBSTR(LOWER(r.description), '^\D*'),
			   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(r.description), '[0-9]+', 1, 2))) NULLS FIRST,
			   LOWER(r.description);
END;

PROCEDURE GetChildRegions(
	in_parent_sids		IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRegions(
		in_parent_sids		=> in_parent_sids,
		in_show_inactive	=> in_show_inactive,
		in_level			=> 2,
		out_cur				=> out_cur);
END;

PROCEDURE GetSelectedRegionDescriptions(
	in_sids				IN	security_pkg.T_SID_IDS,
	in_show_inactive	IN	region.active%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_sids 				security.T_SID_TABLE;
BEGIN
	-- Given this type it's own implementation because we just want the flat list of selected regions, plus we don't
	-- want to change the ordering in this situation.
	
	t_sids := security_pkg.SidArrayToTable(in_sids);

	CheckSecurity(t_sids);
	
	OPEN out_cur FOR
		SELECT DISTINCT r.region_sid, r.description
		  FROM v$region r
		 WHERE (in_show_inactive = 1 OR r.active = 1)
		   AND r.region_sid IN (SELECT column_value FROM TABLE(t_sids));
		 
END;

END Region_Picker_pkg;
/

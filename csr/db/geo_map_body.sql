CREATE OR REPLACE PACKAGE BODY CSR.geo_map_pkg IS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	DELETE FROM geo_map_region 
	 WHERE geo_map_sid = in_sid_id;

	DELETE FROM geo_map_tab_chart
	 WHERE geo_map_tab_id IN (
	 	SELECT geo_map_tab_id FROM geo_map_tab WHERE geo_map_sid = in_sid_id
	 );
	 
	DELETE FROM geo_map_tab
	 WHERE geo_map_sid = in_sid_id;

	DELETE FROM geo_map
	 WHERE geo_map_sid = in_sid_id;
END;

PROCEDURE GetGeoMaps(
	out_cur					OUT SYS_REFCURSOR
)
AS
	v_geo_maps_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'GeoMaps');
BEGIN
	OPEN out_cur FOR
		SELECT gm.geo_map_sid, gm.label, gm.region_selection_type_id, gm.tag_id, gm.include_inactive_regions, 
			gm.start_dtm, gm.end_dtm, gm.interval,
			CASE WHEN po.properties_geo_map_sid IS NOT NULL THEN 1 ELSE 0 END is_properties_map
		  FROM geo_map gm
		  JOIN TABLE(SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_geo_maps_sid, security_pkg.PERMISSION_READ)) so
		    ON gm.geo_map_sid = so.sid_id
		  LEFT JOIN property_options po
		    ON po.properties_geo_map_sid = gm.geo_map_sid
		 ORDER BY geo_map_sid;
END;

PROCEDURE GetRegionSelectionTypes(
	out_region_sel_type_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_sel_type_cur FOR
		SELECT region_selection_type_id, label
		  FROM region_selection_type;
END;

PROCEDURE GetGeoMapTabTypes(
	out_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT geo_map_tab_type_id, label, js_class, map_builder_js_class, map_builder_cs_class
		  FROM geo_map_tab_type
		 WHERE geo_map_tab_type_id IN (SELECT geo_map_tab_type_id FROM customer_geo_map_tab_type WHERE app_sid = SYS_CONTEXT('SECURITY','APP'));
END;

-- get the basics for editing
PROCEDURE GetGeoMap(
	in_geo_map_sid 			IN  security_pkg.T_SID_ID, 
	out_cur 				OUT SYS_REFCURSOR,
	out_regions_cur 		OUT SYS_REFCURSOR,
	out_tab_property_cur	OUT SYS_REFCURSOR,
	out_tab_chart_cur		OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading geo map sid '||in_geo_map_sid);
	END IF;

	OPEN out_cur FOR
		SELECT gm.geo_map_sid, gm.label, gm.region_selection_type_id, gm.tag_id, gm.include_inactive_regions, 
			   gm.start_dtm, gm.end_dtm, gm.interval,
			   CASE WHEN po.properties_geo_map_sid IS NOT NULL THEN 1 ELSE 0 END is_properties_map
		  FROM geo_map gm
		  LEFT JOIN property_options po ON po.properties_geo_map_sid = gm.geo_map_sid
		 WHERE gm.geo_map_sid = in_geo_map_sid;
		 
	OPEN out_regions_cur FOR
		SELECT gmr.region_sid, r.description
		  FROM geo_map_region gmr
		  JOIN v$region r on r.app_sid = gmr.app_sid AND r.region_sid = gmr.region_sid		  
		 WHERE geo_map_sid = in_geo_map_sid;
		 
	OPEN out_tab_property_cur FOR
		SELECT gmt.geo_map_tab_id, gmt.geo_map_sid, gmt.label, gmt.geo_map_tab_type_id, gmt.pos
		  FROM geo_map_tab gmt
		 WHERE gmt.geo_map_sid = in_geo_map_sid
		   AND gmt.geo_map_tab_type_id = 1; -- property details
		 
	OPEN out_tab_chart_cur FOR
		SELECT gmt.geo_map_tab_id, gmt.geo_map_sid, gmt.label, gmt.geo_map_tab_type_id, gmt.pos, 
			   gmtc.chart_height, gmtc.chart_width, dv.dataview_sid, dv.name dataview_name
		  FROM geo_map_tab_chart gmtc
		  JOIN geo_map_tab gmt ON gmt.app_sid = gmtc.app_sid AND gmt.geo_map_tab_id = gmtc.geo_map_tab_id
		  JOIN dataview dv ON dv.app_sid = gmtc.app_sid AND dv.dataview_sid = gmtc.dataview_sid		   	
		 WHERE gmt.geo_map_sid = in_geo_map_sid; 
END;

-- compatibility alias
PROCEDURE CreateGeoMap(	
    in_label                    	IN  geo_map.label%TYPE,
    in_geo_tileset_id              	IN  security_pkg.T_SID_ID,
    in_region_selection_type_id   	IN  geo_map.region_selection_type_id%TYPE,
    in_tag_id                		IN  geo_map.tag_id%TYPE,
    in_include_inactive_regions    	IN  geo_map.include_inactive_regions%TYPE,
    in_start_dtm                   	IN  geo_map.start_dtm%TYPE,
    in_end_dtm                     	IN  geo_map.end_dtm%TYPE,
    in_interval                    	IN  geo_map.interval%TYPE,
	in_parent_sid 					IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_geo_map_sid					OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CreateGeoMap(in_label, in_region_selection_type_id, in_tag_id, in_include_inactive_regions,
				 in_start_dtm, in_end_dtm, in_interval, in_parent_sid, out_geo_map_sid);
END;

PROCEDURE CreateGeoMap(	
    in_label                    	IN  geo_map.label%TYPE,
    in_region_selection_type_id   	IN  geo_map.region_selection_type_id%TYPE,
    in_tag_id                		IN  geo_map.tag_id%TYPE,
    in_include_inactive_regions    	IN  geo_map.include_inactive_regions%TYPE,
    in_start_dtm                   	IN  geo_map.start_dtm%TYPE,
    in_end_dtm                     	IN  geo_map.end_dtm%TYPE,
    in_interval                    	IN  geo_map.interval%TYPE,
	in_parent_sid 					IN  security_pkg.T_SID_ID DEFAULT NULL,
	out_geo_map_sid					OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid  	security_pkg.T_SID_ID;
BEGIN	
	v_parent_sid := COALESCE(in_parent_sid, securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'GeoMaps'));

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_parent_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating a new geo map');
	END IF;
	
	-- Create the securable object
	SecurableObject_Pkg.CreateSO(
		SYS_CONTEXT('SECURITY','ACT'),
		v_parent_sid,
		class_pkg.getClassID('GeoMap'),
		NULL, -- Create with null name the use UniqueSORename to ensure unique
		out_geo_map_sid
	);

	INSERT INTO geo_map (geo_map_sid, label, region_selection_type_id, tag_id, include_inactive_regions, start_dtm, end_dtm, interval)
		VALUES (out_geo_map_sid, in_label, in_region_selection_type_id, in_tag_id, in_include_inactive_regions, in_start_dtm, in_end_dtm, in_interval);		
END;

-- compatibility alias
PROCEDURE AmendGeoMap(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_label                    	IN  geo_map.label%TYPE,
    in_geo_tileset_id              	IN  security_pkg.T_SID_ID,
    in_region_selection_type_id   	IN  geo_map.region_selection_type_id%TYPE,
    in_tag_id                		IN  geo_map.tag_id%TYPE,
    in_include_inactive_regions    	IN  geo_map.include_inactive_regions%TYPE,
    in_start_dtm                   	IN  geo_map.start_dtm%TYPE,
    in_end_dtm                     	IN  geo_map.end_dtm%TYPE,
    in_interval                    	IN  geo_map.interval%TYPE
)
AS
BEGIN
	AmendGeoMap(in_geo_map_sid, in_label, in_region_selection_type_id, in_tag_id,
				in_include_inactive_regions, in_start_dtm, in_end_dtm, in_interval);
END;

PROCEDURE AmendGeoMap(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_label                    	IN  geo_map.label%TYPE,
    in_region_selection_type_id   	IN  geo_map.region_selection_type_id%TYPE,
    in_tag_id                		IN  geo_map.tag_id%TYPE,
    in_include_inactive_regions    	IN  geo_map.include_inactive_regions%TYPE,
    in_start_dtm                   	IN  geo_map.start_dtm%TYPE,
    in_end_dtm                     	IN  geo_map.end_dtm%TYPE,
    in_interval                    	IN  geo_map.interval%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to geo map sid'||in_geo_map_sid);
	END IF;

	UPDATE geo_map
	   SET geo_map_sid = in_geo_map_sid,
		label = in_label,
		region_selection_type_id = in_region_selection_type_id,
		tag_id = in_tag_id,
		include_inactive_regions = in_include_inactive_regions,
		start_dtm =  in_start_dtm,
		end_dtm = in_end_dtm,
		interval = in_interval
	 WHERE geo_map_sid = in_geo_map_sid;
END;

PROCEDURE SetGeoMapRegions(
	in_geo_map_sid 		IN  security_pkg.T_SID_ID, 
	in_region_sids		IN	security_pkg.T_SID_IDS
)
AS
	t 					security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to geo map sid'||in_geo_map_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_region_sids);
		
	DELETE FROM geo_map_region 
	 WHERE geo_map_sid = in_geo_map_sid;
	
	FOR r IN (SELECT column_value region_sid FROM TABLE(t))
	LOOP	
		INSERT INTO geo_map_region(geo_map_sid, region_sid)
		VALUES (in_geo_map_sid, r.region_sid);
	END LOOP;
END;

PROCEDURE DeleteGeoMapTabs(
	in_geo_map_sid 		IN  security_pkg.T_SID_ID 
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to geo map sid'||in_geo_map_sid);
	END IF;

	DELETE FROM geo_map_tab_chart
	 WHERE geo_map_tab_id IN (SELECT geo_map_tab_id FROM geo_map_tab WHERE geo_map_sid = in_geo_map_sid);
	
	DELETE FROM geo_map_tab 
	 WHERE geo_map_sid = in_geo_map_sid;
END;

PROCEDURE CreateGeoMapTab(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_label						IN  geo_map_tab.label%type,
	in_geo_map_tab_type_id			IN  geo_map_tab.geo_map_tab_type_id%type,	
	in_pos							IN  geo_map_tab.pos%type,
	out_geo_map_tab_id				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to geo map sid'||in_geo_map_sid);
	END IF;

	INSERT INTO geo_map_tab(geo_map_tab_id, geo_map_sid, label, geo_map_tab_type_id, pos)
		VALUES(geo_map_tab_id_seq.nextval, in_geo_map_sid, in_label, in_geo_map_tab_type_id, in_pos)
		RETURNING geo_map_tab_id INTO out_geo_map_tab_id;
END;

PROCEDURE CreateGeoMapChartTab(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_geo_map_tab_id				IN security_pkg.T_SID_ID,
	in_dataview_sid					IN security_pkg.T_SID_ID,
	in_chart_height					IN	geo_map_tab_chart.chart_height%TYPE DEFAULT NULL,
	in_chart_width					IN	geo_map_tab_chart.chart_width%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_geo_map_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write to geo map sid'||in_geo_map_sid);
	END IF;

	INSERT INTO geo_map_tab_chart(geo_map_tab_id, dataview_sid, chart_height, chart_width)
		VALUES(in_geo_map_tab_id, in_dataview_sid, in_chart_height, in_chart_width);
END;

PROCEDURE GetRegionGeoData(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_colour_by		IN  VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_regions_table			security.T_SID_TABLE;
	v_colour_by_table		T_SID_AND_DESCRIPTION_TABLE;
BEGIN
	v_regions_table := security_pkg.SidArrayToTable(in_region_sids);
	
	IF in_colour_by = 'complianceRag' THEN
		SELECT T_SID_AND_DESCRIPTION_ROW(1, region_sid, pct_compliant_colour)
		  BULK COLLECT INTO v_colour_by_table
		  FROM v$compliance_item_rag;
	ELSIF in_colour_by = 'permitRag' THEN
		SELECT T_SID_AND_DESCRIPTION_ROW(1, region_sid, pct_compliant_colour)
		  BULK COLLECT INTO v_colour_by_table
		  FROM v$permit_item_rag;	
	ELSE 
		NULL;
	END IF;
		
	OPEN out_cur FOR
		SELECT r.region_sid, r.description, r.geo_longitude, r.geo_latitude, cb.description rgb_hex
		FROM v$region r
		JOIN TABLE(v_regions_table) ON r.region_sid = column_value
		LEFT JOIN TABLE(v_colour_by_table) cb ON cb.sid_id = column_value;
END;
	
END;
/

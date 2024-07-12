CREATE OR REPLACE PACKAGE CSR.geo_map_pkg IS

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE GetGeoMaps(
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetRegionSelectionTypes(
	out_region_sel_type_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetGeoMapTabTypes(
	out_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetGeoMap(
	in_geo_map_sid 			IN  security_pkg.T_SID_ID, 
	out_cur 				OUT SYS_REFCURSOR,
	out_regions_cur 		OUT SYS_REFCURSOR,
	out_tab_property_cur	OUT SYS_REFCURSOR,
	out_tab_chart_cur		OUT SYS_REFCURSOR
);

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
);

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
);

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
);

PROCEDURE AmendGeoMap(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_label                    	IN  geo_map.label%TYPE,
    in_region_selection_type_id   	IN  geo_map.region_selection_type_id%TYPE,
    in_tag_id                		IN  geo_map.tag_id%TYPE,
    in_include_inactive_regions    	IN  geo_map.include_inactive_regions%TYPE,
    in_start_dtm                   	IN  geo_map.start_dtm%TYPE,
    in_end_dtm                     	IN  geo_map.end_dtm%TYPE,
    in_interval                    	IN  geo_map.interval%TYPE
);

PROCEDURE SetGeoMapRegions(
	in_geo_map_sid 		IN  security_pkg.T_SID_ID, 
	in_region_sids		IN	security_pkg.T_SID_IDS
);

PROCEDURE DeleteGeoMapTabs(
	in_geo_map_sid 		IN  security_pkg.T_SID_ID 
);

PROCEDURE CreateGeoMapTab(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_label						IN  geo_map_tab.label%type,
	in_geo_map_tab_type_id			IN  geo_map_tab.geo_map_tab_type_id%type,	
	in_pos							IN  geo_map_tab.pos%type,
	out_geo_map_tab_id				OUT security_pkg.T_SID_ID
);

PROCEDURE CreateGeoMapChartTab(
	in_geo_map_sid 					IN  security_pkg.T_SID_ID,
	in_geo_map_tab_id				IN	security_pkg.T_SID_ID,
	in_dataview_sid					IN	security_pkg.T_SID_ID,
	in_chart_height					IN	geo_map_tab_chart.chart_height%TYPE DEFAULT NULL,
	in_chart_width					IN	geo_map_tab_chart.chart_width%TYPE DEFAULT NULL
);

PROCEDURE GetRegionGeoData(
	in_region_sids	IN	security_pkg.T_SID_IDS,
	in_colour_by	IN  VARCHAR2,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

END;
/

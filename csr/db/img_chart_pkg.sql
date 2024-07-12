CREATE OR REPLACE PACKAGE CSR.Img_Chart_Pkg AS
-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
); 
	  
/*PROCEDURE CreateImgChartFromCache(
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	in_label			IN	img_chart.label%TYPE,
	out_img_chart_sid	OUT	security_pkg.T_SID_ID
);*/

PROCEDURE GetImgCharts(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetImgChartUpload(
	in_img_chart_sid 	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetImageChart(
	in_img_chart_sid	IN	security_pkg.T_SID_ID,
	in_label			IN	csr.img_chart.label%TYPE,
	in_scenario_run_sid	IN	csr.img_chart.scenario_run_sid%TYPE,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_img_chart_sid	OUT	security_pkg.T_SID_ID
);

PROCEDURE GetImgChart(
	in_img_chart_sid 	IN	security_pkg.T_SID_ID,
	out_img_chart_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_region_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearImgChartFields (
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
);

PROCEDURE ClearImgChartInds(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
);

PROCEDURE SetImgChartInd(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID,
	in_description			IN  img_chart_ind.description%TYPE,
	in_ind_sid				IN  img_chart_ind.ind_sid%TYPE,
	in_background_color		IN  img_chart_ind.background_color%TYPE,
	in_border_color			IN  img_chart_ind.border_color%TYPE,
	in_x					IN  img_chart_ind.x%TYPE,
	in_y					IN  img_chart_ind.y%TYPE
);

PROCEDURE ClearImgChartRegions(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
);

PROCEDURE SetImgChartRegion(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID,
	in_description			IN  img_chart_region.description%TYPE,
	in_region_sid			IN  img_chart_region.region_sid%TYPE,
	in_background_color		IN  img_chart_region.background_color%TYPE,
	in_border_color			IN  img_chart_region.border_color%TYPE,
	in_x					IN  img_chart_region.x%TYPE,
	in_y					IN  img_chart_region.y%TYPE
);

PROCEDURE UNSEC_GetForExport(
	in_img_chart_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_ind_cur				OUT	SYS_REFCURSOR
);

-- Used by the json importer in CreateSite
PROCEDURE CreateImageChart(
	in_label			IN	csr.img_chart.label%TYPE,
	in_scenario_run_sid	IN	csr.img_chart.scenario_run_sid%TYPE,
	in_mime_type		IN	csr.img_chart.mime_type%TYPE,
	in_img_data			IN	BLOB,
	out_img_chart_sid	OUT	security_pkg.T_SID_ID
);

END Img_Chart_Pkg ;
/

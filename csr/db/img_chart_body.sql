CREATE OR REPLACE PACKAGE BODY CSR.Img_Chart_Pkg AS

-- Securable object callbacks
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
) AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) AS 
BEGIN
	DELETE FROM img_chart_ind
	 WHERE img_chart_sid = in_sid_id;
	
	DELETE FROM img_chart_region
	 WHERE img_chart_sid = in_sid_id;

	DELETE FROM img_chart
	 WHERE img_chart_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS
BEGIN
	UPDATE img_chart
	   SET parent_sid = in_new_parent_sid_id
	 WHERE img_chart_sid = in_sid_id; 
END;

PROCEDURE GetImgCharts(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dataviews_sid	security_pkg.T_SID_ID;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid , security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied listing contents on the container with sid '||v_dataviews_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT ic.img_chart_sid, ic.label,
			   CASE WHEN ic.scenario_run_type < 2 THEN ic.scenario_run_type ELSE ic.scenario_run_sid END scenario_run_sid,
			   CASE ic.scenario_run_type WHEN 0 THEN 'Merged' WHEN 1 THEN 'Unmerged' ELSE sr.description END scenario_run_description,
			   NVL(ici.item_count, 0) + NVL(icr.item_count, 0) item_count
		  FROM img_chart ic
		  LEFT JOIN (SELECT ic.img_chart_sid, COUNT(*) item_count
					   FROM img_chart ic
					   JOIN img_chart_ind ici ON ic.img_chart_sid = ici.img_chart_sid AND ic.app_sid = ici.app_sid
					  WHERE parent_sid = in_parent_sid
					  GROUP BY ic.img_chart_sid) ici
		    ON ic.img_chart_sid = ici.img_chart_sid
		  LEFT JOIN (SELECT ic.img_chart_sid, COUNT(*) item_count
					   FROM img_chart ic
					   JOIN img_chart_region icr ON ic.img_chart_sid = icr.img_chart_sid AND ic.app_sid = icr.app_sid
					  WHERE parent_sid = in_parent_sid
					  GROUP BY ic.img_chart_sid) icr
		    ON ic.img_chart_sid = icr.img_chart_sid
		  LEFT JOIN scenario_run sr ON sr.scenario_run_sid = ic.scenario_run_sid AND sr.app_sid = ic.app_sid
		 WHERE parent_sid = in_parent_sid
		 ORDER BY ic.label;
END;

PROCEDURE GetImgChartUpload(
	in_img_chart_sid 	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id		security_pkg.T_ACT_ID;
BEGIN
	v_act_id := SYS_CONTEXT('security','act');
	
	-- check permission on file	   	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_img_chart_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
		SELECT img_chart_sid, mime_type, last_modified_dtm, data 
		  FROM img_chart
		 WHERE img_chart_sid = in_img_chart_sid; 	   			
END;

PROCEDURE SetImageChart(
	in_img_chart_sid	IN	security_pkg.T_SID_ID,
	in_label			IN	csr.img_chart.label%TYPE,
	in_scenario_run_sid	IN	csr.img_chart.scenario_run_sid%TYPE,
	in_cache_key		IN	aspen2.filecache.cache_key%TYPE,
	out_img_chart_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_act_id		security_pkg.T_ACT_ID;
	v_app_sid		security_pkg.T_SID_ID;
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	v_act_id := SYS_CONTEXT('security','act');
	v_app_sid := SYS_CONTEXT('security','app');
	out_img_chart_sid := in_img_chart_sid;
	-- we have cache key and sid, so just update background image data
	IF in_cache_key IS NOT NULL AND in_img_chart_sid IS NOT NULL THEN
		-- check permission
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_img_chart_sid, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
		
		--RAISE_APPLICATION_ERROR(-20001, ' cahcekye='||in_cache_Key||' / '||in_img_chart_sid);
		UPDATE img_chart 
		   SET (mime_type, data, sha1, last_modified_dtm) = (
				SELECT mime_type, object, dbms_crypto.hash(object, dbms_crypto.hash_sh1), SYSDATE
				  FROM aspen2.filecache 
				 WHERE cache_key = in_cache_key)
		 WHERE img_chart_sid = in_img_chart_sid;
		
		IF SQL%ROWCOUNT = 0 THEN
			-- pah! not found
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
		END IF; 
		
		out_img_chart_sid := in_img_chart_sid;
		
	-- or we have only cache key, not sid, so create new image object
	ELSIF in_cache_key IS NOT NULL AND in_img_chart_sid IS NULL THEN 
		-- TODO: Check security on dataviews
		v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id , v_app_sid, 'Dataviews');
		
		SecurableObject_pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.GetClassID('CSRImgChart'),
			REPLACE(in_label,'/','\'), out_img_chart_sid	); --'
			
		INSERT INTO img_chart
			(img_chart_sid, parent_sid, label, mime_type, data, sha1)
			SELECT out_img_chart_sid, v_parent_sid, in_label, mime_type, object, 
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key;
		
		IF SQL%ROWCOUNT = 0 THEN
			-- pah! not found
			RAISE_APPLICATION_ERROR(-20001, 'Cache Key "'||in_cache_key||'" not found');
		END IF;
	END IF;

	UPDATE img_chart
	   SET label = in_label,
		   scenario_run_type = LEAST(2, in_scenario_run_sid),
		   scenario_run_sid = CASE WHEN in_scenario_run_sid < 2 THEN NULL ELSE in_scenario_run_sid END
	 WHERE img_chart_sid = out_img_chart_sid;
END;

PROCEDURE GetImgChart(
	in_img_chart_sid 	IN	security_pkg.T_SID_ID,
	out_img_chart_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_region_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_img_chart_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	OPEN out_img_chart_cur FOR
		SELECT ic.label,
			   CASE WHEN ic.scenario_run_type < 2 THEN ic.scenario_run_type ELSE ic.scenario_run_sid END scenario_run_sid,
			   CASE ic.scenario_run_type WHEN 0 THEN 'Merged data' WHEN 1 THEN 'Unmerged data' ELSE sr.description END scenario_run_description
		  FROM img_chart ic
		  LEFT JOIN scenario_run sr ON sr.scenario_run_sid = ic.scenario_run_sid
		 WHERE ic.img_chart_sid = in_img_chart_sid;
	
	OPEN out_ind_cur FOR
		SELECT ici.img_chart_sid, ici.ind_sid, NVL(ici.description, i.description) description, i.description csr_ind_description, ici.measure_conversion_id, ici.x, ici.y, ici.background_color, ici.border_color
		  FROM img_chart_ind ici, v$ind i
		 WHERE i.ind_sid = ici.ind_sid
		   AND img_chart_sid = in_img_chart_sid;
	
	OPEN out_region_cur FOR
		SELECT icr.img_chart_sid, icr.region_sid, NVL(icr.description, r.description) description, r.description csr_region_description, icr.x, icr.y, icr.background_color, icr.border_color
		  FROM img_chart_region icr, v$region r
		 WHERE r.region_sid = icr.region_sid
		   AND img_chart_sid = in_img_chart_sid;
END;

PROCEDURE ClearImgChartFields (
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ClearImgChartInds(in_img_chart_sid);
	ClearImgChartRegions(in_img_chart_sid);
END;

PROCEDURE ClearImgChartInds(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_img_chart_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	DELETE FROM img_chart_ind
	  WHERE img_chart_sid = in_img_chart_sid;
END;

PROCEDURE SetImgChartInd(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID,
	in_description			IN  img_chart_ind.description%TYPE,
	in_ind_sid				IN  img_chart_ind.ind_sid%TYPE,
	in_background_color		IN  img_chart_ind.background_color%TYPE,
	in_border_color			IN  img_chart_ind.border_color%TYPE,
	in_x					IN  img_chart_ind.x%TYPE,
	in_y					IN  img_chart_ind.y%TYPE
)
AS
BEGIN
	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_img_chart_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	INSERT INTO img_chart_ind
		(img_chart_sid, ind_sid, description, x, y, background_color, border_color, measure_conversion_id)
	VALUES
		(in_img_chart_sid, in_ind_sid, in_description, in_x, in_y, in_background_color, in_border_color, null);
END;

PROCEDURE ClearImgChartRegions(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_img_chart_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	DELETE FROM img_chart_region
	  WHERE img_chart_sid = in_img_chart_sid;
END;

PROCEDURE SetImgChartRegion(
	in_img_chart_sid 		IN	security_pkg.T_SID_ID,
	in_description			IN  img_chart_region.description%TYPE,
	in_region_sid			IN  img_chart_region.region_sid%TYPE,
	in_background_color		IN  img_chart_region.background_color%TYPE,
	in_border_color			IN  img_chart_region.border_color%TYPE,
	in_x					IN  img_chart_region.x%TYPE,
	in_y					IN  img_chart_region.y%TYPE
)
AS
BEGIN
	-- check permission
	IF NOT security_pkg.IsAccessAllowedSID(sys_context('security','act'), in_img_chart_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	INSERT INTO img_chart_region
		(img_chart_sid, region_sid, description, x, y, background_color, border_color)
	VALUES
		(in_img_chart_sid, in_region_sid, in_description, in_x, in_y, in_background_color, in_border_color);
END;

PROCEDURE UNSEC_GetForExport(
	in_img_chart_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_ind_cur				OUT	SYS_REFCURSOR
)
AS
	v_region_count			NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_region_count
	  FROM img_chart_region
	 WHERE img_chart_sid = in_img_chart_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	OPEN out_cur FOR
		SELECT img_chart_sid, label, mime_type, data, scenario_run_sid, scenario_run_type, v_region_count region_count
		  FROM img_chart
		 WHERE img_chart_sid = in_img_chart_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_ind_cur FOR
		SELECT ind_sid, description, measure_conversion_id, x, y, background_color, border_color, font_size
		  FROM img_chart_ind
		 WHERE img_chart_sid = in_img_chart_sid
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE CreateImageChart(
	in_label			IN	csr.img_chart.label%TYPE,
	in_scenario_run_sid	IN	csr.img_chart.scenario_run_sid%TYPE,
	in_mime_type		IN	csr.img_chart.mime_type%TYPE,
	in_img_data			IN	BLOB,
	out_img_chart_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_act_id		security_pkg.T_ACT_ID;
	v_app_sid		security_pkg.T_SID_ID;
	v_parent_sid	security_pkg.T_SID_ID;
	v_sha			csr.img_chart.sha1%TYPE;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id , v_app_sid, 'Dataviews');
	
	SecurableObject_pkg.CreateSO(v_act_id, v_parent_sid, class_pkg.GetClassID('CSRImgChart'),
			REPLACE(in_label,'/','\'), out_img_chart_sid	); --'
	
	v_sha := dbms_crypto.hash(in_img_data, dbms_crypto.hash_sh1);
	
	INSERT INTO img_chart
		(img_chart_sid, parent_sid, label, mime_type, data, sha1)
	VALUES
		(out_img_chart_sid, v_parent_sid, in_label, in_mime_type, in_img_data, 
		 v_sha);

END;

END Img_Chart_Pkg;
/

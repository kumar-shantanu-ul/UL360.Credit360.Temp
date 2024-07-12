CREATE OR REPLACE PACKAGE BODY CSR.snapshot_Pkg AS

TYPE t_ddl IS TABLE OF CLOB;
	
PROCEDURE RegisterSnapshot(
	in_name							IN	snapshot.name%TYPE,
	in_title						IN	snapshot.title%TYPE,
	in_description					IN	snapshot.description%TYPE,
	in_tag_group_Ids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	snapshot.start_dtm%TYPE,
	in_end_dtm						IN	snapshot.end_dtm%TYPE,
	in_period_set_id				IN	snapshot.period_set_id%TYPE,
	in_period_interval_id			IN	snapshot.period_interval_id%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_refresh_xml					IN	snapshot.refresh_xml%TYPE,
	in_use_unmerged					IN	snapshot.use_unmerged%TYPE,
	in_is_supplier					IN	snapshot.is_supplier%TYPE
)
AS
BEGIN
	-- check for write permissions on the app as this is pretty serious
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetApp, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app sid '||security_pkg.GetApp);
	END IF;

	INSERT INTO snapshot (
		name, app_sid, title, description,
		start_dtm, end_dtm, 
		period_set_id, period_interval_id, refresh_xml,
		next_update_after_dtm,
		use_unmerged, is_supplier
	) VALUES (
		UPPER(in_name), security_pkg.GetApp, in_title, in_description,
		in_start_dtm, in_end_dtm,
		in_period_set_id, in_period_interval_id, in_refresh_xml,
		SYSDATE,
		in_use_unmerged, in_is_supplier
	);
		
		
	IF in_ind_sids.COUNT = 0 OR (in_ind_sids.COUNT = 1 AND in_ind_sids(1) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just do nothing
		NULL;
	ELSE
		FORALL i IN INDICES OF in_ind_sids
			INSERT INTO snapshot_ind (name, ind_sid) VALUES (UPPER(in_name), in_ind_sids(i));
    END IF;
    
	IF in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(1) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just do nothing
		NULL;
	ELSE
		FORALL i IN INDICES OF in_region_sids
			INSERT INTO snapshot_region (name, region_sid, all_descendents) VALUES (UPPER(in_name), in_region_sids(i), 1);
    END IF;
    
	IF in_tag_group_ids.COUNT = 0 OR (in_tag_group_ids.COUNT = 1 AND in_tag_group_Ids(1) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just do nothing
		NULL;
	ELSE
		FORALL i IN INDICES OF in_tag_group_ids
			INSERT INTO snapshot_tag_group (name, tag_group_id) VALUES (UPPER(in_name), in_tag_group_ids(i));
    END IF;
    
    IF in_is_supplier = 1 THEN
		INSERT INTO snapshot_tag_group (name, tag_group_id)
		SELECT UPPER(in_name), tg.tag_group_id
		  FROM tag_group tg
		 WHERE tg.applies_to_suppliers = 1;
    END IF;
END;

PROCEDURE DropAllSnapshots
AS
	v_name_in_use					NUMBER;
BEGIN
	-- check for write permissions on the app as this is pretty serious
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetApp, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app sid '||security_pkg.GetApp);
	END IF;
	
	FOR r IN (SELECT name
				FROM snapshot
			   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) LOOP
		DropSnapshot(r.name, v_name_in_use);
	END LOOP;
END;

PROCEDURE DropSnapshot(
	in_name							IN	snapshot.name%TYPE,
	out_name_in_use					OUT	NUMBER
)
AS
	v_cnt 		NUMBER(10);
	v_app_sid 	security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	out_name_in_use := 0;

	-- check for write permissions on the app as this is pretty serious
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetApp, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app sid '||security_pkg.GetApp);
	END IF;
	
	-- check app_sid and table name match
	security.security_pkg.setApp(NULL);
	BEGIN
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM snapshot
		 WHERE app_sid != v_app_sid
		   AND name = UPPER(in_name);
	EXCEPTION
		WHEN OTHERS THEN
			security.security_pkg.setApp(v_app_sid);
			RAISE;
	END;
	security.security_pkg.setApp(v_app_sid);
	   
	IF v_cnt != 0 THEN
		out_name_in_use := 1;
		RETURN;
	END IF;

	-- drop view
	SELECT COUNT(*) INTO v_cnt FROM all_views WHERE owner='CSR' AND view_name = 'V$SS_'||UPPER(in_name);
	IF v_cnt > 0 THEN
		EXECUTE IMMEDIATE 'DROP VIEW CSR.V$SS_'||UPPER(in_name);
	END IF;
	
	-- drop main table
	SELECT COUNT(*) INTO v_cnt FROM all_tables WHERE owner='CSR' AND table_name = 'SS_'||UPPER(in_name);
	IF v_cnt > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.SS_'||UPPER(in_name);
	END IF;

	-- drop period
	SELECT COUNT(*) INTO v_cnt FROM all_tables WHERE owner='CSR' AND table_name = 'SS_'||UPPER(in_name)||'_PERIOD';
	IF v_cnt > 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE CSR.SS_'||UPPER(in_name)||'_PERIOD';
	END IF;
	
	DELETE FROM snapshot_region WHERE name = UPPER(in_name);
	DELETE FROM snapshot_ind WHERE name = UPPER(in_name);
	DELETE FROM snapshot_tag_group WHERE name = UPPER(in_name);
	DELETE FROM snapshot WHERE name = UPPER(in_name);
END;

PROCEDURE GetData(
	in_name							IN	snapshot.name%TYPE,
	in_tag_ids						IN	security_pkg.T_SID_IDS,
	in_period_id					IN	NUMBER,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_max_row						IN	NUMBER,
	in_asc							IN	NUMBER,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	in_include_nulls    			IN  NUMBER,
	in_include_inactive_regions		IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR,
	out_sum_cur						OUT SYS_REFCURSOR
)
AS
    v_s  							CLOB;
	v_cnt 							NUMBER(10);
	v_sort_order					VARCHAR2(64);
	v_root_region_sids				security.T_SID_TABLE;
BEGIN
	-- check this dataview actually exists (avoids SQL injection)
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM snapshot
	 WHERE app_sid = security_pkg.GetApp
	   AND name = UPPER(in_name);
	
	IF v_cnt = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Table not found');
	END IF;

	-- check for read permissions on the ind sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading ind sid '||in_ind_sid);
	END IF;
	
	IF in_root_region_sid IS NULL THEN
		-- figure out default for this user/app - we assume we've got permission on this!
		SELECT region_sid
		  BULK COLLECT INTO v_root_region_sids
		  FROM region_start_point
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');
	ELSE
		-- check for read permissions on the region sid that was passed to us
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_root_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||in_root_region_sid);
		END IF;
		v_root_region_sids := security.T_SID_TABLE();
		v_root_region_sids.extend;
		v_root_region_sids(v_root_region_sids.count) := in_root_region_sid;
	END IF;

	IF in_asc = 1 THEN
		v_sort_order := 'asc nulls first';
	ELSE
		v_sort_order := 'desc nulls last';
	END IF;
	
	/* We should try and optimise this, i.e. we could do the region filter (the hierarchical query bit)
	   and the period filter as separate 'inline views', i.e. using WITH foo AS.
	   
	   This way we can still pass the region_Sid + period_id as a single value but use these queries
	   N times if multiple categories are used
	 */
	
	v_s :=	'    SELECT x.*, rownum rn '||chr(10)||
			'      FROM ( '||chr(10);
			  
	IF in_tag_ids.COUNT = 0 OR (in_tag_ids.COUNT = 1 AND in_tag_ids(in_tag_ids.FIRST) IS NULL) THEN
		-- no tags
		    utils_pkg.WriteAppend(v_s, 
	    '       SELECT r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, geo_latitude, r.description, r.active, p.label period_label, v.*,'||chr(10)||
	    '              CASE WHEN r.geo_type=6 AND region_type=3 THEN 0 ELSE r.geo_type END geo_type '||chr(10)||
	    '         FROM ss_'||in_name||' v '||chr(10)||
	    '           JOIN v$region r ON v.region_sid = r.region_sid '||chr(10)||
	    '           JOIN ss_'||in_name||'_period p ON v.period_id = p.period_id '||chr(10)
	        );
	ELSE
		-- loop through a bunch of tags
		utils_pkg.WriteAppend(v_s, 
	    '       SELECT * FROM ('||chr(10));
	    FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST
	    LOOP
	        utils_pkg.WriteAppend(v_s, 
	    '           SELECT r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, geo_latitude, r.description, r.active, p.label period_label, v.*,'||chr(10)||
	    '              CASE WHEN r.geo_type=6 AND region_type=3 THEN 0 ELSE r.geo_type END geo_type '||chr(10)||
	    '             FROM ss_'||in_name||' v '||chr(10)||
	    '               JOIN v$region r ON v.region_sid = r.region_sid '||chr(10)||
	    '               JOIN region_tag rt ON r.region_sid = rt.region_sid '||chr(10)||
	    '               JOIN ss_'||in_name||'_period p ON v.period_id = p.period_id '||chr(10)||
	    '            WHERE tag_id = '|| in_tag_ids(i) ||' '||chr(10)
	        );
	        IF i != in_tag_ids.LAST THEN
	            utils_pkg.WriteAppend(v_s, 'INTERSECT '||chr(10));
	        END IF;
	    END LOOP;
		utils_pkg.WriteAppend(v_s, 
	    '       )v '||chr(10));
	END IF;
	
	utils_pkg.WriteAppend(v_s,
	    '     WHERE v.period_id = :in_period_id'||chr(10)||
	    '       AND v.region_sid IN ('||chr(10)||
	    '          SELECT NVL(link_to_region_sid, region_sid) '||chr(10)||
	    '            FROM region '||chr(10)||
	    '           START WITH parent_sid IN (SELECT column_value FROM TABLE(:v_root_region_sids)) '||chr(10)||
		'         CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid '||chr(10)||
		'       )'||chr(10)
	);
	
	IF in_include_nulls = 0 THEN
        utils_pkg.WriteAppend(v_s, 
        '       AND i$'||in_ind_sid||' is not null '||chr(10)
      	);
	END IF;
	IF in_include_inactive_regions = 0 THEN
        utils_pkg.WriteAppend(v_s, 
        '       AND active = 1 '||chr(10)
      	);
	END IF;
	
	utils_pkg.WriteAppend(v_s, 
		'     ORDER by i$'||in_ind_sid||' '||v_sort_order||chr(10)||
	    '   )x '||chr(10)
	);

	--security_pkg.debugmsg(to_char(v_s));
	OPEN out_cur FOR
		'SELECT * FROM ('||TO_CHAR(v_s)||')WHERE rn BETWEEN 1 AND :in_max_row' USING in_period_id, v_root_region_sids, in_max_row;
	
	OPEN out_sum_cur FOR
		'SELECT count(*) "count",
			cast(sum(i$'||in_ind_sid||') as number(24,10)) "sum", 
			cast(avg(i$'||in_ind_sid||') as number(24,10)) "avg", 
			max(i$'||in_ind_sid||') "max", min(i$'||in_ind_sid||') "min", 
			cast(median(i$'||in_ind_sid||') as number(24,10)) "median" FROM ('||TO_CHAR(v_s)||')' USING in_period_id, v_root_region_sids;
END;


PROCEDURE GetSnapshotForRefresh(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_regions		OUT SYS_REFCURSOR
)
AS
BEGIN
	-- check for write permissions on the app as this is pretty serious
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetApp, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app sid '||security_pkg.GetApp);
	END IF;
	
	-- check app_sid and table name match
	UPDATE snapshot 
 	   SET snapshot_dtm = SYSDATE
 	 WHERE app_sid = security_pkg.GetApp
 	   AND name = UPPER(in_name);
 	      
	IF SQL%ROWCOUNT = 0 THEN
		-- nothing to do
		OPEN out_cur_snapshot FOR
			SELECT null snapshot_dtm, null name, null title, null start_dtm, null end_dtm, 
				   null period_set_id, null period_interval_id, null use_unmerged
			  FROM dual
			 WHERE 1 = 0;
		OPEN out_cur_inds FOR
			SELECT null ind_sid
			  FROM dual
			 WHERE 1 = 0;
	
		OPEN out_cur_regions FOR
			SELECT null region_sid
			  FROM dual
			 WHERE 1 = 0;
		RETURN;
	END IF;
	
	-- we use delete rather than truncate to keep it all in a transaction
	EXECUTE IMMEDIATE 'DELETE FROM CSR.SS_'||UPPER(in_name);
	-- the period data might change on a refresh...
	EXECUTE IMMEDIATE 'DELETE FROM CSR.SS_'||UPPER(in_name)||'_PERIOD';
	
	OPEN out_cur_snapshot FOR
		SELECT ss.snapshot_dtm, name, title, start_dtm, end_dtm, period_set_id,
			   period_interval_id, use_unmerged, refresh_xml
		  FROM snapshot ss
		 WHERE ss.name = UPPER(in_name)
		   AND ss.app_sid = security_pkg.GetApp;

	OPEN out_cur_inds FOR
		SELECT ind_sid
		  FROM snapshot_ind si
		 WHERE si.name= UPPER(in_name);
		 
	GetRegions(in_name, out_cur_regions);

END;

PROCEDURE GetRegions(
	in_name		IN	snapshot.name%TYPE,
	out_cur		OUT SYS_REFCURSOR
)
AS
	v_cnt			NUMBER;
	v_is_supplier	NUMBER;
	v_is_property	NUMBER;
BEGIN
	SELECT is_supplier, is_property
	  INTO v_is_supplier, v_is_property
	  FROM snapshot
	 WHERE name = UPPER(in_name)
	   AND app_sid = security_pkg.GetApp;
	
	IF v_is_supplier=1 THEN
		OPEN out_cur FOR
			SELECT DISTINCT region_sid
			  FROM supplier
			 WHERE app_sid = security_pkg.GetApp;
	ELSIF v_is_property=1 THEN
		OPEN out_cur FOR
			SELECT DISTINCT region_sid
			  FROM region
			 WHERE app_sid = security_pkg.GetApp
			   AND region_type = csr_data_pkg.REGION_TYPE_PROPERTY;
	ELSE
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM snapshot_tag_group
		 WHERE name = UPPER(in_name)
		   AND app_sid = security_pkg.GetApp;
		
		IF v_cnt = 0 THEN
			-- base it on the region tree
			-- TODO: optimise to look at where the data is stored across all indicators requested (and incl
			-- any calculated indicators) and pick the lowest level regions common across all indicators.
			-- That'll be a fun query to write... maybe leave it for another day.
			OPEN out_cur FOR
				-- without descendents
				SELECT region_sid 
				  FROM snapshot_region 
				 WHERE all_descendents = 0
				   AND name = UPPER(in_name)
				 UNION
				-- with descendents
				SELECT /*+ALL_ROWS*/ region_sid
				  FROM (
					SELECT region_sid, connect_by_isleaf isleaf, active
					  FROM region r
					 START WITH region_sid IN (
						SELECT region_sid 
						  FROM snapshot_region 
						 WHERE all_descendents = 1
						   AND name = UPPER(in_name)
					 )
				   CONNECT BY PRIOR NVL(r.link_to_region_sid, r.region_sid) = parent_sid
				  )
				 WHERE isleaf = 1;  -- include inactive too since might be historic data
		ELSE
			OPEN out_cur FOR
				SELECT distinct region_sid
				  FROM snapshot_tag_group sstg, tag_group_member tgm, tag t, region_tag rt
				 WHERE sstg.tag_group_id = tgm.tag_group_Id
				   AND tgm.app_sid = t.app_sid
				   AND tgm.tag_id = t.tag_id
				   AND t.app_sid = rt.app_sid
				   AND t.tag_id = rt.tag_id
				   AND sstg.name = UPPER(in_name)
				   AND sstg.app_sid = security_pkg.GetApp;
		END IF;
	END IF;
END;

PROCEDURE GetSnapshot(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_tags		OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_periods		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_snapshot FOR
		SELECT ss.snapshot_dtm, ss.title, ss.description, ss.chart_template_root_sid,
			   ss.start_dtm, ss.end_dtm, ss.period_set_id, ss.period_interval_id
		  FROM snapshot ss
		 WHERE ss.name = UPPER(in_name)
		   AND ss.app_sid = security_pkg.GetApp;

	OPEN out_cur_tags FOR
		SELECT tg.tag_group_id, tg.name, t.tag_id, t.tag
		  FROM snapshot ss, snapshot_tag_group sstg, v$tag_group tg, tag_group_member tgm, v$tag t
		 WHERE ss.name = sstg.name
		   AND ss.app_sid =sstg.app_sid
		   AND sstg.tag_group_id = tg.tag_group_id
		   AND tg.tag_group_id = tgm.tag_group_id
		   AND tgm.tag_id = t.tag_id
		   AND ss.name = UPPER(in_name)
		 ORDER BY tg.tag_group_id, tag;

	OPEN out_cur_inds FOR
		SELECT i.ind_sid, i.description, m.description measure_description, REPLACE(indicator_pkg.INTERNAL_GetIndPathString(i.ind_sid),'Indicators / ','') ind_path,
			   NVL(i.format_mask, m.format_mask) format_mask
		  FROM snapshot_ind si, v$ind i, measure m
		 WHERE si.name = UPPER(in_name)
		   AND si.ind_sid = i.ind_sid
		   AND i.measure_sid = m.measure_sid
		 ORDER BY si.pos;
	
	OPEN out_cur_periods FOR
		'SELECT period_id, label, start_dtm, end_dtm FROM ss_'||in_name||'_period ORDER BY start_dtm';

END;

PROCEDURE GetSnapshotInfo(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_tags		OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_regions		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur_snapshot FOR
		SELECT ss.snapshot_dtm, ss.name, ss.title, ss.description, ss.use_unmerged, ss.refresh_xml,
			   ss.start_dtm, ss.end_dtm, ss.period_set_id, ss.period_interval_id, ss.is_supplier,
			   ss.chart_template_root_sid
		  FROM snapshot ss
		 WHERE ss.name = UPPER(in_name)
		   AND ss.app_sid = security_pkg.GetApp;

	OPEN out_cur_tags FOR
		SELECT tg.tag_group_id, tg.name
		  FROM snapshot ss
		  JOIN snapshot_tag_group sstg ON ss.name = sstg.name
		  JOIN v$tag_group tg ON sstg.tag_group_id = tg.tag_group_id
		 WHERE ss.name = UPPER(in_name)
		   AND sstg.app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur_inds FOR
		SELECT i.ind_sid, i.description
		  FROM snapshot_ind si
		  JOIN v$ind i ON si.ind_sid = i.ind_sid
		 WHERE si.name = UPPER(in_name)
		   AND si.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY si.pos;
	
	OPEN out_cur_regions FOR
		SELECT r.region_sid, r.description
		  FROM snapshot_region sr
		  JOIN v$region r ON sr.region_sid = r.region_sid
		 WHERE sr.name = UPPER(in_name)
		   AND sr.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetSnapshotList(
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, security_pkg.GetApp, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to app sid '||security_pkg.GetApp);
	END IF;

	OPEN out_cur FOR
		SELECT s.name, s.description, s.start_dtm, s.end_dtm, s.period_set_id, s.period_interval_id
		  FROM snapshot s
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetAllSnapshotsForUpdate(
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.name, c.host, c.alert_batch_run_time
		  FROM snapshot s
		  JOIN customer c ON s.app_sid = c.app_sid
		 WHERE s.next_update_after_dtm < sysdate;
END;

PROCEDURE SetNextUpdateDate(
	in_name				IN snapshot.name%TYPE,
	in_update_dtm		IN snapshot.next_update_after_dtm%type
)
AS
BEGIN
	UPDATE snapshot
	   SET next_update_after_dtm = in_update_dtm
	 WHERE name = in_name
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

END;
/

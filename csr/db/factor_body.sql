CREATE OR REPLACE PACKAGE BODY CSR.factor_pkg AS

FUNCTION CheckForOverlapStdFactorData RETURN NUMBER
AS
	v_overlaps						NUMBER;
BEGIN
	SELECT COUNT(*) 
	  INTO v_overlaps
	  FROM (
		SELECT DISTINCT f1.std_factor_id
	  FROM std_factor f1, std_factor f2
	 WHERE f1.factor_type_id = f2.factor_type_id
	   AND f1.gas_type_id = f2.gas_type_id
	   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
	   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
	   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
	   AND f1.std_factor_id != f2.std_factor_id
	   AND f1.std_factor_set_id = f2.std_factor_set_id
	   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
		   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
	);
	   
	IF v_overlaps > 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;

FUNCTION CheckForOverlapCtmFactorData RETURN NUMBER
AS
	v_overlaps					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_overlaps
	  FROM (
		SELECT DISTINCT f1.custom_factor_id
	  FROM custom_factor f1, custom_factor f2
	 WHERE f1.app_sid = f2.app_sid
	   AND f1.factor_type_id = f2.factor_type_id
	   AND f1.gas_type_id = f2.gas_type_id
	   AND DECODE(f1.region_sid, f2.region_sid, 1, 0) = 1
	   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
	   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
	   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
	   AND f1.custom_factor_id != f2.custom_factor_id
	   AND f1.custom_factor_set_id = f2.custom_factor_set_id
	   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
		   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
	);
	   
	IF v_overlaps > 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;

PROCEDURE GetOverlapStdFactorData(
	out_overlap_count OUT NUMBER,
	out_overlaps OUT VARCHAR2)
AS
BEGIN
	SELECT COUNT(*), SUBSTR(STRAGG(std_factor_id), 1, 4000)
	  INTO out_overlap_count, out_overlaps
	  FROM (
		SELECT DISTINCT f1.std_factor_id
	  FROM std_factor f1, std_factor f2
	 WHERE f1.factor_type_id = f2.factor_type_id
	   AND f1.gas_type_id = f2.gas_type_id
	   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
	   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
	   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
	   AND f1.std_factor_id != f2.std_factor_id
	   AND f1.std_factor_set_id = f2.std_factor_set_id
	   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
	   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
		 ORDER BY f1.std_factor_id
	);
END;

PROCEDURE GetOverlapCtmFactorData(
	out_overlap_count OUT NUMBER,
	out_overlaps OUT VARCHAR2)
AS
BEGIN
	SELECT COUNT(*), SUBSTR(STRAGG(custom_factor_id), 1, 4000)
	  INTO out_overlap_count, out_overlaps
	  FROM (
		SELECT DISTINCT f1.custom_factor_id
	  FROM custom_factor f1, custom_factor f2
	 WHERE f1.app_sid = f2.app_sid
	   AND f1.factor_type_id = f2.factor_type_id
	   AND f1.gas_type_id = f2.gas_type_id
	   AND DECODE(f1.region_sid, f2.region_sid, 1, 0) = 1
	   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
	   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
	   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
	   AND f1.custom_factor_id != f2.custom_factor_id
	   AND f1.custom_factor_set_id = f2.custom_factor_set_id
	   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
	   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
		 ORDER BY f1.custom_factor_id
	);
END;

PROCEDURE SetStdFactorValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_egrid_ref			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE,
	out_std_factor_id		OUT std_factor.std_factor_id%TYPE
)
AS
	v_geo_country			std_factor.geo_country%TYPE;
	v_geo_region            VARCHAR2(4);
	v_std_factor_id			std_factor.std_factor_id%TYPE;
	v_count					NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage standard factors');
	END IF;

	-- extract geo properties if a region_sid is passed
	IF in_region_sid IS NOT NULL THEN
		SELECT geo_country, geo_region INTO v_geo_country, v_geo_region 
		  FROM region 
		 WHERE region_sid = in_region_sid;
	ELSE
		v_geo_country := in_geo_country;
		v_geo_region := in_geo_region;
	END IF;
	
	IF in_value IS NULL THEN
		-- delete
		BEGIN
			SELECT std_factor_id
			  INTO v_std_factor_id
			  FROM std_factor
			 WHERE std_factor_set_id = in_std_factor_set_id
			   AND factor_type_id = in_factor_type_id
			   AND gas_type_id = in_gas_type_id
			   AND NVL(geo_country, 'XX') = NVL(in_geo_country, 'XX')
			   AND NVL(geo_region, 'XX') = NVL(in_geo_region, 'XX')
			   AND NVL(egrid_ref, 'XX') = NVL(in_egrid_ref, 'XX')
			   AND start_dtm = in_start_dtm
			   AND (end_dtm = in_end_dtm OR (end_dtm IS NULL AND in_end_dtm IS NULL));
			-- XXX: needs std_measure_conversion in the table
			INSERT INTO factor_history (app_sid, factor_id, changed_dtm, user_sid, old_value, note)
				SELECT app_sid, factor_id, SYSDATE, SYS_CONTEXT('SECURITY','SID'), value, 'Deleted std factor '||v_std_factor_id||'. Value was '||value||' '||mc.description
				  FROM factor f
					JOIN std_measure_conversion mc ON f.std_measure_conversion_id = mc.std_measure_conversion_id
				 WHERE std_factor_id = v_std_factor_id;
			DELETE FROM std_factor
			 WHERE std_factor_id = v_std_factor_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_std_factor_id := -1; -- The C# layer won't return a null to a long
		END;
	ELSE
		--add new entry to std factor table
		BEGIN
			INSERT INTO std_factor(std_factor_id, factor_type_id, std_factor_set_id, gas_type_id, 
				   geo_country, geo_region, egrid_ref, start_dtm, end_dtm, value,
				   std_measure_conversion_id, note)
			VALUES (STD_FACTOR_ID_SEQ.nextval , in_factor_type_id, in_std_factor_set_id, in_gas_type_id,
				   in_geo_country, in_geo_region, in_egrid_ref, in_start_dtm, in_end_dtm, in_value,
				   in_std_meas_conv_id, in_note)
			RETURNING std_factor_id INTO v_std_factor_id;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				-- we check for overlaps lower down
				UPDATE std_factor
				   SET value = in_value,
					std_measure_conversion_id = in_std_meas_conv_id,
					note = in_note
				 WHERE std_factor_set_id = in_std_factor_set_id
				   AND factor_type_id = in_factor_type_id
				   AND gas_type_id = in_gas_type_id
				   AND NVL(geo_country, 'XX') = NVL(in_geo_country, 'XX')
				   AND NVL(geo_region, 'XX') = NVL(in_geo_region, 'XX')
				   AND NVL(egrid_ref, 'XX') = NVL(in_egrid_ref, 'XX')
				   AND start_dtm = in_start_dtm
				   AND (end_dtm = in_end_dtm OR (end_dtm IS NULL AND in_end_dtm IS NULL))
			  RETURNING std_factor_id INTO v_std_factor_id;			   
			  IF v_std_factor_id IS NULL THEN
				-- uh? which constraint got violated?
					security_pkg.debugmsg(in_std_factor_set_id||','||in_std_factor_set_id||','||in_gas_type_id||','||NVL(in_geo_country, 'XX')
						||','||NVL(in_geo_region, 'XX')||','||NVL(in_egrid_ref, 'XX')||','||in_start_dtm||','||in_end_dtm);
			  END IF;
		END;
	END IF;
	
	-- fiddle with context
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	security_pkg.SetApp(NULL);
	
	FOR r IN (
		-- find a distinct set of customers already using this factor (i.e. matching country|region|egrid|factortype/std_factor_set)
		-- i.e. if we've added a new period then we want to make sure it gets added to the right customers. We could be more specific
		-- and only do this if it's an insert into std_Factor but might as well just go for it regardless.
		SELECT x.app_sid, sf.std_factor_set_id, sf.factor_type_id, sf.geo_country, sf.geo_region, sf.egrid_ref, 
				TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(sf.start_dtm,'YYYY'), 'MMYYYY') start_dtm, 
				CASE
					WHEN sf.end_dtm IS NULL THEN NULL
					ELSE ADD_MONTHS(TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(sf.start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(sf.end_dtm, sf.start_dtm))
				END end_dtm,
				sf.gas_type_id, sf.value, sf.note, sf.std_factor_id, sf.std_measure_conversion_id
		  FROM (
			 SELECT DISTINCT f.app_sid, sf.std_factor_set_id, f.factor_type_id, f.geo_country, f.geo_region, f.egrid_ref
			   FROM factor f
				JOIN std_factor sf ON f.std_factor_id = sf.std_factor_id
 			  WHERE f.factor_type_id = in_factor_type_id
				AND sf.std_factor_set_id = in_std_factor_set_id
				AND NVL(f.geo_country, 'XX') = NVL(in_geo_country, 'XX')
				AND NVL(f.geo_region, 'XX') = NVL(in_geo_region, 'XX')
				AND NVL(f.egrid_ref, 'XX') = NVL(in_egrid_ref, 'XX')
				AND f.is_selected = 1
		   )x 
		   JOIN std_factor sf 
			 ON sf.std_factor_set_id = x.std_factor_set_id
			AND sf.factor_type_id = x.factor_type_id
			AND NVL(sf.geo_country, 'XX') = NVL(x.geo_country, 'XX')
			AND NVL(sf.geo_region, 'XX') = NVL(x.geo_region, 'XX')
			AND NVL(sf.egrid_ref, 'XX') = NVL(x.egrid_ref, 'XX')
		   JOIN (SELECT app_sid, DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month
				   FROM customer) o
			 ON x.app_sid = o.app_sid
	)
	LOOP
		-- wtf is factor.original_factor_id? [ignore it]
		BEGIN
			INSERT INTO factor (app_sid, factor_id, factor_type_id, gas_type_id, start_dtm, end_dtm, 
				geo_country, geo_region, egrid_ref, region_sid, value, note, std_factor_id, std_measure_conversion_id, is_selected)
				VALUES (r.app_sid, factor_id_seq.nextval, r.factor_type_id, r.gas_type_id, r.start_dtm, r.end_dtm,
					r.geo_country, r.geo_region, r.egrid_ref, 
					null, -- region_sid has no context in the context of slapping new factors in from the std set since it's specific
					r.value, r.note, r.std_factor_id, r.std_measure_conversion_id, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE factor 
				   SET value = r.value, note = r.note, std_measure_conversion_id = r.std_measure_conversion_id
				 WHERE std_factor_id = r.std_factor_Id -- bit of a short-cut - if it's not a bespoke factor then the unique key is effectively app_sid and std_factor_id
				   AND app_sid = r.app_sid;
		END;
	END LOOP;
	
	-- write calc jobs for all customer
	FOR r IN (
		SELECT app_sid
		  FROM customer
		 WHERE use_carbon_emission = 1
	)
	LOOP
		security_pkg.SetApp(r.app_sid);
		calc_pkg.AddJobsForFactorType(in_factor_type_id);
	END LOOP;
	
	security_pkg.SetApp(v_app_sid);
	
	out_std_factor_id := v_std_factor_id;
	
END;

/*
This function returns data for each leaf node in the tree (i.e. each factor type).
*/
PROCEDURE GetFactorTypeMappedPaths(
	out_mapped_cur		OUT	SYS_REFCURSOR
)
AS
	v_root factor_type.factor_type_id%TYPE;
BEGIN
	SELECT factor_type_id 
	  INTO v_root
	  FROM factor_type 
	 WHERE parent_id IS NULL;

	OPEN out_mapped_cur FOR
	SELECT ft.factor_type_id, ft.path, ftc.info_note -- Wrapper for info_note clob as clobs cannot be used in comparisons like distinct or union.
	  FROM ( 
		SELECT DISTINCT factor_type_id, path
		  FROM (
			SELECT f.factor_type_id, sf.std_factor_set_id, NULL custom_factor_set_id,
				   CASE WHEN sfa.std_factor_set_id IS NULL THEN 0 ELSE 1 END active, 
				   ltrim(sys_connect_by_path(trim(f.name), ' > '),' > ') path,
				   i.ind_sid
			  FROM factor_type f
			  LEFT JOIN std_factor sf ON sf.factor_type_id = f.factor_type_id
			  LEFT JOIN std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
			  LEFT JOIN ind i ON i.factor_type_id = f.factor_type_id
			 WHERE std_measure_id IS NOT NULL
			   AND sf.std_factor_set_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id 
			UNION 
			SELECT f.factor_type_id, NULL std_factor_set_id, sf.custom_factor_set_id, 
				   1 active, 
				   ltrim(sys_connect_by_path(trim(f.name), ' > '),' > ') path,
				   i.ind_sid
			  FROM factor_type f
			  LEFT JOIN custom_factor sf ON sf.factor_type_id = f.factor_type_id
			  LEFT JOIN ind i ON i.factor_type_id = f.factor_type_id
			 WHERE std_measure_id IS NOT NULL
			   AND sf.custom_factor_set_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id
			UNION
			SELECT f.factor_type_id, NULL std_factor_set_id, NULL custom_factor_set_id,
				   1 active, 
				   ltrim(sys_connect_by_path(trim(f.name), ' > '),' > ') path,
				   i.ind_sid
			  FROM factor_type f
			  LEFT JOIN ind i ON i.factor_type_id = f.factor_type_id
			 WHERE f.factor_type_id = UNSPECIFIED_FACTOR_TYPE
			   AND std_measure_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id
		)
		 WHERE ind_sid is not NULL
	) ft
	  JOIN factor_type ftc ON ft.factor_type_id = ftc.factor_type_id
	 ORDER BY PATH ASC;
END;

PROCEDURE GetIndicatorsForFactorTypes(
	in_factor_type_ids	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_factor_type_ids	security.T_ORDERED_SID_TABLE;
BEGIN
	v_factor_type_ids := security_pkg.SidArrayToOrderedTable(in_factor_type_ids);

	OPEN out_cur FOR
	SELECT i.ind_sid, i.description, i.active, csr.trash_pkg.IsInTrash(security.security_pkg.GetACT, i.ind_sid) deleted
	  FROM v$ind i
	 WHERE i.app_sid = security.security_pkg.getApp
	   AND i.factor_type_id IN (SELECT sid_id FROM TABLE(v_factor_type_ids))
	   AND i.gas_type_id IS NULL;
END;

PROCEDURE ApplyIndicatorMappings(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_measure_sid			IN factor_type.std_measure_id%TYPE,
	in_ind_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_ind_sids				security.T_ORDERED_SID_TABLE;
	v_factor_type_id		factor_type.factor_type_id%TYPE := in_factor_type_id;
	v_trashed_ind_calcs		NUMBER;
BEGIN

	IF in_factor_type_id = 0 THEN
		v_factor_type_id := NULL;
	END IF;

	v_ind_sids := security_pkg.SidArrayToOrderedTable(in_ind_sids);
	UPDATE ind
	   SET factor_type_id = v_factor_type_id
	 WHERE app_sid = security.security_pkg.getApp
	   AND ind_sid IN (SELECT sid_id FROM TABLE(v_ind_sids));

	FOR r IN (SELECT sid_id ind_sid FROM TABLE(v_ind_sids))
	LOOP
		IF v_factor_type_id IS NOT NULL THEN
			UPDATE ind
			   SET factor_type_id = v_factor_type_id,
					gas_measure_sid = in_measure_sid
			 WHERE app_sid = security.security_pkg.getApp
			   AND ind_sid = r.ind_sid;
			indicator_pkg.CreateGasIndicators(r.ind_sid);
		ELSE
			FOR d IN (SELECT ind_sid FROM ind where map_to_ind_sid = r.ind_sid)
			LOOP
				WITH di AS ( -- get indicator and any child indicators
					SELECT ind_sid
					  FROM csr.ind
						   START WITH ind_sid = d.ind_sid
						   CONNECT BY PRIOR ind_sid = parent_sid),
				ti AS ( -- indicators in the trash
					SELECT ind_sid
					  FROM csr.ind
						   START WITH parent_sid = (SELECT trash_sid FROM csr.customer)
						   CONNECT BY PRIOR ind_sid = parent_sid)
				SELECT COUNT(*)
					  INTO v_trashed_ind_calcs
					  FROM di
				  JOIN csr.v$calc_direct_dependency cd ON di.ind_sid = cd.ind_sid
				  JOIN ti on cd.calc_ind_sid = ti.ind_sid;
				
				IF v_trashed_ind_calcs != 0 THEN
					RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
					'Cannot trash indicator '||r.ind_sid||' because it is used by a formula');
				END IF;
			
				securableobject_pkg.DeleteSO(SYS_CONTEXT('SECURITY', 'ACT'), d.ind_sid);
			END LOOP;
		END IF;
	END LOOP;
END;

/*
This function returns the paths to each leaf node in the tree (i.e. each factor type).
*/
PROCEDURE GetFactorTypePaths(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT factor_type_id, LTRIM(sys_connect_by_path(TRIM(name), ' > '),' > ') path
		  FROM factor_type
		 WHERE std_measure_id IS NOT NULL
		 START WITH parent_id IS NULL
		CONNECT BY PRIOR factor_type_id = parent_id;
END;

/*
This function returns the paths to each "folder" node in the tree.
*/
PROCEDURE GetFactorTypeNodes(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT factor_type_id, LTRIM(sys_connect_by_path(TRIM(name), ' > '),' > ') path
		  FROM factor_type
		 WHERE CONNECT_BY_ISLEAF=0
		 START WITH parent_id IS NULL
		CONNECT BY PRIOR factor_type_id = parent_id;
END;


/* MOST OF THIS CODE IS UTTER SHIT. I HAD DELETED LARGE CHUNKS BUT IT'LL NEED MORE TESTING SO I'M HOLDING 
   OFF (SADLY) FOR NOW */

PROCEDURE GetGasList(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- public, no security needed
	
	-- TODO: fix this query, should be gases list per factor type
	OPEN out_cur FOR
		SELECT gas_type_id, name
		  FROM gas_type;
END;

PROCEDURE GetGasTypes(
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- public, no security needed
	OPEN out_cur FOR
		SELECT gas_type_id, name
		  FROM gas_type;
END;

PROCEDURE GetStdMeasure(
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- public, no security needed
	OPEN out_cur FOR
		SELECT std_measure_id, name
		  FROM std_measure;
END;

PROCEDURE GetStdMeasConvList(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	IF in_factor_type_id IS NULL OR in_factor_type_id = 0 THEN
		OPEN out_cur FOR
			SELECT smc.std_measure_conversion_id, smc.description, smc.std_measure_id
			  FROM std_measure_conversion smc;
	ELSE
		OPEN out_cur FOR
			SELECT smc.std_measure_conversion_id, smc.description, smc.std_measure_id
			  FROM std_measure_conversion smc
			  JOIN std_measure sm ON smc.std_measure_id = sm.std_measure_id
			  JOIN factor_type ft ON sm.std_measure_id = ft.std_measure_id
			 WHERE ft.factor_type_id = in_factor_type_id;
	END IF;
END;


PROCEDURE GetAllStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT std_factor_set_id, name, published, visible, info_note
		  FROM std_factor_set
		 ORDER BY name;
END;

PROCEDURE GetStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT std_factor_set_id, name, visible, info_note
		  FROM std_factor_set
		 WHERE published = 1
		   AND visible_in_classic_tool = 1
		 ORDER BY name;
END;

PROCEDURE GetStdFactorSets(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;
	
	-- This SP is only used by the Classic (aka old) EF tool.
	OPEN out_cur FOR
		SELECT sfs.std_factor_set_id, sfs.name, NVL(is_used,0) is_used 
		  FROM (
				SELECT DISTINCT std_factor_set_id, 1 is_used 
				FROM std_factor 
				WHERE factor_type_id = in_factor_type_id
		  )sf, std_factor_set sfs
		 WHERE sfs.std_factor_set_id = sf.std_factor_set_id (+)
		   AND sfs.published = 1
		   AND sfs.visible_in_classic_tool = 1
		 ORDER by sfs.name;


END;


PROCEDURE GetStdFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_geo_country			std_factor.geo_country%TYPE;
	v_geo_region			VARCHAR2(4);
	v_factor_start_month	NUMBER(2);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	
	IF in_region_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || in_region_sid);
		END IF;
	
		SELECT geo_country, geo_region INTO v_geo_country, v_geo_region 
		  FROM region 
		 WHERE region_sid = in_region_sid;
	ELSE
		v_geo_country := in_geo_country;
		v_geo_region := in_geo_region;
	END IF;
	
	SELECT DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month
	  INTO v_factor_start_month
	  FROM customer
	 WHERE app_sid = v_app_sid;
	
	-- A region could be geographical or non geographical, i.e country, or an office(when a special override is required)
	-- Factor values are either standard or bespoke regardless of the region type
	
	-- this is standard value => fetch factor info from std_factor table 
	-- as it doesn't matter if a copy exist in factor table
	OPEN out_cur FOR
		SELECT start_dtm, end_dtm, factor.gas_type_id,
			   gt.name gas_name, value, std_measure_conversion_id, note, 
			   std_factor_id factor_id 
		  FROM (
			SELECT 
				TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY') start_dtm,
				CASE
					WHEN f.end_dtm IS NULL THEN NULL
					ELSE ADD_MONTHS(TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(f.end_dtm, f.start_dtm))
				END end_dtm,
				f.gas_type_id, f.value, f.std_measure_conversion_id, f.note, f.std_factor_id
			  FROM std_factor f
			 WHERE f.factor_type_id = in_factor_type_id
			   AND f.std_factor_set_id = in_std_factor_set_id
			   AND ((v_geo_country IS NULL AND geo_country IS NULL) OR geo_country = v_geo_country)
			   AND ((v_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = v_geo_region OR egrid_ref = v_geo_region)
		  ) factor, gas_type gt
		WHERE factor.gas_type_id = gt.gas_type_id;
	
END;

PROCEDURE StdFactorAddNewValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE,
	in_source				IN std_factor.source%TYPE,
	out_std_factor_id		OUT std_factor.std_factor_id%TYPE
)
AS
	v_geo_country			std_factor.geo_country%TYPE;
	v_geo_region            VARCHAR2(4);
	v_std_factor_id			std_factor.std_factor_id%TYPE;
	v_count					NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage standard factors');
	END IF;

	--extract geo properties
	IF in_region_sid IS NOT NULL THEN
		SELECT geo_country, geo_region INTO v_geo_country, v_geo_region 
		  FROM region 
		 WHERE region_sid = in_region_sid;
	ELSE
		v_geo_country := in_geo_country;
		v_geo_region := in_geo_region;
	END IF;
	
	
	SELECT STD_FACTOR_ID_SEQ.nextval INTO v_std_factor_id FROM DUAL;
	
	--add new entry to std factor table
	SELECT COUNT(*)
	  INTO v_count
	  FROM POSTCODE.region
	 WHERE country = v_geo_country
	   AND v_geo_region IS NULL OR region = v_geo_region;
	   
	IF v_count > 0 THEN
		INSERT INTO std_factor(std_factor_id, factor_type_id, std_factor_set_id, gas_type_id, 
						   geo_country, geo_region, start_dtm, end_dtm, value,
						   std_measure_conversion_id, note)
					VALUES(v_std_factor_id, in_factor_type_id, in_std_factor_set_id, in_gas_type_id,
						   in_geo_country, in_geo_region, in_start_dtm, in_end_dtm, in_value,
						   in_std_meas_conv_id, in_note);
	ELSE
		INSERT INTO std_factor(std_factor_id, factor_type_id, std_factor_set_id, gas_type_id, 
						   geo_country, egrid_ref, start_dtm, end_dtm, value,
						   std_measure_conversion_id, note)
					VALUES(v_std_factor_id, in_factor_type_id, in_std_factor_set_id, in_gas_type_id,
						   in_geo_country, in_geo_region, in_start_dtm, in_end_dtm, in_value,
						   in_std_meas_conv_id, in_note);
	END IF;
	
	out_std_factor_id := v_std_factor_id;
END;

PROCEDURE StdFactorAmendValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	in_value				IN std_factor.value%TYPE,
	in_std_meas_conv_id		IN std_factor.std_measure_conversion_id%TYPE,
	in_note					IN std_factor.note%TYPE
)
AS
	v_factor_type_id		std_factor.factor_type_id%TYPE;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	NULL;
END;

PROCEDURE StdFactorDelValue(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE
)
AS
	v_std_factor_set_id		std_factor_set.std_factor_set_id%TYPE;
	v_factor_type_id		factor_type.factor_type_id%TYPE;
	v_count					NUMBER;
	v_app_sid				security_pkg.T_SID_ID;
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You must be a superadmin user to manage standard factors');
	END IF;
	
	-- update copies factor table
	DELETE FROM factor WHERE std_factor_id = in_std_factor_id;
	-- update std factor table
	DELETE FROM std_factor WHERE std_factor_id = in_std_factor_id;
	
END;

-- Handlers for accessing factor table for bespoke values
--
-- Looks like in_geo_region is some hack where you can pass in an egrid or a geo region.
-- That's pretty unnecessary? Needs cleaning up.
PROCEDURE BespokeFactorAddNewValue(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	in_start_dtm			IN factor.start_dtm%TYPE,
	in_end_dtm				IN factor.end_dtm%TYPE,
	in_gas_type_id			IN factor.gas_type_id%TYPE,
	in_value				IN factor.value%TYPE,
	in_std_meas_conv_id		IN factor.std_measure_conversion_id%TYPE,
	in_note					IN factor.note%TYPE,
	out_factor_id			OUT factor.factor_id%TYPE
)
AS
	v_count					NUMBER(10);
	v_audit_info			VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;

	IF in_region_sid IS NOT NULL THEN
		IF NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security.security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the region with sid ' || in_region_sid);
		END IF;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM POSTCODE.region
	 WHERE country = in_geo_country
	   AND in_geo_region IS NULL OR region = in_geo_region;
	   
	IF v_count > 0 THEN
		INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country, 
						geo_region, std_factor_id, start_dtm, end_dtm, value, 
						std_measure_conversion_id, note, region_sid)
			VALUES(in_app_sid, FACTOR_ID_SEQ.nextval, in_factor_type_id, in_gas_type_id,
				   in_geo_country, in_geo_region, NULL, in_start_dtm, in_end_dtm,
				   in_value, in_std_meas_conv_id, in_note, in_region_sid)
			RETURNING factor_id INTO out_factor_id;
	ELSE
		INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country, 
						egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
						std_measure_conversion_id, note, region_sid)
			VALUES(in_app_sid, FACTOR_ID_SEQ.nextval, in_factor_type_id, in_gas_type_id,
				   in_geo_country, in_geo_region, NULL, in_start_dtm, in_end_dtm,
				   in_value, in_std_meas_conv_id, in_note, in_region_sid)
			RETURNING factor_id INTO out_factor_id;
	END IF;
	
	-- write calc jobs
	calc_pkg.AddJobsForFactorType(in_factor_type_id);
	
	v_audit_info := 'Created Emission factor ( FactorTypeId='|| in_factor_type_id ||', ' ||
		'GeoCountry='|| in_geo_country ||', ' ||
		'GeoRegion='|| in_geo_region ||', ' || 
		'RegionSid='|| in_region_sid ||', ' || 
		'StartDtm='|| in_start_dtm ||', ' || 
		'EndDtm='|| in_end_dtm ||', ' || 
		'GasTypeId='|| in_gas_type_id ||', ' || 
		'Value='|| in_value ||', ' || 
		'Measure='|| in_std_meas_conv_id ||', ' || 
		'Note='|| in_note ||
		')';
		
	csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp,
		in_factor_type_id, v_audit_info);
END;


PROCEDURE BespokeFactorAmendValue(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_id			IN factor.factor_id%TYPE,
	in_start_dtm			IN factor.start_dtm%TYPE,
	in_end_dtm				IN factor.end_dtm%TYPE,
	in_gas_type_id			IN factor.gas_type_id%TYPE,
	in_value				IN factor.value%TYPE,
	in_std_meas_conv_id		IN factor.std_measure_conversion_id%TYPE,
	in_note					IN factor.note%TYPE
)
AS
	v_factor_type_id		factor.factor_type_id%TYPE;
	v_audit_info			VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	-- TODO: this doesn't seem to history anything

	-- update copies factor table
	UPDATE factor 
	   SET start_dtm = in_start_dtm,
			  end_dtm = in_end_dtm,
			  gas_type_id = in_gas_type_id,
			  value = in_value,
			  std_measure_conversion_id = in_std_meas_conv_id,
			  note = in_note,
			  original_factor_id = NULL
	WHERE app_sid = in_app_sid
	  AND factor_id = in_factor_id;
	  
	UPDATE factor 
	   SET start_dtm = in_start_dtm,
			  end_dtm = in_end_dtm,
			  gas_type_id = in_gas_type_id,
			  value = in_value,
			  std_measure_conversion_id = in_std_meas_conv_id,
			  note = in_note
	WHERE app_sid = in_app_sid
	  AND original_factor_id = in_factor_id;
	
	-- write calc jobs
	SELECT factor_type_id
	  INTO v_factor_type_id
	  FROM factor
	 WHERE factor_id = in_factor_id;
	
	calc_pkg.AddJobsForFactorType(v_factor_type_id);
	
	v_audit_info := 'Updated Emission factor (FactorTypeId='|| V_factor_type_id ||', ' ||
		'FactorId='|| in_factor_id ||', ' ||
		'StartDtm='|| in_start_dtm ||', ' || 
		'EndDtm='|| in_end_dtm ||', ' || 
		'GasTypeId='|| in_gas_type_id ||', ' || 
		'Value='|| in_value ||', ' || 
		'Measure='|| in_std_meas_conv_id ||', ' || 
		'Note='|| in_note ||
		')';
	
	csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, 
		v_factor_type_id, v_audit_info);
END;


PROCEDURE BespokeFactorDelValue(
	in_factor_id		IN factor.factor_id%TYPE
)
AS
	v_factor_type_id			factor.factor_type_id%TYPE;
	v_geo_country				factor.geo_country%TYPE;
	v_geo_region				factor.geo_region%TYPE;
	v_region_sid				factor.region_sid%TYPE;
	v_start_dtm					factor.start_dtm%TYPE;
	v_end_dtm					factor.end_dtm%TYPE;
	v_gas_type_id				factor.gas_type_id%TYPE;
	v_value						factor.value%TYPE;
	v_std_measure_conversion_id	factor.std_measure_conversion_id%TYPE;
	v_note						factor.note%TYPE;
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_audit_info				VARCHAR2(1000);
BEGIN
	-- write calc jobs
	SELECT factor_type_id, geo_country, geo_region, region_sid, start_dtm, end_dtm, gas_type_id, value, std_measure_conversion_id, note
	  INTO v_factor_type_id, v_geo_country, v_geo_region, v_region_sid, v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_measure_conversion_id, v_note
	  FROM factor
	 WHERE factor_id = in_factor_id;
	
	-- update copies factor table
	DELETE FROM factor
	 WHERE (factor_id = in_factor_id OR original_factor_id = in_factor_id)
	   AND app_sid = v_app_sid;
	
	calc_pkg.AddJobsForFactorType(v_factor_type_id);
	
	v_audit_info := 'Deleted Emission factor (FactorTypeId='|| v_factor_type_id ||', ' ||
		'GeoCountry='|| v_geo_country ||', ' ||
		'GeoRegion='|| v_geo_region ||', ' || 
		'RegionSid='|| v_region_sid ||', ' || 
		'StartDtm='|| v_start_dtm ||', ' || 
		'EndDtm='|| v_end_dtm ||', ' || 
		'GasTypeId='|| v_gas_type_id ||', ' || 
		'Value='|| v_value ||', ' || 
		'Measure='|| v_std_measure_conversion_id ||', ' || 
		'Note='|| v_note ||
		')';
		
	csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp,
		v_factor_type_id, v_audit_info);
	
END;

PROCEDURE GetBespokeFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;
	
	IF in_region_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || in_region_sid);
		END IF;
	END IF;
	
	-- A region could be geographical or non geographical, i.e country, or an office(when a special override is required)
	-- Factor values are either standard or bespoke regardless of the region type

	-- this is bespoke value => fetch factor info from factor table
	OPEN out_cur FOR
		SELECT start_dtm, end_dtm, factor.gas_type_id, gt.name gas_name, value, std_measure_conversion_id, note, factor_id FROM
		(
		SELECT f.start_dtm, f.end_dtm, f.gas_type_id, f.value, f.std_measure_conversion_id, f.note, f.factor_id
			  FROM factor f
			 WHERE f.factor_type_id = in_factor_type_id
			   AND app_sid = v_app_sid
			   AND std_factor_id IS NULL -- bespoke!
			   AND original_factor_id IS NULL
			   AND ((in_region_sid IS NULL AND region_sid IS NULL
				   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
				   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region))
					OR (in_region_sid IS NOT NULL AND region_sid = in_region_sid))
		) factor, gas_type gt
		where factor.gas_type_id = gt.gas_type_id;

END;

PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_root_sid		security_pkg.T_SID_ID;	
BEGIN	
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	-- get root sid
	v_root_sid := region_tree_pkg.GetPrimaryRegionTreeRootSid;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), v_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || v_root_sid);
	END IF;
	
	-- ROOT LEVEL - displays countries and possible std and bespoke factors (overrides are not possible in this level) 
	
	OPEN out_cur FOR 
		SELECT geo_country, geo_region, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected
		FROM
		(
			SELECT reg.geo_country, null geo_region, reg.name, factors.std_factor_id, factors.std_factor_set_id, factors.factor_id, factors.region_sid, factors.is_selected
			  FROM (  
					SELECT r.geo_country, c.name 
					  FROM (SELECT DISTINCT geo_country 
							  FROM region 
							 WHERE geo_type IS NOT NULL
							 START WITH parent_sid = v_root_sid
						   CONNECT BY PRIOR region_sid = parent_sid
						   ) r,	postcode.country c
					 WHERE r.geo_country = c.country
					) reg,
					(
				   SELECT DISTINCT sf.std_factor_id, sf.std_factor_set_id, sf.geo_country, f.factor_id, f.is_selected, f.region_sid
					 FROM std_factor sf
					 JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id AND sfs.published = 1
					 LEFT JOIN factor f ON (
							sf.std_factor_id = f.std_factor_id
							AND sf.factor_type_id = f.factor_type_id
							AND NVL(f.is_virtual,0) = 0
						)
					WHERE sf.geo_country IS NOT NULL 
					  AND sf.geo_region IS NULL
					  AND sf.egrid_ref IS NULL
					  AND sf.factor_type_id = in_factor_type_id
					UNION ALL -- get bespoke values
				   SELECT DISTINCT sf.std_factor_id, sf.std_factor_set_id, f.geo_country, f.factor_id, f.is_selected, f.region_sid
					 FROM factor f
					 LEFT JOIN (
						SELECT sf.std_factor_id, sf.std_factor_set_id
						  FROM std_factor sf
						  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
						 WHERE sfs.published = 1
				  ) sf ON f.std_factor_id = sf.std_factor_id
					WHERE f.geo_country IS NOT NULL 
					  AND f.geo_region IS NULL
					  AND f.egrid_ref IS NULL
					  AND f.factor_type_id = in_factor_type_id
					  AND f.region_sid IS NULL
					  AND NVL(f.is_virtual,0) = 0
				 ) factors
			WHERE reg.geo_country = factors.geo_country (+)
			ORDER BY reg.geo_country -- C# rely on that
		)
		UNION -- union with global default value for => factor_type, app_sid (hence, for each app defalut value for any factor_type)  
    
		SELECT geo_country, geo_region, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected
		  FROM (
				(
					SELECT NULL geo_country, NULL geo_region, 'WORLDWIDE' name, NULL region_sid
					  FROM dual
				)
				LEFT JOIN
				(
					--std factor values
					SELECT sf.std_factor_id, sf.std_factor_set_id, f.factor_id, f.is_selected
					  FROM std_factor sf
					  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id AND sfs.published = 1
					  LEFT JOIN factor f ON (
								sf.std_factor_id = f.std_factor_id
								AND sf.factor_type_id = f.factor_type_id
								AND NVL(f.is_virtual,0) = 0
							)
					 WHERE sf.geo_country IS NULL
					   AND sf.geo_region IS NULL
					   AND sf.egrid_ref IS NULL
					   AND sf.factor_type_id = in_factor_type_id

					UNION
					
					--bespoke values and selected (but not set) std set values
					SELECT sf.std_factor_id, sf.std_factor_set_id, f.factor_id, f.is_selected
					  FROM factor f
					  LEFT JOIN (
						SELECT sf.std_factor_id, sf.std_factor_set_id
						  FROM std_factor sf
						  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
						 WHERE sfs.published = 1
				   ) sf ON f.std_factor_id = sf.std_factor_id
					 WHERE f.geo_country IS NULL 
					   AND f.geo_region IS NULL
					   AND f.egrid_ref IS NULL
					   AND f.factor_type_id = in_factor_type_id
					   AND f.region_sid IS NULL
					   AND NVL(f.is_virtual,0) = 0
				) ON 1 = 1
		);
END;

PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,	
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_root_sid		security_pkg.T_SID_ID;	
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	--get root sid
	SELECT region_sid INTO v_root_sid FROM region WHERE parent_sid = v_app_sid;

	-- COUNTRY LEVEL - displays regions of given country and possible std and bespoke factors 
	--				   (notice: overrides are possible in this level) 
	
	OPEN out_cur FOR 
		
		SELECT geo_country, geo_region, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected FROM (
			SELECT reg.geo_country, reg.geo_region, reg.name, std.std_factor_id, std.std_factor_set_id, std.factor_id, std.region_sid ,std.is_selected
			  FROM ( 
				SELECT r.geo_country, r.geo_region, gr.name 
				  FROM ( SELECT DISTINCT geo_country, geo_region 
						 FROM region
						WHERE geo_type IS NOT NULL
						  AND geo_country = in_geo_country
						START WITH parent_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
					  CONNECT BY PRIOR region_sid = parent_sid
					  ) r
				 JOIN POSTCODE.region gr ON (
							r.geo_country = gr.country
						AND r.geo_region = gr.region
						)
				 CROSS JOIN factor_type ft
				 WHERE (r.geo_country != 'us'
						OR (ft.factor_type_id = in_factor_type_id AND ft.egrid = 0)
						)
				) reg, 
			   (
				SELECT DISTINCT sf.std_factor_id, sf.std_factor_set_id, sf.geo_country, sf.geo_region, f.factor_id, f.is_selected, f.region_sid
				  FROM std_factor sf
				  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id AND sfs.published = 1
				  LEFT JOIN factor f ON (
						sf.std_factor_id = f.std_factor_id
						AND sf.factor_type_id = f.factor_type_id
						AND NVL(f.is_virtual,0) = 0
					)
				 WHERE sf.geo_region IS NOT NULL 
				   AND sf.factor_type_id = in_factor_type_id
				UNION ALL -- get bespoke and parent values
				 SELECT sf.std_factor_id, sf.std_factor_set_id, f.geo_country, f.geo_region, f.factor_id, f.is_selected, f.region_sid
				   FROM factor f
				   LEFT JOIN (
					SELECT sf.std_factor_id, sf.std_factor_set_id
					  FROM std_factor sf
					  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
					 WHERE sfs.published = 1
				) sf ON f.std_factor_id = sf.std_factor_id
				  WHERE f.geo_region IS NOT NULL
					AND f.app_sid = v_app_sid
					AND f.factor_type_id = in_factor_type_id
					AND f.region_sid IS NULL
					AND NVL(f.is_virtual,0) = 0
				) std
				WHERE reg.geo_country = std.geo_country (+)
				  AND reg.geo_region = std.geo_region (+)
				ORDER BY reg.geo_region -- C# rely on that
		)
		 UNION
		SELECT geo_country, egrid_ref, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected FROM (
			SELECT reg.geo_country, reg.egrid_ref, reg.name, std.std_factor_id, std.std_factor_set_id, std.factor_id, std.region_sid ,std.is_selected
			  FROM ( 
					SELECT 'us' geo_country, e.egrid_ref, e.name
					  FROM egrid e
					  JOIN region r ON e.egrid_ref = r.egrid_ref
					 CROSS JOIN factor_type ft
					 WHERE in_geo_country = 'us'
					   AND r.app_sid = v_app_sid
					   AND ft.factor_type_id = in_factor_type_id
					   AND ft.egrid = 1
			) reg,
			   (
				SELECT DISTINCT sf.std_factor_id, sf.std_factor_set_id, sf.geo_country, sf.egrid_ref, f.factor_id, f.is_selected, f.region_sid
				  FROM std_factor sf
				  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id AND sfs.published = 1
				  LEFT JOIN (
					SELECT *
					  FROM factor f 
					 WHERE f.region_sid IS NULL
					   AND NVL(f.is_virtual,0) = 0
				) f ON sf.std_factor_id  = f.std_factor_id
				 WHERE sf.egrid_ref IS NOT NULL 
				   AND sf.factor_type_id = in_factor_type_id
				UNION ALL -- get bespoke and parent values
				 SELECT sf.std_factor_id, sf.std_factor_set_id, f.geo_country, f.egrid_ref, f.factor_id, f.is_selected, f.region_sid
				   FROM factor f
				   LEFT JOIN (
					SELECT sf.std_factor_id, sf.std_factor_set_id
					  FROM std_factor sf
					  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
					 WHERE sfs.published = 1
				) sf ON f.std_factor_id = sf.std_factor_id
				  WHERE f.geo_region IS NOT NULL OR f.egrid_ref IS NOT NULL
					AND f.factor_type_id = in_factor_type_id
					AND f.region_sid IS NULL
					AND NVL(f.is_virtual,0) = 0
				) std
				WHERE reg.geo_country = std.geo_country (+)
				  AND reg.egrid_ref = std.egrid_ref (+)
				ORDER BY reg.egrid_ref -- C# rely on that
		)
		
	UNION ALL  
		--get overrides   	
		SELECT geo_country, geo_region, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected
		FROM
		(
			SELECT f.geo_country, f.geo_region, f.name, f.std_factor_id, sf.std_factor_set_id, f.factor_id, f.region_sid, f.is_selected
			  FROM (
				SELECT f.geo_country, f.geo_region, r.description name, f.std_factor_id, f.factor_id, f.region_sid, f.is_selected
				  FROM factor f, v$region r  
				 WHERE f.region_sid = r.region_sid 
				   AND f.app_sid = v_app_sid
				   AND factor_type_id = in_factor_type_id
				   AND f.geo_country = in_geo_country
				   AND f.geo_region IS NULL
				   AND f.egrid_ref IS NULL
				   AND NVL(f.is_virtual,0) = 0
			  ) f
			  LEFT JOIN (
				SELECT sf.std_factor_id, sf.std_factor_set_id
				  FROM std_factor sf
				  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
				 WHERE sfs.published = 1
			  ) sf ON f.std_factor_id = sf.std_factor_id
			 ORDER BY f.region_sid -- C# rely on that
		);
END;

PROCEDURE GetRegionFactorsMap(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,	
	in_geo_region			IN factor.geo_region%TYPE,	
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_root_sid		security_pkg.T_SID_ID;	
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	-- REGION LEVEL - displays only overrides for non geo regions under this region and possible std and bespoke factors 

	OPEN out_cur FOR
		SELECT geo_country, geo_region, name, std_factor_id, std_factor_set_id, factor_id, region_sid, is_selected
		FROM
		(
			SELECT f.geo_country, f.geo_region, f.name, f.std_factor_id, sf.std_factor_set_id, f.factor_id, f.region_sid, f.is_selected
			  FROM (
				SELECT f.geo_country, f.geo_region, r.description name, f.std_factor_id, f.factor_id, f.region_sid, f.is_selected
				  FROM factor f, v$region r  
				 WHERE f.region_sid = r.region_sid 
				   AND f.app_sid = v_app_sid
				   AND factor_type_id = in_factor_type_id
				   AND f.geo_country = in_geo_country
				   AND NVL(f.geo_region, f.egrid_ref) = in_geo_region
				   AND NVL(f.is_virtual,0) = 0
			) f
			  LEFT JOIN (
				SELECT sf.std_factor_id, sf.std_factor_set_id
				  FROM std_factor sf
				  JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
				 WHERE sfs.published = 1
			  ) sf ON f.std_factor_id = sf.std_factor_id
			 ORDER BY f.region_sid -- C# rely on that
 		);
END;


PROCEDURE GetFactorTypes(
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');		
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	--TODO add join with indicators 
	OPEN out_cur FOR 
		 SELECT ft.factor_type_id, TRIM(ft.name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(ft.name), ' > '),' > ') path, ft.visible, ft.info_note
		   FROM factor_type ft
		  WHERE parent_id IS NOT NULL
		  START WITH ft.parent_id IS NULL
		CONNECT BY PRIOR ft.factor_type_id = ft.parent_id
		  ORDER SIBLINGS BY ft.name;
END;

PROCEDURE GetVisibleFactorTypes(
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');		
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR 
		 SELECT ft.factor_type_id, TRIM(ft.name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(ft.name), ' > '),' > ') path, m.name measure, ft.egrid, ft.info_note
		   FROM factor_type ft
		   LEFT JOIN std_measure m ON ft.std_measure_id = m.std_measure_id
		  WHERE parent_id IS NOT NULL
		  AND ft.visible = 1
		  START WITH ft.parent_id IS NULL
		CONNECT BY PRIOR ft.factor_type_id = ft.parent_id
		  ORDER SIBLINGS BY ft.name;
END;


PROCEDURE GetAvailableStdFactorSets(
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');		
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	-- This SP is only used by the Profile (ie new) EF tool.
	OPEN out_cur FOR
		SELECT fs.std_factor_set_id, fs.name, published_dtm, fsg.name factor_set_group, fs.info_note, published, visible
		  FROM std_factor_set fs
		  JOIN factor_set_group fsg ON fs.factor_set_group_id = fsg.factor_set_group_id
		 WHERE published = 1	
		   AND visible = 1
		 ORDER BY name;
END;

PROCEDURE DeleteRegionOverrides(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_sids					IN	security_pkg.T_SID_IDS
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_sids 		security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;

	t_sids := security_pkg.SidArrayToTable(in_sids);

	FOR r IN (SELECT * FROM TABLE(t_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write permission denied on the region with sid ' || r.column_value);
		END IF;
	END LOOP;

	DELETE FROM factor 
	 WHERE app_sid = v_app_sid
	   AND factor_type_id = in_factor_type_id
	   AND region_sid IN (SELECT *
	   						FROM TABLE(t_sids));
	
	-- write calc jobs
	calc_pkg.AddJobsForFactorType(in_factor_type_id);
END;

PROCEDURE UpdateSelectedSetForApp(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE
)
AS
	v_factor_start_month	NUMBER(2);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	SELECT DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month
	  INTO v_factor_start_month
	  FROM customer
	 WHERE app_sid = in_app_sid;
	
	--copy standard factor values to factor table
	--this duplication of select query because WITH AS doesn't work on my oracle
	INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country, 
			geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
			std_measure_conversion_id, note, region_sid, is_selected)
	SELECT in_app_sid, FACTOR_ID_SEQ.nextval factor_id, in_factor_type_id, gas_type_id,
				geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
				std_measure_conversion_id, note, NULL, 1 is_selected
	  FROM (
			SELECT sf.factor_type_id, gas_type_id,
					geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
					std_measure_conversion_id, note, priority
			 FROM (
					(
						SELECT factor_type_id, gas_type_id,
							geo_country, geo_region, egrid_ref, std_factor_id,
							TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY') start_dtm,
							CASE
								WHEN end_dtm IS NULL THEN NULL
								ELSE ADD_MONTHS(TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(end_dtm, start_dtm))
							END end_dtm,
							value, std_measure_conversion_id, note
						  FROM std_factor 
						 WHERE std_factor_set_id = in_std_factor_set_id
						   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
						   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
					) sf
					JOIN
					(
						SELECT factor_type_id, level priority
						  FROM factor_type
						 START WITH factor_type_id = in_factor_type_id
						CONNECT BY PRIOR parent_id = factor_type_id
					) ft
					ON sf.factor_type_id = ft.factor_type_id
			)
	)
	 WHERE priority = (
			SELECT min(priority)
			  FROM (
					SELECT priority
					 FROM (
							(
								SELECT factor_type_id
								  FROM std_factor 
								 WHERE std_factor_set_id = in_std_factor_set_id
								   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
								   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
							) sf
							JOIN
							(
								SELECT factor_type_id, level priority
								  FROM factor_type
								 START WITH factor_type_id = in_factor_type_id
								CONNECT BY PRIOR parent_id = factor_type_id
							) ft
							ON sf.factor_type_id = ft.factor_type_id
					)
			)
	);
	
	-- write calc jobs
	calc_pkg.AddJobsForFactorType(in_factor_type_id);
END;

PROCEDURE UpdateSelectedSet(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,	
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE,	
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_count		NUMBER(10);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	--delete existing copies of standard factors
	--delete existing copies of propagated factors
	DELETE FROM factor 
		WHERE app_sid = v_app_sid
		  AND factor_type_id = in_factor_type_id
		  AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
		  AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
		  AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
		  AND (std_factor_id IS NOT NULL OR original_factor_id IS NOT NULL);

	--clear existing selection
	UPDATE factor
	   SET is_selected = 0
	 WHERE app_sid = v_app_sid
	   AND factor_type_id = in_factor_type_id
	   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
	   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
	   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid);
			  	  
	IF in_std_factor_set_id > 0 THEN
		UpdateSelectedSetForApp(v_app_sid, in_factor_type_id, in_geo_country, in_geo_region, in_std_factor_set_id);		
	ELSIF in_std_factor_set_id = 0 THEN
		-- selected set is bespoke
		SELECT COUNT(*)
		  INTO v_count
		  FROM factor
		 WHERE app_sid = v_app_sid
		   AND factor_type_id = in_factor_type_id
		   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
		   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
		   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
		   AND std_factor_id IS NULL
		   AND original_factor_id IS NULL;
		   
		IF v_count > 0 THEN
			UPDATE factor
			   SET is_selected = 1
			 WHERE app_sid = v_app_sid
			   AND factor_type_id = in_factor_type_id
			   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
			   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
			   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
			   AND std_factor_id IS NULL;
		ELSE
			DELETE FROM factor
			 WHERE app_sid = v_app_sid
			   AND factor_type_id = in_factor_type_id
			   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
			   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
			   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
			   AND std_factor_id IS NULL;
			   
			INSERT INTO factor (app_sid, factor_id, factor_type_id, gas_type_id, geo_country, 
						geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
						std_measure_conversion_id, note, region_sid, original_factor_id, is_selected)
			SELECT app_sid, FACTOR_ID_SEQ.nextval, in_factor_type_id, gas_type_id, geo_country,
					geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value,
					std_measure_conversion_id, note, region_sid, factor_id, 1 is_selected
			  FROM (
					SELECT app_sid, gas_type_id, geo_country,
							geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value,
							std_measure_conversion_id, note, region_sid, factor_id, priority
					  FROM (
							(
								SELECT factor_type_id, app_sid, gas_type_id, geo_country,
										geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value,
										std_measure_conversion_id, note, region_sid, factor_id
								  FROM factor f
								 WHERE std_factor_id is null
								   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
							       AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
								   AND app_sid = v_app_sid
							) f
							JOIN
							(
								SELECT factor_type_id, level priority
								  FROM factor_type
								 START WITH factor_type_id = in_factor_type_id
								CONNECT BY PRIOR parent_id = factor_type_id
							) ft ON f.factor_type_id = ft.factor_type_id
					)
			)
			 WHERE priority = (
					SELECT min(priority)
					  FROM (
							SELECT priority
							  FROM (
									(
										SELECT factor_type_id
										  FROM factor f
										 WHERE std_factor_id is null
										   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
										   AND ((in_geo_region IS NULL AND geo_region IS NULL AND egrid_ref IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
										   AND app_sid = v_app_sid
									) f
									JOIN
									(
										SELECT factor_type_id, level priority
										  FROM factor_type
										 START WITH factor_type_id = in_factor_type_id
										CONNECT BY PRIOR parent_id = factor_type_id
									) ft ON f.factor_type_id = ft.factor_type_id
							)
					)
			);
			
		END IF;
	END IF;
	
	-- write calc jobs
	calc_pkg.AddJobsForFactorType(in_factor_type_id);
END;

-- factor type tree procedures
PROCEDURE GetTreeWithDepth(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_fetch_depth			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT factor_type_id sid_id, parent_id parent_sid_id, name, info_note, LEVEL so_level, 
			   CASE WHEN std_measure_id IS NULL THEN 0 ELSE CONNECT_BY_ISLEAF END is_leaf,
			   1 is_match,
			   std_measure_id, mapped, enabled, visible
		  FROM v$factor_type
		 WHERE LEVEL <= in_fetch_depth
		   AND (in_display_active_only = 0 OR (active = 1))
		   AND (in_display_used_only = 0 OR (in_use = 1))
		   AND (in_display_mapped_only = 0 OR (mapped = 1))
		   AND (in_display_disabled = 1 OR (enabled = 1))
		 START WITH (in_include_root = 0 AND parent_id = in_parent_sid) OR 
					(in_include_root = 1 AND factor_type_id = in_parent_sid)		 
		CONNECT BY PRIOR factor_type_id = parent_id
		 ORDER SIBLINGS BY name;
END;

PROCEDURE GetTreeWithSelect(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_select_sid			IN	security_pkg.T_SID_ID,
	in_fetch_depth			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT factor_type_id sid_id, parent_id parent_sid_id, name, LEVEL so_level, 
			   CASE WHEN std_measure_id IS NULL THEN 0 ELSE CONNECT_BY_ISLEAF END is_leaf,
			   1 is_match,
			   std_measure_id, mapped, enabled, info_note, visible
		  FROM v$factor_type
		 WHERE (LEVEL <= in_fetch_depth
		 	OR parent_id IN (
				SELECT factor_type_id
		 		  FROM factor_type
				 START WITH factor_type_id = in_select_sid
				CONNECT BY PRIOR parent_id = factor_type_id
				)
			)
		   AND (in_display_active_only = 0 OR (active = 1))
		   AND (in_display_used_only = 0 OR (in_use = 1))
		   AND (in_display_mapped_only = 0 OR (mapped = 1))
		   AND (in_display_disabled = 1 OR (enabled = 1))
		 START WITH (in_include_root = 0 AND parent_id = in_parent_sid) OR 
				  (in_include_root = 1 AND factor_type_id = in_parent_sid)
		CONNECT BY PRIOR factor_type_id = parent_id
		 ORDER SIBLINGS BY name;
END;

PROCEDURE GetTreeTextFiltered(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_include_root			IN	NUMBER,
	in_search_phrase		IN	VARCHAR2,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT ft.factor_type_id sid_id, ft.parent_id parent_sid_id, ft.name, LEVEL so_level, 
			   CASE WHEN std_measure_id IS NULL THEN 0 ELSE CONNECT_BY_ISLEAF END is_leaf,
			   NVL(tm.is_match,0) is_match,
			   std_measure_id, mapped, enabled, ft.info_note, ft.visible
		  FROM v$factor_type ft, (
				  SELECT DISTINCT ft_t.factor_type_id
					FROM factor_type ft_t
					     START WITH ft_t.factor_type_id IN (
							SELECT DISTINCT ft2.factor_type_id 
							  FROM factor_type ft2
							 WHERE LOWER(ft2.name) LIKE '%'||LOWER(in_search_phrase)||'%'
					 			   START WITH (in_include_root = 0 AND ft2.parent_id = in_parent_sid) OR 
					 						  (in_include_root = 1 AND ft2.factor_type_id = in_parent_sid)
						   		   CONNECT BY PRIOR ft2.factor_type_id = ft2.parent_id)
				 		 CONNECT BY ft_t.factor_type_id = PRIOR ft_t.parent_id
			   ) t,(
				  SELECT DISTINCT ft_tm.factor_type_id, 1 is_match 
				    FROM factor_type ft_tm
				   WHERE LOWER(ft_tm.name) LIKE '%'||LOWER(in_search_phrase)||'%'
		 			     START WITH (in_include_root = 0 AND ft_tm.parent_id = in_parent_sid) OR 
		 						    (in_include_root = 1 AND ft_tm.factor_type_id = in_parent_sid)
			     		 CONNECT BY PRIOR ft_tm.factor_type_id = ft_tm.parent_id
			   ) tm
		 WHERE ft.factor_type_id = t.factor_type_id
		   AND ft.factor_type_id = tm.factor_type_id (+)
		   AND (in_display_active_only = 0 OR (active = 1))
		   AND (in_display_used_only = 0 OR (in_use = 1))
		   AND (in_display_mapped_only = 0 OR (mapped = 1))
		   AND (in_display_disabled = 1 OR (enabled = 1))
		 START WITH (in_include_root = 0 AND ft.parent_id = in_parent_sid) OR 
				  (in_include_root = 1 AND ft.factor_type_id = in_parent_sid)
		CONNECT BY PRIOR ft.factor_type_id = ft.parent_id
		 ORDER SIBLINGS BY ft.name;
	
END;


PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_limit			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT ft.factor_type_id sid_id, ft.parent_id parent_sid_id, ft.name, LEVEL so_level, 
			   CASE WHEN std_measure_id IS NULL THEN 0 ELSE CONNECT_BY_ISLEAF END is_leaf,
			   1 is_match,
			   LTRIM(SYS_CONNECT_BY_PATH(TRIM(ft.name), ' > '),' > ') path,
			   std_measure_id, mapped, enabled, ft.info_note, ft.visible
		  FROM v$factor_type ft
		 WHERE rownum <= in_limit
		   AND (in_display_used_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND in_use = 1))
		   AND (in_display_active_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND active = 1))
		   AND (in_display_mapped_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND mapped = 1))
		   AND (in_display_disabled = 1 OR (CONNECT_BY_ISLEAF = 1 AND enabled = 1))
		 START WITH (in_include_root = 0 AND ft.parent_id = in_root_sid) OR 
				  (in_include_root = 1 AND ft.factor_type_id = in_root_sid)
		CONNECT BY PRIOR ft.factor_type_id = ft.parent_id
		 ORDER SIBLINGS BY ft.name;
END;


PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_display_used_only	IN	NUMBER,
	in_display_active_only	IN	NUMBER,
	in_display_mapped_only	IN	NUMBER,
	in_display_disabled		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR	   
		SELECT ft.factor_type_id sid_id, ft.parent_id parent_sid_id, ft.name, LEVEL so_level, 
			   CASE WHEN std_measure_id IS NULL THEN 0 ELSE CONNECT_BY_ISLEAF END is_leaf,
			   1 is_match,
			   LTRIM(SYS_CONNECT_BY_PATH(TRIM(ft.name), ' > '),' > ') path,
			   std_measure_id, mapped, enabled, ft.info_note, ft.visible
		  FROM v$factor_type ft
		 WHERE rownum <= in_limit
		   AND LOWER(ft.name) LIKE '%'||LOWER(in_search_phrase)||'%'
		   AND (in_display_used_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND in_use = 1))
		   AND (in_display_active_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND active = 1))
		   AND (in_display_mapped_only = 0 OR (CONNECT_BY_ISLEAF = 1 AND mapped = 1))
		   AND (in_display_disabled = 1 OR (CONNECT_BY_ISLEAF = 1 AND enabled = 1))
		 START WITH (in_include_root = 0 AND ft.parent_id = in_root_sid) OR 
				  (in_include_root = 1 AND ft.factor_type_id = in_root_sid)
		 CONNECT BY PRIOR ft.factor_type_id = ft.parent_id
		 ORDER SIBLINGS BY ft.name;
END;

-- end

FUNCTION GetRootFactorTypeSid RETURN security_pkg.T_SID_ID
AS
	v_root_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	SELECT MAX(factor_type_id) INTO v_root_sid 
	  FROM factor_type 
	 WHERE parent_id IS NULL;
	RETURN v_root_sid;
END;

FUNCTION GetFactorTypeNameBySid 
(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
) RETURN factor_type.name%TYPE
AS
	v_name	factor_type.name%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	SELECT name INTO v_name 
	  FROM factor_type
	 WHERE factor_type_id = in_factor_type_id;
	RETURN v_name;
END;


FUNCTION GetStdSetName
(
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE
) RETURN std_factor_set.name%TYPE
AS
	v_name	std_factor_set.name%TYPE;	
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	SELECT name INTO v_name FROM std_factor_set WHERE std_factor_set_id = in_std_factor_set_id;
	
	RETURN v_name;
END;




PROCEDURE GetNonGeoRegionTreeRoots(
	in_geo_country	IN	factor.geo_country%TYPE,
	in_geo_region	IN	factor.geo_region%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_main	factor.region_sid%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;
	
	SELECT region_tree_root_sid
	  INTO v_main
	  FROM region_tree
	 WHERE is_primary = 1;
	
	OPEN out_cur FOR
		WITH main_region AS (
			SELECT app_sid, region_sid, parent_sid, geo_country, geo_region, egrid_ref 
			  FROM region
			 START WITH region_sid = v_main
		   CONNECT BY PRIOR region_sid = parent_sid
		)
		SELECT r.region_sid
		  FROM main_region r
		  JOIN main_region p ON r.parent_sid = p.region_sid AND r.app_sid = p.app_sid
		 WHERE r.geo_country = in_geo_country
		   AND ((r.geo_region IS NULL AND in_geo_region IS NULL) OR r.geo_region = in_geo_region OR r.egrid_ref = in_geo_region)
		   AND (p.geo_country IS NULL OR p.geo_country != r.geo_country OR (r.geo_region IS NOT NULL AND p.geo_region IS NULL) OR p.geo_region != r.geo_region)
		   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;




-- tree handlers for non region tree picker
PROCEDURE GetNonRegionTreeWithDepth(
	in_act_id   	IN  security_pkg.T_ACT_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS,
	in_include_root	IN	NUMBER,
	in_fetch_depth	IN	NUMBER,
	in_factor_id	IN	factor_type.factor_type_id%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_region_sids	security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (SELECT * FROM TABLE(t_region_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || r.column_value);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_match, CONNECT_BY_ISLEAF is_leaf
		  FROM (
			SELECT sid_id, parent_sid_id, name, so_level, is_match, include_all
			  FROM (
					SELECT r.region_sid sid_id, r.parent_sid parent_sid_id, r.description name, LEVEL so_level,
							 1 is_match, geo_region,
							 CONNECT_BY_ROOT geo_region root_geo_region,
							 CASE
								WHEN
									CONNECT_BY_ROOT geo_country = 'us' AND
									CONNECT_BY_ROOT geo_region IS NULL AND
									1 = (SELECT egrid FROM factor_type where factor_type_id = in_factor_id)
								THEN 1 ELSE 0
							END include_all
					  FROM v$region r
					 START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t_region_sids))) OR 
							 (in_include_root = 1 AND region_sid IN (SELECT column_value from TABLE(t_region_sids)))
					CONNECT BY PRIOR region_sid = parent_sid
					 ORDER SIBLINGS BY LOWER(description)
			)
			 WHERE (
					root_geo_region IS NOT NULL
					OR geo_region IS NULL
					OR include_all = 1
			)
		)
		 WHERE so_level <= in_fetch_depth OR include_all = 1
		 START WITH (in_include_root = 0 AND parent_sid_id IN (SELECT column_value from TABLE(t_region_sids))) OR 
			 	(in_include_root = 1 AND sid_id IN (SELECT column_value from TABLE(t_region_sids)))
		CONNECT BY PRIOR sid_id = parent_sid_id;
END;

PROCEDURE GetNonRegionTreeTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_factor_id	IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_region_sids	security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (SELECT * FROM TABLE(t_region_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || r.column_value);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_match, CONNECT_BY_ISLEAF is_leaf
		  FROM (
				SELECT sid_id, parent_sid_id, name, so_level, is_match
				  FROM (
						SELECT r.region_sid sid_id, r.parent_sid parent_sid_id, r.description name, LEVEL so_level, 
							   NVL(tm.is_match,0) is_match, geo_region,
							   CONNECT_BY_ROOT geo_country root_geo_country, CONNECT_BY_ROOT geo_region root_geo_region
						  FROM v$region r,
							(
							  SELECT DISTINCT region_sid
								FROM region
							   START WITH region_sid IN (
										SELECT DISTINCT tmp.region_sid 
										  FROM v$region tmp
										 WHERE LOWER(tmp.description) LIKE '%'||LOWER(in_search_phrase)||'%'
										 START WITH tmp.region_sid IN (SELECT * from TABLE(t_region_sids))
									   CONNECT BY PRIOR tmp.region_sid = tmp.parent_sid
									)
							 CONNECT BY region_sid =  PRIOR parent_sid
							)t,
							(
							  SELECT DISTINCT region_sid, 1 is_match 
								FROM v$region
							   WHERE LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
							   START WITH region_sid IN (SELECT * from TABLE(t_region_sids))
							 CONNECT BY PRIOR region_sid = parent_sid
							)tm
						WHERE r.region_sid = t.region_sid
						  AND r.region_sid = tm.region_sid (+)
						START WITH (in_include_root = 0 AND r.parent_sid IN (SELECT column_value from TABLE(t_region_sids))) OR 
								   (in_include_root = 1 AND r.region_sid IN (SELECT column_value from TABLE(t_region_sids)))
						CONNECT BY PRIOR r.region_sid = r.parent_sid
						ORDER SIBLINGS BY LOWER(r.description)
				)
				 WHERE (
					root_geo_region IS NOT NULL
					OR geo_region IS NULL
					OR (root_geo_country = 'us' AND root_geo_region IS NULL AND 1 = (SELECT egrid FROM factor_type where factor_type_id = in_factor_id))
			)
		)
		 START WITH (in_include_root = 0 AND parent_sid_id IN (SELECT column_value from TABLE(t_region_sids))) OR 
			 	(in_include_root = 1 AND sid_id IN (SELECT column_value from TABLE(t_region_sids)))
		CONNECT BY PRIOR sid_id = parent_sid_id;
END;


PROCEDURE GetNonRegionList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_limit			IN	NUMBER,
	in_factor_id	IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_region_sids	security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (SELECT * FROM TABLE(t_region_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || r.column_value);
		END IF;
	END LOOP;

	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_match, CONNECT_BY_ISLEAF is_leaf, path
		  FROM (
				SELECT sid_id, parent_sid_id, name, so_level, is_match, path
				  FROM (
						SELECT r.region_sid sid_id, r.parent_sid parent_sid_id, r.description name, LEVEL so_level,
							   1 is_match, geo_region,
							   LTRIM(SYS_CONNECT_BY_PATH(TRIM(r.description), ' > '),' > ') path,
							   CONNECT_BY_ROOT geo_country root_geo_country, CONNECT_BY_ROOT geo_region root_geo_region
						  FROM v$region r
						 START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t_region_sids))) OR 
								   (in_include_root = 1 AND region_sid IN (SELECT column_value from TABLE(t_region_sids)))
					   CONNECT BY PRIOR r.region_sid = r.parent_sid
						 ORDER SIBLINGS BY LOWER(r.description)
				)
				WHERE (
					root_geo_region IS NOT NULL
					OR geo_region IS NULL
					OR (root_geo_country = 'us' AND root_geo_region IS NULL AND 1 = (SELECT egrid FROM factor_type where factor_type_id = in_factor_id))
			)
		)
		 WHERE rownum <= in_limit
		 START WITH (in_include_root = 0 AND parent_sid_id IN (SELECT column_value from TABLE(t_region_sids))) OR 
			 	(in_include_root = 1 AND sid_id IN (SELECT column_value from TABLE(t_region_sids)))
		CONNECT BY PRIOR sid_id = parent_sid_id;
END;


PROCEDURE GetNonRegionListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_factor_id		IN	factor_type.factor_type_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid		security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_region_sids	security.T_SID_TABLE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	t_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (SELECT * FROM TABLE(t_region_sids))
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || r.column_value);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, name, so_level, is_match, CONNECT_BY_ISLEAF is_leaf, path
		  FROM (
				SELECT sid_id, parent_sid_id, name, so_level, is_match, path
				  FROM (
						SELECT r.region_sid sid_id, r.parent_sid parent_sid_id, TRIM(r.description) name, LEVEL so_level,
							   1 is_match, geo_region,
							   LTRIM(SYS_CONNECT_BY_PATH(TRIM(r.description), ' > '),' > ') path,
							   CONNECT_BY_ROOT geo_country root_geo_country, CONNECT_BY_ROOT geo_region root_geo_region
						  FROM v$region r
						 START WITH (in_include_root = 0 AND parent_sid IN (SELECT column_value from TABLE(t_region_sids))) OR 
								   (in_include_root = 1 AND region_sid IN (SELECT column_value from TABLE(t_region_sids)))
					   CONNECT BY PRIOR r.region_sid = r.parent_sid
						 ORDER SIBLINGS BY LOWER(r.description)
				)
				 WHERE (
					root_geo_region IS NOT NULL
					OR geo_region IS NULL
					OR (root_geo_country = 'us' AND root_geo_region IS NULL AND 1 = (SELECT egrid FROM factor_type where factor_type_id = in_factor_id))
			)
		)
		 WHERE rownum <= in_limit
		   AND LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%'
		 START WITH (in_include_root = 0 AND parent_sid_id IN (SELECT column_value from TABLE(t_region_sids))) OR 
			 	(in_include_root = 1 AND sid_id IN (SELECT column_value from TABLE(t_region_sids)))
		CONNECT BY PRIOR sid_id = parent_sid_id;
END;

PROCEDURE CheckExistStdFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 AND NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT std_factor_id,
		CASE WHEN in_start_dtm = start_dtm AND (in_end_dtm = end_dtm OR (in_end_dtm IS NULL AND end_dtm IS NULL)) THEN 1
			ELSE 0
		END dates_match
		  FROM std_factor
		 WHERE std_factor_set_id = in_std_factor_set_id
		   AND factor_type_id = in_factor_type_id
		   AND gas_type_id = in_gas_type_id
		   AND ((geo_country IS NULL AND in_geo_country IS NULL) OR geo_country = in_geo_country)
		   AND ((geo_region IS NULL AND egrid_ref IS NULL AND in_geo_region IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
		   -- Overlapping dates
			AND ((
			  in_start_dtm >= start_dtm and (in_start_dtm < end_dtm or end_dtm is null)
			)
			OR (
			  in_start_dtm < start_dtm and (in_end_dtm > start_dtm or in_end_dtm is null)
			));
END;

PROCEDURE CheckExistBespokeFactor(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_gas_type_id			IN std_factor.gas_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT factor_id
		  FROM factor
		 WHERE app_sid = in_app_sid
		   AND std_factor_id IS NULL
		   AND factor_type_id = in_factor_type_id
		   AND gas_type_id = in_gas_type_id
		   AND ((geo_country IS NULL AND in_geo_country IS NULL) OR geo_country = in_geo_country)
		   AND ((geo_region IS NULL AND egrid_ref IS NULL AND in_geo_region IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
		   AND start_dtm = in_start_dtm;
END;

PROCEDURE GetSelectedChildrenStdFactor(
	in_std_factor_id		IN std_factor.std_factor_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT UNIQUE(ft.factor_type_id), priority --, sf.std_factor_set_id, sf.geo_country, sf.geo_region, sf.egrid_ref, priority
		  FROM (
			SELECT std_factor_set_id, std_factor_id, factor_type_id, geo_country, geo_region, egrid_ref
			  FROM std_factor
			  WHERE std_factor_id = in_std_factor_id
		) sf
		JOIN (
			SELECT factor_type_id, CONNECT_BY_ROOT factor_type_id root_id, LEVEL priority
			  FROM factor_type
			CONNECT BY PRIOR factor_type_id = parent_id
		) ft ON sf.factor_type_id = ft.root_id
		JOIN (
			SELECT factor_id, std_factor_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref
			  FROM factor
			 WHERE is_selected = 1
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) f ON ft.factor_type_id = f.factor_type_id
			AND ((sf.geo_country IS NULL AND f.geo_country IS NULL) OR sf.geo_country = f.geo_country)
			AND ((sf.geo_region IS NULL AND f.geo_region IS NULL AND sf.egrid_ref IS NULL AND f.egrid_ref IS NULL) OR sf.geo_region = f.geo_region OR sf.egrid_ref = f.geo_region)
		WHERE sf.factor_type_id != ft.factor_type_id
		ORDER BY priority;
END;

PROCEDURE GetSelectedChildrenFactor(
	in_factor_id			IN factor.factor_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT UNIQUE(ft.factor_type_id), priority
		  FROM (
			SELECT factor_id, factor_type_id, geo_country, geo_region, egrid_ref
			  FROM factor
			  WHERE factor_id = in_factor_id
			  AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) fo
		JOIN (
			SELECT factor_type_id, CONNECT_BY_ROOT factor_type_id root_id, LEVEL priority
			  FROM factor_type
			CONNECT BY PRIOR factor_type_id = parent_id
		) ft ON fo.factor_type_id = ft.root_id
		JOIN (
			SELECT factor_id, std_factor_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref
			  FROM factor
			 WHERE is_selected = 1
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) f ON ft.factor_type_id = f.factor_type_id
			AND ((fo.geo_country IS NULL AND f.geo_country IS NULL) OR fo.geo_country = f.geo_country)
			AND ((fo.geo_region IS NULL AND f.geo_region IS NULL AND fo.egrid_ref IS NULL AND f.egrid_ref IS NULL) OR fo.geo_region = f.geo_region OR fo.egrid_ref = f.geo_region)
		WHERE fo.factor_type_id != ft.factor_type_id
		ORDER BY priority;
END;


PROCEDURE GetUsedGasFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT ft.name factor, ft.path factor_path, gt.name gas, f.value, f.start_dtm, f.end_dtm, f.note,
				smc.description unit, pc.name country, pr.name region, e.name egrid, r.description local_region, f.region_sid, sfs.name factor_set
		  FROM (
			SELECT UNIQUE fi.factor_type_id, fi.gas_type_id FROM (
				SELECT fi.factor_type_id, fi.gas_type_id, (
					select NVL(MIN(active),0) active -- Find out if indicator is active.
					from ind ii
					start with ii.ind_sid = fi.ind_sid
					connect by prior ii.parent_sid = ii.ind_sid
					) active
				  FROM ind fi
				 WHERE fi.ind_sid NOT IN ( -- filter out deleted indicators
					SELECT ti.ind_sid
					  FROM ind ti
					 START WITH ti.parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = in_app_sid)
					CONNECT BY PRIOR ti.ind_sid = ti.parent_sid
					)
				) fi
			 WHERE fi.active != 0 -- filter out inactive indicators
			) i
		  JOIN (
				SELECT factor_type_id, TRIM(name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(name), '>>>'), '>>>') path
				  FROM factor_type
				 WHERE parent_id IS NOT NULL
				 START WITH parent_id IS NULL
				CONNECT BY PRIOR factor_type_id = parent_id
				) ft ON i.factor_type_id = ft.factor_type_id
		  JOIN gas_type gt ON i.gas_type_id = gt.gas_type_id
		  JOIN factor f ON ft.factor_type_id = f.factor_type_id AND gt.gas_type_id = f.gas_type_id
		  JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN std_factor sf ON f.std_factor_id = sf.std_factor_id
		  LEFT JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
		  LEFT JOIN postcode.country pc ON f.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON pc.country = pr.country AND f.geo_region = pr.region
		  LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref
		  LEFT JOIN v$region r ON f.region_sid = r.region_sid
		 WHERE f.is_selected = 1
		   AND f.app_sid = in_app_sid
		 ORDER BY country, region, egrid, local_region, region_sid, factor_path, factor, gas, start_dtm, end_dtm;
END;

FUNCTION GetFactorTypeName(
	in_factor_type_id			IN factor_type.factor_type_id%TYPE
) RETURN factor_type.name%TYPE
AS
	v_factor_type		factor_type.name%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	SELECT ft.name
	  INTO v_factor_type
	  FROM factor_type ft
	 WHERE ft.factor_type_id = in_factor_type_id;
	
	RETURN v_factor_type;
END;

PROCEDURE GetGasFactorListForInd(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_ind_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT f.value, smc.description unit, f.start_dtm,
			NVL(pc.name, 'Worldwide') country, NVL(e.name, pr.name) region, r.description region_override
		  FROM ind i
		  JOIN factor f ON i.factor_type_id = f.factor_type_id AND i.gas_type_id = f.gas_type_id AND i.app_sid = f.app_sid
		  JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN postcode.country pc ON f.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON f.geo_country = pr.country AND f.geo_region = pr.region
		  LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref
		  LEFT JOIN v$region r ON f.region_sid = r.region_sid AND f.app_sid = r.app_sid
		 WHERE i.ind_sid = in_ind_sid
		   AND f.is_selected = 1
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY country, region, region_override, start_dtm;
END;

PROCEDURE GetGasFactorListForInd(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm			IN	factor.start_dtm%TYPE,
	in_end_dtm				IN	factor.end_dtm%TYPE,
	in_geo_countries		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_geo_regions			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_geo_countries_cnt			NUMBER;
	v_geo_regions_cnt			NUMBER;
	v_geo_countries_table		security.T_VARCHAR2_TABLE := security.T_VARCHAR2_TABLE();
	v_geo_regions_table			security.T_VARCHAR2_TABLE := security.T_VARCHAR2_TABLE();
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_ind_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on indicator '||in_ind_sid);
	END IF;
	
	IF in_geo_countries.COUNT = 0 OR (in_geo_countries.COUNT = 1 AND in_geo_countries(in_geo_countries.FIRST) IS NULL) THEN
		v_geo_countries_cnt := 0;
	ELSE
		v_geo_countries_cnt := in_geo_countries.COUNT;
		v_geo_countries_table := security.security_pkg.Varchar2ArrayToTable(in_geo_countries);
	END IF;
	
	IF in_geo_regions.COUNT = 0 OR (in_geo_regions.COUNT = 1 AND in_geo_regions(in_geo_regions.FIRST) IS NULL) THEN
		v_geo_regions_cnt := 0;
	ELSE
		v_geo_regions_cnt := in_geo_regions.COUNT;
		v_geo_regions_table := security.security_pkg.Varchar2ArrayToTable(in_geo_regions);
	END IF;
	
	OPEN out_cur FOR
		SELECT f.value, smc.description unit, f.start_dtm,
			NVL(pc.name, 'Worldwide') country, NVL(e.name, pr.name) region, r.description region_override, NVL(stdfs.name, cfs.name) factor_set_name
		  FROM ind i
		  JOIN factor f ON i.factor_type_id = f.factor_type_id AND i.gas_type_id = f.gas_type_id AND i.app_sid = f.app_sid
		  JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		  LEFT JOIN postcode.country pc ON f.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON f.geo_country = pr.country AND f.geo_region = pr.region
		  LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref
		  LEFT JOIN v$region r ON f.region_sid = r.region_sid AND f.app_sid = r.app_sid
		  LEFT JOIN std_factor stdf ON stdf.std_factor_id = f.std_factor_id
		  LEFT JOIN custom_factor cf ON cf.custom_factor_id = f.custom_factor_id
		  LEFT JOIN std_factor_set stdfs on stdfs.std_factor_set_id = stdf.std_factor_set_id
		  LEFT JOIN custom_factor_set cfs on cfs.custom_factor_set_id = cf.custom_factor_set_id
		 WHERE i.ind_sid = in_ind_sid
		   AND f.is_selected = 1
		   AND (in_end_dtm IS NULL OR f.start_dtm < in_end_dtm)
		   AND (in_start_dtm IS NULL OR f.end_dtm IS NULL OR f.end_dtm > in_start_dtm)
		   AND (f.geo_country IS NULL OR v_geo_countries_cnt = 0 OR f.geo_country IN (SELECT value FROM TABLE(v_geo_countries_table)))
		   AND (f.geo_region IS NULL OR v_geo_regions_cnt = 0 OR (f.geo_country IN (SELECT value FROM TABLE(v_geo_countries_table)) AND f.geo_region IN (SELECT value FROM TABLE(v_geo_regions_table))))
		   AND i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY country, region, region_override, start_dtm;
END;

FUNCTION GetInheritedStdFactorType (
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE
) RETURN factor_type.factor_type_id%TYPE
AS
	v_factor_type_id	factor_type.factor_type_id%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	IF in_region_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || in_region_sid);
		END IF;
	END IF;
	
	SELECT min(id) -- should all be the same
	  INTO v_factor_type_id
	  FROM (
			SELECT
					CASE WHEN f.factor_type_id = sf.factor_type_id THEN 0
						ELSE sf.factor_type_id
					END id
			  FROM factor f
			  JOIN std_factor sf ON f.std_factor_id = sf.std_factor_id
			 WHERE f.factor_type_id = in_factor_type_id
			   AND sf.std_factor_set_id = in_std_factor_set_id
			   AND ((f.geo_country IS NULL AND in_geo_country IS NULL) OR f.geo_country = in_geo_country)
			   AND ((f.geo_region IS NULL AND in_geo_region IS NULL AND f.egrid_ref IS NULL) OR f.geo_region = in_geo_region OR f.egrid_ref = in_geo_region)
			   AND f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	);
	
	IF v_factor_type_id IS NULL THEN
		RETURN 0;
	ELSE
		RETURN v_factor_type_id;
	END IF;
END;

FUNCTION GetInheritedBespokeFactorType (
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_geo_country			IN std_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN factor.region_sid%TYPE
) RETURN factor_type.factor_type_id%TYPE
AS
	v_factor_type_id	factor_type.factor_type_id%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	IF in_region_sid IS NOT NULL THEN
		IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read permission denied on the region with sid ' || in_region_sid);
		END IF;
	END IF;
	
	SELECT min(id) -- should all be the same
	  INTO v_factor_type_id
	  FROM (
			SELECT ofa.factor_type_id id
			  FROM factor f
			  JOIN factor ofa ON f.original_factor_id = ofa.factor_id
			 WHERE f.factor_type_id = in_factor_type_id
			   AND f.std_factor_id IS NULL
			   AND ((f.geo_country IS NULL AND in_geo_country IS NULL) OR f.geo_country = in_geo_country)
			   AND ((f.geo_region IS NULL AND in_geo_region IS NULL AND f.egrid_ref IS NULL) OR f.geo_region = in_geo_region OR f.egrid_ref = in_geo_region)
			   AND ((f.region_sid IS NULL AND in_region_sid IS NULL) OR f.region_sid = in_region_sid)
			   AND f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	);
	
	IF v_factor_type_id IS NULL THEN
		RETURN 0;
	ELSE
		RETURN v_factor_type_id;
	END IF;
END;

PROCEDURE GetFactorTabs(
	in_plugin_type_id		IN	plugin.plugin_type_id%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description,
			p.details, p.preview_image_path
		  FROM plugin p
		 WHERE p.plugin_type_id = in_plugin_type_id;
END;

FUNCTION CreateStdFactorSet(
	in_name						IN std_factor_set.name%TYPE,
	in_factor_set_group_id		IN std_factor_set.factor_set_group_id%TYPE,
	in_info_note				IN std_factor_set.info_note%TYPE DEFAULT NULL
) RETURN std_factor.std_factor_set_id%TYPE
AS
	v_std_factor_set_id		NUMBER(10);
	v_is_group_custom		NUMBER(1);
	v_cnt					NUMBER(8);
BEGIN

	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	SELECT custom
	  INTO v_is_group_custom
	  FROM factor_set_group
	 WHERE factor_set_group_id = in_factor_set_group_id;
	
	IF v_is_group_custom = 1 THEN 
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_UNEXPECTED, 'Cannot create a non custom factor set in a custom factor set group');
	END IF;
	
	SELECT count(name)
	  INTO v_cnt
	  FROM std_factor_set
	 WHERE LOWER(name) = LOWER(in_name);

	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
			'Factor set name already exists');
	END IF;
	
	INSERT INTO std_factor_set (std_factor_set_id, name, factor_set_group_id, created_by_sid, created_dtm, info_note)
	VALUES (factor_set_id_seq.nextval, in_name, in_factor_set_group_id, security.security_pkg.getSid, sysdate, in_info_note)
	RETURNING std_factor_set_id INTO v_std_factor_set_id;
	
	RETURN v_std_factor_set_id;
	
END;

FUNCTION CreateCustomFactorSet(
	in_name						IN custom_factor_set.name%TYPE,
	in_factor_set_group_id		IN custom_factor_set.factor_set_group_id%TYPE,
	in_info_note				IN custom_factor_set.info_note%TYPE DEFAULT NULL
) RETURN custom_factor.custom_factor_set_id%TYPE
AS
	v_custom_factor_set_id		NUMBER(10);
	v_is_group_custom			NUMBER(1);
	v_cnt						NUMBER(8);
BEGIN
	
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	SELECT custom
	  INTO v_is_group_custom
	  FROM factor_set_group
	 WHERE factor_set_group_id = in_factor_set_group_id;
	
	IF v_is_group_custom != 1 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_UNEXPECTED, 'Cannot create a custom factor set in a non custom factor set group.');
	END IF;
	
	SELECT count(name)
	  INTO v_cnt
	  FROM custom_factor_set
	 WHERE LOWER(name) = LOWER(in_name);

	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_VALUES_EXIST, 
			'Factor set name already exists');
	END IF;
	
	INSERT INTO custom_factor_set (custom_factor_set_id, name, factor_set_group_id, created_by_sid, created_dtm, info_note)
	VALUES (factor_set_id_seq.nextval, in_name, in_factor_set_group_id, security.security_pkg.getSid, sysdate, in_info_note)
	RETURNING custom_factor_set_id INTO v_custom_factor_set_id;
	
	RETURN v_custom_factor_set_id;

END;

PROCEDURE GetStdFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_std_factor_set_id	IN std_factor_set.std_factor_set_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT ft.factor_type_id, ft.name factor, ft.path factor_path, gt.name gas, f.value, f.start_dtm, f.end_dtm, f.note, f.source,
				smc.description unit, pc.name country, pr.name region, e.name egrid, sfs.name factor_set, sfs.std_factor_set_id factor_set_id,
				sfs.info_note
		  FROM (
				SELECT factor_type_id, TRIM(name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(name), '>>>'), '>>>') path
				  FROM factor_type
				 WHERE parent_id IS NOT NULL
				 START WITH parent_id IS NULL
				CONNECT BY PRIOR factor_type_id = parent_id
				) ft
		  JOIN std_factor f ON ft.factor_type_id = f.factor_type_id
		  JOIN gas_type gt ON f.gas_type_id = gt.gas_type_id
		  JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		  JOIN std_factor_set sfs ON f.std_factor_set_id = sfs.std_factor_set_id
		  LEFT JOIN postcode.country pc ON f.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON pc.country = pr.country AND f.geo_region = pr.region
		  LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref
		 WHERE f.std_factor_set_id = in_std_factor_set_id
		 ORDER BY country, region, egrid, factor_path, factor, gas, start_dtm, end_dtm;
END;

PROCEDURE GetCustomFactors(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_custom_factor_set_id	IN custom_factor_set.custom_factor_set_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT ft.factor_type_id, ft.name factor, ft.path factor_path, gt.name gas, f.value, f.start_dtm, f.end_dtm, f.note,
				smc.description unit, pc.name country, pr.name region, e.name egrid, cfs.name factor_set, cfs.custom_factor_set_id factor_set_id,
				cfs.info_note
		  FROM (
				SELECT factor_type_id, TRIM(name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(name), '>>>'), '>>>') path
				  FROM factor_type
				 WHERE parent_id IS NOT NULL
				 START WITH parent_id IS NULL
				CONNECT BY PRIOR factor_type_id = parent_id
				) ft
		  JOIN custom_factor f ON ft.factor_type_id = f.factor_type_id
		  JOIN gas_type gt ON f.gas_type_id = gt.gas_type_id
		  JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		  JOIN custom_factor_set cfs ON f.custom_factor_set_id = cfs.custom_factor_set_id
		  LEFT JOIN postcode.country pc ON f.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON pc.country = pr.country AND f.geo_region = pr.region
		  LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref
		 WHERE f.custom_factor_set_id = in_custom_factor_set_id
		 ORDER BY country, region, egrid, factor_path, factor, gas, start_dtm, end_dtm;
END;

-- CUSTOM FACTORS
-- A custom factor is essentially a client specific standard factor set and now has it's own tables called custom_factor and custom_factor_set. 
-- So theoretically you could have bespoke custom factors although I doubt we will create a UI option for it.  

PROCEDURE CheckExistCustomFactor(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 AND NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	OPEN out_cur FOR
		SELECT custom_factor_id factor_id,
		CASE WHEN in_start_dtm = start_dtm AND (in_end_dtm = end_dtm OR (in_end_dtm IS NULL AND end_dtm IS NULL)) THEN 1
			ELSE 0
		END dates_match
		  FROM custom_factor
		 WHERE custom_factor_set_id = in_custom_factor_set_id
		   AND factor_type_id = in_factor_type_id
		   AND gas_type_id = in_gas_type_id
		   AND ((geo_country IS NULL AND in_geo_country IS NULL) OR geo_country = in_geo_country)
		   AND ((geo_region IS NULL AND egrid_ref IS NULL AND in_geo_region IS NULL) OR geo_region = in_geo_region OR egrid_ref = in_geo_region)
		   -- Overlapping dates
			AND ((
			  in_start_dtm >= start_dtm and (in_start_dtm < end_dtm or end_dtm is null)
			)
			OR (
			  in_start_dtm < start_dtm and (in_end_dtm > start_dtm or in_end_dtm is null)
			));
END;

PROCEDURE InsertCustomValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN custom_factor.region_sid%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_custom_factor_id	OUT custom_factor.custom_factor_id%TYPE
)
AS
	v_custom_factor_id		custom_factor.custom_factor_id%TYPE;
	v_count					NUMBER(10);
BEGIN
	v_custom_factor_id := CUSTOM_FACTOR_ID_SEQ.nextval;
	
	--add new entry to custom factor table
	SELECT COUNT(country)
	  INTO v_count
	  FROM POSTCODE.region
	 WHERE country = in_geo_country
	   AND in_geo_region IS NULL OR region = in_geo_region;
	
	-- The incoming geo_region value is either a region code or an egrid code, dependent on whether that country uses region codes or not
	-- as determined by the postcode.region check.
	
	IF v_count > 0 THEN
		--Set geo_region
		INSERT INTO custom_factor(custom_factor_id, factor_type_id, custom_factor_set_id, gas_type_id, 
				geo_country, geo_region, region_sid, start_dtm, end_dtm, value,
				std_measure_conversion_id, note)
		VALUES(v_custom_factor_id, in_factor_type_id, in_custom_factor_set_id, in_gas_type_id,
			   in_geo_country, in_geo_region, in_region_sid, in_start_dtm, in_end_dtm, in_value,
			   in_std_meas_conv_id, in_note);
	ELSE
		--Set egrid_ref
		INSERT INTO custom_factor(custom_factor_id, factor_type_id, custom_factor_set_id, gas_type_id, 
				geo_country, egrid_ref, region_sid, start_dtm, end_dtm, value,
				std_measure_conversion_id, note)
		VALUES(v_custom_factor_id, in_factor_type_id, in_custom_factor_set_id, in_gas_type_id,
			   in_geo_country, in_geo_region, in_region_sid, in_start_dtm, in_end_dtm, in_value,
			   in_std_meas_conv_id, in_note);
	END IF;

	out_custom_factor_id := v_custom_factor_id;
END;

PROCEDURE InsertCustomValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN custom_factor.geo_country%TYPE,
	in_egrid_ref			IN custom_factor.egrid_ref%TYPE,
	in_region_sid			IN custom_factor.region_sid%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_custom_factor_id	OUT custom_factor.custom_factor_id%TYPE
)
AS
	v_custom_factor_id		custom_factor.custom_factor_id%TYPE;
BEGIN
	v_custom_factor_id := CUSTOM_FACTOR_ID_SEQ.nextval;
	
	INSERT INTO custom_factor(custom_factor_id, factor_type_id, custom_factor_set_id, gas_type_id, 
			geo_country, geo_region, egrid_ref, region_sid, start_dtm, end_dtm, value,
			std_measure_conversion_id, note)
	VALUES(v_custom_factor_id, in_factor_type_id, in_custom_factor_set_id, in_gas_type_id,
		   in_geo_country, in_geo_region, in_egrid_ref, in_region_sid, in_start_dtm, in_end_dtm, in_value,
		   in_std_meas_conv_id, in_note);

	out_custom_factor_id := v_custom_factor_id;
END;

PROCEDURE CustomFactorAddNewValue(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_geo_country			IN custom_factor.geo_country%TYPE,
	in_geo_region			IN VARCHAR2,
	in_region_sid			IN custom_factor.region_sid%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_custom_factor_id	OUT custom_factor.custom_factor_id%TYPE
)
AS
	v_custom_factor_id		custom_factor.custom_factor_id%TYPE;
	v_count					NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
	v_audit_msg				VARCHAR2(1000);
	v_audit_info			VARCHAR2(1000);
	v_gas					VARCHAR2(1000);
	v_smc					VARCHAR2(1000);
BEGIN

	InsertCustomValue(
		in_factor_type_id => in_factor_type_id,
		in_custom_factor_set_id => in_custom_factor_set_id,
		in_geo_country => in_geo_country,
		in_geo_region => in_geo_region,
		in_region_sid => in_region_sid,
		in_start_dtm => in_start_dtm,
		in_end_dtm => in_end_dtm,
		in_gas_type_id => in_gas_type_id,
		in_value => in_value,
		in_std_meas_conv_id => in_std_meas_conv_id,
		in_note => in_note,
		out_custom_factor_id => out_custom_factor_id
	);

	SELECT gt.name, smc.description
	  INTO v_gas, v_smc
	  FROM custom_factor cf
	  JOIN gas_type gt ON cf.gas_type_id = gt.gas_type_id
	  JOIN std_measure_conversion smc ON cf.std_measure_conversion_id = smc.std_measure_conversion_id
	 WHERE cf.custom_factor_id = out_custom_factor_id;

	v_audit_msg := 'Created Emission factor ({0})';
	v_audit_info := 'StartDtm='|| in_start_dtm ||', ' ||
		'EndDtm='|| in_end_dtm ||', ' ||
		'Gas='|| v_gas ||', ' ||
		'Value='|| in_value ||', ' ||
		'Measure='|| v_smc ||', ' ||
		'Note='|| in_note;

	WriteFactorLogEntry(
		in_factor_cat_id	=> csr_data_pkg.FACTOR_CAT_CUSTOM,
		in_factor_type_id	=> in_factor_type_id,
		in_factor_set_id	=> in_custom_factor_set_id,
		in_country			=> in_geo_country,
		in_region			=> CASE WHEN v_count > 0 THEN in_geo_region ELSE NULL END,
		in_egrid_ref		=> CASE WHEN v_count = 0 THEN in_geo_region ELSE NULL END,
		in_region_sid		=> in_region_sid,
		in_gas_type_id		=> in_gas_type_id,
		in_start_dtm		=> in_start_dtm,
		in_end_dtm			=> in_end_dtm,
		in_message			=> v_audit_msg,
		in_field_name		=> v_audit_info
	);
END;
	
PROCEDURE CustomFactorAmendValue(
	in_custom_factor_id		IN custom_factor.custom_factor_id%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE,
	in_gas_type_id			IN custom_factor.gas_type_id%TYPE,
	in_value				IN custom_factor.value%TYPE,
	in_std_meas_conv_id		IN custom_factor.std_measure_conversion_id%TYPE,
	in_note					IN custom_factor.note%TYPE,
	out_message				OUT VARCHAR2
)
AS
	v_custom_factor_set_id		custom_factor_set.custom_factor_set_id%TYPE;
	v_factor_type_id			factor_type.factor_type_id%TYPE;
	v_geo_country				custom_factor.geo_country%TYPE;
	v_geo_region				custom_factor.geo_region%TYPE;
	v_egrid_ref					custom_factor.egrid_ref%TYPE;
	v_start_dtm					custom_factor.start_dtm%TYPE;
	v_end_dtm					custom_factor.end_dtm%TYPE;
	v_gas_type_id				custom_factor.gas_type_id%TYPE;
	v_value						custom_factor.value%TYPE;
	v_std_measure_conversion_id	custom_factor.std_measure_conversion_id%TYPE;
	v_note						custom_factor.note%TYPE;
	v_region_sid				custom_factor.region_sid%TYPE;
	v_app_sid					security_pkg.T_SID_ID;
	v_gas_desc					VARCHAR2(1000);
	v_unit_desc					VARCHAR2(1000);
	v_gas_desc_old				VARCHAR2(1000);
	v_unit_desc_old				VARCHAR2(1000);
	
	v_overlap_count				NUMBER;
	v_overlaps					VARCHAR2(4000);
	
	PROCEDURE AuditFieldChange(
		in_field_name	VARCHAR2,
		in_old_val		VARCHAR2,
		in_new_val		VARCHAR2
	)
	AS
	BEGIN
		IF in_old_val!=in_new_val OR
		(in_old_val IS NULL AND in_new_val IS NOT NULL) OR
		(in_new_val IS NULL AND in_old_val IS NOT NULL) THEN
			WriteFactorLogEntry(
				in_factor_cat_id	=> csr_data_pkg.FACTOR_CAT_CUSTOM,
				in_factor_type_id	=> v_factor_type_id,
				in_factor_set_id	=> v_custom_factor_set_id,
				in_country			=> v_geo_country,
				in_region			=> v_geo_region,
				in_egrid_ref		=> v_egrid_ref,
				in_region_sid		=> v_region_sid,
				in_gas_type_id		=> in_gas_type_id,
				in_start_dtm		=> in_start_dtm,
				in_end_dtm			=> in_end_dtm,
				in_field_name		=> in_field_name,
				in_old_val			=> NVL(in_old_val, 'Empty'),
				in_new_val			=> NVL(in_new_val, 'Empty'),
				in_message			=> '{0} changed from "{1}" to "{2}" for gas {3} and period starting {4}'
			);
		END IF;
	END;
BEGIN
	-- set to non-null string in case no overlaps detected.
	out_message := ' ';
	
	SELECT cf.factor_type_id, cf.custom_factor_set_id, cf.geo_country, cf.geo_region, cf.egrid_ref, cf.region_sid, cf.start_dtm,
		cf.end_dtm, cf.gas_type_id, cf.value, cf.std_measure_conversion_id, cf.note, gt.name, smc.description
	  INTO v_factor_type_id, v_custom_factor_set_id, v_geo_country, v_geo_region, v_egrid_ref, v_region_sid, v_start_dtm,
		v_end_dtm, v_gas_type_id, v_value, v_std_measure_conversion_id, v_note, v_gas_desc_old, v_unit_desc_old
	  FROM custom_factor cf
	  JOIN gas_type gt ON cf.gas_type_id = gt.gas_type_id
	  JOIN std_measure_conversion smc ON cf.std_measure_conversion_id = smc.std_measure_conversion_id
	 WHERE custom_factor_id = in_custom_factor_id;
	
	SELECT MIN(smc.description)
	  INTO v_unit_desc
	  FROM std_measure_conversion smc
	 WHERE smc.std_measure_conversion_id = in_std_meas_conv_id;
	
	SELECT MIN(gt.name)
	  INTO v_gas_desc
	  FROM gas_type gt
	 WHERE gt.gas_type_id = in_gas_type_id;
	
	-- update custom factor table
	UPDATE custom_factor
	   SET start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   gas_type_id = in_gas_type_id,
		   value = in_value,
		   std_measure_conversion_id = in_std_meas_conv_id,
		   note = in_note
     WHERE custom_factor_id = in_custom_factor_id;
					
	AuditFieldChange('Start date', v_start_dtm, in_start_dtm);
	AuditFieldChange('End date', v_end_dtm, in_end_dtm);
	AuditFieldChange('Gas', v_gas_desc_old, v_gas_desc);
	AuditFieldChange('Value', v_value, in_value);
	AuditFieldChange('Measure', v_unit_desc_old, v_unit_desc);
	AuditFieldChange('Note', v_note, in_note);

	GetOverlapCtmFactorData(v_overlap_count, v_overlaps);
	IF v_overlap_count > 0 THEN
		IF LENGTH(v_overlaps) > 255 THEN
			v_overlaps := SUBSTR(v_overlaps, 1, 255) || '...';
		END IF;
		out_message := 'Warning: '||v_overlap_count||' overlapping custom factors detected ('||v_overlaps||')';
	END IF;
END;

PROCEDURE CustomFactorDelValue(
	in_custom_factor_id		IN custom_factor.custom_factor_id%TYPE
)
AS
	v_custom_factor_set_id		custom_factor_set.custom_factor_set_id%TYPE;
	v_factor_type_id			factor_type.factor_type_id%TYPE;
	v_geo_country				custom_factor.geo_country%TYPE;
	v_geo_region				custom_factor.geo_region%TYPE;
	v_egrid_ref					custom_factor.egrid_ref%TYPE;
	v_start_dtm					custom_factor.start_dtm%TYPE;
	v_end_dtm					custom_factor.end_dtm%TYPE;
	v_gas_type_id				custom_factor.gas_type_id%TYPE;
	v_value						custom_factor.value%TYPE;
	v_std_measure_conversion_id	custom_factor.std_measure_conversion_id%TYPE;
	v_note						custom_factor.note%TYPE;
	v_region_sid				custom_factor.region_sid%TYPE;
	v_count						NUMBER;
	v_app_sid					security.security_pkg.T_SID_ID;
	v_audit_msg					VARCHAR2(1000);
	v_audit_info				VARCHAR2(1000);
	v_gas						VARCHAR2(1000);
	v_smc						VARCHAR2(1000);
BEGIN
	
	SELECT cf.factor_type_id, cf.custom_factor_set_id, cf.geo_country, cf.geo_region, cf.egrid_ref, cf.region_sid, 
		cf.start_dtm, cf.end_dtm, cf.gas_type_id, cf.value, cf.std_measure_conversion_id, cf.note, gt.name, smc.description
	  INTO v_factor_type_id, v_custom_factor_set_id, v_geo_country, v_geo_region, v_egrid_ref, v_region_sid, 
		v_start_dtm, v_end_dtm, v_gas_type_id, v_value, v_std_measure_conversion_id, v_note, v_gas, v_smc
	  FROM custom_factor cf
	  JOIN gas_type gt ON cf.gas_type_id = gt.gas_type_id
	  JOIN std_measure_conversion smc ON cf.std_measure_conversion_id = smc.std_measure_conversion_id 
	 WHERE custom_factor_id = in_custom_factor_id;
	
	-- Update custom factor table, and remove from factor table first too, in case it's actually enabled.
	DELETE FROM factor WHERE custom_factor_id = in_custom_factor_id;
	DELETE FROM custom_factor WHERE custom_factor_id = in_custom_factor_id;
	
	v_audit_msg := 'Deleted Emission factor ({0})';
	v_audit_info := 'StartDtm='|| v_start_dtm ||', ' || 
		'EndDtm='|| v_end_dtm ||', ' || 
		'Gas='|| v_gas ||', ' || 
		'Value='|| v_value ||', ' || 
		'Measure='|| v_smc ||', ' || 
		'Note='|| v_note;
		
	WriteFactorLogEntry(
		in_factor_cat_id	=> csr_data_pkg.FACTOR_CAT_CUSTOM,
		in_factor_type_id	=> v_factor_type_id,
		in_factor_set_id	=> v_custom_factor_set_id,
		in_country			=> v_geo_country,
		in_region			=> v_geo_region,
		in_egrid_ref		=> v_egrid_ref,
		in_region_sid		=> v_region_sid,
		in_gas_type_id		=> v_gas_type_id,
		in_start_dtm		=> v_start_dtm,
		in_end_dtm			=> v_end_dtm,
		in_message			=> v_audit_msg,
		in_field_name		=> v_audit_info
	);
END;

FUNCTION GetFactorSetName(
	in_factor_set_id		IN NUMBER
) RETURN VARCHAR2
AS
	v_factor_set		VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	SELECT name
	  INTO v_factor_set
	  FROM (
		SELECT name 
		  FROM std_factor_set
		 WHERE std_factor_set_id = in_factor_set_id
		 UNION
		SELECT name
		  FROM custom_factor_set
		 WHERE custom_factor_set_id = in_factor_set_id
	);

	RETURN v_factor_set;
END;

FUNCTION GetFactorSetInfoNote(
	in_factor_set_id		IN NUMBER
) RETURN CLOB
AS
	v_info_note		std_factor_set.info_note%TYPE;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND NOT csr_data_pkg.CheckCapability('View emission factors') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" or "View emission factors" capability');
	END IF;

	-- At least one will always be null.
	SELECT MIN(info_note)
	  INTO v_info_note
	  FROM (
		SELECT TO_CHAR(info_note) info_note
		  FROM std_factor_set
		 WHERE std_factor_set_id = in_factor_set_id
		 UNION
		SELECT TO_CHAR(info_note) info_note
		  FROM custom_factor_set
		 WHERE custom_factor_set_id = in_factor_set_id
	);

	RETURN v_info_note;
END;

PROCEDURE GetEmissionProfiles(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
BEGIN
	OPEN out_cur FOR
		SELECT profile_id, name, start_dtm, end_dtm, applied
		  FROM emission_factor_profile
		 WHERE app_sid = v_app_sid
		 ORDER BY start_dtm, name;
END;

PROCEDURE INTERNAL_DeleteFactors(
	in_profile_id					IN emission_factor_profile.profile_id%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_appliedprofiles		NUMBER(10);
BEGIN
	-- Delete all the factor records (note that once a client uses a profile for the first time, any existing custom factor data will be removed).
	-- This provides a way to get back to a known base state of "nothing selected".
	SELECT COUNT(*)
	  INTO v_appliedprofiles
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND applied = 1;

	IF v_appliedprofiles = 0 THEN
		DELETE FROM factor
		 WHERE app_sid = v_app_sid;
		RETURN;
	END IF;

	-- Note, always deletes "old" tool factors (one's with no profile_id set), in case there's any left hanging around.
	IF in_profile_id IS NULL THEN
		-- Delete factor records from all profiles (they'll be recreated afterwards).
		DELETE FROM factor
		 WHERE app_sid = v_app_sid
		   AND (profile_id IS NULL OR 
				profile_id IN (SELECT profile_id
								FROM emission_factor_profile
							   WHERE app_sid = v_app_sid));
	ELSE
		-- Delete factor records from a specific profile.
		DELETE FROM factor
		 WHERE app_sid = v_app_sid
		   AND (profile_id IS NULL OR profile_id = in_profile_id);
	END IF;
END;

PROCEDURE INTERNAL_DeleteFactors
AS
BEGIN
	INTERNAL_DeleteFactors(in_profile_id => NULL);
END;

--PROCEDURE INTERNAL_Trace(in_msg IN VARCHAR2)
--AS
--BEGIN
--	dbms_output.put_line(in_msg);
--END;

PROCEDURE INTERNAL_ProcessFactor(
	r_app_sid						IN security_pkg.T_SID_ID,
	r_factor_type_id				IN factor_type.factor_type_id%TYPE,
	r_gas_type_id					IN std_factor.gas_type_id%TYPE,
	r_geo_country					IN factor.geo_country%TYPE,
	r_geo_region					IN factor.geo_region%TYPE,
	r_egrid_ref						IN factor.egrid_ref%TYPE,
	r_std_factor_id					IN std_factor.std_factor_id%TYPE,
	r_custom_factor_id				IN custom_factor.custom_factor_id%TYPE,
	r_start_dtm						IN std_factor.start_dtm%TYPE,
	r_end_dtm						IN std_factor.end_dtm%TYPE,
	r_value							IN std_factor.value%TYPE,
	r_std_measure_conversion_id		IN std_measure_conversion.std_measure_conversion_id%TYPE,
	r_note							IN std_factor.note%TYPE,
	r_region_sid					IN factor.region_sid%TYPE,
	r_is_selected					IN NUMBER,
	in_profile_id					IN emission_factor_profile.profile_id%TYPE,
	in_region_sid					IN factor.region_sid%TYPE,
	in_start_dtm					IN std_factor.start_dtm%TYPE,
	in_end_dtm						IN std_factor.end_dtm%TYPE
)
AS
	v_matched_factor	NUMBER;
BEGIN
	--INTERNAL_Trace(' '||'Checking '|| r_factor_type_id ||' '|| r_gas_type_id ||' '|| r_geo_country ||' '|| r_geo_region ||' '|| r_egrid_ref ||' '|| NVL(r_std_factor_id, r_custom_factor_id) ||' '|| r_start_dtm ||' '|| r_end_dtm ||' '|| r_value ||' '|| r_note);
	--INTERNAL_Trace(' '||'against '|| in_profile_id ||' '|| in_region_sid ||' '|| in_start_dtm ||' '|| in_end_dtm);
	
	-- Can occur when capping a profile to a specific date and the factor happens to start on the end cap. If the factor is required, it'll be picked up by the next profile in the chain.
	IF r_start_dtm = in_end_dtm THEN
		--INTERNAL_Trace('  Ignore factor that starts on end date.');
		RETURN;
	END IF;
	-- Similarly, if a factor ends on the start date of a profile, we also want to skip that.
	IF r_end_dtm = in_start_dtm THEN
		RETURN;
	END IF;
	
	v_matched_factor:= 0;
	BEGIN
		SELECT NVL(factor_type_id, 0)
		  INTO v_matched_factor
		  FROM factor f 
		 WHERE f.factor_type_id = r_factor_type_id
		   AND f.gas_type_id = r_gas_type_id
		   AND (in_region_sid IS NULL OR f.region_sid = in_region_sid)
		   AND (r_geo_country IS NULL OR f.geo_country = r_geo_country)
		   AND (r_geo_region IS NULL OR f.geo_region = r_geo_region)
		   AND (r_egrid_ref IS NULL OR f.egrid_ref = r_egrid_ref)
		   AND	(
					(r_std_factor_id IS NOT NULL AND f.std_factor_id = r_std_factor_id) OR
					(r_custom_factor_id IS NOT NULL AND f.custom_factor_id = r_custom_factor_id)
				)
		   AND f.start_dtm = r_start_dtm
		   AND (r_end_dtm IS NULL OR f.end_dtm = r_end_dtm);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;

	IF v_matched_factor > 0 THEN
		IF r_start_dtm < in_start_dtm AND r_end_dtm IS NULL THEN
			--INTERNAL_Trace('  REINSTATE openended factor = '||v_matched_factor||' r_start='||r_start_dtm||' r_end='||r_end_dtm||' in_end='||in_end_dtm);
			INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country,
				geo_region, egrid_ref, std_factor_id, custom_factor_id, start_dtm, end_dtm, value,
				std_measure_conversion_id, note, region_sid, is_selected, profile_id)
			VALUES (r_app_sid, FACTOR_ID_SEQ.nextval, r_factor_type_id, r_gas_type_id, r_geo_country,
				r_geo_region, r_egrid_ref,
				r_std_factor_id, r_custom_factor_id,
				CASE WHEN r_start_dtm < in_start_dtm THEN in_start_dtm ELSE r_start_dtm END,
				CASE WHEN in_end_dtm IS NOT NULL AND in_end_dtm < r_end_dtm THEN in_end_dtm ELSE NVL(r_end_dtm, in_end_dtm) END,
				r_value, r_std_measure_conversion_id, r_note, r_region_sid, r_is_selected, in_profile_id
				);
		END IF;
		
		IF r_start_dtm >= in_start_dtm AND r_end_dtm IS NOT NULL THEN
			--INTERNAL_Trace('  '||'UPDATE v_matched_factor = '||v_matched_factor||' start='||CASE WHEN r_start_dtm < in_start_dtm THEN in_start_dtm ELSE r_start_dtm END||' end='||NVL(r_end_dtm, in_end_dtm));
			--INTERNAL_Trace('   '||r_factor_type_id||', '||r_gas_type_id||', '||r_std_factor_id||', '||r_start_dtm||', '||r_end_dtm);
			
			UPDATE factor
			   SET value = r_value, note = r_note, std_measure_conversion_id = r_std_measure_conversion_id,
				geo_country = r_geo_country, geo_region = r_geo_region, egrid_ref = r_egrid_ref,
				std_factor_id = r_std_factor_id, custom_factor_id = r_custom_factor_id, original_factor_id = NULL,
				start_dtm = CASE WHEN r_start_dtm < in_start_dtm THEN in_start_dtm ELSE r_start_dtm END,
				end_dtm = NVL(r_end_dtm, in_end_dtm),
				profile_id = in_profile_id
			 WHERE factor_type_id = r_factor_type_id
			   AND gas_type_id = r_gas_type_id
			   AND (in_region_sid IS NULL OR region_sid = in_region_sid)
			   AND (r_geo_country IS NULL OR geo_country = r_geo_country)
			   AND (r_geo_region IS NULL OR geo_region = r_geo_region)
			   AND (r_egrid_ref IS NULL OR egrid_ref = r_egrid_ref)
			   AND 	(
						(r_std_factor_id IS NOT NULL AND std_factor_id = r_std_factor_id) OR
						(r_custom_factor_id IS NOT NULL AND custom_factor_id = r_custom_factor_id)
					)
			   AND start_dtm = r_start_dtm
			   AND (r_end_dtm IS NULL OR end_dtm = r_end_dtm);
		END IF;
	END IF;

	IF v_matched_factor = 0 THEN
		--INTERNAL_Trace('  '||'no match, INSERT for start='||
		--	CASE WHEN r_start_dtm < in_start_dtm THEN in_start_dtm ELSE r_start_dtm END||
		--	', end='||
		--	CASE WHEN in_end_dtm IS NOT NULL AND in_end_dtm < r_end_dtm THEN in_end_dtm ELSE NVL(r_end_dtm, in_end_dtm) END
		--);
		INSERT INTO factor(app_sid, factor_id, factor_type_id, gas_type_id, geo_country,
			geo_region, egrid_ref, std_factor_id, custom_factor_id, start_dtm, end_dtm, value,
			std_measure_conversion_id, note, region_sid, is_selected, profile_id)
		VALUES (r_app_sid, FACTOR_ID_SEQ.nextval, r_factor_type_id, r_gas_type_id, r_geo_country,
			r_geo_region, r_egrid_ref,
			r_std_factor_id, r_custom_factor_id,
			CASE WHEN r_start_dtm < in_start_dtm THEN in_start_dtm ELSE r_start_dtm END,
			CASE WHEN in_end_dtm IS NOT NULL AND in_end_dtm < r_end_dtm THEN in_end_dtm ELSE NVL(r_end_dtm, in_end_dtm) END,
			r_value, r_std_measure_conversion_id, r_note, r_region_sid, r_is_selected, in_profile_id
			);
	END IF;
END;

PROCEDURE INTERNAL_UpdateSelectedStdSet(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_region_sid			IN factor.region_sid%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN factor.geo_region%TYPE,
	in_egrid_ref			IN factor.egrid_ref%TYPE,
	in_std_factor_set_id	IN std_factor.std_factor_set_id%TYPE,
	in_start_dtm			IN std_factor.start_dtm%TYPE,
	in_end_dtm				IN std_factor.end_dtm%TYPE
)
AS
	v_factor_start_month	NUMBER(2);
	v_matched_factor 		NUMBER(10);
BEGIN
	SELECT DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month
	  INTO v_factor_start_month
	  FROM customer
	 WHERE app_sid = in_app_sid;
	
	--INTERNAL_Trace('INTERNAL_UpdateSelectedStdSet: p'||in_profile_id||' ft'||in_factor_type_id ||' r'|| in_region_sid||' gc'|| in_geo_country||' gr'|| in_geo_region||' eg'|| in_egrid_ref||' sf'|| in_std_factor_set_id||' sd'|| in_start_dtm||' ed'|| in_end_dtm);

	--copy standard factor values to factor table
	FOR r IN (
		SELECT in_app_sid app_sid, in_factor_type_id factor_type_id, gas_type_id,
				in_geo_country geo_country, in_geo_region geo_region, in_egrid_ref egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
				std_measure_conversion_id, note, in_region_sid region_sid, 1 is_selected
		  FROM (
			SELECT f.factor_type_id, gas_type_id,
					geo_country, geo_region, egrid_ref, std_factor_id, start_dtm, end_dtm, value, 
					std_measure_conversion_id, note, priority
			 FROM (
					(
						SELECT factor_type_id, gas_type_id,
							geo_country, geo_region, egrid_ref, std_factor_id,
							TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY') start_dtm,
							CASE
								WHEN end_dtm IS NULL THEN NULL
								ELSE ADD_MONTHS(
									TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(start_dtm,'YYYY'), 'MMYYYY'), 
									MONTHS_BETWEEN(end_dtm, start_dtm) - (EXTRACT(MONTH from end_dtm) - EXTRACT(MONTH from start_dtm))
								)
							END end_dtm,
							value, std_measure_conversion_id, note
						  FROM std_factor
						 WHERE std_factor_set_id = in_std_factor_set_id
						   AND factor_type_id = in_factor_type_id
						   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
						   AND ((in_geo_region IS NULL AND geo_region IS NULL) OR geo_region = in_geo_region)
						   AND ((in_egrid_ref IS NULL AND egrid_ref IS NULL) OR egrid_ref = in_egrid_ref)
						   AND ((start_dtm <= in_start_dtm AND (end_dtm IS NULL OR end_dtm > in_start_dtm)) OR
								(start_dtm >= in_start_dtm AND (in_end_dtm IS NULL OR start_dtm < in_end_dtm)))
					) f
					JOIN
					(
						SELECT factor_type_id, level priority
						  FROM factor_type
						 START WITH factor_type_id = in_factor_type_id
						CONNECT BY PRIOR parent_id = factor_type_id
					) ft
					ON f.factor_type_id = ft.factor_type_id
			)
		)
		 WHERE priority = (
			SELECT min(priority)
			  FROM (
					SELECT priority
					 FROM (
							(
								SELECT factor_type_id
								  FROM std_factor
								 WHERE std_factor_set_id = in_std_factor_set_id
								   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
								   AND ((in_geo_region IS NULL AND geo_region IS NULL) OR geo_region = in_geo_region)
								   AND ((in_egrid_ref IS NULL AND egrid_ref IS NULL) OR egrid_ref = in_egrid_ref)
								   AND ((start_dtm <= in_start_dtm AND (end_dtm IS NULL OR end_dtm > in_start_dtm)) OR
										(start_dtm >= in_start_dtm AND (in_end_dtm IS NULL OR start_dtm < in_end_dtm)))
							) f
							JOIN
							(
								SELECT factor_type_id, level priority
								  FROM factor_type
								 START WITH factor_type_id = in_factor_type_id
								CONNECT BY PRIOR parent_id = factor_type_id
							) ft
							ON f.factor_type_id = ft.factor_type_id
					)
			)
		)
		ORDER BY factor_type_id, start_dtm
	)
	LOOP
		INTERNAL_ProcessFactor(r.app_sid, r.factor_type_id, r.gas_type_id,
				r.geo_country, r.geo_region, r.egrid_ref, 
				r.std_factor_id, NULL,
				r.start_dtm, r.end_dtm, r.value, 
				r.std_measure_conversion_id, r.note, r.region_sid, r.is_selected,
				in_profile_id, in_region_sid, in_start_dtm, in_end_dtm);
	END LOOP;
END;

PROCEDURE INTERNAL_UpdateSelectedCustSet(
	in_app_sid				IN security_pkg.T_SID_ID,
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_region_sid			IN factor.region_sid%TYPE,
	in_geo_country			IN factor.geo_country%TYPE,
	in_geo_region			IN factor.geo_region%TYPE,
	in_egrid_ref			IN factor.egrid_ref%TYPE,
	in_custom_factor_set_id	IN custom_factor.custom_factor_set_id%TYPE,
	in_start_dtm			IN custom_factor.start_dtm%TYPE,
	in_end_dtm				IN custom_factor.end_dtm%TYPE
)
AS
BEGIN
	--INTERNAL_Trace('INTERNAL_UpdateSelectedCustSet: p'||in_profile_id||' ft'||in_factor_type_id ||' r'|| in_region_sid||' gc'|| in_geo_country||' gr'|| in_geo_region||' eg'|| in_egrid_ref||' sf'|| in_custom_factor_set_id||' sd'|| in_start_dtm||' ed'|| in_end_dtm);

	--copy custom factor values to factor table
	FOR r IN (
		SELECT in_app_sid app_sid, in_factor_type_id factor_type_id, gas_type_id,
				in_geo_country geo_country, in_geo_region geo_region, in_egrid_ref egrid_ref, custom_factor_id, start_dtm, end_dtm, value, 
				std_measure_conversion_id, note, in_region_sid region_sid, 1 is_selected
		  FROM (
			SELECT f.factor_type_id, gas_type_id,
					geo_country, geo_region, egrid_ref, custom_factor_id, start_dtm, end_dtm, value, 
					std_measure_conversion_id, note, priority
			 FROM (
					(
						SELECT factor_type_id, gas_type_id,
							geo_country, geo_region, egrid_ref, custom_factor_id,
							start_dtm, end_dtm,
							value, std_measure_conversion_id, note
						  FROM custom_factor
						 WHERE custom_factor_set_id = in_custom_factor_set_id
						   AND factor_type_id = in_factor_type_id
						   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
						   AND ((in_geo_region IS NULL AND geo_region IS NULL) OR geo_region = in_geo_region)
						   AND ((in_egrid_ref IS NULL AND egrid_ref IS NULL) OR egrid_ref = in_egrid_ref)
						   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
						   AND ((start_dtm <= in_start_dtm AND (end_dtm IS NULL OR end_dtm > in_start_dtm)) OR
								(start_dtm >= in_start_dtm AND (in_end_dtm IS NULL OR start_dtm < in_end_dtm)))
					) f
					JOIN
					(
						SELECT factor_type_id, level priority
						  FROM factor_type
						 START WITH factor_type_id = in_factor_type_id
						CONNECT BY PRIOR parent_id = factor_type_id
					) ft
					ON f.factor_type_id = ft.factor_type_id
			)
		)
		 WHERE priority = (
			SELECT min(priority)
			  FROM (
					SELECT priority
					 FROM (
							(
								SELECT factor_type_id
								  FROM custom_factor 
								 WHERE custom_factor_set_id = in_custom_factor_set_id
								   AND ((in_geo_country IS NULL AND geo_country IS NULL) OR geo_country = in_geo_country)
								   AND ((in_geo_region IS NULL AND geo_region IS NULL) OR geo_region = in_geo_region)
								   AND ((in_egrid_ref IS NULL AND egrid_ref IS NULL) OR egrid_ref = in_egrid_ref)
								   AND ((in_region_sid IS NULL AND region_sid IS NULL) OR region_sid = in_region_sid)
								   AND ((start_dtm <= in_start_dtm AND (end_dtm IS NULL OR end_dtm > in_start_dtm)) OR
										(start_dtm >= in_start_dtm AND (in_end_dtm IS NULL OR start_dtm < in_end_dtm)))
							) f
							JOIN
							(
								SELECT factor_type_id, level priority
								  FROM factor_type
								 START WITH factor_type_id = in_factor_type_id
								CONNECT BY PRIOR parent_id = factor_type_id
							) ft
							ON f.factor_type_id = ft.factor_type_id
					)
			)
		)
		ORDER BY factor_type_id, start_dtm
	)
	LOOP
		INTERNAL_ProcessFactor(r.app_sid, r.factor_type_id, r.gas_type_id,
				r.geo_country, r.geo_region, r.egrid_ref, 
				NULL, r.custom_factor_id,
				r.start_dtm, r.end_dtm, r.value, 
				r.std_measure_conversion_id, r.note, r.region_sid, r.is_selected,
				in_profile_id, in_region_sid, in_start_dtm, in_end_dtm);
	END LOOP;
END;

PROCEDURE INT_AddAppliedFactorsProfile(
	in_profile_id				IN	emission_factor_profile.profile_id%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_profile_id			emission_factor_profile.profile_id%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_end_dtm				emission_factor_profile.end_dtm%TYPE;
BEGIN
	BEGIN
		SELECT profile_id, start_dtm, end_dtm
		  INTO v_profile_id, v_start_dtm, v_end_dtm
		  FROM emission_factor_profile
		 WHERE app_sid = v_app_sid
		   AND profile_id = in_profile_id
		   AND applied = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_profile_id := 0;
	END;
	
	IF v_profile_id > 0 THEN
		FOR efpf IN (SELECT factor_type_id, std_factor_set_id, custom_factor_set_id, region_sid, geo_country, geo_region, egrid_ref
					   FROM emission_factor_profile_factor
					  WHERE app_sid = v_app_sid
						AND profile_id = v_profile_id)
		LOOP
			IF efpf.std_factor_set_id IS NOT NULL THEN
				INTERNAL_UpdateSelectedStdSet(v_app_sid, v_profile_id, efpf.factor_type_id, efpf.region_sid, efpf.geo_country, efpf.geo_region, efpf.egrid_ref,
					efpf.std_factor_set_id, v_start_dtm, v_end_dtm);
			END IF;
			IF efpf.custom_factor_set_id IS NOT NULL THEN
				INTERNAL_UpdateSelectedCustSet(v_app_sid, v_profile_id, efpf.factor_type_id, efpf.region_sid, efpf.geo_country, efpf.geo_region, efpf.egrid_ref,
					efpf.custom_factor_set_id, v_start_dtm, v_end_dtm);

			END IF;

			-- write calc jobs
			calc_pkg.AddJobsForFactorType(efpf.factor_type_id);
		END LOOP;
	END IF;
END;

PROCEDURE INTERNAL_AddAppliedFactors
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
BEGIN
	FOR efp IN (SELECT profile_id
				FROM emission_factor_profile
			   WHERE app_sid = v_app_sid
			     AND applied = 1
				ORDER BY start_dtm)
	LOOP
		INT_AddAppliedFactorsProfile(efp.profile_id);
	END LOOP;
END;

PROCEDURE INTERNAL_UpdateProfileDates
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_last_profile_id 		emission_factor_profile.profile_id%TYPE;
BEGIN
	-- Set all the end dates to NULL to start with, as they're going to get updated later,
	-- and we then avoid any constraint issues while updating them and ensure the last
	-- one is always null.
	UPDATE emission_factor_profile
	   SET end_dtm = NULL
	 WHERE app_sid = v_app_sid;
	   
	-- Set the end dates.
	FOR r IN (
		SELECT profile_id, start_dtm, end_dtm, applied
		  FROM emission_factor_profile
		 WHERE app_sid = v_app_sid
		   AND applied = 1
		 ORDER BY start_dtm, name
		   FOR UPDATE
	)
	LOOP
		IF v_last_profile_id IS NOT NULL THEN
			-- Set end for prev profile.
			UPDATE emission_factor_profile
			   SET end_dtm = r.start_dtm
			 WHERE app_sid = v_app_sid
			   AND profile_id = v_last_profile_id;
		END IF;
		v_last_profile_id := r.profile_id;
	END LOOP;
END;

PROCEDURE CreateEmissionProfile(
	in_name					IN	emission_factor_profile.name%TYPE,
	in_applied				IN	emission_factor_profile.applied%TYPE,
	in_start_dtm			IN	emission_factor_profile.start_dtm%TYPE,
	out_profile_id			OUT	emission_factor_profile.profile_id%TYPE
)
AS
	v_app_sid				security.security_pkg.T_SID_ID := security.security_pkg.getapp;
	v_audit_info			VARCHAR2(1000);
BEGIN
	SELECT emission_factor_profile_id_seq.nextval
	  INTO out_profile_id
	  FROM DUAL;

	INSERT INTO emission_factor_profile	(profile_id, name, start_dtm, end_dtm, applied)
	VALUES (out_profile_id, in_name, in_start_dtm, NULL, NVL(in_applied, 0));

	INTERNAL_UpdateProfileDates;
	
	v_audit_info := 'Created Emission Profile "'|| SUBSTR(in_name, 1, 200) ||'" (id='|| out_profile_id ||', Applied='|| in_applied ||', StartDtm='|| in_start_dtm ||')';
	csr_data_pkg.WriteAuditLogEntry(security.security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, v_app_sid, out_profile_id, v_audit_info);
END;

PROCEDURE DeleteEmissionProfile(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	v_audit_info			VARCHAR2(1000);
BEGIN
	SELECT name, applied, start_dtm
	  INTO v_name, v_applied, v_start_dtm
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	DELETE FROM emission_factor_profile_factor
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	DELETE FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	IF v_applied = 1 THEN
		INTERNAL_UpdateProfileDates;
	END IF;
	INTERNAL_DeleteFactors(in_profile_id => in_profile_id);
	
	v_audit_info := 'Deleted Emission Profile "'|| SUBSTR(v_name, 1, 200) || '" (id='|| in_profile_id ||', Applied='|| v_applied || ', StartDtm='|| v_start_dtm || ')';
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, v_app_sid, in_profile_id, v_audit_info);
END;

PROCEDURE RenameEmissionProfile(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_new_name				IN emission_factor_profile.name%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_name					emission_factor_profile.name%TYPE;
	v_audit_info			VARCHAR2(1000);
BEGIN
	SELECT name
	  INTO v_name
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	UPDATE emission_factor_profile
	   SET name = in_new_name
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;
	   
	v_audit_info := 'Renamed Emission Profile from "'|| SUBSTR(v_name, 1, 200) || '" to "'|| SUBSTR(in_new_name, 1, 200) || '" (id='|| in_profile_id || ')';
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, v_app_sid, v_audit_info);
END;

PROCEDURE UpdateEmissionProfileStatus(
	in_profile_id			IN emission_factor_profile.profile_id%TYPE,
	in_applied				IN emission_factor_profile.applied%TYPE,
	in_start_dtm			IN emission_factor_profile.start_dtm%TYPE
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;

	v_name					emission_factor_profile.name%TYPE;
	v_applied				emission_factor_profile.applied%TYPE;
	v_start_dtm				emission_factor_profile.start_dtm%TYPE;
	
	v_audit_action			VARCHAR(50);
	v_audit_info			VARCHAR2(1000);
BEGIN
	SELECT name, applied, start_dtm
	  INTO v_name, v_applied, v_start_dtm
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;
	   
	 IF in_applied = v_applied AND in_start_dtm = v_start_dtm THEN
		-- No point doing anything if nothing changed.
		RETURN;
	 END IF;

	-- reset the end date to NULL to start with, avoids any constraint issues, prior to updating all the other dates.
	UPDATE emission_factor_profile
	   SET applied = in_applied, start_dtm = in_start_dtm, end_dtm = NULL
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	INTERNAL_UpdateProfileDates;
	INTERNAL_DeleteFactors;
	INTERNAL_AddAppliedFactors;

	IF v_applied != in_applied THEN
		v_audit_action := 'Applied';
		IF in_applied = 0 THEN
			v_audit_action := 'Unapplied';
		END IF;
		IF v_start_dtm = in_start_dtm THEN
			v_audit_info := ' Emission Profile "'|| SUBSTR(v_name, 1, 200) || '" id='|| in_profile_id ||', with start_dtm '|| v_start_dtm;
			csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, v_app_sid, in_profile_id,
				v_audit_action || v_audit_info);
		ELSE
			v_audit_info := ' Emission Profile "'|| SUBSTR(v_name, 1, 200) || '" id='|| in_profile_id ||', changing start_dtm from '|| v_start_dtm || ' to ' || in_start_dtm;
			csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, v_app_sid, in_profile_id,
				v_audit_action || v_audit_info);
		END IF;
	ELSE
		v_audit_info := 'Updated Emission Profile "'|| SUBSTR(v_name, 1, 200) || '" id='|| in_profile_id ||', changing start_dtm from '|| v_start_dtm || ' to ' || in_start_dtm;
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, v_app_sid, in_profile_id,
			v_audit_info);
	END IF;
END;

PROCEDURE RebuildEmissionProfileFactors
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	INTERNAL_DeleteFactors;
	INTERNAL_AddAppliedFactors;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.GetAct, csr_data_pkg.AUDIT_TYPE_FACTOR, security_pkg.GetApp, 0,
		'Rebuilt Emission Profile Factor data');
END;

PROCEDURE GetEmissionProfile(
	in_profile_id			IN emission_factor_profile.name%TYPE,
	out_cur_profile			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_factors			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_mapped			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_app_sid				security_pkg.T_SID_ID := security_pkg.getapp;
	v_root 					factor_type.factor_type_id%TYPE;
	v_profile_start_dtm 	emission_factor_profile.start_dtm%TYPE;
	v_profile_end_dtm 		emission_factor_profile.end_dtm%TYPE;
	v_applied		 		emission_factor_profile.applied%TYPE;
	v_factor_start_month	NUMBER(2);
BEGIN
	SELECT DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month
	  INTO v_factor_start_month
	  FROM customer
	 WHERE app_sid = v_app_sid;
	 
	SELECT NVL(start_dtm, SYSDATE), end_dtm, applied
	  INTO v_profile_start_dtm, v_profile_end_dtm, v_applied
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

	OPEN out_cur_profile FOR
		SELECT profile_id, name, start_dtm, end_dtm, applied
		  FROM emission_factor_profile
		 WHERE app_sid = v_app_sid
		   AND profile_id = in_profile_id;
	
	OPEN out_cur_factors FOR
		SELECT 
			  f.factor_type_id, f.std_factor_set_id, f.custom_factor_set_id,
			  f.region_sid, f.geo_country profile_factor_geo_country, f.geo_region profile_factor_geo_region, f.egrid_ref profile_factor_egrid_ref,
			  r.description local_region, r.geo_country region_geo_country, r.geo_region region_geo_region, r.egrid_ref region_egrid_ref, r.active region_active,
			  f.geo_country geo_country, f.geo_region geo_region, f.egrid_ref,
			  f.factor, f.factor_path,
			  fs.std_factor_set_id fs_std_factor_set_id, fs.name std_factor_set, 
			  cfs.custom_factor_set_id cfs_custom_factor_set_id, cfs.name custom_factor_set,
			  f.gas_type_id, f.gas,
			  NULL factor_id, f.value, 
			  f.start_dtm, f.end_dtm,
			  f.note, f.std_factor_id,
			  f.custom_factor_id,
			  smc.std_measure_conversion_id, smc.description unit,
			  pc.name country, pr.name region, e.name egrid
		 FROM (
			SELECT efpf.app_sid, efpf.profile_id, efpf.factor_type_id, efpf.std_factor_set_id, efpf.custom_factor_set_id,
					efpf.region_sid, efpf.geo_country profile_factor_geo_country, efpf.geo_region profile_factor_geo_region, efpf.egrid_ref profile_factor_egrid_ref,
					f.geo_country geo_country, f.geo_region geo_region, f.egrid_ref,
					ft.name factor, ft.path factor_path,
					gt.gas_type_id, gt.name gas,
					NULL factor_id, f.value,
					TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY') start_dtm,
					CASE
						WHEN f.end_dtm IS NULL THEN NULL
						ELSE ADD_MONTHS(TO_DATE(TO_CHAR(v_factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(f.end_dtm, f.start_dtm))
					END end_dtm,
					f.note, f.std_measure_conversion_id,
					f.std_factor_id, NULL custom_factor_id,
					rank() over (partition by efpf.factor_type_id, gt.gas_type_id order by f.start_dtm desc) rnk
			 FROM emission_factor_profile_factor efpf
			 JOIN (
				SELECT factor_type_id, TRIM(name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(name), '>>>'), FACTOR_PATH_SEPARATOR) path
				  FROM factor_type
				 WHERE parent_id IS NOT NULL
				 START WITH parent_id IS NULL
				CONNECT BY PRIOR factor_type_id = parent_id
				) ft ON ft.factor_type_id = efpf.factor_type_id
			 JOIN gas_type gt ON gt.gas_type_id IN (1,2,3,4)
			 JOIN std_factor f ON ft.factor_type_id = f.factor_type_id AND gt.gas_type_id = f.gas_type_id AND efpf.std_factor_set_id = f.std_factor_set_id
			WHERE efpf.profile_id = in_profile_id
			  AND efpf.app_sid = v_app_sid
			  AND (((v_profile_start_dtm IS NULL OR f.start_dtm <= v_profile_start_dtm) AND (f.end_dtm IS NULL OR f.end_dtm > v_profile_start_dtm)) OR
				   ((v_profile_start_dtm IS NULL OR f.start_dtm >= v_profile_start_dtm) AND (v_profile_end_dtm IS NULL OR f.start_dtm < v_profile_end_dtm)))
			UNION ALL 
			SELECT efpf.app_sid, efpf.profile_id, efpf.factor_type_id, efpf.std_factor_set_id, efpf.custom_factor_set_id,
					efpf.region_sid, efpf.geo_country profile_factor_geo_country, efpf.geo_region profile_factor_geo_region, efpf.egrid_ref profile_factor_egrid_ref,
					f.geo_country geo_country, f.geo_region geo_region, f.egrid_ref,
					ft.name factor, ft.path factor_path,
					gt.gas_type_id, gt.name gas,
					NULL factor_id, f.value,
					f.start_dtm, f.end_dtm,
					f.note, f.std_measure_conversion_id,
					NULL std_factor_id, f.custom_factor_id,
					rank() over (partition by efpf.factor_type_id, gt.gas_type_id order by f.start_dtm desc) rnk
			 FROM emission_factor_profile_factor efpf
			 JOIN (
				SELECT factor_type_id, TRIM(name) name, LTRIM(SYS_CONNECT_BY_PATH(TRIM(name), '>>>'), FACTOR_PATH_SEPARATOR) path
				  FROM factor_type
				 WHERE parent_id IS NOT NULL
				 START WITH parent_id IS NULL
				CONNECT BY PRIOR factor_type_id = parent_id
				) ft ON ft.factor_type_id = efpf.factor_type_id
			 JOIN gas_type gt ON gt.gas_type_id IN (1,2,3,4)
			 JOIN custom_factor f ON efpf.custom_factor_set_id = f.custom_factor_set_id
			  AND ft.factor_type_id = f.factor_type_id
			  AND gt.gas_type_id = f.gas_type_id
			  AND DECODE(f.geo_country, efpf.geo_country, 1, 0) = 1
			  AND DECODE(f.geo_region, efpf.geo_region, 1, 0) = 1
			  AND DECODE(f.egrid_ref, efpf.egrid_ref, 1, 0) = 1
			  AND DECODE(f.region_sid, efpf.region_sid, 1, 0) = 1
			WHERE efpf.profile_id = in_profile_id
			  AND efpf.app_sid = v_app_sid
			  AND (((v_profile_start_dtm IS NULL OR f.start_dtm <= v_profile_start_dtm) AND (f.end_dtm IS NULL OR f.end_dtm > v_profile_start_dtm)) OR
				   ((v_profile_start_dtm IS NULL OR f.start_dtm >= v_profile_start_dtm) AND (v_profile_end_dtm IS NULL OR f.start_dtm < v_profile_end_dtm)))
			) f
		LEFT JOIN v$region r ON r.region_sid = f.region_sid
		LEFT JOIN std_factor_set fs ON fs.std_factor_set_id = f.std_factor_set_id
		LEFT JOIN custom_factor_set cfs ON cfs.custom_factor_set_id = f.custom_factor_set_id
		LEFT JOIN std_measure_conversion smc ON f.std_measure_conversion_id = smc.std_measure_conversion_id
		LEFT JOIN postcode.country pc ON f.geo_country = pc.country AND f.geo_country = pc.country
		LEFT JOIN postcode.region pr ON pc.country = pr.country AND f.geo_region = pr.region AND f.geo_region = pr.region
		LEFT JOIN egrid e ON f.egrid_ref = e.egrid_ref AND f.egrid_ref = e.egrid_ref
		WHERE DECODE(f.egrid_ref, f.profile_factor_egrid_ref, 1, 0) = 1
		  AND DECODE(f.geo_country, f.profile_factor_geo_country, 1, 0) = 1
		  AND DECODE(f.geo_region, f.profile_factor_geo_region, 1, 0) = 1
		  AND DECODE(f.region_sid, r.region_sid, 1, 0) = 1
		ORDER BY factor, country, region, egrid, start_dtm, end_dtm, gas_type_id;
	
	SELECT factor_type_id 
	  INTO v_root
	  FROM factor_type 
	 WHERE parent_id IS NULL;

	-- Currently mapped factor/inds, restricted to the factor types in the profile, and ignoring the gas subindicators.
	OPEN out_cur_mapped FOR
		SELECT UNIQUE factor_type_id, factor_type_name, path, ind_sid, ind_description FROM (
			SELECT f.factor_type_id, TRIM(f.name) factor_type_name, sf.std_factor_set_id, NULL custom_factor_set_id,
				   CASE WHEN sfa.std_factor_set_id IS NULL THEN 0 ELSE 1 END active, 
				   ltrim(sys_connect_by_path(trim(f.name), '>>>'), FACTOR_PATH_SEPARATOR) path,
			 i.ind_sid, i.description ind_description, i.gas_type_id
			  FROM factor_type f
			  LEFT JOIN std_factor sf ON sf.factor_type_id = f.factor_type_id
			  LEFT JOIN std_factor_set_active sfa ON sfa.std_factor_set_id = sf.std_factor_set_id
			  LEFT JOIN v$ind i ON i.factor_type_id = f.factor_type_id
			 WHERE std_measure_id IS NOT NULL
			   AND sf.std_factor_set_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id 
			UNION 
			SELECT f.factor_type_id, TRIM(f.name) factor_type_name, NULL std_factor_set_id, sf.custom_factor_set_id, 
				   1 active, 
				   ltrim(sys_connect_by_path(trim(f.name), '>>>'), FACTOR_PATH_SEPARATOR) path,
				   i.ind_sid, i.description ind_description, i.gas_type_id
			  FROM factor_type f
			  LEFT JOIN custom_factor sf ON sf.factor_type_id = f.factor_type_id
			  LEFT JOIN v$ind i ON i.factor_type_id = f.factor_type_id
			 WHERE std_measure_id IS NOT NULL
			   AND sf.custom_factor_set_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id
			UNION
			SELECT f.factor_type_id, TRIM(f.name) factor_type_name, NULL std_factor_set_id, NULL custom_factor_set_id,
				   1 active, 
				   ltrim(sys_connect_by_path(trim(f.name), '>>>'), FACTOR_PATH_SEPARATOR) path,
					i.ind_sid, i.description ind_description, i.gas_type_id
			  FROM factor_type f
			  LEFT JOIN v$ind i ON i.factor_type_id = f.factor_type_id
			 WHERE f.factor_type_id = UNSPECIFIED_FACTOR_TYPE
			   AND std_measure_id IS NOT NULL
			 START WITH parent_id = v_root
			CONNECT BY PRIOR f.factor_type_id = parent_id) 
		 WHERE ind_sid is not NULL
		   AND factor_type_id IN (
			SELECT factor_type_id 
			  FROM emission_factor_profile_factor efpf
			 WHERE profile_id = in_profile_id
			   AND gas_type_id IS NULL
		   )
		 ORDER BY PATH ASC;
END;

PROCEDURE GetRegionsFactorsMap (
	in_profile_id		IN	emission_factor_profile.profile_id%TYPE,
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE,
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_custom			NUMBER(1);
	v_factor_set_name	VARCHAR2(1024);
	v_factor_type_name	VARCHAR2(1024);
BEGIN
	--Good ol' MIN stopping no data found.
	SELECT MIN(custom), MIN(name)  
	  INTO v_custom, v_factor_set_name
	  FROM (
		SELECT 1 custom, name
		  FROM custom_factor_set cfs
		 WHERE custom_factor_set_id = in_factor_set_id
		 UNION
		SELECT 0 custom, name
		  FROM std_factor_set sfs
		 WHERE std_factor_set_id = in_factor_set_id);
	
	SELECT MIN(name)
	  INTO v_factor_type_name
	  FROM factor_type
	 WHERE factor_type_id = in_factor_type_id;
	
	IF v_custom IS NULL THEN -- We have been passed a non existent factor set, just return location tree
		OPEN out_cur FOR 
			WITH main_region_tree AS (
				SELECT DISTINCT geo_country, geo_region, egrid_ref 
					  FROM v$region
					 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
				   CONNECT BY PRIOR region_sid = parent_sid
			)
			SELECT in_factor_type_id factor_type_id, v_factor_type_name factor_type_name, in_factor_set_id factor_set_id, v_factor_set_name factor_set_name,
				c.country, 
				CASE WHEN e.egrid_ref IS NULL THEN r.region ELSE NULL END region,
				e.egrid_ref, 
				NULL region_sid, 
				NULL fs_val_list, 
				CASE WHEN e.egrid_ref IS NOT NULL THEN e.name WHEN r.region IS NOT NULL THEN r.name WHEN c.country IS NOT NULL THEN c.name ELSE 'Global' END description, 
				0 custom, c.name country_name, r.name region_name, e.name egrid 
			  --Get all locations
			  FROM (SELECT country, name FROM postcode.country UNION SELECT NULL country, NULL name FROM DUAL) c
				--Main regions
			  JOIN (SELECT DISTINCT geo_country, NULL geo_region, NULL egrid_ref
					  FROM main_region_tree
				     UNION
					SELECT DISTINCT geo_country, geo_region, NULL egrid_ref
					  FROM main_region_tree
					 UNION
					SELECT DISTINCT geo_country, NULL geo_region, egrid_ref 
					  FROM main_region_tree
					 UNION
					SELECT NULL, NULL, NULL FROM DUAL) reg 
				ON DECODE(reg.geo_country, c.country , 1, 0) = 1
			  LEFT JOIN postcode.region r ON reg.geo_region = r.region AND reg.geo_country = r.country
			  LEFT JOIN egrid e ON reg.egrid_ref = e.egrid_ref;
	ELSIF v_custom = 0 THEN -- We have a std factor set
		OPEN out_cur FOR 
			WITH main_region_tree AS (
				SELECT DISTINCT geo_country, geo_region, egrid_ref 
					  FROM v$region
					 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
				   CONNECT BY PRIOR region_sid = parent_sid
			)
			SELECT factor_type_id, factor_type_name, factor_set_id, factor_set_name, 
				country,
				CASE WHEN egrid_ref IS NULL THEN region ELSE NULL END region,
				egrid_ref,
				region_sid, 
				TRIM(LISTAGG(CASE WHEN gas_name IS NULL THEN '' ELSE gas_name || ': ' END || CASE WHEN fs_val < 1 THEN RTRIM(TO_CHAR(fs_val, '0.000000000000000000000000000000'), '0') ELSE TO_CHAR(fs_val) END || ' ' || fs_val_m, ', ') WITHIN GROUP (ORDER BY gas_type_id)) fs_val_list,
				description, 
				custom, country_name, region_name, egrid 
			  FROM (
				SELECT in_factor_type_id factor_type_id, v_factor_type_name factor_type_name, in_factor_set_id factor_set_id, v_factor_set_name factor_set_name,
					c.country, r.region, e.egrid_ref, null region_sid, sf.value fs_val, smc1.description fs_val_m, sf.gas_type_id, gt.name gas_name,
					CASE WHEN e.egrid_ref IS NOT NULL THEN e.name
						 WHEN r.region IS NOT NULL THEN r.name
						 WHEN c.country IS NOT NULL THEN c.name
						 ELSE 'Global'
					END description,
					v_custom custom, c.name country_name, r.name region_name, e.name egrid 
				  --Get all locations
				  FROM (SELECT country, name FROM postcode.country UNION SELECT NULL country, NULL name FROM DUAL) c 
					--Main regions
				  JOIN (SELECT DISTINCT geo_country, NULL geo_region, NULL egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT DISTINCT geo_country, geo_region, NULL egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT DISTINCT geo_country, NULL geo_region, egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT NULL, NULL, NULL FROM DUAL) reg 
					ON DECODE(reg.geo_country, c.country , 1, 0) = 1
				  LEFT JOIN postcode.region r ON reg.geo_region = r.region AND reg.geo_country = r.country
				  LEFT JOIN egrid e ON reg.egrid_ref = e.egrid_ref
				  -- Get selected factor set values
				  LEFT JOIN std_factor sf ON 
					DECODE(reg.egrid_ref, sf.egrid_ref, 1, 0) = 1 AND
					DECODE(r.region , sf.geo_region, 1, 0) = 1 AND
					DECODE(c.country , sf.geo_country, 1, 0) = 1 AND
					sf.factor_type_id = in_factor_type_id AND
					sf.std_factor_set_id = in_factor_set_id AND
					sf.gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)
				  LEFT JOIN std_measure_conversion smc1 ON sf.std_measure_conversion_id = smc1.std_measure_conversion_id
				  LEFT JOIN factor_type ft ON ft.factor_type_id = sf.factor_type_id
				  LEFT JOIN std_factor_set sfs ON sf.std_factor_set_id = sfs.std_factor_set_id
				  LEFT JOIN gas_type gt ON sf.gas_type_id = gt.gas_type_id
				 WHERE (sf.start_dtm IS NULL OR sf.start_dtm IN (SELECT MAX(start_dtm) FROM std_factor WHERE 
					DECODE(egrid_ref, sf.egrid_ref, 1, 0) = 1 AND
					DECODE(geo_region , sf.geo_region, 1, 0) = 1 AND
					DECODE(geo_country , sf.geo_country, 1, 0) = 1 AND
					factor_type_id = sf.factor_type_id AND
					std_factor_set_id = sf.std_factor_set_id AND
					sf.gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)))
				)
			GROUP BY factor_type_id, factor_type_name, factor_set_id, factor_set_name, country, region, egrid_ref, region_sid,
					 description, custom, country_name, region_name, egrid;
	ELSIF v_custom = 1 THEN -- We have a custom factor set
		OPEN out_cur FOR
			WITH main_region_tree AS (
				SELECT DISTINCT geo_country, geo_region, egrid_ref 
					  FROM v$region
					 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
				   CONNECT BY PRIOR region_sid = parent_sid
			)
			SELECT factor_type_id, factor_type_name, factor_set_id, factor_set_name,
				country,
				CASE WHEN egrid_ref IS NULL THEN region ELSE NULL END region,
				egrid_ref,
				region_sid, 
				TRIM(LISTAGG(CASE WHEN gas_name IS NULL THEN '' ELSE gas_name || ': ' END || CASE WHEN fs_val < 1 THEN RTRIM(TO_CHAR(fs_val, '0.000000000000000000000000000000'), '0') ELSE TO_CHAR(fs_val) END || ' ' || fs_val_m, ', ') WITHIN GROUP (ORDER BY gas_type_id)) fs_val_list,
				description, 
				custom, country_name, region_name, egrid 
			  FROM (
				SELECT in_factor_type_id factor_type_id, v_factor_type_name factor_type_name, in_factor_set_id factor_set_id, v_factor_set_name factor_set_name,
					c.country, r.region, e.egrid_ref, null region_sid, cf.value fs_val, smc1.description fs_val_m, cf.gas_type_id, gt.name gas_name,
					CASE WHEN e.egrid_ref IS NOT NULL THEN e.name
						 WHEN r.region IS NOT NULL THEN r.name
						 WHEN c.country IS NOT NULL THEN c.name
						 ELSE 'Global'
					END description,
					v_custom custom, c.name country_name, r.name region_name, e.name egrid 
				  --Get all locations + global
				  FROM (SELECT country, name FROM postcode.country UNION SELECT NULL country, NULL name FROM DUAL) c  
					--Main regions
				  JOIN (SELECT DISTINCT geo_country, NULL geo_region, NULL egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT DISTINCT geo_country, geo_region, NULL egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT DISTINCT geo_country, NULL geo_region, egrid_ref 
						  FROM main_region_tree
						 UNION
						SELECT NULL, NULL, NULL FROM DUAL) reg 
					ON DECODE(reg.geo_country, c.country , 1, 0) = 1
				  LEFT JOIN postcode.region r ON reg.geo_region = r.region AND reg.geo_country = r.country
				  LEFT JOIN egrid e ON reg.egrid_ref = e.egrid_ref
				  -- Get selected factor set values
				  LEFT JOIN custom_factor cf ON
					DECODE(reg.egrid_ref , cf.egrid_ref, 1, 0) = 1 AND
					DECODE(reg.geo_region, cf.geo_region, 1, 0) = 1 AND
					DECODE(c.country , cf.geo_country, 1, 0) = 1 AND
					cf.region_sid is NULL AND
					cf.factor_type_id = in_factor_type_id AND
					cf.custom_factor_set_id = in_factor_set_id AND
					cf.gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)
				  LEFT JOIN std_measure_conversion smc1 ON cf.std_measure_conversion_id = smc1.std_measure_conversion_id
				  LEFT JOIN gas_type gt ON cf.gas_type_id = gt.gas_type_id
				 WHERE (cf.start_dtm IS NULL OR cf.start_dtm IN (SELECT MAX(start_dtm) FROM custom_factor WHERE 
					DECODE(egrid_ref, cf.egrid_ref, 1, 0) = 1 AND
					DECODE(geo_region , cf.geo_region, 1, 0) = 1 AND
					DECODE(geo_country , cf.geo_country, 1, 0) = 1 AND
					region_sid IS NULL AND
					factor_type_id = cf.factor_type_id AND
					custom_factor_set_id = cf.custom_factor_set_id AND
					cf.gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)))
				UNION
				SELECT in_factor_type_id factor_type_id, v_factor_type_name factor_type_name, in_factor_set_id factor_set_id, v_factor_set_name factor_set_name,
					cf.geo_country country, r.region region, cf.egrid_ref, cf.region_sid, cf.value fs_val, smc.description fs_val_m, cf.gas_type_id, gt.name gas_name,
					r.description, 
					v_custom custom, c.name country_name, r.name region_name, e.name egrid
				  FROM custom_factor cf
				  JOIN v$region r ON cf.region_sid = r.region_sid
				  JOIN std_measure_conversion smc ON cf.std_measure_conversion_id = smc.std_measure_conversion_id	  
				  LEFT JOIN postcode.country c ON c.country = cf.geo_country
				  LEFT JOIN postcode.region r ON r.country = cf.geo_country AND r.region = cf.geo_region
				  LEFT JOIN csr.egrid e ON e.egrid_ref = cf.egrid_ref
				  LEFT JOIN gas_type gt ON cf.gas_type_id = gt.gas_type_id
				 WHERE cf.custom_factor_set_id = in_factor_set_id
				   AND cf.factor_type_id = in_factor_type_id
				   AND cf.start_dtm IN (SELECT MAX(start_dtm) FROM custom_factor WHERE 
					region_sid = cf.region_sid AND 
					factor_type_id = cf.factor_type_id AND 
					cf.gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O))
				)
			GROUP BY factor_type_id, factor_type_name, factor_set_id, factor_set_name, country, region, egrid_ref, region_sid,
					 description, custom, country_name, region_name, egrid;
	END IF;
END;

PROCEDURE GetActiveFactorSets (
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE,
	in_geo_ids			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_geo_table	security.T_VARCHAR2_TABLE;
	v_geo_cnt	NUMBER(10);
BEGIN
	
	v_geo_table := security.security_pkg.Varchar2ArrayToTable(in_geo_ids);
	v_geo_cnt := CASE (in_geo_ids IS NULL OR in_geo_ids.COUNT = 0 OR (in_geo_ids.COUNT = 1 AND in_geo_ids(1) IS NULL)) WHEN TRUE THEN 0 ELSE 1 END;
	
	OPEN out_cur FOR
		SELECT sfs.std_factor_set_id factor_set_id, sfs.name factor_set_name, sfs.factor_set_group_id, fsg.name group_name, fsg.custom, sfs.info_note
		  FROM std_factor_set sfs
		  JOIN std_factor_set_active a ON sfs.std_factor_set_id = a.std_factor_set_id
		  JOIN factor_set_group fsg ON sfs.factor_set_group_id = fsg.factor_set_group_id
		 WHERE (v_geo_cnt = 0 OR EXISTS (
									SELECT NULL 
									  FROM std_factor sf 
									  JOIN TABLE(v_geo_table) t ON sf.geo_country = t.value OR sf.geo_country IS NULL
									 WHERE std_factor_set_id = sfs.std_factor_set_id AND sf.factor_type_id = NVL(in_factor_type_id, sf.factor_type_id))
				)
		   AND EXISTS (
					SELECT NULL 
					  FROM std_factor
					 WHERE factor_type_id = NVL(in_factor_type_id, factor_type_id) AND std_factor_set_id = sfs.std_factor_set_id
			)
		 UNION ALL
		SELECT cfs.custom_factor_set_id factor_set_id, cfs.name factor_set_name, cfs.factor_set_group_id, fsg.name group_name, fsg.custom, cfs.info_note
		  FROM custom_factor_set cfs
		  JOIN factor_set_group fsg ON cfs.factor_set_group_id = fsg.factor_set_group_id
		 ORDER BY custom ASC, group_name ASC, factor_set_name ASC; 
END;

PROCEDURE GetProfileFactorMap (
	in_profile_id	IN	emission_factor_profile.profile_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pf.profile_id, pf.factor_type_id, ft.name factor_type_name, NVL(cfs.custom_factor_set_id, sfs.std_factor_set_id) factor_set_id, 
			NVL(cfs.name, sfs.name) factor_set_name, pf.region_sid, pf.geo_country country, pf.geo_region region, pf.egrid_ref, decode(pf.std_factor_set_id, null, 1, 0) custom,
			NVL(cf.value, sf.value) fs_val, m.description fs_val_m, gt.gas_type_id gas_type_id, gt.name gas_name
		  FROM emission_factor_profile_factor pf
		  JOIN factor_type ft ON pf.factor_type_id = ft.factor_type_id
		  LEFT JOIN custom_factor_set cfs ON pf.custom_factor_set_id = cfs.custom_factor_set_id
		  LEFT JOIN std_factor_set sfs ON pf.std_factor_Set_id = sfs.std_factor_set_id
		  LEFT JOIN custom_factor cf ON pf.custom_factor_set_id = cf.custom_factor_set_id AND pf.factor_type_id = cf.factor_type_id
				AND DECODE(pf.geo_country, cf.geo_country, 1, 0) = 1
				AND DECODE(pf.geo_region, cf.geo_region, 1, 0) = 1
				AND DECODE(pf.egrid_ref, cf.egrid_ref, 1, 0) = 1
				AND DECODE(pf.region_sid, cf.region_sid, 1, 0) = 1
				AND cf.gas_type_id = csr_data_pkg.GAS_TYPE_CO2E
		  LEFT JOIN std_factor sf ON pf.std_factor_set_id = sf.std_factor_set_id AND pf.factor_type_id = sf.factor_type_id
				AND DECODE(pf.geo_country, sf.geo_country, 1, 0) = 1
				AND DECODE(pf.geo_region, sf.geo_region, 1, 0) = 1
				AND DECODE(pf.egrid_ref, sf.egrid_ref, 1, 0) = 1
				AND sf.gas_type_id = csr_data_pkg.GAS_TYPE_CO2E
		  LEFT JOIN std_measure_conversion m ON m.std_measure_conversion_id = cf.std_measure_conversion_id OR m.std_measure_conversion_id = sf.std_measure_conversion_id
		  LEFT JOIN gas_type gt ON gt.gas_type_id = cf.gas_type_id
		 WHERE pf.profile_id = in_profile_id
		 AND (cf.start_dtm IS NULL OR cf.start_dtm IN (SELECT MAX(start_dtm) FROM custom_factor WHERE
			DECODE(egrid_ref, cf.egrid_ref, 1, 0) = 1 AND
			DECODE(geo_region , cf.geo_region, 1, 0) = 1 AND
			DECODE(geo_country , cf.geo_country, 1, 0) = 1 AND
			DECODE(region_sid, cf.region_sid, 1, 0) = 1 AND
			factor_type_id = cf.factor_type_id AND custom_factor_set_id = cf.custom_factor_set_id AND gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)))
		 AND (sf.start_dtm IS NULL OR sf.start_dtm IN (SELECT MAX(start_dtm) FROM std_factor WHERE 
			DECODE(egrid_ref, sf.egrid_ref, 1, 0) = 1 AND
			DECODE(geo_region , sf.geo_region, 1, 0) = 1 AND
			DECODE(geo_country , sf.geo_country, 1, 0) = 1 AND
			factor_type_id = sf.factor_type_id AND std_factor_set_id = sf.std_factor_set_id AND gas_type_id IN (csr_data_pkg.GAS_TYPE_CO2, csr_data_pkg.GAS_TYPE_CO2E, csr_data_pkg.GAS_TYPE_CH4, csr_data_pkg.GAS_TYPE_N2O)))
		 ORDER BY ft.name, ft.factor_type_id, region_sid, country NULLS FIRST, region NULLS FIRST, egrid_ref NULLS FIRST, gas_type_id;
END;

PROCEDURE GetAllFactors (
	in_factor_type_id	IN	factor_type.factor_type_id%TYPE, 
	in_factor_set_id	IN	std_factor_set.std_factor_set_id%TYPE, 
	in_country			IN	factor.geo_country%TYPE, 
	in_region			IN	factor.geo_region%TYPE, 
	in_region_sid		IN	factor.region_sid%TYPE,
	period_cur			OUT	SYS_REFCURSOR,
	gas_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN period_cur FOR
		SELECT DISTINCT start_dtm, end_dtm
		  FROM custom_factor f
		  JOIN (SELECT app_sid, DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month FROM csr.customer) o ON security_pkg.GetApp = o.app_sid
		 WHERE f.factor_type_id = in_factor_type_id
		   AND f.custom_factor_set_id = in_factor_set_id
		   AND DECODE(f.geo_country, in_country, 1, 0) = 1
		   AND (in_region = f.egrid_ref OR in_region = f.geo_region OR (f.egrid_ref IS NULL AND f.geo_region IS NULL AND in_region IS NULL))
		   AND DECODE(f.region_sid, in_region_sid, 1, 0) = 1
		 UNION
		SELECT DISTINCT 
				TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY') start_dtm,
				CASE 
					WHEN f.end_dtm IS NULL THEN NULL
					ELSE ADD_MONTHS(TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(f.end_dtm, f.start_dtm))
				END end_dtm
		  FROM std_factor f
		  JOIN (SELECT app_sid, DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month FROM csr.customer) o ON security_pkg.GetApp = o.app_sid
		 WHERE f.factor_type_id = in_factor_type_id
		   AND f.std_factor_set_id  = in_factor_set_id
		   AND DECODE(f.geo_country, in_country, 1, 0) = 1
		   AND (in_region = f.egrid_ref OR in_region = f.geo_region OR (f.egrid_ref IS NULL AND f.geo_region IS NULL AND in_region IS NULL));

	OPEN gas_cur FOR
		SELECT f.custom_factor_id factor_id, ft.name factor, gt.gas_type_id, gt.name, f.value, f.note,
				start_dtm, end_dtm,
				m.description unit, m.std_measure_conversion_id unit_id  
		  FROM custom_factor f
		  JOIN factor_type ft ON f.factor_type_id = ft.factor_type_id
		  JOIN gas_type gt ON f.gas_type_id = gt.gas_type_id
		  JOIN std_measure_conversion m ON f.std_measure_conversion_id = m.std_measure_conversion_id
		  JOIN (SELECT app_sid, DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month FROM csr.customer) o ON security_pkg.GetApp = o.app_sid
		 WHERE f.factor_type_id = in_factor_type_id
		   AND f.custom_factor_set_id = in_factor_set_id
		   AND DECODE(f.geo_country, in_country, 1, 0) = 1
		   AND (in_region = f.egrid_ref OR in_region = f.geo_region OR (f.egrid_ref IS NULL AND f.geo_region IS NULL AND in_region IS NULL))
		   AND DECODE(f.region_sid, in_region_sid, 1, 0) = 1
		 UNION ALL
		SELECT f.std_factor_id factor_id, ft.name factor, gt.gas_type_id, gt.name, f.value, f.note, 
				TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY') start_dtm,
				CASE 
					WHEN f.end_dtm IS NULL THEN NULL
					ELSE ADD_MONTHS(TO_DATE(TO_CHAR(factor_start_month, '09') || TO_CHAR(f.start_dtm,'YYYY'), 'MMYYYY'), MONTHS_BETWEEN(f.end_dtm, f.start_dtm))
				END end_dtm,
				m.description unit, m.std_measure_conversion_id unit_id 
		  FROM std_factor f
		  JOIN factor_type ft ON f.factor_type_id = ft.factor_type_id
		  JOIN gas_type gt ON f.gas_type_id = gt.gas_type_id
		  JOIN std_measure_conversion m ON f.std_measure_conversion_id = m.std_measure_conversion_id
		  JOIN (SELECT app_sid, DECODE(adj_factorset_startmonth, 0, 1, 1, start_month) factor_start_month FROM csr.customer) o ON security_pkg.GetApp = o.app_sid
		 WHERE f.factor_type_id = in_factor_type_id
		   AND f.std_factor_set_id  = in_factor_set_id
		   AND DECODE(f.geo_country, in_country, 1, 0) = 1
		   AND (in_region = f.egrid_ref OR in_region = f.geo_region OR (f.egrid_ref IS NULL AND f.geo_region IS NULL AND in_region IS NULL))
		 ORDER BY gas_type_id; 
END;

PROCEDURE GetAuditLogForCustomFactor(
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_factor_type_id		IN	factor_type.factor_type_id%TYPE,
	in_factor_set_id		IN	custom_factor.custom_factor_set_id%TYPE,
	in_country				IN	custom_factor.geo_country%TYPE, 
	in_region				IN	custom_factor.geo_region%TYPE, 
	in_egrid_ref			IN	custom_factor.egrid_ref%TYPE,
	in_region_sid			IN	custom_factor.region_sid%TYPE,
	in_start_row			IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_start_date			IN	DATE,
	in_end_date				IN	DATE,
	out_total				OUT	NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	SELECT COUNT(*)
	  INTO out_total
	  FROM custom_factor_history cfh
	 WHERE cfh.factor_cat_id = csr_data_pkg.FACTOR_CAT_CUSTOM
	   AND cfh.factor_type_id = in_factor_type_id
	   AND cfh.factor_set_id = in_factor_set_id
	   AND DECODE(cfh.geo_country, in_country, 1, 0) = 1
	   AND DECODE(cfh.geo_region, in_region, 1, 0) = 1
	   AND DECODE(cfh.egrid_ref, in_egrid_ref, 1, 0) = 1
	   AND DECODE(cfh.region_sid, in_region_sid, 1, 0) = 1
	   AND cfh.audit_date >= in_start_date AND cfh.audit_date <= in_end_date+1;
	
	OPEN out_cur FOR
		SELECT audit_date, message, full_name, user_name, csr_user_sid, gas_type_id, start_dtm, end_dtm, field_name, old_val, new_val, gas
		
		  FROM (
		  	SELECT ROWNUM rn, x.*
		  	  FROM (
				SELECT cfh.audit_date, cfh.message, cu.full_name, cu.user_name, cu.csr_user_sid, cfh.gas_type_id, cfh.start_dtm,
					cfh.end_dtm, cfh.field_name, cfh.old_val, cfh.new_val, gt.name gas
			      FROM custom_factor_history cfh
				  JOIN csr_user cu ON cfh.user_sid = cu.csr_user_sid
				  JOIN gas_type gt ON cfh.gas_type_id = gt.gas_type_id
				 WHERE cfh.factor_cat_id = csr_data_pkg.FACTOR_CAT_CUSTOM
				   AND cfh.factor_type_id = in_factor_type_id
				   AND cfh.factor_set_id = in_factor_set_id
				   AND DECODE(cfh.geo_country, in_country, 1, 0) = 1
				   AND DECODE(cfh.geo_region, in_region, 1, 0) = 1
				   AND DECODE(cfh.egrid_ref, in_egrid_ref, 1, 0) = 1
				   AND DECODE(cfh.region_sid, in_region_sid, 1, 0) = 1
				   AND cfh.audit_date >= in_start_date AND cfh.audit_date <= in_end_date+1
			 	 ORDER BY audit_date DESC, ROWNUM DESC
			  )x
			 WHERE rownum < in_start_row + in_page_size
		    )
		 WHERE rn >= in_start_row
		 ORDER BY audit_date DESC;
END;

PROCEDURE WriteFactorLogEntry(
	in_factor_cat_id		IN	custom_factor_history.factor_cat_id%TYPE,
	in_factor_type_id		IN	custom_factor_history.factor_type_id%TYPE,
	in_factor_set_id		IN	custom_factor_history.factor_set_id%TYPE,
	in_country				IN	custom_factor_history.geo_country%TYPE,
	in_region				IN 	custom_factor_history.geo_region%TYPE,
	in_egrid_ref			IN	custom_factor_history.egrid_ref%TYPE,
	in_region_sid			IN	custom_factor_history.region_sid%TYPE,
	in_gas_type_id			IN	custom_factor_history.gas_type_id%TYPE,
	in_start_dtm			IN	custom_factor_history.start_dtm%TYPE,
	in_end_dtm				IN	custom_factor_history.end_dtm%TYPE,
	in_field_name			in	custom_factor_history.field_name%TYPE DEFAULT NULL,
	in_old_val				IN	custom_factor_history.old_val%TYPE DEFAULT NULL,
	in_new_val				IN	custom_factor_history.new_val%TYPE DEFAULT NULL,
	in_message				IN	custom_factor_history.message%TYPE
)
AS
BEGIN
	INSERT INTO custom_factor_history
	(custom_factor_history_id, factor_cat_id, factor_type_id, factor_set_id, geo_country, geo_region, egrid_ref, region_sid, gas_type_id,
		start_dtm, end_dtm, field_name, old_val, new_val, message)
	VALUES
	(custom_factor_history_seq.nextval, in_factor_cat_id, in_factor_type_id, in_factor_set_id, in_country, in_region, in_egrid_ref, in_region_sid,
		in_gas_type_id, in_start_dtm, in_end_dtm, in_field_name, in_old_val, in_new_val, in_message);
END;

PROCEDURE AprxDelProfFactors(
	in_profile_id	IN	emission_factor_profile.profile_id%TYPE
)
AS
	v_audit_info	VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	FOR R IN (
		SELECT factor_type_id, std_factor_set_id, custom_factor_set_id, region_sid, geo_country, geo_region, egrid_ref
		  FROM emission_factor_profile_factor
		 WHERE profile_id = in_profile_id
	) 
	LOOP
		v_audit_info := 'Updated Emission Profile id= ' || in_profile_id || 'removed factor for (
			factor_type_id = ' || r.factor_type_id ||
			', factor_set_id = ' || NVL(r.custom_factor_set_id, r.std_factor_set_id) ||
			', geo_country = ' || r.geo_country ||
			', geo_region = ' || r.geo_region ||
			', egrid_ref = ' || r.egrid_ref ||
			', region_sid = ' || r.region_sid || ')';
			
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
			v_audit_info);
	END LOOP;
	
	DELETE FROM emission_factor_profile_factor
	 WHERE profile_id = in_profile_id; 
END;

PROCEDURE AprxDelProfileSetFactors(
	in_profile_id				IN	emission_factor_profile.profile_id%TYPE,
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE,
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE
)
AS
	v_audit_info	VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	IF in_custom_factor_set_id IS NOT NULL THEN
		DELETE FROM emission_factor_profile_factor
		 WHERE app_sid = security_pkg.getApp
		   AND profile_id = in_profile_id
		   AND factor_type_id = in_factor_type_id
		   AND custom_factor_set_id = in_custom_factor_set_id;

		v_audit_info := 'Deleted orphan emission_factor_profile_factor records for Profile id= ' || in_profile_id||', factor_type_id='||in_factor_type_id||', custom_factor_set_id='||in_custom_factor_set_id;
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
			v_audit_info);
	END IF;
END;

PROCEDURE AprxSaveProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE,
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
)
AS
	v_audit_info	VARCHAR2(1000);
BEGIN
	-- Security handled by AprxDelProfFactors as is called in same transaction, not checking here as called as array binds and don't want lots of wasted checks 
	
	INSERT INTO emission_factor_profile_factor
	(profile_id, factor_type_id, std_factor_set_id, custom_factor_set_id, region_sid, geo_country, geo_region, egrid_ref)
	VALUES
	(in_profile_id, in_factor_type_id, in_std_factor_set_id, in_custom_factor_set_id, in_region_sid, in_geo_country, in_geo_region, in_egrid_ref);
	
	v_audit_info := 'Updated Emission Profile id= ' || in_profile_id || 'added factor for (
		factor_type_id = ' || in_factor_type_id ||
		', factor_set_id = ' || NVL(in_custom_factor_set_id, in_std_factor_set_id) ||
		', geo_country = ' || in_geo_country ||
		', geo_region = ' || in_geo_region ||
		', egrid_ref = ' || in_egrid_ref ||
		', region_sid = ' || in_region_sid || ')';
			
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
		v_audit_info);
END;

PROCEDURE SaveProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE,
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
)
AS
	v_audit_info	VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	BEGIN
		INSERT INTO emission_factor_profile_factor
		(profile_id, factor_type_id, std_factor_set_id, custom_factor_set_id, region_sid, geo_country, geo_region, egrid_ref)
		VALUES
		(in_profile_id, in_factor_type_id, in_std_factor_set_id, in_custom_factor_set_id, in_region_sid, in_geo_country, in_geo_region, in_egrid_ref);
		
		v_audit_info := 'Updated Emission Profile id= ' || in_profile_id || 'added factor for (
			factor_type_id = ' || in_factor_type_id ||
			', factor_set_id = ' || NVL(in_custom_factor_set_id, in_std_factor_set_id) ||
			', geo_country = ' || in_geo_country ||
			', geo_region = ' || in_geo_region ||
			', egrid_ref = ' || in_egrid_ref ||
			', region_sid = ' || in_region_sid || ')';
				
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
			v_audit_info);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
END;

PROCEDURE DeleteProfileFactor (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE,
	in_factor_type_id			IN	emission_factor_profile_factor.factor_type_id%TYPE, 
	in_std_factor_set_id		IN	emission_factor_profile_factor.std_factor_set_id%TYPE, 
	in_custom_factor_set_id		IN	emission_factor_profile_factor.custom_factor_set_id%TYPE, 
	in_region_sid				IN	emission_factor_profile_factor.region_sid%TYPE, 
	in_geo_country				IN	emission_factor_profile_factor.geo_country%TYPE, 
	in_geo_region				IN	emission_factor_profile_factor.geo_region%TYPE, 
	in_egrid_ref				IN	emission_factor_profile_factor.egrid_ref%TYPE
)
AS
	v_audit_info	VARCHAR2(1000);
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Manage emission factors') AND csr_user_pkg.IsSuperAdmin <> 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Permission denied due to lack of the "Manage emission factors" capability');
	END IF;
	
	DELETE FROM emission_factor_profile_factor
	 WHERE profile_id = in_profile_id
	   AND factor_type_id = in_factor_type_id
	   AND NVL(std_factor_set_id, -1) = NVL(in_std_factor_set_id, -1)
	   AND NVL(custom_factor_set_id, -1) = NVL(in_custom_factor_set_id, -1)
	   AND NVL(region_sid, -1) = NVL(in_region_sid, -1)
	   AND NVL(geo_country, -1) = NVL(in_geo_country, -1)
	   AND NVL(geo_region, -1) = NVL(in_geo_region, -1)
	   AND NVL(egrid_ref, -1) = NVL(in_egrid_ref, -1);
	
	v_audit_info := 'Updated Emission Profile id= ' || in_profile_id || 'deleted factor for (
		factor_type_id = ' || in_factor_type_id ||
		', factor_set_id = ' || NVL(in_custom_factor_set_id, in_std_factor_set_id) ||
		', geo_country = ' || in_geo_country ||
		', geo_region = ' || in_geo_region ||
		', egrid_ref = ' || in_egrid_ref ||
		', region_sid = ' || in_region_sid || ')';
			
	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
		v_audit_info);
END;

PROCEDURE UpdateEmissionProfileFactors (
	in_profile_id				IN	emission_factor_profile.profile_id%TYPE
)
AS
	v_applied		emission_factor_profile.applied%TYPE;
BEGIN
	SELECT applied INTO v_applied
	  FROM emission_factor_profile
	 WHERE profile_id = in_profile_id
	   AND app_sid = security.security_pkg.getApp;

	IF v_applied =  1 THEN
		
		INTERNAL_DeleteFactors;
		INTERNAL_AddAppliedFactors;
		UpdateSubRegionFactors;
		csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_profile_id,
			'Updated factors for Emission Profile id= ' || in_profile_id);
	END IF;
END;


FUNCTION GetDateForMigratedNewProfile RETURN DATE
AS
	v_date		DATE;
BEGIN

	SELECT MIN(start_dtm)
	  INTO v_date
	  FROM factor
	 WHERE app_sid = security_pkg.getApp;

	RETURN v_date;
END;

PROCEDURE AddStdProfleFactorsFromFactors (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
)
AS
BEGIN

	-- Only inserting std factor in the profile for now.
	INSERT INTO emission_factor_profile_factor
		(profile_id, factor_type_id, std_factor_set_id, region_sid, geo_country, geo_region, egrid_ref)
	SELECT in_profile_id, f.factor_type_id, fs.std_factor_set_id, f.region_sid, f.geo_country, f.geo_region,
		f.egrid_ref
	  FROM factor f
	  JOIN std_factor stdf ON f.std_factor_id = stdf.std_factor_id
	  JOIN std_factor_set fs ON stdf.std_factor_set_id = fs.std_factor_set_id
	 WHERE f.app_sid = security_pkg.getApp
	   AND f.is_selected = 1
	 GROUP BY f.factor_type_id, fs.std_factor_set_id, f.region_sid, f.geo_country, f.geo_region,
		f.egrid_ref;
END;

PROCEDURE AddCustomFactorsToProfile (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
)
AS
BEGIN

	-- Only inserting custom factors here
	INSERT INTO emission_factor_profile_factor
		(profile_id, factor_type_id, custom_factor_set_id, region_sid, geo_country, geo_region, egrid_ref)
	SELECT in_profile_id, f.factor_type_id, cf.custom_factor_set_id, f.region_sid, f.geo_country, f.geo_region,
		f.egrid_ref
	  FROM factor f
	  JOIN custom_factor cf ON f.custom_factor_id = cf.custom_factor_id
	 WHERE f.app_sid = security_pkg.getApp
	   AND f.is_selected = 1
	 GROUP BY f.factor_type_id, cf.custom_factor_set_id, f.region_sid, f.geo_country, f.geo_region,
		f.egrid_ref;
END;

PROCEDURE CreateCustomFactorsFromFactors (
	in_custom_factor_set_id		IN	custom_factor.custom_factor_set_id%TYPE,
	in_get_overrides			IN	NUMBER
)
AS
	v_factor_id					custom_factor.custom_factor_id%TYPE;
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	-- Bespoke factors don't have region_sid
	-- Override factors have region_sid
	FOR r IN (
		SELECT factor_id, factor_type_id, custom_factor_id, region_sid, geo_country, geo_region, egrid_ref, start_dtm, end_dtm,
			gas_type_id, value, std_measure_conversion_id, note
		  FROM factor
		 WHERE app_sid = security_pkg.getApp
		   AND std_factor_id IS NULL
		   AND custom_factor_id IS NULL
		   AND is_selected = 1
		   AND (in_get_overrides > 0 AND region_sid IS NOT NULL
			OR (in_get_overrides <= 0 AND region_sid IS NULL))
	)
	LOOP
		InsertCustomValue(
			in_factor_type_id => r.factor_type_id,
			in_custom_factor_set_id => in_custom_factor_set_id,
			in_geo_country => r.geo_country,
			in_geo_region => r.geo_region,
			in_egrid_ref => r.egrid_ref,
			in_region_sid => r.region_sid,
			in_start_dtm => r.start_dtm,
			in_end_dtm => r.end_dtm,
			in_gas_type_id => r.gas_type_id,
			in_value => r.value,
			in_std_meas_conv_id => r.std_measure_conversion_id,
			in_note => r.note,
			out_custom_factor_id => v_factor_id
		);

		UPDATE factor
		   SET custom_factor_id = v_factor_id
		 WHERE factor_id = r.factor_id
		   AND app_sid = v_app_sid;

	END LOOP;
END;

PROCEDURE RunProfileChecksForMigration (
	in_profile_name		IN	VARCHAR2
)
AS
	v_app_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_count				NUMBER;
BEGIN

	-- Check if profile name is already in use.
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND UPPER(name) = UPPER(in_profile_name);

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Profile name already exists.');
	END IF;

	-- Check if there is an active profile.
	SELECT COUNT(*)
	  INTO v_count
	  FROM emission_factor_profile
	 WHERE app_sid = v_app_sid
	   AND applied = 1;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Migration tool is not compatible with active profiles.');
	END IF;
END;

FUNCTION CheckExistingCustomSets (
	in_check_overrides_only		IN	NUMBER
) RETURN NUMBER
AS
	v_count						NUMBER;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM factor
	 WHERE app_sid = security_pkg.getApp
	   AND std_factor_id IS NULL
	   AND custom_factor_id IS NULL
	   AND (in_check_overrides_only > 0 AND region_sid IS NOT NULL
		OR (in_check_overrides_only <= 0 AND region_sid IS NULL));

	RETURN v_count;

END;

PROCEDURE SetEndDateProfileOnMigration (
	in_profile_id				IN	emission_factor_profile_factor.profile_id%TYPE
)
AS
	v_count						NUMBER;
	v_max_end_date				DATE;
	v_app_sid					security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.factor
	 WHERE app_sid = v_app_sid
	   AND end_dtm IS NULL;

	IF v_count > 0 THEN
		RETURN;
	END IF;

	SELECT MAX(end_dtm)
	  INTO v_max_end_date
	  FROM csr.factor
	 WHERE app_sid = security_pkg.getApp;

	UPDATE emission_factor_profile
	   SET end_dtm = v_max_end_date
	 WHERE app_sid = v_app_sid
	   AND profile_id = in_profile_id;

END;

-- This is separating custom emission factors from factor sets in order the make the migrating script rerunable.
-- IT WILL MESS UP EXISTING CUSTOM FACTOR SETS
PROCEDURE UNSEC_DetachFactorsForMigraton
AS
	v_app security_pkg.T_SID_ID := security_pkg.getApp;
	custom_factor_ids aspen2.t_number_table;
BEGIN

	SELECT custom_factor_id
	  BULK COLLECT INTO custom_factor_ids
	  FROM custom_factor cf
	  JOIN custom_factor_set cfs ON cf.custom_factor_set_id = cfs.custom_factor_set_id
	 WHERE cfs.name IN (MIGRATED_CSTM_SET_NAME, MIGRATED_OVERRS_SET_NAME);

	UPDATE factor
	   SET custom_factor_id = NULL
	 WHERE app_sid = v_app
	   AND custom_factor_id IN (SELECT column_value
								  FROM TABLE (custom_factor_ids));

	DELETE FROM custom_factor
	 WHERE app_sid = v_app
	   AND custom_factor_id IN (SELECT column_value
								  FROM TABLE (custom_factor_ids));

	DELETE FROM emission_factor_profile_factor
	 WHERE app_sid = v_app
	   AND custom_factor_set_id IN (SELECT custom_factor_set_id
									  FROM custom_factor_set
									 WHERE name IN (MIGRATED_CSTM_SET_NAME, MIGRATED_OVERRS_SET_NAME));

	DELETE FROM custom_factor_set
	 WHERE app_sid = v_app
	   AND name IN (MIGRATED_CSTM_SET_NAME, MIGRATED_OVERRS_SET_NAME);

END;

PROCEDURE RenameCustomFactorSet(
	in_factor_set_id		IN custom_factor_set.custom_factor_set_id%TYPE,
	in_new_name				IN custom_factor_set.name%TYPE
) AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SuperAdmin access required to rename custom factor sets.');
	END IF;
	
	UPDATE custom_factor_set
	   SET name = in_new_name
	 WHERE custom_factor_set_id = in_factor_set_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE RenameStdFactorSet(
	in_factor_set_id		IN std_factor_set.std_factor_set_id%TYPE,
	in_new_name				IN std_factor_set.name%TYPE
) AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SuperAdmin access required to rename std factor sets.');
	END IF;
	
	UPDATE std_factor_set
	   SET name = in_new_name
	 WHERE std_factor_set_id = in_factor_set_id;
END;

PROCEDURE UpdateStdFactorSetInfoNote(
	in_factor_set_id		IN std_factor_set.std_factor_set_id%TYPE,
	in_info_note			IN std_factor_set.info_note%TYPE
) AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SuperAdmin access required to update std factor sets.');
	END IF;
	
	UPDATE std_factor_set
	   SET info_note = in_info_note
	 WHERE std_factor_set_id = in_factor_set_id;
END;

PROCEDURE UpdateCustomFactorSetInfoNote(
	in_factor_set_id		IN custom_factor_set.custom_factor_set_id%TYPE,
	in_info_note			IN custom_factor_set.info_note%TYPE
) AS
BEGIN
	IF csr_user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SuperAdmin access required to update custom factor sets.');
	END IF;
	
	UPDATE custom_factor_set
	   SET info_note = in_info_note
	 WHERE custom_factor_set_id  = in_factor_set_id;
END;

PROCEDURE UpdateSubRegionFactors
AS
	v_app security_pkg.T_SID_ID := security_pkg.getApp;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Region Emission Factor Cascading') THEN
		RETURN;
	END IF;

	-- mark them as null before update, then delete any remaining nulls at the end.
	UPDATE csr.factor
	   SET is_virtual = NULL
	 WHERE is_virtual = 1;
	 
	FOR f IN (SELECT * from csr.factor f
			   WHERE f.region_sid IS NOT NULL
				 AND f.app_sid = security_pkg.GetApp
				 AND is_virtual = 0
				)
	LOOP
		
		FOR r IN (SELECT r.region_sid 
					FROM csr.region r
					WHERE r.region_sid != f.region_sid
					CONNECT BY PRIOR r.region_sid = r.parent_sid
					START WITH r.region_sid = f.region_sid)
		LOOP
			UPDATE csr.factor uf
			   SET value = f.value, note = f.note, std_measure_conversion_id = f.std_measure_conversion_id, is_virtual = 1
			 WHERE uf.app_sid = f.app_sid
			   AND uf.factor_type_id = f.factor_type_id
			   AND uf.gas_type_id = f.gas_type_id
			   AND uf.region_sid = r.region_sid
			   AND ((uf.geo_country IS NULL AND f.geo_country IS NULL) OR (uf.geo_country = f.geo_country))
			   AND ((uf.geo_region IS NULL AND f.geo_region IS NULL) OR (uf.geo_region = f.geo_region))
			   AND ((uf.egrid_ref IS NULL AND f.egrid_ref IS NULL) OR (uf.egrid_ref = f.egrid_ref))
			   AND ((uf.start_dtm IS NULL AND f.start_dtm IS NULL) OR (uf.start_dtm = f.start_dtm))
			   AND ((uf.end_dtm IS NULL AND f.end_dtm IS NULL) OR (uf.end_dtm = f.end_dtm))
			   AND NVL(uf.is_virtual,1) = 1;
			IF SQL%ROWCOUNT = 0 THEN
				BEGIN
					INSERT INTO csr.factor (factor_id, factor_type_id, gas_type_id, region_sid, geo_country, geo_region, egrid_ref, is_selected, start_dtm, end_dtm,
					  value, note, std_measure_conversion_id, std_factor_id, original_factor_id, custom_factor_id, profile_id, is_virtual)
					VALUES (csr.factor_id_seq.nextval, f.factor_type_id, f.gas_type_id, r.region_sid, f.geo_country, f.geo_region, f.egrid_ref, f.is_selected, f.start_dtm, f.end_dtm,
					  f.value, f.note, f.std_measure_conversion_id, f.std_factor_id, f.original_factor_id, f.custom_factor_id, f.profile_id, 1);
				EXCEPTION
				  WHEN DUP_VAL_ON_INDEX THEN
					NULL;
				END;
			END IF;
		END LOOP;
	END LOOP;

	DELETE FROM csr.factor
	 WHERE is_virtual IS NULL;
END;

PROCEDURE OverlappingFactors(
	out_std_overlaps_cur			OUT	SYS_REFCURSOR,
	out_custom_overlaps_cur			OUT	SYS_REFCURSOR,
	out_std_overlaps_data_cur		OUT	SYS_REFCURSOR,
	out_custom_overlaps_data_cur	OUT	SYS_REFCURSOR
)
AS
	v_overlap_count				NUMBER;
	v_overlaps					VARCHAR2(4000);
BEGIN
	GetOverlapStdFactorData(v_overlap_count, v_overlaps);
	OPEN out_std_overlaps_cur FOR
		SELECT v_overlap_count count, v_overlaps overlaps FROM DUAL;
	
	GetOverlapCtmFactorData(v_overlap_count, v_overlaps);
	OPEN out_custom_overlaps_cur FOR
		SELECT v_overlap_count count, v_overlaps overlaps FROM DUAL;
	
	OPEN out_std_overlaps_data_cur FOR
		SELECT DISTINCT std_factor_set_id factor_set_id, set_name, factor_type_id, factor_type_name, gas_type_id, geo_country, geo_region FROM (
			SELECT f2.std_factor_set_id, fs.name set_name, f2.factor_type_id, ft.name factor_type_name, f2.gas_type_id, f2.geo_country, f2.geo_region
			  FROM csr.std_factor f1, csr.std_factor f2
			 JOIN csr.factor_type ft ON ft.factor_type_id = f2.factor_type_id
			 JOIN csr.std_factor_set fs ON fs.std_factor_set_id = f2.std_factor_set_id
			 WHERE f1.factor_type_id = f2.factor_type_id
			   AND f1.gas_type_id = f2.gas_type_id
			   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
			   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
			   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
			   AND f1.std_factor_id != f2.std_factor_id
			   AND f1.std_factor_set_id = f2.std_factor_set_id
			   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
			   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
			 ORDER BY f1.std_factor_id
		);

	OPEN out_custom_overlaps_data_cur FOR
		SELECT DISTINCT custom_factor_set_id factor_set_id, set_name, factor_type_id, factor_type_name, gas_type_id, geo_country, geo_region FROM (
			SELECT f2.custom_factor_set_id, cfs.name set_name, f2.factor_type_id, ft.name factor_type_name, f2.gas_type_id, f2.geo_country, f2.geo_region
			  FROM csr.custom_factor f1, csr.custom_factor f2
			 JOIN csr.factor_type ft ON ft.factor_type_id = f2.factor_type_id
			 JOIN csr.custom_factor_set cfs ON cfs.custom_factor_set_id = f2.custom_factor_set_id
			 WHERE f1.app_sid = f2.app_sid
			   AND f1.factor_type_id = f2.factor_type_id
			   AND f1.gas_type_id = f2.gas_type_id
			   AND DECODE(f1.region_sid, f2.region_sid, 1, 0) = 1
			   AND DECODE(f1.egrid_ref, f2.egrid_ref, 1, 0) = 1
			   AND DECODE(f1.geo_country, f2.geo_country, 1, 0) = 1
			   AND DECODE(f1.geo_region, f2.geo_region, 1, 0) = 1
			   AND f1.custom_factor_id != f2.custom_factor_id
			   AND f1.custom_factor_set_id = f2.custom_factor_set_id
			   AND (f1.start_dtm < f2.end_dtm OR f2.end_dtm IS NULL)
			   AND (f1.end_dtm IS NULL OR f1.end_dtm > f2.start_dtm)
			 ORDER BY f1.custom_factor_id
		);
END;

PROCEDURE OrphanedProfileFactors(
	out_orphans_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	 OPEN out_orphans_cur FOR
		SELECT DISTINCT f.profile_id, fp.name profile_name, NVL(f.std_factor_set_id,f.custom_factor_set_id) factor_set_id, NVL(sfs.name,cfs.name) set_name, f.factor_type_id, ft.name factor_type_name, f.region_sid, f.geo_country, f.geo_region, f.egrid_ref
		  FROM emission_factor_profile_factor f
		  LEFT JOIN v$region r ON
			NVL(r.geo_country,0) = NVL(f.geo_country,0) AND
			(NVL(r.geo_region,0) = NVL(f.geo_region,0) OR NVL(r.egrid_ref,0) = NVL(f.egrid_ref,0)) AND
			(f.region_sid IS NULL OR (f.region_sid = r.region_sid))
		  JOIN emission_factor_profile fp ON fp.profile_id = f.profile_id
		  JOIN factor_type ft ON ft.factor_type_id = f.factor_type_id
		  LEFT JOIN std_factor_set sfs ON sfs.std_factor_set_id = f.std_factor_set_id
		  LEFT JOIN custom_factor_set cfs ON cfs.custom_factor_set_id = f.custom_factor_set_id
		 WHERE r.region_sid IS NULL AND f.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY profile_id, factor_set_id, factor_type_id, region_sid, geo_country, geo_region, egrid_ref;
END;

PROCEDURE DeleteOrphanedProfileFactors
AS
BEGIN
	DELETE FROM factor
	 WHERE (app_sid, profile_id, factor_type_id, 
			NVL(region_sid,0), NVL(geo_country,0), NVL(geo_region,0), NVL(egrid_ref,0)
		) IN (
			SELECT f.app_sid, f.profile_id, f.factor_type_id, NVL(f.region_sid,0), NVL(f.geo_country,0), NVL(f.geo_region,0), NVL(f.egrid_ref,0)
			  FROM emission_factor_profile_factor f
			  LEFT JOIN v$region r ON
				NVL(r.geo_country,0) = NVL(f.geo_country,0) AND
				(NVL(r.geo_region,0) = NVL(f.geo_region,0) OR NVL(r.egrid_ref,0) = NVL(f.egrid_ref,0)) AND
				(f.region_sid IS NULL OR (f.region_sid = r.region_sid))
			 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
					(r.region_sid IS NULL OR f.geo_region IS NOT NULL AND f.egrid_ref IS NOT NULL)

		);

	DELETE FROM emission_factor_profile_factor
	 WHERE (app_sid, profile_id, factor_type_id, 
			NVL(std_factor_set_id,0), NVL(custom_factor_set_id,0),
			NVL(region_sid,0), NVL(geo_country,0), NVL(geo_region,0), NVL(egrid_ref,0)
		) IN (
			SELECT f.app_sid, f.profile_id, f.factor_type_id, NVL(f.std_factor_set_id,0), NVL(f.custom_factor_set_id,0), NVL(f.region_sid,0), NVL(f.geo_country,0), NVL(f.geo_region,0), NVL(f.egrid_ref,0)
			  FROM emission_factor_profile_factor f
			  LEFT JOIN v$region r ON
				NVL(r.geo_country,0) = NVL(f.geo_country,0) AND
				(NVL(r.geo_region,0) = NVL(f.geo_region,0) OR NVL(r.egrid_ref,0) = NVL(f.egrid_ref,0)) AND
				(f.region_sid IS NULL OR (f.region_sid = r.region_sid))
			  JOIN emission_factor_profile fp ON fp.profile_id = f.profile_id
			  JOIN factor_type ft ON ft.factor_type_id = f.factor_type_id
			  LEFT JOIN std_factor_set sfs ON sfs.std_factor_set_id = f.std_factor_set_id
			  LEFT JOIN custom_factor_set cfs ON cfs.custom_factor_set_id = f.custom_factor_set_id
			 WHERE f.app_sid = SYS_CONTEXT('SECURITY', 'APP') AND
					(r.region_sid IS NULL OR f.geo_region IS NOT NULL AND f.egrid_ref IS NOT NULL)
		);
END;

PROCEDURE AddFactorType(
	in_parent_id			IN factor_type.parent_id%TYPE,
	in_name					IN factor_type.name%TYPE,
	in_std_measure_id		IN factor_type.std_measure_id%TYPE,
	in_egrid				IN factor_type.egrid%TYPE,
	in_enabled				IN factor_type.enabled%TYPE DEFAULT 0,
	in_info_note			IN factor_type.info_note%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	-- use the next available sequence id.
	LOOP
		BEGIN
			INSERT INTO factor_type (factor_type_id, parent_id, name, std_measure_id, egrid, enabled, info_note)
			VALUES (factor_type_id_seq.nextval, in_parent_id, in_name, in_std_measure_id, in_egrid, in_enabled, in_info_note);
			EXIT;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN NULL;
		END;
	END LOOP;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, factor_type_id_seq.currval,
		'Added Factor Type ' || factor_type_id_seq.currval ||
		': parent=' || in_parent_id ||
		', name=' || in_name ||
		', std_measure_id=' || in_std_measure_id ||
		', egrid=' || in_egrid,
		', enabled=' || in_enabled,
		in_parent_id
	);
END;

PROCEDURE UpdateFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_parent_id			IN factor_type.parent_id%TYPE,
	in_name					IN factor_type.name%TYPE,
	in_std_measure_id		IN factor_type.std_measure_id%TYPE,
	in_egrid				IN factor_type.egrid%TYPE,
	in_info_note			IN factor_type.info_note%TYPE,
	in_visible				IN factor_type.visible%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE factor_type 
	   SET parent_id = in_parent_id,
		   name = in_name,
		   std_measure_id = in_std_measure_id,
		   egrid = in_egrid,
		   info_note = in_info_note,
		   visible = NVL(in_visible, visible)
	 WHERE factor_type_id = in_factor_type_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Updated Factor Type ' || in_factor_type_id ||
		': parent=' || in_parent_id ||
		', name=' || in_name ||
		', std_measure_id=' || in_std_measure_id ||
		', egrid=' || in_egrid,
		in_parent_id
	);
END;

PROCEDURE UpdateFactorTypeInfoNote(
	in_factor_type_id			IN factor_type.factor_type_id%TYPE,
	in_info_note			IN factor_type.info_note%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;
	
	UPDATE factor_type 
	   SET info_note = in_info_note
	 WHERE factor_type_id = in_factor_type_id
	   AND ((in_info_note IS NOT NULL AND info_note IS NULL) 
			 OR (in_info_note IS NULL AND info_note IS NOT NULL)
			 OR DBMS_LOB.COMPARE(in_info_note, info_note) = -1
	);
	
	IF SQL%ROWCOUNT > 0 THEN
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.getact,
			csr_data_pkg.AUDIT_TYPE_FACTOR,
			security.security_pkg.getApp,
			in_factor_type_id,
			'Updated Factor Type Info Note'
		);
	END IF;
END;

PROCEDURE EnableFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE factor_type
	   SET enabled = 1
	 WHERE factor_type_id = in_factor_type_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Enabled Factor Type ' || in_factor_type_id);
END;

PROCEDURE DisableFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE factor_type
	   SET enabled = 0
	 WHERE factor_type_id = in_factor_type_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Disabled Factor Type ' || in_factor_type_id);
END;

PROCEDURE ChangeFactorTypeVisibility(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_visible			IN factor_type.visible%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE factor_type
	   SET visible = in_visible
	 WHERE factor_type_id = in_factor_type_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Changed Factor Type visibility' || in_factor_type_id);
END;

PROCEDURE DeleteFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE
)
AS
	v_count	NUMBER;
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can delete factor type') THEN
		RETURN;
	END IF;

	-- children
	SELECT COUNT(*)
	  INTO v_count
	  FROM factor_type
	 WHERE parent_id = in_factor_type_id;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
			'Cannot delete factor type '||in_factor_type_id||' because it has children'
		);
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM factor_type
	 WHERE factor_type_id = in_factor_type_id
	   AND enabled = 1 
	   AND std_measure_id IS NOT NULL;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IN_USE,
			'Cannot delete factor type '||in_factor_type_id||' because it is enabled'
		);
	END IF;

	DELETE FROM factor_type
	 WHERE factor_type_id = in_factor_type_id
	   AND (enabled = 0 OR std_measure_id IS NULL);

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Deleted Factor Type ' || in_factor_type_id);
END;

PROCEDURE MoveFactorType(
	in_factor_type_id		IN factor_type.factor_type_id%TYPE,
	in_parent_id			IN factor_type.parent_id%TYPE
)
AS
BEGIN
	IF NOT csr_data_pkg.CheckCapability('Can import std factor set') THEN
		RETURN;
	END IF;

	UPDATE factor_type 
	   SET parent_id = in_parent_id
	 WHERE factor_type_id = in_factor_type_id;

	csr_data_pkg.WriteAuditLogEntry(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_FACTOR, security.security_pkg.getApp, in_factor_type_id,
		'Moved Factor Type ' || in_factor_type_id ||
		' to parent=' || in_parent_id,
		in_parent_id
	);
END;

-- Used by the json export
PROCEDURE GetFactorsForExport(
	out_profile_cur			OUT	SYS_REFCURSOR,
	out_factor_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_profile_cur FOR
		SELECT profile_id, name, start_dtm, end_dtm, applied
		  FROM emission_factor_profile
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_factor_cur FOR
		SELECT profile_id, factor_type_id, std_factor_set_id, custom_factor_set_id, geo_country, geo_region, egrid_ref
		  FROM emission_factor_profile_factor
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY profile_id, factor_type_id;

END;

END factor_pkg;
/

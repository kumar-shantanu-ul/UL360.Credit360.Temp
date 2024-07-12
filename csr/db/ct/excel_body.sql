CREATE OR REPLACE PACKAGE BODY ct.excel_pkg
IS

NO_CREATE	CONSTANT NUMBER := 0;
DO_CREATE	CONSTANT NUMBER := 1;

/*
PROCEDURE SetColumnTags (
	in_worksheet_id				IN  csr.worksheet.worksheet_id%TYPE,
	in_column_type_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_column_indices			IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_file_upload_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT file_upload_sid
	  INTO v_file_upload_sid
	  FROM worksheet_file_upload
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id;
	
	IF NOT chain.capability_pkg.CheckCapability(chain.upload_pkg.GetCompanySid(v_file_upload_sid), chain.chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to upload files for company with sid '||chain.upload_pkg.GetCompanySid(v_file_upload_sid));
	END IF;
	
	DELETE FROM worksheet_column 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id;
	
	IF chain.helper_pkg.NumericArrayEmpty(in_column_type_ids) = 0 THEN
		IF in_column_type_ids.count <> in_column_indices.count THEN
			RAISE_APPLICATION_ERROR(-20001, 'in_column_type_ids count <> in_column_indices.count');
		END IF;

		FOR i IN in_column_type_ids.FIRST .. in_column_type_ids.LAST
		LOOP
			INSERT INTO worksheet_column
			(worksheet_id, column_type_id, value_helper_id, column_index)
			SELECT in_worksheet_id, column_type_id, value_helper_id, in_column_indices(i)
			  FROM worksheet_column_type
			 WHERE column_type_id = in_column_type_ids(i);
		END LOOP;
	END IF;
END;*/

/***********************************************************
/*	CURRENCY
/***********************************************************/
PROCEDURE GetCurrencyMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_values 					security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_values);
BEGIN
	-- TODO: SECURITY
	OPEN out_cur FOR
		SELECT in_column_type_id column_type_id, t.value, x.currency_id 
		  FROM TABLE(t_values) t, (
				SELECT vmv.value_map_id, vmv.value, vmc.currency_id
				  FROM csr.worksheet_value_map_value vmv, worksheet_value_map_currency vmc
				 WHERE vmv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND vmv.app_sid = vmc.app_sid
				   AND vmv.column_type_id = in_column_type_id
				   AND vmv.value_map_id = vmc.value_map_id
			 ) x
 		 WHERE LOWER(TRIM(t.value)) = x.value(+);
END;

PROCEDURE SaveCurrencyMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_currency_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_dead_map_ids				chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	util_pkg.FillIdMapperTable(in_column_type_id, in_values, in_currency_ids);
	
	UPDATE id_mapper_table 
	   SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, CASE WHEN NVL(id, -1) < 0 THEN NO_CREATE ELSE DO_CREATE END);
	
	SELECT value_map_id
	  BULK COLLECT INTO v_dead_map_ids
	  FROM id_mapper_table
	 WHERE NVL(id, -1) < 0 
	   AND value_map_id IS NOT NULL;
	
	DELETE FROM worksheet_value_map_currency
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT value_map_id FROM id_mapper_table);
	
	csr.excel_pkg.RemoveValueMap(v_dead_map_ids);
	
	INSERT INTO worksheet_value_map_currency
	(value_map_id, currency_id)
	SELECT value_map_id, id
	  FROM (
		SELECT value_map_id, id, row_number() over (partition by value_map_id order by id) rn
		  FROM id_mapper_table
		 WHERE value_map_id IS NOT NULL
		   AND NVL(id, -1) >= 0
		  )
	 WHERE rn = 1; 
END;

/***********************************************************
/*	REGION
/***********************************************************/
PROCEDURE GetRegionMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_values 					security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_values);
BEGIN
	-- TODO: SECURITY
	OPEN out_cur FOR
		SELECT in_column_type_id column_type_id, t.value, x.region_id 
		  FROM TABLE(t_values) t, (
				SELECT vmv.value_map_id, vmv.value, vmr.region_id
				  FROM csr.worksheet_value_map_value vmv, worksheet_value_map_region vmr
				 WHERE vmv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND vmv.app_sid = vmr.app_sid
				   AND vmv.column_type_id = in_column_type_id
				   AND vmv.value_map_id = vmr.value_map_id
			 ) x
 		 WHERE LOWER(TRIM(t.value)) = x.value(+);
END;

PROCEDURE SaveRegionMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_region_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_dead_map_ids				chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	util_pkg.FillIdMapperTable(in_column_type_id, in_values, in_region_ids);
		
	UPDATE id_mapper_table 
	   SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, CASE WHEN NVL(id, -1) < 0 THEN NO_CREATE ELSE DO_CREATE END);

	SELECT value_map_id
	  BULK COLLECT INTO v_dead_map_ids
	  FROM id_mapper_table
	 WHERE NVL(id, -1) < 0 
	   AND value_map_id IS NOT NULL;

	DELETE FROM worksheet_value_map_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT value_map_id FROM id_mapper_table);

	csr.excel_pkg.RemoveValueMap(v_dead_map_ids);

	INSERT INTO worksheet_value_map_region
	(value_map_id, region_id)
	SELECT value_map_id, id
	  FROM (
		SELECT value_map_id, id, row_number() over (partition by value_map_id order by id) rn
		  FROM id_mapper_table
		 WHERE value_map_id IS NOT NULL
		   AND NVL(id, -1) >= 0
		  )
	 WHERE rn = 1; 
END;

/***********************************************************
/*	BREAKDOWN
/***********************************************************/
PROCEDURE GetBreakdownMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_values 					security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_values);
BEGIN
	-- TODO: SECURITY
	-- TODO: Ensure that the matching that we're presenting is the currently selected breakdown type for the module
	OPEN out_cur FOR
		SELECT null column_type_id, null value, null breakdown_id FROM DUAL WHERE 0 = 1;	
END;

PROCEDURE SaveBreakdownMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_breakdown_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
BEGIN
	NULL;
END;

/***********************************************************
/*	SUPPLIER
/***********************************************************/
PROCEDURE GetSupplierMaps (
	in_supplier_id_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_name_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_id_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_name_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	util_pkg.FillIdMapperTable(in_supplier_id_ct_id, in_supplier_name_ct_id, in_supplier_id_values, in_supplier_name_values);
		
	-- update exact matches
	UPDATE id_mapper_table SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, column_type_id_2, value_2, 0);
	-- update id matches where the name is null
	UPDATE id_mapper_table SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, column_type_id_2, null, 0) WHERE value_map_id IS NULL;
	-- update name matches where the id is null
	UPDATE id_mapper_table SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, null, column_type_id_2, value_2, 0) WHERE value_map_id IS NULL;

	UPDATE id_mapper_table t
	   SET id = (
	   		SELECT s.supplier_id
	   		  FROM worksheet_value_map_supplier s
	   		 WHERE s.value_map_id = t.value_map_id
	   );
	
	UPDATE id_mapper_table t
	   SET id = (
	   		SELECT MIN(s.supplier_id)
	   		  FROM supplier s
	   		 WHERE LOWER(TRIM(s.name)) = LOWER(TRIM(t.value_2))
	   )
	 WHERE id IS NULL;
	
	OPEN out_cur FOR
		SELECT in_supplier_id_ct_id supplier_id_ct_id, in_supplier_name_ct_id supplier_name_ct_id, value_1 id_value, value_2 name_value, id supplier_id
		  FROM id_mapper_table;
END;

PROCEDURE SaveSupplierMaps (
	in_supplier_id_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_name_ct_id		IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_supplier_id_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_name_values		IN	security_pkg.T_VARCHAR2_ARRAY,
	in_supplier_ids				IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_dead_map_ids				chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	
	util_pkg.FillIdMapperTable(in_supplier_id_ct_id, in_supplier_name_ct_id, in_supplier_id_values, in_supplier_name_values, in_supplier_ids);

	INSERT INTO id_mapper_table (column_type_id_1, column_type_id_2, value_1, id)
	SELECT column_type_id_1, column_type_id_2, value_1, id
	  FROM id_mapper_table
	 WHERE value_1 IS NOT NULL
	   AND (column_type_id_1, column_type_id_2, value_1) NOT IN (
	   		SELECT column_type_id_1, column_type_id_2, value_1 FROM id_mapper_table WHERE value_2 IS NULL
	   );

	INSERT INTO id_mapper_table (column_type_id_1, column_type_id_2, value_2, id)
	SELECT column_type_id_1, column_type_id_2, value_2, id
	  FROM id_mapper_table
	 WHERE value_2 IS NOT NULL
	   AND (column_type_id_1, column_type_id_2, value_2) NOT IN (
	 	   		SELECT column_type_id_1, column_type_id_2, value_2 FROM id_mapper_table WHERE value_1 IS NULL
	 	   );

	DELETE FROM id_mapper_table WHERE value_1 IS NULL AND value_2 IS NULL;

	-- update exact matches
	UPDATE id_mapper_table 
	   SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, column_type_id_2, value_2, CASE WHEN NVL(id, -1) < 0 THEN NO_CREATE ELSE DO_CREATE END);
	
	SELECT value_map_id
	  BULK COLLECT INTO v_dead_map_ids
	  FROM id_mapper_table
	 WHERE NVL(id, -1) < 0 
	   AND value_map_id IS NOT NULL;

	DELETE FROM worksheet_value_map_supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT value_map_id FROM id_mapper_table);

	csr.excel_pkg.RemoveValueMap(v_dead_map_ids);

	INSERT INTO worksheet_value_map_supplier
	(value_map_id, supplier_id)
	SELECT value_map_id, id
	  FROM (
	  	SELECT value_map_id, id, row_number() over (partition by value_map_id order by id) rn
		  FROM id_mapper_table
		 WHERE value_map_id IS NOT NULL
		   AND NVL(id, -1) >= 0
		  )
	 WHERE rn = 1; 
END;

/***********************************************************
/*	DISTANCE
/***********************************************************/
PROCEDURE GetDistanceMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	t_values 					security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_values);
BEGIN
	-- TODO: SECURITY
	OPEN out_cur FOR
		SELECT in_column_type_id column_type_id, t.value, x.distance_unit_id 
		  FROM TABLE(t_values) t, (
				SELECT vmv.value_map_id, vmv.value, vmd.distance_unit_id
				  FROM csr.worksheet_value_map_value vmv, worksheet_value_map_distance vmd
				 WHERE vmv.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND vmv.app_sid = vmd.app_sid
				   AND vmv.column_type_id = in_column_type_id
				   AND vmv.value_map_id = vmd.value_map_id
			 ) x
 		 WHERE LOWER(TRIM(t.value)) = x.value(+);
END;

PROCEDURE SaveDistanceMaps (
	in_column_type_id			IN  csr.worksheet_column_type.column_type_id%TYPE,
	in_values					IN	security_pkg.T_VARCHAR2_ARRAY,
	in_distance_unit_ids		IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_dead_map_ids				chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	util_pkg.FillIdMapperTable(in_column_type_id, in_values, in_distance_unit_ids);
	
	UPDATE id_mapper_table 
	   SET value_map_id = csr.excel_pkg.GetValueMapId(column_type_id_1, value_1, CASE WHEN NVL(id, -1) < 0 THEN NO_CREATE ELSE DO_CREATE END);
	
	SELECT value_map_id
	  BULK COLLECT INTO v_dead_map_ids
	  FROM id_mapper_table
	 WHERE NVL(id, -1) < 0 
	   AND value_map_id IS NOT NULL;
	
	DELETE FROM worksheet_value_map_distance
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT value_map_id FROM id_mapper_table);
	
	csr.excel_pkg.RemoveValueMap(v_dead_map_ids);
	
	INSERT INTO worksheet_value_map_distance
	(value_map_id, distance_unit_id)
	SELECT value_map_id, id
	  FROM (
		SELECT value_map_id, id, row_number() over (partition by value_map_id order by id) rn
		  FROM id_mapper_table
		 WHERE value_map_id IS NOT NULL
		   AND NVL(id, -1) >= 0
		  )
	 WHERE rn = 1; 
END;



















PROCEDURE GetWorksheets (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetWorksheet(NULL, out_cur);
END;

PROCEDURE GetWorksheet (
	in_worksheet_id				IN  csr.worksheet.worksheet_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: SECURITY
	
	OPEN out_cur FOR
		SELECT ws.worksheet_id, ws.sheet_name, fu.filename, fu.last_modified_dtm uploaded_date,
		       cu.full_name uploaded_by, (
				SELECT COUNT(*) 
				  FROM csr.worksheet_row wsr 
				 WHERE wsr.worksheet_id = ws.worksheet_id
				   AND wsr.app_sid = ws.app_sid) lines
		  FROM csr.worksheet ws, chain.worksheet_file_upload wfu, chain.file_upload fu, csr.csr_user cu
		 WHERE ws.worksheet_id = wfu.worksheet_id
		   AND wfu.file_upload_sid = fu.file_upload_sid
		   AND fu.last_modified_by_sid = cu.csr_user_sid(+)
		   AND fu.app_sid = cu.app_sid(+)
		   AND fu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fu.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ws.worksheet_id = NVL(in_worksheet_id, ws.worksheet_id);
END;

PROCEDURE SearchPSWorksheets(
	in_page							IN  NUMBER,
	in_page_size					IN  NUMBER,
	in_breakdown_id					IN  ps_item.breakdown_id%TYPE,
	in_region_id					IN  ps_item.region_id%TYPE,
	out_count_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_page							NUMBER(10) DEFAULT in_page;
	v_total_count					NUMBER(10) DEFAULT 0;
	v_total_pages					NUMBER(10) DEFAULT 0;
BEGIN
	-- TODO: SECURITY
	
	-- select all worksheets that meet search criteria, and put in temp table
	  INSERT INTO tt_worksheet_search (worksheet_id, uploaded_date)
	  SELECT DISTINCT wfu.worksheet_id, fu.last_modified_dtm
	    FROM chain.worksheet_file_upload wfu
	    JOIN chain.file_upload fu
	      ON wfu.file_upload_sid = fu.file_upload_sid	    
	    JOIN ps_item item
	      ON item.worksheet_id = wfu.worksheet_id
	   WHERE fu.app_sid = security_pkg.getApp
	     AND item.breakdown_id = NVL(in_breakdown_id, item.breakdown_id)
		 AND item.region_id = NVL(in_region_id, item.region_id)		  
	ORDER BY fu.last_modified_dtm DESC;
  
	-- get total record count/pages
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM tt_worksheet_search;
	  
	SELECT CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END
	  INTO v_total_pages		    
	  FROM tt_worksheet_search;
	
	-- delete any records that aren't between the current pages
	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_worksheet_search
		 WHERE worksheet_id NOT IN (
			SELECT worksheet_id
			  FROM (
				SELECT worksheet_id, rownum rn
				  FROM tt_worksheet_search
			)
			WHERE rn > in_page_size * (v_page - 1)
			  AND rn <= in_page_size * v_page
		 );			 
	END IF;
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count,
		       v_total_pages total_pages
		  FROM dual;
		  
	-- match the paged, sorted results to the relevant tables to return the results
	OPEN out_result_cur FOR
		SELECT ws.worksheet_id, ws.sheet_name, fu.filename, fu.last_modified_dtm uploaded_date,
		       cu.full_name uploaded_by, (
				SELECT COUNT(*) 
				  FROM csr.worksheet_row wsr 
				 WHERE wsr.worksheet_id = ws.worksheet_id
				   AND wsr.app_sid = ws.app_sid) lines
		  FROM csr.worksheet ws, chain.worksheet_file_upload wfu, chain.file_upload fu, csr.csr_user cu
		 WHERE ws.worksheet_id = wfu.worksheet_id
		   AND wfu.file_upload_sid = fu.file_upload_sid
		   AND fu.last_modified_by_sid = cu.csr_user_sid(+)
		   AND fu.app_sid = cu.app_sid(+)
		   AND fu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND fu.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ws.worksheet_id IN (SELECT worksheet_id FROM tt_worksheet_search)
		   ORDER BY fu.last_modified_dtm DESC;	
END;

PROCEDURE DeleteWorksheet (
	in_worksheet_id					csr.worksheet.worksheet_id%TYPE
)
AS
BEGIN
	-- TODO: Sec check
	
	FOR r in (
		SELECT item_id 
		  FROM ct.ps_item
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND worksheet_id = in_worksheet_id
	) LOOP
		products_services_pkg.DeleteItem(r.item_id);
	END LOOP;
	   
	chain.excel_pkg.DeleteWorksheet(in_worksheet_id);
END;

PROCEDURE DeleteAllValueMaps
AS
BEGIN
	-- TODO: Sec check

	FOR r IN (
		SELECT value_map_id FROM csr.worksheet_value_map
	) LOOP 
	
		DELETE FROM ct.worksheet_value_map_breakdown
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value_map_id = r.value_map_id;

		DELETE FROM ct.worksheet_value_map_currency
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value_map_id = r.value_map_id;

		DELETE FROM ct.worksheet_value_map_distance
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value_map_id = r.value_map_id;

		DELETE FROM ct.worksheet_value_map_region
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value_map_id = r.value_map_id;

		DELETE FROM ct.worksheet_value_map_supplier
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND value_map_id = r.value_map_id;
	
	END LOOP;
END;


END excel_pkg;
/

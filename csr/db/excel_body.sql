CREATE OR REPLACE PACKAGE BODY csr.excel_pkg
IS

FUNCTION CreateWorksheet (
	in_sheet_name				IN  csr.worksheet.sheet_name%TYPE,
	in_worksheet_type_id		IN  csr.worksheet.worksheet_type_id%TYPE,
	in_header_row_index			IN  csr.worksheet.header_row_index%TYPE
) RETURN NUMBER
AS
	v_worksheet_id				csr.worksheet.worksheet_id%TYPE;
BEGIN
	INSERT INTO worksheet 
	(worksheet_id, sheet_name, lower_sheet_name, worksheet_type_id, header_row_index)
	VALUES
	(worksheet_id_seq.nextval, in_sheet_name, LOWER(TRIM(in_sheet_name)), in_worksheet_type_id, in_header_row_index)
	RETURNING worksheet_id INTO v_worksheet_id;
	
	RETURN v_worksheet_id;
END;

PROCEDURE GetValueMapperClasses (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT value_mapper_id, class_type
		  FROM worksheet_value_mapper;
END;

PROCEDURE GetValueMappers (
	in_worksheet_type_id		IN  worksheet_type.worksheet_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT vm.value_mapper_id, vm.class_type, vm.mapper_name, vm.mapper_description, vm.js_component_path, vm.js_component, ct.position
		  FROM worksheet_value_mapper vm, (
				SELECT value_mapper_id, MAX(position) KEEP (DENSE_RANK FIRST ORDER BY position) as position
				  FROM worksheet_column_type
				 WHERE worksheet_type_id = in_worksheet_type_id
				   AND value_mapper_id IS NOT NULL
				 GROUP BY value_mapper_id
			) ct
		WHERE ct.value_mapper_id = vm.value_mapper_id
		ORDER BY ct.position;
END;

PROCEDURE GetColumnTypes (
	in_worksheet_type_id		IN  worksheet_type.worksheet_type_id%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT column_type_id, name, description, value_mapper_id, required
		  FROM worksheet_column_type
		 WHERE worksheet_type_id = in_worksheet_type_id
		 ORDER BY position;
END;

PROCEDURE SetColumnTags (
	in_worksheet_id				IN  worksheet.worksheet_id%TYPE,
	in_column_type_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_column_indices			IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
BEGIN
	-- move the arrays into a temp table
	IF chain.helper_pkg.NumericArrayEmpty(in_column_type_ids) = 0 THEN
		IF in_column_type_ids.count <> in_column_indices.count THEN
			RAISE_APPLICATION_ERROR(-20001, 'in_column_type_ids count <> in_column_indices.count');
		END IF;
		
		FOR i IN in_column_type_ids.FIRST .. in_column_type_ids.LAST
		LOOP
			INSERT INTO worksheet_column_remap (column_type_id, column_index)
			VALUES (in_column_type_ids(i), in_column_indices(i));
		END LOOP;
	END IF;
	
	DELETE FROM worksheet_column_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id
	   AND column_type_id NOT IN (SELECT column_type_id FROM worksheet_column_remap);

	DELETE FROM worksheet_column 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id
	   AND column_type_id NOT IN (SELECT column_type_id FROM worksheet_column_remap);
	
	-- set any existing mappings
	UPDATE worksheet_column_remap r
	   SET old_column_index = (
	   		SELECT column_index
	   		  FROM worksheet_column wc
	   		 WHERE wc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   		   AND wc.worksheet_id = in_worksheet_id
	   		   AND wc.column_type_id = r.column_type_id
	   );
	
	DELETE FROM worksheet_column_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id
	   AND column_type_id NOT IN (SELECT column_type_id FROM worksheet_column_remap WHERE column_index <> old_column_index);
	
	UPDATE worksheet_column wc
	   SET column_index = (
	   		SELECT column_index
	   		  FROM worksheet_column_remap r
	   		 WHERE wc.column_type_id = r.column_type_id
	   )
	 WHERE wc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND wc.worksheet_id = in_worksheet_id;
	   
	INSERT INTO worksheet_column
	(worksheet_id, column_type_id, column_index)
	SELECT in_worksheet_id, r.column_type_id, r.column_index
	  FROM worksheet_column_remap r, worksheet_column_type ct
	 WHERE r.column_type_id = ct.column_type_id
	   AND r.column_type_id NOT IN (
	   		SELECT column_type_id 
	   		  FROM worksheet_column 
	   		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   		   AND worksheet_id = in_worksheet_id
	   	);
END;

FUNCTION GetValueMapId (
	in_column_type_id			IN  worksheet_column_type.column_type_id%TYPE,
	in_value					IN  worksheet_value_map_value.value%TYPE,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER
AS
	v_column_type_ids			chain.helper_pkg.T_NUMBER_ARRAY;
	v_values					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	SELECT in_column_type_id 
	  BULK COLLECT INTO v_column_type_ids 
	  FROM DUAL;
		
	SELECT in_value 
	  BULK COLLECT INTO v_values 
	  FROM DUAL;

	RETURN GetValueMapId(v_column_type_ids, v_values, in_create);
END;

FUNCTION GetValueMapId (
	in_column_type_id_1			IN  worksheet_column_type.column_type_id%TYPE,
	in_value_1					IN  worksheet_value_map_value.value%TYPE,
	in_column_type_id_2			IN  worksheet_column_type.column_type_id%TYPE,
	in_value_2					IN  worksheet_value_map_value.value%TYPE,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER
AS
	v_column_type_ids			chain.helper_pkg.T_NUMBER_ARRAY;
	v_values					security_pkg.T_VARCHAR2_ARRAY;
BEGIN
	SELECT column_type_id
	  BULK COLLECT INTO v_column_type_ids 
	  FROM (
	  	SELECT in_column_type_id_1 column_type_id FROM DUAL
	  	UNION ALL
	  	SELECT in_column_type_id_2 column_type_id FROM DUAL
	  );
		
	SELECT value
	  BULK COLLECT INTO v_values 
	  FROM (
	  	SELECT in_value_1 value FROM DUAL
	  	UNION ALL
	  	SELECT in_value_2 value FROM DUAL
	  );
		
	RETURN GetValueMapId(v_column_type_ids, v_values, in_create);
END;

FUNCTION GetValueMapId (
	in_column_type_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_values					IN  security_pkg.T_VARCHAR2_ARRAY,
	in_create					IN  NUMBER DEFAULT 1
) RETURN NUMBER
AS
	v_value_mapper_id			worksheet_value_mapper.value_mapper_id%TYPE;
	v_value_map_id				worksheet_value_map.value_map_id%TYPE;
	v_sql						VARCHAR2(4000);
	v_where						VARCHAR2(500) DEFAULT ' ';
BEGIN
	IF chain.helper_pkg.NumericArrayEmpty(in_column_type_ids) = 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must provide more than 0 column type ids');
	END IF;

	IF in_column_type_ids.COUNT <> in_values.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'You must provide the same number of columns as values');
	END IF;
	
	-- we can just check the value_helper for the first column because RI will self destruct if it's wrong
	SELECT value_mapper_id
	  INTO v_value_mapper_id
	  FROM worksheet_column_type
	 WHERE column_type_id = in_column_type_ids(1);

	v_sql := 'SELECT t1.value_map_id FROM ';
	
	FOR i IN in_column_type_ids.FIRST .. in_column_type_ids.LAST
	LOOP
		IF i > 1 THEN
			v_sql := v_sql || ', ';
		END IF;
		v_sql := v_sql || '
		   (SELECT value_map_id
			  FROM worksheet_value_map_value 
			 WHERE app_sid = SYS_CONTEXT(''SECURITY'', ''APP'')
			   AND column_type_id = :'||((i*2)-1);
			
		IF in_values(i) IS NULL THEN
			-- we don't need this bind variable, but it keeps things in sync
			v_sql := v_sql || ' AND value IS NULL AND :'||(i*2)||' IS NULL';
		ELSE
			v_sql := v_sql || ' AND value = LOWER(TRIM(:'||(i*2)||'))';
		END IF;

		v_sql := v_sql || ') t'||i;
		
		IF i = 2 THEN
			v_where := ' WHERE t1.value_map_id = t2.value_map_id ';
		ELSIF i > 2 THEN
			v_where := v_where || ' AND t1.value_map_id = t'||i||'.value_map_id ';
		END IF;
	END LOOP;
	
	BEGIN
		CASE
			WHEN in_column_type_ids.COUNT = 1 THEN
				EXECUTE IMMEDIATE v_sql||v_where 
				   INTO v_value_map_id 
				  USING in_column_type_ids(1), in_values(1);
			WHEN in_column_type_ids.COUNT = 2 THEN
				EXECUTE IMMEDIATE v_sql||v_where 
				   INTO v_value_map_id 
				  USING in_column_type_ids(1), in_values(1), 
						in_column_type_ids(2), in_values(2);
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Handling more than two column types is not fully implemented (but it''s easy to fix)');
		END CASE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_create <> 0 THEN
				INSERT INTO worksheet_value_map (value_map_id, value_mapper_id)
				VALUES (value_map_id_seq.nextval, v_value_mapper_id)
				RETURNING value_map_id INTO v_value_map_id;

				FOR i IN in_column_type_ids.FIRST .. in_column_type_ids.LAST
				LOOP
					INSERT INTO worksheet_value_map_value
					(value_map_id, value_mapper_id, column_type_id, value)
					VALUES
					(v_value_map_id, v_value_mapper_id, in_column_type_ids(i), LOWER(TRIM(in_values(i))));
				END LOOP;
			END IF;
	END;
	
	RETURN v_value_map_id;	
END;

PROCEDURE RemoveValueMap (
	in_value_map_id				IN  worksheet_value_map.value_map_id%TYPE
) 
AS
	v_value_map_ids				chain.helper_pkg.T_NUMBER_ARRAY;
BEGIN
	SELECT in_value_map_id 
	  BULK COLLECT INTO v_value_map_ids 
	  FROM DUAL;
	
	RemoveValueMap(v_value_map_ids);
END;

PROCEDURE RemoveValueMap (
	in_value_map_ids			IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	t_value_map_ids				chain.T_NUMERIC_TABLE DEFAULT chain.helper_pkg.NumericArrayToTable(in_value_map_ids);
BEGIN
	DELETE FROM worksheet_column_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT item FROM TABLE(t_value_map_ids));

	DELETE FROM worksheet_value_map_value
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT item FROM TABLE(t_value_map_ids));

	DELETE FROM worksheet_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id IN (SELECT item FROM TABLE(t_value_map_ids));
END;

PROCEDURE IgnoreRow (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE,
	in_row_number				IN  worksheet_row.row_number%TYPE
)
AS
BEGIN
	UPDATE worksheet_row
	   SET ignore = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id
	   AND row_number = in_row_number;
END;

PROCEDURE SaveRowNumbers (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE,
	in_row_numbers				IN  chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	t_row_numbers				chain.T_NUMERIC_TABLE DEFAULT chain.helper_pkg.NumericArrayToTable(in_row_numbers);
BEGIN
	INSERT INTO worksheet_row
	(worksheet_id, row_number)
	SELECT in_worksheet_id, item
	  FROM TABLE(t_row_numbers)
	 MINUS
	SELECT worksheet_id, row_number
	  FROM worksheet_row
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id;
END;

PROCEDURE DeleteWorksheet (
	in_worksheet_id				IN  worksheet_row.worksheet_id%TYPE
)
AS
BEGIN
	DELETE FROM csr.worksheet_column_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id;
	
	DELETE FROM csr.worksheet_column
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND worksheet_id = in_worksheet_id;
	   
	DELETE FROM csr.worksheet_row
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	    AND worksheet_id = in_worksheet_id;
	
	DELETE FROM csr.worksheet
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	    AND worksheet_id = in_worksheet_id;
END;

PROCEDURE DeleteValueMap (
	in_value_map_id				IN  worksheet_value_map.value_map_id%TYPE
)
AS
BEGIN
	DELETE FROM csr.worksheet_column_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id = in_value_map_id;

	DELETE FROM csr.worksheet_value_map_value
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id = in_value_map_id;

	DELETE FROM csr.worksheet_value_map
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND value_map_id = in_value_map_id;
END;

PROCEDURE DeleteAllValueMaps
AS
BEGIN
	
	FOR r IN (
		SELECT value_map_id FROM worksheet_value_map
	) LOOP
		DeleteValueMap(r.value_map_id);
	END LOOP;	
END;

END excel_pkg;
/

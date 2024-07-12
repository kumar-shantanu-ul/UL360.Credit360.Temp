SET SERVEROUTPUT ON

DECLARE
	FUNCTION CsrimpTableExists(in_name IN VARCHAR2) RETURN BOOLEAN
	AS
		v_exists				NUMBER(1);
	BEGIN
		SELECT CASE WHEN EXISTS(
					SELECT * 
					  FROM all_tables 
					 WHERE owner = 'CSRIMP' 
					   AND table_name = in_name
			   ) THEN 1 ELSE 0
			   END CASE
		  INTO v_exists
		  FROM DUAL;

		RETURN (v_exists = 1);
	END;

	FUNCTION GetUniqueCsrimpTableName(
		in_owner					IN VARCHAR2, 
		in_table					IN VARCHAR2
	) RETURN VARCHAR2
	AS
		v_prefix					VARCHAR2(10);
		v_name						VARCHAR2(30);
		v_suffix					VARCHAR2(19);
		v_index						PLS_INTEGER := 0;
	BEGIN
		IF in_owner = 'CSR' THEN
			v_prefix := '';
		ELSE 
			v_prefix := SUBSTR(in_owner, 1, 9) || '_';
		END IF;

		v_name := SUBSTR(v_prefix || in_table, 1, 30);

		WHILE CsrimpTableExists(v_name) LOOP
			v_index := v_index + 1;
			v_suffix := '_' || v_index;
			v_name := SUBSTR(v_prefix || in_table, 1, 30 - LENGTH(v_suffix)) || v_suffix;
		END LOOP;

		RETURN v_name;
	END;

	FUNCTION CsrimpTableNeedsUpdate(
		in_source_owner				IN VARCHAR2,
		in_source_table				IN VARCHAR2,
		in_csrimp_table				IN VARCHAR2
	) RETURN BOOLEAN
	AS
		v_changes					PLS_INTEGER;
	BEGIN
		WITH 
			csrimp_columns AS (
				SELECT column_name, 
					   data_type, 
					   data_precision,
					   data_scale,
					   char_col_decl_length
				  FROM all_tab_columns
				 WHERE owner = 'CSRIMP'
				   AND table_name = in_csrimp_table
				   AND column_name != 'CSRIMP_SESSION_ID'
			),
			source_columns AS (
				SELECT column_name, 
					   data_type, 
					   data_precision,
					   data_scale,
					   char_col_decl_length
				  FROM all_tab_columns
				 WHERE owner = in_source_owner
				   AND table_name = in_source_table
				   AND column_name != 'APP_SID'
			)
		SELECT COUNT(DISTINCT column_name) 
		  INTO v_changes
		  FROM (
				-- symmetric difference
				(
					SELECT * FROM csrimp_columns 
					UNION 
					SELECT * FROM source_columns
				) MINUS (
					SELECT * FROM csrimp_columns 
					INTERSECT 
					SELECT * FROM source_columns
				)
		   );

		RETURN v_changes > 0;
	END;

	PROCEDURE DropCsrimpTable(in_name IN VARCHAR2) AS
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE CSRIMP."' || in_name || '"';
	END;

	PROCEDURE CreateCsrimpTable(
		in_source_owner				IN VARCHAR2,
		in_source_table				IN VARCHAR2,
		in_csrimp_table				IN VARCHAR2
	)
	AS
		v_key						VARCHAR2(32767);
		v_sql						VARCHAR2(32767);
	BEGIN
		SELECT LISTAGG('"' || column_name || '"', ',') WITHIN GROUP (ORDER BY position)
		  INTO v_key
		  FROM (
				SELECT 'CSRIMP_SESSION_ID' column_name, -1 position FROM DUAL
				 UNION 
				SELECT col.column_name, col.position
				  FROM all_cons_columns col
				  JOIN all_constraints con 
					ON con.owner = col.owner 
				   AND con.constraint_name = col.constraint_name
				 WHERE con.constraint_type = 'P' 
				   AND con.table_name = in_source_table
				   AND con.owner = in_source_owner
				   AND col.column_name != 'APP_SID'
			  );

		SELECT 'CREATE TABLE CSRIMP."' || in_csrimp_table || '" (' || CHR(10) ||
			   '    CSRIMP_SESSION_ID NUMBER(10) ' ||
								     'DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') ' || 
									 'NOT NULL,' || CHR(10) ||
				LISTAGG(
					'    "' || tc.column_name || '" ' || tc.data_type ||
					CASE WHEN tc.data_precision IS NOT NULL THEN
						'(' || tc.data_precision || 
							CASE WHEN tc.data_scale IS NOT NULL THEN
								',' || tc.data_scale
							END ||
						')'
						 WHEN tc.data_type != 'CLOB' AND tc.char_col_decl_length IS NOT NULL THEN
							'(' || tc.char_col_decl_length || ')'
					END ||
					CASE WHEN tc.nullable = 'N' THEN
						' NOT NULL'
					END || ','|| CHR(10)) WITHIN GROUP (ORDER BY tc.column_id) ||
			   '    PRIMARY KEY (' || v_key || '),' || CHR(10) ||
			   '    FOREIGN KEY (CSRIMP_SESSION_ID) ' ||
					    'REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ' ||
					    'ON DELETE CASCADE' || CHR(10) ||
			   ')'
		  INTO v_sql
		  FROM all_tab_columns tc
		  LEFT JOIN csr.schema_column sc 
			ON sc.table_name = tc.table_name 
		   AND sc.column_name = tc.column_name
		 WHERE tc.table_name = in_source_table
		   AND tc.owner = in_source_owner
		   AND NVL(sc.enable_import, 1) != 0
		   AND tc.column_name != 'APP_SID';

		EXECUTE IMMEDIATE v_sql;
	END;

BEGIN
	-- TODO: it would be a good idea to check for dependency cycles here

	FOR tab IN (SELECT owner, table_name, csrimp_table_name
				  FROM csr.schema_table
			     WHERE enable_import = 1)
	LOOP
		-- Generate unique csrimp table name
		IF tab.csrimp_table_name IS NULL THEN
			-- Because the name generation strategy is non-deterministic, different environments
			-- could end up with different csrimp table mappings. If this becomes an issue an 
			-- alternative would be to force programers to specifiy the mapping table name in the 
			-- basedata.
			tab.csrimp_table_name := GetUniqueCsrimpTableName(tab.owner, tab.table_name);

			UPDATE csr.schema_table 
			   SET csrimp_table_name = tab.csrimp_table_name
			 WHERE owner = tab.owner
			   AND table_name = tab.table_name;
		END IF;

		IF CsrimpTableExists(tab.csrimp_table_name) THEN
			IF CsrimpTableNeedsUpdate(tab.owner, tab.table_name, tab.csrimp_table_name) THEN
				dbms_output.put_line(
					'Changes detected in table ' || tab.owner || '.' || tab.table_name || 
					'. Re-generating csrimp table...');

				DropCsrimpTable(tab.csrimp_table_name);
				CreateCsrimpTable(tab.owner, tab.table_name, tab.csrimp_table_name);
			END IF;
		ELSE
			dbms_output.put_line(
				'Generating csrimp table for new table ' || tab.owner || '.' || tab.table_name || '...'
			);

			CreateCsrimpTable(tab.owner, tab.table_name, tab.csrimp_table_name);
		END IF;
	END LOOP;

	dbms_output.put_line('Creating grants for csrimp/csrexp...');

	FOR tab IN (SELECT owner, table_name, csrimp_table_name
				  FROM csr.schema_table
				 WHERE enable_import = 1)
	LOOP
		EXECUTE IMMEDIATE 'GRANT INSERT ON CSRIMP."'|| tab.csrimp_table_name ||'" TO TOOL_USER';
		EXECUTE IMMEDIATE 'GRANT INSERT ON "' || tab.owner || '"."' || tab.table_name || '" TO CSRIMP';
	END LOOP;

	-- Create grants on sequences
	FOR col IN (SELECT DISTINCT NVL(sc.sequence_owner, sc.owner) sequence_owner, sc.sequence_name 
				  FROM csr.schema_column sc
				  JOIN csr.schema_table st ON sc.table_name = st.table_name
				 WHERE st.enable_import = 1 
				   AND sc.enable_import = 1
				   AND sc.sequence_name IS NOT NULL)
	LOOP
		EXECUTE IMMEDIATE 'GRANT SELECT ON "' || col.sequence_owner || '"."' || col.sequence_name || '" TO CSRIMP';
	END LOOP;
END;
/

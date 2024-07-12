-- trim space from the right but not from the left
SET LINESIZE 9999
SET PAGESIZE 0
SET SERVEROUTPUT ON SIZE UNLIMITED FORMAT TRUNCATED
SET TRIMSPOOL ON

-- suppress "PL/SQL procedure successfully completed."
SET FEEDBACK OFF

-- temp?
SPOOL c:\temp\mcs.OUT

---------
-- HEADER
---------
BEGIN
	DBMS_OUTPUT.PUT_LINE('--');
	DBMS_OUTPUT.PUT_LINE('-- Created with csr/db/utils/makeCreateSchema');
	DBMS_OUTPUT.PUT_LINE('--');
	DBMS_OUTPUT.PUT_LINE('');
	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	-- ! if it prints this and then looks like it's hanging ... just be patient !
	-- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END;
/

--------------------------
-- CREATE SEQUENCE / TABLE
--------------------------
DECLARE
	v_column_name_pad			INTEGER;

	-- NUMBER(1, 10), etc.
	-- we need to collect these first so we know the maximum length for padding
	TYPE array_t IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_datatypes					array_t;

	v_datatype_pad				INTEGER;

	v_i							INTEGER;

	TYPE table_sequence_rt IS RECORD
	(
		table_name		all_tables.table_name%TYPE,
		sequence_name	all_sequences.sequence_name%TYPE
	);
	TYPE table_sequence_t IS TABLE OF table_sequence_rt;
	v_table_sequences			table_sequence_t;

	PROCEDURE CreateSequence(
		in_sequence_name			IN	all_sequences.sequence_name%TYPE,
		in_increment_by				IN	all_sequences.increment_by%TYPE,
		in_min_value				IN	all_sequences.min_value%TYPE,
		in_max_value				IN	all_sequences.max_value%TYPE,
		in_cache_size				IN	all_sequences.cache_size%TYPE,
		in_order_flag				IN	all_sequences.order_flag%TYPE
	)
	AS 
	BEGIN
		DBMS_OUTPUT.PUT('CREATE SEQUENCE CSR.' || in_sequence_name);

		-- a few sequences have START WITH values that aren't 1 (the default)
		-- there's no way to get these from the metadata, so poke them in manually
		IF in_sequence_name = 'FLOW_INVOLVEMENT_TYPE_ID_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 10000');
		ELSIF in_sequence_name = 'IMAGE_UPLOAD_PORTLET_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 129');
		ELSIF in_sequence_name = 'ISSUE_TYPE_ID_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 10000');
		ELSIF in_sequence_name = 'METER_AGGREGATE_TYPE_ID_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 10000');
		ELSIF in_sequence_name = 'METER_INPUT_ID_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 100');
		ELSIF in_sequence_name = 'NON_COMP_DEFAULT_FOLDER_ID_SEQ' THEN
			DBMS_OUTPUT.PUT(' START WITH 2');
		END IF;

		IF in_increment_by <> 1 THEN
			DBMS_OUTPUT.PUT(' INCREMENT BY ' || in_increment_by);
		END IF;

		IF in_min_value IS NOT NULL AND in_min_value <> 1 THEN
			DBMS_OUTPUT.PUT(' MINVALUE ' || in_min_value);
		END IF;

		IF in_max_value IS NOT NULL AND in_max_value NOT IN (999999999999999999999999999, 9999999999999999999999999999) THEN
			DBMS_OUTPUT.PUT(' MAXVALUE ' || in_max_value);
		END IF;

		IF in_cache_size = 0 THEN
			DBMS_OUTPUT.PUT(' NOCACHE');
		ELSIF in_cache_size <> 20 THEN
			-- 20 is the default
			DBMS_OUTPUT.PUT(' CACHE ' || in_cache_size);
		END IF;

		IF in_order_flag = 'Y' THEN
			-- N = NOORDER is the default
			DBMS_OUTPUT.PUT(' ORDER');
		END IF;

		DBMS_OUTPUT.PUT_LINE(';');
	END;

	PROCEDURE CreateSequence(
		in_sequence_name			IN	all_sequences.sequence_name%TYPE
	)
	AS
		v_increment_by			all_sequences.increment_by%TYPE;
		v_min_value				all_sequences.min_value%TYPE;
		v_max_value				all_sequences.max_value%TYPE;
		v_cache_size			all_sequences.cache_size%TYPE;
		v_order_flag			all_sequences.order_flag%TYPE;
	BEGIN
		SELECT increment_by, min_value, max_value, cache_size, order_flag
		  INTO v_increment_by, v_min_value, v_max_value, v_cache_size, v_order_flag
		  FROM all_sequences
		 WHERE sequence_owner = 'CSR'
		   AND sequence_name = in_sequence_name;

		CreateSequence(in_sequence_name, v_increment_by, v_min_value, v_max_value, v_cache_size, v_order_flag);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('*** No data found for sequence ' || in_sequence_name);
			RAISE;
	END;
BEGIN
	-- find which sequences are ID sequences for which tables
	-- in general we can pair these up automatically by name...
	SELECT t.table_name, s.sequence_name
	  BULK COLLECT INTO v_table_sequences
	  FROM all_sequences s
	  LEFT JOIN all_tab_columns t ON s.sequence_owner = t.owner AND s.sequence_name = t.table_name || '_ID_SEQ' AND s.sequence_name = t.column_name || '_SEQ'
	 WHERE s.sequence_owner = 'CSR'
	   AND t.table_name IS NOT NULL
	 -- ... but not always
	 UNION SELECT 'AUDIT_TYPE_FLOW_INV_TYPE', 'AUDIT_TYPE_FLW_INV_TYPE_ID_SEQ' FROM DUAL
	 UNION SELECT 'BENCHMARK_DASHBOARD_CHAR', 'BENCHMARK_DASHB_CHAR_ID_SEQ' FROM DUAL
	 UNION SELECT 'APPROVAL_DASHBOARD_INSTANCE', 'DASHBOARD_INSTANCE_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTOMATED_IMPORT_INSTANCE', 'AUTO_IMP_INSTANCE_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTOMATED_IMPORT_INSTANCE_STEP', 'AUTO_IMP_INSTANCE_STEP_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_IMPEXP_INSTANCE_MSG', 'AUTO_IMPEXP_INSTANCE_MSG_SEQ' FROM DUAL
	 UNION SELECT 'AUTOMATED_EXPORT_INSTANCE', 'AUT_EXPORT_INST_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_EXP_RETRIEVAL_SP', 'AUTO_EXP_RTRVL_SP_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_EXPORT_MESSAGE_MAP', 'AUT_EXPORT_MESSAGE_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_EXP_RETRIEVAL_DATAVIEW', 'AUTO_EXP_RTRVL_DATAVIEW_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_EXP_FILECREATE_DSV', 'AUTO_EXP_FILECRE_DSV_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_EXP_FILEWRITE_FTP', 'AUTO_EXP_FILECRE_FTP_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_IMP_CORE_DATA_SETTINGS', 'AUTO_IMP_COREDTA_SETNGS_ID_SEQ' FROM DUAL
	 UNION SELECT 'AUTO_IMP_IMPORTER_SETTINGS', 'AUTO_IMPORTER_SETTINGS_ID_SEQ' FROM DUAL
	 UNION SELECT 'COURSE_FILE', 'COURSE_FILE_ID_SEQ' FROM DUAL
	 UNION SELECT 'CUSTOMER_FLOW_CAPABILITY', 'CUSTOMER_FLOW_CAP_ID_SEQ' FROM DUAL
	 UNION SELECT 'CUSTOMER_SAML_SSO_CERT', 'SSO_CERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_CHANGE_ALERT', 'DELEG_CHANGE_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_EDITED_ALERT', 'DELEG_EDIT_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_DATE_SCHEDULE', 'DELEGATION_DATE_SCHEDULE_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_GRID', 'DELEGATION_GRID_ID_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_LAYOUT', 'DELEGATION_LAYOUT_ID_SEQ' FROM DUAL
	 UNION SELECT 'DELEGATION_TERMINATED_ALERT', 'DELEG_TERMINATED_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'FLOW_ITEM_GENERATED_ALERT', 'FLOW_ITEM_GEN_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'FLOW_STATE_ROLE_CAPABILITY', 'FLOW_STATE_RL_CAP_ID_SEQ' FROM DUAL
	 UNION SELECT 'GRESB_SUBMISSION_LOG', 'GRESB_SUBMISSION_SEQ' FROM DUAL
	 UNION SELECT 'HELP_IMAGE', 'HELP_IMAGE_ID_SEQ' FROM DUAL
	 UNION SELECT 'HELP_TAG', 'HELP_TAG_ID_SEQ' FROM DUAL
	 UNION SELECT 'IMAGE_UPLOAD_PORTLET', 'IMAGE_UPLOAD_PORTLET_SEQ' FROM DUAL
	 UNION SELECT 'INITIATIVE_IMPORT_MAP_MRU', 'INIT_IMPORT_MAPPING_POS_SEQ' FROM DUAL
	 UNION SELECT 'INITIATIVE_IMPORT_TEMPLATE_MAP', 'INIT_IMPORT_TEMPLATE_ID_SEQ' FROM DUAL
	 UNION SELECT 'INITIATIVE_PERIOD_STATUS', 'INITIATIV_PERIOD_STATUS_ID_SEQ' FROM DUAL
	 UNION SELECT 'INTERNAL_AUDIT_FILE', 'INTERNAL_AUDIT_FILE_ID_SEQ' FROM DUAL
	 UNION SELECT 'INTERNAL_AUDIT_TYPE_GROUP', 'INTERNAL_AUDIT_TYPE_GROUP_SEQ' FROM DUAL
	 UNION SELECT 'INTERNAL_AUDIT_TYPE_SURVEY', 'IA_TYPE_SURVEY_ID_SEQ' FROM DUAL
	 UNION SELECT 'ISSUE_METER_MISSING_DATA', 'ISSUE_METER_MISSING_DATA_SEQ' FROM DUAL
	 UNION SELECT 'MAP_SHPFILE', 'MAP_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_ALARM_COMPARISON', 'METER_COMPARISON_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_ALARM_ISSUE_PERIOD', 'METER_ISSUE_PERIOD_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_ALARM_STATISTIC', 'METER_STATISTIC_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_ALARM_TEST_TIME', 'METER_TEST_TIME_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_DATA_ID', 'METER_DATA_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_RAW_DATA_ERROR', 'METER_RAW_DATA_ERROR_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_RAW_DATA_LOG', 'METER_RAW_DATA_LOG_ID_SEQ' FROM DUAL
	 UNION SELECT 'METER_RAW_DATA_SOURCE', 'RAW_DATA_SOURCE_ID_SEQ' FROM DUAL
	 UNION SELECT 'MODEL_RANGE', 'MODEL_RANGE_ID_SEQ' FROM DUAL
	 UNION SELECT 'MODEL_SHEET', 'MODEL_SHEET_ID_SEQ' FROM DUAL
	 UNION SELECT 'NEW_PLANNED_DELEG_ALERT', 'NEW_PLANDELEG_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'QS_CUSTOM_QUESTION_TYPE', 'CUSTOM_QUESTION_TYPE_ID_SEQ' FROM DUAL
	 UNION SELECT 'QS_EXPR_NON_COMPL_ACTION', 'QS_EXPR_NC_ACTION_ID_SEQ' FROM DUAL
	 UNION SELECT 'QS_QUESTION_OPTION', 'QS_QUESTION_OPTION_ID_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_ANSWER', 'VERSION_STAMP_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_EXPR', 'EXPR_ID_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_EXPR_ACTION', 'QS_EXPR_ACTION_ID_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_QUESTION', 'QUESTION_ID_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_RESPONSE', 'SURVEY_RESPONSE_ID_SEQ' FROM DUAL
	 UNION SELECT 'QUICK_SURVEY_SUBMISSION', 'QS_SUBMISSION_ID_SEQ' FROM DUAL
	 UNION SELECT 'SAML_ASSERTION_LOG', 'SAML_REQUEST_ID_SEQ' FROM DUAL
	 UNION SELECT 'SCENARIO_MAN_RUN_REQUEST', 'SCENARIO_MAN_RUN_REQ_ID_SEQ' FROM DUAL
	 UNION SELECT 'SCENARIO_RUN_VAL', 'SCENARIO_RUN_VAL_ID_SEQ' FROM DUAL
	 UNION SELECT 'SECTION_ATTACH_LOG', 'SEC_ATTACH_LOG_ID_SEQ' FROM DUAL
	 UNION SELECT 'STD_FACTOR_SET', 'FACTOR_SET_ID_SEQ' FROM DUAL
	 UNION SELECT 'SUPPLIER_SCORE_LOG', 'SUPPLIER_SCORE_ID_SEQ' FROM DUAL
	 UNION SELECT 'TAB_GROUP', 'TAG_GROUP_ID_SEQ' FROM DUAL
	 UNION SELECT 'TPL_REPORT_TAG_APPROVAL_NOTE', 'TPL_REPORT_TAG_APP_NOTE_ID_SEQ' FROM DUAL
	 UNION SELECT 'TPL_REPORT_TAG_APPROVAL_MATRIX', 'TPL_REP_TAG_APP_MATRIX_ID_SEQ' FROM DUAL
	 UNION SELECT 'TPL_REPORT_TAG_LOGGING_FORM', 'TPL_REPORT_TAG_LOGGING_FRM_SEQ' FROM DUAL
	 UNION SELECT 'UPDATED_PLANNED_DELEG_ALERT', 'UPDATED_PLANDELEG_ALERT_ID_SEQ' FROM DUAL
	 UNION SELECT 'UTILITY_INVOICE_FIELD', 'UTILITY_INVOICE_FIELD_ID_SEQ' FROM DUAL
	 UNION SELECT 'WORKSHEET_VALUE_MAP', 'VALUE_MAP_ID_SEQ' FROM DUAL
	;

	-- orphaned sequences
	DBMS_OUTPUT.PUT_LINE('-- possibly orphaned sequences');
	<<outer_loop>>
	FOR r IN (
		SELECT sequence_name, increment_by, min_value, max_value, cache_size, order_flag FROM all_sequences
		WHERE sequence_owner = 'CSR'
		ORDER BY REPLACE(sequence_name, '_', '!') -- order underscores between ' ' and 'A'
	)
	LOOP
		IF r.sequence_name = 'FLOW_ITEM_ALERT_ID_SEQ' THEN
			DBMS_OUTPUT.PUT_LINE('-- seems to still be used in client code');
		ELSE
			-- bleurgh; must be a simpler way of doing this
			FOR i IN v_table_sequences.FIRST .. v_table_sequences.LAST LOOP
				-- DBMS_OUTPUT.PUT_LINE('r.sequence_name = ' || r.sequence_name);
				-- DBMS_OUTPUT.PUT_LINE('v_table_sequences(i).sequence_name = ' || v_table_sequences(i).sequence_name);
	
				IF r.sequence_name = v_table_sequences(i).sequence_name THEN
					-- DBMS_OUTPUT.PUT_LINE('-- skipping ' || r.sequence_name);
	
					CONTINUE outer_loop;
				END IF;
			END LOOP;
		END IF;
		-- DBMS_OUTPUT.PUT_LINE('-- keeping ' || r.sequence_name);
		CreateSequence(r.sequence_name, r.increment_by, r.min_value, r.max_value, r.cache_size, r.order_flag);
	END LOOP outer_loop;

	-- tables
	FOR r IN (
		SELECT owner, table_name
		  FROM all_tables
		 WHERE owner = 'CSR'
		   AND temporary = 'N'
		   AND table_name NOT LIKE 'DR$%' -- full text search stuff?
		   AND table_name NOT LIKE '%_OLD'
		   AND table_name NOT LIKE 'FB%'
		 ORDER BY REPLACE(table_name, '_', '!') -- order underscores between ' ' and 'A'
	) LOOP
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE('CREATE TABLE ' || r.owner || '.' || r.table_name || '(');

		-- column names are padded based on the maximum name length for this table, with a gutter of 4
		SELECT MAX(LENGTH(column_name) + 4)
		  INTO v_column_name_pad
		  FROM all_tab_columns
		 WHERE owner = r.owner
		   AND table_name = r.table_name
		   AND column_name NOT LIKE 'XXX_%' -- ignore old columns that were renamed instead of being deleted
		   AND column_name NOT LIKE 'XX_%';

		-- construct the datatypes into a collection
		SELECT CASE
			WHEN data_type = 'NUMBER' AND data_precision IS NULL THEN
				data_type
			WHEN data_type = 'NUMBER' THEN
				data_type || '(' || data_precision || ', ' || data_scale || ')'
			WHEN data_type IN ('BLOB', 'CLOB', 'DATE', 'TIMESTAMP(6)') THEN
				data_type
			WHEN data_type = 'XMLTYPE' AND data_length = 2000 THEN
				-- match what ER Studio did
				'SYS.XMLType'
			-- No need to specify BYTE here -- all CSR table columns are specified as BYTE not CHAR except a few random hacks we can ignore
			--WHEN data_type IN ('VARCHAR', 'VARCHAR2') THEN
			--	data_type || '(' || data_length || CASE WHEN char_used = 'B' THEN ' BYTE' ELSE '' END || ')'
			WHEN data_type = 'TIMESTAMP(6) WITH TIME ZONE' AND data_length = 13 THEN
				'TIMESTAMP WITH TIME ZONE'
			WHEN data_type = 'CHAR' AND data_length = 1 THEN
				'CHAR' -- not 'CHAR(1)'
			WHEN data_type LIKE 'INTERVAL%' THEN
				data_type
			ELSE
				data_type || '(' || data_length || ')'
			END
		  BULK COLLECT INTO v_datatypes
		  FROM all_tab_columns
		 WHERE owner = r.owner
		   AND table_name = r.table_name
		 ORDER BY column_id;

		-- note we cannot change this to SELECT MAX(...) FROM TABLE(v_datatypes);
		-- unless we move the type definitions from local PL/SQL to global SQL
		v_datatype_pad := 0;

		FOR i IN v_datatypes.FIRST .. v_datatypes.LAST
		LOOP
			IF LENGTH(v_datatypes(i)) > v_datatype_pad THEN
				v_datatype_pad := LENGTH(v_datatypes(i));
			END IF;
		END LOOP;

		v_datatype_pad := v_datatype_pad + 4; -- gutter of 4 spaces

		v_i := 1; -- 1-based array index

		FOR s IN (
			SELECT column_name, data_default, nullable
			  FROM all_tab_columns
			 WHERE owner = r.owner
			   AND table_name = r.table_name
			   AND column_name NOT LIKE 'XXX_%' -- ignore old columns that were renamed instead of being deleted
			   AND column_name NOT LIKE 'XX_%'
			 ORDER BY column_id
		) LOOP
			IF v_i > 1 THEN
				DBMS_OUTPUT.PUT_LINE(',');
			END IF;

			DBMS_OUTPUT.PUT('    ' || RPAD(s.column_name, v_column_name_pad));

			IF s.data_default IS NULL AND s.nullable = 'Y' THEN
				-- no padding
				DBMS_OUTPUT.PUT(v_datatypes(v_i));
			ELSE
				DBMS_OUTPUT.PUT(RPAD(v_datatypes(v_i), v_datatype_pad));

				IF s.data_default IS NOT NULL THEN
					DBMS_OUTPUT.PUT('DEFAULT ' || REGEXP_REPLACE(s.data_default, '\s+$', ''));
					IF s.nullable = 'N' THEN
						DBMS_OUTPUT.PUT(' ');
					END IF;
				END IF;
	
				IF s.nullable = 'N' THEN
					DBMS_OUTPUT.PUT('NOT NULL');
				END IF;
			END IF;

			v_i := v_i + 1;
		END LOOP;

		-- check constraints
		FOR s IN (
			SELECT constraint_name, search_condition, generated
			  FROM all_constraints
			 WHERE owner = r.owner
			   AND table_name = r.table_name
			   AND constraint_type = 'C'
			 ORDER BY generated, constraint_name -- put the ones with generated names first ('GENERATED NAME' < 'USER NAME'); ideally they would all be USER NAMEs
		) LOOP
			-- can't do this check in the WHERE above because search_condition is a LONG type
			IF s.generated = 'USER NAME' OR NOT REGEXP_LIKE(s.search_condition, '^"[A-Z0-9_]+" IS NOT NULL$') THEN
				DBMS_OUTPUT.PUT_LINE(',');
				DBMS_OUTPUT.PUT('    ');
				IF s.generated = 'USER NAME' THEN
					DBMS_OUTPUT.PUT('CONSTRAINT ' || s.constraint_name || ' ');
				END IF;
				DBMS_OUTPUT.PUT('CHECK (' || s.search_condition || ')');
			END IF;
		END LOOP;

		-- primary key / unique constraints
		FOR s IN (
			SELECT ac.constraint_name,
				   CASE ac.constraint_type WHEN 'U' THEN 'UNIQUE' WHEN 'P' THEN 'PRIMARY KEY' END constraint_description,
			       LISTAGG(aic.column_name, ', ') WITHIN GROUP (ORDER BY aic.column_position) cols
			  FROM all_constraints ac
			  LEFT JOIN all_ind_columns aic ON ac.table_name = aic.table_name AND ac.owner = aic.table_owner AND ac.index_name = aic.index_name
			 WHERE ac.owner = r.owner
			   AND ac.table_name = r.table_name
			   AND ac.constraint_type IN ('P', 'U')
			 GROUP BY ac.constraint_name, ac.constraint_type
			 ORDER BY ac.constraint_type, ac.constraint_name
		) LOOP
			DBMS_OUTPUT.PUT_LINE(',');
			DBMS_OUTPUT.PUT('    CONSTRAINT ' || s.constraint_name || ' ' || s.constraint_description || ' (' || s.cols || ')');
		END LOOP;

		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE(')');
		DBMS_OUTPUT.PUT_LINE(';');

		-- comments on tables
		FOR s IN (
			SELECT comments
			  FROM all_tab_comments
			 WHERE owner = r.owner
			   AND table_name = r.table_name
			   AND comments IS NOT NULL
		) LOOP
			DBMS_OUTPUT.PUT_LINE('');
			DBMS_OUTPUT.PUT_LINE('COMMENT ON TABLE ' || r.owner || '.' || r.table_name || ' IS ''' || s.comments || '''');
			DBMS_OUTPUT.PUT_LINE(';');
		END LOOP;

		-- comments on columns
		FOR s IN (
			SELECT column_name, comments
			  FROM all_col_comments
			 WHERE owner = r.owner
			   AND table_name = r.table_name
			   AND comments IS NOT NULL
			 ORDER BY column_name
		) LOOP
			DBMS_OUTPUT.PUT_LINE('');
			DBMS_OUTPUT.PUT_LINE('COMMENT ON COLUMN ' || r.owner || '.' || r.table_name || '.' || s.column_name || ' IS ''' || s.comments || '''');
			DBMS_OUTPUT.PUT_LINE(';');
		END LOOP;

		-- sequence specific to this table, if there is one
		FOR i IN v_table_sequences.FIRST .. v_table_sequences.LAST LOOP
			IF r.table_name = v_table_sequences(i).table_name THEN
				DBMS_OUTPUT.PUT_LINE('');
				CreateSequence(v_table_sequences(i).sequence_name);
			END IF;
		END LOOP;

		-- indexes specific to this table, if there are any
		FOR s IN (
			SELECT ai.owner, ai.table_name, ai.index_name, ai.uniqueness,
			       LISTAGG(aic.column_name, ', ') WITHIN GROUP (ORDER BY aic.column_position) cols
			  FROM all_indexes ai
			  LEFT JOIN all_ind_columns aic ON ai.table_name = aic.table_name AND ai.owner = aic.table_owner AND ai.index_name = aic.index_name
			  LEFT JOIN all_constraints ac ON ai.index_name = ac.index_name AND ai.owner = ac.owner
			 WHERE ai.owner = 'CSR'
			   AND ai.index_type = 'NORMAL'
			   AND ac.index_name IS NULL
			   AND aic.table_owner = 'CSR'
			   AND ai.table_name = r.table_name
			   AND aic.table_name = r.table_name
			 GROUP BY ai.owner, ai.table_name, ai.index_name, ai.uniqueness
			 ORDER BY ai.table_name, ai.index_name
		) LOOP
			DBMS_OUTPUT.PUT_LINE('');
			DBMS_OUTPUT.PUT('CREATE ');
			IF s.uniqueness = 'UNIQUE' THEN
				DBMS_OUTPUT.PUT('UNIQUE ');
			END IF;
			DBMS_OUTPUT.PUT('INDEX ' || s.owner || '.' || REGEXP_REPLACE(s.index_name, '^REF', 'Ref'));
			DBMS_OUTPUT.PUT(' ON ' || s.owner || '.' || s.table_name);
			DBMS_OUTPUT.PUT('(' || s.cols || ')');
			DBMS_OUTPUT.PUT_LINE('');
			DBMS_OUTPUT.PUT_LINE(';');
		END LOOP;
	END LOOP;
END;
/

----------------------------
-- ALTER TABLE
-- (Foreign key constraints)
----------------------------
DECLARE
	v_previous_table			VARCHAR2(30);
BEGIN
	FOR r IN (
		SELECT t1_owner, t1_table_name, t1_constraint_name, t1_column_names, t1_delete_rule, deferrable, deferred, t2_table_name, t2_column_names
		  FROM (
			SELECT acc.owner t1_owner,
			       acc.table_name t1_table_name,
			       acc.constraint_name t1_constraint_name,
			       ac.r_constraint_name t2_constraint_name,
			       LISTAGG(acc.column_name, ', ') WITHIN GROUP (ORDER BY acc.position) t1_column_names,
			       ac.delete_rule t1_delete_rule,
			       ac.deferrable,
			       ac.deferred
			  FROM all_cons_columns acc
			  JOIN all_constraints ac ON acc.constraint_name = ac.constraint_name AND acc.owner = ac.owner
			 WHERE ac.constraint_type = 'R'
			   AND acc.owner = 'CSR' -- only interested in FKs between two CSR tables here
			 GROUP BY acc.owner, acc.table_name, acc.constraint_name, ac.r_constraint_name, ac.delete_rule, ac.deferrable, ac.deferred
		) t1,
		(
			SELECT acc.constraint_name t2_constraint_name,
			       acc.table_name t2_table_name,
			       LISTAGG(acc.column_name, ', ') WITHIN GROUP (ORDER BY acc.position) t2_column_names
			  FROM all_cons_columns acc
			  JOIN all_constraints ac ON acc.constraint_name = ac.constraint_name AND acc.owner = ac.owner
			 WHERE ac.constraint_type IN ('P', 'U')
			   AND acc.owner = 'CSR' -- only interested in FKs between two CSR tables here
			 GROUP BY acc.table_name, acc.constraint_name
		) t2
		 WHERE t1.t2_constraint_name = t2.t2_constraint_name
		 ORDER BY REPLACE(t1_table_name, '_', '!'), REPLACE(t1_constraint_name, '_', '!') -- order underscores between ' ' and 'A'
	) LOOP
		IF v_previous_table IS NULL OR r.t1_table_name <> v_previous_table THEN
			DBMS_OUTPUT.PUT_LINE('');
			DBMS_OUTPUT.PUT_LINE('');
			v_previous_table := r.t1_table_name;
		END IF;
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE('ALTER TABLE ' || r.t1_owner || '.' || r.t1_table_name || ' ADD CONSTRAINT ' || REGEXP_REPLACE(r.t1_constraint_name, '^REF', 'Ref'));
		DBMS_OUTPUT.PUT_LINE('    FOREIGN KEY (' || r.t1_column_names || ')');
		DBMS_OUTPUT.PUT('    REFERENCES ' || r.t1_owner || '.' || r.t2_table_name || '(' || r.t2_column_names || ')');
		CASE
			WHEN r.t1_delete_rule IS NULL THEN NULL;
			WHEN r.t1_delete_rule = 'CASCADE' THEN DBMS_OUTPUT.PUT(' ON DELETE CASCADE');
			WHEN r.t1_delete_rule = 'NO ACTION' THEN NULL; -- this is the default
			WHEN r.t1_delete_rule = 'SET NULL' THEN DBMS_OUTPUT.PUT(' ON DELETE SET NULL');
			ELSE RAISE_APPLICATION_ERROR(-20001, 'Unknown delete rule ' || r.t1_delete_rule);
		END CASE;
		IF r.deferrable = 'DEFERRABLE' THEN
			DBMS_OUTPUT.PUT(' DEFERRABLE');
			IF r.deferred = 'DEFERRED' THEN
				-- default is INITIALLY IMMEDIATE, so no need to output that
				DBMS_OUTPUT.PUT(' INITIALLY DEFERRED');
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('');
		DBMS_OUTPUT.PUT_LINE(';');
	END LOOP;
END;
/

BEGIN
	DBMS_OUTPUT.PUT_LINE('');
	DBMS_OUTPUT.PUT_LINE('-- IF YOU ARE THINKING ABOUT PASTING SHIT DOWN HERE YOU''VE PROBABLY GOT THE WRONG IDEA');
	DBMS_OUTPUT.PUT_LINE('-- USE csr/db/utils/makeCreateSchema.sql AGAINST A DATABASE CONTAINING YOUR CHANGES');
	DBMS_OUTPUT.PUT_LINE('-- AND IT WILL PUT THINGS IN THE RIGHT PLACE FOR YOU IN THE FILE IT GENERATES');
	DBMS_OUTPUT.PUT_LINE('');
	DBMS_OUTPUT.PUT_LINE('-- please make sure this file ends with a new line (the same goes for all source code -- this avoids merge issues)');
	DBMS_OUTPUT.PUT_LINE('');
END;
/

SPOOL OFF


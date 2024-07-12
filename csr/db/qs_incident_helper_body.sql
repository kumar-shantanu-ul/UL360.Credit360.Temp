CREATE OR REPLACE PACKAGE BODY csr.qs_incident_helper_pkg AS

PROCEDURE AddAutoColumnValues (
	in_tab_sid			IN	security_pkg.T_SID_ID,
	in_fields			IN	T_QS_INC_FIELD_TABLE,
	out_fields			OUT	T_QS_INC_FIELD_TABLE
)
AS
	v_fields			T_QS_INC_FIELD_TABLE := in_fields;
	v_auto_id			security_pkg.T_SID_ID;
BEGIN
	FOR r IN (
		SELECT tc.oracle_column, tc.auto_sequence
		  FROM cms.tab_column tc
		 WHERE tc.tab_sid = in_tab_sid
		   AND tc.col_type = cms.tab_pkg.CT_AUTO_INCREMENT
		   AND NOT EXISTS (
				SELECT NULL FROM TABLE(v_fields) f WHERE UPPER(f.oracle_column) = UPPER(tc.oracle_column)
		   )
	) LOOP
		EXECUTE IMMEDIATE 'SELECT ' || NVL(r.auto_sequence, 'CMS.ITEM_ID_SEQ') || '.NEXTVAL FROM dual' INTO v_auto_id;
		
		v_fields.EXTEND;
		v_fields(v_fields.COUNT) := T_QS_INC_FIELD_ROW(r.oracle_column, 'num', NULL, v_auto_id, NULL);
	END LOOP;

	out_fields := v_fields;
END;

PROCEDURE BuildInsertParts (
	in_fields			IN	T_QS_INC_FIELD_TABLE,
	out_columns_sql		OUT	VARCHAR2,
	out_values_sql		OUT	VARCHAR2
)
AS
	v_columns_sql		VARCHAR2(16000);
	v_values_sql		VARCHAR2(16000);
BEGIN

	FOR r IN (
		SELECT oracle_column
		  FROM TABLE(in_fields)
	) LOOP

		IF v_columns_sql IS NOT NULL THEN
			v_columns_sql := v_columns_sql || ', ';
		END IF;
		v_columns_sql := v_columns_sql || r.oracle_column;

		IF v_values_sql IS NOT NULL THEN
			v_values_sql := v_values_sql || ', ';
		END IF;
		v_values_sql := v_values_sql || ':' || LOWER(r.oracle_column);

	END LOOP;

	out_columns_sql := v_columns_sql;
	out_values_sql := v_values_sql;
END;

PROCEDURE BindAndExecuteInsert (
	in_sql				IN	VARCHAR2,
	in_fields			IN	T_QS_INC_FIELD_TABLE
)
AS
	v_cur				INTEGER;
	v_rows				INTEGER;
BEGIN
	v_cur := dbms_sql.open_cursor;
	
	BEGIN
		dbms_sql.parse(v_cur, in_sql, dbms_sql.NATIVE);
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE_APPLICATION_ERROR(-20001, SQLERRM || CHR(10) || 'While parsing SQL: ' || in_sql);
	END;
	
	BEGIN
		FOR r IN (
			SELECT oracle_column, bind_type, text_value, num_value, date_value
			  FROM TABLE(in_fields)
		) LOOP
			IF r.bind_type = 'text' THEN
				dbms_sql.bind_variable(v_cur, ':' || LOWER(r.oracle_column), r.text_value);
			ELSIF r.bind_type = 'date' THEN
				dbms_sql.bind_variable(v_cur, ':' || LOWER(r.oracle_column), r.date_value);
			ELSIF r.bind_type = 'num' THEN
				dbms_sql.bind_variable(v_cur, ':' || LOWER(r.oracle_column), r.num_value);
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Cannot bind data of type ' || r.bind_type);
			END IF;
		END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE_APPLICATION_ERROR(-20001, SQLERRM || CHR(10) || 'While binding SQL: ' || in_sql);
	END;

	BEGIN
		v_rows := dbms_sql.execute(v_cur);
	EXCEPTION
		WHEN OTHERS THEN
			dbms_sql.close_cursor(v_cur);
			RAISE_APPLICATION_ERROR(-20001, SQLERRM || CHR(10) || 'While executing SQL: ' || in_sql);
	END;
	
	dbms_sql.close_cursor(v_cur);

	IF v_rows != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Wrong number of rows (' || v_rows || ') inserted for SQL: ' || in_sql);
	END IF;
END;

PROCEDURE OnSurveySubmitted (
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_response_id		IN	quick_survey_submission.survey_response_id%TYPE,
	in_submission_id	IN	quick_survey_submission.submission_id%TYPE
)
AS
	v_survey_version	quick_survey_response.survey_version%TYPE;
	v_lookup_key		quick_survey.lookup_key%TYPE;
	v_tab_sid			security_pkg.T_SID_ID;
	v_flow_sid			security_pkg.T_SID_ID;
	v_oracle_schema		VARCHAR2(30);
	v_oracle_table		VARCHAR2(30);
	v_response_column	VARCHAR2(30);
	v_flow_item_column	VARCHAR2(30);
	v_flow_item_id		security_pkg.T_SID_ID;
	v_latitude_col_sid	security_pkg.T_SID_ID;
	v_latitude_column	VARCHAR2(30);
	v_longitude_column	VARCHAR2(30);
	v_altitude_column	VARCHAR2(30);
	v_h_accuracy_column	VARCHAR2(30);
	v_v_accuracy_column	VARCHAR2(30);
	v_geo_data			quick_survey_submission.geo_latitude%TYPE;
	v_incident_fields	T_QS_INC_FIELD_TABLE;
	v_columns_sql		VARCHAR2(16000);
	v_values_sql		VARCHAR2(16000);
	v_sql				VARCHAR2(32767);
	v_col_type			cms.tab_column.col_type%TYPE;
	v_question_type		quick_survey_question.question_type%TYPE;
	v_answer			quick_survey_answer.answer%TYPE;
	v_val_number		quick_survey_answer.val_number%TYPE;
	v_date				DATE;
	v_region_sid		quick_survey_answer.region_sid%TYPE;
	v_option_lookup_key	quick_survey_question.lookup_key%TYPE;
	v_files_tab_sid		security_pkg.T_SID_ID;
	v_file_fields		T_QS_INC_FIELD_TABLE;
	v_file_data_column	VARCHAR2(30);
	v_file_name_column	VARCHAR2(30);
	v_file_mime_column	VARCHAR2(30);
	v_caption_column	VARCHAR2(30);
	v_column_names		T_VARCHAR2_TABLE;
BEGIN
	-- I don't know what this is or what it does, but IO.cs does it so I assume it is important.
	cms.tab_pkg.GoToContext(NULL);

	SELECT survey_version
	  INTO v_survey_version
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;

	SELECT lookup_key
	  INTO v_lookup_key
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;

	IF v_lookup_key IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Survey ' || in_survey_sid || ' does not have a lookup key');
	END IF;

	BEGIN
		SELECT tab_sid, oracle_schema, oracle_table, flow_sid
		  INTO v_tab_sid, v_oracle_schema, v_oracle_table, v_flow_sid
		  FROM cms.tab
		 WHERE UPPER(oracle_table) = UPPER(v_lookup_key) OR UPPER(oracle_schema) || '.' || UPPER(oracle_table) = UPPER(v_lookup_key);
	EXCEPTION
		WHEN no_data_found THEN
			RAISE_APPLICATION_ERROR(-20001, 'No CMS table with name ' || v_lookup_key);
	END;

	v_incident_fields := T_QS_INC_FIELD_TABLE();

	BEGIN
		SELECT oracle_column
		  INTO v_response_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = cms.tab_pkg.CT_SURVEY_RESPONSE;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
		WHEN too_many_rows THEN
			RAISE_APPLICATION_ERROR(-20001, 'Too many survey response columns in CMS table ' || v_oracle_table);
	END;

	IF v_response_column IS NOT NULL THEN
		v_incident_fields.EXTEND;
		v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_response_column, 'num', NULL, in_response_id, NULL);
	END IF;

	BEGIN
		SELECT oracle_column
		  INTO v_flow_item_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = cms.tab_pkg.CT_FLOW_ITEM;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
		WHEN too_many_rows THEN
			RAISE_APPLICATION_ERROR(-20001, 'Too many flow item columns in CMS table ' || v_oracle_table);
	END;

	IF v_flow_item_column IS NOT NULL THEN
		-- We deliberately don't use AddCmsItem here, since that would check flow permissions, and we want anonymous users to be able to submit the surveys.
		flow_pkg.AddFlowItem(v_flow_sid, v_flow_item_id);
		
		v_incident_fields.EXTEND;
		v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_flow_item_column, 'num', NULL, v_flow_item_id, NULL);
	END IF;

	BEGIN
		SELECT column_sid, oracle_column
		  INTO v_latitude_col_sid, v_latitude_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = cms.tab_pkg.CT_LATITUDE;
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
		WHEN too_many_rows THEN
			NULL;
	END;

	IF v_latitude_col_sid IS NOT NULL THEN
		SELECT geo_latitude
		  INTO v_geo_data
		  FROM quick_survey_submission
		 WHERE survey_response_id = in_response_id
		   AND submission_id = in_submission_id;
		 
		v_incident_fields.EXTEND;
		v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_latitude_column, 'num', NULL, v_geo_data, NULL);

		SELECT oracle_column
		  INTO v_longitude_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = cms.tab_pkg.CT_LONGITUDE
		   AND master_column_sid = v_latitude_col_sid;

		SELECT geo_longitude
		  INTO v_geo_data
		  FROM quick_survey_submission
		 WHERE survey_response_id = in_response_id
		   AND submission_id = in_submission_id;
		   
		v_incident_fields.EXTEND;
		v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_longitude_column, 'num', NULL, v_geo_data, NULL);
		
		SELECT oracle_column
		  INTO v_h_accuracy_column
		  FROM cms.tab_column
		 WHERE tab_sid = v_tab_sid
		   AND col_type = cms.tab_pkg.CT_H_ACCURACY
		   AND master_column_sid = v_latitude_col_sid;

		SELECT geo_h_accuracy
		  INTO v_geo_data
		  FROM quick_survey_submission
		 WHERE survey_response_id = in_response_id
		   AND submission_id = in_submission_id;
		   
		v_incident_fields.EXTEND;
		v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_h_accuracy_column, 'num', NULL, v_geo_data, NULL);

		BEGIN
			SELECT oracle_column
			  INTO v_altitude_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_tab_sid
			   AND col_type = cms.tab_pkg.CT_ALTITUDE
			   AND master_column_sid = v_latitude_col_sid;
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;

		IF v_altitude_column IS NOT NULL THEN
			SELECT geo_altitude
			  INTO v_geo_data
			  FROM quick_survey_submission
			 WHERE survey_response_id = in_response_id
			   AND submission_id = in_submission_id;
		   
			v_incident_fields.EXTEND;
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_altitude_column, 'num', NULL, v_geo_data, NULL);
			
			SELECT oracle_column
			  INTO v_v_accuracy_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_tab_sid
			   AND col_type = cms.tab_pkg.CT_V_ACCURACY
			   AND master_column_sid = v_latitude_col_sid;

			SELECT geo_v_accuracy
			  INTO v_geo_data
			  FROM quick_survey_submission
			 WHERE survey_response_id = in_response_id
			   AND submission_id = in_submission_id;
		   
			v_incident_fields.EXTEND;
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(v_v_accuracy_column, 'num', NULL, v_geo_data, NULL);
		END IF;
	END IF;

	FOR r IN (
		SELECT DISTINCT NVL(SUBSTR(qsq.lookup_key, 1, INSTR(qsq.lookup_key, '.')-1), qsq.lookup_key) question_column
		  FROM quick_survey_question qsq
		 WHERE qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = v_survey_version
		   AND qsq.lookup_key IS NOT NULL
		   AND qsq.question_type IN ('checkbox', 'date', 'note', 'number', 'radio', 'radiorow', 'regionpicker', 'slider')
	) LOOP
		BEGIN
			SELECT col_type
			  INTO v_col_type
			  FROM cms.tab_column
			 WHERE tab_sid = v_tab_sid
			   AND UPPER(oracle_column) = UPPER(r.question_column);
		EXCEPTION
			WHEN no_data_found THEN
				RAISE_APPLICATION_ERROR(-20001, 'No CMS column with name ' || r.question_column);
		END;

		BEGIN
			SELECT DISTINCT qsq.question_type
			  INTO v_question_type
			  FROM quick_survey_question qsq
			 WHERE qsq.survey_sid = in_survey_sid
			   AND qsq.survey_version = v_survey_version
			   AND (qsq.lookup_key = r.question_column OR qsq.lookup_key LIKE r.question_column || '.%')
			   AND qsq.question_type IN ('checkbox', 'date', 'note', 'number', 'radio', 'radiorow', 'regionpicker', 'slider');
		EXCEPTION
			WHEN too_many_rows THEN
				RAISE_APPLICATION_ERROR(-20001, 'Inconsistent question types for CMS column ' || r.question_column);
		END;

		BEGIN
			SELECT qsa.answer, qsa.val_number, qsa.region_sid, 
				   qso.lookup_key
			  INTO v_answer, v_val_number, v_region_sid,
				   v_option_lookup_key
			  FROM quick_survey_question qsq
			  JOIN quick_survey_answer qsa ON qsa.survey_sid = qsq.survey_sid 
										  AND qsa.survey_version = qsq.survey_version
										  AND qsa.question_id = qsq.question_id
			  LEFT JOIN qs_question_option qso ON qso.survey_sid = qsq.survey_sid
											  AND qso.survey_version = qsq.survey_version
											  AND qso.question_option_id = qsa.question_option_id
			 WHERE qsq.survey_sid = in_survey_sid
			   AND qsq.survey_version = v_survey_version
			   AND (qsq.lookup_key = r.question_column OR qsq.lookup_key LIKE r.question_column || '.%')
			   AND qsq.question_type IN ('checkbox', 'date', 'note', 'number', 'radio', 'radiorow', 'regionpicker', 'slider')
			   AND qsa.survey_response_id = in_response_id
			   AND qsa.submission_id = in_submission_id
			   AND (qsa.answer IS NOT NULL OR qsa.val_number IS NOT NULL OR qsa.region_sid IS NOT NULL OR qsa.question_option_id IS NOT NULL);
		EXCEPTION
			WHEN no_data_found THEN
				v_answer := NULL;
				v_val_number := NULL;
				v_region_sid := NULL;
				v_option_lookup_key := NULL;
		END;
		
		v_incident_fields.EXTEND;

		IF v_question_type IN ('checkbox', 'number', 'slider') THEN
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'num',NULL, v_val_number, NULL);
		ELSIF v_question_type IN ('date') THEN
			v_date := TO_DATE('30-12-1899', 'DD-MM-YYYY') + v_val_number;
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'date', NULL, NULL, v_date);
		ELSIF v_question_type IN ('radio', 'radiorow') THEN
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'num',NULL, v_option_lookup_key, NULL);
		ELSIF v_question_type IN ('regionpicker') THEN
			v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'num',NULL, v_region_sid, NULL);
		ELSIF v_question_type IN ('note') THEN
			IF v_col_type = cms.tab_pkg.CT_TIME THEN
				IF INSTR(v_answer, ':') > 0 THEN
					v_date := TO_DATE(v_answer, 'HH24:MI');
				ELSE
					v_date := TO_DATE(v_answer, 'HH24MI');
				END IF;
				v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'date', NULL, NULL, v_date);
			ELSE
				v_incident_fields(v_incident_fields.COUNT) := T_QS_INC_FIELD_ROW(r.question_column, 'text', v_answer, NULL, NULL);
			END IF;
		END IF;
	END LOOP;

	AddAutoColumnValues(v_tab_sid, v_incident_fields, v_incident_fields);
	BuildInsertParts(v_incident_fields, v_columns_sql, v_values_sql);
	
	v_sql := 'INSERT INTO ' || v_oracle_schema || '.' || v_oracle_table || ' ('|| v_columns_sql || ') VALUES (' || v_values_sql || ')';

	BindAndExecuteInsert(v_sql, v_incident_fields);
	
	-- We now have a row in the DB for the main record, and all its values are in v_incident_fields
	-- Now we need to copy the files across

	FOR r IN (
		SELECT qsq.question_id, NVL(SUBSTR(qsq.lookup_key, 1, INSTR(qsq.lookup_key, '.')-1), qsq.lookup_key) files_table,
			   qsf.qs_answer_file_id
		  FROM quick_survey_question qsq
		  JOIN qs_answer_file qsf ON qsf.survey_sid = qsq.survey_sid
								 AND qsf.survey_version = qsq.survey_version 
		 WHERE qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = v_survey_version
		   AND qsq.lookup_key IS NOT NULL
		   AND qsf.survey_response_id = in_response_id
		   AND qsq.question_type IN ('files')
	) LOOP
		BEGIN
			SELECT tab_sid
			  INTO v_files_tab_sid
			  FROM cms.tab
			 WHERE oracle_schema = v_oracle_schema
			   AND oracle_table = r.files_table;
		EXCEPTION
			WHEN no_data_found THEN
				RAISE_APPLICATION_ERROR(-20001, 'No CMS table with name ' || r.files_table);
		END;
		   
		v_file_fields := T_QS_INC_FIELD_TABLE();

		SELECT T_QS_INC_FIELD_ROW(utc.oracle_column, f.bind_type, f.text_value, f.num_value, f.date_value)
		  BULK COLLECT INTO v_file_fields
		  FROM cms.fk_cons fc
		  JOIN cms.fk_cons_col fcc ON fcc.fk_cons_id = fc.fk_cons_id
		  JOIN cms.tab_column ftc ON ftc.column_sid = fcc.column_sid
		  JOIN cms.uk_cons uc ON uc.uk_cons_id = fc.r_cons_id
		  JOIN cms.uk_cons_col ucc ON ucc.uk_cons_id = uc.uk_cons_id AND ucc.pos = fcc.pos
		  JOIN cms.tab_column utc ON utc.column_sid = ucc.column_sid
		  JOIN TABLE(v_incident_fields) f ON f.oracle_column = utc.oracle_column
		 WHERE ftc.tab_sid = v_files_tab_sid
		   AND utc.tab_sid = v_tab_sid;

		IF v_file_fields.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'CMS table ' || r.files_table || ' is not a child of CMS table ' || v_oracle_table);
		END IF;

		AddAutoColumnValues(v_files_tab_sid, v_file_fields, v_file_fields);
		BuildInsertParts(v_file_fields, v_columns_sql, v_values_sql);

		BEGIN
			SELECT oracle_column
			  INTO v_file_data_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_files_tab_sid
			   AND col_type = cms.tab_pkg.CT_FILE_DATA;

			v_columns_sql := v_columns_sql || ', ' || v_file_data_column;
			v_values_sql := v_values_sql || ', qrf.data';
		EXCEPTION
			WHEN no_data_found THEN
				RAISE_APPLICATION_ERROR(-20001, 'No file data column in CMS table ' || r.files_table);
		END;

		BEGIN
			SELECT oracle_column
			  INTO v_file_name_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_files_tab_sid
			   AND col_type = cms.tab_pkg.CT_FILE_NAME;

			v_columns_sql := v_columns_sql || ', ' || v_file_name_column;
			v_values_sql := v_values_sql || ', qrf.filename';
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;

		BEGIN
			SELECT oracle_column
			  INTO v_file_mime_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_files_tab_sid
			   AND col_type = cms.tab_pkg.CT_FILE_MIME;

			v_columns_sql := v_columns_sql || ', ' || v_file_mime_column;
			v_values_sql := v_values_sql || ', qrf.mime_type';
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
		END;

		BEGIN
			SELECT oracle_column
			  INTO v_caption_column
			  FROM cms.tab_column
			 WHERE tab_sid = v_files_tab_sid
			   AND col_type = cms.tab_pkg.CT_NORMAL
			   AND data_type = 'VARCHAR2';
		EXCEPTION
			WHEN no_data_found THEN
				NULL;
			WHEN too_many_rows THEN
				v_column_names := T_VARCHAR2_TABLE(
					'CAPTION',
					'DESCRIPTION',
					'DETAILS'
				);
		   
				FOR i IN 1 .. v_column_names.count LOOP
					BEGIN
						SELECT oracle_column
						  INTO v_caption_column
						  FROM cms.tab_column
						 WHERE tab_sid = v_files_tab_sid
						   AND col_type = cms.tab_pkg.CT_NORMAL
						   AND data_type = 'VARCHAR2'
						   AND UPPER(oracle_column) = UPPER(v_column_names(i));
					EXCEPTION
						WHEN no_data_found THEN
							NULL;
					END;
				END LOOP;
		END;

		IF v_caption_column IS NOT NULL THEN
			v_columns_sql := v_columns_sql || ', ' || v_caption_column;
			v_values_sql := v_values_sql || ', qsf.caption';
		END IF;
	
		v_sql := 'INSERT INTO ' || v_oracle_schema || '.' || r.files_table || ' ('|| v_columns_sql || ') '
			  || 'SELECT ' || v_values_sql || ' '
			  ||   'FROM qs_answer_file qsf '
			  ||   'JOIN qs_response_file qrf ON qrf.survey_response_id = qsf.survey_response_id '
			  ||							'AND qrf.sha1 = qsf.sha1 '
			  ||							'AND qrf.filename = qsf.filename '
			  ||							'AND qrf.mime_type = qsf.mime_type '
			  ||  'WHERE qsf.qs_answer_file_id = :qs_answer_file_id';

		v_file_fields.EXTEND;
		v_file_fields(v_file_fields.COUNT) := T_QS_INC_FIELD_ROW('qs_answer_file_id', 'num', NULL, r.qs_answer_file_id, NULL);

		BindAndExecuteInsert(v_sql, v_file_fields);
	END LOOP;
END;

END;
/

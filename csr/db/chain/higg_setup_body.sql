CREATE OR REPLACE PACKAGE BODY chain.higg_setup_pkg AS

PROCEDURE INTERNAL_SyncSurvey (
	in_survey_sid					IN	security.security_pkg.T_SID_ID
)
AS
BEGIN
	--Internal - security check performed in SetupModules
	UPDATE higg_question_survey hqs
	   SET qs_question_id = (
		SELECT question_id
		  FROM csr.quick_survey_question qsq
		  JOIN higg_question hq ON hq.higg_module_id || '_' || hq.higg_question_id = qsq.lookup_key
		 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
		   AND hq.higg_question_id = hqs.higg_question_id
		   AND hq.higg_question_id NOT IN (1136, 1138)
		)
	  WHERE (higg_question_id, survey_sid, survey_version) IN (
		SELECT hq.higg_question_id, in_survey_sid, 0
		  FROM csr.quick_survey_question qsq
		  JOIN higg_question hq ON hq.higg_module_id || '_' || hq.higg_question_id = qsq.lookup_key
		 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
		   AND hq.higg_question_id = hqs.higg_question_id
		   AND hq.higg_question_id NOT IN (1136, 1138)
	  );

	INSERT INTO higg_question_survey (higg_question_id, survey_sid, qs_question_id, survey_version)
	SELECT hq.higg_question_id, in_survey_sid, qsq.question_id, 0
	  FROM higg_question hq
	  JOIN csr.quick_survey_question qsq ON qsq.lookup_key = hq.higg_module_id || '_' || hq.higg_question_id
	 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
	   AND hq.higg_question_id NOT IN (
		SELECT higg_question_id
		  FROM higg_question_survey
		 WHERE survey_sid = in_survey_sid
	   )
	   AND higg_question_id NOT IN (1136, 1138);

	UPDATE higg_question_option_survey hqos
	   SET qs_question_option_id = (
		SELECT question_option_id
		  FROM csr.qs_question_option qso
		  JOIN csr.quick_survey_question qsq
			ON qsq.question_id = qso.question_id
		   AND qsq.survey_version = qso.survey_version
		  JOIN higg_question_option hqo
			ON qso.lookup_key = hqo.higg_module_id || '_' || hqo.higg_question_id || '_' || hqo.higg_question_option_id
		 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
		   AND hqo.higg_question_option_id = hqos.higg_question_option_id
		)
	 WHERE (higg_question_id, higg_question_option_id, survey_sid, survey_version) IN (
		SELECT hqo.higg_question_id, hqo.higg_question_option_id, in_survey_sid, 0
		  FROM csr.qs_question_option qso
		  JOIN csr.quick_survey_question qsq
		    ON qsq.question_id = qso.question_id
		   AND qsq.survey_version = qso.survey_version
		  JOIN higg_question_option hqo
		    ON qso.lookup_key = hqo.higg_module_id || '_' || hqo.higg_question_id || '_' || hqo.higg_question_option_id
		 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
		   AND hqo.higg_question_option_id = hqos.higg_question_option_id
	 );

	INSERT INTO higg_question_option_survey (higg_question_id, higg_question_option_id, qs_question_id,
		qs_question_option_id, survey_sid, survey_version)
	SELECT hqo.higg_question_id, hqo.higg_question_option_id, qsqo.question_id, qsqo.question_option_id, in_survey_sid, 0
	  FROM higg_question_option hqo
	  JOIN csr.qs_question_option qsqo
	    ON qsqo.lookup_key = hqo.higg_module_id || '_' || hqo.higg_question_id || '_' || hqo.higg_question_option_id
	  JOIN csr.quick_survey_question qsq ON qsq.survey_version = qsqo.survey_version AND qsq.question_id = qsqo.question_id
	 WHERE qsq.survey_sid = in_survey_sid AND qsq.survey_version = 0
	   AND (hqo.higg_question_id, hqo.higg_question_option_id) NOT IN (
		SELECT higg_question_id, higg_question_option_id
		  FROM higg_question_option_survey
		 WHERE survey_sid = in_survey_sid
	   );
END;

PROCEDURE INTERNAL_CreateHiggConfig(
	in_audit_type_id				IN	csr.internal_audit_type.internal_audit_type_id%TYPE,
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_modules						IN	security.security_pkg.T_SID_IDS,
	in_company_type_id				IN	company_type.company_type_id%TYPE,
	in_closure_type_id				IN	csr.audit_closure_type.audit_closure_type_id%TYPE,
	in_auditor_username				IN 	VARCHAR2,
	in_copy_score_on_survey_submit	IN	NUMBER,
	out_higg_config_id 				OUT NUMBER
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := security.security_pkg.GetApp;
	v_act_id					security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_audit_types 				security.security_pkg.T_SID_IDS;
	v_audit_user_sid			security.security_pkg.T_SID_ID;
	v_higg_config_id			NUMBER(10);
	v_quick_survey_type_id		csr.quick_survey_type.quick_survey_type_id%TYPE;
	v_modules					security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_modules);
	v_reference_id				reference.reference_id%TYPE;
	v_score_type_id 			higg_config_module.score_type_id%TYPE;
BEGIN
	BEGIN
		SELECT csr_user_sid
		  INTO v_audit_user_sid
		  FROM csr.csr_user
		 WHERE LOWER(user_name) = LOWER(in_auditor_username);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'User ' || in_auditor_username || ' was not found');
	END;

	BEGIN
		SELECT higg_config_id
		  INTO out_higg_config_id
		  FROM higg_config
		 WHERE app_sid = security_pkg.getapp
		   AND survey_sid = in_survey_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO higg_config(
					app_sid, higg_config_id, company_type_id, audit_type_id, survey_sid,
					closure_type_id, audit_coordinator_sid, copy_score_on_survey_submit)
			VALUES (v_app_sid, higg_config_id_seq.NEXTVAL, in_company_type_id, in_audit_type_id, in_survey_sid,
					in_closure_type_id, v_audit_user_sid, in_copy_score_on_survey_submit)
			RETURNING higg_config_id INTO out_higg_config_id;
	END;

	BEGIN
		csr.quick_survey_pkg.SaveSurveyType(
			in_quick_survey_type_id		=> NULL,
			in_description				=> 'Higg survey',
			in_enable_question_count	=> 0,
			in_show_answer_set_dtm		=> 0,
			in_oth_txt_req_for_score	=> 1,
			in_cs_class					=> 'Credit360.QuickSurvey.CalculationSurveyType',
			in_helper_pkg				=> 'chain.higg_pkg',
			out_quick_survey_type_id	=> v_quick_survey_type_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT quick_survey_type_id
			  INTO v_quick_survey_type_id
			  FROM csr.quick_survey_type
			 WHERE description = 'Higg survey'
			   AND cs_class = 'Credit360.QuickSurvey.CalculationSurveyType'
			   AND helper_pkg = 'chain.higg_pkg'
			   AND app_sid = security_pkg.getapp;
	END;

	csr.quick_survey_pkg.SetSurveyType (
		in_survey_sid					=> in_survey_sid,
		in_survey_type_id				=> v_quick_survey_type_id
	);

	BEGIN
		INSERT INTO reference (lookup_key, label, mandatory, 
			reference_uniqueness_id, reference_location_id,
			show_in_filter, reference_id, reference_validation_id)
		VALUES ('HIGGID', 'Higg ID', 0,
			 2, 0, 
			 1, reference_id_seq.NEXTVAL, chain.chain_pkg.REFERENCE_VALIDATION_NUMERIC)
		RETURNING reference_id INTO v_reference_id;

		INSERT INTO reference_company_type (reference_id, company_type_id)
		VALUES (v_reference_id, in_company_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	INTERNAL_SyncSurvey(in_survey_sid);

	FOR r IN (
		SELECT hm.higg_module_id, st.score_type_id
		  FROM higg_module hm
		  JOIN TABLE(v_modules) m ON m.column_value = hm.higg_module_id
		  JOIN csr.score_type st ON st.lookup_key = hm.score_type_lookup_key
	) LOOP
		BEGIN
			INSERT INTO higg_config_module(higg_config_id, higg_module_id, score_type_id)
			VALUES (out_higg_config_id, r.higg_module_id, r.score_type_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE higg_config_module
				   SET score_type_id = r.score_type_id
				 WHERE higg_module_id = r.higg_module_id
				   AND higg_config_id = out_higg_config_id;
		END;
	END LOOP;

	FOR r IN (
		SELECT hm.tag_group_id
		  FROM higg_module_tag_group hm
		  JOIN TABLE(v_modules) m ON m.column_value = hm.higg_module_id
	)
	LOOP
		csr.tag_pkg.SetTagGroupIATypes(r.tag_group_id, v_audit_types);
	END LOOP;
END;

PROCEDURE INTERNAL_CreateProdIndsMeas(
	in_act_id 					IN security.security_pkg.T_ACT_ID,
	in_aggr_group_name 			IN csr.aggregate_ind_group.name%TYPE,
	in_higg_root_sid			IN csr.ind.ind_sid%TYPE,
	in_higg_survey_sid			IN csr.quick_survey.survey_sid%TYPE
)
AS
	v_unit_ind 				higg_question%ROWTYPE;
	v_unit_weight_ind		higg_question%ROWTYPE;
	v_unit_length_ind 		higg_question%ROWTYPE;
	v_weight_ind 			higg_question%ROWTYPE;
	v_weight_length_ind 	higg_question%ROWTYPE;
	v_weight_weight_ind 	higg_question%ROWTYPE;

	TYPE T_HIGG_QUESTION_ARRAY IS TABLE OF higg_question%ROWTYPE;
	v_higg_question_array 	T_HIGG_QUESTION_ARRAY := T_HIGG_QUESTION_ARRAY();

	TYPE T_HIGG_QUESTION_OPT_ARRAY IS TABLE OF higg_question_option%ROWTYPE;
	v_higg_question_opt_array T_HIGG_QUESTION_OPT_ARRAY := T_HIGG_QUESTION_OPT_ARRAY();

	v_prod_weight_ounces	higg_question_option%ROWTYPE;
	v_prod_weight_tons 		higg_question_option%ROWTYPE;
	v_prod_weight_tonnes	higg_question_option%ROWTYPE;
	v_prod_length_yards		higg_question_option%ROWTYPE;

	v_weight_weight_ounces	higg_question_option%ROWTYPE;
	v_weight_weight_tons 	higg_question_option%ROWTYPE;
	v_weight_weight_tonnes	higg_question_option%ROWTYPE;
	v_weight_length_yards	higg_question_option%ROWTYPE;

	v_measure_sid 					csr.measure.measure_sid%TYPE;
	v_ind_sid 						csr.ind.ind_sid%TYPE;
	v_ind_sids 						security.security_pkg.T_SID_IDS;
	v_question_id 					csr.quick_survey_question.question_id%TYPE;
	v_question_ids					security.security_pkg.T_SID_IDS;
	v_length_measure_array			security.security_pkg.T_VARCHAR2_ARRAY;
	v_length_measure_conv_array		T_NUM_ARRAY;
	v_weight_measure_array 			security.security_pkg.T_VARCHAR2_ARRAY;
	v_weight_measure_conv_array		T_NUM_ARRAY;
	v_measure_conversion_id			csr.measure_conversion.measure_conversion_id%TYPE;
	v_changed_measures				security.security_pkg.T_OUTPUT_CUR;
BEGIN
	v_higg_question_array.EXTEND(6);

	v_unit_ind.higg_question_id 				:= 1136;
	v_unit_ind.measure_name 					:= 'unit';
	v_unit_ind.measure_lookup 					:= 'UNIT';
	v_unit_ind.measure_divisibility 			:= 1;
	v_unit_ind.std_measure_conversion_id 		:= NULL;
	v_unit_ind.indicator_name 					:= 'Annual production (units)';
	v_unit_ind.indicator_lookup					:= 'ANNUAL_PROD_UNIT';

	v_higg_question_array(1) := v_unit_ind;

	v_unit_weight_ind.higg_question_id 			:= 1137;
	v_unit_weight_ind.measure_name 				:= 'lbs';
	v_unit_weight_ind.measure_lookup 			:= 'LBS';
	v_unit_weight_ind.measure_divisibility 		:= 1;
	v_unit_weight_ind.std_measure_conversion_id := 22;
	v_unit_weight_ind.indicator_name 			:= 'Annual production (weight)';
	v_unit_weight_ind.indicator_lookup			:= 'ANNUAL_PROD_WEIGHT';
	v_unit_weight_ind.question_text 			:= 'A';

	v_higg_question_array(2) := v_unit_weight_ind;

	v_unit_length_ind.higg_question_id 			:= 1137;
	v_unit_length_ind.measure_name 				:= 'metres';
	v_unit_length_ind.measure_lookup 			:= 'METRES';
	v_unit_length_ind.measure_divisibility 		:= 1;
	v_unit_length_ind.std_measure_conversion_id := 5;
	v_unit_length_ind.indicator_name 			:= 'Annual production (length)';
	v_unit_length_ind.indicator_lookup			:= 'ANNUAL_PROD_LENGTH';
	v_unit_length_ind.question_text 			:= 'B';

	v_higg_question_array(3) := v_unit_length_ind;

	v_weight_ind.higg_question_id 				:= 1138;
	v_weight_ind.measure_name 					:= 'unit';
	v_weight_ind.measure_lookup 				:= 'UNIT';
	v_weight_ind.measure_divisibility 			:= 1;
	v_weight_ind.std_measure_conversion_id 		:= NULL;
	v_weight_ind.indicator_name 				:= 'Annual production weight (units)';
	v_weight_ind.indicator_lookup				:= 'ANNUAL_WEIGHT_UNIT';

	v_higg_question_array(4) := v_weight_ind;

	v_weight_weight_ind.higg_question_id 			:= 1139;
	v_weight_weight_ind.measure_name 				:= 'lbs';
	v_weight_weight_ind.measure_lookup 				:= 'LBS';
	v_weight_weight_ind.measure_divisibility 		:= 1;
	v_weight_weight_ind.std_measure_conversion_id 	:= 22;
	v_weight_weight_ind.indicator_name 				:= 'Annual production weight (weight)';
	v_weight_weight_ind.indicator_lookup			:= 'ANNUAL_WEIGHT_WEIGHT';
	v_weight_weight_ind.question_text 				:= 'A';

	v_higg_question_array(5) := v_weight_weight_ind;

	v_weight_length_ind.higg_question_id 			:= 1139;
	v_weight_length_ind.measure_name 				:= 'metres';
	v_weight_length_ind.measure_lookup 				:= 'METRES';
	v_weight_length_ind.measure_divisibility 		:= 1;
	v_weight_length_ind.std_measure_conversion_id 	:= 5;
	v_weight_length_ind.indicator_name 				:= 'Annual production weight (length)';
	v_weight_length_ind.indicator_lookup			:= 'ANNUAL_WEIGHT_LENGTH';
	v_weight_length_ind.question_text 				:= 'B';

	v_higg_question_array(6) := v_weight_length_ind;

	FOR i IN v_higg_question_array.FIRST .. v_higg_question_array.LAST
	LOOP
		BEGIN
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM csr.measure
			 WHERE lookup_key = v_higg_question_array(i).measure_lookup;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_measure_sid := NULL;
		END;

		IF v_measure_sid IS NULL THEN
			csr.measure_pkg.createMeasure(
				in_name						 	=> v_higg_question_array(i).measure_name,
				in_description					=> v_higg_question_array(i).measure_name,
				in_pct_ownership_applies		=> 0,
				in_divisibility					=> v_higg_question_array(i).measure_divisibility,
				in_std_measure_conversion_id	=> v_higg_question_array(i).std_measure_conversion_id,
				in_lookup_key					=> v_higg_question_array(i).measure_lookup,
				out_measure_sid					=> v_measure_sid
			);
		END IF;

		csr.aggregate_ind_pkg.SetAggregateInd(
			in_aggr_group_name		=> in_aggr_group_name,
			in_parent				=> in_higg_root_sid,
			in_desc					=> v_higg_question_array(i).indicator_name,
			in_lookup_key			=> v_higg_question_array(i).indicator_lookup || in_higg_survey_sid,
			in_name					=> v_higg_question_array(i).indicator_name,
			in_measure_sid			=> v_measure_sid,
			in_divisibility			=> v_higg_question_array(i).measure_divisibility,
			in_aggregate			=> 'SUM',
			out_ind_sid				=> v_ind_sid
		);

		SELECT question_id
		  INTO v_question_id
		  FROM csr.quick_survey_question qsq
		 WHERE qsq.survey_sid = in_higg_survey_sid AND qsq.survey_version = 0
		   AND qsq.lookup_key = ENV_MODULE || '_' || v_higg_question_array(i).higg_question_id || NVL2(v_higg_question_array(i).question_text, '_' || v_higg_question_array(i).question_text, '');

		v_ind_sids(i) := v_ind_sid;
		v_question_ids(i) := v_question_id;

		-- Create the measure for the question options
		IF v_higg_question_array(i).measure_lookup = 'LBS' THEN
			-- Add extra weight measure conversions
			v_weight_measure_array(1)		:= 'oz (troy)';
			v_weight_measure_conv_array(1)	:=	78;
			v_weight_measure_array(2)		:= 'tonne';
			v_weight_measure_conv_array(2)	:= 4;
			v_weight_measure_array(3)		:= 'oz (avoirdupois)';
			v_weight_measure_conv_array(3)	:= 77;
			v_weight_measure_array(4)		:= 'tons (short)';
			v_weight_measure_conv_array(4)	:= 40;
			v_weight_measure_array(5)		:= 'tonnes (metric)';
			v_weight_measure_conv_array(5)	:= 4;

			FOR i IN v_weight_measure_array.FIRST .. v_weight_measure_array.LAST
			LOOP
				BEGIN
					csr.measure_pkg.SetConversion(
						in_act_id						 => in_act_id,
						in_conversion_id				 => NULL,
						in_measure_sid					 => v_measure_sid,
						in_description					 => v_weight_measure_array(i),
						in_std_measure_conversion_id	 => v_weight_measure_conv_array(i),
						out_conversion_id				 => v_measure_conversion_id
					);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END LOOP;
		END IF;

		IF v_higg_question_array(i).measure_lookup = 'METRES' THEN
			-- Add extra length measure conversion
			v_length_measure_array(1)		:= 'yards';
			v_length_measure_conv_array(1)	:= 28220;

			FOR i IN v_length_measure_array.FIRST .. v_length_measure_array.LAST
			LOOP
				BEGIN
					csr.measure_pkg.SetConversion(
						in_act_id						 => in_act_id,
						in_conversion_id				 => NULL,
						in_measure_sid					 => v_measure_sid,
						in_description					 => v_length_measure_array(i),
						in_std_measure_conversion_id	 => v_length_measure_conv_array(i),
						out_conversion_id				 => v_measure_conversion_id
					);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END LOOP;
		END IF;
	END LOOP;

	v_higg_question_opt_array.EXTEND(8);

	v_prod_weight_ounces.higg_question_option_id 	:= 2487;
	v_prod_weight_ounces.higg_question_id 			:= 1137;
	v_prod_weight_ounces.measure_conversion 		:= 'oz (avoirdupois)';
	v_prod_weight_ounces.std_measure_conversion_id 	:= 77;

	v_higg_question_opt_array(1) := v_prod_weight_ounces;

	v_prod_weight_tons.higg_question_option_id 		:= 2489;
	v_prod_weight_tons.higg_question_id 			:= 1137;
	v_prod_weight_tons.measure_conversion 			:= 'tons (short)';
	v_prod_weight_tons.std_measure_conversion_id 	:= 40;

	v_higg_question_opt_array(2) := v_prod_weight_tons;

	v_prod_weight_tonnes.higg_question_option_id 	:= 2490;
	v_prod_weight_tonnes.higg_question_id 			:= 1137;
	v_prod_weight_tonnes.measure_conversion 		:= 'tonnes (metric)';
	v_prod_weight_tonnes.std_measure_conversion_id 	:= 4;

	v_higg_question_opt_array(3) := v_prod_weight_tonnes;

	v_prod_length_yards.higg_question_option_id 	:= 8313;
	v_prod_length_yards.higg_question_id 			:= 1137;
	v_prod_length_yards.measure_conversion 			:= 'yards';
	v_prod_length_yards.std_measure_conversion_id 	:= 28220;

	v_higg_question_opt_array(4) := v_prod_length_yards;

	v_weight_weight_ounces.higg_question_option_id 		:= 2492;
	v_weight_weight_ounces.higg_question_id 			:= 1139;
	v_weight_weight_ounces.measure_conversion 			:= 'oz (avoirdupois)';
	v_weight_weight_ounces.std_measure_conversion_id 	:= 77;

	v_higg_question_opt_array(5) := v_weight_weight_ounces;

	v_weight_weight_tons.higg_question_option_id 	:= 2494;
	v_weight_weight_tons.higg_question_id 			:= 1139;
	v_weight_weight_tons.measure_conversion 		:= 'tons (short)';
	v_weight_weight_tons.std_measure_conversion_id 	:= 40;

	v_higg_question_opt_array(6) := v_weight_weight_tons;

	v_weight_weight_tonnes.higg_question_option_id 		:= 2495;
	v_weight_weight_tonnes.higg_question_id 			:= 1139;
	v_weight_weight_tonnes.measure_conversion 			:= 'tonnes (metric)';
	v_weight_weight_tonnes.std_measure_conversion_id 	:= 4;

	v_higg_question_opt_array(7) := v_weight_weight_tonnes;

	v_weight_length_yards.higg_question_option_id 	:= 8315;
	v_weight_length_yards.higg_question_id 			:= 1139;
	v_weight_length_yards.measure_conversion 		:= 'yards';
	v_weight_length_yards.std_measure_conversion_id := 28220;

	v_higg_question_opt_array(8) := v_weight_length_yards;

	FOR j IN v_higg_question_opt_array.FIRST .. v_higg_question_opt_array.LAST
	LOOP
		SELECT measure_conversion_id
		  INTO v_measure_conversion_id
		  FROM csr.measure_conversion
		 WHERE std_measure_conversion_id = v_higg_question_opt_array(j).std_measure_conversion_id
		   AND description = v_higg_question_opt_array(j).measure_conversion;

		BEGIN
			INSERT INTO higg_question_opt_conversion (higg_question_id, higg_question_option_id, measure_conversion_id)
			VALUES (v_higg_question_opt_array(j).higg_question_id, v_higg_question_opt_array(j).higg_question_option_id, v_measure_conversion_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	-- This will map the indicators to the survey question
	csr.quick_survey_pkg.SetQuestionIndMappings(
		in_survey_sid			=> in_higg_survey_sid,
		in_question_ids			=> v_question_ids,
		in_ind_sids				=> v_ind_sids,
		out_changed_measures	=> v_changed_measures
	);
END;

PROCEDURE INTERNAL_CreateIndsMeas (
	in_higg_config_id 				IN 	higg_config.higg_config_id%TYPE,
	in_modules						IN	security.security_pkg.T_SID_IDS
)
AS
	v_act_id 						security.security_pkg.T_ACT_ID;
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_measure_conversion_id			csr.measure_conversion.measure_conversion_id%TYPE;
	v_measure_sid 					csr.measure.measure_sid%TYPE;
	v_ind_root_sid		 			csr.ind.ind_sid%TYPE;
	v_ind_sid 						csr.ind.ind_sid%TYPE;
	v_higg_root_sid 				csr.ind.ind_sid%TYPE;
	v_higg_survey_sid 				csr.quick_survey.survey_sid%TYPE;
	v_aggregate_ind_group_id		NUMBER(10);
	v_aggr_group_name 				csr.aggregate_ind_group.name%TYPE;
	v_energy_measure_array			security.security_pkg.T_VARCHAR2_ARRAY;
	v_energy_measure_conv_array 	T_NUM_ARRAY;
	v_weight_measure_array			security.security_pkg.T_VARCHAR2_ARRAY;
	v_weight_measure_conv_array 	T_NUM_ARRAY;
	v_root_ind_label				csr.ind.name%TYPE;
	v_higg_ind_count				NUMBER;
	v_modules						security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_modules);
	CURSOR cm IS
		SELECT m.app_sid, m.measure_sid, m.name, m.description, m.scale, m.format_mask, m.custom_field, m.pct_ownership_applies,
			   m.std_measure_conversion_id, m.divisibility, m.option_set_id, m.lookup_key
		  FROM csr.measure m
		 WHERE measure_sid = v_measure_sid;
BEGIN
	--Internal - security check performed in SetupModules
	SELECT COUNT(*)
	  INTO v_higg_ind_count
	  FROM higg_question hq
	  JOIN TABLE(v_modules) m ON m.column_value = hq.higg_module_id
	 WHERE measure_name IS NOT NULL;

	-- Only add indicators if the modules required have questions that require them
	IF v_higg_ind_count = 0 THEN
		RETURN;
	END IF;

	v_act_id  := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	SELECT hc.survey_sid, 'Higg Indicators (' || qsv.label || ')'
	  INTO v_higg_survey_sid, v_root_ind_label
	  FROM higg_config hc
	  JOIN csr.quick_survey qs ON qs.survey_sid = hc.survey_sid
	  JOIN csr.quick_survey_version qsv ON qsv.survey_sid = qs.survey_sid AND qsv.survey_version = qs.current_version
	 WHERE hc.higg_config_id = in_higg_config_id;

	v_aggr_group_name := 'Higg indicators (' || in_higg_config_id || ')';
	v_aggregate_ind_group_id := csr.aggregate_ind_pkg.SetGroup(
		in_name					=> v_aggr_group_name,
		in_helper_proc			=> 'chain.higg_pkg.GetHiggIndicatorVals'
	);

	UPDATE higg_config
	   SET aggregate_ind_group_id = v_aggregate_ind_group_id
	 WHERE higg_config_id = in_higg_config_id;

	SELECT ind_root_sid
	  INTO v_ind_root_sid
	  FROM csr.customer
	 WHERE app_sid = v_app_sid;
	BEGIN
		-- Create the root higg indicator folder
		csr.indicator_pkg.CreateIndicator(
			in_act_id			=> v_act_id,
			in_parent_sid_id	=> v_ind_root_sid,
			in_app_sid			=> v_app_sid,
			in_name				=> v_root_ind_label,
			in_description		=> v_root_ind_label,
			in_active			=> 1,
			in_lookup_key 		=> 'HIGG_ROOT_IND_' || v_higg_survey_sid,
			out_sid_id			=> v_higg_root_sid
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME then
			v_higg_root_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ind_root_sid, v_root_ind_label);
	END;

	-- Create the base measures
	FOR r IN (
		SELECT higg_question_id, measure_name, measure_lookup, measure_divisibility,
			   std_measure_conversion_id, indicator_name, indicator_lookup, units_question_id
		  FROM higg_question hq
		  JOIN TABLE(v_modules) m ON m.column_value = hq.higg_module_id
		 WHERE measure_name IS NOT NULL
		 ORDER BY higg_question_id
	) LOOP
		-- Check if it exists
		BEGIN
			SELECT measure_sid
			  INTO v_measure_sid
			  FROM csr.measure
			 WHERE lookup_key = r.measure_lookup;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_measure_sid := NULL;
		END;

		IF v_measure_sid IS NULL THEN
			csr.measure_pkg.createMeasure(
				in_name 						=> r.measure_name,
				in_description 					=> r.measure_name,
				in_pct_ownership_applies		=> 0,
				in_divisibility					=> r.measure_divisibility,
				in_std_measure_conversion_id 	=> r.std_measure_conversion_id,
				in_lookup_key 					=> r.measure_lookup,
				out_measure_sid					=> v_measure_sid
			);
		END IF;

		-- Create extra energy measure conversions for other standards
		IF r.measure_lookup = 'KWH' THEN
			v_energy_measure_array(1) 			:= 'BTU (US)';
			v_energy_measure_conv_array(1)	 	:=	47;
			v_energy_measure_array(2) 			:= 'BTU (EC)';
			v_energy_measure_conv_array(2) 		:= 48;
			v_energy_measure_array(3) 			:= 'MMBTU (US)';
			v_energy_measure_conv_array(3)	 	:= 45;
			v_energy_measure_array(4) 			:= 'MMBTU (EC)';
			v_energy_measure_conv_array(4) 		:= 46;
			v_energy_measure_array(5)			:= 'Therm (US)';
			v_energy_measure_conv_array(5)		:= 41;
			v_energy_measure_array(6)			:= 'Therm (EC)';
			v_energy_measure_conv_array(6)		:= 42;

			FOR i IN v_energy_measure_array.FIRST .. v_energy_measure_array.LAST
			LOOP
				BEGIN
					csr.measure_pkg.SetConversion(
						in_act_id						=> v_act_id,
						in_conversion_id 				=> NULL,
						in_measure_sid 					=> v_measure_sid,
						in_description 					=> v_energy_measure_array(i),
						in_std_measure_conversion_id 	=> v_energy_measure_conv_array(i),
						out_conversion_id 				=> v_measure_conversion_id
					);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END LOOP;
		END IF;

		IF r.measure_lookup = 'LBS' THEN
			-- Add extra weight measure conversions
			v_weight_measure_array(1)		:= 'oz (troy)';
			v_weight_measure_conv_array(1)	:=	78;
			v_weight_measure_array(2)		:= 'tonne';
			v_weight_measure_conv_array(2) 	:= 4;


			FOR i IN v_weight_measure_array.FIRST .. v_weight_measure_array.LAST
			LOOP
				BEGIN
					csr.measure_pkg.SetConversion(
						in_act_id						=> v_act_id,
						in_conversion_id 				=> NULL,
						in_measure_sid 					=> v_measure_sid,
						in_description 					=> v_weight_measure_array(i),
						in_std_measure_conversion_id 	=> v_weight_measure_conv_array(i),
						out_conversion_id 				=> v_measure_conversion_id
					);
				EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						NULL;
				END;
			END LOOP;
		END IF;

		-- Create a new indicator for each survey and use the survey sid in the lookup key
		csr.aggregate_ind_pkg.SetAggregateInd(
			in_aggr_group_name		=> v_aggr_group_name,
			in_parent				=> v_higg_root_sid,
			in_desc					=> r.indicator_name,
			in_lookup_key			=> r.indicator_lookup || v_higg_survey_sid,
			in_name					=> r.indicator_name,
			in_measure_sid			=> v_measure_sid,
			in_divisibility			=> r.measure_divisibility,
			in_aggregate			=> 'SUM',
			out_ind_sid				=> v_ind_sid
		);

		-- Create the measure for the question options
		FOR s IN (
			SELECT higg_question_option_id, measure_conversion, std_measure_conversion_id
			  FROM higg_question_option
			 WHERE higg_question_id = r.units_question_id
			   AND measure_conversion IS NOT NULL
			   AND std_measure_conversion_id IS NOT NULL
		) LOOP
			IF s.std_measure_conversion_id = r.std_measure_conversion_id THEN
				-- If the option corresponds to the base measure, we don't need a measure conversion
				v_measure_conversion_id := NULL;
			ELSE
				BEGIN
					SELECT measure_conversion_id
					  INTO v_measure_conversion_id
					  FROM csr.measure_conversion
					 WHERE measure_sid = v_measure_sid
					   AND description = s.measure_conversion;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						csr.measure_pkg.SetConversion(
							in_act_id						=> v_act_id,
							in_conversion_id 				=> NULL,
							in_measure_sid 					=> v_measure_sid,
							in_description 					=> s.measure_conversion,
							in_std_measure_conversion_id 	=> s.std_measure_conversion_id,
							out_conversion_id 				=> v_measure_conversion_id
						);
				END;
			END IF;

			BEGIN
				INSERT INTO higg_question_opt_conversion (higg_question_id, higg_question_option_id, measure_conversion_id)
				VALUES (r.units_question_id, s.higg_question_option_id, v_measure_conversion_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
		END LOOP;
	END LOOP;

	FOR i IN v_modules.FIRST .. v_modules.LAST
	LOOP
		IF v_modules(i) = ENV_MODULE THEN
			INTERNAL_CreateProdIndsMeas(v_act_id, v_aggr_group_name, v_higg_root_sid, v_higg_survey_sid);
		END IF;
	END LOOP;
END;

PROCEDURE INTERNAL_SyncHiggIndicators (
	in_higg_config_id				IN	higg_config.higg_config_id%TYPE,
	in_modules						IN	security.security_pkg.T_SID_IDS
)
AS
	v_ind_sids						security.security_pkg.T_SID_IDS;
	v_question_ids					security.security_pkg.T_SID_IDS;
	v_survey_sid					security.security_pkg.T_SID_ID;
	v_changed_measures				security.security_pkg.T_OUTPUT_CUR;
	v_update_responses_from			csr.quick_survey_version.survey_version%TYPE;
	v_publish_result				security.security_pkg.T_OUTPUT_CUR;
	v_app_sid 						security.security_pkg.T_SID_ID;
	v_higg_ind_count				NUMBER;
	v_modules						security.T_SID_TABLE := security.security_pkg.SidArrayToTable(in_modules);
BEGIN
	--Internal - security check performed in SetupModules
	SELECT COUNT(*)
	  INTO v_higg_ind_count
	  FROM higg_question hq
	  JOIN TABLE(v_modules) m ON m.column_value = hq.higg_module_id
	 WHERE indicator_name IS NOT NULL;

	-- Only add indicators if the modules required have questions that require them
	IF v_higg_ind_count = 0 THEN
		RETURN;
	END IF;

	v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

	SELECT hc.survey_sid
	  INTO v_survey_sid
	  FROM higg_config hc
	 WHERE hc.higg_config_id = in_higg_config_id;

	FOR r IN (
		SELECT i.ind_sid, hqs.qs_question_id, rownum rn
		  FROM higg_question hq
		  JOIN TABLE(v_modules) m ON m.column_value = hq.higg_module_id
		  JOIN higg_question_survey hqs ON hqs.higg_question_id = hq.higg_question_id
		  JOIN csr.ind i ON i.lookup_key = hq.indicator_lookup || v_survey_sid
		 WHERE hq.indicator_name IS NOT NULL
		   AND hqs.survey_sid = v_survey_sid
	)
	LOOP
		v_ind_sids(r.rn) := r.ind_sid;
		v_question_ids(r.rn) := r.qs_question_id;
	END LOOP;

	csr.quick_survey_pkg.SetQuestionIndMappings(
		in_survey_sid				=> v_survey_sid,
		in_question_ids				=> v_question_ids,
		in_ind_sids					=> v_ind_sids,
		out_changed_measures		=> v_changed_measures
	);

	csr.quick_survey_pkg.PublishSurvey(
		in_survey_sid				=> v_survey_sid,
		in_update_responses_from	=> v_update_responses_from,
		out_publish_result			=> v_publish_result
	);
END;

PROCEDURE SetupModules (
	in_higg_config_id 				IN  higg_config.higg_config_id%TYPE,
	in_audit_type_id				IN	csr.internal_audit_type.internal_audit_type_id%TYPE,
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_modules						IN	security.security_pkg.T_SID_IDS,
	in_company_type_id				IN	company_type.company_type_id%TYPE,
	in_closure_type_id				IN	csr.audit_closure_type.audit_closure_type_id%TYPE,
	in_auditor_username				IN	VARCHAR2,
	in_copy_score_on_survey_submit	IN	NUMBER,
	out_higg_config_id				OUT	higg_config.higg_config_id%TYPE
)
AS
	v_higg_config_id				NUMBER(10);
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SetupModules');
	END IF;

	INTERNAL_CreateHiggConfig(
		in_survey_sid				=> in_survey_sid,
		in_audit_type_id			=> in_audit_type_id,
		in_modules					=> in_modules,
		in_company_type_id			=> in_company_type_id,
		in_closure_type_id			=> in_closure_type_id,
		in_auditor_username			=> in_auditor_username,
		in_copy_score_on_survey_submit	=> in_copy_score_on_survey_submit,
		out_higg_config_id 			=> v_higg_config_id
	);

	IF in_higg_config_id = 0 THEN
		INTERNAL_CreateIndsMeas(
			in_higg_config_id			=> v_higg_config_id,
			in_modules					=> in_modules
		);

		INTERNAL_SyncHiggIndicators(
			in_higg_config_id			=> v_higg_config_id,
			in_modules					=> in_modules
		);
	END IF;

	out_higg_config_id := v_higg_config_id;
END;

PROCEDURE GetHiggModules (
	out_higg_modules				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run GetHiggModules');
	END IF;

	OPEN out_higg_modules FOR
		SELECT higg_module_id id, module_name name
		  FROM higg_module;
END;

PROCEDURE GetAvailableSurveys (
	out_surveys_cur					OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run GetHiggModules');
	END IF;

	-- This is a superadmin setup operation, so don't worry about access permissions to surveys
	OPEN out_surveys_cur FOR
		SELECT qs.survey_sid, qsv.label, CASE WHEN hc.higg_config_id IS NOT NULL THEN 1 ELSE 0 END is_in_use
		  FROM csr.quick_survey qs
		  JOIN csr.quick_survey_version qsv ON qsv.survey_version = qs.current_version AND qsv.survey_sid = qs.survey_sid
		  LEFT JOIN higg_config hc ON hc.survey_sid = qs.survey_sid
		 WHERE qs.audience = 'audit';
END;

PROCEDURE GetHiggConfigurations (
	out_higg_config_cur				OUT	security.security_pkg.T_OUTPUT_CUR,
	out_higg_config_modules			OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run GetHiggModules');
	END IF;

	OPEN out_higg_config_cur FOR
		SELECT hc.higg_config_id, hc.audit_type_id internal_audit_type_id, hc.survey_sid,
			hc.closure_type_id audit_closure_type_id, u.user_name audit_coordinator,
			hc.copy_score_on_survey_submit, hc.company_type_id
		  FROM higg_config hc
		  JOIN csr.csr_user u ON u.csr_user_sid = hc.audit_coordinator_sid
		 WHERE hc.app_sid = security.security_pkg.GetApp;

	OPEN out_higg_config_modules FOR
		SELECT higg_config_id, higg_module_id
		  FROM higg_config_module
		 WHERE app_sid = security.security_pkg.GetApp;
END;

FUNCTION IsHiggEnabled
RETURN NUMBER
AS
	v_count					NUMBER(10);
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run IsHiggEnabled');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM higg
	 WHERE app_sid = security.security_pkg.GetApp;

	IF v_count > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE SyncHiggSurvey (
	in_higg_config_id				IN higg_config.higg_config_id%TYPE
)
AS
	v_survey_sid					security.security_pkg.T_SID_ID;
BEGIN
	IF csr.csr_user_pkg.IsSuperAdmin != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can run SyncHiggSurvey');
	END IF;

	SELECT survey_sid
	  INTO v_survey_sid
	  FROM higg_config
	 WHERE higg_config_id = in_higg_config_id;

	INTERNAL_SyncSurvey(v_survey_sid);
END;

END;
/

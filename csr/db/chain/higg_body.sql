CREATE OR REPLACE PACKAGE BODY chain.higg_pkg AS

PROCEDURE GetUnprocessedHiggProfiles (
	out_cur							OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in administrators can run GetUnprocessedHiggProfiles');
	END IF;

	OPEN out_cur FOR
		WITH module_response AS (
			SELECT hp.higg_profile_id, hp.response_year, hc.higg_config_id, LISTAGG(htg.tag_id, ',') WITHIN GROUP (ORDER BY htg.tag_id) tags,
				   COUNT(hcm.higg_module_id) module_count, COUNT(hr.higg_response_id) response_count, MAX(hr.last_updated_dtm) last_updated_dtm
			  FROM higg_config hc
			  JOIN higg_config_module hcm ON hc.higg_config_id = hcm.higg_config_id
			  JOIN higg_module hm ON hcm.higg_module_id = hm.higg_module_id
			  JOIN higg_module_tag_group hmtg ON hmtg.higg_module_id = hm.higg_module_id
			  CROSS JOIN higg_profile hp
			  LEFT JOIN v$higg_response hr ON hr.higg_profile_id = hp.higg_profile_id AND hr.response_year = hp.response_year AND hr.higg_module_id = hm.higg_module_id
			  LEFT JOIN (
				 SELECT tg.tag_group_id, t.lookup_key, t.tag_id
				   FROM csr.tag_group tg
				   JOIN csr.tag_group_member tgm ON tgm.tag_group_id = tg.tag_group_id
				   JOIN csr.tag t ON t.tag_id = tgm.tag_id
				) htg ON htg.tag_group_id = hmtg.tag_group_id AND LOWER(htg.lookup_key) = LOWER(hr.verification_status)
			 GROUP BY hp.higg_profile_id, hp.response_year, hc.higg_config_id
		)
		SELECT mr.higg_profile_id, mr.response_year, s.region_sid, hc.audit_type_id, mr.last_updated_dtm, c.name company_name, hc.closure_type_id,
			mr.tags, hc.audit_coordinator_sid, hc.survey_sid, CASE WHEN ia.deleted = 0 THEN ia.internal_audit_sid ELSE NULL END internal_audit_sid,
			ia.audit_dtm, ia.survey_response_id, mr.higg_config_id
		  FROM v$company_reference cr
		  JOIN company c ON c.company_sid = cr.company_sid
		  JOIN csr.supplier s ON c.company_sid = s.company_sid
		  JOIN module_response mr ON mr.higg_profile_id = cr.value
		  JOIN higg_config hc
		    ON hc.higg_config_id = mr.higg_config_id
		   AND (hc.company_type_id IS NULL OR hc.company_type_id = c.company_type_id)
		  LEFT JOIN higg_config_profile hcp
		    ON hcp.higg_profile_id = mr.higg_profile_id
		   AND hcp.response_year = mr.response_year
		   AND hcp.higg_config_id = mr.higg_config_id
		  LEFT JOIN csr.internal_audit ia ON ia.internal_audit_sid = hcp.internal_audit_sid
		 WHERE cr.lookup_key LIKE HIGG_REFERENCE_FIELD || '%'
		   AND mr.module_count = mr.response_count
		   AND (hcp.internal_audit_sid IS NULL OR ia.deleted = 1 OR ia.audit_dtm < mr.last_updated_dtm);
END;

PROCEDURE UpdateAuditDtm(
	in_audit_sid 		csr.internal_audit.internal_audit_sid%TYPE,
	in_audit_dtm 		csr.internal_audit.audit_dtm%TYPE
)
AS
	v_old_dtm			csr.internal_audit.audit_dtm%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in administrators can run UpdateAuditDtm');
	END IF;

	SELECT audit_dtm
	  INTO v_old_dtm
	  FROM csr.internal_audit
	 WHERE internal_audit_sid = in_audit_sid;

	UPDATE csr.internal_audit
	   SET audit_dtm = in_audit_dtm
	 WHERE internal_audit_sid = in_audit_sid;

	csr.csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr.csr_data_pkg.AUDIT_TYPE_INTERNAL_AUDIT, SYS_CONTEXT('SECURITY', 'APP'),
		in_audit_sid, 'Audit date', v_old_dtm, in_audit_dtm);
END;

PROCEDURE SaveAnswersForProdQuestions(
	in_higg_profile_id		IN higg_profile.higg_profile_id%TYPE,
	in_response_year 		IN higg_response.response_year%TYPE,
	in_higg_config_id		IN higg_config.higg_config_id%TYPE,
	in_higg_response_guid	IN csr.quick_survey_response.guid%TYPE,
	in_higg_survey_version	IN csr.quick_survey_response.survey_version%TYPE,
	in_higg_survey_sid		IN security.security_pkg.T_SID_ID
)
AS
	v_module_id 		higg_config_module.higg_module_id%TYPE;
	v_question_lookup 	csr.quick_survey_question.lookup_key%TYPE;
	v_question_id 		csr.quick_survey_question.question_id%TYPE;
	v_num_answer		csr.quick_survey_answer.val_number%TYPE;
BEGIN
	SELECT higg_module_id
	  INTO v_module_id
	  FROM higg_config_module
	 WHERE higg_config_id = in_higg_config_id;

	-- This is only for questions mapped to the environmental module
	IF v_module_id <> higg_setup_pkg.ENV_MODULE THEN
		RETURN;
	END IF;

	FOR r IN (
		SELECT hqr.higg_question_id parent_question_id, hqo.higg_question_option_id, hqoc.measure_conversion_id, chq.higg_question_id,
			   CASE
					WHEN INSTR(hqr.answer, '|') = 0 THEN hqr.answer
					ELSE SUBSTR(hqr.answer, 1, INSTR(hqr.answer, '|') - 1)
			   END answer
		  FROM v$higg_response hr
		  JOIN higg_question_response hqr ON hqr.higg_response_id = hr.higg_response_id
		  JOIN higg_question hq ON hqr.higg_question_id = hq.higg_question_id
		  JOIN higg_question chq ON hq.units_question_id = chq.higg_question_id
		  JOIN higg_question_response cqr ON hqr.higg_response_id = cqr.higg_response_id AND cqr.higg_question_id = chq.higg_question_id
	 LEFT JOIN higg_question_option hqo ON cqr.option_id = hqo.higg_question_option_id
	 LEFT JOIN higg_question_opt_conversion hqoc ON cqr.higg_question_id = hqoc.higg_question_id AND cqr.option_id = hqoc.higg_question_option_id
		 WHERE hr.response_year = in_response_year
		   AND hr.higg_profile_id = in_higg_profile_id
		   AND hqr.higg_question_id IN (1136, 1138)
	) LOOP
		v_num_answer := NULL;
		IF r.answer IS NOT NULL THEN
			BEGIN
				v_num_answer := TO_NUMBER(r.answer);
			EXCEPTION
				WHEN VALUE_ERROR THEN
					NULL;
			END;
		END IF;

		v_question_lookup := higg_setup_pkg.ENV_MODULE || '_' || r.higg_question_id;

		IF r.higg_question_option_id IN (HIGG_PROD_OZ_OPT_ID, HIGG_PROD_LBS_OPT_ID, HIGG_PROD_TONS_OPT_ID, HIGG_PROD_TONNES_OPT_ID,
										 HIGG_WEIGHT_OZ_OPT_ID, HIGG_WEIGHT_LBS_OPT_ID, HIGG_WEIGHT_TONS_OPT_ID, HIGG_WEIGHT_TONNES_OPT_ID) THEN
			v_question_lookup := v_question_lookup || '_A';
		ELSIF r.higg_question_option_id IN (HIGG_PROD_YARDS_OPT_ID, HIGG_PROD_METRES_OPT_ID, HIGG_WEIGHT_YARDS_OPT_ID, HIGG_WEIGHT_METRES_OPT_ID) THEN
			v_question_lookup := v_question_lookup || '_B';
		ELSE
			v_question_lookup := higg_setup_pkg.ENV_MODULE || '_' || r.parent_question_id;
		END IF;

		SELECT question_id
		  INTO v_question_id
		  FROM csr.quick_survey_question
		 WHERE lookup_key = v_question_lookup
		   AND survey_version = in_higg_survey_version
		   AND survey_sid = in_higg_survey_sid;

		csr.quick_survey_pkg.SetAnswerForResponseGuid(
			in_guid							=>	in_higg_response_guid,
			in_question_id					=>	v_question_id,
			in_answer						=>	NULL,
			in_val_number					=>	v_num_answer,
			in_question_option_id			=>	NULL,
			in_score						=>	NULL,
			in_max_score					=>	NULL,
			in_measure_conversion_id		=>	r.measure_conversion_id
		);
	END LOOP;
END;

PROCEDURE SaveHiggAnswers (
	in_survey_response_id			IN	csr.quick_survey_response.survey_response_id%TYPE,
	in_higg_profile_id				IN	higg_profile.higg_profile_id%TYPE,
	in_response_year 				IN	higg_response.response_year%TYPE,
	in_higg_config_id				IN	higg_config.higg_config_id%TYPE
)
AS
	v_higg_survey_version			csr.quick_survey_response.survey_version%TYPE;
	v_higg_survey_sid				security.security_pkg.T_SID_ID;
	v_higg_response_guid			csr.quick_survey_response.guid%TYPE;
	v_num_answer					csr.quick_survey_answer.val_number%TYPE;
	v_audit_sid						security.security_pkg.T_SID_ID;
	v_measure_conversion_id			csr.measure_conversion.measure_conversion_id%TYPE;
	v_answer						csr.quick_survey_answer.answer%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in administrators can run SaveHiggAnswers');
	END IF;

	SELECT survey_version, survey_sid, guid
	  INTO v_higg_survey_version, v_higg_survey_sid, v_higg_response_guid
	  FROM csr.quick_survey_response
	 WHERE survey_response_id = in_survey_response_id;

	FOR r IN (
		/*	This query gets question responses from the SAC import data mapped to the corresponding quick survey questions/question options,
			including the scores for each question. TODO: document how SAC questions are mapped to quick survey questions.

			Scoring: we need to set scores for radio buttons, checkbox and checkbox group questions. When calling quick_survey_pkg.Submit, the scores are aggregated
			up to the parent checkboxgroup/section questions only if both score and max score have been set for the subquestions and max score is
			more than 0. For radio buttons, we calculate the maximum score to be the largest score of any of its options, or 0 if that's negative.
			For checkboxes, the max score is set to be the same as the score. For checkbox group questions, we set the max score to be the sum of all
			of it's child checkboxes where the score is non-negative. If max_score is set on the question itself, quick_survey_pkg.Submit takes care
			of using the minimum between that and the max_score we provide here.
		*/
		WITH checkbox AS (
			SELECT qsq.question_id, CASE WHEN higg.option_value = 'Yes' THEN '1' ELSE '0' END answer, NULL question_option_id,
				   CASE WHEN INSTR(higg.answer, '|') = 0 THEN NULL ELSE SUBSTR(higg.answer, INSTR(higg.answer, '|') + 1, LENGTH(higg.answer) - INSTR(higg.answer, '|')) END additional_text,
				   CASE WHEN higg.option_value = 'Yes' THEN qsq.score WHEN qsq.score IS NOT NULL THEN 0 ELSE NULL END score, CASE WHEN qsq.score < 0 THEN 0 ELSE qsq.score END max_score, qsq.parent_id,
				   qsp.max_score group_max_score, qsq.parent_version
				  FROM csr.quick_survey_question qsp
				  JOIN csr.quick_survey_question qsq ON qsq.survey_version = qsp.survey_version AND qsp.question_id = qsq.parent_id
				  LEFT JOIN (
					SELECT hqs.qs_question_id, cb.question_type, par.question_type parent_question_type, hqo.option_value, hr.response_year, hr.higg_profile_id, hqr.answer
					  FROM v$higg_response hr
					  JOIN higg_question_response hqr ON hqr.higg_response_id = hr.higg_response_id
					  JOIN higg_question cb ON cb.higg_question_id = hqr.higg_question_id
					  JOIN higg_question_survey hqs ON hqs.higg_question_id = cb.higg_question_id AND hqs.survey_sid = v_higg_survey_sid
					  JOIN higg_question par ON par.higg_question_id = cb.parent_question_id
					  JOIN higg_question_option hqo ON hqo.higg_question_option_id = hqr.option_id AND hqo.higg_question_id = hqr.higg_question_id
					 WHERE hr.higg_profile_id = in_higg_profile_id
					   AND hr.response_year = in_response_year
					   AND ((LOWER(par.question_type) = 'single-choice-grid' AND LOWER(cb.question_type) = 'single') OR LOWER(cb.question_type) IN ('boolean-choice', 'multiple-choice-option'))
					) higg ON qsq.question_id = higg.qs_question_id
			 WHERE LOWER(qsq.question_type) = 'checkbox'
			   AND LOWER(qsp.question_type) = 'checkboxgroup'
			   AND qsq.survey_sid = v_higg_survey_sid
			   AND qsq.survey_version = v_higg_survey_version
		)
		SELECT qsq.question_id, qsq.question_type, qsqt.answer_type,
			CASE
				WHEN INSTR(hqr.answer, '|') = 0 THEN hqr.answer
				ELSE SUBSTR(hqr.answer, 1, INSTR(hqr.answer, '|') - 1)
			END answer, NULL question_option_id, NULL additional_text, NULL score, NULL max_score,
			hq.units_question_id, ur.option_id units_option_id
		  FROM v$higg_response hr
		  JOIN higg_question_response hqr ON hqr.higg_response_id = hr.higg_response_id
		  JOIN higg_question hq ON hq.higg_question_id = hqr.higg_question_id
		  LEFT JOIN (
			SELECT uhr.higg_response_id, uhr.response_year, uhqr.higg_question_id, uhqr.option_id
			  FROM v$higg_response uhr
			  JOIN higg_question_response uhqr ON uhqr.higg_response_id = uhr.higg_response_id
		  ) ur ON ur.higg_response_id = hr.higg_response_id AND ur.response_year = hr.response_year AND ur.higg_question_id = hq.units_question_id
		  JOIN higg_question_survey hqs ON hqs.higg_question_id = hq.higg_question_id AND hqs.survey_sid = v_higg_survey_sid
		  JOIN csr.quick_survey_question qsq ON qsq.question_id = hqs.qs_question_id
		  JOIN csr.question_type qsqt ON qsqt.question_type = qsq.question_type
		 WHERE qsq.survey_sid = v_higg_survey_sid
		   AND qsq.survey_version = v_higg_survey_version
		   AND LOWER(hq.question_type) in ('string', 'text-response', 'file-field')
		   AND hr.higg_profile_id = in_higg_profile_id
		   AND hr.response_year = in_response_year
		 UNION
		SELECT qsq.question_id, qsq.question_type, qsqt.answer_type, NULL, qo.question_option_id,
			   CASE WHEN INSTR(sac.answer, '|') = 0 THEN NULL ELSE SUBSTR(sac.answer, INSTR(sac.answer, '|') + 1, LENGTH(sac.answer) - INSTR(sac.answer, '|')) END,
			   CASE WHEN qso_max.max_score IS NULL THEN NULL ELSE NVL(qo.score, 0) END score, qso_max.max_score, NULL, NULL
		  FROM csr.quick_survey_question qsq
		  JOIN csr.question_type qsqt ON qsqt.question_type = qsq.question_type
		  LEFT JOIN (
			SELECT MAX(qso.score) max_score, qsq.question_id
			  FROM csr.qs_question_option qso
			  JOIN csr.quick_survey_question qsq
			    ON qsq.question_id = qso.question_id
			   AND qsq.survey_version = qso.survey_version
			 WHERE qsq.survey_sid = v_higg_survey_sid
			   AND qsq.survey_version = v_higg_survey_version
			   AND qso.score >= 0
			 GROUP BY qsq.question_id
		  ) qso_max ON qsq.question_id = qso_max.question_id
		  LEFT JOIN (
			SELECT q.qs_question_id, q.qs_question_option_id, hqr.answer
			  FROM v$higg_response hr
			  JOIN higg_question_response hqr ON hqr.higg_response_id = hr.higg_response_id
			  JOIN (
				SELECT hq.higg_question_id, hq.question_type, hq.question_text, hqs.qs_question_id,
					   hqo.option_value, hqos.qs_question_option_id, hqo.higg_question_option_id
				  FROM higg_question hq
				  JOIN higg_question_option hqo ON hqo.higg_question_id = hq.higg_question_id
				  JOIN higg_question_survey hqs ON hqs.higg_question_id = hq.higg_question_id AND hqs.survey_sid = v_higg_survey_sid
				  JOIN higg_question_option_survey hqos ON hqos.higg_question_id = hqo.higg_question_id AND hqos.higg_question_option_id = hqo.higg_question_option_id AND hqos.survey_sid = v_higg_survey_sid
			  ) q ON q.higg_question_id = hqr.higg_question_id AND hqr.option_id = q.higg_question_option_id
			 WHERE hr.higg_profile_id = in_higg_profile_id
			   AND hr.response_year = in_response_year
			   AND LOWER(q.question_type) IN ('dropdown', 'single-choice', 'boolean-choice', 'single', 'dropdown-choice', 'multiple-choice-option')
		  ) sac ON qsq.question_id = sac.qs_question_id
		  LEFT JOIN csr.qs_question_option qo
			ON qo.question_id = qsq.question_id
		   AND qo.survey_version = qsq.survey_version
		   AND qo.question_option_id = sac.qs_question_option_id
		 WHERE qsq.survey_sid = v_higg_survey_sid
		   AND qsq.survey_version = v_higg_survey_version
		   AND qsq.question_type = 'radio'
		 UNION
		SELECT question_id, 'checkbox', 'val', answer, question_option_id, additional_text, score, max_score, NULL, NULL
		  FROM checkbox
		 UNION
		SELECT parent_id, 'checkboxgroup', NULL, NULL, NULL, NULL, SUM(score), NVL(group_max_score, SUM(max_score)), NULL, NULL
		  FROM checkbox
		 GROUP BY parent_id, group_max_score
 	)
	LOOP
		v_num_answer := NULL;
		v_answer := r.answer;

		-- By default, we don't need a measure conversion
		v_measure_conversion_id := NULL;
		IF r.units_question_id IS NOT NULL THEN
			BEGIN
				-- If the question requires a unit, try to map the selected unit to a measure
				-- conversion
				SELECT measure_conversion_id
				  INTO v_measure_conversion_id
				  FROM higg_question_opt_conversion
				 WHERE higg_question_id = r.units_question_id AND higg_question_option_id = r.units_option_id
				   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- If we can't map the unit to a measure conversion (either no unit was specified or the
					-- mapping hasn't been set up), the value is meaningless so blank it. The exception is if
					-- the unit corresponding to the base unit of the measure is selected, in which case we
					-- don't need to provide a measure conversion.
					v_answer := NULL;
			END;
		END IF;

		IF v_answer IS NOT NULL THEN
			BEGIN
				v_num_answer := TO_NUMBER(v_answer);
			EXCEPTION
				WHEN VALUE_ERROR THEN
					NULL;
			END;
		END IF;

		-- could possibly do this in one big upsert if performance is an issue
		csr.quick_survey_pkg.SetAnswerForResponseGuid(
			in_guid							=>	v_higg_response_guid,
			in_question_id					=>	r.question_id,
			in_answer						=>	CASE
													WHEN r.question_type = 'checkbox' THEN r.additional_text
													WHEN r.answer_type = 'val' THEN NULL
													ELSE v_answer
												END,
			in_val_number					=>	CASE
													WHEN r.answer_type = 'val' THEN v_num_answer
													ELSE NULL
												END,
			in_question_option_id			=>	r.question_option_id,
			in_score						=>	CASE WHEN r.score > r.max_score THEN r.max_score ELSE r.score END,
			in_max_score					=>	r.max_score,
			in_measure_conversion_id		=>	v_measure_conversion_id
		);
	END LOOP;

	SaveAnswersForProdQuestions(
		in_higg_profile_id		=> in_higg_profile_id,
		in_response_year 		=> in_response_year,
		in_higg_config_id		=> in_higg_config_id,
		in_higg_response_guid	=> v_higg_response_guid,
		in_higg_survey_version	=> v_higg_survey_version,
		in_higg_survey_sid		=> v_higg_survey_sid
	);

	SELECT internal_audit_sid
	  INTO v_audit_sid
	  FROM csr.internal_audit
	 WHERE survey_response_id = in_survey_response_id;

	BEGIN
		INSERT INTO higg_config_profile (higg_config_id, higg_profile_id, response_year, internal_audit_sid)
		VALUES (in_higg_config_id, in_higg_profile_id, in_response_year, v_audit_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE higg_config_profile
			   SET internal_audit_sid = v_audit_sid
			 WHERE higg_config_id = in_higg_config_id
			   AND higg_profile_id = in_higg_profile_id
			   AND response_year = in_response_year;
	END;
END;

PROCEDURE GetHiggResponseYrTag(
	in_higg_config_id 				IN	higg_config.higg_config_id%TYPE,
	in_response_year 				IN	higg_response.response_year%TYPE,
	out_resp_year_tag_id			OUT	csr.tag.tag_id%TYPE
)
AS
	v_resp_year_tag_group_id			csr.tag_group.tag_group_id%TYPE;
BEGIN
	BEGIN
		SELECT hmtg.tag_group_id
		  INTO v_resp_year_tag_group_id
		  FROM higg_config_module hcm
		  JOIN higg_module_tag_group hmtg ON hcm.higg_module_id = hmtg.higg_module_id
		  JOIN csr.tag_group tg ON hmtg.tag_group_id = tg.tag_group_id
		 WHERE higg_config_id = in_higg_config_id
		   AND UPPER(tg.lookup_key) = chain.higg_pkg.HIGG_RESPONSE_YR_LOOKUP_KEY;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- no response year tag group
			RETURN;
	END;

	csr.tag_pkg.SetTag(
		in_tag_group_id		=> v_resp_year_tag_group_id,
		in_tag				=> in_response_year,
		in_lookup_key		=> in_response_year,
		out_tag_id			=> out_resp_year_tag_id
	);
END;

PROCEDURE GetHiggIndicatorVals (
	in_aggregate_ind_group_id		IN	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm					IN	DATE,
	in_end_dtm						IN	DATE,
	out_cur							OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in administrators can run GetHiggIndicatorVals');
	END IF;

	DELETE FROM csr.temp_response_region;

	INSERT INTO csr.temp_response_region(response_id, region_sid, submission_id, period_start_dtm, period_end_dtm)
	SELECT survey_response_id, region_sid, last_submission_id, TO_DATE(response_year || '-01-01', 'YYYY-MM-DD'), TO_DATE((response_year + 1) || '-01-01', 'YYYY-MM-DD')
	  FROM (
		SELECT qsr.survey_response_id, ia.region_sid, qsr.last_submission_id, hcp.response_year,
			ROW_NUMBER() OVER (PARTITION BY ia.region_sid, hcp.response_year ORDER BY ia.audit_dtm DESC) rn
		  FROM higg_config hc
		  JOIN csr.internal_audit ia ON ia.internal_audit_type_id = hc.audit_type_id
		  JOIN csr.quick_survey_response qsr ON ia.survey_response_id = qsr.survey_response_id AND qsr.survey_sid = hc.survey_sid
		  JOIN higg_config_profile hcp ON hcp.internal_audit_sid = ia.internal_audit_sid
		 WHERE hc.aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND NOT (TO_DATE((hcp.response_year + 1) || '-01-01', 'YYYY-MM-DD') <= in_start_dtm OR TO_DATE(hcp.response_year || '-01-01', 'YYYY-MM-DD') >= in_end_dtm)
		   AND ia.deleted = 0
		   AND qsr.last_submission_id IS NOT NULL
	  )
	 WHERE rn = 1;

	csr.quick_survey_pkg.GetScoreIndVals(out_cur);
END;

PROCEDURE OnSurveySubmitted (
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_response_id					IN	security.security_pkg.T_SID_ID,
	in_submission_id				IN	security.security_pkg.T_SID_ID
)
AS
	v_agg_ind_group_id				csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_response_year					NUMBER;
	v_start_dtm						DATE;
	v_end_dtm						DATE;
BEGIN
	-- Only called by survey type helper so assume security checks have already been
	-- performed.
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_agg_ind_group_id
		  FROM higg_config
		 WHERE survey_sid = in_survey_sid;

		SELECT response_year
		  INTO v_response_year
		  FROM csr.internal_audit ia
		  JOIN higg_config_profile hcp ON hcp.internal_audit_sid = ia.internal_audit_sid
		 WHERE ia.survey_response_id = in_response_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Either the survey type has been applied to survey that's not being used for
			-- Higg integration (which is a misconfiguration) or the response is not tied
			-- to the integration. Either way, don't try to recalculate indicators.
			RETURN;
	END;

	v_start_dtm := TO_DATE(v_response_year || '-01-01', 'YYYY-MM-DD');
	v_end_dtm := TO_DATE((v_response_year + 1) || '-01-01', 'YYYY-MM-DD');

	FOR r IN (
		SELECT qs.score_type_id, qsr.overall_score, qsr.score_threshold_id, s.company_sid
		  FROM csr.v$quick_survey_response qsr
		  JOIN csr.quick_survey qs ON qs.survey_sid = qsr.survey_sid
		  JOIN higg_config hc ON hc.survey_sid = qsr.survey_sid
		  JOIN (
				SELECT survey_response_id, region_sid
				  FROM csr.internal_audit
				 WHERE survey_response_id = in_response_id
				 UNION
				SELECT ias.survey_response_id, region_sid
				  FROM csr.internal_audit_survey ias
				  JOIN csr.internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
				 WHERE ias.survey_response_id = in_response_id
		  ) ia ON ia.survey_response_id = qsr.survey_response_id
		  JOIN csr.supplier s ON ia.region_sid = s.region_sid
		 WHERE qsr.survey_response_id = in_response_id
		   AND hc.copy_score_on_survey_submit = 1
	)
	LOOP
		-- scores
		csr.supplier_pkg.UNSEC_UpdateSupplierScore(
			in_supplier_sid		=> r.company_sid,
			in_score_type_id	=> r.score_type_id,
			in_score			=> r.overall_score,
			in_threshold_id		=> r.score_threshold_id,
			in_as_of_date		=> v_start_dtm,
			in_comment_text		=> 'Copy score from HIGG survey',
			in_valid_until_dtm	=> v_end_dtm
		);
	END LOOP;

	IF v_agg_ind_group_id IS NULL THEN
		RETURN;
	END IF;


	csr.calc_pkg.AddJobsForAggregateIndGroup(
		in_aggregate_ind_group_id	=> v_agg_ind_group_id,
		in_start_dtm				=> v_start_dtm,
		in_end_dtm					=> v_end_dtm
	);
END;

PROCEDURE SetHiggAuditScore(
	in_internal_audit_sid 		csr.internal_audit.internal_audit_sid%TYPE
)
AS
BEGIN
	IF NOT security.security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in administrators can run SetHiggAuditScore');
	END IF;

	FOR r IN (
		SELECT hr.response_score, hcm.score_type_id
		  FROM higg_config_profile hcp
		  JOIN higg_config_module hcm ON hcm.higg_config_id = hcp.higg_config_id
		  JOIN higg_response hr ON hr.higg_profile_id = hcp.higg_profile_id AND hr.response_year = hcp.response_year AND hr.higg_module_id = hcm.higg_module_id
		 WHERE hcp.internal_audit_sid = in_internal_audit_sid
	) LOOP
		csr.audit_pkg.SetAuditScore(
			in_internal_audit_sid	=> in_internal_audit_sid,
			in_score_type_id		=> r.score_type_id,
			in_score				=> r.response_score,
			in_score_threshold_id	=> csr.quick_survey_pkg.GetThresholdFromScore(r.score_type_id, r.response_score)
		);
	END LOOP;
END;

END higg_pkg;
/

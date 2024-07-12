CREATE OR REPLACE PACKAGE BODY csr.question_library_pkg AS

PROCEDURE GetQuestion(
	in_question_id			IN	question_version.question_id%TYPE,
	in_version				IN	question_version.question_version%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_version_cur 		OUT security_pkg.T_OUTPUT_CUR,
	out_tags_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_options_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_options_tags_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_version				question_version.question_version%TYPE;
	v_draft					question_version.question_draft%TYPE;
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions

	IF in_version IS NULL THEN
		SELECT q.latest_question_version, q.latest_question_draft
		  INTO v_version, v_draft
		  FROM csr.question q
		 WHERE q.question_id = in_question_id;
	ELSE
		v_version := 0;
		v_draft := 1;
	END IF;

	OPEN out_cur FOR
		SELECT q.question_id, q.question_type, q.lookup_key,
			   q.latest_question_version, q.latest_question_draft
		  FROM csr.question q
		 WHERE q.question_id = in_question_id;

	OPEN out_version_cur FOR
		SELECT qv.question_version, qv.question_draft, qv.parent_id, qv.parent_version, qv.parent_draft, qv.pos,
					 qv.label, qv.score, qv.max_score, qv.upload_score, qv.weight, qv.dont_normalise_score, qv.has_score_expression,
					 qv.has_max_score_expr, qv.remember_answer, qv.count_question, qv.action, qv.question_xml
		  FROM csr.question q
		  JOIN csr.question_version qv
		    ON q.app_sid = qv.app_sid
		   AND q.question_id = qv.question_id
		 WHERE q.question_id = in_question_id
		   AND qv.question_version = v_version
		   AND qv.question_draft = v_draft;

	OPEN out_tags_cur FOR
		SELECT qt.question_id, qt.show_in_survey, tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag, tgm.pos
		  FROM csr.question q
		  JOIN csr.question_tag qt ON q.question_id = qt.question_id AND qt.question_version = v_version AND qt.question_draft = v_draft
		  JOIN csr.tag_group_member tgm ON qt.tag_id = tgm.tag_id AND qt.app_sid = tgm.app_sid
		  JOIN csr.v$tag t ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
		  JOIN csr.v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		 WHERE tg.applies_to_quick_survey = 1
		   AND q.question_id = in_question_id
		 ORDER BY tgm.tag_group_id, tgm.pos;

	OPEN out_options_cur FOR
		SELECT 	qo.question_option_id,
				qo.question_id, qo.question_version, qo.question_draft,
				qo.color, qo.maps_to_ind_sid, pos,
				qo.non_compliance_popup, qo.non_comp_default_id, qo.non_compliance_type_id, qo.non_compliance_label, qo.non_compliance_detail, qo.non_comp_root_cause, qo.non_comp_suggested_action,
				qo.option_action, qo.label, qo.lookup_key, qo.score, qo.question_option_xml
		  FROM	csr.question q
		  JOIN	csr.question_option	 qo ON 	qo.question_id 		= q.question_id
										AND qo.question_version = v_version
										AND qo.question_draft	= v_draft
		 WHERE	q.question_id 		= in_question_id;

	OPEN out_options_tags_cur FOR
		SELECT qot.question_id,
			   qot.question_version,
			   qot.question_draft,
			   qot.question_option_id,
			   qot.tag_id,
			   tg.tag_group_id
		  FROM csr.question q
		  JOIN csr.question_option	 qo ON 	qo.question_id 		= q.question_id
										AND qo.question_version 	= v_version
										AND qo.question_draft		= v_draft
		  JOIN csr.question_option_nc_tag qot 	ON qot.question_id 		= qo.question_id
												AND qot.question_version	= qo.question_version
												AND qot.question_draft		= qo.question_draft
												AND qot.question_option_id	= qo.question_option_id
		  JOIN csr.tag_group_member tgm 	ON qot.tag_id = tgm.tag_id AND qot.app_sid = tgm.app_sid
		  JOIN csr.tag t 					ON tgm.tag_id = t.tag_id AND tgm.app_sid = t.app_sid
		  JOIN csr.tag_group tg 			ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
		 WHERE q.question_id 		= in_question_id
		   AND tg.applies_to_quick_survey = 1
		 ORDER BY tg.tag_group_id, tgm.pos;
END;

PROCEDURE GetQuestionHistory(
	in_question_id		IN	question_version.question_id%TYPE,
	out_versions_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_versions_cur FOR
		SELECT q.question_id, qv.question_version, qv.question_draft
		  FROM csr.question q
		  JOIN csr.question_version qv
		    ON q.app_sid = qv.app_sid
		   AND q.question_id = qv.question_id
		 WHERE q.question_id = in_question_id
		   AND qv.app_sid = security_pkg.getapp
		 ORDER BY qv.question_version desc;
END;

PROCEDURE GetQuestions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions
	OPEN out_cur FOR
		SELECT question_id, question_version, question_draft, parent_id, parent_version, parent_draft, pos
			   label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression,
			   has_max_score_expr, remember_answer, count_question, action
		  FROM v$question
		 WHERE owned_by_survey_sid IS NULL;
END;

PROCEDURE CreateQuestion(
	in_question_type			IN	question.question_type%TYPE,
	in_custom_question_type_id	IN	question.custom_question_type_id%TYPE,
	in_lookup_key				IN	question.lookup_key%TYPE,
	in_maps_to_ind_sid			IN	question.maps_to_ind_sid%TYPE,
	in_measure_sid				IN	question.measure_sid%TYPE,
	out_question_id				OUT	question.question_id%TYPE
)
AS
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions
	FOR r IN (
		SELECT * FROM dual
		 WHERE EXISTS(
			SELECT NULL FROM question
			 WHERE lookup_key IS NOT NULL
			   AND owned_by_survey_sid IS NULL
			   AND lookup_key = in_lookup_key
		 )
	) LOOP
		RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'lookup_key');
	END LOOP;

	INSERT INTO question
		(question_id, question_type, custom_question_type_id, lookup_key, maps_to_ind_sid, measure_sid, latest_question_version, latest_question_draft)
	VALUES 
		(question_id_seq.nextval, in_question_type, in_custom_question_type_id, in_lookup_key, in_maps_to_ind_sid, in_measure_sid, 0, 0)
	RETURNING question_id INTO out_question_id;
END;

PROCEDURE SaveQuestion(
	in_question_id				IN	question_version.question_id%TYPE,
	in_question_version			IN	question_version.question_version%TYPE,
	in_question_draft			IN	question_version.question_draft%TYPE,
	in_parent_id				IN	question_version.parent_id%TYPE,
	in_parent_version			IN	question_version.parent_version%TYPE,
	in_pos						IN	question_version.pos%TYPE,
	in_label					IN	question_version.label%TYPE,
	in_score					IN	question_version.score%TYPE,
	in_max_score				IN	question_version.max_score%TYPE,
	in_upload_score				IN	question_version.upload_score%TYPE,
	in_weight					IN	question_version.weight%TYPE,
	in_dont_normalise_score		IN	question_version.dont_normalise_score%TYPE,
	in_has_score_expression		IN	question_version.has_score_expression%TYPE,
	in_has_max_score_expr		IN	question_version.has_max_score_expr%TYPE,
	in_remember_answer			IN	question_version.remember_answer%TYPE,
	in_count_question			IN	question_version.count_question%TYPE,
	in_action					IN	question_version.action%TYPE,
	in_question_xml				IN	question_version.question_xml%TYPE,
	in_tag_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY,
	in_tag_show_in_survey		IN	chain.helper_pkg.T_NUMBER_ARRAY
)
AS
	v_tag_ids					chain.T_NUMERIC_TABLE DEFAULT chain.helper_pkg.NumericArrayToTable(in_tag_ids);

BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions

	MERGE INTO question_version qv
	USING (SELECT
				in_question_id			as question_id,
				in_question_version		as question_version,
				in_question_draft		as question_draft,
				in_parent_id			as parent_id,
				in_parent_version		as parent_version,
				CASE WHEN in_parent_id IS NULL THEN NULL ELSE 1 END as parent_draft,
				in_pos					as pos,
				in_label				as label,
				in_score				as score,
				in_max_score			as max_score,
				in_upload_score			as upload_score,
				in_weight				as weight,
				in_dont_normalise_score	as dont_normalise_score,
				in_has_score_expression	as has_score_expression,
				in_has_max_score_expr	as has_max_score_expr,
				in_remember_answer		as remember_answer,
				in_count_question		as count_question,
				in_action				as action,
				in_question_xml			as question_xml
			FROM DUAL) s
	ON (qv.question_id = s.question_id AND qv.question_version = s.question_version AND qv.question_draft = s.question_draft)
	WHEN MATCHED THEN UPDATE
	   SET qv.parent_id = s.parent_id, 
			qv.parent_version = s.parent_version, 
			qv.parent_draft = s.parent_draft,
			qv.pos = s.pos,
			qv.label = s.label,
			qv.score = s.score, 
			qv.max_score = s.max_score, 
			qv.upload_score = s.upload_score, 
			qv.weight = s.weight, 
			qv.dont_normalise_score = s.dont_normalise_score, 
			qv.has_score_expression = s.has_score_expression,
			qv.has_max_score_expr = s.has_max_score_expr, 
			qv.remember_answer = s.remember_answer, 
			qv.count_question = s.count_question, 
			qv.action = s.action, 
			qv.question_xml = s.question_xml
	WHEN NOT MATCHED THEN 
		INSERT (qv.question_id, qv.question_version, qv.question_draft, qv.parent_id, qv.parent_version, qv.parent_draft,
			qv.pos, qv.label, qv.score, qv.max_score, qv.upload_score, qv.weight,
			qv.dont_normalise_score, qv.has_score_expression, qv.has_max_score_expr,
			qv.remember_answer, qv.count_question, qv.action, qv.question_xml)
		VALUES (s.question_id, s.question_version, s.question_draft, s.parent_id,  s.parent_version,  s.parent_draft,
			s.pos, s.label, s.score, s.max_score, s.upload_score, s.weight,
			s.dont_normalise_score, s.has_score_expression, s.has_max_score_expr,
			s.remember_answer, s.count_question, s.action, s.question_xml);
	
	-- Tags - delete all existing tags
	DELETE FROM csr.question_tag 
	 WHERE question_id = in_question_id 
	   AND question_version = in_question_version 
	   AND question_draft = in_question_draft;
	
	FOR i IN in_tag_ids.FIRST .. in_tag_ids.LAST
	LOOP
		IF (in_tag_ids(i) IS NOT NULL) THEN
			INSERT INTO csr.question_tag (question_id, question_version, question_draft, tag_id, show_in_survey)
			VALUES (in_question_id, in_question_version, in_question_draft, in_tag_ids(i), in_tag_show_in_survey(i));
		END IF;
	END LOOP;

	-- Record the latest version of this question for performance reasons
	UPDATE question
	   SET latest_question_version = in_question_version,
	       latest_question_draft = 1
	 WHERE question_id = in_question_id;
END;

PROCEDURE PublishQuestion(
	in_question_id				IN	question_version.question_id%TYPE,
	in_question_version			IN	question_version.question_version%TYPE
)
AS
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions
	INSERT INTO question_version (
		question_id, question_version, question_draft, parent_id, parent_version, parent_draft, pos,
		label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression,
		has_max_score_expr, remember_answer, count_question, action, question_xml)
	SELECT question_id, question_version, 0, parent_id, parent_version, CASE WHEN parent_id IS NULL THEN NULL ELSE 0 END, pos,
		   label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression,
		   has_max_score_expr, remember_answer, count_question, action, question_xml
	  FROM question_version
	 WHERE question_id = in_question_id
	   AND question_version = in_question_version;
	   
	UPDATE question
	   SET latest_question_version = in_question_version,
	       latest_question_draft = 0
	 WHERE question_id = in_question_id;
END;

PROCEDURE SaveQuestionOption(
	in_question_option_id			IN	question_option.question_option_id%TYPE, 
	in_question_id					IN	question_option.question_id%TYPE,
	in_question_version				IN	question_option.question_version%TYPE,
	in_question_draft				IN	question_option.question_draft%TYPE,
	in_pos							IN	question_option.pos%TYPE,
	in_label						IN	question_option.label%TYPE,
	in_score						IN	question_option.score%TYPE,
	in_color						IN	question_option.color%TYPE,
	in_lookup_key					IN	question_option.lookup_key%TYPE,
	in_maps_to_ind_sid				IN	question_option.maps_to_ind_sid%TYPE,
	in_option_action				IN	question_option.option_action%TYPE,
	in_non_compliance_popup			IN	question_option.non_compliance_popup%TYPE,
	in_non_comp_default_id			IN	question_option.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN	question_option.non_compliance_type_id%TYPE,
	in_non_compliance_label			IN	question_option.non_compliance_label%TYPE,
	in_non_compliance_detail		IN	question_option.non_compliance_detail%TYPE,
	in_non_comp_root_cause			IN	question_option.non_comp_root_cause%TYPE,
	in_non_comp_suggested_action	IN	question_option.non_comp_suggested_action%TYPE,
	in_question_option_xml			IN	question_option.question_option_xml%TYPE,
	in_tag_ids						IN  chain.helper_pkg.T_NUMBER_ARRAY,
	out_question_option_id			OUT	question_option.question_option_id%TYPE
)
AS
	v_tag_ids						chain.T_NUMERIC_TABLE DEFAULT chain.helper_pkg.NumericArrayToTable(in_tag_ids);
BEGIN
	-- TODO: Permissions check - US7615 is required to handle permissions
	IF in_question_option_id = 0 THEN
		out_question_option_id := QS_QUESTION_OPTION_ID_SEQ.nextval;
		INSERT INTO question_option(
			question_option_id, question_id, question_version, question_draft,
			pos, label, score, color, lookup_key, maps_to_ind_sid, option_action,
			non_compliance_popup, non_comp_default_id, non_compliance_type_id, 
			non_compliance_label, non_compliance_detail, non_comp_root_cause,
			non_comp_suggested_action, question_option_xml
		) VALUES (
			out_question_option_id, in_question_id, in_question_version, in_question_draft, 
			in_pos, in_label, in_score, in_color, in_lookup_key, in_maps_to_ind_sid, in_option_action,
			in_non_compliance_popup, in_non_comp_default_id, in_non_compliance_type_id,
			in_non_compliance_label, in_non_compliance_detail, in_non_comp_root_cause,
			in_non_comp_suggested_action, in_question_option_xml
		);
	ELSE
		out_question_option_id := in_question_option_id;
		UPDATE question_option
		   SET pos = in_pos,
			   label = in_label,
			   score = in_score,
			   color = in_color,
			   lookup_key = in_lookup_key,
			   maps_to_ind_sid = in_maps_to_ind_sid,
			   option_action = in_option_action,
			   non_compliance_popup = in_non_compliance_popup,
			   non_comp_default_id = in_non_comp_default_id,
			   non_compliance_type_id = in_non_compliance_type_id,
			   non_compliance_label = in_non_compliance_label,
			   non_compliance_detail = in_non_compliance_detail,
			   non_comp_root_cause = in_non_comp_root_cause,
			   non_comp_suggested_action = in_non_comp_suggested_action,
			   question_option_xml = in_question_option_xml
		 WHERE question_option_id = in_question_option_id
		   AND question_id = in_question_id
		   AND question_version = in_question_version
		   AND question_draft = in_question_draft;
	END IF;
	
	-- Tags. Delete tags we don't want anymore
	DELETE FROM csr.question_option_nc_tag qt
	 WHERE qt.question_option_id = out_question_option_id
	   AND qt.question_version = in_question_version 
	   AND qt.question_draft = in_question_draft
	   AND qt.tag_id NOT IN (
			SELECT item from TABLE(v_tag_ids)
		);

	-- Tags. Add missing tags
	FOR r IN (SELECT * from TABLE(v_tag_ids)) LOOP
		BEGIN
			INSERT INTO csr.question_option_nc_tag (question_id, question_option_id, question_version, tag_id, question_draft)
			VALUES (in_question_id, out_question_option_id, in_question_version, r.item, 1);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;

END question_library_pkg;
/

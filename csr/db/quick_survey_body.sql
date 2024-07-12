create or replace PACKAGE BODY csr.quick_survey_pkg AS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	-- null means we're trashing it, all a bit ugly
	IF in_new_name IS NOT NULL THEN
		security.web_pkg.RenameObject(in_act_id, in_sid_id, in_new_name);
	END IF;
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_audience				quick_survey.audience%TYPE;
BEGIN
	SELECT audience
	  INTO v_audience
	  FROM quick_survey
	 WHERE survey_sid = in_sid_id;

	IF v_audience like 'chain%' THEN
		supplier_pkg.UnmakeChainSurvey(in_sid_id);
	END IF;

	-- clean up
	DELETE FROM qs_filter_condition_general
	 WHERE survey_sid = in_sid_id;

	DELETE FROM qs_filter_condition
	 WHERE survey_sid = in_sid_id;

	DELETE FROM flow_item_subscription
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE survey_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = in_sid_id
		)
	);

	DELETE FROM flow_item_generated_alert
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE survey_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = in_sid_id
		)
	);

	DELETE FROM flow_state_log
	 WHERE flow_item_id IN (
		SELECT flow_item_id
		  FROM flow_item
		 WHERE survey_response_id IN (
			SELECT survey_response_id
			  FROM quick_survey_response
			 WHERE survey_sid = in_sid_id
		)
	);

	DELETE FROM flow_item
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);


	DELETE FROM qs_submission_file
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM qs_answer_file
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM qs_response_file
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM qs_answer_log
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM issue_survey_answer
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM quick_survey_answer
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	UPDATE quick_survey_response
	   SET last_submission_id = NULL
	 WHERE survey_sid = in_sid_id;

	DELETE FROM quick_survey_submission
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM supplier_survey_response
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM region_survey_response
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_sid_id
	);

	DELETE FROM qs_question_option_nc_tag
	 WHERE question_id IN (
		SELECT DISTINCT question_id
		  FROM quick_survey_question
		 WHERE survey_sid = in_sid_id
	 );
		
	DELETE FROM quick_survey_expr_action
	 WHERE survey_sid = in_sid_id;

	DELETE FROM quick_survey_expr
	 WHERE survey_sid = in_sid_id;

	DELETE FROM qs_question_option
	 WHERE question_id IN (
		SELECT DISTINCT question_id
		  FROM quick_survey_question
		 WHERE survey_sid = in_sid_id
	 );

	DELETE FROM quick_survey_question_tag
	 WHERE question_id IN (
		SELECT DISTINCT question_id
		  FROM quick_survey_question
		 WHERE survey_sid = in_sid_id
	 );

	FOR r IN (
		SELECT question_id, survey_version, level
		  FROM quick_survey_question
		 WHERE survey_sid = in_sid_id
		 START WITH parent_id is NULL
	   CONNECT BY PRIOR question_id = parent_id
		 ORDER BY LEVEL DESC
	) LOOP
	  DELETE FROM quick_survey_question
	   WHERE question_id = r.question_id
		 AND survey_version = r.survey_version;
	END LOOP;

	DELETE FROM postit
	  WHERE postit_id IN (
		SELECT postit_id FROM qs_response_postit WHERE survey_response_id IN (
			SELECT survey_response_id FROM quick_survey_response WHERE survey_sid = in_sid_id
		)
	);

	campaigns.campaign_pkg.DeleteObject(in_act_id, in_sid_id);

	DELETE FROM quick_survey_response
	 WHERE survey_sid = in_sid_id;

	DELETE FROM quick_survey_version
	 WHERE survey_sid = in_sid_id;

	DELETE FROM question_tag
	 WHERE question_id IN (
		SELECT question_id
		  FROM question
		 WHERE owned_by_survey_sid = in_sid_id
	 );
		
	DELETE FROM question_option_nc_tag
	 WHERE question_id IN (
		SELECT question_id
		  FROM question
		 WHERE owned_by_survey_sid = in_sid_id
	 );
	 
	DELETE FROM question_option
	 WHERE question_id IN (
		SELECT question_id
		  FROM question
		 WHERE owned_by_survey_sid = in_sid_id
	 );

	DELETE FROM question_version
	 WHERE question_id IN (
		SELECT question_id
		  FROM question
		 WHERE owned_by_survey_sid = in_sid_id
	 );

	DELETE FROM question
	 WHERE question_id IN (
		SELECT question_id
		  FROM question
		 WHERE owned_by_survey_sid = in_sid_id
	 );
	 
	DELETE FROM quick_survey
	 WHERE survey_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM security.web_resource
	 WHERE sid_id = in_sid_id;

	-- Although the survey is created as a web resource, this "move" may in fact be a "trash" operation,
	-- in which case we deleted the record from web_resource table. Ideally we wouldn't delete that,
	-- but moving a web_resource under Trash seems to cause problems of its own.
	IF v_cnt > 0 THEN
		security.web_pkg.MoveObject(in_act_id, in_sid_id, in_new_parent_sid_id, in_old_parent_sid_id);
	END IF;
END;

FUNCTION GetSurveyHelperPkg (
	in_survey_sid			IN	security_pkg.T_SID_ID
) RETURN quick_survey_type.helper_pkg%TYPE
AS
	v_helper_pkg		quick_survey_type.helper_pkg%TYPE;
BEGIN
	SELECT MIN(qst.helper_pkg)
	  INTO v_helper_pkg
	  FROM quick_survey qs
	  JOIN quick_survey_type qst ON qs.quick_survey_type_id = qst.quick_survey_type_id
	 WHERE qs.survey_sid = in_survey_sid;

	RETURN v_helper_pkg;
END;

PROCEDURE ExecuteHelperProc (
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_proc_call			IN  VARCHAR2
)
AS
	v_helper_pkg		quick_survey_type.helper_pkg%TYPE := GetSurveyHelperPkg(in_survey_sid);
BEGIN
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || v_helper_pkg || '.' || in_proc_call || ';END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE ExecuteHelperProcReturnCursor (
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_proc					IN  VARCHAR2,
	in_variables			IN  VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_helper_pkg		quick_survey_type.helper_pkg%TYPE := GetSurveyHelperPkg(in_survey_sid);
	v_out_vars			VARCHAR2(100) DEFAULT ':out_cur';
	c_cursor			security_pkg.T_OUTPUT_CUR;
BEGIN
	IF v_helper_pkg IS NOT NULL THEN
		IF in_variables IS NOT NULL THEN
			v_out_vars := ', '||v_out_vars;
		END IF;

		BEGIN
			EXECUTE IMMEDIATE (
				'BEGIN ' || v_helper_pkg || '.' || in_proc || '(' || in_variables || v_out_vars || ');END;'
			) USING c_cursor;

			out_cur := c_cursor;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE OnSurveySubmitted (
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_response_id		IN	security_pkg.T_SID_ID,
	in_submission_id	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteHelperProc(in_survey_sid, 'OnSurveySubmitted('||in_survey_sid||','||in_response_id||','||in_submission_id||')');
END;

PROCEDURE UNSEC_SetAudience(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_audience			IN  quick_survey.audience%TYPE,
	in_always_apply		IN	NUMBER DEFAULT 0
)
AS
	v_chain_users 		security_pkg.T_SID_ID;
	v_chain_managers 	security_pkg.T_SID_ID;
	v_reg_users 		security_pkg.T_SID_ID;
	v_survey_dacl_id	security_pkg.T_ACL_ID;
	v_prev_audience		quick_survey.audience%TYPE;
	v_current_version	quick_survey.current_version%TYPE;
BEGIN
	BEGIN
		SELECT audience, current_version
		  INTO v_prev_audience, v_current_version
		  FROM quick_survey
		 WHERE survey_sid = in_survey_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- must be an insert and we've not inserted yet
			v_prev_audience := null;
	END;

	IF v_prev_audience = in_audience AND in_always_apply = 0 THEN
		-- nothing to do here... abort
		RETURN;
	END IF;

	UPDATE quick_survey
	   SET audience = in_audience
	 WHERE survey_sid = in_survey_sid;

	-- find some user groups
	-- TODO: we need to use lookup_Keys or store these in a table or something else as hard-coded names are a bad idea!
	BEGIN
		v_chain_users := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/Chain Users');
	EXCEPTION
		WHEN security_Pkg.OBJECT_NOT_FOUND THEN
			v_chain_users := null;
	END;

	BEGIN
		v_chain_managers := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/Supply Chain Managers');
	EXCEPTION
		WHEN security_Pkg.OBJECT_NOT_FOUND THEN
			v_chain_managers := null;
	END;

	BEGIN
		v_reg_users := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups/RegisteredUsers');
	EXCEPTION
		WHEN security_Pkg.OBJECT_NOT_FOUND THEN
			-- some idiot renamed it I guess. Well that was stupid of them
			v_reg_users := null;
	END;

	v_survey_dacl_id := Acl_Pkg.GetDACLIDForSID(in_survey_sid);

	-- chain
	/*
	-- dbcom (gb)/Capabilities/Company/Create questionnaire type
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.CREATE_QUESTIONNAIRE_TYPE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitations');
	END IF;
	*/
	IF v_chain_users IS NOT NULL THEN
		-- remove chain users
		acl_pkg.RemoveACEsForSid(security_pkg.getACT, v_survey_dacl_id, v_chain_users);
	END IF;

	IF v_chain_managers IS NOT NULL THEN
		-- remove chain users
		acl_pkg.RemoveACEsForSid(security_pkg.getACT, v_survey_dacl_id, v_chain_managers);
	END IF;

    IF in_audience like 'chain%' THEN
		-- poke chain
		supplier_pkg.MakeChainSurvey(in_survey_sid);
		-- grant chain users
		IF v_chain_users IS NOT NULL THEN
			acl_pkg.AddACE(security_pkg.getACT, v_survey_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_chain_users, security_pkg.PERMISSION_STANDARD_READ);
		END IF;
		-- grant chain managers
		IF v_chain_managers IS NOT NULL THEN
			acl_pkg.AddACE(security_pkg.getACT, v_survey_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_chain_managers, security_pkg.PERMISSION_STANDARD_READ + Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS);
		END IF;
		-- hide for now if unpublished
		IF v_current_version IS NULL THEN
			supplier_pkg.UnmakeChainSurvey(in_survey_sid);
		END IF;
	ELSIF v_prev_audience like 'chain%' THEN
		-- poke chain
		supplier_pkg.UnmakeChainSurvey(in_survey_sid);
	END IF;

	-- everyone
	acl_pkg.RemoveACEsForSid(security_pkg.getACT, v_survey_dacl_id, security_pkg.SID_BUILTIN_EVERYONE);
	IF in_audience = 'everyone' THEN
		acl_pkg.AddACE(security_pkg.getACT, v_survey_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, security_pkg.SID_BUILTIN_EVERYONE, security_pkg.PERMISSION_STANDARD_READ);
	END IF;

	-- existing and audit -- treat the same from a security perspective
	IF v_reg_users IS NOT NULL THEN
		acl_pkg.RemoveACEsForSid(security_pkg.getACT, v_survey_dacl_id, v_reg_users);
		IF in_audience IN ('existing', 'audit') AND v_reg_users IS NOT NULL THEN
			acl_pkg.AddACE(security_pkg.getACT, v_survey_dacl_id, security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_reg_users, security_pkg.PERMISSION_STANDARD_READ);
		END IF;
	END IF;

	/*IF in_audience = 'audit' THEN
		-- Set the aggregate ind type for internal audits
		-- Using a loop, but there should only be 0 or 1 rows
		FOR r IN (
			SELECT aggregate_ind_group_id
			  FROM aggregate_ind_group
			 WHERE name = 'InternalAudit'
		) LOOP
			UPDATE quick_survey
			   SET aggregate_ind_group_id = r.aggregate_ind_group_id
			 WHERE survey_sid = in_survey_sid;
		END LOOP;
	ELSIF v_prev_audience = 'audit' THEN
		UPDATE quick_survey
		   SET aggregate_ind_group_id = NULL
		 WHERE survey_sid = in_survey_sid;
	END IF;*/
END;

PROCEDURE GetRandomSOName(
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	out_name				OUT	security_pkg.T_SO_NAME
)
AS
	v_act_id				security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_existing_sid			security.security_pkg.T_SID_ID;
	v_name					security_pkg.T_SO_NAME := '';
	v_char					security_pkg.T_SO_NAME;
	v_random_seed			NUMBER(2, 0);
BEGIN
	LOOP
		-- We build our name by appending numbers and letters
		-- We only use consonants (and not Y) so it's not a word
		-- We omit K to avoid three consecutive Ks and we omit L
		-- to avoid confusion between l and I.
		v_random_seed := DBMS_RANDOM.VALUE(0, 27);
		v_char := CASE v_random_seed
			WHEN 10 THEN 'b' WHEN 11 THEN 'c' WHEN 12 THEN 'd'
			WHEN 13 THEN 'f' WHEN 14 THEN 'g' WHEN 15 THEN 'h'
			WHEN 16 THEN 'j' WHEN 17 THEN 'm' WHEN 18 THEN 'n'
			WHEN 19 THEN 'p' WHEN 20 THEN 'q' WHEN 21 THEN 'r'
			WHEN 22 THEN 's' WHEN 23 THEN 't' WHEN 24 THEN 'v'
			WHEN 25 THEN 'w' WHEN 26 THEN 'x' WHEN 27 THEN 'z'
			ELSE ''||v_random_seed -- pass through decimal digits
		END;


		v_name := v_name || v_char;
		IF LENGTH(v_name) >= 8 THEN
			BEGIN
				v_existing_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_parent_sid, v_name);
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					EXIT;
			END;
		END IF;
	END LOOP;

	out_name := v_name;
END;

PROCEDURE CreateSurvey(
	in_name					IN  security_pkg.T_SO_NAME,
	in_label				IN  quick_survey_version.label%TYPE,
	in_audience				IN  quick_survey.audience%TYPE,
	in_group_key			IN	quick_survey.group_key%TYPE,
	in_question_xml			IN  quick_survey_version.question_xml%TYPE,
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_score_type_id		IN	quick_survey.score_type_id%TYPE,
	in_survey_type_id		IN	quick_survey_type.quick_survey_type_id%TYPE DEFAULT NULL,
	in_from_question_library IN quick_survey.from_question_library%TYPE DEFAULT 0,
	in_lookup_key			IN	quick_survey.lookup_key%TYPE DEFAULT NULL,
	out_survey_sid          OUT security_pkg.T_SID_ID
)
AS
	v_act_id			security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid			security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_wwwroot			security.security_pkg.T_SID_ID;
	v_wwwroot_surveys   security.security_pkg.T_SID_ID;
	v_parent_sid		security.security_pkg.T_SID_ID;
	v_admins            security.security_pkg.T_SID_ID;
	v_user_sid			security.security_pkg.T_SID_ID;
	v_name				security_pkg.T_SO_NAME DEFAULT in_name;
BEGIN
	v_wwwroot := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
	BEGIN
		v_wwwroot_surveys := securableobject_pkg.GetSIDFromPath(v_act_id, v_wwwroot, 'surveys');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			-- surveys node doesn't exist yet
			web_pkg.CreateResource(v_act_id, v_wwwroot, v_wwwroot, 'surveys', v_wwwroot_surveys);
			-- add administrators
			v_admins := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
			acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_wwwroot_surveys), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT, v_admins, security_pkg.PERMISSION_STANDARD_ALL);
	END;

	IF in_parent_sid > 0 THEN
		v_parent_sid := in_parent_sid;
	ELSE
		v_parent_sid := v_wwwroot_surveys;
	END IF;

	IF v_name IS NULL THEN
		GetRandomSOName(in_parent_sid, v_name);
	END IF;

	-- create our object as a web resource
	web_pkg.CreateResource(v_act_id, v_wwwroot, v_parent_sid, v_name, class_pkg.GetClassId('csrquicksurvey'),
		'/csr/site/quicksurvey/public/view.acds?sid={sid}',
		out_survey_sid);

	INSERT INTO quick_survey
		(survey_sid, audience, group_key, score_type_id, quick_survey_type_id, last_modified_dtm, from_question_library, lookup_key)
	VALUES
		(out_survey_sid, in_audience, in_group_key, in_score_type_id, in_survey_type_id, SYSDATE, in_from_question_library, in_lookup_key);

	-- Create the draft version
	INSERT INTO quick_survey_version
		(survey_sid, survey_version, label, question_xml)
	VALUES
		(out_survey_sid, 0, in_label, in_question_xml);

	UNSEC_SetAudience(out_survey_sid, in_audience, 1);

	INTERNAL_XmlUpdated(out_survey_sid);

	security.user_pkg.GetSid(v_act_id, v_user_sid);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_sid,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE,
		in_app_sid => v_app_sid,
		in_object_sid => out_survey_sid,
		in_description => 'Created survey'
	);
END;

PROCEDURE PublishSurvey (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_update_responses_from	IN	quick_survey_version.survey_version%TYPE,
	out_publish_result			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_issue_template_id				issue_template.issue_template_id%TYPE;
	v_qs_expr_non_compl_action_id	number;
	v_qs_expr_msg_action_id			number;
	v_audience						quick_survey.audience%TYPE;
	v_user_sid						security_pkg.T_SID_ID;
	v_new_version					quick_survey_version.survey_version%TYPE;
	t_owned_question_ids			security.T_SID_TABLE;
	t_shared_question_ids			security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied publishing survey');
	END IF;

	IF in_update_responses_from = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'in_update_responses_from cannot be 0');
	END IF;

	SELECT NVL(current_version, 0) + 1, audience
	  INTO v_new_version, v_audience
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;
	 
	SELECT q.question_id
	  BULK COLLECT INTO t_owned_question_ids
	  FROM question q
	  JOIN quick_survey_question qsq ON qsq.question_id = q.question_id
	 WHERE qsq.survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND q.owned_by_survey_sid = in_survey_sid;

	SELECT q.question_id
	  BULK COLLECT INTO t_shared_question_ids
	  FROM question q
	  JOIN quick_survey_question qsq ON qsq.question_id = q.question_id
	 WHERE qsq.survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND q.owned_by_survey_sid != in_survey_sid;
	   
	INSERT INTO quick_survey_version (survey_sid, survey_version, question_xml, label, start_dtm, end_dtm, published_dtm, published_by_sid)
	SELECT in_survey_sid, v_new_version, question_xml, label, start_dtm, end_dtm, SYSDATE, SYS_CONTEXT('SECURITY', 'SID')
	  FROM quick_survey_version
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0;

	-- publish questions which are 'owned' by this survey by tying their version to the survey version
	INSERT INTO question_version (question_id, question_version, question_draft, parent_id, parent_version, parent_draft, pos, label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression, has_max_score_expr, remember_answer, count_question, action, question_xml)
	SELECT qsq.question_id, v_new_version, 0, qsq.parent_id, v_new_version, 0, qsq.pos, qsq.label, qsq.score, qsq.max_score, qsq.upload_score, qsq.weight, qsq.dont_normalise_score, qsq.has_score_expression, qsq.has_max_score_expr, qsq.remember_answer, qsq.count_question, qsq.action, qv.question_xml
	  FROM quick_survey_question qsq
	  JOIN question_version qv ON qv.question_id = qsq.question_id AND qv.question_version = qsq.question_version
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND qsq.question_id IN (
			SELECT column_value
			  FROM TABLE(t_owned_question_ids)
	   );
	
	-- point the question at its latest version
	UPDATE question
	   SET latest_question_version = v_new_version,
		   latest_question_draft = 0
	 WHERE owned_by_survey_sid = in_survey_sid;

	INSERT INTO question_option (question_option_id, question_id, pos, label, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_version, question_draft, question_option_xml)
	SELECT qsqqo.question_option_id, qsqqo.question_id, qsqqo.pos, qsqqo.label, qsqqo.score, qsqqo.color, qsqqo.lookup_key, qsqqo.maps_to_ind_sid, qsqqo.option_action, qsqqo.non_compliance_popup, qsqqo.non_comp_default_id, qsqqo.non_compliance_type_id, qsqqo.non_compliance_label, qsqqo.non_compliance_detail, qsqqo.non_comp_root_cause, qsqqo.non_comp_suggested_action, v_new_version, 0, qo.question_option_xml
	  FROM qs_question_option qsqqo
	  JOIN question_option qo ON qsqqo.question_option_id = qo.question_option_id AND qsqqo.question_id = qo.question_id AND qsqqo.question_version = qo.question_version
	 WHERE qsqqo.question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;
	   
	INSERT INTO question_option_nc_tag (question_option_id, question_id, tag_id, question_version, question_draft)
	SELECT question_option_id, question_id, tag_id, v_new_version, 0
	  FROM qs_question_option_nc_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;
	
	INSERT INTO question_tag (question_id, tag_id, question_version, question_draft)
	SELECT question_id, tag_id, v_new_version, 0
	  FROM quick_survey_question_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;	   
	
	INSERT INTO quick_survey_question (question_id, question_version, parent_id, parent_version, survey_sid, pos, label, is_visible, question_type, score, lookup_key, maps_to_ind_sid, max_score, upload_score, custom_question_type_id, weight, measure_sid, dont_normalise_score, has_score_expression, has_max_score_expr, survey_version, remember_answer, count_question, action)
	SELECT question_id, v_new_version, parent_id, CASE WHEN parent_id IS NULL THEN NULL ELSE v_new_version END, survey_sid, pos, label, is_visible, question_type, score, lookup_key, maps_to_ind_sid, max_score, upload_score, custom_question_type_id, weight, measure_sid, dont_normalise_score, has_score_expression, has_max_score_expr, v_new_version, remember_answer, count_question, action
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
	   AND question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
	   );
	   
	INSERT INTO qs_question_option (question_option_id, question_id, pos, label, is_visible, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, survey_sid, survey_version, question_version)
	SELECT question_option_id, question_id, pos, label, is_visible, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, survey_sid, v_new_version, v_new_version
	  FROM qs_question_option
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;

	INSERT INTO qs_question_option_nc_tag (question_option_id, question_id, tag_id, survey_version, question_version, survey_sid)
	SELECT question_option_id, question_id, tag_id, v_new_version, v_new_version, in_survey_sid
	  FROM qs_question_option_nc_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;
	
	INSERT INTO quick_survey_question_tag (question_id, tag_id, survey_version, question_version, survey_sid)
	SELECT question_id, tag_id, v_new_version, v_new_version, in_survey_sid
	  FROM quick_survey_question_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		)
	   AND survey_version = 0;
	
	INSERT INTO quick_survey_expr (survey_sid, expr_id, expr, question_id, question_option_id, survey_version, question_version)
	SELECT survey_sid, expr_id, expr, question_id, question_option_id, v_new_version, v_new_version
	  FROM quick_survey_expr
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND (question_id IS NULL OR question_id IN (
		SELECT column_value
		  FROM TABLE(t_owned_question_ids)
		));

	-- publish questions which are shared, question version doesn't change
	INSERT INTO quick_survey_question (question_id, question_version, parent_id, parent_version, survey_sid, pos, label, is_visible, question_type, score, lookup_key, maps_to_ind_sid, max_score, upload_score, custom_question_type_id, weight, measure_sid, dont_normalise_score, has_score_expression, has_max_score_expr, survey_version, remember_answer, count_question, action)
	SELECT question_id, question_version, parent_id, parent_version, survey_sid, pos, label, is_visible, question_type, score, lookup_key, maps_to_ind_sid, max_score, upload_score, custom_question_type_id, weight, measure_sid, dont_normalise_score, has_score_expression, has_max_score_expr, v_new_version, remember_answer, count_question, action
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
	   AND question_id IN (
			SELECT column_value
			  FROM TABLE(t_shared_question_ids)
	   );
	   
	INSERT INTO qs_question_option (question_option_id, question_id, pos, label, is_visible, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, survey_sid, survey_version, question_version)
	SELECT question_option_id, question_id, pos, label, is_visible, score, color, lookup_key, maps_to_ind_sid, option_action, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, survey_sid, v_new_version, question_version
	  FROM qs_question_option
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_shared_question_ids)
		)
	   AND survey_version = 0;

	INSERT INTO qs_question_option_nc_tag (question_option_id, question_id, tag_id, survey_version, question_version, survey_sid)
	SELECT question_option_id, question_id, tag_id, v_new_version, question_version, in_survey_sid
	  FROM qs_question_option_nc_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_shared_question_ids)
		)
	   AND survey_version = 0;
	
	INSERT INTO quick_survey_question_tag (question_id, tag_id, survey_version, question_version, survey_sid)
	SELECT question_id, tag_id, v_new_version, question_version, in_survey_sid
	  FROM quick_survey_question_tag
	 WHERE question_id IN (
		SELECT column_value
		  FROM TABLE(t_shared_question_ids)
		)
	   AND survey_version = 0;
	
	INSERT INTO quick_survey_expr (survey_sid, expr_id, expr, question_id, question_option_id, survey_version, question_version)
	SELECT survey_sid, expr_id, expr, question_id, question_option_id, v_new_version, question_version
	  FROM quick_survey_expr
	 WHERE survey_sid = in_survey_sid
	   AND question_id IN (
		SELECT column_value
		  FROM TABLE(t_shared_question_ids)
		)
	   AND survey_version = 0;

	-- Publish expressions
	FOR r IN (
		SELECT quick_survey_expr_action_id, action_type, survey_sid,
			   expr_id, qs_expr_non_compl_action_id, qs_expr_msg_action_id,
			   show_question_id, mandatory_question_id, show_page_id,
			   show_question_version, mandatory_question_version, show_page_version,
			   issue_template_id
		  FROM quick_survey_expr_action ea
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
	) LOOP
		v_qs_expr_non_compl_action_id := NULL;
		v_qs_expr_msg_action_id := NULL;
		v_issue_template_id := NULL;

		IF r.qs_expr_non_compl_action_id IS NOT NULL THEN
			FOR nc IN (
				SELECT assign_to_role_sid, due_dtm_abs, due_dtm_relative, due_dtm_relative_unit,
					   title, detail, send_email_on_creation, non_comp_default_id, non_compliance_type_id
				  FROM qs_expr_non_compl_action
				 WHERE qs_expr_non_compl_action_id = r.qs_expr_non_compl_action_id
			) LOOP
				INSERT INTO qs_expr_non_compl_action (
					qs_expr_non_compl_action_id, assign_to_role_sid, due_dtm_abs, due_dtm_relative,
					due_dtm_relative_unit, title, detail, send_email_on_creation, non_comp_default_id,
					non_compliance_type_id)
				VALUES (
					qs_expr_nc_action_id_seq.nextval, nc.assign_to_role_sid, nc.due_dtm_abs, nc.due_dtm_relative,
					nc.due_dtm_relative_unit, nc.title, nc.detail, nc.send_email_on_creation,
					nc.non_comp_default_id, nc.non_compliance_type_id)
				RETURNING qs_expr_non_compl_action_id INTO v_qs_expr_non_compl_action_id;

				INSERT INTO qs_expr_nc_action_involve_role (qs_expr_non_compl_action_id, involve_role_sid)
				SELECT v_qs_expr_non_compl_action_id, involve_role_sid
				  FROM qs_expr_nc_action_involve_role
				 WHERE qs_expr_non_compl_action_id = r.qs_expr_non_compl_action_id;
			END LOOP;
		END IF;

		IF r.qs_expr_msg_action_id IS NOT NULL THEN
			FOR m IN (
				SELECT msg, css_class
				  FROM qs_expr_msg_action
				 WHERE qs_expr_msg_action_id = r.qs_expr_msg_action_id
			) LOOP
				INSERT INTO qs_expr_msg_action (qs_expr_msg_action_id, msg, css_class)
				VALUES (qs_expr_msg_action_id_seq.nextval, m.msg, m.css_class)
				RETURNING qs_expr_msg_action_id INTO v_qs_expr_msg_action_id;
			END LOOP;
		END IF;
		
		IF r.issue_template_id IS NOT NULL THEN
			FOR i IN (
				SELECT issue_type_id, label, description, assign_to_user_sid, is_urgent, is_critical, due_dtm, due_dtm_relative, due_dtm_relative_unit
				  FROM issue_template
				 WHERE issue_template_id = r.issue_template_id
			)
			LOOP
				INSERT INTO issue_template (issue_template_id, issue_type_id, label, description, assign_to_user_sid, is_urgent,
					is_critical, due_dtm, due_dtm_relative, due_dtm_relative_unit)
				VALUES (issue_template_id_seq.NEXTVAL, i.issue_type_id, i.label, i.description, i.assign_to_user_sid, i.is_urgent, i.is_critical,
					i.due_dtm, i.due_dtm_relative, i.due_dtm_relative_unit)
				RETURNING issue_template_id INTO v_issue_template_id;
			END LOOP;
			
			FOR i IN (
				SELECT issue_custom_field_id, string_value, date_value
				  FROM issue_template_custom_field
				 WHERE issue_template_id = r.issue_template_id
			)
			LOOP
				INSERT INTO issue_template_custom_field (issue_template_id, issue_custom_field_id, string_value, date_value)
				VALUES (v_issue_template_id, i.issue_custom_field_id, i.string_value, i.date_value);
			END LOOP;
			
			FOR i IN (
				SELECT issue_custom_field_id, issue_custom_field_opt_id
				  FROM issue_template_cust_field_opt
				 WHERE issue_template_id = r.issue_template_id
			)
			LOOP
				INSERT INTO issue_template_cust_field_opt (issue_template_id, issue_custom_field_id, issue_custom_field_opt_id)
				VALUES (v_issue_template_id, i.issue_custom_field_id, i.issue_custom_field_opt_id);
			END LOOP;
		END IF;

		INSERT INTO quick_survey_expr_action (
			quick_survey_expr_action_id, action_type, survey_sid,
			expr_id, qs_expr_non_compl_action_id, qs_expr_msg_action_id,
				show_question_id, mandatory_question_id, show_page_id, survey_version,
				show_question_version, mandatory_question_version, show_page_version,
				issue_template_id
		)
		VALUES (
			qs_expr_action_id_seq.nextval, r.action_type, r.survey_sid,
			r.expr_id, v_qs_expr_non_compl_action_id, v_qs_expr_msg_action_id,
				r.show_question_id, r.mandatory_question_id, r.show_page_id, v_new_version,
				CASE WHEN r.show_question_id IS NULL THEN NULL ELSE v_new_version END, 
				CASE WHEN r.mandatory_question_id IS NULL THEN NULL ELSE v_new_version END, 
				CASE WHEN r.show_page_id IS NULL THEN NULL ELSE v_new_version END,
				v_issue_template_id
		);
	END LOOP;


	-- upgrade any open responses on or above specified version
	IF in_update_responses_from IS NOT NULL THEN
		UPDATE quick_survey_response
		   SET survey_version = v_new_version
		 WHERE survey_sid = in_survey_sid
		   AND survey_version >= in_update_responses_from
		   AND question_xml_override IS NULL;
	END IF;

	UPDATE quick_survey
	   SET current_version = v_new_version
	 WHERE survey_sid = in_survey_sid;

	IF v_new_version=1 AND v_audience like 'chain%' THEN
		-- activate chain questionnaire
		supplier_pkg.MakeChainSurvey(in_survey_sid);
	END IF;

	security.user_pkg.GetSid(security.security_pkg.GetAct, v_user_sid);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_sid,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE,
		in_app_sid => security.security_pkg.GetApp,
		in_object_sid => in_survey_sid,
		in_description => CASE WHEN in_update_responses_from IS NOT NULL THEN 'Published survey and updated existing open responses' ELSE 'Published survey' END
	);

	  OPEN out_publish_result FOR
	SELECT COUNT(survey_response_id) non_updated_response_count, v_new_version new_version
	  FROM quick_survey_response
	 WHERE survey_sid = in_survey_sid
	   AND survey_version != v_new_version
	   AND question_xml_override IS NOT NULL;

END;

PROCEDURE ImportSurveyFromXml_ (
    in_xml					IN	quick_survey_version.question_xml%TYPE,
	in_overwrite_existing	IN	NUMBER,
	in_overwrite_survey_sid	IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_name					IN  security_pkg.T_SO_NAME DEFAULT NULL,
	in_label				IN  quick_survey_version.label%TYPE DEFAULT NULL,
	in_audience				IN  quick_survey.audience%TYPE DEFAULT 'everyone',
	in_parent_sid			IN	security.security_pkg.T_SID_ID DEFAULT NULL,
	in_lookup_key			IN	quick_survey.lookup_key%TYPE DEFAULT NULL,
	out_survey_sid          OUT security.security_pkg.T_SID_ID
)
AS
	v_doc							DBMS_XMLDOM.DOMDocument;
	v_nl							DBMS_XMLDOM.DOMNodeList;
	v_nl2							DBMS_XMLDOM.DOMNodeList;
	v_nl_cust_fields				DBMS_XMLDOM.DOMNodeList;
	v_nl_cust_field_opts			DBMS_XMLDOM.DOMNodeList;
	v_n								DBMS_XMLDOM.DOMNode;
	v_n2							DBMS_XMLDOM.DOMNode;
	v_n3							DBMS_XMLDOM.DOMNode;
	v_n4							DBMS_XMLDOM.DOMNode;
	v_final	 						XMLTYPE;
	v_id							NUMBER(10);
	v_custom_type_id				qs_custom_question_type.custom_question_type_id%TYPE;
	v_custom_js_class				qs_custom_question_type.js_class%TYPE;
	v_type_class					quick_survey_type.cs_class%TYPE;
	v_type_id						quick_survey_type.quick_survey_type_id%TYPE;

	-- expression stuff
	v_actions						DBMS_XMLDOM.DOMNode;
	v_expr							quick_survey_expr.expr%TYPE;
	v_expr_id						quick_survey_expr.expr_id%TYPE;
	v_expr_question_id				quick_survey_expr.question_id%TYPE;
	v_expr_question_option_id		quick_survey_expr.question_option_id%TYPE;
	v_question_id					quick_survey_question.question_id%TYPE;
	v_msg							qs_expr_msg_action.msg%TYPE;
	v_css_class						qs_expr_msg_action.css_class%TYPE;
	v_title							qs_expr_non_compl_action.title%TYPE;
	v_due_dtm_abs					qs_expr_non_compl_action.due_dtm_abs%TYPE;
	v_due_dtm_abs_str				VARCHAR2(50);
	v_due_dtm_relative				qs_expr_non_compl_action.due_dtm_relative%TYPE;
	v_due_dtm_relative_unit			qs_expr_non_compl_action.due_dtm_relative_unit%TYPE;
	v_detail						qs_expr_non_compl_action.detail%TYPE;
	v_send_email_on_creation		qs_expr_non_compl_action.send_email_on_creation%TYPE;
	v_non_comp_default_id			qs_expr_non_compl_action.non_comp_default_id%TYPE;
	v_non_compliance_type_id		qs_expr_non_compl_action.non_compliance_type_id%TYPE;
	v_assign_to_role_sid			security_pkg.T_SID_ID;
	v_assign_to_role_name			role.name%TYPE;
	v_involve_role_sids				security_pkg.T_SID_IDS;
	v_empty_sids					security_pkg.T_SID_IDS;
	v_involve_role_names			VARCHAR2(2000);
	-- issues expression stuff - cripes!
	v_issue_label					issue_template.label%TYPE;
	v_issue_desc					issue_template.description%TYPE;
	v_assign_to_user_name			csr_user.full_name%TYPE;
	v_assign_to_user_sid			security_pkg.T_SID_ID;
	v_issue_is_critical				issue_template.is_critical%TYPE;
	v_issue_is_urgent				issue_template.is_urgent%TYPE;
	v_issue_type_id					issue_template.issue_type_id%TYPE;
	v_custom_field_label			issue_custom_field.label%TYPE;
	v_custom_field_id				issue_custom_field.issue_custom_field_id%TYPE;
	v_custom_field_str_val			issue_template_custom_field.string_value%TYPE;
	v_custom_field_date_val_str		VARCHAR2(50);
	v_custom_field_date_val			issue_template_custom_field.date_value%TYPE;
	v_option_ids					security_pkg.T_SID_IDS;
	v_option_label					VARCHAR2(2000);
	v_option_id						issue_custom_field_option.issue_custom_field_opt_id%TYPE;
BEGIN
	v_doc := dbms_xmldom.newdomdocument(in_xml);

	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//question[@type="custom"]');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);
		v_custom_js_class := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'jsClass');
		SELECT custom_question_type_id
		  INTO v_custom_type_id
		  FROM qs_custom_question_type
		 WHERE js_class = v_custom_js_class;
		DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'customTypeId', v_custom_type_id);
	END LOOP;

	v_n := dbms_xslprocessor.selectSingleNode(DBMS_XMLDOM.makeNode(v_doc),'/questions');
	v_type_class := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'surveyType');

	BEGIN
		SELECT quick_survey_type_id
		  INTO v_type_id
		  FROM quick_survey_type
		 WHERE cs_class = v_type_class;
	EXCEPTION
			WHEN no_data_found THEN
				NULL;
	END;

	-- If there was an import node, remove it as we can only use it once
	v_n2 := dbms_xslprocessor.selectSingleNode(DBMS_XMLDOM.makeNode(v_doc),'/questions/actionImport');
	IF NOT DBMS_XMLDOM.isNull(v_n2) THEN
		v_actions := DBMS_XMLDOM.REMOVECHILD(v_n, v_n2);
	END IF;


	--write back
	v_final := dbms_xmldom.getxmltype(v_doc);

	--dbms_output.put_line(v_final);
	IF in_overwrite_existing = 0 THEN
		CreateSurvey(in_name, in_label, in_audience, NULL, in_xml, in_parent_sid, NULL, v_type_id, 0, in_lookup_key, out_survey_sid);
	ELSE
		FOR r IN (
			SELECT expr_id
			  FROM quick_survey_expr
			 WHERE survey_sid = in_overwrite_survey_sid
			   AND survey_version = 0
		)
		LOOP
			DeleteExpr(r.expr_id);
		END LOOP;
		out_survey_sid := in_overwrite_survey_sid;

		UPDATE quick_survey_version
		   SET question_xml = v_final.getClobVal()
		 WHERE survey_sid = out_survey_sid
		   AND survey_version = 0;

		INTERNAL_XmlUpdated(out_survey_sid);
	END IF;

	IF NOT DBMS_XMLDOM.isNull(v_actions) THEN
		v_nl := dbms_xslprocessor.selectNodes(v_actions, 'expression');
		FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
			v_n := DBMS_XMLDOM.item(v_nl, idx);
			v_expr := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'expr');
			v_expr_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'questionId');
			v_expr_question_option_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'questionOptionId');

			BEGIN
				SELECT expr_id
				  INTO v_expr_id
				  FROM quick_survey_expr
				 WHERE survey_sid = out_survey_sid
				   AND survey_version = 0
				   AND DECODE(expr, v_expr, 1) = 1
				   AND DECODE(question_id, v_expr_question_id, 1) = 1
				   AND DECODE(question_option_id, v_expr_question_option_id, 1) = 1;
			EXCEPTION
				WHEN no_data_found THEN
					CreateExpr(out_survey_sid, v_expr, v_expr_question_id, v_expr_question_option_id, v_expr_id);
			END;

			-- messages
			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'msg');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				v_msg := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'msg');
				v_css_class := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'cssClass');

				UNSEC_CreateExprMsgAction(v_expr_id, v_msg, v_css_class, v_id);
			END LOOP;

			-- non-compliances
			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'nc');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				v_title := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'title');
				v_assign_to_role_name := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'assignToRoleName');
				v_involve_role_names := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'involveRoleNames');
				v_due_dtm_relative := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtmRelative');
				v_detail := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'detail');
				v_send_email_on_creation := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'sendEmail');
				v_non_comp_default_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'nonComplianceDefaultId');
				v_non_compliance_type_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'nonComplianceTypeId');

				IF v_due_dtm_relative IS NOT NULL THEN
					v_due_dtm_relative_unit := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtmRelativeUnit');
					v_due_dtm_abs := NULL;
				ELSE
					v_due_dtm_relative_unit := NULL;
					v_due_dtm_abs_str := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtmAbs');
					v_due_dtm_abs := TO_DATE(v_due_dtm_abs_str, 'yyyy-MM-dd');
				END IF;

				-- This will fail if the role isn't set up
				BEGIN
					SELECT role_sid
					  INTO v_assign_to_role_sid
					  FROM role
					 WHERE name = v_assign_to_role_name;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						RAISE_APPLICATION_ERROR(-20001,'Role "'||v_assign_to_role_name||'" not found');
				END;

				v_involve_role_sids := v_empty_sids; -- This clears the list, apparently?
				FOR r IN (SELECT role_sid FROM role WHERE '|'||v_involve_role_names||'|' LIKE '%|'||name||'|%') LOOP
					v_involve_role_sids(v_involve_role_sids.count+1) := r.role_sid;
				END LOOP;

				UNSEC_CreateExprNonComplAction(v_expr_id, v_title, v_due_dtm_abs, v_due_dtm_relative,
					v_due_dtm_relative_unit, v_assign_to_role_sid, v_involve_role_sids, v_detail,
					v_send_email_on_creation, v_non_comp_default_id, v_non_compliance_type_id, v_id);
			END LOOP;

			-- show questions - can only work with lookup keys or if the imported XML hasn't had its IDs stripped
			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'showQ');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'questionId');

				UNSEC_CreateExprShowQAction(v_expr_id, v_question_id, v_id);
			END LOOP;

			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'mandQ');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'questionId');

				UNSEC_CreateExprMandQAction(v_expr_id, v_question_id, v_id);
			END LOOP;

			-- show pages - can only work if the imported XML hasn't had its IDs stripped
			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'showP');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				v_question_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'questionId');

				UNSEC_CreateExprShowPAction(v_expr_id, v_question_id, v_id);
			END LOOP;
			
			-- issues - can only work if the custom fields exist and the assignee (if set) can be identified
			v_nl2 := dbms_xslprocessor.selectNodes(v_n, 'issue');
			FOR idx2 IN 0 .. DBMS_XMLDOM.getLength(v_nl2) - 1 LOOP
				v_n2 := DBMS_XMLDOM.item(v_nl2, idx2);
				
				v_due_dtm_abs := NULL;
				v_due_dtm_abs_str := NULL;
				v_due_dtm_relative := NULL;
				v_due_dtm_relative_unit := NULL;
				
				v_issue_label := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'issueLabel');
				IF v_issue_label IS NULL THEN
					RAISE_APPLICATION_ERROR(-20001,'Label is required for issue actions');
				END IF;
				v_issue_desc := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'description');
				v_assign_to_user_name := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'assignToUser');
				
				IF v_assign_to_user_name IS NOT NULL THEN
					BEGIN
						SELECT csr_user_sid
						  INTO v_assign_to_user_sid
						  FROM csr.csr_user
						 WHERE v_assign_to_user_name = full_name OR v_assign_to_user_name = friendly_name;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							RAISE_APPLICATION_ERROR(-20001,'User "'||v_assign_to_user_name||'" not found');
					END;
				END IF;
				
				v_issue_is_critical := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'isCritical');
				v_issue_is_urgent := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'isUrgent');
				v_issue_type_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'issueTypeId');
				
				v_due_dtm_relative := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtmRelative');
				IF v_due_dtm_relative IS NOT NULL THEN
					v_due_dtm_relative_unit := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtmRelativeUnit');
					v_due_dtm_abs := NULL;
				ELSE
					v_due_dtm_relative_unit := NULL;
					v_due_dtm_abs_str := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n2), 'dueDtm');
					v_due_dtm_abs := TO_DATE(v_due_dtm_abs_str, 'yyyy-MM-dd');
				END IF;

				UNSEC_CreateExprIssueAction(
					in_expr_id						=> v_expr_id,
					in_issue_type_id				=> v_issue_type_id,
					in_label						=> v_issue_label,
					in_description					=> v_issue_desc,
					in_assign_to_user_sid			=> v_assign_to_user_sid,
					in_is_urgent					=> v_issue_is_urgent,
					in_is_critical					=> v_issue_is_critical,
					in_due_dtm						=> v_due_dtm_abs,
					in_due_dtm_relative				=> v_due_dtm_relative,
					in_due_dtm_relative_unit		=> v_due_dtm_relative_unit,
					out_qs_expr_action_id			=> v_id
				);
				
				v_nl_cust_fields := dbms_xslprocessor.selectNodes(v_n2,'//customField');
				FOR idx3 IN 0 .. DBMS_XMLDOM.getLength(v_nl_cust_fields) - 1 LOOP
					v_n3 := DBMS_XMLDOM.item(v_nl_cust_fields, idx3);
					v_custom_field_label := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n3), 'label');
					BEGIN
						SELECT issue_custom_field_id
						  INTO v_custom_field_id
						  FROM issue_custom_field
						 WHERE label = v_custom_field_label;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							RAISE_APPLICATION_ERROR(-20001,'Custom field "'||v_custom_field_label||'" not found');
					END;
					v_custom_field_str_val := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n3), 'stringValue');
					
					v_custom_field_date_val_str := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n3), 'dateValue');
					IF v_custom_field_date_val_str IS NOT NULL THEN
						v_custom_field_date_val := TO_DATE(v_custom_field_date_val_str, 'yyyy-MM-dd');
					END IF;
					
					v_nl_cust_field_opts := dbms_xslprocessor.selectNodes(v_n3,'./option');
					FOR idx4 IN 0 .. DBMS_XMLDOM.getLength(v_nl_cust_field_opts) - 1 LOOP
						v_n4 := DBMS_XMLDOM.item(v_nl_cust_field_opts, idx4);
						v_option_label := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n4), 'value');
						BEGIN
							SELECT issue_custom_field_opt_id
							  INTO v_option_id
							  FROM issue_custom_field_option
							 WHERE label = v_option_label
							   AND issue_custom_field_id = v_custom_field_id;
						EXCEPTION
							WHEN NO_DATA_FOUND THEN
								RAISE_APPLICATION_ERROR(-20001,'Custom field option "'||v_option_label||'" not found');
						END;
						v_option_ids(idx4) := v_option_id;
					END LOOP;
					
					UNSEC_SetIssueActionCustFld (
						in_qs_expr_action_id			=> v_id,
						in_issue_custom_field_id		=> v_custom_field_id,
						in_string_value					=> v_custom_field_str_val,
						in_date_value					=> v_custom_field_date_val,
						in_option_ids					=> v_option_ids
					);
				END LOOP;
			END LOOP;
		END LOOP;
	END IF;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = out_survey_sid;

	-- Free any resources associated with the document now it
	-- is no longer needed.
	DBMS_XMLDOM.FreeDocument(v_doc);
EXCEPTION
	WHEN OTHERS THEN
		DBMS_XMLDOM.freeDocument(v_doc);
		RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
END;

PROCEDURE ImportSurvey(
    in_xml					IN	quick_survey_version.question_xml%TYPE,
	in_name					IN  security_pkg.T_SO_NAME,
	in_label				IN  quick_survey_version.label%TYPE,
	in_audience				IN  quick_survey.audience%TYPE DEFAULT 'everyone',
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_lookup_key			IN	quick_survey.lookup_key%TYPE DEFAULT NULL,
	out_survey_sid          OUT security.security_pkg.T_SID_ID
)
AS
BEGIN
	ImportSurveyFromXml_(
		in_xml => in_xml,
		in_overwrite_existing => 0,
		in_name => in_name,
		in_label => in_label,
		in_audience => in_audience,
		in_parent_sid => in_parent_sid,
		in_lookup_key => in_lookup_key,
		out_survey_sid => out_survey_sid
	);
END;

PROCEDURE OverwriteSurvey(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_xml				IN	quick_survey_version.question_xml%TYPE
)
AS
	v_survey_sid		security_pkg.T_SID_ID;
	v_user_sid			security.security_pkg.T_SID_ID;
BEGIN
	ImportSurveyFromXml_(
		in_xml => in_xml,
		in_overwrite_existing => 1,
		in_overwrite_survey_sid => in_survey_sid,
		out_survey_sid => v_survey_sid
	);

	security.user_pkg.GetSid(security.security_pkg.GetAct, v_user_sid);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_sid,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE,
		in_app_sid => security.security_pkg.GetApp,
		in_object_sid => v_survey_sid,
		in_description => 'Overwritten survey'
	);
END;

-- strip IDs
FUNCTION StripIDs(
	in_doc							IN XMLType
) RETURN XMLType
AS
	v_doc							DBMS_XMLDOM.DOMDocument;
	v_nl							DBMS_XMLDOM.DOMNodeList;
	v_n								DBMS_XMLDOM.DOMNode;
	v_final_doc						XMLType;
BEGIN

	-- Parse the document and create a new DOM document.
	v_doc := dbms_xmldom.newDOMDocument(in_doc);

	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//*[@id]');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);
		DBMS_XMLDOM.REMOVEATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');
	END LOOP;

	-- write back
	v_final_doc := dbms_xmldom.getxmltype(v_doc);

	-- Free any resources associated with the document now it
	-- is no longer needed.
	DBMS_XMLDOM.FreeDocument(v_doc);
    RETURN v_final_doc;

EXCEPTION
	WHEN OTHERS THEN
		DBMS_XMLDOM.freeDocument(v_doc);
		RAISE;
END;

PROCEDURE INTERNAL_AddTempQuestionXml(
	in_id					IN  question.question_id%TYPE,
	in_node     			IN	DBMS_XMLDOM.DOMNode
)
AS
	v_doc					DBMS_XMLDOM.DOMDocument;
	v_node					DBMS_XMLDOM.DOMNode;
	v_cnl					DBMS_XMLDOM.DOMNodeList;
	v_cn					DBMS_XMLDOM.DOMNode;
	v_null					DBMS_XMLDOM.DOMNode;
	v_xml					CLOB;
BEGIN
	-- in_node is referenced elsewhere, create a deep copy of it first
	v_doc := DBMS_XMLDOM.newDOMDocument;
	v_node := DBMS_XMLDOM.importNode(v_doc, in_node, TRUE);

	-- pull out any child nodes which are questions themselves
	v_cnl := dbms_xslprocessor.selectNodes(v_node,'question|pageBreak|section|checkbox|radioRow');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_cnl) - 1 LOOP
		v_cn := DBMS_XMLDOM.item(v_cnl, idx);
		v_null := DBMS_XMLDOM.removeChild(in_node, v_cn);
	END LOOP;
			
	DBMS_LOB.CreateTemporary(v_xml, TRUE);
	DBMS_XMLDOM.writeToClob(v_node, v_xml);

	INSERT INTO temp_question_xml (id, xml)
	VALUES (in_id, v_xml);

	DBMS_LOB.FreeTemporary(v_xml);
	DBMS_XMLDOM.FreeDocument(v_doc);
END;

PROCEDURE CopySurvey(
	in_copy_survey_sid				IN  security_pkg.T_SID_ID,
	in_new_parent_sid				IN  security_pkg.T_SID_ID,
	in_name							IN  security_pkg.T_SO_NAME,
	in_label						IN  quick_survey_version.label%TYPE,
	out_survey_sid          		OUT security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_user_sid						security.security_pkg.T_SID_ID;
	v_wwwroot						security_pkg.T_SID_ID;
	v_wwwroot_surveys				security_pkg.T_SID_ID;
	v_parent_sid					security_pkg.T_SID_ID;
	v_xml							CLOB;
	v_audience						quick_survey.audience%TYPE;
	v_name							security_pkg.T_SO_NAME DEFAULT in_name;

	-- For setting the IDs of the questions / options
	v_doc							DBMS_XMLDOM.DOMDocument;
	v_nl							DBMS_XMLDOM.DOMNodeList;
	v_n								DBMS_XMLDOM.DOMNode;
	v_id							NUMBER(10);
	v_new_id						NUMBER(10);
	v_old_id						NUMBER(10);
	v_is_survey_q					NUMBER(10);

	-- For copying expressions
	v_expr_id						quick_survey_expr.expr_id%TYPE;
	v_qs_expr_non_compl_action_id	qs_expr_non_compl_action.qs_expr_non_compl_action_id%TYPE;
	v_qs_expr_msg_action_id			qs_expr_msg_action.qs_expr_msg_action_id%TYPE;
	v_issue_template_id				issue_template.issue_template_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_copy_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey');
	END IF;

	v_wwwroot := securableobject_pkg.GetSIDFromPath(v_act, security.security_pkg.GetApp, 'wwwroot');
	v_wwwroot_surveys := securableobject_pkg.GetSIDFromPath(v_act, v_wwwroot, 'surveys');

	IF v_name IS NULL THEN
		GetRandomSOName(in_new_parent_sid, v_name);
	END IF;
	-- create our object as a web resource
	web_pkg.CreateResource(v_act, v_wwwroot, v_wwwroot_surveys, v_name, class_pkg.GetClassId('csrquicksurvey'),
		'/csr/site/quicksurvey/public/view.acds?sid={sid}',
		out_survey_sid);

	IF v_wwwroot_surveys <> in_new_parent_sid THEN
		security.securableObject_pkg.MoveSO(v_act, out_survey_sid, in_new_parent_sid);
	END IF;

	-- strip the IDs before saving to reduce chance of confusion
	INSERT INTO quick_survey
		(survey_sid, audience, quick_survey_type_id, last_modified_dtm)
		SELECT out_survey_sid, audience, quick_survey_type_id, SYSDATE
		  FROM quick_survey
		 WHERE survey_sid = in_copy_survey_sid;

	INSERT INTO quick_survey_version (survey_sid, survey_version, label, question_xml, start_dtm, end_dtm)
	SELECT out_survey_sid, 0, in_label, question_xml, start_dtm, end_dtm
	  FROM quick_survey_version
	 WHERE survey_sid = in_copy_survey_sid
	   AND survey_version = 0;

	INSERT INTO quick_survey_lang (survey_sid, lang)
	SELECT out_survey_sid, lang
	  FROM quick_survey_lang
	 WHERE survey_sid = in_copy_survey_sid;

	SELECT audience
	  INTO v_audience
	  FROM quick_survey
	 WHERE survey_sid = in_copy_survey_sid;

	-- force the permissions
	UNSEC_SetAudience(out_survey_sid, v_audience, 1);

	SELECT question_xml
	  INTO v_xml
	  FROM quick_survey_version
	 WHERE survey_sid = out_survey_sid
	   AND survey_version = 0;

	v_doc := dbms_xmldom.newDOMDocument(v_xml);

	-- Set new question_ids in the XML
	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//question|//pageBreak|//question/checkbox|//section|//question/radioRow');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);
		v_old_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');
		IF v_old_id IS NOT NULL THEN
			-- is this a question library question or a survey question?
			SELECT owned_by_survey_sid
			  INTO v_is_survey_q
			  FROM question
			 WHERE question_id = v_old_id;
			
			IF v_is_survey_q IS NULL THEN
				-- keep the reference to the same question in the new survey
				v_id := v_old_id;
			ELSE
				-- copy the question as well
				INSERT INTO map_id (old_id, new_id)
				VALUES (v_old_id, question_id_seq.nextval)
				RETURNING new_id INTO v_id;
				
				INTERNAL_AddTempQuestionXml(v_id, v_n);
			END IF;
		ELSE
			SELECT question_id_seq.nextval
			  INTO v_id
			  FROM dual;
			  
			INTERNAL_AddTempQuestionXml(v_id, v_n);
		END IF;
		DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id', v_id);
	END LOOP;

	-- Set new question_option_ids
	-- XXX: Mapping using map_id but with negative numbers to avoid ID colissions
	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//question/option|//question/columnHeader');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);
		v_old_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id');
		IF v_old_id IS NOT NULL THEN
			INSERT INTO map_id (old_id, new_id)
			VALUES (-v_old_id, -qs_question_option_id_seq.nextval)
			RETURNING -new_id INTO v_id;

			INTERNAL_AddTempQuestionXml(v_id, v_n);
		ELSE
			SELECT qs_question_option_id_seq.nextval
			  INTO v_id
			  FROM dual;

			INTERNAL_AddTempQuestionXml(v_id, v_n);
		END IF;
		DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'id', v_id);
	END LOOP;

	-- XXX: With mapped IDs, if there are any references, then update those IDs
	v_nl := dbms_xslprocessor.selectNodes(DBMS_XMLDOM.makeNode(v_doc),'//scoreOverride');
	FOR idx IN 0 .. DBMS_XMLDOM.getLength(v_nl) - 1 LOOP
		v_n := DBMS_XMLDOM.item(v_nl, idx);

		BEGIN
			v_old_id := DBMS_XMLDOM.GETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'columnId');
			SELECT -new_id
			  INTO v_new_id
			  FROM map_id
			 WHERE old_id = -v_old_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001,'Could not find scoreOverride column. old_id: '||v_old_id);
		END;

		DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'columnId', v_new_id);
	END LOOP;

	-- write back
	v_xml := dbms_xmldom.getxmltype(v_doc).getClobVal();

	-- this wont' work if we start to cross reference the IDs
	-- in the XML more, e.g. "x is conditional on y"

	-- all mapped questions are new, therefore question_version 0
	
	-- Copy survey questions: new questions will start from version 0, but copy from the max non-draft version
	INSERT INTO question (
		question_id, question_type, lookup_key, owned_by_survey_sid, latest_question_version, latest_question_draft
	)
	SELECT miq.new_id, q.question_type, q.lookup_key, out_survey_sid, 0, 0
	  FROM question q
	  JOIN map_id miq ON q.question_id = miq.old_id
	 WHERE q.owned_by_survey_sid = in_copy_survey_sid;
	
	INSERT INTO question_version (
		question_id, question_draft, question_version, parent_id, parent_draft, parent_version, pos,
		score, max_score, upload_score,	weight, dont_normalise_score, has_score_expression, 
		has_max_score_expr,	remember_answer, count_question, label, action, question_xml
	)
	SELECT miq.new_id, 0, 0, mip.new_id, 0, 0, qv.pos,
		qv.score, qv.max_score, qv.upload_score, qv.weight, qv.dont_normalise_score, qv.has_score_expression,
		qv.has_max_score_expr, qv.remember_answer, qv.count_question, qv.label, qv.action, qx.xml
	  FROM question_version qv
	  JOIN map_id miq ON qv.question_id = miq.old_id
	  JOIN temp_question_xml qx ON qx.id = miq.new_id
	  LEFT JOIN map_id mip ON qv.parent_id = mip.old_id
	 WHERE (qv.question_id, qv.question_version) IN (
			SELECT qvi.question_id, MAX(qvi.question_version)
			  FROM question_version qvi
			 WHERE qvi.question_id = qv.question_id
			   AND qvi.question_draft = 0
			 GROUP BY qvi.question_id
	   );
	
	INSERT INTO question_option
		(question_id, question_option_id, pos, label, score, lookup_key,
		 option_action, color, non_compliance_popup, non_comp_default_id, non_compliance_type_id,
		 non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_draft, question_version, question_option_xml)
		SELECT miq.new_id, -miqo.new_id, qso.pos, qso.label, qso.score, qso.lookup_key,
			   qso.option_action, qso.color, qso.non_compliance_popup, qso.non_comp_default_id,
			   qso.non_compliance_type_id, qso.non_compliance_label, non_compliance_detail,
			   non_comp_root_cause, non_comp_suggested_action, 0, 0, qx.xml
		  FROM qs_question_option qso
		  JOIN map_id miq ON qso.question_id = miq.old_id
		  JOIN map_id miqo ON -qso.question_option_id = miqo.old_id
		  JOIN temp_question_xml qx ON qx.id = -miqo.new_id
		  JOIN quick_survey_question qsq ON qso.question_id = qsq.question_id AND qso.survey_version = qsq.survey_version
		 WHERE qsq.survey_sid = in_copy_survey_sid
		   AND qso.is_visible = 1
		   AND qsq.survey_version = 0;
	
	-- Copy survey questions
	INSERT INTO quick_survey_question
		(question_id, parent_id, survey_sid, pos, is_visible, label, question_type, score, max_score, upload_score, lookup_key, custom_question_type_id, weight, survey_version,
			remember_answer, count_question, action, question_version, question_draft, parent_version)
		SELECT miq.new_id, mip.new_id, out_survey_sid, qsq.pos, 1, qsq.label, qsq.question_type, qsq.score, qsq.max_score, qsq.upload_score, qsq.lookup_key,
			qsq.custom_question_type_id, qsq.weight, 0, remember_answer, count_question, action, question_version, 0, parent_version
		  FROM quick_survey_question qsq
		  JOIN map_id miq ON qsq.question_id = miq.old_id
		  LEFT JOIN map_id mip ON qsq.parent_id = mip.old_id
		 WHERE qsq.survey_sid = in_copy_survey_sid
		   AND qsq.is_visible = 1
		   AND qsq.survey_version = 0;

	INSERT INTO qs_question_option
		(question_id, question_option_id, pos, is_visible, label, score, lookup_key,
		 option_action, color, non_compliance_popup, non_comp_default_id, non_compliance_type_id,
		 non_compliance_label, non_compliance_detail, non_comp_root_cause, non_comp_suggested_action,
		 survey_version, question_version, survey_sid)
		SELECT miq.new_id, -miqo.new_id, qso.pos, 1, qso.label, qso.score, qso.lookup_key,
			   qso.option_action, qso.color, qso.non_compliance_popup, qso.non_comp_default_id,
			   qso.non_compliance_type_id, qso.non_compliance_label, non_compliance_detail,
			   non_comp_root_cause, non_comp_suggested_action, 0, 0, out_survey_sid
		  FROM qs_question_option qso
		  JOIN map_id miq ON qso.question_id = miq.old_id
		  JOIN map_id miqo ON -qso.question_option_id = miqo.old_id
		  JOIN quick_survey_question qsq ON qso.question_id = qsq.question_id AND qso.survey_version = qsq.survey_version
		 WHERE qsq.survey_sid = in_copy_survey_sid
		   AND qso.is_visible = 1
		   AND qsq.survey_version = 0;

	INSERT INTO qs_question_option_nc_tag (question_id, question_option_id, tag_id, survey_version, question_version, survey_sid)
		SELECT miq.new_id, -miqo.new_id, qsqot.tag_id,  0, 0, out_survey_sid
		  FROM qs_question_option_nc_tag qsqot
		  JOIN map_id miq ON qsqot.question_id = miq.old_id
		  JOIN map_id miqo ON -qsqot.question_option_id = miqo.old_id
		  JOIN quick_survey_question qsq ON qsqot.question_id = qsq.question_id AND qsqot.survey_version = qsq.survey_version
		  JOIN qs_question_option qso ON qsqot.question_id = qso.question_id AND qsqot.question_option_id = qso.question_option_id 
		   AND qsqot.survey_version = qso.survey_version
		 WHERE qsq.survey_sid = in_copy_survey_sid
		   AND qso.is_visible = 1
		   AND qsq.survey_version = 0;

	INSERT INTO quick_survey_question_tag (question_id, tag_id, survey_version, survey_sid, question_version)
		SELECT miq.new_id, qsqt.tag_id,  0, out_survey_sid, 0
		  FROM quick_survey_question_tag qsqt
		  JOIN map_id miq ON qsqt.question_id = miq.old_id
		  JOIN quick_survey_question qsq ON qsqt.question_id = qsq.question_id AND qsqt.survey_version = qsq.survey_version
		 WHERE qsq.survey_sid = in_copy_survey_sid
		   AND qsq.survey_version = 0;

	UPDATE quick_survey_version
	   SET question_xml = v_xml
	 WHERE survey_sid = out_survey_sid
	   AND survey_version = 0;

	DBMS_XMLDOM.FreeDocument(v_doc);

	-- copy expressions / actions
	FOR r IN (
		SELECT qse.expr_id, qse.expr, mq.new_id question_id, -mqo.new_id question_option_id
		  FROM quick_survey_expr qse
		  LEFT JOIN map_id mq ON qse.question_id = mq.old_id
		  LEFT JOIN map_id mqo ON -qse.question_option_id = mqo.old_id
		 WHERE survey_sid = in_copy_survey_sid
		   AND survey_version = 0
	) LOOP
		INSERT INTO quick_survey_expr (survey_sid, expr_id, expr, question_id, question_option_id, survey_version, question_version)
		VALUES (out_survey_sid, expr_id_seq.nextval, r.expr, r.question_id, r.question_option_id, 0, 0)
		RETURNING expr_id INTO v_expr_id;

		-- Non-compliance actions
		FOR nc IN (
			SELECT assign_to_role_sid, due_dtm_abs, due_dtm_relative, due_dtm_relative_unit, title,
				   nc.qs_expr_non_compl_action_id, detail, send_email_on_creation, non_comp_default_id,
				   non_compliance_type_id
			  FROM quick_survey_expr_action ea
			  JOIN qs_expr_non_compl_action nc ON ea.qs_expr_non_compl_action_id = nc.qs_expr_non_compl_action_id
			 WHERE ea.survey_sid = in_copy_survey_sid
			   AND ea.expr_id = r.expr_id
			   AND ea.survey_version = 0
		) LOOP
			INSERT INTO qs_expr_non_compl_action (qs_expr_non_compl_action_id, assign_to_role_sid, due_dtm_abs,
				due_dtm_relative, due_dtm_relative_unit, title, detail, send_email_on_creation, non_comp_default_id,
				non_compliance_type_id)
			VALUES (qs_expr_nc_action_id_seq.nextval, nc.assign_to_role_sid, nc.due_dtm_abs, nc.due_dtm_relative,
				nc.due_dtm_relative_unit, nc.title, nc.detail, nc.send_email_on_creation, nc.non_comp_default_id,
				nc.non_compliance_type_id)
			RETURNING qs_expr_non_compl_action_id INTO v_qs_expr_non_compl_action_id;

			INSERT INTO qs_expr_nc_action_involve_role(qs_expr_non_compl_action_id, involve_role_sid)
			SELECT v_qs_expr_non_compl_action_id, involve_role_sid
			  FROM qs_expr_nc_action_involve_role
			 WHERE qs_expr_non_compl_action_id = nc.qs_expr_non_compl_action_id;

			INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, qs_expr_non_compl_action_id, survey_version)
			VALUES (qs_expr_action_id_seq.nextval, 'nc', out_survey_sid, v_expr_id, v_qs_expr_non_compl_action_id, 0);
		END LOOP;
		
		-- Issue actions
		FOR iss IN (
			SELECT it.issue_template_id, issue_type_id, label, description, assign_to_user_sid, is_urgent, is_critical,
				due_dtm_relative, due_dtm_relative_unit
			  FROM quick_survey_expr_action ea
			  JOIN issue_template it ON ea.issue_template_id = it.issue_template_id
			 WHERE ea.survey_sid = in_copy_survey_sid
			   AND ea.expr_id = r.expr_id
			   AND ea.survey_version = 0
		) LOOP
			INSERT INTO issue_template (issue_template_id, issue_type_id, label, description, assign_to_user_sid, is_urgent, is_critical,
				due_dtm_relative, due_dtm_relative_unit)
			VALUES (issue_template_id_seq.nextval, iss.issue_type_id, iss.label, iss.description, iss.assign_to_user_sid, iss.is_urgent, iss.is_critical,
				iss.due_dtm_relative, iss.due_dtm_relative_unit)
			RETURNING issue_template_id INTO v_issue_template_id;

			INSERT INTO issue_template_custom_field (issue_template_id, issue_custom_field_id, string_value, date_value)
			SELECT v_issue_template_id, issue_custom_field_id, string_value, date_value
			  FROM issue_template_custom_field
			 WHERE issue_template_id = iss.issue_template_id;

			INSERT INTO issue_template_cust_field_opt (issue_template_id, issue_custom_field_id, issue_custom_field_opt_id)
			SELECT v_issue_template_id, issue_custom_field_id, issue_custom_field_opt_id
			  FROM issue_template_cust_field_opt
			 WHERE issue_template_id = iss.issue_template_id;

			INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, issue_template_id, survey_version)
			VALUES (qs_expr_action_id_seq.nextval, 'issue', out_survey_sid, v_expr_id, v_issue_template_id, 0);
		END LOOP;

		-- Message actions
		FOR msg IN (
			SELECT msg, css_Class
			  FROM quick_survey_expr_action ea
			  JOIN qs_expr_msg_action msg ON ea.qs_expr_msg_action_id = msg.qs_expr_msg_action_id
			 WHERE ea.survey_sid = in_copy_survey_sid
			   AND ea.expr_id = r.expr_id
			   AND ea.survey_version = 0
		) LOOP
			INSERT INTO qs_expr_msg_action (qs_expr_msg_action_id, msg, css_class)
			VALUES (qs_expr_msg_action_id_seq.nextval, msg.msg, msg.css_class)
			RETURNING qs_expr_msg_action_id INTO v_qs_expr_msg_action_id;

			INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, qs_expr_msg_action_id, survey_version)
			VALUES (qs_expr_action_id_seq.nextval, 'msg', out_survey_sid, v_expr_id, v_qs_expr_msg_action_id, 0);
		END LOOP;

		INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, show_question_id, survey_version)
		SELECT qs_expr_action_id_seq.nextval, 'show_q', out_survey_sid, v_expr_id, map.new_id, 0
		  FROM quick_survey_expr_action ea
		  JOIN map_id map ON ea.show_question_id = map.old_id
		 WHERE ea.survey_sid = in_copy_survey_sid
		   AND ea.expr_id = r.expr_id
		   AND ea.survey_version = 0;

		INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, mandatory_question_id, survey_version)
		SELECT qs_expr_action_id_seq.nextval, 'mand_q', out_survey_sid, v_expr_id, map.new_id, 0
		  FROM quick_survey_expr_action ea
		  JOIN map_id map ON ea.mandatory_question_id = map.old_id
		 WHERE ea.survey_sid = in_copy_survey_sid
		   AND ea.expr_id = r.expr_id
		   AND ea.survey_version = 0;

		INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, show_page_id, survey_version)
		SELECT qs_expr_action_id_seq.nextval, 'show_p', out_survey_sid, v_expr_id, map.new_id, 0
		  FROM quick_survey_expr_action ea
		  JOIN map_id map ON ea.show_page_id = map.old_id
		 WHERE ea.survey_sid = in_copy_survey_sid
		   AND ea.expr_id = r.expr_id
		   AND ea.survey_version = 0;
	END LOOP;

	security.user_pkg.GetSid(v_act, v_user_sid);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_sid,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE,
		in_app_sid => security.security_pkg.GetApp,
		in_object_sid => out_survey_sid,
		in_description => 'Created survey'
	);
END;

PROCEDURE TrashSurvey(
	in_survey_sid					IN security_pkg.T_SID_ID
)
AS
	v_act							security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_description					quick_survey_version.label%TYPE;
	v_audience						quick_survey.audience%TYPE;
BEGIN
	-- set closed dtm if it's not already closed
	UPDATE quick_survey_version
	   SET end_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid
	   AND end_dtm IS NULL
	   AND survey_version IN (SELECT current_version FROM quick_survey WHERE survey_sid = in_survey_sid);

	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_survey_sid,
		'Moved to trash');

	-- hmm row will still exist in web_resource table
	-- XXX: this is nasty but we need to get the row out of the web_resource table otherwise
	-- we'll get dup key constraint violations. When we untrash we'll need to work some
	-- magic to get a row back into the web_resource table.
	security.web_pkg.DeleteObject(v_act, in_survey_sid);

	SELECT label, audience
	  INTO v_description, v_audience
	  FROM v$quick_survey
	 WHERE survey_sid = in_survey_sid;

	IF v_audience like 'chain%' THEN
		supplier_pkg.UnmakeChainSurvey(in_survey_sid);
	END IF;

	trash_pkg.TrashObject(v_act, in_survey_sid,
		securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Trash'),
		v_description);
END;

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
)
AS
	v_act							security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_class_id						security_pkg.T_CLASS_ID;
BEGIN
	v_class_id := class_pkg.GetClassId('CSRQuickSurvey');

	FOR r IN (
		SELECT t.trash_sid, t.so_name
		  FROM trash t, security.securable_object so
		 WHERE t.trash_sid IN (SELECT column_value FROM TABLE(in_object_sids))
		   AND t.trash_sid = so.sid_id
		   AND so.class_id = v_class_id
	) LOOP
		RecreateQuickSurveyWebRes(r.trash_sid, r.so_name, v_class_id);

		csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, r.trash_sid,
			'Restored from trash');

		UPDATE quick_survey_version
		   SET end_dtm = NULL
		 WHERE survey_sid = r.trash_sid
		   AND end_dtm IS NOT NULL
		   AND survey_version IN (SELECT current_version FROM quick_survey WHERE survey_sid = r.trash_sid);
	END LOOP;
END;

PROCEDURE AmendSurvey(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_name				IN  security_pkg.T_SO_NAME,
	in_label			IN  quick_survey_version.label%TYPE,
	in_audience			IN  quick_survey.audience%TYPE,
	in_group_key		IN	quick_survey.group_key%TYPE,
	in_question_xml		IN  quick_survey_version.question_xml%TYPE,
	in_score_type_id	IN	quick_survey.score_type_id%TYPE,
	in_survey_type_id	IN	quick_survey_type.quick_survey_type_id%TYPE,
	in_lookup_key		IN	quick_survey.lookup_key%TYPE
)
AS
	v_act			security.security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY','ACT');
	v_user_sid		security.security_pkg.T_SID_ID;
	v_name			security_pkg.T_SO_NAME DEFAULT in_name;
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(v_act, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey');
	END IF;

	UPDATE quick_survey_version
	   SET label = in_label,
		   question_xml = in_question_xml
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0;

	UPDATE quick_survey
	   SET score_type_id = in_score_type_id,
		   quick_survey_type_id = in_survey_type_id,
		   group_key = in_group_key,
		   lookup_key = in_lookup_key
	 WHERE survey_sid = in_survey_sid;

    UNSEC_SetAudience(in_survey_sid, in_audience);

	IF v_name IS NULL THEN
		v_parent_sid := security.securableObject_pkg.GetParent(v_act, in_survey_sid);
		GetRandomSOName(v_parent_sid, v_name);
	END IF;

	securableobject_pkg.renameSO(v_act, in_survey_sid, v_name);

	IF in_audience like 'chain%' THEN
		chain.questionnaire_pkg.RenameQuestionnaireType(in_survey_sid, in_label);
	END IF;

	INTERNAL_XmlUpdated(in_survey_sid);

	security.user_pkg.GetSid(v_act, v_user_sid);

	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_sid,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE,
		in_app_sid => security.security_pkg.GetApp,
		in_object_sid => in_survey_sid,
		in_description => 'Saved survey'
	);
END;

FUNCTION GetResponseAccess(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE
) RETURN NUMBER
AS
	v_survey_sid					security_pkg.T_SID_ID;
	v_user_sid						security_pkg.T_SID_ID;
	v_audit_sid						security_pkg.T_SID_ID;
	v_summary_audit_sid				security_pkg.T_SID_ID;
	v_secondary_audit_sid			security_pkg.T_SID_ID;
	v_survey_capability_id			customer_flow_capability.flow_capability_id%TYPE;
	v_is_flow_audit					BOOLEAN := FALSE;
	v_audience						quick_survey.audience%TYPE;
	v_supplier_sid					security_pkg.T_SID_ID;
	v_component_id  				supplier_survey_response.component_id%TYPE;
	v_flow_item_id					flow_item.flow_item_id%TYPE;
	v_flow_item_is_editable			NUMBER;
	v_has_read_all_results			BOOLEAN := FALSE;
	v_flow_alert_class				flow.flow_alert_class%TYPE;
	v_response_perm					NUMBER;
BEGIN
	BEGIN
		SELECT qsr.survey_sid, qsr.user_sid, qs.audience,
			   ia.internal_audit_sid, sia.internal_audit_sid, ias.internal_audit_sid, iatsg.survey_capability_id,
			   ssr.supplier_sid, ssr.component_id, fi.flow_item_id, f.flow_alert_class
		  INTO v_survey_sid, v_user_sid, v_audience,
			   v_audit_sid, v_summary_audit_sid, v_secondary_audit_sid, v_survey_capability_id,
			   v_supplier_sid, v_component_id, v_flow_item_id, v_flow_alert_class
		  FROM quick_survey_response qsr
		  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid AND qsr.app_sid = qs.app_sid
		  LEFT JOIN supplier_survey_response ssr ON qsr.survey_response_id = ssr.survey_response_id AND qsr.app_sid = ssr.app_sid
		  LEFT JOIN flow_item fi ON fi.survey_response_id = qsr.survey_response_id AND fi.app_sid = qsr.app_sid
		  LEFT JOIN flow f ON f.flow_sid = fi.flow_sid AND f.app_sid = fi.app_sid
		  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id AND ia.app_sid = qsr.app_sid
		  LEFT JOIN internal_audit sia ON sia.summary_response_id = qsr.survey_response_id AND sia.app_sid = qsr.app_sid
		  LEFT JOIN internal_audit_survey ias ON ias.survey_response_id = qsr.survey_response_id AND ias.app_sid = qsr.app_sid
		  LEFT JOIN internal_audit_type_survey iats ON iats.internal_audit_type_survey_id = ias.internal_audit_type_survey_id AND iats.app_sid = ias.app_sid
		  LEFT JOIN ia_type_survey_group iatsg ON iatsg.ia_type_survey_group_id = iats.ia_type_survey_group_id AND iatsg.app_sid = iats.app_sid
		 WHERE qsr.survey_response_Id = in_response_id
		   AND qsr.hidden = 0;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Response id '||in_response_id||' not found');
	END;

	IF security_pkg.getSid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		-- Batch jobs always have write access
		RETURN security_pkg.PERMISSION_WRITE;
	END IF;

	IF security_pkg.getSid = security_pkg.SID_BUILTIN_GUEST THEN
		-- We can't just let anonymous users view another anonymous user's reponse just
		-- because they can guess a sequential number. We'll have to use CheckGuidAccess instead
		RETURN 0;
	END IF;

	-- check if the survey is editable and check the relevant audit perms
	IF v_audit_sid IS NOT NULL THEN
		v_is_flow_audit := audit_pkg.IsFlowAudit(v_audit_sid);

		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_audit_sid) > 1) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security_pkg.PERMISSION_WRITE))) THEN
			RETURN security_pkg.PERMISSION_WRITE;
		END IF;
		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_audit_sid) > 0) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_SURVEY, security_pkg.PERMISSION_READ))) THEN
			RETURN security_pkg.PERMISSION_READ;
		END IF;
		RETURN 0;
	END IF;

	-- check if the summary survey is editable and check the relevant audit perms
	IF v_summary_audit_sid IS NOT NULL THEN
		v_is_flow_audit := audit_pkg.IsFlowAudit(v_summary_audit_sid);

		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_summary_audit_sid) > 1) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_summary_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, security_pkg.PERMISSION_WRITE))) THEN
			RETURN security_pkg.PERMISSION_WRITE;
		END IF;
		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_summary_audit_sid) > 0) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_summary_audit_sid, csr_data_pkg.FLOW_CAP_AUDIT_EXEC_SUMMARY, security_pkg.PERMISSION_READ))) THEN
			RETURN security_pkg.PERMISSION_READ;
		END IF;
		RETURN 0;
	END IF;

	-- check if the secondary survey is editable and check the relevant audit perms
	IF v_secondary_audit_sid IS NOT NULL THEN
		v_is_flow_audit := audit_pkg.IsFlowAudit(v_secondary_audit_sid);

		IF v_survey_capability_id IS NULL THEN
			v_survey_capability_id := csr_data_pkg.FLOW_CAP_AUDIT_SURVEY;
		END IF;

		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_secondary_audit_sid) > 1) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_secondary_audit_sid, v_survey_capability_id, security_pkg.PERMISSION_WRITE))) THEN
			RETURN security_pkg.PERMISSION_WRITE;
		END IF;
		IF ((NOT v_is_flow_audit AND audit_pkg.GetPermissionOnAudit(v_secondary_audit_sid) > 0) OR
			(v_is_flow_audit AND audit_pkg.HasCapabilityAccess(v_secondary_audit_sid, v_survey_capability_id, security_pkg.PERMISSION_READ))) THEN
			RETURN security_pkg.PERMISSION_READ;
		END IF;
		RETURN 0;
	END IF;

	IF security_pkg.IsAccessAllowedSID(security_pkg.getact, v_survey_sid, Csr_Data_Pkg.PERMISSION_VIEW_ALL_RESULTS) THEN
		-- If the user has access to read all results then grant read access
		v_has_read_all_results := TRUE;
	END IF;

	IF v_supplier_sid IS NOT NULL THEN
		-- If the survey relates to a supplier - grant access based on supplier permissions
		IF chain.questionnaire_security_pkg.CheckPermission(
			chain.questionnaire_pkg.GetQuestionnaireId(v_supplier_sid, 'QuickSurvey.' || v_survey_sid, v_component_id),
			chain.chain_pkg.QUESTIONNAIRE_EDIT) THEN
			RETURN security_pkg.PERMISSION_WRITE;
		END IF;

		IF chain.questionnaire_security_pkg.CheckPermission(
			chain.questionnaire_pkg.GetQuestionnaireId(v_supplier_sid, 'QuickSurvey.' || v_survey_sid, v_component_id),
			chain.chain_pkg.QUESTIONNAIRE_VIEW) OR
			v_has_read_all_results THEN
			RETURN security_pkg.PERMISSION_READ;
		END IF;
		-- TODO: Could also check status of questionnaire
		RETURN 0;
	END IF;

	IF v_flow_item_id IS NOT NULL THEN
		IF v_flow_alert_class = 'campaign' THEN
			v_response_perm := GetResponseCapability(v_flow_item_id);
		
			IF bitand(v_response_perm, security_pkg.PERMISSION_WRITE) = security_pkg.PERMISSION_WRITE THEN
				RETURN security_pkg.PERMISSION_WRITE;
			ELSIF bitand(v_response_perm, security_pkg.PERMISSION_READ) = security_pkg.PERMISSION_READ OR v_has_read_all_results THEN
				RETURN security_pkg.PERMISSION_READ;
			ELSE 
				RETURN 0;
			END IF;
		ELSE
			v_flow_item_is_editable := flow_pkg.GetFlowItemIsEditable(v_flow_item_id);
			
			IF v_flow_item_is_editable <= 0 AND v_has_read_all_results THEN
				RETURN security_pkg.PERMISSION_READ;
			END IF;
		
			RETURN CASE v_flow_item_is_editable
				WHEN 0 THEN security_pkg.PERMISSION_READ
				WHEN 1 THEN security_pkg.PERMISSION_WRITE
				ELSE 0 END;
		END IF;
	END IF;

	-- we've checked permissions on the survey - deny access (unless this user is the one who submitted the data)
	IF v_user_sid = security_pkg.getSid THEN
		RETURN security_pkg.PERMISSION_WRITE;
	ELSIF v_has_read_all_results THEN
		RETURN security_pkg.PERMISSION_READ;
	END IF;

	RETURN 0;
END;

PROCEDURE CheckResponseAccess(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_is_editable					IN	NUMBER DEFAULT 0
)
AS
	v_response_access				NUMBER := GetResponseAccess(in_response_id);
BEGIN
	IF in_is_editable = 1 AND v_response_access != security_pkg.PERMISSION_WRITE THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied for survey response '||in_response_id);
	ELSIF in_is_editable = 0 AND NOT (v_response_access = security_pkg.PERMISSION_READ OR v_response_access = security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for survey response '||in_response_id);
	END IF;
END;

FUNCTION CheckGuidAccess(
	in_guid			IN	quick_survey_response.guid%TYPE,
	in_is_editable	IN	NUMBER DEFAULT 0
)
RETURN quick_survey_response.survey_response_id%TYPE
AS
	v_audience					quick_survey.audience%TYPE;
	v_response_id				quick_survey_response.survey_response_id%TYPE;
BEGIN
	SELECT s.audience, r.survey_response_id
	  INTO v_audience, v_response_id
	  FROM quick_survey s
	  JOIN quick_survey_response r ON s.survey_sid = r.survey_sid
	 WHERE r.guid = in_guid
	   AND r.hidden = 0;

	IF v_audience NOT IN ('everyone') THEN
		-- If we know the GUID and the survey is open to unauthenticated users then allow access (RO+RW)
		-- Otherwise check loged on user user permissions
		CheckResponseAccess(v_response_id, in_is_editable);
	END IF;

	RETURN v_response_id;
END;

FUNCTION GetResponseRegionSid (
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE
)
RETURN security_pkg.T_SID_ID
AS
	v_region_sid				security_pkg.T_SID_ID;
BEGIN
	-- find a region_sid against any of the things a survey can be connected to
	SELECT NVL(ias.region_sid, NVL(ia.region_sid, NVL(rsr.region_sid, s.region_sid)))
	  INTO v_region_sid
	  FROM quick_survey_response qsr
	  LEFT JOIN supplier_survey_response ssr ON qsr.survey_response_id = ssr.survey_response_id AND qsr.app_sid = ssr.app_sid
	  LEFT JOIN supplier s ON ssr.supplier_sid = s.company_sid AND ssr.app_sid = s.app_sid
	  LEFT JOIN region_survey_response rsr ON qsr.survey_response_id = rsr.survey_response_id AND qsr.app_sid = rsr.app_sid
	  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id AND ia.app_sid = qsr.app_sid
	  LEFT JOIN internal_audit ias ON ias.summary_response_id = qsr.survey_response_id AND ias.app_sid = qsr.app_sid
	 WHERE qsr.survey_response_Id = in_response_id;

	RETURN v_region_sid;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
END;

PROCEDURE AddTempQuestion(
	in_question_id				IN  tempor_question.question_id%TYPE,
	in_question_version			IN  tempor_question.question_version%TYPE,	
	in_parent_id				IN  tempor_question.parent_id%TYPE,
	in_parent_version			IN  tempor_question.parent_version%TYPE,
	in_label					IN  tempor_question.label%TYPE,
	in_question_type			IN  tempor_question.question_type%TYPE,
	in_score					IN  tempor_question.score%TYPE,
	in_max_score				IN  tempor_question.max_score%TYPE,
	in_upload_score				IN  tempor_question.upload_score%TYPE,
	in_lookup_key				IN  tempor_question.lookup_key%TYPE,
	in_invert_score				IN  tempor_question.invert_score%TYPE,
	in_custom_question_type_id	IN  tempor_question.custom_question_type_id%TYPE,
	in_weight					IN  tempor_question.weight%TYPE,
	in_dont_normalise_score		IN	tempor_question.dont_normalise_score%TYPE,
	in_has_score_expression		IN	tempor_question.has_score_expression%TYPE,
	in_has_max_score_expr		IN	tempor_question.has_max_score_expr%TYPE,
	in_remember_answer			IN	tempor_question.remember_answer%TYPE,
	in_count_question			IN	tempor_question.count_question%TYPE,
	in_action					IN	tempor_question.action%TYPE,
	in_question_xml				IN	tempor_question.question_xml%TYPE
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM tempor_question;

	INSERT INTO tempor_question (question_id, question_version, parent_id, parent_version, pos, label, question_type, score, max_score,
						   upload_score, lookup_key, invert_score, custom_question_type_id, weight,
						   dont_normalise_score, has_score_expression, has_max_score_expr, remember_answer,
						   count_question, action, question_xml)
		VALUES (in_question_id, in_question_version, in_parent_id, in_parent_version, v_count, in_label, lower(in_question_type), in_score,
			 in_max_score, in_upload_score, in_lookup_key, in_invert_score, in_custom_question_type_id, in_weight,
			 in_dont_normalise_score, in_has_score_expression, in_has_max_score_expr, in_remember_answer,
			 in_count_question, in_action, in_question_xml);
END;

PROCEDURE AddTempQuestionOption(
	in_question_id				IN  temp_question_option.question_id%TYPE,
	in_question_version			IN  temp_question_option.question_version%TYPE,
	in_question_option_id		IN  temp_question_option.question_option_id%TYPE,
	in_label					IN  temp_question_option.label%TYPE,
	in_score					IN  temp_question_option.score%TYPE,
	in_has_override				IN  temp_question_option.has_override%TYPE,
	in_score_override			IN  temp_question_option.score_override%TYPE,
	in_hidden					IN  temp_question_option.hidden%TYPE,
	in_color					IN  temp_question_option.color%TYPE,
	in_lookup_key				IN  temp_question_option.lookup_key%TYPE,
	in_option_action			IN  temp_question_option.option_action%TYPE,
	in_non_compliance_popup		IN  temp_question_option.non_compliance_popup%TYPE,
	in_non_comp_default_id		IN  temp_question_option.non_comp_default_id%TYPE,
	in_non_compliance_type_id	IN  temp_question_option.non_compliance_type_id%TYPE,
	in_non_compliance_label		IN  temp_question_option.non_compliance_label%TYPE,
	in_non_compliance_detail	IN  temp_question_option.non_compliance_detail%TYPE,
	in_non_comp_root_cause		IN  temp_question_option.non_comp_root_cause%TYPE,
	in_non_comp_suggested_action IN  temp_question_option.non_comp_suggested_action%TYPE,
	in_question_option_xml		IN	temp_question_option.question_option_xml%TYPE
)
AS
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_question_option;

	INSERT INTO temp_question_option (question_id, question_version, question_option_id, pos, label, score, has_override,
	                                  score_override, hidden, color, lookup_key, option_action,
									  non_compliance_popup, non_comp_default_id, non_compliance_type_id,
									  non_compliance_label, non_compliance_detail, non_comp_root_cause,
									  non_comp_suggested_action, question_option_xml)
	     VALUES (in_question_id, in_question_version, in_question_option_id, v_count, in_label, in_score, in_has_override,
		         in_score_override, in_hidden, in_color, in_lookup_key, in_option_action,
		         in_non_compliance_popup, in_non_comp_default_id, in_non_compliance_type_id,
				 in_non_compliance_label, in_non_compliance_detail, in_non_comp_root_cause,
				 in_non_comp_suggested_action, in_question_option_xml);
END;

PROCEDURE AddTempQstnOptionNCTag(
	in_question_id				IN	temp_question_option_nc_tag.question_id%TYPE,
	in_question_version			IN	temp_question_option_nc_tag.question_version%TYPE,
	in_question_option_id		IN	temp_question_option_nc_tag.question_option_id%TYPE,
	in_tag_ids					IN	security_pkg.T_SID_IDS --not sids but will do
)
AS
BEGIN
	-- crap hack for ODP.NET
	IF in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FORALL i IN in_tag_ids.FIRST..in_tag_ids.LAST
			INSERT INTO temp_question_option_nc_tag (question_id, question_version, question_option_id, tag_id)
			VALUES (in_question_id, in_question_version, in_question_option_id, in_tag_ids(i));
	END IF;
END;

PROCEDURE AddTempQstnOptionShowQ(
	in_question_id				IN	temp_question_option_show_q.question_id%TYPE,
	in_question_version			IN	temp_question_option_show_q.question_version%TYPE,
	in_question_option_id		IN	temp_question_option_show_q.question_option_id%TYPE,
	in_show_question_ids		IN	security_pkg.T_SID_IDS,
	in_show_question_vers		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	-- crap hack for ODP.NET
	IF in_show_question_ids.COUNT = 1 AND in_show_question_ids(1) IS NULL THEN
		NULL; -- collection is null by default
	ELSE
		FORALL i IN in_show_question_ids.FIRST..in_show_question_ids.LAST
			INSERT INTO temp_question_option_show_q (question_id, question_version, question_option_id, show_question_id, show_question_version)
			VALUES (in_question_id, in_question_version, in_question_option_id, in_show_question_ids(i), in_question_version);
	END IF;
END;

-- Relies on temp question tables being populated in session (done by c# now as oracle xml processing was too slow)
PROCEDURE INTERNAL_XmlUpdated(
	in_survey_sid	IN	security_pkg.T_SID_ID
)
AS
	t_owned_question_ids			security.T_SID_TABLE;
BEGIN
	--Find any duplicate lookup key values and raise an exception before attempting to insert/update records.
	FOR r IN (
		SELECT lookup_key, question_id, COUNT(*)
		  FROM temp_question_option
		 WHERE lookup_key IS NOT NULL
		HAVING COUNT(*) > 1
		 GROUP BY lookup_key, question_id
		 UNION
		SELECT lookup_key, 0, COUNT(*)
		  FROM tempor_question
		 WHERE lookup_key IS NOT NULL
		HAVING COUNT(*) > 1
		 GROUP BY lookup_key, 2
	)
	LOOP
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_DUP_SURVEY_LOOKUP_KEY, r.lookup_key);
	END LOOP;

	-- hide if no longer in XML
	UPDATE quick_survey_question
	   SET is_visible = 0, lookup_key = null -- clear lookup_key to allow its reuse in future
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND (question_id, question_version) NOT IN (
			SELECT question_id, NVL(question_version, 0)
			  FROM tempor_question
	   );
	
	-- insert if new
	-- We have to do this prior to the update in case we've inserted a new section
	-- and moved existing rows under it.
	INSERT INTO question
		(question_id, owned_by_survey_sid, question_type, custom_question_type_id,
		latest_question_version, latest_question_draft)
	SELECT question_id, in_survey_sid, question_type, custom_question_type_id,
		   NVL(question_version, 0), 0
	  FROM tempor_question
	 WHERE question_id NOT IN (
		SELECT question_id
		  FROM question		 
	 );

	INSERT INTO question_version
		(question_id, question_version, question_draft, parent_id, parent_version, parent_draft,
		pos, label, score, max_score, upload_score, weight, dont_normalise_score, has_score_expression,
		has_max_score_expr, remember_answer, count_question, action, question_xml)
	SELECT question_id, NVL(question_version, 0), 0, parent_id, parent_version, 0,
		   pos, label, score, max_score, upload_score, NVL(weight, 1), dont_normalise_score, has_score_expression,
		   has_max_score_expr, remember_answer, count_question, action, question_xml
	  FROM tempor_question
	 WHERE (question_id, NVL(question_version, 0)) NOT IN (
		SELECT question_id, question_version
		  FROM question_version
	 );

	INSERT INTO question_option
		(question_id, question_option_id, pos, label, score, lookup_key, option_action, color,
		non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label,
		non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_version, question_draft, question_option_xml)
		SELECT question_id, question_option_id, pos, NVL(label,'Unnamed'),
			   CASE WHEN has_override = 1 THEN score_override ELSE score END, lookup_key, option_action, color,
			   non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label,
			   non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, NVL(question_version, 0), 0, question_option_xml
		  FROM temp_question_option
		 WHERE (question_option_id, question_id, NVL(question_version, 0)) NOT IN (
		    SELECT question_option_id, qo.question_id, qo.question_version
		      FROM question_version q
			  JOIN question_option qo ON q.question_id = qo.question_id AND q.question_version = qo.question_version AND q.question_draft = qo.question_draft
		 );

	INSERT INTO quick_survey_question
		(question_id, parent_id, survey_sid, pos, is_visible, label, question_type, score, max_score, upload_score,
		 lookup_key, custom_question_type_id, weight, dont_normalise_score, has_score_expression, has_max_score_expr,
		 survey_version, remember_answer, count_question, action, question_version, parent_version)
		SELECT question_id, parent_id, in_survey_sid, pos, 1, label, question_type, score, max_score, upload_score,
			   lookup_key, custom_question_type_id, NVL(weight, 1), dont_normalise_score, has_score_expression,
			   has_max_score_expr, 0, remember_answer, count_question, action, NVL(question_version, 0), CASE WHEN parent_id IS NULL THEN NULL ELSE NVL(parent_version, 0) END CASE
		  FROM tempor_question
		 WHERE (question_id, NVL(question_version, 0)) NOT IN (
			SELECT question_id, question_version
			  FROM quick_survey_question
			 WHERE survey_sid = in_survey_sid
			   AND survey_version = 0
		 );

	-- Update mapped indicator descriptions if the questions change
	FOR r IN (
		SELECT qsq.maps_to_ind_sid, old.description, x.label
		  FROM tempor_question x
		  JOIN quick_survey_question qsq ON x.question_id = qsq.question_id AND NVL(x.question_version, 0) = qsq.question_version
		  JOIN ind_description old ON qsq.maps_to_ind_sid = old.ind_sid
		   AND qsq.label = old.description -- indicator description is same as old label
		 WHERE x.label != qsq.label -- label has changed in survey
		   AND qsq.survey_version = 0
	 ) LOOP
		-- This will fail if the user has access to change surveys but doesn't have access to change indicators
		indicator_pkg.RenameIndicator(r.maps_to_ind_sid, r.label);
	 END LOOP;
	 
	-- update owned questions
	SELECT q.question_id
	  BULK COLLECT INTO t_owned_question_ids
	  FROM question q
	  JOIN tempor_question tq ON q.question_id = tq.question_id
	 WHERE owned_by_survey_sid = in_survey_sid;
	 
	UPDATE question_version qsq
	   SET (label, parent_id, parent_version, pos, score, max_score, upload_score,
		    weight, dont_normalise_score, has_score_expression, has_max_score_expr,
			remember_answer, count_question, action) = (
				SELECT x.label, x.parent_id, CASE WHEN x.parent_id IS NULL THEN NULL ELSE NVL(x.parent_version, 0) END, x.pos, x.score, x.max_score, x.upload_score,
					   NVL(x.weight, 1), x.dont_normalise_score, x.has_score_expression, x.has_max_score_expr,
					   x.remember_answer, x.count_question, x.action
				  FROM tempor_question x
				  JOIN TABLE(t_owned_question_ids) t ON t.column_value = x.question_id
				 WHERE qsq.question_id = x.question_id
				   AND NVL(x.question_version, 0) = qsq.question_version
			)
	 WHERE EXISTS (
		SELECT *
		  FROM tempor_question x
		  JOIN TABLE(t_owned_question_ids) t ON t.column_value = x.question_id
		 WHERE qsq.question_id = x.question_id
		   AND NVL(x.question_version, 0) = qsq.question_version
	   )
	   AND question_draft = 0;
	 
	UPDATE question_option qo
	   SET (label, pos, color, score, lookup_key, option_action,
			non_compliance_popup, non_comp_default_id, non_compliance_type_id,
			non_compliance_label, non_compliance_detail, non_comp_root_cause,
			non_comp_suggested_action) = (
			 SELECT x.label, x.pos, x.color, CASE WHEN NVL(x.has_override, 0) <> 0 THEN x.score_override ELSE x.score END,
					x.lookup_key, x.option_action,
					x.non_compliance_popup, x.non_comp_default_id, x.non_compliance_type_id,
					x.non_compliance_label, x.non_compliance_detail, x.non_comp_root_cause,
					x.non_comp_suggested_action
			   FROM temp_question_option x
			  WHERE qo.question_option_id = x.question_option_id
			    AND qo.question_id = x.question_id
				AND qo.question_version = NVL(x.question_version, 0)
		)
	 WHERE (question_option_id, question_id, question_version) IN (
			SELECT t.question_option_id, t.question_id, NVL(t.question_version, 0)
			  FROM temp_question_option t
			  JOIN TABLE(t_owned_question_ids) o ON o.column_value = t.question_id
	  ) 
	   AND question_draft = 0;
	
	 
	-- update owned questions
	SELECT q.question_id
	  BULK COLLECT INTO t_owned_question_ids
	  FROM question q
	  JOIN tempor_question tq ON q.question_id = tq.question_id
	 WHERE owned_by_survey_sid = in_survey_sid;
	 
	UPDATE question_version qsq
	   SET (label, parent_id, parent_version, pos, score, max_score, upload_score,
		    weight, dont_normalise_score, has_score_expression, has_max_score_expr,
			remember_answer, count_question, action, question_xml) = (
				SELECT x.label, x.parent_id, CASE WHEN x.parent_id IS NULL THEN NULL ELSE NVL(x.parent_version, 0) END, x.pos, x.score, x.max_score, x.upload_score,
					   NVL(x.weight, 1), x.dont_normalise_score, x.has_score_expression, x.has_max_score_expr,
					   x.remember_answer, x.count_question, x.action, x.question_xml
				  FROM tempor_question x
				  JOIN TABLE(t_owned_question_ids) t ON t.column_value = x.question_id
				 WHERE qsq.question_id = x.question_id
				   AND NVL(x.question_version, 0) = qsq.question_version
			)
	 WHERE EXISTS (
		SELECT *
		  FROM tempor_question x
		  JOIN TABLE(t_owned_question_ids) t ON t.column_value = x.question_id
		 WHERE qsq.question_id = x.question_id
		   AND NVL(x.question_version, 0) = qsq.question_version
	   )
	   AND question_draft = 0;
	 
	UPDATE question_option qo
	   SET (label, pos, color, score, lookup_key, option_action,
			non_compliance_popup, non_comp_default_id, non_compliance_type_id,
			non_compliance_label, non_compliance_detail, non_comp_root_cause,
			non_comp_suggested_action, question_option_xml) = (
			 SELECT x.label, x.pos, x.color, CASE WHEN NVL(x.has_override, 0) <> 0 THEN x.score_override ELSE x.score END,
					x.lookup_key, x.option_action,
					x.non_compliance_popup, x.non_comp_default_id, x.non_compliance_type_id,
					x.non_compliance_label, x.non_compliance_detail, x.non_comp_root_cause,
					x.non_comp_suggested_action, x.question_option_xml
			   FROM temp_question_option x
			  WHERE qo.question_option_id = x.question_option_id
			    AND qo.question_id = x.question_id
				AND qo.question_version = NVL(x.question_version, 0)
		)
	 WHERE (question_option_id, question_id, question_version) IN (
			SELECT t.question_option_id, t.question_id, NVL(t.question_version, 0)
			  FROM temp_question_option t
			  JOIN TABLE(t_owned_question_ids) o ON o.column_value = t.question_id
	  ) 
	   AND question_draft = 0;
	
	-- XXX: see FB12548 - it would be possible to cause something to be hidden, hence
	-- why we update is_visible to 1
    -- update if in our table already
	UPDATE quick_survey_question qsq
	   SET (label, parent_id, pos, question_type, score, max_score, upload_score, lookup_key,
		    custom_question_type_id, weight, is_visible, dont_normalise_score,
		    has_score_expression, has_max_score_expr, remember_answer, count_question, action, parent_version) = (
				SELECT x.label, x.parent_id, x.pos, x.question_type, x.score, x.max_score,
					   x.upload_score, x.lookup_key, x.custom_question_type_id, NVL(x.weight, 1), 1,
					   x.dont_normalise_score, x.has_score_expression, x.has_max_score_expr,
					   x.remember_answer, x.count_question, x.action, CASE WHEN x.parent_id IS NULL THEN NULL ELSE NVL(x.parent_version, 0) END
				  FROM tempor_question x
				 WHERE qsq.question_id = x.question_id
				   AND NVL(x.question_version, 0) = qsq.question_version
			)
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = 0
	   AND EXISTS (SELECT null FROM tempor_question t WHERE t.question_id = qsq.question_id AND NVL(t.question_version, 0) = qsq.question_version);

	-- hide if no longer in XML
	UPDATE qs_question_option
	   SET is_visible = 0, lookup_key = null -- clear lookup_key to allow its reuse in future
	 WHERE survey_version = 0
	   AND question_option_id IN (
		    SELECT question_option_id
		      FROM quick_survey_question q
			  JOIN qs_question_option qo ON q.question_id = qo.question_id
			 WHERE q.survey_sid = in_survey_sid
			   AND qo.is_visible = 1
			   AND qo.survey_version = 0
			   AND q.survey_version = 0
		      MINUS
		    SELECT question_option_id FROM temp_question_option
	   );

	DELETE FROM qs_question_option_nc_tag
	 WHERE survey_version = 0
	   AND (question_id, question_version) IN (
		SELECT qsq.question_id, qsq.question_version
		  FROM quick_survey_question qsq
		 WHERE qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = 0
		)
	  AND (question_id, question_option_id, tag_id, question_version) NOT IN (
		SELECT question_id, question_option_id, tag_id, NVL(question_version, 0)
		  FROM temp_question_option_nc_tag
		);

	-- Remove any show question actions that aren't still in use
	DELETE FROM quick_survey_expr_action
	 WHERE survey_version = 0
	   AND show_question_id IS NOT NULL
	   AND survey_sid = in_survey_sid
	   AND (expr_id, survey_version) IN (
		SELECT expr_id, survey_version
		  FROM quick_survey_expr
		 WHERE survey_sid = in_survey_sid
		   AND question_id IS NOT NULL
		   AND question_option_id IS NOT NULL
	   )
	   AND (expr_id, survey_version, show_question_id, show_question_version) NOT IN (
		SELECT qse.expr_id, qse.survey_version, tqosq.show_question_id, NVL(tqosq.show_question_version, 0)
		  FROM temp_question_option_show_q tqosq
		  JOIN quick_survey_expr qse ON tqosq.question_id = qse.question_id AND NVL(tqosq.show_question_version, 0) =  qse.question_version AND tqosq.question_option_id = qse.question_option_id
		 WHERE qse.survey_sid = in_survey_sid
	   );

	-- Tidy up any question based expressions no longer in use
	DELETE FROM quick_survey_expr
	 WHERE survey_version = 0
	   AND survey_sid = in_survey_sid
	   AND question_id IS NOT NULL
	   AND question_option_id IS NOT NULL
	   AND (expr_id, survey_version) NOT IN (
		SELECT expr_id, survey_version
		  FROM quick_survey_expr_action
		 WHERE survey_version = 0
		   AND survey_sid = in_survey_sid
	   );

	-- Update mapped indicator descriptions if the option labels change
	FOR r IN (
		SELECT qso.maps_to_ind_sid, old.description, x.label
		  FROM temp_question_option x
		  JOIN qs_question_option qso ON x.question_id = qso.question_id AND NVL(x.question_version, 0) = qso.question_version AND x.question_option_id = qso.question_option_id
		  JOIN ind_description old ON qso.maps_to_ind_sid = old.ind_sid
		   AND qso.label = old.description -- indicator description is same as old label
		 WHERE x.label != qso.label -- label has changed in survey
		   AND qso.survey_version = 0
	 ) LOOP
		-- This will fail if the user has access to change surveys but doesn't have access to change indicators
		indicator_pkg.RenameIndicator(r.maps_to_ind_sid, r.label);
	 END LOOP;

	-- XXX: see FB12548 - it would be possible to cause something to be hidden, hence
	-- why we update is_visible to 1

    -- update if in our table already
	UPDATE qs_question_option
	   SET (label, pos, color, score, lookup_key, option_action, is_visible,
			non_compliance_popup, non_comp_default_id, non_compliance_type_id,
			non_compliance_label, non_compliance_detail, non_comp_root_cause,
			non_comp_suggested_action) = (
			 SELECT x.label, x.pos, x.color, CASE WHEN NVL(x.has_override, 0) <> 0 THEN x.score_override ELSE x.score END,
					x.lookup_key, x.option_action, CASE WHEN x.hidden=1 THEN 0 ELSE 1 END,
					x.non_compliance_popup, x.non_comp_default_id, x.non_compliance_type_id,
					x.non_compliance_label, x.non_compliance_detail, x.non_comp_root_cause,
					x.non_comp_suggested_action
			   FROM temp_question_option x
			  WHERE qs_question_option.question_option_id = x.question_option_id
			    AND qs_question_option.question_id = x.question_id
		)
	 WHERE (question_option_id, question_id, question_version) IN (
			SELECT question_option_id, question_id, NVL(question_version, 0) FROM temp_question_option
	  )
	   AND survey_version = 0;

	-- rename any linked indicators for radio buttons (i.e. if we rename the radio button then
	-- we also rename the indicator to match)
	FOR r IN (
		SELECT ind_sid, qo.label
		  FROM v$ind i
		  JOIN qs_question_option qo ON i.ind_sid = qo.maps_to_ind_sid AND i.app_sid = qo.app_sid
		 WHERE i.description != qo.label
		   AND qo.is_visible = 1
		   AND qo.survey_version = 0
	)
	LOOP
		-- not very i8n friendly
		UPDATE ind_description
		   SET description = r.label
		 WHERE ind_sid = r.ind_sid;
	END LOOP;

	INSERT INTO qs_question_option
		(question_id, question_option_id, pos, is_visible, label, score, lookup_key, option_action, color,
		survey_version, non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label,
		non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, question_version, survey_sid)
		SELECT question_id, question_option_id, pos, CASE WHEN hidden=1 THEN 0 ELSE 1 END, NVL(label,'Unnamed'),
			   CASE WHEN has_override = 1 THEN score_override ELSE score END, lookup_key, option_action, color, 0,
			   non_compliance_popup, non_comp_default_id, non_compliance_type_id, non_compliance_label,
			   non_compliance_detail, non_comp_root_cause, non_comp_suggested_action, NVL(question_version, 0), in_survey_sid
		  FROM temp_question_option
		 WHERE (question_option_id, question_id, question_version) NOT IN (
		    SELECT question_option_id, qo.question_id, qo.question_version
		      FROM quick_survey_question q
			  JOIN qs_question_option qo ON q.question_id = qo.question_id AND q.survey_version = qo.survey_version
			 WHERE q.survey_sid = in_survey_sid
			   AND q.survey_version = 0
		 );

	INSERT INTO qs_question_option_nc_tag (question_id, question_option_id, tag_id, survey_sid, survey_version, question_version)
	SELECT question_id, question_option_id, tag_id, in_survey_sid, 0, NVL(question_version, 0)
	  FROM temp_question_option_nc_tag
	 MINUS
	SELECT question_id, question_option_id, tag_id, in_survey_sid, survey_version, question_version
	  FROM qs_question_option_nc_tag
	 WHERE (question_id, question_version) IN (
		SELECT question_id, question_version
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
	  );

	INSERT INTO quick_survey_expr (expr_id, survey_sid, survey_version, question_id, question_option_id, question_version)
	SELECT expr_id_seq.NEXTVAL, in_survey_sid, 0, question_id, question_option_id, question_version
	  FROM (
		SELECT tqosq.question_id, tqosq.question_option_id, NVL(tqosq.question_version, 0) question_version
		  FROM temp_question_option_show_q tqosq
		 MINUS
		SELECT question_id, question_option_id, NVL(question_version, 0) question_version
		  FROM quick_survey_expr
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
		   AND question_id IS NOT NULL
		   AND question_option_id IS NOT NULL
	  );

	INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, survey_sid, survey_version, expr_id, action_type, show_question_id, show_question_version)
	SELECT qs_expr_action_id_seq.NEXTVAL, in_survey_sid, 0, expr_id, 'show_q', show_question_id, show_question_version
	  FROM (
		SELECT qse.expr_id, tqosq.show_question_id, NVL(tqosq.question_version, 0) show_question_version
		  FROM temp_question_option_show_q tqosq
		  JOIN quick_survey_expr qse ON tqosq.question_id = qse.question_id AND tqosq.question_option_id = qse.question_option_id
		 WHERE qse.survey_sid = in_survey_sid
		   AND qse.survey_version = 0
		 MINUS
		SELECT expr_id, show_question_id, show_question_version
		  FROM quick_survey_expr_action
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = 0
		   AND show_question_id IS NOT NULL
	  );

	-- invert scores if needed
	FOR r IN (
		WITH qq AS (
			SELECT q.question_id, qo.question_option_id,
				(COUNT(*) OVER (PARTITION BY qo.question_id) + 1)
					- (ROW_NUMBER() OVER (PARTITION BY qo.question_id ORDER BY qo.score)) inv_score_pos,
				ROW_NUMBER() OVER (PARTITION BY qo.question_id ORDER BY qo.score) score_pos,
				qo.score, qo.question_version
			  FROM tempor_question q
			  JOIN qs_question_option qo ON q.question_id = qo.question_id AND NVL(q.question_version, 0) = qo.question_version
			 WHERE q.question_type = 'radiorow'
			   AND qo.is_visible = 1
			   AND q.invert_score = 1
			   AND qo.survey_version = 0
		)
		SELECT q1.question_id, q1.question_option_id, q2.score, q1.question_version
		  FROM qq q1
			JOIN qq q2
				ON q1.question_id = q2.question_id
				AND q1.score_pos = q2.inv_score_pos
	)
	LOOP
		UPDATE qs_question_option
		   SET score = r.score
		 WHERE question_id = r.question_id
		   AND question_option_id = r.question_option_id
		   AND question_version = r.question_version
		   AND survey_version = 0;
	END LOOP;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid;
END;

PROCEDURE SetLookupKey(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	in_lookup_key		IN	quick_survey_question.lookup_key%TYPE
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	--
	v_doc					DBMS_XMLDOM.DOMDocument;
	v_nl					DBMS_XMLDOM.DOMNodeList;
	v_n						DBMS_XMLDOM.DOMNode;
	v_question_xml			CLOB;
	v_lookup_key_in_use		NUMBER;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_question_id
	   AND survey_version = 0;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey sid '||v_survey_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_lookup_key_in_use
	  FROM quick_survey_question
	 WHERE UPPER(lookup_key) = TRIM(UPPER(in_lookup_key))
	   AND survey_sid = v_survey_sid
	   AND survey_version = 0
	   AND question_id <> in_question_id;
	
	IF v_lookup_key_in_use > 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_DUP_SURVEY_LOOKUP_KEY, 'The lookup key '''||in_lookup_key||''' is already in use');
	END IF;

	-- we have a functional index to ensure unique values (maybe need to catch exceptions?)
	-- XXX: fix UI to check for unique lookup_Keys?
	UPDATE quick_survey_question
	   SET lookup_key = TRIM(UPPER(in_lookup_key))
	 WHERE question_id = in_question_id
	   AND survey_version = 0;

	-- ugh -- got to fix XML. This is making me think maybe we recreate the XML from the DB each time? Hmmm....

	-- Fetch the document and create a new DOM document.
	SELECT question_xml
	  INTO v_question_xml
	  FROM quick_survey_version
	 WHERE survey_sid = v_survey_sid
	   AND survey_version = 0;

	v_doc := dbms_xmldom.newDOMDocument(v_question_xml);

	-- XXX: what about IDs on question / option etc? need to tighten XPath
	-- //question | //question/checkbox | //question/radioRow
	v_n := dbms_xslprocessor.selectSingleNode(DBMS_XMLDOM.makeNode(v_doc),'//*[@id='||TO_CHAR(in_question_id)||']');
	IF DBMS_XMLDOM.ISNULL(v_n) THEN
		RAISE_APPLICATION_ERROR(-20001, 'id '||TO_CHAR(in_question_id)||' not found in xml');
	END IF;
	IF in_lookup_key IS NULL THEN
		DBMS_XMLDOM.REMOVEATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'lookupKey');
	ELSE
		DBMS_XMLDOM.SETATTRIBUTE(DBMS_XMLDOM.makeElement(v_n), 'lookupKey', in_lookup_key);
	END IF;

	-- write back
	v_question_xml := dbms_xmldom.getxmltype(v_doc).getClobVal();
	UPDATE quick_survey_version
	   SET question_xml = v_question_xml
	 WHERE survey_sid = v_survey_sid
	   AND survey_version = 0;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = v_survey_sid;

	dbms_xmldom.freeDocument(v_doc);
EXCEPTION
	WHEN OTHERS THEN
		dbms_xmldom.freeDocument(v_doc);
		RAISE;
END;

PROCEDURE INTERNAL_AddRolesToIssue(
	in_qs_expr_nc_action_id			IN  non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE,
	in_issue_id						IN  issue.issue_id%TYPE
)
AS
	v_dummy_out_cur			security_pkg.T_OUTPUT_CUR;
BEGIN
	-- add involved roles to the issue
	FOR r IN (
		SELECT involve_role_sid
		  FROM qs_expr_nc_action_involve_role
		 WHERE qs_expr_non_compl_action_id = in_qs_expr_nc_action_id
		   AND app_sid = security_pkg.GetApp
	) LOOP
		issue_pkg.AddRole(security_pkg.GetACT, in_issue_id, r.involve_role_sid, v_dummy_out_cur);
	END LOOP;
END;

PROCEDURE INTERNAL_RaiseAuditNC(
	in_survey_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_internal_audit_sid			IN	security_pkg.T_SID_ID,
	in_ia_type_survey_id			IN	audit_non_compliance.internal_audit_type_survey_id%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_title						IN	qs_expr_non_compl_action.title%TYPE,
	in_detail						IN	qs_expr_non_compl_action.detail%TYPE,
	in_assign_to_role_sid			IN	security_pkg.T_SID_ID,
	in_qs_expr_nc_action_Id			IN	non_compliance_expr_action.qs_expr_non_compl_action_Id%TYPE,
	in_non_comp_default_id			IN	qs_expr_non_compl_action.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN	qs_expr_non_compl_action.non_compliance_type_id%TYPE,
	in_quick_survey_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	out_issue_ids_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_non_compliance_id				non_compliance.non_compliance_id%TYPE;
	v_issue_id						issue.issue_id%TYPE;
	v_issue_ids						security_pkg.T_SID_IDS;
	v_region_sid					security_pkg.T_SID_ID;
	t_issue_ids						security.T_SID_TABLE;
	v_label							non_comp_default.label%TYPE;
	v_detail						non_comp_default.detail%TYPE;
	v_root_cause					non_comp_default.root_cause%TYPE;
	v_suggested_action				non_comp_default.suggested_action%TYPE;
	v_type_id						non_comp_default.non_compliance_type_id%TYPE;
	v_can_have_actions				non_compliance_type.can_have_actions%TYPE DEFAULT 0;
	v_question_id					quick_survey_expr.question_id%TYPE;
	v_question_option_id					quick_survey_expr.question_option_id%TYPE;
BEGIN
	FOR r IN (
		SELECT NULL dummy
		  FROM non_compliance_expr_action ncea
		  JOIN audit_non_compliance anc ON ncea.non_compliance_id = anc.non_compliance_id
		 WHERE anc.internal_audit_sid = in_internal_audit_sid
		   AND ncea.qs_expr_non_compl_action_Id = in_qs_expr_nc_action_Id
	) LOOP
		-- This means this action has been raised already, either in this audit
		-- or carried forward from a previous audit - no need to re-raise
		OPEN out_issue_ids_cur FOR
			SELECT NULL issue_id
			  FROM DUAL
			 WHERE 1 = 0;

		RETURN;
	END LOOP;

	SELECT qse.question_id, qse.question_option_id
	  INTO v_question_id, v_question_option_id
	  FROM quick_survey_expr qse
	  JOIN quick_survey_expr_action qsea ON qse.expr_id = qsea.expr_id AND qsea.quick_survey_expr_action_id = in_quick_survey_expr_action_id
	  JOIN quick_survey_response qsr ON qse.survey_sid = qsr.survey_sid AND qse.survey_version = qsr.survey_version AND qsr.survey_response_id = in_survey_response_id;

	SELECT region_sid
	  INTO v_region_sid
	  FROM internal_audit
	 WHERE internal_audit_sid = in_internal_audit_sid;

	IF in_non_comp_default_id IS NULL THEN
		-- create a non-compliance for this internal audit (we might delete it later!)
		INSERT INTO non_compliance (
			non_compliance_id, created_in_audit_sid, non_compliance_type_id,
			label, detail, region_sid, question_id, question_option_id
		) VALUES (
			non_compliance_id_seq.NEXTVAL, in_internal_audit_sid, in_non_compliance_type_id,
			in_title, in_detail, v_region_sid, v_question_id, v_question_option_id
		) RETURNING non_compliance_id INTO v_non_compliance_id;
		audit_pkg.INTERNAL_CreateRefID_Non_Comp(v_non_compliance_id);
	ELSE
		SELECT non_compliance_type_id, label, detail, root_cause, suggested_action
		  INTO v_type_id, v_label, v_detail, v_root_cause, v_suggested_action
		  FROM non_comp_default
		 WHERE non_comp_default_id = in_non_comp_default_id;

		INSERT INTO non_compliance (
			non_compliance_id, created_in_audit_sid, non_compliance_type_id,
			label, detail, from_non_comp_default_id, region_sid,
			root_cause, suggested_action, question_id, question_option_id
		) VALUES (
			non_compliance_id_seq.NEXTVAL, in_internal_audit_sid, v_type_id,
			v_label, v_detail, in_non_comp_default_id, v_region_sid,
			v_root_cause, v_suggested_action, v_question_id, v_question_option_id
		) RETURNING non_compliance_id INTO v_non_compliance_id;
		audit_pkg.INTERNAL_CreateRefID_Non_Comp(v_non_compliance_id);

		INSERT INTO non_compliance_tag (non_compliance_id, tag_id)
		SELECT v_non_compliance_id, tag_id
		  FROM non_comp_default_tag
		 WHERE non_comp_default_id = in_non_comp_default_id;
	END IF;

	BEGIN
		INSERT INTO non_compliance_expr_action
			(survey_response_id, qs_expr_non_compl_action_Id, non_compliance_Id)
			VALUES (in_survey_response_id, in_qs_expr_nc_action_Id, v_non_compliance_id);

		INSERT INTO audit_non_compliance (
			audit_non_compliance_id, non_compliance_id, internal_audit_sid,
			attached_to_primary_survey,
			internal_audit_type_survey_id
		) VALUES (
			audit_non_compliance_id_seq.nextval, v_non_compliance_id, in_internal_audit_sid,
			CASE WHEN in_ia_type_survey_id = audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID THEN 1 ELSE 0 END,
			CASE WHEN in_ia_type_survey_id = audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID THEN NULL ELSE in_ia_type_survey_id END
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			DELETE FROM non_compliance
			 WHERE non_compliance_id = v_non_compliance_id;
			-- pull existing value
			SELECT non_compliance_Id
			  INTO v_non_compliance_Id
			  FROM non_compliance_expr_action
			 WHERE survey_response_id = in_survey_response_Id
			   AND qs_expr_non_compl_action_Id = in_qs_expr_nc_action_Id;

			OPEN out_issue_ids_cur FOR
				SELECT NULL issue_id
				  FROM DUAL
				 WHERE 1 = 0;

			RETURN;
	END;

	IF in_non_compliance_type_id IS NOT NULL THEN
		SELECT can_have_actions
		  INTO v_can_have_actions
		  FROM csr.non_compliance_type
		 WHERE non_compliance_type_id = in_non_compliance_type_id;
	END IF;

	IF in_non_comp_default_id IS NOT NULL THEN
		-- create default issues
		FOR r IN (
			SELECT ncdi.label, ncdi.description
			  FROM non_comp_default ncd
			  JOIN non_comp_default_issue ncdi ON ncd.non_comp_default_id = ncdi.non_comp_default_id
			  LEFT JOIN non_compliance_type nct ON ncd.non_compliance_type_id = nct.non_compliance_type_id
			 WHERE ncd.non_comp_default_id = in_non_comp_default_id
			   AND (nct.can_have_actions IS NULL
			    OR nct.can_have_actions = 1)
		) LOOP
			audit_pkg.AddNonComplianceIssue(
				in_non_compliance_id		=> v_non_compliance_id,
				in_label					=> r.label,
				in_description				=> r.description,
				in_assign_to_role_sid		=> in_assign_to_role_sid,
					in_due_dtm					=> in_due_dtm,
				out_issue_id				=> v_issue_id
			);
			INTERNAL_AddRolesToIssue(in_qs_expr_nc_action_Id, v_issue_id);

			v_issue_ids(v_issue_ids.COUNT) := v_issue_id;
		END LOOP;
	END IF;

	audit_pkg.UpdateNonCompClosureStatus(v_non_compliance_id);
	audit_pkg.RecalculateAuditNCScore(in_internal_audit_sid);

	t_issue_ids := security_pkg.SidArrayToTable(v_issue_ids);

	OPEN out_issue_ids_cur FOR
		SELECT CAST(column_value AS NUMBER(10)) issue_id
		  FROM TABLE(t_issue_ids);
END;

PROCEDURE RaiseNonCompliance(
	in_survey_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_quick_survey_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	out_issue_ids_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_internal_audit_sid			security_pkg.T_SID_ID;
	v_ia_type_survey_id				audit_non_compliance.internal_audit_type_survey_id%TYPE;
	v_supplier_sid					security_pkg.T_SID_ID;
	v_qs_expr_nc_action_Id			non_compliance_expr_action.qs_expr_non_compl_action_Id%TYPE;
	v_non_comp_default_id			qs_expr_non_compl_action.non_comp_default_id%TYPE;
	v_non_compliance_type_id		qs_expr_non_compl_action.non_compliance_type_id%TYPE;
	v_title							qs_expr_non_compl_action.title%TYPE;
	v_detail						qs_expr_non_compl_action.detail%TYPE;
	v_survey_sid					security_pkg.T_SID_ID;
	v_assign_to_role_sid			security_pkg.T_SID_ID;
	v_supplier_issue_id				issue.issue_id%TYPE;
BEGIN
	-- pull back details of the non compliance action
	SELECT title, survey_sid, nca.qs_expr_non_compl_action_id, detail, assign_to_role_sid,
		   non_comp_default_id, non_compliance_type_id
	  INTO v_title, v_survey_sid, v_qs_expr_nc_action_Id, v_detail, v_assign_to_role_sid,
		   v_non_comp_default_id, v_non_compliance_type_id
	  FROM qs_expr_non_compl_action nca
	  JOIN quick_survey_expr_action ea ON nca.qs_expr_non_compl_action_id = ea.qs_expr_non_compl_action_id
	  WHERE quick_survey_expr_action_id = in_quick_survey_expr_action_id;
	
	-- Try to raise against an audit's primary survey
	BEGIN
		SELECT internal_audit_sid
		  INTO v_internal_audit_sid
		  FROM internal_audit
		 WHERE survey_response_id = in_survey_response_id;

		INTERNAL_RaiseAuditNC(in_survey_response_id, v_internal_audit_sid, audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID,
							  in_due_dtm, v_title, v_detail,
							  v_assign_to_role_sid, v_qs_expr_nc_action_Id, v_non_comp_default_id,
							  v_non_compliance_type_id, in_quick_survey_expr_action_id, out_issue_ids_cur);

		RETURN;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- Try to raise against an audit's secondary survey
	BEGIN
		SELECT internal_audit_sid, internal_audit_type_survey_id
		  INTO v_internal_audit_sid, v_ia_type_survey_id
		  FROM internal_audit_survey
		 WHERE survey_response_id = in_survey_response_id;

		INTERNAL_RaiseAuditNC(in_survey_response_id, v_internal_audit_sid, v_ia_type_survey_id,
							  in_due_dtm, v_title, v_detail,
							  v_assign_to_role_sid, v_qs_expr_nc_action_Id, v_non_comp_default_id,
							  v_non_compliance_type_id, in_quick_survey_expr_action_id, out_issue_ids_cur);

		RETURN;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- Try to raise against a supplier
	BEGIN
		SELECT supplier_sid
		  INTO v_supplier_sid
		  FROM supplier_survey_response
		 WHERE survey_response_id = in_survey_response_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot raise a non-compliance against a survey response that doesn''t relate to either an audit or a supplier');
	END;

	-- Taken out of the above block as it might hide no_data_found errors within supplier_pkg.AddSupplierIssue
	IF v_supplier_sid IS NOT NULL THEN
		-- this adds involved roles itself, no need to add roles to issues
		supplier_pkg.AddSupplierIssue(
			in_supplier_sid			=> v_supplier_sid,
			in_label				=> v_title,
			in_description			=> NVL(v_detail, ' '),
			in_due_dtm				=> in_due_dtm,
			in_qs_expr_nc_action_id	=> v_qs_expr_nc_action_id,
			out_issue_id			=> v_supplier_issue_id);

		OPEN out_issue_ids_cur FOR
			SELECT v_supplier_issue_id issue_id
			  FROM dual;
	END IF;
END;

FUNCTION GetQuestionID
RETURN quick_survey_question.question_id%TYPE
AS
	v_id 	quick_survey_question.question_id%TYPE;
BEGIN
	SELECT question_id_seq.nextval
	  INTO v_id
	  FROM DUAL;
	RETURN v_id;
END;

FUNCTION GetQuestionOptionID
RETURN qs_question_option.question_option_id%TYPE
AS
	v_id	qs_question_option.question_option_id%TYPE;
BEGIN
	SELECT qs_question_option_id_seq.nextval
	  INTO v_id
	  FROM DUAL;
	RETURN v_id;
END;

FUNCTION GetResponseIdFromGUID(
	in_guid	IN	quick_survey_response.guid%TYPE
) RETURN quick_survey_response.survey_response_id%TYPE
AS
	v_response_id quick_survey_response.survey_response_id%TYPE;
BEGIN
	SELECT survey_response_id
	  INTO v_response_id
	  FROM quick_survey_response
	 WHERE guid = in_guid
	   AND hidden = 0;

	RETURN v_response_id;
END;

FUNCTION GetGUIDFromResponseId(
	in_response_id	IN	quick_survey_response.survey_response_id%TYPE
) RETURN quick_survey_response.guid%TYPE
AS
	v_guid	quick_survey_response.guid%TYPE;
BEGIN
	-- must check access as just knowing the guid might give more access than guessing a response id
	CheckResponseAccess(in_response_id);

	SELECT guid
	  INTO v_guid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;

	RETURN v_guid;
END;

FUNCTION GetGUIDFromUserSidSurveySid(
	in_user_sid 					IN	quick_survey_response.user_sid%TYPE,
	in_survey_sid 					IN	quick_survey_response.survey_sid%TYPE
) RETURN quick_survey_response.guid%TYPE
AS
	v_guid							quick_survey_response.guid%TYPE;
BEGIN
	-- Required to prevent a user using a direct quick survey link, with audience existing user
	-- from creating duplicate responses.

	-- no access check required as guid returned based on user_sid anyway

	SELECT MIN(guid)
	  INTO v_guid
	  FROM (
		SELECT qsr.guid
		  FROM quick_survey_response qsr
		  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
		 WHERE qsr.survey_sid = in_survey_sid
		   AND qsr.user_sid = in_user_sid
		   AND qs.audience = 'existing'
		 ORDER BY qsr.created_dtm DESC
	  )
	 WHERE ROWNUM = 1;

	RETURN v_guid;
END;

FUNCTION INTERNAL_GetSubmissionId (
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE
) RETURN quick_survey_submission.submission_id%TYPE
AS
	v_submission_id			quick_survey_submission.submission_id%TYPE := in_submission_id;
BEGIN
	IF v_submission_id IS NULL THEN
		SELECT NVL(last_submission_id, 0)
		  INTO v_submission_id
		  FROM quick_survey_response
		 WHERE survey_response_id = in_response_id;
	END IF;
	RETURN v_submission_id;
END;

FUNCTION INTERNAL_GetSurveyVersion (
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_survey_version				IN	quick_survey_version.survey_version%TYPE
) RETURN quick_survey_version.survey_version%TYPE
AS
	v_survey_version			quick_survey_version.survey_version%TYPE := in_survey_version;
BEGIN
	IF v_survey_version IS NULL THEN
		SELECT NVL(current_version, 0)
		  INTO v_survey_version
		  FROM quick_survey
		 WHERE survey_sid = in_survey_sid;
	END IF;
	RETURN v_survey_version;
END;

FUNCTION INTERNAL_GetSubmSurveyVersion (
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE
) RETURN quick_survey_version.survey_version%TYPE
AS
	v_survey_version			quick_survey_version.survey_version%TYPE;
	v_submission_id				quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
BEGIN
	SELECT CASE WHEN v_submission_id = 0 THEN qsr.survey_version ELSE qss.survey_version END
	  INTO v_survey_version
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	 WHERE qsr.survey_response_id = in_response_id
	   AND qss.submission_id = v_submission_id;

	RETURN v_survey_version;
END;

FUNCTION GetSurveyVersion(
	in_survey_sid					IN	security_pkg.T_SID_ID
) RETURN quick_survey_version.survey_version%TYPE
AS
BEGIN
	RETURN INTERNAL_GetSurveyVersion(in_survey_sid, NULL);
END;

PROCEDURE GetSurveyVersionFromGUID(
	in_guid							IN	quick_survey_response.guid%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE,
	out_survey_sid					OUT	security_pkg.T_SID_ID,
	out_survey_response_id			OUT	quick_survey_response.survey_response_id%TYPE,
	out_survey_version				OUT	quick_survey_version.survey_version%TYPE
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE := GetResponseIdFromGUID(in_guid);
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(v_response_id, in_submission_id);
BEGIN
	SELECT qsr.survey_sid, qsr.survey_response_id, CASE WHEN v_submission_id = 0 THEN qsr.survey_version ELSE qss.survey_version END
	  INTO out_survey_sid, out_survey_response_id, out_survey_version
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	 WHERE qss.submission_id = v_submission_id
	   AND qsr.survey_response_id = v_response_id;
END;

PROCEDURE GetSurveyVersionFromResponseId(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE,
	out_survey_sid					OUT	security_pkg.T_SID_ID,
	out_survey_version				OUT	quick_survey_version.survey_version%TYPE
)
AS
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
BEGIN
	CheckResponseAccess(in_response_id);

	SELECT qsr.survey_sid, CASE WHEN v_submission_id = 0 THEN qsr.survey_version ELSE qss.survey_version END
	  INTO out_survey_sid, out_survey_version
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	 WHERE qss.submission_id = v_submission_id
	   AND qsr.survey_response_id = in_response_id;
END;

FUNCTION GetSupplierSid(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_supplier_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(supplier_sid)
	  INTO v_supplier_sid
	  FROM supplier_survey_response
	 WHERE survey_response_id = in_response_id;

	RETURN v_supplier_sid;
END;

PROCEDURE GetQuestion(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_options_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid		security_pkg.T_SID_ID;
	v_survey_version	quick_survey_version.survey_version%TYPE;
BEGIN
	SELECT MIN(survey_sid)
	  INTO v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_question_id;

	v_survey_version := INTERNAL_GetSurveyVersion(v_survey_sid, in_survey_version);

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey sid '||v_survey_sid);
	END IF;

	OPEN out_cur FOR
		SELECT q.question_id, q.is_visible, q.label, q.question_type, qt.label question_type_label, q.score, q.lookup_Key,
			   qt.answer_type, q.question_version
		  FROM quick_survey_question q
		  JOIN question_type qt ON q.question_type = qt.question_type
		 WHERE q.question_id = in_question_id
		   AND q.survey_version = v_survey_version;

	OPEN out_options_cur FOR
		SELECT question_option_id, label, is_visible, score, color, lookup_Key
		  FROM qs_question_option
		 WHERE question_id = in_question_id
		   AND survey_version = v_survey_version;
END;

PROCEDURE GetCheckboxes(
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid		security_pkg.T_SID_ID;
	v_survey_version	quick_survey_version.survey_version%TYPE;
BEGIN
	SELECT MIN(survey_sid)
	  INTO v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_question_id;

	v_survey_version := GetSurveyVersion(v_survey_sid);

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey sid '||v_survey_sid);
	END IF;

	OPEN out_cur FOR
		SELECT cq.question_id, cq.label
		  FROM quick_survey_question q
		  JOIN quick_survey_question cq ON cq.parent_id = q.question_id
		 WHERE q.question_id = in_question_id
		   AND q.survey_version = v_survey_version
		   AND q.question_type = 'checkboxgroup'
		   AND cq.question_type = 'checkbox';
END;

PROCEDURE GetCustomQuestionTypes (
	in_custom_question_type_id	IN	qs_custom_question_type.custom_question_type_id%TYPE := NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security - we'll need to know details of custom question types when anonymous users use the survey
	OPEN out_cur FOR
		SELECT custom_question_type_id, description, js_include, js_class, cs_class
		  FROM qs_custom_question_type
		 WHERE app_sid = security_pkg.GetApp
		   AND (in_custom_question_type_id IS NULL OR custom_question_type_id = in_custom_question_type_id);
END;

PROCEDURE MapOptionQuestionToInd(
	in_survey_sid		IN quick_survey.survey_sid%TYPE,
	in_question_id		IN	quick_survey_question.question_id%TYPE,
	in_maps_to_ind_sid	IN	security_pkg.T_SID_ID
)
AS
	v_ind_sid		security_pkg.T_SID_ID;
	v_measure_sid	security_pkg.T_SID_ID;
	v_aggregate_ind_group_id aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	-- get or create a measure
	BEGIN
		SELECT measure_sid
		  INTO v_measure_sid
		  FROM measure
		 WHERE name = 'quick_survey_score'
		   AND app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name				=> 'quick_survey_score',
				in_description		=> 'Score',
				in_divisibility		=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				out_measure_sid		=> v_measure_sid
			);
	END;

	SELECT aggregate_ind_group_id
	  INTO v_aggregate_ind_group_id
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;

	-- XXX: I'm thinking there's more stuff I'm missing with stuff
	-- mapped to random things
	FOR r IN (
		SELECT question_option_id, label, i.measure_sid, i.ind_sid
		  FROM qs_question_option qo
		  LEFT JOIN ind i ON qo.maps_to_ind_sid = i.ind_sid AND i.parent_sid = in_maps_to_ind_sid
		 WHERE question_id = in_question_id
		   AND survey_version = 0
	)
	LOOP
		IF NVL(in_maps_to_ind_sid,-1) = -1 THEN
			--clear for all survey versions
			DELETE FROM aggregate_ind_group_member
			 WHERE ind_sid IN (SELECT maps_to_ind_sid FROM qs_question_option WHERE question_option_id = r.question_option_id)
			   AND aggregate_ind_group_id = v_aggregate_ind_group_id;

			UPDATE qs_question_option
			   SET maps_to_ind_sid = null
			 WHERE question_option_id = r.question_option_id;
		ELSE
			-- if the measures don't match then complain
			IF r.measure_sid != v_measure_sid OR (r.ind_sid IS NOT NULL AND r.measure_sid IS NULL) THEN
				RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace || 'Measure sid mismatch ' || r.measure_sid || '  ' || v_measure_sid);
			END IF;

			IF r.ind_sid IS NULL THEN
				-- create a new indicator
				BEGIN
					indicator_pkg.CreateIndicator(
						in_parent_sid_id 		=> in_maps_to_ind_sid,
						in_name 				=> REPLACE(r.label, '/', '\'), --'
						in_description 			=> r.label,
						in_active	 			=> 1,
						in_measure_sid			=> v_measure_sid,
						in_aggregate			=> 'SUM',
						out_sid_id				=> v_ind_sid
					);
				EXCEPTION
					WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
						-- reuse indicator (should be ok -- XXX: bit dodgy in that it checks the secobj name and ind.description might have been changed?)
						SELECT sid_id
						  INTO v_ind_sid
						  FROM security.securable_object
						 WHERE parent_sid_id = in_maps_to_ind_sid
						   AND LOWER(name) = LOWER(REPLACE(r.label, '/', '\'));  -- '
				END;

				UPDATE qs_question_option
				   SET maps_to_ind_sid = v_ind_sid
				 WHERE question_option_id = r.question_option_id
				   AND survey_version = 0;

				IF v_aggregate_ind_group_id IS NOT NULL THEN
					INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
					VALUES (v_aggregate_ind_group_id, v_ind_sid);
				END IF;
			END IF;
		END IF;
	END LOOP;
END;

PROCEDURE SetQuestionIndMappings(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_question_ids 		IN	security_pkg.T_SID_IDS,
	in_ind_sids 			IN 	security_pkg.T_SID_IDS,
	out_changed_measures	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_prev_measure_sid	security_pkg.T_SID_ID;
	v_new_measure_sid	security_pkg.T_SID_ID;
	v_question_type		question_type.question_type%TYPE;
	v_table 			T_FROM_TO_TABLE := T_FROM_TO_TABLE(); -- names dont' match but structure does!
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey');
	END IF;

	IF in_question_ids.COUNT = 0 OR (in_question_ids.COUNT = 1 AND in_question_ids(in_question_ids.FIRST) IS NULL) THEN
        -- hack for ODP.NET which doesn't support empty arrays - just return nothing
        NULL;
    ELSE
		-- probably not the most efficient approach, but we need to do quite a bit of a checking
		-- on merged values etc
		FOR i IN in_question_ids.FIRST .. in_question_ids.LAST
		LOOP
			BEGIN
				SELECT question_type
				  INTO v_question_type
				  FROM quick_survey_question qsq
				 WHERE qsq.question_id = in_question_ids(i)
				   AND qsq.survey_version = 0;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_question_type := NULL; -- Question was most likely deleted before it was ever saved.
			END;

			IF v_question_type IS NOT NULL THEN
				SELECT MIN(i.measure_sid) -- MIN also gets us a null if no data found
				  INTO v_prev_measure_sid
				  FROM quick_survey_question qsq
				  JOIN ind i ON qsq.maps_to_ind_sid = i.ind_sid AND qsq.app_sid = i.app_sid
				  JOIN quick_survey_answer qsa ON qsq.question_id = qsa.question_id AND qsa.question_version = qsq.question_version -- check we've got answers saved
				 WHERE qsq.question_id = in_question_ids(i)
				   AND qsq.survey_version = 0;

				SELECT MIN(measure_sid) -- MIN gets us a null if in_ind_sids(i) is -1 (which is our dummy null hack)
				  INTO v_new_measure_sid
				  FROM ind
				 WHERE ind_sid = in_ind_sids(i);

				IF v_question_type IN ('number','date','slider')
					AND v_prev_measure_sid IS NOT NULL
					AND null_pkg.ne(v_prev_measure_sid, v_new_measure_sid) THEN
					-- measure has changed and we have entered data...
					v_table.extend;
					v_table(v_table.COUNT) := T_FROM_TO_ROW(in_question_ids(i), v_prev_measure_sid);
				ELSE
					IF v_question_type IN ('radio') THEN
						-- extra stuff for child buttons
						MapOptionQuestionToInd(in_survey_sid, in_question_ids(i), in_ind_sids(i));
					END IF;
					-- ok -- do the update
					UPDATE quick_survey_question
					   SET maps_to_ind_sid = DECODE(in_ind_sids(i), -1, NULL, in_ind_sids(i)),
						   measure_sid = v_new_measure_sid
					 WHERE question_id = in_question_ids(i)
					   AND survey_version = 0;
				END IF;
			END IF;
		END LOOP;
	END IF;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid;

	OPEN out_changed_measures FOR
		SELECT t.from_sid question_id, t.to_sid prev_measure_sid, m.description prev_measure_description
		  FROM TABLE(v_table) t
		  JOIN measure m ON t.to_sid = m.measure_sid;
END;

PROCEDURE SetQuestionMeasureMappings(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_question_ids 		IN	security_pkg.T_SID_IDS,
	in_measure_sids 		IN 	security_pkg.T_SID_IDS,
	out_changed_measures	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_prev_measure_sid	security_pkg.T_SID_ID;
	v_new_measure_sid	security_pkg.T_SID_ID;
	v_question_type		question_type.question_type%TYPE;
	v_table 			T_FROM_TO_TABLE := T_FROM_TO_TABLE(); -- names dont' match but structure does!
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey');
	END IF;

	IF in_question_ids.COUNT = 0 OR (in_question_ids.COUNT = 1 AND in_question_ids(in_question_ids.FIRST) IS NULL) THEN
		-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		NULL;
	ELSE
		-- probably not the most efficient approach, but we need to do quite a bit of a checking
		-- on merged values etc
		FOR i IN in_question_ids.FIRST .. in_question_ids.LAST
		LOOP
			BEGIN
				SELECT question_type
				  INTO v_question_type
				  FROM quick_survey_question qsq
				 WHERE qsq.question_id = in_question_ids(i)
				   AND qsq.survey_sid = in_survey_sid
				   AND qsq.survey_version = 0;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_question_type := NULL; -- Question was most likely deleted before it was ever saved.
			END;

			IF v_question_type IS NOT NULL THEN
				SELECT MIN(NVL(i.measure_sid, m.measure_sid)) -- MIN also gets us a null if no data found
				  INTO v_prev_measure_sid
				  FROM quick_survey_question qsq
				  JOIN quick_survey_answer qsa ON qsq.question_id = qsa.question_id AND qsq.question_version = qsa.question_version -- check we've got answers saved
				  LEFT JOIN ind i ON qsq.maps_to_ind_sid IS NOT NULL AND qsq.app_sid = i.app_sid AND qsq.maps_to_ind_sid = i.ind_sid
				  LEFT JOIN measure m ON qsq.maps_to_ind_sid IS NULL AND qsq.app_sid = m.app_sid AND qsq.measure_sid = m.measure_sid
				 WHERE qsq.question_id = in_question_ids(i)
				   AND qsq.survey_version = 0;

				v_new_measure_sid := NULLIF(in_measure_sids(i), '-1');

				IF v_question_type IN ('number', 'slider')
					AND v_prev_measure_sid IS NOT NULL
					AND null_pkg.ne(v_prev_measure_sid, v_new_measure_sid) THEN
					-- measure has changed and we have entered data...
					v_table.extend;
					v_table(v_table.COUNT) := T_FROM_TO_ROW(in_question_ids(i), v_prev_measure_sid);
				ELSE
					-- ok -- do the update
					UPDATE quick_survey_question
					   SET measure_sid = v_new_measure_sid
					 WHERE question_id = in_question_ids(i)
					   AND survey_version = 0;
				END IF;
			END IF;
		END LOOP;
	END IF;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid;

	OPEN out_changed_measures FOR
		SELECT t.from_sid question_id, t.to_sid prev_measure_sid, m.description prev_measure_description
		  FROM TABLE(v_table) t
		  JOIN measure m ON t.to_sid = m.measure_sid;
END;

PROCEDURE SetQuestionTags(
	in_question_id				IN  quick_survey_question.question_id%TYPE,
	in_tag_ids 					IN	security_pkg.T_SID_IDS
)
AS
	v_survey_sid				security_pkg.T_SID_ID;
	t_tag_ids 					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_question_id
	   AND survey_version = 0;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey');
	END IF;

	-- XXX: We could push tags for the child questions of this question into quick_survey_question_tag
	-- if needed, but we'd need to add an inherited_from_question_id column
	DELETE FROM quick_survey_question_tag
	      WHERE question_id = in_question_id
		    AND survey_version = 0
			AND tag_id NOT IN (SELECT column_value FROM TABLE(t_tag_ids));

	INSERT INTO quick_survey_question_tag (question_id, tag_id, survey_version, survey_sid, question_version)
	     SELECT in_question_id, column_value, 0, v_survey_sid, 0 --temp fix for setting survey_sid and question version. Atm question_version matches survey_version
	       FROM TABLE(t_tag_ids)
		  WHERE column_value NOT IN (
			SELECT tag_id
			  FROM quick_survey_question_tag
			 WHERE question_id = in_question_id
			   AND survey_version = 0
		  );
END;

PROCEDURE SetResponseQuestionXml(
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	in_question_xml_override		IN  quick_survey_response.question_xml_override%TYPE
)
AS
BEGIN
	CheckResponseAccess(in_response_id);

	UPDATE quick_survey_response
	   SET question_xml_override = in_question_xml_override
	 WHERE survey_response_id = in_response_id;
END;

PROCEDURE GetResponseQuestionXml (
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	out_xml							OUT	quick_survey_response.question_xml_override%TYPE
)
AS
BEGIN
	CheckResponseAccess(in_response_id);

	SELECT question_xml_override
	  INTO out_xml
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;
END;

PROCEDURE GetResponseFilterQuestionIds (
	in_survey_sid				IN	csr.quick_survey.survey_sid%TYPE,
	in_survey_response_id		IN 	csr.quick_survey_answer.survey_response_id%TYPE,
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	ExecuteHelperProcReturnCursor(in_survey_sid, 'GetResponseFilterQuestionIds', in_survey_sid||', '||in_survey_response_id, out_cur);
END;

PROCEDURE GetSurveys(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetSurveys(in_parent_sid, NULL, NULL, out_cur);
END;

PROCEDURE GetSurveys(
	in_parent_sid		IN	security_pkg.T_SID_ID,
	in_filter			IN	VARCHAR2,
	in_audience			IN  quick_survey.audience%TYPE,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_write_permissions			security.T_SO_TABLE;
	v_view_results_permissions	security.T_SO_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_parent_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey list on parent_sid '||in_parent_sid);
	END IF;
	
	v_write_permissions := SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_WRITE);
	v_view_results_permissions := SecurableObject_pkg.GetChildrenWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS);

	-- for now just join to security
	OPEN out_cur FOR
		SELECT qs.survey_sid, so.name, qs.label, qs.audience, qs.group_key, qs.lookup_key,
			   wr.path, pwr.path parent_path, qs.created_dtm,
			   CASE WHEN pw.sid_id IS NULL THEN 0 ELSE 1 END is_editable,
			   CASE WHEN pr.sid_id IS NULL THEN 0 ELSE 1 END can_view_results,
			   qs.survey_is_published, qs.survey_has_unpublished_changes, in_parent_sid parent_sid,
			   qs.score_type_id, qs.score_type_label, qs.quick_survey_type_id, qs.quick_survey_type_desc,
			   qs.current_version, qs.from_question_library, qs.capture_geo_location
		  FROM v$quick_survey qs
		  JOIN security.securable_object so ON qs.survey_sid = so.sid_id
		  JOIN security.web_resource wr ON so.sid_Id = wr.sid_id
		  JOIN security.web_resource pwr ON so.parent_sid_id = pwr.sid_id
		  LEFT JOIN TABLE(v_write_permissions) pw ON pw.sid_id = qs.survey_sid
		  LEFT JOIN TABLE(v_view_results_permissions) pr ON pr.sid_id = qs.survey_sid
		 WHERE so.parent_sid_id = in_parent_sid
		   AND (pw.sid_id IS NOT NULL OR pr.sid_id IS NOT NULL)
		   AND (in_filter IS NULL OR LOWER(qs.label) LIKE in_filter||'%')
		   AND (in_audience IS NULL OR qs.audience = audience)
		 ORDER BY LOWER(qs.label);
END;

PROCEDURE GetSurvey(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_version						IN	quick_survey_version.survey_version%TYPE,
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE DEFAULT NULL,
	out_cur             			OUT security_pkg.T_OUTPUT_CUR,
	out_ind_mappings_cur    OUT security_pkg.T_OUTPUT_CUR,
	out_measures_cur    			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_version				quick_survey_version.survey_version%TYPE := in_version;
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey sid '||in_survey_sid);
	END IF;

	-- TODO: if it's ended then warn the user

	IF v_version IS NULL THEN
		SELECT current_version
		  INTO v_version
		  FROM quick_survey
		 WHERE survey_sid = in_survey_sid;

		IF v_version IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot get the current published version of survey with sid: '||in_survey_sid||' because it is has not been published.');
		END IF;
	END IF;

	OPEN out_cur FOR
		-- will be null if it's in the trash
        SELECT NVL(so.name,'(unnamed)') name, NVL(qsr.question_xml_override, qsv.question_xml) question_xml, NVL(wr.path,'/') path, NVL(pwr.path,'/') parent_path,
			   qsv.label, qs.survey_sid, qs.audience, qs.group_key, qs.lookup_key,
			   qst.helper_pkg type_helper_pkg, qst.cs_class type_cs_class, qst.show_answer_set_dtm,
			   qsv.survey_version, qs.current_version,
			CASE WHEN qsv.end_dtm IS NOT NULL AND qsv.end_dtm < SYSDATE THEN 1 ELSE 0 END is_closed,
			CASE WHEN qsv.start_dtm IS NOT NULL AND qsv.start_dtm > SYSDATE THEN 1 ELSE 0 END is_not_yet_open,
			CASE WHEN EXISTS (
				SELECT NULL
				  FROM quick_survey_question qsq
				  JOIN qs_question_option qso ON qsq.question_id = qso.question_id AND qsq.survey_version = qso.survey_version
				 WHERE qsq.is_visible = 1
				   AND qso.is_visible = 1
				   AND qsq.survey_sid = in_survey_sid
				   AND qsq.survey_version = v_version) THEN 1 ELSE 0 END has_score_questions,
			st.score_type_id, st.label score_type_label, st.format_mask score_type_format_mask,
			qs.quick_survey_type_id survey_type_id, qst.description survey_type_description, 
			qst.tearoff_toolbar, qst.capture_geo_location, qst.enable_response_import,
			qs.from_question_library 
		  FROM quick_survey qs
		  JOIN quick_survey_version qsv ON qs.survey_sid = qsv.survey_sid
		  JOIN security.securable_object so ON qs.survey_sid = so.sid_id
		  LEFT JOIN security.web_resource wr ON so.sid_id = wr.sid_id
		  LEFT JOIN security.web_resource pwr ON so.parent_sid_id = pwr.sid_id
		  LEFT JOIN quick_survey_type qst ON qs.quick_survey_type_id = qst.quick_survey_type_id
		  LEFT JOIN quick_survey_response qsr ON qs.survey_sid = qsr.survey_sid AND qsr.survey_response_id = in_response_id
		  LEFT JOIN score_type st ON st.score_type_id = qs.score_type_id
		 WHERE qs.survey_sid = in_survey_sid
		   AND qsv.survey_version = v_version;

	OPEN out_ind_mappings_cur FOR
		SELECT qsq.question_id, qsq.maps_to_ind_sid, qsq.measure_sid, NVL(i.format_mask, m.format_mask) format_mask, question_version
		  FROM quick_survey_question qsq
		  LEFT JOIN ind i ON qsq.app_sid = i.app_sid AND qsq.maps_to_ind_sid = i.ind_sid
		  LEFT JOIN measure m ON i.app_sid = m.app_sid AND (i.measure_sid = m.measure_sid OR qsq.measure_sid = m.measure_sid)
		 WHERE qsq.survey_sid = in_survey_sid
		   AND (qsq.maps_to_ind_sid IS NOT NULL OR qsq.measure_sid IS NOT NULL)
		   AND qsq.survey_version = v_version;

	OPEN out_measures_cur FOR
		SELECT DISTINCT m.measure_sid, m.description, mc.measure_conversion_id, mc.description measure_conversion_description
		  FROM quick_survey_question qsq
		  JOIN measure m ON qsq.measure_sid = m.measure_sid AND qsq.app_sid = m.app_sid
		  LEFT JOIN measure_conversion mc ON m.measure_sid = mc.measure_sid AND m.app_sid = mc.app_sid
		 WHERE qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = v_version;
END;

-- private
PROCEDURE NewResponse_(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_survey_version				IN	quick_survey_version.survey_version%TYPE := NULL,
	in_user_name					IN	quick_survey_response.user_name%TYPE := NULL,
	in_user_sid						IN	security_pkg.T_SID_ID := security_pkg.getsid,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	quick_survey_response.survey_response_id%TYPE
)
AS
	v_act_id			security_pkg.T_ACT_ID := security_pkg.getact;
	v_user_sid			security_pkg.T_SID_ID;
	v_user_name			QUICK_SURVEY_response.user_name%TYPE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, in_survey_version);
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied replying to survey sid '||in_survey_sid);
	END IF;

	v_user_name := in_user_name;
	v_user_sid := in_user_sid;

	IF v_user_sid = security_pkg.SID_BUILTIN_GUEST THEN
		-- anonymous
		v_user_sid := NULL;
	ELSE
		v_user_name := NULL;
	END IF;

	INSERT INTO quick_survey_response
		(survey_response_id, survey_sid, user_Sid, user_name, guid, survey_version)
	VALUES
		(survey_response_id_seq.nextval, in_survey_sid, v_user_sid, v_user_name, user_pkg.generateACT, v_survey_version)
	RETURNING survey_response_id, guid INTO out_response_id, out_guid;

	-- Create submission to store draft values
	INSERT INTO quick_survey_submission (survey_response_id, submission_id, survey_version)
	VALUES (out_response_id, 0, v_survey_version);
END;

PROCEDURE NewResponse(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_user_name		IN	QUICK_SURVEY_response.user_name%TYPE,
	out_guid			OUT quick_survey_response.guid%TYPE,
	out_response_id		OUT	QUICK_SURVEY_response.survey_response_id%TYPE
)
AS
BEGIN
	-- sec checks are done in before insert in overloaded function
	NewResponse_(
		in_survey_sid => in_survey_sid,
		in_survey_version => in_survey_version,
		in_user_name => in_user_name,
		out_guid => out_guid,
		out_response_id => out_response_id);
END;

-- special version for supply chain stuff --overload for backwards compatibility
PROCEDURE NewChainResponse(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID DEFAULT NULL, -- if null then pulls from context
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
)
AS
	v_is_new_response				NUMBER;
BEGIN
	GetOrCreateChainResponse(in_survey_sid, in_supplier_sid, NULL, v_is_new_response, out_guid, out_response_id);
END;

-- special version for supply chain stuff
PROCEDURE GetOrCreateChainResponse(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID DEFAULT NULL, -- if null then pulls from context
	in_component_id					IN  NUMBER,
	out_is_new_response				OUT NUMBER,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
)
AS
	v_user_sid					security_pkg.T_SID_ID;
	v_supplier_sid				security_pkg.T_SID_ID;
	v_count						NUMBER(10,0);
	v_questionnaire_id			chain.questionnaire.questionnaire_id%TYPE;
BEGIN
	v_user_sid := security_pkg.getSid;
	v_supplier_sid := COALESCE(in_supplier_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	v_questionnaire_id := chain.questionnaire_pkg.GetQuestionnaireId(v_supplier_sid, 'QuickSurvey.' || in_survey_sid, in_component_id);

	-- some sec checks are done in NewResponse but we need to do our own chain ones here too
	-- IF NOT chain.capability_pkg.CheckCapability(v_supplier_sid, chain.chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ) THEN
	IF NOT chain.questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain.chain_pkg.QUESTIONNAIRE_VIEW) THEN
	  --if the user followed a link, and is a member of more than one company it may be necessary to switch to the correct company first
	  --do this after checking capability first though since it may also be possible for the user to not be part of the supplier company but still have access to questionnaire data from it
		SELECT COUNT(*)
		  INTO v_count
		  FROM chain.v$company_user
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND company_sid = v_supplier_sid;

		IF v_supplier_sid != SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND v_count > 0 THEN
			chain.company_pkg.SetCompany(v_supplier_sid);
			--try again
			-- IF NOT chain.capability_pkg.CheckCapability(v_supplier_sid, chain.chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ) THEN
			IF NOT chain.questionnaire_security_pkg.CheckPermission(v_questionnaire_id, chain.chain_pkg.QUESTIONNAIRE_VIEW) THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading questionnaire for company sid '||v_supplier_sid);
			END IF;
		END IF;
	END IF;

	NewResponse_(
		in_survey_sid 			=> in_survey_sid,
		in_user_sid 			=> v_user_sid,
		out_guid 				=> out_guid,
		out_response_id 		=> out_response_id);

	-- RE Hard coded dates - this isn't going to work - e.g. getting ORA-01422: exact fetch returns more than requested number of rows
	-- if more than one year of data against the same survey.
	-- We need 1 response per chain questionnaire type and potentially more than one questionnaire type per survey

	BEGIN
		-- Hard coded dates!!!!
		-- This is a bit of a hack to show graphs in chain, but not every
		-- chain site is going to collect data like this
		INSERT INTO SUPPLIER_SURVEY_RESPONSE (
			supplier_sid, survey_sid, survey_response_id, component_id--, period_start_dtm, period_end_dtm
		) VALUES (
			v_supplier_sid, in_survey_sid, out_response_id, in_component_id--, TO_DATE('01-JAN-2012', 'dd-MON-yyyy'), TO_DATE('01-JAN-2013', 'dd-MON-yyyy')
		);

		out_is_new_response := 1;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- clean up (change SUPPLIER_SURVEY_RESPONSE.survey_response_id to NOT NULL DEFERRABLE INITIALLY DEFERRED)
			DELETE FROM quick_survey_submission
			 WHERE survey_response_id = out_response_id
			   AND submission_id = 0;
			DELETE FROM quick_survey_response
			 WHERE survey_response_id = out_response_id;
			-- get the existing id
			SELECT ssr.survey_response_id, qsr.guid
			  INTO out_response_id, out_guid
			  FROM supplier_survey_response ssr
			  JOIN quick_survey_response qsr ON ssr.survey_response_id = qsr.survey_response_id
			 WHERE ssr.survey_sid = in_survey_sid
			   AND ssr.supplier_sid = v_supplier_sid
			   AND (ssr.component_id = in_component_id OR ssr.component_id IS NULL AND in_component_id IS NULL);

			-- unhide if previously hidden
			UPDATE quick_survey_response
			   SET hidden = 0
			 WHERE survey_response_id = out_response_id
			   AND hidden = 1;

			out_is_new_response := 0;
	END;
END;

-- Special version
PROCEDURE GetOrCreateCampaignResponse(
	in_campaign_sid					IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_user_sid						IN	security_pkg.T_SID_ID := NULL,
	out_is_new_response				OUT NUMBER,
	out_guid						OUT quick_survey_response.guid%TYPE,
	out_response_id					OUT	QUICK_SURVEY_response.survey_response_id%TYPE
)
AS
	v_survey_sid					security_pkg.T_SID_ID;
	v_period_start_dtm				campaigns.campaign.period_start_dtm%TYPE;
	v_period_end_dtm				campaigns.campaign.period_end_dtm%TYPE;
	v_carry_forward					campaigns.campaign.carry_forward_answers%TYPE;
	v_from_response_id				NUMBER(10);
	v_from_submission_id			NUMBER(10);

	v_survey_version				quick_survey_response.survey_version%TYPE;
	v_hidden						NUMBER(1);
	v_campaign_details				campaigns.T_CAMPAIGN_TABLE;
BEGIN
	v_campaign_details := campaigns.campaign_pkg.GetCampaignDetails(in_campaign_sid);
	
	SELECT survey_sid, period_start_dtm, period_end_dtm, carry_forward_answers
	  INTO v_survey_sid, v_period_start_dtm, v_period_end_dtm, v_carry_forward
	  FROM TABLE(v_campaign_details);

	-- some usec checks are done in NewResponse but since this bit is done by the user distributing the survey
	-- we need some stricter checks - for now check that they can author the survey
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied distributing surveys for survey sid '||v_survey_sid);
	END IF;


	IF in_region_sid IS NOT NULL THEN
		-- get any existing response that is for the same survey, region and time period that isn't trashed
		BEGIN
			SELECT rsr.survey_response_id, qsr.guid, qsr.hidden
			  INTO out_response_id, out_guid, v_hidden
			  FROM region_survey_response rsr
			  JOIN quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id
			 WHERE rsr.region_sid = in_region_sid
			   AND rsr.survey_sid = v_survey_sid  -- do we need this check?
			   AND rsr.period_start_dtm = v_period_start_dtm  -- do we need this check?
			   AND qsr.qs_campaign_sid = in_campaign_sid;

			out_is_new_response := 0;

				-- unhide if previously hidden
			IF v_hidden = 1 THEN
				UPDATE quick_survey_response
				   SET hidden = 0
				 WHERE survey_response_id = out_response_id;
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				out_is_new_response := 1;

				NewResponse_(
					in_survey_sid => v_survey_sid,
					in_user_sid => NVL(in_user_sid, security_pkg.SID_BUILTIN_GUEST),
					out_guid => out_guid,
					out_response_id => out_response_id);

				UPDATE quick_survey_response
				   SET qs_campaign_sid = in_campaign_sid
				 WHERE survey_response_id = out_response_id;

				INSERT INTO region_survey_response (
					region_sid, survey_sid, survey_response_id, period_start_dtm, period_end_dtm
				) VALUES (
					in_region_sid, v_survey_sid, out_response_id, v_period_start_dtm, v_period_end_dtm
				);

				-- Check if we are carrying answers from the previous submission forward.
				IF v_carry_forward = 1 THEN
					BEGIN
						-- Get the most recent response and the most recent
						-- submission in the response.
						-- We get a NO_DATA_FOUND exception here (and catch
						-- it below) if there is no previously submitted data
						-- (i.e. created a new campaign).

						-- return the latest of the most recent audit or campaign survey (based on start date), unless it is
						-- beyond the end date of the campaign. If the most recent survey has not been submitted or is beyond the
						-- end date return nothing
						SELECT survey_response_id, last_submission_id
						  INTO v_from_response_id, v_from_submission_id
						  FROM
						  (
							SELECT dtm, survey_response_id, last_submission_id, ROWNUM rn
							  FROM
							  (
								SELECT rsr.period_start_dtm dtm, rsr.survey_response_id, qsr.last_submission_id
								  FROM region_survey_response rsr
								  JOIN quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id
								 WHERE rsr.region_sid = in_region_sid
								   AND rsr.survey_sid = v_survey_sid
								   AND qsr.hidden = 0
								   AND qsr.qs_campaign_sid != in_campaign_sid
								   AND NOT EXISTS(SELECT * FROM trash WHERE trash_sid = qsr.qs_campaign_sid)
								 UNION
								SELECT ia.audit_dtm dtm, ia.survey_response_id, qsr.last_submission_id
								  FROM internal_audit ia
								  JOIN quick_survey_response qsr ON ia.survey_response_id = qsr.survey_response_id
								 WHERE ia.region_sid = in_region_sid
								   AND ia.survey_sid = v_survey_sid
								   AND qsr.hidden = 0
								   AND ia.deleted = 0
								 ORDER BY dtm DESC
							  )
						  )
						 WHERE rn = 1
						   AND dtm <= v_period_end_dtm
						   AND last_submission_id IS NOT NULL;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							RETURN;
					END;
					CopyResponse(v_from_response_id, v_from_submission_id, out_response_id);
				END IF;
		END;
	ELSE
		out_is_new_response := 1;
		NewResponse_(
			in_survey_sid => v_survey_sid,
			in_user_sid => NVL(in_user_sid, security_pkg.SID_BUILTIN_GUEST),
			out_guid => out_guid,
			out_response_id => out_response_id);

		UPDATE quick_survey_response
		   SET qs_campaign_sid = in_campaign_sid
		 WHERE survey_response_id = out_response_id;

	END IF;
END;

-- TODO: pass in question_version, using survey_version for now because they will be in sync
PROCEDURE INTERNAL_AddAnswerFile (
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE
)
AS
	v_file_id				qs_answer_file.qs_answer_file_id%TYPE;
	v_survey_sid			quick_survey_version.survey_sid%TYPE;
	v_survey_version		quick_survey_version.survey_version%TYPE;
	v_sha1					RAW(20);
	v_uploaded_dtm			qs_response_file.uploaded_dtm%TYPE DEFAULT COALESCE(in_uploaded_dtm, SYSDATE);
BEGIN
	v_survey_version := INTERNAL_GetSubmSurveyVersion(in_response_id, 0);

	SELECT sys.dbms_crypto.hash(in_data, sys.dbms_crypto.hash_sh1) sha1
	  INTO v_sha1
	  FROM dual;

	BEGIN
		SELECT qs_answer_file_id
		  INTO v_file_id
		  FROM qs_answer_file
		 WHERE survey_response_id = in_response_id
		   AND question_id = in_question_id
		   AND sha1 = v_sha1
		   AND filename = in_filename
		   AND mime_type = in_mime_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_file_id := NULL;
	END;

	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id
	   AND survey_version = v_survey_version;

	IF v_file_id IS NULL THEN
		BEGIN
			INSERT INTO qs_response_file (survey_response_id, filename, mime_type, data, sha1, uploaded_dtm)
			VALUES (in_response_id, in_filename, in_mime_type, in_data, v_sha1, v_uploaded_dtm);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; --it's already there!
		END;

		INSERT INTO qs_answer_file (caption, filename, mime_type, qs_answer_file_id, question_id, sha1, survey_response_id, survey_version, survey_sid, question_version)
		VALUES (in_caption, in_filename, in_mime_type, qs_answer_file_id_seq.nextval, in_question_id, v_sha1, in_response_id, v_survey_version, v_survey_sid, v_survey_version)
		RETURNING qs_answer_file_id INTO v_file_id;
	END IF;

	BEGIN
		INSERT INTO qs_submission_file (qs_answer_file_id, survey_response_id, submission_id, survey_version)
		VALUES (v_file_id, in_response_id, 0, v_survey_version);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; --it's already there!
	END;
END;

PROCEDURE INTERNAL_AddAnswerFile (
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_file_id				qs_answer_file.qs_answer_file_id%TYPE;
	v_survey_sid			quick_survey_version.survey_sid%TYPE;
	v_survey_version		quick_survey_version.survey_version%TYPE;
	v_sha1					RAW(20);
	v_uploaded_dtm			qs_response_file.uploaded_dtm%TYPE DEFAULT COALESCE(in_uploaded_dtm, SYSDATE);
BEGIN
	v_survey_version := INTERNAL_GetSubmSurveyVersion(in_response_id, 0);

	SELECT sys.dbms_crypto.hash(in_data, sys.dbms_crypto.hash_sh1) sha1
	  INTO v_sha1
	  FROM dual;

	BEGIN
		SELECT qs_answer_file_id
		  INTO v_file_id
		  FROM qs_answer_file
		 WHERE survey_response_id = in_response_id
		   AND question_id = in_question_id
		   AND sha1 = v_sha1
		   AND filename = in_filename
		   AND mime_type = in_mime_type;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_file_id := NULL;
	END;

	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id
	   AND survey_version = v_survey_version;

	IF v_file_id IS NULL THEN
		BEGIN
			INSERT INTO qs_response_file (survey_response_id, filename, mime_type, data, sha1, uploaded_dtm)
			VALUES (in_response_id, in_filename, in_mime_type, in_data, v_sha1, v_uploaded_dtm);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; --it's already there!
		END;

		INSERT INTO qs_answer_file (caption, filename, mime_type, qs_answer_file_id, question_id, sha1, survey_response_id, survey_version, survey_sid, question_version)
		VALUES (in_caption, in_filename, in_mime_type, qs_answer_file_id_seq.nextval, in_question_id, v_sha1, in_response_id, v_survey_version, v_survey_sid, v_survey_version)
		RETURNING qs_answer_file_id INTO v_file_id;
	END IF;

	BEGIN
		INSERT INTO qs_submission_file (qs_answer_file_id, survey_response_id, submission_id, survey_version)
		VALUES (v_file_id, in_response_id, 0, v_survey_version);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; --it's already there!
	END;
	
	OPEN out_cur FOR
		SELECT qs_answer_file_id, survey_response_id, question_id, filename, mime_type, cast(sha1 as varchar2(40)) sha1, caption
		  FROM qs_answer_file
		 WHERE qs_answer_file_id = v_file_id;
END;

PROCEDURE CopyResponse (
	in_from_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_from_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_to_response_id			IN	quick_survey_response.survey_response_id%TYPE
)
AS
	v_survey_version				NUMBER;
	v_survey_sid					quick_survey_response.survey_sid%TYPE;
	v_from_submission_id			quick_survey_submission.submission_id%TYPE := in_from_submission_id;

	-- Stuff used for carrying forward files... Yucky.
	v_file_caption					qs_answer_file.caption%TYPE;
	v_file_data						qs_response_file.data%TYPE;	-- Is storing a file in memory a good idea?
	v_filename						qs_answer_file.filename%TYPE;
	v_mime_type						qs_answer_file.mime_type%TYPE;
	v_question_id					qs_answer_file.question_id%TYPE;
	v_uploaded_dtm					qs_response_file.uploaded_dtm%TYPE;
	v_carry_forward_file_id			qs_answer_file.qs_answer_file_id%TYPE;
BEGIN
	IF in_from_submission_id IS NULL THEN
		SELECT last_submission_id
		  INTO v_from_submission_id
		  FROM quick_survey_response
		 WHERE survey_response_id = in_from_response_id;
	END IF;

	CheckResponseAccess(in_from_response_id, 0);
	CheckResponseAccess(in_to_response_id, 1);

	SELECT survey_version, survey_sid
	  INTO v_survey_version, v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_to_response_id;


	-- Copy all answers from previous submission into a new one.
		INSERT INTO quick_survey_answer (survey_response_id, question_id, note, score, question_option_id,
			   val_number, measure_conversion_id, measure_sid, region_sid, answer, html_display, max_score,
			   version_stamp, submission_id, survey_version, log_item, question_version, survey_sid)
		SELECT in_to_response_id, question_id, note, score, question_option_id, val_number, measure_conversion_id,
			   measure_sid, region_sid, answer, html_display, max_score, version_stamp, 0, v_survey_version, log_item, v_survey_version, v_survey_sid
		  FROM quick_survey_answer
		 WHERE survey_response_id = in_from_response_id
		   AND submission_id = v_from_submission_id
		   AND question_id NOT IN (
			SELECT question_id
			  FROM quick_survey_answer
			 WHERE survey_response_id = in_to_response_id
			   AND submission_id = 0
		   );

		-- For each submitted file, copy to new response.
		FOR r IN (
			SELECT qs_answer_file_id, survey_response_id, submission_id
			  FROM qs_submission_file
			 WHERE survey_response_id = in_from_response_id
			   AND submission_id = v_from_submission_id
		)
		LOOP
			-- Not sure if there is a nicer way, but I need this data
			-- Can't do this as part of the insert because I'm using 'RETURNING'.
			SELECT af.caption, rf.data, rf.filename, rf.mime_type, af.question_id, rf.uploaded_dtm
			  INTO v_file_caption, v_file_data, v_filename, v_mime_type, v_question_id, v_uploaded_dtm
			  FROM qs_answer_file af
			  JOIN qs_response_file rf ON af.app_sid = rf.app_sid AND af.survey_response_id = rf.survey_response_id AND af.sha1 = rf.sha1 AND af.filename = rf.filename AND af.mime_type = rf.mime_type
			 WHERE af.survey_response_id = in_from_response_id
			   AND af.qs_answer_file_id = r.qs_answer_file_id;

			-- For each file answer, copy the files to
			-- the new submission.
			INTERNAL_AddAnswerFile(
				in_response_id			=> in_to_response_id,
				in_question_id			=> v_question_id,
				in_filename				=> v_filename,
				in_mime_type			=> v_mime_type,
				in_data					=> v_file_data,
				in_caption				=> v_file_caption,
				in_uploaded_dtm			=> v_uploaded_dtm
			);
		END LOOP;
END;

PROCEDURE CopyAnswer (
	in_from_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_from_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_from_question_id			IN	quick_survey_question.question_id%TYPE,
	in_to_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	--in_to_submission_id			IN	quick_survey_submission.submission_id%TYPE, --always copies into submission 0, and also doesn't overwrite (should it?)
	in_to_question_id			IN	quick_survey_question.question_id%TYPE
)
AS
	v_survey_version				NUMBER;
	v_from_survey_version			NUMBER;
	v_carry_forward_file_id			qs_answer_file.qs_answer_file_id%TYPE;
	v_count							NUMBER;
	v_measure_sid					security_pkg.T_SID_ID;
	v_survey_sid					security_pkg.T_SID_ID;
BEGIN
	CheckResponseAccess(in_from_response_id, 0);
	CheckResponseAccess(in_to_response_id, 1);

	SELECT survey_version
	  INTO v_survey_version
	  FROM quick_survey_response
	 WHERE survey_response_id = in_to_response_id;

	SELECT survey_version
	  INTO v_from_survey_version
	  FROM quick_survey_response
	 WHERE survey_response_id = in_from_response_id;

	SELECT COUNT(*)
	  INTO v_count
	  FROM quick_survey_answer
	 WHERE survey_response_id = in_to_response_id AND question_id = in_to_question_id AND submission_id = 0;

	SELECT measure_sid, survey_sid
	  INTO v_measure_sid, v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_to_question_id
	   AND survey_version = v_survey_version;

	IF v_count = 0 THEN
		-- Copy all answers from previous submission into a new one.
		INSERT INTO quick_survey_answer (survey_response_id, question_id, note, score, question_option_id,
			   val_number, measure_conversion_id, measure_sid, region_sid, answer, html_display, max_score,
			   version_stamp, submission_id, survey_version, log_item, question_version, survey_sid)
		SELECT in_to_response_id, in_to_question_id, note, score, TryGetQuestionOption(question_id, question_option_id, in_to_question_id, v_from_survey_version), val_number, measure_conversion_id,
			   v_measure_sid, region_sid, answer, html_display, max_score, version_stamp, 0, v_survey_version, log_item, v_survey_version, v_survey_sid
		  FROM quick_survey_answer
		 WHERE survey_response_id = in_from_response_id
		   AND submission_id = in_from_submission_id
		   AND question_id = in_from_question_id;
	ELSE
		UPDATE quick_survey_answer
		   SET (note, score, question_option_id, val_number, measure_conversion_id,
			measure_sid, region_sid, answer, html_display, max_score, version_stamp, survey_version, question_version) = (
				SELECT note, score, TryGetQuestionOption(question_id, question_option_id, in_to_question_id, v_from_survey_version), val_number, measure_conversion_id,
					v_measure_sid, region_sid, answer, html_display, max_score, version_stamp, v_survey_version, v_survey_version
				  FROM quick_survey_answer
				 WHERE survey_response_id = in_from_response_id
				   AND submission_id = in_from_submission_id
				   AND question_id = in_from_question_id
			)
		 WHERE survey_response_id = in_to_response_id AND question_id = in_to_question_id AND submission_id = 0;
	END IF;

	-- For each submitted file, copy to new response.
	FOR r IN (
		SELECT qaf.filename, qaf.mime_type, qrf.data, qaf.caption, qrf.uploaded_dtm
		  FROM qs_submission_file qsf
		  JOIN qs_answer_file qaf
			ON qsf.qs_answer_file_id = qaf.qs_answer_file_id
		   AND qsf.survey_response_id = qaf.survey_response_id
		  JOIN qs_response_file qrf
		    ON qaf.app_sid = qrf.app_sid
		   AND qaf.survey_response_id = qrf.survey_response_id
		   AND qaf.sha1 = qrf.sha1
		   AND qaf.filename = qrf.filename
		   AND qaf.mime_type = qrf.mime_type
		 WHERE qsf.survey_response_id = in_from_response_id
		   AND qsf.submission_id = in_from_submission_id
		   AND qaf.question_id = in_from_question_id

	)
	LOOP
		-- For each file answer, copy the files to
		-- the new submission.
		INTERNAL_AddAnswerFile(
			in_response_id			=> in_to_response_id,
			in_question_id			=> in_to_question_id,
			in_filename				=> r.filename,
			in_mime_type			=> r.mime_type,
			in_data					=> r.data,
			in_caption				=> r.caption,
			in_uploaded_dtm			=> r.uploaded_dtm
		);
	END LOOP;
END;

--tries to get an equivalent question option id based on question option lookup keys, returns null if it can't find one
FUNCTION TryGetQuestionOption(
	in_from_question_id			IN	quick_survey_question.question_id%TYPE,
	in_from_question_option_id	IN	qs_question_option.question_option_id%TYPE,
	in_to_question_id			IN	quick_survey_question.question_id%TYPE,
	in_from_survey_version		IN 	NUMBER
) RETURN NUMBER
AS
	v_to_question_option			qs_question_option.question_option_id%TYPE DEFAULT NULL;
BEGIN
	SELECT DISTINCT question_option_id
	  INTO v_to_question_option
	  FROM csr.qs_question_option
	 WHERE question_id = in_to_question_id
	   AND is_visible = 1
	   AND lookup_key = (
		SELECT lookup_key
		  FROM csr.qs_question_option
		 WHERE question_id = in_from_question_id
		   AND is_visible = 1
		   AND question_option_id = in_from_question_option_id
		   AND survey_version = in_from_survey_version );

	RETURN v_to_question_option;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
END;

PROCEDURE GetSupplierSid(
	in_guid				IN	quick_survey_response.guid%TYPE,
	out_supplier_sid	OUT	security_pkg.T_SID_ID
)
AS
BEGIN
-- No permissions if they know the guid
	SELECT supplier_sid
	  INTO out_supplier_sid
	  FROM supplier_survey_response ssr
	  JOIN quick_survey_response qsr ON ssr.survey_response_id = qsr.survey_response_id
	 WHERE qsr.guid = in_guid;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		out_supplier_sid := -1; -- db.RunSPReturnInt64 won't like nulls - return -1
END;

PROCEDURE GetSupplierComponentIds(
	in_guid				IN	quick_survey_response.guid%TYPE,
	out_supplier_sid	OUT	security_pkg.T_SID_ID,
	out_component_id	OUT	supplier_survey_response.component_id%TYPE
)
AS
BEGIN
	-- No permissions if they know the guid
	SELECT supplier_sid, component_id
	  INTO out_supplier_sid, out_component_id
	  FROM supplier_survey_response ssr
	  JOIN quick_survey_response qsr ON ssr.survey_response_id = qsr.survey_response_id
	 WHERE qsr.guid = in_guid;
END;

PROCEDURE GetAnswerNonCompliances(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	quick_survey_question.question_id%TYPE,
	out_nc_cur             	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	OPEN out_nc_cur FOR
		SELECT nc.non_compliance_id, nc.label, nc.detail, nc.created_dtm, nc.is_closed
		  FROM non_compliance nc
		  JOIN audit_non_compliance anc ON nc.app_sid = anc.app_sid AND nc.non_compliance_id = anc.non_compliance_id
		  JOIN internal_audit ia ON anc.app_sid = ia.app_sid AND anc.internal_audit_sid = ia.internal_audit_sid
		 WHERE ia.survey_response_id = v_response_id
		   AND nc.question_id = in_question_id
		 ORDER BY nc.created_dtm;
END;

PROCEDURE GetAnswerLog(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	quick_survey_question.question_id%TYPE,
	out_cur             	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	OPEN out_cur FOR
		SELECT l.set_dtm, u.full_name user_name, u.email user_email, l.log_item
		  FROM qs_answer_log l
		  LEFT JOIN csr.csr_user u ON l.app_sid = u.app_sid AND l.set_by_user_sid = u.csr_user_sid
		 WHERE l.survey_response_id = v_response_id
		   AND l.question_id = in_question_id
		 ORDER BY set_dtm DESC;
END;

PROCEDURE INTERNAL_LogAnswerChange (
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_question_id				IN	quick_survey_answer.question_id%TYPE,
	in_question_version			IN	quick_survey_answer.question_version%TYPE,
	in_submission_id			IN	quick_survey_answer.submission_id%TYPE,
	in_log_item					IN	quick_survey_answer.log_item%TYPE,
	in_version_stamp			IN	quick_survey_answer.version_stamp%TYPE
)
AS
BEGIN
	INSERT INTO qs_answer_log (qs_answer_log_id, survey_response_id, question_id, version_stamp, submission_id, set_by_user_sid, log_item, question_version)
	VALUES (qs_answer_log_id_seq.NEXTVAL, in_response_id, in_question_id, in_version_stamp, in_submission_id, SYS_CONTEXT('SECURITY','SID'), in_log_item, in_question_version);
END;

PROCEDURE UNSEC_UpdateOtherTextScores(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE
)
AS
BEGIN
	-- No security - only used by internal calculations
	UPDATE quick_survey_answer
	   SET score = 0
	 WHERE survey_response_id = in_response_id
	   AND submission_id = in_submission_id
	   AND question_id IN (
		SELECT qsq.question_id
		  FROM quick_survey_question qsq
		  JOIN qs_question_option qsqo
			ON qsqo.question_id = qsq.question_id
		   AND qsqo.survey_version = qsq.survey_version
		  JOIN quick_survey_answer qsa
			ON qsa.question_id = qsqo.question_id
		   AND qsa.question_option_id = qsqo.question_option_id
		   AND qsa.survey_version = qsqo.survey_version
		   AND qsa.question_version = qsq.question_version
		 WHERE qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = in_submission_id
		   AND qsq.question_type = 'radio'
		   AND qsqo.option_action = 'other'
		   AND qsa.answer IS NULL
		   AND qsa.score IS NOT NULL
		   AND qsq.has_score_expression = 0
		 UNION
		SELECT qsq.question_id
		  FROM quick_survey_question qsq
		  JOIN quick_survey_answer qsa
			ON qsa.question_id = qsq.question_id
		   AND qsa.survey_version = qsq.survey_version
		   AND qsa.question_version = qsq.question_version
		  JOIN quick_survey_question par
		    ON par.question_id = qsq.parent_id
		   AND par.question_version = qsq.question_version
		   AND par.survey_version = qsq.survey_version
		 WHERE qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = in_submission_id
		   AND qsq.question_type = 'checkbox'
		   AND par.question_type = 'checkboxgroup'
		   AND qsq.action = 'other'
		   AND qsa.answer IS NULL
		   AND qsa.score IS NOT NULL
		   AND par.has_score_expression = 0
		);
END;

PROCEDURE UpgradeResponseDraft(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_new_version				IN	quick_survey_version.survey_version%TYPE
)
AS
BEGIN
	UPDATE quick_survey_submission
	   SET survey_version = in_new_version
	 WHERE survey_response_id = in_response_id
	  AND submission_id = 0;

	UPDATE quick_survey_answer
	   SET survey_version = in_new_version,
		   question_version = in_new_version
	 WHERE survey_response_id = in_response_id
	  AND submission_id = 0;

	UPDATE qs_submission_file
	   SET survey_version = in_new_version
	 WHERE survey_response_id = in_response_id
	  AND submission_id = 0;
END;


PROCEDURE INTERNAL_SetAnswer(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_question_id				IN	quick_survey_answer.question_id%TYPE,
	in_answer					IN	quick_survey_answer.answer%TYPE,
	in_note						IN	quick_survey_answer.note%TYPE,
	in_question_option_id		IN	quick_survey_answer.question_option_id%TYPE,
	in_val_number				IN	quick_survey_answer.val_number%TYPE,
	in_measure_conversion_id	IN	quick_survey_answer.measure_conversion_id%TYPE,
	in_region_sid				IN	quick_survey_answer.region_sid%TYPE,
	in_html_display				IN	quick_survey_answer.html_display%TYPE,
	in_score					IN	quick_survey_answer.score%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE,
	in_version_stamp			IN	quick_survey_answer.version_stamp%TYPE,
	in_log_item					IN	quick_survey_answer.log_item%TYPE
)
AS
	v_measure_sid		security_pkg.T_SID_ID;
	v_end_dtm			quick_survey_version.end_dtm%TYPE;
	v_question_version	quick_survey_question.question_version%TYPE;
	v_survey_sid		quick_survey_version.survey_sid%TYPE;
	v_survey_version	quick_survey_version.survey_version%TYPE;
	v_submission_ver	quick_survey_submission.survey_version%TYPE;
	v_count				NUMBER;
	v_version_stamp		quick_survey_answer.version_stamp%TYPE;
	v_new_log_item		quick_survey_answer.log_item%TYPE := in_log_item;
	v_old_log_item		quick_survey_answer.log_item%TYPE;
	v_qo_label			qs_question_option.label%TYPE;
BEGIN
	IF in_submission_id != 0 THEN
		SELECT survey_version
		  INTO v_survey_version
		  FROM quick_survey_submission
		 WHERE submission_id = in_submission_id
		   AND survey_response_id = in_response_id;
	ELSE
		-- ok -- check survey is not closed and that the submission version is correct
		SELECT qsv.end_dtm, qsr.survey_version, qss.survey_version
		  INTO v_end_dtm, v_survey_version, v_submission_ver
		  FROM quick_survey_question qsq
		  JOIN quick_survey_response qsr ON qsq.survey_sid = qsr.survey_sid AND qsq.survey_version = qsr.survey_version
		  JOIN quick_survey_version qsv ON qsr.survey_sid = qsv.survey_sid AND qsr.survey_version = qsv.survey_version
		  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id AND qss.submission_id = 0
		 WHERE qsq.question_id = in_question_id
		   AND qsr.survey_response_id = in_response_id;

		IF v_end_dtm IS NOT NULL AND v_end_dtm < SYSDATE THEN
			RAISE_APPLICATION_ERROR(-20001, 'Survey is closed -- cannot set answers');
		END IF;
		
		IF v_survey_version > v_submission_ver THEN
			UpgradeResponseDraft(in_response_id, v_survey_version);
		END IF;
	END IF;

	SELECT measure_sid, question_version, survey_sid
	  INTO v_measure_sid, v_question_version, v_survey_sid
	  FROM quick_survey_question
	 WHERE question_id = in_question_id
	   AND survey_version = v_survey_version;

	IF v_new_log_item IS NULL THEN
		-- hmm, let's just try our best
		IF in_question_option_id IS NULL THEN
			v_new_log_item := NVL(in_answer, to_clob(in_val_number));
		ELSE
			SELECT label
			  INTO v_qo_label
			  FROM qs_question_option
			 WHERE question_id = in_question_id
			   AND question_option_id = in_question_option_id
			   AND survey_version = v_survey_version;

			v_new_log_item := v_qo_label || CASE WHEN in_answer IS NOT NULL THEN ': ' || in_answer ELSE '' END;
		END IF;
	END IF;

	-- insert or update
	BEGIN
		INSERT INTO quick_survey_answer
			(survey_response_id, question_id, answer, note, question_option_id, val_number, measure_sid, measure_conversion_id, 
				region_sid, html_display, score, max_score, log_item, version_stamp, submission_id, survey_version, question_version, survey_sid)
		VALUES
			(in_response_id, in_question_id, in_answer, in_note, in_question_option_id, in_val_number, v_measure_sid, in_measure_conversion_id, 
				in_region_sid, in_html_display, in_score, in_max_score, v_new_log_item, version_stamp_seq.NEXTVAL, in_submission_id, v_survey_version, v_question_version, v_survey_sid)
		RETURNING version_stamp INTO v_version_stamp;
		INTERNAL_LogAnswerChange(
			in_response_id			=> in_response_id,
			in_question_id			=> in_question_id,
			in_question_version		=> v_question_version,
			in_submission_id		=> in_submission_id,
			in_log_item				=> v_new_log_item,
			in_version_stamp		=> v_version_stamp
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			SELECT log_item
			  INTO v_old_log_item
			  FROM quick_survey_answer
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id
			   AND submission_id = in_submission_id;

			UPDATE quick_survey_answer
			   SET answer = in_answer,
				note = in_note,
				question_option_id = in_question_option_id,
				val_number = in_val_number,
				measure_conversion_id = in_measure_conversion_id,
				region_sid = in_region_Sid,
				measure_sid = v_measure_sid,
				html_display = in_html_display,
				score = in_score,
				max_score = in_max_score,
				survey_version = v_survey_version,
				question_version = v_question_version,
				version_stamp = version_stamp_seq.NEXTVAL
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id
			   AND survey_sid = v_survey_sid
			   AND submission_id = in_submission_id
			   AND (version_stamp = in_version_stamp OR in_version_stamp = -1)
			   AND ( -- Only update version_stamp if the value has changed
				null_pkg.sne(question_option_id, in_question_option_id)=1 OR
				null_pkg.sne(val_number, in_val_number)=1 OR
				null_pkg.sne(measure_conversion_id, in_measure_conversion_id)=1 OR
				null_pkg.sne(region_sid, in_region_sid)=1 OR
				null_pkg.sne(score, in_score)=1 OR
				null_pkg.sne(max_score, in_max_score)=1 OR
				null_pkg.sne(answer, in_answer)=1 OR
				null_pkg.sne(note, in_note)=1
			   );

			IF SQL%ROWCOUNT = 0 THEN
				-- Either the value hasn't changed or the version stamp was wrong
				SELECT COUNT(*)
				  INTO v_count
				  FROM quick_survey_answer
				 WHERE survey_response_id = in_response_id
				   AND question_id = in_question_id
				   AND submission_id = in_submission_id
				   AND  -- It's OK if the value we're setting to is the same as in the data
					null_pkg.seq(question_option_id, in_question_option_id)=1 AND
					null_pkg.seq(val_number, in_val_number)=1 AND
					null_pkg.seq(measure_conversion_id, in_measure_conversion_id)=1 AND
					null_pkg.seq(region_sid, in_region_sid)=1 AND
					null_pkg.seq(score, in_score)=1 AND
					null_pkg.seq(max_score, in_max_score)=1 AND
					null_pkg.seq(answer, in_answer)=1 AND
					null_pkg.seq(note, in_note)=1
				   ;

				IF v_count = 0 THEN
					RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CONCURRENCY_CONFLICT, 'Concurrency error. Another user has updated this answer since this user read it');
				END IF;
			END IF;

			IF null_pkg.ne(v_new_log_item, v_old_log_item) THEN
				UPDATE quick_survey_answer
				   SET log_item = v_new_log_item
				 WHERE survey_response_id = in_response_id
				   AND question_id = in_question_id
				   AND submission_id = in_submission_id
			 RETURNING version_stamp INTO v_version_stamp;
				INTERNAL_LogAnswerChange(
					in_response_id			=> in_response_id,
					in_question_id			=> in_question_id,
					in_question_version		=> v_question_version,
					in_submission_id		=> in_submission_id,
					in_log_item				=> v_new_log_item,
					in_version_stamp		=> v_version_stamp
				);
			END IF;
	END;
END;

PROCEDURE INTERNAL_SetAnswer(
	in_response_id				IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_question_id				IN	quick_survey_answer.question_id%TYPE,
	in_answer					IN	quick_survey_answer.answer%TYPE,
	in_note						IN	quick_survey_answer.note%TYPE,
	in_question_option_id		IN	quick_survey_answer.question_option_id%TYPE,
	in_val_number				IN	quick_survey_answer.val_number%TYPE,
	in_measure_conversion_id	IN	quick_survey_answer.measure_conversion_id%TYPE,
	in_region_sid				IN	quick_survey_answer.region_sid%TYPE,
	in_html_display				IN	quick_survey_answer.html_display%TYPE,
	in_score					IN	quick_survey_answer.score%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE,
	in_version_stamp			IN	quick_survey_answer.version_stamp%TYPE,
	in_log_item					IN	quick_survey_answer.log_item%TYPE
)
AS
BEGIN
	INTERNAL_SetAnswer(
		in_response_id,
		0,
		in_question_id,
		in_answer,
		in_note,
		in_question_option_id,
		in_val_number,
		in_measure_conversion_id,
		in_region_sid,
		in_html_display,
		in_score,
		in_max_score,
		in_version_stamp,
		in_log_item);

END;

PROCEDURE SetAnswerForResponseGuid(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_id				IN	quick_survey_answer.question_id%TYPE,
	in_answer					IN	quick_survey_answer.answer%TYPE DEFAULT NULL,
	in_note						IN	quick_survey_answer.note%TYPE DEFAULT NULL,
	in_question_option_id		IN	quick_survey_answer.question_option_id%TYPE DEFAULT NULL,
	in_val_number				IN	quick_survey_answer.val_number%TYPE DEFAULT NULL,
	in_measure_conversion_id	IN	quick_survey_answer.measure_conversion_id%TYPE DEFAULT NULL,
	in_region_sid				IN	quick_survey_answer.region_sid%TYPE DEFAULT NULL,
	in_html_display				IN	quick_survey_answer.html_display%TYPE DEFAULT NULL,
	in_score					IN	quick_survey_answer.score%TYPE DEFAULT NULL,
	in_max_score				IN	quick_survey_answer.max_score%TYPE DEFAULT NULL,
	in_version_stamp			IN	quick_survey_answer.version_stamp%TYPE DEFAULT -1,
	in_log_item					IN	quick_survey_answer.log_item%TYPE DEFAULT NULL
)
AS
	v_response_id				quick_survey_response.survey_response_id%TYPE;
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	INTERNAL_SetAnswer(v_response_id, in_question_id, in_answer, in_note, in_question_option_id,
		in_val_number, in_measure_conversion_id, in_region_sid, in_html_display, in_score, in_max_score,
		in_version_stamp, in_log_item);
END;

PROCEDURE EmptyAnswers(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_ids				IN	security.security_pkg.T_SID_IDS
)
AS
	v_response_id		quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid, 1);
	UNSEC_EmptyAnswers(v_response_id, 0, in_question_ids);
END;

PROCEDURE UNSEC_EmptyAnswers(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids				IN	security.security_pkg.T_SID_IDS
)
AS
	v_question_ids		security.T_SID_TABLE;
BEGIN
	v_question_ids := security.security_pkg.SidArrayToTable(in_question_ids);

	FOR r IN (
		SELECT column_value question_id
		  FROM TABLE(v_question_ids)
	) LOOP
		INTERNAL_SetAnswer(in_response_id, in_submission_id, r.question_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, -1, NULL);
	END LOOP;
END;

PROCEDURE GetResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	OPEN out_cur FOR
		SELECT cast(sha1 as varchar2(40)) sha1, filename, mime_type, uploaded_dtm
		  FROM csr.qs_response_file
		 WHERE app_sid = security.security_pkg.GetApp
		   AND survey_response_id = v_response_id;
END;


PROCEDURE GetResponseFiles(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckResponseAccess(in_response_id, 0);
	
	OPEN out_cur FOR
		SELECT filename, mime_type, uploaded_dtm, data
		  FROM csr.qs_response_file
		 WHERE app_sid = security.security_pkg.GetApp
		   AND survey_response_id = in_response_id;
END;

PROCEDURE GetResponseFile(
	in_sha1			IN	qs_response_file.sha1%TYPE,
	in_filename		IN	qs_response_file.filename%TYPE,
	in_mime_type	IN	qs_response_file.mime_type%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT data, uploaded_dtm, mime_type, filename
		  FROM csr.qs_response_file
		 WHERE app_sid = security.security_pkg.GetApp
		   AND sha1 = in_sha1
		   AND filename = in_filename
		   AND mime_type = in_mime_type
		   AND rownum = 1;
END;

PROCEDURE AddResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_cache_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_cache_key_tbl			security.T_VARCHAR2_TABLE := security.security_pkg.Varchar2ArrayToTable(in_cache_keys);
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	INSERT INTO qs_response_file (survey_response_id, filename, mime_type, data, sha1, uploaded_dtm)
		SELECT v_response_id, fc.filename, fc.mime_type, fc.object data, sys.dbms_crypto.hash(fc.object, sys.dbms_crypto.hash_sh1) sha1, SYSDATE
		  FROM aspen2.filecache fc
		  JOIN TABLE(v_cache_key_tbl) ck ON fc.cache_key = ck.value
		 WHERE (fc.filename, fc.mime_type, sys.dbms_crypto.hash(fc.object, sys.dbms_crypto.hash_sh1)) NOT IN (
			SELECT filename, mime_type, sha1
			  FROM qs_response_file
			 WHERE survey_response_id = v_response_id);
END;

PROCEDURE RemoveResponseFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_remove_sha1s			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_remove_filenames		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_remove_mimetypes		IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	IF in_remove_sha1s.COUNT <> in_remove_filenames.COUNT OR in_remove_sha1s.COUNT <> in_remove_mimetypes.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'Arrays should have the same length.');
	END IF;

	IF in_remove_sha1s.COUNT = 0 OR (in_remove_sha1s.COUNT = 1 AND in_remove_sha1s(in_remove_sha1s.FIRST) IS NULL) THEN
		-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN; -- Don't do anything;
	END IF;

	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	FOR i IN in_remove_sha1s.FIRST .. in_remove_sha1s.LAST
	LOOP
		DELETE FROM qs_submission_file
		 WHERE survey_response_id = v_response_id
		   AND qs_answer_file_id IN (
			SELECT qs_answer_file_id
			  FROM qs_answer_file qaf
			 WHERE qaf.survey_response_id = v_response_id
			   AND qaf.filename = in_remove_filenames(i)
			   AND qaf.mime_type = in_remove_mimetypes(i)
			   AND qaf.sha1 = in_remove_sha1s(i)
		   );

		DELETE FROM qs_answer_file
		 WHERE survey_response_id = v_response_id
		   AND filename = in_remove_filenames(i)
		   AND mime_type = in_remove_mimetypes(i)
		   AND sha1 = in_remove_sha1s(i);

		DELETE FROM qs_response_file
		 WHERE survey_response_id = v_response_id
		   AND filename = in_remove_filenames(i)
		   AND mime_type = in_remove_mimetypes(i)
		   AND sha1 = in_remove_sha1s(i);
	END LOOP;
END;

PROCEDURE SetAnswerFiles(
	in_guid						IN	quick_survey_response.guid%TYPE,
	in_question_id				IN	qs_answer_file.question_id%TYPE,
	in_new_cache_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_new_captions				IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_sha1s			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_filenames		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_mimetypes		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_existing_caption_updates	IN	security.security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_remove_ans_file_ids	security.security_pkg.T_SID_IDS;
	v_existing_answer_files	T_QS_ANSWER_FILES_ARRAY := T_QS_ANSWER_FILES_ARRAY();
	v_existing_file			T_QS_ANSWER_FILES_ROW;
	v_cnt					NUMBER;
	v_data					qs_response_file.data%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid, 1);

	IF NOT (in_existing_sha1s.COUNT = 0 OR (in_existing_sha1s.COUNT = 1 AND in_existing_sha1s(in_existing_sha1s.FIRST) IS NULL)) THEN
		-- hack for ODP.NET which doesn't support empty arrays - just return nothing

		FOR i IN in_existing_sha1s.FIRST .. in_existing_sha1s.LAST
		LOOP
			v_existing_file  := T_QS_ANSWER_FILES_ROW(in_existing_sha1s(i), in_existing_filenames(i), in_existing_mimetypes(i), in_existing_caption_updates(i));

			v_existing_answer_files.extend;
			v_existing_answer_files(v_existing_answer_files.COUNT) := v_existing_file;

				SELECT data
				  INTO v_data
				  FROM qs_response_file
				 WHERE survey_response_id = v_response_id
				   AND sha1 = v_existing_file.sha1
				   AND filename = v_existing_file.filename
				   AND mime_type = v_existing_file.mime_type;

				INTERNAL_AddAnswerFile(
					in_response_id			=> v_response_id,
					in_question_id			=> in_question_id,
					in_filename				=> v_existing_file.filename,
					in_mime_type			=> v_existing_file.mime_type,
					in_data					=> v_data,
					in_caption				=> v_existing_file.caption,
					in_uploaded_dtm			=> NULL
				);
		END LOOP;
	END IF;

	--TODO: why do we update the caption again?
	UPDATE qs_answer_file qaf
	   SET qaf.caption = (
		SELECT eaf.caption
		  FROM TABLE(v_existing_answer_files) eaf
		 WHERE eaf.sha1 = qaf.sha1
		   AND eaf.filename = qaf.filename
		   AND eaf.mime_type = qaf.mime_type
	)
	 WHERE qaf.survey_response_id = v_response_id
	   AND question_id = in_question_id
	   AND EXISTS (
		SELECT 1
		  FROM TABLE(v_existing_answer_files) eaf
		 WHERE eaf.sha1 = qaf.sha1
		   AND eaf.filename = qaf.filename
		   AND eaf.mime_type = qaf.mime_type
	);

	SELECT qs_answer_file_id
	  BULK COLLECT INTO v_remove_ans_file_ids
	  FROM qs_answer_file qaf
	 WHERE survey_response_id = v_response_id
	   AND question_id = in_question_id
	   AND NOT EXISTS (
			SELECT 1
			  FROM TABLE(v_existing_answer_files) eaf
			 WHERE qaf.sha1 = eaf.sha1
			   AND qaf.filename = eaf.filename
			   AND qaf.mime_type = eaf.mime_type
		 );

	IF v_remove_ans_file_ids.COUNT > 0 THEN
		RemoveAnswerFiles(in_guid, in_question_id, v_remove_ans_file_ids);
	END IF;

	IF NOT (in_new_cache_keys.COUNT = 0 OR (in_new_cache_keys.COUNT = 1 AND in_new_cache_keys(in_new_cache_keys.FIRST) IS NULL)) THEN
		AddAnswerFiles(in_guid, in_question_id, in_new_cache_keys, in_new_captions);
	END IF;
END;

PROCEDURE AddAnswerFile(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_file_id				qs_answer_file.qs_answer_file_id%TYPE;
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	INTERNAL_AddAnswerFile(
		in_response_id			=> v_response_id,
		in_question_id			=> in_question_id,
		in_filename				=> in_filename,
		in_mime_type			=> in_mime_type,
		in_data					=> in_data,
		in_caption				=> in_caption,
		in_uploaded_dtm			=> in_uploaded_dtm
	);
END;

PROCEDURE AddAnswerFile(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_filename				IN	qs_answer_file.filename%TYPE,
	in_mime_type			IN	qs_answer_file.mime_type%TYPE,
	in_data					IN	qs_response_file.data%TYPE,
	in_caption				IN	qs_answer_file.caption%TYPE,
	in_uploaded_dtm			IN	qs_response_file.uploaded_dtm%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_file_id				qs_answer_file.qs_answer_file_id%TYPE;
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);


	INTERNAL_AddAnswerFile(
		in_response_id			=> v_response_id,
		in_question_id			=> in_question_id,
		in_filename				=> in_filename,
		in_mime_type			=> in_mime_type,
		in_data					=> in_data,
		in_caption				=> in_caption,
		in_uploaded_dtm			=> in_uploaded_dtm,
		out_cur 				=> out_cur
	);
END;

PROCEDURE AddAnswerFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_captions				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_cache_key_tbl			security.T_VARCHAR2_TABLE := security_pkg.Varchar2ArrayToTable(in_cache_keys);
	v_caption				qs_answer_file.caption%TYPE;
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	FOR r IN (
		SELECT fc.filename, fc.mime_type, fc.object data, ck.pos
		  FROM aspen2.filecache fc
		  JOIN TABLE(v_cache_key_tbl) ck on fc.cache_key = ck.value
	) LOOP
		v_caption := CASE WHEN r.pos <= in_captions.LAST THEN in_captions(r.pos) ELSE NULL END;

		INTERNAL_AddAnswerFile(
			in_response_id			=> v_response_id,
			in_question_id			=> in_question_id,
			in_filename				=> r.filename,
			in_mime_type			=> r.mime_type,
			in_data					=> r.data,
			in_caption				=> v_caption,
			in_uploaded_dtm			=> NULL
		);
	END LOOP;
END;

PROCEDURE RemoveAnswerFiles(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_remove_ids			IN	security_pkg.T_SID_IDS
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_remove_id_tbl			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_remove_ids);
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	DELETE FROM qs_submission_file
	 WHERE survey_response_id = v_response_id
	   AND submission_id = 0
	   AND qs_answer_file_id IN (
		SELECT column_value FROM TABLE(v_remove_id_tbl)
	   );

	-- Delete any files that are no longer referenced by any submission
	DELETE FROM qs_answer_file
	 WHERE survey_response_id = v_response_id
	   AND question_id = in_question_id
	   AND qs_answer_file_id NOT IN (
		SELECT qssf.qs_answer_file_id
		  FROM qs_submission_file qssf
		 WHERE qssf.survey_response_id = v_response_id
	);
END;

PROCEDURE UpdateFileCaptions(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_question_id			IN	qs_answer_file.question_id%TYPE,
	in_file_ids				IN	security_pkg.T_SID_IDS,
	in_captions				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid, 1);

	IF in_file_ids.COUNT = 0 OR (in_file_ids.COUNT = 1 AND in_file_ids(in_file_ids.FIRST) IS NULL) THEN
		-- hack for ODP.NET which doesn't support empty arrays - just return nothing
		RETURN; -- Don't do anything
	END IF;

	FOR i IN in_file_ids.FIRST .. in_file_ids.LAST
	LOOP
		UPDATE qs_answer_file
		   SET caption = in_captions(i)
		 WHERE question_id = in_question_id
		   AND survey_response_id = v_response_id
		   AND qs_answer_file_id = in_file_ids(i);
		IF SQL%ROWCOUNT != 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not update caption on file with ID: '||in_file_ids(i));
		END IF;
	END LOOP;
END;

PROCEDURE GetAnswerFile(
	in_qs_answer_file_id	IN	qs_answer_file.qs_answer_file_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id	qs_answer_file.survey_response_id%TYPE;
BEGIN
	SELECT survey_response_id
	  INTO v_response_id
	  FROM qs_answer_file
	 WHERE qs_answer_file_Id = in_qs_answer_file_id;

	-- There's deliberately no guid equivilent for this. Users must be logged in
	-- and pass security checks to download files
	CheckResponseAccess(v_response_id);

	OPEN out_cur FOR
		SELECT rf.filename, rf.mime_type, rf.data, cast(rf.sha1 as varchar2(40)) sha1,
			   rf.uploaded_dtm, af.caption
		  FROM qs_answer_file af
		  JOIN qs_response_file rf ON af.app_sid = rf.app_sid AND af.survey_response_id = rf.survey_response_id AND af.sha1 = rf.sha1 AND af.filename = rf.filename AND af.mime_type = rf.mime_type
		 WHERE af.qs_answer_file_id = in_qs_answer_file_id;
END;

PROCEDURE GetStopQuestionIds(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_submission_id			quick_survey_submission.submission_id%TYPE;
	v_survey_version		quick_survey_version.survey_version%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);
	v_submission_id := INTERNAL_GetSubmissionId(v_response_id, in_submission_id);
	v_survey_version := INTERNAL_GetSubmSurveyVersion(v_response_id, v_submission_id);

	OPEN out_cur FOR
		SELECT qsa.question_id
		  FROM quick_survey_answer qsa
		  JOIN qs_question_option qo ON qsa.question_option_id = qo.question_option_id AND qsa.question_id = qo.question_id
		 WHERE qsa.survey_response_id = v_response_id
		   AND qsa.submission_id = v_submission_id
		   AND qo.option_action = 'end'
		   AND qo.survey_version = v_survey_version;
END;

PROCEDURE INTERNAL_GetResponse(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_response_cur FOR
		SELECT qsr.survey_sid, qsr.survey_version,
			   qsr.created_dtm, qsr.guid, qsr.survey_response_id response_id,
			   qsr.user_sid, cu.full_name user_full_name,
			   r.region_sid, r.description region_description,
			   qss.overall_score, qss.overall_max_score, st.score_threshold_id, st.description score_threshold_description,
			   qss.submitted_dtm, qss.submission_id, ia.internal_audit_sid,
			   qss.geo_latitude, qss.geo_longitude, qss.geo_altitude, qss.geo_h_accuracy, qss.geo_v_accuracy,
			   fi.flow_item_id, fi.flow_sid,
			   fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key
		  FROM quick_survey_response qsr
		  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id AND qss.submission_id = NVL(in_submission_id, NVL(qsr.last_submission_id, 0))
		  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier s ON ssr.supplier_sid = s.company_sid
		  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
		  LEFT JOIN v$region r on NVL(rsr.region_sid, NVL(ia.region_sid, s.region_sid)) = r.region_sid
		  LEFT JOIN csr_user cu ON qsr.user_sid = cu.csr_user_sid
		  LEFT JOIN score_threshold st ON qss.score_threshold_id = st.score_threshold_id
		  LEFT JOIN csr.flow_item fi ON fi.flow_item_id = ia.flow_item_id OR fi.survey_response_id = qsr.survey_response_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE qsr.survey_response_id = in_response_id
		   AND qsr.hidden = 0;
END;

PROCEDURE INTERNAL_GetResponse(
	in_response_id	    	IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	INTERNAL_GetResponse(in_response_id, in_submission_id, out_response_cur);

    OPEN out_postits_cur FOR
		SELECT qsrp.survey_response_id, p.postit_id, p.message, p.label, p.created_dtm, p.created_by_sid,
			p.created_by_user_name, p.created_by_full_name, p.created_by_email, p.can_edit
		  FROM qs_response_postit qsrp
			JOIN v$postit p ON qsrp.postit_id = p.postit_id AND qsrp.app_sid = p.app_sid
		 WHERE survey_response_id = in_response_id
		 ORDER BY created_dtm;

	OPEN out_postit_files_cur FOR
		SELECT pf.postit_file_Id, pf.postit_id, pf.filename, pf.mime_type, cast(pf.sha1 as varchar2(40)) sha1, pf.uploaded_dtm
		  FROM qs_response_postit qsrp
			JOIN postit p ON qsrp.postit_id = p.postit_id AND qsrp.app_sid = p.app_sid
			JOIN postit_file pf ON p.postit_id = pf.postit_id AND p.app_sid = pf.app_sid
		 WHERE survey_response_id = in_response_id;
END;

PROCEDURE INTERNAL_GetResponseAnswers(
	in_response_id	    	IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
BEGIN
	INTERNAL_GetResponse(in_response_id, in_submission_id, out_response_cur, out_postits_cur, out_postit_files_cur);

	OPEN out_answers_cur FOR
		SELECT a.question_id, a.answer, a.note, a.val_number, a.question_option_id,
			   a.measure_conversion_id, a.region_sid, a.version_stamp,
			   a.score, a.max_score,
			   l.set_dtm, u.full_name user_name, u.email user_email,
			   r.description region_description, a.log_item
		  FROM quick_survey_answer a
		  LEFT JOIN v$region r ON a.region_sid = r.region_sid
		  LEFT JOIN (
			SELECT app_sid, survey_response_id, question_id, set_by_user_sid, set_dtm, version_stamp, ROW_NUMBER() OVER(PARTITION BY app_sid, survey_response_id, question_id, version_stamp ORDER BY set_dtm DESC) rn
			  FROM qs_answer_log
		  ) l ON a.app_sid = l.app_sid AND a.survey_response_id = l.survey_response_id AND a.question_id = l.question_id AND a.version_stamp = l.version_stamp AND l.rn = 1
		  LEFT JOIN csr_user u ON u.csr_user_sid = l.set_by_user_sid
		 WHERE a.survey_response_id = in_response_id
		   AND a.submission_id = v_submission_id;

	OPEN out_answer_files_cur FOR
		SELECT af.qs_answer_file_id, af.question_id, af.filename, af.mime_type, cast(af.sha1 as varchar2(40)) sha1,
			   af.uploaded_dtm, af.caption, af.data
		  FROM v$qs_answer_file af
		 WHERE af.survey_response_id = in_response_id
		   AND af.submission_id = v_submission_id;

	OPEN out_answer_issues_cur FOR
		SELECT isa.question_id, i.label, i.issue_id,
			CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
			CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue_survey_answer isa
		  JOIN issue i ON isa.issue_survey_answer_id = i.issue_survey_answer_id AND isa.app_sid = i.app_sid AND i.is_visible = 1
		 WHERE isa.survey_response_id = in_response_id
		   AND i.deleted = 0;
END;

PROCEDURE INTERNAL_GetResponseAnswers(
	in_response_id	    	IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids			IN	security_pkg.T_SID_IDS,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	v_user_sid				security_pkg.T_SID_ID;
	t_question_ids			security.T_SID_TABLE;
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
BEGIN
	INTERNAL_GetResponse(in_response_id, in_submission_id, out_response_cur, out_postits_cur, out_postit_files_cur);

	t_question_ids := security_pkg.SidArrayToTable(in_question_ids);

	OPEN out_answers_cur FOR
		SELECT a.question_id, a.answer, a.note, a.val_number, a.question_option_id,
			   a.measure_conversion_id, a.region_sid, a.version_stamp,
			   a.score, a.max_score,
			   l.set_dtm, u.full_name user_name, u.email user_email,
			   r.description region_description
		  FROM quick_survey_answer a
		  LEFT JOIN v$region r ON a.region_sid = r.region_sid
		  LEFT JOIN (
			SELECT app_sid, survey_response_id, question_id, set_by_user_sid, set_dtm, version_stamp, ROW_NUMBER() OVER(PARTITION BY app_sid, survey_response_id, question_id, version_stamp ORDER BY set_dtm DESC) rn
			  FROM qs_answer_log
		  ) l ON a.app_sid = l.app_sid AND a.survey_response_id = l.survey_response_id AND a.question_id = l.question_id AND a.version_stamp = l.version_stamp AND l.rn = 1
		  LEFT JOIN csr_user u ON u.csr_user_sid = l.set_by_user_sid
		 WHERE a.survey_response_id = in_response_id
		   AND a.submission_id = v_submission_id
		   AND a.question_id IN (
				SELECT t.column_value FROM TABLE(t_question_ids) t
		   );

	OPEN out_answer_files_cur FOR
		SELECT af.qs_answer_file_id, af.question_id, af.filename, af.mime_type, cast(af.sha1 as varchar2(40)) sha1,
			   af.uploaded_dtm, af.caption
		  FROM v$qs_answer_file af
		 WHERE af.survey_response_id = in_response_id
		   AND af.submission_id = v_submission_id
		   AND af.question_id IN (
				SELECT column_value FROM TABLE(t_question_ids)
		   );

	OPEN out_answer_issues_cur FOR
		SELECT isa.question_id, i.label, i.issue_id,
			CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
			CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
			CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected
		  FROM issue_survey_answer isa
		  JOIN issue i ON isa.issue_survey_answer_id = i.issue_survey_answer_id AND isa.app_sid = i.app_sid AND i.is_visible = 1
		 WHERE isa.survey_response_id = in_response_id
		   AND i.deleted = 0
		   AND isa.question_id IN (
				SELECT t.column_value FROM TABLE(t_question_ids) t
		   );
END;

PROCEDURE GetResponse(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckResponseAccess(in_response_id);

	INTERNAL_GetResponse(in_response_id, in_submission_id, out_response_cur);
END;

PROCEDURE GetResponseByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	INTERNAL_GetResponse(v_response_id, in_submission_id, out_response_cur);
END;

PROCEDURE GetResponseAnswers(
	in_response_id	    	IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid	security_pkg.T_SID_ID;
	v_user_sid		security_pkg.T_SID_ID;
BEGIN
	CheckResponseAccess(in_response_id);

	INTERNAL_GetResponseAnswers(in_response_id, in_submission_id, out_response_cur, out_postits_cur, out_postit_files_cur,
		out_answers_cur, out_answer_files_cur, out_answer_issues_cur);
END;

PROCEDURE GetResponseAnswersByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids			IN	security_pkg.T_SID_IDS,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	INTERNAL_GetResponseAnswers(v_response_id, in_submission_id, in_question_ids, out_response_cur, out_postits_cur,
		out_postit_files_cur, out_answers_cur, out_answer_files_cur, out_answer_issues_cur);
END;

-- get response answers for specific question ids
PROCEDURE GetResponseAnswers(
	in_response_id	    	IN	QUICK_SURVEY_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_question_ids			IN	security_pkg.T_SID_IDS,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_postits_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_postit_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answers_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_files_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_answer_issues_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckResponseAccess(in_response_id);

	INTERNAL_GetResponseAnswers(in_response_id, in_submission_id, in_question_ids, out_response_cur, out_postits_cur,
		out_postit_files_cur, out_answers_cur, out_answer_files_cur, out_answer_issues_cur);
END;

PROCEDURE INTERNAL_GetResponseValues(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_answers			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_conversion_dtm		DATE;
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
	v_survey_version		quick_survey_version.survey_version%TYPE := INTERNAL_GetSubmSurveyVersion(in_response_id, v_submission_id);
BEGIN
	INTERNAL_GetResponse(in_response_id, in_submission_id, out_response_cur);

	SELECT NVL(qss.submitted_dtm, qsr.created_dtm)
	  INTO v_conversion_dtm
	  FROM quick_survey_response qsr
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	 WHERE qsr.survey_response_id = in_response_id
	   AND qss.submission_id = v_submission_id;

	OPEN out_cur_answers FOR
		-- points can be scored for radio buttons and checkboxes
		-- (also maybe other expressions? enhanced functionality)
		SELECT qsa.question_id, qs.label, qs.lookup_key, qsa.score, qsa.max_score,
			   qso.question_option_id, qsa.note comments, files.filenames,
			   CASE WHEN qsa.measure_conversion_id IS NOT NULL AND val_number IS NOT NULL THEN
					-- take conversion factors into account
					measure_pkg.UNSEC_GetBaseValue(val_number, measure_conversion_id, v_conversion_dtm)
				ELSE
					val_number
			   END val_number, qso.lookup_key selected_lookup_key, qso.option_action,
			   NVL(TO_CLOB(qso.lookup_key), answer) text, html_display, r.region_sid,
			   r.description region_description,
			   CASE
				WHEN qsa.question_option_id IS NOT NULL OR (qs.question_type = 'checkbox' AND qsa.val_number = 1) THEN qsa.answer
				ELSE NULL
			   END other_value
		  FROM quick_survey_answer qsa
		  JOIN quick_survey_question qs ON qsa.question_id = qs.question_id
		  JOIN question_type qt ON qs.question_type = qt.question_type
		  LEFT JOIN qs_question_option qso
			ON qsa.question_option_id = qso.question_option_id
		   AND qsa.question_id = qso.question_id
		   AND qs.survey_version = qso.survey_version
		  LEFT JOIN (
				SELECT af.question_id, stragg(af.filename||NVL2(af.caption, ' - '||af.caption, '')) filenames
				  FROM v$qs_answer_file af
				 WHERE af.survey_response_id = in_response_Id
				   AND af.submission_id = v_submission_id
				 GROUP BY af.question_id
			) files ON qs.question_id = files.question_id
		  LEFT JOIN v$region r ON qsa.region_sid = r.region_sid
		 WHERE qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = v_submission_id
		   AND qs.survey_version = v_survey_version;

	-- Get files.
	OPEN out_cur_files FOR
		SELECT af.question_id, af.qs_answer_file_id file_id, af.mime_type, af.uploaded_dtm, af.filename, af.caption
		  FROM quick_survey_answer qsa
		  JOIN quick_survey_question qs ON qsa.question_id = qs.question_id
		  JOIN v$qs_answer_file af ON qs.question_id = af.question_id
		 WHERE qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = v_submission_id
		   AND af.survey_response_id = in_response_Id
		   AND af.submission_id = v_submission_id
		   AND qs.survey_version = v_survey_version;
END;

PROCEDURE GetResponseValues(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_answers			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_start_dtm	 DATE;
BEGIN
	CheckResponseAccess(in_response_id);

	INTERNAL_GetResponseValues(in_response_id, in_submission_id, out_response_cur, out_cur_answers, out_cur_files);
END;

PROCEDURE GetResponseValuesByGuid(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	out_response_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_answers			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	INTERNAL_GetResponseValues(v_response_id, in_submission_id, out_response_cur, out_cur_answers, out_cur_files);
END;


PROCEDURE UNSEC_PublishRegionScore(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	quick_survey_submission.overall_score%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE,
	in_comment_text				IN	region_score_log.comment_text%TYPE DEFAULT NULL
)
AS
	v_region_score_log_id		region_score_log.region_score_log_id%TYPE;
BEGIN
	INSERT INTO region_score_log (region_score_log_id, region_sid, score_type_id, score_threshold_id, score, comment_text)
		 VALUES (region_score_log_id_seq.NEXTVAL, in_region_sid, in_score_type_id, in_threshold_id, in_score, in_comment_text)
	  RETURNING region_score_log_id INTO v_region_score_log_id;

	BEGIN
		INSERT INTO region_score (score_type_id, region_sid, last_region_score_log_id)
			 VALUES (in_score_type_id, in_region_sid, v_region_score_log_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE region_score
			   SET last_region_score_log_id = v_region_score_log_id
			 WHERE score_type_id = in_score_type_id
			   AND region_sid = in_region_sid;
	END;
END;

PROCEDURE INTERNAL_TriggerAggregateJob (
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	out_audit_sid					OUT  security_pkg.T_SID_ID,
	out_region_sid					OUT  security_pkg.T_SID_ID
)
AS
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_agg_ind_id			aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_audience				quick_survey.audience%TYPE;
	v_survey_sid			security_pkg.T_SID_ID;
BEGIN

	SELECT qs.survey_sid, qs.audience
	  INTO v_survey_sid, v_audience
	  FROM quick_survey_response qsr
	  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
	 WHERE qsr.survey_response_id = in_response_id;

	BEGIN
		IF v_audience = 'audit' THEN
			-- TODO: This should extend the period from this audit dtm - for an audit validity period or until
			-- the next audit of the same type for that region
			SELECT qs.aggregate_ind_group_id, qsr.audit_month,
				   LEAD(qsr.audit_month, 1, ADD_MONTHS(qsr.audit_month, NVL(ac.reportable_for_months, NVL(qsr.validity_months, 12))))
				   OVER(PARTITION BY qsr.survey_sid, qsr.region_sid ORDER BY qsr.audit_month ASC),
				   qsr.internal_audit_sid, qsr.region_sid
			  INTO v_agg_ind_id, v_start_dtm, v_end_dtm, out_audit_sid, out_region_sid
			  FROM ( --the latest submission for the most recent audit in this month for this region and for this survey_sid
				SELECT qsr.survey_response_id, qsr.last_submission_id submission_id, TRUNC(ia.audit_dtm, 'MONTH') audit_month,
					   ROW_NUMBER() OVER (PARTITION BY qsr.survey_sid, ia.region_sid, TRUNC(audit_dtm, 'MONTH') ORDER BY audit_dtm DESC) rn,
					   ia.region_sid, ia.internal_audit_type_id, ia.audit_closure_type_id, iat.validity_months, ia.survey_sid, qsr.app_sid, ia.internal_audit_sid
				  FROM quick_survey_response qsr
				  JOIN (
					SELECT internal_audit_sid, survey_response_id
					  FROM internal_audit
					 WHERE survey_response_id = in_response_id
					 UNION
					SELECT internal_audit_sid, survey_response_id
					  FROM internal_audit_survey
					 WHERE survey_response_id = in_response_id
					) ias ON qsr.survey_response_id = ias.survey_response_id
				  JOIN internal_audit ia ON ias.internal_audit_sid = ia.internal_audit_sid
				  JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
				 WHERE qsr.last_submission_id IS NOT NULL
				) qsr
			  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid AND qsr.app_sid = qs.app_sid
			  LEFT JOIN audit_type_closure_type ac ON qsr.audit_closure_type_id = ac.audit_closure_type_id AND qsr.internal_audit_type_id = ac.internal_audit_type_id AND qsr.app_sid = ac.app_sid
			 WHERE qsr.survey_response_id = in_response_id;
		ELSIF v_audience = 'chain' THEN
			SELECT qs.aggregate_ind_group_id,
				   TRUNC(SYSDATE, 'MONTH'),
				   TRUNC(ADD_MONTHS(SYSDATE, qs.submission_validity_months), 'MONTH')
			  INTO v_agg_ind_id, v_start_dtm, v_end_dtm
			  FROM v$quick_survey_response qsr
			  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid AND qsr.app_sid = qs.app_sid
			 WHERE qsr.survey_response_id = in_response_id
			   AND qsr.submission_id > 0
			   AND qs.aggregate_ind_group_id IS NOT NULL;
		ELSE

			SELECT qs.aggregate_ind_group_id, rsr.period_start_dtm, rsr.period_end_dtm
			  INTO v_agg_ind_id, v_start_dtm, v_end_dtm
			  FROM v$quick_survey_response qsr
			  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid AND qsr.app_sid = qs.app_sid
			  LEFT JOIN region_survey_response rsr ON qsr.survey_response_id = rsr.survey_response_id
			 WHERE qsr.survey_response_id = in_response_id
			   AND qsr.submission_id > 0
			   AND qs.aggregate_ind_group_id IS NOT NULL;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- it's ok not to have an aggregate group
	END;

	IF v_agg_ind_id IS NOT NULL AND v_start_dtm IS NOT NULL AND v_end_dtm IS NOT NULL THEN
		-- trigger aggregate job
		calc_pkg.AddJobsForAggregateIndGroup(v_agg_ind_id, TRUNC(v_start_dtm, 'MONTH'), TRUNC(v_end_dtm, 'MONTH'));
	END IF;

END;

PROCEDURE INTERNAL_UpdateNonCompliances (
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN  quick_survey_submission.submission_id%TYPE,
	in_audit_sid					IN  security_pkg.T_SID_ID,
	in_region_sid					IN  security_pkg.T_SID_ID
)
AS
	v_tag_ids				security_pkg.T_SID_IDS;
	v_ia_type_survey_id		audit_non_compliance.internal_audit_type_survey_id%TYPE;
	v_dummy					security_pkg.T_OUTPUT_CUR;
	v_dummy_ids				security_pkg.T_SID_IDS;
	v_dummy_keys			audit_pkg.T_CACHE_KEYS;
BEGIN
	IF in_audit_sid IS NOT NULL THEN
		FOR r IN (
			SELECT qso.question_id, qso.question_option_id, qso.non_comp_default_id,
				   NVL(dnc.non_compliance_type_id, qso.non_compliance_type_id) non_compliance_type_id,
				   NVL(dnc.label, qso.non_compliance_label) non_compliance_label,
				   NVL(dnc.detail, qso.non_compliance_detail) non_compliance_detail,
				   NVL(dnc.root_cause, qso.non_comp_root_cause) non_comp_root_cause,
				   NVL(dnc.suggested_action, qso.non_comp_suggested_action) non_comp_suggested_action,
				   qso.label option_label, qsq.label question_label, qso.survey_version
			  FROM quick_survey_answer qsa
			  JOIN qs_question_option qso
				ON qsa.question_id = qso.question_id
			   AND qsa.question_option_id = qso.question_option_id
			   AND qsa.survey_version = qso.survey_version
			  JOIN quick_survey_question qsq
			    ON qso.question_id = qsq.question_id
			   AND qso.survey_version = qsq.survey_version
			  LEFT JOIN non_comp_default dnc
			    ON qso.non_comp_default_id = dnc.non_comp_default_id
			 WHERE qsa.survey_response_id = in_response_id
			   AND qsa.submission_id = in_submission_id
			   AND (qso.non_comp_default_id IS NOT NULL OR qso.non_compliance_label IS NOT NULL) -- that has a nc definition
			   AND (qso.question_id, qso.question_option_id) NOT IN (
				-- exclude already generated against this option
				SELECT xnc.question_id, xnc.question_option_id
				  FROM non_compliance xnc
				  JOIN audit_non_compliance anc ON xnc.non_compliance_id = anc.non_compliance_id
				 WHERE anc.internal_audit_sid = in_audit_sid
				   AND xnc.question_option_id IS NOT NULL
			)
		) LOOP
			SELECT tag_id
			  BULK COLLECT INTO v_tag_ids
			  FROM qs_question_option_nc_tag
			 WHERE question_id = r.question_id
			   AND question_option_id = r.question_option_id
			   AND survey_version = r.survey_version;

			BEGIN
				SELECT audit_pkg.PRIMARY_AUDIT_TYPE_SURVEY_ID
				  INTO v_ia_type_survey_id
				  FROM internal_audit
				 WHERE survey_response_id = in_response_id;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				-- Try to raise against an audit's secondary survey
					BEGIN
						SELECT internal_audit_type_survey_id
						  INTO v_ia_type_survey_id
						  FROM internal_audit_survey
						 WHERE survey_response_id = in_response_id;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							NULL;
					END;
			END;

			audit_pkg.SaveNonCompliance(
				in_non_compliance_id		=> NULL,
				in_region_sid				=> in_region_sid,
				in_internal_audit_sid		=> in_audit_sid,
				in_from_non_comp_default_id	=> r.non_comp_default_id,
				in_label					=> SUBSTR(REPLACE(REPLACE(r.non_compliance_label, '{Q}', r.question_label), '{A}', r.option_label),1,LEAST(255,LENGTH(REPLACE(REPLACE(r.non_compliance_label, '{Q}', r.question_label), '{A}', r.option_label)))),
				in_detail					=> REPLACE(REPLACE(r.non_compliance_detail, '{Q}', r.question_label), '{A}', r.option_label),
				in_root_cause				=> REPLACE(REPLACE(r.non_comp_root_cause, '{Q}', r.question_label), '{A}', r.option_label),
				in_suggested_action			=> REPLACE(REPLACE(r.non_comp_suggested_action, '{Q}', r.question_label), '{A}', r.option_label),
				in_non_compliance_type_id	=> r.non_compliance_type_id,
				in_is_closed				=> 0,
				in_current_file_uploads		=> v_dummy_ids,
				in_new_file_uploads			=> v_dummy_keys,
				in_tag_ids					=> v_tag_ids,
				in_question_id				=> r.question_id,
				in_question_option_id		=> r.question_option_id,
				in_ia_type_survey_id		=> v_ia_type_survey_id,
				out_nc_cur					=> v_dummy,
				out_nc_upload_cur			=> v_dummy,
				out_nc_tag_cur				=> v_dummy
			);
		END LOOP;
	END IF;


END;


PROCEDURE INTERNAL_CreateNewSubmission (
	in_response_id					IN  quick_survey_response.survey_response_id%TYPE,
	in_geo_latitude					IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude				IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 				IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy				IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy				IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id				OUT  quick_survey_submission.submission_id%TYPE
)
AS
	v_survey_version		quick_survey_version.survey_version%TYPE := INTERNAL_GetSubmSurveyVersion(in_response_id, 0);
BEGIN
	-- create a new submission so we can track multiple submissions
	INSERT INTO quick_survey_submission (
		survey_response_id, submission_id, submitted_dtm, submitted_by_user_sid, survey_version,
		geo_latitude, geo_longitude, geo_altitude, geo_h_accuracy, geo_v_accuracy
	) VALUES (
		in_response_id, qs_submission_id_seq.NEXTVAL, SYSDATE, SYS_CONTEXT('SECURITY','SID'), v_survey_version,
		in_geo_latitude, in_geo_longitude, in_geo_altitude, in_geo_h_accuracy, in_geo_v_accuracy
	) RETURNING submission_id INTO out_submission_id;

	UPDATE quick_survey_response
	   SET last_submission_id = out_submission_id
	 WHERE survey_response_id = in_response_id;

	-- Copy all answers into new submission
	-- Note: if these two INSERTs are updated, the ones at line ~2087 in proc: NewCampaignResponse
	-- should be updated too.
	INSERT INTO quick_survey_answer (survey_response_id, question_id, note, score, question_option_id,
		   val_number, measure_conversion_id, measure_sid, region_sid, answer, html_display, max_score,
		   version_stamp, submission_id, weight_override, survey_version, log_item, survey_sid, question_version)
	SELECT survey_response_id, question_id, note, score, question_option_id, val_number, measure_conversion_id,
		   measure_sid, region_sid, answer, html_display, max_score, version_stamp, out_submission_id,
		   weight_override, survey_version, log_item, survey_sid, question_version
	  FROM quick_survey_answer
	 WHERE survey_response_id = in_response_id
	   AND submission_id = 0;

	-- Copy references to all files into new submission
	INSERT INTO qs_submission_file (qs_answer_file_id, survey_response_id, submission_id, survey_version)
	SELECT qs_answer_file_id, survey_response_id, out_submission_id, survey_version
	  FROM qs_submission_file
	 WHERE survey_response_id = in_response_id
	   AND submission_id = 0;
END;

PROCEDURE INTERNAL_ProgressWorkflow(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_lookup_key			IN	VARCHAR2
)
AS
BEGIN
	FOR r IN (
		SELECT fi.flow_item_id, fi.current_state_id, MIN(fst.to_state_id) submit_to_state_id
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fi.current_state_id = fst.from_state_id
		 WHERE fi.survey_response_id = in_response_id
		   AND fst.lookup_key = in_lookup_key
		 GROUP BY fi.flow_item_id, fi.current_state_id
	) LOOP
		flow_pkg.SetItemState(r.flow_item_id, r.submit_to_state_id, '', SYS_CONTEXT('SECURITY','SID'));
	END LOOP;
END;

PROCEDURE INTERNAL_Submit(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_geo_latitude				IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude			IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 			IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy			IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy			IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id		OUT quick_survey_submission.submission_id%TYPE
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	v_audit_sid				security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
BEGIN
	-- any other permissions?

	INTERNAL_CreateNewSubmission(
		in_response_id		=>	in_response_id,
		in_geo_latitude		=>	in_geo_latitude,
		in_geo_longitude	=>	in_geo_longitude,
		in_geo_altitude 	=>	in_geo_altitude,
		in_geo_h_accuracy	=>	in_geo_h_accuracy,
		in_geo_v_accuracy	=>	in_geo_v_accuracy,
		out_submission_id	=>	out_submission_id
	);

	CalculateResponseScore(in_response_id, out_submission_id);

	SELECT qs.survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response qsr
	  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
	 WHERE qsr.survey_response_id = in_response_id;

	OnSurveySubmitted(v_survey_sid, in_response_id, out_submission_id);

	INTERNAL_TriggerAggregateJob(in_response_id, v_audit_sid, v_region_sid);

	INTERNAL_UpdateNonCompliances(in_response_id,out_submission_id, v_audit_sid, v_region_sid);

	INTERNAL_ProgressWorkflow(in_response_id, 'SUBMIT');
END;


PROCEDURE Submit(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_geo_latitude				IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude			IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 			IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy			IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy			IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id		OUT quick_survey_submission.submission_id%TYPE
)
AS
	v_audience		quick_survey.audience%TYPE;
BEGIN
	-- Check write permissions
	CheckResponseAccess(in_response_id, 1);

	INTERNAL_Submit(
		in_response_id		=>	in_response_id,
		in_geo_latitude		=>	in_geo_latitude,
		in_geo_longitude	=>	in_geo_longitude,
		in_geo_altitude 	=>	in_geo_altitude,
		in_geo_h_accuracy	=>	in_geo_h_accuracy,
		in_geo_v_accuracy	=>	in_geo_v_accuracy,
		out_submission_id	=>	out_submission_id
	);
END;

PROCEDURE Submit(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_geo_latitude				IN	quick_survey_submission.geo_latitude%TYPE DEFAULT NULL,
	in_geo_longitude			IN	quick_survey_submission.geo_longitude%TYPE DEFAULT NULL,
	in_geo_altitude 			IN	quick_survey_submission.geo_altitude%TYPE DEFAULT NULL,
	in_geo_h_accuracy			IN	quick_survey_submission.geo_h_accuracy%TYPE DEFAULT NULL,
	in_geo_v_accuracy			IN	quick_survey_submission.geo_v_accuracy%TYPE DEFAULT NULL,
	out_submission_id		OUT quick_survey_submission.submission_id%TYPE
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
BEGIN
	-- Check write permissions
	v_response_id := CheckGuidAccess(in_guid, 1);

	INTERNAL_Submit(
		in_response_id		=>	v_response_id,
		in_geo_latitude		=>	in_geo_latitude,
		in_geo_longitude	=>	in_geo_longitude,
		in_geo_altitude 	=>	in_geo_altitude,
		in_geo_h_accuracy	=>	in_geo_h_accuracy,
		in_geo_v_accuracy	=>	in_geo_v_accuracy,
		out_submission_id	=>	out_submission_id
	);
END;

PROCEDURE GetQuestionTree(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- you need read permission
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||in_survey_sid);
	END IF;

	OPEN out_questions_cur FOR
		SELECT question_id, label, question_type, score, lookup_key, maps_to_ind_sid, measure_sid, parent_id,
			   action, question_version
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = in_survey_version
		 ORDER BY pos;

	OPEN out_question_options_cur FOR
        SELECT q.question_id, qo.question_option_id, qo.label, qo.score, qo.color, qo.lookup_key, qo.pos,
			   qo.option_action, qo.non_compliance_popup, qo.non_comp_default_id, qo.non_compliance_type_id,
			   qo.non_compliance_label, qo.non_compliance_detail/*, qo.non_comp_root_cause, qo.non_comp_suggested_action*/, q.question_version
          FROM quick_survey_question q
          JOIN qs_question_option qo ON q.question_id = qo.question_id AND q.survey_version = qo.survey_version
         WHERE q.is_visible = 1
           AND qo.is_visible = 1
           AND q.survey_sid = in_survey_sid
           AND q.survey_version = in_survey_version
         ORDER BY q.pos, qo.pos;
END;

-- we also need standard filters (e.g. submitted between date x/y, was submitted, status)
-- Passing an empty array means "do all questions"
PROCEDURE INTERNAL_GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_response_id_table		IN	security.T_SID_TABLE,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_question_ids				security.T_SID_TABLE;
	v_submission_id_table		security.T_SID_TABLE;
BEGIN
    -- you need write permission to get the results
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||in_survey_sid);
	END IF;

	t_question_ids := security_pkg.SidArrayToTable(in_question_ids);
	
	SELECT last_submission_id
	  BULK COLLECT INTO v_submission_id_table
	  FROM quick_survey_response
	 WHERE survey_response_id IN (
		SELECT DISTINCT column_value FROM TABLE(in_response_id_table)
	 );

	IF in_question_ids.COUNT = 0 OR (in_question_ids.COUNT = 1 AND in_question_ids(in_question_ids.FIRST) IS NULL) THEN
		SELECT question_id
		  BULK COLLECT INTO t_question_ids
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND survey_version = in_survey_version
		   AND is_visible = 1;
	END IF;

	-- TODO: filter this using in_questiOn_ids
	OPEN out_questions_cur FOR
		SELECT question_id, label, question_type, score, lookup_key, maps_to_ind_sid, measure_sid, parent_id, question_version, parent_version
		  FROM quick_survey_question
		 WHERE is_visible = 1
		   AND survey_sid = in_survey_sid
		   AND survey_version = in_survey_version
		 ORDER BY pos;

	-- TODO: filter this using in_questiOn_ids
	OPEN out_question_options_cur FOR
        SELECT q.question_id, qo.question_option_id, qo.label, qo.score, qo.color, qo.lookup_key, qo.pos, q.question_version, q.parent_version
          FROM quick_survey_question q
          JOIN qs_question_option qo ON q.question_id = qo.question_id AND q.survey_version = qo.survey_version
         WHERE q.is_visible = 1
           AND qo.is_visible = 1
           AND q.survey_sid = in_survey_sid
           AND q.survey_version = in_survey_version
         ORDER BY q.pos, qo.pos;

	-- answers for radio buttons
	OPEN out_option_answers_cur FOR
		SELECT qo.question_id, qo.question_option_id, SUM(qo.score) score_sum, COUNT(qo.question_option_id) score_count
		  FROM (SELECT DISTINCT column_value question_id FROM TABLE(t_question_ids)) q
		  JOIN qs_question_option qo
			ON q.question_id = qo.question_id
		   AND qo.survey_version = in_survey_version
		  JOIN quick_survey_answer qa
		    ON qa.question_id = qo.question_id
		   AND qa.question_option_id = qo.question_option_id
		 WHERE qo.is_visible = 1
		   AND qa.submission_id IN (
				SELECT DISTINCT column_value FROM TABLE(v_submission_id_table)
		   )
         GROUP BY qo.question_id, qo.question_option_id;

	-- answers for checkboxes
	OPEN out_checkbox_cur FOR
		SELECT qa.question_id, SUM(qa.val_number) checked_count, COUNT(q.question_id) response_count
		  FROM (SELECT DISTINCT column_value question_id FROM TABLE(t_question_ids)) qp
		  JOIN quick_survey_question q ON qp.question_id = q.question_id
		  JOIN quick_survey_answer qa ON qa.question_id = q.question_id
		 WHERE q.is_visible = 1
		   AND q.survey_sid = in_survey_sid
		   AND q.question_type = 'checkbox'
		   AND q.survey_version = in_survey_version
		   AND qa.submission_id IN (
				SELECT DISTINCT column_value FROM TABLE(v_submission_id_table)
		   )
         GROUP BY qa.question_id;
END;

PROCEDURE GetResultsForResponseGuid(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_guid						IN	quick_survey_response.guid%TYPE,
	out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id				quick_survey_response.survey_response_id%TYPE;
	v_audience					quick_survey.audience%TYPE;
	v_survey_version			quick_survey_version.survey_version%TYPE;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);
	v_survey_version := INTERNAL_GetSubmSurveyVersion(v_response_id, NULL);

	OPEN out_questions_cur FOR
		SELECT question_id, label, question_type, score, lookup_key, maps_to_ind_sid, measure_sid, parent_id
		  FROM quick_survey_question
		 WHERE is_visible = 1
		   AND survey_sid = in_survey_sid
		   AND survey_version = v_survey_version
		 ORDER BY pos;

	OPEN out_question_options_cur FOR
		SELECT q.question_id, qo.question_option_id, qo.label, qo.score, qo.color, qo.lookup_key, qo.pos
		  FROM quick_survey_question q
		  JOIN qs_question_option qo ON q.question_id = qo.question_id AND q.survey_version = qo.survey_version
		 WHERE q.is_visible = 1
		   AND qo.is_visible = 1
		   AND q.survey_sid = in_survey_sid
		   AND q.survey_version = v_survey_version
		 ORDER BY q.pos, qo.pos;

	-- answers for radio buttons
	OPEN out_option_answers_cur FOR
		SELECT qa.question_id, qa.question_option_id, SUM(qo.score) score_sum, COUNT(qo.question_option_id) score_count
		  FROM v$quick_survey_answer qa
		  JOIN quick_survey_question q ON qa.question_id = q.question_id
		  JOIN qs_question_option qo
			ON qa.question_option_id = qo.question_option_id
		   AND qa.question_id = qo.question_id
		   AND q.survey_version = qo.survey_version
		 WHERE q.is_visible = 1
		   AND qo.is_visible = 1
		   AND q.survey_sid = in_survey_sid
		   AND q.survey_version = v_survey_version
		   AND qa.survey_response_id = v_response_id
         GROUP BY qa.question_id, qa.question_option_id;

	-- answers for checkboxes
	OPEN out_checkbox_cur FOR
		SELECT qa.question_id, SUM(val_number) checked_count, COUNT(q.question_id) response_count
		  FROM v$quick_survey_answer qa
		  JOIN quick_survey_question q ON qa.question_id = q.question_id
		 WHERE q.is_visible = 1
		   AND q.survey_sid = in_survey_sid
		   AND q.survey_version = v_survey_version
		   AND q.question_type = 'checkbox'
		   AND qa.survey_response_id = v_response_id
		 GROUP BY qa.question_id;
END;

-- without a compound filter_id
PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetResults(in_survey_sid, in_survey_version, in_question_ids, null, out_questions_cur, out_question_options_cur, out_option_answers_cur, out_checkbox_cur);
END;

-- Pass in a compound filter_id
-- we also need standard filters (e.g. submitted between date x/y, was submitted, status)
-- Passing an empty array means "do all questions"
PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids		security.T_SID_TABLE;
BEGIN
	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, NULL, t_response_ids);
	INTERNAL_GetResults(
		in_survey_sid,
		in_survey_version,
		in_question_ids,
		t_response_ids,
		out_questions_cur,
		out_question_options_cur,
		out_option_answers_cur,
		out_checkbox_cur
	);
END;

-- Pass in a compound filter_id and a campaign Sid
-- we also need standard filters (e.g. submitted between date x/y, was submitted, status)
-- Passing an empty array means "do all questions"
PROCEDURE GetResults(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids		security.T_SID_TABLE;
BEGIN
	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, in_campaign_sid, t_response_ids);
	INTERNAL_GetResults(
		in_survey_sid,
		in_survey_version,
		in_question_ids,
		t_response_ids,
		out_questions_cur,
		out_question_options_cur,
		out_option_answers_cur,
		out_checkbox_cur
	);
END;

PROCEDURE GetResultsForResponseIds(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_ids 			IN	security_pkg.T_SID_IDS,
	in_response_ids				IN	security_pkg.T_SID_IDS,
    out_questions_cur			OUT	security_pkg.T_OUTPUT_CUR,
    out_question_options_cur	OUT	security_pkg.T_OUTPUT_CUR,
    out_option_answers_cur		OUT	security_pkg.T_OUTPUT_CUR,
    out_checkbox_cur 			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids		security.T_SID_TABLE;
BEGIN
	t_response_ids := security_pkg.SidArrayToTable(in_response_ids);
	INTERNAL_GetResults(
		in_survey_sid,
		in_survey_version,
		in_question_ids,
		t_response_ids,
		out_questions_cur,
		out_question_options_cur,
		out_option_answers_cur,
		out_checkbox_cur
	);
END;

PROCEDURE ListResponses(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
    out_responses				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids		security.T_SID_TABLE;
BEGIN
	-- Does permission checks
	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, in_campaign_sid, t_response_ids);

	-- TODO: Add paging. Currently this page is only visible to ArcelorMittal who will only ever have 6 responses
	--       but should add paging before enabling for other clients
	--
	--		 As of 11/4/13 this is also used by the Rest API, so when you add paging keep the non-paged version. -- SGB

	OPEN out_responses FOR
		SELECT qsr.survey_response_id response_id, qsr.survey_sid, qsr.survey_version, qsr.guid,
			   qsr.submission_id, qsr.submitted_dtm, qsr.created_dtm,
			   cu.csr_user_sid user_sid, cu.full_name user_full_name, cu.full_name submitted_by,
			   r.region_sid, r.description region_description,
			   rt.class_name region_type_class_name, CASE WHEN answer_files.file_count>0 OR response_files.file_count>0 THEN 1 ELSE 0 END has_files,
			   qsc.name campaign_name, st.description AS score_label, c.name AS country, NVL(co.country_is_hidden, 1) country_is_hidden,
			   fi.flow_item_id, fi.flow_sid,
			   fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key,
			   qss.geo_latitude, qss.geo_longitude, qss.geo_altitude, qss.geo_h_accuracy, qss.geo_v_accuracy
		  FROM v$quick_survey_response qsr
		  JOIN TABLE(t_response_ids) f ON qsr.survey_response_id = f.column_value
		  LEFT JOIN quick_survey_submission qss ON qss.survey_response_id = qsr.survey_response_id AND qss.submission_id = qsr.submission_id
		  LEFT JOIN campaigns.campaign qsc on qsr.qs_campaign_sid = qsc.campaign_sid
		  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier s ON s.company_sid = ssr.supplier_sid
		  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
		  LEFT JOIN internal_audit_survey ias ON qsr.app_sid = ias.app_sid AND qsr.survey_response_id = ias.survey_response_id
		  LEFT JOIN internal_audit ia2 ON qsr.app_sid = ia2.app_sid AND ias.internal_audit_sid = ia2.internal_audit_sid
		  LEFT JOIN v$region r ON COALESCE(rsr.region_sid, s.region_sid, ia.region_sid, ia2.region_sid) = r.region_sid
		  LEFT JOIN region_type rt ON r.region_type = rt.region_type
		  LEFT JOIN csr_user cu ON qss.submitted_by_user_sid = cu.csr_user_sid
		  LEFT JOIN (
			SELECT survey_response_id, submission_id, count(*) file_count
			  FROM v$qs_answer_file
			 GROUP BY survey_response_id, submission_id
		  ) answer_files ON answer_files.survey_response_id = qsr.survey_response_id AND answer_files.submission_id = qsr.submission_id
		  LEFT JOIN (
			SELECT qrp.survey_response_id, count(*) file_count
			  FROM csr.qs_response_postit qrp
			  JOIN csr.postit_file pf ON pf.postit_id = qrp.postit_id
			 GROUP BY qrp.survey_response_id
		  ) response_files ON response_files.survey_response_id = qsr.survey_response_id
		  LEFT JOIN score_threshold st ON st.score_threshold_id = qss.score_threshold_id
		  LEFT JOIN chain.company co ON co.company_sid = ssr.supplier_sid
		  LEFT JOIN postcode.country c ON c.country = co.country_code
		  LEFT JOIN chain.questionnaire q ON q.company_sid = ssr.supplier_sid AND q.questionnaire_type_id = ssr.survey_sid
			AND (q.component_id IS NULL AND ssr.component_id IS NULL OR ssr.component_id = q.component_id)
		  LEFT JOIN csr.flow_item fi ON fi.flow_item_id = ia.flow_item_id OR fi.survey_response_id = qsr.survey_response_id
		  LEFT JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE qsr.survey_sid = in_survey_sid
		   AND (q.questionnaire_id IS NULL OR q.rejected = 0)
		 ORDER BY submitted_dtm DESC;
END;

PROCEDURE ListResponsesComments(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
	out_comments				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids					security.T_SID_TABLE;
BEGIN
	-- Does permission checks
	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, in_campaign_sid, t_response_ids);

	OPEN out_comments FOR
		SELECT qsa.survey_response_id AS response_id, qsq.label, qsa.note
		  FROM v$quick_survey_answer qsa
		  JOIN TABLE(t_response_ids) f ON qsa.survey_response_id = f.column_value
		  JOIN quick_survey_question qsq ON qsq.survey_sid = in_survey_sid AND qsq.question_id = qsa.question_id AND qsa.survey_version = qsq.survey_version
		 WHERE qsa.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND qsa.note IS NOT NULL
		   AND dbms_lob.substr(qsa.note) <> ''
		 ORDER BY qsa.survey_response_id, qsq.pos;
END;

PROCEDURE ListResponsesUnansweredQuest(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_compound_filter_id		IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid				IN	security_pkg.T_SID_ID,
	out_unanswered_questions	OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids					security.T_SID_TABLE;
BEGIN
	-- Does permission checks
	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, in_campaign_sid, t_response_ids);

	OPEN out_unanswered_questions FOR
		SELECT qsuq.survey_response_id AS response_id, qsuq.question_id, qsuq.question_type, qsuq.question_label
		  FROM v$quick_survey_unans_quest qsuq
		  JOIN TABLE(t_response_ids) f ON qsuq.survey_response_id = f.column_value
		 WHERE qsuq.survey_sid = in_survey_sid
		 ORDER BY qsuq.survey_response_id, qsuq.question_pos;
END;

PROCEDURE GetSurveyScoreThresholds(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT st.score_threshold_id, st.description
		  FROM quick_survey_score_threshold qsst
		  JOIN score_threshold st ON st.score_threshold_id = qsst.score_threshold_id
		 WHERE qsst.survey_sid = in_survey_sid
		 ORDER BY st.description;
END;

PROCEDURE GetSurveyResponsesUsers(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT qsr.user_sid, cu.full_name
		  FROM quick_survey_response qsr
		  JOIN csr_user cu ON cu.csr_user_sid = qsr.user_sid
		 WHERE qsr.survey_sid = in_survey_sid
		 ORDER BY cu.full_name;
END;

PROCEDURE GetRawResults(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_compound_filter_id	IN	chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid			IN	security_pkg.T_SID_ID,
	out_responses			OUT	security_pkg.T_OUTPUT_CUR,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_response_ids		security.T_SID_TABLE;
	v_start_dtm			DATE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, NULL);
BEGIN
    -- you need write permission to get the results
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||in_survey_sid);
	END IF;

	GetSurveyResponseIds(in_survey_sid, in_compound_filter_id, in_campaign_sid, t_response_ids);

	-- TODO: hard-coded -- where do we get survey dates from in reality when using conversion factors?
	v_start_dtm := '1 jan 2011';

	OPEN out_responses FOR
		WITH response_audit AS(
			SELECT internal_audit_sid, survey_response_id
			  FROM csr.internal_audit
			 WHERE survey_response_id IS NOT NULL
			 UNION
			SELECT internal_audit_sid, survey_response_id
			  FROM csr.internal_audit_survey
			 WHERE survey_response_id IS NOT NULL
		)
		SELECT qsr.survey_response_id, qsr.created_dtm, qsr.submitted_dtm,
				ia.internal_audit_sid audit_sid, ia.label audit_label, ia.audit_dtm, iat.label audit_type_label,
				r.description region_description, u.full_name user_full_name, files.filenames,
				ROUND(DECODE(qsr.overall_max_score, 0, 0, qsr.overall_score / qsr.overall_max_score), 15) overall_score, st.description score_threshold_description
		  FROM v$quick_survey_response qsr
		  JOIN TABLE(t_response_ids) t ON qsr.survey_response_id = t.column_value
		  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier s ON s.company_sid = ssr.supplier_sid
		  LEFT JOIN chain.v$company c ON ssr.supplier_sid = c.company_sid
		  LEFT JOIN response_audit ra ON ra.survey_response_id = qsr.survey_response_id
		  LEFT JOIN internal_audit ia ON ia.internal_audit_sid = ra.internal_audit_sid
		  LEFT JOIN internal_audit_type iat ON ia.internal_audit_type_id = iat.internal_audit_type_id
		  LEFT JOIN v$region r ON NVL(ia.region_sid, NVL(rsr.region_sid, s.region_sid)) = r.region_sid
		  LEFT JOIN csr_user u ON qsr.user_sid = u.csr_user_sid
		  LEFT JOIN score_threshold st ON qsr.score_threshold_id = st.score_threshold_id
		  LEFT JOIN (
			SELECT survey_response_id, stragg(filename) filenames
			  FROM qs_response_postit qrp
			  JOIN postit_file pf ON pf.postit_id = qrp.postit_id
			 GROUP BY survey_response_id
		  ) files ON files.survey_response_id = qsr.survey_response_id
		 WHERE qsr.survey_sid = in_survey_sid;

	OPEN out_cur FOR
		SELECT qsa.survey_response_id, qsa.question_id,
			   CASE
				WHEN qsa.question_option_id IS NOT NULL THEN qo.label
				WHEN qsa.region_sid IS NOT NULL THEN r.description
				ELSE NULL
			   END short_answer_text,
			   CASE
				WHEN (DBMS_LOB.GETLENGTH(qsa.answer) = 0) THEN NULL
				ELSE qsa.answer
			   END long_answer_text, -- split short and long answer texts as to_clob conversion was causing memory problems on live
			   CASE
				WHEN (DBMS_LOB.GETLENGTH(qsa.answer) = 0) THEN NULL
				WHEN (DBMS_LOB.GETLENGTH(qsa.answer) <= 1000) THEN DBMS_LOB.SUBSTR(qsa.answer, DBMS_LOB.GETLENGTH(qsa.answer))
				ELSE NULL
			   END shortened_long_answer_text,
			   CASE
				WHEN qsa.measure_conversion_id IS NOT NULL THEN
					-- take conversion factors into account
					measure_pkg.UNSEC_GetBaseValue(val_number, measure_conversion_id, v_start_dtm)
				ELSE val_number
			   END val_number, val_number entry_val_number,
			   measure_conversion_id entry_measure_conversion_id,
			   qsa.note, NVL(qsa.score, qo.score) score, qsa.region_sid, f.filenames,
			   CASE
				WHEN qsa.question_option_id IS NOT NULL OR (qsq.question_type = 'checkbox' AND qsa.val_number = 1) THEN qsa.answer
				ELSE NULL
			   END other_value
		  FROM quick_survey_answer qsa
		  JOIN quick_survey_question qsq ON qsq.question_id = qsa.question_id AND qsq.app_sid = qsa.app_sid
		  JOIN v$quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id AND qsa.submission_id = qsr.submission_id
		  JOIN TABLE(t_response_ids) t ON qsa.survey_response_id = t.column_value
		  LEFT JOIN qs_question_option qo ON qsa.question_option_id = qo.question_option_id AND qsa.question_id = qo.question_id AND qsa.app_sid = qo.app_sid AND qo.survey_version = v_survey_version
		  LEFT JOIN v$region r ON qsa.region_sid = r.region_sid
		  LEFT JOIN (
			SELECT qaf.survey_response_id, qaf.submission_id, qaf.question_id,
				   stragg(qaf.filename||NVL2(qaf.caption, ' - '||qaf.caption, '')) filenames
			  FROM v$qs_answer_file qaf
			  JOIN TABLE(t_response_ids) t2 ON qaf.survey_response_id = t2.column_value
			GROUP BY survey_response_id, submission_id, question_id
		  ) f ON qsa.survey_response_id = f.survey_response_id AND qsa.submission_id = f.submission_id AND qsa.question_id = f.question_Id
		 WHERE qsq.is_visible = 1
		   AND qsr.survey_sid = in_survey_sid
		   AND qsq.survey_version = v_survey_version
		 ORDER BY qsa.survey_response_id; -- sort order matters! i.e. we look for the responseId changing to move rows
END;

PROCEDURE FilterSurveys(
	in_filter			IN	VARCHAR2,
	in_audience			IN	quick_survey.audience%TYPE,
	in_group_key		IN	VARCHAR2,
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
)
IS
	v_surveys		security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_surveys := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'wwwroot/surveys');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			OPEN out_cur FOR
				SELECT null survey_sid, null label, null audience
				  FROM DUAL
				 WHERE 1 = 0;
			RETURN;
	END;

	OPEN out_cur FOR
		SELECT qs.survey_sid, qsv.label, qs.audience
		  FROM quick_survey qs
		  JOIN TABLE(securableObject_pkg.GetDescendantsWithPermAsTable(SYS_CONTEXT('SECURITY', 'ACT'), v_surveys, security_pkg.PERMISSION_READ)) s
		    ON qs.survey_sid = s.sid_id
		  JOIN quick_survey_version qsv ON qs.survey_sid = qsv.survey_sid AND qs.current_version = qsv.survey_version
		 WHERE LOWER(qsv.label) LIKE LOWER(in_filter)||'%'
		   AND (in_group_key IS NULL OR LOWER(qs.group_key) LIKE LOWER(in_group_key)||'%')
		   AND (in_audience IS NULL OR qs.audience = in_audience)
		 ORDER BY LOWER(qsv.label);
END;

PROCEDURE GetSurveyTreeWithDepth(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_fetch_depth		IN  NUMBER,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		-- Need to get the tree data from the results of filtering by group key starting from the provided parent sid
	  	SELECT so.sid_id, so.name, qs.survey_sid, qs.label, qs.group_key, qs.lookup_key,
			   CONNECT_BY_ISLEAF is_leaf, so.parent_sid_id, so.link_sid_id, wr.path, level lvl
		  FROM security.securable_object so
	      JOIN security.web_resource wr ON wr.sid_id = so.sid_id
	 LEFT JOIN csr.v$quick_survey qs ON qs.survey_sid = so.sid_id
	     WHERE level <= in_fetch_depth
	       AND (in_audience IS NULL OR qs.audience = in_audience OR qs.survey_sid IS NULL)
		   AND (in_group_key IS NULL OR qs.survey_sid IS NULL OR LOWER(qs.group_key) LIKE LOWER(in_group_key)||'%')
		   AND (qs.survey_sid IS NULL OR (qs.survey_sid IS NOT NULL AND current_version IS NOT NULL))
	START WITH ((in_include_root = 0 AND so.parent_sid_id = in_parent_sid) OR
			 	   (in_include_root = 1 AND so.sid_id = in_parent_sid))
    CONNECT BY PRIOR so.sid_id = so.parent_sid_id AND (in_show_inactive = 1 OR so.sid_id NOT IN (SELECT trash_sid FROM csr.trash))
ORDER SIBLINGS BY LOWER(so.name);
END;

PROCEDURE GetSurveyTreeTextFiltered(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT so.sid_id, so.name, so.parent_sid_id, so.link_sid_id,
			   qs.survey_sid, qs.label, qs.group_key, qs.lookup_key,
			   CONNECT_BY_ISLEAF is_leaf, LEVEL lvl, wr.path
		  FROM (
				    SELECT DISTINCT sid_id
					  FROM security.securable_object so
				 LEFT JOIN csr.v$quick_survey qs ON qs.survey_sid = so.sid_id
				START WITH sid_id IN (
							  SELECT survey_sid
							    FROM csr.v$quick_survey
							   WHERE (LOWER(label) LIKE '%'||LOWER(in_search_phrase)||'%')
								 AND (in_audience IS NULL OR audience = in_audience OR survey_sid IS NULL)
								 AND (in_group_key IS NULL OR LOWER(group_key) LIKE LOWER(in_group_key)||'%')
								 AND current_version IS NOT NULL
				)
				CONNECT BY PRIOR parent_sid_id = sid_id
					   AND (in_show_inactive = 1 OR so.sid_id NOT IN (SELECT trash_sid FROM csr.trash))
			 ) t
		  JOIN security.securable_object so ON t.sid_id = so.sid_id
	 LEFT JOIN csr.v$quick_survey qs ON qs.survey_sid = so.sid_id
	 LEFT JOIN security.web_resource wr ON so.sid_id = wr.sid_id
	START WITH ((in_include_root = 0 AND so.parent_sid_id = in_parent_sid)
			OR (in_include_root = 1 AND so.sid_id = in_parent_sid))
	CONNECT BY PRIOR so.sid_id = so.parent_sid_id
		   AND (in_show_inactive = 1 OR so.sid_id NOT IN (SELECT trash_sid FROM csr.trash));
END;

PROCEDURE GetSurveyTreeWithSelect(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_select_sid		IN	security_pkg.T_SID_ID,
	in_show_inactive 	IN 	NUMBER,
	in_group_key 		IN  VARCHAR2 DEFAULT NULL,
	in_audience			IN	VARCHAR2 DEFAULT NULL,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		-- Get all survey folders and surveys with 'audit' audience. We may have to filter by group key so have to traverse down and up the tree and get the intersect	OPEN out_cur FOR
		SELECT so.sid_id, so.name, qs.survey_sid, qs.label, qs.group_key, qs.lookup_key, 
			   CONNECT_BY_ISLEAF is_leaf, so.parent_sid_id, so.link_sid_id, wr.path, level lvl
		  FROM security.securable_object so
		  JOIN security.web_resource wr ON wr.sid_id = so.sid_id
	 LEFT JOIN csr.v$quick_survey qs ON qs.survey_sid = so.sid_id
		 WHERE (in_audience IS NULL OR qs.audience = in_audience OR qs.survey_sid IS NULL)
		   AND (in_group_key IS NULL OR qs.survey_sid IS NULL OR LOWER(qs.group_key) LIKE LOWER(in_group_key)||'%')
		   AND (qs.survey_sid IS NULL OR (qs.survey_sid IS NOT NULL AND current_version IS NOT NULL))
	START WITH ((in_include_root = 0 AND parent_sid_id = in_parent_sid) OR
				(in_include_root = 1 AND so.sid_id = in_parent_sid))
	CONNECT BY PRIOR so.sid_id = so.parent_sid_id AND (in_show_inactive = 1 OR so.sid_id NOT IN (SELECT trash_sid FROM csr.trash))
		 ORDER SIBLINGS BY LOWER(name);
END;

PROCEDURE GetAllSurveyQuestions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Check permissions need to be added!

	OPEN out_cur FOR
		SELECT question_id,  survey_sid, pos, label
		 FROM CSR.QUICK_SURVEY_QUESTION;
END;

PROCEDURE GetTreeWithDepth(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_label		quick_survey_version.label%TYPE;
	v_use_dummy_root	NUMBER(10);
	t 					security.T_SID_TABLE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, in_survey_version);
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_survey_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_parent_ids);

	SELECT label
	  INTO v_root_label
	  FROM quick_survey_version
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = v_survey_version;

	SELECT CASE WHEN in_include_root = 1 AND (SELECT COUNT(*) FROM TABLE(t) WHERE column_value = -1) > 0 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;

	OPEN out_cur FOR
		-- not sure if UNION ALL guarantees that no sorting will take place. I suspect not, so play safe
		SELECT *
		  FROM (
			-- stick in a dummy root node?
			SELECT -1 question_id, 1 is_visible, v_root_label label, 'root' question_type, 0 score, null lookup_key,
					1 lvl, 0 is_leaf, 0 rn
			  FROM DUAL
			 WHERE v_use_dummy_root = 1
			 UNION ALL
			SELECT *
			  FROM (
					SELECT qsq.question_id, qsq.is_visible, qsq.label, qsq.question_type, qsq.score, qsq.lookup_key,
							LEVEL + v_use_dummy_root lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn
					  FROM quick_survey_question qsq
					  JOIN question_type qst ON qsq.question_type = qst.question_type
					 WHERE survey_sid = in_survey_sid
					   AND is_visible = 1
					   AND qsq.question_type != 'pagebreak'
					   AND level <= in_fetch_depth
					   AND qsq.survey_version = v_survey_version
					 START WITH NVL(qsq.parent_id,-1) IN (SELECT column_value from TABLE(t))
				   CONNECT BY PRIOR qsq.question_id = qsq.parent_id AND PRIOR qsq.survey_version = qsq.survey_version
					ORDER SIBLINGS BY qsq.pos
			  )
		)
	 ORDER BY rn;
END;

PROCEDURE GetTreeWithSelect(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_select_sid		IN	security_pkg.T_SID_ID,
	in_fetch_depth		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_label		quick_survey_version.label%TYPE;
	v_use_dummy_root	NUMBER(10);
	t 					security.T_SID_TABLE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, in_survey_version);
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_survey_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_parent_ids);

	SELECT label
	  INTO v_root_label
	  FROM quick_survey_version
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = v_survey_version;

	SELECT CASE WHEN in_include_root = 1 AND (SELECT COUNT(*) FROM TABLE(t) WHERE column_value = -1) > 0 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;

	OPEN out_cur FOR
		SELECT question_id, is_visible, label, question_type, score, lookup_key, lvl, is_leaf, rn
		  FROM (
			-- stick in a dummy root node?
			SELECT -1 question_id, 1 is_visible, v_root_label label, 'root' question_type, 0 score, null lookup_key,
					1 lvl, 0 is_leaf, 0 rn, -1 parent_id
			  FROM DUAL
			 WHERE v_use_dummy_root = 1
			 UNION ALL
			SELECT *
			  FROM (
					SELECT qsq.question_id, qsq.is_visible, qsq.label, qsq.question_type, qsq.score, qsq.lookup_key,
							LEVEL + v_use_dummy_root lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn, parent_id
					  FROM quick_survey_question qsq
						JOIN question_type qst ON qsq.question_type = qst.question_type
					 WHERE survey_sid = in_survey_sid
					   AND is_visible = 1
					   AND qsq.question_type != 'pagebreak'
					   AND level <= in_fetch_depth
					   AND qsq.survey_version = v_survey_version
					 START WITH NVL(qsq.parent_id,-1) IN (SELECT column_value from TABLE(t))
				   CONNECT BY PRIOR qsq.question_id = qsq.parent_id AND PRIOR qsq.survey_version = qsq.survey_version
					ORDER SIBLINGS BY qsq.pos
			  )
		 )
		 WHERE lvl <= in_fetch_depth
		 	OR question_Id IN (
				SELECT question_id
		 		  FROM quick_survey_question
		 		 WHERE survey_version = v_survey_version
		 			START WITH question_id = in_select_sid
		 			CONNECT BY PRIOR parent_id = question_id AND PRIOR survey_version = survey_version
		 	)
		 	OR parent_id IN (
				SELECT question_id
		 		  FROM quick_survey_question
		 		 WHERE survey_version = v_survey_version
		 			START WITH question_id = in_select_sid
		 			CONNECT BY PRIOR parent_id = question_id AND PRIOR survey_version = survey_version
		 	)
		ORDER BY rn;
END;

PROCEDURE GetTreeTextFiltered(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_label		quick_survey_version.label%TYPE;
	v_use_dummy_root	NUMBER(10);
	t 					security.T_SID_TABLE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, in_survey_version);
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_survey_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_parent_ids);

	SELECT label
	  INTO v_root_label
	  FROM quick_survey_version
	 WHERE survey_sid = in_survey_sid
	   AND survey_version = v_survey_version;

	SELECT CASE WHEN in_include_root = 1 AND (SELECT COUNT(*) FROM TABLE(t) WHERE column_value = -1) > 0 THEN 1 ELSE 0 END
		INTO v_use_dummy_root
		FROM dual;

	OPEN out_cur FOR
		SELECT qsq.question_id, is_visible, label, question_type, score, lookup_key,
			lvl, is_leaf
		  FROM (
				-- stick in a dummy root node?
				SELECT -1 question_id, 1 is_visible, v_root_label label, 'root' question_type, 0 score, null lookup_key,
						1 lvl, 0 is_leaf, 0 rn
				  FROM DUAL
				 WHERE v_use_dummy_root = 1
				 UNION ALL
				sELECT *
				  FROM (
						SELECT qsq.question_id, qsq.is_visible, qsq.label, qsq.question_type, qsq.score, qsq.lookup_key,
								LEVEL + v_use_dummy_root lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn
						  FROM quick_survey_question qsq
						  JOIN question_type qst ON qsq.question_type = qst.question_type
						 WHERE survey_sid = in_survey_sid
						   AND is_visible = 1
						   AND qsq.question_type != 'pagebreak'
						   AND qsq.survey_version = v_survey_version
						 START WITH NVL(qsq.parent_id,-1) IN (SELECT column_value from TABLE(t))
					   CONNECT BY PRIOR qsq.question_id = qsq.parent_id AND PRIOR survey_version = survey_version
						ORDER SIBLINGS BY qsq.pos
				  )
		)qsq, (
			SELECT -1 question_id
			  FROM dual
			 UNION ALL
			SELECT DISTINCT question_id
			  FROM quick_survey_question
			 WHERE survey_version = v_survey_version
			 	START WITH question_id IN (
			 		SELECT question_id
			 		  FROM quick_survey_question
			 		 WHERE survey_sid = in_survey_sid
			 		   AND survey_version = v_survey_version
			 		   AND (LOWER(label) LIKE '%'||LOWER(in_search_phrase)||'%')
			 	)
			 	CONNECT BY PRIOR parent_id = question_id AND PRIOR survey_version = survey_version
		)ti
		WHERE qsq.question_Id = ti.question_Id
		ORDER BY qsq.rn;
END;

PROCEDURE GetListTextSurveys(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t 					security.T_SID_TABLE;
BEGIN

	t := security_pkg.SidArrayToTable(in_parent_ids);

	OPEN out_cur FOR
		SELECT *
		  -- ************* N.B. that's a literal 0x1 character in there, not a space **************
		  FROM (
				SELECT qsq.question_id, qsq.is_visible, qsq.label, qsq.question_type, qsq.score, qsq.lookup_key,
					LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn,
					SYS_CONNECT_BY_PATH(replace(qsq.label,chr(1),'_'),'') path
				  FROM quick_survey_question qsq
					JOIN question_type qst ON qsq.question_type = qst.question_type
				 WHERE (survey_sid = in_survey_sid or in_survey_sid = 0)
				   AND is_visible = 1
				   AND qsq.question_type != 'pagebreak'
				   AND LOWER(qsq.label) LIKE '%'||LOWER(in_search_phrase)||'%'
				 START WITH NVL(qsq.parent_id,-1) IN (SELECT column_value from TABLE(t))
			   CONNECT BY PRIOR qsq.question_id = qsq.parent_id AND PRIOR survey_version = survey_version
				ORDER SIBLINGS BY qsq.pos
		  )
		 WHERE rownum <= in_fetch_limit
		ORDER BY rn;
END;



PROCEDURE GetListTextFiltered(
	in_survey_sid		IN	security_pkg.T_SID_ID,
	in_survey_version	IN	quick_survey_version.survey_version%TYPE,
	in_parent_ids		IN	security_pkg.T_SID_IDS,
	in_include_root		IN	NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_fetch_limit		IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t 					security.T_SID_TABLE;
	v_survey_version	quick_survey_version.survey_version%TYPE := INTERNAL_GetSurveyVersion(in_survey_sid, in_survey_version);
BEGIN
	-- check permissions
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the survey with sid '||in_survey_sid);
	END IF;

	t := security_pkg.SidArrayToTable(in_parent_ids);

	OPEN out_cur FOR
		SELECT *
		  -- ************* N.B. that's a literal 0x1 character in there, not a space **************
		  FROM (
				SELECT qsq.question_id, qsq.is_visible, qsq.label, qsq.question_type, qsq.score, qsq.lookup_key,
					LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, ROWNUM rn,
					SYS_CONNECT_BY_PATH(replace(qsq.label,chr(1),'_'),'') path
				  FROM quick_survey_question qsq
					JOIN question_type qst ON qsq.question_type = qst.question_type
				 WHERE (survey_sid = in_survey_sid or in_survey_sid = 0)
				   AND is_visible = 1
				   AND qsq.question_type != 'pagebreak'
				   AND LOWER(qsq.label) LIKE '%'||LOWER(in_search_phrase)||'%'
				   AND qsq.survey_version = v_survey_version
				 START WITH NVL(qsq.parent_id,-1) IN (SELECT column_value from TABLE(t))
			   CONNECT BY PRIOR qsq.question_id = qsq.parent_id AND PRIOR survey_version = survey_version
				ORDER SIBLINGS BY qsq.pos
		  )
		 WHERE rownum <= in_fetch_limit
		ORDER BY rn;
END;

PROCEDURE GetExpressions(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	out_expr					OUT security_pkg.T_OUTPUT_CUR,
	out_non_compl_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_non_compl_role_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_msg_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_show_q_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_mand_q_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_show_p_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cust_fields_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_issue_cust_opts_cur		OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_expr FOR
		SELECT qse.expr_id, qse.expr, qse.question_id, qse.question_option_id, qsq.label question_label, qso.label question_option_label
		  FROM quick_survey_expr qse
	 LEFT JOIN quick_survey_question qsq ON qse.question_id = qsq.question_id AND qse.survey_version = qsq.survey_version
	 LEFT JOIN qs_question_option qso ON qse.question_option_id = qso.question_option_id AND qse.survey_version = qso.survey_version
		 WHERE qse.survey_sid = in_survey_sid
		   AND qse.survey_version = in_survey_version;

	OPEN out_non_compl_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, assign_to_role_sid, r.name assign_to_role_name,
			   due_dtm_abs, due_dtm_relative, due_dtm_relative_unit, title, detail, send_email_on_creation,
			   non_comp_default_id, nct.non_compliance_type_id, can_have_actions
		  FROM quick_survey_expr_action ea
		  JOIN qs_expr_non_compl_action nc ON ea.qs_expr_non_compl_action_id = nc.qs_expr_non_compl_action_id
	 LEFT JOIN csr.non_compliance_type nct ON nct.non_compliance_type_id = nc.non_compliance_type_id
	 LEFT JOIN role r ON nc.assign_to_role_sid = r.role_sid
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;

	OPEN out_non_compl_role_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, involve_role_sid, r.name involve_role_name
		  FROM quick_survey_expr_action ea
		  JOIN qs_expr_non_compl_action nc ON ea.qs_expr_non_compl_action_id = nc.qs_expr_non_compl_action_id
		  JOIN qs_expr_nc_action_involve_role ncir ON nc.qs_expr_non_compl_action_id = ncir.qs_expr_non_compl_action_id
		  JOIN role r ON ncir.involve_role_sid = r.role_sid
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;

	OPEN out_msg_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, msg, css_Class
		  FROM quick_survey_expr_action ea
		  JOIN qs_expr_msg_action msg ON ea.qs_expr_msg_action_id = msg.qs_expr_msg_action_id
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;

	OPEN out_show_q_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, ea.show_question_id question_id, q.label
		  FROM quick_survey_expr_action ea
		  JOIN quick_survey_question q ON ea.app_sid = q.app_sid AND q.question_id = ea.show_question_id AND ea.survey_version = q.survey_version
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		   AND q.is_visible=1
		 ORDER BY ea.expr_id;

	OPEN out_mand_q_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, ea.mandatory_question_id question_id, q.label
		  FROM quick_survey_expr_action ea
		  JOIN quick_survey_question q ON ea.app_sid = q.app_sid AND q.question_id = ea.mandatory_question_id AND ea.survey_version = q.survey_version
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		   AND q.is_visible=1
		 ORDER BY ea.expr_id;

	OPEN out_show_p_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, ea.show_page_id question_id, q.label
		  FROM quick_survey_expr_action ea
		  JOIN quick_survey_question q ON ea.app_sid = q.app_sid AND ea.show_page_id = q.question_id AND ea.survey_version = q.survey_version
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		   AND q.is_visible=1
		 ORDER BY ea.expr_id;
	
	OPEN out_issue_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, it.label issue_label, it.description, it.assign_to_user_sid, cu.full_name assign_to_user_name,
			it.is_urgent, it.is_critical, it.due_dtm, it.due_dtm_relative, it.due_dtm_relative_unit
		  FROM quick_survey_expr_action ea
		  JOIN issue_template it ON it.issue_template_id = ea.issue_template_id
		  LEFT JOIN csr_user cu ON cu.csr_user_sid = it.assign_to_user_sid
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;

	OPEN out_issue_cust_fields_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, itcf.issue_custom_field_id, icf.label issue_custom_field_label,
			itcf.string_value, itcf.date_value
		  FROM quick_survey_expr_action ea
		  JOIN issue_template_custom_field itcf ON itcf.issue_template_id = ea.issue_template_id
		  JOIN issue_custom_field icf ON icf.issue_custom_field_id = itcf.issue_custom_field_id
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;

	OPEN out_issue_cust_opts_cur FOR
		SELECT ea.expr_id, ea.quick_survey_expr_action_id, itcfo.issue_custom_field_id, itcfo.issue_custom_field_opt_id, icfo.label issue_custom_field_option
		  FROM quick_survey_expr_action ea
		  JOIN issue_template_cust_field_opt itcfo ON itcfo.issue_template_id = ea.issue_template_id
		  JOIN issue_custom_field_option icfo ON icfo.issue_custom_field_id = itcfo.issue_custom_field_id AND icfo.issue_custom_field_opt_id = itcfo.issue_custom_field_opt_id
		 WHERE ea.survey_sid = in_survey_sid
		   AND ea.survey_version = in_survey_version
		 ORDER BY ea.expr_id;
END;

PROCEDURE CreateExpr(
	in_survey_sid					IN	security_pkg.T_SID_ID,
	in_expr							IN	quick_survey_expr.expr%TYPE,
	in_question_id					IN	quick_survey_expr.question_id%TYPE,
	in_question_option_id			IN	quick_survey_expr.question_option_id%TYPE,
	out_expr_id						OUT	quick_survey_expr.expr_id%TYPE
)
AS
BEGIN
    -- you need write permission
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||in_survey_sid);
	END IF;

	INSERT INTO quick_survey_expr (survey_sid, expr_id, expr, survey_version, question_id, question_option_id)
		VALUES (in_survey_sid, expr_id_seq.nextval, in_expr, 0, in_question_id, in_question_option_id)
		RETURNING expr_id INTO out_expr_id;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid;
END;

PROCEDURE DeleteExpr(
	in_expr_id		IN	quick_survey_expr.expr_id%TYPE
)
AS
	v_survey_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_Id
	   AND survey_version = 0;

	-- you need write permission
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||v_survey_sid);
	END IF;

	-- we've got cascade delete FK constraints
	DELETE FROM quick_survey_expr_action
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	DELETE FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = v_survey_sid;
END;

PROCEDURE UpdateExpr(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_expr							IN	quick_survey_expr.expr%TYPE,
	in_question_id					IN	quick_survey_expr.question_id%TYPE,
	in_question_option_id			IN	quick_survey_expr.question_option_id%TYPE
)
AS
	v_survey_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_Id
	   AND survey_version = 0;

	-- you need write permission
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||v_survey_sid);
	END IF;

	UPDATE quick_survey_expr
	   SET expr = in_expr,
	       question_id = in_question_id,
		   question_option_id = in_question_option_id
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = v_survey_sid;
END;

PROCEDURE DeleteActionsNotInList (
	in_expr_id				IN	quick_survey_expr.expr_id%TYPE,
	in_actions_to_keep		IN	security_pkg.T_SID_IDS
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	t_actions_to_keep		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_actions_to_keep);
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_Id
	   AND survey_version = 0;

	-- you need write permission
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on survey sid '||v_survey_sid);
	END IF;

	-- this will cascade delete on its dependencies
	DELETE FROM quick_survey_expr_action
	 WHERE expr_id = in_expr_id
	   AND quick_survey_expr_action_id NOT IN (SELECT column_value FROM TABLE(t_actions_to_keep))
	   AND survey_version = 0;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = v_survey_sid;
END;

PROCEDURE UNSEC_CreateExprNonComplAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_title						IN	qs_expr_non_compl_action.title%TYPE,
	in_due_dtm_abs					IN	qs_expr_non_compl_action.due_dtm_abs%TYPE,
	in_due_dtm_relative				IN	qs_expr_non_compl_action.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	qs_expr_non_compl_action.due_dtm_relative_unit%TYPE,
	in_assign_to_role_sid			IN	security_pkg.T_SID_ID,
	in_involve_role_sids			IN	security_pkg.T_SID_IDS,
	in_detail						IN	qs_expr_non_compl_action.detail%TYPE,
	in_send_email_on_creation		IN	qs_expr_non_compl_action.send_email_on_creation%TYPE,
	in_non_comp_default_id			IN  qs_expr_non_compl_action.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN  qs_expr_non_compl_action.non_compliance_type_id%TYPE DEFAULT NULL,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)
AS
	v_survey_sid					security_pkg.T_SID_ID;
	v_qs_expr_non_compl_action_id	qs_expr_non_compl_action.qs_expr_non_compl_action_id%TYPE;
	t 								security.T_SID_TABLE;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	INSERT INTO qs_expr_non_compl_action
		(qs_expr_non_compl_action_id, assign_to_role_sid, due_dtm_abs, due_dtm_relative,
		 due_dtm_relative_unit, title, detail, send_email_on_creation, non_comp_default_id, non_compliance_type_id)
		VALUES (qs_expr_nc_action_id_seq.nextval, in_assign_to_role_sid, in_due_dtm_abs, in_due_dtm_relative,
			in_due_dtm_relative_unit, in_title, in_detail, in_send_email_on_creation, in_non_comp_default_id,
			in_non_compliance_type_id)
		RETURNING qs_expr_non_compl_action_id INTO v_qs_expr_non_compl_action_id;

	-- stick stuff into the roles table
    t := security_pkg.SidArrayToTable(in_involve_role_sids);
    INSERT INTO qs_expr_nc_action_involve_role
		(qs_expr_non_compl_action_id, involve_role_sid)
		SELECT v_qs_expr_non_compl_action_id, column_value
          FROM TABLE(t);

	-- and finally into the expr_action table
	INSERT INTO quick_survey_expr_action
		(quick_survey_expr_action_id, action_type, survey_sid, expr_id, qs_expr_non_compl_action_id, survey_version)
		VALUES (qs_expr_action_id_seq.nextval, 'nc', v_survey_sid, in_expr_id, v_qs_expr_non_compl_action_id, 0)
		RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;

PROCEDURE UNSEC_UpdateExprNonComplAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_title						IN	qs_expr_non_compl_action.title%TYPE,
	in_due_dtm_abs					IN	qs_expr_non_compl_action.due_dtm_abs%TYPE,
	in_due_dtm_relative				IN	qs_expr_non_compl_action.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	qs_expr_non_compl_action.due_dtm_relative_unit%TYPE,
	in_assign_to_role_sid			IN	security_pkg.T_SID_ID,
	in_involve_role_sids			IN	security_pkg.T_SID_IDS,
	in_detail						IN	qs_expr_non_compl_action.detail%TYPE,
	in_send_email_on_creation		IN	qs_expr_non_compl_action.send_email_on_creation%TYPE,
	in_non_comp_default_id			IN  qs_expr_non_compl_action.non_comp_default_id%TYPE,
	in_non_compliance_type_id		IN  qs_expr_non_compl_action.non_compliance_type_id%TYPE DEFAULT NULL
)
AS
	v_qs_expr_non_compl_action_id	qs_expr_non_compl_action.qs_expr_non_compl_action_id%TYPE;
	t 								security.T_SID_TABLE;
BEGIN
	SELECT qs_expr_non_compl_action_id
	  INTO v_qs_expr_non_compl_action_id
	  FROM quick_survey_expr_action
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id
	   AND survey_version = 0
	   FOR UPDATE; -- lock

	-- just update
	UPDATE qs_expr_non_compl_action
	   SET assign_to_role_sid = in_assign_to_role_sid,
		due_dtm_abs = in_due_dtm_abs,
		due_dtm_relative = in_due_dtm_relative,
		due_dtm_relative_unit = in_due_dtm_relative_unit,
		title = in_title,
		detail = in_detail,
		send_email_on_creation = in_send_email_on_creation,
		non_comp_default_id = in_non_comp_default_id,
		non_compliance_type_id = in_non_compliance_type_id
	 WHERE qs_expr_non_compl_action_id = v_qs_expr_non_compl_action_id;

	-- we'll reinsert shortly
	DELETE FROM qs_Expr_nc_action_involve_role
	 WHERE qs_expr_non_compl_action_id = v_qs_expr_non_compl_action_id;

	-- stick stuff into the roles table
	t := security_pkg.SidArrayToTable(in_involve_role_sids);
	INSERT INTO qs_expr_nc_action_involve_role
		(qs_expr_non_compl_action_id, involve_role_sid)
		SELECT v_qs_expr_non_compl_action_id, column_value
		  FROM TABLE(t);
END;

PROCEDURE UNSEC_CreateExprMsgAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_msg							IN	qs_expr_msg_action.msg%TYPE,
	in_css_class					IN	qs_expr_msg_action.css_class%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)
AS
	v_survey_sid				security_pkg.T_SID_ID;
	v_qs_expr_msg_action_id		qs_expr_msg_action.qs_expr_msg_action_id%TYPE;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	INSERT INTO qs_expr_msg_action
		(qs_expr_msg_action_id, msg, css_class)
		VALUES (qs_expr_msg_action_id_seq.nextval, in_msg, in_css_class)
		RETURNING qs_expr_msg_action_id INTO v_qs_expr_msg_action_id;

	-- and finally into the expr_action table
	INSERT INTO quick_survey_expr_action
		(quick_survey_expr_action_id, action_type, survey_sid, expr_id, qs_expr_msg_action_id, survey_version)
		VALUES (qs_expr_action_id_seq.nextval, 'msg', v_survey_sid, in_expr_id, v_qs_expr_msg_action_id, 0)
		RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;


PROCEDURE UNSEC_UpdateExprMsgAction(
	in_qs_expr_action_id	IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_msg					IN	qs_expr_msg_action.msg%TYPE,
	in_css_class			IN	qs_expr_msg_action.css_class%TYPE
)
AS
BEGIN
	-- just update
	UPDATE qs_expr_msg_action
	   SET msg = in_msg,
		css_class = in_css_class
	 WHERE qs_expr_msg_action_id = (
		SELECT qs_expr_msg_action_id
		  FROM quick_survey_expr_action
	     WHERE quick_survey_expr_action_id = in_qs_expr_action_id
	       AND survey_version = 0
	 );
END;

PROCEDURE UNSEC_CreateExprShowQAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)AS
	v_survey_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	INSERT INTO quick_survey_expr_action
		(quick_survey_expr_action_id, action_type, survey_sid, expr_id, show_question_id, survey_version)
		VALUES (qs_expr_action_id_seq.nextval, 'show_q', v_survey_sid, in_expr_id, in_question_id, 0)
		RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;

PROCEDURE UNSEC_UpdateExprShowQAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
)
AS
BEGIN
	UPDATE quick_survey_expr_action
	   SET show_question_id = in_question_id
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id
	   AND survey_version = 0;
END;

PROCEDURE UNSEC_CreateExprMandQAction (
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)
AS
	v_survey_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	INSERT INTO quick_survey_expr_action
		(quick_survey_expr_action_id, action_type, survey_sid, expr_id, mandatory_question_id, survey_version)
		VALUES (qs_expr_action_id_seq.nextval, 'mand_q', v_survey_sid, in_expr_id, in_question_id, 0)
		RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;

PROCEDURE UNSEC_UpdateExprMandQAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
)
AS
BEGIN
	UPDATE quick_survey_expr_action
	   SET mandatory_question_id = in_question_id
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id
	   AND survey_version = 0;
END;

PROCEDURE UNSEC_CreateExprShowPAction(
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)AS
	v_survey_sid					security_pkg.T_SID_ID;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;

	INSERT INTO quick_survey_expr_action
		(quick_survey_expr_action_id, action_type, survey_sid, expr_id, show_page_id, survey_version)
		VALUES (qs_expr_action_id_seq.nextval, 'show_p', v_survey_sid, in_expr_id, in_question_id, 0)
		RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;

PROCEDURE UNSEC_UpdateExprShowPAction(
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE
)
AS
BEGIN
	UPDATE quick_survey_expr_action
	   SET show_page_id = in_question_id
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id
	   AND survey_version = 0;
END;

PROCEDURE UNSEC_CreateExprIssueAction (
	in_expr_id						IN	quick_survey_expr.expr_id%TYPE,
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE,
	in_label						IN	issue_template.label%TYPE,
	in_description					IN	issue_template.description%TYPE,
	in_assign_to_user_sid			IN	issue_template.assign_to_user_sid%TYPE,
	in_is_urgent					IN	issue_template.is_urgent%TYPE,
	in_is_critical					IN	issue_template.is_critical%TYPE,
	in_due_dtm						IN	issue_template.due_dtm%TYPE,
	in_due_dtm_relative				IN	issue_template.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_template.due_dtm_relative_unit%TYPE,
	out_qs_expr_action_id			OUT	quick_survey_expr_action.quick_survey_expr_action_id%TYPE
)
AS
	v_survey_sid					security_pkg.T_SID_ID;
	v_issue_template_id				issue_template.issue_template_id%TYPE;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_expr
	 WHERE expr_id = in_expr_id
	   AND survey_version = 0;
	
	INSERT INTO issue_template (issue_template_id, issue_type_id, label, description, assign_to_user_sid, is_urgent, is_critical,
		due_dtm, due_dtm_relative, due_dtm_relative_unit)
	VALUES (issue_template_id_seq.NEXTVAL, in_issue_type_id, in_label, in_description, in_assign_to_user_sid, in_is_urgent, in_is_critical,
		in_due_dtm, in_due_dtm_relative, in_due_dtm_relative_unit)
	RETURNING issue_template_id INTO v_issue_template_id;

	INSERT INTO quick_survey_expr_action (quick_survey_expr_action_id, action_type, survey_sid, expr_id, survey_version, issue_template_id)
	VALUES (qs_expr_action_id_seq.nextval, 'issue', v_survey_sid, in_expr_id, 0, v_issue_template_id)
	RETURNING quick_survey_expr_action_id INTO out_qs_expr_action_id;
END;

PROCEDURE UNSEC_UpdateExprIssueAction (
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_issue_type_id				IN	issue_type.issue_type_id%TYPE,
	in_label						IN	issue_template.label%TYPE,
	in_description					IN	issue_template.description%TYPE,
	in_assign_to_user_sid			IN	issue_template.assign_to_user_sid%TYPE,
	in_is_urgent					IN	issue_template.is_urgent%TYPE,
	in_is_critical					IN	issue_template.is_critical%TYPE,
	in_due_dtm						IN	issue_template.due_dtm%TYPE,
	in_due_dtm_relative				IN	issue_template.due_dtm_relative%TYPE,
	in_due_dtm_relative_unit		IN	issue_template.due_dtm_relative_unit%TYPE
)
AS
	v_issue_template_id				issue_template.issue_template_id%TYPE;
BEGIN
	SELECT issue_template_id
	  INTO v_issue_template_id
	  FROM csr.quick_survey_expr_action
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id;

	UPDATE issue_template
	   SET issue_type_id = in_issue_type_id,
	       label = in_label,
	       description = in_description,
	       assign_to_user_sid = in_assign_to_user_sid,
		   is_urgent = in_is_urgent,
		   is_critical = in_is_critical,
		   due_dtm = in_due_dtm,
		   due_dtm_relative = in_due_dtm_relative,
		   due_dtm_relative_unit = in_due_dtm_relative_unit
	 WHERE issue_template_id = v_issue_template_id;
	
	DELETE FROM issue_template_custom_field
	 WHERE issue_template_id = v_issue_template_id;
	
	DELETE FROM issue_template_cust_field_opt
	 WHERE issue_template_id = v_issue_template_id;
END;

PROCEDURE UNSEC_SetIssueActionCustFld (
	in_qs_expr_action_id			IN	quick_survey_expr_action.quick_survey_expr_action_id%TYPE,
	in_issue_custom_field_id		IN	issue_custom_field.issue_custom_field_id%TYPE,
	in_string_value					IN	issue_template_custom_field.string_value%TYPE,
	in_date_value					IN	issue_template_custom_field.date_value%TYPE,
	in_option_ids					IN	security_pkg.T_SID_IDS
)
AS
	t_option_ids					security.T_SID_TABLE;
	v_issue_template_id				issue_template.issue_template_id%TYPE;
BEGIN
	SELECT issue_template_id
	  INTO v_issue_template_id
	  FROM csr.quick_survey_expr_action
	 WHERE quick_survey_expr_action_id = in_qs_expr_action_id;
	
	INSERT INTO issue_template_custom_field (issue_template_id, issue_custom_field_id, string_value, date_value)
	VALUES (v_issue_template_id, in_issue_custom_field_id, in_string_value, in_date_value);
	
	IF in_option_ids IS NOT NULL THEN
		t_option_ids := security_pkg.SidArrayToTable(in_option_ids);
		
		INSERT INTO issue_template_cust_field_opt (issue_template_id, issue_custom_field_id, issue_custom_field_opt_id)
		SELECT v_issue_template_id, in_issue_custom_field_id, column_value
		  FROM TABLE(t_option_ids);
	END IF;
END;

PROCEDURE AddIssue(
	in_guid				IN	quick_survey_response.guid%TYPE,
	in_question_id 		IN  quick_survey_question.question_id%TYPE,
	in_label			IN	issue.label%TYPE,
	in_description		IN	issue_log.message%TYPE,
	in_due_dtm			IN	issue.due_dtm%TYPE,
	in_source_url		IN	issue.source_url%TYPE,
	in_is_urgent		IN	NUMBER,
	in_is_critical		IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id		OUT issue.issue_id%TYPE
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_survey_version		quick_survey_version.survey_version%TYPE;
	v_region_sid			security_pkg.T_SID_ID;
	v_survey_sid			security_pkg.T_SID_ID;
BEGIN
	v_response_id := GetResponseIdFromGUID(in_guid);
	GetSurveyVersionFromResponseId(v_response_id, 0, v_survey_sid, v_survey_version);
	v_region_sid := GetResponseRegionSid(v_response_id);

	issue_pkg.CreateIssue(
		in_label					=> in_label,
		in_description				=> in_description,
		in_source_label				=> null,
		in_issue_type_id			=> csr_data_pkg.ISSUE_SURVEY_ANSWER,
		in_correspondent_id			=> null,
		in_raised_by_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid		=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_role_sid		=> null,
		in_priority_id				=> null,
		in_due_dtm					=> in_due_dtm,
		in_source_url				=> in_source_url,
		in_region_sid				=> v_region_sid,
		in_is_urgent				=> in_is_urgent,
		in_is_critical				=> in_is_critical,
		out_issue_id				=> out_issue_id
	);

	-- involve company that owns the survey
	INSERT INTO issue_involvement (issue_id, company_sid)
	SELECT out_issue_id, ssr.supplier_sid
	  FROM supplier_survey_response ssr
	 WHERE ssr.survey_response_id = v_response_id;

	IF SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') > 0 THEN
		-- involve logged in company
		INSERT INTO issue_involvement (issue_id, company_sid)
		VALUES (out_issue_id, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	-- bang in some users too?

	-- bind to answer
	-- use survey_version=0
	INSERT INTO issue_survey_answer (issue_survey_answer_id, survey_response_id, question_id, survey_version, question_version, survey_sid)
		VALUES (issue_survey_answer_id_seq.nextval, v_response_id, in_question_id, v_survey_version, v_survey_version, v_survey_sid);

	UPDATE issue
	   SET issue_survey_answer_id = issue_survey_answer_id_seq.CURRVAL
	 WHERE issue_id = out_issue_id;
END;

PROCEDURE SetPostIt(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_postit_id			IN	postit.postit_id%TYPE,
	out_postit_id			OUT postit.postit_id%TYPE
)
AS
	v_response_id	quick_survey_response.survey_response_id%TYPE;
	v_survey_sid	security_pkg.T_SID_ID;
BEGIN
	v_response_id := GetResponseIdFromGUID(in_guid);

	-- Not super happy with the security here. We secure the postit based upon a survey SID
	-- which isn't adequate -- i.e. it ought to call a custom bit of SQL to check the security.
	-- Need to add a 'secured_with_sql' to the pinboard stuff?
	-- XXX: my solution was to make the GetFile code (which is the really weak bit of this)
	-- take the SHA1 hash as a parameter, so that you need to know the file id and the hash
	-- to download a file. This still isn't perfect because fundamentally you could write new
	-- code which would mean that notes could still be accessed but it's a big improvement since
	-- the existing application code will only pull relevant postits from the database (there's
	-- no generic web-accessible 'get me the text of postit X' knocking around at the moment,
	-- whereas there was a file download page that just took a sequence which could easily be fed
	-- numbers to pull out files).
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_Id = v_response_Id;

	postit_pkg.Save(in_postit_id, null, 'message', v_survey_sid, out_postit_id);

	BEGIN
		INSERT INTO qs_response_postit (survey_response_id, postit_id)
			VALUES (v_response_id, out_postit_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- ignore
	END;
END;

/* private */
PROCEDURE FilterNumber (
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT survey_response_id
		  FROM v$quick_survey_answer qsa
		 WHERE qsa.question_id = in_question_id
		   AND ((in_comparator = '=' AND qsa.val_number = in_compare_to_num_val)
			OR (in_comparator = '>' AND qsa.val_number > in_compare_to_num_val)
			OR (in_comparator = '<' AND qsa.val_number < in_compare_to_num_val)
			OR (in_comparator = '<=' AND qsa.val_number <= in_compare_to_num_val)
			OR (in_comparator = '>=' AND qsa.val_number >= in_compare_to_num_val)
			OR (in_comparator = '!=' AND qsa.val_number != in_compare_to_num_val))
	  );
END;

/* private */
PROCEDURE FilterString (
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_str_val		IN	qs_filter_condition.compare_to_str_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT survey_response_id
		  FROM v$quick_survey_answer qsa
		 WHERE qsa.question_id = in_question_id
		   AND ((in_comparator = 'contains' AND lower(qsa.answer) LIKE '%' || lower(in_compare_to_str_val) || '%')
			OR (in_comparator = 'not contains' AND lower(qsa.answer) NOT LIKE '%' || lower(in_compare_to_str_val) || '%'))
	  );
END;

/* private */
PROCEDURE FilterFiles (
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_str_val		IN	qs_filter_condition.compare_to_str_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	IF in_comparator = 'contains' THEN
		SELECT survey_response_id
		  BULK COLLECT INTO out_sids
		  FROM (
			-- NOTE: There is a bug in Oracle 11g (BUG: 9149005/14113225) using CONTAINS with ANSI joins, the workaround is to use oracle style joins
			SELECT DISTINCT qsaf.survey_response_id
			  FROM v$qs_answer_file qsaf, v$quick_survey_response qsr
			 WHERE qsaf.survey_response_id = qsr.survey_response_id
			   AND qsaf.submission_id = qsr.submission_id
			   AND qsaf.question_id = in_question_id
			   AND CONTAINS(data, in_compare_to_str_val) > 0
		  );
	ELSIF in_comparator = 'not contains' THEN
		SELECT survey_response_id
		  BULK COLLECT INTO out_sids
		  FROM (
			SELECT survey_response_id
			  FROM (
				SELECT DISTINCT qsaf.survey_response_id
				  FROM v$qs_answer_file qsaf
				  JOIN v$quick_survey_response qsr ON qsaf.survey_response_id = qsr.survey_response_id AND qsaf.submission_id = qsr.submission_id
				)
			WHERE survey_response_id NOT IN (
				-- NOTE: There is a bug in Oracle 11g (BUG: 9149005/14113225) using CONTAINS with ANSI joins, the workaround is to use oracle style joins
				SELECT DISTINCT qsaf.survey_response_id
				  FROM v$qs_answer_file qsaf, v$quick_survey_response qsr
				 WHERE qsaf.survey_response_id = qsr.survey_response_id
				   AND qsaf.submission_id = qsr.submission_id
				   AND qsaf.question_id = in_question_id
				   AND CONTAINS(qsaf.data, in_compare_to_str_val) > 0
				)
		  );
	ELSE
		out_sids := security.T_SID_TABLE();
	END IF;
END;

/* private */
PROCEDURE FilterOption(
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_option_id		IN	qs_filter_condition.compare_to_option_id%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT survey_response_id
		  FROM v$quick_survey_answer qsa
		 WHERE qsa.question_id = in_question_id
		   AND ((in_comparator = '=' AND qsa.question_option_id = in_compare_to_option_id)
			OR (in_comparator = '!=' AND qsa.question_option_id != in_compare_to_option_id))
	  );
END;

/* private */
PROCEDURE FilterRegion (
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_region_sid	IN	qs_filter_condition.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT survey_response_id
		  FROM v$quick_survey_answer qsa
		 WHERE qsa.question_id = in_question_id
		   AND (
			(in_comparator = 'is' AND qsa.region_sid IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid = in_compare_to_region_sid))
			OR
			(in_comparator = 'is not' AND (qsa.region_sid IS NULL OR qsa.region_sid NOT IN (
			 SELECT region_sid
			   FROM region
			  WHERE region_sid = in_compare_to_region_sid)))
			OR
			(in_comparator = 'is descendant' AND qsa.region_sid IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid ! = in_compare_to_region_sid
			  START WITH region_sid = in_compare_to_region_sid
		    CONNECT BY PRIOR region_sid = parent_sid))
			OR
			(in_comparator = 'is not descendant' AND (qsa.region_sid IS NULL OR qsa.region_sid NOT IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid ! = in_compare_to_region_sid
			  START WITH region_sid = in_compare_to_region_sid
		    CONNECT BY PRIOR region_sid = parent_sid)))
		  )
	  );
END;

/* private */
PROCEDURE FilterRegionGeneral (
	in_survey_sid				IN	quick_survey.survey_sid%TYPE,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_region_sid	IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
	    SELECT DISTINCT qsr.survey_response_id
		  FROM v$quick_survey_response qsr
		  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN supplier s ON s.company_sid = ssr.supplier_sid
		  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
		  LEFT JOIN internal_audit_survey ias ON qsr.app_sid = ias.app_sid AND qsr.survey_response_id = ias.survey_response_id
		  LEFT JOIN internal_audit ia2 ON qsr.app_sid = ia2.app_sid AND ias.internal_audit_sid = ia2.internal_audit_sid
		  LEFT JOIN v$region r ON COALESCE(rsr.region_sid, s.region_sid, ia.region_sid, ia2.region_sid) = r.region_sid
	     WHERE qsr.survey_sid = in_survey_sid
		   AND (
			(in_comparator = 'is' AND r.region_sid IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid = in_compare_to_region_sid))
			OR
			(in_comparator = 'is not' AND (r.region_sid IS NULL OR r.region_sid NOT IN (
			 SELECT region_sid
			   FROM region
			  WHERE region_sid = in_compare_to_region_sid)))
			OR
			(in_comparator = 'is descendant' AND r.region_sid IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid ! = in_compare_to_region_sid
			  START WITH region_sid = in_compare_to_region_sid
		    CONNECT BY PRIOR region_sid = parent_sid))
			OR
			(in_comparator = 'is not descendant' AND (r.region_sid IS NULL OR r.region_sid NOT IN (
 		     SELECT region_sid
			   FROM csr.region
			  WHERE region_sid ! = in_compare_to_region_sid
			  START WITH region_sid = in_compare_to_region_sid
		    CONNECT BY PRIOR region_sid = parent_sid)))
		  )
	  );
END;

/* private */
PROCEDURE FilterSubmissionDate (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
  decodedDate						number(10,0);
BEGIN
	-- encoded via csr\web\site\pending\Schema.js > daysSince1900ToDate
	decodedDate := TO_NUMBER(TO_CHAR(TO_DATE('30-12-1899', 'DD-MM-YYYY'), 'j')) + in_compare_to_num_val;

	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT qsr.survey_response_id
		  FROM (
		    SELECT qsr.survey_response_id, TO_NUMBER(TO_CHAR(qsr.submitted_dtm, 'j')) AS sdtm
		      FROM v$quick_survey_response qsr
		     WHERE qsr.survey_sid = in_survey_sid
			   AND qsr.submitted_dtm IS NOT NULL
		  ) qsr
	 WHERE ((in_comparator = '=' AND qsr.sdtm = decodedDate)
	   OR (in_comparator = '>' AND qsr.sdtm > decodedDate)
	   OR (in_comparator = '<' AND qsr.sdtm < decodedDate)
	   OR (in_comparator = '<=' AND qsr.sdtm <= decodedDate)
	   OR (in_comparator = '>=' AND qsr.sdtm >= decodedDate)
	   OR (in_comparator = '!=' AND qsr.sdtm != decodedDate)));
END;

/* private */
PROCEDURE FilterContainsComments (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT vqsr.survey_response_id, vqsr.survey_sid,
		  (SELECT COUNT(*)
		     FROM quick_survey_answer
			WHERE survey_response_id = vqsr.survey_response_id
			  AND NOTE IS NOT NULL) AS note_count
		  FROM v$quick_survey_response vqsr) qsr
		 WHERE survey_sid = in_survey_sid
          AND ((in_comparator = '=' AND ((in_compare_to_num_val = 1 AND note_count > 0) OR (in_compare_to_num_val = 0 AND note_count = 0)))
		   OR (in_comparator = '!=' AND ((in_compare_to_num_val = 1 AND note_count = 0) OR (in_compare_to_num_val = 0 AND note_count > 0))));
END;

/* private */
PROCEDURE FilterContainsUnansweredQuest (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT vqsr.survey_response_id, vqsr.survey_sid,
		  (SELECT COUNT(*)
		     FROM v$quick_survey_unans_quest
			WHERE survey_sid = in_survey_sid
			  AND survey_response_id = vqsr.survey_response_id) AS questions_count
		  FROM v$quick_survey_response vqsr) qsr
		 WHERE survey_sid = in_survey_sid
		   AND ((in_comparator = '=' AND ((in_compare_to_num_val = 1 AND questions_count > 0) OR (in_compare_to_num_val = 0 AND questions_count = 0)))
			OR (in_comparator = '!=' AND ((in_compare_to_num_val = 1 AND questions_count = 0) OR (in_compare_to_num_val = 0 AND questions_count > 0))));
END;

/* private */
PROCEDURE FilterScoreThreshold (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT qsr.survey_response_id
		  FROM v$quick_survey_response qsr
		 WHERE qsr.survey_sid = in_survey_sid
		   AND ((in_comparator = '=' AND in_compare_to_num_val = qsr.score_threshold_id)
			OR (in_comparator = '!=' AND (qsr.score_threshold_id IS NULL OR in_compare_to_num_val <> qsr.score_threshold_id)))
      );
END;

/* private */
PROCEDURE FilterSubmissionUser (
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_comparator				IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	out_sids					OUT	security.T_SID_TABLE
)
AS
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT qsr.survey_response_id
		  FROM v$quick_survey_response qsr
		 WHERE qsr.survey_sid = in_survey_sid
		   AND ((in_comparator = '=' AND in_compare_to_num_val = qsr.user_sid)
			OR (in_comparator = '!=' AND in_compare_to_num_val <> qsr.user_sid))
    );
END;

/* private because we aren't passing in an existing set of ids to join to */
PROCEDURE INTERNAL_FilterResponseIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	out_sids						OUT security.T_SID_TABLE
)
AS
	v_operator						chain.filter.operator_type%TYPE;
	v_out_sids						security.T_SID_TABLE;
	v_working_sids					security.T_SID_TABLE;
	v_temp_sids						security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	SELECT operator_type
	  INTO v_operator
	  FROM chain.filter
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;

	FOR r IN (
		SELECT qsc.filter_id, qsc.qs_filter_condition_id, qsc.question_id, NULL AS condition_class, NULL AS survey_sid,
			qsc.comparator, qsc.compare_to_str_val, qsc.compare_to_num_val, qsc.compare_to_option_id, qsq.question_type,
			qsc.qs_campaign_sid
		  FROM qs_filter_condition qsc
		  JOIN quick_survey_question qsq
		    ON qsc.app_sid = qsq.app_sid
		   AND qsc.question_id = qsq.question_id
		   AND qsc.survey_version = qsq.survey_version
		 WHERE qsc.app_sid = security_pkg.GetApp
		   AND qsc.filter_id = in_filter_id

		UNION ALL

		SELECT qsfcg.filter_id, qsfcg.qs_filter_condition_general_id AS qs_filter_condition_id, NULL AS question_id, qsfcgt.condition_class, qsfcg.survey_sid,
		    qsfcg.comparator, qsfcg.compare_to_str_val, qsfcg.compare_to_num_val, NULL AS compare_to_option_id, NULL AS question_type,
			qsfcg.qs_campaign_sid
		  FROM qs_filter_condition_general qsfcg
		  JOIN qs_filter_cond_gen_type qsfcgt ON qsfcgt.qs_filter_cond_gen_type_id = qsfcg.qs_filter_cond_gen_type_id
		 WHERE qsfcg.app_sid = security_pkg.GetApp
		   AND qsfcg.filter_id = in_filter_id
	)
	LOOP
		IF r.question_id IS NOT NULL THEN
			IF r.question_type IN ('number','slider', 'date', 'checkbox') THEN
				FilterNumber(r.question_id, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.question_type IN ('radio', 'radiorow') THEN
				FilterOption(r.question_id, r.comparator, r.compare_to_option_id, v_out_sids);
			ELSIF r.question_type IN ('files') THEN
				FilterFiles(r.question_id, r.comparator, r.compare_to_str_val, v_out_sids);
			ELSIF r.question_type IN ('note') THEN
				FilterString(r.question_id, r.comparator, r.compare_to_str_val, v_out_sids);
			ELSIF r.question_type IN ('regionpicker') THEN
				FilterRegion(r.question_id, r.comparator, r.compare_to_num_val, v_out_sids);
			END IF;
		ELSE --general conditions
			IF r.condition_class IN ('generalregionpicker') THEN
				FilterRegionGeneral(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.condition_class IN ('generalsubmissiondate') THEN
				FilterSubmissionDate(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.condition_class IN ('generalsubmissionuser') THEN
				FilterSubmissionUser(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.condition_class IN ('generalcontainscomments') THEN
				FilterContainsComments(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.condition_class IN ('generalscore') THEN
				FilterScoreThreshold(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			ELSIF r.condition_class IN ('generalcontainsunansweredquestions') THEN
				FilterContainsUnansweredQuest(r.survey_sid, r.comparator, r.compare_to_num_val, v_out_sids);
			END IF;
		END IF;

		IF r.qs_campaign_sid IS NOT NULL THEN
			SELECT survey_response_id
			  BULK COLLECT INTO v_temp_sids
			  FROM quick_survey_response qsr
			  JOIN TABLE(v_out_sids) w ON qsr.survey_response_id = column_value
			 WHERE qsr.qs_campaign_sid = r.qs_campaign_sid;

			v_out_sids := v_temp_sids;
		END IF;

		IF v_working_sids IS NULL THEN
			v_working_sids := v_out_sids;
		ELSE
			IF v_operator = 'and' THEN
				SELECT column_value
				  BULK COLLECT INTO v_temp_sids
				  FROM (
					SELECT DISTINCT w.column_value
					  FROM TABLE(v_working_sids) w
						JOIN TABLE(v_out_sids) o ON w.column_value = o.column_value
				  );
			ELSE
				SELECT column_value
				  BULK COLLECT INTO v_temp_sids
				  FROM (
					SELECT column_value
					  FROM TABLE(v_working_sids)
					 UNION
					SELECT column_value
					  FROM TABLE(v_out_sids)
				  );
			END IF;
			v_working_sids := v_temp_sids;
		END IF;
	END LOOP;

	out_sids := v_working_sids;
END;

/* This adapter can go when quick survey filtering gets upgraded to use t_filtered_object type*/
PROCEDURE INTERNAL_FilterResponseIds (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	out_sids			OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_out_sids			security.T_SID_TABLE;
BEGIN
	INTERNAL_FilterResponseIds(in_filter_id, v_out_sids);

	IF v_out_sids IS NULL THEN
		out_sids := NULL;
	ELSE
		SELECT chain.T_FILTERED_OBJECT_ROW(column_value, NULL, NULL)
		  BULK COLLECT INTO out_sids
		  FROM TABLE(v_out_sids);
	END IF;
END;

PROCEDURE GetGeneralFilterConditionTypes (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qs_filter_cond_gen_type_id, condition_class, question_label
		  FROM qs_filter_cond_gen_type
		 ORDER BY question_label;
END;

FUNCTION CountSurveyResponses(
	in_survey_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_cnt		NUMBER(10);
BEGIN
	BEGIN
		SELECT count(*)
   		  INTO v_cnt
		  FROM quick_survey qs
		  JOIN v$quick_survey_response qsr ON qs.survey_sid = qsr.survey_sid
		  LEFT JOIN supplier_survey_response ssr ON qsr.survey_response_id = ssr.survey_response_id
		  LEFT JOIN chain.v$company c ON ssr.supplier_sid = c.company_sid
		  LEFT JOIN internal_audit ia ON qsr.survey_response_id = ia.survey_response_id
		  LEFT JOIN security.securable_object ia_so ON ia.internal_audit_sid = ia_so.sid_id
		 WHERE qs.survey_sid = in_survey_sid
		   AND qsr.submitted_dtm IS NOT NULL
		   AND (qs.audience not like 'chain%' OR c.company_sid IS NOT NULL)
		   AND (qs.audience!='audit' OR ia_so.parent_sid_id NOT IN (SELECT tc.trash_sid FROM customer tc))
		 GROUP BY qs.survey_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_cnt := 0;
	END;

	RETURN v_cnt;
END;

PROCEDURE GetSurveyResponseIds(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_compound_filter_id	IN  chain.compound_filter.compound_filter_id%TYPE,
	in_campaign_sid			IN  security_pkg.T_SID_ID,
	out_results				OUT security.T_SID_TABLE
)
AS
	v_list					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_survey_sid, csr_data_pkg.PERMISSION_VIEW_ALL_RESULTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading survey list on surevey_sid '||in_survey_sid);
	END IF;

	-- Get initial list of responses
	SELECT qsr.survey_response_id
	  BULK COLLECT INTO v_list
	  FROM v$quick_survey_response qsr
	  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
	  LEFT JOIN region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
	  LEFT JOIN supplier_survey_response ssr ON ssr.survey_response_id = qsr.survey_response_id
	  LEFT JOIN supplier s ON s.company_sid = ssr.supplier_sid
	  LEFT JOIN chain.v$company c ON ssr.supplier_sid = c.company_sid
	  LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
	  LEFT JOIN security.securable_object ia_so ON ia.internal_audit_sid = ia_so.sid_id
	  LEFT JOIN internal_audit_survey ias ON qsr.app_sid = ias.app_sid AND qsr.survey_response_id = ias.survey_response_id
	  LEFT JOIN internal_audit ia2 ON qsr.app_sid = ia2.app_sid AND ias.internal_audit_sid = ia2.internal_audit_sid
	  LEFT JOIN security.securable_object ia2_so ON ia2.internal_audit_sid = ia2_so.sid_id
	  LEFT JOIN (
			SELECT DISTINCT region_sid
			  FROM region
			 START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND region_sid IN (SELECT region_sid FROM region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID'))
		   CONNECT BY PRIOR app_sid = app_sid
		       AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		) rt ON COALESCE(rsr.region_sid, s.region_sid, ia.region_sid, ia2.region_sid) = rt.region_sid
	  LEFT JOIN security.securable_object cso ON qsr.qs_campaign_sid = cso.sid_id AND qsr.app_sid = cso.application_sid_id
	 WHERE qsr.app_sid = security_pkg.GetApp
	   AND qsr.survey_sid = in_survey_sid
	   AND (NVL(in_campaign_sid, 0) = 0 OR qsr.qs_campaign_sid = in_campaign_sid)
	   AND (submitted_dtm IS NOT NULL OR NVL(in_campaign_sid, 0) > 1)
	   AND (qs.audience not like 'chain%' OR c.company_sid IS NOT NULL)
	   AND (qs.audience != 'audit' OR rsr.survey_response_id IS NOT NULL OR ia_so.parent_sid_id NOT IN (SELECT tc.trash_sid FROM customer tc) OR ia2_so.parent_sid_id NOT IN (SELECT tc.trash_sid FROM customer tc))
	   AND (COALESCE(rsr.region_sid, s.region_sid, ia.region_sid, ia2.region_sid) IS NULL OR rt.region_sid IS NOT NULL)
	   AND ((qsr.qs_campaign_sid IS NOT NULL AND cso.parent_sid_id NOT IN (SELECT trash_sid FROM customer)) OR qsr.qs_campaign_sid IS NULL);

	-- XPJ passes round zero for some reason?
	IF NVL(in_compound_filter_id, 0) > 0 THEN
		chain.filter_pkg.CheckCompoundFilterAccess(in_compound_filter_id, security_pkg.PERMISSION_READ);

		FOR r IN (
			SELECT f.filter_id, ft.helper_pkg
			  FROM chain.filter f
			  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
			 WHERE f.compound_filter_id = in_compound_filter_id
		) LOOP
			EXECUTE IMMEDIATE ('BEGIN ' || r.helper_pkg || '.FilterResponseIds(:filter_id, :input, :output);END;') USING r.filter_id, v_list, OUT v_list;
		END LOOP;
	END IF;

	out_results := v_list;
END;

PROCEDURE FilterResponseIds (
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_sids				IN  security.T_SID_TABLE,
	out_sids			OUT security.T_SID_TABLE
)
AS
	v_sids				security.T_SID_TABLE;
BEGIN
	out_sids := security.T_SID_TABLE();

	INTERNAL_FilterResponseIds(in_filter_id, v_sids);

	SELECT column_value
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT i.column_value
		  FROM TABLE(in_sids) i
		  JOIN TABLE(v_sids) o ON i.column_value = o.column_value
	  );
END;

/* filter helper_pkg procs */
PROCEDURE FilterCompanySids (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_response_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_starting_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_is_campaign_filter			NUMBER;
BEGIN
	v_starting_sids := in_sids;

	IF in_parallel = 0 THEN
		out_sids := in_sids;
	ELSE
		out_sids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	INTERNAL_FilterResponseIds(in_filter_id, v_response_ids);

	IF v_response_ids IS NOT NULL THEN
		SELECT COUNT(*)
		  INTO v_is_campaign_filter
		  FROM chain.filter f
		  JOIN chain.filter_type ft ON f.filter_type_id = ft.filter_type_id
		 WHERE f.filter_id = in_filter_id
		   AND ft.description = 'Survey Campaign Filter';

		IF v_is_campaign_filter = 0 THEN
			SELECT chain.T_FILTERED_OBJECT_ROW(company_sid, NULL, NULL)
			  BULK COLLECT INTO out_sids
			  FROM chain.v$company c
			  JOIN TABLE(in_sids) t ON c.company_sid = t.object_id
			  JOIN supplier_survey_response ssr ON c.app_sid = ssr.app_sid AND c.company_sid = ssr.supplier_sid
			  JOIN TABLE(v_response_ids) w ON ssr.survey_response_id = w.object_id;
		ELSE
			SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, NULL, NULL)
			  BULK COLLECT INTO out_sids
			  FROM supplier s
			  JOIN TABLE(in_sids) t ON s.company_sid = t.object_id
			  JOIN region_survey_response rsr ON s.app_sid = rsr.app_sid AND s.region_sid = rsr.region_sid
			  JOIN TABLE(v_response_ids) w ON rsr.survey_response_id = w.object_id;
		END IF;
	END IF;

	FOR r IN (
		SELECT name, filter_field_id, show_all, group_by_index
		  FROM chain.v$filter_field
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_filter_id
		   AND (in_max_group_by IS NULL OR group_by_index <= in_max_group_by)
	) LOOP
		IF r.name LIKE 'QuestionnaireStatus.%' THEN
			IF in_parallel = 0 THEN
				supplier_pkg.FilterQuestionnaireStatuses(in_filter_id, r.filter_field_id, r.show_all, out_sids, v_result_sids);
			ELSE
				supplier_pkg.FilterQuestionnaireStatuses(in_filter_id, r.filter_field_id, r.show_all, v_starting_sids, v_result_sids);
			END IF;
		ELSIF r.name LIKE 'CampaignStatus.%' THEN
			-- in_parallel?
			IF in_parallel = 0 THEN
				FilterCompanyResponseStatuses(in_filter_id, r.filter_field_id, r.show_all, out_sids, v_result_sids);
			ELSE
				FilterCompanyResponseStatuses(in_filter_id, r.filter_field_id, r.show_all, v_starting_sids, v_result_sids);
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown filter ' || r.name);
		END IF;

		IF in_parallel = 0 THEN
			out_sids := v_result_sids;
		ELSE
			out_sids := out_sids MULTISET UNION v_result_sids;
		END IF;
	END LOOP;
END;

PROCEDURE CopyFilter (
	in_from_filter_id			IN	chain.filter.filter_id%TYPE,
	in_to_filter_id				IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	-- called as a helper_pkg call - no security
	INSERT INTO qs_filter_condition(filter_id, qs_filter_condition_id, question_id, comparator,
				compare_to_str_val, compare_to_num_val, compare_to_option_id, survey_version,
				pos, survey_sid, qs_campaign_sid, question_version)
		SELECT in_to_filter_id, csr.qs_filter_condition_id_seq.nextval, question_id, comparator,
				compare_to_str_val, compare_to_num_val, compare_to_option_id, survey_version,
				pos, survey_sid, qs_campaign_sid, question_version
		  FROM qs_filter_condition
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_from_filter_id;

	-- general conditions
	INSERT INTO qs_filter_condition_general(filter_id, qs_filter_condition_general_id, survey_sid, qs_filter_cond_gen_type_id,
				comparator, compare_to_str_val, compare_to_num_val, pos, qs_campaign_sid)
		SELECT in_to_filter_id, csr.qs_filter_condition_id_seq.nextval, survey_sid, qs_filter_cond_gen_type_id,
				comparator, compare_to_str_val, compare_to_num_val, pos, qs_campaign_sid
		  FROM qs_filter_condition_general
		 WHERE app_sid = security_pkg.GetApp
		   AND filter_id = in_from_filter_id;

	chain.filter_pkg.CopyFieldsAndValues(in_from_filter_id, in_to_filter_id);
END;

PROCEDURE DeleteFilter (
	in_filter_id				IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	-- called as a helper_pkg call - no security
	DELETE FROM qs_filter_condition_general
	 WHERE filter_id = in_filter_id;

	DELETE FROM qs_filter_condition
	 WHERE filter_id = in_filter_id;
END;

FUNCTION IsFilterEmpty(
	in_filter_id				IN  chain.filter.filter_id%TYPE
) RETURN NUMBER
AS
	v_count						NUMBER;
	v_is_filter_empty			NUMBER := chain.filter_pkg.IsFilterEmpty(in_filter_id);
BEGIN
	IF v_is_filter_empty = 0 THEN
		RETURN 0;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM dual
	 WHERE EXISTS (
		SELECT filter_id
		  FROM csr.qs_filter_condition_general
		 WHERE filter_id = in_filter_id
		)
	   OR EXISTS (
		SELECT filter_id
		  FROM csr.qs_filter_condition
		 WHERE filter_id = in_filter_id
		);

	IF v_count > 0 THEN
		RETURN 0;
	END IF;

	RETURN 1;
END;

PROCEDURE SaveFilterCondition (
	in_filter_id				IN	qs_filter_condition.filter_id%TYPE,
	in_pos						IN	qs_filter_condition.pos%TYPE,
	in_question_id				IN	qs_filter_condition.question_id%TYPE,
	in_comparator				IN	qs_filter_condition.comparator%TYPE,
	in_compare_to_str_val		IN	qs_filter_condition.compare_to_str_val%TYPE,
	in_compare_to_num_val		IN	qs_filter_condition.compare_to_num_val%TYPE,
	in_compare_to_option_id		IN	qs_filter_condition.compare_to_option_id%TYPE,
	in_survey_sid				IN	qs_filter_condition.survey_sid%TYPE,
	in_qs_campaign_sid			IN	qs_filter_condition.qs_campaign_sid%TYPE
)
AS
	v_compound_filter_id	chain.compound_filter.compound_filter_id%TYPE;
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundIdFromFilterId(in_filter_id);
	chain.filter_pkg.CheckCompoundFilterAccess(v_compound_filter_id, security_pkg.PERMISSION_WRITE);

	BEGIN
		INSERT INTO qs_filter_condition (filter_id, qs_filter_condition_id, pos, question_id, question_version, comparator,
			compare_to_str_val, compare_to_num_val, compare_to_option_id, survey_version, survey_sid, qs_campaign_sid)
		VALUES (in_filter_id, qs_filter_condition_id_seq.NEXTVAL, in_pos, in_question_id, 0, in_comparator,
			in_compare_to_str_val, in_compare_to_num_val, in_compare_to_option_id, 0, in_survey_sid, in_qs_campaign_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE qs_filter_condition
			   SET question_id = in_question_id,
				   comparator = in_comparator,
				   compare_to_str_val = in_compare_to_str_val,
				   compare_to_num_val = in_compare_to_num_val,
				   compare_to_option_id = in_compare_to_option_id
			 WHERE app_sid = security_pkg.GetApp
			   AND filter_id = in_filter_id
			   AND pos = in_pos
			   AND survey_sid = in_survey_sid
			   AND null_pkg.seq(qs_campaign_sid, in_qs_campaign_sid) = 1;
	END;
END;

PROCEDURE SaveFilterConditionGeneral (
	in_filter_id					IN	qs_filter_condition_general.filter_id%TYPE,
	in_pos							IN	qs_filter_condition_general.pos%TYPE,
	in_survey_sid					IN	quick_survey.survey_sid%TYPE,
	in_qs_filter_cond_gen_type_id	IN	qs_filter_cond_gen_type.qs_filter_cond_gen_type_id%TYPE,
	in_comparator					IN	qs_filter_condition_general.comparator%TYPE,
	in_compare_to_str_val			IN	qs_filter_condition_general.compare_to_str_val%TYPE,
	in_compare_to_num_val			IN	qs_filter_condition_general.compare_to_num_val%TYPE,
	in_qs_campaign_sid				IN	qs_filter_condition_general.qs_campaign_sid%TYPE
)
AS
	v_compound_filter_id				chain.compound_filter.compound_filter_id%TYPE;
BEGIN
	v_compound_filter_id := chain.filter_pkg.GetCompoundIdFromFilterId(in_filter_id);
	chain.filter_pkg.CheckCompoundFilterAccess(v_compound_filter_id, security_pkg.PERMISSION_WRITE);

	BEGIN
		INSERT INTO qs_filter_condition_general (filter_id, qs_filter_condition_general_id, pos,
		    survey_sid, qs_filter_cond_gen_type_id,
			comparator, compare_to_str_val, compare_to_num_val, qs_campaign_sid)
		VALUES (in_filter_id, qs_filter_condition_gen_id_seq.NEXTVAL, in_pos, in_survey_sid,
		    in_qs_filter_cond_gen_type_id,
			in_comparator, in_compare_to_str_val, in_compare_to_num_val, in_qs_campaign_sid);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE qs_filter_condition_general
			   SET qs_filter_cond_gen_type_id = in_qs_filter_cond_gen_type_id,
				comparator = in_comparator,
				compare_to_str_val = in_compare_to_str_val,
				compare_to_num_val = in_compare_to_num_val
			 WHERE app_sid = security_pkg.GetApp
			   AND filter_id = in_filter_id
			   AND pos = in_pos
			   AND survey_sid = in_survey_sid
			   AND null_pkg.seq(qs_campaign_sid, in_qs_campaign_sid) = 1;
	END;
END;

PROCEDURE DeleteRemainingConditions (
	in_filter_id					IN	qs_filter_condition.filter_id%TYPE,
	in_survey_sid					IN	qs_filter_condition.survey_sid%TYPE,
	in_qs_campaign_sid				IN	qs_filter_condition.qs_campaign_sid%TYPE,
	in_conditions_to_keep			IN	security_pkg.T_SID_IDS
)
AS
	v_conditions_to_keep			security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_conditions_to_keep);
BEGIN
	chain.filter_pkg.CheckCompoundFilterAccess(chain.filter_pkg.GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);

	DELETE FROM qs_filter_condition
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id
	   AND survey_sid = in_survey_sid
	   AND null_pkg.seq(qs_campaign_sid, in_qs_campaign_sid) = 1
	   AND pos NOT IN (
		SELECT column_value FROM TABLE(v_conditions_to_keep)
	);

	DELETE FROM qs_filter_condition_general
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id
	   AND survey_sid = in_survey_sid
	   AND null_pkg.seq(qs_campaign_sid, in_qs_campaign_sid) = 1
	   AND pos NOT IN (
		SELECT column_value FROM TABLE(v_conditions_to_keep)
	);
END;

FUNCTION HasFilterConditions(
	in_filter_id				IN	chain.filter.filter_id%TYPE
) RETURN NUMBER
AS
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM (
		SELECT filter_id
		  FROM qs_filter_condition
		 WHERE filter_id = in_filter_id
		 UNION
		 SELECT filter_id
		  FROM qs_filter_condition_general
		 WHERE filter_id = in_filter_id
	  );

	IF v_count > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE ClearConditions(
	in_filter_id				IN	chain.filter.filter_id%TYPE
)
AS
BEGIN
	DELETE FROM qs_filter_condition
	 WHERE app_sid = security_pkg.GetApp
	   AND filter_id = in_filter_id;

	DELETE FROM qs_filter_condition_general
	 WHERE app_sid = security_pkg.GetApp
	  AND filter_id = in_filter_id;
END;

PROCEDURE DeleteRemainingFilters (
	in_filter_id					IN	chain.filter.filter_id%TYPE,
	in_survey_sids_to_keep			IN	security_pkg.T_SID_IDS,
	in_campaign_sids_to_keep		IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	chain.filter_pkg.CheckCompoundFilterAccess(chain.filter_pkg.GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_WRITE);

	-- Just in case.
	DELETE FROM temp_filter_conditions;

	-- crap hack for ODP.NET
	IF in_survey_sids_to_keep IS NOT NULL AND NOT (in_survey_sids_to_keep.COUNT = 1 AND in_survey_sids_to_keep(1) IS NULL) THEN
		FOR v_i IN 1 .. in_survey_sids_to_keep.COUNT LOOP
			INSERT INTO temp_filter_conditions (survey_sid, qs_campaign_sid)
				 VALUES (in_survey_sids_to_keep(v_i), in_campaign_sids_to_keep(v_i));
		END LOOP;
	END IF;


	DELETE FROM qs_filter_condition
	      WHERE filter_id = in_filter_id
		    AND (survey_sid, NVL(qs_campaign_sid, -1))
			NOT IN (
				SELECT survey_sid, qs_campaign_sid
				  FROM temp_filter_conditions
			);

	DELETE FROM qs_filter_condition_general
	      WHERE filter_id = in_filter_id
		    AND (survey_sid, NVL(qs_campaign_sid, -1))
			NOT IN (
				SELECT survey_sid, qs_campaign_sid
				  FROM temp_filter_conditions
			);
END;

PROCEDURE GetAllFilterConditions (
	in_filter_id				IN	chain.filter.filter_id%TYPE,
	out_filter_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_filter_cond_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	chain.filter_pkg.CheckCompoundFilterAccess(chain.filter_pkg.GetCompoundIdFromFilterId(in_filter_id), security_pkg.PERMISSION_READ);

	OPEN out_filter_cur FOR
		SELECT f.app_sid, f.filter_id, f.filter_type_id, f.compound_filter_id, f.operator_type, COALESCE(qsq.survey_sid, qsfcg.survey_sid, -1) AS survey_sid,
			NVL(qsfc.qs_campaign_sid, -1) as campaign_sid
		  FROM chain.filter f -- This will move to CSR at some point
		  LEFT JOIN qs_filter_condition qsfc ON f.app_sid = qsfc.app_sid AND f.filter_id = qsfc.filter_id
		  LEFT JOIN quick_survey_question qsq ON qsfc.app_sid = qsq.app_sid AND qsfc.question_id = qsq.question_id AND qsfc.survey_version = qsq.survey_version
		  LEFT JOIN qs_filter_condition_general qsfcg ON f.app_sid = qsfcg.app_sid AND f.filter_id = qsfcg.filter_id
		 WHERE f.app_sid = security_pkg.GetApp -- ??
		   AND f.filter_id = in_filter_id
		 GROUP BY f.app_sid, f.filter_id, f.filter_type_id, f.compound_filter_id, f.operator_type, COALESCE(qsq.survey_sid, qsfcg.survey_sid, -1),NVL(qsfc.qs_campaign_sid, -1);

	OPEN out_filter_cond_cur FOR
		SELECT filter_id, pos, question_id,
			comparator, compare_to_str_val, compare_to_num_val, compare_to_option_id,
			question_label, node_class, compare_to_option_description, compare_to_region_description,
			survey_sid, qs_campaign_sid
		  FROM (
		    SELECT qsfc.filter_id, qsfc.pos, qsfc.question_id,
				qsfc.comparator, qsfc.compare_to_str_val, qsfc.compare_to_num_val, qsfc.compare_to_option_id,
				qsq.label question_label, 'survey'||qsq.question_type node_class, op.label compare_to_option_description,
				CASE WHEN qsq.question_type = 'regionpicker' AND qsfc.compare_to_num_val IS NOT NULL THEN (
				  SELECT description FROM v$region WHERE app_sid = qsfc.app_sid AND region_sid = qsfc.compare_to_num_val)
					ELSE NULL END AS compare_to_region_description,
				qsfc.survey_sid, qsfc.qs_campaign_sid
			  FROM qs_filter_condition qsfc
			  LEFT JOIN quick_survey_question qsq ON qsfc.app_sid = qsq.app_sid AND qsfc.question_id = qsq.question_id AND qsfc.survey_version = qsq.survey_version
			  LEFT JOIN qs_question_option op ON qsfc.question_id = op.question_id AND qsfc.compare_to_option_id = op.question_option_id AND qsfc.survey_version = op.survey_version
			  LEFT JOIN region r ON qsfc.app_sid = r.app_sid AND qsq.question_type='regionpicker' AND qsfc.compare_to_num_val = r.region_sid
		     WHERE qsfc.app_sid = security_pkg.GetApp
			   AND filter_id IN (
			     SELECT filter_id FROM chain.filter WHERE app_sid = security_pkg.GetApp AND filter_id = in_filter_id)

		    UNION ALL
		    --general conditions
		    SELECT qsfc.filter_id, qsfc.pos, qsfcgt.qs_filter_cond_gen_type_id AS question_id,
				qsfc.comparator, qsfc.compare_to_str_val, qsfc.compare_to_num_val, NULL AS compare_to_option_id,
				qsfcgt.question_label, qsfcgt.condition_class AS node_class, NULL AS compare_to_option_description,
				CASE WHEN qsfcgt.condition_class = 'generalregionpicker' AND qsfc.compare_to_num_val IS NOT NULL THEN (
				  SELECT description FROM v$region WHERE app_sid = qsfc.app_sid AND region_sid = qsfc.compare_to_num_val)
					ELSE NULL END AS compare_to_region_description,
				qsfc.survey_sid, qsfc.qs_campaign_sid
			  FROM qs_filter_condition_general qsfc
			  JOIN qs_filter_cond_gen_type qsfcgt ON qsfcgt.qs_filter_cond_gen_type_id = qsfc.qs_filter_cond_gen_type_id
		     WHERE qsfc.app_sid = security_pkg.GetApp
			   AND filter_id IN (
			     SELECT filter_id FROM chain.filter WHERE app_sid = security_pkg.GetApp AND filter_id = in_filter_id)
		  )
		 ORDER BY pos;
END;

PROCEDURE UNSEC_SetAnswer(
	in_response_id				IN quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN quick_survey_response.last_submission_id%TYPE DEFAULT NULL,
	in_question_lookup_key		IN quick_survey_question.lookup_key%TYPE,
	in_answer					IN VARCHAR2,
	in_report_errors			IN NUMBER DEFAULT 0
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
	v_question_id				quick_survey_question.question_id%TYPE;
	v_question_type				quick_survey_question.question_type%TYPE;
	v_question_version			quick_survey_question.question_version%TYPE;
	v_survey_sid				quick_survey_question.survey_sid%TYPE;
	v_survey_version			quick_survey_response.survey_version%TYPE;
	v_submission_id				quick_survey_response.last_submission_id%TYPE;
	v_question_option_id		csr.qs_question_option.question_option_id%TYPE;
	v_numeric_answer			NUMBER(10);
BEGIN
	BEGIN

		IF in_response_id IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001,'Response Id must not be null');
		END IF;

		IF in_question_lookup_key IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001,'Question Lookup Key must not be null');
		END IF;

		v_submission_id := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
		v_survey_version := INTERNAL_GetSubmSurveyVersion(in_response_id, v_submission_id);
		
		SELECT survey_sid
		  INTO v_survey_sid
		  FROM quick_survey_response
		 WHERE survey_response_id = in_response_id
		   AND app_sid = v_app_sid;
		
		SELECT question_id, question_type, question_version
		  INTO v_question_id, v_question_type, v_question_version
		  FROM quick_survey_question
		 WHERE UPPER(lookup_key) = UPPER(in_question_lookup_key)
		   and survey_sid = v_survey_sid
		   AND survey_version = v_survey_version
		   AND app_sid = v_app_sid;

		IF v_question_type = 'checkbox' OR
		   v_question_type = 'number' OR
		   v_question_type = 'slider' OR
		   v_question_type = 'regionpicker' THEN
			v_numeric_answer := TO_NUMBER(in_answer);
		END IF;

		CASE
		  WHEN v_question_type = 'section' OR v_question_type = 'checkboxgroup' OR v_question_type = 'custom' OR
			   v_question_type = 'date' OR v_question_type = 'noncompliances' OR v_question_type = 'matrix' THEN
		    -- we don't currently support date but we ought to, the rest have no real meaning in this context.
			-- error?
			NULL;
		  WHEN v_question_type = 'checkbox' OR v_question_type = 'number' OR v_question_type = 'slider' THEN
			BEGIN
				INSERT INTO csr.quick_survey_answer(survey_response_id, submission_id, survey_version, version_stamp, question_id, val_number, question_version, survey_sid)
				VALUES( in_response_id, v_submission_id, v_survey_version, csr.version_stamp_seq.nextval, v_question_id, v_numeric_answer, v_question_version, v_survey_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE quick_survey_answer
					   SET val_number = v_numeric_answer
					 WHERE survey_response_id = in_response_id
					   AND question_id = v_question_id
					   AND submission_id = v_submission_id
					   AND survey_version = v_survey_version
					   AND survey_sid = v_survey_sid
					   AND question_version = v_question_version;
			END;
		  WHEN v_question_type = 'note' OR v_question_type = 'rtquestion' THEN
			BEGIN
				INSERT INTO csr.quick_survey_answer(survey_response_id, submission_id, survey_version, version_stamp, question_id, answer, question_version, survey_sid)
				VALUES( in_response_id, v_submission_id, v_survey_version, csr.version_stamp_seq.nextval, v_question_id, in_answer, v_question_version, v_survey_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE quick_survey_answer
					   SET answer = in_answer
					 WHERE survey_response_id = in_response_id
					   AND question_id = v_question_id
					   AND submission_id = v_submission_id
					   AND survey_version = v_survey_version
					   AND survey_sid = v_survey_sid
					   AND question_version = v_question_version;
			END;
		  WHEN v_question_type = 'radio' OR v_question_type = 'radiorow' THEN
			SELECT question_option_id
			  INTO v_question_option_id
			  FROM qs_question_option
			 WHERE question_id = v_question_id
			   AND UPPER(lookup_key) = UPPER(in_answer)
			   AND survey_version = v_survey_version;

			BEGIN
				INSERT INTO csr.quick_survey_answer(survey_response_id, submission_id, survey_version, version_stamp, question_id, question_option_id, question_version, survey_sid)
				VALUES( in_response_id, v_submission_id, v_survey_version, csr.version_stamp_seq.nextval, v_question_id, v_question_option_id, v_question_version, v_survey_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE quick_survey_answer
					   SET question_option_id = v_question_option_id
					 WHERE survey_response_id = in_response_id
					   AND question_id = v_question_id
					   AND submission_id = v_submission_id
					   AND survey_version = v_survey_version
   					   AND survey_sid = v_survey_sid
					   AND question_version = v_question_version;
			END;
		  WHEN v_question_type = 'regionpicker' THEN
			BEGIN
				INSERT INTO csr.quick_survey_answer(survey_response_id, submission_id, survey_version, version_stamp, question_id, region_sid, question_version, survey_sid)
				VALUES( in_response_id, v_submission_id, v_survey_version, csr.version_stamp_seq.nextval, v_question_id, v_numeric_answer, v_question_version, v_survey_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE quick_survey_answer
					   SET region_sid = v_numeric_answer
					 WHERE survey_response_id = in_response_id
					   AND question_id = v_question_id
					   AND submission_id = v_submission_id
					   AND survey_version = v_survey_version
   					   AND survey_sid = v_survey_sid
					   AND question_version = v_question_version;
			END;
		END CASE;
	EXCEPTION
		WHEN OTHERS THEN
			IF in_report_errors = 1 THEN
				RAISE;
			ELSE
				RETURN;
			END IF;
	END;

END;

PROCEDURE UNSEC_SetAnswerScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey_version.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_score					IN	quick_survey_answer.score%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE
)
AS
BEGIN
	-- No security - only called internally by calculations
	BEGIN
		INSERT INTO quick_survey_answer(question_id, question_version, survey_response_id, score, max_score, version_stamp, submission_id, survey_sid, survey_version)
		VALUES (in_question_id, in_question_version, in_response_id, in_score, in_max_score, version_stamp_seq.NEXTVAL, in_submission_id, in_survey_sid, in_survey_version);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE quick_survey_answer
			   SET score = in_score,
				   max_score = in_max_score
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id
			   AND submission_id = in_submission_id;
	END;
END;

PROCEDURE UNSEC_SetAnswerMaxScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_max_score				IN	quick_survey_answer.max_score%TYPE
)
AS
BEGIN
	-- No security - only called internally by calculations
	BEGIN
		INSERT INTO quick_survey_answer(question_id, question_version, survey_response_id, score, max_score, version_stamp, submission_id, survey_sid, survey_version)
		VALUES (in_question_id, in_question_version, in_response_id, 0, in_max_score, version_stamp_seq.NEXTVAL, in_submission_id, in_survey_sid, in_survey_version);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE quick_survey_answer
			   SET score = CASE WHEN score > in_max_score THEN in_max_score ELSE NVL(score,0) END,
				   max_score = in_max_score
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id
			   AND question_version = in_question_version
			   AND survey_sid = in_survey_sid
			   AND submission_id = in_submission_id;
	END;
END;

PROCEDURE UNSEC_SetSectionWeight(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid				IN	quick_survey.survey_sid%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE,
	in_question_version			IN	quick_survey_question.question_version%TYPE,
	in_weight					IN	quick_survey_answer.max_score%TYPE
)
AS
BEGIN
	-- No security - only called internally by calculations
	BEGIN
		INSERT INTO quick_survey_answer(question_id, survey_response_id, weight_override, version_stamp, submission_id, survey_version,
			question_version, survey_sid)
		VALUES (in_question_id, in_response_id, in_weight, version_stamp_seq.NEXTVAL, in_submission_id, in_survey_version,
			in_question_version, in_survey_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE quick_survey_answer
			   SET weight_override = in_weight
			 WHERE survey_response_id = in_response_id
			   AND question_id = in_question_id
			   AND submission_id = in_submission_id;
	END;
END;

FUNCTION UNSEC_OtherTextReqForScore(
	in_survey_response_id			quick_survey_response.survey_response_id%TYPE
)
RETURN BOOLEAN
AS
	v_other_text_req_for_score		NUMBER(1);
BEGIN
	-- No security - only called internally by calculations
	SELECT other_text_req_for_score
	  INTO v_other_text_req_for_score
	  FROM quick_survey_response qsr
	  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
	  LEFT JOIN quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id
	 WHERE qsr.survey_response_id = in_survey_response_id;

	RETURN null_pkg.eq(v_other_text_req_for_score, 1);
END;

PROCEDURE INTERNAL_CalculateScore(
	in_response_id					IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id				IN	quick_survey_submission.submission_id%TYPE,
	in_survey_sid					IN	quick_survey_version.survey_sid%TYPE,
	in_survey_version				IN	quick_survey_version.survey_version%TYPE,
	in_question_id					IN	quick_survey_question.question_id%TYPE,
	out_score						OUT	quick_survey_answer.score%TYPE,
	out_max_score					OUT	quick_survey_answer.max_score%TYPE
)
AS
	v_temp_score			quick_survey_answer.score%TYPE;
	v_temp_max_score		quick_survey_answer.max_score%TYPE;
	v_question_type			quick_survey_question.question_type%TYPE;
	v_dont_normalise_score	quick_survey_question.dont_normalise_score%TYPE;
	v_has_score_expression	quick_survey_question.has_score_expression%TYPE;
	v_has_max_score_expr	quick_survey_question.has_max_score_expr%TYPE;
	v_question_max_score	quick_survey_question.max_score%TYPE;
	v_question_version		quick_survey_question.question_version%TYPE;
	v_upload_score			quick_survey_question.upload_score%TYPE;
	v_has_file				NUMBER(1);
BEGIN
	SELECT question_type, dont_normalise_score, has_score_expression,
		   has_max_score_expr, max_score, question_version, upload_score
	  INTO v_question_type, v_dont_normalise_score, v_has_score_expression,
		   v_has_max_score_expr, v_question_max_score, v_question_version, v_upload_score
	  FROM quick_survey_question
	 WHERE question_id = in_question_id
	   AND survey_version = in_survey_version
	   AND survey_sid = in_survey_sid
	   AND is_visible = 1;

	-- Does this question have any answer files against it for this submission - used to calculate score if upload score is set
	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_has_file
	  FROM qs_answer_file af
	  JOIN qs_submission_file sf ON af.qs_answer_file_id = sf.qs_answer_file_id AND af.survey_response_id = sf.survey_response_id
	 WHERE af.question_id = in_question_id
	   AND af.survey_response_id = in_response_id
	   AND af.question_version = v_question_version
	   AND sf.submission_id = in_submission_id;

	IF v_question_type IN ('section', 'matrix', 'checkboxgroup') THEN
		FOR r IN (
			SELECT qsq.question_id, NVL(qsa.weight_override, qsq.weight) weight
			  FROM quick_survey_question qsq
			  LEFT JOIN quick_survey_answer qsa
			    ON qsq.question_id = qsa.question_id
			   AND qsa.question_version = qsq.question_version				
			   AND qsq.app_sid = qsa.app_sid
			   AND qsa.survey_response_id = in_response_id
			   AND qsa.submission_id = in_submission_id
			 WHERE qsq.question_id IN (
				SELECT question_id
				  FROM quick_survey_question
				 WHERE survey_version = in_survey_version
				 START WITH parent_id = in_question_id
				CONNECT BY PRIOR question_id = parent_id AND PRIOR question_type NOT IN ('section', 'matrix', 'checkboxgroup') AND PRIOR survey_version = survey_version AND PRIOR question_version = parent_version
			 )
			   AND qsq.survey_version = in_survey_version
			   AND is_visible = 1
		) LOOP
			INTERNAL_CalculateScore(in_response_id, in_submission_id, in_survey_sid, in_survey_version, r.question_id, v_temp_score, v_temp_max_score);

			out_score := CASE WHEN out_score IS NULL AND v_temp_score IS NULL THEN NULL ELSE NVL(out_score, 0) + (r.weight*NVL(v_temp_score, 0)) END;
			out_max_score := CASE WHEN out_max_score IS NULL AND v_temp_max_score IS NULL THEN NULL ELSE NVL(out_max_score, 0) +(r.weight* NVL(v_temp_max_score, 0)) END;
		END LOOP;

		IF v_upload_score IS NOT NULL THEN
			out_max_score := out_max_score + v_upload_score;

			IF v_has_file = 1 THEN
				out_score := out_score + v_upload_score;
			END IF;
		END IF;

		-- Don't overwrite section scores if they have been set via an expression
		IF v_has_score_expression = 1 OR v_has_max_score_expr = 1 THEN
			SELECT CASE WHEN v_has_score_expression = 1 THEN MIN(score) ELSE out_score END,
				   CASE WHEN v_has_max_score_expr = 1 THEN MIN(max_score) ELSE out_max_score END
			  INTO out_score, out_max_score
			  FROM quick_survey_answer
			 WHERE survey_response_id = in_response_id
			   AND submission_id = in_submission_id
			   AND question_id = in_question_id;
			out_score := LEAST(out_max_score, out_score);
		ELSIF v_question_max_score IS NOT NULL AND v_question_type = 'checkboxgroup' AND out_max_score IS NOT NULL THEN
			out_max_score := v_question_max_score;
			out_score := LEAST(v_question_max_score, out_score);
		END IF;

		IF out_max_score IS NULL OR out_max_score = 0 THEN
			-- XXX: Would it be better to remove this row altogether?
			UNSEC_SetAnswerScore(in_response_id, in_submission_id, in_survey_sid, in_survey_version, in_question_id, v_question_version, NULL, NULL);
		ELSE

			IF v_question_type = 'section' AND v_dont_normalise_score=0 THEN
				-- For now only normalise sections - could have a configuration to normalise matrixes
				out_score := out_score / out_max_score;
				out_max_score := out_max_score / out_max_score;
			END IF;
			UNSEC_SetAnswerScore(in_response_id, in_submission_id, in_survey_sid, in_survey_version, in_question_id, v_question_version, out_score, out_max_score);
		END IF;
	ELSE
		BEGIN
			SELECT score, max_score
			  INTO out_score, out_max_score
			  FROM quick_survey_answer
			 WHERE survey_response_id = in_response_id
			   AND submission_id = in_submission_id
			   AND question_id = in_question_id;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
END;

FUNCTION GetThresholdFromScore (
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	NUMBER
) RETURN quick_survey_submission.score_threshold_id%TYPE
AS
	v_score_threshold_id		score_threshold.score_threshold_id%TYPE;
BEGIN
	BEGIN
		SELECT score_threshold_id
		  INTO v_score_threshold_id
		  FROM (
			SELECT st.score_threshold_id
			  FROM score_threshold st
			 WHERE st.app_sid = security_pkg.GetApp
			   AND st.score_type_id = in_score_type_id
			   AND in_score<=st.max_value
			 ORDER BY st.max_value ASC
			)
		 WHERE ROWNUM = 1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_score_threshold_id := NULL;
	END;

	RETURN v_score_threshold_id;
END;

PROCEDURE CalculateResponseScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	out_score					OUT	quick_survey_answer.score%TYPE,
	out_max_score				OUT	quick_survey_answer.max_score%TYPE,
	out_score_threshold_id		OUT	quick_survey_submission.score_threshold_id%TYPE
)
AS
	v_survey_sid			security_pkg.T_SID_ID;
	v_score_type_id			score_type.score_type_id%TYPE;
	v_min_score				score_type.min_score%TYPE;
	v_max_score				score_type.max_score%TYPE;
	v_start_score			score_type.start_score%TYPE;
	v_normalise				score_type.normalise_to_max_score%TYPE;
	v_temp_score			quick_survey_answer.score%TYPE;
	v_temp_max_score		quick_survey_answer.max_score%TYPE;
	v_submission_id			quick_survey_submission.submission_id%TYPE := INTERNAL_GetSubmissionId(in_response_id, in_submission_id);
	v_survey_version		quick_survey_version.survey_version%TYPE := INTERNAL_GetSubmSurveyVersion(in_response_id, in_submission_id);
BEGIN
	-- No security - we aren't changing the answers, just calculating a score based on them

	IF UNSEC_OtherTextReqForScore(in_response_id) THEN
		UNSEC_UpdateOtherTextScores(in_response_id, in_submission_id);
	END IF;

	SELECT qsr.survey_sid, qs.score_type_id
	  INTO v_survey_sid, v_score_type_id
	  FROM quick_survey_response qsr
	  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid AND qsr.app_sid = qs.app_sid
	 WHERE qsr.survey_response_id = in_response_id;

	FOR r IN (
		SELECT qsq.question_id, NVL(qsa.weight_override, qsq.weight) weight
		  FROM quick_survey_question qsq
		  LEFT JOIN quick_survey_answer qsa
		    ON qsq.question_id = qsa.question_id
		   AND qsq.question_version = qsa.question_version
		   AND qsq.app_sid = qsa.app_sid
		   AND qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = in_submission_id
		 WHERE qsq.survey_sid = v_survey_sid
		   AND qsq.parent_id IS NULL
		   AND qsq.survey_version = v_survey_version
		   AND qsq.is_visible = 1
	) LOOP
		INTERNAL_CalculateScore(in_response_id, v_submission_id, v_survey_sid, v_survey_version, r.question_id, v_temp_score, v_temp_max_score);

		out_score := CASE WHEN out_score IS NULL AND v_temp_score IS NULL THEN NULL ELSE NVL(out_score, 0) + (r.weight*NVL(v_temp_score, 0)) END;
		out_max_score := CASE WHEN out_max_score IS NULL AND v_temp_max_score IS NULL THEN NULL ELSE NVL(out_max_score, 0) +(r.weight*NVL(v_temp_max_score, 0)) END;
	END LOOP;

	IF v_score_type_id IS NULL THEN
		v_normalise := 1;
	ELSE
		SELECT min_score, max_score, start_score, normalise_to_max_score
		  INTO v_min_score, v_max_score, v_start_score, v_normalise
		  FROM score_type
		 WHERE score_type_id = v_score_type_id;

		out_score := v_start_score + out_score;
	END IF;

	IF v_normalise = 1 AND out_max_score IS NOT NULL AND out_max_score != 0 THEN
		out_score := out_score / out_max_score;
		out_max_score := out_max_score / out_max_score;
	END IF;

	IF v_max_score IS NOT NULL THEN
		out_max_score := v_max_score;

		IF v_normalise = 1 THEN
			out_score := out_score * out_max_score;
		END IF;

		IF out_score > v_max_score THEN
			out_score := v_max_score;
		END IF;
	END IF;

	out_score_threshold_id := GetThresholdFromScore(v_score_type_id, out_score);

	-- Re-base min score after normalisation (otherwiwse anyting != 0 wouldn't work as expected) and after thresholding
	IF v_min_score IS NOT NULL AND out_score < v_min_score THEN
		out_score := v_min_score;
	END IF;

	UPDATE quick_survey_submission
	   SET overall_score = out_score,
		   overall_max_score = out_max_score,
		   score_threshold_id = out_score_threshold_id
	 WHERE survey_response_id = in_response_id
	   AND submission_id = v_submission_id;
END;

PROCEDURE CalculateResponseScore(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE
)
AS
	v_temp_score			quick_survey_answer.score%TYPE;
	v_temp_max_score		quick_survey_answer.max_score%TYPE;
	v_temp_threshold_id		quick_survey_submission.score_threshold_id%TYPE;
BEGIN
	CalculateResponseScore(in_response_id, in_submission_id, v_temp_score, v_temp_max_score, v_temp_threshold_id);
END;

PROCEDURE GetScoreIndVals
(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetScoreIndVals');
	END IF;

	OPEN out_cur FOR
		-- Get number of responses
		SELECT trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, COUNT(trr.response_id) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN ind i ON i.parent_sid = sur.root_ind_sid AND i.name='response_count'
		 WHERE qsr.app_sid = security_pkg.GetApp
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get overall response score
		SELECT trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qss.overall_score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN ind i ON i.parent_sid = sur.root_ind_sid AND i.name='score'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND qss.overall_max_score IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get overall response max score
		SELECT trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qss.overall_max_score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN ind i ON i.parent_sid = sur.root_ind_sid AND i.name='max_score'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND qss.overall_max_score IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get overall score threshold (it uses MAX threshold index but there should only be one)
		SELECT trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, MAX(st.measure_list_index) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN score_threshold st ON qss.score_threshold_id = st.score_threshold_id
		  JOIN ind i ON i.parent_sid = sur.root_ind_sid AND i.name='score_threshold'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND st.measure_list_index IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get all option score counts
		SELECT /*+ALL_ROWS*/ trr.region_sid, qo.maps_to_ind_sid ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, COUNT(trr.response_id) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND qss.survey_version = q.survey_version
		  JOIN qs_question_option qo ON q.question_id = qo.question_id AND qo.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qss.survey_response_id
		   AND qsa.question_option_id = qo.question_option_id AND qsa.question_id = qo.question_id
		   AND qsa.submission_id = qss.submission_id
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND qo.maps_to_ind_sid IS NOT NULL
		   AND q.question_type IN ('radio', 'radiorow')
		 GROUP BY trr.region_sid, qo.maps_to_ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get all option max scores
		SELECT /*+ALL_ROWS*/ trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qsa.max_score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qss.survey_response_id
		   AND qsa.submission_id = qss.submission_id AND qsa.question_id = q.question_id
		  JOIN ind i ON i.parent_sid = q.maps_to_ind_sid AND i.name='max_score'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND q.question_type IN ('radio', 'radiorow', 'custom')
		   AND qsa.max_score IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Question total score
		SELECT /*+ALL_ROWS*/ trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qsa.score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.question_id = q.question_id AND qsa.survey_response_id = qss.survey_response_id
		   AND qsa.submission_id = qss.submission_id
		  JOIN ind i ON q.maps_to_ind_sid = i.ind_sid
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND q.question_type IN ('radio', 'radiorow', 'checkboxgroup', 'matrix', 'custom')
		   AND qsa.max_score IS NOT NULL
		   AND i.ind_type = csr_data_pkg.IND_TYPE_AGGREGATE -- some combinations may have calculations for this instead
		   AND i.measure_sid IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Section calculated score
		SELECT /*+ALL_ROWS*/ trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qsa.score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.question_id = q.question_id AND qsa.survey_response_id = qss.survey_response_id
		   AND qsa.submission_id = qss.submission_id
		  JOIN ind i ON i.parent_sid = q.maps_to_ind_sid AND i.name='score'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND q.question_type IN ('section', 'matrix', 'checkboxgroup')
		   AND qsa.max_score IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get all section max scores
		SELECT /*+ALL_ROWS*/ trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(qsa.max_score) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.question_id = q.question_id AND qsa.survey_response_id = qss.survey_response_id
		   AND qsa.submission_id = qss.submission_id
		  JOIN ind i ON q.maps_to_ind_sid = i.parent_sid AND i.name = 'max_score'
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND q.question_type IN ('section', 'matrix', 'checkboxgroup')
		   AND qsa.max_score IS NOT NULL
		 GROUP BY trr.region_sid, i.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- Get all section aggregated scores (gets the count broken down by score of all selected options beneath a section)
		-- (I have a horrid feeling that this could get really slow) (MDW: yep, certainly did).
		-- To improve performance, these indicators could be removed as the score can now be calculated by
		-- the quick_survey_answer.score and .max_score - but for formal question sets it can still be useful
		-- to show score counts aggregated to sections for a single response e.g. [2 bad][ 5 average ][   10    good   ]
		SELECT /*+ALL_ROWS*/ trr.region_sid, ci.ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, COUNT(trr.response_id) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN (
			SELECT /*+ALL_ROWS*/ sec.root_question_id section_question_id, secqo.question_id option_question_id, secqo.question_option_id, secqo.survey_version
			  FROM (SELECT CONNECT_BY_ROOT sec.question_id root_question_id, sec.question_id, sec.survey_version
					  FROM csr.quick_survey_question sec
						   START WITH sec.question_id IN (
							SELECT question_id
							  FROM csr.quick_survey_question
							 WHERE question_type IN ('section', 'matrix')
							   --AND survey_sid = in_survey_sid -- TODO JOIN csr.to survey tbl from agg_ind tbl
						  )
						   CONNECT BY PRIOR sec.question_id = sec.parent_id AND PRIOR sec.survey_version = sec.survey_version) sec
			  LEFT JOIN csr.qs_question_option secqo ON secqo.question_id = sec.question_id AND secqo.survey_version = sec.survey_version
			) dqo ON q.question_id = dqo.section_question_id AND q.survey_version = dqo.survey_version
		  JOIN qs_question_option qo ON dqo.question_option_id = qo.question_option_id AND dqo.option_question_id = qo.question_id AND dqo.survey_version = qo.survey_version
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qss.survey_response_id AND qsa.question_option_id = qo.question_option_id
		   AND qsa.submission_id = qss.submission_id
		  JOIN ind ci ON q.maps_to_ind_sid = ci.parent_sid AND ci.name = 'score'||qo.score
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND qo.score IS NOT NULL
		   AND q.question_type IN ('section', 'matrix')
		   AND ci.name LIKE 'score%'
		 GROUP BY trr.region_sid, ci.ind_sid, trr.period_start_dtm, trr.period_end_dtm

		UNION ALL

		-- get score_threshold scores
		SELECT /*+ALL_ROWS*/ trr.region_sid, qsst.maps_to_ind_sid ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, 1 val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON qss.survey_response_id = trr.response_id AND qss.submission_id = trr.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey_score_threshold qsst ON qsst.survey_sid = qsr.survey_sid AND qsst.score_threshold_id = qss.score_threshold_id
		 WHERE qsst.maps_to_ind_sid IS NOT NULL

		UNION ALL

		-- Get all number fields too
		-- TODO: This assumes we always add 2 numbers if they map to the same region/ind/period
		--       but hopefully this shouldn't happen
		SELECT /*+ALL_ROWS*/ trr.region_sid, q.maps_to_ind_sid ind_sid, trr.period_start_dtm, trr.period_end_dtm,
			   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, SUM(
					CASE WHEN qsa.measure_conversion_id IS NOT NULL THEN
						-- take conversion factors into account
						measure_pkg.UNSEC_GetBaseValue(qsa.val_number, measure_conversion_id, trr.period_start_dtm)
					ELSE val_number END
				) val_number, null error_code
		  FROM temp_response_region trr
		  JOIN quick_survey_submission qss ON trr.response_id = qss.survey_response_id AND trr.submission_id = qss.submission_id
		  JOIN quick_survey_response qsr ON qss.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey sur ON qsr.survey_sid = sur.survey_sid
		  JOIN quick_survey_question q ON sur.survey_sid = q.survey_sid AND q.survey_version = 0
		  JOIN quick_survey_answer qsa ON qsa.survey_response_id = qss.survey_response_id
		   AND qsa.submission_id = qss.submission_id AND qsa.question_id = q.question_id
		 WHERE qss.app_sid = security_pkg.GetApp
		   AND q.maps_to_ind_sid IS NOT NULL
		   AND q.question_type IN ('number','slider','checkbox')
		 GROUP BY trr.region_sid, q.maps_to_ind_sid, trr.period_start_dtm, trr.period_end_dtm

		 -- scrag must get all vals for the same region/ind together
		 ORDER BY ind_sid, region_sid, period_start_dtm
		;
END;

PROCEDURE GetAuditScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetAuditScoreIndVals');
	END IF;

	DELETE FROM temp_response_region; -- Just in case

	INSERT INTO temp_response_region(response_id, region_sid, submission_id, period_start_dtm, period_end_dtm)
	SELECT survey_response_id, region_sid, submission_id, period_start_dtm, period_end_dtm
	  FROM (
		SELECT qss.survey_response_id, qss.region_sid, qss.submission_id, qss.audit_month period_start_dtm,
			   LEAD(qss.audit_month, 1, ADD_MONTHS(qss.audit_month, NVL(ac.reportable_for_months, NVL(qss.validity_months, 12))))
			   OVER(PARTITION BY qss.survey_sid, qss.region_sid ORDER BY qss.audit_month ASC) period_end_dtm
		  FROM ( --the latest submission for the most recent audit in this month for this region and for this survey_sid
			SELECT qsr.app_sid, qsr.survey_response_id, qsr.last_submission_id submission_id, TRUNC(ia.audit_dtm, 'MONTH') audit_month,
				   ROW_NUMBER() OVER (PARTITION BY qsr.survey_sid, ia.region_sid, TRUNC(audit_dtm, 'MONTH') ORDER BY audit_dtm DESC) rn,
				   ia.region_sid, ia.internal_audit_type_id, ia.audit_closure_type_id, iat.validity_months, ia.survey_sid
			  FROM quick_survey_response qsr
			  JOIN internal_audit ia ON ia.app_sid = qsr.app_sid AND ia.survey_response_id = qsr.survey_response_id
			  JOIN internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
			 WHERE last_submission_id IS NOT NULL
		   	   AND ia.internal_audit_sid NOT IN (SELECT trash_sid FROM trash)
			   AND hidden = 0
			) qss
		  JOIN quick_survey sur ON qss.app_sid = sur.app_sid AND qss.survey_sid = sur.survey_sid
		  LEFT JOIN audit_type_closure_type ac ON qss.audit_closure_type_id = ac.audit_closure_type_id AND qss.internal_audit_type_id = ac.internal_audit_type_id AND qss.app_sid = ac.app_sid
		 WHERE sur.aggregate_ind_group_id = in_aggregate_ind_group_id
		   AND qss.rn = 1
		)
	 WHERE period_start_dtm < in_end_dtm
	   AND period_end_dtm > in_start_dtm;

	GetScoreIndVals(out_cur);
END;

PROCEDURE GetSupplierScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetSupplierScoreIndVals');
	END IF;

	DELETE FROM temp_response_region; -- Just in case

	INSERT INTO temp_response_region(response_id, region_sid, submission_id, period_start_dtm, period_end_dtm)
	SELECT survey_response_id, region_sid, submission_id, period_start_dtm, period_end_dtm
	  FROM (
		SELECT ssr.survey_response_id, sup.region_sid, qss.submission_id, qss.submitted_month period_start_dtm,
			   LEAD(qss.submitted_month, 1, ADD_MONTHS(qss.submitted_month, sur.submission_validity_months))
			   OVER(PARTITION BY qss.survey_response_id ORDER BY qss.submitted_month ASC) period_end_dtm
		  FROM supplier sup
		  JOIN supplier_survey_response ssr ON sup.company_sid = ssr.supplier_sid
		  JOIN (
			SELECT survey_response_id, submission_id, TRUNC(submitted_dtm, 'MONTH') submitted_month,
				   ROW_NUMBER() OVER (PARTITION BY survey_response_id, TRUNC(submitted_dtm, 'MONTH') ORDER BY submitted_dtm DESC) rn
			  FROM quick_survey_submission
			 WHERE submitted_dtm IS NOT NULL
			) qss ON ssr.survey_response_id = qss.survey_response_id AND qss.rn = 1
		  JOIN quick_survey sur ON ssr.survey_sid = sur.survey_sid
		  JOIN chain.customer_options co ON sup.app_sid = co.app_sid
		  JOIN chain.v$questionnaire_share qsh ON sup.company_sid = qsh.qnr_owner_company_sid
				AND co.top_company_sid = qsh.share_with_company_sid
				AND sur.survey_sid = qsh.questionnaire_type_id
				AND (qsh.component_id IS NULL AND ssr.component_id IS NULL OR qsh.component_id = ssr.component_id)
		  JOIN (
			SELECT app_sid, questionnaire_share_id, MIN(share_log_entry_index) first_accepted_index
			  FROM chain.qnr_share_log_entry
			 WHERE share_status_id = 14 --chain_pkg.SHARED_DATA_ACCEPTED
			 GROUP BY app_sid, questionnaire_share_id
			) qsa ON qsh.app_sid = qsa.app_sid AND qsh.questionnaire_share_id = qsa.questionnaire_share_id
		 WHERE sup.app_sid = security_pkg.GetApp
		   AND sur.aggregate_ind_group_id = in_aggregate_ind_group_id
		)
	 WHERE period_start_dtm < in_end_dtm
	   AND period_end_dtm > in_start_dtm;

	GetScoreIndVals(out_cur);
END;

PROCEDURE GetRegionScoreIndVals
(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
) AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetRegionScoreIndVals');
	END IF;

	DELETE FROM temp_response_region; -- Just in case

	INSERT INTO temp_response_region(response_id, region_sid, submission_id, period_start_dtm, period_end_dtm)
	SELECT rsr.survey_response_id, rsr.region_sid, qsr.last_submission_id, rsr.period_start_dtm, rsr.period_end_dtm
	  FROM region_survey_response rsr
	  JOIN quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id
	  JOIN quick_survey sur ON rsr.survey_sid = sur.survey_sid
	 WHERE NOT (rsr.period_end_dtm < in_start_dtm OR rsr.period_start_dtm >= in_end_dtm)
	   AND qsr.last_submission_id IS NOT NULL
	   AND qsr.hidden = 0
	   AND sur.aggregate_ind_group_id = in_aggregate_ind_group_id;

	GetScoreIndVals(out_cur);
END;

PROCEDURE GetSurveyLangs (
	in_survey_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_survey_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading from survey');
	END IF;

	OPEN out_cur FOR
		SELECT l.lang, l.description
		  FROM quick_survey_lang qsl
		  JOIN aspen2.lang l ON qsl.lang=l.lang
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND survey_sid = in_survey_sid;
END;

PROCEDURE GetAllSurveyLangs (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No real harm in anyone pulling out all the langs?
	OPEN out_cur FOR
		SELECT DISTINCT l.lang, l.description
		  FROM quick_survey_lang qsl
		  JOIN aspen2.lang l ON qsl.lang=l.lang
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE AddSurveyLang (
	in_survey_sid				IN  security_pkg.T_SID_ID,
	in_lang						IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to survey');
	END IF;

	INSERT INTO quick_survey_lang (survey_sid, lang)
		 VALUES (in_survey_sid, in_lang);
END;

PROCEDURE DeleteSurveyLang (
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_survey_sid				IN  security_pkg.T_SID_ID,
	in_lang						IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_survey_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting from survey');
	END IF;

	DELETE FROM quick_survey_lang
		  WHERE app_sid = in_app_sid
		    AND survey_sid = in_survey_sid
			AND lang = in_lang;
END;

FUNCTION IsSubmitted (
	in_response_guid			IN	quick_survey_response.guid%TYPE
) RETURN NUMBER
AS
BEGIN
	FOR r IN (
		SELECT NULL
		  FROM dual
		 WHERE EXISTS(
			SELECT NULL
			  FROM quick_survey_response
			 WHERE last_submission_id IS NOT NULL
			   AND guid=in_response_guid
			)
	) LOOP
		RETURN 1;
	END LOOP;
	RETURN 0;
END;

PROCEDURE SetCustomQuestionType (
	in_description				IN	qs_custom_question_type.description%TYPE,
	in_js_include				IN	qs_custom_question_type.js_include%TYPE,
	in_js_class					IN	qs_custom_question_type.js_class%TYPE,
	in_cs_class					IN	qs_custom_question_type.cs_class%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run SetCustomQuestionType');
	END IF;

	BEGIN
		INSERT INTO qs_custom_question_type(custom_question_type_id, description, js_include, js_class, cs_class)
		VALUES (custom_question_type_id_seq.NEXTVAL, in_description, in_js_include, in_js_class, in_cs_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE qs_custom_question_type
			   SET description = in_description, js_include = in_js_include, cs_class = in_cs_class
			 WHERE js_class = in_js_class;
	END;
END;

FUNCTION GetScoreTypeId (
	in_lookup_key				IN	score_type.lookup_key%TYPE
) RETURN score_type.score_type_id%TYPE
AS
	v_score_type_id				score_type.score_type_id%TYPE;
BEGIN
	SELECT MIN(score_type_id)
	  INTO v_score_type_id
	  FROM score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND lookup_key = in_lookup_key;

	RETURN CASE WHEN v_score_type_id IS NULL THEN -1 ELSE v_score_type_id END;
END;

PROCEDURE GetScoreTypes(
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_score_thresh_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_score_typ_aud_typ_cur	OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No permissions to get the lists
	OPEN out_score_cur FOR
		SELECT score_type_id, label, pos, hidden, allow_manual_set,
			   lookup_key, applies_to_supplier, reportable_months,
			   format_mask, ask_for_comment, applies_to_surveys, applies_to_non_compliances,
			   min_score, max_score, start_score, normalise_to_max_score,
			   applies_to_regions, applies_to_audits, applies_to_supp_rels, applies_to_permits
		  FROM score_type
		 WHERE app_sid = security_pkg.GetApp
		 ORDER BY pos, score_type_id;

	OPEN out_score_thresh_cur FOR
		SELECT score_threshold_id, description, max_value,
			   text_colour, background_colour, bar_colour,
			   icon_image_filename, dashboard_filename, score_type_id,
			   cast(icon_image_sha1 as VARCHAR2(40)) icon_image_sha1,
			   cast(dashboard_sha1 as VARCHAR2(40)) dashboard_sha1,
			   lookup_key
		  FROM score_threshold
		 WHERE app_sid = security_pkg.GetApp
		 ORDER BY max_value;

	OPEN out_score_typ_aud_typ_cur FOR
		SELECT stat.score_type_id, stat.internal_audit_type_id
		  FROM score_type_audit_type stat
		 WHERE stat.app_sid = security_pkg.GetApp;
END;

PROCEDURE DeleteScoreType(
	in_score_type_id	IN	score_type.score_type_id%TYPE
)
AS
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	DELETE FROM score_threshold
	 WHERE score_type_id=in_score_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM score_type
	 WHERE score_type_id=in_score_type_id
	   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SaveScoreType (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_label				IN	score_type.label%TYPE,
	in_pos					IN	score_type.pos%TYPE,
	in_hidden				IN	score_type.hidden%TYPE,
	in_allow_manual_set		IN	score_type.allow_manual_set%TYPE,
	in_lookup_key			IN	score_type.lookup_key%TYPE,
	in_applies_to_supplier	IN	score_type.applies_to_supplier%TYPE,
	in_reportable_months	IN	score_type.reportable_months%TYPE,
	in_format_mask			IN	score_type.format_mask%TYPE DEFAULT '#,##0.0%',
	in_ask_for_comment		IN	score_type.ask_for_comment%TYPE DEFAULT 'none',
	in_applies_to_surveys	IN	score_type.applies_to_surveys%TYPE DEFAULT 0,
	in_applies_to_ncs		IN	score_type.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_regions	IN	score_type.applies_to_regions%TYPE DEFAULT 0,
	in_min_score			IN	score_type.min_score%TYPE DEFAULT NULL,
	in_max_score			IN	score_type.max_score%TYPE DEFAULT NULL,
	in_start_score			IN	score_type.start_score%TYPE DEFAULT 0,
	in_norm_to_max_score	IN	score_type.normalise_to_max_score%TYPE DEFAULT 0,
	in_applies_to_audits	IN	score_type.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_supp_rels	IN	score_type.applies_to_supp_rels%TYPE DEFAULT 0,
	in_applies_to_permits	IN	score_type.applies_to_permits%TYPE DEFAULT 0,
	out_score_type_id		OUT	score_type.score_type_id%TYPE
)
AS
	v_score_type_id			score_type.score_type_id%TYPE := in_score_type_id;
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	IF v_score_type_id IS NULL THEN
		INSERT INTO score_type (score_type_id, label,
				pos, hidden, allow_manual_set, lookup_key,
				applies_to_supplier, reportable_months,
				format_mask, ask_for_comment,
				applies_to_surveys, applies_to_non_compliances,
				applies_to_regions, applies_to_audits,
				min_score, max_score, start_score, 
				normalise_to_max_score, applies_to_supp_rels, applies_to_permits)
		VALUES (score_type_id_seq.nextval, in_label,
				in_pos, in_hidden, in_allow_manual_set, in_lookup_key,
				in_applies_to_supplier, in_reportable_months,
				in_format_mask, in_ask_for_comment,
				in_applies_to_surveys, in_applies_to_ncs,
				in_applies_to_regions, in_applies_to_audits,
				in_min_score, in_max_score, in_start_score, 
				in_norm_to_max_score, in_applies_to_supp_rels, in_applies_to_permits)
		RETURNING score_type_id INTO v_score_type_id;
	ELSE
		UPDATE score_type
		   SET label = in_label,
			   pos = in_pos,
			   hidden = in_hidden,
			   allow_manual_set = in_allow_manual_set,
			   lookup_key = in_lookup_key,
			   applies_to_supplier = in_applies_to_supplier,
			   reportable_months = in_reportable_months,
			   format_mask = in_format_mask,
			   ask_for_comment = in_ask_for_comment,
			   applies_to_audits = in_applies_to_audits,
			   applies_to_surveys = in_applies_to_surveys,
			   applies_to_non_compliances = in_applies_to_ncs,
			   applies_to_regions = in_applies_to_regions,
			   min_score = in_min_score,
			   max_score = in_max_score,
			   start_score = in_start_score,
			   normalise_to_max_score = in_norm_to_max_score,
			   applies_to_supp_rels = in_applies_to_supp_rels,
			   applies_to_permits = in_applies_to_permits
		 WHERE score_type_id = v_score_type_id
		   AND app_sid = security_pkg.GetApp;
	END IF;

	out_score_type_id := v_score_type_id;
END;

PROCEDURE SaveScoreType (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_label				IN	score_type.label%TYPE,
	in_pos					IN	score_type.pos%TYPE,
	in_hidden				IN	score_type.hidden%TYPE,
	in_allow_manual_set		IN	score_type.allow_manual_set%TYPE,
	in_lookup_key			IN	score_type.lookup_key%TYPE,
	in_applies_to_supplier	IN	score_type.applies_to_supplier%TYPE,
	in_reportable_months	IN	score_type.reportable_months%TYPE,
	in_format_mask			IN	score_type.format_mask%TYPE DEFAULT '#,##0.0%',
	in_ask_for_comment		IN	score_type.ask_for_comment%TYPE DEFAULT 'none',
	in_applies_to_surveys	IN	score_type.applies_to_surveys%TYPE DEFAULT 0,
	in_applies_to_ncs		IN	score_type.applies_to_non_compliances%TYPE DEFAULT 0,
	in_applies_to_regions	IN	score_type.applies_to_regions%TYPE DEFAULT 0,
	in_min_score			IN	score_type.min_score%TYPE DEFAULT NULL,
	in_max_score			IN	score_type.max_score%TYPE DEFAULT NULL,
	in_start_score			IN	score_type.start_score%TYPE DEFAULT 0,
	in_norm_to_max_score	IN	score_type.normalise_to_max_score%TYPE DEFAULT 0,
	in_applies_to_audits	IN	score_type.applies_to_audits%TYPE DEFAULT 0,
	in_applies_to_supp_rels	IN	score_type.applies_to_supp_rels%TYPE DEFAULT 0,
	in_applies_to_permits	IN	score_type.applies_to_permits%TYPE DEFAULT 0,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_score_type_id			score_type.score_type_id%TYPE := in_score_type_id;
BEGIN
	SaveScoreType(in_score_type_id, in_label, in_pos, in_hidden, in_allow_manual_set, in_lookup_key, in_applies_to_supplier, in_reportable_months, in_format_mask, in_ask_for_comment,
		in_applies_to_surveys, in_applies_to_ncs, in_applies_to_regions, in_min_score, in_max_score, in_start_score, in_norm_to_max_score, in_applies_to_audits, in_applies_to_supp_rels, 
		in_applies_to_permits, v_score_type_id);
	
	
	OPEN out_cur FOR
		SELECT score_type_id, label, pos, hidden, allow_manual_set,
			   lookup_key, applies_to_supplier, reportable_months,
			   format_mask, ask_for_comment, applies_to_surveys, applies_to_non_compliances,
			   applies_to_regions, applies_to_audits, min_score, max_score, 
			   start_score, normalise_to_max_score, applies_to_supp_rels, applies_to_permits
		  FROM score_type
		 WHERE score_type_id = v_score_type_id
		   AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SetScoreTypePositions(
	in_score_type_ids		IN	security_pkg.T_SID_IDS
)
AS
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	FOR idx IN 1 .. in_score_type_ids.count LOOP
		UPDATE score_type
		   SET pos = idx
		 WHERE score_type_id = in_score_type_ids(idx);
	END LOOP;
END;

PROCEDURE SaveScoreThreshold(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_description			IN	score_threshold.description%TYPE,
	in_max_value			IN	score_threshold.max_value%TYPE,
	in_text_colour			IN	score_threshold.text_colour%TYPE,
	in_background_colour	IN	score_threshold.background_colour%TYPE,
	in_bar_colour			IN	score_threshold.bar_colour%TYPE,
	in_score_type_id		IN	score_threshold.score_type_id%TYPE,
	in_lookup_key			IN	score_threshold.lookup_key%TYPE DEFAULT NULL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_score_threshold_id	score_threshold.score_threshold_id%TYPE := in_score_threshold_id;
	v_survey_root_sid		security_pkg.T_SID_ID;
	v_measure_sid			security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	IF in_score_threshold_id IS NULL THEN
		INSERT INTO score_threshold (score_threshold_id, description,
				max_value, text_colour, background_colour, bar_colour,
				score_type_id, lookup_key)
		VALUES (score_threshold_id_seq.NEXTVAL, in_description,
				in_max_value, in_text_colour, in_background_colour,
				in_bar_colour, in_score_type_id, in_lookup_key)
		RETURNING score_threshold_id INTO v_score_threshold_id;
	ELSE
		UPDATE score_threshold
		   SET description = in_description,
			   max_value = in_max_value,
			   text_colour = in_text_colour,
			   background_colour = in_background_colour,
			   bar_colour = in_bar_colour,
			   score_type_id = in_score_type_id,
			   lookup_key = in_lookup_key
		 WHERE score_threshold_id = in_score_threshold_id
		   AND app_sid = security_pkg.GetApp;
	END IF;

	OPEN out_cur FOR
		SELECT score_threshold_id, description, max_value, text_colour,
			   background_colour, bar_colour
		  FROM score_threshold
		 WHERE app_sid = security_pkg.GetApp
		   AND score_threshold_id = v_score_threshold_id;
END;

PROCEDURE DeleteRemovedThresholds (
	in_score_type_id		IN	score_type.score_type_id%TYPE,
	in_thresholds_to_keep	IN	security_pkg.T_SID_IDS
)
AS
	v_thresholds_to_keep	security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_thresholds_to_keep);
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	DELETE FROM score_threshold
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND score_threshold_id NOT IN (SELECT column_value FROM TABLE(v_thresholds_to_keep));
END;

PROCEDURE ChangeThresholdIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	IF in_cache_key IS NULL THEN
		UPDATE score_threshold
		   SET icon_image = NULL,
		       icon_image_filename = NULL,
		       icon_image_mime_type = NULL
		 WHERE score_threshold_id = in_score_threshold_id;
	ELSE
		-- update word doc
		UPDATE score_threshold
		   SET (icon_image, icon_image_filename, icon_image_mime_type, icon_image_sha1) = (
				SELECT object, filename, mime_type, sys.dbms_crypto.hash(object, sys.dbms_crypto.hash_sh1)
				  FROM aspen2.filecache
				 WHERE cache_key = in_cache_key
			 )
		 WHERE score_threshold_id = in_score_threshold_id;
	END IF;
END;

PROCEDURE GetThresholdIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security - it's just an icon

	OPEN out_cur FOR
		SELECT icon_image image, icon_image_filename filename, icon_image_mime_type mime_type
		  FROM score_threshold
		 WHERE app_sid = security_pkg.getApp
		   AND score_threshold_id = in_score_threshold_id
		   AND icon_image IS NOT NULL;
END;

PROCEDURE ChangeDashboardIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE
)
AS
	v_survey_root_sid		security_pkg.T_SID_ID;
BEGIN
	v_survey_root_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys');

	-- Check that user can add surveys
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_survey_root_sid, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot edit thresholds if no access to surveys');
	END IF;

	IF in_cache_key IS NULL THEN
		UPDATE score_threshold
		   SET dashboard_image = NULL,
		       dashboard_filename = NULL,
		       dashboard_mime_type = NULL
		 WHERE score_threshold_id = in_score_threshold_id;
	ELSE
		-- update word doc
		UPDATE score_threshold
		   SET (dashboard_image, dashboard_filename, dashboard_mime_type, dashboard_sha1) = (
				SELECT object, filename, mime_type, sys.dbms_crypto.hash(object, sys.dbms_crypto.hash_sh1)
				  FROM aspen2.filecache
				 WHERE cache_key = in_cache_key
			 )
		 WHERE score_threshold_id = in_score_threshold_id;
	END IF;
END;

PROCEDURE GetDashboardIcon(
	in_score_threshold_id	IN	score_threshold.score_threshold_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security - it's just an icon

	OPEN out_cur FOR
		SELECT dashboard_image image, dashboard_filename filename, dashboard_mime_type mime_type
		  FROM score_threshold
		 WHERE app_sid = security_pkg.getApp
		   AND score_threshold_id = in_score_threshold_id
		   AND dashboard_image IS NOT NULL;
END;

PROCEDURE GetWorkflowState(
	in_survey_sid			IN	security_pkg.T_SID_ID,
	in_guid					IN	quick_survey_response.guid%TYPE,
	out_state				OUT	security_pkg.T_OUTPUT_CUR,
	out_actions				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_flow_alert_class		flow.flow_alert_class%TYPE;
	v_flow_item_is_editable	NUMBER;
BEGIN
	v_response_id := CheckGuidAccess(in_guid);

	SELECT MIN(fi.flow_item_id), MIN(f.flow_alert_class)
	  INTO v_flow_item_id, v_flow_alert_class
	  FROM flow_item fi
	  JOIN flow f ON fi.flow_sid = f.flow_sid
	 WHERE fi.survey_response_id = v_response_id;

	IF v_flow_alert_class = 'campaign' THEN
		v_flow_item_is_editable := CheckResponseCapability(v_flow_item_id, security_pkg.PERMISSION_WRITE);
	ELSE -- non campaign survey WFs: not sure whether they are used, there just a few recs on live, probably bad data
		SELECT NVL(MAX(fsr.is_editable), 0)
		  INTO v_flow_item_is_editable
		  FROM flow_item fi
		  JOIN flow f ON fi.flow_sid = f.flow_sid
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  LEFT JOIN region_role_member rmr ON rsr.region_sid = rmr.region_sid AND rmr.user_sid = security_pkg.GetSid
		  LEFT JOIN flow_state_role fsr ON fsr.role_sid = rmr.role_sid AND  fs.flow_state_id = fsr.flow_state_id
		 WHERE fi.survey_response_id = v_response_id;
	END IF;

	OPEN out_state FOR
		SELECT fi.current_state_id, fs.label label, v_flow_item_is_editable is_editable,
				CASE WHEN fi.current_state_id = f.default_state_id THEN 1 ELSE 0 END is_in_default_state,
				fi.flow_item_id
		  FROM flow_item fi
		  JOIN flow f ON fi.flow_sid = f.flow_sid
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		 WHERE fi.flow_item_id = v_flow_item_id;

	OPEN out_actions FOR
		SELECT DISTINCT fst.flow_state_transition_id, fst.verb, fst.lookup_key,
				fst.ask_for_comment, fst.button_icon_path, fst.to_state_id,
				fst.mandatory_fields_message
		  FROM flow_item fi
		  JOIN flow_state_transition fst ON fst.from_state_id = fi.current_state_id
		  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  LEFT JOIN flow_state_transition_role fstr ON fstr.flow_state_transition_id = fst.flow_state_transition_id
		  LEFT JOIN flow_state_transition_inv fsti ON fsti.flow_state_transition_id = fst.flow_state_transition_id
		  LEFT JOIN region_role_member rrm 
			ON rsr.region_sid = rrm.region_sid 
		   AND fstr.role_sid = rrm.role_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN supplier s ON rsr.region_sid = s.region_sid
		  LEFT JOIN chain.v$purchaser_involvement pi 
			ON fsti.flow_involvement_type_id = pi.flow_involvement_type_id 
		   AND s.company_sid = pi.supplier_company_sid
		 WHERE fi.flow_item_id = v_flow_item_id
		   AND (fstr.role_sid = rrm.role_sid OR fsti.flow_involvement_type_id = pi.flow_involvement_type_id);
END;

FUNCTION CheckFlowTransitionPermission(
	in_flow_item	flow_item.flow_item_id%TYPE,
	in_state_id		flow_state.flow_state_id%TYPE
) RETURN BOOLEAN
AS
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM flow_item fi
	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
	  JOIN flow_state_transition fst ON fst.from_state_id = fi.current_state_id
	  LEFT JOIN flow_state_transition_role fstr ON fst.flow_state_transition_id = fstr.flow_state_transition_id
	  LEFT JOIN flow_state_transition_inv fsti ON fsti.flow_state_transition_id = fst.flow_state_transition_id
 	  LEFT JOIN region_role_member rrm ON rrm.region_sid = rsr.region_sid
	   AND rrm.user_sid = security_pkg.GetSid
	   AND rrm.role_sid = fstr.role_sid
	  LEFT JOIN supplier s ON rsr.region_sid = s.region_sid
	  LEFT JOIN chain.v$purchaser_involvement pi ON fsti.flow_involvement_type_id = pi.flow_involvement_type_id 
	   AND s.company_sid = pi.supplier_company_sid
	 WHERE fi.flow_item_id = in_flow_item
	   AND fst.to_state_id = in_state_id
	   AND (fstr.role_sid = rrm.role_sid OR fsti.flow_involvement_type_id = pi.flow_involvement_type_id);

	RETURN v_count > 0;
END;

PROCEDURE SetNextWorkflowState(
	in_guid					IN	quick_survey_response.guid%TYPE,
	in_next_state_id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_next_state_editable	OUT	NUMBER
) AS
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_response_id			quick_survey_response.survey_response_id%TYPE;
	v_flow_alert_class		flow.flow_alert_class%TYPE;
	v_perm_level			NUMBER;
BEGIN
	-- Check read permissions on survey
	v_response_id := CheckGuidAccess(in_guid);
	
	SELECT flow_item_id, flow_alert_class
	  INTO v_flow_item_id, v_flow_alert_class
	  FROM flow_item fi
	  JOIN flow f ON f.flow_sid = fi.flow_sid
	 WHERE survey_response_id = v_response_id; 

	IF NOT CheckFlowTransitionPermission(v_flow_item_id, in_next_state_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot transition to: '||in_next_state_id||' on survey response: '||v_response_id);
	END IF;

	flow_pkg.SetItemState(v_flow_item_id, in_next_state_id, in_comment_text, SYS_CONTEXT('SECURITY','SID'));

	IF v_flow_alert_class = 'campaign' THEN
		v_perm_level := GetResponseCapability(v_flow_item_id);
		IF bitand(v_perm_level, security_pkg.PERMISSION_WRITE) = security_pkg.PERMISSION_WRITE THEN
			out_next_state_editable := 1;
		ELSIF bitand(v_perm_level, security_pkg.PERMISSION_READ) = security_pkg.PERMISSION_READ THEN
			out_next_state_editable := 0;
		ELSE 
			out_next_state_editable := -1;
		END IF;
	ELSE
		out_next_state_editable := NVL(flow_pkg.GetFlowItemIsEditable(v_flow_item_id), -1);
	END IF;
END;

PROCEDURE GetMySurveys (
	in_parent_region_sid	IN	security_pkg.T_SID_ID,
	in_remove_submitted		IN	NUMBER DEFAULT MY_SURVEYS_SHOW_ALL,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_audits_sid NUMBER(10);

	v_can_create_audits		NUMBER(1) := 0;
	v_audits_table			security.T_SID_TABLE;
BEGIN
	BEGIN
		v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_audits_sid := NULL;
	END;

	IF v_audits_sid IS NOT NULL THEN
		v_audits_table := audit_pkg.GetAuditsForUserAsTable;
	END IF;

	IF v_audits_sid IS NOT NULL AND security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security.security_pkg.PERMISSION_ADD_CONTENTS) THEN
		v_can_create_audits := 1;
	END IF;

	-- no security check as we only return data relating to the logged in user
	OPEN out_cur FOR
		SELECT qs.survey_sid, MIN(qsv.label) label, 
				MAX(CASE bitwise_pkg.bitor(fsrc.permission_set, security_pkg.PERMISSION_WRITE) WHEN security_pkg.PERMISSION_WRITE THEN 1 ELSE 0 END) is_editable,
				MIN(r.region_sid) region_sid, MIN(r.description) region_description,
				MIN(wr.path) path, MIN(fs.label) as state, MIN(cu.full_name) set_by,
				MIN(cu.email) set_by_email, MIN(fsl.set_dtm) set_on_dtm, qsr.survey_response_id,
				MIN(rt.class_name) region_type_class_name, rsr.period_start_dtm,
				rsr.period_end_dtm, MIN(qss.overall_score) score, MIN(qss.overall_max_score) max_score,
				MIN(st.format_mask) score_format, MIN(str.text_colour) score_colour, MIN(str.description) score_label,
				MIN(str.score_threshold_id) score_threshold_id, qs.quick_survey_type_id,
				CASE WHEN MIN(ta.column_value) IS NULL THEN NULL ELSE MIN(ia.internal_audit_sid) END internal_audit_sid,
				CASE WHEN MIN(qs.auditing_audit_type_id) IS NULL OR MIN(ia.internal_audit_sid) IS NOT NULL OR MIN(qsr.last_submission_id) IS NULL THEN 0 ELSE v_can_create_audits END can_create_audits
		  FROM flow_item fi
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
		  JOIN quick_survey_response qsr ON fi.survey_response_id = qsr.survey_response_id
		  JOIN quick_survey qs ON qsr.survey_sid = qs.survey_sid
		  JOIN quick_survey_version qsv ON qsr.survey_sid = qsv.survey_sid AND qsr.survey_version = qsv.survey_version
		  JOIN security.web_resource wr ON wr.sid_id = qs.survey_sid
		  JOIN v$region r ON rsr.region_sid = r.region_sid
		  JOIN region_type rt ON r.region_type = rt.region_type
		  JOIN flow_state_role_capability fsrc ON fs.flow_state_id = fsrc.flow_state_id
		  LEFT JOIN region_role_member rrm ON rrm.region_sid = r.region_sid
		   AND rrm.user_sid = security_pkg.GetSid
		   AND rrm.role_sid = fsrc.role_sid 
		  LEFT JOIN supplier s ON r.region_sid = s.region_sid
		  LEFT JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id 
		   AND s.company_sid = pi.supplier_company_sid
		  LEFT JOIN (
				SELECT region_sid
				  FROM region
				 START WITH region_sid = in_parent_region_sid
			   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
			) pr ON pr.region_sid = rsr.region_sid
		  LEFT JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id AND NVL(qsr.last_submission_id, 0) = qss.submission_id AND qsr.survey_version > 0
		  LEFT JOIN score_type st ON ST.score_type_id = qs.score_type_id
		  LEFT JOIN score_threshold str ON str.score_type_id = st.score_type_id AND str.score_threshold_id = qss.score_threshold_id
		  LEFT JOIN flow_state_log fsl ON fi.last_flow_state_log_id = fsl.flow_state_log_id
		  LEFT JOIN csr_user cu ON cu.csr_user_sid = fsl.set_by_user_sid
		  LEFT JOIN internal_audit ia ON ia.comparison_response_id = qsr.survey_response_id AND ia.deleted = 0
		  LEFT JOIN (SELECT DISTINCT column_value FROM TABLE(v_audits_table)) ta ON ia.internal_audit_sid = ta.column_value
		 WHERE qsr.hidden = 0
		   AND (
				in_remove_submitted = MY_SURVEYS_SHOW_ALL OR
				(in_remove_submitted = MY_SURVEYS_SHOW_UNSUBMITTED AND qss.submitted_dtm IS NULL) OR
				(in_remove_submitted = MY_SURVEYS_SHOW_SUBMITTED AND qss.submitted_dtm IS NOT NULL)
			)
		   AND qsr.qs_campaign_sid NOT IN (SELECT trash_sid FROM trash)
		   AND (in_parent_region_sid IS NULL
		    OR pr.region_sid IS NOT NULL)
		   AND (rrm.role_sid IS NOT NULL OR pi.flow_involvement_type_id IS NOT NULL)
		   AND permission_set > 0
		 GROUP BY qs.survey_sid, qs.quick_survey_type_id, qsr.survey_response_id, rsr.period_start_dtm, rsr.period_end_dtm
		 ORDER BY rsr.period_start_dtm DESC;
END;

PROCEDURE CreateScoreThresholdMeasure (
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	out_measure_sid				OUT	security_pkg.T_SID_ID
)
AS
	v_has_thresholds			NUMBER(1);
	v_next_index				NUMBER(10);
	v_cust_field				measure.custom_field%TYPE;
	v_label						score_type.label%TYPE;
BEGIN
	SELECT NVL(MIN(1), 0)
	  INTO v_has_thresholds
	  FROM score_threshold
	 WHERE score_type_id = in_score_type_id;

	IF v_has_thresholds=0 THEN
		out_measure_sid := NULL;
		RETURN;
	END IF;

	SELECT measure_sid, label
	  INTO out_measure_sid, v_label
	  FROM score_type
	 WHERE score_type_id = in_score_type_id
	   AND app_sid = security_pkg.getApp;

	IF out_measure_sid IS NULL THEN
		measure_pkg.CreateMeasure(
			in_name						=> 'score_threshold_'||in_score_type_id,
			in_description				=> v_label,
			in_pct_ownership_applies	=> 0,
			in_custom_field				=> '',
			in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			out_measure_sid				=> out_measure_sid
		);

		UPDATE score_type
		   SET measure_sid = out_measure_sid
		 WHERE score_type_id = in_score_type_id;
	END IF;

	-- Set indexes on all thresholds that don't have any
	FOR r IN (
		SELECT *
		  FROM score_threshold
		 WHERE score_type_id = in_score_type_id
		   AND measure_list_index IS NULL
		 ORDER BY max_value
	) LOOP
		SELECT NVL(MAX(measure_list_index), 0) + 1
		  INTO v_next_index
		  FROM score_threshold
		 WHERE score_type_id = in_score_type_id;

		UPDATE score_threshold
		   SET measure_list_index = v_next_index
		 WHERE score_threshold_id = r.score_threshold_id;
	END LOOP;

	v_cust_field := '';
	FOR r IN (
		SELECT score_threshold_id, description, measure_list_index,
			   NVL(LAG(measure_list_index) OVER (ORDER BY measure_list_index), 1) prev_measure_list_index
		  FROM score_threshold
		 WHERE score_type_id = in_score_type_id
		 ORDER BY measure_list_index
	) LOOP
		-- Account for gaps caused by deleted thresholds
		FOR d IN (r.prev_measure_list_index+2)..r.measure_list_index LOOP
			v_cust_field := v_cust_field || '(deleted)' || CHR(13) || CHR(10);
		END LOOP;
		v_cust_field := v_cust_field || r.description || CHR(13) || CHR(10);
	END LOOP;

	UPDATE measure
	   SET custom_field = v_cust_field
	 WHERE measure_sid = out_measure_sid;
END;

PROCEDURE SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL
)
AS
	v_question_ids	security.security_pkg.T_SID_IDS;
BEGIN
	Internal_SynchroniseIndicators(in_survey_sid, in_score_type_id, v_question_ids);
END;

PROCEDURE SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL,
	in_question_ids 			IN  security_pkg.T_SID_IDS
)
AS
BEGIN
	Internal_SynchroniseIndicators(in_survey_sid, in_score_type_id, in_question_ids);
END;

PROCEDURE Internal_SynchroniseIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE := NULL,
	in_question_ids 			IN  security_pkg.T_SID_IDS
)
AS
	in_ind_survey_root_sid		security_pkg.T_SID_ID;
	in_ind_root_sid				security_pkg.T_SID_ID;
	v_survey_label				quick_survey_version.label%TYPE;
	tbl_primary					T_SID_AND_DESCRIPTION_TABLE;
	tbl_compare					T_SID_AND_DESCRIPTION_TABLE;
	v_ind_sid					security_pkg.T_SID_ID;
	v_out_sid					security_pkg.T_SID_ID;
	v_overall_score_sid			security_pkg.T_SID_ID;
	v_overall_max_score_sid		security_pkg.T_SID_ID;
	v_score_threshold_sid		security_pkg.T_SID_ID;
	v_score_measure_sid			security_pkg.T_SID_ID;
	v_score_cnt_measure_sid		security_pkg.T_SID_ID;
	v_surv_numb_measure_sid		security_pkg.T_SID_ID;
	v_score_list_measure_sid	security_pkg.T_SID_ID;
	v_seek_parent_sid			security_pkg.T_SID_ID;
	v_response_count_sid		security_pkg.T_SID_ID;
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_helper_proc				aggregate_ind_group.helper_proc%TYPE;
	v_score						NUMBER(1);
	v_max_score					NUMBER(1);
	v_div_xml					varchar2(4000);
	v_mul_xml					varchar2(4000);
	v_score_question_count		NUMBER(10);
	v_score_type_id				score_type.score_type_id%TYPE := in_score_type_id;
	t_question_ids 				security.T_SID_TABLE;
BEGIN
	-- TODO: Check a capability to do this - we'll revoke this on clients that have been set up differently via a customer-specific script

	IF in_question_ids.COUNT <> 0 OR (in_question_ids.COUNT = 1 AND in_question_ids(in_question_ids.FIRST) IS NOT NULL) THEN
		t_question_ids := security_pkg.SidArrayToTable(in_question_ids);

		SELECT T_SID_AND_DESCRIPTION_ROW(rownum, question_id, LTRIM(SYS_CONNECT_BY_PATH(replace(question_id,chr(1),'_'),''),''))
		  BULK COLLECT INTO tbl_primary
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND question_type IN ('section', 'radio', 'number', 'slider', 'radiorow', 'matrix', 'checkboxgroup', 'checkbox')
		   AND is_visible = 1
		   AND survey_version = 0
		START WITH parent_id IS NULL AND question_id IN (SELECT column_value FROM TABLE(t_question_ids))
		CONNECT BY PRIOR question_id = parent_id AND PRIOR survey_version = survey_version;
	ELSE
		SELECT T_SID_AND_DESCRIPTION_ROW(rownum, question_id, LTRIM(SYS_CONNECT_BY_PATH(replace(question_id,chr(1),'_'),''),''))
		  BULK COLLECT INTO tbl_primary
		  FROM quick_survey_question
		 WHERE survey_sid = in_survey_sid
		   AND question_type IN ('section', 'radio', 'number', 'slider', 'radiorow', 'matrix', 'checkboxgroup', 'checkbox')
		   AND is_visible = 1
		   AND survey_version = 0
		START WITH parent_id IS NULL
		CONNECT BY PRIOR question_id = parent_id AND PRIOR survey_version = survey_version;
	END IF;

	-- get or create a measure
	BEGIN
		SELECT measure_sid
		  INTO v_score_measure_sid
		  FROM measure
		 WHERE name = 'quick_survey_score_pct'
		   AND app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name						=> 'quick_survey_score_pct',
				in_description				=> 'Score',
				in_scale					=> 4,
				in_format_mask				=> '#,##0.0',
				in_pct_ownership_applies	=> 0,
				in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				out_measure_sid				=> v_score_measure_sid
			);
	END;

	IF in_score_type_id IS NULL THEN
		SELECT score_type_id
		  INTO v_score_type_id
		  FROM quick_survey
		 WHERE survey_sid = in_survey_sid;
	END IF;

	BEGIN
		SELECT measure_sid
		  INTO v_score_cnt_measure_sid
		  FROM measure
		 WHERE name = 'quick_survey_score'
		   AND app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name						=> 'quick_survey_score',
				in_description				=> 'Score count',
				in_pct_ownership_applies 	=> 0,
				in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				out_measure_sid				=> v_score_cnt_measure_sid
			);
	END;

	-- Create a default measure for all numbers
	BEGIN
		SELECT measure_sid
		  INTO v_surv_numb_measure_sid
		  FROM measure
		 WHERE name = 'quick_survey_number'
		   AND app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name						=> 'quick_survey_number',
				in_description				=> 'Survey number',
				in_scale					=> 4,
				in_format_mask				=> '#,##0.####',
				in_pct_ownership_applies 	=> 0,
				in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				out_measure_sid				=> v_surv_numb_measure_sid
			);
	END;

	IF v_score_type_id IS NOT NULL THEN
		CreateScoreThresholdMeasure(in_score_type_id, v_score_list_measure_sid);
		UPDATE quick_survey
		   SET score_type_id = v_score_type_id
		 WHERE survey_sid = in_survey_sid;
	END IF;

	BEGIN
		in_ind_survey_root_sid := securableobject_pkg.getSidFromPath(security_pkg.getAct, security_pkg.getApp, 'Indicators/Questionnaires');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id		=> securableobject_pkg.getSidFromPath(security_pkg.getAct, security_pkg.getApp, 'Indicators'),
				in_name					=> 'Questionnaires',
				in_description			=> 'Questionnaires',
				out_sid_id				=> in_ind_survey_root_sid
			);
	END;

	SELECT qsv.label, qs.root_ind_sid, qs.aggregate_ind_group_id,
		   CASE (qs.audience)
				WHEN 'chain' THEN 'csr.quick_survey_pkg.GetSupplierScoreIndVals'
				WHEN 'audit' THEN 'csr.quick_survey_pkg.GetAuditScoreIndVals'
				ELSE 'csr.quick_survey_pkg.GetRegionScoreIndVals' END
	  INTO v_survey_label, in_ind_root_sid, v_aggregate_ind_group_id, v_helper_proc
	  FROM quick_survey qs
	  JOIN quick_survey_version qsv ON qs.survey_sid = qsv.survey_sid
	 WHERE qs.survey_sid = in_survey_sid
	   AND qsv.survey_version = 0;

	IF in_ind_root_sid IS NULL THEN
		BEGIN
			in_ind_root_sid := securableobject_pkg.getSidFromPath(security_pkg.getAct, security_pkg.getApp, 'Indicators/Questionnaires/'||v_survey_label);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				indicator_pkg.CreateIndicator(
					in_parent_sid_id		=> in_ind_survey_root_sid,
					in_name					=> v_survey_label,
					in_description			=> v_survey_label,
					in_measure_sid			=> v_score_measure_sid,
					in_aggregate			=> 'SUM',
					out_sid_id				=> in_ind_root_sid
				);
		END;

		UPDATE quick_survey
		   SET root_ind_sid = in_ind_root_sid
		 WHERE survey_sid = in_survey_sid;
	END IF;

	IF v_aggregate_ind_group_id IS NULL THEN
		INSERT INTO aggregate_ind_group (aggregate_ind_group_id, helper_proc, name, label, run_daily)
		VALUES (aggregate_ind_group_id_seq.NEXTVAL, v_helper_proc, 'QuickSurveyScores.'||in_survey_sid, 'QuickSurveyScores.'||in_survey_sid, 0)
		RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;

		UPDATE quick_survey
		   SET aggregate_ind_group_id = v_aggregate_ind_group_id
		 WHERE survey_sid = in_survey_sid;
	ELSE
		UPDATE aggregate_ind_group
		   SET helper_proc = v_helper_proc,
				name = 'QuickSurveyScores.'||in_survey_sid
		 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id;
	END IF;

	-- delete from indicators when no longer in primary survey set
	FOR r IN (
		SELECT i.ind_sid, i.name, i.ind_type
		  FROM ind i
		  JOIN (
			SELECT ind_sid, LEVEL lev
			  FROM ind
			 START WITH parent_sid = in_ind_root_sid
			CONNECT BY PRIOR ind_sid = parent_sid
		  ) x ON i.ind_sid = x.ind_sid
		  LEFT JOIN (
			SELECT maps_to_ind_sid
			  FROM quick_survey_question
			 WHERE question_id in (
				SELECT sid_id FROM TABLE(tbl_primary)
				)
			   AND survey_version = 0
			 UNION
			 SELECT maps_to_ind_sid
			   FROM qs_question_option
			  WHERE question_id in (
				SELECT sid_id FROM TABLE(tbl_primary)
			  )
			   AND survey_version = 0
			) rem on i.ind_sid = rem.maps_to_ind_sid
		 WHERE rem.maps_to_ind_sid IS NULL
		 ORDER BY x.lev DESC
	)
	LOOP
		IF r.name NOT LIKE 'score%' AND r.name NOT IN ('response_count', 'score_threshold', 'max_score') THEN
			-- TODO: need a better check so that we don't delete scores on sections
			--       but do delete things that aren't needed anymore
			--       Ideally we'd have map_to_ind_sid values for all sids involved
			--       and remove joins based on name
			--dbms_output.put_line('deleting '||r.ind_sid);

			DELETE FROM aggregate_ind_group_member
			 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id
			   AND ind_sid = r.ind_sid;

			DELETE FROM aggregate_ind_group_member
			 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id
			   AND ind_sid IN (
				SELECT ind_sid FROM ind where parent_sid = r.ind_sid AND name like 'score%'
			 );

			-- XXX: consider using trash instead?
			-- XXX: consider how to map indicators for published / unpublished versions?
			securableobject_pkg.DeleteSO(security_pkg.getACT, r.ind_sid);
		END IF;
	END LOOP;

	-- get/create an indicator to take the number of responses
	BEGIN
		SELECT ind_sid
		  INTO v_response_count_sid
		  FROM ind
		 WHERE parent_sid = in_ind_root_sid
		   AND name = 'response_count';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--dbms_output.put_line('creating Total responses');
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> in_ind_root_sid,
				in_name 				=> 'response_count',
				in_description 			=> 'Total responses',
				in_active	 			=> 1,
				in_measure_sid			=> v_score_cnt_measure_sid,
				in_aggregate			=> 'SUM',
				out_sid_id				=> v_response_count_sid
			);

			UPDATE ind
			   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE, is_system_managed = 1
			 WHERE ind_sid = v_response_count_sid;

			INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
			VALUES (v_aggregate_ind_group_id, v_response_count_sid);
	END;

	-- count the number of questions that have a score
	SELECT count(*)
	  INTO v_score_question_count
	  FROM quick_survey_question qs
	  LEFT JOIN qs_question_option qso ON qs.question_id = qso.question_id AND qso.is_visible=1 AND qs.survey_version = qso.survey_version
	 WHERE qs.survey_sid = in_survey_sid
	   AND qs.is_visible=1
	   AND qs.score IS NOT NULL OR qso.score IS NOT NULL
	   AND qs.survey_version = 0;

	IF v_score_question_count>0 THEN
		-- get/create an indicator to take the overall score of responses
		BEGIN
			SELECT ind_sid
			  INTO v_overall_score_sid
			  FROM ind
			 WHERE parent_sid = in_ind_root_sid
			   AND name = 'score';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				--dbms_output.put_line('creating Overall score');
				indicator_pkg.CreateIndicator(
					in_parent_sid_id 		=> in_ind_root_sid,
					in_name 				=> 'score',
					in_description 			=> 'Overall score',
					in_active	 			=> 1,
					in_measure_sid			=> v_score_measure_sid,
					in_aggregate			=> 'SUM',
					out_sid_id				=> v_overall_score_sid
				);

				UPDATE ind
				   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE, is_system_managed = 1
				 WHERE ind_sid = v_overall_score_sid;

				INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
				VALUES (v_aggregate_ind_group_id, v_overall_score_sid);
		END;

		-- get/create an indicator to take the overall max score of responses
		BEGIN
			SELECT ind_sid
			  INTO v_overall_max_score_sid
			  FROM ind
			 WHERE parent_sid = in_ind_root_sid
			   AND name = 'max_score';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				--dbms_output.put_line('creating Overall max score');
				indicator_pkg.CreateIndicator(
					in_parent_sid_id 		=> in_ind_root_sid,
					in_name 				=> 'max_score',
					in_description 			=> 'Overall maximum score',
					in_active	 			=> 1,
					in_measure_sid			=> v_score_measure_sid,
					in_aggregate			=> 'SUM',
					in_normalize			=> 1,
					out_sid_id				=> v_overall_max_score_sid
				);

				UPDATE ind
				   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE, is_system_managed = 1
				 WHERE ind_sid = v_overall_max_score_sid;

				INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
				VALUES (v_aggregate_ind_group_id, v_overall_max_score_sid);
		END;

		-- Set overall score calc
		-- TODO: 13p fix needed
		calc_pkg.SetCalcXMLAndDeps(
			in_act_id => security_pkg.GetAct,
			in_calc_ind_sid => in_ind_root_sid,
			in_calc_xml => '<divide><left><path sid="'||v_overall_score_sid||'" description="Overall score" /></left><right><path sid="'||v_overall_max_score_sid||'" description="Overall maximum score" /></right></divide>',
			in_is_stored => 0,
			in_period_set_id => 1,
			in_period_interval_id => 1,
			in_do_temporal_aggregation => 0,
			in_calc_description => 'System calculation'
		);
	END IF;

	-- get/create an indicator to take the score threshold (if this survey has scoring)
	IF v_score_type_id IS NOT NULL AND v_score_list_measure_sid IS NOT NULL AND v_score_question_count>0 THEN
		BEGIN
			SELECT ind_sid
			  INTO v_score_threshold_sid
			  FROM ind
			 WHERE parent_sid = in_ind_root_sid
			   AND name = 'score_threshold';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				--dbms_output.put_line('creating Score threshold');
				indicator_pkg.CreateIndicator(
					in_parent_sid_id 		=> in_ind_root_sid,
					in_name 				=> 'score_threshold',
					in_description 			=> 'Score threshold',
					in_active	 			=> 1,
					in_measure_sid			=> v_score_list_measure_sid,
					in_aggregate			=> 'NONE',
					out_sid_id				=> v_score_threshold_sid
				);

				UPDATE ind
				   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE, is_system_managed = 1
				 WHERE ind_sid = v_score_threshold_sid;

				INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
				VALUES (v_aggregate_ind_group_id, v_score_threshold_sid);
		END;
	END IF;

	-- Pulled out from the next bit to avoid 'operator not implemented' on live
	SELECT T_SID_AND_DESCRIPTION_ROW(rownum, question_id, LTRIM(SYS_CONNECT_BY_PATH(replace(question_id,chr(1),'_'),''),''))
	  BULK COLLECT INTO tbl_compare
	  FROM ind i
	  JOIN quick_survey_question qsq
		ON i.ind_sid = qsq.maps_to_ind_sid
	   AND qsq.survey_sid = in_survey_sid
	   AND qsq.survey_version = 0
	 START WITH i.parent_sid = in_ind_root_sid
	CONNECT BY PRIOR i.ind_sid = i.parent_sid;

	-- create stuff that's in the survey question set but not the ind tree
	-- XXX getting 'operator not implemented' on live with the MINUS bla bla....
	FOR r IN (
		SELECT x.question_id, x.path, qsq.label, qsq.question_type
		  FROM (
			SELECT sid_id question_id, description path
			  FROM TABLE(tbl_primary)
			  MINUS
			SELECT sid_id question_id, description path
			  FROM TABLE(tbl_compare)
		  )x
		  JOIN quick_survey_question qsq ON x.question_id = qsq.question_id
		  JOIN TABLE(tbl_primary) tp ON x.question_id = tp.sid_id
		 WHERE qsq.survey_version = 0
		ORDER BY tp.pos
	)
	LOOP
		-- process in order (tp.pos)

		-- find what the parent question_id maps to
		BEGIN
			SELECT qsqp.maps_to_ind_sid
			  INTO v_seek_parent_sid
			  FROM quick_survey_question qsq
			  JOIN quick_survey_question qsqp ON qsq.parent_id = qsqp.question_id AND qsq.survey_version = qsqp.survey_version
			 WHERE qsq.question_id = r.question_id
			   AND qsq.survey_version = 0;

			IF v_seek_parent_sid IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'assertion failure for question_id = ' || r.question_id || '!');
			END IF;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- assume root question?
				v_seek_parent_sid := in_ind_root_sid;
		END;

		-- create indicator for section / question
		--dbms_output.put_line('creating '||r.label||' ('||r.question_id||')');
		indicator_pkg.CreateIndicator(
			in_parent_sid_id 		=> v_seek_parent_sid,
			in_name 				=> SUBSTR(REPLACE(r.label, '/', '\'),1,230)||'.'||r.question_id, --'
			in_description 			=> SUBSTR(r.label,1,1000),
			in_active	 			=> 1,
			in_measure_sid			=> CASE r.question_type
										WHEN 'number' THEN v_surv_numb_measure_sid
										WHEN 'slider' THEN v_surv_numb_measure_sid
										WHEN 'section' THEN v_score_measure_sid
										WHEN 'matrix' THEN v_score_measure_sid
										WHEN 'custom' THEN v_score_measure_sid
										WHEN 'checkbox' THEN v_score_cnt_measure_sid
										WHEN 'checkboxgroup' THEN v_score_measure_sid
										ELSE NULL END,
			in_aggregate			=> 'SUM',
			out_sid_id				=> v_seek_parent_sid
		);
		
		UPDATE question
		   SET maps_to_ind_sid = v_seek_parent_sid,
				measure_sid = CASE r.question_type
								WHEN 'number' THEN v_surv_numb_measure_sid
								WHEN 'slider' THEN v_surv_numb_measure_sid
								WHEN 'section' THEN v_score_measure_sid
								WHEN 'matrix' THEN v_score_measure_sid
								WHEN 'custom' THEN v_score_measure_sid
								WHEN 'checkbox' THEN v_score_cnt_measure_sid
								WHEN 'checkboxgroup' THEN v_score_measure_sid
								ELSE NULL END
		 WHERE question_id = r.question_id
		   AND owned_by_survey_sid = in_survey_sid;

		UPDATE quick_survey_question
		   SET maps_to_ind_sid = v_seek_parent_sid,
				measure_sid = CASE r.question_type
								WHEN 'number' THEN v_surv_numb_measure_sid
								WHEN 'slider' THEN v_surv_numb_measure_sid
								WHEN 'section' THEN v_score_measure_sid
								WHEN 'matrix' THEN v_score_measure_sid
								WHEN 'custom' THEN v_score_measure_sid
								WHEN 'checkbox' THEN v_score_cnt_measure_sid
								WHEN 'checkboxgroup' THEN v_score_measure_sid
								ELSE NULL END
		 WHERE question_id = r.question_id
		   AND survey_version = 0;

		-- create indicator to store the maximum possible score (so score can't be marked down
		-- for hidden or not applicable questions)
		IF r.question_type IN ('section', 'matrix', 'checkboxgroup') THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> v_seek_parent_sid,
				in_name 				=> 'max_score',
				in_description 			=> 'Maximum score',
				in_active	 			=> 1,
				in_measure_sid			=> v_score_cnt_measure_sid,
				in_aggregate			=> 'SUM',
				in_normalize			=> 1,
				out_sid_id				=> v_out_sid
			);
		END IF;

		IF r.question_type IN ('section', 'matrix', 'checkboxgroup') THEN
			-- create indicator to store the calculated score (this is divided by
			-- max_score up the region tree)
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> v_seek_parent_sid,
				in_name 				=> 'score',
				in_description 			=> 'Score',
				in_active	 			=> 1,
				in_measure_sid			=> v_score_cnt_measure_sid,
				in_aggregate			=> 'SUM',
				out_sid_id				=> v_out_sid
			);
		END IF;
	END LOOP;

	-- Now the options
	FOR r IN (
		SELECT q.maps_to_ind_sid, q.question_id, qo.score, qo.question_option_id, qo.label,
			   q.label question_label
		  FROM TABLE(tbl_primary) t
		  JOIN quick_survey_question q ON t.sid_id = q.question_id
		  JOIN qs_question_option qo ON q.question_id = qo.question_id AND q.survey_version = qo.survey_version
		  JOIN ind pi ON pi.ind_sid = q.maps_to_ind_sid
		  LEFT JOIN ind ci ON (ci.parent_sid = pi.ind_sid AND ci.name = 'qs_option'||qo.question_option_id) OR ci.ind_sid = qo.maps_to_ind_sid
		 WHERE q.maps_to_ind_sid IS NOT NULL
		   AND ci.ind_sid IS NULL
		   AND q.survey_sid = in_survey_sid
		   AND q.is_visible=1
		   AND qo.is_visible=1
		   AND q.question_type IN ('radiorow', 'radio')
		   AND q.survey_version = 0
	)
	LOOP
		-- create indicator for score counts
		--dbms_output.put_line('creating Score '||r.score||' - '||r.label||' ('||r.question_option_id||')');
		indicator_pkg.CreateIndicator(
			in_parent_sid_id 		=> r.maps_to_ind_sid,
			in_name 				=> 'qs_option'||r.question_option_id,
			in_description 			=> r.label,
			in_active	 			=> 1,
			in_measure_sid			=> v_score_cnt_measure_sid,
			in_aggregate			=> 'SUM',
			out_sid_id				=> v_out_sid
		);

		UPDATE qs_question_option
		   SET maps_to_ind_sid = v_out_sid
		 WHERE question_id = r.question_id
		   AND question_option_id = r.question_option_id
		   AND survey_version = 0;
	END LOOP;

	-- Now the section scores
	-- Commented out as these run really slowly in quick_survey_pkg.GetScoreIndVals
	-- It's only worth enabling if a client has asked for it
	-- Arcelor have it. It makes sense if the question options are consistant throughout
	-- e.g. Good, OK, Bad - and gives counts per section, e.g. section 1 has 3 good, 7 ok, 2 bad.
	-- This might be better to do with CR360 calculations, or we should invest on improving
	-- the speed of the relevant section of quick_survey_pkg.GetScoreIndVals
	/*FOR r IN (
		SELECT q.maps_to_ind_sid, q.question_id, dqo.score, q.label, dqo.label option_label
		  FROM (
			SELECT DISTINCT CONNECT_BY_ROOT q.question_id section_question_id, qo.score, qo.label
			  FROM quick_survey_question q
			  LEFT JOIN qs_question_option qo ON qo.question_id = q.question_id
			  START WITH q.question_id IN (
				SELECT question_id
				  FROM quick_survey_question qsq
				 WHERE qsq.question_type = 'section'
				   AND qsq.survey_sid = in_survey_sid
			  )
			  CONNECT BY PRIOR q.question_id = q.parent_id
			) dqo
		  JOIN quick_survey_question q ON dqo.section_question_id = q.question_id
		  LEFT JOIN ind ci ON ci.parent_sid = q.maps_to_ind_sid AND ci.name = 'score'||dqo.score
		 WHERE q.maps_to_ind_sid IS NOT NULL
		   AND ci.ind_sid IS NULL
		   AND dqo.score IS NOT NULL
		   AND q.question_type = 'section'
	)
	LOOP
		-- create indicator for score counts
		--dbms_output.put_line('creating Section Score '||r.score||' - '||r.label);
		indicator_pkg.CreateIndicator(
			in_parent_sid_id 		=> r.maps_to_ind_sid,
			in_name 				=> 'score'||r.score,
			in_description 			=> r.option_label || ' (section total)',--CASE (r.score) WHEN 0 THEN 'None' WHEN 1 THEN 'Minimal / Low' WHEN 2 THEN 'Average / Reactive' WHEN 3 THEN 'Good / Proactive' WHEN 4 THEN 'Very Advanced' END,
			in_active	 			=> 1,
			in_measure_sid			=> v_score_cnt_measure_sid,
			in_aggregate			=> 'SUM',
			out_sid_id				=> v_out_sid
		);

		--TODO mark sections somehow so that we don't delete their mapped indicators on next run

	END LOOP;*/

	IF v_score_type_id IS NOT NULL AND v_score_question_count > 0 THEN
		FOR r IN (
			SELECT st.*, s.root_ind_sid, s.survey_sid
			  FROM score_threshold st
			  JOIN quick_survey s ON s.survey_sid = in_survey_sid
			  LEFT JOIN quick_survey_score_threshold qsst
				   ON st.score_threshold_id = qsst.score_threshold_id
				   AND s.survey_sid = qsst.survey_sid
			 WHERE qsst.maps_to_ind_sid IS NULL
			   AND st.score_type_id = v_score_type_id
		) LOOP
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> r.root_ind_sid,
				in_name 				=> SUBSTR(LOWER(r.description),1,239)||'.'||r.score_threshold_id,
				in_description 			=> r.description,
				in_active	 			=> 1,
				in_measure_sid			=> v_score_cnt_measure_sid,
				in_aggregate			=> 'SUM',
				out_sid_id				=> v_out_sid
			);

			UPDATE ind
			   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE,
				   is_system_managed = 1
			 WHERE ind_sid = v_out_sid;

			BEGIN
				INSERT INTO quick_survey_score_threshold (survey_sid, score_threshold_id, maps_to_ind_sid)
				VALUES (r.survey_sid, r.score_threshold_id, v_out_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE quick_survey_score_threshold
					   SET maps_to_ind_sid = v_out_sid
					 WHERE survey_sid = r.survey_sid
					   AND score_threshold_id = r.score_threshold_id;
			END;

			INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
			VALUES (v_aggregate_ind_group_id, v_out_sid);
		END LOOP;
	END IF;

	-- Make calcs for overall score as a %age
	FOR r IN (
		SELECT q.question_id, q.maps_to_ind_sid, max_score.ind_sid max_score_ind_sid, score.ind_sid score_ind_sid
		  FROM quick_survey_question q
		  JOIN ind max_score ON max_score.parent_sid = q.maps_to_ind_sid AND max_score.name='max_score'
		  JOIN ind score ON score.parent_sid = q.maps_to_ind_sid AND score.name='score'
		 WHERE q.survey_sid = in_survey_sid
		   AND q.question_type IN ('section', 'matrix', 'checkboxgroup')
		   AND q.maps_to_ind_sid IS NOT NULL
		   AND score.ind_type != csr_data_pkg.IND_TYPE_CALC
	) LOOP
		v_div_xml := NULL;
		v_mul_xml := NULL;

		-- TODO: 13p fix needed
		calc_pkg.SetCalcXMLAndDeps(
			in_act_id => security_pkg.GetAct,
			in_calc_ind_sid => r.maps_to_ind_sid,
			in_calc_xml => '<divide><left><path sid="'||r.score_ind_sid||'" description="Score" /></left><right><path sid="'||r.max_score_ind_sid||'" description="Maximum score" /></right></divide>',
			in_is_stored => 0,
			in_period_set_id => 1,
			in_period_interval_id => 1,
			in_do_temporal_aggregation => 0,
			in_calc_description => 'System calculation'
		);
	END LOOP;

	DELETE FROM aggregate_ind_group_member
	 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id
	   AND ind_sid NOT IN (
		SELECT ind_sid
		  FROM ind
		 START WITH parent_sid = in_ind_root_sid
		CONNECT BY PRIOR ind_sid = parent_sid
	);

	UPDATE ind
	   SET ind_type = csr_data_pkg.IND_TYPE_AGGREGATE, is_system_managed = 1
	 WHERE ind_type != csr_data_pkg.IND_TYPE_AGGREGATE
	   AND measure_sid IS NOT NULL
	   AND ind_sid IN (
		SELECT ind_sid
		  FROM ind
		 START WITH parent_sid = in_ind_root_sid
		CONNECT BY PRIOR ind_sid = parent_sid
		 MINUS
		SELECT qsq.maps_to_ind_sid
		  FROM quick_survey_question qsq
		 WHERE qsq.question_type IN ('section', 'radio', 'matrix', 'checkboxgroup')
		   AND qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = 0
		);

	INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
	SELECT v_aggregate_ind_group_id, ind_sid
	  FROM (
		SELECT ind_sid, ind_type
		  FROM ind
		 START WITH parent_sid = in_ind_root_sid
		CONNECT BY PRIOR ind_sid = parent_sid
	  )
	 WHERE ind_type = csr_data_pkg.IND_TYPE_AGGREGATE
	 MINUS
	SELECT aggregate_ind_group_id, ind_sid
	  FROM aggregate_ind_group_member
	 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id;

	UPDATE quick_survey
	   SET last_modified_dtm = SYSDATE
	 WHERE survey_sid = in_survey_sid;

	calc_pkg.AddJobsForAggregateIndGroup(v_aggregate_ind_group_id);
END;

PROCEDURE FixUserMappedIndicators(
	in_survey_sid				IN	security_pkg.T_SID_ID
)
AS
	v_aggregate_ind_group_id	aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_helper_proc				aggregate_ind_group.helper_proc%TYPE;
BEGIN
	SELECT aggregate_ind_group_id,
		   CASE (audience)
				WHEN 'chain' THEN 'csr.quick_survey_pkg.GetSupplierScoreIndVals'
				WHEN 'audit' THEN 'csr.quick_survey_pkg.GetAuditScoreIndVals'
				ELSE 'csr.quick_survey_pkg.GetRegionScoreIndVals' END
	  INTO v_aggregate_ind_group_id, v_helper_proc
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;

	IF v_aggregate_ind_group_id IS NULL THEN
		INSERT INTO aggregate_ind_group (aggregate_ind_group_id, helper_proc, name)
		VALUES (aggregate_ind_group_id_seq.NEXTVAL, v_helper_proc, 'QuickSurveyScores.'||in_survey_sid)
		RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;

		UPDATE quick_survey
		   SET aggregate_ind_group_id = v_aggregate_ind_group_id
		 WHERE survey_sid = in_survey_sid;
	ELSE
		UPDATE aggregate_ind_group
		   SET helper_proc = v_helper_proc,
				name = 'QuickSurveyScores.'||in_survey_sid
		 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id;
	END IF;

	INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
	SELECT DISTINCT v_aggregate_ind_group_id, qsq.maps_to_ind_sid
	  FROM quick_survey_question qsq
	 WHERE qsq.survey_sid = in_survey_sid
	   AND qsq.maps_to_ind_sid IS NOT NULL
	   AND qsq.maps_to_ind_sid NOT IN (
		SELECT ind_sid
		  FROM aggregate_ind_group_member
		 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id
	   );

	INSERT INTO aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
	SELECT DISTINCT v_aggregate_ind_group_id, qso.maps_to_ind_sid
	  FROM quick_survey_question qsq
	  JOIN qs_question_option qso ON qsq.question_id = qso.question_id
	 WHERE qsq.survey_sid = in_survey_sid
	   AND qso.maps_to_ind_sid IS NOT NULL
	   AND qso.maps_to_ind_sid NOT IN (
		SELECT ind_sid
		  FROM aggregate_ind_group_member
		 WHERE aggregate_ind_group_id = v_aggregate_ind_group_id
	   );
END;

/*Returns historic submissions (without the draft version)*/
PROCEDURE GetSubmissions(
	in_survey_response_id	IN quick_survey_response.survey_response_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	CheckResponseAccess(in_survey_response_id);

	OPEN out_cur FOR
		SELECT qss.submission_id, qss.submitted_dtm, qss.submitted_by_user_sid, qss.overall_score, cu.full_name submitted_by_user_full_name
		  FROM quick_survey_submission qss
		  JOIN csr_user cu ON qss.submitted_by_user_sid = cu.csr_user_sid
		 WHERE qss.survey_response_id = in_survey_response_id
		   AND qss.submission_id <> 0 --todo: pass this as an option?
		 ORDER BY qss.submitted_dtm DESC;
END;

FUNCTION GetCSClass(
	in_survey_sid			IN	security_pkg.T_SID_ID
) RETURN qs_custom_question_type.cs_class%TYPE
AS
	v_type_class	quick_survey_type.cs_class%TYPE DEFAULT NULL;
BEGIN
	SELECT qst.cs_class
	  INTO v_type_class
	  FROM quick_survey qs
	  LEFT JOIN quick_survey_type qst ON qs.quick_survey_type_id = qst.quick_survey_type_id
	 WHERE qs.survey_sid = in_survey_sid;

	RETURN v_type_class;
END;

PROCEDURE RecreateQuickSurveyWebRes(
	in_object_sid		IN	security_pkg.T_SID_ID,
	in_object_name		IN	security.securable_object.Name%TYPE,
	in_class_id			IN  security_pkg.T_SID_ID
)
AS
    v_app_sid		security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_act_id		security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_web_root_sid	security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'wwwroot');
BEGIN
	INSERT INTO security.WEB_RESOURCE(WEB_ROOT_SID_ID, PATH, SID_ID, IP_RULE_ID, REWRITE_PATH)
		VALUES(v_web_root_sid, '/surveys/'||in_object_name, in_object_sid, null, '/csr/site/quicksurvey/public/view.acds?sid='||in_object_sid);
END;

-- This will go through all questions of the provided survey and attempt to copy an answer from a previous submission if that question or one of its parents was marked with "remember_answer"
-- it will always try to get the most recent answer available that the user has access to
PROCEDURE CopyAnswersFromPrevious(
	in_survey_sid					IN security_pkg.T_SID_ID,
	in_response_id					IN quick_survey_response.survey_response_id%TYPE,
	in_region_sid					IN security_pkg.T_SID_ID,
	in_only_same_survey				IN NUMBER DEFAULT 0 --if this is 1 it will copy only from another response of the same survey, otherwise it will copy from any survey that has questions with the same lookup_keys
)
AS
	v_survey_has_rember_answer		NUMBER(10);
	v_survey_version				NUMBER(10);
BEGIN
	-- Temporary optimisation fix!
	SELECT COUNT(question_id)
	  INTO v_survey_has_rember_answer
	  FROM quick_survey_question
	 WHERE remember_answer = 1
	   AND survey_sid = in_survey_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_survey_has_rember_answer = 0 THEN
		RETURN;
	END IF;

	SELECT survey_version
	  INTO v_survey_version
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;

	FOR q IN ( SELECT DISTINCT question_id, lookup_key
				 FROM quick_survey_question
				WHERE survey_sid = in_survey_sid
				  AND is_visible = 1
				  AND survey_version = v_survey_version
				START WITH remember_answer = 1
				  AND lookup_key IS NOT NULL
			  CONNECT BY
				PRIOR question_id = parent_id )
	LOOP
		DECLARE
			v_from_response_id		quick_survey_response.survey_response_id%TYPE;
			v_from_submission_id	quick_survey_submission.submission_id%TYPE;
			v_from_question_id		quick_survey_question.question_id%TYPE;
		BEGIN
			SELECT survey_response_id, question_id, submission_id
			  INTO v_from_response_id, v_from_submission_id, v_from_question_id
			  FROM ( SELECT qsa.survey_response_id, qsa.question_id, qsa.submission_id
			           FROM quick_survey_answer qsa
					   JOIN quick_survey_question qsq ON qsa.question_id = qsq.question_id AND qsa.survey_version = qsq.survey_version
					   JOIN quick_survey_response qsr ON qsa.survey_response_id = qsr.survey_response_id
					   JOIN quick_survey_submission qss ON qsa.submission_id = qss.submission_id
					   LEFT JOIN supplier_survey_response ssr ON qsr.survey_response_id = ssr.survey_response_id
					   LEFT JOIN supplier s ON ssr.supplier_sid = s.company_sid
					   LEFT JOIN region_survey_response rsr ON qsr.survey_response_id = rsr.survey_response_id
					   LEFT JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
					   LEFT JOIN internal_audit ias ON ias.summary_response_id = qsr.survey_response_id
					  WHERE (in_only_same_survey = 0 OR qsa.survey_sid = in_survey_sid)
					    AND COALESCE(ias.region_sid, ia.region_sid, rsr.region_sid, s.region_sid) = in_region_sid
					    AND qss.submitted_dtm IS NOT NULL
					    AND qsq.lookup_key = q.lookup_key
				      ORDER BY qss.submitted_dtm DESC )
			 WHERE rownum = 1;

			CopyAnswer(v_from_response_id, v_from_submission_id, v_from_question_id, in_response_id, q.question_id);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END LOOP;
END;

PROCEDURE GetSurveyChangeList(
	in_act_id			IN security.security_pkg.T_ACT_ID,
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security.security_pkg.IsAccessAllowedSID(in_act_id, in_survey_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT al.audit_date, NVL(cu.full_name, 'System Administrator') full_name, al.description
		  FROM csr.audit_log al
		  JOIN csr_user cu ON al.app_sid = cu.app_sid AND al.user_sid = cu.csr_user_sid
		 WHERE al.app_sid = security.security_pkg.GetApp
		   AND al.object_sid = in_survey_sid
		   AND al.audit_type_id IN
			(csr_data_pkg.AUDIT_TYPE_SURVEY_CHANGE, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA)
		 ORDER BY al.audit_date;
END;

PROCEDURE SyncAnswerScores(
	in_survey_response_id		quick_survey_submission.survey_response_Id%TYPE,
	in_survey_submission_id		quick_survey_submission.submission_Id%TYPE,
	in_survey_version			quick_survey_submission.survey_version%TYPE
)
AS
	v_survey_sid			security.security_pkg.T_SID_ID;
BEGIN
	IF in_survey_submission_id = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'We don''t allow syncing asnwer scores for draft submissions');
	END IF;

	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE app_sid = security_pkg.getApp
	   AND survey_response_Id = in_survey_response_Id;

/* 	SELECT current_version
	  INTO v_current_survey_version
	  FROM quick_survey
	 WHERE app_sid = security_pkg.GetApp
	   AND survey_sid = v_survey_sid; */

/* 	IF in_survey_version = v_current_survey_version THEN
		RAISE_APPLICATION_ERROR(-20001, 'We don''t allow syncing asnwer scores of the last survey version');
	END IF; */

	--update the question option scores for radio, matrix questions (val_number and question_option_id seem to be mutually exclusive)
	UPDATE quick_survey_answer qsa
	   SET score = CASE WHEN qsa.question_option_id IS NULL THEN
			(
				NVL2(score, (--TODO: if there is no question_option and no score_expression, score should be set to null, not max score
					SELECT max(score) --TODO: that was a wrong assumption: either set it to null OR set to max/min score based on the pre-updated answer - possibly is caused because of bad data
					  FROM qs_question_option qso
					 WHERE qso.app_sid = qsa.app_Sid
					   AND qso.question_id = qsa.question_id
					   AND qso.survey_version = in_survey_version
					   AND qso.is_visible = 1
				   ), NULL)
			)
			ELSE
			(
				SELECT score
				  FROM qs_question_option qso
				 WHERE qso.app_sid = qsa.app_Sid
				   AND qso.question_option_id = qsa.question_option_id
				   AND qso.question_id = qsa.question_id
				   AND qso.survey_version = in_survey_version
				   AND qso.is_visible = 1
		   )END,
	   max_score = (
			NVL2(max_score,
				(SELECT max(score) --get the max possible score from all options
				  FROM qs_question_option qso
				 WHERE qso.app_sid = qsa.app_Sid
				   AND qso.question_id = qsa.question_id
				   AND qso.is_visible = 1
				   AND qso.survey_version = in_survey_version),
				NULL
			)
	   )
	 WHERE qsa.app_sid = security_Pkg.getApp
	   AND qsa.survey_response_Id = in_survey_response_id
	   AND qsa.submission_id = in_survey_submission_id
	   AND qsa.survey_version = in_survey_version
	   --AND qsa.question_option_id is NOT NULL --user might have left the answer empty, still we might want to update the max_score?
	   AND EXISTS (
			SELECT 1
			  FROM quick_survey_question qsq
			 WHERE qsq.question_id = qsa.question_id
			   AND qsq.survey_version = qsa.survey_version
			   AND qsq.has_score_expression = 0
			   AND qsq.has_max_score_expr = 0
			   AND qsq.is_visible = 1
			   AND qsq.question_type IN ('radio', 'radiorow')
	   );

	--update checkbox question scores
	UPDATE quick_survey_answer qsa
	   SET (score, max_score) = (
			SELECT CASE qsa.val_number WHEN 1 THEN qsq.score ELSE NVL2(qsq.score, 0, NULL) END, NVL(qsq.max_score, qsq.score)
			  FROM quick_survey_question qsq
			 WHERE qsq.app_sid = qsa.app_Sid
			   AND qsq.question_id = qsa.question_id
			   AND qsq.is_visible = 1
			   AND qsq.survey_version = in_survey_version
	   )
	 WHERE qsa.app_sid = security_Pkg.getApp
	   AND qsa.survey_response_Id = in_survey_response_id
	   AND qsa.submission_id = in_survey_submission_id
	   AND qsa.survey_version = in_survey_version
	   AND qsa.question_option_id IS NULL
	   AND qsa.val_number IN (0, 1) --unchecked/checked
	   AND EXISTS (
			SELECT 1
			  FROM quick_survey_question qsq2
			 WHERE qsq2.question_id = qsa.question_id
			   AND qsq2.survey_version = qsa.survey_version
			   AND qsq2.has_score_expression = 0
			   AND qsq2.has_max_score_expr = 0
			   AND qsq2.is_visible = 1
			   AND qsq2.question_type = 'checkbox'
	   );
END;

PROCEDURE GetSurveyTypes(
	out_cur						OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- permissions?

	OPEN out_cur FOR
		SELECT quick_survey_type_id, description, cs_class, helper_pkg,
			   enable_question_count, show_answer_set_dtm,
			   other_text_req_for_score, tearoff_toolbar, capture_geo_location, enable_response_import
		  FROM quick_survey_type
		 WHERE app_sid = security.security_pkg.getApp;
END;

PROCEDURE SaveSurveyType(
	in_quick_survey_type_id		IN quick_survey_type.quick_survey_type_id%TYPE,
	in_description				IN quick_survey_type.description%TYPE,
	in_enable_question_count	IN quick_survey_type.enable_question_count%TYPE,
	in_show_answer_set_dtm		IN quick_survey_type.show_answer_set_dtm%TYPE,
	in_oth_txt_req_for_score	IN quick_survey_type.other_text_req_for_score%TYPE,
	in_tearoff_toolbar 			IN quick_survey_type.tearoff_toolbar%TYPE DEFAULT 0,
	in_cs_class					IN quick_survey_type.cs_class%TYPE,
	in_helper_pkg				IN quick_survey_type.helper_pkg%TYPE,
	in_capture_geo_location		IN quick_survey_type.capture_geo_location%TYPE DEFAULT 0,
	in_enable_response_import   IN quick_survey_type.enable_response_import%TYPE DEFAULT 1,
	out_quick_survey_type_id	OUT quick_survey_type.quick_survey_type_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can edit survey types');
	END IF;

	IF in_quick_survey_type_id IS NULL THEN

		IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_user_pkg.IsSuperAdmin = 1) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can add survey types');
		END IF;

		INSERT INTO quick_survey_type (
			quick_survey_type_id, description, enable_question_count,
			show_answer_set_dtm, cs_class, helper_pkg, other_text_req_for_score,
			tearoff_toolbar, capture_geo_location, enable_response_import
		) VALUES (
			quick_survey_type_id_seq.NEXTVAL, in_description, in_enable_question_count,
			in_show_answer_set_dtm, in_cs_class, in_helper_pkg, in_oth_txt_req_for_score, 
			in_tearoff_toolbar, in_capture_geo_location, in_enable_response_import 
		) RETURNING quick_survey_type_id INTO out_quick_survey_type_id;

	ELSE

		UPDATE quick_survey_type
		   SET description = in_description,
			   enable_question_count = in_enable_question_count,
			   show_answer_set_dtm = in_show_answer_set_dtm,
			   other_text_req_for_score = in_oth_txt_req_for_score,
			   tearoff_toolbar = in_tearoff_toolbar,
			   capture_geo_location = in_capture_geo_location,
			   enable_response_import = in_enable_response_import
		 WHERE quick_survey_type_id = in_quick_survey_type_id;

		IF security_pkg.IsAdmin(security_pkg.GetAct) OR csr_user_pkg.IsSuperAdmin = 1 THEN
			UPDATE quick_survey_type
			   SET helper_pkg = in_helper_pkg
			 WHERE quick_survey_type_id = in_quick_survey_type_id;
		END IF;

		out_quick_survey_type_id := in_quick_survey_type_id;

	END IF;
END;

PROCEDURE SetSurveyType (
	in_survey_sid					IN	security.security_pkg.T_SID_ID,
	in_survey_type_id				IN	quick_survey_type.quick_survey_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_survey_sid, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied setting survey type');
	END IF;

	UPDATE quick_survey
	   SET quick_survey_type_id = in_survey_type_id
	 WHERE survey_sid = in_survey_sid;
END;

PROCEDURE GetAllCountQuestionsIds(
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	in_survey_version	IN quick_survey_response.survey_version%TYPE,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qsq.question_id
		  FROM quick_survey_question qsq
		 WHERE qsq.app_sid = security_pkg.getapp
		   AND qsq.survey_sid = in_survey_sid
		   AND qsq.survey_version = in_survey_version
		   AND qsq.count_question = 1
		   AND qsq.is_visible = 1; --not deleted
END;

PROCEDURE GetAnsweredQuestionIds(
	in_response_id			IN quick_survey_submission.survey_response_Id%TYPE,
	in_submission_id		IN quick_survey_submission.submission_Id%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_survey_sid		security.security_pkg.T_SID_ID;
	v_survey_version	quick_survey_response.survey_version%TYPE;
BEGIN
	SELECT survey_sid, survey_version, survey_sid
	  INTO v_survey_sid, v_survey_version, v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;

	OPEN out_cur FOR
		SELECT qsq.question_id
		  FROM quick_survey_question qsq
		  JOIN quick_survey_answer qsa ON qsa.question_id = qsq.question_id AND qsa.survey_version = qsq.survey_version AND qsa.question_version = qsq.question_version
		 WHERE qsq.app_sid = security_pkg.getapp
		   AND qsq.survey_sid = v_survey_sid
		   AND qsq.survey_version = v_survey_version
		   AND qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = NVL(in_submission_id, 0)
		   AND qsq.count_question = 1
		   AND qsq.is_visible = 1
		   AND (qsa.question_option_id IS NOT NULL --todo: are they any other fields I should consider?
			OR qsa.val_number IS NOT NULL --todo: not sure if that is right
			OR qsa.answer IS NOT NULL
			OR qsa.note IS NOT NULL
			OR qsa.region_sid IS NOT NULL
			OR EXISTS (
				SELECT 1
				  FROM qs_answer_file qaf
				  JOIN qs_submission_file qsf ON qaf.qs_answer_file_id = qsf.qs_answer_file_id
				 WHERE qaf.question_id = qsq.question_id
				   AND qaf.survey_version = qsq.survey_version
				   AND qaf.survey_response_id = in_response_id
				   AND qsf.submission_id = NVL(in_submission_id, 0)
				)
			);
END;

FUNCTION IsQuestionCountEnabled(
	in_quick_survey_type_id		IN quick_survey.quick_survey_type_id%TYPE
)RETURN NUMBER
AS
	v_count_enabled		NUMBER;
BEGIN
	SELECT enable_question_count
	  INTO v_count_enabled
	  FROM quick_survey_type
	 WHERE app_sid = security_pkg.getapp
	   AND quick_survey_type_id = in_quick_survey_type_id;

	RETURN v_count_enabled;
END;

PROCEDURE UpdateLinkedResponse(
	in_ref_response_id				IN quick_survey_submission.survey_response_id%TYPE,
	in_target_response_id			IN quick_survey_submission.survey_response_id%TYPE
)
AS
	v_target_survey_sid				security.security_pkg.T_SID_ID;
	v_survey_version				quick_survey_response.survey_version%TYPE;
BEGIN
	SELECT survey_sid, survey_version
	  INTO v_target_survey_sid, v_survey_version
	  FROM csr.quick_survey_response
	 WHERE survey_response_id = in_target_response_id;

	FOR r IN (
		SELECT qsa.submission_id from_submission_id, qsa.question_id from_question_id, qstq.question_id to_question_id, qsa.lookup_key
		  FROM v$quick_survey_answer qsa
		  JOIN quick_survey_response qsr
			ON qsa.survey_response_id = qsr.survey_response_id
		  JOIN (
			SELECT DISTINCT lookup_key, question_id
			  FROM quick_survey_question
			 WHERE survey_sid = v_target_survey_sid
			   AND survey_version = v_survey_version
			   AND is_visible = 1
			) qstq
			ON qsa.lookup_key = qstq.lookup_key
		 WHERE qsa.survey_response_id = in_ref_response_id
	) LOOP
		CopyAnswer(in_ref_response_id, r.from_submission_id, r.from_question_id, in_target_response_id, r.to_question_id);
	END LOOP;
END;

PROCEDURE GetCssStyles(
	out_css_styles_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security - these are just CSS classes
	OPEN out_css_styles_cur FOR
		SELECT class_name, description, type, position
		  FROM quick_survey_css
		 WHERE app_sid = security_pkg.getapp;
END;

PROCEDURE CreateScoreTypeAggType (
	in_analytic_function			score_type_agg_type.analytic_function%TYPE,
	in_score_type_id				score_type_agg_type.score_type_id%TYPE,
	in_applies_to_nc_score			score_type_agg_type.applies_to_nc_score%TYPE,
	in_applies_to_primary_survey	score_type_agg_type.applies_to_primary_audit_survy%TYPE,
	in_applies_to_audits 			score_type_agg_type.applies_to_audits%TYPE,
	in_ia_type_survey_group_id		score_type_agg_type.ia_type_survey_group_id%TYPE
)
AS
	v_score_type_agg_type_id		score_type_agg_type.score_type_agg_type_id%TYPE;
	v_customer_aggregate_type_id	chain.customer_aggregate_type.customer_aggregate_type_id%TYPE;
	v_score_type_label				score_type.label%TYPE;
	v_survey_group_label			ia_type_survey_group.label%TYPE;
BEGIN

	SELECT MIN(label)
	  INTO v_score_type_label
	  FROM score_type
	 WHERE score_type_id = in_score_type_id;

	SELECT MIN(label)
	  INTO v_survey_group_label
	  FROM ia_type_survey_group
	 WHERE ia_type_survey_group_id = in_ia_type_survey_group_id;

	-- create score type add type
	INSERT INTO score_type_agg_type (score_type_agg_type_id, analytic_function, score_type_id,
				applies_to_nc_score, applies_to_primary_audit_survy, applies_to_audits, ia_type_survey_group_id)
	VALUES (score_type_agg_type_id_seq.NEXTVAL, in_analytic_function, in_score_type_id,
				in_applies_to_nc_score, in_applies_to_primary_survey, in_applies_to_audits, in_ia_type_survey_group_id)
	RETURNING score_type_agg_type_id INTO v_score_type_agg_type_id;

	-- link to a customer agg type
	v_customer_aggregate_type_id := chain.filter_pkg.UNSEC_AddCustomerAggregateType (
		in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_AUDITS,
		in_score_type_agg_type_id	=> v_score_type_agg_type_id
	);

	-- add agg type config to hide by default
	chain.filter_pkg.SaveAggregateTypeConfig (
		in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_AUDITS,
		in_aggregate_type_id		=> v_customer_aggregate_type_id,
		in_label					=>
				CASE in_analytic_function
					WHEN chain.filter_pkg.AFUNC_MIN THEN 'Minimum '
					WHEN chain.filter_pkg.AFUNC_MAX THEN 'Maximum '
					WHEN chain.filter_pkg.AFUNC_AVERAGE THEN 'Average '
					WHEN chain.filter_pkg.AFUNC_SUM THEN 'Total '
				END ||
				CASE
					WHEN in_applies_to_nc_score = 1 THEN 'finding '
					WHEN in_applies_to_primary_survey = 1 THEN 'survey '
					WHEN in_applies_to_audits = 1 THEN 'audit '
					ELSE LOWER(v_survey_group_label)||' '
				END ||
				LOWER(v_score_type_label),
		in_enabled					=> 0
	);
END;

FUNCTION GetTrashedResponses (
	in_survey_sid					IN security.security_pkg.T_SID_ID
)
RETURN security.security_pkg.T_SID_IDS
AS
	v_response_ids					security.security_pkg.T_SID_IDS;
BEGIN
	SELECT survey_response_id
	  BULK COLLECT INTO v_response_ids
	  FROM (
		-- This seems to cover campaign surveys tied to deleted regions
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = in_survey_sid
		   AND hidden = 1
		 UNION
		SELECT qsr.survey_response_id
		  FROM quick_survey_response qsr
		  JOIN internal_audit ia ON ia.survey_response_id = qsr.survey_response_id
		 WHERE ia.deleted = 1
		   AND qsr.survey_sid = in_survey_sid
		 UNION
		SELECT qsr.survey_response_id
		  FROM quick_survey_response qsr
		  JOIN internal_audit_survey ias ON qsr.survey_response_id = ias.survey_response_id
		  JOIN internal_audit ia ON ia.internal_audit_sid = ias.internal_audit_sid
		 WHERE ia.deleted = 1
		   AND qsr.survey_sid = in_survey_sid
	);
	
	RETURN v_response_ids;
END;

PROCEDURE GetSurveyVersions(
	in_survey_sid		IN security.security_pkg.T_SID_ID,
	in_include_zero		IN NUMBER,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_trashed_response_ids		security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can perform this action');
	END IF;

	v_trashed_response_ids := security_pkg.SidArrayToTable(GetTrashedResponses(in_survey_sid));

	OPEN out_cur FOR
		SELECT qsv.survey_version, COUNT(qss.survey_version) number_of_submissions
		  FROM quick_survey_version qsv
		  LEFT JOIN csr.quick_survey_response qsr
			ON qsr.survey_sid = qsv.survey_sid
		  LEFT JOIN csr.quick_survey_submission qss
			ON qss.survey_response_id = qsr.survey_response_id
		   AND qss.survey_version = qsv.survey_version
		   AND qss.submission_id != 0
		 WHERE qsv.survey_sid = in_survey_sid
		   AND (qsv.survey_version != 0 OR in_include_zero = 1)
		   AND qsr.question_xml_override IS NULL
		   AND qsr.survey_response_id NOT IN (SELECT column_value FROM TABLE(v_trashed_response_ids))
		  GROUP BY qsv.survey_version
		  ORDER BY qsv.survey_version ASC;

END;

PROCEDURE GetUpgradableSubmissions(
	in_survey_sid			IN security.security_pkg.T_SID_ID,
	in_survey_version_from	IN quick_survey_submission.survey_version%TYPE,
	in_survey_version_to	IN quick_survey_submission.survey_version%TYPE,
	out_cur					OUT	security.security_pkg.T_OUTPUT_CUR
)
AS
	v_max_survey_version		quick_survey_submission.survey_version%TYPE;
	v_trashed_response_ids		security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can perform this action');
	END IF;

	SELECT MAX(survey_version)
	  INTO v_max_survey_version
	  FROM quick_survey_version
	 WHERE survey_sid = in_survey_sid;

	IF in_survey_version_from <= 0 OR in_survey_version_to <= 0 OR in_survey_version_from > v_max_survey_version OR in_survey_version_to > v_max_survey_version THEN
		RAISE_APPLICATION_ERROR(-20001, 'To and from survey versions must be greater than 0 and less than ' || v_max_survey_version);
	END IF;
	
	v_trashed_response_ids := security_pkg.SidArrayToTable(GetTrashedResponses(in_survey_sid));

	OPEN out_cur FOR
		SELECT qss.submission_id, qss.survey_response_id response_id, qss.survey_version
		  FROM csr.quick_survey_response qsr
		  JOIN csr.quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
		 WHERE qss.submission_id != 0
		   AND qsr.survey_sid = in_survey_sid
		   AND qss.survey_version = in_survey_version_from
		   AND qsr.question_xml_override IS NULL
		   AND qsr.survey_response_id NOT IN (SELECT column_value FROM TABLE(v_trashed_response_ids));

END;

PROCEDURE UpgradeSubmissionToVersion(
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE,
	in_survey_version		IN	quick_survey_version.survey_version%TYPE
)
AS
	v_survey_sid				security.security_pkg.T_SID_ID;
	t_owned_question_ids		security.T_SID_TABLE;
BEGIN
	IF security.user_pkg.IsSuperAdmin = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only super admins can perform this action');
	END IF;

	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;

	UPDATE quick_survey_submission
	   SET survey_version = in_survey_version
	 WHERE survey_response_id = in_response_id
	  AND submission_id = in_submission_id;

	DELETE FROM quick_survey_answer qsa
	 WHERE qsa.survey_response_id = in_response_id
	   AND qsa.submission_id = in_submission_id
	   AND question_id NOT IN (
				SELECT qsq.question_id
				  FROM quick_survey_question qsq
				 WHERE qsq.survey_sid = v_survey_sid
				   AND qsq.survey_version = in_survey_version
				   AND qsq.is_visible = 1
			);

	SELECT q.question_id
	  BULK COLLECT INTO t_owned_question_ids
	  FROM question q
	  JOIN quick_survey_question qsq ON qsq.question_id = q.question_id
	 WHERE qsq.survey_sid = v_survey_sid
	   AND qsq.survey_version = in_survey_version
	   AND q.owned_by_survey_sid = v_survey_sid;
	   
	FOR r IN (
		SELECT qsq.question_id, qsq.measure_sid
		  FROM quick_survey_answer qsa
		  JOIN quick_survey_answer qsq on qsq.question_id = qsa.question_id and qsq.survey_version = in_survey_version AND qsa.question_version = qsq.question_version
		 WHERE qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = in_submission_id
		   AND NVL(qsa.measure_sid,0) != NVL(qsq.measure_sid,0)
		) 
	LOOP 
	  UPDATE quick_survey_answer
		     SET measure_sid = r.measure_sid,
			     measure_conversion_id = NULL
		   WHERE question_id = r.question_id
		     AND survey_response_id = in_response_id
		     AND submission_id = in_submission_id;
		END LOOP;

	UPDATE quick_survey_answer
	   SET survey_version = in_survey_version
	 WHERE survey_response_id = in_response_id
	   AND submission_id = in_submission_id;

	-- update the owned by quick_survey_answers to have the same version as the survey
	UPDATE quick_survey_answer
	   SET question_version = in_survey_version
	 WHERE survey_response_id = in_response_id
	   AND submission_id = in_submission_id
	   AND question_id IN (
			SELECT column_value
			  FROM TABLE(t_owned_question_ids)
	   );
	   
	UPDATE qs_submission_file
	   SET survey_version = in_survey_version
	 WHERE survey_response_id = in_response_id
	  AND submission_id = in_submission_id;
END;

PROCEDURE INTERNAL_RescoreAnswer(
	in_response_id				IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id			IN	quick_survey_submission.submission_id%TYPE,
	in_survey_version			IN	quick_survey_version.survey_version%TYPE,
	in_question_id				IN	quick_survey_question.question_id%TYPE
)
AS
	v_score					quick_survey_answer.score%TYPE;
	v_max_score				quick_survey_answer.max_score%TYPE;
	v_question_type			quick_survey_question.question_type%TYPE;
	v_dont_normalise_score	quick_survey_question.dont_normalise_score%TYPE;
	v_has_score_expression	quick_survey_question.has_score_expression%TYPE;
	v_has_max_score_expr	quick_survey_question.has_max_score_expr%TYPE;
	v_question_score		quick_survey_question.score%TYPE;
	v_question_max_score	quick_survey_question.max_score%TYPE;
	v_question_version		quick_survey_question.question_version%TYPE;
	v_question_option_id	qs_question_option.question_option_id%TYPE;
	v_val_number			quick_survey_answer.val_number%TYPE;
	v_survey_sid			quick_survey_response.survey_sid%TYPE;
BEGIN
	SELECT survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response
	 WHERE survey_response_id = in_response_id;
	   
	SELECT question_type, dont_normalise_score, has_score_expression,
		   has_max_score_expr, qsq.score, qsq.max_score, question_option_id, val_number, qsq.question_version
	  INTO v_question_type, v_dont_normalise_score, v_has_score_expression,
		   v_has_max_score_expr, v_question_score, v_question_max_score, v_question_option_id, v_val_number, v_question_version
	  FROM quick_survey_question qsq
	  LEFT JOIN quick_survey_answer qsa ON qsa.survey_response_id = in_response_id AND qsq.question_id = qsa.question_id AND qsq.survey_version = qsa.survey_version AND qsa.submission_id = in_submission_id  AND qsa.question_version = qsq.question_version
	 WHERE qsq.question_id = in_question_id
	   AND qsq.survey_version = in_survey_version
	   AND qsq.survey_sid = v_survey_sid;

	IF v_question_type IN ('section', 'matrix', 'checkboxgroup') THEN
		-- score child questions but ignore the container, scored later.
		FOR r IN (
			SELECT qsq.question_id, NVL(qsa.weight_override, qsq.weight) weight
			  FROM quick_survey_question qsq
			  LEFT JOIN quick_survey_answer qsa
			    ON qsq.question_id = qsa.question_id
			   AND qsq.app_sid = qsa.app_sid
			   AND qsa.survey_response_id = in_response_id
			   AND qsa.submission_id = in_submission_id
			   AND qsa.question_version = qsq.question_version
			 WHERE qsq.question_id IN (
				SELECT question_id
				  FROM quick_survey_question
				 WHERE survey_version = in_survey_version
				 START WITH parent_id = in_question_id
				CONNECT BY PRIOR question_id = parent_id AND PRIOR question_type NOT IN ('section', 'matrix', 'checkboxgroup') AND PRIOR survey_version = survey_version
			 )
			   AND qsq.survey_version = in_survey_version
			   AND is_visible = 1
		) LOOP
			INTERNAL_RescoreAnswer(in_response_id, in_submission_id, in_survey_version, r.question_id);
		END LOOP;
	ELSIF v_has_score_expression = 1 OR v_has_max_score_expr = 1 THEN
		-- ignore, will be scored later, either in SQL or C#
		NULL;
	ELSIF v_question_type IN ('radio', 'radiorow') THEN
		IF v_question_option_id IS NOT NULL THEN
			SELECT score
			  INTO v_score
			  FROM qs_question_option
			 WHERE question_option_id = v_question_option_id
			   AND question_id = in_question_id
			   AND survey_version = in_survey_version;
		END IF;

		IF v_score IS NOT NULL THEN
			SELECT MAX(score)
			  INTO v_max_score
			  FROM qs_question_option
			 WHERE question_id = in_question_id
			   AND survey_version = in_survey_version
			   AND qs_question_option.score > 0;
		END IF;

		UNSEC_SetAnswerScore(
			in_response_id,
			in_submission_id,
			v_survey_sid,
			in_survey_version,
			in_question_id,
			v_question_version,
			v_score,
			v_max_score
		);
	ELSIF v_question_type IN ('checkbox') THEN
		IF v_val_number = 1 THEN
			v_score := v_question_score;
		END IF;
		IF v_question_score < 0 THEN
			v_question_score := 0;
		END IF;
		IF v_score IS NULL AND v_question_score IS NOT NULL THEN
			v_score := 0;
		END IF;

		UNSEC_SetAnswerScore(
			in_response_id,
			in_submission_id,
			v_survey_sid,
			in_survey_version,
			in_question_id,
			v_question_version,
			v_score,
			v_question_score
		);
	END IF;
END;

PROCEDURE RescoreAnswers (
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
)
AS
BEGIN
	CheckResponseAccess(in_response_id, 1);
	
	UNSEC_RescoreAnswers(in_response_id,in_submission_id);
END;

PROCEDURE UNSEC_RescoreAnswers (
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
)
AS
	v_survey_sid			security.security_pkg.T_SID_ID;
	v_survey_version		quick_survey_version.survey_version%TYPE := INTERNAL_GetSubmSurveyVersion(in_response_id, in_submission_id);
BEGIN

	SELECT qsr.survey_sid
	  INTO v_survey_sid
	  FROM quick_survey_response qsr
	 WHERE qsr.survey_response_id = in_response_id;

	FOR r IN (
		SELECT qsq.question_id, NVL(qsa.weight_override, qsq.weight) weight
		  FROM quick_survey_question qsq
		  LEFT JOIN quick_survey_answer qsa
		    ON qsq.question_id = qsa.question_id
		   AND qsa.question_version = qsq.question_version
		   AND qsq.app_sid = qsa.app_sid
		   AND qsa.survey_response_id = in_response_id
		   AND qsa.submission_id = in_submission_id
		 WHERE qsq.survey_sid = v_survey_sid
		   AND qsq.parent_id IS NULL
		   AND qsq.survey_version = v_survey_version
	) LOOP
		INTERNAL_RescoreAnswer(in_response_id, in_submission_id, v_survey_version, r.question_id);
	END LOOP;
END;

PROCEDURE FinaliseSubmissionUpgrade (
	in_response_id			IN	quick_survey_response.survey_response_id%TYPE,
	in_submission_id		IN	quick_survey_submission.submission_id%TYPE
)
AS
BEGIN
	CheckResponseAccess(in_response_id, 1);

	CalculateResponseScore(in_response_id, in_submission_id);
END;

PROCEDURE FilterIds (
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_audit_type_group_key			IN  internal_audit_type_group.lookup_key%TYPE,
	in_parallel						IN	NUMBER,
	in_max_group_by					IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_response_ids					chain.T_FILTERED_OBJECT_TABLE;
	v_result_sids					chain.T_FILTERED_OBJECT_TABLE;
	v_starting_sids					chain.T_FILTERED_OBJECT_TABLE;
BEGIN
	v_starting_sids := in_sids;

	IF in_parallel = 0 THEN
		out_sids := in_sids;
	ELSE
		out_sids := chain.T_FILTERED_OBJECT_TABLE();
	END IF;

	INTERNAL_FilterResponseIds(in_filter_id, v_response_ids);

	IF v_response_ids IS NOT NULL THEN
		SELECT chain.T_FILTERED_OBJECT_ROW(ia.internal_audit_sid, NULL, NULL)
		  BULK COLLECT INTO out_sids
		  FROM internal_audit ia
		  JOIN TABLE(in_sids) t ON ia.internal_audit_sid = t.object_id
		  LEFT JOIN internal_audit_survey ias ON ia.internal_audit_sid = ias.internal_audit_sid
		  JOIN TABLE(v_response_ids) w ON (ia.survey_response_id = w.object_id OR ia.summary_response_id = w.object_id OR ias.survey_response_id = w.object_id);
	END IF;

END;


PROCEDURE FilterCompanyResponseStatuses(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
BEGIN

	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, t.stateId, t.stateLabel
		  FROM (
			SELECT fs.flow_state_id AS stateId, fs.label AS stateLabel
			FROM chain.filter_field ff
			 JOIN campaigns.campaign qc ON ff.name = 'CampaignStatus.' || qc.campaign_sid
			 JOIN flow f ON qc.flow_sid = f.flow_sid
			 JOIN flow_state fs ON f.flow_sid = fs.flow_sid
			 WHERE ff.filter_field_id = in_filter_field_id
		  ) t
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = t.stateId
		 );
	END IF;

	chain.filter_pkg.SortFlowStateValues(in_filter_field_id);
	chain.filter_pkg.SetFlowStateColours(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, ff.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM supplier s
			  JOIN TABLE(in_sids) t ON s.company_sid = t.object_id
			  JOIN region_survey_response rsr ON s.app_sid = rsr.app_sid AND s.region_sid = rsr.region_sid
			  JOIN flow_item fi ON rsr.survey_response_id = fi.survey_response_id
			  JOIN quick_survey_response qsr ON rsr.survey_response_id = qsr.survey_response_id
			  JOIN chain.filter_value fv ON fi.current_state_id =  fv.num_value
			  JOIN chain.filter_field ff ON fv.filter_field_id = ff.filter_field_id AND ff.name  = 'CampaignStatus.'||qsr.qs_campaign_sid
	 WHERE  fv.filter_field_id = in_filter_field_id;

END;

PROCEDURE PopulateExtendedFolderSearch (
	in_parent_sid			security.security_pkg.T_SID_ID,
	in_so_class_id   		security.securable_object_class.class_id%TYPE,
	in_search_term			VARCHAR2
)
AS
BEGIN
	-- Clear temp table
	DELETE FROM temp_folder_search_extension;

	-- search term is user input, therefore parameterize it to guard against SQL injection
	INSERT INTO temp_folder_search_extension (sid_id, parent_sid, search_result_text)
		SELECT so.sid_id, so.parent_sid_id, label
		FROM csr.v$quick_survey qs
			JOIN TABLE (
				security.SecurableObject_pkg.GetTreeWithPermAsTable(security.security_pkg.GetACT(), in_parent_sid, security.security_pkg.PERMISSION_READ, null, null,1 )) so
			    ON qs.survey_sid = so.sid_id and so.class_id = in_so_class_id
			WHERE (LOWER(label) LIKE  '%' || LOWER(in_search_term) ||'%' )
			AND qs.app_sid = security_pkg.GetApp;

END;

PROCEDURE SetScoreTypeAuditTypes (
	in_score_type_id				IN	score_type.score_type_id%TYPE,
	in_associated_audit_type_ids	IN	security_pkg.T_SID_IDS
)
AS
	v_keeper_id_tbl					security.T_SID_TABLE;
BEGIN
	-- crap hack for ODP.NET
	IF in_associated_audit_type_ids IS NULL OR (in_associated_audit_type_ids.COUNT = 1 AND in_associated_audit_type_ids(1) IS NULL) THEN
		v_keeper_id_tbl := security.T_SID_TABLE();
	ELSE
		v_keeper_id_tbl := security_pkg.SidArrayToTable(in_associated_audit_type_ids);
	END IF;

	DELETE FROM score_type_audit_type
	WHERE score_type_id = in_score_type_id;

	INSERT INTO score_type_audit_type (score_type_id, internal_audit_type_id)
	SELECT in_score_type_id, column_value FROM TABLE(v_keeper_id_tbl);
END;

FUNCTION GetResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE
) RETURN NUMBER
AS
	v_perm				NUMBER DEFAULT 0;
BEGIN
	FOR r IN(
		SELECT permission_set
		  FROM csr.flow_item fi
		  JOIN csr.region_survey_response rsr ON rsr.survey_response_id = fi.survey_response_id
		  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
		  LEFT JOIN csr.region_role_member rrm ON rsr.region_sid = rrm.region_sid AND fsrc.role_sid = rrm.role_sid AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN csr.supplier s ON rsr.region_sid = s.region_sid
		  LEFT JOIN chain.v$purchaser_involvement pi ON fsrc.flow_involvement_type_id = pi.flow_involvement_type_id AND s.company_sid = pi.supplier_company_sid
		 WHERE fi.flow_item_id = in_flow_item
		   AND fsrc.flow_capability_id = csr.csr_data_pkg.FLOW_CAP_CAMPAIGN_RESPONSE
		   AND (rrm.role_sid IS NOT NULL OR pi.flow_involvement_type_id IS NOT NULL)
		   AND permission_set > 0
	)
	LOOP
		v_perm := security.bitwise_pkg.bitor(v_perm, r.permission_set);
	END LOOP;
	
	RETURN v_perm;
END;

FUNCTION CheckResponseCapability(
	in_flow_item		csr.flow_item.flow_item_id%TYPE,
	in_expected_perm	NUMBER
) RETURN NUMBER
AS
	v_perm				NUMBER := GetResponseCapability(in_flow_item);
BEGIN
	IF BITAND(v_perm, in_expected_perm) = in_expected_perm THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN

	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM quick_survey_response qsr
	  JOIN flow_item fi ON qsr.survey_response_id = fi.survey_response_id
	  JOIN region_survey_response rsr ON fi.survey_response_id = rsr.survey_response_id
	 WHERE fi.flow_item_id = in_flow_item_id
	   AND qsr.qs_campaign_sid IS NOT NULL;

	RETURN v_count;
END;

PROCEDURE GetSurveySidsForLookupKey(
	in_survey_lookup_key	IN	quick_survey.lookup_key%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT survey_sid
		  FROM csr.quick_survey
		 WHERE lookup_key = in_survey_lookup_key;
END;

END quick_survey_pkg;
/


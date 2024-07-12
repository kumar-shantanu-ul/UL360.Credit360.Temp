create or replace PACKAGE BODY csr.audit_helper_pkg AS

PROCEDURE ReaggregateAllIndicators(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	v_internal_audit_sid		security.security_pkg.T_SID_ID;
BEGIN
	aggregate_ind_pkg.RefreshAll();
END;

PROCEDURE PublishSurveyScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to pubish scores from surveys which have 'apply to supplier' score types to the supplier.
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update company scores in other circumstances.
	v_internal_audit_sid		security.security_pkg.T_SID_ID;
	v_audit_next_due_dtm		DATE;
	v_company_sid				security.security_pkg.T_SID_ID;
BEGIN
	-- Gets internal audit details of the current workflow
	BEGIN
		SELECT av.internal_audit_sid, av.next_audit_due_dtm, s.company_sid
		  INTO v_internal_audit_sid, v_audit_next_due_dtm, v_company_sid
		  FROM v$all_audit_validity av
		  JOIN supplier s on s.region_sid = av.region_sid
		 WHERE av.flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			aspen2.error_pkg.LogError('Warning. Audit helper did not copy survey score to supplier when transitioning to state: ' || in_to_state_id || ' for flow item id:'||in_flow_item_id);
			RETURN;
	END;
	
	-- Error if  multiple supplier surveys exist on the audit with the same score_type_id
	FOR chk IN (
		SELECT 1 FROM dual
		 WHERE EXISTS (
			SELECT qs.survey_sid, st.score_type_id
			  FROM (
				-- Primary survey
				SELECT internal_audit_sid, survey_sid
				  FROM internal_audit ia 
				 WHERE ia.internal_audit_sid = v_internal_audit_sid
				 UNION ALL
				-- Secondary surveys
				SELECT ias.internal_audit_sid, ias.survey_sid 
				  FROM internal_audit_survey ias 
				 WHERE ias.internal_audit_sid = v_internal_audit_sid
			) svy
			  JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
			  JOIN score_type st on qs.score_type_id = st.score_type_id
			 WHERE st.applies_to_supplier = 1
			 GROUP BY qs.survey_sid, st.score_type_id
			HAVING count(*) > 1
		)
	) LOOP
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'Cannot publish supplier scores from multiple surveys that have the same score type.');
	END LOOP;
	
	FOR r IN (
		SELECT qsr.survey_sid, qsr.survey_response_id, st.score_type_id, st.applies_to_supplier, qsr.overall_score, qsr.score_threshold_id, qsr.submission_id
		  FROM (
			-- Primary survey
			SELECT internal_audit_sid, survey_sid, survey_response_id
			  FROM internal_audit ia 
			 WHERE ia.internal_audit_sid = v_internal_audit_sid
			 UNION ALL
			-- Secondary surveys
			SELECT ias.internal_audit_sid, ias.survey_sid, ias.survey_response_id
			  FROM internal_audit_survey ias 
			 WHERE ias.internal_audit_sid = v_internal_audit_sid
		) svy
		  JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
		  JOIN score_type st on qs.score_type_id = st.score_type_id
		  JOIN v$quick_survey_response qsr on qsr.survey_sid = qs.survey_sid AND qsr.survey_response_id = svy.survey_response_id
		WHERE svy.survey_sid is not null 
		  AND qsr.submission_id != 0
		  AND st.applies_to_supplier = 1
	)
	LOOP
		supplier_pkg.UNSEC_UpdateSupplierScore(
			in_supplier_sid			=> v_company_sid,
			in_score_type_id		=> r.score_type_id,
			in_score				=> r.overall_score,
			in_threshold_id			=> r.score_threshold_id,
			in_as_of_date			=> SYSDATE,
			in_comment_text			=> 'Copy survey score from audit workflow item ' || in_flow_item_id,
			in_valid_until_dtm		=> v_audit_next_due_dtm,
			in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_QS,
			in_score_source_id		=> r.submission_id
		);
	END LOOP;
END;


PROCEDURE PublishSurveyScoresToProperty(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from surveys which have 'apply to region' score types
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update region (property) scores in other circumstances.
	v_internal_audit_sid		security.security_pkg.T_SID_ID;
	v_region_sid				security.security_pkg.T_SID_ID;	
BEGIN
	BEGIN
		-- Gets internal audit details of the current workflow
		SELECT ia.internal_audit_sid, ia.region_sid
		  INTO v_internal_audit_sid, v_region_sid
		  FROM internal_audit ia
		  JOIN region r on r.region_sid = ia.region_sid
		 WHERE r.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
		   AND ia.flow_item_id = in_flow_item_id;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			aspen2.error_pkg.LogError('Warning. Audit helper did not copy survey score to region when transitioning to state: ' || in_to_state_id || ' for flow item id:'||in_flow_item_id);
			RETURN;
	END;
	
	-- When multiple surveys exist on the audit with the same score_type_id, we should error
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT qs.survey_sid, st.score_type_id
			  FROM (
				-- Primary survey sid
				SELECT internal_audit_sid, survey_sid
				  FROM internal_audit ia 
				 WHERE ia.internal_audit_sid = v_internal_audit_sid
				 UNION ALL
				-- Secondary survey sids
				SELECT ias.internal_audit_sid, ias.survey_sid
				  FROM internal_audit_survey ias 
				 WHERE ias.internal_audit_sid = v_internal_audit_sid
			) svy
			JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
			JOIN score_type st on qs.score_type_id = st.score_type_id
			WHERE st.applies_to_regions = 1
			GROUP BY qs.survey_sid, st.score_type_id
			HAVING count(*) > 1
		)
	) LOOP
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'Cannot publish property scores from multiple surveys that have the same score type.');
	END LOOP;
	
	FOR r IN (
		SELECT qsr.survey_sid, qsr.survey_response_id, st.score_type_id, st.applies_to_supplier, qsr.overall_score, qsr.score_threshold_id
		  FROM (
			-- Primary survey
			SELECT internal_audit_sid, survey_sid, survey_response_id
			  FROM internal_audit ia 
			 WHERE ia.internal_audit_sid = v_internal_audit_sid
			 UNION ALL
			-- Secondary surveys
			SELECT ias.internal_audit_sid, ias.survey_sid, ias.survey_response_id
			  FROM internal_audit_survey ias 
			 WHERE ias.internal_audit_sid = v_internal_audit_sid
		) svy
		  JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
		  JOIN score_type st on qs.score_type_id = st.score_type_id
		  JOIN v$quick_survey_response qsr on qsr.survey_sid = qs.survey_sid AND qsr.survey_response_id = svy.survey_response_id
		 WHERE svy.survey_sid is not null 
		   AND qsr.submission_id != 0
		   AND st.applies_to_regions = 1
	)
	LOOP		
		quick_survey_pkg.UNSEC_PublishRegionScore(
			in_region_sid		=> v_region_sid,
			in_score_type_id	=> r.score_type_id,
			in_score			=> r.overall_score,
			in_threshold_id		=> r.score_threshold_id,
			in_comment_text		=> 'Publish survey score from audit workflow item ' || in_flow_item_id
		);
	END LOOP;
END;

PROCEDURE ApplyAuditScoresToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from audit scores.
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update scores on supplier in other circumstances.
	v_company_sid				security.security_pkg.T_SID_ID;
	v_score_threshold_id		score_threshold.score_threshold_id%TYPE;
	v_score_type_id				score_type.score_type_id%TYPE;
	v_audit_next_due_dtm		DATE;
	v_score						internal_audit.nc_score%TYPE;
	v_internal_audit_sid		internal_audit.internal_audit_sid%TYPE;
BEGIN
	SELECT s.company_sid, a.next_audit_due_dtm, a.internal_audit_sid
	  INTO v_company_sid, v_audit_next_due_dtm, v_internal_audit_sid
	  FROM v$audit a
	  JOIN supplier s ON s.region_sid = a.region_sid
     WHERE flow_item_id = in_flow_item_id;

	FOR r IN (
		SELECT ias.score_type_id, ias.score, ias.score_threshold_id
		  FROM internal_audit_score ias
		  JOIN score_type st ON st.score_type_id = ias.score_type_id
		 WHERE st.applies_to_supplier = 1
		   AND internal_audit_sid = v_internal_audit_sid
	) LOOP
		supplier_pkg.UNSEC_UpdateSupplierScore(
			in_supplier_sid			=> v_company_sid,
			in_score_type_id		=> r.score_type_id,
			in_score				=> r.score,
			in_threshold_id			=> r.score_threshold_id, 
			in_as_of_date			=> SYSDATE,
			in_comment_text			=> 'Copy audit score from audit workflow item ' || in_flow_item_id,
			in_valid_until_dtm		=> v_audit_next_due_dtm,
			in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_AUDIT,
			in_score_source_id		=> v_internal_audit_sid
		);
	END LOOP;
END;

PROCEDURE PublishSurveyScoresToPermit(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from surveys which have 'apply to region' score types
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update region (property) scores in other circumstances.
	v_internal_audit_sid		security.security_pkg.T_SID_ID;
	v_permit_id					security.security_pkg.T_SID_ID;	
BEGIN
	BEGIN
		-- Gets internal audit details of the current workflow
		SELECT ia.internal_audit_sid, ia.permit_id
		  INTO v_internal_audit_sid, v_permit_id
		  FROM internal_audit ia
		  JOIN compliance_permit p on p.compliance_permit_id = ia.permit_id
		 WHERE ia.flow_item_id = in_flow_item_id;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			aspen2.error_pkg.LogError('Warning. Audit helper did not copy survey score to permti when transitioning to state: ' || in_to_state_id || ' for flow item id:'||in_flow_item_id);
			RETURN;
	END;
	
	-- When multiple surveys exist on the audit with the same score_type_id, we should error
	FOR chk IN (
		SELECT * FROM dual
		 WHERE EXISTS (
			SELECT qs.survey_sid, st.score_type_id
			  FROM (
				-- Primary survey sid
				SELECT internal_audit_sid, survey_sid
				  FROM internal_audit ia 
				 WHERE ia.internal_audit_sid = v_internal_audit_sid
				 UNION ALL
				-- Secondary survey sids
				SELECT ias.internal_audit_sid, ias.survey_sid 
				  FROM internal_audit_survey ias 
				 WHERE ias.internal_audit_sid = v_internal_audit_sid
			) svy
			JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
			JOIN score_type st on qs.score_type_id = st.score_type_id
			WHERE st.applies_to_permits = 1
			GROUP BY qs.survey_sid, st.score_type_id
			HAVING count(*) > 1
		)
	) LOOP
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'Cannot publish permit scores from multiple surveys that have the same score type.');
	END LOOP;
	
	FOR r IN (
		SELECT qsr.survey_sid, qsr.survey_response_id, st.score_type_id, qsr.overall_score, qsr.score_threshold_id, ia.next_audit_due_dtm
		  FROM (
			-- Primary survey
			SELECT internal_audit_sid, survey_sid, survey_response_id
			  FROM internal_audit ia 
			 WHERE ia.internal_audit_sid = v_internal_audit_sid
			 UNION ALL
			-- Secondary surveys
			SELECT ias.internal_audit_sid, ias.survey_sid, ias.survey_response_id 
			  FROM internal_audit_survey ias 
			 WHERE ias.internal_audit_sid = v_internal_audit_sid
		) svy
		  JOIN quick_survey qs on qs.survey_sid = svy.survey_sid
		  JOIN score_type st on qs.score_type_id = st.score_type_id
		  JOIN v$quick_survey_response qsr on qsr.survey_sid = qs.survey_sid AND qsr.survey_response_id = svy.survey_response_id
		  JOIN v$audit ia ON ia.internal_audit_sid = svy.internal_audit_sid
		 WHERE svy.survey_sid IS NOT NULL 
		   AND qsr.submission_id != 0
		   AND st.applies_to_permits = 1
	)
	LOOP		
		permit_pkg.SetPermitScore (
			in_permit_id			=> v_permit_id,
			in_score_type_id		=> r.score_type_id,
			in_threshold_id			=> r.score_threshold_id,
			in_score				=> r.overall_score,
			in_valid_until_dtm		=> r.next_audit_due_dtm,
			in_is_override			=> 0,
			in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_QS,
			in_score_source_id		=> r.survey_response_id,
			in_comment_text			=> 'Publish survey score from audit workflow item ' || in_flow_item_id
		);
	END LOOP;
END;

PROCEDURE ApplyAuditNCScoreToSupplier(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  flow_state_log.comment_text%TYPE,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	-- Transition Helper to publish scores from audit NC scores.
	-- Permissions are not checked in this helper because we are called by the workflow which will have already checked
	-- that the current user is permitted to initiate the transition - Even though they may not technically have permission 
	-- to update scores on supplier in other circumstances.
	v_company_sid				security.security_pkg.T_SID_ID;
	v_score_threshold_id		score_threshold.score_threshold_id%TYPE;
	v_score_type_id				score_type.score_type_id%TYPE;
	v_audit_next_due_dtm		DATE;
	v_score						internal_audit.nc_score%TYPE;
	v_internal_audit_sid		internal_audit.internal_audit_sid%TYPE;
BEGIN
	SELECT s.company_sid, a.nc_score_thrsh_id, a.nc_score, a.nc_score_type_id, a.next_audit_due_dtm, a.internal_audit_sid
	  INTO v_company_sid, v_score_threshold_id, v_score, v_score_type_id, v_audit_next_due_dtm, v_internal_audit_sid
	  FROM v$audit a
	  JOIN supplier s ON s.region_sid = a.region_sid
     WHERE flow_item_id = in_flow_item_id;

	supplier_pkg.UNSEC_UpdateSupplierScore(
		in_supplier_sid			=> v_company_sid,
		in_score_type_id		=> v_score_type_id,
		in_score				=> v_score,
		in_threshold_id			=> v_score_threshold_id, 
		in_as_of_date			=> SYSDATE,
		in_comment_text			=> 'Copy finding score from audit workflow item ' || in_flow_item_id,
		in_valid_until_dtm		=> v_audit_next_due_dtm,
		in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_AUDIT,
		in_score_source_id		=> v_internal_audit_sid
	);
END;

PROCEDURE SetMatchingSupplierFlowState(
	in_flow_sid					IN  security.security_pkg.T_SID_ID,
	in_flow_item_id				IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id			IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key	IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text				IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid					IN  security.security_pkg.T_SID_ID
)
AS
	v_company_sid				chain.company.company_sid%TYPE;
	v_supplier_flow_item_id		chain.supplier_relationship.flow_item_id%TYPE;
	v_supplier_flow_sid			flow.flow_sid%TYPE;
	v_to_state_lookup_key		flow_state.lookup_key%TYPE;
	v_to_state_lookup_count		NUMBER(3);
	v_to_state_id_supplier		flow_state.flow_state_id%TYPE;
	v_cache_keys				security_pkg.T_VARCHAR2_ARRAY;
BEGIN   
	BEGIN
		SELECT lookup_key
		  INTO v_to_state_lookup_key
		  FROM flow_state fs
		 WHERE fs.flow_state_id = in_to_state_id
		   AND fs.flow_sid = in_flow_sid;

		IF v_to_state_lookup_key IS NULL THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Flow state id '||in_to_state_id||' does not have a lookup key. Please assign a lookup key or remove transition helper');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find flow state with id '||in_to_state_id);
	END;

	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM internal_audit ia
		  JOIN supplier s ON ia.region_sid = s.region_sid
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Could not find company sid for audit with flow item id '||in_flow_item_id);
	END;

	BEGIN
		SELECT flow_item_id
		  INTO v_supplier_flow_item_id
		  FROM chain.supplier_relationship sr
		 WHERE sr.supplier_company_sid = v_company_sid
		   AND sr.purchaser_company_sid = chain.helper_pkg.GetTopCompanySid;

		IF v_supplier_flow_item_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Relationship between top company and company with sid '||v_company_sid||' does not have a flow item id');
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Relationship not found between top company and company with sid '||v_company_sid);
	END;

	BEGIN
		SELECT flow_sid
		  INTO v_supplier_flow_sid
		  FROM flow_item fi
		 WHERE fi.flow_item_id = v_supplier_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Flow item id '||v_supplier_flow_item_id||' not assigned to correct supplier workflow');
	END;

	BEGIN
		SELECT count(flow_state_id)
		  INTO v_to_state_lookup_count
		  FROM flow_state fs
		 WHERE fs.flow_sid = v_supplier_flow_sid
		   AND fs.lookup_key = v_to_state_lookup_key;
		   
		IF v_to_state_lookup_count > 1 THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'Multiple flow states with lookup key '||v_to_state_lookup_key||' found in workflow with sid '||v_supplier_flow_sid);
		END IF;
	END;

	BEGIN
		SELECT flow_state_id
		  INTO v_to_state_id_supplier
		  FROM flow_state fs
		 WHERE fs.flow_sid = v_supplier_flow_sid
		   AND fs.lookup_key = v_to_state_lookup_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_OBJECT_NOT_FOUND, 'Flow state with lookup key '||v_to_state_lookup_key||' not found in workflow with sid '||v_supplier_flow_sid);
	END;
	
	flow_pkg.SetItemState(
		in_flow_item_id		=> v_supplier_flow_item_id,
		in_to_state_Id		=> v_to_state_id_supplier,
		in_comment_text		=> 'Transition supplier to match state of audit workflow item ' || in_flow_item_id,
		in_cache_keys		=> v_cache_keys,
		in_force			=> 1,
		in_cancel_alerts	=> 0
	);
END;

PROCEDURE CheckSurveySubmission(
	in_flow_sid						IN  security.security_pkg.T_SID_ID,
	in_flow_item_id					IN  csr.csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN  csr.csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN  csr.csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN  csr.csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid						IN  security.security_pkg.T_SID_ID
)
AS
	v_completed_dtm					DATE;
BEGIN   
	SELECT survey_completed
	  INTO v_completed_dtm
	  FROM csr.v$audit
	 WHERE flow_item_id = in_flow_item_id;

	IF v_completed_dtm IS NULL THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'You must submit the survey before transition'); 
	END IF;
END;

PROCEDURE CheckForFindingsCreated(
	in_flow_sid						IN  security.security_pkg.T_SID_ID,
	in_flow_item_id					IN  csr_data_pkg.T_FLOW_ITEM_ID,
	in_from_state_id				IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_to_state_id					IN  csr_data_pkg.T_FLOW_STATE_ID,
	in_transition_lookup_key		IN  csr_data_pkg.T_LOOKUP_KEY,
	in_comment_text					IN  csr_data_pkg.T_FLOW_COMMENT_TEXT,
	in_user_sid						IN  security.security_pkg.T_SID_ID
)
AS
	v_nc_count	NUMBER;
BEGIN
	SELECT COUNT (*)
	  INTO v_nc_count
	  FROM internal_audit ia
	  JOIN non_compliance nc ON nc.created_in_audit_sid = ia.internal_audit_sid
	 WHERE ia.flow_item_id = in_flow_item_id;

	IF v_nc_count = 0 THEN
		RAISE_APPLICATION_ERROR(csr.csr_data_pkg.ERR_FLOW_STATE_CHANGE_FAILED, 'No findings have been entered for this audit. You need to create a finding before transition.'); 
	END IF;
END;

END audit_helper_pkg;
/

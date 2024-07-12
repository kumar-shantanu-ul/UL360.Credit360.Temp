CREATE OR REPLACE PACKAGE BODY csr.workflow_api_pkg AS

PROCEDURE GetPermissibleTransitions(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_transitions_cur		OUT	SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_count					NUMBER;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	OPEN out_transitions_cur FOR
		SELECT DISTINCT verb, fst.pos, fst.flow_state_transition_id
		  FROM flow_item fi
		  JOIN flow_item_region fir on fir.flow_item_id = fi.flow_item_id
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid
		  JOIN flow_state_transition fst ON fst.from_state_id = fs.flow_state_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND EXISTS (
			   SELECT 1
				 FROM region_role_member rrm 
				 JOIN flow_state_transition_role fstr ON rrm.role_sid = fstr.role_sid
				WHERE fstr.flow_state_transition_id = fst.flow_state_transition_id
				  AND rrm.app_sid = fi.app_sid
				  AND rrm.region_sid = fir.region_sid
				  AND rrm.user_sid = v_user_sid
		   );
END;

FUNCTION GetToStateId(
	in_transition_id	IN flow_state_transition.flow_state_transition_id%TYPE
) RETURN NUMBER
AS	v_to_state_id 	flow_state.flow_state_id%TYPE;
BEGIN
	BEGIN
		SELECT to_state_id
		  INTO v_to_state_id
		  FROM flow_state_transition
		 WHERE flow_state_transition_id = in_transition_id;

		RETURN v_to_state_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow transition id ('||in_transition_id||') cannot be found.');
	END;
END;

FUNCTION HasPermissionsOnTransition(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_flow_state_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE
) RETURN NUMBER
AS
	v_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_region_sids_t		security.T_SID_TABLE;
	v_has_perm			NUMBER;
BEGIN
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_has_perm
	  FROM flow_state_transition_role fstr
	  JOIN region_role_member rrm ON rrm.role_sid = fstr.role_sid 
	   AND rrm.user_sid = v_user_sid 
	 WHERE flow_state_transition_id = in_flow_state_transition_id
	   AND rrm.region_sid IN (
		   SELECT fir.region_sid
			 FROM flow_item_region fir
			WHERE fir.flow_item_id = in_flow_item_id
	   );

	RETURN v_has_perm;
END;

PROCEDURE SetItemState_SEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment_text			IN	flow_state_log.comment_text%TYPE,
	out_flow_state_log_cur	OUT	SYS_REFCURSOR,
	out_flow_state_cur		OUT	SYS_REFCURSOR
)
AS
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_transition_id			flow_state_transition.flow_state_transition_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	BEGIN
		SELECT flow_state_transition_id
		  INTO v_transition_id
		  FROM flow_state_transition
		 WHERE flow_state_transition_id = in_transition_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified transition ('||in_transition_id||') cannot be found.');
	END;

	IF HasPermissionsOnTransition(in_flow_item_id, in_transition_id) = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'User with SID:'||SYS_CONTEXT('SECURITY', 'SID')||' doesn''t have permissions on transition with id:'||in_transition_id||' for flow item id:'||in_flow_item_id);
	END IF;

	flow_pkg.SetItemState(
		in_flow_item_id			=> in_flow_item_id,
		in_to_state_Id			=> GetToStateId(in_transition_id),
		in_comment_text			=> in_comment_text,
		in_cache_keys			=> v_cache_keys,
		in_user_sid				=> SYS_CONTEXT('SECURITY','SID'),
		in_force				=> 0,
		in_cancel_alerts		=> 0,
		out_flow_state_log_id	=> v_flow_state_log_id
	);

	OPEN out_flow_state_log_cur FOR
		SELECT v_flow_state_log_id flow_state_log_id FROM DUAL;

	GetFlowState_UNSEC(
		in_flow_item_id			=> in_flow_item_id,
		out_flow_state_cur		=> out_flow_state_cur
	);
END;

PROCEDURE GetStateTransitionDetail(
	in_flow_transition_id			IN	flow_state_transition.flow_state_transition_id%TYPE,
	out_detail						OUT	SYS_REFCURSOR
)
AS
	v_transition_id					flow_state_transition.flow_state_transition_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_state_transition_id
		  INTO v_transition_id
		  FROM flow_state_transition
		 WHERE flow_state_transition_id = in_flow_transition_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified transition ('||in_flow_transition_id||') cannot be found.');
	END;

	OPEN out_detail FOR
		SELECT fs.flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.flow_state_nature_id,
			pfs.flow_state_id prev_flow_state_id, pfs.label prev_flow_state_label, pfs.lookup_key prev_flow_state_lookup_key,
			pfs.flow_state_nature_id prev_flow_state_nature_id
		  FROM flow_state_transition fst
		  JOIN flow_state fs ON fs.flow_state_id = fst.to_state_id
		  JOIN flow_state pfs ON pfs.flow_state_id = fst.from_state_id
		 WHERE fst.flow_state_transition_id = in_flow_transition_id;
END;

PROCEDURE GetFlowStateSurveyTags_UNSEC(
	in_flow_item_id				IN	flow_item.flow_item_id%TYPE,
	out_flow_state_tags_cur		OUT	SYS_REFCURSOR
)
AS
	v_flow_item_id				flow_item.flow_item_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	OPEN out_flow_state_tags_cur FOR
		SELECT fsst.tag_id
		  FROM csr.flow_item fi
		  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id
		  JOIN csr.flow_state_survey_tag fsst ON fs.flow_state_id = fsst.flow_state_id
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fi.app_sid = security_pkg.getApp;
END;

FUNCTION GetItemCapabilityPermission (
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_capability_id	IN	flow_capability.flow_capability_id%TYPE
) RETURN security_pkg.T_PERMISSION
AS
	v_permission_set	security_pkg.T_PERMISSION DEFAULT 0;
	v_flow_item_id		flow_item.flow_item_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	FOR r IN (
		SELECT fsrc.permission_set
		  FROM flow_item fi
		  JOIN flow_item_region fir on fir.flow_item_id = fi.flow_item_id
		  JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id
		  LEFT JOIN region_role_member rrm
			ON rrm.role_sid = fsrc.role_sid
		   AND rrm.region_sid = fir.region_sid
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
		   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 WHERE fi.flow_item_id = in_flow_item_id
		   AND fsrc.flow_capability_id = in_capability_id
		   AND (
				(fsrc.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
				(fsrc.group_sid IS NOT NULL AND act.act_id IS NOT NULL )
			)
	) LOOP
		v_permission_set := security.bitwise_pkg.bitor(v_permission_set, r.permission_set);
	END LOOP;

	RETURN v_permission_set;
END;

PROCEDURE GetFlowState_UNSEC(
	in_flow_item_id			IN	flow_item.flow_item_id%TYPE,
	out_flow_state_cur		OUT	SYS_REFCURSOR
)
AS
	v_flow_item_id			flow_item.flow_item_id%TYPE;
BEGIN
	BEGIN
		SELECT flow_item_id
		  INTO v_flow_item_id
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;

	OPEN out_flow_state_cur FOR 
		SELECT fs.label flow_state_label, fs.state_colour, fsn.label flow_state_nature_label, fs.flow_state_nature_id, fs.survey_editable is_survey_editable
		  FROM flow_item fi
		  JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id
		  LEFT JOIN flow_state_nature fsn ON fsn.flow_state_nature_id = fs.flow_state_nature_id
		 WHERE fi.flow_item_id = in_flow_item_id;
END;

PROCEDURE GetPermissibleIds (
	in_capability_id			IN	flow_capability.flow_capability_id%TYPE,
	in_region_sid				IN	flow_item_region.region_sid%TYPE,
	out_permissible_ids_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sid				flow_item_region.region_sid%TYPE;
BEGIN
	BEGIN
		SELECT region_sid
		  INTO v_region_sid
		  FROM csr.region
		 WHERE region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified region ('||in_region_sid||') cannot be found.');
	END;

	OPEN out_permissible_ids_cur FOR
		SELECT DISTINCT fi.flow_item_id
		  FROM flow_item fi
		  JOIN flow_item_region fir ON fir.flow_item_id = fi.flow_item_id
		  JOIN flow_state_role_capability fsrc ON fi.current_state_id = fsrc.flow_state_id
		  LEFT JOIN region_role_member rrm
			ON rrm.role_sid = fsrc.role_sid
		   AND rrm.region_sid = fir.region_sid
		   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  LEFT JOIN security.act act ON fsrc.group_sid = act.sid_id
		   AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
		 WHERE fir.region_sid = in_region_sid
		   AND fsrc.flow_capability_id = in_capability_id
		   AND (
				(fsrc.role_sid IS NOT NULL AND rrm.role_sid IS NOT NULL) OR
				(fsrc.group_sid IS NOT NULL AND act.act_id IS NOT NULL )
			)
		   AND fsrc.permission_set > 0;
END;

PROCEDURE GetFlowStateLogs (
	in_flow_item_id				IN	flow_state_log.flow_item_id%TYPE,
	out_flow_state_logs_cur		OUT	SYS_REFCURSOR
)
AS
	v_flow_sid					security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT flow_sid
		  INTO v_flow_sid
		  FROM flow_item
		 WHERE flow_item_id = in_flow_item_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The specified flow item ('||in_flow_item_id||') cannot be found.');
	END;
	
	-- check permission on the workflow - bit lame
	-- TODO: how do we secure this stuff better?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, v_flow_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading flow sid '||v_flow_sid);
	END IF;

	OPEN out_flow_state_logs_cur FOR
		SELECT fsl.flow_state_log_id, fsl.set_by_user_sid, cu.full_name set_by_full_name,
			   fs.flow_state_id set_to_state_id, fs.label set_to_state_label,
			   fsl.set_dtm, fsl.comment_text, prev_fs.flow_state_id set_from_state_id, prev_fs.label set_from_state_label,
			   CASE WHEN fsl.set_by_user_sid = security.security_pkg.SID_BUILTIN_ADMINISTRATOR THEN 1 ELSE 0 END is_automated
		  FROM (
			SELECT flow_state_log_id, set_by_user_sid, set_dtm, comment_text, flow_state_Id, flow_item_id,
				   LAG(flow_state_log_id, 1) OVER (PARTITION BY flow_item_id ORDER BY flow_state_log_id) AS prev_flow_state_log_id
			  FROM flow_state_log
			) fsl
		  JOIN csr_user cu ON fsl.set_by_user_sid = cu.csr_user_sid
		  JOIN flow_state fs ON fsl.flow_state_Id = fs.flow_state_id
		  LEFT JOIN flow_state_log prev_fsl ON fsl.prev_flow_state_log_id = prev_fsl.flow_state_log_id
		  LEFT JOIN flow_state prev_fs ON prev_fsl.flow_state_id = prev_fs.flow_state_id
		 WHERE fsl.flow_item_id = in_flow_item_id
		 ORDER BY fsl.flow_state_log_id DESC;
END;

END;
/

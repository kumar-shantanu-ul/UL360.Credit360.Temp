CREATE OR REPLACE PACKAGE BODY CSR.deleg_admin_pkg AS

PROCEDURE SetIndTags(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_tags				IN	security_pkg.T_VARCHAR2_ARRAY
)
AS
	DML_ERRORS EXCEPTION;
	PRAGMA EXCEPTION_INIT(DML_ERRORS, -24381);
	t_tags	security.T_VARCHAR2_TABLE;
	v_root_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	-- dereference to get root delegation
	v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);

	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid '||v_root_delegation_sid);
	END IF;
	
	IF in_tags.COUNT = 1 AND in_tags(1) IS NULL THEN
		-- hack for ODP.NET which doesn't support empty arrays - just delete everything
		DELETE FROM delegation_ind_tag 
		 WHERE delegation_sid = v_root_delegation_sid
		   AND ind_sid = in_ind_sid;

		DELETE FROM delegation_ind_cond_action
		 WHERE (delegation_sid, tag) NOT IN (
		   	SELECT DISTINCT delegation_sid, tag
			  FROM delegation_ind_tag
		 );

		DELETE FROM delegation_ind_tag_list
		 WHERE (delegation_sid, tag) NOT IN (
			SELECT DISTINCT delegation_sid, tag
			  FROM delegation_ind_tag
		 );
		 RETURN;
	END IF;
	
	-- we have a unique key constraint with a functional index LOWER(tag)
	BEGIN
		FORALL i IN INDICES OF in_tags SAVE EXCEPTIONS -- we need exceptions or it'll stop after first exception
			INSERT INTO delegation_ind_tag_list (delegation_sid, tag)
				VALUES (v_root_delegation_sid, in_tags(i));
	EXCEPTION
		WHEN DML_ERRORS THEN	
			FOR i IN 1 .. SQL%BULK_EXCEPTIONS.count 
			LOOP
				IF SQL%BULK_EXCEPTIONS(i).ERROR_CODE != 1 THEN
					-- we can't raise system exceptions
					RAISE_APPLICATION_ERROR(-20001, SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
				END IF;
			END LOOP;
	END;
	
	
	BEGIN
		FORALL i IN INDICES OF in_tags SAVE EXCEPTIONS -- we need exceptions or it'll stop after first exception
			INSERT INTO DELEGATION_IND_TAG (delegation_sid, ind_sid, tag) 
				SELECT v_root_delegation_sid, in_ind_sid, tag -- reselect from delegation tag so we get the case the same
				  FROM delegation_ind_tag_list
				 WHERE delegation_sid = v_root_delegation_sid
				   AND LOWER(tag) = LOWER(in_tags(i));
	EXCEPTION
		WHEN DML_ERRORS THEN	
			FOR i IN 1 .. SQL%BULK_EXCEPTIONS.count 
			LOOP
				IF SQL%BULK_EXCEPTIONS(i).ERROR_CODE != 1 THEN
					-- we can't raise system exceptions
					RAISE_APPLICATION_ERROR(-20001, SQLERRM(-SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
				END IF;
			END LOOP;
	END;
	
	
	-- tidy up		
	t_tags := security_pkg.Varchar2ArrayToTable(in_tags);

	DELETE FROM delegation_ind_tag 
	 WHERE delegation_sid = v_root_delegation_sid
	   AND ind_sid = in_ind_sid
	   AND LOWER(tag) NOT IN (
		   SELECT LOWER(value)
			 FROM TABLE(t_tags)
		);

	-- Hmm, perhaps this should clean up actions attached to tags that are no 
	-- longer attached to any indicators.  Leaving them for now, I guess the user
	-- might get confused if they remove a tag and add it again only to find the
	-- actions have disappeared.	
	DELETE FROM delegation_ind_tag_list
	 WHERE (delegation_sid, tag) NOT IN (
		SELECT DISTINCT delegation_sid, tag
		  FROM delegation_ind_tag
		UNION
		SELECT DISTINCT delegation_sid, tag
		  FROM delegation_ind_cond_action
	 );
END;

PROCEDURE CreateIndCond(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_expr				IN	delegation_ind_cond.expr%TYPE,
	out_ind_cond_id		OUT	delegation_ind_cond.delegation_ind_cond_id%TYPE
)
AS
	v_root_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	-- dereference to get root delegation
	v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
	
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid '||v_root_delegation_sid);
	END IF;

	INSERT INTO delegation_ind_cond (
		delegation_sid, ind_sid, delegation_ind_cond_id, expr
	) VALUES (
		v_root_delegation_sid, in_ind_sid, delegation_ind_cond_id_seq.nextval, in_expr
	) RETURNING delegation_ind_cond_id INTO out_ind_cond_id;
		
END;

PROCEDURE AmendIndCond(
	in_ind_cond_id		IN	delegation_ind_cond.delegation_ind_cond_id%TYPE,
	in_expr				IN	delegation_ind_cond.expr%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM delegation_ind_cond
	 WHERE delegation_ind_cond_id = in_ind_cond_id;		
	 
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE delegation_ind_cond
	   SET expr = in_expr
	  WHERE delegation_ind_cond_id = in_ind_cond_id;		
	  
	-- clear out actions
	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_ind_cond_id = in_ind_cond_id;
END;

PROCEDURE SetStyles(
	in_delegation_sid	IN	security_pkg.T_SID_ID,
	in_ind_sid			IN	security_pkg.T_SID_ID,
	in_description		IN	delegation_ind_description.description%TYPE,
	in_css_class		IN	delegation_ind.css_class%TYPE,
	in_visibility		IN	delegation_ind.visibility%TYPE,
	in_change_all		IN	NUMBER
)
AS
	v_root_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	-- dereference to get root delegation
	IF in_change_all = 1 THEN
		v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
	ELSE
		v_root_delegation_sid := in_delegation_sid;
	END IF;
	
	-- check permissions on the root
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- in_change_all means that we change everything from the root down
	FOR r IN (
		SELECT app_sid, description, css_class, visibility, delegation_sid, ind_sid
		  FROM v$delegation_ind
		 WHERE delegation_sid IN (
			SELECT delegation_sid
			  FROM delegation d			
			 START WITH delegation_sid = v_root_delegation_sid
		   CONNECT BY PRIOR delegation_sid = parent_sid
		  )
		  AND ind_sid = in_ind_sid
	)
	LOOP	
		UPDATE delegation_ind
		   SET css_class = in_css_class,
			   visibility = in_visibility
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid;
		
		DELETE FROM delegation_ind_description
		 WHERE delegation_sid = r.delegation_sid
		   AND ind_sid = r.ind_sid
		   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
		   
		INSERT INTO delegation_ind_description (delegation_sid, ind_sid, lang, description)
			SELECT r.delegation_sid, r.ind_sid, NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en'), in_description
			  FROM dual
			 MINUS
			SELECT r.delegation_sid, r.ind_sid, lang, description
			  FROM ind_description
			 WHERE ind_sid = r.ind_sid
			   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

		csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid, 
			'Delegation indicator description', r.description, in_description);
		csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid, 
			'Delegation style', r.css_class, in_css_class);
		csr_data_pkg.AuditValueChange(security_pkg.getACT, csr_data_pkg.AUDIT_TYPE_DELEGATION, r.app_sid, r.delegation_sid, 
			'Delegation visibility', r.visibility, in_visibility);
	END LOOP;
END;


PROCEDURE DeleteIndCond(
	in_ind_cond_id		IN	delegation_ind_cond.delegation_ind_cond_id%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT delegation_sid
	  INTO v_delegation_sid
	  FROM delegation_ind_cond
	 WHERE delegation_ind_cond_id = in_ind_cond_id;		
	 
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- clear out actions
	DELETE FROM delegation_ind_cond_action
	 WHERE delegation_ind_cond_id = in_ind_cond_id;
	
	-- delete condition   
	DELETE FROM delegation_ind_cond 
	 WHERE delegation_ind_cond_id = in_ind_cond_id;
END;


-- this gets called repeatedly so we rely on the security check in CreateIndCond or AmendIndCod
PROCEDURE UNSEC_AddIndCondAction(
	in_ind_cond_id		IN	delegation_ind_cond_action.delegation_ind_cond_id%TYPE,
	in_action			IN	delegation_ind_cond_action.action%TYPE,
	in_tag				IN	delegation_ind_cond_action.tag%TYPE
)
AS
	v_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	INSERT INTO delegation_ind_cond_action (delegation_sid, ind_sid, delegation_ind_cond_id, action, tag)
		SELECT dic.delegation_sid, dic.ind_sid, dic.delegation_ind_cond_id, in_action, dt.tag
		  FROM delegation_ind_cond dic
			JOIN delegation_ind_tag_list dt 
				ON dic.delegation_sid = dt.delegation_sid
				AND LOWER(dt.tag) = LOWER(in_tag) -- ensure we use the same case
		 WHERE delegation_ind_cond_id = in_ind_cond_id;
	
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Ind cond id or tag not found');
	END IF;
END;

PROCEDURE GetConditions(
	in_delegation_sid		IN	security_pkg.T_SID_ID,
	cur_ind_tag				OUT	security_pkg.T_OUTPUT_CUR,
	cur_ind_cond			OUT	security_pkg.T_OUTPUT_CUR,
	cur_ind_cond_action		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_root_delegation_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- dereference to get root delegation
	v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
	
	OPEN cur_ind_tag FOR
		SELECT ind_sid, tag
		  FROM delegation_ind_tag
		 WHERE delegation_sid = v_root_delegation_sid
		   AND ind_sid IN (
			-- just return relevant indicators -- i.e. we might have subdelegated a small subset
			SELECT ind_sid  
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
		   );

	OPEN cur_ind_cond FOR
		SELECT ind_sid, delegation_ind_cond_id, expr 
		  FROM delegation_ind_cond
		 WHERE delegation_sid = v_root_delegation_sid
		   AND ind_sid IN (
			-- just return relevant indicators -- i.e. we might have subdelegated a small subset
			SELECT ind_sid  
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
		   );

	OPEN cur_ind_cond_action FOR
		SELECT ind_sid, delegation_ind_cond_id, action, tag
		  FROM delegation_ind_cond_action
		 WHERE delegation_sid = v_root_delegation_sid
		   AND ind_sid IN (
			-- just return relevant indicators -- i.e. we might have subdelegated a small subset
			SELECT ind_sid  
			  FROM delegation_ind
			 WHERE delegation_sid = in_delegation_sid
		   );
END;
	

PROCEDURE GetFormExpressions(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
    OPEN out_cur FOR
        SELECT form_expr_id, delegation_sid, expr, description
          FROM form_expr
         WHERE delegation_sid = v_root_delegation_sid;
END;


PROCEDURE GetFormExpressionForIndicator(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_ind_sid          IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
    OPEN out_cur FOR
        SELECT fe.form_expr_id, fe.delegation_sid, fe.expr, fe.description
		  FROM deleg_ind_form_expr dife
		  JOIN form_expr fe ON fe.app_sid = dife.app_sid AND fe.form_expr_id = dife.form_expr_id
         WHERE dife.delegation_sid = v_root_delegation_sid
           AND dife.ind_sid = in_ind_sid;
END;


PROCEDURE SetFormExpressionForIndicator(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_ind_sid          IN  security_pkg.T_SID_ID,
    in_form_expr_id     IN  form_expr.form_expr_id%TYPE
)
AS
    v_act_id						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_deleg_ind_cnt 				NUMBER(10, 0);
    v_root_delegation_sid			security_pkg.T_SID_ID;
	v_cur							SYS_REFCURSOR;
	v_ignored_cur					SYS_REFCURSOR;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(v_act_id, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid '||v_root_delegation_sid);
    END IF;
    
    -- have we been given a valid deleg/ind map?
    SELECT COUNT(*)
      INTO v_deleg_ind_cnt
      FROM delegation_ind
     WHERE delegation_sid = v_root_delegation_sid
       AND ind_sid = in_ind_sid;        

    IF v_deleg_ind_cnt IS NULL OR v_deleg_ind_cnt < 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid delegation/ind combination supplied');
    END IF;

    -- just clear any existing mapping(s) and recreate
    DELETE FROM deleg_ind_form_expr 
     WHERE delegation_sid = v_root_delegation_sid
       AND ind_sid = in_ind_sid;
        
    -- create new mapping if we have been supplied an expr id...otherwise leave unmapped
    IF in_form_expr_id IS NOT NULL THEN
        INSERT INTO deleg_ind_form_expr (delegation_sid, ind_sid, form_expr_id)
            VALUES (v_root_delegation_sid, in_ind_sid, in_form_expr_id);
    END IF;
	
	IF in_form_expr_id IS NULL THEN
		FOR r IN (
			SELECT s.sheet_id, sv.region_sid, sv.ind_sid
			  FROM sheet s 
			  JOIN sheet_value sv ON s.sheet_id = sv.sheet_id
			  JOIN sheet_value_hidden_cache svhc ON sv.sheet_value_id = svhc.sheet_value_id
			 WHERE s.delegation_sid = in_delegation_sid 
			   AND sv.ind_sid = in_ind_sid
		) LOOP
			delegation_pkg.UnhideValue(
				in_act_id				=> v_act_id,
				in_sheet_id				=> r.sheet_id,
				in_ind_sid				=> r.ind_sid,
				in_region_sid			=> r.region_sid,
				out_cur					=> v_cur,
				out_cur_files			=> v_ignored_cur
			);
		END LOOP;
	END IF;
END;


PROCEDURE CreateFormExpression(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    in_expr             IN  form_expr.expr%TYPE,
    in_description      IN  form_expr.description%TYPE,
    out_form_expr_id    OUT form_expr.form_expr_id%TYPE
)
AS
    v_form_expr_id           form_expr.form_expr_id%TYPE;
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    SELECT FORM_EXPR_ID_SEQ.NEXTVAL
      INTO v_form_expr_id
      FROM dual;
        
    INSERT INTO form_expr (form_expr_id, delegation_sid, expr, description)
        VALUES (v_form_expr_id, v_root_delegation_sid, in_expr, in_description);

    out_form_expr_id := v_form_expr_id;
END;


PROCEDURE UpdateFormExpression(
    in_form_expr_id     IN form_expr.form_expr_id%TYPE,
    in_expr             IN  form_expr.expr%TYPE,
    in_description      IN  form_expr.description%TYPE
)
AS
    v_delegation_sid         security_pkg.T_SID_ID;
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN

    SELECT delegation_sid
      INTO v_delegation_sid
      FROM form_expr
     WHERE form_expr_id = in_form_expr_id;

    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(v_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid '||v_root_delegation_sid);
    END IF;
    
    UPDATE form_expr
       SET expr = in_expr, description = in_description
     WHERE form_expr_id = in_form_expr_id;
END;


PROCEDURE DeleteFormExpression(
    in_form_expr_id     IN form_expr.form_expr_id%TYPE
)
AS
    v_delegation_sid         security_pkg.T_SID_ID;
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN

    SELECT delegation_sid
      INTO v_delegation_sid
      FROM form_expr
     WHERE form_expr_id = in_form_expr_id;

    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(v_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid '||v_root_delegation_sid);
    END IF;
    
    DELETE FROM form_expr
     WHERE form_expr_id = in_form_expr_id;
END;


PROCEDURE GetDelegationIndExpressionMap(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
    OPEN out_cur FOR
        SELECT dife.ind_sid, dife.form_expr_id
          FROM deleg_ind_form_expr dife, delegation_ind di
         WHERE dife.delegation_sid = v_root_delegation_sid
           AND di.delegation_sid = in_delegation_sid
           AND dife.app_sid = di.app_sid AND dife.ind_sid = di.ind_sid;
END;


PROCEDURE GetDelegIndGroups(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
     OPEN out_cur FOR
		SELECT deleg_ind_group_id, delegation_sid, title, start_collapsed
		  FROM deleg_ind_group
		 WHERE delegation_sid = v_root_delegation_sid; 
END;


PROCEDURE GetDelegIndGroupInds(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    out_cur                  OUT security_pkg.T_OUTPUT_CUR
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
    OPEN out_cur FOR
        SELECT dig.ind_sid
          FROM deleg_ind_group_member dig
          JOIN delegation_ind di ON di.app_sid = dig.app_sid AND di.delegation_sid = in_delegation_sid AND di.ind_sid = dig.ind_sid
         WHERE dig.delegation_sid = v_root_delegation_sid
           AND dig.deleg_ind_group_id = in_deleg_ind_group_id
         ORDER BY di.pos;
END;


PROCEDURE CreateDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_title                 IN  deleg_ind_group.title%TYPE,
	in_start_collapsed		 IN	 deleg_ind_group.start_collapsed%TYPE,
    out_deleg_ind_group_id   OUT deleg_ind_group.deleg_ind_group_id%TYPE
)
AS
    v_deleg_ind_group_id deleg_ind_group.deleg_ind_group_id%TYPE;
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    SELECT DELEG_IND_GROUP_ID_SEQ.NEXTVAL
        INTO v_deleg_ind_group_id
        FROM dual;
        
    INSERT INTO deleg_ind_group
        (deleg_ind_group_id, delegation_sid, title, start_collapsed)
        VALUES
        (v_deleg_ind_group_id, v_root_delegation_sid, in_title, in_start_collapsed);

    out_deleg_ind_group_id := v_deleg_ind_group_id;
END;


PROCEDURE UpdateDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    in_title                 IN  deleg_ind_group.title%TYPE,
	in_start_collapsed		 IN	 deleg_ind_group.start_collapsed%TYPE
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    UPDATE deleg_ind_group
       SET title = in_title, start_collapsed = in_start_collapsed
     WHERE deleg_ind_group_id = in_deleg_ind_group_id;
END;


PROCEDURE DeleteDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    DELETE FROM deleg_ind_group
     WHERE deleg_ind_group_id = in_deleg_ind_group_id;
END;


PROCEDURE AddIndToDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_deleg_ind_group_id    IN  deleg_ind_group.deleg_ind_group_id%TYPE,
    in_ind_sid               IN  security_pkg.T_SID_ID
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    --delete any existing group membership
    DELETE FROM deleg_ind_group_member
     WHERE delegation_sid = v_root_delegation_sid
       AND ind_sid = in_ind_sid;
        
    --create new group membership
    INSERT INTO deleg_ind_group_member (delegation_sid, ind_sid, deleg_ind_group_id)
        VALUES (v_root_delegation_sid, in_ind_sid, in_deleg_ind_group_id);
END;


PROCEDURE RemoveIndFromDelegIndGroup(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_ind_sid               IN  security_pkg.T_SID_ID
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, v_root_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on root delegation sid ' || v_root_delegation_sid);
    END IF;
    
    --delete existing group membership
    DELETE FROM deleg_ind_group_member
     WHERE delegation_sid = v_root_delegation_sid
        AND ind_sid = in_ind_sid;
END;


PROCEDURE GetDelegIndGroupForInd(
    in_delegation_sid        IN  security_pkg.T_SID_ID,
    in_ind_sid               IN  security_pkg.T_SID_ID,
    out_deleg_ind_group_id   OUT deleg_ind_group.deleg_ind_group_id%TYPE
)
AS
    v_root_delegation_sid    security_pkg.T_SID_ID;
BEGIN
    -- dereference to get root delegation
    v_root_delegation_sid := delegation_pkg.GetRootDelegationSid(in_delegation_sid);
    
    IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_READ) THEN
        RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid ' || in_delegation_sid);
    END IF;
    
	BEGIN
		SELECT deleg_ind_group_id
		  INTO out_deleg_ind_group_id
		  FROM deleg_ind_group_member
		 WHERE delegation_sid = v_root_delegation_sid
			AND ind_sid = in_ind_sid;    
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			out_deleg_ind_group_id := 0; -- XXX: seems odd, but I guess we can't return null. -1 might be better. Oh well.
	END;
END;


END;
/

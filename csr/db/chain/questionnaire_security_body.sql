CREATE OR REPLACE PACKAGE BODY CHAIN.questionnaire_security_pkg
IS

FUNCTION GetCompanySid (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid				security.security_pkg.T_SID_ID;
	v_procurer_company_sid		security.security_pkg.T_SID_ID;
	v_supplier_company_sid		security.security_pkg.T_SID_ID;
BEGIN
	-- get the company that owns the questionnaire
	SELECT company_sid
	  INTO v_supplier_company_sid
	  FROM questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id;
	
	-- if the questionnaire company sid is the session company, then the company function must be supplier
	IF v_supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		
		IF in_company_function_id <> chain_pkg.SUPPLIER THEN
			RAISE_APPLICATION_ERROR(-20001, 'Suppliers can only set their own permissions on a questionnaire, not the procurers permissions');
		END IF;
		
		v_company_sid := v_supplier_company_sid;
		
	-- this should be a procurer company then
	ELSE
	
		BEGIN
			SELECT share_with_company_sid
			  INTO v_procurer_company_sid
			  FROM questionnaire_share
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND questionnaire_id = in_questionnaire_id
			   AND qnr_owner_company_sid = v_supplier_company_sid
			   AND share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Questionnaire id '||in_questionnaire_id||' is not shared with the company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		END;
		
		IF in_company_function_id = chain_pkg.PROCURER THEN
			v_company_sid := v_procurer_company_sid;
		ELSIF in_company_function_id = chain_pkg.SUPPLIER THEN
			v_company_sid := v_supplier_company_sid;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown company function id ('||in_company_function_id||')');
		END IF;
		
	END IF;
	
	RETURN v_company_sid;
END;

FUNCTION CanGrantPermissions(
	in_questionnaire_id		IN questionnaire.questionnaire_id%TYPE,
	in_company_sid			IN security.security_pkg.T_SID_ID
)RETURN NUMBER
AS 
	v_can_grant NUMBER;
BEGIN
	IF capability_pkg.CheckCapability(in_company_sid, chain_pkg.MANAGE_QUESTIONNAIRE_SECURITY) THEN
		RETURN 1;
	END IF;
	
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_can_grant
	  FROM questionnaire_user_action
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND company_function_id = chain_pkg.PROCURER --supported only for procurer user
	   AND questionnaire_action_id = chain_pkg.QUESTIONNAIRE_GRANT_PERMS;
	
	RETURN v_can_grant;
END;

PROCEDURE ValidateManageQnrSecurity (
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE
) 
AS
	v_company_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_company_sid := GetCompanySid(in_questionnaire_id, in_company_function_id);
	
	-- verify that we have either permission to manage questionnaire security for the company OR grant questionnaire actions
	IF CanGrantPermissions(in_questionnaire_id, v_company_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied managing questionnaire security for company with sid '||v_company_sid || ' and company_function_id' || in_company_function_id);
	END IF;
END;

PROCEDURE SetActionSecurityMask (
	in_questionnaire_type_id	IN  questionnaire_type.questionnaire_type_id%TYPE,
	in_company_function			IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION,
	in_action_security_type		IN  chain_pkg.T_ACTION_SECURITY_TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetActionSecurityMask can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO qnr_action_security_mask
		(questionnaire_type_id, company_function_id, questionnaire_action_id, action_security_type_id)
		VALUES
		(in_questionnaire_type_id, in_company_function, in_questionnaire_action, in_action_security_type);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE qnr_action_security_mask
			   SET action_security_type_id = in_action_security_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND questionnaire_type_id = in_questionnaire_type_id
			   AND company_function_id = in_company_function
			   AND questionnaire_action_id = in_questionnaire_action;
	END;
END;

PROCEDURE SetQuestionnaireUsers (
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_user_sids				IN  security.security_pkg.T_SID_IDS,
	out_newly_added_users_cur	OUT security.security_pkg.T_OUTPUT_CUR
) 
AS
	v_company_sid				security.security_pkg.T_SID_ID;
	v_user_sid_table			security.T_SID_TABLE;
BEGIN
	
	ValidateManageQnrSecurity(in_company_function_id, in_questionnaire_id);
	
	v_company_sid := GetCompanySid(in_questionnaire_id, in_company_function_id);
	
	v_user_sid_table := security.security_pkg.SidArrayToTable(in_user_sids);
	
	-- remove any existing permissions that have been granted to users for this questionnaire against the provided company function
	DELETE FROM questionnaire_user_action
	 WHERE app_sid = security.security_pkg.GetApp
	   AND questionnaire_id = in_questionnaire_id
	   AND company_function_id = in_company_function_id
	   AND user_sid NOT IN (SELECT column_value FROM TABLE(v_user_sid_table));
	
	-- remove the user entries as well
	DELETE FROM questionnaire_user
	 WHERE app_sid = security.security_pkg.GetApp
	   AND questionnaire_id = in_questionnaire_id
	   AND company_function_id = in_company_function_id
	   AND user_sid NOT IN (SELECT column_value FROM TABLE(v_user_sid_table));
	
	OPEN out_newly_added_users_cur FOR
		SELECT column_value user_sid
		  FROM TABLE(v_user_sid_table)
		 MINUS
		SELECT user_sid
		  FROM questionnaire_user
		 WHERE app_sid = security.security_pkg.GetApp
		   AND questionnaire_id = in_questionnaire_id
		   AND company_function_id = in_company_function_id
		   AND company_sid = v_company_sid;
	
	-- make sure that all other users are in this role as well
	INSERT INTO questionnaire_user
	(questionnaire_id, user_sid, company_function_id, company_sid)
	SELECT in_questionnaire_id, user_sid, in_company_function_id, v_company_sid
	  FROM (
		SELECT column_value user_sid
		  FROM TABLE(v_user_sid_table)
		 MINUS
		SELECT user_sid
		  FROM questionnaire_user
		 WHERE app_sid = security.security_pkg.GetApp
		   AND questionnaire_id = in_questionnaire_id
		   AND company_function_id = in_company_function_id
		   AND company_sid = v_company_sid
	);
END;

PROCEDURE SetUserPermissions (
	in_company_function_id		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_permitted_actions		IN  security_pkg.T_SID_IDS
) 
AS
	v_company_sid				security.security_pkg.T_SID_ID;
	v_permitted_actions_table	security.T_SID_TABLE;
BEGIN
	ValidateManageQnrSecurity(in_company_function_id, in_questionnaire_id);
	
	v_company_sid := GetCompanySid(in_questionnaire_id, in_company_function_id);
		
	DELETE FROM questionnaire_user_action
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id
	   AND company_function_id = in_company_function_id
	   AND user_sid = in_user_sid;
	
	IF in_permitted_actions IS NOT NULL THEN
		v_permitted_actions_table := security.security_pkg.SidArrayToTable(in_permitted_actions);
		
		INSERT INTO questionnaire_user_action
		(questionnaire_id, user_sid, company_function_id, company_sid, questionnaire_action_id)
		SELECT in_questionnaire_id, in_user_sid, in_company_function_id, v_company_sid, column_value
		  FROM TABLE(v_permitted_actions_table);
	END IF;
END;

PROCEDURE GetSecurityMasks (
	in_company_function			IN  chain_pkg.T_COMPANY_FUNCTION,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT questionnaire_type_id, company_function_id, questionnaire_action_id, capability_check, user_check
		  FROM v$qnr_action_security_mask
	     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	       AND company_function_id = NVL(in_company_function, company_function_id)
		 ORDER BY questionnaire_action_id;
END;

PROCEDURE GetPermissionMatrix (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_entry_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_entry_permission_cur	OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_procurer_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
	v_cur_pos					NUMBER;
BEGIN
	DELETE FROM TT_QNR_SECURITY_ACTION;

	DELETE FROM TT_QNR_SECURITY_ENTRY;

	DELETE FROM TT_QNR_SECURITY_ENTRY_ACTION;

	
	-- if the incoming company_sid is null, or if the session company sid, then this is the supplier
	IF NVL(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		v_supplier_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	-- otherwise, they're the procurer
	ELSE
		SELECT purchaser_company_sid, supplier_company_sid
		  INTO v_procurer_company_sid, v_supplier_company_sid
		  FROM v$supplier_relationship
		 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND supplier_company_sid = in_company_sid;
	END IF;
	
	INSERT INTO TT_QNR_SECURITY_ACTION
	(questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id, questionnaire_action_id)
	SELECT q.questionnaire_id, q.questionnaire_type_id, q.company_function_id, q.company_sid, action_security_type_id, questionnaire_action_id
	  FROM (
			  -- partial pivot of questionnaire data by company function
			  SELECT app_sid, questionnaire_id, questionnaire_type_id, company_sid, chain_pkg.SUPPLIER company_function_id
				FROM questionnaire
			   WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 AND company_sid = v_supplier_company_sid
			   UNION ALL
			  SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, share_with_company_sid company_sid, chain_pkg.PROCURER company_function_id
				FROM questionnaire q, questionnaire_share qs
			   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 AND q.app_sid = qs.app_sid
				 AND q.questionnaire_id = qs.questionnaire_id
				 AND q.company_sid = v_supplier_company_sid
				 AND q.company_sid = qs.qnr_owner_company_sid
				 AND qs.share_with_company_sid = v_procurer_company_sid
		   ) q, (
			  -- partial pivot of v$qnr_action_security_mask so that we can join on specific action types
			  SELECT app_sid, questionnaire_type_id, company_function_id, questionnaire_action_id, chain_pkg.AST_CAPABILITIES action_security_type_id
				FROM v$qnr_action_security_mask
			   WHERE capability_check = chain_pkg.ACTIVE
			   UNION ALL
			  SELECT app_sid, questionnaire_type_id, company_function_id, questionnaire_action_id, chain_pkg.AST_USERS action_security_type_id
				FROM v$qnr_action_security_mask
			   WHERE user_check = chain_pkg.ACTIVE
		   ) m
	 WHERE q.app_sid = m.app_sid
	   AND q.questionnaire_type_id = m.questionnaire_type_id
	   AND q.company_function_id = m.company_function_id;
	   
	-- CAPABILITIES (Company groups)
	INSERT INTO TT_QNR_SECURITY_ENTRY
	(questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id, id, description, position)
	SELECT qsa.questionnaire_id, qsa.questionnaire_type_id, qsa.company_function_id, qsa.company_sid, qsa.action_security_type_id, company_group_type_id, cgt.name, rownum
	  FROM (
			  SELECT DISTINCT questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id
				FROM tt_qnr_security_action
			   WHERE action_security_type_id = chain_pkg.AST_CAPABILITIES
			) qsa, company_group_type cgt
	 WHERE cgt.is_global = chain_pkg.INACTIVE
	   AND cgt.name <> chain_pkg.PENDING_GROUP
	 ORDER BY cgt.company_group_type_id;
	
	SELECT MAX(position)
	  INTO v_cur_pos
	  FROM TT_QNR_SECURITY_ENTRY;
	  
	-- CAPABILITIES	(Company type Roles)
	INSERT INTO TT_QNR_SECURITY_ENTRY
	(questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id, id, description, position)
	SELECT qsa.questionnaire_id, qsa.questionnaire_type_id, qsa.company_function_id, qsa.company_sid, qsa.action_security_type_id, r.role_sid, r.name, ROW_NUMBER() OVER (ORDER BY r.name)  + v_cur_pos
	  FROM (
			  SELECT DISTINCT questionnaire_id, questionnaire_type_id, company_function_id, tt.company_sid, action_security_type_id, company_type_id
				FROM tt_qnr_security_action tt
				JOIN company c ON tt.company_sid = c.company_sid
			   WHERE action_security_type_id = chain_pkg.AST_CAPABILITIES
			) qsa
	   JOIN company_type_role ctr ON qsa.company_type_id = ctr.company_type_id
	   JOIN csr.role r ON ctr.app_sid = r.app_sid AND ctr.role_sid = r.role_sid;
	  
	-- USERS
	INSERT INTO TT_QNR_SECURITY_ENTRY
	(questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id, id, description, position)
	SELECT qsa.questionnaire_id, qsa.questionnaire_type_id, qsa.company_function_id, qsa.company_sid, qsa.action_security_type_id, qu.user_sid, csru.full_name, rownum
	  FROM (
			  SELECT DISTINCT questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id
				FROM tt_qnr_security_action
			   WHERE action_security_type_id = chain_pkg.AST_USERS    
			) qsa, questionnaire_user qu, csr.csr_user csru
	 WHERE qu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND qu.app_sid = csru.app_sid
	   AND qu.questionnaire_id = qsa.questionnaire_id
	   AND qu.company_sid = qsa.company_sid
	   AND qu.company_function_id = qsa.company_function_id
	   AND qu.user_sid = csru.csr_user_sid
	 ORDER BY qu.added_dtm DESC;
	 
	-- CAPABILITIES [SUPPLIERS]
	INSERT INTO TT_QNR_SECURITY_ENTRY_ACTION
	(questionnaire_id, company_function_id, company_sid, action_security_type_id, id, questionnaire_action_id)
	SELECT qsa.questionnaire_id, qsa.company_function_id, qsa.company_sid, qsa.action_security_type_id, NVL(cac.company_group_type_id, cac.role_sid), qsa.questionnaire_action_id
	  FROM v$company_action_capability cac, company sc, TT_QNR_SECURITY_ACTION qsa, company_type_capability ctc
	 WHERE sc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sc.company_sid = v_supplier_company_sid
	   AND cac.company_sid = sc.company_sid
	   AND cac.company_function_id = chain_pkg.SUPPLIER
	   AND qsa.company_function_id = cac.company_function_id
	   AND qsa.company_sid = cac.company_sid
	   AND qsa.action_security_type_id = chain_pkg.AST_CAPABILITIES
	   AND qsa.action_security_type_id = cac.action_security_type_id
	   AND qsa.questionnaire_action_id = cac.questionnaire_action_id
	   AND ctc.app_sid = sc.app_sid
	   AND ctc.primary_company_type_id = sc.company_type_id
	   AND (ctc.primary_company_group_type_id = cac.company_group_type_id OR ctc.primary_company_type_role_sid = cac.role_sid)
	   AND ctc.capability_id = cac.capability_id
	   AND security.bitwise_pkg.bitand(cac.permission_set, ctc.permission_set) = cac.permission_set;
	
	-- CAPABILITIES [PROCURERS]
	IF v_procurer_company_sid IS NOT NULL THEN
		INSERT INTO TT_QNR_SECURITY_ENTRY_ACTION
		(questionnaire_id, company_function_id, company_sid, action_security_type_id, id, questionnaire_action_id)
		SELECT qsa.questionnaire_id, qsa.company_function_id, qsa.company_sid, qsa.action_security_type_id, NVL(cac.company_group_type_id, cac.role_sid), qsa.questionnaire_action_id
		  FROM v$company_action_capability cac, company pc, company sc, company_type_capability ctc, TT_QNR_SECURITY_ACTION qsa
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = sc.app_sid
		   AND pc.company_sid = v_procurer_company_sid
		   AND sc.company_sid = v_supplier_company_sid
		   AND cac.company_sid = pc.company_sid
		   AND cac.company_function_id = chain_pkg.PROCURER
		   AND qsa.company_function_id = cac.company_function_id
		   AND qsa.company_sid = cac.company_sid
		   AND qsa.action_security_type_id = chain_pkg.AST_CAPABILITIES
		   AND qsa.action_security_type_id = cac.action_security_type_id
		   AND qsa.questionnaire_action_id = cac.questionnaire_action_id
		   AND ctc.app_sid = pc.app_sid
		   AND ctc.primary_company_type_id = pc.company_type_id
		   AND (ctc.primary_company_group_type_id = cac.company_group_type_id OR ctc.primary_company_type_role_sid = cac.role_sid)
		   AND ctc.secondary_company_type_id = sc.company_type_id
		   AND ctc.capability_id = cac.capability_id
		   AND security.bitwise_pkg.bitand(cac.permission_set, ctc.permission_set) = cac.permission_set;
	END IF;
	
	-- USERS
	INSERT INTO TT_QNR_SECURITY_ENTRY_ACTION
	(questionnaire_id, company_function_id, company_sid, action_security_type_id, id, questionnaire_action_id)
	SELECT qu.questionnaire_id, qu.company_function_id, qsa.company_sid, qsa.action_security_type_id, qu.user_sid, qu.questionnaire_action_id
	  FROM tt_qnr_security_action qsa, questionnaire_user_action qu
	 WHERE qu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND qu.questionnaire_id = qsa.questionnaire_id
	   AND qu.company_function_id = qsa.company_function_id
	   AND qu.company_sid = qsa.company_sid
	   AND qu.questionnaire_action_id = qsa.questionnaire_action_id
	   AND qsa.action_security_type_id = chain_pkg.AST_USERS;
	
	OPEN out_entry_cur FOR
		SELECT questionnaire_id, questionnaire_type_id, company_function_id, company_sid, action_security_type_id, id, description, position
		  FROM TT_QNR_SECURITY_ENTRY
		 ORDER BY questionnaire_id, company_function_id, action_security_type_id, position;
		 
	OPEN out_entry_permission_cur FOR
		SELECT questionnaire_id, company_function_id, company_sid, action_security_type_id, id, questionnaire_action_id
		  FROM TT_QNR_SECURITY_ENTRY_ACTION
		 ORDER BY questionnaire_id, company_function_id, action_security_type_id, questionnaire_action_id;
END;

PROCEDURE DivineSecureSearchParameters (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_current_user_view		IN  chain_pkg.T_COMPANY_FUNCTION,
	in_for_company_function		IN  chain_pkg.T_COMPANY_FUNCTION,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid				security_pkg.T_SID_ID;
	v_questionnaire_type_id		questionnaire.questionnaire_type_id%TYPE;
BEGIN
	
	IF in_current_user_view = chain_pkg.PROCURER THEN
		-- the questionnaire must be shared with them
		SELECT q.questionnaire_type_id,
			   CASE WHEN in_for_company_function = chain_pkg.PROCURER THEN qs.share_with_company_sid
					WHEN in_for_company_function = chain_pkg.SUPPLIER THEN qs.qnr_owner_company_sid END
		  INTO v_questionnaire_type_id, v_company_sid
		  FROM questionnaire q, questionnaire_share qs
		 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND q.app_sid = qs.app_sid
		   AND q.questionnaire_id = in_questionnaire_id
		   AND q.questionnaire_id = qs.questionnaire_id
		   AND q.company_sid = qs.qnr_owner_company_sid
		   AND qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		   
	ELSIF in_current_user_view = chain_pkg.SUPPLIER THEN
		-- they must be the questionnaire owner
		SELECT q.questionnaire_type_id,
			   CASE WHEN in_for_company_function = chain_pkg.SUPPLIER THEN q.company_sid END company_sid
		  INTO v_questionnaire_type_id, v_company_sid
		  FROM questionnaire q
		 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND q.questionnaire_id = in_questionnaire_id
		   AND q.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
   
	END IF;

	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Company sid could not be determined indicating invalid input');
	END IF;
	
	OPEN out_cur FOR
		SELECT v_company_sid company_sid, 
				CASE WHEN SUM(user_check) > 0 THEN 1 ELSE 0 END allow_add_user
				--CASE WHEN SUM(other_check) > 0 THEN 1 ELSE 0 END allow_add_other
		  FROM v$qnr_action_security_mask
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id = v_questionnaire_type_id
		   AND company_function_id = in_for_company_function;
END;

/* Sql wrapper */
FUNCTION CheckPermissionSQL (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION
) RETURN NUMBER
AS
BEGIN
	IF CheckPermission(in_questionnaire_id, in_questionnaire_action) = TRUE THEN
		RETURN 1;
	ELSE 
		RETURN 0;
	END IF;
END;

FUNCTION CheckPermission (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_questionnaire_action		IN  chain_pkg.T_QUESTIONNAIRE_ACTION,
	in_user_sid					IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	in_company_sid				IN  security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
) RETURN BOOLEAN
AS
	v_questionnaire_type_id		questionnaire_type.questionnaire_type_id%TYPE;
	v_company_function_id		chain_pkg.T_COMPANY_FUNCTION;
	v_qnr_owner_company_sid		security_pkg.T_SID_ID;
	v_company_sid				security_pkg.T_SID_ID;
	v_capability				chain_pkg.T_CAPABILITY;
	v_permission_set			security_pkg.T_PERMISSION;
	v_permission_type			chain_pkg.T_CAPABILITY_PERM_TYPE;
	v_capability_check			NUMBER(10);
	v_user_check				NUMBER(10);
	v_count						NUMBER(10);
BEGIN
	
	-- Allow batch processes access to all questionnaires
	IF in_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		RETURN TRUE;
	END IF;
	
	-- get the questionnaire type id, the company who owns the questionnaire, and the company function
	BEGIN
		SELECT questionnaire_type_id, company_sid, 
		       CASE WHEN company_sid = in_company_sid THEN company_sid ELSE NULL END,
			   CASE WHEN company_sid = in_company_sid THEN chain_pkg.SUPPLIER ELSE chain_pkg.PROCURER END
		  INTO v_questionnaire_type_id, v_qnr_owner_company_sid, v_company_sid, v_company_function_id
		  FROM questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_id = in_questionnaire_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;	
	
	-- 	if the company function is the procurer, verify the questionnaire share, as well as the supplier relationship
	IF v_company_function_id = chain_pkg.PROCURER THEN
		BEGIN
			SELECT qs.share_with_company_sid
			  INTO v_company_sid
			  FROM v$questionnaire_share qs, v$supplier_relationship sr
			 WHERE qs.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND qs.app_sid = sr.app_sid
			   AND qs.questionnaire_id = in_questionnaire_id
			   AND qs.share_with_company_sid = in_company_sid
			   AND qs.share_with_company_sid = sr.purchaser_company_sid
			   AND qs.qnr_owner_company_sid = v_qnr_owner_company_sid
			   AND qs.qnr_owner_company_sid = sr.supplier_company_sid;		   
		EXCEPTION
			WHEN NO_DATA_FOUND THEN NULL;
		END;	
	END IF;
	
	-- if the company sid is not set at this point, then then there's something wrong with the check - return false
	IF v_company_sid IS NULL THEN
		RETURN FALSE;
	END IF;
	
	-- gets the mask configuration
	BEGIN
		SELECT capability_check, user_check 
		  INTO v_capability_check, v_user_check
		  FROM v$qnr_action_security_mask
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id = v_questionnaire_type_id
		   AND company_function_id = v_company_function_id
		   AND questionnaire_action_id = in_questionnaire_action;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN 
			RETURN FALSE;
	END;
	
	-- if we should check capabilities, and a capability check passes, return true
	IF v_capability_check = chain_pkg.ACTIVE THEN
		
		SELECT capability_name, permission_type, permission_set
		  INTO v_capability, v_permission_type, v_permission_set
		  FROM chain.v$qnr_action_capability
		 WHERE questionnaire_action_id = in_questionnaire_action;
		
		IF v_permission_type = chain_pkg.SPECIFIC_PERMISSION THEN
			IF capability_pkg.CheckCapability(v_qnr_owner_company_sid, v_capability, v_permission_set) THEN
				RETURN TRUE;
			END IF;
		ELSIF v_permission_type = chain_pkg.BOOLEAN_PERMISSION THEN
			IF capability_pkg.CheckCapability(v_qnr_owner_company_sid, v_capability) THEN
				RETURN TRUE;
			END IF;
		END IF;
		
	END IF;
	
	-- if we should check users, and a user check passes, return true
	IF v_user_check = chain_pkg.ACTIVE THEN
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM questionnaire_user_action
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_id = in_questionnaire_id
		   AND company_function_id = v_company_function_id
		   AND questionnaire_action_id = in_questionnaire_action
		   AND user_sid = in_user_sid
		   AND company_sid = in_company_sid;
		
		IF v_count = 1 THEN
			RETURN TRUE;
		END IF;
		
	END IF;
	
	-- otherwise...
	RETURN FALSE;
END;

PROCEDURE OnQnnairePermissionsChange(
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE
)
AS
BEGIN

	chain.chain_link_pkg.OnQnnairePermissionsChange(in_questionnaire_id);
END;

END questionnaire_security_pkg;
/

























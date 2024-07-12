CREATE OR REPLACE PACKAGE chain.latest128_pkg AS

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);
END;
/


CREATE OR REPLACE PACKAGE BODY chain.latest128_pkg AS

PROCEDURE csr_deleg_AddUser_UNSECURED(
	in_act_id			security_pkg.T_ACT_ID,
	in_delegation_sid	security_pkg.T_SID_ID,
	in_user_sid			security_pkg.T_SID_ID
)
AS
	v_full_name		csr.csr_user.full_name%TYPE;
BEGIN
	SELECT full_name 
	  INTO v_full_name
	  FROM csr.csr_user
	 WHERE csr_user_sid = in_user_sid;
	 
	INSERT INTO csr.audit_log
		(AUDIT_DATE, AUDIT_TYPE_ID, app_sid, OBJECT_SID, USER_SID, DESCRIPTION, PARAM_1, PARAM_2, PARAM_3, SUB_OBJECT_ID)
	VALUES
		(SYSDATE, 10, SYS_CONTEXT('SECURITY','APP'), in_delegation_sid, sys_context('security','sid'), 'Assigned delegation user "{0}" ({1})', 
		v_full_name, sys_context('security','sid'), null, null);	
			
	INSERT INTO csr.DELEGATION_USER
		(delegation_sid, user_sid)
	VALUES
		(in_delegation_sid, in_user_sid);
	security.group_pkg.AddMember(in_act_id, in_user_sid, in_delegation_sid);
END;

PROCEDURE csr_supplier_ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)AS
BEGIN
	FOR r IN (
		SELECT delegation_sid
		  FROM csr.supplier_delegation
		 WHERE supplier_sid = in_company_sid
		 MINUS -- remove delegations where this user is already assigned	 
		SELECT sd.delegation_sid 
		  FROM csr.supplier_delegation sd
			JOIN csr.delegation d ON sd.delegation_sid = d.delegation_sid
			JOIN csr.delegation_user du ON d.delegation_sid = du.delegation_sid
		 WHERE supplier_sid = in_company_sid
	)
	LOOP	
		csr_deleg_AddUser_UNSECURED(security_pkg.getACT, r.delegation_sid, in_user_sid);
	END LOOP;
	
	INSERT INTO csr.LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'ApproveUser', 'COMPANY_SID=' || in_company_sid || '\n' ||
									'USER_SID=' || in_user_sid || '\n');
END;

PROCEDURE DeleteGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 	
	DELETE
      FROM security.group_members 
     WHERE member_sid_id = in_member_sid and group_sid_id = in_group_sid;
END;

PROCEDURE AddGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END;

PROCEDURE ApproveUser (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, 'Pending Users');
	v_user_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, 'Users');
	v_count					NUMBER(10);
BEGIN
	
--	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
--		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
--	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;	
	
	DeleteGroupMember(in_user_sid, v_pending_sid); 
	AddGroupMember(in_user_sid, v_user_sid); 
	
	IF SYS_CONTEXT('SECURITY', 'APP') IN (7012911, 1543894, 10382451, 10771034, 10354751, 10110773, 11925431) THEN
		csr_supplier_ApproveUser(in_company_sid, in_user_sid);
	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10186359, 10492441) THEN
		csr_supplier_ApproveUser(in_company_sid, in_user_sid); -- chaindemo.link_pkg just calls this
	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10341131) THEN
		NULL; -- otto.link_pkg does nothing
	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10341131) THEN
 		NULL; -- mcdonalds.mcdonalds_link_pkg does nothing
 	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10217841) THEN
 		NULL; -- deutschebank.db_chain_pkg is dead apparently
 		--just adds an audit log entry
 		--EXECUTE IMMEDIATE 'INSERT INTO deutschebank.LINK_AUDIT (action_dtm, function_name, message ) '||
 		--	'VALUES ( SYSDATE, ''ApproveUser'', ''COMPANY_SID=' || in_company_sid || '\n' || 'USER_SID=' || in_user_sid || '\n' || ''')';
 	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10103501) THEN
 		NULL; -- rfa.rfa_link_pkg does nothing
 	ELSIF SYS_CONTEXT('SECURITY', 'APP') IN (10127111 ) THEN
 		NULL; -- maersk.maersk_link_pkg does nothing 
	END IF;
END;

PROCEDURE MakeAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, 'Administrators');
	v_count					NUMBER(10);
BEGIN	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;
	
	ApproveUser(in_company_sid, in_user_sid);
	AddGroupMember(in_user_sid, v_admin_sid); 
END;

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, 'Pending Users');
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	AddGroupMember(in_user_sid, v_pending_sid);
	
	-- URG!!!! we'll make them full users straight away for now...
	ApproveUser(in_company_sid, in_user_sid);
	
	-- if we don't have an admin user, this user will go straight to the top
	IF v_count = 0 THEN
		MakeAdmin(in_company_sid, in_user_sid);
	END IF;
END;


END;
/

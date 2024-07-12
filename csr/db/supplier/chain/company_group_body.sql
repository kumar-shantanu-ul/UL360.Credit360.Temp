CREATE OR REPLACE PACKAGE BODY SUPPLIER.company_group_pkg
IS

PROCEDURE GetGroupSid (
	in_group_type			IN  T_GROUP_TYPE,
	out_group_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	GetGroupSid(in_group_type, company_pkg.GetCompany, out_group_sid);
END;

PROCEDURE GetGroupSid (
	in_group_type			IN  T_GROUP_TYPE,
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_group_sid			OUT	security_pkg.T_SID_ID
) 
AS
	v_group_name			security_pkg.T_SO_NAME;
BEGIN

	CASE 
		WHEN in_group_type = GT_COMPANY_ADMIN THEN
			v_group_name := GN_COMPANY_ADMIN;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown group type specified ('||in_group_type||')');
		END CASE;
	
	-- ensure that the groups exist
	BEGIN
		out_group_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, in_company_sid, v_group_name);
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			-- create it if it doesn't, then try to get it again (its possible that create will 
			-- throw security exceptions, but if we can't get a sid we're probably dead in the water anyways)
			CreateGroups(in_company_sid);
			out_group_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, in_company_sid, v_group_name);
	END;
END;

FUNCTION UserIsMember (
	in_group_type			IN  T_GROUP_TYPE
) RETURN BOOLEAN
AS
	v_group_members			security.T_SO_TABLE;
	v_group_sid				security_pkg.T_SID_ID;
	v_count					NUMBER(10);
BEGIN
	
	-- group_pkg.GetMembersAsTable should provide any security that we need 
	GetGroupSid(in_group_type, v_group_sid);
	v_group_members	:= group_pkg.GetMembersAsTable(security_pkg.GetAct, v_group_sid);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_group_members)
	 WHERE sid_id = security_pkg.GetSid;
	
	RETURN (v_count = 1);
END;

PROCEDURE AddUserToGroup (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_group_type			IN  T_GROUP_TYPE
)
AS
	v_group_sid				security_pkg.T_SID_ID;
	v_count					NUMBER(10);
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM company_user
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = company_pkg.GetCompany
	   AND csr_user_sid = in_user_sid;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'The user with sid '||in_user_sid||' is not a member of the company with sid '||company_pkg.GetCompany||'.');
	END IF;
	
	GetGroupSid(in_group_type, v_group_sid);
	group_pkg.AddMember(security_pkg.GetAct, in_user_sid, v_group_sid);
END;


PROCEDURE RemoveUserFromGroup (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_group_type			IN  T_GROUP_TYPE
)
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN

	IF NOT UserIsMember(GT_COMPANY_ADMIN) THEN
		RAISE_APPLICATION_ERROR(-20001, 'The user with sid '||in_user_sid||' is not an administrator for '||company_pkg.GetCompany||'.');
	END IF;

	GetGroupSid(in_group_type, v_group_sid);
	group_pkg.DeleteMember(security_pkg.GetAct, in_user_sid, v_group_sid);
END;


PROCEDURE GetCompanyAdmins (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN
	
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading from company with sid '||company_pkg.GetCompany||'.');
	END IF;
	
	GetGroupSid(GT_COMPANY_ADMIN, v_group_sid);
		
	OPEN out_cur FOR
		SELECT vcu.company_sid, vcu.app_sid, vcu.csr_user_sid, vcu.pending_company_authorization, vcu.user_profile_visibility_id,
		       vcu.full_name, vcu.email, vcu.job_title, vcu.phone_number,
		       gm.sid_id, gm.parent_sid_id, gm.dacl_id, gm.class_id, gm.NAME, gm.flags, gm.owner
		  FROM v$chain_user vcu,
		  		TABLE(security.group_pkg.GetMembersAsTable(security_pkg.GetAct, v_group_sid)) gm
		 WHERE vcu.company_sid = company_pkg.GetCompany
		   AND vcu.app_sid = security_pkg.GetApp
		   AND vcu.csr_user_sid = gm.sid_id;	
END;

PROCEDURE GetUserGroupTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct(), company_pkg.GetCompany, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading from company with sid '||company_pkg.GetCompany||'.');
	END IF;
	

	OPEN out_cur FOR	
		SELECT DECODE(so.name,
				GN_COMPANY_ADMIN, GT_COMPANY_ADMIN) group_type
		  FROM security.securable_object so, security.group_members gm
		 WHERE so.parent_sid_id = company_pkg.GetCompany
		   AND so.sid_id = gm.group_sid_id
		   AND gm.member_sid_id = security_pkg.GetSid;
END;

PROCEDURE CreateGroups (
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_group_sid				security_pkg.T_SID_ID;
	--v_children				security.T_SO_TABLE;
	v_has_admin				NUMBER(10);
BEGIN

	--v_children := securableobject_pkg.GetChildrenAsTable(security_pkg.GetAct, in_company_sid);
	
	SELECT COUNT(*)
      INTO v_has_admin
      FROM TABLE ( securableobject_pkg.GetChildrenAsTable(security_pkg.GetAct, in_company_sid) )
     WHERE name = GN_COMPANY_ADMIN;
    
    IF v_has_admin = 0 THEN
		-- create admin group
		security.group_pkg.CreateGroup(
			security_pkg.GetAct,
			in_company_sid,
			security_pkg.GROUP_TYPE_DISTRIBUTION,
			GN_COMPANY_ADMIN,
			v_group_sid
		);
		-- give the admin group full permission on the company
		acl_pkg.AddACE(
			security_pkg.GetAct, 
			acl_pkg.GetDACLIDForSID(in_company_sid), 
			security_pkg.ACL_INDEX_LAST, 
			security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_INHERIT_INHERITABLE + security_pkg.ACE_FLAG_INHERITABLE, 
			v_group_sid, 
			security_pkg.PERMISSION_STANDARD_ALL
		);
	END IF;
	
	commit;
	
	--PERMISSION_STANDARD_READ
	
END;

END company_group_pkg;
/

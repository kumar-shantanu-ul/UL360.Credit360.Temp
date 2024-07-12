CREATE OR REPLACE PACKAGE BODY CSR.user_container_Pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid		IN security_pkg.T_SID_ID
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
	NULL;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
) 
AS	
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
)
AS   
BEGIN		 
	NULL;
END;

/**
 * Create a new user_container
 *
 * @param	in_name						Name
 * @param	out_user_container_sid		The SID of the created object
 */
PROCEDURE CreateUserContainer(
	in_name						IN	security_pkg.T_SO_NAME,
	out_user_container_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_act					security_pkg.T_ACT_ID;
	v_parent_sid_id			security_pkg.T_SID_ID;
BEGIN
	v_act := SYS_CONTEXT('SECURITY','ACT');
	
	-- create this thing under the users node for the current app
	v_parent_sid_id := securableobject_pkg.getsidfrompath(v_act, SYS_CONTEXT('SECURITY','APP'), 'Users');
	
	group_pkg.CreateGroupWithClass(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY,
		REPLACE(in_name, '/', '\'), class_pkg.getClassID('CSRUserContainer'), out_user_container_sid);
			
	-- add object to the DACL (the user_container is a group, so it has permissions on itself)
	-- i.e. if you make someone a member of this group then they get to do everything beneath this
	acl_pkg.AddACE(v_act, acl_pkg.GetDACLIDForSID(out_user_container_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, out_user_container_sid, security_pkg.PERMISSION_STANDARD_ALL);

	csr_data_pkg.WriteAuditLogEntry(v_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY','APP'), out_user_container_sid,
		'Created user container "{0}"', in_name);
END;

END user_container_pkg;
/

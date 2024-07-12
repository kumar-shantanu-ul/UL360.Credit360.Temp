CREATE OR REPLACE PACKAGE BODY CSR.role_pkg AS

/*

-- goes up tree finding things that map
select ro.name, r.description, cu.full_name
  from approval_step_role apsro, role ro, region_role_member rrm, region r, csr_user cu
 where apsro.approval_step_id = 13789
   and apsro.role_sid = ro.role_sid
   and ro.role_sid = rrm.role_sid
   and rrm.user_sid = cu.csr_user_sid
   and rrm.region_sid = r.region_sid
   and rrm.region_sid in (
		select maps_to_region_sid
		  from pending_region
		 start with pending_region_id in (
			select pending_region_id
			  from approval_step_region
			 where approval_step_id = 13789
		)
		connect by prior parent_region_id = pending_region_id
 );



select ro.name, pr.description, cu.full_name, aps.approval_step_id
  from approval_step_role apsro, approval_step aps, approval_step_region apsr, pending_region pr, region_role_member rrm, role ro, csr_user cu
 where apsro.role_sid = ro.role_sid
   and apsro.approval_step_id = aps.approval_step_id
   and aps.approval_step_id = apsr.approval_step_id
   and apsr.pending_region_id = pr.pending_region_id
   and pr.maps_to_region_sid = rrm.region_sid
   and rrm.role_sid = ro.role_sid
   and rrm.user_sid = cu.csr_user_sid;

*/

-- Internal security methods
FUNCTION WriteAccessAllowed(
	in_act_id		IN	Security_Pkg.T_ACT_ID,
	in_role_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count			NUMBER;
BEGIN
	-- If the user already has write permission on the role then no need for further checks
	IF security_pkg.IsAccessAllowedSID(in_act_id, in_role_sid, security_pkg.PERMISSION_WRITE) THEN
		RETURN 1;
	END IF;

	-- The user doesn't have write permission, check role grants
	-- to see if they can write to the role
	SELECT COUNT(*)
	  INTO v_count
	  FROM role_grant rg
	 WHERE rg.grant_role_sid = in_role_sid
		START WITH rg.role_sid IN (
			SELECT group_sid_id
	      	  FROM security.group_members
	        	START WITH member_sid_id = SYS_CONTEXT('SECURITY', 'SID')
	        	CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id
	     )
		CONNECT BY NOCYCLE PRIOR rg.grant_role_sid = rg.role_sid
	;

	IF v_count > 0 THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

FUNCTION WriteAccessAllowed(
	in_role_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	RETURN WriteAccessAllowed(SYS_CONTEXT('SECURITY', 'ACT'), in_role_sid);
END;

FUNCTION IsRoleSystemManaged(
	in_role_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_is_system_managed NUMBER;
BEGIN
	SELECT is_system_managed
	  INTO v_is_system_managed
	  FROM role
	 WHERE role_sid = in_role_sid;

	RETURN v_is_system_managed;
END;

FUNCTION CanAlterSystemManagedRole
RETURN BOOLEAN
AS
	v_alter_system_managed_role			NUMBER;
BEGIN
	SELECT NVL(MIN(val), 0)
	  INTO v_alter_system_managed_role
	  FROM transaction_context
	 WHERE key = 'alter_system_managed_role';

	RETURN v_alter_system_managed_role = 1;
END;

PROCEDURE INTERNAL_PrepGrantRegionCheck
AS
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_role_region;

	IF v_count = 0 THEN
		-- Get role/root-level region combinations
		INSERT INTO temp_role_region (role_sid, region_sid) (
			SELECT DISTINCT rg.grant_role_sid, CONNECT_BY_ROOT rrm.region_sid region_sid
			  FROM csr.role_grant rg
				LEFT JOIN csr.region_role_member rrm
				    ON rg.app_sid = rrm.app_sid
				   AND rg.role_sid = rrm.role_sid
				   AND rrm.inherited_from_sid = rrm.region_sid
				   -- XXX: If we don't restrict this to the sid of the logged on user then the logged on
				   -- user will be able to assign roles granted to them to any region that any other user
				   -- on the system, who also happens to be in the role that is the source of the grant,
				   -- is associated with through that role. This restriction is to prevent escalation of
				   -- privileges to regions with which the logged on user is not associated via any role,
				   -- although this restriction isn't quite in-line with the original wording of the spec.
		 	 	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			  	START WITH rg.role_sid IN (
			  		SELECT group_sid_id
			          FROM security.group_members
			            START WITH member_sid_id = SYS_CONTEXT('SECURITY', 'SID')
			            CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id)
			  	CONNECT BY NOCYCLE PRIOR rg.grant_role_sid = rg.role_sid
		);

		-- Fill in for child regions (reflects the available
		-- selections in the multi-root tree picker)
		FOR r IN (
			SELECT DISTINCT role_sid, region_sid
			  FROM temp_role_region
		) LOOP
			INSERT INTO temp_role_region (role_sid, region_sid) (
				SELECT r.role_sid, region_sid
				  FROM region
				 WHERE region_sid != r.region_sid
				 	START WITH region_sid = r.region_sid
				 	CONNECT BY PRIOR region_sid = parent_sid
			);
		END LOOP;
	END IF;
END;

PROCEDURE INTERNAL_CheckGrantRegions(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS
)AS
	v_count			NUMBER;
	v_denied		VARCHAR(4000);
	t_sids			security.T_SID_TABLE;
BEGIN

	-- Nothing to do if the user has write permission on the role
	IF security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_role_sid, security_pkg.PERMISSION_WRITE) THEN
		RETURN;
	END IF;

	INTERNAL_PrepGrantRegionCheck;

	-- Check the top-level regions are beneath the regions
	-- this user can administer for this role, if the temp_role_region
	-- table is empty the nthis check is not needed (admin user)
	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_role_region
	 WHERE role_sid = in_role_sid;

	IF v_count > 0 THEN

		v_denied := NULL;
		t_sids := security_pkg.SidArrayToTable(in_region_sids);
		FOR r IN (
			SELECT column_value region_sid
			  FROM TABLE(t_sids) -- Requested region sids
			MINUS
			SELECT region_sid
			  FROM temp_role_region -- Alowed region sids
			 WHERE role_sid = in_role_sid
		) LOOP
			IF v_denied IS NOT NULL THEN
				v_denied := v_denied || ', ';
			END IF;
			v_denied := v_denied || r.region_sid;
		END LOOP;
		IF v_denied IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding role for regions: '||v_denied);
		END IF;
	END IF;
END;

PROCEDURE INTERNAL_AddGroupMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_role_sid		IN Security_Pkg.T_SID_ID,
	out_added		OUT BOOLEAN
)
AS
BEGIN
	IF WriteAccessAllowed(in_act_id, in_role_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Access denied writing to role with sid '||in_role_sid);
	END IF;

	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_role_sid);
		out_added := TRUE;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			out_added := FALSE;
	END;
END;

PROCEDURE INTERNAL_AddGroupMember(
	in_act_id		IN Security_Pkg.T_ACT_ID,
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_role_sid		IN Security_Pkg.T_SID_ID
)
AS
	v_result BOOLEAN := FALSE;
BEGIN
	INTERNAL_AddGroupMember(in_act_id, in_member_sid, in_role_sid, v_result);
END;


PROCEDURE INTERNAL_DeleteGroupMember(
	in_act_id				IN Security_Pkg.T_ACT_ID,
	in_member_sid			IN Security_Pkg.T_SID_ID,
    in_role_sid				IN Security_Pkg.T_SID_ID,
    in_check_permissions	IN BOOLEAN := TRUE
)
AS
BEGIN
	IF in_check_permissions AND WriteAccessAllowed(in_act_id, in_role_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Access denied writing to role with sid '||in_role_sid);
	END IF;

	DELETE FROM security.group_members
     WHERE member_sid_id = in_member_sid
       AND group_sid_id = in_role_sid;
END;

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
	IF IsRoleSystemManaged(in_sid_id) = 1 AND NOT CanAlterSystemManagedRole THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot rename a system managed role. Role sid:'||in_sid_id);
	END IF;

	IF in_new_name IS NOT NULL THEN
		UPDATE role
		   SET name = in_new_name
		 WHERE role_sid = in_sid_id;
	END IF;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_app_sid	security_pkg.T_SID_ID;
	v_name		role.name%TYPE;
BEGIN
	IF IsRoleSystemManaged(in_sid_id) = 1 AND NOT CanAlterSystemManagedRole THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot delete a system managed role. Role sid:'||in_sid_id);
	END IF;

	SELECT app_sid, name
	  INTO v_app_sid, v_name
	  FROM role
	 WHERE role_sid = in_sid_id;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid,
		v_app_sid, 'Deleted role "{0}"', v_name);

 	-- clean up
 	DELETE FROM QS_EXPR_NC_ACTION_INVOLVE_ROLE
 	 WHERE involve_role_sid = in_sid_id;

 	DELETE FROM DELEGATION_ROLE
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM deleg_plan_role
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM flow_transition_alert_role
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM flow_state_transition_role
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM flow_state_role_capability
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM flow_state_role
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM role_grant
 	 WHERE role_sid = in_sid_id;

 	DELETE FROM role_grant
 	 WHERE grant_role_sid = in_sid_id;

 	DELETE FROM role_user_cover
 	 WHERE role_sid = in_sid_id;

	DELETE FROM audit_type_expiry_alert_role
	 WHERE role_sid = in_sid_id;

 	DELETE FROM REGION_ROLE_MEMBER
 	 WHERE role_sid = in_sid_id;

	-- delete date schedules
	FOR r IN (
		SELECT delegation_date_schedule_id
		  FROM deleg_plan_date_schedule
		 WHERE role_sid = in_sid_id
	) LOOP
		DELETE FROM deleg_plan_date_schedule
		 WHERE delegation_date_schedule_id = r.delegation_date_schedule_id;

		DELETE FROM sheet_date_schedule
		 WHERE delegation_date_schedule_id = r.delegation_date_schedule_id;

		DELETE FROM delegation_date_schedule
		 WHERE delegation_date_schedule_id = r.delegation_date_schedule_id;
	END LOOP;

	DELETE FROM ISSUE_INVOLVEMENT
 	 WHERE role_sid = in_sid_id;

	DELETE FROM meter_tab_group
	 WHERE role_sid = in_sid_id;

	DELETE FROM compliance_permit_tab_group
	 WHERE role_sid = in_sid_id;

 	DELETE FROM role
 	 WHERE role_sid = in_sid_id;

 	chain.filter_pkg.ClearCacheForAllUsers;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE GrantRole(
	in_role_sid				IN	security_pkg.T_SID_ID,
	in_grant_role_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the role with sid '||in_role_sid);
	END IF;
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the role with sid '||in_grant_role_sid);
	END IF;

	BEGIN
		INSERT INTO role_grant
			(role_sid, grant_role_sid)
		VALUES
			(in_role_sid, in_grant_role_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- already exists
	END;
END;

PROCEDURE GetRoleGrants(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rg.role_sid, rg.grant_role_sid, CONNECT_BY_ROOT rrm.region_sid region_sid
		  FROM csr.role_grant rg
			LEFT JOIN csr.region_role_member rrm
			    ON rg.app_sid = rrm.app_sid
			   AND rg.role_sid = rrm.role_sid
			   AND rrm.inherited_from_sid = rrm.region_sid
			   -- XXX: If we don't restrict this to the sid of the logged on user then the logged on
			   -- user will be able to assign roles granted to them to any region that any other user
			   -- on the system, who also happens to be in the role that is the source of the grant,
			   -- is associated with through that role. This restriction is to prevent escalation of
			   -- privileges to regions with which the logged on user is not associated via any role,
			   -- although this restriction isn't quite in-line with the original wording of the spec.
	 	 	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  	START WITH rg.role_sid IN (
		  		SELECT group_sid_id
		          FROM security.group_members
		            START WITH member_sid_id = SYS_CONTEXT('SECURITY', 'SID')
		            CONNECT BY NOCYCLE PRIOR group_sid_id = member_sid_id)
		  	CONNECT BY NOCYCLE PRIOR rg.grant_role_sid = rg.role_sid
		;
END;

PROCEDURE GetRoles(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading csr root sid '||in_app_sid);
	END IF;

 	OPEN out_cur FOR
 		SELECT role_sid, name, lookup_key, is_property_manager, is_metering, is_delegation,
		       is_supplier, is_system_managed
 		  FROM role r
 		 WHERE app_sid = in_app_sid
		   AND is_hidden = 0
 		 ORDER BY name;
END;

PROCEDURE GetRoles(
	in_is_metering			IN	role.is_metering%TYPE,
	in_is_property_manager	IN	role.is_property_manager%TYPE,
	in_is_supplier			IN	role.is_supplier%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, security_pkg.getApp, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading csr root sid '||security_pkg.getApp);
	END IF;

 	OPEN out_cur FOR
 		SELECT role_sid, name, lookup_key, is_property_manager, is_metering, is_delegation,
		       is_supplier, is_system_managed
 		  FROM role
 		 WHERE app_sid = security_pkg.getApp
 		   AND (is_metering = in_is_metering oR in_is_metering IS NULL)
 		   AND (is_property_manager = in_is_property_manager oR in_is_property_manager IS NULL)
 		   AND (is_supplier = in_is_supplier oR in_is_supplier IS NULL)
 		 ORDER BY name;
END;

PROCEDURE GetRole(
	in_role_sid				IN	security_pkg.T_SID_ID,
	out_role_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_roots_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, security_pkg.getApp, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading csr root sid '||security_pkg.getApp);
	END IF;

	OPEN out_role_cur FOR
 		SELECT role_sid, name, lookup_key, is_property_manager, is_metering, is_delegation,
		       is_supplier, is_system_managed
 		  FROM role
 		 WHERE app_sid = security_pkg.getApp
 		   AND role_sid = in_role_sid;

 	OPEN out_roots_cur FOR
 		SELECT region_sid
 		  FROM region_role_member rrm
 		 WHERE app_sid = security_pkg.getApp
 		   AND role_sid = in_role_sid
 		   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
 		   AND inherited_from_sid = region_sid; -- and NOT inherited

END;

-- Legacy behaviour, does not include inherited roles
PROCEDURE GetRoleMembersForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid		security_pkg.T_SID_ID;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||in_region_sid);
	END IF;

	-- The way the UI works at the moment the input region sid will never be a
	-- link, if that changes in the future we should be able to cope with it.
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

 	OPEN out_cur FOR
 		SELECT r.role_sid, r.name role_name, r.lookup_key, rrm.user_sid, cu.full_name, cu.user_name, cu.email
 		  FROM role r, region_role_member rrm, csr_user cu
	 LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
 		 WHERE r.role_sid = rrm.role_sid
 		   AND rrm.user_Sid = cu.csr_user_sid
 		   AND rrm.region_sid = v_region_sid
 		   AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
		   AND t.trash_sid IS NULL -- and user is not deleted
 		 ORDER BY role_name, full_name;
END;

-- Gets everything, including inherited roles
PROCEDURE GetAllRoleMembersForRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid		security_pkg.T_SID_ID;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||in_region_sid);
	END IF;

 	-- The way the UI works at the moment the input region sid will never be a
	-- link, if that changes in the future we should be able to cope with it.
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

 	OPEN out_cur FOR
 		SELECT DISTINCT r.role_sid, r.name role_name, r.lookup_key, rrm.user_sid, cu.full_name, cu.user_name, cu.email,
				CASE
					WHEN rrm.inherited_from_sid = v_region_sid THEN 0
					ELSE 1
				END is_inherited
 		  FROM role r, region_role_member rrm, csr_user cu
	 LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
 		 WHERE r.role_sid = rrm.role_sid
 		   AND rrm.user_Sid = cu.csr_user_sid
 		   AND rrm.region_sid = v_region_sid
		   AND t.trash_sid IS NULL -- and user is not deleted
 		 ORDER BY role_name, full_name;
END;

-- Legacy behaviour, does not include inherited roles
PROCEDURE GetRoleMembersForUser(
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRoleMembersForUser(
		security_pkg.GetACT,
		in_user_sid,
		out_cur
	);
END;

PROCEDURE GetRoleMembersForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_tree_root				region.region_sid%TYPE;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||in_user_sid);
	END IF;

 	SELECT region_root_sid
 	  INTO v_region_tree_root
 	  FROM customer;

 	-- The region_role_member table should never contain references to regions
 	-- that are links, they should have been resolved before going into the table.
 	OPEN out_cur FOR

		SELECT x.role_sid, x.role_name, x.lookup_key, x.region_sid, x.region_description, y.path region_path
		  FROM (
			SELECT DISTINCT r.role_sid, r.name role_name, r.lookup_key, reg.region_sid, reg.description region_description
			  FROM role r
				JOIN region_role_member rrm ON r.role_sid = rrm.role_sid AND r.app_sid = rrm.app_sid AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
				JOIN v$region reg ON rrm.region_sid = reg.region_sid AND rrm.app_Sid = reg.app_sid
			 WHERE rrm.user_Sid = in_user_sid
			   AND r.is_hidden = 0
		  )x JOIN (SELECT r.region_sid, REPLACE(SUBSTR(SYS_CONNECT_BY_PATH(REPLACE(r.description, CHR(1), '_'), ''), 2), '', ' / ') path
				   FROM v$region r
				  START WITH parent_sid = v_region_tree_root
				CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
		  )y ON x.region_sid = y.region_sid
		ORDER BY role_name, region_description;
END;

PROCEDURE GetGrantRoleMembersForUser(
	in_user_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_count							NUMBER;
	v_region_tree_root				region.region_sid%TYPE;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||security_pkg.GetSID);
	END IF;

 	SELECT region_root_sid
 	  INTO v_region_tree_root
 	  FROM customer;

 	-- The region_role_member table should never contain references to regions
 	-- that are links, they should have been resolved before going into the table.

 	INTERNAL_PrepGrantRegionCheck;

 	OPEN out_cur FOR
		SELECT DISTINCT r.role_sid, r.name role_name, r.lookup_key, reg.region_sid, reg.description region_description,
				(SELECT REPLACE(SUBSTR(SYS_CONNECT_BY_PATH(REPLACE(r.description, CHR(1), '_'), ''), 2), '', ' / ') path
				   FROM v$region r
				  WHERE r.region_sid = rrm.region_sid
						START WITH parent_sid = v_region_tree_root
						CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid) region_path
		  FROM role r, region_role_member rrm, v$region reg, temp_role_region gr
		 WHERE r.role_sid = rrm.role_sid
		   AND r.is_hidden = 0
		   AND rrm.user_sid = in_user_sid
		   AND rrm.region_sid = reg.region_sid
		   AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
		   AND gr.role_sid = rrm.role_sid
		   AND gr.region_sid = rrm.region_sid
	 		ORDER BY role_name, region_description;
END;

-- Gets everything, including inherited roles
PROCEDURE GetAllRoleMembersForUser(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check for permissions on user sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading user sid '||in_user_sid);
	END IF;

 	-- The region_role_member table should never contain references to regions
 	-- that are links, they should have been resolved before going into the table.

 	OPEN out_cur FOR
		SELECT r.role_sid, r.name role_name, r.lookup_key, reg.region_sid, reg.description region_description
		  FROM role r, region_role_member rrm, v$region reg
		 WHERE r.role_sid = rrm.role_sid
		   --AND r.is_hidden = 0 --should this get the hidden roles too ?
		   AND rrm.user_Sid = in_user_sid
		   AND rrm.region_sid = reg.region_sid
	 		ORDER BY role_name,region_description;
END;

-- TODO: rename to "ByName"?
FUNCTION GetRoleID(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE
) RETURN role.role_sid%TYPE
AS
	v_role_sid	role.role_sid%TYPE;
BEGIN
	BEGIN
		SELECT role_sid
		  INTO v_role_sid
		  FROM role
		 WHERE app_sid = in_app_sid
		   AND LOWER(name) = LOWER(in_role_name);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_role_sid := null;
	END;
	RETURN v_role_sid;
END;

FUNCTION GetRoleIdByKey (
	in_lookup_key					IN  role.lookup_key%TYPE
) RETURN role.role_sid%TYPE
AS
	v_role_sid	role.role_sid%TYPE;
BEGIN
	BEGIN
		SELECT role_sid
		  INTO v_role_sid
		  FROM role
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(lookup_key) = LOWER(in_lookup_key);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_role_sid := null;
	END;
	RETURN v_role_sid;
END;

--Gets a list of all role memberships for the site.
--TODO - This should support filtering by role, user and region start point
PROCEDURE GetAllRoleMemberships(
	out_cur		OUT SYS_REFCURSOR
)
AS
BEGIN

	OPEN out_cur FOR
    SELECT r.ROLE_SID, r.name role_name, cu.FULL_NAME, cu.CSR_USER_SID, cu.user_name, cu.EMAIL, reg.DESCRIPTION region_description, reg.REGION_SID, reg.path, su.ACCOUNT_ENABLED active
		  FROM csr.REGION_ROLE_MEMBER rrm
		  JOIN csr.role r 		ON rrm.ROLE_SID 	= r.ROLE_SID
		  JOIN csr.csr_user cu 	ON rrm.USER_SID 	= cu.CSR_USER_SID AND NOT EXISTS( SELECT NULL FROM csr.TRASH WHERE TRASH_SID = cu.CSR_USER_SID)
		  JOIN (
				SELECT region_sid, description, REPLACE(LTRIM(sys_connect_by_path(description, ''),''),'',' > ') path
				   FROM csr.v$region

				 START WITH region_sid IN (
					SELECT region_tree_root_sid FROM csr.region_tree -- any tree
				 )
				 CONNECT BY PRIOR region_sid = parent_sid
		  ) reg ON rrm.region_sid = reg.region_sid
		  JOIN security.USER_TABLE su ON cu.CSR_USER_SID  = su.SID_ID
		 WHERE rrm.app_sid 				= SYS_CONTEXT('SECURITY', 'APP')
		   AND rrm.INHERITED_FROM_SID	= rrm.REGION_SID
		 ORDER BY rrm.ROLE_SID ASC;
END;

PROCEDURE SetRole(
	in_role_name					IN 	role.name%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
)
AS
BEGIN
	SetRole(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), in_role_name, NULL, out_role_sid);
END;

PROCEDURE SetRole(
	in_role_name					IN 	role.name%TYPE,
	in_lookup_key					IN 	role.lookup_key%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
)
AS
BEGIN
	SetRole(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), in_role_name, in_lookup_key, out_role_sid);
END;

PROCEDURE SetRole(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		    IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE,
	out_role_sid		OUT	role.role_sid%TYPE
)
AS
BEGIN
	SetRole(in_act_id, in_app_sid, in_role_name, NULL, out_role_sid);
END;

PROCEDURE SetRole(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid		    IN	security_pkg.T_SID_ID,
	in_role_name		IN	role.name%TYPE,
	in_lookup_key		IN 	role.lookup_key%TYPE,
	out_role_sid		OUT	role.role_sid%TYPE
)
AS
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
BEGIN

	BEGIN
		v_class_id := class_pkg.GetClassId('CSRRole');
        v_groups_sid := securableobject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'Groups');

        -- this will check permissions on the Groups node
        group_pkg.CreateGroupWithClass(in_act_id, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
            REPLACE(in_role_name,'/','\'), v_class_id, out_role_sid); --'

        -- in theory the create object will fail with duplicate_object_name, but to be safe we also
        -- have a unique constraint on the role table.
		INSERT INTO role
			(role_sid, app_sid, name, lookup_key)
		VALUES
			(out_role_sid, in_app_sid, in_role_name, in_lookup_key);

		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid,
			in_app_sid, 'Created role "{0}"', in_role_name);

    EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			out_role_sid := null;
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_role_sid := null;
	END;

	IF out_role_sid IS NULL THEN
		UPDATE role
		   SET name = in_role_name,
	        lookup_key = NVL(in_lookup_key, lookup_key)
		 WHERE UPPER(name) = UPPER(in_role_name)
		   AND app_sid = in_app_sid
		 RETURNING role_sid INTO out_role_sid;


		--check permission....
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid,  csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
		END IF;
	END IF;
END;

PROCEDURE UpdateRole(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_new_name		IN	security_pkg.T_SO_NAME,
	in_lookup_key	IN	csr.role.lookup_key%TYPE,
	in_grant_sids	IN	security_pkg.T_SID_IDS
)
AS
BEGIN
	
	csr.role_pkg.UpdateRole(
		in_role_sid			=> in_role_sid,
		in_role_name		=> in_new_name,
		in_lookup_key		=> in_lookup_key
	);
	
	-- Set granted role members
	csr.role_pkg.SetRoleGrantedRoleMembers(
		in_role_sid		=> in_role_sid,
		in_grant_sids	=> in_grant_sids
	);

END;

PROCEDURE UpdateRole(
	in_role_sid						IN	role.role_sid%TYPE,
	in_role_name					IN 	role.name%TYPE,
	in_lookup_key					IN 	role.lookup_key%TYPE
)
AS
	v_role_name						role.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), csr_data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	SELECT name 
	  INTO v_role_name
	  FROM role
	 WHERE role_sid = in_role_sid;

	IF in_role_name IS NOT NULL AND v_role_name != in_role_name THEN
		csr_data_pkg.AuditValueChange(
			SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, SYS_CONTEXT('SECURITY', 'APP'), 
			in_role_sid, 'Name', v_role_name, in_role_name
		);
			
		securableobject_pkg.RenameSO(SYS_CONTEXT('SECURITY', 'ACT'), in_role_sid, REPLACE(in_role_name,'/','\')); --'
	END IF;

	UPDATE role
	   SET name = NVL(in_role_name, name),
	       lookup_key = NVL(in_lookup_key, lookup_key)
	 WHERE role_sid = in_role_sid;
END;

PROCEDURE SetRoleFlags(
	in_role_sid					IN	role.role_sid%TYPE,
	in_is_metering					IN	role.is_metering%TYPE DEFAULT NULL,
	in_is_property_manager			IN	role.is_property_manager%TYPE DEFAULT NULL,
	in_is_delegation				IN	role.is_delegation%TYPE DEFAULT NULL,
	in_is_supplier					IN	role.is_supplier%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(
			security_pkg.GetAct,
			security_pkg.GetApp,
			csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;

	UPDATE role SET
		is_metering					= NVL(in_is_metering, is_metering),
		is_property_manager			= NVL(in_is_property_manager, is_property_manager),
		is_delegation				= NVL(in_is_delegation, is_delegation),
		is_supplier					= NVL(in_is_supplier, is_supplier)
	WHERE role_sid = in_role_sid;
END;

-- this could be rather slow! We could make it more efficient by poking the ACL table
-- directly I guess. Also we could track the changes more carefully -- this assumes
-- that we have no idea of the state, so we remove everything reapply.
-- XXX: Not referenced by anything?
PROCEDURE ResynchACEs(
	in_act_id		security_pkg.T_ACT_ID,
	in_role_sid		security_pkg.T_SID_ID
)
AS
	v_region_dacl_id 			security_Pkg.T_ACL_ID;
BEGIN
	-- remove the ACEs that have been set for this role across the region tree
	FOR r IN (
		-- get all the users and regions that this role has things to do with
		SELECT user_sid, Acl_Pkg.GetDACLIDForSID(region_sid) dacl_id
		  FROM (
			SELECT DISTINCT user_sid, region_sid
			  FROM region_role_member
			 WHERE role_sid = in_role_sid
			   AND inherited_from_sid = region_sid
		)
	)
	LOOP
		acl_pkg.RemoveACEsForSid(in_act_id, r.dacl_id, r.user_sid);
	END LOOP;

	-- TODO: what if it's a "starting point"? shouldn't we then go and add these individual permissions too?
	-- now add back a bunch of ACEs
	FOR r IN (
		-- get all the roles, users and regions that this role has things to do with
		SELECT region_sid, user_sid, region_permission_set, Acl_Pkg.GetDACLIDForSID(region_sid) region_dacl_id
		  FROM (
			SELECT DISTINCT rrm.region_sid, rrm.user_sid, role.region_permission_set
			  FROM region_role_member rrm
				JOIN role ON rrm.role_sid = role.role_sid
			  WHERE rrm.region_sid IN (
				SELECT DISTINCT region_sid
				  FROM region_role_member
				 WHERE role_sid = in_role_sid
				   AND inherited_from_sid = region_sid
			   )
			   AND role.region_permission_set IS NOT NULL
		)
	)
	LOOP
		-- add an ACE and propagate it down
		acl_pkg.AddACE(in_act_id, r.region_dacl_id, security_pkg.ACL_INDEX_LAST,
			security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			r.user_sid, r.region_permission_set);
	END LOOP;

	-- propagate down all the regions we touched
	FOR r IN (
		-- get all the regions that this role has things to do with
		SELECT DISTINCT region_sid
		  FROM region_role_member
		 WHERE role_sid = in_role_sid
		   AND inherited_from_sid = region_sid
	)
	LOOP
		acl_pkg.PropogateACEs(in_act_id, r.region_sid);
	END LOOP;
END;

-- always use order Role, Region, User for consistency
PROCEDURE LogRoleChange(
	in_log_type			IN	audit_log.audit_type_id%TYPE,
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_csr_user_sid		IN	security_pkg.T_SID_ID,
	in_region_log_msg	IN	audit_log.description%TYPE,
	in_user_log_msg		IN	audit_log.description%TYPE
)
AS
	v_role_name				role.name%TYPE;
	v_region_description	region_description.description%TYPE;
	v_user_name				csr_user.full_name%TYPE;
BEGIN
	/*
	  FB97924: It confuses everyone when the audit shows log entries for role removals for regions that have been deleted.
	  Roles aren't currently trashed (they're just deleted), but if they ever get changed to be trashed, this will have
	  to change to include "trash_pkg.IsInTrash(security_pkg.GetACT, in_role_sid) = 1".
	*/
	IF trash_pkg.IsInTrashHierarchical(security_pkg.GetACT, in_region_sid) = 1
	THEN
		RETURN;
	END IF;


	SELECT name
	  INTO v_role_name
	  FROM role
	 WHERE role_sid = in_role_sid;

	-- role name is not useful; description is
	SELECT NVL(description, '-')
	  INTO v_region_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	-- use user_name instead of full_name because it's more stable (the users can't change it themselves)
	SELECT user_name
	  INTO v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_csr_user_sid;

	-- log to region
	csr_data_pkg.WriteAuditLogEntry(
		security_pkg.GetACT,
		in_log_type,
		security_pkg.GetAPP,
		in_region_sid,
		in_region_log_msg,
		v_role_name,
		v_user_name);

	-- log to user
	csr_data_pkg.WriteAuditLogEntry(
		security_pkg.GetACT,
		in_log_type,
		security_pkg.GetAPP,
		in_csr_user_sid,
		in_user_log_msg,
		v_role_name,
		v_region_description,
		in_region_sid);
END;

PROCEDURE LogRoleDelete(
	in_log_type		IN	audit_log.audit_type_id%TYPE,
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_csr_user_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	LogRoleChange(
		in_log_type,
		in_role_sid,
		in_region_sid,
		in_csr_user_sid,
		'Removed {1} from role {0}',
		'Removed from role {0}, region {1} ({2})');
END;

PROCEDURE UNSEC_LogRoleDeleteOnDeact(
	in_app_sid		IN	security_pkg.T_SID_ID,
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_csr_user_sid	IN	security_pkg.T_SID_ID
)
AS
	v_user_performing_change	security_pkg.T_SID_ID;
	v_role_name					role.name%TYPE;
	v_region_description		region.name%TYPE;
	v_user_name					csr_user.full_name%TYPE;
BEGIN

	SELECT name
	  INTO v_role_name
	  FROM role
	 WHERE role_sid = in_role_sid;

	-- role name is not useful; description is
	SELECT NVL(description, '-')
	  INTO v_region_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	-- use user_name instead of full_name because it's more stable (the users can't change it themselves)
	SELECT user_name
	  INTO v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_csr_user_sid;

	BEGIN
		user_pkg.GetSid(security_pkg.getACT, v_user_performing_change);
	EXCEPTION
		WHEN security_Pkg.NOT_LOGGED_ON THEN
			v_user_performing_change := security_pkg.SID_BUILTIN_ADMINISTRATOR;
	END;

	-- log to user
	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_performing_change,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED,
		in_app_sid => in_app_sid,
		in_object_sid => in_csr_user_sid,
		in_description => 'Removed from role {0}, region {1} ({2}) on user deactivation.',
		in_param_1 => v_role_name,
		in_param_2 => v_region_description,
		in_param_3 => in_region_sid
	);

	-- log to region
	csr_data_pkg.WriteAuditLogEntryForSid(
		in_sid_id => v_user_performing_change,
		in_audit_type_id => csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED,
		in_app_sid => in_app_sid,
		in_object_sid => in_region_sid,
		in_description => 'Removed {1} from role {0} on user deactivation.',
		in_param_1 => v_role_name,
		in_param_2 => v_user_name
	);
END;

PROCEDURE LogRoleInsert(
	in_log_type		IN	audit_log.audit_type_id%TYPE,
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_csr_user_sid	IN	security_pkg.T_SID_ID,
	in_reason		IN  VARCHAR2 DEFAULT NULL
)
AS
BEGIN
	LogRoleChange(
		in_log_type,
		in_role_sid,
		in_region_sid,
		in_csr_user_sid,
		'Added {1} to role {0}',
		COALESCE(in_reason, 'Added to role {0}, region {1} ({2})')
		);
END;

PROCEDURE AddRoleMemberForRegion(
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0
)
AS
BEGIN
	AddRoleMemberForRegion(SYS_CONTEXT('SECURITY', 'ACT'), in_role_sid, in_region_sid, in_user_sid, in_log);

END;

PROCEDURE AddRoleMemberForRegion(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0,
	in_force_alter_system_managed	IN NUMBER DEFAULT 0,
	in_inherited_from_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for region sid '||in_region_sid);
	END IF;

	AddRoleMemberForRegion_UNSEC(in_act_id, in_role_sid, in_region_sid, in_user_sid, in_log, in_force_alter_system_managed, in_inherited_from_sid);
END;

PROCEDURE AddRoleMemberForRegion_UNSEC(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID,
	in_log			IN  NUMBER DEFAULT 0,
	in_force_alter_system_managed	IN NUMBER DEFAULT 0,
	in_inherited_from_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_region_dacl_id 			security_Pkg.T_ACL_ID;
	v_region_sid				security_pkg.T_SID_ID;
	v_region_permission_set		security_pkg.T_PERMISSION;
	v_membership_changed		BOOLEAN := FALSE;
BEGIN
	IF in_force_alter_system_managed = 0 AND IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	-- The way the UI works at the moment the input region sid will never be a
	-- link, if that changes in the future we should be able to cope with it.
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	-- make sure user belongs to the security group
	INTERNAL_AddGroupMember(in_act_id, in_user_sid, in_role_sid, v_membership_changed); -- add to role

	-- grant this user any permission specified
	SELECT region_permission_set
	  INTO v_region_permission_set
	  FROM role
	 WHERE role_sid = in_role_sid;

	IF v_region_permission_set IS NOT NULL THEN
		-- add an ACE and propagate it down
		v_region_dacl_id := Acl_Pkg.GetDACLIDForSID(v_region_sid);
		acl_pkg.AddACE(in_act_id, v_region_dacl_id, security_pkg.ACL_INDEX_LAST,
			security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			in_user_sid, v_region_permission_set);
		acl_pkg.PropogateACEs(in_act_id, v_region_sid);
	END IF;

	IF in_log = 1 AND v_membership_changed THEN
		LogRoleInsert(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, v_region_sid, in_user_sid,
			'Region role membership added for role "{0}", user "'||in_user_sid||'" at region "{1}" ({2})');
	END IF;

    BEGIN
    	FOR r IN (
    		SELECT NVL(link_to_region_sid, region_sid) region_sid
          	  FROM region
          	  	START WITH region_sid = v_region_sid
          	  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
    	) LOOP
    		BEGIN
		        INSERT INTO region_role_member
		        	(role_sid, region_sid, user_sid, inherited_from_sid)
				  VALUES
				  	(in_role_sid, r.region_sid, in_user_sid, NVL(in_inherited_from_sid, v_region_sid));

				IF in_log = 1 THEN
					LogRoleInsert(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, r.region_sid, in_user_sid,
						'Region role membership added for role "{0}", user "'||in_user_sid||'" at region "{1}" ({2}), inherited from region "'||v_region_sid||'"');
				END IF;

		    EXCEPTION
		        WHEN DUP_VAL_ON_INDEX THEN
		            NULL; -- ignore if it's already in there
			END;
		END LOOP;
    END;

	chain.filter_pkg.ClearCacheForUser (
		in_user_sid => in_user_sid
	);
END;

PROCEDURE UNSEC_DeleteRegionRoleMember(
	in_act_id				IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_role_sid				IN	role.role_sid%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_log					IN	NUMBER DEFAULT 0,
	in_check_permissions	IN	BOOLEAN DEFAULT FALSE
)
AS
	v_role_member_count	NUMBER;
BEGIN

	DELETE FROM region_role_member
	 WHERE role_sid = in_role_sid
	   AND inherited_from_sid = in_region_sid  -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.
	   AND user_sid = in_user_sid;

	IF SQL%ROWCOUNT > 0 THEN
		SELECT COUNT(*)
		  INTO v_role_member_count
		  FROM csr.region_role_member
		 WHERE role_sid = in_role_sid
		   AND user_sid = in_user_sid;

		--If the user is no longer a member of this role, delete him from the group too
		IF v_role_member_count =  0 THEN
			INTERNAL_DeleteGroupMember(in_act_id, in_user_sid, in_role_sid, in_check_permissions);
		END IF;

		IF in_log = 1 THEN
			-- log the removal
			LogRoleDelete(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, in_region_sid, in_user_sid);
		END IF;

		chain.filter_pkg.ClearCacheForUser (
			in_user_sid => in_user_sid
		);
	END IF;
END;

PROCEDURE DeleteRegionRoleMember(
	in_act_id		IN	security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_log			IN NUMBER DEFAULT 0,
	in_force_alter_system_managed IN NUMBER DEFAULT 0
)
AS
	v_role_member_count	NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for region sid'||in_region_sid);
	END IF;

	IF in_force_alter_system_managed = 0 AND IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	UNSEC_DeleteRegionRoleMember(
		in_role_sid		=> in_role_sid,
		in_region_sid	=> in_region_sid,
		in_user_sid		=> in_user_sid,
		in_log			=> in_log,
		in_check_permissions => TRUE
	);
END;

PROCEDURE DeleteRolesFromRegionForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID
)
AS
	v_user_name				csr_user.full_name%TYPE;
	v_region_description	region.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for region sid'||in_region_sid);
	END IF;
	--todo:
	DELETE FROM region_role_member
	 WHERE user_sid = in_user_sid
	   AND inherited_from_sid = in_region_sid;

	-- use user_name instead of full_name because it's more stable (the users can't change it themselves)
	SELECT user_name
	  INTO v_user_name
	  FROM csr_user
	 WHERE csr_user_sid = in_user_sid;

	-- role name is not useful; description is
	SELECT NVL(description, '-')
	  INTO v_region_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	--Audit the change

	-- log to region
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id,
		csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED,
		security_pkg.GetAPP,
		in_region_sid,
		'Removed {0} from all roles on region',
		v_user_name);

	-- log to user
	csr_data_pkg.WriteAuditLogEntry(
		in_act_id,
		csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED,
		security_pkg.GetAPP,
		in_user_sid,
		'Removed from all roles on region {0} ({1})',
		v_region_description,
		in_region_sid);

	chain.filter_pkg.ClearCacheForUser (
		in_user_sid => in_user_sid
	);
END;

PROCEDURE DeleteRegionsFromRoleForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_role_sid		IN	security_pkg.T_SID_ID
)
AS
	v_user_name				csr_user.full_name%TYPE;
	v_region_description	region.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for user sid'||in_user_sid);
	END IF;

	IF IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	FOR r IN (
		SELECT region_sid
		  FROM region_role_member
		 WHERE user_sid = in_user_sid
		   AND role_sid = in_role_sid
		   AND inherited_from_sid = region_sid
	)
	LOOP
		DeleteRegionRoleMember(in_act_id, in_role_sid, r.region_sid, in_user_sid, 1);
	END LOOP;
END;

PROCEDURE UNSEC_DeleteAllRolesFromUser(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_include_system_managed	IN NUMBER DEFAULT 0
)
AS
	v_act_id					security_pkg.T_ACT_ID;
BEGIN

	-- Remove user from groups with roles granted
	FOR r IN (
		SELECT role_sid
		  FROM role
		 WHERE app_sid = in_app_sid
		   AND (in_include_system_managed = 1 OR (in_include_system_managed = 0 AND is_system_managed = 0)))
	LOOP
		INTERNAL_DeleteGroupMember(v_act_id, in_user_sid, r.role_sid, FALSE);
	END LOOP;

	-- Logging top region roles only
	FOR res IN (
		SELECT rr.region_sid, rr.role_sid
		  FROM region_role_member rr
		  JOIN role r ON rr.role_sid = r.role_sid
		 WHERE r.app_sid = in_app_sid
		   AND rr.user_sid = in_user_sid
		   AND rr.region_sid = rr.inherited_from_sid
		   AND (in_include_system_managed = 1 OR (in_include_system_managed = 0 AND r.is_system_managed = 0)))
	LOOP
		UNSEC_LogRoleDeleteOnDeact(in_app_sid, res.role_sid, res.region_sid, in_user_sid);
	END LOOP;

	DELETE FROM region_role_member
	 WHERE app_sid = in_app_sid
	   AND user_sid = in_user_sid
	   AND role_sid IN ( SELECT role_sid
						   FROM role
						  WHERE app_sid = in_app_sid
							AND (in_include_system_managed = 1 OR (in_include_system_managed = 0 AND is_system_managed = 0)));

	UPDATE csr_user
	   SET remove_roles_on_deactivation = 0
	 WHERE app_sid = in_app_sid
	   AND csr_user_sid = in_user_sid;

	chain.filter_pkg.ClearCacheForUser (
		in_user_sid => in_user_sid
	);
END;

PROCEDURE DeleteAllRolesFromUser(
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_include_system_managed	IN NUMBER DEFAULT 0
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for user sid'||in_user_sid);
	END IF;

	UNSEC_DeleteAllRolesFromUser(security_Pkg.getApp, in_user_sid, in_include_system_managed);
END;

-- TODO: Set ACLs
PROCEDURE SetRoleMembersForRegion(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_user_sids	IN	security_pkg.T_SID_IDS
)AS
	v_region_sid	security_pkg.T_SID_ID;
	v_current_ids 	security_pkg.T_SID_IDS;
	v_insert_ids 	security_pkg.T_SID_IDS;
	v_tids			security.T_SID_TABLE;
	t_user_sids		security.T_SID_TABLE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for region sid'||in_region_sid);
	END IF;

	IF IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	-- The way the UI works at the moment the input region sid will never be a
	-- link, if that changes in the future we should be able to cope with it.
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	IF in_user_sids.COUNT = 1 AND in_user_sids(in_user_sids.FIRST) IS NULL THEN
		-- hack for ODP.NET which doesn't support empty arrays - just delete everything

		-- log the removal for each user
		FOR r IN (
			SELECT user_sid
			  FROM region_role_member
			 WHERE role_sid = in_role_sid
			   AND region_sid = v_region_sid
			   AND inherited_from_sid = region_sid
		)
		LOOP
			LogRoleDelete(csr_data_pkg.AUDIT_TYPE_REGION_ROLE_CHANGED, in_role_sid, in_region_sid, r.user_sid);
		END LOOP;

		-- remove users from group if they don't have any other RRMs
		FOR r IN (
			SELECT DISTINCT user_sid
			  FROM region_role_member rrm
			 WHERE role_sid = in_role_sid
			   AND region_sid = v_region_sid
			   AND inherited_from_sid = region_sid
			   AND NOT EXISTS (
				SELECT *
				  FROM region_role_member x
				 WHERE x.app_sid = rrm.app_sid
				   AND x.user_sid = rrm.user_sid
				   AND x.role_sid = in_role_sid
				   AND x.inherited_from_sid != rrm.inherited_from_sid
			   )
		) LOOP
			group_pkg.DeleteMember(in_act_id, r.user_sid, in_role_sid);
		END LOOP;

		DELETE FROM REGION_ROLE_MEMBER
		 WHERE role_sid = in_role_sid
		   AND inherited_from_sid = v_region_sid; -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.
	ELSE
		-- PL/SQL associative arrays (index-by tables) are sparse,
		-- so select all existing stuff for easy lookup
		FOR r IN (
			SELECT user_sid
			  FROM region_role_member
			 WHERE role_sid = in_role_sid
			   AND region_sid = v_region_sid
			   AND inherited_from_sid = region_sid -- and NOT inherited
		)
		LOOP
			v_current_ids(r.user_sid) := r.user_sid;
		END LOOP;

		-- go through each ID that we want to set
		FOR i IN in_user_sids.FIRST .. in_user_sids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_user_sids(i)) THEN
				-- remove from current_ids so we don't try to delete
				v_current_ids.DELETE(in_user_sids(i));
			ELSE
				-- mark for insertion
				v_insert_ids(v_insert_ids.COUNT+1) := in_user_sids(i);
                -- make sure user belongs to the security group
                INTERNAL_AddGroupMember(in_act_id, in_user_sids(i), in_role_sid); -- add to role
			END IF;
		END LOOP;

		-- delete what we don't want
		FORALL i IN INDICES OF v_current_ids
			DELETE FROM region_role_member
			 WHERE role_sid = in_role_sid
			   AND inherited_from_sid = v_region_sid -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.
			   AND user_sid = v_current_ids(i);

		-- Get the user ids to be inserted as a table
		v_tids := security_pkg.SidArrayToTable(v_insert_ids);

		-- insert the new rows for each region
		FOR r IN (
			SELECT NVL(link_to_region_sid, region_sid) region_sid
			  FROM region
				START WITH region_sid = v_region_sid
				CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		)
		LOOP
			BEGIN
				INSERT INTO region_role_member
				  (role_sid, region_sid, user_sid, inherited_from_sid)
					SELECT in_role_sid, r.region_sid, column_value, v_region_sid
					  FROM TABLE(v_tids);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL; -- ignore if it's already in there
			END;
		END LOOP;

		-- log the addition at the top-level region
		IF v_insert_ids.COUNT > 0 THEN
			FOR i IN v_insert_ids.FIRST .. v_insert_ids.LAST
			LOOP
				LogRoleInsert(csr_data_pkg.AUDIT_TYPE_REGION_ROLE_CHANGED, in_role_sid, in_region_sid, v_insert_ids(i));
			END LOOP;
		END IF;

		-- argh... pain in the neck to figure out who needs to be deleted from the security group....
		t_user_sids := security_pkg.SidArrayToTable(v_current_ids);

		FOR r IN (
			SELECT cu.column_value csr_user_sid
			  FROM TABLE(t_user_sids) cu LEFT JOIN (
				SELECT role_sid, user_sid
				  FROM region_role_member
				 WHERE inherited_from_sid = region_sid
				   AND role_sid = in_role_sid
			  )rrm ON cu.column_value = rrm.user_sid
			  WHERE rrm.user_sid IS NULL
		 )
		LOOP
			group_pkg.DeleteMember(in_act_id, r.csr_user_sid, in_role_sid);

			-- log the removal at the top-level region
			LogRoleDelete(csr_data_pkg.AUDIT_TYPE_REGION_ROLE_CHANGED, in_role_sid, in_region_sid, r.csr_user_sid);
		END LOOP;
	END IF;

    -- This is fatal if users have manually subdelegated or manipulated delegations afterwards
    -- since it will apply the chain it wants (e.g. a/b/c, even if the user has manually subdelegated
    -- so that the chain is now a/b/c/d, thus deleting data for d).
    --deleg_plan_pkg.UpdateDelegUsers(in_region_sid);

    chain.filter_pkg.ClearCacheForAllUsers;
END;

PROCEDURE SetRoleMembersForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	VARCHAR2
)
AS
	v_sids security_pkg.T_SID_IDS;
BEGIN
	SELECT item
	   BULK COLLECT INTO v_sids
	  FROM TABLE(utils_pkg.SplitString(in_region_sids));
	SetRoleMembersForUser(in_act_id, in_role_sid, in_user_sid, v_sids);
END;

-- TODO: Set ACLs
PROCEDURE SetRoleMembersForUser(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_role_sid		IN	role.role_sid%TYPE,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS
)AS
	v_region_sids	security_pkg.T_SID_IDS;
	v_current_ids 	security_pkg.T_SID_IDS;
	v_insert_ids 	security_pkg.T_SID_IDS;
	v_tids			security.T_SID_TABLE;
	v_regions		security.T_SID_TABLE;
	v_j				INTEGER;
BEGIN
	-- check for permissions on user sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema for user sid'||in_user_sid);
	END IF;

	IF IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	IF in_region_sids.COUNT = 1 AND in_region_sids(in_region_sids.FIRST) IS NULL THEN
		-- Log the delete of this user from all top-level regions for this role
		FOR r IN (
			SELECT region_sid
			FROM csr.region_role_member
			WHERE user_sid = in_user_sid
			AND role_sid = in_role_sid
			AND region_sid = inherited_from_sid
		) LOOP
			LogRoleDelete(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, r.region_sid, in_user_sid);
		END LOOP;

		DELETE FROM region_role_member
		 WHERE role_sid = in_role_sid
		   AND user_sid = in_user_sid;
		-- if we've not actually touched anything then just don't barf with a permission denied
		-- on the group -- this happens when you edit roles on the edit user page - often the user
		-- won't have permission on the role but actually they're not trying to change it. Probably
		-- we should fix this via the UI, but for a new user account, it's hard to know if they've
		-- actually changed anything in the UI. See FB19221
		IF SQL%ROWCOUNT > 0 THEN
			-- hack for ODP.NET which doesn't support empty arrays - just delete everything
			INTERNAL_DeleteGroupMember(in_act_id, in_user_sid, in_role_sid); -- no longer in this role
		END IF;

		RETURN;
	END IF;

	-- Resolve any links in passed region sids
	v_regions := security_pkg.SidArrayToTable(in_region_sids);
	FOR r IN (
		SELECT NVL(r.link_to_region_sid, r.region_sid) region_sid
		  FROM region r, TABLE(v_regions) rin
		 WHERE r.region_sid = rin.column_value
	) LOOP
		v_region_sids(v_region_sids.COUNT+1) := r.region_sid;
	END LOOP;

	-- make sure user belongs to the security group
	INTERNAL_AddGroupMember(in_act_id, in_user_sid, in_role_sid); -- add to role

	-- PL/SQL associative arrays (index-by tables) are sparse,
	-- so select all existing stuff for easy lookup
	FOR r IN (
		SELECT region_sid
		  FROM region_role_member
		 WHERE role_sid = in_role_sid
		   AND user_sid = in_user_sid
		   AND region_sid = inherited_from_sid -- and NOT inherited
	)
	LOOP
		v_current_ids(r.region_sid) := r.region_sid;
	END LOOP;

	-- go through each ID that we want to set
	FOR i IN v_region_sids.FIRST .. v_region_sids.LAST
	LOOP
		IF v_current_ids.EXISTS(v_region_sids(i)) THEN
			-- remove from current_ids so we don't try to delete
			v_current_ids.DELETE(v_region_sids(i));
		ELSE
			-- mark for insertion
			v_insert_ids(v_insert_ids.COUNT+1) := v_region_sids(i);
		END IF;
	END LOOP;

	-- Check the user is allowed to modify regions
	INTERNAL_CheckGrantRegions(in_role_sid, v_current_ids);
	INTERNAL_CheckGrantRegions(in_role_sid, v_insert_ids);

	-- delete what we don't want
	FORALL i IN INDICES OF v_current_ids
		DELETE FROM region_role_member
		 WHERE role_sid = in_role_sid
		   AND user_sid = in_user_sid
		   AND inherited_from_sid = v_current_ids(i); -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.

	-- log the deletions
	v_j := v_current_ids.FIRST;
	WHILE (v_j IS NOT NULL)
	LOOP
		LogRoleDelete(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, v_current_ids(v_j), in_user_sid);
		v_j := v_current_ids.next(v_j);
	END LOOP;

	-- Get the top level regions to be inserted as a table
	v_tids := security_pkg.SidArrayToTable(v_insert_ids);

	-- Insert the new rows for each top level region
	FOR r IN (
		SELECT /*+ALL_ROWS*/NVL(link_to_region_sid, region_sid) region_sid, connect_by_root region_sid top_region_sid
		  FROM region r
        START WITH region_sid IN (
            SELECT column_value FROM TABLE(v_tids)
        )
        CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	) LOOP
		BEGIN
	        INSERT INTO region_role_member
	          	(role_sid, user_sid, region_sid, inherited_from_sid)
			VALUES
				(in_role_sid, in_user_sid, r.region_sid, r.top_region_sid)
			;

			-- log the insert if it's a top-level region
			IF r.region_sid = r.top_region_sid THEN
				LogRoleInsert(csr_data_pkg.AUDIT_TYPE_USER_ROLE_CHANGED, in_role_sid, r.top_region_sid, in_user_sid);
			END IF;
	    EXCEPTION
	        WHEN DUP_VAL_ON_INDEX THEN
	            NULL; -- ignore if it's already in there
		END;
	END LOOP;

	chain.filter_pkg.ClearCacheForUser (
		in_user_sid => in_user_sid
	);
END;

-- XXX: no security, ported from direct SQL in Credit360.NewUserAlert
-- XXX: does the name reflect what it actually does?
-- (from original code) TODO: what if > 1 region???
PROCEDURE GetUserRoles(
	in_user_sid			IN	csr_user.csr_user_sid%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.description region_description, ro.name role_name, stragg(cu.full_name) full_name, stragg(cu.email) email
		  FROM role ro, region_role_member rrm, v$region r, csr_user cu
		 WHERE ro.role_sid = rrm.role_sid
		   AND rrm.region_sid IN (
				SELECT DISTINCT region_sid
				  FROM region_role_member
				 WHERE user_sid = in_user_sid
			)
		   AND rrm.user_sid = cu.csr_user_sid
		   AND rrm.region_sid = r.region_sid
		   AND rrm.region_sid = inherited_from_sid -- and NOT inherited
		 GROUP BY r.description, ro.name
		 ORDER BY r.description;
END;

PROCEDURE GetUserRoleRegions(
	in_role_name		IN	role.name%TYPE,
	in_roots_only		IN  NUMBER DEFAULT 0,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as it uses security_pkg.getsid
	OPEN out_cur FOR
		SELECT rg.region_sid, rg.description
          FROM role r
          JOIN region_role_member rrm on r.role_sid = rrm.role_sid
          JOIN v$region rg on rrm.region_sid = rg.region_sid
          WHERE LOWER(r.name) IN (
				-- XXX: let's hope the role names don't have comma's in! -- shoudl change to take an array
				SELECT item FROM TABLE(utils_pkg.splitstring(LOWER(in_role_name)))
			)
            AND rrm.user_sid = security_pkg.getSid
            AND rg.active = 1 -- active only
            AND (in_roots_only = 0 OR rrm.inherited_from_sid = rrm.region_sid)
          ORDER BY rg.description;
END;

-- another version -- this is sid based and uses region_type
PROCEDURE GetUserRoleRegions(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_type	IN	region.region_type%TYPE,
	in_roots_only	IN  NUMBER DEFAULT 0,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- no security as it uses security_pkg.getsid
	-- Also, if they're not in the role they don't get any data back
	OPEN out_cur FOR
		WITH r AS (
			SELECT rg.region_sid, rg.description
			  FROM role r
			  JOIN region_role_member rrm on r.role_sid = rrm.role_sid
			  JOIN v$region rg on rrm.region_sid = rg.region_sid
			 WHERE rrm.user_sid = security_pkg.getSid
			   AND (in_region_type IS NULL OR region_type = in_region_type)
			   AND rg.active = 1 -- active only
			   AND r.role_sid = in_role_sid
			   AND (in_roots_only = 0 OR rrm.inherited_from_sid = rrm.region_sid)
	  	    )
			SELECT r.region_sid, r.description, x.path
			  FROM r
				JOIN (
					-- umm -- not hugely efficient as goes down whole region tree
					-- the path stuff is just used ATM by /site/portal/region.acds so we could
					-- break out into another SP if it's a problem
					SELECT region_type, region_sid, description, replace(ltrim(sys_connect_by_path(prior description, ''),''),'',' > ') path
					  FROM v$region
					 WHERE region_sid IN (
						SELECT region_sid FROM r
					  )
					 START WITH parent_sid IN (
						SELECT region_tree_root_sid FROM region_tree -- any tree
					 )
					 CONNECT BY PRIOR region_sid = parent_sid
				)x ON r.region_sid = x.region_sid
             ORDER BY description;

END;

PROCEDURE PropagateRoleMembership (
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID
)
AS
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	IF IsRoleSystemManaged(in_role_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CHANGING_SYS_MANAGED_ROLE, 'You cannot make changes into a system managed role. Role sid:'||in_role_sid);
	END IF;

	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	FOR r IN (
		SELECT NVL(link_to_region_sid, region_sid) region_sid
		  FROM region
		  START WITH parent_sid = v_region_sid
		CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	)
	LOOP
		BEGIN
			INSERT INTO region_role_member
			  (region_sid, role_sid, user_sid, inherited_from_sid)
				SELECT r.region_sid, role_sid, user_sid, v_region_sid
				  FROM region_role_member
				 WHERE region_sid = v_region_sid
				   AND role_sid = in_role_sid;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	chain.filter_pkg.ClearCacheForAllUsers;
END;


PROCEDURE GetPropertyManagerRoleRegions(
	out_role_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- we join to region_role_member in case a customer has mulitple
	-- region manager roles and users are assigned to different ones
	OPEN out_role_cur FOR
		SELECT DISTINCT rrm.role_sid
		  FROM region_role_member rrm
		  JOIN role ro ON rrm.role_sid = ro.role_sid
		 WHERE rrm.inherited_from_sid = rrm.region_sid
		   AND rrm.user_sid = security_pkg.GetSid
		   AND ro.is_property_manager = 1;

	OPEN out_cur FOR
		WITH prop AS (
			SELECT rrm.region_sid
			  FROM region_role_member rrm
			  JOIN role ro ON rrm.role_sid = ro.role_sid
			 WHERE rrm.inherited_from_sid = rrm.region_sid
			   AND rrm.user_sid = security_pkg.GetSid
			   AND ro.is_property_manager = 1
		)
		-- shove the regions and roles into a tree structure
		SELECT NVL(link_to_region_sid, region_sid) region_sid, description, region_type, level lvl, active,
			   (SELECT STRAGG(tag_id) FROM region_tag WHERE region_sid = r.region_sid GROUP BY region_sid) tag_ids -- consider a second output cursor instead?
		  FROM v$region r
		 WHERE active = 1
		 START WITH region_sid IN (
			SELECT region_sid FROM prop
		 )
		CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		   --AND PRIOR active = 1 -- returns 0 rows with ORDER SIBLINGS BY clause
		 ORDER SIBLINGS BY description
		;

END;


/*****************  HACKED IN STUFF **************************/
-- DO NOT USE THIS STUFF!!! It's only used by Otto at present and I'm trying
-- to phase it out.
PROCEDURE AssignToTaggedRoleDelegations(
	in_role_name		IN	role.name%TYPE,
	in_tag_group_name	IN	tag_group_description.name%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- XXX: this is way too drastic but will work for Otto for now
	-- RK: I think we'll deprecate this tagged delegation role type stuff as it's way
	-- to complicated. Going for an "Add" button on the delegation instead which is clearer
	-- this won't quite work for Ottto though.
	DELETE FROM delegation_region
	 WHERE region_sid = in_region_sid
	   AND app_sid = (select app_sid from customer where host='otto.credit360.com');

	FOR r IN (
        -- look for other delegations which exist on the system which are tagged
		WITH child_delegs AS (
            SELECT d.delegation_sid
              FROM region_role_member rrm, role ro, region r, region_tag rt, customer c, reporting_period rp,
                delegation d, delegation_user du, delegation_tag dt, tag t, tag_group_member tgm, v$tag_group tg
             WHERE rrm.role_sid = ro.role_sid
               AND rrm.region_sid = r.region_sid
               AND r.region_sid = rt.region_sid
               AND ro.app_sid = c.app_sid
               AND c.current_reporting_period_sid = rp.reporting_period_sid
               AND c.app_sid = d.app_sid
               AND d.delegation_sid = du.delegation_sid
               AND d.delegation_sid = dt.delegation_sid
               AND dt.tag_id = t.tag_id
               AND rt.tag_id = t.tag_id
               AND t.tag_id = tgm.tag_id
               AND tgm.tag_group_id = tg.tag_group_id
               --
               AND LOWER(ro.name) = LOWER(in_role_name)
               -- the user must be in the role and delegation
               AND rrm.user_sid = du.user_sid
               -- the role must apply to this region
               AND r.region_sid = in_region_sid
               -- the delegation must be tagged with a tag in the applicable tag group
               AND LOWER(tg.name) = LOWER(in_tag_group_name)
               -- the delegation must be in the current reporting period
               AND d.end_dtm > rp.start_dtm
               AND d.start_dtm < rp.end_dtm
			   AND du.inherited_from_sid = du.delegation_sid
             MINUS
                -- exclude delegations this region is already included in
            SELECT delegation_sid
              FROM delegation_region
             WHERE region_sid = in_region_sid
        )
         -- get all descendents of the applicable root delegations
		SELECT delegation_sid
          FROM delegation
         START WITH delegation_sid IN (
			-- get the applicable root delegations
			SELECT delegation_sid
              FROM delegation
             WHERE CONNECT_BY_ISLEAF = 1
             START WITH delegation_sid IN (
				SELECT delegation_sid FROM child_delegs
              )
			  CONNECT BY PRIOR parent_sid = delegation_sid
          )
		  CONNECT BY PRIOR delegation_sid = parent_sid
	)
	LOOP
		--security_pkg.debugmsg(security_pkg.getsid||' added region_sid '||in_region_sid||' to delegation '||r.delegation_Sid);
		INSERT INTO delegation_region (delegation_sid, region_sid, pos, mandatory, aggregate_to_region_sid)
		VALUES (r.delegation_sid, in_region_sid, 0, 0, in_region_sid);

		INSERT INTO delegation_region_description (delegation_sid, region_sid, lang, description)
			SELECT r.delegation_sid, in_region_sid, rd.lang, prd.description || ' - ' || rd.description
			  FROM region r
			  JOIN region_description prd ON r.app_sid = prd.app_sid AND r.parent_sid = prd.region_sid
			  JOIN region_description rd ON r.app_sid = rd.app_sid AND r.region_sid = rd.region_sid
			 WHERE r.region_sid = in_region_sid
			   AND prd.lang = rd.lang;
	END LOOP;
END;

PROCEDURE GetRoleGrantedRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rg.role_sid, r.name
		  FROM csr.role_grant rg
		  JOIN csr.role r ON r.role_sid = rg.role_sid
		 WHERE rg.grant_role_sid = in_role_sid
		 ORDER BY r.name;
END;

PROCEDURE SetRoleGrantedRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_grant_sids	IN  security_pkg.T_SID_IDS
)
AS
	t_grant_sids	security.T_SID_TABLE;
BEGIN
	IF WriteAccessAllowed(SYS_CONTEXT('SECURITY','ACT'), in_role_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Access denied writing to role with sid '||in_role_sid);
	END IF;

	t_grant_sids := security_pkg.SidArrayToTable(in_grant_sids);

	DELETE FROM role_grant
	 WHERE grant_role_sid = in_role_sid;

	INSERT INTO csr.role_grant (role_sid,grant_role_sid)
	  SELECT g.column_value, in_role_sid
	    FROM TABLE (t_grant_sids) g
	   WHERE NOT EXISTS(SELECT * FROM role_grant WHERE grant_role_sid = in_role_sid AND role_sid = g.column_value);
END;

PROCEDURE GetGroupMemberRolesAndGroups(
	in_group_sid_id		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR		 
		SELECT so.sid_id, so.name,
		  CASE WHEN r.name IS NULL THEN 0 ELSE 1 END isRole
		  FROM security.group_members gm
		  JOIN security.securable_object so ON gm.member_sid_id = so.sid_id
	 LEFT JOIN csr.role r ON r.role_sid = gm.member_sid_id AND so.application_sid_id = r.app_sid
		 WHERE gm.group_sid_id = in_group_sid_id
		 ORDER BY r.name;
END;

PROCEDURE SetGroupGrantedRoleMembers(
	in_group_sid_id		IN	security_pkg.T_SID_ID,
	in_role_sids		IN  security_pkg.T_SID_IDS
)
AS
	t_role_sids	security.T_SID_TABLE;
BEGIN
	IF WriteAccessAllowed(SYS_CONTEXT('SECURITY','ACT'), in_group_sid_id) = 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED,
			'Access denied writing to group with sid '||in_group_sid_id);
	END IF;

	t_role_sids := security_pkg.SidArrayToTable(in_role_sids);

	DELETE FROM security.group_members
	  WHERE group_sid_id = in_group_sid_id
	  AND  MEMBER_SID_ID IN (SELECT role_sid FROM role);

	INSERT INTO security.group_members (member_sid_id,group_sid_id)
	  SELECT rs.column_value, in_group_sid_id
	    FROM TABLE (t_role_sids) rs;
END;

PROCEDURE GetRoleUserRegions(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_grp_sid			IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total_rows		OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID;
	v_act_id	security_pkg.T_ACT_ID;
	v_users_sid	security_pkg.T_SID_ID;
BEGIN

	v_app_sid := SYS_CONTEXT('SECURITY','APP');
	v_act_id := SYS_CONTEXT('SECURITY','ACT');
	v_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users');

	WITH usrRegRA AS ( --List of users that have specific role for a specific user who has any role on the same region, with level of first users rrm tree
		SELECT cu.csr_user_sid usr, r.region_sid, r.description, cu2.csr_user_sid role_user_sid, cu2.full_name, cu2.user_name, cu2.email, ir.lvl
		  FROM csr.v$csr_user cu
		  JOIN (SELECT DISTINCT app_sid, region_sid, user_sid
				  FROM csr.region_role_member rrm
				 WHERE region_sid = inherited_from_sid) rrm
			ON rrm.app_sid = cu.app_sid AND rrm.user_sid = cu.csr_user_sid
		  JOIN csr.v$region r ON rrm.region_sid = r.region_sid
		  JOIN csr.region_role_member rrm2 ON rrm2.region_sid = rrm.region_sid
		  JOIN csr.role rl ON rl.role_sid = in_role_sid AND rrm2.role_sid = rl.role_sid
		  JOIN csr.v$csr_user cu2 ON rrm2.user_sid = cu2.csr_user_sid
		  JOIN security.securable_object so ON so.sid_id = cu2.csr_user_sid
		  JOIN (SELECT region_sid, description, active, level lvl
				  FROM csr.v$region START WITH region_sid IN (SELECT region_sid FROM csr.region_tree WHERE is_primary = 1)
			   CONNECT BY PRIOR region_sid = parent_sid) ir ON ir.region_sid = rrm2.inherited_from_sid AND ir.active = 1
		 WHERE cu2.csr_user_sid != cu.csr_user_sid
		   AND cu2.active = 1 AND r.active = 1
		   AND NOT EXISTS (SELECT NULL FROM security.group_members WHERE member_sid_id = cu2.csr_user_sid AND group_sid_id = in_grp_sid)
		   AND so.parent_sid_id = v_users_sid
		   AND cu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
		 ORDER BY r.region_sid, cu2.full_name, cu2.user_name
	) -- Just get the RA for the region closest to the users role region
	SELECT COUNT(*)
	  INTO out_total_rows
	  FROM (
		SELECT usr, region_sid, description, MAX(user_name)
		  FROM usrRegRA alll
		 WHERE lvl = (SELECT MAX(lvl) FROM usrRegRA mx WHERE mx.usr = alll.usr AND mx.region_sid = alll.region_sid)
		 GROUP BY usr, region_sid, description
	);

	OPEN out_cur FOR
		WITH usrRegRA AS ( --List of users that have specific role for a specific user who has any role on the same region, with level of first users rrm tree
			SELECT cu.csr_user_sid usr, r.region_sid, r.description, cu2.csr_user_sid role_user_sid, cu2.full_name, cu2.user_name, cu2.email, ir.lvl
			  FROM csr.v$csr_user cu
			  JOIN (SELECT DISTINCT app_sid, region_sid, user_sid
					  FROM csr.region_role_member rrm
					 WHERE region_sid = inherited_from_sid) rrm
			    ON rrm.app_sid = cu.app_sid AND rrm.user_sid = cu.csr_user_sid
			  JOIN csr.v$region r ON rrm.region_sid = r.region_sid
			  JOIN csr.region_role_member rrm2 ON rrm2.region_sid = rrm.region_sid
			  JOIN csr.role rl ON rl.role_sid = in_role_sid AND rrm2.role_sid = rl.role_sid
			  JOIN csr.v$csr_user cu2 ON rrm2.user_sid = cu2.csr_user_sid
			  JOIN security.securable_object so ON so.sid_id = cu2.csr_user_sid
			  JOIN (SELECT region_sid, description, active, level lvl
					  FROM csr.v$region START WITH region_sid IN (SELECT region_sid FROM csr.region_tree WHERE is_primary = 1)
				   CONNECT BY PRIOR region_sid = parent_sid) ir ON ir.region_sid = rrm2.inherited_from_sid AND ir.active = 1
			 WHERE cu2.csr_user_sid != cu.csr_user_sid
			   AND cu2.active = 1 AND r.active = 1
			   AND NOT EXISTS (SELECT NULL FROM security.group_members WHERE member_sid_id = cu2.csr_user_sid AND group_sid_id = in_grp_sid)
			   AND so.parent_sid_id = v_users_sid
			   AND cu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
			 ORDER BY r.region_sid, cu2.full_name, cu2.user_name
		) -- Just get the RA for the region closest to the users role region
		SELECT usr user_sid, in_role_sid role_sid, region_sid, description, path, user_string
		  FROM (
				SELECT usr, region_sid, description, path, user_string, rownum rn
				  FROM (
					SELECT usr, region_sid, description, region_pkg.GetRegionPathStringFromStPt(region_sid) path,
						REPLACE(STRAGG2(full_name ||
							DECODE(email, NULL, '', ' (<a target="_top" href="mailto:' || email || '">' || email || '</a>)')),
						',','; ') user_string
					  FROM usrRegRA alll
					 WHERE lvl = (SELECT MAX(lvl) FROM usrRegRA mx WHERE mx.usr = alll.usr AND mx.region_sid = alll.region_sid)
					 GROUP BY usr, region_sid, description
					 ORDER BY path
				)
				 WHERE (in_page_size IS NULL OR rownum < in_start_row + NVL(in_page_size, 0)))
		 WHERE rn >= in_start_row;
END;

FUNCTION IsUserInRole(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	FOR r IN (
		SELECT * FROM dual WHERE EXISTS (
			SELECT * FROM region_role_member
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND region_sid = in_region_sid
			   AND role_sid = in_role_sid
		)
	) LOOP
		RETURN TRUE;
	END LOOP;

	RETURN FALSE;
END;

FUNCTION Sql_IsUserInRole(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
BEGIN
	IF IsUserInRole(in_role_sid, in_region_sid) THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

PROCEDURE GetRoleGrantsForExport(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run role_pkg.GetRoleGrantsForExport');
	END IF;

	OPEN out_cur FOR
		SELECT r.name role_name, rg.grant_role_sid
		  FROM csr.role_grant rg
		  JOIN csr.role r ON r.role_sid = rg.role_sid;
END;

PROCEDURE GetAllMembersForRegionByRole (
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_role_sids				IN  security_pkg.T_SID_IDS,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	t_role_sids					security.T_SID_TABLE;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||in_region_sid);
	END IF;

 	-- The way the UI works at the moment the input region sid will never be a
	-- link, if that changes in the future we should be able to cope with it.
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	 t_role_sids := security_pkg.SidArrayToTable(in_role_sids);

 	OPEN out_cur FOR
 		SELECT DISTINCT r.role_sid, r.name role_name, r.lookup_key, rrm.user_sid, cu.full_name, cu.user_name, cu.email,
				CASE
					WHEN rrm.inherited_from_sid = v_region_sid THEN 0
					ELSE 1
				END is_inherited
 		  FROM TABLE(t_role_sids) rs, role r, region_role_member rrm, csr_user cu
	 LEFT JOIN trash t on cu.csr_user_sid = t.trash_sid
 		 WHERE rs.column_value = r.role_sid
		   AND rs.column_value = rrm.role_sid
 		   AND rrm.user_Sid = cu.csr_user_sid
 		   AND rrm.region_sid = v_region_sid
		   AND t.trash_sid IS NULL -- and user is not deleted
 		 ORDER BY role_name, full_name;

END;

PROCEDURE AllowAlterSystemManagedRole
AS
BEGIN
	INSERT INTO csr.transaction_context (key, val)
	VALUES ('alter_system_managed_role', 1);
END;

END;
/

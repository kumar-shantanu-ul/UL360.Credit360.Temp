CREATE OR REPLACE PACKAGE BODY ACTIONS.role_pkg AS

PROCEDURE GetRoles(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Just call through to csr for now
	csr.role_pkg.GetRoles(security_pkg.GetACT, security_pkg.GetAPP, out_cur);
END;

PROCEDURE GetRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetRoleMembers(in_role_sid, NULL, out_cur);
END;

-- Does not include inherited roles
PROCEDURE GetRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_region_start_sid	security_pkg.T_SID_ID;
	v_region_sid		security_pkg.T_SID_ID;
BEGIN
	-- check for permissions on role sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_role_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading role sid '||in_role_sid);
	END IF;
 
 /*
 	SELECT NVL(link_to_region_sid, region_sid)
 	  INTO v_region_sid
 	  FORM region
 	 WHERE region_sid = in_region_sid;
 	 
 	v_region_start_sid := v_region_sid;
 	IF v_region_start_sid < 0 THEN
 		v_region_start_sid := NULL;
 	END IF;
 	
 	IF v_region_start_sid IS NULL THEN
 		SELECT region_tree_root_sid
 		  INTO v_region_start_sid
 		  FROM csr.region_tree
 		 WHERE is_primary = 1;
 	END IF;
 	
 	-- TODO: region filtering
 	-- Need to get all entries for the region/role/member if one of the regions matches the filter
 	*/
 	
 	OPEN out_cur FOR
 		SELECT x.*
 		  FROM (
	 		SELECT r.role_sid, r.name role_name,
	 			   p.project_sid, p.name project_name, 
	 			   rgn.region_sid, rgn.description region_desc,
	 			   rrm.user_sid, cu.full_name, cu.user_name, cu.email
	 		  FROM csr.role r, project p, csr.v$region rgn, csr.csr_user cu, project_region_role_member rrm
	 		 WHERE r.role_sid = rrm.role_sid
	 		   AND p.project_sid = rrm.project_sid
	 		   AND rgn.region_sid = rrm.region_sid
	 		   AND cu.csr_user_sid = rrm.user_sid
	 		   AND rrm.role_sid = in_role_sid
	 		   AND rrm.inherited_from_sid = rrm.region_sid -- and NOT inherited
	 	 ) x
	 	 WHERE security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, x.region_sid, security_pkg.PERMISSION_READ) = 1
	 	   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, x.project_sid, security_pkg.PERMISSION_READ) = 1
	 		ORDER BY x.full_name, x.region_desc;
END;

-- Gets everything, including inherited roles
PROCEDURE GetAllRoleMembers(
	in_role_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check for permissions on role sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_role_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading role sid '||in_role_sid);
	END IF;
 
 	OPEN out_cur FOR
 		SELECT /*+ALL_ROWS*/
 		 	   r.role_sid, r.name role_name,
 			   p.project_sid, p.name project_name, 
 			   rgn.region_sid, rgn.description region_desc,
 			   rrm.user_sid, cu.full_name, cu.user_name, cu.email
 		  FROM csr.role r, project p, csr.v$region rgn, csr.csr_user cu, project_region_role_member rrm
 		 WHERE r.role_sid = rrm.role_sid
 		   AND p.project_sid = rrm.project_sid
 		   AND rgn.region_sid = rrm.region_sid
 		   AND cu.csr_user_sid = rrm.user_sid
 		   AND rrm.role_sid = in_role_sid
 		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, rrm.region_sid, security_pkg.PERMISSION_READ) = 1
 		   AND security_pkg.SQL_IsAccessAllowedSID(security_pkg.GetACT, rrm.project_sid, security_pkg.PERMISSION_READ) = 1
 		 ORDER BY cu.full_name, rgn.description;
END;

PROCEDURE AddProjectRoleMember(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID
)
AS
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	
	-- TODO: check permissions on, the role possibly?

	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM csr.region
	 WHERE region_sid = in_region_sid;

	-- make sure user belongs to the security group
	group_pkg.AddMember(security_pkg.GetACT, in_user_sid, in_role_sid);

    BEGIN
    	FOR r IN (
    		SELECT NVL(link_to_region_sid, region_sid) region_sid
          	  FROM csr.region
          	  	START WITH region_sid = v_region_sid
          	  	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid         
    	) LOOP
    		BEGIN
		        INSERT INTO project_region_role_member 
		        	(role_sid, project_sid, region_sid, user_sid, inherited_from_sid)
				  VALUES 
				  	(in_role_sid, in_project_sid, r.region_sid, in_user_sid, v_region_sid);
		    EXCEPTION
		        WHEN DUP_VAL_ON_INDEX THEN
		            NULL; -- ignore if it's already in there
			END;
		END LOOP;
    END;
END;

PROCEDURE DeleteProjectRoleMember(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_project_sid	IN	security_pkg.T_SID_ID,
	in_user_sid 	IN	security_pkg.T_SID_ID
)
AS
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	
	-- TODO: check permissions on, the role possibly?
	
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM csr.region
	 WHERE region_sid = in_region_sid;
	
	group_pkg.DeleteMember(security_pkg.GetACT, in_user_sid, in_role_sid);

	-- Delete inherited entries
	DELETE FROM project_region_role_member
	 WHERE role_sid = in_role_sid
	   AND inherited_from_sid = v_region_sid
	   AND project_sid = in_project_sid
	   AND user_sid = in_user_sid;

	-- Delete the top-level entry
	DELETE FROM project_region_role_member
	 WHERE role_sid = in_role_sid
	   AND region_sid = v_region_sid
	   AND project_sid = in_project_sid
	   AND user_sid = in_user_sid;

END;

PROCEDURE SetProjectRoleMembers(
	in_role_sid		IN	security_pkg.T_SID_ID,
	in_region_sids	IN	security_pkg.T_SID_IDS,
	in_project_sids	IN	security_pkg.T_SID_IDS,
	in_user_sids	IN	security_pkg.T_SID_IDS
)
AS
	t_region_sids	security.T_ORDERED_SID_TABLE;
	t_project_sids	security.T_ORDERED_SID_TABLE;
	t_user_sids		security.T_ORDERED_SID_TABLE;
BEGIN
	
	-- TODO: check permissions on, the role possibly?

	-- all the arrays will ahve the same lenght, if one is empty the all will be empty
	IF in_region_sids.COUNT = 0 OR (in_region_sids.COUNT = 1 AND in_region_sids(in_region_sids.FIRST) IS NULL) THEN
		FOR r IN (
			SELECT user_sid
			  FROM project_region_role_member
			 WHERE role_sid = in_role_sid
		       AND inherited_from_sid = region_sid
		)
		LOOP
			group_pkg.DeleteMember(security_pkg.GetACT, r.user_sid, in_role_sid);
		END LOOP;
		
		DELETE FROM project_region_role_member
		 WHERE role_sid = in_role_sid;
		RETURN;
	END IF;
	
	-- Convert arrays to ordered tables (we'll join them on pos)
	t_region_sids := security_pkg.SidArrayToOrderedTable(in_region_sids);
	t_project_sids := security_pkg.SidArrayToOrderedTable(in_project_sids);
	t_user_sids := security_pkg.SidArrayToOrderedTable(in_user_sids);

	-- Delete stuff we no longer want
	FOR r IN (
		SELECT region_sid, project_sid, user_sid
		  FROM project_region_role_member
		 WHERE role_sid = in_role_sid
		MINUS
		SELECT rgn.region_sid, prj.sid_id project_sid, usr.sid_id user_sid
		  FROM (
		  	SELECT NVL(rgn.link_to_region_sid, rgn.region_sid) region_sid, rin.pos
		  	  FROM csr.region rgn, TABLE(t_region_sids) rin
		  	 WHERE rgn.region_sid = rin.sid_id
		  )rgn, TABLE(t_project_sids) prj, TABLE(t_user_sids) usr
		 WHERE rgn.pos = prj.pos
		   AND rgn.pos = usr.pos
	) LOOP
		DeleteProjectRoleMember(in_role_sid, r.region_sid, r.project_sid, r.user_sid);	
	END LOOP;

	-- Add new project/role/region entries
	FOR r IN (
		SELECT rgn.region_sid, prj.sid_id project_sid, usr.sid_id user_sid
		  FROM (
		  	SELECT NVL(rgn.link_to_region_sid, rgn.region_sid) region_sid, rin.pos
		  	  FROM csr.region rgn, TABLE(t_region_sids) rin
		  	 WHERE rgn.region_sid = rin.sid_id
		  )rgn, TABLE(t_project_sids) prj, TABLE(t_user_sids) usr
		 WHERE rgn.pos = prj.pos
		   AND rgn.pos = usr.pos
		MINUS
		SELECT region_sid, project_sid, user_sid
		  FROM project_region_role_member
		 WHERE role_sid = in_role_sid
	) LOOP
		AddProjectRoleMember(in_role_sid, r.region_sid, r.project_sid, r.user_sid);
	END LOOP;
	
END;

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.supplier_pkg AS
/*
A) Yes suppliers can change their country or sector. I think
sector is more likely to change (e.g. one of our customers might see us as
Environmental but we'd see ourselves Software).
B) Update company is triggered when the company details change. I've altered
supplier_pkg to move the company region if these values change (which can
leave empty regions). And actually it doesn't really know if it's changed,
just that it isn't where it ought to be but we can use that to trigger other
things if required as we'd have old parent region sid, new parent region sid
and the company that's moving.
*/

PROCEDURE SyncCompanyTypeRoles(
	in_company_sid				IN security_pkg.T_SID_ID,
	in_use_cascade_role_changed	IN NUMBER DEFAULT 0,
	in_supplier_company_sid		IN security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_ucd_act				security_pkg.T_ACT_ID;
	v_role_sid				security_pkg.T_SID_ID;
	v_company_type_id		NUMBER(10);
BEGIN

	--skip this if batch mode is active (used for importing large amounts of companies)
	IF SYS_CONTEXT('SECURITY', 'CHAIN_SUP_ROLE_SYNC_BATCH_MODE') = 'TRUE' THEN
		RETURN;
	END IF;

	IF in_company_sid IS NULL AND in_supplier_company_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Owner company cannot be empty when syncing roles with regards to the supplier with sid:'||in_supplier_company_sid);
	END IF;

	IF in_company_sid IS NOT NULL THEN
		BEGIN
			SELECT company_type_id
			  INTO v_company_type_id
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = in_company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RETURN;
		END;
	END IF;

	chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

	BEGIN
		-- ensure that every company type that should have a role, does
		FOR r IN (
			SELECT *
			  FROM chain.company_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_type_id = NVL(v_company_type_id, company_type_id)
			   AND use_user_role = 1
			   AND user_role_sid IS NULL
		) LOOP
			role_pkg.SetRole(r.plural, r.lookup_key, v_role_sid);

			UPDATE chain.company_type
			   SET user_role_sid = v_role_sid
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_type_id = r.company_type_id;
		END LOOP;

		DELETE FROM chain.tt_company_user;

		INSERT INTO chain.tt_company_user (company_sid, user_sid)
		SELECT DISTINCT cg.company_sid, sgm.member_sid_id
		  FROM chain.company_group cg
		  JOIN security.group_members sgm ON cg.group_sid = sgm.group_sid_id
		  JOIN chain.company c on cg.company_sid = c.company_sid
		  JOIN csr.csr_user cu on sgm.member_sid_id = cu.csr_user_sid
		 WHERE cg.company_group_type_id in (2) -- Users
		   AND c.company_sid = NVL(in_company_sid, c.company_sid);
		
		DELETE FROM tt_company_region_role;
		
		-- add all users as role members for their own region
		INSERT INTO tt_company_region_role(company_sid, region_sid, role_sid, active, deleted)
		SELECT c.company_sid, s.region_sid, ct.user_role_sid, c.active, DECODE(ct.use_user_role, 0, 1, 0) deleted
		  FROM chain.company c
		  JOIN csr.supplier s ON c.app_sid = s.app_sid AND c.company_sid = s.company_sid
		  JOIN chain.company_type ct ON c.app_sid = ct.app_sid AND c.company_type_id = ct.company_type_id
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND s.region_sid IS NOT NULL
		   AND c.deleted = 0
		   AND c.pending = 0
		   AND ct.user_role_sid IS NOT NULL
		   AND EXISTS (
				SELECT 1 
				  FROM chain.tt_company_user tt
				 WHERE c.company_sid = tt.company_sid
		   );
		
		-- add all users as role members for their supplier's regions
		INSERT INTO tt_company_region_role(company_sid, region_sid, role_sid, active, deleted)
		SELECT pc.company_sid, s.region_sid, pct.user_role_sid, sr.active, 
				CASE 
					WHEN sr.deleted = 1 THEN 1
					WHEN pc.deleted = 1 THEN 1
					WHEN NVL(ctr.use_user_roles, 0) = 0 THEN 1
					ELSE 0
			   END deleted
		  FROM chain.supplier_relationship sr
		  JOIN chain.company pc ON sr.app_sid = pc.app_sid AND sr.purchaser_company_sid = pc.company_sid
		  JOIN supplier ps ON ps.company_sid = pc.company_sid
		  JOIN chain.company_type pct ON pc.app_sid = pct.app_sid AND pc.company_type_id = pct.company_type_id
		  JOIN chain.company sc ON pc.app_sid = sc.app_sid AND sr.supplier_company_sid = sc.company_sid
		  LEFT JOIN chain.company_type_relationship ctr ON pc.company_type_id = ctr.primary_company_type_id AND sc.company_type_id = ctr.secondary_company_type_id AND pc.app_sid = ctr.app_sid
		  JOIN supplier s ON sc.app_sid = s.app_sid AND sc.company_sid = s.company_sid
		  JOIN region supr ON supr.region_sid = s.region_sid
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pct.user_role_sid IS NOT NULL
		   AND s.region_sid IS NOT NULL
		   AND sc.deleted = 0
		   AND (in_supplier_company_sid IS NULL OR sc.company_sid = in_supplier_company_sid)
		   AND (in_use_cascade_role_changed = 1 OR ctr.use_user_roles = 1) -- only include rows to unset RRM if we know the cascade flag has changed
		   AND supr.parent_sid <> ps.region_sid --exclude subsidiaries created under purchaser's region. They are getting synced in region_pkg anyway
		   AND EXISTS (
				SELECT 1 
				  FROM chain.tt_company_user tt
				 WHERE pc.company_sid = tt.company_sid
		   );
		
		FOR r IN (
			SELECT t2.user_sid, t1.role_sid, t1.region_sid
			  FROM tt_company_region_role t1
			  JOIN chain.tt_company_user t2 ON t2.company_sid = t1.company_sid
			 WHERE t1.active = 1
			   AND t1.deleted = 0
			   AND NOT EXISTS (
					SELECT 1 
					  FROM region_role_member rrm
					 WHERE rrm.user_sid = t2.user_sid
					   AND rrm.role_sid = t1.role_sid
					   AND rrm.region_sid = t1.region_sid 
				 )
		) 
		LOOP
			/* Do not use SetRoleMembersForRegion here as it deletes existing region role members that do not belong to the passed array of sids
			 Use AddRoleMemberForRegion instead */
			role_pkg.AddRoleMemberForRegion(
				in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=> r.role_sid,
				in_region_sid	=> r.region_sid,
				in_user_sid		=> r.user_sid,
				in_log			=> 0,
				in_force_alter_system_managed => 1
			);
		END LOOP;
		
		FOR r IN (
			SELECT t2.user_sid, t1.role_sid, t1.region_sid
			  FROM tt_company_region_role t1
			  JOIN chain.tt_company_user t2 ON t2.company_sid = t1.company_sid
			 WHERE (t1.active = 0 OR t1.deleted = 1)
			   AND EXISTS (
					SELECT 1 
					  FROM region_role_member rrm
					 WHERE rrm.user_sid = t2.user_sid
					   AND rrm.role_sid = t1.role_sid
					   AND rrm.region_sid = t1.region_sid 
				 )
		) 
		LOOP
			role_pkg.DeleteRegionRoleMember(
				in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=> r.role_sid,
				in_region_sid	=> r.region_sid,
				in_user_sid		=> r.user_sid,
				in_log			=> 0,
				in_force_alter_system_managed	=> 1
			);
		END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
			RETURN;
	END;

	chain.helper_pkg.RevertLogonUCD;
END;

PROCEDURE UNSEC_RemoveFollowerRoles(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
	v_role_sid					security.security_pkg.T_SID_ID;
	v_purchaser_company_type_id chain.company_type.company_type_id%TYPE := chain.company_type_pkg.GetCompanytypeId(in_company_sid => in_purchaser_company_sid);
	v_supplier_company_type_id  chain.company_type.company_type_id%TYPE := chain.company_type_pkg.GetCompanytypeId(in_company_sid => in_supplier_company_sid);
BEGIN
	SELECT follower_role_sid
	  INTO v_role_sid
	  FROM chain.company_type_relationship
	 WHERE primary_company_type_id = v_purchaser_company_type_id
	   AND secondary_company_type_id = v_supplier_company_type_id;

	IF v_role_sid IS NULL THEN
		RETURN;
	END IF;

	chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

	BEGIN
		FOR r IN (
			SELECT rrm.region_sid, rrm.user_sid
			  FROM chain.supplier_follower sf
			  JOIN supplier s ON s.company_sid = sf.supplier_company_sid
			  JOIN region_role_member rrm ON rrm.region_sid = s.region_sid 
			   AND rrm.role_sid = v_role_sid
			   AND rrm.user_sid = sf.user_sid
			 WHERE sf.purchaser_company_sid = in_purchaser_company_sid
			   AND sf.supplier_company_sid = in_supplier_company_sid
		) LOOP
			role_pkg.DeleteRegionRoleMember(
				in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=> v_role_sid,
				in_region_sid	=> r.region_sid,
				in_user_sid		=> r.user_sid,
				in_force_alter_system_managed => 1);
		END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
			RETURN;
	END;
	chain.helper_pkg.RevertLogonUCD;
END;

PROCEDURE INTERNAL_SyncFollowerRoles(
	in_purchaser_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_supplier_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_role_sid					security.security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT follower_role_sid
		  INTO v_role_sid
		  FROM chain.company_type_relationship
		 WHERE primary_company_type_id = in_purchaser_company_type
		   AND secondary_company_type_id = in_supplier_company_type;

		IF v_role_sid IS NULL THEN
			RETURN;
		END IF;

		chain.helper_pkg.LogonUCD;

		FOR r IN (
			SELECT DISTINCT sf.user_sid, sup.region_sid
			  FROM chain.supplier_follower sf
			  JOIN chain.company pc ON sf.purchaser_company_sid = pc.company_sid
			  JOIN chain.company sc ON sf.supplier_company_sid = sc.company_sid
			  JOIN supplier sup ON sc.company_sid = sup.company_sid
		 LEFT JOIN region_role_member rlm ON rlm.region_sid = sup.region_sid
			   AND sf.user_sid = rlm.user_sid AND rlm.role_sid = v_role_sid
			 WHERE (in_user_sid IS NULL OR sf.user_sid = in_user_sid)
			   AND pc.company_type_id = in_purchaser_company_type
			   AND sc.company_type_id = in_supplier_company_type
			   AND (in_purchaser_company_sid IS NULL OR pc.company_sid = in_purchaser_company_sid)
			   AND (in_supplier_company_sid IS NULL OR sc.company_sid = in_supplier_company_sid)
			   AND rlm.user_sid IS NULL
			   AND sc.deleted = 0
			   AND sup.region_sid IS NOT NULL
		) LOOP
			role_pkg.AddRoleMemberForRegion(
				in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=> v_role_sid,
				in_region_sid	=> r.region_sid,
				in_user_sid		=> r.user_sid,
				in_log			=> 0,
				in_force_alter_system_managed => 1);
		END LOOP;

		FOR r IN (
			SELECT rrm.region_sid, rrm.user_sid
			  FROM chain.company c
			  JOIN supplier s ON s.company_sid = c.company_sid
			  JOIN region_role_member rrm
				ON rrm.region_sid = s.region_sid
			   AND rrm.role_sid = v_role_sid
			  LEFT JOIN chain.supplier_follower sf
				ON sf.supplier_company_sid = c.company_sid
			   AND sf.user_sid = rrm.user_sid
			 WHERE c.company_type_id = in_supplier_company_type
			   AND (in_user_sid IS NULL OR rrm.user_sid = in_user_sid)
			   AND (in_supplier_company_sid IS NULL OR c.company_sid = in_supplier_company_sid)
			   AND sf.user_sid IS NULL
		) LOOP
			role_pkg.DeleteRegionRoleMember(
				in_act_id		=> SYS_CONTEXT('SECURITY', 'ACT'),
				in_role_sid		=> v_role_sid,
				in_region_sid	=> r.region_sid,
				in_user_sid		=> r.user_sid,
				in_force_alter_system_managed => 1);
		END LOOP;

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
			RETURN;
	END;
END;

PROCEDURE UNSEC_SyncFollowerRoles(
	in_purchaser_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_supplier_company_type	IN	chain.company_type.company_type_id%TYPE,
	in_user_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
BEGIN
	INTERNAL_SyncFollowerRoles(
		in_purchaser_company_type	=>	in_purchaser_company_type,
		in_supplier_company_type	=>	in_supplier_company_type,
		in_user_sid					=>	in_user_sid,
		in_purchaser_company_sid	=>	NULL,
		in_supplier_company_sid		=>	NULL
	);
END;

PROCEDURE UNSEC_SyncCompanyFollowerRoles(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_purchaser_company_type_id		chain.company_type.company_type_id%TYPE := chain.company_type_pkg.GetCompanyTypeId(in_purchaser_company_sid);
	v_supplier_company_type_id		chain.company_type.company_type_id%TYPE := chain.company_type_pkg.GetCompanyTypeId(in_supplier_company_sid);
BEGIN
	INTERNAL_SyncFollowerRoles(
		in_purchaser_company_type	=>	v_purchaser_company_type_id,
		in_supplier_company_type	=>	v_supplier_company_type_id,
		in_user_sid					=>	in_user_sid,
		in_purchaser_company_sid	=>	in_purchaser_company_sid,
		in_supplier_company_sid		=>	in_supplier_company_sid
	);
END;

FUNCTION INTERNAL_GetRegionRootSid(
	in_ucd_act					IN	security_pkg.T_ACT_ID,
	in_ct_region_root_sid		IN  security_pkg.T_SID_ID
)RETURN NUMBER
AS
	v_region_root_sid			security_pkg.T_SID_ID;
	v_so_name					security_pkg.T_SO_NAME;
BEGIN
	IF in_ct_region_root_sid IS NOT NULL THEN
		RETURN in_ct_region_root_sid;
	END IF;

	-- see if we've got a specific sid set -- e.g. Whistler use this because their
	-- supplier node lives under whistler in order to push down various factors.
	-- This is probably the exception rather than the rule due to the Geographic stuff
	-- that the supplier stuff entails, so this override should be used with care.
	-- i.e. If parent == "USA" then we dont' want to put a "Suppliers" node under this
	-- as it will have it's own (conflicting) geography.
	SELECT supplier_region_root_sid
	  INTO v_region_root_sid
	  FROM customer
	 WHERE app_sid = security_pkg.getApp;

	IF v_region_root_sid IS NULL THEN
		-- if primary tree is called Suppliers then just use this (e.g SCAA), otherwise assume it's a subnode
		v_region_root_sid := region_tree_pkg.GetPrimaryRegionTreeRootSid;
		SELECT LOWER(name)
		  INTO v_so_name
		  FROM security.securable_object
		 WHERE sid_id = v_region_root_sid;
		IF v_so_name != 'suppliers' THEN
			v_region_root_sid := securableobject_pkg.GetSidFromPath(in_ucd_act, v_region_root_sid, 'Suppliers');
		END IF;
	END IF;

	RETURN v_region_root_sid;
END;

-- this gets called by csr_user_pkg.CreateUser
PROCEDURE ChainCompanyUserCreated(
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_company_sid	IN	security_pkg.T_SID_ID
)
AS
	v_company_sid					security_pkg.T_SID_ID DEFAULT in_company_sid;
	v_add_csr_user_to_top_comp		chain.customer_options.add_csr_user_to_top_comp%TYPE;
	v_region_sid					security_pkg.T_SID_ID;
BEGIN
	IF v_company_sid IS NULL THEN
		SELECT NVL(SYS_CONTEXT('SECURITY','CHAIN_COMPANY'), MIN(top_company_sid))
		  INTO v_company_sid
		  FROM chain.customer_options
		 WHERE app_sid = security_pkg.GetApp;
	END IF;

	IF v_company_sid IS NULL THEN
		RETURN;
	END IF;

	--if it's the top company., check the flag before we add the user to it
	SELECT add_csr_user_to_top_comp
	  INTO v_add_csr_user_to_top_comp
	  FROM chain.customer_options
	 WHERE app_sid = security_pkg.GetApp;

	IF chain.helper_pkg.IsSidTopCompany(v_company_sid) = 1 AND v_add_csr_user_to_top_comp = 0 THEN
		RETURN;
	END IF;

	IF SYS_CONTEXT('SECURITY','CHAIN_COMPANY') IS NULL THEN
		-- The CSR user hasn't used a chain page yet, so they don't have a company_sid in their session
		-- Log them in as the top company
		security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	END IF;

	SELECT MIN(NVL(default_region_mount_sid, region_sid))
	  INTO v_region_sid
	  FROM supplier
	 WHERE company_sid = v_company_sid;

	-- automatically makes them registered
	chain.company_user_pkg.SetVisibility(in_user_sid, chain.chain_pkg.NAMEJOBTITLE);

	-- poke default company sid
	UPDATE chain.chain_user
	   SET default_company_sid = v_company_sid
	 WHERE user_sid = in_user_sid;

	-- HACK 1: Add the region start point for the company region so the next line doesn't try to add it itself.
	-- This prevents link_pkg code from adding a region start point (as UCD) that we know we will try to remove
	-- as part of setting the region start points in the edit user page (logged in as the current user) as that
	-- will likely have a permission error.
	IF v_region_sid IS NOT NULL THEN
		BEGIN
			INSERT INTO region_start_point(user_sid, region_sid)
			VALUES (in_user_sid, v_region_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				v_region_sid := NULL; -- Somehow this start point already existed, don't remove
		END;
	END IF;

	-- make them members of the company
	chain.company_user_pkg.AddUserToCompany_UNSEC(v_company_sid, in_user_sid);

	-- HACK 2: Now remove the region start point so that the web request code doesn't get access deneied permissions
	-- trying to remove it when it applies the region start point selection in the create user page
	DELETE FROM region_start_point
	 WHERE user_sid = in_user_sid AND region_sid = v_region_sid;

	-- already done by AddUserToCompany but a comment in the AddUserToCompany code
	-- looks like it might get removed at some point so let's play safe
	chain.company_user_pkg.ApproveUser(v_company_sid, in_user_sid);
END;

-- maps tasks
PROCEDURE UpdateTasksForCompany(
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

-- the assumption here is that the user isn't a topco user but a bog standard supplier user
PROCEDURE AddCompanyUser(
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_user_sid						IN  security_pkg.T_SID_ID
)
AS
	v_ucd_act						security_pkg.T_ACT_ID;
	v_region_sid					security_pkg.T_SID_ID;
	v_supplier_group_sid			security_pkg.T_SID_ID;
	v_start_points					security_pkg.T_SID_IDS;
BEGIN
	BEGIN
		chain.helper_pkg.LogonUCD;
		
		v_ucd_act := security_pkg.GetAct;

		-- find delegations
		FOR r IN (
			SELECT delegation_sid
			  FROM supplier_delegation
			 WHERE supplier_sid = in_company_sid
		) LOOP
			delegation_pkg.UNSEC_AddUser(v_ucd_act, r.delegation_sid, in_user_sid);
		END LOOP;

		-- set start point
		BEGIN
			SELECT default_region_mount_sid
			  INTO v_region_sid
			  FROM csr.supplier
			 WHERE company_sid = in_company_sid;

			v_region_sid := NVL(v_region_sid, GetRegionSid(in_company_sid));
		EXCEPTION
			WHEN no_data_found THEN
				v_region_sid := NULL;
		END;

		IF chain.helper_pkg.IsSidTopCompany(in_company_sid) != 1 THEN
			-- XXX: top companies aren't in CSR.SUPPLIER -- this is barfing for Iain prior to TWDC pitch
			-- chain seems a bit messy in this respect and I don't know how it works, but this solves his immediate
			-- problem
			BEGIN
				v_supplier_group_sid := role_pkg.GetRoleID(security_pkg.GetApp, 'Suppliers');
				IF v_supplier_group_sid IS NULL THEN
					-- If suppliers group isn't a role
					v_supplier_group_sid := securableobject_pkg.GetSidFromPath(v_ucd_act, security_pkg.GetApp, 'Groups/Suppliers');
					group_pkg.AddMember(v_ucd_act, in_user_sid, v_supplier_group_sid);
				END IF;
			EXCEPTION
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					NULL; -- If Suppliers group isn't set up then do nothing
			END;
		END IF;

		-- the ucd can't update a super user, so let's check if it's allowed before we try to update the user's region start points
		IF v_region_sid IS NOT NULL AND
		   security_pkg.IsAccessAllowedSID(v_ucd_act, in_user_sid, security_pkg.PERMISSION_WRITE) THEN

			-- add a start point for the region
			SELECT region_sid
			  BULK COLLECT INTO v_start_points
			  FROM (SELECT region_sid
					  FROM region_start_point
					 WHERE user_sid = in_user_sid
					 UNION
					SELECT v_region_sid
					  FROM dual);

			csr_user_pkg.SetRegionStartPoints(in_user_sid, v_start_points);
		END IF;

		-- makes no real sense to the users.... so hide
		UPDATE csr_user
		   SET show_portal_help = 0
		 WHERE csr_user_sid = in_user_sid;

		-- stick this user in any is_supplier roles
		IF v_region_sid IS NOT NULL AND chain.helper_pkg.IsSidTopCompany(in_company_sid) = 0 THEN
			FOR r IN (
				SELECT role_sid FROM role WHERE is_supplier = 1 AND app_sid = SYS_CONTEXT('SECURITY','APP')
			) LOOP
				role_pkg.AddRoleMemberForRegion(
					in_act_id						=> v_ucd_act,
					in_role_sid						=> r.role_sid,
					in_region_sid					=> v_region_sid,
					in_user_sid 					=> in_user_sid,
					in_force_alter_system_managed	=> 1);
			END LOOP;
		END IF;

		INSERT INTO link_audit (action_dtm, function_name, message)
		VALUES (SYSDATE, 'AddCompanyUser', 'USER_SID=' || in_user_sid || '\nCOMPANY_SID=' ||in_company_sid);

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;

	SyncCompanyTypeRoles(in_company_sid);
END;

-- used directly by mcdonalds-fiber/db/link_body and mcdonalds-supplychain/db/link_body. Also is called by chain_link_pkg
PROCEDURE RemoveUserFromCompany(
	in_user_sid						IN  security_pkg.T_SID_ID,
	in_company_sid					IN  security_pkg.T_SID_ID
)
AS
	v_role_sid						security_pkg.T_SID_ID;
	v_region_sid					security_pkg.T_SID_ID;
	v_act_id						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_type_id				chain.company_type.company_type_id%TYPE;
	v_use_user_role					chain.company_type.use_user_role%TYPE;
	v_ucd_act						security_pkg.T_ACT_ID;
	v_start_points					security_pkg.T_SID_IDS;
BEGIN
	BEGIN
		SELECT s.region_sid, ct.use_user_role, ct.user_role_sid, ct.company_type_id
		  INTO v_region_sid, v_use_user_role, v_role_sid, v_company_type_id
		  FROM csr.supplier s
		  JOIN chain.company c ON s.company_sid = c.company_sid
		  LEFT JOIN chain.company_type ct ON c.company_type_id = ct.company_type_id
		 WHERE s.company_sid = in_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN;
	END;

	IF v_region_sid IS NOT NULL THEN
		-- the ucd can't update a super user, so let's check if it's allowed before we try to update the user's region start points
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		BEGIN
			IF security_pkg.IsAccessAllowedSID(v_ucd_act, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
				-- remove the start point for the region
				SELECT region_sid
				  BULK COLLECT INTO v_start_points
				  FROM (SELECT region_sid
						  FROM region_start_point
						 WHERE user_sid = in_user_sid
						 MINUS
						SELECT v_region_sid
						  FROM dual);

				IF v_start_points.COUNT = 0 THEN
					-- this is the user's last region start point (i.e. last company) - trash user
					csr_user_pkg.DeleteUser(v_ucd_act, in_user_sid);
				ELSE
					csr_user_pkg.SetRegionStartPoints(in_user_sid, v_start_points);
				END IF;
			END IF;
			chain.helper_pkg.RevertLogonUCD;
		EXCEPTION
			WHEN OTHERS THEN
				chain.helper_pkg.RevertLogonUCD;
				RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
		END;
	END IF;

	IF v_use_user_role = 1 AND v_role_sid IS NOT NULL THEN
		-- delete user from role member for this company region
		-- uses UNSEC because link packages assume that the caller has done security checks.
		-- Better than using the awful UCD hack
		role_pkg.UNSEC_DeleteRegionRoleMember(v_act_id, v_role_sid, v_region_sid, in_user_sid);

		-- delete user from member from company's suppliers regions
		FOR r IN (
			SELECT s.region_sid
			  FROM chain.company sc
			  JOIN csr.supplier s ON sc.company_sid = s.company_sid
			  JOIN chain.supplier_relationship sr ON sr.purchaser_company_sid = in_company_sid AND sr.supplier_company_sid = sc.company_sid
			  JOIN chain.company_type_relationship ctr ON ctr.primary_company_type_id = v_company_type_id AND ctr.secondary_company_type_id = sc.company_type_id
			 WHERE ctr.use_user_roles = 1
		) LOOP
			role_pkg.UNSEC_DeleteRegionRoleMember(v_act_id, v_role_sid, r.region_sid, in_user_sid);
		END LOOP;

		--remove user from the Suppliers role
		FOR r IN (
			SELECT role_sid
			  FROM role
			 WHERE is_supplier = 1
			   AND app_sid = SYS_CONTEXT('SECURITY','APP')
		) LOOP
			role_pkg.UNSEC_DeleteRegionRoleMember(v_act_id, r.role_sid, v_region_sid, in_user_sid);
		END LOOP;
	END IF;

	FOR r IN (
		SELECT company_sid
		  FROM chain.v$company_user
		 WHERE user_sid = in_user_sid
	) LOOP
		SyncCompanyTypeRoles(r.company_sid);
	END LOOP;

	INSERT INTO link_audit (action_dtm, function_name, message)
		VALUES (SYSDATE, 'RemoveUserFromCompany', 'USER_SID=' || in_user_sid || '\nCOMPANY_SID=' || in_company_sid);
END;

PROCEDURE CreateSupplierRole(
	in_role_name					IN 	role.name%TYPE,
	out_role_sid					OUT	role.role_sid%TYPE
)
AS
	v_role_sid	security_pkg.T_SID_ID;
	v_ucd_act	security_pkg.T_ACT_ID;
BEGIN
	-- login as daemon user
	v_ucd_act := csr_user_pkg.LogonUserCreatorDaemon;

	role_pkg.SetRole(in_role_name, out_role_sid);

	UPDATE role SET is_supplier = 1 WHERE role_Sid = out_role_sid;

	FOR r IN (
		SELECT cu.user_sid, s.company_sid, s.region_sid
		  FROM chain.v$company_user cu
			JOIN supplier s ON cu.company_sid = s.company_sid
	) LOOP
		role_pkg.AddRoleMemberForRegion(v_ucd_act, out_role_sid, r.region_sid, r.user_sid);
	END LOOP;
END;

PROCEDURE EnsureSecondaryRegionTree(
	in_company_sid			IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID
)
AS
	v_ucd_act				security_pkg.T_ACT_ID;
	v_country_code			postcode.country.country%TYPE;
	v_country_name			postcode.country.name%TYPE;
	v_count					NUMBER(10);
	-- secondary tree stuff
	v_secondary_root_sid	security_pkg.T_SID_ID;
	v_sec_sector_region_sid	security_pkg.T_SID_ID;
	v_temp_sid				security_pkg.T_SID_ID;
BEGIN

	BEGIN
		-- login as daemon user
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		SELECT c.country_code, pc.name
		  INTO v_country_code, v_country_name
		  FROM chain.company c
		  JOIN postcode.country pc ON c.country_code = pc.country
		 WHERE company_sid = in_company_sid;

		-- If we have a secondary tree based on sector then country, map this region to that structure
		BEGIN
			-- TODO - since clients can see the name, we need something internal to link to here
			v_secondary_root_sid := region_tree_pkg.GetSecondaryRegionTreeRootSid('suppliers by sector');
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				chain.helper_pkg.RevertLogonUCD;
				RETURN; -- no secondary tree
		END;

		FOR sec IN (
			SELECT s.sector_id, s.description, LEVEL lvl
			  FROM chain.sector s
			 START WITH s.sector_id IN (SELECT sector_id FROM chain.company WHERE company_sid = in_company_sid)
			 CONNECT BY PRIOR parent_sector_id = sector_id
			 ORDER BY LEVEL DESC
		) LOOP
			BEGIN
				-- try create
				region_pkg.CreateRegion(
					in_act_id      => v_ucd_act,
					in_parent_sid  => NVL(v_sec_sector_region_sid, v_secondary_root_sid),
					in_name        => REPLACE(sec.description, '/', '\'),
					in_description => sec.description,
					out_region_sid => v_sec_sector_region_sid
				);
			EXCEPTION
				WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
					-- read
					v_sec_sector_region_sid := securableobject_pkg.getSidFromPath(v_ucd_act, NVL(v_sec_sector_region_sid, v_secondary_root_sid), REPLACE(sec.description, '/', '\'));
			END;

			-- If we're at the bottom of the sector tree then create the country
			IF sec.lvl = 1 THEN
				BEGIN
					-- try create
					region_pkg.CreateRegion(
						in_act_id      => v_ucd_act,
						in_parent_sid  => v_sec_sector_region_sid,
						in_name        => v_country_code,
						in_description => v_country_name,
						out_region_sid => v_sec_sector_region_sid
					);
				EXCEPTION
					WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
						-- read
						v_sec_sector_region_sid := securableobject_pkg.getSidFromPath(v_ucd_act, v_sec_sector_region_sid, v_country_code);
				END;
			END IF;
		END LOOP;

		-- Remove an old links
		FOR r IN (
			SELECT r.region_sid
			  FROM region r
			 WHERE r.link_to_region_sid = in_region_sid
			   AND r.parent_sid != v_sec_sector_region_sid
			   AND r.region_sid IN (
				 SELECT t.region_sid
				   FROM region t
				  START WITH parent_sid = v_secondary_root_sid
				CONNECT BY PRIOR region_sid = parent_sid
			)
		) LOOP
			securableobject_pkg.DeleteSO(v_ucd_act, r.region_sid);
		END LOOP;

		SELECT count(*)
		  INTO v_count
		  FROM region r
		 WHERE r.link_to_region_sid = in_region_sid
		   AND r.parent_sid = v_sec_sector_region_sid;

		IF v_count = 0 AND v_sec_sector_region_sid IS NOT NULL THEN
			region_pkg.CreateLinkToRegion(
				in_act_id      => v_ucd_act,
				in_parent_sid  => v_sec_sector_region_sid,
				in_link_to_sid => in_region_sid,
				out_region_sid => v_temp_sid
			);
		END IF;

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
END;

PROCEDURE EnsurePrimaryRegionTree(
	in_company_sid					IN	security_pkg.T_SID_ID,
	out_region_sid					OUT	security_pkg.T_SID_ID
)
AS
	-- region stuff
	v_so_name						security_pkg.T_SO_NAME;
	v_ucd_act						security_pkg.T_ACT_ID;
	v_temp_sid						security_pkg.T_SID_ID;
	v_lookup						region.lookup_key%TYPE;
	CURSOR c IS
		SELECT c.country_code, pc.name country_name, pc.latitude, pc.longitude, ct.region_root_sid,
		       NVL(ct.default_region_layout, '{COUNTRY}/{SECTOR}') default_region_layout,
			   ct.create_subsids_under_parent, ct.plural ct_plural, ct.lookup_key ct_lookup_key,
			   c.parent_sid, c.state, c.city,
			   bu.business_unit_id primary_business_unit_id, bu.description primary_business_unit_desc
		  FROM chain.v$company c
		  JOIN chain.company_type ct ON c.app_sid = ct.app_sid AND c.company_type_id = ct.company_type_id
		  JOIN postcode.country pc ON c.country_code = pc.country
		  LEFT JOIN chain.business_unit_supplier bus
		    ON c.app_sid = bus.app_sid AND c.company_sid = bus.supplier_company_sid AND bus.is_primary_bu = 1
		  LEFT JOIN chain.business_unit bu ON bus.app_sid = bu.app_sid AND bus.business_unit_id = bu.business_unit_id
		 WHERE company_sid = in_company_sid;
	comp							c%ROWTYPE;
BEGIN
	OPEN c;
	FETCH c INTO comp;

	IF comp.create_subsids_under_parent = 1 THEN
		-- Get the region_sid of this company's parent
		SELECT MIN(s.region_sid)
		  INTO out_region_sid
		  FROM supplier s
		 WHERE s.company_sid = comp.parent_sid;

		IF out_region_sid IS NOT NULL THEN
			RETURN;
		END IF;
	END IF;

	BEGIN
		-- login as daemon user
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		v_lookup := 'supplier';
		out_region_sid := INTERNAL_GetRegionRootSid(v_ucd_act, comp.region_root_sid);

		-- create parent regions based on company type layout. The regex chops '{COUNTRY}/{SECTOR}' up into 2 rows of COUNTRY and SECTOR
		FOR r IN (
			SELECT LTRIM(RTRIM(UPPER(REGEXP_SUBSTR(str, '{[^}]+}', 1, level, 'i')), '}'), '{') AS layout
			  FROM (
				SELECT comp.default_region_layout AS str FROM dual
			  )
			CONNECT BY level <= LENGTH(REGEXP_REPLACE(str, '{[^}]+}'))+1
		) LOOP
			IF r.layout = 'COUNTRY' THEN
				-- locate the region for the country (or create if not present)
				v_lookup := v_lookup||'_'||comp.country_name;

				SELECT MIN(region_sid)
				  INTO v_temp_sid
				  FROM region
				 WHERE lookup_key = v_lookup
				   AND active = 1;

				IF v_temp_sid IS NULL THEN
					BEGIN
						-- try create
						region_pkg.CreateRegion(
							in_act_id      => v_ucd_act,
							in_parent_sid  => out_region_sid,
							in_name        => comp.country_code,
							in_description => comp.country_name,
							in_geo_type    => region_pkg.REGION_GEO_TYPE_COUNTRY,
							in_geo_country => comp.country_code,
							out_region_sid => v_temp_sid
						);

						UPDATE region
						   SET lookup_key = v_lookup
						 WHERE region_sid = v_temp_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, comp.country_code);
					END;
				END IF;

				out_region_sid := v_temp_sid;
			ELSIF r.layout = 'STATE' AND comp.state IS NOT NULL THEN
				-- locate the region for the state (or create if not present)
				v_lookup := v_lookup||'_ST'||comp.state;

				SELECT MIN(region_sid)
				  INTO v_temp_sid
				  FROM region
				 WHERE lookup_key = v_lookup
				   AND active = 1;

				IF v_temp_sid IS NULL THEN
					BEGIN
						-- try create
						region_pkg.CreateRegion(
							in_act_id      => v_ucd_act,
							in_parent_sid  => out_region_sid,
							in_name        => comp.state,
							in_description => comp.state,
							in_geo_type    => region_pkg.REGION_GEO_TYPE_INHERITED,
							in_geo_country => comp.country_code,
							out_region_sid => v_temp_sid
						);

						UPDATE region
						   SET lookup_key = v_lookup
						 WHERE region_sid = v_temp_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, REPLACE(comp.state, '/', '\'));
					END;
				END IF;

				out_region_sid := v_temp_sid;
			ELSIF r.layout = 'CITY' AND comp.city IS NOT NULL THEN
				-- locate the region for the city (or create if not present)
				v_lookup := v_lookup||'_CT'||comp.city;

				SELECT MIN(region_sid)
				  INTO v_temp_sid
				  FROM region
				 WHERE lookup_key = v_lookup
				   AND active = 1;

				IF v_temp_sid IS NULL THEN
					BEGIN
						-- try create
						region_pkg.CreateRegion(
							in_act_id      => v_ucd_act,
							in_parent_sid  => out_region_sid,
							in_name        => comp.city,
							in_description => comp.city,
							in_geo_type    => region_pkg.REGION_GEO_TYPE_INHERITED,
							in_geo_country => comp.country_code,
							out_region_sid => v_temp_sid
						);

						UPDATE region
						   SET lookup_key = v_lookup
						 WHERE region_sid = v_temp_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, REPLACE(comp.city, '/', '\'));
					END;
				END IF;

				out_region_sid := v_temp_sid;
			ELSIF r.layout = 'COMPANY_TYPE' THEN
				v_lookup := v_lookup||'_'||comp.ct_lookup_key;

				SELECT MIN(region_sid)
				  INTO v_temp_sid
				  FROM region
				 WHERE lookup_key = v_lookup
				   AND active = 1;

				IF v_temp_sid IS NULL THEN
					BEGIN
						-- try create
						region_pkg.CreateRegion(
							in_act_id      => v_ucd_act,
							in_parent_sid  => out_region_sid,
							in_name        => comp.ct_lookup_key,
							in_description => comp.ct_plural,
							out_region_sid => v_temp_sid
						);

						UPDATE region
						   SET lookup_key = v_lookup
						 WHERE region_sid = v_temp_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, comp.ct_lookup_key);
					END;
				END IF;

				out_region_sid := v_temp_sid;
			ELSIF r.layout = 'PRIMARY_BUSINESS_UNIT' AND comp.primary_business_unit_id IS NOT NULL THEN
				v_lookup := v_lookup||'_BUID'||comp.primary_business_unit_id;

				SELECT MIN(region_sid)
				  INTO v_temp_sid
				  FROM region
				 WHERE lookup_key = v_lookup
				   AND active = 1;

				IF v_temp_sid IS NULL THEN
					BEGIN
						-- try create
						region_pkg.CreateRegion(
							in_act_id      => v_ucd_act,
							in_parent_sid  => out_region_sid,
							in_name        => comp.primary_business_unit_id,
							in_description => comp.primary_business_unit_desc,
							out_region_sid => v_temp_sid
						);

						UPDATE region
						   SET lookup_key = v_lookup
						 WHERE region_sid = v_temp_sid;
					EXCEPTION
						WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
							v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, comp.primary_business_unit_id);
					END;
				END IF;

				out_region_sid := v_temp_sid;
			ELSIF r.layout = 'SECTOR' THEN
				-- Add the sectors in heirachical order
				FOR sec IN (
					SELECT s.sector_id, s.description, LEVEL lvl
					  FROM chain.sector s
					 START WITH s.sector_id IN (SELECT sector_id FROM chain.company WHERE company_sid = in_company_sid)
					 CONNECT BY PRIOR parent_sector_id = sector_id
					 ORDER BY LEVEL DESC
				) LOOP
					v_lookup := v_lookup||'_SECID'||sec.sector_id;

					SELECT MIN(region_sid)
					  INTO v_temp_sid
					  FROM region
					 WHERE lookup_key = v_lookup
					   AND active = 1;

					IF v_temp_sid IS NULL THEN
						BEGIN
							-- try create
							region_pkg.CreateRegion(
								in_act_id      => v_ucd_act,
								in_parent_sid  => out_region_sid,
								in_name        => sec.description,
								in_description => sec.description,
								out_region_sid => v_temp_sid
							);
							UPDATE region
							   SET lookup_key = v_lookup
							 WHERE region_sid = v_temp_sid;
						EXCEPTION
							WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
								-- read
								v_temp_sid := securableobject_pkg.getSidFromPath(v_ucd_act, out_region_sid, sec.description);
						END;
					END IF;

					out_region_sid := v_temp_sid;
				END LOOP;
			ELSIF r.layout = 'PARENT' THEN
				-- Get region sid of parent company
				SELECT MIN(s.region_sid)
				  INTO out_region_sid
				  FROM supplier s
				 WHERE s.company_sid = comp.parent_sid;

				IF out_region_sid IS NOT NULL THEN
					v_lookup := v_lookup||'_PAR'||out_region_sid;
				END IF;
			END IF;
		END LOOP;

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
END;

FUNCTION GetRegionSid(
	in_company_sid				security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_supplier_region_sid		security_pkg.T_SID_ID;
BEGIN
	SELECT MIN(region_sid)
	  INTO v_supplier_region_sid
	  FROM supplier
	 WHERE company_sid = in_company_sid;

	RETURN v_supplier_region_sid;
END;

FUNCTION GetCompanySid(
	in_region_sid				security_pkg.T_SID_ID,
	in_swallow_not_found		NUMBER DEFAULT 0
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID := 0;
BEGIN
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM supplier
		 WHERE region_sid = in_region_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			IF in_swallow_not_found = 0 THEN
				RAISE;
			END IF;
	END;

	RETURN v_company_sid;
END;

--creates a chain company from an existing region of type "Supplier".
--mainly to be used with struct region imports
--there's a few assumptions: there already is a region and a company type is provided (which also uses SUPPLIER type region types)
--also, no relationships are established by this SP
PROCEDURE AddCompanyFromRegion(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_company_type_id	IN	chain.company_type.company_type_id%TYPE,
	in_sector_id		IN  chain.company.sector_id%TYPE DEFAULT NULL,
	in_lookup_keys		IN	chain.chain_pkg.T_STRINGS DEFAULT chain.chain_pkg.EMPTY_VALUES, --reference labels
	in_values			IN	chain.chain_pkg.T_STRINGS DEFAULT chain.chain_pkg.EMPTY_VALUES, --reference labels
	out_company_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_region_type			region_type.region_type%TYPE;
	v_company_name			chain.company.name%TYPE;
	v_country_code			region.geo_country%TYPE;
	v_parent_region_sid		security_pkg.T_SID_ID := null;

	v_user_group_sid 		security_pkg.T_SID_ID;
	v_ucd_act				security_pkg.T_ACT_ID;
BEGIN
	SELECT description, geo_country
	  INTO v_company_name, v_country_code
	  FROM csr.v$region
	 WHERE region_sid = in_region_sid;

	chain.company_pkg.CreateCompanyNoLink(
		in_name 			=>	v_company_name,
		in_country_code		=>	v_country_code,
		in_company_type_id	=>	in_company_type_id,
		in_sector_id		=>	in_sector_id,
		in_lookup_keys		=>	in_lookup_keys,
		in_values			=>	in_values,
		out_company_sid		=>	out_company_sid
	);

	EnsurePrimaryRegionTree(out_company_sid, v_parent_region_sid);

	BEGIN
		-- login as daemon user
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		--move the region to the correct place in the tree
		IF v_parent_region_sid IS NOT NULL THEN
			region_pkg.MoveRegion(security_pkg.getACT, in_region_sid, v_parent_region_sid);
		END IF;

		-- fiddle with ACLs -- just let all users fiddle with the region (useful for using property manager).
		v_user_group_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, out_company_sid, 'Users');
		acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(in_region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_user_group_sid, security_pkg.PERMISSION_STANDARD_ALL);

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;

	EnsureSecondaryRegionTree(out_company_sid, in_region_sid);

	-- no exception handling since this shouldn't fail and if it does then something's wrong
	INSERT INTO supplier (company_sid, region_sid)
	VALUES (out_company_sid, in_region_sid);

	-- link audit legacy
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'AddCompanyFromRegion', 'COMPANY_SID=' || out_company_sid);

	SyncCompanyTypeRoles(out_company_sid);
END;

FUNCTION GetChainDocumentLibrary
RETURN security_pkg.T_SID_ID
AS
	v_doc_library_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_doc_library_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Chain Documents');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			v_doc_library_sid := NULL;
	END;

	RETURN v_doc_library_sid;
END;

FUNCTION GetPermissibleDocumentFolders(
	in_doc_library_sid				IN  security_pkg.T_SID_ID
)
RETURN security.T_SID_TABLE
AS
	v_permissible_folders			security.T_SID_TABLE;
	v_permissible_company_sids		security.T_SID_TABLE;
	v_has_access_to_own_files		NUMBER := 0;
BEGIN
	IF supplier_pkg.GetChainDocumentLibrary = in_doc_library_sid THEN
		v_permissible_company_sids := chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ);

		IF chain.type_capability_pkg.CheckCapability(chain.chain_pkg.UPLOADED_FILE, security_pkg.PERMISSION_READ) THEN
			v_has_access_to_own_files := 1;
		END IF;

		SELECT df.doc_folder_sid
		  BULK COLLECT INTO v_permissible_folders
		  FROM doc_folder df
		  JOIN TABLE(v_permissible_company_sids) c ON df.company_sid = c.column_value
		 UNION
		SELECT df.doc_folder_sid
		  FROM doc_folder df
		 WHERE v_has_access_to_own_files = 1
		   AND df.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;

	RETURN v_permissible_folders;
END;

FUNCTION CheckDocumentPermissions(
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_chain_permission_set			security_pkg.T_PERMISSION := in_permission_set;
BEGIN
	-- map normal permissions to chain's simplified permissions
	IF in_permission_set IN (security_pkg.PERMISSION_DELETE, security_pkg.PERMISSION_ADD_CONTENTS) THEN
		v_chain_permission_set := security_pkg.PERMISSION_WRITE;
	ELSIF in_permission_set = security_pkg.PERMISSION_LIST_CONTENTS THEN
		v_chain_permission_set := security_pkg.PERMISSION_READ;
	END IF;

	RETURN chain.type_capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.UPLOADED_FILE, v_chain_permission_set);
END;

PROCEDURE GetOrCreateDocumentLibrary(
	out_doc_library_sid				OUT security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_act_id						security_pkg.T_ACT_ID := security_pkg.GetAct;
	v_reg_users_sid					security_pkg.T_SID_ID;
	v_admins_sid					security_pkg.T_SID_ID;
	v_ucd_sid						security_pkg.T_SID_ID;
	v_chain_sid						security_pkg.T_SID_ID;
	v_doc_folder_sid				security_pkg.T_SID_ID;
BEGIN
	-- Get the library (if it exists). If it doesn't, create it.
	-- Get the Chain securable object and see if we have a doc library for it
	out_doc_library_sid := GetChainDocumentLibrary;

	IF out_doc_library_sid IS NULL THEN
		v_chain_sid := securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Chain');

		csr.doc_lib_pkg.CreateLibrary(
			in_parent_sid_id	=> v_chain_sid,
			in_library_name		=> 'Chain Documents',
			in_documents_name	=> 'Documents',
			in_trash_name		=> 'Recycle Bin',
			in_app_sid			=> v_app_sid,
			out_doc_library_sid	=> out_doc_library_sid
		);

		-- don't inherit the everyone permission that chain adds on the chain node
		securableobject_pkg.ClearFlag(v_act_id, out_doc_library_sid, security_pkg.SOFLAG_INHERIT_DACL);
		acl_pkg.DeleteAllACEs(v_act_id, acl_pkg.GetDACLIDForSID(out_doc_library_sid));

		v_reg_users_sid 		:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/RegisteredUsers');
		v_admins_sid 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Administrators');
		v_ucd_sid	 			:= securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'users/UserCreatorDaemon');

		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(out_doc_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			v_admins_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_WRITE + security_pkg.PERMISSION_DELETE);

		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(out_doc_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			v_ucd_sid, security_pkg.PERMISSION_STANDARD_ALL);

		-- give registered users just read on the doc lib and documents folder
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(out_doc_library_sid), -1, security_pkg.ACE_TYPE_ALLOW, 0,
			v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);

		v_doc_folder_sid := securableobject_pkg.GetSIDFromPath(v_act_id, out_doc_library_sid, 'Documents');
		acl_pkg.AddACE(v_act_id, acl_pkg.GetDACLIDForSID(v_doc_folder_sid), -1, security_pkg.ACE_TYPE_ALLOW, security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security_pkg.PERMISSION_STANDARD_READ);

		acl_pkg.PropogateACEs(v_act_id, out_doc_library_sid);
	END IF;
END;

PROCEDURE CreateDocLibraryFolder(
	in_company_sid      		IN  security_pkg.T_SID_ID,
	in_folder_name				IN  VARCHAR2
)
AS
	v_doc_lib_sid				security_pkg.T_SID_ID;
	v_new_folder_sid			security_pkg.T_SID_ID;
BEGIN
	GetOrCreateDocumentLibrary(v_doc_lib_sid);

	doc_folder_pkg.CreateFolder(
		in_parent_sid 			=> doc_folder_pkg.GetDocumentsFolder(v_doc_lib_sid),
		in_name 				=> in_folder_name,
		in_company_sid 			=> in_company_sid,
		in_is_system_managed	=> 1,
		out_sid_id 				=> v_new_folder_sid
	);
END;

FUNCTION FormatDocFolderName(
	in_company_name				IN  VARCHAR2,
	in_company_sid				IN  security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
BEGIN
	RETURN SUBSTRB(REPLACE(in_company_name,'/','-'), 1, 240) || ' ('|| in_company_sid ||')';
END;

FUNCTION GetDocumentLibraryFolder (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS
	v_folder_sid					security_pkg.T_SID_ID;
	v_parent_sid					security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := doc_folder_pkg.GetDocumentsFolder(GetChainDocumentLibrary());

	BEGIN
		SELECT df.doc_folder_sid
		  INTO v_folder_sid
		  FROM doc_folder df
		  JOIN security.securable_object so ON so.sid_id = df.doc_folder_sid
		 WHERE df.is_system_managed = 1
		   AND df.company_sid = in_company_sid
		   AND so.parent_sid_id = v_parent_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_folder_sid := NULL;
	END;

	RETURN v_folder_sid;
END;

PROCEDURE AddMissingCompanyDocFolders
AS
	v_doc_lib_sid				security_pkg.T_SID_ID;
	v_ucd_act					security_pkg.T_ACT_ID;
BEGIN
	BEGIN
		-- login as daemon user
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		GetOrCreateDocumentLibrary(v_doc_lib_sid);

		FOR r IN (
			SELECT c.name, c.company_sid
			  FROM chain.company c
			  JOIN chain.company_type ct ON c.app_sid = ct.app_sid AND c.company_type_id = ct.company_type_id
			  LEFT JOIN doc_folder df ON c.app_sid = df.app_sid AND c.company_sid = df.company_sid AND df.is_system_managed = 1
			 WHERE ct.create_doc_library_folder = 1
			   AND df.doc_folder_sid IS NULL
			   AND c.deleted = 0
			   AND c.pending = 0
		) LOOP
			CreateDocLibraryFolder(r.company_sid, FormatDocFolderName(r.name, r.company_sid));
		END LOOP;

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
END;

PROCEDURE AddCompany(
	in_company_sid      		IN  security_pkg.T_SID_ID
)
AS
	-- region stuff
	v_supplier_region_sid		security_pkg.T_SID_ID := null;
	v_primary_region_sid		security_pkg.T_SID_ID := null;

	v_user_group_sid 			security_pkg.T_SID_ID;
	v_region_type				region_type.region_type%TYPE;
	v_create_doc_library_folder chain.company_type.create_doc_library_folder%TYPE;

	CURSOR cc IS
		SELECT name, country_code, city, state, company_type_id
		  FROM chain.company
		 WHERE company_sid = in_company_sid;
	r_cc cc%ROWTYPE;
BEGIN
	BEGIN
		-- region_sid FK constraint is deferred...
		INSERT INTO supplier (company_sid) VALUES (in_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- company is already registered
			v_supplier_region_sid := GetRegionSid(in_company_sid);
	END;

	-- then see if we need a new folder
	OPEN cc;
	FETCH cc INTO r_cc;
	CLOSE cc;

	SELECT default_region_type, create_doc_library_folder
	  INTO v_region_type, v_create_doc_library_folder
	  FROM chain.company_type
	 WHERE company_type_id = r_cc.company_type_id;

	IF v_create_doc_library_folder = 1 THEN
		BEGIN
			-- login as daemon user
			chain.helper_pkg.LogonUCD;

			CreateDocLibraryFolder(in_company_sid, FormatDocFolderName(r_cc.name, in_company_sid));

			chain.helper_pkg.RevertLogonUCD;
		EXCEPTION
			WHEN OTHERS THEN
				-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
				chain.helper_pkg.RevertLogonUCD;
				RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
		END;
	END IF;

	IF v_supplier_region_sid IS NULL THEN
		-- it's a new company

		-- only create region if a region type has been set on for this company type
		IF v_region_type IS NOT NULL THEN
			EnsurePrimaryRegionTree(in_company_sid, v_primary_region_sid);

			BEGIN
				-- login as daemon user
				chain.helper_pkg.LogonUCD;

				-- create supplier company as region
				-- name the region '<Supplier> (SID)'
				region_pkg.CreateRegion(
					in_parent_sid  => v_primary_region_sid,
					in_name        => SUBSTR(REPLACE(r_cc.name,'/','\\'),1,243)||' ('||in_company_sid||')', -- sanitize name
					in_description => r_cc.name,
					in_geo_type    => region_pkg.REGION_GEO_TYPE_INHERITED,
					in_geo_country => r_cc.country_code,
					out_region_sid => v_supplier_region_sid
				);

				region_pkg.SetRegionType(v_supplier_region_sid, v_region_type);

				-- fiddle with ACLs -- just let all users fiddle with the region (useful for using property manager).
				v_user_group_sid := securableobject_pkg.getSidFromPath(security_pkg.getACT, in_company_sid, 'Users');
				acl_pkg.AddACE(security_pkg.getACT, acl_pkg.GetDACLIDForSID(v_supplier_region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
					security_pkg.ACE_FLAG_DEFAULT, v_user_group_sid, security_pkg.PERMISSION_STANDARD_ALL);

				chain.helper_pkg.RevertLogonUCD;
			EXCEPTION
				WHEN OTHERS THEN
					-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
					chain.helper_pkg.RevertLogonUCD;
					RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
			END;

			EnsureSecondaryRegionTree(in_company_sid, v_supplier_region_sid);

			UPDATE supplier
			   SET region_sid = v_supplier_region_sid
			 WHERE company_sid = in_company_sid;
		END IF;
	END IF;

	-- link audit legacy
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	 VALUES(SYSDATE, 'AddCompany', 'COMPANY_SID=' || in_company_sid);

	SyncCompanyTypeRoles(in_company_sid);
END;

PROCEDURE UpdateCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
)
AS
	r_c chain.company%ROWTYPE;
	r_r region%ROWTYPE;
	v_primary_region_sid		security_pkg.T_SID_ID;
	v_supplier_region_sid		security_pkg.T_SID_ID;
	v_ucd_act					security_pkg.T_ACT_ID;
	v_geo_region				region.geo_region%TYPE;
	v_geo_city_id				region.geo_city_id%TYPE;
	v_new_folder_name			security_pkg.T_SO_NAME;
	v_old_folder_name			security_pkg.T_SO_NAME;
	v_doc_folder_sid			security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_supplier_region_sid := GetRegionSid(in_company_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Sanity check - if we get here this company was created before csr.supplier_pkg was set up as the chain link pkg
			NULL;
	END;

	IF v_supplier_region_sid IS NOT NULL THEN
		--TODO: it would be better if we only attempted this if we knew the values had changed
		EnsurePrimaryRegionTree(in_company_sid, v_primary_region_sid);

		BEGIN
			-- login as daemon user
			chain.helper_pkg.LogonUCD;
			v_ucd_act := security_pkg.GetAct;

			IF securableobject_pkg.GetParent(v_ucd_act, v_supplier_region_sid) != v_primary_region_sid THEN
				-- clearing geo location information in order to move the region. Subsequent modification will put it back
				csr.region_pkg.SetLatLong(v_supplier_region_sid, 0, 0);
				securableobject_pkg.MoveSO(v_ucd_act, v_supplier_region_sid, v_primary_region_sid);
			END IF;

			SELECT *
			  INTO r_r
			  FROM region
			 WHERE region_sid = v_supplier_region_sid;

			v_geo_city_id := r_r.geo_city_id;
			v_geo_region := r_r.geo_region;

			SELECT *
			  INTO r_c
			  FROM chain.company
			 WHERE company_sid = in_company_sid;

			--if we are changing country, clear the geo_region
			IF r_c.country_code != NVL(r_r.geo_country, '-') THEN
				v_geo_region := NULL;
				v_geo_city_id := NULL;
			END IF;

			BEGIN
				SELECT so.name, df.doc_folder_sid
				  INTO v_old_folder_name, v_doc_folder_sid
				  FROM doc_folder df
				  JOIN security.securable_object so ON df.doc_folder_sid = so.sid_id
				 WHERE df.company_sid = in_company_sid
				   AND df.is_system_managed = 1
				   AND so.parent_sid_id = doc_folder_pkg.GetDocumentsFolder(GetChainDocumentLibrary);

				v_new_folder_name := FormatDocFolderName(r_c.name, in_company_sid);
			EXCEPTION
				WHEN no_data_found THEN
					NULL;
			END;

			IF v_doc_folder_sid IS NOT NULL AND null_pkg.ne(v_old_folder_name, v_new_folder_name) THEN
				securableobject_pkg.RenameSO(v_ucd_act, v_doc_folder_sid, v_new_folder_name);
			END IF;

			csr.region_pkg.AmendRegion(
				in_act_id 		=> v_ucd_act,
				in_region_sid 	=> v_supplier_region_sid,
				in_description	=> r_c.name,
				in_active 		=> r_r.active,
				in_pos 			=> r_r.pos,
				in_geo_type 	=> r_r.geo_type,
				in_info_xml		=> r_r.info_xml,
				in_geo_country	=> r_c.country_code,
				in_geo_region	=> v_geo_region,
				in_geo_city		=> v_geo_city_id,
				in_map_entity	=> r_r.map_entity,
				in_egrid_ref	=> r_r.egrid_ref,
				in_region_ref	=> r_r.region_ref,
				in_acquisition_dtm => r_r.acquisition_dtm,
				in_disposal_dtm	=> r_r.disposal_dtm,
				in_region_type	=> r_r.region_type);

            -- The region_description has only been set for the language of the executing user. As
            -- Chain apears to have no concept of this, we need to update all existing translations.
            FOR r IN (SELECT lang FROM region_description WHERE region_sid = v_supplier_region_sid) LOOP
                csr.region_pkg.SetTranslation(v_supplier_region_sid, r.lang, r_c.name);
            END LOOP;

			EnsureSecondaryRegionTree(in_company_sid, v_supplier_region_sid);

			chain.helper_pkg.RevertLogonUCD;
		EXCEPTION
			WHEN OTHERS THEN
				-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
				chain.helper_pkg.RevertLogonUCD;
				RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
		END;
	END IF;
END;

PROCEDURE SetLatLong(
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_latitude			IN	region.geo_latitude%TYPE,
	in_longitude		IN	region.geo_longitude%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT r.region_sid
		  FROM region r
		  JOIN supplier s ON r.app_sid = s.app_sid AND r.region_sid = s.region_sid
		 WHERE s.company_sid = in_company_sid
		   AND (DECODE(r.geo_latitude, in_latitude, 1, 0) = 0
		    OR DECODE(r.geo_longitude, in_longitude, 1, 0) = 0)
	) LOOP
		BEGIN
			-- login as daemon user
			chain.helper_pkg.LogonUCD;

			region_pkg.SetLatLong(r.region_sid, in_latitude, in_longitude);

			chain.helper_pkg.RevertLogonUCD;
		EXCEPTION
			WHEN OTHERS THEN
				-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
				chain.helper_pkg.RevertLogonUCD;
				RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
		END;
	END LOOP;
END;

PROCEDURE DeleteCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
)
AS
	v_region_sid	security_pkg.T_SID_ID;
	v_response_ids	security.T_SID_TABLE;
	v_start_points	security_pkg.T_SID_IDS;
	v_trash_count	NUMBER(10);
BEGIN
	BEGIN
		v_region_sid := GetRegionSid(in_company_sid);

		UPDATE issue
		   SET deleted=1, issue_supplier_id = NULL
		 WHERE issue_supplier_id IN (
			SELECT issue_supplier_id
			  FROM issue_supplier
			 WHERE company_sid = in_company_sid
		 );

		DELETE FROM issue_supplier
		 WHERE company_sid = in_company_sid;

		SELECT survey_response_id
		  BULK COLLECT INTO v_response_ids
		  FROM supplier_survey_response
		 WHERE supplier_sid = in_company_sid;

		DELETE FROM qs_answer_log
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM qs_submission_file
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM qs_answer_file
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM qs_response_file
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM quick_survey_answer
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		UPDATE quick_survey_response
		   SET last_submission_id = NULL
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM quick_survey_submission
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		-- TODO: dependencies for flow_item
		DELETE FROM flow_item
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM issue_survey_answer
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM non_compliance_expr_action
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM qs_response_postit
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM supplier_survey_response
		 WHERE supplier_sid = in_company_sid;

		DELETE FROM quick_survey_response
		 WHERE survey_response_id IN (SELECT column_value FROM TABLE(v_response_ids));

		DELETE FROM current_supplier_score
		 WHERE company_sid = in_company_sid;

		DELETE FROM supplier_score_log
		 WHERE supplier_sid = in_company_sid;

		DELETE FROM chain.supplier_audit
		 WHERE supplier_company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		-- can't set auditor company to null, so delete it.
		DELETE FROM chain.supplier_audit
		 WHERE auditor_company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		UPDATE chain.supplier_audit
		   SET created_by_company_sid = NULL
		 WHERE created_by_company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		UPDATE internal_audit
		   SET auditor_company_sid = NULL
		 WHERE auditor_company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		UPDATE batch_job
		   SET requested_by_company_sid = NULL
		 WHERE requested_by_company_sid = in_company_sid
		   AND app_sid = SYS_CONTEXT('SECURITY','APP');

		IF v_region_sid IS NOT NULL THEN
			-- Remove the deleted region from the user's start points
			FOR u IN (
				SELECT user_sid
				  FROM region_start_point
				 WHERE region_sid = v_region_sid
			) LOOP
				SELECT region_sid
				  BULK COLLECT INTO v_start_points
				  FROM region_start_point
				 WHERE user_sid = u.user_sid
				   AND region_sid != v_region_sid;

				IF v_start_points.COUNT = 0 THEN
					-- this is the user's last region start point (i.e. last company) - delete user
					securableobject_pkg.DeleteSO(security_pkg.getACT, u.user_sid);
				ELSE
					csr_user_pkg.SetRegionStartPoints(u.user_sid, v_start_points);
				END IF;
			END LOOP;
		END IF;

		DELETE FROM supplier
		 WHERE company_sid = in_company_sid;

		FOR r IN (
			SELECT df.doc_folder_sid, so.name
			  FROM doc_folder df
			  JOIN security.securable_object so ON df.app_sid = so.application_sid_id AND df.doc_folder_sid = so.sid_id
			 WHERE df.company_sid = in_company_sid
		) LOOP
			UPDATE doc_folder
			   SET company_sid = NULL
			 WHERE doc_folder_sid = r.doc_folder_sid;

			doc_folder_pkg.DeleteFolder(r.doc_folder_sid, r.name, v_trash_count);
		END LOOP;

		IF v_region_sid IS NOT NULL THEN
			securableobject_pkg.DeleteSO(security_pkg.getACT, v_region_sid);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND
			THEN NULL; -- Allow for DeleteCompany getting called twice when company is deleted fully
	END;

	SyncCompanyTypeRoles(in_company_sid);
END;

PROCEDURE VirtualDeleteCompany(
	in_company_sid      IN  security_pkg.T_SID_ID
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_ucd_act					security_pkg.T_ACT_ID;
	v_start_points				security_pkg.T_SID_IDS;
	v_trash_count				NUMBER(10);
BEGIN
	BEGIN
		v_region_sid := GetRegionSid(in_company_sid);
		IF v_region_sid IS NULL THEN
			RETURN;
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- Allow for DeleteCompany getting called twice when company is deleted fully
	END;

	UPDATE issue
	   SET deleted=1
	 WHERE issue_supplier_id IN (
		SELECT issue_supplier_id
		  FROM issue_supplier
		 WHERE company_sid = in_company_sid
	 );

	BEGIN
		-- login as daemon user
		chain.helper_pkg.LogonUCD;
		v_ucd_act := security_pkg.GetAct;

		-- Remove the deleted region from the user's start points
		FOR u IN (
			SELECT user_sid
			  FROM region_start_point
			 WHERE region_sid = v_region_sid
		) LOOP
			SELECT region_sid
			  BULK COLLECT INTO v_start_points
			  FROM region_start_point
			 WHERE user_sid = u.user_sid
			   AND region_sid != v_region_sid;

			IF v_start_points.COUNT = 0 THEN
				-- this is the user's last region start point (i.e. last company) - trash user
				csr_user_pkg.DeleteUser(v_ucd_act, u.user_sid);
			ELSE
				csr_user_pkg.SetRegionStartPoints(u.user_sid, v_start_points);
			END IF;
		END LOOP;

		-- delete any regions that link to this region
		FOR r IN (
			SELECT region_sid
			  FROM region
			 WHERE link_to_region_sid = v_region_sid
		) LOOP
			security.securableobject_pkg.DeleteSO(v_ucd_act, r.region_sid);
		END LOOP;

		region_pkg.TrashObject(v_ucd_act, v_region_sid);

		FOR r IN (
			SELECT df.doc_folder_sid, so.name
			  FROM doc_folder df
			  JOIN security.securable_object so ON df.app_sid = so.application_sid_id AND df.doc_folder_sid = so.sid_id
			 WHERE df.company_sid = in_company_sid
		) LOOP
			UPDATE doc_folder
			   SET company_sid = NULL
			 WHERE doc_folder_sid = r.doc_folder_sid;

			doc_folder_pkg.UNSEC_DeleteFolder(r.doc_folder_sid, r.name, v_trash_count);
		END LOOP;

		chain.helper_pkg.RevertLogonUCD;
	EXCEPTION
		WHEN OTHERS THEN
			-- Undo setting of the ACT on error just in case the error is caught and more code is ran that might rely on it
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'ORA'||SQLCODE||': '||SQLERRM||' '||dbms_utility.format_error_backtrace);
	END;
END;

PROCEDURE InviteCreated(
	in_invitation_id			IN	chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'InviteCreated', 'INVITATION_ID=' || in_invitation_id);
END;

PROCEDURE QuestionnaireAdded(
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE
)
AS
	v_ucd_act	security_pkg.T_ACT_ID;
	v_users		VARCHAR2(255);
	-- delegation stuff
	v_region_sid			security_pkg.T_SID_ID;
	v_tpl_delegation_sid	security_pkg.T_SID_ID;
	v_is_deleg				NUMBER;
	v_new_deleg_sid			security_pkg.T_SID_ID;
	v_lowest_deleg_sid		security_pkg.T_SID_ID;
	v_deleg_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	-- TODO: what security checks are required?

	v_ucd_act := csr_user_pkg.LogonUserCreatorDaemon;

	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'QuestionnaireAdded', 'FROM_COMPANY_SID=' || in_from_company_sid || '\n' ||
											'TO_COMPANY_SID=' || in_to_company_sid || '\n' ||
											'TO_USER_SID=' || in_to_user_sid || '\n' ||
											'QUESTIONNAIRE_ID=' || in_questionnaire_id || '\n');

	SELECT questionnaire_type_id,
		(SELECT COUNT(*) FROM chain_tpl_delegation WHERE tpl_delegation_sid = questionnaire_type_id)
	  INTO v_tpl_delegation_sid, v_is_deleg
	  FROM chain.questionnaire
	 WHERE questionnaire_id = in_questionnaire_id;

	IF v_is_deleg = 0 THEN
		-- this questionnaire type isn't registered as a delegation - maybe a logging form?
		-- anyway, give up
		RETURN;
	END IF;

	-- tpl_delegation_sid is the same as the chain questionnaire_id
	BEGIN
		INSERT INTO supplier_delegation
			(supplier_sid, tpl_delegation_sid, delegation_sid)
		VALUES
			(in_to_company_sid, v_tpl_delegation_sid, v_tpl_delegation_sid); -- we'll use the v_tpl_delegation_sid for now instead of a deferrable constraint
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- already added? i.e. maybe this is a different company asking for
			-- the info, so nothing more to do...
			RETURN;
	END;

	-- copy delegation
	delegation_pkg.CopyDelegation(v_ucd_act, v_tpl_delegation_sid, null, v_new_deleg_sid);

	UPDATE supplier_delegation
	   SET delegation_sid = v_new_deleg_sid
	 WHERE supplier_sid = in_to_company_sid
	   AND tpl_delegation_sid = v_tpl_delegation_sid
	   AND delegation_sid = v_tpl_delegation_sid;

	-- insert our region
	INSERT INTO delegation_region (delegation_sid, region_sid, mandatory, pos, aggregate_to_region_sid)
		SELECT v_new_deleg_sid, s.region_sid, 0, 0, s.region_sid
	      FROM supplier s
	      JOIN region r ON s.region_sid = r.region_sid
	     WHERE company_sid = in_to_company_sid;

	v_region_sid := GetRegionSid(in_to_company_sid);

	-- set users...
	-- XXX: needs a config option for 'use delegations vs. don't'
	IF 1 = 1 THEN
		-- no approval process
		SELECT STRAGG(user_sid) user_list
		  INTO v_users
		  FROM chain.v$company_user
		 WHERE company_sid = in_to_company_sid;
	ELSE
		-- with approval process
		SELECT f.user_list || '/' || t.user_list
		  INTO v_users
		  FROM (
			SELECT STRAGG(user_sid) user_list
			  FROM chain.v$company_user
			 WHERE company_sid = in_from_company_sid
		  )f, (
			SELECT STRAGG(user_sid) user_list
			  FROM chain.v$company_user
			 WHERE company_sid = in_to_company_sid
		  )t;
	END IF;

	-- subdelegate
	delegation_pkg.ApplyChainToRegion(v_ucd_act, v_new_deleg_sid, v_region_sid, v_users, 1, v_deleg_cur);
	FETCH v_deleg_cur INTO v_lowest_deleg_sid; -- get the top level sid
	IF v_deleg_cur%FOUND THEN
		FETCH v_deleg_cur INTO v_lowest_deleg_sid; -- and again for the second level sid (if we can)
	END IF;
	CLOSE v_deleg_cur;

	-- track the new delegation_sid
	UPDATE supplier_delegation
	   SET delegation_sid = v_lowest_deleg_sid
	 WHERE supplier_sid = in_to_company_sid
	   AND tpl_delegation_sid = v_tpl_delegation_sid;
END;

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)AS
BEGIN
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'ActivateCompany', 'COMPANY_SID=' || in_company_sid);

	SyncCompanyTypeRoles(in_company_sid);
END;

PROCEDURE DeactivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
	v_region_sid				supplier.region_sid%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.DEACTIVATE_COMPANY)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Deactivate access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;

	BEGIN
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

		BEGIN
			SELECT region_sid INTO v_region_sid
			  FROM supplier
			 WHERE company_sid = in_company_sid;
		EXCEPTION
			WHEN no_data_found THEN
				v_region_sid := NULL;
		END;

		IF v_region_sid IS NOT NULL THEN
			region_pkg.SetRegionActive(
				in_region_sid	=> v_region_sid,
				in_active		=> 0,
				in_fast			=> 0
			);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
			RETURN;
	END;

	chain.helper_pkg.RevertLogonUCD;
END;

PROCEDURE ReactivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
	v_region_sid				supplier.region_sid%TYPE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.DEACTIVATE_COMPANY)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Reactivate access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;

	BEGIN
		chain.helper_pkg.LogonUCD(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));

		BEGIN
			SELECT region_sid INTO v_region_sid
			  FROM supplier
			 WHERE company_sid = in_company_sid;
		EXCEPTION
			WHEN no_data_found THEN
				v_region_sid := NULL;
		END;

		IF v_region_sid IS NOT NULL THEN
			region_pkg.SetRegionActive(
				in_region_sid	=> v_region_sid,
				in_active		=> 1,
				in_fast			=> 0
			);
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			chain.helper_pkg.RevertLogonUCD;
			RAISE_APPLICATION_ERROR(-20001, 'Intercepted '||SQLERRM||chr(10)||dbms_utility.format_error_backtrace);
			RETURN;
	END;

	chain.helper_pkg.RevertLogonUCD;
END;

PROCEDURE ActivateUser(
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'ActivateUser', 'USER_SID=' || in_user_sid);
END;

PROCEDURE ApproveUser(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)AS
BEGIN
	FOR r IN (
		SELECT delegation_sid
		  FROM supplier_delegation
		 WHERE supplier_sid = in_company_sid
		 MINUS -- remove delegations where this user is already assigned
		SELECT sd.delegation_sid
		  FROM supplier_delegation sd
		  JOIN delegation d ON sd.delegation_sid = d.delegation_sid
		  JOIN delegation_user du ON d.delegation_sid = du.delegation_sid AND du.inherited_from_sid = d.delegation_sid
		 WHERE supplier_sid = in_company_sid
	)
	LOOP
		delegation_pkg.UNSEC_AddUser(security_pkg.getACT, r.delegation_sid, in_user_sid);
	END LOOP;

	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'ApproveUser', 'COMPANY_SID=' || in_company_sid || '\n' ||
									'USER_SID=' || in_user_sid || '\n');

	SyncCompanyTypeRoles(in_company_sid);
END;

PROCEDURE ActivateRelationship(
	in_owner_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)AS
BEGIN
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'ActivateRelationship', 'OWNER_COMPANY_SID=' || in_owner_company_sid || '\n' ||
											'SUPPLIER_COMPANY_SID=' || in_supplier_company_sid || '\n');

	SyncCompanyTypeRoles(in_company_sid => in_owner_company_sid, in_supplier_company_sid => in_supplier_company_sid);
END;

PROCEDURE TerminateRelationship(
	in_owner_company_sid		IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)AS
BEGIN
	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'DeactivateRelationship', 'OWNER_COMPANY_SID=' || in_owner_company_sid || '\n' ||
											'SUPPLIER_COMPANY_SID=' || in_supplier_company_sid || '\n');

	SyncCompanyTypeRoles(in_owner_company_sid);
END;

-- marks a delegation as suitable for use with
-- the supply chain system
PROCEDURE MarkDelegationAsTemplate(
	in_delegation_sid	IN	security_pkg.T_SID_ID
)
AS
	v_name		delegation.name%TYPE;
	v_url		VARCHAR2(1024);
BEGIN
	-- check user has write permissions on delegation_sid
	IF NOT delegation_pkg.CheckDelegationPermission(security.security_pkg.getACT, in_delegation_sid, delegation_pkg.DELEG_PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on delegation sid '||in_delegation_sid);
	END IF;

	BEGIN
		INSERT INTO CHAIN_TPL_DELEGATION (tpl_delegation_sid) VALUES (in_delegation_Sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(-20001, 'Delegation already registered for use with chain');
	END;

	SELECT name
	  INTO v_name
	  FROM delegation
	 WHERE delegation_sid = in_delegation_sid;

	v_url := '/csr/site/delegation/sheet2/supplierQuestionnaire.acds?tplDelegationSid='||in_delegation_sid||chr(38)||'companySid={companySid}';

	chain.questionnaire_pkg.CreateQuestionnaireType(
		in_delegation_sid, -- type_id - XXX: there's a sequence but we don't appear to have to use it?
		v_url,  -- edit_url
		v_url,  -- view_url - consider some kind of qs param for read-only? hardly secure!
		1,  -- owner_can_review
		v_name,
		'Credit360.Delegation.'||in_delegation_sid,  -- XXX: this is some random thing that must be unique
		'csr.supplier_pkg', -- was chainlin_pkg
		NULL, -- group_name
		NULL  -- position
	);
END;

/*
-- some code to delete a delegation prev marked as a template
-- prob nto a great idea as it deletes tons of stuff but...
begin
	DELETE FROM supplier_delegation
	 WHERE tpl_delegation_sid IN (11215573, 11215757);
	delete from CHAIN_TPL_DELEGATION where tpl_delegation_sid in (11215573, 11215757);
	chain.questionnaire_pkg.DeleteQuestionnaireType(11215573);
	chain.questionnaire_pkg.DeleteQuestionnaireType(11215757);
end;
*/

PROCEDURE GetSheets(
	in_company_sid			IN 	security_pkg.T_SID_ID,
	in_tpl_delegation_sid	IN 	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check user has read permissions on the company
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_company_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on company sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT d.delegation_sid, d.NAME, s.start_dtm, s.end_dtm, s.sheet_id,
		       d.editing_url url, s.submission_dtm, s.status, s.last_action_colour
		  FROM supplier_delegation sd
		  JOIN delegation d ON sd.delegation_sid = d.delegation_sid
		  JOIN sheet_with_last_action s ON d.delegation_sid = s.delegation_sid
		 WHERE s.is_visible = 1
		   AND supplier_sid = in_company_sid
		   AND tpl_delegation_sid = in_tpl_delegation_sid
		 ORDER BY d.name, s.start_dtm;
END;

PROCEDURE DeleteQuestionnaires(
	in_company_sid			IN 	security_pkg.T_SID_ID
)
AS
BEGIN
	-- delete the delegations
	FOR r IN (
		SELECT delegation_sid
		  FROM delegation
		 START WITH delegation_sid IN (
			-- go to the root as the supplier_delegation is the supplier deleg, not the top one
			SELECT delegation_sid
			  FROM supplier_delegation
			 WHERE supplier_sid = in_company_sid
		 )
		 CONNECT BY PRIOR delegation_sid = parent_sid
	)
	LOOP
		securableobject_pkg.DeleteSO(security_pkg.getACT, r.delegation_sid);
	END LOOP;

	DELETE FROM supplier_delegation
	 WHERE supplier_sid = in_company_sid;

	DELETE FROM qs_answer_file
	 WHERE survey_response_id IN (SELECT survey_response_id FROM supplier_survey_response WHERE supplier_sid=in_company_sid);

	DELETE FROM qs_response_file
	 WHERE survey_response_id IN (SELECT survey_response_id FROM supplier_survey_response WHERE supplier_sid=in_company_sid);

	DELETE FROM qs_answer_log
	 WHERE survey_response_id IN (SELECT survey_response_id FROM supplier_survey_response WHERE supplier_sid=in_company_sid);

	DELETE FROM quick_survey_answer
	 WHERE survey_response_id IN (SELECT survey_response_id FROM supplier_survey_response WHERE supplier_sid=in_company_sid);

	DELETE FROM supplier_survey_response
	 WHERE supplier_sid=in_company_sid;
END;

PROCEDURE GetMyCompanies(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT s.region_sid, c.name, c.company_sid
		  FROM chain.v$company_user cu
			JOIN chain.company c ON cu.company_sid = c.company_sid
			JOIN supplier s ON cu.company_sid = s.company_sid
		 WHERE cu.user_sid = SYS_CONTEXT('SECURITY','SID');
END;

PROCEDURE GetCompanyProfile(
	in_company_sid	security_pkg.T_SID_ID,
	out_cur	OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check user has read capability permissions on the company
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT s.logo_file_Sid, c.name, s.region_sid
		  FROM supplier s
		  JOIN chain.company c ON s.company_sid = c.company_sid
		 WHERE s.company_sid = in_company_sid;
END;

PROCEDURE GetCompanyProfile(
	out_cur	OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetCompanyProfile(SYS_CONTEXT('SECURITY','CHAIN_COMPANY'), out_cur);
END;

PROCEDURE UploadLogo(
	in_company_sid	IN	security_pkg.T_SID_ID,
	in_cache_key	IN	aspen2.filecache.cache_key%type,
	out_logo_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_logo_file_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;

	SELECT logo_file_sid
	  INTO v_logo_file_sid
	  FROM supplier
	 WHERE company_sid = in_company_sid
	   FOR UPDATE;

	-- this stuff will do security checks for us
	IF v_logo_file_sid IS NULL THEN
		fileupload_pkg.CreateFileUploadFromCache(security_pkg.getact, securableobject_pkg.getsidfrompath(security_pkg.getact, in_company_sid, 'Uploads'), in_cache_key, v_logo_file_sid);
	ELSE
		fileupload_pkg.UpdateFileUploadFromCache(security_pkg.getact, v_logo_file_Sid, in_cache_key);
	END IF;

	UPDATE supplier
	   SET logo_file_sid = v_logo_file_sid
	 WHERE company_sid = in_company_sid;

	out_logo_sid := v_logo_file_sid;
END;

PROCEDURE GetInviteLandingDetails(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- no sec checks needed
	OPEN out_cur FOR
		SELECT chain_invite_landing_preable, chain_invite_landing_qstn
		  FROM customer
		 WHERE app_sid = security_pkg.GetApp;
END;

PROCEDURE UnmakeChainSurvey(
	in_quick_survey_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- questionnaire_pkg looks after permissions (possibly too restricted?)
	chain.questionnaire_pkg.HideQuestionnaireType(in_quick_survey_sid);

	-- TODO: remove permissions for chain users?
END;


PROCEDURE MakeChainSurvey(
	in_quick_survey_sid	IN	security_pkg.T_SID_ID
)
AS
	v_name			quick_survey_version.label%TYPE;
	v_url			VARCHAR2(1024);
BEGIN
	-- check user has write permissions on survey_sid
	--IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_quick_survey_sid, security_pkg.PERMISSION_WRITE) THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on quick survey sid '||in_quick_survey_sid);
	--END IF;

	SELECT label
	  INTO v_name
	  FROM v$quick_survey
	 WHERE survey_sid = in_quick_survey_sid;

	--v_url := '/survey/'||security.securableobject_pkg.GetName(security_pkg.GetAct, in_quick_survey_sid)||'/{companySid}';
	-- The above would be nicer, but the below is easier

	IF chain.questionnaire_pkg.IsProductQuestionnaireType(in_quick_survey_sid) = 1 THEN
		v_url := '/csr/site/quicksurvey/public/chainview.acds?sid='||in_quick_survey_sid||chr(38)||'companySid={companySid}'||chr(38)||'componentId={componentId}';
	ELSE
		v_url := '/csr/site/quicksurvey/public/chainview.acds?sid='||in_quick_survey_sid||chr(38)||'companySid={companySid}'||chr(38)||'forCompanySid={fromCompanySid}';
	END IF;

	-- questionnaire_pkg looks after permissions (possibly too restricted?)
	-- TODO:
	--companySid << root company
	--Capabilities/Company/Create questionnaire type
	chain.questionnaire_pkg.CreateQuestionnaireType(
		in_quick_survey_sid,
		v_url,  -- edit_url
		v_url,  -- view_url - consider some kind of qs param for read-only? currently uses questionnaire_share
		1,  -- owner_can_review
		v_name,
		'QuickSurvey.'||in_quick_survey_sid,  -- XXX: this is some random thing that must be unique
		'csr.supplier_pkg', -- this can be manually overriden in the rare event that it's not the correct pkg
		NULL, -- group_name
		NULL  -- position
	);

	-- TODO: apply permissions to chain users?
END;

PROCEDURE SearchQuestionnairesByType(
	in_questionnaire_type_id	IN	NUMBER,
	in_phrase					IN	VARCHAR2,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT c.company_sid, c.name company_name, qt.name questionnaire_name, qs.entry_dtm submitted_dtm,
				qt.view_url, qs.share_status_name questionnaire_status_name, qs.component_id, cmp.component_code component_description
		  FROM chain.v$company c
		  JOIN chain.v$questionnaire_share qs ON c.company_sid = qs.qnr_owner_company_sid AND c.app_sid = qs.app_sid
		  JOIN chain.questionnaire_type qt ON qs.questionnaire_type_id = qt.questionnaire_type_id
		  LEFT JOIN chain.component cmp ON qs.component_id = cmp.component_id
		 WHERE qs.share_with_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND qs.questionnaire_type_id = in_questionnaire_type_id
		   AND (LOWER(c.name) LIKE '%'||RTRIM(LTRIM(LOWER(in_phrase)))||'%'
		    OR (c.app_sid, c.company_sid) IN (
				SELECT ssr.app_sid, ssr.supplier_sid
				  FROM csr.supplier_survey_response ssr
				  JOIN csr.quick_survey_answer qsa ON ssr.survey_response_id = qsa.survey_response_id AND ssr.app_sid = qsa.app_sid
				 WHERE LOWER(qsa.answer) LIKE '%'||LTRIM(RTRIM(in_phrase))||'%'
				   AND ssr.survey_sid = qs.questionnaire_type_id
				)
		    OR (c.app_sid, c.company_sid) IN (
				-- NOTE: There is a bug in Oracle 11g (BUG: 9149005/14113225) using CONTAINS with ANSI joins, the workaround is to use oracle style joins
				SELECT ssr.app_sid, ssr.supplier_sid
				  FROM csr.supplier_survey_response ssr, csr.qs_answer_file qsaf, csr.qs_response_file qsrf
				 WHERE CONTAINS(qsrf.data, in_phrase, 1) > 0
				   AND ssr.survey_sid = qs.questionnaire_type_id
				   --first join conditions
				   AND ssr.app_sid = qsaf.app_sid AND ssr.survey_response_id = qsaf.survey_response_id
				   --second join conditions
				   AND qsaf.app_sid = qsrf.app_sid AND qsaf.survey_response_id = qsrf.survey_response_id AND qsaf.sha1 = qsrf.sha1 AND qsaf.filename = qsrf.filename AND qsaf.mime_type = qsrf.mime_type
				));
END;

PROCEDURE GetCompanyScores(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on company scores with sid '||in_company_sid);
	END IF;

	OPEN out_score_cur FOR
		SELECT in_company_sid company_sid, s.score, st.score_threshold_id, st.description,
				s.changed_by_user_sid, s.changed_by_user_full_name, s.comment_text,
				st.text_colour, st.background_colour, t.label score_type_label,
				t.score_type_id, t.allow_manual_set, t.format_mask, s.valid_until_dtm,
				NVL(s.valid, 1) valid
		  FROM csr.score_type t
		  LEFT JOIN v$supplier_score s ON t.score_type_id = s.score_type_id
		   AND s.company_sid = in_company_sid
		  LEFT JOIN csr.score_threshold st ON st.score_threshold_id = s.score_threshold_id
		 WHERE (t.allow_manual_set = 1 OR s.score IS NOT NULL OR s.score_threshold_id IS NOT NULL)
		   AND t.hidden = 0
		   AND t.applies_to_supplier = 1
		 ORDER BY t.pos, t.score_type_id;
END;

PROCEDURE GetCompanyScoreLog(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.VIEW_COMPANY_SCORE_LOG)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Score log access denied to company with sid '||in_company_sid);
	END IF;

	OPEN out_score_cur FOR
		SELECT s.supplier_sid, s.supplier_score_id, s.score,
			   s.score_threshold_id, sth.description score_threshold_description,
			   s.score_type_id, sty.label score_type_label,
			   s.set_dtm, s.changed_by_user_sid, cu.full_name changed_by_user_full_name, s.comment_text,
			   s.valid_until_dtm, CASE WHEN s.valid_until_dtm IS NULL OR s.valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
		  FROM csr.supplier_score_log s
		  LEFT JOIN csr.score_threshold sth ON sth.score_threshold_id = s.score_threshold_id
		  JOIN csr.score_type sty ON sty.score_type_id = s.score_type_id
		  LEFT JOIN csr.csr_user cu ON cu.csr_user_sid = s.changed_by_user_sid
		 WHERE s.supplier_sid = in_company_sid
		   AND (in_score_type_id IS NULL OR s.score_type_id = in_score_type_id)
		 ORDER BY s.set_dtm DESC;
END;

PROCEDURE GetSupplierExtrasData(
	in_company_sids				IN  security_pkg.T_SID_IDS,
	out_score_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	t_company_sids				security.T_SID_TABLE DEFAULT security_pkg.SidArrayToTable(in_company_sids);
	v_score_perm_sids			security.T_SID_TABLE DEFAULT chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
	v_tag_perm_sids		 		security.T_SID_TABLE DEFAULT chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ);
BEGIN

	OPEN out_score_cur FOR
		SELECT s.company_sid, s.score, st.score_threshold_id, st.description,
				st.text_colour, st.background_colour, t.label score_type_label,
				t.score_type_id, t.allow_manual_set, t.format_mask, s.valid_until_dtm, s.valid
		  FROM v$supplier_score s
		  JOIN TABLE(t_company_sids) t ON t.column_value = s.company_sid
		  JOIN TABLE(v_score_perm_sids) cts ON cts.column_value = s.company_sid
		  JOIN chain.company c ON s.company_sid = c.company_sid AND s.app_sid = c.app_sid
		  JOIN supplier sup ON s.company_sid = sup.company_sid
		  LEFT JOIN csr.score_threshold st ON st.score_threshold_id = s.score_threshold_id
		  LEFT JOIN csr.score_type t ON s.score_type_id = t.score_type_id
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.deleted = chain.chain_pkg.NOT_DELETED
		   AND t.hidden = 0
		 ORDER BY t.pos;

	OPEN out_tags_cur FOR
		SELECT s.company_sid, rt.region_sid, rt.tag_id, tag.tag
		  FROM supplier s
		  JOIN chain.company c ON s.company_sid = c.company_sid AND s.app_sid = c.app_sid
		  JOIN TABLE(t_company_sids) t ON t.column_value = s.company_sid
		  JOIN TABLE(v_tag_perm_sids) cts ON cts.column_value = c.company_sid
		  JOIN region_tag rt ON s.region_sid = rt.region_sid
		  JOIN tag_group_member tgm ON rt.tag_id = tgm.tag_id
		  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
		  JOIN v$tag tag ON rt.tag_id = tag.tag_id
		 WHERE tg.applies_to_suppliers = 1;
END;

PROCEDURE UNSEC_SetSupplierScoreThold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	supplier_score_log.score_threshold_id%TYPE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE,
	in_set_dtm					IN  supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_valid_until_dtm			IN  supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL, 
	in_force_set_current		IN	NUMBER DEFAULT 1
)
AS
	v_score						quick_survey_submission.overall_score%TYPE := NULL;
	v_score_source_type			supplier_score_log.score_source_type%TYPE := NULL;
	v_score_source_id			supplier_score_log.score_source_id%TYPE := NULL;
	v_count						NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM score_type
	 WHERE app_sid = security_pkg.GetApp
	   AND score_type_id = in_score_type_id
	   AND allow_manual_set = 1;

	IF v_count != 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot manually set score threshold for a score type that doesn''t allow manual setting');
	END IF;

	-- Get current numeric score if there is one
	BEGIN
		SELECT score, score_source_type, score_source_id
		  INTO v_score, v_score_source_type, v_score_source_id
		  FROM v$supplier_score
		 WHERE company_sid = in_company_sid
		   AND score_type_id = in_score_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	UNSEC_UpdateSupplierScore(
		in_supplier_sid			=> in_company_sid,
		in_score_type_id		=> in_score_type_id,
		in_score				=> v_score,
		in_threshold_id			=> in_threshold_id,
		in_comment_text			=> in_comment_text,
		in_score_source_type	=> v_score_source_type,
		in_score_source_id		=> v_score_source_id, 
		in_as_of_date 			=> in_set_dtm,
		in_valid_until_dtm 		=> in_valid_until_dtm,	
		in_force_set_current 	=> in_force_set_current		
	);
END;

PROCEDURE SetSupplierScoreThreshold(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_threshold_id				IN	supplier_score_log.score_threshold_id%TYPE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE
)
AS
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied setting the score for company with sid:' || in_company_sid);
	END IF;

	UNSEC_SetSupplierScoreThold(
		in_company_sid		=> in_company_sid,
		in_score_type_id	=> in_score_type_id,
		in_threshold_id		=> in_threshold_id,
		in_comment_text		=> in_comment_text
	);
END;

PROCEDURE UNSEC_UpdateSupplierScore(
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_score_type_id			IN	score_type.score_type_id%TYPE,
	in_score					IN	quick_survey_submission.overall_score%TYPE,
	in_threshold_id				IN	quick_survey_submission.score_threshold_id%TYPE,
	in_as_of_date				IN	supplier_score_log.set_dtm%TYPE DEFAULT SYSDATE,
	in_comment_text				IN	supplier_score_log.comment_text%TYPE DEFAULT NULL,
	in_valid_until_dtm			IN  supplier_score_log.valid_until_dtm%TYPE DEFAULT NULL,
	in_score_source_type		IN	supplier_score_log.score_source_type%TYPE DEFAULT NULL,
	in_score_source_id			IN	supplier_score_log.score_source_id%TYPE DEFAULT NULL,
	in_propagate_scores			IN	NUMBER DEFAULT 1,
	in_force_set_current		IN	NUMBER DEFAULT 1
)
AS
	v_ask_for_comment			score_type.ask_for_comment%TYPE;
	v_supplier_score_id			supplier_score_log.supplier_score_id%TYPE;
	v_reportable_months			score_type.reportable_months%TYPE;
	
	v_latest_score_dtm			DATE;
BEGIN
	SELECT ask_for_comment INTO v_ask_for_comment
	  FROM score_type
	 WHERE score_type_id = in_score_type_id;

	IF v_ask_for_comment = 'required' AND in_comment_text IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Comments are required when setting scores of type ' || in_score_type_id);
	END IF;
	
	-- if we have exactly the same supplier / start / end / score type - update that score log entry
	SELECT MAX(supplier_score_id)
	  INTO v_supplier_score_id
	  FROM supplier_score_log 
	 WHERE supplier_sid = in_supplier_sid
	   AND score_type_id = in_score_type_id
	   AND set_dtm = in_as_of_date
	   AND valid_until_dtm = in_valid_until_dtm;
	   
	IF v_supplier_score_id IS NULL THEN 	
		INSERT INTO supplier_score_log (supplier_score_id, supplier_sid, score, score_threshold_id,
					set_dtm, score_type_id, comment_text, valid_until_dtm, score_source_type, score_source_id)
		VALUES (supplier_score_id_seq.NEXTVAL, in_supplier_sid, in_score, in_threshold_id,
					in_as_of_date, in_score_type_id, in_comment_text, in_valid_until_dtm, in_score_source_type, in_score_source_id)
		RETURNING supplier_score_id INTO v_supplier_score_id;
	ELSE
		UPDATE supplier_score_log
		   SET 	score = in_score, 
				score_threshold_id = in_threshold_id,
				comment_text = in_comment_text, 
				score_source_type = in_score_source_type, 
				score_source_id = in_score_source_id
		 WHERE supplier_score_id = v_supplier_score_id;
	END IF;

	-- Got to question the "force" behaviour as the current date should always be a calculated on the fly thing,
	-- not something that can be "set" - put in "force_latest" (default on) to maintain backwards compatibility 
	-- Defaults to override and always sets new score as current. Otherwise only does it if there
	-- is no existing score or the set date is same / greater than the latest score
	SELECT MAX(set_dtm) 
	  INTO v_latest_score_dtm
	  FROM supplier_score_log
	 WHERE supplier_sid = in_supplier_sid
	   and score_type_id = in_score_type_id;
	
	-- we force this to be current or we do it based on the as of date being the latest one for this company / score type pair
	IF (in_force_set_current = 1 OR (NVL(v_latest_score_dtm, in_as_of_date) <= in_as_of_date)) THEN
		BEGIN
			INSERT INTO current_supplier_score (score_type_id, company_sid, last_supplier_score_id)
			VALUES (in_score_type_id, in_supplier_sid, v_supplier_score_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE current_supplier_score
				   SET last_supplier_score_id = v_supplier_score_id
				 WHERE company_sid = in_supplier_sid
				   AND score_type_id = in_score_type_id;
		END;
	END IF;

	SELECT t.reportable_months
	  INTO v_reportable_months
	  FROM score_type t
	 WHERE t.score_type_id = in_score_type_id;

	 FOR r IN (
		SELECT aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name='SupplierScores'
	) LOOP
		aggregate_ind_pkg.RefreshGroup(r.aggregate_ind_group_id, TRUNC(SYSDATE, 'MONTH'), TRUNC(ADD_MONTHS(SYSDATE, v_reportable_months), 'MONTH'));
	END LOOP;

	IF in_propagate_scores = 1 THEN
		chain.company_score_pkg.UNSEC_PropagateCompanyScores(
			in_company_sid		=> in_supplier_sid,
			in_score_type_id	=> in_score_type_id,
			in_set_dtm			=> in_as_of_date,
			in_valid_until_dtm	=> in_valid_until_dtm
		);
	END IF;

	chain.chain_link_pkg.SupplierScoreUpdated(in_supplier_sid, in_score_type_id, in_score, in_threshold_id, v_supplier_score_id);
END;

FUNCTION GetScoreTypeIdByKey(
	in_key					IN csr.score_type.lookup_key%TYPE 
) RETURN csr.score_type.score_type_id%TYPE
AS
	v_score_type_id			csr.score_type.score_type_id%TYPE;
BEGIN
	SELECT score_type_id 
	  INTO v_score_type_id
	  FROM csr.score_type
	 WHERE lookup_key = in_key;
	   
	RETURN v_score_type_id;
END;

FUNCTION GetScoreThreshIdByKey(
	in_score_type_id		IN csr.score_threshold.score_type_id%TYPE,
	in_key					IN csr.score_threshold.lookup_key%TYPE 
) RETURN csr.score_threshold.score_threshold_id%TYPE
AS
	v_score_threshold_id	csr.score_threshold.score_threshold_id%TYPE;
BEGIN
	SELECT score_threshold_id 
	  INTO v_score_threshold_id
	  FROM csr.score_threshold
	 WHERE lookup_key = in_key
	   AND score_type_id = in_score_type_id;
	   
	RETURN v_score_threshold_id;
END;

PROCEDURE QuestionnaireShareStatusChange(
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid	IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid	IN	security_pkg.T_SID_ID,
	in_status					IN	chain.chain_pkg.T_SHARE_STATUS
)
AS
	v_score						quick_survey_answer.score%TYPE;
	v_max_score					quick_survey_answer.max_score%TYPE;
	v_threshold_id				quick_survey_submission.score_threshold_id%TYPE;
BEGIN
	-- Questionnaire type ID also happens to be the survey sid
	FOR r IN (
		SELECT questionnaire_type_id, qs.aggregate_ind_group_id, qsr.submission_id, qsr.survey_response_id, qsr.submitted_dtm,
			   st.score_type_id
		  FROM chain.questionnaire q
		  JOIN csr.quick_survey qs ON q.questionnaire_type_id = qs.survey_sid AND q.app_sid = qs.app_sid
		  JOIN csr.supplier_survey_response ssr ON ssr.supplier_sid = q.company_sid AND q.questionnaire_type_id = ssr.survey_sid
		  JOIN csr.v$quick_survey_response qsr ON qs.survey_sid = qsr.survey_sid AND ssr.survey_response_id = qsr.survey_response_id
		  LEFT JOIN csr.score_type st ON qs.score_type_id = st.score_type_id AND st.applies_to_supplier = 1
		 WHERE q.app_sid = security_pkg.GetApp
		   AND q.questionnaire_id = in_questionnaire_id
	) LOOP
		IF in_status IN (chain.chain_pkg.SHARED_DATA_ACCEPTED) THEN
			quick_survey_pkg.CalculateResponseScore(r.survey_response_id, r.submission_id, v_score, v_max_score, v_threshold_id);
			IF r.score_type_id IS NOT NULL THEN
				UNSEC_UpdateSupplierScore(
					in_supplier_sid			=> in_qnr_owner_company_sid,
					in_score_type_id		=> r.score_type_id,
					in_score				=> v_score / v_max_score,
					in_threshold_id			=> v_threshold_id,
					in_comment_text			=> 'Questionnaire share status change',
					in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_QS,
					in_score_source_id		=> r.submission_id
				);
			END IF;
		END IF;

		IF r.aggregate_ind_group_id IS NOT NULL AND r.submitted_dtm IS NOT NULL THEN
			calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id, TRUNC(r.submitted_dtm, 'MONTH'), TRUNC(ADD_MONTHS(SYSDATE,1),'MONTH'));
		END IF;
	END LOOP;
END;

PROCEDURE QuestionnaireStatusChange(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE,
	in_status_id				IN	chain.chain_pkg.T_QUESTIONNAIRE_STATUS
)
AS
	v_score						quick_survey_answer.score%TYPE;
	v_max_score					quick_survey_answer.max_score%TYPE;
	v_threshold_id				quick_survey_submission.score_threshold_id%TYPE;
BEGIN
	-- check if we're resubmitting an approved survey and update the score accordingly
	IF in_status_id = chain.chain_pkg.READY_TO_SHARE THEN -- submitted
		FOR r IN (
			SELECT qsr.survey_response_id, qsr.submission_id, qs.aggregate_ind_group_id, qsr.submitted_dtm, st.score_type_id
			  FROM chain.v$questionnaire_share q
			  JOIN csr.quick_survey qs ON q.questionnaire_type_id = qs.survey_sid AND q.app_sid = qs.app_sid
			  JOIN csr.supplier_survey_response ssr ON ssr.supplier_sid = q.qnr_owner_company_sid AND q.questionnaire_type_id = ssr.survey_sid
			  JOIN csr.v$quick_survey_response qsr ON qs.survey_sid = qsr.survey_sid AND ssr.survey_response_id = qsr.survey_response_id
			  JOIN csr.score_type st ON qs.score_type_id = st.score_type_id
			 WHERE q.app_sid = security_pkg.GetApp
			   AND q.questionnaire_id = in_questionnaire_id
			   AND q.share_status_id = chain.chain_pkg.SHARED_DATA_ACCEPTED
			   AND st.applies_to_supplier = 1
			   AND ROWNUM=1
		) LOOP
			quick_survey_pkg.CalculateResponseScore(r.survey_response_id, r.submission_id, v_score, v_max_score, v_threshold_id);

			UNSEC_UpdateSupplierScore(
				in_supplier_sid			=> in_company_sid,
				in_score_type_id		=> r.score_type_id,
				in_score				=> v_score / v_max_score,
				in_threshold_id			=> v_threshold_id,
				in_comment_text			=> 'Questionnaire share status change',
				in_score_source_type	=> csr_data_pkg.SCORE_SOURCE_TYPE_QS,
				in_score_source_id		=> r.submission_id
			);

			IF r.aggregate_ind_group_id IS NOT NULL THEN
				calc_pkg.AddJobsForAggregateIndGroup(r.aggregate_ind_group_id, TRUNC(r.submitted_dtm, 'MONTH'), TRUNC(ADD_MONTHS(SYSDATE,1),'MONTH'));
			END IF;
		END LOOP;
	END IF;
END;

PROCEDURE FilterSuppliersByScore(
	in_filter_id		IN  chain.filter.filter_id%TYPE,
	in_filter_field_id	IN  NUMBER,
	in_show_all			IN  NUMBER,
	in_ids				IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids				OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_score_perm_sids			security.T_SID_TABLE DEFAULT chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.COMPANY_SCORES, security_pkg.PERMISSION_READ);
BEGIN
	-- pre-populate filter value with all possible options when user has selected "All"
	-- we do this to get descriptions and to be able to drill down by filter_value_id
	IF in_show_all = 1 THEN
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description, colour)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, st.score_threshold_id, st.description, st.bar_colour
		  FROM score_threshold st
		  JOIN chain.filter_field ff ON ff.name = 'ScoreThreshold.'||st.score_type_id
		 WHERE ff.filter_field_id = in_filter_field_id
		   AND NOT EXISTS ( -- exclude any we may have already
				SELECT *
				  FROM chain.filter_value fv
				 WHERE fv.filter_field_id = in_filter_field_id
				   AND fv.num_value = st.score_threshold_id
		 );
	END IF;
	
	chain.filter_pkg.SetThresholdColours(in_filter_field_id);

	chain.filter_pkg.SortScoreThresholdValues(in_filter_field_id);

	SELECT chain.T_FILTERED_OBJECT_ROW(company_sid, fv.group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM v$supplier_score ss
	  JOIN (SELECT DISTINCT object_id FROM TABLE(in_ids)) t ON ss.company_sid = t.object_id
	  JOIN TABLE(v_score_perm_sids) cts ON ss.company_sid = cts.column_value
	  JOIN chain.v$filter_value fv ON ss.score_threshold_id = fv.num_value AND fv.name = 'ScoreThreshold.'||ss.score_type_id
	  JOIN score_type st ON st.score_type_id = ss.score_type_id
	 WHERE fv.filter_id = in_filter_id
	   AND fv.filter_field_id = in_filter_field_id
	   AND (ss.valid = 1 OR st.show_expired_scores = 1);
END;

PROCEDURE FilterQuestionnaireStatuses(
	in_filter_id					IN  chain.filter.filter_id%TYPE,
	in_filter_field_id				IN  NUMBER,
	in_show_all						IN  NUMBER,
	in_sids							IN  chain.T_FILTERED_OBJECT_TABLE,
	out_sids						OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_count				NUMBER(10);
BEGIN
	IF in_show_all = 1 THEN
		--ensure the filter_value rows include all options
		INSERT INTO chain.filter_value (filter_value_id, filter_field_id, num_value, description)
		SELECT chain.filter_value_id_seq.NEXTVAL, in_filter_field_id, s.status_id, s.description
		  FROM (
			SELECT chain.chain_pkg.SHARED_DATA_ACCEPTED status_id, 'Accepted' description FROM dual
			UNION ALL SELECT chain.chain_pkg.SHARING_DATA, 'Submitted' FROM dual
			UNION ALL SELECT chain.chain_pkg.NOT_SHARED_PENDING, 'Pending' FROM dual
			UNION ALL SELECT chain.chain_pkg.NOT_SHARED_OVERDUE, 'Overdue' FROM dual
			UNION ALL SELECT chain.chain_pkg.SHARED_DATA_RETURNED, 'Returned' FROM dual
			UNION ALL SELECT chain.chain_pkg.SHARED_DATA_REJECTED, 'Cancelled' FROM dual
			UNION ALL SELECT chain.chain_pkg.SHARED_DATA_EXPIRED, 'Expired' FROM dual
			UNION ALL SELECT chain.chain_pkg.QNR_INVITATION_NOT_ACCEPTED, 'Invitation not yet accepted' FROM dual
			UNION ALL SELECT chain.chain_pkg.QNR_INVITATION_DECLINED, 'Invitation actively declined' FROM dual
			UNION ALL SELECT chain.chain_pkg.QNR_INVITATION_EXPIRED, 'Invitation expired' FROM dual
			UNION ALL SELECT chain.chain_pkg.NOT_SENT, 'Not sent' FROM dual
		  ) s
		 WHERE NOT EXISTS (
			SELECT *
			  FROM chain.filter_value fv
			 WHERE fv.filter_field_id = in_filter_field_id
			   AND fv.num_value = s.status_id
		 );
	END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(company_sid, group_by_index, filter_value_id)
	  BULK COLLECT INTO out_sids
	  FROM (
		SELECT DISTINCT c.object_id company_sid, fv.group_by_index, fv.filter_value_id
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_sids)) c
		  JOIN chain.v$questionnaire_type_status qts ON c.object_id = qts.company_sid
		  JOIN chain.v$filter_value fv ON qts.status_id = fv.num_value AND fv.name = 'QuestionnaireStatus.'||qts.questionnaire_type_id
		 WHERE fv.filter_id = in_filter_id
		   AND fv.filter_field_id = in_filter_field_id
		 UNION
		SELECT c.object_id company_sid, fv.group_by_index, fv.filter_value_id
		  FROM (SELECT DISTINCT object_id FROM TABLE(in_sids)) c
		  JOIN chain.v$filter_value fv ON fv.filter_id = in_filter_id AND fv.filter_field_id = in_filter_field_id AND fv.num_value = chain.chain_pkg.NOT_SENT
		 WHERE c.object_id NOT IN (
			SELECT qts.company_sid
			  FROM chain.v$questionnaire_type_status qts
			  JOIN chain.v$filter_value fv ON fv.name = 'QuestionnaireStatus.'||qts.questionnaire_type_id
			 WHERE fv.filter_id = in_filter_id
		 )
	   );
END;

PROCEDURE AddSupplierIssue(
	in_supplier_sid				IN	security_pkg.T_SID_ID,
	in_label					IN	issue.label%TYPE,
	in_description				IN	issue_log.message%TYPE,
	in_assigned_to_user_sid		IN	issue.assigned_to_user_sid%TYPE								DEFAULT NULL,
	in_role_sid					IN	security_pkg.T_SID_ID										DEFAULT NULL,
	in_due_dtm					IN	issue.due_dtm%TYPE											DEFAULT NULL,
	in_qs_expr_nc_action_id		IN	non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE	DEFAULT NULL,
	in_is_urgent				IN	NUMBER														DEFAULT NULL,
	in_is_critical				IN	issue.is_critical%TYPE										DEFAULT 0,
	out_issue_id				OUT	issue.issue_id%TYPE
)
AS
	v_region_sid				security_pkg.T_SID_ID;
	v_issue_supplier_id			issue_supplier.issue_supplier_id%TYPE;
	v_issue_log_id				issue_log.issue_log_id%TYPE;
	v_count						NUMBER(10);
	v_issue_log_count			NUMBER;
	v_primary_user_sid			security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'SID');
	v_assigned_to_user_sid		issue.assigned_to_user_sid%TYPE;
BEGIN
	-- TODO better security checks (possibly new capabability in chain?)
	-- Also this function gets called when survey is submitted
	IF NOT chain.capability_pkg.CheckCapability(in_supplier_sid, chain.chain_pkg.ACTIONS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding action to company with sid '||in_supplier_sid);
	END IF;

	v_region_sid := GetRegionSid(in_supplier_sid);

	IF in_assigned_to_user_sid IS NOT NULL THEN
		v_assigned_to_user_sid := in_assigned_to_user_sid;
	ELSIF in_qs_expr_nc_action_id IS NOT NULL THEN
		SELECT count(*)
		  INTO v_count
		  FROM issue_supplier
		 WHERE company_sid = in_supplier_sid
		   AND qs_expr_non_compl_action_id = in_qs_expr_nc_action_id;

		IF v_count > 0 THEN
			-- This issue has been raised already
			out_issue_id := -1;
			RETURN;
		END IF;

		-- TODO: This will fail in a multi-tier implementation
		SELECT MIN(sf.user_sid)
		  INTO v_primary_user_sid
		  FROM chain.supplier_follower sf
		  JOIN chain.customer_options c ON sf.app_sid = c.app_sid AND sf.purchaser_company_sid = c.top_company_sid
		 WHERE sf.supplier_company_sid = in_supplier_sid
		   AND is_primary = 1;

		IF in_role_sid IS NULL THEN
			v_assigned_to_user_sid := v_primary_user_sid;
		END IF;
	END IF;

	issue_pkg.CreateIssue(
		in_label => in_label,
		in_issue_type_id => csr_data_pkg.ISSUE_SUPPLIER,
		in_raised_by_user_sid => NVL(v_primary_user_sid, security_pkg.GetSid),
		in_assigned_to_user_sid => v_assigned_to_user_sid,
		in_assigned_to_role_sid => in_role_sid,
		in_due_dtm => in_due_dtm,
		in_region_sid => v_region_sid,
		in_is_urgent => in_is_urgent,
		in_is_critical => in_is_critical,
		out_issue_id =>out_issue_id);

	--issue_pkg.AddLogEntry(security_pkg.getAct, out_issue_id, 0, NVL(in_description, ' '), null, null, null, v_issue_log_id);
	-- Bypass the security from the above because the user filling in the survey doesn't have permissions on the issue that has been created
	INSERT INTO issue_log
		(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated)
	VALUES
		(issue_log_id_seq.nextval, out_issue_id, NVL(in_description, ' '), NVL(v_primary_user_sid, security_pkg.getsid), SYSDATE, 0)
	RETURNING issue_log_id INTO v_issue_log_id;

	SELECT COUNT(*)
	  INTO v_issue_log_count
	  FROM issue_log
	 WHERE issue_id = out_issue_id;

	UPDATE issue
	   SET first_issue_log_id = CASE WHEN v_issue_log_count = 1 THEN v_issue_log_id ELSE first_issue_log_id END,
		   last_issue_log_id = v_issue_log_id
	 WHERE issue_id = out_issue_id
	   AND app_sid = security_pkg.GetApp;

	BEGIN
		INSERT INTO issue_supplier (
			issue_supplier_id, company_sid, qs_expr_non_compl_action_id)
		VALUES (
			issue_supplier_id_seq.NEXTVAL, in_supplier_sid, in_qs_expr_nc_action_id)
		RETURNING
			issue_supplier_id INTO v_issue_supplier_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- This should rarely happen because of the check above
			UPDATE issue
			   SET deleted = 1
			 WHERE issue_id = out_issue_id;

			out_issue_id := -1;

			RETURN;
	END;

	UPDATE issue
	   SET issue_supplier_id = v_issue_supplier_id
	 WHERE issue_id = out_issue_id;

	-- urgh, add involved roles here as well, again bypassing the security, as no permission on the new issue.
	-- this code needs cleaning up!
	IF in_qs_expr_nc_action_Id IS NOT NULL THEN
		INSERT INTO issue_involvement (issue_id, is_an_owner, user_sid, role_sid)
		SELECT out_issue_id, 0, user_sid, null
		  FROM chain.supplier_follower sf
		  JOIN chain.customer_options c ON sf.app_sid = c.app_sid AND sf.purchaser_company_sid = c.top_company_sid
		 WHERE sf.supplier_company_sid = in_supplier_sid
		   AND is_primary = 0
		 UNION
		SELECT out_issue_id, 0, null, involve_role_sid
		  FROM qs_expr_nc_action_involve_role
		 WHERE qs_expr_non_compl_action_id = in_qs_expr_nc_action_id
		   AND app_sid = security_pkg.GetApp;
	END IF;
END;

PROCEDURE UNSEC_SetTagsInsertOnly(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_ids_t			IN	security.T_SID_TABLE
)
AS
BEGIN
	INSERT INTO region_tag (region_sid, tag_id)
	SELECT in_company_region_sid, column_value
	  FROM TABLE(in_tag_ids_t)
	 WHERE column_value NOT IN (
		SELECT tag_id
		  FROM region_tag
		 WHERE region_sid = in_company_region_sid
		);
END;

PROCEDURE UNSEC_SetTagsInsertOnly(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_tag_ids_t			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
BEGIN
	UNSEC_SetTagsInsertOnly(
		in_company_region_sid	=> in_company_region_sid,
		in_tag_ids_t			=> v_tag_ids_t
	);
END;

PROCEDURE UNSEC_SetTags(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_ids				IN	security_pkg.T_SID_IDS,
	in_tag_group_id 		IN	tag_group.tag_group_id%TYPE DEFAULT NULL
)
AS
	v_tag_ids			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
BEGIN
	DELETE FROM region_tag
	 WHERE region_sid = in_company_region_sid
	   AND tag_id NOT IN (
			SELECT column_value FROM TABLE(v_tag_ids)
		)
	   AND tag_id IN (
			SELECT tag_id
			  FROM tag_group_member tgm
			  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
			 WHERE tg.applies_to_suppliers = 1
			   AND (tg.tag_group_id = in_tag_group_id OR in_tag_group_id IS NULL)
			);

	UNSEC_SetTagsInsertOnly(
		in_company_region_sid	=> in_company_region_sid,
		in_tag_ids_t			=> v_tag_ids
	);
END;

PROCEDURE SetTags(
	in_company_sid		IN	security_pkg.T_SID_ID,
	in_tag_ids			IN	security_pkg.T_SID_IDS,
	in_tag_group_id		IN	tag_group.tag_group_id%TYPE DEFAULT NULL
)
AS
	v_tag_ids					security.T_SID_TABLE := security_pkg.SidArrayToTable(in_tag_ids);
	v_region_sid				security_pkg.T_SID_ID;
	v_ucd_act					security_pkg.T_ACT_ID;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to set tags on company with sid '||in_company_sid);
	END IF;

	BEGIN
		v_region_sid := GetRegionSid(in_company_sid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Setting tags before mapped region created');

			RETURN;
	END;

	-- re-trigger calc jobs for all calcs dependent on any tag ids that are changing
	FOR r IN (
		SELECT tag_id
		  FROM region_tag
		 WHERE region_sid = v_region_sid
		   AND tag_id NOT IN (SELECT column_value from TABLE(v_tag_ids))
		 UNION
		SELECT column_value
		  FROM TABLE(v_tag_ids)
		 WHERE column_value NOT IN (SELECT tag_id FROM region_tag WHERE region_sid = v_region_sid)
	) LOOP
		tag_pkg.INTERNAL_AddCalcJobs(r.tag_id);
	END LOOP;

	UNSEC_SetTags(
		in_company_region_sid	=> v_region_sid,
		in_tag_ids				=> in_tag_ids,
		in_tag_group_id 		=> in_tag_group_id
	);

	region_pkg.ApplyDynamicPlans(v_region_sid, 'Region tags changed');
END;

/* PL-SQL version */
FUNCTION GetTags(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE
AS
	v_tag_ids	security.T_SID_TABLE;
BEGIN
	IF NOT chain.capability_pkg.CheckCapability(in_company_sid, chain.chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;

	SELECT DISTINCT t.tag_id
	  BULK COLLECT INTO v_tag_ids
	  FROM tag t
	  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
	  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
	  JOIN region_tag rt ON rt.tag_id = t.tag_id
	  JOIN supplier s ON s.region_sid = rt.region_sid
	 WHERE s.company_sid = in_company_sid
	   AND tg.applies_to_suppliers = 1;

	RETURN v_tag_ids;
END;

PROCEDURE GetTags(
	in_company_sid				IN	security_pkg.T_SID_ID,
	out_tags					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_tag_ids	security.T_SID_TABLE DEFAULT GetTags(in_company_sid);
BEGIN
	
	OPEN out_tags FOR
		SELECT t.tag_id, t.tag, s.region_sid, tg.tag_group_id, tg.name tag_group_name, tgm.pos
		  FROM v$tag t
		  JOIN TABLE(v_company_tag_ids) tt ON t.tag_id = tt.column_value
		  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
		  JOIN v$tag_group tg ON tgm.tag_group_id = tg.tag_group_id
		  JOIN supplier s ON s.company_sid = in_company_sid;
END;

FUNCTION UNSEC_GetTagsText(
	in_company_region_sid	IN	security_pkg.T_SID_ID,
	in_tag_group_id			IN  tag_group.tag_group_id%TYPE
) RETURN VARCHAR2
AS
	v_text	VARCHAR2(4000);
BEGIN
	SELECT listagg(t.tag, ', ') WITHIN GROUP (ORDER BY t.tag)
	  INTO v_text
	  FROM v$tag t
	  JOIN region_tag rt ON rt.tag_id = t.tag_id
	  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id
	  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id
	 WHERE rt.region_sid = in_company_region_sid
	   AND tg.tag_group_id = in_tag_group_id;

	RETURN v_text;
END;

PROCEDURE FilterCompaniesByTags(
	in_filter_id			IN  chain.filter.filter_id%TYPE,
	in_filter_field_id		IN  NUMBER,
	in_filter_field_name	IN  chain.filter_field.name%TYPE,
	in_group_by_index		IN  NUMBER,
	in_show_all				IN  NUMBER,
	in_ids					IN  chain.T_FILTERED_OBJECT_TABLE,
	out_ids					OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_tag_group_id	 				NUMBER;
	v_tag_perm_sids		 			security.T_SID_TABLE DEFAULT chain.type_capability_pkg.GetPermissibleCompanySids(chain.chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ);
BEGIN
	v_tag_group_id := CAST(regexp_substr(in_filter_field_name,'[0-9]+') AS NUMBER);

	IF in_show_all = 1 THEN
		chain.filter_pkg.ShowAllTags(in_filter_field_id, v_tag_group_id);
	END IF;

	-- Include the current logged-in company if it has permissions on tags as GetPermissibleCompanySids
	-- does not include the current logged-in company in the checks
    IF chain.type_capability_pkg.CheckCapability(chain.chain_pkg.COMPANY_TAGS, security_pkg.PERMISSION_READ) THEN
        v_tag_perm_sids.extend;
        v_tag_perm_sids(v_tag_perm_sids.count) := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
    END IF;

	SELECT chain.T_FILTERED_OBJECT_ROW(s.company_sid, in_group_by_index, fv.filter_value_id)
	  BULK COLLECT INTO out_ids
	  FROM csr.supplier s
	  JOIN TABLE(in_ids) t ON s.company_sid = t.object_id
	  JOIN TABLE(v_tag_perm_sids) cts ON s.company_sid = cts.column_value
	  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid
	  JOIN chain.filter_value fv ON rt.tag_id = fv.num_value
	 WHERE fv.filter_field_id = in_filter_field_id;
END;

/*
Appears to be unused.
Comment out for now in case it turns up in an undocumented helper proc.
PROCEDURE GetMonthlyScoreIndData(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_date						DATE;
	v_dates_table				T_DATE_PAIR_TABLE; -- needs adding if this SP gets reinstated.
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetMonthlyScoreIndData');
	END IF;

	DELETE FROM temp_dates;
	v_date := ADD_MONTHS(TRUNC(in_start_dtm, 'MONTH'), 1);
	WHILE v_date <= ADD_MONTHS(in_end_dtm, 1) AND v_date <= ADD_MONTHS(SYSDATE, 1) LOOP
		-- This is vastly quicker to join to than TABLE OF DATE
		INSERT INTO temp_dates (column_value, eff_date) values (v_date, case when v_date>sysdate then sysdate else v_date end);
		v_date := ADD_MONTHS(v_date, 1);
	END LOOP;

	SELECT td.column_value, td.eff_date
	  BULK COLLECT INTO v_dates_table
	  FROM csr.temp_dates td;

	OPEN out_cur FOR
		SELECT * FROM (
			SELECT s.region_sid, st.supplier_score_ind_sid ind_sid, scores.period_start_dtm, scores.period_end_dtm,
				   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, 1 val_number, null error_code
			  FROM (
				SELECT ssl.score_threshold_id, st.score_type_id, ssl.supplier_sid, ADD_MONTHS(td.column_value, -1) period_start_dtm, td.column_value period_end_dtm,
					   ROW_NUMBER() OVER (PARTITION BY ssl.score_threshold_id, st.score_type_id, ssl.supplier_sid, td.column_value ORDER BY ssl.set_dtm DESC) rn
				  FROM supplier_score_log ssl
				  JOIN score_threshold st ON st.score_threshold_id = ssl.score_threshold_id
				  --JOIN temp_dates td ON ssl.set_dtm < td.eff_date AND ssl.set_dtm >= ADD_MONTHS(td.column_value, -1)
				  JOIN TABLE(v_dates_table) td on ssl.set_dtm < td.eff_date AND ssl.set_dtm >= ADD_MONTHS(td.date, -1)
			  ) scores
			  JOIN supplier s ON s.company_sid = scores.supplier_sid
			  JOIN score_type t ON t.score_type_id = scores.score_type_id
			  JOIN score_threshold st ON st.score_threshold_id = scores.score_threshold_id
			  JOIN aggregate_ind_group_member aigm ON aigm.ind_sid = st.supplier_score_ind_sid
			 WHERE scores.rn = 1
			   AND st.supplier_score_ind_sid IS NOT NULL
			   AND aigm.aggregate_ind_group_id = in_aggregate_ind_group_id
			   AND t.applies_to_supplier = 1

		 UNION ALL

			SELECT s.region_sid, t.supplier_score_ind_sid ind_sid, scores.period_start_dtm, scores.period_end_dtm,
				   csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, st.measure_list_index val_number, null error_code
			  FROM (
				SELECT ssl.score_threshold_id, st.score_type_id, ssl.supplier_sid, ADD_MONTHS(td.column_value, -1) period_start_dtm, td.column_value period_end_dtm,
					   ROW_NUMBER() OVER (PARTITION BY st.score_type_id, ssl.supplier_sid, td.column_value ORDER BY ssl.set_dtm DESC) rn
				  FROM supplier_score_log ssl
				  JOIN score_threshold st ON st.score_threshold_id = ssl.score_threshold_id
				  --JOIN temp_dates td ON ssl.set_dtm < td.eff_date AND ssl.set_dtm >= ADD_MONTHS(td.column_value, -1)
				  JOIN TABLE(v_dates_table) td on ssl.set_dtm < td.eff_date AND ssl.set_dtm >= ADD_MONTHS(td.date, -1)
			  ) scores
			  JOIN supplier s ON s.company_sid = scores.supplier_sid
			  JOIN score_type t ON t.score_type_id = scores.score_type_id
			  JOIN score_threshold st ON st.score_threshold_id = scores.score_threshold_id
			  JOIN aggregate_ind_group_member aigm ON aigm.ind_sid = st.supplier_score_ind_sid
			 WHERE scores.rn = 1
			   AND st.measure_list_index IS NOT NULL
			   AND aigm.aggregate_ind_group_id = in_aggregate_ind_group_id
			   AND t.applies_to_supplier = 1
	  )
	  ORDER BY ind_sid, region_sid, period_start_dtm;
END;
*/

PROCEDURE GetScoreIndValData(
	in_aggregate_ind_group_id	IN	aggregate_ind_group.aggregate_ind_group_id%TYPE,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can run GetIndicatorValues');
	END IF;

	-- The below uses ROW_NUMBER to limit supplier_score rows to no more than one per month per supplier, with
	-- the most recent being used.
	-- The month of the set_dtm is the supplier_score period_start_dtm.
	-- The period_end_dtm is the next score's start_dtm, or the score type's reportable_months if
	-- there isn't a more recent supplier_score

	-- JDB|30/10/14 - Fix: partition over score type as well (previously this was incorrect when the application has
	-- multiple score types)
	OPEN out_cur FOR
		SELECT region_sid, ind_sid, period_start_dtm, period_end_dtm,
			   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, val_number, null error_code
		  FROM (
			SELECT region_sid, ind_sid, period_start_dtm, 1 val_number,
				   LEAD(period_start_dtm, 1, ADD_MONTHS(period_start_dtm, reportable_months)) OVER (PARTITION BY region_sid, score_type_id ORDER BY period_start_dtm ASC) period_end_dtm
			  FROM (
				SELECT ss.supplier_sid, ss.set_dtm, st.supplier_score_ind_sid ind_sid, s.region_sid, TRUNC(ss.set_dtm, 'MONTH') period_start_dtm,
					   ROW_NUMBER() OVER (PARTITION BY ss.supplier_sid, t.score_type_id, TRUNC(ss.set_dtm, 'MONTH') ORDER BY ss.set_dtm DESC) rn,
					   t.reportable_months, t.score_type_id
				  FROM supplier_score_log ss
				  JOIN score_threshold st ON ss.score_threshold_id = st.score_threshold_id
				  JOIN supplier s ON ss.supplier_sid = s.company_sid
				  JOIN score_type t ON st.score_type_id = t.score_type_id
				  JOIN aggregate_ind_group_member aigm ON st.supplier_score_ind_sid = aigm.ind_sid
				 WHERE st.supplier_score_ind_sid IS NOT NULL
				   AND t.applies_to_supplier = 1
				   AND aigm.aggregate_ind_group_id = in_aggregate_ind_group_id
			  )
			 WHERE rn = 1
			)
		 WHERE period_start_dtm < in_end_dtm
		   AND period_end_dtm > in_start_dtm

		UNION ALL

		SELECT region_sid, ind_sid, period_start_dtm, period_end_dtm,
			   csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id, val_number, null error_code
		  FROM (
			SELECT region_sid, ind_sid, period_start_dtm, val_number,
				   LEAD(period_start_dtm, 1, ADD_MONTHS(period_start_dtm, reportable_months)) OVER (PARTITION BY region_sid, score_type_id ORDER BY period_start_dtm ASC) period_end_dtm
			  FROM (
				SELECT ss.supplier_sid, ss.set_dtm, t.supplier_score_ind_sid ind_sid, s.region_sid, TRUNC(ss.set_dtm, 'MONTH') period_start_dtm,
					   ROW_NUMBER() OVER (PARTITION BY ss.supplier_sid, t.score_type_id, TRUNC(ss.set_dtm, 'MONTH') ORDER BY ss.set_dtm DESC) rn,
					   st.measure_list_index val_number, t.reportable_months, t.score_type_id
				  FROM supplier_score_log ss
				  JOIN score_threshold st ON ss.score_threshold_id = st.score_threshold_id
				  JOIN score_type t ON st.score_type_id = t.score_type_id
				  JOIN supplier s ON ss.supplier_sid = s.company_sid
				  JOIN aggregate_ind_group_member aigm ON st.supplier_score_ind_sid = aigm.ind_sid
				 WHERE st.measure_list_index IS NOT NULL
				   AND t.applies_to_supplier = 1
				   AND aigm.aggregate_ind_group_id = in_aggregate_ind_group_id
			  )
			 WHERE rn = 1
			)
		 WHERE period_start_dtm < in_end_dtm
		   AND period_end_dtm > in_start_dtm
		 ORDER BY ind_sid, region_sid, period_start_dtm;
END;

PROCEDURE SynchScoreInds(
	in_parent_ind_sid			IN	security_pkg.T_SID_ID,
	in_helper_proc				IN	VARCHAR2 DEFAULT 'csr.supplier_pkg.GetScoreIndValData'
)
AS
	v_score_cnt_measure_sid		security_pkg.T_SID_ID;
	v_aggregate_ind_group_id	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_out_sid					security_pkg.T_SID_ID;
	v_threshold_measure_sid		security_pkg.T_SID_ID;
BEGIN
	-- Re-use score count from quick survey
	BEGIN
		SELECT measure_sid
		  INTO v_score_cnt_measure_sid
		  FROM measure
		 WHERE name = 'quick_survey_score'
		   AND app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			measure_pkg.CreateMeasure(
				in_name				=> 'quick_survey_score',
				in_description		=> 'Score count',
				in_pct_ownership_applies => 0,
				out_measure_sid		=> v_score_cnt_measure_sid
			);
	END;

	SELECT MIN(aggregate_ind_group_id)
	  INTO v_aggregate_ind_group_id
	  FROM aggregate_ind_group
	 WHERE name = 'SupplierScores';

	IF v_aggregate_ind_group_id IS NULL THEN
		INSERT INTO aggregate_ind_group (aggregate_ind_group_id, helper_proc, name, run_daily, label)
		VALUES (aggregate_ind_group_id_seq.NEXTVAL, in_helper_proc, 'SupplierScores', 0, 'SupplierScores')
		RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;
	END IF;

	FOR st IN (
		SELECT score_type_id, supplier_score_ind_sid, label
		  FROM score_type
		 WHERE app_sid = security_pkg.GetApp
		   AND applies_to_supplier = 1
	) LOOP
		quick_survey_pkg.CreateScoreThresholdMeasure(st.score_type_id, v_threshold_measure_sid);

		IF v_threshold_measure_sid IS NOT NULL AND st.supplier_score_ind_sid IS NULL THEN
			indicator_pkg.CreateIndicator(
				in_parent_sid_id 		=> in_parent_ind_sid,
				in_name 				=> 'score_threshold_'||st.score_type_id,
				in_description 			=> st.label,
				in_active	 			=> 1,
				in_measure_sid			=> v_threshold_measure_sid,
				in_divisibility			=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				in_aggregate			=> 'NONE',
				out_sid_id				=> v_out_sid
			);

			UPDATE ind
			   SET ind_type = csr.csr_data_pkg.IND_TYPE_AGGREGATE,
				   is_system_managed = 1
			 WHERE ind_sid = v_out_sid;

			UPDATE score_type
			   SET supplier_score_ind_sid = v_out_sid
			 WHERE score_type_id = st.score_type_id;

			INSERT INTO aggregate_ind_group_member(aggregate_ind_group_id, ind_sid)
			VALUES (v_aggregate_ind_group_id, v_out_sid);
		END IF;
	END LOOP;

	FOR r IN (
		SELECT st.score_threshold_id, st.description,
			   t.supplier_score_ind_sid parent_ind_sid
		  FROM score_threshold st
		  JOIN score_type t ON st.score_type_id = t.score_type_id
		 WHERE st.supplier_score_ind_sid IS NULL
		   AND t.supplier_score_ind_sid IS NOT NULL
		   AND t.applies_to_supplier = 1
	) LOOP
		indicator_pkg.CreateIndicator(
			in_parent_sid_id 		=> r.parent_ind_sid,
			in_name 				=> lower(r.description),
			in_description 			=> r.description,
			in_active	 			=> 1,
			in_measure_sid			=> v_score_cnt_measure_sid,
			in_divisibility			=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			in_aggregate			=> 'SUM',
			out_sid_id				=> v_out_sid
		);

		UPDATE ind
		   SET ind_type = csr.csr_data_pkg.IND_TYPE_AGGREGATE,
			   is_system_managed = 1
		 WHERE ind_sid = v_out_sid;

		UPDATE score_threshold
		   SET supplier_score_ind_sid = v_out_sid
		 WHERE score_threshold_id = r.score_threshold_id;

		INSERT INTO aggregate_ind_group_member(aggregate_ind_group_id, ind_sid)
		VALUES (v_aggregate_ind_group_id, v_out_sid);
	END LOOP;

	calc_pkg.AddJobsForAggregateIndGroup(v_aggregate_ind_group_id);
END;

PROCEDURE GetSupplierFlowAggregates(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT SYS_REFCURSOR
)
AS
	v_date						DATE;
	v_dates_table				T_DATE_TABLE;
BEGIN
	DELETE FROM csr.temp_dates;
	v_date := ADD_MONTHS(in_start_dtm, 1);
	WHILE v_date <= ADD_MONTHS(in_end_dtm, 1) AND v_date <= ADD_MONTHS(SYSDATE, 1) LOOP
		-- This is vastly quicker to join to than TABLE OF DATE
		INSERT INTO csr.temp_dates (column_value, eff_date) values (v_date, case when v_date>sysdate then sysdate else v_date end);
		v_date := ADD_MONTHS(v_date, 1);
	END LOOP;

	SELECT td.eff_date
	  BULK COLLECT INTO v_dates_table
	  FROM csr.temp_dates td;

	OPEN out_cur FOR
		SELECT ind_sid, region_sid, period period_start_dtm, ADD_MONTHS(period, 1) period_end_dtm,
		       csr.csr_data_pkg.SOURCE_TYPE_AGGREGATE_GRP source_type_id,
		       val_number, null error_code
		  FROM (
			SELECT i.ind_sid, s.region_sid, ADD_MONTHS(TRUNC(fsl.eff_date, 'MONTH'), -1) period, fs.rn val_number
			  FROM chain.supplier_relationship sr
			  JOIN (
				SELECT flow_item_id, flow_state_id, set_dtm, dates.column_value eff_date,
					   ROW_NUMBER() OVER (PARTITION BY flow_item_id, dates.column_value ORDER BY set_dtm DESC, flow_state_log_id DESC) rn
				  FROM csr.flow_state_log fsli
				  JOIN TABLE(v_dates_table) dates on fsli.set_dtm < dates.column_value
			  ) fsl ON sr.flow_item_id = fsl.flow_item_id
			  JOIN (
				SELECT flow_state_id, flow_sid,
					   ROW_NUMBER() OVER (PARTITION BY flow_sid ORDER BY flow_state_id) rn
				  FROM csr.flow_state
			  ) fs ON fs.flow_state_id = fsl.flow_state_id
			  JOIN csr.flow f ON f.flow_sid = fs.flow_sid
			  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
			  JOIN csr.aggregate_ind_group_member aigm ON aigm.aggregate_ind_group_id = f.aggregate_ind_group_id
			  JOIN csr.ind i ON aigm.ind_sid = i.ind_sid
			 WHERE fsl.rn = 1 AND f.aggregate_ind_group_id = in_aggregate_ind_group_id
			   AND UPPER(i.lookup_key) = UPPER('LATEST_SUPPLIER_FLOW_STATE_' || f.flow_sid)

			UNION

			SELECT fs.ind_sid, s.region_sid, ADD_MONTHS(TRUNC(fsl.eff_date, 'MONTH'), -1) period, count(*) val_number
			  FROM csr.flow f
			  JOIN csr.flow_state fs ON f.flow_sid = fs.flow_sid
			  JOIN (
				SELECT flow_item_id, flow_state_id, set_dtm, dates.column_value eff_date,
					   ROW_NUMBER() OVER (PARTITION BY flow_item_id, dates.column_value ORDER BY set_dtm DESC, flow_state_log_id DESC) rn
				  FROM csr.flow_state_log fsli
				  JOIN TABLE(v_dates_table) dates on fsli.set_dtm < dates.column_value
			  ) fsl ON fsl.flow_state_id = fs.flow_state_id
			  JOIN chain.supplier_relationship sr ON sr.flow_item_id = fsl.flow_item_id
			  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
			 WHERE rn = 1 AND f.aggregate_ind_group_id = in_aggregate_ind_group_id
			   AND fs.ind_sid IS NOT NULL
			 GROUP BY fs.ind_sid, s.region_sid, TRUNC(fsl.eff_date, 'MONTH')

			UNION

			SELECT i.ind_sid, s.region_sid, ADD_MONTHS(TRUNC(fsl.eff_date, 'MONTH'), -1) period,
				   TO_NUMBER(TO_CHAR(fsl.set_dtm, 'J')) - TO_NUMBER(TO_CHAR(DATE '1899-12-31', 'J')) val_number
			  FROM csr.flow f
			  JOIN csr.flow_state fs ON fs.flow_sid = f.flow_sid
			  JOIN (
				SELECT flow_item_id, flow_state_id, set_dtm, dates.column_value eff_date,
					   ROW_NUMBER() OVER (PARTITION BY flow_item_id, dates.column_value, flow_state_id ORDER BY set_dtm DESC, flow_state_log_id DESC) rn
				  FROM csr.flow_state_log fsli
				  JOIN TABLE(v_dates_table) dates on fsli.set_dtm < dates.column_value
			  ) fsl ON fsl.flow_state_id = fs.flow_state_id
			  JOIN csr.aggregate_ind_group_member aigm ON f.aggregate_ind_group_id = aigm.aggregate_ind_group_id
			  JOIN csr.ind i ON i.ind_sid = aigm.ind_sid AND UPPER(i.lookup_key) = UPPER(fs.lookup_key)
			  JOIN chain.supplier_relationship sr ON sr.flow_item_id = fsl.flow_item_id
			  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
			 WHERE f.aggregate_ind_group_id = in_aggregate_ind_group_id
			   AND UPPER(i.name) LIKE 'SUPPLIER_FLOW_STATE_DTM_%'
			   AND fsl.rn = 1
		);
END;

-- Currently only called by cvs\clients\marksandspencer\db\chain_setup_body. To be removed.
PROCEDURE CreateSupplierFlowIndicators(
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_start_date				IN	DATE,
	in_end_date					IN	DATE
)
AS
	v_act_id					security_pkg.T_ACT_ID := security_pkg.getact;
	v_aggregate_ind_group_id	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_ind_root_sid				security_pkg.T_SID_ID;
	v_parent_sid				security_pkg.T_SID_ID;
	v_ind_sid					security_pkg.T_SID_ID;
	v_count_measure_sid			security_pkg.T_SID_ID;
	v_date_measure_sid			security_pkg.T_SID_ID;
	v_flow_label				csr.flow.label%TYPE;
	v_flow_state_measure		security_pkg.T_SID_ID;
	v_custom_field				measure.custom_field%TYPE := '';
	v_agg_ind_group_name		csr.aggregate_ind_group.name%TYPE := 'SUPPLIERFLOWSTATES_' || in_flow_sid;
	v_end_date					DATE;
	v_start_date				DATE;
BEGIN
	v_end_date := NVL(in_end_date, SYSDATE);
	IF v_end_date > SYSDATE THEN
		v_end_date := SYSDATE;
	END IF;

	v_start_date := NVL(in_start_date, SYSDATE);
	IF v_start_date > SYSDATE THEN
		v_start_date := SYSDATE;
	END IF;

	IF v_end_date < v_start_date THEN
		RAISE_APPLICATION_ERROR('20001', 'End date must come after start date');
	END IF;

	BEGIN
		SELECT label
		  INTO v_flow_label
		  FROM csr.flow
		 WHERE flow_sid = in_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'The flow with the specified SID could not be found.');
	END;

	SELECT MIN(aggregate_ind_group_id)
	  INTO v_aggregate_ind_group_id
	  FROM aggregate_ind_group
	 WHERE UPPER(name) = v_agg_ind_group_name;

	IF v_aggregate_ind_group_id IS NULL THEN
		INSERT INTO aggregate_ind_group (aggregate_ind_group_id, helper_proc, name, run_daily, label)
		VALUES (aggregate_ind_group_id_seq.NEXTVAL, 'csr.supplier_pkg.GetSupplierFlowAggregates', v_agg_ind_group_name, 0, v_agg_ind_group_name)
		RETURNING aggregate_ind_group_id INTO v_aggregate_ind_group_id;
	END IF;

	UPDATE csr.flow
	   SET aggregate_ind_group_id = v_aggregate_ind_group_id
	 WHERE flow_sid = in_flow_sid;

	v_ind_root_sid := security.securableobject_pkg.GetSidFromPath(
		security.security_pkg.GetAct,
		security.security_pkg.GetApp,
		'Indicators');

	BEGIN
		SELECT measure_sid
		  INTO v_count_measure_sid
		  FROM csr.measure
		 WHERE name='#';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.measure_pkg.CreateMeasure(
				in_name				=> '#',
				in_description		=> '#',
				out_measure_sid		=> v_count_measure_sid
			);
	END;

	BEGIN
		SELECT ind_sid
		  INTO v_parent_sid
		  FROM csr.ind
		 WHERE lookup_key = 'SUPPLIER_FLOW_STATES_' || in_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- If the top level indicator already exists, delete it and its descendents.
	-- (Any descendents that relate to unchanged/new workflow states will be recreated
	-- with data recalculated by scrag, while any descendents relating to removed
	-- states will be deleted.)
	IF v_parent_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(v_act_id, v_parent_sid);
	END IF;

	csr.indicator_pkg.CreateIndicator(
		in_name				=> 'SUPPLIER_FLOW_STATES_' || in_flow_sid,
		in_description		=> 'Flow states: ' || v_flow_label,
		in_lookup_key		=> 'SUPPLIER_FLOW_STATES_' || in_flow_sid,
		in_parent_sid_id	=> v_ind_root_sid,
		out_sid_id			=> v_parent_sid
	);

	BEGIN
		SELECT measure_sid
		  INTO v_flow_state_measure
		  FROM csr.measure
		 WHERE name='SUPPLIER_FLOW_STATES_' || in_flow_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.measure_pkg.CreateMeasure(
				in_name						=> 'SUPPLIER_FLOW_STATES_' || in_flow_sid,
				in_description				=> 'Flow states for flow ' || v_flow_label,
				in_pct_ownership_applies 	=> 0,
				in_custom_field				=> '',
				in_divisibility				=> csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
				out_measure_sid				=> v_flow_state_measure
			);
	END;

	SELECT measure_sid
	  INTO v_date_measure_sid
	  FROM csr.measure
	 WHERE LOWER(name)='date';

	FOR r IN (
		SELECT flow_state_id, label, lookup_key
		  FROM flow_state
		 WHERE flow_sid = in_flow_sid
		   AND is_deleted = 0
		 ORDER BY flow_state_id
	) LOOP
		-- rebuild the flow state measure items in case new flow items have been added
		v_custom_field := v_custom_field || r.label || CHR(13) || CHR(10);

		aggregate_ind_pkg.SetAggregateInd(
			in_aggr_group_name => v_agg_ind_group_name,
			in_parent          => v_parent_sid,
			in_desc            => r.label,
			in_lookup_key      => r.lookup_key || '_' || in_flow_sid,
			in_name            => 'SUPPLIER_FLOW_STATE_COUNT_'||UPPER(r.flow_state_id),
			in_measure_sid     => v_count_measure_sid,
			in_divisibility    => csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			out_ind_sid        => v_ind_sid);

		UPDATE flow_state
		   SET ind_sid = v_ind_sid
		 WHERE flow_state_id = r.flow_state_id;

		aggregate_ind_pkg.SetAggregateInd(
			in_aggr_group_name => v_agg_ind_group_name,
			in_parent          => v_parent_sid,
			in_desc            => r.label || ' set date',
			in_lookup_key      => r.lookup_key,
			in_name            => 'SUPPLIER_FLOW_STATE_DTM_'||UPPER(r.flow_state_id),
			in_measure_sid     => v_date_measure_sid,
			in_aggregate	   => 'NONE',
			in_divisibility    => csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
			out_ind_sid        => v_ind_sid);
	END LOOP;

	UPDATE measure
	   SET custom_field = v_custom_field
	 WHERE measure_sid = v_flow_state_measure;

	aggregate_ind_pkg.SetAggregateInd(
		in_aggr_group_name => v_agg_ind_group_name,
		in_parent          => v_parent_sid,
		in_desc            => 'Latest flow state for ' || v_flow_label,
		in_lookup_key      => 'LATEST_SUPPLIER_FLOW_STATE_' || in_flow_sid,
		in_name            => 'LATEST_SUPPLIER_FLOW_STATE_' || in_flow_sid,
		in_measure_sid     => v_flow_state_measure,
		in_aggregate 	   => 'NONE',
		in_divisibility    => csr_data_pkg.DIVISIBILITY_LAST_PERIOD,
		out_ind_sid        => v_ind_sid);

	calc_pkg.AddJobsForAggregateIndGroup(v_aggregate_ind_group_id, TRUNC(v_start_date, 'MONTH'), ADD_MONTHS(TRUNC(v_end_date, 'MONTH'), 1));

	-- flow_pkg.SetItemState already checks if the flow has an agg. ind. group and creates a new
	-- scrag job if so.
END;

-- Primarily used for Funds (Properties).
PROCEDURE GetSuppliers(
	in_supplier_sid		IN		supplier.company_sid%TYPE	DEFAULT NULL,	-- NULL = Get All
	out_cur				OUT		security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Security??
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only administrators can get a list of companies.');
	END IF;

	-- If no supplier SID was given, get all.
		OPEN out_cur FOR
			SELECT c.name, s.company_sid, s.region_sid
			  FROM chain.company c
			  JOIN supplier s
				ON s.company_sid = c.company_sid
			WHERE s.company_sid = NVL(in_supplier_sid, s.company_sid);
END;

PROCEDURE NukeChain
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'NukeChain can only be run as BuiltIn/Administrator');
	END IF;

	INSERT INTO LINK_AUDIT (action_dtm, function_name, message)
	VALUES(SYSDATE, 'NukeChain', 'Nuke verified');

	DELETE FROM csr.property_fund WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM csr.fund WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	UPDATE csr.mgmt_company SET company_sid = NULL WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier_delegation WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM chain_tpl_delegation WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM current_supplier_score WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier_score_log WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier_survey_response WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	UPDATE issue SET issue_supplier_id = NULL WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM issue_supplier WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

FUNCTION GetRegSidsFromCompSids (
	in_company_sids				IN	security_pkg.T_SID_IDS
) RETURN security_pkg.T_SID_IDS
AS
	v_company_table				security.T_SID_TABLE;
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	v_company_table	:= security_pkg.SidArrayToTable(in_company_sids);
	
	SELECT region_sid 
	  BULK COLLECT INTO v_region_sids
	  FROM TABLE(v_company_table) c
	  JOIN csr.supplier s ON c.column_value = s.company_sid;
	
	IF ((in_company_sids IS NOT NULL) AND (in_company_sids.COUNT > 0) AND (v_region_sids.COUNT = 0)) THEN
		RAISE_APPLICATION_ERROR(-20001, 'No regions found - you may be using companies not backed by regions');
	END IF;
	  
	RETURN v_region_sids;
END;

PROCEDURE GetRegSidsFromCompSids (
	in_company_sids				IN	security_pkg.T_SID_IDS, 
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_region_table				security.T_SID_TABLE;
	v_region_sids				security_pkg.T_SID_IDS;
BEGIN
	v_region_sids := GetRegSidsFromCompSids(in_company_sids);
	v_region_table := security_pkg.SidArrayToTable(v_region_sids);
	
	OPEN out_cur FOR
		SELECT column_value 
		  FROM TABLE(v_region_table);
END;

END supplier_pkg;
/

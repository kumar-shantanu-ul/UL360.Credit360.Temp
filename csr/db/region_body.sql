CREATE OR REPLACE PACKAGE BODY CSR.Region_Pkg AS

FUNCTION GetGeoCommonality(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_geo_level		IN NUMBER
) RETURN NUMBER;

FUNCTION ParseLink(
	in_sid	IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID
AS 
	v_sid	security_pkg.T_SID_ID;
BEGIN
	BEGIN
		SELECT NVL(link_to_region_sid, region_sid) INTO v_sid
		  FROM region
		 WHERE region_sid = in_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_sid := in_sid;
	END;
	RETURN v_sid;
END;

FUNCTION ProcessStartPoints(
	in_act_id   	IN  security_pkg.T_ACT_ID,
	in_parent_sids	IN	security_pkg.T_SID_IDS,
	in_include_root	IN	NUMBER
)
RETURN security.T_ORDERED_SID_TABLE
AS
	v_parsed_sids	security_pkg.T_SID_IDS;
BEGIN
	-- Process link and check permissions
	FOR i IN in_parent_sids.FIRST .. in_parent_sids.LAST
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_parent_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||in_parent_sids(i));
		END IF;		
		
		IF in_include_root = 0 THEN			
			v_parsed_sids(i) := ParseLink(in_parent_sids(i));
		ELSE 
			v_parsed_sids(i) := in_parent_sids(i);
		END IF;
	END LOOP;
	RETURN security_pkg.SidArrayToOrderedTable(v_parsed_sids);
END;

PROCEDURE CheckParent(
	in_parent_sid	IN	security_pkg.T_SID_ID
)
AS
	v_deleg_plans_sid	security_pkg.T_SID_ID;
	v_is_under_tree		NUMBER(10);
	v_trash_sid			security_pkg.T_SID_ID;
BEGIN	
	-- check if parent_sid_id is legit -- i.e. under a region tree root
	SELECT COUNT(*)
	  INTO v_is_under_tree
	  FROM region_tree
	 WHERE region_tree_root_sid IN (
		SELECT region_sid
		  FROM region
		 START WITH region_sid = in_parent_sid
	     CONNECT BY PRIOR parent_sid = region_sid
	 );

	BEGIN
		v_trash_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'Trash');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	BEGIN
		v_deleg_plans_sid := SecurableObject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY', 'ACT'), SYS_CONTEXT('SECURITY', 'APP'), 'DelegationPlans');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL;
	END;

	IF v_is_under_tree = 0 AND in_parent_sid NOT IN (v_trash_sid, v_deleg_plans_sid) THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NOT_UNDER_REGION_TREE, 'Parent '||in_parent_sid||' is not under a region tree or the trash can');
	END IF;	
END;

PROCEDURE INTERNAL_RemoveInheritedRoles(
	in_region_sid	IN security_pkg.T_SID_ID
)
AS
	v_region_sid	security_pkg.T_SID_ID;
BEGIN
	-- Resolve links
	SELECT NVL(link_to_region_sid, region_sid)
	  INTO v_region_sid
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	 -- Process for this region and all its descendents
	 FOR r IN (
		SELECT NVL(link_to_region_sid, region_sid) region_sid
		  FROM region
		 START WITH region_sid = v_region_sid
	   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	 ) LOOP
		-- Delete role memberships that don't inherit from this region and its ancestors or any region that
		-- links to it or their ancestors, so long as they are not system managed (we assume these are
		-- managed elsewhere by different logic than region heirachy)
		DELETE FROM region_role_member
		 WHERE region_sid = r.region_sid
		   AND inherited_from_sid NOT IN (
				SELECT region_sid
				  FROM region
				 START WITH r.region_sid IN (region_sid, link_to_region_sid)
			   CONNECT BY PRIOR parent_sid IN (region_sid, link_to_region_sid)
		   )
		   AND role_sid IN (
			SELECT role_sid
			  FROM role
			 WHERE is_system_managed = 0
		   );
		
		DELETE FROM actions.project_region_role_member
		 WHERE region_sid = r.region_sid
		   AND inherited_from_sid NOT IN (
				SELECT region_sid
				  FROM region
				 START WITH r.region_sid IN (region_sid, link_to_region_sid)
			   CONNECT BY PRIOR parent_sid IN (region_sid, link_to_region_sid)
		   );
	 END LOOP;
END;

PROCEDURE INTERNAL_InhertRolesFromParent(
	in_region_sid		IN	security_pkg.T_SID_ID
)
AS
	v_parent_sid		security_pkg.T_SID_ID;
	v_retries			NUMBER;
BEGIN
	
	-- Get parent, resolving if it's a link
	BEGIN
		SELECT NVL(p.link_to_region_sid, p.region_sid)
		  INTO v_parent_sid
		  FROM region c, region p
		 WHERE c.region_sid = in_region_sid
		   AND p.region_sid = c.parent_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- No parent, nothing to ihherit
			RETURN;
	END;
	
	-- Inherit roles from parent
	FOR r IN (
		SELECT rrm.user_sid, rrm.role_sid, rrm.inherited_from_sid
		  FROM region_role_member rrm, region rgn
		 WHERE rgn.region_sid = v_parent_sid
		   AND rrm.region_sid = NVL(rgn.link_to_region_sid, rgn.region_sid)
	) LOOP
		-- This is ugly, but there is a remote chance of the insert statement throwing
		-- DUP_VAL_ON_INDEX. The db performs the SELECT...MINUS before locking the table
		-- for the insert. This leaves a small window for another transaction to complete
		-- that inserts a row that causes a conflict.
		--
		-- Keep trying until it works, but with an arbitrary limit of 100 attempts as a safety
		-- net. If this is hit, we know something's gone wrong.
		v_retries := 100;
		WHILE TRUE
		LOOP
			BEGIN
				INSERT INTO region_role_member (user_sid, role_sid, inherited_from_sid, region_sid)
					SELECT r.user_sid, r.role_sid, r.inherited_from_sid, NVL(link_to_region_sid, region_sid)
					  FROM region
					 START WITH region_sid = in_region_sid
				   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
					 MINUS
					SELECT user_sid, role_sid, inherited_from_sid, region_sid
					  FROM region_role_member
					 WHERE user_sid = r.user_sid
					   AND role_sid = r.role_sid
					   AND inherited_from_sid = r.inherited_from_sid;
				EXIT;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					v_retries := v_retries - 1;
					IF v_retries = 0 THEN
						RAISE;
					END IF;
			END;
		END LOOP;
	END LOOP;
	
	FOR r IN (
		SELECT rrm.project_sid, rrm.user_sid, rrm.role_sid, rrm.inherited_from_sid
		  FROM actions.project_region_role_member rrm, region rgn
		 WHERE rgn.region_sid = v_parent_sid
		   AND rrm.region_sid = NVL(rgn.link_to_region_sid, rgn.region_sid)
	) LOOP
		v_retries := 100;
		WHILE TRUE
		LOOP
			BEGIN
				INSERT INTO actions.project_region_role_member (project_sid, user_sid, role_sid, inherited_from_sid, region_sid)
					SELECT r.project_sid, r.user_sid, r.role_sid, r.inherited_from_sid, NVL(link_to_region_sid, region_sid)
					  FROM region
					 START WITH region_sid = in_region_sid
				   CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
					 MINUS
					SELECT project_sid, user_sid, role_sid, inherited_from_sid, region_sid
					  FROM actions.project_region_role_member;
				EXIT;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					v_retries := v_retries - 1;
					IF v_retries = 0 THEN
						RAISE;
					END IF;
			END;
		END LOOP;
	END LOOP;
	
	chain.filter_pkg.ClearCacheForAllUsers;
END;

PROCEDURE ApplyDynamicPlans(
	in_region_sid					IN	region.region_sid%TYPE,
	in_source_msg					IN	VARCHAR2
)
AS
BEGIN
	-- TODO: Move this out into a C# API call
	campaigns.campaign_pkg.ApplyDynamicCampaign(in_region_sid);
	
	-- Reapply any dynamic delegation plans that might involve the new region
	deleg_plan_pkg.ApplyDynamicPlans(in_region_sid, in_source_msg);
END;

/**
 * Create a new region
 *
 * @param	in_parent_sid		Parent object
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	out_region_sid			The SID of the created object
 */
PROCEDURE CreateRegion(
	in_act_id						IN	security_pkg.T_ACT_ID         DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid					IN	security_pkg.T_SID_ID, 
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name							IN	region.name%TYPE,
	in_description					IN	region_description.description%TYPE,
	in_active						IN	region.active%TYPE			  DEFAULT 1,	      
	in_pos							IN	region.pos%TYPE    			  DEFAULT NULL,	
	in_geo_type         			IN	region.geo_type%TYPE		  DEFAULT region_pkg.REGION_GEO_TYPE_INHERITED,
	in_info_xml						IN	region.info_xml%TYPE          DEFAULT NULL,
	in_geo_country					IN	region.geo_country%TYPE       DEFAULT NULL,
	in_geo_region					IN	region.geo_region%TYPE        DEFAULT NULL,
	in_geo_city						IN	region.geo_city_id%TYPE       DEFAULT NULL,
	in_map_entity					IN	region.map_entity%TYPE        DEFAULT NULL,
	in_geo_longitude				IN  region.geo_longitude%TYPE 	  DEFAULT NULL,	
	in_geo_latitude					IN  region.geo_latitude%TYPE 	  DEFAULT NULL,
	in_egrid_ref					IN 	region.egrid_ref%TYPE         DEFAULT NULL,
	in_region_ref					IN	region.region_ref%TYPE        DEFAULT NULL,
	in_acquisition_dtm				IN	region.acquisition_dtm%TYPE   DEFAULT TRUNC(SYSDATE),
	in_disposal_dtm					IN	region.disposal_dtm%TYPE	  DEFAULT NULL,
	in_region_type					IN	region.region_type%TYPE	      DEFAULT csr_data_pkg.REGION_TYPE_NORMAL,
	in_apply_deleg_plans			IN	NUMBER						  DEFAULT 1,
	in_write_calc_jobs				IN	NUMBER						  DEFAULT 1,
	out_region_sid					OUT	region.region_sid%TYPE
)
AS
  	v_path					VARCHAR2(2000);
	v_pos					region.pos%TYPE;
	v_parent_sid_id			security_pkg.T_SID_ID;
	v_latitude				postcode.country.latitude%TYPE;
	v_longitude				postcode.country.longitude%TYPE;
	v_geo_country			region.geo_country%TYPE;
	v_geo_region			region.geo_region%TYPE;
	v_geo_city				region.geo_city_id%TYPE;
	v_map_entity			region.map_entity%TYPE;
	v_egrid_ref				region.egrid_ref%TYPE;	
	v_is_in_region_tree		NUMBER;	
BEGIN
    IF in_parent_sid IS NULL THEN
        -- default to regions
        v_parent_sid_id := Securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Regions');
	ELSE    
        -- parse parent sid in order to resolve any links
        v_parent_Sid_Id := region_pkg.ParseLink(in_parent_sid);        
	END IF;
	
	CheckParent(in_parent_sid);

	IF in_pos IS NULL THEN
		SELECT NVL(MAX(pos),0)+1 
		  INTO v_pos 
		  FROM region 
		 WHERE parent_sid = v_parent_sid_id;
	ELSE   
		v_pos := in_pos;
	END IF;
	
	-- XXX: I'm not sure what REGION_GEO_TYPE_OTHER intends, but the check constraint CK_GEO_TYPE
	-- specifies that all geo properties are null if this is selected.
	IF in_geo_type != region_pkg.REGION_GEO_TYPE_OTHER THEN
		SELECT COUNT(*)
		  INTO v_is_in_region_tree
		  FROM region
		 WHERE app_sid = in_app_sid AND region_sid = v_parent_sid_id;

		-- get geo properties off the parent incl egrid	
		IF v_is_in_region_tree > 0 THEN
			SELECT geo_country, geo_region, geo_city_id, map_entity, geo_longitude, geo_latitude, egrid_ref
			  INTO v_geo_country, v_geo_region, v_geo_city, v_map_entity, v_longitude, v_latitude, v_egrid_ref
			  FROM region
			 WHERE app_sid = in_app_sid AND region_sid = v_parent_sid_id;
		END IF;
		 
		IF in_geo_type != region_pkg.REGION_GEO_TYPE_INHERITED THEN	
			-- if not inherited then override various it all (apart from egrid which is treated separately)
			IF in_geo_type = region_pkg.REGION_GEO_TYPE_LOCATION THEN
				-- set initial latitude/longitude just to prevent constraint errors
				-- we set proper coordinates using region_pkg.SetLatLong in same transaction
				v_longitude := 0;
				v_latitude := 0;
				IF in_geo_longitude IS NOT NULL AND in_geo_latitude IS NOT NULL THEN
					v_longitude := in_geo_longitude - 360 * FLOOR((in_geo_longitude+180)/360);
					v_latitude := CASE WHEN in_geo_latitude < -90 THEN -90 WHEN in_geo_latitude > 90 THEN 90 ELSE in_geo_latitude END;
				END IF;
				
			ELSIF in_geo_type = region_pkg.REGION_GEO_TYPE_OTHER THEN
				v_longitude := NULL;
				v_latitude := NULL;
				v_geo_country := NULL;
				v_geo_region := NULL;
				v_geo_city := NULL;
			ELSIF in_geo_city IS NOT NULL THEN 
				SELECT longitude, latitude
				  INTO v_longitude, v_latitude
				  FROM postcode.city
				 WHERE city_id = in_geo_city;
			ELSIF in_geo_region IS NOT NULL THEN
				SELECT longitude, latitude
				  INTO v_longitude, v_latitude
				  FROM postcode.region
				 WHERE country = in_geo_country 
				   AND region = in_geo_region;
			ELSIF in_geo_country IS NOT NULL THEN
				SELECT longitude, latitude
				  INTO v_longitude, v_latitude
				  FROM postcode.country
				 WHERE country = in_geo_country;
			END IF;
			v_geo_country := in_geo_country;
			v_geo_region := in_geo_region;
			v_geo_city := in_geo_city;
			v_map_entity := in_map_entity;					
		END IF;
	END IF;	
	
	group_pkg.CreateGroupWithClass(in_act_id, v_parent_sid_id, security_pkg.GROUP_TYPE_SECURITY,
		REPLACE(in_name, '/', '\'), --'
		class_pkg.getClassID('CSRRegion'), out_region_sid);

	--security_pkg.debugmsg('new region sid='||out_region_sid||', parent_sid='||v_parent_sid_id||', app_sid='||in_app_sid||
	--	', name='||REPLACE(in_name, '/', '\')||', active='||in_active||', pos='||v_pos||', geo_type='||in_geo_type||
	--	', geo_latitude='||v_latitude||', geo_longitude='||v_longitude||', geo_country='||v_geo_country||
	--	', geo_region='||v_geo_region||', geo_city='||v_geo_city||', map_entity='||v_map_entity||
	--	', egrid_ref='||NVL(in_egrid_ref, v_egrid_ref)||', lookup_key='||in_lookup_key||', acquisition_dtm='||in_acquisition_dtm);
		
	INSERT INTO region (region_sid, parent_sid, app_sid, name, active, pos, geo_type, 
		geo_latitude, geo_longitude, info_xml, geo_country, geo_region, geo_city_id, map_entity, egrid_ref, region_ref,
		acquisition_dtm, disposal_dtm, region_type)
	VALUES (out_region_sid, v_parent_sid_id, in_app_sid, REPLACE(NVL(in_name, in_description), '/', '\'), --'
		in_active, v_pos, in_geo_type, 
		v_latitude, v_longitude, in_info_xml, v_geo_country, v_geo_region, v_geo_city, v_map_entity, 
		NVL(in_egrid_ref, v_egrid_ref), -- inherit from parent if not specified
		in_region_ref,
		in_acquisition_dtm, in_disposal_dtm, in_region_type);

	INSERT INTO region_description (region_sid, lang, description)
		SELECT out_region_sid, lang, in_description
		  FROM v$customer_lang;

	-- inherit events from parent
	region_event_pkg.InheritEvents(out_region_sid);
	
	-- add object to the DACL (the region is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, out_region_sid, security_pkg.PERMISSION_STANDARD_READ);

	-- Inherit procedure documents
	INSERT INTO region_proc_doc
		(region_sid, doc_id, inherited)
	  SELECT out_region_sid, doc_id, 1
	    FROM region_proc_doc
	   WHERE region_sid = v_parent_sid_id;
	   
	INSERT INTO region_proc_file
		(region_sid, meter_document_id, inherited)
	  SELECT out_region_sid, meter_document_id, 1
	    FROM region_proc_file
	   WHERE region_sid = v_parent_sid_id;

	IF in_write_calc_jobs = 1 THEN
		csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);
		
		MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
		USING (SELECT app_sid, ind_sid, MIN(period_start_dtm) period_start_dtm, MAX(period_end_dtm) period_end_dtm
			     FROM val v
			    WHERE region_sid = in_parent_sid
			      AND ind_sid IN (SELECT ind_sid 
								    FROM ind 
								   WHERE app_sid = in_app_sid
								     AND aggregate IN ('DOWN', 'FORCE DOWN'))
			    GROUP BY app_sid, ind_sid
				UNION
				-- Add region to scrag scenario file.
				SELECT app_sid, ind_root_sid, calc_start_dtm, calc_end_dtm
				  FROM customer c
				 WHERE app_sid = in_app_sid
				) v
		   ON (v.app_sid = vcl.app_sid AND v.ind_sid = vcl.ind_sid)
		 WHEN MATCHED THEN
			UPDATE 
			   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
				   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
		 WHEN NOT MATCHED THEN
			INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
			VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);	
	END IF;
	
	-- Inherit roles from parent
	INSERT INTO region_role_member
	  (user_sid, region_sid, role_sid, inherited_from_sid)
		SELECT user_sid, out_region_sid, role_sid, inherited_from_sid -- Inherit from wherever the parent inherited from, not from the parent
		  FROM region_role_member
		 WHERE region_sid = v_parent_sid_id;

	-- Inherit actions project roles
	INSERT INTO actions.project_region_role_member
	  (project_sid, user_sid, region_sid, role_sid, inherited_from_sid)
		SELECT project_sid, user_sid, out_region_sid, role_sid, inherited_from_sid -- Inherit from wherever the parent inherited from, not from the parent
		  FROM actions.project_region_role_member
		 WHERE region_sid = v_parent_sid_id;

	-- Inherit meter alarms
	meter_alarm_pkg.OnNewRegion(out_region_sid);
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, in_app_sid, out_region_sid,
		'Created "{0}"', INTERNAL_GetRegionPathString(out_region_sid));
	
	IF in_apply_deleg_plans = 1 THEN
		ApplyDynamicPlans(out_region_sid, 'Region created');
	END IF;

	compliance_pkg.OnRegionCreate(out_region_sid);
END;

PROCEDURE GetRegionTrees(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- TODO : security
	OPEN out_cur FOR
        SELECT rt.region_tree_root_sid, rt.last_recalc_dtm, rt.is_primary, r.name, r.description
          FROM region_tree rt, v$region r 
         WHERE rt.region_tree_root_sid = r.region_sid
           AND rt.app_sid = in_app_sid
           AND rt.app_sid = r.app_sid
           AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, r.region_sid, security_pkg.PERMISSION_READ)=1;
END;


PROCEDURE CreateRegionTreeRoot(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_name						IN	security_pkg.T_SO_NAME,
	in_is_primary				IN	region_tree.is_primary%TYPE,
	out_region_tree_root_sid	OUT	security_pkg.T_SID_ID
)
AS
	v_sid 			security_pkg.T_SID_ID;
	v_regions_sid	security_pkg.T_SID_ID;
	v_main_sid      security_pkg.T_SID_ID;
	v_pos			NUMBER;
BEGIN
	-- check whether we've broken into multiple trees already
	SELECT MIN(region_tree_root_sid)
	  INTO v_sid
	  FROM region_tree
	 WHERE app_sid = in_app_sid;
	 
	v_regions_sid := securableObject_pkg.GetSidFromPath(in_act_id, in_app_sid, 'Regions');
	
	-- rename what we had move as 'main'
	-- (unless our new one is called main!)
	IF v_sid = v_regions_sid THEN
		BEGIN
			-- create a new container/region called 'regions/main'
			group_pkg.CreateGroupWithClass(in_act_id, v_regions_sid, security_pkg.GROUP_TYPE_SECURITY, 'Main',
				security_pkg.SO_CONTAINER, v_main_sid);
		EXCEPTION 
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			-- create a new container/region called 'regions/null'
			group_pkg.CreateGroupWithClass(in_act_id, v_regions_sid, security_pkg.GROUP_TYPE_SECURITY, NULL,
				security_pkg.SO_CONTAINER, v_main_sid);
		END;
		-- add object to the DACL (the region is a group, so it has permissions on itself)
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(v_main_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, v_main_sid, security_pkg.PERMISSION_STANDARD_READ);
		    
		INSERT INTO region (app_sid, region_sid, parent_sid, name, active, pos, region_type)
		VALUES (in_app_sid, v_main_sid, v_regions_sid, 'Main', 1, 1, csr_data_pkg.REGION_TYPE_ROOT);

		INSERT INTO region_description (region_sid, lang, description)
			SELECT v_main_sid, lang, 'Main'
			  FROM v$customer_lang;
		    
		-- move stuff from regions under this new container
		FOR r IN (
		    SELECT region_sid FROM region WHERE parent_sid = v_regions_sid AND region_sid != v_main_sid
		)
		LOOP
		    securableobject_pkg.MoveSO(in_act_id, r.region_sid, v_main_sid);
		END LOOP;
	
		-- add the tree
		INSERT INTO region_tree
			(region_tree_root_sid, is_primary)
		VALUES
			(v_main_sid, 1);
			
		-- if the user somehow had anything propagating down Regions then knock that on the head
		UPDATE ind
		   SET prop_down_region_tree_sid = v_main_sid
		 WHERE prop_down_region_tree_sid = v_regions_sid;

		-- delete the old primary region tree
		DELETE FROM region_tree
		 WHERE region_tree_root_sid = v_regions_sid;
	END IF;	

	-- if we just created a new "Main" node above, and they want to create one called
	-- main, then DON'T create a new thing called main, just use what we had above
	IF v_sid = v_regions_sid AND LOWER(in_name) = 'main' THEN
		out_region_tree_root_sid := securableobject_pkg.GetSidFromPath(in_act_id, v_regions_sid, 'Main');
		UPDATE region_tree
		   SET region_tree_root_sid = out_region_tree_root_sid
		 WHERE region_tree_root_sid = v_sid;
	ELSE
		group_pkg.CreateGroupWithClass(in_act_id, v_regions_sid, security_pkg.GROUP_TYPE_SECURITY, in_name,
			security_pkg.SO_CONTAINER, out_region_tree_root_sid);
		-- add object to the DACL (the region is a group, so it has permissions on itself)
		acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_region_tree_root_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
			security_pkg.ACE_FLAG_DEFAULT, out_region_tree_root_sid, security_pkg.PERMISSION_STANDARD_READ);

		-- zap any other primaries
		IF in_is_primary = 1 THEN
			UPDATE region_tree
			   SET is_primary = 0
			 WHERE app_sid = in_app_sid;
		END IF;

		INSERT INTO region_tree (region_tree_root_sid, app_sid, is_primary, is_system_managed)
		VALUES (out_region_tree_root_sid, in_app_sid, in_is_primary, CASE in_is_primary WHEN 0 THEN 1 ELSE 0 END);
		
		SELECT COUNT(*) + 1
		  INTO v_pos
		  FROM region
		 WHERE app_sid = in_app_sid AND parent_sid = v_regions_sid;
		 
		INSERT INTO region (app_sid, region_sid, parent_sid, name, active, pos, region_type)
		VALUES (in_app_sid, out_region_tree_root_sid, v_regions_sid, in_name, 1, v_pos, csr_data_pkg.REGION_TYPE_ROOT);

		INSERT INTO region_description (region_sid, lang, description)
			SELECT out_region_tree_root_sid, lang, in_name
			  FROM v$customer_lang;
	END IF;
END;

PROCEDURE INTERNAL_CheckParentChildTypes(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_parent_sid					IN	security_pkg.T_SID_ID
)
AS
	v_region_type					NUMBER(10);
	v_parent_type					NUMBER(10);
BEGIN
	SELECT region_type 
      INTO v_region_type 
      FROM region
     WHERE region_sid = in_region_sid;
	 
	SELECT region_type 
      INTO v_parent_type 
      FROM region
     WHERE region_sid = in_parent_sid;
	
	IF v_region_type = csr_data_pkg.REGION_TYPE_SPACE AND v_parent_type != csr_data_pkg.REGION_TYPE_PROPERTY THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_PARENT_TYPE, 'New parent is wrong region type.');			
	END IF;
END;

FUNCTION INTERNAL_CopyRegion(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_new_parent_sid			IN	security_pkg.T_SID_ID,
	in_is_paste_under_secondary	IN	NUMBER,
	in_name						IN	region.name%TYPE DEFAULT NULL,
	in_description				IN	region_description.description%TYPE DEFAULT NULL,
	in_copy_geo_data			IN  NUMBER DEFAULT 0
) RETURN NUMBER
AS
	CURSOR c IS
		SELECT so.name, description, pos, geo_type, info_xml, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude, map_entity, egrid_ref, lookup_key, region_ref, disposal_dtm, acquisition_dtm, active, app_sid,
			   region_type, link_to_region_sid
		  FROM v$region r 
		  JOIN security.securable_object so ON r.region_sid = so.sid_id
		 WHERE region_Sid = in_region_sid;
		 
	o						c%ROWTYPE;
	v_new_sid				security_pkg.T_SID_ID;
	v_sid					security_pkg.T_SID_ID;
	v_child_count			NUMBER(10);
	v_converted_to_link		BOOLEAN;
	v_start_dtm				DATE;
    v_pct          			pct_ownership.pct%TYPE;	
    v_not_found				BOOLEAN;
	v_under_self			NUMBER(10);
	v_properties_enabled	security_pkg.T_SID_ID;

BEGIN
	SELECT COUNT(*)
	  INTO v_under_self
	  FROM region
	 WHERE region_sid = in_region_sid
	 START WITH region_sid = in_new_parent_sid
   CONNECT BY PRIOR parent_sid = region_sid;

	IF v_under_self > 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_MOVED_UNDER_SELF, 'Can''t copy an object under itself');
	END IF;
	
	INTERNAL_CheckParentChildTypes(in_region_sid, in_new_parent_sid);
	
	OPEN c;
	FETCH c INTO o;
	v_not_found := c%NOTFOUND;
	CLOSE c;	
	IF v_not_found THEN
		RETURN null; -- not found
	END IF;
	
	IF in_copy_geo_data = 0 THEN
	   o.geo_type := REGION_GEO_TYPE_INHERITED; 
	   o.geo_country := NULL;
	   o.geo_region := NULL;
	   o.geo_city_id := NULL;
	   o.map_entity := NULL;
	   o.geo_longitude := NULL;
	   o.geo_latitude := NULL;
	END IF;
	
	-- We can't just copy the geographic stuff as it might be screwed, i.e. pasting one country under another.
	-- For now we simply inherit from the parent
	region_pkg.CreateRegion(
		in_act_id						=> in_act_id,
		in_parent_sid					=> in_new_parent_sid,
		in_app_sid 						=> o.app_sid,
		in_name							=> NVL(in_name, o.name), 
		in_description					=> NVL(in_description, o.description),
		in_active						=> o.active,
		in_info_xml						=> o.info_xml,
		in_acquisition_dtm				=> o.acquisition_dtm,
		in_disposal_dtm					=> o.disposal_dtm,
		in_region_type					=> o.region_type,
		in_apply_deleg_plans			=> 0, -- suppress plan application until copy is complete
		in_geo_type						=> o.geo_type,
		in_geo_country					=> o.geo_country,
		in_geo_region					=> o.geo_region,
		in_geo_city						=> o.geo_city_id,
		in_map_entity					=> o.map_entity,		
		in_geo_longitude				=> o.geo_longitude,
		in_geo_latitude					=> o.geo_latitude,
		out_region_sid					=> v_new_sid);
	
	-- copy over tags
	INSERT INTO region_tag (region_sid, tag_id)
		SELECT v_new_sid, tag_id
		  FROM region_tag
		 WHERE region_sid = in_region_sid;

	-- If copying under a secondary region tree then do Properties as links
	-- i.e. most likely primary structure is a _physical_ asset structure
	-- and so secondary trees tend to link to physical assets
	SELECT COUNT(*) 
	  INTO v_child_count
	  FROM region 
	 WHERE parent_sid = in_region_sid;
	
	v_converted_to_link := FALSE;
	IF o.link_to_region_sid IS NOT NULL THEN
		-- there's a link already so point this to it and then bail
		UPDATE region 
		   SET link_to_region_sid = o.link_to_region_sid
		 WHERE region_sid = v_new_sid;
		v_converted_to_link := TRUE;
	END IF;
	 
	-- XXX: should we include METER types here too? Probably
	IF in_is_paste_under_secondary = 1 AND (o.region_type = csr_data_pkg.REGION_TYPE_PROPERTY OR v_child_count = 0) THEN
		UPDATE region 
		   SET link_to_region_sid = in_region_sid
		 WHERE region_sid = v_new_sid;
		v_converted_to_link := TRUE; 
	END IF;
	
	IF v_converted_to_link THEN
		-- The region may have inherited role membership during creation (beofre it was a link), 
		-- when we convert it to a link the membership has to be transfered to the region that is linked to.
		-- Remove any references to the region that is now a link from the 
		-- region_role_member and actions.project region_role_member tables
		DELETE FROM region_role_member
		 WHERE region_sid = v_new_sid;
		DELETE FROM actions.project_region_role_member
		 WHERE region_sid = v_new_sid;
		-- Inherit roles from the parent of the link
		INTERNAL_InhertRolesFromParent(v_new_sid);
		-- Inherit roles from the parent of the link
		meter_alarm_pkg.OnDeleteRegion(v_new_sid);
		meter_alarm_pkg.OnConvertRegionToLink(v_new_sid);
		-- Nothing more to do, return the new sid
		RETURN v_new_sid;
	END IF;
	
	-- copy over meter stuff
	INSERT INTO all_meter 
		(region_sid, note, active, app_sid, meter_source_type_id, reference, crc_meter, export_live_data_after_dtm, days_measure_conversion_id, costdays_measure_conversion_id, approved_by_sid, approved_dtm, is_core, meter_type_id, lower_threshold_percentage, upper_threshold_percentage, metering_version)
		SELECT v_new_sid, note, active, app_sid, meter_source_type_id, reference, crc_meter, export_live_data_after_dtm, days_measure_conversion_id, costdays_measure_conversion_id, approved_by_sid, approved_dtm, is_core, meter_type_id, lower_threshold_percentage, upper_threshold_percentage, metering_version
		  FROM all_meter
		 WHERE region_sid = in_region_sid;

	INSERT INTO meter_input_aggr_ind
		(region_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id)
		SELECT v_new_sid, meter_input_id, aggregator, meter_type_id, measure_sid, measure_conversion_id
		  FROM meter_input_aggr_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND region_sid = in_region_sid;

	INSERT INTO meter_utility_contract (region_sid, utility_contract_id)
		SELECT v_new_sid, utility_contract_id
		  FROM meter_utility_contract
		 WHERE region_sid = in_region_sid;
	
	-- NOTE: we don't copy Events -- seems silly to do this, but maybe someone will
	-- want this in future. It seems less likely because events are most likely very
	-- specific to the original region being copied.
	
	-- copy over any documents that were set at ths location (i.e. NOT inherited).
	INSERT INTO region_proc_doc
		(region_sid, doc_id, inherited)
	  SELECT v_new_sid, doc_id, inherited
	    FROM region_proc_doc
	   WHERE region_sid = in_region_sid
	     AND inherited = 0;

	-- some stuff isn't applicable if we're copying a whole secondary tree
	IF in_is_paste_under_secondary = 0 THEN
		-- Copy roles
		-- automatic inherit roles
		-- uniqueness not necessary, since it is the current behaviour
		INSERT INTO region_role_member (user_sid, region_sid, role_sid, inherited_from_sid)
			SELECT user_sid, v_new_sid region_sid, role_sid, v_new_sid inherited_from_sid
			  FROM region_role_member rrm
			 WHERE rrm.region_sid = in_region_sid
			   AND rrm.inherited_from_sid = rrm.region_sid;
	
		-- argh -- why is it called 'meter_document'??! Anyway, copy this over too 
		-- so long as it's not inherited. 'region_proc' isn't much better. Grr.
		INSERT INTO region_proc_file
			(region_sid, meter_document_id, inherited)
		  SELECT v_new_sid, meter_document_id, inherited
			FROM region_proc_file
		   WHERE region_sid = in_region_sid
			 AND inherited = 0;
		
		-- Inherit meter alarms etc.
		meter_alarm_pkg.OnCopyRegion(in_region_sid, v_new_sid);
	END IF;
	
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE parent_sid = in_region_sid
	)
	LOOP
		v_sid := INTERNAL_CopyRegion(
			in_act_id					=> in_act_id,
			in_region_sid				=> r.region_sid,
			in_new_parent_sid			=> v_new_sid,
			in_is_paste_under_secondary	=> in_is_paste_under_secondary,
			in_copy_geo_data			=> in_copy_geo_data);
	END LOOP;
	
	FOR r IN (
		SELECT start_dtm, pct
		  FROM pct_ownership
		 WHERE region_sid = in_region_sid
		 )
	LOOP
		SetPctOwnership(
		in_act_id 		=> in_act_id,	
		in_region_sid	=> v_new_sid,
		in_start_dtm	=> r.start_dtm,
		in_pct			=> r.pct);
	END LOOP;

	-- Ensure property fully setup on copy...
	SELECT property_flow_sid
	INTO v_properties_enabled
	FROM customer
	WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF v_properties_enabled IS NOT NULL THEN
		IF o.region_type = csr_data_pkg.REGION_TYPE_PROPERTY THEN
		 	FOR r in (
				SELECT street_addr_1, street_addr_2, city, state, postcode, company_sid, property_type_id, property_sub_type_id
		  		  FROM csr.property
		 		 WHERE region_Sid = in_region_sid
			)
			LOOP
				property_pkg.MakeProperty(
					in_act_id				=> SYS_CONTEXT('SECURITY', 'ACT'),
					in_company_sid			=> r.company_sid,
					in_region_sid			=> v_new_sid,
					in_property_type_id		=> r.property_type_id,
					in_property_sub_type_id	=> r.property_sub_type_id,
					in_street_addr_1		=> r.street_addr_1,
					in_street_addr_2		=> r.street_addr_2,
					in_city					=> r.city,
					in_state				=> r.state,
					in_postcode				=> r.postcode,
					in_is_create			=>	1
				);
			END LOOP;
		END IF;
	END IF;

	RETURN v_new_sid;
END;

PROCEDURE CopyRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_new_parent_sid	IN	security_pkg.T_SID_ID,
	out_sid				OUT	security_pkg.T_SID_ID
)
AS	
	v_copying_primary_tree 		NUMBER(10);
	v_pasting_under_secondary	NUMBER(10);
	v_app_sid				security_pkg.T_SID_ID;
	v_is_root				NUMBER(10);
	v_sid					security_pkg.T_SID_ID;
	v_region_sid			security_pkg.T_SID_ID;
	v_name					security_pkg.T_SO_NAME;
	v_base_name				security_pkg.T_SO_NAME;
	v_description			region_description.description%TYPE;
	v_base_description		region_description.description%TYPE;
	v_duplicate_count 		NUMBER(10);
	v_parent_sid			security_pkg.T_SID_ID;
	v_copy_geo_data			NUMBER(10);
	v_has_parent			NUMBER(10);
	v_parent_node_sid		security_pkg.T_SID_ID;	
	v_parent_geo_type		region.geo_type%TYPE;
	v_parent_geo_country	region.geo_country%TYPE;
	v_parent_geo_region		region.geo_region%TYPE;
	v_geo_type				region.geo_type%TYPE;
	v_geo_city_id 			region.geo_city_id%TYPE;
	v_geo_region			region.geo_region%TYPE;
	v_fits_geo_hierarchy	NUMBER(10);
BEGIN
	-- fetch the app sid -> since they're supplying the ACT like all the other region SPs,
	-- then we should fetch the App_Sid ourselves I guess rather than relying on security_pkg.GetAPp
	SELECT app_sid
	  INTO v_app_sid
	  FROM region
	 WHERE region_sid = in_region_sid;

	-- are they copying a region_tree_root?
	SELECT COUNT(*) 
	  INTO v_is_root
	  FROM region_tree
	 WHERE region_tree_root_sid = in_region_sid;
	
	IF v_is_root = 1 THEN
		-- if copying a root then must be pasted at top, so reset the v_parent_sid
		SELECT region_root_sid
		  INTO v_parent_sid
		  FROM customer
		 WHERE app_sid = v_app_sid;
		 
		v_pasting_under_secondary := 0; -- this doesn't get used
	ELSE
		v_parent_sid := in_new_parent_sid;

		v_pasting_under_secondary := region_tree_pkg.IsInSecondaryTree(in_region_sid);
	END IF;
	
	v_copying_primary_tree := region_tree_pkg.IsInPrimaryTree(in_region_sid);

	-- if NO_DATA_FOUND then it's in the Trash? Should we check for this?

	
	-- figure out a unique name. Hmm -- we don't want it to race though.
	-- This looks like it'll race but it's the same code as used in securableobject_pkg.
	-- Both bits of code probably need looking at. Worst case it'll just barf.
	SELECT name, description
	  INTO v_name, v_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;

	v_base_name := v_name; -- keep a copy
	v_duplicate_count := 0;
	WHILE TRUE 
	LOOP
		BEGIN
			v_sid := securableobject_pkg.GetSIDFromPath(in_act_id, v_parent_sid, v_name);
		EXCEPTION
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				-- ok -- got a name that wiill work
				EXIT;
		END;
		-- XXX: I18N issue here
		v_name := v_base_name || ' (copy)';
		v_duplicate_count := v_duplicate_count + 1;
		IF v_duplicate_count > 1 THEN
			v_name := v_base_name||' (copy '||v_duplicate_count||')';
		END IF;
	END LOOP;
		
	-- now figure out a non duplicate description
	v_base_description := v_description; -- keep a copy
	v_duplicate_count := 0;
	WHILE TRUE 
	LOOP
		SELECT MIN(description)
		  INTO v_description
		  FROM v$region
		 WHERE parent_sid = v_parent_sid
		   AND LOWER(description) = LOWER(v_description);

		IF v_description IS NULL THEN
			-- ok -- got a name that wiill work
			EXIT;
		END IF;

		-- XXX: I18N issue here
		v_description := v_base_description || ' (copy)';
		v_duplicate_count := v_duplicate_count + 1;
		IF v_duplicate_count > 1 THEN
			v_description := v_base_description||' (copy '||v_duplicate_count||')';
		END IF;
	END LOOP;
	
	IF v_is_root = 1 THEN
		-- it's a root. Return the new tree sid into v_parent_sid
		region_pkg.CreateRegionTreeRoot(in_act_id, v_app_sid, v_description, 0, v_parent_sid);
		v_region_sid := in_region_sid;
		
		-- it's ok to copy geograpic data. This is a root so we know that things will fit a geographic hierarchy.
		v_copy_geo_data := 1;
		
		IF v_copying_primary_tree = 1 THEN
			-- if we copied the primary tree for the first time then in_region_sid will point
			-- to app/Regions, however the first time round there's some fiddling where it moves
			-- the primary region tree under a new sec obj, so get the root again for safety's sake
			SELECT region_tree_root_sid
			  INTO v_region_sid
			  FROM region_tree
			 WHERE is_primary = 1
			   AND app_sid = v_app_sid;
		END IF;
		FOR r IN (	
			SELECT region_sid, name, description
			  FROM v$region
			 WHERE parent_sid = v_region_sid
		)
		LOOP    
			out_sid := INTERNAL_CopyRegion(
				in_act_id					=> in_act_id,
				in_region_sid				=> r.region_sid,
				in_new_parent_sid			=> v_parent_sid,
				in_is_paste_under_secondary	=> 1,
				in_name						=> r.name,
				in_description				=> r.description,
				in_copy_geo_data			=> v_copy_geo_data);
		END LOOP;
		-- return the root
		out_sid := v_parent_sid;
	ELSE
		-- not a root
	
		-- determine whether geographic data can be copied 
        v_parent_node_sid := v_parent_sid;		
		LOOP
			SELECT 1 - COUNT(*) 
			  INTO v_has_parent 
			  FROM region_tree
			 WHERE region_tree_root_sid = v_parent_node_sid;
        
			SELECT geo_type, geo_country, geo_region, parent_sid 
			  INTO v_parent_geo_type, v_parent_geo_country, v_parent_geo_region, v_parent_node_sid 
			  FROM region 
			 WHERE region_sid = v_parent_node_sid;
  
			IF v_has_parent = 0 OR v_parent_geo_type != region_pkg.REGION_GEO_TYPE_INHERITED THEN 
				EXIT;
			END IF;    
		END LOOP;  

		v_copy_geo_data := 0;
		IF v_parent_geo_type = REGION_GEO_TYPE_INHERITED THEN 
			v_copy_geo_data := 1;	
		ELSE
			SELECT MIN(CASE r.geo_type 
					   	WHEN REGION_GEO_TYPE_COUNTRY	THEN r.geo_type
					   	WHEN REGION_GEO_TYPE_REGION	THEN r.geo_type
					   	WHEN REGION_GEO_TYPE_CITY	THEN r.geo_type 
					   ELSE NULL END) 
			  INTO v_geo_type
			  FROM region r			
				   START WITH r.region_sid = in_region_sid
				   CONNECT BY r.parent_sid = PRIOR r.region_sid;
			
			IF v_geo_type = REGION_GEO_TYPE_REGION OR v_geo_type = REGION_GEO_TYPE_CITY THEN
				SELECT geo_city_id, geo_region
				 INTO v_geo_city_id, v_geo_region
				 FROM region r	
				WHERE geo_type = v_geo_type AND rownum = 1	
					  START WITH r.region_sid = in_region_sid
					  CONNECT BY r.parent_sid = PRIOR r.region_sid;
			END IF;
			
			IF v_geo_type IS NULL THEN	-- inherited or location or other or map entity
				v_copy_geo_data := 1;	
			ELSIF v_geo_type = REGION_GEO_TYPE_CITY AND v_parent_geo_type = REGION_GEO_TYPE_COUNTRY THEN				
			
				v_fits_geo_hierarchy := 0;
				
				SELECT COUNT(*) 
				  INTO v_fits_geo_hierarchy
				  FROM postcode.city
				 WHERE city_id = v_geo_city_id
				   AND country = v_parent_geo_country;
			
				IF v_fits_geo_hierarchy != 0 THEN 
					v_copy_geo_data := 1;	
				END IF;
			
			ELSIF v_geo_type = REGION_GEO_TYPE_CITY AND v_parent_geo_type = REGION_GEO_TYPE_REGION THEN				
			
				v_fits_geo_hierarchy := 0;
			
				SELECT COUNT(*) 
				  INTO v_fits_geo_hierarchy
				  FROM postcode.city
				 WHERE city_id = v_geo_city_id
				   AND region = v_parent_geo_region;
			
				IF v_fits_geo_hierarchy != 0 THEN 
					v_copy_geo_data := 1;	
				END IF;
			
			ELSIF v_geo_type = REGION_GEO_TYPE_REGION AND v_parent_geo_type = REGION_GEO_TYPE_COUNTRY THEN				
			
				v_fits_geo_hierarchy := 0;
			
				SELECT COUNT(*) 
				  INTO v_fits_geo_hierarchy
				  FROM postcode.city
				 WHERE region = v_geo_region
				   AND country = v_parent_geo_country;
			
				IF v_fits_geo_hierarchy != 0 THEN 
					v_copy_geo_data := 1;	
				END IF;
			
			END IF;
		END IF; 
		
		-- copy region(s)
		out_sid := INTERNAL_CopyRegion(
			in_act_id					=> in_act_id,
			in_region_sid				=> in_region_sid,
			in_new_parent_sid			=> v_parent_sid,
			in_is_paste_under_secondary	=> CASE WHEN v_copying_primary_tree = 1 AND v_pasting_under_secondary = 1 THEN 1 ELSE 0 END,
			in_name						=> v_name,
			in_description				=> v_description,
			in_copy_geo_data			=> v_copy_geo_data);		
	END IF;

	-- Reapply any dynamic delegation plans that might involve the new region
	ApplyDynamicPlans(out_sid, 'Region copied'); 
END;	

PROCEDURE AmendRegionTreeRoot(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_tree_root_sid		IN	security_pkg.T_SID_ID,
	in_name						IN	security_pkg.T_SO_NAME,
	in_is_primary				IN	region_tree.is_primary%TYPE
)
AS
	v_app_sid	security_pkg.T_SID_ID;
BEGIN
	SecurableObject_pkg.RenameSO(in_act_id, in_region_tree_root_sid, REPLACE(in_name,'/','\')); --'
	
	SELECT app_sid 
	  INTO v_app_sid	
	  FROM region_tree
	 WHERE region_tree_root_sid = in_region_tree_root_sid;
	
	-- zap any other primaries
	IF in_is_primary = 1 THEN
		UPDATE region_tree
		   SET is_primary = 0
		 WHERE app_sid =v_app_sid;
	END IF;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, 
	in_region_tree_root_sid, 'Set name to "{0}" ({1})', in_name, CASE WHEN in_is_primary = 1 THEN 'primary' ELSE 'not primary' END);
	
	
	UPDATE region_tree
	   SET is_primary = in_is_primary
	 WHERE region_tree_root_sid = in_region_tree_root_sid;
END;

/**
 * Returns the path of a region
 * 	
 * @param 	in_act_id 	Access token
 * @param 	in_sid_id 	The sid of the object
 * @return 	A string containing the path of the object relative to <app>/regions
 */
FUNCTION GetFlattenedRegionPath(
    in_act 		IN Security_Pkg.T_ACT_ID,
	in_sid_id 	IN Security_Pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_name	VARCHAR2(4000) := null;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_sid_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	FOR tree_rec IN (
		SELECT level, region_sid, parent_sid, name 
		  FROM region
	   CONNECT BY PRIOR parent_sid = region_sid
		 START WITH region_sid = in_sid_id
	)
	LOOP
		-- Append the current level to the name-so-far
		IF v_name IS NULL THEN
			v_name := tree_rec.NAME;
		ELSE
		    v_name := tree_rec.NAME || '/' || v_name;
		END IF;
	END LOOP;
	IF v_name IS NULL THEN
	    RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid_id||' was not found');
	END IF;
	v_name := '/' || v_name;
	RETURN v_name;
END;


-- sane version using the description not the name
FUNCTION UNSEC_GetFlattenedRegionPath2(
	in_sid_id 	IN Security_Pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_name	VARCHAR2(4000) := null;
BEGIN	
	FOR tree_rec IN (
		SELECT level, region_sid, parent_sid, description 
		  FROM v$region
	   CONNECT BY PRIOR parent_sid = region_sid
		 START WITH region_sid = in_sid_id
	)
	LOOP
		-- Append the current level to the name-so-far
		IF v_name IS NULL THEN
			v_name := tree_rec.DESCRIPTION;
		ELSE
		    v_name := tree_rec.DESCRIPTION || '/' || v_name;
		END IF;
	END LOOP;
	IF v_name IS NULL THEN
	    RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The object with SID '||in_sid_id||' was not found');
	END IF;
	v_name := '/' || v_name;
	RETURN v_name;
END;


PROCEDURE GetRegionPath(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN  
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	-- umm -- don't we need to end at their starting point?
	OPEN out_cur FOR
		SELECT region_sid, description
		  FROM v$region
		 START WITH region_sid = in_region_sid 
	   CONNECT BY PRIOR parent_sid = region_sid
		ORDER BY LEVEL DESC;
END;

PROCEDURE AddAggregateJobs(
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID
)
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT app_sid, ind_sid, v_calc_start_dtm period_start_dtm, v_calc_end_dtm period_end_dtm
	  		 FROM ind) i
	   ON (vcl.app_sid = i.app_sid AND vcl.ind_sid = i.ind_sid)
	 WHEN MATCHED THEN
		UPDATE 
		   SET vcl.start_dtm = LEAST(vcl.start_dtm, i.period_start_dtm),
			   vcl.end_dtm = GREATEST(vcl.end_dtm, i.period_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (i.ind_sid, i.period_start_dtm, i.period_end_dtm);
END;

-- private
PROCEDURE AddAggregateJobsForCO2Inds
AS
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
	v_count							NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM ind i
	 WHERE i.gas_type_id IS NOT NULL;
	
	IF v_count = 0 THEN
		RETURN;
	END IF;

	csr_data_pkg.LockApp(csr_data_pkg.LOCK_TYPE_CALC);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	MERGE /*+ALL_ROWS*/ INTO val_change_log vcl
	USING (SELECT i.app_sid, i.ind_sid, v_calc_start_dtm period_start_dtm, v_calc_end_dtm period_end_dtm
		     FROM ind i
		    WHERE i.gas_type_id IS NOT NULL) v
	   ON (v.app_sid = vcl.app_sid AND v.ind_sid = vcl.ind_sid)
	 WHEN MATCHED THEN
		UPDATE 
		   SET vcl.start_dtm = LEAST(vcl.start_dtm, v.period_start_dtm),
			   vcl.end_dtm = GREATEST(vcl.end_dtm, v.period_end_dtm)
	 WHEN NOT MATCHED THEN
		INSERT (vcl.ind_sid, vcl.start_dtm, vcl.end_dtm)
		VALUES (v.ind_sid, v.period_start_dtm, v.period_end_dtm);
END;

PROCEDURE PropagateGeoProp(
	in_region_sid					IN	security_pkg.T_SID_ID
)
AS
	v_geo_country 					region.geo_country%TYPE;
	v_geo_region					region.geo_region%TYPE;
	v_geo_city_id					region.geo_city_id%TYPE;
	v_map_entity					region.map_entity%TYPE;
	v_geo_latitude					region.geo_latitude%TYPE;
	v_geo_longitude					region.geo_longitude%TYPE;
BEGIN
	-- we should propagate down all possible properties, i.e. if we have:
	-- France 
	-- |_ Auvergne
	--    |_ Some town
	--    |_ Some other town (unmapped)
	-- then, if we alter "Auvergne" to remove it's "geo_type" then
	-- we can't alter 'some other town (unmapped)' to point to anywhere
	-- other than the Auvergne, UNLESS we clear stuff down (previously the
	-- code didn't used to do this, hence the long note :))
	SELECT geo_country, geo_region, geo_city_id, map_entity, geo_latitude, geo_longitude
	  INTO v_geo_country, v_geo_region, v_geo_city_id, v_map_entity, v_geo_latitude, v_geo_longitude
	  FROM region
	 WHERE region_sid = in_region_sid;

	UPDATE region
	   SET geo_country = v_geo_country,
		   geo_region = v_geo_region,
		   geo_city_id = v_geo_city_id,
		   map_entity = v_map_entity,
		   geo_latitude = v_geo_latitude,
		   geo_longitude = v_geo_longitude,
		   last_modified_dtm = SYSDATE
	 WHERE (app_sid, region_sid) IN (
	 		SELECT app_sid, region_sid
	 		  FROM region
	 		  	   START WITH parent_sid = in_region_sid
	 		  	   		  AND geo_type = REGION_GEO_TYPE_INHERITED
	 		  	   CONNECT BY PRIOR app_sid = app_sid 
	 		  	          AND PRIOR region_sid = parent_sid -- assuming we don't want to go down the secondary tree?
	 		  	          AND geo_type = REGION_GEO_TYPE_INHERITED);

	AddAggregateJobsForCO2Inds;
END;

PROCEDURE PropagateEgridProp(
	in_region_sid					IN 	region.region_sid%TYPE,
	in_egrid_ref					IN	region.egrid_ref%TYPE
)
AS
	v_egrid_ref						region.egrid_ref%TYPE;
BEGIN
	SELECT egrid_ref
	  INTO v_egrid_ref
	  FROM region
	 WHERE region_sid = in_region_sid;
	
	UPDATE region
	   SET egrid_ref = v_egrid_ref,
		   last_modified_dtm = SYSDATE
	 WHERE (app_sid, region_sid) IN (	 
			SELECT app_sid, region_sid
	 		  FROM region
			 START WITH parent_sid = in_region_sid
               AND egrid_ref_overridden = 0
           CONNECT BY PRIOR app_sid = app_sid 
			   AND PRIOR region_sid = parent_sid -- assuming we don't want to go down the secondary tree?
               AND egrid_ref_overridden = 0               
	);

	AddAggregateJobsForCO2Inds;
END;

PROCEDURE DisposeRegion(
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	region.disposal_dtm%TYPE DEFAULT NULL
)
AS
	v_active		region.active%TYPE;
	v_disposal_dtm	region.disposal_dtm%TYPE;
	v_region_type	region.region_type%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security','act'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT active, disposal_dtm, region_type
	  INTO v_active, v_disposal_dtm, v_region_type
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	csr_data_pkg.AuditValueChange(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getapp, 
		in_region_sid, 'Active', v_active, 0);
	csr_data_pkg.AuditValueChange(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.getapp, 
		in_region_sid, 'Disposal date', v_disposal_dtm, in_disposal_dtm);
	
	UPDATE region 
	   SET active = 0,
		   disposal_dtm = in_disposal_dtm,
		   last_modified_dtm = SYSDATE
	 WHERE region_sid = in_region_sid
	    OR link_to_region_sid IN (
			-- apply to all secondary hierarchy nodes pointing at this region
			SELECT region_sid
			  FROM region
			 WHERE active = 1
			   AND link_to_region_sid
				IN (
				   SELECT region_sid
					FROM region 
					CONNECT BY PRIOR region_sid = parent_sid
					  START WITH region_sid = in_region_sid
			)
		);
 
	IF v_active != 0 THEN
		FOR r IN (
			SELECT app_sid, active, region_sid
			  FROM region
			 START WITH parent_sid = in_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid
		)
		LOOP
			IF r.active != 0 THEN
				UPDATE region 
				   SET active = 0, last_modified_dtm = SYSDATE
				 WHERE region_sid = r.region_sid;
				-- audit
				csr_data_pkg.AuditValueChange(security_pkg.getact, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
					r.region_sid, 'Active', r.active, 0);
				END IF;
		END LOOP;
	END IF; 
	
	IF (v_region_type = csr_data_pkg.REGION_TYPE_METER OR v_region_type = csr_data_pkg.REGION_TYPE_RATE) AND (
	   (in_disposal_dtm IS NULL AND v_disposal_dtm IS NOT NULL) OR
	   (in_disposal_dtm IS NOT NULL AND v_disposal_dtm IS NULL) OR
	   (in_disposal_dtm IS NOT NULL AND v_disposal_dtm IS NOT NULL AND in_disposal_dtm <> v_disposal_dtm)) THEN
	   	  -- Update meter reading derived data on the main system from the earliest new or old disposal date
	   	  meter_pkg.RecalcValtableFromDtm(in_region_sid, 
	   	  	LEAST(NVL(in_disposal_dtm, v_disposal_dtm), NVL(v_disposal_dtm, in_disposal_dtm)));
	   	  
	ELSIF v_region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER AND (
	    (in_disposal_dtm IS NULL AND v_disposal_dtm IS NOT NULL) OR
	    (in_disposal_dtm IS NOT NULL AND v_disposal_dtm IS NULL) OR
	    (in_disposal_dtm IS NOT NULL AND v_disposal_dtm IS NOT NULL AND in_disposal_dtm <> v_disposal_dtm)) THEN
	   	  -- Update meter reading derived data on the main system
	   	  meter_pkg.INTERNAL_RecomputeValueData(in_region_sid);
	END IF;

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE UNSEC_AmendRegionActive(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_active				IN	region.active%TYPE,
	in_old_acquisition_dtm	IN	region.acquisition_dtm%TYPE,
	in_old_disposal_dtm		IN	region.disposal_dtm%TYPE,
	in_fast					IN	NUMBER
)
AS
	CURSOR c IS 
		SELECT r.app_sid, r.active, r.region_type, r.acquisition_dtm, r.disposal_dtm
		  FROM v$region r, customer c
		 WHERE r.region_sid = in_region_sid
		   AND r.app_sid = c.app_sid;
	r c%ROWTYPE;
BEGIN	
	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN 
		RETURN; 
	END IF;

	IF r.active = in_active THEN
		RETURN;
	END IF;

	UPDATE region 
	   SET active = in_active, last_modified_dtm = SYSDATE
	 WHERE region_sid = in_region_sid;

	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Active', r.active, in_active);

	FOR rr IN (
		SELECT app_sid, active, region_sid
			FROM region
			START WITH parent_sid = in_region_sid
		CONNECT BY PRIOR region_sid = parent_sid
	)
	LOOP
		IF rr.active != in_active THEN
			UPDATE region 
			   SET active = in_active, last_modified_dtm = SYSDATE
			 WHERE region_sid = rr.region_sid;
			
			csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, rr.app_sid, 
				rr.region_sid, 'Active', rr.active, in_active);
			END IF;
	END LOOP;
	
	IF in_fast = 0 THEN
		-- If the acquisition date has changed or been set/removed then update (if this is a meter region)
		IF r.region_type = csr_data_pkg.REGION_TYPE_METER OR 
		   r.region_type = csr_data_pkg.REGION_TYPE_RATE OR
		   r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER THEN
	   
			IF (in_old_acquisition_dtm IS NULL AND r.acquisition_dtm IS NOT NULL) OR
			   (in_old_acquisition_dtm IS NOT NULL AND r.acquisition_dtm IS NULL) OR
			   (in_old_acquisition_dtm IS NOT NULL AND r.acquisition_dtm IS NOT NULL AND in_old_acquisition_dtm != r.acquisition_dtm) THEN	   	   	
		   		-- Recompute all system value data for this meter
		   		meter_pkg.INTERNAL_RecomputeValueData(in_region_sid);
		
			ELSE
				-- If the acquisition date changed then the entire meter data is 
				-- recomputed, so there's no need to check the disposal date as well
			
				-- FB 2911
				-- IF the region is a meter
				-- AND (the region active state has changed from inactive to active
				-- OR if the region is inactive and the disposal date has changed)
				--
				-- We need to recompute the data if the region has been made 
				-- inactive as the disposal date may well fall inside a period where 
				-- there is data, we never want to see data in the main system that is
				-- derived from reading values after the disposal date. Note that we
				-- only adjust the metering data on the main system if a disposal 
				-- date is avaialable.
				--
				IF -- The region has been re-activated
				   ((in_active = 1 AND r.active = 0) OR 
					-- The region has been deactivated and a disposal date is avaialable
					(in_active <> r.active AND r.disposal_dtm IS NOT NULL) OR 
					-- The region is inactive and the disposal date has changed
					(in_active = 0 AND r.disposal_dtm IS NOT NULL AND in_old_disposal_dtm <> r.disposal_dtm)) THEN
			   			-- Update meter reading derived data on the main system from the earliest new or old disposal date
			   		IF r.region_type = csr_data_pkg.REGION_TYPE_REALTIME_METER THEN
			   			meter_pkg.INTERNAL_RecomputeValueData(in_region_sid);
			   		ELSE
			   		  meter_pkg.RecalcValtableFromDtm(in_region_sid, 
			   	  		LEAST(NVL(r.disposal_dtm, in_old_disposal_dtm), NVL(in_old_disposal_dtm, r.disposal_dtm)));
					END IF;
				END IF;
			END IF;
		END IF;
	
		-- region has been re-activated, make the region visible on delegation form
		IF in_active = 1 AND r.active = 0 THEN
			UPDATE delegation_region
			   SET hide_after_dtm = NULL,
				   hide_inclusive = 0
			 WHERE hide_after_dtm IS NOT NULL
			   AND region_sid IN (
					SELECT region_sid
					  FROM region
					 WHERE app_sid = r.app_sid
					 START WITH region_sid = in_region_sid
				   CONNECT BY PRIOR region_sid = parent_sid
				   )
			   AND app_sid = r.app_sid;
		END IF;
	
		-- If the region has changed activation state then reapply any dynamic delegation plans that involve it
		IF r.active != in_active THEN
			ApplyDynamicPlans(in_region_sid, 'Region activity changed');
		END IF;
	END IF;

	-- Create energy star jobs if required
	energy_star_job_pkg.OnRegionChange(in_region_sid);
END;

PROCEDURE SetRegionActive(
	in_region_sid		IN	region.region_sid%TYPE,
	in_active			IN	region.active%TYPE,
	in_fast				IN	NUMBER
)
AS
	CURSOR c IS 
		SELECT r.acquisition_dtm, r.disposal_dtm
		  FROM v$region r, customer c
		 WHERE r.region_sid = in_region_sid
		   AND r.app_sid = c.app_sid;
	r c%ROWTYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security.security_pkg.GetAct, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied amending region ' || in_region_sid);
	END IF;

	OPEN c;
	FETCH c INTO r;
	IF c%NOTFOUND THEN 
		RETURN; 
	END IF;

	UNSEC_AmendRegionActive(security.security_pkg.GetAct, in_region_sid, in_active, r.acquisition_dtm, r.disposal_dtm, in_fast);
END;

/**
 * Update a region
 *
 * @param	in_act_id				Access token
 * @param	in_region_sid			The region to update
 * @param	in_description			The new region description
 * @param	in_active				Active? (1 = active / 0 = inactive)
 */
PROCEDURE AmendRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	region_description.description%TYPE,
	in_active						IN	region.active%TYPE,
	in_pos							IN	region.pos%TYPE,
	in_geo_type						IN	region.geo_type%TYPE,
	in_info_xml						IN	region.info_xml%TYPE,
	in_geo_country					IN	region.geo_country%TYPE,
	in_geo_region					IN	region.geo_region%TYPE,
	in_geo_city						IN	region.geo_city_id%TYPE,
	in_map_entity					IN	region.map_entity%TYPE,
	in_egrid_ref					IN	region.egrid_ref%TYPE,
	in_region_ref					IN	region.region_ref%TYPE,
	in_acquisition_dtm				IN	region.acquisition_dtm%TYPE DEFAULT NULL,	
	in_disposal_dtm					IN	region.disposal_dtm%TYPE DEFAULT NULL,
	in_region_type					IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
)
AS
	CURSOR c IS 
		SELECT r.description, r.active, r.pos, r.info_xml, r.app_sid, region_info_xml_fields, r.disposal_dtm, r.acquisition_dtm,
			   r.region_ref, pc.name country_name, pr.name region_name, py.city_name city_name, r.egrid_ref,
			   r.parent_sid, r.region_type, r.geo_latitude, r.geo_longitude
		  FROM v$region r, customer c, postcode.country pc, postcode.region pr, postcode.city py
		 WHERE r.geo_country = pc.country(+)
		   AND r.geo_region = pr.region(+)
		   AND r.geo_country = pr.country(+)
		   AND r.geo_city_id = py.city_id(+)
		   AND r.region_sid = in_region_sid
		   AND r.app_sid = c.app_sid;
	r c%ROWTYPE;
	v_pos							region.pos%TYPE;
	v_longitude						region.geo_longitude%TYPE;
	v_latitude  					region.geo_latitude%TYPE;
	v_new_country_name				postcode.country.name%TYPE;
	v_new_region_name				postcode.region.name%TYPE;
	v_new_city_name					postcode.city.city_name%TYPE;
	v_parent_geo_country			region.geo_country%TYPE;
	v_parent_geo_region				region.geo_region%TYPE;
	v_parent_geo_city_id			region.geo_city_id%TYPE;
	v_parent_map_entity				region.map_entity%TYPE;
	v_parent_geo_longitude			region.geo_longitude%TYPE;
	v_parent_geo_latitude			region.geo_latitude%TYPE;
	v_parent_egrid_ref				region.egrid_ref%TYPE;	
	v_not_found						BOOLEAN;
	v_has_parent					NUMBER := 1;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	OPEN c;
	FETCH c INTO r;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN;
	END IF;
	
	-- if null pos is passed then keep what we had before
	IF in_pos IS NULL THEN
		v_pos := NVL(r.pos, 1);
	ELSE
		v_pos := NVL(in_pos, 1);
	END IF;

	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Description', r.description, in_description);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Region type', r.region_type, in_region_type);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Reference', r.region_ref, in_region_ref);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Acquisition date', r.acquisition_dtm, in_acquisition_dtm);

	-- info xml
	csr_data_pkg.AuditInfoXmlChanges(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, r.region_info_xml_fields, r.info_xml, in_info_xml);
	 
	-- change any form / data explorer or delegation indicator names	 	 
 	UPDATE form_region_member 
	   SET description = in_description 
	 WHERE region_sid = in_region_sid 
	   AND description = r.description;

	UPDATE pending_region 
	   SET description = in_description 
	 WHERE maps_to_region_sid = in_region_sid 
	   AND description = r.description;
	   
	-- XXX: I'm not sure what REGION_GEO_TYPE_OTHER intends, but the check constraint CK_GEO_TYPE
	-- specifies that all geo properties are null if this is selected.
	IF in_geo_type != region_pkg.REGION_GEO_TYPE_OTHER THEN

		-- get geo properties off the parent
		BEGIN
			SELECT geo_country, geo_region, geo_city_id, map_entity, geo_longitude, geo_latitude, egrid_ref
			  INTO v_parent_geo_country, v_parent_geo_region, v_parent_geo_city_id, v_parent_map_entity,
				   v_parent_geo_longitude, v_parent_geo_latitude, v_parent_egrid_ref
			  FROM region
			 WHERE app_sid = r.app_sid AND region_sid = r.parent_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_has_parent := 0;			
		END;
		-- fetch longitude and latitude
		IF in_geo_type = region_pkg.REGION_GEO_TYPE_LOCATION THEN
			-- set initial latitude/longitude just to prevent constraint errors
			-- we set proper coordinates using region_pkg.SetLatLong in same transaction
			IF r.geo_latitude IS NULL OR r.geo_longitude IS NULL THEN
				v_longitude := 0;
				v_latitude := 0;
			ELSE 
				v_latitude := r.geo_latitude;
				v_longitude := r.geo_longitude;
			END IF;
		ELSIF in_geo_type = region_pkg.REGION_GEO_TYPE_INHERITED AND v_has_parent = 1 THEN
			-- for auditing, we need the city/region/country names from the parent
			IF v_parent_geo_city_id IS NOT NULL THEN
				SELECT city_name, region_name, country_name
				  INTO v_new_city_name, v_new_region_name, v_new_country_name
				  FROM postcode.city_full
				 WHERE city_id = v_parent_geo_city_id;
			ELSIF v_parent_geo_region IS NOT NULL THEN
				SELECT pr.name, pc.name
				  INTO v_new_region_name, v_new_country_name
				  FROM postcode.region pr, postcode.country pc
				 WHERE pr.country = v_parent_geo_country 
				   AND pr.region = v_parent_geo_region
				   AND pr.country = pc.country;
			ELSIF v_parent_geo_country IS NOT NULL THEN
				SELECT name
				  INTO v_new_country_name
				  FROM postcode.country
				 WHERE country = v_parent_geo_country;
			END IF;
		ELSIF in_geo_city IS NOT NULL THEN 
			SELECT longitude, latitude, city_name, region_name, country_name
			  INTO v_longitude, v_latitude, v_new_city_name, v_new_region_name, v_new_country_name
			  FROM postcode.city_full
			 WHERE city_id = in_geo_city;
		ELSIF in_geo_region IS NOT NULL THEN
			SELECT COALESCE(pr.longitude, pc.longitude, 0), COALESCE(pr.latitude, pc.latitude, 0), pr.name, pc.name   
			  INTO v_longitude, v_latitude, v_new_region_name, v_new_country_name
			  FROM postcode.region pr, postcode.country pc
			 WHERE pr.country = in_geo_country 
			   AND pr.region = in_geo_region
			   AND pr.country = pc.country;
		ELSIF in_geo_country IS NOT NULL THEN
			SELECT longitude, latitude, name
			  INTO v_longitude, v_latitude, v_new_country_name
			  FROM postcode.country
			 WHERE country = in_geo_country;
		END IF;
	END IF;
	
	-- audit geo stuff
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'City', r.city_name, v_new_city_name);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'State/region', r.region_name, v_new_region_name);
	IF in_geo_type != region_pkg.REGION_GEO_TYPE_LOCATION THEN
		csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
			in_region_sid, 'Country', r.country_name, v_new_country_name);
	END IF;
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'EGrid', r.egrid_ref, in_egrid_ref);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Disposal date', r.disposal_dtm, in_disposal_dtm);
	csr_data_pkg.AuditValueChange(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, r.app_sid, 
		in_region_sid, 'Acquisition date', r.acquisition_dtm, in_acquisition_dtm);
	
	UPDATE region 
	   SET pos = v_pos, 
		   info_xml = in_info_xml,
		   region_ref = in_region_ref,
		   disposal_dtm = in_disposal_dtm,
		   acquisition_dtm = in_acquisition_dtm,
		   region_type = in_region_type,
		   last_modified_dtm = SYSDATE
	 WHERE region_sid = in_region_sid;
	 
	UPDATE region_description
	   SET description = in_description
	 WHERE lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	   AND region_sid = in_region_sid;
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing region_description row for the region with sid '||
			in_region_sid||' and langauge '||SYS_CONTEXT('SECURITY', 'LANGUAGE'));
	END IF;
	 
	-- update geo stuff.	 
	-- TODO: changes to geographic properties should kick off CO2 recalc jobs
	IF in_geo_type = region_pkg.REGION_GEO_TYPE_INHERITED AND v_has_parent = 1 THEN	
		UPDATE region
		   SET geo_type = region_pkg.REGION_GEO_TYPE_INHERITED,
		   	   geo_country = v_parent_geo_country,
		   	   geo_region = v_parent_geo_region,
		   	   geo_city_id = v_parent_geo_city_id,
		   	   map_entity = v_parent_map_entity,
		   	   geo_longitude = v_parent_geo_longitude,
		   	   geo_latitude = v_parent_geo_latitude,
		   	   egrid_ref = in_egrid_ref,
			   egrid_ref_overridden = (
					CASE WHEN null_pkg.sne(in_egrid_ref, v_parent_egrid_ref) = 1  THEN 1 ELSE 0 END
			   )
		 WHERE app_sid = r.app_sid AND region_sid = in_region_sid;
	ELSE
		UPDATE region
		   SET geo_type = in_geo_type,
			   geo_country = in_geo_country,
			   geo_region = in_geo_region,
			   geo_city_id = in_geo_city,
			   map_entity = in_map_entity,
			   geo_longitude = v_longitude,
			   geo_latitude = v_latitude,
			   egrid_ref = in_egrid_ref,
			   egrid_ref_overridden = (
					CASE WHEN null_pkg.sne(in_egrid_ref, v_parent_egrid_ref) = 1 THEN 1 ELSE 0 END
			   )
		 WHERE region_sid = in_region_sid;
	END IF;

	PropagateGeoProp(in_region_sid);
	PropagateEGridProp(in_region_sid, in_egrid_ref);
	
	UNSEC_AmendRegionActive(in_act_id, in_region_sid, in_active, r.acquisition_dtm, r.disposal_dtm, 0);

	compliance_pkg.OnRegionUpdate(in_region_sid);
	
	IF r.region_type != in_region_type THEN
		ApplyDynamicPlans(in_region_sid, 'Region type changed');
	END IF;
END;

PROCEDURE SetLatLong(
	in_region_sid		 			IN	security_pkg.T_SID_ID,
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE
)
AS
	v_parent_region_sid				security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('security','act'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	IF in_latitude IS NULL AND in_longitude IS NULL THEN
	
		-- inherit 
		UPDATE region
		   SET geo_type = REGION_GEO_TYPE_INHERITED
		 WHERE region_sid = in_region_sid;
		
		SELECT parent_sid
		  INTO v_parent_region_sid
		  FROM region
		 WHERE region_sid = in_region_sid;
		
		PropagateGeoProp(v_parent_region_sid);
	
	ELSE
	
		-- if we change latitude longitude, then we automatically change region type to LOCATION
		UPDATE region 
		   SET geo_type = REGION_GEO_TYPE_LOCATION,
			   geo_latitude = CASE WHEN in_latitude < -90 THEN -90 WHEN in_latitude > 90 THEN 90 ELSE in_latitude END,
			   geo_longitude = in_longitude - 360 * FLOOR((in_longitude+180)/360),
			   last_modified_dtm = SYSDATE
		 WHERE region_sid = in_region_sid;
		
		PropagateGeoProp(in_region_sid);
	
	END IF;
END;
	

PROCEDURE RenameRegion(
	in_region_sid		 			IN	security_pkg.T_SID_ID,
	in_description 					IN	region_description.description%TYPE
)
AS
	CURSOR c IS
		SELECT description, app_sid
		  FROM v$region
		 WHERE region_sid = in_region_sid;
	record 							c%ROWTYPE;
	v_not_found						BOOLEAN;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied renaming region');
	END IF;

	-- write a log entry describing the change...
	OPEN c;
	FETCH c INTO record;
	v_not_found := c%NOTFOUND;
	CLOSE c;
	IF v_not_found THEN
		RETURN;
	END IF;
	
	IF record.description = in_description THEN
		RETURN; -- only audit changes
	END IF;
	
	csr_data_pkg.AuditValueChange(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, record.app_sid, 
		in_region_sid, 'Description', record.description, in_description);

    -- saving places where objects have been specially renamed...
	UPDATE form_region_member 
	   SET description = in_description 
	 WHERE region_sid = in_region_sid 
	   AND description = record.description;
		   
	UPDATE pending_region 
	   SET description = in_description 
	 WHERE maps_to_region_sid = in_region_sid 
	   AND description = record.description;

	-- and finally changing the description of the region
	UPDATE region_description
	   SET description = in_description
 	 WHERE region_sid = in_region_sid
 	   AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
 	   
	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing region_description row for the region with sid '||
			in_region_sid||' and language '||SYS_CONTEXT('SECURITY', 'LANGUAGE'));
	END IF;
END;


-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
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
) AS
BEGIN
	--UPDATE REGION SET NAME = in_new_name WHERE region_sid = in_sid_id;
	NULL;
END;

-- no security, private function only used by this package
PROCEDURE FixStartPointsForDeletion(
	in_region_sid					IN security_pkg.T_SID_ID
)
AS
    v_start_points					security_pkg.T_SID_IDS;	
	v_cnt							NUMBER;
BEGIN
	-- We can't delete this region if it's an active user's start point.
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM region_start_point 
	 WHERE region_sid = in_region_sid
	   AND user_sid NOT IN (
			SELECT trash_sid
			  FROM trash
		);
	IF v_cnt > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_OBJECT_IS_MOUNT_POINT,
			'Cannot delete region '||in_region_sid||' because it is used by one or more users as a start point');
	END IF;

	-- Don't allow trashed users to keep this region as a start point.
	FOR r IN (SELECT user_sid
				FROM region_start_point
			   WHERE region_sid = in_region_sid) LOOP

		SELECT region_sid
		  BULK COLLECT INTO v_start_points
		  FROM region_start_point
		 WHERE user_sid = r.user_sid
		   AND region_sid != in_region_sid;

		IF v_start_points.COUNT = 0 THEN
			-- This is the last region start point for a trashed user,
			-- so remove this start point. We can't call csr_user_pkg.SetRegionStartPoints
			-- because passing it an empty list would try to set their start point
			-- to the logged on user's start points (probably region root if the user
			-- is deleting users) which wouldn't be safe
			DELETE FROM region_start_point
			 WHERE user_sid = r.user_sid
			   AND region_sid = in_region_sid;
		ELSE
			csr_user_pkg.SetRegionStartPoints(r.user_sid, v_start_points);
		END IF;
	END LOOP;
END;

PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
) AS	
	v_app_sid				security_pkg.T_SID_ID;	
	v_parent_sid			region.parent_sid%TYPE;
	v_trash_sid				customer.trash_sid%TYPE;
BEGIN
	FixStartPointsForDeletion(in_sid_id);
	
	-- delete any regions that link to this object
	FOR r IN (SELECT region_sid FROM region WHERE link_to_region_sid = in_sid_id)
	LOOP		
		securableobject_pkg.DeleteSO(in_act_id, r.region_sid);
	END LOOP;
	
	-- delete all internal audits for this region
	FOR r IN
	(
		SELECT internal_audit_sid
		  FROM internal_audit a
		 WHERE region_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	LOOP
		securableobject_pkg.DeleteSO(in_act_id, r.internal_audit_sid);
	END LOOP;
	
	
	SELECT app_sid, parent_sid
	  INTO v_app_sid, v_parent_sid
	  FROM region 
	 WHERE region_sid = in_sid_id;

	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
		'Deleted {0}', INTERNAL_GetRegionPathString(in_sid_id));

	FOR r IN (SELECT doc_folder_sid FROM doc_folder WHERE property_sid = in_sid_id)
	LOOP
		securableobject_pkg.DeleteSO(in_act_id, r.doc_folder_sid);
	END LOOP;

	-- we need to set our audit log object_sid to null due to FK constraint
	update audit_log set object_sid = null where object_sid = in_sid_id;
	
	-- unhook imports
	UPDATE IMP_REGION SET MAPS_TO_REGION_SID = NULL
	 WHERE MAPS_TO_REGION_SID = in_sid_id;
	 
	-- add a recalc job for our parent, as long as it's not the trash or the app
	SELECT trash_sid
	  INTO v_trash_sid
	  FROM customer
	 WHERE app_sid = v_app_sid;
	IF v_parent_sid NOT IN (v_app_sid, v_trash_sid) THEN
		AddAggregateJobs(v_app_sid, v_parent_sid);
	END IF;

	-- delete all values associated with this region
	UPDATE IMP_VAL SET SET_VAL_ID = NULL WHERE SET_VAL_ID IN
		(SELECT VAL_ID FROM VAL WHERE region_sid = in_sid_id);
	DELETE FROM val_note 
	 WHERE region_sid = in_sid_id;
	DELETE FROM val_file 
	 WHERE val_id IN (SELECT val_id
						FROM val
					   WHERE region_sid = in_sid_id);
	DELETE FROM val 
	 WHERE region_sid = in_sid_id;
	DELETE FROM val_change 
	 WHERE region_sid = in_sid_id;
	DELETE FROM target_dashboard_value 
	 WHERE region_sid = in_sid_id;
	DELETE FROM dashboard_item 
	 WHERE region_sid = in_sid_id;
	DELETE FROM tpl_report_tag_dv_region
	 WHERE region_sid = in_sid_id;

	DELETE FROM dataview_region_description
	 WHERE region_sid = in_sid_id;
	DELETE FROM dataview_region_member
	 WHERE region_sid = in_sid_id;

	DELETE FROM form_region_member
	 WHERE region_sid = in_sid_id;

	DELETE FROM target_dashboard_reg_member
	 WHERE region_sid = in_sid_id;

	DELETE FROM pct_ownership_change
	 WHERE region_sid = in_sid_id;
	DELETE FROM pct_ownership 
	 WHERE region_sid = in_sid_id;
	FOR r IN (
		SELECT sheet_value_id 
		  FROM sheet_value
		 WHERE region_sid = in_sid_id
	) 
	LOOP
		sheet_pkg.INTERNAL_DeleteSheetValue(r.sheet_value_Id);
	END LOOP;
	DELETE FROM delegation_region_description
	 WHERE region_sid = in_sid_id;
	DELETE FROM delegation_region
	 WHERE region_sid = in_sid_id;
	DELETE FROM region_tag
	 WHERE region_sid = in_sid_id;
	DELETE FROM region_owner
	 WHERE region_sid = in_sid_id;
	DELETE FROM region_start_point
	 WHERE region_sid = in_sid_id;

	UPDATE csr_user
	   SET primary_region_sid = NULL
	 WHERE primary_region_sid = in_sid_id;
	
	-- Delete this and all inherited roles
	-- XXX: roles don't currently propagate down secondary trees. Either way 
	-- we don't want to delete stuff under links, so don't resolve them! Role
	-- propagation is rather like propagate down with indicators -- it should
	-- only ever be done down one tree. With indicators we can pick the tree.
	-- Maybe we need the same with roles? Bit overly complex though I think.
	DELETE FROM region_role_member 
	 WHERE region_sid IN (
	 	SELECT region_sid
	 	  FROM region
	 	 	START WITH region_sid = in_sid_id
	 	 	CONNECT BY PRIOR region_sid = parent_sid
	 );
	
	DELETE FROM region_role_member 
	 WHERE inherited_from_sid = in_sid_id;
	  
	-- clean out actions
	DELETE FROM actions.task_recalc_region WHERE region_sid = in_sid_id;
	DELETE FROM actions.aggr_task_period_override WHERE region_sid = in_sid_id;
	DELETE FROM actions.aggr_task_period WHERE region_sid = in_sid_id;
	DELETE FROM actions.task_period_override WHERE region_sid = in_sid_id;
	DELETE FROM actions.task_period WHERE region_sid = in_sid_id;
	DELETE FROM actions.task_period_file_upload WHERE region_sid = in_sid_id;
	DELETE FROM actions.task_region WHERE region_sid = in_sid_id;
	
	DELETE FROM actions.project_region_role_member 
	 WHERE region_sid IN (
	 	SELECT NVL(link_to_region_sid, region_sid) region_sid
	 	  FROM region
	 	 	START WITH region_sid = in_sid_id
	 	 	CONNECT BY PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
	 );
	
	
	-- Clean out meter alarms
	meter_alarm_pkg.OnDeleteRegion(in_sid_id);
	
	-- Create energy star jobs if required
	-- This will mop up the ES region sid references
	energy_star_job_pkg.OnRegionRemoved(in_sid_id);
	
	-- Remove meter issues
	FOR r IN (
		SELECT issue_id
		  FROM csr.issue i
			JOIN csr.issue_meter ii ON i.issue_meter_id = ii.issue_meter_id
		 WHERE ii.region_sid = in_sid_id
		 UNION
		SELECT issue_id
		  FROM csr.issue i
			JOIN csr.issue_sheet_value ii ON i.issue_sheet_value_id = ii.issue_sheet_value_id
		 WHERE ii.region_sid = in_sid_id
	) LOOP	
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	END LOOP;
	
	UPDATE csr.issue
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
	
	UPDATE csr.issue
	   SET last_region_sid = NULL
	 WHERE last_region_sid = in_sid_id;
	
	-- Remove region reference from raw data issues
	UPDATE issue_meter_raw_data
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
	
	-- clean out meter stuff
	DELETE FROM meter_list_cache
	 WHERE region_sid = in_sid_id;
	DELETE FROM meter_reading 
	 WHERE region_sid = in_sid_id;
	DELETE FROM meter_input_aggr_ind 
	 WHERE region_sid = in_sid_id;
	DELETE FROM meter_photo
	 WHERE region_sid = in_sid_id;
	DELETE FROM meter_live_data
	 WHERE region_sid = in_sid_id;
	DELETE FROM all_meter 
	 WHERE region_sid = in_sid_id;

	-- clean out linked documents
	DELETE FROM region_proc_doc 
	 WHERE region_sid = in_sid_id;
	DELETE FROM region_proc_file 
	 WHERE region_sid = in_sid_id;

	-- clean up divisional reporting stuff 
	DELETE FROM property_division 
         WHERE division_id IN (
		SELECT division_id FROM division WHERE region_sid = in_sid_id
	  ) OR region_sid = in_sid_id;
	  
	-- Clean out energy star
	energy_star_pkg.OnDeleteRegion(in_act_id, in_sid_id);

	-- clean out property stuff
	DELETE FROM property_fund_ownership 
	 WHERE region_sid = in_sid_id;
	DELETE FROM property_fund
	 WHERE region_sid = in_sid_id;
	DELETE FROM lease_space
	 WHERE space_region_sid = in_sid_id;
	DELETE FROM property_photo
	 WHERE space_region_sid = in_sid_id;
	DELETE FROM property_photo
	 WHERE property_region_sid = in_sid_id;
	DELETE FROM all_space
	 WHERE region_sid = in_sid_id;
	DELETE FROM all_property 
	 WHERE region_sid = in_sid_id;
	DELETE FROM division 
	 WHERE region_sid = in_sid_id;

	-- clean out gresb links
	DELETE FROM property_gresb 
	 WHERE region_sid = in_sid_id;

	DELETE FROM scenario_run_val
	 WHERE region_sid = in_sid_id;	 
	DELETE FROM scenario_region
	 WHERE region_sid = in_sid_id;

	DELETE FROM tab_portlet_user_region
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM current_supplier_score
	 WHERE company_sid IN (
	 	SELECT company_sid
	 	  FROM supplier
	 	 WHERE region_sid = in_sid_id
	 );
	
	DELETE FROM supplier_score_log
	 WHERE supplier_sid IN (
	 	SELECT company_sid
	 	  FROM supplier
	 	 WHERE region_sid = in_sid_id
	 );
	
	DELETE FROM supplier
	 WHERE region_sid = in_sid_id;

	DELETE FROM region_description
	 WHERE region_sid = in_sid_id;

	-- Need to update imp_val before deleting from region_metric_val
	UPDATE imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE set_region_metric_val_id IN (
	 	SELECT region_metric_val_id
	 	  FROM region_metric_val
	 	 WHERE region_sid = in_sid_id);

	DELETE FROM region_metric_val
	 WHERE region_sid = in_sid_id;

	DELETE FROM region_set_region
	 WHERE region_sid = in_sid_id;

	DELETE FROM deleg_plan_deleg_region_deleg
	 WHERE applied_to_region_sid = in_sid_id;
	
	DELETE FROM deleg_plan_deleg_region_deleg
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM deleg_plan_deleg_region
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM region_survey_response
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM deleg_plan_region
	 WHERE region_sid = in_sid_id;
	 
	 FOR r IN (
		SELECT issue_id
		FROM issue
		WHERE region_sid = in_sid_id
	 ) LOOP
		csr.issue_pkg.UNSEC_DeleteIssue(r.issue_id);
	 END LOOP;

	DELETE FROM imp_conflict_val
	 WHERE imp_conflict_id IN (
	 	SELECT imp_conflict_id
	 	  FROM imp_conflict
	 	 WHERE region_sid = in_sid_id
	 );
 
	DELETE FROM imp_conflict
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM dataview_zone
	 WHERE start_val_region_sid = in_sid_id
		OR end_val_region_sid = in_sid_id;

	DELETE FROM val_note
	 WHERE region_sid = in_sid_id;

	DELETE FROM snapshot_region
	 WHERE region_sid = in_sid_id;
	 
	UPDATE section_fact
	   SET map_to_region_sid = NULL
	 WHERE map_to_region_sid = in_sid_id;
	 
	UPDATE section_module
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM scenario_rule_region
	 WHERE region_sid = in_sid_id;

	DELETE FROM SCENARIO_RUN_SNAPSHOT_REGION 
	 WHERE region_sid = in_sid_id;

	UPDATE pending_region 
	   SET maps_to_region_sid = NULL
	 WHERE maps_to_region_sid = in_sid_id;
	 	 
	DELETE FROM factor_history
	 WHERE factor_id IN (
	 	SELECT factor_id
	 	  FROM factor
	 	 WHERE region_sid = in_sid_id
	 );
 
	DELETE FROM factor
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM custom_factor
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM tpl_report_schedule_region
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM tpl_report_sched_saved_doc
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM auto_imp_region_map
	 WHERE region_sid = in_sid_id;
	
	FOR R IN (
		SELECT issue_id
		  FROM issue i
		  JOIN issue_compliance_region icr ON i.issue_compliance_region_id = icr.issue_compliance_region_id
		  JOIN compliance_item_region cir ON icr.app_sid = cir.app_sid AND icr.flow_item_id = cir.flow_item_id
		 WHERE cir.region_sid = in_sid_id
	) LOOP
		issue_pkg.UNSEC_DeleteIssue(r.issue_id);	
	END LOOP;
	
	DELETE FROM issue_compliance_region
	 WHERE (app_sid, flow_item_id) IN
		(SELECT app_sid, flow_item_id
		   FROM compliance_item_region
	      WHERE region_sid = in_sid_id);
	
	FOR R IN (
		SELECT ist.issue_scheduled_task_id
		  FROM issue_scheduled_task ist
		  JOIN comp_item_region_sched_issue c ON ist.app_sid = c.app_sid AND ist.issue_scheduled_task_id = c.issue_scheduled_task_id
		  JOIN compliance_item_region cir ON c.app_sid = cir.app_sid AND c.flow_item_id = cir.flow_item_id
		 WHERE cir.region_sid = in_sid_id
	) LOOP
		--UNSEC
		issue_pkg.DeleteScheduledTask(r.issue_scheduled_task_id);
	END LOOP;
	
	DELETE FROM comp_permit_sched_issue
	 WHERE (app_sid, flow_item_id) IN
		(SELECT app_sid, flow_item_id
		   FROM compliance_item_region
	      WHERE region_sid = in_sid_id);
		
	DELETE FROM compliance_item_region
	 WHERE region_sid = in_sid_id;

	DELETE FROM compliance_root_regions
	 WHERE region_sid = in_sid_id;        
	
	DELETE FROM compliance_rollout_regions
	 WHERE region_sid = in_sid_id;

	DELETE FROM compliance_region_tag
	 WHERE region_sid = in_sid_id;
	
	FOR r IN (SELECT compliance_permit_id FROM compliance_permit WHERE region_sid = in_sid_id) LOOP	
		permit_pkg.UNSEC_DeletePermit(r.compliance_permit_id);	
	END LOOP;

	DELETE FROM aggr_region
	 WHERE region_sid = in_sid_id;
	 
	DELETE FROM flow_item_region
	 WHERE region_sid = in_sid_id;
	 
	-- Null out the quick_survey_answer region field rather than delete the trail of quick_survey_answer and qs_answer_log.
	UPDATE quick_survey_answer
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;

	DELETE FROM secondary_region_tree_log
	 WHERE region_sid = in_sid_id;
	
	DELETE FROM secondary_region_tree_ctrl
	 WHERE region_sid = in_sid_id;	
	
	UPDATE issue_scheduled_task 
	   SET copied_from_id = NULL 
	 WHERE copied_from_id IN (SELECT issue_scheduled_task_id FROM issue_scheduled_task WHERE region_sid = in_sid_id);
	
	DELETE FROM issue_scheduled_task
	 WHERE region_sid = in_sid_id;

	DELETE FROM model_instance_region 
	 WHERE region_sid = in_sid_id;

	DELETE FROM img_chart_region 
	 WHERE region_sid = in_sid_id;

	DELETE FROM dataview_trend 
	 WHERE region_sid = in_sid_id;

	DELETE FROM region_event 
	 WHERE region_sid = in_sid_id;


	DELETE FROM activity 
	 WHERE region_sid = in_sid_id;

	DELETE FROM AGGREGATE_IND_VAL_DETAIL 
	 WHERE region_sid = in_sid_id;

	DELETE FROM APPROVAL_DASHBOARD_REGION 
	 WHERE region_sid = in_sid_id;

	DELETE FROM APPROVAL_NOTE_PORTLET_NOTE 
	 WHERE region_sid = in_sid_id;

	DELETE FROM AUTO_IMP_CORE_DATA_VAL_FAIL 
	 WHERE region_sid = in_sid_id;

	DELETE FROM calendar_event 
	 WHERE region_sid = in_sid_id;

	DELETE FROM course 
	 WHERE region_sid = in_sid_id;

	DELETE FROM course_type_region 
	 WHERE region_sid = in_sid_id;

	DELETE FROM DEGREEDAY_REGION 
	 WHERE region_sid = in_sid_id;

	DELETE FROM DELEG_REPORT_REGION 
	 WHERE root_region_sid = in_sid_id;

	DELETE FROM DUFF_METER_REGION 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EST_BUILDING 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EST_JOB 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EST_METER 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EST_REGION_CHANGE_LOG 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EST_SPACE 
	 WHERE region_sid = in_sid_id;

	DELETE FROM EVENT 
	 WHERE raised_for_region_sid = in_sid_id;

	DELETE FROM FORECASTING_RULE 
	 WHERE region_sid = in_sid_id;

	UPDATE FUND
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;

	DELETE FROM GEO_MAP_REGION 
	 WHERE region_sid = in_sid_id;

	DELETE FROM INBOUND_CMS_ACCOUNT 
	 WHERE default_region_sid = in_sid_id;

	DELETE FROM INITIATIVE_PERIOD 
	 WHERE region_sid = in_sid_id;

	DELETE FROM INITIATIVE_REGION 
	 WHERE region_sid = in_sid_id;

	DELETE FROM ISSUE_METER_MISSING_DATA 
	 WHERE region_sid = in_sid_id;

	UPDATE ISSUE_TYPE
	   SET default_region_sid = NULL
	 WHERE default_region_sid = in_sid_id;

	DELETE FROM LIKE_FOR_LIKE_EXCLUDED_REGIONS 
	 WHERE region_sid = in_sid_id;

	DELETE FROM LIKE_FOR_LIKE_SLOT 
	 WHERE region_sid = in_sid_id;

	UPDATE METER_ORPHAN_DATA
	   SET region_sid = NULL
	 WHERE region_sid = in_sid_id;

	DELETE FROM METER_UTILITY_CONTRACT 
	 WHERE region_sid = in_sid_id;

	DELETE FROM MGT_COMPANY_TREE_SYNC_JOB 
	 WHERE tree_root_sid = in_sid_id;

	UPDATE MODEL_INSTANCE_MAP
	   SET map_to_region_sid = NULL
	 WHERE map_to_region_sid = in_sid_id;

	DELETE FROM REGION_CERTIFICATE 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_ENERGY_RATING 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_INTERNAL_AUDIT 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_METER_ALARM 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_POSTIT 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_SCORE_LOG 
	 WHERE region_sid = in_sid_id;

	DELETE FROM REGION_SCORE 
	 WHERE region_sid = in_sid_id;

	DELETE FROM RULESET_RUN 
	 WHERE region_sid = in_sid_id;

/*
All the csr FK refs to region. The ones currently dealt with in DeleteObject (2015-2564) are marked *.

	*activity
	*AGGR_REGION
	*AGGREGATE_IND_VAL_DETAIL
	*ALL_METER
	*ALL_PROPERTY
	*APPROVAL_DASHBOARD_REGION
	*APPROVAL_NOTE_PORTLET_NOTE
	*AUTO_IMP_CORE_DATA_VAL_FAIL
	*AUTO_IMP_REGION_MAP
	*CALENDAR_EVENT
	*compliance_permit
	*compliance_region_tag
	*COURSE
	*COURSE_TYPE_REGION
	*CSR_USER
	*CUSTOM_FACTOR
	*DASHBOARD_ITEM
	*DATAVIEW_REGION_MEMBER
	*DATAVIEW_TREND
	*DATAVIEW_ZONE
	*DEGREEDAY_REGION
	*DELEG_PLAN_DELEG_REGION
	*DELEG_PLAN_DELEG_REGION_DELEG
	*DELEG_PLAN_REGION
DELEG_PLAN_SURVEY_REGION (Now XX_DELEG_PLAN_SURVEY_REGION)
	*DELEG_REPORT_REGION
	*DELEGATION_REGION
	*DIVISION
	*DUFF_METER_REGION
	*EST_BUILDING
	*EST_JOB
	*EST_METER
	*EST_REGION_CHANGE_LOG
	*EST_SPACE
	*EVENT
	*FACTOR
	*FORECASTING_RULE
	*FORM_REGION_MEMBER
	*FUND
	*GEO_MAP_REGION
	*IMG_CHART_REGION
	*IMP_CONFLICT
	*IMP_REGION
	*INBOUND_CMS_ACCOUNT
	*INITIATIVE_PERIOD
	*INITIATIVE_REGION
	*INTERNAL_AUDIT
	*ISSUE
	*ISSUE_METER_MISSING_DATA
	?ISSUE_SHEET_VALUE (Indirect?)
	*ISSUE_TYPE
	*LIKE_FOR_LIKE_EXCLUDED_REGIONS
	*LIKE_FOR_LIKE_SLOT
	*CORE_WORKING_HOURS_REGION
	*METER_ORPHAN_DATA
	*METER_UTILITY_CONTRACT
	*MGT_COMPANY_TREE_SYNC_JOB
	*MODEL_INSTANCE_MAP
	*MODEL_INSTANCE_REGION
	*PCT_OWNERSHIP
	*PCT_OWNERSHIP_CHANGE
	*PENDING_REGION
	*PROPERTY_FUND
	*PROPERTY_FUND_OWNERSHIP
	*property_gresb
	*QUICK_SURVEY_ANSWER
	*REGION_CERTIFICATE
	*REGION_DESCRIPTION
	*REGION_ENERGY_RATING
	*REGION_EVENT
	*REGION_INTERNAL_AUDIT
	*REGION_METER_ALARM
	*REGION_METRIC_VAL
	*REGION_OWNER
	*REGION_POSTIT
	*REGION_PROC_DOC
	*REGION_PROC_FILE
	*REGION_ROLE_MEMBER
	*REGION_SCORE
	*REGION_SCORE_LOG
	*REGION_SET_REGION
	*REGION_START_POINT
	*REGION_SURVEY_RESPONSE
	*REGION_TAG
	*RULESET_RUN
	*SCENARIO_REGION
	*SCENARIO_RULE_REGION
	*SCENARIO_RUN_SNAPSHOT_REGION
	*SCENARIO_RUN_VAL
	*SECONDARY_REGION_TREE_CTRL
	*SECONDARY_REGION_TREE_LOG
	*SECTION_FACT
	*SECTION_MODULE
	*SHEET_VALUE
	*SHEET_VALUE_CHANGE (Indirectly via SHEET_VALUE)
	*SNAPSHOT_REGION
	*SUPPLIER
	*TAB_PORTLET_USER_REGION
	*TARGET_DASHBOARD_REG_MEMBER
	*TARGET_DASHBOARD_VALUE
	*TPL_REPORT_SCHED_SAVED_DOC
	*TPL_REPORT_SCHEDULE_REGION
	*VAL
	*VAL_CHANGE
	*VAL_NOTE
	*COMPLIANCE_ROLLOUT_REGIONS
DATA_BUCKET_VAL
*/


	-- Cross Schema constraints
	UPDATE chain.saved_filter_alert_subscriptn
	   SET region_sid = null
	 WHERE region_sid = in_sid_id;

	DELETE FROM chain.saved_filter_region
	 WHERE region_sid = in_sid_id;

	UPDATE chain.company_type
	   SET region_root_sid = null
	 WHERE region_root_sid = in_sid_id;


	DELETE FROM region 
	 WHERE region_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN security_pkg.T_SID_ID
)AS   
	v_app_sid						security_pkg.T_SID_ID;	
	v_old_parent_sid				security_pkg.T_SID_ID;
	v_geo_type						security_pkg.T_SID_ID;
	v_region_type					region.region_type%TYPE;
	v_new_owner_sid					property.company_sid%TYPE;
	v_old_owner_sid					property.company_sid%TYPE;	
	v_new_parent_country			region.geo_country%TYPE;
	v_new_parent_region				region.geo_region%TYPE;
	v_new_parent_city				region.geo_city_id%TYPE;
	v_verify_geo					NUMBER;
	v_trash_sid						security_pkg.T_SID_ID;
BEGIN		 
	CheckParent(in_new_parent_sid_id);

	SELECT trash_sid
	  INTO v_trash_sid
	  FROM customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT app_sid, parent_sid, geo_type, region_type
	  INTO v_app_sid, v_old_parent_sid, v_geo_type, v_region_type
	  FROM region 
	 WHERE region_sid = in_sid_id;

	-- recalc relevant things for old and new positions
	-- add a recalc job for our parent
	IF v_old_parent_sid != v_trash_sid THEN
		AddAggregateJobs(v_app_sid, v_old_parent_sid);
	END IF;
	
	UPDATE region 
	   SET parent_sid = in_new_parent_sid_id,
		   last_modified_dtm = SYSDATE
	 WHERE region_sid = in_sid_id;	
	
	BEGIN
		-- Verify geo properties:
		-- **********************
		-- 1) Fetch parent's geo properties
		SELECT geo_country, geo_region, geo_city_id 
		  INTO v_new_parent_country, v_new_parent_region, v_new_parent_city
		  FROM region
		 WHERE region_sid = in_new_parent_sid_id;
	
		-- 2) Go down the region tree and check if there an explict geo region. If such exist, check if it can be moved under
		--	  the new parent. (Basically the logic is simple, Maryland (US) cannot move under UK...) 
		SELECT SUM(cant_move) 
		  INTO v_verify_geo
		  FROM (SELECT region_sid, 
					   CASE 
						WHEN (geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)) AND (
							 (v_new_parent_country IS NOT NULL AND geo_country <> v_new_parent_country) OR
							 (v_new_parent_region IS NOT NULL AND geo_region <> v_new_parent_region) OR
							 (v_new_parent_city IS NOT NULL AND geo_city_id <> v_new_parent_city)) 
						THEN 1 ELSE 0 END cant_move
				  FROM region
					   START WITH region_sid = in_sid_id
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid);
		
		IF v_verify_geo > 0 THEN
			-- 3) If verification failed, throw an exception!
			RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CANT_MOVE_REGION_GEO, 'Cannot move region to new parent, geo properties mismatch');
		ELSE
			-- 4) If verification succeeded and we are inheriting geo properties, propagate from the new parent
			-- (this could be slightly more efficient as we do all siblings again -- but it's not very expensive anyway)
			IF v_geo_type = REGION_GEO_TYPE_INHERITED THEN
				PropagateGeoProp(in_new_parent_sid_id);
			ELSIF v_geo_type = REGION_GEO_TYPE_LOCATION THEN
			 -- 5) If a location geo type has been moved, update the country/region to match parent
				UPDATE region
				   SET geo_country = v_new_parent_country,
				       geo_region = v_new_parent_region,
					   geo_city_id = v_new_parent_city
				 WHERE region_sid = in_sid_id;
			END IF;
		END IF;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- We're probably trashing the object
	END;
		
	IF in_new_parent_sid_id != v_trash_sid THEN
		-- only log if not going to trash, there's a separate log entry for that handled by trash_body
		csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_sid_id,
			'Moved under "{0}"', 
			INTERNAL_GetRegionPathString(in_new_parent_sid_id));
	END IF;

	-- add a recalc job for the new parent (unless this is the trash...)
	IF in_new_parent_sid_id != v_trash_sid THEN
		AddAggregateJobs(v_app_sid, in_new_parent_sid_id);
	END IF;
	
	-- Remove anything _this_node_ previously inherited
	DELETE FROM region_proc_doc
	 WHERE region_sid IN (
	 	SELECT region_sid 
	 	  FROM region
	 	 	   START WITH region_sid = in_sid_id
	 	 	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
	  )
	   AND doc_id IN (
		SELECT doc_id
		  FROM region_proc_doc
		 WHERE region_sid = in_sid_id
		   AND inherited = 1
	  );

	DELETE FROM region_proc_file
	 WHERE region_sid IN (
	 	SELECT region_sid 
	 	  FROM region
	 	 	   START WITH region_sid = in_sid_id
	 	 	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
	 )
	 AND meter_document_id IN (
		SELECT meter_document_id
		  FROM region_proc_file
		 WHERE region_sid = in_sid_id
		   AND inherited = 1
	);
	
	-- Inherit procedure documents
	INSERT INTO region_proc_doc (region_sid, doc_id, inherited)
	  SELECT in_sid_id, doc_id, 1
	    FROM region_proc_doc
	   WHERE region_sid = in_new_parent_sid_id;
	 
	INSERT INTO region_proc_file (region_sid, meter_document_id, inherited)
	  SELECT in_sid_id, meter_document_id, 1
	    FROM region_proc_file
	   WHERE region_sid = in_new_parent_sid_id;
	   
	-- remove _inherited_ roles from this node and all it's children
	INTERNAL_RemoveInheritedRoles(in_sid_id);
	 
	-- Inherit roles from our new parent
	INTERNAL_InhertRolesFromParent(in_sid_id);
	
	-- Tell the meter package the region has moved, 
	-- the procedure doesn't act on non-meter type regions
	meter_pkg.OnRegionMoved(in_sid_id);
	meter_alarm_pkg.OnMoveRegion(in_sid_id);
	
	-- chain (FB35692): if moved region is a property then try to update its owner
	IF v_region_type = 3 THEN
		-- do we have an existing property record
		SELECT MIN(company_sid)
		  INTO v_old_owner_sid 
		  FROM property 
		 WHERE region_sid = in_sid_id;   
    
		IF v_old_owner_sid IS NOT NULL THEN
			-- whizz up the hierarchy and find the first supplier_sid
			SELECT MIN(company_sid)
			  INTO v_new_owner_sid
			  FROM (
				SELECT FIRST_VALUE(company_sid) OVER (ORDER BY lvl) company_sid
				  FROM (
					SELECT region_sid, level lvl
					  FROM region
					 START WITH region_sid = in_new_parent_sid_id
					CONNECT BY PRIOR parent_sid = region_sid
				 )x JOIN supplier s ON x.region_sid = s.region_sid 
			 );
     
			-- region is tied to a supplier = new owner
			IF v_new_owner_sid IS NOT NULL THEN
				UPDATE property 
				   SET company_sid = v_new_owner_sid 
				 WHERE region_sid = in_sid_id;
			END IF;
     
		END IF;
	END IF;	

	-- Tell the energy star job package the region was moved
	energy_star_job_pkg.OnRegionMove(in_sid_id);

	compliance_pkg.OnRegionMove(in_sid_id);
	
	deleg_plan_pkg.OnRegionMove(in_sid_id, in_old_parent_sid_id);
	
	IF v_old_parent_sid != v_trash_sid THEN
		ApplyDynamicPlans(in_old_parent_sid_id, 'Child region ('||in_sid_id||') moved out.');
	END IF;	
	ApplyDynamicPlans(in_sid_id, 'Region moved.');
END;

/**
 * Move an existing region
 *
 * @param	in_act_id				Access token
 * @param	in_move_region_sid		REgion to move
 * @param   in_parent_sid 			New parent object
 *
 */
PROCEDURE MoveRegion(
	in_act_id 						IN 	security_pkg.T_ACT_ID,
	in_region_sid 					IN 	security_pkg.T_SID_ID,
	in_parent_sid 					IN 	security_pkg.T_SID_ID
)
AS
	v_name						security_pkg.T_SO_NAME;
	v_region_in_primary_tree	NUMBER(10);
	v_parent_in_primary_tree    NUMBER(10);
BEGIN
	v_region_in_primary_tree := region_tree_pkg.IsInPrimaryTree(in_region_sid);

	v_parent_in_primary_tree := region_tree_pkg.IsInPrimaryTree(in_parent_sid);

	IF v_region_in_primary_tree = 1 AND v_parent_in_primary_tree = 0 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_CANT_MOVE_REGION_PRI2SEC, 'You cannot move a region from the primary tree to a secondary tree');			
	END IF;
	
	INTERNAL_CheckParentChildTypes(in_region_sid, in_parent_sid);
	
    -- original name
    SELECT name 
      INTO v_name 
      FROM region
     WHERE region_sid = in_region_sid;
	
	securableobject_pkg.RenameSO(in_act_id, in_region_sid, null); -- rename to null so we don't get dupe object name errors
	securableobject_pkg.MoveSO(in_act_id, in_Region_sid, in_parent_sid);	
	utils_pkg.UniqueSORename(in_act_id, in_region_sid, v_name); -- rename back uniquely
	
	-- orphan values are picked up by RAG2 -- might want to port this to RAG1 as well
END;

FUNCTION HasLinksToSubtree(
	in_region_sid					IN security_pkg.T_SID_ID
)
RETURN NUMBER
AS
	v_cnt							NUMBER;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region with sid '||in_region_sid);
	END IF;

	WITH st AS (
		SELECT region_sid
		  FROM region
		  	   START WITH region_sid = in_region_sid
		  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
	)
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM region
	 WHERE link_to_region_sid IN (SELECT region_sid FROM st)
	   AND region_sid NOT IN (SELECT region_sid FROM st);

	RETURN CASE WHEN v_cnt > 0 THEN 1 ELSE 0 END;
END;

PROCEDURE TrashObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_region_sid					IN security_pkg.T_SID_ID
)
AS
	v_description					region_description.description%TYPE;
	v_app_sid						security_pkg.T_SID_ID;
	v_doclib_folder					security_pkg.T_SID_ID;
	v_doc_trash_count				NUMBER;
BEGIN
	IF region_pkg.GetRegionIsSystemManaged(in_region_sid => in_region_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SYSTEM_MANAGED_REGION_UPDATE, 'Cannot update system managed regions');
	END IF;

	FixStartPointsForDeletion(in_region_sid);

	-- get name and sid
	SELECT description, app_sid
	  INTO v_description, v_app_sid
	  FROM v$region 
	 WHERE region_sid = in_region_sid;
		
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_region_sid,
		'Moved "{0}" to trash', INTERNAL_GetRegionPathString(in_region_sid));
	
	-- delete any links that point to this object or its children
	FOR r IN (
		SELECT region_sid
		  FROM region
		 WHERE link_to_region_sid
		 	IN (
			   SELECT region_sid
			 	FROM region 
			 	CONNECT BY PRIOR region_sid = parent_sid
				  START WITH region_sid = in_region_sid
				))
	LOOP
		-- If this sid is already trashed, no need to attempt to trash again.
		IF trash_pkg.IsInTrash(in_act_id, r.region_sid) = 0 THEN
			TrashObject(in_act_id, r.region_sid);
		END IF;
	END LOOP;			
	 
	-- Remove property doclib folder
	v_doclib_folder := property_pkg.GetDocLibFolder(in_property_sid => in_region_sid);
	IF v_doclib_folder IS NOT NULL THEN
		UPDATE doc_folder SET is_system_managed = 0 WHERE doc_folder_sid = v_doclib_folder;
		doc_folder_pkg.DeleteFolder(
			in_folder_sid			=> v_doclib_folder, 
			in_deleted_text			=> 'Parent property moved to trash',
			out_trash_count			=> v_doc_trash_count
		);
	END IF;

	-- Tell meter alarms
	meter_alarm_pkg.OntrashRegion(in_region_sid);
	
	-- Create energy star jobs if required
	-- This will mop up the ES region sid references
	energy_star_job_pkg.OnRegionRemoved(in_region_sid);
	 
	-- deactivate this and all children
	UPDATE region SET active = 0, last_modified_dtm = SYSDATE
	 WHERE region_sid IN
	 	(SELECT region_sid
	 		 FROM region 
	 	CONNECT BY PRIOR region_sid = parent_sid
		  START WITH region_sid = in_region_sid);
	 
	trash_pkg.TrashObject(in_act_id, in_region_sid, 
		securableobject_pkg.GetSIDFromPath(in_act_id, v_app_sid, 'Trash'),
		v_description);
		
	-- Untick In delegation planner 
	UPDATE deleg_plan_deleg_region
	   SET pending_deletion = csr_data_pkg.DELEG_PLAN_DELETE_ALL 
	 WHERE region_sid = in_region_sid;

	-- Reapply any dynamic delegation plans that involve this region
	ApplyDynamicPlans(in_region_sid, 'Region trashed');

	-- Delete from delegation planner
	DELETE FROM deleg_plan_region
	 WHERE region_sid = in_region_sid;
	 
	-- remove from reports
	DELETE FROM dataview_region_description
	 WHERE region_sid = in_region_sid;
	 
	DELETE FROM tpl_report_tag_dv_region
	 WHERE region_sid = in_region_sid;
	 
	DELETE FROM dataview_region_member
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
)
AS
	v_exists						NUMBER;
	v_doc_folder_sid				security_pkg.T_SID_ID;
BEGIN
	WITH rr AS ( -- regions being restored
		SELECT region_sid, link_to_region_sid
		  FROM region
			   START WITH region_sid IN (SELECT column_value FROM TABLE(in_object_sids))
			   CONNECT BY PRIOR region_sid = parent_sid),
	tr AS ( -- regions in the trash
		SELECT region_sid
		  FROM region
		       START WITH parent_sid = (SELECT trash_sid FROM customer)
			   CONNECT BY PRIOR region_sid = parent_sid)
		-- find regions being restored that link to regions in the trash
		-- that aren't themselves being restored
		SELECT COUNT(*)
		  INTO v_exists
		  FROM rr, tr
		 WHERE rr.link_to_region_sid = tr.region_sid
		   AND rr.link_to_region_sid NOT IN (SELECT region_sid FROM rr);

	IF v_exists > 0 THEN
		RAISE_APPLICATION_ERROR(Csr_Data_Pkg.ERR_REGION_LINKS_TO_TRASH,
			'Cannot restore one or more regions because they link to regions in the trash');
	END IF;
	
	-- mark the restored regions active again
	UPDATE region
	   SET active = 1
	 WHERE region_sid IN (
	 		SELECT region_sid
	 		  FROM region
				   START WITH region_sid IN (SELECT column_value FROM TABLE(in_object_sids))
				   CONNECT BY PRIOR region_sid = parent_sid);

	-- If the region is a property, and the property doc library is enabled, re-create the document
	-- folder. (We don't attempt to restore the documents which were trashed.)
	IF property_pkg.GetPropertyDocLib() IS NOT NULL THEN
		FOR r IN (SELECT region_sid
					FROM region
				   WHERE region_type = csr_data_pkg.REGION_TYPE_PROPERTY
				   START WITH region_sid IN (SELECT column_value FROM TABLE(in_object_sids))
				 CONNECT BY PRIOR region_sid = parent_sid)
		LOOP
			property_pkg.CreatePropertyDocLibFolder(
				in_property_sid			=> r.region_sid,
				out_folder_sid			=> v_doc_folder_sid
			);
		END LOOP;
	END IF;
END;

PROCEDURE GetRegion(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region with sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
		SELECT r.region_sid, r.name, r.description, r.parent_sid, r.pos, extract(r.info_xml,'/').getClobVal() info_xml,
		       r.active, r.link_to_region_sid, r.region_type, 
		       -- parent_region_type -> useful for metering where the parent type is important for rates - we're not
		       -- checking permission on the parent but we're not exactly leaking valuable information
		       pr.region_type parent_region_type, 
		       region_pkg.INTERNAL_GetRegionPathString(rl.region_sid) link_to_region_path, r.geo_latitude, r.geo_longitude, 
		       r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref,
		       nvl(rl.active, 1) linked_active, lrt.class_name linked_region_classname,
			   CASE WHEN sr.region_sid IS NULL THEN 1 ELSE 0 END is_primary,
			   region_pkg.GetRegionIsSystemManaged(in_region_sid => in_region_sid) is_system_managed
		  FROM v$region r
		  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid
		  LEFT JOIN region pr ON r.parent_sid = pr.region_sid AND r.app_sid = pr.app_sid
		  LEFT JOIN region_type lrt ON rl.region_type = lrt.region_type
		  LEFT JOIN (
				  SELECT srr.region_sid, srrt.is_system_managed
					FROM region srr
					LEFT JOIN region_tree srrt ON srrt.region_tree_root_sid = srr.region_sid
				   START WITH srrt.is_primary = 0
				 CONNECT BY PRIOR srr.region_sid = srr.parent_sid
		  ) sr ON sr.region_sid = r.region_sid
		 WHERE r.region_sid = in_region_sid;
END;

FUNCTION GetRegionIsSystemManaged(
	in_region_sid IN security_pkg.T_SID_ID
) RETURN BINARY_INTEGER
AS
	v_is_system_managed			BINARY_INTEGER;
BEGIN
	WITH regionCte(R_SID) AS (
		SELECT region_sid AS R_SID
		  FROM region r
		 START WITH r.region_sid = in_region_sid
		CONNECT BY r.region_sid = PRIOR r.parent_sid
		   AND r.app_sid = PRIOR r.app_sid
	)
	SELECT COUNT(*)
	  INTO v_is_system_managed
	  FROM regionCte r
	  LEFT JOIN region_tree rt ON rt.region_tree_root_sid = r.R_SID
	 WHERE rt.is_system_managed = 1;

	RETURN CASE WHEN (v_is_system_managed > 0) THEN 1 ELSE 0 END;
END;

PROCEDURE GetRegions(
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
)
AS
	v_region_sids					security.T_ORDERED_SID_TABLE;
	v_ordered_region_sids			security.T_ORDERED_SID_TABLE;
	v_allowed_region_sids			security.T_SO_TABLE;
	v_first_sid						region.region_sid%TYPE;
BEGIN
	-- Check the permissions / existence of region sids as directed
	v_ordered_region_sids := security_pkg.SidArrayToOrderedTable(in_region_sids);
	v_allowed_region_sids := securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security_pkg.SidArrayToTable(in_region_sids), 
		security_pkg.PERMISSION_READ
	);

	-- skipping missing and denied can be done in one step
	-- paths: skip missing=M, skip denied=D MD; cases 00, 01, 10, 11
	IF in_skip_missing = 1 AND in_skip_denied = 1 THEN -- 11
		SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
		  BULK COLLECT INTO v_region_sids
		  FROM region r,
		  	   TABLE(v_ordered_region_sids) rp,
		  	   TABLE(v_allowed_region_sids) ar
		 WHERE r.region_sid = rp.sid_id
		   AND ar.sid_id = r.region_sid
		   AND ar.sid_id = rp.sid_id;
		   
	-- otherwise check separately, according to preferences
	ELSE
		IF in_skip_missing = 1 THEN -- 10 (M=1 and D!=1 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_region_sids
			  FROM region r,
			  	   TABLE(v_ordered_region_sids) rp
			 WHERE r.region_sid = rp.sid_id;

			v_ordered_region_sids := v_region_sids;
		ELSE -- 00 or 01
			-- report missing, if any
			SELECT MIN(rr.sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_region_sids) rr
			  LEFT JOIN region r
			    ON r.region_sid = rr.sid_id
			 WHERE r.region_sid IS NULL;

			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND,
					'The region with sid '||v_first_sid||' does not exist');			
			END IF;
		END IF;
		
		IF in_skip_denied = 1 THEN -- 01 (D=1 and M!=0 by first if statement)
			SELECT security.T_ORDERED_SID_ROW(rp.sid_id, rp.pos)
			  BULK COLLECT INTO v_region_sids
			  FROM TABLE(v_allowed_region_sids) ar
			  JOIN TABLE(v_ordered_region_sids) rp
			    ON ar.sid_id = rp.sid_id;
		ELSE -- 00 or 10
			SELECT MIN(sid_id)
			  INTO v_first_sid
			  FROM TABLE(v_ordered_region_sids) rp
			 WHERE sid_id NOT IN (
			 		SELECT sid_id
			 		  FROM TABLE(v_allowed_region_sids));
			  
			IF v_first_sid IS NOT NULL THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
					'Read permission denied on the region with sid '||v_first_sid);
			END IF;
			
			-- 00 => no region sids set, use input
			IF in_skip_missing = 0 THEN
				v_region_sids := v_ordered_region_sids;
			END IF;
		END IF;
	END IF;

	OPEN out_region_cur FOR
		SELECT r.region_sid, r.name, r.description, r.parent_sid, r.pos, extract(r.info_xml,'/').getClobVal() info_xml,
		       r.active, r.link_to_region_sid, r.region_type, 
		       pr.region_type parent_region_type, -- useful for metering where the parent type is important for rates - we're not checking permission on the parent but we're not exactly leaking valuable information
        	   region_pkg.INTERNAL_GetRegionPathString(r.region_sid) path,
        	   region_pkg.INTERNAL_GetRegionPathString(rl.region_sid) link_to_region_path, r.geo_latitude, r.geo_longitude, 
			   r.geo_country, r.geo_region, r.geo_city_id, r.map_entity, r.egrid_ref, r.geo_type, r.disposal_dtm, r.acquisition_dtm, r.lookup_key, r.region_ref
		  FROM TABLE(v_region_sids) rs
		  JOIN v$region r ON rs.sid_id = r.region_sid
		  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid
		  LEFT JOIN region pr ON r.parent_sid = pr.region_sid AND r.app_sid = pr.app_sid
		 ORDER BY rs.pos;
		  
	OPEN out_tag_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM TABLE(v_region_sids) s, region_tag rt
		 WHERE rt.region_sid = s.sid_id
		 ORDER BY rt.region_sid, rt.tag_id;		  
END;

PROCEDURE GetRegionFromKey(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_lookup_key		IN region.lookup_key%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
    v_sid   security_pkg.T_SID_ID;
BEGIN
    BEGIN
        SELECT region_sid
          INTO v_sid
          FROM region
         WHERE UPPER(lookup_key) = UPPER(in_lookup_key)
           AND app_sid = in_app_sid
           AND region_sid NOT IN ( -- filter out deleted regions
                SELECT region_sid
                  FROM region
                  START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = in_app_sid)
                CONNECT BY PRIOR region_sid = parent_sid
               );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Region not found with key '||in_lookup_key);
    END;
    -- GetRegion will do our security checking...
    GetRegion(in_act_id, v_sid, out_cur);
END;

PROCEDURE INTERNAL_GetCoreRegionsBySids(
	in_region_sids				IN	security.T_SID_TABLE,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, parent_sid AS parent_id, r.lookup_key, r.region_ref, link_to_region_sid AS link_to_region_id, 
			   r.region_type, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type
		  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(in_region_sids))
		ORDER BY r.region_sid;
	
	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid IN (SELECT column_value FROM TABLE(in_region_sids))
		ORDER BY r.region_sid;
END;

FUNCTION INTERNAL_GetTrashedRegionSids
RETURN security.T_SID_TABLE
AS
	v_trashed_region_sids		security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_trashed_region_sids
	  FROM (
		SELECT region_sid
		  FROM region 
			START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
			CONNECT BY PRIOR region_sid = parent_sid
		);	
	RETURN v_trashed_region_sids;
END;

PROCEDURE INTERNAL_GetCoreRegions(
	in_include_all				IN	NUMBER,
	in_include_null_lookup_keys	IN	NUMBER,
	in_lookup_keys				IN	security.T_VARCHAR2_TABLE,
	in_skip						IN	NUMBER,
	in_take						IN	NUMBER,
	out_region_cur				OUT	SYS_REFCURSOR,
	out_description_cur			OUT	SYS_REFCURSOR,
	out_total_rows_cur			OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_region_sids				security.T_SID_TABLE;
	v_trashed_region_sids		security.T_SID_TABLE;
BEGIN
	v_lookup_keys := in_lookup_keys;
			
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
		
	SELECT region_sid 		
	  BULK COLLECT INTO v_region_sids
	  FROM (
		SELECT region_sid, rownum rn
		  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				ORDER BY r.region_sid
				)
			)
		WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;
	
	OPEN out_total_rows_cur FOR
		SELECT COUNT(r.region_sid) total_rows
		  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (in_include_all = 1 OR (LOWER(r.lookup_key) IN (SELECT LOWER(x.value) FROM TABLE(v_lookup_keys) x)) OR (r.lookup_key IS NULL AND in_include_null_lookup_keys = 1))
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));

	INTERNAL_GetCoreRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE GetCoreRegions(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	INTERNAL_GetCoreRegions(
		in_include_all				=> 1,
		in_include_null_lookup_keys	=> 0,
		in_lookup_keys				=> security.T_VARCHAR2_TABLE(),
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_region_cur				=> out_region_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE GetCoreRegionsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_lookup_keys				security.T_VARCHAR2_TABLE;
	v_lookup_keys_count			NUMBER;
	v_lookup_contains_null		NUMBER(1) := 0;
BEGIN	
	v_lookup_keys := security_pkg.Varchar2ArrayToTable(in_lookup_keys);
	SELECT COUNT(*)
	  INTO v_lookup_keys_count
	  FROM TABLE(v_lookup_keys);
	
	IF in_lookup_keys.COUNT = 1 AND v_lookup_keys_count = 0 THEN
		-- Single null key in the params doesn't turn into a single null table entry for some reason.
		v_lookup_contains_null := 1;
	END IF;
	
	FOR r IN (SELECT value FROM TABLE(v_lookup_keys))
	LOOP
		IF r.value IS NULL OR LENGTH(r.value) = 0 THEN
			v_lookup_contains_null := 1;
			EXIT;
		END IF;
	END LOOP;
	
	INTERNAL_GetCoreRegions(
		in_include_all				=> 0,
		in_include_null_lookup_keys	=> v_lookup_contains_null,
		in_lookup_keys				=> v_lookup_keys,
		in_skip						=> in_skip,
		in_take						=> in_take,
		out_region_cur				=> out_region_cur,
		out_description_cur			=> out_description_cur,
		out_total_rows_cur			=> out_total_rows_cur
	);
END;

PROCEDURE UNSEC_GetCoreRegionsByDescrptn(
	in_description			IN	region_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();

	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM (
		SELECT region_sid, rownum rn
		  FROM (
			SELECT DISTINCT r.region_sid
			  FROM region r
			  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND d.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			   AND LOWER(d.description) = LOWER(in_description)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			ORDER BY r.region_sid
				)
			)
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;
		
	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(r.region_sid)) total_rows
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(d.description) = LOWER(in_description)
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));

	INTERNAL_GetCoreRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE UNSEC_GetCoreRegionBySid(
	in_sid					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
)
AS
	v_trashed_region_sids		security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
	
	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, parent_sid AS parent_id, r.lookup_key, r.region_ref, link_to_region_sid AS link_to_region_id, 
			   r.region_type, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type
		  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = in_sid
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));
		
	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = in_sid
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));
END;

PROCEDURE UNSEC_GetCoreRegionByPath(
	in_path					IN	VARCHAR2,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
)
AS
v_region_sid				security_pkg.T_SID_ID;
path_cur 					SYS_REFCURSOR;
BEGIN

	FindCoreRegionPath(
		in_act_id			=> SYS_CONTEXT('SECURITY', 'ACT'),
		in_app_sid			=> SYS_CONTEXT('SECURITY', 'APP'),
		in_path				=> LOWER(in_path),
		in_separator		=> '/',
		out_cur				=> path_cur
	);

	LOOP
		FETCH path_cur INTO v_region_sid;
		 EXIT WHEN path_cur%notfound;
	END LOOP;
	CLOSE path_cur;

	OPEN out_region_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, parent_sid AS parent_id, r.lookup_key, r.region_ref, link_to_region_sid AS link_to_region_id, 
			   r.region_type, r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type
		  FROM region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v_region_sid;
		
	OPEN out_description_cur FOR
		SELECT DISTINCT r.region_sid AS region_id, d.lang AS "language", d.description
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.region_sid = v_region_sid;
END;

PROCEDURE FindCoreRegionPath(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 			T_PATH;
	v_parents				security.T_SID_TABLE;
	v_new_parents			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	SELECT LOWER(TRIM(item)) 
		BULK COLLECT INTO v_path_parts 
		FROM table(utils_pkg.SplitString(in_path, in_separator));
		
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
		
	-- populate possible parents with the first part of the path
	BEGIN
		SELECT region_sid 
		  BULK COLLECT INTO v_parents
		  FROM v$region
		 WHERE LOWER(description) = v_path_parts(1)
		   AND app_sid = in_app_sid
		   AND active = 1
		   AND region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
		   AND region_sid IN (
				SELECT region_sid
				  FROM region
				 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid
			   CONNECT BY PRIOR region_sid = parent_sid
			);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT region_sid
				  FROM v$region
				 WHERE 1 = 0;
			RETURN;
	END;
	-- now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- select everything that matches into a set of possible parents
		SELECT region_sid 
		BULK COLLECT INTO v_new_parents
		FROM v$region
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (
			SELECT COLUMN_VALUE
 			  FROM TABLE(v_parents)
		);	
		v_parents := v_new_parents; -- we have to select into a different collection, so copy back on top
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;
	-- check permissions and return the stuff we've found
	OPEN out_cur FOR
		SELECT region_sid
		  FROM v$region
		 WHERE region_sid IN (
		 	SELECT column_value
		 	  FROM TABLE(v_parents)
		   );
END;

PROCEDURE UNSEC_GetCoreRegionsByGeoCtry(
	in_geo_country			IN	region.geo_country%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM (
		SELECT DISTINCT region_sid, rownum rn
		  FROM (
				SELECT r.region_sid
				  FROM region r
				 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND LOWER(r.geo_country) = LOWER(in_geo_country)
				   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
				ORDER BY r.region_sid
				)
		  )
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1; 
		  
		  OPEN out_total_rows_cur FOR
			SELECT COUNT(DISTINCT(r.region_sid)) total_rows
			  FROM region r
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND LOWER(r.geo_country) = LOWER(in_geo_country)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));

	INTERNAL_GetCoreRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE UNSEC_GetCoreRegionsByGeoRegn(
	in_geo_region			IN	region.geo_region%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();

	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM (
		SELECT DISTINCT region_sid, rownum rn
		  FROM (
			SELECT r.region_sid
			  FROM region r
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND LOWER(r.geo_region) = LOWER(in_geo_region)
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			ORDER BY r.region_sid
				)
		  )
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;
		
	OPEN out_total_rows_cur FOR
		SELECT COUNT(DISTINCT(r.region_sid)) total_rows
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(r.geo_region) = LOWER(in_geo_region)
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));

	INTERNAL_GetCoreRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

PROCEDURE UNSEC_GetCoreRegionsByGeoCity(
	in_geo_city_id			IN	region.geo_city_id%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_region_cur			OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sids			security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
	
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM (
		SELECT region_sid, rownum rn
		  FROM (
			SELECT r.region_sid
			  FROM region r
			 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND r.geo_city_id = in_geo_city_id
			   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids))
			ORDER BY r.region_sid
				)
		  )
		 WHERE rn > in_skip
		  AND rn < in_skip + in_take + 1;
		
	OPEN out_total_rows_cur FOR
		SELECT COUNT(r.region_sid) total_rows
		  FROM region r
		  JOIN region_description d ON r.region_sid = d.region_sid AND  r.app_sid = d.app_sid
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND r.geo_city_id = in_geo_city_id
		   AND r.region_sid NOT IN (SELECT column_value FROM TABLE(v_trashed_region_sids));

	INTERNAL_GetCoreRegionsBySids(
		in_region_sids			=>	v_region_sids,
		out_region_cur			=>	out_region_cur,
		out_description_cur		=>	out_description_cur
	);
END;

FUNCTION GetRegionSidFromRef(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_region_ref		IN region.region_ref%TYPE
) RETURN security_pkg.T_SID_ID
AS 
	v_sid   security_pkg.T_SID_ID;
BEGIN
	BEGIN
        SELECT region_sid
          INTO v_sid
          FROM region
         WHERE UPPER(region_ref) = UPPER(in_region_ref)
           AND app_sid = in_app_sid 
           AND region_sid NOT IN ( -- filter out deleted regions
                SELECT region_sid
                  FROM region
                  START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = in_app_sid)
                CONNECT BY PRIOR region_sid = parent_sid
               );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Region not found with ref '||in_region_ref);
    END;
	RETURN v_sid;
END;

PROCEDURE GetRegionSidsFromRef (
	in_region_ref		IN region.region_ref%TYPE,
	out_regions_cur		OUT	SYS_REFCURSOR
)
AS 
BEGIN
	BEGIN
		OPEN out_regions_cur FOR
			SELECT region_sid
			  FROM region
			 WHERE UPPER(region_ref) = UPPER(in_region_ref)
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP') 
			   AND region_sid NOT IN ( -- filter out deleted regions
					SELECT region_sid
					  FROM region
					 START WITH parent_sid IN (SELECT trash_sid FROM customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') )
					 CONNECT BY PRIOR region_sid = parent_sid
					);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'Region not found with ref '||in_region_ref);
	END;
END;

PROCEDURE GetRegionFromRef(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_region_ref		IN region.region_ref%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
    v_sid   security_pkg.T_SID_ID;
BEGIN
	v_sid := GetRegionSidFromRef(in_act_id, in_app_sid, in_region_ref);
    -- GetRegion will do our security checking...
    GetRegion(in_act_id, v_sid, out_cur);
END;

PROCEDURE GetRegions(
	in_region_sids	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_roots 		security.T_ORDERED_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sids, 0);
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ region_sid sid_id, description, link_to_region_sid, active, r.region_type, rt.class_name, vr.pos
		  FROM table(v_roots) vr 
		  JOIN v$region r ON r.region_sid = vr.sid_id 
		  JOIN region_type rt ON r.region_type = rt.region_type
		 ORDER BY vr.pos;
END;

PROCEDURE GetGeoDataLowBound(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_geo_country			region.geo_country%TYPE;
	v_geo_region   			region.geo_region%TYPE;
	v_geo_city				region.geo_city_id%TYPE;
	v_geo_latitude			region.geo_latitude%TYPE;
	v_geo_longitude			region.geo_longitude%TYPE;
	v_country_name			postcode.country.name%TYPE;
	v_region_name			postcode.region.name%TYPE;
	v_city_name				postcode.city.city_name%TYPE;	
	v_geo_type_lowbound		region.geo_type%TYPE;
	v_geo_type_agg_lowbound region.geo_type%TYPE;
	v_geo_country_lowbound	region.geo_country%TYPE;
	v_geo_region_lowbound	region.geo_region%TYPE;
	v_geo_city_lowbound		region.geo_city_id%TYPE;
	v_row_count				NUMBER;
BEGIN	
	SELECT geo_country, geo_region, geo_city_id, geo_latitude, geo_longitude
	  INTO v_geo_country, v_geo_region, v_geo_city, v_geo_latitude, v_geo_longitude
	  FROM region
	 WHERE region_sid = in_region_sid;	
	
	-- get geo properties boundaries
	-- 1) check against the ancestors => enforced by the UI (actually very simple, because you only have one parent...)
	-- 2) check against the children
	
	-- Is lower bound exist??
	SELECT MIN(geo_type) 
	  INTO v_geo_type_lowbound 
	  FROM (SELECT region_sid, geo_type
			  FROM region
		     WHERE geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)
		     START WITH parent_sid = in_region_sid
		   CONNECT BY PRIOR region_sid = parent_sid);
	
	IF v_geo_type_lowbound IS NOT NULL THEN -- if such geo lower bound exist, 
		-- First, take geo properties of child with the minimum geo_type
		SELECT geo_type, geo_country, geo_region, geo_city_id 
		  INTO v_geo_type_lowbound, v_geo_country_lowbound, v_geo_region_lowbound, v_geo_city_lowbound
		  FROM (SELECT region_sid, geo_type, geo_country, geo_region, geo_city_id
				  FROM (SELECT region_sid, geo_type, geo_country, geo_region, geo_city_id
						  FROM region
					     WHERE geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)
					  		   START WITH parent_sid = in_region_sid
					 		   CONNECT BY PRIOR region_sid = parent_sid
					   		   ORDER SIBLINGS BY geo_type) 
			      WHERE ROWNUM = 1);
		
		-- First, find commonality within geo properties
		v_geo_type_agg_lowbound := REGION_GEO_TYPE_CITY; -- initialize to city level (minimum)
		v_row_count := GetGeoCommonality(in_act_id, in_region_sid, REGION_GEO_TYPE_COUNTRY);
		IF v_row_count > 1 THEN -- don't agree on country 
			v_geo_type_agg_lowbound := REGION_GEO_TYPE_COUNTRY; -- lower bound is country level
		ELSE
			v_row_count := GetGeoCommonality(in_act_id, in_region_sid, REGION_GEO_TYPE_REGION);
			IF v_row_count > 1 THEN -- don't agree on region 
				v_geo_type_agg_lowbound := REGION_GEO_TYPE_REGION; -- lower bound is region level  
			END IF;
		END IF;
	
		-- Second, the real lower bound is the minimum between aggregated and the first geo level
		IF v_geo_type_agg_lowbound < v_geo_type_lowbound THEN
			v_geo_type_lowbound := v_geo_type_agg_lowbound; 
		END IF;
		
		-- Third, enforce geo properties of the sons
		IF v_geo_type_lowbound >= REGION_GEO_TYPE_COUNTRY THEN
			v_geo_country := v_geo_country_lowbound; -- at minimum enforce country 
			IF v_geo_type_lowbound >= REGION_GEO_TYPE_REGION THEN
				v_geo_region := v_geo_region_lowbound; -- at minimum enforce region
				IF v_geo_type_lowbound >= REGION_GEO_TYPE_CITY THEN
					v_geo_city := v_geo_city_lowbound; -- at minimum enforce city
				END IF;
			END IF;
		END IF;
	END IF;
		
	-- fetch names
	IF v_geo_country IS NOT NULL THEN
		SELECT name 
		  INTO v_country_name 
		  FROM postcode.country 
		 WHERE country = v_geo_country;
	
		IF v_geo_region IS NOT NULL THEN
			SELECT name 
			  INTO v_region_name 
			  FROM postcode.region 
			 WHERE country = v_geo_country 
			   AND region = v_geo_region;
			
			IF v_geo_city IS NOT NULL THEN
				SELECT city_name 
			 	  INTO v_city_name 
			 	  FROM postcode.city 
			 	 WHERE city_id = v_geo_city;
			END IF;
		END IF;
	END IF;
	
	OPEN out_cur FOR                                    
		SELECT in_region_sid, v_geo_country geo_country, v_geo_region geo_region, v_geo_latitude geo_latitude, v_geo_longitude geo_longitude, 
			   v_geo_city geo_city_id, v_country_name country_name, v_region_name region_name, 
			   v_city_name city_name, v_geo_type_lowbound geo_type_lowbound
		  FROM DUAL;
END;

FUNCTION GetGeoCommonality(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_geo_level		IN NUMBER
) RETURN NUMBER
AS
	v_row_count			NUMBER;
BEGIN
	IF in_geo_level = REGION_GEO_TYPE_COUNTRY THEN
		SELECT COUNT(*)
		  INTO v_row_count
		  FROM (SELECT 1
				  FROM region
				 WHERE geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)
					   START WITH parent_sid = in_region_sid
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
				 GROUP BY geo_country);
	ELSIF in_geo_level = REGION_GEO_TYPE_REGION THEN
		SELECT COUNT(*)
		  INTO v_row_count
		  FROM (SELECT 1
				  FROM region
				 WHERE geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)
					   START WITH parent_sid = in_region_sid
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
				 GROUP BY geo_country, geo_region);
	ELSE
		SELECT COUNT(*)
		  INTO v_row_count
		  FROM (SELECT 1
				  FROM region
				 WHERE geo_type NOT IN (REGION_GEO_TYPE_OTHER, REGION_GEO_TYPE_INHERITED, REGION_GEO_TYPE_LOCATION)
					   START WITH parent_sid = in_region_sid
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
				 GROUP BY geo_country, geo_region, geo_city_id);
	END IF;
	
	RETURN v_row_count;	
END;

PROCEDURE GetGeoData(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_geo_country			region.geo_country%TYPE;
	v_geo_region    		region.geo_region%TYPE;
	v_geo_city     			region.geo_city_id%TYPE;
	v_geo_latitude			region.geo_latitude%TYPE;
	v_geo_longitude			region.geo_longitude%TYPE;
	v_geo_type				region.geo_type%TYPE;
	v_egrid_ref				region.egrid_ref%TYPE;
	v_country_name			postcode.country.name%TYPE;
	v_region_name   		postcode.region.name%TYPE;
	v_city_name     		postcode.city.city_name%TYPE;
BEGIN
	SELECT geo_type, geo_country, geo_region, geo_city_id, geo_latitude, geo_longitude, egrid_ref
	  INTO v_geo_type, v_geo_country, v_geo_region, v_geo_city, v_geo_latitude, v_geo_longitude, v_egrid_ref
	  FROM region
	 WHERE region_sid = in_region_sid;	
	
	-- fetch names
	IF v_geo_country IS NOT NULL THEN
		SELECT name 
		  INTO v_country_name 
		  FROM postcode.country 
		 WHERE country = v_geo_country;
	
		IF v_geo_region IS NOT NULL THEN
			SELECT name 
			  INTO v_region_name 
			  FROM postcode.region 
			 WHERE country = v_geo_country 
			   AND region = v_geo_region;
			
			IF v_geo_city IS NOT NULL THEN
				SELECT city_name 
				  INTO v_city_name 
				  FROM postcode.city 
				 WHERE city_id = v_geo_city;
			END IF;
		END IF;
	END IF;
	
	OPEN out_cur FOR                                    
		SELECT in_region_sid, v_geo_type geo_type, v_geo_country geo_country, v_geo_region geo_region, 
			   v_geo_city geo_city_id, v_geo_latitude geo_latitude, v_geo_longitude geo_longitude, v_country_name country_name, v_region_name region_name, 
			   v_city_name city_name, v_egrid_ref egrid_ref
		  FROM DUAL;
END;

-- Copy of indicator_pkg.LookupIndicator
PROCEDURE LookupRegion(
	in_text				IN	region_description.description%TYPE,
	in_ancestors		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_region_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_text region_description.description%TYPE;
	v_ancestors security.T_VARCHAR2_TABLE;
	v_first_ancestor NUMBER;
	v_last_ancestor NUMBER;
	v_ancestor_count NUMBER;
BEGIN
	v_text := LOWER(in_text);
	v_ancestors := security_pkg.Varchar2ArrayToTable(in_ancestors);
	v_first_ancestor := in_ancestors.FIRST;
	v_last_ancestor := in_ancestors.LAST;
	
	-- We can't rely on in_ancestors.COUNT becasue of the ODP.NET hack where we pass an array with a single NULL element rather than an empty array.
	
	SELECT COUNT(*) INTO v_ancestor_count FROM TABLE(v_ancestors);

	BEGIN
		WITH region_hierarchy AS
		(
			 SELECT CONNECT_BY_ROOT region.region_sid root_region_sid, region.region_sid, LEVEL region_level, CASE WHEN filter.pos IS NULL AND LEVEL = 1 THEN v_last_ancestor + 1 ELSE filter.pos END filter_pos
			   FROM v$region region
			   LEFT JOIN TABLE(v_ancestors) filter
				 ON filter.value = region.description
			  WHERE region.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			  START WITH LOWER(region.description) = v_text
			CONNECT BY region.region_sid = PRIOR region.parent_sid
				AND region.app_sid = PRIOR region.app_sid
		)
		 SELECT region_sid INTO out_region_sid
		   FROM region_hierarchy
		  WHERE (v_ancestor_count = 0 AND region_level = 1)
		     OR filter_pos = v_last_ancestor + 1
		  START WITH v_ancestor_count = 0
		     OR (filter_pos = v_first_ancestor AND region_level > 1)
		CONNECT BY root_region_sid = PRIOR root_region_sid
			AND filter_pos = PRIOR filter_pos + 1
			AND region_level < PRIOR region_level;
	EXCEPTION
		WHEN no_data_found THEN
			out_region_sid := -1;
	END;
END;

PROCEDURE FindRegionPath(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT SYS_REFCURSOR
)
AS
	TYPE T_PATH IS TABLE OF VARCHAR2(1024) INDEX BY BINARY_INTEGER;
	v_path_parts 		T_PATH;
	v_parents			security.T_SID_TABLE;
	v_new_parents		security.T_SID_TABLE;
BEGIN
	SELECT LOWER(TRIM(item)) 
      BULK COLLECT INTO v_path_parts 
      FROM table(utils_pkg.SplitString(in_path, in_separator));
	-- populate possible parents with the first part of the path
	BEGIN
		SELECT region_sid 
		  BULK COLLECT INTO v_parents
		  FROM v$region
		 WHERE LOWER(description) = v_path_parts(1)
		   AND app_sid = in_app_sid
		   AND active = 1
		   AND region_sid IN (
				SELECT region_sid
				  FROM region
				 START WITH region_sid = region_tree_pkg.GetPrimaryRegionTreeRootSid -- umm -- shouldnt' this be the mount point?
			   CONNECT BY PRIOR region_sid = parent_sid		   
		   );
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_cur FOR
				SELECT region_sid, parent_sid, name, description, active, pos, geo_latitude, geo_longitude, geo_country, 
					   geo_region, geo_city_id, map_entity, egrid_ref, geo_type, region_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref
				  FROM v$region
				 WHERE 1 = 0;
			RETURN;
	END;
	-- now check each part of the rest of the path
	FOR i IN 2 .. v_path_parts.LAST
	LOOP
		-- select everything that matches into a set of possible parents
		SELECT region_sid 
	      BULK COLLECT INTO v_new_parents
	      FROM v$region
		 WHERE LOWER(description) = TRIM(v_path_parts(i))
		   AND active = 1
		   AND parent_sid IN (
			SELECT COLUMN_VALUE
 			  FROM TABLE(v_parents)
	    );	
		v_parents := v_new_parents; -- we have to select into a different collection, so copy back on top
		IF v_parents.COUNT = 0 THEN
			EXIT;
		END IF;
	END LOOP;
	-- check permissions and return the stuff we've found
	OPEN out_cur FOR
		SELECT region_sid, parent_sid, name, description, active, pos, geo_latitude, geo_longitude, geo_country, 
			   geo_region, geo_city_id, map_entity, egrid_ref, geo_type, region_type, disposal_dtm, acquisition_dtm, lookup_key, region_ref
		  FROM v$region
		 WHERE region_sid IN (
		 	SELECT column_value
		 	  FROM TABLE(v_parents)
		   )
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, region_sid, security_pkg.PERMISSION_READ)=1;
END;



-- why??! what calls this?
FUNCTION CountChildren(
	in_parent_sids 	IN	security_pkg.T_SID_IDS
) RETURN NUMBER
AS
	t 			security.T_SID_TABLE;
	v_cnt		NUMBER(10);
BEGIN
	t := security_pkg.SidArrayToTable(in_parent_sids);	
	SELECT count(*) 
   	  INTO v_cnt
	  FROM region r, TABLE(t)t
     WHERE r.parent_sid = t.column_value;
    RETURN v_cnt;
END;


-- for report
PROCEDURE UNSEC_GetIndentation(
	in_parent_sids 	IN	security_pkg.T_SID_IDS,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	t 			security.T_SID_TABLE;
BEGIN
	t := security_pkg.SidArrayToTable(in_parent_sids);	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ x.region_sid, x.lvl - MIN(lvl) OVER () indent
		  FROM (
			SELECT region_sid, description, level lvl, rownum rn
			  FROM v$region
			 START WITH region_sid = (
				SELECT region_root_sid FROM customer WHERE app_sid = security_pkg.getApp
			 )
			CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
		 )x
		 WHERE x.region_sid IN (
			SELECT region_sid
			  FROM region
			 START WITH region_sid IN (
				SELECT column_value FROM TABLE(t)
			 )
			CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid
		 );
END;

-- NB parses links to return linked children
PROCEDURE GetChildren_(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	in_active						IN	NUMBER,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_root_region_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
		
	OPEN out_region_cur FOR
		SELECT /*+ALL_ROWS*/ 
			   NVL(rl.region_sid, r.region_sid) region_sid, 
			   NVL(rl.name, r.name) name, 
			   NVL(rl.description, r.description) description, 
			   NVL(rl.parent_sid, r.parent_sid) parent_sid,
			   NVL(rl.pos, r.pos) pos,
			   NVL(rl.info_xml, r.info_xml) info_xml,
			   NVL(rl.active, r.active) active,
			   NVL(rl.link_to_region_sid, r.link_to_region_sid) link_to_region_sid,
			   NVL(rl.map_entity, r.map_entity) map_entity,
			   NVL(rl.egrid_ref, r.egrid_ref) egrid_ref,
			   NVL(rl.geo_type, r.geo_type) geo_type,
			   NVL(rl.geo_country, r.geo_country) geo_country,
			   NVL(rl.geo_region, r.geo_region) geo_region,
			   NVL(rl.geo_city_id, r.geo_city_id) geo_city_id,
			   NVL(rl.geo_latitude, r.geo_latitude) geo_latitude,
			   NVL(rl.geo_longitude, r.geo_longitude) geo_longitude,
			   NVL(rl.region_type, r.region_type) region_type,
			   NVL(rl.disposal_dtm, r.disposal_dtm) disposal_dtm,
			   NVL(rl.acquisition_dtm, r.acquisition_dtm) acquisition_dtm,
			   NVL(rl.lookup_key, r.lookup_key) lookup_key,
			   NVL(rl.region_ref, r.region_ref) region_ref
		  FROM v$region r
		  LEFT JOIN v$region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid 
		 WHERE r.parent_sid = in_root_region_sid 
		   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND (NVL(rl.active, r.active) = in_active OR in_active IS NULL)
		 ORDER BY REGEXP_SUBSTR(LOWER(NVL(rl.description, r.description)), '^\D*'),
			   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(NVL(rl.description, r.description)), '[0-9]+', 1, 2))) NULLS FIRST,
			   LOWER(NVL(rl.description, r.description));

	OPEN out_region_tag_cur FOR
		SELECT rt.region_sid, rt.tag_id
		  FROM region r, region_tag rt
		 WHERE r.parent_sid = in_root_region_sid
		   AND r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND (r.active = in_active OR in_active IS NULL)
		   AND r.app_sid = rt.app_sid AND r.region_sid = rt.region_sid
		 ORDER BY rt.region_sid, rt.tag_id;
END;

PROCEDURE GetChildren(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetChildren_(in_act_id, in_root_region_sid, 1, out_region_cur, out_region_tag_cur);
END;

PROCEDURE GetChildrenInclInactive(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetChildren_(in_act_id, in_root_region_sid, null, out_region_cur, out_region_tag_cur);
END;

PROCEDURE GetInactiveChildren(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	out_region_cur					OUT	SYS_REFCURSOR,
	out_region_tag_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	GetChildren_(in_act_id, in_root_region_sid, 0, out_region_cur, out_region_tag_cur);
END;

/**
 * Searches through regions
 *
 * @param	in_act_id			Access token
 * @param   in_app_sid 	CSR Root SID
 * @param	in_phrase			Search phrase (or null)
 */
PROCEDURE Search(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_phrase		 	IN VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid, description, name, active 
		  FROM v$region 
		 WHERE app_sid = in_app_sid
		   AND LOWER(description) LIKE '%'||LOWER(in_phrase)||'%'
		   AND active = 1
		 ORDER BY description;
END;


PROCEDURE GetRegionsForList(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_region_list	IN	VARCHAR2,
	out_cur			OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT region_sid, parent_sid, name, description, active, r.pos
		  FROM TABLE(Utils_Pkg.SplitString(in_region_list,','))l, v$region r
		 WHERE l.item = r.region_sid 
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, l.item, security_pkg.PERMISSION_READ)=1
		 ORDER BY l.POS;
END;

/* region ownership */
PROCEDURE SetOwners(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_user_sid		IN	security_pkg.T_SID_ID,
	in_region_list	IN	VARCHAR2
)
AS
	t_items				T_SPLIT_TABLE;
BEGIN  
	-- ok, pull what we're setting stuff to out into a table 
	t_items := Utils_Pkg.SplitString(in_region_list, ',');
	
	DELETE FROM REGION_OWNER WHERE USER_SID = in_user_sid;
	
	INSERT INTO REGION_OWNER (USER_SID, REGION_SID) 
		SELECT in_user_sid, t.item FROM TABLE(t_items) t; 
END;


PROCEDURE FilterRegionsLimit(  
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,	 
	in_filter			IN	VARCHAR2,
	in_limit			IN	NUMBER,
	out_cur				OUT SYS_REFCURSOR
)      
AS	   
BEGIN		   
	OPEN out_cur FOR
		SELECT *
		  FROM (
				SELECT region_sid, description
				  FROM v$region
				 WHERE LOWER(description) LIKE LOWER(in_filter)||'%'
				   AND app_sid = in_app_sid
				   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, region_sid, security_pkg.PERMISSION_READ) = 1
				   AND active = 1 -- active only!
				 ORDER BY description
			    )
		  WHERE rownum <= in_limit;
END;	

PROCEDURE FilterRegions(
	in_filter		IN	region_description.description%TYPE,
	in_region_type	IN	region.region_type%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_region_sids	security.T_SID_TABLE;
BEGIN
	SELECT region_sid
	  BULK COLLECT INTO v_region_sids
	  FROM v$region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND LOWER(description) LIKE LOWER('%'||in_filter||'%')
	   AND active = 1 -- active only
	   AND (in_region_type IS NULL OR region_type = in_region_type);
	
	OPEN out_cur FOR    
		SELECT region_sid, description, path, region_type, region_ref, active, class_name
		  FROM (
			SELECT rt.region_type, rt.class_name, r.region_sid, r.description, replace(ltrim(sys_connect_by_path(prior r.description, ''),''),'',' > ') path, r.region_ref, r.active
			  FROM v$region r
			  JOIN region_type rt ON r.region_type = rt.region_type
			 WHERE region_sid IN (
				SELECT column_value FROM TABLE(v_region_sids)
			 )
			 START WITH parent_sid = (
				-- restrict to stuff under the primary
				SELECT region_tree_root_sid FROM region_tree WHERE is_primary = 1
			 )
			 CONNECT BY PRIOR region_sid = parent_sid
		  )
		  WHERE region_sid IN (
			SELECT sid_id FROM TABLE(SecurableObject_pkg.GetSIDsWithPermAsTable(SYS_CONTEXT('SECURITY','ACT'), v_region_sids,
				security_pkg.PERMISSION_READ))
		 );
END; 


/**
 * Returns a list of owners for an region
 *
 * @param	in_act_id		Access token
 * @param   in_region_sid 	Region SID
 */
PROCEDURE GetRegionsForUser(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_app_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	  
	
	OPEN out_cur FOR 
		SELECT r.region_sid, r.description 
		  FROM v$region r, region_owner ro
		 WHERE r.region_sid = ro.region_sid
		   AND ro.user_sid = in_user_sid
		   AND r.app_sid = in_app_sid
		 ORDER BY r.description;
END;


PROCEDURE FilterRegions(  
	in_act_id			IN 	security_pkg.T_ACT_ID,
	in_app_sid		IN	security_pkg.T_SID_ID,	 
	in_filter			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
)      
AS	   
BEGIN		   
	OPEN out_cur FOR  	
		SELECT region_sid, description
		  FROM v$region
		 WHERE LOWER(description) LIKE LOWER(in_filter)||'%'
		   AND app_sid = in_app_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, region_sid, security_pkg.PERMISSION_READ) = 1
		   AND active = 1 -- active only!
		 ORDER BY DESCRIPTION;
END;	


PROCEDURE GetActiveUsersForRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN	  
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	  
	
	OPEN out_cur FOR 
		SELECT cu.full_name, cu.email, ro.user_sid
		  FROM csr_user cu, region_owner ro, security.user_table ut
		 WHERE cu.csr_user_sid = ro.user_sid AND ro.user_sid = ut.sid_id AND cu.csr_user_sid = ut.sid_id
		   AND ro.region_sid = in_region_sid
		   AND ut.account_enabled = 1
		 ORDER BY cu.full_name;
END;


PROCEDURE AddUserToRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN	  
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	  
	
	BEGIN
		INSERT INTO region_owner
			(region_sid, user_sid)
		VALUES
			(in_region_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN 
			NULL;
	END;
END;


PROCEDURE RemoveUserFromRegion(
	in_act_id 			IN security_pkg.T_ACT_ID,
	in_region_sid		IN security_pkg.T_SID_ID,
	in_user_sid			IN security_pkg.T_SID_ID
)
AS
BEGIN	  
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	  
	
	DELETE FROM region_owner
	 WHERE region_sid = in_region_sid
       AND user_sid = in_user_sid;
END;

-- TODO: check for circular reference
PROCEDURE CreateLinkToRegion(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_parent_sid		IN	security_pkg.T_SID_ID, 
	in_link_to_sid		IN	security_pkg.T_SID_ID, 
	out_region_sid		OUT security_pkg.T_SID_ID 
)
AS
	v_region_name			region.name%TYPE;
	v_region_description	region_description.description%TYPE;
	v_app_sid				security_pkg.T_SID_ID;
	v_guid					security_pkg.T_ACT_ID;
	v_is_primary			NUMBER(10);
	v_parent_link_to_sid	security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_link_to_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;	  

	-- get details of the region we're linking to (name etc)
	SELECT name, description, app_sid
	  INTO v_region_name, v_region_description, v_app_sid
	  FROM v$region
	 WHERE region_sid = in_link_to_sid;
	
	-- check that the parent_sid is in a secondary tree
	v_is_primary := region_tree_pkg.IsInPrimaryTree(in_parent_sid);
	-- also find out if the parent_sid is itself a link (which is not allowed)
	BEGIN
		SELECT link_to_region_sid
		  INTO v_parent_link_to_sid
		  FROM region
		 WHERE region_sid = in_parent_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			-- ignore- just means it's right under the root (i.e. parent_sid isn't in region table)
			NULL;
	END;

	IF v_is_primary = 1 OR v_parent_link_to_sid IS NOT NULL THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_PARENT_IN_PRIMARY_TREE, 'You can only create region links under a secondary tree');				
	END IF;

	-- OLD TODO: not sure if relevant any more: check that link_to_sid isn't already linked to (directly or indirectly) 

	-- 'Link to '||v_region_name (we use a guid for now instead)
	-- we use a guid so that the name is unique but can be exported ok (null would work with csrexp/csrimp
	-- since it would never be able to match existing objects)
	v_guid := user_pkg.GenerateACT;
	
	group_pkg.CreateGroupWithClass(in_act_id, in_parent_sid, security_pkg.GROUP_TYPE_SECURITY,
		v_guid, class_pkg.getClassID('CSRRegion'), out_region_sid);

	INSERT INTO region 
		(region_sid, parent_sid, app_sid, name, active, pos, info_xml, link_to_region_sid)
	VALUES 
		(out_region_sid, in_parent_sid, v_app_sid, v_region_name, 1, 0, NULL, in_link_to_sid);

	INSERT INTO region_description (region_sid, lang, description)
		SELECT out_region_sid, lang, description
		  FROM region_description
		 WHERE region_sid = in_link_to_sid;

	-- add object to the DACL (the region is a group, so it has permissions on itself)
	acl_pkg.AddACE(in_act_id, acl_pkg.GetDACLIDForSID(out_region_sid), security_pkg.ACL_INDEX_LAST, security_pkg.ACE_TYPE_ALLOW,
		security_pkg.ACE_FLAG_DEFAULT, out_region_sid, security_pkg.PERMISSION_STANDARD_READ);
		
	-- shove in some recalc jobs
	AddAggregateJobs(v_app_sid, in_link_to_sid);

	-- Propagate any roles from the parent of the new link
	INTERNAL_InhertRolesFromParent(out_region_sid);
	
	-- Propogare any meter alarms from the parent of the new link
	meter_alarm_pkg.OnConvertRegionToLink(out_region_sid);
	
	csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, 
		out_region_sid, 'Created link from "{0}"', INTERNAL_GetRegionPathString(in_link_to_sid));    	 
END;

PROCEDURE GetReportingRegions(
	in_root_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_onlyActive					IN	NUMBER DEFAULT 0,
	out_cur							OUT SYS_REFCURSOR,
	desc_cur						OUT SYS_REFCURSOR,
	tag_cur							OUT SYS_REFCURSOR
)
AS
	v_root_sids						security.T_SID_TABLE;
	v_trashed_region_sids	security.T_SID_TABLE;
  v_region_sids		      security.T_SID_TABLE;
BEGIN
	v_trashed_region_sids := INTERNAL_GetTrashedRegionSids();
  
	-- Check security on the root region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	SELECT region_sid
    BULK COLLECT INTO v_region_sids
	FROM (
          SELECT r.region_sid
            FROM csr.v$region r
           WHERE r.app_sid = security_pkg.GetApp
             AND NOT EXISTS (SELECT column_value FROM TABLE(v_trashed_region_sids) WHERE column_value = r.region_sid)
           START WITH r.region_sid = in_root_sid
          CONNECT BY PRIOR r.region_sid = parent_sid
   	);

	OPEN out_cur FOR
	SELECT r.region_sid, SYS_CONNECT_BY_PATH(region_sid, '/') ancestry, CONNECT_BY_ISLEAF is_leaf, active
      FROM csr.v$region r
      JOIN TABLE(v_region_sids) v ON r.region_sid = v.column_value
	  AND (CASE WHEN in_onlyActive = 1 THEN r.active ELSE 1 END) = 1
    START WITH r.region_sid = in_root_sid
	CONNECT BY PRIOR r.region_sid = parent_sid;

	OPEN desc_cur FOR
    SELECT DISTINCT r.column_value region_sid, rd.lang, rd.description 
	  FROM TABLE(v_region_sids) r
      JOIN csr.region_description rd ON r.column_value = rd.region_sid
	  JOIN aspen2.translation_set t ON t.hidden = 0 AND t.lang = rd.lang
	ORDER BY r.column_value, rd.lang;
        
	OPEN tag_cur FOR
	SELECT DISTINCT r.column_value region_sid, td.lang, tgd.name, td.tag
	  FROM TABLE(v_region_sids) r
      JOIN csr.region_tag rt ON r.column_value = rt.region_sid
      JOIN csr.tag_group_member tgm ON tgm.tag_id = rt.tag_id AND tgm.app_sid = rt.app_sid
	  JOIN csr.tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tg.app_sid = rt.app_sid
      JOIN csr.tag_group_description tgd ON tgm.tag_group_id = tgd.tag_group_id AND tgd.app_sid = rt.app_sid
      JOIN csr.tag_description td ON td.tag_id = tgm.tag_id AND td.lang = tgd.lang AND td.app_sid = rt.app_sid
	  JOIN aspen2.translation_set tr ON tr.application_sid = rt.app_sid AND tr.hidden = 0;    
END;

PROCEDURE GetTree(
	in_act_id   IN  security_pkg.T_ACT_ID,
	in_sid_id 	IN  security_pkg.T_SID_ID,
	in_depth 	IN  NUMBER,
	out_cur		OUT SYS_REFCURSOR
)
IS
BEGIN
	OPEN out_cur FOR
		-- hardcoded class to CSRRegion
	    SELECT region_pkg.ParseLink(sid_id) sid_id, NAME, class_id, Class_Pkg.GetClassName(class_id) class_name, tree_pkg.GetAttributeList(sid_id, Class_Pkg.GetClassName(class_id)) attribute_list, LEVEL,
				LEVEL so_level
			  FROM SECURITY.securable_object so
	    START WITH sid_id = in_sid_id CONNECT BY PRIOR ParseLink(sid_id) = parent_sid_id AND
			  security_pkg.SQL_IsAccessAllowedSID(in_act_id, sid_id, security_pkg.PERMISSION_READ) = 1 AND LEVEL<=in_depth;
END;


-- internal func so doesn't check security - assumes caller will
-- not ideal from a multilingual perspective
FUNCTION INTERNAL_GetPctOwnershipString(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
  v_s	VARCHAR2(4095) := NULL;
BEGIN
    FOR r IN (
        SELECT start_dtm, end_dtm, pct
          FROM pct_ownership
         WHERE region_sid = in_region_sid
         ORDER BY start_dtm
    )
    LOOP
        IF v_s IS NOT NULL THEN
            v_s := v_s || '; ';
        END IF;
        IF TO_CHAR(r.start_dtm, 'DD') = 1 AND
            TO_CHAR(r.end_dtm, 'DD') = 1 THEN
            -- we can show short form
            v_s := v_s || TO_CHAR(r.start_dtm, 'Mon YYYY') 
                || ' -> ' || TO_CHAR(r.end_dtm - 1, 'Mon YYYY');
        ELSE
            v_s := v_s || TO_CHAR(r.start_dtm, 'FMDD Mon YYYY') 
                || ' -> ' || TO_CHAR(r.end_dtm - 1, 'FMDD Mon YYYY');
        END IF;
        v_s := RTRIM(v_s) || ' (' || r.pct * 100 || '%)'; 
    END LOOP;
    RETURN v_s;
END;

PROCEDURE GetRegionTree(
	in_root_sid						IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR,
	out_tag_groups_cur				OUT SYS_REFCURSOR,
	out_tag_cur						OUT SYS_REFCURSOR,
	out_roles_cur					OUT SYS_REFCURSOR,
	out_role_members_cur			OUT SYS_REFCURSOR
)
AS
	v_root_sids						security.T_SID_TABLE;
	v_region_sids					security.T_SID_TABLE;
BEGIN
	IF in_root_sid IS NULL THEN
		-- get the start sids
		SELECT region_sid
		  BULK COLLECT INTO v_root_sids
		  FROM region_start_point
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID');
	ELSE
		v_root_sids := security.T_SID_TABLE();
		v_root_sids.extend;
		v_root_sids(v_root_sids.count) := in_root_sid;
	   
		-- Check security on the root region sid	
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_root_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
		END IF;
	END IF;

	OPEN out_cur FOR
		SELECT NVL(r.link_to_region_sid, r.region_sid) sid_id,
			   CASE WHEN r.link_to_region_sid IS NOT NULL 
					THEN (SELECT description FROM csr.v$region WHERE region_sid = r.link_to_region_sid)
					ELSE r.description 
			   END description,
			   r.region_sid, LEVEL, r.lookup_key, r.region_ref,
			   CASE WHEN r.link_to_Region_sid IS NOT NULL 
					THEN region_pkg.INTERNAL_GetRegionPathString(r.link_to_Region_sid) 
			   END linked_to,
			   region_pkg.INTERNAL_GetPctOwnershipString(r.region_sid) pct_ownership,
			   CASE WHEN r.link_to_region_sid IS NOT NULL 
					THEN (SELECT active FROM csr.v$region WHERE region_sid = r.link_to_region_sid)
					ELSE r.active
			   END active,
			   country, region, city_name, egrid_ref, r.geo_latitude, r.geo_longitude, r.info_xml, r.acquisition_dtm, r.disposal_dtm, r.parent_sid,
			   CASE WHEN r.link_to_region_sid IS NOT NULL
					THEN (SELECT rt.label FROM csr.v$region thisr JOIN region_type rt ON rt.region_type = thisr.region_type WHERE thisr.region_sid = r.link_to_region_sid)
					ELSE r.region_type_label
			   END region_type_label,
			   r.urjanet_meter_id meter_serial_id,
			   r.meter_type_id, 
			   r.meter_type_label,
			   r.meter_cons_ind_sid, 
			   r.meter_cons_measure_desc,
			   r.meter_cost_ind_sid, 
			   r.meter_cost_measure_desc,
			   r.meter_days_ind_sid, 
			   r.meter_days_measure_desc,
			   r.meter_costdays_ind_sid,
			   r.meter_costdays_measure_desc,
			   r.meter_source_type,
			   r.meter_reference,
			   r.meter_note,
			   r.gresb_asset_id,
			   r.geo_country
		  FROM (
			 SELECT r.parent_sid, r.region_sid, r.description, r.link_to_region_sid, r.active, r.lookup_key,r.region_ref,
					c.name country, rg.name region, cy.city_name, egrid_ref,r.geo_latitude, r.geo_longitude, xmltype.getstringval(r.info_xml) info_xml,
					rt.label region_type_label, r.acquisition_dtm, r.disposal_dtm, r.geo_country,
					m.meter_type_id, mi.label meter_type_label,
					m.primary_ind_sid meter_cons_ind_sid, 
					m.cost_ind_sid meter_cost_ind_sid, 
					m.days_ind_sid meter_days_ind_sid,
					m.costdays_ind_sid meter_costdays_ind_sid,
					st.description meter_source_type, 
					m.reference meter_reference, 
					m.note meter_note, m.urjanet_meter_id,
					NVL(pric.description, prim.description) meter_cons_measure_desc,
					NVL(cstc.description, cstm.description) meter_cost_measure_desc,
					NVL(dayc.description, daym.description) meter_days_measure_desc,
					NVL(cdyc.description, cdym.description) meter_costdays_measure_desc,
					pg.asset_id gresb_asset_id
			   FROM v$region r
			   JOIN region_type rt ON r.region_type = rt.region_type
			   LEFT JOIN postcode.country c ON r.geo_country = c.country
			   LEFT JOIN postcode.region rg ON r.geo_country = rg.country AND r.geo_region = rg.region
			   LEFT JOIN postcode.city cy ON r.geo_city_id = cy.city_id
			   
			   LEFT JOIN v$meter m ON r.region_sid = m.region_sid
			   LEFT JOIN meter_source_type st ON st.meter_source_type_id = m.meter_source_type_id
			   LEFT JOIN v$legacy_meter_type	mi ON mi.meter_type_id = m.meter_type_id
			   
			   LEFT JOIN ind prii ON prii.ind_sid = m.primary_ind_sid
			   LEFT JOIN measure prim ON prim.measure_sid = prii.measure_sid
			   LEFT JOIN measure_conversion pric ON pric.measure_conversion_id = m.primary_measure_conversion_id
			   
			   LEFT JOIN ind csti ON csti.ind_sid = m.cost_ind_sid
			   LEFT JOIN measure cstm ON cstm.measure_sid = csti.measure_sid
			   LEFT JOIN measure_conversion cstc ON cstc.measure_conversion_id = m.cost_measure_conversion_id 
			  
			   LEFT JOIN ind dayi ON dayi.ind_sid = m.days_ind_sid
			   LEFT JOIN measure daym ON daym.measure_sid = dayi.measure_sid
			   LEFT JOIN measure_conversion dayc ON dayc.measure_conversion_id = m.days_measure_conversion_id
			   
			   LEFT JOIN ind cdyi ON cdyi.ind_sid = m.costdays_ind_sid
			   LEFT JOIN measure cdym ON cdym.measure_sid = cdyi.measure_sid
			   LEFT JOIN measure_conversion cdyc ON cdyc.measure_conversion_id = m.costdays_measure_conversion_id 
			   
			   LEFT JOIN property_gresb pg ON pg.region_sid = r.region_sid
			  WHERE r.app_sid = security_pkg.GetApp
		  ) r
		 START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_sids))
		  CONNECT BY PRIOR nvl(link_to_region_sid, region_sid) = parent_sid
		 ORDER SIBLINGS BY 
			REGEXP_SUBSTR(LOWER(description), '^\D*') NULLS FIRST, 
			TO_NUMBER(REGEXP_SUBSTR(LOWER(description), '[0-9]+')) NULLS FIRST, 
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 2))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 3))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 4))) NULLS FIRST,
			LOWER(description), region_sid;

	SELECT NVL(link_to_region_sid, region_sid)
	  BULK COLLECT INTO v_region_sids
	  FROM region
	 WHERE app_sid = security_pkg.GetApp
	 START WITH region_sid IN (SELECT column_value FROM TABLE(v_root_sids))
   CONNECT BY PRIOR nvl(link_to_region_sid, region_sid) = parent_sid;
	  
	OPEN out_tag_groups_cur FOR
	    SELECT tag_group_id, name,
		    NVL((SELECT MAX(COUNT(*))
			       FROM region_tag rt
				  WHERE rt.region_sid in (
						SELECT *
						  FROM TABLE(v_region_sids)
				    )
			      AND rt.tag_id IN (
					SELECT tag_id
					  FROM tag_group_member
					 WHERE tag_group_id = tg.tag_group_id 
				   )
				GROUP BY region_sid),0) tags_count
		 FROM v$tag_group tg
		WHERE app_sid = security_pkg.GetApp
		  AND applies_to_regions = 1;
		  
	OPEN out_tag_cur FOR
		SELECT rt.tag_id, (
			SELECT tag_group_id
			  FROM tag_group_member tgm
			 WHERE tgm.tag_id = rt.tag_id
		 ) tag_group_id, (
			SELECT tag
			  FROM v$tag t
			 WHERE t.tag_id = rt.tag_id) tag_name,
		region_sid
		  FROM region_tag rt
		 WHERE tag_id IN (
			SELECT tag_id
			  FROM tag_group_member
			 WHERE tag_group_id IN (
					SELECT tag_group_id
					  FROM tag_group
					 WHERE app_sid = security_pkg.GetApp
					   AND applies_to_regions = 1
				)
		 )
		 AND rt.region_sid IN (
			SELECT region_sid 
			  FROM TABLE(v_region_sids)
		 )
	   ORDER BY region_sid,tag_group_id;
	
	OPEN out_roles_cur FOR
	   SELECT role_sid, name
		 FROM role r
		WHERE app_sid = security_pkg.getApp;

	OPEN out_role_members_cur FOR
	   SELECT role_sid, region_sid, full_name||' ('||email||')' usr
		 FROM region_role_member rrm
			JOIN csr_user cu ON rrm.app_sid = cu.app_sid and rrm.user_sid = cu.csr_user_sid
		WHERE region_sid IN (			
			SELECT region_sid 
			  FROM TABLE(v_region_sids)
		 )
		  AND inherited_from_sid = region_sid
		 ORDER BY region_sid, role_sid;
END;

-- internal func so doesn't check security - assumes caller will
FUNCTION INTERNAL_GetRegionPathString(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(4095);
BEGIN
	v_s := NULL;
	FOR r IN (
		SELECT region_sid, description
		  FROM v$region
		 START WITH region_sid = in_region_sid CONNECT BY PRIOR parent_sid = region_sid
		 ORDER BY LEVEL DESC
		 )
	LOOP
		IF v_s IS NOT NULL THEN
			v_s := v_s || ' / ';
		END IF;
		v_s := v_s || r.description;
	END LOOP;
	RETURN v_s;
END;

FUNCTION GetRegionPathStringFromStPt(
	in_region_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2 DETERMINISTIC
AS
	v_s							VARCHAR2(4095);
	v_has_primary_region_sp		NUMBER;
	v_access_allowed			NUMBER;
	v_primary_root_region_sid	security_pkg.T_SID_ID;
BEGIN
	v_s := NULL;

	v_primary_root_region_sid	:= region_tree_pkg.GetPrimaryRegionTreeRootSid;

	SELECT COUNT(*)
		INTO v_has_primary_region_sp
		FROM (
			SELECT 1
			  FROM dual
			 WHERE EXISTS(
				SELECT 1
				  FROM region_start_point
				 WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
				   AND region_sid = v_primary_root_region_sid
		)
	);

	IF v_has_primary_region_sp = 0 THEN
		-- Check the region is under the user's start points.
		SELECT COUNT(*)
		  INTO v_access_allowed
		  FROM (
			SELECT 1
			  FROM dual
			 WHERE EXISTS(
				SELECT 1
				  FROM region
				 WHERE region_sid = in_region_sid
				START WITH region_sid IN (SELECT region_sid FROM csr.region_start_point WHERE user_sid = SYS_CONTEXT('SECURITY','SID'))
				CONNECT BY PRIOR region_sid = parent_sid
			)
		);
		IF v_access_allowed = 0 THEN
			RETURN 'You do not have permission to see this region';
		END IF;
	END IF;

	RETURN INTERNAL_GetRegionPathString(in_region_sid);
END;

PROCEDURE SetTranslation(
	in_region_sid		IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
)
AS
	v_act			security_pkg.T_ACT_ID;
	v_description	region_description.description%TYPE;
BEGIN
	-- NB region_description must have descriptions for ALL customer languages
	v_act := security_pkg.GetACT();
	IF NOT Security_pkg.IsAccessAllowedSID(v_act, in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the region with sid ' ||in_region_sid);
	END IF;
	
	UPDATE region_description
	   SET description = in_translated
	 WHERE region_sid = in_region_sid AND lang = in_lang;
	
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing region description for the language '||in_lang||
			' and the region with sid '||in_region_sid);
	END IF;
END;

PROCEDURE GetTranslations(
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT Security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating translations for the region with sid ' ||in_region_sid);
	END IF;
	
	-- Get the description (thing to be translated), and application the region object belongs to
	OPEN out_cur FOR
		SELECT lang, description translated
		  FROM region_description
	 	 WHERE region_sid = in_region_sid;
END;

PROCEDURE SetPctOwnershipApplies(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_measure_sid_id				IN	security_pkg.T_SID_ID,
	in_pct_ownership_applies		IN	pct_ownership_change.PCT_OWNERSHIP_APPLIES%TYPE
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_calc_job_id					calc_job.calc_job_id%TYPE;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- delete any job about this already
	DELETE FROM pct_ownership_change
	 WHERE started_processing_dtm IS NULL
	   AND measure_sid = in_measure_sid_id;
	
	INSERT INTO pct_ownership_change
		(pct_ownership_change_id, added_dtm, added_by_sid, measure_sid, pct_ownership_applies)
	VALUES
		(pct_ownership_change_id_seq.NEXTVAL, SYSDATE, v_user_sid, in_measure_sid_id, in_pct_ownership_applies);
		
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- queue a job for the change
	stored_calc_datasource_pkg.GetOrCreateCalcJob(
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_calc_job_type			=> stored_calc_datasource_pkg.CALC_JOB_TYPE_PCT_OWNERSHIP,
		in_scenario_run_sid			=> NULL,
		in_start_dtm				=> v_calc_start_dtm,
		in_end_dtm					=> v_calc_end_dtm,
		in_full_recompute			=> 0,
		in_delay_publish_scenario	=> 0,
		out_calc_job_id				=> v_calc_job_id
	);
END;


PROCEDURE ApplyRegionPctChange(
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	val.period_start_dtm%TYPE,
	in_end_dtm					IN	val.period_end_dtm%TYPE
)
AS
	v_val_id					val.val_id%TYPE;
	v_update_flags				NUMBER;
	v_sheet_id					security_pkg.T_SID_ID;
BEGIN	  
	v_update_flags := indicator_pkg.IND_CASCADE_PCT_OWNERSHIP;

    FOR r IN (
        SELECT val_id, v.ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id, source_id,
               entry_measure_conversion_id, entry_val_number, note,
               v.val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM val_converted v
         WHERE source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
           AND v.region_sid = in_region_sid
           AND (period_start_dtm < in_end_dtm OR in_end_dtm IS NULL)
           AND period_end_dtm > in_start_dtm
    )
    LOOP
        Indicator_Pkg.SetValueWithReasonWithSid(in_user_sid, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
            r.val_number, 
            0,  --flags
            r.source_type_id, r.source_id,
            r.entry_measure_conversion_id, r.entry_val_number, 
            null, -- we just use null for aggr_est_val since we explicitly don't touch aggregated values in this loop
            v_update_flags,
            'Change to percent ownership of region',
            r.note, v_val_id);
    END LOOP;
    -- now fix up delegation values
    -- we don't need to use a stored procedure as there are no fancy recalculations needed
    -- TODO: we could speed this up by joining directly to the pct_ownership table rather than calling the ownership function
    FOR r IN (
        SELECT sv.sheet_value_id, sv.val_number * region_pkg.GetPctOwnership(sv.ind_sid, sv.region_sid, sv.start_dtm) val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM sheet_value_converted sv
         WHERE sv.region_sid = in_region_sid
           AND (sv.start_dtm < in_end_dtm OR in_end_dtm IS NULL)
           AND sv.end_dtm > in_start_dtm
    )
    LOOP
		/* This isn't useful as this function is private and only ever called by scrag (via ProcessPctOwnershipChange)
		v_sheet_id := sheet_pkg.GetSheetIdForSheetValueId(r.sheet_value_id);
		IF sheet_pkg.SheetIsReadOnly(v_sheet_id) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || v_sheet_id || 'is read only');
		END IF;*/
		
        UPDATE sheet_value 
           SET val_number = r.val_number 
         WHERE sheet_value_id = r.sheet_value_id; -- we can't use rowid because sheet_value_converted is not a key-preserved join
    END LOOP;
END;


PROCEDURE ApplyMeasurePctChange(
	in_user_sid					IN	security_pkg.T_SID_ID,
	in_measure_sid_id			IN	security_pkg.T_SID_ID,
	in_pct_ownership_applies 	IN  measure.pct_ownership_applies%TYPE
)
AS
	v_val_id					val.val_id%TYPE;
	v_update_flags				NUMBER;
	v_sheet_id					security_pkg.T_SID_ID;
BEGIN
	v_update_flags := indicator_pkg.IND_CASCADE_PCT_OWNERSHIP;

    -- update all base values
    -- we have to do this after we've altered the measure or it'll base the pct_ownership calc on the old pct_ownership_applies values
    FOR r IN (
        SELECT val_id, v.ind_sid, region_sid, period_start_dtm, period_end_dtm, source_type_id, source_id,
               entry_measure_conversion_id, entry_val_number, note,
               v.val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM val_converted v, ind i
         WHERE source_type_id != csr_data_pkg.SOURCE_TYPE_AGGREGATOR
           AND v.ind_sid = i.ind_sid
           AND i.measure_sid = in_measure_sid_id
    )
    LOOP
        Indicator_Pkg.SetValueWithReasonWithSid(in_user_sid, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
            r.val_number, 
            0,  --flags
            r.source_type_id, r.source_id,
            r.entry_measure_conversion_id, r.entry_val_number, 
            null, -- we just use null for aggr_est_val since we explicitly don't touch aggregated values in this loop
            v_update_flags,
            'Set Percent ownership applies on measure to '||in_pct_ownership_applies,
            r.note, v_val_id);
    END LOOP;
    -- now fix up delegation values
    -- we don't need to use a stored procedure as there are no fancy recalculations needed
    -- TODO: we could speed this up by joining directly to the pct_ownership table rather than calling the ownership function
    FOR r IN (
        SELECT sv.sheet_value_id, sv.val_number * region_pkg.GetPctOwnership(sv.ind_sid, sv.region_sid, sv.start_dtm) val_number -- val_converted derives val_number from entry_val_number in case of pct_ownership
          FROM sheet_value_converted sv, ind i
         WHERE sv.app_sid = i.app_sid
           AND sv.ind_sid = i.ind_sid
           AND i.measure_sid = in_measure_sid_id
    )
    LOOP
		v_sheet_id := sheet_pkg.GetSheetIdForSheetValueId(r.sheet_value_id);
		IF sheet_pkg.SheetIsReadOnly(v_sheet_id) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied, sheet ' || v_sheet_id || 'is read only');
		END IF;
		
        UPDATE sheet_value 
           SET val_number = r.val_number 
         WHERE sheet_value_id = r.sheet_value_id; -- we can't use rowid because sheet_value_converted is not a key-preserved join
    END LOOP;
END;

PROCEDURE ProcessPctOwnership(
	in_app_sid						IN	customer.app_sid%TYPE,
	in_calc_job_id					IN	calc_job.calc_job_id%TYPE
)
AS
    v_pct_ownership_change_Id		pct_ownership_change.pct_ownership_change_Id%TYPE;     
	v_added_by_sid					pct_ownership_change.added_by_sid%TYPE;
	v_measure_sid					pct_ownership_change.measure_sid%TYPE;
	v_pct_ownership_applies			pct_ownership_change.pct_ownership_applies%TYPE;
	v_region_sid					pct_ownership_change.region_sid%TYPE;
	v_start_dtm						pct_ownership_change.start_dtm%TYPE;
	v_end_dtm						pct_ownership_change.end_dtm%TYPE;
	v_pct							pct_ownership_change.pct%TYPE;
	v_started_processing_dtm		pct_ownership_change.started_processing_dtm%TYPE;
	v_app_sid						pct_ownership_change.app_sid%TYPE;
	v_cnt							NUMBER;
	v_processed						NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM pct_ownership_change
	 WHERE app_sid = in_app_sid;
	
	stored_calc_datasource_pkg.RecordProgress(in_calc_job_id, stored_calc_datasource_pkg.PHASE_CALCULATE, 0, v_cnt);
	
	LOOP
	    v_pct_ownership_change_Id := NULL; -- need to clear these down
	    v_measure_sid := NULL; -- need to clear these down
	    v_region_sid := NULL; -- need to clear these down
	    
		UPDATE pct_ownership_change
		   SET started_processing_dtm = SYSDATE
		 WHERE started_processing_dtm IS NULL
		   AND app_sid = in_app_sid
		   AND ROWNUM = 1
     RETURNING app_sid, pct_ownership_change_id, added_by_sid, measure_sid, pct_ownership_applies,
			   region_sid, start_dtm, end_dtm, pct, started_processing_dtm 
		  INTO v_app_sid, v_pct_ownership_change_id, v_added_by_sid, v_measure_sid, v_pct_ownership_applies,
		   	   v_region_sid, v_start_dtm, v_end_dtm, v_pct, v_started_processing_dtm;
		--COMMIT; -- commit as fast as possible to reduce lock contention
		
		EXIT WHEN v_pct_ownership_change_id IS NULL;
	
		IF v_measure_sid IS NOT NULL THEN
			ApplyMeasurePctChange(v_added_by_sid, v_measure_sid, v_pct_ownership_applies);
		ELSIF v_region_sid IS NOT NULL THEN 
			ApplyRegionPctChange(v_added_by_sid, v_region_sid, v_start_dtm, v_end_dtm);
		END IF;

		-- delete our job
		DELETE FROM pct_ownership_change
		 WHERE pct_ownership_change_id = v_pct_ownership_change_id;
		--COMMIT; -- more committing
		
		stored_calc_datasource_pkg.RecordProgress(in_calc_job_id, v_processed);		
	END LOOP;
END;


-- setting to null = delete
-- TODO: if a change has been made, then we need
-- to go and recalculate things?
PROCEDURE UNSEC_SetPctOwnership(
    in_act_id     	 		IN  security_pkg.T_ACT_ID,	   
    in_region_sid   	    IN	security_pkg.T_SID_ID,
    in_start_dtm			IN	date,
    in_pct          		IN	pct_ownership.pct%TYPE
)
IS	    
    v_count		NUMBER(10);
	CURSOR c_pre IS
	   	SELECT start_dtm, end_dtm 
		  FROM pct_ownership 
		 WHERE start_dtm <= in_start_dtm
           AND region_sid = in_region_sid
         ORDER BY start_dtm desc
           FOR UPDATE;
    r_pre	c_pre%ROWTYPE;
	CURSOR c_post IS
	   	SELECT start_dtm, end_dtm 
		  FROM pct_ownership 
		 WHERE start_dtm > in_start_dtm
           AND region_sid = in_region_sid
         ORDER BY start_dtm asc
           FOR UPDATE;
    r_post	c_post%ROWTYPE;
    v_end_dtm	DATE;
    v_user_sid	security_pkg.T_SID_ID;
    v_app_sid	security_pkg.T_SID_ID;
    CURSOR c_lock IS
    	SELECT start_dtm, end_dtm
    	  FROM pct_ownership_change
    	 WHERE region_sid = in_region_sid 
    	   AND started_processing_dtm IS NULL
    	   FOR UPDATE;
	v_calc_job_id					calc_job.calc_job_id%TYPE;
	v_found							BOOLEAN;
	v_calc_start_dtm				customer.calc_start_dtm%TYPE;
	v_calc_end_dtm					customer.calc_end_dtm%TYPE;
BEGIN
    v_end_dtm := null;
	OPEN c_pre;
   	FETCH c_pre INTO r_pre;
   	v_found := c_pre%FOUND; 
	IF v_found THEN
    	IF r_pre.start_dtm = in_start_dtm THEN
        	DELETE FROM pct_ownership
             WHERE CURRENT OF c_pre;
        ELSE
	    	UPDATE pct_ownership
	           SET end_dtm = in_start_dtm 
	         WHERE CURRENT OF c_pre;
        END IF;
    END IF; 
	CLOSE c_pre;
   	
	OPEN c_post;
   	FETCH c_post INTO r_post;
   	v_found := c_post%FOUND;
    CLOSE c_post;
	IF v_found THEN
        v_end_dtm := r_post.start_dtm;
    END IF; 
    IF in_pct IS NULL THEN
    	UPDATE pct_ownership
           SET end_dtm = v_end_dtm
         WHERE start_dtm <= in_start_dtm
		   AND end_dtm = in_start_dtm
           AND region_sid = in_region_sid;
    ELSE
	    INSERT INTO pct_ownership
	    	(region_sid, start_dtm, end_dtm, pct)
	    VALUES	
	    	(in_region_sid, in_start_dtm, v_end_dtm, in_pct);
    END IF;
    
    SELECT app_sid
      INTO v_app_sid
      FROM region
     WHERE region_sid = in_region_sid;
      
	-- write row into audit log
	IF v_end_dtm IS NULL THEN    
	    csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_region_sid,
			'Set percentage ownership from {0} onwards to {1}%', TO_CHAR(in_start_dtm, 'DD-MON-YYYY'), in_pct*100);
	ELSE
	    csr_data_pkg.WriteAuditLogEntry(in_act_id, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_region_sid,
			'Set percentage ownership from {0} to {1} to {2}%', TO_CHAR(in_start_dtm, 'DD-MON-YYYY'), TO_CHAR(v_end_dtm, 'DD-MON-YYYY'), in_pct*100);
	END IF;
	
	-- write row into change job table
	user_pkg.GetSid(in_act_id, v_user_sid);

	-- lock all rows where region_Sid = in_region_sid
	OPEN c_lock;
	
	-- delete anything we cover	completely
	DELETE FROM pct_ownership_change
	 WHERE start_dtm >= in_start_dtm
	   AND (end_dtm <= v_end_dtm 
	   		OR v_end_dtm IS NULL)
	   AND region_sid = in_region_sid
	   AND started_processing_dtm IS NULL;
	
	-- if we don't go on forever, then tidy up things that intersect with our end date   
	IF v_end_dtm IS NOT NULL THEN
		UPDATE pct_ownership_change
		   SET start_dtm = v_end_dtm
		 WHERE start_dtm < v_end_dtm
		   AND end_dtm > in_start_dtm 
	   	   AND region_sid = in_region_sid
	   	   AND started_processing_dtm IS NULL;
	END IF;
	
	-- tidy up things that intersect with out start date
	UPDATE pct_ownership_change
	   SET end_dtm = in_start_dtm
	 WHERE (end_dtm > in_start_dtm OR end_dtm IS NULL)
	   AND start_dtm <= in_start_dtm
	   AND region_sid = in_region_sid
	   AND started_processing_dtm IS NULL;
	
    INSERT INTO pct_ownership_change
    	(pct_ownership_change_id, added_dtm, added_by_sid, region_sid, start_dtm, end_dtm, pct)
    VALUES
    	(pct_ownership_change_id_seq.NEXTVAL, SYSDATE, v_user_sid, in_region_sid, in_start_dtm, v_end_dtm, in_pct);

	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_calc_start_dtm, v_calc_end_dtm
	  FROM customer;

	-- queue a job for the change
	stored_calc_datasource_pkg.GetOrCreateCalcJob(
		in_app_sid					=> SYS_CONTEXT('SECURITY', 'APP'),
		in_calc_job_type			=> stored_calc_datasource_pkg.CALC_JOB_TYPE_PCT_OWNERSHIP,
		in_scenario_run_sid			=> NULL,
		in_start_dtm				=> v_calc_start_dtm,
		in_end_dtm					=> v_calc_end_dtm,
		in_full_recompute			=> 0,
		in_delay_publish_scenario	=> 0,
		out_calc_job_id				=> v_calc_job_id
	);
END;


PROCEDURE SetPctOwnership(
    in_act_id     	 		IN  security_pkg.T_ACT_ID,	   
    in_region_sid   	    IN	security_pkg.T_SID_ID,
    in_start_dtm			IN	date,
    in_pct          		IN	pct_ownership.pct%TYPE
)
AS
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, csr_data_pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering schema');
	END IF;
	
	UNSEC_SetPctOwnership(
		in_act_id => in_act_id,
		in_region_sid => in_region_sid,
		in_start_dtm => in_start_dtm,
		in_pct => in_pct
	);
END;

PROCEDURE GetPctOwnership(
    in_act_id       			IN  security_pkg.T_ACT_ID,
    in_region_sid           	IN	security_pkg.T_SID_ID,
	out_cur						OUT SYS_REFCURSOR
)
IS
	v_measure_sid				security_pkg.T_SID_ID;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||in_region_sid);
	END IF;

	OPEN out_cur FOR
    	SELECT start_dtm, TO_CHAR(start_dtm, 'dd Mon yyyy') start_dtm_fmt,
        	   end_dtm, TO_CHAR(end_dtm-1, 'dd Mon yyyy') end_dtm_fmt,
               pct
          FROM pct_ownership
         WHERE region_sid = in_region_sid;
END;


FUNCTION GetPctOwnership(
    in_ind_sid          IN	security_pkg.T_SID_ID,
    in_region_sid       IN	security_pkg.T_SID_ID,
    in_dtm              IN  date
) RETURN pct_ownership.pct%TYPE
IS
    v_pct_ownership_applies measure.pct_Ownership_applies%TYPE;
    v_pct                   pct_ownership.pct%TYPE;
BEGIN
	BEGIN
		SELECT pct_ownership_applies
		  INTO v_pct_ownership_applies
		  FROM measure m, ind i
		 WHERE i.measure_sid = m.measure_sid
		   AND i.ind_sid = in_ind_sid;
	EXCEPTION
		-- default to 0
		WHEN NO_DATA_FOUND THEN 
			v_pct_ownership_applies := 0;
	END;
    IF v_pct_ownership_applies = 0 THEN
        RETURN 1; -- assume 100% ownership
    END IF;
    
    BEGIN
        SELECT pct
          INTO v_pct
          FROM pct_ownership
         WHERE region_sid = in_region_sid
           AND start_dtm <= in_dtm
           AND NVL(end_dtm, in_dtm + 1) > in_dtm; -- end_dtm is null will always return true
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_pct := 1; -- assume 100% ownership
    END;
    RETURN v_pct;
END;

PROCEDURE GetTreeForMap (
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
) AS
	v_root_sids							security.T_ORDERED_SID_TABLE;
BEGIN
	v_root_sids := ProcessStartPoints(in_act_id, in_parent_sids, 0);
	
	OPEN out_cur FOR
			SELECT r.region_sid, rd.description, r.lookup_key, r.region_ref, r.info_xml
			  FROM region r
			  JOIN region_description rd ON r.app_sid = rd.app_sid
			   AND NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
			   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			 WHERE LEVEL <= in_fetch_depth
		START WITH r.parent_sid IN (SELECT sid_id FROM TABLE(v_root_sids))
		CONNECT BY PRIOR r.app_sid = r.app_sid
			   AND PRIOR r.region_sid = r.parent_sid
		  ORDER BY LEVEL DESC, rd.description;
END;

PROCEDURE GetTreeSinceDate(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
    in_modified_since_dtm			IN	audit_log.audit_date%TYPE,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots			security.T_ORDERED_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
			   r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
			   r.lvl, r.is_leaf, r.region_type, r.active, rt.class_name, 
			   lookup_key, region_ref, disposal_dtm, acquisition_dtm, info_xml, last_modified_dtm,
			   CASE WHEN sr.region_sid IS NULL THEN 1 ELSE 0 END is_primary
		  FROM (
			SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
				   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
				   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
				   r.lookup_key, r.region_ref, r.disposal_dtm, r.acquisition_dtm, r.info_xml, r.last_modified_dtm
			  FROM v$resolved_region_description r
				   START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
				   			   (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
				   			  AND (in_show_inactive = 1 OR r.active = 1)
				   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   			  AND (in_show_inactive = 1 OR r.active = 1)
				   ) r
		  JOIN region_type rt ON r.region_type = rt.region_type
		  LEFT JOIN (
				  SELECT srr.region_sid
					FROM region srr
					LEFT JOIN region_tree srrt ON srrt.region_tree_root_sid = srr.region_sid
				   START WITH srrt.is_primary = 0
				 CONNECT BY PRIOR srr.region_sid = srr.parent_sid
		  ) sr ON sr.region_sid = r.region_sid
		 WHERE r.last_modified_dtm >= in_modified_since_dtm;
END;
	
PROCEDURE GetTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots			security.T_ORDERED_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	-- As the wheel has spun nearly 360 degrees
	-- once again regions are revealed to be laggardly
	-- Joy in spring! Rewrite time is here again!  
	OPEN out_cur FOR
		SELECT sid_id, parent_sid_id, description, link_to_region_sid, lvl, is_leaf, class_name,
			   active, pos, info_xml, flag, acquisition_dtm, disposal_dtm, region_type, region_ref,
			   lookup_key, geo_country, geo_region, geo_city_id, geo_longitude, geo_latitude,
			   geo_type, map_entity, egrid_ref, egrid_ref_overridden, last_modified_dtm, is_primary
		  FROM (
			SELECT /*+ALL_ROWS*/
				   SUBSTR(r.spath, 1, LENGTH(r.spath) - LENGTH(r.region_sid) - 1) pspath,
				   r.spath,
				   r.region_sid sid_id, 
				   r.parent_sid parent_sid_id,
				   rd.description,
				   r.link_to_region_sid,
				   r.lvl, 
				   r.is_leaf, 
				   rt.class_name, 
			  	   -- this pattern is a bit messier than NVL, but it avoids taking properties off the link
			  	   -- in the case that the property is unset on the region -- that's only possible if it's
			  	   -- nullable, but quite a few of the properties are.  They should not be set on the link,
			  	   -- but we don't want to return duff data because we do end up with links with properties.
				   --CASE WHEN rl.region_sid IS NOT NULL THEN rl.name ELSE r.name END name,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.active ELSE r.active END active,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.pos ELSE r.pos END pos,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.info_xml ELSE rx.info_xml END info_xml,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.flag ELSE r.flag END flag,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.acquisition_dtm ELSE r.acquisition_dtm END acquisition_dtm,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.disposal_dtm ELSE r.disposal_dtm END disposal_dtm,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_type ELSE r.region_type END region_type,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.region_ref ELSE r.region_ref END region_ref,
				   r.lookup_key, 
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_country ELSE r.geo_country END geo_country,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_region ELSE r.geo_region END geo_region,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_city_id ELSE r.geo_city_id END geo_city_id,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_longitude ELSE r.geo_longitude END geo_longitude,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_latitude ELSE r.geo_latitude END geo_latitude,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.geo_type ELSE r.geo_type END geo_type,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.map_entity ELSE r.map_entity END map_entity,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref ELSE r.egrid_ref END egrid_ref,
				   CASE WHEN rl.region_sid IS NOT NULL THEN rl.egrid_ref_overridden ELSE r.egrid_ref_overridden END egrid_ref_overridden,
				   -- If either the region or the region link is modified, then the resolved region
				   -- should appear to be modified.  GREATEST returns null if any of its arguments are
				   -- null, so the below ensures that we get the greatest non-null modified date.
				   GREATEST(NVL(r.last_modified_dtm, rl.last_modified_dtm),
						    NVL(rl.last_modified_dtm, r.last_modified_dtm)) last_modified_dtm,
				   CASE WHEN sr.region_sid IS NULL THEN 1 ELSE 0 END is_primary
			  FROM (
				SELECT r.app_sid, r.region_sid, r.link_to_region_sid, r.parent_sid, r.lookup_key,
					   r.region_type, r.region_ref, r.acquisition_dtm, r.disposal_dtm, r.flag,
					   r.pos, r.active, SYS_CONNECT_BY_PATH(r.region_sid, '/') spath,
					   r.geo_country, r.geo_region, r.geo_city_id, r.geo_longitude, r.geo_latitude, r.geo_type,
					   r.map_entity, r.egrid_ref, r.egrid_ref_overridden, r.last_modified_dtm,
					   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf
				  FROM region r
				  LEFT JOIN region rla ON r.link_to_region_sid = rla.region_sid AND r.app_sid = rla.app_sid
				 WHERE level <= in_fetch_depth
					   START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
								   (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
								  AND (in_show_inactive = 1 OR NVL(rla.active, r.active) = 1)
					   CONNECT BY PRIOR r.app_sid = r.app_sid AND
								  PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid AND
								  (in_show_inactive = 1 OR NVL(rla.active, r.active) = 1)
					) r
			  JOIN region rx ON r.region_sid = rx.region_sid
			  LEFT JOIN region rl ON r.link_to_region_sid = rl.region_sid AND r.app_sid = rl.app_sid
			  JOIN region_type rt ON NVL(rl.region_type, r.region_type) = rt.region_type
			  JOIN region_description rd ON NVL(r.link_to_region_sid, r.region_sid) = rd.region_sid
			   AND rd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
			  LEFT JOIN (
				  SELECT srr.region_sid
					FROM region srr
					LEFT JOIN region_tree srrt ON srrt.region_tree_root_sid = srr.region_sid
				   START WITH srrt.is_primary = 0
				 CONNECT BY PRIOR srr.region_sid = srr.parent_sid
			  ) sr ON sr.region_sid = r.region_sid
			  )
		START WITH pspath IS NULL CONNECT BY PRIOR spath = pspath		   
		ORDER SIBLINGS BY 
			REGEXP_SUBSTR(LOWER(description), '^\D*') NULLS FIRST, 
			TO_NUMBER(REGEXP_SUBSTR(LOWER(description), '[0-9]+')) NULLS FIRST, 
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 2))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 3))) NULLS FIRST,
			TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(description), '[0-9]+', 1, 4))) NULLS FIRST,
			LOWER(description), sid_id;
END;

PROCEDURE GetTreeWithSelect( 
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots			security.T_ORDERED_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	OPEN out_cur FOR
		WITH sel AS (
			SELECT '/'||reverse(sys_connect_by_path(reverse(to_char(parent_sid)),'/')) path
			  FROM region rp
			 WHERE (in_include_root = 1 and rp.region_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
				   (in_include_root = 0 and rp.parent_sid IN (SELECT sid_id FROM TABLE(v_roots)))
			 START WITH rp.region_sid IN (
			 	SELECT region_sid
				  FROM region r
				   START WITH region_sid = in_select_sid
				   CONNECT BY PRIOR app_sid = app_sid AND PRIOR parent_sid = region_sid AND (
					   (in_include_root = 1 AND PRIOR region_sid NOT IN (SELECT sid_id FROM TABLE(v_roots))) OR
					   (in_include_root = 0 AND PRIOR parent_sid NOT IN (SELECT sid_id FROM TABLE(v_roots))))
			 )
			 CONNECT BY PRIOR rp.app_sid = rp.app_sid AND PRIOR rp.parent_sid = rp.region_sid
		)
		SELECT /*+ALL_ROWS*/ x.region_sid sid_id, x.parent_sid parent_sid_id, x.description, x.geo_city_id,
			   x.geo_country, x.geo_region, x.geo_longitude, x.geo_latitude, x.geo_type, x.link_to_region_sid,
			   x.lvl, x.is_leaf, x.region_type, x.active, rt.class_name, x.last_modified_dtm
		  FROM (
			SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid, r.last_modified_dtm,
				   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
				   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
             	   sys_connect_by_path(to_char(r.region_sid),'/')||'/' path,
             	   sys_connect_by_path(to_char(r.parent_sid),'/')||'/' ppath          	       
		 	  FROM v$resolved_region_description r
			       START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
			 			       (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
				   			  AND (in_show_inactive = 1 OR r.active = 1)
		 		   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				 		      AND (in_show_inactive = 1 OR r.active = 1)
		 		   ORDER SIBLINGS BY r.description, r.region_sid) x
		  JOIN region_type rt ON x.region_type = rt.region_type
		 WHERE lvl <= in_fetch_depth 
			OR path IN (SELECT path FROM sel) 
			OR ppath IN (SELECT path FROM sel)
		 ORDER BY rn;
END;

-- Note: broken with secondary region trees
PROCEDURE GetTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 		security.T_ORDERED_SID_TABLE;
	v_region_root	security_pkg.T_SID_ID;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	SELECT region_root_sid
	  INTO v_region_root
	  FROM customer
	 WHERE app_sid = in_app_sid;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ x.region_sid sid_id, x.parent_sid parent_sid_id, x.description, x.geo_city_id,
			   x.geo_country, x.geo_region, x.geo_longitude, x.geo_latitude, x.geo_type, x.link_to_region_sid,
			   x.lvl, x.is_leaf, x.region_type, x.active, rt.class_name,
			   lookup_key, region_ref, disposal_dtm, acquisition_dtm, info_xml, last_modified_dtm,
			   CASE WHEN sr.region_sid IS NULL THEN 1 ELSE 0 END is_primary
		  FROM (
			SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
				   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
				   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
				   r.lookup_key, r.region_ref, r.disposal_dtm, r.acquisition_dtm, r.info_xml, r.last_modified_dtm,
             	   sys_connect_by_path(to_char(r.region_sid),'/')||'/' path,
             	   sys_connect_by_path(to_char(r.parent_sid),'/')||'/' ppath             	       
		 	  FROM v$resolved_region_description r
		  	 	   START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
			 			       (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
				   			  AND (in_show_inactive = 1 OR r.active = 1)
				   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   			  AND (in_show_inactive = 1 OR r.active = 1)
		  	 	   ORDER SIBLINGS BY r.description, r.region_sid) x
		  JOIN region_type rt ON x.region_type = rt.region_type
		  LEFT JOIN (
				  SELECT srr.region_sid
					FROM region srr
					LEFT JOIN region_tree srrt ON srrt.region_tree_root_sid = srr.region_sid
				   START WITH srrt.is_primary = 0
				 CONNECT BY PRIOR srr.region_sid = srr.parent_sid
		  ) sr ON sr.region_sid = x.region_sid
		 WHERE x.region_sid IN (
		  	SELECT r.region_sid 
		  	  FROM region r, (
					SELECT r2.region_sid, r1.region_sid parent_sid
					  FROM region r1, region r2
					 WHERE r1.link_to_region_sid = r2.parent_sid AND r2.app_sid = in_app_sid AND 
					 	   r2.app_sid = in_app_sid AND r1.app_sid = r2.app_sid
					 UNION ALL
					SELECT region_sid, parent_sid
					  FROM region
					  	   START WITH app_sid = in_app_sid AND region_sid = v_region_root
					  	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid) rp
			  WHERE r.region_sid = rp.region_sid
					START WITH r.region_sid IN (SELECT region_sid 
					       					      FROM region_description
					       				         WHERE (
														LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%' 
														OR UPPER(region_ref) = UPPER(in_search_phrase) -- exact match
														OR UPPER(lookup_key) = UPPER(in_search_phrase) -- exact match
													)
					       				           AND app_sid = in_app_sid
					       				           AND lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en'))
			        CONNECT BY PRIOR app_sid = app_sid AND PRIOR rp.parent_sid = r.region_sid)
		 ORDER BY rn;
END;

PROCEDURE GetTreeTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,	
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 		security.T_ORDERED_SID_TABLE;
	v_region_root	security_pkg.T_SID_ID;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	SELECT region_root_sid
	  INTO v_region_root
	  FROM customer
	 WHERE app_sid = in_app_sid;

	OPEN out_cur FOR
		--Get region tree based on whether to get inactive and whether or not to include root.
		SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
			   r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
			   r.lvl, r.is_leaf, r.region_type, r.active, rt.class_name	
		  FROM ( 
			SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
				   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
				   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type
		  	  FROM v$resolved_region_description r
		  	       START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
			 			       (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
				   			  AND (in_show_inactive = 1 OR r.active = 1)
				   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
							  AND (in_show_inactive = 1 OR r.active = 1)
		  	 	   ORDER SIBLINGS BY r.description, r.region_sid) r
		  JOIN region_type rt ON r.region_type = rt.region_type
		 --Filter based on region tags and search phrase
		 WHERE EXISTS (
			SELECT null
			  FROM
				(
				  --Collect all the region sids with the tag and/or Search phase as a separate query as oracle cannot seem to handle having a complex query in the start with
				  WITH selected_regs AS (
						--Collect all regions that have all tags
						SELECT region_sid 
						FROM
							(SELECT region_sid
							FROM (
							SELECT rt.region_sid, st.set_id
								FROM search_tag st
								JOIN region_tag rt ON st.tag_id = rt.tag_id
							UNION -- effectively does distinct
							SELECT nnr.region_sid, st.set_id
								FROM region_tag rt -- find regions where we link directly in secondary tree
								JOIN region nnr ON nnr.link_to_region_sid = rt.region_sid AND nnr.app_sid = rt.app_sid
								JOIN search_tag st ON st.tag_id = rt.tag_id
							)
							GROUP BY region_sid
							HAVING COUNT(*) = in_tag_group_count)
						UNION ALL
						--Collect all regions that have the search phrase
						SELECT region_sid
						FROM v$region
						WHERE app_sid = in_app_sid
						AND (in_search_phrase != ''
							AND (
								LOWER(description) LIKE '%'||LOWER(in_search_phrase)||'%'
								OR UPPER(region_ref) = UPPER(in_search_phrase) -- exact match
								OR UPPER(lookup_key) = UPPER(in_search_phrase) -- exact match
						))
					)
				--Find all regions with the tags and their children 
				SELECT nr.region_sid
				  FROM region nr
				  JOIN (
						--Find the child regions in the main tree of the link region based on their linked to region
						SELECT r2.region_sid, r1.region_sid parent_sid
						  FROM region r1, region r2
						 WHERE r1.link_to_region_sid = r2.parent_sid AND r2.app_sid = in_app_sid AND
							 r2.app_sid = in_app_sid AND r1.app_sid = r2.app_sid
						 UNION ALL
						--Find the child regions of regions in the main tree.
						SELECT region_sid, parent_sid
						  FROM region
						 START WITH app_sid = in_app_sid AND region_sid = v_region_root
					   CONNECT BY PRIOR app_sid = app_sid AND PRIOR region_sid = parent_sid) rp
					ON nr.region_sid = rp.region_sid
				 START WITH nr.region_sid IN (SELECT region_sid FROM selected_regs)
			   CONNECT BY PRIOR app_sid = app_sid AND PRIOR rp.parent_sid = nr.region_sid)
			WHERE region_sid = r.region_sid)
		ORDER BY rn;
END;

PROCEDURE GetListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	in_class_filter					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 				security.T_ORDERED_SID_TABLE;
	v_class_filter			security_pkg.T_VARCHAR2_ARRAY;
	t_class_filter			security.T_VARCHAR2_TABLE;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);

	v_class_filter := in_class_filter;
	IF v_class_filter.COUNT = 0 OR (v_class_filter.COUNT = 1 AND v_class_filter(v_class_filter.FIRST) IS NULL) THEN
		SELECT DISTINCT class_name
		  BULK COLLECT INTO v_class_filter
		  FROM region_type rt, customer_region_type crt
		 WHERE rt.region_type = crt.region_type;
	END IF;
	
	t_class_filter := security_pkg.Varchar2ArrayToTable(v_class_filter);

	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT *
		  FROM (
			SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
				   r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
				   r.lvl, r.is_leaf, r.region_type, r.active, r.path, rt.class_name	
			  FROM (
			  	-- this pointless wrapper works around a bug in 10.0.2.0.4 (fixed in .5) where the where
			  	-- clause causes no results to be returned if inline with the CONNECT BY
			  	SELECT r.region_sid, r.parent_sid, r.description, r.geo_city_id,
				       r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
				       r.lvl, r.is_leaf, r.rn, r.region_type, r.active, r.path
				  FROM (
					SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
						   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
						   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
						   SYS_CONNECT_BY_PATH(replace(r.description, chr(1), '_'), '') path,
						   r.lookup_key, r.region_ref
				  	  FROM v$resolved_region_description r
						   START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
									   (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
									  AND (in_show_inactive = 1 OR r.active = 1)
						   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid AND
									  (in_show_inactive = 1 OR r.active = 1)
				  ) r
				 WHERE LOWER(r.description) LIKE '%'||LOWER(in_search_phrase)||'%'
					OR LOWER(r.region_ref) = LOWER(in_search_phrase) -- exact match
					OR LOWER(r.lookup_key) = LOWER(in_search_phrase) -- exact match
					OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND r.region_sid = TO_NUMBER(in_search_phrase))
			  ) r
			  JOIN region_type rt ON r.region_type = rt.region_type
			  JOIN TABLE(t_class_filter) cf ON LOWER(rt.class_name) = LOWER(cf.value)
			 ORDER BY 
				REGEXP_SUBSTR(LOWER(path), '^\D*') NULLS FIRST, 
				TO_NUMBER(REGEXP_SUBSTR(LOWER(path), '[0-9]+')) NULLS FIRST, 
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(path), '[0-9]+', 1, 2))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(path), '[0-9]+', 1, 3))) NULLS FIRST,
				TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(path), '[0-9]+', 1, 4))) NULLS FIRST,
				LOWER(path), sid_id
			 )
		 WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetListTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	in_class_filter					IN	security_pkg.T_VARCHAR2_ARRAY,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 				security.T_ORDERED_SID_TABLE;
	v_class_filter			security_pkg.T_VARCHAR2_ARRAY;
	t_class_filter			security.T_VARCHAR2_TABLE;
	v_using_class_filter	NUMBER;
BEGIN
	v_roots := ProcessStartPoints(in_act_id, in_parent_sids, in_include_root);
	
	v_using_class_filter := 1;
	v_class_filter := in_class_filter;
	IF v_class_filter.COUNT = 0 OR (v_class_filter.COUNT = 1 AND v_class_filter(v_class_filter.FIRST) IS NULL) THEN
		v_using_class_filter := 0;
		SELECT class_name
		  BULK COLLECT INTO v_class_filter
		  FROM region_type rt, customer_region_type crt
		 WHERE rt.region_type = crt.region_type;
	END IF;
	
	t_class_filter := security_pkg.Varchar2ArrayToTable(v_class_filter);
	
	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (
			SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
				   r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
				   r.lvl, r.is_leaf, r.region_type, r.active, rt.class_name, r.path
			  FROM (
			  	-- this pointless wrapper works around a bug in 10.0.2.0.4 (fixed in .5) where the where
			  	-- clause causes no results to be returned if inline with the CONNECT BY
			  	SELECT r.region_sid, r.parent_sid, r.description, r.geo_city_id,
				       r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
				       r.lvl, r.is_leaf, r.rn, r.region_type, r.active, r.path
			  	  FROM (
					SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
						   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
						   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
						   SYS_CONNECT_BY_PATH(replace(r.description, chr(1), '_'), '') path,
						   r.lookup_key, r.region_ref
				  	  FROM v$resolved_region_description r
						   START WITH ((in_include_root = 0 AND r.parent_sid IN (SELECT sid_Id FROM TABLE(v_roots))) OR 
									   (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots))))
									  AND (in_show_inactive = 1 OR r.active = 1)
						   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
									  AND (in_show_inactive = 1 OR r.active = 1)
						   ORDER SIBLINGS BY 
							REGEXP_SUBSTR(LOWER(r.description), '^\D*') NULLS FIRST, 
							TO_NUMBER(REGEXP_SUBSTR(LOWER(r.description), '[0-9]+')) NULLS FIRST, 
							TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(r.description), '[0-9]+', 1, 2))) NULLS FIRST,
							TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(r.description), '[0-9]+', 1, 3))) NULLS FIRST,
							TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(r.description), '[0-9]+', 1, 4))) NULLS FIRST,
							LOWER(r.description), r.region_sid) r
				 WHERE (LOWER(r.description) LIKE '%'||LOWER(in_search_phrase)||'%'
						OR UPPER(r.region_ref) = UPPER(in_search_phrase) -- exact match
						OR UPPER(r.lookup_key) = UPPER(in_search_phrase) -- exact match
						)) r
		 	  JOIN region_type rt ON r.region_type = rt.region_type
			  JOIN TABLE(t_class_filter) cf ON LOWER(rt.class_name) = LOWER(cf.value)	      		
			 WHERE region_sid IN (
		               SELECT region_sid
		                 FROM (
							SELECT rt.region_sid, st.set_id
							  FROM search_tag st
							  JOIN region_tag rt ON st.tag_id = rt.tag_id
							 UNION -- effectively does distinct
							SELECT r.region_sid, st.set_id
							  FROM region_tag rt -- find regions where we link directly in secondary tree
							  JOIN region r ON r.link_to_region_sid = rt.region_sid AND r.app_sid = rt.app_sid
							  JOIN search_tag st ON st.tag_id = rt.tag_id
		                 )
		                GROUP BY region_sid
		               HAVING count(*) = in_tag_group_count
		          )
	      		ORDER BY r.rn
	      ) WHERE rownum <= in_fetch_limit;
END;

PROCEDURE GetDescendants(
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN	NUMBER,
	in_region_type_filter			IN	region.region_type%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_roots 						security.T_ORDERED_SID_TABLE;
BEGIN
	v_roots := ProcessStartPoints(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sids, in_include_root);

	-- ************* N.B. that's a literal 0x1 character in there, not a space **************
	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ r.region_sid sid_id, r.parent_sid parent_sid_id, r.description, r.geo_city_id,
			   r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type, r.link_to_region_sid,
			   r.lvl, r.is_leaf, r.region_type, r.active, rt.class_name	
		  FROM ( 
			SELECT r.region_sid, r.description, r.link_to_region_sid, r.parent_sid,
				   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, rownum rn, r.active, r.region_type, 
				   r.geo_city_id, r.geo_country, r.geo_region, r.geo_longitude, r.geo_latitude, r.geo_type,
				   r.lookup_key, r.region_ref, r.acquisition_dtm, r.disposal_dtm, r.info_xml,
				   SYS_CONNECT_BY_PATH(replace(r.description, chr(1), '_'), '') path
		  	  FROM v$resolved_region_description r
				   START WITH (in_include_root = 0 AND r.parent_sid IN (SELECT sid_id FROM TABLE(v_roots))) OR 
							  (in_include_root = 1 AND r.region_sid IN (SELECT sid_id FROM TABLE(v_roots)))
				   CONNECT BY PRIOR r.app_sid = r.app_sid AND PRIOR NVL(r.link_to_region_sid, r.region_sid) = r.parent_sid
				   			  AND (in_show_inactive = 1 OR r.active = 1)) r
		  JOIN region_type rt ON r.region_type = rt.region_type
		 WHERE (in_region_type_filter IS NULL OR r.region_type = in_region_type_filter);
END;

PROCEDURE SetExtraInfoValue(
	in_act		    IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_key		    IN	VARCHAR2,		
	in_value	    IN	VARCHAR2
)
AS
	v_path 			VARCHAR2(255) := '/fields/field[@name="'||in_key||'"]';
	v_new_node 		VARCHAR2(1024) := '<field name="'||in_key||'">'||htf.escape_sc(in_value)||'</field>';
	v_app_sid		security_pkg.T_SID_ID;	
	v_old_value	    VARCHAR2(1024);
	v_has_changed	NUMBER(10) := 0;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(in_act, in_region_sid, Csr_Data_Pkg.PERMISSION_ALTER_SCHEMA) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering region');
	END IF;
	
	SELECT EXTRACTVALUE(info_xml, v_path) 
	  INTO v_old_value
	  FROM region 
	 WHERE region_sid = in_region_sid;
	
	IF (v_old_value IS NULL AND in_value IS NOT NULL) 
		OR (v_old_value IS NOT NULL AND in_value IS NULL)
		OR v_old_value <> htf.escape_sc(in_value) THEN
		v_has_changed := 1;
	END IF;
	
	UPDATE REGION
	   SET INFO_XML = 
			CASE
				WHEN info_xml IS NULL THEN
					APPENDCHILDXML(XMLType('<fields/>'), '/fields',  XmlType(v_new_node))
		    	WHEN EXISTSNODE(info_xml, v_path||'/text()') = 1 THEN
		    		UPDATEXML(info_xml, v_path||'/text()', htf.escape_sc(in_value))
		    	WHEN EXISTSNODE(info_xml, v_path) = 1 THEN
		    		UPDATEXML(info_xml, v_path, XmlType(v_new_node))
		    	ELSE
		    		APPENDCHILDXML(info_xml, '/fields', XmlType(v_new_node))
			END,
		   last_modified_dtm = SYSDATE
	WHERE region_sid = in_region_sid
	RETURNING app_sid INTO v_app_sid;
	
	IF v_has_changed = 1 THEN 
		csr_data_pkg.WriteAuditLogEntry(in_act, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, v_app_sid, in_region_sid, 'Set {0} to {1}', in_key, in_value);
	END IF;
END;


PROCEDURE GetGeoTree(
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_root_sid	security_pkg.T_SID_ID;
BEGIN
	SELECT region_root_sid
	  INTO v_root_sid
	  FROM customer 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT(), v_root_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||v_root_sid);
	END IF;

	OPEN out_cur FOR
		SELECT geo_type, geo_country, geo_region, map_entity, egrid_ref, geo_city_id, geo_latitude, geo_longitude, description raw_description, 
			   SYS_CONNECT_BY_PATH(description, ' > ') description, region_sid
		  FROM v$region r
		 START WITH region_sid = v_root_sid AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid;
END;

PROCEDURE GetTreeAtAbsLevel(
	in_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_abs_level	IN	NUMBER,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_root_sid 		security_pkg.T_SID_ID := in_parent_sid;
	v_parent_sid 	security_pkg.T_SID_ID := in_parent_sid;
BEGIN
	-- Putting this in the query below makes Oracle choose some nuts execution plan	
	v_parent_sid := ParseLink(in_parent_sid);
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||v_parent_sid);
	END IF;
	
	-- If the root sid is null then we want to use the real root sid here 
	-- an absolute level value from the tree regardless of the mount point.
	v_root_sid := COALESCE(in_root_sid, region_tree_pkg.GetPrimaryRegionTreeRootSid);

	OPEN out_cur FOR
		SELECT a.lvl abs_level, r.*, rt.class_name
		  FROM (
		    SELECT LEVEL lvl, region_sid sid_id
		      FROM region
		     WHERE LEVEL = DECODE(in_abs_level, -1, LEVEL, in_abs_level)
		       AND CONNECT_BY_ISLEAF = DECODE(in_abs_level, -1, 1, CONNECT_BY_ISLEAF)
		           START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = v_root_sid
		           CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		) a JOIN (
		    SELECT /*+ALL_ROWS*/ region_sid sid_id, description description, link_to_region_sid, 
		    	   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, active, region_type, ROWNUM rn,
		    	   geo_city_id, geo_country, geo_region, geo_longitude, geo_latitude, geo_type
		      FROM v$region
		     	   START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = v_parent_sid
		           CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		           ORDER SIBLINGS BY description, region_sid
		) r ON a.sid_id = r.sid_id
			JOIN region_type rt ON r.region_type = rt.region_type
		 ORDER BY r.rn;
END;

PROCEDURE SearchTreeAtAbsLevel(
	in_root_sid		IN	security_pkg.T_SID_ID,
	in_parent_sid	IN	security_pkg.T_SID_ID,
	in_abs_level	IN	NUMBER,
	in_search		IN	region_description.description%TYPE,
	out_cur			OUT	SYS_REFCURSOR
)
AS
	v_root_sid 		security_pkg.T_SID_ID := in_parent_sid;
	v_parent_sid 	security_pkg.T_SID_ID := in_parent_sid;
BEGIN
	-- Putting this in the query below makes Oracle choose some nuts execution plan	
	v_parent_sid := ParseLink(in_parent_sid);
	
	-- Use real primary root sid
	v_root_sid := COALESCE(in_root_sid, region_tree_pkg.GetPrimaryRegionTreeRootSid);

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_parent_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||v_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT /*+ALL_ROWS*/ a.lvl abs_level, r.*, rt.class_name
		  FROM (
		    SELECT LEVEL lvl, region_sid sid_id
		      FROM region
		     WHERE LEVEL = DECODE(in_abs_level, -1, LEVEL, in_abs_level)
		       AND CONNECT_BY_ISLEAF = DECODE(in_abs_level, -1, 1, CONNECT_BY_ISLEAF)
		           START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = v_root_sid
		           CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		) a JOIN (
		    SELECT region_sid sid_id, description, link_to_region_sid, 
		    	   LEVEL lvl, CONNECT_BY_ISLEAF is_leaf, active, region_type, ROWNUM rn,
		    	   geo_city_id, geo_country, geo_region, geo_longitude, geo_latitude, geo_type
		      FROM v$region
		           START WITH app_sid = SYS_CONTEXT('SECURITY', 'APP') AND region_sid = v_parent_sid
		           CONNECT BY PRIOR app_sid = app_sid AND PRIOR NVL(link_to_region_sid, region_sid) = parent_sid
		           ORDER SIBLINGS BY description, region_sid
		) r ON a.sid_id = r.sid_id
			JOIN region_type rt ON r.region_type = rt.region_type
		 WHERE LOWER(description) LIKE '%'||LOWER(in_search)||'%'
	     ORDER BY r.rn;
END;

-- XXX: Strong recommendation *NOT* to use this. I think Dickie wrote it for shuffling around
-- the region tree for RBSENV who have a lot of regions but it looks the sort of thing that will
-- suffer from bitrot and I'm not sure it's a good idea to have lots of people deciding to do this
-- without knowing how to trigger all the relevant aggregation jobs etc.
PROCEDURE FastMoveRegion(
	in_region_sid		security_pkg.T_SID_ID,
	in_parent_sid		security_pkg.T_SID_ID
)
AS
	v_region_sid		security_pkg.T_SID_ID;
BEGIN
	-- This procedure simply swaps the parent sids in the csr and security tables 
	-- it is then up to the caller to move the region themselves and deal with ACE 
	-- propogation and region tree recalculation issues themselves.

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the region with sid '||in_region_sid);
	END IF;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_parent_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to the region with sid '||in_parent_sid);
	END IF;

	-- Update security table
	UPDATE security.securable_object
	   SET parent_sid_id = in_parent_sid
	 WHERE sid_id = in_region_sid;
	 
	-- Update region table
	UPDATE csr.region
	   SET parent_sid = in_parent_sid, last_modified_dtm = SYSDATE
	WHERE region_sid = in_region_sid;

	-- Remove anything _this_node_ previously inherited
	DELETE FROM region_proc_doc
	 WHERE region_sid IN (
	 	SELECT region_sid 
	 	  FROM region
	 	 	START WITH region_sid = in_region_sid
	 	 	CONNECT BY PRIOR region_sid = parent_sid
	 )
	 AND doc_id IN (
		SELECT doc_id
		  FROM region_proc_doc
		 WHERE region_sid = in_region_sid
		   AND inherited = 1
	);
	
	DELETE FROM region_proc_file
	 WHERE region_sid IN (
	 	SELECT region_sid 
	 	  FROM region
	 	 	START WITH region_sid = in_region_sid
	 	 	CONNECT BY PRIOR region_sid = parent_sid
	 )
	 AND meter_document_id IN (
		SELECT meter_document_id
		  FROM region_proc_file
		 WHERE region_sid = in_region_sid
		   AND inherited = 1
	);

	-- Inherit procedure documents
	INSERT INTO region_proc_doc
		(region_sid, doc_id, inherited)
	  SELECT in_region_sid, doc_id, 1
	    FROM region_proc_doc
	   WHERE region_sid = in_parent_sid;
	
	INSERT INTO region_proc_file
		(region_sid, meter_document_id, inherited)
	  SELECT in_region_sid, meter_document_id, 1
	    FROM region_proc_file
	   WHERE region_sid = in_parent_sid;
	   
	-- remove _inherited_ roles from this node and all it's children
	INTERNAL_RemoveInheritedRoles(in_region_sid);
	 
	-- Inherit roles from our new parent
	INTERNAL_InhertRolesFromParent(in_region_sid);
	
	-- Tell the meter package the region has moved, 
	-- the procedure doesn't act on non-meter type regions
	meter_pkg.OnRegionMoved(in_region_sid);
	meter_alarm_pkg.OnMoveRegion(in_region_sid);
	
END;

PROCEDURE GetDependencies(
	in_act			IN	security_pkg.T_ACT_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_delegations	OUT	SYS_REFCURSOR
)
AS
	v_some_delegs		security.T_SID_TABLE;
BEGIN
	-- This is pretty horrible, but permission checking every delegation is too expensive (minutes if many)
	-- and this query is pretty much going to be run by an admin (since it's called from the edit schema
	-- pages), which means they likely have access to the delegations anyway.
	-- Hence, just get a few delegations then only permission check some of those.  We get more than we
	-- need in the hope of getting something to return if permission is denied.
	SELECT d.delegation_sid
	  BULK COLLECT INTO v_some_delegs
	  FROM delegation d, delegation_region dr, customer c, reporting_period rp
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND d.app_sid = c.app_sid AND d.parent_sid = d.app_sid
	   AND d.app_sid = dr.app_sid AND d.delegation_sid = dr.delegation_sid
	   AND dr.region_sid = in_region_sid
	   AND c.app_sid = d.app_sid
	   AND c.app_sid = rp.app_sid AND c.current_reporting_period_sid = rp.reporting_period_sid
	   AND d.start_dtm < rp.end_dtm
	   AND d.end_dtm > rp.start_dtm
	   AND rownum <= 300;
	   
	OPEN out_delegations FOR
		SELECT /*+ALL_ROWS*/ *
		  FROM (SELECT d.delegation_sid, d.name, d.description, d.start_dtm, d.end_dtm,
		  			   d.period_set_id, d.period_interval_id
				  FROM v$delegation d,
				  	   TABLE(SecurableObject_pkg.GetSIDsWithPermAsTable(in_act, v_some_delegs,
					   		 security_pkg.PERMISSION_READ)) so
				 WHERE d.delegation_sid = so.sid_id
				 ORDER BY LOWER(d.name))
		  WHERE ROWNUM <= 100;
END;



FUNCTION GetRegionTypeName (
	in_region_type			IN	region.region_type%TYPE
) RETURN VARCHAR2
AS
	v_name	region_type.label%TYPE;
BEGIN
	SELECT label
	  INTO v_name
	  FROM region_type
	 WHERE region_type = in_region_type;
	RETURN v_name;
END;

PROCEDURE SetRegionType(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
)
AS
	v_parent_sid			security_pkg.T_SID_ID;
	v_new_region_type		region.region_type%TYPE;
	v_old_region_type		region.region_type%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied writing to region with sid '||in_region_sid);
	END IF;	

	SELECT parent_sid, region_type
	  INTO v_parent_sid, v_old_region_type
	  FROM region
	 WHERE region_sid = in_region_sid;
	 
	IF v_old_region_type != in_region_type THEN 	
		
		v_new_region_type := in_region_type;
		
		-- Meter types require further validation
		IF meter_pkg.IsMeterType(in_region_type) THEN
			v_new_region_type := meter_pkg.ValidMeterType(in_region_sid, v_parent_sid, in_region_type);
		END IF;
		
		-- Update the region type
		UPDATE region
		   SET region_type = in_region_type,
			   last_modified_dtm = SYSDATE
		 WHERE region_sid = in_region_sid;
		
		-- Audit the change
		csr_data_pkg.WriteAuditLogEntry(security_pkg.GetACT, csr_data_pkg.AUDIT_TYPE_CHANGE_SCHEMA, security_pkg.GetAPP, in_region_sid, 
			'Region type changed from "{0}" to "{1}"', GetRegionTypeName(v_old_region_type), GetRegionTypeName(in_region_type));
		
		ApplyDynamicPlans(in_region_sid, 'Region type changed');
	END IF;
END;


PROCEDURE GetRegionTypes (
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT rt.region_type, rt.label
		  FROM region_type rt, customer_region_type crt
		 WHERE crt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rt.region_type = crt.region_type
		   -- Used for drop-down, don't show "Root" type
		   AND NOT rt.region_type = csr_data_pkg.REGION_TYPE_ROOT
		   	ORDER BY rt.region_type
		;
END;

PROCEDURE GetAllEGrids(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT egrid_ref, egrid_ref || ' - ' || name name
		  FROM egrid
		 ORDER BY name;
END;

FUNCTION GetRegionDescription(
	in_region_sid		IN security_pkg.T_SID_ID
) RETURN region_description.description%type
AS
	v_description			region_description.description%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	SELECT description
	  INTO v_description
	  FROM v$region
	 WHERE region_sid = in_region_sid;
	
	RETURN v_description;
END;

PROCEDURE GetRegionDescriptions(
	in_region_sids			IN security_pkg.T_SID_IDS,
	out_region_desc_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sid_table			security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
	v_region_sid_table_allowed	security.T_SID_TABLE := security.T_SID_TABLE();
	v_region_sid_list_allowed	security_pkg.T_SID_IDS;
BEGIN
	FOR r IN (
		SELECT column_value
		  FROM TABLE(v_region_sid_table)
	)
	LOOP
		IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), r.column_value, security_pkg.PERMISSION_READ) THEN
			v_region_sid_table_allowed.extend();
			v_region_sid_table_allowed(v_region_sid_table_allowed.COUNT) := r.column_value;
		END IF;
	END LOOP;

	SELECT column_value
	  BULK COLLECT INTO v_region_sid_list_allowed
	  FROM TABLE(v_region_sid_table_allowed);

	GetRegionDescriptions_UNSEC(v_region_sid_list_allowed, out_region_desc_cur);
END;

PROCEDURE GetRegionDescriptions_UNSEC(
	in_region_sids			IN security_pkg.T_SID_IDS,
	out_region_desc_cur		OUT	SYS_REFCURSOR
)
AS
	v_region_sid_table		security.T_SID_TABLE := security_pkg.SidArrayToTable(in_region_sids);
BEGIN
	OPEN out_region_desc_cur FOR
		SELECT vr.region_sid, vr.description
		  FROM v$region vr
		  JOIN TABLE(v_region_sid_table) rs
		    ON vr.region_sid = rs.column_value;
END;

PROCEDURE CopyValues(
	in_from_region_sid	IN	security_pkg.T_SID_ID,
	in_new_region_sid	IN	security_pkg.T_SID_ID,
	in_period_start_dtm	IN	DATE 			DEFAULT NULL,
	in_period_end_dtm	IN	DATE 			DEFAULT NULL,
	in_reason			IN	VARCHAR2		DEFAULT NULL,
	in_move				IN	NUMBER			DEFAULT 0
)
AS
	v_val_id			val.val_id%TYPE;
	v_file_uploads		security_pkg.T_SID_IDS;
	v_cnt				NUMBER(10) := 0;
	v_reason			VARCHAR2(1000);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_from_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region with sid '||in_from_region_sid);
	END IF;
	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_new_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the region with sid '||in_new_region_sid);
	END IF;
	
	IF in_reason IS NULL THEN 
		IF in_move = 1 THEN 
			v_reason := 'Moved';
		ELSE
			v_reason := 'Copied';
		END IF;
	ELSE
		v_reason := in_reason;
	END IF;
	FOR r IN (
		SELECT v.changed_by_sid user_sid, in_new_region_sid region_sid, v.ind_sid, v.period_start_dtm, v.period_end_dtm,
			   v.val_number, v.flags, v.source_type_id, v.source_id, v.entry_measure_conversion_id,
			   v.entry_val_number, v.error_code, v.note, v.val_id
		  FROM val_converted v
		 WHERE v.region_sid = in_from_region_sid
		   AND v.source_type_id != 5
           AND (in_period_start_dtm IS NULL OR v.period_start_dtm >= in_period_start_dtm) 
           AND (in_period_end_dtm IS NULL OR v.period_end_dtm <= in_period_end_dtm)
	)
	LOOP	
		v_cnt := v_cnt + 1;
        v_file_uploads.delete;
        
        SELECT file_upload_sid
          BULK COLLECT INTO v_file_uploads
          FROM val_file
         WHERE val_id = r.val_id;
		
		indicator_pkg.SetValueWithReasonWithSid(r.user_sid, r.ind_sid, r.region_sid, r.period_start_dtm, r.period_end_dtm, 
			  r.val_number, r.flags, r.source_type_id, r.source_id, r.entry_measure_conversion_id,
			  r.entry_val_number, r.error_code, 0, v_reason, r.note, 1, v_file_uploads, v_val_id);
		
		IF in_move = 1 THEN
			indicator_pkg.DeleteVal(SYS_CONTEXT('SECURITY','ACT'), r.val_id, v_reason);
		END IF;
	END LOOP;
END;

FUNCTION ConcatRegionTags(
	in_region_sid		IN	security_pkg.T_SID_ID
) RETURN VARCHAR2
IS
	v_item				VARCHAR2(1024) := '';
	v_sep				VARCHAR2(2) := '';
	v_previous_group	tag_group_description.name%TYPE := 'any old junk';
	v_add 				VARCHAR2(1024);
BEGIN
	FOR r IN (
		SELECT tg.name groupName, t.tag tagName
		  FROM region_tag rt
		  JOIN v$tag t ON rt.tag_id = t.tag_id
		  JOIN tag_group_member tgm ON tgm.tag_id = t.tag_id
		  JOIN v$tag_group tg ON tg.tag_group_id = tgm.tag_group_id
		 WHERE rt.region_sid = in_region_sid
		 ORDER BY tg.name, t.tag
	)
	LOOP
		v_add := v_sep;
		IF r.groupName != v_previous_group THEN
			v_add := v_sep || r.groupName || ': ';
		END IF;
		v_add := v_add || r.tagName;
		
		IF LENGTHB(v_item || v_add)<1020 THEN
			v_item := v_item || v_add;
		ELSE
			v_item := v_item || '...';
			EXIT;
		END IF;
		
		v_sep := ', ';
		v_previous_group := r.groupName;
	END LOOP;
	RETURN v_item;
END;

/**
 * Update a region
 *
 * @param	in_act_id				Access token
 * @param	in_region_sid			The region to update
 * @param	in_description			The new region description
 * @param	in_active				Active? (1 = active / 0 = inactive)
 * @param	in_pos					Position
 * @param	in_geo_type				Geo Type
 * @param	in_info_xml				Region Info
 * @param	in_geo_country			Geo Country
 * @param	in_geo_region			Geo Region
 * @param	in_geo_city				Geo City
 * @param	in_map_entity			Map Entity
 * @param	in_egrid_ref			EGrid Reference
 * @param	in_region_ref			Region Reference
 * @param	in_acquisition_dtm		Acquisition Date
 * @param	in_region_type			Region Type
 */
PROCEDURE AmendRegion(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_description					IN	region_description.description%TYPE,
	in_active						IN	region.active%TYPE,
	in_pos							IN	region.pos%TYPE,
	in_geo_type						IN	region.geo_type%TYPE,
	in_info_xml						IN	region.info_xml%TYPE,
	in_geo_country					IN	region.geo_country%TYPE,
	in_geo_region					IN	region.geo_region%TYPE,
	in_geo_city						IN	region.geo_city_id%TYPE,
	in_map_entity					IN	region.map_entity%TYPE,
	in_egrid_ref					IN	region.egrid_ref%TYPE,
	in_region_ref					IN	region.region_ref%TYPE,
	in_acquisition_dtm				IN	region.acquisition_dtm%TYPE DEFAULT NULL,	
	in_region_type					IN	region.region_type%TYPE	DEFAULT csr_data_pkg.REGION_TYPE_NORMAL
)
AS
	v_disposal_dtm					region.disposal_dtm%TYPE DEFAULT NULL;	
BEGIN

	IF region_pkg.GetRegionIsSystemManaged(in_region_sid => in_region_sid) = 1 THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_SYSTEM_MANAGED_REGION_UPDATE, 'Cannot update system managed regions');
	END IF;

	-- if active = 0 then get the previously saved disposal date on pop up
	IF in_active = 0 THEN
		SELECT disposal_dtm INTO v_disposal_dtm
		  FROM region
		 WHERE region_sid = in_region_sid;
	END IF;
	
	AmendRegion(in_act_id, in_region_sid, in_description, in_active, in_pos,
		in_geo_type, in_info_xml, in_geo_country, in_geo_region, in_geo_city,
		in_map_entity, in_egrid_ref, in_region_ref, in_acquisition_dtm, v_disposal_dtm, in_region_type
	);
END;

PROCEDURE SetRegionRef(
	in_region_sid	IN region.region_sid%TYPE,
	in_region_ref	IN region.region_ref%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE region
	   SET region_ref = in_region_ref
	 WHERE region_sid = in_region_sid;
END;

PROCEDURE SetLookupKey(
	in_region_sid	IN region.region_sid%TYPE,
	in_lookup_key	IN region.lookup_key%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	UPDATE region
	   SET lookup_key = in_lookup_key
	 WHERE region_sid = in_region_sid;
END;

FUNCTION IsHiddenOnDelegationForm(
	in_region_sid 		IN	security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM delegation_region
	 WHERE hide_after_dtm IS NOT NULL
	   AND app_sid = security.security_pkg.GetApp
	   AND region_sid = in_region_sid;

	IF v_count > 0 THEN
		RETURN 1;
	END IF;
	RETURN 0;
END;

PROCEDURE FindCommonAncestor(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	out_region_sid		OUT	security_pkg.T_SID_ID
)
AS
	v_regions				security.T_SID_TABLE;
BEGIN
	
	v_regions := security_pkg.SidArrayToTable(in_region_sids);
	
	SELECT region_sid
	  INTO out_region_sid
	  FROM (
        SELECT region_sid, MIN(LEVEL) lvl, COUNT(*) num
		  FROM region
         START WITH region.REGION_SID IN ( SELECT column_value FROM TABLE(v_regions) )
       CONNECT BY PRIOR parent_sid = region_sid AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
         GROUP BY region_sid
        HAVING COUNT(*) = (SELECT COUNT(*) FROM TABLE(v_regions))
		 ORDER BY lvl
	  )
	 WHERE ROWNUM = 1;
END;

PROCEDURE GetAllTranslations(
	in_root_region_sids		IN	security.security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid					security.security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	t_root_region_sids			security.T_SID_TABLE;
BEGIN
	t_root_region_sids := security_pkg.SidArrayToTable(in_root_region_sids);

	OPEN out_cur FOR
		WITH rgn AS (
			SELECT app_sid, region_sid, active, link_to_region_sid, lvl, ROWNUM rn
			  FROM (
				SELECT r.app_sid, r.region_sid, r.active, r.link_to_region_sid, LEVEL lvl
				  FROM region r
				  JOIN (
					SELECT app_sid, region_sid, description
					  FROM region_description
					 WHERE app_sid = v_app_sid
					   AND lang = NVL(in_validation_lang, 'en')
				)rd ON r.app_sid = rd.app_sid AND r.region_sid = rd.region_sid
				 WHERE r.app_sid = v_app_sid
				 START WITH r.region_sid IN (SELECT column_value from TABLE(t_root_region_sids))
			   CONNECT BY PRIOR r.region_sid = r.parent_sid
				 ORDER SIBLINGS BY 
					   REGEXP_SUBSTR(LOWER(rd.description), '^\D*') NULLS FIRST, 
					   TO_NUMBER(REGEXP_SUBSTR(LOWER(rd.description), '[0-9]+')) NULLS FIRST, 
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(rd.description), '[0-9]+', 1, 2))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(rd.description), '[0-9]+', 1, 3))) NULLS FIRST,
					   TO_NUMBER(CONCAT('0.', REGEXP_SUBSTR(LOWER(rd.description), '[0-9]+', 1, 4))) NULLS FIRST,
					   LOWER(rd.description), r.region_sid
			)
		)
		SELECT rgn.region_sid sid, rgn.active, rd.description, rd.lang, rgn.lvl so_level,
			   CASE WHEN rd.last_changed_dtm > in_changed_since THEN 1 ELSE 0 END has_changed,
			   CASE WHEN rgn.link_to_region_sid IS NULL THEN 0 ELSE 1 END is_link
		  FROM rgn
		  JOIN aspen2.translation_set ts ON rgn.app_sid = ts.application_sid
		  LEFT JOIN region_description rd ON rgn.app_sid = rd.app_sid AND rgn.region_sid = rd.region_sid AND ts.lang = rd.lang
		 ORDER BY rn,
			   CASE WHEN ts.lang = NVL(in_validation_lang, 'en') THEN 0 ELSE 1 END,
			   LOWER(ts.lang);
END;

PROCEDURE ValidateTranslations(
	in_region_sids			IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_act						security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_region_sid_desc_tbl		T_SID_AND_DESCRIPTION_TABLE := T_SID_AND_DESCRIPTION_TABLE();
BEGIN
	IF in_region_sids.COUNT != in_descriptions.COUNT THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_ARRAY_SIZE_MISMATCH, 'Number of region sids do not match number of descriptions.');
	END IF;
		
	IF in_region_sids.COUNT = 0 THEN
		RETURN;
	END IF;

	v_region_sid_desc_tbl.EXTEND(in_region_sids.COUNT);
	FOR i IN 1..in_region_sids.COUNT
	LOOP
		v_region_sid_desc_tbl(i) := T_SID_AND_DESCRIPTION_ROW(i, in_region_sids(i), in_descriptions(i));
	END LOOP;

	OPEN out_cur FOR
		SELECT rd.region_sid sid,
			   CASE rd.description WHEN rdt.description THEN 0 ELSE 1 END has_changed,
			   region_pkg.GetRegionIsSystemManaged(in_region_sid => rd.region_sid) is_system_managed,
			   security.security_pkg.SQL_IsAccessAllowedSID(v_act, rd.region_sid, security_pkg.PERMISSION_WRITE) can_write
		  FROM region_description rd
		  JOIN TABLE(v_region_sid_desc_tbl) rdt ON rd.region_sid = rdt.sid_id
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND lang = in_validation_lang;
END;

PROCEDURE GetUsedCountries(
	out_cur							OUT	SYS_REFCURSOR
)
AS
	v_primary_root_region_sid		security_pkg.T_SID_ID := region_tree_pkg.GetPrimaryRegionTreeRootSid;
BEGIN
	OPEN out_cur FOR
		SELECT c.country, c.name, c.latitude, c.longitude, c.area_in_sqkm, c.continent, c.currency, c.iso3, c.is_standard
		  FROM postcode.country c
		 WHERE EXISTS (
			SELECT NULL
			  FROM (
				SELECT DISTINCT geo_country
				  FROM region
				 START WITH region_sid = v_primary_root_region_sid
			   CONNECT BY PRIOR region_sid = parent_sid) r
			 WHERE r.geo_country = c.country
		)
		 ORDER BY c.name;
END;

PROCEDURE GetUsedGeoRegions(
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT r.country, r.region, r.name, r.latitude, r.longitude
		  FROM postcode.region r
		 WHERE EXISTS (
			SELECT NULL
			  FROM region cr
			 WHERE cr.geo_region = r.region
		)
		 ORDER BY r.name;
END;

PROCEDURE GetRegionMapTypes(
	in_filter					IN VARCHAR2,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security needed - fetching global combobox values
	OPEN out_cur FOR
		SELECT region_data_map_id, data_element, description, is_property, is_meter
		  FROM region_data_map
		  JOIN customer c ON app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 WHERE LOWER(description) LIKE LOWER('%'||in_filter||'%')
		   AND (is_property = 0 OR c.property_flow_sid IS NOT NULL)
		   AND (is_meter = 0 OR c.metering_enabled = 1) 
		 ORDER BY region_data_map_id;
END;

PROCEDURE GetRegionMapTypes(
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	GetRegionMapTypes('', out_cur);
END;

PROCEDURE GetRegionMapData(
	in_region_sid					IN	region.region_sid%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_region_sids					security.security_pkg.T_SID_IDS;
BEGIN
	v_region_sids(1) := in_region_sid;
	
	GetRegionMapData(v_region_sids, out_cur);
END;

PROCEDURE GetRegionMapData(
	in_region_sids					IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_t								security.T_SO_TABLE;
BEGIN
	v_t := security.securableObject_pkg.GetSIDsWithPermAsTable(
		SYS_CONTEXT('SECURITY', 'ACT'), 
		security.security_pkg.SidArrayToTable(in_region_sids), 
		security.security_pkg.PERMISSION_READ
	);
	-- no security needed - fetching global combobox values
	OPEN out_cur FOR
		SELECT r.region_sid, region_data_map_id, data_element,
			CASE data_element
				WHEN 'SID'				THEN TO_CHAR(r.region_sid)
				WHEN 'DESC'				THEN TO_CHAR(r.description)
				WHEN 'REF'				THEN TO_CHAR(r.region_ref)
				WHEN 'GEO_CITY'			THEN TO_CHAR(pci.city_name)
				WHEN 'GEO_ST_CODE'		THEN TO_CHAR(r.geo_region)
				WHEN 'GEO_ST_DESC'		THEN TO_CHAR(pr.name)
				WHEN 'GEO_COUNTRY_CODE' THEN TO_CHAR(r.geo_country)
				WHEN 'GEO_COUNTRY_DESC'	THEN TO_CHAR(pc.name)
				WHEN 'MGNT_COMPANY'		THEN TO_CHAR(mc.name)
				WHEN 'FUND'				THEN TO_CHAR(f.name)
				WHEN 'PROP_TYPE'		THEN TO_CHAR(pt.label)
				WHEN 'PROP_SUB_TYPE'	THEN TO_CHAR(pst.label)
				WHEN 'PROP_ADDR1'		THEN TO_CHAR(p.street_addr_1)
				WHEN 'PROP_ADDR2'		THEN TO_CHAR(p.street_addr_2)
				WHEN 'PROP_CITY'		THEN TO_CHAR(p.city)
				WHEN 'PROP_STATE'		THEN TO_CHAR(p.state)
				WHEN 'PROP_ZIP'			THEN TO_CHAR(p.postcode)
				WHEN 'MET_NUM'			THEN TO_CHAR(m.reference)
				WHEN 'MET_TYPE'			THEN TO_CHAR(mst.description)
				ELSE TO_CHAR(r.app_sid)
			END val
		  FROM csr.region_data_map rdm
		 CROSS JOIN csr.v$region r
		  JOIN TABLE(v_t) t ON t.sid_id = r.region_sid
		  LEFT JOIN postcode.country pc ON r.geo_country = pc.country
		  LEFT JOIN postcode.region pr ON r.geo_region = pr.region
		  LEFT JOIN postcode.city pci ON r.geo_city_id = pci.city_id
		  LEFT JOIN csr.property p ON r.region_sid = p.region_sid
		  LEFT JOIN csr.property_type pt ON p.property_type_id = pt.property_type_id
		  LEFT JOIN csr.property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id
		  LEFT JOIN csr.property_fund pf ON r.region_sid = pf.region_sid
		  LEFT JOIN csr.fund f ON pf.fund_id = f.fund_id
		  LEFT JOIN csr.mgmt_company mc ON p.mgmt_company_id = mc.mgmt_company_id
		  LEFT JOIN csr.all_meter m ON m.region_sid = r.region_sid
		  LEFT JOIN csr.meter_source_type mst ON mst.meter_source_type_id = m.meter_source_type_id
		 ORDER BY region_data_map_id;
END;

PROCEDURE RegionHasTag(
	in_region_sid				IN	region.region_sid%TYPE,
	in_tag_id					IN	tag.tag_id%type,
	out_has_tag					OUT NUMBER
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region with sid '||in_region_sid);
	END IF;
	
	UNSEC_RegionHasTag(
		in_region_sid	=> in_region_sid,
		in_tag_id		=> in_tag_id,
		out_has_tag		=> out_has_tag
	);

END;

PROCEDURE UNSEC_RegionHasTag(
	in_region_sid				IN	region.region_sid%TYPE,
	in_tag_id					IN	tag.tag_id%type,
	out_has_tag					OUT NUMBER
)
AS
BEGIN

	SELECT COUNT(*)
	  INTO out_has_tag
	  FROM region_tag
	 WHERE region_sid = in_region_sid
	   AND tag_id = in_tag_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;

PROCEDURE GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the region with sid '||in_region_sid);
	END IF;

	UNSEC_GetRegionRecord(
		in_region_sid		=> in_region_sid,
		out_region			=> out_region
	);

END;

PROCEDURE UNSEC_GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
)
AS
BEGIN

	SELECT T_REGION(
		region_sid,
		link_to_region_sid,
		parent_sid,
		description,
		active,
		pos,
		info_xml,
		acquisition_dtm,
		disposal_dtm,
		region_type,
		lookup_key,
		geo_country,
		geo_region,
		geo_city_id,
		geo_longitude,
		geo_latitude,
		geo_type,
		egrid_ref,
		region_ref
	)
	  INTO out_region
	  FROM csr.v$region
	 WHERE region_sid = in_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;



END region_pkg;
/

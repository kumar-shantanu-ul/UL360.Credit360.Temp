CREATE OR REPLACE PACKAGE BODY csr.region_set_pkg AS

/**
 * Create a new region set
 *
 * @param	in_app_sid				App sid
 * @param	in_owner_sid			Sid of the user who will own the new region set
 * @param	in_name					Name for the new region set
 * @param	in_region_sids			The regions to include in this set
 * @param	out_region_set_id		The SID of the created object
 */
PROCEDURE CreateRegionSet(
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_owner_sid					IN	csr_user.csr_user_sid%TYPE,
	in_name							IN	region_set.name%TYPE,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_region_set_id				OUT	region_set.region_set_id%TYPE
)
AS
	v_roots							security.T_ORDERED_SID_TABLE;
	v_region_set_id					region_set.region_set_id%TYPE;
BEGIN
	-- TODO Auditing? Doesn't really matter at the moment, since region sets aren't shared

	-- checks that the current user has access to the regions
	v_roots := csr.region_pkg.ProcessStartPoints(SYS_CONTEXT('SECURITY', 'ACT'), in_region_sids, 0);

	INSERT INTO region_set (app_sid, region_set_id, owner_sid, name, disposal_dtm)
	     VALUES (in_app_sid, region_set_id_seq.NEXTVAL, in_owner_sid, in_name, NULL)
	  RETURNING region_set_id
	       INTO v_region_set_id;
	       
	-- we need a distinct since we can be passed the same ind_sid multiple times (e.g. if the user has added to the list with different functions applied etc)
	INSERT INTO region_set_region (app_sid, region_set_id, region_sid, pos)
	     SELECT in_app_sid, v_region_set_id, sid_id, MIN(pos)
		   FROM TABLE(v_roots)
		  GROUP BY in_app_sid, v_region_set_id, sid_id;

	out_region_set_id := v_region_set_id;
END;

/**
 * Create or update a region set
 *
 * @param	in_name					Name for the new region set
 * @param	in_shared				Is the region set shared?
 * @param	in_region_sids			The regions to include in this set
 * @param	out_region_set_id		The id of the created object
 */
PROCEDURE SaveRegionSet(
	in_name							IN	region_set.name%TYPE,
	in_shared						IN	NUMBER,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_region_set_id				OUT	region_set.region_set_id%TYPE
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_count							NUMBER;
	v_region_set_id					region_set.region_set_id%TYPE;
	v_owner_sid						region_set.owner_sid%TYPE;
	v_region_sids					security.T_ORDERED_SID_TABLE;
BEGIN
	-- If saving shared region set, check capability
	IF in_shared = 1 AND NOT csr_data_pkg.CheckCapability('Save shared region sets') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Save shared region sets" capabilty.');
	END IF;

	-- TODO Auditing?

	-- checks that the current user has access to the regions
	v_region_sids := security_pkg.SidArrayToOrderedTable(in_region_sids);

	v_owner_sid := CASE WHEN in_shared = 0 THEN SYS_CONTEXT('SECURITY','SID') ELSE NULL END;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM region_set
	 WHERE name = in_name
	   AND NVL(owner_sid,-1) = NVL(v_owner_sid,-1)
	   AND disposal_dtm IS NULL;

	FOR i IN in_region_sids.FIRST .. in_region_sids.LAST
	LOOP
		IF NOT security.security_pkg.IsAccessAllowedSid(security_pkg.GetAct, in_region_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the region with sid '||in_region_sids(i));
		END IF;
	END LOOP;
	
	IF v_count = 1 THEN
		SELECT region_set_id
		  INTO v_region_set_id
		  FROM region_set
		 WHERE name = in_name
		   AND NVL(owner_sid,-1) = NVL(v_owner_sid,-1)
		   AND disposal_dtm IS NULL;

	   DELETE FROM region_set_region
		 WHERE region_set_id = v_region_set_id;
	ELSE
		INSERT INTO region_set (region_set_id, owner_sid, name)
			 VALUES (region_set_id_seq.NEXTVAL, v_owner_sid, in_name)
		  RETURNING region_set_id
			   INTO v_region_set_id;
	END IF;
	
	-- we need a distinct since we can be passed the same region_sid multiple times (e.g. if the user has added to the list with different functions applied etc)
	INSERT INTO region_set_region (region_set_id, region_sid, pos)
	     SELECT DISTINCT v_region_set_id, sid_id, MIN(pos)
		   FROM TABLE(v_region_sids)
		  GROUP BY v_region_set_id, sid_id;
		  
	out_region_set_id := v_region_set_id;
END;

/**
 * Mark a region set as disposed/deleted
 *
 * @param	in_region_set_id		The region set to dispose
 * @param	in_disposal_dtm			The disposal date (defaults to SYSDATE)
 */
PROCEDURE DisposeRegionSet(
	in_region_set_id				IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	region_set.disposal_dtm%TYPE DEFAULT SYSDATE
)
AS
	v_owner_sid						region_set.owner_sid%TYPE;
BEGIN
	-- TODO Auditing?
	
	SELECT owner_sid
	  INTO v_owner_sid
	  FROM region_set
	 WHERE region_set_id = in_region_set_id;
		 
	-- If disposing shared region set, check capability
	IF v_owner_sid IS NULL AND NOT csr_data_pkg.CheckCapability('Save shared region sets') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Save shared region sets" capabilty.');
	END IF;

	-- If disposing private region set, check that this user owns it
	IF v_owner_sid IS NOT NULL AND v_owner_sid != SYS_CONTEXT('SECURITY','SID') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not own region set id '||in_region_set_id);
	END IF;
	
	UPDATE region_set
	   SET disposal_dtm = in_disposal_dtm
	 WHERE region_set_id = in_region_set_id;
END;

/**
 * Get all region sets available to the current user
 *
 * @param	out_cur					The IDs and names of the region sets
 */
PROCEDURE GetRegionSets(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_user_sid				security_pkg.T_SID_ID;
	v_region_set_ids		security_pkg.T_SID_IDS;
	v_region_set_index		NUMBER;
	v_include_set			BOOLEAN;
	t_region_set_ids		security.T_SID_TABLE;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	user_pkg.GetSID(v_act_id, v_user_sid);

	v_region_set_index := 1;
	FOR r IN (
		SELECT region_set_id, name
		  FROM region_set
		 WHERE (owner_sid = v_user_sid OR owner_sid IS NULL)
		   AND disposal_dtm IS NULL
		)
	LOOP
		v_include_set := TRUE;

		FOR rs IN (
			SELECT region_sid
			  FROM region_set_region
			 WHERE region_set_id = r.region_set_id
			)
		LOOP
			IF NOT security_pkg.IsAccessAllowedSID(v_act_id, rs.region_sid, security_pkg.PERMISSION_READ) THEN
				v_include_set := FALSE;
				EXIT;
			END IF;
		END LOOP;
		
		IF v_include_set THEN
			v_region_set_ids(v_region_set_index) := r.region_set_id;
			v_region_set_index := v_region_set_index + 1;
		END IF;
	END LOOP;
	
	t_region_set_ids := security_pkg.SidArrayToTable(v_region_set_ids);
	OPEN out_cur FOR
		SELECT region_set_id, name, CASE WHEN owner_sid IS NULL THEN 1 ELSE 0 END shared, CASE WHEN owner_sid = v_user_sid THEN 1 ELSE 0 END owned
		  FROM region_set
		 WHERE region_set_id IN (SELECT column_value FROM TABLE(t_region_set_ids))
		 ORDER BY shared, LOWER(name);
END;

/**
 * Get the regions that make up a given region set
 *
 * @param	in_region_set_id		The ID of the region set
 * @param	out_cur					The SIDs and names of the regions in this set
 */
PROCEDURE GetRegionSetRegions(
	in_region_set_id				IN	security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_user_sid					security_pkg.T_SID_ID;
	v_owner_check				NUMBER;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	user_pkg.GetSID(v_act_id, v_user_sid);

	-- Check that the region set is available to the current user
	SELECT COUNT(*)
	  INTO v_owner_check
	  FROM region_set
	 WHERE app_sid = security_pkg.GetApp
	   AND region_set_id = in_region_set_id
	   AND (owner_sid = v_user_sid OR owner_sid IS NULL);

	IF v_owner_check < 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region set id '||in_region_set_id);
	END IF;

	-- Check that the regions in the region set are available to the current user
	FOR r IN (
		SELECT region_sid
		  FROM region_set_region
		 WHERE region_set_id = in_region_set_id
		)
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, r.region_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region sid '||r.region_sid);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT rsr.region_sid, NVL(r2.description, r.description) name
		  FROM region_set_region rsr
		  JOIN v$region r ON r.region_sid = rsr.region_sid
	 LEFT JOIN v$region r2 ON r2.region_sid = r.link_to_region_sid
		 WHERE rsr.region_set_id = in_region_set_id
		 ORDER BY rsr.pos;
END;

END region_set_pkg;
/

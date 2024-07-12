CREATE OR REPLACE PACKAGE BODY csr.indicator_set_pkg AS

/**
 * Create a new indicator set
 *
 * @param	in_app_sid				App sid
 * @param	in_owner_sid			Sid of the user who will own the new indicator set
 * @param	in_name					Name for the new indicator set
 * @param	in_ind_sids				The indicators to include in this set
 * @param	out_ind_set_id			The SID of the created object
 */
PROCEDURE CreateIndicatorSet(
	in_app_sid 						IN	security_pkg.T_SID_ID         DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_owner_sid					IN	csr_user.csr_user_sid%TYPE,
	in_name							IN	ind_set.name%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_set_id					OUT	ind_set.ind_set_id%TYPE
)
AS
	v_ind_set_id					ind_set.ind_set_id%TYPE;
	v_ind_ids						security.T_ORDERED_SID_TABLE;
BEGIN
	-- TODO Auditing? Doesn't really matter at the moment, since indicator sets aren't shared

	-- check that the current user has access to the indicators

	v_ind_ids := security_pkg.SidArrayToOrderedTable(in_ind_sids);

	FOR i IN in_ind_sids.FIRST .. in_ind_sids.LAST
	LOOP
		IF NOT security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_ind_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_ind_sids(i));
		END IF;
	END LOOP;

	INSERT INTO ind_set (app_sid, ind_set_id, owner_sid, name, disposal_dtm)
	     VALUES (in_app_sid, ind_set_id_seq.NEXTVAL, in_owner_sid, in_name, NULL)
	  RETURNING ind_set_id
	       INTO v_ind_set_id;

	-- we need a distinct since we can be passed the same ind_sid multiple times (e.g. if the user has added to the list with different functions applied etc)
	INSERT INTO ind_set_ind (app_sid, ind_set_id, ind_sid, pos)
	     SELECT DISTINCT in_app_sid, v_ind_set_id, ii.sid_id, MIN(pos)
		   FROM TABLE(v_ind_ids) ii
		  GROUP BY in_app_sid, v_ind_set_id, ii.sid_id;

	out_ind_set_id := v_ind_set_id;
END;

/**
 * Create or update an indicator set
 *
 * @param	in_name					Name for the new indicator set
 * @param	in_ind_sids				The indicators to include in this set
 * @param	in_shared				Is the indicator set shared?
 * @param	out_ind_set_id			The SID of the created object
 */
PROCEDURE SaveIndicatorSet(
	in_name							IN	ind_set.name%TYPE,
	in_shared						IN	NUMBER,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	out_ind_set_id					OUT	ind_set.ind_set_id%TYPE
)
AS
	v_user_sid						security_pkg.T_SID_ID;
	v_count							NUMBER;
	v_ind_set_id					ind_set.ind_set_id%TYPE;
	v_owner_sid						ind_set.owner_sid%TYPE;
	v_ind_sids					security.T_ORDERED_SID_TABLE;
BEGIN
	-- If saving shared indicator set, check capability
	IF in_shared = 1 AND NOT csr_data_pkg.CheckCapability('Save shared indicator sets') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Save shared indicator sets" capabilty.');
	END IF;

	-- TODO Auditing?

	-- checks that the current user has access to the indicators
	v_ind_sids := security_pkg.SidArrayToOrderedTable(in_ind_sids);

	v_owner_sid := CASE WHEN in_shared = 0 THEN SYS_CONTEXT('SECURITY','SID') ELSE NULL END;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM ind_set
	 WHERE name = in_name
	   AND NVL(owner_sid,-1) = NVL(v_owner_sid,-1)
	   AND disposal_dtm IS NULL;

	FOR i IN in_ind_sids.FIRST .. in_ind_sids.LAST
	LOOP
		IF NOT security.security_pkg.IsAccessAllowedSid(security_pkg.GetAct, in_ind_sids(i), security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied to the indicator with sid '||in_ind_sids(i));
		END IF;
	END LOOP;
	
	IF v_count = 1 THEN
		SELECT ind_set_id
		  INTO v_ind_set_id
		  FROM ind_set
		 WHERE name = in_name
		   AND NVL(owner_sid,-1) = NVL(v_owner_sid,-1)
		   AND disposal_dtm IS NULL;

	   DELETE FROM ind_set_ind
		 WHERE ind_set_id = v_ind_set_id;
	ELSE
		INSERT INTO ind_set (ind_set_id, owner_sid, name)
			 VALUES (ind_set_id_seq.NEXTVAL, v_owner_sid, in_name)
		  RETURNING ind_set_id
			   INTO v_ind_set_id;
	END IF;
	
	-- we need a distinct since we can be passed the same ind_sid multiple times (e.g. if the user has added to the list with different functions applied etc)
	INSERT INTO ind_set_ind (ind_set_id, ind_sid, pos)
	     SELECT DISTINCT v_ind_set_id, sid_id, MIN(pos)
		   FROM TABLE(v_ind_sids)
		  GROUP BY v_ind_set_id, sid_id;
		  
	out_ind_set_id := v_ind_set_id;
END;

/**
 * Mark a indicator set as disposed/deleted
 *
 * @param	in_ind_set_id			The indicator set to dispose
 * @param	in_disposal_dtm			The disposal date (defaults to SYSDATE)
 */
PROCEDURE DisposeIndicatorSet(
	in_ind_set_id					IN	security_pkg.T_SID_ID,
	in_disposal_dtm					IN	ind_set.disposal_dtm%TYPE DEFAULT SYSDATE
)
AS
	v_owner_sid						ind_set.owner_sid%TYPE;
BEGIN
	-- TODO Auditing?

	SELECT owner_sid
	  INTO v_owner_sid
	  FROM ind_set
	 WHERE ind_set_id = in_ind_set_id;
	
	-- If disposing shared indicator set, check capability
	IF v_owner_sid IS NULL AND NOT csr_data_pkg.CheckCapability('Save shared indicator sets') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not have permissions on the "Save shared indicator sets" capabilty.');
	END IF;

	-- If disposing private indicator set, check that this user owns it
	IF v_owner_sid IS NOT NULL AND v_owner_sid != SYS_CONTEXT('SECURITY','SID') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You do not own indicator set id '||in_ind_set_id);
	END IF;
	
	UPDATE ind_set
	   SET disposal_dtm = in_disposal_dtm
	 WHERE ind_set_id = in_ind_set_id;
END;

/**
 * Get all indicator sets owned by the current user
 *
 * @param	out_cur					The IDs and names of the indicator sets
 */
PROCEDURE GetIndicatorSets(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id			security_pkg.T_ACT_ID;
	v_user_sid			security_pkg.T_SID_ID;
	v_ind_set_ids		security_pkg.T_SID_IDS;
	v_ind_set_index		NUMBER;
	v_include_set		BOOLEAN;
	t_ind_set_ids		security.T_SID_TABLE;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	user_pkg.GetSID(v_act_id, v_user_sid);

	v_ind_set_index := 1;
	FOR r IN (
		SELECT ind_set_id, name
		  FROM ind_set
		 WHERE (owner_sid = v_user_sid OR owner_sid IS NULL)
		   AND disposal_dtm IS NULL
		)
	LOOP
		v_include_set := TRUE;

		FOR rs IN (
			SELECT ind_sid
			  FROM ind_set_ind
			 WHERE ind_set_id = r.ind_set_id
			)
		LOOP
			IF NOT security_pkg.IsAccessAllowedSID(v_act_id, rs.ind_sid, security_pkg.PERMISSION_READ) THEN
				v_include_set := FALSE;
				EXIT;
			END IF;
		END LOOP;
		
		IF v_include_set THEN
			v_ind_set_ids(v_ind_set_index) := r.ind_set_id;
			v_ind_set_index := v_ind_set_index + 1;
		END IF;
	END LOOP;
	
	t_ind_set_ids := security_pkg.SidArrayToTable(v_ind_set_ids);
	OPEN out_cur FOR
		SELECT ind_set_id, name, CASE WHEN owner_sid IS NULL THEN 1 ELSE 0 END shared, CASE WHEN owner_sid = v_user_sid THEN 1 ELSE 0 END owned
		  FROM ind_set
		 WHERE ind_set_id IN (SELECT column_value FROM TABLE(t_ind_set_ids))
		 ORDER BY shared, LOWER(name);
END;

/**
 * Get the indicators that make up a given indicator set
 *
 * @param	in_ind_set_id			The ID of the indicator set
 * @param	out_cur					The SIDs and names of the indicators in this set
 */
PROCEDURE GetIndicatorSetIndicators(
	in_ind_set_id					IN	security_pkg.T_SID_ID,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id					security_pkg.T_ACT_ID;
	v_user_sid					security_pkg.T_SID_ID;
	v_owner_check				NUMBER;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	user_pkg.GetSID(v_act_id, v_user_sid);

	-- Check that the indicator set belongs to the current user
	SELECT COUNT(*)
	  INTO v_owner_check
	  FROM ind_set
	 WHERE app_sid = security_pkg.GetApp
	   AND ind_set_id = in_ind_set_id
	   AND (owner_sid = v_user_sid OR owner_sid IS NULL);

	IF v_owner_check < 1 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading indicator set id '||in_ind_set_id);
	END IF;

	-- Check that the indicators in the indicator set are available to the current user
	FOR r IN (
		SELECT ind_sid
		  FROM ind_set_ind
		 WHERE ind_set_id = in_ind_set_id
		)
	LOOP
		IF NOT security_pkg.IsAccessAllowedSID(v_act_id, r.ind_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading indicator sid '||r.ind_sid);
		END IF;
	END LOOP;
	
	OPEN out_cur FOR
		SELECT isi.ind_sid, i.description name
		  FROM csr.ind_set_ind isi
		  JOIN csr.v$ind i ON isi.app_sid = i.app_sid AND isi.ind_sid = i.ind_sid
		 WHERE isi.ind_set_id = in_ind_set_id
		 ORDER BY isi.pos;
END;

END indicator_set_pkg;
/

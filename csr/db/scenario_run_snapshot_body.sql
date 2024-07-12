CREATE OR REPLACE PACKAGE BODY CSR.scenario_run_snapshot_pkg AS

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_class_id						IN	security_pkg.T_CLASS_ID,
	in_name							IN	security_pkg.T_SO_NAME,
	in_parent_sid_id				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	-- Should be called via the Create method
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_name						IN	security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE DeleteObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID
)
AS
	v_app_sid						security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	DELETE FROM scenario_run_snapshot_region
	 WHERE app_sid = v_app_sid AND scenario_run_snapshot_sid = in_sid_id;
	
	DELETE FROM scenario_run_snapshot_ind
	 WHERE app_sid = v_app_sid AND scenario_run_snapshot_sid = in_sid_id;

	UPDATE scenario_run_snapshot
	   SET version = NULL
	 WHERE app_sid = v_app_sid AND scenario_run_snapshot_sid = in_sid_id;

	DELETE FROM scenario_run_snapshot_file
	 WHERE app_sid = v_app_sid AND scenario_run_snapshot_sid = in_sid_id;

	DELETE FROM scenario_run_snapshot
	 WHERE app_sid = v_app_sid AND scenario_run_snapshot_sid = in_sid_id;

	IF SQL%ROWCOUNT != 1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Missing scenario run snapshot with sid '||in_sid_id);
	END IF;	
END;

PROCEDURE MoveObject(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_sid_id						IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id			IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id			IN	security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE GetSnapshot(
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'),
		in_scenario_run_snapshot_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED,
			'Access denied reading the scenario run snapshot with sid '||in_scenario_run_snapshot_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT scenario_run_snapshot_sid, scenario_run_sid, start_dtm, end_dtm,
		       last_updated_dtm, version, period_set_id, period_interval_id
		  FROM scenario_run_snapshot
		 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;

	OPEN out_ind_cur FOR
		SELECT ind_sid
		  FROM scenario_run_snapshot_ind
		 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;

	OPEN out_region_cur FOR
		SELECT region_sid
		  FROM scenario_run_snapshot_region
		 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;
END;

PROCEDURE CreateScenarioRunSnapshot(
	in_scenario_run_sid				IN	scenario_run_snapshot.scenario_run_sid%TYPE,
	in_name							IN	security_pkg.T_SO_NAME,
	in_start_dtm					IN	scenario_run_snapshot.start_dtm%TYPE,
	in_end_dtm						IN	scenario_run_snapshot.end_dtm%TYPE,
	in_period_set_id				IN	scenario_run_snapshot.period_set_id%TYPE,
	in_period_interval_id			IN	scenario_run_snapshot.period_interval_id%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	out_scenario_run_snapshot_sid	OUT	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE
)
AS
	v_ind_sids						security.T_SID_TABLE;
	v_region_sids					security.T_SID_TABLE;
BEGIN	 
	securableObject_pkg.CreateSO(security_pkg.GetACT(), in_scenario_run_sid,
		class_pkg.GetClassId('CSRScenarioRunSnapshot'), in_name, out_scenario_run_snapshot_sid);
		
	INSERT INTO scenario_run_snapshot (scenario_run_snapshot_sid, scenario_run_sid,
		start_dtm, end_dtm, period_set_id, period_interval_id)
	VALUES (out_scenario_run_snapshot_sid, in_scenario_run_sid,
		in_start_dtm, in_end_dtm, in_period_set_id, in_period_interval_id);

	INSERT INTO scenario_run_snapshot_file (scenario_run_snapshot_sid, version)
	VALUES (out_scenario_run_snapshot_sid, 0);
	
	UPDATE scenario_run_snapshot
	   SET version = 0
	 WHERE scenario_run_snapshot_sid = out_scenario_run_snapshot_sid;

	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
	INSERT INTO scenario_run_snapshot_ind (scenario_run_snapshot_sid, ind_sid)
		SELECT out_scenario_run_snapshot_sid, column_value
		  FROM TABLE(v_ind_sids);

	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	INSERT INTO scenario_run_snapshot_region (scenario_run_snapshot_sid, region_sid)
		SELECT out_scenario_run_snapshot_sid, column_value
		  FROM TABLE(v_region_sids);
END;

-- No security: only used by scrag++'s analysisServer
PROCEDURE AddSnapshot(
	in_app_sid						IN	scenario_run_snapshot.app_sid%TYPE,
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot.scenario_run_snapshot_sid%TYPE,
	out_cur							OUT	SYS_REFCURSOR,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_region_cur					OUT	SYS_REFCURSOR
)
AS
	v_version						scenario_run_snapshot.version%TYPE;
BEGIN
	SELECT NVL(MAX(version), 0) + 1
	  INTO v_version
	  FROM scenario_run_snapshot_file
	 WHERE app_sid = in_app_sid
	   AND scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;
	   
	INSERT INTO scenario_run_snapshot_file (app_sid, scenario_run_snapshot_sid, version)
	VALUES (in_app_sid, in_scenario_run_snapshot_sid, v_version);
	
	OPEN out_cur FOR
		SELECT s.scenario_sid, sr.scenario_run_sid, sr.description, srsf.file_path, srsf.sha1, 
			   srs.version, srs.period_set_id, srs.period_interval_id, srs.start_dtm, srs.end_dtm,
			   s.equality_epsilon, v_version next_version
		  FROM scenario_run_snapshot srs, scenario_run_snapshot_file srsf,
		  	   scenario_run sr, scenario s
		 WHERE srs.app_sid = in_app_sid AND srs.scenario_run_snapshot_sid = in_scenario_run_snapshot_sid
		   AND srs.app_sid = sr.app_sid AND srs.scenario_run_sid = sr.scenario_run_sid
		   AND sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		   AND srs.app_sid = srsf.app_sid AND srs.scenario_run_snapshot_sid = srsf.scenario_run_snapshot_sid 
		   AND srs.version = srsf.version;
		   
	OPEN out_ind_cur FOR
		SELECT ind_sid
		  FROM scenario_run_snapshot_ind
		 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;

	OPEN out_region_cur FOR
		SELECT region_sid
		  FROM scenario_run_snapshot_region
		 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid;
END;

PROCEDURE SetSnapshotFile(
	in_app_sid						IN	scenario_run_snapshot_file.app_sid%TYPE,
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot_file.scenario_run_snapshot_sid%TYPE,
	in_version						IN	scenario_run_snapshot_file.version%TYPE,
	in_file_path					IN	scenario_run_snapshot_file.file_path%TYPE,
	in_sha1							IN	scenario_run_snapshot_file.sha1%TYPE
)
AS
BEGIN
	UPDATE scenario_run_snapshot_file
	   SET file_path = in_file_path,
		   sha1 = in_sha1
	 WHERE app_sid = in_app_sid 
	   AND scenario_run_snapshot_sid = in_scenario_run_snapshot_sid
	   AND version = in_version;

	UPDATE scenario_run_snapshot
	   SET version = in_version,
	   	   last_updated_dtm = SYSDATE
	 WHERE app_sid = in_app_sid 
	   AND scenario_run_snapshot_sid = in_scenario_run_snapshot_sid
	   AND version < in_version;

	-- Delete old scenario run snapshot file details.
	-- (these used to be kept for cleanup, but now the calcJobRunner process 
	--  has a clean up thread that spins around looking for files in the 
	--  'repository' directory that are old and cleans them up periodically)
	DELETE FROM scenario_run_snapshot_file
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND scenario_run_snapshot_sid = in_scenario_run_snapshot_sid
	   AND version < in_version;	 

	COMMIT;
END;

PROCEDURE RefreshSnapshotInputs(
	in_scenario_run_snapshot_sid	IN	scenario_run_snapshot_file.scenario_run_snapshot_sid%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS
)
AS
	v_ind_sids						security.T_SID_TABLE;
	v_region_sids					security.T_SID_TABLE;
BEGIN	 

	v_ind_sids := security_pkg.SidArrayToTable(in_ind_sids);
	INSERT INTO scenario_run_snapshot_ind (scenario_run_snapshot_sid, ind_sid)
		SELECT in_scenario_run_snapshot_sid, column_value
		  FROM TABLE(v_ind_sids) 
		 WHERE column_value NOT IN (
			SELECT ind_sid 
			  FROM scenario_run_snapshot_ind 
			 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid);

	v_region_sids := security_pkg.SidArrayToTable(in_region_sids);
	INSERT INTO scenario_run_snapshot_region (scenario_run_snapshot_sid, region_sid)
		SELECT in_scenario_run_snapshot_sid, column_value
		  FROM TABLE(v_region_sids)
		 WHERE column_value NOT IN (
			SELECT region_sid
			  FROM scenario_run_snapshot_region
			 WHERE scenario_run_snapshot_sid = in_scenario_run_snapshot_sid);

END;

END scenario_run_snapshot_pkg;
/

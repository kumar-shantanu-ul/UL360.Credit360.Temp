CREATE OR REPLACE PACKAGE BODY CSR.scenario_api_pkg AS

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_sid, security_pkg.PERMISSION_READ) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on scenario '||in_scenario_sid);
	END IF;
	
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid AS scenario_run_id, s.scenario_sid AS scenario_id, s.description, sr.last_success_dtm
		  FROM csr.scenario s
		  LEFT JOIN csr.scenario_run sr ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		 WHERE s.scenario_sid = in_scenario_sid
		   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetScenarioByRunSid(
	in_scenario_run_sid				IN	scenario_run.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	IF security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_scenario_run_sid, security_pkg.PERMISSION_READ) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on scenario run '||in_scenario_run_sid);
	END IF;
	
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid AS scenario_run_id, s.scenario_sid AS scenario_id, s.description, sr.last_success_dtm
		  FROM csr.scenario s
		  LEFT JOIN csr.scenario_run sr ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		 WHERE sr.scenario_run_sid = in_scenario_run_sid
		   AND s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_scn_cur FOR
		SELECT sr.scenario_run_sid AS scenario_run_id, s.scenario_sid AS scenario_id, s.description, sr.last_success_dtm
		  FROM scenario s
		  LEFT JOIN scenario_run sr ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), s.scenario_sid, security_Pkg.PERMISSION_READ) = 1;
END;

PROCEDURE GetMergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
v_scenario_sid						scenario.scenario_sid%TYPE;
BEGIN
	BEGIN
		SELECT s.scenario_sid 
		  INTO v_scenario_sid 
		  FROM csr.scenario s
		  LEFT JOIN scenario_run sr ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		  JOIN csr.customer c on c.app_sid = sr.app_sid AND c.merged_scenario_run_sid = sr.scenario_run_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		  v_scenario_sid := -1;
	END;
	GetScenario(v_scenario_sid, out_scn_cur);
END;

PROCEDURE GetUnmergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
)
AS
v_scenario_sid						scenario.scenario_sid%TYPE;
BEGIN
	BEGIN
		SELECT s.scenario_sid 
		  INTO v_scenario_sid 
		  FROM csr.scenario s
		  LEFT JOIN scenario_run sr ON sr.app_sid = s.app_sid AND sr.scenario_sid = s.scenario_sid
		  JOIN csr.customer c on c.app_sid = sr.app_sid AND c.unmerged_scenario_run_sid = sr.scenario_run_sid
		 WHERE s.app_sid = SYS_CONTEXT('SECURITY', 'APP');
		EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		  v_scenario_sid := -1;
	END;
	GetScenario(v_scenario_sid, out_scn_cur);
END;


END;
/

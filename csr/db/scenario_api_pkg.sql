CREATE OR REPLACE PACKAGE CSR.scenario_api_pkg AS

PROCEDURE GetScenario(
	in_scenario_sid					IN	scenario.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarioByRunSid(
	in_scenario_run_sid				IN	scenario_run.scenario_sid%TYPE,
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetScenarios(
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetMergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetUnmergedScenario(
	out_scn_cur						OUT	SYS_REFCURSOR
);

END;
/

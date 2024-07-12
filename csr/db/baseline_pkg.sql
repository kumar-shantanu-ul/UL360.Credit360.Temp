CREATE OR REPLACE PACKAGE csr.baseline_pkg AS

PROCEDURE CreateBaselineConfig (
	in_baseline_name					IN  baseline_config.baseline_name%TYPE,
	in_baseline_lookup_key				IN  baseline_config.baseline_lookup_key%TYPE,
	out_baseline_config_id				OUT baseline_config.baseline_config_id%TYPE
);

PROCEDURE CreateBaselineConfigPeriod (
	in_baseline_config_id				IN  baseline_config_period.baseline_config_id%TYPE,
	in_baseline_period_dtm				IN  baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN  baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN  baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL,
	out_baseline_config_period_id		OUT baseline_config_period.baseline_config_period_id%TYPE
);

PROCEDURE UpdateBaselineConfig (
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE,
	in_baseline_name					IN baseline_config.baseline_name%TYPE,
	in_baseline_lookup_key				IN baseline_config.baseline_lookup_key%TYPE
);

PROCEDURE UpdateBaselineConfigPeriod (
	in_baseline_config_period_id		IN baseline_config_period.baseline_config_period_id%TYPE,
	in_baseline_period_dtm				IN baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL
);

PROCEDURE GetBaselineConfigs (
	out_baseline_config_cur				OUT SYS_REFCURSOR,
	out_baseline_config_period_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetBaselineConfig (
	in_baseline_config_id				IN  baseline_config.baseline_config_id%TYPE,
	out_cur								OUT SYS_REFCURSOR
);

PROCEDURE GetBaselineConfigList (
	out_cur OUT SYS_REFCURSOR
);

PROCEDURE GetBaselineConfigPeriod (
	in_baseline_config_id				IN  baseline_config_period.baseline_config_id%TYPE,
	out_cur								OUT SYS_REFCURSOR
);

PROCEDURE DeleteBaselineConfig (
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE
);

PROCEDURE DeleteBaselineConfigPeriod (
	in_baseline_config_period_id		IN baseline_config_period.baseline_config_period_id%TYPE
);


PROCEDURE GetCalcDependencies (
	in_baseline_config_id				IN  baseline_config_period.baseline_config_id%TYPE,
	out_cur								OUT SYS_REFCURSOR
);

PROCEDURE CheckOverlapPeriods(
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE,
	in_baseline_config_period_id		IN baseline_config_period.baseline_config_period_id%TYPE DEFAULT 0,
	in_baseline_period_dtm				IN baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL
);

PROCEDURE AddCalcJobs(
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE
);

END;
/

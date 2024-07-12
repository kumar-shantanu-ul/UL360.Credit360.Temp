CREATE OR REPLACE PACKAGE BODY csr.baseline_pkg IS

PROCEDURE CreateBaselineConfig (
	in_baseline_name					IN  baseline_config.baseline_name%TYPE,
	in_baseline_lookup_key				IN  baseline_config.baseline_lookup_key%TYPE,
	out_baseline_config_id				OUT baseline_config.baseline_config_id%TYPE
) 
AS
BEGIN
	out_baseline_config_id := baseline_config_id_seq.nextval;

	INSERT INTO baseline_config (
		app_sid,
		baseline_config_id,
		baseline_name,
		baseline_lookup_key) 
	VALUES (
		security.security_pkg.getapp,
		out_baseline_config_id,
		in_baseline_name,
		in_baseline_lookup_key
	);
END;

PROCEDURE CreateBaselineConfigPeriod (
	in_baseline_config_id				IN  baseline_config_period.baseline_config_id%TYPE,
	in_baseline_period_dtm				IN  baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN  baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN  baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL,
	out_baseline_config_period_id		OUT baseline_config_period.baseline_config_period_id%TYPE
) 
AS
BEGIN
	IF in_baseline_cover_period_start_dtm IS NULL AND in_baseline_cover_period_end_dtm IS NOT NULL
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NULL_BASELINE_COVER_START_DATE, 'Cover start cannot be null when end date is not null');
	END IF;
	
	IF  in_baseline_cover_period_start_dtm < in_baseline_period_dtm
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_BASELINE_COVER_START_DATE, 'Cover start should be greater than baseline start');
	END IF;
	
	IF  in_baseline_cover_period_end_dtm <= in_baseline_cover_period_start_dtm
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_BASELINE_COVER_END_DATE, 'Cover end should be greater than cover start');
	END IF;
	
	CheckOverlapPeriods(in_baseline_config_id, 0, in_baseline_period_dtm, in_baseline_cover_period_start_dtm, in_baseline_cover_period_end_dtm);

	out_baseline_config_period_id:=csr.baseline_config_period_id_seq.nextval;

	INSERT INTO baseline_config_period (
		app_sid,
		baseline_config_period_id,
		baseline_config_id,
		baseline_period_dtm,
		baseline_cover_period_start_dtm,
		baseline_cover_period_end_dtm
	) VALUES (
		security.security_pkg.getapp,
		out_baseline_config_period_id,
		in_baseline_config_id,
		TRUNC(in_baseline_period_dtm),
		TRUNC(in_baseline_cover_period_start_dtm),
		TRUNC(in_baseline_cover_period_end_dtm)
	);
END;

PROCEDURE UpdateBaselineConfig (
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE,
	in_baseline_name					IN baseline_config.baseline_name%TYPE,
	in_baseline_lookup_key				IN baseline_config.baseline_lookup_key%TYPE
)
AS
BEGIN
	UPDATE baseline_config
	   SET baseline_name = in_baseline_name,
		   baseline_lookup_key = in_baseline_lookup_key
	 WHERE baseline_config_id = in_baseline_config_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE UpdateBaselineConfigPeriod (
	in_baseline_config_period_id		IN baseline_config_period.baseline_config_period_id%TYPE,
	in_baseline_period_dtm				IN baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL
)
AS
	in_baseline_config_id				baseline_config.baseline_config_id%TYPE;
BEGIN
	IF in_baseline_cover_period_start_dtm IS NULL AND in_baseline_cover_period_end_dtm IS NOT NULL
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_NULL_BASELINE_COVER_START_DATE, 'Cover start cannot be null when end date is not null');
	END IF;
	
	IF  in_baseline_cover_period_start_dtm < in_baseline_period_dtm
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_BASELINE_COVER_START_DATE, 'Cover start should be greater than baseline start');
	END IF;
	
	IF  in_baseline_cover_period_end_dtm <= in_baseline_cover_period_start_dtm
	THEN
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_INVALID_BASELINE_COVER_END_DATE, 'Cover end should be greater than cover start');
	END IF;

	SELECT baseline_config_id
		INTO  in_baseline_config_id
		FROM  csr.baseline_config_period
	WHERE baseline_config_period_id = in_baseline_config_period_id;

	CheckOverlapPeriods(in_baseline_config_id, in_baseline_config_period_id, in_baseline_period_dtm, in_baseline_cover_period_start_dtm, in_baseline_cover_period_end_dtm);

	UPDATE baseline_config_period
	   SET baseline_period_dtm = TRUNC(in_baseline_period_dtm),
		   baseline_cover_period_start_dtm = TRUNC(in_baseline_cover_period_start_dtm),
		   baseline_cover_period_end_dtm = TRUNC(in_baseline_cover_period_end_dtm)
	 WHERE baseline_config_period_id = in_baseline_config_period_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBaselineConfigs (
	out_baseline_config_cur			OUT SYS_REFCURSOR,
	out_baseline_config_period_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_baseline_config_cur FOR
		SELECT baseline_config_id, baseline_name, baseline_lookup_key
		  FROM baseline_config
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_baseline_config_period_cur FOR
		SELECT baseline_config_period_id, baseline_config_id,
			baseline_period_dtm, baseline_cover_period_start_dtm,
			baseline_cover_period_end_dtm
		  FROM baseline_config_period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBaselineConfig (
	in_baseline_config_id			IN  baseline_config.baseline_config_id%TYPE,
	out_cur 						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT baseline_config_id, baseline_name, baseline_lookup_key
		  FROM baseline_config 
		 WHERE baseline_config_id = in_baseline_config_id
		  AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBaselineConfigList (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT baseline_config_id, baseline_name, baseline_lookup_key
		  FROM baseline_config
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetBaselineConfigPeriod (
	in_baseline_config_id			IN 	baseline_config_period.baseline_config_id%TYPE,
	out_cur 						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT baseline_config_period_id, baseline_config_id,
			baseline_period_dtm, baseline_cover_period_start_dtm,
			baseline_cover_period_end_dtm
		  FROM baseline_config_period
		 WHERE baseline_config_id = in_baseline_config_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteBaselineConfig (
	in_baseline_config_id			IN  baseline_config.baseline_config_id%TYPE
)
AS
BEGIN
	DELETE FROM baseline_config_period
	 WHERE baseline_config_id = in_baseline_config_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM baseline_config 
	 WHERE baseline_config_id = in_baseline_config_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE DeleteBaselineConfigPeriod (
	in_baseline_config_period_id	IN  baseline_config_period.baseline_config_period_id%TYPE
)
AS
BEGIN
	DELETE FROM baseline_config_period
	 WHERE baseline_config_period_id = in_baseline_config_period_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetCalcDependencies (
	in_baseline_config_id			IN 	baseline_config_period.baseline_config_id%TYPE,
	out_cur 						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT calc_ind_sid, baseline_config_id
		  FROM csr.calc_baseline_config_dependency
		 WHERE baseline_config_id = in_baseline_config_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE CheckOverlapPeriods(
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE,
	in_baseline_config_period_id		IN baseline_config_period.baseline_config_period_id%TYPE DEFAULT 0,
	in_baseline_period_dtm				IN baseline_config_period.baseline_period_dtm%TYPE,
	in_baseline_cover_period_start_dtm	IN baseline_config_period.baseline_cover_period_start_dtm%TYPE DEFAULT NULL,
	in_baseline_cover_period_end_dtm	IN baseline_config_period.baseline_cover_period_end_dtm%TYPE DEFAULT NULL
)
AS
baseline_start_overlap NUMBER;
cover_start_overlap NUMBER;
cover_end_overlap NUMBER;
BEGIN
	SELECT COUNT(*)
	 INTO baseline_start_overlap
	 FROM csr.baseline_config_period bcp
	WHERE baseline_config_id = in_baseline_config_id
		AND baseline_config_period_id <> in_baseline_config_period_id
		AND in_baseline_period_dtm >= bcp.baseline_period_dtm
		AND in_baseline_period_dtm < add_months(bcp.baseline_period_dtm,12)
		AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF baseline_start_overlap > 0
	THEN
		 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_BASELINE_CONFIG_OVERLAP, 'Baseline start period overlaps existing config period');
	END IF;
	
	SELECT COUNT(*)
	 INTO cover_start_overlap
	 FROM csr.baseline_config_period bcp
	WHERE baseline_config_id = in_baseline_config_id
		AND baseline_config_period_id <> in_baseline_config_period_id
		AND in_baseline_cover_period_start_dtm > bcp.baseline_cover_period_start_dtm AND in_baseline_cover_period_start_dtm < bcp.baseline_cover_period_end_dtm
		AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF cover_start_overlap > 0
	THEN
		 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_BASELINE_CONFIG_COVER_START_OVERLAP, 'Cover start overlaps existing config period');
	END IF;

	SELECT COUNT(*)
	 INTO cover_start_overlap
	 FROM csr.baseline_config_period bcp
	WHERE baseline_config_id = in_baseline_config_id
		AND baseline_config_period_id <> in_baseline_config_period_id
		AND in_baseline_cover_period_start_dtm > bcp.baseline_cover_period_start_dtm AND bcp.baseline_cover_period_end_dtm is NULL
		AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF cover_start_overlap > 0
	THEN
		 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_BASELINE_CONFIG_COVER_START_OVERLAP, 'Cover start overlaps existing config period');
	END IF;

	SELECT COUNT(*)
	 INTO cover_end_overlap
	 FROM csr.baseline_config_period bcp
	WHERE baseline_config_id = in_baseline_config_id
		AND baseline_config_period_id <> in_baseline_config_period_id
		AND in_baseline_cover_period_start_dtm < bcp.baseline_cover_period_start_dtm
		AND in_baseline_cover_period_end_dtm > bcp.baseline_cover_period_start_dtm
		AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF cover_end_overlap > 0
	THEN
		 RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_BASELINE_CONFIG_COVER_END_OVERLAP, 'Cover end overlaps existing config period');
	END IF;
END;

PROCEDURE AddCalcJobs(
	in_baseline_config_id				IN baseline_config.baseline_config_id%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT DISTINCT calc_ind_sid
		  FROM calc_baseline_config_dependency
		 WHERE baseline_config_id = in_baseline_config_id
	 ) LOOP
		calc_pkg.AddJobsForCalc(r.calc_ind_sid);
	 END LOOP;
END;

END;
/
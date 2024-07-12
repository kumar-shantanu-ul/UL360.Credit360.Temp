CREATE OR REPLACE PACKAGE BODY csr.period_pkg AS

PROCEDURE GetPeriodSets(
	out_period_set_cur				OUT SYS_REFCURSOR,
	out_period_cur					OUT SYS_REFCURSOR,
	out_period_dates_cur			OUT SYS_REFCURSOR,
	out_period_interval_cur			OUT SYS_REFCURSOR,
	out_period_interval_memb_cur	OUT SYS_REFCURSOR
)
AS
	v_start_month_offset			NUMBER(1);
BEGIN
	v_start_month_offset:= csr_data_pkg.SQL_CheckCapability('Adjust period labels to start month');
	
	-- This info is public
	OPEN out_period_set_cur FOR
		SELECT period_set_id, annual_periods, label, DECODE(v_start_month_offset, 1, start_month, 0) start_month
		  FROM period_set ps
		  JOIN customer c ON ps.app_sid = c.app_sid
		 WHERE ps.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY period_set_id;

	OPEN out_period_cur FOR
		SELECT period_set_id, period_id, label, start_dtm, end_dtm
		  FROM period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY period_set_id, period_id;

	OPEN out_period_dates_cur FOR
		SELECT period_set_id, period_id, year, start_dtm, end_dtm
		  FROM period_dates
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY period_set_id, period_id;

	OPEN out_period_interval_cur FOR
		SELECT period_set_id, period_interval_id, label, single_interval_label, 
			   single_interval_no_year_label, multiple_interval_label
		  FROM period_interval
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY period_set_id;

	OPEN out_period_interval_memb_cur FOR
		SELECT period_set_id, period_interval_id, start_period_id, end_period_id
		  FROM period_interval_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 ORDER BY period_set_id, period_interval_id, start_period_id;
END;


PROCEDURE GetPeriodSet(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	out_period_set_cur				OUT SYS_REFCURSOR,
	out_period_cur					OUT SYS_REFCURSOR,
	out_period_dates_cur			OUT SYS_REFCURSOR,
	out_period_interval_cur			OUT SYS_REFCURSOR,
	out_period_interval_memb_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	-- This info is public
	OPEN out_period_set_cur FOR
		SELECT annual_periods, label
		  FROM period_set
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND period_set_id = in_period_set_id
		 ORDER BY period_set_id;

	OPEN out_period_cur FOR
		SELECT period_set_id, period_id, label, start_dtm, end_dtm
		  FROM period
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND period_set_id = in_period_set_id
		 ORDER BY period_id;

	OPEN out_period_dates_cur FOR
		SELECT period_id, year, start_dtm, end_dtm
		  FROM period_dates
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND period_set_id = in_period_set_id
		 ORDER BY period_id;

	OPEN out_period_interval_cur FOR
		SELECT period_interval_id, label, single_interval_label, 
			   single_interval_no_year_label, multiple_interval_label
		  FROM period_interval
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND period_set_id = in_period_set_id
		 ORDER BY period_interval_id;

	OPEN out_period_interval_memb_cur FOR
		SELECT period_interval_id, start_period_id, end_period_id
		  FROM period_interval_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND period_set_id = in_period_set_id
		 ORDER BY period_interval_id, start_period_id;
END;

FUNCTION GetIntervalNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN NUMBER
AS
	v_min_len						NUMBER;
	v_max_len						NUMBER;
	v_min_period_number				NUMBER;
	v_total_periods					NUMBER;
	v_current_interval_number		NUMBER;
	v_current_year_period			NUMBER;
	v_total_intervals				NUMBER;
BEGIN
	SELECT MIN(start_period_id) min_period_number,
		   MIN(end_period_id - start_period_id + 1) min_len,
		   MAX(end_period_id - start_period_id + 1) max_len,
		   SUM(end_period_id - start_period_id + 1) total_periods,
		   COUNT(*) total_intervals
	  INTO v_min_period_number, v_min_len, v_max_len, v_total_periods, v_total_intervals
	  FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id;

	-- work out the interval number that we are currently in
	v_current_year_period := MOD(in_period_number - v_min_period_number, v_total_periods) + 1;
	SELECT interval
	  INTO v_current_interval_number
	  FROM (SELECT rownum interval, start_period_id, end_period_id
			  FROM (SELECT period_set_id,period_interval_id,start_period_id,end_period_id
					  FROM period_interval_member
					 WHERE period_set_id = in_period_set_id and period_interval_id = in_period_interval_id
				  ORDER BY period_set_id, period_interval_id))
	 WHERE v_current_year_period BETWEEN start_period_id and end_period_id;
	RETURN FLOOR((in_period_number - v_min_period_number) / v_total_periods) * v_total_intervals + v_current_interval_number;
END;

FUNCTION GetIntervalNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN NUMBER
AS
BEGIN
	RETURN GetIntervalNumber(in_period_set_id, in_period_interval_id,
			GetPeriodNumber(in_period_set_id, in_dtm));
END;

FUNCTION GetPeriodNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_interval_number				IN	NUMBER
)
RETURN NUMBER
AS
	v_min_len						NUMBER;
	v_max_len						NUMBER;
	v_min_period_number				NUMBER;
	v_total_intervals				NUMBER; 
	v_total_periods					NUMBER; 
	v_current_year_interval			NUMBER;
	v_current_period				NUMBER;
BEGIN
	SELECT MIN(start_period_id) min_period_number,
		   MIN(end_period_id - start_period_id + 1) min_len,
		   MAX(end_period_id - start_period_id + 1) max_len,
		   SUM(end_period_id - start_period_id + 1) total_periods,
		   COUNT(*) total_intervals
	  INTO v_min_period_number, v_min_len, v_max_len, v_total_periods, v_total_intervals
	  FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id;

	-- work out the interval number we are currently in and convert that to total periods from the start of the year
	v_current_year_interval := MOD(in_interval_number - 1, v_total_intervals) + 1;
	SELECT NVL(SUM(period_len), 0)
	  INTO v_current_period
	  FROM (SELECT ROW_NUMBER() OVER (ORDER BY start_period_id) interval_number,
				   end_period_id - start_period_id + 1 period_len
			  FROM period_interval_member
			 WHERE period_set_id = in_period_set_id
			   AND period_interval_id = in_period_interval_id)
	 WHERE interval_number < v_current_year_interval;
	RETURN 1 + v_total_periods * FLOOR((in_interval_number - 1) / v_total_intervals) + v_current_period;
END;

FUNCTION GetPeriodNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN NUMBER
AS
	v_annual_periods				period_set.annual_periods%TYPE;
	v_period_number					NUMBER;
	v_period_count					NUMBER;
	v_period_year					NUMBER;
	v_seek_dtm						VARCHAR2(5);
BEGIN
	SELECT annual_periods
	  INTO v_annual_periods
	  FROM period_set
	 WHERE period_set_id = in_period_set_id;
	 
	IF v_annual_periods = 1 THEN

		v_seek_dtm := TO_CHAR(in_dtm, 'MM-DD');

		SELECT period_number, period_count, period_year
		  INTO v_period_number, v_period_count, v_period_year
		  FROM (SELECT ROW_NUMBER() OVER (ORDER BY start_dtm) period_number, 
					   COUNT(*) OVER () period_count, 
					   EXTRACT(YEAR FROM start_dtm) period_year,
					   TO_CHAR(start_dtm,'MM-DD') start_dtm, 
					   TO_CHAR(end_dtm,'MM-DD') end_dtm
				  FROM period
				 WHERE period_set_id = in_period_set_id)
		 WHERE start_dtm <= v_seek_dtm AND (v_seek_dtm < end_dtm OR start_dtm > end_dtm);

		RETURN v_period_number + v_period_count * (EXTRACT(YEAR FROM in_dtm) - v_period_year);
	END IF;

	SELECT period_number
	  INTO v_period_number
	  FROM (SELECT start_dtm, end_dtm, ROW_NUMBER() OVER (ORDER BY start_dtm) period_number
			  FROM period_dates 
			 WHERE period_set_id = in_period_set_id)
	 WHERE start_dtm <= in_dtm AND in_dtm < end_dtm;
	 RETURN v_period_number;
END;

FUNCTION GetPeriodDate(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN DATE
AS
	v_annual_periods				period_set.annual_periods%TYPE;
	v_period_number					NUMBER;
	v_periods						NUMBER;
	v_date							DATE;
	v_year							NUMBER;
BEGIN
	SELECT annual_periods
	  INTO v_annual_periods
	  FROM period_set
	 WHERE period_set_id = in_period_set_id;
	 
	IF v_annual_periods = 1 THEN		 
		SELECT start_dtm, periods
		  INTO v_date, v_periods
		  FROM (SELECT start_dtm, end_dtm, 
					   ROW_NUMBER() OVER (ORDER BY start_dtm) period_number,
					   COUNT(*) OVER () periods
				  FROM period
				 WHERE period_set_id = in_period_set_id)
		 WHERE MOD(in_period_number  - 1, periods) + 1 = period_number;		 
		v_year := EXTRACT(YEAR FROM v_date) + FLOOR((in_period_number - 1) / v_periods);
		RETURN TO_DATE(v_year || '-' || EXTRACT(MONTH FROM v_date) || '-' || EXTRACT(DAY FROM v_date), 'YYYY-MM-DD');
	END IF;

	SELECT start_dtm
	  INTO v_date
	  FROM (SELECT start_dtm, end_dtm, ROW_NUMBER() OVER (ORDER BY start_dtm) period_number
			  FROM period_dates 
			 WHERE period_set_id = in_period_set_id)
	 WHERE period_number = in_period_number;
	RETURN v_date;
END;

FUNCTION AddIntervals(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER,
	in_intervals					IN	NUMBER
)
RETURN NUMBER
AS
	v_min_len						NUMBER;
	v_max_len						NUMBER;
	v_total_periods					NUMBER;
	v_min_period_number				NUMBER;
	v_total_intervals				NUMBER;
BEGIN
	SELECT MIN(start_period_id) min_period_number,
		   MIN(end_period_id - start_period_id + 1) min_len,
		   MAX(end_period_id - start_period_id + 1) max_len,
		   SUM(end_period_id - start_period_id + 1) total_periods,
		   COUNT(*) total_intervals
	  INTO v_min_period_number, v_min_len, v_max_len, v_total_periods, v_total_intervals
	  FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id;
	   
	-- This is a fixed interval, so we can just do simple maths
	IF v_min_len = v_max_len THEN
		RETURN in_period_number + v_min_len * in_intervals;
	END IF;
	
	-- XXX: not sure what I was thinking in the c# code -- we can't
	-- have non-aligned period numbers where intervals don't have consistent
	-- lengths, so we should be dealing with a snapped interval anyway?
	
	-- TODO: these have some commonalities (querying the period set for info)
	-- so we could merge them to optimise the code
	RETURN GetPeriodNumber(in_period_set_id, in_period_interval_id,
			GetIntervalNumber(in_period_set_id, in_period_interval_id, in_period_number) + in_intervals);
END;

FUNCTION AddIntervals(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE,
	in_intervals					IN	NUMBER
)
RETURN DATE
AS
BEGIN
	RETURN GetPeriodDate(in_period_set_id, 
				AddIntervals(in_period_set_id, in_period_interval_id, 
					GetPeriodNumber(in_period_set_id, in_dtm), in_intervals));
END;

FUNCTION GetIntervalPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_interval_number				IN	NUMBER
)
RETURN NUMBER
AS
	v_total_intervals				NUMBER;
BEGIN
	SELECT COUNT(*) total_intervals
	  INTO v_total_intervals
	  FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id;

	RETURN in_interval_number - v_total_intervals;	
END;

FUNCTION GetIntervalPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE
AS
BEGIN
	RETURN GetPeriodDate(in_period_set_id,
				GetPeriodNumber(in_period_set_id, in_period_interval_id, 
					GetIntervalPreviousYear(in_period_set_id, in_period_interval_id, 
						GetIntervalNumber(in_period_set_id, in_period_interval_id, in_dtm))));
END;

FUNCTION GetPeriodPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN NUMBER
AS
	v_total_periods						NUMBER;
BEGIN
	SELECT COUNT(*) total_periods
	  INTO v_total_periods
	  FROM period
	 WHERE period_set_id = in_period_set_id;

	RETURN in_period_number - v_total_periods;
END;

FUNCTION GetPeriodPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE
AS
BEGIN
	RETURN GetPeriodDate(in_period_set_id,
				GetPeriodPreviousYear(in_period_set_id,
					GetPeriodNumber(in_period_set_id, in_dtm)));
END;

FUNCTION AggregateOverTime(
	in_cur					IN	SYS_REFCURSOR,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_period_set_id		IN	period_set.period_set_id%TYPE,
	in_peiod_interval_id	IN	period_interval.period_interval_id%TYPE,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE
AS
	v_region_sid			security_pkg.T_SID_ID;
	v_start_dtm				val.period_start_dtm%TYPE;
	v_end_dtm				val.period_end_dtm%TYPE;
	v_val_number			val.val_number%TYPE;
	v_input_tbl				T_NORMALISED_VAL_TABLE := T_NORMALISED_VAL_TABLE();
BEGIN
	LOOP
		FETCH in_cur INTO v_region_sid, v_start_dtm, v_end_dtm, v_val_number;
		EXIT WHEN in_cur%NOTFOUND;
		v_input_tbl.EXTEND;
		v_input_tbl(v_input_tbl.COUNT) := T_NORMALISED_VAL_ROW(v_region_sid, v_start_dtm, v_end_dtm, v_val_number);
	END LOOP;
	
	RETURN AggregateOverTime(
		v_input_tbl,
		in_start_dtm,
		in_end_dtm,
		in_period_set_id,
		in_peiod_interval_id,
		in_divisibility
	);
END;

-- Populates temp_period_dtms with annual period dates for given date range
PROCEDURE GenerateAnnualPeriodDates(
	in_period_set_id		IN	period_set.period_set_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
) AS
BEGIN
	-- Generate some period dates in the specified date range
	-- (only if the specified period set has the annual_periods flag set)
	FOR r IN (
		SELECT period_set_id
		  FROM period_set
		 WHERE period_set_id = in_period_set_id
		   AND annual_periods = 1
	) LOOP
		-- XXX: This might need extending as it assumes that periods in the annual 
		-- periods set are one month long and that period id = 1 is in January.
		DELETE FROM temp_period_dtms;
		INSERT INTO temp_period_dtms (period_id, year, start_dtm, end_dtm)
		  SELECT period_id, EXTRACT (YEAR FROM start_dtm) year, start_dtm, ADD_MONTHS(start_dtm, 1) end_dtm
			  FROM (
			  SELECT MOD(LEVEL-1, 12) + 1 period_id, ADD_MONTHS(TRUNC(in_start_dtm, 'MONTH'), LEVEL - 1) start_dtm
				FROM DUAL
				CONNECT BY LEVEL <= MONTHS_BETWEEN (TRUNC(in_end_dtm, 'MONTH'), TRUNC(in_start_dtm, 'MONTH')) + 1
			  );
	END LOOP;
END;

FUNCTION AggregateOverTime(
	in_tbl					IN	T_NORMALISED_VAL_TABLE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE,
	in_period_set_id		IN	period_set.period_set_id%TYPE,
	in_peiod_interval_id	IN	period_interval.period_interval_id%TYPE,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE
AS
	v_output_tbl			T_NORMALISED_VAL_TABLE := T_NORMALISED_VAL_TABLE();
	v_start_dtm				DATE;
	v_end_dtm				DATE;
	v_duration				NUMBER;
	v_ip_period_duration	NUMBER;
	v_val_duration			NUMBER;
	v_aggr					val.val_number%TYPE;
BEGIN
	-- Generate some period dates in the output range if required
	GenerateAnnualPeriodDates(in_period_set_id, in_start_dtm, in_end_dtm);
	
	-- For each output period interval...
	FOR op IN (
		-- This part selects out the dates for arbitrary period intervals (should be mutually exclusive with below)
		SELECT start_dtm, end_dtm
		  FROM (
			SELECT spd.start_dtm, epd.end_dtm --, m.period_set_id, m.period_interval_id, m.start_period_id, m.end_period_id
			  FROM period_interval_member m
			  JOIN period_set s ON s.period_set_id = m.period_set_id AND annual_periods = 0
			  JOIN period sp ON sp.period_set_id = m.period_set_id AND sp.period_id = m.start_period_id
			  JOIN period_dates spd ON spd.period_set_id = m.period_set_id AND spd.period_id = sp.period_id
			  JOIN period ep ON ep.period_set_id = m.period_set_id AND ep.period_id = m.end_period_id
			  JOIN period_dates epd ON epd.period_set_id = m.period_set_id AND epd.period_id = ep.period_id
			WHERE m.period_set_id = in_period_set_id
			  AND m.period_interval_id = in_peiod_interval_id
			  AND spd.year = epd.year
			UNION
			-- This part selects out the dates for annual period intervals (should be mutually exclusive with above)
			SELECT spd.start_dtm, epd.end_dtm --, m.period_set_id, m.period_interval_id, m.start_period_id, m.end_period_id
			  FROM period_interval_member m
			  JOIN period_set s ON s.period_set_id = m.period_set_id AND annual_periods = 1
			  JOIN period sp ON sp.period_set_id = m.period_set_id AND sp.period_id = m.start_period_id
			  JOIN period ep ON ep.period_set_id = m.period_set_id AND ep.period_id = m.end_period_id
			  JOIN temp_period_dtms spd ON spd.period_id = sp.period_id
			  JOIN temp_period_dtms epd ON epd.period_id = ep.period_id
			 WHERE m.period_set_id = in_period_set_id
			   AND m.period_interval_id = in_peiod_interval_id
			   AND spd.year = epd.year
		 )
		 WHERE start_dtm < in_end_dtm
		   AND end_dtm > in_start_dtm
			ORDER BY start_dtm
	) LOOP
		-- For each region...
		FOR r IN (
			SELECT DISTINCT region_sid
			  FROM TABLE(in_tbl)
		) LOOP
			
			v_aggr := NULL;
			v_val_duration := 0;
			
			-- For each overlapping input period...
			FOR ip IN (
				SELECT start_dtm, end_dtm, val_number
				  FROM TABLE(in_tbl)
				 WHERE region_sid = r.region_sid
				   AND start_dtm < op.end_dtm
				   AND end_dtm > op.start_dtm  
					ORDER BY start_dtm
			) LOOP
				-- Normalise and aggregate the input data into the output period:
				-- crop date off either side of our period
				v_start_dtm := GREATEST(op.start_dtm, ip.start_dtm);
				v_end_dtm := LEAST(op.end_dtm, ip.end_dtm);
				
				-- get duration in days
				v_duration := TRUNC(v_end_dtm, 'DD') - TRUNC(v_start_dtm, 'DD');
				
				-- set the actual value
				IF in_divisibility = csr_data_pkg.DIVISIBILITY_DIVISIBLE THEN
					-- if divisible, then get a proportional value for this period
					v_ip_period_duration := TRUNC(ip.end_dtm, 'DD') - TRUNC(ip.start_dtm, 'DD');
					IF ip.val_number IS NOT NULL THEN
						v_aggr := NVL(v_aggr, 0) + ip.val_number * v_duration / v_ip_period_duration;
					END IF;
					
				ELSIF in_divisibility = csr_data_pkg.DIVISIBILITY_LAST_PERIOD THEN
					-- we want to use the last value for the period
					-- e.g. Q1, Q2, Q3, Q4 << we take Q4 value
					IF ip.val_number IS NOT NULL THEN
						v_aggr := ip.val_number;
					END IF;

				ELSIF in_divisibility = csr_data_pkg.DIVISIBILITY_AVERAGE THEN
					-- if not divisible, then average this out over differing periods for val
					IF v_val_duration + v_duration = 0 THEN
						v_aggr := 0;
					ELSE
						v_aggr := (NVL(v_aggr, 0) * v_val_duration + ip.val_number * v_duration) / (v_val_duration + v_duration);
						v_val_duration := v_val_duration + v_duration;
					END IF;
				END IF;
				
			END LOOP;
			
			-- Add ouptut row
			v_output_tbl.EXTEND;
			v_output_tbl(v_output_tbl.COUNT) := T_NORMALISED_VAL_ROW(r.region_sid, op.start_dtm, op.end_dtm, v_aggr);
			
		END LOOP;
	END LOOP;
	
	RETURN v_output_tbl;
END;

FUNCTION TruncToPeriod(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE,
	in_add_periods					IN	NUMBER DEFAULT 0
)
RETURN DATE
AS
BEGIN
	RETURN GetPeriodDate(
		in_period_set_id,
		GetPeriodNumber(
			in_period_set_id,
			in_dtm
		) + in_add_periods
	);
END;
	
FUNCTION TruncToPeriodStart(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE
AS
BEGIN
	RETURN TruncToPeriod(in_period_set_id, in_dtm, 0);
END;

FUNCTION TruncToPeriodEnd(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE
AS
BEGIN
	RETURN TruncToPeriod(in_period_set_id, in_dtm, 1);
END;

PROCEDURE AmendPeriodInterval(
	in_period_set_id		IN  period_set.period_set_id%TYPE,
	in_period_interval_id	IN  period_interval.period_interval_id%TYPE,
	in_single_int_label		IN  period_interval.single_interval_label%TYPE,
	in_multiple_int_label	IN  period_interval.multiple_interval_label%TYPE,
	in_single_int_ny_label	IN  period_interval.single_interval_no_year_label%TYPE
) AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring period set intervals, only super admins can do this.');
	END IF;

	UPDATE period_interval
	   SET single_interval_label = in_single_int_label,
	       single_interval_no_year_label = in_single_int_ny_label,
		   multiple_interval_label = in_multiple_int_label
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AmendPeriodInterval Set {0}, Interval {1}', in_period_set_id, in_period_interval_id);
END;

PROCEDURE AddPeriodSet(
	in_annual_periods				IN	period_set.annual_periods%TYPE,
	in_label						IN	period_set.label%TYPE,
	out_period_set_id				OUT period.period_set_id%TYPE
)
AS
	v_period_set_id					NUMBER;
	v_cnt							NUMBER := 1;
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
	v_label							period_set.label%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can add period set.');
	END IF;

	SELECT MAX(period_set_id)
	  INTO v_period_set_id
	  FROM period_set
	 WHERE app_sid = v_app_sid;
	
	v_label := in_label;
	
	WHILE v_cnt != 0 LOOP
		SELECT COUNT(*)
		  INTO v_cnt
		  FROM period_set
		 WHERE TRIM(label) = TRIM(v_label);
		
		IF v_cnt > 0 THEN
			v_label := TRIM(v_label) || ' New';
		END IF;
	END LOOP;
	
	INSERT INTO period_set
		(period_set_id, annual_periods, label)
	VALUES
		(v_period_set_id + 1, in_annual_periods, v_label);

	out_period_set_id := v_period_set_id + 1;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AddPeriodSet Set {0}, label {1}', out_period_set_id, v_label);
END;

PROCEDURE UpdatePeriodSet(
	in_period_set_id			IN	period_set.period_set_id%TYPE,
	in_annual_periods			IN	period_set.annual_periods%TYPE,
	in_label					IN	period_set.label%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can update period set.');
	END IF;

	UPDATE period_set
	   SET annual_periods = in_annual_periods,
	   	   label = in_label
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'UpdatePeriodSet Set {0}, label {1}', in_period_set_id, in_label);
END;

PROCEDURE DeletePeriodSet(
	in_period_set_id			IN	period_set.period_set_id%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period set.');
	END IF;
	
	DELETE FROM period_interval_member 
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;
	
	DELETE FROM period_interval 
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;
	
	DELETE FROM period_dates 
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;

	DELETE FROM period 
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;

	DELETE FROM period_set 
	 WHERE period_set_id = in_period_set_id 
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeletePeriodSet Set {0}', in_period_set_id);
END;

PROCEDURE AddPeriod(
	in_period_set_id			IN	period.period_set_id%TYPE,
	in_label					IN	period.label%TYPE,
	in_start_dtm				IN	period.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm					IN	period.end_dtm%TYPE DEFAULT NULL,
	out_period_id				OUT period.period_id%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
	v_period_id 				period.period_id%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can add period.');
	END IF;

	SELECT MAX(period_id)
	  INTO v_period_id
	  FROM period
	 WHERE period_set_id = in_period_set_id
	   AND app_sid = v_app_sid;

	IF v_period_id IS NULL THEN
		v_period_id := 1;
	ELSE
		v_period_id := v_period_id + 1;
	END IF;

	INSERT INTO period
		(period_set_id, period_id, label, start_dtm, end_dtm)
	VALUES
		(in_period_set_id, v_period_id, in_label, in_start_dtm, in_end_dtm);
	
	out_period_id := v_period_id;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AddPeriod for set {0}, id {1} label {2} for '||in_start_dtm||' - '||in_end_dtm, in_period_set_id, out_period_id, in_label);
END;

PROCEDURE UpdatePeriod(
	in_period_set_id			IN	period.period_set_id%TYPE,
	in_period_id				IN	period.period_id%TYPE,
	in_label					IN	period.label%TYPE,
	in_start_dtm				IN	period.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm					IN	period.end_dtm%TYPE DEFAULT NULL
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can update period.');
	END IF;

	UPDATE period
	   SET label = in_label,
		   start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm
	 WHERE period_set_id = in_period_set_id 
	   AND period_id = in_period_id
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'UpdatePeriod for set {0}, id {1} label {2} to '||in_start_dtm||' - '||in_end_dtm, in_period_set_id, in_period_id, in_label);
END;

PROCEDURE DeletePeriod(
	in_period_set_id			IN	period.period_set_id%TYPE,
	in_period_id				IN	period.period_id%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period.');
	END IF;

	DELETE FROM period_interval_member 
	 WHERE period_set_id = in_period_set_id 
	   AND start_period_id = in_period_id 
	   AND app_sid = v_app_sid;

	DELETE FROM period_dates 
	 WHERE period_set_id = in_period_set_id 
	   AND period_id = in_period_id 
	   AND app_sid = v_app_sid;

	DELETE FROM period 
	 WHERE period_set_id = in_period_set_id 
	   AND period_id = in_period_id 
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeletePeriod for set {0}, id {1}', in_period_set_id, in_period_id);
END;

PROCEDURE AddPeriodDates(
	in_period_set_id			IN	period_dates.period_set_id%TYPE,
	in_period_id				IN	period_dates.period_id%TYPE,
	in_year						IN	period_dates.year%TYPE,
	in_start_dtm				IN	period_dates.start_dtm%TYPE,
	in_end_dtm					IN	period_dates.end_dtm%TYPE
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can add period dates.');
	END IF;

	-- truncate dtm's to date component as s++ will error if the time components are nonzero
	INSERT INTO period_dates
		(period_set_id, period_id, year, start_dtm, end_dtm)
	VALUES
		(in_period_set_id, in_period_id, in_year, TRUNC(in_start_dtm),  TRUNC(in_end_dtm));

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AddPeriodDates for set {0}, id {1} for '||in_year||':'||in_start_dtm||' - ' ||in_end_dtm, in_period_set_id, in_period_id);
END;

PROCEDURE UpdatePeriodDates(
	in_period_set_id			IN	period_dates.period_set_id%TYPE,
	in_period_id				IN	period_dates.period_id%TYPE,
	in_year						IN	period_dates.year%TYPE,
	in_start_dtm				IN	period_dates.start_dtm%TYPE,
	in_end_dtm					IN	period_dates.end_dtm%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can update period dates.');
	END IF;

	-- truncate dtm's to date component as s++ will error if the time components are nonzero
	UPDATE period_dates
	   SET start_dtm = TRUNC(in_start_dtm),
		   end_dtm = TRUNC(in_end_dtm)
	 WHERE period_set_id = in_period_set_id 
	   AND period_id = in_period_id
	   AND year = in_year
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'UpdatePeriodDates for set {0}, id {1} year '||in_year||' to '||in_start_dtm||' - ' ||in_end_dtm, in_period_set_id, in_period_id);
END;

PROCEDURE DeletePeriodDates(
	in_period_set_id			IN	period_dates.period_set_id%TYPE,
	in_period_id				IN	period_dates.period_id%TYPE,
	in_year						IN	period_dates.year%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period dates.');
	END IF;

	DELETE FROM period_dates
	 WHERE period_set_id = in_period_set_id
	   AND period_id = in_period_id
	   AND year = in_year
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeletePeriodDates for set {0}, id {1} year '||in_year, in_period_set_id, in_period_id);
END;

PROCEDURE DeleteAllPeriodDates(
	in_period_set_id			IN	period_dates.period_set_id%TYPE
)
AS
	v_app_sid					security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period dates.');
	END IF;

	DELETE FROM period_dates
	 WHERE period_set_id = in_period_set_id
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeleteAllPeriodDates for set {0}', in_period_set_id);
END;

PROCEDURE AddPeriodInterval(
	in_period_set_id							IN	period_interval.period_set_id%TYPE,
	in_single_interval_label					IN	period_interval.single_interval_label%TYPE,
	in_multiple_interval_label					IN	period_interval.multiple_interval_label%TYPE,
	in_label									IN	period_interval.label%TYPE,
	in_single_interval_no_year_label			IN	period_interval.single_interval_no_year_label%TYPE,
	out_period_interval_id						OUT period_interval.period_interval_id%TYPE
)
AS
	v_app_sid									security_pkg.T_SID_ID := security_pkg.GetApp;
	v_period_interval_id						NUMBER;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can add period interval.');
	END IF;
	
	SELECT MAX(period_interval_id)
	  INTO v_period_interval_id
	  FROM period_interval
	 WHERE period_set_id = in_period_set_id
	   AND app_sid = v_app_sid;

	IF v_period_interval_id IS NULL THEN
		v_period_interval_id := 1;
	ELSE
		v_period_interval_id := v_period_interval_id + 1;
	END IF;
	
	INSERT INTO period_interval
		(period_set_id, period_interval_id, single_interval_label, multiple_interval_label, label, single_interval_no_year_label)
	VALUES
		(in_period_set_id, v_period_interval_id, in_single_interval_label, in_multiple_interval_label, in_label, in_single_interval_no_year_label);
		
	out_period_interval_id := v_period_interval_id;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AddPeriodInterval for set {0} id {1}', in_period_set_id, out_period_interval_id);
END;

PROCEDURE UpdatePeriodInterval(
	in_period_set_id							IN	period_interval.period_set_id%TYPE,
	in_period_interval_id						IN	period_interval.period_interval_id%TYPE,
	in_single_interval_label					IN	period_interval.single_interval_label%TYPE,
	in_multiple_interval_label					IN	period_interval.multiple_interval_label%TYPE,
	in_label									IN	period_interval.label%TYPE,
	in_single_interval_no_year_label			IN	period_interval.single_interval_no_year_label%type
)
AS
	v_app_sid									security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can update period interval.');
	END IF;

	UPDATE period_interval
	   SET single_interval_label = in_single_interval_label,
	   	   multiple_interval_label = in_multiple_interval_label,
	   	   label = in_label,
	   	   single_interval_no_year_label = in_single_interval_no_year_label
	 WHERE period_set_id = in_period_set_id 
	   AND period_interval_id = in_period_interval_id
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'UpdatePeriodInterval for set {0} id {1}', in_period_set_id, in_period_interval_id);
END;

PROCEDURE DeletePeriodInterval(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE
)
AS
	v_app_sid						security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period interval.');
	END IF;

	DELETE FROM period_interval_member
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id
	   AND app_sid = v_app_sid;

	DELETE FROM period_interval
	 WHERE period_set_id = in_period_set_id
	   AND period_interval_id = in_period_interval_id
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeletePeriodInterval for set {0} id {1}', in_period_set_id, in_period_interval_id);
END;


PROCEDURE AddPeriodIntervalMember(
	in_period_set_id									IN	period_interval_member.period_set_id%TYPE,
	in_period_interval_id								IN	period_interval_member.period_interval_id%TYPE,
	in_start_period_id									IN	period_interval_member.start_period_id%TYPE,
	in_end_period_id									IN	period_interval_member.end_period_id%TYPE
)
AS
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can add period interval member.');
	END IF;

	INSERT INTO period_interval_member
		(period_set_id, period_interval_id, start_period_id, end_period_id)
	VALUES
		(in_period_set_id, in_period_interval_id, in_start_period_id, in_end_period_id);

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'AddPeriodIntervalMember for set {0} id {1} for '||in_start_period_id||' - '||in_end_period_id, in_period_set_id, in_period_interval_id);
END;

PROCEDURE DeletePeriodIntervalMembers(
	in_period_set_id					IN	period_interval_member.period_set_id%TYPE,
	in_period_interval_id				IN	period_interval_member.period_interval_id%TYPE
)
AS
	v_app_sid							security_pkg.T_SID_ID := security_pkg.GetApp;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Only superadmins can delete period interval member.');
	END IF;

	DELETE FROM period_interval_member
	 WHERE period_set_id = in_period_set_id 
	   AND period_interval_id = in_period_interval_id
	   AND app_sid = v_app_sid;

	csr_data_pkg.WriteAuditLogEntry(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_PERIOD_SET, SYS_CONTEXT('SECURITY', 'APP'), SYS_CONTEXT('SECURITY', 'SID'), 
		'DeletePeriodIntervalMember for set {0} id {1}', in_period_set_id, in_period_interval_id);
END;

END period_pkg;
/

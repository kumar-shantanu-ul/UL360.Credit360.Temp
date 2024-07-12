CREATE OR REPLACE PACKAGE BODY csr.period_span_pattern_pkg IS

FUNCTION MakePeriodSpanPattern(
	in_period_span_pattern_type_id	IN	period_span_pattern.period_span_pattern_type_id%TYPE DEFAULT 2,
	in_period_set_id				IN	period_span_pattern.period_set_id%TYPE DEFAULT 1,
	in_period_interval_id			IN	period_span_pattern.period_interval_id%TYPE DEFAULT 1,
	in_date_from					IN	period_span_pattern.date_from%TYPE DEFAULT NULL,
	in_date_to						IN	period_span_pattern.date_to%TYPE DEFAULT NULL,
	in_periods_offset_from_now		IN	period_span_pattern.periods_offset_from_now%TYPE DEFAULT 0,
	in_number_rolling_periods		IN	period_span_pattern.number_rolling_periods%TYPE DEFAULT 0,
	in_period_in_year				IN	period_span_pattern.period_in_year%TYPE DEFAULT 0,
	in_year_offset					IN	period_span_pattern.year_offset%TYPE DEFAULT 0,
	in_period_in_year_2				IN	period_span_pattern.period_in_year_2%TYPE DEFAULT 0,
	in_year_offset_2				IN	period_span_pattern.year_offset_2%TYPE DEFAULT 0
) RETURN NUMBER
AS
	v_id		NUMBER;
BEGIN

	SELECT period_span_pattern_id_seq.nextval
	  INTO v_id
	  FROM DUAL;
	
	INSERT INTO period_span_pattern
		(period_span_pattern_id, period_span_pattern_type_id, period_set_id, period_interval_id, date_from, date_to, periods_offset_from_now, number_rolling_periods,
		 period_in_year, year_offset, period_in_year_2, year_offset_2)
	VALUES
		(v_id, in_period_span_pattern_type_id, in_period_set_id, in_period_interval_id, in_date_from, in_date_to, in_periods_offset_from_now, in_number_rolling_periods,
		 in_period_in_year, in_year_offset, in_period_in_year_2, in_year_offset_2);

	RETURN v_id;
	
END;

PROCEDURE UpdatePeriodSpanPattern(
	in_period_span_pattern_id		IN period_span_pattern.period_span_pattern_id%TYPE,
	in_period_span_pattern_type_id	IN period_span_pattern.period_span_pattern_type_id%TYPE, 
	in_period_interval_id			IN period_span_pattern.period_interval_id%TYPE, 
	in_period_set_id				IN period_span_pattern.period_set_id%TYPE, 
	in_from_date					IN period_span_pattern.date_from%TYPE,
	in_to_date						IN period_span_pattern.date_to%TYPE, 
	in_offset						IN period_span_pattern.periods_offset_from_now%TYPE, 
	in_no_of_rolling_periods		IN period_span_pattern.number_rolling_periods%TYPE,
	in_period_in_year				IN period_span_pattern.period_in_year%TYPE,
	in_year_offset					IN period_span_pattern.year_offset%TYPE, 
	in_end_period_in_year			IN period_span_pattern.period_in_year_2%TYPE, 
	in_end_year_offset				IN period_span_pattern.year_offset_2%TYPE
)
AS
	v_period_span_pattern_type_id	period_span_pattern.period_span_pattern_type_id%TYPE;
	v_period_interval_id			period_span_pattern.period_interval_id%TYPE;
	v_period_set_id					period_span_pattern.period_set_id%TYPE;
	v_from_date						period_span_pattern.date_from%TYPE;
	v_to_date						period_span_pattern.date_to%TYPE;
	v_offset						period_span_pattern.periods_offset_from_now%TYPE;
	v_no_of_rolling_periods			period_span_pattern.number_rolling_periods%TYPE;
	v_period_in_year				period_span_pattern.period_in_year%TYPE;
	v_year_offset					period_span_pattern.year_offset%TYPE;
	v_end_period_in_year			period_span_pattern.period_in_year_2%TYPE;
	v_end_year_offset				period_span_pattern.year_offset_2%TYPE;
BEGIN
	IF NOT (csr_user_pkg.IsSuperAdmin = 1 OR security.security_pkg.IsAdmin(security.security_pkg.GetAct)) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied configuring exporters, only BuiltinAdministrator or super admins can run this.');
	END IF;
	
	BEGIN
		SELECT period_span_pattern_type_id, period_interval_id, period_set_id, date_from, date_to, periods_offset_from_now,
			   number_rolling_periods, period_in_year, year_offset, period_in_year_2, year_offset_2
		  INTO v_period_span_pattern_type_id, v_period_interval_id, v_period_set_id, v_from_date, v_to_date, v_offset, v_no_of_rolling_periods,
			   v_period_in_year, v_year_offset, v_end_period_in_year, v_end_year_offset
		  FROM period_span_pattern 
		 WHERE period_span_pattern_id = in_period_span_pattern_id
		 AND   app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
		UPDATE period_span_pattern
		   SET period_span_pattern_type_id = in_period_span_pattern_type_id, period_interval_id = in_period_interval_id, 
			   period_set_id = in_period_set_id, date_from = in_from_date, date_to = in_to_date, periods_offset_from_now = in_offset,
			   number_rolling_periods = in_no_of_rolling_periods, period_in_year = in_period_in_year, year_offset = in_year_offset,
			   period_in_year_2 = in_end_period_in_year, year_offset_2 = in_end_year_offset
		 WHERE period_span_pattern_id = in_period_span_pattern_id
		 AND   app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'period span pattern type id', in_period_span_pattern_type_id, v_period_span_pattern_type_id);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'period interval id', in_period_interval_id, v_period_interval_id);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'period set id', in_period_set_id, v_period_set_id);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'from date', in_from_date, v_from_date);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'to date', in_to_date, v_to_date);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'offset', in_offset, v_offset);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'no of rolling periods', in_no_of_rolling_periods, v_no_of_rolling_periods);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'period in year', in_period_in_year, v_period_in_year);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'year offset', in_year_offset, v_year_offset);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'end period in year', in_end_period_in_year, v_end_period_in_year);
		period_span_pattern_pkg.AuditValue(in_period_span_pattern_id, 'end year offset', in_end_year_offset, v_end_year_offset);

	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'An export class with that name already exists.');
	END;
END;

PROCEDURE GetPeriodSpanPattern(
	in_period_span_pattern_id		IN	period_span_pattern.period_span_pattern_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT period_span_pattern_id, period_span_pattern_type_id, period_interval_id, period_set_id, date_from, date_to, 
			   periods_offset_from_now, number_rolling_periods, period_in_year, year_offset, period_in_year_2, year_offset_2
		  FROM period_span_pattern
		 WHERE period_span_pattern_id = in_period_span_pattern_id;
END;

PROCEDURE GetPeriodSpanPatternTypes(
	out_cur			OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT period_span_pattern_type_id, label
		  FROM csr.period_span_pattern_type
		 ORDER BY label ASC;
END;

-- AUDIT LOGGING
PROCEDURE AuditValue(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			VARCHAR2,
	in_old_val			VARCHAR2
)
AS
BEGIN
	csr_data_pkg.AuditValueChange(SYS_CONTEXT('SECURITY', 'ACT'), csr_data_pkg.AUDIT_TYPE_EXPIMP_AUTO_EXPORT, SYS_CONTEXT('SECURITY', 'APP'), in_class_sid, in_field, in_old_val, in_new_val);
END;
-- END AUDIT LOGGING

END;
/

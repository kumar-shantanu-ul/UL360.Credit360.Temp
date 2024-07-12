CREATE OR REPLACE PACKAGE csr.period_span_pattern_pkg IS

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
) RETURN NUMBER;

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
	in_end_period_in_year				IN period_span_pattern.period_in_year_2%TYPE, 
	in_end_year_offset				IN period_span_pattern.year_offset_2%TYPE
);

PROCEDURE GetPeriodSpanPattern(
	in_period_span_pattern_id		IN	period_span_pattern.period_span_pattern_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetPeriodSpanPatternTypes(
	out_cur			OUT SYS_REFCURSOR
);

PROCEDURE AuditValue(
	in_class_sid		NUMBER,
	in_field			VARCHAR2,
	in_new_val			VARCHAR2,
	in_old_val			VARCHAR2
);

END period_span_pattern_pkg;
/

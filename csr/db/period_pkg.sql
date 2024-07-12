CREATE OR REPLACE PACKAGE CSR.period_pkg AS

PROCEDURE GetPeriodSets(
	out_period_set_cur				OUT	SYS_REFCURSOR,
	out_period_cur					OUT SYS_REFCURSOR,
	out_period_dates_cur			OUT	SYS_REFCURSOR,
	out_period_interval_cur			OUT	SYS_REFCURSOR,
	out_period_interval_memb_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetPeriodSet(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	out_period_set_cur				OUT SYS_REFCURSOR,
	out_period_cur					OUT SYS_REFCURSOR,
	out_period_dates_cur			OUT SYS_REFCURSOR,
	out_period_interval_cur			OUT SYS_REFCURSOR,
	out_period_interval_memb_cur	OUT SYS_REFCURSOR
);

FUNCTION GetIntervalNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN NUMBER;

FUNCTION GetIntervalNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN NUMBER;

FUNCTION GetPeriodNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_interval_number				IN	NUMBER
)
RETURN NUMBER;

FUNCTION GetPeriodNumber(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN NUMBER;

FUNCTION GetPeriodDate(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN DATE;

FUNCTION AddIntervals(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER,
	in_intervals					IN	NUMBER
)
RETURN NUMBER;

FUNCTION AddIntervals(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE,
	in_intervals					IN	NUMBER
)
RETURN DATE;

FUNCTION GetIntervalPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_interval_number				IN	NUMBER
)
RETURN NUMBER;

FUNCTION GetIntervalPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE;

FUNCTION GetPeriodPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_period_number				IN	NUMBER
)
RETURN NUMBER;

FUNCTION GetPeriodPreviousYear(
	in_period_set_id				IN	period_interval.period_interval_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE;

PROCEDURE GenerateAnnualPeriodDates(
	in_period_set_id		IN	period_set.period_set_id%TYPE,
	in_start_dtm			IN	DATE,
	in_end_dtm				IN	DATE
);

FUNCTION AggregateOverTime(
	in_cur					IN	SYS_REFCURSOR,
	in_start_dtm 			IN	DATE,
	in_end_dtm				IN	DATE,
    in_period_set_id		IN	period_set.period_set_id%TYPE,
    in_peiod_interval_id	IN	period_interval.period_interval_id%TYPE,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE;

FUNCTION AggregateOverTime(
	in_tbl					IN	T_NORMALISED_VAL_TABLE,
	in_start_dtm 			IN	DATE,
	in_end_dtm				IN	DATE,
    in_period_set_id		IN	period_set.period_set_id%TYPE,
    in_peiod_interval_id	IN	period_interval.period_interval_id%TYPE,
	in_divisibility			IN	NUMBER DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE
) RETURN T_NORMALISED_VAL_TABLE;

FUNCTION TruncToPeriod(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE,
	in_add_periods					IN	NUMBER DEFAULT 0
)
RETURN DATE;

FUNCTION TruncToPeriodStart(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE;

FUNCTION TruncToPeriodEnd(
	in_period_set_id				IN	period_interval.period_set_id%TYPE,
	in_dtm							IN	DATE
)
RETURN DATE;

PROCEDURE AmendPeriodInterval(
	in_period_set_id		IN  period_set.period_set_id%TYPE,
	in_period_interval_id	IN  period_interval.period_interval_id%TYPE,
	in_single_int_label		IN  period_interval.single_interval_label%TYPE,
	in_multiple_int_label	IN  period_interval.multiple_interval_label%TYPE,
	in_single_int_ny_label	IN  period_interval.single_interval_no_year_label%TYPE
);

PROCEDURE AddPeriodSet(
	in_annual_periods				IN	period_set.annual_periods%TYPE,
	in_label						IN	period_set.label%TYPE,
	out_period_set_id				OUT period.period_set_id%TYPE
);

PROCEDURE UpdatePeriodSet(
	in_period_set_id				IN	period_set.period_set_id%TYPE,
	in_annual_periods				IN	period_set.annual_periods%TYPE,
	in_label						IN	period_set.label%TYPE
);

PROCEDURE DeletePeriodSet(
	in_period_set_id				IN	period_set.period_set_id%TYPE
);

PROCEDURE AddPeriod(
	in_period_set_id				IN	period.period_set_id%TYPE,
	in_label						IN	period.label%TYPE,
	in_start_dtm					IN	period.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						IN	period.end_dtm%TYPE DEFAULT NULL,
	out_period_id					OUT period.period_id%TYPE
);

PROCEDURE UpdatePeriod(
	in_period_set_id				IN	period.period_set_id%TYPE,
	in_period_id					IN	period.period_id%TYPE,
	in_label						IN	period.label%TYPE,
	in_start_dtm					IN	period.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm						IN	period.end_dtm%TYPE DEFAULT NULL
);

PROCEDURE DeletePeriod(
	in_period_set_id				IN	period.period_set_id%TYPE,
	in_period_id					IN	period.period_id%TYPE
);

PROCEDURE AddPeriodDates(
	in_period_set_id				IN	period_dates.period_set_id%TYPE,
	in_period_id					IN	period_dates.period_id%TYPE,
	in_year							IN	period_dates.year%TYPE,
	in_start_dtm					IN	period_dates.start_dtm%TYPE,
	in_end_dtm						IN	period_dates.end_dtm%TYPE
);

PROCEDURE UpdatePeriodDates(
	in_period_set_id				IN	period_dates.period_set_id%TYPE,
	in_period_id					IN	period_dates.period_id%TYPE,
	in_year							IN	period_dates.year%TYPE,
	in_start_dtm					IN	period_dates.start_dtm%TYPE,
	in_end_dtm						IN	period_dates.end_dtm%TYPE
);

PROCEDURE DeletePeriodDates(
	in_period_set_id				IN	period_dates.period_set_id%TYPE,
	in_period_id					IN	period_dates.period_id%TYPE,
	in_year							IN	period_dates.year%TYPE
);

PROCEDURE DeleteAllPeriodDates(
	in_period_set_id				IN	period_dates.period_set_id%TYPE
);

PROCEDURE AddPeriodInterval(
	in_period_set_id							IN	period_interval.period_set_id%TYPE,
	in_single_interval_label					IN	period_interval.single_interval_label%TYPE,
	in_multiple_interval_label					IN	period_interval.multiple_interval_label%TYPE,
	in_label									IN	period_interval.label%TYPE,
	in_single_interval_no_year_label			IN	period_interval.single_interval_no_year_label%TYPE,
	out_period_interval_id						OUT period_interval.period_interval_id%TYPE
);

PROCEDURE UpdatePeriodInterval(
	in_period_set_id						IN	period_interval.period_set_id%TYPE,
	in_period_interval_id					IN	period_interval.period_interval_id%TYPE,
	in_single_interval_label				IN	period_interval.single_interval_label%TYPE,
	in_multiple_interval_label				IN	period_interval.multiple_interval_label%TYPE,
	in_label								IN	period_interval.label%TYPE,
	in_single_interval_no_year_label		IN	period_interval.single_interval_no_year_label%type
);

PROCEDURE DeletePeriodInterval(
	in_period_set_id						IN	period_interval.period_set_id%TYPE,
	in_period_interval_id					IN	period_interval.period_interval_id%TYPE
);

PROCEDURE AddPeriodIntervalMember(
	in_period_set_id						IN	period_interval_member.period_set_id%TYPE,
	in_period_interval_id					IN	period_interval_member.period_interval_id%TYPE,
	in_start_period_id						IN	period_interval_member.start_period_id%TYPE,
	in_end_period_id						IN	period_interval_member.end_period_id%TYPE
);

PROCEDURE DeletePeriodIntervalMembers(
	in_period_set_id						IN	period_interval_member.period_set_id%TYPE,
	in_period_interval_id					IN	period_interval_member.period_interval_id%TYPE
);

END period_pkg;
/

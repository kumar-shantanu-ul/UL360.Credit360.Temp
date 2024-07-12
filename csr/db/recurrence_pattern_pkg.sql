CREATE OR REPLACE TYPE CSR.RECURRENCE_PATTERN AS OBJECT (	
	repeat_period		VARCHAR2(255), 			-- daily|weekly|monthly|yearly
	repeat_every 		NUMBER(10), 			-- null means no value
    repeat_weekday      NUMBER(1),
	weekly_days			T_RECURRENCE_DAYS, 		-- monday/tuesday etc
	day_varying_type	VARCHAR2(255), 			-- first/last/etc
	day_varying_day		VARCHAR2(255), 			-- monday/tuesday/wednesday etc
	day_varying_month	VARCHAR2(255), 			-- apr/may etc
	day_number			NUMBER(10), 			-- 2
	day_month			VARCHAR2(255), 			-- apr/may etc
	x_day_b_number		NUMBER(10),				-- 2 (used as '2 days before end of period')
	x_day_b_month		VARCHAR2(255),			-- apr/may etc
	start_dtm			DATE,
	end_dtm				DATE,
	occurrences			T_RECURRENCE_DATES,
	
	CONSTRUCTOR FUNCTION RECURRENCE_PATTERN(
		SELF 							IN OUT NOCOPY RECURRENCE_PATTERN, 
		recurrence_pattern_xml 			IN XMLType
	) RETURN SELF AS RESULT,

	MEMBER FUNCTION WeekDay(
		in_dtm						IN	DATE
	) RETURN NUMBER,

    MEMBER PROCEDURE SetDaysOfWeek(
        in_days     					IN  T_RECURRENCE_DAYS
    ),

	MEMBER PROCEDURE SetRepeatPeriod(
		in_repeat_period				IN	VARCHAR2,
        in_repeat_every     			IN  NUMBER DEFAULT NULL
	),
    
	MEMBER PROCEDURE SetDay(
		in_day_number					IN	NUMBER,
        in_day_month    				IN  VARCHAR2 DEFAULT NULL
	),
    
	MEMBER PROCEDURE SetDayVarying(
		in_day_varying_type				IN	VARCHAR2,
		in_day_varying_day				IN	VARCHAR2,
		in_day_varying_month			IN	VARCHAR2
	),
	
	MEMBER PROCEDURE SetMonth(
        in_month						IN  VARCHAR2
	),
	
	MEMBER FUNCTION GetXml RETURN XMLType,
	
	MEMBER FUNCTION GetClob RETURN CLOB,
	
	MEMBER FUNCTION IsDone(
		in_dtm							IN	DATE
	) RETURN BOOLEAN,
	
	MEMBER FUNCTION IsDoneMonthly(
		in_dtm							IN	DATE
	) RETURN BOOLEAN,
	
	MEMBER FUNCTION IsDoneDayVarying(
		in_dtm							IN	DATE
	) RETURN BOOLEAN,
	
	MEMBER FUNCTION IsEqual(
		in_pattern		IN	RECURRENCE_PATTERN
	) RETURN BOOLEAN,
	
	MEMBER FUNCTION MonthToMonthNumber(
		in_month						IN	VARCHAR2
	) RETURN NUMBER,
	
	MEMBER FUNCTION DayToDayNumber(
		in_day							IN	VARCHAR2
	) RETURN NUMBER,
	
	MEMBER FUNCTION DayNumberToDay(
		in_day_number					IN	NUMBER
	) RETURN VARCHAR2,
	
	MEMBER FUNCTION OrdinalToNumber(
		in_ordinal						IN	VARCHAR2
	) RETURN NUMBER,

	MEMBER PROCEDURE DoMakeOccurrencesXDaysBefore,
	MEMBER PROCEDURE DoMakeOccurrencesHourly,
	MEMBER PROCEDURE DoMakeOccurrencesDaily,
	MEMBER PROCEDURE DoMakeOccurrencesWeekly,
	MEMBER PROCEDURE DoMakeOccurrencesMonthly,
	MEMBER PROCEDURE DoMakeOccurrencesYearly,
	MEMBER PROCEDURE DoMakeOccurrencesDayVarying,
	MEMBER PROCEDURE DoMakeOccurrences,
	
	MEMBER FUNCTION MakeOccurrences(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_start_dtm					IN	DATE,
		in_end_dtm						IN	DATE
	)
	RETURN T_RECURRENCE_DATES,
	
	MEMBER PROCEDURE MakeOccurrences(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_start_dtm					IN	DATE,
		in_end_dtm						IN	DATE
	),

	MEMBER FUNCTION GetOccurrences(
		in_dtm							IN	DATE,
		in_include_on_dtm				IN	BOOLEAN
	)
	RETURN T_RECURRENCE_DATES,
	
	MEMBER FUNCTION GetOccurrencesAfter(
		in_dtm							IN	DATE
	)
	RETURN T_RECURRENCE_DATES,
	
	MEMBER FUNCTION GetOccurrencesOnOrAfter(
		in_dtm							IN	DATE
	)
	RETURN T_RECURRENCE_DATES,
	
	/* Added GetNext.. to allow peeking at upcoming occurrences without needing an end date or a full set of occurrences to be generated */
	MEMBER FUNCTION GetNextOccurrence(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_dtm							IN DATE
	)
	RETURN DATE,
	
	MEMBER FUNCTION GetNextHourlyOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextDailyOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextWeeklyOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextMonthlyOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextYearlyOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextDayVaryingOccurrence
	RETURN DATE,
	MEMBER FUNCTION GetNextXDaysBeforeOccurrence
	RETURN DATE
	
);
/

CREATE OR REPLACE PACKAGE  CSR.RECURRENCE_PATTERN_pkg
IS

FUNCTION GetNextOccurrence(
	in_recurrence_pattern_xml 			IN XMLType,
	in_dtm								IN DATE
) RETURN DATE;

END;
/

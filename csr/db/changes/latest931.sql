-- Please update version.sql too -- this keeps clean builds in sync
define version=931
@update_header

begin
	for r in (select type_name from all_types where owner='CSR' and type_name in ('RECURRENCE_PATTERN')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE CSR.'||r.type_name;
	end loop;
	for r in (select type_name from all_types where owner='CSR' and type_name in ('T_RECURRENCE_DAYS')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE CSR.'||r.type_name;
	end loop;
	for r in (select type_name from all_types where owner='CSR' and type_name in ('T_RECURRENCE_DATES')) loop
		--dbms_output.put_line('drop '||r.type_name);
		execute immediate 'DROP TYPE CSR.'||r.type_name;
	end loop;
end;
/

CREATE OR REPLACE TYPE CSR.T_RECURRENCE_DAYS AS TABLE OF VARCHAR2(100);
/
CREATE OR REPLACE TYPE CSR.T_RECURRENCE_DATES AS TABLE OF DATE;
/

-- hmm, not sure how object types should be treated -- having it pasted here won't hurt
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
	start_dtm			DATE,
	end_dtm				DATE,
	occurrences			T_RECURRENCE_DATES,
	
	CONSTRUCTOR FUNCTION RECURRENCE_PATTERN(
		SELF 							IN OUT NOCOPY RECURRENCE_PATTERN, 
		recurrence_pattern_xml 			IN XMLType
	) RETURN SELF AS RESULT,

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
	RETURN T_RECURRENCE_DATES	
);
/

CREATE OR REPLACE TYPE BODY CSR.RECURRENCE_PATTERN AS
	CONSTRUCTOR FUNCTION RECURRENCE_PATTERN(
		SELF 							IN OUT NOCOPY RECURRENCE_PATTERN, 
		recurrence_pattern_xml 			IN XMLType
	) RETURN SELF AS RESULT 
	IS
        v_repeat_every  VARCHAR2(255);
	BEGIN
		SELECT EXTRACT(recurrence_pattern_xml,'recurrences/node()').getRootElement(),	
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/@every-n').getStringVal()
		  INTO SELF.repeat_period, v_repeat_every
		  FROM DUAL;
		IF SELF.repeat_period IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'repeat_period must be daily, weekly, monthly or yearly');
		END IF;
		
        IF v_repeat_every = 'weekday' THEN
            SELF.repeat_weekday := 1;
            SELF.repeat_every := NULL;
        ELSE
            SELF.repeat_every := TO_NUMBER(v_repeat_every);
        END IF;
        
		-- pull out any weekly day nodes
		SELECT EXTRACT(VALUE(x),'node()').getRootElement()
		  BULK COLLECT INTO weekly_days
		  FROM TABLE(XMLSEQUENCE(EXTRACT(recurrence_pattern_xml,'recurrences/weekly/node()')))x
		  ;
		
		SELECT 
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/day-varying/@type').getStringVal(),
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/day-varying/@day').getStringVal(),
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/day-varying/@month').getStringVal()
		  INTO SELF.day_Varying_type, SELF.day_varying_day, SELF.day_varying_month
		  FROM DUAL;
		
		
		SELECT 
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/day/@number').getStringVal(),
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/day/@month').getStringVal()
		  INTO SELF.day_number, SELF.day_month
		  FROM DUAL;
		
		RETURN;
	END;
	
	MEMBER PROCEDURE SetRepeatPeriod(
		in_repeat_period	IN	VARCHAR2,
        in_repeat_every     IN  NUMBER DEFAULT NULL
	)
	IS
        v_cnt   NUMBER(10);
	BEGIN
        IF LOWER(in_repeat_period) NOT IN ('daily','weekly','monthly','yearly') THEN
            RAISE_APPLICATION_ERROR(-20001,'repeat-period must be one of "daily", "weekly", "monthly", "yearly"');
        END IF;
		SELF.repeat_period := LOWER(in_repeat_period);
        SELF.repeat_every := NVL(in_repeat_every,1);
        
        IF SELF.repeat_period IN ('daily','weekly') THEN
            -- clear out day and day varying            
            SELF.day_varying_type := NULL;
            SELF.day_varying_day := NULL;
            SELF.day_varying_month := NULL;
            SELF.day_number	:= NULL;
            SELF.day_month := NULL;
        ELSIF SELF.repeat_period IN ('monthly') THEN
            -- clear out year specific things
            SELF.day_month := NULL;
            SELF.day_varying_month := NULL;
        END IF;
	END;

    MEMBER PROCEDURE SetDaysOfWeek(
        in_days     					IN  T_RECURRENCE_DAYS
    )
    IS
        v_cnt   NUMBER(10);
    BEGIN
        IF SELF.repeat_period != 'weekly' THEN
            RAISE_APPLICATION_ERROR(-20001,'Cannot set days of week when repeat-period is "daily", "monthly" or "yearly"');
        END IF;

        SELECT COUNT(*) 
          INTO v_cnt 
          FROM TABLE(in_days)
         WHERE column_value NOT IN ('monday','tuesday','wednesday','thursday','friday','saturday','sunday');
        
        IF v_cnt > 0 THEN 
            RAISE_APPLICATION_ERROR(-20001,'Valid days of the week are: "monday", "tuesday", "wednesday", "thursday", "friday", "saturday" or "sunday"');
        END IF;
        
        SELF.weekly_days := in_days;
    END;

	MEMBER PROCEDURE SetDay(
		in_day_number					IN	NUMBER,
        in_day_month    				IN  VARCHAR2 DEFAULT NULL
	)
	IS        
	BEGIN
        IF SELF.repeat_period IN ('daily','weekly') THEN
            RAISE_APPLICATION_ERROR(-20001,'Cannot set day when repeat-period is "daily" or "weekly"');
        ELSIF SELF.repeat_period IN ('monthly') AND in_day_month IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20001,'Cannot set day-month when repeat-period is "monthly"');
        ELSIF in_day_number IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,'day-number must be set');        
        ELSIF (SELF.repeat_period = 'yearly' AND in_day_month IS NULL) OR in_day_month NOT IN ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec') THEN
            RAISE_APPLICATION_ERROR(-20001,'day-month must be one of "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", or "dec"');
        END IF;

        SELF.day_number := in_day_number;
        SELF.day_month := in_day_month;

        -- clear out day varying            
        SELF.day_varying_type := NULL;
        SELF.day_varying_day := NULL;
        SELF.day_varying_month := NULL;
	END;

	MEMBER PROCEDURE SetDayVarying(
		in_day_varying_type				IN	VARCHAR2,
		in_day_varying_day				IN	VARCHAR2,
		in_day_varying_month			IN	VARCHAR2
	)
	IS        
	BEGIN
        IF SELF.repeat_period IN ('daily','weekly') THEN
            RAISE_APPLICATION_ERROR(-20001,'Cannot set day-varying when repeat-period is "daily" or "weekly"');
        ELSIF SELF.repeat_period IN ('monthly') AND in_day_varying_month IS NOT NULL THEN
            RAISE_APPLICATION_ERROR(-20001,'Cannot set day-varying-month when repeat-period is "monthly"');
        ELSIF in_day_varying_type IS NULL OR LOWER(in_day_varying_type) NOT IN ('first','second','third','fourth','last') THEN
            RAISE_APPLICATION_ERROR(-20001,'day-varying-type must be one of "first", "second", "third", "fourth" or "last"');
        ELSIF in_day_varying_day IS NULL OR LOWER(in_day_varying_day) NOT IN ('monday','tuesday','wednesday','thursday','friday','saturday','sunday') THEN
            RAISE_APPLICATION_ERROR(-20001,'day-varying-day must be one of "monday", "tuesday", "wednesday", "thursday", "friday", "saturday" or "sunday"');
        ELSIF (SELF.repeat_period = 'yearly' AND in_day_varying_month IS NULL) OR in_day_varying_month NOT IN ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec') THEN
            RAISE_APPLICATION_ERROR(-20001,'day-varying-month must be one of "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", or "dec"');
        END IF;

        SELF.day_varying_type := LOWER(in_day_varying_type);
        SELF.day_varying_day := LOWER(in_day_varying_day);
        SELF.day_varying_month := LOWER(in_day_varying_month);

        -- clear out day 
        SELF.day_number := NULL;
        SELF.day_month := NULL;
	END;
	
	MEMBER PROCEDURE SetMonth(
        in_month    					IN  VARCHAR2
	)
	IS        
	BEGIN
        IF in_month NOT IN ('jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec') THEN
            RAISE_APPLICATION_ERROR(-20001,'day-month must be one of "jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", or "dec"');
        END IF;

        SELF.day_month := in_month;
	END;

	
	MEMBER FUNCTION GetXml RETURN XMLType
	IS
        v_result    XMLType;
    BEGIN 
        -- XMLAGG(XMLELEMENT(evalname column_value)) breaks with an ORA-600 error (due to evalname)
        SELECT
            XMLELEMENT("recurrences", 
                XMLELEMENT(evalname SELF.repeat_period, 
                    XMLATTRIBUTES((CASE WHEN SELF.repeat_weekday =1 THEN 'weekday' ELSE TO_CHAR(SELF.repeat_every) END) as "every-n"),
                    XMLAGG(XMLType('<'||column_value||'/>')),
                    CASE 
                    WHEN SELF.day_varying_type IS NOT NULL THEN
                        XMLELEMENT("day-varying", 
                            XMLATTRIBUTES(SELF.day_varying_type as "type", SELF.day_varying_day as "day", SELF.day_varying_month as "month"))
                    WHEN SELF.day_number IS NOT NULL THEN
                        XMLELEMENT("day", XMLATTRIBUTES(SELF.day_number as "number", SELF.day_month as "month"))
                    END                    
                )
            )
         INTO v_result
         FROM TABLE(SELF.weekly_days)
        ;
		RETURN v_result;
	END;
	
	MEMBER FUNCTION GetClob RETURN CLOB
	IS
		v_result CLOB;
	BEGIN
		SELECT EXTRACT(SELF.getXML,'/').getClobVal()
		  INTO v_result
		  FROM DUAL;
		
		RETURN v_result;
	END;
	
	MEMBER FUNCTION IsDone(
		in_dtm							IN	DATE
	)
	RETURN BOOLEAN
	AS
	BEGIN
		IF in_dtm IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'null date passed to IsDone');
		END IF;
		IF SELF.end_dtm IS NOT NULL AND in_dtm >= SELF.end_dtm THEN
			RETURN TRUE;
		END IF;
		/* occurrences not supported yet
		if (m_occurrences.Count >= m_maxOccurrences)
		{
			return true;
		} 
		*/
		RETURN FALSE;
	END;
	
	MEMBER FUNCTION MonthToMonthNumber(
		in_month						IN	VARCHAR2
	) RETURN NUMBER
	AS
	BEGIN
		IF in_month = 'jan' THEN
			RETURN 1;
		ELSIF in_month = 'feb' THEN
			RETURN 2;
		ELSIF in_month = 'mar' THEN
			RETURN 3;
		ELSIF in_month = 'apr' THEN
			RETURN 4;
		ELSIF in_month = 'may' THEN
			RETURN 5;
		ELSIF in_month = 'jun' THEN
			RETURN 6;
		ELSIF in_month = 'jul' THEN
			RETURN 7;
		ELSIF in_month = 'aug' THEN
			RETURN 8;
		ELSIF in_month = 'sep' THEN
			RETURN 9;
		ELSIF in_month = 'oct' THEN
			RETURN 10;
		ELSIF in_month = 'nov' THEN
			RETURN 11;
		ELSIF in_month = 'dec' THEN
			RETURN 12;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown month: '||in_month);
		END IF;
	END;
	
	MEMBER FUNCTION DayToDayNumber(
		in_day							IN	VARCHAR2
	) RETURN NUMBER
	AS
	BEGIN
		IF in_day = 'sunday' THEN
			RETURN 1;
		ELSIF in_day = 'monday' THEN
			RETURN 2;
		ELSIF in_day = 'tuesday' THEN
			RETURN 3;
		ELSIF in_day = 'wednesday' THEN
			RETURN 4;
		ELSIF in_day = 'thursday' THEN
			RETURN 5;
		ELSIF in_day = 'friday' THEN
			RETURN 6;
		ELSIF in_day = 'saturday' THEN
			RETURN 7;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown day: '||in_day);
		END IF;
	END;
	
	MEMBER FUNCTION DayNumberToDay(
		in_day_number					IN	NUMBER
	) RETURN VARCHAR2
	AS
	BEGIN
		IF in_day_number = 1 THEN
			RETURN 'sunday';
		ELSIF in_day_number = 2 THEN
			RETURN 'monday';
		ELSIF in_day_number = 3 THEN
			RETURN 'tuesday';
		ELSIF in_day_number = 4 THEN
			RETURN 'wednesday';
		ELSIF in_day_number = 5 THEN
			RETURN 'thursday';
		ELSIF in_day_number = 6 THEN
			RETURN 'friday';
		ELSIF in_day_number = 7 THEN
			RETURN 'saturday';
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown day: '||in_day_number);
		END IF;
	END;
		
	MEMBER FUNCTION OrdinalToNumber(
		in_ordinal						IN	VARCHAR2
	) RETURN NUMBER
	AS
	BEGIN
		if in_ordinal = 'last' THEN
			RETURN -1;
		ELSIF in_ordinal = 'first' THEN
			RETURN 1;
		ELSIF in_ordinal = 'second' THEN
			RETURN 2;
		ELSIF in_ordinal = 'third' THEN
			RETURN 3;
		ELSIF in_ordinal = 'fourth' THEN 
			RETURN 4;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown ordinal: '||in_ordinal);
		END IF;
	END;
	
	MEMBER PROCEDURE DoMakeOccurrencesDaily
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN		
		IF SELF.repeat_weekday = 1 THEN
			-- make weekday occurrences
			-- check every day and add if it's not a weekend
			WHILE NOT IsDone(v_start_dtm) LOOP
				IF TO_CHAR(v_start_dtm, 'D') NOT IN ('7', '1') THEN
					SELF.occurrences.extend(1);
					SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;
				END IF;
				v_start_dtm := v_start_dtm + 1;
			END LOOP;
		ELSE
			-- make every N occurrences
			WHILE NOT IsDone(v_start_dtm) LOOP
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;

				v_start_dtm := v_start_dtm + NVL(SELF.repeat_every, 1);
			END LOOP;
		END IF;
	END;
	
	MEMBER PROCEDURE DoMakeOccurrencesWeekly
	AS
		v_start_dtm					DATE := SELF.start_dtm;
		v_day						VARCHAR2(100);
	BEGIN
		IF SELF.weekly_days.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'No weekly_days specified');
		END IF;
		
		WHILE NOT IsDone(v_start_dtm) LOOP
			FOR i IN 1..7 LOOP
				v_day := DayNumberToDay(TO_NUMBER(TO_CHAR(v_start_dtm, 'D')));
						
				FOR j IN SELF.weekly_days.FIRST .. SELF.weekly_days.LAST LOOP
					IF SELF.weekly_days(j) = v_day THEN
						SELF.occurrences.extend(1);
						SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;
						EXIT;
					END IF;
				END LOOP;
				v_start_dtm := v_start_dtm + 1;
				EXIT WHEN IsDone(v_start_dtm);
			END LOOP;
			-- subtract 1 because we've just done a week above
			v_start_dtm := v_start_dtm + 7 * (NVL(SELF.repeat_every, 1) - 1);
		END LOOP;
	END;
	
	MEMBER PROCEDURE DoMakeOccurrencesMonthly
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN
		v_start_dtm := TRUNC(SELF.start_dtm, 'MON') + SELF.day_number - 1;
		
		WHILE NOT IsDone(v_start_dtm) LOOP
			-- check it's after start, in case our start dtm = 20th of month and we ask for 10th day
			IF v_start_dtm >= SELF.start_dtm THEN
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;
			END IF;
			v_start_dtm := ADD_MONTHS(v_start_dtm, NVL(SELF.repeat_every, 1));
		END LOOP;
	END;

	MEMBER PROCEDURE DoMakeOccurrencesYearly
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN
		v_start_dtm := ADD_MONTHS(TRUNC(SELF.start_dtm, 'YEAR'), MonthToMonthNumber(SELF.day_month) - 1) + SELF.day_number - 1;
		
		WHILE NOT IsDone(v_start_dtm) LOOP
			-- check it's after start, in case our start dtm = 20th of month and we ask for 10th day
			IF v_start_dtm >= SELF.start_dtm THEN
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;
			END IF;
			v_start_dtm := ADD_MONTHS(v_start_dtm, 12 * NVL(SELF.repeat_every, 1));
		END LOOP;
	END;

	MEMBER PROCEDURE DoMakeOccurrencesDayVarying
	AS
		v_ordinal					NUMBER;
		v_seek_day_number			NUMBER;
		v_dtm						DATE;
		v_day_num					NUMBER;
		v_this_dtm					DATE;
	BEGIN
		v_this_dtm := ADD_MONTHS(TRUNC(SELF.start_dtm, 'YEAR'), MonthToMonthNumber(NVL(SELF.day_varying_month, 'jan')) - 1);
		v_seek_day_number := DayToDayNumber(SELF.day_varying_day);
		v_ordinal := OrdinalToNumber(SELF.day_varying_type);
		WHILE NOT IsDone(v_this_dtm) LOOP
			IF v_ordinal = -1 THEN
				-- last day
				v_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), 1);
				v_day_num := TO_CHAR(v_dtm, 'D');
				IF v_day_num > v_seek_day_number THEN
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num);
				ELSE
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num - 7);
				END IF;
			ELSE
				-- everything else
				-- starting with 1st day of this month, figure out the required date
				v_dtm := TRUNC(v_this_dtm, 'MON');
				v_day_num := TO_CHAR(v_dtm, 'D');
				
				-- e.g. looking for a monday, and the first day of month is a tuesday
				IF v_day_num > v_seek_day_number THEN
					v_this_dtm := v_dtm + 7 + v_seek_day_number - v_day_num;
				ELSE
					v_this_dtm := v_dtm + v_seek_day_number - v_day_num;
				END IF;
				
				-- adjust to second, third etc
				v_this_dtm := v_this_dtm + 7 * (v_ordinal - 1);
			END IF;
			
			IF v_this_dtm >= SELF.start_dtm THEN
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_this_dtm;
			END IF;
			v_this_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), NVL(SELF.repeat_every, 1) * CASE WHEN SELF.repeat_period = 'monthly' THEN 1 ELSE 12 END);
		END LOOP;
	END;

	MEMBER PROCEDURE DoMakeOccurrences
	AS
	BEGIN
		IF SELF.day_varying_type IS NOT NULL THEN
			DoMakeOccurrencesDayVarying;
		ELSE
			CASE SELF.repeat_period
				WHEN 'daily' THEN
					DoMakeOccurrencesDaily;
				WHEN 'weekly' THEN
					DoMakeOccurrencesWeekly;
				WHEN 'monthly' THEN
					DoMakeOccurrencesMonthly;
				WHEN 'yearly' THEN
					DoMakeOccurrencesYearly;
			END CASE;
		END IF;
	END;
	
	MEMBER FUNCTION MakeOccurrences(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_start_dtm					IN	DATE,
		in_end_dtm						IN	DATE
	)
	RETURN T_RECURRENCE_DATES
	AS
	BEGIN
		SELF.start_dtm := in_start_dtm;
		SELF.end_dtm := in_end_dtm;
		SELF.occurrences := T_RECURRENCE_DATES();
		DoMakeOccurrences;
		RETURN SELF.occurrences;
	END;

	MEMBER PROCEDURE MakeOccurrences(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_start_dtm					IN	DATE,
		in_end_dtm						IN	DATE
	)
	AS
		v_dates							T_RECURRENCE_DATES;
	BEGIN
		v_dates := MakeOccurrences(in_start_dtm, in_end_dtm);
	END;

	MEMBER FUNCTION GetOccurrences(
		in_dtm							IN	DATE,
		in_include_on_dtm				IN	BOOLEAN
	)
	RETURN T_RECURRENCE_DATES
	AS
		v_dates							T_RECURRENCE_DATES;
		v_first							PLS_INTEGER;
		v_last							PLS_INTEGER;
		v_pos							PLS_INTEGER;
	BEGIN
		IF SELF.occurrences IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'MakeOccurrences must be called first');
		END IF;
		v_dates := T_RECURRENCE_DATES();
		
		IF SELF.occurrences.COUNT > 0 THEN
			v_dates := T_RECURRENCE_DATES();
			v_first := SELF.occurrences.FIRST;
			v_last := SELF.occurrences.LAST;

			WHILE v_first <= v_last LOOP
				v_pos := (v_first + v_last) / 2;
				IF in_include_on_dtm AND SELF.occurrences(v_pos) = in_dtm THEN
					EXIT;
				ELSIF SELF.occurrences(v_pos) > in_dtm THEN
					v_last := v_pos - 1;
				ELSE
					v_first := v_pos + 1;
				END IF;
			END LOOP;
			IF SELF.occurrences(v_pos) < in_dtm THEN
				v_pos := v_pos + 1;
			END IF;
			IF v_pos <= SELF.occurrences.LAST THEN
				v_first := v_pos;
				v_dates.extend(SELF.occurrences.LAST - v_pos + 1);
				WHILE v_pos <= SELF.occurrences.LAST LOOP
					v_dates(v_pos - v_first + 1) := SELF.occurrences(v_pos);
					v_pos := v_pos + 1;
				END LOOP;
			END IF;
				
		END IF;
		RETURN v_dates;
	END;
		
	MEMBER FUNCTION GetOccurrencesAfter(
		in_dtm							IN	DATE
	)
	RETURN T_RECURRENCE_DATES
	AS
	BEGIN
		RETURN GetOccurrences(in_dtm, FALSE);
	END;
	
	MEMBER FUNCTION GetOccurrencesOnOrAfter(
		in_dtm							IN	DATE
	)
	RETURN T_RECURRENCE_DATES
	AS
	BEGIN
		RETURN GetOccurrences(in_dtm, TRUE);
	END;
END;
/

@../deleg_plan_pkg
@../delegation_pkg
@../region_pkg
@../region_body
@../delegation_body
@../deleg_plan_body
@../csrimp/imp_body
@../strategy_body
@../tag_body

@update_tail

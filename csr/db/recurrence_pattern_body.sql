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
			RAISE_APPLICATION_ERROR(-20001, 'repeat_period must be hourly, daily, weekly, monthly or yearly');
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
		  
		SELECT 
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/x-day-b/@number').getStringVal(),
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/x-day-b/@month').getStringVal()
		  INTO SELF.x_day_b_number, SELF.x_day_b_month
		  FROM DUAL;

		RETURN;
	END;
	
	MEMBER FUNCTION WeekDay(
		in_dtm						IN	DATE
	) RETURN NUMBER
	AS
	BEGIN
		RETURN 1 + MOD(1 + TRUNC(in_dtm) - TRUNC(in_dtm, 'IW'), 7);
	END;

	MEMBER PROCEDURE SetRepeatPeriod(
		in_repeat_period	IN	VARCHAR2,
        in_repeat_every     IN  NUMBER DEFAULT NULL
	)
	IS
        v_cnt   NUMBER(10);
	BEGIN
        IF LOWER(in_repeat_period) NOT IN ('hourly', 'daily','weekly','monthly','yearly') THEN
            RAISE_APPLICATION_ERROR(-20001,'repeat-period must be one of "hourly", "daily", "weekly", "monthly", "yearly"');
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
					WHEN SELF.x_day_b_month IS NOT NULL THEN
                        XMLELEMENT("x-day-b", 
                            XMLATTRIBUTES(SELF.x_day_b_number as "number", SELF.x_day_b_month as "month"))
                    WHEN SELF.x_day_b_number IS NOT NULL THEN
                        XMLELEMENT("x-day-b", 
                            XMLATTRIBUTES(SELF.x_day_b_number as "number"))
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
	
	-- FB39350 adding this function so that due dates on monthly delegations can be different from the month where the sheet starts(e.g. Sheet for January can be due on 1st March if every-n=2)
	MEMBER FUNCTION IsDoneMonthly(
		in_dtm							IN	DATE
	)
	RETURN BOOLEAN
	AS
	BEGIN
		IF in_dtm IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'null date passed to IsDoneMonthly');
		END IF;

		IF SELF.end_dtm IS NOT NULL THEN
			IF SELF.repeat_every > 1 THEN
				IF in_dtm >= ADD_MONTHS(SELF.end_dtm, SELF.repeat_every) THEN
					RETURN TRUE;
				END IF;
			ELSE -- when the repeat_every is 1 the previous logic on IsDone will be used
				IF in_dtm >= SELF.end_dtm THEN
					RETURN TRUE;
				END IF;
			END IF;
		END IF;
		/* occurrences not supported yet
		if (m_occurrences.Count >= m_maxOccurrences)
		{
			return true;
		} 
		*/
		RETURN FALSE;
	END;
	
	-- FB39350 adding this function so that due dates on monthly delegations can be different from the month where the sheet starts(e.g. Sheet for January can be due on 1st March if every-n=2)
	MEMBER FUNCTION IsDoneDayVarying(
		in_dtm							IN	DATE
	)
	RETURN BOOLEAN
	AS
	BEGIN
		IF in_dtm IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'null date passed to IsDoneDayVarying');
		END IF;
		
		IF SELF.end_dtm IS NOT NULL THEN
			IF SELF.repeat_every > 1 THEN
				IF in_dtm >= ADD_MONTHS(SELF.start_dtm, SELF.repeat_every) THEN
					RETURN TRUE;
				END IF;
			ELSE -- when the repeat_every is 1 the previous logic on IsDone will be used
				IF in_dtm >= SELF.end_dtm THEN
					RETURN TRUE;
				END IF;
			END IF;
		END IF;
		/* occurrences not supported yet
		if (m_occurrences.Count >= m_maxOccurrences)
		{
			return true;
		} 
		*/
		RETURN FALSE;
	END;
		
	MEMBER FUNCTION IsEqual(
		in_pattern		IN	RECURRENCE_PATTERN
	) RETURN BOOLEAN
	AS
	BEGIN
		IF (SELF.repeat_period = in_pattern.repeat_period OR (SELF.repeat_period IS NULL AND in_pattern.repeat_period IS NULL))
			AND (SELF.repeat_every = in_pattern.repeat_every OR (SELF.repeat_every IS NULL AND in_pattern.repeat_every IS NULL))
			AND (SELF.repeat_weekday = in_pattern.repeat_weekday OR (SELF.repeat_weekday IS NULL AND in_pattern.repeat_weekday IS NULL))
			AND (SELF.day_varying_type = in_pattern.day_varying_type OR (SELF.day_varying_type IS NULL AND in_pattern.day_varying_type IS NULL))
			AND (SELF.day_varying_day = in_pattern.day_varying_day OR (SELF.day_varying_day IS NULL AND in_pattern.day_varying_day IS NULL))
			AND (SELF.day_varying_month = in_pattern.day_varying_month OR (SELF.day_varying_month IS NULL AND in_pattern.day_varying_month IS NULL))
			AND (SELF.day_number = in_pattern.day_number OR (SELF.day_number IS NULL AND in_pattern.day_number IS NULL))
			AND (SELF.day_month = in_pattern.day_month OR (SELF.day_month IS NULL AND in_pattern.day_month IS NULL))
			AND (SELF.x_day_b_number = in_pattern.x_day_b_number OR (SELF.x_day_b_number IS NULL AND in_pattern.x_day_b_number IS NULL))
			AND (SELF.x_day_b_month = in_pattern.x_day_b_month OR (SELF.x_day_b_month IS NULL AND in_pattern.x_day_b_month IS NULL))
			AND (SELF.start_dtm = in_pattern.start_dtm OR (SELF.start_dtm IS NULL AND in_pattern.start_dtm IS NULL))
			AND (SELF.end_dtm = in_pattern.end_dtm OR (SELF.end_dtm IS NULL AND in_pattern.end_dtm IS NULL))
			AND (SELF.weekly_days = in_pattern.weekly_days OR (SELF.weekly_days IS NULL AND in_pattern.weekly_days IS NULL))
			AND (SELF.occurrences = in_pattern.occurrences OR (SELF.occurrences IS NULL AND in_pattern.occurrences IS NULL)) THEN
				RETURN TRUE;
		END IF;
		RETURN FALSE;
	END;
	
	MEMBER FUNCTION MonthToMonthNumber(
		in_month						IN	VARCHAR2
	) RETURN NUMBER
	AS
		v_month							VARCHAR2(3);
	BEGIN
		v_month := LOWER(SUBSTR(in_month, 1, 3));
		IF v_month = 'jan' THEN
			RETURN 1;
		ELSIF v_month = 'feb' THEN
			RETURN 2;
		ELSIF v_month = 'mar' THEN
			RETURN 3;
		ELSIF v_month = 'apr' THEN
			RETURN 4;
		ELSIF v_month = 'may' THEN
			RETURN 5;
		ELSIF v_month = 'jun' THEN
			RETURN 6;
		ELSIF v_month = 'jul' THEN
			RETURN 7;
		ELSIF v_month = 'aug' THEN
			RETURN 8;
		ELSIF v_month = 'sep' THEN
			RETURN 9;
		ELSIF v_month = 'oct' THEN
			RETURN 10;
		ELSIF v_month = 'nov' THEN
			RETURN 11;
		ELSIF v_month = 'dec' THEN
			RETURN 12;
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Unknown month: '||v_month);
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
	
	MEMBER PROCEDURE DoMakeOccurrencesXDaysBefore
	AS
		v_start_dtm					DATE := SELF.start_dtm;
		v_initial_start_dtm			DATE;	
	BEGIN
		WHILE NOT IsDone(v_start_dtm) LOOP
			SELF.occurrences.extend(1);
			CASE SELF.repeat_period
				WHEN 'yearly' THEN
					SELF.occurrences(SELF.occurrences.COUNT) := add_months((last_day(to_date('01-' || SELF.x_day_b_month || '/' || (EXTRACT (YEAR FROM v_start_dtm))))) - SELF.x_day_b_number,-12);	-- specified month of year within reporting period, minus 'x' days
				WHEN 'monthly' THEN
					--get the last day in the month for the v_start_dtm then subtract SELF.x_day_b_number
					v_initial_start_dtm := v_start_dtm;
					SELF.occurrences(SELF.occurrences.COUNT) :=  LAST_DAY(v_start_dtm) - SELF.x_day_b_number + 1;
				ELSE
					SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm - SELF.x_day_b_number;
			END CASE;
			
			v_start_dtm := ADD_MONTHS(v_start_dtm, NVL(SELF.repeat_every, 1));
		END LOOP;
	END;
	
	MEMBER PROCEDURE DoMakeOccurrencesHourly
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN		
			-- make every N occurrences
			WHILE NOT IsDone(v_start_dtm) LOOP
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_start_dtm;

				v_start_dtm := v_start_dtm + NVL(SELF.repeat_every, 1) / 24;
			END LOOP;
	END;	
	
	MEMBER PROCEDURE DoMakeOccurrencesDaily
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN		
		IF SELF.repeat_weekday = 1 THEN
			-- make weekday occurrences
			-- check every day and add if it's not a weekend
			WHILE NOT IsDone(v_start_dtm) LOOP
				IF WeekDay(v_start_dtm) NOT IN (7, 1) THEN
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
				v_day := DayNumberToDay(WeekDay(v_start_dtm));
						
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
		v_next_dtm					DATE := SELF.start_dtm;
	BEGIN
		v_start_dtm := TRUNC(SELF.start_dtm, 'MON');
		WHILE NOT IsDoneMonthly(v_start_dtm) LOOP
			-- This is meant to cope with the (rather daft) situation where a day > 28 is requested
			-- which doesn't then exist in some months by using it where possible
			-- ADD_MONTHS usess 'last day of month' if the day doesn't exist, but then once you 
			-- add a month to the last day of a month it continues to use the last day of the month
			-- e.g. ADD_MONTHS(date '2011-04-30') = date '2011-05-31'
			DECLARE
				day_not_in_current_month EXCEPTION;
				PRAGMA EXCEPTION_INIT (day_not_in_current_month, -1839);
				day_greater_31 EXCEPTION;
				PRAGMA EXCEPTION_INIT (day_greater_31, -1847);
			BEGIN
				v_next_dtm := to_date(SELF.day_number ||'/'||
						(EXTRACT(MONTH FROM v_start_dtm))||'/'||
						(EXTRACT(YEAR FROM v_start_dtm)), 'DD/MM/YYYY');
			EXCEPTION
				WHEN day_not_in_current_month THEN
					v_next_dtm := LAST_DAY (v_start_dtm);
				WHEN day_greater_31 THEN
					v_next_dtm := v_start_dtm + SELF.day_number - 1;
			END;
			-- check it's after start, in case our start dtm = 20th of month and we ask for 10th day
			IF v_next_dtm >= SELF.start_dtm THEN
				SELF.occurrences.extend(1);
				SELF.occurrences(SELF.occurrences.COUNT) := v_next_dtm;
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
		WHILE NOT IsDoneDayVarying(v_this_dtm) LOOP
			IF v_ordinal = -1 THEN
				-- last day
				v_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), 1);
				
				v_day_num := WeekDay(v_dtm);
				IF v_day_num > v_seek_day_number THEN
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num);
				ELSE
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num - 7);
				END IF;
			ELSE
				-- everything else
				-- starting with 1st day of this month, figure out the required date
				v_dtm := TRUNC(v_this_dtm, 'MON');
				v_day_num := WeekDay(v_dtm);
				
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
			v_this_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), CASE WHEN SELF.repeat_period = 'monthly' THEN 1 ELSE 12 END);
		END LOOP;
	END;

	MEMBER PROCEDURE DoMakeOccurrences
	AS
	BEGIN
		IF SELF.day_varying_type IS NOT NULL THEN
			DoMakeOccurrencesDayVarying;
		ELSIF SELF.x_day_b_number IS NOT NULL THEN
			DoMakeOccurrencesXDaysBefore;
		ELSE
			CASE SELF.repeat_period
				WHEN 'hourly' THEN
					DoMakeOccurrencesHourly;			
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
		
		IF self.x_day_b_number IS NOT NULL THEN
			RETURN SELF.occurrences;	-- x_day_b is setting the "due date" to before the end of the sheet period, and will already be right.
		END IF;
		
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
			IF (SELF.occurrences(v_pos) < in_dtm) THEN 
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
	
	MEMBER FUNCTION GetNextOccurrence(
		self							IN OUT NOCOPY RECURRENCE_PATTERN,
		in_dtm							IN DATE
	)
	RETURN DATE
	AS
	BEGIN
		SELF.start_dtm := in_dtm;
		
		IF SELF.day_varying_type IS NOT NULL THEN
			RETURN GetNextDayVaryingOccurrence;
		ELSIF SELF.x_day_b_number IS NOT NULL THEN
			RETURN GetNextXDaysBeforeOccurrence;
		ELSE
			CASE SELF.repeat_period
				WHEN 'hourly' THEN
					RETURN GetNextHourlyOccurrence;
				WHEN 'daily' THEN
					RETURN GetNextDailyOccurrence;
				WHEN 'weekly' THEN
					RETURN GetNextWeeklyOccurrence;
				WHEN 'monthly' THEN
					RETURN GetNextMonthlyOccurrence;
				WHEN 'yearly' THEN
					RETURN GetNextYearlyOccurrence;
			END CASE;
		END IF;
	END;
	
	MEMBER FUNCTION GetNextHourlyOccurrence
	RETURN DATE
	AS
		v_start_dtm					DATE := SELF.start_dtm;
	BEGIN		
		v_start_dtm := v_start_dtm + NVL(SELF.repeat_every, 1) / 24;
		
		RETURN v_start_dtm;
	END;	
	
	MEMBER FUNCTION GetNextDailyOccurrence
	RETURN DATE
	AS
		v_start_dtm					DATE := TRUNC(SELF.start_dtm, 'DD');
	BEGIN		
		IF SELF.repeat_weekday = 1 THEN
			v_start_dtm := v_start_dtm + 1;
			-- skip weekend days
			WHILE WeekDay(v_start_dtm) IN (7, 1) LOOP
				v_start_dtm := v_start_dtm + 1;
			END LOOP;	
		ELSE
			v_start_dtm := v_start_dtm + NVL(SELF.repeat_every, 1);
		END IF;
		
		RETURN v_start_dtm;
	END;
	
	MEMBER FUNCTION GetNextWeeklyOccurrence
	RETURN DATE	
	AS
		v_start_dtm					DATE := TRUNC(SELF.start_dtm, 'DD');
	BEGIN
		IF SELF.weekly_days.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'No weekly_days specified');
		END IF;
		
		/* check for next occurrence in current week */
		FOR i IN SELF.weekly_days.FIRST .. SELF.weekly_days.LAST LOOP
			IF DayToDayNumber(SELF.weekly_days(i)) > WeekDay(v_start_dtm) THEN
				RETURN v_start_dtm + (DayToDayNumber(SELF.weekly_days(i)) - WeekDay(v_start_dtm));
			END IF;
		END LOOP;
		
		/* occurrence not found, skip to start of next week in schedule */
		v_start_dtm := v_start_dtm + 7 * NVL(SELF.repeat_every, 1) - WeekDay(v_start_dtm) + 1;
		
		/* check for next occurrence in current week */
		FOR i IN SELF.weekly_days.FIRST .. SELF.weekly_days.LAST LOOP
			IF DayToDayNumber(SELF.weekly_days(i)) >= WeekDay(v_start_dtm) THEN
				RETURN v_start_dtm + (DayToDayNumber(SELF.weekly_days(i)) - WeekDay(v_start_dtm));
			END IF;
		END LOOP;
		
		/* should've found the next date by now */
		RAISE_APPLICATION_ERROR(-20001, 'GetNextWeeklyOccurrence could not find next occurrence');
	END;
	
	MEMBER FUNCTION GetNextMonthlyOccurrence
	RETURN DATE
	AS
		v_start_dtm					DATE := TRUNC(SELF.start_dtm, 'MONTH');
		v_next_dtm					DATE := TRUNC(SELF.start_dtm, 'DD');
	BEGIN
		DECLARE
			day_not_in_current_month EXCEPTION;
			PRAGMA EXCEPTION_INIT (day_not_in_current_month, -1839);
			day_greater_31 EXCEPTION;
			PRAGMA EXCEPTION_INIT (day_greater_31, -1847);
		BEGIN
			v_next_dtm := TO_DATE(SELF.day_number ||'/'||
					(EXTRACT(MONTH FROM v_start_dtm))||'/'||
					(EXTRACT(YEAR FROM v_start_dtm)), 'DD/MM/YYYY');
		EXCEPTION
			WHEN day_not_in_current_month THEN
				v_next_dtm := LAST_DAY (v_start_dtm);
			WHEN day_greater_31 THEN
				v_next_dtm := v_start_dtm + SELF.day_number - 1;
		END;
		
		-- XXX: The UI says something like "The frst <something> following every nth month".
		-- This is a little tricky as we don't know which month it's supposed to start on.
		-- So should this be a modulus so for every 3 months it only ever falls on Jan, Apr, Jul, Oct
		-- or should it count from the given date so if we tell it to start wit the 1st Feb then it will return May?
		IF v_next_dtm <= SELF.start_dtm THEN
			v_start_dtm := ADD_MONTHS(v_next_dtm, NVL(SELF.repeat_every, 1));
		ELSE
			v_start_dtm := v_next_dtm;
		END IF;
		
		RETURN v_start_dtm;
	END;
	
	MEMBER FUNCTION GetNextYearlyOccurrence
	RETURN DATE
	AS
		v_start_dtm					DATE := TRUNC(SELF.start_dtm, 'DD');
	BEGIN
		v_start_dtm := ADD_MONTHS(TRUNC(SELF.start_dtm, 'YEAR'), MonthToMonthNumber(SELF.day_month) - 1) + SELF.day_number - 1;
		
		IF v_start_dtm <= SELF.start_dtm THEN
			v_start_dtm := ADD_MONTHS(v_start_dtm, 12 * NVL(SELF.repeat_every, 1));
		END IF;
		
		RETURN v_start_dtm;
	END;
	
	MEMBER FUNCTION GetNextDayVaryingOccurrence
	RETURN DATE
	AS
		v_ordinal					NUMBER;
		v_seek_day_number			NUMBER;
		v_dtm						DATE;
		v_day_num					NUMBER;
		v_this_dtm					DATE;
		v_next_search_step			NUMBER;
	BEGIN
		
		IF SELF.repeat_period = 'monthly' THEN
			v_this_dtm := TRUNC(SELF.start_dtm, 'MONTH');
			v_next_search_step := 1;
		ELSE 
			-- XXX: This only works when we're searching for the nth day name in a given
			-- month each year, it doesn't work for the nth day name of every month,
			-- in which case it would always just return the 1st of feb!!
			v_this_dtm := ADD_MONTHS(TRUNC(SELF.start_dtm, 'YEAR'), MonthToMonthNumber(NVL(SELF.day_varying_month, 'jan')) - 1);
			v_next_search_step := 12;
		END IF;
		
		v_seek_day_number := DayToDayNumber(SELF.day_varying_day);
		v_ordinal := OrdinalToNumber(SELF.day_varying_type);
		
		LOOP
		
			IF v_ordinal = -1 THEN
				-- last day
				v_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), 1);
				v_day_num := WeekDay(v_dtm);
				IF v_day_num > v_seek_day_number THEN
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num);
				ELSE
					v_this_dtm := v_dtm + (v_seek_day_number - v_day_num - 7);
				END IF;
			ELSE
				-- everything else
				-- starting with 1st day of this month, figure out the required date
				v_dtm := TRUNC(v_this_dtm, 'MON');
				v_day_num := WeekDay(v_dtm);
				
				-- e.g. looking for a monday, and the first day of month is a tuesday
				IF v_day_num > v_seek_day_number THEN
					v_this_dtm := v_dtm + 7 + v_seek_day_number - v_day_num;
				ELSE
					v_this_dtm := v_dtm + v_seek_day_number - v_day_num;
				END IF;
				
				-- adjust to second, third etc
				v_this_dtm := v_this_dtm + 7 * (v_ordinal - 1);
			END IF;
		
			-- XXX: Can't just add some number of months on here because we're searching for a particular
			-- day and the date (month day number) on which that day falls will not always be the same in the next search perriod.
			-- So, if the date we found is before the start date go round and do the day search  again for the next search perod.
			/*
			IF v_this_dtm < SELF.start_dtm THEN
				v_this_dtm := ADD_MONTHS(TRUNC(v_this_dtm, 'MON'), NVL(SELF.repeat_every, 1) * CASE WHEN SELF.repeat_period = 'monthly' THEN 1 ELSE 12 END);
			END IF;
			*/
			
			EXIT WHEN v_this_dtm > SELF.start_dtm;
			v_this_dtm :=TRUNC(ADD_MONTHS(v_this_dtm, v_next_search_step), 'MONTH');
			
		END LOOP;
		
		RETURN v_this_dtm;
	END;
	
	MEMBER FUNCTION GetNextXDaysBeforeOccurrence
	RETURN DATE
	AS
		v_start_dtm					DATE := TRUNC(SELF.start_dtm, 'DD');
		v_initial_start_dtm			DATE;
	BEGIN
		CASE SELF.repeat_period
			WHEN 'yearly' THEN
				v_start_dtm := add_months((last_day(to_date('01-' || SELF.x_day_b_month || '/' || (EXTRACT (YEAR FROM v_start_dtm))))) - SELF.x_day_b_number,-12);	-- specified month of year within reporting period, minus 'x' days
			WHEN 'monthly' THEN
				--get the last day in the month for the v_start_dtm then subtract SELF.x_day_b_number
				v_initial_start_dtm := v_start_dtm;
				v_start_dtm :=  LAST_DAY(v_start_dtm) - SELF.x_day_b_number + 1;
				
				--if the v_start_dtm has not changed we want to return next month's occurence
				--so that we do not keep repeatedly returning v_start_dtm
				IF v_start_dtm = v_initial_start_dtm THEN 
					v_start_dtm := LAST_DAY(ADD_MONTHS(v_start_dtm, 1)) - SELF.x_day_b_number + 1; 
				END IF;
			ELSE
				v_start_dtm := v_start_dtm - SELF.x_day_b_number;
		END CASE;
		
		RETURN v_start_dtm;
	END;
	
END;
/

CREATE OR REPLACE PACKAGE BODY CSR.RECURRENCE_PATTERN_pkg
IS

FUNCTION GetNextOccurrence(
	in_recurrence_pattern_xml 			IN XMLType,
	in_dtm								IN DATE
) RETURN DATE
AS
	v_schedule 							csr.RECURRENCE_PATTERN := csr.RECURRENCE_PATTERN(in_recurrence_pattern_xml);
BEGIN
	RETURN v_schedule.GetNextOccurrence(in_dtm);
END;

END;
/

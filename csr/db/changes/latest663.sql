-- Please update version.sql too -- this keeps clean builds in sync
define version=663
@update_header

CREATE OR REPLACE TYPE BODY csr.RECURRENCE_PATTERN AS
	CONSTRUCTOR FUNCTION RECURRENCE_PATTERN(
		SELF IN OUT NOCOPY RECURRENCE_PATTERN, 
		recurrence_pattern_xml IN XMLType
	) RETURN SELF AS RESULT 
	IS
        v_repeat_every  VARCHAR2(255);
	BEGIN
		SELECT EXTRACT(recurrence_pattern_xml,'recurrences/node()').getRootElement(),	
			EXTRACT(recurrence_pattern_xml,'recurrences/node()/@every-n').getStringVal()
		  INTO SELF.repeat_period, v_repeat_every
		  FROM DUAL;
		
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
        in_days     IN  T_RECURRENCE_DAYS
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
		in_day_number	IN	NUMBER,
        in_day_month    IN  VARCHAR2 DEFAULT NULL
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
		in_day_varying_type IN	VARCHAR2,
		in_day_varying_day IN	VARCHAR2,
		in_day_varying_month IN	VARCHAR2
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
END;
/


declare
	v_rp 	csr.RECURRENCE_PATTERN;
	v_cnt	number(10) := 0;
begin
	for r in (
		select delegation_sid, schedule_xml, to_char(end_dtm,'mon') mon
		  from csr.delegation 
		 where schedule_xml like '%yearly%' 
		   and schedule_xml not like '%month=%'
	)
	loop
		dbms_output.put_line(r.schedule_xml);
		v_rp := csr.RECURRENCE_PATTERN(XMLType(r.schedule_xml));
		IF v_rp.day_number IS NOT NULL THEN
			v_rp.SetRepeatPeriod('yearly');
			v_rp.SetDay(v_rp.day_number, r.mon);
			update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
			v_cnt := v_cnt + 1;
		END IF;
		IF v_rp.day_varying_type IS NOT NULL THEN
			v_rp.SetRepeatPeriod('yearly');
			v_rp.SetDayVarying(v_rp.day_varying_type, v_rp.day_varying_day, r.mon);
			update csr.delegation set schedule_xml = v_rp.getClob where delegation_Sid = r.delegation_sid;
			v_cnt := v_cnt + 1;
		END IF;
	end loop;
	dbms_output.put_line('fixed '||v_cnt||' yearly');
end;
/

@update_tail

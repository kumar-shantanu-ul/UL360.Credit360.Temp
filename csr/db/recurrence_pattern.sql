/*
 *  Object to manage XML Recurrence Patterns like those used by NPSL.Recurrrence
 *
 *  SetRepeatPeriod   - Set the repeat period and optional interval (e.g. yearly, monthly, weekly, daily).
 *  SetDaysOfWeek     - Set the days of the week for a Weekly pattern.
 *  SetDay            - Set a static day for a monthly or yearly pattern.
 *  SetDayVarying     - Set a variable day (e.g. 'first thursday') for a monthly or yearly pattern.
 *  SetMonth          - Set the month of a yearly pattern.
 *  GetXml            - XMLType representation of the pattern
 *  GetClob			  - CLOB representation of the pattern XML
 *  GetCalendarString - dbms_scheduler.evaluate_calendar_string format (for computing occurrences)
 *
 *  DECLARE
 *      v_xml	    XMLType;
 *      v_schedule 	RECURRENCE_PATTERN := RECURRENCE_PATTERN(XMLType('<recurrences><yearly><day number="10" month="aug"/></yearly></recurrences>'));
 *  --	v_schedule 	RECURRENCE_PATTERN := RECURRENCE_PATTERN(XMLType('<recurrences><monthly every-n="1"><day number="1"/></monthly></recurrences>'));
 *  --	v_schedule 	RECURRENCE_PATTERN := RECURRENCE_PATTERN(XMLType('<recurrences><weekly every-n="1"><monday/><wednesday/></weekly></recurrences>'));
 *  begin
 *      v_schedule.SetRepeatPeriod('weekly', 2);
 *      v_schedule.SetDaysOfWeek(T_RECURRENCE_DAYS('monday','wednesday'));
 *      v_xml := v_schedule.getXML;
 *      DBMS_OUTPUT.PUT_LINE(v_schedule.getClob);
 *   end;
 *  /
 *
 */
begin
	-- note: these can't be combined -- you can't drop types with dependants so they need to be dropped in the right order
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

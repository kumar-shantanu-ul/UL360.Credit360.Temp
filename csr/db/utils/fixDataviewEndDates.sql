SET SERVEROUTPUT ON

DECLARE
	v_end date;
	v_now date := sysdate;
BEGIN
	FOR r IN (
		SELECT app_sid,dataview_sid,start_dtm,period_set_id,period_interval_id FROM csr.dataview WHERE end_Dtm IS NULL ORDER BY app_sid 
	)
	LOOP	
		IF r.period_interval_id=4 THEN
			v_end := ADD_MONTHS(TRUNC(v_now, 'YEAR'), 12);
		ELSIF r.period_interval_id=2 THEN
			v_end := ADD_MONTHS(TRUNC(v_now, 'Q'), 3);
		ELSIF r.period_interval_id = 1 THEN
			v_end := ADD_MONTHS(TRUNC(v_now, 'MON'), 1);
		ELSIF r.period_interval_id = 3 THEN
			v_end := TRUNC(v_now, 'Q');
			IF v_end = TRUNC(v_now, 'YEAR') THEN
				v_end := ADD_MONTHS(v_end, 6);
			ELSE
				v_end := ADD_MONTHS(v_end, 3);
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('app '||r.app_sid||', dataview '||r.dataview_sid||', period_interval_id '||r.period_interval_id||', end '||
			TO_CHAR(v_end, 'yyyy-MM-dd'));
		UPDATE csr.dataview SET end_dtm = v_end WHERE dataview_sid = r.dataview_sid AND app_sid = r.app_sid;
	END LOOP;
END;
/

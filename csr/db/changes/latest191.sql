-- Please update version.sql too -- this keeps clean builds in sync
define version=191
@update_header

CREATE OR REPLACE 
PROCEDURE UpdateAlertsTEMP(
	in_ind_sid		IN  security_pkg.T_SID_ID,
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_val_number	IN 	VAL.val_number%TYPE,
	in_start_dtm	IN	VAL.period_start_dtm%TYPE,
	in_end_dtm		IN	VAL.period_end_dtm%TYPE
)
AS
	v_period	CHAR(1);
	CURSOR c_win IS
		SELECT UPPER_BRACKET, LOWER_BRACKET FROM IND_WINDOW
		 WHERE IND_SID = in_ind_sid
		   AND PERIOD = v_period;
	v_this_start_dtm	DATE;
	v_this_end_dtm		DATE;
	v_check_start_dtm	DATE;
	v_check_end_dtm		DATE;
	v_check_val_id		VAL.val_id%TYPE;
BEGIN
	v_period := val_pkg.GetIntervalFromRange(in_start_dtm, in_end_dtm);
	-- round off dates appropriately for this period
	val_pkg.GetPeriod(in_start_dtm, in_end_dtm, 0, v_this_start_dtm, v_this_end_dtm);
	-- are there ANY periods that match our start_dtm -> end_dtm FOR our INDICATOR?
	FOR r_win IN c_win LOOP
		-- if so, update alerts for our PREVIOUS PERIOD....
		val_pkg.GetPeriod(in_start_dtm, in_end_dtm, -1, v_check_start_dtm, v_check_end_dtm);
		UPDATE VAL
		   SET alert =
		   (SELECT CASE
		   	  WHEN ABS(in_val_number) > ABS(val_number)*r_win.upper_bracket THEN
			  	'Value more than '||(r_win.upper_bracket*100)||'% of previous value'
			  WHEN ABS(in_val_number) < ABS(val_number)*r_win.lower_bracket THEN
			  	'Value less than '||(r_win.lower_bracket*100)||'% of previous value'
			  ELSE NULL END
			  FROM VAL_CONVERTED
			 WHERE ind_sid = in_ind_sid
			   AND region_sid = in_region_sid
			   AND period_start_dtm = v_check_start_dtm
			   AND period_end_dtm = v_check_end_dtm
		   )
		 WHERE ind_sid = in_ind_sid
		   AND region_sid = in_region_sid
		   AND period_start_dtm = in_start_dtm
		   AND period_end_dtm = in_end_dtm;

		-- and update alerts for our NEXT PERIOD
		val_pkg.GetPeriod(in_start_dtm, in_end_dtm, +1, v_check_start_dtm, v_check_end_dtm);
		-- clear old alerts
		FOR r IN (
           SELECT val_id, CASE
                  WHEN ABS(val_number) > ABS(in_val_number)*r_win.upper_bracket THEN
                    'Value more than '||(r_win.upper_bracket*100)||'% of previous value'
                  WHEN ABS(val_number) < ABS(in_val_number)*r_win.lower_bracket THEN
                    'Value less than '||(r_win.lower_bracket*100)||'% of previous value'
                  ELSE NULL END alert
              FROM VAL_CONVERTED
             WHERE ind_sid = in_ind_sid
               AND region_sid = in_region_sid
               AND period_start_dtm = v_check_start_dtm
               AND period_end_dtm = v_check_end_dtm
        )
        LOOP
            UPDATE val SET alert = r.alert WHERE val_id = r.val_id;
        END LOOP;
	END LOOP;
END;
/

-- fix alerts for negative numbers
declare
    v_act_id security_pkg.t_act_id;
begin
    user_pkg.logonAuthenticated(security_pkg.sid_builtin_administrator, 86400, v_act_id);
    for s in (select iw.ind_sid, iw.period, iw.lower_bracket, iw.upper_bracket
                from ind_window iw, ind i
               where iw.ind_sid = i.ind_sid) loop -- and i.app_sid = (select app_sid from customer where host='ica.credit360.com')) loop
		FOR r IN (
		   SELECT region_sid, period_start_dtm, period_end_dtm, val_number 
		     FROM VAL_CONVERTED
            WHERE ind_sid = s.ind_sid
		)
		LOOP
			UpdateAlertsTEMP(s.ind_sid, r.region_sid, r.val_number, r.period_start_dtm, r.period_end_dtm);
		END LOOP;
		
		FOR r IN (
			SELECT ind_sid, region_sid, val_number, sv.sheet_id 
			  FROM delegation d, sheet s, sheet_value sv 
			 WHERE d.delegation_sid = s.delegation_sid
			   AND sv.sheet_id = s.sheet_id
			   AND ind_sid = s.ind_sid
		)
		LOOP
			delegation_pkg.UpdateAlerts(r.ind_sid,r.region_sid,r.val_number,r.sheet_id);
		END LOOP; 
    end loop;
end;
/

drop procedure UpdateAlertsTEMP;

@update_tail

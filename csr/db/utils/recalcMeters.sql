DECLARE
	v_act				security_pkg.T_ACT_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	FOR r IN (
		SELECT region_sid, trunc(min(reading_dtm),'Mon') min_Dtm, add_months(trunc(max(reading_dtm),'Mon'),1) max_dtm
		  FROM meter_reading
		 GROUP BY region_sid
	)
	LOOP
		meter_pkg.SetValTableForPeriod(v_act, r.region_sid, 0, r.min_dtm, r.max_dtm);
	END LOOP;
END;
/

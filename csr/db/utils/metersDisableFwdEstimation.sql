BEGIN
    user_pkg.logonadmin('&&1');
    UPDATE customer SET fwd_estimate_meters = 0 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	FOR r IN (
		SELECT region_sid, trunc(min(reading_dtm),'Mon') min_Dtm, add_months(trunc(max(reading_dtm),'Mon'),1) max_dtm
		  FROM csr.meter_reading
		 GROUP BY region_sid
	)
	LOOP
		meter_pkg.SetValTableForPeriod(SYS_CONTEXT('SECURITY','ACT'), r.region_sid, 0, r.min_dtm, r.max_dtm);
	END LOOP;
END;
/

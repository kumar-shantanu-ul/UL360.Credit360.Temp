VAR b_exit_code NUMBER;

DECLARE
	v_source_count			NUMBER;
BEGIN
	
	:b_exit_code := 0;
	security.user_pkg.logonadmin('&&1');
	
	SELECT COUNT(*)
	  INTO v_source_count
	  FROM csr.meter_source_type
	 WHERE app_sid = security_pkg.GetAPP
	   AND realtime_metering = 1;
	   
	IF v_source_count = 0 THEN
		:b_exit_code := 255;
	END IF;
END;
/

EXIT :b_exit_code;

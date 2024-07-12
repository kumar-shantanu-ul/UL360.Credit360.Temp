VAR b_exit_code NUMBER;

DECLARE
	v_crc_metering_enabled		csr.customer.crc_metering_enabled%TYPE;
BEGIN
	
	:b_exit_code := 0;
	security.user_pkg.logonadmin('&&1');
	
	SELECT crc_metering_enabled
	  INTO v_crc_metering_enabled
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF NVL(v_crc_metering_enabled, 0) <> 1 THEN
		:b_exit_code := 255;
	END IF;
END;
/

EXIT :b_exit_code;

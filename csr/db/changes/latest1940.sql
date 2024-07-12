-- Please update version.sql too -- this keeps clean builds in sync
define version=1940
@update_header

BEGIN
	-- Update matching factors (not bespoke ones)
	FOR r IN (
		SELECT f.app_sid, f.factor_id
		FROM csr.std_factor sf
		JOIN csr.factor f ON f.std_factor_id = sf.std_factor_id
		AND f.start_dtm = sf.start_dtm
		AND f.end_dtm = sf.end_dtm
		AND f.value = sf.value
		WHERE sf.std_factor_id IN (184324243, 184324827, 184324535, 184325119)
	)
	LOOP

		UPDATE csr.factor SET start_dtm = DATE '2000-01-01' WHERE app_sid = r.app_sid AND factor_id = r.factor_id;

	END LOOP;
	
	-- Update standard factors
	UPDATE csr.std_factor SET start_dtm = DATE '2000-01-01' WHERE std_factor_id = 184324243;
	UPDATE csr.std_factor SET start_dtm = DATE '2000-01-01' WHERE std_factor_id = 184324827;
	UPDATE csr.std_factor SET start_dtm = DATE '2000-01-01' WHERE std_factor_id = 184324535;
	UPDATE csr.std_factor SET start_dtm = DATE '2000-01-01' WHERE std_factor_id = 184325119;

END;
/

@update_tail
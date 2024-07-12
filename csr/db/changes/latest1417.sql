-- Please update version.sql too -- this keeps clean builds in sync
define version=1417
@update_header

-- Correct std measure conversion value
BEGIN
	UPDATE csr.std_measure_conversion 
	   SET a = 0.000000000948043428
	 WHERE description = 'MBTU (US)';
END;
/

-- Recompute any ind that uses a BTU 
-- like measure and has gas calculatons
BEGIN
	FOR a IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT DISTINCT (i.app_sid)
			  FROM csr.ind i, csr.ind g
			 WHERE i.ind_sid = g.map_to_ind_sid
			   AND i.measure_sid in (
			    SELECT measure_sid 
			      FROM csr.measure 
			     WHERE LOWER(description) LIKE '%btu%'
			 )
		)
	) LOOP
		security.user_pkg.logonadmin(a.host);
		FOR r IN (
			SELECT DISTINCT (i.ind_sid)
			  FROM csr.ind i, csr.ind g
			 WHERE i.app_sid = a.app_sid
			   AND g.app_sid = a.app_sid
			   AND i.ind_sid = g.map_to_ind_sid
			   AND i.measure_sid in (
			    SELECT measure_sid 
			      FROM csr.measure 
			     WHERE LOWER(description) LIKE '%btu%'
			)
		) LOOP
			csr.calc_pkg.AddJobsForInd(r.ind_sid);
		END LOOP;
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

@update_tail

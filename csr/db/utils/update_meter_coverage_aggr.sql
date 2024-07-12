DECLARE
	v_aggr_ind_group_id		number(10);
	v_lookup_key			csr.ind.lookup_key%TYPE :='METER_COVERAGE_DAYS';
BEGIN
	user_pkg.logonadmin('&&host');
	
	v_aggr_ind_group_id := csr.aggregate_ind_pkg.setGroup(v_lookup_key, 'csr.meter_aggr_pkg.GetDataCoverageDaysAggr');

	FOR rr IN (
		SELECT ind_sid
		  FROM csr.meter_data_coverage_ind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	)
	LOOP
		BEGIN
			INSERT INTO csr.aggregate_ind_group_member (aggregate_ind_group_id, ind_sid)
				VALUES (v_aggr_ind_group_id, rr.ind_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	csr.aggregate_ind_pkg.RefreshGroup(v_lookup_key);
	COMMIT;
END;
/

CREATE OR REPLACE PACKAGE BODY CSR.test_like_for_like_pkg AS

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;

PROCEDURE TestGetFinalValuesNoData AS
	v_like_for_like_object		t_like_for_like;
	v_like_for_like_val_table	t_like_for_like_val_table;

	v_val_cur					SYS_REFCURSOR;

	v_count						NUMBER;

	v_val_cur_period_start_dtm	DATE;
	v_val_cur_period_end_dtm	DATE;
	v_val_cur_ind_sid			NUMBER;
	v_val_cur_region_sid		NUMBER;
	v_val_cur_source_type_id	NUMBER;
	v_val_cur_source_id			NUMBER;
	v_val_cur_val_number		NUMBER;
	v_val_cur_error_code		NUMBER;
	v_val_cur_is_merged			NUMBER;
	v_val_cur_changed_dtm		DATE;
	v_val_cur_val_key			VARCHAR2(100);

BEGIN
	
	like_for_like_pkg.GetFinalValues(
		in_like_for_like_object		=>	v_like_for_like_object,
		in_like_for_like_val		=>	v_like_for_like_val_table,
		out_val_cur					=>	v_val_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_val_cur INTO 
			v_val_cur_period_start_dtm,
			v_val_cur_period_end_dtm,
			v_val_cur_ind_sid,
			v_val_cur_region_sid,
			v_val_cur_source_type_id,
			v_val_cur_source_id,
			v_val_cur_val_number,
			v_val_cur_error_code,
			v_val_cur_is_merged,
			v_val_cur_changed_dtm,
			v_val_cur_val_key
		;
		EXIT WHEN v_val_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_val_cur_period_start_dtm||'('||v_val_cur_period_end_dtm||')');
	END LOOP;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 results');

END;


PROCEDURE TestGetFinalValuesTempData AS
	v_like_for_like_object		t_like_for_like;
	v_like_for_like_val_table	t_like_for_like_val_table;

	v_val_cur					SYS_REFCURSOR;

	v_count						NUMBER;

	v_val_cur_period_start_dtm	DATE;
	v_val_cur_period_end_dtm	DATE;
	v_val_cur_ind_sid			NUMBER;
	v_val_cur_region_sid		NUMBER;
	v_val_cur_source_type_id	NUMBER;
	v_val_cur_source_id			NUMBER;
	v_val_cur_val_number		NUMBER;
	v_val_cur_error_code		NUMBER;
	v_val_cur_is_merged			NUMBER;
	v_val_cur_changed_dtm		DATE;
	v_val_cur_val_key			VARCHAR2(100);

BEGIN
	
	INSERT INTO t_like_for_like_val_normalised
		(ind_sid, region_sid, period_start_dtm, period_end_dtm, val_number, source_type_id, source_id)
	VALUES
		(1, 2, DATE '2022-01-01', DATE '2022-02-01', 3, CSR_DATA_PKG.SOURCE_TYPE_DIRECT, 4);

	like_for_like_pkg.GetFinalValues(
		in_like_for_like_object		=>	v_like_for_like_object,
		in_like_for_like_val		=>	v_like_for_like_val_table,
		out_val_cur					=>	v_val_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_val_cur INTO 
			v_val_cur_period_start_dtm,
			v_val_cur_period_end_dtm,
			v_val_cur_ind_sid,
			v_val_cur_region_sid,
			v_val_cur_source_type_id,
			v_val_cur_source_id,
			v_val_cur_val_number,
			v_val_cur_error_code,
			v_val_cur_is_merged,
			v_val_cur_changed_dtm,
			v_val_cur_val_key
		;
		EXIT WHEN v_val_cur%NOTFOUND;

		v_count := v_count + 1;
		TRACE(v_val_cur_period_start_dtm||'('||v_val_cur_period_end_dtm||')');
		unit_test_pkg.AssertAreEqual(1, v_val_cur_ind_sid, 'Expected valid ind_sid');
		unit_test_pkg.AssertAreEqual(2, v_val_cur_region_sid, 'Expected valid region_sid');
		unit_test_pkg.AssertAreEqual(CSR_DATA_PKG.SOURCE_TYPE_DIRECT, v_val_cur_source_type_id, 'Expected valid source_type_id');
		unit_test_pkg.AssertAreEqual(4, v_val_cur_source_id, 'Expected valid source_id');
		unit_test_pkg.AssertAreEqual(3, v_val_cur_val_number, 'Expected valid val_number');
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 result');

END;

PROCEDURE TestLoadExcludedValsRawTableNoDupes
AS
	v_dummy_sid			NUMBER(10);	
	v_region_root_sid	NUMBER(10);
	v_exclude_sid		NUMBER(10);	
	v_val_sid			NUMBER(10);
	v_L4L_sid			NUMBER(10);
	v_scenario_run_sid	NUMBER(10);
	v_out_cur			SYS_REFCURSOR;
	
	v_period_start_dtm	DATE;
	v_period_end_dtm	DATE;
	v_ind_sid			NUMBER(10);
	v_region_sid		NUMBER(10);
	v_source_type_id	NUMBER(10);
	v_source_id			NUMBER(10);
	v_val_number		NUMBER(24, 10);
	v_error_code		NUMBER(10);
	v_is_merged			NUMBER(1);
	v_changed_dtm		DATE;
	v_val_key			NUMBER(10);
BEGIN
	enable_pkg.EnableScenarios;

	enable_pkg.EnableLikeforlike;

	v_region_root_sid := unit_test_pkg.GetOrCreateRegion('L4L_REGION');
	v_exclude_sid := unit_test_pkg.GetOrCreateInd('EXCLUDE_IND');
	v_val_sid := unit_test_pkg.GetOrCreateInd('VAL_IND');
	
	v_dummy_sid := unit_test_pkg.SetIndicatorValue(
		in_ind_sid					=> v_exclude_sid,
		in_region_sid				=> v_region_root_sid,
		in_period_start				=> '01-JAN-2021',
		in_period_end				=> '01-FEB-2021',
		in_val_number				=> 1
	);
	
	v_dummy_sid := unit_test_pkg.SetIndicatorValue(
		in_ind_sid					=> v_exclude_sid,
		in_region_sid				=> v_region_root_sid,
		in_period_start				=> '01-FEB-2021',
		in_period_end				=> '01-MAR-2021',
		in_val_number				=> 1
	);
	
	v_dummy_sid := unit_test_pkg.SetIndicatorValue(
		in_ind_sid					=> v_exclude_sid,
		in_region_sid				=> v_region_root_sid,
		in_period_start				=> '01-MAR-2021',
		in_period_end				=> '01-APR-2021',
		in_val_number				=> 0
	);
	
	v_dummy_sid := unit_test_pkg.SetIndicatorValue(
		in_ind_sid					=> v_val_sid,
		in_region_sid				=> v_region_root_sid,
		in_period_start				=> '01-JAN-2021',
		in_period_end				=> '01-APR-2021',
		in_val_number				=> 100
	);
	
	like_for_like_pkg.CreateSlot(
		in_name						=>	'L4L Test',
		in_ind_sid					=>	v_exclude_sid,
		in_region_sid				=>	v_region_root_sid,
		in_include_inactive_regions	=>	1,
		in_period_start_dtm			=>	'01-JAN-2021',
		in_period_end_dtm			=>	'01-JAN-2022',
		in_period_set_id			=>	1,
		in_period_interval_id		=>	1,
		in_rule_type				=>	like_for_like_pkg.RULE_TYPE_PER_INTERVAL,
		out_like_for_like_sid		=>	v_L4L_sid
	);
	
	like_for_like_pkg.UNSEC_AddExcludedRegion(v_L4L_sid, v_region_root_sid, '01-JAN-2021', '01-FEB-2021');
	like_for_like_pkg.UNSEC_AddExcludedRegion(v_L4L_sid, v_region_root_sid, '01-FEB-2021', '01-MAR-2021');
	
	SELECT scenario_run_sid
	  INTO v_scenario_run_sid
	  FROM like_for_like_slot
	 WHERE like_for_like_sid = v_L4L_sid;

	like_for_like_pkg.GetScenarioData(
		in_start_dtm					=> '01-JAN-2021',
		in_end_dtm						=> '01-JAN-2022',
		in_scenario_run_sid				=> v_scenario_run_sid,
		out_val_cur						=> v_out_cur
	);
	
	LOOP
		FETCH v_out_cur INTO
			v_period_start_dtm,
			v_period_end_dtm,
			v_ind_sid,
			v_region_sid,
			v_source_type_id,
			v_source_id,
			v_val_number,
			v_error_code,
			v_is_merged,
			v_changed_dtm,
			v_val_key
		;
		EXIT WHEN v_out_cur%NOTFOUND;
		Trace(v_period_start_dtm || ' '|| v_period_end_dtm || ' '|| v_ind_sid || ' '|| v_region_sid || ' '|| v_val_number);
		
		IF v_region_sid = v_region_root_sid AND v_ind_sid = v_val_sid AND v_period_start_dtm = '01-MAR-2021' AND v_period_end_dtm = '01-APR-2021' THEN
			unit_test_pkg.AssertAreEqual(34, ROUND(v_val_number), 'Val doubled');
		END IF ;
	END LOOP;
	
	security.securableobject_pkg.deleteso(security.security_pkg.GetAct, v_L4L_sid);
	security.securableobject_pkg.deleteso(security.security_pkg.GetAct, v_exclude_sid);
	security.securableobject_pkg.deleteso(security.security_pkg.GetAct, v_val_sid);
	security.securableobject_pkg.deleteso(security.security_pkg.GetAct, v_region_root_sid);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
END;

PROCEDURE TearDownFixture
AS
BEGIN
	-- Clear down data after all tests have ran
	NULL;
END;

END test_like_for_like_pkg;
/

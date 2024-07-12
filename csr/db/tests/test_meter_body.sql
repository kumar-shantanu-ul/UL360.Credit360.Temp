CREATE OR REPLACE PACKAGE BODY csr.test_meter_pkg AS

v_site_name						VARCHAR2(200);
v_pit_meter_region_sid			security.security_pkg.T_SID_ID;
v_arb_meter_region_sid			security.security_pkg.T_SID_ID;
v_rt_meter_region_sid			security.security_pkg.T_SID_ID;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	-- dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_sid							NUMBER;
	v_days_ind_sid 					NUMBER;
	v_cost_ind_sid 					NUMBER;
	v_consump_ind_sid				NUMBER;
	v_meter_input_id_consumption	NUMBER;
	v_meter_input_id_cost			NUMBER;
	v_empty_ids						security_pkg.T_SID_IDS;
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	enable_pkg.EnableMeteringBase();
	enable_pkg.EnableRealtimeMetering();
	
	v_days_ind_sid := unit_test_pkg.GetOrCreateInd('DAYS');
	v_cost_ind_sid := unit_test_pkg.GetOrCreateInd('COST');
	v_consump_ind_sid := unit_test_pkg.GetOrCreateInd('CONSUMPTION');
	
	SELECT meter_input_id
	  INTO v_meter_input_id_consumption
	  FROM meter_input
	 WHERE lookup_key = 'CONSUMPTION';

	SELECT meter_input_id
	  INTO v_meter_input_id_cost
	  FROM meter_input
	 WHERE lookup_key = 'COST';
	
	BEGIN
		meter_pkg.AddTempMeterTypeInput( v_meter_input_id_consumption, 'SUM', v_consump_ind_sid);
		meter_pkg.AddTempMeterTypeInput( v_meter_input_id_cost, 'SUM', v_cost_ind_sid);
		meter_pkg.SaveMeterType(
			in_meter_type_id				=> NULL,
			in_label						=> 'MeterType1',
			in_group_key					=> 'GRPKEY',
			in_days_ind_sid					=> v_days_ind_sid,
			in_costdays_ind_sid				=> v_cost_ind_sid,
			out_meter_type_id				=> v_sid
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	
	v_pit_meter_region_sid := unit_test_pkg.GetOrCreateRegion('PIT_METER_REGION', NULL, csr_data_pkg.REGION_TYPE_METER);
	v_arb_meter_region_sid := unit_test_pkg.GetOrCreateRegion('ARB_METER_REGION', NULL, csr_data_pkg.REGION_TYPE_METER);
	v_rt_meter_region_sid := unit_test_pkg.GetOrCreateRegion('RT_METER_REGION', NULL, csr_data_pkg.REGION_TYPE_METER);

	meter_pkg.MakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> v_arb_meter_region_sid,
		in_meter_type_id			=> v_sid,
		in_note						=> 'ARB NOTE',
		in_source_type_id			=> 2,
		in_manual_data_entry		=> 1,
		in_reference				=> 'REF1',
		in_contract_ids				=> v_empty_ids,
		in_active_contract_id		=> NULL
	);
	
	meter_pkg.MakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> v_pit_meter_region_sid,
		in_meter_type_id			=> v_sid,
		in_note						=> 'PIT NOTE',
		in_source_type_id			=> 1,
		in_manual_data_entry		=> 1,
		in_reference				=> 'REF2',
		in_contract_ids				=> v_empty_ids,
		in_active_contract_id		=> NULL
	);

	meter_pkg.MakeMeter(
		in_act_id					=> SYS_CONTEXT('SECURITY','ACT'),
		in_region_sid				=> v_rt_meter_region_sid,
		in_meter_type_id			=> v_sid,
		in_note						=> 'RT NOTE',
		in_source_type_id			=> 2,
		in_manual_data_entry		=> 0,
		in_reference				=> 'REF3',
		in_contract_ids				=> v_empty_ids,
		in_active_contract_id		=> NULL
	);
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-1980',
		in_end_dtm 			=> '01-JAN-1980'
	);
END;
-- HELPER PROCS

-- Tests

PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodPIT AS
	v_test_name			VARCHAR2(100) := 'ImportPreventsRowsThatOverlapDataLockPeriodPIT';
	v_out				SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
	v_reading_id 		NUMBER;
BEGIN
	Trace(v_test_name);
	
	meter_pkg.SetMeterReading(
		in_act_id               => security.security_pkg.GetAct,
		in_region_sid           => v_pit_meter_region_sid,
		in_meter_reading_id     => NULL,
		in_entry_dtm			=> SYSDATE,
		in_reading_dtm         	=> '01-JAN-2000',
		in_val                  => 10,
		in_note                 => '',
		in_reference			=> '123',
		in_cost					=> 5,
		in_doc_id				=> NULL,
		in_cache_key			=> '',
		out_reading_id          => v_reading_id
	);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);
	
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Start equal to lock start
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_pit_meter_region_sid, '01-JAN-2000', NULL, v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
	
	-- Start in lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-2, v_pit_meter_region_sid, '01-MAR-2000', NULL, v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
			
	-- Previous record in lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-3, v_pit_meter_region_sid, '01-MAR-2001', NULL, v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');		
	
	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (	
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP	  
		unit_test_pkg.AssertAreEqual('Reading date inside data lock period', r.error_msg, 'Row not marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodARB AS
	v_test_name		VARCHAR2(100) := 'ImportPreventsRowsThatOverlapDataLockPeriodARB';
	v_out			SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
BEGIN
	Trace(v_test_name);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);
	
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Start and end in lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_arb_meter_region_sid, '01-JAN-2000', '01-FEB-2000', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
	-- End in lock		
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-2, v_arb_meter_region_sid, '01-NOV-1999', '01-FEB-2000', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
	-- Start in lock		
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-3, v_arb_meter_region_sid, '01-NOV-2000', '01-FEB-2001', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');

	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (	
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP	  
		unit_test_pkg.AssertAreEqual('Reading date inside data lock period', r.error_msg, 'Row not marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE ImportPreventsRowsThatOverlapDataLockPeriodRT AS
	v_test_name			VARCHAR2(100) := 'ImportPreventsRowsThatOverlapDataLockPeriodRT';
	v_out				SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
	v_reading_id 		NUMBER;
BEGIN
	Trace(v_test_name);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);
	
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Start and end in lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_rt_meter_region_sid, '01-JAN-2000', '01-FEB-2000', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
	-- End in lock		
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-2, v_rt_meter_region_sid, '01-NOV-1999', '01-FEB-2000', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');
	-- Start in lock		
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-3, v_rt_meter_region_sid, '01-NOV-2000', '01-FEB-2001', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');

	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (	
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP	  
		unit_test_pkg.AssertAreEqual('Reading date inside data lock period', r.error_msg, 'Row not marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodPIT AS
	v_test_name		VARCHAR2(100) := 'ImportAllowsRowsThatAreOutsideDataLockPeriodPIT';
	v_out			SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
	v_reading_id 		NUMBER;
BEGIN
	Trace(v_test_name);
	
	meter_pkg.SetMeterReading(
		in_act_id               => security.security_pkg.GetAct,
		in_region_sid           => v_pit_meter_region_sid,
		in_meter_reading_id     => NULL,
		in_entry_dtm			=> SYSDATE,
		in_reading_dtm         	=> '01-JAN-2001',
		in_val                  => 10,
		in_note                 => '',
		in_reference			=> '123',
		in_cost					=> 5,
		in_doc_id				=> NULL,
		in_cache_key			=> '',
		out_reading_id          => v_reading_id
	);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);
	
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Start and end in lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_arb_meter_region_sid, '01-FEB-2001', NULL, v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');

	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (	
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP	  
		unit_test_pkg.AssertNotEqual('Reading date inside data lock period', r.error_msg, 'Row incorrectly marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodARB AS
	v_test_name		VARCHAR2(100) := 'ImportAllowsRowsThatAreOutsideDataLockPeriodARB';
	v_out			SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
BEGIN
	Trace(v_test_name);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);
	
	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';
	
	-- Start and end outside lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_arb_meter_region_sid, '01-JAN-2001', '01-FEB-2001', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');

	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (	
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP	  
		unit_test_pkg.AssertNotEqual('Reading date inside data lock period', r.error_msg, 'Row incorrectly marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE ImportAllowsRowsThatAreOutsideDataLockPeriodRT AS
	v_test_name		VARCHAR2(100) := 'ImportAllowsRowsThatAreOutsideDataLockPeriodRT';
	v_out			SYS_REFCURSOR;
	v_meter_input_id 	NUMBER;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-2000',
		in_end_dtm 			=> '01-JAN-2001'
	);

	SELECT meter_input_id
	  INTO v_meter_input_id
	  FROM csr.meter_input
	 WHERE app_sid  = SYS_CONTEXT('SECURITY', 'APP')
	   AND lookup_key = 'CONSUMPTION';

	-- Start and end outside lock
	INSERT INTO temp_meter_reading_rows
		(source_row, region_sid, start_dtm, end_dtm, meter_input_id, consumption, 
		reference, note, reset_val, priority, unit_of_measure, statement_id)
	 VALUES (-1, v_rt_meter_region_sid, '01-JAN-2001', '01-FEB-2001', v_meter_input_id, 50, 
			'123', '', NULL, NULL, NULL, '');

	meter_pkg.ImportMeterReadingRows(v_out);
	
	FOR r IN (
		SELECT source_row, error_msg
		  FROM temp_meter_reading_rows
	)
	LOOP
		unit_test_pkg.AssertNotEqual('Reading date inside data lock period', r.error_msg, 'Row incorrectly marked as error for source row: ' || r.source_row);
	END LOOP;
END;

PROCEDURE TestSetArbitraryPeriodAfter AS
	v_test_name					VARCHAR2(100) := 'TestSetArbitraryPeriodHappyPathAfter';
	v_old_count					NUMBER;
	v_new_count					NUMBER;
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '01-Dec-2022'
	);

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	meter_pkg.SetArbitraryPeriod(
			in_region_sid 		=> v_pit_meter_region_sid,
			in_meter_reading_id => 0,
			in_entry_dtm 		=> SYSDATE,
			in_start_dtm        => '03-Dec-2022',
			in_end_dtm          => '31-Dec-2022',
			in_val            	=> 5,
			in_note             => 'Some Note',
			in_reference		=> 'Sample Ref',
			in_cost				=> 6,
			in_doc_id			=> NULL,
			in_cache_key		=> '',
			in_is_estimate		=> 5,
			out_reading_id      => v_meter_reading_id
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(v_new_count,v_old_count + 1, 'New record must be inserted');
END;

PROCEDURE TestSetArbitraryPeriodOn AS
	v_test_name					VARCHAR2(100) := 'TestSetArbitraryPeriodHappyPathOn';
	v_old_count					NUMBER;
	v_new_count					NUMBER;
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '01-Dec-2022'
	);

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	meter_pkg.SetArbitraryPeriod(
			in_region_sid 		=> v_pit_meter_region_sid,
			in_meter_reading_id => 0,
			in_entry_dtm 		=> SYSDATE,
			in_start_dtm        => '01-Dec-2022',
			in_end_dtm          => '31-Dec-2022',
			in_val            	=> 5,
			in_note             => 'Some Note',
			in_reference		=> 'Sample Ref',
			in_cost				=> 6,
			in_doc_id			=> NULL,
			in_cache_key		=> '',
			in_is_estimate		=> 5,
			out_reading_id      => v_meter_reading_id
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	csr.unit_test_pkg.AssertAreEqual(v_new_count,v_old_count + 1, 'New record must be inserted');
END;

PROCEDURE TestUpdatingLockedInPeriod AS
	v_test_name					VARCHAR2(100) := 'TestUpdatingLockedInPeriodNonHappyPath';
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '31-Dec-2022'
	);

	BEGIN
		meter_pkg.SetArbitraryPeriod(
			in_region_sid 		=> v_pit_meter_region_sid,
			in_meter_reading_id => 0,
			in_entry_dtm 		=> SYSDATE,
			in_start_dtm        => '01-Dec-2022',
			in_end_dtm          => '31-Dec-2022',
			in_val            	=> 5,
			in_note             => 'Some Note',
			in_reference		=> 'Sample Ref',
			in_cost				=> 6,
			in_doc_id			=> NULL,
			in_cache_key		=> '',
			in_is_estimate		=> 5,
			out_reading_id      => v_meter_reading_id
		);

		unit_test_pkg.TestFail('Expecting an Exception here');

	EXCEPTION
		WHEN csr.csr_data_pkg.METER_WITHIN_LOCK_PERIOD THEN
			NULL; -- Expected result
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Unexpected Exception was thrown');
	END;
END;

PROCEDURE TestDeleteMeterReading AS
	v_test_name					VARCHAR2(100) := 'TestDeleteMeterReadingHappyPath';
	v_old_count					NUMBER;
	v_new_count					NUMBER;
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '02-Dec-2022'
	);

	meter_pkg.SetArbitraryPeriod(
			in_region_sid 		=> v_pit_meter_region_sid,
			in_meter_reading_id => 0,
			in_entry_dtm 		=> SYSDATE,
			in_start_dtm        => '03-Dec-2022',
			in_end_dtm          => '31-Dec-2022',
			in_val            	=> 5,
			in_note             => 'Some Note',
			in_reference		=> 'Sample Ref',
			in_cost				=> 6,
			in_doc_id			=> NULL,
			in_cache_key		=> '',
			in_is_estimate		=> 5,
			out_reading_id      => v_meter_reading_id
	);

	SELECT COUNT(*)
	  INTO v_old_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	meter_pkg.DeleteMeterReading(SYS_CONTEXT('SECURITY', 'ACT'), v_meter_reading_id);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM meter_reading
	 WHERE region_sid = v_pit_meter_region_sid
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	unit_test_pkg.AssertIsTrue(v_new_count < v_old_count,'Meter reading should be deleted.');
END;

PROCEDURE TestDeleteLockedInPeriod AS
	v_test_name					VARCHAR2(100) := 'TestDeleteLockedInPeriodNonHappyPath';
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Nov-2022',
		in_end_dtm 			=> '30-Nov-2022'
	);

	meter_pkg.SetArbitraryPeriod(
		in_region_sid 		=> v_pit_meter_region_sid,
		in_meter_reading_id => 0,
		in_entry_dtm 		=> SYSDATE,
		in_start_dtm        => '01-Dec-2022',
		in_end_dtm          => '31-Dec-2022',
		in_val            	=> 5,
		in_note             => 'Some Note',
		in_reference		=> 'Sample Ref',
		in_cost				=> 6,
		in_doc_id			=> NULL,
		in_cache_key		=> '',
		in_is_estimate		=> 5,
		out_reading_id      => v_meter_reading_id
	);
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '31-Dec-2022'
	);

	BEGIN
		meter_pkg.DeleteMeterReading(SYS_CONTEXT('SECURITY', 'ACT'), v_meter_reading_id);
		unit_test_pkg.TestFail('Expecting an Exception here');

	EXCEPTION
		WHEN csr.csr_data_pkg.METER_WITHIN_LOCK_PERIOD THEN
			NULL; -- Expected result
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Unexpected Exception was thrown');
	END;
END;

PROCEDURE TestSetMeterReadingAfter
AS
	v_test_name					VARCHAR2(100) := 'TestSetMeterReadingHappyPathAfter';
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
	v_meter_note 			    meter_reading.note%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '01-Dec-2022'
	);

	meter_pkg.SetMeterReading(
		in_act_id               => security.security_pkg.GetAct,
		in_region_sid           => v_pit_meter_region_sid,
		in_meter_reading_id     =>  0,
		in_entry_dtm			=> SYSDATE,
		in_reading_dtm         	=> '03-Dec-2022',
		in_val                  => 10,
		in_note                 => 'Sample Note',
		in_reference			=> 'Sample Ref',
		in_cost					=> 5,
		in_doc_id				=> NULL,
		in_cache_key			=> '',
		out_reading_id          => v_meter_reading_id
	);

	SELECT note
	  INTO v_meter_note
	  FROM csr.meter_reading
	 WHERE meter_reading_id = v_meter_reading_id;

	csr.unit_test_pkg.AssertAreEqual('Sample Note', v_meter_note, 'Record should be updated');
END;

PROCEDURE TestSetMeterReadingOn
AS
	v_test_name					VARCHAR2(100) := 'TestSetMeterReadingHappyPathOn';
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
	v_meter_note 			    meter_reading.note%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '01-Dec-2022'
	);

	meter_pkg.SetMeterReading(
		in_act_id               => security.security_pkg.GetAct,
		in_region_sid           => v_pit_meter_region_sid,
		in_meter_reading_id     =>  0,
		in_entry_dtm			=> SYSDATE,
		in_reading_dtm         	=> '01-Dec-2022',
		in_val                  => 10,
		in_note                 => 'Sample Note',
		in_reference			=> 'Sample Ref',
		in_cost					=> 5,
		in_doc_id				=> NULL,
		in_cache_key			=> '',
		out_reading_id          => v_meter_reading_id
	);

	SELECT note
	  INTO v_meter_note
	  FROM csr.meter_reading
	 WHERE meter_reading_id = v_meter_reading_id;

	csr.unit_test_pkg.AssertAreEqual('Sample Note', v_meter_note, 'Record should be updated');
END;

PROCEDURE TestSetMeterLockedInPeriod AS
	v_test_name					VARCHAR2(100) := 'TestSetMeterLockedInPeriodNonHappyPath';
	v_meter_reading_id 			meter_reading.meter_reading_id%TYPE;
BEGIN
	Trace(v_test_name);

	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-Dec-2022',
		in_end_dtm 			=> '01-Dec-2022'
	);

	BEGIN
		meter_pkg.SetMeterReading(
			in_act_id               => security.security_pkg.GetAct,
			in_region_sid           => v_pit_meter_region_sid,
			in_meter_reading_id     =>  0,
			in_entry_dtm			=> SYSDATE,
			in_reading_dtm         	=> '01-NOV-2022',
			in_val                  => 10,
			in_note                 => 'Sample Note',
			in_reference			=> 'Sample Ref',
			in_cost					=> 5,
			in_doc_id				=> NULL,
			in_cache_key			=> '',
			out_reading_id          => v_meter_reading_id
		);

		unit_test_pkg.TestFail('Expecting an Exception here');

	EXCEPTION
		WHEN csr.csr_data_pkg.METER_WITHIN_LOCK_PERIOD THEN
			NULL; -- Expected result
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('Unexpected Exception was thrown');
	END;
END;
--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
	
	DELETE FROM csr.temp_meter_reading_rows;
	
	DELETE FROM csr.meter_reading WHERE region_sid IN (v_pit_meter_region_sid, v_arb_meter_region_sid, v_rt_meter_region_sid);
	
	DELETE FROM csr.meter_source_data WHERE region_sid IN (v_rt_meter_region_sid);
END;

PROCEDURE TearDownFixture AS
	v_sid		NUMBER;
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	
	DELETE FROM csr.temp_meter_reading_rows;
	
	SELECT MIN(region_sid)
	  INTO v_sid
	  FROM region
	 WHERE name = 'PIT_METER_REGION';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_sid
	  FROM region
	 WHERE name = 'ARB_METER_REGION';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	SELECT MIN(region_sid)
	  INTO v_sid
	  FROM region
	 WHERE name = 'RT_METER_REGION';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;

	SELECT MIN(ind_sid)
	  INTO v_sid
	  FROM ind
	 WHERE lookup_key = 'DAYS';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	SELECT MIN(ind_sid)
	  INTO v_sid
	  FROM ind
	 WHERE lookup_key = 'COST';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	SELECT MIN(ind_sid)
	  INTO v_sid
	  FROM ind
	 WHERE lookup_key = 'CONSUMPTION';
	
	IF v_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_sid);
	END IF;
	
	csr_data_pkg.LockPeriod(
		in_act_id 			=> security.security_pkg.GetAct,
		in_app_sid 			=> security.security_pkg.GetApp,
		in_start_dtm 		=> '01-JAN-1980',
		in_end_dtm 			=> '01-JAN-1980'
	);
END;

END test_meter_pkg;
/

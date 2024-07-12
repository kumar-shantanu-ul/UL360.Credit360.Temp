CREATE OR REPLACE PACKAGE BODY csr.test_meter_patch_pkg AS

v_site_name		VARCHAR2(200);

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	--dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE SetUp AS
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;



-- HELPER PROCS



-- Tests

PROCEDURE CantAddDupTempMeterCons AS
	v_test_name		VARCHAR2(100) := 'CantAddDupTempMeterCons';
	v_count			NUMBER;
BEGIN
	Trace(v_test_name);

	-- expect to start with empty
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption;
	  
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 MC records'||' - '||v_count||' found.');

	-- test with no MC records
		
	csr.meter_patch_pkg.INT_InsertConsumptionNoDup(
		in_region_sid			=> 100,
		in_meter_input_id		=> 200,
		in_this_priority		=> 2,
		in_last_priority		=> 1,
		in_start_dtm			=> DATE '2019-01-01',
		in_end_dtm				=> DATE '2019-02-01'
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption;

	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 MC records'||' - '||v_count||' found.');

	-- test with one MC record with a value
	Trace(v_test_name||': test with one MC record with a value');
	INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
	VALUES (100, 200, 1,  DATE '2019-01-01',  DATE '2019-02-01', 10);

	csr.meter_patch_pkg.INT_InsertConsumptionNoDup(
		in_region_sid			=> 100,
		in_meter_input_id		=> 200,
		in_this_priority		=> 2,
		in_last_priority		=> 1,
		in_start_dtm			=> DATE '2019-01-01',
		in_end_dtm				=> DATE '2019-02-01'
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption;

	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected 2 MC records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption
	 WHERE priority = 2;

	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 priority 2 MC records'||' - '||v_count||' found.');
	
	
	-- test with another MC record with no value
	Trace(v_test_name||': test with another MC record with no value');
	INSERT INTO temp_meter_consumption (region_sid, meter_input_id, priority, start_dtm, end_dtm, val_number)
	VALUES (100, 200, 1,  DATE '2019-01-01',  DATE '2019-02-01', NULL);

	csr.meter_patch_pkg.INT_InsertConsumptionNoDup(
		in_region_sid			=> 100,
		in_meter_input_id		=> 200,
		in_this_priority		=> 2,
		in_last_priority		=> 1,
		in_start_dtm			=> DATE '2019-01-01',
		in_end_dtm				=> DATE '2019-02-01'
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption;

	unit_test_pkg.AssertIsTrue(v_count = 4, 'Expected 4 MC records'||' - '||v_count||' found.');

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.temp_meter_consumption
	 WHERE priority = 2;

	unit_test_pkg.AssertIsTrue(v_count = 2, 'Expected 2 priority 2 MC records'||' - '||v_count||' found.');
	

END;

--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	DELETE FROM csr.temp_meter_consumption;
END;

END test_meter_patch_pkg;
/

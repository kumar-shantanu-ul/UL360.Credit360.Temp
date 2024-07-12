CREATE OR REPLACE PACKAGE BODY CSR.test_period_set_pkg AS

C_Period_Set_Id period_set.period_set_id%TYPE;
C_Annual_Period_Id period_set.annual_periods%TYPE := 0;
C_Period_Set_Label period_set.label%TYPE := 'Test_PeriodSet_Label';
C_Period_Id period.period_id%TYPE := 1;
C_Period_Year period_dates.year%TYPE := '2022';
C_Period_Interval_Id period_interval.period_interval_id%TYPE := 1;
C_Start_period_id period_interval_member.start_period_id%TYPE := 1;

PROCEDURE Trace(in_str VARCHAR2) AS
BEGIN
	dbms_output.put_line(in_str);
	--NULL;
END;

PROCEDURE CreatePeriodSet AS
BEGIN
	period_pkg.AddPeriodSet(
		in_annual_periods => C_Annual_Period_Id,
		in_label => C_Period_Set_Label,
		out_period_set_id => C_Period_Set_Id
	);
END;

PROCEDURE CreatePeriods AS
BEGIN
	period_pkg.AddPeriod(
		in_period_set_id => C_Period_Set_Id,
		in_label => 'M1',
		out_period_id => C_Period_Id
	);
	
	period_pkg.AddPeriod(
		in_period_set_id => C_Period_Set_Id,
		in_label => 'M2',
		out_period_id => C_Period_Id
	);
END;

PROCEDURE CreatePeriodDates AS
BEGIN
	period_pkg.AddPeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year,
		in_start_dtm => TO_DATE('2022-01-01','YYYY-MM-DD'),
		in_end_dtm => TO_DATE('2022-01-31','YYYY-MM-DD')
	);
END;

PROCEDURE CreatePeriodInterval AS
BEGIN
	period_pkg.AddPeriodInterval(
		in_period_set_id => C_Period_Set_Id,
		in_single_interval_label => 'W{0:I} {0:YYYY}',
		in_multiple_interval_label => 'W{0:I} {0:YYYY} - W{1:I} {1:YYYY}',
		in_label => 'Weekly',
		in_single_interval_no_year_label => 'W{0:I}',
		out_period_interval_id => C_Period_Interval_Id
	);
END;

PROCEDURE CreatePeriodIntervalMember AS
BEGIN
	period_pkg.AddPeriodIntervalMember(
		in_period_set_id => C_Period_Set_Id,
		in_period_interval_id => C_Period_Interval_Id,
		in_start_period_id => C_Start_period_id,
		in_end_period_id =>  C_Start_period_id
	);
END;

PROCEDURE SeedData AS
BEGIN
	CreatePeriodSet();
	CreatePeriods();
	CreatePeriodDates();
	CreatePeriodInterval();
	CreatePeriodIntervalMember();
END;

PROCEDURE TestAddPeriodSet AS
	v_old_count				NUMBER;
	v_new_count				NUMBER;
	v_new_label				VARCHAR2(255);
	v_new_period_set_id		csr.period.period_set_id%TYPE;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.period_set;

	period_pkg.AddPeriodSet(
		in_annual_periods => C_Annual_Period_Id,
		in_label => C_Period_Set_Label,
		out_period_set_id =>v_new_period_set_id
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period_set;

	SELECT label
	  INTO v_new_label
	  FROM csr.period_set
	  WHERE period_set_id = v_new_period_set_id;

	unit_test_pkg.AssertAreEqual(v_old_count + 1, v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual(C_Period_Set_Label || ' New', v_new_label, 'New Label should be created');
END;

PROCEDURE TestUpdatePeriodSet AS
	v_label_updated		VARCHAR2(255) := 'TestPeriod_AddPeriodSet_Updated';
	v_result_label		VARCHAR2(255);
BEGIN
	period_pkg.UpdatePeriodSet(
		in_period_set_id => C_Period_Set_Id,
		in_annual_periods => C_Annual_Period_Id,
		in_label => v_label_updated
	);

	SELECT label
	  INTO v_result_label
	  FROM csr.period_set
	  WHERE period_set_id = C_Period_Set_Id;

	unit_test_pkg.AssertAreEqual(v_label_updated, v_result_label, 'Updated Label should match');
END;

PROCEDURE TestDeletePeriodSet AS
	v_count				NUMBER;
BEGIN
	period_pkg.DeletePeriodSet(
		in_period_set_id => C_Period_Set_Id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.period_set
	 WHERE period_set_id = C_Period_Set_Id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');

	--Reseed the data
	SeedData();
END;

PROCEDURE TestAddPeriod AS
	v_label				VARCHAR2(255);
	v_old_count			NUMBER;
	v_new_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.period
	 WHERE period_set_id = C_Period_Set_Id;

	period_pkg.AddPeriod(
		in_period_set_id => C_Period_Set_Id,
		in_label => 'M3',
		out_period_id => C_Period_Id
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period
	 WHERE period_set_id = C_Period_Set_Id;

	SELECT label
	  INTO v_label
	  FROM csr.period
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual('M3', v_label, 'New Label should be created');
END;

PROCEDURE TestUpdatePeriod AS
	v_label_updated		VARCHAR2(255) := 'Jan(Modified)';
	v_result_label		VARCHAR2(255);
BEGIN
	period_pkg.UpdatePeriod(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_label => v_label_updated
	);

	SELECT label
	  INTO v_result_label
	  FROM csr.period
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id;

	unit_test_pkg.AssertAreEqual(v_label_updated, v_result_label, 'Updated Label should match');
END;

PROCEDURE TestDeletePeriod AS
	v_period_id			NUMBER;
	v_count				NUMBER;
BEGIN
	period_pkg.DeletePeriod(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.period
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');

	--Reseed periods
	CreatePeriods();
END;

PROCEDURE TestAddPeriodDates AS
	v_start				VARCHAR2(255);
	v_start_dtm			DATE;
	v_end				VARCHAR2(255);
	v_end_dtm			DATE;
	v_old_count			NUMBER;
	v_new_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year;

	period_pkg.AddPeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year,
		in_start_dtm => TO_DATE('2022-02-01','YYYY-MM-DD'),
		in_end_dtm => TO_DATE('2022-02-28','YYYY-MM-DD')
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year;

	SELECT start_dtm, end_dtm, start_dtm, end_dtm
	  INTO v_start, v_end, v_start_dtm, v_end_dtm
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year;

	Trace('tdate '||TRUNC(TO_DATE('2022-02-01','YYYY-MM-DD'), 'DAY'));

	unit_test_pkg.AssertAreEqual((v_old_count + 1), v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual('01-FEB-22', v_start, 'Period Date should be created with start date.');
	unit_test_pkg.AssertAreEqual('28-FEB-22', v_end, 'Period Date should be created with start date.');


	period_pkg.AddPeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year + 1,
		in_start_dtm => TO_DATE('2023-02-28 10:01','YYYY-MM-DD HH:SS'),
		in_end_dtm => TO_DATE('2023-03-31 11:02','YYYY-MM-DD HH:SS')
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year + 1;

	SELECT start_dtm, end_dtm, start_dtm, end_dtm
	  INTO v_start, v_end, v_start_dtm, v_end_dtm
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year + 1;

	unit_test_pkg.AssertAreEqual((v_old_count + 1), v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual('28-FEB-23', v_start, 'Period Date should be created with start date.');
	unit_test_pkg.AssertAreEqual('31-MAR-23', v_end, 'Period Date should be created with end date.');
	unit_test_pkg.AssertAreEqual(0, extract(hour from CAST(v_start_dtm as timestamp)), 'Period Date hour should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(minute from CAST(v_start_dtm as timestamp)), 'Period Date minute should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(second from CAST(v_start_dtm as timestamp)), 'Period Date second should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(hour from CAST(v_end_dtm as timestamp)), 'Period Date hour should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(minute from CAST(v_end_dtm as timestamp)), 'Period Date minute should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(second from CAST(v_end_dtm as timestamp)), 'Period Date second should be zero.');
END;

PROCEDURE TestUpdatePeriodDates AS
	v_start				VARCHAR2(255);
	v_start_dtm			DATE;
	v_end				VARCHAR2(255);
	v_end_dtm			DATE;
BEGIN
	period_pkg.UpdatePeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year,
		in_start_dtm => TO_DATE('2022-03-01','YYYY-MM-DD'),
		in_end_dtm => TO_DATE('2022-03-31','YYYY-MM-DD')
	);

	SELECT start_dtm, end_dtm,  start_dtm, end_dtm
	  INTO v_start, v_end, v_start_dtm, v_end_dtm
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year;

	unit_test_pkg.AssertAreEqual('01-MAR-22', v_start, 'Start dtm should be updated.');
	unit_test_pkg.AssertAreEqual('31-MAR-22', v_end, 'End dtm should be updated.');


	period_pkg.UpdatePeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year,
		in_start_dtm => TO_DATE('2022-04-01 08:01','YYYY-MM-DD HH:SS'),
		in_end_dtm => TO_DATE('2022-04-30 09:02','YYYY-MM-DD HH:SS')
	);

	SELECT start_dtm, end_dtm,  start_dtm, end_dtm
	  INTO v_start, v_end, v_start_dtm, v_end_dtm
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id
	   AND year = C_Period_Year;

	unit_test_pkg.AssertAreEqual('01-APR-22', v_start, 'Start dtm should be updated.');
	unit_test_pkg.AssertAreEqual('30-APR-22', v_end, 'End dtm should be updated.');
	unit_test_pkg.AssertAreEqual(0, extract(hour from CAST(v_start_dtm as timestamp)), 'Period Date hour should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(minute from CAST(v_start_dtm as timestamp)), 'Period Date minute should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(second from CAST(v_start_dtm as timestamp)), 'Period Date second should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(hour from CAST(v_end_dtm as timestamp)), 'Period Date hour should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(minute from CAST(v_end_dtm as timestamp)), 'Period Date minute should be zero.');
	unit_test_pkg.AssertAreEqual(0, extract(second from CAST(v_end_dtm as timestamp)), 'Period Date second should be zero.');
END;

PROCEDURE TestDeletePeriodDates AS
	v_count				NUMBER;
BEGIN
	period_pkg.DeletePeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year
	);

	period_pkg.DeletePeriodDates(
		in_period_set_id => C_Period_Set_Id,
		in_period_id => C_Period_Id,
		in_year => C_Period_Year + 1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.period_dates
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_id = C_Period_Id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');

	--Reseed period dates
	CreatePeriodDates();
END;

PROCEDURE TestAddPeriodInterval AS
	v_label				VARCHAR2(255);
	v_old_count			NUMBER;
	v_new_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.period_interval
	 WHERE period_set_id = C_Period_Set_Id;

	period_pkg.AddPeriodInterval(
		in_period_set_id => C_Period_Set_Id,
		in_single_interval_label => 'Q{0:I} {0:YYYY}',
		in_multiple_interval_label => 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}',
		in_label => 'Quarterly',
		in_single_interval_no_year_label => 'Q{0:I}',
		out_period_interval_id => C_Period_Interval_Id
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period_interval
	 WHERE period_set_id = C_Period_Set_Id;

	SELECT label
	  INTO v_label
	  FROM csr.period_interval
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id;

	unit_test_pkg.AssertAreEqual(v_old_count + 1, v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual('Quarterly', v_label, 'Period Interval should be created with the new label.');
END;

PROCEDURE TestUpdatePeriodInterval AS
	v_label			VARCHAR2(255);
BEGIN
	period_pkg.UpdatePeriodInterval(
		in_period_set_id => C_Period_Set_Id,
		in_period_interval_id => C_Period_Interval_Id,
		in_single_interval_label => 'Q{0:I} {0:YYYY}',
		in_multiple_interval_label => 'Q{0:I} {0:YYYY} - Q{1:I} {1:YYYY}',
		in_label => 'Quarterly(Modified)',
		in_single_interval_no_year_label => 'Q{0:I}'
	);

	SELECT label
	  INTO v_label
	  FROM csr.period_interval
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id  = C_Period_Interval_Id;

	unit_test_pkg.AssertAreEqual('Quarterly(Modified)', v_label, 'Label should be updated.');
END;

PROCEDURE TestDeletePeriodInterval AS
	v_count					NUMBER;
BEGIN
	period_pkg.DeletePeriodInterval(
		in_period_set_id => C_Period_Set_Id,
		in_period_interval_id => C_Period_Interval_Id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.period_interval
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');

	--Reseed Period Interval
	CreatePeriodInterval();
END;

PROCEDURE TestAddPeriodIntervalMember AS
	v_old_count				NUMBER;
	v_new_count				NUMBER;
	v_end_period_id			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_old_count
	  FROM csr.period_interval_member
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id;

	period_pkg.AddPeriodIntervalMember(
		in_period_set_id => C_Period_Set_Id,
		in_period_interval_id => C_Period_Interval_Id,
		in_start_period_id => C_Period_Id - 1, --C_Period_Id points to max period_id
		in_end_period_id =>  C_Period_Id - 1
	);

	SELECT COUNT(*)
	  INTO v_new_count
	  FROM csr.period_interval_member
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id;

	SELECT end_period_id
	  INTO v_end_period_id
	  FROM csr.period_interval_member
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id
	   AND start_period_id = C_Period_Id - 1;

	unit_test_pkg.AssertAreEqual((v_old_count+ 1), v_new_count, 'Row count must increment by one.');
	unit_test_pkg.AssertAreEqual(C_Period_Id - 1, v_end_period_id, 'Period Interval should be created with End Period Id.');
END;

PROCEDURE TestDeletePeriodIntervalMember AS
	v_count					NUMBER;
BEGIN
	period_pkg.DeletePeriodIntervalMembers(
		in_period_set_id => C_Period_Set_Id,
		in_period_interval_id => C_Period_Interval_Id
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.period_interval_member
	 WHERE period_set_id = C_Period_Set_Id
	   AND period_interval_id = C_Period_Interval_Id;

	unit_test_pkg.AssertAreEqual(0, v_count, 'Deleted record should not be found');

	--Reseed Period Interval Member
	CreatePeriodIntervalMember();
END;

PROCEDURE DeletePeriodSet
AS
BEGIN
	DELETE FROM csr.period_interval_member WHERE period_set_id > 1;
	DELETE FROM csr.period_interval WHERE period_set_id > 1;
	DELETE FROM csr.period_dates WHERE period_set_id > 1;
	DELETE FROM csr.period WHERE period_set_id > 1;
	DELETE FROM csr.period_set WHERE period_set_id > 1;
	DELETE FROM csr.period_set WHERE period_set_id > 1;
	DELETE FROM csr.period_set WHERE period_set_id > 1;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
	DeletePeriodSet();
	SeedData();
END;

PROCEDURE TearDownFixture
AS
BEGIN
	-- Clear down data after all tests have ran
	DeletePeriodSet();
END;

END test_period_set_pkg;
/

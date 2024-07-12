CREATE OR REPLACE PACKAGE BODY csr.test_aggregate_ind_pkg AS

v_site_name VARCHAR2(100);

FUNCTION GetOrCreateBucket(
	in_description 			IN	csr.data_bucket.description%TYPE
) RETURN NUMBER
AS
	v_sid			csr.data_bucket.data_bucket_sid%TYPE;
BEGIN
	BEGIN
		SELECT data_bucket_sid
		  INTO v_sid
		  FROM csr.data_bucket
		 WHERE description = in_description;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.data_bucket_pkg.CreateBucket(
				in_description			=> in_description,
				in_enabled				=> 1,
				out_data_bucket_sid		=> v_sid
			);
	END;
	RETURN v_sid;
END;

FUNCTION GetOrCreateAggIndGroup(
	in_name				IN	aggregate_ind_group.name%TYPE,
	in_fetch_sp			IN	aggregate_ind_group.data_bucket_fetch_sp%TYPE,
	in_bucket_sid		IN	csr.data_bucket.data_bucket_sid%TYPE DEFAULT NULL
) RETURN aggregate_ind_group.aggregate_ind_group_id%TYPE
AS
	v_agg_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	BEGIN
		SELECT aggregate_ind_group_id
		  INTO v_agg_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name = in_name;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			csr.aggregate_ind_pkg.CreateGroup(
				in_name						=> in_name,
				in_label					=> in_name,
				in_helper_proc				=> in_fetch_sp,
				in_helper_proc_args			=> 'vals',
				out_aggregate_ind_group_id	=> v_agg_ind_group_id
			);
	END;
	
	IF in_bucket_sid IS NOT NULL THEN
		UPDATE aggregate_ind_group
		   SET data_bucket_sid = in_bucket_sid,
			   data_bucket_fetch_sp = in_fetch_sp
		 WHERE aggregate_ind_group_id = v_agg_ind_group_id;
	END IF;
	
	RETURN v_agg_ind_group_id;
END;

PROCEDURE DataFetchDoesntThrowWithNoInstance
AS
	v_bucket_sid			csr.data_bucket.data_bucket_sid%TYPE;
	v_agg_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_cur					SYS_REFCURSOR;
BEGIN
	unit_test_pkg.StartTest('csr.test_aggregate_ind_pkg.DataFetchDoesntThrowWithNoInstance');
	
	v_bucket_sid := GetOrCreateBucket(in_description => 'DataFetchDoesntThrowWithNoInstance');
	v_agg_ind_group_id := GetOrCreateAggIndGroup(
		in_name			=> 'DataFetchDoesntThrowWithNoInstance',
		in_fetch_sp		=> 'csr.test_aggregate_ind_pkg.GetData',
		in_bucket_sid	=> v_bucket_sid
	);

	BEGIN
		csr.aggregate_ind_pkg.GetBucketData(
			in_aggregate_ind_group_id	=> v_agg_ind_group_id,
			in_start_dtm				=> TO_DATE('01-JAN-2000'),
			in_end_dtm					=> TO_DATE('01-JAN-2020'),
			out_cur						=> v_cur
		);
	EXCEPTION
		WHEN OTHERS THEN
			unit_test_pkg.TestFail('csr.test_aggregate_ind_pkg.GetBucketData should not have thrown!');
	END;
	
	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'DataFetchDoesntThrowWithNoInstance';
END;

PROCEDURE DataFetchThrowsWhenNoBucket
AS
	v_agg_ind_group_id		aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_cur					SYS_REFCURSOR;
	v_no_err				BOOLEAN := FALSE;
BEGIN
	unit_test_pkg.StartTest('csr.test_aggregate_ind_pkg.DataFetchThrowsWhenNoBucket');
	
	v_agg_ind_group_id := GetOrCreateAggIndGroup(
		in_name			=> 'DataFetchThrowsWhenNoBucket',
		in_fetch_sp		=> 'csr.test_aggregate_ind_pkg.GetBucketData'
	);

	BEGIN
		csr.aggregate_ind_pkg.GetBucketData(
			in_aggregate_ind_group_id	=> v_agg_ind_group_id,
			in_start_dtm				=> TO_DATE('01-JAN-2000'),
			in_end_dtm					=> TO_DATE('01-JAN-2020'),
			out_cur						=> v_cur
		);
		
		v_no_err := TRUE;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
		WHEN OTHERS THEN
			unit_test_pkg.AssertAreEqual(SQLCODE, -20001, 'Unexpected throw running csr.test_aggregate_ind_pkg.GetBucketData with no bucket set.');
	END;
	
	IF v_no_err THEN
		unit_test_pkg.TestFail('csr.test_aggregate_ind_pkg.GetBucketData should have thrown, because no bucket was set.');
	END IF;

	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'DataFetchThrowsWhenNoBucket';
END;


PROCEDURE AggIndGroupWithDataBucketTriggersBatchJob
AS
	v_bucket_sid			csr.data_bucket.data_bucket_sid%TYPE;
	v_agg_ind_group_id		csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_pre_max_batch_job		NUMBER;
	v_post_max_batch_job	NUMBER;
	v_start_dtm				csr.customer.calc_start_dtm%TYPE;
	v_end_dtm				csr.customer.calc_end_dtm%TYPE;
BEGIN
	unit_test_pkg.StartTest('csr.test_aggregate_ind_pkg.AggIndGroupWithDataBucketTriggersBatchJob');
	
	v_bucket_sid := GetOrCreateBucket(in_description => 'AggIndGroupWithDataBucketTriggersBatchJob');
	v_agg_ind_group_id := GetOrCreateAggIndGroup(
		in_name			=> 'AggIndGroupWithDataBucketTriggersBatchJob',
		in_fetch_sp		=> 'csr.test_aggregate_ind_pkg.GetData',
		in_bucket_sid	=> v_bucket_sid
	);
	
	SELECT MAX(batch_job_id)
	  INTO v_pre_max_batch_job
	  FROM csr.batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	-- A job is only created when one isn't already queued. So we need to
	-- make sure the queue is empty.
	DELETE FROM agg_ind_data_bucket_pending_job
	 WHERE data_bucket_sid = v_bucket_sid;
	
	csr.calc_pkg.AddJobsForAggregateIndGroup(
		in_aggregate_ind_group_id	=> v_agg_ind_group_id,
		in_start_dtm				=> v_start_dtm,
		in_end_dtm					=> v_end_dtm
	);
	
	SELECT MAX(batch_job_id)
	  INTO v_post_max_batch_job
	  FROM csr.batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	unit_test_pkg.AssertIsTrue(v_post_max_batch_job > v_pre_max_batch_job, 
		'A batch job should have been created, but was not.');

	DELETE FROM csr.batch_job_data_bucket_agg_ind
	 WHERE aggregate_ind_group_id = (
		SELECT aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name = 'AggIndGroupWithDataBucketTriggersBatchJob'
	);

	DELETE FROM agg_ind_data_bucket_pending_job
	 WHERE data_bucket_sid = v_bucket_sid;

	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'AggIndGroupWithDataBucketTriggersBatchJob';

END;

PROCEDURE AggIndGroupWithDataBucketTriggersCalcJob
AS
	v_agg_ind_group_id		csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_pre_max_batch_job		NUMBER;
	v_post_max_batch_job	NUMBER;
	v_calc_job_row_count	NUMBER;
	v_start_dtm				csr.customer.calc_start_dtm%TYPE;
	v_end_dtm				csr.customer.calc_end_dtm%TYPE;
BEGIN
	-- We can't specifically check for a calck job because the job itself gets created
	-- by an oracle schedule. So we have to check for the row in aggregate_ind_calc_job
	-- which is what the schedule uses to generate the calc job. Simple, eh? :/

	unit_test_pkg.StartTest('csr.test_aggregate_ind_pkg.AggIndGroupWithDataBucketTriggersCalcJob');
	
	v_agg_ind_group_id := GetOrCreateAggIndGroup(
		in_name			=> 'AggIndGroupWithDataBucketTriggersCalcJob',
		in_fetch_sp		=> 'csr.test_aggregate_ind_pkg.GetBucketData'
	);
	
	SELECT MAX(batch_job_id)
	  INTO v_pre_max_batch_job
	  FROM csr.batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	SELECT calc_start_dtm, calc_end_dtm
	  INTO v_start_dtm, v_end_dtm
	  FROM csr.customer
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	DELETE FROM aggregate_ind_calc_job
	 WHERE aggregate_ind_group_id = v_agg_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	csr.calc_pkg.AddJobsForAggregateIndGroup(
		in_aggregate_ind_group_id	=> v_agg_ind_group_id,
		in_start_dtm				=> v_start_dtm,
		in_end_dtm					=> v_end_dtm
	);
	
	SELECT MAX(batch_job_id)
	  INTO v_post_max_batch_job
	  FROM csr.batch_job
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	unit_test_pkg.AssertIsTrue(v_post_max_batch_job = v_pre_max_batch_job, 
		'A batch job should NOT have been created, but one was.');
	
	SELECT COUNT(*)
	  INTO v_calc_job_row_count
	  FROM aggregate_ind_calc_job
	 WHERE aggregate_ind_group_id = v_agg_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	unit_test_pkg.AssertIsTrue(v_calc_job_row_count > 0, 
		'Expected a row in aggregate_ind_calc_job but did not find one.');

	DELETE FROM csr.batch_job_data_bucket_agg_ind
	 WHERE aggregate_ind_group_id = (
		SELECT aggregate_ind_group_id
		  FROM aggregate_ind_group
		 WHERE name = 'AggIndGroupWithDataBucketTriggersCalcJob'
	);

	DELETE FROM aggregate_ind_calc_job
	 WHERE aggregate_ind_group_id = v_agg_ind_group_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'AggIndGroupWithDataBucketTriggersCalcJob';
END;

PROCEDURE SetGroupOnDuplicateDoesUpdate
AS
	v_agg_ind_group_id		csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_agg_ind_group_id2		csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_set_helper_proc		csr.aggregate_ind_group.helper_proc%TYPE;
BEGIN
	unit_test_pkg.StartTest('csr.test_aggregate_ind_pkg.SetGroupOnDuplicateDoesUpdate');

	-- Belt and braces
	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'DupeName';

	csr.aggregate_ind_pkg.CreateGroup(
		in_name						=> 'DupeName',
		in_label					=> 'DupeName',
		in_helper_proc				=> 'Initial.Fetch.Sp',
		in_helper_proc_args			=> 'vals',
		out_aggregate_ind_group_id	=> v_agg_ind_group_id
	);
	-- Shouldn't throw!
	v_agg_ind_group_id2 := csr.aggregate_ind_pkg.SetGroup(
		in_name						=> 'DupeName',
		in_helper_proc				=> 'Some.New.Sp'
	);
	
	unit_test_pkg.AssertAreEqual(v_agg_ind_group_id, v_agg_ind_group_id2, 
		'SetGroupOnDuplicateDoesUpdate - Expected same group id returned');
	
	SELECT helper_proc
	  INTO v_set_helper_proc
	  FROM aggregate_ind_group
	 WHERE aggregate_ind_group_id = v_agg_ind_group_id;
	
	unit_test_pkg.AssertAreEqual(v_set_helper_proc, 'Some.New.Sp', 
		'SetGroupOnDuplicateDoesUpdate - Helper proc was not updated as expected.');
END;

PROCEDURE TestRemoveAggIndGroup
AS
	v_agg_ind_group_id		csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
	v_existing_group_count	NUMBER;
	v_post_max_batch_job	NUMBER;
BEGIN

	-- Belt and braces
	DELETE FROM csr.aggregate_ind_group
	WHERE name = 'TEST_IND_GROUP';

	csr.aggregate_ind_pkg.CreateGroup(
		in_name						=> 'TEST_IND_GROUP',
		in_label					=> 'TEST_IND_GROUP',
		in_helper_proc				=> 'Initial.Fetch.Sp',
		in_helper_proc_args			=> 'vals',
		out_aggregate_ind_group_id	=> v_agg_ind_group_id
	);

	csr.aggregate_ind_pkg.RemoveAggIndGroup(
		in_aggregate_ind_group_id	=> v_agg_ind_group_id
	);

	SELECT COUNT(*) INTO v_existing_group_count
	FROM csr.aggregate_ind_group
	WHERE aggregate_ind_group_id = v_agg_ind_group_id;

	unit_test_pkg.AssertAreEqual(v_existing_group_count, 0, 
		'RemoveAggIndGroup - Group was not deleted as expected.');

END;

PROCEDURE SetUp
AS
BEGIN
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDown
AS
BEGIN
	-- No harm doing this again just in case.
	-- It's safest to log in once per test as well
	security.user_pkg.logonadmin(v_site_name);
	
	DELETE FROM csr.aggregate_ind_group
	 WHERE name = 'DupeName';
	
	-- Un-set the Built-in admin's user sid from the session,
	-- otherwise all permissions tests against any ACT will return true
	-- because of the internal workings of security pkgs
	security_pkg.SetContext('SID', NULL);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	dbms_output.put_line('SetUpFixture called with '||in_site_name);
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDownFixture
AS
BEGIN
	NULL;
END;

END;
/

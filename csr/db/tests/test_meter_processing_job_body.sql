CREATE OR REPLACE PACKAGE BODY csr.test_meter_processing_job_pkg AS

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

PROCEDURE ExpireJobsNoJobs AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsNoJobs';
	v_count			NUMBER;
	v_expired_count	NUMBER;
BEGIN
	Trace(v_test_name);

	-- expect to start with empty
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_count = 0, 'Expected 0 MPJ records'||' - '||v_count||' found.');
	csr.meter_processing_job_pkg.ExpireJobs;
END;

PROCEDURE ExpireJobsOneJobPending AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobPending';
	v_count			NUMBER;
	v_expired_count	NUMBER;
BEGIN
	Trace(v_test_name);

	-- test with one MPJ record
	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Pending',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	0
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_count = 1, 'Expected 1 MPJ records'||' - '||v_count||' found.');
	
	csr.meter_processing_job_pkg.ExpireJobs;
	
	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 0, 'Expected MPJ record to have count of 0 '||' - '||v_expired_count||' found.');

END;

PROCEDURE ExpireJobsOneJobUploading AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobUploading';
	v_count			NUMBER;
	v_expired_count	NUMBER;
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	0
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 0, 'Expected MPJ record to have count of 0 '||' - '||v_expired_count||' found.');

END;

PROCEDURE ExpireJobsOneJobUploadingExpired AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobUploadingExpired';
	v_count			NUMBER;
	v_expired_count	NUMBER;
	v_local_status	VARCHAR2(100);
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record to have count of 1 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;

	unit_test_pkg.AssertIsTrue(v_local_status = 'Pending', 'Expected pending MPJ record'||' - is '||v_local_status);

END;

PROCEDURE ExpireJobsOneJobDownloadingExpired AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobUploadingExpired';
	v_count			NUMBER;
	v_expired_count	NUMBER;
	v_local_status	VARCHAR2(100);
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Downloading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record to have count of 1 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;

	unit_test_pkg.AssertIsTrue(v_local_status = 'ResultsReady', 'Expected ResultsReady MPJ record'||' - is '||v_local_status);

END;

PROCEDURE ExpireJobsOneJobUpdatingExpired AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobUpdatingExpired';
	v_count			NUMBER;
	v_expired_count	NUMBER;
	v_local_status	VARCHAR2(100);
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Updating',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record to have count of 1 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;

	unit_test_pkg.AssertIsTrue(v_local_status = 'HaveFiles', 'Expected HaveFiles MPJ record'||' - is '||v_local_status);

END;

PROCEDURE ExpireJobsOneJobUploadingExpiredMultiple AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsOneJobUploadingExpiredMultiple';
	v_count			NUMBER;
	v_expired_count	NUMBER;
	v_local_status	VARCHAR2(100);
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record to have count of 1 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;

	unit_test_pkg.AssertIsTrue(v_local_status = 'Pending', 'Expected pending MPJ record'||' - is '||v_local_status);


	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job;
	unit_test_pkg.AssertIsTrue(v_expired_count = 2, 'Expected MPJ record to have count of 2 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;

	unit_test_pkg.AssertIsTrue(v_local_status = 'Pending', 'Expected pending MPJ record'||' - is '||v_local_status);


END;

PROCEDURE ExpireJobsMultipleJobsUploadingExpired AS
	v_test_name		VARCHAR2(100) := 'ExpireJobsMultipleJobsUploadingExpired';
	v_count			NUMBER;
	v_expired_count	NUMBER;
	v_local_status	VARCHAR2(100);
BEGIN
	Trace(v_test_name);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	2,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.SetJob(
		in_container_id			=>	1,
		in_job_id				=>	3,
		in_local_status			=>	'Uploading',
		in_meter_raw_data_id	=>	NULL,
		in_local_result_path	=>	NULL,
		in_remote_status		=>	NULL,
		in_upload_uri			=>	NULL,
		in_result_uri			=>	NULL,
		in_remote_result_path	=>	NULL,
		in_unhide				=>	1
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-60,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	2
	);

	csr.meter_processing_job_pkg.Int_SetHideTime(
		in_timeout				=>	-70,
		in_timeout_unit			=>	'SECOND',
		in_container_id			=>	1,
		in_job_id				=>	3
	);

	csr.meter_processing_job_pkg.ExpireJobs;

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record 2 to have expired count of 1 '||' - '||v_expired_count||' found.');

	SELECT expired_count
	  INTO v_expired_count
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 3;
	unit_test_pkg.AssertIsTrue(v_expired_count = 1, 'Expected MPJ record 3 to have expired count of 1 '||' - '||v_expired_count||' found.');

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 2;
	unit_test_pkg.AssertIsTrue(v_local_status = 'Pending', 'Expected pending MPJ record'||' - is '||v_local_status);

	SELECT local_status
	  INTO v_local_status
	  FROM csr.meter_processing_job
	 WHERE container_id = 1
	   AND job_id = 3;
	unit_test_pkg.AssertIsTrue(v_local_status = 'Pending', 'Expected pending MPJ record'||' - is '||v_local_status);
END;


--
PROCEDURE TearDown AS
BEGIN
	Trace('TearDown');
	DELETE FROM csr.meter_processing_job;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	DELETE FROM csr.meter_processing_job;
END;

END test_meter_processing_job_pkg;
/

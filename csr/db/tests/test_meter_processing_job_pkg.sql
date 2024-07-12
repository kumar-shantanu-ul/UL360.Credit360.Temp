CREATE OR REPLACE PACKAGE csr.test_meter_processing_job_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE SetUp;

-- Tests
PROCEDURE ExpireJobsNoJobs;
PROCEDURE ExpireJobsOneJobPending;
PROCEDURE ExpireJobsOneJobUploading;
PROCEDURE ExpireJobsOneJobUploadingExpired;
PROCEDURE ExpireJobsOneJobDownloadingExpired;
PROCEDURE ExpireJobsOneJobUpdatingExpired;
PROCEDURE ExpireJobsOneJobUploadingExpiredMultiple;
PROCEDURE ExpireJobsMultipleJobsUploadingExpired;


PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_meter_processing_job_pkg;
/

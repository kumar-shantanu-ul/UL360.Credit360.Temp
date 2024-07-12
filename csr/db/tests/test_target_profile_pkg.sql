CREATE OR REPLACE PACKAGE csr.test_target_profile_pkg AS

PROCEDURE SetUp;
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
PROCEDURE TestGetTargetProfiles;
PROCEDURE TestDeleteTargetProfile;
PROCEDURE TestEditTargetProfile;
PROCEDURE TestGetTargetProfileTypes;
PROCEDURE TearDown;

END test_target_profile_pkg;
/

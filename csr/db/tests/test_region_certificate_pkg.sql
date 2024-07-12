CREATE OR REPLACE PACKAGE csr.test_region_certificate_pkg AS

-- Start/end of tests
PROCEDURE SetUpFixture;
PROCEDURE TearDownFixture;

-- Start/end of each test
PROCEDURE SetUp;
PROCEDURE TearDown;

-- Tests
PROCEDURE TestGetCertificatesByTypeLookup;
PROCEDURE TestAddCertificateForRegion;

PROCEDURE TestGetCertificatesForRegionSid;
PROCEDURE TestGetDeletedCertificatesForRegionSid;

PROCEDURE TestUpdateCertificateForRegion;
PROCEDURE TestDeleteCertificateForRegion;

PROCEDURE TestGetEnergyRatingByTypeLookup;
PROCEDURE TestAddEnergyRatingForRegion;
PROCEDURE TestGetEnergyRatingForRegionSid;
PROCEDURE TestUpdateRegionEnergyRating;
PROCEDURE TestDeleteEnergyRatingForRegion;
PROCEDURE TestAddEnergyRatingForRegionSingleGresbRecord;

PROCEDURE TestGetCertificatesByRegion;
PROCEDURE TestGetDeletedCertificatesByRegion;

PROCEDURE TestGetCertificateLevels;
PROCEDURE TestUpsertCertificateForRegion;
PROCEDURE TestDeleteCertificatesForRegion;
PROCEDURE TestAdminCleanupDeletedCertificates;

PROCEDURE TestGetEnergyRatingsByRegion;
PROCEDURE TestUpsertEnergyRatingForRegion;
PROCEDURE TestDeleteEnergyRatingsForRegion;

END test_region_certificate_pkg;
/

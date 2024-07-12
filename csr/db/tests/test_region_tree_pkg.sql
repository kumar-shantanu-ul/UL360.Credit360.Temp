CREATE OR REPLACE PACKAGE csr.test_region_tree_pkg AS

PROCEDURE SetUpFixture;
PROCEDURE SetUp;

-- Tests for logging
PROCEDURE SyncSecondaryForTag;
PROCEDURE SyncSecondaryForTagGroup;
PROCEDURE SyncSecondaryActivePropOnly;
PROCEDURE SyncSecondaryForTagGroupList;
PROCEDURE SyncSecondaryPropByFunds;
PROCEDURE SyncPropTreeByMgtCompany;

-- Tests for syncing.
PROCEDURE SyncSecondaryForTag_One;
PROCEDURE SyncSecondaryForTagGroup_One;
PROCEDURE SyncScndryActivePropOnly_One;
PROCEDURE SyncScndryForTagGroupList_One;
PROCEDURE SyncSecondaryPropByFunds_One;
PROCEDURE SyncPropTreeByMgtCompany_One;

PROCEDURE SyncSecondaryForTag_WithRole;
PROCEDURE SyncSecondaryForTagGroup_WithRole;
PROCEDURE SyncScndryActivePropOnly_WithRole;
PROCEDURE SyncScndryForTagGroupList_WithRole;
PROCEDURE SyncSecondaryPropByFunds_WithRole;
PROCEDURE SyncPropTreeByMgtCompany_WithRole;

PROCEDURE TearDown;
PROCEDURE TearDownFixture;


END test_region_tree_pkg;
/

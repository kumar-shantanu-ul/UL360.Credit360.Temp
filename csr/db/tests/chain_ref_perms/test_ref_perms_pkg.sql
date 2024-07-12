CREATE OR REPLACE PACKAGE chain.test_ref_perms_pkg
IS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestCannotSetRefsWithNoPerms;
PROCEDURE TestCanSetRefsWithGroupPerms;
PROCEDURE TestCanSetRefsWithRolePerms;
PROCEDURE TestCannotSetRefsWithROPerms;
PROCEDURE TestRefPermsApplyByRef;
PROCEDURE TestCannotSetRefForBadCompType;
PROCEDURE TestChainAdminsGetBestPerms;

END;
/


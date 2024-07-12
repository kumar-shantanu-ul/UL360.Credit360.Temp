CREATE OR REPLACE PACKAGE chain.test_dedupe_purchaser_pkg AS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestNoMatchAutoCreate;

PROCEDURE TestOneMatchAutoMerge;

PROCEDURE TestNoMatchManualCreate;

PROCEDURE TestMatchManualMerge;

PROCEDURE TestNoMatchCreateCompFailRel;

PROCEDURE TestOneMatchMergeCompFailRel;

PROCEDURE TestLoopRelMerge;

PROCEDURE TestIndirectLoopRelMerge;

END;
/

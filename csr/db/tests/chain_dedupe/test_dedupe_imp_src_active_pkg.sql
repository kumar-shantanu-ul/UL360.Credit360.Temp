CREATE OR REPLACE PACKAGE chain.test_dedupe_imp_src_active_pkg
IS

TYPE T_NUMBERS                	IS TABLE OF NUMBER(10);
TYPE T_ARRAY					IS TABLE OF VARCHAR2(100);
TYPE T_DATE_ARRAY				IS TABLE OF DATE;

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestImpSrcActiveNoNoMatch;

PROCEDURE TestImpSrcActiveYesNoMatch;

PROCEDURE TestImpSrcActiveNoMatch;

PROCEDURE TestImpSrcActiveYesMatch;

PROCEDURE TestImpSrcNoNoMatchActDeactDtm;

PROCEDURE TestImpSrcYsNoMatchActDeactDtm;

PROCEDURE TestImpSrcNoMatchActDeactDtm;

PROCEDURE TestImpSrcYesMatchActDeactDtm;

END;
/

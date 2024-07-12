CREATE OR REPLACE PACKAGE chain.test_bus_rel_pkg
IS

PROCEDURE SetUpFixture(in_site_name VARCHAR2);

PROCEDURE SetSite(in_site_name VARCHAR2);

PROCEDURE SetUp;

PROCEDURE TearDown;

PROCEDURE TearDownFixture;

PROCEDURE TestCreateBusRel;

PROCEDURE TestDeleteBusRel;

PROCEDURE TestDelBusRelExpctAccessDnied1;

PROCEDURE TestDelBusRelExpctAccessDnied2;

PROCEDURE TestDelBusRelExpctAccessDnied3;

PROCEDURE TestDelBusRelExpctAccessDnied4;

PROCEDURE TestDelBusRelExpctAccessDnied5;

END;
/


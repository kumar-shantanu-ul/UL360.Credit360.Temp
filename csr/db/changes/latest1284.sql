-- Please update version.sql too -- this keeps clean builds in sync
define version=1284
@update_header

CREATE OR REPLACE PACKAGE ct.reports_pkg AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY ct.reports_pkg AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
/

GRANT EXECUTE ON ct.reports_pkg TO web_user;

@..\ct\reports_pkg
@..\ct\reports_body

@update_tail
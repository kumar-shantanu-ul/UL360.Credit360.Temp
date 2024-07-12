-- Please update version too -- this keeps clean builds in sync
define version=1735
@update_header

DROP PACKAGE CMS.BATCH_IMPORT

CREATE OR REPLACE PACKAGE CMS.BATCH_IMPORT_PKG
AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY CMS.BATCH_IMPORT_PKG
AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/

REM @..\..\..\aspen2\cms\db\batch_import_pkg
REM @..\..\..\aspen2\cms\db\batch_import_body

@update_tail
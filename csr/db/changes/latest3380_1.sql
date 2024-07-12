-- Please update version.sql too -- this keeps clean builds in sync
define version=3380
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_USER AS 
	OBJECT (
	CSR_USER_SID				NUMBER(10),
	EMAIL						VARCHAR2(256),
	FULL_NAME					VARCHAR2(256),
	USER_NAME					VARCHAR2(256),
	FRIENDLY_NAME				VARCHAR2(255),
	JOB_TITLE					VARCHAR2(100),
	ACTIVE						NUMBER(1),
	USER_REF					VARCHAR2(255),
	LINE_MANAGER_SID			NUMBER(10)
);
/


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE CSR.CORE_ACCESS_PKG
AS
PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY CSR.CORE_ACCESS_PKG
AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/

GRANT EXECUTE ON CSR.CORE_ACCESS_PKG TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@..\tag_pkg
@..\region_pkg
@..\csr_user_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\core_access_pkg

@..\tag_body
@..\region_body
@..\csr_user_body
@..\..\..\aspen2\cms\db\tab_body
@..\core_access_body

@update_tail

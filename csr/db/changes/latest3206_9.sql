-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CHAIN.T_PERMISSION_MATRIX_ROW AS
  OBJECT (
	CAPABILITY_ID 					NUMBER(10),
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10)
  );
/

CREATE OR REPLACE TYPE CHAIN.T_PERMISSION_MATRIX_TABLE AS
 TABLE OF T_PERMISSION_MATRIX_ROW;
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

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/type_capability_pkg
@../chain/type_capability_body

@update_tail

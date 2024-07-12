-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_USER_GROUP_ROW AS
	OBJECT (
		CSR_USER_SID		NUMBER(10),
		GROUP_SID			NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_USER_GROUP_TABLE AS
  TABLE OF CSR.T_USER_GROUP_ROW;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body
@../flow_body

@update_tail

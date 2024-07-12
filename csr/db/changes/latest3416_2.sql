-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.TT_AUDIT_CAP_DATA_ROW AS
	OBJECT ( 
		INTERNAL_AUDIT_SID		NUMBER(10), 
		INTERNAL_AUDIT_TYPE_ID	NUMBER(10),
		FLOW_CAPABILITY_ID		NUMBER(10),
		PERMISSION_SET			NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.TT_AUDIT_CAP_DATA_TABLE AS
	TABLE OF CSR.TT_AUDIT_CAP_DATA_ROW;
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
@../audit_body

@update_tail

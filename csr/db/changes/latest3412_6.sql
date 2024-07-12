-- Please update version.sql too -- this keeps clean builds in sync
define version=3412
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_FLOW_FILTER_DATA_ROW AS
	OBJECT (
		ID						NUMBER(10),
		IS_EDITABLE				NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_FILTER_DATA_TABLE AS
	TABLE OF CSR.T_FLOW_FILTER_DATA_ROW;
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
@../property_body

@update_tail

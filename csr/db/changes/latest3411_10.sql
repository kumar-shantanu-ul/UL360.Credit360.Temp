-- Please update version.sql too -- this keeps clean builds in sync
define version=3411
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CHAIN.T_FILTER_OBJECT_DATA_ROW AS
	 OBJECT (
		DATA_TYPE_ID					NUMBER(10),
		AGG_TYPE_ID						NUMBER(10),
		OBJECT_ID						NUMBER(10),
		VAL_NUMBER						NUMBER(24, 10),
		FILTER_VALUE_ID					NUMBER(10)
	 );
/

CREATE OR REPLACE TYPE CHAIN.T_FILTER_OBJECT_DATA_TABLE AS
	TABLE OF CHAIN.T_FILTER_OBJECT_DATA_ROW;
/

CREATE OR REPLACE TYPE CHAIN.T_GROUP_BY_PIVOT_ROW AS
	 OBJECT (
		OBJECT_ID NUMBER(10),
		FILTER_VALUE_ID1 NUMBER(10),
		FILTER_VALUE_ID2 NUMBER(10),
		FILTER_VALUE_ID3 NUMBER(10),
		FILTER_VALUE_ID4 NUMBER(10)
	 );
/

CREATE OR REPLACE TYPE CHAIN.T_GROUP_BY_PIVOT_TABLE AS
	TABLE OF CHAIN.T_GROUP_BY_PIVOT_ROW;
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
@../chain/filter_body

@update_tail

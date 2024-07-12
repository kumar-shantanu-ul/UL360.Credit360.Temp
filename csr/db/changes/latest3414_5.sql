-- Please update version.sql too -- this keeps clean builds in sync
define version=3414
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_ROW AS
	OBJECT (
		IND_SID				NUMBER(10),
		REGION_SID			NUMBER(10),
		PERIOD_START_DTM	DATE,
		PERIOD_END_DTM		DATE,
		VAL_NUMBER			NUMBER(24,10),
		SOURCE_TYPE_ID		NUMBER(10),
		SOURCE_ID			NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_TABLE AS
	TABLE OF CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_ROW;
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
@../like_for_like_pkg
@../like_for_like_body

@update_tail

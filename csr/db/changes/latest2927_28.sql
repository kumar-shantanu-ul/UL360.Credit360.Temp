-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=28
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_DATA_ID_REGION (
	METER_DATA_ID					NUMBER(10)		NOT NULL,
	REGION_SID						NUMBER(10)		NOT NULL
) ON COMMIT DELETE ROWS;

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
@../meter_report_body

@update_tail

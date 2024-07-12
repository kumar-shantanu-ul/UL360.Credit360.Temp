-- Please update version.sql too -- this keeps clean builds in sync
define version=3416
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE OR REPLACE TYPE CSR.T_GET_VALUE_RESULT_ROW AS
	OBJECT (
		period_start_dtm	DATE,
		period_end_dtm		DATE,
		source				NUMBER(10,0),
		source_id			NUMBER(20,0),
		source_type_id		NUMBER(10,0),
		ind_sid				NUMBER(10,0),
		region_sid			NUMBER(10,0),
		val_number			NUMBER(24,10),
		error_code			NUMBER(10,0),
		changed_dtm			DATE,
		note				CLOB,
		flags				NUMBER (10,0),
		is_leaf				NUMBER(1,0),
		is_merged			NUMBER(1,0),
		path				VARCHAR2(1024)
	);
/

CREATE OR REPLACE TYPE CSR.T_GET_VALUE_RESULT_TABLE AS
	TABLE OF CSR.T_GET_VALUE_RESULT_ROW;
/

DROP TABLE CSR.temp_sheets_ind_region_to_use;

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
@../val_datasource_pkg
@../val_datasource_body

@update_tail

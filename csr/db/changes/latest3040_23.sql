-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=23
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Query this - rest of grid extension stuff is in chain but it seems better to put this here as it 
-- could touch any other schema....
CREATE GLOBAL TEMPORARY TABLE CHAIN.TEMP_GRID_EXTENSION_MAP
(
	SOURCE_ID			NUMBER(10, 0)	NOT NULL,
	LINKED_TYPE			NUMBER(10,0)	NOT NULL,
	LINKED_ID			NUMBER(10, 0)	NOT NULL
)
ON COMMIT DELETE ROWS;

-- *** Grants ***
grant select, insert, update, delete on chain.temp_grid_extension_map to csr;
grant select on chain.grid_extension to csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_filter_pkg

@../chain/activity_report_body
@../chain/company_filter_body
@../audit_report_body
@../non_compliance_report_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2881
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.meter_insert_data ADD (
	source_row NUMBER(10) NULL,
	error_msg VARCHAR2(4000) NULL
);

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
@../meter_monitor_pkg
@../meter_monitor_body
@../meter_body

@update_tail

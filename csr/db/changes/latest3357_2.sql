-- Please update version.sql too -- this keeps clean builds in sync
define version=3357
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.temp_meter_consumption MODIFY (end_dtm NULL);

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
@../meter_body

@update_tail

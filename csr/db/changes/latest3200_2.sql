-- Please update version.sql too -- this keeps clean builds in sync
define version=3200
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSRIMP.METER_RAW_DATA_LOG MODIFY (USER_SID NULL);

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

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Packages ***
@..\chain\company_filter_pkg
@..\chain\company_filter_body

@update_tail

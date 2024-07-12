-- Please update version.sql too -- this keeps clean builds in sync
define version=3319
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
-- remove TRAVEL schema from sysdata as it'll have been removed by a zap site by this point
DELETE FROM CMS.SYS_SCHEMA
 WHERE oracle_schema = 'TRAVEL';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.all_property DROP CONSTRAINT FK_FUND_PROPERTY;

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

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3336
define minor_version=5
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
INSERT INTO CSR.EGRID (EGRID_REF, NAME) VALUES ('PRMS', 'Puerto Rico Miscellaneous');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

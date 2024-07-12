-- Please update version.sql too -- this keeps clean builds in sync
define version=3433
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
-- Force the script to remain present after "dev -rs"
SELECT 1 FROM DUAL;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

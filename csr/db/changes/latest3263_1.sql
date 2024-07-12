-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=1
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
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit cscript inds', 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can create cscript inds', 0);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../indicator_pkg
@../indicator_body
@../calc_pkg
@../calc_body

@update_tail

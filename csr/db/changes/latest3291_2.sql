-- Please update version.sql too -- this keeps clean builds in sync
define version=3291
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.gresb_submission_log 
RENAME COLUMN submission_data TO response_data;

ALTER TABLE csr.gresb_submission_log ADD request_data CLOB;

/* csrimp changes */
ALTER TABLE csrimp.gresb_submission_log 
RENAME COLUMN submission_data TO response_data;

ALTER TABLE csrimp.gresb_submission_log ADD request_data CLOB;

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
@../gresb_config_pkg
@../gresb_config_body
@../schema_body
@../csrimp/imp_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3392
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.quick_survey_type ADD enable_response_import NUMBER(10, 0) DEFAULT 1 NOT NULL;
ALTER TABLE csrimp.quick_survey_type ADD enable_response_import NUMBER(10, 0) DEFAULT 1 NOT NULL;

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
@../quick_survey_pkg
@../quick_survey_body
@../csrimp/imp_body
@update_tail

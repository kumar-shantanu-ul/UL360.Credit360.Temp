-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=4
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

INSERT INTO csr.module (module_id, module_name, enable_sp, description) VALUES (104, 'API Suggestions', 'EnableSuggestionsApi', 'Enables the Suggestions Api.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_pkg
@..\enable_body

@update_tail

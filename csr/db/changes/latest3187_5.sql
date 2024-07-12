-- Please update version.sql too -- this keeps clean builds in sync
define version=3187
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
UPDATE csr.module
   SET module_name = 'Suggestions',
	   enable_sp = 'EnableSuggestions',
	   description = 'Enables Suggestions.'
 WHERE enable_sp = 'EnableSuggestionsApi';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail

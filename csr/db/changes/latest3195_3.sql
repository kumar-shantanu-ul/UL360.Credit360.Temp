-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
define minor_version=3
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
	UPDATE CSR.OSHA_BASE_DATA 
	   SET definition_and_validations = 'The reason why an establishment''s injury and illness summary was changed, if applicable'
	 WHERE osha_base_data_id = 27;
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@update_tail

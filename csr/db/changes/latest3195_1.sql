-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
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
UPDATE csr.osha_base_data
SET definition_and_validations = 'The name of the establishment reporting data. The system matches the data in your file to existing establishments based on establishment name. <b>Each establishment MUST have a unique name.</b>'
WHERE osha_base_data_id = 1;

UPDATE csr.osha_base_data
SET definition_and_validations = 'The North American Industry Classification System (NAICS) code which classifies an establishment’s business. Use a 2012 code, found here: <a href="http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012">http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012</a><ul><li>Must be a number and be 6 digits in length</li></ul>'
WHERE osha_base_data_id = 7;
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***


@update_tail

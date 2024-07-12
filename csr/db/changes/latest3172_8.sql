-- Please update version.sql too -- this keeps clean builds in sync
define version=3172
define minor_version=8
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
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (81, 'Batch Company Geocode', 'chain-company-geocode', 1, 'support@credit360.com', 3, 120);

	INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) VALUES (52, 'Geotag companies', 'Geotag all companies that have some address data besides country and do not currently have a location specified. Note this will use part of our monthly mapquest transaction allowance (even in test environments).', 'GeotagCompanies', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\batch_job_pkg
@..\util_script_pkg
@..\chain\company_pkg

@..\util_script_body
@..\chain\company_body

@update_tail

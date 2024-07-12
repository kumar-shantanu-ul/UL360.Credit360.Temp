-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, one_at_a_time, notify_address, notify_after_attempts)
VALUES (21, 'Batch Property Geocode', 'batch-prop-geocode', 1, 'support@credit360.com', 3);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_pkg
@../property_body
@../batch_job_pkg

@update_tail

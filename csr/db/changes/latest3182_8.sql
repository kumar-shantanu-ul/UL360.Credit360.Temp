-- Please update version.sql too -- this keeps clean builds in sync
define version=3182
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer
	ADD site_type VARCHAR(10) DEFAULT 'Customer' NOT NULL
	CONSTRAINT ck_site_type CHECK (
		site_type IN ('Customer', 'Prospect', 'Sandbox', 'Staff', 'Retired'));

ALTER TABLE csrimp.customer ADD site_type VARCHAR(10) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.customer
	SET site_type = CASE
		WHEN host LIKE '%-dev.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-sandbox.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-test.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-training.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-demo.credit360.com' THEN 'Prospect'
		WHEN host LIKE '%-pilot.credit360.com' THEN 'Prospect'
		WHEN host LIKE '%-imp.credit360.com' THEN 'Staff'
		WHEN host LIKE '%-staff.credit360.com' THEN 'Staff'
		WHEN host LIKE '%-zap.credit360.com' THEN 'Retired'
		ELSE 'Customer'
	END;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_pkg
@../csr_data_pkg

@../csrimp/imp_body
@../csr_app_body
@../schema_body

@update_tail

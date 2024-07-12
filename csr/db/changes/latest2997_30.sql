-- Please update version.sql too -- this keeps clean builds in sync
define version=2997
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD (
	REST_API_GUEST_ACCESS						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CUST_REST_API_GUEST_ACCESS CHECK (REST_API_GUEST_ACCESS IN (0,1))
);
ALTER TABLE CSRIMP.CUSTOMER ADD (
	REST_API_GUEST_ACCESS						NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT CK_CUST_REST_API_GUEST_ACCESS CHECK (REST_API_GUEST_ACCESS IN (0,1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.module_param (
		module_id, param_name, param_hint, pos
	) VALUES (
		41, 'in_enable_guest_access', 'Guest access (y/n)', 0
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg

@../customer_body
@../enable_body
@../quick_survey_body
@../schema_body
@../csrimp/imp_body

@update_tail

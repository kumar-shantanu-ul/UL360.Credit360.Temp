-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_permit ADD (
	site_commissioning_required 	NUMBER(1) DEFAULT 0 NOT NULL,
	site_commissioning_dtm 			DATE NULL
);

ALTER TABLE csrimp.compliance_permit ADD (
	site_commissioning_required 	NUMBER(1) NOT NULL,
	site_commissioning_dtm 			DATE NULL
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\permit_pkg

@..\permit_body
@..\permit_report_body
@..\schema_body
@..\csrimp\imp_body

@update_tail

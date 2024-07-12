-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.product_supplier ADD (
	is_active					NUMBER(1) DEFAULT 0 NOT NULL
);

UPDATE chain.product_supplier SET is_active = 1;

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

@../chain/company_product_pkg
@../chain/product_supplier_report_pkg

@../chain/company_product_body
@../chain/product_supplier_report_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.product_supplier_tab
	ADD (
			purchaser_company_col_sid	NUMBER(10, 0),
			supplier_company_col_sid	NUMBER(10, 0),
			product_col_sid				NUMBER(10, 0),
			user_company_col_sid		NUMBER(10, 0)
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
@../chain/plugin_pkg
@../chain/company_product_pkg

@../chain/plugin_body
@../chain/company_product_body

@update_tail

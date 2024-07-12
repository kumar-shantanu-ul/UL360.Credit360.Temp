-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=5
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
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, 1 /*chain.product_supplier_report_pkg.AGG_TYPE_COUNT*/, 'Number of suppliers');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/product_report_pkg
@../chain/product_supplier_report_pkg

@../chain/product_report_body
@../chain/product_supplier_report_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=40
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

-- Products list filter alerts
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_ID', 'Product Id', 0, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_TYPE_ID', 'Product Type Id', 0, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_TYPE', 'Product Type', 1, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'COMPANY', 'Company', 1, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'IS_ACTIVE', 'Active', 0, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_NAME', 'Product Name', 1, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'COMPANY_SID', 'Company Sid', 0, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'SKU', 'SKU', 0, NULL);

	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'LOOKUP_KEY', 'Lookup Key', 0, NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/product_report_pkg

@../chain/product_report_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=11
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
	UPDATE csr.plugin
	   SET description = SUBSTR(description, 14)
	 WHERE plugin_type_id IN (18, 19, 20)
	   AND plugin_id != 92
	   AND SUBSTR(description, 1, 14) = 'Chain Product ';

	BEGIN
		insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
		values (98, 18, 'Certification Requirements Header', '/csr/site/chain/manageProduct/controls/CertificationRequirementsHeader.js', 'Chain.ManageProduct.CertificationRequirementsHeader', 'Credit360.Chain.Plugins.CertificationRequirementsDto', 'This header shows the certification requirements for a product.');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_product_pkg
@../chain/company_product_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=14
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
	   SET description = 'Supplier scores'
	 WHERE js_class = 'Chain.ManageCompany.ScoreHeader'
	   AND description = 'Score header for company management page'
	   AND cs_class = 'Credit360.Chain.Plugins.ScoreHeaderDto';
	   
END;
/

BEGIN
	INSERT INTO csr.plugin
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES
		(csr.plugin_id_seq.nextval, 11, 'Certifications', '/csr/site/chain/managecompany/controls/CertificationHeader.js',
			'Chain.ManageCompany.CertificationHeader', 'Credit360.Chain.Plugins.CertificationHeaderDto',
			'This header shows any certifications for a company.',
			'/csr/shared/plugins/screenshots/company_header_certifications.png');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/certification_pkg
@../chain/certification_body

@update_tail

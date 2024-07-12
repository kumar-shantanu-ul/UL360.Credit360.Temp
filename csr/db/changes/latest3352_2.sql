-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON cms.form_response_import_options TO csr;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.util_script(util_script_id, util_script_name, description, util_script_sp, wiki_article)
VALUES(66, 'Set CMS Forms Importer helper SP', 'Sets/updates the helper package that the CMS Forms Importer integration will call when importing responses from the Forms API.', 'SetCmsFormsImpSP', NULL);

INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Form ID', 'ID of the Form to set/update helper package', 0, NULL, 0);

INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Helper SP', 'SP called when importing responses', 1, NULL, 0);

INSERT INTO csr.util_script_param(util_script_id, param_name, param_hint, pos, param_value, param_hidden)
VALUES(66, 'Delete?', 'y/n to delete helper sp record for form', 2, 'n', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=0
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
UPDATE csr.std_factor SET note='The CO2 '|| chr(38) || ' CO2e values are in-correctly displayed in this factor. Either enter the values correctly using a bespoke factor or consider using a more recent factor set if available.'  WHERE std_factor_id=184369876;
UPDATE csr.std_factor SET note='The CO2 '|| chr(38) || ' CO2e values are in-correctly displayed in this factor. Either enter the values correctly using a bespoke factor or consider using a more recent factor set if available.'  WHERE std_factor_id=184369877;
UPDATE csr.std_factor SET note='The CO2 '|| chr(38) || ' CO2e values are in-correctly displayed in this factor. Either enter the values correctly using a bespoke factor or consider using a more recent factor set if available.'  WHERE std_factor_id=184369880;
UPDATE csr.std_factor SET note='The CO2 '|| chr(38) || ' CO2e values are in-correctly displayed in this factor. Either enter the values correctly using a bespoke factor or consider using a more recent factor set if available.'  WHERE std_factor_id=184369881;

BEGIN

	INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article)
	VALUES (14,'Add new branding', 'Add a newly created branding folder to the avaliable list, this will still need to be add to a demo site via the change branding page', 'AddNewBranding', null );

	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
	VALUES (14, 'Client Folder', 'The client folder that contains the css', 0);

	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
	VALUES (14, 'Brand Name', 'Name of the branding - this will appear in the dropdown', 1);

	INSERT INTO csr.util_script_param (util_script_id, param_name, param_hint, pos)
	VALUES (14, 'Author', 'Who created the branding', 2);
     
END;
/

INSERT INTO aspen2.lang (lang, description, lang_id) VALUES ('bs','Bosnian', 203);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../branding_pkg
@../branding_body
@../util_script_pkg
@../util_script_body

@update_tail

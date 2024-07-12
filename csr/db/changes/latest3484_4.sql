-- Please update version.sql too -- this keeps clean builds in sync
define version=3484
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(
		in_sid_id			=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
		in_act_timeout		=> NULL,
		in_app_sid			=> NULL,
		out_act_id			=> v_act
	);
	
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.security_pkg.SO_WEB_RESOURCE,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
END;
/

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (82, 'Create a Chain System Administrator Role', 'A system wide administrator with permissions outside of the supply chain module for administration of the module itself.', 'CreateChainSystemAdminRole','');

INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (82, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (83, 'Create a Chain Supplier Administrator Role', 'A supply chain administrator for top level company with access to managing all suppliers.', 'CreateSupplierAdminRole','');

INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (83, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../util_script_pkg
@../util_script_body
@../chain/setup_body

@update_tail

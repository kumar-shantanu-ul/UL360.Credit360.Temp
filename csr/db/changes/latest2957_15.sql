-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=15
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
CREATE OR REPLACE FUNCTION csr.Temp_SetCorePlugin(
	in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
	in_js_class						IN  csr.plugin.js_class%TYPE,
	in_description					IN  csr.plugin.description%TYPE,
	in_js_include					IN  csr.plugin.js_include%TYPE,
	in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
							details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
					 in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE plugin 
		   SET description = in_description,
			   js_include = in_js_include,
			   cs_class = in_cs_class,
			   details = in_details,
			   preview_image_path = in_preview_image_path,
			   form_path = in_form_path
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = in_js_class
		   AND app_sid IS NULL
		   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
			   RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;
/

DECLARE
	v_plugin_id NUMBER;
BEGIN
	v_plugin_id := csr.temp_SetCorePlugin(
		in_plugin_type_id		=> 10, /* csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB */
		in_description			=> 'Supplier followers',
		in_js_class				=> 'Chain.ManageCompany.SupplierFollowersTab',
		in_js_include			=> '/csr/site/chain/manageCompany/controls/SupplierFollowersTab.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.SupplierFollowersDto',
		in_details				=> 'This tab shows the followers of the selected company, and given the correct permissions, will allow adding/removing followers.'
	);
END;
/

DROP FUNCTION csr.Temp_SetCorePlugin;

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
	
END;
/
DECLARE 
	v_capability_id		NUMBER;
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  								/* CT_COMMON*/
		in_capability		=> 'Edit own follower status' 		/* chain.chain_pkg.EDIT_OWN_FOLLOWER_STATUS */, 
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier 		=> 1								/* chain_pkg.IS_SUPPLIER_CAPABILITY */
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;


CREATE OR REPLACE PROCEDURE chain.tmp_GrantCapability (
	in_capability_type		IN  NUMBER,
	in_capability			IN  VARCHAR2,
	in_group				IN  VARCHAR2,
	in_permission_set		IN  security.security_pkg.T_PERMISSION
)
AS
	v_capability_id			NUMBER;
	v_company_group_type_id	NUMBER;
BEGIN

	SELECT capability_id
	  INTO v_capability_id
	  FROM capability
	 WHERE capability_type_id = in_capability_type
	   AND capability_name = in_capability;
	
	SELECT company_group_type_id
	  INTO v_company_group_type_id
	  FROM company_group_type
	 WHERE name = in_group;
	
	INSERT INTO chain.group_capability(group_capability_id, company_group_type_id, capability_id, permission_set)
		VALUES(chain.group_capability_id_seq.NEXTVAL, v_company_group_type_id, v_capability_id, in_permission_set);
END;
/

BEGIN
	security.user_pkg.logonadmin;

	chain.tmp_GrantCapability(0 /* chain.chain_pkg.CT_COMMON */,   'Edit own follower status', 'Users', security.security_pkg.PERMISSION_WRITE);

END;
/

DROP PROCEDURE chain.tmp_GrantCapability;

-- update all clients
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.company_type_capability
	(app_sid, primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id, permission_set)
		SELECT ct.app_sid, ct.company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id, gc.permission_set
		  FROM chain.group_capability gc, chain.capability c, chain.company_type_relationship ctr, chain.company_type ct
		 WHERE ct.app_sid = ctr.app_sid
		   AND ct.company_type_id = ctr.primary_company_type_id
		   AND gc.capability_id = c.capability_id
		   AND c.capability_name = 'Edit own follower status'
		   AND (ctr.primary_company_type_id, ctr.secondary_company_type_id, gc.company_group_type_id, gc.capability_id) NOT IN (
				SELECT primary_company_type_id, secondary_company_type_id, primary_company_group_type_id, capability_id
				  FROM chain.company_type_capability
		   );
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_pkg
@../chain/company_user_pkg

@../supplier_body
@../chain/company_body
@../chain/company_user_body
@../chain/company_filter_body

@update_tail

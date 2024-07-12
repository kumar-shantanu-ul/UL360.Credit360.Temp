-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid, result_mode);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
@..\chain\create_views

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.plugin 
   SET js_class = 'Chain.ManageCompany.SupplierListTab',
       js_include = '/csr/site/chain/managecompany/controls/SupplierListTab.js'
 WHERE js_class = 'Chain.ManageCompany.SupplierList';

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/
-- New chain capabilities
BEGIN
	chain.temp_RegisterCapability(0 /*chain.chain_pkg.CT_COMMON*/, 'Create relationship with supplier' /*chain.chain_pkg.CREATE_RELATIONSHIP*/, 1 /*chain.chain_pkg.BOOLEAN_PERMISSION*/, 1 /*chain.chain_pkg.IS_SUPPLIER_CAPABILITY*/);
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;



-- ** New package grants **

-- *** Packages ***
@..\chain\chain_pkg
@..\chain\company_pkg
@..\chain\company_type_pkg
@..\chain\company_body
@..\chain\company_type_body
@..\chain\company_filter_body
@..\chain\supplier_audit_body
@..\chain\type_capability_body
@..\chain\plugin_body
@..\plugin_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=41
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
EXEC security.user_pkg.LogonAdmin;

DROP TYPE CHAIN.T_COMPANY_RELATIONSHIP_TABLE;

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_ROW AS
	OBJECT (
		COMPANY_SID					NUMBER(10),
		NAME						VARCHAR(1000),
		COUNTRY_NAME				VARCHAR(1000),
		ACTIVE_RELATIONSHIP			NUMBER(1),
		EDITABLE_RELATIONSHIP		NUMBER(1),--Based on capabilities
		COMPANY_TYPE_DESCRIPTION	VARCHAR(1000),
		RELATIONSHIP_ROLE			NUMBER(1), --1 SUPPLIER, 2 PURCHASER
		HAS_READ_PERMS_ON_COMPANY	NUMBER(1),
		IS_PRIMARY					NUMBER(1),
		CAN_BE_PRIMARY				NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CHAIN.T_COMPANY_RELATIONSHIP_TABLE AS 
	TABLE OF CHAIN.T_COMPANY_RELATIONSHIP_ROW;
/

ALTER TABLE chain.company_type_relationship ADD (
	can_be_primary			NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.supplier_relationship ADD (
	is_primary				NUMBER(1) DEFAULT 0 NOT NULL
);
ALTER TABLE chain.company_tab ADD (
	supplier_restriction	NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE chain.company_type_relationship ADD (
	CONSTRAINT chk_cmp_type_rel_cbp CHECK (can_be_primary IN (1, 0))
);
ALTER TABLE chain.supplier_relationship ADD (
	CONSTRAINT chk_supp_rel_primary CHECK (is_primary IN (1, 0))
);
ALTER TABLE chain.company_tab ADD (
	CONSTRAINT chk_comp_tab_supp_res CHECK (supplier_restriction IN (0, 1, 2))
);

ALTER TABLE csrimp.chain_compan_type_relati ADD (
	can_be_primary			NUMBER(1)
);
ALTER TABLE csrimp.chain_supplier_relationship ADD (
	is_primary			NUMBER(1)
);
ALTER TABLE csrimp.chain_company_tab ADD (
	supplier_restriction			NUMBER(1)
);

UPDATE csrimp.chain_compan_type_relati SET can_be_primary = 0;
UPDATE csrimp.chain_supplier_relationship SET is_primary = 0;
UPDATE csrimp.chain_company_tab SET supplier_restriction = 0;

ALTER TABLE csrimp.chain_compan_type_relati MODIFY can_be_primary NOT NULL;
ALTER TABLE csrimp.chain_supplier_relationship MODIFY is_primary NOT NULL;
ALTER TABLE csrimp.chain_company_tab MODIFY supplier_restriction NOT NULL;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

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
	IF in_capability_type = 10 /*chain_pkg.CT_COMPANIES*/ THEN
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

BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  															/* CT_ON_BEHALF_OF*/
		in_capability		=> 'Set primary purchaser in a relationship between A and B', 	/* SET_PRIMARY_PRCHSR */
		in_perm_type		=> 1, 															/* BOOLEAN_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

BEGIN
	INSERT INTO csr.plugin
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES
		(csr.plugin_id_seq.NEXTVAL, 11, 'Primary purchasers', '/csr/site/chain/managecompany/controls/PrimaryPurchasersHeader.js',
			'Chain.ManageCompany.PrimaryPurchasersHeader', 'Credit360.Chain.Plugins.PrimaryPurchasersHeaderDto',
			'This header shows any primary purchasers for a company.',
			'/csr/shared/plugins/screenshots/company_header_primary_purchasers.png');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/company_pkg
@../chain/company_type_pkg
@../chain/company_filter_pkg
@../chain/plugin_pkg

@../chain/company_body
@../chain/company_type_body
@../chain/company_filter_body
@../chain/plugin_body
@../schema_body 
@../csrimp/imp_body

@update_tail

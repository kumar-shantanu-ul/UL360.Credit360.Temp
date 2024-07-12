-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=37
@update_header

-- *** DDL ***
-- Create tables


-- Alter tables
ALTER TABLE chain.product_metric_val ADD note VARCHAR2(4000);
ALTER TABLE chain.product_supplier_metric_val ADD note VARCHAR2(4000);
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
		in_capability_type	=> 1,  												/* CT_COMPANY */
		in_capability		=> 'Product metric values as supplier',				/* PRODUCT_METRIC_VAL_AS_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 0
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  												/* CT_SUPPLIERS */
		in_capability		=> 'Product supplier metric values',				/* PRD_SUPP_METRIC_VAL */
		in_perm_type		=> 0,												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  												/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product supplier metric values of suppliers',	/* PRD_SUPP_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  												/* CT_COMPANY */
		in_capability		=> 'Product supplier metric values as supplier',	/* PRD_SUPP_METRIC_VAL_AS_SUPP */
		in_perm_type		=> 0, 												/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 0
	);
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

DELETE FROM chain.company_type_capability WHERE capability_id IN (
	SELECT capability_id
	  FROM chain.capability
	 WHERE capability_name IN ('Supplier product metric values', 'Supplier product metric values of suppliers', 'Product metric values of suppliers')
);
DELETE FROM chain.capability WHERE capability_name = 'Supplier product metric values';
DELETE FROM chain.capability WHERE capability_name = 'Supplier product metric values of suppliers';
DELETE FROM chain.capability WHERE capability_name = 'Product metric values of suppliers';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/chain_pkg
@../chain/product_metric_pkg
@../chain/company_product_pkg

@../chain/product_metric_body
@../chain/company_product_body


@update_tail

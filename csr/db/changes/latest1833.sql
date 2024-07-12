-- Please update version.sql too -- this keeps clean builds in sync
define version=1833
@update_header

BEGIN

	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.SUPPLIER_NO_RELATIONSHIP, chain.chain_pkg.SPECIFIC_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY); */
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'Supplier with no established relationship', 0, 0, 1);
	
END;
/

@../supplier_pkg
@../chain/chain_pkg
@../chain/type_capability_pkg
@../chain/company_type_pkg
@../chain/company_pkg
@../chain/company_user_pkg

@../supplier_body
@../chain/type_capability_body
@../chain/company_type_body
@../chain/company_body
@../chain/company_user_body

@update_tail
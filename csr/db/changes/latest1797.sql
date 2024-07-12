-- Please update version.sql too -- this keeps clean builds in sync
define version=1797
@update_header

/* View supplier company references capability for CT_COMPANY */
BEGIN

	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.VIEW_REFERENCE_LABEL_FIELDS, chain.chain_pkg.BOOLEAN_PERMISSION); */
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'View supplier company reference fields', 1, 1, 0);
	
END;
/

@../chain/invitation_body
 
@update_tail
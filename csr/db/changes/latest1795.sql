-- Please update version.sql too -- this keeps clean builds in sync
define version=1795
@update_header

DECLARE v_view_relatonships_cap_id NUMBER; /* 'View relationships between A and B' capability id */
		v_card_group_id 		   NUMBER := 5; /* 'Supplier Details' */
		v_card_id	   			   NUMBER;
BEGIN
	--logon as builtin admin, no app
	security.user_pkg.logonadmin;

	--Get View relationships capability id
	SELECT capability_id
	  INTO v_view_relatonships_cap_id
	  FROM chain.capability
	 WHERE capability_name =  'View relationships between A and B'; /*  chain.chain_pkg.VIEW_RELATIONSHIPS; */

	--Get supplier relationship capability id
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.SupplierRelationship';
	
	FOR r IN (	
		SELECT DISTINCT h.host
		  FROM chain.v$chain_host h
	) 
	LOOP 
		security.user_pkg.LogonAdmin(r.host);
	
		/* update conditional required capability for card manager 'Supplier Details' and card 'SupplierRelationship' 
			to view_relatonships required capability */
		UPDATE chain.card_group_card
		   SET required_capability_id = v_view_relatonships_cap_id
		 WHERE app_sid = security.security_pkg.getApp
		   AND card_group_id = v_card_group_id
		   AND card_id = v_card_id;
	
	END LOOP;
		 
END;
/

/* View supplier company references capability */
BEGIN

	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_SUPPLIERS, chain.chain_pkg.VIEW_REFERENCE_LABEL_FIELDS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY); */
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, 'View supplier company reference fields', 2, 1, 1);
	
END;
/

@../chain/chain_pkg
@../chain/type_capability_pkg
@../chain/card_pkg

@../chain/type_capability_body
@../chain/card_body

@update_tail
PROMPT >> Creating component types
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.acceptance_status (acceptance_status_id, description) VALUES (chain.chain_pkg.ACCEPT_PENDING, 'Pending');
	INSERT INTO chain.acceptance_status (acceptance_status_id, description) VALUES (chain.chain_pkg.ACCEPT_ACCEPTED, 'Accepted');
	INSERT INTO chain.acceptance_status (acceptance_status_id, description) VALUES (chain.chain_pkg.ACCEPT_REJECTED, 'Rejected');

	INSERT INTO chain.component_supplier_type (component_supplier_type_id, description) VALUES (chain.chain_pkg.SUPPLIER_NOT_SET, 'Supplier not set');
	INSERT INTO chain.component_supplier_type (component_supplier_type_id, description) VALUES (chain.chain_pkg.EXISTING_SUPPLIER, 'Existing supplier');
	INSERT INTO chain.component_supplier_type (component_supplier_type_id, description) VALUES (chain.chain_pkg.EXISTING_PURCHASER, 'Existing purchaser');
	INSERT INTO chain.component_supplier_type (component_supplier_type_id, description) VALUES (chain.chain_pkg.UNINVITED_SUPPLIER, 'Uninvited supplier');
	
	/******************************************************************************
		CHAIN CORE COMPONENTS
	******************************************************************************/
	chain.component_pkg.CreateType(
		chain.chain_pkg.PRODUCT_COMPONENT, 
		'Credit360.Chain.Products.Product',
		'chain.product_pkg', 
		'/csr/site/chain/components/products/ProductNode.js', 
		'Product'
	);

	chain.component_pkg.CreateType(	
		chain.chain_pkg.LOGICAL_COMPONENT, 
		'Credit360.Chain.Products.LogicalComponent',
		'chain.component_pkg', 
		'/csr/site/chain/components/products/LogicalNode.js', 
		'Logical',
		chain.card_pkg.GetCardGroupId('Logical Component Wizard')
	);

	chain.component_pkg.CreateType(
		chain.chain_pkg.PURCHASED_COMPONENT, 
		'Credit360.Chain.Products.PurchasedComponent',
		'chain.purchased_component_pkg', 
		'/csr/site/chain/components/products/PurchasedNode.js', 
		'Purchased',
		chain.card_pkg.GetCardGroupId('Purchased Component Wizard')
	);
	
	chain.component_pkg.CreateType(
		chain.chain_pkg.VALIDATED_PURCHASED_COMPONENT, 
		'Credit360.Chain.Products.ValidatedPurchasedComponent',
		'chain.validated_purch_component_pkg', 
		'/csr/site/chain/components/products/PurchasedNode.js', 
		'ValidatedPurchased',
		chain.card_pkg.GetCardGroupId('Purchased Component Wizard')
	);
	
	chain.component_pkg.CreateType(
		chain.chain_pkg.NOTSURE_COMPONENT, 
		'Credit360.Chain.Products.NotSureComponent',
		'chain.component_pkg', 
		'/csr/site/chain/components/products/NotSureNode.js', 
		'Not Sure',
		chain.card_pkg.GetCardGroupId('Not Sure Component Wizard')
	);

	/******************************************************************************
		RAINFOREST ALLIANCE COMPONENTS
	******************************************************************************/
	-- TO DO - move these
	
	chain.component_pkg.CreateType (
		chain.chain_pkg.RA_WOOD_COMPONENT, 
		'Clients.RainforestAlliance.WoodComponent', 
		'rfa.wood_component_pkg', 
		'/rainforestalliance/components/products/ClientComponentNode.js',
		'Rainforest Alliance Wood',
		chain.card_pkg.GetCardGroupId('Wood Source Wizard')
	);
	
	chain.component_pkg.CreateType (
		chain.chain_pkg.RA_NOT_WOOD_COMPONENT, 
		'Clients.RainforestAlliance.NotWoodComponent', 
		'rfa.not_wood_component_pkg', 
		'/rainforestalliance/components/products/NotWoodComponentNode.js',
		'Non Wood or Paper Input',
		chain.card_pkg.GetCardGroupId('Not Wood Wizard')
	);
	
	--PRODUCT VALIDATION STATUSES
	INSERT INTO chain.validation_status (validation_status_id, description) VALUES (1, 'Initial');
	INSERT INTO chain.validation_status (validation_status_id, description) VALUES (2, 'Not yet validated');
	INSERT INTO chain.validation_status (validation_status_id, description) VALUES (3, 'Validation needs review');
	INSERT INTO chain.validation_status (validation_status_id, description) VALUES (4, 'Validation in progress');
	INSERT INTO chain.validation_status (validation_status_id, description) VALUES (5, 'Validated');
END;
/

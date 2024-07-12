define version=111
@update_header

-- here if needed but feels risky to run on live where its not needed
@latest111_packages

BEGIN
	user_pkg.logonadmin;
	
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE,
		in_message_template 		=> 'One or more components that you buy {uninvitedSupplier:OPEN}need their supplier to be invited{uninvitedSupplier:CLOSE}.',
		in_repeat_type 				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'All suppliers that have components associated with them have been invited {relCompletedDtm}', -- shouldn't need a completion message as we should have an invitation message or it becomes irrelevant (i.e. products deleted)
		in_css_class 				=> 'background-icon company-icon',
		in_addressing_type			=> chain.chain_pkg.COMPANY_ADDRESS
	);
	
	chain.message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.chain_pkg.UNINVITED_SUPPLIERS_TO_INVITE, 
		in_param_name 				=> 'uninvitedSupplier', 
		in_href 					=> '/csr/site/chain/uninvitedSuppliers.acds'
	);
	
	chain.card_pkg.RegisterCard(
		'Purchased Component summary page', 
		'Credit360.Chain.Cards.Empty',
		'/csr/site/chain/cards/componentBuilder/purchasedComponentSummary.js', 
		'Chain.Cards.PurchasedComponentSummary'
	);
	
END;
/

connect csr/csr@&_CONNECT_IDENTIFIER

	grant execute on csr.stragg to chain;
	grant execute on csr.stragg2 to chain;

connect chain/chain@&_CONNECT_IDENTIFIER

@..\chain_pkg
@..\uninvited_pkg
@..\purchased_component_body
@..\message_body
@..\uninvited_body

@update_tail
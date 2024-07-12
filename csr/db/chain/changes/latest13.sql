define version=13
@update_header

@..\card_pkg
@..\company_pkg
@..\invitation_pkg

@..\card_body
@..\company_body
@..\invitation_body


INSERT INTO card_group
(card_group_id, name, description, require_all_cards)
VALUES
(11, 'Pending Supplier Details', 'Allows company users to view or details of suppliers that they have invited to the system.', 0);

begin
	card_pkg.RegisterCard(
		'A card that shows a summary of invitations sent to a supplier', 
		'Credit360.Chain.Cards.SupplierInvitationSummary',
		'/csr/site/chain/cards/supplierInvitationSummary.js', 
		'Chain.Cards.SupplierInvitationSummary',
		null
	);	

	card_pkg.RegisterCard(
		'Forces a readOnly config flag on edit company.', 
		'Credit360.Chain.Cards.EditCompany',
		'/csr/site/chain/cards/viewCompany.js', 
		'Chain.Cards.ViewCompany',
		null
	);
end;
/


@update_tail

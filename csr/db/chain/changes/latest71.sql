define version=71
@update_header

@latest71_packages

ALTER TABLE chain.SUPPLIER_RELATIONSHIP ADD VIRTUALLY_ACTIVE_KEY NUMBER(10);

CREATE INDEX chain.SUP_REL_VIR_ACTIVE_KEY_IDX ON chain.SUPPLIER_RELATIONSHIP(VIRTUALLY_ACTIVE_KEY);

CREATE SEQUENCE chain.VIRTUALLY_ACTIVE_KEY_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

-- reregister Create Supplier in Uber Wizard to get countries list
begin
	user_pkg.logonadmin;

	chain.card_pkg.RegisterCard(
		'Chain.Cards.CreateCompany extension with logic for component builder progression and searching', 
		'Credit360.Chain.Cards.AddCompany',
		'/csr/site/chain/cards/componentBuilder/createSupplier.js', 
		'Chain.Cards.ComponentBuilder.CreateSupplier'
	);


end;
/

@update_tail
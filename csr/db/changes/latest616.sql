-- Please update version.sql too -- this keeps clean builds in sync
define version=616
@update_header

connect chain/chain@&_CONNECT_IDENTIFIER

DECLARE
	v_count			NUMBER(10);
	v_js_class		chain.card.js_class_type%TYPE;
BEGIN
	
	FOR r IN (
		SELECT * FROM chain.v$chain_host WHERE chain.chain_implementation LIKE 'CSR.%'
	) LOOP
	
		user_pkg.logonadmin(r.host);
	
		chain.card_pkg.SetGroupCards('My Company', T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser', 'Chain.Cards.StubSetup'));
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.ViewCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, TRUE);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.EditCompany', chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE, FALSE);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain_pkg.CT_COMPANY, chain_pkg.CREATE_USER);
		chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.StubSetup', chain_pkg.CT_COMPANY, chain_pkg.SETUP_STUB_REGISTRATION);
		
	END LOOP;
END;
/

connect csr/csr@&_CONNECT_IDENTIFIER

@update_tail

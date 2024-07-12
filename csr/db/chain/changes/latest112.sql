define version=112
@update_header

-- Can use latest111_packages if this script fails to run as schema hasn't changed since
@latest111_packages
-- chain_pkg.COMPANY_DELETED won't be defined in latest111_packages
@latest112_chain_pkg

BEGIN
	user_pkg.logonadmin;
	
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMPANY_DELETED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The supplier {reCompany} has been deleted.',
		in_css_class 				=> 'background-icon delete-icon'
	);
	
	chain.message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.chain_pkg.COMPANY_DELETED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'reCompany', 
		in_css_class 				=> 'background-icon faded-supplier-icon', 
		in_value 					=> '{reCompanyName}'
	);
	
END;
/


@..\chain_pkg
@..\company_body
@..\invitation_body

@update_tail
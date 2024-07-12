-- Please update version.sql too -- this keeps clean builds in sync
define version=2471
@update_header

@latest2471_packages

BEGIN
	security.user_pkg.LogonAdmin;
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RETURNED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{reCompanySid}'
	);
	
	chain.temp_message_pkg.DefineMessageParam(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RETURNED, 
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_param_name 				=> 'fromCompanySid', 
		in_value 					=> '{reCompanySid}'
	);
END;
/

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_chain_pkg;

@update_tail
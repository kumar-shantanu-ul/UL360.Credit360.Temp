-- Please update version.sql too -- this keeps clean builds in sync
define version=2298
@update_header

-- rename this with version
@latest2298_packages

BEGIN
	security.user_pkg.LogonAdmin;
	
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.AUDIT_REQUEST_REQUIRED,
		in_secondary_lookup         => chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Audit required, please {reAuditRequestLink}.',
		in_completed_template 		=> 'Audit request submitted to {reAuditCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon audit-request-icon',
		in_repeat_type 				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_addressing_type			=> chain.temp_chain_pkg.COMPANY_ADDRESS
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.AUDIT_REQUEST_REQUIRED,
				in_secondary_lookup         => chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reAuditRequestLink', 
				in_value 					=> 'click here to submit an audit request',
				in_href						=> '/csr/site/chain/createAuditRequest.acds'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.AUDIT_REQUEST_REQUIRED, 
				in_secondary_lookup         => chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reAuditCompanyName', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reAuditCompanyName}'
			);
END;
/

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_chain_pkg;

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2366
@update_header

@latest2366_packages

BEGIN
	security.user_pkg.logonadmin();
	
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.AUDIT_REQUEST_REQUIRED,
		in_secondary_lookup         => chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Audit required for {reCompanyName}, please {reAuditRequestLink}.',
		in_completed_template 		=> 'Audit request submitted to {reSecondaryCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon audit-request-icon',
		in_repeat_type 				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.AUDIT_REQUEST_REQUIRED,
				in_secondary_lookup         => chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reAuditRequestLink', 
				in_value 					=> 'submit an audit request',
				in_href						=> '/csr/site/chain/createAuditRequest.acds?auditeeSid={reCompanySid}'
			);
END;
/

@update_tail

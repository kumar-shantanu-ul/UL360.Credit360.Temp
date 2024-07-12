define version=127
@update_header

--@..\chain_pkg
@latest127_packages

BEGIN
	user_pkg.logonadmin;
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} for {reCompany} was rejected by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain_pkg.ACKNOWLEDGE,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} was rejected by {reCompany}.',
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RETURNED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} was returned to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RETURNED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain_pkg.CODE_ACTION,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} was returned from {reCompany}. Please correct an re-submit.',
		in_completed_template 		=> 'Submitted by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	
	
END;
/

@..\chain_pkg
@..\questionnaire_pkg
@..\questionnaire_body
@..\message_body
@..\task_body


@update_tail

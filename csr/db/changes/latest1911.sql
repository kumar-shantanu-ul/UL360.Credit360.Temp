-- Please update version.sql too -- this keeps clean builds in sync
define version=1911
@update_header

@latest1911_packages

/************** CHAIN PRODUCT/COMPONENT QUESTIONNAIRE SETUP ******************/

BEGIN

security.user_pkg.logonadmin;
	----------------------------------------------------------------------------
	--		COMPLETE_COMP_QUESTIONNAIRE
	----------------------------------------------------------------------------
chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please enter {reQuestionnaire} ({reComponentDescription}) data for {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} ({reComponentDescription}) data submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({reComponentDescription}) submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({reComponentDescription}) submitted by {triggerUser} to {reCompany}.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({reComponentDescription}) for {reCompany} was rejected by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({reComponentDescription}) was rejected by {reCompany}.',
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({reComponentDescription}) was returned to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({reComponentDescription}) was returned from {reCompany}. Please correct and re-submit.',
		in_completed_template 		=> 'Submitted by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_APPROVED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Your {reQuestionnaire} ({reComponentDescription}) has been received and accepted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({reComponentDescription}) has been approved.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({reComponentDescription}) is overdue.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({reComponentDescription}) is overdue.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
END;
/

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_chain_pkg;

@update_tail
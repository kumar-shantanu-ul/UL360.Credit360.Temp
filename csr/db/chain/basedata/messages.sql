BEGIN
	-- setup message repeat types
	BEGIN
		INSERT INTO chain.repeat_type (repeat_type_id, description)
		VALUES (chain.chain_pkg.NEVER_REPEAT, 'Never repeat');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.repeat_type (repeat_type_id, description)
		VALUES (chain.chain_pkg.REPEAT_IF_CLOSED, 'Repeat it if closed');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO chain.repeat_type (repeat_type_id, description)
		VALUES (chain.chain_pkg.REFRESH_OR_REPEAT, 'Refreshes the timestamp on an existing open message, or creates a new one');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.repeat_type (repeat_type_id, description)
		VALUES (chain.chain_pkg.ALWAYS_REPEAT, 'Always repeat');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- setup addressing types
	BEGIN
		INSERT INTO chain.addressing_type (addressing_type_id, description)
		VALUES (chain.chain_pkg.USER_ADDRESS, 'Private address - send it to this user regardless of company');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.addressing_type (addressing_type_id, description)
		VALUES (chain.chain_pkg.COMPANY_USER_ADDRESS, 'User address - send it to this user at the specified company');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.addressing_type (addressing_type_id, description)
		VALUES (chain.chain_pkg.COMPANY_ADDRESS, 'Company address - send it to all users of this company');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- setup message priority
	BEGIN
		INSERT INTO chain.message_priority (message_priority_id, description)
		VALUES (chain.chain_pkg.HIDDEN, 'Never show the message');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.message_priority (message_priority_id, description)
		VALUES (chain.chain_pkg.NEUTRAL, 'The message is neutral (informational)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.message_priority (message_priority_id, description)
		VALUES (chain.chain_pkg.SHOW_STOPPER, 'This must be attended to before other show stopper or highlighted messages are shown');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.message_priority (message_priority_id, description)
		VALUES (chain.chain_pkg.TO_DO_LIST, 'This message is a To Do to allowed it to be displayed differently');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- setup completion types
	BEGIN
		INSERT INTO chain.completion_type (completion_type_id, description)
		VALUES (chain.chain_pkg.NO_COMPLETION, 'No completion is required - this is a pure message');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.completion_type (completion_type_id, description)
		VALUES (chain.chain_pkg.ACKNOWLEDGE, 'The user must only acknowledge that this message has been read');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO chain.completion_type (completion_type_id, description)
		VALUES (chain.chain_pkg.CODE_ACTION, 'The user must follow a course of action, and this will be completed through code');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/


BEGIN

	security.user_pkg.LogonAdmin;
	
	/****************************************************************************
			ADMINISTRATIVE MESSAGING
	*****************************************************************************/
	
	----------------------------------------------------------------------------
	--	CONFIRM_COMPANY_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_message_template 		=> 'An admin must check your registered company details for {toCompany}.',
		in_repeat_type 				=> chain.chain_pkg.NEVER_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Confirmed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon info-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.CONFIRM_COMPANY_DETAILS, 
				in_param_name 				=> 'toCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_href 					=> '/csr/site/chain/myCompany.acds?confirm=true', 
				in_value 					=> '{toCompanyName}'
			);
			
	----------------------------------------------------------------------------
	--		CONFIRM_YOUR_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.CONFIRM_YOUR_DETAILS,
		in_message_template 		=> 'You must check your {toUser:OPEN}personal details{toUser:CLOSE}.',
		in_repeat_type 				=> chain.chain_pkg.NEVER_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.USER_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Confirmed {relCompletedDtm}',
		in_css_class 				=> 'background-icon info-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.CONFIRM_YOUR_DETAILS, 
				in_param_name 				=> 'toUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_href 					=> '/csr/site/chain/myDetails.acds?confirm=true'
			);
	
	----------------------------------------------------------------------------
	--		COMPANY_DELETED
	----------------------------------------------------------------------------
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

	----------------------------------------------------------------------------
	--		SUPPLIER_DETAILS_REQUIRED
	----------------------------------------------------------------------------
  chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.SUPPLIER_DETAILS_REQUIRED,
		in_message_template 		=> 'One or more of your {reSuppliers} need updating.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_css_class 				=> 'background-icon info-icon',
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.SUPPLIER_DETAILS_REQUIRED, 
				in_param_name 				=> 'reSuppliers', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/managecompany.acds', 
				in_value 					=> 'suppliers'
			);			
	
	/****************************************************************************
			INVITATION MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		INVITATION_SENT
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation sent to {reUser} of {reCompany} by {triggerUser}.',
		in_css_class 				=> 'background-icon invitation-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);
	
	----------------------------------------------------------------------------
	--		INVITATION_ACCEPTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation accepted by {reUser} from {reCompany}.',
		in_css_class 				=> 'background-icon invitation-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
	
	
	----------------------------------------------------------------------------
	--		INVITATION_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation rejected by {reUser} from {reCompany}. {inviteDetails:OPEN}Click here to view invitation details{inviteDetails:CLOSE}',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon invitation-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_value 					=> '{reCompanyName}'
			);

	----------------------------------------------------------------------------
	--		INVITATION_EXPIRED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation to {reUser} of {reCompany} has expired.',
		in_css_class 				=> 'background-icon invitation-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
		
	
	/****************************************************************************
			QUESTIONNAIRE MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		COMPLETE_QUESTIONNAIRE
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please enter {reQuestionnaire} data for {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} data submitted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} submitted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_repeat_type				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_SUBMITTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} submitted by {triggerUser} to {reCompany}.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} for {reCompany} was rejected by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} was rejected by {reCompany}.',
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RETURNED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} was returned to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RETURNED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} was returned from {reCompany}. Please correct and re-submit.',
		in_completed_template 		=> 'Submitted by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RESENT -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please review and re-submit {reQuestionnaire} data for {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RESENT -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} was re-sent to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{companySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Your {reQuestionnaire} has been received and accepted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'resultsUrl'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} has been approved.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromcompanySid', 
				in_value 					=> '{toCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_OVERDUE -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_OVERDUE -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromcompanySid', 
				in_value 					=> '{reCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_EXPIRED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_EXPIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} has expired.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	/****************************************************************************
			COMPONENT QUESTIONNAIRE MESSAGING
	*****************************************************************************/
	
	----------------------------------------------------------------------------
	--		COMPLETE_COMP_QUESTIONNAIRE
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please enter {reQuestionnaire} ({componentDescription}) data for {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} ({componentDescription}) data submitted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) submitted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);						

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) submitted by {triggerUser} to {reCompany}.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);									
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) for {reCompany} was rejected by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);	

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);						

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) was rejected by {reCompany}.',
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);	

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) was returned to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);		
				
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) was returned from {reCompany}. Please correct and re-submit.',
		in_completed_template 		=> 'Submitted by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RESENT -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please review and re-submit {reQuestionnaire} ({componentDescription}) data for {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RESENT -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) was re-sent to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_APPROVED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Your {reQuestionnaire} ({componentDescription}) has been received and accepted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);			
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) has been approved.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_EXPIRED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_EXPIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) has expired.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
	
	/****************************************************************************
			COMPONENT MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		PRODUCT_MAPPING_REQUIRED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'One or more products that {reCompany} buys from you {productMapping:OPEN}needs to be mapped{productMapping:CLOSE} to the actual products you sell.',
		in_repeat_type 				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Last mapping completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon product-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'productMapping', 
				in_href 					=> '/csr/site/chain/products/mapmyproductstopurchasers.acds?companySid={reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		UNINVITED_SUPPLIERS_TO_INVITE
	----------------------------------------------------------------------------
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
	
	
	----------------------------------------------------------------------------
	--		MAPPED_PRODUCTS_TO_PUBLISH
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
		in_message_template 		=> 'One or more products you sell {productsYouSell:OPEN}need finishing{productsYouSell:CLOSE}.',
		in_repeat_type 				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'All products you sell were last published {relCompletedDtm}',
		in_css_class 				=> 'background-icon company-icon',
		in_addressing_type			=> chain.chain_pkg.COMPANY_ADDRESS
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH, 
				in_param_name 				=> 'productsYouSell', 
				in_href 					=> '/csr/site/chain/products/productsMyCompanySells.acds?showUnpublished=true'
			);
	

	/****************************************************************************
			MAERSK/CHAINDEMO SPECIFIC
	****************************************************************************/	
	----------------------------------------------------------------------------
	--		CHANGED_SUPPLIER_REG_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 				=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS,
		in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template				=> 'Supplier registration details for {reCompany} have changed. Please review your {rap:OPEN}Readiness Assessment Priority{rap:CLOSE}.',
		in_completion_type 				=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 			=> 'Reviewed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 					=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 			=> 'reCompany', 
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 				=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup =>		chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
				in_secondary_lookup	=> 		chain.chain_pkg.PURCHASER_MSG,
				in_param_name =>			'rap'
		);


	----------------------------------------------------------------------------
	--		ACTION_PLAN_STARTED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 				=> chain.chain_pkg.ACTION_PLAN_STARTED,
		in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template				=> 'An {actionPlan:OPEN}action plan{actionPlan:CLOSE} has been started (or restarted) for {reCompany}.',
		in_css_class 					=> 'background-icon faded-questionnaire-icon',
		in_priority						=> chain.chain_pkg.HIDDEN -- turn off by default
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.ACTION_PLAN_STARTED, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name			=> 'reCompany', 
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 				=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.ACTION_PLAN_STARTED, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 			=> 'actionPlan'
		);
		
		
	------------------------------------------------------------------------------
	-- RELATIONSHIPS
	------------------------------------------------------------------------------
	--RELATIONSHIP_ACTIVATED FOR PURCHASER
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_ACTIVATED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template			=>  'A relationship with {reCompany} has been established.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_ACTIVATED, 
						in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
						in_value 				=> '{reCompanyName}'
					);
					
	--RELATIONSHIP_ACTIVATED FOR SUPPLIER	
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_ACTIVATED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template			=>  'A relationship with {reCompany} has been established.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
		);

			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_ACTIVATED, 
						in_secondary_lookup		=> chain.chain_pkg.SUPPLIER_MSG,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_href 				=> NULL,
						in_value 				=> '{reCompanyName}'
					);
					
	--RELATIONSHIP_ACTIVATED_BETWEEN		
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_ACTIVATED_BETWEEN,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template			=>  'A relationship of {reCompany} with {reSecondaryCompany} has been established.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
		);

			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_ACTIVATED_BETWEEN, 
						in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
						in_value 				=> '{reCompanyName}'
					);
					
			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_ACTIVATED_BETWEEN, 
						in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
						in_param_name			=> 'reSecondaryCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
						in_value 				=> '{reSecondaryCompanyName}'
					);
					
	--RELATIONSHIP_DELETED FOR PURCHASER
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_DELETED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template			=>  'The relationship with {reCompany} has been deleted.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_DELETED, 
						in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_value 				=> '{reCompanyName}'
					);
					
										
	--RELATIONSHIP_DELETED FOR SUPPLIER
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_DELETED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template			=>  'The relationship with {reCompany} has been deleted.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_DELETED, 
						in_secondary_lookup		=> chain.chain_pkg.SUPPLIER_MSG,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_value 				=> '{reCompanyName}'
					);
					
					
	--RELATIONSHIP_DELETED_BETWEEN
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.RELATIONSHIP_DELETED_BETWEEN,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template			=>  'The relationship of {reCompany} with {reSecondaryCompany} has been deleted.',
		in_css_class 				=> 'background-icon info-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
						in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_DELETED_BETWEEN, 
						in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
						in_param_name			=> 'reCompany', 
						in_css_class 			=> 'background-icon faded-company-icon',
						in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
						in_value 				=> '{reCompanyName}'
					);
					
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.RELATIONSHIP_DELETED_BETWEEN, 
				in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name			=> 'reSecondaryCompany', 
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
				in_value 				=> '{reSecondaryCompanyName}'
			);

			
	------------------------------------------------------------------------------
	-- Invitations between B and C messaging for A
	------------------------------------------------------------------------------
	-- INVITATION_SENT_FROM_B_TO_C
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT_FROM_B_TO_C,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template 		=> 'Invitation sent to {reUser} of {reCompany} by {triggerUser} of {reSecondaryCompany}.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
		

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);
			
										
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.INVITATION_SENT_FROM_B_TO_C, 
				in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name			=> 'reSecondaryCompany', /* the company that triggered the invitation */
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
				in_value 				=> '{reSecondaryCompanyName}'
			);
	
	----------------------------------------------------------------------------
	--		INVITATION_ACCPTED_FROM_B_TO_C 
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCPTED_FROM_B_TO_C,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template 		=> 'Invitation sent by {reSecondaryCompany} accepted by {reUser} from {reCompany}.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCPTED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCPTED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.INVITATION_ACCPTED_FROM_B_TO_C, 
				in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name			=> 'reSecondaryCompany', /* the company that triggered the invitation */
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
				in_value 				=> '{reSecondaryCompanyName}'
			);
	
	
	----------------------------------------------------------------------------
	--		INVITATION_RJECTED_FROM_B_TO_C
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_RJECTED_FROM_B_TO_C,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template 		=> 'Invitation sent by {reSecondaryCompany} rejected by {reUser} from {reCompany}.',
		in_css_class 				=> 'background-icon delete-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_RJECTED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_RJECTED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.INVITATION_RJECTED_FROM_B_TO_C, 
				in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name			=> 'reSecondaryCompany', /* the company that triggered the invitation */
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
				in_value 				=> '{reSecondaryCompanyName}'
			);

	----------------------------------------------------------------------------
	--		INVITATION_EXPIRED_FROM_B_TO_C
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED_FROM_B_TO_C,
		in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
		in_message_template 		=> 'Invitation sent by {reSecondaryCompany} to {reUser} of {reCompany} has expired.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED_FROM_B_TO_C, 
				in_secondary_lookup			=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
		
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.INVITATION_EXPIRED_FROM_B_TO_C, 
				in_secondary_lookup		=> chain.chain_pkg.NONE_IMPLIED,
				in_param_name			=> 'reSecondaryCompany', /* the company that triggered the invitation */
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}',
				in_value 				=> '{reSecondaryCompanyName}'
			);
					
	----------------------------------------------------------------------------
	--		INVITATION_SENT => SUPPLIER_MSG 
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Invitation sent by {reUser} of {reCompany}.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> NULL,
				in_value 					=> '{reCompanyName}'
			);
			
				
			chain.message_pkg.DefineMessageParam( /* it can be used in overriden messages that display invitation url  */
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reInvitation', 
				in_value 					=> '{reInvitationId}'
			);
	
			chain.message_pkg.DefineMessageParam( /* it can be used in overriden messages that display invitation url  */
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reInvitationUrl'
			);	
			
	----------------------------------------------------------------------------
	--		INVITATION_ACCEPTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Invitation sent by {reCompany} accepted by {reUser}.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> NULL,
				in_value 					=> '{reCompanyName}'
			);
			
			
	----------------------------------------------------------------------------
	--		INVITATION_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Invitation sent by {reCompany} rejected by {reUser}.',
		in_css_class 				=> 'background-icon delete-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_value 					=> '{reCompanyName}'
			);
			
	----------------------------------------------------------------------------
	--	INVITATION_EXPIRED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
		chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Invitation sent by {reCompany} expired.',
		in_css_class 				=> 'background-icon invitation-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.NO_COMPLETION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_value 					=> '{reCompanyName}'
			);
			
	----------------------------------------------------------------------------
	--	Audit request messaging
	----------------------------------------------------------------------------
	--	AUDIT_REQUEST_CREATED -> Auditor
	----------------------------------------------------------------------------
		
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_CREATED,
		in_message_template 		=> 'Audit of {reSecondaryCompany} requested by {reUser} at {reCompany}. {reAuditRequestLink}',
		in_completed_template 		=> 'Audit created by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon audit-request-icon',
		in_repeat_type 				=> chain.chain_pkg.ALWAYS_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_priority					=> chain.chain_pkg.NEUTRAL
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reSecondaryCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reSecondaryCompanyName}'
			);
			
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_CREATED, 
				in_param_name 				=> 'reAuditRequestLink', 
				in_value 					=> 'Click here to view the request.',
				in_href						=> '/csr/site/chain/auditRequest.acds?auditRequestId={reAuditRequestId}'
			);
			
	
	----------------------------------------------------------------------------
	--	AUDIT_REQUEST_REQUIRED -> Supplier
	----------------------------------------------------------------------------
		
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_REQUIRED,
		in_secondary_lookup         => chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Audit required for {reCompanyName}, please {reAuditRequestLink}.',
		in_completed_template 		=> 'Audit request submitted to {reSecondaryCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon audit-request-icon',
		in_repeat_type 				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.AUDIT_REQUEST_REQUIRED,
				in_secondary_lookup         => chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reAuditRequestLink', 
				in_value 					=> 'create an audit request',
				in_href						=> '/csr/site/chain/createAuditRequest.acds?auditeeSid={reCompanySid}'
			);
END;
/

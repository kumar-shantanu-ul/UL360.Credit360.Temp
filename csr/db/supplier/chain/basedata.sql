BEGIN
	INSERT INTO supplier.user_profile_visibility (user_profile_visibility_id, description) VALUES (0, 'Fully hidden (i.e. superusers)');
	INSERT INTO supplier.user_profile_visibility (user_profile_visibility_id, description) VALUES (1, 'Hidden');
	INSERT INTO supplier.user_profile_visibility (user_profile_visibility_id, description) VALUES (2, 'Show my job title'); 
	INSERT INTO supplier.user_profile_visibility (user_profile_visibility_id, description) VALUES (3, 'Show only my name and job title'); 
	INSERT INTO supplier.user_profile_visibility (user_profile_visibility_id, description) VALUES (4, 'Show all');
END;
/

BEGIN
	INSERT INTO supplier.invite_status (invite_status_id, description) VALUES (0, 'Invitation sent');
	INSERT INTO supplier.invite_status (invite_status_id, description) VALUES (1, 'Cancelled');
	INSERT INTO supplier.invite_status (invite_status_id, description) VALUES (2, 'Accepted');
	INSERT INTO supplier.invite_status (invite_status_id, description) VALUES (3, 'Rejected - not supplier');
END;
/

BEGIN
	INSERT INTO supplier.contact_state (contact_state_id, description) VALUES (0, 'Active');
	INSERT INTO supplier.contact_state (contact_state_id, description) VALUES (1, 'Removed by owner procurer');
	INSERT INTO supplier.contact_state (contact_state_id, description) VALUES (2, 'Removed by contact invitation rejection');
	INSERT INTO supplier.contact_state (contact_state_id, description) VALUES (3, 'Registered as user');
END;
/

BEGIN
	INSERT INTO supplier.questionnaire_response_status (response_status_id, description) VALUES (0, 'Not completed');
	INSERT INTO supplier.questionnaire_response_status (response_status_id, description) VALUES (1, 'Submitted for approval');
	INSERT INTO supplier.questionnaire_response_status (response_status_id, description) VALUES (2, 'Approved for release');
END;
/

BEGIN
	INSERT INTO supplier.request_status (request_status_id, description) VALUES (0, 'Pending supplier acceptance');
	INSERT INTO supplier.request_status (request_status_id, description) VALUES (1, 'Accepted by supplier');
	INSERT INTO supplier.request_status (request_status_id, description) VALUES (2, 'Submitted by supplier');
END;
/

BEGIN
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (0, 'Text only');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (1, 'UserSid (Full name), CompanySid (Company name)');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (2, 'UserSid (Full name), UserSid (Full name), CompanySid (Company name)');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (3, 'UserSid (Full name), ContactId (Company name), QuestionnaireId (Friendly name)');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (4, 'UserSid (Full name), SupplierSid (Company name), QuestionnaireId (Friendly name)');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (5, 'UserSid (Full name), ProcurerSid (Company name), QuestionnaireId (Friendly name)');
	INSERT INTO supplier.message_template_format (message_template_format_id, tpl_format) VALUES (6, 'SupplierSid (Company name), QuestionnaireId (Friendly name)');
	
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		0, 
		0, 
		'Standard welcome message', 
		'Welcome to the CHAIN!');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		1, 
		1, 
		'Join company request', 
		'{0} would like to be added as a user to {1}');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		2, 
		2, 
		'Join company granted', 
		'{0} has added {1} as a user to {2}');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		3, 
		1, 
		'Join company denied', 
		'{0} has denied your request to be added as a user to {1}');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		4, 
		3, 
		'Contact invited to fill in questionnaire', 
		'{0} has invited {1} to complete the {2} questionnaire');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		5, 
		3, 
		'Contact reminded to fill in questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
		
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		6, 
		3, 
		'Contact questionnaire invitation cancelled', 
		'{0} has cancelled the request for {1} to complete the {2} questionnaire');
		
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		7, 
		4, 
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
		
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		8, 
		5, 
		'Message that a user has accepted an inviation from a procurer, to complete a questionnare', 
		'{0} has accepted the invitation from {1} to complete the {2} questionnaire');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		9, 
		4, 
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{1} has accepted the invitation from {0} to complete the {2} questionnaire');
		
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		10, 
		6, 
		'Message that a supplier has released a questionnaire to a procurer', 
		'{0} has submitted the {1} questionnaire');

	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		11, 
		5, 
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{0} has released {2} questionnaire to {1}');
	
	INSERT INTO supplier.message_template (message_template_id, message_template_format_id, label, tpl) VALUES (
		12, 
		4, 
		'Reminder from procurer to supplier user to complete a questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
END;
/

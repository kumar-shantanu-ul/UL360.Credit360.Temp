-- Please update version.sql too -- this keeps clean builds in sync
define version=1688
@update_header

--Snapshot of chain.card_pkg for RegisterCard and SetGroupsCards
@@latest1688_packages 
--	
BEGIN		
	
	security.user_pkg.logonadmin;
	
	INSERT INTO chain.invitation_type VALUES(4, 'No Questionnaire Invitation');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (11, 'Rejected - Not partner', NULL);
	
	 --add it in chain\basedata\csr_alerts.sql
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5014,
		'Chain company invitation',
		'A chain company invitation (without requiring a questionnaire) is created.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
		EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain company invitation',
				send_trigger = 'A chain company invitation (without requiring a questionnaire) is created.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5014;
	END;

	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'PERSONAL_MESSAGE', 'Personal message', 'A personal message from the sending user', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'LINK', 'Link', 'A hyperlink to the invitation landing page', 11);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES (5014, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 12);
	

	
	-- Create Company card group
	-- add to managers.sql, cards.sql
	chain.temp_card_pkg.RegisterCardGroup(10, 'Create Company', 'Used to create company by company type');
	chain.temp_card_pkg.RegisterCardGroup(39, 'Company Invitation Landing', 'Landing page verification for company invitations');

	-- Create Company card
	chain.temp_card_pkg.RegisterCard(
		'Company basic data including company type',
		'Credit360.Chain.Cards.CreateCompanyByCT',
		'/csr/site/chain/cards/createCompanyByCT.js', 
		'Chain.Cards.CreateCompanyByCT'
	);
	
	-- Supplier relationships card
	chain.temp_card_pkg.RegisterCard(
		'Supplier relationships',
		'Credit360.Chain.Cards.SupplierRelationship',
		'/csr/site/chain/cards/supplierRelationship.js', 
		'Chain.Cards.SupplierRelationship'
	); 
	
	--Company invitation confirmation
	chain.temp_card_pkg.RegisterCard(
		'Confirms company invitation details with a potential new user', 
		'Credit360.Chain.Cards.CompanyInvitationConfirmation',
		'/csr/site/chain/cards/CompanyInvitationConfirmation.js', 
		'Chain.Cards.CompanyInvitationConfirmation',
		chain.T_STRING_LIST('login', 'register', 'reject')
	);
	
END;
/

@..\chain\chain_pkg
@..\chain\invitation_pkg
@..\chain\questionnaire_pkg
@..\chain\company_type_pkg
@..\chain\company_pkg

@..\chain\invitation_body
@..\chain\company_type_body
@..\chain\company_body
@..\chain\chain_body

@update_tail
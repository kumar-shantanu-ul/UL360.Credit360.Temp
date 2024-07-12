PROMPT >> Setting up invitations
BEGIN	
	INSERT INTO chain.registration_status (registration_status_id, description) VALUES (0, 'Pending registration');
	INSERT INTO chain.registration_status (registration_status_id, description) VALUES (1, 'Registered');
	INSERT INTO chain.registration_status (registration_status_id, description) VALUES (2, 'Rejected');
	INSERT INTO chain.registration_status (registration_status_id, description) VALUES (3, 'Merged');
	
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (1, 'Active', 'Active'); -- start at 1 so that ACTIVE matches other implementations
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (2, 'Expired', 'Expired');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (3, 'Cancelled', 'Cancelled');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (4, 'Provisionally accepted', NULL);
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (5, 'Accepted', 'Accepted');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (6, 'Rejected - Not employee', 'Rejected');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (7, 'Rejected - Not supplier', NULL);
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (8, 'Another user self-registered', NULL);
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (9, 'User rejected terms and conditions', 'Rejected');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (10, 'Not invited', 'Not invited');
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (11, 'Rejected - Not partner', NULL);
	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (12, 'Rejected questionnaire request', NULL);
	
	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (1, 'Questionnaire Invitation');
	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (2, 'Stub Invitation');	
	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (3, 'Self Registration Questionnaire Invitation');
	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (4, 'No Questionnaire Invitation');
	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (5, 'Request questionnaire from an existing company');
END;
/

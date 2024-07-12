define version=101
@update_header

	INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (3, 'Self Registration Questionnaire Invitation');
	
	ALTER TABLE chain.INVITATION ADD CONSTRAINT SELF_REG_Q_INVITATION_CHECK CHECK (
	invitation_type_id <> 3 OR
	(
		invitation_type_id = 3 AND
		from_company_sid IS NOT NULL AND
		from_user_sid IS NOT NULL
	));

	INSERT INTO chain.card_group
	(card_group_id, name, description)
	VALUES
	(20, 'Questionnaire Self Registration Invitation Landing', 'Landing page verification for self registration questionnaire invitations');
	
@update_tail
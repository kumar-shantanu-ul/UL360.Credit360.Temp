define version=103
@update_header

BEGIN	

	INSERT INTO chain.invitation_status (invitation_status_id, description, filter_description) VALUES (8, 'Another user self-registered', NULL);
	
END;
/


@update_tail
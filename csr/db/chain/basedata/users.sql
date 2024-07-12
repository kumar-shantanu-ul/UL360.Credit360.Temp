PROMPT >> Setting up user statuses
BEGIN	
	INSERT INTO chain.visibility (visibility_id, description) VALUES (0, 'Hidden');
	INSERT INTO chain.visibility (visibility_id, description) VALUES (1, 'Job title');
	INSERT INTO chain.visibility (visibility_id, description) VALUES (2, 'Name and job title');
	INSERT INTO chain.visibility (visibility_id, description) VALUES (3, 'All details');		
END;
/

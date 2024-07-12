define version=36
@update_header

BEGIN
	INSERT INTO chain.action_repeat_type (action_repeat_type_id, description) VALUES (4, 'Reopen');
END;
/

@..\action_pkg
@..\action_body

@update_tail

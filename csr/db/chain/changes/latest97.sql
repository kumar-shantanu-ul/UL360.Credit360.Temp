define version=97
@update_header

BEGIN
	INSERT INTO CHAIN.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (4, 6, 9);
	
	INSERT INTO CHAIN.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (4, 6, 9);
	
	UPDATE CHAIN.task_action_trigger_transition 
	   SET to_task_status_id = 3
	 WHERE task_action_id = 14
	   AND from_task_status_id = -2;
END;
/


@..\chain_pkg
@..\task_pkg
@..\task_body
@..\rls

@update_tail
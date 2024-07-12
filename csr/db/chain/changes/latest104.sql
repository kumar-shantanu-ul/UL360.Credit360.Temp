define version=104
@update_header

BEGIN
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (10, 'The task is in a "waiting to start review" state - review timer will trigger to open');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (5, 'Set the task to start review timer');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (15, 'Revert start on the review timer');
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (1, 10, 3);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (11, 3, 10);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (12, 10, 6);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (3, 10, 8);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (13, 10, 9);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (4, 10, 9);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 0, 10);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 3, 10);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 6, 10);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 7, 10);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 9, 10);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (15, 10, 0);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (15, 10, 7);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (1, 10, 3);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (2, 10, 6);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (3, 10, 8);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (4, 10, 9);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 0, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 7, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 8, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 3, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 6, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (5, 9, 10);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (15, 10, -2);

	
END;
/

BEGIN
	INSERT INTO chain.card_group(card_group_id, name, description)
	VALUES(21, 'Supplier Extras', 'Takes a single card that can provide additional supplier details for multiple location use');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		UPDATE chain.card_group
		   SET description='Takes a single card that can provide additional supplier details for multiple location use'
		 WHERE card_group_id=21;
END;
/

@..\chain_pkg
@..\chain_link_pkg
@..\company_pkg
@..\message_pkg
@..\task_pkg

@..\chain_link_body
@..\company_body
@..\message_body
@..\task_body
@..\scheduled_alert_body


@update_tail

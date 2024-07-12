PROMPT >> Setting task common basedata
BEGIN
	/*****************************************************
		TASK STATUS
	*****************************************************/
	-- Virtual status
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_DEFAULT_STATUS, 'Reset to the default status for the task type');
	
	-- Virtual status
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_LAST_STATUS, 'Revert the status to the task.last_status_id');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_HIDDEN, 'Hidden');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_OPEN, 'Open');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_CLOSED, 'Closed/Finished');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_PENDING, 'Pending');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_REMOVED, 'Removed / Not Required');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_NA, 'Not applicable');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_REVIEW, 'The task is in a "waiting to start review" state - review timer will trigger to open');
	
	/* These states aren't currently used, so they've been removed to keep the data a bit cleaner
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_REQ_INIT_APPROVAL, 'Requires initial approval');

	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_SUB_INIT_APPROVAL, 'Submitted for intial approval');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_SUB_APPROVAL, 'Submitted for approval');
	
	INSERT INTO chain.task_status (task_status_id, description) 
	VALUES (chain.chain_pkg.TASK_APPROVED, 'Approved (until next review)');
	*/
	
	/*****************************************************
		TASK ENTRY TYPE
	*****************************************************/	
	
	INSERT INTO chain.task_entry_type (task_entry_type_id, description)
	VALUES (chain.chain_pkg.TASK_DATE, 'timestamp');
	
	INSERT INTO chain.task_entry_type (task_entry_type_id, description)
	VALUES (chain.chain_pkg.TASK_NOTE, 'note');
	
	INSERT INTO chain.task_entry_type (task_entry_type_id, description)
	VALUES (chain.chain_pkg.TASK_FILE, 'file');
		
	/*****************************************************
		TASK ACTION
	*****************************************************/

	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.OPEN_TASK, 'Open a task');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.CLOSE_TASK, 'Close a task');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REMOVE_TASK, 'Remove a task');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.NA_TASK, 'N/A a task');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, 'Set the task to start review timer');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REVERT_OPEN_TASK, 'Revert task open');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REVERT_CLOSE_TASK, 'Revert task close');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REVERT_REMOVE_TASK, 'Rever task remove');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REVERT_NA_TASK, 'Revert task N/A');
	
	INSERT INTO chain.task_action (task_action_id, description)
	VALUES (chain.chain_pkg.REVERT_START_REVIEW_TASK, 'Revert start on the review timer');
	
	
	/*****************************************************
		TASK ACTION LOOKUP
	*****************************************************/

	-- Works as: When the status is changing from X to Y, it is the action happening
	-- first case example: When we are changing from [HIDDEN, PENDING, REMOVED, NA or REVIEW] -> OPEN, this is an ON_OPEN_TASK action

	-- ON_OPEN_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_OPEN_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_OPEN);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_OPEN_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_OPEN);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_OPEN_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_OPEN);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_OPEN_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_OPEN);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_OPEN_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_OPEN);
	
	-- ON_REVERT_OPEN_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_OPEN_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_HIDDEN);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_OPEN_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_PENDING);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_OPEN_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_REVIEW);
	
	-- ON_CLOSE_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_CLOSED);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_CLOSED);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_CLOSED);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_CLOSED);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_CLOSED);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_CLOSE_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_CLOSED);

	-- ON_REVERT_CLOSE_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_CLOSE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_HIDDEN);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_CLOSE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_PENDING);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_CLOSE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_OPEN);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_CLOSE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_NA);
		
	-- ON_REMOVE_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REMOVE_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_REMOVED);
	
	-- ON_REVERT_REMOVE_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_HIDDEN);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_OPEN);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_CLOSED);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_PENDING);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_REMOVED);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_NA);
		
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_NA);
		
	-- ON_NA_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_NA_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_NA);

	-- ON_REVERT_NA_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_NA_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_HIDDEN);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_NA_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_PENDING);
	
	-- ON_START_REVIEW_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_START_REVIEW_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_START_REVIEW_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_START_REVIEW_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_START_REVIEW_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_START_REVIEW_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_REVIEW);
	
	-- ON_REVERT_START_REVIEW_TASK lookups
	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_START_REVIEW_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_HIDDEN);

	INSERT INTO chain.task_action_lookup (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.ON_REVERT_START_REVIEW_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_PENDING);


	/*****************************************************
		TASK ACTION TRIGGER TRANSITION
	*****************************************************/	
	
	-- Works as: When we're triggering this action, and we're in our current state, go to this state
	-- first case example: When we are OPENING a task, and our currect state is [HIDDEN, PENDING, REMOVED, NA or REVIEW] change the state to OPEN, otherwise ignore
	
	-- OPEN_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.OPEN_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_OPEN);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.OPEN_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_OPEN);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.OPEN_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_OPEN);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.OPEN_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_OPEN);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.OPEN_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_OPEN);

	-- REVERT_OPEN_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REVERT_OPEN_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_DEFAULT_STATUS);

	-- CLOSE_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_CLOSED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_CLOSED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_CLOSED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_CLOSED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_CLOSED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.CLOSE_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_CLOSED);
	
	-- REVERT_CLOSE_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REVERT_CLOSE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_OPEN);
	
	-- REMOVE_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_REMOVED);
	
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REMOVE_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_REMOVED);
	
	-- REVERT_REMOVE_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REVERT_REMOVE_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_LAST_STATUS);
	
	-- NA_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_NA);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.NA_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_NA);

	-- REVERT_NA_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REVERT_NA_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_OPEN);

	-- START_REVIEW_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_HIDDEN, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_PENDING, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_REMOVED, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_OPEN, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_CLOSED, chain.chain_pkg.TASK_REVIEW);

	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.START_REVIEW_TASK, chain.chain_pkg.TASK_NA, chain.chain_pkg.TASK_REVIEW);
	
	-- REVERT_START_REVIEW_TASK transitions
	INSERT INTO chain.task_action_trigger_transition (task_action_id, from_task_status_id, to_task_status_id)
	VALUES (chain.chain_pkg.REVERT_START_REVIEW_TASK, chain.chain_pkg.TASK_REVIEW, chain.chain_pkg.TASK_DEFAULT_STATUS);
END;
/

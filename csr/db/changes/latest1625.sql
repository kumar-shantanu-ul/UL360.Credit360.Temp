-- Please update version.sql too -- this keeps clean builds in sync
define version=1625
@update_header

-- fix for clean builds with incorrect base data
BEGIN
	UPDATE csr.issue_state
	   SET description = 'Default Permissions'
	 WHERE issue_state_id = 0;
 
	BEGIN
		INSERT INTO csr.issue_state (issue_state_id, description)
		  VALUES (9, 'Create');
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/
							 
@update_tail

ALTER TABLE TASK ADD (owner_sid NUMBER(10) NULL);

BEGIN
	UPDATE TASK t SET owner_sid = 
	(SELECT user_or_group_sid
	 FROM TASK_ROLE_MEMBER trm
	WHERE t.task_sid = trm.task_sid 
	  AND role_id = (SELECT role_id FROM ROLE WHERE NAME='RMOW Lead'));
	UPDATE TASK SET owner_sid = 3 WHERE owner_sid IS NULL;
END;
/
COMMIT;       
             
ALTER TABLE TASK MODIFY owner_sid NOT NULL;

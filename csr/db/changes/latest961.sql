-- Please update version.sql too -- this keeps clean builds in sync
define version=961
@update_header

ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD (TASK_MANAGER_HELPER_TYPE VARCHAR2(1000));

ALTER TABLE CHAIN.TASK ADD (SKIPPED NUMBER(1, 0) DEFAULT 0 NOT NULL);

BEGIN
	UPDATE CHAIN.task_type SET mandatory = 1;
	UPDATE CHAIN.task SET due_date = NULL WHERE task_type_id IN (SELECT task_type_id FROM CHAIN.task_type WHERE due_in_days IS NULL);
END;
/

@..\chain\chain_link_pkg
@..\chain\task_pkg

@..\chain\chain_link_body
@..\chain\helper_body
@..\chain\task_body

@update_tail

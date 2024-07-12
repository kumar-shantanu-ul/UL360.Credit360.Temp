-- Please update version.sql too -- this keeps clean builds in sync
define version=90
@update_header

declare
	v_n varchar2(255);
begin
	select constraint_name 
	  into v_n
	  from all_constraints 
	 where owner='ACTIONS' and (constraint_name like 'REFTASK_STATUS_TRANSITION%' OR constraint_name = 'FK_TASK_ST_TR_TASK')
	   and table_name ='TASK';
	execute immediate 'alter table actions.task drop constraint '||v_n;
end;
/

ALTER TABLE actions.TASK_STATUS_TRANSITION ADD CONSTRAINT CONS_TASK_STATUS_TRANSITION  UNIQUE (TASK_STATUS_TRANSITION_ID);

ALTER TABLE actions.TASK ADD CONSTRAINT FK_TASK_ST_TR_TASK 
    FOREIGN KEY (LAST_TRANSITION_ID)
    REFERENCES actions.TASK_STATUS_TRANSITION(TASK_STATUS_TRANSITION_ID) ON DELETE SET NULL
;
 
@update_tail

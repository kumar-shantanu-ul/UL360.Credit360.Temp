-- Please update version.sql too -- this keeps clean builds in sync
define version=24
@update_header

-- this index wasn't present in my db (rk)
DECLARE
    v_cnt number(10);
BEGIN
    select count(*) INTO v_cnt
      from dba_indexes 
     where owner='ACTIONS' and index_name='PK7';
    if v_cnt = 0 then
		execute immediate('ALTER INDEX REFPROJECT_TASK_PERIOD_STATU26 RENAME TO PK7');
		execute immediate('ALTER TABLE TASK_PERIOD RENAME CONSTRAINT REFPROJECT_TASK_PERIOD_STATU26 TO PK7');
		execute immediate('ALTER TABLE TASK_PERIOD ADD CONSTRAINT RefPROJECT_TASK_PERIOD_STATU26 '||
		    'FOREIGN KEY (PROJECT_SID, TASK_PERIOD_STATUS_ID) '||
		    'REFERENCES PROJECT_TASK_PERIOD_STATUS(PROJECT_SID, TASK_PERIOD_STATUS_ID)');
    end if;
END;
/

@update_tail

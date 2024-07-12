-- Please update version.sql too -- this keeps clean builds in sync
define version=48
@update_header

alter table AGGR_TASK_IND_DEPENDENCY drop primary key drop index;
alter table AGGR_TASK_IND_DEPENDENCY add 
    CONSTRAINT PK_AGGR_TASK_IND_DEPENDENCY PRIMARY KEY (APP_SID, TASK_SID, IND_SID)
    USING INDEX
TABLESPACE INDX
;

@update_tail

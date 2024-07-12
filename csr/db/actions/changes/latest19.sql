-- Please update version.sql too -- this keeps clean builds in sync
define version=19
@update_header

ALTER TABLE AGGR_TASK_IND_DEPENDENCY DROP CONSTRAINT PK54;

ALTER TABLE AGGR_TASK_IND_DEPENDENCY ADD CONSTRAINT PK54 PRIMARY KEY (TASK_SID, IND_SID);

@update_tail
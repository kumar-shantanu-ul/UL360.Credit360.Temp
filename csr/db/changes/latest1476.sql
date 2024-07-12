-- Please update version.sql too -- this keeps clean builds in sync
define version=1476
@update_header

ALTER TABLE CHAIN.TT_SUMMARY_TASKS MODIFY COMPANY_SID NUMBER(10) NULL;

@..\chain\task_body

@update_tail
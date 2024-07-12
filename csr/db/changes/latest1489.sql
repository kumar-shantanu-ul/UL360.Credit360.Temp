-- Please update version.sql too -- this keeps clean builds in sync
define version=1489
@update_header

ALTER TABLE CHAIN.TT_SUMMARY_TASKS ADD DUE_DATE DATE;

@..\chain\chain_link_pkg

@..\chain\chain_link_body
@..\chain\task_body 

@update_tail
-- Please update version.sql too -- this keeps clean builds in sync
define version=488
@update_header

ALTER TABLE PENDING_DATASET ADD (helper_pkg VARCHAR2(255));

@..\approval_step_range_body

@update_tail

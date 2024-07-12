-- Please update version.sql too -- this keeps clean builds in sync
define version=494
@update_header

ALTER TABLE issue_scheduled_task
	ADD NEXT_RUN_DTM TIMESTAMP(6);

@update_tail

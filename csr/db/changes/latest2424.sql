-- Please update version.sql too -- this keeps clean builds in sync
define version=2424
@update_header

@../chain/task_body

@update_tail
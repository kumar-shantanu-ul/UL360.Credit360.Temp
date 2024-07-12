-- Please update version.sql too -- this keeps clean builds in sync
define version=1809
@update_header

@../chain/task_pkg
@../chain/task_body
 
@update_tail
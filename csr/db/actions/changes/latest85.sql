-- Please update version.sql too -- this keeps clean builds in sync
define version=85
@update_header

grant select, references on TASK_TAG to csr;

@update_tail

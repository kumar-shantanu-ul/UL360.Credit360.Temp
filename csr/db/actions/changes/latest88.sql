-- Please update version.sql too -- this keeps clean builds in sync
define version=88
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select, delete, references on csr.selected_axis_task to actions;

connect actions/actions@&_CONNECT_IDENTIFIER
@../task_body
@../initiative_body

@update_tail

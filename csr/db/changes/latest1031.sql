-- Please update version.sql too -- this keeps clean builds in sync
define version=1031
@update_header

grant select, references on actions.TASK_PERIOD to csr;
grant select, references on actions.TASK_PERIOD_STATUS to csr;

@../strategy_pkg
@../strategy_body

@update_tail

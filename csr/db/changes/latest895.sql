-- Please update version.sql too -- this keeps clean builds in sync
define version=895
@update_header

alter table csr.model_instance add (
	run_state varchar2(1) default 'N' not null,
	constraint chk_mi_run_state check (run_state in (
		'N', -- New
		'W', -- Waiting for run completion
		'R'  -- Run / ready
	))
);

update csr.model_instance set run_state = 'R';

@..\model_pkg
@..\model_body

@update_tail

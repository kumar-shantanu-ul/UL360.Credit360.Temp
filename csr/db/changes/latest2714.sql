-- Please update version.sql too -- this keeps clean builds in sync
define version=2714
@update_header

ALTER TABLE csr.qs_answer_file MODIFY (
	DATA NULL
);

@update_tail

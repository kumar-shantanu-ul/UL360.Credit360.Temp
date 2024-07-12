-- Please update version.sql too -- this keeps clean builds in sync
define version=350
@update_header

DROP SEQUENCE csr.approval_step_id_seq;

@update_tail

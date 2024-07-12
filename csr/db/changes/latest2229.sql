-- Please update version.sql too -- this keeps clean builds in sync
define version=2229
@update_header

ALTER TABLE csr.flow_state
ADD
	(
		MOVE_TO_FLOW_STATE_ID		NUMBER(10,0) DEFAULT NULL
	);

@..\flow_pkg
@..\flow_body

@update_tail

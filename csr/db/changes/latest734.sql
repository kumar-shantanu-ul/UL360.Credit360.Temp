-- Please update version.sql too -- this keeps clean builds in sync
define version=734
@update_header

ALTER TABLE csr.ISSUE MODIFY (
	LABEL	VARCHAR2(2048)
);

@update_tail

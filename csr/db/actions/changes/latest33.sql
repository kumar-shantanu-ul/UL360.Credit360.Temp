-- Please update version.sql too -- this keeps clean builds in sync
define version=33
@update_header

ALTER TABLE PROJECT ADD (
	ICON	VARCHAR2(256) NULL
);

@update_tail

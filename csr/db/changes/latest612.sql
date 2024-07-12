-- Please update version.sql too -- this keeps clean builds in sync
define version=612
@update_header

ALTER TABLE csr.role ADD (
	LOOKUP_KEY VARCHAR2(255)
);

CREATE UNIQUE INDEX csr.UK_ROLE_LOOKUP_KEY ON csr.ROLE(APP_SID, UPPER(NVL(LOOKUP_KEY,ROLE_SID)));

@..\role_pkg
@..\role_body


@update_tail

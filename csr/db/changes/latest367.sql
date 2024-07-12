-- Please update version.sql too -- this keeps clean builds in sync
define version=367
@update_header

ALTER TABLE UTILITY_CONTRACT ADD (
	CREATED_BY_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','SID') NULL
)
;

@../rls

@update_tail

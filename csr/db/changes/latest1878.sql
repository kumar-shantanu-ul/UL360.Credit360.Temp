-- Please update version.sql too -- this keeps clean builds in sync
define version=1878
@update_header

CREATE SEQUENCE CSR.ISSUE_INITIATIVE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 5
	NOORDER
;


@update_tail

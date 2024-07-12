--Please update version.sql too -- this keeps clean builds in sync
define version=2679
@update_header

ALTER TABLE CSRIMP.REGION ADD (
	REGION_REF              VARCHAR2(255)
);

@..\csrimp\imp_body.sql

@update_tail

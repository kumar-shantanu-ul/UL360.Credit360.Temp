-- Please update version.sql too -- this keeps clean builds in sync
define version=2446
@update_header

ALTER TABLE csrimp.MODEL ADD (
	LOOKUP_KEY                  VARCHAR2(255)
);
    

@..\schema_body
@..\csrimp\imp_body

@update_tail
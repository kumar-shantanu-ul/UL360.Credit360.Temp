-- Please update version.sql too -- this keeps clean builds in sync
define version=988
@update_header

ALTER TABLE CHEM.SUBSTANCE_USE DROP CONSTRAINT UC_SUBSTANCE_USE_1;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
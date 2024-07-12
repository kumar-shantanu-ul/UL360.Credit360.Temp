-- Please update version.sql too -- this keeps clean builds in sync
define version=987
@update_header

ALTER TABLE CHEM.SUBSTANCE ADD CONSTRAINT UK_SUBSTANCE UNIQUE (APP_SID, REF, DESCRIPTION);

@update_tail
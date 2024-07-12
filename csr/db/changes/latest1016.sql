-- Please update version.sql too -- this keeps clean builds in sync
define version=1016
@update_header

DROP INDEX CHEM.UK_MANUFACTURER;

CREATE UNIQUE INDEX CHEM.UK_MANUFACTURER ON CHEM.MANUFACTURER (APP_SID,NAME);

@update_tail
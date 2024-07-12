-- Please update version.sql too -- this keeps clean builds in sync
define version=2423
@update_header

ALTER TABLE postcode.airport MODIFY pos NOT NULL;

@update_tail
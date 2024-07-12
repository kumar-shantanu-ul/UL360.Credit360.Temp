-- Please update version.sql too -- this keeps clean builds in sync
define version=441
@update_header

ALTER TABLE property_division
DROP PRIMARY KEY;

@update_tail

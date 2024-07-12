-- Please update version.sql too -- this keeps clean builds in sync
define version=440
@update_header

ALTER TABLE property_division
MODIFY(end_dtm NULL);

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=438
@update_header

ALTER TABLE dataview_ind_member
DROP PRIMARY KEY;

ALTER TABLE dataview_region_member
DROP PRIMARY KEY;

@update_tail

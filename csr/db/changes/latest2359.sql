-- Please update version.sql too -- this keeps clean builds in sync
define version=2359
@update_header

alter table csrimp.map_val modify old_val_id number(20);
alter table csrimp.map_val modify new_val_id number(20);

@update_tail

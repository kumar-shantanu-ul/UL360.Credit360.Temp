-- Please update version.sql too -- this keeps clean builds in sync
define version=1672
@update_header

alter table csrimp.dataview_zone add type number(10) default 0 not null;
alter table csrimp.dataview_zone add description varchar2(255) null;

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1665
@update_header

alter table csr.dataview_zone add type number(10) default 0 not null;
alter table csr.dataview_zone add description varchar2(255) null;

@../dataview_pkg
@../dataview_body

@update_tail

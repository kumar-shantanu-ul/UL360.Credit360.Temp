-- Please update version.sql too -- this keeps clean builds in sync
define version=388
@update_header

alter table snapshot_ind add (pos number(10,0) default 0 not null);

@../snapshot_body

@update_tail

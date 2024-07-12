-- Please update version.sql too -- this keeps clean builds in sync
define version=31
@update_header


alter table imp_ind add (ignore number(1,0) default 0 not null);

alter table imp_region add (ignore number(1,0) default 0 not null);


@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=27
@update_header

update scheme_field set show_in_browse=0 where show_in_browse is null;
alter table scheme_field modify show_in_browse not null;

@update_tail

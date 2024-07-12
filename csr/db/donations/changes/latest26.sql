-- Please update version.sql too -- this keeps clean builds in sync
define version=26
@update_header

ALTER TABLE SCHEME_FIELD add SHOW_IN_BROWSE2 NUMBER(1);
update scheme_field set show_in_browse2=show_in_browse;
alter table scheme_field drop column show_in_browse;
ALTER TABLE SCHEME_FIELD rename column show_in_browse2 to show_in_browse;

@update_tail

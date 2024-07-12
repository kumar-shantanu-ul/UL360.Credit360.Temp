-- Please update version.sql too -- this keeps clean builds in sync
define version=565
@update_header

alter table ind_window add (temp_upper_bracket number(10,4), temp_lower_bracket number(10,4));
lock table ind_window in exclusive mode;
alter table ind_window modify lower_bracket null;
alter table ind_window modify upper_bracket null;
update ind_window set temp_upper_bracket = upper_bracket, temp_lower_bracket = lower_bracket, upper_bracket=null,lower_bracket=null;
alter table ind_window modify upper_bracket number(10,4);
alter table ind_window modify lower_bracket number(10,4);
update ind_window set lower_bracket = temp_lower_bracket, upper_bracket = temp_upper_bracket;
alter table ind_window modify lower_bracket not null;
alter table ind_window modify upper_bracket not null;
alter table ind_window drop column temp_upper_bracket;
alter table ind_window drop column temp_lower_bracket;

@update_tail

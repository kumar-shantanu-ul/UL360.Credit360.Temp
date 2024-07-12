define version=111
set define off
set define &
insert into version (part, db_version) values ('greentick', &version);
commit;

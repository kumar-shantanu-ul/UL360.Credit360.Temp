define version=1
set define off
set define &
insert into version (part, db_version) values ('chain', &version);
commit;

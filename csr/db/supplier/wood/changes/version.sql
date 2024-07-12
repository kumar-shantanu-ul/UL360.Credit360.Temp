define version=0
set define off
set define &
insert into version (part, db_version) values ('wood', &version);
commit;

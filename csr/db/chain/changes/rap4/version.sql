define rap4_version=15
set define off
set define &
insert into chain.version (db_version, part) values (&rap4_version, 'rap4');
commit;

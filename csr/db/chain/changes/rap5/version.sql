define rap5_version=14
set define off
set define &
insert into chain.version (db_version, part) values (&rap5_version, 'rap5');
commit;

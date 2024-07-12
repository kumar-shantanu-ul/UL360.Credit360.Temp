define version=3500
define minor_version=2
set define &
INSERT INTO csr.version (db_version, minor_version) VALUES (&version, &minor_version);
COMMIT;

SELECT 'security' oracle_user, db_version from security.version
UNION
SELECT 'mail' oracle_user, db_version from mail.version
UNION
SELECT 'csr' oracle_user, db_version from csr.version
;

exit
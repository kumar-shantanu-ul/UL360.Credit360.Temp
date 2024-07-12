spool C:\cvs\csr\db\supplier\greentick\create_db.log app

PROMPT > creating sequences and tables...
PROMPT ====================================================
@create_schema
@create_views
@create_fk_indexes

GRANT DELETE ON GT_TARGET_SCORES TO CSR;
GRANT DELETE ON GT_TARGET_SCORES_LOG TO CSR;

PROMPT Building packages
PROMPT ====================================================
@build

exit

PROMPT >> Disabling chain

EXEC user_pkg.LogonAdmin('&&1');
@@DisableChainPLSQL.sql
/

commit;

PROMPT >> *** CHAIN DISABLED

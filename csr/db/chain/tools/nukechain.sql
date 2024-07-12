whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

SET VERIFY OFF;
SET SERVEROUTPUT ON;

PROMPT >> Enter a host

DECLARE
BEGIN
	security.user_pkg.logonadmin('&&1');
	chain.chain_pkg.DeleteChainData(SYS_CONTEXT('SECURITY', 'APP'));
END;
/

@@DisableChainPLSQL.sql
/

commit;
exit

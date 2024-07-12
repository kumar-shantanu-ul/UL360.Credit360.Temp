PROMPT >> Enabling portlets

connect csr/csr@&_CONNECT_IDENTIFIER
PROMPT >> Please enter a host:
@@..\..\utils\EnablePortal &&1

PROMPT >> Enabling chain

connect chain/chain@&_CONNECT_IDENTIFIER
EXEC user_pkg.LogonAdmin('&&1');
PROMPT >> Would you like to setup menus and change the login home? (Y/N)
@@EnableChainPLSQL.sql &&2
/

commit;

PROMPT >> *** CHAIN ENABLED

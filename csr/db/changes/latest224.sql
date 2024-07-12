-- Please update version.sql too -- this keeps clean builds in sync
define version=224
@update_header

create user web_user identified by web_user default tablespace users temporary tablespace temp;
grant create session to web_user;
@..\web_grants

PROMPT You must also import latest224.reg into the registry
PROMPT If on x64, you must import latest224_x64.reg into the registry as well

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=43
@update_header

PROMPT Enter connection (e.g. ASPEN)
connect security/security@&&1

grant select on group_members to actions;
grant execute on group_pkg to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail

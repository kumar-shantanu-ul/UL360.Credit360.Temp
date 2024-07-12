-- Please update version.sql too -- this keeps clean builds in sync
define version=50
@update_header

-- run as csr
PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

grant select, references on role to actions;
grant select, references on region_role_member to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail

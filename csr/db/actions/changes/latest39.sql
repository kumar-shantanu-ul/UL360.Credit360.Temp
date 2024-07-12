-- Please update version.sql too -- this keeps clean builds in sync
define version=39
@update_header

PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

grant select, references on measure to actions;
grant select, references on measure_conversion to actions;
grant execute on csr_data_pkg to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail

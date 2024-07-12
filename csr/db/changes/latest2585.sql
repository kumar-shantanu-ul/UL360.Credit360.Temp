-- Please update version.sql too -- this keeps clean builds in sync
define version=2585
@update_header

-- Fix unnecessary chain PUBLIC grants.
REVOKE SELECT ON chain.tt_sid_link_lookup FROM PUBLIC;
REVOKE EXECUTE ON chain.t_capability_check_row FROM PUBLIC;
REVOKE EXECUTE ON chain.t_capability_check_table FROM PUBLIC;
REVOKE EXECUTE ON chain.t_numeric_table FROM PUBLIC;

GRANT EXECUTE ON chain.t_capability_check_table TO csr;
GRANT EXECUTE ON chain.t_numeric_table TO csr;

@update_tail

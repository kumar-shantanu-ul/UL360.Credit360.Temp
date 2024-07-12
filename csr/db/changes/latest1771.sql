-- Please update version.sql too -- this keeps clean builds in sync
define version=1771
@update_header

grant execute on csr.stragg to chem;

@update_tail
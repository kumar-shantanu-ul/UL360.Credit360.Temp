-- Please update version.sql too -- this keeps clean builds in sync
define version=2232
@update_header

GRANT EXECUTE ON chain.company_tag_pkg TO csr;

@update_tail

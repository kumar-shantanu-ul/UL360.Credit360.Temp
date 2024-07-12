-- Please update version.sql too -- this keeps clean builds in sync
define version=1212
@update_header

grant execute on chain.company_pkg to ct;

@update_tail
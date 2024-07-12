-- Please update version.sql too -- this keeps clean builds in sync
define version=2122
@update_header

grant execute on chain.T_STRING_LIST to csr;

@update_tail
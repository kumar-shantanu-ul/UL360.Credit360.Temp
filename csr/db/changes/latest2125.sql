-- Please update version.sql too -- this keeps clean builds in sync
define version=2125
@update_header

grant execute on chain.card_pkg to csr;

@update_tail
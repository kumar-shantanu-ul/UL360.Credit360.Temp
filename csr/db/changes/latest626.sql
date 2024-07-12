-- Please update version.sql too -- this keeps clean builds in sync
define version=626
@update_header

connect chain/chain@&_CONNECT_IDENTIFIER

grant update on chain.chain_user to csr;

connect csr/csr@&_CONNECT_IDENTIFIER
@..\csr_user_body

@update_tail

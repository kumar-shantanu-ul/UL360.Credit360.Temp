-- Please update version.sql too -- this keeps clean builds in sync
define version=735
@update_header

@requiredvers 'chain' 125 'trunk'

connect chain/chain@&_CONNECT_IDENTIFIER

grant select on chain.sector to csr;

connect csr/csr@&_CONNECT_IDENTIFIER

@../supplier_body

@update_tail

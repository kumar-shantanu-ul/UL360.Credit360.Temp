-- Please update version.sql too -- this keeps clean builds in sync
define version=514
@update_header


grant select, references on csr_user to chain with grant option;

CONNECT security/security@&_CONNECT_IDENTIFIER;
grant select, references on securable_object to chain WITH GRANT OPTION;
grant select, references on group_members to chain WITH GRANT OPTION;

CONNECT chain/chain@&_CONNECT_IDENTIFIER

grant select, references on chain.v$company_user to csr;

CONNECT CSR/CSR@&_CONNECT_IDENTIFIER

@..\supplier_body

@update_tail



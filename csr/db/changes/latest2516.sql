-- Please update version.sql too -- this keeps clean builds in sync
define version=2516
@update_header

INSERT INTO csr.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can import users and role memberships via structure import', 0);

@../csr_user_pkg
@../csr_user_body
@../role_pkg
@../role_body

@update_tail


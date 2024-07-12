-- Please update version.sql too -- this keeps clean builds in sync
define version=229
@update_header

PROMPT enter connection (e.g. ASPEN):
connect security/security@&&1
grant select, references, update on security.securable_object to csr;

connect csr/csr@&&1
@..\csr_user_body

@update_tail

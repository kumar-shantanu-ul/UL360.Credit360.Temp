-- Please update version.sql too -- this keeps clean builds in sync
define version=2429
@update_header

@../csr_app_body

@update_tail

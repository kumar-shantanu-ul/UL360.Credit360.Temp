-- Please update version.sql too -- this keeps clean builds in sync
define version=482
@update_header

connect actions/actions@&_CONNECT_IDENTIFIER

GRANT DELETE ON ACTIONS.TASK_RECALC_REGION TO CSR;

connect csr/csr@&_CONNECT_IDENTIFIER

@..\region_body

@update_tail

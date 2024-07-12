-- Please update version.sql too -- this keeps clean builds in sync
define version=1007
@update_header

DROP INDEX CSR.UK_FLOW_STATE_LOOKUP;

@update_tail

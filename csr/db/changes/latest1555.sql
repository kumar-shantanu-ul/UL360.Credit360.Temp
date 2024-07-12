-- Please update version.sql too -- this keeps clean builds in sync
define version=1555
@update_header

ALTER TABLE CSR.FLOW_ITEM MODIFY LAST_FLOW_STATE_LOG_ID NULL;

ALTER TABLE CSR.FLOW_ITEM MODIFY LAST_FLOW_STATE_LOG_ID NOT NULL DEFERRABLE INITIALLY DEFERRED;

@update_tail
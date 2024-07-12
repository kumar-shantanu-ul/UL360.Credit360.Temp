-- Please update version.sql too -- this keeps clean builds in sync
define version=1618
@update_header

ALTER TABLE CSR.FLOW_STATE ADD IS_FINAL  NUMBER(1, 0)     DEFAULT 0 NOT NULL;

@../flow_body

@update_tail

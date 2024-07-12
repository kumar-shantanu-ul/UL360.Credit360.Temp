-- Please update version.sql too -- this keeps clean builds in sync
define version=79
@update_header

ALTER TABLE supplier.chain_questionnaire MODIFY app_sid DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL;

@update_tail

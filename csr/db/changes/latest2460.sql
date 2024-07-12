-- Please update version.sql too -- this keeps clean builds in sync
define version=2460
@update_header

@..\chain\company_body
@..\audit_body

@update_tail

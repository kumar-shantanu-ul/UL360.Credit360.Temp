-- Please update version.sql too -- this keeps clean builds in sync
define version=1743
@update_header

@..\chain\company_pkg
@..\chain\company_body

@update_tail

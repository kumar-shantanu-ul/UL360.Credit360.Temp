-- Please update version.sql too -- this keeps clean builds in sync
define version=2697
@update_header

@..\chain\business_relationship_pkg
@..\chain\company_filter_pkg

@..\chain\business_relationship_body
@..\chain\company_filter_body

@update_tail

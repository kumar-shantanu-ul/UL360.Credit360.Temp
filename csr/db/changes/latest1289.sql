-- Please update version.sql too -- this keeps clean builds in sync
define version=1289
@update_header

grant execute on chain.excel_pkg to ct;

@..\chain\excel_pkg
@..\excel_pkg
@..\ct\breakdown_type_pkg
@..\ct\breakdown_group_pkg
@..\ct\breakdown_pkg
@..\ct\company_pkg
@..\ct\excel_pkg
@..\ct\link_pkg
@..\ct\util_pkg

@..\chain\excel_body
@..\excel_body
@..\ct\breakdown_type_body
@..\ct\breakdown_group_body
@..\ct\breakdown_body
@..\ct\company_body
@..\ct\excel_body
@..\ct\link_body
@..\ct\util_body

@update_tail

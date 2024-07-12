-- Please update version.sql too -- this keeps clean builds in sync
define version=1234
@update_header

grant all on csr.tab_portlet to ct;
grant all on csr.tab_group to ct;
grant all on csr.tab to ct;

@..\portlet_pkg
@..\ct\util_pkg

@..\ct\util_body
@..\portlet_body

@update_tail

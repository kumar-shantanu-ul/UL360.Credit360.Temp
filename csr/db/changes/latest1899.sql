-- Please update version.sql too -- this keeps clean builds in sync
define version=1899
@update_header

alter table cms.tab add policy_function varchar2(100);
alter table csrimp.cms_tab add policy_function varchar2(100);

@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
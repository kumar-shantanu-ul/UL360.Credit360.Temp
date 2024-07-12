-- Please update version.sql too -- this keeps clean builds in sync
define version=1020
@update_header

alter table cms.tab_column add helper_pkg varchar2(255);

@../../../aspen2/cms/db/tab_body

@update_tail

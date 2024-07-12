-- Please update version.sql too -- this keeps clean builds in sync
define version=1139
@update_header

alter table cms.tab_column add tree_desc_field varchar2(30);
alter table cms.tab_column add tree_id_field varchar2(30);
alter table cms.tab_column add tree_parent_id_field varchar2(30);

insert into cms.col_type values (29, 'Tree');

@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body

@update_tail

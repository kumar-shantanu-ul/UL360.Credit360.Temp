--Please update version.sql too -- this keeps clean builds in sync
define version=2704
@update_header

begin
	for r in (select 1 from all_tab_columns where owner='CSRIMP' and table_name='CMS_TAB_COLUMN' and column_name='OWNER_PERMISSION' and nullable='N')
	loop
		execute immediate 'alter table csrimp.cms_tab_column modify owner_permission null';
	end loop;
	for r in (select 1 from all_tab_columns where owner='CMS' and table_name='TAB_COLUMN' and column_name='OWNER_PERMISSION' and nullable='N')
	loop
		execute immediate 'alter table cms.tab_column modify owner_permission null';
	end loop;
end;
/

@../../../aspen2/cms/db/tab_body
	
@update_tail

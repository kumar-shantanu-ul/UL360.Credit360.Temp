-- Please update version.sql too -- this keeps clean builds in sync
define version=2947
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
declare
	v_exists number;
begin
	select count(*) into v_exists from all_indexes where owner='CMS' and index_name='IX_IMP_CONS_COLS_OWN_TAB_COL';
	if v_exists = 0 then
		execute immediate 'create index cms.ix_imp_cons_cols_own_tab_col on cms.imp_cons_columns (owner, table_name, column_name)';
	end if;

	select count(*) into v_exists from all_indexes where owner='CMS' and index_name='IX_IMP_CONS_OWN_CONS';
	if v_exists = 0 then
		execute immediate 'create index cms.ix_imp_cons_own_cons on cms.imp_constraints (owner, constraint_name)';
	end if;
	
	select count(*) into v_exists from all_indexes where owner='CMS' and index_name='IX_IMP_CONS_R_OWN_R_CONS';
	if v_exists = 0 then
		execute immediate 'create index cms.ix_imp_cons_r_own_r_cons on cms.imp_constraints (r_owner, r_constraint_name)';
	end if;
	
	for r in (select table_name from all_tables where owner = 'CSRIMP' and table_name in ('TEMP_SHEET_HISTORY', 'TEMP_SHEET_VALUE', 'TEMP_IMP_SET_VAL')) loop
		execute immediate 'drop table csrimp.'||r.table_name;
	end loop;
end;
/

-- *** Grants ***
grant select, insert, update, delete on csrimp.lookup_table to web_user;
grant select, insert, update, delete on csrimp.lookup_table_entry to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail

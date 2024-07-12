-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index cms.ix_imp_cons_cols_own_tab_col on cms.imp_cons_columns (owner, table_name, column_name);
create index cms.ix_imp_cons_own_cons on cms.imp_constraints (owner, constraint_name);
create index cms.ix_imp_cons_r_own_r_cons on cms.imp_constraints (r_owner, r_constraint_name);
drop table csrimp.temp_sheet_history;
drop table csrimp.temp_sheet_value;
drop table csrimp.temp_imp_set_val;

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

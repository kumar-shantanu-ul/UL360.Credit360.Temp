-- Please update version.sql too -- this keeps clean builds in sync
define version=3049
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='TEMP_DELEGATION_USER';
	if v_exists = 0 then
		execute immediate 'create global temporary table csr.temp_delegation_user (delegation_sid number(10), user_sid number(10)) on commit delete rows';
	end if;
end;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../delegation_body

@update_tail

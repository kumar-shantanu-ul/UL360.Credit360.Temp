-- Please update version.sql too -- this keeps clean builds in sync
define version=3134
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
declare
	v_exists	number;
begin
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='DB_CONFIG';
	if v_exists = 0 then
		execute immediate '
CREATE TABLE CSR.DB_CONFIG
(
	ONLY_ONE_ROW					NUMBER(1) DEFAULT 0 NOT NULL,
	BATCH_UDP_NOTIFY_COMMAND		VARCHAR2(4000), 
	BATCH_UDP_BROADCAST_ADDRESSES	VARCHAR2(4000),
	CONSTRAINT CK_DB_CONFIG_ONLY_ONE_ROW CHECK (only_one_row = 0),
	CONSTRAINT PK_DB_CONFIG PRIMARY KEY (ONLY_ONE_ROW)
)';
		execute immediate 'INSERT INTO CSR.DB_CONFIG (ONLY_ONE_ROW) VALUES (0)';
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

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../scenario_run_snapshot_pkg
@../scenario_run_snapshot_body

@update_tail

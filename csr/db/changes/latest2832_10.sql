-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
create table cms.oracle_tab
(
	oracle_schema	varchar2(30) not null,
	oracle_table	varchar2(30) not null,
	constraint pk_oracle_tab primary key (oracle_schema, oracle_table)
);

insert into cms.oracle_tab (oracle_schema, oracle_table)
	select distinct oracle_schema, oracle_table
	  from cms.tab;

alter table cms.tab add constraint fk_tab_oracle_tab foreign key 
(oracle_schema, oracle_table) references cms.oracle_tab (oracle_schema, oracle_table);

-- Alter tables

-- *** Grants ***
grant select, insert on cms.oracle_tab to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail

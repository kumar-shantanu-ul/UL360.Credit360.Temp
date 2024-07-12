-- Please update version.sql too -- this keeps clean builds in sync
define version=2881
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.lookup_table
(
	app_sid 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	lookup_id		NUMBER(10) NOT NULL,
	lookup_name		VARCHAR2(255) NOT NULL,
	constraint pk_lookup_table primary key (app_sid, lookup_id),
	constraint fk_lookup_table_customer foreign key (app_sid)
	references csr.customer (app_sid)
);

CREATE TABLE csr.lookup_table_entry
(
	app_sid 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	lookup_id		NUMBER(10) NOT NULL,
	start_dtm		DATE NOT NULL,
	val				NUMBER,
	constraint pk_lookup_table_entry primary key (app_sid, lookup_id, start_dtm),
	constraint fk_lookup_tab_ent_lookup_tab foreign key (app_sid, lookup_id)
	references csr.lookup_table (app_sid, lookup_id)
);

create index csr.ix_lookup_tab_entry_lookup_id on csr.lookup_table_entry (app_sid, lookup_id);

CREATE TABLE CSRIMP.LOOKUP_TABLE
(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_ID						NUMBER(10) NOT NULL,
	LOOKUP_NAME						VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_LOOKUP_TABLE PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_ID)
);

CREATE TABLE CSRIMP.LOOKUP_TABLE_ENTRY
(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_ID						NUMBER(10) NOT NULL,
	START_DTM						DATE NOT NULL,
	VAL								NUMBER,
	CONSTRAINT PK_LOOKUP_TABLE_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_ID, START_DTM)
);

-- Alter tables

-- *** Grants ***
grant insert on csr.lookup_table to csrimp;
grant insert on csr.lookup_table_entry to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../schema_body
@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../csrimp/imp_body
@../calc_body
@../csr_app_body

@update_tail

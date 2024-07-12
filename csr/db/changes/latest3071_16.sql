-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.schema_table (
	owner							VARCHAR2(30),
	table_name						VARCHAR2(30),
	enable_export					NUMBER(1) DEFAULT 1,
	enable_import					NUMBER(1) DEFAULT 1,
	csrimp_table_name				VARCHAR2(30) NULL,
	module_name						VARCHAR2(255) NULL,
    CONSTRAINT pk_schema_table		PRIMARY KEY (owner, table_name),
	CONSTRAINT ck_schema_table_uc	CHECK (owner = UPPER(owner) AND table_name = UPPER(table_name)),
	CONSTRAINT ck_schema_table_mod	CHECK (LOWER(module_name) NOT IN ('all', 'none'))
);

CREATE TABLE csr.schema_column (
	owner							VARCHAR2(30),
	table_name						VARCHAR2(30),
	column_name						VARCHAR2(30),
	enable_export					NUMBER(1) DEFAULT 1,
	enable_import					NUMBER(1) DEFAULT 1,
	is_map_source					NUMBER(1) DEFAULT 1,	-- save work by clearing this on non-pk tables
	is_sid							NUMBER(1) NULL,			-- NULL = guess from name 
	sequence_owner					VARCHAR2(30) NULL,		-- NULL = same as table
	sequence_name					VARCHAR2(30) NULL,
	map_table						VARCHAR2(30) NULL,		-- only need these for legacy mapping tables
	map_old_id_col					VARCHAR2(30) NULL,
	map_new_id_col					VARCHAR2(30) NULL,
    CONSTRAINT pk_schema_column		PRIMARY KEY (owner, table_name, column_name),
	CONSTRAINT ck_schema_column_uc	CHECK (owner = UPPER(owner) AND 
										   table_name = UPPER(table_name) AND 
										   column_name = UPPER(column_name) AND
										   sequence_owner = UPPER(sequence_owner))
);

CREATE TABLE csrimp.map_id (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	sequence_owner					VARCHAR2(30),
	sequence_name					VARCHAR2(30),
	old_id							NUMBER(10),
	new_id							NUMBER(10),
	CONSTRAINT pk_map_id			PRIMARY KEY (csrimp_session_id, sequence_owner, sequence_name, old_id),
	CONSTRAINT uk_map_id 			UNIQUE (csrimp_session_id, sequence_name, new_id),
	CONSTRAINT fk_map_id 			FOREIGN KEY (csrimp_session_id) 
										REFERENCES csrimp.csrimp_session (csrimp_session_id) 
										ON DELETE CASCADE,
	CONSTRAINT ck_map_id_uc			CHECK (sequence_owner = UPPER(sequence_owner) AND
										   sequence_name = UPPER(sequence_name))
);

ALTER TABLE csr.schema_column ADD (
	CONSTRAINT fk_schem_column_table 
		FOREIGN KEY (owner, table_name) 
		REFERENCES csr.schema_table(owner, table_name)
);

-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.schema_column TO csrimp;
GRANT SELECT ON csr.schema_table TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../schema_pkg

@../csrimp/imp_body
@../schema_body

@update_tail

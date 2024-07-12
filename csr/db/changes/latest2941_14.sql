-- Please update version.sql too -- this keeps clean builds in sync
define version=2941
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE chain.import_source_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE SEQUENCE chain.dedupe_mapping_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE SEQUENCE chain.dedupe_rule_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

CREATE TABLE chain.import_source(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	import_source_id		NUMBER NOT NULL,
	name					VARCHAR2(255) NOT NULL,
	position				NUMBER NOT NULL,
	can_create				NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT pk_import_source PRIMARY KEY (app_sid, import_source_id),
	CONSTRAINT uc_import_source UNIQUE (app_sid, position) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT chk_can_create CHECK (can_create IN (0,1))
);

CREATE TABLE chain.dedupe_field(
	dedupe_field_id			NUMBER NOT NULL,
	oracle_table			VARCHAR2(30) NOT NULL,
	oracle_column			VARCHAR2(30) NOT NULL,
	description				VARCHAR2(64) NOT NULL,
	CONSTRAINT pk_dedupe_field PRIMARY KEY (dedupe_field_id),
	CONSTRAINT uc_dedupe_field UNIQUE (oracle_table, oracle_column)
);

CREATE TABLE chain.dedupe_mapping(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_mapping_id		NUMBER NOT NULL,
	import_source_id		NUMBER NOT NULL,
	tab_sid					NUMBER NOT NULL,
	col_sid					NUMBER NOT NULL,
	dedupe_field_id			NUMBER NULL,
	reference_lookup		VARCHAR2(255) NULL,
	CONSTRAINT pk_dedupe_mapping PRIMARY KEY (app_sid, dedupe_mapping_id),
	CONSTRAINT chk_dedupe_field_or_ref CHECK ((dedupe_field_id IS NULL AND reference_lookup IS NOT NULL) OR (dedupe_field_id IS NOT NULL AND reference_lookup IS NULL)),
	CONSTRAINT uc_dedupe_mapping_col UNIQUE (app_sid, import_source_id, tab_sid, col_sid)
);

CREATE TABLE chain.dedupe_rule(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_rule_id			NUMBER NOT NULL,
	import_source_id		NUMBER NOT NULL,
	position				NUMBER NOT NULL,
	CONSTRAINT pk_dedupe_rule PRIMARY KEY (app_sid, dedupe_rule_id),
	CONSTRAINT uc_dedupe_rule UNIQUE (app_sid, import_source_id, position) DEFERRABLE INITIALLY DEFERRED
);

CREATE TABLE chain.dedupe_rule_mapping(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	dedupe_rule_id			NUMBER NOT NULL,
	dedupe_mapping_id		NUMBER NOT NULL,
	is_fuzzy				NUMBER(1, 0) DEFAULT 0 NOT NULL,
	position				NUMBER NOT NULL,
	CONSTRAINT pk_dedupe_rule_mapping PRIMARY KEY (app_sid, dedupe_rule_id, dedupe_mapping_id),
	CONSTRAINT uc_dedupe_rule_mapping UNIQUE (app_sid, dedupe_rule_id, position) DEFERRABLE INITIALLY DEFERRED
);


--csrimp data tables
CREATE TABLE CSRIMP.CHAIN_IMPORT_SOURCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	CAN_CREATE NUMBER(1,0) NOT NULL,
	NAME VARCHAR2(255) NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_IMPORT_SOURCE PRIMARY KEY (CSRIMP_SESSION_ID, IMPORT_SOURCE_ID),
	CONSTRAINT FK_CHAIN_IMPORT_SOURCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_MAPPING_ID NUMBER NOT NULL,
	COL_SID NUMBER NOT NULL,
	DEDUPE_FIELD_ID NUMBER,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	REFERENCE_LOOKUP VARCHAR2(255),
	TAB_SID NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_MAPPING_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_MAPPING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_RULE_ID NUMBER NOT NULL,
	IMPORT_SOURCE_ID NUMBER NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_RULE PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_RULE_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_RULE_MAPPIN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_RULE_ID NUMBER NOT NULL,
	DEDUPE_MAPPING_ID NUMBER NOT NULL,
	IS_FUZZY NUMBER(1,0) NOT NULL,
	POSITION NUMBER NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_RULE_MAPPIN PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_RULE_ID, DEDUPE_MAPPING_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_RULE_MAPPIN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Csrimp Map tables
CREATE TABLE CSRIMP.MAP_CHAIN_IMPORT_SOURCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	NEW_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_IMPORT_SOURCE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_IMPORT_SOURCE UNIQUE (CSRIMP_SESSION_ID, NEW_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_IMPORT_SOURCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MAPPING UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MAPPING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_IS
	FOREIGN KEY (app_sid, import_source_id)
	REFERENCES chain.import_source(app_sid, import_source_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_FIELD
	FOREIGN KEY (dedupe_field_id)
	REFERENCES chain.dedupe_field(dedupe_field_id);
	
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT FK_DEDUPE_MAPPING_COL
	FOREIGN KEY (app_sid, col_sid, tab_sid)
	REFERENCES cms.tab_column(app_sid, column_sid, tab_sid);

ALTER TABLE chain.dedupe_rule ADD CONSTRAINT FK_DEDUPE_RULE_IMPORT_SOURCE
	FOREIGN KEY (app_sid, import_source_id)
	REFERENCES chain.import_source(app_sid, import_source_id);
	
ALTER TABLE chain.dedupe_rule_mapping ADD CONSTRAINT FK_DEDUPE_RULE_MAPPING_RULE
	FOREIGN KEY (app_sid, dedupe_rule_id)
	REFERENCES chain.dedupe_rule(app_sid, dedupe_rule_id);
	
ALTER TABLE chain.dedupe_rule_mapping ADD CONSTRAINT FK_DEDUPE_RULE_MAPPING_MAP
	FOREIGN KEY (app_sid, dedupe_mapping_id)
	REFERENCES chain.dedupe_mapping(app_sid, dedupe_mapping_id);


-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_import_source to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_mapping to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_rule to web_user;
grant select, insert, update, delete on csrimp.chain_dedupe_rule_mappin to web_user;


grant select, insert, update on chain.import_source to csrimp;
grant select, insert, update on chain.dedupe_mapping to csrimp;
grant select, insert, update on chain.dedupe_rule to csrimp;
grant select, insert, update on chain.dedupe_rule_mapping to csrimp;

grant select on chain.import_source_id_seq to csrimp;
grant select on chain.import_source_id_seq to CSR;
grant select on chain.dedupe_mapping_id_seq to csrimp;
grant select on chain.dedupe_mapping_id_seq to CSR;
grant select on chain.dedupe_rule_id_seq to csrimp;
grant select on chain.dedupe_rule_id_seq to CSR;

grant select, insert, update on chain.import_source to CSR;
grant select, insert, update on chain.dedupe_mapping to CSR;
grant select, insert, update on chain.dedupe_rule to CSR;
grant select, insert, update on chain.dedupe_rule_mapping to CSR;

grant select on chain.import_source_id_seq to CSR;
grant select on chain.dedupe_mapping_id_seq to CSR;
grant select on chain.dedupe_rule_id_seq to CSR;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	--company table
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (1, 'COMPANY', 'NAME', 'Company name');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (2, 'COMPANY', 'PARENT_SID', 'Parent company');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (3, 'COMPANY', 'COMPANY_TYPE_ID', 'Company type');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (4, 'COMPANY', 'CREATED_DTM', 'Created date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (5, 'COMPANY', 'ACTIVATED_DTM', 'Activated date');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (6, 'COMPANY', 'ACTIVE', 'Active');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (7, 'COMPANY', 'ADDRESS', 'Address');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (8, 'COMPANY', 'STATE', 'State');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (9, 'COMPANY', 'POSTCODE', 'Postcode');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (10, 'COMPANY', 'COUNTRY_CODE', 'Country');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (11, 'COMPANY', 'PHONE', 'Phone');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (12, 'COMPANY', 'FAX', 'Fax');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (13, 'COMPANY', 'WEBSITE', 'Website');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (14, 'COMPANY', 'EMAIL', 'Email');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (15, 'COMPANY', 'DELETED', 'Deleted');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (16, 'COMPANY', 'SECTOR_ID', 'Sector');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (17, 'COMPANY', 'CITY', 'City');
	INSERT INTO chain.dedupe_field(dedupe_field_id, oracle_table, oracle_column, description) VALUES (18, 'COMPANY', 'DEACTIVATED_DTM', 'Deactivated date');
END;
/

-- ** New package grants **
create or replace package chain.company_dedupe_pkg as
procedure dummy;
end;
/
create or replace package body chain.company_dedupe_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON chain.company_dedupe_pkg TO web_user;
GRANT EXECUTE ON chain.company_dedupe_pkg TO csr; --needed for csrApp

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../chain/company_dedupe_pkg

@../schema_body
@../chain/company_dedupe_body
@../csrimp/imp_body

@update_tail

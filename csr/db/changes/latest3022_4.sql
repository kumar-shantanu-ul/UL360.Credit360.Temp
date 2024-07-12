-- Please update version.sql too -- this keeps clean builds in sync
define version=3022
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CHAIN.DEDUPE_PREPROC_RULE_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;
CREATE TABLE CHAIN.DEDUPE_PREPROC_COMP (
	APP_SID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPANY_SID 			NUMBER(10) NOT NULL,
	NAME 					VARCHAR2(255) NOT NULL,
	ADDRESS 				VARCHAR2(1024),
	CITY	 				VARCHAR2(255),
	STATE 					VARCHAR2(255),
	POSTCODE 				VARCHAR2(255),
	WEBSITE 				VARCHAR2(1000),
	PHONE					VARCHAR2(255),
	EMAIL_DOMAIN 			VARCHAR2(255),
	UPDATED_DTM 			DATE,
	CONSTRAINT PK_DEDUPE_PREPROC_COMP PRIMARY KEY (APP_SID, COMPANY_SID)
);

ALTER TABLE CHAIN.DEDUPE_PREPROC_COMP ADD CONSTRAINT COMPANY_DEDUPE_PREPROC_COMP 
	FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CHAIN.COMPANY (APP_SID,COMPANY_SID);
	
CREATE TABLE CHAIN.DEDUPE_PREPROC_RULE (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PREPROC_RULE_ID 		NUMBER(10) NOT NULL,
	PATTERN 					VARCHAR2(1000) NOT NULL,
	REPLACEMENT 				VARCHAR2(1000),
	RUN_ORDER 					NUMBER(10) NOT NULL,
	CONSTRAINT UC_DEDUPE_PREPROC_RULE UNIQUE (APP_SID, RUN_ORDER) DEFERRABLE INITIALLY DEFERRED,
	CONSTRAINT CHK_DP_PP_RULE_PATT_REP CHECK (PATTERN <> REPLACEMENT),
	CONSTRAINT PK_DEDUPE_PREPROC_RULE PRIMARY KEY (APP_SID, DEDUPE_PREPROC_RULE_ID)
);

ALTER TABLE CHAIN.DEDUPE_PREPROC_RULE ADD CONSTRAINT REF_DEDUPE_PREPROCESS_RULE_APP
	FOREIGN KEY (APP_SID)
	REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

CREATE TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY (
	APP_SID 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	DEDUPE_PREPROC_RULE_ID 		NUMBER(10) NOT NULL,
	DEDUPE_FIELD_ID 			NUMBER(10),
	COUNTRY_CODE				VARCHAR2(2),
	CONSTRAINT UC_DEDUPE_PP_FIELD_CNTRY UNIQUE (APP_SID, DEDUPE_PREPROC_RULE_ID, DEDUPE_FIELD_ID, COUNTRY_CODE)
);

ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT DD_PP_RULE_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (APP_SID, DEDUPE_PREPROC_RULE_ID) REFERENCES CHAIN.DEDUPE_PREPROC_RULE (APP_SID,DEDUPE_PREPROC_RULE_ID);

ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT DD_FIELD_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (DEDUPE_FIELD_ID) REFERENCES CHAIN.DEDUPE_FIELD (DEDUPE_FIELD_ID);

ALTER TABLE CHAIN.DEDUPE_PP_FIELD_CNTRY ADD CONSTRAINT COUNTRY_DD_PP_FIELD_CNTRY 
	FOREIGN KEY (COUNTRY_CODE) REFERENCES POSTCODE.COUNTRY (COUNTRY);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_PREPRO_COMP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	ADDRESS VARCHAR2(1024),
	CITY VARCHAR2(255),
	NAME VARCHAR2(255) NOT NULL,
	POSTCODE VARCHAR2(255),
	STATE VARCHAR2(255),
	WEBSITE VARCHAR2(1000),
	PHONE VARCHAR2(255),
	EMAIL_DOMAIN VARCHAR2(255),
	UPDATED_DTM DATE,
	CONSTRAINT PK_CHAIN_DEDUPE_PREPRO_COMP PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID),
	CONSTRAINT FK_CHAIN_DEDUPE_PREPRO_COMP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDUPE_PREPRO_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DEDUPE_PREPROC_RULE_ID NUMBER(10,0) NOT NULL,
	PATTERN VARCHAR2(1000) NOT NULL,
	REPLACEMENT VARCHAR2(1000),
	RUN_ORDER NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_DEDUPE_PREPRO_RULE PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_PREPROC_RULE_ID),
	CONSTRAINT FK_CHAIN_DEDUPE_PREPRO_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_DEDU_PP_FIEL_CNTRY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COUNTRY_CODE VARCHAR2(2),
	DEDUPE_FIELD_ID NUMBER(10,0),
	DEDUPE_PREPROC_RULE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT FK_CHAIN_DEDU_PP_FIEL_CNTRY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PREP_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PREP_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PREP_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PREP_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.customer_options ADD enable_dedupe_preprocess NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_co_enable_preprocess CHECK (enable_dedupe_preprocess IN (0,1));

ALTER TABLE csrimp.chain_customer_options ADD enable_dedupe_preprocess NUMBER(1);
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_co_enable_preprocess CHECK (enable_dedupe_preprocess IN (0,1));

create index chain.ix_dedupe_pp_fld_country_field on chain.dedupe_pp_field_cntry (dedupe_field_id);
create index chain.ix_dedupe_pp_fld_country_count on chain.dedupe_pp_field_cntry (country_code);

BEGIN
	DBMS_SCHEDULER.CREATE_JOB (
		job_name        => 'chain.DedupePreprocessing',
		job_type        => 'PLSQL_BLOCK',
		job_action      => 'chain.dedupe_preprocess_pkg.RunPreprocessJob;',
		job_class       => 'low_priority_job',
		start_date      => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval => 'FREQ=HOURLY;',
		enabled         => TRUE,
		auto_drop       => FALSE,
		comments        => 'Create Dedupe preprocessing batch job');
END;
/
	
-- *** Grants ***
-- Package grants
grant select, insert, update, delete on csrimp.chain_dedupe_prepro_comp to tool_user;
grant select, insert, update, delete on csrimp.chain_dedupe_prepro_rule to tool_user;
grant select, insert, update, delete on csrimp.chain_dedu_pp_fiel_cntry to tool_user;

-- grants for csrimp
grant select, insert, update on chain.dedupe_preproc_comp to csrimp;
grant select, insert, update on chain.dedupe_preproc_rule to csrimp;
grant select, insert, update on chain.dedupe_pp_field_cntry to csrimp;

-- sequence grants
grant select on chain.dedupe_preproc_rule_id_seq to csrimp;
grant select on chain.dedupe_preproc_rule_id_seq to CSR;

-- non csrimp grants
grant select, insert, update on chain.dedupe_preproc_comp to CSR;
grant select, insert, update on chain.dedupe_preproc_rule to CSR;
grant select, insert, update on chain.dedupe_pp_field_cntry to CSR;

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE chain.dedupe_admin_pkg as
	PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY chain.dedupe_admin_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/

CREATE OR REPLACE PACKAGE chain.dedupe_helper_pkg as
	PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY chain.dedupe_helper_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/

CREATE OR REPLACE PACKAGE chain.dedupe_preprocess_pkg as
	PROCEDURE dummy;
END;
/

CREATE OR REPLACE PACKAGE BODY chain.dedupe_preprocess_pkg as
	PROCEDURE dummy
	AS
	BEGIN
		null;
	END;
END;
/

GRANT EXECUTE ON chain.dedupe_admin_pkg TO web_user;
-- *** Conditional Packages ***

-- *** Packages ***
@../chain/helper_pkg
@../chain/company_type_pkg
@../chain/dedupe_admin_pkg
@../chain/dedupe_helper_pkg
@../chain/dedupe_preprocess_pkg
@../chain/company_dedupe_pkg
@../schema_pkg

@../chain/helper_body
@../chain/chain_body
@../chain/company_type_body
@../chain/company_body
@../chain/dedupe_admin_body
@../chain/company_dedupe_body
@../chain/dedupe_helper_body
@../chain/dedupe_preprocess_body
@../chain/test_chain_utils_body
@../schema_body
@../imp_body


@update_tail

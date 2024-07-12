-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=39
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.dedupe_sub (
    dedupe_sub_id		NUMBER(10) NOT NULL,
    app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	pattern            	VARCHAR2(1000) NOT NULL, 
	substitution        VARCHAR2(1000) NOT NULL, 
	proc_pattern        VARCHAR2(1000), 
	proc_substitution   VARCHAR2(1000), 
	updated_dtm         DATE,
    CONSTRAINT pk_dedupe_sub PRIMARY KEY (dedupe_sub_id)
);

COMMENT ON TABLE chain.dedupe_sub IS 'desc="Deduplication CMS table for holding alternative strings for matching"';
COMMENT ON COLUMN chain.dedupe_sub.app_sid IS 'app';
COMMENT ON COLUMN chain.dedupe_sub.dedupe_sub_id IS 'desc="Id",auto';
COMMENT ON COLUMN chain.dedupe_sub.pattern IS 'desc="Pattern"';
COMMENT ON COLUMN chain.dedupe_sub.substitution IS 'desc="Substitution"';
COMMENT ON COLUMN chain.dedupe_sub.proc_pattern IS 'desc="Pre-processed pattern"';
COMMENT ON COLUMN chain.dedupe_sub.proc_substitution IS 'desc="Pre-processed substitution"';
COMMENT ON COLUMN chain.dedupe_sub.updated_dtm iS 'desc="Updated date"';

CREATE TABLE CSRIMP.CHAIN_DEDUPE_SUB (
    CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DEDUPE_SUB_ID NUMBER(10) NOT NULL,
    PATTERN VARCHAR2(1000) NOT NULL,
    SUBSTITUTION VARCHAR2(1000) NOT NULL,
    PROC_PATTERN VARCHAR2(1000),
    PROC_SUBSTITUTION VARCHAR2(1000),
    UPDATED_DTM DATE,
    CONSTRAINT PK_CHAIN_DEDUPE_SUB PRIMARY KEY (CSRIMP_SESSION_ID, DEDUPE_SUB_ID),
    CONSTRAINT FK_CHAIN_DEDUPE_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_SUB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_SUB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_SUB UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE chain.dedupe_sub ADD CONSTRAINT fk_cust_opt_dedupe_sub
    FOREIGN KEY (app_sid)
    REFERENCES chain.customer_options(app_sid);

CREATE UNIQUE INDEX uk_dedupe_sub_patt_sub ON chain.dedupe_sub (app_sid, LOWER(TRIM(pattern)), LOWER(TRIM(substitution)));

-- *** Grants ***
GRANT SELECT ON chain.dedupe_sub TO csr;
GRANT SELECT, INSERT, UPDATE on chain.dedupe_sub TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_dedupe_sub TO tool_user;

-- ** Cross schema constraints ***


-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS


-- Data
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (92, 'Chain Company Dedupe', 'EnableCompanyDedupePreProc', 'Enables the preprocessing job and the registers the city substituion CMS table for Chain company deduplication.');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body
@../chain/chain_body
@../chain/dedupe_admin_pkg
@../chain/dedupe_admin_body
@../chain/dedupe_preprocess_pkg
@../chain/dedupe_preprocess_body
@../chain/company_dedupe_pkg
@../chain/company_dedupe_body
@../csrimp/imp_body
@../schema_pkg
@../schema_body

@update_tail

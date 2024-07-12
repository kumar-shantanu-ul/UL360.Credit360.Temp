-- Please update version.sql too -- this keeps clean builds in sync
define version=3060
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.pend_company_suggested_match (
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	pending_company_sid 		NUMBER(10) NOT NULL,
	matched_company_sid			NUMBER(10) NOT NULL,
	dedupe_rule_set_id			NUMBER(10) NULL,
	CONSTRAINT pk_pend_company_suggestd_match PRIMARY KEY (app_sid, pending_company_sid, matched_company_sid)
);

ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT chk_pend_company_matched_ne 
	CHECK (pending_company_sid != matched_company_sid);
		
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_company_sugg_match
	FOREIGN KEY (app_sid, pending_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_matched_company
	FOREIGN KEY (app_sid, matched_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_rule_set_id
	FOREIGN KEY (app_sid, dedupe_rule_set_id) REFERENCES chain.dedupe_rule_set (app_sid, dedupe_rule_set_id);

CREATE TABLE chain.pending_company_tag(
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	pending_company_sid			NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_pending_company_tag PRIMARY KEY (app_sid, pending_company_sid, tag_id)
);
		
ALTER TABLE chain.pending_company_tag ADD CONSTRAINT fk_pend_company_tag_comp
	FOREIGN KEY (app_sid, pending_company_sid) REFERENCES chain.company (app_sid, company_sid);

CREATE TABLE csrimp.chain_pend_cmpny_suggstd_match (
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	pending_company_sid			NUMBER(10) NOT NULL,
	matched_company_sid			NUMBER(10) NOT NULL,
	dedupe_rule_set_id			NUMBER(10) NULL,
	CONSTRAINT pk_pend_cmpny_suggstd_match PRIMARY KEY (csrimp_session_id, pending_company_sid, matched_company_sid),
	CONSTRAINT fk_pend_cmpny_suggstd_match_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

ALTER TABLE csrimp.chain_pend_cmpny_suggstd_match ADD CONSTRAINT chk_pend_company_matched_ne 
	CHECK (pending_company_sid != matched_company_sid);

CREATE TABLE csrimp.chain_pending_company_tag(
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	pending_company_sid 		NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_chain_pending_company_tag PRIMARY KEY (csrimp_session_id, pending_company_sid, tag_id),
	CONSTRAINT fk_chain_pending_cmpny_tag_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
	
-- Alter tables
ALTER TABLE chain.dedupe_staging_link ADD is_owned_by_system NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_staging_link MODIFY staging_tab_sid NULL;
ALTER TABLE chain.dedupe_staging_link MODIFY staging_id_col_sid NULL;

ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT chk_is_owned_by_system_st CHECK (is_owned_by_system IN (0,1));
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT chk_system_tab_col 
	CHECK ((is_owned_by_system = 0 AND staging_tab_sid IS NOT NULL AND staging_id_col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND staging_tab_sid IS NULL AND staging_id_col_sid IS NULL));

CREATE UNIQUE INDEX chain.uk_staging_system_owned ON chain.dedupe_staging_link (CASE WHEN is_owned_by_system = 1 THEN app_sid END);

ALTER TABLE csrimp.chain_dedupe_stagin_link ADD is_owned_by_system NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_stagin_link MODIFY staging_tab_sid NULL;
ALTER TABLE csrimp.chain_dedupe_stagin_link MODIFY staging_id_col_sid NULL;

ALTER TABLE csrimp.chain_dedupe_stagin_link ADD CONSTRAINT chk_is_owned_by_system_st CHECK (is_owned_by_system IN (0,1));
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD CONSTRAINT chk_system_tab_col 
	CHECK ((is_owned_by_system = 0 AND staging_tab_sid IS NOT NULL AND staging_id_col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND staging_tab_sid IS NULL AND staging_id_col_sid IS NULL));

ALTER TABLE chain.dedupe_mapping ADD is_owned_by_system NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_mapping MODIFY tab_sid NULL;
ALTER TABLE chain.dedupe_mapping MODIFY col_sid NULL;

ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_is_owned_by_system_map CHECK (is_owned_by_system IN (0,1));
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_system_mapping_tab_col 
	CHECK ((is_owned_by_system = 0 AND tab_sid IS NOT NULL AND col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND tab_sid IS NULL AND col_sid IS NULL));

ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT uc_dedupe_mapping_tab_col;
CREATE UNIQUE INDEX chain.uk_dedupe_mapping ON chain.dedupe_mapping (app_sid, dedupe_staging_link_id, tab_sid, CASE WHEN is_owned_by_system = 0 THEN col_sid ELSE dedupe_mapping_id END);

ALTER TABLE csrimp.chain_dedupe_mapping ADD is_owned_by_system NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_mapping MODIFY tab_sid NULL;
ALTER TABLE csrimp.chain_dedupe_mapping MODIFY col_sid NULL;

ALTER TABLE csrimp.chain_dedupe_mapping ADD CONSTRAINT chk_is_owned_by_system_map CHECK (is_owned_by_system IN (0,1));
ALTER TABLE csrimp.chain_dedupe_mapping ADD CONSTRAINT chk_system_mapping_tab_col 
	CHECK ((is_owned_by_system = 0 AND tab_sid IS NOT NULL AND col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND tab_sid IS NULL AND col_sid IS NULL));

ALTER TABLE chain.company ADD requested_by_company_sid	NUMBER(10);
ALTER TABLE chain.company ADD requested_by_user_sid		NUMBER(10);
ALTER TABLE chain.company ADD pending					NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE chain.company ADD CONSTRAINT chk_pending CHECK (pending IN (0,1));

ALTER TABLE chain.company ADD CONSTRAINT fk_company_request_by_company
	FOREIGN KEY (app_sid, requested_by_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
CREATE INDEX chain.ix_requested_by_company_sid ON chain.company (app_sid, requested_by_company_sid);
	
CREATE INDEX chain.ix_requested_by_user_sid ON chain.company (app_sid, requested_by_user_sid);

ALTER TABLE csrimp.chain_company ADD requested_by_company_sid	NUMBER(10);
ALTER TABLE csrimp.chain_company ADD requested_by_user_sid		NUMBER(10);
ALTER TABLE csrimp.chain_company ADD pending					NUMBER(1) NOT NULL;

ALTER TABLE csrimp.chain_company ADD CONSTRAINT chk_pending CHECK (pending IN (0,1));

ALTER TABLE chain.customer_options ADD enable_dedupe_onboarding NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_enable_dedupe_onboarding CHECK (enable_dedupe_onboarding IN (0,1));

ALTER TABLE csrimp.chain_customer_options ADD enable_dedupe_onboarding NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_enable_dedupe_onboarding CHECK (enable_dedupe_onboarding IN (0,1));

create index chain.ix_pending_compa_tag_id on chain.pending_company_tag (app_sid, tag_id);
create index chain.ix_pend_company__dedupe_rule_s on chain.pend_company_suggested_match (app_sid, dedupe_rule_set_id);
create index chain.ix_pend_company__matched_compa on chain.pend_company_suggested_match (app_sid, matched_company_sid);

-- *** Grants ***
grant select on chain.pend_company_suggested_match to csr;
grant select, insert, update on chain.pend_company_suggested_match to csrimp;
grant select, insert, update, delete on csrimp.chain_pend_cmpny_suggstd_match to tool_user;

grant select on chain.pending_company_tag to csr;
grant select, insert, update on chain.pending_company_tag to csrimp;
grant select, insert, update, delete on csrimp.chain_pending_company_tag to tool_user;

-- ** Cross schema constraints ***
	
ALTER TABLE chain.pending_company_tag ADD CONSTRAINT fk_pend_company_tag_tag
	FOREIGN KEY (app_sid, tag_id) REFERENCES csr.tag (app_sid, tag_id);

ALTER TABLE chain.company ADD CONSTRAINT fk_company_requested_by_user
	FOREIGN KEY (app_sid, requested_by_user_sid) REFERENCES csr.csr_user (app_sid, csr_user_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
BEGIN
	security.user_pkg.logonadmin(NULL);
	
	INSERT INTO chain.dedupe_staging_link (app_sid, dedupe_staging_link_id, import_source_id, 
		description, position, is_owned_by_system)
	SELECT app_sid, chain.dedupe_staging_link_id_seq.nextval, import_source_id,
		'System managed staging', 1, 1
	  FROM chain.import_source
	 WHERE is_owned_by_system = 1;
END;
/
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***
begin
	for r in (select * from all_objects where owner='CHAIN' and object_name='TEST_DEDUPE_MULTISOURCE_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package chain.test_dedupe_multisource_pkg';
	end loop;
end;
/
-- *** Packages ***
@../chain/dedupe_admin_pkg
@../chain/company_pkg
@../chain/company_dedupe_pkg
@../chain/helper_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../chain/dedupe_admin_body
@../chain/company_body
@../chain/company_dedupe_body
@../chain/helper_body
@../chain/setup_body
@../supplier_body
@../schema_body
@../csrimp/imp_body

@update_tail

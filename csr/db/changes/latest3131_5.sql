-- Please update version.sql too -- this keeps clean builds in sync
define version=3131
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
DROP TABLE csrimp.chain_suppl_relati_score CASCADE CONSTRAINTS;
DROP TABLE chain.supplier_relationship_score CASCADE CONSTRAINTS;

CREATE TABLE CHAIN.SUPPLIER_RELATIONSHIP_SCORE(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SUPPLIER_RELATIONSHIP_SCORE_ID	NUMBER(10, 0)	NOT NULL,
	PURCHASER_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	SUPPLIER_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SET_DTM							DATE			DEFAULT SYSDATE NOT NULL,
	SCORE							NUMBER(15, 5),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	CHANGED_BY_USER_SID 			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	COMMENT_TEXT           			CLOB,
	VALID_UNTIL_DTM        			DATE,
    SCORE_SOURCE_TYPE      			NUMBER(10),
    SCORE_SOURCE_ID        			NUMBER(10),
	IS_OVERRIDE						NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SUPPLIER_RELATIONHSIP_SCORE PRIMARY KEY (APP_SID, SUPPLIER_RELATIONSHIP_SCORE_ID),
	CONSTRAINT UK_SUPPLIER_RELATIONSHIP_SCORE UNIQUE (PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID, SET_DTM, IS_OVERRIDE),
	CONSTRAINT CHK_SUP_REL_SCORE_SET_DTM CHECK (SET_DTM = TRUNC(SET_DTM)),
	CONSTRAINT CHK_SUP_REL_SCORE_VLD_DTM CHECK (VALID_UNTIL_DTM = TRUNC(VALID_UNTIL_DTM)),
	CONSTRAINT CHK_IS_OVERRIDE CHECK (IS_OVERRIDE IN (0,1))
);
CREATE INDEX chain.ix_rel_score_purch_suppl ON chain.supplier_relationship_score (app_sid, purchaser_company_sid, supplier_company_sid);
CREATE INDEX chain.ix_rel_score_type ON chain.supplier_relationship_score (app_sid, score_type_id);
CREATE INDEX chain.ix_rel_score_csr_user ON chain.supplier_relationship_score (app_sid, changed_by_user_sid);
CREATE INDEX chain.ix_rel_score_threshold ON chain.supplier_relationship_score (app_sid, score_threshold_id);

CREATE TABLE CSRIMP.CHAIN_SUPPL_RELATI_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SUPPLIER_RELATIONSHIP_SCORE_ID	NUMBER(10, 0)	NOT NULL,
	PURCHASER_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	SUPPLIER_COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	SCORE_THRESHOLD_ID				NUMBER(10, 0),
	SET_DTM							DATE			DEFAULT SYSDATE NOT NULL,
	SCORE							NUMBER(15, 5),
	SCORE_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	CHANGED_BY_USER_SID 			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	COMMENT_TEXT           			CLOB,
	VALID_UNTIL_DTM        			DATE,
    SCORE_SOURCE_TYPE      			NUMBER(10),
    SCORE_SOURCE_ID        			NUMBER(10),	
	IS_OVERRIDE						NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_CHAIN_SUPPL_RELATI_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, SUPPLIER_RELATIONSHIP_SCORE_ID),
	CONSTRAINT FK_CHAIN_SUPPL_RELATI_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CHAIN.SUPPLIER_RELATIONSHIP_SCORE ADD CONSTRAINT FK_SUPPLIER_REL_SCORE_REL
	FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID)
	REFERENCES CHAIN.SUPPLIER_RELATIONSHIP (APP_SID, PURCHASER_COMPANY_SID, SUPPLIER_COMPANY_SID);
	
-- *** Grants ***
-- need to regrant as dropping / recreating
GRANT SELECT, INSERT, UPDATE ON chain.supplier_relationship_score TO csr;
GRANT SELECT, INSERT, UPDATE ON chain.supplier_relationship_score TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_suppl_relati_score TO tool_user;

-- for the grant
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score AS SELECT app_sid FROM chain.supplier_relationship_score;
GRANT SELECT, REFERENCES ON chain.v$current_sup_rel_score TO csr;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.SUPPLIER_RELATIONSHIP_SCORE ADD CONSTRAINT FK_SUP_REL_SCORE_TYPE 
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE(APP_SID, SCORE_TYPE_ID);

ALTER TABLE CHAIN.SUPPLIER_RELATIONSHIP_SCORE ADD CONSTRAINT FK_SUP_REL_SCORE_THRESH_ID 
	FOREIGN KEY (APP_SID, SCORE_THRESHOLD_ID)
	REFERENCES CSR.SCORE_THRESHOLD(APP_SID, SCORE_THRESHOLD_ID);
	
ALTER TABLE CHAIN.SUPPLIER_RELATIONSHIP_SCORE ADD CONSTRAINT FK_SUP_REL_CSR_USER 
	FOREIGN KEY (APP_SID, CHANGED_BY_USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);
	
-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$current_country_risk_level AS
	SELECT crl.app_sid, crl.country, rl.risk_level_id, rl.label, rl.lookup_key
	  FROM chain.country_risk_level crl
	  JOIN chain.risk_level rl ON rl.risk_level_id = crl.risk_level_id
	 WHERE crl.start_dtm <= SYSDATE
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.country_risk_level crl2
			 WHERE crl2.country = crl.country
			   AND crl2.start_dtm > crl.start_dtm
			   AND crl2.start_dtm <= SYSDATE
		);
		
-- csr/db/chain/create_views.sql
/***********************************************************************
	v$current_raw_sup_rel_score - the current non-overridden (raw) supplier relationship score
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_raw_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND (srs.valid_until_dtm IS NULL OR srs.valid_until_dtm > SYSDATE)
	   AND is_override = 0
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 0
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		);

-- csr/db/chain/create_views.sql
/***********************************************************************
	v$current_ovr_sup_rel_score - the current overridden supplier relationship score
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_ovr_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
	   AND (srs.valid_until_dtm IS NULL OR srs.valid_until_dtm > SYSDATE)
	   AND is_override = 1
	   AND NOT EXISTS (
			SELECT *
			  FROM chain.supplier_relationship_score srs2
			 WHERE srs.purchaser_company_sid = srs2.purchaser_company_sid
			   AND srs.supplier_company_sid = srs2.supplier_company_sid
			   AND srs.score_type_id = srs2.score_type_id
			   AND is_override = 1
			   AND srs2.set_dtm > srs.set_dtm
			   AND srs2.set_dtm <= SYSDATE
		);
		
-- csr/db/chain/create_views.sql
/***********************************************************************
	v$current_sup_rel_score_all - the current raw supplier relationship score and corresponding overrides
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score_all AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   MAX(supplier_relationship_score_id) raw_sup_relationship_score_id, 
		   MAX(score_threshold_id) raw_score_threshold_id, 
		   MAX(score) raw_score, 
		   MAX(set_dtm) raw_set_dtm, 
		   MAX(valid_until_dtm) raw_valid_until_dtm, 
		   MAX(changed_by_user_sid) raw_changed_by_user_sid, 
		   MAX(score_source_type) raw_score_source_type, 
		   MAX(score_source_id) raw_score_source_id, 
		   --
		   MAX(ovr_sup_relationship_score_id) ovr_sup_relationship_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id
	  FROM (
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, 
				   --
				   NULL ovr_sup_relationship_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id
			  FROM chain.v$current_raw_sup_rel_score
			  UNION ALL
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   NULL supplier_relationship_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, 
				   --
				   supplier_relationship_score_id ovr_sup_relationship_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override, set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, 
				   changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, score_source_id ovr_score_source_id
			  FROM chain.v$current_ovr_sup_rel_score
	)
	GROUP BY supplier_company_sid, purchaser_company_sid, score_type_id; 

-- csr/db/chain/create_views.sql
/***********************************************************************
	v$current_sup_rel_score - the current supplier relationship score - returns overridden if set / raw if not
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$current_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   --
		   NVL(ovr_score_threshold_id, raw_score_threshold_id) score_threshold_id, 
		   NVL(ovr_score, raw_score) score, 
		   NVL2(ovr_score_threshold_id, ovr_set_dtm, raw_set_dtm) set_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_valid_until_dtm, raw_valid_until_dtm) valid_until_dtm, 
		   NVL2(ovr_score_threshold_id, ovr_changed_by_user_sid, raw_changed_by_user_sid) changed_by_user_sid, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_type, raw_score_source_type) score_source_type, 
		   NVL2(ovr_score_threshold_id, ovr_score_source_id, raw_score_source_id) score_source_id
	  FROM v$current_sup_rel_score_all;
	  
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../supplier_pkg
@../chain/company_pkg
@../chain/chain_link_pkg

@../schema_body
@../supplier_body

@../chain/company_body
@../chain/chain_link_body
@../chain/helper_body
@../chain/company_filter_body

@../csrimp/imp_body

@update_tail

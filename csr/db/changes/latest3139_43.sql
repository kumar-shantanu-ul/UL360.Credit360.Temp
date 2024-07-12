-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=43
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- add new score display options
ALTER TABLE csr.score_type ADD show_expired_scores NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.score_type ADD CONSTRAINT chk_score_type_show_exp CHECK (show_expired_scores IN (0, 1));

ALTER TABLE csrimp.score_type ADD show_expired_scores NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.score_type ADD CONSTRAINT chk_score_type_show_exp CHECK (show_expired_scores IN (0, 1));

-- the new default behaviour is not the existing behaviour - so turn this option "on" for all existing systems
UPDATE csr.score_type SET show_expired_scores = 1;

ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT chk_sup_rel_dtm_valid CHECK ((valid_until_dtm IS NULL) OR (set_dtm <= valid_until_dtm));
ALTER TABLE chain.supplier_relationship_score DROP CONSTRAINT uk_supplier_relationship_score;
ALTER TABLE chain.supplier_relationship_score ADD CONSTRAINT uk_supplier_relationship_score UNIQUE (purchaser_company_sid, supplier_company_sid, score_type_id, set_dtm, is_override);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
	 
CREATE OR REPLACE VIEW chain.v$current_raw_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
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
		)
;

CREATE OR REPLACE VIEW chain.v$current_ovr_sup_rel_score AS
	SELECT 
		   supplier_company_sid, purchaser_company_sid, score_type_id, 
		   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
		   comment_text, changed_by_user_sid, score_source_type, score_source_id, 
		   CASE WHEN valid_until_dtm IS NULL OR valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid
	  FROM chain.supplier_relationship_score srs
	 WHERE srs.set_dtm <= SYSDATE
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
		)
;

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
		   MAX(valid) raw_valid, 
		   --
		   MAX(ovr_sup_relationship_score_id) ovr_sup_relationship_score_id, 
		   MAX(ovr_score_threshold_id) ovr_score_threshold_id, 
		   MAX(ovr_score) ovr_score, 
		   MAX(ovr_set_dtm) ovr_set_dtm, 
		   MAX(ovr_valid_until_dtm) ovr_valid_until_dtm,  
		   MAX(ovr_changed_by_user_sid) ovr_changed_by_user_sid, 
		   MAX(ovr_score_source_type) ovr_score_source_type, 
		   MAX(ovr_score_source_id) ovr_score_source_id, 
		   MAX(valid) ovr_valid
	  FROM (
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   supplier_relationship_score_id, score_threshold_id, score, is_override, set_dtm, valid_until_dtm, 
				   changed_by_user_sid, score_source_type, score_source_id, valid,
				   --
				   NULL ovr_sup_relationship_score_id, NULL ovr_score_threshold_id, NULL ovr_score, NULL ovr_is_override, NULL ovr_set_dtm, NULL ovr_valid_until_dtm, 
				   NULL ovr_changed_by_user_sid, NULL ovr_score_source_type, NULL ovr_score_source_id, NULL ovr_valid
			  FROM chain.v$current_raw_sup_rel_score
			  UNION ALL
			SELECT 
				   supplier_company_sid, purchaser_company_sid, score_type_id, 
				   --
				   NULL supplier_relationship_score_id, NULL score_threshold_id, score, NULL is_override, NULL set_dtm, NULL valid_until_dtm, 
				   NULL changed_by_user_sid, NULL score_source_type, NULL score_source_id, NULL valid,
				   --
				   supplier_relationship_score_id ovr_sup_relationship_score_id, score_threshold_id ovr_score_threshold_id, score ovr_score, is_override ovr_is_override, set_dtm ovr_set_dtm, valid_until_dtm ovr_valid_until_dtm, 
				   changed_by_user_sid ovr_changed_by_user_sid, score_source_type ovr_score_source_type, score_source_id ovr_score_source_id, valid ovr_valid
			  FROM chain.v$current_ovr_sup_rel_score
	)
	GROUP BY supplier_company_sid, purchaser_company_sid, score_type_id
; 

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
		   NVL2(ovr_score_threshold_id, ovr_score_source_id, raw_score_source_id) score_source_id, 
		   NVL2(ovr_score_threshold_id, ovr_valid, raw_valid) valid
	  FROM v$current_sup_rel_score_all
;

-- *** Data changes ***
-- RLS

-- Data


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/company_body.sql
@../chain/company_filter_body.sql

@../supplier_body.sql
@../schema_body.sql

@../csrimp/imp_body.sql


@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.supplier_score_log
  ADD score_source_type NUMBER(10);

ALTER TABLE csr.supplier_score_log
  ADD score_source_id NUMBER(10);

ALTER TABLE csrimp.supplier_score_log
  ADD score_source_type NUMBER(10);

ALTER TABLE csrimp.supplier_score_log
  ADD score_source_id NUMBER(10);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- c:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id,
		   ss.changed_by_user_sid, cu.full_name changed_by_user_full_name, ss.comment_text,
		   st.description score_threshold_description, t.label score_type_label, t.pos,
		   t.format_mask, ss.valid_until_dtm, CASE WHEN ss.valid_until_dtm IS NULL OR ss.valid_until_dtm >= SYSDATE THEN 1 ELSE 0 END valid,
		   ss.score_source_type, ss.score_source_id
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = ss.supplier_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id
	  LEFT JOIN csr.csr_user cu ON ss.changed_by_user_sid = cu.csr_user_sid;
	  
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg
@..\csr_data_body
@..\audit_helper_body
@..\campaign_body
@..\schema_body
@..\csrimp\imp_body
@..\supplier_pkg
@..\supplier_body

@update_tail

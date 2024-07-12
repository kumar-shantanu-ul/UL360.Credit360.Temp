-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- make period span pattern specific to period data exports, rather than being generic
ALTER TABLE csr.auto_exp_retrieval_dataview ADD (
	period_span_pattern_id				NUMBER(10, 0)
);

ALTER TABLE csr.auto_exp_retrieval_dataview
ADD CONSTRAINT fk_auto_exp_rdv_psp_id FOREIGN KEY (app_sid, period_span_pattern_id) REFERENCES csr.period_span_pattern(app_sid, period_span_pattern_id);

-- Move across existing settings
UPDATE csr.auto_exp_retrieval_dataview aerd
   SET aerd.period_span_pattern_id = (
		SELECT DISTINCT aec.period_span_pattern_id
		  FROM csr.automated_export_class aec
		 WHERE aerd.auto_exp_retrieval_dataview_id = aec.auto_exp_retrieval_dataview_id);

ALTER TABLE csr.auto_exp_retrieval_dataview MODIFY period_span_pattern_id NOT NULL;
CREATE INDEX csr.ix_auto_exp_rdv_period_span_p ON csr.auto_exp_retrieval_dataview (app_sid, period_span_pattern_id);

-- Drop the old column 
ALTER TABLE csr.automated_export_class DROP CONSTRAINT FK_AUTO_EXP_CL_PER_SPAN_PAT_ID;
ALTER TABLE csr.automated_export_class DROP COLUMN period_span_pattern_id;


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\automated_export_pkg
@..\automated_export_body

@update_tail

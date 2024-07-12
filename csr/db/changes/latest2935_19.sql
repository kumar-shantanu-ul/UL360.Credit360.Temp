-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.flow_transition_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.flow_transition_alert ADD CONSTRAINT chk_fta_can_be_edited CHECK (can_be_edited_before_sending IN (0,1));

ALTER TABLE csr.t_flow_trans_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.flow_item_generated_alert ADD subject_override CLOB NULL;
ALTER TABLE csr.flow_item_generated_alert ADD body_override CLOB NULL;

ALTER TABLE csrimp.flow_transition_alert ADD can_be_edited_before_sending NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csrimp.flow_item_generated_alert ADD subject_override CLOB NULL;
ALTER TABLE csrimp.flow_item_generated_alert ADD body_override CLOB NULL;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
--C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$flow_item_gen_alert AS
SELECT fta.flow_transition_alert_id, fta.customer_alert_type_id, fta.helper_sp,
	flsf.flow_state_id from_state_id, flsf.label from_state_label,
	flst.flow_state_id to_state_id, flst.label to_state_label, 
	fsl.flow_state_log_Id, fsl.set_dtm, fsl.set_by_user_sid, fsl.comment_text,
	cusb.full_name set_by_full_name, cusb.email set_by_email, cusb.user_name set_by_user_name, 
	cut.csr_user_sid to_user_sid, cut.full_name to_full_name,
	cut.email to_email, cut.user_name to_user_name, cut.friendly_name to_friendly_name,
	fi.app_sid, fi.flow_item_id, fi.flow_sid, fi.current_state_id,
	fi.survey_response_id, fi.dashboard_instance_id, fta.to_initiator, fta.flow_alert_helper,
	figa.to_column_sid, figa.flow_item_generated_alert_id, figa.processed_dtm, figa.created_dtm, 
	cat.is_batched, ftacc.alert_manager_flag, fta.flow_state_transition_id,
	figa.subject_override, figa.body_override, fta.can_be_edited_before_sending
  FROM flow_item_generated_alert figa 
  JOIN flow_state_log fsl ON figa.flow_state_log_id = fsl.flow_state_log_id AND figa.flow_item_id = fsl.flow_item_id AND figa.app_sid = fsl.app_sid
  JOIN csr_user cusb ON fsl.set_by_user_sid = cusb.csr_user_sid AND fsl.app_sid = cusb.app_sid 
  JOIN flow_item fi ON figa.flow_item_id = fi.flow_item_id AND figa.app_sid = fi.app_sid
  JOIN flow_transition_alert fta ON figa.flow_transition_alert_id = fta.flow_transition_alert_id AND figa.app_sid = fta.app_sid            
  JOIN flow_state_transition fst ON fta.flow_state_transition_id = fst.flow_state_transition_id AND fta.app_sid = fst.app_sid
  JOIN flow_state flsf ON fst.from_state_id = flsf.flow_state_id AND fst.app_sid = flsf.app_sid
  JOIN flow_state flst ON fst.to_state_id = flst.flow_state_id AND fst.app_sid = flst.app_sid
  LEFT JOIN cms_alert_type cat ON  fta.customer_alert_type_id = cat.customer_alert_type_id
  LEFT JOIN flow_transition_alert_cms_col ftacc ON figa.flow_transition_alert_id = ftacc.flow_transition_alert_id AND figa.to_column_sid = ftacc.column_sid
  LEFT JOIN csr_user cut ON figa.to_user_sid = cut.csr_user_sid AND figa.app_sid = cut.app_sid
 WHERE fta.deleted = 0;

--C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$open_flow_item_gen_alert AS
SELECT flow_transition_alert_id, customer_alert_type_id, helper_sp,
	from_state_id, from_state_label,
	to_state_id, to_state_label, 
	flow_state_log_Id, set_dtm, set_by_user_sid, comment_text,
	set_by_full_name, set_by_email, set_by_user_name, 
	to_user_sid, to_full_name,
	to_email, to_user_name, to_friendly_name,
	app_sid, flow_item_id, flow_sid, current_state_id,
	survey_response_id, dashboard_instance_id, to_initiator, flow_alert_helper,
	to_column_sid, flow_item_generated_alert_id,
	is_batched, alert_manager_flag, created_dtm, flow_state_transition_id,
	subject_override, body_override, can_be_edited_before_sending
  FROM csr.v$flow_item_gen_alert 
 WHERE processed_dtm IS NULL;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\flow_pkg
@..\audit_pkg
@..\chain\supplier_flow_pkg

@..\flow_body
@..\audit_body
@..\chain\supplier_flow_body
@..\schema_body
@..\csrimp\imp_body

@update_tail

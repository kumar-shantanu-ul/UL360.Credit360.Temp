-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.customer
  ADD tear_off_deleg_header NUMBER(1) NOT NULL;

ALTER TABLE csrimp.customer
  ADD deleg_dropdown_threshold NUMBER(10) NOT NULL;

ALTER TABLE csr.customer
  ADD user_picker_extra_fields VARCHAR2(255);

ALTER TABLE csrimp.customer
  ADD user_picker_extra_fields VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,                  -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title, csru.user_ref,  -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								              -- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0;

CREATE OR REPLACE VIEW CHAIN.v$company_user AS
	SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name,
		   vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,
		   vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		   vcu.account_enabled, vcu.user_ref
	  FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
	 WHERE cug.app_sid = vcu.app_sid
	   AND cug.user_group_sid = gm.group_sid_id
	   AND vcu.user_sid = gm.member_sid_id;
	 
-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.util_script (
	  util_script_id, util_script_name, description, util_script_sp, wiki_article
	) VALUES (
	  25, 'Set extra fields for user picker', 'Set the extra fields (email, user_name, user_ref) to be displayed in user picker.', 'SetUserPickerExtraFields', NULL
	);

	INSERT INTO csr.util_script_param (
	  util_script_id, param_name, param_hint, pos, param_value, param_hidden
	) VALUES (
	  25, 'Extra fields', 'Comma separated list of fields. Allowed fields are email, user_name and user_ref. Enter space to clear the extra fields.', 0, NULL, 0
	);
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.customer
	   SET user_picker_extra_fields = 'email'
	 WHERE user_picker_extra_fields IS NULL;
	 
	 security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_user_body
@..\customer_body
@..\schema_body
@..\csrimp\imp_body
@..\audit_body
@..\issue_body
@..\chain\company_user_body
@..\util_script_pkg
@..\util_script_body
@..\flow_pkg
@..\flow_body
@..\teamroom_pkg
@..\teamroom_body

@update_tail

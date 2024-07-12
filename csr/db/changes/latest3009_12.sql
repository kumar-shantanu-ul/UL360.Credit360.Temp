-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,                  -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title, csru.user_ref,  -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,	cu.default_company_sid, 	              -- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled, csru.send_alerts
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected
	   AND cu.registration_status_id <> 3 -- not merged
	   AND cu.deleted = 0;

CREATE OR REPLACE VIEW chain.v$company_user AS
	SELECT cug.app_sid, cug.company_sid, vcu.user_sid, vcu.email, vcu.user_name,
		   vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title,
		   vcu.visibility_id, vcu.registration_status_id, vcu.details_confirmed,
		   vcu.account_enabled, vcu.user_ref, vcu.default_company_sid
	  FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
	 WHERE cug.app_sid = vcu.app_sid
	   AND cug.user_group_sid = gm.group_sid_id
	   AND vcu.user_sid = gm.member_sid_id;
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\company_pkg
@..\chain\company_body
@..\chain\company_user_pkg
@..\chain\company_user_body

@update_tail

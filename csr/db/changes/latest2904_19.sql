-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.V$MY_USER AS
  SELECT ut.account_enabled, CASE WHEN cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END is_direct_report,
		 cu.app_sid, cu.csr_user_sid, cu.email, cu.guid, cu.full_name, cu.user_name,
		 cu.friendly_name, cu.info_xml, cu.send_alerts, cu.show_portal_help, cu.donations_reports_filter_id,
		 cu.donations_browse_filter_id, cu.hidden, cu.phone_number, cu.job_title, cu.show_save_chart_warning,
		 cu.enable_aria, cu.created_dtm, cu.line_manager_sid, cu.last_modified_dtm, cu.last_logon_type_id, cu.avatar,
		 cu.avatar_last_modified_dtm, cu.avatar_sha1, cu.avatar_mime_type, cu.primary_region_sid
    FROM csr.csr_user cu
    JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
   START WITH cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID')
  CONNECT BY PRIOR cu.csr_user_sid = cu.line_manager_sid;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

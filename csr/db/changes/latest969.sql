-- Please update version.sql too -- this keeps clean builds in sync
define version=969
@update_header

CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.region_mount_point_sid, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

@..\csr_user_pkg
@..\csr_user_body

@update_tail

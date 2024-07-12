-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
-- C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$delegation_hierarchical AS
	SELECT d.app_sid, d.delegation_sid, d.parent_sid, d.name, d.master_delegation_sid, d.created_by_sid, d.schedule_xml, d.note, d.group_by, d.allocate_users_to, d.start_dtm, d.end_dtm, d.reminder_offset, 
		   d.is_note_mandatory, d.section_xml, d.editing_url, d.fully_delegated, d.grid_xml, d.is_flag_mandatory, d.show_aggregate, d.hide_sheet_period, d.delegation_date_schedule_id, d.layout_id, 
		   d.tag_visibility_matrix_group_id, d.period_set_id, d.period_interval_id, d.submission_offset, d.allow_multi_period, NVL(dd.description, d.name) as description, dp.submit_confirmation_text,
		   d.lvl
	  FROM (
		SELECT app_sid, delegation_sid, parent_sid, name, master_delegation_sid, created_by_sid, schedule_xml, note, group_by, allocate_users_to, start_dtm, end_dtm, reminder_offset, 
			   is_note_mandatory, section_xml, editing_url, fully_delegated, grid_xml, is_flag_mandatory, show_aggregate, hide_sheet_period, delegation_date_schedule_id, layout_id, 
			   tag_visibility_matrix_group_id, period_set_id, period_interval_id, submission_offset, allow_multi_period, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid, LEVEL lvl
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.app_sid = d.app_sid 
	   AND dd.delegation_sid = d.delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../sheet_body
@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1523
@update_header

--
-- PLEASE SVN UP c:\cvs\aspen2\db\ FIRST
--

-- redo the view to include flow_item_id
CREATE OR REPLACE VIEW csr.v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, s.flow_item_id, s.current_route_step_id,
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, s.help_text, REF, plugin, plugin_config, section_status_sid, further_info_url
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

@..\..\..\aspen2\db\utils_pkg
@..\..\..\aspen2\db\utils_body
@..\section_pkg
@..\section_body

@update_tail
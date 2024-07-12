-- Please update version.sql too -- this keeps clean builds in sync
define version=283
@update_header

CREATE OR REPLACE VIEW v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, 
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, REF, plugin, plugin_config, section_status_sid, further_info_url
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

	   	 
@..\text\section_root_pkg
@..\text\section_root_body
	   	 
drop package clone_section_pkg;	   	 
	   	 
@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=156
@update_header


CREATE VIEW v$checked_out_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, checked_out_dtm, csr_root_sid, section_position, active, module_root_sid, title_only  
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.checked_out_version_number = sv.version_number;

CREATE VIEW v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, checked_out_dtm, csr_root_sid, section_position, active, module_root_sid, title_only  
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;


@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2064
@update_header

ALTER TABLE CSR.SECTION ADD (
	PREVIOUS_SECTION_SID	NUMBER(10, 0)
);

ALTER TABLE CSR.SECTION_MODULE ADD (
	PREVIOUS_MODULE_SID		NUMBER(10, 0)
);

CREATE UNIQUE INDEX CSR.AK_SECTION_MODULE ON CSR.SECTION_MODULE(MODULE_ROOT_SID)
;

ALTER TABLE CSR.SECTION ADD CONSTRAINT CK_PREVIOUS_SECTION_SID 
    FOREIGN KEY (APP_SID, PREVIOUS_SECTION_SID)
    REFERENCES CSR.SECTION(APP_SID, SECTION_SID)
;

ALTER TABLE CSR.SECTION_MODULE ADD CONSTRAINT CK_PREVIOUS_MODULE_SID 
    FOREIGN KEY (APP_SID, PREVIOUS_MODULE_SID)
    REFERENCES CSR.SECTION_MODULE(APP_SID, MODULE_ROOT_SID)
;

UPDATE CSR.SECTION SET PREVIOUS_SECTION_SID = COPIED_FROM_SECTION_SID;

COMMIT;

ALTER TABLE CSR.SECTION DROP COLUMN COPIED_FROM_SECTION_SID; 

CREATE OR REPLACE VIEW csr.v$visible_version AS
	SELECT s.section_sid, s.parent_sid, sv.version_number, sv.title, sv.body, s.checked_out_to_sid, s.checked_out_dtm, s.flow_item_id, s.current_route_step_id, s.is_split,
		   s.app_sid, s.section_position, s.active, s.module_root_sid, s.title_only, s.help_text, REF, plugin, plugin_config, section_status_sid, further_info_url,
		   s.previous_section_sid
	  FROM section s, section_version sv
	 WHERE s.section_sid = sv.section_sid
	   AND s.visible_version_number = sv.version_number;

@../section_pkg
@../section_body
@../section_root_pkg
@../section_root_body

@update_tail

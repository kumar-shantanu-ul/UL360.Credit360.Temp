-- Please update version.sql too -- this keeps clean builds in sync
define version=2063
@update_header

ALTER TABLE CSR.INITIATIVE_PROJECT ADD  (
  FIELDS_XML_NEW      SYS.XMLType,
  PERIOD_FIELDS_XML_NEW   SYS.XMLType
);

UPDATE CSR.INITIATIVE_PROJECT SET FIELDS_XML_NEW = XMLType(FIELDS_XML), PERIOD_FIELDS_XML_NEW = XMLType(PERIOD_FIELDS_XML);

ALTER TABLE CSR.INITIATIVE_PROJECT MODIFY FIELDS_XML_NEW NOT NULL;
ALTER TABLE CSR.INITIATIVE_PROJECT MODIFY PERIOD_FIELDS_XML_NEW NOT NULL;


ALTER TABLE CSR.INITIATIVE_PROJECT DROP COLUMN FIELDS_XML;
ALTER TABLE CSR.INITIATIVE_PROJECT DROP COLUMN PERIOD_FIELDS_XML;

ALTER TABLE CSR.INITIATIVE_PROJECT RENAME COLUMN FIELDS_XML_NEW TO FIELDS_XML;
ALTER TABLE CSR.INITIATIVE_PROJECT RENAME COLUMN PERIOD_FIELDS_XML_NEW TO PERIOD_FIELDS_XML;

DROP TABLE CSR.TEMP_INITIATIVE PURGE;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_INITIATIVE(
  INITIATIVE_SID      NUMBER(10),   
  FLOW_STATE_ID     NUMBER(10),
  FLOW_STATE_LABEL    VARCHAR2(255),
  FLOW_STATE_LOOKUP_KEY VARCHAR2(255),  
  FLOW_STATE_COLOUR   NUMBER(10),
  FLOW_STATE_POS      NUMBER(10),
  IS_EDITABLE       NUMBER(1),
  ACTIVE          NUMBER(1),
  OWNER_SID       NUMBER(10)
)
ON COMMIT DELETE ROWS;

CREATE OR REPLACE VIEW csr.v$my_initiatives AS
  SELECT  i.app_sid, i.initiative_sid,
    ir.region_sid,
    fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
    r.role_sid, r.name role_name,
    MAX(fsr.is_editable) is_editable,
    rg.active,
    null owner_sid
    FROM  region_role_member rrm
    JOIN  role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
    JOIN flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
    JOIN flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid
    JOIN flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
    JOIN initiative i ON fi.flow_item_id = i.flow_Item_id AND fi.app_sid = i.app_sid
    JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid AND rrm.region_sid = ir.region_sid AND rrm.app_sid = ir.app_sid
    JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
   WHERE  rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
   GROUP BY i.app_sid, i.initiative_sid,
    ir.region_sid,
    fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
    r.role_sid, r.name,
    rg.active
   UNION ALL
  SELECT  i.app_sid, i.initiative_sid, ir.region_sid, 
    fi.current_state_id flow_state_id, fs.label flow_state_label, fs.lookup_key flow_state_lookup_key, fs.state_colour flow_state_colour, fs.pos flow_state_pos,
    null role_sid,  null role_name,
    MAX(igfs.is_editable) is_editable,
    rg.active,
    iu.user_sid owner_sid
    FROM initiative_user iu
    JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
    JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
    JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = fs.flow_sid AND fi.app_sid = fs.app_sid
    JOIN initiative_project_user_group ipug 
    ON iu.initiative_user_group_id = ipug.initiative_user_group_id
     AND iu.project_sid = ipug.project_sid
    JOIN initiative_group_flow_state igfs
    ON ipug.initiative_user_group_id = igfs.initiative_user_group_id
     AND ipug.project_sid = igfs.project_sid
     AND ipug.app_sid = igfs.app_sid
     AND fs.flow_state_id = igfs.flow_State_id AND fs.flow_sid = igfs.flow_sid AND fs.app_sid = igfs.app_sid
    JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
    JOIN region rg ON ir.region_sid = rg.region_sid AND ir.app_Sid = rg.app_sid
    LEFT JOIN rag_status rs ON i.rag_status_id = rs.rag_status_id AND i.app_sid = rs.app_sid
   WHERE iu.user_sid = SYS_CONTEXT('SECURITY','SID')
   GROUP BY i.app_sid, i.initiative_sid, ir.region_sid, 
    fi.current_state_id, fs.label, fs.lookup_key, fs.state_colour, fs.pos,
    rg.active, iu.user_sid;


@..\initiative_project_pkg.sql
@..\initiative_pkg.sql
@..\initiative_project_body.sql
@..\initiative_body.sql
@..\initiative_grid_body.sql

@update_tail

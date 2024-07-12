-- Please update version.sql too -- this keeps clean builds in sync
define version=2426
@update_header

CREATE OR REPLACE VIEW chem.v$my_substance_region 
	AS
SELECT sr.app_sid, sr.region_sid, sr.substance_id, MAX(fsr.is_editable) is_editable
  FROM csr.region_role_member rrm
  JOIN csr.role r ON rrm.role_sid = r.role_sid AND rrm.app_sid = r.app_sid
  JOIN csr.flow_state_role fsr ON fsr.role_sid = r.role_sid AND fsr.app_sid = r.app_sid
  JOIN csr.flow_state fs ON fsr.flow_state_id = fs.flow_state_id AND fsr.app_sid = fs.app_sid 
  JOIN csr.flow_item fi ON fs.flow_state_id = fi.current_state_id AND fs.app_sid = fi.app_sid
  JOIN chem.substance_region sr ON fi.flow_item_id = sr.flow_item_id AND rrm.region_sid = sr.region_sid AND rrm.app_sid = sr.app_sid
  JOIN csr.region rg ON sr.region_sid = rg.region_sid AND sr.app_Sid = rg.app_sid
 WHERE rrm.user_sid = SYS_CONTEXT('SECURITY','SID')
 GROUP BY sr.app_sid, sr.region_sid, sr.substance_id;
 

@update_tail
--Please update version.sql too -- this keeps clean builds in sync
define version=2668
@update_header

-- FB64636
CREATE OR REPLACE VIEW csr.tag_group_ir_member AS
  -- get region tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag,  region_sid, null ind_sid, null non_compliance_id 
    FROM tag_group_member tgm, tag t, region_tag rt
   WHERE tgm.tag_id = t.tag_id
     AND rt.tag_id = t.tag_id
  UNION ALL
  -- get indicator tags   
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id,t.tag,  null region_sid, it.ind_sid ind_sid, null non_compliance_id 
    FROM tag_group_member tgm, tag t, ind_tag it
   WHERE tgm.tag_id = t.tag_id
     AND it.tag_id = t.tag_id
  UNION ALL
 -- get non compliance tags
  SELECT tgm.tag_group_id, tgm.pos, t.tag_id, t.tag, null region_sid, null ind_sid, nct.non_compliance_id 
    FROM tag_group_member tgm, tag t, non_compliance_tag nct
   WHERE tgm.tag_id = t.tag_id
     AND nct.tag_id = t.tag_id;    
	 
-- FB62262
-- convert 1/kg to 1/lb => 1/lb = 1/(2.20462262*kg)
INSERT INTO CSR.STD_MEASURE_CONVERSION 
	(STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) 
VALUES (26046, 31, '1/lb', 2.20462262, 1, 0, 0);

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=1969
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_INITIATIVE(
    INITIATIVE_SID          NUMBER(10),     
    FLOW_STATE_ID           NUMBER(10),
    FLOW_STATE_LABEL        VARCHAR2(255),
    FLOW_STATE_LOOKUP_KEY   VARCHAR2(255),  
    FLOW_STATE_COLOUR       NUMBER(10),
    IS_EDITABLE             NUMBER(1),
    ACTIVE                  NUMBER(1),
    OWNER_SID               NUMBER(10)
)
ON COMMIT DELETE ROWS;

update security.securable_object set name = replace(name, 'chem.substance_pkg.', 'chem.report_pkg.') where name like 'chem.substance_pkg.%';

CREATE OR REPLACE VIEW "CHEM"."V$OUTPUTS" 
AS
SELECT spu.app_sid, NVL(cg.label, 'Unknown') cas_group_label, cg.cas_group_id,
       c.cas_code, c.name, c.is_voc, c.category,
       s.ref substance_ref, s.description substance_description,
       sr.waiver_status_id, sr.region_sid, spu.start_dtm, spu.end_dtm,
       spcd.to_air_pct * spu.mass_value * sc.pct_composition air_mass_value,
       spcd.to_water_pct * spu.mass_value * sc.pct_composition water_mass_value,
       spu.mass_value * sc.pct_composition cas_weight,
       spcd.to_air_pct,
       spcd.to_water_pct,
       spcd.to_waste_pct,
       spcd.to_product_pct,
       spcd.remaining_pct,
       root_delegation_sid,
       sr.local_ref,
       sr.first_used_dtm,
       srp.first_used_dtm process_first_used_dtm
  FROM substance_process_use spu
  JOIN substance s ON spu.substance_id = s.substance_id AND spu.app_sid = s.app_sid
  JOIN substance_region sr ON spu.substance_id = sr.substance_id AND spu.region_sid = sr.region_sid AND spu.app_sid = sr.app_sid
  JOIN substance_region_process srp
    ON spu.substance_id = srp.substance_id
   AND spu.region_sid = srp.region_sid
   AND spu.process_id = srp.process_id
   AND spu.app_sid = srp.app_sid
  LEFT JOIN substance_process_cas_dest spcd
    ON spu.substance_process_use_id = spcd.substance_process_use_id
   AND spu.substance_id = spcd.substance_id
   AND spu.app_sid = spcd.app_sid
  JOIN substance_cas sc ON s.substance_id = sc.substance_id
  JOIN cas c ON sc.cas_code = c.cas_code
  LEFT JOIN cas_group_member cgm ON c.cas_code = cgm.cas_code
  LEFT JOIN cas_group cg ON cgm.cas_group_id = cg.cas_group_id AND cgm.app_sid = cg.app_sid;

ALTER TABLE csr.ind modify lookup_key varchar2(255);




CREATE OR REPLACE PACKAGE chem.report_pkg
AS
END;
/

GRANT EXECUTE ON chem.report_pkg TO WEB_USER;

grant execute on chem.report_pkg to csr;
grant execute on chem.report_pkg to web_user;

@..\chem\report_pkg
@..\chem\substance_pkg
@..\initiative_grid_pkg
@..\initiative_pkg
@..\teamroom_pkg
@..\section_pkg

@..\teamroom_body
@..\initiative_grid_body
@..\initiative_body
@..\chem\substance_body
@..\chem\report_body
@..\section_body



@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=44

@update_header

-- insert material provenance mappings
-- 
-- TABLE: GT_PDA_MAT_PROV_MAPPING 
--

CREATE TABLE GT_PDA_MAT_PROV_MAPPING(
    GT_MATERIAL_ID               NUMBER(10, 0)    NOT NULL,
    GT_PDA_PROVENANCE_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK329 PRIMARY KEY (GT_MATERIAL_ID, GT_PDA_PROVENANCE_TYPE_ID)
)
;

-- 
-- TABLE: GT_PDA_MAT_PROV_MAPPING 
--

ALTER TABLE GT_PDA_MAT_PROV_MAPPING ADD CONSTRAINT RefGT_PDA_PROVENANCE_TYPE875 
    FOREIGN KEY (GT_PDA_PROVENANCE_TYPE_ID)
    REFERENCES GT_PDA_PROVENANCE_TYPE(GT_PDA_PROVENANCE_TYPE_ID)
;

ALTER TABLE GT_PDA_MAT_PROV_MAPPING ADD CONSTRAINT RefGT_MATERIAL876 
    FOREIGN KEY (GT_MATERIAL_ID)
    REFERENCES GT_MATERIAL(GT_MATERIAL_ID)
;

-- insert mapping base data
INSERT INTO GT_PDA_MAT_PROV_MAPPING (GT_MATERIAL_ID, GT_PDA_PROVENANCE_TYPE_ID)
	SELECT gt_material_id, gt_pda_provenance_type_id 
	  FROM gt_material m, gt_pda_provenance_type pt
	 WHERE m.natural = 1
	   AND pt.natural = 1;
	   
INSERT INTO GT_PDA_MAT_PROV_MAPPING (GT_MATERIAL_ID, GT_PDA_PROVENANCE_TYPE_ID)	   
	SELECT gt_material_id, gt_pda_provenance_type_id 
	  FROM gt_material m, gt_pda_provenance_type pt
	 WHERE m.natural = 0
	   AND pt.natural = 0;
	
	
@update_tail
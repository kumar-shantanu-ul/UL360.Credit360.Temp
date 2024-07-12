-- Please update version.sql too -- this keeps clean builds in sync
define version=6
@update_header


ALTER TABLE GT_PRODUCT_TYPE ADD (
	  GT_ACCESS_VISC_TYPE_ID      NUMBER(10, 0) DEFAULT 2  NOT NULL  
	);
	
	
ALTER TABLE GT_PRODUCT_TYPE ADD CONSTRAINT RefGT_ACCESS_VISC_TYPE756 
    FOREIGN KEY (GT_ACCESS_VISC_TYPE_ID)
    REFERENCES GT_ACCESS_VISC_TYPE(GT_ACCESS_VISC_TYPE_ID)
;	


-- removing viscosity from packaging answers
ALTER TABLE gt_packaging_answers DROP COLUMN gt_access_visc_type_id;

-- removing viscosity from product design answers
ALTER TABLE GT_PDESIGN_ANSWERS DROP CONSTRAINT RefGT_ACCESS_VISC_TYPE762;

ALTER TABLE GT_PDESIGN_ANSWERS DROP CONSTRAINT RefGT_ACCESS_PACK_MAPPING764;

ALTER TABLE GT_PDESIGN_ANSWERS DROP COLUMN gt_access_visc_type_id;

-- removing gt_access_pack_type from product design answers
ALTER TABLE GT_PDESIGN_ANSWERS DROP CONSTRAINT RefGT_ACCESS_PACK_TYPE763;

ALTER TABLE GT_PDESIGN_ANSWERS DROP COLUMN GT_ACCESS_PACK_TYPE_ID;


-- add high risk flag
ALTER TABLE gt_packaging_answers ADD (PACK_RISK NUMBER(2, 0) DEFAULT 0 NOT NULL);
	
@update_tail
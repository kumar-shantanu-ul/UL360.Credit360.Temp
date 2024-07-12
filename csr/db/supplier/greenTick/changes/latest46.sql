-- Please update version.sql too -- this keeps clean builds in sync
define version=46

@update_header

-- update mineral items that used to be nullable
UPDATE gt_pda_material_item  
SET gt_pda_provenance_type_id = 8,  
    gt_pda_accred_type_id = 4 
WHERE gt_pda_provenance_type_id IS NULL;


ALTER TABLE SUPPLIER.GT_PDA_MATERIAL_ITEM
MODIFY(GT_PDA_PROVENANCE_TYPE_ID  NOT NULL);


ALTER TABLE SUPPLIER.GT_PDA_MATERIAL_ITEM
MODIFY(GT_PDA_ACCRED_TYPE_ID  NOT NULL);
	
@update_tail
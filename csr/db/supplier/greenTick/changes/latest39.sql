-- Please update version.sql too -- this keeps clean builds in sync
define version=39

@update_header

-- link all materials to all chemicals 
INSERT INTO SUPPLIER.GT_PDA_HC_MAT_MAP (GT_MATERIAL_ID, GT_PDA_HAZ_CHEM_ID) 
    select gt_material_id, gt_pda_haz_chem_id from gt_material, gt_pda_haz_chem;


@update_tail
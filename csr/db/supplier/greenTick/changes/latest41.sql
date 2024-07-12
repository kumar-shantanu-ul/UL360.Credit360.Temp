-- Please update version.sql too -- this keeps clean builds in sync
define version=41

@update_header

--map materials to manufac processes

INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 1 from gt_material where gt_material_group_id = 1;
	
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID)  
	select gt_material_id, 2 from gt_material where gt_material_group_id = 2;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID)  
	select gt_material_id, 3 from gt_material where gt_material_group_id = 2;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 4 from gt_material where gt_material_group_id = 2;

INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 5 from gt_material where gt_material_group_id = 3;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 6 from gt_material where gt_material_group_id = 3;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 7 from gt_material where gt_material_group_id = 3;

INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 8 from gt_material where gt_material_group_id = 4;
	
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 9 from gt_material where gt_material_group_id = 5;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 10 from gt_material where gt_material_group_id = 5;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 11 from gt_material where gt_material_group_id = 5;
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 12 from gt_material where gt_material_group_id = 5;
	
INSERT INTO SUPPLIER.GT_MAT_MAN_MAPPIING (GT_MATERIAL_ID, GT_MANUFAC_TYPE_ID) 
	select gt_material_id, 13 from gt_material where gt_material_group_id = 6;
	
@update_tail
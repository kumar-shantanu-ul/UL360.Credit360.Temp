-- Please update version.sql too -- this keeps clean builds in sync
define version=111
@update_header 


	-- map prov types to mats
	INSERT INTO SUPPLIER.gt_pda_mat_prov_mapping (gt_material_id, gt_pda_provenance_type_id) 
		 SELECT gt_material_id, gt_pda_provenance_type_id 
		   FROM SUPPLIER.gt_material m, SUPPLIER.gt_pda_provenance_type pt 
		  WHERE m.natural = pt.natural
		    AND gt_material_id NOT IN (SELECT gt_material_id FROM SUPPLIER.gt_pda_mat_prov_mapping);
		   	
			
	-- map haz chems to mats
	INSERT INTO SUPPLIER.gt_pda_hc_mat_map (gt_material_id, gt_pda_haz_chem_id)
	     SELECT gt_material_id, gt_pda_haz_chem_id FROM SUPPLIER.gt_pda_haz_chem hc, gt_material m WHERE gt_material_id NOT IN (SELECT gt_material_id FROM gt_pda_hc_mat_map);

@update_tail
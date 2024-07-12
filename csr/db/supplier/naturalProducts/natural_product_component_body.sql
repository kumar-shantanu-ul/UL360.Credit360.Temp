create or replace package body supplier.natural_product_component_pkg
IS


PROCEDURE CreatePartComponent(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_product_id					IN	product_part.product_id%TYPE,
	in_parent_part_id				IN	product_part.product_part_id%TYPE,
	in_common_name					IN	np_component_description.common_name%TYPE,
	in_species						IN	np_component_description.species%TYPE,
	in_genus						IN	np_component_description.genus%TYPE,
	in_description					IN	np_component_description.description%TYPE,
	in_country_of_origin			IN	np_component_description.country_of_origin%TYPE,
	in_region						IN	np_component_description.region%TYPE,
	in_kingdom_id 					IN	np_component_description.np_kingdom_id%TYPE,
	in_natural_claim				IN	np_component_description.natural_claim%TYPE,
	in_component_code				IN	np_component_description.component_code%TYPE,
	in_collection_desc				IN	np_component_description.collection_desc%TYPE,
	in_env_harvest_safeguard_desc	IN	np_component_description.env_harvest_safeguard_desc%TYPE,
	in_env_process_safeguard_desc	IN	np_component_description.env_process_safeguard_desc%TYPE,
	in_pp_group_id					IN	np_component_description.np_production_process_group_id%TYPE,
	out_product_part_id				OUT	product_part.product_part_id%TYPE
)
AS
	v_part_type_id			product_part.part_type_id%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
BEGIN
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = COMPONENT_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_product_id, in_parent_part_id, out_product_part_id);
	
	INSERT INTO np_component_description
		(product_part_id, common_name, species, genus, description, 
			country_of_origin, region, np_kingdom_id, natural_claim, 
			component_code, collection_desc, env_harvest_safeguard_desc, 
			env_process_safeguard_desc, np_production_process_group_id)
		VALUES (out_product_part_id, in_common_name, in_species, in_genus, 
			in_description, in_country_of_origin, in_region, in_kingdom_id, in_natural_claim, 
			in_component_code, in_collection_desc, in_env_harvest_safeguard_desc, 
			in_env_process_safeguard_desc, in_pp_group_id);
			
	-- audit log 
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = in_product_id;
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Added Natural Product component {0}', in_description, NULL, NULL, in_product_id);	
END;

-- copies own children as well
PROCEDURE CopyPart(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_from_part_id					IN product_part.product_part_id%TYPE, 
	in_to_product_id				IN product_part.product_id%TYPE, 
	in_new_parent_part_id			IN product_part.parent_id%TYPE,
	out_product_part_id				OUT product_part.product_part_id%TYPE
)
AS
	v_new_product_part_id				product_part.product_part_id%TYPE;
	v_new_child_product_part_id			product_part.product_part_id%TYPE;
	v_part_type_id						product_part.part_type_id%TYPE;
	v_old_prod_process_group_id 	np_component_description.np_production_process_group_id%TYPE;
	v_new_prod_process_group_id 	np_component_description.np_production_process_group_id%TYPE;
BEGIN
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = COMPONENT_DESCRIPTION_CLS;

	-- Security check done inside CreateProductPart
	product_part_pkg.CreateProductPart(in_act_id, v_part_type_id, in_to_product_id, in_new_parent_part_id, v_new_product_part_id);

	BEGIN 
		SELECT np_production_process_group_id INTO v_old_prod_process_group_id 
		  FROM np_component_description
	     WHERE product_part_id = in_from_part_id;
	
		-- copy production process group
		SELECT np_pproc_group_id_seq.nextval 
		  INTO v_new_prod_process_group_id
		  FROM DUAL;
			-- Create the group
		INSERT INTO np_production_process_group
			(np_production_process_group_id)
			VALUES (v_new_prod_process_group_id);
	     
		INSERT INTO np_pp_group_member (np_production_process_group_id, np_production_process_id) 
		SELECT v_new_prod_process_group_id, np_production_process_id
		  FROM np_pp_group_member
		 WHERE np_production_process_group_id = v_old_prod_process_group_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- no group - nothing to copy
			v_new_prod_process_group_id := NULL;
	END;
	
	INSERT INTO np_component_description
		(product_part_id, common_name, species, genus, description, 
			country_of_origin, region, np_kingdom_id, natural_claim, 
			component_code, collection_desc, env_harvest_safeguard_desc, 
			env_process_safeguard_desc, np_production_process_group_id)
	 SELECT v_new_product_part_id, common_name, species, genus, description, 
			country_of_origin, region, np_kingdom_id, natural_claim, 
			component_code, collection_desc, env_harvest_safeguard_desc, 
			env_process_safeguard_desc, v_new_prod_process_group_id
	   FROM np_component_description
	  WHERE product_part_id = in_from_part_id;
	 	
	-- now copies children 
	FOR child IN (
		SELECT product_part_id, package FROM product_part pp, part_type pt
		 WHERE pp.part_type_id = pt.part_type_id
		   AND parent_id = in_from_part_id
		   ORDER BY product_part_id ASC
	)
	LOOP
		    EXECUTE IMMEDIATE 'begin '||child.package||'.CopyPart(:1,:2,:3,:4,:5);end;'
				USING in_act_id, child.product_part_id, in_to_product_id, v_new_product_part_id, OUT v_new_child_product_part_id;
	END LOOP;
	
	out_product_part_id := v_new_product_part_id;
	
END;


PROCEDURE UpdatePartComponent(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_part_id						IN	product_part.product_part_id%TYPE,
	in_common_name					IN	np_component_description.common_name%TYPE,
	in_species						IN	np_component_description.species%TYPE,
	in_genus						IN	np_component_description.genus%TYPE,
	in_description					IN	np_component_description.description%TYPE,
	in_country_of_origin			IN	np_component_description.country_of_origin%TYPE,
	in_region						IN	np_component_description.region%TYPE,
	in_kingdom_id 					IN	np_component_description.np_kingdom_id%TYPE,
	in_natural_claim				IN	np_component_description.natural_claim%TYPE,
	in_component_code				IN	np_component_description.component_code%TYPE,
	in_collection_desc				IN	np_component_description.collection_desc%TYPE,
	in_env_harvest_safeguard_desc	IN	np_component_description.env_harvest_safeguard_desc%TYPE,
	in_env_process_safeguard_desc	IN	np_component_description.env_process_safeguard_desc%TYPE,
	in_pp_group_id					IN	np_component_description.np_production_process_group_id%TYPE
)
AS

	CURSOR c_old IS 
	    SELECT     common_name, species, genus, npd.description, c.country, region, npk.description kingdom, 
	            CASE natural_claim WHEN 1 THEN 'Yes' ELSE 'No' END natural_claim, component_code, collection_desc,
	            env_harvest_safeguard_desc, env_process_safeguard_desc
	         FROM np_component_description npd, country c, np_kingdom npk
	        WHERE npd.country_of_origin = c.country_code
	          AND npd.np_kingdom_id = npk.np_kingdom_id
	          AND product_part_id = in_part_id;
	r_old c_old%ROWTYPE;
	
	CURSOR c_new IS 
	    SELECT     common_name, species, genus, npd.description, c.country, region, npk.description kingdom, 
	            CASE natural_claim WHEN 1 THEN 'Yes' ELSE 'No' END natural_claim, component_code, collection_desc,
	            env_harvest_safeguard_desc, env_process_safeguard_desc
	         FROM np_component_description npd, country c, np_kingdom npk
	        WHERE npd.country_of_origin = c.country_code
	          AND npd.np_kingdom_id = npk.np_kingdom_id
	          AND product_part_id = in_part_id;
	r_new c_new%ROWTYPE;

	v_app_sid 			security_pkg.T_SID_ID;
	v_parent_desc			np_part_description.description%TYPE;
	v_product_id 			product.product_id%TYPE;

BEGIN
	
	IF NOT product_part_pkg.IsPartAccessAllowed(in_act_id, in_part_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to part with id '||in_part_id);
	END IF;
	
	-- read some bits about the old part
	OPEN c_old;
	FETCH c_old INTO r_old;
	IF c_old%NOTFOUND THEN
		CLOSE c_old;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_old;

	UPDATE np_component_description
	   SET common_name = in_common_name, 
	       species = in_species,
	       genus = in_genus,
	       description = in_description, 
		   country_of_origin = in_country_of_origin,
		   region = in_region,
		   np_kingdom_id = in_kingdom_id,
		   natural_claim = in_natural_claim, 
		   component_code = in_component_code,
		   collection_desc = in_collection_desc,
		   env_harvest_safeguard_desc = in_env_harvest_safeguard_desc,
		   env_process_safeguard_desc = in_env_process_safeguard_desc,
		   np_production_process_group_id = in_pp_group_id
	 WHERE product_part_id = in_part_id;
	 
	-- read some bits about the new part
	OPEN c_new;
	FETCH c_new INTO r_new;
	IF c_new%NOTFOUND THEN
		CLOSE c_new;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The part with id '||in_part_id||' was not found');
	END IF;
	CLOSE c_new;
	
	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id)
    	INTO v_product_id 
    	FROM product_part
		START WITH product_part_id = in_part_id
		CONNECT BY PRIOR parent_id = in_part_id;
	
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
    SELECT npd.description 
    	INTO v_parent_desc
    	FROM np_part_description npd, product_part pp
   		WHERE pp.parent_id = npd.product_part_id 
    	AND pp.product_part_id = in_part_id;
    	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Common name', r_old.common_name, r_new.common_name, v_product_id);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Species', r_old.species, r_new.species, v_product_id);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Genus', r_old.genus, r_new.genus, v_product_id);		
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Description', r_old.description, r_new.description, v_product_id);
	 
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Country', r_old.country, r_new.country, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Region', r_old.region, r_new.region, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Kingdom', r_old.kingdom, r_new.kingdom, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Natural Claim', r_old.natural_claim, r_new.natural_claim, v_product_id);
				
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Component Code', r_old.component_code, r_new.component_code, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Collection Process', r_old.collection_desc, r_new.collection_desc, v_product_id);
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Harvesting environmental safeguards', r_old.env_harvest_safeguard_desc, r_new.env_harvest_safeguard_desc, v_product_id);

	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid,
		'Natural Product component: ' || v_parent_desc || ': Processing environmental safeguards', r_old.env_process_safeguard_desc, r_new.env_process_safeguard_desc, v_product_id);
END;

PROCEDURE DeletePart(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_part_id				IN product_part.product_part_id%TYPE
)
AS
	v_desc					np_part_description.description%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	v_product_id 			product.product_id%TYPE;
BEGIN

	SELECT description INTO v_desc FROM np_component_description WHERE product_part_id = in_part_id;

	-- could be multiple products in the future but not supported atm
    SELECT DISTINCT(product_id) 
    	INTO v_product_id
    	FROM product_part
		START WITH product_part_id = in_part_id
		CONNECT BY PRIOR parent_id = product_part_id;
	 
	-- Audit changes
	SELECT app_sid INTO v_app_sid FROM all_product WHERE product_id = v_product_id;
	
	DELETE FROM np_component_description
	 WHERE product_part_id IN (
         SELECT product_part_id
               FROM all_product p, product_part pp
              WHERE p.product_id = pp.product_id
         START WITH product_part_id = in_part_id
         CONNECT BY PRIOR product_part_id = parent_id
	);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_app_sid, 'Deleted Natural Product compenent {0}', v_desc, NULL, NULL, v_product_id);
END;

PROCEDURE GetPartComponents(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_part_id				IN	product_part.product_part_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT product_part_pkg.IsPartAccessAllowed(in_act_id, in_part_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading part with id '||in_part_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT p.product_id, p.product_part_id, p.part_type_id, p.parent_id, 
				d.common_name, d.species, d.genus, d.description, d.region, d.natural_claim, d.component_code, 
				d.collection_desc, d.env_harvest_safeguard_desc, d.env_process_safeguard_desc, d.np_production_process_group_id,
				d.country_of_origin, c.country country_of_origin_name, d.np_kingdom_id, k.name np_kingdom_name
		  FROM product_part p, np_component_description d, country c, np_kingdom k
		 WHERE p.parent_id = in_part_id
		   AND d.product_part_id = p.product_part_id
		   AND c.country_code = d.country_of_origin
		   AND k.np_kingdom_id = d.np_kingdom_id
		   	ORDER BY d.description;
END;

PROCEDURE SetProductionProcesses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_product_id			IN	product_part.product_id%TYPE,
	in_group_id				IN	np_component_description.np_production_process_group_id%TYPE,
	in_proc_ids				IN 	T_PROCESS_IDS,
	out_group_id			OUT	np_component_description.np_production_process_group_id%TYPE
)
AS
	v_old_processes			audit_pkg.T_VARCHAR2_VALUES;
	v_new_processes			audit_pkg.T_VARCHAR2_VALUES;
	v_index					NUMBER;
	v_app_sid 			security_pkg.T_SID_ID;
	v_product_id 			product.product_id%TYPE;
BEGIN
	out_group_id := in_group_id;
	IF out_group_id < 0 THEN
		-- Get a new group id
		SELECT np_pproc_group_id_seq.nextval 
		  INTO out_group_id
		  FROM DUAL;
		-- Create the group
		INSERT INTO np_production_process_group
			(np_production_process_group_id)
			VALUES (out_group_id);
	END IF;
	
   SELECT p.app_sid, p.product_id INTO v_app_sid, v_product_id FROM product p
   WHERE product_id = in_product_id;
	
	-- need to do audit logging here as may be deleteing old processes before inserting new tags
	v_index := 1;
	FOR r IN (
 		SELECT name FROM np_production_process npp, np_pp_group_member npgm 
		    WHERE np_production_process_group_id = out_group_id
		      AND npp.np_production_process_id = npgm.np_production_process_id
	)
	LOOP
		v_old_processes(v_index) := r.name;
		v_index := v_index + 1;
	END LOOP;
	
	-- Delete old group members
	DELETE FROM np_pp_group_member
	 WHERE np_production_process_group_id = out_group_id;
	 
	-- check for "empty array"
	IF in_proc_ids.COUNT = 1 AND in_proc_ids(1) IS NULL THEN
		RETURN;
	END IF;

	
	-- Insert new group members
	FOR i IN in_proc_ids.FIRST .. in_proc_ids.LAST
	LOOP
		INSERT INTO np_pp_group_member
			(np_production_process_group_id, np_production_process_id)
			VALUES (out_group_id, in_proc_ids(i));
	END LOOP;
	
	-- get new processes
	v_index := 1;
	FOR r IN (
 		SELECT name FROM np_production_process npp, np_pp_group_member npgm 
		    WHERE np_production_process_group_id = out_group_id
		      AND npp.np_production_process_id = npgm.np_production_process_id
	)
	LOOP
		v_new_processes(v_index) := r.name;
		v_index := v_index + 1;
	END LOOP;	
	
	audit_pkg.AuditVarcharListChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_app_sid, 
		'Adding production process', 'Removing production process', NULL, NULL, NULL, 
		v_old_processes, v_new_processes, 1, v_product_id);
		
END;

PROCEDURE GetProductionProcesses(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_group_id				IN	np_component_description.np_production_process_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.np_production_process_id, p.name, p.description
		  FROM np_pp_group_member g, np_production_process p
		 WHERE g.np_production_process_group_id = in_group_id
		   AND p.np_production_process_id = g.np_production_process_id
			ORDER BY p.name;
END;

-- Helper function in all part type spoecific packages to return min
-- doc date for any groups attatched to parts of this type for a product. 
-- If no doc groups for a type return NULL date
PROCEDURE GetMinDateForType (
	in_product_id			IN product.product_id%TYPE,
	out_min_date			OUT DATE -- don't use function as don't think you can use EXECUTE IMMEDIATE
)
AS
BEGIN
	out_min_date  := NULL;
END;

END natural_product_component_pkg;
/

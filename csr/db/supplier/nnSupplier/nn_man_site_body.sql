CREATE OR REPLACE PACKAGE BODY nn_man_site_pkg
IS

PROCEDURE GetManufacturingSite(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_site_id						IN NN_MANUFACTURING_SITE.COMPANY_PART_ID%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT company_part_pkg.IsPartAccessAllowed(in_act_id, in_site_id, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading manufacturing site with id '||in_site_id);
	END IF;
	
	OPEN out_cur FOR
		SELECT company_part_id, manufacturer_name, site_address, site_contact_name, 
			site_contact_number, c.country_code, c.country country_name, employees_at_site, processes_at_site
		  FROM nn_manufacturing_site s, nn_country c
		 WHERE company_part_id = in_site_id
		   AND c.country_code = s.country_code;
END;

PROCEDURE CreateManufacturingSite(
	in_act_id								IN security_pkg.T_ACT_ID,
	in_company_sid					IN security_pkg.T_SID_ID,
	in_parent_part_id				IN company_part.parent_id%TYPE,
	in_manufacturer_name		IN nn_manufacturing_site.manufacturer_name%TYPE,
	in_address							IN nn_manufacturing_site.site_address%TYPE,
	in_contact_name					IN nn_manufacturing_site.site_contact_name%TYPE,
	in_contact_number				IN nn_manufacturing_site.site_contact_number%TYPE,
	in_country_code					IN nn_manufacturing_site.country_code%TYPE,
	in_employees_at_site		IN nn_manufacturing_site.employees_at_site%TYPE,
	in_processes_at_site		IN nn_manufacturing_site.processes_at_site%TYPE,
	out_manufacturing_site_id		OUT nn_manufacturing_site.company_part_id%TYPE
)
AS
	v_site_id		company_part.company_part_id%TYPE;
	v_part_type_id			company_part.part_type_id%TYPE;
	v_app_sid 			security_pkg.T_SID_ID;
	--v_parent_desc			wood_part_description.description%TYPE;
	--v_product_id 			product.product_id%TYPE;
BEGIN
	
	-- don't need security check here as CreateCompanyPart checks everything we need to worry about
	-- this just floats on the top and does the custom bits for MANUFACTURING SITE
	
	SELECT part_type_id 
	  INTO v_part_type_id 
	  FROM part_type
	 WHERE class_name = PART_MAN_SITE_CLASS_NAME;

	company_part_pkg.CreateCompanyPart(in_act_id, v_part_type_id, in_company_sid, in_parent_part_id, v_site_id);
	
	INSERT INTO nn_manufacturing_site (company_part_id, manufacturer_name, 
	  			 site_address, site_contact_name, site_contact_number, country_code, employees_at_site, processes_at_site) 
		VALUES (v_site_id, in_manufacturer_name, in_address, in_contact_name, in_contact_number, in_country_code, in_employees_at_site, in_processes_at_site);
	
	out_manufacturing_site_id := v_site_id;

	-- audit
	SELECT app_sid INTO v_app_sid FROM all_company WHERE company_sid = in_company_sid;
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, in_company_sid, 'Added manufacturing site {0}', in_manufacturer_name, NULL, NULL, NULL);	

END;

PROCEDURE UpdateManufacturingSite(
	in_act_id								IN security_pkg.T_ACT_ID,
	in_site_id							IN nn_manufacturing_site.company_part_id%TYPE,
	in_manufacturer_name		IN nn_manufacturing_site.manufacturer_name%TYPE,
	in_address							IN nn_manufacturing_site.site_address%TYPE,
	in_contact_name					IN nn_manufacturing_site.site_contact_name%TYPE,
	in_contact_number				IN nn_manufacturing_site.site_contact_number%TYPE,
	in_country_code					IN nn_manufacturing_site.country_code%TYPE,
	in_employees_at_site		IN nn_manufacturing_site.employees_at_site%TYPE,
	in_processes_at_site		IN nn_manufacturing_site.processes_at_site%TYPE
)
AS
	CURSOR c_old IS 
		SELECT manufacturer_name, site_address, site_contact_name, site_contact_number, cty.country , employees_at_site, processes_at_site  
		   FROM nn_manufacturing_site ms, nn_country cty
		    WHERE ms.country_code = cty.country_code
		    AND company_part_id = in_site_id;
	r_old c_old%ROWTYPE;
	
	CURSOR c_new IS 
		SELECT manufacturer_name, site_address, site_contact_name, site_contact_number, cty.country , employees_at_site, processes_at_site  
		   FROM nn_manufacturing_site ms, nn_country cty
		    WHERE ms.country_code = cty.country_code
		    AND company_part_id = in_site_id;
	r_new c_new%ROWTYPE;

	v_app_sid 					security_pkg.T_SID_ID;
	v_company_sid 					company.company_sid%TYPE;
BEGIN

	IF NOT company_part_pkg.IsPartAccessAllowed(in_act_id, in_site_id, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to manufacturing site with id '||in_site_id);
	END IF;

	-- read some bits about the old site
	OPEN c_old;
	FETCH c_old INTO r_old;
	IF c_old%NOTFOUND THEN
		CLOSE c_old;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The manufacturing site with id '||in_site_id||' was not found');
	END IF;
	CLOSE c_old;

	UPDATE nn_manufacturing_site
	   SET manufacturer_name = in_manufacturer_name,
	   site_address = in_address, 
	   site_contact_name = in_contact_name,
	   site_contact_number = in_contact_number,
	   country_code = in_country_code, 
	   employees_at_site = in_employees_at_site,
	   processes_at_site = in_processes_at_site
	 WHERE company_part_id = in_site_id;
	 
	-- read some bits about the new part
	OPEN c_new;
	FETCH c_new INTO r_new;
	IF c_new%NOTFOUND THEN
		CLOSE c_new;
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_OBJECT_NOT_FOUND, 'The manufacturing site with id '||in_site_id||' was not found');
	END IF;
	CLOSE c_new;
	 
	-- could be multiple compnies in the future but not supported atm
    SELECT DISTINCT(company_sid) 
    	INTO v_company_sid
    	FROM company_part
		START WITH company_part_id = in_site_id
		CONNECT BY PRIOR parent_id = company_part_id;
	 
	-- Audit changes
	SELECT app_sid INTO v_app_sid FROM all_company WHERE company_sid = v_company_sid;
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Manufacturer Name', r_old.manufacturer_name, r_new.manufacturer_name, NULL);	
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Site Address', r_old.site_address, r_new.site_address, NULL);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Site Contact Name', r_old.site_contact_name, r_new.site_contact_name, NULL);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Site Contact Number', r_old.site_contact_number, r_new.site_contact_number, NULL);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Country', r_old.country, r_new.country, NULL);	
	
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Employees At Site', r_old.employees_at_site, r_new.employees_at_site, NULL);	
		
	audit_pkg.AuditValueChange(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED, v_app_sid, v_company_sid,
		'Manufacturing site: ' || in_manufacturer_name || ': Processes At Site', r_old.processes_at_site, r_new.processes_at_site, NULL);	
END;

PROCEDURE DeleteManufacturingSite(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_site_id					IN company_part.company_part_id%TYPE
)
AS
	v_manufacturer_name		nn_manufacturing_site.manufacturer_name%TYPE;
	v_app_sid 				security_pkg.T_SID_ID;
	v_company_sid 				company.company_sid%TYPE;
BEGIN

	SELECT manufacturer_name INTO v_manufacturer_name FROM nn_manufacturing_site WHERE company_part_id = in_site_id;
	
	-- could be multiple companies in the future but not supported atm
    SELECT DISTINCT(company_sid) 
    	INTO v_company_sid
    	FROM company_part
		START WITH company_part_id = in_site_id
		CONNECT BY PRIOR parent_id = company_part_id;
	
	-- audit log 
	SELECT app_sid INTO v_app_sid FROM all_company WHERE company_sid = v_company_sid;
	
	DELETE FROM nn_manufacturing_site 
	 WHERE company_part_id IN (
         SELECT company_part_id
               FROM all_company c, company_part cp
              WHERE c.company_sid = cp.company_sid
         START WITH company_part_id = in_site_id
         CONNECT BY PRIOR company_part_id = parent_id
	);
	
	audit_pkg.WriteAuditLogEntry(in_act_id, csr.csr_data_pkg.AUDIT_TYPE_QUEST_SAVED,
		v_app_sid, v_company_sid, 'Deleted manufacturing site {0}', v_manufacturer_name, NULL, NULL, NULL);	
	
END;

PROCEDURE GetCountryList(
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT country_code, country
		  FROM nn_country
		 	ORDER BY country;
END;

PROCEDURE DeleteAbsentSites(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_company_sid			IN security_pkg.T_SID_ID,
	in_site_ids				IN T_SITE_IDS
)
AS
	v_current_ids			T_SITE_IDS;
BEGIN
	-- Get current ids
	FOR r IN (
		SELECT ms.company_part_id
		  FROM nn_manufacturing_site ms, company_part cp
		 WHERE cp.company_sid = in_company_sid
		   AND ms.company_part_id = cp.company_part_id
	) LOOP
		v_current_ids(r.company_part_id) := r.company_part_id;
	END LOOP;
	
	-- Remove any part ids present in the input array
	IF in_site_ids(1) IS NOT NULL THEN
		FOR i IN in_site_ids.FIRST .. in_site_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_site_ids(i)) THEN
				v_current_ids.DELETE(in_site_ids(i));
			END IF;
		END LOOP;
	END IF;
	
	-- Delete any ids remaining
	IF v_current_ids.COUNT > 0 THEN
		FOR i IN v_current_ids.FIRST .. v_current_ids.LAST
		LOOP
			DeleteManufacturingSite(in_act_id, v_current_ids(i));
		END LOOP;
	END IF;
	
END;


END nn_man_site_pkg;
/

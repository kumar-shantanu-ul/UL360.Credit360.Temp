/*
   Sequence:
   - initialProductImport_createTables.sql
   - run C:\cvs\csr\db\supplier\import\ExcelToDBImport pointing at excel file e.g. "C:\cvs\csr\db\supplier\importFinalFormattedImport19032008.xls"
   - run this script
 */

DECLARE
    v_app_sid                  csr.customer.app_sid%TYPE;
    v_admin_group_sid		   security_pkg.T_SID_ID;

    CURSOR product_cur
        IS
            SELECT * FROM product_import_data where product_id not in (1);
            
    product_row        product_cur%ROWTYPE;
    
    CURSOR wood_cur
        IS
            SELECT * FROM WOOD_IMPORT_DATA WHERE product_id = product_row.product_id
                ORDER BY part_name;
    wood_row                        wood_cur%ROWTYPE;
     
    CURSOR species_cur
        IS
            SELECT * FROM tree_species WHERE lower(trim(species_code)) = lower(trim(wood_row.wood_type));   
    
    species_row                     species_cur%ROWTYPE;  
            
    CURSOR country_cur
        IS
            SELECT * FROM country WHERE lower(trim(country)) = lower(trim(wood_row.country_of_origin));          
    country_row                     country_cur%ROWTYPE;
    
    CURSOR scheme_cur
        IS
            SELECT * FROM cert_scheme WHERE lower(trim(name)) = lower(trim(wood_row.cert_scheme));          
    scheme_row                     scheme_cur%ROWTYPE;
                
    CURSOR wood_type_cur
        IS
            SELECT * FROM wrme_wood_type WHERE lower(trim(description)) = lower(trim(product_row.product_type));          
    wood_type_row                     wood_type_cur%ROWTYPE;
    
    CURSOR supplier_cur
        IS
            SELECT * FROM company WHERE app_sid = v_app_sid AND LOWER(name) = LOWER(TRIM(product_row.supplier));
    supplier_row                    supplier_cur%ROWTYPE;
                
    CURSOR sales_type_cur
        IS
            SELECT t.* FROM tag t, tag_group tg, tag_group_member tgm 
            WHERE lower(t.tag) = lower(trim(product_row.brand))
            AND tg.tag_group_sid = tgm.tag_group_sid
            AND t.tag_id = tgm.tag_id
            AND tg.app_sid = v_app_sid;
 
    CURSOR merchant_type_cur
        IS
             SELECT t.* FROM tag t, tag_group tg, tag_group_member tgm 
             WHERE lower(tag) = lower(trim(product_row.business_centre))
             AND tg.tag_group_sid = tgm.tag_group_sid
            AND t.tag_id = tgm.tag_id
            AND tg.app_sid = v_app_sid;
            
    CURSOR boots_cur
    IS
         SELECT * FROM company WHERE app_sid = v_app_sid AND name = 'Boots UK Ltd';  
           
     
    CURSOR andrew_cur
    IS
         SELECT * FROM csr.csr_user where lower(full_name) LIKE '%andrew jenkins%' AND app_sid = v_app_sid;

    sales_type_row                  sales_type_cur%ROWTYPE;
    merchant_type_row               merchant_type_cur%ROWTYPE;
    boots_row                       boots_cur%ROWTYPE;
    andrew_row                      andrew_cur%ROWTYPE;
    
    v_act                           security_pkg.T_ACT_ID;

    v_andrew_user_sid               NUMBER;
    v_boots_sid                     NUMBER;
    
    v_supplier_sid                  product.SUPPLIER_COMPANY_SID%TYPE;
     v_supplier_user_sid            NUMBER;
    
        v_exists                      NUMBER;
    v_product_id                    product.PRODUCT_ID%TYPE;
    v_country_code                  wood_part_wood.COUNTRY_CODE%TYPE;
    v_species_code                  wood_part_wood.SPECIES_CODE%TYPE;
    v_wood_type						wood_part_wood.WRME_WOOD_TYPE_ID%TYPE;
    v_cert_scheme_id                wood_part_wood.cert_scheme_id%TYPE;
    

    v_last_wood_part_name           wood_part_description.DESCRIPTION%TYPE;-- VARCHAR2(1024);
    v_this_wood_part_name           wood_part_description.DESCRIPTION%TYPE; --VARCHAR2(1024);

    v_product_part_id               wood_part_description.PRODUCT_PART_ID%TYPE;
    v_wood_part_id                  wood_part_description.PRODUCT_PART_ID%TYPE;     

    v_num_wood_for_part             NUMBER;
    v_num_wood_for_part_Ri          NUMBER;
    v_num_wood_for_part_Rii         NUMBER;
    
    v_product_type_tag_group_id     tag_group.TAG_GROUP_SID%TYPE;
    v_sales_type_tag_group_id       tag_group.TAG_GROUP_SID%TYPE;
    v_merchant_type_tag_group_id    tag_group.TAG_GROUP_SID%TYPE;
    
    v_tag_id                        tag_group_member.TAG_ID%TYPE;
    v_pos                           tag_group_member.POS%TYPE;
    

BEGIN
        -- get app sid 
        SELECT app_sid INTO v_app_sid FROM csr.customer WHERE host =  '&&1';
        
        --get act
        user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);

        -- create or get boots company sid 
        OPEN boots_cur;
        FETCH boots_cur INTO boots_row;
                        
        IF (boots_cur%FOUND) THEN 
            v_boots_sid := boots_row.company_sid;
            -- andrew already exists
            SELECT MIN(csr_user_sid) INTO v_andrew_user_sid FROM company_user WHERE company_sid = v_boots_sid ;
        ELSE
        	SELECT (10/0) INTO v_boots_sid FROM DUAL;
           /* company_pkg.CREATECOMPANY(v_act, v_app_sid, 'Boots Group PLC', '1  Thane Road', 'Beeston', null, 
               null, 'Nottingham', 'Nottinghamshire', 'NG2 3AA', '+44 (0) 115 950 6111', null, null, 1, 'ENG', v_owner_sid);               
            csr.csr_user_pkg.createUser(v_act, v_app_sid, 'andrew jenkins', 'jenkins12', 'andrew jenkins', 'andrewjenkins@credit360.com2', null, null, null, v_owner_user_sid);
            v_admin_group_sid := securableobject_pkg.GetSIDFromPath(v_act, v_app_sid, 'Groups/Administrators');
            group_pkg.AddMember(v_act, v_owner_user_sid, v_admin_group_sid);
            company_pkg.ADDCONTACT(v_act, v_app_sid, v_owner_sid,  v_owner_user_sid);*/
        END IF; 
        CLOSE boots_cur;
        
        -- get product merchannt and sales type tag group id
        SELECT tag_group_sid INTO v_product_type_tag_group_id  FROM tag_group WHERE app_sid = v_app_sid AND name = 'product_category';
        SELECT tag_group_sid INTO v_merchant_type_tag_group_id  FROM tag_group WHERE app_sid = v_app_sid AND name = 'merchant_type';
        SELECT tag_group_sid INTO v_sales_type_tag_group_id  FROM tag_group WHERE app_sid = v_app_sid AND name = 'sale_type';

        OPEN product_cur;
        
        FETCH product_cur
        INTO product_row;
        
        WHILE (product_cur%FOUND)                       
        LOOP
        
            select count(*) into  v_exists from product where product_code = product_row.item_code and app_sid = v_app_sid;
            
            if ( v_exists <1) then  -- create
            
                  DBMS_OUTPUT.Put_Line('Creating prod');

                -- find out if supplier already present 
                OPEN supplier_cur;
                FETCH supplier_cur INTO supplier_row;
            
                IF (supplier_cur%NOTFOUND) THEN
                    SELECT (10/0) INTO v_boots_sid FROM DUAL;
                    -- create it if not exist and get sid 
                    company_pkg.CREATECOMPANY(v_act, v_app_sid, lower(trim(product_row.supplier)), 'temp address 1', 'temp address 2', 'temp address 3', 
                        'temp address 4', 'temp town', 'temp state', 'temp postcode', 'temp phone 1', 'temp phone 2', 'temp fax', 0, 'UK', v_supplier_sid);
                    
					csr.csr_user_pkg.createUser(
						in_act						=> v_act,
						in_app_sid					=> v_app_sid,
						in_user_name				=> lower(trim(product_row.supplier)) || ' user',
						in_password					=> 'password12',
						in_full_name				=> lower(trim(product_row.supplier)) || ' user',
						in_friendly_name			=> lower(trim(product_row.supplier)) || ' user',
						in_email					=> 'fake@credit360.com2',
						in_job_title				=> null,
						in_phone_number				=> null,
						in_info_xml					=> null,
						in_send_alerts				=> 1,
						out_user_sid				=> v_supplier_user_sid
					);
                
                    company_pkg.ADDCONTACT(v_act, v_app_sid, v_supplier_sid,  v_supplier_user_sid);
                ELSE
                    -- get sid if it does exist 
                    SELECT company_sid INTO v_supplier_sid FROM company WHERE app_sid = v_app_sid AND LOWER(name) = LOWER(trim(product_row.supplier));
                
                    -- a bit lazy - but probably not an issue as should only be one user per company 
                    SELECT MIN(csr_user_sid) INTO v_supplier_user_sid FROM company_user cu WHERE cu.company_sid = v_supplier_sid;
                END IF;
                CLOSE supplier_cur;
            
                -- create the product part and part description 
                product_pkg.CREATEPRODUCT(v_act, v_app_sid, product_row.item_code, product_row.product, v_supplier_sid, '31 mar 2009', 1, v_product_id);

                     
                -- Links single appriver  to each q 
    		    INSERT INTO product_questionnaire_link (product_id, questionnaire_id, approver_sid, approver_company_sid, questionnaire_status_id, used)
    			    VALUES (v_product_id, 1, v_andrew_user_sid,  v_boots_sid, 1, 1);
     		    INSERT INTO product_questionnaire_link (product_id, questionnaire_id, approver_sid, approver_company_sid, questionnaire_status_id)
    			    VALUES (v_product_id, 2, null,  null, 0);
     		    INSERT INTO product_questionnaire_link (product_id, questionnaire_id, approver_sid, approver_company_sid, questionnaire_status_id)
    			    VALUES (v_product_id, 3, null,  null, 0);
      		    INSERT INTO product_questionnaire_link (product_id, questionnaire_id, approver_sid, approver_company_sid, questionnaire_status_id)
    			    VALUES (v_product_id, 4, null,  null, 0);
     		    INSERT INTO product_questionnaire_link (product_id, questionnaire_id, approver_sid, approver_company_sid, questionnaire_status_id)
    			    VALUES (v_product_id, 5, null,  null, 0);
   

                              
                -- Link single provider tp each q 
    				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid, provider_company_sid)
    						SELECT v_product_id, 1, v_andrew_user_sid, company_sid
    							FROM company_user cu
    								WHERE cu.csr_user_sid = v_andrew_user_sid;
    				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid, provider_company_sid)
    						SELECT v_product_id, 2, v_andrew_user_sid, company_sid
    							FROM company_user cu
    								WHERE cu.csr_user_sid = v_andrew_user_sid;
    				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid, provider_company_sid)
    						SELECT v_product_id, 3, v_andrew_user_sid, company_sid
    							FROM company_user cu
    								WHERE cu.csr_user_sid = v_andrew_user_sid;                                
    				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid, provider_company_sid)
    						SELECT v_product_id, 4, v_andrew_user_sid, company_sid
    							FROM company_user cu
    								WHERE cu.csr_user_sid = v_andrew_user_sid;
     				INSERT INTO product_questionnaire_provider (product_id, questionnaire_id, provider_sid, provider_company_sid)
    						SELECT v_product_id, 5, v_andrew_user_sid, company_sid
    							FROM company_user cu
    								WHERE cu.csr_user_sid = v_andrew_user_sid;                               
                                
                                            
                -- mapping from old product to new one for debug and cleanup of data post import
                INSERT INTO product_import_mapping (import_product_id, new_product_id, dtm) VALUES (product_row.product_id, v_product_id, sysdate);
            
                -- do sales type here 
                OPEN sales_type_cur;
                FETCH sales_type_cur INTO sales_type_row;
           
                IF  (sales_type_cur%FOUND) THEN 
                    v_tag_id := sales_type_row.tag_id;
                ELSE
                    SELECT MAX(pos) INTO v_pos FROM tag_group_member WHERE tag_group_sid = v_sales_type_tag_group_id;
                    tag_pkg.ADDNEWTAGTOGROUP(v_act, v_sales_type_tag_group_id, lower(trim(product_row.brand)), lower(trim(product_row.brand)), v_pos + 1, 1, v_tag_id);
                END IF;
                product_pkg.SetProductTag(v_act, v_product_id, v_tag_id);  
                CLOSE sales_type_cur;         
            
                -- do merchant type here 
                OPEN merchant_type_cur;
                FETCH merchant_type_cur INTO merchant_type_row;
           
                IF  (merchant_type_cur%FOUND) THEN 
                    v_tag_id := merchant_type_row.tag_id;
                ELSE
                    SELECT MAX(pos) INTO v_pos FROM tag_group_member WHERE tag_group_sid = v_merchant_type_tag_group_id;
                    tag_pkg.ADDNEWTAGTOGROUP(v_act, v_merchant_type_tag_group_id, lower(trim(product_row.business_centre)), lower(trim(product_row.business_centre)), v_pos + 1, 1, v_tag_id);
                END IF;
                product_pkg.SetProductTag(v_act, v_product_id, v_tag_id);   
                CLOSE merchant_type_cur;
         
                -- 3= paper type 
                product_pkg.SetProductTag(v_act, v_product_id, 3); 
                --product_pkg.SetProductTag(v_act, v_product_id, 1281);
            ELSE
                  select product_id into  v_product_id from product where product_code = product_row.item_code and app_sid = v_app_sid;
                 DBMS_OUTPUT.Put_Line('found prod - '|| v_product_id);
            end if;
            
             -- get wood_type
            OPEN wood_type_cur;
            FETCH wood_type_cur INTO wood_type_row;
           
            IF  (wood_type_cur%FOUND) THEN 
                v_wood_type := wood_type_row.wrme_wood_type_id;
            ELSE
                v_wood_type := 0; -- unknown - for import only 
            END IF;
            CLOSE wood_type_cur;
            
            DBMS_OUTPUT.Put_Line('- wood type ' || v_wood_type);

            OPEN wood_cur;
        
            FETCH wood_cur
            INTO wood_row;
            
            -- set all products to wood questionairre 
            --INSERT INTO PRODUCT_QUESTIONNAIRE (PRODUCT_ID, QUESTIONNAIRE_ID, QUESTIONNAIRE_STATUS_ID) VALUES (v_product_id , 1, 1);

            -- set last wood part name to blank - create a new wood part when desctiption changes 
            v_last_wood_part_name := '';  
        
            WHILE (wood_cur%FOUND)             
            LOOP            
            
                 v_this_wood_part_name := trim(lower(wood_row.part_name));
                 
                -- find out how many wood types in this product part 
                SELECT COUNT(*) INTO v_num_wood_for_part FROM wood_import_data WHERE product_id = product_row.product_id and lower(trim(part_name)) = v_this_wood_part_name;     
                SELECT COUNT(*) INTO v_num_wood_for_part_Ri FROM wood_import_data WHERE product_id = product_row.product_id and lower(trim(cert_type)) = 'ri' and lower(trim(part_name)) = v_this_wood_part_name;           
                SELECT COUNT(*) INTO v_num_wood_for_part_Rii FROM wood_import_data WHERE product_id = product_row.product_id and lower(trim(cert_type)) = 'rii' and lower(trim(part_name)) = v_this_wood_part_name;
                 
                 -- get species code if it exists 
                OPEN species_cur;
                FETCH species_cur INTO species_row;
           
                IF  (species_cur%FOUND) THEN 
                    v_species_code := species_row.species_code;
                ELSE
                    v_species_code := 'Un s'; -- unspecified 
                END IF;
                CLOSE species_cur;
                
                 -- get country code 
                OPEN country_cur;
                FETCH country_cur INTO country_row;
           
                IF  (country_cur%FOUND) THEN 
                    v_country_code := country_row.country_code;
                ELSE
                    v_country_code := 'UN'; -- unknown - for import only 
                END IF;
                CLOSE country_cur;
                
                 -- get cert scheme id 
                OPEN scheme_cur;
                FETCH scheme_cur INTO scheme_row;
           
                IF  (scheme_cur%FOUND) THEN 
                    v_cert_scheme_id := scheme_row.cert_scheme_id;
                ELSE
                    v_cert_scheme_id := 9; -- No Scheme  
                END IF;
                CLOSE scheme_cur;
                
                --DBMS_OUTPUT.Put_Line(' - this part name ' || v_this_wood_part_name);
            
                -- if the last part name is '' or different create a new part description 
                IF ((v_last_wood_part_name <> v_this_wood_part_name) OR (v_last_wood_part_name IS NULL)) THEN
                              
                    -- new part in the main system is created in call below                           
                    -- create new part description in the wood system 
                    part_description_pkg.CREATEPARTDESCRIPTION(
                        v_act, v_product_id, null, 
                        wood_row.part_name, wood_row.qty, wood_row.weight, 1, 
                        v_num_wood_for_part_Rii/v_num_wood_for_part*100, 
                        v_num_wood_for_part_Ri/v_num_wood_for_part*100, 
                        null, null, null, null, 'UN', 'UN', v_product_part_id);
                    DBMS_OUTPUT.Put_Line('Created part description ' || v_product_id);
                END IF;        
                
                -- don't create wood parts for recycled parts 
                IF (LOWER(wood_row.cert_type)) NOT LIKE '%ri%' THEN
                	-- create new wood part in the wood system  
                	part_wood_pkg.CREATEPARTWOOD(v_act, v_product_id, v_product_part_id, v_species_code, v_country_code, null, null, 1, v_wood_type, v_cert_scheme_id, v_wood_part_id);                     
                	DBMS_OUTPUT.Put_Line('Created wood part ' || v_wood_part_id);
                END IF;
                
                IF (LOWER(wood_row.cert_type)) = 'ri' THEN
                	UPDATE wood_part_description SET pre_recycled_country_code = v_country_code;
                	UPDATE wood_part_description SET pre_cert_scheme_id = v_cert_scheme_id;
                END IF;
                
                IF (LOWER(wood_row.cert_type)) = 'rii' THEN
                	UPDATE wood_part_description SET post_recycled_country_code = v_country_code;
                	UPDATE wood_part_description SET post_cert_scheme_id = v_cert_scheme_id;
                END IF;
                                
                -- update the name 
                v_last_wood_part_name := v_this_wood_part_name;
            
                FETCH wood_cur
                INTO wood_row;
            END LOOP;
            
            CLOSE wood_cur;

      
            FETCH product_cur
            INTO product_row;
        END LOOP;

        CLOSE product_cur;
	
END;

commit;


DROP TABLE PRODUCT_IMPORT_DATA PURGE;
DROP TABLE PRODUCT_IMPORT_MAPPING PURGE
DROP TABLE WOOD_IMPORT_DATA PURGE;

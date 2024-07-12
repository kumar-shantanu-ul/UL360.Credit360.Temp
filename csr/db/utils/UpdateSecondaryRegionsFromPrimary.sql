PROMPT Update Secondary regions from Primary Region
PROMPT 1) Enter current host name
define from_host = "&&1"

DECLARE
	v_from_host				csr.customer.host%TYPE := '&&from_host';
	v_count_regions			NUMBER := 0;
	v_count_tags			NUMBER := 0;
	v_count_descriptions	NUMBER := 0;
BEGIN
    security.user_pkg.LogonAdmin(v_from_host);

    -- Update secondary regions (ones with a link to a primary one) using the primary region data.
    FOR rec_cur IN (
      SELECT * FROM csr.region linkregion
      JOIN (
        SELECT  linkedregion.REGION_SID AS src_region_sid
               ,linkedregion.INFO_XML AS src_info_xml
               ,linkedregion.REGION_TYPE AS src_region_type
               ,linkedregion.GEO_TYPE AS src_geo_type
               ,linkedregion.GEO_COUNTRY AS src_geo_country
               ,linkedregion.GEO_LATITUDE AS src_geo_latitude
               ,linkedregion.GEO_LONGITUDE AS src_geo_longitude
               ,linkedregion.REGION_REF AS src_region_ref
          FROM csr.region linkedregion 
         WHERE linkedregion.REGION_SID IN (SELECT LINK_TO_REGION_SID FROM csr.region WHERE LINK_TO_REGION_SID IS NOT null)) 
        ON linkregion.LINK_TO_REGION_SID = src_region_sid
    ) LOOP
        --DBMS_OUTPUT.PUT_LINE('Updating ' || rec_cur.REGION_SID);
        v_count_regions:=v_count_regions+1;
        -- update the secondary region       
        UPDATE csr.region linkedregion2
           SET  linkedregion2.INFO_XML = rec_cur.src_info_xml
               ,linkedregion2.REGION_TYPE = rec_cur.src_region_type
               ,linkedregion2.GEO_TYPE = rec_cur.src_geo_type
               ,linkedregion2.GEO_COUNTRY = rec_cur.src_geo_country
               ,linkedregion2.GEO_LATITUDE = rec_cur.src_geo_latitude
               ,linkedregion2.GEO_LONGITUDE = rec_cur.src_geo_longitude
               ,linkedregion2.REGION_REF = rec_cur.src_region_ref
         WHERE REGION_SID = rec_cur.REGION_SID
          AND (INFO_XML NOT LIKE rec_cur.src_info_xml OR 
                REGION_TYPE != rec_cur.src_region_type OR
                GEO_TYPE != rec_cur.src_geo_type OR
                GEO_COUNTRY != rec_cur.src_geo_country OR
                GEO_LATITUDE != rec_cur.src_geo_latitude OR
                GEO_LONGITUDE != rec_cur.src_geo_longitude OR
                REGION_REF != rec_cur.src_region_ref
                );

       -- Remove all the tags for the linked region
       DELETE FROM csr.region_tag
       WHERE REGION_SID = rec_cur.REGION_SID;

        -- Get the tags for the source region and populate the linked region to match
       FOR tags_cur IN (SELECT * FROM csr.region_tag linkregiontag WHERE REGION_SID = rec_cur.src_region_sid) 
       LOOP
          --DBMS_OUTPUT.PUT_LINE('Add region ' || rec_cur.src_region_sid || ' tag ' || tags_cur.TAG_ID || ' to linked region ' || rec_cur.REGION_SID);
			v_count_tags:=v_count_tags+1;

            BEGIN
                INSERT INTO csr.region_tag (APP_SID, TAG_ID, REGION_SID) 
                     VALUES (tags_cur.APP_SID, tags_cur.TAG_ID, rec_cur.REGION_SID);
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                v_count_tags:=v_count_tags-1;
            END;

       END LOOP;
	
		-- Update any dynamic delegation plans that depend on this region
		csr.region_pkg.ApplyDynamicPlans(rec_cur.REGION_SID, 'Region tags changed');

      -- Remove all the language variants for the linked region
       DELETE FROM csr.region_description
       WHERE REGION_SID = rec_cur.REGION_SID;

        -- Get the descriptions for the source region and populate the linked region to match
       FOR desc_cur IN (SELECT * FROM csr.region_description linkregiondesc WHERE REGION_SID = rec_cur.src_region_sid) 
       LOOP
          --DBMS_OUTPUT.PUT_LINE('Add region ' || rec_cur.src_region_sid || ' descr ' || desc_cur.DESCRIPTION || ' to linked region ' || rec_cur.REGION_SID);
        	v_count_descriptions:=v_count_descriptions+1;

          BEGIN
              INSERT INTO csr.region_description (APP_SID, REGION_SID, LANG, DESCRIPTION) 
                   VALUES (desc_cur.APP_SID, rec_cur.REGION_SID, desc_cur.LANG, desc_cur.DESCRIPTION);
          EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
              v_count_descriptions:=v_count_descriptions-1;
          END;

       END LOOP;

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Updated ' || v_count_regions || ' regions, ' || v_count_descriptions || ' descriptions and ' || v_count_tags || ' tags.');
	
END;
/

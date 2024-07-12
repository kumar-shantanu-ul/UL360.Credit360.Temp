SET VERIFY OFF
SET SERVEROUTPUT ON
/*
 To set the acquisition date(s) for given region(s).
 Initialize v_region_sids with list of region_sids and v_acquisition_dtms with acquisition/open dates.
*/
DECLARE
	TYPE T_REGION_SIDS		IS TABLE OF security.security_pkg.T_SID_ID;
	TYPE T_AQ_DTMS			IS TABLE OF csr.region.acquisition_dtm%TYPE;
	
	v_region_sids			T_REGION_SIDS;
	v_acquisition_dtms		T_AQ_DTMS;
	
	v_act_id				security.security_pkg.T_ACT_ID;
	v_region_sid			security.security_pkg.T_SID_ID;
	v_name					csr.region.name%TYPE;
	v_description			csr.region_description.description%TYPE;
	v_parent_sid			security.security_pkg.T_SID_ID;
	v_pos					csr.region.pos%TYPE;
	v_info_xml				CLOB;
	v_active				csr.region.active%TYPE;
	v_link_to_region_sid	security.security_pkg.T_SID_ID;
	v_region_type			csr.region.region_type%TYPE;
	v_parent_region_type	csr.region.region_type%TYPE;
	link_to_region_path		VARCHAR2(1000);
	v_geo_latitude			csr.region.geo_latitude%TYPE;
	v_geo_longitude			csr.region.geo_longitude%TYPE;
	v_geo_country			csr.region.geo_country%TYPE;
	v_geo_region			csr.region.geo_region%TYPE;
	v_geo_city				csr.region.geo_city_id%TYPE;
	v_map_entity			csr.region.map_entity%TYPE;
	v_egrid_ref				csr.region.egrid_ref%TYPE;
	v_geo_type         		csr.region.geo_type%TYPE;
	v_disposal_dtm			csr.region.acquisition_dtm%TYPE;
	v_acquisition_dtm		csr.region.acquisition_dtm%TYPE;
	v_lookup_key			csr.region.lookup_key%TYPE;
	v_region_ref			csr.region.region_ref%TYPE;
	
	OUT_CUR					security.security_pkg.T_OUTPUT_CUR;
BEGIN
	-- Initialize with region_sids to be updated
	v_region_sids := T_REGION_SIDS(
		/* Region_sid goes here */
	);
	-- Initialize with respective acquisition dates to be set to
	v_acquisition_dtms := T_AQ_DTMS(
		/* Disposal_dtm goes here */
	);
	
	IF v_region_sids.COUNT != v_acquisition_dtms.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'No of regions doesn''t match no of acquisition dates');
	END IF;
	
	security.user_pkg.logonadmin('&host');
	v_act_id := security.security_pkg.GetACT;
	
	FOR r IN 1..v_region_sids.COUNT
	LOOP
		IF v_region_sids(r) IS NULL OR v_acquisition_dtms(r) IS NULL THEN
			SYS.dbms_output.put_line('Failed to update region, region_sid or acquisition date is null.');
		ELSE
			csr.region_pkg.GetRegion(v_act_id, v_region_sids(r), OUT_CUR);
			LOOP
				FETCH OUT_CUR 
				 INTO v_region_sid, v_name, v_description, v_parent_sid, v_pos, v_info_xml,
					  v_active, v_link_to_region_sid, v_region_type, v_parent_region_type,
					  link_to_region_path, v_geo_latitude, v_geo_longitude,
					  v_geo_country, v_geo_region, v_geo_city, v_map_entity, v_egrid_ref, v_geo_type,
					  v_disposal_dtm, v_acquisition_dtm, v_lookup_key, v_region_ref;
				EXIT WHEN OUT_CUR%NOTFOUND;
				SYS.dbms_output.put_line('Updating Region ' || v_region_sids(r) || ', Acquisition Date -> ' || v_acquisition_dtms(r));
				csr.region_pkg.AmendRegion(
					v_act_id, v_region_sid, v_description, v_active, v_pos, v_geo_type,
					CASE WHEN v_info_xml is null THEN null ELSE XMLTYPE(v_info_xml) END,
					v_geo_country, v_geo_region, v_geo_city, v_map_entity,
					v_egrid_ref, v_region_ref, v_acquisition_dtms(r), v_disposal_dtm, v_region_type
				);
			END LOOP;
		END IF;
	END LOOP;
	COMMIT;
END;
/
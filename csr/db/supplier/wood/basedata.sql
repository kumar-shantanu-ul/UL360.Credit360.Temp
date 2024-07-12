spool C:\cvs\csr\db\supplier\create_db.log app

SET SERVEROUTPUT ON;


PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE ON;

BEGIN

    BEGIN
        INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description) values (1, 'wood', 'Wood', 'wood');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN  
            null; -- just in case clean is run multiple times
    END;

    BEGIN
        INSERT INTO SUPPLIER.part_type (part_type_id, class_name, package) values (1, 'PART_DESCRIPTION', 'part_description_pkg');
        INSERT INTO SUPPLIER.part_type (part_type_id, class_name, package) values (2, 'PART_WOOD', 'part_wood_pkg');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN  
            null; -- just in case clean is run multiple times
    END;

    INSERT INTO SUPPLIER.bleaching_process (bleaching_process_id, name) values (1, 'Unknown');
    INSERT INTO SUPPLIER.bleaching_process (bleaching_process_id, name) values (2, 'Totally Chlorine Free (TCF)');
    INSERT INTO SUPPLIER.bleaching_process (bleaching_process_id, name) values (3, 'Elemental Chlorine Free (ECF)');
    INSERT INTO SUPPLIER.bleaching_process (bleaching_process_id, name) values (4, 'Other bleaching method');
    INSERT INTO SUPPLIER.bleaching_process (bleaching_process_id, name) values (5, 'Unbleached');

    --INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (0, 'Unspecified', 'Unspecified', 1);
    INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (1, 'Wood', 'Manufactured product non-pulp (general)', 3.8);
    INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (2, 'Paper', 'Paper (other) and board', 4.3);
    INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (3, 'Pulp/Fluff Pulp', 'Pulp products (general)', 3.7);
    INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (4, 'Recycled', 'Paper (recycled)', 3.5);
    INSERT INTO SUPPLIER.wrme_wood_type (wrme_wood_type_id, description, explanation, factor_per_metric_ton) VALUES (5, 'Med. density fibreboard (MDF)', 'Fibreboard (non compressed)', 2.5);
    
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('1', 'Limited knowledge of source');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('2', 'Source Assessed');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('3', 'Source Verified');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('4', 'Credibly Certified');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('RI', 'Recycled pre-consumer');
    INSERT INTO SUPPLIER.forest_source_cat (forest_source_cat_code, name) values ('RII', 'Recycled post-consumer');

    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (1, 'Unknown', 'Unknown', '2', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (2, 'Certfor', 'Certfor', '3', '1');
    --INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (3, 'Cerflor', 'Cerflor', '3', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (4, 'CSA', 'CSA', '3', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (5, 'FSC', 'FSC', '4', '4');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc, allow_user_select) values (6, 'FSC Recycled', 'FSC Recycled', 'RII', 'RII', 0);
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (7, 'LEI', 'LEI', '3', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (8, 'MTCC', 'MTCC', '3', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (9, 'No Certification Scheme', 'No Certification Scheme', '2', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (10, 'PEFC', 'PEFC', '3', '3');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (11, 'SFI', 'SFI', '3', '1');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (12, 'SGS CSP', 'SGS CSP', '3', '2');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (13, 'TFT', 'TFT', '3', '2');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (14, 'Verified 1st Party', 'Verified 1st Party', '2', '2');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (15, 'Verified 2nd Party', 'Verified 2nd Party', '3', '3');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (16, 'Verified 3rd Party', 'Verified 3rd Party', '3', '3');
    INSERT INTO SUPPLIER.cert_scheme (cert_scheme_id, name, description, verified_fscc, non_verified_fscc) values (17, 'WWF Producer Group', 'WWF Producer Group', '3', '2');
	
	UPDATE supplier.country SET means_verified = 0 WHERE lower(country_code) = ('un');

	UPDATE supplier.tree_species SET means_verified = 0 WHERE lower(species_code) = ('un s');
	
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RI', 1);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RI', 9);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RI', 14);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RI', 15);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RI', 16);
	
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 1);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 5);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 9);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 14);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 15);
	INSERT INTO SUPPLIER.RECYC_FSCC_CS_MAP (FOREST_SOURCE_CAT_CODE, CERT_SCHEME_ID) VALUES ('RII', 16);

END;
/


PROMPT > running wwf_species_import...
@wwf_species_import



commit;

exit;
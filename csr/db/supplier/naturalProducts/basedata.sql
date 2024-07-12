spool C:\cvs\csr\db\supplier\create_db.log app

SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE ON;

BEGIN
    BEGIN
        INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description) values (2, 'naturalProduct', 'Natural Products', 'Natural Products');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN  
            null; -- just in case clean is run multiple times
    END;
         
    BEGIN
        INSERT INTO SUPPLIER.part_type (part_type_id, class_name, package) values (3, 'NP_PART_DESCRIPTION', 'natural_product_part_pkg');
        INSERT INTO SUPPLIER.part_type (part_type_id, class_name, package) values (4, 'NP_COMPONENT_DESCRIPTION', 'natural_product_component_pkg');
        INSERT INTO SUPPLIER.part_type (part_type_id, class_name, package) values (5, 'NP_PART_EVIDENCE_DESCRIPTION', 'natural_product_evidence_pkg');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN  
            null; -- just in case clean is run multiple times
    END;

    INSERT INTO SUPPLIER.NP_KINGDOM (NP_KINGDOM_ID, NAME, DESCRIPTION) VALUES ( 1, 'Flora', 'Flora');
    INSERT INTO SUPPLIER.NP_KINGDOM (NP_KINGDOM_ID, NAME, DESCRIPTION) VALUES ( 2, 'Fauna', 'Fauna');
    INSERT INTO SUPPLIER.NP_KINGDOM (NP_KINGDOM_ID, NAME, DESCRIPTION) VALUES ( 3, 'Fungi', 'Fungi');

    INSERT INTO SUPPLIER.NP_EVIDENCE_TYPE (NP_EVIDENCE_TYPE_ID, NAME, DESCRIPTION) VALUES (1 , 'Certification Scheme', 'Certification Scheme');
    INSERT INTO SUPPLIER.NP_EVIDENCE_TYPE (NP_EVIDENCE_TYPE_ID, NAME, DESCRIPTION) VALUES (2 , 'Export Certificate', 'Export Certificate');
    INSERT INTO SUPPLIER.NP_EVIDENCE_TYPE (NP_EVIDENCE_TYPE_ID, NAME, DESCRIPTION) VALUES (3 , 'Other', 'Other');
    INSERT INTO SUPPLIER.NP_EVIDENCE_TYPE (NP_EVIDENCE_TYPE_ID, NAME, DESCRIPTION) VALUES (4 , 'None', 'None');
	
	INSERT INTO SUPPLIER.NP_EVIDENCE_CLASS (NP_EVIDENCE_CLASS_ID, NAME, DESCRIPTION) VALUES (1, 'Species', 'Species');
	INSERT INTO SUPPLIER.NP_EVIDENCE_CLASS (NP_EVIDENCE_CLASS_ID, NAME, DESCRIPTION) VALUES (2, 'Growing / Harvesting', 'Growing / Harvesting');
	INSERT INTO SUPPLIER.NP_EVIDENCE_CLASS (NP_EVIDENCE_CLASS_ID, NAME, DESCRIPTION) VALUES (3, 'Processing', 'Processing');
	INSERT INTO SUPPLIER.NP_EVIDENCE_CLASS (NP_EVIDENCE_CLASS_ID, NAME, DESCRIPTION) VALUES (4, 'Final Product Production', 'Final Product Production');
	
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (1,'Anion exchange','Anion exchange');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (2,'Bleaching - with chemical addition','Bleaching - with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (3,'Cation exchange','Cation exchange');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (4,'Conversion - with chemical addition or synthesis','Conversion - with chemical addition or synthesis');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (5,'Curing - with chemical addition','Curing - with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (6,'Decaffeination - with chemical addition','Decaffeination - with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (7,'Enzymolysis','Enzymolysis');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (8,'Esterification','Esterification');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (9,'Hormonal action','Hormonal action');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (10,'Hydrogenation','Hydrogenation');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (11,'Hydrolysis - with chemical addition','Hydrolysis - with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (12,'Interesterification','Interesterification');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (13,'Oxidation - with chemical addition','Oxidation - with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (14,'Reduction -  with chemical addition','Reduction -  with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (15,'Smoking -  with chemical addition','Smoking -  with chemical addition');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (16,'Synthesis - chemical','Synthesis - chemical');
    INSERT INTO SUPPLIER.NP_PRODUCTION_PROCESS (NP_PRODUCTION_PROCESS_ID, NAME, DESCRIPTION)  VALUES (17,'Tenderising -  with chemical addition','Tenderising -  with chemical addition');
END;
/

commit;

exit;
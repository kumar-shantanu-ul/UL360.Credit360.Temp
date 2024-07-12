spool C:\cvs\csr\db\supplier\greentick\basedata_db.log app

SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 


SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(10	,'gtFormulation',	'Formulation',		'Formulation',		'gt_formulation_pkg');

EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/	
	
BEGIN
-- gt_ancillary_material
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (1, 'Water', 1,1 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (2, 'Reusable Items (e.g. Comb)', 1,2 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (3, 'Cotton Wool', 2,3 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (4, 'Wipes', 2,4 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (5, 'Tissue ', 2,5 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (6, 'Pads, Puffs Etc.', 2,6 ); -- score is a guess
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (7, 'Spatula (Disposable)', 2,7 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (8, 'Gloves (Disposable)', 2,8 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (9, 'Electrical Items (e.g. Hair Dryers)', 2,9 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (10, 'Soap', 3,10 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (11, 'Surfactants', 3,11 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (12, 'Cleansers', 3,12 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (13, 'Solvents', 5,13 );
	INSERT INTO SUPPLIER.gt_ancillary_material (gt_ancillary_material_id, description, gt_score, pos) VALUES (14, 'Nail Polish Remover', 5,14 );
END;
/

--gt_hazzard_chemical
BEGIN
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (1,'Alcohol >15% (Non aerosol products)','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (2,'Alcohol - Aerosols >80%','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (3,'Cetrimonium chloride ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (4,'Cyclopentasiloxane ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (5,'Diethylhexyl butamido triazone ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (6,'Myrtrimonium bromide ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (7,'Isohexadecane ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (8,'Isotridecyl salicylate ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (9,'Octyldodecanol ','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (10,'Triclosan','R');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (11,'Zinc pyrithione ','R');
	
	
	
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (12,'Allantoin ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (13,'Alcohol in aerosols between      (55% - 80%)','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (14,'Aluminum chlorohydrate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (15,'C12-15 alkyl benzoate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (16,'Cocamidopropyl betaine ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (17,'Cyclohexasiloxane ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (18,'Caprylic/capric triglyceride          ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (19,'Dicalcium phosphate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (20,'Ethylhexyl stearate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (21,'Ethyl butylacetylamino propionate  ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (22,'Ethylhexyl salicylate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (23,'Glycol stearate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (24,'Laureth-7 ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (25,'Laureth-4 ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (26,'Magnesium stearate ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (27,'Methylene bisbenzotriazoyl tetramethylbutylphenol  ','O');
	INSERT INTO SUPPLIER.gt_hazzard_chemical (gt_hazzard_chemical_id, description, colour) VALUES (28,'Sorbitan stearate ','O');

	-- I had the update script so didn't bother amalgamating - same thing in the end	
	-- red 
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '64-17-5 3', ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 1;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = null, ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 2;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '112-02-7 7', ENV_EFFECT='High usage and potent experimental ecotoxicity value' WHERE gt_hazzard_chemical_id = 3;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '541-02-6 3', ENV_EFFECT='High usage and potent ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 4;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = null, ENV_EFFECT='Very potent estimate of ecotoxicity / Extremely high estimated partitioning to sludge and extremely potent daphnid ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 5;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '1119-97-7', ENV_EFFECT='Very potent experimental ecotoxicity ' WHERE gt_hazzard_chemical_id = 6;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '4390-04-9;60908-77-2', ENV_EFFECT=' High usage very potent estimate of ecotoxicity / high estimated partitioning to sludge' WHERE gt_hazzard_chemical_id = 7;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '19666-16-1', ENV_EFFECT='High usage and very potent estimate of ecotoxicity' WHERE gt_hazzard_chemical_id = 8;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '5333-42-6 3', ENV_EFFECT='Potent default ecotoxicity used' WHERE gt_hazzard_chemical_id = 9;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '3380-34-5', ENV_EFFECT='Very toxic to aquatic organisms' WHERE gt_hazzard_chemical_id = 10;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '13463-41-7', ENV_EFFECT='High partitioning to water and very potent experimental ecotoxicity' WHERE gt_hazzard_chemical_id = 11;
	
	
	--orange 
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '97-59-6 3', ENV_EFFECT='Default daphnid ecotoxicity value used ' WHERE gt_hazzard_chemical_id = 12;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '64-17-5 3', ENV_EFFECT='High usage and high experimental partitioning to aqueous phase ' WHERE gt_hazzard_chemical_id = 13;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '12042-91-0', ENV_EFFECT='Potent default ecotoxicity used' WHERE gt_hazzard_chemical_id = 14;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '68411-27-8 3', ENV_EFFECT='High usage and potent estimated ecotoxicity' WHERE gt_hazzard_chemical_id = 15;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '61789-40-0', ENV_EFFECT='High usage  ' WHERE gt_hazzard_chemical_id = 16;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '540-97-6 3', ENV_EFFECT='High usage and potent ecotoxicity estimate Collate ' WHERE gt_hazzard_chemical_id = 17;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '65381-09-1;73398-61-5', ENV_EFFECT='High usage limited data on constituents and constituent composition, high partitioning estimates to sludge and soil and high earthworm ecotoxicity estimates' WHERE gt_hazzard_chemical_id = 18;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '7789-77-7 4', ENV_EFFECT='Potent default ecotoxicity used ' WHERE gt_hazzard_chemical_id = 19;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '22047-49-0 3', ENV_EFFECT='High usage high estimated partitioning to sludge and potent earthworm ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 20;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '52304-36-6', ENV_EFFECT='High usage and high partitioning to water and moderate ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 21;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '118-60-5', ENV_EFFECT='High usage potent experimental ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 22;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '111-60-4 3', ENV_EFFECT='High usage and potent ecotoxicity estimate / potent daphnid ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 23;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '3055-97-8 3', ENV_EFFECT='High estimated partitioning to water and potent default ecotoxicity estimate used' WHERE gt_hazzard_chemical_id = 24;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '5274-68-0', ENV_EFFECT='Default daphnid ecotoxicity value used ' WHERE gt_hazzard_chemical_id = 25;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '557-04-0', ENV_EFFECT='Potent default ecotoxicity used ' WHERE gt_hazzard_chemical_id = 26;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '103597-45-1', ENV_EFFECT='High usage extremely high estimated partitioning to sludge and high potent earthworm ecotoxicity estimate' WHERE gt_hazzard_chemical_id = 27;
	UPDATE GT_HAZZARD_CHEMICAL SET CAS_NUMBER = '1338-41-6 3', ENV_EFFECT='Potent ecotoxicity ' WHERE gt_hazzard_chemical_id = 28;
	--

END;
/

begin
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (1,  6,  'Brazil Nut', 'Medium', 'Bertholletia excelsa', 'UCN Redlist Classification - Vulnerable.  Category and Criteria ver A1a,c,d & 2c,d #Community traded/sustainable sourced offer the best chance of survival/viability.Classification seems to stem from uncertainty about long term viability of the harvest if rainforest logging increases.  #Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (2,  5,  'Ginkgo', 'Low', 'Ginkgo biloba', 'IUCN Redlist Classification - Endangered.  Category and Criteria ver B1&2c#Wild population is very confined.  Cultivated crops in other areas are not affected - confirmed by Kew.#Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (3,  6,  'Ginseng', 'High if from Russia, otherwise low', 'Panax ginseng', 'IUCN Redlist Classification - Not Classified.#CITES Appendix II (Threatened).#Only the populations of the Russian Federation; no other population is included in the Appendices.  Source from outside Russia and avoid uncontrolled wild harvest.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (4,  5,  'Juniper', 'Low', 'Juniper communis', 'IUCN Redlist Classification - Lower risk/least concern.  Category and Criteria ver 2.3#Only the nipponica variety is classified all other varieties are not threatened.#Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (5,  5,  'Mango', 'Low', 'Mangifera indica', 'IUCN Redlist Classification - Data Deficient. Category and Criteria ver 2.3#Wide ranging cultivated crop - wild populations in eastern India may be cuase for concern.#Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (6,  5,  'Pomegranate', 'Low', 'Punica granatum', 'IUCN Redlist Classification - Least concern.  Category and Criteria ver 3.1#Not believed to be approaching population decline (of >30% in 10years/3 generations - Redlist inclusion criteria), but livestock grazing is a threat in some territories.#Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (7,  6,  'Walnut', 'High if from Asia, Medium from other sources', 'Juglans regia', 'IUCN Redlist Classification - Near Threatened. Category and Criteria ver 3.1#Harvest of wild populations in its natural range (Central Asia) is a reason for classification, other threats include livestock grazing and tree cutting#Not classified under CITES.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (8,  5,  'Gelatin / Tallow / stearates', 'Low', '', 'Verifiable bioproducts only#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (9,  10,  'Cochineal', 'High', 'Dactylopius coccus', 'Sourced from beetle species. Used in many colours eg: carmines. Not included in IUCN Red List or CITES Appendices but growing public opinion against its use.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (10, 5,  'Collagen', 'Low', 'Terrestrial Animals', 'Mostly agricultural bovine sources, #');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (11, 6,  'Collagen', 'Medium', 'Marine - Cod', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (12, 10,  'Collagen', 'High', 'Marine - Shark', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (13, 6,  'Fish Oils', 'Medium', 'Cod / South pacific Sardine', 'Worries about dioxin/PCB/PAH/BFR contamination should continue to look at alternative sources for Omega oils.#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (14, 6,  'Chitosan', 'Medium', '', 'Shellfish are primary sources. Some concern abour irresponsible farming / harvesting methods#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (15, 6,  'Glucosamine', 'Medium', '', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (16, 6,  'Condroitin', 'Medium', '', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (17, 10,  'Fragrances - Musks', 'High', 'Civet cat', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (18, 6,  'Wax, Honey , Royal jelly, Propolis', 'Green', 'Bees', '#');
  INSERT INTO SUPPLIER.gt_endangered_species (gt_endangered_species_id, risk_score, description, risk_level, details, notes) values (19, 6,  'Fossil Waxes', 'High', 'Fossil minerals', 'Mineral sources very rare#');
end;
/

INSERT INTO SUPPLIER.gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) 
	SELECT 1, gt_endangered_species_id FROM gt_endangered_species;
	
INSERT INTO SUPPLIER.gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) 
	SELECT 2, gt_endangered_species_id FROM gt_endangered_species;
	
INSERT INTO SUPPLIER.gt_endangered_prod_class_map (gt_product_class_id, gt_endangered_species_id) 
	SELECT 3, gt_endangered_species_id FROM gt_endangered_species;

begin
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (1,'Elaeis Guineensis (Palm Oil)', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (2,'Hydrogenated palm oil', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (3,'Hydrogenated palm glycerides', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (4,'isomerised palm oil', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (5,'Elaeis Guineensis (Palm kernel oil)', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (6,'Hydrogenated palm kernel oil', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (7,'Hydrogenated palm kernel glycerides', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (8,'Palm kernel wax', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (9,'Palm kernel glycerides', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (10,'Palm kernel acid', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (11,'Palm kernel alcohol', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (12,'Palm acid', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (13,'Palm glycerides', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (14,'Palm alcohol', 1);
  INSERT INTO SUPPLIER.gt_palm_ingred (gt_palm_ingred_id, description, palm_confirmed) values (15,'Hydrogenated palm acid', 1);
end;
/

begin
-- INSERT water stressed regions BASE DATA
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (1, 1,'California', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (2, 2,'Southern Amazon (Peru, Bolivia, S Brazil)', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (3, 3,'Southern Russian states, Ukraine, Turkey', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (4, 4,'Middle East & Morocco, Algeria, Tunisia, Egypt, Libya', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (5, 5,'Sub Saharan Africa (Somalia, Ethiopia,Niger, Chad, Mali)', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (6, 6,'Northern India', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (7, 7,'China', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (8, 8,'Australia', 0.2);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (9, 9,'None of These', 0);
	INSERT INTO SUPPLIER.gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (10, 10, 'Unknown', 0.2);
end;
/

commit;
exit;
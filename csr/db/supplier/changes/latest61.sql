-- Please update version.sql too -- this keeps clean builds in sync
define version=61
@update_header

set define off;

delete from gt_endangered_species;

insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (1,'Brazil Nut', 'Medium', 'Bertholletia excelsa', 'UCN Redlist Classification - Vulnerable.  Category and Criteria ver A1a,c,d & 2c,d #Community traded/sustainable sourced offer the best chance of survival/viability.Classification seems to stem from uncertainty about long term viability of the harvest if rainforest logging increases.  #Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (2,'Ginkgo', 'Low', 'Ginkgo biloba', 'IUCN Redlist Classification - Endangered.  Category and Criteria ver B1&2c#Wild population is very confined.  Cultivated crops in other areas are not affected - confirmed by Kew.#Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (3,'Ginseng', 'High if from Russia, otherwise low', 'Panax ginseng', 'IUCN Redlist Classification - Not Classified.#CITES Appendix II (Threatened).#Only the populations of the Russian Federation; no other population is included in the Appendices.  Source from outside Russia and avoid uncontrolled wild harvest.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (4,'Juniper', 'Low', 'Juniper communis', 'IUCN Redlist Classification - Lower risk/least concern.  Category and Criteria ver 2.3#Only the nipponica variety is classified all other varieties are not threatened.#Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (5,'Mango', 'Low', 'Mangifera indica', 'IUCN Redlist Classification - Data Deficient. Category and Criteria ver 2.3#Wide ranging cultivated crop - wild populations in eastern India may be cuase for concern.#Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (6,'Pomegranate', 'Low', 'Punica granatum', 'IUCN Redlist Classification - Least concern.  Category and Criteria ver 3.1#Not believed to be approaching population decline (of >30% in 10years/3 generations - Redlist inclusion criteria), but livestock grazing is a threat in some territories.#Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (7,'Walnut', 'High if from Asia, Medium from other sources', 'Juglans regia', 'IUCN Redlist Classification - Near Threatened. Category and Criteria ver 3.1#Harvest of wild populations in its natural range (Central Asia) is a reason for classification, other threats include livestock grazing and tree cutting#Not classified under CITES.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (8,'Gelatin / Tallow / stearates', 'Low', '', 'Verifiable bioproducts only#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (9,'Cochineal', 'High', 'Dactylopius coccus', 'Sourced from beetle species. Used in many colours eg: carmines. Not included in IUCN Red List or CITES Appendices but growing public opinion against its use.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (10,'Collagen', 'Low', 'Terrestrial Animals', 'Mostly agricultural bovine sources, #');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (11,'Collagen', 'Medium', 'Marine - Cod', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (12,'Collagen', 'High', 'Marine - Shark', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (13,'Fish Oils', 'Medium', 'Cod / South pacific Sardine', 'Worries about dioxin/PCB/PAH/BFR contamination should continue to look at alternative sources for Omega oils.#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (14,'Chitosan', 'Medium', '', 'Shellfish are primary sources. Some concern abour irresponsible farming / harvesting methods#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (15,'Glucosamine', 'Medium', '', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (16,'Condroitin', 'Medium', '', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (17,'Fragrances - Musks', 'High', 'Civet cat', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (18,'Wax, Honey , Royal jelly, Propolis', 'Green', 'Bees', '#');
insert into gt_endangered_species (gt_endangered_species_id, description, risk_level, details, notes) values (19,'Fossil Waxes', 'High', 'Fossil minerals', 'Mineral sources very rare#');

update GT_SUS_RELATION_TYPE set description='Supplier known to Boots, not yet Audited' where GT_SUS_RELATION_TYPE_ID=4;


commit;

@update_tail

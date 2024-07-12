-- Please update version.sql too -- this keeps clean builds in sync
define version=3443
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE csr.temp_certification
(
	certification_id			NUMBER(10,0) NOT NULL,
	certification_type_id		NUMBER(10,0) NOT NULL,
	external_id					VARCHAR2(255) NOT NULL,
	name						VARCHAR2(255)
)
ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE csr.temp_certification_level
(
	certification_level_id		NUMBER(10,0) NOT NULL,
	certification_id			NUMBER(10,0) NOT NULL,
	position					NUMBER(10,0) NOT NULL,
	name						VARCHAR2(255)
)
ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE csr.temp_energy_rating
(
	energy_rating_id			NUMBER(10,0) NOT NULL,
	certification_type_id		NUMBER(10,0) NOT NULL,
	external_id					NUMBER(10,0) NOT NULL,
	name						VARCHAR2(255)
)
ON COMMIT DELETE ROWS;
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1139, 1, 1139, '2000-Watt/Site - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1140, 1, 1140, '2000-Watt/Site - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (585, 1, 585, 'ABINC Certification/Urban Development and Shopping Centre');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1106, 1, 1106, 'ActiveScore/ActiveScore');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1148, 1, 1148, 'AirRated/AirScore');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1149, 1, 1149, 'AirRated/AirScore D'||chr(38)||'O');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1219, 1, 1219, 'AIS (Accessibility Indicator System)/AIS 1/2018 Standard');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1142, 1, 1142, 'ARCA/Nuove Costruzioni');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1092, 1, 1092, 'Arc/Performance Certificates - 3');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1211, 1, 1211, 'Association Promotelec/Habitat Neuf');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (895, 1, 895, 'Austin Energy/Austin Energy Green Building - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1172, 1, 1172, 'BASIX/BASIX');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1147, 1, 1147, 'BBCA/BBCA');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1164, 1, 1164, 'BBCA/BBCA - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (598, 1, 598, 'BCA Green Mark/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1214, 1, 1214, 'BCA Green Mark/Healthier Workplaces - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1215, 1, 1215, 'BCA Green Mark/Healthier Workplaces - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (567, 1, 567, 'BCA Green Mark/New Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (901, 1, 901, 'BEAM Plus/Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1105, 1, 1105, 'BEAM Plus/Existing Building - Selective Scheme');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (3, 1, 3, 'BEAM Plus/Interior');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (898, 1, 898, 'BEAM Plus/New Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (6, 1, 6, 'BERDE/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (183, 1, 183, 'BERDE/Operations');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (7, 1, 7, 'BERDE/Retrofits and Renovations');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1184, 1, 1184, 'BIT Building/BIT Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (186, 1, 186, 'BOMA/360');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (541, 1, 541, 'BOMA/BEST');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1112, 1, 1112, 'BOMA/China - Certificate of Excellence');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (354, 1, 354, 'BRaVe/Building RAting ValuE');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (251, 1, 251, 'BREEAM/Code for Sustainable Homes');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (586, 1, 586, 'BREEAM/Domestic Refurbishment');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (997, 1, 997, 'BREEAM/Home Quality Mark');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (691, 1, 691, 'BREEAM/In Use');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (966, 1, 966, 'BREEAM/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1216, 1, 1216, 'BREEAM-NOR/BREEAM-NOR New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (692, 1, 692, 'BREEAM/Refurbishment and Fit-out');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (583, 1, 583, 'Build it Green/GreenPoint Rated, Existing Home');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (765, 1, 765, 'Build it Green/GreenPoint Rated, New Home');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (695, 1, 695, 'Built Green/Built Green');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (998, 1, 998, 'CALGreen/CALGreen');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1188, 1, 1188, 'CarbonCare Label/CarbonCare Label');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1146, 1, 1146, 'CasaClima/Nature');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (188, 1, 188, 'CASBEE/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (699, 1, 699, 'CASBEE/for Market Promotion');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (941, 1, 941, 'CASBEE/for Real Estate');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (988, 1, 988, 'CASBEE/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (16, 1, 16, 'CASBEE/Renovation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1116, 1, 1116, 'CASBEE/Wellness Office - Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1115, 1, 1115, 'CASBEE/Wellness Office - New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (832, 1, 832, 'CEEDA/Design-Operate');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (702, 1, 702, 'Certified Rental Building Program/Certified Rental Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1210, 1, 1210, 'Certiv'||UNISTR('\00E9')||'a/The E+C- Label');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (982, 1, 982, 'China Green Building Label/GB/T 50378-2014 - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1096, 1, 1096, 'China Green Building Label/GB/T 50378-2014 - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1150, 1, 1150, 'China Green Warehouses/China Green Warehouses');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1117, 1, 1117, 'Cleaning Accountability Framework/CAF Building Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (340, 1, 340, 'DBJ Green Building Certification/DBJ Green Building Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (925, 1, 925, 'DBJ Green Building Certification/DBJ Green Building Certification - Plan Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (975, 1, 975, 'DGBC Woonmerk/Woon Kwaliteit Richtlijn');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1129, 1, 1129, 'DGNB/Buildings In Use');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (78, 1, 78, 'DGNB/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (571, 1, 571, 'DGNB/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1130, 1, 1130, 'DGNB/Renovation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1223, 1, 1223, 'Earth Advantage/Earth Advantage Multifamily');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (303, 1, 303, 'EarthCheck/Sustainable Design');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (703, 1, 703, 'EarthCraft/EarthCraft');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (984, 1, 984, 'EDGE/EDGE - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1180, 1, 1180, 'EDGE/EDGE - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1145, 1, 1145, 'Energy Star/Residential New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (625, 1, 625, 'Enterprise Green Communities/Enterprise Green Communities');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1094, 1, 1094, 'Fitwel/Fitwel - Built');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1002, 1, 1002, 'Fitwel/Fitwel - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1128, 1, 1128, 'Fitwel/Viral Response');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (711, 1, 711, 'Florida Green Building Certification/Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1097, 1, 1097, 'Florida Green Building Certification/Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1201, 1, 1201, 'GBC Italia/Condomini - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1202, 1, 1202, 'GBC Italia/Condomini - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1198, 1, 1198, 'GBC Italia/Historic Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1200, 1, 1200, 'GBC Italia/Home V2');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1199, 1, 1199, 'GBC Italia/Quartieri');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (906, 1, 906, 'GPR Gebouw/GPR Gebouw - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1103, 1, 1103, 'GPR Gebouw/GPR Gebouw - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (889, 1, 889, 'Green Building Index (GBI)/Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (859, 1, 859, 'Green Building Index (GBI)/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (190, 1, 190, 'Green Globes/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (93, 1, 93, 'Green Globes/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1008, 1, 1008, 'Green Globes/Sustainable Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (192, 1, 192, 'Green Key/Eco-Rating Program');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1118, 1, 1118, 'Green Key International/Ecolabel');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (973, 1, 973, 'Green Rating/Green Rating Remote Assessment');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1177, 1, 1177, 'GreenRE/GreenRE - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1178, 1, 1178, 'GreenRE/GreenRE - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (194, 1, 194, 'Green Seal/Hotels and Lodging');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1187, 1, 1187, 'Green Shield Certified/Green Shield Certified');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (196, 1, 196, 'GreenShip/Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (95, 1, 95, 'GreenShip/New Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1186, 1, 1186, 'Green Star/Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (660, 1, 660, 'Green Star/Communities');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1001, 1, 1001, 'Green Star/Design '||chr(38)||' As Built');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1185, 1, 1185, 'Green Star/Homes');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (577, 1, 577, 'Green Star/Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (828, 1, 828, 'Green Star NZ/Design '||chr(38)||' As Built');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1004, 1, 1004, 'Green Star NZ/Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1093, 1, 1093, 'Green Star NZ/Performance');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (722, 1, 722, 'Green Star/Performance');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (575, 1, 575, 'Green Star SA/Design '||chr(38)||' As Built');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (587, 1, 587, 'Green Star SA/Performance');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (990, 1, 990, 'GRIHA/Green Rating for Integrated Habitat Assessment - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1098, 1, 1098, 'GRIHA/Green Rating for Integrated Habitat Assessment - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (841, 1, 841, 'G-SEED/G-SEED');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1221, 1, 1221, 'Homestar/Homestar Design Rating');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1119, 1, 1119, 'Hong Kong Environmental Protection Department/IAQ Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (675, 1, 675, 'Housing Performance Indication System/Housing Performance Evaluation - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1099, 1, 1099, 'Housing Performance Indication System/Housing Performance Evaluation - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1222, 1, 1222, 'IGBC Green/Affordable Housing');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (198, 1, 198, 'IGBC Green/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1171, 1, 1171, 'IGBC Green/Factory Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (766, 1, 766, 'IGBC Green/Homes');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1170, 1, 1170, 'IGBC Green/Logistics Parks and Warehouses');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (724, 1, 724, 'IGBC Green/New Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (516, 1, 516, 'IGBC Green/SEZs');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1203, 1, 1203, 'IGBC/Health '||chr(38)||' Well-being Certification - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1204, 1, 1204, 'IGBC/Health '||chr(38)||' Well-being Certification - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1111, 1, 1111, 'International Living Future Institute/Core Green Building Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (681, 1, 681, 'International Living Future Institute/Living Building Challenge');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (591, 1, 591, 'IREM Certified Sustainable Properties/IREM Certified Sustainable Properties');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1141, 1, 1141, 'Irish GBC/Home Performance Index');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1213, 1, 1213, 'Klimaaktiv/Klimaaktiv Building Standard');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1143, 1, 1143, 'LEA-Label/LEA-Label');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (959, 1, 959, 'LEED/Building Design and Construction (BD+C)');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (946, 1, 946, 'LEED/Building Operations and Maintenance (O+M)');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (954, 1, 954, 'LEED/for Homes');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (965, 1, 965, 'LEED/Interior Design and Construction (ID+C)');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (947, 1, 947, 'LEED/Neighborhood Development (ND)');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (992, 1, 992, 'LOTUS/Buildings in Operation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1131, 1, 1131, 'LOTUS/Homes');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1109, 1, 1109, 'LOTUS/Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1108, 1, 1108, 'LOTUS/New Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1137, 1, 1137, 'Milieuplatform Zorg/Milieuthermometer Zorg');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (200, 1, 200, 'Milj'||UNISTR('\00F6')||'byggnad/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (743, 1, 743, 'Milj'||UNISTR('\00F6')||'byggnad/New Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (605, 1, 605, 'MINERGIE/A');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (557, 1, 557, 'MINERGIE/ECO');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (905, 1, 905, 'MINERGIE/MINERGIE');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (666, 1, 666, 'MINERGIE/P');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1197, 1, 1197, 'Mostadam/Commercial Buildings D+C');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (581, 1, 581, 'NABERS/Multi-rating');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1121, 1, 1121, 'NF Habitat/HQE Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1123, 1, 1123, 'NF Habitat/HQE Exploitation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1122, 1, 1122, 'NF Habitat/HQE R'||UNISTR('\00E9')||'novation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (588, 1, 588, 'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires en Exploitation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (247, 1, 247, 'NF HQE/B'||UNISTR('\00E2')||'timents Tertiaires - Neuf ou R'||UNISTR('\00E9')||'novation');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (723, 1, 723, 'NGBS/National Green Building Standard - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1100, 1, 1100, 'NGBS/National Green Building Standard - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1090, 1, 1090, 'Parksmart/Parksmart');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (799, 1, 799, 'Passiefwoning/Passiefwoning');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1136, 1, 1136, 'Passive House Institute/EnerPHit');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1135, 1, 1135, 'Passive House Institute/Passive House');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1220, 1, 1220, 'Planet Mark/Development Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1212, 1, 1212, 'Prestaterre Certifications/Bee Logement Neuf');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (977, 1, 977, 'RESET Air/Commercial Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (976, 1, 976, 'RESET Air/Core and Shell');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1174, 1, 1174, 'Rick Hansen Foundation/Accessibility Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1173, 1, 1173, 'Rick Hansen Foundation/Accessibility Certification - Pre-Construction Rating');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1181, 1, 1181, 'SEED/SEED Next generation Living - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1182, 1, 1182, 'SEED/SEED Next Generation Living - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (745, 1, 745, 'SGBC Green Building EU/SGBC GreenBuilding EU - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1104, 1, 1104, 'SGBC Green Building EU/SGBC GreenBuilding EU - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1183, 1, 1183, 'SGBC/Green Build NollCO2');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1195, 1, 1195, 'SGBC/Milj'||UNISTR('\00F6')||'byggnad iDrift');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1209, 1, 1209, 'SG Clean/SG Clean Programme');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (752, 1, 752, 'SKA Rating/SKA Rating - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1101, 1, 1101, 'SKA Rating/SKA Rating - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (920, 1, 920, 'SMBC Sustainable Building Assessment/Existing Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (921, 1, 921, 'SMBC Sustainable Building Assessment/New Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1196, 1, 1196, 'SSREI/SSREI');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (781, 1, 781, 'Standard Nachhaltiges Bauen Schweiz (SNBS)/Standard Nachhaltiges Bauen Schweiz (SNBS)');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (450, 1, 450, 'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1102, 1, 1102, 'Svanen/Milj'||UNISTR('\00F6')||'m'||UNISTR('\00E4')||'rkta - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1175, 1, 1175, 'TABC/EEWH - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1176, 1, 1176, 'TABC/EEWH - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1217, 1, 1217, 'test_case/new project');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (646, 1, 646, 'Toronto Green Standard/Toronto Green Standard');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (994, 1, 994, 'TREES/Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1107, 1, 1107, 'TREES/Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (609, 1, 609, 'TripAdvisor/GreenLeaders');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1088, 1, 1088, 'TRUE (Total Resource Use and Efficiency)/Zero Waste Certification');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1138, 1, 1138, 'UL/Verified Healthy Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1124, 1, 1124, 'WELL Building Standard/Community');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (903, 1, 903, 'WELL Building Standard/Core and Shell');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1113, 1, 1113, 'WELL Building Standard/Existing Building');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1114, 1, 1114, 'WELL Building Standard/Existing Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (885, 1, 885, 'WELL Building Standard/New Buildings');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1081, 1, 1081, 'WELL Building Standard/New Interiors');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1127, 1, 1127, 'WELL/Health-Safety Rating');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1207, 1, 1207, 'WiredScore/SmartScore - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1208, 1, 1208, 'WiredScore/SmartScore - Operational');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1205, 1, 1205, 'WiredScore/WiredScore - Design '||chr(38)||' Construction');
	INSERT INTO csr.temp_certification (certification_id, certification_type_id, external_id, name) VALUES (1206, 1, 1206, 'WiredScore/WiredScore - Operational');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (1, 1106, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (2, 1106, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (3, 1106, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (4, 1106, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (5, 1148, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (6, 1148, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (7, 1148, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (8, 1148, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (9, 1149, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (10, 1149, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (11, 1149, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (12, 1149, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (13, 1219, 0, '5 star grade');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (14, 1219, 1, '4 star grade');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (15, 1219, 2, '3 star grade');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (16, 1219, 3, '2 star grade');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (17, 1219, 4, '1 star grade');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (18, 1142, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (19, 1142, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (20, 1142, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (21, 1142, 3, 'Green');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (22, 895, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (23, 895, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (24, 895, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (25, 895, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (26, 895, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (27, 1147, 0, 'Excellence Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (28, 1147, 1, 'Performance Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (29, 1147, 2, 'Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (30, 1164, 0, 'Excellence Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (31, 1164, 1, 'Performance Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (32, 1164, 2, 'Label');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (33, 598, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (34, 598, 1, 'GoldPlus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (35, 598, 2, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (36, 598, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (37, 1214, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (38, 1214, 1, 'GoldPlus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (39, 1214, 2, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (40, 1214, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (41, 1215, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (42, 1215, 1, 'GoldPlus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (43, 1215, 2, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (44, 1215, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (45, 567, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (46, 567, 1, 'GoldPlus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (47, 567, 2, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (48, 567, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (49, 901, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (50, 901, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (51, 901, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (52, 901, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (53, 1105, 0, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (54, 1105, 1, 'Very Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (55, 1105, 2, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (56, 1105, 3, 'Satisfactory');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (57, 3, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (58, 3, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (59, 3, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (60, 3, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (61, 898, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (62, 898, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (63, 898, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (64, 898, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (65, 6, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (66, 6, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (67, 6, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (68, 6, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (69, 6, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (70, 183, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (71, 183, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (72, 183, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (73, 183, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (74, 183, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (75, 7, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (76, 7, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (77, 7, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (78, 7, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (79, 7, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (80, 1184, 0, '30% improvement');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (81, 1184, 1, '20% improvement');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (82, 1184, 2, '10% improvement');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (83, 1184, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (84, 541, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (85, 541, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (86, 541, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (87, 541, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (88, 541, 4, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (89, 251, 0, 'Code Level 6');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (90, 251, 1, 'Code Level 5');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (91, 251, 2, 'Code Level 4');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (92, 251, 3, 'Code Level 3');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (93, 251, 4, 'Code Level 2');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (94, 251, 5, 'Code Level 1');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (95, 586, 0, 'Outstanding');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (96, 586, 1, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (97, 586, 2, 'Very Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (98, 586, 3, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (99, 586, 4, 'Pass');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (100, 691, 0, 'Outstanding');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (101, 691, 1, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (102, 691, 2, 'Very Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (103, 691, 3, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (104, 691, 4, 'Pass');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (105, 691, 5, 'Acceptable');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (106, 966, 0, 'Outstanding');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (107, 966, 1, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (108, 966, 2, 'Very Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (109, 966, 3, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (110, 966, 4, 'Pass');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (111, 1216, 0, 'Outstanding');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (112, 1216, 1, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (113, 1216, 2, 'Very good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (114, 1216, 3, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (115, 1216, 4, 'Pass');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (116, 692, 0, 'Outstanding');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (117, 692, 1, 'Excellent');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (118, 692, 2, 'Very Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (119, 692, 3, 'Good');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (120, 692, 4, 'Pass');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (121, 695, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (122, 695, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (123, 695, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (124, 1188, 0, 'Carbon Neutral');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (125, 1188, 1, '80% reduction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (126, 1188, 2, '60% reduction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (127, 1188, 3, '40% reduction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (128, 1188, 4, '20% reduction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (129, 1188, 5, '5% reduction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (130, 188, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (131, 188, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (132, 188, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (133, 188, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (134, 188, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (135, 699, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (136, 699, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (137, 699, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (138, 699, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (139, 699, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (140, 941, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (141, 941, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (142, 941, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (143, 941, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (144, 941, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (145, 988, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (146, 988, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (147, 988, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (148, 988, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (149, 988, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (150, 16, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (151, 16, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (152, 16, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (153, 16, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (154, 16, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (155, 1116, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (156, 1116, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (157, 1116, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (158, 1116, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (159, 1116, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (160, 1115, 0, 'Superior (S)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (161, 1115, 1, 'Very Good (A)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (162, 1115, 2, 'Good (B+)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (163, 1115, 3, 'Slightly Poor (B-)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (164, 1115, 4, 'Poor (C)');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (165, 832, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (166, 832, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (167, 832, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (168, 982, 0, 'Three Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (169, 982, 1, 'Two Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (170, 982, 2, 'One Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (171, 1096, 0, 'Three Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (172, 1096, 1, 'Two Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (173, 1096, 2, 'One Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (174, 1150, 0, 'Grade 1');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (175, 1150, 1, 'Grade 2');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (176, 1150, 2, 'Grade 3');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (177, 1117, 0, '3 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (178, 340, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (179, 340, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (180, 340, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (181, 340, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (182, 340, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (183, 925, 0, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (184, 925, 1, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (185, 925, 2, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (186, 925, 3, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (187, 925, 4, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (188, 1129, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (189, 1129, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (190, 1129, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (191, 1129, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (192, 78, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (193, 78, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (194, 78, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (195, 78, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (196, 571, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (197, 571, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (198, 571, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (199, 571, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (200, 1223, 0, 'Platinum + Zero Energy Ready');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (201, 1223, 1, 'Platinum + Zero Energy');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (202, 1223, 2, 'Platinum + Zero Energy Plus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (203, 1223, 3, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (204, 1223, 4, 'Silver ');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (205, 1223, 5, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (206, 984, 0, 'Advanced');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (207, 984, 1, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (208, 1180, 0, 'Zero Carbon');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (209, 1094, 0, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (210, 1094, 1, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (211, 1094, 2, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (212, 1002, 0, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (213, 1002, 1, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (214, 1002, 2, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (215, 1128, 0, 'Approved with Distinction');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (216, 1128, 1, 'Approved');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (217, 1201, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (218, 1201, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (219, 1201, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (220, 1201, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (221, 1202, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (222, 1202, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (223, 1202, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (224, 1202, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (225, 1198, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (226, 1198, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (227, 1198, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (228, 1198, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (229, 1200, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (230, 1200, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (231, 1200, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (232, 1200, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (233, 1199, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (234, 1199, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (235, 1199, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (236, 1199, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (237, 190, 0, '4 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (238, 190, 1, '3 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (239, 190, 2, '2 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (240, 190, 3, '1 Green Globe');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (241, 93, 0, '4 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (242, 93, 1, '3 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (243, 93, 2, '2 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (244, 93, 3, '1 Green Globe');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (245, 1008, 0, '4 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (246, 1008, 1, '3 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (247, 1008, 2, '2 Green Globes');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (248, 1008, 3, '1 Green Globe');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (249, 1177, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (250, 1177, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (251, 1177, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (252, 1177, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (253, 1178, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (254, 1178, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (255, 1178, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (256, 1178, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (257, 1186, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (258, 1186, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (259, 1186, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (260, 660, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (261, 660, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (262, 660, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (263, 1001, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (264, 1001, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (265, 1001, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (266, 577, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (267, 577, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (268, 577, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (269, 828, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (270, 828, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (271, 828, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (272, 1004, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (273, 1004, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (274, 1004, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (275, 1093, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (276, 1093, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (277, 1093, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (278, 1093, 3, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (279, 1093, 4, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (280, 1093, 5, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (281, 722, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (282, 722, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (283, 722, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (284, 722, 3, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (285, 722, 4, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (286, 722, 5, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (287, 575, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (288, 575, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (289, 575, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (290, 587, 0, '6 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (291, 587, 1, '5 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (292, 587, 2, '4 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (293, 587, 3, '3 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (294, 587, 4, '2 Stars');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (295, 587, 5, '1 Star');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (296, 1221, 0, '10 Homestar');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (297, 1221, 1, '9 Homestar');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (298, 1221, 2, '8 Homestar');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (299, 1221, 3, '7 Homestar');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (300, 1221, 4, '6 Homestar');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (301, 1119, 0, 'Excellent Class');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (302, 1119, 1, 'Good Class');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (303, 1222, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (304, 1222, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (305, 1222, 2, 'Silver ');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (306, 1222, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (307, 1171, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (308, 1171, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (309, 1171, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (310, 1171, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (311, 1170, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (312, 1170, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (313, 1170, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (314, 1170, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (315, 1203, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (316, 1203, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (317, 1203, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (318, 1203, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (319, 1204, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (320, 1204, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (321, 1204, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (322, 1204, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (323, 681, 0, 'Living');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (324, 681, 1, 'Petal');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (325, 1141, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (326, 1141, 1, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (327, 1213, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (328, 1213, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (329, 1213, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (330, 1143, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (331, 1143, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (332, 1143, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (333, 1143, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (334, 959, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (335, 959, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (336, 959, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (337, 959, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (338, 946, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (339, 946, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (340, 946, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (341, 946, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (342, 954, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (343, 954, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (344, 954, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (345, 954, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (346, 965, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (347, 965, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (348, 965, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (349, 965, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (350, 947, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (351, 947, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (352, 947, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (353, 947, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (354, 992, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (355, 992, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (356, 992, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (357, 992, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (358, 1131, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (359, 1131, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (360, 1131, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (361, 1131, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (362, 1109, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (363, 1109, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (364, 1109, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (365, 1109, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (366, 1108, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (367, 1108, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (368, 1108, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (369, 1108, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (370, 1137, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (371, 1137, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (372, 1137, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (373, 200, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (374, 200, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (375, 200, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (376, 743, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (377, 743, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (378, 743, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (379, 1197, 0, 'Diamond');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (380, 1197, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (381, 1197, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (382, 1197, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (383, 1197, 4, 'Green');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (384, 588, 0, 'EXCEPTIONNEL');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (385, 588, 1, 'EXCELLENT');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (386, 588, 2, 'TRES BON');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (387, 588, 3, 'BON');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (388, 588, 4, 'PASS');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (389, 247, 0, 'EXCEPTIONNEL');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (390, 247, 1, 'EXCELLENT');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (391, 247, 2, 'TRES BON');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (392, 247, 3, 'BON');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (393, 247, 4, 'PASS');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (394, 723, 0, 'Emerald');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (395, 723, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (396, 723, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (397, 723, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (398, 1100, 0, 'Emerald');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (399, 1100, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (400, 1100, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (401, 1100, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (402, 1090, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (403, 1090, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (404, 1090, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (405, 1090, 3, 'Pioneer');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (406, 1136, 0, 'Premium');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (407, 1136, 1, 'Plus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (408, 1136, 2, 'Classic');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (409, 1135, 0, 'Premium');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (410, 1135, 1, 'Plus');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (411, 1135, 2, 'Classic');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (412, 1220, 0, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (413, 1174, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (414, 1174, 1, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (415, 1196, 0, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (416, 1196, 1, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (417, 1196, 2, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (418, 1175, 0, 'Diamond');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (419, 1175, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (420, 1175, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (421, 1175, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (422, 1175, 4, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (423, 1176, 0, 'Diamond');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (424, 1176, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (425, 1176, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (426, 1176, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (427, 1176, 4, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (428, 646, 0, 'Tier 4');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (429, 646, 1, 'Tier 3');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (430, 646, 2, 'Tier 2');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (431, 994, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (432, 994, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (433, 994, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (434, 994, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (435, 1107, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (436, 1107, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (437, 1107, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (438, 1107, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (439, 609, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (440, 609, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (441, 609, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (442, 609, 3, 'Bronze');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (443, 609, 4, 'GreenPartner');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (444, 1088, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (445, 1088, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (446, 1088, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (447, 1088, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (448, 1138, 0, 'for Indoor Environmental Quality');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (449, 1138, 1, 'for Indoor Air and Water');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (450, 1138, 2, 'for Indoor Air');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (451, 1124, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (452, 1124, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (453, 1124, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (454, 903, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (455, 903, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (456, 903, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (457, 1113, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (458, 1113, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (459, 1113, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (460, 1114, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (461, 1114, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (462, 1114, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (463, 885, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (464, 885, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (465, 885, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (466, 1081, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (467, 1081, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (468, 1081, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (469, 1207, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (470, 1207, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (471, 1207, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (472, 1207, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (473, 1208, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (474, 1208, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (475, 1208, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (476, 1208, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (477, 1205, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (478, 1205, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (479, 1205, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (480, 1205, 3, 'Certified');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (481, 1206, 0, 'Platinum');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (482, 1206, 1, 'Gold');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (483, 1206, 2, 'Silver');
	INSERT INTO csr.temp_certification_level (certification_level_id, certification_id, position, name) VALUES (484, 1206, 3, 'Certified');
END;
/

BEGIN
	-- There are no deleted certificates.
	MERGE INTO csr.certification c
	 USING (
	    SELECT certification_id, name FROM csr.temp_certification
	) x
	ON (c.certification_id = x.certification_id)
	 WHEN MATCHED THEN 
	     UPDATE
	        SET name = x.name
	 WHEN NOT MATCHED THEN
	 	INSERT (certification_id, certification_type_id, external_id, name)
	 	VALUES (x.certification_id, 1, x.certification_id, x.name)
	;
	
	-- There are no deleted certificate levels.
	MERGE INTO csr.certification_level cl
	 USING (
	    SELECT certification_id, name, position FROM csr.temp_certification_level
	) x
	ON (cl.name = x.name AND cl.certification_id = x.certification_id)
	 WHEN MATCHED THEN 
	     UPDATE
	        SET position = x.position
	 WHEN NOT MATCHED THEN
	 	INSERT (certification_level_id, certification_id, position, name)
	 	VALUES (x.position + 1, x.certification_id, x.position, x.name)
	;
END;
/

DROP TABLE csr.temp_certification_level;
DROP TABLE csr.temp_certification;

BEGIN
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (64, 1, 64, 'Arc Energy Performance Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (65, 1, 65, 'Arc Energy Performance Score');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (66, 1, 66, 'BBC Effinergie');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (67, 1, 67, 'BBC Effinergie Rénovation');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (48, 1, 48, 'BCA BESS (Building Energy Submission System) Benchmarking');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (90, 1, 90, 'BEE Star Rating - Shopping Mall - 1 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (89, 1, 89, 'BEE Star Rating - Shopping Mall - 2 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (88, 1, 88, 'BEE Star Rating - Shopping Mall - 3 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (87, 1, 87, 'BEE Star Rating - Shopping Mall - 4 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (86, 1, 86, 'BEE Star Rating - Shopping Mall - 5 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (49, 1, 49, 'BELS');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (68, 1, 68, 'BEPOS Effinergie');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (69, 1, 69, 'BEPOS+ Effinergie');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (50, 1, 50, 'Building Energy Rating (BER) Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (51, 1, 51, 'DPE (Diagnostic de performance énergétique)');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (52, 1, 52, 'Energiattest - Norway');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (53, 1, 53, 'Energideklaration - Sweden');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (70, 1, 70, 'Energy Index - NL');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (47, 1, 47, 'Energy Star Certified - 75-79 Points');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (46, 1, 46, 'Energy Star Certified - 80-84 Points');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (45, 1, 45, 'Energy Star Certified - 85-89 Points');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (44, 1, 44, 'Energy Star Certified - 90-95 Points');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (43, 1, 43, 'Energy Star Certified - 96-100 Points');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (54, 1, 54, 'Energy Star Portfolio Manager');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (3, 1, 3, 'EU EPC - A');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (2, 1, 2, 'EU EPC - A+');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (1, 1, 1, 'EU EPC - A++');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (83, 1, 83, 'EU EPC - A+++');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (84, 1, 84, 'EU EPC - A++++');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (13, 1, 13, 'EU EPC - A1');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (14, 1, 14, 'EU EPC - A2');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (15, 1, 15, 'EU EPC - A3');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (85, 1, 85, 'EU EPC - A4');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (4, 1, 4, 'EU EPC - B');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (5, 1, 5, 'EU EPC - B-');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (16, 1, 16, 'EU EPC - B1');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (17, 1, 17, 'EU EPC - B2');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (18, 1, 18, 'EU EPC - B3');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (26, 1, 26, 'EU EPC - Belgium');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (6, 1, 6, 'EU EPC - C');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (19, 1, 19, 'EU EPC - C1');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (20, 1, 20, 'EU EPC - C2');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (21, 1, 21, 'EU EPC - C3');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (7, 1, 7, 'EU EPC - D');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (22, 1, 22, 'EU EPC - D1');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (23, 1, 23, 'EU EPC - D2');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (8, 1, 8, 'EU EPC - E');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (24, 1, 24, 'EU EPC - E1');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (25, 1, 25, 'EU EPC - E2');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (9, 1, 9, 'EU EPC - F');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (10, 1, 10, 'EU EPC - G');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (92, 1, 92, 'EU EPC - Germany (Non-residential)');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (11, 1, 11, 'EU EPC - H');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (12, 1, 12, 'EU EPC - I');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (27, 1, 27, 'EU EPC - Latvia');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (28, 1, 28, 'EU EPC - Poland');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (29, 1, 29, 'EU EPC - Slovenia');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (71, 1, 71, 'Fannie Mae Energy Performance Metric');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (56, 1, 56, 'GEAK');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (57, 1, 57, 'Green Star Performance Energy Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (91, 1, 91, 'HKEERSB');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (58, 1, 58, 'HKGOC - Energywi$e Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (81, 1, 81, 'Hong Kong EMSD Energy Benchmarking');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (82, 1, 82, 'Hong Kong GBC BEST Tool');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (72, 1, 72, 'HPE (Haute Performance Energétique)');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (78, 1, 78, 'Japan e-mark');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (77, 1, 77, 'KEA Korea Building Energy Efficiency Certification');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (73, 1, 73, 'NABERS Co-Assess');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (41, 1, 41, 'NABERS Energy - 0.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (42, 1, 42, 'NABERS Energy - 0 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (39, 1, 39, 'NABERS Energy - 1.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (40, 1, 40, 'NABERS Energy - 1 Star');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (37, 1, 37, 'NABERS Energy - 2.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (38, 1, 38, 'NABERS Energy - 2 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (35, 1, 35, 'NABERS Energy - 3.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (36, 1, 36, 'NABERS Energy - 3 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (33, 1, 33, 'NABERS Energy - 4.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (34, 1, 34, 'NABERS Energy - 4 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (31, 1, 31, 'NABERS Energy - 5.5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (32, 1, 32, 'NABERS Energy - 5 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (30, 1, 30, 'NABERS Energy - 6 Stars');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (59, 1, 59, 'NatHERS');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (60, 1, 60, 'OID Taloen Benchmarking');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (74, 1, 74, 'Ontario EWRB');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (61, 1, 61, 'SIA 2031 Energy Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (75, 1, 75, 'Superior Energy Performance 50001');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (76, 1, 76, 'THPE (Très Haute Performance Energétique)');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (79, 1, 79, 'TMG Tokyo Energy Performance Certificate');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (80, 1, 80, 'TMG Tokyo Green Labelling for Condominiums');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (93, 1, 93, 'TMG Tokyo Near-Top-level Facility');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (62, 1, 62, 'TMG Tokyo Small and Medium Scale Facilities');
	INSERT INTO csr.temp_energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (63, 1, 63, 'TMG Tokyo Top-level Facility');
END;
/

BEGIN
	MERGE INTO csr.energy_rating c
	 USING (
	    SELECT energy_rating_id, name FROM csr.temp_energy_rating
	) x
	ON (c.energy_rating_id = x.energy_rating_id)
	 WHEN MATCHED THEN 
	     UPDATE
	        SET name = x.name
	 WHEN NOT MATCHED THEN
	 	INSERT (energy_rating_id, certification_type_id, external_id, name)
	 	VALUES (x.energy_rating_id, 1, x.energy_rating_id, x.name)
	;
	
	-- Not in use at time of writing
	DELETE FROM csr.energy_rating WHERE energy_rating_id = 55;
END;
/

DROP TABLE csr.temp_energy_rating;
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

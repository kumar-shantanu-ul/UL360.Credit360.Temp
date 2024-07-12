-- Please update version.sql too -- this keeps clean builds in sync
define version=3422
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE SEQUENCE CSR.CERT_LEVEL_ID_SEQ START WITH 464 INCREMENT BY 1 NOCYCLE CACHE 5;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1211, 1, 1211, 'Association Promotelec/Habitat Neuf');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1214, 1, 1214, 'BCA Green Mark/Healthier Workplaces - Design '||chr(38)||' Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1215, 1, 1215, 'BCA Green Mark/Healthier Workplaces - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1216, 1, 1216, 'BREEAM-NOR/BREEAM-NOR New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1210, 1, 1210, 'Certiv'|| UNISTR('\00E9') ||'a/The E+C- Label');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1201, 1, 1201, 'GBC Italia/Condomini - Design '||chr(38)||' Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1202, 1, 1202, 'GBC Italia/Condomini - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1198, 1, 1198, 'GBC Italia/Historic Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1200, 1, 1200, 'GBC Italia/Home V2');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1199, 1, 1199, 'GBC Italia/Quartieri');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1203, 1, 1203, 'IGBC/Health '||chr(38)||' Well-being Certification - Design '||chr(38)||' Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1204, 1, 1204, 'IGBC/Health '||chr(38)||' Well-being Certification - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1213, 1, 1213, 'Klimaaktiv/Klimaaktiv Building Standard');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1197, 1, 1197, 'Mostadam/Commercial Buildings D+C');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1212, 1, 1212, 'Prestaterre Certifications/Bee Logement Neuf');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1195, 1, 1195, 'SGBC/Milj'|| UNISTR('\00F6') ||'byggnad iDrift');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1209, 1, 1209, 'SG Clean/SG Clean Programme');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1196, 1, 1196, 'SSREI/SSREI');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1217, 1, 1217, 'test_case/new project');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1207, 1, 1207, 'WiredScore/SmartScore - Design '||chr(38)||' Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1208, 1, 1208, 'WiredScore/SmartScore - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1205, 1, 1205, 'WiredScore/WiredScore - Design '||chr(38)||' Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1206, 1, 1206, 'WiredScore/WiredScore - Operational');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (396, 1214, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (397, 1214, 1, 'GoldPlus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (398, 1214, 2, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (399, 1214, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (400, 1215, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (401, 1215, 1, 'GoldPlus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (402, 1215, 2, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (403, 1215, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (404, 1216, 0, 'Outstanding');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (405, 1216, 1, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (406, 1216, 2, 'Very good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (407, 1216, 3, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (408, 1216, 4, 'Pass');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (409, 1201, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (410, 1201, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (411, 1201, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (412, 1201, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (413, 1202, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (414, 1202, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (415, 1202, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (416, 1202, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (417, 1198, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (418, 1198, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (419, 1198, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (420, 1198, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (421, 1200, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (422, 1200, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (423, 1200, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (424, 1200, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (425, 1199, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (426, 1199, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (427, 1199, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (428, 1199, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (429, 1203, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (430, 1203, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (431, 1203, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (432, 1203, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (433, 1204, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (434, 1204, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (435, 1204, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (436, 1204, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (437, 1213, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (438, 1213, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (439, 1213, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (440, 1197, 0, 'Diamond');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (441, 1197, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (442, 1197, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (443, 1197, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (444, 1197, 4, 'Green');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (445, 1196, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (446, 1196, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (447, 1196, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (448, 1207, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (449, 1207, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (450, 1207, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (451, 1207, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (452, 1208, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (453, 1208, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (454, 1208, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (455, 1208, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (456, 1205, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (457, 1205, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (458, 1205, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (459, 1205, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (460, 1206, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (461, 1206, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (462, 1206, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (463, 1206, 3, 'Certified');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (90, 1, 90, 'BEE Star Rating - Shopping Mall - 1 Star');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (89, 1, 89, 'BEE Star Rating - Shopping Mall - 2 Star');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (88, 1, 88, 'BEE Star Rating - Shopping Mall - 3 Star');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (87, 1, 87, 'BEE Star Rating - Shopping Mall - 4 Star');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (86, 1, 86, 'BEE Star Rating - Shopping Mall - 5 Star');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_certificate_pkg
@../region_certificate_body

@update_tail

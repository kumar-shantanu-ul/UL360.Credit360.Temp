define version=3382
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.CERTIFICATION_TYPE (
	CERTIFICATION_TYPE_ID		NUMBER(10,0) NOT NULL,
	NAME						VARCHAR2(255) NOT NULL,
	LOOKUP_KEY					VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_CERT_TYPE PRIMARY KEY (CERTIFICATION_TYPE_ID),
	CONSTRAINT UK_CERT_TYPE_LOOKUP UNIQUE (LOOKUP_KEY)
);
CREATE TABLE CSR.CERTIFICATION (
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_TYPE_ID		NUMBER(10,0) NOT NULL,
	EXTERNAL_ID					VARCHAR2(255) NOT NULL,
	NAME						VARCHAR2(255),
	CONSTRAINT PK_CERT PRIMARY KEY (CERTIFICATION_ID),
	CONSTRAINT UK_CERT_EXT_ID UNIQUE (CERTIFICATION_TYPE_ID, EXTERNAL_ID)
);
CREATE TABLE CSR.CERTIFICATION_LEVEL (
	CERTIFICATION_LEVEL_ID		NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	POSITION					NUMBER(10,0) NOT NULL,
	NAME						VARCHAR2(255),
	CONSTRAINT PK_CERT_LEVEL PRIMARY KEY (CERTIFICATION_LEVEL_ID, CERTIFICATION_ID),
	CONSTRAINT UK_CERT_POS UNIQUE (CERTIFICATION_ID, POSITION)
);
CREATE TABLE CSR.ENERGY_RATING (
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_TYPE_ID		NUMBER(10,0) NOT NULL,
	EXTERNAL_ID					NUMBER(10,0) NOT NULL,
	NAME						VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_ENERGY_RATING PRIMARY KEY (ENERGY_RATING_ID),
	CONSTRAINT UK_ENERGY_RAT_EXT_ID UNIQUE (CERTIFICATION_TYPE_ID, EXTERNAL_ID)
);
CREATE TABLE CSR.REGION_CERTIFICATES (
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_LEVEL_ID		NUMBER(10,0),
	CERTIFICATE_NUMBER			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,0) NOT NULL,
	EXPIRY_DTM					DATE,
	ISSUED_DTM					DATE,
	CONSTRAINT PK_REGION_CERTS PRIMARY KEY (APP_SID, REGION_SID, CERTIFICATION_ID, CERTIFICATION_LEVEL_ID, ISSUED_DTM, EXPIRY_DTM)
);
CREATE TABLE CSR.REGION_ENERGY_RATINGS (
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATE_NUMBER			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,0) NOT NULL,
	EXPIRY_DTM					DATE,
	ISSUED_DTM					DATE,
	CONSTRAINT PK_REGION_ENERGY_RAT PRIMARY KEY (APP_SID, REGION_SID, ENERGY_RATING_ID, ISSUED_DTM, EXPIRY_DTM)
);
CREATE TABLE CSRIMP.REGION_CERTIFICATES (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	CERTIFICATION_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATION_LEVEL_ID		NUMBER(10,0),
	CERTIFICATE_NUMBER			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,0) NOT NULL,
	EXPIRY_DTM					DATE,
	ISSUED_DTM					DATE
);
CREATE TABLE CSRIMP.REGION_ENERGY_RATINGS (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REGION_SID					NUMBER(10,0) NOT NULL,
	ENERGY_RATING_ID			NUMBER(10,0) NOT NULL,
	CERTIFICATE_NUMBER			NUMBER(10,0) NOT NULL,
	FLOOR_AREA					NUMBER(10,0) NOT NULL,
	ISSUED_DTM					DATE,
	EXPIRY_DTM					DATE
);
CREATE OR REPLACE TYPE CSR.T_USER_PROFILE AS 
	OBJECT (
	PRIMARY_KEY					VARCHAR2(128),
	CSR_USER_SID				NUMBER(10),
	EMPLOYEE_REF				VARCHAR2(128),
	PAYROLL_REF					NUMBER(10),
	FIRST_NAME					VARCHAR2(256),
	LAST_NAME					VARCHAR2(256),
	MIDDLE_NAME					VARCHAR2(256),
	FRIENDLY_NAME				VARCHAR2(256),
	EMAIL_ADDRESS				VARCHAR2(256),
	WORK_PHONE_NUMBER			VARCHAR2(32),
	WORK_PHONE_EXTENSION		VARCHAR2(8),
	HOME_PHONE_NUMBER			VARCHAR2(32),
	MOBILE_PHONE_NUMBER			VARCHAR2(32),
	MANAGER_EMPLOYEE_REF		VARCHAR2(128),
	MANAGER_PAYROLL_REF			NUMBER(10),
	MANAGER_PRIMARY_KEY			VARCHAR2(128),
	EMPLOYMENT_START_DATE		DATE,
	EMPLOYMENT_LEAVE_DATE		DATE,
	DATE_OF_BIRTH				DATE,
	GENDER						VARCHAR2(128),
	JOB_TITLE					VARCHAR2(128),
	CONTRACT					VARCHAR2(256),
	EMPLOYMENT_TYPE				VARCHAR2(256),
	PAY_GRADE					VARCHAR2(256),
	BUSINESS_AREA_REF			VARCHAR2(256),
	BUSINESS_AREA_CODE			NUMBER(10),
	BUSINESS_AREA_NAME			VARCHAR2(256),
	BUSINESS_AREA_DESCRIPTION	VARCHAR2(1024),
	DIVISION_REF				VARCHAR2(256),
	DIVISION_CODE				NUMBER(10),
	DIVISION_NAME				VARCHAR2(256),
	DIVISION_DESCRIPTION		VARCHAR2(1024),
	DEPARTMENT					VARCHAR2(256),
	NUMBER_HOURS				NUMBER(12,2),
	COUNTRY						VARCHAR2(128),
	LOCATION					VARCHAR2(256),
	BUILDING					VARCHAR2(256),
	COST_CENTRE_REF				VARCHAR2(256),
	COST_CENTRE_CODE			NUMBER(10),
	COST_CENTRE_NAME			VARCHAR2(256),
	COST_CENTRE_DESCRIPTION		VARCHAR2(1024),
	WORK_ADDRESS_1				VARCHAR2(256),
	WORK_ADDRESS_2				VARCHAR2(256),
	WORK_ADDRESS_3				VARCHAR2(256),
	WORK_ADDRESS_4				VARCHAR2(256),
	HOME_ADDRESS_1				VARCHAR2(256),
	HOME_ADDRESS_2				VARCHAR2(256),
	HOME_ADDRESS_3				VARCHAR2(256),
	HOME_ADDRESS_4				VARCHAR2(256),
	LOCATION_REGION_SID			NUMBER(10),
	INTERNAL_USERNAME			VARCHAR2(256),
	MANAGER_USERNAME			VARCHAR2(256),
	ACTIVATE_ON					DATE,
	DEACTIVATE_ON				DATE,
	CREATION_INSTANCE_STEP_ID	NUMBER(10),
	CREATED_DTM					DATE,
	CREATED_USER_SID			NUMBER(10),
	CREATION_METHOD				VARCHAR2(256),
	UPDATED_INSTANCE_STEP_ID	NUMBER(10),
	LAST_UPDATED_DTM			DATE,
	LAST_UPDATED_USER_SID		NUMBER(10),
	LAST_UPDATE_METHOD			VARCHAR2(256)
);
/
CREATE OR REPLACE TYPE CSR.T_REGION AS 
	OBJECT (
	REGION_SID					NUMBER(10),
	LINK_TO_REGION_SID			NUMBER(10),
	PARENT_SID					NUMBER(10),
	DESCRIPTION					VARCHAR2(1023),
	ACTIVE						NUMBER(10),
	POS							NUMBER(10),
	INFO_XML					SYS.XMLTYPE,
	ACQUISITION_DTM				DATE,
	DISPOSAL_DTM				DATE,
	REGION_TYPE					NUMBER(2),
	LOOKUP_KEY					VARCHAR2(1024),
	GEO_COUNTRY					VARCHAR2(2),
	GEO_REGION					VARCHAR2(2),
	GEO_CITY_ID					NUMBER(10),
	GEO_LONGITUDE				NUMBER,
	GEO_LATITUDE				NUMBER,
	GEO_TYPE					NUMBER(10),
	EGRID_REF					VARCHAR2(4),
	REGION_REF					VARCHAR2(255)
);
/


ALTER TABLE CSR.CERTIFICATION ADD CONSTRAINT FK_CERT_CERT_TYPE_ID
	FOREIGN KEY (CERTIFICATION_TYPE_ID)
	REFERENCES CSR.CERTIFICATION_TYPE(CERTIFICATION_TYPE_ID)
;
ALTER TABLE CSR.CERTIFICATION_LEVEL ADD CONSTRAINT FK_CERT_LEVEL_CERT
	FOREIGN KEY (CERTIFICATION_ID)
	REFERENCES CSR.CERTIFICATION(CERTIFICATION_ID)
;
ALTER TABLE CSR.ENERGY_RATING ADD CONSTRAINT FK_ENERGY_RAT_LVL_CERT
	FOREIGN KEY (CERTIFICATION_TYPE_ID)
	REFERENCES CSR.CERTIFICATION_TYPE(CERTIFICATION_TYPE_ID)
;
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT FK_REG_CERT_CERT_ID
	FOREIGN KEY (CERTIFICATION_ID)
	REFERENCES CSR.CERTIFICATION(CERTIFICATION_ID)
;
ALTER TABLE CSR.REGION_CERTIFICATES ADD CONSTRAINT FK_REG_CERT_CERT_LVL
	FOREIGN KEY (CERTIFICATION_LEVEL_ID, CERTIFICATION_ID)
	REFERENCES CSR.CERTIFICATION_LEVEL(CERTIFICATION_LEVEL_ID, CERTIFICATION_ID)
;
ALTER TABLE CSR.REGION_ENERGY_RATINGS ADD CONSTRAINT FK_REG_ENE_RAT_ID
	FOREIGN KEY (ENERGY_RATING_ID)
	REFERENCES CSR.ENERGY_RATING(ENERGY_RATING_ID)
;
CREATE INDEX CSR.IX_REGION_CERTIF_CERTIFICATION ON CSR.REGION_CERTIFICATES (CERTIFICATION_ID);
CREATE INDEX CSR.IX_REGION_CERTIF_CERTIF_LEVEL ON CSR.REGION_CERTIFICATES (CERTIFICATION_LEVEL_ID, CERTIFICATION_ID);
CREATE INDEX CSR.IX_REGION_ENERGY_ENERGY_RATING ON CSR.REGION_ENERGY_RATINGS (ENERGY_RATING_ID);


grant select,insert,update,delete on csrimp.region_certificates to tool_user;
grant select,insert,update,delete on csrimp.region_energy_ratings to tool_user;
grant select,insert,update on csr.region_certificates to csrimp;
grant select,insert,update on csr.region_energy_ratings to csrimp;
grant select,insert,update on csr.scheduled_stored_proc to csrimp;
GRANT EXECUTE ON cms.form_pkg TO csr;








INSERT INTO csr.plugin 
(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES 
(csr.plugin_id_seq.nextval, 1, 'Certifications', '/csr/site/property/properties/controls/CertificationsTab.js',
 'Controls.CertificationsTab', 'Credit360.Plugins.PluginDto', 'Certifications Tab', null);
INSERT INTO csr.certification_type (certification_type_id, name, lookup_key) VALUES (1, 'Gresb', 'GRESB');
SET ESCAPE ON;
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (1, 1, 1139, '2000-Watt/Site - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (2, 1, 1140, '2000-Watt/Site - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (3, 1, 585, 'ABINC Certification/Urban Development and Shopping Centre');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (4, 1, 1148, 'AirRated/AirScore');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (5, 1, 1149, 'AirRated/AirScore D\&O');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (6, 1, 1142, 'ARCA/Nuove Costruzioni');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (7, 1, 1092, 'Arc/Performance Certificates - 3');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (8, 1, 895, 'Austin Energy/Austin Energy Green Building - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (9, 1, 1147, 'BBCA/BBCA');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (10, 1, 1164, 'BBCA/BBCA - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (11, 1, 598, 'BCA Green Mark/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (12, 1, 567, 'BCA Green Mark/New Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (13, 1, 901, 'BEAM Plus/Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (14, 1, 1105, 'BEAM Plus/Existing Building - Selective Scheme');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (15, 1, 3, 'BEAM Plus/Interior');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (16, 1, 898, 'BEAM Plus/New Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (17, 1, 6, 'BERDE/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (18, 1, 183, 'BERDE/Operations');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (19, 1, 7, 'BERDE/Retrofits and Renovations');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (20, 1, 186, 'BOMA/360');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (21, 1, 541, 'BOMA/BEST');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (22, 1, 1112, 'BOMA/China - Certificate of Excellence');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (23, 1, 354, 'BRaVe/Building RAting ValuE');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (24, 1, 251, 'BREEAM/Code for Sustainable Homes');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (25, 1, 586, 'BREEAM/Domestic Refurbishment');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (26, 1, 997, 'BREEAM/Home Quality Mark');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (27, 1, 691, 'BREEAM/In Use');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (28, 1, 966, 'BREEAM/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (29, 1, 692, 'BREEAM/Refurbishment and Fit-out');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (30, 1, 583, 'Build it Green/GreenPoint Rated, Existing Home');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (31, 1, 765, 'Build it Green/GreenPoint Rated, New Home');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (32, 1, 695, 'Built Green/Built Green');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (33, 1, 998, 'CALGreen/CALGreen');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (34, 1, 1146, 'CasaClima/Nature');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (35, 1, 188, 'CASBEE/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (36, 1, 699, 'CASBEE/for Market Promotion');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (37, 1, 941, 'CASBEE/for Real Estate');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (38, 1, 988, 'CASBEE/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (39, 1, 16, 'CASBEE/Renovation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (40, 1, 1116, 'CASBEE/Wellness Office - Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (41, 1, 1115, 'CASBEE/Wellness Office - New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (42, 1, 832, 'CEEDA/Design-Operate');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (43, 1, 702, 'Certified Rental Building Program/Certified Rental Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (44, 1, 982, 'China Green Building Label/GB/T 50378-2014 - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (45, 1, 1096, 'China Green Building Label/GB/T 50378-2014 - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (46, 1, 1150, 'China Green Warehouses/China Green Warehouses');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (47, 1, 1117, 'Cleaning Accountability Framework/CAF Building Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (48, 1, 1106, 'CyclingScore/CyclingScore');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (49, 1, 340, 'DBJ Green Building Certification/DBJ Green Building Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (50, 1, 925, 'DBJ Green Building Certification/DBJ Green Building Certification - Plan Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (51, 1, 975, 'DGBC Woonmerk/Woon Kwaliteit Richtlijn');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (52, 1, 1129, 'DGNB/Buildings In Use');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (53, 1, 78, 'DGNB/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (54, 1, 571, 'DGNB/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (55, 1, 1130, 'DGNB/Renovation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (56, 1, 303, 'EarthCheck/Sustainable Design');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (57, 1, 703, 'EarthCraft/EarthCraft');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (58, 1, 984, 'EDGE/Excellence in Design for Greater Efficiencies');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (59, 1, 1145, 'Energy Star/Residential New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (60, 1, 625, 'Enterprise Green Communities/Enterprise Green Communities');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (61, 1, 1094, 'Fitwel/Fitwel - Built');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (62, 1, 1002, 'Fitwel/Fitwel - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (63, 1, 1128, 'Fitwel/Viral Response');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (64, 1, 711, 'Florida Green Building Certification/Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (65, 1, 1097, 'Florida Green Building Certification/Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (66, 1, 906, 'GPR Gebouw/GPR Gebouw - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (67, 1, 1103, 'GPR Gebouw/GPR Gebouw - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (68, 1, 889, 'Green Building Index (GBI)/Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (69, 1, 859, 'Green Building Index (GBI)/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (70, 1, 190, 'Green Globes/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (71, 1, 93, 'Green Globes/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (72, 1, 1008, 'Green Globes/Sustainable Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (73, 1, 192, 'Green Key/Eco-Rating Program');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (74, 1, 1118, 'Green Key International/Ecolabel');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (75, 1, 973, 'Green Rating/Green Rating Remote Assessment');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (76, 1, 194, 'Green Seal/Hotels and Lodging');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (77, 1, 196, 'GreenShip/Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (78, 1, 95, 'GreenShip/New Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (79, 1, 660, 'Green Star/Communities');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (80, 1, 1001, 'Green Star/Design \& As Built');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (81, 1, 577, 'Green Star/Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (82, 1, 828, 'Green Star NZ/Design \& As Built');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (83, 1, 1004, 'Green Star NZ/Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (84, 1, 1093, 'Green Star NZ/Performance');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (85, 1, 722, 'Green Star/Performance');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (86, 1, 575, 'Green Star SA/Design \& As Built');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (87, 1, 587, 'Green Star SA/Performance');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (88, 1, 990, 'GRIHA/Green Rating for Integrated Habitat Assessment - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (89, 1, 1098, 'GRIHA/Green Rating for Integrated Habitat Assessment - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (90, 1, 841, 'G-SEED/G-SEED');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (91, 1, 1119, 'Hong Kong Environmental Protection Department/IAQ Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (92, 1, 675, 'Housing Performance Indication System/Housing Performance Evaluation - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (93, 1, 1099, 'Housing Performance Indication System/Housing Performance Evaluation - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (94, 1, 198, 'IGBC Green/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (95, 1, 766, 'IGBC Green/Homes');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (96, 1, 724, 'IGBC Green/New Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (97, 1, 516, 'IGBC Green/SEZs');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (98, 1, 1111, 'International Living Future Institute/Core Green Building Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (99, 1, 681, 'International Living Future Institute/Living Building Challenge');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (100, 1, 591, 'IREM Certified Sustainable Properties/IREM Certified Sustainable Properties');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (101, 1, 1141, 'Irish GBC/Home Performance Index');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (102, 1, 1143, 'LEA-Label/LEA-Label');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (103, 1, 959, 'LEED/Building Design and Construction (BD+C)');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (104, 1, 946, 'LEED/Building Operations and Maintenance (O+M)');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (105, 1, 954, 'LEED/for Homes');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (106, 1, 965, 'LEED/Interior Design and Construction (ID+C)');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (107, 1, 947, 'LEED/Neighborhood Development (ND)');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (108, 1, 992, 'LOTUS/Buildings in Operation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (109, 1, 1131, 'LOTUS/Homes');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (110, 1, 1109, 'LOTUS/Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (111, 1, 1108, 'LOTUS/New Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (112, 1, 1137, 'Milieuplatform Zorg/Milieuthermometer Zorg');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (113, 1, 200, 'Miljöbyggnad/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (114, 1, 743, 'Miljöbyggnad/New Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (115, 1, 605, 'MINERGIE/A');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (116, 1, 557, 'MINERGIE/ECO');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (117, 1, 905, 'MINERGIE/MINERGIE');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (118, 1, 666, 'MINERGIE/P');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (119, 1, 581, 'NABERS/Multi-rating');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (120, 1, 1121, 'NF Habitat/HQE Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (121, 1, 1123, 'NF Habitat/HQE Exploitation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (122, 1, 1122, 'NF Habitat/HQE Rénovation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (123, 1, 588, 'NF HQE/Bâtiments Tertiaires en Exploitation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (124, 1, 247, 'NF HQE/Bâtiments Tertiaires - Neuf ou Rénovation');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (125, 1, 723, 'NGBS/National Green Building Standard - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (126, 1, 1100, 'NGBS/National Green Building Standard - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (127, 1, 1090, 'Parksmart/Parksmart');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (128, 1, 799, 'Passiefwoning/Passiefwoning');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (129, 1, 1136, 'Passive House Institute/EnerPHit');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (130, 1, 1135, 'Passive House Institute/Passive House');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (131, 1, 977, 'RESET Air/Commercial Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (132, 1, 976, 'RESET Air/Core and Shell');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (133, 1, 745, 'SGBC Green Building EU/SGBC GreenBuilding EU - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (134, 1, 1104, 'SGBC Green Building EU/SGBC GreenBuilding EU - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (135, 1, 752, 'SKA Rating/SKA Rating - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (136, 1, 1101, 'SKA Rating/SKA Rating - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (137, 1, 920, 'SMBC Sustainable Building Assessment/Existing Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (138, 1, 921, 'SMBC Sustainable Building Assessment/New Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (139, 1, 781, 'Standard Nachhaltiges Bauen Schweiz (SNBS)/Standard Nachhaltiges Bauen Schweiz (SNBS)');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (140, 1, 450, 'Svanen/Miljömärkta - Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (141, 1, 1102, 'Svanen/Miljömärkta - Operational');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (142, 1, 646, 'Toronto Green Standard/Toronto Green Standard');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (143, 1, 994, 'TREES/Design \& Construction');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (144, 1, 1107, 'TREES/Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (145, 1, 609, 'TripAdvisor/GreenLeaders');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (146, 1, 1088, 'TRUE (Total Resource Use and Efficiency)/Zero Waste Certification');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (147, 1, 1138, 'UL/Verified Healthy Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (148, 1, 1124, 'WELL Building Standard/Community');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (149, 1, 903, 'WELL Building Standard/Core and Shell');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (150, 1, 1113, 'WELL Building Standard/Existing Building');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (151, 1, 1114, 'WELL Building Standard/Existing Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (152, 1, 885, 'WELL Building Standard/New Buildings');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (153, 1, 1081, 'WELL Building Standard/New Interiors');
INSERT INTO csr.certification (certification_id, certification_type_id, external_id, name) VALUES (154, 1, 1127, 'WELL/Health-Safety Rating');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (1, 3, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (2, 3, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (3, 3, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (4, 3, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (5, 4, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (6, 4, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (7, 4, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (8, 4, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (9, 5, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (10, 5, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (11, 5, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (12, 5, 3, 'Green');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (13, 7, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (14, 7, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (15, 7, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (16, 7, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (17, 7, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (18, 8, 0, 'Excellence Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (19, 8, 1, 'Performance Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (20, 8, 2, 'Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (21, 9, 0, 'Excellence Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (22, 9, 1, 'Performance Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (23, 9, 2, 'Label');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (24, 10, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (25, 10, 1, 'GoldPlus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (26, 10, 2, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (27, 10, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (28, 11, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (29, 11, 1, 'GoldPlus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (30, 11, 2, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (31, 11, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (32, 12, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (33, 12, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (34, 12, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (35, 12, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (36, 13, 0, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (37, 13, 1, 'Very Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (38, 13, 2, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (39, 13, 3, 'Satisfactory');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (40, 14, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (41, 14, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (42, 14, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (43, 14, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (44, 15, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (45, 15, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (46, 15, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (47, 15, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (48, 16, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (49, 16, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (50, 16, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (51, 16, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (52, 16, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (53, 17, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (54, 17, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (55, 17, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (56, 17, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (57, 17, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (58, 18, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (59, 18, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (60, 18, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (61, 18, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (62, 18, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (63, 20, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (64, 20, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (65, 20, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (66, 20, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (67, 20, 4, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (68, 23, 0, 'Code Level 6');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (69, 23, 1, 'Code Level 5');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (70, 23, 2, 'Code Level 4');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (71, 23, 3, 'Code Level 3');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (72, 23, 4, 'Code Level 2');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (73, 23, 5, 'Code Level 1');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (74, 24, 0, 'Outstanding');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (75, 24, 1, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (76, 24, 2, 'Very Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (77, 24, 3, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (78, 24, 4, 'Pass');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (79, 26, 0, 'Outstanding');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (80, 26, 1, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (81, 26, 2, 'Very Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (82, 26, 3, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (83, 26, 4, 'Pass');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (84, 26, 5, 'Acceptable');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (85, 27, 0, 'Outstanding');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (86, 27, 1, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (87, 27, 2, 'Very Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (88, 27, 3, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (89, 27, 4, 'Pass');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (90, 28, 0, 'Outstanding');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (91, 28, 1, 'Excellent');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (92, 28, 2, 'Very Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (93, 28, 3, 'Good');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (94, 28, 4, 'Pass');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (95, 31, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (96, 31, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (97, 31, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (98, 34, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (99, 34, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (100, 34, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (101, 34, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (102, 34, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (103, 35, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (104, 35, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (105, 35, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (106, 35, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (107, 35, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (108, 36, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (109, 36, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (110, 36, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (111, 36, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (112, 36, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (113, 37, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (114, 37, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (115, 37, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (116, 37, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (117, 37, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (118, 38, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (119, 38, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (120, 38, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (121, 38, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (122, 38, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (123, 39, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (124, 39, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (125, 39, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (126, 39, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (127, 39, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (128, 40, 0, 'Superior (S)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (129, 40, 1, 'Very Good (A)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (130, 40, 2, 'Good (B+)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (131, 40, 3, 'Slightly Poor (B-)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (132, 40, 4, 'Poor (C)');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (133, 41, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (134, 41, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (135, 41, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (136, 43, 0, 'Three Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (137, 43, 1, 'Two Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (138, 43, 2, 'One Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (139, 44, 0, 'Three Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (140, 44, 1, 'Two Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (141, 44, 2, 'One Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (142, 45, 0, 'Grade 1');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (143, 45, 1, 'Grade 2');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (144, 45, 2, 'Grade 3');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (145, 46, 0, '3 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (146, 47, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (147, 47, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (148, 47, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (149, 47, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (150, 48, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (151, 48, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (152, 48, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (153, 48, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (154, 48, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (155, 49, 0, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (156, 49, 1, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (157, 49, 2, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (158, 49, 3, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (159, 49, 4, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (160, 51, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (161, 51, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (162, 51, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (163, 51, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (164, 52, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (165, 52, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (166, 52, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (167, 52, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (168, 53, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (169, 53, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (170, 53, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (171, 53, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (172, 57, 0, 'Zero Carbon');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (173, 57, 1, 'Advanced');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (174, 57, 2, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (175, 60, 0, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (176, 60, 1, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (177, 60, 2, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (178, 61, 0, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (179, 61, 1, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (180, 61, 2, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (181, 62, 0, 'Approved with Distinction');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (182, 62, 1, 'Approved');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (183, 69, 0, '4 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (184, 69, 1, '3 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (185, 69, 2, '2 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (186, 69, 3, '1 Green Globe');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (187, 70, 0, '4 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (188, 70, 1, '3 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (189, 70, 2, '2 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (190, 70, 3, '1 Green Globe');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (191, 71, 0, '4 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (192, 71, 1, '3 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (193, 71, 2, '2 Green Globes');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (194, 71, 3, '1 Green Globe');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (195, 78, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (196, 78, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (197, 78, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (198, 79, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (199, 79, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (200, 79, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (201, 80, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (202, 80, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (203, 80, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (204, 81, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (205, 81, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (206, 81, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (207, 82, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (208, 82, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (209, 82, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (210, 83, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (211, 83, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (212, 83, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (213, 83, 3, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (214, 83, 4, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (215, 83, 5, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (216, 84, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (217, 84, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (218, 84, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (219, 84, 3, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (220, 84, 4, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (221, 84, 5, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (222, 85, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (223, 85, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (224, 85, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (225, 86, 0, '6 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (226, 86, 1, '5 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (227, 86, 2, '4 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (228, 86, 3, '3 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (229, 86, 4, '2 Stars');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (230, 86, 5, '1 Star');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (231, 90, 0, 'Excellent Class');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (232, 90, 1, 'Good Class');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (233, 98, 0, 'Living');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (234, 98, 1, 'Petal');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (235, 100, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (236, 100, 1, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (237, 101, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (238, 101, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (239, 101, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (240, 101, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (241, 102, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (242, 102, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (243, 102, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (244, 102, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (245, 103, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (246, 103, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (247, 103, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (248, 103, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (249, 104, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (250, 104, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (251, 104, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (252, 104, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (253, 105, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (254, 105, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (255, 105, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (256, 105, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (257, 106, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (258, 106, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (259, 106, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (260, 106, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (261, 107, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (262, 107, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (263, 107, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (264, 107, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (265, 108, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (266, 108, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (267, 108, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (268, 108, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (269, 109, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (270, 109, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (271, 109, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (272, 109, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (273, 110, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (274, 110, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (275, 110, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (276, 110, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (277, 111, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (278, 111, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (279, 111, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (280, 112, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (281, 112, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (282, 112, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (283, 113, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (284, 113, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (285, 113, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (286, 122, 0, 'EXCEPTIONNEL');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (287, 122, 1, 'EXCELLENT');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (288, 122, 2, 'TRES BON');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (289, 122, 3, 'BON');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (290, 122, 4, 'PASS');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (291, 123, 0, 'EXCEPTIONNEL');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (292, 123, 1, 'EXCELLENT');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (293, 123, 2, 'TRES BON');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (294, 123, 3, 'BON');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (295, 123, 4, 'PASS');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (296, 124, 0, 'Emerald');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (297, 124, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (298, 124, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (299, 124, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (300, 125, 0, 'Emerald');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (301, 125, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (302, 125, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (303, 125, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (304, 126, 0, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (305, 126, 1, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (306, 126, 2, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (307, 126, 3, 'Pioneer');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (308, 128, 0, 'Premium');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (309, 128, 1, 'Plus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (310, 128, 2, 'Classic');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (311, 129, 0, 'Premium');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (312, 129, 1, 'Plus');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (313, 129, 2, 'Classic');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (314, 141, 0, 'Tier 4');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (315, 141, 1, 'Tier 3');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (316, 141, 2, 'Tier 2');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (317, 142, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (318, 142, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (319, 142, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (320, 142, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (321, 143, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (322, 143, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (323, 143, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (324, 143, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (325, 144, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (326, 144, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (327, 144, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (328, 144, 3, 'Bronze');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (329, 144, 4, 'GreenPartner');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (330, 145, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (331, 145, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (332, 145, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (333, 145, 3, 'Certified');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (334, 146, 0, 'for Indoor Environmental Quality');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (335, 146, 1, 'for Indoor Air and Water');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (336, 146, 2, 'for Indoor Air');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (337, 147, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (338, 147, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (339, 147, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (340, 148, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (341, 148, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (342, 148, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (343, 149, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (344, 149, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (345, 149, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (346, 150, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (347, 150, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (348, 150, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (349, 151, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (350, 151, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (351, 151, 2, 'Silver');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (352, 152, 0, 'Platinum');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (353, 152, 1, 'Gold');
INSERT INTO csr.certification_level (certification_level_id, certification_id, position, name) VALUES (354, 152, 2, 'Silver');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (1, 1, 64, 'Arc Energy Performance Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (2, 1, 65, 'Arc Energy Performance Score');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (3, 1, 66, 'BBC Effinergie');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (4, 1, 67, 'BBC Effinergie Rénovation');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (5, 1, 48, 'BCA BESS (Building Energy Submission System) Benchmarking');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (6, 1, 49, 'BELS');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (7, 1, 68, 'BEPOS Effinergie');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (8, 1, 69, 'BEPOS+ Effinergie');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (9, 1, 50, 'Building Energy Rating (BER) Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (10, 1, 51, 'DPE (Diagnostic de performance énergétique)');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (11, 1, 52, 'Energiattest - Norway');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (12, 1, 53, 'Energideklaration - Sweden');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (13, 1, 70, 'Energy Index - NL');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (14, 1, 47, 'Energy Star Certified - 75-79 Points');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (15, 1, 46, 'Energy Star Certified - 80-84 Points');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (16, 1, 45, 'Energy Star Certified - 85-89 Points');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (17, 1, 44, 'Energy Star Certified - 90-95 Points');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (18, 1, 43, 'Energy Star Certified - 96-100 Points');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (19, 1, 54, 'Energy Star Portfolio Manager');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (20, 1, 55, 'EnEV Energieausweise');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (21, 1, 3, 'EU EPC - A');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (22, 1, 2, 'EU EPC - A+');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (23, 1, 1, 'EU EPC - A++');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (24, 1, 83, 'EU EPC - A+++');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (25, 1, 84, 'EU EPC - A++++');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (26, 1, 13, 'EU EPC - A1');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (27, 1, 14, 'EU EPC - A2');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (28, 1, 15, 'EU EPC - A3');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (29, 1, 85, 'EU EPC - A4');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (30, 1, 4, 'EU EPC - B');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (31, 1, 5, 'EU EPC - B-');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (32, 1, 16, 'EU EPC - B1');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (33, 1, 17, 'EU EPC - B2');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (34, 1, 18, 'EU EPC - B3');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (35, 1, 26, 'EU EPC - Belgium');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (36, 1, 6, 'EU EPC - C');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (37, 1, 19, 'EU EPC - C1');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (38, 1, 20, 'EU EPC - C2');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (39, 1, 21, 'EU EPC - C3');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (40, 1, 7, 'EU EPC - D');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (41, 1, 22, 'EU EPC - D1');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (42, 1, 23, 'EU EPC - D2');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (43, 1, 8, 'EU EPC - E');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (44, 1, 24, 'EU EPC - E1');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (45, 1, 25, 'EU EPC - E2');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (46, 1, 9, 'EU EPC - F');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (47, 1, 10, 'EU EPC - G');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (48, 1, 11, 'EU EPC - H');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (49, 1, 12, 'EU EPC - I');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (50, 1, 27, 'EU EPC - Latvia');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (51, 1, 28, 'EU EPC - Poland');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (52, 1, 29, 'EU EPC - Slovenia');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (53, 1, 71, 'Fannie Mae Energy Performance Metric');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (54, 1, 56, 'GEAK');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (55, 1, 57, 'Green Star Performance Energy Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (56, 1, 58, 'HKGOC - Energywi$e Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (57, 1, 81, 'Hong Kong EMSD Energy Benchmarking');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (58, 1, 82, 'Hong Kong GBC BEST Tool');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (59, 1, 72, 'HPE (Haute Performance Energétique)');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (60, 1, 78, 'Japan e-mark');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (61, 1, 77, 'KEA Korea Building Energy Efficiency Certification');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (62, 1, 73, 'NABERS Co-Assess');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (63, 1, 41, 'NABERS Energy - 0.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (64, 1, 42, 'NABERS Energy - 0 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (65, 1, 39, 'NABERS Energy - 1.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (66, 1, 40, 'NABERS Energy - 1 Star');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (67, 1, 37, 'NABERS Energy - 2.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (68, 1, 38, 'NABERS Energy - 2 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (69, 1, 35, 'NABERS Energy - 3.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (70, 1, 36, 'NABERS Energy - 3 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (71, 1, 33, 'NABERS Energy - 4.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (72, 1, 34, 'NABERS Energy - 4 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (73, 1, 31, 'NABERS Energy - 5.5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (74, 1, 32, 'NABERS Energy - 5 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (75, 1, 30, 'NABERS Energy - 6 Stars');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (76, 1, 59, 'NatHERS');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (77, 1, 60, 'OID Taloen Benchmarking');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (78, 1, 74, 'Ontario EWRB');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (79, 1, 61, 'SIA 2031 Energy Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (80, 1, 75, 'Superior Energy Performance 50001');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (81, 1, 76, 'THPE (Très Haute Performance Energétique)');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (82, 1, 79, 'TMG Tokyo Energy Performance Certificate');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (83, 1, 80, 'TMG Tokyo Green Labelling for Condominiums');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (84, 1, 62, 'TMG Tokyo Small and Medium Scale Facilities');
INSERT INTO csr.energy_rating (energy_rating_id, certification_type_id, external_id, name) VALUES (85, 1, 63, 'TMG Tokyo Top-level Facility');
SET ESCAPE OFF;
DELETE FROM csr.module_param
 WHERE module_id = 65;
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
VALUES (65, 'Select GRESB environment (sandbox or live)', 0, '(sandbox|live)', 1);
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint, allow_blank)
VALUES (65, 'Floor Area Measure Type', 1, '(m^2|ft^2)', 1);
UPDATE csr.authentication_scope
   SET auth_scope = 'https://graph.microsoft.com/offline_access,https://graph.microsoft.com/openid,https://graph.microsoft.com/User.Read,https://graph.microsoft.com/Sites.ReadWrite.All'
 WHERE auth_scope_id = 2;
 




create or replace package csr.region_certificate_pkg as
procedure dummy;
end;
/
create or replace package body csr.region_certificate_pkg as
procedure dummy
as
begin
	null;
end;
end;
/
GRANT EXECUTE ON csr.region_certificate_pkg TO web_user;


@..\region_certificate_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\enable_pkg
@..\user_profile_pkg
@..\region_pkg
@..\issue_pkg
@..\delegation_pkg
@..\customer_pkg
@..\..\..\aspen2\cms\db\form_pkg
@..\core_access_pkg
@..\initiative_pkg
@..\quick_survey_pkg


@..\csr_app_body
@..\region_certificate_body
@..\schema_body
@..\csrimp\imp_body
@..\enable_body
@..\user_profile_body
@..\region_body
@..\issue_body
@..\delegation_body
@..\customer_body
@..\..\..\aspen2\cms\db\form_body
@..\core_access_body
@..\integration_question_answer_report_body
@..\initiative_body
@..\initiative_grid_body
@..\initiative_report_body
@..\quick_survey_body



@update_tail

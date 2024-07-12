-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=25
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_activity_sub_type (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	activity_type_id				NUMBER(10,0) NOT NULL,
	activity_sub_type_id			NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	pos								NUMBER(10),
	CONSTRAINT pk_compl_activity_sub_type
		PRIMARY KEY (app_sid, activity_type_id, activity_sub_type_id),
	CONSTRAINT fk_compl_activity_sub_type
		FOREIGN KEY (app_sid, activity_type_id)
		REFERENCES csr.compliance_activity_type (app_sid, activity_type_id)
);

CREATE SEQUENCE csr.compliance_activ_sub_type_seq START WITH 10000;

CREATE TABLE CSRIMP.COMPLIANCE_ACTIVITY_SUB_TYPE (
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ACTIVITY_TYPE_ID 				NUMBER(10,0) NOT NULL,
	ACTIVITY_SUB_TYPE_ID 			NUMBER(10,0) NOT NULL,
	DESCRIPTION 					VARCHAR2(1024) NOT NULL,
	POS 							NUMBER(10),
	CONSTRAINT PK_COMPLIANCE_ACTIVITY_SB_TYP PRIMARY KEY (CSRIMP_SESSION_ID, ACTIVITY_TYPE_ID, ACTIVITY_SUB_TYPE_ID),
	CONSTRAINT FK_COMPLIA_ACTIV_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPL_ACTIVITY_SUB_TYPE (
	CSRIMP_SESSION_ID 				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPL_ACTIVITY_SUB_TYPE_ID 	NUMBER(10) NOT NULL,
	NEW_COMPL_ACTIVITY_SUB_TYPE_ID 	NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPL_ACT_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csr.std_compl_activity_type (
	activity_type_id				NUMBER(10) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_activity_type PRIMARY KEY (activity_type_id)
);

CREATE TABLE csr.std_compl_activity_sub_type (
	activity_type_id				NUMBER(10) NOT NULL,
	activity_sub_type_id			NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_activity_sub_type
		PRIMARY KEY (activity_type_id, activity_sub_type_id),
	CONSTRAINT fk_std_activity_sub_type
		FOREIGN KEY (activity_type_id)
		REFERENCES csr.std_compl_activity_type (activity_type_id)
);

CREATE TABLE csr.std_compl_application_type (
	application_type_id				NUMBER(10) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_application_type PRIMARY KEY (application_type_id)
);

CREATE TABLE csr.std_compl_condition_type (
	condition_type_id				NUMBER(10) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_condition_type PRIMARY KEY (condition_type_id)
);

CREATE TABLE csr.std_compl_condition_sub_type (
	condition_type_id				NUMBER(10,0) NOT NULL,
	condition_sub_type_id			NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_cond_sub_type
		PRIMARY KEY (condition_type_id, condition_sub_type_id),
	CONSTRAINT fk_std_cond_sub_type
		FOREIGN KEY (condition_type_id)
		REFERENCES csr.std_compl_condition_type (condition_type_id)
);

CREATE TABLE csr.std_compl_permit_type (
	permit_type_id					NUMBER(10) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_permit_type PRIMARY KEY (permit_type_id)
);

CREATE TABLE csr.std_compl_permit_sub_type (
	permit_type_id					NUMBER(10) NOT NULL,
	permit_sub_type_id				NUMBER(10) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_std_compl_permit_sub_type PRIMARY KEY (permit_type_id, permit_sub_type_id),
	CONSTRAINT fk_std_permit_sub_type
		FOREIGN KEY (permit_type_id)
		REFERENCES csr.std_compl_permit_type (permit_type_id)
);

DROP SEQUENCE csr.compliance_activity_type_seq;
DROP SEQUENCE csr.compliance_application_tp_seq;
DROP SEQUENCE csr.compliance_condition_type_seq;
DROP SEQUENCE csr.compliance_cond_sub_type_seq;
DROP SEQUENCE csr.compliance_permit_type_seq;
DROP SEQUENCE csr.compliance_permit_sub_type_seq;

CREATE SEQUENCE csr.compliance_activity_type_seq START WITH 10000;
CREATE SEQUENCE csr.compliance_application_tp_seq START WITH 10000;
CREATE SEQUENCE csr.compliance_condition_type_seq START WITH 10000;
CREATE SEQUENCE csr.compliance_cond_sub_type_seq START WITH 10000;
CREATE SEQUENCE csr.compliance_permit_type_seq START WITH 10000;
CREATE SEQUENCE csr.compliance_permit_sub_type_seq START WITH 10000;

-- Alter tables
ALTER TABLE csr.compliance_permit MODIFY permit_sub_type_id NULL;
ALTER TABLE csr.compliance_permit ADD (
	activity_sub_type_id			NUMBER(10),
	CONSTRAINT fk_compl_permit_activ_sub_type
		FOREIGN KEY (app_sid, activity_type_id, activity_sub_type_id)
		REFERENCES csr.compliance_activity_sub_type (app_sid, activity_type_id, activity_sub_type_id)
);

ALTER TABLE csr.compliance_permit_condition MODIFY condition_sub_type_id NULL;

ALTER TABLE csr.compliance_permit_type ADD (pos NUMBER(10));
ALTER TABLE csr.compliance_permit_sub_type ADD (pos NUMBER(10));
ALTER TABLE csr.compliance_condition_type ADD (pos NUMBER(10));
ALTER TABLE csr.compliance_condition_sub_type ADD (pos NUMBER(10));
ALTER TABLE csr.compliance_activity_type ADD (pos NUMBER(10));
ALTER TABLE csr.compliance_application_type ADD (pos NUMBER(10));

ALTER TABLE csrimp.compliance_permit_type ADD (pos NUMBER(10));
ALTER TABLE csrimp.compliance_permit_sub_type ADD (pos NUMBER(10));
ALTER TABLE csrimp.compliance_condition_type ADD (pos NUMBER(10));
ALTER TABLE csrimp.compliance_condition_sub_type ADD (pos NUMBER(10));
ALTER TABLE csrimp.compliance_activity_type ADD (pos NUMBER(10));
ALTER TABLE csrimp.compliance_application_type ADD (pos NUMBER(10));

-- *** Grants ***
GRANT SELECT ON csr.compliance_activity_type_seq TO csrimp;
GRANT SELECT ON csr.compliance_application_tp_seq TO csrimp;
GRANT SELECT ON csr.compliance_cond_sub_type_seq TO csrimp;
GRANT SELECT ON csr.compliance_condition_type_seq TO csrimp;
GRANT SELECT ON csr.compliance_permit_sub_type_seq TO csrimp;
GRANT SELECT ON csr.compliance_permit_type_seq TO csrimp;
GRANT SELECT ON csr.compliance_activ_sub_type_seq TO csrimp;

grant select, insert, update on csr.compliance_activity_sub_type to csrimp;
grant select, insert, update, delete on csrimp.compliance_activity_sub_type to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (1, 'Grant');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (2, 'Renewal');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (3, 'Variation');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (4, 'Transfer');
	INSERT INTO csr.std_compl_application_type(application_type_id, description) VALUES (5, 'Surrender');
END;
/

BEGIN
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (1, 'Installation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (2, 'Waste operation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (3, 'Mining waste operation');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (4, 'Small waste incineration plant');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (5, 'Mobile plant');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (6, 'Solvent emissions');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (7, 'Stand-alone water discharge');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (8, 'Groundwater activity');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (9, 'Flood risk activities on or near a main river or sea defence');
	INSERT INTO csr.std_compl_activity_type(activity_type_id, description) VALUES (10, 'Radioactive substances');
	
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 1, 'ERF');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 2, 'Landfill');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 3, 'Composting');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 4, 'HWRC');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 5, 'Transfer Station');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 6, 'Decommissioning');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 7, 'RDF');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 8, 'WWTW');
	INSERT INTO csr.std_compl_activity_sub_type(activity_type_id, activity_sub_type_id, description) VALUES (2, 9, 'IWMF');
END;
/

BEGIN
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (1, 'Management');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (2, 'Operations');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (3, 'Emissions and monitoring');
	INSERT INTO csr.std_compl_condition_type(condition_type_id, description) VALUES (4, 'Information');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 1, 'General Management');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 2, 'Finance');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 3, 'Energy efficiency');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 4, 'Multiple operator installations');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 5, 'Efficient use of raw materials');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (1, 6, 'Avoidance, recovery and disposal of wastes');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 1, 'Permitted activities');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 2, 'The site');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 3, 'Landfill Engineering');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 4, 'Waste acceptance');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 5, 'Leachate levels');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 6, 'Operating techniques');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 7, 'Volume');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 8, 'Discharge Period');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 9, 'Technical Requirements');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 10, 'Improvement');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 11, 'Pre-operational');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 12, 'Closure and aftercare');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 13, 'Landfill gas management');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (2, 14, 'Pestsk');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 1, 'Emissions to water, air or land');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 2, 'Emissions of substances not controlled by emission limits');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 3, 'Monitoring');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 4, 'Odour');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 5, 'Noise and vibration');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 6, 'Pests');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 7, 'Monitoring for the purposes of the Large Combustion Plant Directive');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (3, 8, 'Air Quality Management Plan');
	
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 1, 'Records');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 2, 'Reporting');
	INSERT INTO csr.std_compl_condition_sub_type(condition_type_id, condition_sub_type_id, description) VALUES (4, 3, 'Notifications');
END;
/

BEGIN
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (1, 'SR: Biological treatment of waste');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (2, 'SR: Flood risk activities');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (3, 'SR: Installations');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (4, 'SR: Low impact installation');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (5, 'SR: Keeping/transfer of waste');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (6, 'SR: Metal recovery/scrap metal');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (7, 'SR: Materials recovery and recycling');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (8, 'SR: Onshore oil and gas exploration, and mining operation');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (9, 'SR: Radioactive substances for non-nuclear sites');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (10, 'SR: Recovery or use of waste on land');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (11, 'SR: Treatment to produce aggregate or construction materials');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (12, 'SR: Water discharges');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (13, 'Bespoke');
	INSERT INTO csr.std_compl_permit_type(permit_type_id, description) VALUES (14, 'Exemption');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 1, 'SR2008 No. 16 25kte and 75kte: composting in open systems (no longer available)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 2, 'SR2008 No. 17 75kte: composting in closed systems (in-vessel composting)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 3, 'SR2008 No. 18 75kte: non hazardous mechanical biological (aerobic) treatment facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 4, 'SR2015 No. 12 75kte non-hazardous mechanical biological (aerobic) treatment facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 5, 'SR2008 No. 19 75kte: non-hazardous sludge biological chemical and physical treatment site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 6, 'SR2008 No. 19 250kte: non-hazardous sludge biological chemical and physical treatment site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 7, 'SR2009 No. 4: combustion of biogas in engines at a sewage treatment works');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 8, 'SR2010 No. 14 500t: composting biodegradable waste');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 9, 'SR2010 No. 15: anaerobic digestion facility including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 10, 'SR2010 No. 16: on-farm anaerobic digestion facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 11, 'SR2010 No. 17: storage of digestate from anaerobic digestion plants');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 12, 'SR2010 No. 18: storage and treatment of dredgings for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 13, 'SR2011 No. 1 500t: composting biodegradable waste (in open and closed systems)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 14, 'SR2012 No. 3: composting in closed systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 15, 'SR2012 No. 7: composting in open systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 16, 'SR2012 No. 10: on-farm anaerobic digestion facility using farm wastes only, including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (1, 17, 'SR2012 No. 12: anaerobic digestion facility including use of the resultant biogas (waste recovery operation)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 1, 'SR2015 No. 26: temporary dewatering affecting up to 20 metres of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 2, 'SR2015 No. 27: constructing an outfall pipe of 300mm to 500mm diameter');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 3, 'SR2015 No. 28: installing a clear span bridge on a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 4, 'SR2015 No. 29: temporary storage within the flood plain of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 5, 'SR2015 No. 30: temporary diversion of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 6, 'SR2015 No. 31: channel habitat structure made of natural materials');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 7, 'SR2015 No. 32: installing a access culvert of no more than 5 metres length');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 8, 'SR2015 No. 33: repairing and protecting up to 20 metres of the bank of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 9, 'SR2015 No. 34: temporary scaffolding affecting up to 20 metres length of a main river');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 10, 'SR2015 No. 35: excavating a wetland or pond in a main river floodplain');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 11, 'SR2015 No. 36: installing and using site investigation boreholes and temporary trial pits within a main river floodplain for a period of up to 4 weeks');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (2, 12, 'SR2015 No. 38: removing a total of 100 metres of exposed gravel from bars and shoals');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 1, 'SR2012 No. 4: composting in closed systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 2, 'SR2012 No. 8: composting in open systems');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 3, 'SR2012 No. 9: on-farm anaerobic digestion using farm wastes');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 4, 'SR2012 No. 11: anaerobic digestion facility including use of the resultant biogas');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (3, 5, 'SR2012 No. 13: treatment of Incinerator Bottom Ash (IBA)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (4, 1, 'SR2009 No. 2: low impact part A installation');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (4, 2, 'SR2009 No. 3: low impact part A installation for the production of biodiesel');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 1, 'SR2008 No. 1 75kte: household, commercial and industrial waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 2, 'SR2015 No. 4 75kte: household, commercial and industrial waste transfer station');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 3, 'SR2008 No. 2: household, commercial and industrial waste transfer station (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 4, 'SR2015 No. 5: household, commercial and industrial waste transfer station (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 5, 'SR2008 No. 3 75kte: household, commercial and industrial waste transfer station with treatment (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 6, 'SR2015 No. 6 75kte: household, commercial and industrial waste transfer station with treatment');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 7, 'SR2008 No. 4: household, commercial and industrial waste transfer station with treatment (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 8, 'SR2015 No. 7: household, commercial and industrial waste transfer station with treatment (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 9, 'SR2008 No. 5 75kte: household, commercial and industrial waste transfer station and asbestos storage (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 10, 'SR2015 No. 8 75kte: household, commercial and industrial waste transfer station with asbestos storage');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 11, 'SR2008 No. 6: household, commercial and industrial waste transfer station with asbestos storage (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 12, 'SR2015 No. 9: household, commercial and industrial waste transfer station with asbestos storage (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 13, 'SR2008 No. 7 75kte: household, commercial and industrial waste transfer station with treatment and asbestos storage (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 14, 'SR2015 No. 10 75kte: household, commercial and industrial waste transfer station with treatment and asbestos storage');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 15, 'SR2008 No. 8: household, commercial and industrial waste transfer station with treatment and asbestos storage (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 16, 'SR2015 No. 11: household, commercial and industrial waste transfer station with treatment and asbestos storage (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 17, 'SR2008 No. 9: asbestos waste transfer station');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 18, 'SR2008 No. 10 75kte: inert and excavation waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 19, 'SR2008 No. 11 75kte: inert and excavation waste transfer station with treatment (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 20, 'SR2008 No. 24 75Kte: clinical waste and healthcare waste transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 21, 'SR2008 No. 25 75kte: clinical waste and healthcare waste treatment and transfer station (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 22, 'SR2009 No. 5: inert and excavation waste transfer station below 250kte (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 23, 'SR2009 No. 6: inert and excavation waste transfer station with treatment below 250kte (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 24, 'SR2012 No. 15: storage of electrical insulating oils');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (5, 25, 'SR2013 No. 1: treatment of 100 t/y of clinical and healthcare waste');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 1, 'SR2012 No. 14: metal recycling, vehicle storage, depollution and dismantling facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 2, 'SR2015 No. 18: metal recycling, vehicle storage, depollution and dismantling facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 3, 'SR2008 No. 20 75kte: vehicle storage, depollution and dismantling (authorised treatment) facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 4, 'SR2015 No. 13 75kte: vehicle storage depollution and dismantling (authorised treatment) facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 5, 'SR2011 No. 2: metal recycling site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 6, 'SR2015 No. 16: metal recycling site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 7, 'SR2008 No. 21 75kte: metal recycling site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 8, 'SR2015 No. 14 75kte: metal recycling site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 9, 'SR2009 No. 7: storage of furnace ready scrap metal for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 10, 'SR2008 No. 22 75kte: storage of furnace ready scrap metal for recovery');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 11, 'SR2008 No. 23 75kte: WEEE authorised treatment facility excluding ozone depleting substances (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 12, 'SR2015 No. 15 75kte: WEEE authorised treatment facility excluding ozone depleting substances');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 13, 'SR2015 No. 3: metal recycling and WEEE authorised treatment facility excluding ozone depleting substances');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 14, 'SR2011 No. 3: vehicle storage depollution and dismantling (authorised treatment) facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (6, 15, 'SR2015 No. 17: vehicle storage depollution and dismantling authorised treatment facility');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 1, 'SR2008 No. 12 75kte: non hazardous household waste amenity site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 2, 'SR2015 No. 19 75kte: non-hazardous household waste amenity site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 3, 'SR2008 No. 13 75kte: non-hazardous and hazardous household waste amenity site (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 4, 'SR2015 No. 20 75kte: non-hazardous and hazardous household waste amenity site');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 5, 'SR2008 No. 14 75kte: materials recycling facility (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 6, 'SR2015 No. 21 75kte: materials recycling facility');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 7, 'SR2008 No. 15: materials recycling facility (no building) (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 8, 'SR2015 No. 22: Materials recycling facility (no building)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 9, 'SR2011 No. 4: treatment of waste wood for recovery (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (7, 10, 'SR2015 No. 23: treatment of waste wood for recovery'); 
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 1, 'SR2009 No. 8: management of inert wastes and unpolluted soil at mines and quarries');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 2, 'SR2014 No. 2: the management of extractive waste');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 3, 'SR2015 No. 2: storage and handling of crude oil');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (8, 4, 'SR2015 No. 1: onshore oil exploration');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (9, 1, 'SR2010 No. 1: category 5 sealed radioactive sources standard rules');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (9, 2, 'SR2014 No. 4: NORM waste from oil and gas production');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 1, 'SR2015 No. 39: use of waste in a deposit for recovery operation');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 2, 'SR2008 No. 27: mobile plant for the treatment of soils and contaminated material, substances or products');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 3, 'SR2010 No. 4: mobile plant for land-spreading');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 4, 'SR2010 No. 5: mobile plant for reclamation, restoration or improvement of land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 5, 'SR2010 No. 6: mobile plant for land-spreading of sewage sludge');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 6, 'SR2010 No. 7 50kte: use of waste in construction (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 7, 'SR2010 No. 8: use of waste in construction (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 8, 'SR2010 No. 9: use of waste for reclamation, restoration or improvement of land (existing permits)');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (10, 9, 'SR2010 No. 10: standard rules to operate waste for reclamation, restoration or improvement of land (existing permits)');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 1, 'SR2010 No. 11: mobile plant for the treatment of waste to produce soil, soil substitutes and aggregate');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 2, 'SR2010 No. 12: treatment of waste to produce soil, soil substitutes and aggregate');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 3, 'SR2010 No. 13: use of waste to manufacture timber or construction products');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (11, 4, 'SR2015 No. 24: use of waste to manufacture timber or construction products');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (12, 1, 'SR2010 No. 2: discharge to surface water');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (12, 2, 'SR2010 No. 3: discharge to surface water');
	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 1, 'Waste exemption: D1 depositing waste from dredging inland waters');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 2, 'Waste exemption: D2 depositing waste from a railway sanitary convenience');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 3, 'Waste exemption: D3 depositing waste from a portable sanitary convenience');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 4, 'Waste exemption: D4 depositing agricultural waste consisting of plant tissue under a Plant Health Notice');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 5, 'Waste exemption: D5 depositing waste samples for testing or analysis');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 6, 'Waste exemption: D6 disposal by incineration');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 7, 'Waste exemption: D7 burning waste in the open');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 8, 'Waste exemption: D8 burning waste at a port under a Plant Health Notice');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 9, 'Waste exemption: NWFD 2 temporary storage at the place of production');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 10, 'Waste exemption: NWFD 3 temporary storage of waste at a place controlled by the producer');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 11, 'Waste exemption: NWFD 4 temporary storage at a collection point');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 12, 'Waste exemption: S1 storing waste in secure containers');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 13, 'Waste exemption: S2 storing waste in a secure place');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 14, 'Waste exemption: S3 storing sludge');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 15, 'Waste exemption: T22 treatment of animal by-product waste at a collection centre');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 16, 'Waste exemption: T3 treatment of waste metals and metal alloys by heating for the purposes of removing grease');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 17, 'Waste exemption: T7 treatment of waste bricks, tiles and concrete by crushing, grinding or reducing in size');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 18, 'Waste exemption: U10 spreading waste to benefit agricultural land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 19, 'Waste exemption: U11 spreading waste to benefit non-agricultural land');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 20, 'Waste exemption: U12 using mulch');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 21, 'Waste exemption: U13 spreading plant matter to provide benefits');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 22, 'Waste exemption: U14 incorporating ash into soil');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 23, 'Waste exemption: U15 pig and poultry ash');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 24, 'Waste exemption: U16 using depolluted end-of-life vehicles for parts');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 25, 'Waste exemption: U2 use of baled end-of-life tyres in construction');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 26, 'Waste exemption: U3 construction of entertainment or educational installations');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 27, 'Waste exemption: U4 burning of waste as a fuel in a small appliance');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 28, 'Waste exemption: U5 using biodiesel produced from waste as fuel');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 29, 'Waste exemption: U6 using sludge to re-seed a waste water treatment plant');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 30, 'Waste exemption: U7 using effluent to clean a highway gravel bed');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 31, 'Waste exemption: U8 using waste for a specified purpose');
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 32, 'Waste exemption: U9 using waste to manufacture finished goods');	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 33, 'Groundwater tracer');	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 34, 'Groundwater remediation');	
	INSERT INTO csr.std_compl_permit_sub_type(permit_type_id, permit_sub_type_id, description) VALUES (14, 35, 'Flood');	
END;
/

DECLARE
	v_dummy_sid		NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
	     WHERE LOWER(action) IN ('/csr/site/compliance/admin/menu.acds', '/csr/site/compliance/admin/configure.acds')
	) LOOP
		security.securableobject_pkg.DeleteSo(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
	
	FOR r IN (
		SELECT app_sid
		  FROM csr.compliance_options
	) LOOP
		BEGIN
			security.menu_pkg.CreateMenu(
				security.security_pkg.GetAct, 
				security.securableObject_pkg.GetSIDFromPath(security.security_pkg.GetAct, r.app_sid, 'menu/admin'), 
				'csr_compliance_admin', 
				'Compliance admin', 
				'/csr/site/compliance/admin/Menu.acds', 
				21, null, v_dummy_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../schema_pkg
@@../compliance_pkg

@@../schema_body
@@../enable_body
@@../compliance_body
@@../csrimp/imp_body

@update_tail

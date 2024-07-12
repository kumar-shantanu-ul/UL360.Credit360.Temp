define version=2915
define minor_version=0
define is_combined=1
@update_header

declare
	v_exists number;

	procedure dc(in_tn varchar2, in_cn varchar2) as
		v_exists number;
	begin
		select count(*) into v_exists from all_constraints where owner='CSRIMP' and table_name=in_tn and constraint_name=in_cn;
		if v_exists = 1 then
			execute immediate 'alter table csrimp.'||in_tn||' drop constraint '||in_cn;
		end if;
	end;
begin	
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISS_CUST_FLD_DATE_FLD');
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISSUE_CUST_FLD_DATE_VAL');
	dc('ISSUE_CUSTOM_FIELD_DATE_VAL', 'FK_ISSUE_CUST_IS');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_IND_QSST');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_QS_QSST');
	dc('QUICK_SURVEY_SCORE_THRESHOLD', 'FK_ST_QSST');
	dc('SUPPLIER_SURVEY_RESPONSE', 'FK_SUPP_SURV_RESP_QK_SURV_RESP');
	dc('SUPPLIER_SURVEY_RESPONSE', 'FK_SUPP_SURV_RESP_SUPPLIER');
	
	select count(*) into v_exists from all_constraints where constraint_name='FK_ISS_CUST_FLD_IS' and owner='CSRIMP' and table_name='ISSUE_CUSTOM_FIELD_DATE_VAL';
	if v_exists = 0 then execute immediate
		'alter table csrimp.ISSUE_CUSTOM_FIELD_DATE_VAL add CONSTRAINT FK_ISS_CUST_FLD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE';
	end if;
end;
/

begin
	for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION' and temporary='N') loop
		dbms_output.put_line('tab '||r.table_name);
		execute immediate 'truncate table csrimp.'||r.table_name;
	end loop;
	delete from csrimp.csrimp_session;
end;
/

CREATE SEQUENCE csr.region_score_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE csr.region_score_log (
	app_sid			   				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_score_log_id	 			NUMBER(10, 0)	NOT NULL,
	region_sid		 				NUMBER(10, 0)	NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	score_threshold_id				NUMBER(10, 0),
	score							NUMBER(15, 5),
	set_dtm							DATE			DEFAULT SYSDATE NOT NULL,
	changed_by_user_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	comment_text					CLOB,
	CONSTRAINT pk_region_score_log PRIMARY KEY (app_sid, region_score_log_id),
	CONSTRAINT fk_region_score_log_type FOREIGN KEY (app_sid, score_type_id) 
		REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_region_score_log_user FOREIGN KEY (app_sid, changed_by_user_sid) 
		REFERENCES csr.csr_user (app_sid, csr_user_sid),
	CONSTRAINT fk_region_score_log_region FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_region_score_log_thresh_id FOREIGN KEY (app_sid, score_threshold_id)
		REFERENCES csr.score_threshold (app_sid, score_threshold_id)
);
CREATE TABLE csr.region_score (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	last_region_score_log_id 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_region_score PRIMARY KEY (app_sid, score_type_id, region_sid),
	CONSTRAINT fk_region_score_score_type FOREIGN KEY (app_sid, score_type_id) 
		REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_region_score_region FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_region_score_last_score FOREIGN KEY (app_sid, last_region_score_log_id) 
		REFERENCES csr.region_score_log (app_sid, region_score_log_id)
);
CREATE INDEX csr.ix_region_score_last_region_s ON csr.region_score (app_sid, last_region_score_log_id);
CREATE INDEX csr.ix_region_score_region_sid ON csr.region_score (app_sid, region_sid);
CREATE INDEX csr.ix_region_score_changed_by_us ON csr.region_score_log (app_sid, changed_by_user_sid);
CREATE INDEX csr.ix_region_score_score_type_id ON csr.region_score_log (app_sid, score_type_id);
CREATE INDEX csr.ix_region_score_score_thresho ON csr.region_score_log (app_sid, score_threshold_id);
CREATE INDEX csr.ix_region_score_log_region_sid ON csr.region_score_log (app_sid, region_sid);
CREATE TABLE csrimp.region_score_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_score_log_id	 			NUMBER(10, 0)	NOT NULL,
	region_sid		 				NUMBER(10, 0)	NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	score_threshold_id				NUMBER(10, 0),
	score							NUMBER(15, 5),
	set_dtm							DATE			DEFAULT SYSDATE NOT NULL,
	changed_by_user_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'SID'),
	comment_text					CLOB,
	CONSTRAINT pk_region_score_log PRIMARY KEY (csrimp_session_id, region_score_log_id),
	CONSTRAINT fk_region_score_log_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.region_score (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	score_type_id					NUMBER(10, 0)	NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	last_region_score_log_id 		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_region_score PRIMARY KEY (csrimp_session_id, score_type_id, region_sid),
	CONSTRAINT fk_region_score_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_region_score_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_region_score_log_id 		NUMBER(10)	NOT NULL,
	new_region_score_log_id 		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_region_score PRIMARY KEY (csrimp_session_id, old_region_score_log_id) USING INDEX,
	CONSTRAINT uk_map_region_score UNIQUE (csrimp_session_id, new_region_score_log_id) USING INDEX,
    CONSTRAINT fk_map_region_score_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);
CREATE OR REPLACE TYPE CSR.T_USER_GROUP_ROW AS
	OBJECT (
		CSR_USER_SID		NUMBER(10),
		GROUP_SID			NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_USER_GROUP_TABLE AS
  TABLE OF CSR.T_USER_GROUP_ROW;
/
CREATE TABLE CSR.EST_METER_CONV(
    METER_TYPE    VARCHAR2(256)    NOT NULL,
    UOM           VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK2018 PRIMARY KEY (METER_TYPE, UOM)
);
CREATE TABLE CSR.EST_METER_TYPE(
    METER_TYPE    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_EST_METER_TYPE PRIMARY KEY (METER_TYPE)
);
CREATE TABLE CSR.EST_PROPERTY_TYPE(
    EST_PROPERTY_TYPE    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_EST_PROPERTY_TYPE PRIMARY KEY (EST_PROPERTY_TYPE)
);
CREATE TABLE CSR.EST_SPACE_TYPE(
    EST_SPACE_TYPE    VARCHAR2(256)     NOT NULL,
    LABEL             VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_EST_SPACE_TYPE PRIMARY KEY (EST_SPACE_TYPE)
);
BEGIN
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Adult Education');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Ambulatory Surgical Center');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Aquarium');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Automobile Dealership');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Bank Branch');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Bar/Nightclub');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Barracks');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Bowling Alley');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Casino');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('College/University');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Convenience Store with Gas Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Convenience Store without Gas Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Convention Center');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Courthouse');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Data Center');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Distribution Center');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Drinking Water Treatment '||'&'||' Distribution');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Enclosed Mall');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Energy/Power Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Fast Food Restaurant');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Financial Office');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Fire Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Fitness Center/Health Club/Gym');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Food Sales');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Food Service');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Hospital (General Medical '||'&'||' Surgical)');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Hotel');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Ice/Curling Rink');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Indoor Arena');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('K-12 School');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Laboratory');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Library');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Lifestyle Center');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Mailing Center/Post Office');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Manufacturing/Industrial Plant');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Medical Office');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Mixed Use Property');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Movie Theater');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Multifamily Housing');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Museum');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Non-Refrigerated Warehouse');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Office');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Education');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Entertainment/Public Assembly');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Lodging/Residential');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Mall');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Public Services');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Recreation');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Restaurant/Bar');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Services');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Stadium');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Technology/Science');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other - Utility');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Other/Specialty Hospital');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Outpatient Rehabilitation/Physical Therapy');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Parking');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Performing Arts');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Personal Services (Health/Beauty, Dry Cleaning, etc)');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Police Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Pre-school/Daycare');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Prison/Incarceration');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Race Track');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Refrigerated Warehouse');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Repair Services (Vehicle, Shoe, Locksmith, etc)');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Residence Hall/Dormitory');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Residential Care Facility');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Restaurant');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Retail Store');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Roller Rink');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Self-Storage Facility');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Senior Care Community');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Single Family Home');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Social/Meeting Hall');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Stadium (Closed)');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Stadium (Open)');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Strip Mall');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Supermarket/Grocery Store');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Swimming Pool');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Transportation Terminal/Station');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Urgent Care/Clinic/Other Outpatient');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Veterinary Office');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Vocational School');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Wastewater Treatment Plant');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Wholesale Club/Supercenter');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Worship Facility');
	INSERT INTO csr.est_property_type (est_property_type) VALUES ('Zoo');
END;
/
BEGIN
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('adultEducation', 'Adult Education');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('ambulatorySurgicalCenter', 'Ambulatory Surgical Center');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('aquarium', 'Aquarium');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('automobileDealership', 'Automobile Dealership');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('bankBranch', 'Bank Branch');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('barNightclub', 'Bar Nightclub');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('barracks', 'Barracks');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('bowlingAlley', 'Bowling Alley');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('casino', 'Casino');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('collegeUniversity', 'College University');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('convenienceStoreWithGasStation', 'Convenience Store With Gas Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('convenienceStoreWithoutGasStation', 'Convenience Store Without Gas Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('conventionCenter', 'Convention Center');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('courthouse', 'Courthouse');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('dataCenter', 'Data Center');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('distributionCenter', 'Distribution Center');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('drinkingWaterTreatmentAndDistribution', 'Drinking Water Treatment And Distribution');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('enclosedMall', 'Enclosed Mall');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('energyPowerStation', 'Energy Power Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('fastFoodRestaurant', 'Fast Food Restaurant');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('financialOffice', 'Financial Office');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('fireStation', 'Fire Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('fitnessCenterHealthClubGym', 'Fitness Center Health Club Gym');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('foodSales', 'Food Sales');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('foodService', 'Food Service');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('hospital', 'Hospital');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('hotel', 'Hotel');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('iceCurlingRink', 'Ice Curling Rink');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('indoorArena', 'Indoor Arena');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('k12School', 'K12 School');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('laboratory', 'Laboratory');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('library', 'Library');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('lifestyleCenter', 'Lifestyle Center');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('mailingCenterPostOffice', 'Mailing Center Post Office');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('manufacturingIndustrialPlant', 'Manufacturing Industrial Plant');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('medicalOffice', 'Medical Office');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('movieTheater', 'Movie Theater');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('multifamilyHousing', 'Multifamily Housing');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('museum', 'Museum');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('nonRefrigeratedWarehouse', 'Non Refrigerated Warehouse');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('office', 'Office');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('other', 'Other');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherEducation', 'Other Education');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherEntertainmentPublicAssembly', 'Other Entertainment Public Assembly');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherLodgingResidential', 'Other Lodging Residential');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherMall', 'Other Mall');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherPublicServices', 'Other Public Services');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherRecreation', 'Other Recreation');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherRestaurantBar', 'Other Restaurant Bar');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherServices', 'Other Services');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherSpecialityHospital', 'Other Speciality Hospital');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherStadium', 'Other Stadium');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherTechnologyScience', 'Other Technology Science');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('otherUtility', 'Other Utility');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('outpatientRehabilitationPhysicalTherapy', 'Outpatient Rehabilitation Physical Therapy');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('parking', 'Parking');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('performingArts', 'Performing Arts');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('personalServices', 'Personal Services');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('policeStation', 'Police Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('preschoolDaycare', 'Preschool Daycare');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('prison', 'Prison');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('raceTrack', 'Race Track');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('refrigeratedWarehouse', 'Refrigerated Warehouse');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('repairServices', 'Repair Services');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('residenceHallDormitory', 'Residence Hall Dormitory');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('residentialCareFacility', 'Residential Care Facility');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('restaurant', 'Restaurant');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('retail', 'Retail');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('rollerRink', 'Roller Rink');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('selfStorageFacility', 'Self Storage Facility');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('seniorCareCommunity', 'Senior Care Community');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('singleFamilyHome', 'Single Family Home');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('socialMeetingHall', 'Social Meeting Hall');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('stadiumClosed', 'Stadium Closed');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('stadiumOpen', 'Stadium Open');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('stripMall', 'Strip Mall');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('supermarket', 'Supermarket');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('swimmingPool', 'Swimming Pool');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('transportationTerminalStation', 'Transportation Terminal Station');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('urgentCareClinicOtherOutpatient', 'Urgent Care Clinic Other Outpatient');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('veterinaryOffice', 'Veterinary Office');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('vocationalSchool', 'Vocational School');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('wastewaterTreatmentPlant', 'Wastewater Treatment Plant');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('wholesaleClubSupercenter', 'Wholesale Club Supercenter');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('worshipFacility', 'Worship Facility');
	INSERT INTO csr.est_space_type (est_space_type, label) VALUES ('zoo', 'Zoo');
END;
/
BEGIN
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Coal Anthracite');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Coal Bituminous');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Coke');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Diesel');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Chilled Water - Electric-Driven Chiller');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Chilled Water - Other');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Hot Water');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('District Steam');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Electric');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Electric on Site Solar');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Electric on Site Wind');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Fuel Oil No 1');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Fuel Oil No 2');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Fuel Oil No 4');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Fuel Oil No 5 or 6');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Kerosene');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Natural Gas');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Other (Energy)');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Propane');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Wood');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('IT Equipment Input Energy (meters on each piece of equipment)');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Power Distribution Unit (PDU) Input Energy');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Power Distribution Unit (PDU) Output Energy');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Uninterruptible Power Supply (UPS) Output Energy');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Alternative Water Generated On-Site - Indoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Alternative Water Generated On-Site - Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Potable Water - Indoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Potable Water - Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Reclaimed Water - Indoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Municipally Supplied Reclaimed Water - Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Other - Mixed Indoor/Outdoor (Water)');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Other - Outdoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Other - Indoor');
	INSERT INTO csr.est_meter_type (meter_type) VALUES ('Average Influent Flow');
END;
/
BEGIN
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Indoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'tons');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'pounds');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'KLbs. (thousand pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'MLbs. (million pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'tons');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'pounds');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'KLbs. (thousand pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'MLbs. (million pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'tons');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'pounds');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'KLbs. (thousand pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'MLbs. (million pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'ton hours');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Electric-Driven Chiller', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Electric-Driven Chiller', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Electric-Driven Chiller', 'ton hours');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'ton hours');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Other', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Other', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Other', 'ton hours');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Hot Water', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Hot Water', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Hot Water', 'therms');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'pounds');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'KLbs. (thousand pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'MLbs. (million pounds)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'therms');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric', 'MWh (million Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Solar', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Solar', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Solar', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Solar', 'MWh (million Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Wind', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Wind', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Wind', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Wind', 'MWh (million Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Indoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'therms');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other (Energy)', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Outdoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'Gallons (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'Kcm (Thousand Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'KGal (thousand gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'MCF(million cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'MGal (million gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'MGal (million gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'cGal (hundred gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other - Indoor', 'cGal (hundred gallons) (UK)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Wood', 'kBtu (thousand Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Wood', 'MBtu (million Btu)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Wood', 'tons');
	-- Non-documented conversions below (derived from PM UI)
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('IT Equipment Input Energy (meters on each piece of equipment)', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Power Distribution Unit (PDU) Input Energy', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Power Distribution Unit (PDU) Output Energy', 'kWh (thousand Watt-hours)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Uninterruptible Power Supply (UPS) Output Energy', 'kWh (thousand Watt-hours)');
	-- Guessed conversions below (no document couldn't find in UI)
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'Gallons (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'KGal (thousand gallons) (US)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'Liters');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'ccf (hundred cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'cf (cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'cm (Cubic meters)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'kcf (thousand cubic feet)');
	INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Average Influent Flow', 'Gallons (UK)');
END;
/
BEGIN
	-- Property types
	DELETE FROM csr.est_property_type_map map
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_property_type t
	 	 WHERE t.est_property_type = map.est_property_type
	 );
	-- Space types
	DELETE FROM csr.est_space_type_map map
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_space_type t
	 	 WHERE t.est_space_type = map.est_space_type
	 );
	 DELETE FROM csr.est_space_type_attr attr
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_space_type t
	 	 WHERE t.est_space_type = attr.est_space_type
	 );
	-- Meter types
	DELETE FROM csr.est_conv_mapping map
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_meter_conv c
	 	 WHERE c.meter_type = map.meter_type
	 	   AND c.uom = map.uom
	 );
	DELETE FROM csr.est_meter_type_mapping map
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_meter_type t
	 	 WHERE t.meter_type = map.meter_type
	 );
END;
/
CREATE SEQUENCE CSR.GRESB_SUBMISSION_SEQ 
	START WITH 1 
	INCREMENT BY 1
	ORDER; 
CREATE TABLE CSR.GRESB_PROPERTY_TYPE (
	NAME	VARCHAR2(255),
	CODE	VARCHAR2(255),
	CONSTRAINT PK_GRESB_PROP_TYPE PRIMARY KEY (CODE)
);
CREATE TABLE CSR.GRESB_INDICATOR_TYPE (
	GRESB_INDICATOR_TYPE_ID				NUMBER(10, 0) NOT NULL,
	TITLE								VARCHAR2(255) NOT NULL,
	REQUIRED							NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_TYPE PRIMARY KEY (GRESB_INDICATOR_TYPE_ID)
);
CREATE TABLE CSR.GRESB_INDICATOR (
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	GRESB_INDICATOR_TYPE_ID			NUMBER(10, 0) NOT NULL,
	TITLE							VARCHAR2(255) NOT NULL,
	FORMAT							VARCHAR2(255),
	DESCRIPTION						VARCHAR2(4000),
	UNIT							VARCHAR2(255),
	STD_MEASURE_CONVERSION_ID		NUMBER(10,0),
	CONSTRAINT PK_GRESB_INDICATOR PRIMARY KEY (GRESB_INDICATOR_ID),
	CONSTRAINT FK_GI_STD_MC FOREIGN KEY (STD_MEASURE_CONVERSION_ID) REFERENCES CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID),
	CONSTRAINT FK_GI_GIT FOREIGN KEY (GRESB_INDICATOR_TYPE_ID) REFERENCES CSR.GRESB_INDICATOR_TYPE (GRESB_INDICATOR_TYPE_ID)
);
CREATE TABLE CSR.GRESB_ERROR (
	GRESB_ERROR_ID					VARCHAR2(255) NOT NULL,
	DESCRIPTION						VARCHAR2(4000) NULL,
	CONSTRAINT PK_GRESB_ERROR PRIMARY KEY (GRESB_ERROR_ID)
);
CREATE TABLE CSR.GRESB_INDICATOR_MAPPING (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	IND_SID							NUMBER(10, 0),
	MEASURE_CONVERSION_ID			NUMBER(10, 0),
	NOT_APPLICABLE					NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_MAPPING PRIMARY KEY (APP_SID, GRESB_INDICATOR_ID),
	CONSTRAINT FK_GIM_GI FOREIGN KEY (GRESB_INDICATOR_ID) REFERENCES CSR.GRESB_INDICATOR (GRESB_INDICATOR_ID),
	CONSTRAINT FK_GIM_IND FOREIGN KEY (APP_SID, IND_SID) REFERENCES CSR.IND (APP_SID, IND_SID),
	CONSTRAINT FK_GIM_MC FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID) REFERENCES CSR.MEASURE_CONVERSION (APP_SID, MEASURE_CONVERSION_ID)
);
CREATE TABLE CSR.GRESB_SUBMISSION_LOG (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	GRESB_SUBMISSION_ID				NUMBER(10, 0) NOT NULL,
	GRESB_RESPONSE_ID				VARCHAR2(255) NOT NULL,
	SUBMISSION_TYPE					NUMBER(10, 0) NOT NULL,
	SUBMISSION_DATE					DATE NOT NULL,
	SUBMISSION_DATA					CLOB NULL,
	CONSTRAINT PK_GRESB_SUBMISSION_LOG PRIMARY KEY (APP_SID, GRESB_SUBMISSION_ID),
	CONSTRAINT CK_SUBMISSION_TYPE_VALID CHECK (SUBMISSION_TYPE IN (0, 1))
);
CREATE TABLE csr.property_fund (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	container_sid					NUMBER(10, 0) NULL,
	CONSTRAINT pk_property_fund PRIMARY KEY (app_sid, region_sid, fund_id),
	CONSTRAINT fk_property_fund_region FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_property_fund_fund FOREIGN KEY (app_sid, fund_id) REFERENCES csr.fund (app_sid, fund_id),
	CONSTRAINT fk_property_fund_container FOREIGN KEY (app_sid, container_sid) REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT ck_ownership CHECK (ownership > 0 AND ownership <= 1)
);
CREATE INDEX csr.ix_property_fund_fund_id ON csr.property_fund (app_sid, fund_id);
CREATE TABLE CSRIMP.MAP_GRESB_SUBMISSION_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	NEW_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_GRESB_SUBMISSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_GRESB_SUBMISSION_ID) USING INDEX,
	CONSTRAINT FK_MAP_GRESB_SUBMISSION_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.GRESB_INDICATOR_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	IND_SID							NUMBER(10, 0) NOT NULL,
	MEASURE_CONVERSION_ID			NUMBER(10, 0),
	NOT_APPLICABLE					NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, GRESB_INDICATOR_ID),
	CONSTRAINT FK_GRESB_INDICATOR_MAPPING FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.GRESB_SUBMISSION_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GRESB_SUBMISSION_ID				NUMBER(10, 0) NOT NULL,
	GRESB_RESPONSE_ID				VARCHAR2(255) NOT NULL,
	SUBMISSION_TYPE					NUMBER(10, 0) NOT NULL,
	SUBMISSION_DATE					DATE NOT NULL,
	SUBMISSION_DATA					CLOB NULL,
	CONSTRAINT PK_GRESB_SUBMISSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, GRESB_SUBMISSION_ID),
	CONSTRAINT FK_GRESB_SUBMISSION_LOG FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csrimp.property_fund (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	container_sid					NUMBER(10, 0) NULL,
	CONSTRAINT pk_property_fund		PRIMARY KEY (csrimp_session_id, region_sid, fund_id),
	CONSTRAINT fk_property_fund		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csr.gresb_service_config (
	name							VARCHAR2(255) NOT NULL,
	url								VARCHAR2(255) NOT NULL,
	client_id						VARCHAR2(255) NOT NULL,
	client_secret					VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_gresb_service_config PRIMARY KEY (name)
);
CREATE UNIQUE INDEX csr.ix_gresb_service_config_name ON csr.gresb_service_config(LOWER(name));


ALTER TABLE CSR.DATAVIEW ADD (show_variance_explanations NUMBER(1,0) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.DATAVIEW_HISTORY ADD (show_variance_explanations NUMBER(1,0) DEFAULT 0 NOT NULL);
ALTER TABLE CSRIMP.DATAVIEW ADD (show_variance_explanations NUMBER(1,0) NOT NULL);
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD (show_variance_explanations NUMBER(1,0) NOT NULL);
ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB ADD CONSTRAINT FK_METINPAGG_METTYPCNGBATJOB 
    FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;
ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB ADD CONSTRAINT FK_METTYP_METTYPCNGBATJOB 
    FOREIGN KEY (APP_SID, METER_TYPE_ID)
    REFERENCES CSR.METER_TYPE(APP_SID, METER_TYPE_ID)
;
ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB DROP CONSTRAINT FK_METTYPINP_METTYPCNGBATJOB;
CREATE INDEX CSR.IX_METINPAGG_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB(APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METTYP_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB(APP_SID, METER_TYPE_ID);

-- Missed from schema, so installed systems won't have this!
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(*)
	 INTO v_count
	 FROM all_constraints
	WHERE constraint_name = 'FK_EST_CUST_GLOBAL_APP'
	AND owner='CSR';

	IF v_count != 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.est_customer DROP CONSTRAINT FK_EST_CUST_GLOBAL_APP';
	END IF;
END;
/

ALTER TABLE csr.est_options
DROP CONSTRAINT FK_EST_CUSTOMER_OPTIONS;

ALTER TABLE csr.est_customer ADD (
	ORG_NAME	VARCHAR2(256),
	EMAIL		VARCHAR2(256)
);
BEGIN
	security.user_pkg.LogonAdmin;
	MERGE INTO csr.est_customer ec
	USING 
	(
		SELECT pm_customer_id,
			   org_name,
			   email
		  FROM csr.est_customer_global
	) ecg ON (ecg.pm_customer_id = ec.pm_customer_id)
	WHEN MATCHED THEN UPDATE 
	 SET ec.org_name = ecg.org_name, 
		 ec.email = ecg.email;
END;
/
 
ALTER TABLE csr.est_customer MODIFY (
	ORG_NAME NOT NULL
); 
DROP VIEW csr.v$est_customer;
ALTER TABLE CSR.EST_ATTR_FOR_BUILDING ADD (
	LABEL				VARCHAR2(256)
);
ALTER TABLE csr.score_type ADD (
	applies_to_regions				NUMBER(1) DEFAULT 0 NOT NULL,	
	CONSTRAINT ck_score_type_app_to_reg_1_0 CHECK (applies_to_regions in (0, 1))	
);
ALTER TABLE csrimp.score_type ADD (
	applies_to_regions				NUMBER(1)
);
UPDATE csrimp.score_type SET applies_to_regions = 0;
ALTER TABLE csrimp.score_type MODIFY applies_to_regions NOT NULL;
ALTER TABLE csrimp.score_type ADD CONSTRAINT ck_score_type_app_to_reg_1_0 CHECK (applies_to_regions in (0, 1));
ALTER TABLE csr.region_metric_val ADD measure_sid					NUMBER(10);
ALTER TABLE csr.region_metric_val ADD source_type_id 				NUMBER(10);
ALTER TABLE csr.region_metric_val ADD entry_measure_conversion_id	NUMBER(10);
ALTER TABLE csr.region_metric_val ADD entry_val 					NUMBER(24,10);
ALTER TABLE csr.temp_region_metric_val ADD source_type_id			NUMBER(10);

DECLARE
BEGIN
	UPDATE csr.region_metric_val rmv
	SET (rmv.measure_sid, rmv.source_type_id, rmv.entry_measure_conversion_id) =
		(SELECT measure_sid, source_type_id, measure_conversion_id
		   FROM csr.region_metric_region rmr
		  WHERE rmv.app_sid = rmr.app_sid
		    AND rmv.ind_sid = rmr.ind_sid
		    AND rmv.region_sid = rmr.region_sid
		);
	UPDATE csr.region_metric_val
	SET entry_val = val;
		UPDATE csr.region_metric_val rmv
		   SET val = -- csr.measure_pkg.UNSEC_GetBaseValue
				   (SELECT NVL(NVL(mc.a, mcp.a), 1) * POWER(rmv.entry_val, NVL(NVL(mc.b, mcp.b), 1)) + NVL(NVL(mc.c, mcp.c), 0)
					  FROM csr.measure_conversion mc,
					  	   csr.measure_conversion_period mcp
					 WHERE mc.app_sid = mcp.app_sid(+) AND mc.measure_conversion_id = mcp.measure_conversion_id(+)
					   AND rmv.app_sid = mc.app_sid(+) AND rmv.entry_measure_conversion_id = mc.measure_conversion_id(+)
					   AND (rmv.effective_dtm >= mcp.start_dtm or mcp.start_dtm IS NULL)
					   AND (rmv.effective_dtm < mcp.end_dtm or mcp.end_dtm IS NULL))
		 WHERE entry_measure_conversion_id is not null;
END;
/
ALTER TABLE csr.region_metric_val MODIFY (measure_sid NOT NULL, source_type_id NOT NULL);
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_REGION
	FOREIGN KEY (app_sid, region_sid)
	REFERENCES csr.region(app_sid, region_sid)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_REGION_M
	FOREIGN KEY (app_sid, ind_sid, measure_sid)
	REFERENCES csr.region_metric(app_sid, ind_sid, measure_sid)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_MEASURE_C
	FOREIGN KEY (app_sid, measure_sid, entry_measure_conversion_id)
	REFERENCES csr.measure_conversion(app_sid, measure_sid, measure_conversion_id)
;
ALTER TABLE csr.region_metric_val ADD CONSTRAINT FK_REGION_METRIC_VAL_SOURCE_T
	FOREIGN KEY (source_type_id)
	REFERENCES csr.source_type(source_type_id)
;
CREATE INDEX csr.IX_REGION_METRIC_VAL_REGION ON csr.region_metric_val (app_sid, region_sid);
CREATE INDEX csr.IX_REGION_METRIC_VAL_REGION_M ON csr.region_metric_val (app_sid, ind_sid, measure_sid);
CREATE INDEX csr.IX_REGION_METRIC_VAL_MEASURE_C ON csr.region_metric_val (app_sid, measure_sid, entry_measure_conversion_id);
CREATE INDEX csr.IX_REGION_METRIC_VAL_SOURCE_T ON csr.region_metric_val (source_type_id);
CREATE TABLE csr.FB87487_region_metric_region
AS
SELECT * FROM csr.region_metric_region;
DROP TABLE csr.region_metric_region CASCADE CONSTRAINTS;
DROP TABLE csrimp.region_metric_region CASCADE CONSTRAINTS;
DROP INDEX csr.IX_RMETRICR_RMETRIC_VAL;
EXEC security.user_pkg.LogonAdmin;
CREATE TABLE csr.FB87487_region_metric_val AS 
SELECT *
  FROM (
	SELECT app_sid, region_metric_val_id, region_sid, ind_sid, effective_dtm, entered_by_sid, entered_dtm, val, note, 
	       FIRST_VALUE(region_metric_val_id) OVER (
					PARTITION BY app_sid, region_sid, ind_sid, TRUNC(effective_dtm, 'DD') 
					    ORDER BY entered_dtm DESC, region_metric_val_id DESC
			) keep_region_metric_val_id
	  FROM csr.region_metric_val
  ) 
 WHERE region_metric_val_id != keep_region_metric_val_id;
 
ALTER TABLE csr.FB87487_region_metric_val ADD CONSTRAINT pk_FB87487_region_metric_val PRIMARY KEY (app_sid, region_metric_val_id);
CREATE TABLE csr.FB87487_imp_val
AS
SELECT * 
  FROM csr.imp_val
 WHERE set_region_metric_val_id IS NOT NULL
  AND (app_sid, set_region_metric_val_id) IN (
		SELECT app_sid, region_metric_val_id
		  FROM csr.FB87487_region_metric_val
 );
DECLARE
BEGIN
	UPDATE csr.imp_val
	   SET set_region_metric_val_id = NULL
	 WHERE (app_sid, imp_val_id) IN (
		SELECT app_sid, imp_val_id
		  FROM csr.FB87487_imp_val
	);
	DELETE FROM csr.region_metric_val rmv
	 WHERE (app_sid, region_metric_val_id) IN (
		SELECT app_sid, region_metric_val_id
		  FROM csr.FB87487_region_metric_val
	);
	UPDATE csr.region_metric_val
	   SET effective_dtm = TRUNC(effective_dtm, 'DD')
	 WHERE effective_dtm != TRUNC(effective_dtm, 'DD');
END;
/
ALTER TABLE csr.region_metric_val ADD CONSTRAINT CK_REGION_METRIC_VAL_EFF_DTM CHECK (effective_dtm = TRUNC(effective_dtm, 'DD'));
ALTER TABLE csrimp.region_metric_val ADD CONSTRAINT CK_REGION_METRIC_VAL_EFF_DTM CHECK (effective_dtm = TRUNC(effective_dtm, 'DD'));
ALTER TABLE chain.company_header ADD (
	page_company_col_sid	NUMBER (10, 0),
	user_company_col_sid	NUMBER (10, 0)
);
ALTER TABLE csrimp.chain_company_header ADD (
	page_company_col_sid	NUMBER (10, 0),
	user_company_col_sid	NUMBER (10, 0)
);
ALTER TABLE CSR.EST_CONV_MAPPING ADD CONSTRAINT FK_ESTMETCON_ESTCONMAP 
    FOREIGN KEY (METER_TYPE, UOM)
    REFERENCES CSR.EST_METER_CONV(METER_TYPE, UOM)
;
ALTER TABLE CSR.EST_METER_CONV ADD CONSTRAINT FK_ESTMETTYP_ESTMETCNV 
    FOREIGN KEY (METER_TYPE)
    REFERENCES CSR.EST_METER_TYPE(METER_TYPE)
;
ALTER TABLE CSR.EST_METER_TYPE_MAPPING ADD CONSTRAINT FK_ESTMETTYP_ESTMETTYPMAP 
    FOREIGN KEY (METER_TYPE)
    REFERENCES CSR.EST_METER_TYPE(METER_TYPE)
;
ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP ADD CONSTRAINT FK_ESTPROPTYP_ESTPROPTYPMAP 
    FOREIGN KEY (EST_PROPERTY_TYPE)
    REFERENCES CSR.EST_PROPERTY_TYPE(EST_PROPERTY_TYPE)
;
ALTER TABLE CSR.EST_SPACE_TYPE_ATTR ADD CONSTRAINT FK_ESTSPCTYP_ESTSPCTYPATTR 
    FOREIGN KEY (EST_SPACE_TYPE)
    REFERENCES CSR.EST_SPACE_TYPE(EST_SPACE_TYPE)
;
ALTER TABLE CSR.EST_SPACE_TYPE_MAP ADD CONSTRAINT FK_ESTSPCTYP_ESTSPCTYPMAP 
    FOREIGN KEY (EST_SPACE_TYPE)
    REFERENCES CSR.EST_SPACE_TYPE(EST_SPACE_TYPE)
;
BEGIN
	-- Remove non mapped 
	DELETE FROM csr.est_building_metric_mapping
	 WHERE ind_sid IS NULL;
	DELETE FROM csr.est_space_attr_mapping
	 WHERE ind_sid IS NULL;
	-- Remove any conv mappings with null measure_sid
	DELETE FROM csr.est_conv_mapping
	 WHERE measure_sid IS NULL;
	-- Remove any conversion mappings where the meter type is not mapped
	DELETE FROM csr.est_conv_mapping c
	 WHERE NOT EXISTS (
	 	SELECT 1
	 	  FROM csr.est_meter_type_mapping t
	 	 WHERE t.app_sid = c.app_sid
	 	   AND t.est_account_sid = c.est_account_sid
	 	   AND t.meter_type = c.meter_type
	 	   AND meter_type_id IS NOT NULL
	 );
	-- Remove any meter mappings with null meter_type_id
	DELETE FROM csr.est_meter_type_mapping
	 WHERE meter_type_id IS NULL;
END;
/
ALTER TABLE CSR.EST_METER_TYPE_MAPPING MODIFY (
	METER_TYPE_ID              NUMBER(10, 0)    NOT NULL
);
ALTER TABLE CSR.EST_CONV_MAPPING MODIFY (
	MEASURE_SID              NUMBER(10, 0)    NOT NULL
);
ALTER TABLE CSR.EST_BUILDING_METRIC_MAPPING MODIFY(
	IND_SID					NUMBER(10, 0)	NOT NULL
);
ALTER TABLE CSR.EST_SPACE_ATTR_MAPPING MODIFY(
	IND_SID					NUMBER(10, 0)	NOT NULL
);
ALTER TABLE CSR.EST_CONV_MAPPING ADD CONSTRAINT FK_MEASURE_ESTCONVMAP 
    FOREIGN KEY (APP_SID, MEASURE_SID)
    REFERENCES CSR.MEASURE(APP_SID, MEASURE_SID)
;
CREATE INDEX CSR.IX_ESTMETCON_ESTCONMAP ON CSR.EST_CONV_MAPPING(METER_TYPE, UOM);
CREATE INDEX CSR.IX_ESTMETTYP_ESTMETCNV ON CSR.EST_METER_CONV(METER_TYPE);
CREATE INDEX CSR.IX_ESTMETTYP_ESTMETTYPMAP ON CSR.EST_METER_TYPE_MAPPING(METER_TYPE);
CREATE INDEX CSR.IX_ESTPROPTYP_ESTPROPTYPMAP ON CSR.EST_PROPERTY_TYPE_MAP(EST_PROPERTY_TYPE);
CREATE INDEX CSR.ESTSPCTYP_ESTSPCTYPATTR ON CSR.EST_SPACE_TYPE_ATTR(EST_SPACE_TYPE);
CREATE INDEX CSR.IX_ESTSPCTYP_ESTSPCTYPMAP ON CSR.EST_SPACE_TYPE_MAP(EST_SPACE_TYPE);
CREATE INDEX CSR.IX_MEASURE_ESTCONVMAP ON CSR.EST_CONV_MAPPING (APP_SID, MEASURE_SID);
ALTER TABLE CSR.PROPERTY_TYPE
ADD (GRESB_PROP_TYPE_CODE VARCHAR2(255));
ALTER TABLE CSR.PROPERTY_TYPE
ADD CONSTRAINT FK_PROP_TYPE_GRESB_PROP_TYPE FOREIGN KEY (GRESB_PROP_TYPE_CODE)
REFERENCES CSR.GRESB_PROPERTY_TYPE(CODE);
ALTER TABLE csr.fund ADD (
	region_sid NUMBER(10, 0) NULL,
	CONSTRAINT fk_fund_region 
		FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid));
ALTER TABLE csr.property_options ADD (enable_multi_fund_ownership NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.property_options MODIFY (enable_multi_fund_ownership DEFAULT 1);
ALTER TABLE csr.property_options ADD (
	gresb_service_config			VARCHAR2(255),
	CONSTRAINT fk_prop_optns_gresb_srvc_cfg FOREIGN KEY (gresb_service_config)
		REFERENCES csr.gresb_service_config (name)
);
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(column_name)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'PROPERTY_TYPE'
	   AND column_name = 'LOOKUP_KEY';
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.PROPERTY_TYPE ADD LOOKUP_KEY VARCHAR2(255)';
	END IF;
END;
/
ALTER TABLE CSRIMP.PROPERTY_TYPE
ADD GRESB_PROP_TYPE_CODE VARCHAR2(255);
ALTER TABLE csr.region_tree ADD (is_fund NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.all_property RENAME COLUMN fund_id TO obsolete_fund_id;
ALTER TABLE csrimp.property_options ADD (
	enable_multi_fund_ownership		NUMBER(1, 0) DEFAULT 1 NOT NULL,
	properties_geo_map_sid			NUMBER(10) NULL,
	gresb_service_config			VARCHAR2(255) NULL
);
ALTER TABLE csrimp.fund ADD (region_sid NUMBER(10, 0) NULL);
ALTER TABLE csrimp.region_tree ADD (is_fund NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.property DROP (fund_id);
create index csr.ix_property_fund_container_sid on csr.property_fund (app_sid, container_sid);
create index csr.ix_property_opti_gresb_service on csr.property_options (gresb_service_config);
create index csr.ix_property_type_gresb_prop_ty on csr.property_type (gresb_prop_type_code);
create index csr.ix_gresb_indicat_type_id on csr.gresb_indicator (gresb_indicator_type_id);
create index csr.ix_gresb_indicat_std_measure_c on csr.gresb_indicator (std_measure_conversion_id);
create index csr.ix_gresb_indicat_indicat_id on csr.gresb_indicator_mapping (gresb_indicator_id);
create index csr.ix_gresb_indicat_measure_conve on csr.gresb_indicator_mapping (app_sid, measure_conversion_id);
create index csr.ix_gresb_indicat_ind_sid on csr.gresb_indicator_mapping (app_sid, ind_sid);
create index csr.ix_fund_region_sid on csr.fund (app_sid, region_sid);


GRANT EXECUTE ON csr.energy_star_account_pkg TO security;
grant select on csr.region_score_log_id_seq to csrimp;
grant insert on csr.region_score to csrimp;
grant insert on csr.region_score_log to csrimp;
grant select,insert,update,delete on csrimp.region_score to web_user;
grant select,insert,update,delete on csrimp.region_score_log to web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_indicator_mapping TO web_user;
GRANT SELECT, INSERT, UPDATE ON csr.gresb_indicator_mapping TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.gresb_submission_log to csrimp;
GRANT SELECT ON csr.gresb_submission_seq to csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_indicator_mapping to web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_submission_log to web_user;
grant select, insert, update on csr.property_fund to csrimp;
grant select, insert, update, delete on csrimp.property_fund to web_user;


ALTER TABLE chain.company_header ADD CONSTRAINT fk_company_hdr_page_comp_col 
	FOREIGN KEY (app_sid, page_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid)
;
ALTER TABLE chain.company_header ADD CONSTRAINT fk_company_hdr_user_comp_col
	FOREIGN KEY (app_sid, user_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid)
;


CREATE OR REPLACE TYPE CSR.T_ENERGY_STAR_ATTR_MAP_ROW AS 
  OBJECT (
  	ATTR_NAME				VARCHAR2(256),
  	IND_SID					NUMBER(10),
	UOM						VARCHAR2(256),
	MEASURE_CONVERSION_ID	NUMBER(10),
	IS_SPACE				NUMBER(1)
  );
/
CREATE OR REPLACE TYPE CSR.T_ENERGY_STAR_ATTR_MAP_TABLE AS 
  TABLE OF CSR.T_ENERGY_STAR_ATTR_MAP_ROW;
/
DROP VIEW csr.v$region_metric_region;
DROP VIEW csr.v$region_metric_val_converted;

CREATE OR REPLACE VIEW CSR.V$AUDIT_CAPABILITY AS
	SELECT ia.app_sid, ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM internal_audit ia
	  JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN security.act act ON act.sid_id = fsrc.group_sid AND act.act_id = SYS_CONTEXT('SECURITY', 'ACT')
	  LEFT JOIN (
		SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
		  FROM flow_item_involvement fii
		  JOIN flow_state_involvement fsi 
	        ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
		 WHERE fii.user_sid = SYS_CONTEXT('SECURITY','SID')
		) finv 
		ON finv.flow_item_id = fi.flow_item_id 
	   AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id 
	   AND finv.flow_state_id = fi.current_state_id
	 WHERE ia.deleted = 0
	   AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2)	   -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
	    OR finv.flow_involvement_type_id IS NOT NULL
		OR rrm.role_sid IS NOT NULL
		OR act.sid_id IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, ia.internal_audit_type_id, fsrc.flow_capability_id;

CREATE OR REPLACE VIEW csr.v$imp_val_mapped AS
	SELECT iv.imp_val_id, iv.imp_session_Sid, iv.file_sid, ii.maps_to_ind_sid, iv.start_dtm, iv.end_dtm,
		   ii.description ind_description,
		   i.description maps_to_ind_description,
		   ir.description region_description,
		   i.aggregate,
		   iv.val,
		   NVL(NVL(mc.a, mcp.a),1) factor_a,
		   NVL(NVL(mc.b, mcp.b),1) factor_b,
		   NVL(NVL(mc.c, mcp.c),0) factor_c,
		   m.description measure_description,
		   im.maps_to_measure_conversion_id,
		   mc.description from_measure_description,
		   NVL(i.format_mask, m.format_mask) format_mask,
		   ir.maps_to_region_sid,
		   iv.rowid rid,
		   ii.app_Sid, iv.note,
		   CASE WHEN m.custom_field LIKE '|%' THEN 1 ELSE 0 END is_text_ind,
		   icv.imp_conflict_id,
		   m.measure_sid,
		   iv.imp_ind_id, iv.imp_region_id,
		   CASE WHEN rm.ind_Sid IS NOT NULL THEN 1 ELSE 0 END is_region_metric
	  FROM imp_val iv
		   JOIN imp_ind ii
		   		 ON iv.imp_ind_id = ii.imp_ind_id
		   		AND iv.app_sid = ii.app_sid
		   		AND ii.maps_to_ind_sid IS NOT NULL
		   JOIN imp_region ir
		  		 ON iv.imp_region_id = ir.imp_region_id
		   		AND iv.app_sid = ir.app_sid
		   		AND ir.maps_to_region_sid IS NOT NULL
	  LEFT JOIN imp_measure im
	      		 ON iv.imp_ind_id = im.imp_ind_id
	      		AND iv.imp_measure_id = im.imp_measure_id
	      		AND iv.app_sid = im.app_sid
	  LEFT JOIN measure_conversion mc
				 ON im.maps_to_measure_conversion_id = mc.measure_conversion_id
				AND im.app_sid = mc.app_sid
      LEFT JOIN measure_conversion_period mcp
				 ON mc.measure_conversion_id = mcp.measure_conversion_id
				AND (iv.start_dtm >= mcp.start_dtm or mcp.start_dtm is null)
				AND (iv.start_dtm < mcp.end_dtm or mcp.end_dtm is null)
	  LEFT JOIN imp_conflict_val icv
				 ON iv.imp_val_id = icv.imp_val_id
				AND iv.app_sid = icv.app_sid
		   JOIN v$ind i
				 ON ii.maps_to_ind_sid = i.ind_sid
				AND ii.app_sid = i.app_sid
				AND i.ind_type = 0
	  LEFT JOIN region_metric rm
				 ON i.ind_sid = rm.ind_sid AND i.app_sid = rm.app_sid
			   JOIN measure m
				 ON i.measure_sid = m.measure_sid
				AND i.app_sid = m.app_sid;
CREATE OR REPLACE VIEW csr.v$imp_merge AS
	SELECT *
	  FROM v$imp_val_mapped
	 WHERE imp_conflict_id IS NULL;
ALTER TABLE csrimp.region_metric_val ADD measure_sid					NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD source_type_id 				NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD entry_measure_conversion_id	NUMBER(10);
ALTER TABLE csrimp.region_metric_val ADD entry_val 						NUMBER(24,10);
UPDATE csrimp.region_metric_val rmv
   SET measure_sid = (SELECT measure_sid FROM csrimp.ind WHERE ind_sid = rmv.ind_sid),
	   source_type_id = 14;
ALTER TABLE csrimp.region_metric_val MODIFY (measure_sid NOT NULL, source_type_id NOT NULL);
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, 
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score, sr.survey_version,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL 
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;
CREATE OR REPLACE VIEW CSR.V$EST_METER_TYPE_MAPPING AS
	SELECT a.app_sid, a.est_account_sid, t.meter_type, m.meter_type_id
	  FROM csr.est_meter_type t
	  CROSS JOIN csr.est_account a
	  LEFT JOIN csr.est_meter_type_mapping m 
			 ON a.app_sid = m.app_sid 
			AND a.est_account_sid = m.est_account_sid
			AND t.meter_type = m.meter_type
;
CREATE OR REPLACE VIEW CSR.V$EST_CONV_MAPPING AS
	SELECT a.app_sid, a.est_account_sid, c.meter_type, c.uom, m.measure_sid, m.measure_conversion_id
	  FROM csr.est_meter_conv c
	  CROSS JOIN csr.est_account a
	  LEFT JOIN csr.est_conv_mapping m 
			 ON a.app_sid = m.app_sid 
			AND a.est_account_sid = m.est_account_sid
			AND c.meter_type = m.meter_type
			AND c.uom = m.uom
;
CREATE OR REPLACE VIEW CSR.PROPERTY
	(APP_SID, REGION_SID, FLOW_ITEM_ID,
	 STREET_ADDR_1, STREET_ADDR_2, CITY, STATE, POSTCODE,
	 COMPANY_SID, PROPERTY_TYPE_ID, PROPERTY_SUB_TYPE_ID,
	 MGMT_COMPANY_ID, MGMT_COMPANY_OTHER,
	 PM_BUILDING_ID, CURRENT_LEASE_ID, MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH) AS
  SELECT ALP.APP_SID, ALP.REGION_SID, ALP.FLOW_ITEM_ID,
	 ALP.STREET_ADDR_1, ALP.STREET_ADDR_2, ALP.CITY, ALP.STATE, ALP.POSTCODE,
	 ALP.COMPANY_SID, ALP.PROPERTY_TYPE_ID, ALP.PROPERTY_SUB_TYPE_ID,
	 ALP.MGMT_COMPANY_ID, ALP.MGMT_COMPANY_OTHER,
	 ALP.PM_BUILDING_ID, ALP.CURRENT_LEASE_ID, ALP.MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH
    FROM ALL_PROPERTY ALP JOIN region r ON r.region_sid = alp.region_sid
   WHERE r.region_type = 3;
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, pf.fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		LEFT JOIN (
			-- In the case of multiple fund ownership, the "default" fund is the fund with the highest 
			-- ownership. Where multiple funds have the same ownership, the default is the fund that was 
			-- created first. Fund ID is retained for compatability with pre-multi ownership code.
			SELECT 
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid 
								   ORDER BY ownership DESC, fund_id ASC) priority 
			FROM csr.property_fund 
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;


CREATE TABLE CSR.TRANS_ATTR_TYPE(
    TYPE_NAME     VARCHAR2(256)    NOT NULL,
    BASIC_TYPE    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_TRANS_EST_ATTR_TYPE PRIMARY KEY (TYPE_NAME)
);
CREATE TABLE CSR.TRANS_ATTR_UNIT(
    TYPE_NAME    VARCHAR2(256)    NOT NULL,
    UOM          VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_TRANS_EST_ATTR_UNIT PRIMARY KEY (TYPE_NAME, UOM)
);
CREATE TABLE CSR.TRANS_ATTR_ENUM(
    TYPE_NAME    VARCHAR2(256)    NOT NULL,
    ENUM         VARCHAR2(256)    NOT NULL,
    POS          NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CONSTRAINT PK_TRANS_EST_ATTR_ENUM PRIMARY KEY (TYPE_NAME, ENUM)
);
CREATE TABLE CSR.TRANS_ATTR_FOR_SPACE(
    ATTR_NAME    VARCHAR2(256)     NOT NULL,
    TYPE_NAME    VARCHAR2(256)     NOT NULL,
    NOTES        VARCHAR2(4000),
    CONSTRAINT PK_TRANS_EST_ATTR_FOR_SPACE PRIMARY KEY (ATTR_NAME)
);
CREATE TABLE CSR.TRANS_SPACE_TYPE_ATTR(
    EST_SPACE_TYPE    VARCHAR2(256)    NOT NULL,
    ATTR_NAME         VARCHAR2(256)    NOT NULL,
    IS_MANDATORY      NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_MANDATORY IN(0,1)),
    CONSTRAINT PK_TRANS_EST_SPACE_TYPE_ATTR PRIMARY KEY (EST_SPACE_TYPE, ATTR_NAME)
);
CREATE TABLE CSR.TRANS_ATTR_FOR_BUILDING(
    ATTR_NAME       VARCHAR2(256)    NOT NULL,
    TYPE_NAME       VARCHAR2(256)    NOT NULL,
    LABEL			VARCHAR2(256),
    IS_MANDATORY    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (IS_MANDATORY IN(0,1)),
    CONSTRAINT PK_TRANS_EST_ATTR_FOR_BUILDING PRIMARY KEY (ATTR_NAME)
);


BEGIN
	INSERT INTO CSR.STD_MEASURE (STD_MEASURE_ID, NAME, DESCRIPTION, SCALE, FORMAT_MASK, REGIONAL_AGGREGATION, CUSTOM_FIELD, PCT_OWNERSHIP_APPLIES, M, KG, S, A, K, MOL, CD) VALUES (38, 'kg.s^-1', 'kg.s^-1', 0, '#,##0', 'sum', NULL, 0, 0, 1, -1, 0, 0, 0, 0);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28176, 38, 'tonne/minute', 0.05999999988, 1, 0, 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28177, 38, 'ton/minute', 0.06613867850965, 1, 0, 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
UPDATE csr.flow_state
   SET lookup_key = null
 WHERE is_deleted = 1;
	DELETE FROM chain.filter_value fv
	 WHERE EXISTS (
		SELECT app_sid, filter_value_id 
		  FROM (
				SELECT app_sid, filter_value_id, 
					ROW_NUMBER() OVER 
					(PARTITION BY app_sid, filter_field_id, num_value, str_value, start_dtm_value, end_dtm_value, region_sid, user_sid, min_num_val, 
						max_num_val, compound_filter_id_value, saved_filter_sid_value, period_set_id, period_interval_id, start_period_id, filter_type, null_filter 
					ORDER BY app_sid, filter_value_id) rn
				  FROM chain.filter_value
			)
		 WHERE rn > 1 AND app_sid = fv.app_sid AND filter_value_id = fv.filter_value_id);
/*
 *	Classes and permissions originally added in latest2686. However, basedata was not updated. Re-add in case they have been missed on newer DBs.
*/
DECLARE
	v_new_class_id 			security.security_pkg.T_SID_ID;
	v_act 					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	-- create csr app classes (inherits from aspenapp)
	-- CMSContainer.
	BEGIN
		security.class_pkg.CreateClass(
			in_act_id			=>  v_act,
			in_parent_class_id	=>  security.Security_Pkg.SO_CONTAINER,
			in_class_name		=>  'CmsContainer',
			in_helper_pkg		=>  NULL,
			in_helper_prog_id	=>  NULL,
			out_class_id		=>  v_new_class_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT class_id
			  INTO v_new_class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'CmsContainer'
			   AND parent_class_id = security.Security_Pkg.SO_CONTAINER
			   AND helper_pkg IS NULL
			   AND helper_prog_id IS NULL;
	END;
	-- Add permissions conditionally as they might have been missed.
	BEGIN
		INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 65536, 'Export');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 131072, 'Bulk export');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	-- CMSTable.
	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'CMSTable', 'cms.tab_pkg', null, v_new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			SELECT class_id
			  INTO v_new_class_id
			  FROM security.securable_object_class
			 WHERE class_name = 'CMSTable'
			   AND parent_class_id IS NULL
			   AND helper_pkg = 'cms.tab_pkg'
			   AND helper_prog_id IS NULL;
	END;
	-- Add permissions conditionally as they might have been missed.
	BEGIN
		INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 65536, 'Export');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO security.permission_name (class_id, permission, permission_name) values (v_new_class_id, 131072, 'Bulk export');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'CMSFilter', 'cms.filter_pkg', null, v_new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
	security.user_pkg.LogOff(v_act);
END;
/
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (66, 'Energy Star', 'EnableEnergyStar', 'Enables Energy Star property integration.');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
DELETE FROM csr.est_customer_global WHERE pm_customer_id IN (
	SELECT pm_customer_id FROM csr.est_customer);
BEGIN
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('amountOfLaundryProcessedAnnuallyType','DECIMAL');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('useDecimalType','DECIMAL');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('grossFloorAreaType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('useYesNoType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('coolingEquipmentRedundancyType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('optionalFloorAreaType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('hoursPerDayGuestsOnsiteType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('useIntegerType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('itEnergyConfigurationType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('onsiteLaundryType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('monthsInUseType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('numberOfWeekdaysType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('ownedByType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('percentCooledType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('percentHeatedType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('percentOfficeCooledType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('percentOfficeHeatedType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('poolType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('poolSizeType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('residentPopulationType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('useStringType','STRING');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('upsSystemRedundancyType','ENUM');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('numberOfBuildingsType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('occupancyPercentageType','INT');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType','DECIMAL');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('PlantDesignFlowRateType','DECIMAL');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('PlantDesignFlowRateType','Cubic Meters per Day');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('PlantDesignFlowRateType','Million Gallons per Day');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('amountOfLaundryProcessedAnnuallyType','Kilogram');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('amountOfLaundryProcessedAnnuallyType','pounds');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('amountOfLaundryProcessedAnnuallyType','short tons');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('coolingEquipmentRedundancyType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('grossFloorAreaType','Square Feet');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('grossFloorAreaType','Square Meters');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('hoursPerDayGuestsOnsiteType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('itEnergyConfigurationType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType','Feet');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType','Meters');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('monthsInUseType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('numberOfBuildingsType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('numberOfWeekdaysType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('occupancyPercentageType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('onsiteLaundryType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('optionalFloorAreaType','Square Feet');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('optionalFloorAreaType','Square Meters');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('ownedByType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('percentCooledType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('percentHeatedType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('percentOfficeCooledType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('percentOfficeHeatedType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('poolSizeType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('poolType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('residentPopulationType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('upsSystemRedundancyType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('useDecimalType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('useIntegerType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('useStringType','<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('useYesNoType','<null>');
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('useYesNoType','Yes',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('useYesNoType','No',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','N',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','N+1',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','N+2',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','2N',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','Greater than 2N',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('coolingEquipmentRedundancyType','None of the Above',5);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('hoursPerDayGuestsOnsiteType','Less Than 15',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('hoursPerDayGuestsOnsiteType','15 To 19',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('hoursPerDayGuestsOnsiteType','More Than 20',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('itEnergyConfigurationType','UPS Supports Only IT Equipment',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('itEnergyConfigurationType','UPS Include Non IT Load Less Than 10%',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('itEnergyConfigurationType','UPS Include Non-IT Load Greater Than 10% Load Submetered',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('itEnergyConfigurationType','UPS Include Non IT Load Greater Than 10% Load Not Submetered',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('itEnergyConfigurationType','Facility Has No UPS',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('onsiteLaundryType','Linens only',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('onsiteLaundryType','Terry only',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('onsiteLaundryType','Both linens and terry',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('onsiteLaundryType','No laundry facility',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('ownedByType','For Profit',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('ownedByType','Non Profit',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('ownedByType','Governmental',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','0',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','10',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','20',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','30',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','40',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','50',5);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','60',6);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','70',7);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','80',8);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','90',9);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentCooledType','100',10);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','0',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','10',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','20',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','30',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','40',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','50',5);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','60',6);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','70',7);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','80',8);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','90',9);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentHeatedType','100',10);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeCooledType','50% or more',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeCooledType','Less than 50%',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeCooledType','Not Air Conditioned',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeHeatedType','50% or more',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeHeatedType','Less than 50%',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('percentOfficeHeatedType','Not Heated',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('poolType','Indoor',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('poolType','Outdoor',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('poolSizeType','Recreational',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('poolSizeType','Short Course',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('poolSizeType','Olympic',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','No specific resident population',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','Dedicated Student',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','Dedicated Military',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','Dedicated Senior/Independent Living',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','Dedicated Special Accessibility Needs',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('residentPopulationType','Other dedicated housing',5);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','N',0);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','N+1',1);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','N+2',2);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','2N',3);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','Greater than 2N',4);
	INSERT INTO csr.trans_attr_enum (type_name, enum, pos) VALUES ('upsSystemRedundancyType','None of the Above',5);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('amountOfLaundryProcessedAnnually','amountOfLaundryProcessedAnnuallyType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('averageEffluentBiologicalOxygenDemand','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('averageInfluentBiologicalOxygenDemand','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('averageNumberOfResidents','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('completelyEnclosedFootage','grossFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('cookingFacilities','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('coolingEquipmentRedundancy','coolingEquipmentRedundancyType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('exteriorEntranceToThePublic','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('fixedFilmTrickleFiltrationProcess','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('fullServiceSpaFloorArea','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('areaOfAllWalkInRefrigerationUnits','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('lengthOfAllOpenClosedRefrigerationUnits','lengthOfAllOpenClosedRefrigerationUnitsType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('enclosedFloorArea','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('governmentSubsidizedHousing','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('gymCenterFloorArea','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('hasComputerLab','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('hasDiningHall','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('hasLaboratory','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('hoursPerDayGuestsOnsite','hoursPerDayGuestsOnsiteType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('isHighSchool','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('isTertiaryCare','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('iceEvents','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfConcertShowEventsPerYear','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfSpecialOtherEventsPerYear','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfSportingEventsPerYear','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfSurgicalOperatingBeds','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('sizeOfElectronicScoreBoards','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('surgeryCenterFloorArea','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('itEnergyMeterConfiguration','itEnergyConfigurationType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('laundryFacility','onsiteLaundryType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('maximumNumberOfFloors','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('maximumResidentCapacity','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('licensedBedCapacity','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('monthsInUse','monthsInUseType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfBedrooms','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfCashRegisters','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfCommercialRefrigerationUnits','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfCommercialWashingMachines','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfComputers','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialLivingUnitsLowRiseSetting','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfFTEWorkers','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfGuestMealsServedPerYear','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfLaundryHookupsInAllUnits','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfLaundryHookupsInCommonArea','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfMriMachines','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfOpenClosedRefrigerationUnits','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfPeople','useIntegerType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialLiftSystems','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialLivingUnits','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialWashingMachines','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfRooms','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfHotelRooms','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfStaffedBeds','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfWalkInRefrigerationUnits','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfWeekdaysOpen','numberOfWeekdaysType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfWorkers','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('gymnasiumFloorArea','optionalFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('studentSeatingCapacity','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('nutrientRemoval','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('onSiteLaundryFacility','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('openFootage','grossFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('openOnWeekends','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('ownedBy','ownedByType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('partiallyEnclosedFootage','grossFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('percentCooled','percentCooledType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('percentHeated','percentHeatedType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialLivingUnitsMidRiseSetting','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('percentOfGrossFloorAreaThatIsCommonSpaceOnly','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('percentOfficeCooled','percentOfficeCooledType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('percentOfficeHeated','percentOfficeHeatedType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('plantDesignFlowRate','PlantDesignFlowRateType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('poolLocation','poolType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('poolSize','poolSizeType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('numberOfResidentialLivingUnitsHighRiseSetting','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('residentPopulation','residentPopulationType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('schoolDistrict','useStringType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('seatingCapacity','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('singleStore','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('totalGrossFloorArea','grossFloorAreaType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('upsSystemRedundancy','upsSystemRedundancyType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('supplementalHeating','useYesNoType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('weeklyOperatingHours','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('enrollment','useDecimalType',null);
	INSERT INTO csr.trans_attr_for_space (attr_name, type_name, notes) VALUES ('grantDollars','useDecimalType',null);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('mailingCenterPostOffice','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('mailingCenterPostOffice','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('mailingCenterPostOffice','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('library','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('library','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('library','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('library','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherSpecialityHospital','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherSpecialityHospital','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherSpecialityHospital','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherSpecialityHospital','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('conventionCenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('conventionCenter','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('conventionCenter','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('conventionCenter','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('veterinaryOffice','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('veterinaryOffice','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('veterinaryOffice','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('veterinaryOffice','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('urgentCareClinicOtherOutpatient','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('urgentCareClinicOtherOutpatient','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('urgentCareClinicOtherOutpatient','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('urgentCareClinicOtherOutpatient','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('energyPowerStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('energyPowerStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('energyPowerStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('energyPowerStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherServices','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherServices','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherServices','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherServices','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barNightclub','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barNightclub','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barNightclub','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barNightclub','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherUtility','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherUtility','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherUtility','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherUtility','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('zoo','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('zoo','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('zoo','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('zoo','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('automobileDealership','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('automobileDealership','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('automobileDealership','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('automobileDealership','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('museum','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('museum','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('museum','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('museum','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRecreation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRecreation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRecreation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRecreation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRestaurantBar','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRestaurantBar','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRestaurantBar','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherRestaurantBar','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('lifestyleCenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('lifestyleCenter','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('lifestyleCenter','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('lifestyleCenter','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('policeStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('policeStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('policeStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('policeStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('preschoolDaycare','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('preschoolDaycare','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('preschoolDaycare','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('preschoolDaycare','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('raceTrack','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('raceTrack','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('raceTrack','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('raceTrack','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('selfStorageFacility','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('selfStorageFacility','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('selfStorageFacility','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('selfStorageFacility','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fastFoodRestaurant','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fastFoodRestaurant','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fastFoodRestaurant','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fastFoodRestaurant','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('laboratory','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('laboratory','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('laboratory','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('laboratory','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('repairServices','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('repairServices','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('repairServices','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('repairServices','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherTechnologyScience','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherTechnologyScience','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherTechnologyScience','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherTechnologyScience','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fireStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fireStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fireStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fireStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('performingArts','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('performingArts','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('performingArts','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('performingArts','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('outpatientRehabilitationPhysicalTherapy','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('outpatientRehabilitationPhysicalTherapy','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('outpatientRehabilitationPhysicalTherapy','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('outpatientRehabilitationPhysicalTherapy','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stripMall','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stripMall','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stripMall','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stripMall','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('rollerRink','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('rollerRink','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('rollerRink','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('rollerRink','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEducation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEducation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEducation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEducation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fitnessCenterHealthClubGym','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fitnessCenterHealthClubGym','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fitnessCenterHealthClubGym','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('fitnessCenterHealthClubGym','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('aquarium','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('aquarium','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('aquarium','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('aquarium','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodService','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodService','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodService','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodService','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('restaurant','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('restaurant','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('restaurant','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('restaurant','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('enclosedMall','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('enclosedMall','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('enclosedMall','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('enclosedMall','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('iceCurlingRink','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('iceCurlingRink','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('iceCurlingRink','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('iceCurlingRink','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('adultEducation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('adultEducation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('adultEducation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('adultEducation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEntertainmentPublicAssembly','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEntertainmentPublicAssembly','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEntertainmentPublicAssembly','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherEntertainmentPublicAssembly','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('movieTheater','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('movieTheater','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('movieTheater','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('movieTheater','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('transportationTerminalStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('transportationTerminalStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('transportationTerminalStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('transportationTerminalStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('vocationalSchool','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('vocationalSchool','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('vocationalSchool','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('vocationalSchool','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('socialMeetingHall','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('socialMeetingHall','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('socialMeetingHall','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('socialMeetingHall','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherMall','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherMall','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherMall','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherMall','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('other','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('other','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('other','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('other','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('refrigeratedWarehouse','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('refrigeratedWarehouse','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('refrigeratedWarehouse','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','singleStore',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','exteriorEntranceToThePublic',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('retail','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','hasLaboratory',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','onSiteLaundryFacility',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','maximumNumberOfFloors',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','numberOfStaffedBeds',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','numberOfFTEWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','numberOfMriMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','ownedBy',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','isTertiaryCare',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','licensedBedCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hospital','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','numberOfSurgicalOperatingBeds',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','surgeryCenterFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('medicalOffice','numberOfMriMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('dataCenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('dataCenter','coolingEquipmentRedundancy',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('dataCenter','itEnergyMeterConfiguration',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('dataCenter','upsSystemRedundancy',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','percentOfficeCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','percentOfficeHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('courthouse','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('singleFamilyHome','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('singleFamilyHome','numberOfBedrooms',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('singleFamilyHome','numberOfPeople',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('nonRefrigeratedWarehouse','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfResidentialLivingUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfBedrooms',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfResidentialLivingUnitsMidRiseSetting',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfLaundryHookupsInAllUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfLaundryHookupsInCommonArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfResidentialLivingUnitsLowRiseSetting',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','numberOfResidentialLivingUnitsHighRiseSetting',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','residentPopulation',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('multifamilyHousing','governmentSubsidizedHousing',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','percentOfficeCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('office','percentOfficeHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','exteriorEntranceToThePublic',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','singleStore',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wholesaleClubSupercenter','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfResidentialLivingUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','averageNumberOfResidents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','maximumResidentCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfCommercialRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfCommercialWashingMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfResidentialWashingMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','numberOfResidentialLiftSystems',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('seniorCareCommunity','licensedBedCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfResidentialLivingUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','averageNumberOfResidents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','maximumResidentCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfCommercialRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfCommercialWashingMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfResidentialWashingMachines',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','numberOfResidentialLiftSystems',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residentialCareFacility','licensedBedCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('swimmingPool','poolSize',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('swimmingPool','poolLocation',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('swimmingPool','monthsInUse',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','numberOfRooms',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','hasComputerLab',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('residenceHallDormitory','hasDiningHall',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','averageInfluentBiologicalOxygenDemand',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','averageEffluentBiologicalOxygenDemand',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','plantDesignFlowRate',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','fixedFilmTrickleFiltrationProcess',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('wastewaterTreatmentPlant','nutrientRemoval',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('distributionCenter','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','numberOfCommercialRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','seatingCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('worshipFacility','numberOfWeekdaysOpen',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','percentOfficeCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','percentOfficeHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('financialOffice','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('drinkingWaterTreatmentAndDistribution','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('parking','supplementalHeating',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('parking','openFootage',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('parking','completelyEnclosedFootage',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('parking','partiallyEnclosedFootage',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('supermarket','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('foodSales','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithGasStation','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','numberOfOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','numberOfCashRegisters',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','areaOfAllWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('convenienceStoreWithoutGasStation','lengthOfAllOpenClosedRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','hasComputerLab',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','hasDiningHall',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','numberOfRooms',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('barracks','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','fullServiceSpaFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','gymCenterFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','hoursPerDayGuestsOnsite',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','numberOfCommercialRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','numberOfGuestMealsServedPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','numberOfHotelRooms',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','laundryFacility',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','amountOfLaundryProcessedAnnually',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('hotel','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','openOnWeekends',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','cookingFacilities',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','isHighSchool',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','monthsInUse',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','schoolDistrict',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','studentSeatingCapacity',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('k12School','gymnasiumFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','percentOfficeCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','percentOfficeHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bankBranch','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','enrollment',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','grantDollars',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('collegeUniversity','numberOfFTEWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','enclosedFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','numberOfSportingEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','numberOfConcertShowEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','numberOfSpecialOtherEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','sizeOfElectronicScoreBoards',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','iceEvents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('indoorArena','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','enclosedFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','numberOfSportingEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','numberOfConcertShowEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','numberOfSpecialOtherEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','sizeOfElectronicScoreBoards',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','iceEvents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherStadium','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','enclosedFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','numberOfSportingEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','numberOfConcertShowEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','numberOfSpecialOtherEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','sizeOfElectronicScoreBoards',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','iceEvents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumClosed','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','enclosedFloorArea',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','numberOfSportingEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','numberOfConcertShowEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','numberOfSpecialOtherEventsPerYear',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','sizeOfElectronicScoreBoards',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','iceEvents',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','numberOfWalkInRefrigerationUnits',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','percentCooled',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('stadiumOpen','percentHeated',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('prison','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('prison','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('prison','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('prison','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('manufacturingIndustrialPlant','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('manufacturingIndustrialPlant','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('manufacturingIndustrialPlant','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('manufacturingIndustrialPlant','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('ambulatorySurgicalCenter','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('ambulatorySurgicalCenter','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('ambulatorySurgicalCenter','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('ambulatorySurgicalCenter','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bowlingAlley','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bowlingAlley','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bowlingAlley','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('bowlingAlley','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherPublicServices','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherPublicServices','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherPublicServices','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherPublicServices','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherLodgingResidential','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherLodgingResidential','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherLodgingResidential','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('otherLodgingResidential','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('casino','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('casino','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('casino','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('casino','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('personalServices','totalGrossFloorArea',1);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('personalServices','weeklyOperatingHours',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('personalServices','numberOfComputers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('personalServices','numberOfWorkers',0);
	INSERT INTO csr.trans_space_type_attr (est_space_type, attr_name, is_mandatory) VALUES ('mailingCenterPostOffice','totalGrossFloorArea',1);
	-- Simulated building metrics
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('bldgGrossFloorArea','grossFloorAreaType','Building Gross Floor Area',1);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('numberOfBuildings','numberOfBuildingsType','Number of Buildings',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('occupancyPercentage','occupancyPercentageType','Occupancy Percentage',0);
	-- Types for read-only building metrics
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('buildingMetricNumeric', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('GJ', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('GJ/m'||UNISTR('\00B2')||'', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('GJ/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kWh', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kWh/m'||UNISTR('\00B2')||'', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kWh/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('Metric Tons CO2e', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kgCO2e/m'||UNISTR('\00B2')||'', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kgCO2e/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('kgCO2e/GJ', 'NUMERIC');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('buildingMetricString', 'STRING');
	INSERT INTO csr.trans_attr_type (type_name, basic_type) VALUES ('USD', 'NUMERIC');
	-- Units for read-only building metrics
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('buildingMetricNumeric', '<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('GJ', 'GJ');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('GJ/m'||UNISTR('\00B2')||'', 'GJ/m'||UNISTR('\00B2')||'');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('GJ/m'||UNISTR('\00B3')||'PJ', 'GJ/m'||UNISTR('\00B3')||'PJ');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kWh', 'kWh');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kWh/m'||UNISTR('\00B2')||'', 'kWh/m'||UNISTR('\00B2')||'');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kWh/m'||UNISTR('\00B3')||'PJ', 'kWh/m'||UNISTR('\00B3')||'PJ');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('Metric Tons CO2e', 'Metric Tons CO2e');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kgCO2e/m'||UNISTR('\00B2')||'', 'kgCO2e/m'||UNISTR('\00B2')||'');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kgCO2e/m'||UNISTR('\00B3')||'PJ', 'kgCO2e/m'||UNISTR('\00B3')||'PJ');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('kgCO2e/GJ', 'kgCO2e/GJ');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('buildingMetricString', '<null>');
	INSERT INTO csr.trans_attr_unit (type_name, uom) VALUES ('USD', 'USD');
	-- Read-only building metrics
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('score','buildingMetricNumeric','ENERGY STAR Score',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianSiteTotal','GJ','National Median Site Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianSourceTotal','GJ','National Median Source Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianSiteIntensity','GJ/m'||UNISTR('\00B2')||'','National Median Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianSourceIntensity','GJ/m'||UNISTR('\00B2')||'','National Median Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianWaterWasteWaterSiteIntensity','GJ/m'||UNISTR('\00B3')||'PJ','National Median Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianWaterWasteWaterSourceIntensity','GJ/m'||UNISTR('\00B3')||'PJ','National Median Water/Wastewater Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('percentBetterThanSiteIntensityMedian','buildingMetricNumeric','Difference from National Median Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('percentBetterThanSourceIntensityMedian','buildingMetricNumeric','Difference from National Median Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('percentBetterThanWaterWasteWaterSiteIntensityMedian','buildingMetricNumeric','Difference from National Median Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('percentBetterThanWaterWasteWaterSourceIntensityMedian','buildingMetricNumeric','Difference from National Median Water/Wastewater Source  EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteTotal','GJ','Site Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceTotal','GJ','Source Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteIntensity','GJ/m'||UNISTR('\00B2')||'','Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceIntensity','GJ/m'||UNISTR('\00B2')||'','Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSiteIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSourceIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteTotalWN','GJ','Weather Normalized Site Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceTotalWN','GJ','Weather Normalized Source Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteIntensityWN','GJ/m'||UNISTR('\00B2')||'','Weather Normalized Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceIntensityWN','GJ/m'||UNISTR('\00B2')||'','Weather Normalized Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSiteIntensityWN','GJ/m'||UNISTR('\00B3')||'PJ','Weather Normalized Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSourceIntensityWN','GJ/m'||UNISTR('\00B3')||'PJ','Weather Normalized Water/Wastewater Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteElectricityTotalWN','kWh','Weather Normalized Site Electricity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteElectricityIntensityWN','kWh/m'||UNISTR('\00B2')||'','Weather Normalized Site Electricity Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSiteElectricityIntensityWN','kWh/m'||UNISTR('\00B3')||'PJ','Weather Normalized Water/Wastewater Site Electricity Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteNaturalGasUseTotalWN','GJ','Weather Normalized Site Natural Gas Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteNaturalGasUseIntensityWN','GJ/m'||UNISTR('\00B2')||'','Weather Normalized Site Natural Gas Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSiteNaturalGasUseIntensityWN','GJ/m'||UNISTR('\00B3')||'PJ','Weather Normalized Water/Wastewater Site Natural Gas Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteEnergyUseAdjustedToCurrentYear','GJ','Site Energy Use - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceEnergyUseAdjustedToCurrentYear','GJ','Source Energy Use - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('siteIntensityAdjustedToCurrentYear','GJ/m'||UNISTR('\00B2')||'','Site EUI - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('sourceIntensityAdjustedToCurrentYear','GJ/m'||UNISTR('\00B2')||'','Source EUI - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSiteIntensityAdjustedToCurrentYear','GJ/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Site EUI - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterSourceIntensityAdjustedToCurrentYear','GJ/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Source EUI - Adjusted to Current Year',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianScore','buildingMetricNumeric','National Median ENERGY STAR Score',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('totalGHGEmissions','Metric Tons CO2e','Total GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('totalGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Total GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterTotalGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Total GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('directGHGEmissions','Metric Tons CO2e','Direct GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('directGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Direct GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterDirectGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Direct GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('indirectGHGEmissions','Metric Tons CO2e','Indirect GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('indirectGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Indirect GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterIndirectGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Indirect GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('biomassGHGEmissions','Metric Tons CO2e','Biomass GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('biomassGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Biomass GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('waterWasteWaterBiomassGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B3')||'PJ','Water/Wastewater Biomass GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('egridOutputEmissionsRate','kgCO2e/GJ','eGRID Output Emissions Rate',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('regionalPowerGrid','buildingMetricString','eGRID Subregion',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('electricDistributionUtility','buildingMetricString','Electric Distribution Utility',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('powerPlant','buildingMetricString','Power Plant',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('medianTotalGHGEmissions','Metric Tons CO2e','National Median Total GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('energyStarCertificationYears','buildingMetricString','ENERGY STAR Certification - Year(s) Certified',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('energyStarCertificationEligibility','buildingMetricString','ENERGY STAR Certification - Eligibility',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('energyStarCertificationApplicationStatus','buildingMetricString','ENERGY STAR Certification - Application Status',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('energyStarCertificationProfilePublished','buildingMetricString','ENERGY STAR Certification - Profile Published',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetScore','buildingMetricNumeric','Target ENERGY STAR Score',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetPercentBetterThanSourceIntensityMedian','buildingMetricNumeric','Target % Better Than Median Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetSiteTotal','GJ','Target Site Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetSourceTotal','GJ','Target Source Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetSiteIntensity','GJ/m'||UNISTR('\00B2')||'','Target Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetSourceIntensity','GJ/m'||UNISTR('\00B2')||'','Target Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetWaterWasteWaterSiteIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Target Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetWaterWasteWaterSourceIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Target Water/Wastewater Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetEnergyCost','USD','Target Energy Cost',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetTotalGHGEmissions','Metric Tons CO2e','Target Total GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetScore','buildingMetricNumeric','Design Target ENERGY STAR Score',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetBetterThanMedianSourceIntensity','buildingMetricNumeric','Design Target % Better Than Median Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetSiteTotal','GJ','Design Target Site Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetSourceTotal','GJ','Design Target Source Energy Use',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetSiteIntensity','GJ/m'||UNISTR('\00B2')||'','Design Target Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetSourceIntensity','GJ/m'||UNISTR('\00B2')||'','Design Target Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetWaterWasteWaterSiteIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Design Target Water/Wastewater Site EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetWaterWasteWaterSourceIntensity','GJ/m'||UNISTR('\00B3')||'PJ','Design Target Water/Wastewater Source EUI',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetEnergyCost','USD','Design Target Energy Cost',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetTotalGHGEmissions','Metric Tons CO2e','Design Target Total GHG Emissions',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('designTargetTotalGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Design Target Total GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('targetTotalGHGEmissionsIntensity','kgCO2e/m'||UNISTR('\00B2')||'','Target Total GHG Emissions Intensity',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterUPSOutputSiteEnergy','kWh','Data Center - UPS Output Meter',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterPDUInputSiteEnergy','kWh','Data Center - PDU Input Meter',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterPDUOutputSiteEnergy','kWh','Data Center - PDU Output Meter',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterITEquipmentInputSiteEnergy','kWh','Data Center - IT Equipment Input Meter',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterITSiteEnergy','kWh','Data Center - IT Site Energy',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterITSourceEnergy','GJ','Data Center - IT Source Energy',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterSourcePUE','buildingMetricNumeric','Data Center - PUE',0);
	INSERT INTO csr.trans_attr_for_building (attr_name, type_name, label, is_mandatory) VALUES ('dataCenterPUEMedian','buildingMetricNumeric','Data Center - National Median PUE',0);
	FOR r IN (
		SELECT type_name, basic_type
		  FROM csr.trans_attr_type
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_type (type_name, basic_type)
			VALUES (r.type_name, r.basic_type);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_type
				   SET basic_type = r.basic_type
				 WHERE type_name = r.type_name;
		END;
	END LOOP;
	FOR r IN (
		SELECT type_name, uom
		  FROM csr.trans_attr_unit
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_unit (type_name, uom)
			VALUES (r.type_name, r.uom);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	FOR r IN (
		SELECT type_name, enum, pos
		  FROM csr.trans_attr_enum
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_enum (type_name, enum, pos)
			VALUES (r.type_name, r.enum, r.pos);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_enum
				   SET pos = r.pos
				 WHERE type_name = r.type_name
				   AND enum = r.enum;
		END;
	END LOOP;
	FOR r IN (
		SELECT attr_name, type_name
		  FROM csr.trans_attr_for_space
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_for_space (attr_name, type_name)
			VALUES (r.attr_name, r.type_name);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_for_space
				   SET type_name = r.type_name
				 WHERE attr_name = r.attr_name;
		END;
	END LOOP;
	FOR r IN (
		SELECT est_space_type, attr_name, is_mandatory
		  FROM csr.trans_space_type_attr
	) LOOP
		BEGIN
			INSERT INTO csr.est_space_type_attr (est_space_type, attr_name, is_mandatory)
			VALUES (r.est_space_type, r.attr_name, r.is_mandatory);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_space_type_attr
				   SET is_mandatory = r.is_mandatory
				 WHERE est_space_type = r.est_space_type
				   AND attr_name = r.attr_name;
		END;
	END LOOP;
	FOR r IN (
		SELECT attr_name, type_name, label, is_mandatory
		  FROM csr.trans_attr_for_building
	) LOOP
		BEGIN
			INSERT INTO csr.est_attr_for_building (attr_name, type_name, label, is_mandatory)
			VALUES (r.attr_name, r.type_name, r.label, r.is_mandatory);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.est_attr_for_building
				   SET type_name = r.type_name,
				       label = r.label,
				       is_mandatory = r.is_mandatory
				 WHERE attr_name = r.attr_name;
		END;
	END LOOP;
END;
/
DROP TABLE csr.TRANS_ATTR_TYPE;
DROP TABLE csr.TRANS_ATTR_UNIT;
DROP TABLE csr.TRANS_ATTR_ENUM;
DROP TABLE csr.TRANS_ATTR_FOR_SPACE;
DROP TABLE csr.TRANS_SPACE_TYPE_ATTR;
DROP TABLE csr.TRANS_ATTR_FOR_BUILDING;
UPDATE csr.score_type
   SET applies_to_regions = 1
 WHERE (app_sid, score_type_id) IN (
	SELECT qs.app_sid, qs.score_type_id
	  FROM csr.quick_survey qs
	  JOIN csr.qs_campaign qsc ON qs.app_sid = qsc.app_sid AND qs.survey_sid = qsc.survey_sid
	 WHERE qs.score_type_id IS NOT NULL
);
DECLARE 
	v_region_score_id	NUMBER(10);
BEGIN
	security.user_pkg.LogonAdmin;
	-- get the last score for a region that is linked to a campaign survey that has been submitted for each score type
	FOR r IN (		     
		SELECT app_sid, region_sid, score_type_id, score_threshold_id, overall_score, submitted_dtm, submitted_by_user_sid
		  FROM (
			SELECT rsr.app_sid, rsr.region_sid, qs.score_type_id, qss.score_threshold_id, qss.overall_score, qss.submitted_dtm, qss.submitted_by_user_sid,
				   ROW_NUMBER() OVER (PARTITION BY rsr.app_sid, rsr.region_sid, qs.score_type_id ORDER BY qss.submitted_dtm DESC) rn
			  FROM csr.region_survey_response rsr
			  JOIN csr.quick_survey_response sr ON rsr.app_sid = sr.app_sid AND rsr.survey_response_id = sr.survey_response_id AND rsr.survey_sid = sr.survey_sid
			  JOIN csr.quick_survey_submission qss ON sr.app_sid = qss.app_sid
			   AND sr.survey_response_id = qss.survey_response_id
			   AND NVL(sr.last_submission_id, 0) = qss.submission_id
			   AND sr.survey_version > 0 -- filter out draft submissions
			   AND sr.hidden = 0 -- filter out hidden responses
			  JOIN csr.quick_survey qs ON sr.app_sid = qs.app_sid AND sr.survey_sid = qs.survey_sid      
			  JOIN csr.qs_campaign qsc ON qs.app_sid = qsc.app_sid AND qs.survey_sid = qsc.survey_sid
			 WHERE (qss.overall_score IS NOT NULL OR qss.score_threshold_id IS NOT NULL)
			   AND qs.score_type_id IS NOT NULL   
			   AND qss.submitted_dtm IS NOT NULL
		  ) 
		 WHERE rn = 1
	) LOOP
		INSERT INTO csr.region_score_log (app_sid, region_score_log_id, region_sid,	score_type_id, score_threshold_id, score, set_dtm, changed_by_user_sid)
		     VALUES (r.app_sid, csr.region_score_log_id_seq.NEXTVAL, r.region_sid, r.score_type_id, r.score_threshold_id, r.overall_score, r.submitted_dtm, r.submitted_by_user_sid)
		  RETURNING region_score_log_id INTO v_region_score_id;
		  
		BEGIN
			INSERT INTO csr.region_score (app_sid, score_type_id, region_sid, last_region_score_log_id)
				 VALUES (r.app_sid, r.score_type_id, r.region_sid, v_region_score_id);	
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE csr.region_score
				   SET last_region_score_log_id = v_region_score_id
				 WHERE app_sid = r.app_sid
				   AND score_type_id = r.score_type_id
				   AND region_sid = r.region_sid;
		END;
	END LOOP;
END;
/
INSERT INTO csr.property_fund (app_sid, region_sid, fund_id, ownership)
	SELECT app_sid, region_sid, obsolete_fund_id, 1
	  FROM csr.all_property
	 WHERE obsolete_fund_id IS NOT NULL;
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('accepted', 'A boolean field must be set');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('blank', 'Cannot be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('confirmation', 'Value must match {0}’s value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_lt_tot', 'Maximum Coverage must be greater than or equal to Data Coverage');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_value_required', 'All fields (value, max coverage, and total coverage) must be provided if any are provided');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('empty', 'Cannot be blank or an empty collection');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('equal_to', 'Value must be exactly {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('even', 'Must be even');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('exclusion', 'The value is one of the attributes excluded values');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('field_invalid', 'The field name is not valid');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than', 'Must be greater than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than_or_equal_to', 'Must be greater than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('inclusion', 'Must be one of the attributes permitted value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('invalid', 'Is not a valid value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than', 'Must be less than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than_or_equal_to', 'Must be less than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('months_in_year', 'Must be within a year (12 months)');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_a_number', 'Must be a number');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_an_integer', 'Must be an integer');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('odd', 'Must be odd');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('other_than', 'The value is the wrong length. It must not be {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('percentage_lte_100', 'Must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('present', 'Must be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('record_invalid', 'There is some unspecified problem with the record. More details me be present on other attributes');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('restrict_dependent_destroy', 'The record could not be deleted because a {0} depends on it');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('taken', 'The value must be unique and has already been used in this context');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_long', 'The value is too long. It must be at most {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_short', 'The value is too short. It must be at least {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('wrong_length', 'The value is the wrong length. It must be exactly {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_lte_100', 'Total waste disposal must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_alloc', 'Waste management data cannot be provided for both Managed and Indirectly Managed columns');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_negative', 'Must not be negative'); 
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than_zero', 'Must be greater than zero'); 
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, High Street', 'RHS');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, Shopping Center', 'RSM');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, Warehouse', 'RWB');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Office', 'OFF');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Distribution Warehouse', 'DWH');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Business Parks', 'BUS');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Manufacturing', 'MAN');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Multi-family', 'RMF');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Family Houses', 'RFA');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Senior Houses', 'RSE');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Student Houses', 'RST');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Hotel', 'HOT');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Healthcare', 'HEC');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Medical Office', 'MED');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Leisure', 'LEI');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Data Centers', 'DAT');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Self-storage', 'SST');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Parking (indoors)', 'PAR');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Other', 'OTH');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Other 2', 'OT2');
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (1, 'Property', 1);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (2, 'Energy', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (3, 'GHG', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (4, 'Water', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (5, 'Waste', 0);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (103, 1, 'asset_size', 'x > 0', 'The total floor area of an asset in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (104, 1, 'major_renovation', '[Y, N, null]', 'Has the building been involved in any major renovation? This should be a checkbox or list indicator, or alternatively a date or numeric indicator containing the year of the last major renovation.', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (1, 2, 'en_man_bcf_abs', 'x > 0', 'Fuel consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (2, 2, 'en_man_bcf_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (3, 2, 'en_man_bcf_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (4, 2, 'en_man_bcd_abs', 'x > 0', 'District heating and cooling consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (5, 2, 'en_man_bcd_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (6, 2, 'en_man_bcd_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (7, 2, 'en_man_bce_abs', 'x > 0', 'Electricity consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (8, 2, 'en_man_bce_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (9, 2, 'en_man_bce_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (10, 2, 'en_man_bsf_abs', 'x > 0', 'Fuel consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (11, 2, 'en_man_bsf_cov', 'x > 0', 'Data coverage area of the shared services or central plant specified in the field above (en_man_bsf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (12, 2, 'en_man_bsf_tot', 'x > 0', 'Maximum coverage area of shared services or the central plant specified in the field above (en_man_bsf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (13, 2, 'en_man_bsd_abs', 'x > 0', 'District heating and cooling consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (14, 2, 'en_man_bsd_cov', 'x > 0', 'Data coverage area of the shared services or the central plant specified in the field above (en_man_bsd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (15, 2, 'en_man_bsd_tot', 'x > 0', 'Maximum coverage area of the shared services or the central plant specified in the field above (en_man_bsd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (16, 2, 'en_man_bse_abs', 'x > 0', 'Electricity consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (17, 2, 'en_man_bse_cov', 'x > 0', 'Data coverage area of the shared services or the central plant specified in the field above (en_man_bse_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (18, 2, 'en_man_bse_tot', 'x > 0', 'Maximum coverage area of the shared services or the central plant specified in the field above (en_man_bse_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (19, 2, 'en_man_bof_abs', 'x > 0', 'Fuel consumption from outdoor, exterior and parking areas of the asset over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (20, 2, 'en_man_boe_abs', 'x > 0', 'Electricity consumption from outdoor, exterior, and parking areas of the asset over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (21, 2, 'en_man_tlf_abs', 'x > 0', 'Fuel consumption of tenant space purchased by landlords over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (22, 2, 'en_man_tlf_cov', 'x > 0', 'Data coverage area of the tenant space purchased by landlords specified in the field above (en_man_tlf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (23, 2, 'en_man_tlf_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tlf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (24, 2, 'en_man_tld_abs', 'x > 0', 'District heating and cooling consumption of tenant space purchased by a landlord over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (25, 2, 'en_man_tld_cov', 'x > 0', 'Data coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tld_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (26, 2, 'en_man_tld_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tld_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (27, 2, 'en_man_tle_abs', 'x > 0', 'Electricity consumption of tenant space purchased by a landlord over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (28, 2, 'en_man_tle_cov', 'x > 0', 'Data coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tle_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (29, 2, 'en_man_tle_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tle_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (30, 2, 'en_man_ttf_abs', 'x > 0', 'Fuel consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (31, 2, 'en_man_ttf_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (32, 2, 'en_man_ttf_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (33, 2, 'en_man_ttd_abs', 'x > 0', 'District heating and cooling consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (34, 2, 'en_man_ttd_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (35, 2, 'en_man_ttd_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (36, 2, 'en_man_tte_abs', 'x > 0', 'Electricity consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (37, 2, 'en_man_tte_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_tte_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (38, 2, 'en_man_tte_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_tte_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (39, 2, 'en_man_wcf_abs', 'x > 0', 'Fuel consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (40, 2, 'en_man_wcf_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (41, 2, 'en_man_wcf_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (42, 2, 'en_man_wcd_abs', 'x > 0', 'District heating and cooling consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (43, 2, 'en_man_wcd_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (44, 2, 'en_man_wcd_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (45, 2, 'en_man_wce_abs', 'x > 0', 'Electricity consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (46, 2, 'en_man_wce_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (47, 2, 'en_man_wce_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (48, 2, 'en_ind_wwf_abs', 'x > 0', 'Fuel consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (49, 2, 'en_ind_wwf_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (50, 2, 'en_ind_wwf_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (51, 2, 'en_ind_wwd_abs', 'x > 0', 'District heating and cooling consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (52, 2, 'en_ind_wwd_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (53, 2, 'en_ind_wwd_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (54, 2, 'en_ind_wwe_abs', 'x > 0', 'Electricity consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (55, 2, 'en_ind_wwe_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwe_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (56, 2, 'en_ind_wwe_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwe_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (57, 2, 'en_ind_wof_abs', 'x > 0', 'Fuel consumption of outdoor, exterior, and parking areas over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (58, 2, 'en_ind_woe_abs', 'x > 0', 'Electricity consumption of outdoor, exterior, and parking areas over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (59, 3, 'ghg_s1_abs', 'x > 0', 'Scope 1 greenhouse gas emissions over the current year. Scope 1 is defined as all direct GHG emissions of the asset. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (60, 3, 'ghg_s1_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s1_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (61, 3, 'ghg_s1_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s1_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (62, 3, 'ghg_s2_abs', 'x > 0', 'Scope 2 greenhouse gas emissions of the asset over the current year. Scope 2 is defined as indirect GHG emissions as a result of purchased electricity, heat, and steam. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (63, 3, 'ghg_s2_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s2_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (64, 3, 'ghg_s2_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s2_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (65, 3, 'ghg_s3_abs', 'x > 0', 'Scope 3 greenhouse gas emissions over the current year. Scope 3 is defined as all indirect GHG emissions that do not result from the purchase of electricity, heat, or steam. Scope 3 does not apply to all assets. Measured in metric tonnes', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (66, 3, 'ghg_s3_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s3_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (67, 3, 'ghg_s3_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s3_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (68, 3, 'ghg_offset_abs', 'x > 0', 'The greenhouse gas offset purchased for the asset over the current year. Greenhouse gas offset is defined as the purchased reduction in greenhouse gases in order to offset the emissions made at the asset. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (69, 3, 'ghg_net_abs', 'x > 0', 'The net greenhouse gas emissions for the asset after purchasing the greenhouse gas offsets.', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (70, 4, 'wat_man_bc_abs', 'x > 0', 'Water consumption of all common areas within the base building over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (71, 4, 'wat_man_bc_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (wat_man_bc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (72, 4, 'wat_man_bc_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (wat_man_bc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (73, 4, 'wat_man_bs_abs', 'x > 0', 'Water consumption of all shared services/ central plant areas within the base building over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (74, 4, 'wat_man_bs_cov', 'x > 0', 'Data coverage area of the shared services/ central plant areas specified in the field above (wat_man_bs_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (75, 4, 'wat_man_bs_tot', 'x > 0', 'Maximum coverage area of the shared services/ central plant areas specified in the field above (wat_man_bs_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (76, 4, 'wat_man_bo_abs', 'x > 0', 'Water consumption of all exterior or outdoor areas of the asset over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (77, 4, 'wat_man_tl_abs', 'x > 0', 'Water consumption of tenant space purchase by landlords over the current year. Measure in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (78, 4, 'wat_man_tl_cov', 'x > 0', 'Data coverage area of the tenant space purchased by landlords specified in the field above (wat_man_tl_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (79, 4, 'wat_man_tl_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by landlords specified in the field above (wat_man_tl_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (80, 4, 'wat_man_tt_abs', 'x > 0', 'Water consumption of tenant space purchase by tenants over the current year. Measure in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (81, 4, 'wat_man_tt_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (wat_man_tt_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (82, 4, 'wat_man_tt_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (wat_man_tt_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (83, 4, 'wat_man_wc_abs', 'x > 0', 'Water consumption of the rational building (tenant space and common areas combined) over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (84, 4, 'wat_man_wc_cov', 'x > 0', 'Data coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_man_wc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (85, 4, 'wat_man_wc_tot', 'x > 0', 'Maximum coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_man_wc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (86, 4, 'wat_ind_ww_abs', 'x > 0', 'Water consumption of the rational building (tenant space and common areas combined) over the current year. Measured in cubic meters. Applies only to indirectly managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (87, 4, 'wat_ind_ww_cov', 'x > 0', 'Data coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_ind_ww_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (88, 4, 'wat_ind_ww_tot', 'x > 0', 'Maximum coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_ind_ww_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (89, 4, 'wat_ind_wo_abs', 'x > 0', 'Water consumption of outdoor or exterior areas of the asset over the current year. Measured in cubic meters. Applies only to indirectly managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (90, 5, 'was_man_haz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (91, 5, 'was_man_nhaz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of non-hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (92, 5, 'was_man_perc', '0 < x '||UNISTR('\2264')||' 100', 'Percent of the asset covered by the data above (was_man_haz_abs), (was_man_nhaz_abs) . Based on floor area covered / total floor area.', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (93, 5, 'was_ind_haz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to indirectly managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (94, 5, 'was_ind_nhaz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of non-hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to indirectly managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (95, 5, 'was_ind_perc', '0 < x '||UNISTR('\2264')||' 100', 'Percent of the asset covered by the data above (was_man_haz_abs), (was_man_nhaz_abs) . Based on floor area covered / total floor area.', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (96, 5, 'was_i_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via incineration over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (97, 5, 'was_l_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via landfills over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (98, 5, 'was_wd_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted from landfills over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (99, 5, 'was_dwe_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through converting waste to energy over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (100, 5, 'was_dr_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through recycling over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (101, 5, 'was_do_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through other methods over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (102, 5, 'was_oth_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via other methods over the current year. Applies to all assets', '%', NULL);
COMMIT;
INSERT INTO csr.gresb_service_config (name, url, client_id, client_secret)
	 VALUES ('live', 'https://api.gresb.com', '97f9abc25fe4cdbbbf71120d2cea7e05f1c54043e6ff5b38c2fc5ece3cd8d6d0', '965590d32c7f52055c75de27087b8cbce6fe982e30ab02281bebee7e58b90720');
	 
INSERT INTO csr.gresb_service_config (name, url, client_id, client_secret)
	 VALUES ('sandbox', 'https://api-sandbox.gresb.com', '74efe6224867e4237ac20304b42b0989ccf8a18d1c20e08a86e8e8d2b1467d34', '7a5d844f78f4ae0e0eb138b335405957d42791928161f4ce79cdfb971f53619c');
COMMIT;
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
		VALUES (65, 'GRESB', 'EnableGRESB', 'Enable GRESB property integration. Once enabled, the client''s site has to be added to the cr360 GRESB account, '||
		'by adding a new application under account settings, with the callback URL ''https://CLIENT_NAME.credit360.com/csr/site/property/gresb/authorise.acds''. '||
		'NOTE  - if enabling in a test environment, be sure to set the gresb_service_config from ''live'' to ''sandbox'' on the property_options table.', 1);
		




CREATE OR REPLACE PACKAGE csr.gresb_config_pkg AS END;
/
GRANT EXECUTE ON csr.gresb_config_pkg TO web_user;


@..\energy_star_pkg
@..\dataview_pkg
@..\scenario_pkg
@..\energy_star_attr_pkg
@..\schema_pkg
@..\quick_survey_pkg
@..\property_report_pkg
@..\property_pkg
@..\region_metric_pkg
@..\chain\plugin_pkg
@..\audit_pkg
@..\csr_user_pkg
@..\csr_data_pkg
@..\gresb_config_pkg
@..\enable_pkg


@..\scenario_body
@..\scenario_run_body
@..\flow_body
@..\energy_star_body
@..\dataview_body
@..\schema_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\web_publication_body
@..\meter_body
@..\enable_body
@..\property_body
@..\energy_star_attr_body
@..\quick_survey_body
@..\property_report_body
@..\chain\filter_body
@..\csr_app_body
@..\measure_body
@..\region_body
@..\region_metric_body
@..\imp_body
@..\energy_star_helper_body
@..\energy_star_job_data_body
@..\audit_body
@..\plugin_body
@..\chain\plugin_body
@..\csr_user_body
@..\non_compliance_report_body;
@..\energy_star_account_body
@..\gresb_config_body
@..\region_tree_body
@..\supplier_body
@..\stored_calc_datasource_body



@update_tail

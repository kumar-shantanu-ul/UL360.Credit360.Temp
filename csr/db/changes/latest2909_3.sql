-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
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

-- Base data needs inserting before FK constraints are added

-- PROPERTY TYPES
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

-- SPACE TYPES
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

-- METER TYPES
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

-- METER TYPE -> UOM
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

-- Clean up invalid types before adding constraints
-- (they'll not be doing anything anyway if the types don't match Energy Star)
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

-- Alter tables

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

-- Need to clean up mapping data before making columns not null
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


-- FK indexes
CREATE INDEX CSR.IX_ESTMETCON_ESTCONMAP ON CSR.EST_CONV_MAPPING(METER_TYPE, UOM);
CREATE INDEX CSR.IX_ESTMETTYP_ESTMETCNV ON CSR.EST_METER_CONV(METER_TYPE);
CREATE INDEX CSR.IX_ESTMETTYP_ESTMETTYPMAP ON CSR.EST_METER_TYPE_MAPPING(METER_TYPE);
CREATE INDEX CSR.IX_ESTPROPTYP_ESTPROPTYPMAP ON CSR.EST_PROPERTY_TYPE_MAP(EST_PROPERTY_TYPE);
CREATE INDEX CSR.ESTSPCTYP_ESTSPCTYPATTR ON CSR.EST_SPACE_TYPE_ATTR(EST_SPACE_TYPE);
CREATE INDEX CSR.IX_ESTSPCTYP_ESTSPCTYPMAP ON CSR.EST_SPACE_TYPE_MAP(EST_SPACE_TYPE);
CREATE INDEX CSR.IX_MEASURE_ESTCONVMAP ON CSR.EST_CONV_MAPPING (APP_SID, MEASURE_SID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.V$EST_METER_TYPE_MAPPING AS
	SELECT a.app_sid, a.est_account_sid, t.meter_type, m.meter_type_id
	  FROM csr.est_meter_type t
	  CROSS JOIN csr.est_account a
	  LEFT JOIN csr.est_meter_type_mapping m 
			 ON a.app_sid = m.app_sid 
			AND a.est_account_sid = m.est_account_sid
			AND t.meter_type = m.meter_type
;

-- /csr/db/create_views.sql
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

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_body
@../energy_star_attr_body
@../energy_star_account_body

@update_tail

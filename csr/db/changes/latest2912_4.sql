-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EST_ATTR_FOR_BUILDING ADD (
	LABEL				VARCHAR2(256)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- Types
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

-- *** Data changes ***
-- RLS

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

-- Data
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_attr_pkg
@../energy_star_attr_body

@update_tail

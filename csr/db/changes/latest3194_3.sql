-- Please update version.sql too -- this keeps clean builds in sync
define version=3194
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.OSHA_BASE_DATA(
	OSHA_BASE_DATA_ID				NUMBER(10,0)	NOT NULL,
	DATA_ELEMENT					VARCHAR2(50)	NOT NULL,
	DEFINITION_AND_VALIDATIONS		VARCHAR2(2000)	NOT NULL,
	FORMAT							VARCHAR2(10)	NOT NULL,
	LENGTH							NUMBER(3,0)		NOT NULL,
	REQUIRED						NUMBER(1)		NOT NULL,
	CONSTRAINT PK_OSHA_BASE_DATA 	PRIMARY KEY (OSHA_BASE_DATA_ID)
)
;

CREATE TABLE CSR.OSHA_MAPPING(
	APP_SID					NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OSHA_BASE_DATA_ID		NUMBER(10,0)	NOT NULL,
	IND_SID					NUMBER(10,0),
	CMS_COL_SID				NUMBER(10,0),
CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID, IND_SID, CMS_COL_SID),
CONSTRAINT FK_OSHA_BASE_DATA_ID FOREIGN KEY (OSHA_BASE_DATA_ID) REFERENCES CSR.OSHA_BASE_DATA (OSHA_BASE_DATA_ID),
CONSTRAINT FK_IND_SID FOREIGN KEY (IND_SID) REFERENCES CSR.IND (IND_SID)
)
;

CREATE TABLE CSRIMP.OSHA_MAPPING(
	APP_SID					NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OSHA_BASE_DATA_ID		NUMBER(10,0)	NOT NULL,
	IND_SID					NUMBER(10,0),
	CMS_COL_SID				NUMBER(10,0),
CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID, IND_SID, CMS_COL_SID)
)
;
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (1, 'establishment_name', 'The name of the establishment reporting data. The system matches the data in your file to existing establishments based on establishment name. <b><u>Each establishment MUST have a unique name.</u></b>', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (2, 'company_name', 'The name of the company that owns the establishment.', 'Character', 100, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (3, 'street_address', 'The street address of the establishment. <ul><li>Should not contain a PO Box address</li></ul>', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (4, 'city', 'The city where the establishment is located.', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (5, 'state', 'The state where the establishment is located. <ul><li>Enter the two character postal code for the U.S. State or Territory in which the establishment is located.</li></ul>', 'Character', 2, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (6, 'zip', 'The full zip code for the establishment. <ul><li>Must be a five or nine digit number</li></ul>', 'Text', 9, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (7, 'naics_code', 'The North American Industry Classification System (NAICS) code which classifies an establishment’s business. Use a 2012 code, found here:<a href="http://www.census.gov/cgibin/sssd/naics/naicsrch?chart=2012">http://www.census.gov/cgibin/sssd/naics/naicsrch?chart=2012</a><ul><li>Must be a number and be 6 digits in length</li></ul>', 'Integer', 6, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (8, 'industry_description', 'Industry Description <ul><li>You may provide an industry description in addition to your NAICS code.</li></ul>', 'Character', 300, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (9, 'size', 'The size of the establishment based on the maximum number of employees which worked there <b><u>at any point</u></b> in the year you are submitting data for.<ul><li>Enter 1 if the establishment has < 20 employees</li><li>Enter 2 if the establishment has 20-249 employees</li><li>Enter 3 if the establishment has 250+ employees</li></ul>', 'Integer', 1, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (10, 'establishment_type', 'Identify if the establishment is part of a state or local government. <ul><li>Enter 1 if the establishment is not a government entity</li><li>Enter 2 if the establishment is a State Government entity</li><li>Enter 3 if the establishment is a Local Government entity</li></ul>', 'Integer', 1, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (11, 'year_filing_for', 'The calendar year in which the injuries and illnesses being reported occurred at the establishment. <ul><li>Must be a four digit number</li><li>Cannot be earlier than 2016</li></ul>', 'Integer', 4, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (12, 'annual_average_employees', 'Annual Average Number of Employees<ul><li>Must be > 0</li><li>Must be a number</li><li>Should be < 25,000</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (13, 'total_hours_worked', 'Total hours worked by all employees last year <ul><li>Must be > 0</li><li>Must be numeric</li><li>total_hours_worked divided by annual_average_employees  must be < 8760</li><li>total_hours_worked divided by annual_average_employees should be > 500</li></ul>', 'Integer', 10, 1); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (14, 'no_injuries_illnesses', 'Whether the establishment had any OSHA recordable work-related injuries or illnesses during the year.<ul><li>Enter 1 if the establishment had injuries or illnesses</li><li>Enter 2 if the establishment did not have injuries or illnesses</li></ul>', 'Integer', 1, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (15, 'total_deaths', 'Total number of deaths (Form 300A Field G) <ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (16, 'total_dafw_cases', 'Total number of cases with days away from work (Form 300A Field H)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (17, 'total_djtr_cases', 'Total number of cases with job transfer or restriction (Form 300A Field I)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (18, 'total_other_cases', 'Total number of other recordable cases (Form 300A Field J)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (19, 'total_dafw_days', 'Total number of days away from work (Form 300A Field K)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (20, 'total_djtr_days', 'Total number of days of job transfer or restriction (Form 300A Field L)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (21, 'total_injuries', 'Total number of injuries (Form 300A Field M(1))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (22, 'total_skin_disorders', 'Total number of skin disorders (Form 300A Field M(2))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (23, 'total_respiratory_conditions', 'Total number of respiratory conditions (Form 300A Field M(3))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (24, 'total_poisonings', 'Total number of poisonings (Form 300A Field M(4))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (25, 'total_hearing_loss', 'Total number of hearing loss (Form 300A Field M(5))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (26, 'total_other_illnesses', 'Total number of all other illnesses (Form 300A Field M(6))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (27, 'change_reason', 'The reason why an establishment’s injury and illness summary was changed, if applicable', 'Character', 100, 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		VALUES (105, 'OSHA', 'EnableOSHAModule', 'Enables the OSHA module.');
END;
/




-- ** New package grants **
create or replace package csr.osha_pkg as end;
/
grant execute on csr.osha_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***

@../osha_pkg

@../osha_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CHAIN.HIGG_QUESTION_OPT_CONVERSION (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	HIGG_QUESTION_ID				NUMBER(10) NOT NULL,
	HIGG_QUESTION_OPTION_ID			NUMBER(10) NOT NULL,
	MEASURE_CONVERSION_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_HIGG_Q_OPT_CONV PRIMARY KEY (APP_SID, HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID),
	CONSTRAINT FK_HIGG_Q_O_CONV_QO FOREIGN KEY (HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID)
	REFERENCES CHAIN.HIGG_QUESTION_OPTION (HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID)
);

CREATE TABLE CSRIMP.HIGG_QUESTION_OPT_CONVERSION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	HIGG_QUESTION_ID				NUMBER(10) NOT NULL,
	HIGG_QUESTION_OPTION_ID			NUMBER(10) NOT NULL,
	MEASURE_CONVERSION_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_HIGG_Q_OPT_CONV PRIMARY KEY (CSRIMP_SESSION_ID, HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID),
    CONSTRAINT FK_HIGG_Q_OPT_CONV_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CHAIN.HIGG_QUESTION
ADD (
	UNITS_QUESTION_ID 			NUMBER(10) NULL,
	INDICATOR_NAME 				VARCHAR2(255) NULL,
	INDICATOR_LOOKUP 			VARCHAR2(255) NULL,
	MEASURE_NAME 				VARCHAR2(255) NULL,
	MEASURE_LOOKUP 				VARCHAR2(255) NULL,
	MEASURE_DIVISIBILITY		NUMBER(10) NULL,
	STD_MEASURE_CONVERSION_ID	NUMBER(10) NULL
);

ALTER TABLE CHAIN.HIGG_QUESTION_OPTION
ADD (
	MEASURE_CONVERSION 				VARCHAR2(255) NULL,
	STD_MEASURE_CONVERSION_ID 		NUMBER(10) NULL
);

ALTER TABLE CHAIN.HIGG_CONFIG 
ADD (
	AGGREGATE_IND_GROUP_ID NUMBER(10) NULL,
	CONSTRAINT UK_HIGG_CONFIG_SURVEY UNIQUE (APP_SID, SURVEY_SID)
);

ALTER TABLE CHAIN.HIGG_CONFIG
MODIFY COMPANY_TYPE_ID NULL;

ALTER TABLE CSRIMP.HIGG_CONFIG 
ADD (
	AGGREGATE_IND_GROUP_ID NUMBER(10) NULL
);

CREATE INDEX CHAIN.IX_HIGG_CONFIG_COMPANY_TYPE ON CHAIN.HIGG_CONFIG (APP_SID, COMPANY_TYPE_ID);
CREATE INDEX CHAIN.IX_HIGG_CONFIG_AUDIT_TYPE ON CHAIN.HIGG_CONFIG (APP_SID, AUDIT_TYPE_ID);
CREATE INDEX CHAIN.IX_HIGG_CONFIG_CLOSURE_TYPE ON CHAIN.HIGG_CONFIG (APP_SID, AUDIT_TYPE_ID, CLOSURE_TYPE_ID);
CREATE INDEX CHAIN.IX_HIGG_CONFIG_AUDIT_COORD ON CHAIN.HIGG_CONFIG (APP_SID, AUDIT_COORDINATOR_SID);
CREATE INDEX CHAIN.IX_HIGG_CONFIG_AGG_IND ON CHAIN.HIGG_CONFIG (APP_SID, AGGREGATE_IND_GROUP_ID);
CREATE INDEX CHAIN.IX_HIGG_MOD_T_G_TAG_GROUP ON CHAIN.HIGG_MODULE_TAG_GROUP (APP_SID, TAG_GROUP_ID);
CREATE INDEX CHAIN.IX_HIGG_CON_MOD_HIGG_CONFIG ON CHAIN.HIGG_CONFIG_MODULE (APP_SID, HIGG_CONFIG_ID);
CREATE INDEX CHAIN.IX_HIGG_CON_MOD_HIGG_MODULE ON CHAIN.HIGG_CONFIG_MODULE (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_MOD_SEC_HIGG_MODULE ON CHAIN.HIGG_MODULE_SECTION (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_MOD_SUB_SEC_HIGG_MOD ON CHAIN.HIGG_MODULE_SUB_SECTION (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_MOD_SUB_SEC_HIGG_SEC ON CHAIN.HIGG_MODULE_SUB_SECTION (HIGG_SECTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_PARENT ON CHAIN.HIGG_QUESTION (PARENT_QUESTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_MODULE ON CHAIN.HIGG_QUESTION (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_SUB_SEC ON CHAIN.HIGG_QUESTION (HIGG_SUB_SECTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_SUR_QS ON CHAIN.HIGG_QUESTION_SURVEY (APP_SID, SURVEY_SID);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_SUR_QSQ ON CHAIN.HIGG_QUESTION_SURVEY (APP_SID, QS_QUESTION_ID, SURVEY_VERSION);
CREATE INDEX CHAIN.IX_HIGG_QUESTION_SUR_QUESTION ON CHAIN.HIGG_QUESTION_SURVEY (HIGG_QUESTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QU_OPT_QUESTION ON CHAIN.HIGG_QUESTION_OPTION (HIGG_MODULE_ID, HIGG_QUESTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QU_OPT_MODULE ON CHAIN.HIGG_QUESTION_OPTION (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_QU_OPT_SUR_QO ON CHAIN.HIGG_QUESTION_OPTION_SURVEY (HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID);
CREATE INDEX CHAIN.IX_HIGG_QU_OPT_SUR_QSQ ON CHAIN.HIGG_QUESTION_OPTION_SURVEY (APP_SID, SURVEY_SID);
CREATE INDEX CHAIN.IX_HIGG_QU_OPT_SUR_QSQO ON CHAIN.HIGG_QUESTION_OPTION_SURVEY (APP_SID, QS_QUESTION_ID, QS_QUESTION_OPTION_ID, SURVEY_VERSION);
CREATE INDEX CHAIN.IX_HIGG_RESPONSE_MODULE ON CHAIN.HIGG_RESPONSE (HIGG_MODULE_ID);
CREATE INDEX CHAIN.IX_HIGG_RESPONSE_PROFILE ON CHAIN.HIGG_RESPONSE (APP_SID, HIGG_PROFILE_ID, RESPONSE_YEAR);
CREATE INDEX CHAIN.IX_HIGG_SECTION_SCORE_SECTION ON CHAIN.HIGG_SECTION_SCORE (HIGG_SECTION_ID);
CREATE INDEX CHAIN.IX_HIGG_SECTION_SCORE_RES ON CHAIN.HIGG_SECTION_SCORE (APP_SID, HIGG_RESPONSE_ID);
CREATE INDEX CHAIN.IX_HIGG_SUB_SEC_SCORE_SUB_SEC ON CHAIN.HIGG_SUB_SECTION_SCORE (HIGG_SUB_SECTION_ID);
CREATE INDEX CHAIN.IX_HIGG_SUB_SEC_SCORE_SEC ON CHAIN.HIGG_SUB_SECTION_SCORE (APP_SID, HIGG_RESPONSE_ID, HIGG_SECTION_ID);
CREATE INDEX CHAIN.IX_HIGG_Q_RES_RESPONSE ON CHAIN.HIGG_QUESTION_RESPONSE (APP_SID, HIGG_RESPONSE_ID);
CREATE INDEX CHAIN.IX_HIGG_Q_RES_QUESTION ON CHAIN.HIGG_QUESTION_RESPONSE (HIGG_QUESTION_ID);
CREATE INDEX CHAIN.IX_HIGG_Q_RES_OPTION ON CHAIN.HIGG_QUESTION_RESPONSE (HIGG_QUESTION_ID, OPTION_ID);
CREATE INDEX CHAIN.IX_HIGG_CONF_PROF_CONFIG ON CHAIN.HIGG_CONFIG_PROFILE (APP_SID, HIGG_CONFIG_ID);
CREATE INDEX CHAIN.IX_HIGG_CONF_PROF_PROFILE ON CHAIN.HIGG_CONFIG_PROFILE (APP_SID, HIGG_PROFILE_ID, RESPONSE_YEAR);
CREATE INDEX CHAIN.IX_HIGG_CONF_PROF_AUDIT ON CHAIN.HIGG_CONFIG_PROFILE (APP_SID, INTERNAL_AUDIT_SID);
CREATE INDEX CHAIN.IX_HIGG_Q_OPT_CONV_MC ON CHAIN.HIGG_QUESTION_OPT_CONVERSION (APP_SID, MEASURE_CONVERSION_ID);
CREATE INDEX CHAIN.IX_HIGG_Q_OPT_CONV_QO ON CHAIN.HIGG_QUESTION_OPT_CONVERSION (HIGG_QUESTION_ID, HIGG_QUESTION_OPTION_ID);

-- *** Grants ***
GRANT SELECT ON CSR.QUICK_SURVEY_TYPE TO CHAIN;
GRANT REFERENCES, SELECT ON CSR.MEASURE_CONVERSION TO CHAIN;
GRANT UPDATE ON CSR.MEASURE TO CHAIN;
GRANT SELECT, UPDATE, INSERT, DELETE ON CSR.TEMP_RESPONSE_REGION TO CHAIN;
GRANT UPDATE ON CSR.QUICK_SURVEY_QUESTION TO CHAIN;
GRANT SELECT ON CSR.QUICK_SURVEY_VERSION TO CHAIN;
GRANT SELECT, REFERENCES ON CSR.AGGREGATE_IND_GROUP TO CHAIN;

GRANT EXECUTE ON CSR.INDICATOR_PKG TO CHAIN;
GRANT EXECUTE ON CSR.AGGREGATE_IND_PKG TO CHAIN;
GRANT EXECUTE ON CSR.MEASURE_PKG TO CHAIN;
GRANT EXECUTE ON CHAIN.HIGG_PKG TO WEB_USER;

GRANT SELECT, INSERT, UPDATE ON CHAIN.HIGG_QUESTION_OPT_CONVERSION TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.HIGG_QUESTION_OPT_CONVERSION TO TOOL_USER;
GRANT SELECT ON CHAIN.HIGG_QUESTION_OPT_CONVERSION TO CSR;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.HIGG_QUESTION_OPT_CONVERSION ADD CONSTRAINT FK_HIGG_Q_O_CONV_CONVERSION
	FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
	REFERENCES CSR.MEASURE_CONVERSION (APP_SID, MEASURE_CONVERSION_ID);
	
ALTER TABLE CHAIN.HIGG_CONFIG ADD CONSTRAINT FK_HIGG_CONF_AGG_IND_GROUP
	FOREIGN KEY (APP_SID, AGGREGATE_IND_GROUP_ID)
	REFERENCES CSR.AGGREGATE_IND_GROUP (APP_SID, AGGREGATE_IND_GROUP_ID);


-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- Basedata (setting up higg question to indicator/measure details)
BEGIN
	-- Insert new std measures
	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28188, 5, '10 CF', 3.53146667, 1, 0, 1
	);

	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28189, 5, '10 gallon', 26.4172052, 1, 0, 1
	);

	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28190, 5, '10 m^3', 0.1, 1, 0, 1
	);

	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28191, 5, 'acre-foot', 0.000810714, 1, 0, 1
	);

	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28192, 5, 'DIGL', 21.9969157, 1, 0, 1
	);
	
	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28193, 5, 'hgal', 2.64172052, 1, 0, 1
	);

	INSERT INTO csr.std_measure_conversion (
		std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
	) VALUES (
		28194, 5, 'kilolitres', 1, 1, 0, 1
	);

	UPDATE chain.higg_question
	   SET indicator_name = 'Annual production (units)',
		indicator_lookup = 'PROD_UNITS',
		measure_name = 'Units',
		measure_lookup = 'UNITS',
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1136;

	UPDATE chain.higg_question
	   SET units_question_id = 1139,
		indicator_name = 'Annual production (weight)',
		indicator_lookup = 'PROD_WEIGHT',
		measure_name = 'lbs',
		measure_lookup = 'LBS',
		std_measure_conversion_id = 22,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1138;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'oz (avoirdupois)',
		std_measure_conversion_id = 77
	 WHERE higg_question_id = 1139
	   AND higg_question_option_id = 2492;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tons (short)',
		std_measure_conversion_id = 40
	 WHERE higg_question_id = 1139
	   AND higg_question_option_id = 2494;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tonnes (metric)',
		std_measure_conversion_id = 39
	 WHERE higg_question_id = 1139
	   AND higg_question_option_id = 2495;
	
	UPDATE chain.higg_question
	   SET units_question_id = 1225,
		indicator_name = 'Annual electricity use',
		indicator_lookup = 'ANNUAL_ELECTRICITY',
		measure_name = 'kwh',
		measure_lookup = 'KWH',
		std_measure_conversion_id = 8,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1224;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kwh',
		std_measure_conversion_id = 8
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2850;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Btu (UK)',
		std_measure_conversion_id = 31
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2847;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'GJ',
		std_measure_conversion_id = 30
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2848;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'gwh',
		std_measure_conversion_id = 15797
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2849;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'MJ',
		std_measure_conversion_id = 5717
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2851;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'MMBtu (UK)',
		std_measure_conversion_id = 32
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2852;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'MWh',
		std_measure_conversion_id = 29
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2853;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Therm (UK)',
		std_measure_conversion_id = 11
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2854;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'TJ',
		std_measure_conversion_id = 50
	 WHERE higg_question_id = 1225
	   AND higg_question_option_id = 2852;
	
	UPDATE chain.higg_question
	   SET units_question_id = 1446,
		indicator_name = 'Annual water use',
		indicator_lookup = 'ANNUAL_WATER',
		measure_name = 'm^3',
		measure_lookup = 'METRES_CUBED',
		std_measure_conversion_id = 9,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1445;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'm^3',
		std_measure_conversion_id = 9
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3322;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10 CF',
		std_measure_conversion_id = 28188
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3308;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10 gallon',
		std_measure_conversion_id = 28189
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3309;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10m^3',
		std_measure_conversion_id = 28190
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3310;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'acre-foot',
		std_measure_conversion_id = 28191
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3311;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Ccf',
		std_measure_conversion_id = 26
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3312;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'cf',
		std_measure_conversion_id = 25
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3313;

	UPDATE chain.higg_question_option
	   SET measure_conversion = 'DIGL',
		std_measure_conversion_id = 28192
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3314;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'gallons',
		std_measure_conversion_id = 24
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3315;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'hcf',
		std_measure_conversion_id = 26
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3316;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'hgal',
		std_measure_conversion_id = 28193
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3317;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'IGL',
		std_measure_conversion_id = 23
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3318;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kgal',
		std_measure_conversion_id = 26158
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3319;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kilolitres',
		std_measure_conversion_id = 28194
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3320;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'litres',
		std_measure_conversion_id = 10
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3321;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Mcf',
		std_measure_conversion_id = 61
	 WHERE higg_question_id = 1446
	   AND higg_question_option_id = 3323;

	UPDATE chain.higg_question
	   SET units_question_id = 1542,
		indicator_name = 'Daily wastewater volume',
		indicator_lookup = 'DAILY_WASTEWATER',
		measure_name = 'm^3',
		measure_lookup = 'METRES_CUBED',
		std_measure_conversion_id = 9,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1541;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'm^3',
		std_measure_conversion_id = 9
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3400;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10 CF',
		std_measure_conversion_id = 28188
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3387;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10 gallon',
		std_measure_conversion_id = 28189
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3388;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = '10m^3',
		std_measure_conversion_id = 28190
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3389;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'acre-foot',
		std_measure_conversion_id = 28191
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3390;
	
	-- eh? are these both cubic feet?
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Ccf',
		std_measure_conversion_id = 26
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3391;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'cf',
		std_measure_conversion_id = 25
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3392;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'DIGL',
		std_measure_conversion_id = 28192
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3393;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'gallons',
		std_measure_conversion_id = 24
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3394;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'hcf',
		std_measure_conversion_id = 26
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3395;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'hgal',
		std_measure_conversion_id = 28193
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3396;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'IGL',
		std_measure_conversion_id = 23
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3397;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kgal',
		std_measure_conversion_id = 26158
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3398;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kilolitres',
		std_measure_conversion_id = 28194
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3399;
	
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'Mcf',
		std_measure_conversion_id = 61
	 WHERE higg_question_id = 1542
	   AND higg_question_option_id = 3401;
	

	UPDATE chain.higg_question
	   SET units_question_id = 1727,
		indicator_name = 'Annual amount of solid waste',
		indicator_lookup = 'ANNUAL_SOLID_WASTE',
		measure_name = 'lbs',
		measure_lookup = 'LBS',
		std_measure_conversion_id = 22,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1726;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'lbs',
		std_measure_conversion_id = 22
	 WHERE higg_question_id = 1727
	   AND higg_question_option_id = 3754;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kg',
		std_measure_conversion_id = 3
	 WHERE higg_question_id = 1727
	   AND higg_question_option_id = 3753;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tonnes (metric)',
		std_measure_conversion_id = 39
	 WHERE higg_question_id = 1727
	   AND higg_question_option_id = 3755;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tons (short)',
		std_measure_conversion_id = 40
	 WHERE higg_question_id = 1727
	   AND higg_question_option_id = 3756;

	UPDATE chain.higg_question
	   SET units_question_id = 1730,
		indicator_name = 'Annual amount of hazardous waste',
		indicator_lookup = 'ANNUAL_HAZARDOUS_WASTE',
		measure_name = 'lbs',
		measure_lookup = 'LBS',
		std_measure_conversion_id = 22,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1729;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'lbs',
		std_measure_conversion_id = 22
	 WHERE higg_question_id = 1730
	   AND higg_question_option_id = 3759;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kg',
		std_measure_conversion_id = 3
	 WHERE higg_question_id = 1730
	   AND higg_question_option_id = 3758;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tonnes (metric)',
		std_measure_conversion_id = 39
	 WHERE higg_question_id = 1730
	   AND higg_question_option_id = 3760;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tons (short)',
		std_measure_conversion_id = 40
	 WHERE higg_question_id = 1730
	   AND higg_question_option_id = 3761;

	UPDATE chain.higg_question
	   SET units_question_id = 1733,
		indicator_name = 'Annual amount of waste that is recycled',
		indicator_lookup = 'ANNUAL_RECYCLED_WASTE',
		measure_name = 'lbs',
		measure_lookup = 'LBS',
		std_measure_conversion_id = 22,
		measure_divisibility = 2 /* csr.csr_data_pkg.DIVISIBILITY_LAST_PERIOD */
	 WHERE higg_question_id = 1732;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'lbs',
		std_measure_conversion_id = 22
	 WHERE higg_question_id = 1733
	   AND higg_question_option_id = 3764;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'kg',
		std_measure_conversion_id = 3
	 WHERE higg_question_id = 1733
	   AND higg_question_option_id = 3763;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tonnes (metric)',
		std_measure_conversion_id = 39
	 WHERE higg_question_id = 1733
	   AND higg_question_option_id = 3765;
	 
	UPDATE chain.higg_question_option
	   SET measure_conversion = 'tons (short)',
		std_measure_conversion_id = 40
	 WHERE higg_question_id = 1733
	   AND higg_question_option_id = 3766;
	
	-- Fix typo from SAC
	UPDATE chain.higg_question_option 
	   SET option_value = 'cf' 
	 WHERE higg_question_option_id = 3313
	   AND higg_question_id = 1446
	   AND higg_module_id = 6;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\higg_pkg
@..\chain\higg_setup_pkg
@..\quick_survey_pkg
@..\schema_pkg

@..\chain\chain_body
@..\chain\higg_body
@..\chain\higg_setup_body
@..\csrimp\imp_body
@..\quick_survey_body
@..\enable_body
@..\schema_body

@update_tail

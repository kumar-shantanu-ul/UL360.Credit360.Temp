-- Please update version.sql too -- this keeps clean builds in sync
define version=2921
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415288;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415289;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415290;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415291;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415292;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415293;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415294;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415295;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415296;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415297;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415298;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415299;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415300;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415301;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415302;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415303;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415304;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415305;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415306;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415307;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415308;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415309;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415310;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415311;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415312;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415313;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415314;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415315;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415316;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415317;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415318;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415319;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415320;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415321;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415322;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415323;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415324;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415325;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415326;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415327;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415328;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415329;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415330;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415331;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415332;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415333;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415334;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415335;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415336;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415337;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415338;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415339;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415340;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415341;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415342;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415343;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415344;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415345;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415346;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415347;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415348;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415349;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415350;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415351;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415352;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415353;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415354;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415355;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415356;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415357;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415358;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415359;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415360;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415361;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415362;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415363;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415364;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415365;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415366;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415367;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415368;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415369;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415370;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415371;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415372;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415373;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415374;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415375;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415376;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415377;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415378;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415379;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415380;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415381;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415382;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184415383;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415384;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415385;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415386;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415387;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415388;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415389;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415390;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415391;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415392;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415393;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415394;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415395;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415396;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415397;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415398;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184415399;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184415400;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184415401;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415402;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415403;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415404;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415405;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415406;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415407;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415408;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415409;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415410;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415411;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415412;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415413;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415414;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415415;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415416;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415417;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415418;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415419;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415420;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415421;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415422;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415423;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415424;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415425;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415426;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415427;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415428;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415429;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415430;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415431;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415432;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415433;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415434;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415435;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415436;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415437;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415438;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415439;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415440;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415441;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415442;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415443;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415444;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415445;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415446;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415447;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415448;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415449;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415450;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415451;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415452;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415453;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415454;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415455;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415456;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415457;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415458;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415459;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415460;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415461;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415462;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415463;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415464;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415465;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415466;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415467;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415468;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415469;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415470;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415471;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415472;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415473;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415474;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415475;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415476;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415477;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415478;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415479;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415480;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415481;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415482;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415483;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415484;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415485;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415486;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415487;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415488;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415489;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415490;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415491;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415492;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415493;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415494;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415495;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415496;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415497;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415498;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415499;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415500;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415501;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415502;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415503;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415504;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415505;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415506;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415507;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415508;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415509;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415510;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415511;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415512;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415513;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415514;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415515;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415516;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415517;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415518;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415519;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415520;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415521;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415522;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415523;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415524;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415525;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415526;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415527;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415528;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415529;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415530;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415531;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415532;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415533;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415534;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415535;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415536;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415537;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415538;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415539;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415540;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415541;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415542;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415543;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415544;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415545;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415546;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415547;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415548;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415549;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415550;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415551;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415552;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415553;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415554;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415555;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415556;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415557;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415558;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415559;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415560;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415561;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415562;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415563;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415564;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415565;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415566;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415567;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415568;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415569;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415570;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415571;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415572;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415573;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415574;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415575;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415576;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415577;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415578;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415579;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415580;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415581;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415582;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415583;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415584;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415585;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415586;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415587;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415588;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415589;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415590;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415591;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415592;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415593;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415594;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415595;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415596;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415597;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415598;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415599;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415600;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415601;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415602;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415603;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415604;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415605;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415606;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415607;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415608;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415609;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415610;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415611;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415612;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415613;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415614;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415615;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415616;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415617;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415618;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415619;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415620;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415621;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415622;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415623;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415624;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415625;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415626;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415627;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415628;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415629;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415630;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415631;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415632;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415633;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415634;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415635;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415636;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415637;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415638;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415639;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415640;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415641;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415642;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415643;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415644;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415645;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415646;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415647;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415648;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415649;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415650;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415651;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415652;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415653;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415654;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415655;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415656;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415657;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415658;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415659;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415660;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415661;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415662;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415663;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415664;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415665;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415666;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415667;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415668;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415669;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415670;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415671;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415672;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415673;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415674;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415675;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415676;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415677;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415678;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415679;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415680;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415681;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415682;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415683;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415684;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415685;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415686;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415687;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415688;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415689;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415690;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415691;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415692;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415693;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415694;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415695;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415696;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415697;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415698;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415699;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415700;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415701;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415702;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415703;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415704;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415705;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415706;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415707;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415708;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415709;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415710;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415711;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415712;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415713;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415714;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415715;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415716;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415717;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415718;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415719;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415720;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415721;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415722;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415723;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415724;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415725;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415726;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415727;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415728;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415729;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415730;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415731;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415732;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415733;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415734;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415735;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415736;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415737;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415738;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415739;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415740;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415741;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415742;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415743;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415744;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415745;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415746;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415747;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415748;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415749;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415750;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415751;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415752;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415753;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415754;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415755;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415756;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415757;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415758;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415759;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415760;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415761;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415762;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415763;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415764;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415765;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415766;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415767;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415768;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415769;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415770;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415771;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415772;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415773;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415774;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415775;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415776;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415777;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415778;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415779;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415780;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415781;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415782;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415783;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415784;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415785;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415786;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415787;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415788;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415789;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415790;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415791;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415792;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415793;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415794;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415795;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415796;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415797;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415798;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415799;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415800;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415801;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415802;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415803;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415804;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415805;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415806;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415807;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415808;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415809;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415810;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415811;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415812;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415813;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415814;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415815;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415816;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415817;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415818;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415819;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415820;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415821;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415822;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415823;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415824;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415825;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415826;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415827;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415828;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415829;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415830;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415831;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415832;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415833;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415834;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415835;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415836;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415837;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415838;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415839;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415840;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415841;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415842;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415843;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415844;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415845;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415846;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415847;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415848;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415849;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415850;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415851;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415852;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415853;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415854;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415855;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415856;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415857;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415858;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415859;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415860;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415861;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415862;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415863;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415864;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415865;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415866;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415867;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415868;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415869;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415870;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415871;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415872;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415873;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415874;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415875;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415876;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415877;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415878;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415879;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415880;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415881;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415882;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415883;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415884;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415885;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415886;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415887;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415888;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415889;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415890;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415891;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415892;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415893;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415894;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415895;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415896;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415897;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415898;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415899;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415900;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415901;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415902;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415903;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415904;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415905;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415906;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415907;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415908;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415909;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415910;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415911;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415912;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415913;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415914;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415915;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415916;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415917;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415918;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415919;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415920;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415921;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415922;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415923;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415924;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415925;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415926;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415927;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415928;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415929;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415930;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415931;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415932;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415933;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415934;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415935;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415936;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415937;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415938;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415939;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415940;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415941;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415942;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415943;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415944;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415945;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415946;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415947;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415948;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415949;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415950;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415951;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415952;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415953;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415954;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415955;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415956;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415957;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415958;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415959;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415960;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415961;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415962;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415963;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415964;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415965;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415966;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415967;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415968;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415969;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415970;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415971;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415972;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415973;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415974;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415975;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415976;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415977;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415978;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415979;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415980;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415981;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415982;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415983;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415984;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415985;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415986;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415987;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415988;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415989;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415990;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415991;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415992;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415993;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415994;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415995;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184415996;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415997;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415998;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184415999;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416000;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416001;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416002;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416003;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416004;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416005;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416006;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416007;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416008;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416009;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416010;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416011;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416012;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416013;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416014;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416015;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416016;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416017;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416018;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416019;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416020;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416021;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416022;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416023;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416024;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416025;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416026;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416027;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416028;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416029;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416030;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416031;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416032;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416033;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416034;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416035;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416036;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416037;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416038;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416039;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416040;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416041;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416042;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416043;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416044;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416045;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416046;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416047;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416048;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416049;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416050;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416051;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416052;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416053;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416054;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416055;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416056;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416057;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416058;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416059;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416060;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416061;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416062;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416063;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416064;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416065;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416066;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416067;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416068;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416069;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416070;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416071;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416072;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416073;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416074;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416075;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416076;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416077;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416078;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416079;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416080;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416081;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416082;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416083;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416084;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416085;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416086;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416087;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416088;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416089;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416090;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416091;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416092;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416093;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416094;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416095;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416096;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416097;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416098;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416099;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416100;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416101;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416102;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416103;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416104;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416105;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416106;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416107;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416108;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416109;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416110;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416111;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416112;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416113;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416114;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416115;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416116;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416117;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416118;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416119;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416120;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416121;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416122;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416123;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416124;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416125;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416126;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416127;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416128;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416129;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416130;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416131;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416132;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416133;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416134;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416135;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416136;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416137;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416138;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416139;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416140;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416141;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416142;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416143;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416144;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416145;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416146;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416147;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416148;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416149;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416150;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416151;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416152;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416153;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416154;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416155;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416156;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416157;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416158;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416159;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416160;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416161;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416162;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416163;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416164;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416165;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416166;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416167;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416168;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416169;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416170;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416171;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416172;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416173;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416174;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416175;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416176;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416177;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416178;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416179;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416180;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416181;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416182;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416183;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416184;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416185;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416186;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416187;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416188;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416189;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416190;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416191;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416192;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416193;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416194;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416195;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416196;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416197;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416198;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416199;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416200;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416201;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416202;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416203;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416204;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416205;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416206;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416207;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416208;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416209;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416210;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416211;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416212;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416213;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416214;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416215;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416216;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416217;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416218;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416219;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416220;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416221;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416222;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416223;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416224;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416225;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416226;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416227;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416228;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416229;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416230;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416231;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416232;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416233;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416234;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416235;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416236;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416237;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416238;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416239;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416240;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416241;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416242;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416243;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416244;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416245;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416246;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416247;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416248;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416249;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416250;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416251;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416252;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416253;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416254;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416255;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416256;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416257;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416258;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416259;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416260;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416261;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416262;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416263;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416264;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416265;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416266;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416267;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416268;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416269;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416270;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416271;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416272;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416273;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416274;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416275;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416276;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416277;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416278;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416279;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416280;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416281;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416282;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416283;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416284;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416285;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416286;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416287;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416288;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416289;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416290;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416291;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416292;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416293;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416294;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416295;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416296;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416297;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416298;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416299;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416300;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416301;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416302;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416303;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416304;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416305;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416306;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416307;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416308;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416309;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416310;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416311;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416312;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416313;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416314;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416315;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416316;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416317;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416318;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416319;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416320;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416321;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416322;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416323;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416324;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416325;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416326;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416327;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416328;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 7'
	 WHERE std_factor_id=184416329;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416330;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416331;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416332;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416333;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416334;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416335;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416336;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416337;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416338;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416339;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416340;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416341;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416342;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416343;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416344;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416345;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416346;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416347;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416348;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416349;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416350;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416351;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416352;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416353;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416354;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416355;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416356;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416357;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416358;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416359;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416360;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416361;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416362;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416363;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416364;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416365;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416366;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416367;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416368;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416369;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416370;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416371;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416372;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416373;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416374;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416375;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416376;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416377;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416378;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416379;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416380;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416381;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416382;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416383;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416384;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416385;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416386;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416387;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416388;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416389;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416390;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416391;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416392;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416393;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416394;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416395;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416396;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416397;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416398;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416399;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416400;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416401;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416402;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416403;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416404;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416405;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416406;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416407;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416408;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416409;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416410;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416411;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416412;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416413;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416414;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416415;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416416;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416417;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416418;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416419;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416420;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416421;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416422;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416423;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416424;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416425;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416426;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416427;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416428;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416429;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416430;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416431;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416432;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416433;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416434;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416435;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416436;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416437;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416438;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416439;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416440;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416441;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416442;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416443;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416444;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416445;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416446;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416447;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416448;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416449;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416450;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416451;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416452;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416453;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416454;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416455;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416456;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416457;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416458;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416459;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416460;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416461;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416462;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416463;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416464;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416465;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416466;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416467;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416468;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416469;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416470;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416471;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416472;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416473;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416474;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416475;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416476;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416477;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416478;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416479;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416480;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416481;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416482;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416483;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416484;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416485;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416486;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416487;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416488;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416489;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416490;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416491;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416492;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416493;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416494;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416495;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416496;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416497;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416498;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416499;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416500;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416501;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416502;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416503;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416504;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416505;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416506;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416507;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416508;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416509;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416510;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416511;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416512;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416513;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416514;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416515;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416516;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416517;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416518;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416519;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416520;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416521;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416522;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416523;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416524;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416525;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416526;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416527;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416528;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416529;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416530;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416531;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416532;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416533;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416534;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416535;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416536;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416537;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416538;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416539;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416540;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416541;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416542;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416543;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416544;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416545;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416546;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416547;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416548;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416549;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416550;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416551;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416552;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416553;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416554;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416555;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416556;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416557;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416558;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416559;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416560;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416561;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416562;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416563;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416564;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416565;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416566;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416567;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416568;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416569;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416570;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416571;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416572;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416573;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416574;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416575;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416576;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416577;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416578;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416579;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416580;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416581;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416582;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10b'
	 WHERE std_factor_id=184416583;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416584;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416585;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416586;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416587;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416588;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416589;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416590;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416591;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416592;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416593;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416594;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416595;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416596;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416597;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416598;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 10a'
	 WHERE std_factor_id=184416599;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416600;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416601;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416602;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416603;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416604;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416605;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416606;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 9'
	 WHERE std_factor_id=184416607;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416608;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416609;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416610;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416611;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416612;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416613;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416614;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 8'
	 WHERE std_factor_id=184416615;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416616;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416617;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416618;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416619;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416620;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416621;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416622;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416623;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416624;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416625;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416626;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416627;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416628;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416629;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416630;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416631;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416632;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416633;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416634;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416635;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416636;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416637;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416638;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416639;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416640;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416641;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416642;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416643;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416644;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416645;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416646;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416647;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416648;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416649;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416650;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416651;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416652;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416653;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416654;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416655;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416656;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416657;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416658;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416659;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416660;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416661;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416662;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416663;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416664;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416665;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416666;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416667;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416668;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416669;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416670;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 2'
	 WHERE std_factor_id=184416671;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416672;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416673;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416674;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416675;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416676;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416677;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416678;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416679;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416680;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416681;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416682;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416683;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416684;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416685;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416686;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416687;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416688;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416689;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416690;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416691;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416692;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416693;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416694;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416695;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416696;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416697;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416698;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416699;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416700;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416701;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416702;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416703;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416704;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416705;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416706;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416707;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416708;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416709;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf'
	 WHERE std_factor_id=184416710;

	UPDATE csr.std_factor 
	   SET note='https://www.epa.gov/sites/production/files/2015-12/documents/emission-factors_nov_2015.pdf, TABLE 1'
	 WHERE std_factor_id=184416711;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416712;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416713;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416714;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416715;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416716;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416717;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416718;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 9'
	 WHERE std_factor_id=184416719;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416720;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416721;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416722;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416723;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416724;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416725;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416726;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416727;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416728;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416729;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416730;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416731;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416732;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416733;

	UPDATE csr.std_factor 
	   SET note='Calculated with AR4 GWP as specified in http://www.epa.gov/climateleadership/documents/emission-factors.pdf'
	 WHERE std_factor_id=184416734;

	UPDATE csr.std_factor 
	   SET note='http://www.epa.gov/climateleadership/documents/emission-factors.pdf, TABLE 1'
	 WHERE std_factor_id=184416735;

	COMMIT;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

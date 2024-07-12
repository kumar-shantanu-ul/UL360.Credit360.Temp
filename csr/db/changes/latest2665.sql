--Please update version.sql too -- this keeps clean builds in sync
define version=2665
@update_header

WHENEVER SQLERROR EXIT FAILURE ROLLBACK 
WHENEVER OSERROR EXIT FAILURE ROLLBACK

SET DEFINE OFF;

BEGIN
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385902,48,8068,2,NULL,NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385903,48,15639,1,NULL,NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385904,48,8068,2,'us',NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385905,48,15639,1,'us',NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385906,48,8068,2,'gb',NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385907,48,15639,1,'gb',NULL,NULL,54,DATE '1990-01-01',NULL,5.56,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385908,48,15596,1,'us',NULL,NULL,1461,DATE '1990-01-01',NULL,0.054,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385909,48,15596,2,'us',NULL,NULL,1461,DATE '1990-01-01',NULL,0.054,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385910,48,15596,1,'gb',NULL,NULL,1461,DATE '1990-01-01',NULL,0.05728,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385911,48,15596,2,'gb',NULL,NULL,1461,DATE '1990-01-01',NULL,0.05728,'http://www.ghgprotocol.org/files/ghgp/Emission-Factors-from-Cross-Sector-Tools-%28April%202014%29_0.xlsx');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385912,49,7348,3,'gb',NULL,NULL,17,DATE '1990-01-01',DATE '2013-01-01',0.00027, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385913,49,7348,1,'gb',NULL,NULL,17,DATE '1990-01-01',DATE '2013-01-01',0.18483, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385914,49,7348,2,'gb',NULL,NULL,17,DATE '1990-01-01',DATE '2013-01-01',0.18521, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385915,49,7348,4,'gb',NULL,NULL,17,DATE '1990-01-01',DATE '2013-01-01',0.00011, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385916,49,7348,3,'gb',NULL,NULL,17,DATE '2013-01-01',DATE '2014-01-01',0.00027, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385917,49,7348,1,'gb',NULL,NULL,17,DATE '2013-01-01',DATE '2014-01-01',0.18366, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385918,49,7348,2,'gb',NULL,NULL,17,DATE '2013-01-01',DATE '2014-01-01',0.18404, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385919,49,7348,4,'gb',NULL,NULL,17,DATE '2013-01-01',DATE '2014-01-01',0.00011, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385920,49,7348,3,'gb',NULL,NULL,17,DATE '2014-01-01',NULL,0.000303976,'Standard natural gas received through the gas mains grid network in the UK.');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385921,49,7348,1,'gb',NULL,NULL,17,DATE '2014-01-01',NULL,0.1845574,'Standard natural gas received through the gas mains grid network in the UK.');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385922,49,7348,2,'gb',NULL,NULL,17,DATE '2014-01-01',NULL,0.184973,'Standard natural gas received through the gas mains grid network in the UK.');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385923,49,7348,4,'gb',NULL,NULL,17,DATE '2014-01-01',NULL,0.0001116,'Standard natural gas received through the gas mains grid network in the UK.');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385924,49,8106,3,'gb',NULL,NULL,33,DATE '1990-01-01',DATE '2013-01-01',0.003, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385925,49,8106,1,'gb',NULL,NULL,33,DATE '1990-01-01',DATE '2013-01-01',2.7595, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385926,49,8106,2,'gb',NULL,NULL,33,DATE '1990-01-01',DATE '2013-01-01',3.0213, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385927,49,8106,4,'gb',NULL,NULL,33,DATE '1990-01-01',DATE '2013-01-01',0.2587, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385928,49,8106,3,'gb',NULL,NULL,33,DATE '2013-01-01',DATE '2014-01-01',0.0026, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385929,49,8106,1,'gb',NULL,NULL,33,DATE '2013-01-01',DATE '2014-01-01',2.7312, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385930,49,8106,2,'gb',NULL,NULL,33,DATE '2013-01-01',DATE '2014-01-01',2.9343, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385931,49,8106,4,'gb',NULL,NULL,33,DATE '2013-01-01',DATE '2014-01-01',0.2005, EMPTY_CLOB());
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385932,49,8106,3,'gb',NULL,NULL,33,DATE '2014-01-01',NULL,0.00252951,'Medium oil used in diesel engines, and heating systems (aka red diesel)');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385933,49,8106,1,'gb',NULL,NULL,33,DATE '2014-01-01',NULL,2.726496,'Medium oil used in diesel engines, and heating systems (aka red diesel)');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385934,49,8106,2,'gb',NULL,NULL,33,DATE '2014-01-01',NULL,2.92577,'Medium oil used in diesel engines, and heating systems (aka red diesel)');
	INSERT INTO CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) VALUES (184385935,49,8106,4,'gb',NULL,NULL,33,DATE '2014-01-01',NULL,0.1967451,'Medium oil used in diesel engines, and heating systems (aka red diesel)');
END;
/

@update_tail

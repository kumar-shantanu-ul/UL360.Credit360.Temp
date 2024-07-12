-- Please update version.sql too -- this keeps clean builds in sync
define version=2763
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- FB71585
Insert into CSR.STD_FACTOR (STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) values (184401738,55,8688,2,null,null,null,17,date '2014-01-01',date '2015-01-01',0.02759,'Standard natural gas received through the gas mains grid network in the UK');

UPDATE CSR.STD_FACTOR
   SET VALUE = 0.155873333
 WHERE STD_FACTOR_ID = 184398943;

UPDATE CSR.STD_FACTOR
   SET VALUE = 0.157086667
 WHERE STD_FACTOR_ID = 184398944;

UPDATE CSR.STD_FACTOR
   SET VALUE = 0.146264286
 WHERE STD_FACTOR_ID = 184398959;

UPDATE CSR.STD_FACTOR
   SET VALUE = 0.147564286
 WHERE STD_FACTOR_ID = 184398960;

-- ** New package grants **

-- *** Packages ***

@update_tail

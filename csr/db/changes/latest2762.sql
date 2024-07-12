-- Please update version.sql too -- this keeps clean builds in sync
define version=2762
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

update CSR.STD_MEASURE_CONVERSION 
  set A=0.0000000000000001634557634436
where DESCRIPTION='MMBOE';

update CSR.STD_MEASURE_CONVERSION 
  set A=0.0000000000000163455763443681
where DESCRIPTION='kBOE/m^3';

update CSR.STD_MEASURE_CONVERSION 
  set A=0.0000000000000000163455763444
where DESCRIPTION='MMBOE/m^3';

-- ** New package grants **

-- *** Packages ***

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2764
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***

INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) 
VALUES (120, 3,'mm',1000,1,0);

-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail

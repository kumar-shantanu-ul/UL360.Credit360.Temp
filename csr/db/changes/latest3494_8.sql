-- Please update version.sql too -- this keeps clean builds in sync
define version=3494
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
UPDATE CSR.IND 
   SET TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE = NULL
 WHERE TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE IS NOT NULL;
ALTER TABLE CSR.IND MODIFY (TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE NUMBER(10,4));

UPDATE CSRIMP.IND 
   SET TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE = NULL
 WHERE TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE IS NOT NULL;
ALTER TABLE CSRIMP.IND MODIFY (TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE NUMBER(10,4));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

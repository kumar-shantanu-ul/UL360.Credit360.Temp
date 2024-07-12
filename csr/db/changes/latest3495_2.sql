-- Please update version.sql too -- this keeps clean builds in sync
define version=3495
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

UPDATE csr.ind
   SET tolerance_number_of_periods = NULL, tolerance_number_of_standard_deviations_from_average = NULL
 WHERE tolerance_number_of_periods IS NOT NULL OR tolerance_number_of_standard_deviations_from_average IS NOT NULL;

ALTER TABLE csr.ind ADD CONSTRAINT CHK_TOLERANCE_TYPE CHECK (TOLERANCE_TYPE IN (0,1,2,3,4));
ALTER TABLE csr.ind ADD CONSTRAINT CHK_TOLERANCE_NUMBER_OF_PERIODS CHECK (
    TOLERANCE_NUMBER_OF_PERIODS >= 3 AND TOLERANCE_NUMBER_OF_PERIODS <= 99
);
ALTER TABLE csr.ind ADD CONSTRAINT CHK_TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE CHECK (
    TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE >= 0 AND TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE <= 5
);
ALTER TABLE csr.ind DROP CONSTRAINT IND_TOLERANCE;

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

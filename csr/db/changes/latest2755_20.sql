-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.IMP_VAL DROP CONSTRAINT FK_REG_MET_VAL_IMP_VAL;

ALTER TABLE CSR.IMP_VAL ADD CONSTRAINT FK_REG_MET_VAL_IMP_VAL 
FOREIGN KEY (APP_SID, SET_REGION_METRIC_VAL_ID)
 REFERENCES CSR.REGION_METRIC_VAL(APP_SID, REGION_METRIC_VAL_ID);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../indicator_body
@../region_body
@../region_metric_body

@update_tail

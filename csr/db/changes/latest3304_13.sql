-- Please update version.sql too -- this keeps clean builds in sync
define version=3304
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DATA_BUCKET_VAL
DROP COLUMN VAL_KEY;
ALTER TABLE CSR.DATA_BUCKET_VAL
ADD VAL_KEY NUMBER(10);

ALTER TABLE CSR.DATA_BUCKET_SOURCE_DETAIL
DROP COLUMN VAL_KEY;
ALTER TABLE CSR.DATA_BUCKET_SOURCE_DETAIL
ADD VAL_KEY NUMBER(10) NOT NULL;


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
@../data_bucket_pkg
@../data_bucket_body

@update_tail

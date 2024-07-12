-- Please update version.sql too -- this keeps clean builds in sync
define version=3137
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.std_factor_set ADD visible_in_classic_tool NUMBER(1) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- Update up to and including 30th October 2017
UPDATE csr.std_factor_set
   SET visible_in_classic_tool = 1
 WHERE published_dtm IS NULL OR
  published_dtm < DATE '2017-10-31';
 
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_body

@update_tail

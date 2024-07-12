-- Please update version.sql too -- this keeps clean builds in sync
define version=3304
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.IND DROP CONSTRAINT CK_IND_AGGR;
ALTER TABLE CSR.IND 
  ADD CONSTRAINT CK_IND_AGGR CHECK (aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'NONE', 'DOWN', 'FORCE DOWN', 'LOWEST', 'FORCE LOWEST', 'HIGHEST', 'FORCE HIGHEST'));

ALTER TABLE CSRIMP.IND DROP CONSTRAINT CK_IND_AGGR;
ALTER TABLE CSRIMP.IND 
  ADD CONSTRAINT CK_IND_AGGR CHECK (aggregate IN ('SUM', 'FORCE SUM', 'AVERAGE', 'NONE', 'DOWN', 'FORCE DOWN', 'LOWEST', 'FORCE LOWEST', 'HIGHEST', 'FORCE HIGHEST'));

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
@../indicator_body

@update_tail

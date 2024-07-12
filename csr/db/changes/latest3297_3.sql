-- Please update version.sql too -- this keeps clean builds in sync
define version=3297
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
GRANT CREATE TABLE TO csr;

DROP INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH;

CREATE INDEX csr.IX_CP_ACTIVITY_DETAILS_SEARCH ON csr.COMPLIANCE_PERMIT(ACTIVITY_DETAILS) indextype is ctxsys.context 
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

REVOKE CREATE TABLE FROM csr;


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

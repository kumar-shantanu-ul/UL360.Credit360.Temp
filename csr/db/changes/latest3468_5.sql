-- Please update version.sql too -- this keeps clean builds in sync
define version=3468
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE cms.zap_pkg IS END;
/
grant execute on cms.zap_pkg to csr;


-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/zap_pkg
@../../../aspen2/cms/db/zap_body
@../zap_pkg
@../zap_body

@update_tail

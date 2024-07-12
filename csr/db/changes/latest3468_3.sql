-- Please update version.sql too -- this keeps clean builds in sync
define version=3468
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.t_split_table TO csrimp;
-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/db/utils_pkg
@../../../aspen2/db/utils_body

@../csrimp/imp_body

@update_tail

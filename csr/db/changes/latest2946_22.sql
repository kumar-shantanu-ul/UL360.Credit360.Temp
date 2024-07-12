-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table cms.tab_column add format_mask varchar2(200);
alter table csrimp.cms_tab_column add format_mask varchar2(200);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body
@../../../aspen2/cms/db/tab_body

@update_tail

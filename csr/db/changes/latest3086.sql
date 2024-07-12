-- Please update version.sql too -- this keeps clean builds in sync
define version=3086
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
grant select, insert, update, delete on csrimp.chain_co_tab_related_co_type to tool_user;

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX chain.ix_company_produ_tag_group_id_ on chain.company_product_tag (app_sid, tag_group_id, tag_id);
CREATE INDEX chain.ix_product_suppl_tag_group_id_ on chain.product_supplier_tag (app_sid, tag_group_id, tag_id);

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

@update_tail

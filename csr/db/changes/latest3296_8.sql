-- Please update version.sql too -- this keeps clean builds in sync
define version=3296
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DELETE FROM cms.tab_column_link
 WHERE column_sid_1 = column_sid_2
   AND item_id_1 = item_id_2;

ALTER TABLE cms.tab_column_link ADD (
	CONSTRAINT ck_tab_column_link_self CHECK (column_sid_1 <> column_sid_2 OR item_id_1 <> item_id_2)
);

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

@update_tail

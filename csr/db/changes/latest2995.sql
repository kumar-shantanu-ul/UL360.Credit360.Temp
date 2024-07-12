-- Please update version.sql too -- this keeps clean builds in sync
define version=2995
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.filter_export_batch DROP CONSTRAINT PK_FILTER_EXPORT_BATCH;

DELETE FROM chain.filter_export_batch WHERE compound_filter_id IS NULL;

ALTER TABLE chain.filter_export_batch ADD CONSTRAINT PK_FILTER_EXPORT_BATCH PRIMARY KEY (APP_SID, BATCH_JOB_ID, COMPOUND_FILTER_ID);
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
@../chain/filter_pkg
@../chain/filter_body

@update_tail

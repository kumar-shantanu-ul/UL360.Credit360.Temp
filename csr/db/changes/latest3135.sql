-- Please update version.sql too -- this keeps clean builds in sync
define version=3135
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DELETE FROM chain.bsci_log;
ALTER TABLE chain.bsci_log ADD SERVICE VARCHAR2(255) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.batch_job_type 
   SET timeout_mins = 360 
 WHERE batch_job_type_id = 26;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/bsci_pkg

@../enable_body
@../chain/bsci_body

@update_tail

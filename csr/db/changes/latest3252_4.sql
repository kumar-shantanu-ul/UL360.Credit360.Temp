-- Please update version.sql too -- this keeps clean builds in sync
define version=3252
define minor_version=4
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
UPDATE csr.compliance_item_rollout
   SET rollout_dtm = sysdate,
       rollout_pending = 1
 WHERE country = 'us'
   AND region = 'DE'
   AND suppress_rollout = 0; 


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

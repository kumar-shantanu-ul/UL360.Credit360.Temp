-- Please update version.sql too -- this keeps clean builds in sync
define version=3450
define minor_version=3
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
UPDATE security.user_table
   SET account_enabled = 0
 WHERE sid_id IN (
    SELECT cu.csr_user_sid
      FROM security.user_table ut
      JOIN csr.trash t ON ut.sid_id = t.trash_sid
      JOIN csr.csr_user cu ON cu.csr_user_sid = ut.sid_id
     WHERE ut.account_enabled = 1
 );


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_body

@update_tail

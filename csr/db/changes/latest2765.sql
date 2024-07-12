-- Please update version.sql too -- this keeps clean builds in sync
define version=2765
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

--FB60136
UPDATE csr.std_alert_type 
   SET description = 'User account – pending deactivation'
 WHERE std_alert_type_id = 73;

-- ** New package grants **

-- *** Packages ***

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2799
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.std_alert_type
   SET send_trigger = 'You manually sub-delegate a form and choose to notify users by clicking ''Yes - send e-mails'''
 WHERE std_alert_type_id = 2;

 -- ** New package grants **

-- *** Packages ***

@update_tail

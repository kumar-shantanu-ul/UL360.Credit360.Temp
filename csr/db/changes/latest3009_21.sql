-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=21
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

UPDATE csr.module
   SET warning_msg = 'This enables parts of the supply chain system and cannot be undone.<br/><br/><span style="font-weight:bold">DANGER!</span><br/>Re-running this script will reinstate default property permissions and menus.<br/>It may remove some non-standard property menus.'
 WHERE Enable_Sp = 'EnableProperties';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_body

@update_tail

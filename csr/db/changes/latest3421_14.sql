-- Please update version.sql too -- this keeps clean builds in sync
define version=3421
define minor_version=14
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
UPDATE chain.capability
   SET description = 'Allows users to promote a company user to a company administrator and (combined with "Remove user from company") remove administrators from the company on the Company users page. Also provides access to the "User''s roles" checkboxes on the page, allowing them to view/assign roles to the user.'
 WHERE capability_name = 'Promote user';
 
UPDATE chain.capability
   SET description = 'Allows users to view and edit the "User account is active" and "Send email alerts" checkboxes when editing user details, controlling whether the user account is active and whether the user receives email alerts.'
 WHERE capability_name = 'Manage user';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

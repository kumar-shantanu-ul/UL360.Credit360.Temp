-- Please update version.sql too -- this keeps clean builds in sync
define version=2983
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.capability ADD description VARCHAR2(1024);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 121, 'Capability enabled');

BEGIN
	DELETE FROM csr.capability
	 where name = 'Use gauge-style charts';

	UPDATE csr.capability 
	   SET description='User Management: Turns on the ability to send messages to users on user list page'
	 WHERE name = 'Message users';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of email/full name panel on User details page'
	 WHERE name = 'Edit user details';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Groups�section on User details page'
	 WHERE name = 'Edit user groups';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Starting points�section on User details page'
	 WHERE name = 'Edit user starting points';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Delegation cover section on User details page'
	 WHERE name = 'Edit user delegation cover';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of default�User roles section on User details page'
	 WHERE name = 'Edit user roles';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of restricted User roles�section on User details�page (based on which roles you have ability to grant to)'
	 WHERE name = 'User roles admin';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Active checkbox on User details page'
	 WHERE name = 'Edit user active';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Accessibility section on User details page'
	 WHERE name = 'Edit user accessibility';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Send alerts? checkbox on User details page'
	 WHERE name = 'Edit user alerts';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Regional settings (language / culture) on User details page'
	 WHERE name = 'Edit user regional settings';
	UPDATE csr.capability
	   SET description='User Management: Allows editing of�Regions with which user is associated section on User details page (Note: This field is not necessary on most new sites. It is only used with the Community involvement module.)'
	 WHERE name = 'Edit user region association';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to copy forward values from the previous sheet'
	 WHERE name = 'Copy forward delegation';
	UPDATE csr.capability
	   SET description='Reporting: Allows user to save region sets for other users to access'
	 WHERE name = 'Save shared region sets';
	UPDATE csr.capability
	   SET description='Reporting: Allows user to save indicator sets for other users to access'
	 WHERE name = 'Save shared indicator sets';
	UPDATE csr.capability
	   SET description='User Management: Allows the display of the user fields user name, full name, friendly name, email, job title and phone number in user management'
	 WHERE name = 'View user details';
	UPDATE csr.capability
	   SET description='Delegations: It''s possible in delegations to submit a parent before a child (e.g. if the person who normally enters is off on holiday). Turning this on stops this happening.'
	 WHERE name = 'Allow parent sheet submission before child sheet approval';
	UPDATE csr.capability
	   SET description='Delegations: Allows a sheet to be returned once approved'
	 WHERE name = 'Allow sheet to be returned once approved';
	UPDATE csr.capability
	   SET description='Delegations: Only allow bottom delegation to enter data'
	 WHERE name = 'Only allow bottom delegation to enter data';
	UPDATE csr.capability
	   SET description='Data Explorer: Shows the�Suppress unmerged data message�checkbox'
	 WHERE name = 'Highlight unmerged data';
	UPDATE csr.capability
	   SET description='Region Management: Show/hide ability to link documents to regions (used for CRC reporting but could be implemented more broadly)'
	 WHERE name = 'Edit Region Docs';
	UPDATE csr.capability
	   SET description='Templated Reports: Needed to manage advanced settings for administering templated reports e.g. "change owner"'
	 WHERE name = 'Manage all templated report settings';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to subdelegate sheets'
	 WHERE name = 'Subdelegation';
	UPDATE csr.capability
	   SET description='Delegations: Allows a user to split a delegation into separate child regions'
	 WHERE name = 'Split delegations';
	UPDATE csr.capability
	   SET description='Delegations: Allows the user to raise a data change request for a sheet they have already submitted'
	 WHERE name = 'Allow users to raise data change requests';
	UPDATE csr.capability
	   SET description='My Details: Allows user to change their full name and email address'
	 WHERE name = 'Edit personal details';
	UPDATE csr.capability
	   SET description='Data Explorer: On-the-fly calculations are often used in Data Explorer to show this year versus the�previous year. In this situation,�showing the previous year label doesn''t really make sense, so this capability can be used to hide it.'
	 WHERE name = 'Hide year on chart axis labels when chart has FlyCalc';
	UPDATE csr.capability
	   SET description='My Details: Show and change who is covering for you on delegation data provision'
	 WHERE name = 'Edit personal delegation cover';
	UPDATE csr.capability
	   SET description='Delegations: Show additional export option in sheet export toolbar item dropdown'
	 WHERE name = 'Can export delegation summary';
	UPDATE csr.capability
	   SET description='System Management: This capability is required to view the audit log on the Indicator details, Region details, and User details pages'
	 WHERE name = 'View user audit log';
	UPDATE csr.capability
	   SET description='Delegations: Shows a�link to the delegation from the Sheet page'
	 WHERE name = 'View Delegation link from Sheet';
	UPDATE csr.capability
	   SET description='Delegations: Shows a message indicating there are unsaved values on a delegation form when you click away from the web page'
	 WHERE name = 'Enable Delegation Sheet changes warning';
	UPDATE csr.capability
	   SET description='Portals: Tabs (or Portal pages)�can generally only be edited by the owner. This capability allows users to make changes to any tab (including�adding items, editing tab settings,�deleting the tab, hiding the�tab or showing tabs that they have hidden)�via�the�Options�menu on their homepage.'
	 WHERE name = 'Manage any portal';
	UPDATE csr.capability
	   SET description='CMS: Allows users to see Public filters folder in list views (ability to write to the folder is permission controlled)'
	 WHERE name = 'Allow user to share CMS filters';
	UPDATE csr.capability
	   SET description='Portals: Allows user to add new portal tabs. �Also allows a user to copy a tab, hide a tab or view tabs they have�hidden via the Options�menu on their homepage.'
	 WHERE name = 'Add portal tabs';
	UPDATE csr.capability
	   SET description='User Management: Show / edit line-manager field in the User details page'
	 WHERE name = 'Edit user line manager';
	UPDATE csr.capability
	   SET description='Excel Models: Treat N/A as a blank cell value in Excel models instead of as N/A'
	 WHERE name = 'Suppress N\A''s in model runs';
	UPDATE csr.capability
	   SET description='Templated Reports: View and download any templated reports, even if you didn�t generate or receive them'
	 WHERE name = 'Download all templated reports';
	UPDATE csr.capability
	   SET description='Delegations: Data Change requests where the user''s data has been approved normally need the current owner to approve them. If enabled, the form is automatically returned to the user.'
	 WHERE name = 'Automatically approve Data Change Requests';
	UPDATE csr.capability
	   SET description='Delegations: Allows users to change values on delegations sheets in spite of system lock date settings'
	 WHERE name = 'Can edit forms before system lock date';
	UPDATE csr.capability
	   SET description='User Management: Allows management of group membership from the users list page'
	 WHERE name = 'Can manage group membership list page';
	UPDATE csr.capability
	   SET description='User Management: Allows deactivation of users from the users list page'
	 WHERE name = 'Can deactivate users list page';
	UPDATE csr.capability
	   SET description='System Management: Allows user to view emission factors'
	 WHERE name = 'View emission factors';
	UPDATE csr.capability
	   SET description='System Management: Allows user to edit emission factors'
	 WHERE name = 'Manage emission factors';
END;
/

-- ** New package grants **
-- Create dummy packages for the grant
create or replace package csr.capability_pkg as
	procedure dummy;
end;
/
create or replace package body csr.capability_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.capability_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../capability_pkg
@../capability_body

@update_tail

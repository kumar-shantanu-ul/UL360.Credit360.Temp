-- Please update version.sql too -- this keeps clean builds in sync
define version=3206
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.capability ADD (
	  description						VARCHAR2(1024)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE chain.capability SET description = 'Ability to edit details in the "Company" tab on the Supply Chain Company Details page.' WHERE capability_name = 'Company';
UPDATE chain.capability SET description = 'View and make change to details in the Company Details page.' WHERE capability_name = 'Suppliers';
UPDATE chain.capability SET description = 'Give users a user name to log in with that is separate from their email address.' WHERE capability_name = 'Specify user name';
UPDATE chain.capability SET description = 'View and edit any questionnaire associated with the company.' WHERE capability_name = 'Questionnaire';
UPDATE chain.capability SET description = 'Submit a questionnaire associated with the user''s company.' WHERE capability_name = 'Submit questionnaire';
UPDATE chain.capability SET description = 'Add actions (issues) to individual questions on a supplier survey. The Survey Answer issue type must also be enabled.' WHERE capability_name = 'Query questionnaire answers';
UPDATE chain.capability SET description = 'Managing read, write, approve, submit permissions on a survey for a particular user.' WHERE capability_name = 'Manage questionnaire security';
UPDATE chain.capability SET description = 'Create a survey that can be sent to suppliers.' WHERE capability_name = 'Create questionnaire type';
UPDATE chain.capability SET description = 'Register a user without sending them an invitation.' WHERE capability_name = 'Setup stub registration';
UPDATE chain.capability SET description = 'Reset a user''s password.' WHERE capability_name = 'Reset password';
UPDATE chain.capability SET description = 'Create a user from the Company users page.' WHERE capability_name = 'Create user';
UPDATE chain.capability SET description = 'Ability to add users to the company.' WHERE capability_name = 'Add user to company';
UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Events';
UPDATE chain.capability SET description = 'Ability to read and create new actions on supply chain specific pages that don''t result from data collection (e.g. audits and surveys).' WHERE capability_name = 'Actions';
UPDATE chain.capability SET description = 'Whether users can view or edit tasks the company has to do. Tasks have replaced "actions" and "events".' WHERE capability_name = 'Tasks';
UPDATE chain.capability SET description = 'Whether you can edit any company metrics.' WHERE capability_name = 'Metrics';
UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Products';
UPDATE chain.capability SET description = 'Relates to whether you can add products a supplier sells to a top company.' WHERE capability_name = 'Components';
UPDATE chain.capability SET description = 'Ability to promote a company user to a company administrator from the Company users page.' WHERE capability_name = 'Promote user';
UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Product code types';
UPDATE chain.capability SET description = 'This controls who can view and edit company folders and documents in the Supply Chain document library.' WHERE capability_name = 'Uploaded file';
UPDATE chain.capability SET description = 'Ability to edit another company user''s email address on the Company users page.' WHERE capability_name = 'Edit user email address';
UPDATE chain.capability SET description = 'Ability to edit your own email address on the Supply Chain My details page and the Company users page.' WHERE capability_name = 'Edit own email address';
UPDATE chain.capability SET description = 'View supplier audits on a "Supplier Audits" tab in the supplier profile page.' WHERE capability_name = 'View supplier audits';
UPDATE chain.capability SET description = 'Ability to view/edit any extra details in yellow in the supplier details tab.' WHERE capability_name = 'View company extra details';
UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Manage activities';
UPDATE chain.capability SET description = 'Ability to add and remove users from roles.' WHERE capability_name = 'Manage user';
UPDATE chain.capability SET description = 'Read access allows the user to view alternative names for the company. These are displayed under "Additional information" on the Company details tab of the company''s profile page (in this case, the Manage companies page). Read/write access allows the user to view and edit alternative names for the company.' WHERE capability_name = 'Alternative company names';
UPDATE chain.capability SET description = 'Specific to Carbon Trust Hotspotter tool.' WHERE capability_name = 'CT Hotspotter';
UPDATE chain.capability SET description = 'The company is at the highest level of the hierarchy and can view all suppliers.' WHERE capability_name = 'Is top company';
UPDATE chain.capability SET description = 'Enable the Supplier Registration Wizard for sending questionnaires to new companies (as part of an invitation) or existing companies.' WHERE capability_name = 'Send questionnaire invitation';
UPDATE chain.capability SET description = 'Create a new company with an invitation but without a questionnaire.' WHERE capability_name = 'Send company invitation';
UPDATE chain.capability SET description = 'Deprecated - replaced by tertiary relationships' WHERE capability_name = 'Send invitation on behalf of';
UPDATE chain.capability SET description = 'Ability to send news items.' WHERE capability_name = 'Send newsflash';
UPDATE chain.capability SET description = 'Ability to view news items.' WHERE capability_name = 'Receive user-targeted newsflash';
UPDATE chain.capability SET description = 'Approve a questionnaire submitted by another company.' WHERE capability_name = 'Approve questionnaire';
UPDATE chain.capability SET description = 'Allow users to cancel a survey that has been sent to a supplier. Once canceled, the supplier can no longer access the survey to edit or submit it.' WHERE capability_name = 'Reject questionnaire';
UPDATE chain.capability SET description = 'Change the user who receives supplier messages (if you only want certain users as contacts for certain suppliers) and add or remove users from the Supplier followers plugin.' WHERE capability_name = 'Change supplier follower';
UPDATE chain.capability SET description = 'Must be true for the workflow transition buttons to be displayed.' WHERE capability_name = 'Manage workflows';
UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the supplier.' WHERE capability_name = 'Create company as subsidiary';
UPDATE chain.capability SET description = 'Create a new company user without an invitation (i.e. from the Company users page or the Company invitation wizard). If false, the Company invitation wizard does not allow you to search for existing companies or add contacts.' WHERE capability_name = 'Create company without invitation.';
UPDATE chain.capability SET description = 'Create a new company user with an invitation.' WHERE capability_name = 'Create company user with invitation';
UPDATE chain.capability SET description = 'Remove a user from the company so that they are no longer a member of the company and no longer have the permissions associated with that company type. This does not delete a user from the system. In order to remove administrator users, the "Promote user" permission is also required.' WHERE capability_name = 'Remove user from company';
UPDATE chain.capability SET description = 'Create a new company by sending an invitation with a questionnaire.' WHERE capability_name = 'Send questionnaire invitation to new company';
UPDATE chain.capability SET description = 'Send a questionnaire to an existing company.' WHERE capability_name = 'Send questionnaire invitation to existing company';
UPDATE chain.capability SET description = 'See secondary suppliers that you have no relationship with.' WHERE capability_name = 'Supplier with no established relationship';
UPDATE chain.capability SET description = 'Create a company relationship with an existing company without sending a company or questionnaire invitation. The "Supplier with no established relationship" must also be set to "Read" on the company type relationship. Users with the permission can search for existing companies that they don''t have a relationship with from the Supplier list tab/plugin on the Manage Companies page. ' WHERE capability_name = 'Create relationship with supplier';
UPDATE chain.capability SET description = 'View the relationship between the secondary and tertiary company on the "Relationships" plugin.' WHERE capability_name = 'View relationships between A and B';
UPDATE chain.capability SET description = 'Add or remove a relationship between a secondary and a tertiary company from the "Relationships" plugin.' WHERE capability_name = 'Add remove relationships between A and B';
UPDATE chain.capability SET description = 'Ability to ask an auditor to carry out an audit on a supplier without specifying/creating the audit (requires its own page). The Auditor company must also have the “Create supplier audit” permission on the Auditor > Auditee company type relationship.' WHERE capability_name = 'Request audits';
UPDATE chain.capability SET description = 'Create a 2nd party audit (i.e. top company auditing a supplier).' WHERE capability_name = 'Create supplier audit';
UPDATE chain.capability SET description = 'If true, users can filter by "Supplier of" and "Related by <business relationship type>" on the Supplier list plugin.' WHERE capability_name = 'Filter on company relationships';
UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for audits on companies.' WHERE capability_name = 'Filter on company audits';
UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for the fields of CMS tables on the company record. The CMS table must include company columns pointing to actual company SIDs. A flag on the CMS table is also required (this is enabled automatically but may be switched off).' WHERE capability_name = 'Filter on cms companies';
UPDATE chain.capability SET description = 'Ability to create business relationships. Business relationship types must also be configured.' WHERE capability_name = 'Create business relationships';
UPDATE chain.capability SET description = 'Ability to add the company to business relationships.' WHERE capability_name = 'Add company to business relationships';
UPDATE chain.capability SET description = 'View the company''s business relationships. Requires the Business relationships plugin/tab.' WHERE capability_name = 'View company business relationships';
UPDATE chain.capability SET description = 'Ability to update the time periods on a business relationship.' WHERE capability_name = 'Update company business relationship periods';
UPDATE chain.capability SET description = 'Make a company active or inactive. When a company is made inactive, users of that company cannot log in and new surveys, audits, delegation forms, logging forms and activities cannot be created. Existing data can be viewed.' WHERE capability_name = 'Deactivate company';
UPDATE chain.capability SET description = 'Allows the secondary company in the company relationship to create a business relationship with the primary company.' WHERE capability_name = 'Add company to business relationships (supplier => purchaser)';
UPDATE chain.capability SET description = 'Allows the secondary company to view business relationships with the primary company. Requires the business relationships plugin/tab.' WHERE capability_name = 'View company business relationships (supplier => purchaser)';
UPDATE chain.capability SET description = 'Allows the secondary company to update the time periods on a business relationship between them and the primary company.' WHERE capability_name = 'Update company business relationship periods (supplier => purchaser)';
UPDATE chain.capability SET description = 'Send a questionnaire to a supplier (new or existing) on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of';
UPDATE chain.capability SET description = 'Send a questionnaire to an existing supplier on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of to existing company';
UPDATE chain.capability SET description = 'Create an audit on the tertiary company on behalf of the secondary company. For example, if the indirect relationship were "Top Company (Third party auditor => Supplier), this permission would allow the top company to create an audit between the third party auditor and supplier.' WHERE capability_name = 'Create supplier audit on behalf of';
UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the tertiary company.' WHERE capability_name = 'Create subsidiary on behalf of';
UPDATE chain.capability SET description = 'View subsidiaries/sub-companies of the secondary company.' WHERE capability_name = 'View subsidiaries on behalf of';
UPDATE chain.capability SET description = 'Allows a holding company to ask any company in the system to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an existing company in the database';
UPDATE chain.capability SET description = 'Allows a holding company to ask a company that it has a direct company relationship with to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an established relationship';
UPDATE chain.capability SET description = 'Read access allows the user to view company scores. Scores are displayed in the score header on the company''s profile page, and in columns on the supplier list. Read/write access allows the user to view and edit company scores, if the score type is configured to allow the score to be set manually.' WHERE capability_name = 'Company scores';
UPDATE chain.capability SET description = 'View changes to the company score. Requires the Score header for company management page header plugin.' WHERE capability_name = 'View company score log';
UPDATE chain.capability SET description = 'Compare submissions of the same survey by a single company.' WHERE capability_name = 'Audit questionnaire responses';
UPDATE chain.capability SET description = 'Used if there is a separate tab used to show any tags associated with a company (not relevant if tags are shown on the same tab as the company details).' WHERE capability_name = 'Company tags';
UPDATE chain.capability SET description = 'Enables the user to follow or stop following companies through the Supplier follower plugin.' WHERE capability_name = 'Edit own follower status';
UPDATE chain.capability SET description = 'View certifications for companies on the supplier list page. This permission allows users to see the following information about the most recent audit of the type(s) specified in the certification: audit type, valid from, valid to, and audit result.' WHERE capability_name = 'View certifications';
UPDATE chain.capability SET description = 'Set the purchaser company in a relationship as the primary purchaser for that supplier.' WHERE capability_name = 'Set primary purchaser in a relationship between A and B';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/capability_pkg
@../chain/type_capability_pkg

@../chain/capability_body
@../chain/type_capability_body

@update_tail

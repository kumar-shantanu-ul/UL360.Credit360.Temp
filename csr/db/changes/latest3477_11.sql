-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables
TRUNCATE TABLE CHAIN.CAPABILITY_GROUP;
DROP SEQUENCE CHAIN.CAPABILITY_GROUP_SEQ;
DROP INDEX chain.ix_capability_gr_capability_id;

ALTER TABLE CHAIN.CAPABILITY_GROUP DROP CONSTRAINT UK_CI_CAPABILITY_GROUP;
ALTER TABLE CHAIN.CAPABILITY_GROUP DROP COLUMN CAPABILITY_ID;

-- Alter tables

ALTER TABLE CHAIN.CAPABILITY ADD (
	  CAPABILITY_GROUP_ID		    NUMBER(10, 0) DEFAULT 7 NOT NULL,
	  POSITION			            NUMBER(10, 0) DEFAULT 0 NOT NULL
	);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (1, 'Company Details' , 0, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (2, 'Business relationships' , 1, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (3, 'Users' , 2, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (4, 'Survey invitation' , 3, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (5, 'Onboarding and relationships' , 4, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (6, 'Advanced' , 5, 1);

    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (7, 'Other' , 6, 1);
END;
/

BEGIN
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 1
	WHERE capability_name IN ('Company', 'Suppliers', 'Alternative company names', 'Company scores', 'Company tags', 'View company extra details', 'View company score log');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 2
	WHERE capability_name IN ('Add company to business relationships', 'Update company business relationship periods', 'View company business relationships', 'Filter on company relationships', 'Create business relationships', 'View company business relationships (supplier => purchaser)', 'Update company business relationship periods (supplier => purchaser)', 'Add company to business relationships (supplier => purchaser)');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 3
	WHERE capability_name IN ('Edit own email address', 'Add user to company', 'Company user', 'Create user', 'Edit user email address', 'Manage user', 'Promote user', 'Remove user from company', 'Reset password', 'Specify user name');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 4
	WHERE capability_name IN ('Send questionnaire invitations on behalf of', 'Create questionnaire type', 'Manage questionnaire security', 'Questionnaire', 'Submit questionnaire', 'Approve questionnaire', 'Create company user with invitation', 'Reject questionnaire', 'Request questionnaire from an established relationship', 'Request questionnaire from an existing company in the database', 'Send questionnaire invitation', 'Send questionnaire invitation to existing company', 'Send questionnaire invitation to new company', 'Audit questionnaire responses', 'Create questionnaire type', 'Manage questionnaire security', 'Query questionnaire answers', 'Questionnaire', 'Setup stub registration', 'Submit questionnaire', 'Send questionnaire invitations on behalf of to existing company');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 5
	WHERE capability_name IN ('Change supplier follower', 'Create company as subsidiary', 'Create company user without invitation', 'Create company without invitation', 'Create relationship with supplier', 'Edit own follower status', 'Supplier with no established relationship', 'Deactivate company');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 6
	WHERE capability_name IN ('Send newsflash', 'Send company invitation', 'Send invitation on behalf of', 'Add supplier to products', 'Components', 'Create products', 'CT Hotspotter', 'Events', 'Manage activities', 'Manage product certification requirements', 'Metrics', 'Product certifications', 'Product code types', 'Product metric values', 'Product supplier certifications', 'Product supplier metric values', 'Product suppliers', 'Products', 'Tasks', 'Add product suppliers of suppliers', 'Product supplier certifications of suppliers', 'Product supplier metric values of suppliers', 'Product suppliers of suppliers', 'Filter on company audits', 'Filter on cms companies', 'Products as supplier', 'Product supplier metric values as supplier', 'Receive user-targeted newsflash', 'Product metric values as supplier');

	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 7
	WHERE capability_name IN ('Is top company', 'Actions', 'Uploaded file', 'View certifications', 'View country risk levels', 'Manage workflows', 'Actions', 'Create supplier audit', 'Request audits', 'Uploaded file', 'View certifications', 'View supplier audits', 'Add remove relationships between A and B', 'Create subsidiary on behalf of', 'Create supplier audit on behalf of', 'Set primary purchaser in a relationship between A and B', 'View relationships between A and B', 'View subsidiaries on behalf of');
END;
/


ALTER TABLE CHAIN.CAPABILITY ADD CONSTRAINT FK_CAP_CAP_GROUP
	FOREIGN KEY (CAPABILITY_GROUP_ID)
	REFERENCES CHAIN.CAPABILITY_GROUP(CAPABILITY_GROUP_ID)
;

create index chain.ix_capability_capability_gr on chain.capability (capability_group_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/capability_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3475
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CHAIN.CAPABILITY_GROUP_SEQ;

CREATE TABLE CHAIN.CAPABILITY_GROUP(
	CAPABILITY_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	CAPABILITY_ID			NUMBER(10, 0)		NOT NULL,
	GROUP_NAME				VARCHAR2(255)		NOT NULL,
	GROUP_POSITION			NUMBER(10, 0)		DEFAULT 0 NOT NULL,
	IS_VISIBLE				NUMBER(1, 0)		DEFAULT 1 NOT NULL,
	CONSTRAINT PK_CAPABILITY_GROUP PRIMARY KEY (CAPABILITY_GROUP_ID),
	CONSTRAINT UK_CI_CAPABILITY_GROUP UNIQUE (CAPABILITY_GROUP_ID, CAPABILITY_ID),
	CONSTRAINT FK_CAPABILITY_GROUP_CAPABILITY_ID
		FOREIGN KEY (CAPABILITY_ID)
		REFERENCES CHAIN.CAPABILITY (CAPABILITY_ID)
);

CREATE INDEX chain.ix_capability_gr_capability_id ON chain.capability_group (capability_id);
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Company', 'Suppliers', 'Alternative company names', 'Company scores', 'Company tags', 'View company extra details', 'View company score log')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Company Details', 0, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN ( 
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Add company to business relationships', 'Update company business relationship periods', 'View company business relationships', 'Filter on company relationships', 'Create business relationships', 'View company business relationships (supplier => purchaser)', 'Update company business relationship periods (supplier => purchaser)', 'Add company to business relationships (supplier => purchaser)')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Business relationships', 1, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Edit own email address', 'Add user to company', 'Company user', 'Create user', 'Edit user email address', 'Manage user', 'Promote user', 'Remove user from company', 'Reset password', 'Specify user name')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Users', 2, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Send questionnaire invitations on behalf of', 'Create questionnaire type', 'Manage questionnaire security', 'Questionnaire', 'Submit questionnaire', 'Approve questionnaire', 'Create company user with invitation', 'Reject questionnaire', 'Request questionnaire from an established relationship', 'Request questionnaire from an existing company in the database', 'Send questionnaire invitation', 'Send questionnaire invitation to existing company', 'Send questionnaire invitation to new company', 'Audit questionnaire responses', 'Create questionnaire type', 'Manage questionnaire security', 'Query questionnaire answers', 'Questionnaire', 'Setup stub registration', 'Submit questionnaire', 'Send questionnaire invitations on behalf of to existing company')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Survey invitation', 3, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN (
		SELECT capability_id 
		FROM chain.capability 
		WHERE capability_name IN ('Change supplier follower', 'Create company as subsidiary', 'Create company user without invitation', 'Create company without invitation', 'Create relationship with supplier', 'Edit own follower status', 'Supplier with no established relationship', 'Deactivate company')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Onboarding and relationships', 4, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN (
		SELECT capability_id 
		FROM chain.capability 
		WHERE capability_name IN ('Send newsflash', 'Send company invitation', 'Send invitation on behalf of', 'Add supplier to products', 'Components', 'Create products', 'CT Hotspotter', 'Events', 'Manage activities', 'Manage product certification requirements', 'Metrics', 'Product certifications', 'Product code types', 'Product metric values', 'Product supplier certifications', 'Product supplier metric values', 'Product suppliers', 'Products', 'Tasks', 'Add product suppliers of suppliers', 'Product supplier certifications of suppliers', 'Product supplier metric values of suppliers', 'Product suppliers of suppliers', 'Filter on company audits', 'Filter on cms companies', 'Products as supplier', 'Product supplier metric values as supplier', 'Receive user-targeted newsflash', 'Product metric values as supplier')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Advanced', 5, 1);
	END LOOP;
END;
/

BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Is top company', 'Actions', 'Uploaded file', 'View certifications', 'View country risk levels', 'Manage workflows', 'Actions', 'Create supplier audit', 'Request audits', 'Uploaded file', 'View certifications', 'View supplier audits', 'Add remove relationships between A and B', 'Create subsidiary on behalf of', 'Create supplier audit on behalf of', 'Set primary purchaser in a relationship between A and B', 'View relationships between A and B', 'View subsidiaries on behalf of')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Other', 6, 1);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/capability_pkg
@../chain/capability_body

@update_tail

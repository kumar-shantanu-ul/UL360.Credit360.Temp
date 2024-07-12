-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.SECTION_TRANSITION (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SECTION_TRANSITION_SID  		NUMBER(10, 0)    NOT NULL,
	FROM_SECTION_STATUS_SID 		NUMBER(10, 0)    NOT NULL,
	TO_SECTION_STATUS_SID   		NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SECTION_TRANSITION PRIMARY KEY (CSRIMP_SESSION_ID, SECTION_TRANSITION_SID),
	CONSTRAINT FK_SECTION_TRANSITION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csrimp.FLOW_STATE_ROLE_CAPABILITY drop constraint CHK_FLOW_STATE_ROLE_CAPABILITY DROP INDEX;
ALTER TABLE csrimp.flow_state_role_capability add constraint CHK_FLOW_STATE_ROLE_CAPABILITY CHECK (
	(ROLE_SID IS NULL AND GROUP_SID IS NOT NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL) OR
	(ROLE_SID IS NOT NULL AND GROUP_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NULL) OR
	(ROLE_SID IS NULL AND GROUP_SID IS NULL AND FLOW_INVOLVEMENT_TYPE_ID IS NOT NULL)
);

ALTER TABLE csrimp.FLOW_STATE_ROLE_CAPABILITY drop constraint UK_FLOW_STATE_ROLE_CAPABILITY DROP INDEX;
ALTER TABLE csrimp.FLOW_STATE_ROLE_CAPABILITY ADD CONSTRAINT UK_FLOW_STATE_ROLE_CAPABILITY UNIQUE (CSRIMP_SESSION_ID, FLOW_STATE_ID, FLOW_CAPABILITY_ID, ROLE_SID, GROUP_SID, FLOW_INVOLVEMENT_TYPE_ID);

-- *** Grants ***
GRANT INSERT ON csr.section_transition TO csrimp;
GRANT INSERT,SELECT,UPDATE,DELETE ON csrimp.section_transition TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail

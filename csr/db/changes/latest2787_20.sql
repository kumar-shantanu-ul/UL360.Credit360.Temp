-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.FLOW_STATE_TRANSITION ADD GROUP_SID_CAN_SET NUMBER(10, 0);
ALTER TABLE CSRIMP.FLOW_STATE_TRANSITION ADD GROUP_SID_CAN_SET NUMBER(10, 0);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE CSR.FLOW_STATE_TRANSITION ADD CONSTRAINT FK_FST_GROUP 
	FOREIGN KEY (GROUP_SID_CAN_SET) REFERENCES SECURITY.GROUP_TABLE(SID_ID);

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\cms\db\tab_pkg
@..\chain\chain_pkg
@..\chain\company_pkg

@..\..\..\aspen2\cms\db\tab_body
@..\flow_body
@..\chain\company_body
@..\schema_body
@..\csrimp\imp_body

@update_tail

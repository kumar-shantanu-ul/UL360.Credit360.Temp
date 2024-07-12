-- Please update version.sql too -- this keeps clean builds in sync
define version=3200
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSRIMP.MAP_SECONDARY_REGION_TREE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_LOG_ID NUMBER(10) NOT NULL,
	NEW_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SCNDRY_RGN_TREE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCNDRY_RGN_TREE_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_SCNDRY_RGN_TREE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT SELECT ON csr.scndry_region_tree_log_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body

@update_tail

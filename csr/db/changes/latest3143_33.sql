-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=33
@update_header

-- *** DDL ***
-- Create tables

--csrimp
CREATE TABLE CSRIMP.FLOW_ITEM_REGION (
	CSRIMP_SESSION_ID				        NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    FLOW_ITEM_ID                            NUMBER(10, 0)    NOT NULL,
    REGION_SID                              NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FLOW_ITEM_REGION PRIMARY KEY (CSRIMP_SESSION_ID, FLOW_ITEM_ID, REGION_SID),
    CONSTRAINT FK_FLOW_ITEM_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
-- Alter tables


-- *** Grants ***
grant insert, update, select on csr.flow_item_region to csrimp;

-- ** Cross schema constraints ***


-- *** Views ***
-- Please paste the content of the view.

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

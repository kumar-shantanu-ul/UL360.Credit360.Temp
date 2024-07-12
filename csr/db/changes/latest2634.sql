--Please update version.sql too -- this keeps clean builds in sync
define version=2634
@update_header

-- Alter tables
ALTER TABLE chain.business_relationship_type ADD (
	FORM_PATH		VARCHAR2(255),
	TAB_SID			NUMBER(10, 0),
	COLUMN_SID		NUMBER(10, 0)
);
 
-- ** Cross schema constraints ***
ALTER TABLE chain.business_relationship_type ADD (
	CONSTRAINT fk_bus_rel_tab FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB(APP_SID, TAB_SID),
	CONSTRAINT fk_bus_rel_tab_column FOREIGN KEY (APP_SID, TAB_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN(APP_SID, TAB_SID, COLUMN_SID)
);
 

-- *** Packages ***
@../chain/business_relationship_pkg
@../chain/business_relationship_body

	
@update_tail
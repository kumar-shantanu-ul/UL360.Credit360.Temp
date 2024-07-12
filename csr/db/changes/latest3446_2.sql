-- Please update version.sql too -- this keeps clean builds in sync
define version=3446
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.ISSUE_ACTION_LOG ADD (
	IS_PUBLIC					NUMBER(1, 0),
	INVOLVED_USER_SID			NUMBER(10, 0),
	INVOLVED_USER_SID_REMOVED	NUMBER(10, 0)
);


ALTER TABLE CSRIMP.ISSUE_ACTION_LOG ADD (
	IS_PUBLIC					NUMBER(1, 0),
	INVOLVED_USER_SID			NUMBER(10, 0),
	INVOLVED_USER_SID_REMOVED	NUMBER(10, 0)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	BEGIN
		INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) 
			VALUES (13,'Issues',6);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (25/*CSR.CSR_DATA_PKG.IAT_IS_PUBLIC_CHANGED*/, 'Public status changed');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (26/*CSR.CSR_DATA_PKG.IAT_INVOLVED_USER_ASSIGNED*/, 'Involved user assigned');
	INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) 
		VALUES (27/*CSR.CSR_DATA_PKG.IAT_INVOLVED_USER_SID_REMOVED*/, 'Involved user removed');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../csrimp/imp_body
@../issue_pkg
@../issue_body
@../schema_body

@update_tail

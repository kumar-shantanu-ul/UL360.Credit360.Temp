-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.BSCI_SUPPLIER
ADD (
	CODE_OF_CONDUCT_SIGN_INT	VARCHAR2(255) NULL,
	SA8000_CERTIFIED			VARCHAR2(255) NULL,
	AUDIT_CERTIFICATION			VARCHAR2(4000) NULL
);

ALTER TABLE CHAIN.BSCI_AUDIT
ADD (
	EXECSUMM_AUDIT_RPT			VARCHAR2(4000) NULL
);

ALTER TABLE CSRIMP.CHAIN_BSCI_SUPPLIER
ADD (
	CODE_OF_CONDUCT_SIGN_INT	VARCHAR2(255) NULL,
	SA8000_CERTIFIED			VARCHAR2(255) NULL,
	AUDIT_CERTIFICATION			VARCHAR2(4000) NULL
);

ALTER TABLE CSRIMP.CHAIN_BSCI_AUDIT
ADD (
	EXECSUMM_AUDIT_RPT			VARCHAR2(4000) NULL
);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/bsci_pkg
@../chain/bsci_body

@../schema_body
@../csrimp/imp_body

@update_tail

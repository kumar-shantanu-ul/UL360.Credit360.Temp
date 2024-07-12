-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CHAIN.BSCI_OPTIONS
ADD (
	PRODUCER_LINKED					NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_BSCI_OPTIONS_PROD_LINKED CHECK (PRODUCER_LINKED IN (0,1))
);

ALTER TABLE CSRIMP.CHAIN_BSCI_OPTIONS
ADD PRODUCER_LINKED					NUMBER(1);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\bsci_pkg

@..\chain\bsci_body
@..\csrimp\imp_body
@..\schema_body

@update_tail

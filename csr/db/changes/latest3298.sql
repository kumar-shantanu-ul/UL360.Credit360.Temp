-- Please update version.sql too -- this keeps clean builds in sync
define version=3298
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables


ALTER TABLE CSR.CUSTOMER DROP CONSTRAINT FK_TRUCOST_PORTLET_TAB_ID
;

ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT FK_TRUCOST_PORTLET_TAB_ID
    FOREIGN KEY (APP_SID, TRUCOST_PORTLET_TAB_ID)
    REFERENCES CSR.TAB(APP_SID, TAB_ID)
;

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
@../chain/chain_pkg

@../csr_app_body
@../chain/chain_body


@update_tail

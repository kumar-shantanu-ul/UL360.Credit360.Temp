-- Please update version.sql too -- this keeps clean builds in sync
define version=3315
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.sheet_potential_orphan_files
(
    APP_SID                 NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SHEET_VALUE_ID          NUMBER(10, 0) NOT NULL,
    FILE_UPLOAD_SID         NUMBER(10, 0) NOT NULL,
	SUBMISSION_DTM			DATE
);

-- Alter tables

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
@..\sheet_body
@..\csr_app_body

@update_tail

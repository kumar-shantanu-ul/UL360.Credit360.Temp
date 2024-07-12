-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TT_UPDATE_ISSUES_ERROR (
	ISSUE_ID				NUMBER NOT NULL,
	MESSAGE					VARCHAR2(4000) NOT NULL
) ON COMMIT DELETE ROWS;
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
@../issue_pkg
@../issue_body

@update_tail

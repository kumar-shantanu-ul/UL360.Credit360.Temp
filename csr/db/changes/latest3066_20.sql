-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- fix stupid data
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE csr.pct_ownership
	   SET start_dtm = add_months(end_dtm, -12)
	 WHERE start_dtm = TO_DATE('01/01/0016', 'DD/MM/RRRR');
END;
/

-- update constraint to stop stupid data in the future
ALTER TABLE csr.pct_ownership DROP CONSTRAINT ck_pct_ownership_dates;
ALTER TABLE csr.pct_ownership ADD CONSTRAINT ck_pct_ownership_dates CHECK
(start_dtm = TRUNC(start_dtm, 'MON') AND start_dtm >= TO_DATE('01/01/1900', 'DD/MM/YYYY') AND (end_dtm IS NULL OR (end_dtm = TRUNC(end_dtm, 'MON') AND end_dtm >= TO_DATE('01/01/1900', 'DD/MM/YYYY') AND end_dtm > start_dtm)));

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_body

@update_tail

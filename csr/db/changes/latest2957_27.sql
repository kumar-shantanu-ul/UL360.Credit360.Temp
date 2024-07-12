-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=27
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

UPDATE csr.region r
   SET acquisition_dtm = NULL
 WHERE EXISTS (
	SELECT NULL 
	  FROM csr.est_meter
	 WHERE first_bill_dtm < TO_DATE('01-01-1900', 'DD-MM-YYYY')
	   AND region_sid = r.region_sid);
	

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_body

@update_tail

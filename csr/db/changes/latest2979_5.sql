-- Please update version.sql too -- this keeps clean builds in sync
define version=2979
define minor_version=5
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

BEGIN
	UPDATE chain.higg_question
	   SET measure_divisibility = 1 /*csr.csr_data_pkg.DIVISIBILITY_DIVISIBLE*/
	 WHERE higg_question_id IN (1136, 1138, 1224, 1445, 1541, 1726, 1729, 1732);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chain/higg_setup_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=3304
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- this will update the container class for the following sites on live from AspenApp to CSRApp
-- jlp.flagcsr.co.uk - status unknown
-- boots.credit360.com - believe left
-- starbucks.credit360.com- believe left
-- zap-mcdonalds.credit360.com- believe left
-- oldmutual.credit360.com - live client
-- ica.credit360.com - live client
-- www2.credit360.com - test site?
-- sky.credit360.com - live client
-- test.credit360.com - test site?
-- ing-historic.credit360.com - status unknown
-- cairn.credit360.com - live client
-- quilter.credit360.com - live client

UPDATE security.securable_object 
   SET class_id = (
		SELECT class_id 
		  FROM security.securable_object_class 
		 WHERE class_name = 'CSRApp') 
 WHERE sid_id IN (
203969,
63132193,
638204,
713533,
2871935,
2043314,
1945714,
1846924,
1518185,
1542409,
1288503,
1223164
)
   AND class_id = (
		SELECT class_id 
		  FROM security.securable_object_class 
		 WHERE class_name = 'AspenApp');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

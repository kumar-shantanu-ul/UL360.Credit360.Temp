-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=10
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
INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article)
VALUES (33, 'Reset permit workflows', 'Resets the permit, permit application and permit condition workflows back to the default. Can be used to get the latest updates made to the default workflow','ResyncDefaultPermitFlows', 'W3092');

UPDATE csr.util_script
   SET wiki_article ='W3093'
 WHERE util_script_id = 30;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail

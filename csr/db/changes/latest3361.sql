-- Please update version.sql too -- this keeps clean builds in sync
define version=3361
define minor_version=0
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

delete from cms.doc_template where app_sid not in (select sid_id from security.securable_object);
delete from aspen2.translated where application_sid not in (select sid_id from security.securable_object);
delete from aspen2.translation where application_sid not in (select sid_id from security.securable_object);
delete from aspen2.translation_set_include where application_sid not in (select sid_id from security.securable_object);
delete from aspen2.translation_set_include where to_application_sid not in (select sid_id from security.securable_object);
delete from aspen2.translation_set where application_sid not in (select sid_id from security.securable_object);
delete from aspen2.translation_application where application_sid not in (select sid_id from security.securable_object);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_app_body
@../../../aspen2/db/tr_body



@update_tail

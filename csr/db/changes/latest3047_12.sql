-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=12
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
begin
	delete from security.permission_mapping where parent_class_id in (
		select class_id from security.securable_object_class where lower(class_name) in ('mdcomment', 'aspenredirect'));
	delete from security.permission_mapping where child_class_id in (
		select class_id from security.securable_object_class where lower(class_name) in ('mdcomment', 'aspenredirect'));
	delete from security.permission_name where class_id in (
		select class_id from security.securable_object_class where lower(class_name) in ('mdcomment', 'aspenredirect'));
	delete from security.securable_object_class where class_id in
		(select class_id from security.securable_object_class where lower(class_name) in ('mdcomment', 'aspenredirect'));
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
drop package aspen2.aspenredirect_pkg;

@update_tail

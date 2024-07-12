define version=136
@update_header

-- add login-autocomplete attributes for old children of AspenApp
insert into security.attributes (class_id, attribute_id, name, flags)
	select class_id, security.attribute_id_seq.nextval, 'login-autocomplete', 0
	  from security.securable_object_class
	 where parent_class_id = (select class_id from security.securable_object_class where lower(class_name)='aspenapp') and
	 	   class_id not in (select class_id from security.attributes where lower(name)='login-autocomplete');

@update_tail

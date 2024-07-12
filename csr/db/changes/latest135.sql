define version=135
@update_header

-- delete old use-ssl-for-all-requests attribute
declare
	v_class_id		security.securable_object_class.class_id%type;
	v_attribute_id	security.attributes.attribute_id%type;
	v_la_attribute	security.attributes.attribute_id%type;
	v_rbs_sid		security.securable_object.sid_id%type;
	v_apps_sid		security.securable_object.sid_id%type;
begin
	select class_id
	  into v_class_id
	  from security.securable_object_class
	 where lower(class_name) = 'csrdata';
	  
	begin
	select attribute_id
	  into v_attribute_id
	  from security.attributes
	 where class_id = v_class_id and lower(name) = 'use-ssl-for-all-requests';
	delete
	  from security.securable_object_attributes
	 where attribute_id = v_attribute_id;
	delete
	  from security.attributes
	 where attribute_id = v_attribute_id;
	exception when no_data_found then null; end;
	
	select class_id
	  into v_class_id
	  from security.securable_object_class
	 where lower(class_name) = 'aspenapp';

	insert into security.attributes
		(class_id, attribute_id, name, flags)
	values
		(v_class_id, security.attribute_id_seq.nextval, 'login-autocomplete', 0)
	returning attribute_id into v_la_attribute;
	
	select sid_id
	  into v_apps_sid
	  from security.securable_object 
	 where lower(name) = 'applications' and parent_sid_id = (
	 		select sid_id
	 		  from security.securable_object 
	 		 where parent_sid_id = 0 and lower(name) = 'aspen');
	 		 
	insert into security.securable_object_attributes (sid_id, attribute_id, number_value)
		select sid_id, v_la_attribute, 0
		  from security.securable_object 
		 where parent_sid_id = v_apps_sid and
		 	   lower(name) in ('rbs.credit360.com', 'rbsenv.credit360.com', 'test.rbs.credit360.com');
end;
/

@update_tail

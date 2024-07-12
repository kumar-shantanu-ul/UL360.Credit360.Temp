-- Please update version.sql too -- this keeps clean builds in sync
define version=2104
@update_header


CREATE OR REPLACE PACKAGE csr.section_search_pkg
AS
END;
/

GRANT EXECUTE ON csr.section_search_pkg TO web_user;

DECLARE
	v_class_id	NUMBER(10);
	v_cnt 		number;
BEGIN
	security.user_pkg.logonadmin;
	v_class_id := security.class_pkg.GetClassId('CSRSectionRoot');

	select count(*)
	  into v_cnt
	  from security.permission_name
	 where class_id = v_class_id
	   and permission_name = 'Edit section module';
	if v_cnt = 0 then
		security.class_pkg.AddPermission(
			in_act_id			=> SYS_CONTEXT('security', 'act'),
			in_class_id			=> v_class_id,
			in_permission		=> 262144, --csr.csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE,
			in_permission_name	=> 'Edit section module');
	end if; 

	select count(*)
	  into v_cnt
	  from security.permission_mapping
	 where parent_class_id = security.security_pkg.SO_CONTAINER
	   and parent_permission = security.security_pkg.PERMISSION_ADD_CONTENTS
	   and child_class_id = v_class_id
	   and child_permission = 262144;
	if v_cnt = 0 then
		security.class_pkg.CreateMapping(
			in_act_id				=> SYS_CONTEXT('security', 'act'),
			in_parent_class_id		=> security.security_pkg.SO_CONTAINER,
			in_parent_permission	=> security.security_pkg.PERMISSION_ADD_CONTENTS,
			in_child_class_id		=> v_class_id,
			in_child_permission		=> 262144 --csr.csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE
		);
	end if;
END;
/

@../csr_data_pkg
@../section_pkg
@../section_search_pkg

@../csr_data_body
@../section_body
@../section_search_body
@../section_root_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=819
@update_header

update csr.help_image set sha1=dbms_crypto.hash(data,3);

@../stored_calc_datasource_body
@../help_image_pkg
@../help_image_body
@../fileupload_body

@update_tail
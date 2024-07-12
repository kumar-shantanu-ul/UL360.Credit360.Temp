-- Please update version.sql too -- this keeps clean builds in sync
define version=352
@update_header

update customer set region_info_xml_fields = replace(region_info_xml_fields, '<field ', '<field hide-on-form="1" ');

@../delegation_body

@update_tail

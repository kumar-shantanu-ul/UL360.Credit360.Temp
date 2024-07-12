-- Please update version.sql too -- this keeps clean builds in sync
define version=2558
@update_header

@..\..\..\aspen2\cms\db\calc_xml_body

@update_tail
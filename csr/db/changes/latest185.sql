-- Please update version.sql too -- this keeps clean builds in sync
define version=185
@update_header

update pending_element_type set is_number =1, is_string=1 where element_Type in (12,13);

@update_tail

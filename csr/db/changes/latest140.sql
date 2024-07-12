-- Please update version.sql too -- this keeps clean builds in sync
define version=140
@update_header

drop table temp_tree;
create global temporary table temp_tree (
	sid_id 			number(10),
	parent_sid_id	number(10),
	dacl_id			number(10),
	class_id		number(10),
	name			varchar2(255),
	flags			number(10),
	owner			number(10),
	so_level		number(10),
	is_leaf			number(1),
	path			varchar2(4000)
) on commit delete rows;

@..\doc_body
@..\..\..\..\aspen2\tools\recompile_packages

@update_tail

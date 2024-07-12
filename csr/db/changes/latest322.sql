-- Please update version.sql too -- this keeps clean builds in sync
define version=322
@update_header

CREATE GLOBAL TEMPORARY TABLE region_list_2 (
	app_sid 	NUMBER(10), 
	region_sid 	NUMBER(10), 
	path 		VARCHAR2(4000),
	is_leaf 	NUMBER(1)
) ON COMMIT DELETE ROWS;

@..\val_datasource_body

@update_tail
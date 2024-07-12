-- Please update version.sql too -- this keeps clean builds in sync
define version=2710
@update_header

CREATE GLOBAL TEMPORARY TABLE CMS.TT_FILTERED_ID
( 
	ID							NUMBER(10) NOT NULL
) 
ON COMMIT DELETE ROWS; 

@..\..\..\aspen2\cms\db\filter_body

@update_tail

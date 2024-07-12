-- Please update version.sql too -- this keeps clean builds in sync
define version=812
@update_header

CREATE GLOBAL TEMPORARY TABLE CSR.temp_delegation_for_region
(
	sheet_id						number(10),
	delegation_sid					number(10),
	parent_sid						number(10),
	name							varchar2(255),
	start_dtm						date,
	end_dtm							date,
	interval						varchar(32),
	last_action_id					number(10),
	submission_dtm					date,
	status							number(10),
	sheet_action_description		varchar2(255),
	editing_url						varchar2(255),
	root_delegation_sid				number(10),
	last_action_colour				char(1)
) ON COMMIT DELETE ROWS;

@update_tail
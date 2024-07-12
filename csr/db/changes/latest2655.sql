--Please update version.sql too -- this keeps clean builds in sync
define version=2655
@update_header

drop table CSR.temp_delegation_for_region;

CREATE GLOBAL TEMPORARY TABLE CSR.temp_delegation_for_region
(
	sheet_id						number(10),
	delegation_sid					number(10),
	parent_sid						number(10),
	name							varchar2(255),
	start_dtm						date,
	end_dtm							date,
	period_set_id					number(10),
	period_interval_id				number(10),
	delegation_start_dtm			date,
	delegation_end_dtm				date,
	last_action_id					number(10),
	submission_dtm					date,
	status							number(10),
	sheet_action_description		varchar2(255),
	editing_url						varchar2(255),
	root_delegation_sid				number(10),
	last_action_colour				char(1)
) ON COMMIT DELETE ROWS;

@../delegation_body

@update_tail

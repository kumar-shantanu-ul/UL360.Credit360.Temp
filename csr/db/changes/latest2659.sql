--Please update version.sql too -- this keeps clean builds in sync
define version=2659
@update_header

DROP TABLE CSR.temp_delegation_detail;
CREATE GLOBAL TEMPORARY TABLE CSR.temp_delegation_detail
(
	sheet_id						number(10),
	parent_sheet_id					number(10),
	delegation_sid					number(10),
	parent_delegation_sid			number(10),
	is_visible						number(1),
	name							varchar2(255),
	start_dtm						date,
	end_dtm							date,
	period_set_id					number(10),
	period_interval_id				number(10),
	delegation_start_dtm			date,
	delegation_end_dtm				date,
	submission_dtm					date,
	status							number(10),
	sheet_action_description		varchar2(255),
	sheet_action_downstream			varchar2(255),
	fully_delegated					number(1),
	editing_url						varchar2(255),
	last_action_id					number(10),
	is_top_level					number(1),
	approve_dtm						date,
	delegated_by_user				number(1),
	percent_complete				number(10,0)
) ON COMMIT DELETE ROWS;

@../delegation_body

@update_tail

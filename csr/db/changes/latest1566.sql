-- Please update version.sql too -- this keeps clean builds in sync
define version=1566
@update_header

@..\quick_survey_pkg
@..\quick_survey_body

@update_tail

-- Please update version.sql too -- this keeps clean builds in sync
define version=2118
@update_header

@..\quick_survey_pkg.sql
@..\tag_body
@..\issue_body.sql
@..\quick_survey_body.sql

@update_tail

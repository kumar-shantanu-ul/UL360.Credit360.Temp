-- Please update version.sql too -- this keeps clean builds in sync
define version=2112
@update_header

GRANT INSERT ON security.web_resource TO csr;

@..\quick_survey_pkg

@..\quick_survey_body
@..\trash_body

@update_tail

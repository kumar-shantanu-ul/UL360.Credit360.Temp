-- Please update version.sql too -- this keeps clean builds in sync
define version=2517
@update_header

@../quick_survey_pkg
@../folderlib_pkg

@../quick_survey_body
@../folderlib_body

@update_tail
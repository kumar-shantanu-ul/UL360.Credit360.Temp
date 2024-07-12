-- Please update version.sql too -- this keeps clean builds in sync
define version=329
@update_header

alter table quick_survey add (
    QUESTION_XML		 SYS.XMLType
);

@../quick_Survey_pkg
@../quick_Survey_body

@update_tail

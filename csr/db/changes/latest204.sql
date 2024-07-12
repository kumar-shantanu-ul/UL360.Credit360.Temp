-- Please update version.sql too -- this keeps clean builds in sync
define version=204
@update_header


DECLARE
	v_act				security_pkg.T_ACT_ID;
	new_class_id        security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//builtin/administrator', 10000, v_act);
    class_pkg.CreateClass(v_act, null, 'CSROldSurvey', 'csr.old_survey_pkg', NULL, new_class_id);
EXCEPTION
    WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
        new_class_id:=class_pkg.GetClassId('CSROldSurvey');
END;	
/

alter table old_survey add (
    question_xml_path varchar2(255)
);

@..\old_survey_pkg
@..\old_survey_body
grant execute on old_survey_pkg to security;


@update_tail

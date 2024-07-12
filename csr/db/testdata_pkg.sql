CREATE OR REPLACE PACKAGE CSR.TestData_Pkg AS

FUNCTION ImportSurvey(
	in_xml 							IN XMLTYPE,
	in_name							IN VARCHAR2,
	in_label						IN VARCHAR2
) RETURN security.security_pkg.T_SID_ID;

/**
 * Add test data to the current site
 *
 * @param 	in_cms_user						Name of the schema for the CMS user
 * @param 	in_is_multiple_survey_audits	0 => create standard audits; 1 => create multiple survey audits
 */
PROCEDURE AddTestData(
	in_cms_user						IN	VARCHAR2,
	in_is_multiple_survey_audits	IN	NUMBER
);

END TestData_Pkg;
/

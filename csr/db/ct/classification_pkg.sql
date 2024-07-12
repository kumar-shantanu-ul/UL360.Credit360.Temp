CREATE OR REPLACE PACKAGE ct.classification_pkg AS

STEM_METHOD_NONE_ALL				CONSTANT NUMBER(10) := 4;
KEYWRD_SRC_CORE_ATTR				CONSTANT NUMBER(10) := 6;

MATCH_METH_EXACT					CONSTANT NUMBER(10) := 1;
MATCH_METH_EDIT 					CONSTANT NUMBER(10) := 2;
--http://docs.oracle.com/cd/E14072_01/appdev.112/e10577/u_match.htm
MATCH_METH_JAROWINKLER 				CONSTANT NUMBER(10) := 3;
--http://docs.oracle.com/cd/E14072_01/appdev.112/e10577/u_match.htm

PROCEDURE GetOriginalTreeText(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBricks(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);
/*PROCEDURE GetKeywordWeighting(
	in_ps_attribute_source_id		IN ps_attribute.ps_attribute_source_id%TYPE,
	in_ps_stem_method_id			IN ps_attribute.ps_stem_method_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);*/
PROCEDURE GetBrickMatchesForTerm(
	in_word							IN ps_attribute.attribute%TYPE,
	in_ps_attribute_source_id		IN ps_attribute.ps_attribute_source_id%TYPE,
	in_ps_stem_method_id			IN ps_attribute.ps_stem_method_id%TYPE,
	in_match_method_id				IN NUMBER,
	in_threshold					IN NUMBER,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);


END classification_pkg;
/

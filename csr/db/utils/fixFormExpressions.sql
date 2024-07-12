/*
* This script is a workaround for an issue with form expressions which causes
* indicators to be validated even when they are hidden.
*
* The problem is caused when an expression has a single path node as follows:
*
* <expr>
*   <path sid="123456" description="Indicator description" />
* </expr>
*
* The client-side JavaScript will evaluate this as true if the referenced indicator
* has a value of 1, which is assumed to be Yes for a Yes/No indicator.
*
* The server-side code will evaluate this as true of the referenced indicator has
* any value - including 2 (for No) and so will perform validation in all cases.
*
* This script changes expressions in this form to the following unambiguous version:
*
* <expr>
*   <equal>
*     <left> 
*       <path sid="123456" description="Indicator description" />
*     </left>
*     <right>
*       <literal>1</literal>
*     </right>
*   </equal>
* </expr>
*
* A fix is required to ensure that client and server evaluate expressions the same way. It
* may also be desirable not to allow expressions of the first form, as the meaning of testing
* an indicator for true is not always clear.
*/

DECLARE
	v_xsl		XMLTYPE := XMLTYPE('<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/>
	<xsl:template match="expr">
		<expr>
			<equal>
				<left>
					<xsl:copy-of select="path"/>
				</left>
				<right>
					<literal>1</literal>
				</right>
			</equal>
		</expr>
	</xsl:template>
</xsl:stylesheet>
');
	v_result	XMLTYPE;
BEGIN
	FOR r IN (
		SELECT fe.form_expr_id, fe.expr
		  FROM form_expr fe, TABLE(XMLSEQUENCE(EXTRACT(fe.expr, '//expr/path')))
	) LOOP
		v_result := r.expr.transform(v_xsl);
		DBMS_OUTPUT.PUT_LINE('Updating form_expr_id: ' || r.form_expr_id || ' from ' || r.expr.getCLOBVal() || ' to ' || v_result.getCLOBVal());
		UPDATE form_expr
		   SET expr = v_result
		 WHERE form_expr_id = r.form_expr_id;
	END LOOP;
END;
/

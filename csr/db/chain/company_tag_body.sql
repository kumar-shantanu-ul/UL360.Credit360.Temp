CREATE OR REPLACE PACKAGE BODY CHAIN.company_tag_pkg
IS

PROCEDURE GetTagGroup (
	in_tag_group_id			IN  chain.company_tag_group.tag_group_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, ctg.applies_to_component, ctg.applies_to_purchase
		  FROM company_tag_group ctg
		  JOIN csr.v$tag_group tg
		    ON ctg.tag_group_id = tg.tag_group_id
		 WHERE tg.app_sid = security_pkg.GetApp
		   AND company_sid = SYS_CONTEXT('COMPANY', 'CHAIN_COMPANY')
		   AND tg.tag_group_id = NVL(in_tag_group_id, tg.tag_group_id);
END;

PROCEDURE GetTagGroups (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetTagGroup(null, out_cur);
END;

PROCEDURE SetTagGroup (
	in_tag_group_id			IN  chain.company_tag_group.tag_group_id%TYPE,
	in_applies_to_component	IN  chain.company_tag_group.applies_to_component%TYPE,
	in_applies_to_purchase	IN  chain.company_tag_group.applies_to_purchase%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	BEGIN
		INSERT INTO company_tag_group (app_sid, company_sid, tag_group_id, applies_to_component, applies_to_purchase)
			 VALUES (security_pkg.GetApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_tag_group_id, in_applies_to_component, in_applies_to_purchase);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE company_tag_group
			   SET applies_to_component = in_applies_to_component,
			       applies_to_purchase = in_applies_to_purchase
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND tag_group_id = in_tag_group_id;
	END;
END;

PROCEDURE GetCompanyTags (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT company_sid, company_name, source, tag_group_name, tag, tag_group_id, tag_id, tag_lookup_key
		  FROM v$company_tag
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid;
END;

END company_tag_pkg;
/

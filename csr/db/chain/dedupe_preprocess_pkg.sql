CREATE OR REPLACE PACKAGE CHAIN.dedupe_preprocess_pkg
IS

PROCEDURE PreprocessCompany(
	in_company_sid 		company.company_sid%TYPE
);

PROCEDURE PreprocessAllRulesForCompanies;

PROCEDURE PreprocessAllRulesForSubst;

PROCEDURE ApplyRulesToCompanyRow(
	in_out_company_row		IN OUT T_DEDUPE_COMPANY_ROW
);

PROCEDURE RunPreprocessJob;

FUNCTION GetDomainNameFromEmail(
	in_email		IN company.email%TYPE
) RETURN company.email%TYPE DETERMINISTIC;

FUNCTION ApplyBlkLstDomain(
	in_domain		IN company.email%TYPE
) RETURN company.email%TYPE;

END dedupe_preprocess_pkg;
/


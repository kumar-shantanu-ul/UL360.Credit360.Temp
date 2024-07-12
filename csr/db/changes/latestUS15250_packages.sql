CREATE OR REPLACE PACKAGE chain.latestUS15250_package IS

FUNCTION NormaliseCompanyName (
	in_company_name			IN  company.name%TYPE
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC;

FUNCTION GenerateCompanySignature(
	in_normalised_name		company.name%TYPE,
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL,
	in_parent_sid			security_pkg.T_SID_ID DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC;

END;
/

CREATE OR REPLACE PACKAGE BODY chain.latestUS15250_package IS

FUNCTION NormaliseCompanyName (
	in_company_name			IN  company.name%TYPE
) RETURN security_pkg.T_SO_NAME
DETERMINISTIC
AS
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')), '/', '\');
END;

FUNCTION GenerateSignaturePrefix(
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC
AS
	v_signature_prefix			company.signature%TYPE;
BEGIN
	SELECT LISTAGG(
		CASE  
		WHEN val = 'COUNTRY' THEN 'co:' || in_country
		WHEN val = 'COMPANY_TYPE' THEN 'ct:' || in_company_type_id
		WHEN val = 'CITY' AND in_city IS NOT NULL THEN 'ci:' || in_city
		WHEN val = 'STATE' AND in_state IS NOT NULL THEN 'st:' || in_state
		WHEN val = 'SECTOR' AND in_sector_id IS NOT NULL THEN 'sct:' || in_sector_id
		END, '|') 
		WITHIN GROUP (ORDER BY lvl)
	  INTO v_signature_prefix 
	  FROM (
  		SELECT LTRIM(RTRIM(UPPER(REGEXP_SUBSTR(str, '{[^}]+}', 1, level, 'i')), '}'), '{') AS val, level lvl
		  FROM (SELECT in_layout AS str FROM dual)
	   CONNECT BY level <= LENGTH(REGEXP_REPLACE(str, '{[^}]+}'))+1
		);

	RETURN v_signature_prefix;
END;

FUNCTION GenerateCompanySignature(
	in_normalised_name		company.name%TYPE,
	in_country				company.country_code%TYPE DEFAULT NULL,
	in_company_type_id		company.company_type_id%TYPE DEFAULT NULL,
	in_city					company.city%TYPE DEFAULT NULL,	
	in_state				company.state%TYPE DEFAULT NULL,
	in_sector_id			company.sector_id%TYPE DEFAULT NULL,
	in_layout				company_type.default_region_layout%TYPE DEFAULT NULL,
	in_parent_sid			security_pkg.T_SID_ID DEFAULT NULL
) RETURN company.signature%TYPE
DETERMINISTIC
AS
	v_signature			company.signature%TYPE;
	v_signature_prefix	company.signature%TYPE;
BEGIN
	IF in_parent_sid IS NOT NULL THEN
		RETURN LOWER('parent:' || in_parent_sid  || '|na:' || in_normalised_name);
	END IF;

	v_signature_prefix := GenerateSignaturePrefix(
		in_country			=> in_country,
		in_company_type_id	=> in_company_type_id,
		in_city				=> in_city,
		in_state			=> in_state,
		in_sector_id		=> in_sector_id,
		in_layout			=> in_layout
	);

	RETURN LOWER(v_signature_prefix || '|na:' || in_normalised_name);
END;

END;
/
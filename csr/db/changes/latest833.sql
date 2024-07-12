-- Please update version.sql too -- this keeps clean builds in sync
define version=833
@update_header

DECLARE
	TYPE T_VC IS TABLE OF VARCHAR2(255) INDEX BY BINARY_INTEGER;
	v_names	T_VC;
	v_codes	T_VC;
BEGIN
	v_names(1) := 'D'||UNISTR('\FFFD')||'nemark';
	v_codes(1) := 'dk';
	v_names(2) := 'Gro'||UNISTR('\FFFD')||'britainien';
	v_codes(2) := 'gb';
	v_names(3) := 'Littauen';
	v_codes(3) := 'lt';
	v_names(4) := ''||UNISTR('\FFFD')||'sterreich';
	v_codes(4) := 'at';
	v_names(5) := 'Rum'||UNISTR('\FFFD')||'nien';
	v_codes(5) := 'ro';
	v_names(6) := 'Tschechien';
	v_codes(6) := 'cz';
	v_names(7) := 'T'||UNISTR('\FFFD')||'rkei';
	v_codes(7) := 'tr';
	v_names(8) := 'Wei'||UNISTR('\FFFD')||'ru'||UNISTR('\FFFD')||'land';
	v_codes(8) := 'by';

	FOR i IN v_names.FIRST..v_names.LAST
	LOOP
		BEGIN
			INSERT INTO postcode.country_alias(alias, country, lang) VALUES (v_names(i), v_codes(i), 'de');
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

@update_tail
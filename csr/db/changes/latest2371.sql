-- Please update version.sql too -- this keeps clean builds in sync
define version=2371
@update_header

BEGIN
	/* Seems to be missing compared to GeoIP city/timezone mappings in aspen2 */
	INSERT INTO ASPEN2.TIMEZONES_MAP_CLDR_TO_WIN(CLDR,WIN)VALUES('America/Buenos Aires', 'Argentina Standard Time');
END;
/

@update_tail

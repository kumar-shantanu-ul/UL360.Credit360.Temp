define version=54
@update_header

DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version WHERE PART='rap4';
	IF v_version > 0 AND v_version < 15 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= YOU NEED TO BRING THE "rap4" SUBFOLDER UP TO DATE FIRST =======');
	END IF;
	IF v_version = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, '========= PLEASE RUN Rap4ReleaseScripts\prerelease.sql AND THEN Rap4ReleaseScripts\release.sql =======');
	END IF;
END;
/

@update_tail


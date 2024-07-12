PROMPT Please enter a regular expression to zap matching sites.
PROMPT eg, ^(apitest|uitest|ujtest)
PROMPT would match any site which starts with "apitest", "uitest" or "ujtest"

DEFINE expr=&&1
DEFINE max_minutes=&&2;
DEFINE rename_on_failure=&&3;

WHENEVER oserror EXIT FAILURE
WHENEVER sqlerror EXIT FAILURE
SET ECHO ON

SET SERVEROUTPUT ON

DECLARE
	v_app_sid				csr.customer.app_sid%TYPE;
	v_total_count			NUMBER;
	v_error_count			NUMBER := 0;
	v_success_count			NUMBER := 0;
	v_exit_after			DATE := SYSDATE+(1/1440*NVL(&&max_minutes,60));
	FUNCTION IsTimeToExit
	RETURN NUMBER
	AS
	BEGIN
		IF SYSDATE > v_exit_after THEN
			dbms_output.put_line ( 'Exiting, as time expired' );
			RETURN 1;
		END IF;
		RETURN 0;
	END;
	
	FUNCTION SiteHasRecentActivity(
		in_host			csr.customer.host%TYPE
	)
	RETURN NUMBER
	AS
		v_max_audit_dtm			DATE;
	BEGIN
		SELECT MAX(audit_date)
		  INTO v_max_audit_dtm
		  FROM csr.audit_log
		 WHERE app_sid = v_app_sid;
		IF v_max_audit_dtm > SYSDATE-1 THEN
			dbms_output.put_line ('Skipping '||in_host||' because it has recent activity.');
			RETURN 1;
		END IF;
		RETURN 0;
	END;
	
	PROCEDURE DoRenameIfRequired(
		in_rename_on_failure	NUMBER,
		in_current_host			csr.customer.host%TYPE
	)
	AS
		v_new_site_name			csr.customer.host%TYPE;
	BEGIN
		IF in_rename_on_failure > 0 THEN
			BEGIN
				v_new_site_name := 'zapfailure-'||in_current_host;
				csr.site_name_management_pkg.RenameSite(
					in_to_host => v_new_site_name
				);
				COMMIT;
				dbms_output.put_line ('Renamed '||in_current_host||' to '||v_new_site_name);
			EXCEPTION
				WHEN others THEN
					dbms_output.put_line ('Renaming '||in_current_host||' to '||v_new_site_name||' failed. Stack follows.');
					dbms_output.put_line ( DBMS_UTILITY.FORMAT_ERROR_STACK() );
					dbms_output.put_line ( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() );
					ROLLBACK;
			END;
		END IF;
	END;
BEGIN

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM csr.customer 
	 WHERE REGEXP_LIKE (host, '&&expr');

	dbms_output.put_line ('Found '||v_total_count||' sites to zap...');
		
		
	FOR r IN (
		SELECT host 
		  FROM csr.customer 
		 WHERE REGEXP_LIKE (host, '&&expr')
	) LOOP
		BEGIN
			-- Check to see if we've run out of time
			IF IsTimeToExit() = 1 THEN
				EXIT;
			END IF;
			
			security.user_pkg.logonadmin(r.host);
			v_app_sid := SYS_CONTEXT('SECURITY', 'APP');

			-- Check to ensure the site hasn't been used recently. This stops it
			-- from deleting sites which might be running in test suits right now.
			IF SiteHasRecentActivity(in_host => r.host) = 1 THEN
				CONTINUE;
			END IF;

			DELETE FROM csr.delegation_grid
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

			cms.tab_pkg.DropAllTables();

			DELETE FROM cms.app_schema 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

			DELETE FROM cms.tag
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

			csr.csr_app_pkg.DeleteApp(
				in_reduce_contention => 1,
				in_debug_log_deletes => 1,
				in_logoff_before_delete_so => 1
			);
			
			v_total_count := v_total_count - 1;
			IF (MOD(v_total_count, 10) = 0) THEN
				dbms_output.put_line (v_total_count || ' sites left to delete');
			END IF;
			v_success_count := v_success_count + 1;
			COMMIT;
		EXCEPTION WHEN OTHERS THEN
			dbms_output.put_line ('Error zapping ' || r.host);
			dbms_output.put_line ( DBMS_UTILITY.FORMAT_ERROR_STACK() );
			dbms_output.put_line ( DBMS_UTILITY.FORMAT_ERROR_BACKTRACE() );
			v_error_count := v_error_count + 1;
			ROLLBACK;
			DoRenameIfRequired(
				in_rename_on_failure => &&rename_on_failure,
				in_current_host => r.host
			);
		END;
	END LOOP;
	security.user_pkg.logonadmin();
	
	dbms_output.put_line ('Zapped '||v_success_count||' sites.');
	IF v_error_count > 0 THEN
		raise_application_error(-20001, v_error_count || ' sites failed to zap.');
	END IF;
END;
/
exit;
/


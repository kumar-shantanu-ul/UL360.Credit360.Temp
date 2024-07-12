-- Changes the names and descriptions of delegations created by a plan to
-- reflect the template.
ACCEPT HOST CHAR PROMPT 'Host (e.g. credit-agricole.credit360.com): '
SET SERVEROUTPUT ON
DECLARE
	master_deleg_sid NUMBER(10);
	master_deleg_name VARCHAR2(1023 BYTE);
	master_deleg_desc VARCHAR2(1023 BYTE);
BEGIN
	security.user_pkg.logonAdmin('&&host');

	-- For each delegation created from a template
	FOR deleg IN (SELECT * FROM csr.delegation 
				   WHERE master_delegation_sid IS NOT NULL)
	LOOP	
		-- Get the name from the master delegation
		SELECT delegation_sid, name 
		  INTO master_deleg_sid, master_deleg_name
		  FROM csr.delegation 
		 WHERE delegation_sid = deleg.master_delegation_sid;

		-- Fix the delegation name
		IF deleg.name <> master_deleg_name THEN
			dbms_output.put_line(
				'[' || deleg.delegation_sid || '] "' || deleg.name || '" -> "' || master_deleg_name || '"');

			UPDATE csr.delegation
			   SET name = master_deleg_name
			 WHERE delegation_sid = deleg.delegation_sid;
		END IF;

		-- For each description translation for the current delegation 
		FOR deleg_description IN (SELECT * FROM csr.delegation_description
								   WHERE delegation_sid = deleg.delegation_sid)
		LOOP 
			SELECT description
			  INTO master_deleg_desc
			  FROM csr.delegation_description
			 WHERE lang = deleg_description.lang
			   AND delegation_sid = deleg.master_delegation_sid;

			IF deleg_description.description <> master_deleg_desc THEN
				dbms_output.put_line(
					'[' || deleg_description.delegation_sid || '|' || deleg_description.lang || '] "' ||
					deleg_description.description || '" -> "' || master_deleg_desc || '"');

				UPDATE csr.delegation_description
				   SET description = master_deleg_desc
				 WHERE delegation_sid = deleg_description.delegation_sid
				   AND lang = deleg_description.lang;
			END IF;
		END LOOP;
	END LOOP;
END;
/

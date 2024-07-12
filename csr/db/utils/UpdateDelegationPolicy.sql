PROMPT Enter host and delegation policy message
PROMPT If you leave the message blank, all messages will be deleted.
DECLARE
BEGIN

  security.user_pkg.logonadmin('&&1');

  FOR r IN (
    SELECT app_sid, delegation_sid FROM csr.delegation
  )
  LOOP
    BEGIN 	
      csr.delegation_pkg.UpdatePolicy(r.delegation_sid, '&&2');
    END;
  END LOOP;
END;
/

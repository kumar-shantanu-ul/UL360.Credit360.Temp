--https://essent.credit360.com/csr/site/help/viewHelp.acds?popup=1
--https://essent.credit360.com/csr/site/help/editHelp.acds

PROMPT Enter the host name, preferably with an upper case initial letter, e.g. Essent
declare
  v_act				security_pkg.T_ACT_ID;
  v_app_sid			security_pkg.T_SID_ID;
  v_lang_id       	help_lang.help_lang_id%TYPE;
  v_host			VARCHAR2(255) := '&&1';
begin
  user_pkg.LogonAdmin(v_host);
  v_app_sid := security_pkg.getapp;
  -- bases this on English (British) which is help_lang_id 1
  help_pkg.AddLanguage(v_act, 1, 'English ('||v_host||')', v_lang_id);
  UPDATE help_lang 
     SET short_name=LOWER(v_host) 
   WHERE help_lang_id = v_lang_id;
  UPDATE customer_help_lang 
     SET help_lang_id = v_lang_id 
   WHERE app_sid = v_app_sid
     AND is_default = 1;
end;
/

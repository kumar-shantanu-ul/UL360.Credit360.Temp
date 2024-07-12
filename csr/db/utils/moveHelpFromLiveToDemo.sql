-- export from live
--*************************************************
exp csr/csr tables=(HELP_FILE,HELP_LANG,HELP_TOPIC,HELP_TOPIC_TEXT,HELP_TOPIC_FILE) file=help.dmp
--*************************************************


-- drop stuff on the system you want to connect to
alter table CUSTOMER_HELP_LANG drop CONSTRAINT RefHELP_LANG412;
drop table HELP_FILE  purge;
drop table HELP_LANG  purge;
drop table HELP_TOPIC purge;
drop table HELP_TOPIC_TEXT purge;
drop table HELP_TOPIC_FILE purge;


-- do the import
--*************************************************
imp csr/csr@aspen file=help.dmp tables=(HELP_FILE,HELP_LANG,HELP_TOPIC,HELP_TOPIC_TEXT,HELP_TOPIC_FILE)

--*************************************************


-- fix up parent keys not found warnings
declare
	v_act				security_pkg.T_ACT_ID;
	v_sid				security_pkg.T_SID_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/mark', 10000, v_act);
	v_sid := securableobject_pkg.GetSIDFromPath(v_act, 0, '//csr/users/mark');
	update HELP_FILE set uploaded_by_sid = v_sid;
	update HELP_TOPIC_TEXT set LAST_UPDATED_BY_SID = v_sid;
	commit;
end;
/

ALTER TABLE HELP_TOPIC DISABLE CONSTRAINT RefHELP_TOPIC414;
ALTER TABLE HELP_TOPIC_TEXT DISABLE CONSTRAINT RefHELP_TOPIC416;
ALTER TABLE HELP_TOPIC_FILE DISABLE CONSTRAINT RefHELP_TOPIC_TEXT457;
ALTER TABLE HELP_TOPIC_FILE DISABLE CONSTRAINT REFHELP_TOPIC439;

-- create all the securable objects
declare
	v_act				security_pkg.T_ACT_ID;
	v_root				security_pkg.T_SID_ID;
	v_class_id			security_pkg.T_CLASS_ID;
	v_sid				security_pkg.T_SID_ID;
begin
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/mark', 10000, v_act);
	v_class_id := class_pkg.getClassID('CSRHelpTopic');
	v_root := securableobject_pkg.GetSIDFromPath(v_act, 0,  'csr/Help');
	FOR r IN (
		select help_topic_id, parent_id, lookup_name, '//csr/help'||substr(SYS_CONNECT_BY_PATH(lookup_name,'/'), 0, length(SYS_CONNECT_BY_PATH(lookup_name,'/')) - length(lookup_name) -1) path
		  from csr.help_topic
		 start with parent_id is null
		connect by prior help_topic_id = parent_id 
	)
	LOOP
		securableobject_pkg.createSO(v_act, securableobject_pkg.GetSIDFromPath(v_act, 0, r.path), security_PKG.SO_CONTAINER, r.lookup_name, v_sid);
		-- fix up tables
		UPDATE help_topic 
		   SET help_topic_id = v_sid
		 WHERE help_topic_id = r.help_topic_id;
		UPDATE help_topic 
		   SET parent_id = v_sid
		 WHERE parent_id = r.help_topic_id;
		UPDATE help_topic_file
		   SET help_topic_Id = v_sid
		 WHERE help_topic_Id = r.help_topic_id;
		UPDATE help_topic_text
		   SET help_topic_Id = v_sid
		 WHERE help_topic_Id = r.help_topic_id;
		-- fix up class
		update security.securable_object 
		   SET class_id = v_class_id
		 WHERE sid_id = v_sid;
	END LOOP;
end;
/



-- re-enable constaints
ALTER TABLE HELP_TOPIC ENABLE CONSTRAINT RefHELP_TOPIC414;
ALTER TABLE HELP_TOPIC_TEXT ENABLE CONSTRAINT RefHELP_TOPIC416;
ALTER TABLE HELP_TOPIC_FILE ENABLE CONSTRAINT RefHELP_TOPIC_TEXT457;
ALTER TABLE HELP_TOPIC_FILE ENABLE CONSTRAINT RefHELP_TOPIC439;
ALTER TABLE HELP_FILE ENABLE CONSTRAINT RefCSR_USER421;
ALTER TABLE HELP_TOPIC_TEXT ENABLE CONSTRAINT RefCSR_USER422;

ALTER TABLE CUSTOMER_HELP_LANG ADD CONSTRAINT RefHELP_LANG412 
    FOREIGN KEY (HELP_LANG_ID)
    REFERENCES HELP_LANG(HELP_LANG_ID)
;
/* YOU MUST WARN CLIENTS THAT THIS IS A REALLY BAD IDEA BEFORE DOING THIS!! */
/* Then you must warn them again (in writing!) */
DECLARE
	v_host				varchar2(255) := '&&1';
	v_pwd				varchar2(255);
BEGIN
	user_pkg.LogonAdmin(v_host);
	-- passwords expire after a year
	update security.account_policy 
	    set max_password_age = 365 
	 where sid_id = securableobject_pkg.getsidfrompath(security_pkg.getapp,security_pkg.getapp,'AccountPolicy');
 
    FOR r IN (
        SELECT csr_user_sid, user_name, full_name
          FROM csr_user 
         WHERE --(LOWER(user_name) LIKE 'grupo%' OR LOWER(user_name) LIKE 'u0%')
			--csr_user_sid in (select csr_user_sid from csr_user minus select csr_user_sid from csr_user as of timestamp sysdate -1) -- users added in the past day
           csr_user_sid NOT IN (SELECT csr_user_sid FROM superadmin)
    ) 
    LOOP 
		v_pwd := dbms_random.string('l', 8)||round(dbms_random.value(1000,9999));
		user_pkg.ChangePasswordBySID(security_pkg.getact, v_pwd, r.csr_user_sid);
		-- set last change date to over a year ago to force them to change on login
		update security.user_table 
		    set last_password_change=sysdate-366 
		 where sid_id = r.csr_user_sid;	
        DBMS_OUTPUT.PUT_LINE('Setting password for '||r.full_name||' ('||r.user_name||') = '||v_pwd); 
    END LOOP;
END;
/


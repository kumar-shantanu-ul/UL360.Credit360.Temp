define version=128
@update_header

connect csr/csr@&_CONNECT_IDENTIFIER
grant select,insert on csr.audit_log to chain;
grant select on csr.delegation to chain;
grant select,insert on csr.delegation_user to chain;
grant select on csr.supplier_delegation to chain;
grant insert on csr.link_audit to chain;
connect chain/chain@&_CONNECT_IDENTIFIER

@latest128_pkg

DECLARE
	v_topco_sid	security_pkg.T_SID_ID;
BEGIN
	FOR rc IN (
		SELECT c.app_sid, c.host
		  FROM chain.customer_options co 
			JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE top_company_sid IS NOT NULL
	)
	LOOP
		dbms_output.put_line('fixing '||rc.host);
		user_pkg.logonadmin(rc.host);
		
		SELECT MIN(top_company_sid)
		  INTO v_topco_sid
		  FROM chain.customer_options
		 WHERE app_sid = security_pkg.GetApp;
		--
		FOR r IN (
			SELECT csr_user_sid, user_name
			  FROM csr.v$csr_user
			 WHERE csr_user_sid NOT IN (
				SELECT user_sid FROM chain.chain_user
			 ) AND csr_user_sid NOT IN (	
				SELECT csr_user_sid FROM csr.superadmin
			 )
		)
		LOOP
			dbms_output.put_line('  '||r.user_name);
			INSERT INTO chain.chain_user
				(user_sid, visibility_id, registration_status_id, default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
				VALUES (
					r.csr_user_sid, 2, --chain_pkg.NAMEJOBTITLE, 
					1, --chain_pkg.REGISTERED , 
					v_topco_sid, 
					1, -- chain_pkg.ACTIVE, 
					1
			);
			
			-- make them members of topco
			chain.latest128_pkg.AddUserToCompany(v_topco_sid, r.csr_user_sid);
		END LOOP;
		
		user_pkg.logonadmin;
	END LOOP;
END;
/

drop package latest128_pkg;

connect csr/csr@&_CONNECT_IDENTIFIER

revoke select,insert on csr.audit_log from chain;
revoke select on csr.delegation from chain;
revoke select,insert on csr.delegation_user from chain;
revoke select on csr.supplier_delegation from chain;
revoke insert on csr.link_audit from chain;

@..\..\csr_user_pkg.sql
@..\..\supplier_pkg.sql

@..\..\csr_user_body.sql
@..\..\supplier_body.sql

connect chain/chain@&_CONNECT_IDENTIFIER

@update_tail

set serveroutput on
set feedback 0
@@logoff

declare
	v_count number(10);
	v_host varchar2(100);
	v_like varchar2(100);
begin
	v_like := '&1..%';

	select
		count(*) into v_count
	from
		csr.customer
	where
		lower(host) like lower(v_like)
	;

	if v_count <> 1 then
		v_like := '&1%';

		select
			count(*) into v_count
		from
			csr.customer
		where
			lower(host) like lower(v_like)
		;
	end if;

	if v_count <> 1 then
		v_like := '&1';

		select
			count(*) into v_count
		from
			csr.customer
		where
			to_char(app_sid) like v_like
		;

		if v_count = 1 then
			select
				host into v_like
			from
				csr.customer
			where
				to_char(app_sid) like v_like;
		end if;
	end if;

	if v_count = 0 then
		dbms_output.put_line('No matching hosts found.');
	elsif v_count = 1 then
		select
			host into v_host
		from
			csr.customer
		where
			lower(host) like lower(v_like)
		;

		user_pkg.logonadmin(v_host, 172800);

		dbms_output.put_line('Admin logon for ' || v_host || ' (' || sys_context('security', 'app') || ') completed.');
	else
		dbms_output.put_line('Host name ambiguous.');
	end if;
end;
/

SET TERMOUT OFF
COL READ_FROM_SET NEW_VALUE CONNECT_IDENTIFIER
SELECT LOWER('&_USER') || ':' || (SELECT host FROM csr.customer WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')) || '@' || LOWER('&_CONNECT_IDENTIFIER') READ_FROM_SET FROM DUAL;
SET TERMOUT ON
SET SQLPROMPT "&&CONNECT_IDENTIFIER> "

set feedback 1
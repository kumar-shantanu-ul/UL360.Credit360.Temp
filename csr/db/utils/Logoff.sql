declare
	v_count NUMBER;
begin
	select count(*) into v_count from dual where sys_context('SECURITY', 'ACT') is null;

	if v_count = 0 then
		user_pkg.logoff(sys_context('SECURITY', 'ACT'));
	end if;
end;
/

SET TERMOUT OFF
COL READ_FROM_SET NEW_VALUE CONNECT_IDENTIFIER
SELECT LOWER('&_USER') || '@' || LOWER('&_CONNECT_IDENTIFIER') READ_FROM_SET FROM DUAL;
SET TERMOUT ON
SET SQLPROMPT "&&CONNECT_IDENTIFIER> "

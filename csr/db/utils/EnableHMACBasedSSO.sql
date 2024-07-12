prompt Enter host:
define host="&1"
prompt [B]inary or [A]SCII key?
define key="&2"
prompt Overwrite existing key? [y|N]
define overwrite="&3"

set serveroutput on

@EnableSSLBasedSSO &&host

declare
	v_key_length	number;
	v_key		csr.hmac.shared_secret%type;
	v_i		integer;
	v_byte		integer;
begin
	security.user_pkg.LogonAdmin('&&host');

	select data_length
	into v_key_length
	from all_tab_columns
	where owner = 'CSR' and table_name = 'HMAC' and column_name = 'SHARED_SECRET';

	v_key := dbms_crypto.RandomBytes(v_key_length);

	if upper('&&overwrite') = 'Y' then
		delete from csr.hmac where app_sid = sys_context('security', 'app');
	end if;

	begin
		insert into csr.hmac (shared_secret)
		values (v_key);
	exception
		when dup_val_on_index then
			select shared_secret
			into v_key
			from csr.hmac;
	end;

	if upper('&&key') = 'A' then
		for v_i in 1..v_key_length loop
			v_byte := utl_raw.cast_to_binary_integer(utl_raw.substr(v_key, v_i, 1));

			if v_byte < 32 or v_byte > 126 then
				v_byte := mod(v_byte, 95) + 32;
				v_key := utl_raw.overlay(utl_raw.substr(utl_raw.cast_from_binary_integer(v_byte), 4 , 1), v_key, v_i, 1);
			end if;
		end loop;

		dbms_output.put_line('  Key (Hex) = ' || v_key);

		update csr.hmac
		set shared_secret = v_key
		where app_sid = sys_context('security', 'app');

		dbms_output.put_line('Key (ASCII) = ' || utl_raw.cast_to_varchar2(v_key));
	else
		dbms_output.put_line('Key (Hex) = ' || v_key);
	end if;
end;
/
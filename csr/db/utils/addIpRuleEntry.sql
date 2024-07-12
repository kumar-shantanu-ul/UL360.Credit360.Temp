PROMPT please enter: host
define host='&&1'
PROMPT please enter: IP address e.g. 192.168.1.0
define ip_address='&&2'
PROMPT please enter: Subnet mask e.g. 255.255.255.255
define subnet_mask='&&3'
PROMPT please enter: allow?	1 or 0
define allow='&&4'
PROMPT please enter: require SSL? 1 or 0
define require_ssl='&&5'
PROMPT please enter: ip_rule_id for given host
define ip_rule_id='&&6'

whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

declare
	v_ip_rule_id		security.ip_rule.ip_rule_id%TYPE;
	v_ip_rule_index		security.ip_rule_entry.ip_rule_index%TYPE;
	
	v_parts_cnt			number(10);
	v_invalid_parts_cnt	number(10);
	shift				number;
	shifted_mask		number;
	full_mask			number(10);
	full_ip				number(10);
	shifted_ip			number;

	t_parts				aspen2.T_SPLIT_TABLE;
	
	type array_t is varray(4) of number;
	ip_parts			array_t;
	subnet_parts		array_t;
begin
	security.user_pkg.logonadmin('&&host');
  
  -- Check for invalid ip address
	t_parts := csr.utils_pkg.splitstring('&&ip_address', '.');
	select count(*) into v_parts_cnt FROM TABLE(CAST(t_parts AS aspen2.T_SPLIT_TABLE));
	select count(*) into v_invalid_parts_cnt FROM TABLE(CAST(t_parts AS aspen2.T_SPLIT_TABLE)) where TO_NUMBER(item) < 0 OR TO_NUMBER(item) > 255;

	if v_parts_cnt <> 4 OR v_invalid_parts_cnt > 0 then
		raise_application_error(-20001, 'invalid IP address: '||'&&ip_address');
	end if;
	
	-- Check for invalid subnet mask
	t_parts := csr.utils_pkg.splitstring('&&subnet_mask', '.');
	select count(*) into v_parts_cnt FROM TABLE(CAST(t_parts AS aspen2.T_SPLIT_TABLE));
	select count(*) into v_invalid_parts_cnt FROM TABLE(CAST(t_parts AS aspen2.T_SPLIT_TABLE)) where TO_NUMBER(item) < 0 OR TO_NUMBER(item) > 255;

	if v_parts_cnt <> 4 OR v_invalid_parts_cnt > 0 then
		raise_application_error(-20001, 'invalid subnet mask: '||'&&subnet_mask');
	end if;

	-- Get ip and subnet mask parts
	ip_parts := array_t(null, null, null, null);
	subnet_parts := array_t(null, null, null, null);

	for r in (
		select item, pos FROM TABLE(CAST(csr.utils_pkg.splitstring('&&ip_address', '.') AS aspen2.T_SPLIT_TABLE))
	) loop
		ip_parts(r.pos) := r.item;
	end loop;
	
	for r in (
		select item, pos FROM TABLE(CAST(csr.utils_pkg.splitstring('&&subnet_mask', '.') AS aspen2.T_SPLIT_TABLE))
	) loop
		subnet_parts(r.pos) := r.item;
	end loop;	

	full_ip := 0;
	shifted_ip := 0;
	full_mask := 0;
	shifted_mask := 0;

	shift := 0;
  
	-- Convert ip address and mask to number
	for i in 1..4 loop
		shifted_ip := ip_parts(i) * power(2, shift); -- shift to correct byte
		full_ip := full_ip + shifted_ip - BITAND(full_ip, shifted_ip); -- bitwise or

		shifted_mask := subnet_parts(i) * power(2, shift); -- shift to correct byte
		full_mask := full_mask + shifted_mask - BITAND(full_mask, shifted_mask); -- bitwise or
		
		shift := shift + 8;
	end loop;
  
	-- Create ip rule if it doesn't exist
	begin
		select ip_rule_id
		into v_ip_rule_id
		from SECURITY.ip_rule
		where ip_rule_id = TO_NUMBER('&&ip_rule_id');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			insert into security.ip_rule (ip_rule_id)
			values (TO_NUMBER('&&ip_rule_id'))
			returning ip_rule_id into v_ip_rule_id;
	end;

	select nvl(max(ip_rule_index) + 1, 1)
	into v_ip_rule_index
	from security.ip_rule_entry
	where ip_rule_id = v_ip_rule_id;
	
	-- Create ip_rule_entry
	insert into SECURITY.ip_rule_entry (ip_rule_id, ip_rule_index, ipv4_address, ipv4_bitmask, require_ssl, allow)
	values (v_ip_rule_id, v_ip_rule_index, full_ip, full_mask, TO_NUMBER('&&require_ssl'), TO_NUMBER('&&allow'));
end;
/

PROMPT *** New IP rule entry added to SECURITY.IP_RULE_ENTRY 	***
PROMPT *** No changes have been made to the web resources		***
PROMPT *** associated with the IP rule (see IP_RULE_ID column	***
PROMPT *** on SECURITY.WEB_RESOURCE)							***

declare
begin
	for r in (
		select delegation_sid, delegation_pkg.isFullyDelegated(delegation_sid) fd from delegation where fully_delegated != delegation_pkg.isFullyDelegated(delegation_sid)
	)
	loop
		update delegation set fully_delegated = r.fd where delegation_sid = r.delegation_sid;
	end loop;
end;
/
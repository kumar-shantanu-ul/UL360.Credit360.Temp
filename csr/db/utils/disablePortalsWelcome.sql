begin
	user_pkg.logonadmin('&&1');
	update csr_user set show_portal_help = 0 where csr_user_sid not in (select csr_user_sid from superadmin);
end;
/

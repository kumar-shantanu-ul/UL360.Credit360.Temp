ACCEPT host CHAR     PROMPT 'Host (e.g. clientname.credit360.com)  :  '

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnablePortal;
	commit;
end;
/
exit;
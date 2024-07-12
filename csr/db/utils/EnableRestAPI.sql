PROMPT 'Host (e.g. clientname.credit360.com)  :  '
DEFINE host=&&1

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableRestAPI;
	commit;
end;
/
exit;
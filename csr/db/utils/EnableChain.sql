ACCEPT host CHAR           PROMPT 'Host (e.g. clientname.credit360.com)             :  '
ACCEPT sitename CHAR       PROMPT 'site name (defaults to "Supply chain management"):  '

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableChain('&&sitename');
	commit;
end;
/
exit;
ACCEPT host CHAR                PROMPT 'Host (e.g. clientname.credit360.com):  '
ACCEPT topCompanyName CHAR      PROMPT 'Top company name (defaults to CR360):  '

begin
	
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableChainTwoTier(NVL('&&topCompanyName', 'CR360'));
	commit;
end;
/
exit;
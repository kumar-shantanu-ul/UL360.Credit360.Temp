ACCEPT host CHAR        PROMPT 'Host (e.g. clientname.credit360.com)  :  '
ACCEPT user CHAR        PROMPT 'User                                  :  '
ACCEPT password CHAR    PROMPT 'Password                              :  '

begin
	security.user_pkg.logonadmin('&&host');
	csr.enable_pkg.EnableFeeds('&&user', '&&password');
	commit;
end;
/
exit;
PROMPT 'ONLY USE THIS ON A LOCAL DB. WILL SUCCEED FOR LIVE, BUT THE PROFILE WILL NOT WORK!';

ACCEPT host CHAR     PROMPT 'Host (e.g. clientname.credit360.com)  :  '

begin
	security.user_pkg.logonadmin('&&host');
	
	INSERT INTO csr.ftp_profile (ftp_profile_id, label, host_name, secure_credentials, fingerprint, username, password, port_number, ftp_protocol_id)
	VALUES (csr.ftp_profile_id_seq.nextval, 'dev_SFTP_cmsimport', 'ldn-dev-ftp01', 
	'PuTTY-User-Key-File-2: ssh-rsa
Encryption: none
Comment: cmsimport
Public-Lines: 6
AAAAB3NzaC1yc2EAAAABJQAAAQEAixLpsW/ebnGAMOOcsiAbSyY40WYdrWv2xQ4l
9Cp2sxtxe6XDpygJbjtMj9m4qAP+RJkLjxHM8VWYo/shtVXftNSfotVSAvARzo6n
MoRiyXO1wBGm685aPGjSCIpahIxq18S5CHP42wKvroeX6dQdzxAvz9/FgWo5Kx2o
LrriRrFh7S6h4KHwsadYqOw9gADOBac0B3Avriz+mH7Mq+aX/2HrY0TGP2lnZ9ry
0fZEI8eXUjbYDjsiN+IseymNuTUMbU7CU2JWIL2NFsFLWgYi+7gJrswnhmIJ7wqQ
J+RDCGQj/gVCF9kqKkjNa/r6a/79YFWsVYl/4gosPpKfOfs9pw==
Private-Lines: 14
AAABADwj2q2YKNXQN28WUZkipATSQhVclzY8hmMNCX5XjUaIaGzSD2rg4XvGnaX9
SO61nmLaZd0Ax1Oaot8gfUd/FKE5WcnftMMAB7NEm1QdkoCgvUwjTxncsWY7KmSO
2wjixmskowqTA9RUMEt4578PnjAG/+swVWhlSSdmxUSj13iDZM1am4PzObxSPMmU
R7VZDJXsT16fl92WzJwXErSVgpHHeluYxgmBUX14ryW09/WgEH+q6ealx4ug5+2R
wSwF6SJ9s8BU2ZH5T56uthtTjanfarQtozyNCM5eEFZCFf0rWw4/G5MO+9Ft9mpb
kgX/H98baozszq3hEZUtAWI3/C0AAACBAPrylVySSPjDIbD7q85z9y8LnnNMNSDI
MKDVpFPku/s26q9ljvGMsjN8dIZjPf/YCavseheSxYbwBN5aKTVQUH49uW9W2qxg
xrSgYYtOsqmYjbQISn8kk+AdGWKYM/jvoAsDhZx7tCVK4MrpgVm79M6B9Yuo0XMh
KpqdK8KDYX6bAAAAgQCN37e9rTaCawd7GxmJOKux31ZJMGn/tY+kmeUdhZDe11nx
CeSKvLwneT9XZ4XG47vFPoGDlhY91Pk1y59JsxbjD9KjT8NynmZQV2u67CJBylWu
5dge5cgFdLenyDd3P0/WaY212BJeixm4rIXfAiw1KnC6RtRuzscY+G7Jg3hH5QAA
AIARPQoChFhOeuVl66aJBDnjIwXz/CmI2d1ptRxzeqwqqaUvjQYWFc438LcZV04f
p2OibRLpIYo0ZZwUwtMHM79RSTBVryJTjiXVGBM/khvP2ZBYUpbznIg/01ePW2la
8SComnnyPEB6/gOATS/8FFry2zRv5hxtYRX2BfokaMAq4A==
Private-MAC: f3a96133399152efc208e1a7cd7ccc643fef7d9c', 
	'ssh-rsa 2048 21:5d:f8:9d:63:59:41:93:0f:d3:92:57:4f:41:01:8e', 'cmsimport', null, 2222, 2);
	
	commit;
end;
/
exit;
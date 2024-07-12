GRANT EXECUTE ON donations.SCHEME_pkg TO SECURITY;
GRANT EXECUTE ON donations.recipient_pkg TO SECURITY;
GRANT EXECUTE ON donations.recipient_pkg TO CSR;
GRANT EXECUTE ON donations.region_group_pkg TO SECURITY;
GRANT EXECUTE ON donations.tag_pkg TO SECURITY;
GRANT EXECUTE ON donations.sys_pkg TO CSR;
GRANT EXECUTE ON donations.status_pkg TO SECURITY;
GRANT EXECUTE ON donations.transition_pkg TO SECURITY;
grant execute on donations.reports_pkg to csr;
grant execute on donations.sys_pkg to csr;
grant execute on donations.funding_commitment_pkg to mail;

@@web_grants


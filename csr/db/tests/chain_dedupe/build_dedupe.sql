set define off

@@chain_dedupe\test_chain_shared_dedupe_pkg
@@chain_dedupe\test_chain_shared_dedupe_body
@@chain_dedupe\test_chain_dedupe_pkg
@@chain_dedupe\test_chain_dedupe_body
@@chain_dedupe\test_chain_cms_dedupe_pkg
@@chain_dedupe\test_chain_cms_dedupe_body
@@chain_dedupe\test_chain_user_dedupe_pkg
@@chain_dedupe\test_chain_user_dedupe_body
@@chain_dedupe\test_chain_preprocess_pkg
@@chain_dedupe\test_chain_preprocess_body
@@chain_dedupe\test_dedupe_partial_pkg
@@chain_dedupe\test_dedupe_partial_body
@@chain_dedupe\test_chain_substitution_pkg
@@chain_dedupe\test_chain_substitution_body
@@chain_dedupe\test_dedupe_multisource_pkg
@@chain_dedupe\test_dedupe_multisource_body
@@chain_dedupe\test_dedupe_pending_pkg
@@chain_dedupe\test_dedupe_pending_body
@@chain_dedupe\test_dedupe_purchaser_pkg
@@chain_dedupe\test_dedupe_purchaser_body
@@chain_dedupe\test_dedupe_imp_src_active_pkg
@@chain_dedupe\test_dedupe_imp_src_active_body


--grant access to csr so that unit_test_pkg can call it
grant execute on chain.test_chain_dedupe_pkg to csr;
grant execute on chain.test_chain_cms_dedupe_pkg to csr;
grant execute on chain.test_chain_user_dedupe_pkg to csr;
grant execute on chain.test_chain_preprocess_pkg to csr;
grant execute on chain.test_dedupe_partial_pkg to csr;
grant execute on chain.test_chain_substitution_pkg to csr;
grant execute on chain.test_dedupe_multisource_pkg to csr;
grant execute on chain.test_dedupe_purchaser_pkg to csr;
grant execute on chain.test_dedupe_pending_pkg to csr;
grant execute on chain.test_dedupe_imp_src_active_pkg to csr;

set define on

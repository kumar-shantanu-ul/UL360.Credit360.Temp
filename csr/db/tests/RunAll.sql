WHENEVER oserror EXIT FAILURE
WHENEVER sqlerror EXIT FAILURE

-- Run with explicit site
--@all_tests 'db-unit-tests.credit360.com'

-- Run with default site (rag.credit360.com)
@all_tests


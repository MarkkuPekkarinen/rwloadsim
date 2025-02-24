rem
rem Copyright (c) 2023 Oracle Corporation
rem Licensed under the Universal Permissive License v 1.0
rem as shown at https://oss.oracle.com/licenses/upl/

rem
rem Owner  : bengsig
rem
rem Name
rem   mtit_create.sql - Create mtit synonyms
rem
rem History
rem   bengsig  10-may-2023 - Creation

create or replace synonym aw_mtit_noix for &&1..aw_mtit_noix
/

create or replace synonym aw_mtit_ix for &&1..aw_mtit_ix
/

create or replace synonym aw_mtit_revix for &&1..aw_mtit_revix
/

create or replace synonym aw_mtit_ixp8 for &&1..aw_mtit_ixp8
/

create or replace synonym aw_mtit_cdr for &&1..aw_mtit_cdr
/

create or replace synonym aw_mit_seq_small for &&1..aw_mit_seq_small
/

create or replace synonym aw_mit_seq_large for &&1..aw_mit_seq_large
/

create or replace synonym aw_mit_seq_scale for &&1..aw_mit_seq_scale
/

exit

devtools::load_all()

devtools::test()

# fetch_objfun()
# OBJV:********************************************     8986.318       **************************************************



lst <- read_lst_file("../tests/testthat/full_cov.lst")


# lst <- read_lst_file("../tests/lsts/theta_no_cov.lst")
lst <- read_lst_file("../tests/testthat/theta_no_SE.lst")

lst <- read_lst_file("../tests/testthat/test_1.lst")


summary(lst)

fetch_thetas(lst)
fetch_etas(lst)
fetch_condn(lst)

fetch_ofv(lst, 3)


header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
header2 <- "STANDARD ERROR OF ESTIMATE"
subheader <- "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"
subheader <- "OMEGA - CORR MATRIX FOR RANDOM EFFECTS - ETAS"

.f_get_block_values(lst, header1, header2, subheader)

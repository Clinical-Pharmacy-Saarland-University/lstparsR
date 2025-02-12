devtools::load_all()

# fetch_objfun()
# OBJV:********************************************     8986.318       **************************************************



lst <- read_lst_file("./tests/lsts/full_cov.lst")


fetch_thetas(lst)
0
fetch_etas(lst, 3)
fetch_sigmas(lst, 3)

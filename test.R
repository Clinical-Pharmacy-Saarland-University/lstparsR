devtools::load_all()

# fetch_objfun()
#OBJV:********************************************     8986.318       **************************************************



lst <- read_lst_file("./tests/lsts/full_cov.lst")


fetch_thetas(lst)


fetch_ofv(lst, ofv_digits = 0)

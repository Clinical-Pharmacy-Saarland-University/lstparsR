# parsing the long synthetic reference listing is stable

    structure(list(parameter = c("TH_1", "TH_2", "TH_3", "TH_4", 
    "TH_5", "TH_6", "TH_7", "TH_8", "TH_9", "TH10", "TH11", "TH12"
    ), estimate = c(5.84, 27100, 9.62, 41.7, 0.736, 0.183, -0.0942, 
    0.0127, 1.38, 0.552, -0.218, 0.0461), se = c(0.426, 3950000, 
    1.07, 6.33, 0.0911, 0.0402, 0.0213, 0.00294, 0.271, 0.0876, 0.0738, 
    0.0129), rse = c(7.29452054794521, 14575.6457564576, 11.1226611226611, 
    15.1798561151079, 12.3777173913043, 21.9672131147541, 22.6114649681529, 
    23.1496062992126, 19.6376811594203, 15.8695652173913, 33.8532110091743, 
    27.9826464208243)), row.names = c(NA, -12L), class = c("tbl_df", 
    "tbl", "data.frame"))

---

    structure(list(parameter = c("ETA1", "ETA2", "ETA3", "ETA4", 
    "ETA5", "ETA6", "ETA7"), estimate = c(0.0784, 0.112, 3.27e-09, 
    5.62e-08, 1.09e-06, 0.04, 0.04), se = c(0.0352, 0.0431, 1.84e+71, 
    2.33e+72, 8.41e+67, NA, NA), rse = c(44.8979591836735, 38.4821428571429, 
    5.62691131498471e+81, 4.14590747330961e+81, 7.71559633027523e+75, 
    NA, NA), shrinkage = c(6.12, 2.48, 100, 100, 98.3, 97.6, 98.8
    )), row.names = c(NA, -7L), class = c("tbl_df", "tbl", "data.frame"
    ))

---

    structure(list(parameter = c("EPS1", "EPS2"), estimate = c(0.0331, 
    0.0127), se = c(0.00415, 0.00388), rse = c(12.5377643504532, 
    30.5511811023622)), row.names = c(NA, -2L), class = c("tbl_df", 
    "tbl", "data.frame"))

---

    6342.518

---

    546.511627906977

# fetch_all output for the long synthetic reference listing is stable

    list(thetas = structure(list(parameter = c("TH_1", "TH_2", "TH_3", 
    "TH_4", "TH_5", "TH_6", "TH_7", "TH_8", "TH_9", "TH10", "TH11", 
    "TH12"), estimate = c(5.84, 27100, 9.62, 41.7, 0.736, 0.183, 
    -0.0942, 0.0127, 1.38, 0.552, -0.218, 0.0461), se = c(0.426, 
    3950000, 1.07, 6.33, 0.0911, 0.0402, 0.0213, 0.00294, 0.271, 
    0.0876, 0.0738, 0.0129), rse = c(7.29452054794521, 14575.6457564576, 
    11.1226611226611, 15.1798561151079, 12.3777173913043, 21.9672131147541, 
    22.6114649681529, 23.1496062992126, 19.6376811594203, 15.8695652173913, 
    33.8532110091743, 27.9826464208243)), row.names = c(NA, -12L), class = c("tbl_df", 
    "tbl", "data.frame")), etas = structure(list(parameter = c("ETA1", 
    "ETA2", "ETA3", "ETA4", "ETA5", "ETA6", "ETA7"), estimate = c(0.0784, 
    0.112, 3.27e-09, 5.62e-08, 1.09e-06, 0.04, 0.04), se = c(0.0352, 
    0.0431, 1.84e+71, 2.33e+72, 8.41e+67, NA, NA), rse = c(44.8979591836735, 
    38.4821428571429, 5.62691131498471e+81, 4.14590747330961e+81, 
    7.71559633027523e+75, NA, NA), shrinkage = c(6.12, 2.48, 100, 
    100, 98.3, 97.6, 98.8)), row.names = c(NA, -7L), class = c("tbl_df", 
    "tbl", "data.frame")), sigmas = structure(list(parameter = c("EPS1", 
    "EPS2"), estimate = c(0.0331, 0.0127), se = c(0.00415, 0.00388
    ), rse = c(12.5377643504532, 30.5511811023622)), row.names = c(NA, 
    -2L), class = c("tbl_df", "tbl", "data.frame")), ofv = 6342.518, 
        condn = 546.511627906977)

# THETA parsing of a listing with damaged OMEGA/SIGMA blocks is stable

    structure(list(parameter = c("TH_1", "TH_2", "TH_3", "TH_4"), 
        estimate = c(7.69, 18.3, 3.06, 46.4), se = c(0.522, 1.75, 
        0.433, 6.02), rse = c(6.78803641092328, 9.56284153005464, 
        14.1503267973856, 12.9741379310345)), row.names = c(NA, -4L
    ), class = c("tbl_df", "tbl", "data.frame"))

# THETA parsing without a covariance step is stable

    structure(list(parameter = c("TH_1", "TH_2", "TH_3", "TH_4"), 
        estimate = c(4.46, 30.7, 1.18, 0.701), se = c(NA_real_, NA_real_, 
        NA_real_, NA_real_), rse = c(NA_real_, NA_real_, NA_real_, 
        NA_real_)), row.names = c(NA, -4L), class = c("tbl_df", "tbl", 
    "data.frame"))


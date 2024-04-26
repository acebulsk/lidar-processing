# this script regresses contact number and interception efficiency 
# a regression is run for each portion of the hemisphere (360*90 regressions)
# each regression is essentially the R2 between a raster of IP and a raster of Contact Numbers

import h5py
import numpy as np
import pandas as pd


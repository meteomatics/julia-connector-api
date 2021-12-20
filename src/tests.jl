using MeteomaticsAPI
using Dates

# We can obtain a time-series of surface temperature and pressure for two coordinates at 1.5 hourly 
# resolution over the next 14 days:

df_ts = querytimeseries(
    [(0, 50), (50, 0)], Dates.now(), Dates.now() + Day(14), 
    Hour(1)+Minute(30), ["t_2m:C", "msl_pressure:hPa"]
)

# Here a CompoundPeriod was used as the interval (4th argument) to demonstrate how one can in general 
# be created in Julia: the connector accepts these as long as constituent parts are of types Day, 
# Hour, Minute and/or Second. Start and end dates were provided as Dates.Date objects. Alternatively, 
# users can provide well-formed strings. 

# We can obtain gridded data for the same variables. Be sure to provide as many variables into which 
# to unpack the requests as you have parameters:

df_grid_t, df_grid_p = querygrid(Dates.now(), ["t_2m:C", "msl_pressure:hPa"], 50, 0, 0, 50, 1, 1)

# The login credentials required to run this query are contained in Config.jl. You can overwrite these, 
# or provide your own credentials as optional arguments. All additional optional arguments described at 
# https://www.meteomatics.com/en/api/request/optional-parameters/ are also available.

# Two types of metadata requests can be made, but require an API subscription to work properly 
# (metadata requests don't work for 'mix' models; other models are not available without subscription)
df_tr = querytimeranges(
    ["t_2m:C", "msl_pressure:hPa"], "ecmwf-vareps"
)

df_it = queryinitdatetime(
    Dates.now(), Dates.now() + Day(14), 
    Hour(1)+Minute(30), ["t_2m:C", "msl_pressure:hPa"], "ecmwf-vareps"
)

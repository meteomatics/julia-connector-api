include("DataTypes.jl")
include("ParserFunctions.jl")
include("Config.jl")

using HTTP
using CSV
using DataFrames
using Suppressor

availablemodels = [
    "mix",
    "ecmwf-ifs",
    "ecmwf-ens",
    "ecmwf-ens-cluster",
    "ecmwf-ens-tc",
    "ecmwf-vareps",
    "ecmwf-mmsf",
    "cmc-gem",
    "ncep-gfs",
    "mm-tides",
    "mm-swiss1k",
    "ukmo-euro4",
    "mf-arome",
    "dwd-icon-eu",
    "ecmwf-cams",
    "fmi-silam",
    "ecmwf-wam",
    "ecmwf-cmems",
    "noaa-hycom",
    "ecmwf-era5",
    "chc-chirps2",
    "mix-radar",
    "mm-heliosat",
    "mm-lightning", 
    "noaa-swpc",
    "mix-satellite",
    "eumetsat-h03b",
    "dlr-corine",
    "mix-obs",
    "mm-mos",
    "mri-esm2-ssp126",
    "mri-esm2-ssp245",
    "mri-esm2-ssp370",
    "mri-esm2-ssp460",
    "mri-esm2-ssp585"
]

ensemblemodels = Dict(
    "ecmwf-ens" => [string(x) for x in 0:1:50],
    "ecmwf-vareps" =>  [string(x) for x in 0:1:32],
    "ecmwf-mmsf" =>  [string(x) for x in 0:1:31],
    "ncep-gfs-ens" => [string(x) for x in 0:1:31]
)

clustermodels = Dict(
    "as above" => "so below"
)

"""
Optional arguments should be checked to ensure that they correspond to valid API calls.
Some of these have not been implemented yet: valid ens_select and cluster_select depend on the chosen model,
and I don't have complete information on this to hand as of the time of first draft.
"""
function checkopts(model, calibrated, mask, ens_select, cluster_select, timeout)
    if model === nothing
    else
        @assert in(model, availablemodels)
    end
    calibrated::Union{Bool, Nothing} 
    if mask === nothing 
    else
        mask = lowercase(mask)
        @assert mask == "land" || mask == "sea"
    end
    # @assert ens_select belongs to some group of valid values (dependent on model) or is nothing
    # @assert cluster_select as above 
    timeout::Union{Integer, Nothing}
end

"""
Returns a DataFrame containing a time-series for each of the pairs of coordinates provided and each of the parameters requested.
The first two columns describe the location (latitude and longitude) of the time-series; the third column contains the date and
time as a string. The remaining columns contain the data for the requested variables at these locations and dates/times. 
The user may provide a username and password; otherwise those contained in Config.jl are used. Change these to your own credentials
to avoid having to provide the information for every request. Optional arguments are also available, see 
https://www.meteomatics.com/en/api/request/optional-parameters/ for more details and default behaviour.
"""
function querytimeseries(coordinate_list, startdate, enddate, interval, parameters; username=username, password=password,
        model=nothing, calibrated=nothing, mask=nothing, ens_select=nothing, cluster_select=nothing, timeout=nothing)
    checkopts(model, calibrated, mask, ens_select, cluster_select, timeout)
    url = parse_url(
        username, 
        password, 
        data_url(
            validdatetime = parse_datetimes(startdate, enddate, interval), 
            parameters = parse_parameters(parameters), 
            location = parse_locations(coordinate_list), 
            opts = Dict(
                "model" => model, 
                "calibrated" => calibrated,
                "mask" => mask,
                "ens_select" => ens_select,
                "cluster_select" => cluster_select,
                "timeout" => timeout
            )
        )
    )
    return handlerequest(url)
end

"""
Returns a DataFrame containing longitudes in the first row and latitudes in the first column. The rest of the DataFrame is populated
with the requested data at the coordinates subtended by row/column #1. The date and time of the request is not contained within the 
DataFrame: users should keep track of this separately. 
The user may provide a username and password; otherwise those contained in Config.jl are used. Change these to your own credentials
to avoid having to provide the information for every request. Optional arguments are also available, see 
https://www.meteomatics.com/en/api/request/optional-parameters/ for more details and default behaviour.
"""
function querygrid(startdate, parameter::String, north, west, south, east, reslat, reslon; username=username, password=password,
        model=nothing, calibrated=nothing, mask=nothing, ens_select=nothing, cluster_select=nothing, timeout=nothing)
    checkopts(model, calibrated, mask, ens_select, cluster_select, timeout)
    url = parse_url(
        username, 
        password, 
        data_url(
            validdatetime = parse_datetime(startdate), 
            parameters = parse_parameters(parameter), 
            location = parse_locations(north, west, south, east, reslon, reslat),
            opts = Dict(
                "model" => model, 
                "calibrated" => calibrated,
                "mask" => mask,
                "ens_select" => ens_select,
                "cluster_select" => cluster_select,
                "timeout" => timeout
            )
        )
    )
    @suppress_err df = handlerequest(url)  # warning (regarding badly shaped .csv) suppressed
    # post-process the DataFrame:
    df = df[2:end, :]  # remove header
    rename!(df, names(df)[1] => "Column1", names(df)[2] => "Column2") # change column names (back to defaults; hardcoded)
    col1 = [missing, parse.(Float64, df[2:end, 1])...] # now that string values have been removed, convert cols to float...
    col2 = [parse.(Float64, df[1:end, 2])...] # ...achieved by making substitute columns with strings replaced by missing...
    df = df[:, 3:end]  # ...removing the original columns from the DataFrame...
    insertcols!(df, 1, :Column1 => col1) # ...and inserting the prepared columns at the requisite indexes
    insertcols!(df, 2, :Column2 => col2)
    allowmissing!(df)
    return df
end

"""
Returns one DataFrame per requested parameter, containing longitudes in the first row and latitudes in the first column. The rest of the DataFrame is populated
with the requested data at the coordinates subtended by row/column #1. The date and time of the request is not contained within the 
DataFrame: users should keep track of this separately. 
The user may provide a username and password; otherwise those contained in Config.jl are used. Change these to your own credentials
to avoid having to provide the information for every request. Optional arguments are also available, see 
https://www.meteomatics.com/en/api/request/optional-parameters/ for more details and default behaviour.
"""
function querygrid(startdate, parameters::Vector{String}, north, west, south, east, reslat, reslon; username=username, password=password,
    model=nothing, calibrated=nothing, mask=nothing, ens_select=nothing, cluster_select=nothing, timeout=nothing)
    if length(parameters) == 1
        return querygrid(startdate, parameters[1], north, west, south, east, reslat, reslon; username=username, password=password,
        model=model, calibrated=calibrated, mask=mask, ens_select=ens_select, cluster_select, timeout=timeout)
    else
        checkopts(model, calibrated, mask, ens_select, cluster_select, timeout)
        url = parse_url(
            username, 
            password, 
            data_url(
                validdatetime = parse_datetime(startdate), 
                parameters = parse_parameters(parameters), 
                location = parse_locations(north, west, south, east, reslon, reslat),
                opts = Dict(
                    "model" => model, 
                    "calibrated" => calibrated,
                    "mask" => mask,
                    "ens_select" => ens_select,
                    "cluster_select" => cluster_select,
                    "timeout" => timeout
                )
            )
        )
        df = handlerequest(url)
        dfs = Array{DataFrame}(undef, length(names(df)) - 3)
        i = 1
        for column in names(df)[4:end]
            dfs[i] = reshape(select(df, 1, 2, column))
            i += 1
        end
        return dfs
    end
end

"""
Takes a DataFrame as returned by a grid request of multiple parameters. Reshapes- and processes the DataFrame and returns it.
"""
function reshape(df::DataFrames.DataFrame)
    unstacked = unstack(df, 1, 2, 3)
    allowmissing!(unstacked)
    firstrow = DataFrame(Dict((names(unstacked)[i], [0.0, parse.(Float64, names(unstacked[:, 2:end]))...][i]) for i in 1:length(names(unstacked))))[:, names(unstacked)]
    allowmissing!(firstrow)
    firstrow[1,1] = missing
    [push!(firstrow, unstacked[i, :]) for i in 1:length(unstacked[:, 1])]
    rename!(firstrow, [names(firstrow)[i] => "Column$i" for i in 1:length(names(firstrow))]...)
    return firstrow  
end

"""
Returns a DataFrame whose first column is the names of the parameters requested and whose second- and third columns are, 
respectively, the minimum date from which that variable is available in the queried model and the maximum available date
for that parameter. This is a meta-request - no optional parameters exist. The user may still optionally provide a 
username and password; otherwise these are obtained from Config.jl.
"""
function querytimeranges(parameters, model; username=username, password=password)
    url = parse_url(username, password, meta_url(metaquery="get_time_range", model=model, parameters=parse_parameters(parameters)))
    return handlerequest(url)
end

"""
Returns a DataFrame whose first column is the date & time of some variable requested from a model, and whose subsequent columns 
describe the date and time at which the model was run to produce the results which would currently be obtained by querying the model
for each of the parameters queried. This is a meta-request - no optional parameters exist. The user may still optionally provide a 
username and password; otherwise these are obtained from Config.jl.
"""
function queryinitdatetime(startdate, enddate, interval, parameters, model; username=username, password=password)
    url = parse_url(
        username, password, meta_url(metaquery="get_init_date", model=model, 
        parameters=parse_parameters(parameters), validdatetime=parse_datetimes(startdate, enddate, interval))
        )
    return handlerequest(url)
end

"""
Takes a URL, parsed from a url data type, from a query function. Obtains a response from the API for this URL, 
parses the response as a CSV, and parses the CSV data as a DataFrame.
"""
function handlerequest(url)
    response = HTTP.request("GET", url)
    csv_data = CSV.File(response.body)
    return DataFrames.DataFrame(csv_data)
end

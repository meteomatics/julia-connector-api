using Dates 
using TimeZones

"""
Parses the date/time part of the request URL for cases such as querytimeseries where a start- and end date & time plus
a time-step is required. Calls parse_datetime (singular) to parse the start- and end date & time; calls parse_interval 
to parse the time-step.
"""
function parse_datetimes(startdate, enddate, interval)
    return "$(parse_datetime(startdate))--$(parse_datetime(enddate)):$(parse_interval(interval))"
end

"""
Parses date & time information passed as a string. Checks that the format of the string is as expected.
"""
function parse_datetime(datetime::String)
    @assert occursin(r"^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$", datetime) "Make sure start- and end datetime strings match 'YYYY-MM-DDTHH:MM:SST' format, where T and Z are literal characters."
    return "$datetime"
end 

"""
Parses date & time information passed as a Date.DateTime.  
"""
function parse_datetime(datetime::DateTime)
    return "$(Dates.format(datetime, "yyyy-mm-ddTHH:MM:SS"))Z"
end

"""
Parses date & time information passed as a TimeZones.ZonedDateTime by converting to a Dates.DateTime in UTC
and calling the method for a Dates.DateTime argument.
"""
function parse_datetime(datetime::ZonedDateTime)
    return parse_datetime(DateTime(datetime, UTC))
end

"""
Parses the time-step part of the URL if the user has provided a string. Checks that the string has the correct format.
"""
function parse_interval(interval::String)
    @assert occursin(r"^P(\dD)?(T(\d[HMS])+)?$", interval) "Intervals should start with P. Days may be left blank, but sub-day periods should be separated from days by T."
    return "$interval"
end

"""
Parses the time-step part of the URL if the user has provided a (number of) Dates.Day
"""
function parse_interval(interval::Dates.Day)
    return "P$(interval.value)D"
end

"""
Parses the time-step part of the URL if the user has provided a (number of) Dates.Hour
"""
function parse_interval(interval::Dates.Hour)
    return "PT$(interval.value)H"
end

"""
Parses the time-step part of the URL if the user has provided a (number of) Dates.Minute
"""
function parse_interval(interval::Dates.Minute)
    return "PT$(interval.value)M"
end

"""
Parses the time-step part of the URL if the user has provided a (number of) Dates.Second
"""
function parse_interval(interval::Dates.Second)
    return "PT$(interval.value)S"
end

"""
Parses the time-step part of the URL if the user has provided a Dates.CompoundPeriod. 
"""
function parse_interval(interval::Dates.CompoundPeriod)
    lookup = Dict(Dates.Day=>'D', Dates.Hour=>'H', Dates.Minute=>'M',Dates.Second=>'S')
    undelimited = join(["$(p.value)$(lookup[typeof(p)])" for p in interval.periods])
    ind = findfirst(c->c=='D', undelimited)
    if isnothing(ind) 
        daypart="" 
        timepart=undelimited 
    else 
        daypart="$(undelimited[1:ind])"
        timepart="$(undelimited[ind+1:end])" 
    end
    return "P$(daypart)T$(timepart)"
end

"""
Parses the parameters part of the URL, assuming the user has provided a vector containing their parameters.
Concatenates the parameters into a string and passes to string version of the method.
"""
function parse_parameters(parameters::Vector{String})
    return parse_parameters(join(parameters, ','))
end

"""
Checks that the parameter string provided (either by the user or by the vector method) fits the expected pattern. 
"""
function parse_parameters(parameters::String)
    @assert occursin(r"(^.+:.+)+$", parameters) "There may be a typo in one or more of your parameters. Parameters should feature a name and a unit, separated by ':'"
    return parameters
end

"""
Parses the location part of the URL if the user has provided a vector of coordinate tuples as required for e.g. 
querytimeseries. Checks each coordinate pair to ensure that they are within an accepted range (wrapping longitudes
if they are in the 180-360 degree range).
"""
function parse_locations(coordinate_list::Vector{<:NTuple{2, Real}})
    coordinate_string = ""
    for (lat, lon) in coordinate_list
        if abs(lat) > 90 throw(DomainError(lat, "value literally out of this world, in a bad way")) end
        if -180 > lon || lon > 360 throw(DomainError(lon, "value outside of supported range")) 
        elseif lon > 180 lon -= 360 end
        coordinate_string*="$lat,$lon+"
    end
    return first(coordinate_string, length(coordinate_string)-1)
end

"""
The user may feasibly forget to wrap a single location tuple in a vector, in which case this method saves the day.
"""
function parse_locations(coordinate::Tuple{Real, Real})
    lat = coordinate[1]
    lon = coordinate[2]
    if abs(lat) > 90 throw(DomainError(lat, "value literally out of this world, in a bad way")) end
    if -180 > lon || lon > 360 throw(DomainError(lon, "value outside of supported range")) 
    elseif lon > 180 lon -= 360 end
    return "$lat,$lon"
end

"""
The user may feasibly enter a single location as a vector, rather than a vector of tuples. This method permits this mistake
"""
function parse_locations(coordinate::Vector{T} where T<:Real)
    if length(coordinate) != 2 throw(ArgumentError("Please wrap your coordinate pairs as Tuples")) end
    lat = coordinate[1]
    lon = coordinate[2]
    if abs(lat) > 90 throw(DomainError(lat, "value literally out of this world, in a bad way")) end
    if -180 > lon || lon > 360 throw(DomainError(lon, "value outside of supported range")) 
    elseif lon > 180 lon -= 360 end
    return "$lat,$lon"
end

"""
Parses the location part of the URL if the user has provided bounding latitudes and longitudes as required for 
e.g. querygrid. Checks each coordinate  to ensure that they are within an accepted range (wrapping longitudes
if they are in the 180-360 degree range).
"""
function parse_locations(north::Real, west::Real, south::Real, east::Real, reslat::Real, reslon::Real)
    if abs(north) > 90 throw(DomainError(north, "value literally out of this world, in a bad way")) end
    if abs(south) > 90 throw(DomainError(south, "value literally out of this world, in a bad way")) end
    if east < west throw(ArgumentError("`east` should be greater than `west`. Areas crossing the dateline are not currently supported")) end
    if -180 > west || west > 360 throw(DomainError(north, "value outside of supported range")) 
    elseif west > 180 west -= 360 end
    if -180 > east || east > 360 throw(DomainError(east, "value outside of supported range")) 
    elseif east > 180 east -= 360 end
    return "$(north),$(west)_$(south),$(east):$reslat,$reslon"
end

"""
Unpacks a DataTypes.data_url into the format anticipated for a request.
"""
function parse_url(username::String, password::String, url::data_url)
    request_url = "https://$username:$password@api.meteomatics.com/"
    request_url *= "$(url.validdatetime)/$(url.parameters)/$(url.location)/$(url.format)"
    request_url *= "?"
    for (key, value) in url.opts
        if value === nothing
        else
            request_url *= "$key=$value&"
        end
    end
    return first(request_url, length(request_url) - 1)
end

"""
Unpacks a DataTypes.meta_url into the format anticipated for a request.
"""
function parse_url(username::String, password::String, url::meta_url)
    base_url = "https://$username:$password@api.meteomatics.com/"
    base_url *= url.metaquery*"?"
    base_url *= "model=$(url.model)&"
    if !isnothing(url.validdatetime) base_url *= "valid_date=$(url.validdatetime)&" end
    base_url *= "parameters=$(url.parameters)"
    return base_url
end

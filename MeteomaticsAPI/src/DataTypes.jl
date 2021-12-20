using Parameters 

abstract type meteomatics_url end

"""
Data type for containing required & optional parts of the request URL for data queries
"""
@with_kw struct data_url<:meteomatics_url
    validdatetime::String
    parameters::String
    location::String
    format::String = "csv"  
    opts::Dict
end

"""
Data type for containing required & optional parts of the request URL for meta queries
"""
@with_kw struct meta_url<:meteomatics_url
    metaquery::String
    model::String 
    parameters::String
    validdatetime::Union{String, Nothing} = nothing
    # there are no 'opts' for a meta_url in the current implementations
end
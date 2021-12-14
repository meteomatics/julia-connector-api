abstract type MeteomaticsAPIException <: Exception end

struct BadRequest <: MeteomaticsAPIException end
struct Unauthorized <: MeteomaticsAPIException end
struct Forbidden <: MeteomaticsAPIException end
struct NotFound <: MeteomaticsAPIException end
struct RequestTimeout <: MeteomaticsAPIException end
struct PayloadTooLarge <: MeteomaticsAPIException end
struct UriTooLong <: MeteomaticsAPIException end
struct TooManyRequests <: MeteomaticsAPIException end
struct InternalServerError <: MeteomaticsAPIException end

request_exceptions = {
    400: BadRequest,
    401: Unauthorized,
    403: Forbidden,
    404: NotFound,
    408: RequestTimeout,
    413: PayloadTooLarge,
    414: UriTooLong,
    429: TooManyRequests,
    500: InternalServerError
}
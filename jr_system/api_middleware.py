from django.http import JsonResponse


class ApiJsonErrorMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            response = self.get_response(request)
        except Exception:
            if request.path.startswith("/api/"):
                return JsonResponse(
                    {"success": False, "message": "Internal server error."},
                    status=500,
                )
            raise
        return self._json_api_error_response(request, response)

    def _json_api_error_response(self, request, response):
        if not request.path.startswith("/api/"):
            return response
        if response.get("Content-Type", "").startswith("application/json"):
            return response
        if response.status_code < 400:
            return response

        messages = {
            400: "Bad request.",
            403: "Permission denied.",
            404: "Endpoint not found.",
            405: "Method not allowed.",
        }
        return JsonResponse(
            {
                "success": False,
                "message": messages.get(response.status_code, "Request failed."),
            },
            status=response.status_code,
        )

    def process_exception(self, request, exception):
        if request.path.startswith("/api/"):
            return JsonResponse(
                {"success": False, "message": "Internal server error."},
                status=500,
            )
        return None

    def process_response(self, request, response):
        return self._json_api_error_response(request, response)

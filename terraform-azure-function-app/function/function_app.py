"""
Azure Function App – Blob read/write example (Python v2 programming model).

Environment variables (set via Terraform app_settings):
    DATA_STORAGE_ACCOUNT_URL  – Primary blob service endpoint of the data storage account.
    DATA_BLOB_CONTAINER_NAME  – Name of the blob container.
    DATA_STORAGE_CLIENT_ID    – Client ID of the user-assigned managed identity used for
                                blob authentication.

Routes:
    GET  /api/blobs/{name}  – Download a blob by name.
    POST /api/blobs/{name}  – Upload / overwrite a blob with the request body.
"""

import logging
import os

import azure.functions as func
from azure.core.exceptions import ResourceNotFoundError
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

_STORAGE_URL = os.environ["DATA_STORAGE_ACCOUNT_URL"]
_CONTAINER = os.environ["DATA_BLOB_CONTAINER_NAME"]
_CLIENT_ID = os.environ["DATA_STORAGE_CLIENT_ID"]

# Module-level client is reused across warm invocations of the same function
# instance, avoiding repeated credential acquisition and connection setup.
_blob_client: BlobServiceClient | None = None


def _get_blob_service_client() -> BlobServiceClient:
    """Return a cached BlobServiceClient authenticated via the user-assigned managed identity."""
    global _blob_client  # noqa: PLW0603
    if _blob_client is None:
        credential = ManagedIdentityCredential(client_id=_CLIENT_ID)
        _blob_client = BlobServiceClient(account_url=_STORAGE_URL, credential=credential)
    return _blob_client


@app.route(route="blobs/{name}", methods=["GET"])
def read_blob(req: func.HttpRequest) -> func.HttpResponse:
    """Download a blob and return its content as application/octet-stream."""
    name = req.route_params.get("name")
    logging.info("read_blob called for '%s'", name)
    try:
        blob_client = _get_blob_service_client().get_blob_client(
            container=_CONTAINER, blob=name
        )
        data = blob_client.download_blob().readall()
        return func.HttpResponse(
            body=data,
            status_code=200,
            mimetype="application/octet-stream",
        )
    except ResourceNotFoundError:
        logging.warning("Blob not found: '%s'", name)
        return func.HttpResponse(
            f"Blob '{name}' not found.",
            status_code=404,
        )
    except Exception as exc:  # pylint: disable=broad-except
        logging.exception("Unexpected error reading blob '%s': %s", name, exc)
        return func.HttpResponse(
            "Internal server error.",
            status_code=500,
        )


@app.route(route="blobs/{name}", methods=["POST"])
def write_blob(req: func.HttpRequest) -> func.HttpResponse:
    """Write the request body as a blob, overwriting any existing blob with the same name."""
    name = req.route_params.get("name")
    logging.info("write_blob called for '%s'", name)
    try:
        blob_client = _get_blob_service_client().get_blob_client(
            container=_CONTAINER, blob=name
        )
        blob_client.upload_blob(req.get_body(), overwrite=True)
        return func.HttpResponse(
            f"Blob '{name}' written successfully.",
            status_code=201,
        )
    except Exception as exc:  # pylint: disable=broad-except
        logging.exception("Unexpected error writing blob '%s': %s", name, exc)
        return func.HttpResponse(
            "Internal server error.",
            status_code=500,
        )

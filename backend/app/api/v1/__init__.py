from fastapi import APIRouter

api_router = APIRouter()


@api_router.get("/")
async def api_root():
    """API root endpoint"""
    return {"message": "Coletânea Digital API v1"}

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import warnings
from app.api.v1 import api_router
from app.core.config import settings

app = FastAPI(
    title="Coletânea Digital API",
    description="Backend API para Coletânea Digital",
    version="1.0.0",
)

# Validar CORS antes de aplicar middleware
if settings.is_production and "*" in settings.CORS_ORIGINS:
    warnings.warn(
        "⚠️  SECURITY WARNING: CORS_ORIGINS is set to '*' with allow_credentials=True in production. "
        "This is a security risk. Please set specific origins in your .env.prod file.",
        UserWarning,
        stacklevel=1
    )

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include API router
app.include_router(api_router, prefix="/api/v1")


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "coletanea-digital-api"}


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Coletânea Digital API",
        "version": "1.0.0",
        "docs": "/docs"
    }

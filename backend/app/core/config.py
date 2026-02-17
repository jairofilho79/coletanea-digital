from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import field_validator
from typing import List, Union
import warnings
import os


class Settings(BaseSettings):
    # Database
    DATABASE_URL: str
    POSTGRES_USER: str = "coletanea_user"
    POSTGRES_PASSWORD: str = "coletanea_password"
    POSTGRES_DB: str = "coletanea_db"
    POSTGRES_PORT: int = 5433

    # Deployment Configuration
    ENVIRONMENT: str = "dev"  # dev ou prod
    DEPLOYMENT_HOST: str = ""  # IP local ou URI do VPS

    # API
    API_PORT: int = 8001
    CORS_ORIGINS: Union[str, List[str]] = "*"

    # Future: JWT Configuration (for auth features)
    # JWT_SECRET_KEY: str = ""
    # JWT_ALGORITHM: str = "HS256"
    # JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    @field_validator('CORS_ORIGINS', mode='after')
    @classmethod
    def validate_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        """Valida CORS_ORIGINS e alerta sobre wildcard em produção"""
        if isinstance(v, str):
            if v == "*" or v == "":
                parsed = ["*"]
            else:
                parsed = [origin.strip() for origin in v.split(",") if origin.strip()]
        else:
            parsed = v if isinstance(v, list) else ["*"]

        # Verificar se está em produção e usando wildcard
        environment = os.getenv("ENVIRONMENT", os.getenv("DEPLOYMENT_ENV", "dev"))
        if environment == "prod" and "*" in parsed:
            warnings.warn(
                "⚠️  SECURITY WARNING: CORS_ORIGINS is set to '*' in production environment. "
                "This is a security risk. Please set specific origins in your .env.prod file:\n"
                "CORS_ORIGINS=https://your-domain.com,https://www.your-domain.com",
                UserWarning,
                stacklevel=2
            )

        return parsed

    @property
    def is_production(self) -> bool:
        """Verifica se está em ambiente de produção"""
        return self.ENVIRONMENT == "prod"

    @property
    def is_development(self) -> bool:
        """Verifica se está em ambiente de desenvolvimento"""
        return self.ENVIRONMENT == "dev"

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
    )


settings = Settings()

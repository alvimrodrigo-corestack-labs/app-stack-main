from fastapi import FastAPI
import os

app = FastAPI(title="CoreStack Labs App")

@app.get("/")
def read_root():
    return {
        "message": "Hello from CoreStack Labs!",
        "env": os.getenv("ENVIRONMENT", "dev"),
        "database_status": "connected (mocked)"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}

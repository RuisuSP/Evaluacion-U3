# Importa la clase datetime para manejar fechas y horas
from datetime import datetime

# Para tipos opcionales
from typing import Optional

# FastAPI APIs
from fastapi import FastAPI, UploadFile, File, HTTPException, Form

# SQLAlchemy
from sqlalchemy import create_engine, Column, Integer, String, TIMESTAMP

# ORM Base
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# Pydantic esquema
from pydantic import BaseModel

# Manejo de archivos
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os

import traceback

app = FastAPI()

UPLOAD_FOLDER = "imagenes"
if not os.path.exists(UPLOAD_FOLDER):
    os.makedirs(UPLOAD_FOLDER)

app.mount("/imagenes", StaticFiles(directory="imagenes"), name="imagenes")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

DATABASE_URL = "mysql+mysqlconnector://root@localhost:3307/db_app_foto"
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

Base = declarative_base()

class Foto(Base):
    __tablename__ = "p10_foto"

    id = Column(Integer, primary_key=True, index=True)
    descripcion = Column(String(200), nullable=True)         
    ruta_foto = Column(String(255), nullable=False)          
    fecha = Column(TIMESTAMP, default=datetime.utcnow)

# Crear tabla si no existe
Base.metadata.create_all(bind=engine)

class FotoSchema(BaseModel):
    id: int
    descripcion: Optional[str]
    ruta_foto: str
    fecha: datetime

    model_config = {
        "from_attributes": True
    }

@app.post("/fotos/")
async def subir_foto(
    descripcion: str = Form(None),
    file: UploadFile = File(...)
):
    try:

        ruta_archivo = f"{UPLOAD_FOLDER}/{file.filename}"

        with open(ruta_archivo, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        nueva_foto = Foto(
            descripcion=descripcion,
            ruta_foto=file.filename
        )

        db = SessionLocal()
        db.add(nueva_foto)
        db.commit()
        db.refresh(nueva_foto)

        return {
            "mensaje": "Foto subida correctamente",
            "datos": FotoSchema.from_orm(nueva_foto)
        }

    except Exception as e:
        print("\n----- ERROR EN EL ENDPOINT /fotos/ -----")
        traceback.print_exc()   # imprime el error real en consola
        print("----- FIN ERROR -----\n")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")

    finally:
        try:
            file.file.close()
        except:
            pass
        
@app.get("/fotos/")
def obtener_fotos():
    db = SessionLocal()
    try:
        fotos = db.query(Foto).all()
        return [FotoSchema.from_orm(f) for f in fotos]
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
    finally:
        db.close()

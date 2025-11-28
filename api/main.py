import os
import shutil
import hashlib
import traceback
from datetime import datetime
from typing import Optional, List
from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Depends
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session, relationship
from pydantic import BaseModel


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

DATABASE_URL = "mysql+mysqlconnector://root:root@localhost:3306/db_paquexpress"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
class UsuarioDB(Base):
    __tablename__ = "usuarios"
    id_usuario = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100))
    correo = Column(String(50), unique=True)
    password = Column(String(200))
    rol = Column(String(20))

class PaqueteDB(Base):
    __tablename__ = "paquetes"
    id_paquete = Column(Integer, primary_key=True, index=True)
    descripcion = Column(String(200))
    direccion_destino = Column(String(255))
    id_repartidor = Column(Integer, ForeignKey("usuarios.id_usuario"))
    estado = Column(String(20), default="pendiente")
    
    foto_evidencia = Column(Text, nullable=True) 
    ubicacion = Column(String(100), nullable=True)
    fecha = Column(DateTime, nullable=True)

Base.metadata.create_all(bind=engine)

class LoginRequest(BaseModel):
    correo: str
    password: str

class PaqueteResponse(BaseModel):
    id_paquete: int
    descripcion: str
    direccion_destino: str
    estado: str
    class Config:
        from_attributes = True

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def md5_hash(password: str) -> str:
    return hashlib.md5(password.encode()).hexdigest()

@app.post("/login")
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(UsuarioDB).filter(UsuarioDB.correo == data.correo).first()
    
    if not user:
        raise HTTPException(status_code=400, detail="Correo no registrado")
        
    if user.password != md5_hash(data.password):
        raise HTTPException(status_code=400, detail="Contraseña incorrecta")
    
    return {
        "mensaje": "Login exitoso",
        "id_usuario": user.id_usuario,
        "nombre": user.nombre,
        "rol": user.rol
    }

@app.get("/mis-paquetes/{id_repartidor}", response_model=List[PaqueteResponse])
def obtener_paquetes(id_repartidor: int, db: Session = Depends(get_db)):
    paquetes = db.query(PaqueteDB).filter(
        PaqueteDB.id_repartidor == id_repartidor,
        PaqueteDB.estado == "pendiente"
    ).all()
    return paquetes

@app.post("/entregar/{id_paquete}")
async def entregar_paquete(
    id_paquete: int,
    file: UploadFile = File(...),
    latitud: str = Form(...),
    longitud: str = Form(...),
    db: Session = Depends(get_db)
):
    try:
        paquete = db.query(PaqueteDB).filter(PaqueteDB.id_paquete == id_paquete).first()
        if not paquete:
            raise HTTPException(status_code=404, detail="Paquete no encontrado")

        nombre_archivo = f"{file.filename}"
        ruta_guardado = f"{UPLOAD_FOLDER}/{nombre_archivo}"
        
        with open(ruta_guardado, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        ubicacion_str = f"{latitud}, {longitud}"

        paquete.foto_evidencia = nombre_archivo
        paquete.ubicacion = ubicacion_str
        paquete.fecha = datetime.now()
        paquete.estado = "entregado"

        db.commit()
        
        return {"mensaje": "Entrega registrada", "foto": nombre_archivo}

    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Error al procesar entrega: {str(e)}")
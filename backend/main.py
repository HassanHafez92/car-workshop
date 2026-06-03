import os
import uuid
import datetime
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
import firebase_admin
from firebase_admin import credentials, firestore

app = FastAPI(title="نظام إدارة ورش السيارات - Python Backend API", version="1.0.0")

# Enable CORS for Flutter Web Localhost
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase Firestore Initialization with Local Mock Fallback
db = None
firebase_active = False

try:
    # Try initializing using default application credentials or environment
    firebase_admin.initialize_app()
    db = firestore.client()
    firebase_active = True
    print(">>> Firebase Admin SDK initialized successfully in Python Backend.")
except Exception as e:
    print(f">>> WARNING: Firebase SDK initialization failed ({e}). Falling back to Local Mock Database.")
    firebase_active = False

# Local Mock Database (Matches Initial Flutter Mock Data)
local_db: Dict[str, List[Dict[str, Any]]] = {
    "users": [
        {
            "id": "user_admin",
            "name": "حسن شعبان (المدير)",
            "username": "admin",
            "password": "admin123",
            "role": 0,
            "isActive": True
        },
        {
            "id": "user_reception",
            "name": "علي عثمان (الاستقبال)",
            "username": "reception",
            "password": "rec123",
            "role": 1,
            "isActive": True
        },
        {
            "id": "user_tech",
            "name": "م. محمود علي (الفني)",
            "username": "tech",
            "password": "tech123",
            "role": 2,
            "isActive": True
        },
        {
            "id": "user_store",
            "name": "سامي محمود (أمين المستودع)",
            "username": "store",
            "password": "store123",
            "role": 3,
            "isActive": True
        },
        {
            "id": "user_accountant",
            "name": "ممدوح رأفت (المحاسب)",
            "username": "accountant",
            "password": "acc123",
            "role": 4,
            "isActive": True
        }
    ],
    "customers": [
        {
            "id": "cust_1",
            "name": "أحمد محمد الخطيب",
            "phone": "01012345678",
            "email": "ahmed@example.com",
            "address": "الدقي، الجيزة، مصر",
            "type": "cash",
            "creditLimit": 0.0,
            "isActive": True
        },
        {
            "id": "cust_2",
            "name": "شركة النقل اللوجستي السريع",
            "phone": "0229876543",
            "email": "info@logistic-transport.com",
            "address": "مصر الجديدة، القاهرة",
            "type": "credit",
            "creditLimit": 50000.0,
            "isActive": True
        }
    ],
    "vehicles": [
        {
            "id": "veh_1",
            "customerId": "cust_1",
            "plateNumber": "أ ب ج 1234",
            "chassisNumber": "MRH53G12345678",
            "make": "تويوتا",
            "model": "كورولا",
            "year": "2021",
            "color": "فضي ميتاليك",
            "odometer": 65400,
            "notes": "صيانات دورية منتظمة"
        }
    ],
    "parts": [
        {
            "id": "part_1",
            "code": "OIL-5W30-SYN",
            "name": "زيت محرك تخليقي بالكامل 5W30 (4 لتر)",
            "category": "زيوت ومواد تزييت",
            "brand": "موبيل 1",
            "compatibleModels": "جميع الموديلات",
            "minStock": 10,
            "unit": "عبوة",
            "defaultPurchasePrice": 450.0,
            "defaultSellingPrice": 650.0,
            "targetMargin": 44.4,
            "location": "مستودع رئيسي - الرف أ3",
            "stockCount": 25
        }
    ],
    "job_cards": [],
    "invoices": [],
    "ledger_entries": [],
    "suppliers": [
        {
            "id": "supp_1",
            "name": "الشركة الوطنية لقطع غيار السيارات",
            "phone": "01234567890",
            "address": "وسط البلد، القاهرة",
            "paymentTerms": "credit",
            "isActive": True
        },
        {
            "id": "supp_2",
            "name": "موزع فلاتر وزيوت الأمل الدائري",
            "phone": "01123456789",
            "address": "المعادي، القاهرة",
            "paymentTerms": "cash",
            "isActive": True
        }
    ],
    "appointments": [
        {
            "id": "app_1",
            "customerId": "cust_1",
            "vehicleId": "veh_1",
            "dateTime": f"{datetime.datetime.now().strftime('%Y-%m-%d')} 10:00",
            "serviceType": "صيانة دورية 60 ألف كم",
            "status": "confirmed",
            "assignedBay": "مجرى رقم 1"
        }
    ],
    "stock_movements": [
        {
            "id": "mov_1",
            "partId": "part_1",
            "type": "receipt",
            "quantity": 25,
            "referenceId": "PINV-1002",
            "date": datetime.datetime.now().strftime("%Y-%m-%d"),
            "notes": "رصيد بداية المدة الافتراضي للمخزن"
        }
    ],
    "audit_logs": [
        {
            "id": "aud_init",
            "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
            "userRole": "Admin",
            "action": "تشغيل خادم بايثون",
            "details": "تم تشغيل خادم FastAPI بنجاح وتهيئة الاتصال بقاعدة البيانات."
        }
    ]
}

def log_audit(role: str, action: str, details: str):
    log_entry = {
        "id": f"aud_{int(datetime.datetime.now().timestamp() * 1000)}",
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "userRole": role,
        "action": action,
        "details": details
    }
    if firebase_active:
        db.collection("audit_logs").document(log_entry["id"]).set(log_entry)
    else:
        local_db["audit_logs"].insert(0, log_entry)

# --- Endpoints ---

@app.get("/api/status")
def get_status():
    return {
        "status": "online",
        "timestamp": datetime.datetime.now().isoformat(),
        "database_mode": "Firebase Cloud Firestore" if firebase_active else "Local Mock Database"
    }

# --- CRM Customers ---
@app.get("/api/customers")
def get_customers():
    if firebase_active:
        docs = db.collection("customers").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["customers"]

@app.post("/api/customers")
def add_customer(customer: Dict[str, Any] = Body(...)):
    customer["id"] = customer.get("id") or f"cust_{uuid.uuid4().hex[:12]}"
    customer["isActive"] = customer.get("isActive", True)
    
    if firebase_active:
        db.collection("customers").document(customer["id"]).set(customer)
    else:
        local_db["customers"].append(customer)
        
    log_audit("API Client", "إضافة عميل", f"تم تسجيل العميل: {customer['name']} عبر واجهة برمجة التطبيقات REST API.")
    return customer

# --- CRM Vehicles ---
@app.get("/api/vehicles")
def get_vehicles():
    if firebase_active:
        docs = db.collection("vehicles").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["vehicles"]

@app.post("/api/vehicles")
def add_vehicle(vehicle: Dict[str, Any] = Body(...)):
    vehicle["id"] = vehicle.get("id") or f"veh_{uuid.uuid4().hex[:12]}"
    
    if firebase_active:
        db.collection("vehicles").document(vehicle["id"]).set(vehicle)
    else:
        local_db["vehicles"].append(vehicle)
        
    log_audit("API Client", "إضافة سيارة", f"تسجيل سيارة لوحة {vehicle['plateNumber']} عبر واجهة برمجة التطبيقات.")
    return vehicle

# --- Inventory Parts ---
@app.get("/api/parts")
def get_parts():
    if firebase_active:
        docs = db.collection("parts").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["parts"]

@app.post("/api/parts/adjust")
def adjust_part_stock(part_id: str, change: int = Body(embed=True), reason: str = Body(embed=True)):
    if firebase_active:
        part_ref = db.collection("parts").document(part_id)
        part_doc = part_ref.get()
        if not part_doc.exists:
            raise HTTPException(status_code=404, detail="Part not found")
        part_data = part_doc.to_dict()
        new_qty = part_data.get("stockCount", 0) + change
        part_ref.update({"stockCount": new_qty})
        
        # Log stock movement
        mov_id = f"mov_{uuid.uuid4().hex[:12]}"
        db.collection("stock_movements").document(mov_id).set({
            "id": mov_id,
            "partId": part_id,
            "type": "adjustment",
            "quantity": change,
            "date": datetime.datetime.now().strftime("%Y-%m-%d"),
            "notes": reason
        })
        log_audit("API Client", "تعديل مخزون جرد", f"تعديل جرد لقطعة {part_data['name']} بمقدار {change}.")
        return {"partId": part_id, "newStockCount": new_qty}
    else:
        for part in local_db["parts"]:
            if part["id"] == part_id:
                part["stockCount"] += change
                log_audit("API Client", "تعديل مخزون جرد", f"تعديل جرد لقطعة {part['name']} بمقدار {change}.")
                return {"partId": part_id, "newStockCount": part["stockCount"]}
        raise HTTPException(status_code=404, detail="Part not found")

# --- Job Cards ---
@app.get("/api/jobcards")
def get_jobcards():
    if firebase_active:
        docs = db.collection("job_cards").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["job_cards"]

@app.post("/api/jobcards")
def create_jobcard(job: Dict[str, Any] = Body(...)):
    job["id"] = job.get("id") or f"job_{uuid.uuid4().hex[:12]}"
    job["status"] = job.get("status", "New")
    
    if firebase_active:
        db.collection("job_cards").document(job["id"]).set(job)
    else:
        idx = -1
        for i, jc in enumerate(local_db["job_cards"]):
            if jc["id"] == job["id"]:
                idx = i
                break
        if idx != -1:
            local_db["job_cards"][idx] = job
        else:
            local_db["job_cards"].append(job)
        
    log_audit("API Client", "فتح/تعديل كرت صيانة", f"كرت صيانة {job.get('cardNo')} لسيارة عميل.")
    return job

# --- Suppliers ---
@app.get("/api/suppliers")
def get_suppliers():
    if firebase_active:
        docs = db.collection("suppliers").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["suppliers"]

@app.post("/api/suppliers")
def add_supplier(supplier: Dict[str, Any] = Body(...)):
    supplier["id"] = supplier.get("id") or f"supp_{uuid.uuid4().hex[:12]}"
    supplier["isActive"] = supplier.get("isActive", True)
    if firebase_active:
        db.collection("suppliers").document(supplier["id"]).set(supplier)
    else:
        local_db["suppliers"].append(supplier)
    log_audit("API Client", "إضافة مورد", f"تم تسجيل المورد: {supplier['name']} عبر واجهة برمجة التطبيقات REST API.")
    return supplier

# --- Parts ---
@app.post("/api/parts")
def add_part(part: Dict[str, Any] = Body(...)):
    part["id"] = part.get("id") or f"part_{uuid.uuid4().hex[:12]}"
    if firebase_active:
        db.collection("parts").document(part["id"]).set(part)
    else:
        local_db["parts"].append(part)
    log_audit("API Client", "إضافة قطعة غيار", f"تم تعريف قطعة غيار: {part['name']} عبر واجهة برمجة التطبيقات REST API.")
    return part

# --- Stock Movements ---
@app.get("/api/stockmovements")
def get_stockmovements():
    if firebase_active:
        docs = db.collection("stock_movements").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["stock_movements"]

@app.post("/api/stockmovements")
def add_stockmovement(movement: Dict[str, Any] = Body(...)):
    movement["id"] = movement.get("id") or f"mov_{uuid.uuid4().hex[:12]}"
    if firebase_active:
        db.collection("stock_movements").document(movement["id"]).set(movement)
    else:
        local_db["stock_movements"].append(movement)
    return movement

# --- Appointments ---
@app.get("/api/appointments")
def get_appointments():
    if firebase_active:
        docs = db.collection("appointments").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["appointments"]

@app.post("/api/appointments")
def add_appointment(appointment: Dict[str, Any] = Body(...)):
    appointment["id"] = appointment.get("id") or f"app_{uuid.uuid4().hex[:12]}"
    if firebase_active:
        db.collection("appointments").document(appointment["id"]).set(appointment)
    else:
        idx = -1
        for i, app in enumerate(local_db["appointments"]):
            if app["id"] == appointment["id"]:
                idx = i
                break
        if idx != -1:
            local_db["appointments"][idx] = appointment
        else:
            local_db["appointments"].append(appointment)
    log_audit("API Client", "حجز موعد", f"حجز موعد صيانة للعميل: {appointment.get('customerId')} بتاريخ {appointment.get('dateTime')}.")
    return appointment

# --- Invoices ---
@app.get("/api/invoices")
def get_invoices():
    if firebase_active:
        docs = db.collection("invoices").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["invoices"]

@app.post("/api/invoices")
def add_invoice(invoice: Dict[str, Any] = Body(...)):
    invoice["id"] = invoice.get("id") or f"inv_{uuid.uuid4().hex[:12]}"
    if firebase_active:
        db.collection("invoices").document(invoice["id"]).set(invoice)
    else:
        idx = -1
        for i, inv in enumerate(local_db["invoices"]):
            if inv["id"] == invoice["id"]:
                idx = i
                break
        if idx != -1:
            local_db["invoices"][idx] = invoice
        else:
            local_db["invoices"].append(invoice)
    log_audit("API Client", "إصدار فاتورة", f"تسجيل فاتورة رقم {invoice.get('invoiceNo')} بقيمة {invoice.get('netTotal')} ج.م.")
    return invoice

# --- Ledger Entries ---
@app.get("/api/ledgerentries")
def get_ledgerentries():
    if firebase_active:
        docs = db.collection("ledger_entries").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["ledger_entries"]

@app.post("/api/ledgerentries")
def add_ledgerentry(entry: Dict[str, Any] = Body(...)):
    entry["id"] = entry.get("id") or f"led_{uuid.uuid4().hex[:12]}"
    if firebase_active:
        db.collection("ledger_entries").document(entry["id"]).set(entry)
    else:
        local_db["ledger_entries"].append(entry)
    return entry

# --- Audit Logs ---
@app.get("/api/auditlogs")
def get_auditlogs():
    if firebase_active:
        docs = db.collection("audit_logs").order_by("timestamp", direction=firestore.Query.DESCENDING).stream()
        return [doc.to_dict() for doc in docs]
    return local_db["audit_logs"]

# --- Authentication Endpoints ---
@app.post("/api/auth/login")
def login(payload: Dict[str, Any] = Body(...)):
    username = payload.get("username", "").strip().lower()
    password = payload.get("password", "")
    
    if firebase_active:
        docs = db.collection("users").where("username", "==", username).stream()
        users = [doc.to_dict() for doc in docs]
    else:
        users = local_db["users"]
        
    for user in users:
        if user["username"].lower() == username and user["password"] == password:
            if not user["isActive"]:
                raise HTTPException(status_code=400, detail="الحساب معطل حالياً.")
            log_audit(user["name"], "تسجيل الدخول", f"تم تسجيل دخول المستخدم {user['name']} بنجاح.")
            return user
            
    raise HTTPException(status_code=401, detail="اسم المستخدم أو كلمة المرور غير صحيحة.")

@app.get("/api/auth/users")
def get_users():
    if firebase_active:
        docs = db.collection("users").stream()
        return [doc.to_dict() for doc in docs]
    return local_db["users"]

@app.post("/api/auth/register")
def register(user: Dict[str, Any] = Body(...)):
    user["id"] = user.get("id") or f"user_{uuid.uuid4().hex[:12]}"
    user["isActive"] = user.get("isActive", True)
    if firebase_active:
        db.collection("users").document(user["id"]).set(user)
    else:
        local_db["users"].append(user)
    log_audit("Admin", "تسجيل مستخدم جديد", f"تم إنشاء حساب جديد لـ {user['name']}.")
    return user

@app.post("/api/auth/users/{user_id}/status")
def toggle_user_status(user_id: str, is_active: bool = Body(embed=True)):
    if firebase_active:
        user_ref = db.collection("users").document(user_id)
        if not user_ref.get().exists:
            raise HTTPException(status_code=404, detail="المستخدم غير موجود.")
        user_ref.update({"isActive": is_active})
        user_data = user_ref.get().to_dict()
        user_name = user_data.get("name", "غير معروف")
    else:
        found_user = None
        for user in local_db["users"]:
            if user["id"] == user_id:
                user["isActive"] = is_active
                found_user = user
                break
        if not found_user:
            raise HTTPException(status_code=404, detail="المستخدم غير موجود.")
        user_name = found_user["name"]
        
    log_audit("Admin", "تعديل حالة مستخدم", f"تمت إعادة تعيين حالة المستخدم {user_name} إلى {'نشط' if is_active else 'معطل'}.")
    return {"id": user_id, "isActive": is_active}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)

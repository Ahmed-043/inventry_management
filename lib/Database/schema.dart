final Map<String, Map<String, String>> dbSchema = {
  'info': {
    'db_name': 'TEXT NOT NULL',
    'description': 'TEXT',
    'image': 'BLOB',
    'location' : 'TEXT DEFAULT ""',
    'phone' : 'TEXT DEFAULT ""',
    'backupDir' : 'TEXT DEFAULT ""', // backup Folder
    'lastBackup' : 'INTEGER DEFAULT 0',
    'backupFreq' : 'INTEGER DEFAULT 0 CHECK(backupFreq IN (0,1,2,3))' // 0: None, 1: Daily, 2: Weekly, 3: Monthly
  },
  'products': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL DEFAULT ""',
    'base_price': 'REAL DEFAULT 0 CHECK(base_price >= 0)',
    'stock': 'INTEGER DEFAULT 0 CHECK(stock >= 0)',
    'low_stock': 'INTEGER DEFAULT -1 CHECK(low_stock >= -1)',
    'weight': 'REAL DEFAULT 0 CHECK(weight >= 0)',
    'sku': 'TEXT UNIQUE',
    'active': 'BOOL DEFAULT TRUE',
    'sold': 'INTEGER DEFAULT 0 CHECK(sold >= 0)',
    'image': 'BLOB',
    'components': "TEXT NOT NULL DEFAULT ''",
    'category': 'INTEGER DEFAULT 0',
    'description': 'TEXT',
  },
  'categories':{
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL DEFAULT ""',
    'sequence': 'INTEGER DEFAULT 0',
  },
  'persons': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'name': 'TEXT NOT NULL',
    'phone': 'TEXT DEFAULT ""',
    'address': 'TEXT DEFAULT ""',
    'email': 'TEXT DEFAULT ""',
    'image': 'BLOB',
    'payment': 'REAL DEFAULT 0',
    'personType': "TEXT CHECK(personType IN ('customer','supplier')) NOT NULL DEFAULT 'customer'",
    'type': "TEXT CHECK(type IN ('major','local')) NOT NULL DEFAULT 'local'",
  },
  'orders': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'person_id': 'INTEGER DEFAULT 0',
    'name': 'TEXT DEFAULT ""',
    'order_type': "TEXT CHECK(order_type IN ('buy','sell')) NOT NULL",
    'total_amount': 'REAL DEFAULT 0',
    'paid_amount': 'REAL DEFAULT 0',
    'total_weight': 'REAL DEFAULT 0',
    'tax' : 'TEXT DEFAULT ""', //'%,0.0'
    'discount' : 'TEXT DEFAULT ""', //'Rs,0.0'
    'order_status': "TEXT CHECK(order_status IN ('Pending','Completed','Canceled')) NOT NULL DEFAULT 'Pending'",
    'payment_status': "TEXT CHECK(payment_status IN ('Pending','Paid','Overdue')) NOT NULL DEFAULT 'Pending'",
    'order_timestamp': 'INTEGER NOT NULL',
    'due_date': 'INTEGER DEFAULT 0',
    'remark': 'TEXT DEFAULT ""',
  },
  'order_items': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'order_id': 'INTEGER NOT NULL',
    'product_id': 'INTEGER NOT NULL',
    'name': 'TEXT DEFAULT ""',
    'sku': 'TEXT DEFAULT ""',
    'quantity': 'REAL NOT NULL CHECK(quantity > 0)',
    'weight': 'REAL CHECK(quantity > 0) DEFAULT 0',
    'price': 'REAL NOT NULL DEFAULT 0',
    'discount': 'REAL DEFAULT 0',
    'tax': 'REAL DEFAULT 0',
  },
  'payment_transactions': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'person_id': 'INTEGER DEFAULT 0',
    'name': 'TEXT DEFAULT ""',
    'order_id': 'INTEGER DEFAULT 0',
    'amount': 'REAL NOT NULL DEFAULT 0',
    'paid_amount': 'REAL NOT NULL DEFAULT 0',
    'payment_status': "TEXT CHECK(payment_status IN ('Pending','Paid','Overdue')) NOT NULL DEFAULT 'Paid'",
    'due_date': 'INTEGER DEFAULT 0',
    'payment_method': "TEXT CHECK(payment_method IN ('Digital','Cash','Bank','Other')) NOT NULL DEFAULT 'Cash'",
    'timestamp': 'INTEGER NOT NULL DEFAULT 0',
    'payment_timestamp': 'INTEGER NOT NULL DEFAULT 0',
    'remark': 'TEXT DEFAULT ""',
  },
  'inventory_movements': {
    'id': 'INTEGER PRIMARY KEY AUTOINCREMENT',
    'product_id': 'INTEGER NOT NULL',
    'order_id': 'INTEGER DEFAULT 0',
    'order_item_id': 'INTEGER DEFAULT 0',
    'movement_type':
    "TEXT NOT NULL CHECK(movement_type IN ("
        "'Purchase',"
        "'Sale',"
        "'Purchase Return',"
        "'Sales Return',"
        "'Stock Adjustment',"
        "'Opening Stock',"
        "'Stock Transfer',"
        "'Stock Correction'"
        "))",
    'quantity_change': 'INTEGER NOT NULL',
    'stock_before': 'INTEGER NOT NULL DEFAULT 0',
    'stock_after': 'INTEGER NOT NULL DEFAULT 0',
    'unit_cost': 'REAL DEFAULT 0',
    'unit_price': 'INTEGER DEFAULT 0',
    'total_value': 'INTEGER DEFAULT 0',
    'location': 'TEXT DEFAULT ""',
    'timestamp': 'INTEGER NOT NULL',
    'remark': 'TEXT DEFAULT ""',
  },
};

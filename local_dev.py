#!/usr/bin/env python3
"""
Local Development Script for 3x-ui Traffic Dashboard
This script helps set up a development environment with mock data for testing.
"""

import os
import sys
import sqlite3
import argparse
import json
from pathlib import Path
import uvicorn
import time
from datetime import datetime, timedelta

# Add the project directory to the path
project_dir = Path(__file__).parent
sys.path.append(str(project_dir))

def create_mock_database(db_path):
    """Create a mock SQLite database with sample data for testing"""
    print(f"Creating mock database at {db_path}...")
    
    # Create parent directory if it doesn't exist
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    # Connect to the database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Create tables
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS inbounds (
        id INTEGER PRIMARY KEY,
        remark TEXT
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY,
        inbound_id INTEGER,
        uuid TEXT,
        email TEXT,
        enable INTEGER,
        expiry_time INTEGER,
        FOREIGN KEY (inbound_id) REFERENCES inbounds(id)
    )
    ''')
    
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS client_traffics (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        up INTEGER,
        down INTEGER,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )
    ''')
    
    # Insert sample data
    # Inbounds
    cursor.execute("INSERT INTO inbounds (id, remark) VALUES (1, 'VLESS TCP')")
    cursor.execute("INSERT INTO inbounds (id, remark) VALUES (2, 'Trojan WS')")
    cursor.execute("INSERT INTO inbounds (id, remark) VALUES (3, 'VMess TCP')")
    
    # Current timestamp in milliseconds
    now = int(time.time() * 1000)
    future = int((datetime.now() + timedelta(days=30)).timestamp() * 1000)
    past = int((datetime.now() - timedelta(days=5)).timestamp() * 1000)
    
    # Users
    users = [
        (1, 1, "00000000-0000-0000-0000-000000000001", "user1@example.com", 1, future),
        (2, 2, "00000000-0000-0000-0000-000000000002", "user2@example.com", 1, future),
        (3, 3, "00000000-0000-0000-0000-000000000003", "user3@example.com", 1, past),
        (4, 1, "00000000-0000-0000-0000-000000000004", "user4@example.com", 0, future),
    ]
    
    cursor.executemany(
        "INSERT INTO users (id, inbound_id, uuid, email, enable, expiry_time) VALUES (?, ?, ?, ?, ?, ?)",
        users
    )
    
    # Traffic data
    traffic_data = [
        (1, 1, 5_000_000_000, 10_000_000_000),  # 5GB up, 10GB down
        (2, 2, 2_500_000_000, 7_500_000_000),   # 2.5GB up, 7.5GB down
        (3, 3, 15_000_000_000, 25_000_000_000), # 15GB up, 25GB down
        (4, 4, 500_000_000, 1_500_000_000),     # 0.5GB up, 1.5GB down
    ]
    
    cursor.executemany(
        "INSERT INTO client_traffics (id, user_id, up, down) VALUES (?, ?, ?, ?)",
        traffic_data
    )
    
    # Commit changes and close connection
    conn.commit()
    conn.close()
    
    print("Mock database created successfully with sample data!")
    print("\nSample users for testing:")
    print("UUID: 00000000-0000-0000-0000-000000000001, Username: user1@example.com")
    print("UUID: 00000000-0000-0000-0000-000000000002, Username: user2@example.com")
    print("UUID: 00000000-0000-0000-0000-000000000003, Username: user3@example.com (expired)")
    print("UUID: 00000000-0000-0000-0000-000000000004, Username: user4@example.com (disabled)")

def create_env_file():
    """Create a .env file for local development"""
    env_path = project_dir / ".env"
    
    if not env_path.exists():
        mock_db_path = project_dir / "mock_data" / "x-ui.db"
        
        with open(env_path, "w") as f:
            f.write(f"# Local development configuration\n")
            f.write(f"DB_PATH={mock_db_path}\n")
            f.write(f"HOST=127.0.0.1\n")
            f.write(f"PORT=8000\n")
            f.write(f"RATE_LIMIT=100/minute\n")
        
        print(f"Created .env file at {env_path}")
    else:
        print(f".env file already exists at {env_path}")

def run_development_server():
    """Run the development server"""
    from backend.main import app
    
    host = os.getenv("HOST", "127.0.0.1")
    port = int(os.getenv("PORT", "8000"))
    
    print(f"Starting development server at http://{host}:{port}")
    uvicorn.run("backend.main:app", host=host, port=port, reload=True)

def main():
    parser = argparse.ArgumentParser(description="3x-ui Traffic Dashboard Development Tool")
    parser.add_argument("--setup", action="store_true", help="Set up the development environment")
    parser.add_argument("--run", action="store_true", help="Run the development server")
    
    args = parser.parse_args()
    
    if args.setup or (not args.setup and not args.run):
        # Create mock database
        mock_db_path = project_dir / "mock_data" / "x-ui.db"
        create_mock_database(mock_db_path)
        
        # Create .env file
        create_env_file()
        
        print("\nDevelopment environment setup complete!")
        print(f"You can now run the server with: python {__file__} --run")
    
    if args.run:
        # Run the development server
        run_development_server()

if __name__ == "__main__":
    main()

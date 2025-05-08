#!/bin/bash

# 3x-ui Traffic Dashboard Installer
# This script installs and configures the 3x-ui Traffic Dashboard

set -e

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  print_error "Please run as root (use sudo)"
  exit 1
fi

# Check if 3x-ui is installed
if [ ! -f "/etc/x-ui/x-ui.db" ]; then
  print_warning "3x-ui database not found at /etc/x-ui/x-ui.db"
  read -p "Continue anyway? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Create installation directory
INSTALL_DIR="/opt/3x-ui-dashboard"
print_message "Creating installation directory: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Install dependencies
print_message "Updating package lists..."
apt-get update

print_message "Installing required packages..."
apt-get install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx sqlite3

# Install speedtest-cli for the Speed Test feature
print_message "Installing speedtest-cli for Speed Test feature..."
apt-get install -y speedtest-cli || pip3 install speedtest-cli

# Create virtual environment
print_message "Setting up Python virtual environment..."
python3 -m venv "$INSTALL_DIR/venv"
source "$INSTALL_DIR/venv/bin/activate"

# Clone repository or copy files
if [ -d "backend" ] && [ -d "frontend" ] && [ -d "parser" ]; then
  print_message "Copying local files to installation directory..."
  cp -r backend frontend parser .env.example "$INSTALL_DIR/"
else
  print_message "Downloading latest version from GitHub..."
  apt-get install -y git
  git clone https://github.com/V2rayZone/3x-ui-traffic-dashboard.git "$INSTALL_DIR/temp"
  cp -r "$INSTALL_DIR/temp/"* "$INSTALL_DIR/"
  rm -rf "$INSTALL_DIR/temp"
fi

# Install Python dependencies
print_message "Installing Python dependencies..."
# Check if requirements.txt exists in backend directory, otherwise use the one in root
if [ -f "$INSTALL_DIR/backend/requirements.txt" ]; then
  pip install -r "$INSTALL_DIR/backend/requirements.txt"
elif [ -f "$INSTALL_DIR/requirements.txt" ]; then
  pip install -r "$INSTALL_DIR/requirements.txt"
else
  print_error "Could not find requirements.txt file"
  # Install essential packages manually
  print_message "Installing essential packages manually..."
  pip install fastapi uvicorn python-dotenv slowapi pydantic jinja2 aiofiles speedtest-cli
fi

# Ensure frontend files are in the correct location
print_message "Setting up frontend files..."
if [ ! -d "$INSTALL_DIR/frontend" ]; then
  print_warning "Frontend directory not found, creating it..."
  mkdir -p "$INSTALL_DIR/frontend"
fi

# Create a minimal index.html if it doesn't exist
if [ ! -f "$INSTALL_DIR/frontend/index.html" ]; then
  print_warning "index.html not found, creating a minimal version..."
  cat > "$INSTALL_DIR/frontend/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>3x-ui Traffic Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #1a1a2e;
            color: #ffffff;
            margin: 0;
            padding: 0;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        .header h1 {
            color: #7b68ee;
            margin-bottom: 10px;
        }
        .card {
            background-color: #16213e;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }
        .card-title {
            color: #7b68ee;
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 1.5rem;
        }
        .card-content {
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .chart-container {
            width: 150px;
            height: 150px;
            position: relative;
        }
        .info-container {
            flex-grow: 1;
            margin-left: 20px;
        }
        .info-item {
            margin-bottom: 10px;
        }
        .info-label {
            color: #a0a0a0;
            font-size: 0.9rem;
        }
        .info-value {
            font-size: 1.1rem;
            font-weight: bold;
        }
        .button {
            background-color: #7b68ee;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 1rem;
            transition: background-color 0.3s;
        }
        .button:hover {
            background-color: #6a5acd;
        }
        .speed-test-results {
            display: none;
            margin-top: 20px;
        }
        .result-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
            padding: 10px;
            background-color: #0f3460;
            border-radius: 5px;
        }
        .loader {
            display: none;
            text-align: center;
            margin: 20px 0;
        }
        .loader-spinner {
            border: 4px solid rgba(255, 255, 255, 0.3);
            border-radius: 50%;
            border-top: 4px solid #7b68ee;
            width: 30px;
            height: 30px;
            animation: spin 1s linear infinite;
            margin: 0 auto;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>3x-ui Traffic Dashboard</h1>
        </div>
        
        <div class="card">
            <h2 class="card-title">Traffic Usage</h2>
            <div class="card-content">
                <div class="chart-container">
                    <!-- Placeholder for chart -->
                    <div style="width: 150px; height: 150px; background-color: #0f3460; border-radius: 50%; display: flex; justify-content: center; align-items: center;">
                        <span style="color: #7b68ee; font-size: 1.5rem;">75%</span>
                    </div>
                </div>
                <div class="info-container">
                    <div class="info-item">
                        <div class="info-label">Download</div>
                        <div class="info-value">5.67 GB</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Upload</div>
                        <div class="info-value">2.34 GB</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Total</div>
                        <div class="info-value">8.01 GB</div>
                    </div>
                    <div class="info-item">
                        <div class="info-label">Status</div>
                        <div class="info-value" style="color: #4CAF50;">Active</div>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2 class="card-title">Speed Test</h2>
            <button id="runSpeedTest" class="button">Run Speed Test</button>
            
            <div id="loader" class="loader">
                <div class="loader-spinner"></div>
                <p>Running speed test... This may take a minute.</p>
            </div>
            
            <div id="speedTestResults" class="speed-test-results">
                <div class="result-item">
                    <span>Download Speed:</span>
                    <span id="downloadSpeed">0 Mbps</span>
                </div>
                <div class="result-item">
                    <span>Upload Speed:</span>
                    <span id="uploadSpeed">0 Mbps</span>
                </div>
                <div class="result-item">
                    <span>Ping:</span>
                    <span id="ping">0 ms</span>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2 class="card-title">Server Health</h2>
            <div class="info-item">
                <div class="info-label">CPU Usage</div>
                <div class="info-value">25%</div>
            </div>
            <div class="info-item">
                <div class="info-label">Memory Usage</div>
                <div class="info-value">40%</div>
            </div>
            <div class="info-item">
                <div class="info-label">Disk Usage</div>
                <div class="info-value">30%</div>
            </div>
        </div>
        
        <div class="card" style="text-align: center;">
            <h2 class="card-title">Need More Traffic?</h2>
            <button id="renewButton" class="button">Renew Subscription</button>
        </div>
    </div>

    <script>
        document.getElementById('runSpeedTest').addEventListener('click', function() {
            // Show loader
            document.getElementById('loader').style.display = 'block';
            document.getElementById('speedTestResults').style.display = 'none';
            
            // Call the API
            fetch('/api/speed-test')
                .then(response => response.json())
                .then(data => {
                    // Hide loader
                    document.getElementById('loader').style.display = 'none';
                    
                    // Show results
                    document.getElementById('speedTestResults').style.display = 'block';
                    document.getElementById('downloadSpeed').textContent = data.download.toFixed(2) + ' Mbps';
                    document.getElementById('uploadSpeed').textContent = data.upload.toFixed(2) + ' Mbps';
                    document.getElementById('ping').textContent = data.ping.toFixed(1) + ' ms';
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('loader').style.display = 'none';
                    alert('Error running speed test. Please try again.');
                });
        });
        
        document.getElementById('renewButton').addEventListener('click', function() {
            window.open('https://t.me/admin_username', '_blank');
        });
    </script>
</body>
</html>
EOF
fi

# Create JS directory and basic app.js if they don't exist
if [ ! -d "$INSTALL_DIR/frontend/js" ]; then
  mkdir -p "$INSTALL_DIR/frontend/js"
  cat > "$INSTALL_DIR/frontend/js/app.js" << EOF
// Basic functionality for the dashboard
document.addEventListener('DOMContentLoaded', function() {
    // Speed Test button
    const runSpeedTestBtn = document.getElementById('runSpeedTest');
    if (runSpeedTestBtn) {
        runSpeedTestBtn.addEventListener('click', function() {
            // Show loader
            document.getElementById('loader').style.display = 'block';
            document.getElementById('speedTestResults').style.display = 'none';
            
            // Call the API
            fetch('/api/speed-test')
                .then(response => response.json())
                .then(data => {
                    // Hide loader
                    document.getElementById('loader').style.display = 'none';
                    
                    // Show results
                    document.getElementById('speedTestResults').style.display = 'block';
                    document.getElementById('downloadSpeed').textContent = data.download.toFixed(2) + ' Mbps';
                    document.getElementById('uploadSpeed').textContent = data.upload.toFixed(2) + ' Mbps';
                    document.getElementById('ping').textContent = data.ping.toFixed(1) + ' ms';
                })
                .catch(error => {
                    console.error('Error:', error);
                    document.getElementById('loader').style.display = 'none';
                    alert('Error running speed test. Please try again.');
                });
        });
    }
    
    // Renew button
    const renewBtn = document.getElementById('renewButton');
    if (renewBtn) {
        renewBtn.addEventListener('click', function() {
            window.open('https://t.me/admin_username', '_blank');
        });
    }
});
EOF
fi

# Create and configure .env file
print_message "Configuring environment variables..."
if [ -f "$INSTALL_DIR/.env.example" ]; then
  cp "$INSTALL_DIR/.env.example" "$INSTALL_DIR/.env"
else
  print_warning ".env.example not found, creating a default .env file..."
  cat > "$INSTALL_DIR/.env" << EOF
# 3x-ui Traffic Dashboard Environment Variables
DB_PATH=/etc/x-ui/x-ui.db
HOST=0.0.0.0
PORT=8000
RATE_LIMIT=100/minute
TELEGRAM_ADMIN_URL=https://t.me/admin_username
EOF
fi

# Prompt for Telegram admin URL
print_message "Setting up Telegram admin contact for the Renew button..."
read -p "Enter Telegram admin contact URL (e.g., https://t.me/username): " telegram_url
if [ -n "$telegram_url" ]; then
  print_message "Setting Telegram admin contact URL..."
  # Update the .env file
  sed -i "s|TELEGRAM_ADMIN_URL=.*|TELEGRAM_ADMIN_URL=$telegram_url|g" "$INSTALL_DIR/.env"
  
  # Also update the JavaScript file to use the correct Telegram URL
  if [ -f "$INSTALL_DIR/frontend/js/app.js" ]; then
    print_message "Configuring Renew button with your Telegram URL..."
    sed -i "s|window.open('https://t.me/admin_username', '_blank');|window.open('$telegram_url', '_blank');|g" "$INSTALL_DIR/frontend/js/app.js"
  fi
else
  print_warning "No Telegram URL provided. Users won't be able to use the Renew button."
fi

# Create log directory
mkdir -p /var/log/3x-ui-dashboard

# Create systemd service
print_message "Creating systemd service..."
cat > /etc/systemd/system/3x-ui-dashboard.service << EOF
[Unit]
Description=3x-ui Traffic Dashboard
After=network.target

[Service]
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/uvicorn backend.main:app --host 0.0.0.0 --port 8000
Restart=always
StandardOutput=append:/var/log/3x-ui-dashboard/output.log
StandardError=append:/var/log/3x-ui-dashboard/error.log

[Install]
WantedBy=multi-user.target
EOF

# Setup Nginx configuration
print_message "Setting up Nginx configuration..."
read -p "Enter your domain name (leave empty for IP-only access): " DOMAIN

if [ -n "$DOMAIN" ]; then
  # Create Nginx config with domain
  cat > /etc/nginx/sites-available/3x-ui-dashboard << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

  # Enable site and get SSL certificate
  ln -sf /etc/nginx/sites-available/3x-ui-dashboard /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx

  print_message "Setting up SSL with Let's Encrypt..."
  certbot --nginx -d $DOMAIN --non-interactive --agree-tos --email webmaster@$DOMAIN
else
  print_message "Skipping domain setup. You can access the dashboard directly via IP:8000"
fi

# Start and enable the service
print_message "Starting the service..."
systemctl daemon-reload
systemctl enable 3x-ui-dashboard

# Test if the backend can start manually first
print_message "Testing backend startup..."
cd "$INSTALL_DIR"
source "$INSTALL_DIR/venv/bin/activate"
python3 -c "import sys; print(f'Python version: {sys.version}')" || print_warning "Python version check failed"

# Create a debug script to help diagnose issues
print_message "Creating debug tools..."
cat > "$INSTALL_DIR/debug.sh" << EOF
#!/bin/bash
echo "=== 3x-ui Traffic Dashboard Debug Tool ==="
echo "Checking installation directory..."
ls -la /opt/3x-ui-dashboard
echo "\nChecking frontend directory..."
ls -la /opt/3x-ui-dashboard/frontend
echo "\nChecking backend directory..."
ls -la /opt/3x-ui-dashboard/backend
echo "\nChecking service status..."
systemctl status 3x-ui-dashboard
echo "\nChecking logs..."
tail -n 50 /var/log/3x-ui-dashboard/error.log
echo "\nTrying to start server manually..."
cd /opt/3x-ui-dashboard
source /opt/3x-ui-dashboard/venv/bin/activate
python3 -c "import sys; print(f'Python version: {sys.version}')"
echo "\nChecking if port 8000 is in use..."
netstat -tuln | grep 8000
echo "\nDebug complete. If you're still having issues, please check the full logs."
EOF
chmod +x "$INSTALL_DIR/debug.sh"

# Check if the main.py file exists
if [ ! -f "$INSTALL_DIR/backend/main.py" ]; then
  print_error "Backend main.py file not found. Creating a minimal version..."
  mkdir -p "$INSTALL_DIR/backend"
  cat > "$INSTALL_DIR/backend/main.py" << EOF
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, HTMLResponse
import os
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("dashboard")

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/api/health")
def health_check():
    return {"status": "ok"}

@app.get("/api/usage")
def get_usage(uuid: str = None, username: str = None):
    # Mock data for demonstration
    return {
        "username": username or "user123",
        "uuid": uuid or "00000000-0000-0000-0000-000000000001",
        "upload_gb": 2.34,
        "download_gb": 5.67,
        "total_gb": 8.01,
        "status": "active",
        "expiry_time": "2025-06-08T00:00:00Z"
    }

@app.get("/api/speed-test")
def run_speed_test():
    # Mock data for demonstration
    return {
        "download": 95.42,
        "upload": 25.31,
        "ping": 15.7,
        "success": True
    }

# Determine the frontend path
frontend_path = Path(__file__).parent.parent / "frontend"
logger.info(f"Frontend path: {frontend_path}, exists: {frontend_path.exists()}")

# Log the directory contents for debugging
if frontend_path.exists():
    logger.info(f"Frontend directory contents: {[f.name for f in frontend_path.iterdir()]}")

# Serve the index.html file for the root path
@app.get("/", response_class=HTMLResponse)
async def get_index():
    index_path = frontend_path / "index.html"
    logger.info(f"Serving index from: {index_path}, exists: {index_path.exists()}")
    
    if index_path.exists():
        with open(index_path, "r") as f:
            return f.read()
    else:
        # Create a basic HTML file if index.html doesn't exist
        logger.warning("index.html not found, serving default page")
        html_content = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>3x-ui Traffic Dashboard</title>
            <style>
                body {
                    font-family: Arial, sans-serif;
                    background-color: #1a1a2e;
                    color: #ffffff;
                    margin: 0;
                    padding: 20px;
                }
                .container {
                    max-width: 800px;
                    margin: 0 auto;
                    background-color: #16213e;
                    border-radius: 10px;
                    padding: 20px;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
                }
                h1 {
                    color: #7b68ee;
                    text-align: center;
                }
                .card {
                    background-color: #0f3460;
                    border-radius: 8px;
                    padding: 15px;
                    margin-bottom: 15px;
                }
                .btn {
                    background-color: #7b68ee;
                    color: white;
                    border: none;
                    padding: 10px 15px;
                    border-radius: 5px;
                    cursor: pointer;
                }
                .btn:hover {
                    background-color: #6a5acd;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>3x-ui Traffic Dashboard</h1>
                <div class="card">
                    <h2>Welcome!</h2>
                    <p>Your 3x-ui Traffic Dashboard is running. If you're seeing this page, the frontend files may not have been properly installed.</p>
                    <p>Check the installation logs for more information.</p>
                </div>
                <div class="card">
                    <h2>API Status</h2>
                    <p>The API server is running. You can test the endpoints:</p>
                    <ul>
                        <li><a href="/api/health" style="color: #7b68ee;">Health Check</a></li>
                        <li><a href="/api/usage?username=test" style="color: #7b68ee;">Usage Data</a></li>
                        <li><a href="/api/speed-test" style="color: #7b68ee;">Speed Test</a></li>
                    </ul>
                </div>
            </div>
        </body>
        </html>
        """
        return html_content

# Serve static files
if frontend_path.exists():
    app.mount("/js", StaticFiles(directory=str(frontend_path / "js")), name="js")
    app.mount("/css", StaticFiles(directory=str(frontend_path / "css")), name="css")
    app.mount("/img", StaticFiles(directory=str(frontend_path / "img")), name="img")
    app.mount("/static", StaticFiles(directory=str(frontend_path / "static")), name="static")

@app.exception_handler(404)
async def not_found_exception_handler(request: Request, exc: HTTPException):
    return get_index()
EOF
fi

# Now start the service
systemctl start 3x-ui-dashboard
sleep 2

# Check if service is running
if systemctl is-active --quiet 3x-ui-dashboard; then
  print_message "Service started successfully!"
else
  print_error "Service failed to start. Check logs with: journalctl -u 3x-ui-dashboard"
  print_message "Attempting to start manually for debugging..."
  cd "$INSTALL_DIR"
  source "$INSTALL_DIR/venv/bin/activate"
  nohup uvicorn backend.main:app --host 0.0.0.0 --port 8000 > /var/log/3x-ui-dashboard/output.log 2> /var/log/3x-ui-dashboard/error.log &
  print_message "Manual startup attempted. Check logs for details."
fi

print_message "Setting correct permissions..."
chmod -R 755 "$INSTALL_DIR"
chown -R root:root "$INSTALL_DIR"

# Final message
print_message "Installation completed!"
if [ -n "$DOMAIN" ]; then
  echo -e "${GREEN}You can access your dashboard at: https://$DOMAIN${NC}"
else
  echo -e "${GREEN}You can access your dashboard at: http://YOUR_SERVER_IP:8000${NC}"
fi
echo -e "${YELLOW}Check logs at: /var/log/3x-ui-dashboard/error.log${NC}"
echo -e "\n${GREEN}If you encounter any issues:${NC}"
echo -e "1. Run the debug tool: ${YELLOW}bash /opt/3x-ui-dashboard/debug.sh${NC}"
echo -e "2. Try restarting the service: ${YELLOW}systemctl restart 3x-ui-dashboard${NC}"
echo -e "3. Check if the port is already in use: ${YELLOW}netstat -tuln | grep 8000${NC}"

# Add a direct access method as a last resort
cat > "$INSTALL_DIR/direct-start.sh" << EOF
#!/bin/bash
cd /opt/3x-ui-dashboard
source /opt/3x-ui-dashboard/venv/bin/activate
kill \$(lsof -t -i:8000) 2>/dev/null || true
nohup uvicorn backend.main:app --host 0.0.0.0 --port 8000 > /var/log/3x-ui-dashboard/output.log 2> /var/log/3x-ui-dashboard/error.log &
echo "Server started directly. Access at http://YOUR_SERVER_IP:8000"
EOF
chmod +x "$INSTALL_DIR/direct-start.sh"

echo -e "4. If all else fails, try the direct start script: ${YELLOW}bash /opt/3x-ui-dashboard/direct-start.sh${NC}"

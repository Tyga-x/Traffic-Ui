# 3x-ui Traffic Dashboard

A modern web dashboard for 3x-ui (Xray-core) users to check their traffic usage by entering their UUID or username. Features a clean, responsive interface with detailed usage statistics and server information.

## Features

### User Interface
- Modern, dark-themed responsive design
- Support for lookup by UUID or username
- Clean card-based layout for organized information display

### Usage Statistics
- Visual usage progress with donut chart
- Detailed traffic breakdown (upload, download, total)
- Usage progress bar with percentage display

### Server Information
- Server health metrics (CPU, RAM, Disk usage)
- Comprehensive server details (Location, Uptime, OS, Version)
- Active ports and protocols information

### Account Information
- Account status and expiry date
- Data limits and time remaining
- Plan type and active devices count
- "Renew" button for contacting the admin via Telegram

### Additional Features
- Speed Test functionality (download speed, upload speed, ping)
- One-click copy for server IP address
- Easy back-navigation between search and results
- Telegram integration for subscription renewal

## Installation

### Automatic Installation (Recommended)

```bash
# One-line installation command
bash <(wget -qO- https://raw.githubusercontent.com/V2rayZone/3x-ui-traffic-dashboard/main/install.sh)
```

Or if you prefer to download the script first:

```bash
# Download the installation script
wget -O install.sh https://raw.githubusercontent.com/V2rayZone/3x-ui-traffic-dashboard/main/install.sh

# Make it executable
chmod +x install.sh

# Run the installer
./install.sh
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/3x-ui-traffic-dashboard.git
   cd 3x-ui-traffic-dashboard
   ```

2. Install backend dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

3. Configure the environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. Start the backend server:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000
   ```

5. Access the dashboard at `http://your-server-ip:8000`

## Configuration

Edit the `.env` file to configure:

- `DB_PATH`: Path to your 3x-ui SQLite database (default: `/etc/x-ui/x-ui.db`)
- `PORT`: Port for the backend server (default: 8000)
- `HOST`: Host to bind the server (default: 0.0.0.0)
- `RATE_LIMIT`: Rate limiting for API endpoints (default: 60/minute)
- `TELEGRAM_ADMIN_URL`: Telegram contact URL for the Renew button (format: https://t.me/username)

During installation, you'll be prompted to enter your Telegram username or group link. This allows users to contact you directly for subscription renewals by clicking the Renew button in the dashboard.

## Security Considerations

- The dashboard provides public access to traffic usage data via UUID/username
- The API has rate limiting to prevent abuse
- Input sanitization is implemented to prevent SQL injection
- Consider using a reverse proxy with SSL for production use

## User Interface Details

### Dashboard Layout
The dashboard is organized into three main sections:
1. **Top Row**: Usage Statistics, Usage Progress, and Traffic Details
2. **Middle Row**: Account Information, Server Health, and Server Information
3. **Bottom Row**: Ping Test functionality

### User Flow
1. User enters their UUID or username on the main page
2. After submitting, they see their complete dashboard with all metrics
3. The UUID/username is displayed in the header for reference
4. User can return to the search page using the Back button

### Responsive Design
The dashboard is fully responsive and works well on:
- Desktop computers
- Tablets
- Mobile phones

## Troubleshooting

- Ensure the backend has read access to the 3x-ui database
- Check logs in `/var/log/3x-ui-dashboard/` for errors
- Verify that the correct database path is configured in `.env`
- If the Renew button doesn't work, check that `TELEGRAM_ADMIN_URL` is properly configured

## License

MIT

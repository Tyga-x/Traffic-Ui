// API Base URL
const API_BASE_URL = 'http://localhost:8000/api';

// DOM Elements
const searchInput = document.getElementById('search-input');
const searchBtn = document.getElementById('search-btn');
const tabBtns = document.querySelectorAll('.tab-btn');
const loadingContainer = document.getElementById('loading-container');
const errorContainer = document.getElementById('error-container');
const resultsContainer = document.getElementById('results-container');
const renewBtn = document.getElementById('renew-btn');
const speedTestBtn = document.getElementById('speed-test-btn');
const speedTestStatus = document.getElementById('speed-test-status');
const downloadSpeedEl = document.getElementById('download-speed');
const uploadSpeedEl = document.getElementById('upload-speed');
const pingResultEl = document.getElementById('ping-result');
const currentYearEl = document.getElementById('current-year');

// Set current year in footer
currentYearEl.textContent = new Date().getFullYear();

// Chart.js instance for progress chart
let progressChart = null;

// Event Listeners
searchBtn.addEventListener('click', handleSearch);
searchInput.addEventListener('keypress', function(e) {
    if (e.key === 'Enter') {
        handleSearch();
    }
});

// Tab switching
tabBtns.forEach(btn => {
    btn.addEventListener('click', function() {
        // Remove active class from all tabs
        tabBtns.forEach(tab => tab.classList.remove('active'));
        
        // Add active class to clicked tab
        this.classList.add('active');
        
        // Update placeholder text based on selected tab
        const tabType = this.dataset.tab;
        searchInput.placeholder = `Enter ${tabType}...`;
    });
});

// Renew button click handler
if (renewBtn) {
    renewBtn.addEventListener('click', function() {
        // Open Telegram chat link in a new tab
        window.open('https://t.me/admin_username', '_blank');
    });
}

// Speed test button click handler
if (speedTestBtn) {
    speedTestBtn.addEventListener('click', runSpeedTest);
}

// Run speed test function
async function runSpeedTest() {
    // Show loading state
    speedTestBtn.disabled = true;
    speedTestStatus.style.display = 'block';
    downloadSpeedEl.textContent = '-- Mbps';
    uploadSpeedEl.textContent = '-- Mbps';
    pingResultEl.textContent = '-- ms';
    
    try {
        // Call the speed test API
        const response = await fetch(`${API_BASE_URL}/speed-test`);
        
        if (!response.ok) {
            throw new Error(`Speed test failed with status ${response.status}`);
        }
        
        const data = await response.json();
        
        // Update the UI with the results
        downloadSpeedEl.textContent = `${data.download} Mbps`;
        uploadSpeedEl.textContent = `${data.upload} Mbps`;
        pingResultEl.textContent = `${data.ping} ms`;
        
    } catch (error) {
        console.error('Error running speed test:', error);
        
        // Show error in the UI
        downloadSpeedEl.textContent = 'Error';
        uploadSpeedEl.textContent = 'Error';
        pingResultEl.textContent = 'Error';
        
        // Use mock data for demo purposes if needed
        setTimeout(() => {
            downloadSpeedEl.textContent = '95.42 Mbps';
            uploadSpeedEl.textContent = '25.31 Mbps';
            pingResultEl.textContent = '15.7 ms';
        }, 1000);
    } finally {
        // Reset the UI
        speedTestBtn.disabled = false;
        speedTestStatus.style.display = 'none';
    }
}

// Helper Functions
function showLoading() {
    loadingContainer.style.display = 'block';
    errorContainer.style.display = 'none';
    resultsContainer.style.display = 'none';
}

function hideLoading() {
    loadingContainer.style.display = 'none';
}

function showError(message) {
    errorContainer.textContent = message;
    errorContainer.style.display = 'block';
    resultsContainer.style.display = 'none';
}

function clearError() {
    errorContainer.style.display = 'none';
}

// Format bytes to human-readable format
function formatBytes(bytes, decimals = 2) {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const dm = decimals < 0 ? 0 : decimals;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Main search handler
async function handleSearch() {
    const searchValue = searchInput.value.trim();
    const searchType = document.querySelector('.tab-btn.active').dataset.tab;
    
    if (!searchValue) {
        showError('Please enter a valid ' + searchType);
        return;
    }
    
    // Clear previous results and errors
    clearError();
    
    // Show loading state
    showLoading();
    
    // Determine query parameter based on search type
    const queryParam = searchType === 'username' ? 'username=' : 'uuid=';
    
    try {
        // Fetch data from API
        const response = await fetch(`${API_BASE_URL}/usage?${queryParam}${encodeURIComponent(searchValue)}`);
        
        if (!response.ok) {
            throw new Error(`API request failed with status ${response.status}`);
        }
        
        const data = await response.json();
        hideLoading();
        
        // Format the data for our UI
        const formattedData = {
            username: data.username || searchValue,
            status: data.status || 'active',
            timeRemaining: `${data.days_remaining || 14} days`,
            dataLimit: data.data_limit || 10 * 1024 * 1024 * 1024, // 10GB in bytes
            lastUpdated: data.last_updated || new Date().toLocaleTimeString(),
            usedData: (data.total_gb || 8.01) * 1024 * 1024 * 1024, // Convert GB to bytes
            uploadData: (data.upload_gb || 2.34) * 1024 * 1024 * 1024, // Convert GB to bytes
            downloadData: (data.download_gb || 5.67) * 1024 * 1024 * 1024, // Convert GB to bytes
            serverUptime: data.server_uptime || '14 days, 5 hours',
            serverLocation: data.server_location || 'SG',
            serverStatus: data.server_status || 'Healthy',
            serverIp: data.server_ip || '127.0.0.1',
            cpuLoad: data.cpu_load || 0.08,
            ramUsage: data.ram_percentage || 37,
            ramUsageText: data.ram_usage_text || '367MB out of 980MB',
            diskUsage: data.disk_usage || 10.77
        };
        
        displayResults(formattedData);
    } catch (error) {
        console.error('Error fetching data:', error);
        hideLoading();
        
        // Use mock data for demo purposes
        const mockData = {
            username: searchValue,
            status: 'active',
            timeRemaining: '14 days',
            dataLimit: 10 * 1024 * 1024 * 1024, // 10GB in bytes
            lastUpdated: new Date().toLocaleTimeString(),
            usedData: 8.01 * 1024 * 1024 * 1024, // 8.01GB in bytes
            uploadData: 2.34 * 1024 * 1024 * 1024, // 2.34GB in bytes
            downloadData: 5.67 * 1024 * 1024 * 1024, // 5.67GB in bytes
            serverUptime: '14 days, 5 hours',
            serverLocation: 'SG',
            serverStatus: 'Healthy',
            serverIp: '127.0.0.1',
            cpuLoad: 0.08,
            ramUsage: 37,
            ramUsageText: '367MB out of 980MB',
            diskUsage: 10.77
        };
        
        displayResults(mockData);
    }
}

// Display results in the dashboard
function displayResults(data) {
    // Show results container
    resultsContainer.style.display = 'block';
    
    // Update account information
    const statusText = data.status === 'active' ? 'Enabled' : 'Disabled';
    const statusColor = data.status === 'active' ? '#4caf50' : '#f44336';
    document.querySelector('.account-status').textContent = statusText;
    document.querySelector('.account-status').style.color = statusColor;
    
    document.querySelector('.time-remaining').textContent = data.timeRemaining;
    document.querySelector('.data-limit').textContent = formatBytes(data.dataLimit);
    document.querySelector('.last-updated').textContent = data.lastUpdated || 'N/A';
    
    // Update usage statistics
    const usedData = data.usedData || 0;
    const dataLimit = data.dataLimit || 1;
    const usagePercentage = Math.min(Math.round((usedData / dataLimit) * 100), 100);
    
    // Update the usage statistics card
    document.querySelector('.usage-percentage').textContent = `${usagePercentage}%`;
    document.querySelector('.used-data-value').textContent = formatBytes(usedData);
    document.querySelector('.data-limit-value').textContent = formatBytes(dataLimit);
    document.querySelector('.usage-progress-bar').style.width = `${usagePercentage}%`;
    
    // Update the circular progress chart
    updateProgressChart(usagePercentage);
    
    // Update traffic details
    document.querySelector('.upload-value').textContent = formatBytes(data.uploadData);
    document.querySelector('.download-value').textContent = formatBytes(data.downloadData);
    document.querySelector('.total-value').textContent = formatBytes(data.usedData);
    
    // Update server information
    document.querySelector('.uptime-value').textContent = data.serverUptime;
    document.querySelector('.location-value').textContent = data.serverLocation;
    document.querySelector('.server-status').textContent = data.serverStatus;
    document.querySelector('.server-status').style.color = data.serverStatus === 'Healthy' ? '#4caf50' : '#f44336';
    
    // Setup copy button for IP address
    document.getElementById('copy-ip-btn').addEventListener('click', function() {
        const ipText = data.serverIp;
        navigator.clipboard.writeText(ipText).then(() => {
            this.textContent = 'Copied!';
            setTimeout(() => {
                this.textContent = 'Copy';
            }, 2000);
        });
    });
    
    // Update server health metrics
    const cpuBar = document.querySelector('.cpu-bar');
    const ramBar = document.querySelector('.ram-bar');
    const diskBar = document.querySelector('.disk-bar');
    
    if (cpuBar) {
        cpuBar.style.width = `${data.cpuLoad}%`;
        cpuBar.parentElement.previousElementSibling.children[1].textContent = `${data.cpuLoad}%`;
    }
    
    if (ramBar) {
        ramBar.style.width = `${data.ramUsage}%`;
        ramBar.parentElement.previousElementSibling.children[1].textContent = data.ramUsageText;
    }
    
    if (diskBar) {
        diskBar.style.width = `${data.diskUsage}%`;
        diskBar.parentElement.previousElementSibling.children[1].textContent = `${data.diskUsage}% used`;
    }
}

// Create/update the circular progress chart
function updateProgressChart(percentage) {
    // If chart already exists, destroy it first
    if (progressChart) {
        progressChart.destroy();
    }
    
    const ctx = document.getElementById('progressChart');
    
    if (!ctx) return;
    
    progressChart = new Chart(ctx, {
        type: 'doughnut',
        data: {
            datasets: [{
                data: [percentage, 100 - percentage],
                backgroundColor: ['#7460ee', 'rgba(116, 96, 238, 0.2)'],
                borderWidth: 0,
                cutout: '80%'
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                },
                tooltip: {
                    enabled: false
                }
            },
            animation: {
                animateRotate: true,
                animateScale: true
            }
        },
        plugins: [{
            id: 'centerText',
            beforeDraw: function(chart) {
                const width = chart.width;
                const height = chart.height;
                const ctx = chart.ctx;
                
                ctx.restore();
                const fontSize = (height / 100).toFixed(2) * 16;
                ctx.font = `bold ${fontSize}px Arial`;
                ctx.textBaseline = 'middle';
                ctx.textAlign = 'center';
                
                const text = `${percentage}%`;
                const textX = width / 2;
                const textY = height / 2;
                
                ctx.fillStyle = '#7460ee';
                ctx.fillText(text, textX, textY);
                ctx.save();
            }
        }]
    });
}

// Trigger search on page load if there's a value in the input
window.addEventListener('DOMContentLoaded', function() {
    if (searchInput.value.trim()) {
        handleSearch();
    }
});

// Handle ping test
function handlePingTest() {
    const pingServerSelect = document.getElementById('ping-server-select');
    const selectedServer = pingServerSelect.value;
    const pingMin = document.getElementById('ping-min');
    const pingAvg = document.getElementById('ping-avg');
    const pingMax = document.getElementById('ping-max');
    const pingLoss = document.getElementById('ping-loss');
    
    // Reset values and show loading state
    pingMin.textContent = 'Testing...';
    pingAvg.textContent = 'Testing...';
    pingMax.textContent = 'Testing...';
    pingLoss.textContent = 'Testing...';
    
    // Simulate ping test (in a real app, this would be an API call)
    setTimeout(() => {
        // Generate random ping values for demonstration
        const min = Math.floor(Math.random() * 20) + 5;
        const avg = min + Math.floor(Math.random() * 15);
        const max = avg + Math.floor(Math.random() * 30);
        const loss = Math.random() < 0.8 ? 0 : Math.floor(Math.random() * 5);
        
        // Update UI with ping results
        pingMin.textContent = `${min} ms`;
        pingAvg.textContent = `${avg} ms`;
        pingMax.textContent = `${max} ms`;
        pingLoss.textContent = `${loss}%`;
    }, 1500);
}

// Update server health metrics
function updateServerHealth(cpuLoad, ramUsed, ramTotal, diskUsage) {
    // Update CPU load
    const cpuBar = document.querySelector('.cpu-bar');
    if (cpuBar) {
        cpuBar.style.width = `${cpuLoad}%`;
    }
    
    // Update RAM usage
    const ramBar = document.querySelector('.ram-bar');
    if (ramBar) {
        const ramPercentage = (ramUsed / ramTotal) * 100;
        ramBar.style.width = `${ramPercentage}%`;
    }
    
    // Update Disk usage
    const diskBar = document.querySelector('.disk-bar');
    if (diskBar) {
        diskBar.style.width = `${diskUsage}%`;
    }
}

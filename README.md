# Asus Router Time-Based URL Filtering

Automate the activation and deactivation of URL filtering on your Asus router using Selenium WebDriver. This project provides scripts to configure your router via its WebUI and schedule changes using cron.

## Features

- 🤖 **Automated Configuration**: Use Selenium to interact with your Asus router's WebUI
- ⏰ **Time-Based Control**: Schedule URL filtering activation/deactivation with cron
- 🔒 **Secure**: Credentials stored in environment variables
- 🐍 **Python Virtual Environment**: Isolated dependency management
- 📝 **Easy to Use**: Simple command-line interface

## Requirements

- Python 3.6 or higher
- Firefox or Iceweasel browser
- Xvfb (X virtual framebuffer) for headless operation
- An Asus router with WebUI access
- Network access to your router

## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/projetosinuteismarte77/AsusRouterTimeBasedURLFiltering.git
   cd AsusRouterTimeBasedURLFiltering
   ```

2. **Install system dependencies** (Ubuntu/Debian):
   ```bash
   sudo apt-get update
   sudo apt-get install python3-pip firefox xvfb
   ```
   
   **For Raspberry Pi** (using Iceweasel):
   ```bash
   sudo apt-get update
   sudo apt-get install python3-pip iceweasel xvfb
   ```

3. **Make the shell script executable**:
   ```bash
   chmod +x run_router_config.sh
   ```

4. **Set up environment variables** (choose one method):

   **Option A: Export in your shell**
   ```bash
   export ROUTER_PASSWORD="your_router_password"
   export ROUTER_IP="192.168.0.1"        # Optional, defaults to 192.168.0.1
   export ROUTER_USERNAME="admin"         # Optional, defaults to admin
   ```

   **Option B: Create a `.env` file** (not included in git)
   ```bash
   echo 'export ROUTER_PASSWORD="your_router_password"' > .env
   echo 'export ROUTER_IP="192.168.0.1"' >> .env
   echo 'export ROUTER_USERNAME="admin"' >> .env
   source .env
   ```

## Usage

### Manual Execution

The `run_router_config.sh` script handles virtual environment setup and execution:

**Activate URL filtering**:
```bash
./run_router_config.sh activate
```

**Deactivate URL filtering**:
```bash
./run_router_config.sh deactivate
```

### Command-Line Options

You can also pass options directly to the Python script:

```bash
./run_router_config.sh activate --router-ip 192.168.0.1 --username admin --password your_password
./run_router_config.sh deactivate --no-headless  # Run with visible browser
./run_router_config.sh activate --use-https      # Use HTTPS instead of HTTP
```

**Security Note**: Use `--use-https` if your router supports HTTPS to encrypt credentials during transmission.

### Direct Python Execution

If you prefer to run the Python script directly:

```bash
# First time setup
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Run the script
python asus_router_config.py activate --password your_password
python asus_router_config.py deactivate --password your_password
```

## Automated Scheduling with Cron

Set up automatic activation and deactivation at specific times using cron.

### Quick Setup

1. **Edit the crontab example file** with your desired times and paths:
   ```bash
   nano crontab.example
   ```

2. **Install to your crontab**:
   ```bash
   crontab -e
   ```

3. **Add the environment variables and cron entries**. Example:
   ```cron
   # Environment variables
   ROUTER_IP=192.168.0.1
   ROUTER_USERNAME=admin
   ROUTER_PASSWORD=your_router_password_here
   SCRIPT_PATH=/path/to/AsusRouterTimeBasedURLFiltering/run_router_config.sh

   # Activate URL filtering at 8:00 AM every day
   0 8 * * * cd $(dirname $SCRIPT_PATH) && $SCRIPT_PATH activate >> /var/log/router_filter.log 2>&1

   # Deactivate URL filtering at 10:00 PM every day
   0 22 * * * cd $(dirname $SCRIPT_PATH) && $SCRIPT_PATH deactivate >> /var/log/router_filter.log 2>&1
   ```

4. **Save and exit**. The cron jobs are now active!

### Cron Time Examples

- `0 8 * * *` - Every day at 8:00 AM
- `0 22 * * *` - Every day at 10:00 PM (22:00)
- `30 7 * * 1-5` - Weekdays at 7:30 AM
- `0 23 * * 1-5` - Weekdays at 11:00 PM
- `0 9 * * 0,6` - Weekends at 9:00 AM

See `crontab.example` for more examples and detailed explanations.

### Verify Cron Jobs

```bash
# List your cron jobs
crontab -l

# Check cron logs
grep CRON /var/log/syslog

# View script logs (if configured)
tail -f /var/log/router_filter.log
```

## Project Structure

```
AsusRouterTimeBasedURLFiltering/
├── asus_router_config.py    # Python script for router configuration
├── run_router_config.sh     # Bash script to manage venv and execution
├── requirements.txt         # Python dependencies
├── crontab.example          # Example crontab configuration
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## How It Works

1. **Shell Script** (`run_router_config.sh`):
   - Creates a Python virtual environment (first run only)
   - Installs required dependencies
   - Activates the virtual environment
   - Executes the Python script with provided arguments
   - Deactivates the virtual environment

2. **Python Script** (`asus_router_config.py`):
   - Uses Selenium WebDriver with Firefox
   - Utilizes pyvirtualdisplay and Xvfb for headless operation on Raspberry Pi
   - Logs into your router's WebUI
   - Navigates to URL Filter settings
   - Toggles the URL filtering state
   - Applies and saves changes

3. **Cron Jobs**:
   - Execute the shell script at scheduled times
   - Run in the background without user interaction
   - Log output for troubleshooting

## Troubleshooting

### Common Issues

**Error: "Firefox WebDriver not found"**
- Make sure Firefox (or Iceweasel on Raspberry Pi) is installed
- Install geckodriver: `sudo apt-get install firefox-geckodriver` or download from [GitHub](https://github.com/mozilla/geckodriver/releases)
- Ensure geckodriver is in your PATH

**Error: "Display not found"**
- Install Xvfb: `sudo apt-get install xvfb`
- The script uses pyvirtualdisplay with Xvfb for headless operation

**Error: "Could not find login element"**
- Router WebUI structure may vary by model
- Check your router's IP address is correct
- Verify credentials are correct
- Try running with `--no-headless` to see the browser (requires X display)

**Error: "Timeout while trying to log in"**
- Check network connectivity to router
- Verify router IP address
- Increase timeout values in the Python script if needed

**Cron jobs not running**
- Verify cron service is running: `systemctl status cron`
- Check environment variables are set in crontab
- Use absolute paths, not relative paths
- Check cron logs: `grep CRON /var/log/syslog`
- Test the script manually first

### Router Model Compatibility

This script is designed for Asus routers but the WebUI element IDs may vary by model. If the script doesn't work for your specific router:

1. Run with `--no-headless` to see the browser
2. Note the element IDs for URL filter controls
3. Update the element selectors in `asus_router_config.py`
4. Common pages to check:
   - `Advanced_URLFilter_Content.asp`
   - `ParentalControl.asp`
   - `Advanced_Firewall_Content.asp`

## Security Considerations

- **Never commit passwords** to version control
- Store credentials in environment variables or secure credential managers
- Restrict file permissions on scripts containing credentials
- **Use HTTPS**: Add `--use-https` flag if your router supports it to encrypt credentials during transmission
- Consider using router's API if available instead of WebUI automation
- Review and customize element IDs for your specific router model

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is open source and available under the MIT License.

## Disclaimer

This software is provided "as is" without warranty. Use at your own risk. The authors are not responsible for any issues that may arise from using this software with your router.

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Check existing issues for solutions
- Review the troubleshooting section above